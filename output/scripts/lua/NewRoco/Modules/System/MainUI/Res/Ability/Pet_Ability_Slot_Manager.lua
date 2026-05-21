require("UnLuaEx")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatusUtils = require("NewRoco.Modules.Core.Scene.Component.Status.StatusUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local SummonPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SummonPetComponent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local Pet_Ability_Slot_Manager = NRCClass:Extend("Pet_Ability_Slot_Manager")

function Pet_Ability_Slot_Manager:Init(onPetSlot, offPetSlot, shortCutSlot, perceptionSlot, rideAbilitySlot, offTempPetSlot, rideJumpSlot, mainUIModule)
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self._inited then
    if localPlayer.isReconnect then
      self:TrySetRidePet()
      return
    end
    self:UnInit()
  end
  localPlayer.petAbilitySlotManager = self
  self._onPetSlot = onPetSlot
  self._offTempPetSlot = offTempPetSlot
  self._shortCutSlot = shortCutSlot
  self._perceptionSlot = perceptionSlot
  self._rideAbilitySlot = rideAbilitySlot
  self._rideJumpSlot = rideJumpSlot
  self._onPetSlot:OnInit()
  self._offTempPetSlot:OnInit()
  self._shortCutSlot:OnInit(true)
  self._perceptionSlot:OnInit()
  self._perceptionSlot:BindAbility()
  self.localPlayer = localPlayer
  self.module = mainUIModule
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_RefreshMainPetSelectedState, self.OnSetMainPet)
  self.module:RegisterEvent(self, MainUIModuleEvent.UI_Refresh_MainPet, self.OnUIRefreshMainPet)
  self.module:RegisterEvent(self, MainUIModuleEvent.PetHeadInfoChange, self.OnFreePet)
  self.module:RegisterEvent(self, MainUIModuleEvent.HidePetAbilitySlot, self.OnHideUI)
  NRCEventCenter:RegisterEvent("Pet_Ability_Slot_Manager", self, SceneEvent.OnPlayerEnterGrass, self.OnPlayerEnterGrass)
  NRCEventCenter:RegisterEvent("Pet_Ability_Slot_Manager", self, SceneEvent.OnPlayerExitGrass, self.OnPlayerExitGrass)
  NRCEventCenter:RegisterEvent("Pet_Ability_Slot_Manager", self, SceneEvent.OnMiniGameRide, self.OnMiniGameRide)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_WILL_OUT_OFF_CONTROL, self.OnOutOfControl)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_RETURN_TO_CONTROL, self.OnGetControl)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.OnEnvMask)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, self.OnDoubleRideSucceed)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChanged)
  self.localPlayer:AddEventListener(self, PlayerModuleEvent.ON_RELATION_RIDE_PET, self.OnRelationRidePet)
  _G.NRCEventCenter:RegisterEvent("Pet_Ability_Slot_Manager", self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  self.showDelay = _G.DataConfigManager:GetGlobalConfigNumByKeyType("pet_ability_shortcut_show_delay", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 500) / 1000.0
  self._curShowDelay = 0
  self._petInfo = {}
  self._inited = true
  self:SetMainPet(self._mainPet)
  self:TryHideShortCut()
  self:TrySetRidePet()
end

function Pet_Ability_Slot_Manager:UnInit()
  self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_RefreshMainPetSelectedState)
  self.module:UnRegisterEvent(self, MainUIModuleEvent.UI_Refresh_MainPet)
  self.module:UnRegisterEvent(self, MainUIModuleEvent.PetHeadInfoChange)
  self.module:UnRegisterEvent(self, MainUIModuleEvent.HidePetAbilitySlot)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerEnterGrass, self.OnPlayerEnterGrass)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerExitGrass, self.OnPlayerExitGrass)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnMiniGameRide, self.OnMiniGameRide)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_WILL_OUT_OFF_CONTROL, self.OnOutOfControl)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_RETURN_TO_CONTROL, self.OnGetControl)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_ENV_MASK_CHANGED, self.OnEnvMask)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, self.OnDoubleRideSucceed)
  self.localPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_RELATION_RIDE_PET, self.OnRelationRidePet)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  for pet, v in pairs(self._petInfo) do
    pet:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
  end
  self.localPlayer.petAbilitySlotManager = nil
  self._petInfo = {}
  self._onPetSlot:OnUnInit()
  self._offTempPetSlot:OnUnInit()
  self._shortCutSlot:OnUnInit()
  self._perceptionSlot:OnUnInit()
  self._onPetSlot = nil
  self._offTempPetSlot = nil
  self._shortCutSlot = nil
  self._perceptionSlot = nil
  self.localPlayer = nil
  self.module = nil
  self._inited = false
  self._mainPet = nil
end

function Pet_Ability_Slot_Manager:OnSceneLoaded()
  self.localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self._onPetSlot:ReBindPlayer()
  self._offTempPetSlot:ReBindPlayer()
  self._shortCutSlot:ReBindPlayer()
  self._perceptionSlot:ReBindPlayer()
  self._rideAbilitySlot:ReBindPlayer()
  self._rideJumpSlot:ReBindPlayer()
end

function Pet_Ability_Slot_Manager:OnSetMainPet(gid)
  local pet = self.localPlayer:GetPetByGid(gid)
  self:SetMainPet(pet)
end

function Pet_Ability_Slot_Manager:SetMainPet(pet)
  if self._mainPet == pet and pet and self._petInfo[pet] and self._petInfo[pet] == pet.config.id then
    return
  end
  if pet then
    self.mainPetCanFly = self:PetCanShortCutFly(pet)
    if self.mainPetCanFly then
      self:TryHideShortCut()
    end
    self:TryRefreshShortCut()
    Log.DebugFormat("SetMainPet id = %d", pet.config.id)
  else
    self.mainPetCanFly = false
  end
  if pet and pet.config.scene_ability > 0 then
    self._onPetSlot:BindAbility(pet.config.scene_ability, pet)
    self._onPetSlot:NotifyPetStatus(pet, pet:GetStatus())
    self._perceptionSlot:RemovePet()
  else
    local allRideConf
    if pet then
      allRideConf = DataConfigManager:GetAllRidePet(pet.config.id, true)
    end
    if allRideConf and not allRideConf.not_use_for_ride then
      self._onPetSlot:BindAbility(AbilityID.RIDE_ALL, pet)
      self._onPetSlot:NotifyPetStatus(pet, pet:GetStatus())
      self._offTempPetSlot:NotifyPetStatus(pet, pet:GetStatus())
      self._perceptionSlot:RemovePet()
    else
      self._onPetSlot:UnBindAbility(pet)
      self._perceptionSlot:AddPet(pet)
      if pet then
        self._perceptionSlot:NotifyPetStatus(pet, pet:GetStatus())
      else
        self._onPetSlot:BindCurrentRide()
      end
    end
  end
  if pet then
    self:AddPet(pet)
  end
  if self._mainPet ~= pet then
    if self._mainPet and self._mainPet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG then
      self:RemovePet(self._mainPet)
    end
    self._mainPet = pet
  end
end

function Pet_Ability_Slot_Manager:AddPet(pet)
  if self._petInfo[pet] then
    if self._petInfo[pet] == pet.config.id then
      return
    end
    self:RemovePet(pet)
  end
  self._petInfo[pet] = pet.config.id
  pet:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
  self:OnPetStatusChanged(pet:GetStatus(), nil, pet)
end

function Pet_Ability_Slot_Manager:RemovePet(pet)
  if self._petInfo[pet] then
    pet:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPetStatusChanged)
    pet:ResetStatus()
    self._petInfo[pet] = nil
  end
end

function Pet_Ability_Slot_Manager:OnFreePet(gidList)
  if not gidList then
    return
  end
  for i, v in ipairs(gidList) do
    local gid = v
    local pet = self.localPlayer:GetPetByGid(gid)
    if pet and self._petInfo[pet] then
      if self._mainPet and self._mainPet.gid == gid then
        self:SetMainPet(nil)
      end
      self:RemovePet(pet)
    end
  end
end

function Pet_Ability_Slot_Manager:OnUIRefreshMainPet()
  self:TryRefreshShortCut()
end

function Pet_Ability_Slot_Manager:OnPlayerEnterGrass()
  if not self._isOutOfControl then
    self:TryHideShortCut()
  end
end

function Pet_Ability_Slot_Manager:OnPlayerExitGrass()
  if self._isOutOfControl then
    self:TryShowShortCut()
  end
end

function Pet_Ability_Slot_Manager:OnDoubleRideSucceed(isOnPet, petID, isPlayer1P)
end

function Pet_Ability_Slot_Manager:TryHideShortCut()
  local focusPet = self._shortCutSlot:GetFocusPet()
  if self._shortCutSlot:GetVisible() or focusPet then
    self._shortCutSlot:UnBindAbility()
  end
  self._rideJumpSlot:OnShortCutFlyChange(false)
end

function Pet_Ability_Slot_Manager:BindShortCutPet()
  local flyPet
  if self.localPlayer:IsInTogetherMove() then
    flyPet = self:GetDoubleFlyPet()
  else
    flyPet = self:GetFlyPet()
  end
  if flyPet then
    self._shortCutSlot:BindAbility(AbilityID.RIDE_ALL, flyPet)
    self._shortCutSlot:NotifyPetStatus(flyPet, flyPet:GetStatus())
  end
  return flyPet
end

function Pet_Ability_Slot_Manager:TryShowShortCut()
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) or self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    return
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_ABILITY_SHORTCUT)
  if not self._shortCutSlot:GetVisible() then
    local flyPet = self:BindShortCutPet()
    if flyPet then
      self._rideJumpSlot:OnShortCutFlyChange(true)
    else
      Log.Debug("pet slot: no fly pet available")
    end
  end
end

function Pet_Ability_Slot_Manager:TryRefreshShortCut()
  if self._shortCutSlot:GetVisible() then
    self:BindShortCutPet()
  elseif self._isOutOfControl then
    self:TryShowShortCut()
  end
end

function Pet_Ability_Slot_Manager:GetFlyPet()
  if self._mainPet and self._mainPet.config then
    self.mainPetCanFly = self:PetCanShortCutFly(self._mainPet)
    if self.mainPetCanFly then
      return self._mainPet
    end
  end
  if table.contains(ProtoEnum.SceneRideAllType.SRAT_FLY) then
    return nil
  end
  local flyPet
  local teamInfo = DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  if not (teamInfo and teamInfo.teams) or "table" ~= type(teamInfo.teams) or #teamInfo.teams < 1 then
    return nil
  end
  local mainTeam = teamInfo.teams[teamInfo.main_team_idx + 1]
  if not (mainTeam and mainTeam.pet_infos) or "table" ~= type(mainTeam.pet_infos) then
    return nil
  end
  for _, petInfo in pairs(mainTeam.pet_infos) do
    local pet = self.localPlayer:GetPetByGid(petInfo.pet_gid)
    if pet and self:PetCanShortCutFly(pet) then
      flyPet = pet
      break
    end
  end
  if flyPet then
    return flyPet
  end
  return nil
end

function Pet_Ability_Slot_Manager:GetDoubleFlyPet()
  local rideComponent = self.localPlayer.viewObj.BP_RideComponent
  local tempPet
  if self._mainPet and self._mainPet.config then
    self.mainPetCanFly = self:PetCanShortCutFly(self._mainPet)
    if self.mainPetCanFly then
      if rideComponent:IsDoubleRidePet(self._mainPet, false) then
        return self._mainPet
      else
        tempPet = self._mainPet
      end
    end
  end
  if table.contains(ProtoEnum.SceneRideAllType.SRAT_FLY) then
    return tempPet
  end
  local flyPet
  local teamInfo = DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  if not (teamInfo and teamInfo.teams) or "table" ~= type(teamInfo.teams) or #teamInfo.teams < 1 then
    return nil
  end
  local mainTeam = teamInfo.teams[teamInfo.main_team_idx + 1]
  if not (mainTeam and mainTeam.pet_infos) or "table" ~= type(mainTeam.pet_infos) then
    return nil
  end
  for _, petInfo in pairs(mainTeam.pet_infos) do
    local pet = self.localPlayer:GetPetByGid(petInfo.pet_gid)
    if pet and self:PetCanShortCutFly(pet) then
      if rideComponent:IsDoubleRidePet(pet, false) then
        flyPet = pet
        break
      else
        tempPet = tempPet or pet
      end
    end
  end
  if flyPet then
    return flyPet
  end
  return tempPet
end

function Pet_Ability_Slot_Manager:PetCanShortCutFly(pet)
  if pet and pet.rideConfig then
    local function CheckHp()
      if pet.gid and pet.gid > 0 then
        local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet.gid)
        
        local PetAdditional = PetData.attribute_new_info.addi_attr_data
        local curHp = 114514
        for i, attr in ipairs(PetAdditional) do
          if attr.type == _G.ProtoEnum.AttributeType.AT_HPCUR then
            curHp = attr.addi_attr
          end
        end
        return curHp > 0
      end
    end
    
    local movementList = pet.rideConfig.basic_movement_list
    if 1 == #movementList then
      local movementId = movementList[1]
      local movementConfig = DataConfigManager:GetRideBasicMovement(movementId)
      return movementConfig.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY and CheckHp()
    end
    if self.localPlayer and self.localPlayer.viewObj then
      local isPlayerFalling = self.localPlayer.viewObj.CharacterMovement.MovementMode == UE4.EMovementMode.MOVE_Falling
      local isPetFalling = false
      local RidePet = self.localPlayer.viewObj.BP_RideComponent.RidePet
      if RidePet then
        isPetFalling = RidePet.CharacterMovement.MovementMode == UE4.EMovementMode.MOVE_Falling
      end
      if not isPlayerFalling and not isPetFalling then
        return false
      end
    end
    for i = 1, #movementList do
      local movementId = movementList[i]
      local movementConfig = DataConfigManager:GetRideBasicMovement(movementId)
      if movementConfig.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY then
        return (CheckHp())
      end
    end
  end
  return false
end

function Pet_Ability_Slot_Manager:TrySetRidePet()
  if not self.localPlayer or not self.localPlayer.viewObj then
    Log.Error("\229\136\157\229\167\139\229\140\150\229\164\167\228\184\150\231\149\140\230\138\128\232\131\189UI\229\164\177\232\180\165\239\188\129")
    return
  end
  local RidePet = self.localPlayer.viewObj.BP_RideComponent.ScenePet
  if RidePet then
    if RidePet ~= self._mainPet and self._mainPet and self._mainPet.gid > 0 then
      self._onPetSlot:NotifyPetStatus(RidePet, RidePet:GetStatus())
    end
    self._offTempPetSlot:NotifyPetStatus(RidePet, RidePet:GetStatus())
    self:AddPet(RidePet)
  end
end

function Pet_Ability_Slot_Manager:Update(deltaTime)
  if not self._curShowDelay then
    self._curShowDelay = 0
  end
  if self._isOutOfControl then
    if self._curShowDelay > 0 then
      self._curShowDelay = self._curShowDelay - deltaTime
      if self._curShowDelay < 0 then
        self:TryShowShortCut()
        self._curShowDelay = self.showDelay
      end
    end
  elseif self._curShowDelay > 0 then
    self._curShowDelay = self._curShowDelay - deltaTime
    if self._curShowDelay < 0 then
      self:TryHideShortCut()
    end
  end
  if self._mainPet and self._mainPet.isMiniGamePet then
    self._mainPet:Update(deltaTime)
  end
end

function Pet_Ability_Slot_Manager:OnPetStatusChanged(status, value, pet)
  local petStatus = pet:GetStatus()
  if self._petInfo[pet] then
    self._onPetSlot:NotifyPetStatus(pet, petStatus)
    self._offTempPetSlot:NotifyPetStatus(pet, petStatus)
    self._shortCutSlot:NotifyPetStatus(pet, petStatus)
  end
  self._perceptionSlot:NotifyPetStatus(pet, petStatus)
  if petStatus == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG and pet ~= self._mainPet then
    self:RemovePet(pet)
  end
end

function Pet_Ability_Slot_Manager:OnOutOfControl()
  self._isOutOfControl = true
  self._curShowDelay = self.showDelay or 0
  if self._curShowDelay < 0.05 then
    self._curShowDelay = 0.01
    self:TryShowShortCut()
  end
end

function Pet_Ability_Slot_Manager:OnGetControl()
  self._isOutOfControl = false
  self._curShowDelay = 0.01
end

function Pet_Ability_Slot_Manager:OnPlayerStatusChanged(status, value, opCode)
  if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
    self._shortCutSlot:UnBindAbility()
    self._isOutOfControl = false
  end
  local shortPet = self._shortCutSlot:GetFocusPet()
  local RideCompoment = self.localPlayer.viewObj.BP_RideComponent
  if RideCompoment and RideCompoment.ScenePet then
    if shortPet and RideCompoment.ScenePet == shortPet then
      self._shortCutSlot:UnBindAbility()
    end
    if self.localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and not self._petInfo[RideCompoment.ScenePet] then
      self:TrySetRidePet()
    end
  else
    self:TryRefreshShortCut()
  end
end

function Pet_Ability_Slot_Manager:ReCallOffPet(pet)
end

function Pet_Ability_Slot_Manager:OnEnvMask()
  self._onPetSlot:OnEnvMask()
  self._offTempPetSlot:OnEnvMask()
  self._shortCutSlot:OnEnvMask()
end

function Pet_Ability_Slot_Manager:LogDebugInfo(msg)
end

function Pet_Ability_Slot_Manager:OnMovementModeChanged(PreMoveMode, CurMoveMode, PreCustomMode, CurCustomMode)
end

function Pet_Ability_Slot_Manager:OnMiniGameRide(petID, vitality, rideAllCustomGid, npcId, optionId)
  if petID > 0 then
    if self._mainPet and self._mainPet.config.id == petID and self._mainPet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
      return
    end
    local pet
    if rideAllCustomGid == _G.ProtoEnum.SceneRideAllCustomGid.SRCG_MiniGame then
      pet = self:GetMiniGamePetFromTeam(petID)
    end
    if not pet then
      local playerModule = NRCModuleManager:GetModule("PlayerModule")
      local gid = -rideAllCustomGid
      pet = ScenePlayerPet(playerModule, petID, gid, self.localPlayer)
      pet.isMiniGamePet = true
      pet.npcId = npcId
      pet.optionId = optionId
    end
    self.localPlayer:StopRide(true)
    self.localPlayer.abilityComponent:StopAbility(true)
    if pet.isMiniGamePet and pet then
      self:AddPet(pet)
    end
    local helper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL)
    if helper then
      helper:HandleStatus(self.localPlayer, pet)
    end
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
  end
end

function Pet_Ability_Slot_Manager:OnRelationRidePet(pet, isMine)
  self:AddPet(pet)
end

function Pet_Ability_Slot_Manager:GetMiniGamePetFromTeam(petID)
  if self._mainPet and self._mainPet.config.id == petID then
    return self._mainPet
  end
  local teamInfo = DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  if not teamInfo or #teamInfo.teams < 1 then
    return nil
  end
  local mainTeam = teamInfo.teams[teamInfo.main_team_idx + 1]
  if mainTeam and mainTeam.pet_infos then
    for _, petInfo in pairs(mainTeam.pet_infos) do
      local pet = self.localPlayer:GetPetByGid(petInfo.pet_gid)
      if pet and pet.config.id == petID then
        return pet
      end
    end
  end
  return nil
end

function Pet_Ability_Slot_Manager:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self._rideAbilitySlot):IsPCMode()
end

function Pet_Ability_Slot_Manager:OnHideUI(hide)
  local visible = not hide and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Hidden
  self._onPetSlot:SetVisibility(visible)
  self._offPetSlot:SetVisibility(visible)
  self._offTempPetSlot:SetVisibility(visible)
  if hide and self._mainPet and self._mainPet:GetStatus() == ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_RIDE then
    self._rideAbilitySlot:SetVisibility(visible)
    self._rideJumpSlot:SetVisibility(visible)
  else
    self._rideAbilitySlot:SetVisible(UE4.ESlateVisibility.Visible)
    self._rideJumpSlot:SetVisible(UE4.ESlateVisibility.Visible)
  end
end

function Pet_Ability_Slot_Manager:GetOnPetBtnBlock(pet)
  if self._onPetSlot then
    return self._onPetSlot:GetBtnBlock(pet)
  end
  return false
end

return Pet_Ability_Slot_Manager
