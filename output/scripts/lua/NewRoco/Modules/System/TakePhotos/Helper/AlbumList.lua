local EnmOperationMode = {Default = 0, Remove = 1}
local AlbumList = Class("AlbumList")

function AlbumList:Ctor(FilmView)
  self.FilmView = FilmView
  self.CurrOperationMode = EnmOperationMode.Default
  self.CurrDataList = {}
  self.List = FilmView.List
end

function AlbumList:DispatchEvent(...)
  self:GetModule():DispatchEvent(...)
end

function AlbumList:GetModule()
  if self._Module then
    return self._Module
  end
  self._Module = NRCModuleManager:GetModule("TakePhotosModule")
  return self._Module
end

function AlbumList:GetModuleData()
  return (self:GetModule() or {}).data or {}
end

function AlbumList:GetPhotoManager()
  return self:GetModule().Controller.PhotoManager
end

function AlbumList:Reset()
  self.CurrOperationMode = EnmOperationMode.Default
end

function AlbumList:GetPhotoBySerialId(SerialId)
end

function AlbumList:ReloadConditionally()
end

function AlbumList:InDefaultMode()
  return self.CurrOperationMode == EnmOperationMode.Default
end

function AlbumList:InRemoveMode()
  return self.CurrOperationMode == EnmOperationMode.Remove
end

function AlbumList:GetDataList()
  return self.CurrDataList
end

function AlbumList:ToggleSelectFlagBySerialId(SerialId)
  local UIData = self:GetDataBySerialId(SerialId)
  if UIData then
    UIData.bSelected = not UIData.bSelected
  end
end

function AlbumList:SelectPhotoBySerialId(SerialId)
  local UIData = self:GetDataBySerialId(SerialId)
  if UIData then
    UIData.bSelected = true
  end
end

function AlbumList:ToggleToDefault()
  self.CurrOperationMode = EnmOperationMode.Default
end

function AlbumList:ToggleMode()
  if self.CurrOperationMode == EnmOperationMode.Remove then
    self.CurrOperationMode = EnmOperationMode.Default
  elseif self.CurrOperationMode == EnmOperationMode.Default then
    self.CurrOperationMode = EnmOperationMode.Remove
  end
end

function AlbumList:OnItemSelected(SerialId)
  return self.FilmView:OnItemSelected(SerialId)
end

function AlbumList:RefreshSelectAllView()
  local bHasNoSelect = false
  for i, Data in ipairs(self.CurrDataList) do
    if Data.SerialId and not Data.bSelected then
      bHasNoSelect = true
      break
    end
  end
  return bHasNoSelect
end

function AlbumList:RefreshRemoveBtnStatus()
  local bHasSelect = false
  for i, Data in ipairs(self.CurrDataList) do
    if Data.SerialId and Data.bSelected then
      bHasSelect = true
      break
    end
  end
  return bHasSelect
end

function AlbumList:ToggleSelectAllWaitRemove()
  local bHasNoSelect = false
  for i, Data in ipairs(self.CurrDataList) do
    if Data.SerialId and not Data.bSelected then
      bHasNoSelect = true
      break
    end
  end
  local bSelectAll = bHasNoSelect
  for i, Data in ipairs(self.CurrDataList) do
    if Data.SerialId then
      Data.bSelected = bSelectAll
    end
  end
  return bSelectAll
end

function AlbumList:GetHintText()
end

function AlbumList:GetPhotoNum()
end

function AlbumList:GetPhotoMaxNum()
end

function AlbumList:RemovePhotoBySerialId(SerialId)
end

function AlbumList:GetPhotoLimitTitle()
end

function AlbumList:BuildDataList()
end

function AlbumList:RemoveSelection()
  local NeedRemove = {}
  for i, Data in ipairs(self.CurrDataList) do
    if Data.bSelected then
      table.insert(NeedRemove, Data.SerialId)
    end
  end
  self:ToggleToDefault()
  self:RemovePhotosBySerials(NeedRemove)
end

function AlbumList:RemovePhotosBySerials(NeedRemove)
end

function AlbumList:OnThumbnailTextureGenerated(PhotoData)
  local bValidPhotoData = false
  for i, Data in ipairs(self.CurrDataList) do
    if Data.PhotoData == PhotoData then
      bValidPhotoData = true
      break
    end
  end
  if not bValidPhotoData then
    return
  end
  local SerialId = PhotoData.SerializeId
  local Item = self:GetViewBySerialId(SerialId)
  if Item then
    Item:OnItemUpdate(self.CurrDataList[SerialId])
  end
end

function AlbumList:GetViewBySerialId(SerialId)
  return self.List:GetItemByIndex(SerialId - 1)
end

function AlbumList:GetDataBySerialId(SerialId)
  return self.CurrDataList[SerialId]
end

function AlbumList:RefreshActivityData()
  local PhotoActivityManager = _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.GetPhotoActivityManager)
  local InAlbumSubmitStatus = PhotoActivityManager:InAlbumSubmitStatus()
  for i, Data in ipairs(self.CurrDataList) do
    Data.bHasBeenActivityReported = PhotoActivityManager and InAlbumSubmitStatus and PhotoActivityManager:IsPhotoDataHasBeenSubmit(Data.PhotoData)
    Data.bActivityRequiredPhoto = PhotoActivityManager and InAlbumSubmitStatus and PhotoActivityManager:CanRequestPhotoData(Data.PhotoData)
    Data.InAlbumSubmitStatus = InAlbumSubmitStatus
  end
end

function AlbumList:RefreshActivityReportedFlag()
  self:RefreshActivityData()
  for i = 0, self.List:GetItemCount() - 1 do
    local Item = self.List:GetItemByIndex(i)
    if Item then
      Item:OnRefreshActivityReportedFlag()
    end
  end
end

function AlbumList:RefreshByUploadRefresh()
end

function AlbumList:InternalBuildCreateDateText(SerialId)
  local Data = self:GetPhotoBySerialId(SerialId)
  if not Data then
    return ""
  end
  local Name = Data:UnpackPhotoName()
  if not Name then
    return ""
  end
  local EndIdx = string.find(Name, "%.") or #Name + 1
  local Len = 13
  local J = EndIdx - 1
  local I = J - Len + 1
  local Timestamp = math.tointeger(string.sub(Name, I, J))
  if Timestamp then
    local Date = os.date("*t", math.floor(Timestamp / 1000))
    if Date then
      return string.format("%s/%s/%s", Date.year, Date.month, Date.day), Timestamp
    end
  end
  return ""
end

return AlbumList
