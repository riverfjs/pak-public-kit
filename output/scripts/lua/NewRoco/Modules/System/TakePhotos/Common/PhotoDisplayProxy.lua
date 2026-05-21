local ResourceMgr = require("NewRoco.Modules.System.TakePhotos.Common.TakePhotoFileManager")
local Delegate = require("Utils.Delegate")
local PhotoCacheDefine = require("NewRoco.Modules.System.TakePhotos.Common.PhotoCacheDefine")
local PhotoDisplayProxy = Class()

function PhotoDisplayProxy:Ctor(UserWidget, Image, Tag)
  assert(Tag, "Need tag")
  assert(PhotoCacheDefine.Tags[Tag], "Tag not define")
  self.Tag = Tag
  self.Photograph = Image
  self.UserWidget = UserWidget
  self.ResourceMgr = ResourceMgr()
  self.OnReadyDelegate = Delegate()
  self.OnStartDownloadDelegate = Delegate()
  self.OnDownloadingDelegate = Delegate()
  self.LoadingInfo = nil
  self.TextureRef = nil
  self.Texture = nil
  self.Mode = -1
  self.DisplayModeParams = {}
end

function PhotoDisplayProxy:LogDebug(...)
  Log.Debug("[PhotoDisplayProxy]", ...)
end

function PhotoDisplayProxy:LogError(...)
  Log.Error("[PhotoDisplayProxy]", ...)
end

function PhotoDisplayProxy:SetDisplayMiniMode(DisplayW, DisplayH, ImageW, ImageH)
  if not DisplayW then
    Log.Error("PhotoDisplayProxy Invalid DisplayW")
  elseif not DisplayH then
    Log.Error("PhotoDisplayProxy Invalid DisplayH")
  end
  self.Mode = 0
  self.DisplayModeParams = {
    DisplayW,
    DisplayH,
    ImageW,
    ImageH
  }
end

function PhotoDisplayProxy:SetDisplayRawMode(ImageW, ImageH)
  if not ImageW then
    Log.Error("PhotoDisplayProxy Invalid ImageW")
  elseif not ImageH then
    Log.Error("PhotoDisplayProxy Invalid ImageH")
  end
  self.Mode = 1
  self.DisplayModeParams = {ImageW, ImageH}
end

function PhotoDisplayProxy:DisplayUrl(Url, Md5, FileName)
  assert(Url and "" ~= Url)
  assert(Md5 and "" ~= Md5)
  assert(FileName and "" ~= FileName)
  self:LogDebug("DisplayUrl", Url, Md5, FileName)
  if not self.UserWidget or not UE.UObject.IsValid(self.UserWidget) then
    self:LogError(" Invalid UserWidget,", Url, Md5, FileName)
    return
  end
  if self.LoadingInfo then
    if self.LoadingInfo.Url == Url and self.LoadingInfo.Md5 == Md5 and self.LoadingInfo.FileName == FileName then
      self:LogDebug(" Loading ", self.LoadingInfo.Url, self.LoadingInfo.Md5, self.LoadingInfo.FileName, self.LoadingInfo.bReady)
      if self.LoadingInfo.bReady then
        self:InternalRefreshTexture(self.Texture)
        self.OnReadyDelegate:Invoke(self.Texture)
      end
      return
    end
    self.ResourceMgr:ReleaseResources()
    if self.Texture then
      UnLua.Unref(self.Texture)
      self.Texture = nil
    end
    self.TextureRef = nil
  end
  local FullPath = PhotoCacheDefine.GetTagFileFullPath(self.Tag, FileName)
  local Brief = self.ResourceMgr:CreateBrief()
  Brief:AsRemoteFile(FullPath, Url, Md5)
  self.ResourceMgr:CreateFileByBrief(Brief)
  local VisualFile = self.ResourceMgr:GetFileByBrief(Brief)
  self.LoadingInfo = {
    Url = Url,
    Md5 = Md5,
    FileName = FileName,
    Brief = Brief,
    FullPath = FullPath,
    bReady = false
  }
  VisualFile.OnValidDataLoaded:Add(self, self.OnInternalFileReady)
  VisualFile.OnBytesChanged:Add(self, self.OnInternalByteChanged)
  VisualFile.OnHeaderReceived:Add(self, self.OnInternalHeadReceived)
  VisualFile:AsyncLoadResource()
end

function PhotoDisplayProxy:GetValidPhotoPath()
  if self.Texture and self.LoadingInfo then
    return self.LoadingInfo.FullPath or ""
  end
  return ""
end

function PhotoDisplayProxy:GetFileName()
  if self.LoadingInfo then
    return self.LoadingInfo.FileName
  end
end

function PhotoDisplayProxy:Destroy()
  if self.LoadingInfo then
    self.LoadingInfo = nil
  end
  if self.TextureRef then
    self.TextureRef = nil
  end
  self.ResourceMgr:ReleaseResources()
end

function PhotoDisplayProxy:OnInternalByteChanged(Sent, Received)
  if self.TotalBytes then
    self.LoadingInfo.ReceivedBytes = Received
    self.OnDownloadingDelegate:Invoke(Received, self.LoadingInfo.TotalBytes)
  end
end

function PhotoDisplayProxy:OnInternalHeadReceived(Key, Value)
  if "Content-Length" == Key then
    self:LogDebug("StartLoad FileSize=", Value, self.LoadingInfo.FileName, self.LoadingInfo.Url)
    self.LoadingInfo.TotalBytes = Value
    self.LoadingInfo.ReceivedBytes = 0
    self.OnStartDownloadDelegate:Invoke(self.LoadingInfo.Url, self.LoadingInfo.Md5, self.LoadingInfo.FileName, Value)
  end
end

function PhotoDisplayProxy:OnInternalFileReady(VisualFile)
  if VisualFile and UE.UObject.IsValid(VisualFile) then
    self:LogDebug("Download Ready FileSize=", self.LoadingInfo.FileName, self.LoadingInfo.Md5, self.LoadingInfo.ReceivedBytes, self.LoadingInfo.TotalBytes)
    local Texture
    if self.TextureRef and self.Texture and UE.UObject.IsValid(self.Texture) then
      Texture = self.Texture
      if not VisualFile:SetUpdateDesiredTexture(self.Texture) then
        UnLua.Unref(self.Texture)
        self.Texture = nil
        self.TextureRef = nil
        Texture = nil
        self:LogDebug("Try Update texture from cache, but failed")
      else
        self:LogDebug("UpdateTexture", self.Texture:GetName())
      end
    end
    if nil == Texture then
      local TextureRef = Texture and UnLua.Ref(Texture)
      Texture = VisualFile:CreateUpdatedTexture2D(self.Tag)
      self.TextureRef = TextureRef
      self.Texture = Texture
      self:LogDebug("CreateTexture", self.Texture:GetName())
    end
    self.LoadingInfo.bReady = true
    self:InternalRefreshTexture(Texture)
    self.OnReadyDelegate:Invoke(Texture)
  end
end

function PhotoDisplayProxy:InternalRefreshTexture(Texture)
  if not self.Photograph or not UE.UObject.IsValid(self.Photograph) then
    return
  end
  if 0 == self.Mode then
    local DisplayW, DisplayH = self.DisplayModeParams[1], self.DisplayModeParams[2]
    local ThumbnailWidth = Texture:Blueprint_GetSizeX()
    local ThumbnailHeight = Texture:Blueprint_GetSizeY()
    local ScaleToViewWidth = DisplayW / ThumbnailWidth
    local ScaleToViewHeight = DisplayH / ThumbnailHeight
    local MaxiScale = math.max(ScaleToViewWidth, ScaleToViewHeight)
    DisplayW = MaxiScale * ThumbnailWidth
    DisplayH = MaxiScale * ThumbnailHeight
    local Anchors = self.Photograph.Slot:GetAnchors()
    Anchors.Minimum.X = 0.5
    Anchors.Minimum.Y = 0.5
    Anchors.Maximum.X = 0.5
    Anchors.Maximum.Y = 0.5
    self.Photograph.Slot:SetAnchors(Anchors)
    self.Photograph.Slot:SetAutoSize(true)
    self.Photograph:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(Texture, DisplayW and math.floor(DisplayW), DisplayH and math.floor(DisplayH)))
  elseif 1 == self.Mode then
    local ImageW, ImageH = self.DisplayModeParams[1], self.DisplayModeParams[2]
    local Anchors = self.Photograph.Slot:GetAnchors()
    Anchors.Minimum.X = 0
    Anchors.Minimum.Y = 0
    Anchors.Maximum.X = 1
    Anchors.Maximum.Y = 1
    self.Photograph.Slot:SetAnchors(Anchors)
    self.Photograph.Slot:SetAutoSize(false)
    self.Photograph:SetBrush(UE.UWidgetBlueprintLibrary.MakeBrushFromTexture(Texture, ImageW and math.floor(ImageW), ImageH and math.floor(ImageH)))
  end
end

return PhotoDisplayProxy
