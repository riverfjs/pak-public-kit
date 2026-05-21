local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneEnum = require("NewRoco.Modules.Core.Scene.Common.SceneEnum")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local NpcOptionEvent = require("NewRoco.Modules.Core.NPC.Executors.NpcOptionEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local PetHUDComponent = Base:Extend("PetHUDComponent")
local HardCatchDiff = _G.DataConfigManager:GetGlobalConfigByKeyType("hard_catch_difference", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
local ZeroCatchDiff = _G.DataConfigManager:GetGlobalConfigByKeyType("zero_catch_difference", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
local MessageConf = _G.DataConfigManager:GetNpcGlobalConfig("mark_magic_message_id", true)
local FakeMessageConf = _G.DataConfigManager:GetNpcGlobalConfig("mark_fake_magic_message_id", true)
local VideoConf = 55591
local FlowerConf = _G.DataConfigManager:GetNpcGlobalConfig("mark_energe_flower_id", true)
local GrassConf = _G.DataConfigManager:GetNpcGlobalConfig("mark_life_flower_id", true)
local nameColorBoundary = _G.DataConfigManager:GetPetGlobalConfig("pet_level_boundary").num
local petBondIconDistance
local LocalNpcNameType = Enum.NpcNameType
local ColorType = {
  None = 0,
  White = 1,
  Orange = 2,
  Red = 3
}
local IdentifyIdGen = 0
PetHUDComponent:SetMemberCount(16)

function PetHUDComponent:PreCtor()
  Base.PreCtor(self)
  self.isHudShow = true
  self.IdentifyId = 0
  self.currentPerceptionLevel = SceneEnum.PerceptionHudType.None
  self.futurePerceptionLevel = SceneEnum.PerceptionHudType.None
  self.d_UpdatePerception = nil
  self.isPerceptionHudVisible = false
  self.targetingNpc = nil
  self.pendingTargetNpcId = nil
  self._listenNpcCreation = false
  self.CachedName = ""
  self._NpcNameplateShowDistanceSqr = 0
  self.npcTitleIconShowDistanceSqr = 0
  self.homeNpcOutputShowDistanceSqr = 0
  self.homePetFeedableShowDis = 0
  self.bShouldShow = true
  self.colorType = ColorType.None
  self.HidePerceptionForBattle = false
  self.preVisible = false
  self.PetBondActiveFlag = 0
end

function PetHUDComponent:Attach(owner)
  Base.Attach(self, owner)
  self.config = self.owner.config
  self.serverData = self.owner.serverData
  self.IdentifyId = IdentifyIdGen
  IdentifyIdGen = IdentifyIdGen + 1
  self._NpcNameplateShowDistanceSqr = self.config.npc_nameplate_show_distance * self.config.npc_nameplate_show_distance
  self.npcTitleIconShowDistanceSqr = math.max(self.config.icon_show_distance * self.config.icon_show_distance, self._NpcNameplateShowDistanceSqr)
  local petFeedableShowDis = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_feed_distance") and _G.DataConfigManager:GetHomeGlobalConfig("home_pet_feed_distance").num or 200
  local homePetStatusShowDis = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_feed_cd_distance") and _G.DataConfigManager:GetHomeGlobalConfig("home_pet_feed_cd_distance").num or 300
  self.homePetFeedableShowDis = petFeedableShowDis * petFeedableShowDis
  self.homeNpcOutputShowDistanceSqr = homePetStatusShowDis * homePetStatusShowDis
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_DATA, self.OnPlayerDataChange)
  self.owner:AddEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  self.HidePerceptionForBattle = owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_FIGHTING) and true or false
  if self.config and self.config.show_name_type == LocalNpcNameType.NNT_INTERACTIVE then
    self:InitVisibleWithInteraction()
    self.owner:AddEventListener(self, NPCModuleEvent.OnInteractingChanged, self.OnInteractingChanged)
  end
  SceneUtils.RegisterNPCVisibilityNotify(self, true)
end

function PetHUDComponent:DeAttach()
  SceneUtils.UnregisterNPCVisibilityNotify(self)
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
  self:SetMainHudPerception(SceneEnum.PerceptionHudType.None, true)
  self.isPerceptionHudVisible = false
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player:SendEvent(PlayerModuleEvent.ON_PLAYER_LOST_PERCEPED_BY_NPC, self.IdentifyId)
  end
  if self.pendingTargetNpcId then
    self.pendingTargetNpcId = nil
  end
  self:SetListenNpcCreation(false)
  if self.PetBondOption then
    self.PetBondOption:RemoveEventListener(self, NpcOptionEvent.Destroy, self.OnPetBondOptionDestroy)
  end
  if self.config and self.config.show_name_type == LocalNpcNameType.NNT_INTERACTIVE then
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnInteractingChanged, self.OnInteractingChanged)
  end
end

function PetHUDComponent:OnSetViewObj()
  local config = self.config
  local viewObj = self.owner.viewObj
  if config and UE.UObject.IsValid(viewObj) then
    if config.show_name_type == Enum.NpcNameType.NNT_NONE and config.npc_nameplate_show_distance > 0 then
      viewObj:AddCustomTickDistance(config.npc_nameplate_show_distance)
    end
    if not string.IsNilOrEmpty(config.title_icon_path) and config.icon_show_distance > 0 then
      viewObj:AddCustomTickDistance(config.icon_show_distance)
    end
  end
end

function PetHUDComponent:UpdateData(ServerData, isReconnect)
  Base.UpdateData(self, ServerData, isReconnect)
  self.serverData = ServerData
  if isReconnect then
    local aiInfo = self.serverData.npc_base.is_server_ai and self.serverData.ai_info
    if not aiInfo then
      self:SetMainHudPerception(self.futurePerceptionLevel)
      return
    end
    local level = aiInfo.hud_type
    if 4 == level then
      local applied = self:SetPerceptionTargetingNpcById(aiInfo.hud_target_id)
      if not applied or 0 == aiInfo.hud_target_id then
        level = 1
      end
    else
      self:SetPerceptionTargetingNpcById(0)
    end
    self:SetMainHudPerception(level)
  end
end

function PetHUDComponent:EndTracking()
  self.bTrackedByTask = false
  if UE.UObject.IsValid(self._headHud) then
    self._headHud:ShowTrackingEnd()
  end
end

function PetHUDComponent:ShowHomeStatus(bShow, bInProduce, needTime, startTime)
  if not (self.serverData and self.serverData.home_pet) or self:IsShowingPerception() then
    return
  end
  if UE.UObject.IsValid(self._headHud) then
    self._headHud:ShowProduction(bShow, bInProduce, needTime, startTime, self.serverData.base.actor_id, self.serverData.home_pet.home_pet_info.pet_gid)
  end
end

function PetHUDComponent:UpdateHomeOutput(bInProduce, furnitureCoin)
  if self:IsShowingPerception() then
    return
  end
  if UE.UObject.IsValid(self._headHud) then
    self._headHud:UpdateHomeOutput(bInProduce, furnitureCoin)
  end
end

function PetHUDComponent:HighlightHomePetHud(bHighlight)
  if self:IsShowingPerception() then
    return
  end
  if UE.UObject.IsValid(self._headHud) then
    self._headHud:HighlightHomePetHud(bHighlight)
  end
end

function PetHUDComponent:HasNpcHud()
  local Result = self.owner.viewObj and (self.owner.viewObj.name == "BP_NPCCharacter_C" or self.owner.viewObj.name == "BP_PEO_Scene_C")
  return Result
end

function PetHUDComponent:IsPeopleNpcHud()
  return self.owner.viewObj and self.owner.viewObj.name == "BP_PEO_Scene_C"
end

function PetHUDComponent:SetTracked(bTracked)
  if self.bTrackedByTask == bTracked then
    return
  end
  self.bTrackedByTask = bTracked
  self:OnDistanceOptimize(0, 1, self.owner.squaredDis2Local, 1)
end

function PetHUDComponent:OnLevelChange(val)
  self.serverData.base.lv = val
  self:UpdateHudName(true)
end

function PetHUDComponent:OnAiControlFlagChanged(flags, previous)
  local OffsetBit = 1 << Enum.SceneAiControlFlags.SACF_HIDE_HUD_TEXT
  if (flags ~ previous) & OffsetBit > 0 and flags & OffsetBit > 0 then
    self:UpdateHudName(false)
  end
end

function PetHUDComponent:OnLogicStatusUpdated()
  local shouldHidePerception = self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_FIGHTING) and true or false
  if self.HidePerceptionForBattle ~= shouldHidePerception then
    self.HidePerceptionForBattle = shouldHidePerception
    if shouldHidePerception then
      self:SetMainHudPerception(SceneEnum.PerceptionHudType.None, true)
    end
  end
  if self.owner and UE.UObject.IsValid(self._headHud) then
    local bInFighting = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    self._headHud:SetFightingVisible(bInFighting)
    self:UpdateExpandStatus()
  end
end

function PetHUDComponent:UpdateExpandStatus()
  if not (self.owner and self._headHud) or not UE.UObject.IsValid(self._headHud) then
    return
  end
  if HomeIndoorSandbox and HomeIndoorSandbox:InLocalMasterIndoor() then
    local bExpanding = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_ROOM_EXPAND_ING)
    local bExpandFinish = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_ROOM_EXPAND_FINISH)
    self._headHud:SetRoomExpandStatus(bExpanding, bExpandFinish)
    self.bRoomExpanding = bExpanding
  else
    self.bRoomExpanding = false
    self._headHud:SetRoomExpandStatus(false, false)
  end
end

function PetHUDComponent:SetOwnerName(bVisible)
  if self.owner and UE.UObject.IsValid(self._headHud) then
    if bVisible and not self:IsShowingPerception() then
      if self.owner.serverData and self.owner.serverData.npc_base then
        local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        local playerId
        if localPlayer then
          playerId = localPlayer:GetServerId()
        end
        local mutationType = self.owner.serverData.npc_base.mutation_type
        local ownerId = self.owner.serverData.npc_base.create_avatar_id
        if ownerId and ownerId ~= playerId and UIUtils.CheckIsHighValuePet(self.owner) and not self.owner.serverData.is_magic_replay then
          local _, ownerName = UIUtils.GetHighValuePetTipsAndOwnerName(self.owner.serverData)
          self._headHud:SetOwnerName(ownerName)
        else
          self._headHud:SetOwnerName("")
        end
      end
    else
      self._headHud:SetOwnerName("")
    end
  end
end

function PetHUDComponent:OnFrameLoaded()
  self._headHud = nil
  local viewObj = self.owner.viewObj
  if UE.UObject.IsValid(viewObj) then
    local HeadWidget = viewObj.HeadWidget
    if UE.UObject.IsValid(HeadWidget) then
      self._headHud = HeadWidget:GetUserWidgetObject()
      HeadWidget.ConfigShowDistance = self.config.npc_nameplate_show_distance
      if not string.IsNilOrEmpty(self.config.title_icon_path) then
        HeadWidget.FarDisAppearDis = 4000
      end
      self.owner:SendEvent(NPCModuleEvent.OnCharacterHUDLoaded)
    end
  end
  self:SetOwnerName(true)
  self:UpdateHudName(false)
  self:UpdateNPCNameColor()
  if self.config.show_name_type ~= Enum.NpcNameType.NNT_NONE then
    self:SetNameVisible(false)
  end
  self:UpdateTitleInfo()
  self:UpdateExpandStatus()
  self.frameLoaded = true
  self.isHudVisible = nil
end

function PetHUDComponent:GetRelativeHeight()
  local HudScaleOffset = 0
  if self:IsPeopleNpcHud() then
    return HudScaleOffset
  elseif self.owner.viewObj and self.owner.viewObj.HeadWidget and self.owner.bShowAimedLv then
    HudScaleOffset = self.owner.viewObj.HeadWidget.RelativeScale3D.Z * 60 + 30
  end
  return HudScaleOffset
end

function PetHUDComponent:RestoreHeadWidgetLocation()
  local View = self.owner.viewObj
  UE.UNRCCharacterUtils.RestoreHeadWidgetTransform(View)
end

function PetHUDComponent:SetHeadWidgetTransform(NewTrans, bKeepScale, bAddToDefault)
  local View = self.owner.viewObj
  UE.UNRCCharacterUtils.SetHeadWidgetTransform(View, NewTrans, bKeepScale, bAddToDefault)
end

function PetHUDComponent:UpdateHudName(needUpdateColor)
  local name = self:GetShowName()
  if name then
    self:SetHudName(name, needUpdateColor)
  end
end

function PetHUDComponent:SetHudName(name, needUpdateColor)
  if UE.UObject.IsValid(self._headHud) and self.CachedName ~= name then
    self._headHud:SetName(name)
    self.CachedName = name
  end
  if needUpdateColor then
    self:UpdateNPCNameColor()
  end
end

function PetHUDComponent:ForceUpdate()
  if not self.owner.viewObj then
    self.frameLoaded = false
    return
  end
  if not self.frameLoaded then
    self:OnFrameLoaded()
  end
  self.owner:CalSquaredDis2Local()
  self:OnDistanceOptimize(0, 1, self.owner.squaredDis2Local, 1)
end

function PetHUDComponent:OnDistanceOptimize(distanceIgnoreZ, viewDotValue, distance, distanceRatio)
  if _G.HUDComponentDisabled then
    if UE.UObject.IsValid(self._headHud) then
      self._headHud:SetVisible(false)
    end
    return
  end
  if not self.frameLoaded then
    return
  end
  local View = self.owner.viewObj
  if not View then
    return
  end
  local isShowHud = self.isHudShow
  if isShowHud then
    if self.config.show_name_type == LocalNpcNameType.NNT_HIDE then
      isShowHud = false
    elseif distance > self._NpcNameplateShowDistanceSqr and not self.owner.isAimed then
      isShowHud = false
    else
      isShowHud = true
    end
    if BattleManager.isInBattle then
      isShowHud = false
    end
  end
  isShowHud = isShowHud and self.bShouldShow and (not self.bTrackedByTask or not not self.owner.bShowAimedLv)
  local farmNPCType = self.owner:GetFarmNPCType()
  if farmNPCType == FarmModuleEnum.NPCType.Land then
    local standingLandId = _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetCurrentStandingLandId)
    isShowHud = isShowHud and standingLandId ~= self.owner.luaObj.landId
    local op = FarmUtils.GetLandOptionStatus(self.owner.luaObj.landId)
    if isShowHud then
      isShowHud = op ~= FarmModuleEnum.OptionType.Sowing and op ~= FarmModuleEnum.OptionType.None
    end
  elseif farmNPCType == FarmModuleEnum.NPCType.Board and isShowHud then
    isShowHud = SceneUtils.IsLogicStatusPlantUnlockLand(self.owner)
  end
  if self.isHudVisible == isShowHud then
    if isShowHud and self.owner.bShowAimedLv then
      self:SetNameVisible(true)
    end
    if self.isHudVisible and self.config.id ~= 55561 and self.config.id ~= 55591 then
      self:UpdateHudName(false)
    end
    if self:IsShowingPerception() then
      self:SetOwnerName(false)
    else
      self:SetOwnerName(true)
    end
  else
    self.isHudVisible = isShowHud
    if isShowHud then
      self:UpdateHudName(true)
    end
    if farmNPCType == FarmModuleEnum.NPCType.None then
      self:SetNameVisible(isShowHud)
      if self.bRoomExpanding then
        self:UpdateExpandStatus()
      end
    else
      self:SetNameVisible(isShowHud and self.config.show_name)
      if farmNPCType == FarmModuleEnum.NPCType.Entrance then
        self:SetPlantStatusVisible(isShowHud, farmNPCType)
      elseif farmNPCType == FarmModuleEnum.NPCType.Land then
        local landId = self.owner:GetFarmLandNpcId()
        self:SetPlantStatusVisible(isShowHud, farmNPCType, landId)
      elseif farmNPCType == FarmModuleEnum.NPCType.Board then
        self:SetPlantStatusVisible(isShowHud, farmNPCType, SceneUtils.IsLogicStatusPlantUnlockLand(self.owner))
      end
    end
    local widgetComp = self.owner.viewObj.HeadWidget
    if UE4.UObject.IsValid(widgetComp) then
      if self.isHudVisible or self:IsShowingPerception() or farmNPCType == FarmModuleEnum.NPCType.Land then
        widgetComp.bFacePlayer = true
      else
        widgetComp.bFacePlayer = false
      end
      if UE.UObject.IsValid(self._headHud) and not self._headHud:IsShowPerceptionHead() then
        self._headHud:SetVisible(isShowHud)
      end
    end
  end
  if self.hasTitleInfo and UE.UObject.IsValid(self._headHud) then
    local titleVisible = distance < self.npcTitleIconShowDistanceSqr and not self.bTrackedByTask and self.isHudShow
    self._headHud:SetTitleVisible(titleVisible)
    local widgetComp = self.owner.viewObj.HeadWidget
    if UE4.UObject.IsValid(widgetComp) then
      widgetComp.bFacePlayer = titleVisible or self.isHudVisible
    end
  end
  if self.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME and UE.UObject.IsValid(self._headHud) and self.owner.HomePetFeedStatusComponent then
    local bInProduce, needTime, startTime, outputInfo, bagItemId = self.owner.HomePetFeedStatusComponent:UpdateFeedInfo()
    local statusVisible = (bInProduce and distance < self.homeNpcOutputShowDistanceSqr or not bInProduce and distance < self.homePetFeedableShowDis) and not self:IsShowingPerception()
    self._headHud:ShowProduction(statusVisible, bInProduce, needTime, startTime, self.serverData.base.actor_id, self.serverData.home_pet.home_pet_info.pet_gid, outputInfo, bagItemId)
  end
  if MessageConf then
    local messageId = MessageConf.num
    if self.config.id == messageId then
      self:CheckShowTrace(distance)
    end
  end
  if FakeMessageConf then
    local FakeMessageId = FakeMessageConf.num
    if self.config.id == FakeMessageId then
      self:CheckShowTrace(distance)
    end
  end
  if VideoConf then
    local VideoId = VideoConf
    if self.config.id == VideoId then
      self:CheckShowTrace(distance)
    end
  end
  local FlowerId, GrassId
  if FlowerConf then
    FlowerId = FlowerConf.num
  end
  if GrassConf then
    GrassId = GrassConf.num
  end
  if (self.config.id == FlowerId or self.config.id == GrassId) and UE.UObject.IsValid(self._headHud) then
    local statusVisible = distance < self._NpcNameplateShowDistanceSqr
    if self.preVisible ~= statusVisible and self.owner.viewObj.HeadWidget then
      self._headHud:SetTraceNameVisible(statusVisible)
      self._headHud:ShowTopMessage(statusVisible, self.owner)
      self.preVisible = statusVisible
    end
  end
  if nil == petBondIconDistance then
    local petBondIconDistanceConf = _G.DataConfigManager:GetNpcGlobalConfig("pet_bond_icon_distance")
    petBondIconDistance = petBondIconDistanceConf and petBondIconDistanceConf.num or 4000
    petBondIconDistance = petBondIconDistance * petBondIconDistance
  end
  if self.isHudVisible and distance < petBondIconDistance then
    local interactionComponent = self.owner and self.owner.InteractionComponent
    self.PetBondOption = interactionComponent and interactionComponent:GetValidPetBondOption()
    self:SetPetBondVisible(self.PetBondOption and true or false)
    if self.PetBondOption and not self.PetBondOption:HasListener(self, NpcOptionEvent.Destroy, self.OnPetBondOptionDestroy) then
      self.PetBondOption:AddEventListener(self, NpcOptionEvent.Destroy, self.OnPetBondOptionDestroy)
    end
  else
    self:SetPetBondVisible(false)
  end
end

function PetHUDComponent:OnPetBondOptionDestroy()
  if self.PetBondOption then
    self.PetBondOption:RemoveEventListener(self, NpcOptionEvent.Destroy, self.OnPetBondOptionDestroy)
    self.PetBondOption = nil
  end
  self:SetPetBondVisible(false)
end

function PetHUDComponent:CheckShowTrace(distance)
  if UE.UObject.IsValid(self._headHud) then
    local statusVisible = distance < self._NpcNameplateShowDistanceSqr
    if self.preVisible ~= statusVisible then
      self._headHud:SetMagicMessageVisible(true)
      self._headHud:ShowTopMessage(statusVisible, self.owner)
      self.preVisible = statusVisible
    end
  end
end

function PetHUDComponent:SetVisible(enable)
  if _G.HUDComponentDisabled then
    return
  end
  self.bShouldShow = enable
  self:ForceUpdate()
end

function PetHUDComponent:SetRenderStatus(enable, opSource)
  local viewObj = self.owner.viewObj
  if UE.UObject.IsValid(viewObj) then
    local HeadWidget = viewObj.HeadWidget
    if UE.UObject.IsValid(HeadWidget) then
      HeadWidget:SetRenderStatus(enable, opSource)
    end
  end
end

function PetHUDComponent:OnVisible()
  if not self.isPerceptionHudVisible then
    self:SetMainHudPerception(self.futurePerceptionLevel)
    self.isPerceptionHudVisible = true
  end
  if self.owner and UE.UObject.IsValid(self._headHud) then
    local bInFighting = self.owner:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
    self._headHud:SetFightingVisible(bInFighting)
  end
end

function PetHUDComponent:OnInvisible()
  if self.isPerceptionHudVisible then
    self:SetMainHudPerception(SceneEnum.PerceptionHudType.None, true)
    self.isPerceptionHudVisible = false
  end
end

function PetHUDComponent:OnPlayerDataChange()
  if self.isHudVisible then
    self:UpdateNPCNameColor()
  end
end

function PetHUDComponent:Destroy()
  local playerDataModel = _G.DataModelMgr.PlayerDataModel
  if playerDataModel then
    playerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_DATA, self.OnPlayerDataChange)
  end
  self._headHud = nil
  if self.owner and UE4.UObject.IsValid(self.owner.viewObj) then
    local HeadWidget = self.owner.viewObj.HeadWidget
    if UE.UObject.IsValid(HeadWidget) then
      local hud = HeadWidget:GetWidget()
      if UE.UObject.IsValid(hud) then
        _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ReturnHudToPool, "UMG_Hud_Pet", hud)
        HeadWidget:SetWidget(nil)
      end
    end
  end
end

function PetHUDComponent:UpdateNPCNameColor()
  if not UE.UObject.IsValid(self._headHud) then
    return
  end
  if not self.serverData then
    return
  end
  if not self.owner.config then
    return
  end
  if self.owner.serverData.MagicFeedInfo then
    return
  end
  local fColor
  local colorType = ColorType.None
  local subLevel = 0
  local worldLevel = (_G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel() or 0) + 1
  if not _G.DataConfigManager:GetWorldLevelConf(worldLevel) then
    return
  end
  local pet_level_limit = _G.DataConfigManager:GetWorldLevelConf(worldLevel).pet_level_limit
  if self.serverData.base.lv then
    subLevel = self.serverData.base.lv - pet_level_limit
    if subLevel > nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#c12a2a")
      colorType = ColorType.Red
    elseif subLevel > 0 and subLevel <= nameColorBoundary then
      fColor = UE4.UNRCStatics.HexToSlateColor("#e77d00")
      colorType = ColorType.Orange
    else
      fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
      colorType = ColorType.White
    end
    if self:CheckDungeonPetMimic() then
      fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
      colorType = ColorType.White
    end
    if self.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME then
      fColor = UE4.UNRCStatics.HexToSlateColor("#ffffff")
      colorType = ColorType.White
    end
    if colorType ~= self.colorType then
      self._headHud:SetNameColor(fColor)
      self.colorType = colorType
    end
  end
end

function PetHUDComponent:UpdateTitleInfo()
  if not UE.UObject.IsValid(self._headHud) then
    return
  end
  if not self.config then
    return
  end
  if not string.IsNilOrEmpty(self.config.npc_worldtitle) or not string.IsNilOrEmpty(self.config.title_icon_path) then
    self.hasTitleInfo = true
    self._headHud:SetTitleInfo(self.config.npc_worldtitle, self.config.title_icon_path)
  end
end

function PetHUDComponent:GetShowName()
  local name = ""
  if self.config.npc_role_type ~= Enum.PetRoleTypeInNPCConf.PRTINC_HOME then
    if self.config.show_name and self.config.show_name > 0 then
      if self.serverData.MagicFeedInfo and self.serverData.MagicFeedInfo.name then
        name = self.serverData.MagicFeedInfo.name
        return name
      else
        local PetInfo = self.owner.serverData and self.owner.serverData.pet_info
        if PetInfo and 0 ~= PetInfo.gid then
          name = self.owner.serverData.base.name
        end
        if string.IsNilOrEmpty(name) then
          if self.sceneConf then
            name = self.sceneConf.name or self.config.name
          else
            name = self.config.name
          end
        end
      end
    end
  elseif self.serverData.home_pet and self.serverData.base and self.serverData.base.name then
    name = self.serverData.base.name
  end
  if name and (1 == self.config.show_level or 0 == self.config.show_level and self.owner.bShowAimedLv or self.owner.config and self.owner.config.throwing_interact_type == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET and self.colorType == ColorType.Orange or self.colorType == ColorType.Red) and self.serverData and not self:ShouldHideHud() then
    return string.format(LuaText.pethudcomponent_1, name, self.serverData.base.lv)
  end
  return name
end

function PetHUDComponent:ShouldHideHud()
  local hiddenComp = self.owner.HiddenComponent
  if hiddenComp and hiddenComp:IsHidden() then
    return true
  end
  local AIComp = self.owner.AIComponent
  if AIComp and AIComp:HasControlFlags(Enum.SceneAiControlFlags.SACF_HIDE_HUD_TEXT) then
    return true
  end
  return false
end

function PetHUDComponent:SetNameVisible(visible)
  if UE.UObject.IsValid(self._headHud) and self._headHud.SetNameVisible then
    self._headHud:SetNameVisible(visible)
  end
end

function PetHUDComponent:SetFocusVisible(visible)
  if UE.UObject.IsValid(self._headHud) and self._headHud.SetFocusVisible then
    self._headHud:SetFocusVisible(visible)
  end
end

function PetHUDComponent:ShowLockInfo(visible)
end

function PetHUDComponent:ShowAutoLockInfo(visible)
  if UE.UObject.IsValid(self._headHud) and self._headHud.ShowAutoLockIcon then
    self._headHud:ShowAutoLockIcon(false)
  end
end

function PetHUDComponent:ShowPetTypeIcon(petBaseConf, visible)
  if UE.UObject.IsValid(self._headHud) and self._headHud.ShowCatchPetType and petBaseConf then
    self._headHud:ShowCatchPetType(petBaseConf, visible)
  end
end

function PetHUDComponent:AddDebugInfo(key, value)
  if not UE4.UNRCStatics.IsEditor() then
    return
  end
  if self.owner and UE4.UObject.IsValid(self.owner.viewObj) then
    local HeadWidget = self.owner.viewObj.HeadWidget
    if UE.UObject.IsValid(HeadWidget) then
      HeadWidget:SetDebugData(key, value)
    end
  end
end

function PetHUDComponent:IsShowingPerception()
  if self.currentPerceptionLevel == SceneEnum.PerceptionHudType.Lose or self.currentPerceptionLevel == SceneEnum.PerceptionHudType.None then
    return false
  else
    return true
  end
end

function PetHUDComponent:GetCurrentHudPerception()
  return self.currentPerceptionLevel
end

function PetHUDComponent:SetMainHudPerception(level, imme)
  if self.futurePerceptionLevel == level and not imme then
    return
  end
  self.futurePerceptionLevel = level
  if self.HidePerceptionForBattle then
    self.futurePerceptionLevel = SceneEnum.PerceptionHudType.None
  end
  if not self.isPerceptionHudVisible then
    return
  end
  if self.d_UpdatePerception then
    _G.DelayManager:CancelDelayById(self.d_UpdatePerception)
  end
  if imme then
    self:ApplyCurrentPerception()
  else
    self.d_UpdatePerception = _G.DelayManager:DelaySeconds(0.3, self.ApplyCurrentPerception, self)
  end
end

function PetHUDComponent:ApplyCurrentPerception()
  local oldLevel = self.currentPerceptionLevel
  local newLevel = self.futurePerceptionLevel
  if oldLevel == newLevel then
    return
  end
  Log.DebugFunc(function()
    return string.format("[PetHUDComponent]ApplyCurrentPerception: %s, %s", table.getKeyName(SceneEnum.PerceptionHudType, newLevel), self.owner:DebugNPCNameAndID())
  end)
  self:ApplyPerceptionToMainHud(newLevel)
  self:ApplyPerceptionToHeadHud(newLevel)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    local bPlayerInteract = newLevel == SceneEnum.PerceptionHudType.TackAction or newLevel == SceneEnum.PerceptionHudType.HardAction
    if bPlayerInteract then
      Player:SendEvent(PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.IdentifyId)
    else
      Player:SendEvent(PlayerModuleEvent.ON_PLAYER_LOST_PERCEPED_BY_NPC, self.IdentifyId)
    end
  end
  self.currentPerceptionLevel = newLevel
  self.d_UpdatePerception = nil
end

function PetHUDComponent:UpdateAcceptTaskHUD(TaskID, bVisible)
  if UE.UObject.IsValid(self._headHud) and self._headHud.ShowTrackIcon and self._headHud.bTrackVisible ~= bVisible then
    self._headHud:ShowTrackIcon(TaskID, bVisible)
  end
end

function PetHUDComponent:ApplyPerceptionToMainHud(Type)
  local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if MainUIModule then
    local valid, num = MainUIModule:HasPanel("LobbyMain")
    if valid then
      local panel = MainUIModule:GetPanel("LobbyMain")
      if Type == SceneEnum.PerceptionHudType.Perceive or Type == SceneEnum.PerceptionHudType.GroupTarget then
        panel.UMG_Hud_PerceptionPanel:PerceivePlayer(self.owner)
      elseif Type == SceneEnum.PerceptionHudType.TackAction then
        panel.UMG_Hud_PerceptionPanel:TackActionToPlayer(self.owner)
      elseif Type == SceneEnum.PerceptionHudType.HardAction then
        panel.UMG_Hud_PerceptionPanel:HardActionToPlayer(self.owner)
      elseif Type == SceneEnum.PerceptionHudType.Lose or Type == SceneEnum.PerceptionHudType.None then
        panel.UMG_Hud_PerceptionPanel:LosePlayer(self.owner)
      end
    end
  end
end

function PetHUDComponent:ApplyPerceptionToHeadHud(Type)
  if UE.UObject.IsValid(self._headHud) and self.owner then
    if Type ~= SceneEnum.PerceptionHudType.None and Type ~= SceneEnum.PerceptionHudType.Lose then
      local widgetComp = self.owner.viewObj.HeadWidget
      if widgetComp then
        widgetComp:ForceUpdateScale()
        widgetComp.bFacePlayer = true
      end
      self._headHud:SetVisible(true)
    end
    self._headHud:ShowPerceptionHead(self.owner, Type, self.targetingNpc)
    if self._headHud:IsShowPerceptionHead() then
      self:SetPetBondVisible(false)
    elseif self.PetBondOption then
      self:SetPetBondVisible(true)
    end
  end
end

function PetHUDComponent:SetPerceptionTargetingNpcById(ServerId)
  if 0 == ServerId or nil == ServerId then
    if self.pendingTargetNpcId then
      self.pendingTargetNpcId = nil
    end
    self:SetListenNpcCreation(false)
    return false
  end
  local npc = self.owner.module:GetNpcByServerID(ServerId)
  if npc then
    self:SetPerceptionTargetingNpc(npc)
    return true
  else
    self.pendingTargetNpcId = ServerId
    self:SetListenNpcCreation(true)
    return false
  end
end

function PetHUDComponent:SetListenNpcCreation(enable)
  if self._listenNpcCreation ~= enable then
    if enable then
      _G.NRCEventCenter:RegisterEvent("PetHudComponent.instance", self, NPCModuleEvent.On_NPC_Create, self.OnTargetingNpcEnter)
    else
      _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_Create, self.OnTargetingNpcEnter)
    end
    self._listenNpcCreation = enable
  end
end

function PetHUDComponent:OnTargetingNpcEnter(npc)
  if self.pendingTargetNpcId and npc:GetServerId() == self.pendingTargetNpcId then
    self:SetListenNpcCreation(false)
    self:SetPerceptionTargetingNpc(npc)
    self:SetMainHudPerception(SceneEnum.PerceptionHudType.GroupTarget)
  end
end

function PetHUDComponent:OnTargetingNpcLeave()
  self.targetingNpc = nil
  self:ApplyPerceptionToHeadHud(self.currentPerceptionLevel)
  if self.pendingTargetNpcId then
    self:SetListenNpcCreation(true)
  end
end

function PetHUDComponent:SetPerceptionTargetingNpc(npc)
  if self.targetingNpc == npc then
    return
  end
  if self.targetingNpc then
    self.targetingNpc:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnTargetingNpcLeave)
  end
  if npc then
    npc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnTargetingNpcLeave)
  end
  self.targetingNpc = npc
  self:ApplyPerceptionToHeadHud(self.currentPerceptionLevel)
end

function PetHUDComponent:ChangePerceptionKey(value)
  if self.ShowPerceptionKey ~= value then
    self.ShowPerceptionKey = value
    if UE.UObject.IsValid(self._headHud) and self.owner and self._headHud:IsShowPerceptionHead() then
      local PerceptionUI = self._headHud:GetSubPanel("UMG_Hud_Perception")
      if PerceptionUI then
        PerceptionUI:CheckCollision()
      end
    end
  end
end

function PetHUDComponent:HasPerceptionTargetingNpc()
  return self.targetingNpc
end

function PetHUDComponent:SetPlantStatusVisible(visible, ...)
  if UE.UObject.IsValid(self._headHud) and self._headHud.SetPlantStatusVisible then
    self._headHud:SetPlantStatusVisible(visible, ...)
  end
end

function PetHUDComponent:OnRefreshFarmNpcStatus(...)
  if UE.UObject.IsValid(self._headHud) and self._headHud.OnRefreshFarmNpcStatus then
    self._headHud:OnRefreshFarmNpcStatus(...)
  end
end

function PetHUDComponent:SetPetBondVisible(bIsVisible)
  if not UE.UObject.IsValid(self._headHud) then
    return
  end
  if bIsVisible and self._headHud:IsShowPerceptionHead() then
    return
  end
  self._headHud:SetVeryIntimateVisible(bIsVisible, 0 ~= self.PetBondActiveFlag)
end

function PetHUDComponent:SetPetBondActive(bIsActive, Reason)
  Reason = Reason or 0
  if bIsActive then
    self.PetBondActiveFlag = self.PetBondActiveFlag | 1 << Reason
  else
    self.PetBondActiveFlag = self.PetBondActiveFlag & ~(1 << Reason)
  end
  if UE.UObject.IsValid(self._headHud) then
    self._headHud:SetPetBondActive(0 ~= self.PetBondActiveFlag)
  end
end

function PetHUDComponent:CheckDungeonPetMimic()
  local bInDungeon = _G.DataModelMgr.PlayerDataModel:IsInDungeon()
  local bMimic = self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_MIMIC) or self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_MIMIC_OPTION)
  return bInDungeon and bMimic
end

function PetHUDComponent:InitVisibleWithInteraction()
  self.isHudShow = self.owner.InteractionComponent:HasAnyInteractingOption()
  if not self.isHudShow then
    Log.Debug("PetHUDComponent: SetHudHide By Interaction")
  end
end

function PetHUDComponent:OnInteractingChanged(HasAnyInteractingOption)
  self.isHudShow = HasAnyInteractingOption
  if not self.isHudShow then
    Log.Debug("PetHUDComponent: SetHudHide By Interaction")
  end
end

return PetHUDComponent
