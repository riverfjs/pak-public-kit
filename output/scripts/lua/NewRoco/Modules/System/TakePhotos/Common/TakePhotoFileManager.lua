local TakePhotoFileBrief = require("NewRoco.Modules.System.TakePhotos.Common.TakePhotoFileBrief")
local TakePhotoFileManager = Class("TakePhotoFileManager")

function TakePhotoFileManager:Ctor()
  self.Files = {}
end

function TakePhotoFileManager:ReleaseResources()
  for Brief, File in pairs(self.Files) do
    local Obj = ObjectRefUnBoxing(File)
    if UE.UObject.IsValid(Obj) then
      Obj:ReleaseResources()
      UnLua.Unref(Obj)
    end
  end
  self.Files = {}
end

function TakePhotoFileManager:CreateBrief()
  return TakePhotoFileBrief()
end

function TakePhotoFileManager:CreateFileByBrief(Brief)
  if Brief and not self.Files[Brief] then
    local Instance = NewObject(UE.UTakePhotoFile, UE4.UNRCPlatformGameInstance.GetInstance())
    local File = ObjectRefBoxing(Instance)
    self.Files[Brief] = File
    Instance:SetByFileBrief(Brief)
    return Brief
  end
end

function TakePhotoFileManager:GetFileByBrief(Brief)
  local File = self.Files[Brief]
  if File then
    return ObjectRefUnBoxing(File)
  end
end

function TakePhotoFileManager:DeleteBrief(Brief)
  local File = Brief and self.Files[Brief]
  if File then
    local Obj = ObjectRefUnBoxing(File)
    if UE.UObject.IsValid(Obj) then
      Obj:DeleteFile()
      Obj:ReleaseResources()
      UnLua.Unref(Obj)
    end
    self.Files[Brief] = nil
  end
end

function TakePhotoFileManager:RemoveBriefResource(Brief)
  local File = Brief and self.Files[Brief]
  if File then
    local Obj = ObjectRefUnBoxing(File)
    if UE.UObject.IsValid(Obj) then
      Obj:ReleaseResources()
      UnLua.Unref(Obj)
    end
    self.Files[Brief] = nil
  end
end

return TakePhotoFileManager
