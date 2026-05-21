local TakePhotoFileBrief = Class("TakePhotoFileBrief")
local Delegate = require("Utils.Delegate")

function TakePhotoFileBrief:Ctor()
  self.FilePath = nil
  self.DesiredMd5 = nil
  self.Url = nil
  self.DesiredTexture = nil
  self.ThumbnailHeight = 0
  self.OnTextureChanged = Delegate()
end

function TakePhotoFileBrief:AsLocalFile(FilePath, DesiredMd5)
  self.FilePath = FilePath
  self.DesiredMd5 = DesiredMd5
  return self
end

function TakePhotoFileBrief:AsRemoteFile(FilePath, Url, DesiredMd5)
  self.FilePath = FilePath
  self.DesiredMd5 = DesiredMd5
  self.Url = Url
  return self
end

function TakePhotoFileBrief:IsThumbnailFile()
  return self.ThumbnailHeight and self.ThumbnailHeight > 0
end

function TakePhotoFileBrief:SetThumbnail(ThumbnailHeight)
  self.ThumbnailHeight = ThumbnailHeight
  return self
end

function TakePhotoFileBrief:SetOverrideThumbnailPath(Path)
  self.OverrideThumbnailPath = Path
end

function TakePhotoFileBrief:GetThumbnailPath()
  if self.OverrideThumbnailPath then
    return self.OverrideThumbnailPath
  end
  if self:IsThumbnailFile() then
    return self.FilePath .. "_Thumbnail"
  else
    return ""
  end
end

return TakePhotoFileBrief
