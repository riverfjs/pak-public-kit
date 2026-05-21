local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local Super = require("NewRoco/Modules/System/TakePhotos/Helper/AlbumList")
local RemoteAlbumList = Super:Extend("RemoteAlbumList")

function RemoteAlbumList:GetPhotoLimitTitle()
  return LuaText.takephoto_cloud_storage_text
end

function RemoteAlbumList:GetHintText(bFromTakingPhoto)
  if bFromTakingPhoto then
    return LuaText.takephoto_cloud_storage_tips_bottom
  else
    return LuaText.takephoto_card_tips_bottom
  end
end

function RemoteAlbumList:ReloadConditionally()
end

function RemoteAlbumList:GetDataBySerialId(SerialId)
  assert(self.SerialIndicesMapping)
  local UIIndex = self.SerialIndicesMapping[SerialId]
  return UIIndex and self.CurrDataList[UIIndex]
end

function RemoteAlbumList:GetViewBySerialId(SerialId)
  assert(self.SerialIndicesMapping)
  local UIIndex = self.SerialIndicesMapping[SerialId]
  return UIIndex > 0 and self.List:GetItemByIndex(UIIndex - 1)
end

function RemoteAlbumList:BuildDataList()
  local Num = self:GetPhotoNum()
  self.SerialIndicesMapping = {}
  local SerialList = {}
  for i = 1, Num do
    local SerialId = i
    local DataText, CreateTimestamp = self:InternalBuildCreateDateText(SerialId)
    table.insert(SerialList, {
      SerialId = SerialId,
      bSelected = false,
      PhotoData = self:GetPhotoBySerialId(SerialId),
      bRemoveMode = self:InRemoveMode(),
      DoSelectDelegate = function()
        return self:OnItemSelected(SerialId)
      end,
      CreateDateText = DataText,
      CreateTimestamp = CreateTimestamp or SerialId,
      GetDesiredThumbnailSize = function()
        return self.FilmView.ThumbnailDesiredWidth, self.FilmView.ThumbnailDesiredHeight
      end,
      bRemoteData = true
    })
  end
  table.sort(SerialList, function(a, b)
    return a.CreateTimestamp < b.CreateTimestamp
  end)
  for UIIndex, UIData in pairs(SerialList) do
    self.SerialIndicesMapping[UIData.SerialId] = UIIndex
  end
  for i = Num + 1, self:GetPhotoMaxNum() do
    table.insert(SerialList, {})
  end
  self.CurrDataList = SerialList
  self:RefreshActivityData()
end

function RemoteAlbumList:GetPhotoNum()
  local Manager = self:GetPhotoManager()
  return Manager:GetRemotePhotoNum()
end

function RemoteAlbumList:GetPhotoMaxNum()
  return TakePhotosEnum.TPGlobalNum("takephoto_cloud_storage_num")
end

function RemoteAlbumList:GetPhotoBySerialId(SerialId)
  local Manager = self:GetPhotoManager()
  return Manager:GetRemotePhotoDataBySerial(SerialId)
end

function RemoteAlbumList:RemovePhotoBySerialId(SerialId)
  if not SerialId then
    return
  end
  local Manager = self:GetPhotoManager()
  return Manager:RemoveRemotePhotoBySerial(SerialId)
end

function RemoteAlbumList:RemovePhotosBySerials(NeedRemove)
  local Manager = self:GetPhotoManager()
  return Manager:RemoveRemotePhotosBySerials(NeedRemove)
end

return RemoteAlbumList
