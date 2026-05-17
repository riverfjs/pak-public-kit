using AssetRipper.TextureDecoder.Astc;
using AssetRipper.TextureDecoder.Dxt;
using CUE4Parse.Compression;
using CUE4Parse.Encryption.Aes;
using CUE4Parse.FileProvider;
using CUE4Parse.FileProvider.Objects;
using CUE4Parse.UE4.Lua;
using CUE4Parse.UE4.Assets.Exports.Texture;
using CUE4Parse.UE4.Objects.Core.Misc;
using CUE4Parse.UE4.Versions;
using SkiaSharp;
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

if (args.Length > 0 && args[0] == "--extract-luac")
{
    string luaPakDir = Path.Combine(repoRoot, "paks");
    string luaOutRoot = Path.Combine(repoRoot, "output", "scripts");
    string? luaAesKeyHex = null;
    bool allScripts = false;
    bool writeBytecode = true;
    bool writeDisasm = true;

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
            case "--all":
                allScripts = true;
                break;
            case "--battle":
                allScripts = false;
                break;
            case "--bytecode-only":
                writeBytecode = true;
                writeDisasm = false;
                break;
            case "--disasm-only":
                writeBytecode = false;
                writeDisasm = true;
                break;
            case "--no-disasm":
                writeDisasm = false;
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
        Console.Error.WriteLine("Usage: dotnet run /p:SkipNatives=true -- --extract-luac <aes-key|@key-file> [--paks path] [--output path] [--all]");
        Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --extract-luac --aes-file <path> [--paks path] [--output path] [--all]");
        Environment.Exit(1);
    }

    ValidateAesKey(luaAesKeyHex);
    var luaProvider = OpenProvider(luaPakDir, luaAesKeyHex, assemblyDir);
    var luacFiles = luaProvider.Files.Values
        .Where(f => Path.GetExtension(f.Path).Equals(".luac", StringComparison.OrdinalIgnoreCase))
        .Where(f => allScripts || IsBattleLuaPath(f.Path))
        .Select(f => new { File = f, CleanPath = CleanPakPath(f.Path) })
        .GroupBy(item => item.CleanPath, StringComparer.OrdinalIgnoreCase)
        .Select(group => group.Last())
        .OrderBy(item => item.CleanPath, StringComparer.OrdinalIgnoreCase)
        .ToList();
    var modeName = allScripts ? "all" : "battle";
    var luaBytecodeDir = Path.Combine(luaOutRoot, "luac", modeName);
    var luaDisasmDir = Path.Combine(luaOutRoot, "disasm", modeName);

    Console.WriteLine($"Lua output : {luaOutRoot}");
    Console.WriteLine($"Mode       : {modeName}");
    Console.WriteLine($"Candidates : {luacFiles.Count}");

    if (writeBytecode) CleanLuaOutputDir(luaBytecodeDir, "*.luac");
    if (writeDisasm) CleanLuaOutputDir(luaDisasmDir, "*.luasm");

    var bytecodeIndex = new List<string>();
    var disasmIndex = new List<string>();
    int bytecodeWritten = 0, disasmWritten = 0, luacErrors = 0, disasmErrors = 0;
    Parallel.ForEach(luacFiles, file =>
    {
        try
        {
            var data = luaProvider.SaveAsset(file.File);

            if (writeBytecode)
            {
                var dest = Path.Combine(luaBytecodeDir, file.CleanPath);
                Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                File.WriteAllBytes(dest, data);
                lock (bytecodeIndex)
                {
                    bytecodeIndex.Add(Path.GetRelativePath(luaBytecodeDir, dest).Replace('\\', '/'));
                }
                Interlocked.Increment(ref bytecodeWritten);
            }

            if (writeDisasm)
            {
                try
                {
                    var dest = Path.Combine(luaDisasmDir, ToLuaDisasmRelativePath(file.CleanPath));
                    Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                    File.WriteAllText(dest, DisassembleLuaBytecode(data, file.CleanPath), new UTF8Encoding(false));
                    lock (disasmIndex)
                    {
                        disasmIndex.Add(Path.GetRelativePath(luaDisasmDir, dest).Replace('\\', '/'));
                    }
                    Interlocked.Increment(ref disasmWritten);
                }
                catch (Exception ex)
                {
                    Interlocked.Increment(ref disasmErrors);
                    if (disasmErrors <= 10)
                        Console.Error.WriteLine($"DISASM WARN: {file.File.Path}: {ex.Message}");
                }
            }
        }
        catch (Exception ex)
        {
            Interlocked.Increment(ref luacErrors);
            if (luacErrors <= 10)
                Console.Error.WriteLine($"LUAC WARN: {file.File.Path}: {ex.Message}");
        }
    });

    if (writeBytecode)
    {
        WriteJsonIndex(luaBytecodeDir, bytecodeIndex);
        Console.WriteLine($"Lua bytecode: {bytecodeWritten} exported, {luacErrors} skipped");
        Console.WriteLine($"Bytecode index: {Path.Combine(luaBytecodeDir, "index.json")}");
    }
    if (writeDisasm)
    {
        WriteJsonIndex(luaDisasmDir, disasmIndex);
        Console.WriteLine($"Lua disasm  : {disasmWritten} exported, {disasmErrors} skipped");
        Console.WriteLine($"Disasm index: {Path.Combine(luaDisasmDir, "index.json")}");
    }
    Environment.Exit(bytecodeWritten + disasmWritten > 0 ? 0 : 4);
}

if (args.Length < 1)
{
    Console.Error.WriteLine("Usage: dotnet run /p:SkipNatives=true -- <aes-key-hex> [pak-dir] [out-dir]");
    Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --aes-file <path> [pak-dir] [out-dir]");
    Console.Error.WriteLine("       dotnet run /p:SkipNatives=true -- --probe-icons [pak-dir] [--aes-file path]");
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
    return IsPetTexturePath(file) || IsItemTexturePath(file);
}

static bool IsPetTexturePath(GameFile file)
{
    var p = file.Path.Replace('\\', '/');
    return p.Contains("/System/Common/Icon/Pet1024/", StringComparison.OrdinalIgnoreCase);
}

static bool IsItemTexturePath(GameFile file)
{
    var p = file.Path.Replace('\\', '/');
    if (p.Contains("/System/Common/Icon/Pet1024/", StringComparison.OrdinalIgnoreCase) ||
        p.Contains("/System/Common/Icon/Pet256/", StringComparison.OrdinalIgnoreCase))
    {
        return false;
    }

    return p.Contains("/System/Common/Icon/", StringComparison.OrdinalIgnoreCase) ||
           p.Contains("/System/BattleUI/Raw/Atlas/", StringComparison.OrdinalIgnoreCase);
}

static int GetTextureExportPriority(GameFile file)
{
    var p = file.Path.Replace('\\', '/');
    if (p.Contains("/System/Common/Icon/Pet1024/", StringComparison.OrdinalIgnoreCase)) return 0;
    if (p.Contains("/System/Common/Icon/BagItem/", StringComparison.OrdinalIgnoreCase)) return 1;
    if (p.Contains("/System/Common/Icon/Item190/", StringComparison.OrdinalIgnoreCase)) return 2;
    if (p.Contains("/System/Common/Icon/", StringComparison.OrdinalIgnoreCase)) return 3;
    if (p.Contains("/System/BattleUI/Raw/Atlas/FeatureIcon/", StringComparison.OrdinalIgnoreCase)) return 4;
    if (p.Contains("/System/BattleUI/Raw/Atlas/SkillIcon/", StringComparison.OrdinalIgnoreCase)) return 5;
    if (p.Contains("/System/BattleUI/Raw/Atlas/", StringComparison.OrdinalIgnoreCase)) return 6;
    return 9;
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

        var assetName = Path.GetFileNameWithoutExtension(file.Name);
        var normalizedPath = file.Path.Replace('\\', '/');
        var outputSubdir = IsPetTexturePath(file)
            ? Path.Combine("assets", "webp", "pets")
            : Path.Combine("assets", "webp", "items");
        var dest = Path.Combine(outDir, outputSubdir, $"{assetName}.webp");
        Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
        File.WriteAllBytes(dest, data.ToArray());
        exported = true;
    }

    return exported;
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

static bool IsBattleLuaPath(string path)
{
    var p = "/" + path.Replace('\\', '/').ToLowerInvariant();
    string[] markers = [
        "/scriptc/common/localserver/",
        "/scriptc/newroco/modules/core/battle/",
        "/scriptc/newroco/ai/behaviortree/actions/battle/",
        "/scriptc/newroco/ai/behaviortree/actions/battlenpc/",
        "/scriptc/newroco/ai/behaviortree/decorators/battle/",
        "/scriptc/newroco/ai/behaviortree/services/luaserviceinitbattlestate",
        "/scriptc/newroco/ai/behaviortree/services/luaserviceupdatebattleinfo",
        "/scriptc/newroco/editor/battlecenterdebug/",
        "/scriptc/data/tinyio_config/battle",
        "/scriptc/data/tinyio_config/buff",
        "/scriptc/data/tinyio_config/level_skill",
        "/scriptc/data/tinyio_config/monster_skillbank",
        "/scriptc/data/tinyio_config/skill",
    ];
    return markers.Any(p.Contains);
}

static void CleanLuaOutputDir(string dir, string pattern)
{
    if (Directory.Exists(dir))
    {
        foreach (var path in Directory.GetFiles(dir, pattern, SearchOption.AllDirectories))
            File.Delete(path);
        var oldIndex = Path.Combine(dir, "index.json");
        if (File.Exists(oldIndex))
            File.Delete(oldIndex);
    }
    Directory.CreateDirectory(dir);
}

static void WriteJsonIndex(string dir, IEnumerable<string> paths)
{
    Directory.CreateDirectory(dir);
    var indexPath = Path.Combine(dir, "index.json");
    File.WriteAllText(indexPath, JsonSerializer.Serialize(
        paths.OrderBy(item => item, StringComparer.OrdinalIgnoreCase),
        new JsonSerializerOptions { WriteIndented = true }));
}

static string ToLuaDisasmRelativePath(string luacPath)
{
    var path = luacPath.Replace('\\', '/');
    return path.EndsWith(".luac", StringComparison.OrdinalIgnoreCase)
        ? $"{path[..^5]}.luasm"
        : $"{path}.luasm";
}

static string DisassembleLuaBytecode(byte[] data, string sourcePath)
{
    using var Ar = new FLuaArchive(sourcePath, data, null);
    var bytecode = FLuaReader.ReadLua54(Ar);
    var sb = new StringBuilder();
    sb.AppendLine($"-- path: {sourcePath}");
    sb.AppendLine("-- format: decrypted standard Lua 5.4 bytecode");
    sb.AppendLine("-- note: disassembly, not original source");
    sb.AppendLine();
    AppendLuaFunction(sb, bytecode.MainFunc, "main", 0);
    return sb.ToString();
}

static void AppendLuaFunction(StringBuilder sb, LuaFunction func, string name, int depth)
{
    var indent = new string(' ', depth * 2);
    var instructionCount = func.Code.Length / 4;
    sb.AppendLine($"{indent}{name} source={QuoteForLuaText(func.SourceName)} lines={func.LineDefined}-{func.LastLineDefined} params={func.NumParams} vararg={func.IsVarArg} stack={func.MaxStackSize} upvalues={func.Upvalues.Length}");

    if (func.Constants.Length > 0)
    {
        sb.AppendLine($"{indent}constants ({func.Constants.Length}):");
        for (var i = 0; i < func.Constants.Length; i++)
            sb.AppendLine($"{indent}  K[{i}] = {FormatLuaConstant(func.Constants[i])}");
    }

    if (func.Upvalues.Length > 0)
    {
        sb.AppendLine($"{indent}upvalues ({func.Upvalues.Length}):");
        for (var i = 0; i < func.Upvalues.Length; i++)
        {
            var nameHint = i < func.Debug.UpvalueNames.Length ? func.Debug.UpvalueNames[i].NameData : string.Empty;
            var up = func.Upvalues[i];
            sb.AppendLine($"{indent}  U[{i}] = instack={up.Instack} idx={up.Idx} kind={up.Kind} name={QuoteForLuaText(nameHint)}");
        }
    }

    if (func.Debug.LocVars.Length > 0)
    {
        sb.AppendLine($"{indent}locals ({func.Debug.LocVars.Length}):");
        for (var i = 0; i < func.Debug.LocVars.Length; i++)
        {
            var local = func.Debug.LocVars[i];
            sb.AppendLine($"{indent}  L[{i}] = {QuoteForLuaText(local.NameData)} pc={local.StartPc}-{local.EndPc}");
        }
    }

    sb.AppendLine($"{indent}instructions ({instructionCount}):");
    for (var pc = 0; pc < instructionCount; pc++)
    {
        var raw = BitConverter.ToUInt32(func.Code, pc * 4);
        var opcode = (int) (raw & 0x7F);
        var a = (raw >> 7) & 0xFF;
        var k = (raw >> 15) & 0x01;
        var b = (raw >> 16) & 0xFF;
        var c = (raw >> 24) & 0xFF;
        var bx = (raw >> 15) & 0x1FFFF;
        var ax = (raw >> 7) & 0x1FFFFFF;
        var sbx = (int) bx - 65535;
        var sj = (int) ax - 16777215;
        var opName = GetLua54OpcodeName(opcode);
        sb.AppendLine($"{indent}  [{pc + 1:0000}] {opName,-14} A={a} B={b} C={c} k={k} Bx={bx} sBx={sbx} Ax={ax} sJ={sj} raw=0x{raw:X8}{LuaInstructionComment(opName, func, (int) a, (int) b, (int) c, (int) bx)}");
    }

    for (var i = 0; i < func.Protos.Length; i++)
    {
        sb.AppendLine();
        AppendLuaFunction(sb, func.Protos[i], $"function[{i}]", depth + 1);
    }
}

static string LuaInstructionComment(string opName, LuaFunction func, int a, int b, int c, int bx)
{
    return opName switch
    {
        "LOADK" when IsLuaConstantIndex(func, bx) => $" ; R[{a}] = K[{bx}] {FormatLuaConstant(func.Constants[bx])}",
        "GETTABUP" when IsLuaConstantIndex(func, c) => $" ; R[{a}] = U[{b}][K[{c}] {FormatLuaConstant(func.Constants[c])}]",
        "GETFIELD" when IsLuaConstantIndex(func, c) => $" ; R[{a}] = R[{b}][K[{c}] {FormatLuaConstant(func.Constants[c])}]",
        "SETFIELD" when IsLuaConstantIndex(func, b) => $" ; R[{a}][K[{b}] {FormatLuaConstant(func.Constants[b])}] = R[{c}]",
        "ADDK" or "SUBK" or "MULK" or "MODK" or "POWK" or "DIVK" or "IDIVK" or "BANDK" or "BORK" or "BXORK"
            when IsLuaConstantIndex(func, c) => $" ; K[{c}] {FormatLuaConstant(func.Constants[c])}",
        "CLOSURE" => $" ; R[{a}] = function[{bx}]",
        _ => string.Empty
    };
}

static bool IsLuaConstantIndex(LuaFunction func, int index)
{
    return index >= 0 && index < func.Constants.Length;
}

static string FormatLuaConstant(LuaConstant constant)
{
    var type = constant.Type & 0x3F;
    return type switch
    {
        0 => "nil",
        1 => "false",
        17 => "true",
        3 when constant.Data.Length == 8 => BitConverter.ToDouble(constant.Data, 0).ToString("R", System.Globalization.CultureInfo.InvariantCulture),
        19 when constant.Data.Length == 8 => BitConverter.ToInt64(constant.Data, 0).ToString(System.Globalization.CultureInfo.InvariantCulture),
        4 or 20 => QuoteForLuaText(constant.StrData),
        _ => $"<{LuaConstantTypeName(type)} type=0x{constant.Type:X2} bytes={Convert.ToHexString(constant.Data)}>"
    };
}

static string LuaConstantTypeName(int type)
{
    return type switch
    {
        0 => "nil",
        1 => "boolean",
        3 => "float",
        4 => "short-string",
        17 => "true",
        19 => "integer",
        20 => "long-string",
        _ => "unknown"
    };
}

static string QuoteForLuaText(string value)
{
    return JsonSerializer.Serialize(value);
}

static string GetLua54OpcodeName(int opcode)
{
    string[] names = [
        "MOVE", "LOADI", "LOADF", "LOADK", "LOADKX", "LOADFALSE", "LFALSESKIP", "LOADTRUE",
        "LOADNIL", "GETUPVAL", "SETUPVAL", "GETTABUP", "GETTABLE", "GETI", "GETFIELD",
        "SETTABUP", "SETTABLE", "SETI", "SETFIELD", "NEWTABLE", "SELF",
        "ADDI", "ADDK", "SUBK", "MULK", "MODK", "POWK", "DIVK", "IDIVK",
        "BANDK", "BORK", "BXORK", "SHRI", "SHLI",
        "ADD", "SUB", "MUL", "MOD", "POW", "DIV", "IDIV", "BAND", "BOR", "BXOR", "SHL", "SHR",
        "MMBIN", "MMBINI", "MMBINK",
        "UNM", "BNOT", "NOT", "LEN",
        "CONCAT",
        "CLOSE", "TBC",
        "JMP",
        "EQ", "LT", "LE",
        "EQK", "EQI", "LTI", "LEI", "GTI", "GEI",
        "TEST", "TESTSET",
        "CALL", "TAILCALL",
        "RETURN", "RETURN0", "RETURN1",
        "FORLOOP", "FORPREP",
        "TFORPREP", "TFORCALL", "TFORLOOP",
        "SETLIST",
        "CLOSURE",
        "VARARG", "VARARGPREP",
        "EXTRAARG"
    ];
    return opcode >= 0 && opcode < names.Length ? names[opcode] : $"OP_{opcode}";
}

static string ResolvePath(string value, string baseDir)
{
    return Path.IsPathRooted(value)
        ? Path.GetFullPath(value)
        : Path.GetFullPath(Path.Combine(baseDir, value));
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
