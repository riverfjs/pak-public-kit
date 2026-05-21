local PhotoCacheDefine = require("NewRoco.Modules.System.TakePhotos.Common.PhotoCacheDefine")
local PhotoDisplayUtils = {}
PhotoDisplayUtils.PhotoCacheDefine = PhotoCacheDefine

function PhotoDisplayUtils.ParseActivityPhotoParams(CdnUrl)
  local Names = string.split(CdnUrl, "/")
  local FileName = Names[#Names]
  local Elements = string.split(FileName, "_")
  local timestamp, activity_sub_id, rawWidth, rawHeight = Elements[1], Elements[2], Elements[3], Elements[4]
  return FileName, math.tointeger(rawWidth), math.tointeger(rawHeight)
end

function PhotoDisplayUtils.ParseUrlFileName(CdnUrl)
  local Names = string.split(CdnUrl, "/")
  local FileName = Names[#Names]
  return FileName
end

function PhotoDisplayUtils.DisplayActivityPhotoMiniMode(CdnUrl, Md5, Proxy, DisplayW, DisplayH)
  assert(DisplayW > 0)
  assert(DisplayW > 0)
  local FileName, rawWidth, rawHeight = PhotoDisplayUtils.ParseActivityPhotoParams(CdnUrl)
  Proxy:SetDisplayMiniMode(DisplayW, DisplayH, rawWidth, rawHeight)
  Proxy:DisplayUrl(CdnUrl, Md5, FileName)
end

function PhotoDisplayUtils.DisplayActivityPhotoRawMode(CdnUrl, Md5, Proxy)
  local FileName, rawWidth, rawHeight = PhotoDisplayUtils.ParseActivityPhotoParams(CdnUrl)
  Proxy:SetDisplayRawMode(rawWidth, rawHeight)
  Proxy:DisplayUrl(CdnUrl, Md5, FileName)
end

return PhotoDisplayUtils
