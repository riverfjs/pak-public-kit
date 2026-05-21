local UMG_Activity_ObservationNotes_C = _G.NRCPanelBase:Extend("UMG_Activity_ObservationNotes_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local TaskQueryHandler = require("NewRoco.Modules.System.Misc.TaskQueryHandler")

function UMG_Activity_ObservationNotes_C:OnActive()
  self.judgeTaskQuery = nil
  self.lockStoryData = nil
  self.StoryDataList = {}
  self:InitAnimalList()
  self:SetTitle()
  self.NRCSwitcher_83:SetActiveWidgetIndex(0)
  self.TextDescMaxCount = {
    80,
    189,
    105
  }
  self:OnAddEventListener()
  ActivityUtils.SendTLogActivityButtonAction(4000002, 4)
end

function UMG_Activity_ObservationNotes_C:OnDeactive()
  self:RemoveButtonListener(self.CloseBtn.btnClose)
  self:RemoveButtonListener(self.LookPhotosBtn)
  self:RemoveButtonListener(self.Btn_NotUnlocked)
  self:RemoveButtonListener(self.Btn_NotUnlocked_1)
  self:RemoveButtonListener(self.Btn_NotUnlocked_2)
  self:RemoveButtonListener(self.LookOverBtn_1.btnLevelUp)
  self:RemoveButtonListener(self.LookOverBtn_2.btnLevelUp)
  self:RemoveButtonListener(self.LookOverBtn_3.btnLevelUp)
end

function UMG_Activity_ObservationNotes_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnCloseClick)
  self:AddButtonListener(self.LookPhotosBtn, self.OnLookPhoto)
  self:AddButtonListener(self.Btn_NotUnlocked, self.OnLockTextTips)
  self:AddButtonListener(self.Btn_NotUnlocked_1, self.OnLockTextTips)
  self:AddButtonListener(self.Btn_NotUnlocked_2, self.OnLockTextTips)
  self:AddButtonListener(self.LookOverBtn_1.btnLevelUp, self.LookOverBtnOnClick1)
  self:AddButtonListener(self.LookOverBtn_2.btnLevelUp, self.LookOverBtnOnClick2)
  self:AddButtonListener(self.LookOverBtn_3.btnLevelUp, self.LookOverBtnOnClick3)
end

function UMG_Activity_ObservationNotes_C:InitAnimalList()
  local tableId = _G.DataConfigManager.ConfigTableId.PET_INFORMATION_CONF
  local allData = _G.DataConfigManager:GetAllByTableID(tableId)
  local showListData = {}
  for _, animalData in pairs(allData) do
    local isOpen = animalData.if_open
    local isAppear = true
    local startTime = animalData.appear_time
    local endTime = animalData.disappear_time
    local serverTimestamp = ActivityUtils.GetSvrTimestamp()
    if startTime and endTime and (startTime > serverTimestamp or endTime < serverTimestamp) then
      isAppear = false
    end
    if isOpen and isAppear then
      table.insert(showListData, animalData)
    end
    self.ListItem:InitList(showListData)
  end
end

function UMG_Activity_ObservationNotes_C:UpdateAnimalInfo(data)
  self.InfoId = data.id
  self.StoryDataList = {}
  local petInfoData = _G.DataConfigManager:GetPetInformationConf(self.InfoId)
  self.NRCText_Title:SetText(petInfoData.title)
  local petStoryGroup = petInfoData.story_page_group
  for index, petStoryData in pairs(petStoryGroup) do
    local unlockType = petStoryData.story_page_type
    if unlockType == Enum.PETStoryPageType.PSPT_TASK then
      self.lockStoryData = {index = index, petStoryData = petStoryData}
      local taskId = petInfoData.task_id
      self.judgeTaskQuery = TaskQueryHandler({taskId})
      self.judgeTaskQuery:QueryTaskStatus(self, self.PreTaskCheckCallback)
    else
      self:ShowStory(index, petStoryData)
    end
    table.insert(self.StoryDataList, petStoryData)
  end
  for i = 1, 3 do
    self:ShowStory(i, self.StoryDataList[i])
  end
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(data.petbase_id)
  local petPicture = {
    petbaseConf.JL_res,
    petbaseConf.JL_shiny_res
  }
  self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(false)
  self.Icon1:SetPath(petPicture[1])
  self.Bg1:SetPath(petInfoData.pet_backgroung_image)
  self.Image_Egg:SetPath(petInfoData.egg_image)
  local leftData = {
    image = petInfoData.left_picture_image,
    txt_pos = petInfoData.left_txt_position,
    content = petInfoData.left_txt
  }
  if petInfoData.left_picture_position == Enum.PetSotryDecorationImage.PSDI_FRONT then
    self.PetSticker_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetSticker_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetSticker_2:SetInfo(leftData)
  else
    self.PetSticker_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PetSticker_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetSticker_1:SetInfo(leftData)
  end
  local rightData = {
    image = petInfoData.right_picture_image,
    txt_pos = petInfoData.right_txt_position,
    content = petInfoData.right_txt
  }
  self.PetSticker:SetInfo(rightData)
end

function UMG_Activity_ObservationNotes_C:OnBtnCloseClick()
  if 0 == self.NRCSwitcher_83:GetActiveWidgetIndex() then
    self:DoClose()
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401012, "UMG_Activity_ObservationNotes_C:OnBtnCloseClick")
    self:SwitchPanel(0)
  end
end

function UMG_Activity_ObservationNotes_C:SwitchPanel(index, data)
  if data then
    self:UpdateAnimalInfo(data)
  end
  self.NRCSwitcher_83:SetActiveWidgetIndex(index)
end

function UMG_Activity_ObservationNotes_C:PreTaskCheckCallback(allFinished)
  if allFinished then
    if self.lockStoryData then
      self:ShowStory(self.lockStoryData.index, self.lockStoryData.petStoryData)
      self.lockStoryData = nil
    end
  else
    local switcher = self["NRCSwitcher_Text_" .. self.lockStoryData.index]
    if switcher then
      switcher:SetActiveWidgetIndex(1)
    end
  end
end

function UMG_Activity_ObservationNotes_C:ShowStory(index, petStoryData)
  local switcher = self["NRCSwitcher_Text_" .. index]
  if switcher then
    switcher:SetActiveWidgetIndex(0)
  end
  local title = self["NRCText_Title" .. index]
  if title then
    if petStoryData and petStoryData.story_title then
      title:SetText(petStoryData.story_title)
    else
      title:SetText("")
    end
  end
  local describe = self["NRCText_Describe" .. index]
  if describe then
    local desc = ""
    if petStoryData and petStoryData.story_txt then
      desc = petStoryData.story_txt
    end
    local text = self:GetPartShowText(index, desc)
    describe:SetText(text)
  end
end

function UMG_Activity_ObservationNotes_C:OnLookPhoto()
  ActivityUtils.SendTLogActivityButtonAction(4000002, 5)
  local petInfoData = _G.DataConfigManager:GetPetInformationConf(self.InfoId)
  local bagItemId = petInfoData.bagitem_id
  local hasItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if hasItem then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Activity_ObservationNotes_C:OnLookPhoto")
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenObservationNotesPhotoPanel, self.InfoId)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_Activity_ObservationNotes_C:OnLookPhoto")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.activity_animals_picture_tips)
  end
end

function UMG_Activity_ObservationNotes_C:OnLockTextTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.activity_animals_unfinish_task_tips)
end

function UMG_Activity_ObservationNotes_C:SetTitle()
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if titleConf then
    self.Title1:Set_MainTitle(titleConf.title)
    self.Title1:SetBg(titleConf.head_icon)
    self.Title1:SetSubtitle(titleConf.subtitle[1].subtitle)
  end
  self.NRCText_0:SetText(LuaText.activity_pet_information_pet_txt)
end

function UMG_Activity_ObservationNotes_C:LookOverBtnOnClick1()
  self:GoToLookDetailNote(1)
end

function UMG_Activity_ObservationNotes_C:LookOverBtnOnClick2()
  self:GoToLookDetailNote(2)
end

function UMG_Activity_ObservationNotes_C:LookOverBtnOnClick3()
  self:GoToLookDetailNote(3)
end

function UMG_Activity_ObservationNotes_C:GoToLookDetailNote(index)
  _G.NRCAudioManager:PlaySound2DAuto(40002028, "UMG_Activity_ObservationNotes_C:GoToLookDetailNote")
  local storyData = self.StoryDataList[index]
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenObservationNotesDetailsPanel, storyData)
end

function UMG_Activity_ObservationNotes_C:GetPartShowText(index, totalText)
  local textLen = utf8.len(totalText)
  local isShow = false
  local maxLen = self.TextDescMaxCount[index]
  if textLen > maxLen then
    isShow = true
  else
    isShow = false
  end
  local lookBtn = self["LookOverBtn_" .. index]
  if lookBtn then
    if isShow then
      lookBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      lookBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if isShow then
    local truncated = ""
    local count = 0
    for i, code in utf8.codes(totalText) do
      if count < maxLen - 3 then
        truncated = truncated .. utf8.char(code)
        count = count + 1
      else
        break
      end
    end
    return truncated .. "..."
  end
  return totalText
end

return UMG_Activity_ObservationNotes_C
