local Super = require("NewRoco/Modules/System/TakePhotos/Helper/AlbumList")
local LocalAlbumList = Super:Extend("LocalAlbumList")

function LocalAlbumList:BuildDataList()
  local Num = self:GetPhotoNum()
  local SerialList = {}
  local PhotoServer = NRCModuleManager:GetModule("TakePhotosModule").PhotoServer
  for i = 1, Num do
    local SerialId = i
    local PhotoData = self:GetPhotoBySerialId(SerialId)
    local Name = PhotoData:UnpackPhotoName()
    local bLocalFileInRemote = PhotoServer:HasPhotoName(Name)
    table.insert(SerialList, {
      SerialId = SerialId,
      bSelected = false,
      PhotoData = PhotoData,
      bRemoveMode = self:InRemoveMode(),
      DoSelectDelegate = function()
        return self:OnItemSelected(SerialId)
      end,
      GetDesiredThumbnailSize = function()
        return self.FilmView.ThumbnailDesiredWidth, self.FilmView.ThumbnailDesiredHeight
      end,
      bLocalFileInRemote = bLocalFileInRemote,
      CreateDateText = self:InternalBuildCreateDateText(SerialId)
    })
    if PhotoData then
      PhotoData:DetachSection()
    end
  end
  for i = Num + 1, self:GetPhotoMaxNum() do
    table.insert(SerialList, {})
  end
  self.CurrDataList = SerialList
  self:RefreshActivityData()
end

function LocalAlbumList:RefreshByUploadRefresh(PhotoData)
  if not PhotoData then
    return
  end
  local SerialId = PhotoData.SerializeId
  local Data = self:GetDataBySerialId(SerialId)
  if not Data then
    return
  end
  local Name = PhotoData:UnpackPhotoName()
  Data.bLocalFileInRemote = NRCModuleManager:GetModule("TakePhotosModule").PhotoServer:HasPhotoName(Name)
  local Item = self:GetViewBySerialId(SerialId)
  if Item then
    Item:RefreshByUploadRefresh()
  end
end

function LocalAlbumList:GetHintText(bFromTakingPhoto)
  return LuaText.takephoto_storage_cleared_tips_bottom
end

function LocalAlbumList:GetPhotoLimitTitle()
  return LuaText.takephoto_storage_text
end

function LocalAlbumList:GetPhotoNum()
  local Manager = self:GetPhotoManager()
  return Manager:GetLocalPhotoNum()
end

function LocalAlbumList:GetPhotoBySerialId(SerialId)
  local Manager = self:GetPhotoManager()
  return Manager:GetLocalPhotoDataBySerial(SerialId)
end

function LocalAlbumList:GetPhotoMaxNum()
  return self:GetPhotoManager().LocalMaxiPhotoNum
end

function LocalAlbumList:RemovePhotoBySerialId(SerialId)
  local Manager = self:GetPhotoManager()
  Manager:RemoveLocalPhotoBySerial(SerialId)
end

function LocalAlbumList:RemovePhotosBySerials(NeedRemove)
  local Manager = self:GetPhotoManager()
  Manager:RemoveLocalPhotosBySerials(NeedRemove)
end

return LocalAlbumList
