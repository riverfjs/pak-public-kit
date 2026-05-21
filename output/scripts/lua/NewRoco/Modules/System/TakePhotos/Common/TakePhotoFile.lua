local TakePhotoFile = Class("TakePhotoFile")
local Delegate = require("Utils.Delegate")

function TakePhotoFile:Ctor()
  self.Path = nil
  self.Url = nil
  self.DesiredMd5 = nil
  self.bValid = false
  self.ThumbnailHeight = 0
  self.ThumbnailPath = ""
  self.HttpService = nil
  self.HttpServiceRef = nil
  self.HttpRetryCount = 0
  self.bNeedGenerateThumbnail = false
  self.OnValidDataLoaded = Delegate()
  self.OnHeaderReceived = Delegate()
  self.OnBytesChanged = Delegate()
end

function TakePhotoFile:DeleteFile()
  if self.Path then
    UE.UNRCStatics.DeleteToFile(self.Path)
    UE.UNRCStatics.DeleteToFile(self.Path .. "x")
  end
  if self.ThumbnailPath then
    UE.UNRCStatics.DeleteToFile(self.ThumbnailPath)
  end
end

function TakePhotoFile:ReleaseResources()
  if self.HttpService and UE.UObject.IsValid(self.HttpService) then
    UnLua.Unref(self.HttpService)
    self.HttpService = nil
    self.HttpServiceRef = nil
  end
  self.Path = nil
  self.Url = nil
  self.OnValidDataLoaded:Clear()
  self.Overridden.ReleaseResources(self)
end

function TakePhotoFile:OnCompleted(_, bSuccess)
  self.bValid = bSuccess
  if self.Url and not self.bValid and 0 == self.HttpRetryCount then
    self:InternalLoadFromUrl()
  end
  if self.bValid then
    self.OnValidDataLoaded:Invoke(self)
  elseif 0 ~= self.HttpRetryCount then
    Log.Debug("[TakePhotoFile]", self.DesiredMd5, self.ReadonlyFileMd5)
  end
end

function TakePhotoFile:SetByFileBrief(Brief)
  self.Url = Brief.Url
  self.Path = Brief.FilePath
  self.DesiredMd5 = Brief.DesiredMd5
  self.ThumbnailHeight = Brief.ThumbnailHeight
  self.ThumbnailPath = Brief:GetThumbnailPath()
end

function TakePhotoFile:UpdateTexture(Texture2D)
  self:SetUpdateDesiredTexture(Texture2D)
end

function TakePhotoFile:AsyncLoadResource()
  if self.Path and self:AsyncLoadFromFilePath(self.Path, self.DesiredMd5 or "", self.ThumbnailHeight or 0, self.ThumbnailPath or "") then
    self.OnPhotoFileDataLoaded:Clear()
    self.OnPhotoFileDataLoaded:Add(self, self.OnCompleted)
    return
  end
  if self.Url and 0 == self.HttpRetryCount then
    self:InternalLoadFromUrl()
  end
end

function TakePhotoFile:InternalLoadFromUrl()
  if self.Url then
    if not self.HttpService then
      self.HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
      if self.HttpService then
        self.HttpServiceRef = UnLua.Ref(self.HttpService)
      end
    end
    if self.HttpService then
      self.HttpService:ResetHeaders()
      self.HttpService:ResetFields()
      self.HttpService:SetUrl(self.Url)
      if self.OnHeaderReceived:HasAny() then
        self.HttpService:SetHeaderReceivedDelegate({
          self.HttpService,
          function(_, Key, Value)
            self.OnHeaderReceived:Invoke(Key, Value)
          end
        })
      end
      if self.OnBytesChanged:HasAny() then
        self.HttpService:SetProgressUpdateDelegate({
          self.HttpService,
          function(_, Sent, Received)
            self.OnBytesChanged:Invoke(Sent, Received)
          end
        })
      end
      self.HttpService:SetVerb("GET")
      self.HttpService:Request({
        self.HttpService,
        function(Service, Status)
          if UE.UObject.IsValid(self) and self.Path then
            if Status == UE4.EHttpServiceStatus.RspSuccess then
              self.HttpRetryCount = self.HttpRetryCount + 1
              local Directory = UE.UBlueprintPathsLibrary.GetPath(self.Path)
              if not UE.UNRCStatics.DirectoryExists(Directory) then
                UE.UNRCStatics.MakeDirectory(Directory)
              end
              Service:SaveToFile(self.Path)
              Log.Debug("[TakePhotoFile] DownloadFile Success", self.Path, self.ReadonlyStatus)
              if self.ReadonlyStatus ~= UE.ETakePhotoFileStatus.Loading then
                self.ReadonlyStatus = UE.ETakePhotoFileStatus.None
              end
              self:AsyncLoadResource()
            else
              Log.Debug("[TakePhotoFile] DownloadFile Failed", self.Path)
            end
          end
        end
      })
    end
  end
end

return TakePhotoFile
