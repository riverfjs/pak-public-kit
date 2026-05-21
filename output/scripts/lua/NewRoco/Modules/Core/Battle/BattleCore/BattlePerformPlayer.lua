local BattlePerformCluster = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformCluster")
local BattlePerformGroup = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformGroup")
local BattlePerformNode = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformNode")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattlePerformPlayer = NRCClass:Extend("BattlePerformPlayer")

function BattlePerformPlayer:Ctor(turnPlayer)
  self.turnPlayer = turnPlayer
  self.curMsTime = UpdateManager.Timestamp
  self.roundStartTime = os.msTime()
  self.rountTimeoutDuration = 60000
  self.clusterTimeoutDuration = 30000
  self.IsStopTickTimeout = false
  self.isPause = false
  self.NeedResume = false
  self.pauseLock = 0
  self.PerformGroupLst = {}
  self.performLst = {}
  self.isRecycleNode = false
  self.performNodeIdx = 0
  self.performComboClusterLst = {}
  self.performClusterIdxCur = 1
  self.performingClusterCount = 0
  self.performingClusterNodeIDs = {}
  self.PerformClusterLst = {}
  self.IsFinalize = false
  self.PerformedBuffInfo = {}
  self.PerformedPopInfo = {}
  self.PerformedEffectPopInfo = {}
  self.cmdValidCheckResult = BattleEnum.PerformCmdValidCheckResult.Success
  self.LimitMaxNumber = 5
  self.CurTriggerNumber = 0
  self.FrameStartNodeNum = 0
  self.hadChangeSkillPositionPlayer = nil
  self:EnableUpdate()
end

function BattlePerformPlayer:CanTriggerNext()
  if self.CurTriggerNumber > self.LimitMaxNumber or self.FrameStartNodeNum >= self.LimitMaxNumber and self.bUpdateRegistered then
    return false
  end
  return true
end

function BattlePerformPlayer:RecordBuffPlayedRes(resPath, casterId)
  resPath = resPath or ""
  self.PerformedBuffInfo[casterId] = resPath
end

function BattlePerformPlayer:CheckBuffRepeatByRes(resPath, casterId)
  if self.PerformedBuffInfo[casterId] and self.PerformedBuffInfo[casterId] == resPath then
    return true
  end
  return false
end

function BattlePerformPlayer:RecordPopPlayedRes(resPath, casterId)
  resPath = resPath or ""
  self.PerformedPopInfo[casterId] = resPath
end

function BattlePerformPlayer:CheckPopRepeatByRes(resPath, casterId)
  if self.PerformedPopInfo[casterId] and self.PerformedPopInfo[casterId] == resPath then
    return true
  end
  return false
end

function BattlePerformPlayer:RecordEffectPopPlayedId(casterId)
  self.PerformedEffectPopInfo[casterId] = true
end

function BattlePerformPlayer:CheckEffectPopRepeatById(casterId)
  return self.PerformedEffectPopInfo[casterId]
end

local MaxProcessFrame = 5
local MaxCreateCountPerFrame = 25

function BattlePerformPlayer:PreProcess(cmd)
  local result = self:PreSortPerformCmd(cmd)
  if not result then
    Log.Error("CMD PreSort Error!")
    return
  end
  self:Clear()
  self.performTime = 0
  self.isRoundBegin = true
  local performInfos = cmd.perform_info
  local totalPerformCount = #performInfos
  local CurrentCreateCountPerFrame = 1
  if totalPerformCount <= MaxCreateCountPerFrame then
    CurrentCreateCountPerFrame = totalPerformCount
  else
    local processFrame = math.min(MaxProcessFrame, math.ceil(totalPerformCount / MaxCreateCountPerFrame))
    CurrentCreateCountPerFrame = math.ceil(totalPerformCount / processFrame)
  end
  if totalPerformCount > 0 then
    BattleBudget:PushDelayTask(nil, function()
      self:CreatePerformNode(cmd, CurrentCreateCountPerFrame)
    end)
  else
    self:StartPerform()
  end
end

function BattlePerformPlayer:CreatePerformNode(cmd, CreateCount)
  if not BattleManager:IsInBattle(true) then
    Log.Warning("zgx BattlePerformPlayer:CreatePerformNode not in battle")
    return
  end
  local performInfos = cmd.perform_info
  if self.performNodeIdx < #performInfos then
    if CreateCount <= 0 then
      CreateCount = MaxCreateCountPerFrame
    end
    local StartIndex = self.performNodeIdx + 1
    local EndIndex = math.min(#performInfos, StartIndex + CreateCount - 1)
    for i = StartIndex, EndIndex do
      self.performNodeIdx = self.performNodeIdx + 1
      self:CreatePerformNodeByInfo(performInfos[i], self.performNodeIdx, _G.GlobalConfig.FastPlay or cmd.IsFastPlay)
    end
    if self.performNodeIdx < #performInfos then
      BattleBudget:PushDelayTask(nil, function()
        self:CreatePerformNode(cmd, CreateCount)
      end)
    else
      BattleBudget:PushDelayTask(nil, function()
        if not BattleManager:IsInBattle(true) then
          return
        end
        self:PreProcessClientData(cmd)
        self:StartPerform()
      end)
    end
  else
    Log.Warning("zgx BattlePerformPlayer:CreatePerformNode", self.performNodeIdx, #performInfos)
    self:PreProcessClientData(cmd)
    self:StartPerform()
  end
end

function BattlePerformPlayer:CreatePerformNodeByInfo(performInfo, performNodeIdx, IsFastPlay)
  local performNode = BattlePerformNodePool:Get(BattlePerformNode, self)
  local group_id = performInfo.group_id
  performNode.IsFastPlay = IsFastPlay
  performNode:PreProcess(performInfo, performNodeIdx)
  if not self.PerformGroupLst[group_id] then
    self.PerformGroupLst[group_id] = BattlePerformGroup(group_id)
  end
  self.PerformGroupLst[group_id]:AddNode(performNode)
  table.insert(self.performLst, performNode)
  if performNode:IsGroupHead() then
    if not performNode:GetGroupRef() or performNode:IsCopeSkill() then
      local cluster = BattlePerformCluster(self)
      cluster.ClusterId = #self.PerformClusterLst + 1
      cluster:AddGroup(self.PerformGroupLst[group_id])
      table.insert(self.PerformClusterLst, cluster)
    end
  elseif 0 == performNode:GetCastMoment() and not self:IsCmdCriticalFailure(self.cmdValidCheckResult) then
    self.cmdValidCheckResult = BattleEnum.PerformCmdValidCheckResult.UnexpectedCM0
  end
  BattlePerformDebug.ZGXDebugPerformDetail(performNode, performInfo)
  return performNode
end

function BattlePerformPlayer:PreProcessClientData(cmd)
  self:PreProcessChangePet()
  self:PreprocessLastHitNode(cmd)
  self:PreprocessLastDeadNode(cmd)
  self:PreprocessClusterLst()
  self:PreProcessCombinationSkill()
  self:PreprocessComboCluster()
  self:PreprocessMultiAttackNode(cmd)
  self:PreProcessEnjoyField()
  self:PreProcessCounterNew()
  self:PreProcessPlayerSkillBossification()
  self:PreProcessMergerPetDie()
  self:UpdateProcessUI(cmd)
  self:PreProcessGatherBuffEnd()
  self:PreprocessPrepareToBattle()
  self:PreprocessDeathBombBuff()
  self:PreprocessResonance()
end

function BattlePerformPlayer:PreProcessPlayerSkillBossification()
  for i, cluster in ipairs(self.PerformClusterLst) do
    local bossification = false
    local playerSkillPerformNode, petId
    local isBindChangeModel = false
    local isBindChangePet = false
    for i = 1, #cluster.ClusterGroups do
      local group = cluster.ClusterGroups[i]
      for j = 1, #group.GroupNodes do
        local performNode = group.GroupNodes[j]
        if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
          local role_skill_cast = performNode:GetPerformData()
          local skill_id = role_skill_cast.skill_id
          local SkillConf = _G.SkillUtils.GetSkillConf(skill_id)
          if SkillConf and SkillConf.skill_result and #SkillConf.skill_result > 0 then
            local EffectConf = _G.DataConfigManager:GetEffectConf(SkillConf.skill_result[1].effect_id)
            if EffectConf and (EffectConf.effect_order == Enum.EffectType.ET_BOSS_BLOOD or EffectConf.effect_order == Enum.EffectType.ET_ROLE_CHANGE_PET) then
              bossification = true
              playerSkillPerformNode = performNode
              petId = role_skill_cast.pet_id
            end
          else
            Log.Error("SKILL_CONF\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
          end
        end
        if bossification and playerSkillPerformNode and performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL then
          if isBindChangeModel then
            Log.Error("zgx There are multi changmodel in the cluster")
            local changeModel = performNode:GetPerformData()
            if changeModel and changeModel.pet_id == petId then
              playerSkillPerformNode:SetPerformData("change_model", performNode:GetPerformData())
            end
          else
            isBindChangeModel = true
            playerSkillPerformNode:SetPerformData("change_model", performNode:GetPerformData())
          end
        end
        if bossification and playerSkillPerformNode and performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
          if isBindChangePet then
            Log.Error("zgx There are multi changepet in the cluster")
            local changePet = performNode:GetPerformData()
            if changePet and changePet.rest_pet_id == petId then
              playerSkillPerformNode:SetPerformData("change_pet", performNode:GetPerformData())
            end
          else
            isBindChangePet = true
            playerSkillPerformNode:SetPerformData("change_pet", performNode:GetPerformData())
          end
        end
      end
    end
  end
end

function BattlePerformPlayer:PreProcessCombinationSkill()
  local PerformGroupLst = self.PerformGroupLst or {}
  local casterIdToComboCount = {}
  for _, group in ipairs(PerformGroupLst) do
    local headNode = group and group.HeadNode
    local performType = headNode and headNode:GetPerformType()
    if performType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
      local comboSkillCast = headNode and headNode:GetPerformData()
      local casterId = comboSkillCast and comboSkillCast.caster_id
      local prevCount = casterId and casterIdToComboCount[casterId] or 0
      local nextCount = prevCount + 1
      casterIdToComboCount[casterId] = nextCount
    end
  end
  for _, group in ipairs(PerformGroupLst) do
    local headNode = group and group.HeadNode
    local ownerCluster = group and group.OwnerCluster
    local performType = headNode and headNode:GetPerformType()
    if performType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
      local comboSkillCast = headNode and headNode:GetPerformData()
      local casterId = comboSkillCast and comboSkillCast.caster_id
      local comboCount = casterId and casterIdToComboCount[casterId] or 0
      if comboCount > 1 and ownerCluster then
        ownerCluster.IsCombinationProcessCluster = true
      end
    end
  end
  for _, node in ipairs(self.performLst) do
    if node:GetOwnerCluster().IsCombinationProcessCluster and node:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
      node.IsFastPlay = true
    end
  end
end

function BattlePerformPlayer:PreProcessChangePet()
  for i = 1, #self.performLst do
    local perform = self.performLst[i]
    if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
      local changePet = perform:GetPerformData()
      if changePet.battle_pet_id == changePet.rest_pet_id then
        BattleManager.battleRuntimeData:SetHasPetReturn(changePet.battle_pet_id)
      end
      if changePet and not changePet.battlePets then
        changePet.battlePets = {
          changePet.battle_pet_id
        }
        changePet.restPets = {
          changePet.rest_pet_id
        }
        changePet.battleInfos = {
          changePet.battle_pet_info
        }
        local suitId = BattleManager.battlePawnManager:GetPetChangeSuitIdByGuid(changePet.battle_pet_id)
        if suitId < 0 then
          local relationPet = {}
          relationPet[changePet.battle_pet_id] = true
          relationPet[changePet.rest_pet_id] = true
          for j = i + 1, #self.performLst do
            local next = self.performLst[j]
            if next.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
              local nextChange = next:GetPerformData()
              if nextChange.player_id == changePet.player_id then
                local nextSuitId = BattleManager.battlePawnManager:GetPetChangeSuitIdByGuid(nextChange.battle_pet_id)
                if not relationPet[nextChange.battle_pet_id] and not relationPet[nextChange.rest_pet_id] and nextSuitId < 0 then
                  nextChange.battlePets = {}
                  table.insert(changePet.battlePets, nextChange.battle_pet_id)
                  table.insert(changePet.restPets, nextChange.rest_pet_id)
                  table.insert(changePet.battleInfos, nextChange.battle_pet_info)
                else
                  nextChange.battlePets = {
                    nextChange.battle_pet_id
                  }
                  nextChange.restPets = {
                    nextChange.rest_pet_id
                  }
                  nextChange.battleInfos = {
                    nextChange.battle_pet_info
                  }
                  relationPet[nextChange.battle_pet_id] = true
                  relationPet[nextChange.rest_pet_id] = true
                end
              end
            end
          end
        end
      end
    end
  end
end

function BattlePerformPlayer:PreProcessCounterNew()
  for _, cluster in ipairs(self.PerformClusterLst) do
    if cluster.HeadGroup and cluster.HeadGroup.HeadNode and cluster.HeadGroup.HeadNode:IsCopeSkill() then
      _G.BattleManager.battleRuntimeData:SetIsDelayRiOf(true)
      local group_ref = cluster.HeadGroup.HeadNode:GetGroupRef()
      if group_ref then
        local beCounterGroup = self.PerformGroupLst[group_ref]
        if beCounterGroup and beCounterGroup ~= cluster.HeadGroup and not beCounterGroup.IsProcessCounter then
          local beCounterCluster = beCounterGroup.OwnerCluster
          if beCounterCluster then
            beCounterGroup.IsProcessCounter = true
            cluster.HeadGroup.HeadNode:SetBeCounterNode(beCounterGroup.HeadNode)
            beCounterGroup.HeadNode:SetCounterNode(cluster.HeadGroup.HeadNode)
            beCounterGroup.HeadNode:SetLogicCastMoment(BattlePerformNode.LogicCastType.ON_BE_COUNTER)
            self:MoveNodesToOtherGroup(beCounterGroup, cluster.HeadGroup, ProtoEnum.Buffbasetrigger_type.OnBeforeAttack, ProtoEnum.Buffbasetrigger_type.OnAfterAttack)
            self:MoveNodesToOtherGroup(cluster.HeadGroup, beCounterGroup, ProtoEnum.Buffbasetrigger_type.OnBeforeAttack, ProtoEnum.Buffbasetrigger_type.OnBeforeAttack)
            beCounterCluster:AddKeepServerOrderCluster(cluster)
          end
        end
      end
    end
  end
end

function BattlePerformPlayer:MoveNodesToOtherGroup(fromGroup, toGroup, fromCastMoment, toCastMoment)
  local formCluster = fromGroup.OwnerCluster
  local toCluster = toGroup.OwnerCluster
  local RemoveGroupId = {}
  for i = #formCluster.ClusterGroups, 1, -1 do
    local group = formCluster.ClusterGroups[i]
    if group ~= fromGroup and group.HeadNode and group.HeadNode:GetCastMoment() == fromCastMoment and group.HeadNode:GetGroupRef() == fromGroup.GroupId then
      formCluster:RemoveGroup(group)
      toCluster:AddGroup(group, true, toGroup.GroupId)
      table.insert(RemoveGroupId, group.GroupId)
      group.HeadNode:ModifyCastMoment(toCastMoment)
    end
  end
  local loopMax = 300
  while #RemoveGroupId > 0 and loopMax > 0 do
    local oldRemoveGroupId = RemoveGroupId
    RemoveGroupId = {}
    loopMax = loopMax - 1
    if loopMax <= 0 then
      Log.Error("zgx Loop too many times!!!")
    end
    for i = #formCluster.ClusterGroups, 1, -1 do
      local group = formCluster.ClusterGroups[i]
      if group ~= fromGroup and group.HeadNode and table.contains(oldRemoveGroupId, group.HeadNode:GetGroupRef() or -1) then
        formCluster:RemoveGroup(group)
        toCluster:AddGroup(group)
        table.insert(RemoveGroupId, group.GroupId)
      end
    end
  end
  for i = #fromGroup.GroupNodes, 1, -1 do
    local node = fromGroup.GroupNodes[i]
    if node ~= fromGroup.HeadNode and fromGroup.HeadNode and node:GetCastMoment() == fromCastMoment then
      fromGroup:RemoveNode(node)
      toGroup:AddNode(node)
      node:ModifyCastMoment(toCastMoment)
    end
  end
end

function BattlePerformPlayer:PreProcessCounter()
  local isCounterSkill = false
  local countGroupId = 0
  local changeModelList = {}
  for i = 1, #self.performLst do
    local performNode = self.performLst[i]
    if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
      isCounterSkill = performNode:IsCopeSkill()
      countGroupId = performNode.groupID
    elseif performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER and performNode:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnBeforeAttack and isCounterSkill and (performNode:GetGroupID() == countGroupId or performNode:GetGroupRef() == countGroupId) then
      performNode:ModifyCastMoment(ProtoEnum.Buffbasetrigger_type.OnAfterAttack)
    end
    if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL and performNode:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnHit then
      local change_info = performNode:GetPerformData()
      if not changeModelList[change_info.pet_id] then
        changeModelList[change_info.pet_id] = {}
      end
      table.insert(changeModelList[change_info.pet_id], performNode)
    end
  end
  if isCounterSkill then
    for pet_id, changeList in pairs(changeModelList) do
      if #changeList > 1 then
        table.sort(changeList, function(a, b)
          return a:GetExecIdx() < b:GetExecIdx()
        end)
        local startChangeNode = changeList[1]
        for i = 2, #changeList do
          local nextChangeNode = changeList[i]
          nextChangeNode.OwnerGroup:RemoveNode(nextChangeNode)
          startChangeNode.OwnerGroup:AddNode(nextChangeNode)
        end
      end
    end
  end
end

function BattlePerformPlayer:GetBuffTriggerPlayerPet(perform)
  if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    local buffTrigger = perform:GetPerformData()
    if buffTrigger and buffTrigger.need_select_pet then
      return _G.BattleManager.battlePawnManager:GetCurPlayerPet(buffTrigger.target_id)
    end
  end
  return nil
end

function BattlePerformPlayer:PreProcessGatherBuffEnd()
  local gatherCache = {}
  local hasGatherRemove = false
  for i = 1, #self.performLst do
    local perform = self.performLst[i]
    if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
      local buffTrigger = perform:GetPerformData()
      if BuffUtils.IsGatherBuff(buffTrigger.buff_id) then
        if not gatherCache[buffTrigger.caster_id] then
          gatherCache[buffTrigger.caster_id] = {}
        end
        local removeTriggers = gatherCache[buffTrigger.caster_id].removeTriggers
        if not removeTriggers then
          removeTriggers = {}
          gatherCache[buffTrigger.caster_id].removeTriggers = removeTriggers
        end
        table.insert(removeTriggers, perform)
      end
    elseif perform.performNodeType == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
      local buffChange = perform:GetPerformData()
      if BuffUtils.IsGatherBuff(buffChange.buff_id) and buffChange.type == ProtoEnum.BuffChangeType.BCT_REMOVE then
        if not gatherCache[buffChange.caster_id] then
          gatherCache[buffChange.caster_id] = {}
        end
        gatherCache[buffChange.caster_id].isRemoveGather = true
        gatherCache[buffChange.caster_id].removeChangeBuff = perform
        hasGatherRemove = true
      end
    end
  end
  if not hasGatherRemove then
    return
  end
  for caster_id, cache in pairs(gatherCache) do
    if cache.isRemoveGather and cache.removeTriggers then
      for __, v in ipairs(cache.removeTriggers) do
        v.IsFastPlay = true
      end
    end
  end
end

function BattlePerformPlayer:PreProcessMergerPetDie()
  if BattleUtils.IsFinalBattleP1() then
    for i = #self.performLst, 1, -1 do
      local perform = self.performLst[i]
      if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
        local deadPet = perform:GetPerformData()
        if deadPet and not deadPet.deadPets then
          deadPet.deadPets = {deadPet}
          local relationPet = {}
          relationPet[deadPet.target_id] = true
          for j = i - 1, 1, -1 do
            local next = self.performLst[j]
            if next.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
              local nextDead = next:GetPerformData()
              if nextDead.caster_id == deadPet.caster_id then
                if not relationPet[nextDead.target_id] then
                  table.insert(deadPet.deadPets, nextDead)
                  relationPet[nextDead.target_id] = true
                end
                next.IsFastPlay = true
              end
            end
          end
        end
      end
    end
  elseif BattleUtils.IsB1FinalBattleP3() then
    for i = #self.performLst, 1, -1 do
      local perform = self.performLst[i]
      if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
        local deadPet = perform:GetPerformData()
        local target = _G.BattleManager.battlePawnManager:GetPetByGuid(deadPet.target_id)
        if target and target.teamEnm == BattleEnum.Team.ENUM_ENEMY then
          perform.IsFastPlay = true
          return
        end
      end
    end
  elseif BattleUtils.IsB1FinalBattleP2() then
    for i = #self.performLst, 1, -1 do
      local perform = self.performLst[i]
      if perform.performNodeType == ProtoEnum.BattlePerformType.BPT_DEATH then
        local deadPet = perform:GetPerformData()
        local target = _G.BattleManager.battlePawnManager:GetPetByGuid(deadPet.target_id)
        if target and target.teamEnm == BattleEnum.Team.ENUM_TEAM then
          perform.IsFastPlay = true
          return
        end
      end
    end
  end
end

function BattlePerformPlayer:PreSortPerformCmd(cmd)
  local performInfos = cmd.perform_info
  local TmpSortLst = {}
  for i = 1, #performInfos do
    local performInfo = performInfos[i]
    local groupID = performInfo.group_id
    if groupID > #TmpSortLst then
      if groupID > #TmpSortLst + 1 then
        self.cmdValidCheckResult = BattleEnum.PerformCmdValidCheckResult.GroupIdxJump
        return false
      end
      local newLst = {}
      table.insert(TmpSortLst, newLst)
    end
    table.insert(TmpSortLst[groupID], performInfo)
  end
  local mergeLst = {}
  for i = 1, #TmpSortLst do
    for j = 1, #TmpSortLst[i] do
      table.insert(mergeLst, TmpSortLst[i][j])
    end
  end
  cmd.perform_info = mergeLst
  return true
end

function BattlePerformPlayer:PreprocessClusterEventTime()
  self.clusterEventTimeLst = {}
  for i = 1, #self.PerformClusterLst do
    local performNode = self.PerformClusterLst[i].HeadGroup.HeadNode
    self.clusterEventTimeLst[i] = nil
    if performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_SKILL_CAST or performNode.performNodeType == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
      local skillID = performNode.performInfo.skill_cast.skill_id
      local SkillConf = _G.SkillUtils.GetSkillConf(skillID, true)
      if SkillConf and SkillConf.res_id then
        local time = SkillUtils.GetSkillEventTime(ProtoEnum.Buffbasetrigger_type.OnHit, SkillConf.res_id)
        self.clusterEventTimeLst[i] = time
      end
    end
  end
end

function BattlePerformPlayer:PreProcessEnjoyField()
  if _G.BattleManager.stateFsm:GetActiveStateName() == BattleEnum.StateNames.PrePlay then
    local InsertPos = {}
    local newPos = {}
    for i = 1, #self.PerformClusterLst do
      newPos[i] = i
    end
    for i, v in pairs(self.PerformClusterLst) do
      local performNode = v.HeadGroup.HeadNode
      if self:IsEnjoyFieldNode(performNode) then
        local type = performNode:GetPerformType()
        if InsertPos[type] then
          for fi, fv in pairs(InsertPos) do
            if fv > InsertPos[type] then
              InsertPos[fi] = InsertPos[fi] + 1
            end
          end
          InsertPos[type] = InsertPos[type] + 1
          local pos = newPos[i]
          table.remove(newPos, i)
          table.insert(newPos, InsertPos[type], pos)
        else
          InsertPos[type] = i
        end
      end
    end
    local newPerformClusterLst = {}
    for old, new in pairs(newPos) do
      newPerformClusterLst[old] = self.PerformClusterLst[new]
    end
    self.PerformClusterLst = newPerformClusterLst
  end
end

function BattlePerformPlayer:IsEnjoyFieldNode(performNode)
  if performNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE or performNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
    local buffConfig = _G.DataConfigManager:GetBuffConf(performNode:GetPerformID())
    if buffConfig and buffConfig.buff_list_priority >= 5 then
      return true
    end
  end
end

function BattlePerformPlayer:PreprocessComboCluster()
  if #self.PerformClusterLst < 2 or not BattleCoreEnv.EnableComboAttack then
    return
  else
    for i = 1, #self.PerformClusterLst - 1 do
      local checkAns = self:CheckIsComboCluster(i, i + 1)
      if checkAns then
        local comboTable = {}
        local delayTime = self:CalculateComboClusterDelay(i, i + 1)
        table.insert(comboTable, i)
        table.insert(comboTable, i + 1)
        table.insert(comboTable, delayTime)
        table.insert(self.performComboClusterLst, comboTable)
        i = i + 1
      end
    end
  end
end

function BattlePerformPlayer:CalculateComboClusterDelay(clusterID1, clusterID2)
  local skillCast1 = self.PerformClusterLst[clusterID1].HeadGroup.HeadNode.performInfo.skill_cast
  local skillCast2 = self.PerformClusterLst[clusterID2].HeadGroup.HeadNode.performInfo.skill_cast
  local time1 = self:PreprocessSkillCastEventTime(skillCast1)
  local time2 = self:PreprocessSkillCastEventTime(skillCast2)
  if time1 and time2 then
    local time = time1 - time2 + BattleConst.MultiplayerBattle.ComboAttackDelay
    if time >= 0 then
      return time
    else
      return 0.5
    end
  else
    return 0.5
  end
end

function BattlePerformPlayer:PreprocessSkillCastEventTime(skillCast)
  local skillID = skillCast.skill_id
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillID, true)
  if SkillConf and SkillConf.res_id then
    local time = SkillUtils.GetSkillEventTime(ProtoEnum.Buffbasetrigger_type.OnHit, SkillConf.res_id)
    return time
  end
  return nil
end

function BattlePerformPlayer:PreprocessChangeSkillPosition()
  local skillPositionChangePerformClusterLst = {}
  local newPerformClusterLst = {}
  for i, cluster in ipairs(self.PerformClusterLst) do
    local clusterHeadNode = cluster.HeadGroup.HeadNode
    if clusterHeadNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_SKILL_POS_CHANGE then
      table.insert(skillPositionChangePerformClusterLst, cluster)
    else
      table.insert(newPerformClusterLst, cluster)
    end
  end
  for i, cluster in ipairs(skillPositionChangePerformClusterLst) do
    table.insert(newPerformClusterLst, cluster)
  end
  self.PerformClusterLst = newPerformClusterLst
end

function BattlePerformPlayer:PreprocessPrepareToBattle()
  if not BattleUtils.IsTerritoryTrialBattle() then
    return
  end
  local segments = {}
  local currentSegment = {}
  for i, cluster in ipairs(self.PerformClusterLst) do
    local clusterHeadNode = cluster.HeadGroup.HeadNode
    if clusterHeadNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE then
      if #currentSegment > 0 then
        table.insert(segments, currentSegment)
      end
      currentSegment = {}
    end
    table.insert(currentSegment, cluster)
  end
  if #currentSegment > 0 then
    table.insert(segments, currentSegment)
  end
  for _, segment in ipairs(segments) do
    self:MergePrepareToBattleInSegment(segment)
  end
end

function BattlePerformPlayer:MergePrepareToBattleInSegment(segment)
  local firstPrepareToBattleNode
  for i, cluster in ipairs(segment) do
    local clusterHeadNode = cluster.HeadGroup.HeadNode
    if clusterHeadNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE then
      firstPrepareToBattleNode = clusterHeadNode
      break
    end
  end
  if not firstPrepareToBattleNode then
    return
  end
  for i, cluster in ipairs(segment) do
    local clusterHeadNode = cluster.HeadGroup.HeadNode
    if clusterHeadNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE and firstPrepareToBattleNode and firstPrepareToBattleNode ~= clusterHeadNode then
      local firstPrepareToBattleNodeData = firstPrepareToBattleNode and firstPrepareToBattleNode:GetPerformData()
      local currentData = clusterHeadNode:GetPerformData()
      local firstPrepareToBattleNodeSyncData = firstPrepareToBattleNode and firstPrepareToBattleNode:GetSyncData()
      local currentSyncData = clusterHeadNode and clusterHeadNode:GetSyncData()
      local firstPetInfoList = firstPrepareToBattleNodeSyncData and firstPrepareToBattleNodeSyncData.pet_sync_info or {}
      local currentInfoList = currentSyncData and currentSyncData.pet_sync_info or {}
      for _, syncInfo in ipairs(currentInfoList) do
        table.insert(firstPetInfoList, syncInfo)
      end
      table.clear(currentInfoList)
      local firstIdList = firstPrepareToBattleNodeData and firstPrepareToBattleNodeData.pet_id or {}
      local currentIdList = currentData and currentData.pet_id or {}
      for _, petId in ipairs(currentIdList) do
        table.insert(firstIdList, petId)
      end
      table.clear(currentIdList)
      local firstPosList = firstPrepareToBattleNodeData and firstPrepareToBattleNodeData.to_pos or {}
      local currentPosList = currentData and currentData.to_pos or {}
      for _, pos in ipairs(currentPosList) do
        table.insert(firstPosList, pos)
      end
      table.clear(currentPosList)
    end
  end
end

function BattlePerformPlayer:PreprocessDeathBombBuff()
  local PerformClusterLst = self.PerformClusterLst or {}
  local PerformGroupLst = self.PerformGroupLst or {}
  for _, cluster in ipairs(PerformClusterLst) do
    local clusterHeadGroup = cluster and cluster.HeadGroup
    local clusterHeadGroupHeadNode = clusterHeadGroup and clusterHeadGroup.HeadNode
    if clusterHeadGroupHeadNode then
      local hasDeadBombBuff = false
      local deadBombGroup, deadBombNode, deadNode
      local clusterGroups = cluster and cluster.ClusterGroups or {}
      local buffTriggerCasterId, deadCasterId
      for _, group in ipairs(clusterGroups) do
        local groupHeadNode = group and group.HeadNode
        local groupHeadNodePerformType = groupHeadNode and groupHeadNode:GetPerformType()
        if groupHeadNodePerformType == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
          local buffTrigger = groupHeadNode and groupHeadNode:GetPerformData()
          buffTriggerCasterId = buffTrigger and buffTrigger.caster_id
          if buffTrigger and buffTrigger.buff_id == BattleConst.BuffId.DeadBombBuff then
            hasDeadBombBuff = true
            deadBombGroup = group
            local groupRefGroupId = groupHeadNode and groupHeadNode:GetGroupRef()
            local refGroup = groupRefGroupId and PerformGroupLst[groupRefGroupId]
            local refGroupNodes = refGroup and refGroup.GroupNodes or {}
            for _, node in ipairs(refGroupNodes) do
              local nodePerformType = node and node:GetPerformType()
              if nodePerformType == ProtoEnum.BattlePerformType.BPT_DEATH then
                local deadInfo = node and node:GetPerformData()
                local deadInfoTargetId = deadInfo and deadInfo.target_id
                local isSameCaster = buffTriggerCasterId and deadInfoTargetId == buffTriggerCasterId or false
                if isSameCaster then
                  deadBombNode = groupHeadNode
                  deadNode = node
                  deadCasterId = deadInfo and deadInfo.caster_id
                  break
                end
              end
            end
            break
          end
        end
      end
      if hasDeadBombBuff and deadBombGroup and deadBombNode and deadNode then
        local originalGroup = deadNode.OwnerGroup
        if originalGroup then
          originalGroup:RemoveNode(deadNode)
        end
        deadBombGroup:AddNode(deadNode)
        deadBombNode:ModifyCastMoment(ProtoEnum.Buffbasetrigger_type.OnAfterAttack)
        deadNode:ModifyCastMoment(ProtoEnum.Buffbasetrigger_type.OnAfterAttack)
        if deadNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_DEATH then
          local deadInfo = deadNode and deadNode:GetPerformData()
          if deadInfo then
            deadInfo.dead_type = ProtoEnum.BattleDeadInfo.DeadType.DIE_WITH_CASTER
          end
        end
        if deadBombNode:GetPerformType() == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
          local buffTrigger = deadBombNode and deadBombNode:GetPerformData()
          if buffTrigger and deadCasterId then
            buffTrigger.target_id = deadCasterId
          end
        end
        Log.Debug("BattlePerformPlayer:PreprocessDeathBombBuff: \230\136\144\229\138\159\229\164\132\231\144\134\229\144\140\229\189\146\228\186\142\229\176\189Buff\232\161\168\230\188\148\239\188\140\230\173\187\228\186\161\232\138\130\231\130\185\229\183\178\231\167\187\229\138\168\229\136\176buff\232\167\166\229\143\145\231\187\132")
      end
    end
  end
end

function BattlePerformPlayer:CheckIsComboCluster(clusterID1, clusterID2)
  if not self:CheckIsValidComboCluster(clusterID1) then
    return false
  end
  if not self:CheckIsValidComboCluster(clusterID2) then
    return false
  end
  local cluster1Head = self.PerformClusterLst[clusterID1].HeadGroup.HeadNode
  local cluster2Head = self.PerformClusterLst[clusterID2].HeadGroup.HeadNode
  return self:CheckIsComboSkill(cluster1Head.performInfo.skill_cast, cluster2Head.performInfo.skill_cast)
end

function BattlePerformPlayer:CheckIsValidComboCluster(clusterID)
  local cluster = self.PerformClusterLst[clusterID]
  if not cluster then
    return nil
  end
  local clusterHead = cluster.HeadGroup.HeadNode
  if not clusterHead then
    return nil
  end
  if clusterHead.performNodeType ~= ProtoEnum.BattlePerformType.BPT_SKILL_CAST and clusterHead.performNodeType ~= ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
    return false
  end
  if clusterHead:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnCounter or clusterHead:GetCastMoment() == ProtoEnum.Buffbasetrigger_type.OnInterrupt then
    return false
  end
  if self.PerformClusterLst[clusterID]:GetNeedPerformNodeNumber() > 1 then
    return false
  end
  return true
end

function BattlePerformPlayer:CheckIsComboSkill(skillCast1, skillCast2)
  if not skillCast1 or not skillCast2 then
    return false
  end
  if skillCast1.caster_id == skillCast2.caster_id then
    return false
  end
  local pet1 = _G.BattleManager.battlePawnManager:GetPetByGuid(skillCast1.caster_id)
  local pet2 = _G.BattleManager.battlePawnManager:GetPetByGuid(skillCast2.caster_id)
  if not pet1 or not pet2 then
    return false
  end
  if pet1.teamEnm ~= pet2.teamEnm then
    return false
  end
  return self:CheckIsComboSkillType(skillCast1.skill_id, skillCast2.skill_id)
end

function BattlePerformPlayer:CheckIsComboSkillType(skill_id1, skill_id2)
  local skillConf1 = _G.SkillUtils.GetSkillConf(skill_id1)
  local skillConf2 = _G.SkillUtils.GetSkillConf(skill_id2)
  if not skillConf1 or not skillConf2 then
    return false
  end
  if skillConf1.damage_type == ProtoEnum.DamageType.DT_NONE and skillConf2.damage_type ~= ProtoEnum.DamageType.DT_NONE then
    return false
  end
  if skillConf2.damage_type == ProtoEnum.DamageType.DT_NONE and skillConf1.damage_type ~= ProtoEnum.DamageType.DT_NONE then
    return false
  end
  if 1 == skillConf1.is_show or 1 == skillConf2.is_show then
    return false
  end
  Log.Debug("BattlePerformPlayer CheckIsComboSkillType true")
  return true
end

function BattlePerformPlayer:PreprocessClusterLst()
  for _, group in ipairs(self.PerformGroupLst) do
    if not group.OwnerCluster then
      local cluster = self:GetPerformCluster(group, 0)
      if self:IsCmdCriticalFailure(self.cmdValidCheckResult) then
        return
      end
      if cluster then
        cluster:AddGroup(group)
      else
        Log.Error("PreprocessClusterLst is Error!! \230\136\152\230\150\151\232\161\168\230\188\148\230\149\176\230\141\174\229\135\186\233\148\153\239\188\129\239\188\129\239\188\129")
      end
    end
  end
  for _, cluster in ipairs(self.PerformClusterLst) do
    cluster:GetNeedPerformNodeNumber()
  end
end

function BattlePerformPlayer:PreprocessResonance()
  local resonance_nodes = {}
  for _, group in ipairs(self.PerformGroupLst) do
    for _, node in ipairs(group.GroupNodes) do
      if node.performNodeType == ProtoEnum.BattlePerformType.BPT_FEATURE_RESONANCE then
        table.insert(resonance_nodes, node)
        _G.BattleManager.battleRuntimeData:AddResonancePerform()
        break
      end
    end
  end
  for _, resonance_node in ipairs(resonance_nodes) do
    local resonance_group_id = resonance_node:GetGroupID()
    for _, group in ipairs(self.PerformGroupLst) do
      for _, node in ipairs(group.GroupNodes) do
        if node:GetGroupRef() == resonance_group_id then
          local info = node:GetInfo()
          local player = node:GetPlayer()
          if info and info.skill_cast and info.skill_cast.perform_flag == ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_RESONANCE and player then
            player:SetRuntimeData("is_finish", true)
            self.performNodeIdx = self.performNodeIdx + 1
            local perform_info = table.clone(info)
            perform_info.group_id = resonance_group_id
            perform_info.is_group_head = false
            perform_info.group_ref = resonance_node:GetGroupRef()
            perform_info.cast_moment = ProtoEnum.Buffbasetrigger_type.Immediatyly
            local perform_node = self:CreatePerformNodeByInfo(perform_info, self.performNodeIdx, node.IsFastPlay)
            resonance_node:AddParallelNode(perform_node)
          end
        end
      end
    end
  end
end

function BattlePerformPlayer:GetPerformCluster(group, depth)
  if depth >= 300 then
    self.cmdValidCheckResult = BattleEnum.PerformCmdValidCheckResult.RefDeadLoop
    return nil
  end
  if group then
    if group.OwnerCluster then
      return group.OwnerCluster
    elseif group.HeadNode and group.HeadNode:HasGroupRef() then
      return self:GetPerformCluster(self.PerformGroupLst[group.HeadNode:GetGroupRef()], depth + 1)
    end
  else
    return nil
  end
end

function BattlePerformPlayer:PreprocessLastHitNode(cmd)
  for i = 1, #self.performLst do
    local performNode = self.performLst[#self.performLst - i + 1]
    if performNode.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_DAMAGE and cmd.is_battle_finished and performNode.performInfo.is_last_hit then
      local groupId = performNode:GetGroupID()
      local cnt = #self.PerformGroupLst[groupId].GroupNodes
      local group = self.PerformGroupLst[groupId]
      local sourceId = performNode.performInfo.damage_info.source_id
      for j = 1, cnt do
        local node = group.GroupNodes[cnt - j + 1]
        if node.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
          if node.performInfo.skill_cast.skill_id == sourceId then
            node.IsLastHitNode = true
            return
          end
        elseif node.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
          if node.performInfo.combo_skill_cast.skill_id == sourceId then
            node.IsLastHitNode = true
            return
          end
        elseif node.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
          if node.performInfo.buff_trigger.buff_id == sourceId then
            node.IsLastHitNode = true
            return
          end
        elseif node.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER and node.performInfo.effect_trigger.effect_id == sourceId then
          node.IsLastHitNode = true
          return
        end
      end
    end
  end
end

function BattlePerformPlayer:PreprocessMultiAttackNode(cmd)
  for i = 1, #self.performLst do
    local performNode = self.performLst[i]
    if performNode:IsGroupHead() and (performNode.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_SKILL_CAST or performNode.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_COMBO_SKILL) then
      local groupId = performNode:GetGroupID()
      local group = performNode.OwnerGroup
      local cluster = performNode.OwnerGroup.OwnerCluster
      local serveTotalHit = 0
      local damageInfos
      for _, v in ipairs(group.GroupNodes) do
        if SkillUtils.IsMultiAttackType(v:GetCastMoment()) then
          serveTotalHit = math.max(serveTotalHit, v:GetCastMoment() - ProtoEnum.Buffbasetrigger_type.OnAttackHit + 1)
          if v:IsDamageInfoNode() then
            damageInfos = damageInfos or {}
            table.insert(damageInfos, v)
          end
        end
      end
      for _, v in ipairs(cluster.ClusterGroups) do
        if v.HeadNode:HasGroupRef() and v.HeadNode:GetGroupRef() == groupId and SkillUtils.IsMultiAttackType(v.HeadNode:GetCastMoment()) then
          serveTotalHit = math.max(serveTotalHit, v.HeadNode:GetCastMoment() - ProtoEnum.Buffbasetrigger_type.OnAttackHit + 1)
          if v.HeadNode:IsDamageInfoNode() then
            damageInfos = damageInfos or {}
            table.insert(damageInfos, v.HeadNode)
          end
        end
      end
      if serveTotalHit > 0 then
        performNode:SetMultiAttackNumber(serveTotalHit)
        performNode:SetIsMultiAttackType(serveTotalHit > 1)
        if damageInfos then
          for _, v in ipairs(damageInfos) do
            v:SetMultiAttackNumber(serveTotalHit)
          end
        end
      else
        performNode:SetMultiAttackNumber(0)
        performNode:SetIsMultiAttackType(false)
      end
    end
  end
end

function BattlePerformPlayer:PreprocessLastDeadNode(cmd)
  if cmd.is_battle_finished then
    local performListLen = #self.performLst
    for index = performListLen, 1, -1 do
      local performNode = self.performLst[index]
      if performNode.performNodeType == _G.ProtoEnum.BattlePerformType.BPT_DEATH then
        performNode.IsLastDeadNode = true
        break
      end
    end
  end
end

function BattlePerformPlayer:StartPerform()
  self.pauseLock = 0
  Log.Debug("BattlePerformPlayer StartPerform")
  if not self:ProcessCmdValidCheckResult(self.cmdValidCheckResult) then
    self.turnPlayer:HandlePerformComplete()
    return
  end
  self.CurTriggerNumber = 0
  self.FrameStartNodeNum = 0
  self.performClusterIdxCur = 0
  self.performingClusterCount = 0
  self:PerformNextCluster(0.01)
end

function BattlePerformPlayer:IsCmdCriticalFailure()
  Log.Error("\230\179\168\230\132\143\239\188\154\230\136\152\230\150\151\232\167\166\229\143\145\228\186\134\228\184\128\228\184\170\232\135\180\229\145\189\233\148\153\232\175\175:\232\175\183\231\171\139\229\141\179\230\138\138\230\136\152\230\150\151\230\149\176\230\141\174\230\143\144\228\190\155\231\187\153lance", self.cmdValidCheckResult)
  return self.cmdValidCheckResult == BattleEnum.PerformCmdValidCheckResult.GroupIdxJump or self.cmdValidCheckResult == BattleEnum.PerformCmdValidCheckResult.RefDeadLoop
end

function BattlePerformPlayer:GetNextClusterNode()
  if self.performClusterIdxCur < #self.PerformClusterLst then
    local next = self.performClusterIdxCur + 1
    return self.PerformClusterLst[next].HeadGroup.HeadNode
  end
end

function BattlePerformPlayer:PerformNextCluster(deltaTime, deltaFrames)
  if not self.IsFinalize then
    deltaTime = deltaTime or 0
    if self.performClusterIdxCur < #self.PerformClusterLst then
      local ClusterIdxCur = self.performClusterIdxCur + 1
      self.performClusterIdxCur = ClusterIdxCur
      local nextClusterNode = self.PerformClusterLst[ClusterIdxCur].HeadGroup.HeadNode
      self.PerformClusterLst[self.performClusterIdxCur]:Play(deltaTime, deltaFrames)
      if ClusterIdxCur < self.performClusterIdxCur then
        return
      end
      Log.Debug("EnableComboAttack:", BattleCoreEnv.EnableComboAttack)
      if BattleCoreEnv.EnableComboAttack then
        for i, clusterComboLst in ipairs(self.performComboClusterLst) do
          if clusterComboLst and 3 == #clusterComboLst and clusterComboLst[1] == ClusterIdxCur and clusterComboLst[2] == ClusterIdxCur + 1 then
            self:PerformNextCluster(clusterComboLst[3])
          end
        end
      end
      if ClusterIdxCur < self.performClusterIdxCur then
        return
      end
      if self:IsEnjoyFieldNode(nextClusterNode) then
        local next = self:GetNextClusterNode()
        if next and next:GetPerformType() == nextClusterNode:GetPerformType() and self:IsEnjoyFieldNode(next) then
          self:PerformNextCluster(0, 1)
        end
      end
    elseif 0 == self.performingClusterCount then
      self.turnPlayer:HandlePerformComplete()
    end
  end
end

function BattlePerformPlayer:PerformNodeCallback(performNode, castMoment, LimitType)
  if self:IsCounter(castMoment) then
    Log.Debug("ProtoEnum.Buffbasetrigger_type.CopeSkill")
    local nexClusterNode = self:GetNextClusterNode()
    if not nexClusterNode then
      return
    end
    if self:IsCounter(nexClusterNode:GetCastMoment()) then
      Log.Debug("ProtoEnum.Buffbasetrigger_type.OnCounter", nexClusterNode:GetCastMoment())
      self:PerformNextCluster(0, BattleBudget.clusterDelayTime)
    end
  end
end

function BattlePerformPlayer:IsCounter(castMoment)
  return castMoment == ProtoEnum.Buffbasetrigger_type.OnInterrupt or castMoment == ProtoEnum.Buffbasetrigger_type.OnCounter or castMoment == ProtoEnum.Buffbasetrigger_type.OnCounterEnd
end

function BattlePerformPlayer:ClusterCompleteCallBack(cluster)
  if _G.BattleManager.isInBattle and not cluster.IsCompleteCallBack then
    cluster.IsCompleteCallBack = true
    self.performingClusterCount = self.performingClusterCount - 1
    if not self.isPause then
      self:TryNextCluster()
    else
      self.NeedResume = true
    end
  end
end

function BattlePerformPlayer:TryNextCluster()
  if 0 == self.performingClusterCount then
    self:PerformNextCluster(0, BattleBudget.clusterDelayTime)
  else
    self:CheckPerformPlayerIsStuck()
  end
end

function BattlePerformPlayer:OnTick(deltaTime)
  self.curMsTime = UpdateManager.Timestamp
  self.FrameStartNodeNum = 0
  if self.isPause then
    return
  end
  for _, v in ipairs(self.performLst) do
    v:OnTickTimeout(deltaTime)
  end
end

function BattlePerformPlayer:RecalcTimeoutDuration(value)
  for _, v in ipairs(self.performLst) do
    v:AddTimeoutDuration(value)
  end
end

function BattlePerformPlayer:Pause()
  self.pauseLock = self.pauseLock + 1
  self:RefreshPauseState()
end

function BattlePerformPlayer:Resume()
  if 0 == self.pauseLock then
    Log.Debug("BattlePerformPlayer:Resume. There is no lock left in perform player")
  elseif self.pauseLock > 0 then
    self.pauseLock = self.pauseLock - 1
  else
    Log.Error("BattlePerformPlayer:Resume. Lock num below zero")
  end
  self:RefreshPauseState()
end

function BattlePerformPlayer:RefreshPauseState()
  if 0 == self.pauseLock then
    self.isPause = false
    if self.NeedResume then
      self.NeedResume = false
      self:TryNextCluster()
    end
  elseif self.pauseLock > 0 then
    self.isPause = true
  else
    self.isPause = false
    if self.NeedResume then
      self.NeedResume = false
      self:TryNextCluster()
    end
    Log.Error("BattlePerformPlayer:RefreshPauseState. Lock num below zero")
  end
end

function BattlePerformPlayer:IsCmdCriticalFailure(result)
  return result == BattleEnum.PerformCmdValidCheckResult.GroupIdxJump or result == BattleEnum.PerformCmdValidCheckResult.RefDeadLoop
end

function BattlePerformPlayer:ProcessCmdValidCheckResult(result)
  if result == BattleEnum.PerformCmdValidCheckResult.RefDeadLoop then
    Log.Error("\232\161\168\230\188\148\229\140\133\229\144\136\230\179\149\230\128\167\230\163\128\230\181\139\239\188\154\230\136\152\230\150\151\230\151\160\230\179\149\231\187\167\231\187\173\239\188\140\232\161\168\230\188\148\230\149\176\230\141\174\229\140\133\229\188\149\231\148\168\230\173\187\229\190\170\231\142\175\229\149\166\239\188\129")
    return false
  elseif result == BattleEnum.PerformCmdValidCheckResult.GroupIdxJump then
    Log.Error("\232\161\168\230\188\148\229\140\133\229\144\136\230\179\149\230\128\167\230\163\128\230\181\139\239\188\154\230\136\152\230\150\151\230\151\160\230\179\149\231\187\167\231\187\173\239\188\140\232\161\168\230\188\148\230\149\176\230\141\174\229\140\133\232\183\179\231\187\132\229\143\183\229\149\166\239\188\129")
    return false
  elseif result == BattleEnum.PerformCmdValidCheckResult.UnexpectedCM0 then
    Log.Error("\232\161\168\230\188\148\229\140\133\229\144\136\230\179\149\230\128\167\230\163\128\230\181\139\239\188\154\230\136\152\230\150\151\229\143\175\232\131\189\230\151\160\230\179\149\231\187\167\231\187\173\239\188\140\232\161\168\230\188\148\230\149\176\230\141\174\229\140\133\230\156\137\229\188\130\229\184\184\231\154\132cm0\229\149\166\239\188\129")
    return true
  end
  return true
end

function BattlePerformPlayer:IsAllGroupHeadPerpormedAndNoPerforming()
  local hasUnperformNode = false
  for i = 1, #self.performLst do
    local node = self.performLst[i]
    if not node:IsPerforming() and not node:IsPerformed() then
      hasUnperformNode = true
    end
    if node:IsGroupHead() then
      if not node:IsPerformed() then
        return false, hasUnperformNode
      end
    elseif node:IsPerforming() then
      return false, hasUnperformNode
    end
  end
  return true, hasUnperformNode
end

function BattlePerformPlayer:GetGroupData(groupID)
  return self.PerformGroupLst[groupID]
end

function BattlePerformPlayer:Free()
  self:DisableUpdate()
  self:Clear()
end

function BattlePerformPlayer:DisableUpdate()
  if self.bUpdateRegistered then
    UpdateManager:UnRegister(self)
    self.bUpdateRegistered = false
  end
end

function BattlePerformPlayer:EnableUpdate()
  if not self.bUpdateRegistered then
    UpdateManager:Register(self)
    self.bUpdateRegistered = true
  end
end

function BattlePerformPlayer:UpdateProcessUI(cmd)
  _G.BattleEventCenter:Dispatch(BattleEvent.START_BATTLE_PERFORM, self, cmd)
end

function BattlePerformPlayer:CheckPerformPlayerIsStuck()
  for _, cluster in pairs(self.PerformClusterLst) do
    if cluster and cluster.IsPerforming then
      return
    end
  end
  Log.Debug("zgx BattlePerformPlayer:PerformComplete:", self.performingClusterCount)
  for id, v in ipairs(self.PerformClusterLst) do
    if not v.IsPerforming and not v.IsPerformed then
      local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\231\142\176\229\156\168\229\188\186\229\136\182\230\146\173\230\148\190\229\143\166\228\184\128\228\184\170Cluster:" .. id
      Log.Error(errorMsg)
      BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
      self.performingClusterCount = 0
      self.performClusterIdxCur = id - 1
      self:PerformNextCluster(0, 0)
      return
    end
  end
  local errorMsg = "zgx\233\152\178\229\141\161\230\173\187\239\188\154\230\179\168\230\132\143\239\188\154\229\174\162\230\136\183\231\171\175\229\143\175\232\131\189\229\183\178\231\187\143\229\141\161\230\173\187\228\186\134\239\188\140\231\142\176\229\156\168\229\188\186\229\136\182\231\187\147\230\157\159"
  BattleReplayCachePool:UploadBattleDataTOCrashSight(errorMsg)
  self.turnPlayer:HandlePerformComplete()
end

function BattlePerformPlayer:GetNonePerformCluster()
  local num = 0
  if self.PerformClusterLst then
    for _, v in ipairs(self.PerformClusterLst) do
      if not v.IsPerformed and not v.IsPerforming then
        num = num + 1
      end
    end
  end
  return num
end

function BattlePerformPlayer:DoFinalize()
  self.IsFinalize = true
  if self.PerformClusterLst then
    for _, cluster in ipairs(self.PerformClusterLst) do
      if cluster.IsPerforming then
        cluster:DoFinalize()
      end
    end
  end
end

function BattlePerformPlayer:GetNodeByExecId(execId)
  if self.performLst then
    for _, node in ipairs(self.performLst) do
      if node:GetExecIdx() == execId then
        return node
      end
    end
  end
end

function BattlePerformPlayer:BuffSkillPlay(pet, skillObject, buffId)
  if self.hadChangeSkillPositionPlayer and pet and skillObject and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY and not skillObject.IsIgnoreCameraAction and _G.SkillUtils.SkillHasCameraAction(skillObject) then
    local battleMainWindow = BattleUtils.GetMainWindow()
    if battleMainWindow then
      battleMainWindow.SkillPanelLoader:SetVisibility(UE4.ESlateVisibility.Collapsed)
      Log.Warning("BattlePerformPlayer:BuffSkillPlayWithCameraAction  Hide Skill panel by buffid=", buffId, skillObject:GetName())
    end
  end
end

function BattlePerformPlayer:Clear()
  self.isRoundBegin = false
  self.PerformGroupLst = {}
  self.PerformClusterLst = {}
  for i = 1, #self.performLst do
    BattlePerformNodePool:Release(self.performLst[i])
  end
  self.performLst = {}
  self.performClusterIdxCur = 1
  self.performNodeIdx = 0
  self.performingClusterCount = 0
  self.performComboClusterLst = {}
  self.cmdValidCheckResult = BattleEnum.PerformCmdValidCheckResult.Success
  self.PerformedBuffInfo = {}
  self.PerformedPopInfo = {}
  self.PerformedEffectPopInfo = {}
  self.hadChangeSkillPositionPlayer = false
end

return BattlePerformPlayer
