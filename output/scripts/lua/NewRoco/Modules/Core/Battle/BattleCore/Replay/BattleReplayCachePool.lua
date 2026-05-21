local JsonUtils = require("Common.JsonUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattlePerformNode = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformNode")
local ProtoCMD = require("Data.PB.ProtoCMD")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleReplayCachePool = NRCClass:Extend()
local StrFormat = string.format
local tInsert = table.insert
local OsTime = os.time

function BattleReplayCachePool:Ctor()
  self.dict = {}
  self.battleInfo = {}
  self.roundStartHeadDict = {}
  self.isSavedDict = {}
  self.curCacheBattleID = 0
  self.preNotifyIdx = -1
  self.ZoneBattleEnterNotify = nil
  self.reportRecord = {}
  self.uploadVersion = "1.2"
  if RocoEnv.IS_SHIPPING then
    self.isEnableCache = false
  else
    self.isEnableCache = true
  end
  if RocoEnv.IS_EDITOR then
    self.isUsingStreaming = false
  else
    self.isUsingStreaming = true
  end
end

function BattleReplayCachePool:Reset()
  self.dict = {}
  self.battleInfo = {}
end

function BattleReplayCachePool:StartCache(battleID)
  Log.Debug("BattleReplayCachePool StartCache:", battleID)
  self.curCacheBattleID = battleID
end

function BattleReplayCachePool:ClearCache()
  self.dict = {}
  self.battleInfo = {}
end

function BattleReplayCachePool:Push(cmdid, notify)
  if _G.BattleManager.battleRuntimeData:IsInReplayMode() then
    Log.Debug("\229\189\149\229\131\143\229\155\158\230\146\173\230\168\161\229\188\143\228\184\141\229\134\153\229\133\165\230\136\152\230\150\151\230\149\176\230\141\174")
    return
  end
  if cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY then
    return
  end
  if 1 == BattleDebugger.enableFieldUsageLog then
    Log.Debug("BattleDebugger enableFieldUsageLog \230\156\159\233\151\180\230\154\130\228\184\141\230\148\175\230\140\129\229\134\153\229\133\165\230\136\152\230\150\151\230\149\176\230\141\174(\230\156\170\230\157\165\229\143\175\228\187\165\229\129\154\229\136\176)")
    return
  end
  Log.Debug("BattleReplayCachePool:Push:", cmdid, ProtoCMD.MessageMap[cmdid])
  if cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
    Log.Debug("BattleReplayCachePool push :ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY:", notify.init_info.battle_id, type(notify.init_info.battle_id))
    self.curCacheBattleID = notify.init_info.battle_id
  end
  if not self.isEnableCache then
    return
  end
  if not self.dict[self.curCacheBattleID] then
    self.dict[self.curCacheBattleID] = {}
    if self.isUsingStreaming then
      local File = string.format("%s%s.json", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "BattleReplay_" .. self.curCacheBattleID)
      File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
      self.fileHandler = File
      UE4.UNRCStatics.OpenFileForStreamingWrite(File)
      UE4.UNRCStatics.StreamingWriteFile(self.fileHandler, "[\n")
      self.isFirstLineNotify = true
    end
  end
  if self.fileHandler then
    local rapidjson = require("rapidjson")
    local Content = rapidjson.encode({
      id = cmdid,
      idStr = ProtoCMD.MessageMap[cmdid],
      data = notify
    }, {pretty = true, sort_keys = true})
    if not self.isFirstLineNotify then
      UE4.UNRCStatics.StreamingWriteFile(self.fileHandler, ",\n")
    else
      self.isFirstLineNotify = false
    end
    UE4.UNRCStatics.StreamingWriteFile(self.fileHandler, Content)
  end
  if not self.isUsingStreaming then
    local OriNotify = table.deepCopy(notify)
    table.insert(self.dict[self.curCacheBattleID], {
      id = cmdid,
      idStr = ProtoCMD.MessageMap[cmdid],
      data = OriNotify
    })
  end
end

function BattleReplayCachePool:RecordBattleOp(cmdid, notify)
  if cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
    self:CollectEnterBattleInfo(notify)
  elseif cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY or cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
    self:CollectPerformInfo(cmdid, notify)
  elseif cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY then
    self:CollectRoundSelectInfo(notify)
  end
end

function BattleReplayCachePool:CollectEnterBattleInfo(enterNotify)
  if enterNotify.is_reconnect then
    local enterState = ""
    if _G.BattleManager.stateFsm then
      enterState = "\230\136\152\230\150\151\229\134\133\233\135\141\232\191\158 \229\189\147\229\137\141\231\138\182\230\128\129\230\156\186\228\184\186: " .. (_G.BattleManager.stateFsm:GetActiveStateName() or "\230\156\170\231\159\165")
    else
      enterState = "\230\157\128\232\191\155\231\168\139\233\135\141\232\191\158"
    end
    local time = os.date("%Y-%m-%d %H:%M:%S", math.floor(enterNotify.round_time / 1000))
    local desc = StrFormat("%s \233\135\141\232\191\158\229\155\158\229\144\136:%d, battle_state:%d \233\135\141\232\191\158\230\151\182\233\151\180:%s \n", enterState, enterNotify.round, enterNotify.init_info.battle_state, time)
    tInsert(self.battleInfo, desc)
  else
    self.battleInfo = {}
    local pawnManager = _G.BattleManager.battlePawnManager
    local playerTeamInfo = ""
    for playIdx, spawnData in ipairs(enterNotify.init_info.player_team) do
      local roleID = pawnManager:GetRoleId(spawnData, BattleEnum.Team.ENUM_TEAM)
      local petInfoStr = ""
      for petIdx, petInfo in ipairs(spawnData.pets) do
        local insidePetInfo = petInfo.battle_inside_pet_info
        petInfoStr = StrFormat("%s %s(%d base %d)\228\189\141\231\189\174\228\184\186%d;", petInfoStr, insidePetInfo.name, insidePetInfo.conf_id, insidePetInfo.base_conf_id, insidePetInfo.pos)
      end
      playerTeamInfo = StrFormat("\230\136\145\230\150\185\232\167\146\232\137\178\230\168\161\229\158\139%d,\230\144\186\229\184\166\231\178\190\231\129\181:%s", roleID, petInfoStr)
    end
    local enemyTeamInfo = ""
    for playIdx, spawnData in ipairs(enterNotify.init_info.enemy_team) do
      local roleID = pawnManager:GetRoleId(spawnData, BattleEnum.Team.ENUM_ENEMY)
      local petInfoStr = ""
      for petIdx, petInfo in ipairs(spawnData.pets) do
        local insidePetInfo = petInfo.battle_inside_pet_info
        petInfoStr = StrFormat("%s %s(%d base %d) \228\189\141\231\189\174:%d;", petInfoStr, insidePetInfo.name, insidePetInfo.conf_id, insidePetInfo.base_conf_id, insidePetInfo.pos)
      end
      enemyTeamInfo = StrFormat("\230\149\140\230\150\185\232\167\146\232\137\178\230\168\161\229\158\139%d,\230\144\186\229\184\166\231\178\190\231\129\181:%s", roleID, petInfoStr)
    end
    local time = os.date("%Y-%m-%d %H:%M:%S", enterNotify.init_info.battle_start_time)
    local desc = StrFormat("\232\191\155\229\133\165\230\136\152\230\150\151! \230\136\152\230\150\151\233\133\141\231\189\174id:%d \230\136\152\230\150\151\231\177\187\229\158\139:%d \229\133\165\230\136\152\231\177\187\229\158\139:%d \230\136\152\230\150\151\229\188\128\229\167\139\230\151\182\233\151\180:%s \n %s \n %s \n", enterNotify.init_info.battle_cfg_id[1], enterNotify.battle_mode, enterNotify.enter_battle_type, time, playerTeamInfo, enemyTeamInfo)
    tInsert(self.battleInfo, desc)
  end
end

function BattleReplayCachePool:CollectPerformInfo(cmdid, notify)
  local pawnManager = _G.BattleManager.battlePawnManager
  local perform_info = notify.perform_cmd.perform_info or {}
  local round = notify.perform_cmd.round
  local info = {
    round .. "\229\155\158\229\144\136\232\161\168\230\188\148:"
  }
  if cmdid == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
    info = {
      "\230\136\152\229\137\141\232\161\168\230\188\148:"
    }
  end
  for i, v in ipairs(perform_info) do
    if v.type == ProtoEnum.BattlePerformType.BPT_SKILL_CAST or v.type == ProtoEnum.BattlePerformType.BPT_COMBO_SKILL then
      local caster, target, skillId
      if v.skill_cast then
        caster = pawnManager:GetPetByGuid(v.skill_cast.caster_id)
        local targetId = v.skill_cast.target_id and v.skill_cast.target_id[1] or v.skill_cast.caster_id
        target = pawnManager:GetPetByGuid(targetId)
        skillId = v.skill_cast.skill_id
      elseif v.combo_skill_cast then
        caster = pawnManager:GetPetByGuid(v.combo_skill_cast.caster_id)
        local targetId = v.combo_skill_cast.target_id and v.combo_skill_cast.target_id[1] or v.combo_skill_cast.caster_id
        target = pawnManager:GetPetByGuid(targetId)
        skillId = v.combo_skill_cast.skill_id
      end
      if caster and target then
        local desc = StrFormat("%s\233\135\138\230\148\190\230\138\128\232\131\189%d,\231\155\174\230\160\135%s;", caster.card.name, skillId, target.card.name)
        tInsert(info, desc)
      end
    elseif v.type == ProtoEnum.BattlePerformType.BPT_ROLE_SKILL_CAST then
      if v.role_skill_cast then
        local caster = pawnManager:GetPetByGuid(v.role_skill_cast.pet_id)
        if caster then
          local desc = StrFormat("%s\233\135\138\230\148\190\228\186\134\228\184\187\232\167\146\233\173\148\230\179\149%d;", caster.card.name, v.role_skill_cast.skill_id)
          tInsert(info, desc)
        end
      end
    elseif v.type == ProtoEnum.BattlePerformType.BPT_CHANGE_PET then
      if v.change_pet then
        local player = pawnManager:GetPlayerByGuid(v.change_pet.player_id)
        local caster = player.deck:GetCardByGuid(v.change_pet.battle_pet_id)
        local target = player.deck:GetCardByGuid(v.change_pet.rest_pet_id)
        if caster and target then
          local desc = StrFormat("%s(%d)\230\155\191\230\141\162\230\136\144\228\186\134%s(%d);", caster.name, caster.petInfo.battle_common_pet_info.conf_id, target.name, target.petInfo.battle_common_pet_info.conf_id)
          tInsert(info, desc)
        end
      end
    elseif v.type == ProtoEnum.BattlePerformType.BPT_DEATH then
      if v.dead_info then
        local deadPet = pawnManager:GetPetByGuid(v.dead_info.target_id)
        if deadPet then
          local desc = StrFormat("%s\230\173\187\228\186\161;", deadPet.card.name)
          table.insert(info, desc)
        end
      end
    elseif v.type == ProtoEnum.BattlePerformType.BPT_CHANGE_MODEL then
      if v.change_model then
        local changePet = pawnManager:GetPetByGuid(v.change_model.pet_id)
        if changePet then
          local newName = v.change_model.pet_info and v.change_model.pet_info.battle_inside_pet_info.name or "\230\156\170\231\159\165"
          local desc = StrFormat("%s\230\155\180\230\141\162\230\168\161\229\158\139\228\184\186%s;", changePet.card.name, newName)
          tInsert(info, desc)
        end
      end
    elseif v.type == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER and v.buff_trigger and BuffUtils.IsRidOfBuff(v.buff_trigger.buff_id) then
      local caster = pawnManager:GetPetByGuid(v.buff_trigger.caster_id)
      local target = pawnManager:GetPetByGuid(v.buff_trigger.target_id)
      if caster and target then
        local desc = StrFormat("%s\229\144\185\233\163\158\228\186\134%s;", caster.card.name, target.card.name)
        tInsert(info, desc)
      end
    end
  end
  if #info > 1 then
    tInsert(info, "    \n")
    tInsert(self.battleInfo, table.concat(info))
  end
end

function BattleReplayCachePool:CollectRoundSelectInfo(roundNotify)
  local time = os.date("%Y-%m-%d %H:%M:%S", math.floor(roundNotify.state_info.round_time / 1000))
  local desc = StrFormat("\229\188\128\229\167\139\229\155\158\229\144\136\233\128\137\230\139\155 \229\189\147\229\137\141\229\155\158\229\144\136:%s state_type:%s \230\151\182\233\151\180:%s \n", roundNotify.state_info.round, roundNotify.state_type, time)
  tInsert(self.battleInfo, desc)
end

function BattleReplayCachePool:BattleExit()
  local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
  local desc = StrFormat("\233\128\128\229\135\186\230\136\152\230\150\151\239\188\140\230\151\182\233\151\180%s \n", BattleUtils.GetLocalDebugTime())
  tInsert(self.battleInfo, desc)
end

function BattleReplayCachePool:StopRecordBattle()
  if _G.BattleManager.battleRuntimeData:IsInReplayMode() then
    return
  end
  if self.isEnableCache and self.isUsingStreaming and self.fileHandler then
    UE4.UNRCStatics.StreamingWriteFile(self.fileHandler, "]")
    UE4.UNRCStatics.CloseFileForStreamingWrite(self.fileHandler)
    self.fileHandler = nil
  end
end

function BattleReplayCachePool:GetBattleData(battleID)
  Log.Debug("BattleReplayCachePool GetBattleData:", battleID)
  for k, v in pairs(self.dict) do
    Log.Debug("BattleReplayCachePool GetBattleData show key:", k)
  end
  return self.dict[battleID]
end

function BattleReplayCachePool:PreProcessDict(battleID)
  self.roundStartHeadDict = {}
  self.preNotifyIdx = -1
  if self.dict[battleID] then
    local lst = self:GetBattleData(battleID)
    local idx = 1
    for i = 1, #lst do
      if lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY then
        local notify = lst[i].data
        if notify.state_info.round == idx then
          table.insert(self.roundStartHeadDict, idx, i)
          idx = idx + 1
        end
      elseif lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
        self.ZoneBattleEnterNotify = lst[i].data
      elseif lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
        self.preNotifyIdx = i
      elseif lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY then
        local notify = lst[i].data
        if notify.round_settle_info then
          notify.settle_info = notify.round_settle_info
        end
      end
    end
  else
    Log.Error("battleId dont exist in dict")
  end
end

function BattleReplayCachePool:CheckInHeadDict(idx)
  if table.contains(self.roundStartHeadDict, idx) then
    return true
  else
    return false
  end
end

function BattleReplayCachePool:GetRoundStartData(battleID, roundIdx)
  if self.dict[battleID] then
    local lst = self:GetBattleData(battleID)
    local idx = 0
    for i = 1, #lst do
      Log.Debug("BattleReplayCachePool GetRoundStartData:", lst[i].id, lst[i].idStr, #lst)
      if lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY then
        idx = idx + 1
        if idx == roundIdx then
          Log.Debug("BattleReplayCachePool GetRoundStartData succ:", lst[i].data)
          return lst[i].data
        end
      end
    end
    Log.Debug("BattleReplayCachePool GetRoundStartData rounddata is not exist:", roundIdx)
  else
    Log.Debug("BattleReplayCachePool GetRoundStartData fail:", battleID, #self.dict[battleID])
  end
  return nil
end

function BattleReplayCachePool:GetRoundData(battleID, roundIdx)
  if self.dict[battleID] then
    local lst = self:GetBattleData(battleID)
    local idx = 0
    for i = 1, #lst do
      Log.Debug("BattleReplayCachePool GetRoundData:", lst[i].id, lst[i].idStr, #lst)
      if lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY then
        idx = idx + 1
        if idx == roundIdx then
          Log.Debug("BattleReplayCachePool GetRoundData succ:", idx, roundIdx, #lst, lst[i].data)
          return lst[i].data
        end
      end
    end
    Log.Debug("BattleReplayCachePool GetRoundData rounddata is not exist:", roundIdx)
  else
    Log.Debug("BattleReplayCachePool GetRoundData fail:", battleID, #self.dict[battleID])
  end
  return nil
end

function BattleReplayCachePool:GetRoundSyncData(battleID, roundIdx)
  if self.dict[battleID] then
    local lst = self.dict[battleID]
    local idx = 0
    for i = 1, #lst do
      if lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY then
        idx = idx + 1
        if idx == roundIdx then
          Log.Debug("BattleReplayCachePool GetRoundSyncData succ:", idx, roundIdx, #lst, lst[i].data)
          return lst[i].data
        end
      end
    end
    Log.Debug("BattleReplayCachePool GetRoundSyncData rounddata is not exist:", roundIdx)
  else
    Log.Debug("BattleReplayCachePool GetRoundSyncData fail:", battleID, #self.dict[battleID])
  end
  return nil
end

function BattleReplayCachePool:GetBattleFinishData(battleID)
  if self.dict[battleID] then
    local lst = self.dict[battleID]
    for i = 1, #lst do
      if lst[i].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY then
        Log.Debug("BattleReplayCachePool GetBattleFinishData succ:", #lst, lst[i].data)
        return lst[i].data
      end
    end
    Log.Debug("BattleReplayCachePool GetBattleFinishData rounddata is not exist:")
  else
    Log.Debug("BattleReplayCachePool GetBattleFinishData fail:", battleID, #self.dict[battleID])
  end
  return nil
end

function BattleReplayCachePool.LoadBattleDataFromJsonData(fileName, data)
  if fileName and data then
    data = JsonUtils.StringToJson(data)
    if string.EndsWith(fileName, ".json") then
      fileName = string.Substr(fileName, 1, string.len(fileName) - 5)
    end
    local battleID = _G.BattleReplayCachePool:TryGetBattleIDByName(fileName)
    if battleID then
      _G.BattleReplayCachePool.dict[battleID] = data
      local boo, errorCode = _G.BattleReplayCachePool:CheckBattleDataIsLegal(battleID)
      if not boo then
        Log.Error("\229\138\160\232\189\189\228\186\134\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174\239\188\140\229\183\178\231\187\143\232\135\170\229\138\168\229\141\184\232\189\189:", battleID, fileName, errorCode)
        _G.BattleReplayCachePool.dict[battleID] = nil
        return false
      else
        Log.Error("\230\136\144\229\138\159\229\138\160\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174:", battleID, fileName)
      end
      _G.BattleReplayCachePool:PreProcessDict(battleID)
      BattleReplayManager:DoReplayBattle(battleID)
    end
  end
end

function BattleReplayCachePool:LoadBattleData(fileName, fromAutoBattle, isReadFromSaved)
  local data
  if fromAutoBattle then
    if isReadFromSaved then
      data = JsonUtils.LoadSaved("AutoBattle/" .. fileName, {})
    else
      data = JsonUtils.LoadSavedFromAutoBattle(fileName, {})
    end
  else
    data = JsonUtils.LoadSaved(fileName, {})
  end
  self:FixBattleData(data)
  local battleID = self:TryGetBattleIDByName(fileName)
  self.dict[battleID] = data
  local boo, errorCode = self:CheckBattleDataIsLegal(battleID)
  if not boo then
    Log.Error("\229\138\160\232\189\189\228\186\134\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174\239\188\140\229\183\178\231\187\143\232\135\170\229\138\168\229\141\184\232\189\189:", battleID, fileName, errorCode)
    self.dict[battleID] = nil
    return false
  else
    Log.Debug("\230\136\144\229\138\159\229\138\160\232\189\189\230\136\152\230\150\151\230\149\176\230\141\174:", battleID, fileName)
  end
  self:PreProcessDict(battleID)
  return true
end

local SearchAndConvertToNumber = function(t, fieldNames)
  if type(t) == "table" then
    for k, v in pairs(t) do
      if type(fieldNames) == "table" then
        for _, fieldName in ipairs(fieldNames) do
          if k == fieldName and type(v) == "string" then
            local num = tonumber(v)
            if num then
              t[k] = num
            end
          end
        end
      end
      SearchAndConvertToNumber(v, fieldNames)
    end
  end
end

function BattleReplayCachePool:FixBattleData(data)
  SearchAndConvertToNumber(data, {"ai_status"})
end

function BattleReplayCachePool:SaveBattleData()
  for battleID, battleDataPair in pairs(self.dict) do
    Log.Debug("BattleReplayCachePool log battle data:begin:", battleID)
    for i = 1, #battleDataPair do
      if battleDataPair[1].data.init_info then
        battleDataPair[1].data.init_info.battle_id = tostring(battleDataPair[1].data.init_info.battle_id)
      end
      Log.Debug("BattleReplayCachePool log battle data:", ProtoCMD.MessageMap[battleDataPair[i].id])
    end
    JsonUtils.DumpSavedSortKey(os.date("%m-%d_%H_%M_%S") .. battleID, battleDataPair, 50)
    Log.Debug("BattleReplayCachePool log battle data:end:", battleID)
  end
end

function BattleReplayCachePool:SaveCurBattleData()
  local battleID = self.curCacheBattleID
  local battleDataPair = self.dict[self.curCacheBattleID]
  if not battleDataPair then
    Log.Error("BattleReplayCachePool SaveCurBattleData failed:", battleID)
    return
  end
  if not next(battleDataPair) then
    Log.Error("BattleReplayCachePool SaveCurBattleData failed, data is empty:", battleID)
    return
  end
  Log.Debug("BattleReplayCachePool log battle data:begin:", battleID)
  local isLegal, errorCode = self:CheckBattleDataIsLegal(battleID)
  if not isLegal then
    Log.Error("\230\179\168\230\132\143\239\188\140\228\191\157\229\173\152\228\186\134\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174:", battleID, errorCode)
  end
  for i = 1, #battleDataPair do
    Log.Debug("BattleReplayCachePool log battle data:", ProtoCMD.MessageMap[battleDataPair[i].id])
  end
  if battleDataPair[1].data.init_info then
    battleDataPair[1].data.init_info.battle_id = tostring(battleDataPair[1].data.init_info.battle_id)
  end
  local bSuccess, FullPath = JsonUtils.DumpSavedSortKey(os.date("%m-%d_%H_%M_%S_") .. battleID, battleDataPair, 50)
  Log.Debug("BattleReplayCachePool log battle data:end:", battleID)
  return bSuccess, FullPath
end

function BattleReplayCachePool:UploadBattleDataTOCrashSight(errorReason)
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  if not OnlineModule or not OnlineModule.data then
    return
  end
  local Data = OnlineModule.data
  local blackServer = {
    "\232\135\170\229\138\168\229\140\150\230\181\139\232\175\149\230\156\141",
    "\233\133\141\231\189\174\231\142\175\229\162\131",
    "yuuhaosun",
    "Chenhao",
    "xinyu",
    "dsxu-DC",
    "\229\143\153\228\186\139\233\133\141\231\189\174",
    "AI\232\174\173\231\187\131\230\156\141"
  }
  for i, v in ipairs(blackServer) do
    if string.find(Data.serverName, v) then
      return
    end
  end
  if self.reportRecord[errorReason] and OsTime() - self.reportRecord[errorReason] < 2 then
    return
  end
  if BattleLog then
    BattleLog.OnAntiStuck()
  end
  self.reportRecord[errorReason] = OsTime()
  local isLegal, errorCode = self:CheckBattleDataIsLegal(self.curCacheBattleID)
  local errorMsg = ""
  if not isLegal then
    errorMsg = StrFormat("\230\179\168\230\132\143\239\188\140\228\191\157\229\173\152\228\186\134\233\157\158\230\179\149\230\136\152\230\150\151\230\149\176\230\141\174:  %s", errorCode)
  end
  local battleInfo = ""
  if BattleManager:IsInBattle() and BattleManager.battleRuntimeData.battleConfig then
    local battleCfgId = BattleManager.battleRuntimeData.battleConfig.id
    local curRound = BattleManager.battleRuntimeData.roundIndex
    local battlePos = BattleManager.battleRuntimeData.ServerBattlePos or {}
    battleInfo = StrFormat("\230\136\152\230\150\151\233\133\141\231\189\174Id:%s, \229\135\186\233\148\153\229\155\158\229\144\136:%s, \230\136\152\230\150\151\229\156\176\231\130\185:(%s,%s,%s)", battleCfgId, curRound, battlePos.x, battlePos.y, battlePos.z)
  end
  local uploadBattleInfo = {}
  for i = math.max(#self.battleInfo - 9, 1), #self.battleInfo do
    table.insert(uploadBattleInfo, self.battleInfo[i])
  end
  local stackIdx = string.find(errorReason, "stack", 1) or 200
  local errorInfo = string.sub(errorReason, 1, stackIdx - 1)
  local errName = StrFormat("\230\136\152\230\150\151\233\152\178\229\141\161\230\173\187 %s;  \230\156\141\229\138\161\229\153\168\228\191\161\230\129\175:%s port:%s; ", errorInfo, Data.serverName, Data.port)
  local errReason = StrFormat("\230\136\152\230\150\151\228\191\161\230\129\175 %s;  \230\136\152\230\150\151ID:%s;  \232\167\146\232\137\178\228\191\161\230\129\175:%s openId:%s;\230\160\161\233\170\140\230\136\152\230\150\151\230\149\176\230\141\174:%s; Version:%s; \233\148\153\232\175\175\229\142\159\229\155\160:%s; \233\128\137\230\139\155\228\191\161\230\129\175:%s;", battleInfo, self.curCacheBattleID, Data.userName, Data.openid, errorMsg, self.uploadVersion, errorReason, table.concat(uploadBattleInfo))
  _G.BattleEventCenter:Dispatch(BattleEvent.OnCallCrashSight, errReason)
  if BattleAutoTest.IsAutoPlayBattleRecords then
    BattleAutoTest:AddAutoPlayErrorLog(self.curCacheBattleID, Data.serverName, errorReason)
    if not BattleAutoTest.CacheError then
      BattleAutoTest.CacheError = {}
    end
    local endIndex = string.find(errorReason, "\n") - 1
    local errorStr = string.sub(errorReason, 1, endIndex)
    local errorInfo = {
      recordName = BattleAutoTest.CurCommand,
      recordMessage = errorStr
    }
    table.insert(BattleAutoTest.CacheError, errorInfo)
  else
    local TraceBack = errorReason .. debug.traceback()
    local bSuccess, FileFullPath = self:SaveCurBattleData()
    if not bSuccess and self.fileHandler then
      local Names = string.split(self.fileHandler, "/")
      local Name = Names[#Names]
      Names[#Names] = os.date("%m-%d_%H_%M_%S_") .. Name
      FileFullPath = table.concat(Names, "/")
      UE4.UNRCStatics.CloseFileForStreamingWrite(self.fileHandler)
      UE4.UNRCStatics.CopyFile(self.fileHandler, FileFullPath)
      UE4.UNRCStatics.OpenFileForStreamingWrite(self.fileHandler)
      UE4.UNRCStatics.OpenFileForStreamingWrite(FileFullPath)
      UE4.UNRCStatics.StreamingWriteFile(FileFullPath, "]")
      UE4.UNRCStatics.CloseFileForStreamingWrite(FileFullPath)
      bSuccess = UE.UBlueprintPathsLibrary.FileExists(FileFullPath)
    end
    if bSuccess then
      bSuccess = NRCModuleManager:DoCmd(CosUploadModuleCmd.ReqCosUploadUrlForBattle, self.curCacheBattleID, FileFullPath, function(ServerRemotePath)
        errName = errName .. "\n" .. "Cos\228\184\138\230\138\165:[" .. ServerRemotePath .. "]\n"
        NRCSDKManager:CrashSightReportExceptionWithReason(errName, errReason, TraceBack)
        UE.UNRCStatics.DeleteToFile(FileFullPath)
      end)
    else
      errName = errName .. "\n" .. "Cos\228\184\138\230\138\165:\228\191\157\229\173\152\230\136\152\230\150\151\229\189\149\229\131\143\229\164\177\232\180\165"
      NRCSDKManager:CrashSightReportExceptionWithReason(errName, errReason, TraceBack)
    end
  end
end

function BattleReplayCachePool:GetUploadVersion()
  return self.uploadVersion
end

function BattleReplayCachePool:CheckBattleDataIsLegal(battleID)
  local battleData = self:GetBattleData(battleID)
  if battleData and #battleData >= 2 then
    for i = 1, #battleData do
      Log.Debug("BattleReplayCachePool:CheckBattleDataIsLegal:", ProtoCMD:GetMessageName(battleData[i].id), battleData[i].data.state_type)
    end
    if battleData[1].id ~= ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
      return false, "ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY is not exist"
    end
  else
    local errorCode = string.format("battleData len is illegal: battleId %s, len %s", battleID, battleData and #battleData or "nil")
    return false, errorCode
  end
  return true
end

function BattleReplayCachePool:TryGetBattleIDByName(fileName)
  local strArr = string.Split(fileName, "_")
  Log.Debug("BattleReplayCachePool loadbattledata:", fileName, #strArr, strArr[#strArr])
  return tonumber(strArr[#strArr])
end

function BattleReplayCachePool:DumpBattleDataToString(battleID, isSaveLocal)
  Log.Debug("BattleReplayCachePool DumpBattleDataToString begin:", battleID)
  local battleData = self:GetBattleData(battleID)
  local dumpStr = ""
  local roundIdx = 0
  for i = 1, #battleData do
    local id = battleData[i].id
    local data = battleData[i].data
    if id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
      local preplayNotify = data
      local str = self:PrintPerformCmdToString(preplayNotify.perform_cmd)
      dumpStr = dumpStr .. "Round 0:" .. battleData[i].idStr .. "\n" .. str
    elseif id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY then
      roundIdx = roundIdx + 1
      Log.Debug("BattleReplayCachePool DumpBattleDataToString:", roundIdx)
      local performStartNotify = data
      local str = self:PrintPerformCmdToString(performStartNotify.perform_cmd)
      dumpStr = dumpStr .. "Round " .. roundIdx .. ":" .. battleData[i].idStr .. "\n" .. str
    else
      dumpStr = dumpStr .. battleData[i].idStr .. "\n"
    end
  end
  Log.Debug("BattleReplayCachePool DumpBattleDataToString end:\n", dumpStr)
  if isSaveLocal then
    local File = string.format("%s%s.txt", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "\232\167\163\230\158\144\230\136\152\230\150\151\230\149\176\230\141\174" .. battleID)
    File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
    Log.Debug("BattleReplayCachePool DumpBattleDataToString filename:", File)
    local Content = dumpStr
    local Success = UE4.UNRCStatics.WriteToFile(File, Content)
  end
end

function BattleReplayCachePool:PrintChangePetCmdToString(changePetCmd)
  Log.Debug("BattleReplayCachePool PrintChangePetCmdToString:", changePetCmd.battle_pet_id)
  return "ChangePet:battle_pet_id:" .. changePetCmd.battle_pet_id .. "\n"
end

function BattleReplayCachePool:PrintPerformCmdToString(performCmd)
  local str = ""
  if performCmd.perform_info then
    for i = 1, #performCmd.perform_info do
      local performInfo = performCmd.perform_info[i]
      local performNode = BattlePerformNode()
      performNode:PreProcess(performInfo, i)
      local performNodeInfos = {
        "NodeIdx:" .. performNode:GetNodeIdx(),
        "ExecIdx:" .. performNode:GetExecIdx(),
        "CasterID:" .. performNode:GetCasterID(),
        "PerformType:" .. performNode:GetPerformTypeTostring(),
        "PerformID:" .. performNode:GetPerformIDToName(),
        "Group:" .. performNode:GetGroupID(),
        "GRef:" .. (performNode:GetGroupRef() or ""),
        "CastMoment" .. performNode:GetCastMomentToString() .. "(" .. performNode:GetCastMoment() .. ")",
        "IsHead:" .. (performNode:IsGroupHead() and "True" or "False")
      }
      str = str .. table.concat(performNodeInfos, "\t")
      Log.Debug("BattleReplayCachePool PrintPerformCmdToString:", str)
      if performInfo.type == ProtoEnum.BattlePerformType.BPT_SKILL_CAST then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_CHANGE then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_BUFF_TRIGGER then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_EFFECT_TRIGGER then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DAMAGE then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_HEAL then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_ENERGY then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_DEATH then
      elseif performInfo.type == ProtoEnum.BattlePerformType.BPT_REVIVE then
      end
      str = str .. "\n"
    end
  end
  return str
end

return BattleReplayCachePool
