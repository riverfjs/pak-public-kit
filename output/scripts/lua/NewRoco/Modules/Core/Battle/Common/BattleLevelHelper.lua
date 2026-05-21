local BattleLevelHelper = NRCClass()
local CinematicModuleEvent = require("NewRoco.Modules.Core.Cinematic.CinematicModuleEvent")
local BloodTeamScenePath = "/Game/ArtRes/Level/Game/TeamBattle/TeamBattle_XMTZ/TeamBattle_XMTZ_Release"

function BattleLevelHelper:Init()
  _G.NRCEventCenter:RegisterEvent("BattleLevelHelper", self, CinematicModuleEvent.Started, self.PreloadB1level)
end

function BattleLevelHelper:LoadLevelStream(scenePath, shouldBeVisible, Location, Rotation)
  local LevelStreaming = UE4.UNRCStatics.CreateCustomStreamingLevel(scenePath, true)
  if LevelStreaming then
    LevelStreaming:SetShouldBeVisible(shouldBeVisible)
    self.levelStreaming = LevelStreaming
    LevelStreaming.OnLevelLoaded:Add(LevelStreaming, function(level)
      self.isLevelLoad = true
    end)
  else
    Location = Location or FVectorZero
    Rotation = Rotation or FRotatorZero
    LevelStreaming = BattleManager.vBattleField:LoadBattleLevel(scenePath, Location, Rotation)
    if LevelStreaming then
      LevelStreaming:SetShouldBeVisible(shouldBeVisible)
      self.levelStreaming = LevelStreaming
      LevelStreaming.OnLevelLoaded:Add(LevelStreaming, function(level)
        self.isLevelLoad = true
      end)
    else
      Log.Error("zgx Level Load Failed , Level Name", scenePath)
    end
  end
  return LevelStreaming
end

function BattleLevelHelper:SetEnvVolumeForLoadLevel(IsEnterBattle)
  if self.isLevelLoad then
    if UE4.UObject.IsValid(self.levelStreaming) then
      local EnvSystemVolume = UE4.UNRCStatics.GetActorFromLevelByClass(self.levelStreaming:GetLoadedLevel(), UE4.AEnvSystemVolume)
      if EnvSystemVolume then
        EnvSystemVolume.IsUsedVolume = IsEnterBattle or false
        EnvSystemVolume.bUnbound = IsEnterBattle or false
      end
    else
      Log.Error("VBattleField  LevelStreaming is nil")
    end
    BattleManager.vBattleField:MarkTodVolumeArrayDirty()
  end
end

function BattleLevelHelper:CancelLevelStream(scenePath)
  if self.levelStreaming and UE4.UObject.IsValid(self.levelStreaming) then
    self.levelStreaming:SetShouldBeLoaded(false)
    self.levelStreaming.OnLevelLoaded:Clear()
  end
  if not string.IsNilOrEmpty(scenePath) then
    UE4.UNRCStatics.RemoveCustomStreamingLevel(scenePath)
  end
  self:ClearWait()
  self.levelStreaming = nil
  self.isLevelLoad = false
end

function BattleLevelHelper:ResetLevelData()
  self:ClearWait()
  self.levelStreaming:SetShouldBeVisible(true)
  self.levelStreaming.OnLevelLoaded:Clear()
  self.levelStreaming = nil
  self.isLevelLoad = false
end

function BattleLevelHelper:StartWait(waitTime)
  if not self.levelStreaming then
    return
  end
  if self.waitHandle then
    return
  end
  waitTime = waitTime or 60
  self.waitHandle = _G.DelayManager:DelaySeconds(waitTime, self.CancelLevelStream, self)
end

function BattleLevelHelper:ClearWait()
  if self.waitHandle then
    _G.DelayManager:CancelDelayById(self.waitHandle)
    self.waitHandle = nil
  end
end

function BattleLevelHelper:GetIsLevelLoad()
  return self.isLevelLoad and self.levelStreaming
end

function BattleLevelHelper:PreloadB1level(SeqConf)
  if SeqConf then
    local finalbattle_loadlevel_id = _G.DataConfigManager:GetBattleGlobalConfig("B1_finalbattle_loadlevel").num
    if finalbattle_loadlevel_id == SeqConf.id then
      BattleResourceManager:LoadResAsync(self, BattleConst.B1P1EnterSequence)
    end
  end
end

function BattleLevelHelper:LoadBloodTeamLevelStream()
  if self.levelStreaming then
    self:ClearWait()
    return
  end
  self:LoadLevelStream(BloodTeamScenePath, true)
  BattleSkillManager:PreLoadSingleResInternal(BattleConst.TeamBloodPerEnterBattle, true)
  BattleSkillManager:PreLoadSingleResInternal(BattleConst.BloodTeamEnterFarBattle, true)
  BattleSkillManager:PreLoadSingleResInternal(BattleConst.TeamBloodBossEffect, true)
end

function BattleLevelHelper:CancelBloodTeamLevelStream()
  self:CancelLevelStream(BloodTeamScenePath)
end

function BattleLevelHelper:ResetBloodTeamLevelData()
  if self.levelStreaming then
    self.levelStreaming:SetShouldBeVisible(true)
    self:ResetLevelData()
  end
end

function BattleLevelHelper:OnEnterBattle()
  Log.Debug("BattleLevelHelper OnEnterBattle")
end

function BattleLevelHelper:OnLeaveBattle()
  Log.Debug("BattleLevelHelper OnLeaveBattle")
  if BattleUtils.IsBloodTeam() then
    UE4.UNRCStatics.RemoveCustomStreamingLevel(BloodTeamScenePath)
  end
end

return BattleLevelHelper
