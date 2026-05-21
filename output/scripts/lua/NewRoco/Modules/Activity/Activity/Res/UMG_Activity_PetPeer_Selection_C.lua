local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local UMG_Activity_PetPeer_Selection_C = _G.NRCPanelBase:Extend("UMG_Activity_PetPeer_Selection_C")

function UMG_Activity_PetPeer_Selection_C:OnConstruct()
  self.previewWorld:OnConstruct()
  self.HeadItem.ParentView = self
  self.ScreeningBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CoCreationActivityText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Btn6:SetBtnText(LuaText.PET_Partner_9)
  self:OnAddEventListener()
  self.delayTimer = nil
end

function UMG_Activity_PetPeer_Selection_C:OnDestruct()
  self.previewWorld:OnDestruct()
  self.HeadItem.ParentView = nil
  self:RemoveAllButtonListener()
  if self.delayTimer then
    _G.DelayManager:CancelDelayById(self.delayTimer)
    self.delayTimer = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.FilterPetPartner, self.OnBtnFilerApplyClick)
end

function UMG_Activity_PetPeer_Selection_C:OnActive(data)
  self.activityInst = data
  self.currentPetData = nil
  self.isPartnerPet = false
  self.prePetInfo = {}
  self:PlayAnimation(self.In)
  self:OnInitPetData()
end

function UMG_Activity_PetPeer_Selection_C:OnDeactive()
end

function UMG_Activity_PetPeer_Selection_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClick)
  self:AddButtonListener(self.MagnifyingGlass.btnLevelUp, self.OnBtnMagnifyingClick)
  self:AddButtonListener(self.Btn_Dazzling_3.btnLevelUp, self.OnBtnDazzlingClick)
  self:AddButtonListener(self.Btn6.btnLevelUp, self.OnBtnCommitClick)
  self:AddButtonListener(self.ScreeningBtn.btnLevelUp, self.OnBtnFilerClick)
  self:AddButtonListener(self.BtnRechristen_1, self.OnBtnOpenPetTip)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_PetPeer_Selection_C", self, PetUIModuleEvent.FilterPetPartner, self.OnBtnFilerApplyClick)
end

function UMG_Activity_PetPeer_Selection_C:OnInitPetData()
  local partnerPetData = self.activityInst:GetPartnerPetData()
  if partnerPetData then
    self.TestPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HeadItem:SetIconPathAndMaterial(partnerPetData.base_conf_id, partnerPetData.mutation_type, partnerPetData.glass_info, true)
  else
    self.TestPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if titleConf and titleConf.subtitle and #titleConf.subtitle > 0 then
    self.Title1:Set_MainTitle(titleConf.title)
    self.Title1:SetBg(titleConf.head_icon)
    self.Title1:SetSubtitle(titleConf.subtitle[1].subtitle)
  end
  self.Text_Title:SetText(LuaText.PET_Partner_7)
  self.Text_Title_1:SetText(LuaText.PET_Partner_8)
  local petPoolData = self.activityInst:GetPartnerPetConf()
  if petPoolData then
    local petListData = self:SetPetList(petPoolData)
    self:InitDefaulSelected(petListData)
  end
  self:RefreshRightShow()
end

function UMG_Activity_PetPeer_Selection_C:InitDefaulSelected(petListData)
  local bChooseInheritPet = self.activityInst:IsChooseInheritPet()
  local partnerPetData = self.activityInst:GetPartnerPetData()
  if bChooseInheritPet then
    self.GridView:ClearSelection()
    self.currentPetData = partnerPetData
    self.isPartnerPet = true
    self.HeadItem:SetSelectedState(1)
  else
    local choosePetID, choosePetEggID = self.activityInst:GetChoosedPetBaseIDAndEggID()
    if 0 == choosePetID and partnerPetData then
      self.GridView:ClearSelection()
      self.currentPetData = partnerPetData
      self.isPartnerPet = true
      self.HeadItem:SetSelectedState(1)
    else
      local index = 0
      for i, v in ipairs(petListData) do
        if v.petData.pet_base_id == choosePetID then
          index = i - 1
          break
        end
      end
      self.GridView:SelectItemByIndex(index)
      self.HeadItem:SetSelectedState(0)
    end
  end
end

function UMG_Activity_PetPeer_Selection_C:SetPetList(petList)
  local petListData = {}
  for i, v in ipairs(petList) do
    table.insert(petListData, {parentPanel = self, petData = v})
  end
  self.GridView:Clear()
  self.GridView:InitList(petListData, true)
  if self.delayTimer then
    _G.DelayManager:CancelDelay(self.delayTimer)
    self.delayTimer = nil
  end
  self.delayTimer = _G.DelayManager:DelayFrames(1, function()
    self.GridView:PreCreatePanel()
    self.delayTimer = nil
  end)
  return petListData
end

function UMG_Activity_PetPeer_Selection_C:OnBtnOpenPetTip()
  if self.currentPetData then
    local petBaseId = 0
    if self.isPartnerPet then
      petBaseId = self.currentPetData.base_conf_id
    else
      petBaseId = self.currentPetData.pet_base_id
    end
    local paramData = {
      petData = {base_conf_id = petBaseId}
    }
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, paramData, _G.Enum.GoodsType.GT_PET)
  end
end

function UMG_Activity_PetPeer_Selection_C:OnCloseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_Activity_PetPeer_Selection_C:OnCloseBtnClick")
  self:PlayAnimation(self.Out)
end

function UMG_Activity_PetPeer_Selection_C:OnAnimationFinished(Animation)
  if Animation == self.Out then
    self:OnClose()
  end
end

function UMG_Activity_PetPeer_Selection_C:OnChildItemClick(childPanel, index, bIsSelected)
  Log.Debug("UMG_Activity_PetPeer_Selection_C:OnChildItemClick")
  childPanel:OnItemSelected(bIsSelected)
  self.isPartnerPet = true
  self.currentPetData = self.activityInst:GetPartnerPetData()
  self:RefreshRightShow()
  self.GridView:ClearSelection()
end

function UMG_Activity_PetPeer_Selection_C:OnBtnMagnifyingClick()
  local petBaseId, petData
  if self.isPartnerPet then
    petData = {
      mutation_type = self.currentPetData.mutation_type,
      glass_info = self.currentPetData.glass_info,
      nature = self.currentPetData.nature
    }
    petBaseId = self.currentPetData.base_conf_id
  else
    petBaseId = self.currentPetData.pet_base_id
  end
  if petBaseId and 0 ~= petBaseId then
    _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Activity_AbuBadge_C:OpenPetPanel")
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petBaseId, true, nil, petData)
  end
end

function UMG_Activity_PetPeer_Selection_C:OnBtnFilerClick()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenFilterPanel, PetUIModuleEnum.OpenSortType.PetPartnerActivity, {
    HiddenParam = nil,
    chooseTypeList = self.chooseTypeList,
    HiddenFilterEnum = {
      1,
      2,
      3,
      4,
      5,
      6
    }
  })
end

function UMG_Activity_PetPeer_Selection_C:OnBtnFilerApplyClick(chooseTypeList)
  self.chooseTypeList = chooseTypeList
  local departmentFilter = chooseTypeList.DepartmentFilter
  local petPoolData = self.activityInst:GetPartnerPetConf()
  local petList = {}
  if petPoolData then
    if nil == departmentFilter or 0 == #departmentFilter then
      petList = petPoolData
    else
      for i, v in ipairs(petPoolData) do
        for _, filterType in ipairs(departmentFilter) do
          local success = self:FilterPetTypeByPetID(filterType, v.pet_base_id)
          if success then
            table.insert(petList, v)
            break
          end
        end
      end
    end
  end
  local petFilterList = self:SetPetList(petList)
  if nil == departmentFilter or 0 == #departmentFilter then
    local partnerPetData = self.activityInst:GetPartnerPetData()
    if partnerPetData then
      self.TestPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    for _, filterType in ipairs(departmentFilter) do
      local partnerPetData = self.activityInst:GetPartnerPetData()
      if partnerPetData then
        local success = self:FilterPetTypeByPetID(filterType, partnerPetData.base_conf_id)
        self.TestPet:SetVisibility(success and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
        if success then
          break
        end
      end
    end
  end
  _G.DelayManager:DelayFrames(2, function()
    self:DealWithFilterSelected(petFilterList)
  end)
end

function UMG_Activity_PetPeer_Selection_C:DealWithFilterSelected(petFilterList)
  if not self.currentPetData then
    return
  end
  if self.isPartnerPet then
    self.GridView:ClearSelection()
    self.HeadItem:SetSelectedState(1)
  else
    for i, v in ipairs(petFilterList) do
      if v.petData.pet_base_id == self.currentPetData.pet_base_id then
        self.GridView:SelectItemByIndex(i - 1)
        self.HeadItem:SetSelectedState(0)
        break
      end
    end
  end
end

function UMG_Activity_PetPeer_Selection_C:FilterPetTypeByPetID(filterType, petID)
  local conf = _G.DataConfigManager:GetPetbaseConf(petID)
  if not conf then
    return false
  end
  for _, unitType in ipairs(conf.unit_type) do
    if filterType.data and filterType.data.filter_enum_name and filterType.data.filter_enum_value and unitType == _G.Enum[filterType.data.filter_enum_name][filterType.data.filter_enum_value] then
      return true
    end
  end
  return false
end

function UMG_Activity_PetPeer_Selection_C:OnBtnDazzlingClick()
  if self.currentPetData then
    if PetUtils.CheckIsHiddenShiningGlass(self.currentPetData.mutation_type, self.currentPetData.glass_info) or PetUtils.CheckIsHiddenGlass(self.currentPetData.mutation_type, self.currentPetData.glass_info) or PetUtils.CheckIsShiningGlass(self.currentPetData.mutation_type) or PetMutationUtils.GetMutationValue(self.currentPetData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenDazzlingTipsPanel, self.currentPetData)
    elseif PetUtils.CheckIsCHAOS(self.currentPetData.mutation_type) or PetMutationUtils.GetMutationValue(self.currentPetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenMutationTipsPanel, self.currentPetData)
    end
  end
end

function UMG_Activity_PetPeer_Selection_C:OnBtnCommitClick()
  if self.activityInst then
    if self.isPartnerPet then
      self:OnConfirmCommit()
    else
      self.activityInst:ChoosePartnerPetReq(self.currentPetData.pet_base_id, self.isPartnerPet, false)
      self:PlayAnimation(self.Out)
    end
    _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_Activity_PetPeer_Selection_C:OnBtnCommitClick")
  end
end

function UMG_Activity_PetPeer_Selection_C:OnConfirmCommit()
  if not self.isPartnerPet then
    return
  end
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = LuaText.PET_Partner_14
  local petName = self.activityInst:GetSelectPetName(self.currentPetData.base_conf_id, self.isPartnerPet)
  local Content = string.format(LuaText.PET_Partner_15, petName)
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.PET_Partner_17, LuaText.PET_Partner_16):SetCloseBtnNotDoCancel(true):SetCallback(self, function(caller, isOK, clickType)
    if clickType == CommonBtnEnum.DialogCancelType.NullClickType or clickType == CommonBtnEnum.DialogCancelType.CloseClickType then
      return
    end
    self:PlayAnimation(self.Out)
    self.activityInst:ChoosePartnerPetReq(self.currentPetData.base_conf_id, self.isPartnerPet, isOK)
  end)
  Context:SetForceEnableFullScreenBtn()
  Context:SetContentTextJustify(UE4.ETextJustify.Left)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Activity_PetPeer_Selection_C:OnItemSelected(childData)
  self.currentPetData = childData
  self.isPartnerPet = false
  self.HeadItem:SetSelectedState(0)
  self:RefreshRightShow()
end

function UMG_Activity_PetPeer_Selection_C:RefreshRightShow()
  if self.currentPetData == nil then
    return
  end
  self.Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local name = ""
  local gender, petId
  self.NRCImage_17:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCImage_18:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ElfIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Attr1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local petUnitType = {}
  if self.isPartnerPet then
    name = self.currentPetData.name
    petId = self.currentPetData.base_conf_id
    gender = self.currentPetData.gender
    self.NRCImage_18:SetVisibility(1 == gender and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    self.NRCImage_17:SetVisibility(1 == gender and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CoCreationActivityText:SetText("")
    self.TextSwitcher:SetActiveWidgetIndex(1)
    local experienceList = self:SetItemGainWay(self.currentPetData)
    self.ItemGainWay:InitList(experienceList)
    self.ItemGainWay:EndInertialScrolling()
    self.ItemGainWay:NRCScrollToStart()
  else
    name = self.activityInst:GetSelectPetName(self.currentPetData.pet_base_id, self.isPartnerPet)
    petId = self.currentPetData.pet_base_id
    self.CoCreationActivityText:SetText(LuaText.PET_Partner_19)
    self.TextSwitcher:SetActiveWidgetIndex(0)
    local conf = _G.DataConfigManager:GetPetbaseConf(petId)
    if conf then
      self.Describe:SetText(conf.description)
    end
  end
  self.Name_1:SetText(name)
  self.previewWorld:SetPreviewByPetBaseId(self, petId, self.currentPetData.mutation_type, self.currentPetData.glass_info, self.currentPetData.nature, self.OnPetShowSuccess)
  local petConf = _G.DataConfigManager:GetPetbaseConf(petId)
  if petConf and petConf.unit_type then
    for _, _type in ipairs(petConf.unit_type) do
      local typeInfo = _G.DataConfigManager:GetTypeDictionary(_type)
      if typeInfo then
        table.insert(petUnitType, {
          Name = typeInfo.short_name,
          Path = typeInfo.type_icon
        })
      end
    end
  end
  self.Attr2:InitGridView(petUnitType)
  self:SetSpecialSign(self.currentPetData)
end

function UMG_Activity_PetPeer_Selection_C:OnPetShowSuccess()
  self.previewWorld:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_Activity_PetPeer_Selection_C:SetSpecialSign(petData)
  if PetUtils.CheckIsShiningChaos(petData.mutation_type) then
  elseif PetUtils.CheckIsCHAOS(petData.mutation_type) then
  elseif PetUtils.CheckIsHiddenShiningGlass(petData.mutation_type, petData.glass_info) then
    local path = UEPath.DifferentDazzlingColors
    self.Btn_Dazzling_3:SetPath(path, path, path)
  elseif PetUtils.CheckIsShiningGlass(petData.mutation_type) then
    local path = UEPath.DifferentDazzlingColors
    self.Btn_Dazzling_3:SetPath(path, path, path)
  elseif PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    local path = UEPath.DifferentColors
    self.Btn_Dazzling_3:SetPath(path, path, path)
  elseif PetUtils.CheckIsHiddenGlass(petData.mutation_type, petData.glass_info) then
    local path = UEPath.DazzlingColors
    self.Btn_Dazzling_3:SetPath(path, path, path)
  elseif PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    local path = UEPath.DazzlingColors
    self.Btn_Dazzling_3:SetPath(path, path, path)
  end
end

function UMG_Activity_PetPeer_Selection_C:SetItemGainWay(petData)
  if not petData then
    return {}
  end
  petData = petData.activity_partner_pet_data
  if not petData then
    return {}
  end
  local List = {}
  local Text = ""
  local AddTime = ""
  local Count = ""
  if petData.add_time then
    AddTime = os.date(LuaText.medal_text_5, petData.add_time)
    Text = string.format(LuaText.pet_partner_experience_text_9, AddTime)
  end
  if petData.together_catch_info then
    local name = ""
    if petData.together_catch_info.is_onwer_catch then
      name = petData.together_catch_info.related_name
    else
      name = petData.together_catch_info.catched_name
    end
    if name then
      local nameText = string.format(LuaText.pet_partner_experience_text_10, name)
      Text = string.format("%s%s", Text, nameText)
    end
  end
  local PetCatchWay
  if petData.catch_way == Enum.PetCatchWay.PCW_WILD then
    local temp
    if petData.caught_camp then
      local CampConf = _G.DataConfigManager:GetCampConf(petData.caught_camp)
      if CampConf then
        temp = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_7").msg
        PetCatchWay = string.format(temp, CampConf.camp_name)
      end
    else
      PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_1").msg
    end
  elseif petData.catch_way == Enum.PetCatchWay.PCW_VISIT then
    local temp = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_2").msg
    PetCatchWay = string.format(temp, petData.catch_visit_owner_name)
  elseif petData.catch_way == Enum.PetCatchWay.PCW_EGGHATCH then
    PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_3").msg
  elseif petData.catch_way == Enum.PetCatchWay.PCW_DUNGEON then
    PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_6").msg
  elseif petData.catch_way == Enum.PetCatchWay.PCW_TEAMBATTLE then
    PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_4").msg
  elseif petData.catch_way == Enum.PetCatchWay.PCW_LEGEND then
    PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_5").msg
  else
    PetCatchWay = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_1").msg
  end
  Text = string.format("%s%s", Text, PetCatchWay)
  if petData.catch_lv then
    Count = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_text_8").msg
    Count = string.format(Count, petData.catch_lv)
    Text = string.format("%s%s", Text, Count)
  end
  table.insert(List, {
    Text = Text,
    Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon1_png.img_Medal_Icon1_png'"
  })
  local natureDesc = PetUtils.GetNatureDes(petData)
  if natureDesc then
    Text = natureDesc
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon2_png.img_Medal_Icon2_png'"
    })
  end
  if petData.key_experience and petData.key_experience.blessing_info then
    local blessing_info = petData.key_experience.blessing_info
    if blessing_info.from_player_name and blessing_info.from_pet_name then
      Text = string.format(LuaText.interactiontree_cifu_text_1, blessing_info.from_player_name, blessing_info.from_pet_name)
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon6_png.img_Medal_Icon6_png'"
      })
    end
  end
  if petData.key_experience and petData.key_experience.evolute_info then
    Text = ""
    for i, Evolute in ipairs(petData.key_experience.evolute_info) do
      AddTime = os.date(LuaText.medal_text_5, Evolute.evolute_time)
      local BeforePetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.before_base_conf_id)
      local AfterPetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.after_base_conf_id)
      local msg = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_form_1").msg
      local Text_Info = string.format(msg, AddTime, BeforePetBaseConf.name, AfterPetBaseConf.name)
      Text = string.format("%s%s", Text, Text_Info)
      if i ~= #petData.key_experience.evolute_info then
        Text = string.format("%s%s", Text, "\n")
      end
    end
    if "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon4_png.img_Medal_Icon4_png'"
      })
    end
  end
  Text = ""
  if petData.key_experience and petData.key_experience.legend_first_win_alone_info then
    AddTime = os.date(LuaText.medal_text_5, petData.key_experience.legend_first_win_alone_info.win_time)
    local msg = _G.DataConfigManager:GetLocalizationConf("pet_partner_experience_form_3").msg
    local Text_Info = string.format(msg, AddTime)
    Text = string.format("%s%s", Text, Text_Info)
  end
  if "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon3_png.img_Medal_Icon3_png'"
    })
  end
  if petData.closeness_info and petData.closeness_info.closeness_lv and 0 ~= petData.closeness_info.closeness_lv then
    Text = ""
    local PetCloseLevelEffectConf = _G.DataConfigManager:GetPetCloseLevelEffectConf(petData.closeness_info.closeness_lv + 1)
    if PetCloseLevelEffectConf.localization_id and "" ~= PetCloseLevelEffectConf.localization_id then
      local LocalizationConf = _G.DataConfigManager:GetLocalizationConf(PetCloseLevelEffectConf.localization_id)
      Text = string.format(LocalizationConf.msg, petData.name)
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon5_png.img_Medal_Icon5_png'"
      })
    end
  end
  Text = LuaText.PET_Partner_10
  if Text and "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon1_png.img_Medal_Icon1_png'"
    })
  end
  return List
end

function UMG_Activity_PetPeer_Selection_C:ResetRotateModule()
  self.previewWorld:ResetRotate()
end

function UMG_Activity_PetPeer_Selection_C:SetRuler(headPos)
end

return UMG_Activity_PetPeer_Selection_C
