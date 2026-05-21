require("UnLuaEx")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PetAbilitySlotManager = require("NewRoco.Modules.System.MainUI.Res.Ability.Pet_Ability_Slot_Manager")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_PC_KeyFoundation_C = _G.NRCViewBase:Extend("UMG_PC_KeyFoundation_C")

function UMG_PC_KeyFoundation_C:OnConstruct()
  if not self:IsPCMode() then
    return
  end
  self:Log("UMG_PC_KeyFoundation_C:OnConstruct")
  self:SetChildViews(self.AbilitySlot_Throw.UMG_Ability_Slot_Throw, self.AbilitySlot_Main.UMG_Ability_Main_Slot, self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility)
  self:AddChildView(self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown)
  self:AddChildView(self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp)
  self:AddChildView(self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet)
  self:AddChildView(self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet)
  self:AddChildView(self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet)
  self:AddChildView(self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet)
  self:AddChildView(self.AbilitySlot_Perception.UMG_Ability_Slot_Perception)
  self:AddChildView(self.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch)
  self:AddChildView(self.AbilitySlot_Jump.UMG_Ability_Slot_Jump)
  self:AddChildView(self.AbilitySlot_Emote.UMG_Ability_Slot_Emote)
  self:AddChildView(self.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform)
  self:AddChildView(self.AbilitySlot_Seed.UMG_Ability_Slot_Seed)
  self:AddChildView(self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate)
  self:AddChildView(self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare)
  self:AddChildView(self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1)
  self:AddChildView(self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand)
  self:AddChildView(self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump)
  self:BindPCKeyToSlotPC()
  self.petAbilitySlotManager = PetAbilitySlotManager()
  self.CanPress = true
  self:MagicShowSet()
  self:EquipItemShowSet()
  self:SeedShowSet()
  self:EquipFoodShowSet()
  self:PCSet()
  self:InitInfo()
  self.playerAbilityImcName = "IMC_PlayerAbilityNormal"
  self.tempImc = "IMC_PlayerAbilityNormal"
  self:SetPcSlotTextByIA(self.AbilitySlot_Main, "IA_PlayerDashStart_Normal")
  self:AddAllIMC()
  self:UiAddInputMappingContext()
  self:OnAddEventListener()
end

function UMG_PC_KeyFoundation_C:BindPCKeyToSlotPC()
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.FoundationPCKey = self.AbilitySlot_Throw.Text_PCKey
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.ParentPanel = self.AbilitySlot_Throw
  self.HUDMagic.UMG_Magic.FoundationPCKey = self.HUDMagic.Text_PCKey
  self.EquipItem.UMG_EquipItem.FoundationPCKey = self.EquipItem.Text_PCKey
  self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1.FoundationPCKey = self.AbilitySlot_PetCare_1.Text_PCKey
  self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1.ParentPanel = self.AbilitySlot_PetCare_1
  self.AbilitySlot_Seed.UMG_Ability_Slot_Seed.FoundationPCKey = self.AbilitySlot_Seed.Text_PCKey
  self.AbilitySlot_Seed.UMG_Ability_Slot_Seed.ParentPanel = self.AbilitySlot_Seed
  self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand.FoundationPCKey = self.AbilitySlot_UnHand.Text_PCKey
  self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand.ParentPanel = self.AbilitySlot_UnHand
  self.AbilitySlot_Jump.UMG_Ability_Slot_Jump.ParentPanel = self.AbilitySlot_Jump
  self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate.FoundationPCKey = self.AbilitySlot_Eradicate.Text_PCKey
  self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate.ParentPanel = self.AbilitySlot_Eradicate
  self.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch.FoundationPCKey = self.AbilitySlot_Crouch.Text_PCKey
  self.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch.ParentPanel = self.AbilitySlot_Crouch
  self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet.FoundationPCKey = self.AbilitySlot_OffTempPet.Text_PCKey
  self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet.ParentPanel = self.AbilitySlot_OffTempPet
  self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare.FoundationPCKey = self.AbilitySlot_PetCare.Text_PCKey
  self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare.ParentPanel = self.AbilitySlot_PetCare
  self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet.FoundationPCKey = self.AbilitySlot_ShortCut.Text_PCKey
  self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet.ParentPanel = self.AbilitySlot_ShortCut
  self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown.FoundationPCKey = self.AbilitySlot_ClimbDown.Text_PCKey
  self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown.ParentPanel = self.AbilitySlot_ClimbDown
  self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump.FoundationPCKey = self.AbilitySlot_RideJump.Text_PCKey
  self.abilityslot_RideJump.UMG_Ability_Main_RideJump.ParentPanel = self.AbilitySlot_RideJump
  self.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform.FoundationPCKey = self.AbilitySlot_Untransform.Text_PCKey
  self.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform.ParentPanel = self.AbilitySlot_Untransform
  self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp.FoundationPCKey = self.AbilitySlot_ClimbUp.Text_PCKey
  self.abilityslot_ClimbUp.UMG_Ability_Main_ClimbUp.ParentPanel = self.AbilitySlot_ClimbUp
  self.AbilitySlot_Main.UMG_Ability_Main_Slot.FoundationPCKey = self.AbilitySlot_Main.Text_PCKey
  self.abilityslot_Main.UMG_Ability_Main_Slot.ParentPanel = self.AbilitySlot_Main
  self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility.FoundationPCKey = self.AbilitySlot_RideAbility.Text_PCKey
  self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility.ParentPanel = self.AbilitySlot_RideAbility
  self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet.FoundationPCKey = self.AbilitySlot_OnPet.Text_PCKey
  self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet.ParentPanel = self.AbilitySlot_OnPet
  self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet.FoundationPCKey = self.AbilitySlot_OffPet.Text_PCKey
  self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet.ParentPanel = self.AbilitySlot_OffPet
  self.AbilitySlot_Perception.UMG_Ability_Slot_Perception.FoundationPCKey = self.AbilitySlot_Perception.Text_PCKey
  self.AbilitySlot_Perception.UMG_Ability_Slot_Perception.ParentPanel = self.AbilitySlot_Perception
  self.AbilitySlot_Emote.UMG_Ability_Slot_Emote.FoundationPCKey = self.AbilitySlot_Emote.Text_PCKey
  self.AbilitySlot_Emote.UMG_Ability_Slot_Emote.ParentPanel = self.AbilitySlot_Emote
end

function UMG_PC_KeyFoundation_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_PC_KeyFoundation_C", self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
end

function UMG_PC_KeyFoundation_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
end

function UMG_PC_KeyFoundation_C:OnDestruct()
  self:RemoveEventListener()
end

function UMG_PC_KeyFoundation_C:AddInputBlock()
  self.CanPress = true
  self:UiRemoveInputMappingContext()
  self.isPcBlock = true
end

function UMG_PC_KeyFoundation_C:AddAllIMC()
  self.imcPriority = -2
  do
    local mappingContext = self:AddInputMappingContext("IMC_PlayerAbilityAll", self.imcPriority)
    if mappingContext then
      mappingContext:BindAction("IA_AbilitySlotOnPet", self, "OnPcAbilitySlotOnPet", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerClimbJumpStart_Climb", self, "OnPcAbilitySlotClimbJumpStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerClimbJumpEnd_Climb", self, "OnPcAbilitySlotClimbJumpEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_ExitClimbing_Climb", self, "OnPcAbilitySlotExitClimbEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_ExitClimbing_ClimbStart", self, "OnPcAbilitySlotExitClimbStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotEmote", self, "OnPcAbilitySlotEmote", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotUntransform", self, "OnPcAbilitySlotUntransform", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_TransformSkillStart_Transform", self, "OnPcAbilitySlotTransformSkillStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_TransformSkillEnd_Transform", self, "OnPcAbilitySlotTransformSkillEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotPerceptionStart", self, "OnPcAbilitySlotPerceptionStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotPerceptionEnd", self, "OnPcAbilitySlotPerceptionEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_CanelRideAbility", self, "OnPcAbilityCancel", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PetRiddingSkillStart_OnPet", self, "OnPcAbilitySlotRideAbilityStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PetRiddingSkillEnd_OnPet", self, "OnPcAbilitySlotRideAbilityEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_SkyPetRiddingSkillStart_OnPet", self, "OnPcAbilitySlotRideSkyAbilityStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_SkyPetRiddingSkillEnd_OnPet", self, "OnPcAbilitySlotRideSkyAbilityEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_OffTempPet_OnPet", self, "OnPcAbilitySlotOffTempPet", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_OffTempPet_OnPetStart", self, "OnPcAbilitySlotOffTempPetStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotShortCut", self, "OnPcAbilitySlotShortCut", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotShortCutStart", self, "OnPcAbilitySlotShortCutStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotOffPet", self, "OnPcAbilitySlotOffPet", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotOnPetStart", self, "OnPcAbilitySlotOnPetStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotOffPetStart", self, "OnPcAbilitySlotOffPetStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerSwimDashEnd_Water", self, "OnPcAbilitySlotWaterDashEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerSwimDashStart_Water", self, "OnPcAbilitySlotWaterDashStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotJump", self, "OnPcAbilitySlotJump", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_ChangeWalkRun", self, "OnPcChangeWalkRun", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotCrouch", self, "OnPcAbilitySlotCrouch", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerDashEnd_Normal", self, "OnPcAbilitySlotMainEnd", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_PlayerDashStart_Normal", self, "OnPcAbilitySlotMainStart", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlotUnHand", self, "OnPcAbilitySlotUnHand", UE.ETriggerEvent.Triggered)
      mappingContext:BindAction("IA_AbilitySlot_SecondMainStart", self, "OnPcAbilitySlotSecondMainStart", UE.ETriggerEvent.Triggered)
      local inputAction = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MagicSelectStart")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction, UE.ETriggerEvent.Triggered, self, "MagicSelectStart")
      local inputAction2 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_MagicSelectEnd")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction2, UE.ETriggerEvent.Triggered, self, "MagicSelectEnd")
      local inputAction3 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_BallSelectStart")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction3, UE.ETriggerEvent.Triggered, self, "BallSelectStart")
      local inputAction4 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_BallSelectEnd")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction4, UE.ETriggerEvent.Triggered, self, "BallSelectEnd")
      local inputAction5 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_OpenSeedBag")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction5, UE.ETriggerEvent.Triggered, self, "OpenSeedBag")
      local inputAction6 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_Shovel_MainUIDefault")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction6, UE.ETriggerEvent.Triggered, self, "OnPcRemovePlant")
      local inputAction7 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_AbilitySlotHomePetFood")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction7, UE.ETriggerEvent.Triggered, self, "OnPcAbilitySlotOnEquipFood")
      local inputAction8 = UE.UNRCEnhancedInputHelper.GetInputAction("IA_AbilitySlotHomePetCall")
      UE.UNRCEnhancedInputHelper.BindAction(inputAction8, UE.ETriggerEvent.Triggered, self, "OnPcAbilitySlotPetCareCall")
    else
      Log.Error("AddInputIMC IMC_PlayerAbilityAll failed")
    end
    return
  end
end

function UMG_PC_KeyFoundation_C:OnNormal()
  return self.playerAbilityImcName == "IMC_PlayerAbilityNormal" and not self.Throwing
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotPetCareCall()
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_PET_CALL, false, false)
  if Ban or self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  elseif self:OnNormal() then
    self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOnEquipFood()
  if self:OnNormal() then
    self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotSeedStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self:OnNormal() then
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotSeedEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self:OnNormal() then
  end
end

function UMG_PC_KeyFoundation_C:RemoveInputBlock()
  self.isPcBlock = nil
  self:UiAddInputMappingContext()
end

function UMG_PC_KeyFoundation_C:UiAddInputMappingContext()
  if self.isPcBlock then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_PlayerAbilityAll")
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
  end
end

function UMG_PC_KeyFoundation_C:UiRemoveInputMappingContext()
  if self.isPcBlock then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_PlayerAbilityAll")
  if mappingContext then
    mappingContext:DisableInputMappingContext()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotCrouch()
  if self:OnNormal() then
    self.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotJump()
  if self:OnNormal() or self.Throwing then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
      return
    end
    self.AbilitySlot_Jump.UMG_Ability_Slot_Jump:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotClimbJumpStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotClimbJumpEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp:OnPCKey(1)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotTransformSkillStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotTransformSkillEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(1)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotRideAbilityStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" then
    local canCast = self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:GetCanCast()
    if canCast then
      self.rideAbilitySkill = true
      self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(0)
    end
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotRideAbilityEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" and self.rideAbilitySkill then
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(1)
  end
  self.rideAbilitySkill = nil
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotRideSkyAbilityStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    local canCast = self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:GetCanCast(true)
    if canCast then
      self.rideAbilitySkySkill = true
      self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(0)
    end
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotRideSkyAbilityEnd()
  if (self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityTransform") and self.rideAbilitySkySkill then
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnPCKey(1)
  end
  self.rideAbilitySkySkill = nil
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotWaterDashStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityWater" then
    self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotWaterDashEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityWater" then
    self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnPCKey(1)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotMainStart()
  if self:OnNormal() then
    self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotMainEnd()
  if self:OnNormal() then
    self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnPCKey(1)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilityCancel()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" and self.CancelChargeBtn.CancelChargeBtn:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:OnCancelChargeBtnClick()
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnSlotCanceled()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOffTempPet()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" then
    self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOffTempPetStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" then
    self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet:OnPCKey(true)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotExitClimbStart()
  self.OnPcAbilityExitClimbSucceed = false
  if self.playerAbilityImcName == "IMC_PlayerAbilityClimb" then
    if self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown.Visibility == UE.ESlateVisibility.HitTestInvisible then
      self.OnPcAbilityExitClimbSucceed = false
    else
      self.OnPcAbilityExitClimbSucceed = true
    end
    self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown:OnPCKey(true)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotExitClimbEnd()
  if self.playerAbilityImcName == "IMC_PlayerAbilityClimb" and self.OnPcAbilityExitClimbSucceed then
    self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOffPetStart()
  self.OnPcAbilitySlotOffPetSucceed = false
  if self.OnPcAbilitySlotOnPetSucceed then
    return
  end
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" then
    if self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet.Visibility == UE.ESlateVisibility.HitTestInvisible then
      self.OnPcAbilitySlotOffPetSucceed = false
    else
      self.OnPcAbilitySlotOffPetSucceed = true
    end
    self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet:OnPCKey(true)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOffPet()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" and self.OnPcAbilitySlotOffPetSucceed then
    self.OnPcAbilitySlotOffPetSucceed = nil
    self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOnPetStart()
  self.OnPcAbilitySlotOnPetSucceed = false
  if self.OnPcAbilitySlotOffPetSucceed then
    return
  end
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    return
  end
  if self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet.Visibility == UE.ESlateVisibility.Hidden or self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet.Visibility == UE.ESlateVisibility.Collapsed or self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet.Visibility == UE.ESlateVisibility.HitTestInvisible then
    self.OnPcAbilitySlotOnPetSucceed = false
  else
    self.OnPcAbilitySlotOnPetSucceed = true
    self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet:OnPCKey(true)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotOnPet()
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    return
  end
  if self.OnPcAbilitySlotOnPetSucceed then
    self.OnPcAbilitySlotOnPetSucceed = nil
    self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotPerceptionStart()
  if self:OnNormal() or self.playerAbilityImcName == "IMC_PlayerAbilityWater" or self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityAir" then
    self.AbilitySlot_Perception.UMG_Ability_Slot_Perception:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotPerceptionEnd()
  if self:OnNormal() or self.playerAbilityImcName == "IMC_PlayerAbilityWater" or self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityAir" then
    self.AbilitySlot_Perception.UMG_Ability_Slot_Perception:OnPCKey(1)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotShortCut()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityAir" then
    if self.AbilitySlotShortCutStartSucceed then
      self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet:OnPCKey()
    end
  else
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING) and self.AbilitySlotShortCutStartSucceed then
      self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet:OnPCKey()
    end
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotShortCutStart()
  self.AbilitySlotShortCutStartSucceed = false
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityAir" then
    self.AbilitySlotShortCutStartSucceed = true
    self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet:OnPCKey(true)
  else
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SLIDING) then
      self.AbilitySlotShortCutStartSucceed = true
      self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet:OnPCKey(true)
    end
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotUntransform()
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotEmote()
  if self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_Emote.UMG_Ability_Slot_Emote:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcChangeWalkRun()
  if self:OnNormal() and self.localPlayer then
    self.localPlayer.viewObj:OnCtrlKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotUnHand()
  if self:OnNormal() or self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" then
    self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand:OnPCKey()
  end
end

function UMG_PC_KeyFoundation_C:OnPcAbilitySlotSecondMainStart()
  if self.playerAbilityImcName == "IMC_PlayerAbilityOnPet" or self.playerAbilityImcName == "IMC_PlayerAbilityTransform" then
    self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump:OnPCKey(0)
  end
end

function UMG_PC_KeyFoundation_C:OnDisable()
  self.CanPress = true
  self.HUDMagic.UMG_Magic:OnDisable()
  self.EquipItem.UMG_EquipItem:OnDisable()
end

function UMG_PC_KeyFoundation_C:MagicSelectStart()
  if self:IsInMiniGamePerform() then
    return
  end
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_MAGIC, true)
  if isBan or self.HUDMagic.UMG_Magic:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.HUDMagic.UMG_Magic:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self:OnPCUseMagic(0)
  end
end

function UMG_PC_KeyFoundation_C:MagicSelectEnd()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_MAGIC, true)
  if isBan or self.HUDMagic.UMG_Magic:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.HUDMagic.UMG_Magic:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self:OnPCUseMagic(1)
  end
end

function UMG_PC_KeyFoundation_C:BallSelectStart()
  if self:IsInMiniGamePerform() then
    return
  end
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_THROW, true)
  if isBan or self.EquipItem.UMG_EquipItem:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.EquipItem.UMG_EquipItem:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self:OnPCUseEquipItem(0)
  end
end

function UMG_PC_KeyFoundation_C:BallSelectEnd()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_THROW, true)
  if isBan or self.EquipItem.UMG_EquipItem:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.EquipItem.UMG_EquipItem:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self:OnPCUseEquipItem(1)
  end
end

function UMG_PC_KeyFoundation_C:UpdateBindInputAction()
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:BindInputAction()
  self:AddAllIMC()
  self:UiAddInputMappingContext()
end

function UMG_PC_KeyFoundation_C:OnPlayerStatusChanged(status, value, opCode)
  local caster = self.localPlayer
  local statusComponent = caster.statusComponent
  if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    self.tempImc = "IMC_PlayerAbilityTransform"
    if "IMC_PlayerAbilityTransform" ~= self.playerAbilityImcName then
      self:SetPcSlotTextByIA(self.AbilitySlot_RideAbility, "IA_TransformSkillStart_Transform")
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    self.tempImc = "IMC_PlayerAbilityOnPet"
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityOnPet" then
      self:SetPcSlotTextByIA(self.AbilitySlot_RideAbility, "IA_PetRiddingSkillStart_OnPet")
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
    self.tempImc = "IMC_PlayerAbilityClimb"
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) then
    self.tempImc = "IMC_PlayerAbilityWater"
    if self.playerAbilityImcName ~= "IMC_PlayerAbilityWater" then
      self:SetPcSlotTextByIA(self.AbilitySlot_Main, "IA_PlayerSwimDashStart_Water")
    end
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING) then
  elseif statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_LANDED) then
    if statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      if self.playerAbilityImcName == "IMC_PlayerAbilityNormal" and not self.Throwing then
        self.Throwing = true
      end
    else
      self.tempImc = "IMC_PlayerAbilityNormal"
      if self.playerAbilityImcName ~= "IMC_PlayerAbilityNormal" then
        self:SetPcSlotTextByIA(self.AbilitySlot_Main, "IA_PlayerDashStart_Normal")
      end
    end
  else
    self.tempImc = "IMC_PlayerAbilityNormal"
  end
  if self.Throwing and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    self.Throwing = nil
  end
end

function UMG_PC_KeyFoundation_C:OnPCUseMagic(action_type)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    local hasMagic = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_MAGIC)
    if not hasMagic then
      return
    elseif 0 == action_type then
      if self.CanPress then
        self.CanPress = false
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
        self.HUDMagic.UMG_Magic:OnBtnPressed()
      end
    else
      self.CanPress = true
      self.HUDMagic.UMG_Magic:OnBtnReleased()
    end
  end
end

function UMG_PC_KeyFoundation_C:OnPCUseEquipItem(action_type)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    if 0 == action_type then
      if self.CanPress then
        self.CanPress = false
        self.EquipItem.UMG_EquipItem:OnBtnPressed()
      end
    else
      self.CanPress = true
      self.EquipItem.UMG_EquipItem:OnBtnReleased()
    end
  end
end

function UMG_PC_KeyFoundation_C:AddChildView(childView)
  table.insert(self.viewChildViews, childView)
end

function UMG_PC_KeyFoundation_C:IsInMiniGamePerform()
  local status = _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
  if "Perform" == miniGameStage or status == ProtoEnum.MinigameStatus.MS_FINISH then
    return true
  end
  return false
end

function UMG_PC_KeyFoundation_C:OnActive()
  self:Log("UMG_PC_KeyFoundation_C:OnActive")
  self:OnBeforeOpen()
  self:AddEventListener()
end

function UMG_PC_KeyFoundation_C:OnDeactive()
  self:Log("UMG_PC_KeyFoundation_C:OnDeActive")
  self:OnBeforeClose()
  _G.UpdateManager:UnRegister(self)
end

function UMG_PC_KeyFoundation_C:OnTick(InDeltaTime)
  self.playerAbilityImcName = self.tempImc
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:Update(InDeltaTime)
  end
end

function UMG_PC_KeyFoundation_C:AddEventListener()
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem, self.UpdateThrowItem)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, self.ShowThrowSlot)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_SHORTCUT, self.ShowShortCut)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_SetThrowNull, self.SetThrowNull)
  self.module:RegisterEvent(self, MainUIModuleEvent.ChangePCCancelAimBtnVisibility, self.ChangePCCancelAimBtnVisibility)
  self.module:RegisterEvent(self, MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, self.ChangePCCancelChargeBtnVisibility)
  self.module:RegisterEvent(self, MainUIModuleEvent.ChangePCShapeShiftBtnVisibility, self.ChangePCShapeShiftBtnVisibility)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  self.CancelChargeBtn.CancelChargeBtn.OnClicked:Add(self, self.OnCancelChargeBtnClick)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnFlagUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_PlayerAbilities_C", self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:RegisterEvent("UMG_PlayerAbilities_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCSet)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MAGIC_UI, self, self.OnChangeMagicUi)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_CATCH_IN_WORLD, self, self.OnChangePetCatch)
end

function UMG_PC_KeyFoundation_C:RemoveEventListener()
  if self.module then
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SetThrowNull)
    self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_SHORTCUT)
  end
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  end
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnFlagUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MAGIC_UI, self, self.OnChangeMagicUi)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_CATCH_IN_WORLD, self, self.OnChangePetCatch)
end

function UMG_PC_KeyFoundation_C:OnFlagUpdate(flagId, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flagId)
  if bIsHomeOwner == UseSelf then
    return
  end
  self:AutoSetThrowItemVisibility()
end

function UMG_PC_KeyFoundation_C:InitInfo()
  Log.Debug("UMG_PC_KeyFoundation_C:InitInfo")
  self.ThrowItemType = -1
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot.LongPressTriggerTime = 0.15
  self:AutoSetThrowItemVisibility()
end

function UMG_PC_KeyFoundation_C:OnBeforeOpen()
  Log.Debug("UMG_PC_KeyFoundation_C:OnBeforeOpen")
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ReBindPlayer()
  self.AbilitySlot_Emote.UMG_Ability_Slot_Emote:ReBindPlayer()
  self.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform:ReBindPlayer()
  self.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch:ReBindPlayer()
  self.AbilitySlot_Main.UMG_Ability_Main_Slot:ReBindPlayer()
  self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown:ReBindPlayer()
  self.AbilitySlot_Jump.UMG_Ability_Slot_Jump:ReBindPlayer()
  self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp:ReBindPlayer()
  self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate:ReBindPlayer()
  self.AbilitySlot_PetCare.UMG_Ability_Slot_PetCare:ReBindPlayer()
  self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1:ReBindPlayer()
  self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand:ReBindPlayer()
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
  self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnActive()
  self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp:OnActive()
  self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnActive()
  self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump:OnActive()
  self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown:OnActive()
  self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand:OnActive()
  local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:BindAbility(throwHelper)
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:Init(self.AbilitySlot_OnPet.UMG_Ability_Slot_OnPet, self.AbilitySlot_OffPet.UMG_Ability_Slot_OffPet, self.AbilitySlot_ShortCut.UMG_Ability_Slot_OnPet, self.AbilitySlot_Perception.UMG_Ability_Slot_Perception, self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility, self.AbilitySlot_OffTempPet.UMG_Ability_Slot_OffPet, self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump, self.module)
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
    self.module:RefreshMainPetSelect()
  end
end

function UMG_PC_KeyFoundation_C:OnBeforeClose()
  if self.localPlayer then
    self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_LOST_FOCUS, self.OnLostFocus)
  end
  self.AbilitySlot_Main.UMG_Ability_Main_Slot:OnDeactive()
  self.AbilitySlot_ClimbUp.UMG_Ability_Main_ClimbUp:OnDeactive()
  self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility:OnDeactive()
  self.AbilitySlot_RideJump.UMG_Ability_Main_RideJump:OnDeactive()
  self.AbilitySlot_ClimbDown.UMG_Ability_Slot_ClimbDown:OnDeactive()
  self.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand:OnDeactive()
  if self.petAbilitySlotManager then
    self.petAbilitySlotManager:UnInit()
  end
end

function UMG_PC_KeyFoundation_C:SetThrowItem(itemType, itemId)
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetPetSwitchShow(itemType, itemId)
end

function UMG_PC_KeyFoundation_C:OnLostFocus()
  self:OnPcAbilityCancel()
end

function UMG_PC_KeyFoundation_C:UpdateThrowItem(itemType, itemId, recycleState, session)
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetIsEnabled(true)
  self:SetThrowItemVisibility(itemType, itemId)
  if nil == itemId then
    return
  end
  self:MagicShowSet()
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetPetSwitchShow(itemType, itemId, recycleState, session)
  if 0 == itemType then
    self:SetThrowOrRecycle(false, nil)
  else
    self:SetThrowOrRecycle(recycleState, session)
  end
end

function UMG_PC_KeyFoundation_C:SetThrowOrRecycle(recycleState, session)
  local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
  local recycleHelper = AbilityHelperManager.GetHelper(AbilityID.RECYCLE_THROW)
  if true == recycleState then
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:BindAbility(recycleHelper)
  else
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:BindAbility(throwHelper)
  end
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:OnPetStatusChanged(nil, nil, self.AbilitySlot_Throw.UMG_Ability_Slot_Throw._pet)
end

function UMG_PC_KeyFoundation_C:ShowThrowSlot(showJoystic)
  Log.Debug("UMG_PC_KeyFoundation_C:ShowThrowSlot", showJoystic)
  if false == showJoystic then
    self:AutoSetThrowItemVisibility()
  else
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_PC_KeyFoundation_C:ChangeHUDMagicByFunctionBan(bShow)
  if bShow then
    self:MagicShowSet()
  else
    self.HUDMagic.UMG_Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HUDMagic.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:ChangeEquipItemByFunctionBan(bShow)
  if self:IsPCMode() then
    if bShow then
      self.EquipItem.UMG_EquipItem:ShowEquipItem(UE4.ESlateVisibility.Visible)
    else
      self.EquipItem.UMG_EquipItem:ShowEquipItem(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.EquipItem.UMG_EquipItem:ShowEquipItem(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:MagicShowSet()
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MAGIC_UI, false, false)
  if Ban then
    Log.Debug("UMG_CompassIcon_C.show \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    if self.HUDMagic then
      if self.HUDMagic.UMG_Magic then
        self.HUDMagic.UMG_Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.HUDMagic.Text_PCKey then
        self.HUDMagic.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    return
  end
  local hasMagic = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_MAGIC)
  if not hasMagic then
    self.HUDMagic.UMG_Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HUDMagic.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.HUDMagic.UMG_Magic:SetVisibility(UE4.ESlateVisibility.Visible)
    if self:IsPCMode() then
      self.HUDMagic.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Visible)
      self.HUDMagic.UMG_Magic.MagicBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      self.HUDMagic.UMG_Magic.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_PC_KeyFoundation_C:EquipItemShowSet()
  if self:IsPCMode() then
    self.EquipItem.UMG_EquipItem:ShowEquipItem(UE4.ESlateVisibility.Visible)
  else
    self.EquipItem.UMG_EquipItem:ShowEquipItem(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:SetMagicSelected(visible)
  self.HUDMagic.UMG_Magic:ShowSelected(visible)
end

function UMG_PC_KeyFoundation_C:SetEquipItemSelected(visible)
  if self:IsPCMode() then
    self.EquipItem.UMG_EquipItem:ShowSelected(visible)
  else
    self.EquipItem.UMG_EquipItem:CheckEquipItemShow(false, true)
  end
end

function UMG_PC_KeyFoundation_C:OnChangeMagicUi(State, FunctionBanType, ConditionType)
  self:ChangeHUDMagicByFunctionBan(not State)
end

function UMG_PC_KeyFoundation_C:OnChangePetCatch(State, FunctionBanType, ConditionType)
  self:ChangeEquipItemByFunctionBan(not State)
end

function UMG_PC_KeyFoundation_C:ChangeHUDMagicState(show)
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MAGIC_UI, false, false)
  if Ban then
    Log.Debug("UMG_CompassIcon_C.show \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  local hasMagic = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_MAGIC)
  if hasMagic and self:IsPCMode() then
    self.HUDMagic.UMG_Magic:SetVisibility(show)
    self.HUDMagic.Text_PCKey:SetVisibility(show)
  end
end

function UMG_PC_KeyFoundation_C:ChangeEquipItemState(show)
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_CATCH_IN_WORLD, false, false)
  if Ban then
    Log.Debug("UMG_CompassIcon_C.show \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  local hide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
  if hide then
    return
  end
  if self:IsPCMode() then
    local hasBall = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckHadUseBall)
    if hasBall then
      self.EquipItem.UMG_EquipItem:ShowEquipItem(show)
    end
  else
    self.EquipItem.UMG_EquipItem:CheckEquipItemShow(false, true)
  end
end

function UMG_PC_KeyFoundation_C:ChangeHUDMagicByFunctionBan(bShow)
  if bShow then
    self:MagicShowSet()
  else
    self.HUDMagic.UMG_Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HUDMagic.Text_PCKey:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:UpdateEquipMagicItemInfo(bSetThrow)
  self.CanPress = true
  local curEquipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
  local curEquipItemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
  local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if self:IsPCMode() then
    self.HUDMagic.UMG_Magic:SetMagicInfo(curEquipMagicInfo, bSetThrow)
  end
  if curSelectedPetGid <= 0 and nil == curEquipMagicInfo and nil == curEquipItemInfo then
    local CatchPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    for i = 1, #CatchPetInfo do
      if PetUtils.GetPetBaseAttrByType(CatchPetInfo[i], _G.ProtoEnum.AttributeType.AT_HPCUR) > 0 then
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, CatchPetInfo[i])
        return
      end
    end
  end
end

function UMG_PC_KeyFoundation_C:UpdateEquipItemInfo(bSetThrow)
  local curEquipitem = NRCModuleManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
  if nil == curEquipitem then
    self:SetEquipItemSelected(false)
  end
  if self:IsPCMode() then
    self.EquipItem.UMG_EquipItem:SetEquipItem(curEquipitem, bSetThrow)
  else
    self.EquipItem.UMG_EquipItem:CheckEquipItemShow(false, true)
  end
end

function UMG_PC_KeyFoundation_C:ShowShortCut()
  local caster = self.localPlayer
  local statusComponent = caster.statusComponent
  if not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and not statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_SWIMMING) and statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING) then
    self.tempImc = "IMC_PlayerAbilityAir"
  end
end

function UMG_PC_KeyFoundation_C:GetSkillPanelVisible()
  return self.SkillVisible
end

function UMG_PC_KeyFoundation_C:InitForLocalMode()
  Log.Debug("UMG_PC_KeyFoundation_C:InitForLocalMode")
  self:InitInfo()
  self:OnBeforeOpen()
end

function UMG_PC_KeyFoundation_C:OnSceneLoaded()
  Log.Debug("UMG_PC_KeyFoundation_C:OnSceneLoaded")
  self:InitInfo()
  self:OnSceneLoadedResetActivated()
  self:OnBeforeOpen()
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
end

function UMG_PC_KeyFoundation_C:OnSceneLoadedResetActivated()
  if self.AbilitySlot_Main then
    self.AbilitySlot_Main.UMG_Ability_Main_Slot._activated = false
  end
  if self.AbilitySlot_RideAbility then
    self.AbilitySlot_RideAbility.UMG_Ability_Main_RideAbility._activated = false
  end
end

function UMG_PC_KeyFoundation_C:SetThrowItemVisibility(itemType, item)
  local isAiming = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
  if isAiming then
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 1 == itemType then
    if not PetUtils.IsHavePet() then
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  else
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    if item and item.num then
      if item.num > 0 then
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(true, false)
      else
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(true, true)
      end
    else
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(false, false)
    end
  end
end

function UMG_PC_KeyFoundation_C:AutoSetThrowItemVisibility()
  local isLocalMode = NRCEnv:IsLocalMode()
  if isLocalMode then
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    return
  end
  local EquipItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetCurEquipItemInfo)
  local isHavePet = PetUtils.IsHavePet()
  if self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.ThrowItemType == nil then
    self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 1 == self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.ThrowItemType then
    if isHavePet then
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif 0 == self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.ThrowItemType then
    if EquipItem and EquipItem.num > 0 then
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(true, false)
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
      local hasBall = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckHadUseBall)
      if hasBall then
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(true, true)
      else
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ChangeBallState(false, false)
      end
    end
  else
    local EquipMagic = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
    if EquipMagic and EquipMagic.num > 0 then
      local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_THROW)
      if not bHide then
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Visible)
        self.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    else
      self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PC_KeyFoundation_C:SetThrowNull()
  self.AbilitySlot_Throw.UMG_Ability_Slot_Throw:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PC_KeyFoundation_C:ChangePCCancelAimBtnVisibility(bIsShow)
  if bIsShow then
    self.CancelAimBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.CancelAimBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:ChangePCCancelChargeBtnVisibility(bIsShow)
  if bIsShow then
    self.CancelChargeBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CancelChargeBtn.CancelChargeBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CancelChargeBtn.ScrollPCKey_2:SetKeyVisibility(true)
  else
    self.CancelChargeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CancelChargeBtn.CancelChargeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CancelChargeBtn.ScrollPCKey_2:SetKeyVisibility(false)
  end
end

function UMG_PC_KeyFoundation_C:OnCancelChargeBtnClick()
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:SendEvent(PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, false)
end

function UMG_PC_KeyFoundation_C:ChangePCShapeShiftBtnVisibility(bIsShow)
  if bIsShow then
    self.ShapeshiftBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ShapeshiftBtn.ShapeshiftBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShapeshiftBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShapeshiftBtn.ShapeshiftBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PC_KeyFoundation_C:PCSet()
  if self:IsPCMode() and SystemSettingModuleCmd then
    self:PCCancelAimBtnSet()
    self:PCCancelChargeBtnSet()
    self:PCShapeShiftBtnSet()
    self:PcTextSet()
  end
end

function UMG_PC_KeyFoundation_C:SetPcSlotTextByIA(abilitySlot, iaName)
  local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, iaName)
  if "" ~= image then
    abilitySlot.Text_PCKey:SetImageMode(image)
  else
    abilitySlot.Text_PCKey:SetText(text)
  end
end

function UMG_PC_KeyFoundation_C:PcTextSet()
  self.AbilitySlot_ClimbDown.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_ClimbUp.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_RideAbility.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_RideJump.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_ShortCut.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_Perception.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_OnPet.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_Main.Text_PCKey:SetKeyVisibility(true)
  self.abilitySlot_Untransform.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_Eradicate.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_PetCare.Text_PCKey:SetKeyVisibility(true)
  self.AbilitySlot_UnHand.Text_PCKey:SetKeyVisibility(true)
  if SystemSettingModuleCmd then
    self:SetPcSlotTextByIA(self.AbilitySlot_ClimbDown, "IA_ExitClimbing_Climb")
    self:SetPcSlotTextByIA(self.AbilitySlot_ClimbUp, "IA_PlayerClimbJumpStart_Climb")
    self:SetPcSlotTextByIA(self.AbilitySlot_ShortCut, "IA_AbilitySlotShortCut")
    self:SetPcSlotTextByIA(self.AbilitySlot_Perception, "IA_AbilitySlotPerceptionStart")
    self:SetPcSlotTextByIA(self.AbilitySlot_OnPet, "IA_AbilitySlotOnPet")
    self:SetPcSlotTextByIA(self.abilitySlot_Untransform, "IA_AbilitySlotUntransform")
    self:SetPcSlotTextByIA(self.AbilitySlot_OffPet, "IA_AbilitySlotOffPet")
    self:SetPcSlotTextByIA(self.AbilitySlot_OffTempPet, "IA_OffTempPet_OnPet")
    self:SetPcSlotTextByIA(self.HUDMagic, "IA_MagicSelectStart")
    self:SetPcSlotTextByIA(self.EquipItem, "IA_BallSelectStart")
    self:SetPcSlotTextByIA(self.AbilitySlot_Crouch, "IA_AbilitySlotCrouch")
    self:SetPcSlotTextByIA(self.AbilitySlot_Seed, "IA_OpenSeedBag")
    self:SetPcSlotTextByIA(self.AbilitySlot_PetCare, "IA_AbilitySlotHomePetCall")
    self:SetPcSlotTextByIA(self.AbilitySlot_PetCare_1, "IA_AbilitySlotHomePetFood")
    self:SetPcSlotTextByIA(self.AbilitySlot_Eradicate, "IA_Shovel_MainUIDefault")
    self:SetPcSlotTextByIA(self.AbilitySlot_UnHand, "IA_AbilitySlotUnHand")
  end
end

function UMG_PC_KeyFoundation_C:PCCancelAimBtnSet()
  self.ScrollPCKey:SetKeyVisibility(true)
  self.ScrollPCKey:SetRightClickMode()
end

function UMG_PC_KeyFoundation_C:PCCancelChargeBtnSet()
  local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_CanelRideAbility")
  if "" ~= image then
    self.CancelChargeBtn.ScrollPCKey_2:SetImageMode(image)
  else
    self.CancelChargeBtn.ScrollPCKey_2:SetText(text)
  end
end

function UMG_PC_KeyFoundation_C:PCShapeShiftBtnSet()
  self.ShapeshiftBtn.ScrollPCKey_1:SetKeyVisibility(true)
  local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_Shapeshift")
  if "" ~= image then
    self.ShapeshiftBtn.ScrollPCKey_1:SetImageMode(image)
  else
    self.ShapeshiftBtn.ScrollPCKey_1:SetText(text)
  end
end

function UMG_PC_KeyFoundation_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_PC_KeyFoundation_C:OnBagInfoChange()
  self:UpdateEquipItemInfo(false)
  self:UpdateEquipMagicItemInfo(false)
end

function UMG_PC_KeyFoundation_C:SeedShowSet()
  local bPCMode = self:IsPCMode()
  if self.AbilitySlot_Seed.UMG_Ability_Slot_Seed and self.AbilitySlot_Seed.UMG_Ability_Slot_Seed.SetInputType then
    self.AbilitySlot_Seed.UMG_Ability_Slot_Seed:SetInputType(true, bPCMode)
  end
end

function UMG_PC_KeyFoundation_C:OpenSeedBag()
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_PLANT, false, false)
  if Ban or self.AbilitySlot_Seed.UMG_Ability_Slot_Seed:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.AbilitySlot_Seed.UMG_Ability_Slot_Seed:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self.AbilitySlot_Seed.UMG_Ability_Slot_Seed:OnSlotClicked()
  end
end

function UMG_PC_KeyFoundation_C:SeedShowSet()
  local bPCMode = self:IsPCMode()
  if self.AbilitySlot_Seed.UMG_Ability_Slot_Seed and self.AbilitySlot_Seed.UMG_Ability_Slot_Seed.SetInputType then
    self.AbilitySlot_Seed.UMG_Ability_Slot_Seed:SetInputType(true, bPCMode)
  end
end

function UMG_PC_KeyFoundation_C:EquipFoodShowSet()
  local bPCMode = self:IsPCMode()
  if self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1 and self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1.SetInputType then
    self.AbilitySlot_PetCare_1.UMG_Ability_Slot_PetCare1:SetInputType(true, bPCMode)
  end
end

function UMG_PC_KeyFoundation_C:OnPcRemovePlant()
  local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_CLEAR_PLANT, false, false)
  if Ban or self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate:GetVisibility() == UE4.ESlateVisibility.Collapsed or self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  else
    self.AbilitySlot_Eradicate.UMG_Ability_Slot_Eradicate:OnSlotClicked()
  end
end

return UMG_PC_KeyFoundation_C
