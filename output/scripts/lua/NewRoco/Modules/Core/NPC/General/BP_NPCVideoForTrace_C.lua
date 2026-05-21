local MagicReplayUtils = require("NewRoco.Modules.System.MagicReplay.MagicReplayUtils")
local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
require("UnLuaEx")
local PetHUDComponent = require("NewRoco.Modules.Core.Scene.Component.HUD.PetHUDComponent")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local VideoEnum = ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO
local path = "Blueprint'/Game/NewRoco/Modules/Core/NPC/General/BP_NPCCommonVideo.BP_NPCCommonVideo'"
local BP_NPCVideoForTrace_C = Base:Extend("BP_NPCVideoForTrace_C")

function BP_NPCVideoForTrace_C:Init()
  Base.Init(self)
  self.range_warning_conf = _G.DataConfigManager:GetGlobalConfig("mark_video_rec_alarm_range")
  self.range_error_conf = _G.DataConfigManager:GetGlobalConfig("mark_video_rec_range")
end

function BP_NPCVideoForTrace_C:SetSceneCharacter(sceneCharacter)
  Base.SetSceneCharacter(self, sceneCharacter)
  if not sceneCharacter then
    return
  end
  local FeedInfo = sceneCharacter.serverData.MagicFeedInfo
  if FeedInfo then
    if FeedInfo.sub_type then
      local config = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
      local wand_id
      for _, value in pairs(config) do
        if value.child_type == FeedInfo.sub_type then
          wand_id = value.wand_id
          break
        end
      end
      if wand_id then
        local wandConf = _G.DataConfigManager:GetFashionWandConf(wand_id, true)
        if wandConf then
          local magicId = wandConf.magic_list[VideoEnum]
          local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
          local AvatarConfig = avatarSystem:GetAvatarConfig()
          local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, VideoEnum)
          local wandData = UE4.FAvatarWandInfo_Video()
          UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(VideoEnum), RowKey, wandData)
          local magicConfig = wandData.VideoMagicResource
          if magicConfig then
            path = UE4.UNRCStatics.GetSoftObjPath(magicConfig.VideoItem)
          end
          sceneCharacter.viewObj.NRCChildActor:SetPath(path)
        end
      end
    end
  else
    local wandData = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO, true)
    if wandData then
      path = UE4.UNRCStatics.GetSoftObjPath(wandData.VideoItem)
    end
    sceneCharacter.viewObj.NRCChildActor:SetPath(path)
  end
  _G.NRCEventCenter:RegisterEvent("BP_NPCVideoForTrace_C", self, SceneEvent.LoadMapStart, self.LoadMapStart)
end

function BP_NPCVideoForTrace_C:LoadMapStart()
  self.sceneCharacter:OnPlayerTeleportStart()
end

function BP_NPCVideoForTrace_C:Recycle()
  self:DeactivateMagicReplayCheck()
  Base.Recycle(self)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.LoadMapStart)
end

function BP_NPCVideoForTrace_C:OnLeaveBattle()
  Base.OnLeaveBattle(self)
  local npc = self.sceneCharacter
  if not npc then
    return
  end
  local hudComp = npc:EnsureComponent(PetHUDComponent)
  local Hud = hudComp._headHud
  if not Hud then
    return
  end
  Hud:ShowTopMessage(true, npc)
end

function BP_NPCVideoForTrace_C:OnVisible()
  Base.OnVisible(self)
  self.Child = self.NRCChildActor:GetChildActor()
end

function BP_NPCVideoForTrace_C:SetPosition(InitPosition, SelectPosition)
  self.InitialPosition = InitPosition
  self.SelectPosition = SelectPosition
  if not self.Child then
    self.Child = self.NRCChildActor:GetChildActor()
  end
  self.Child.InitialPosition = InitPosition
  self.Child.SelectPosition = SelectPosition
end

function BP_NPCVideoForTrace_C:SetTopMessageVisible()
  local npc = self.sceneCharacter
  if npc then
    local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
    if not hudClass then
      Log.Error("BP_NPCVideoForTrace_C:SetTopMessageVisible _G.NRCBigWorldPreloader:Get(PET_HUD) First Failed")
      hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
      if not hudClass then
        Log.Error("BP_NPCVideoForTrace_C:SetTopMessageVisible _G.NRCBigWorldPreloader:Get(PET_HUD) Second Failed")
        return
      end
      return
    end
    local hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
    if not hud then
      Log.Error("BP_NPCVideoForTrace_C:SetTopMessageVisible Create hud First Failed")
      hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
      if not hud then
        Log.Error("BP_NPCVideoForTrace_C:SetTopMessageVisible Create hud Second Failed")
        return
      end
    end
    self.HeadWidget:SetWidget(hud)
    hud:SetParentHUD(self.HeadWidget)
    self.hudComp = npc:EnsureComponent(PetHUDComponent)
    if self.hudComp then
      self.hudComp:OnSetViewObj()
      self.hudComp:ForceUpdate()
    end
  end
end

function BP_NPCVideoForTrace_C:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
end

function BP_NPCVideoForTrace_C:ActivateMagicReplayCheck()
  Log.Debug("BP_NPCVideoForTrace_C:ActivateMagicReplayCheck", self.isActivateRangeCheck)
  if not self.isActivateRangeCheck then
    self.isActivateRangeCheck = true
    self.lastWarningState = false
    UpdateManager:Register(self)
  end
end

function BP_NPCVideoForTrace_C:DeactivateMagicReplayCheck()
  Log.Debug("BP_NPCVideoForTrace_C:DeactivateMagicReplayCheck", self.isActivateRangeCheck)
  if self.isActivateRangeCheck then
    self.isActivateRangeCheck = false
    UpdateManager:UnRegister(self)
  end
end

function BP_NPCVideoForTrace_C:OnTick(deltaTime)
  self:CheckMagicReplayRange()
end

function BP_NPCVideoForTrace_C:CheckMagicReplayRange()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local pos = player:GetActorLocation()
  local npcPos = self:Abs_K2_GetActorLocation()
  if MagicReplayUtils.IsOpActivated(MagicReplayModuleEnum.ModuleOpType.Replay) then
    if not self.lastWarningState and self:IsOutOfCheckRange(pos, npcPos, self.range_warning_conf) then
      self.lastWarningState = true
      local msg = _G.LuaText.mark_video_watch_quit_alarm
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, msg)
    elseif self.lastWarningState and not self:IsOutOfCheckRange(pos, npcPos, self.range_warning_conf) then
      self.lastWarningState = false
    end
  end
  if self:IsOutOfCheckRange(pos, npcPos, self.range_error_conf) then
    self:DeactivateMagicReplayCheck()
    _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.LeaveMagicReplayArea)
  end
end

function BP_NPCVideoForTrace_C:IsOutOfCheckRange(pos1, pos2, range_conf)
  local checkHeight = range_conf.numList[2] * 100
  if checkHeight < math.abs(pos1.Z - pos2.Z) then
    return true
  end
  local checkRadius = range_conf.numList[1] * 100
  if (pos1.X - pos2.X) ^ 2 + (pos1.Y - pos2.Y) ^ 2 > checkRadius ^ 2 then
    return true
  end
  return false
end

function BP_NPCVideoForTrace_C:IsRecTarget(npc_id)
  if not (self.sceneCharacter and self.sceneCharacter.serverData) or not self.sceneCharacter.serverData.base then
    return false
  end
  if self.sceneCharacter.serverData.base.actor_id == npc_id then
    return true
  end
  return false
end

function BP_NPCVideoForTrace_C:PlaySeqTargetEmergeEffect(targetView, isPlayer, isRidePet, isChangeSuit)
  local FeedInfo = self.sceneCharacter.serverData.MagicFeedInfo
  local magicConfig
  if FeedInfo then
    if FeedInfo.sub_type then
      local config = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
      local wand_id
      for _, value in pairs(config) do
        if value.child_type == FeedInfo.sub_type then
          wand_id = value.wand_id
          break
        end
      end
      if wand_id then
        local wandConf = _G.DataConfigManager:GetFashionWandConf(wand_id, true)
        if wandConf then
          local magicId = wandConf.magic_list[VideoEnum]
          local avatarSystem = UE4.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE4.UAvatarSubsystem)
          local AvatarConfig = avatarSystem:GetAvatarConfig()
          local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magicId, VideoEnum)
          local wandData = UE4.FAvatarWandInfo_Video()
          UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(VideoEnum), RowKey, wandData)
          magicConfig = wandData.VideoMagicResource
        end
      end
    end
  else
    magicConfig = MagicMessageUtils.GetAvatarWandConfig(ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO)
  end
  local SkillPath
  if isPlayer then
    if isChangeSuit then
      SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Suit"
      if magicConfig then
        SkillPath = UE4.UNRCStatics.GetSoftObjPath(magicConfig.SuitAppear)
      end
    else
      SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Charactor"
      if magicConfig then
        SkillPath = UE4.UNRCStatics.GetSoftObjPath(magicConfig.CharacterAppear)
      end
    end
  elseif isRidePet then
    SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Ride"
    if magicConfig then
      SkillPath = UE4.UNRCStatics.GetSoftObjPath(magicConfig.RideAppear)
    end
  else
    SkillPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/MovieMagic/G6_Scene_MovieMagic_Pet"
    if magicConfig then
      SkillPath = UE4.UNRCStatics.GetSoftObjPath(magicConfig.PetAppear)
    end
  end
  if not self.RocoSkill then
    Log.Error("BP_NPCVideoForTrace_C:PlayReplayEffect self.RocoSkill is nil")
  end
  local skill
  local ChildActor = self.NRCChildActor:GetChildActor()
  if isPlayer then
    skill = RocoSkillProxy.Create(SkillPath, self.RocoSkill)
    skill:SetCaster(ChildActor)
    skill:SetTargets({targetView})
    skill:SetForcePlayPassive(true)
  else
    if isRidePet then
      skill = RocoSkillProxy.Create(SkillPath, self.RocoSkill)
    else
      skill = RocoSkillProxy.Create(SkillPath, targetView.RocoSkill)
    end
    skill:SetCaster(targetView)
    skill:SetTargets({ChildActor})
  end
  skill:SetPassive(true)
  skill:SetWithLoadAndPlay(true)
  skill:RegisterEventCallback("PreEnd", self, self.OnEmergeEffectSkillComplete)
  skill:RegisterEventCallback("End", self, self.OnEmergeEffectSkillComplete)
  skill:RegisterEventCallback("Interrupt", self, self.OnEmergeEffectSkillComplete)
  skill:RegisterEventCallback("ShowPlayer", self, self.OnEmergeEffectShowPlayer)
  skill:RegisterEventCallback("ShowPet", self, self.OnEmergeEffectShowPet)
  skill:PlaySkill(self, self.OnEmergeEffectSkillStart)
end

function BP_NPCVideoForTrace_C:OnEmergeEffectSkillStart(Skill, Result)
  Log.Debug("BP_NPCVideoForTrace_C:OnEmergeEffectSkillStart", Result)
  if Result ~= UE.ESkillStartResult.Success then
    self:OnEmergeEffectSkillComplete()
  end
end

function BP_NPCVideoForTrace_C:OnEmergeEffectSkillComplete()
end

function BP_NPCVideoForTrace_C:OnEmergeEffectShowPlayer(eventName, skill)
  if skill and skill.DynamicData and skill.DynamicData.Targets[1] and UE.UObject.IsValid(skill.DynamicData.Targets[1]) then
    skill.DynamicData.Targets[1]:SetHiddenMask(false, UE4.EPlayerForceHiddenType.MagicReplay)
  end
end

function BP_NPCVideoForTrace_C:OnEmergeEffectShowPet(eventName, skill)
  if skill and skill.DynamicData and skill.DynamicData.Caster and UE.UObject.IsValid(skill.DynamicData.Caster) then
    skill.DynamicData.Caster:SetHiddenMask(false, UE4.EPlayerForceHiddenType.MagicReplay)
  end
end

return BP_NPCVideoForTrace_C
