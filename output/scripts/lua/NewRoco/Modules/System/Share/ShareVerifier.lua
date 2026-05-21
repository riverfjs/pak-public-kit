local ShareVerifier = {}
ShareVerifier.FileKind = {Pic = "pic", Video = "video"}
ShareVerifier.Reason = {
  OK = "ok",
  InvalidPath = "invalid_path",
  FileNotFound = "file_not_found",
  HashFailed = "hash_failed",
  Tampered = "tampered",
  Untrusted = "untrusted"
}
local PendingFileMd5Map = {}

local function NormalizePath(path)
  if type(path) ~= "string" or "" == path then
    return nil
  end
  return UE.UNRCStatics.ConvertToAbsolutePath(path, true)
end

local function HashFile(absPath)
  if not UE.UNRCStatics.FileExists(absPath) then
    return nil
  end
  local md5 = UE.UNRCStatics.HashFileMD5(absPath)
  if type(md5) ~= "string" or "" == md5 then
    return nil
  end
  return md5
end

function ShareVerifier.Register(path, md5)
  local absPath = NormalizePath(path)
  if not absPath then
    Log.Warning("[ShareVerifier] Register: invalid path", path)
    return false
  end
  local finalMd5 = md5
  if not finalMd5 or "" == finalMd5 then
    finalMd5 = HashFile(absPath)
  end
  if not finalMd5 then
    Log.Warning("[ShareVerifier] Register: hash failed", absPath)
    return false
  end
  PendingFileMd5Map[absPath] = finalMd5
  Log.Debug("[ShareVerifier] Register", absPath, finalMd5)
  return true
end

function ShareVerifier.Unregister(path)
  local absPath = NormalizePath(path)
  if not absPath then
    return
  end
  PendingFileMd5Map[absPath] = nil
end

function ShareVerifier.Verify(path, kind)
  kind = kind or "unknown"
  local absPath = NormalizePath(path)
  if not absPath then
    Log.Error("[ShareVerifier] Verify: invalid path", path, kind)
    return false, ShareVerifier.Reason.InvalidPath
  end
  if not UE.UNRCStatics.FileExists(absPath) then
    Log.Error("[ShareVerifier] Verify: file not found", absPath, kind)
    return false, ShareVerifier.Reason.FileNotFound
  end
  local expected = PendingFileMd5Map[absPath]
  if expected then
    local actual = HashFile(absPath)
    if not actual then
      Log.Error("[ShareVerifier] Verify: hash failed", absPath, kind)
      return false, ShareVerifier.Reason.HashFailed
    end
    if actual ~= expected then
      Log.Error("[ShareVerifier] Verify: tampered (pending)", absPath, kind, "expected", expected, "actual", actual)
      return false, ShareVerifier.Reason.Tampered
    end
    return true, ShareVerifier.Reason.OK
  end
  Log.Error("[ShareVerifier] Verify: untrusted file (no expected md5 source)", absPath, kind)
  return false, ShareVerifier.Reason.Untrusted
end

return ShareVerifier
