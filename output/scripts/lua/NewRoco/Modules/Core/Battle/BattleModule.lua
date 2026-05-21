local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleModuleData = require("NewRoco.Modules.Core.Battle.BattleModuleData")
local ProtoMessage = require("Data.PB.ProtoMessage")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local BattleModule = NRCModuleBase:Extend("BattleModule")

function BattleModule:OnConstruct()
  self.data = self:SetData("BattleModuleData", "NewRoco.Modules.Core.Battle.BattleModuleData")
  NRCEventCenter:RegisterEvent("BattleModule", self, SceneEvent.PostLoadMapStart, self.HandlePostLoadMapStart)
  NRCEventCenter:RegisterEvent("BattleModule", self, SceneEvent.PreLoadMapFinish, self.HandlePreLoadMapFinish)
end

function BattleModule:OnDestruct()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PreLoadMapFinish, self.HandlePreLoadMapFinish)
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.PostLoadMapStart, self.HandlePostLoadMapStart)
end

function BattleModule:OnActive()
end

function BattleModule:OnIsInBattle()
  return _G.BattleManager.isInBattle
end

function BattleModule:OnGetBattleFieldCenterPos()
  return BattleManager.battleRuntimeData.NearbyValidBattleLocation
end

function BattleModule:OnGetBattleFieldRadius()
  if BattleManager.vBattleField then
    return BattleManager.vBattleField:GetBattleFieldRange()
  end
  return BattleConst.Define.BattleFieldRange
end

function BattleModule:OnCheckNpcInHideRange(npc)
  if not BattleManager.DebugBattleHide then
    return true
  end
  if npc then
    local BattleHideNpcCenter = BattleManager.vBattleField.BattleHideNpcCenter
    local BattleHideNpcExtent = BattleManager.vBattleField.BattleHideNpcExtent
    if BattleHideNpcCenter and BattleHideNpcExtent then
      for i = 1, #BattleHideNpcCenter do
        local localPos = BattleHideNpcCenter[i]:InverseTransformPosition(npcPos)
        if math.abs(localPos.X) > BattleHideNpcExtent[i].X then
          return false
        end
        if math.abs(localPos.Y) > BattleHideNpcExtent[i].Y then
          return false
        end
        if math.abs(localPos.Z) > BattleHideNpcExtent[i].Z then
          return false
        end
        return true
      end
    end
    return false
  end
end

function BattleModule:OnSelectExtraCatchBall(ballGID, selectIndex)
  local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow and mainWindow.UmgLoaders[BattleEnum.Operation.ENUM_CATCH] then
    local panel = mainWindow:GetSubPanel(BattleEnum.Operation.ENUM_CATCH)
    if panel and panel.InitBallData then
      local bNeedSelect = true
      if selectIndex then
        panel:InitBallData(bNeedSelect, selectIndex)
      else
        panel:InitBallData()
      end
    end
  end
end

function BattleModule:OnDeactive()
end

function BattleModule:OnLogin(isRelogin)
end

local function LoadBattleFieldLevelAsyncTask(self)
  if not self.data or self.data.battleFieldLevelLoadingState == BattleModuleData.BattleFieldLoadingState.LOADING then
    Log.Error("zgx repeat load battle field!!!")
    return
  end
  self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.LOADING
  a.wait(au.DelayFrames(1))
  local battleFieldActor = self:GetBattleFieldActor()
  self.data.currentBattleFieldActor = battleFieldActor
  if UE4.UObject.IsValid(self.data.currentBattleFieldActor) then
    self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.SUCCESS
    Log.Warning("battle field level is existed.")
    return true
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local battleFieldLevelPath = "/Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/BattleField_BigWorld_01.BattleField_BigWorld_01"
  local loadLevelOk, steamingLevelOrMessage = a.wait(au.LoadLevelInstance(World, battleFieldLevelPath, UE.FVector(), UE.FRotator(), true, 20))
  a.wait(au.DelayFrames(10))
  UE4.UNRCStatics.BlockTillLevelStreamingCompleted(UE4Helper.GetCurrentWorld())
  battleFieldActor = self:GetBattleFieldActor()
  self.data.currentBattleFieldActor = battleFieldActor
  BattleManager.vBattleField.battleFieldActor = battleFieldActor
  if not UE4.UObject.IsValid(self.data.currentBattleFieldActor) then
    if not loadLevelOk then
      self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.ERROR
      return false, steamingLevelOrMessage
    else
      self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.ERROR
      return false, "battle field level load, but failed to find battle field actor"
    end
  end
  self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.SUCCESS
  self.data.currentLevelStreaming = steamingLevelOrMessage
  return true
end

function BattleModule:OnCmdLoadBattleFieldLevel(completeCallback)
  completeCallback = completeCallback or function()
  end
  au.LaunchWithTimeout(a.sync(LoadBattleFieldLevelAsyncTask)(self), 15, function(ok, internalOkOrMessage, message)
    if not ok then
      Log.Error(internalOkOrMessage)
      completeCallback(false, internalOkOrMessage)
    elseif not internalOkOrMessage then
      Log.Error(message)
      completeCallback(false, internalOkOrMessage)
    else
      completeCallback(true)
    end
  end)
end

function BattleModule:HandlePostLoadMapStart(SameSceneRes, bReconnecting, id)
  if SameSceneRes then
    return
  end
  if self.data.battleFieldLevelLoadingState == BattleModuleData.BattleFieldLoadingState.LOADING then
    return
  end
  self.data.currentBattleFieldActor = nil
  if UE.UObject.IsValid(self.data.currentLevelStreaming) then
    self.data.currentLevelStreaming:SetShouldBeVisible(false)
    self.data.currentLevelStreaming:SetShouldBeLoaded(false)
    self.data.currentLevelStreaming:SetIsRequestingUnloadAndRemoval(true)
    UE4.UNRCStatics.BlockTillLevelStreamingCompleted(UE4Helper.GetCurrentWorld())
  end
  self.data.currentLevelStreaming = nil
  self.data.battleFieldLevelLoadingState = BattleModuleData.BattleFieldLoadingState.WAITING_FOR_LOAD
end

function BattleModule:HandlePreLoadMapFinish(world)
  au.Launch(a.sync(LoadBattleFieldLevelAsyncTask)(self), function(ok, internalOkOrMessage, message)
    if not ok then
      Log.Error(internalOkOrMessage)
    elseif not internalOkOrMessage then
      Log.Error(message)
    else
      Log.Debug("BattleModule:OnPostLoadMapWithWorld load battle field level completed")
    end
  end)
end

function BattleModule:OnCmdGetBattleFieldLevelIsReady()
  return self.data.battleFieldLevelLoadingState == BattleModuleData.BattleFieldLoadingState.SUCCESS
end

function BattleModule:GetBattleFieldActor()
  local World = _G.UE4Helper.GetCurrentWorld()
  local battleFieldConfList = UE4.UGameplayStatics.GetAllActorsOfClass(World, UE.ABattleFieldConf)
  for i, battleFieldConf in tpairs(battleFieldConfList) do
    if UE4.UObject.IsValid(battleFieldConf.BattleFieldActor) then
      return battleFieldConf.BattleFieldActor
    end
  end
  return nil
end

function BattleModule:OnCmdGetCurrentBattleFieldActor()
  if UE4.UObject.IsValid(self.data.currentBattleFieldActor) then
    return self.data.currentBattleFieldActor
  end
  self.data.currentBattleFieldActor = self:GetBattleFieldActor()
  return self.data.currentBattleFieldActor
end

function BattleModule:OnCmdCollectSkillEnhanceInfoForChangePetAttr(skillId, petGuid)
  local skillEnhanceInfos = {}
  if not skillId or not _G.BattleManager:IsInBattle() then
    return skillEnhanceInfos
  end
  local battleCard = _G.BattleManager.battlePawnManager:GetCardByGuid(petGuid)
  local ownerPlayer = battleCard and battleCard.owner
  local deck = ownerPlayer and ownerPlayer.deck
  local ownerPlayerBattleCards = deck and deck.cards or {}
  local inFieldCards = {}
  for i, card in ipairs(ownerPlayerBattleCards) do
    if card:IsInBattle() then
      table.insert(inFieldCards, card)
    end
  end
  local buff93SkillEnhanceInfo
  do
    local skillConf = _G.SkillUtils.GetSkillConf(skillId)
    local skillResult = skillConf and skillConf.skill_result and #skillConf.skill_result > 0 and skillConf.skill_result[1]
    local effectId = skillResult and skillResult.effect_id
    local buffConfig = _G.DataConfigManager:GetBuffConf(effectId, true)
    local buffBaseId = buffConfig and buffConfig.buff_base_ids[1] or 0
    local buffBaseConf = buffBaseId and _G.DataConfigManager:GetBuffbaseConf(buffBaseId, true)
    if BattleUtils.IsBuffBaseIdIsBuff93AndParams5Is5(buffBaseId) then
      local buffbase_param = buffBaseConf and buffBaseConf.buffbase_param
      local param11 = buffbase_param and buffbase_param[11]
      local tip_id = param11 and param11.params and param11.params[1] or 0
      local skillEnhanceInfo = ProtoMessage:newSkillEnhanceInfo()
      skillEnhanceInfo.buff_id = effectId
      skillEnhanceInfo.buffbase_id = buffBaseId
      skillEnhanceInfo.stack = 1
      skillEnhanceInfo.tip_id = tip_id
      buff93SkillEnhanceInfo = skillEnhanceInfo
    end
  end
  if buff93SkillEnhanceInfo then
    table.insert(skillEnhanceInfos, buff93SkillEnhanceInfo)
    buff93SkillEnhanceInfo = nil
  end
  for i, battlePetCard in ipairs(inFieldCards) do
    if battlePetCard:IsEnemy() then
    else
      local battlePetInfo = battlePetCard and battlePetCard.petInfo
      local battlePetInsideInfo = battlePetInfo and battlePetInfo.battle_inside_pet_info
      local battlePetBuffInfoList = battlePetInsideInfo and battlePetInsideInfo.buffs
      local hasBuff64EnhanceInfoAdd = false
      if battlePetBuffInfoList then
        for j, buffInfo in ipairs(battlePetBuffInfoList) do
          local buffId = buffInfo and buffInfo.buff_id
          local buffStack = buffInfo and buffInfo.stack
          local buffConfig = _G.DataConfigManager:GetBuffConf(buffId, true)
          local buffBaseId = buffConfig and buffConfig.buff_base_ids and buffConfig.buff_base_ids[1]
          local buffBaseConf = buffConfig and _G.DataConfigManager:GetBuffbaseConf(buffConfig.buff_base_ids[1])
          local buffBaseOrder = buffBaseConf and buffBaseConf.buffbase_order
          local buffbase_param = buffBaseConf and buffBaseConf.buffbase_param
          if buffBaseOrder == Enum.BuffType.BFT_STRENGTHEN_THE_SKILL then
            local param1 = buffbase_param and buffbase_param[1] and buffbase_param[1].params
            local param2 = buffbase_param and buffbase_param[2] and buffbase_param[2].params
            local param8 = buffbase_param and buffbase_param[8] and buffbase_param[8].params
            local param1Value = param1 and param1[1]
            local skillIdList = {}
            if 7 == param1Value then
              skillIdList = param2 or {}
            end
            local tipsId = param8 and param8[1]
            if table.contains(skillIdList, skillId) and tipsId then
              local skillEnhanceInfo = ProtoMessage:newSkillEnhanceInfo()
              skillEnhanceInfo.buff_id = buffId
              skillEnhanceInfo.buffbase_id = buffBaseId
              skillEnhanceInfo.stack = buffStack
              skillEnhanceInfo.tip_id = tipsId
              table.insert(skillEnhanceInfos, skillEnhanceInfo)
              hasBuff64EnhanceInfoAdd = true
            end
          end
        end
      else
        Log.Error("BattleModule battlePetBuffInfoList is nil")
      end
      if hasBuff64EnhanceInfoAdd then
        break
      end
    end
  end
  return skillEnhanceInfos
end

function BattleModule:OnCmdGetPvpConfByBattleType(battleType)
  local data = self.data
  local pvpConfIdToBattleConf = data and data.pvpConfIdToBattleConf or {}
  local targetPvpConfId = -1
  for pvpConfId, battleConf in pairs(pvpConfIdToBattleConf) do
    local battleConfType = battleConf and battleConf.type
    if battleType == battleConfType then
      targetPvpConfId = pvpConfId
    end
  end
  local pvpConf = _G.DataConfigManager:GetPvpConf(targetPvpConfId, true)
  return pvpConf
end

return BattleModule
