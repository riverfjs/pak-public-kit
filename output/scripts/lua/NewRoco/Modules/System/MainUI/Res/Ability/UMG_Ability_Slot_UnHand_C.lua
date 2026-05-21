require("UnLuaEx")
local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local UMG_Ability_Slot_UnHand_C = Base:Extend("UMG_Ability_Slot_UnHand_C")

function UMG_Ability_Slot_UnHand_C:OnConstruct()
  Base.OnConstruct(self)
  self._isVisible = false
  self.inDoubleRide = false
  self.is1p = false
  self.is2p = false
end

function UMG_Ability_Slot_UnHand_C:OnDestruct()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, self.OnDoubleRideSucceed)
  end
  Base.OnDestruct(self)
end

function UMG_Ability_Slot_UnHand_C:OnActive()
  if self.localPlayer then
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, self.OnDoubleRideSucceed)
  end
  self:RefreshView()
end

function UMG_Ability_Slot_UnHand_C:OnDeactive()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, self.OnDoubleRideSucceed)
  end
end

function UMG_Ability_Slot_UnHand_C:OnCast(isPress)
  if not isPress then
    return
  end
  local player = self.localPlayer
  if not player then
    return
  end
  local inviteComp = player.InviteComponent
  if not inviteComp then
    return
  end
  if self.inDoubleRide and self.is1p then
    local rideComp = player.viewObj.BP_RideComponent
    if rideComp and UE.UObject.IsValid(rideComp.RideMoveComp) then
      if rideComp.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Walking or rideComp.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Custom and (rideComp.RideMoveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Gliding or rideComp.RideMoveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_ClimbWater) then
        rideComp:TryChangeToLink()
      else
        rideComp:OnRideFailed()
        rideComp:StopRide()
      end
    end
  else
    inviteComp:InteractCancel()
  end
end

function UMG_Ability_Slot_UnHand_C:OnPCKey()
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  self:OnSlotPressed()
end

function UMG_Ability_Slot_UnHand_C:RefreshView()
  if self.OnRefreshHandle then
    DelayManager:CancelDelayById(self.OnRefreshHandle)
    self.OnRefreshHandle = nil
  end
  self.OnRefreshHandle = DelayManager:DelayFrames(1, function()
    self.OnRefreshHandle = nil
    if not UE.UObject.IsValid(self) then
      return
    end
    self:InternalRefreshView()
  end)
end

function UMG_Ability_Slot_UnHand_C:InternalRefreshView()
  local player = self.localPlayer
  if not player or not UE.UObject.IsValid(player.viewObj) then
    Log.Error("UMG_Ability_Slot_UnHand_C:InternalRefreshView local player is nil")
    return
  end
  local rideComp = player.viewObj.BP_RideComponent
  if not rideComp then
    Log.Error("UMG_Ability_Slot_UnHand_C:InternalRefreshView ride component is nil")
    return
  end
  local statusComp = player.statusComponent
  if not statusComp then
    Log.Error("UMG_Ability_Slot_UnHand_C:InternalRefreshView status component is nil")
    return
  end
  self.inDoubleRide = rideComp:IsInDoubleRide()
  if self.inDoubleRide then
    local customParams = player.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if customParams and customParams.ride_param then
      local actor_id = player.serverData and player.serverData.base and player.serverData.base.actor_id
      self.is1p = actor_id == customParams.ride_param.double_ride_1p_id
      self.is2p = actor_id == customParams.ride_param.double_ride_2p_id
    end
  else
    self.is1p = player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND)
    self.is2p = player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
  end
  local UIFunctionHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_UNHAND)
  self._isVisible = (self.is1p or self.is2p) and not UIFunctionHide
  Log.Debug("UMG_Ability_Slot_UnHand_C:InternalRefreshView", self._isVisible, self.is1p, self.is2p, UIFunctionHide)
  if self._isVisible then
    self:SetHandInHandRole(self.is2p)
  end
  self.Switcher:SetActiveWidgetIndex(self.inDoubleRide and 1 or 0)
  self:SetVisible(self._isVisible)
  if self._isVisible then
    self.BP_UIIcon:SetPath(self.inDoubleRide and "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_TerminatedCycling_png.img_TerminatedCycling_png'" or "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_BreakHand_png.img_BreakHand_png")
  end
  local ia = "IA_AbilitySlotUnHand"
  local pcKey = self.Text_PCKey
  if not _G.UE4Helper.IsPCMode() then
    pcKey = self.Text_PCKey
  elseif self.FoundationPCKey then
    pcKey = self.FoundationPCKey
  end
  if SystemSettingModuleCmd then
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, ia)
    if "" ~= image then
      pcKey:SetImageMode(image)
    else
      pcKey:SetText(text)
    end
  end
end

function UMG_Ability_Slot_UnHand_C:OnPlayerStatusChanged(status, value, opCode)
  if status ~= Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND and status ~= Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P and status ~= Enum.WorldPlayerStatusType.WPST_RIDEALL then
    return
  end
  Log.Debug("UMG_Ability_Slot_UnHand_C:OnPlayerStatusChanged", status, value, opCode)
  self:RefreshView()
  Base.OnPlayerStatusChanged(self, status, value, opCode)
end

function UMG_Ability_Slot_UnHand_C:OnDoubleRideSucceed()
  Log.Debug("UMG_Ability_Slot_UnHand_C:OnDoubleRideSucceed")
  self:RefreshView()
end

function UMG_Ability_Slot_UnHand_C:OnFunctionBan()
  Log.Debug("UMG_Ability_Slot_UnHand_C:OnFunctionBan")
  self:RefreshView()
end

function UMG_Ability_Slot_UnHand_C:SetParent(umg_player_abilities)
  self.umg_player_abilities = umg_player_abilities
  self:RefreshView()
end

function UMG_Ability_Slot_UnHand_C:SetHandInHandRole(isGuest)
  if not self.umg_player_abilities then
    return
  end
  local Slot = self.umg_player_abilities.AbilitySlot_UnHand.Slot
  if Slot then
    Slot:SetPosition(isGuest and UE.FVector2D(-246, Slot:GetPosition().Y) or UE.FVector2D(-907, Slot:GetPosition().Y))
  end
end

return UMG_Ability_Slot_UnHand_C
