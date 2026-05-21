local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local enum = reload("Data.Config.Enum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_PetBaseInfo_C = _G.NRCViewBase:Extend("UMG_PetBaseInfo_C")

function UMG_PetBaseInfo_C:OnConstruct()
  self:SetChildViews(self.PetRadarInfo, self.UMG_PetRate)
  self.backpackState = false
  self.uiData = {
    petTempUpLevel = 0,
    petTempUpExp = 0,
    lastPetInfo = {},
    IsOnclickGrowUp = false
  }
  self.uiItem = {}
  self.uiItem.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  self.uiItem.skillIcons = {
    self.skillIcon1,
    self.skillIcon2,
    self.skillIcon3,
    self.skillIcon4
  }
  self.PetbeforeInfo = {}
  self.IsUpgrade = false
  self.IsHasOpenGroup = true
  self.data = self.module:GetData("PetUIModuleData")
  if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType) == PetUIModuleEnum.EnterType.PetInheritance then
    self.openPetTipsType = TipEnum.OpenPetTipsType.InheritancePet
  else
    self.openPetTipsType = TipEnum.OpenPetTipsType.PetMainPanel
  end
  self:SetBtnInfo()
  self:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_RED_POINT_NOTIFY, self.OnPetRedPointNotify)
  self:PlayIn()
  self:PetFriendInterfaceDisplay()
end

function UMG_PetBaseInfo_C:SetBtnInfo()
  self.icon1 = "PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/img_chengzhang_png.img_chengzhang_png'"
  self.UMG_btnLevelUp:SetBtnText(LuaText.umg_petbaseinfo_1)
  self.UMG_btnLevelUp_1:SetBtnText(LuaText.umg_petbaseinfo_1)
  self.UMG_btnLevelUp_2:SetBtnText(LuaText.umg_petlevelup_17)
  self.Btn_Details:SetBtnText(LuaText.umg_petlevelup_17)
  self.UMG_btnLevelUp_3:SetBtnText(LuaText.inspire_text_1)
  if self.data:GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PetAltar then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetBaseInfo_C:OnDeactive()
  self:CancelDelay()
  self:StopAllAnimations()
end

function UMG_PetBaseInfo_C:OnDestruct()
  self:OnRemoveEventListener()
  self:CancelDelay()
  table.clear(self.uiData)
  table.clear(self.uiItem)
  self.uiData = nil
  self.uiItem = nil
end

function UMG_PetBaseInfo_C:OnEnable()
end

function UMG_PetBaseInfo_C:OnDisable()
end

function UMG_PetBaseInfo_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_btnLevelUp.btnLevelUp, self.OnBtnLevelUpClick)
  self:AddButtonListener(self.UMG_btnLevelUp_1.btnLevelUp, self.OnBtnLevelUpClick)
  self:AddButtonListener(self.UMG_btnLevelUp_2.btnLevelUp, self.OnbtnLevelUp_1Click)
  self:AddButtonListener(self.UMG_btnLevelUp_3.btnLevelUp, self.OnInspireBtnClick)
  self:AddButtonListener(self.Btn_Details.btnLevelUp, self.OnbtnLevelUp_1Click)
  self:AddButtonListener(self.btnFightValue, self.OnBtnFightValueClick)
  self:AddButtonListener(self.NRCButton_45, self.OnBtnNRCButton_45Click)
  self:AddButtonListener(self.BtnRechristen_1, self.OnBtnRechristen_1Click)
  self:AddButtonListener(self.NRCButton_1, self.OnTalentBtnClick)
  self:AddButtonListener(self.NRCButton, self.OnTalentBtnClick)
  self.NRCButton_1.OnPressed:Add(self, self.OnNRCButton_1Pressed)
  self.NRCButton_1.OnReleased:Add(self, self.OnNRCButton_1Released)
  self.NRCButton.OnPressed:Add(self, self.OnNRCButton_1Pressed)
  self.NRCButton.OnReleased:Add(self, self.OnNRCButton_1Released)
  self:AddButtonListener(self.SkillBtn, self.OnFeatureSkillBtnClick)
  self:AddButtonListener(self.NRCButton_112, self.OnNRCButton_112Click)
  self:AddButtonListener(self.NRCButton_43, self.OnNRCButton_112Click)
  self.NRCButton_43.OnPressed:Add(self, self.OnNRCButton_43Pressed)
  self.NRCButton_43.OnReleased:Add(self, self.OnNRCButton_43Released)
  self.NRCButton_112.OnPressed:Add(self, self.OnNRCButton_43Pressed)
  self.NRCButton_112.OnReleased:Add(self, self.OnNRCButton_43Released)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self.BtnRechristen_1.OnPressed:Add(self, self.OnRechristenPressed)
  self.BtnRechristen_1.OnReleased:Add(self, self.OnRechristenReleased)
  self.BloodPulse.OnPressed:Add(self, self.OnBloodPulsePressed)
  self.BloodPulse.OnReleased:Add(self, self.OnBloodPulseReleased)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_EXPINFO_UPDATE, self.OnExpInfoUpdate)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_SELECT_SKILL_UPDATE, self.OnSelectSkillUpdate)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_CHANGE_SKILL_INFO, self.OnChangeSkillInfo)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_CHANGE, self.OnLeftSubPanelChange)
  self:RegisterEvent(self, PetUIModuleEvent.PetRename, self.UpdatePetName)
  self:RegisterEvent(self, PetUIModuleEvent.UpdatePetCollect, self.UpdateCollect)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_UPDATECURSTATE, self.OnUpdateCurState)
  self:RegisterEvent(self, PetUIModuleEvent.PetBaseInfoPlayEvoAnim, self.PlayEvoPanelAnim)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.OnDisableEvoBtn)
  _G.NRCEventCenter:RegisterEvent("UMG_PetBaseInfo_C", self, PetUIModuleEvent.EnterBackpack, self.OnBackpackOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_PetBaseInfo_C", self, PetUIModuleEvent.ExitBackpack, self.OnBackpackClose)
  _G.NRCEventCenter:RegisterEvent("UMG_PetBaseInfo_C", self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
  self.Button_Dazzling.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_Dazzling.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_DazzlingYise.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_DazzlingYise.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_Heterochrome.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_Heterochrome.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_Nightmare.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_Nightmare.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_DazzlingSeason.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_DazzlingSeason.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_DazzlingSeason_Hide.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_DazzlingSeason_Hide.OnReleased:Add(self, self.OnReleaseMutationBtn)
  self.Button_DemonicAnomaly.OnPressed:Add(self, self.OnOpenIconTips)
  self.Button_DemonicAnomaly.OnReleased:Add(self, self.OnReleaseMutationBtn)
end

function UMG_PetBaseInfo_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.EnterBackpack, self.OnBackpackOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.ExitBackpack, self.OnBackpackClose)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_RED_POINT_NOTIFY, self.OnPetRedPointNotify)
  self:RemoveButtonListener(self.Button_Dazzling, self.OnOpenIconTips)
  self:RemoveButtonListener(self.Button_DazzlingYise, self.OnOpenIconTips)
end

function UMG_PetBaseInfo_C:OnBackpackOpen()
  self.backpackState = true
  self:SetLevelBtnSwitch()
end

function UMG_PetBaseInfo_C:OnBackpackClose()
  self.backpackState = false
  self:SetLevelBtnSwitch()
end

function UMG_PetBaseInfo_C:OnPlayerDataChange()
  self:updatePetInfo()
end

function UMG_PetBaseInfo_C:OnExpInfoUpdate(_upLevel, _curTotalExp, _isAddItem, _IsShowMax)
  self.uiData.petTempUpLevel = _upLevel
  self.uiData.petTempUpExp = _curTotalExp
  self.uiData.isAddItem = _isAddItem
  self.uiData.isShowMax = _IsShowMax
  self.IsHasOpenGroup = false
  self:updatePetLevelAndExp()
end

function UMG_PetBaseInfo_C:OnSelectSkillUpdate(_skillPos)
  for i, skillIcon in ipairs(self.uiItem.skillIcons) do
    skillIcon:SetSelectState(i == _skillPos)
  end
end

function UMG_PetBaseInfo_C:OnChangeSkillInfo(_srcskill, _dstPos)
  local skillIcons = self.uiItem.skillIcons
  local srcIcon
  local dstIcon = skillIcons[_dstPos]
  local srcSkillId = _srcskill.id
  for i, skillIcon in ipairs(self.uiItem.skillIcons) do
    if i ~= _dstPos and skillIcon:getSkillId() == srcSkillId then
      srcIcon = skillIcon
      break
    end
  end
  if srcIcon then
    srcIcon:PlayChangeAnimation()
  end
  if dstIcon then
    dstIcon:PlayChangeAnimation()
  end
end

function UMG_PetBaseInfo_C:OnLeftSubPanelChange(_subPanelIndex)
  if _subPanelIndex and _subPanelIndex > 0 then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PetInfoPanelChanage(true)
  else
    self.Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self:SetLevelBtnSwitch()
    self:PetInfoPanelChanage(false)
  end
end

function UMG_PetBaseInfo_C:OnNewPetBagReleaseLifeModeChanged(IsReleaseLifeMode)
  self:UpdateViewInNewPetBagReleaseLifeMode()
end

function UMG_PetBaseInfo_C:UpdateViewInNewPetBagReleaseLifeMode()
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    if self.Btn then
      self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if UE4.UObject.IsValid(self.UMG_PetEvoTip) then
      self.UMG_PetEvoTip:ShowEvoTip(0)
    end
  end
end

function UMG_PetBaseInfo_C:OnSelectPetChange(_petData)
  self.PetbeforeInfo = self.uiData.petData or _petData
  self.uiData.petData = _petData
  if _petData then
    self.DetailsSwitcher:SetActiveWidgetIndex(0)
    if self.uiData then
      if self.uiData.petTempUpExp <= 0 then
        self.uiData.IsOnclickGrowUp = false
      end
      self.uiData.petTempUpLevel = 0
      self.uiData.petTempUpExp = 0
      self:SetMaxIcon(false)
      self:updatePetInfo()
      self:RefreshEvoState()
      self.uiData.isGroUp = false
    end
  end
end

function UMG_PetBaseInfo_C:RefreshEvoState()
  self.IsUpgrade = false
  self.data.EvoTargetCfgId = nil
  local playerRedPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  for k, v in ipairs(playerRedPointInfo) do
    if (v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_TEAM or v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_BACKPACK) and v.point_data and #v.point_data > 0 then
      for key, val in ipairs(v.point_data) do
        local dataList = string.Split(val, ".")
        if self.uiData and self.uiData.petData and self.uiData.petData.gid == tonumber(dataList[1]) then
          self.data.EvoTargetCfgId = dataList[2]
          self.IsUpgrade = true
          Log.Debug(self.data.EvoTargetCfgId, "UMG_PetBaseInfo_C:RefreshEvoState")
          break
        end
      end
    end
  end
  self:ShowEvoTip()
end

function UMG_PetBaseInfo_C:SetCulCanEvo(CanEvo, CanBreakThrough)
  self.CulCanEvo = CanEvo
  if CanBreakThrough then
    self.CultivateRed:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CultivateRed_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CultivateRed_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.CultivateRed:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CultivateRed_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CultivateRed_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:OnPetRedPointNotify(notify)
  if notify and notify.rp_group and #notify.rp_group > 0 then
    for k, v in ipairs(notify.rp_group) do
      if v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_TEAM or v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_BACKPACK then
        self:RefreshEvoState()
      end
    end
  end
end

function UMG_PetBaseInfo_C:PetInfoPanelChanage(IsChanage)
  if IsChanage then
    self.Panel_SpecialSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Panel_SpecialSkill:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetBaseInfo_C:OnPetGroUpSuccess(_changes)
  self.uiData.IsOnclickGrowUp = true
  local changes = _changes
  for i, v in ipairs(changes) do
    if v.pet_data then
      self.uiData.petData = v.pet_data
    end
  end
  self:updatePetInfo()
end

function UMG_PetBaseInfo_C:updatePetInfo()
  local petData = self.uiData.petData
  Log.Dump(petData, 6, "UMG_PetBaseInfo_C:updatePetInfo")
  if petData then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
    if not petBaseConf then
      self:clearPetInfo()
      return
    end
    local isHidden = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, petData.gid)
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
    if openPetData and friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      isHidden = true
    end
    if isHidden then
      self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.UMG_CollectBtn:UpdateInfo(petData.partner_mark, true)
    if 0 ~= petData.changed_nature_neg_attr_type or 0 ~= petData.changed_nature_pos_attr_type then
      self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_lailang_png.img_lailang_png'")
    else
      self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_character_png.img_character_png'")
    end
    self.uiData.petBaseConf = petBaseConf
    self:updatePetLevelAndExp()
    local specialityId = petData and petData.speciality_id
    if specialityId then
      local PetTalentConf = _G.DataConfigManager:GetPetTalentConf(specialityId)
      if PetTalentConf then
        local strText = PetTalentConf.name
        local str = string.StringGetTotalNum(strText)
        if str > 4 then
          self.Spacer:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Spacer_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.Spacer:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Spacer_71:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        if 2 == str or 6 == str then
          strText = string.format(" %s ", strText)
        end
        self.textPetNature_1:SetText(strText)
      end
    end
    self:updateFeatureSkill(petBaseConf)
    self:updatePetNature(petData.nature)
    self:updatePetGender(petData.gender)
    self:updatePetTypeIcon(petBaseConf.unit_type)
    self:updatePetEnergy(petData)
    self:UpdateMedalIcon()
    if self.PetRadarInfo and self.PetRadarInfo.updatePetInfo then
      self.PetRadarInfo:updatePetInfo(petData, petBaseConf)
    else
      Log.Error("self.PetRadarInfo or self.PetRadarInfo.updatePetInfo Not Found")
    end
    if utf8.len(petData.name) ~= nil and utf8.len(petData.name) > _G.DataConfigManager:GetPetGlobalConfig("pet_name_num_max").num then
      petData.name = string.sub(petData.name, 1, string.len(petData.name) - 3)
    end
    local name
    if petData.name ~= "" then
      if petData.name ~= nil then
        name = petData.name
      else
        name = petBaseConf.name
      end
    else
      name = petBaseConf.name
    end
    self.textPetName:SetText(name)
    local BallId = petData.ball_id
    if 0 == BallId then
      BallId = 100002
    end
    local CurIconConf = _G.DataConfigManager:GetBallConf(BallId)
    if CurIconConf then
      local CurIconPath = CurIconConf.ball_tips_icon
      self.UMG_PetEvoTip.CurIcon:SetPath(CurIconPath)
    end
    self:SetTalentRank(petData)
    self:SetLevelBtnSwitch()
    self:updatePetSkillInfo()
    self:updatePetTotleProp()
    self:SetCatchHardLV()
    self:SetMaxIcon(false)
    self:UpdatePetMutationIcon()
    self:SetSpecialSign()
  else
    self.uiData.petBaseConf = nil
    self:clearPetInfo()
  end
  local enterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  if enterType == PetUIModuleEnum.EnterType.PetInheritance then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCButton_45:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_PetEvoTip:SetDisableEvoTips(true)
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_PetBaseInfo_C:UpdateMedalIcon()
  if not self.uiData.petData then
    return
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    local petData = friendInfo.petData
    self:UpdateFriendPetEquipMedal(petData)
    if petData and petData.wear_medal_conf_id == nil or 0 == petData.wear_medal_conf_id then
      self.Meda:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    return
  end
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.uiData.petData.gid)
  if WearMedal then
    local medalLevelInfo = UIUtils.GetMedalLevelInfo(WearMedal.conf_id, WearMedal.complete_cnt)
    if medalLevelInfo then
      self.MedaIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.MedaIcon:SetPath(medalLevelInfo.icon2)
    end
  else
    self.MedaIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:SetTalentRank(petData)
  self.UMG_PetRate:SetText(petData, self.openPetTipsType)
end

function UMG_PetBaseInfo_C:OnUpdateCurState()
  self:ShowEvoTip()
end

function UMG_PetBaseInfo_C:UpdatePetName(refreshInfo)
  self.uiData.petData = refreshInfo.ret_info.goods_change_info.changes[1].pet_data
  local petRename = self.uiData.petData.name
  self.textPetName:SetText(petRename)
end

function UMG_PetBaseInfo_C:UpdateCollect(partner_mark)
  self.uiData.petData.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_PetBaseInfo_C:GetPreciseDecimal(num, n)
  if type(num) ~= "number" then
    return num
  end
  n = n or 0
  n = math.floor(n)
  if n < 0 then
    n = 0
  end
  local decimal = 10 ^ n
  local temp = math.floor(num * decimal)
  return temp / decimal
end

function UMG_PetBaseInfo_C:SetMaxIcon(IsShow)
  if IsShow then
    self.NRCText_MAX:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCText_MAX:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:SetLevelBtnSwitch()
  local PetInfo = self.uiData.petData
  if nil == PetInfo then
    return
  end
  if self.backpackState then
    self.Btn:SetActiveWidgetIndex(2)
    return
  end
  local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(self.uiData.petData)
  local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
  local LevelToplimit = _G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit")
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
  if nil ~= select_pet_conf_id then
    local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_PET_GROW)
    if not hideMagicManua then
      Log.Debug(self.uiData.petData.level, LevelToplimit.num, GrowOrder, #BreakNumberAllConf, self.uiData.petData.last_breakthrough_lv, self.uiData.petData.grow_times, "UMG_PetBaseInfo_C:SetLevelBtnSwitch")
      if self.uiData.petData.level < LevelToplimit.num and GrowOrder - 1 < #BreakNumberAllConf then
        self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Btn:SetActiveWidgetIndex(1)
      elseif self.uiData.petData.level >= LevelToplimit.num and GrowOrder - 1 >= #BreakNumberAllConf then
        self:SetInspireBtn()
      elseif self.uiData.petData.level >= LevelToplimit.num and GrowOrder - 1 < #BreakNumberAllConf then
        local isHidden = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, self.uiData.petData.gid)
        self.Btn:SetVisibility(isHidden and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Btn:SetActiveWidgetIndex(2)
      elseif self.uiData.petData.level < LevelToplimit.num and GrowOrder - 1 >= #BreakNumberAllConf then
        self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Btn:SetActiveWidgetIndex(0)
      end
    elseif self.uiData.petData.level >= LevelToplimit.num then
      self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn:SetActiveWidgetIndex(0)
    end
  elseif self.uiData.petData.level >= LevelToplimit.num then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn:SetActiveWidgetIndex(0)
  end
  self:PetFriendInterfaceDisplay()
  self:SetGrowUpTip()
  self:UpdateViewInNewPetBagReleaseLifeMode()
end

function UMG_PetBaseInfo_C:SetInspireBtn()
  if self.uiData == nil then
    Log.Error("UMG_PetBaseInfo_C:SetInspireBtn: uiData is nil")
    return
  end
  if nil == self.uiData.petData then
    Log.Error("UMG_PetBaseInfo_C:SetInspireBtn: petData is nil")
    return
  end
  local EnterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  local GrowUpType = PetUtils.GetPetGrowUpType(self.uiData.petData)
  if GrowUpType == PetUIModuleEnum.PetGrowUpType.WaitToInspire then
    if EnterType == PetUIModuleEnum.EnterType.PvpPetTeamUmg then
      self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn:SetActiveWidgetIndex(3)
    end
  elseif GrowUpType == PetUIModuleEnum.PetGrowUpType.Max then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:SetCatchHardLV()
  self.CatchHardLv:Clear()
  local PetStarsList = PetUtils.GetPetStarsListByPetGID(self.uiData.petData.gid, self.uiData.petData)
  self.CatchHardLv:InitGridView(PetStarsList)
end

function UMG_PetBaseInfo_C:updateFeatureSkill(PetbaseConf)
  local skillId, lock = PetUtils.GetPetFeatrueSkillId(PetbaseConf)
  if lock then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 0 ~= skillId then
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
    if skillCfg then
      if skillCfg.icon then
        self.SkillIcon:SetPath(skillCfg.icon)
      end
      self.SkillNameTxt:SetText(skillCfg.name)
    end
  else
    self.CanvasPanel_71:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:updatePetNature(_nature)
  local petNatureConf = _G.DataConfigManager:GetNatureConf(_nature)
  if petNatureConf then
    self.textPetNature:SetText(petNatureConf.name or "")
  end
end

function UMG_PetBaseInfo_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.uiItem.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PetBaseInfo_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  local BloodTypeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  self.Attr1:InitGridView(typeList)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.uiData.petData.blood_id)
  if PetBloodConf then
    table.insert(BloodTypeList, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.Attr:InitGridView(BloodTypeList)
end

function UMG_PetBaseInfo_C:UpdatePetMutationIcon()
  local petData = self.uiData.petData
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if petData and petData.mutation_type ~= _G.Enum.MutationDiffType.MDT_NONE then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
      self.Switcher:SetActiveWidgetIndex(0)
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS) then
      self.Switcher:SetActiveWidgetIndex(1)
    elseif PetMutationUtils.GetMutationValue(petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
      self.Switcher:SetActiveWidgetIndex(2)
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PetBaseInfo_C:updatePetEnergy(petData)
  local PetConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  self.petHpText:SetText(string.format("<curhp4>%d</><curhp4>/%d</>", petData.energy, PetConf.max_energy))
end

function UMG_PetBaseInfo_C:updatePetLevelAndExp()
  local petData = self.uiData.petData
  local lastPetInfo = self.uiData.lastPetInfo
  if petData then
    local petLevelConf = _G.DataConfigManager:GetPetLevelConf(petData.level)
    local curExp = petData.exp or 0
    local maxExp = petLevelConf and petLevelConf.pet_exp or 1
    local expInfo, levelInfo
    local maxPetLevel = PetUtils.GetPetMaxLevel(self.uiData.petData)
    if petData.level > 1 then
      petLevelConf = _G.DataConfigManager:GetPetLevelConf(petData.level - 1)
      if petLevelConf then
        maxExp = maxExp - petLevelConf.pet_exp
        curExp = curExp - petLevelConf.pet_exp
      end
    end
    expInfo = string.format("%d<tex2>/%d</>", curExp, maxExp)
    levelInfo = string.format("<lv>%d</><tex2>/%d</>", petData.level or 0, maxPetLevel)
    if self.uiData.isShowMax == false then
      self:SetMaxIcon(true)
    else
      self:SetMaxIcon(false)
    end
    local expPercent = curExp / maxExp
    self.textPetExp:SetVisibility(UE4.ESlateVisibility.Visible)
    self.textPetExp:SetText(expInfo)
    self.textPetLevel:SetText(levelInfo)
    self.textPetExp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.progressPetExp:SetPercent(expPercent)
    local maxPetLevelInfo = _G.DataConfigManager:GetPetGlobalConfig("pet_level_toplimit").num
    if maxPetLevelInfo <= petData.level then
      self.textPetExp:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.progressPetExp:SetPercent(1)
    end
    if maxPetLevelInfo > petData.level and petData.overflow_exp and 0 ~= petData.overflow_exp then
      self.textPetExp_1:SetText(petData.overflow_exp)
      self.experience:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.experience:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    lastPetInfo.gid = 0
  end
end

function UMG_PetBaseInfo_C:playPetExpAnimation(_petLevel, _petExpPercent)
  if not self.uiData then
    self.progressPetExp:SetPercent(_petExpPercent)
    return
  end
  if self.uiData.IsOnclickGrowUp == false then
    self:DispatchEvent(PetUIModuleEvent.PET_UI_UPGRADE_CONSTRAINT, true)
  end
  local lastPetInfo = self.uiData.lastPetInfo
  local oldLevel = lastPetInfo.level or 0
  local newLevel = _petLevel
  local oldPercent = lastPetInfo.expPercent or 0
  local newPercent = _petExpPercent
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime() + aniTime * oldPercent
  local endTime = ani:GetStartTime() + aniTime * newPercent
  Log.Debug(newLevel, oldLevel, "UMG_PetBaseInfo_C:playPetExpAnimation")
  if newLevel ~= oldLevel then
    lastPetInfo.isContinueExpEffect = true
    endTime = ani:GetEndTime()
  else
    self.uiData.IsOnclickGrowUp = false
  end
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  if false == lastPetInfo.isContinueExpEffect then
    self:DelaySeconds(endTime - beginTime, function()
      self:DispatchEvent(PetUIModuleEvent.PET_UI_UPGRADE_CONSTRAINT, false)
    end)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1036, "UMG_PetBaseInfo_C:playPetExpAnimation")
  self:PlayAnimationTimeRange(ani, beginTime, endTime)
end

function UMG_PetBaseInfo_C:OnPetExpEffectPlayEnd()
  local petData = self.uiData.petData
  local lastPetInfo = self.uiData.lastPetInfo
  local maxPetLevel = PetUtils.GetPetMaxLevel(self.uiData.petData)
  if maxPetLevel <= petData.level then
    self.textPetExp:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.progressPetExp:SetPercent(1)
    if self.uiData.IsOnclickGrowUp == false then
      NRCModuleManager:DoCmd(PetUIModuleCmd.PetUpgradePopout, self.PetbeforeInfo, self.uiData, self.petInfoMainCtrl)
      self:SetLevelBtnSwitch()
    end
    return
  end
  if not lastPetInfo.isContinueExpEffect then
    self.progressPetExp:SetPercent(lastPetInfo.expPercent)
    return
  end
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime()
  local endTime = ani:GetStartTime() + aniTime * lastPetInfo.expPercent
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  self:PlayAnimationTimeRange(ani, beginTime, endTime)
  self:PlayAnimation(self.LevelUp)
  lastPetInfo.isContinueExpEffect = false
end

function UMG_PetBaseInfo_C:updatePetSkillInfo()
  local petEquipSkills = {}
  local petData = self.uiData.petData
  if petData and petData.skill and petData.skill.skill_data then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped then
        petEquipSkills[skillData.pos] = skillData
      end
    end
  end
  self.uiData.petEquipSkills = petEquipSkills
end

function UMG_PetBaseInfo_C:updatePetSpecialSkill()
  local skillData = self.uiData.petEquipSkills[enum.PetSkillPos.PET_FEATURE_SKILL_POS]
  if skillData then
    local skillCfg = _G.DataConfigManager:GetSkillConf(skillData.id)
    if skillCfg then
      self.specialSkillIicon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.specialSkillIicon:SetPath(skillCfg.icon)
      self.textSpecialSkillName:SetText(skillCfg.name)
      self.textSpecialSkillDesc:SetText(skillCfg.desc)
      return
    end
  end
  self:clearPetSpecialSkill()
end

function UMG_PetBaseInfo_C:clearPetSpecialSkill()
  if self.specialSkillIicon then
    self.specialSkillIicon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.textSpecialSkillName:SetText("")
  if self.textSpecialSkillDesc then
    self.textSpecialSkillDesc:SetText("")
  end
end

function UMG_PetBaseInfo_C:updatePetNormalSkill()
  local petData = self.uiData.petData
  if petData then
    local petSkillDatas = self.uiData.petEquipSkills
    for i, skillIcon in ipairs(self.uiItem.skillIcons) do
      local skillData = petSkillDatas[i]
      skillIcon:SetSkillData(petSkillDatas[i], i)
      skillIcon:SetClickCallback(self, self.OnNormalSkillClick)
    end
  end
end

function UMG_PetBaseInfo_C:clearPetNormalSkill()
  for i, skillIcon in ipairs(self.uiItem.skillIcons) do
    skillIcon:SetSkillData(nil)
  end
end

function UMG_PetBaseInfo_C:updatePetTotleProp()
  local PetBasePropList = {
    enum.AttributeType.AT_HPMAX,
    enum.AttributeType.AT_PHYATK,
    enum.AttributeType.AT_PHYDEF,
    enum.AttributeType.AT_SPEATK,
    enum.AttributeType.AT_SPEDEF,
    enum.AttributeType.AT_SPEED
  }
  local petData = self.uiData.petData
  local petBaseConf = self.uiData.petBaseConf
  if petData and petBaseConf then
    local value = 0
    for _, propType in ipairs(PetBasePropList) do
      value = value + PetUtils.CalcProperty(petBaseConf, petData, propType) or 0
    end
    self.textPetTotleProp:SetText(value)
  end
end

function UMG_PetBaseInfo_C:clearPetInfo()
  self.textPetNature:SetText("")
  self.textPetName:SetText("")
  self.textPetExp:SetText("")
  self.textPetLevel:SetText("")
  self.textPetTotleProp:SetText("")
  self:updatePetGender(0)
  self:updatePetTypeIcon({})
  self:clearPetSpecialSkill()
  self:clearPetNormalSkill()
end

function UMG_PetBaseInfo_C:OnNormalSkillClick(_skillData, _skillIndex)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnNormalSkillClick")
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:showSkillMainPanel(_skillData, _skillIndex)
  end
end

function UMG_PetBaseInfo_C:OnBtnLevelUpClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_ADD_PET_EXP, true)
  if isBan then
    return
  end
  local itemList = NRCModeManager:DoCmd(BagModuleCmd.GetCanFeedItem)
  if #itemList <= 0 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petbaseinfo_5)
  else
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenLevelUpPanel, self.petInfoMainCtrl, self.uiData)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetPetRightPanelShareComboBox)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002011, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
end

function UMG_PetBaseInfo_C:OnbtnLevelUp_1Click()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_GROW, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetBaseInfo_C:OnbtnLevelUp_1Click")
  local PetInfo = self.uiData.petData
  local maxPetLevel = PetUtils.GetPetGrowLevel(self.uiData.petData)
  if maxPetLevel <= PetInfo.level then
  end
  if UE4.UObject.IsValid(self.petInfoMainCtrl) then
    self.uiData.IsOnclickGrowUp = true
    self.petInfoMainCtrl:ShowGrowUpPanel()
    self:DispatchEvent(PetUIModuleEvent.OpenGrowUpSwitchCloseBtn)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetPetRightPanelShareComboBox)
  end
end

function UMG_PetBaseInfo_C:OnInspireBtnClick()
  if self.uiData == nil then
    Log.Error("UMG_PetBaseInfo_C:OnInspireBtnClick uiData is nil")
    return
  end
  if nil == self.uiData.petData then
    Log.Error("UMG_PetBaseInfo_C:OnInspireBtnClick petData is nil")
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_GROW, true)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetBaseInfo_C:OnInspireBtnClick")
  if UE4.UObject.IsValid(self.petInfoMainCtrl) then
    self.uiData.IsOnclickGrowUp = true
    self.petInfoMainCtrl:ShowGrowUpPanel()
    self:DispatchEvent(PetUIModuleEvent.OpenGrowUpSwitchCloseBtn)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetPetRightPanelShareComboBox)
  end
end

function UMG_PetBaseInfo_C:OnBtnLevelUp2Click()
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:TrainPet()
  end
end

function UMG_PetBaseInfo_C:OnBtnFightValueClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnFightValueClick")
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenLevelUpPanel, self.petInfoMainCtrl, self.uiData)
end

function UMG_PetBaseInfo_C:OnBtnNRCButton_45Click()
  if self:IsAnimationPlaying(self.New_In) then
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetIsPlayPetSkill) then
    return
  end
  if _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_MINI_GAME) then
    local tip = _G.DataConfigManager:GetLocalizationConf("Error_Code_2331").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip)
    return
  end
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    return
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPetData and friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    return
  end
  local IsPlayPetSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsPlayPetSkill)
  if IsPlayPetSkill then
    return
  end
  local isLock = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetBox")
  if isLock then
    return
  end
  local isLock1 = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetInfoMain")
  if isLock1 then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  self:EnterLevelUp()
end

function UMG_PetBaseInfo_C:OnBtnRechristen_1Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips, self.uiData and self.uiData.petData)
end

function UMG_PetBaseInfo_C:OnNRCButton_112Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpendblockerTips, self.openPetTipsType, self.uiData and self.uiData.petData)
end

function UMG_PetBaseInfo_C:OnTalentBtnClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenTipsStrongPoint, self.uiData.petData)
end

function UMG_PetBaseInfo_C:OnFeatureSkillBtnClick()
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPeculiarityTips, self.uiData.petData)
end

function UMG_PetBaseInfo_C:OnNRCButton_43Pressed()
  self:StopAnimation(self.Press_4)
  self:StopAnimation(self.Up_4)
  self:PlayAnimation(self.Press_4)
end

function UMG_PetBaseInfo_C:OnNRCButton_43Released()
  self:StopAnimation(self.Press_4)
  self:StopAnimation(self.Up_4)
  self:PlayAnimation(self.Up_4)
end

function UMG_PetBaseInfo_C:OnNRCButton_1Pressed()
  self:StopAnimation(self.Press_5)
  self:StopAnimation(self.Up_5)
  self:PlayAnimation(self.Press_5)
end

function UMG_PetBaseInfo_C:OnNRCButton_1Released()
  self:StopAnimation(self.Press_5)
  self:StopAnimation(self.Up_5)
  self:PlayAnimation(self.Up_5)
end

function UMG_PetBaseInfo_C:OnBloodPulse()
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_PetBaseInfo_C:OnBloodPulse")
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetUIOpenPetBloodPulse, self.uiData.petData, self.openPetTipsType)
end

function UMG_PetBaseInfo_C:OnCollectBtn()
  local enterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  if enterType == PetUIModuleEnum.EnterType.PetInheritance then
    return
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.uiData.petData.gid, self.uiData.petData.partner_mark)
end

function UMG_PetBaseInfo_C:OnPanelStateChange(_isShow)
  if _isShow then
    if self.uiData and self.uiData.petData then
      self.DetailsSwitcher:SetActiveWidgetIndex(0)
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAniEx(self.New_in)
      self:UpdateMedalIcon()
    else
      self:SetEmpty()
    end
  else
    self:StopAllAnimations()
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetBaseInfo_C:SetEmpty()
  self.DetailsSwitcher:SetActiveWidgetIndex(1)
end

function UMG_PetBaseInfo_C:OnAnimationFinished(Animation)
  if Animation == self.Exp_ADD then
    self:OnPetExpEffectPlayEnd()
  elseif Animation == self.LevelUp then
    if self.uiData.IsOnclickGrowUp == false then
      NRCModuleManager:DoCmd(PetUIModuleCmd.PetUpgradePopout, self.PetbeforeInfo, self.uiData, self.petInfoMainCtrl)
      self:SetLevelBtnSwitch()
    end
    self.uiData.IsOnclickGrowUp = false
  elseif Animation == self.Out_Xxqh then
  elseif Animation == self.In then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_PetBaseInfo_C:OnRechristenPressed()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Press_1)
end

function UMG_PetBaseInfo_C:OnRechristenReleased()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Up_1)
end

function UMG_PetBaseInfo_C:OnBloodPulsePressed()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Press_2)
end

function UMG_PetBaseInfo_C:OnBloodPulseReleased()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Up_2)
end

function UMG_PetBaseInfo_C:setPetInfoMainCtrl(_petInfoMainCtrl)
  self.petInfoMainCtrl = _petInfoMainCtrl
end

function UMG_PetBaseInfo_C:PlayAniEx(_ani)
  if _ani and not self:IsAnimationPlaying(_ani) then
    self:PlayAnimation(_ani)
  end
end

function UMG_PetBaseInfo_C:PlayIn()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.New_in)
  self.PetRadarInfo:PlayAnimationIn()
end

function UMG_PetBaseInfo_C:EnterLevelUp()
  if self.IsUpgrade == false then
    return
  end
  local petData = self.uiData.petData
  local petLv = petData.level or 0
  local evolutionPetBaseId, evolutionIndex = self:GetEvolutionPetBaseId(petData.base_conf_id)
  Log.Warning("\232\191\155\229\140\150\229\149\166\239\188\129")
  if evolutionIndex then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").EVO
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
    local petEvoInfo = {}
    table.insert(petEvoInfo, {
      beforeBaseConfId = petData.base_conf_id,
      afterBaseConfigId = evolutionPetBaseId,
      petGid = petData.gid,
      evoIndex = evolutionIndex - 1
    })
    self.petInfoMainCtrl:ShowOrHideViewingBtn(false)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseMoreList, false)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetEvoNewPanel, petEvoInfo, 0)
  else
    Log.Error("\232\191\155\229\140\150\228\191\161\230\129\175\230\156\137\232\175\175")
  end
end

function UMG_PetBaseInfo_C:GetEvolutionPetBaseId(petBaseID)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseID)
  local petEvolutionList = petBaseConf.evolution_pet_id
  local petEquipSkillList = self:GetPetEquipSkills(self.uiData.petData)
  local TargetEvoPetBaseId
  local playerRedPointInfo = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  for k, v in ipairs(playerRedPointInfo) do
    if (v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_TEAM or v.reason_type == _G.Enum.RedPointReason.RPR_PET_EVOLVE_BACKPACK) and v.point_data and #v.point_data > 0 then
      for key, val in ipairs(v.point_data) do
        local dataList = string.Split(val, ".")
        if self.uiData and self.uiData.petData and self.uiData.petData.gid == tonumber(dataList[1]) then
          TargetEvoPetBaseId = dataList[2]
          if "string" == type(TargetEvoPetBaseId) then
            TargetEvoPetBaseId = tonumber(TargetEvoPetBaseId)
          end
          break
        end
      end
    end
  end
  if TargetEvoPetBaseId and petEvolutionList then
    for i = 1, #petEvolutionList do
      if petEvolutionList[i] and TargetEvoPetBaseId == petEvolutionList[i] then
        return TargetEvoPetBaseId, i
      end
    end
  end
  return nil
end

function UMG_PetBaseInfo_C:CheckPetEvoCondition(conditionEnum)
  if conditionEnum == _G.Enum.PetEvolutionCondition.PEC_LEVEL_UP then
  elseif conditionEnum == _G.Enum.PetEvolutionCondition.PEC_NEED_GENDER then
  elseif conditionEnum == _G.Enum.PetEvolutionCondition.PEC_NEED_NATURE then
  elseif conditionEnum == _G.Enum.PetEvolutionCondition.PEC_NEED_TIME then
  elseif conditionEnum == _G.Enum.PetEvolutionCondition.PEC_NEED_WEATHER then
  elseif conditionEnum == _G.Enum.PetEvolutionCondition.PEC_NEED_LINK then
  end
end

function UMG_PetBaseInfo_C:GetPetEquipSkills(petData)
  local petEquipSkills = {}
  if petData then
    for i, skillData in ipairs(petData.skill.skill_data) do
      if skillData.is_equipped and skillData.pos > 0 and skillData.pos <= 4 then
        table.insert(petEquipSkills, skillData)
      end
    end
  end
  return petEquipSkills
end

function UMG_PetBaseInfo_C:SetGrowUpTip()
  self.NrcRedPoint:SetupKey(135, {
    self.uiData.petData.gid
  })
  self.NrcRedPoint_1:SetupKey(135, {
    self.uiData.petData.gid
  })
end

function UMG_PetBaseInfo_C:GetListIconInfo()
  local petData = self.uiData.petData
  local ItemInfos = PetUtils.GetPetGrowNeedItems(petData)
  local PlayerWorldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
  local BreakLevelPoint, GrowOrder = PetUtils.GetPetGrowLevel(petData)
  local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
  if GrowOrder >= 1 and GrowOrder <= #BreakNumberAllConf then
    local BreakNumberConf = _G.DataConfigManager:GetBreakNumberConf(GrowOrder)
    if PlayerWorldLevel < BreakNumberConf.world_level_limit then
      return false
    end
    local needneedMoney = BreakNumberConf.currency_number
    local curMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
    if needneedMoney <= curMoney then
      for i = 1, #ItemInfos do
        local item = ItemInfos[i]
        if item.needCount > item.itemCount then
          return false
        end
      end
      return true
    end
  end
  return false
end

function UMG_PetBaseInfo_C:getItemCount(_itemId)
  local itemData = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, _itemId)
  if itemData then
    return itemData.num or 0
  end
  return 0
end

function UMG_PetBaseInfo_C:ShowEvoTip()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.IsUpgrade = false
  end
  if self.IsUpgrade and not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) then
    self.UMG_PetEvoTip:ShowEvoTip(10)
  else
    self.UMG_PetEvoTip:ShowEvoTip(0)
  end
end

function UMG_PetBaseInfo_C:PlayEvoPanelAnim(bEvo)
  if bEvo then
    self:PlayAnimation(self.To_Jinhua_1)
    self.UMG_PetEvoTip:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:PlayAnimation(self.BackTo_Jingling_1)
    self.UMG_PetEvoTip:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetBaseInfo_C:OnDisableEvoBtn(isDisable)
  if isDisable then
    self.NRCButton_45:SetIsEnabled(false)
  else
    self.NRCButton_45:SetIsEnabled(true)
  end
end

function UMG_PetBaseInfo_C:SetSpecialSign()
  self.State_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if PetUtils.CheckIsShiningChaos(self.uiData.petData.mutation_type) then
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(6)
  elseif PetUtils.CheckIsCHAOS(self.uiData.petData.mutation_type) then
    if self:IsAnimationPlaying(self.New_in) then
    end
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(2)
  elseif PetUtils.CheckIsHiddenShiningGlass(self.uiData.petData.mutation_type, self.uiData.petData.glass_info) then
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(5)
    local path = self:GetHiddenGlassIcon(true)
    if "" ~= path then
      self.Nightmare_3:SetPath(path)
    end
  elseif PetUtils.CheckIsShiningGlass(self.uiData.petData.mutation_type) then
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(3)
  elseif PetMutationUtils.GetMutationValue(self.uiData.petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    if self:IsAnimationPlaying(self.New_in) then
      self.Heterochrome:SetRenderOpacity(0)
    end
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(1)
  elseif PetUtils.CheckIsHiddenGlass(self.uiData.petData.mutation_type, self.uiData.petData.glass_info) then
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(4)
    local path = self:GetHiddenGlassIcon(false)
    if "" ~= path then
      self.Nightmare_2:SetPath(path)
    end
  elseif PetMutationUtils.GetMutationValue(self.uiData.petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    if self:IsAnimationPlaying(self.New_in) then
      self.Dazzling:SetRenderOpacity(0)
    end
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetActiveWidgetIndex(0)
  end
end

function UMG_PetBaseInfo_C:OnOpenIconTips()
  self:StopAnimation(self.Press_3)
  self:StopAnimation(self.Up_3)
  self:PlayAnimation(self.Press_3)
  if not self.uiData.petData then
    Log.Warning("UMG_PetBaseInfo_C:OnOpenIconTips self.uiData.petData is nil")
    return
  end
  if PetUtils.CheckIsHiddenShiningGlass(self.uiData.petData.mutation_type, self.uiData.petData.glass_info) or PetUtils.CheckIsHiddenGlass(self.uiData.petData.mutation_type, self.uiData.petData.glass_info) or PetUtils.CheckIsShiningGlass(self.uiData.petData.mutation_type) or PetMutationUtils.GetMutationValue(self.uiData.petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenDazzlingTipsPanel, self.uiData.petData)
  elseif PetUtils.CheckIsCHAOS(self.uiData.petData.mutation_type) or PetMutationUtils.GetMutationValue(self.uiData.petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenMutationTipsPanel, self.uiData.petData)
  end
end

function UMG_PetBaseInfo_C:OnReleaseMutationBtn()
  self:StopAnimation(self.Press_3)
  self:StopAnimation(self.Up_3)
  self:PlayAnimation(self.Up_3)
end

function UMG_PetBaseInfo_C:GetHiddenGlassIcon(bShiningGlass)
  if self.uiData.petData and self.uiData.petData.glass_info then
    local HiddenGlassID = self.uiData.petData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if bShiningGlass and HiddenGlassConf.yise_icon then
          return HiddenGlassConf.yise_icon
        elseif HiddenGlassConf.icon then
          return HiddenGlassConf.icon
        end
      end
    end
  end
  return ""
end

function UMG_PetBaseInfo_C:PetFriendInterfaceDisplay()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPetData and friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsUpgrade = false
  end
end

function UMG_PetBaseInfo_C:UpdateFriendPetEquipMedal(petData)
  if petData.wear_medal_conf_id then
    local MedalConf = _G.DataConfigManager:GetMedalConf(petData.wear_medal_conf_id)
    self.Meda:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if MedalConf then
      self.MedaIcon:SetPath(MedalConf.big_icon)
    end
  end
end

return UMG_PetBaseInfo_C
