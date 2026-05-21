local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_Pet_Attribute_C = _G.NRCViewBase:Extend("UMG_Pet_Attribute_C")

function UMG_Pet_Attribute_C:OnConstruct()
  self.showing = true
  self.IsFirstIn = true
  self.lockAll = false
  self:SetBtnInfo()
  self:OnAddEventListener()
  self.DetailPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.owner:SwitchToThumbVersion(self.IsFirstIn)
  self.owner:PlayAniMationOpenXqAniReverse(self.IsFirstIn)
  self:PlayAnimation(self.RightIConbreathe, 0, 9999)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_Attribute_C:SetBtnInfo()
  local Icon = "PaperSprite'/Game/NewRoco/Modules/System/CommonBtn/Raw/Frames/img_gaimingputong_png.img_gaimingputong_png'"
  self.Btn_Rename:SetPath(Icon, Icon, Icon)
end

function UMG_Pet_Attribute_C:OnActive()
end

function UMG_Pet_Attribute_C:OnDeactive()
  if self.module then
    self.module:OnSavePetBagChildrenPanelState("Attribute", false)
  end
  self:StopAllAnimations()
end

function UMG_Pet_Attribute_C:OnAddEventListener()
  self:AddButtonListener(self.SwitchButton, self.OnClickSwitchBtn)
  self:RegisterEvent(self, PetUIModuleEvent.PetRename, self.UpdatePetName)
  self:AddButtonListener(self.Btn_Rename.btnLevelUp, self.RenameClick)
  self:AddButtonListener(self.DepartBtn, self.OpenPetTips)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
  self:RegisterEvent(self, PetUIModuleEvent.PlayAttributeOutAnim, self.PlayOpenXqAnB)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.btn2.btnLevelUp, self.onClickRemoveEgg)
  self.DepartBtn.OnPressed:Add(self, self.OnDepartBtnPressed)
  self.DepartBtn.OnReleased:Add(self, self.OnDepartBtnReleased)
  self.BloodPulse.OnPressed:Add(self, self.OnBloodPulsePressed)
  self.BloodPulse.OnReleased:Add(self, self.OnBloodPulseReleased)
end

function UMG_Pet_Attribute_C:OpenPetTips()
  if self.owner and self.owner.uiData and self.petData then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, self.owner.uiData, _G.Enum.GoodsType.GT_PET)
  end
end

function UMG_Pet_Attribute_C:CloseSwitchButton(_IsDisabled)
  if _IsDisabled then
    self.ButtonSwitch:SetIsEnabled(false)
  else
    self.ButtonSwitch:SetIsEnabled(true)
  end
end

function UMG_Pet_Attribute_C:OnBloodPulse()
  if self.petData then
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetBloodPulse, self.petData, TipEnum.OpenPetTipsType.PetMainPanel)
  end
end

function UMG_Pet_Attribute_C:onClickRemoveEgg()
  _G.NRCAudioManager:PlaySound2DAuto(1086, "UMG_Pet_Attribute_C:onClickRemoveEgg")
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local conf = _G.DataConfigManager:GetPetGlobalConfig("hatch_interrupt_text")
  local title = LuaText.umg_pet_attribute_1
  local des = conf and conf.str or LuaText.umg_pet_attribute_2
  local leftText = conf and conf.button_left or LuaText.umg_pet_attribute_3
  local rightText = conf and conf.button_right or LuaText.umg_pet_attribute_4
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.RemoveEggCallblack):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Pet_Attribute_C:RemoveEggCallblack(isOk)
  if isOk and self.eggInfo then
    local gid = self.eggInfo.gid
    local hatchedMax = _G.DataConfigManager:GetPetEggConf(self.eggInfo.bagItem.egg_data.conf_id).hatch_data
    local hatchedSecs = self.eggInfo.bagItem.egg_data.hatched_secs
    if hatchedMax <= hatchedSecs then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.umg_pet_attribute_5)
      return
    end
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ZoneStopHatchReq, gid)
  end
  _G.NRCAudioManager:PlaySound2DAuto(1220002039, "UMG_Pet_Attribute_C:RemoveEggCallblack")
end

function UMG_Pet_Attribute_C:PlayAnimationIn()
  self:PlayAnimation(self.Open_jinglingye)
end

function UMG_Pet_Attribute_C:UpdatePetName(refreshInfo)
  self.owner.uiData.init_pet_gid = self.owner.currentPetInfo.gid
  local petData = refreshInfo.ret_info.goods_change_info.changes[1].pet_data
  self.owner:ChangePetNameByPetData(petData)
  self.PetName:SetText(petData.name)
  self:SetOnNewStateRemove()
end

function UMG_Pet_Attribute_C:SetOnNewStateRemove()
  if self.petData and self.petData.gid and self.Btn_Rename.RedDot and self.Btn_Rename.RedDot:IsRed() then
    self.Btn_Rename.RedDot:EraseRedPoint()
  end
end

function UMG_Pet_Attribute_C:RenameClick()
  if self.petData then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenRechristenPanel, self.petData)
    NRCModuleManager:DoCmd(RedPointModuleCmd.EraseRedPoint, 136, {
      self.petData.gid
    })
  end
end

function UMG_Pet_Attribute_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "PetUIModule", "PetBox")
end

function UMG_Pet_Attribute_C:OnClickSwitchBtn()
  if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetIsPlayPetSkill) then
    return
  end
  self:SwitchVersion()
end

function UMG_Pet_Attribute_C:SwitchVersion(bSkipCheck)
  if self.lockAll and not bSkipCheck then
    return false
  end
  if self:CheckIsSelectBtn() and not bSkipCheck then
    return false
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").SUBPANEL
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  local IsPlayPetSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetIsPlayPetSkill)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  if IsPlayPetSkill and self:IsCanPlayPetSkill() and self.showing and not bSkipCheck then
    return false
  end
  local IsOpenAttribute = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetAttribute)
  if not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCanSharePet) and not IsOpenAttribute and self.showing and not bSkipCheck then
    return false
  end
  self.isEgg = false and self.petInfo.isEgg or true
  if not bSkipCheck then
    self.module:OnSavePetBagChildrenPanelState("Attribute", self.showing)
  end
  self.showing = not self.showing
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, self.showing)
  self.IsFirstIn = false
  self.lockAll = true
  self:StopAllAnimations()
  self:DispatchEvent(PetUIModuleEvent.AttributeChangeSetEggBtn, self.showing)
  if self.showing then
    _G.NRCAudioManager:PlaySound2DAuto(40002010)
    self:ShowThumbDetail()
    self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 0)
    self.ButtonSwitch:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ButtonSwitch:SetActiveWidgetIndex(0)
    self:DispatchEvent(PetUIModuleEvent.SwitchCloseBtnState, 2)
    self:PlayAnimation(self.OpenXqAniA_Back)
  else
    _G.NRCAudioManager:PlaySound2DAuto(40002009)
    self:HideThumbDetail()
    self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 1)
    self.ButtonSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:DispatchEvent(PetUIModuleEvent.SwitchCloseBtnState, 1)
    if 1 == self.owner.curMenuButtonIndex then
    end
  end
  return true
end

function UMG_Pet_Attribute_C:IsCanPlayPetSkill()
  if not self.IsFirstIn then
    return true
  end
  local IsOpenSkill = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetSKill)
  local IsOpenAttribute = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetAttribute)
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if IsOpenSkill or IsOpenAttribute or openPetData then
    return false
  end
  return true
end

function UMG_Pet_Attribute_C:SwitchVersion1()
  self.showing = not self.showing
  self.IsFirstIn = false
  if self.showing then
    _G.NRCAudioManager:PlaySound2DAuto(1354)
    self:ShowThumbDetail()
    self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 0)
  else
    _G.NRCAudioManager:PlaySound2DAuto(1353)
    self:HideThumbDetail()
    self:DispatchEvent(PetUIModuleEvent.OpenDetailCameraLocation, 1)
    if 1 == self.owner.curMenuButtonIndex then
    end
  end
  self.ButtonSwitch:SetActiveWidgetIndex(1)
  self.TakeBack:SetRenderOpacity(1.0)
end

function UMG_Pet_Attribute_C:SetOwner(owner)
  self.owner = owner
end

function UMG_Pet_Attribute_C:ShowThumbDetail()
  self.DetailPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseRightPanel)
  self.owner:SwitchToThumbVersion(self.IsFirstIn)
  self.owner:PlayAniMationOpenXqAniReverse(self.IsFirstIn)
end

function UMG_Pet_Attribute_C:HideThumbDetail()
  self.DetailPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenRightPanel, self.owner.petInfoMainCtrl, nil, self.bShowSendMark)
  self.owner:SwitchToDetailVersion()
  self.owner:PlayAniMationOpenXqAni()
end

function UMG_Pet_Attribute_C:IsOpenDetail()
  local Visible = self.DetailPanel:GetVisibility()
  Log.Debug(Visible, 6, "UMG_Pet_Attribute_C:IsOpenDetail")
  if Visible == UE4.ESlateVisibility.Visible or Visible == UE4.ESlateVisibility.SelfHitTestInvisible then
    return true
  else
    return false
  end
end

function UMG_Pet_Attribute_C:UpdatePetData(petInfo)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, self.showing)
  if nil == petInfo then
    self:SetPetBriefInfoVisibility(false)
    self.petInfo = nil
    self.petData = nil
  else
    self.isEgg = false
    self:SetPetBriefInfoVisibility(true)
    self.Switcher_77:SetActiveWidgetIndex(0)
    self.petInfo = petInfo
    self.petData = petInfo.petData
    self.PetName:SetText(self.petData.name)
    local showRename = BattleUtils.GetBit(self.petData.pet_status_flags, 4)
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    local isShowFriend = false
    if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      showRename = false
      isShowFriend = true
    end
    local Pos = self.VerticalBox_111.Slot:GetPosition()
    if not showRename then
      Pos.X = -151.5
    else
      Pos.X = -202.0
    end
    self.VerticalBox_111.Slot:SetPosition(Pos)
    self.Btn_Rename.RedDot:SetupKey(136, {
      self.petData.gid
    })
    self.Btn_Rename:SetVisibility(showRename and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    local PetStarsList = false == isShowFriend and PetUtils.GetPetStarsListByPetGID(self.petData.gid) or PetUtils.GetPetStarsListByPetGID(nil, friendInfo.petData)
    self.CatchHardLv:InitGridView(PetStarsList)
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
    self:UpdatePetMutationIcon()
    local unit_type = PetBaseConf.unit_type
    self:updatePetTypeIcon(unit_type)
  end
end

function UMG_Pet_Attribute_C:SetPetBriefInfoVisibility(bVisible)
  self.VerticalBox_111:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.HorizontalBox_42:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Switcher_77:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Btn_Rename:SetVisibility(bVisible and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Pet_Attribute_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  local BloodTypeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  self.Attr1:InitGridView(typeList)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  if PetBloodConf then
    table.insert(BloodTypeList, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.Attr:InitGridView(BloodTypeList)
end

function UMG_Pet_Attribute_C:RefreshPetName(_PetData)
  self.petData = _PetData
  self.PetName:SetText(self.petData.name)
end

function UMG_Pet_Attribute_C:UpdatePetMutationIcon()
  local petData = self.petData
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
  else
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_Attribute_C:OnAnimationFinished(Animation)
  if Animation == self.OpenXqAniA then
  elseif Animation == self.OpenXqAnB then
    self:PlayAnimation(self.RightIConbreathe, 0, 9999)
    self.lockAll = false
  elseif Animation == self.OpenXqAniB_Back then
  elseif Animation == self.OpenXqAniA_Back then
    self:PlayAnimation(self.RightIConbreathe, 0, 9999)
    self.lockAll = false
  end
end

function UMG_Pet_Attribute_C:OnDepartBtnPressed()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Press_1)
end

function UMG_Pet_Attribute_C:OnDepartBtnReleased()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Up_1)
end

function UMG_Pet_Attribute_C:OnBloodPulsePressed()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Press_2)
end

function UMG_Pet_Attribute_C:OnBloodPulseReleased()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Up_2)
end

function UMG_Pet_Attribute_C:PlayOpenXqAnB()
  self:PlayAnimation(self.OpenXqAnB, 0, 1, UE4.EUMGSequencePlayMode.Forward, 0.5)
end

return UMG_Pet_Attribute_C
