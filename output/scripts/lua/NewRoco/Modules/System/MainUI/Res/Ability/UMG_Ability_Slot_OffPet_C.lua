require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityErrorCode = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityErrorCode")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local UMG_Ability_Slot_OffPet_C = Base:Extend("UMG_Ability_Slot_OffPet_C")

function UMG_Ability_Slot_OffPet_C:OnInit(isNormalRide)
  self.Btn_Slot.OnPressed:Add(self, self.OnSlotPressed)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.localPlayer = localPlayer
  self.playShowOrHide = false
  self.isNormalRide = isNormalRide
  if self.isNormalRide then
    self.slotIndex = 4
    self.slotSubIndex = 2
  else
    self.slotIndex = 5
    self.slotSubIndex = 2
  end
  self:SetPcText()
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_OffPet_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_RIDE_OFF, self, self.RefreshView)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_OffPet_C", self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.RefreshView)
  if self:IsPCMode() then
    self:RegisterEvent(self, MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, self.RideSkillAim)
  else
    self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.RideSkillAim)
  end
end

function UMG_Ability_Slot_OffPet_C:OnUnInit()
  if self._abilityHelper then
    self._abilityHelper = nil
  end
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
    self.localPlayer = nil
  end
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_RIDE_OFF, self, self.RefreshView)
  if self:IsPCMode() then
    self:UnRegisterEvent(self, MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, self.RideSkillAim)
  else
    self:UnRegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.RideSkillAim)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.RefreshView)
end

function UMG_Ability_Slot_OffPet_C:OnRideMoveTypeChange()
  self:RefreshView()
end

function UMG_Ability_Slot_OffPet_C:RideSkillAim(inAim)
  self.rideSkillAim = inAim
  self:RefreshView()
end

function UMG_Ability_Slot_OffPet_C:SetPcText()
  if SystemSettingModuleCmd and self.Text_PCKey then
    local pcKey = self.Text_PCKey
    if not _G.UE4Helper.IsPCMode() then
      pcKey = self.Text_PCKey
    elseif self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    local iaName = self.isNormalRide and "IA_AbilitySlotOffPet" or "IA_OffTempPet_OnPet"
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, iaName)
    if "" ~= image then
      pcKey:SetImageMode(image)
    else
      pcKey:SetText(text)
    end
  end
end

function UMG_Ability_Slot_OffPet_C:BindAbility(pet, status, subStatus)
  local abilityID = self.localPlayer.abilityComponent:GetAbilityIDByStatus(status, false, subStatus)
  if abilityID then
    if self._abilityHelper then
      if self._abilityHelper.config.id ~= abilityID then
        self:UnBindAbility()
      end
      return
    end
    self._abilityHelper = AbilityHelperManager.GetHelper(abilityID)
  end
  self._bindPet = pet
  self._isVisible = true
  self:RefreshView()
end

function UMG_Ability_Slot_OffPet_C:UnBindAbility()
  if self._abilityHelper then
    self._abilityHelper = nil
  end
  self._isVisible = false
  self._bindPet = nil
  self:RefreshView()
end

function UMG_Ability_Slot_OffPet_C:UIBan(FuncId)
  if FuncId == Enum.FunctionEntrance.FE_RIDE then
    self:RefreshView()
  end
end

function UMG_Ability_Slot_OffPet_C:SetVisible(visible, focusChanges)
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
  end
  if false == visible then
    Base.SetVisible(self, visible, focusChanges)
  else
    self.delayID = _G.DelayManager:DelayFrames(1, function()
      self.delayID = nil
      Base.SetVisible(self, visible, focusChanges)
    end)
  end
end

function UMG_Ability_Slot_OffPet_C:RefreshView()
  local overrideVisible = true
  if not self._abilityHelper then
    self:SetVisible(false)
    self._isVisible = false
    return
  end
  local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow() or _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_RIDE_OFF)
  local isInAim = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  local isDoubleRide = self.localPlayer.viewObj.BP_RideComponent and self.localPlayer.viewObj.BP_RideComponent:IsInDoubleRide() or false
  if bHide or isInAim or self.rideSkillAim or isDoubleRide then
    overrideVisible = false
  end
  if self._isVisible then
    if not self.isNormalRide then
    end
    local IconPath = self:GetIcon()
    if nil ~= IconPath and "" ~= IconPath then
      self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if IconPath ~= self.oldIconPath or self.overrideStatus then
        local pressIcon = self:GetPressIcon()
        if not overrideVisible then
          self.overrideStatus = true
        else
          self.overrideStatus = nil
        end
        if not self.overrideStatus and nil ~= pressIcon and "" ~= pressIcon then
          self.Image_Bg:SetPath(pressIcon)
        end
        self.oldPressIconPath = pressIcon
        self.oldIconPath = IconPath
        if not self.overrideStatus then
          if self.Visibility == UE4.ESlateVisibility.Visible then
            self.BP_UIIcon:SetPath(IconPath)
          else
            self.BP_UIIcon:SetPath(IconPath)
          end
        end
      end
    else
      self._isVisible = false
      self:SetVisible(self._isVisible, true)
    end
  end
  self:SetVisible(overrideVisible and self._isVisible)
end

function UMG_Ability_Slot_OffPet_C:OnPlayerStatusChanged(status, value, opCode)
  if self._bindPet then
    self:RefreshView()
  end
  Base.OnPlayerStatusChanged(self, status, value, opCode)
end

function UMG_Ability_Slot_OffPet_C:GetRelationTreePanelShow()
  if _G.RelationTreeCmd then
    return _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpeningRelationPanel)
  end
  return nil
end

function UMG_Ability_Slot_OffPet_C:GetUiData()
  local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow()
  return {
    visible = self._isVisible and not bHide,
    iconPath = self.oldIconPath,
    oldPressIconPath = self.oldPressIconPath
  }
end

function UMG_Ability_Slot_OffPet_C:GetIcon()
  return self._abilityHelper:GetIcon(self.localPlayer)
end

function UMG_Ability_Slot_OffPet_C:GetPressIcon()
  return self._abilityHelper:GetPressIcon(self.localPlayer)
end

function UMG_Ability_Slot_OffPet_C:OnCast(isPress)
  if not self.localPlayer then
    return
  end
  if not self._abilityHelper then
    return
  end
  local castType = isPress and Enum.SceneAbilitySlotCastType.SASCT_PRESS or Enum.SceneAbilitySlotCastType.SASCT_CLICK
  if self._abilityHelper.config.scene_ability_slot_cast_type ~= castType then
    return AbilityErrorCode.NOT_CASTTYPE
  end
  local abilityComponent = self.localPlayer.abilityComponent
  if abilityComponent._currentAbility and abilityComponent._currentAbility:IsCasting() and abilityComponent._currentAbility.helper.config.id == AbilityID.RIDE_ALL then
    Log.Error("\230\156\172\229\156\176\231\142\169\229\174\182\228\184\141\229\186\148\232\175\165\229\173\152\229\156\168\230\140\129\231\187\173\231\154\132\233\170\145\228\185\152\230\138\128\232\131\189\239\188\140\232\191\155\232\161\140\228\184\173\230\150\173")
    abilityComponent._currentAbility:Finish(true)
  end
  local errorCode = AbilityErrorCode.NO_ERROR
  if not self.doubleRide then
    errorCode = self._abilityHelper:CanCastAbility(self.localPlayer)
  end
  if errorCode == AbilityErrorCode.NO_ERROR then
    local abilityComponent = self.localPlayer.abilityComponent
    errorCode = abilityComponent:CanCastAbility(self._abilityHelper)
    if errorCode == AbilityErrorCode.NO_ERROR and self.localPlayer.inputComponent and self.localPlayer.inputComponent:GetInputEnable() then
      self._abilityHelper:HandleStatus(self.localPlayer, false, true)
      self._isVisible = false
      self:RefreshView()
    end
  end
  Log.DebugFormat("OffPet error %d", errorCode)
end

function UMG_Ability_Slot_OffPet_C:ShowDoubleRideUI(isOnPet, PetID, isPlayer1P)
  if isPlayer1P then
    return
  end
  if isOnPet then
    local abilityID = self.localPlayer.abilityComponent:GetAbilityIDByStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, false)
    if abilityID then
      if self._abilityHelper and self._abilityHelper.config.id ~= abilityID then
        self:UnBindAbility()
      end
      self._abilityHelper = AbilityHelperManager.GetHelper(abilityID)
    end
    self.doubleRide = true
    self._isVisible = true
    self.doubleRidePetID = PetID
    self:RefreshView()
  else
    self.doubleRide = nil
    self._isVisible = false
    self.doubleRidePetID = nil
    self:UnBindAbility()
  end
end

function UMG_Ability_Slot_OffPet_C:NotifyPetStatus(pet, petStatus)
  if petStatus == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
    if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
      self:UnBindAbility()
      return
    end
    self:BindAbility(pet, ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    self:RefreshView()
  else
    if self._bindPet and self._bindPet ~= pet then
      return
    end
    self:UnBindAbility()
  end
end

function UMG_Ability_Slot_OffPet_C:OnPCKey(isPress)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if isPress then
    self:OnSlotPressed()
  else
    if _G.FriendModuleCmd then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    end
    self:OnSlotClicked()
  end
end

function UMG_Ability_Slot_OffPet_C:OnAnimationFinished(anim)
  if self.out and anim == self.out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Ability_Slot_OffPet_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

return UMG_Ability_Slot_OffPet_C
