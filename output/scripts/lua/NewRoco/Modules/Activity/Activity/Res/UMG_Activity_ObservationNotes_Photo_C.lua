local UMG_Activity_ObservationNotes_Photo_C = _G.NRCPanelBase:Extend("UMG_Activity_ObservationNotes_Photo_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_ObservationNotes_Photo_C:OnActive(infoId)
  self.ColorPointList = {
    "#4f4337ff",
    "#85618dff",
    "c52412ff",
    "f18435ff",
    "ffc90dff",
    "97c115ff",
    "52bc1eff",
    "c3c3c3ff",
    "e5e5e5ff"
  }
  self.InfoId = infoId
  local petInfoData = _G.DataConfigManager:GetPetInformationConf(infoId)
  self.NRCText_Title:SetText(petInfoData.animal_name)
  self.NRCText_Describe:SetText(petInfoData.txt1)
  local photoGroup = petInfoData.picture_information_group
  self.showPhotoList = {}
  self.curPhotoIndex = 1
  for _, photoData in pairs(photoGroup) do
    if photoData.animal_picture ~= "" and "" ~= photoData.picture_information then
      table.insert(self.showPhotoList, photoData)
    end
  end
  if #self.showPhotoList <= 1 then
    self.Btn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:ShowPhoto()
  self:ShowAnimRarity(petInfoData.animal_rarity_level)
  self:OnAddEventListener()
end

function UMG_Activity_ObservationNotes_Photo_C:OnDeactive()
  self:RemoveButtonListener(self.Btn2.btnLevelUp)
  self:RemoveButtonListener(self.Btn1.btnLevelUp)
  self:RemoveButtonListener(self.CloseBtn.btnClose)
end

function UMG_Activity_ObservationNotes_Photo_C:OnAddEventListener()
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnLeft)
  self:AddButtonListener(self.Btn1.btnLevelUp, self.OnRight)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnCloseClick)
end

function UMG_Activity_ObservationNotes_Photo_C:ShowPhoto()
  if self.showPhotoList and #self.showPhotoList > 0 then
    local curPhotoData = self.showPhotoList[self.curPhotoIndex]
    self.NRCText_Name:SetText(curPhotoData.picture_information)
    self.Photograph:SetPath(curPhotoData.animal_picture)
  end
end

function UMG_Activity_ObservationNotes_Photo_C:OnLeft()
  if not self.showPhotoList or 1 == #self.showPhotoList then
    return
  end
  if 1 == self.curPhotoIndex then
    self.curPhotoIndex = #self.showPhotoList
  else
    self.curPhotoIndex = self.curPhotoIndex - 1
  end
  self:ShowPhoto()
end

function UMG_Activity_ObservationNotes_Photo_C:OnRight()
  if not self.showPhotoList or 1 == #self.showPhotoList then
    return
  end
  if self.curPhotoIndex == #self.showPhotoList then
    self.curPhotoIndex = 1
  else
    self.curPhotoIndex = self.curPhotoIndex + 1
  end
  self:ShowPhoto()
end

function UMG_Activity_ObservationNotes_Photo_C:OnBtnCloseClick()
  self:DoClose()
end

function UMG_Activity_ObservationNotes_Photo_C:ShowAnimRarity(level)
  local rarityStr = ActivityUtils.GetActivityGlobalConfig("pet_animals_rarity_level_name").str
  local dataList = {}
  local index = 1
  for word in rarityStr:gmatch("([^;]+)") do
    local rarityData = {
      text = word,
      color = self.ColorPointList[index]
    }
    index = index + 1
    table.insert(dataList, rarityData)
  end
  self.ListRarity:InitGridView(dataList)
  for i = 1, self.ListRarity:GetItemCount() do
    local item = self.ListRarity:GetItemByIndex(i - 1)
    local isTarget = false
    if i == level then
      isTarget = true
    end
    item:ShowInfo(isTarget)
  end
  if self.ListRarity then
    self.ListRarity:RefreshGridViewLayout()
  end
end

return UMG_Activity_ObservationNotes_Photo_C
