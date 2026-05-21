local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local PetPhotoListView = Class("PetPhotoListView")
local Delegate = require("Utils.Delegate")

function PetPhotoListView:Ctor(ListView, ScrollBox)
  self.ScrollBox = ScrollBox
  self.ListView = ListView
  local Module = NRCModuleManager:GetModule("TakePhotosModule")
  self.Module = Module
  self.PhotoManager = Module and Module.Controller.PhotoManager
  self.OnPhotosRemovedDelegate = Delegate()
  self.bResourceCreated = false
end

function PetPhotoListView:Active()
  self.Module:RegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved, self.OnPhotosRemoved)
  self.Module:RegisterEvent(self, TakePhotosModuleEvent.OnPhotosRemoved, self.OnPhotosRemoved)
end

function PetPhotoListView:Deactivate()
  self.Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnPhotoRemoved, self.OnPhotosRemoved)
  self.Module:UnRegisterEvent(self, TakePhotosModuleEvent.OnPhotosRemoved, self.OnPhotosRemoved)
  self:Hide()
  self.ScrollBox = nil
  self.ListView = nil
  if self.bResourceCreated then
    self.PhotoManager:ReleaseThumbnailPool()
    self.bResourceCreated = false
  end
end

function PetPhotoListView:GetDisplayPhotoNum()
  return self.DisplayNum or 0
end

function PetPhotoListView:GetDataListByHandbookId(HandbookId)
  local PetBaseIdMap = {}
  local HandbookConf = _G.DataConfigManager:GetPetHandbook(HandbookId, true)
  if HandbookConf and HandbookConf.include_petbase_id then
    for i, v in pairs(HandbookConf.include_petbase_id) do
      for j, petbase_id in pairs(v.petbase_id) do
        PetBaseIdMap[petbase_id] = true
      end
    end
  end
  local Md5Map = {}
  
  local function Condition(PhotoData)
    local Md5 = PhotoData:GetDesiredMd5()
    if not Md5 or Md5Map[Md5] then
      return false
    end
    local PhotoInfo = PhotoData:GetPhotoInfo()
    if PhotoInfo then
      for i, petBaseId in ipairs(PhotoInfo.pet_base_id_list) do
        if PetBaseIdMap[petBaseId] then
          Md5Map[Md5] = true
          return true
        end
      end
    end
    return false
  end
  
  local SerialList = {}
  local TempPhotoDataList = {}
  local Num = self.PhotoManager:GetRemotePhotoNum()
  local DisplayNum = 0
  for i = 1, Num do
    local SerialId = i
    local PhotoData = self.PhotoManager:GetRemotePhotoDataBySerial(SerialId)
    if Condition(PhotoData) then
      local CreateDateText, CreateTimestamp = self:InternalBuildCreateDateText(PhotoData)
      table.insert(SerialList, {
        SerialId = SerialId,
        bSelected = false,
        PhotoData = PhotoData,
        bRemoveMode = false,
        DoSelectDelegate = function()
          return self:OnItemSelected(SerialId, PhotoData)
        end,
        GetDesiredThumbnailSize = function()
          return self.ThumbnailDesiredWidth, self.ThumbnailDesiredHeight
        end,
        bLocalFile = false,
        CreateDateText = CreateDateText,
        CreateTimestamp = CreateTimestamp
      })
      DisplayNum = DisplayNum + 1
    end
    if PhotoData then
      PhotoData:DetachSection()
    end
  end
  Num = self.PhotoManager:GetLocalPhotoNum()
  for i = 1, Num do
    local SerialId = i
    local PhotoData = self.PhotoManager:GetLocalPhotoDataBySerial(SerialId)
    if Condition(PhotoData) then
      local CreateDateText, CreateTimestamp = self:InternalBuildCreateDateText(PhotoData)
      table.insert(SerialList, {
        SerialId = SerialId,
        bSelected = false,
        PhotoData = PhotoData,
        bRemoveMode = false,
        DoSelectDelegate = function()
          return self:OnItemSelected(SerialId, PhotoData)
        end,
        GetDesiredThumbnailSize = function()
          return self.ThumbnailDesiredWidth, self.ThumbnailDesiredHeight
        end,
        bLocalFile = true,
        CreateDateText = CreateDateText,
        CreateTimestamp = CreateTimestamp
      })
      DisplayNum = DisplayNum + 1
    end
    if PhotoData then
      PhotoData:DetachSection()
    end
  end
  table.sort(SerialList, function(a, b)
    if a.CreateTimestamp ~= b.CreateTimestamp then
      return a.CreateTimestamp < b.CreateTimestamp
    end
    return a.SerialId < b.SerialId
  end)
  for i = 1, #SerialList do
    local Data = SerialList[i]
    Data.PhotoData:AttachSection(TempPhotoDataList, true)
  end
  local SerializeNum = #SerialList
  local DesiredNum = math.ceil(SerializeNum * 1.0 / 3) * 3
  for i = SerializeNum + 1, DesiredNum do
    table.insert(SerialList, {})
  end
  while #SerialList < 9 do
    table.insert(SerialList, {})
  end
  self.DisplayNum = DisplayNum
  return SerialList
end

function PetPhotoListView:InternalBuildCreateDateText(PhotoData)
  local Data = PhotoData
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
  return "", Timestamp
end

function PetPhotoListView:OnItemSelected(SerialId, PhotoData)
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "PetPhotoListView:OnItemSelected")
  local PhotoPath = PhotoData:GetPhotoPath()
  Log.Debug("\230\159\165\231\156\139\229\164\167\229\155\190", SerialId, PhotoPath)
  if PhotoPath and UE4.UBlueprintPathsLibrary.FileExists(PhotoPath) then
    self.Module:ClosePanel("PhotoFileViewUI")
    self.Module:PopupPhotoFileView(PhotoData)
  else
    Log.Warning("Wait for downloading", PhotoPath)
  end
end

function PetPhotoListView:OnPhotosRemoved()
  if self.HandbookId and self.ListView and UE.UObject.IsValid(self.ListView) then
    self.DataList = self:GetDataListByHandbookId(self.HandbookId)
    self.ListView:InitGridView(self.DataList)
    self.OnPhotosRemovedDelegate:Invoke()
  end
end

function PetPhotoListView:GetItemCount()
  return self.DataList and #self.DataList or 0
end

function PetPhotoListView:Show(HandbookId)
  if HandbookId == self.HandbookId then
    return
  end
  if self.HandbookId then
    self:Hide()
  end
  if not self.bResourceCreated then
    self.PhotoManager:InitThumbnailPool()
    self.bResourceCreated = true
  end
  self.HandbookId = HandbookId
  self:AdaptSize()
  self:UpdateRange()
  self.DataList = self:GetDataListByHandbookId(HandbookId)
  self.ListView:InitGridView(self.DataList)
  UpdateManager:Register(self)
end

function PetPhotoListView:Hide()
  self.HandbookId = nil
  UpdateManager:UnRegister(self)
end

function PetPhotoListView:OnTick()
  if not self.HandbookId then
    return
  end
  self:UpdateRange()
end

function PetPhotoListView:AdaptSize()
  local ViewportSize = self.Module.data:GetScreenSize()
  local VXY = ViewportSize.X / ViewportSize.Y
  local FixWidth = 523
  local ThumbnailWidth = FixWidth - 40
  local ThumbnailHeight = ThumbnailWidth / VXY
  local ItemHeight = ThumbnailHeight + 60
  self.ItemDesiredWidth = math.floor(FixWidth)
  self.ItemDesiredHeight = math.floor(ItemHeight)
  self.ThumbnailDesiredWidth = ThumbnailWidth
  self.ThumbnailDesiredHeight = ThumbnailHeight
  self.ListView:SetCustomSize(self.ItemDesiredWidth, self.ItemDesiredHeight)
end

function PetPhotoListView:UpdateRange()
  if not self.DataList then
    return
  end
  local ScrollBox = self.ScrollBox
  if ScrollBox and UE.UObject.IsValid(ScrollBox) then
    local ScrollOffset = ScrollBox:GetScrollOffset()
    local ViewportSize = UE.USlateBlueprintLibrary.GetLocalSize(ScrollBox:GetCachedGeometry())
    local ViewportHeight = ViewportSize.Y
    local StartRow = math.floor(ScrollOffset / self.ItemDesiredHeight)
    local EndRow = math.ceil((ScrollOffset + ViewportHeight) / self.ItemDesiredHeight)
    local ColumnsPerRow = self.ListView.m_colCount
    local StartIndex = StartRow * ColumnsPerRow
    local EndIndex = (EndRow + 1) * ColumnsPerRow - 1
    StartIndex = math.max(0, StartIndex)
    local bChanged, OldStart, OldEnd = self.PhotoManager.ThumbnailScrollPool:UpdateThumbnailScrollRange(StartIndex, EndIndex)
    if bChanged then
      for i = StartIndex, EndIndex do
        if i < OldStart or i > OldEnd then
          local Data = self.DataList[i + 1]
          if Data then
            self.ListView:RefreshItemDataByIndex(i)
          end
        end
      end
    end
  else
  end
end

return PetPhotoListView
