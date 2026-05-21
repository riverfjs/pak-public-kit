local JsonUtils = require("Common.JsonUtils")
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local BattleDebugControl = require("NewRoco.Modules.System.BattleUI.Res.BattleDebugger.BattleDebugControl")
local PerfCatCmd = require("Profiler.PerfCat.PerfCatCmd")
local SkillAutoTest = NRCClass()

function SkillAutoTest:Init()
  self.debugCtrl = BattleDebugControl()
  _G.BattleManager.battleRuntimeData.battleDebugControl = self.debugCtrl
  self.autoBattleParam = JsonUtils.LoadSaved("AutoBattle/AutoTestParam")
  if not self.autoBattleParam then
    self.autoBattleParam = {}
    self.autoBattleParam.Pos = {
      x = 440399,
      y = 669799,
      z = 1231
    }
    self.autoBattleParam.TeamPet = "2000101"
    self.autoBattleParam.EnemyPet = "\230\176\180\232\147\157\232\147\157"
    self.autoBattleParam.ShowModel = false
    self.autoBattleParam.Mode = 1
    self.autoBattleParam.PlayCount = 2
    self.autoBattleParam.DungeonId = 0
    self.autoBattleParam.ShowOverdraw = false
    self.autoBattleParam.TestSkills = {7000010}
    self.autoBattleParam.DefendSkills = {7000320}
    self.autoBattleParam.AttackSkills = {7150050, 7140070}
    self.autoBattleParam.StateSkills = {7000030}
    self.autoBattleParam.BlackList = {7021060}
    self.autoBattleParam.TeamPet2 = "\230\129\182\233\173\148\229\143\174"
    self.autoBattleParam.EnemyPet2 = "\233\184\173\229\144\137\229\144\137"
    JsonUtils.DumpSaved("AutoBattle/AutoTestParam", self.autoBattleParam)
  end
  local EnvSystemModule = _G.NRCModuleManager:GetModule("EnvSystemModule")
  EnvSystemModule.LockWeather = Enum.WeatherType.WT_SUNNY
  EnvSystemModule.bChangeResult = true
end

function SkillAutoTest:StartAutoTest(callback_on_finished)
  self:Init()
  self.isStarted = false
  self.isFinished = false
  self.callback_on_finished = callback_on_finished or nil
  self.isInBattleTest = true
  self.currentRound = 0
  self.curPlayCount = 1
  self.maxPlayCount = self.autoBattleParam.PlayCount or 2
  self.testSkills = self.autoBattleParam.TestSkills
  self.teamSkillIdx = 0
  self.defendSkills = self.autoBattleParam.DefendSkills
  self.defendSkillIdx = 0
  self.attackSkills = self.autoBattleParam.AttackSkills
  self.attackSkillIdx = 0
  self.stateSkills = self.autoBattleParam.StateSkills
  self.blackList = self.autoBattleParam.BlackList or {7021060}
  self.stateSkillIdx = 0
  self.skillPerformTrackers = {}
  self.res_to_skill = {}
  if 1 == self.autoBattleParam.Mode and 0 == #self.testSkills then
    self.testSkills = self:CollectSkillByType({
      Enum.SkillType.ST_DAMAGE,
      Enum.SkillType.ST_DEFEND,
      Enum.SkillType.ST_STATUS
    })
  end
  if 4 == self.autoBattleParam.Mode or 5 == self.autoBattleParam.Mode then
    self:CollectAllSkill()
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_SELECT_START, BattleEvent.PrepareBattleOver, BattlePerformEvent.TurnPlayStart, BattlePerformEvent.TurnPlayComplete, BattleEvent.OnCallCrashSight)
  NRCEventCenter:RegisterEvent("SkillAutoTest", self, TaskModuleEvent.BattleOver, self.OnExitBattleEvent)
  self:SetEnterBattleParam()
  self.debugCtrl:EnterDebugBattle(self.enterBattleParam)
  self.debugCtrl.isInAutoTest = true
  self.isStarted = true
  PerfCatCmd.ExecCmdCurrentWorld("WorldTileTool.EnableLuaDebugPanel 0")
end

function SkillAutoTest:CollectSkillByType(types)
  local AllSkill = _G.DataConfigManager:GetAllByName("SKILL_CONF")
  local validSkillNum = 0
  local orderSkillList = {}
  for _, v in pairs(AllSkill) do
    if not string.IsNilOrEmpty(v.name) and not string.find(v.name, "\230\181\139\232\175\149") and not string.IsNilOrEmpty(v.res_id) and v.Skill_Type and table.contains(types, v.Skill_Type) and self:IsValidSkill(v.id) then
      if not self.res_to_skill[v.res_id] or self.res_to_skill[v.res_id] > v.id then
        self.res_to_skill[v.res_id] = v.id
      end
      validSkillNum = validSkillNum + 1
    end
  end
  for _, v in pairs(self.res_to_skill) do
    table.insert(orderSkillList, v)
  end
  table.sort(orderSkillList, function(a, b)
    return a < b
  end)
  Log.Warning("SkillAutoTest \230\148\182\233\155\134\230\138\128\232\131\189\230\149\176 (\229\142\187\233\135\141\229\137\141) ", validSkillNum)
  Log.Warning("SkillAutoTest \230\148\182\233\155\134\230\138\128\232\131\189\230\149\176 (\229\142\187\233\135\141\229\144\142) ", #orderSkillList)
  return orderSkillList
end

function SkillAutoTest:IsValidSkill(skillId)
  return not table.contains(self.blackList, skillId)
end

function SkillAutoTest:CollectAllSkill()
  local AllSkill = _G.DataConfigManager:GetAllByName("SKILL_CONF")
  local counterSkill = {}
  local beCounterSkillType = {}
  local countRepeatMap = {}
  local becountRepeatMap = {}
  local tInsert = table.insert
  local orderSkillList = {}
  for _, v in pairs(AllSkill) do
    tInsert(orderSkillList, v)
  end
  table.sort(orderSkillList, function(a, b)
    return a.id < b.id
  end)
  local skillCfg
  for _, v in ipairs(orderSkillList) do
    skillCfg = v
    local needPlay = not string.IsNilOrEmpty(skillCfg.name) and not string.find(skillCfg.name, "\230\181\139\232\175\149") and not string.IsNilOrEmpty(skillCfg.res_id) and skillCfg.Skill_Type and skillCfg.Skill_Type ~= Enum.SkillType.ST_NONE and self:IsValidSkill(v.id)
    if needPlay then
      if not countRepeatMap[skillCfg.res_id] and skillCfg.skill_result and #skillCfg.skill_result > 0 then
        for i, v in pairs(skillCfg.skill_result) do
          local EffectConf = _G.DataConfigManager:GetEffectConf(v.effect_id, true)
          if EffectConf and EffectConf.effect_order == Enum.EffectType.ET_COUNTER then
            tInsert(counterSkill, {
              id = skillCfg.id,
              skillType = skillCfg.Skill_Type,
              res_id = skillCfg.res_id
            })
            countRepeatMap[skillCfg.res_id] = true
          end
        end
      end
      if 0 == skillCfg.id % 10 and not becountRepeatMap[skillCfg.res_id] then
        if not beCounterSkillType[skillCfg.Skill_Type] then
          beCounterSkillType[skillCfg.Skill_Type] = {
            skillList = {},
            curIdx = 1
          }
        end
        tInsert(beCounterSkillType[skillCfg.Skill_Type].skillList, skillCfg.id)
        becountRepeatMap[skillCfg.res_id] = true
      end
    end
  end
  self.teamSkills = {}
  self.enemySkills = {}
  for i, v in ipairs(counterSkill) do
    table.insert(self.teamSkills, v.id)
    local countSkillType = self:GetCountSkillType(v.skillType)
    local beCountSkillArray = beCounterSkillType[countSkillType].skillList
    local curIndex = beCounterSkillType[countSkillType].curIdx
    if curIndex > #beCountSkillArray then
      curIndex = 1
    end
    local beCountSkill = beCountSkillArray[curIndex]
    beCounterSkillType[countSkillType].curIdx = curIndex + 1
    table.insert(self.enemySkills, beCountSkill)
  end
  Log.Warning("SkillAutoTest \229\186\148\229\175\185\230\138\128\230\128\187\230\149\176 ", #self.teamSkills)
  Log.Warning("SkillAutoTest \230\149\140\230\150\185\230\138\128\232\131\189\232\162\171\229\186\148\229\175\185\230\138\128\230\128\187\230\149\176 ", #self.enemySkills)
end

function SkillAutoTest:GetCountSkillType(countSkillType)
  if countSkillType == Enum.SkillType.ST_DAMAGE then
    return Enum.SkillType.ST_STATUS
  elseif countSkillType == Enum.SkillType.ST_STATUS then
    return Enum.SkillType.ST_DEFEND
  elseif countSkillType == Enum.SkillType.ST_DEFEND then
    return Enum.SkillType.ST_DAMAGE
  end
end

function SkillAutoTest:SetEnterBattleParam()
  self.enterBattleParam = {}
  self.enterBattleParam.battleType = 5 == self.autoBattleParam.Mode and 2 or 1
  self.enterBattleParam.isShowHP = false
  self.enterBattleParam.battlePos = self.autoBattleParam.Pos or {
    x = 440399,
    y = 669799,
    z = 1331
  }
  self.enterBattleParam.DungeonId = self.autoBattleParam.DungeonId or 0
  local teamPet = self:GetTeamPet(self.autoBattleParam.TeamPet)
  self.enterBattleParam.player_team = {playerSex = 1, pet1 = teamPet}
  local enemyPet = self:GetEnemyPet(self.autoBattleParam.EnemyPet)
  self.enterBattleParam.enemy_team = {
    npcName = "[17015]\232\183\175\230\152\147\230\150\175 BP_Battle_NPC_01101",
    pet1 = enemyPet
  }
  if 5 == self.autoBattleParam.Mode then
    local teamPet2 = self:GetTeamPet(self.autoBattleParam.TeamPet2)
    self.enterBattleParam.player_team.pet2 = self:GetTeamPet(teamPet2)
    local enemyPet2 = self:GetEnemyPet(self.autoBattleParam.EnemyPet2)
    self.enterBattleParam.enemy_team.pet2 = self:GetEnemyPet(enemyPet2)
  end
end

function SkillAutoTest:GetTeamPet(petInfo)
  if not string.IsNilOrEmpty(petInfo) then
    for i, v in pairs(self.debugCtrl:GetAllPetList()) do
      if v:find(string.lower(petInfo)) then
        return v
      end
    end
  end
  return string.lower("[9999999]\230\151\160\230\149\140\233\184\173\229\144\137\229\144\137(\230\181\139\232\175\149\231\148\168) BP_Com_YaJiJi1_001")
end

function SkillAutoTest:GetEnemyPet(petInfo)
  if not string.IsNilOrEmpty(petInfo) then
    for i, v in pairs(self.debugCtrl:GetAllMonsterList()) do
      if v:find(string.lower(petInfo)) then
        return v
      end
    end
  end
  return string.lower("[9999999]\230\151\160\230\149\140\233\184\173\229\144\137\229\144\137(\230\181\139\232\175\149\231\148\168) BP_Com_YaJiJi1_001")
end

function SkillAutoTest:OnBattleEvent(eventName, param1, param2)
  if not self.isInBattleTest then
    return
  end
  if eventName == BattleEvent.PrepareBattleOver then
    self:OnPrepareBattleOver()
  elseif eventName == BattleEvent.ROUND_SELECT_START then
    self:OnRoundStart()
  elseif eventName == BattlePerformEvent.TurnPlayStart then
    local skillList = param1
    local buffList = param2
    self:OnTurnPlayStart(skillList, buffList)
  elseif eventName == BattlePerformEvent.OnCallCrashSight then
    self:OnCallCrashSight(param1)
  elseif eventName == BattlePerformEvent.TurnPlayComplete then
    self:OnTurnPlayComplete()
  elseif eventName == BattleEvent.StartSkill_AutoPerform then
    local skillObject = param1
    if skillObject then
      Log.Debug("OnBattleEvent \230\138\128\232\131\189 ", skillObject:GetName())
    end
  end
end

function SkillAutoTest:OnPrepareBattleOver()
  local roundCount = 0
  if 1 == self.autoBattleParam.Mode then
    roundCount = self.maxPlayCount
  elseif 2 == self.autoBattleParam.Mode then
    roundCount = #self.testSkills
  elseif 3 == self.autoBattleParam.Mode then
    roundCount = #self.testSkills
  elseif 4 == self.autoBattleParam.Mode then
    roundCount = #self.teamSkills
  elseif 5 == self.autoBattleParam.Mode then
    roundCount = #self.teamSkills
  end
  local allMyTeam = BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  for teamIdx, team in ipairs(allMyTeam) do
    for petIdx, pet in ipairs(team.pets) do
      if pet and pet.card.pos > 0 then
        local petPos = teamIdx * pet.card.pos
        self["teamPetGuid" .. petPos] = pet.card.guid
      end
    end
  end
  local allEnemyTeam = BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)
  for teamIdx, team in ipairs(allEnemyTeam) do
    for petIdx, pet in ipairs(team.pets) do
      if pet and pet.card.pos > 0 then
        local petPos = teamIdx * pet.card.pos
        self["enemyPetGuid" .. petPos] = pet.card.guid
      end
    end
  end
  if self.autoBattleParam.ShowOverdraw then
    PerfCatCmd.SetViewMode("simpleoverdraw")
    PerfCatCmd.EnableShaderComplexityPostProcess()
  else
    PerfCatCmd.SetViewMode("lit")
    PerfCatCmd.DisableShaderComplexityPostProcess()
  end
  if self.autoBattleParam.EffectQuality then
    self:SetEffectQuality(self.autoBattleParam.EffectQuality)
  end
  self.debugCtrl:ShowOrHideAllScreenInfo()
  Log.DebugFormat("SkillAutoTest \230\136\152\230\150\151\229\188\128\229\167\139 mode:%d, \230\128\187\232\161\168\230\188\148\229\155\158\229\144\136\230\149\176:%d", self.autoBattleParam.Mode, roundCount)
  PerfCatCmd.SkillCombat.Start()
end

function SkillAutoTest:SetEffectQuality(vfxQuality)
  if "high" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.High)
  elseif "medium" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.Medium)
  elseif "low" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.Low)
  end
end

function SkillAutoTest:OnTurnPlayStart(skillList, buffList)
  local validSkillAssetList = {}
  local validSkillIdList = {}
  for k, v in pairs(skillList) do
    if 730000600 ~= k and 20000200 ~= k then
      table.insert(validSkillAssetList, v)
      table.insert(validSkillIdList, k // 100)
    end
  end
  if 1 == self.autoBattleParam.Mode then
    if 1 == #validSkillAssetList then
      local skillAssetName = string.match(validSkillAssetList[1], "([^/]+)$")
      local index, _ = string.find(validSkillAssetList[1], "/Game")
      local packageName = string.sub(validSkillAssetList[1], index)
      if packageName and self.res_to_skill[packageName] then
        PerfCatCmd.SkillCombat.Play(string.format("%d#%s", self.res_to_skill[packageName], skillAssetName))
      else
        PerfCatCmd.SkillCombat.Play(string.format("%d#%s", validSkillIdList[1], skillAssetName))
      end
      if self.skillPerformTrackers[validSkillIdList[1]] then
        self.skillPerformTrackers[validSkillIdList[1]] = nil
      end
    elseif #validSkillAssetList > 1 then
      Log.Error("[SkillAutoTest] More than one skill performed, PerfCat cannot track the skill for now.")
    end
  end
  Log.DebugFormat("SkillAutoTest \229\155\158\229\144\136\232\161\168\230\188\148\229\188\128\229\167\139 mode: %d, round: %d", self.autoBattleParam.Mode, self.currentRound)
end

function SkillAutoTest:OnCallCrashSight(reason)
  PerfCatCmd.SkillCombat.Crash(reason)
  Log.WarningFormat("SkillAutoTest \229\155\158\229\144\136\232\161\168\230\188\148\230\138\165\233\148\153 \233\148\153\232\175\175\230\151\165\229\191\151:%s", reason)
end

function SkillAutoTest:OnTurnPlayComplete()
  PerfCatCmd.SkillCombat.Pause()
  Log.DebugFormat("SkillAutoTest \229\155\158\229\144\136\232\161\168\230\188\148\231\187\147\230\157\159 round:%d", self.currentRound)
end

function SkillAutoTest:OnRoundStart()
  NRCModeManager:DoCmd(BattleUIModuleCmd.BattleMainSetOpacity, 0)
  self.currentRound = self.currentRound + 1
  if not self.autoBattleParam.ShowModel then
    self:HideModel()
  end
  local roundParam = self:PrepareRoundParam()
  self.delayId = _G.DelayManager:DelaySeconds(1, function()
    self.debugCtrl:RoundStart(roundParam)
    if self.delayId then
      _G.DelayManager:CancelDelayById(self.delayId)
      self.delayId = nil
    end
  end)
end

function SkillAutoTest:HideModel()
  self:HideModelByTeamInfo(BattleEnum.Team.ENUM_TEAM)
  self:HideModelByTeamInfo(BattleEnum.Team.ENUM_ENEMY)
end

function SkillAutoTest:HideModelByTeamInfo(teamEnum)
  local allMyTeam = BattleManager.battlePawnManager:GetAllTeam(teamEnum)
  for teamIdx, team in ipairs(allMyTeam) do
    local teamPlayer = team.player
    if teamPlayer and teamPlayer.model then
      teamPlayer:HidePlayer(true)
    end
    for petIdx, teamPet in ipairs(team.pets) do
      if teamPet then
        local mesh = teamPet.model:GetComponentByClass(UE.USkeletalMeshComponent)
        if mesh then
          mesh:SetVisibility(false)
          mesh:SetHiddenInGame(true)
        end
        teamPet.model:SetSelfFXVisible(false)
        teamPet:ChangeBuffVisibility(false)
      end
    end
  end
end

function SkillAutoTest:PrepareRoundParam()
  local teamSkillCfg, enemySkillCfg
  if 1 == self.autoBattleParam.Mode then
    teamSkillCfg = self:GetTeamSkill()
    if not teamSkillCfg and self.curPlayCount < self.maxPlayCount then
      self.curPlayCount = self.curPlayCount + 1
      self.teamSkillIdx = 0
      teamSkillCfg = self:GetTeamSkill()
    end
    if not teamSkillCfg then
      for k, v in pairs(self.skillPerformTrackers) do
        if v > 5 then
          self.skillPerformTrackers[k] = nil
        else
          teamSkillCfg = _G.DataConfigManager:GetSkillConf(k)
          Log.WarningFormat("[SkillAutoTest] replay %d, tries: %d", k, v)
        end
      end
    end
    if not teamSkillCfg then
      self:SendExitBattle()
      return
    end
    if self.skillPerformTrackers[teamSkillCfg.id] then
      self.skillPerformTrackers[teamSkillCfg.id] = self.skillPerformTrackers[teamSkillCfg.id] + 1
    else
      self.skillPerformTrackers[teamSkillCfg.id] = 0
    end
    enemySkillCfg = _G.DataConfigManager:GetSkillConf(7300006)
  elseif 2 == self.autoBattleParam.Mode then
    teamSkillCfg = self:GetTeamSkill()
    Log.Dump(self.testSkills, 5, "SkillAutoTest:PrepareRoundParam")
    if not teamSkillCfg then
      self:SendExitBattle()
      return
    end
    enemySkillCfg = self:GetCountSkill(teamSkillCfg.Skill_Type)
    if not enemySkillCfg then
      self:SendExitBattle()
      return
    end
  elseif 3 == self.autoBattleParam.Mode then
    teamSkillCfg = self:GetTeamSkill()
    if not teamSkillCfg then
      self:SendExitBattle()
      return
    end
    enemySkillCfg = self:GetBeCountSkill(teamSkillCfg.Skill_Type)
    if not enemySkillCfg then
      self:SendExitBattle()
      return
    end
  elseif self.teamSkillIdx < #self.teamSkills then
    local skillIdx1, tSCfg = self:GetValidSkill(self.teamSkillIdx, self.teamSkills)
    if not tSCfg then
      self:SendExitBattle()
      return
    end
    teamSkillCfg = tSCfg
    self.teamSkillIdx = skillIdx1
    local skillIdx2, eSCfg = self:GetValidSkill(self.teamSkillIdx, self.enemySkills)
    if not eSCfg then
      self:SendExitBattle()
      return
    end
    enemySkillCfg = eSCfg
    self.teamSkillIdx = skillIdx2
  else
    self:SendExitBattle()
    return
  end
  if not teamSkillCfg or not enemySkillCfg then
    self:SendExitBattle()
    return
  end
  local roundParam = {}
  roundParam.playerMagicCMDs = {}
  roundParam.teamCMDs = {}
  local teamSkillInfo = {}
  teamSkillInfo[1] = self:CreateSkillInfo(BattleEnum.Team.ENUM_TEAM, 1, self.teamPetGuid1, self.enemyPetGuid1, 1, teamSkillCfg.id)
  table.insert(roundParam.teamCMDs, teamSkillInfo)
  roundParam.enemyCMDs = {}
  local enemySkillInfo = {}
  enemySkillInfo[1] = self:CreateSkillInfo(BattleEnum.Team.ENUM_ENEMY, 1, self.enemyPetGuid1, self.teamPetGuid1, 1, enemySkillCfg.id)
  table.insert(roundParam.enemyCMDs, enemySkillInfo)
  if 5 == self.autoBattleParam.Mode then
    local teamSkillInfo2 = {}
    teamSkillInfo2[1] = self:CreateSkillInfo(BattleEnum.Team.ENUM_TEAM, 2, self.teamPetGuid2, self.enemyPetGuid2, 2, 7300006)
    table.insert(roundParam.teamCMDs, teamSkillInfo2)
    local enemySkillInfo2 = {}
    enemySkillInfo2[1] = self:CreateSkillInfo(BattleEnum.Team.ENUM_ENEMY, 2, self.enemyPetGuid2, self.teamPetGuid2, 2, 7300006)
    table.insert(roundParam.enemyCMDs, enemySkillInfo2)
  end
  Log.DebugFormat("SkillAutoTest \229\155\158\229\144\136\233\128\137\230\139\155 \230\136\145\230\150\185\230\138\128\232\131\189:%d_%s %s, \230\149\140\230\150\185\230\138\128\232\131\189:%d_%s %s", teamSkillCfg.id, teamSkillCfg.name, teamSkillCfg.res_id, enemySkillCfg.id, enemySkillCfg.name, enemySkillCfg.res_id)
  return roundParam
end

function SkillAutoTest:CreateSkillInfo(team, pos, petGuid, skillTargetId, playOrder, skillId)
  local skillInfo = {}
  skillInfo.team = team
  skillInfo.pos = pos
  skillInfo.petGuid = petGuid
  skillInfo.skillTargetId = skillTargetId
  skillInfo.playOrder = playOrder
  skillInfo.skillId = skillId
  skillInfo.attackCount = 1
  skillInfo.isKill = false
  return skillInfo
end

function SkillAutoTest:GetValidSkill(curIndex, skillList)
  local skillCfg, skillId
  while not skillCfg do
    curIndex = curIndex + 1
    if curIndex > #skillList then
      return nil
    end
    skillId = skillList[curIndex]
    skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  end
  return curIndex, skillCfg
end

function SkillAutoTest:GetTeamSkill()
  if not self.teamSkillIdx then
    return nil
  end
  local skillIdx, skillCfg = self:GetValidSkill(self.teamSkillIdx, self.testSkills)
  self.teamSkillIdx = skillIdx
  return skillCfg
end

function SkillAutoTest:GetDefendSkill()
  local skillIdx, skillCfg = self:GetValidSkill(self.defendSkillIdx, self.defendSkills)
  if not skillCfg then
    skillIdx, skillCfg = self:GetValidSkill(0, self.defendSkills)
  end
  self.defendSkillIdx = skillIdx
  return skillCfg
end

function SkillAutoTest:GetStateSkill()
  local skillIdx, skillCfg = self:GetValidSkill(self.stateSkillIdx, self.stateSkills)
  if not skillCfg then
    skillIdx, skillCfg = self:GetValidSkill(0, self.stateSkills)
  end
  self.stateSkillIdx = skillIdx
  return skillCfg
end

function SkillAutoTest:GetAttackSkill()
  local skillIdx, skillCfg = self:GetValidSkill(self.attackSkillIdx, self.attackSkills)
  if not skillCfg then
    skillIdx, skillCfg = self:GetValidSkill(0, self.attackSkills)
  end
  self.attackSkillIdx = skillIdx
  return skillCfg
end

function SkillAutoTest:GetCountSkill(Skill_Type)
  if Skill_Type == Enum.SkillType.ST_DAMAGE then
    return self:GetStateSkill()
  elseif Skill_Type == Enum.SkillType.ST_STATUS then
    return self:GetDefendSkill()
  elseif Skill_Type == Enum.SkillType.ST_DEFEND then
    return self:GetAttackSkill()
  end
end

function SkillAutoTest:GetBeCountSkill(Skill_Type)
  if Skill_Type == Enum.SkillType.ST_DAMAGE then
    return self:GetDefendSkill()
  elseif Skill_Type == Enum.SkillType.ST_STATUS then
    return self:GetAttackSkill()
  elseif Skill_Type == Enum.SkillType.ST_DEFEND then
    return self:GetStateSkill()
  end
end

function SkillAutoTest:SendExitBattle()
  local req = _G.ProtoMessage:newZoneGmBattleEndReq()
  req.battle_result = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_BATTLE_END_REQ, req, self, self.OnQuitBattle)
end

function SkillAutoTest:OnQuitBattle()
  if self.isInBattleTest then
    self.isInBattleTest = false
    _G.BattleEventCenter:UnBind(self)
    NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.BattleOver, self.OnExitBattleEvent)
    Log.DebugFormat("SkillAutoTest \230\136\152\230\150\151\231\187\147\230\157\159 mode:%d, \232\161\168\230\188\148\229\155\158\229\144\136\230\149\176:%d", self.autoBattleParam.Mode, self.currentRound)
    self.debugCtrl:ShowOrHideAllScreenInfo()
    self.debugCtrl.isInAutoTest = false
    _G.BattleManager.battleRuntimeData.battleDebugControl = nil
  end
  PerfCatCmd.SkillCombat.Stop()
  self.isFinished = true
  if self.autoBattleParam.ShowOverdraw then
    PerfCatCmd.SetViewMode("lit")
  end
  if self.callback_on_finished then
    self:callback_on_finished()
  end
end

function SkillAutoTest:OnExitBattleEvent()
  self:OnQuitBattle()
end

return SkillAutoTest
