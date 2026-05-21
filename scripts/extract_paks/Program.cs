using AssetRipper.TextureDecoder.Astc;
using AssetRipper.TextureDecoder.Dxt;
using CUE4Parse.Compression;
using CUE4Parse.Encryption.Aes;
using CUE4Parse.FileProvider;
using CUE4Parse.FileProvider.Objects;
using CUE4Parse.UE4.Lua.unluac;
using CUE4Parse.UE4.Assets.Exports.Texture;
using CUE4Parse.UE4.Objects.Core.Misc;
using CUE4Parse.UE4.Versions;
using SkiaSharp;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;

var assemblyDir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) ?? ".";
var repoRoot = FindRepoRoot(assemblyDir);

if (args.Length > 0 && args[0] == "--probe-icons")
{
    string probePakDir = Path.Combine(repoRoot, "paks");
    string? probeAesKeyHex = null;
    List<string> probeContains = [];
    for (var i = 1; i < args.Length; i++)
    {
        switch (args[i])
        {
            case "--aes-file":
            case "--key-file":
                probeAesKeyHex = ReadAesFile(RequireValue(args, ref i, args[i]));
                break;
            case "--aes-key":
                probeAesKeyHex = RequireValue(args, ref i, args[i]);
                break;
            case "--contains":
                probeContains.Add(RequireValue(args, ref i, args[i]));
                break;
            default:
                if (args[i].StartsWith("--", StringComparison.Ordinal))
                {
                    Console.Error.WriteLine($"ERROR: Unknown probe argument: {args[i]}");
                    Environment.Exit(1);
                }
                probePakDir = ResolvePath(args[i], Environment.CurrentDirectory);
                break;
        }
    }

    var probeVersion = new VersionContainer(EGame.GAME_RocoKingdomWorld);
    var probeProvider = new DefaultFileProvider(probePakDir, SearchOption.TopDirectoryOnly, probeVersion);
    probeProvider.Initialize();
    if (!string.IsNullOrWhiteSpace(probeAesKeyHex))
    {
        ValidateAesKey(probeAesKeyHex);
        var mounted = probeProvider.SubmitKey(new FGuid(), new FAesKey(probeAesKeyHex));
        Console.WriteLine($"Mounted with AES: {mounted}");
    }

    var iconQuery = probeProvider.Files.Values
        .Where(f => Path.GetExtension(f.Path).Equals(".uasset", StringComparison.OrdinalIgnoreCase));
    if (probeContains.Count > 0)
    {
        iconQuery = iconQuery.Where(f => probeContains.Any(term =>
            f.Path.Contains(term, StringComparison.OrdinalIgnoreCase)));
    }
    else
    {
        iconQuery = iconQuery.Where(IsIconTexturePath);
    }

    var iconFiles = iconQuery
        .OrderBy(f => f.Path)
        .ToList();

    Console.WriteLine($"PAK dir: {probePakDir}");
    Console.WriteLine($"Total files: {probeProvider.Files.Count}");
    if (probeContains.Count > 0)
        Console.WriteLine($"Contains: {string.Join(", ", probeContains)}");
    Console.WriteLine($"Icon texture candidates: {iconFiles.Count}");
    foreach (var path in iconFiles.Take(120).Select(f => f.Path))
        Console.WriteLine(path);
    Environment.Exit(iconFiles.Count > 0 ? 0 : 3);
}

if (args.Length > 0 && args[0] == "--extract-lua")
{
    string luaPakDir = Path.Combine(repoRoot, "paks");
    string luaOutRoot = Path.Combine(repoRoot, "output", "scripts");
    string? luaAesKeyHex = null;
    string? luaDecompilerPath = null;
    string? luaUnluacLibraryPath = null;
    int luaJobs = Math.Max(1, Environment.ProcessorCount);
    int luaDecompilerTimeoutMs = 30_000;
    List<string> luaContains = [];

    for (var i = 1; i < args.Length; i++)
    {
        switch (args[i])
        {
            case "--aes-file":
            case "--key-file":
                luaAesKeyHex = ReadAesFile(RequireValue(args, ref i, args[i]));
                break;
            case "--aes-key":
                luaAesKeyHex = RequireValue(args, ref i, args[i]);
                break;
            case "--paks":
            case "--pak-dir":
                luaPakDir = ResolvePath(RequireValue(args, ref i, args[i]), Environment.CurrentDirectory);
                break;
            case "-o":
            case "--output":
                luaOutRoot = ResolvePath(RequireValue(args, ref i, args[i]), Environment.CurrentDirectory);
                break;
            case "--decompiler":
                luaDecompilerPath = ResolveToolPath(RequireValue(args, ref i, args[i]), Environment.CurrentDirectory);
                break;
            case "--unluac-lib":
                luaUnluacLibraryPath = ResolvePath(RequireValue(args, ref i, args[i]), Environment.CurrentDirectory);
                break;
            case "--jobs":
            case "--threads":
                if (!int.TryParse(RequireValue(args, ref i, args[i]), out luaJobs) || luaJobs < 1)
                {
                    Console.Error.WriteLine("ERROR: --jobs must be a positive integer");
                    Environment.Exit(1);
                }
                break;
            case "--timeout-ms":
                if (!int.TryParse(RequireValue(args, ref i, args[i]), out luaDecompilerTimeoutMs) || luaDecompilerTimeoutMs < 1)
                {
                    Console.Error.WriteLine("ERROR: --timeout-ms must be a positive integer");
                    Environment.Exit(1);
                }
                break;
            case "--contains":
            case "--only":
                luaContains.Add(RequireValue(args, ref i, args[i]));
                break;
            default:
                if (args[i].StartsWith("@", StringComparison.Ordinal))
                {
                    luaAesKeyHex = ReadAesFile(args[i][1..]);
                }
                else if (!args[i].StartsWith("--", StringComparison.Ordinal) && string.IsNullOrWhiteSpace(luaAesKeyHex))
                {
                    luaAesKeyHex = args[i];
                }
                else
                {
                    Console.Error.WriteLine($"ERROR: Unknown Lua export argument: {args[i]}");
                    Environment.Exit(1);
                }
                break;
        }
    }

    if (string.IsNullOrWhiteSpace(luaAesKeyHex))
    {
        Console.Error.WriteLine("Usage: dotnet run /p:SkipNatives=true -- --extract-lua <aes-key|@key-file> [--paks path] [--output path] [--jobs n] [--timeout-ms n] [--contains text] --decompiler path");
        Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --extract-lua --aes-file <path> [--paks path] [--output path] [--jobs n] [--timeout-ms n] [--contains text] --unluac-lib path");
        Environment.Exit(1);
    }

    ValidateAesKey(luaAesKeyHex);
    if (!string.IsNullOrWhiteSpace(luaUnluacLibraryPath))
    {
        UnluacHelper.Initialize(new Unluac(luaUnluacLibraryPath));
    }
    else if (string.IsNullOrWhiteSpace(luaDecompilerPath))
    {
        luaDecompilerPath = FindExecutable("unluac-cli");
    }

    if (UnluacHelper.Instance is null && string.IsNullOrWhiteSpace(luaDecompilerPath))
    {
        Console.Error.WriteLine("ERROR: Lua source output needs a decompiler. Pass --decompiler <unluac-cli|unluac.jar> or --unluac-lib <path>.");
        Environment.Exit(1);
    }

    var luaProvider = OpenProvider(luaPakDir, luaAesKeyHex, assemblyDir);
    var luacFiles = luaProvider.Files.Values
        .Where(f => Path.GetExtension(f.Path).Equals(".luac", StringComparison.OrdinalIgnoreCase))
        .Select(f => new { File = f, CleanPath = CleanLuaSourcePath(f.Path) })
        .Where(item => luaContains.Count == 0 || luaContains.Any(term =>
            item.CleanPath.Contains(term, StringComparison.OrdinalIgnoreCase) ||
            item.File.Path.Contains(term, StringComparison.OrdinalIgnoreCase)))
        .GroupBy(item => item.CleanPath, StringComparer.OrdinalIgnoreCase)
        .Select(group => group.First())
        .OrderBy(item => item.CleanPath, StringComparer.OrdinalIgnoreCase)
        .ToList();
    var luaSourceDir = Path.Combine(luaOutRoot, "lua");

    Console.WriteLine($"Lua output : {luaOutRoot}");
    Console.WriteLine($"Candidates : {luacFiles.Count}");
    Console.WriteLine($"Jobs       : {luaJobs}");
    Console.WriteLine($"Timeout ms : {luaDecompilerTimeoutMs}");
    if (luaContains.Count > 0)
        Console.WriteLine($"Contains   : {string.Join(", ", luaContains)}");

    if (luaContains.Count == 0)
        CleanLuaSourceOutput(luaOutRoot, luaSourceDir);
    else
        Directory.CreateDirectory(luaSourceDir);

    var sourceIndex = new List<string>();
    int sourceWritten = 0, luacErrors = 0, sourceErrors = 0;
    var decompileOptions = new ParallelOptions
    {
        MaxDegreeOfParallelism = luaJobs
    };
    Parallel.ForEach(luacFiles, decompileOptions, file =>
    {
        try
        {
            var data = luaProvider.SaveAsset(file.File);

            try
            {
                var dest = Path.Combine(luaSourceDir, ToLuaSourceRelativePath(file.CleanPath));
                Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                File.WriteAllText(dest, DecompileLuaSource(data, file.CleanPath, luaDecompilerPath, luaDecompilerTimeoutMs), new UTF8Encoding(false));
                lock (sourceIndex)
                {
                    sourceIndex.Add(Path.GetRelativePath(luaSourceDir, dest).Replace('\\', '/'));
                }
                Interlocked.Increment(ref sourceWritten);
            }
            catch (Exception ex)
            {
                Interlocked.Increment(ref sourceErrors);
                if (sourceErrors <= 10)
                    Console.Error.WriteLine($"SOURCE WARN: {file.File.Path}: {ex.Message}");
            }
        }
        catch (Exception ex)
        {
            Interlocked.Increment(ref luacErrors);
            if (luacErrors <= 10)
                Console.Error.WriteLine($"LUAC WARN: {file.File.Path}: {ex.Message}");
        }
    });

    WriteJsonIndex(luaSourceDir, luaContains.Count == 0 ? sourceIndex : EnumerateLuaSourceFiles(luaSourceDir));
    Console.WriteLine($"Lua source  : {sourceWritten} exported, {sourceErrors} decompile errors, {luacErrors} read errors");
    Console.WriteLine($"Source index: {Path.Combine(luaSourceDir, "index.json")}");
    Environment.Exit(sourceWritten > 0 ? 0 : 4);
}

if (args.Length < 1)
{
    Console.Error.WriteLine("Usage: dotnet run /p:SkipNatives=true -- <aes-key-hex> [pak-dir] [out-dir]");
    Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --aes-file <path> [pak-dir] [out-dir]");
    Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --probe-icons [pak-dir] [--aes-file path]");
    Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --extract-lua <aes-key|@key-file> [--paks path] [--output path] [--jobs n] [--timeout-ms n] [--contains text] --decompiler path");
    Console.Error.WriteLine("  aes-key-hex: 64-character hex AES key");
    Console.Error.WriteLine("  pak-dir:     directory containing .pak files (default: ../../paks)");
    Console.Error.WriteLine("  out-dir:     output directory (default: ../../temp)");
    Environment.Exit(1);
}

var argIndex = 1;
string aesKeyHex;
if (args[0] is "--aes-file" or "--key-file")
{
    var optionIndex = 0;
    aesKeyHex = ReadAesFile(RequireValue(args, ref optionIndex, args[0]));
    argIndex = 2;
}
else if (args[0].StartsWith("@", StringComparison.Ordinal))
{
    aesKeyHex = ReadAesFile(args[0][1..]);
}
else
{
    aesKeyHex = args[0];
}

string pakDir = args.Length > argIndex ? args[argIndex] : "../../paks";
string outDir = args.Length > argIndex + 1 ? args[argIndex + 1] : "../../temp";

pakDir = args.Length > argIndex
    ? ResolvePath(pakDir, Environment.CurrentDirectory)
    : Path.Combine(repoRoot, "paks");
outDir = args.Length > argIndex + 1
    ? ResolvePath(outDir, Environment.CurrentDirectory)
    : Path.Combine(repoRoot, "temp");

ValidateAesKey(aesKeyHex);
var aesKey = new FAesKey(aesKeyHex);

Console.WriteLine($"AES key : {aesKeyHex[..16]}...");
Console.WriteLine($"PAK dir : {pakDir}");
Console.WriteLine($"Output  : {outDir}");

if (!Directory.Exists(pakDir))
{
    Console.Error.WriteLine($"ERROR: PAK directory not found: {pakDir}");
    Environment.Exit(1);
}

var pakFiles = Directory.GetFiles(pakDir, "*.pak");
if (pakFiles.Length == 0)
{
    Console.Error.WriteLine($"ERROR: No .pak files found in {pakDir}");
    Environment.Exit(1);
}
Console.WriteLine($"Found {pakFiles.Length} PAK files");

// Init compression (Oodle from lib/ directory)
// Dylib is copied to output dir via csproj Content
var oodlePath = Path.Combine(assemblyDir, "liboo2coremac64.2.9.16.dylib");

if (OperatingSystem.IsMacOS())
{
    if (!File.Exists(oodlePath))
    {
        Console.Error.WriteLine($"WARNING: Oodle dylib not found at {oodlePath}, Oodle files will fail");
    }
    try { OodleHelper.Initialize(oodlePath); Console.WriteLine("Oodle OK"); }
    catch (Exception e) { Console.Error.WriteLine($"Oodle init failed: {e.Message}"); }
}
else if (OperatingSystem.IsWindows())
{
    try { OodleHelper.Initialize(); Console.WriteLine("Oodle OK"); }
    catch (Exception e) { Console.Error.WriteLine($"Oodle init failed: {e.Message}"); }
}

try { ZlibHelper.Initialize(); Console.WriteLine("Zlib OK"); }
catch (Exception e) { Console.Error.WriteLine($"Zlib skipped: {e.Message}"); }

// Open paks with RocoKingdomWorld game type
var version = new VersionContainer(EGame.GAME_RocoKingdomWorld);
var provider = new DefaultFileProvider(pakDir, SearchOption.TopDirectoryOnly, version);
provider.Initialize();

Console.WriteLine($"Submitting AES key...");
provider.SubmitKey(new FGuid(), aesKey);

var totalFiles = provider.Files.Count;
Console.WriteLine($"Loaded {totalFiles} files across all paks");

// Try decrypting a sample to validate the key
var testFile = provider.Files.Values.FirstOrDefault();
if (testFile != null)
{
    try
    {
        provider.SaveAsset(testFile);
        Console.WriteLine("AES key validated OK");
    }
    catch (Exception e)
    {
        Console.Error.WriteLine($"ERROR: AES key validation failed - key is wrong or paks are corrupt");
        Console.Error.WriteLine($"  Details: {e.Message}");
        Console.Error.WriteLine($"  Test file: {testFile.Path}");
        Environment.Exit(2);
    }
}

// Extract table/config files.
var extractExts = new HashSet<string> { ".bytes", ".non", ".json", ".png", ".txt", ".ini", ".jpg" };
var toExtract = provider.Files.Values
    .Where(f => extractExts.Contains(Path.GetExtension(f.Path).ToLower()))
    .ToList();

Console.WriteLine($"Files to extract: {toExtract.Count}");
Console.WriteLine("Extracting...");

int extracted = 0, errors = 0;
Parallel.ForEach(toExtract, file =>
{
    try
    {
        var data = provider.SaveAsset(file);
        var dest = Path.Combine(outDir, CleanPakPath(file.Path));
        Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
        File.WriteAllBytes(dest, data);
        Interlocked.Increment(ref extracted);
    }
    catch (Exception ex)
    {
        Interlocked.Increment(ref errors);
        if (errors <= 10)
            Console.Error.WriteLine($"RAW WARN: {file.Path}: {ex.Message}");
    }
});

Console.WriteLine($"Done: {extracted} extracted, {errors} raw files skipped");

Console.WriteLine("Exporting texture icons...");
var textureFiles = provider.Files.Values
    .Where(f => Path.GetExtension(f.Path).Equals(".uasset", StringComparison.OrdinalIgnoreCase))
    .Where(IsIconTexturePath)
    .OrderBy(GetTextureExportPriority)
    .ThenBy(f => f.Path, StringComparer.OrdinalIgnoreCase)
    .ToList();

Console.WriteLine($"Texture candidates: {textureFiles.Count}");
foreach (var path in textureFiles.Take(20).Select(f => f.Path))
    Console.WriteLine($"  TEX {path}");

if (textureFiles.Count == 0)
{
    Console.Error.WriteLine("ERROR: No icon texture candidates found in mounted PAK files.");
    Environment.Exit(4);
}

int textures = 0, textureErrors = 0;
foreach (var file in textureFiles)
{
    try
    {
        if (ExportTexture(provider, file, outDir))
            textures++;
    }
    catch (Exception ex)
    {
        textureErrors++;
        if (textureErrors <= 10)
            Console.Error.WriteLine($"TEX ERR: {file.Path}: {ex.Message}");
    }
}

static bool IsIconTexturePath(GameFile file)
{
    var p = file.Path.Replace('\\', '/');
    return p.Contains("/System/Common/Icon/", StringComparison.OrdinalIgnoreCase) ||
           p.Contains("/System/BattleUI/Raw/Atlas/", StringComparison.OrdinalIgnoreCase);
}

static int GetTextureExportPriority(GameFile file)
{
    var p = file.Path.Replace('\\', '/');
    if (p.Contains("/System/Common/Icon/HeadIcon/", StringComparison.OrdinalIgnoreCase)) return 0;
    if (p.Contains("/System/Common/Icon/BigHeadIcon256/", StringComparison.OrdinalIgnoreCase)) return 1;
    if (p.Contains("/System/Common/Icon/Pet1024/", StringComparison.OrdinalIgnoreCase)) return 2;
    if (p.Contains("/System/Common/Icon/Pet256/", StringComparison.OrdinalIgnoreCase)) return 3;
    if (p.Contains("/System/Common/Icon/BagItem/", StringComparison.OrdinalIgnoreCase)) return 4;
    if (p.Contains("/System/Common/Icon/Item190/", StringComparison.OrdinalIgnoreCase)) return 5;
    if (p.Contains("/System/Common/Icon/", StringComparison.OrdinalIgnoreCase)) return 6;
    if (p.Contains("/System/BattleUI/Raw/Atlas/FeatureIcon/", StringComparison.OrdinalIgnoreCase)) return 7;
    if (p.Contains("/System/BattleUI/Raw/Atlas/SkillIcon/", StringComparison.OrdinalIgnoreCase)) return 8;
    if (p.Contains("/System/BattleUI/Raw/Atlas/", StringComparison.OrdinalIgnoreCase)) return 9;
    return 10;
}

Console.WriteLine($"Texture icons: {textures} exported, {textureErrors} errors");
if (textures == 0)
{
    Console.Error.WriteLine("ERROR: Icon texture candidates were found, but none decoded to webp.");
    Environment.Exit(4);
}

static bool ExportTexture(DefaultFileProvider provider, GameFile file, string outDir)
{
    if (!provider.TryLoadPackage(file, out var package) || package is null)
        return false;

    var exported = false;
    foreach (var texture in package.GetExports().OfType<UTexture2D>())
    {
        using var bitmap = DecodeTexture(texture);
        if (bitmap is null)
            continue;

        using var image = SKImage.FromBitmap(bitmap);
        using var data = image.Encode(SKEncodedImageFormat.Webp, 90);
        if (data is null)
            continue;

        var dest = Path.Combine(outDir, GetTextureOutputRelativePath(file));
        Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
        File.WriteAllBytes(dest, data.ToArray());
        exported = true;
    }

    return exported;
}

static string GetTextureOutputRelativePath(GameFile file)
{
    var gamePackagePath = ToGamePackagePath(file.Path);
    var packageDir = Path.GetDirectoryName(gamePackagePath)?.Replace('\\', '/') ?? "Game";
    var assetName = Path.GetFileNameWithoutExtension(gamePackagePath);
    if (string.IsNullOrWhiteSpace(assetName))
        assetName = Path.GetFileNameWithoutExtension(file.Name);

    var segments = new List<string> { "assets", "webp" };
    segments.AddRange(SafePathSegments(packageDir));
    segments.Add($"{assetName}.webp");
    return Path.Combine(segments.ToArray());
}

static string ToGamePackagePath(string pakPath)
{
    var p = pakPath.Replace('\\', '/').TrimStart('/');
    const string contentMarker = "/Content/";
    var contentIndex = p.IndexOf(contentMarker, StringComparison.OrdinalIgnoreCase);
    if (contentIndex >= 0)
        return "Game/" + p[(contentIndex + contentMarker.Length)..];

    const string contentPrefix = "Content/";
    if (p.StartsWith(contentPrefix, StringComparison.OrdinalIgnoreCase))
        return "Game/" + p[contentPrefix.Length..];

    return p.StartsWith("Game/", StringComparison.OrdinalIgnoreCase) ? p : $"Game/{p}";
}

static IEnumerable<string> SafePathSegments(string path)
{
    foreach (var segment in path.Split('/', StringSplitOptions.RemoveEmptyEntries))
    {
        if (segment is "." or "..")
            throw new InvalidOperationException($"Unsafe asset path segment in {path}");
        yield return segment;
    }
}

static SKBitmap? DecodeTexture(UTexture2D texture)
{
    var mip = texture.GetFirstMip();
    var source = mip?.BulkData?.Data;
    if (mip is null || source is null || source.Length == 0)
        return null;

    var width = mip.SizeX;
    var height = mip.SizeY;
    if (width <= 0 || height <= 0)
        return null;

    var rgba = new byte[width * height * 4];
    var decoderOutputsBgra = false;
    switch (texture.Format)
    {
        case EPixelFormat.PF_B8G8R8A8:
            if (source.Length < rgba.Length) return null;
            for (var i = 0; i < width * height; i++)
            {
                rgba[i * 4 + 0] = source[i * 4 + 2];
                rgba[i * 4 + 1] = source[i * 4 + 1];
                rgba[i * 4 + 2] = source[i * 4 + 0];
                rgba[i * 4 + 3] = source[i * 4 + 3];
            }
            break;
        case EPixelFormat.PF_R8G8B8A8:
            if (source.Length < rgba.Length) return null;
            Buffer.BlockCopy(source, 0, rgba, 0, rgba.Length);
            break;
        case EPixelFormat.PF_DXT1:
            DxtDecoder.DecompressDXT1(source, width, height, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_DXT3:
            DxtDecoder.DecompressDXT3(source, width, height, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_DXT5:
            DxtDecoder.DecompressDXT5(source, width, height, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_ASTC_4x4:
            AstcDecoder.DecodeASTC(source, width, height, 4, 4, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_ASTC_6x6:
            AstcDecoder.DecodeASTC(source, width, height, 6, 6, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_ASTC_8x8:
            AstcDecoder.DecodeASTC(source, width, height, 8, 8, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_ASTC_10x10:
            AstcDecoder.DecodeASTC(source, width, height, 10, 10, rgba);
            decoderOutputsBgra = true;
            break;
        case EPixelFormat.PF_ASTC_12x12:
            AstcDecoder.DecodeASTC(source, width, height, 12, 12, rgba);
            decoderOutputsBgra = true;
            break;
        default:
            return null;
    }

    if (decoderOutputsBgra)
        SwapRedBlue(rgba);

    var bitmap = new SKBitmap(new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Unpremul));
    Marshal.Copy(rgba, 0, bitmap.GetPixels(), rgba.Length);
    return bitmap;
}

static void SwapRedBlue(byte[] rgba)
{
    for (var i = 0; i < rgba.Length; i += 4)
    {
        (rgba[i], rgba[i + 2]) = (rgba[i + 2], rgba[i]);
    }
}

static DefaultFileProvider OpenProvider(string pakDir, string aesKeyHex, string assemblyDir)
{
    Console.WriteLine($"AES key : {aesKeyHex[..16]}...");
    Console.WriteLine($"PAK dir : {pakDir}");

    if (!Directory.Exists(pakDir))
    {
        Console.Error.WriteLine($"ERROR: PAK directory not found: {pakDir}");
        Environment.Exit(1);
    }

    var pakFiles = Directory.GetFiles(pakDir, "*.pak");
    if (pakFiles.Length == 0)
    {
        Console.Error.WriteLine($"ERROR: No .pak files found in {pakDir}");
        Environment.Exit(1);
    }
    Console.WriteLine($"Found {pakFiles.Length} PAK files");

    var oodlePath = Path.Combine(assemblyDir, "liboo2coremac64.2.9.16.dylib");
    if (OperatingSystem.IsMacOS())
    {
        if (!File.Exists(oodlePath))
            Console.Error.WriteLine($"WARNING: Oodle dylib not found at {oodlePath}, Oodle files will fail");
        try { OodleHelper.Initialize(oodlePath); Console.WriteLine("Oodle OK"); }
        catch (Exception e) { Console.Error.WriteLine($"Oodle init failed: {e.Message}"); }
    }
    else if (OperatingSystem.IsWindows())
    {
        try { OodleHelper.Initialize(); Console.WriteLine("Oodle OK"); }
        catch (Exception e) { Console.Error.WriteLine($"Oodle init failed: {e.Message}"); }
    }

    try { ZlibHelper.Initialize(); Console.WriteLine("Zlib OK"); }
    catch (Exception e) { Console.Error.WriteLine($"Zlib skipped: {e.Message}"); }

    var provider = new DefaultFileProvider(pakDir, SearchOption.TopDirectoryOnly, new VersionContainer(EGame.GAME_RocoKingdomWorld));
    provider.Initialize();
    Console.WriteLine("Submitting AES key...");
    provider.SubmitKey(new FGuid(), new FAesKey(aesKeyHex));
    Console.WriteLine($"Loaded {provider.Files.Count} files across all paks");

    return provider;
}

static string CleanPakPath(string path)
{
    var cleanPath = path.TrimStart('/');
    while (cleanPath.StartsWith("../")) cleanPath = cleanPath[3..];
    if (cleanPath.StartsWith("NRC/")) cleanPath = cleanPath[4..];
    return cleanPath;
}

static string CleanLuaSourcePath(string path)
{
    var cleanPath = CleanPakPath(path).Replace('\\', '/');
    const string scriptPrefix = "Content/ScriptC/";
    var index = cleanPath.IndexOf(scriptPrefix, StringComparison.OrdinalIgnoreCase);
    if (index >= 0)
        cleanPath = cleanPath[(index + scriptPrefix.Length)..];
    else if (cleanPath.StartsWith("ScriptC/", StringComparison.OrdinalIgnoreCase))
        cleanPath = cleanPath["ScriptC/".Length..];
    return cleanPath;
}

static void CleanLuaSourceOutput(string luaOutRoot, string luaSourceDir)
{
    foreach (var name in new[] { "lua", "luac", "disasm" })
    {
        var dir = Path.Combine(luaOutRoot, name);
        if (Directory.Exists(dir))
            Directory.Delete(dir, recursive: true);
    }
    Directory.CreateDirectory(luaSourceDir);
}

static void WriteJsonIndex(string dir, IEnumerable<string> paths)
{
    Directory.CreateDirectory(dir);
    var indexPath = Path.Combine(dir, "index.json");
    File.WriteAllText(indexPath, JsonSerializer.Serialize(
        paths.OrderBy(item => item, StringComparer.OrdinalIgnoreCase),
        new JsonSerializerOptions { WriteIndented = true }));
}

static IEnumerable<string> EnumerateLuaSourceFiles(string dir)
{
    if (!Directory.Exists(dir))
        return [];

    return Directory.EnumerateFiles(dir, "*.lua", SearchOption.AllDirectories)
        .Select(path => Path.GetRelativePath(dir, path).Replace('\\', '/'));
}

static string ToLuaSourceRelativePath(string luacPath)
{
    var path = luacPath.Replace('\\', '/');
    return path.EndsWith(".luac", StringComparison.OrdinalIgnoreCase)
        ? $"{path[..^5]}.lua"
        : $"{path}.lua";
}

static string DecompileLuaSource(byte[] data, string sourcePath, string? decompilerPath, int timeoutMs)
{
    if (UnluacHelper.Instance is not null)
    {
        var rc = UnluacHelper.Decompile(data, [], (uint) EUnluacFlags.Decompile, out var output, out var log);
        if ((rc == EUnluacErrorCode.Ok || rc == EUnluacErrorCode.PartialDecompile) && output.Length > 0)
            return Encoding.UTF8.GetString(output);

        var detail = log.Length > 0 ? Encoding.UTF8.GetString(log) : rc.ToString();
        throw new InvalidOperationException($"native unluac failed for {sourcePath}: {detail}");
    }

    if (string.IsNullOrWhiteSpace(decompilerPath))
        throw new InvalidOperationException("Lua source decompiler is not configured");

    return DecompileLuaSourceWithExternalTool(data, sourcePath, decompilerPath, timeoutMs);
}

static string DecompileLuaSourceWithExternalTool(byte[] data, string sourcePath, string decompilerPath, int timeoutMs)
{
    var tempDir = Path.Combine(Path.GetTempPath(), "nrc-extract-lua");
    Directory.CreateDirectory(tempDir);
    var stem = Guid.NewGuid().ToString("N");
    var inputPath = Path.Combine(tempDir, $"{stem}.luac");
    var outputPath = Path.Combine(tempDir, $"{stem}.lua");
    File.WriteAllBytes(inputPath, data);

    try
    {
        var psi = new ProcessStartInfo
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };

        if (decompilerPath.EndsWith(".jar", StringComparison.OrdinalIgnoreCase))
        {
            AddJavaDecompilerArguments(psi, decompilerPath, inputPath);
        }
        else
        {
            psi.FileName = decompilerPath;
            psi.ArgumentList.Add("-i");
            psi.ArgumentList.Add(inputPath);
            psi.ArgumentList.Add("-D");
            psi.ArgumentList.Add("lua5.4");
            psi.ArgumentList.Add("-o");
            psi.ArgumentList.Add(outputPath);
        }

        using var process = Process.Start(psi) ?? throw new InvalidOperationException($"failed to start decompiler: {decompilerPath}");
        var stdoutTask = process.StandardOutput.ReadToEndAsync();
        var stderrTask = process.StandardError.ReadToEndAsync();
        if (!process.WaitForExit(timeoutMs))
        {
            try { process.Kill(entireProcessTree: true); } catch { /* best effort */ }
            try { process.WaitForExit(); } catch { /* best effort */ }
            if (decompilerPath.EndsWith(".jar", StringComparison.OrdinalIgnoreCase))
                return DecompileLuaSourceWithJarFallbacks(inputPath, sourcePath, decompilerPath, timeoutMs, "default decompile timed out");
            throw new TimeoutException($"decompiler timed out for {sourcePath}");
        }

        var stdout = stdoutTask.GetAwaiter().GetResult();
        var stderr = stderrTask.GetAwaiter().GetResult();

        if (File.Exists(outputPath))
            return File.ReadAllText(outputPath, Encoding.UTF8);

        if (process.ExitCode == 0)
            return stdout;

        if (decompilerPath.EndsWith(".jar", StringComparison.OrdinalIgnoreCase))
            return DecompileLuaSourceWithJarFallbacks(inputPath, sourcePath, decompilerPath, timeoutMs, stderr.Trim());

        throw new InvalidOperationException($"decompiler failed for {sourcePath}: {stderr.Trim()}".Trim());
    }
    finally
    {
        TryDeleteFile(inputPath);
        TryDeleteFile(outputPath);
    }
}

static string DecompileLuaSourceWithJarFallbacks(string inputPath, string sourcePath, string decompilerPath, int timeoutMs, string firstError)
{
    var attempts = new[]
    {
        new[] { "--nodebug" },
        new[] { "--luaj" },
        new[] { "--nodebug", "--luaj" },
    };
    var errors = new List<string>();
    if (!string.IsNullOrWhiteSpace(firstError))
        errors.Add(firstError);

    foreach (var extraArgs in attempts)
    {
        var psi = new ProcessStartInfo
        {
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };
        AddJavaDecompilerArguments(psi, decompilerPath, inputPath, extraArgs);

        using var process = Process.Start(psi) ?? throw new InvalidOperationException($"failed to start decompiler: {decompilerPath}");
        var stdoutTask = process.StandardOutput.ReadToEndAsync();
        var stderrTask = process.StandardError.ReadToEndAsync();
        if (!process.WaitForExit(timeoutMs))
        {
            try { process.Kill(entireProcessTree: true); } catch { /* best effort */ }
            try { process.WaitForExit(); } catch { /* best effort */ }
            errors.Add($"{string.Join(" ", extraArgs)} timed out");
            continue;
        }

        var stdout = stdoutTask.GetAwaiter().GetResult();
        var stderr = stderrTask.GetAwaiter().GetResult();
        if (process.ExitCode == 0 && !string.IsNullOrWhiteSpace(stdout))
            return stdout;
        if (!string.IsNullOrWhiteSpace(stderr))
            errors.Add($"{string.Join(" ", extraArgs)}: {stderr.Trim()}");
    }

    throw new InvalidOperationException($"decompiler failed for {sourcePath}: {string.Join("\n---\n", errors)}".Trim());
}

static void AddJavaDecompilerArguments(ProcessStartInfo psi, string decompilerPath, string inputPath, IEnumerable<string>? extraArgs = null)
{
    psi.FileName = FindExecutable("java") ?? "java";
    psi.ArgumentList.Add("-jar");
    psi.ArgumentList.Add(decompilerPath);
    if (extraArgs is not null)
    {
        foreach (var arg in extraArgs)
            psi.ArgumentList.Add(arg);
    }
    psi.ArgumentList.Add(inputPath);
}

static string ResolvePath(string value, string baseDir)
{
    return Path.IsPathRooted(value)
        ? Path.GetFullPath(value)
        : Path.GetFullPath(Path.Combine(baseDir, value));
}

static string ResolveToolPath(string value, string baseDir)
{
    return value.Contains(Path.DirectorySeparatorChar) ||
           value.Contains(Path.AltDirectorySeparatorChar) ||
           value.StartsWith(".", StringComparison.Ordinal)
        ? ResolvePath(value, baseDir)
        : value;
}

static string? FindExecutable(string name)
{
    if (File.Exists(name))
        return Path.GetFullPath(name);

    var pathEnv = Environment.GetEnvironmentVariable("PATH");
    if (string.IsNullOrWhiteSpace(pathEnv))
        return null;

    foreach (var dir in pathEnv.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
    {
        var candidate = Path.Combine(dir, name);
        if (File.Exists(candidate))
            return candidate;

        if (OperatingSystem.IsWindows())
        {
            var pathext = Environment.GetEnvironmentVariable("PATHEXT") ?? ".EXE;.BAT;.CMD";
            foreach (var ext in pathext.Split(';', StringSplitOptions.RemoveEmptyEntries))
            {
                candidate = Path.Combine(dir, $"{name}{ext}");
                if (File.Exists(candidate))
                    return candidate;
            }
        }
    }

    return null;
}

static void TryDeleteFile(string path)
{
    try
    {
        if (File.Exists(path))
            File.Delete(path);
    }
    catch
    {
        // Temporary cleanup is best-effort.
    }
}

static string RequireValue(string[] args, ref int index, string option)
{
    if (index + 1 >= args.Length)
    {
        Console.Error.WriteLine($"ERROR: {option} requires a value");
        Environment.Exit(1);
    }

    index++;
    return args[index];
}

static string ReadAesFile(string path)
{
    path = ResolvePath(path, Environment.CurrentDirectory);
    if (!File.Exists(path))
    {
        Console.Error.WriteLine($"ERROR: AES key file not found: {path}");
        Environment.Exit(1);
    }

    return new string(File.ReadAllText(path).Where(c => !char.IsWhiteSpace(c)).ToArray());
}

static void ValidateAesKey(string aesKeyHex)
{
    if (aesKeyHex.Length != 64 || !aesKeyHex.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f' or >= 'A' and <= 'F'))
    {
        Console.Error.WriteLine($"ERROR: AES key must be 64 hex characters, got {aesKeyHex.Length}");
        Environment.Exit(1);
    }
}

static string FindRepoRoot(string startDir)
{
    var dir = new DirectoryInfo(Path.GetFullPath(startDir));
    while (dir is not null)
    {
        if (Directory.Exists(Path.Combine(dir.FullName, "scripts")) &&
            (File.Exists(Path.Combine(dir.FullName, "pyproject.toml")) ||
             Directory.Exists(Path.Combine(dir.FullName, "paks"))))
        {
            return dir.FullName;
        }
        dir = dir.Parent;
    }

    return Path.GetFullPath(Path.Combine(startDir, "../../../../.."));
}
