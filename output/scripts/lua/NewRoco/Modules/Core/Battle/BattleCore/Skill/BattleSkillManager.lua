local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleModuleCmd = require("NewRoco.Modules.Core.Battle.BattleModuleCmd")
local CachedSkillObj = NRCClass()

function CachedSkillObj:Ctor()
  self.skillID = nil
  self.path = nil
  self.skillCla = nil
  self.skillObj = nil
  self.isResLoaded = false
  self.isSkillResReady = false
  self.fromTraceback = nil
  self.callbackList = nil
end

function CachedSkillObj:AddCallBackList(callBackOwner, callback, paramList)
  if self.callbackList == nil then
    self.callbackList = {}
  end
  if RocoEnv.IS_EDITOR then
    self.fromTraceback = debug.traceback()
  end
  for i, v in ipairs(self.callbackList) do
    if v.owner == callBackOwner and v.callbackFunc == callback then
      Log.Error("CachedSkillObj:AddCallBackList \233\135\141\229\164\141\230\183\187\229\138\160")
      return
    end
  end
  table.insert(self.callbackList, {
    owner = callBackOwner,
    callbackFunc = callback,
    paramList = paramList
  })
end

function CachedSkillObj:OnLoadComplete(isSucceed)
  if not self.callbackList then
    return
  end
  for i, v in ipairs(self.callbackList) do
    if v.owner and v.callbackFunc then
      v.callbackFunc(v.owner, isSucceed, self.path, table.unpack(v.paramList))
    end
  end
  self.callbackList = nil
end

local BattleSkillManager = NRCClass()

function BattleSkillManager:Ctor()
  self.maxPoolSize = 10
  self.recycleTime = 30
  self.freeSkillLst = {}
  self.workingSkillLst = {}
  WeakTable(self.workingSkillLst)
  self.skillObjToSkillComponent = {}
  WeakTable(self.skillObjToSkillComponent)
  self.skillObjRef = {}
  WeakTable(self.skillObjRef)
  self.cacheSkillObjDict = {}
  self.resRequestLst = {}
  self.refLst = {}
end

function BattleSkillManager:GetResChangeSkillPath(skillId)
  local skillResChange = _G.DataConfigManager:GetSkillResChangeConf(SkillUtils.CheckSkillId(skillId), true)
  if skillResChange then
    return skillResChange.res_id
  end
end

function BattleSkillManager:OnCurveLoaded(resPath)
end

function BattleSkillManager:PreProcessPerformCMDToReslist(cmd, settle_info)
  local resList = {}
  local filterSet = {}
  
  local function TryAddLst(value)
    if not value then
      Log.Debug("BattleSkillManager PreProcessPerformCMDToReslist: cannt find res path")
      return
    end
    if not string.StartsWith(value, "/Game/ArtRes/Effects") then
      Log.Error("BattleSkillManager PreProcessPerformCMDToReslist: Path Error", value)
      return
    end
    if filterSet[value] then
      return
    end
    if self:IsResLoaded(value) then
      return
    end
    filterSet[value] = 1
    Log.Debug("BattleSkillManager TryAddLst:", value)
    table.insert(resList, value)
  end
  
  if cmd.perform_info then
    for i = 1, #cmd.perform_info do
      local performInfo = cmd.perform_info[i]
      if performInfo.type == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
        local skillID = performInfo.skill_cast.skill_id
        local skillResPath, isExist = SkillUtils.GetSkillResID(skillID)
        if isExist then
          TryAddLst(skillResPath)
        end
        local changeRes = self:GetResChangeSkillPath(skillID)
        if changeRes then
          TryAddLst(changeRes)
        end
        BattleResourceManager:LoadAssetAsync(self, BattleConst.AttackHitSpeedCurve, self.OnCurveLoaded)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
        local skillID = performInfo.combo_skill_cast.skill_id
        local skillResPath, isExist = SkillUtils.GetSkillResID(skillID)
        if isExist then
          TryAddLst(skillResPath)
        end
        local changeRes = self:GetResChangeSkillPath(skillID)
        if changeRes then
          TryAddLst(changeRes)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
        local buff_change = performInfo.buff_change
        local RealBuffID = buff_change.buff_id
        local buffResPath, isExist = SkillUtils.GetBuffResID(RealBuffID, buff_change.type)
        if isExist then
          TryAddLst(buffResPath)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_CATCH_PET then
        local BattleCatchPetInfo = performInfo.catch_pet_info
        if BattleUtils.IsTeam() and BattleCatchPetInfo.success then
          TryAddLst(BattleConst.TeamBloodCatchSuccess)
        end
        TryAddLst(BattleConst.Define.CATCH_SKILL)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
        local buff_trigger = performInfo.buff_trigger
        local RealBuffID = buff_trigger.buff_id
        local buffResPath, isExist = SkillUtils.GetBuffResID(RealBuffID, buff_trigger.perform_type)
        if isExist then
          TryAddLst(buffResPath)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
        local resPath
        if performInfo.change_pet.perform_type == ProtoEnum.ChangePetPerformType.CPPT_NO_BALL then
          resPath = BattleConst.NoBallHuanChong
        else
          local Player = BattleManager.battlePawnManager:GetPlayerByGuid(performInfo.change_pet.player_id)
          if Player then
            if Player.teamEnm == BattleEnum.Team.ENUM_TEAM then
              if BattleUtils.IsNpcAssist() and Player:IsAssistNpc() then
                resPath = BattleConst.EnemyHuanChong
              else
                resPath = BattleUtils.GetChangePetPathBySuit(Player, performInfo.change_pet.battle_pet_info.battle_inside_pet_info.base_conf_id)
                local noSuitRes = BattleUtils.GetChangePetPathBySuit(Player, -1)
                if noSuitRes ~= resPath then
                  TryAddLst(noSuitRes)
                end
              end
              local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.RecallPet)
              TryAddLst(SkillResConf.res_id)
            else
              resPath = BattleUtils.GetChangePetPathBySuit(Player, performInfo.change_pet.battle_pet_info.battle_inside_pet_info.base_conf_id)
              local noSuitRes = BattleUtils.GetChangePetPathBySuit(Player, -1)
              if noSuitRes ~= resPath then
                TryAddLst(noSuitRes)
              end
              TryAddLst(BattleConst.EnemyRecallPet)
            end
          else
            TryAddLst(BattleConst.HuanChong)
          end
        end
        TryAddLst(resPath)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL then
        TryAddLst(self:GetChangeModelRes())
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BOX_SHIELD_BREAK then
        local firstSkill, secondeSkill = self:GetSurpriseBoxShieldBreakRes(performInfo.box_shield_break)
        if firstSkill then
          TryAddLst(firstSkill)
        end
        if secondeSkill then
          TryAddLst(secondeSkill)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DEATH then
        local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDead)
        if SkillResConf then
          TryAddLst(SkillResConf.res_id)
        end
        local resPath = self:GetDepthSkillRes(performInfo.dead_info)
        if resPath then
          TryAddLst(resPath)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_REVIVE then
        local resPath
        local target = BattleManager.battlePawnManager:GetCardByGuid(performInfo.revive_info.caster_id)
        if target then
          resPath = target.AppearancePath:GetHuanChong()
          TryAddLst(resPath)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_PET_ESCAPE then
        TryAddLst(_G.DataConfigManager:GetBattleGlobalConfig("1vn_escape_res").str)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
        local resPath = _G.DataConfigManager:GetSkillConf(performInfo.role_skill_cast.skill_id)
        if resPath then
          TryAddLst(resPath.res_id)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
        local effect_id = performInfo.effect_trigger.effect_id
        TryAddLst(self:GetEffectSkillRes(effect_id))
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DAMAGE then
        local isTrigger = performInfo.damage_info.execution or false
        if isTrigger then
          TryAddLst(BattleConst.WorldLeaderEnterReward)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_SUPPLY_PET then
        local List = self:GetSupplyPetRes(performInfo.supply_pet)
        for _, v in ipairs(List) do
          TryAddLst(v)
        end
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_AI then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BAG_TO_PREPARE then
        TryAddLst(BattleConst.TerritoryTrial.CommonBagToPrepare)
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_PREPARE_TO_BATTLE then
        local prepareToBattle = performInfo and performInfo.prepare_to_battle
        local petId = prepareToBattle and prepareToBattle.pet_id
        local battlePet = _G.BattleManager.battlePawnManager:GetPetByGuid(petId)
        local card = battlePet and battlePet.card
        local petInfo = card and card.petInfo
        local insideInfo = petInfo and petInfo.battle_inside_pet_info
        local trialInfo = insideInfo and insideInfo.trial_pet_info
        local isBoss = trialInfo and trialInfo.is_boss
        if isBoss then
          TryAddLst(BattleConst.TerritoryTrial.BossPrepareToBattle)
        end
      end
    end
  end
  if BattleUtils.IsWorldLeaderFight() and cmd.is_battle_finished and settle_info then
    if BattleUtils.IsBattleWin(settle_info.result) then
      TryAddLst(BattleConst.WorldLeaderSuccessExit[1])
      TryAddLst(BattleConst.WorldLeaderSuccessExit[2])
    else
      TryAddLst(BattleConst.WorldLeaderFailExit[1])
      TryAddLst(BattleConst.WorldLeaderFailExit[2])
    end
  end
  self.beginPreloadSkillResTime = os.msTime()
  if 0 == #resList then
    self.donePreloadSkillResTime = os.msTime()
    Log.Debug("BattleSkillManager preload skill cost time:", self.donePreloadSkillResTime - self.beginPreloadSkillResTime)
    BattleEventCenter:Dispatch(BattleEvent.OnAllSkillResLoaded)
  else
    self:PreLoadRes(resList, true)
  end
end

function BattleSkillManager:GetDepthSkillRes(dead_info)
  local target = BattleManager.battlePawnManager:GetCardByGuid(dead_info.target_id)
  local Player = target and target.owner
  local deathExist = BattleUtils.IsDeathExist(target)
  if deathExist then
    local value = target:GetMonsterConfigIsNightmareValue()
    if value and 2 == value and 1 == deathExist then
      return BattleConst.NightmarePetDeadWithStun
    end
    if BattleUtils.IsSkipRecycleBall() then
      return BattleConst.PetDeadWithStunNoBall
    else
      return BattleConst.PetDeadWithStun
    end
  end
  if BattleUtils.IsWorldLeaderFight() and Player and Player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return BattleConst.WorldLeaderDie
  elseif dead_info.dead_type == ProtoEnum.BattleDeadInfo.DeadType.BLOW_AWAY then
    return BattleConst.PetDeadBlowAway
  elseif BattleUtils.IsFinalBattleP1() then
    return BattleConst.PetDeadFinalBattle
  elseif Player and Player:IsSpecialNoPcSelfDead() then
    return BattleConst.PetDeadNoPc
  elseif Player and Player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    if BattleUtils.IsFinalBattleP2() then
      return BattleConst.EnemyDeadFinalBattleBlackScreen
    elseif BattleUtils.IsB1FinalBattleP1() then
      return BattleConst.B1P1EnemyDeadG6
    end
  end
  if Player then
    if Player.model then
      if Player.teamEnm == BattleEnum.Team.ENUM_TEAM then
        local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDeadWithPlayerTeam)
        return SkillResConf.res_id
      else
        local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDeadWithPlayerEnemy)
        return SkillResConf.res_id
      end
    else
      local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDead)
      if SkillResConf then
        return SkillResConf.res_id
      end
    end
  else
    Log.Warning("zgx \230\137\190\228\184\141\229\136\176\230\173\187\228\186\161\229\174\160\231\137\169\231\154\132\228\191\161\230\129\175")
    local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDeadWithPlayerEnemy)
    return SkillResConf.res_id
  end
end

function BattleSkillManager:GetEffectSkillRes(effect_id)
  local effect = _G.DataConfigManager:GetEffectConf(effect_id)
  if effect and effect.effect_order == Enum.EffectType.ET_ANIMATION and effect.effect_param and effect.effect_param[1] and effect.effect_param[1].params then
    local resId = effect.effect_param[1].params[1] or 0
    local SkillResConf = DataConfigManager:GetSkillResConf(resId, true)
    if SkillResConf and SkillResConf.res_id then
      return SkillResConf.res_id
    end
  end
end

function BattleSkillManager:GetSupplyPetRes(supplyInfo)
  local ResList
  if BattleUtils.IsFinalBattleP1() then
    ResList = {
      BattleConst.FinalBattleHuanChong
    }
    return ResList
  elseif BattleUtils.IsFinalBattleP2() then
    ResList = {
      BattleConst.FinalBattleP2Debut
    }
    return ResList
  else
    local player = BattleManager.battlePawnManager:GetPlayerByGuid(supplyInfo.player_id)
    if player then
      if player.teamEnm == BattleEnum.Team.ENUM_TEAM then
        if BattleUtils.IsNpcAssist() and player:IsAssistNpc() then
          ResList = {
            BattleConst.EnemyHuanChong
          }
          return ResList
        end
      elseif BattleUtils.IsWildEnemy() then
        local BattleConf = BattleUtils.GetCurrentBattleConf()
        ResList = {
          BattleUtils.GetWildSupplySkillRes(BattleConf)
        }
        return ResList
      elseif BattleUtils.IsB1FinalBattleP1() then
        ResList = {
          BattleConst.B1P1EnemyCallOutG6
        }
        return ResList
      end
      if supplyInfo.pet_infos then
        ResList = {}
        for _, pet_info in ipairs(supplyInfo.pet_infos) do
          table.insert(ResList, BattleUtils.GetChangePetPathBySuit(player, pet_info.pet_info.battle_inside_pet_info.base_conf_id))
        end
        table.insert(ResList, BattleUtils.GetChangePetPathBySuit(player, -1))
      else
        Log.Error("zgx \230\137\190\228\184\141\229\136\176\232\161\165\229\174\160\231\154\132\229\175\185\232\177\161")
      end
    end
  end
  return ResList or {}
end

function BattleSkillManager:GetChangeModelRes()
  if BattleUtils.IsB1FinalBattleP3() then
    return BattleConst.B1P3EvolutionG6
  else
    local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetChangeModel)
    return SkillResConf.res_id
  end
end

function BattleSkillManager:GetSurpriseBoxShieldBreakRes(BoxShieldBreak)
  local firstSkillPath, secondSkillPath
  firstSkillPath = _G.BattleConst.SurpriseBoxShieldBreak.MutationsSkillPath
  secondSkillPath = _G.BattleConst.SurpriseBoxShieldBreak.NormalPetSkillPath
  return firstSkillPath, secondSkillPath
end

function BattleSkillManager:IsSkillResLoaded(skillID)
  local skillResPath = SkillUtils.GetSkillResID(skillID)
  return self:IsResLoaded(skillResPath)
end

function BattleSkillManager:IsBuffResLoaded(buffID, type)
  local buffResPath = SkillUtils.GetBuffResID(buffID, type)
  return self:IsResLoaded(buffResPath)
end

function BattleSkillManager:IsResLoaded(resPath)
  return self.cacheSkillObjDict[resPath] and self.cacheSkillObjDict[resPath].isResLoaded
end

function BattleSkillManager:IsResReady(resPath)
  return self.cacheSkillObjDict[resPath] and self.cacheSkillObjDict[resPath].isSkillResReady
end

function BattleSkillManager:GetLoadedClass(resPath, ignoreLog)
  if not ignoreLog then
    for k, v in pairs(self.cacheSkillObjDict) do
      Log.Debug("path:", k, v.skillCla)
    end
  end
  local asset = BattleResourceManager:GetCacheAssetDirect(resPath, true)
  if asset then
    return asset
  end
  if self.cacheSkillObjDict[resPath] then
    return self.cacheSkillObjDict[resPath].skillCla
  end
  if "Unknown" == resPath then
    return
  end
  if not ignoreLog then
    Log.Error("BattleSkillManager GetLoadedClass \232\142\183\229\143\150\233\162\132\229\138\160\232\189\189\229\175\185\232\177\161\229\164\177\232\180\165:", resPath)
  end
  return nil
end

function BattleSkillManager:GetAndClearCache(resPath)
  local res = self.cacheSkillObjDict[resPath]
  self.cacheSkillObjDict[resPath] = nil
  return res
end

function BattleSkillManager:PreLoadRes(resList, needFormat, priority)
  if nil == needFormat then
    needFormat = true
  end
  self.beginPreloadSkillResTime = os.msTime()
  for i = 1, #resList do
    self:PreLoadSingleResInternal(resList[i], needFormat, priority)
  end
end

function BattleSkillManager:PreLoadSingleResInternal(resPath, needFormat, priority, callBackOwner, callback, ...)
  priority = priority or PriorityEnum.Passive_Battle_SkillDefault
  if self.cacheSkillObjDict[resPath] then
    if self.cacheSkillObjDict[resPath].isResLoaded then
      Log.Debug("zgx res has been loaded ,path is ", resPath)
      BattleEventCenter:Dispatch(BattleEvent.OnSkillResLoaded, resPath)
      self:OnLoadSkillComplete()
      if callback then
        callback(callBackOwner, true, self.cacheSkillObjDict[resPath].path, ...)
      end
    else
      self.cacheSkillObjDict[resPath]:AddCallBackList(callBackOwner, callback, {
        ...
      })
      Log.Debug("zgx res is loading now ,path is ", resPath)
    end
    return
  end
  self.cacheSkillObjDict[resPath] = CachedSkillObj()
  local cachedSkillObj = self.cacheSkillObjDict[resPath]
  cachedSkillObj.path = resPath
  cachedSkillObj.loadBeginTime = os.msTime()
  cachedSkillObj:AddCallBackList(callBackOwner, callback, {
    ...
  })
  local formatedPath = needFormat and _G.NRCUtils.FormatBlueprintAssetPath(resPath) or resPath
  local resRequest = _G.BattleResourceManager:LoadAssetAsync(self, formatedPath, function(caller, skillCla, battleRequest)
    if not skillCla:IsA(UE.UClass) then
      Log.Error("BattleSkillManager:PreLoadSingleResInternal fail,skillClas is not a UClass:", resPath, formatedPath)
      return
    end
    local battleFieldActor = BattleUtils.GetBattleFieldActor()
    local isOnSkillAsyncLoadCompleteValidFunction = UE4.UObject.IsValid(battleFieldActor) and type(battleFieldActor.OnSkillAsyncLoadComplete) == "function"
    if not isOnSkillAsyncLoadCompleteValidFunction then
      Log.Error("BattleSkillManager:PreLoadSingleResInternal battleFieldActor.OnSkillComplete is not a valid function")
    end
    if UE4.UObject.IsValid(battleFieldActor) and battleFieldActor.Skill and isOnSkillAsyncLoadCompleteValidFunction then
      local rocoSkill = battleFieldActor.Skill
      local skillObj = rocoSkill:AddSkillObjFromClassAndReturn(skillCla)
      if not skillObj or not UE4.UObject.IsValid(skillObj) then
        self.cacheSkillObjDict[resPath] = nil
        BattleEventCenter:Dispatch(BattleEvent.OnSkillResLoaded, resPath)
        self:OnLoadSkillComplete()
        cachedSkillObj:OnLoadComplete(false)
        Log.Error("BattleSkillManager:PreLoadSingleResInternal fail,resPath:", resPath)
        return
      end
      table.insert(self.refLst, UnLua.Ref(skillCla))
      table.insert(self.refLst, UnLua.Ref(skillObj))
      table.insert(self.skillObjRef, skillObj)
      cachedSkillObj.skillCla = skillCla
      cachedSkillObj.skillObj = skillObj
      cachedSkillObj.loadedCompleteTime = os.msTime()
      cachedSkillObj.isResLoaded = true
      cachedSkillObj.path = resPath
      BattleEventCenter:Dispatch(BattleEvent.OnSkillBeforeAsync, resPath, skillObj)
      skillObj:SetPriority(priority)
      skillObj.OnAsyncLoadCompleted:Add(battleFieldActor, battleFieldActor.OnSkillAsyncLoadComplete)
      skillObj:StartAsyncLoading()
    else
      Log.Error("BattleSkillManager:PreLoadSingleResInternal fail,resPath 2:", resPath)
      self.cacheSkillObjDict[resPath] = nil
      BattleEventCenter:Dispatch(BattleEvent.OnSkillResLoaded, resPath)
      self:OnLoadSkillComplete()
      cachedSkillObj:OnLoadComplete(false)
    end
  end, function(caller, skillCla)
    Log.Error("\233\162\132\229\138\160\232\189\189\232\181\132\230\186\144\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129 path  ", resPath)
    self.cacheSkillObjDict[resPath] = nil
    BattleEventCenter:Dispatch(BattleEvent.OnSkillResLoaded, resPath)
    self:OnLoadSkillComplete()
    cachedSkillObj:OnLoadComplete(false)
  end, nil, nil, nil, priority)
  self.resRequestLst[resRequest] = 1
end

function BattleSkillManager:PreLoadSingleRes(resPath, needFormat, callBackOwner, callback, ...)
  self.beginPreloadSkillResTime = os.msTime()
  self:PreLoadSingleResInternal(resPath, needFormat, PriorityEnum.Passive_Battle_Default, callBackOwner, callback, ...)
end

function BattleSkillManager:ReleaseRequest(resRequest)
  NRCResourceManager:UnLoadRes(resRequest.request)
  self.resRequestLst[resRequest] = nil
end

function BattleSkillManager:ReleaseAllRequest()
  for k, v in pairs(self.resRequestLst) do
    self:ReleaseRequest(k)
  end
end

function BattleSkillManager:OnLoadSkillComplete(skillObj)
  Log.Debug("BattleSkillManager:OnLoadSkillComplete()", skillObj or "nil")
  local battleFieldActor = BattleUtils.GetBattleFieldActor()
  if skillObj and battleFieldActor then
    skillObj.OnAsyncLoadCompleted:Remove(battleFieldActor, battleFieldActor.OnSkillAsyncLoadComplete)
  end
  local isAllDone = true
  for resPath, cachedSkillObj in pairs(self.cacheSkillObjDict) do
    if cachedSkillObj.skillObj and cachedSkillObj.skillObj == skillObj then
      cachedSkillObj.isSkillResReady = true
      cachedSkillObj.actionReadyTime = os.msTime()
      cachedSkillObj:OnLoadComplete(true)
      Log.Debug("BattleSkillManager load skill with res complete:", cachedSkillObj.path)
      BattleEventCenter:Dispatch(BattleEvent.OnSkillResLoaded, cachedSkillObj.path)
    end
    if not cachedSkillObj.isSkillResReady then
      isAllDone = false
    end
  end
  if isAllDone then
    self.donePreloadSkillResTime = os.msTime()
    if self.beginPreloadSkillResTime then
      Log.Debug("BattleSkillManager preload skill cost time:", self.donePreloadSkillResTime - self.beginPreloadSkillResTime)
    end
    BattleEventCenter:Dispatch(BattleEvent.OnAllSkillResLoaded)
  end
end

function BattleSkillManager:ClearCache()
  local pets = BattleManager.battlePawnManager:GetAllPets()
  for i = 1, #pets do
    if pets[i] and pets[i].model and UE4.UObject.IsValid(pets[i].model) and pets[i].model.RocoSkill then
      pets[i].lastAnimSkill = nil
      local rocoSkill = pets[i].model.RocoSkill
      rocoSkill:ClearNotworkingSkillObj()
    end
  end
  local players = BattleManager.battlePawnManager:GetInFieldAllPlayers()
  if players then
    for i = 1, #players do
      if players[i] and players[i].model and UE4.UObject.IsValid(players[i].model) and players[i].model.RocoSkill then
        local rocoSkill = players[i].model.RocoSkill
        rocoSkill:ClearNotworkingSkillObj()
      end
    end
  end
  if BattleManager.vBattleField.battleFieldActor and BattleManager.vBattleField.battleFieldActor.Skill then
    BattleManager.vBattleField.battleFieldActor.Skill:ClearNotworkingSkillObj()
  end
  for i = 1, #self.skillObjRef do
    if self.skillObjRef[i] then
      self.skillObjRef[i]:Destroy()
    end
  end
  self.cacheSkillObjDict = {}
  for _, objRef in pairs(self.refLst) do
    if UE.UObject.IsValid(objRef) then
      UnLua.Unref(objRef)
    end
  end
  self.refLst = {}
end

function BattleSkillManager:ClearLocalPlayerSkill()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.viewObj then
    SkillUtils.ClearSkillObj(localPlayer.viewObj.RocoSkill)
  end
end

function BattleSkillManager:PrepareSkill(battlePet, skillComponent, CastParam, isUseCache)
  if nil == isUseCache then
    isUseCache = true
  end
  battlePet = battlePet or {}
  local view = battlePet.model or battlePet.viewObj
  local rocoSkillComponent, skillObj = self:PrepareSkillInternal(view, battlePet, skillComponent, CastParam, isUseCache)
  if not skillObj then
    return
  end
  if battlePet.model then
    skillObj:RegisterRawCallback(battlePet, battlePet.OnSkillEvent)
  end
  table.insert(self.workingSkillLst, skillObj)
  Log.Debug("SkillManager prepare skill:", skillObj:GetName())
  return rocoSkillComponent, skillObj
end

function BattleSkillManager:PrepareSkillInternal(view, battlePet, skillComponent, CastParam, isUseCache)
  if not skillComponent then
    Log.Error("PrepareSkillInternal skillComponent is null, res path")
    return
  end
  local rocoSkillComponent = skillComponent
  Log.Debug("BattleSkillManager PrepareSkill:", rocoSkillComponent)
  local skillObj = self:GetSkillObj(skillComponent, CastParam, isUseCache)
  if not skillObj then
    if CastParam.CompleteCallback then
      CastParam.CompleteCallback(CastParam.CallbackOwner)
    end
    return
  end
  local blackboard = skillObj:GetBlackboard()
  if blackboard and UE.UObject.IsValid(blackboard) then
    if BattleUtils.IsTeam() or BattleUtils.IsWorldLeaderFight() then
      blackboard:SetValueAsString("ShowPetForCE", "ShowPetForCE")
    end
    if CastParam.BlackStringValue then
      for i, v in pairs(CastParam.BlackStringValue) do
        blackboard:SetValueAsString(i, v)
      end
    end
  end
  if CastParam.ActorStringValue then
    for actor, v in pairs(CastParam.ActorStringValue) do
      for _, key in ipairs(v) do
        skillObj:AddIndividualKey(actor, key)
      end
    end
  end
  self.skillObjToSkillComponent[skillObj] = rocoSkillComponent
  skillObj.CleanupMaterials = true
  skillObj:SetCaster(CastParam.Caster)
  skillObj:SetCounterActor(CastParam.CounterActor)
  skillObj:SetBeCounterActor(CastParam.BeCounterActor)
  if CastParam.Characters then
    skillObj:SetCharacters(CastParam.Characters)
  else
    local pawnManager = _G.BattleManager.battlePawnManager
    skillObj:SetCharacters(pawnManager:GetAllPawnActorForSkill())
  end
  skillObj:SetPower(CastParam.Power)
  if CastParam.IsBuffShow then
    skillObj:SetTargets({view})
  else
    skillObj:SetIsRestrained(CastParam.IsRestrained)
    skillObj:SetIsRestraint(CastParam.IsRestraint)
    skillObj:SetReduceHP(CastParam.ReduceHP)
    skillObj:SetPassive(CastParam.IsPassive)
    skillObj:SetDynamicData(CastParam.DynamicData)
    local targetPets = CastParam.TargetPets
    local petModels = {}
    if targetPets then
      for i = 1, #targetPets do
        if targetPets[i].model then
          table.insert(petModels, targetPets[i].model)
        else
          Log.Error("battle pet without model!!")
        end
      end
    end
    skillObj:SetTargets(petModels)
    if CastParam.AcceptPreEnd then
      SkillUtils.SetEarlyEnd(skillObj)
    end
  end
  local battleFieldActor = BattleManager.vBattleField.battleFieldActor
  if battleFieldActor and battleFieldActor.Skill then
    skillObj.OnAsyncLoadCompleted:Add(battleFieldActor, battleFieldActor.OnSkillCompleteReal)
    skillObj:StartAsyncLoading()
  end
  if CastParam.OnLastHitCallBack then
    local damages = {}
    local LogicHits, AnimHits = SkillUtils.GetSkillHitPoints(skillObj)
    local last = math.max(LogicHits[#LogicHits] or 0, 0)
    Log.DebugFormat("Binding Last Attack %f", last)
    skillObj:BindLuaEvent(last, "Last")
  end
  local findFirstHit = true
  if CastParam.OnTriggerBeforeHitCallback then
    local LogicHits, AnimHits = SkillUtils.GetSkillHitPoints(skillObj)
    if nil == AnimHits or 0 == #AnimHits then
      Log.DebugFormat("Binding First Attack not found")
      findFirstHit = false
    else
      local first = self:GetFirstHit(AnimHits)
      first = math.max(first - 0.1 or 0, 0)
      Log.DebugFormat("Binding First Attack %f", first)
      skillObj:BindLuaEvent(first, "TriggerBeforeHit")
    end
  end
  self:ModifyShinengSkill(skillObj, CastParam, battlePet)
  if CastParam.Interrupt then
    local Skill = rocoSkillComponent:GetActiveSkill()
    if Skill then
      rocoSkillComponent:CancelSkill(Skill, UE4.ESkillActionResult.SkillActionResultInterrupted)
    end
  end
  if _G.BattleManager.battlePawnManager.TeamatePlayer then
    skillObj.BattleGenderType = _G.BattleManager.battlePawnManager.TeamatePlayer.roleInfo.base.sex or 0
  end
  if BattleUtils.IsDeepWater() then
    skillObj.BattleFieldLimitType = UE.EBattleFieldLimitType.Water
  else
    skillObj.BattleFieldLimitType = UE.EBattleFieldLimitType.Ground
  end
  if battlePet and battlePet.card and battlePet.card:IsCheerPet() then
    skillObj.IsIgnoreCameraAction = true
  end
  self:RegisterEventCallback(skillObj, CastParam, findFirstHit)
  return rocoSkillComponent, skillObj
end

function BattleSkillManager:GetSkillObj(skillComponent, CastParam, isUseCache)
  local skillObj
  if not isUseCache then
    skillObj = skillComponent:AddSkillObjFromClassAndReturn(CastParam.SkillClass)
    if not skillObj then
      local rocoSkillComp = _G.BattleManager.battlePawnManager.TeamatePlayer.model.RocoSkill
      skillObj = rocoSkillComp:AddSkillObjFromClassAndReturn(CastParam.SkillClass)
      Log.Error("\232\167\166\229\143\145\229\136\155\229\187\186\230\138\128\232\131\189\229\188\130\229\184\184\239\188\140\232\175\183\228\191\157\229\173\152\230\136\152\230\150\151\230\149\176\230\141\174\229\185\182\229\143\145\231\187\153lance")
    end
  else
    local resPath
    if not CastParam.SkillClass then
      if CastParam.skillID or CastParam.buffID then
        if CastParam.IsBuffShow then
          resPath = SkillUtils.GetBuffResID(CastParam.buffID, CastParam.perform_type)
        else
          resPath = SkillUtils.GetSkillResID(CastParam.skillID)
        end
      elseif CastParam.ResID then
        resPath = CastParam.ResID
      end
    end
    if CastParam.SkillClass then
      skillObj = skillComponent:AddSkillObjFromClassAndReturn(CastParam.SkillClass)
    elseif self:IsResLoaded(resPath) then
      skillObj = skillComponent:AddSkillObjFromClassAndReturn(self:GetLoadedClass(resPath))
    else
      Log.Error("BattleSkillManager:PrepareSkillInternal \230\178\161\230\156\137\233\162\132\229\138\160\232\189\189\232\181\132\230\186\144\239\188\140\230\151\160\230\179\149\233\135\138\230\148\190\230\138\128\232\131\189")
    end
  end
  table.insert(self.skillObjRef, skillObj)
  return skillObj
end

function BattleSkillManager:ModifyShinengSkill(skillObj, CastParam, battlePet)
  if battlePet and CastParam.SpType >= 0 and battlePet.PlayShineng then
    local actions = skillObj:GetAllActions()
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action:IsA(UE4.URocoCharacterMaterialModifyAction) then
        local params = action.Parameters
        for j = 1, params:Length() do
          local param = params:GetRef(j)
          if param.ParamName == "FresnelCo0lor" and skillObj.MColor then
            local color = skillObj.MColor:Get(skillObj.TypeImage:Get(CastParam.SpType + 1) + 1)
            param.VectorParam.R = color.R / 255
            param.VectorParam.G = color.G / 255
            param.VectorParam.B = color.B / 255
          end
        end
        break
      end
    end
    for i = 1, actions:Length() do
      local action = actions:Get(i)
      if action:IsA(UE4.URocoPlayFxSystemAction) and action.FxSystemAsset then
        battlePet:PlayShiNeng(CastParam.SpType, action.FxSystemAsset)
      end
    end
  end
end

function BattleSkillManager:RegisterEventCallback(skillObj, CastParam, findFirstHit)
  skillObj:RegisterEventCallback("End", CastParam.CallbackOwner, CastParam.CompleteCallback)
  skillObj:RegisterEventCallback("PreEnd", CastParam.CallbackOwner, CastParam.CompleteCallback)
  skillObj:RegisterEventCallback("PreEndAnim", CastParam.CallbackOwner, CastParam.CompleteCallback)
  skillObj:RegisterEventCallback("HideBuffBar", CastParam.CallbackOwner, CastParam.HideBuffBarCallback)
  skillObj:RegisterEventCallback("ShowBuffBar", CastParam.CallbackOwner, CastParam.ShowBuffBarCallback)
  skillObj:RegisterEventCallback("HideTargetsBuffBar", CastParam.CallbackOwner, CastParam.HideTargetsBuffBarCallback)
  skillObj:RegisterEventCallback("ShowTargetsBuffBar", CastParam.CallbackOwner, CastParam.ShowTargetsBuffBarCallback)
  skillObj:RegisterEventCallback("HideHPBar", CastParam.CallbackOwner, CastParam.HideHPBarCallback)
  skillObj:RegisterEventCallback("ShowHPBar", CastParam.CallbackOwner, CastParam.ShowHPBarCallback)
  skillObj:RegisterEventCallback("FlyEnergy", CastParam.CallbackOwner, CastParam.OnFlyEnergyCallback)
  skillObj:RegisterEventCallback("HidePopUp", CastParam.CallbackOwner, CastParam.HidePopupCallback)
  skillObj:RegisterEventCallback("ShowPopUp", CastParam.CallbackOwner, CastParam.ShowPopupCallback)
  skillObj:RegisterEventCallback("OpenUI", CastParam.CallbackOwner, CastParam.OpenUICallback)
  skillObj:RegisterEventCallback("CancelBeCountSkill", CastParam.CallbackOwner, CastParam.InterruptBeCounterSkill)
  skillObj:RegisterEventCallback("OtherPetPerform", CastParam.CallbackOwner, CastParam.OnOtherPetPerformCallback)
  skillObj:RegisterEventCallback("OnRemoveCutsceneBlackGround", CastParam.CallbackOwner, CastParam.OnRemoveCutsceneBlackGround)
  skillObj:RegisterEventCallback("SkillCounter", CastParam.CallbackOwner, CastParam.OnCounterCallback)
  skillObj:RegisterEventCallback("SkillInterrupt", CastParam.CallbackOwner, CastParam.OnInterruptCallback)
  skillObj:RegisterEventCallback("SkillCoping", CastParam.CallbackOwner, CastParam.OnCopingCallback)
  skillObj:RegisterEventCallback("TriggerBeHit", CastParam.CallbackOwner, CastParam.OnHitCallback)
  if CastParam.OnSkillBreakCallback then
    skillObj:RegisterEventCallback("Interrupt", CastParam.CallbackOwner, CastParam.OnSkillBreakCallback)
  else
    skillObj:RegisterEventCallback("Interrupt", CastParam.CallbackOwner, CastParam.CompleteCallback)
  end
  if CastParam.OnStartFailedCallback then
    skillObj:RegisterEventCallback("StartFailed", CastParam.CallbackOwner, CastParam.OnStartFailedCallback)
  else
    skillObj:RegisterEventCallback("StartFailed", CastParam.CallbackOwner, CastParam.CompleteCallback)
  end
  skillObj:RegisterEventCallback("RoleMagicTrigger", CastParam.CallbackOwner, CastParam.OnRoleMagicChangeModelCallback)
  skillObj:RegisterEventCallback("BeingAttacked", CastParam.CallbackOwner, CastParam.OnBeingAttackedCallback)
  if CastParam.OnTriggerBeforeHitCallback then
    if findFirstHit then
      skillObj:RegisterEventCallback("TriggerBeforeHit", CastParam.CallbackOwner, CastParam.OnTriggerBeforeHitCallback)
    else
      skillObj:RegisterEventCallback("TriggerBeHit", CastParam.CallbackOwner, CastParam.OnTriggerBeforeHitCallback)
    end
  end
  if CastParam.SkipMeleeBackswingCallback then
    skillObj:RegisterEventCallback("SkipMeleeBackswing", CastParam.CallbackOwner, CastParam.SkipMeleeBackswingCallback)
  end
  if CastParam.SkipRangedBackswingCallback then
    skillObj:RegisterEventCallback("SkipRangedBackswing", CastParam.CallbackOwner, CastParam.SkipRangedBackswingCallback)
  end
  skillObj:RegisterEventCallback("Last", CastParam.CallbackOwner, CastParam.OnLastHitCallBack)
  skillObj:RegisterEventCallback("AnimationHit", CastParam.CallbackOwner, CastParam.OnAnimCallback)
  skillObj:RegisterEventCallback("TriggerBeHitAnim", CastParam.CallbackOwner, CastParam.OnHitAnimCallback)
  skillObj:RegisterEventCallback("TriggerBeHitCombo", CastParam.CallbackOwner, CastParam.OnHitComboCallback)
  skillObj:RegisterEventCallback("CounterEnd", CastParam.CallbackOwner, CastParam.OnCounterEndCallback)
  skillObj:RegisterEventCallback("StopBulletTime", CastParam.CallbackOwner, CastParam.OnStopBulletTime)
  skillObj:RegisterEventCallback("AllHitEnd", CastParam.CallbackOwner, CastParam.OnAllHitEnd)
  skillObj:RegisterEventCallback("StateEffectEnd", CastParam.CallbackOwner, CastParam.OnStateEffectEndCallback)
  skillObj:RegisterEventCallback("NormalDefendEnd", CastParam.CallbackOwner, CastParam.OnNormalDefendEnd)
  if CastParam.ExtraEvents then
    for name, callBack in pairs(CastParam.ExtraEvents) do
      skillObj:RegisterEventCallback(name, CastParam.CallbackOwner, callBack)
    end
  end
end

function BattleSkillManager:PlaySkill(skillObj, notCancel)
  local rocoSkillComponent = self.skillObjToSkillComponent[skillObj]
  Log.Debug("BattleSkillManager PlaySkill:", rocoSkillComponent, skillObj)
  if rocoSkillComponent then
    if not notCancel then
      rocoSkillComponent:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultSuccessful)
    end
    return rocoSkillComponent:PlaySkill(skillObj)
  end
end

function BattleSkillManager:GetFirstHit(Hits)
  local ret = Hits[1]
  for i = 1, #Hits do
    if ret > Hits[i] then
      ret = Hits[i]
    end
  end
  return ret
end

function BattleSkillManager:CommonCast(battlePet, skillComponent, CastParam)
  local rocoSkillComponent, skillObj = self:PrepareSkill(battlePet, skillComponent, CastParam)
  rocoSkillComponent:CancelSkill(skillObj, UE4.ESkillActionResult.SkillActionResultSuccessful)
  rocoSkillComponent:PlaySkill(skillObj)
  return skillObj
end

function BattleSkillManager.CheckActorIsReadyToAction(actor, actionName, actionArg, skillObj)
  local battlePet = BattleManager.battlePawnManager:GetBattlePetByActor(actor, true)
  if battlePet and battlePet.card:IsModelInBattle() then
    local battlePetState = battlePet.card.petState
    if ("Stepback" == actionName or table.contains(SkillUtils.hitAnimationName, actionArg)) and battlePet.HasShieldThisAttack then
      return false
    end
    if "Stepback" == actionName then
      local animName = actionArg
      return battlePetState:IsStepbackable() and battlePetState:IsAnimable(animName)
    elseif "PlayAnimationByName" == actionName then
      local animName = actionArg
      local isAnimable = battlePetState:IsAnimable(animName)
      if "Test" == animName then
        return isAnimable
      end
      if battlePet:GetAnimComponent() then
        if battlePet.lastAnimSkill and battlePet.lastAnimSkill == skillObj then
          if isAnimable then
            battlePet.lastAnimSkill = skillObj
          end
          return isAnimable
        elseif SkillUtils:CheckAnimCanPlay(animName, battlePet:GetAnimComponent():GetCurAnimNameWithCheck()) then
          if isAnimable then
            battlePet.lastAnimSkill = skillObj
          end
          return isAnimable
        end
        Log.Error("zgx CheckActorIsReadyToAction animation \233\171\152\228\188\152\229\133\136\231\186\167\229\138\168\231\148\187\230\146\173\230\148\190\228\184\173\239\188\154", animName, " < ", battlePet:GetAnimComponent():GetCurAnimNameWithCheck())
      end
      return false
    elseif "RootMotionAnimationMove" == actionName then
      return battlePetState:IsMovable()
    elseif "CameraShakeAction" == actionName then
      return not skillObj:GetBeCounting() or not skillObj.isInBulletTime
    elseif "RootMotionAnimation" == actionName then
      battlePet.lastAnimSkill = skillObj
      return true
    end
  elseif BattleManager:IsInBattle(true) and "PlayAnimationByName" == actionName then
    local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.viewObj == actor then
      for _, status in pairs(BattleConst.NoAnimStatus) do
        if localPlayer.statusComponent:HasStatus(status) then
          return false
        end
      end
    end
  end
  return true
end

function BattleSkillManager:IsDeepWater()
  return BattleUtils.IsDeepWater()
end

return BattleSkillManager
