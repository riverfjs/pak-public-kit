require("UnLuaEx")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PetAbilitySlotManager = require("NewRoco.Modules.System.MainUI.Res.Ability.Pet_Ability_Slot_Manager")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local UMG_PlayerAbilities_C = _G.NRCViewBase:Extend("UMG_PlayerAbilities_C")

function UMG_PlayerAbilities_C:OnConstruct()
  if self:IsPCMode() then
    return
  end
  self:Log("UMG_PlayerAbilities_C:OnConstruct")
  self:SetChildViews(self.AbilitySlot_Throw, self.AbilitySlot_Main, self.AbilitySlot_RideAbility)
  self:AddChildView(self.AbilitySlot_ClimbDown)
  self:AddChildView(self.AbilitySlot_ClimbUp)
  self:AddChildView(self.AbilitySlot_OnPet)
  self:AddChildView(self.AbilitySlot_OffPet)
  self:AddChildView(self.AbilitySlot_OffTempPet)
  self:AddChildView(self.AbilitySlot_ShortCut)
  self:AddChildView(self.AbilitySlot_Perception)
  self:AddChildView(self.AbilitySlot_Crouch)
  self:AddChildView(self.AbilitySlot_Jump)
  self:AddChildView(self.AbilitySlot_Emote)
  self:AddChildView(self.AbilitySlot_Untransform)
  self:AddChildView(self.AbilitySlot_Eradicate)
  self:AddChildView(self.AbilitySlot_PetCare)
  self:AddChildView(self.AbilitySlot_UnHand)
  self:AddChildView(self.AbilitySlot_RideJump)
  self.petAbilitySlotManager = PetAbilitySlotManager()
  self:PCSet()
  self:InitInfo()
  self.playerAbilityImcName = "IMC_PlayerAbilityNormal"
  self:AddAllIMC()
  self:UiAddInputMappingContext()
  _G.UpdateManager:UnRegister(self)
end

function UMG_PlayerAbilities_C:OnDestruct()
  self:RemoveEventListener()
end

function UMG_PlayerAbilities_C:AddInputBlock()
  self.isPcBlock = true
  self:UiRemoveInputMappingContext()
end

function UMG_PlayerAbilities_C:AddAllIMC()
  local mappingContext1 = self:AddInputMappingContext("IMC_PlayerAbilityClimb")
  if mappingContext1 then
    mappingContext1:BindAction("IA_AbilitySlotOnPet", self, "OnPcAbilitySlotOnPet", UE.ETriggerEvent.Triggered)
    mappingContext1:BindAction("IA_PlayerClimbJumpStart_Climb", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
    mappingContext1:BindAction("IA_PlayerClimbJumpEnd_Climb", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
    mappingContext1:BindAction("IA_ExitClimbing_Climb", self, "OnPcAbilitySlotOffPet", UE.ETriggerEvent.Triggered)
    mappingContext1:BindAction("IA_AbilitySlotOnPetStart")
    mappingContext1:DisableInputMappingContext()
  end
  local mappingContext2 = self:AddInputMappingContext("IMC_PlayerAbilityTransform")
  if mappingContext2 then
    mappingContext2:BindAction("IA_AbilitySlotEmote", self, "OnPcAbilitySlotEmote", UE.ETriggerEvent.Triggered)
    mappingContext2:BindAction("IA_AbilitySlotUntransform", self, "OnPcAbilitySlotUntransform", UE.ETriggerEvent.Triggered)
    mappingContext2:BindAction("IA_TransformSkillStart_Transform", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
    mappingContext2:BindAction("IA_TransformSkillEnd_Transform", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
    mappingContext2:BindAction("IA_AbilitySlot_SecondMainStart", self, "OnPcAbilitySlotSecondMainStart", UE.ETriggerEvent.Triggered)
    mappingContext2:DisableInputMappingContext()
  end
  local mappingContext3 = self:AddInputMappingContext("IMC_PlayerAbilityOnPet")
  if mappingContext3 then
    mappingContext3:BindAction("IA_AbilitySlotPerceptionStart", self, "OnPcAbilitySlotPerceptionStart", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotPerceptionEnd", self, "OnPcAbilitySlotPerceptionEnd", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_CanelRideAbility", self, "OnPcAbilityCancel", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_PetRiddingSkillStart_OnPet", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_PetRiddingSkillEnd_OnPet", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_OffTempPet_OnPet", self, "OnPcAbilitySlotOffTempPet", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotOnPet")
    mappingContext3:BindAction("IA_AbilitySlotShortCut", self, "OnPcAbilitySlotShortCut", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotOffPet", self, "OnPcAbilitySlotOffPet", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotOnPetStart", self, "OnPcAbilitySlotOnPetStart", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotOffPetStart", self, "OnPcAbilitySlotOffPetStart", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlotUnHand", self, "OnPcAbilitySlotUnHand", UE.ETriggerEvent.Triggered)
    mappingContext3:BindAction("IA_AbilitySlot_SecondMainStart", self, "OnPcAbilitySlotSecondMainStart", UE.ETriggerEvent.Triggered)
    mappingContext3:DisableInputMappingContext()
  end
  local mappingContext4 = self:AddInputMappingContext("IMC_PlayerAbilityWater")
  if mappingContext4 then
    mappingContext4:BindAction("IA_AbilitySlotOnPet")
    mappingContext4:BindAction("IA_AbilitySlotPerceptionEnd")
    mappingContext4:BindAction("IA_AbilitySlotPerceptionStart")
    mappingContext4:BindAction("IA_PlayerSwimDashEnd_Water", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
    mappingContext4:BindAction("IA_PlayerSwimDashStart_Water", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
    mappingContext4:BindAction("IA_AbilitySlotOnPetStart")
    mappingContext4:DisableInputMappingContext()
  end
  local mappingContext5 = self:AddInputMappingContext("IMC_PlayerAbilityAir")
  if mappingContext5 then
    mappingContext5:DisableInputMappingContext()
    mappingContext5:BindAction("IA_AbilitySlotJump", self, "OnPcAbilitySlotJump", UE.ETriggerEvent.Triggered)
    mappingContext5:BindAction("IA_AbilitySlotOnPet")
    mappingContext5:BindAction("IA_AbilitySlotShortCut")
    mappingContext5:BindAction("IA_AbilitySlotOnPetStart")
    mappingContext5:DisableInputMappingContext()
  end
  local mappingContext6 = self:AddInputMappingContext("IMC_PlayerAbilityNormal")
  if mappingContext6 then
    mappingContext6:BindAction("IA_AbilitySlotJump", self, "OnPcAbilitySlotJump", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_ChangeWalkRun", self, "OnPcChangeWalkRun", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_AbilitySlotOnPet")
    mappingContext6:BindAction("IA_AbilitySlotPerceptionStart")
    mappingContext6:BindAction("IA_AbilitySlotPerceptionEnd")
    mappingContext6:BindAction("IA_AbilitySlotCrouch", self, "OnPcAbilitySlotCrouch", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_PlayerDashEnd_Normal", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_PlayerDashStart_Normal", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_AbilitySlotOnPetStart")
    mappingContext6:BindAction("IA_AbilitySlotSeedStart", self, "OnPcAbilitySlotSeedStart", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_AbilitySlotSeedEnd", self, "OnPcAbilitySlotSeedEnd", UE.ETriggerEvent.Triggered)
    mappingContext6:BindAction("IA_AbilitySlotUnHand", self, "OnPcAbilitySlotUnHand", UE.ETriggerEvent.Triggered)
    mappingContext6:DisableInputMappingContext()
  end
  local inputAction6 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_Shovel_MainUIDefault")
  UE.UNRCEnhancedInputHelper.BindAction(inputAction6, UE.ETriggerEvent.Triggered, self, "OnPcRemovePlant")
end

function UMG_PlayerAbilities_C:RemoveInputBlock()
  self.isPcBlock = nil
  self:UiAddInputMappingContext(self.playerAbilityImcName)
end

function UMG_PlayerAbilities_C:UiAddInputMappingContext()
  if self.isPcBlock then
    return
  end
  local mappingContext = self:GetInputMappingContext(self.playerAbilityImcName)
  if mappingContext then
    mappingContext:EnableInputMappingContext()
  end
end

function UMG_PlayerAbilities_C:UiRemoveInputMappingContext()
  if self.isPcBlock then
    return
  end
  local mappingContext = self:GetInputMappingContext(self.playerAbilityImcName)
  if mappingContext then
    mappingContext:DisableInputMappingContext()
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotCrouch()
  self.AbilitySlot_Crouch:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotJump()
  self.AbilitySlot_Jump:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotMainStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_RideAbility:OnPCKey(0)
  elseif self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    self.AbilitySlot_ClimbUp:OnPCKey(0)
  else
    self.AbilitySlot_Main:OnPCKey(0)
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotSecondMainStart()
  self.AbilitySlot_RideJump:OnPCKey(0)
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotPetCareCall()
  if self.AbilitySlot_PetCare.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_PetCare.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_PetCare.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  self.AbilitySlot_PetCare:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotSeedStart()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotSeedEnd()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotUnHand()
  self.AbilitySlot_UnHand:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotMainEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_RideAbility:OnPCKey(1)
  elseif self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    self.AbilitySlot_ClimbUp:OnPCKey(1)
  else
    self.AbilitySlot_Main:OnPCKey(1)
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotOffTempPet()
  self.AbilitySlot_OffTempPet:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotOffPetStart()
  if self.AbilitySlot_OffPet.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_OffPet.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_OffPet.Visibility == UE.ESlateVisibility.HitTestInvisible then
    self.OnPcAbilitySlotOffPetSucceed = false
  else
    self.OnPcAbilitySlotOffPetSucceed = true
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotOffPet()
  if self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    self.AbilitySlot_ClimbDown:OnPCKey(0)
  elseif self.OnPcAbilitySlotOffPetSucceed then
    self.AbilitySlot_OffPet:OnPCKey()
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotOnPetStart()
  if self.AbilitySlot_OnPet.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_OnPet.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_OnPet.Visibility == UE.ESlateVisibility.HitTestInvisible then
    self.OnPcAbilitySlotOnPetSucceed = false
  else
    self.OnPcAbilitySlotOnPetSucceed = true
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotOnPet()
  if self.OnPcAbilitySlotOnPetSucceed then
    self.AbilitySlot_OnPet:OnPCKey()
  end
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotPerceptionStart()
  self.AbilitySlot_Perception:OnPCKey(0)
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotPerceptionEnd()
  self.AbilitySlot_Perception:OnPCKey(1)
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotShortCut()
  self.AbilitySlot_ShortCut:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotUntransform()
  self.AbilitySlot_Untransform:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcAbilitySlotEmote()
  self.AbilitySlot_Emote:OnPCKey()
end

function UMG_PlayerAbilities_C:OnPcChangeWalkRun()
  if self.localPlayer then
    self.localPlayer.viewObj:OnCtrlKey(0)
  end
end

function UMG_PlayerAbilities_C:UpdateBindInputAction()
  self.AbilitySlot_Throw:BindInputAction()
  self:AddAllIMC()
  self:UiAddInputMappingContext()
end

function UMG_PlayerAbilities_C:OnPlayerStatusChanged(status, value, opCode)
  local caster = self.localPlayer
  local statusComponent = caster.statusComponent
  if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityTransform" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityTransform"
      self:UiAddInputMappingContext()
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityOnPet" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityOnPet"
      self:UiAddInputMappingContext()
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityClimb" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityClimb"
      self:UiAddInputMappingContext()
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityWater" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityWater"
      self:UiAddInputMappingContext()
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING) then
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityAir" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityAir"
      self:UiAddInputMappingContext()
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED) then
    if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      if self.playerAbilityImcName == "IMC_PlayerAbilityNormal" and not self.Throwing then
        self.Throwing = true
      end
      if self.playerAbilityImcName == "IMC_PlayerAbilityAir" then
        self:UiRemoveInputMappingContext()
        self.playerAbilityImcName = "IMC_PlayerAbilityNormal"
        self:UiAddInputMappingContext()
        self.Throwing = true
      end
    elseif self.playerAbilityImcName ~= "IMC_PlayerAbilityNormal" then
      self:UiRemoveInputMappingContext()
      self.playerAbilityImcName = "IMC_PlayerAbilityNormal"
      self:UiAddInputMappingContext()
    end
  end
  if self.Throwing and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    self.Throwing = nil
    if self.playerAbilityImcName == "IMC_PlayerAbilityNormal" then
    end
  end
end

function UMG_PlayerAbilities_C:AddChildView(childView)
  table.insert(self.viewChildViews, childView)
end

function UMG_PlayerAbilities_C:OnActive()
  self:Log("UMG_PlayerAbilities_C:OnActive")
  self:OnBeforeOpen()
  self:AddEventListener()
  _G.UpdateManager:Register(self)
end

function UMG_PlayerAbilities_C:OnDeactive()
  self:Log("UMG_PlayerAbilities_C:OnDeActive")
  self:OnBeforeClose()
  _G.UpdateManager:UnRegister(self)
end

function UMG_PlayerAbilities_C:OnTick(InDeltaTime)
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:Update(InDeltaTime)
  end
end

function UMG_PlayerAbilities_C:AddEventListener()
  if self.module then
    self.module:RegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem, self.UpdateThrowItem)
    self.module:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, self.ShowThrowSlot)
    self.module:RegisterEvent(self, MainUIModuleEvent.UI_SetThrowNull, self.SetThrowNull)
    self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    self.module:RegisterEvent(self, MainUIModuleEvent.ReqShowHideAbilitySlotByReason, self.OnReqShowHideAbilitySlotByReason)
  end
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnFlagUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_PlayerAbilities_C", self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:RegisterEvent("UMG_PlayerAbilities_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.OnUIFuncVisibilityChange)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.OnEnterHomeMap)
    homeModule:RegisterEvent(self, HomeModuleEvent.OnExitHomeMap, self.OnExitHomeMap)
  end
end

function UMG_PlayerAbilities_C:RemoveEventListener()
  if self.module then
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowNull)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.ReqShowHideAbilitySlotByReason)
  end
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  end
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnFlagUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.OnUIFuncVisibilityChange)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnExitHomeMap)
  end
end

function UMG_PlayerAbilities_C:OnReqShowHideAbilitySlotByReason(Type, Visible, Reason)
  self:Log("OnReqShowHideAbilitySlotByReason", Type, Visible, Reason)
  if "Jump" == Type then
    self.AbilitySlot_Jump:AddVisibilityByUser(Visible, Reason)
  elseif "Crouch" == Type then
    self.AbilitySlot_Crouch:AddVisibilityByUser(Visible, Reason)
  else
    if "Main" == Type then
      self.AbilitySlot_Main:AddVisibilityByUser(Visible, Reason)
    else
    end
  end
end

function UMG_PlayerAbilities_C:OnFlagUpdate(flagId, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flagId)
  if bIsHomeOwner == UseSelf then
    return
  end
  self:AutoSetThrowItemVisibility()
end

function UMG_PlayerAbilities_C:OnUIFuncVisibilityChange(uiFunctionId, bHide)
  if uiFunctionId == Enum.FunctionEntrance.FE_THROW and self.AbilitySlot_Throw and self.AbilitySlot_Throw.ThrowItemType ~= nil and self.AbilitySlot_Throw.ThrowItemType > 1 then
    Log.DebugFormat("UMG_PlayerAbilities_C:OnUIFuncVisibilityChange update AutoSetThrowItemVisibility, uiFunctionId=%s, bHide=%s, ThrowItemType=%s", tostring(uiFunctionId), tostring(bHide), tostring(self.AbilitySlot_Throw.ThrowItemType))
    self:AutoSetThrowItemVisibility()
  end
end

function UMG_PlayerAbilities_C:InitInfo()
  Log.Debug("UMG_PlayerAbilities_C:InitInfo")
  self.ThrowItemType = -1
  self.AbilitySlot_Throw.Btn_Slot.LongPressTriggerTime = 0.15
  self:AutoSetThrowItemVisibility()
end

function UMG_PlayerAbilities_C:OnBeforeOpen()
  Log.Debug("UMG_PlayerAbilities_C:OnBeforeOpen")
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.AbilitySlot_Throw:ReBindPlayer()
  self.AbilitySlot_Emote:ReBindPlayer()
  self.AbilitySlot_Untransform:ReBindPlayer()
  self.AbilitySlot_Crouch:ReBindPlayer()
  self.AbilitySlot_Main:ReBindPlayer()
  self.AbilitySlot_ClimbDown:ReBindPlayer()
  self.AbilitySlot_Jump:ReBindPlayer()
  self.AbilitySlot_ClimbUp:ReBindPlayer()
  self.AbilitySlot_Eradicate:ReBindPlayer()
  self.AbilitySlot_PetCare:ReBindPlayer()
  self.AbilitySlot_UnHand:ReBindPlayer()
  self.AbilitySlot_UnHand:SetParent(self)
  self.AbilitySlot_Main:OnActive()
  self.AbilitySlot_ClimbUp:OnActive()
  self.AbilitySlot_RideAbility:OnActive()
  self.AbilitySlot_RideJump:OnActive()
  self.AbilitySlot_ClimbDown:OnActive()
  self.AbilitySlot_UnHand:OnActive()
  local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
  self.AbilitySlot_Throw:BindAbility(throwHelper)
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:Init(self.AbilitySlot_OnPet, self.AbilitySlot_OffPet, self.AbilitySlot_ShortCut, self.AbilitySlot_Perception, self.AbilitySlot_RideAbility, self.AbilitySlot_OffTempPet, self.AbilitySlot_RideJump, self.module)
  end
  local isLocalMode = NRCEnv:IsLocalMode()
  self:Log("isLocalMode", isLocalMode)
  if not isLocalMode then
    local selectedGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
    local EquipItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
    local MagicItem = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
    if 0 == selectedGid then
      self:UpdateThrowItem(0, EquipItem)
    elseif -1 == selectedGid and MagicItem and MagicItem.id ~= nil then
      self:UpdateThrowItem(2, MagicItem)
    end
    if self.module then
      self.module:RefreshMainPetSelect()
    else
      Log.Error("Exception: UMG_PlayerAbilities_C:OnBeforeOpen module is nil")
    end
  end
end

function UMG_PlayerAbilities_C:OnBeforeClose()
  self.AbilitySlot_Main:OnDeactive()
  self.AbilitySlot_ClimbUp:OnDeactive()
  self.AbilitySlot_RideAbility:OnDeactive()
  self.AbilitySlot_RideJump:OnDeactive()
  self.AbilitySlot_ClimbDown:OnDeactive()
  self.AbilitySlot_UnHand:OnDeactive()
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:UnInit()
  end
end

function UMG_PlayerAbilities_C:SetThrowItem(itemType, itemId)
  self.AbilitySlot_Throw:SetPetSwitchShow(itemType, itemId)
end

function UMG_PlayerAbilities_C:UpdateThrowItem(itemType, itemId, recycleState, session)
  self.AbilitySlot_Throw.Btn_Slot:SetIsEnabled(true)
  self:SetThrowItemVisibility(itemType, itemId)
  local isBall = itemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM
  if table.isEmpty(itemId) and not isBall then
    return
  end
  self.AbilitySlot_Throw:SetPetSwitchShow(itemType, itemId, recycleState, session)
  if 0 == itemType then
    self:SetThrowOrRecycle(false, nil)
  else
    self:SetThrowOrRecycle(recycleState, session)
  end
end

function UMG_PlayerAbilities_C:SetThrowOrRecycle(recycleState, session)
  local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
  local recycleHelper = AbilityHelperManager.GetHelper(AbilityID.RECYCLE_THROW)
  if true == recycleState then
    self.AbilitySlot_Throw:BindAbility(recycleHelper)
  else
    self.AbilitySlot_Throw:BindAbility(throwHelper)
  end
  self.AbilitySlot_Throw:OnPetStatusChanged(nil, nil, self.AbilitySlot_Throw._pet)
end

function UMG_PlayerAbilities_C:ShowThrowSlot(showJoystic)
  Log.Debug("UMG_PlayerAbilities_C:ShowThrowSlot", showJoystic)
  if false == showJoystic then
    self:AutoSetThrowItemVisibility()
  else
    self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AbilitySlot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_PlayerAbilities_C:GetSkillPanelVisible()
  return self.SkillVisible
end

function UMG_PlayerAbilities_C:InitForLocalMode()
  Log.Debug("UMG_PlayerAbilities_C:InitForLocalMode")
  self:InitInfo()
  self:OnBeforeOpen()
end

function UMG_PlayerAbilities_C:OnSceneLoaded()
  Log.Debug("UMG_PlayerAbilities_C:OnSceneLoaded")
  self:InitInfo()
  if self.AbilitySlot_Main then
    self.AbilitySlot_Main._activated = false
  end
  if self.AbilitySlot_RideAbility then
    self.AbilitySlot_RideAbility._activated = false
  end
  self:OnBeforeOpen()
end

function UMG_PlayerAbilities_C:SetThrowItemVisibility(itemType, item)
  local isAiming = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
  if isAiming then
    self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 1 == itemType then
    if not PetUtils.IsHavePet() then
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    if item and item.num then
      if item.num > 0 then
        self.AbilitySlot_Throw:ChangeBallState(true, false)
      else
        self.AbilitySlot_Throw:ChangeBallState(true, true)
      end
    else
      self.AbilitySlot_Throw:ChangeBallState(false, false)
    end
  end
end

function UMG_PlayerAbilities_C:AutoSetThrowItemVisibility()
  local isLocalMode = NRCEnv:IsLocalMode()
  if isLocalMode then
    self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    self.AbilitySlot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    return
  end
  local EquipItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
  local isHavePet = PetUtils.IsHavePet()
  if self.AbilitySlot_Throw.ThrowItemType == nil then
    self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 1 == self.AbilitySlot_Throw.ThrowItemType then
    if isHavePet then
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      self.AbilitySlot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif 0 == self.AbilitySlot_Throw.ThrowItemType then
    if EquipItem and EquipItem.num > 0 then
      self.AbilitySlot_Throw:ChangeBallState(true, false)
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      self.AbilitySlot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      local hasBall = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckHadUseBall)
      if hasBall then
        self.AbilitySlot_Throw:ChangeBallState(true, true)
      else
        self.AbilitySlot_Throw:ChangeBallState(false, false)
      end
    end
  else
    local EquipMagic = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
    if EquipMagic and EquipMagic.num > 0 then
      local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_THROW)
      if not bHide then
        self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
        self.AbilitySlot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    else
      self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PlayerAbilities_C:SetThrowNull()
  self.AbilitySlot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PlayerAbilities_C:PCSet()
  if self:IsPCMode() then
    self:PCShortCutSet()
    self:PCPerceptionSet()
    self:PCOnPetSet()
    self:PCThrowSet()
    self:PCSlotMainSet()
    self:PCOffPetSet()
  end
end

function UMG_PlayerAbilities_C:PCShortCutSet()
  self.AbilitySlot_ShortCut.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_ShortCut.Text_PCKey:SetText("C")
end

function UMG_PlayerAbilities_C:PCPerceptionSet()
  local position = self.AbilitySlot_Perception.Slot:GetPosition()
  position.x = -508.0
  position.y = -172.0
  self.AbilitySlot_Perception.Slot:SetPosition(position)
end

function UMG_PlayerAbilities_C:PCOnPetSet()
  self.AbilitySlot_OnPet.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_OnPet.Text_PCKey:SetText("R")
  local post = self.AbilitySlot_OnPet.Slot:GetPosition()
  post.x = -566.0
  post.y = -232.0
  self.AbilitySlot_OnPet.Slot:SetPosition(post)
end

function UMG_PlayerAbilities_C:PCThrowSet()
  local pos = self.AbilitySlot_Throw.Slot:GetPosition()
  pos.x = -360.0
  pos.y = -270.0
  self.AbilitySlot_Throw.Slot:SetPosition(pos)
end

function UMG_PlayerAbilities_C:PCSlotMainSet()
  self.AbilitySlot_Main.Slot:SetZOrder(-1)
  self.AbilitySlot_Main.CanvasPanel_4:SetRenderOpacity(0)
  self.AbilitySlot_Main.Btn_Slot:SetRenderOpacity(0)
end

function UMG_PlayerAbilities_C:PCOffPetSet()
  local pos = self.AbilitySlot_OffPet.Slot:GetPosition()
  pos.x = -284.843933
  pos.y = -406.859467
  self.AbilitySlot_OffPet.Slot:SetPosition(pos)
end

function UMG_PlayerAbilities_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_PlayerAbilities_C:OnPcRemovePlant()
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_CLEAR_PLANT, false, false)
  if Ban or self.AbilitySlot_Eradicate:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.AbilitySlot_Eradicate:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self.AbilitySlot_Eradicate:OnSlotClicked()
  end
end

function UMG_PlayerAbilities_C:OnEnterHomeMap()
  if _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InLocalMasterIndoor() and not self.hideThrowItemForFood then
    if self.AbilitySlot_Throw then
      self.AbilitySlot_Throw:ChangeBallState(false, false)
      self.AbilitySlot_PetCare:RefreshView()
    end
    self.hideThrowItemForFood = true
  end
end

function UMG_PlayerAbilities_C:OnExitHomeMap()
  if self.hideThrowItemForFood then
    self.AbilitySlot_PetCare:RefreshView()
    self.hideThrowItemForFood = nil
  end
end

return UMG_PlayerAbilities_C
