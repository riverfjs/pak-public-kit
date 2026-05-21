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
local UMG_Ability_Slot_OnPet_C = Base:Extend("UMG_Ability_Slot_OnPet_C")

function UMG_Ability_Slot_OnPet_C:OnInit(isShortCut)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.localPlayer = localPlayer
  self.GlobalBlockFlag = 0
  self.BlockGIDs = {}
  self.isShortCut = isShortCut or false
  if self.isShortCut then
    self.slotIndex = 2
    self.slotSubIndex = 3
  else
    self.slotIndex = 4
    self.slotSubIndex = 1
  end
  _G.UpdateManager:Register(self)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_OnPet_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_OffPet_C", self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.RefreshUI)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_WATER_STATUS_CHANGE, self.OnWaterStatusChange)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
  if not self.isShortCut then
    if self:IsPCMode() then
      self:RegisterEvent(self, MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, self.RideSkillAim)
    else
      self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.RideSkillAim)
    end
  end
  self.rideSkillAim = false
end

function UMG_Ability_Slot_OnPet_C:OnUnInit()
  if self._abilityHelper then
    self._abilityHelper = nil
    self._focusPet = {}
  end
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_WATER_STATUS_CHANGE, self.OnWaterStatusChange)
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
    self.localPlayer = nil
  end
  if not self.isShortCut then
    if self:IsPCMode() then
      self:UnRegisterEvent(self, MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, self.RideSkillAim)
    else
      self:UnRegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.RideSkillAim)
    end
  end
  self._isAbilityBlock = false
  self._isBlock = false
  _G.UpdateManager:UnRegister(self)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.RefreshUI)
end

function UMG_Ability_Slot_OnPet_C:OnDestruct()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
    self.delayID = nil
  end
  Base.OnDestruct(self)
end

function UMG_Ability_Slot_OnPet_C:RideSkillAim(inAim)
  self.rideSkillAim = inAim
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:BindAbility(abilityID, pet)
  if abilityID then
    self._focusTempPet = nil
    if self._abilityHelper then
      if self._abilityHelper.config.id == abilityID and (nil == pet or self._focusPet == pet) then
        return
      end
      self:UnBindAbility()
    end
    local helper = AbilityHelperManager.GetHelper(abilityID)
    if helper then
      self._abilityHelper = helper
      self._focusPet = pet
    end
    self._isVisible = true
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_OnPet_C:UnBindAbility()
  self._focusTempPet = nil
  if self._abilityHelper then
    self._abilityHelper = nil
    self._focusPet = nil
  end
  self._isVisible = false
  self._shortChange = false
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:BindCurrentRide()
  if self.localPlayer and self.localPlayer.viewObj and self.localPlayer.viewObj.BP_RideComponent then
    local pet = self.localPlayer.viewObj.BP_RideComponent.ScenePet
    if pet and pet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
      self:BindAbility(AbilityID.RIDE_ALL, pet)
      self._focusTempPet = pet
      self._isBlock = true
    end
  end
end

function UMG_Ability_Slot_OnPet_C:GetFocusPet()
  return self._focusPet
end

function UMG_Ability_Slot_OnPet_C:OnSlotReleased(bind)
  if self._focusPet and _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") then
    local bInTaskFollow, Message = _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, self._focusPet.gid, 2)
    if bInTaskFollow then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Message)
    end
  end
  Base.OnSlotReleased(self, bind)
end

function UMG_Ability_Slot_OnPet_C:OnPlayerStatusChanged(status, value, opCode)
  if not self.isShortCut and status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    if self._focusPet == nil and not self._abilityHelper and not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
      local selectedGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
      if selectedGid <= 0 then
        self:BindCurrentRide()
      end
    end
    if self._focusPet then
      local selectedGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
      if selectedGid <= 0 and not self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
        self:UnbindAbility()
      end
    end
  end
  if not self._abilityHelper then
    self:RefreshUI()
    return
  end
  local isNowBlocked = self._abilityHelper:IsBlock(self.localPlayer, self._focusPet)
  if isNowBlocked ~= self.isBlock then
    self.isBlock = isNowBlocked
  end
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:NotifyPetStatus(pet, petStatus)
  if self._focusPet == pet then
    local isPetInteracting = petStatus == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_INTERACT
    local isRiding = petStatus == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE
    local isBlock = isPetInteracting or isRiding
    if self._isBlock ~= isBlock then
      self._isBlock = isBlock
    end
    if not isRiding and self._focusTempPet then
      self:UnBindAbility()
    end
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_OnPet_C:OnCast(isPress)
  if not self._abilityHelper then
    return
  end
  local isBlock, togetherBlock = self:IsBlock()
  if self._uiBlock then
    if self.isShortCut and togetherBlock and isPress then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.travel_together_full)
    end
    if self._focusPet and self._focusPet.config and isPress then
      local petID = self._focusPet.config.id
      local pet_socket_mask = DataConfigManager:GetRideSocketExport(petID)
      if not (pet_socket_mask and pet_socket_mask.socket_mask) or 0 ~= DataModelMgr.PlayerDataModel.ban_ride_sockets_mask & pet_socket_mask.socket_mask then
        NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_ability_slot_onpet_1)
      end
    end
    if self.localPlayer and self.localPlayer.ShowTaskAreaRideAllBanTips and isPress then
      self.localPlayer:ShowTaskAreaRideAllBanTips()
    end
    return
  end
  if isBlock then
    if self._abilityHelper:IsEnvBlock() then
      NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_ability_slot_onpet_1)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1009, "UMG_Ability_Slot_C:OnSlotPressed")
    end
    if self.isShortCut and togetherBlock then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.travel_together_full)
    end
    return
  end
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
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
  local errorCode = self._abilityHelper:CanCastAbility(self.localPlayer, self._focusPet)
  if errorCode == AbilityErrorCode.NO_ERROR then
    errorCode = abilityComponent:CanCastAbility(self._abilityHelper)
    if errorCode == AbilityErrorCode.NO_ERROR and self.localPlayer.inputComponent:GetInputEnable() then
      local gid = self._focusPet.gid
      self._abilityHelper:HandleStatus(self.localPlayer, self._focusPet)
    end
  elseif errorCode == AbilityErrorCode.TASK_AREA_BAN and self.localPlayer and self.localPlayer.ShowTaskAreaRideAllBanTips and isPress then
    self.localPlayer:ShowTaskAreaRideAllBanTips()
  end
  return errorCode
end

function UMG_Ability_Slot_OnPet_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Ability_Slot_OnPet_C:RefreshUI()
  if self.delayID then
    _G.DelayManager:CancelDelayById(self.delayID)
  end
  self.delayID = _G.DelayManager:DelayFrames(1, function()
    if not UE.UObject.IsValid(self) then
      return
    end
    if not (self._abilityHelper and self._focusPet) or not self._focusPet.config then
      self:SetVisible(false)
      return
    end
    local isInTransform = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
    local isRide = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    local isInAim = self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
    local Visible = self:GetVisible()
    if Visible then
      local isBlock = self:IsBlock()
      if self._abilityHelper.Islocked and self._abilityHelper:Islocked(self.localPlayer, self._focusPet.config.id) then
        self:SetVisible(false)
        return
      end
      self._uiBlock = isBlock
      local IconPath = self._abilityHelper:GetIcon(self.localPlayer, isBlock)
      if nil ~= IconPath and "" ~= IconPath then
        self.BP_UIIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if IconPath ~= self.oldIconPath then
          self.oldIconPath = IconPath
          local pressIcon = self._abilityHelper:GetPressIcon(self.localPlayer)
          if nil ~= pressIcon and "" ~= pressIcon then
            self.Image_Bg:SetPath(pressIcon)
          end
          if self.Visibility == UE4.ESlateVisibility.Visible then
            self.BP_UIIcon:SetPath(IconPath)
          else
            self.BP_UIIcon:SetPath(IconPath)
          end
        end
      else
        self:SetVisible(false, true)
        return
      end
      if self.isShortCut then
        self.Image_Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/btn_feixingshiheng_xuanzhong_png.btn_feixingshiheng_xuanzhong_png'")
        if self._uiBlock then
          self.BP_UIIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/btn_feixingshiheng_zhihui_png.btn_feixingshiheng_zhihui_png'")
        else
          self.BP_UIIcon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/btn_feixingshiheng_png.btn_feixingshiheng_png'")
        end
      end
    end
    local newVisible = Visible and not isInTransform and not isInAim
    self:SetVisible(newVisible)
    if self.isShortCut and newVisible ~= self._shortChange then
      self._shortChange = newVisible
      if newVisible then
        self:PlayAnimation(self.Show_change)
      end
    end
  end)
end

function UMG_Ability_Slot_OnPet_C:GetRelationTreePanelShow()
  if _G.RelationTreeCmd then
    return _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpeningRelationPanel)
  end
  return nil
end

function UMG_Ability_Slot_OnPet_C:UIBan(FuncId)
  if FuncId == Enum.FunctionEntrance.FE_RIDE then
    self.bInBanCondition = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow()
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_OnPet_C:OnTick(InDeltaTime)
  local UpdateTime = 0.5
  if self.isShortCut then
    if self._isVisible and (self._isAbilityBlock or self._uiBlock or 0 ~= self._tickTime) then
      UpdateTime = 0.2
    else
      return
    end
  end
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if self._tickTime == nil then
    self._tickTime = 0
  end
  self._tickTime = self._tickTime + InDeltaTime
  if UpdateTime < self._tickTime then
    self._tickTime = 0
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_OnPet_C:OnWaterStatusChange(newStatus, oldStatus)
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:OnRideMoveTypeChange()
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:IsBlock()
  if self._abilityHelper then
    local abilityIsBlock = self._abilityHelper:IsBlock(self.localPlayer, self._focusPet)
    if self._isAbilityBlock ~= abilityIsBlock then
      self._isAbilityBlock = abilityIsBlock
    end
  end
  local BlockFlag = 0 ~= self.GlobalBlockFlag or table.containsKey(self.BlockGIDs, self._focusPet.gid)
  local togetherBlock = false
  if self.localPlayer:IsInTogetherMove() then
    togetherBlock = true
    if self:CanDoubleRide() then
      togetherBlock = false
    end
  end
  return self._isBlock or self._isAbilityBlock or BlockFlag or self.rideSkillAim or togetherBlock, togetherBlock
end

function UMG_Ability_Slot_OnPet_C:CanDoubleRide()
  if self._focusPet and self._focusPet.config then
    local rideComponent = self.localPlayer.viewObj.BP_RideComponent
    if rideComponent and not rideComponent.bIsDoubleRide2p and rideComponent:IsDoubleRidePet(self._focusPet, false) then
      return true
    end
  end
  return false
end

function UMG_Ability_Slot_OnPet_C:GetVisible()
  if self.isShortCut and self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
    self._isVisible = false
    return self._isVisible
  end
  local ban = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_RIDE) or self:GetRelationTreePanelShow()
  return self._isVisible and not ban
end

function UMG_Ability_Slot_OnPet_C:OnPCKey(isPress)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if isPress then
    self:OnSlotPressed()
  else
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    self:OnSlotClicked()
  end
end

function UMG_Ability_Slot_OnPet_C:OnAnimationFinished(anim)
  if self.out and anim == self.out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Ability_Slot_OnPet_C:SetBlockForReason(bBlock, Reason)
  Reason = Reason or _G.MainUIModuleEnum.AbilityBtnBlockReason.Any
  if bBlock then
    self.GlobalBlockFlag = self.GlobalBlockFlag | 1 << Reason
  else
    self.GlobalBlockFlag = self.GlobalBlockFlag & ~(1 << Reason)
  end
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:SetPetRideBlockForReason(bBlock, Gid, Reason)
  Reason = Reason or _G.MainUIModuleEnum.AbilityBtnBlockReason.Any
  if not self.BlockGIDs then
    self.BlockGIDs = {}
  end
  if bBlock then
    self.BlockGIDs[Gid] = (self.BlockGIDs[Gid] or 0) | 1 << Reason
  else
    if not self.BlockGIDs[Gid] then
      return
    end
    self.BlockGIDs[Gid] = self.BlockGIDs[Gid] & ~(1 << Reason)
    if 0 == self.BlockGIDs[Gid] then
      self.BlockGIDs[Gid] = nil
    end
  end
  self:RefreshUI()
end

function UMG_Ability_Slot_OnPet_C:GetBtnBlock(pet)
  local BlockFlag = 0 ~= self.GlobalBlockFlag or pet and table.containsKey(self.BlockGIDs, pet.gid)
  return BlockFlag
end

return UMG_Ability_Slot_OnPet_C
