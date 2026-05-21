local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_MedalPanel_C = _G.NRCViewBase:Extend("UMG_MedalPanel_C")

function UMG_MedalPanel_C:OnConstruct()
  self.PetData = nil
  self.WearMedal = nil
  self.IsFirstOpen = false
  self:OnAddEventListener()
end

function UMG_MedalPanel_C:OnDestruct()
end

function UMG_MedalPanel_C:OnActive()
end

function UMG_MedalPanel_C:OnDeactive()
end

function UMG_MedalPanel_C:updatePetInfo(_PetData)
  self.PetData = _PetData
  if _PetData then
    if self.PetData and _PetData.gid ~= self.PetData.gid then
      self.IsFirstOpen = false
    end
    self:SetWeigthAndStature(_PetData)
  end
end

function UMG_MedalPanel_C:OnPanelStateChange(_isShow)
  if _isShow then
    if self.PetData then
      self:SetPanelInfo()
      self.Button_EquippableMedal.RedDot:SetupKey(197, {
        self.PetData.gid
      })
      self.Button.RedDot:SetupKey(197, {
        self.PetData.gid
      })
      self.IsFirstOpen = true
    else
      self:SetEmpty()
    end
  else
    self:StopAllAnimations()
  end
end

function UMG_MedalPanel_C:OnAddEventListener()
  self:AddButtonListener(self.Button_EquippableMedal.btnLevelUp, self.OnClickButton_EquippableMedal)
  self:AddButtonListener(self.Button.btnLevelUp, self.OnClickButton_EquippableMedal)
  self:RegisterEvent(self, PetUIModuleEvent.PetWearMedalEvent, self.OnPetWearMedalEvent)
  self:RegisterEvent(self, PetUIModuleEvent.CloseMedalWonPanel, self.OnCloseMedalWonPanel)
end

function UMG_MedalPanel_C:OnPetWearMedalEvent()
  self:SetPanelInfo()
end

function UMG_MedalPanel_C:OnCloseMedalWonPanel()
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
  if WearMedal then
    self:PlayAnimation(self.Own_change_in)
  else
    self:PlayAnimation(self.Non_Change_in)
  end
  if not self.WearMedal then
    if WearMedal then
      self:PlayAnimation(self.Newicon_shine)
    end
  elseif self.WearMedal and WearMedal and self.WearMedal.conf_id ~= WearMedal.conf_id then
    self:PlayAnimation(self.Newicon_shine)
  end
  self.WearMedal = WearMedal
end

function UMG_MedalPanel_C:SetPanelInfo()
  self.DetailsSwitcher:SetActiveWidgetIndex(0)
  self:SetMedalInfo()
  self:SetItemGainWay()
end

function UMG_MedalPanel_C:SetEmpty()
  self.DetailsSwitcher:SetActiveWidgetIndex(1)
  self.NRCText_Empty:SetText(LuaText.Select_Null_Pet_Detail)
end

function UMG_MedalPanel_C:SetMedalInfo()
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
  if not self.IsFirstOpen then
    self.WearMedal = WearMedal
  end
  self.NRCImage_50:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Text_defeat:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ReplacementRedal_Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if WearMedal then
    self.NotWear:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ReplacementRedal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_Defeat:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local MedalConf = _G.DataConfigManager:GetMedalConf(WearMedal.conf_id)
    if MedalConf then
      local iconPath = MedalConf.big_icon
      if MedalConf.medal_ui_format == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 or MedalConf.medal_ui_format == _G.Enum.MedaluiFormat.MUIF_SPECIAL_4 then
        local medalLevelInfo = UIUtils.GetMedalLevelInfo(WearMedal.conf_id, WearMedal.complete_cnt)
        if medalLevelInfo then
          iconPath = medalLevelInfo.big_icon2
        end
      end
      self.ICON:SetPath(iconPath)
      self.NRCText_54:SetText(MedalConf.name)
    end
    if WearMedal.complete_cnt and WearMedal.complete_cnt > 0 then
      if MedalConf then
        if MedalConf.can_repeat_get and MedalConf.can_repeat_get > 0 then
          if MedalConf.repeat_get_award and #MedalConf.repeat_get_award > 0 and WearMedal.complete_cnt >= MedalConf.repeat_get_award[1].count then
            self.ICON_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("71c204FF"))
            self.NRCText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("71c204FF"))
          else
            self.ICON_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("929086FF"))
            self.NRCText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("929086FF"))
          end
          self.ICON_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.NRCText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.NRCText:SetText(WearMedal.complete_cnt)
        else
          self.ICON_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        if MedalConf.medal_ui_format == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 then
          local medalLevelInfo = UIUtils.GetMedalLevelInfo(WearMedal.conf_id, WearMedal.complete_cnt)
          if medalLevelInfo and medalLevelInfo.ui_param2 then
            local params = medalLevelInfo.ui_param2:split(";")
            if params and #params >= 3 then
              self.Text_defeat:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(params[1]))
              self.NRCImage_50:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
              self.NRCImage_50:SetPath(params[3])
            end
            self.Text_defeat:SetText(WearMedal.complete_cnt)
            self.Text_defeat:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.CanvasPanel_Defeat:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          end
        end
      else
        self.ICON_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.ICON_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:PlayAnimation(self.Own_change)
  else
    self.NotWear:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ReplacementRedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if MedalList and #MedalList > 0 then
      self.NRCText_1:SetText(LuaText.medal_text_3)
      self.Button_EquippableMedal:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.NRCText_1:SetText(LuaText.medal_text_4)
      self.Button_EquippableMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:PlayAnimation(self.Non_change)
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.Button_EquippableMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Button:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if friendInfo.petData and friendInfo.petData.wear_medal_conf_id and 0 ~= friendInfo.petData.wear_medal_conf_id then
      local MedalConf = _G.DataConfigManager:GetMedalConf(friendInfo.petData.wear_medal_conf_id)
      self.ReplacementRedal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if MedalConf then
        self.ICON:SetPath(MedalConf.big_icon)
        self.NRCText_54:SetText(MedalConf.name)
        self.NotWear:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ICON_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCText:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ReplacementRedal_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      self.ReplacementRedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NotWear:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCText_1:SetText(LuaText.medal_text_4)
      self.Button_EquippableMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_MedalPanel_C:GetPetGainTimeAndWay(isPartner)
  local Text, addTime, catchInfo, petData, catchLvl
  if isPartner then
    petData = self.PetData.activity_partner_pet_data
    if petData then
      addTime = petData.add_time
      catchInfo = petData.together_catch_info
      catchLvl = petData.catch_lv
    end
  else
    petData = self.PetData.activity_partner_pet_data
    if petData then
      local time = os.date(LuaText.medal_text_5, self.PetData.add_time)
      Text = string.format(LuaText.PET_Partner_11, time)
      return Text
    else
      petData = self.PetData
      addTime = petData.add_time
      catchInfo = petData.together_catch_info
      catchLvl = petData.catch_lv
    end
  end
  if addTime then
    local AddTime = os.date(LuaText.medal_text_5, addTime)
    Text = string.format(LuaText.pet_experience_text_9, AddTime)
  end
  if catchInfo then
    local name = ""
    if catchInfo.is_onwer_catch then
      name = catchInfo.related_name
    else
      name = catchInfo.catched_name
    end
    if name then
      local nameText = string.format(LuaText.pet_experience_text_10, name)
      Text = string.format("%s%s", Text, nameText)
    end
  end
  local PetCatchWay = self:GetPetCatchWay(petData)
  if PetCatchWay then
    Text = string.format("%s%s", Text, PetCatchWay)
  end
  if catchLvl then
    local Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_8").msg
    Count = string.format(Count, catchLvl)
    Text = string.format("%s%s", Text, Count)
  end
  return Text
end

function UMG_MedalPanel_C:GetPetNutureDesc(isPartner)
  local Text
  if isPartner then
    if self.PetData.activity_partner_pet_data then
      Text = self.PetData.activity_partner_pet_data.nature_desc
    end
  else
    local natureDesc = PetUtils.GetNatureDes(self.PetData)
    Text = natureDesc
  end
  return Text
end

function UMG_MedalPanel_C:GetPetBlessingInfo(isPartner)
  local Text, blessing_info
  if isPartner then
    local petData = self.PetData.activity_partner_pet_data
    if petData and petData.key_experience then
      blessing_info = petData.key_experience.blessing_info
    end
  elseif self.PetData and self.PetData.key_experience then
    blessing_info = self.PetData.key_experience.blessing_info
  end
  if blessing_info and blessing_info.from_player_name and blessing_info.from_pet_name then
    Text = string.format(LuaText.interactiontree_cifu_text_1, blessing_info.from_player_name, blessing_info.from_pet_name)
  end
  return Text
end

function UMG_MedalPanel_C:GetPetEvoluteInfo(isPartner)
  local Text, evolute_info
  if isPartner then
    local petData = self.PetData.activity_partner_pet_data
    if petData and petData.key_experience then
      evolute_info = petData.key_experience.evolute_info
    end
  elseif self.PetData and self.PetData.key_experience then
    evolute_info = self.PetData.key_experience.evolute_info
  end
  if evolute_info then
    Text = ""
    for i, Evolute in ipairs(evolute_info) do
      AddTime = os.date(LuaText.medal_text_5, Evolute.evolute_time)
      local BeforePetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.before_base_conf_id)
      local AfterPetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.after_base_conf_id)
      local msg = _G.DataConfigManager:GetLocalizationConf("pet_experience_form_1").msg
      local Text_Info = string.format(msg, AddTime, BeforePetBaseConf.name, AfterPetBaseConf.name)
      Text = string.format("%s%s", Text, Text_Info)
      if i ~= #evolute_info then
        Text = string.format("%s%s", Text, "\n")
      end
    end
  end
  return Text
end

function UMG_MedalPanel_C:GetPetPKInfo(isPartner)
  local Text = ""
  local legend_first_win_alone_info
  if isPartner then
    local petData = self.PetData.activity_partner_pet_data
    if petData and petData.key_experience then
      legend_first_win_alone_info = petData.key_experience.legend_first_win_alone_info
    end
  elseif self.PetData and self.PetData.key_experience then
    legend_first_win_alone_info = self.PetData.key_experience.legend_first_win_alone_info
  end
  if legend_first_win_alone_info then
    AddTime = os.date(LuaText.medal_text_5, legend_first_win_alone_info.win_time)
    local msg = _G.DataConfigManager:GetLocalizationConf("pet_experience_form_3").msg
    local Text_Info = string.format(msg, AddTime)
    Text = string.format("%s%s", Text, Text_Info)
  end
  return Text
end

function UMG_MedalPanel_C:GetPetClosenessInfo(isPartner)
  local Text, closeness_info, name
  if isPartner then
    local petData = self.PetData.activity_partner_pet_data
    if petData and petData.closeness_info then
      closeness_info = petData.closeness_info
      name = petData.name
    end
  elseif self.PetData and self.PetData.closeness_info then
    closeness_info = self.PetData.closeness_info
    name = self.PetData.name
  else
    closeness_info = self.PetData.closeness_info or nil
    name = self.PetData and self.PetData.name and self.PetData.name or nil
  end
  if name then
    local Closenesslv = closeness_info and closeness_info.closeness_lv and closeness_info.closeness_lv or 0
    local PetCloseLevelEffectConf = _G.DataConfigManager:GetPetCloseLevelEffectConf(Closenesslv + 1)
    if PetCloseLevelEffectConf.localization_id and PetCloseLevelEffectConf.localization_id ~= "" then
      local LocalizationConf = _G.DataConfigManager:GetLocalizationConf(PetCloseLevelEffectConf.localization_id)
      Text = string.format(LocalizationConf.msg, name)
    end
  end
  return Text
end

function UMG_MedalPanel_C:GetHeterochromeSuitInfo(isPartner)
  local Text, obtain_shiny_fashion_info
  if isPartner then
    local petData = self.PetData.activity_partner_pet_data
    if petData and petData.key_experience then
      obtain_shiny_fashion_info = petData.key_experience.obtain_shiny_fashion_info
    end
  elseif self.PetData and self.PetData.key_experience then
    obtain_shiny_fashion_info = self.PetData.key_experience.obtain_shiny_fashion_info
  end
  if obtain_shiny_fashion_info then
    local dateInfo = os.date("*t", obtain_shiny_fashion_info.obtain_time)
    local petName = ""
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(obtain_shiny_fashion_info.pet_base_id)
    if PetBaseConf then
      petName = PetBaseConf.name
    end
    local msg = _G.DataConfigManager:GetLocalizationConf("pet_experience_form_3_card").msg
    Text = string.format(msg, dateInfo.year, string.format("%02d", dateInfo.month), string.format("%02d", dateInfo.day), petName)
  end
  return Text
end

function UMG_MedalPanel_C:SetItemGainWay()
  if self.PetData == nil then
    return
  end
  local List = {}
  local Text
  if self.PetData.activity_partner_pet_data then
    Text = self:GetPetGainTimeAndWay(true)
    if Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon1_png.img_Medal_Icon1_png'"
      })
    end
    Text = self:GetPetNutureDesc(true)
    if Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon2_png.img_Medal_Icon2_png'"
      })
    end
    Text = self:GetPetBlessingInfo(true)
    if Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon6_png.img_Medal_Icon6_png'"
      })
    end
    Text = self:GetPetEvoluteInfo(true)
    if Text and "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon4_png.img_Medal_Icon4_png'"
      })
    end
    Text = self:GetPetPKInfo(true)
    if Text and "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon3_png.img_Medal_Icon3_png'"
      })
    end
    Text = self:GetPetClosenessInfo(true)
    if Text and "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon5_png.img_Medal_Icon5_png'"
      })
    end
    Text = LuaText.PET_Partner_10
    if Text and "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon1_png.img_Medal_Icon1_png'"
      })
    end
    Text = self:GetHeterochromeSuitInfo(true)
    if Text and "" ~= Text then
      table.insert(List, {
        Text = Text,
        Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon4_png.img_Medal_Icon4_png'"
      })
    end
  end
  Text = self:GetPetGainTimeAndWay(false)
  if Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon1_png.img_Medal_Icon1_png'"
    })
  end
  Text = self:GetPetNutureDesc(false)
  if Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon2_png.img_Medal_Icon2_png'"
    })
  end
  Text = self:GetPetBlessingInfo(false)
  if Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon6_png.img_Medal_Icon6_png'"
    })
  end
  Text = self:GetPetEvoluteInfo(false)
  if Text and "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon4_png.img_Medal_Icon4_png'"
    })
  end
  Text = self:GetPetPKInfo(false)
  if Text and "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon3_png.img_Medal_Icon3_png'"
    })
  end
  Text = self:GetPetClosenessInfo(false)
  if Text and "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon5_png.img_Medal_Icon5_png'"
    })
  end
  Text = self:GetHeterochromeSuitInfo(false)
  if Text and "" ~= Text then
    table.insert(List, {
      Text = Text,
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Icon4_png.img_Medal_Icon4_png'"
    })
  end
  if self.PetData.key_experience and self.PetData.key_experience.text_desc then
    for _, ExperienceID in pairs(self.PetData.key_experience.text_desc or {}) do
      if ExperienceID then
        local ExperienceConf = _G.DataConfigManager:GetTextExpConf(ExperienceID)
        if ExperienceConf then
          local ExperienceText = ""
          if 1 == ExperienceID then
            ExperienceText = string.format(LuaText[ExperienceConf.exp_localization_id], self.PetData.name)
          end
          table.insert(List, {
            Text = ExperienceText,
            Icon = ExperienceConf.exp_icon
          })
        end
      end
    end
  end
  self.ItemGainWay:InitList(List)
end

function UMG_MedalPanel_C:SetWeigthAndStature(petData)
  if not (petData and petData.weight) or not petData.height then
    return
  end
  local WeightData = petData.weight * 0.001
  local num = string.format("%.2f", WeightData)
  self.TextWeight:SetText(num)
  self.TextStature:SetText(string.format("%.2f", petData.height * 0.01))
end

function UMG_MedalPanel_C:GetPetCatchWay(petData)
  if petData then
    if petData.catch_way == Enum.PetCatchWay.PCW_WILD then
      local Count
      if petData.caught_camp then
        local CampConf = _G.DataConfigManager:GetCampConf(petData.caught_camp)
        if CampConf then
          Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_7").msg
          return string.format(Count, CampConf.camp_name)
        end
      end
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_VISIT then
      local Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_2").msg
      return string.format(Count, petData.catch_visit_owner_name)
    elseif petData.catch_way == Enum.PetCatchWay.PCW_EGGHATCH then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_3").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_DUNGEON then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_6").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_TEAMBATTLE then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_4").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_LEGEND then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_5").msg
    else
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    end
  end
end

function UMG_MedalPanel_C:OnClickButton_EquippableMedal()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MEDAL_USE, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_MedalPanel_C:OnClickButton_EquippableMedal")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenMedalWonPanel, self.PetData)
  self:DispatchEvent(PetUIModuleEvent.OpenDetailPanelEvent, true, true)
  self:DispatchEvent(PetUIModuleEvent.SetPetHiddenInGame, true)
end

return UMG_MedalPanel_C
