local BattleAttackPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleAttackPlayer")
local BattleBuffPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleBuffPlayer")
local BattleBuffChangePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleBuffChangePlayer")
local BattlePopupPlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePopupPlayer")
local BattleSpEnergyPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleSpEnergyPlayer")
local BattleUseItemPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleUseItemPlayer")
local BattleChangePetPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleChangePetPlayer")
local BattleIdlePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleIdlePlayer")
local BattleCatchChangePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleCatchChangePlayer")
local BattleEscapeChangePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleEscapeChangePlayer")
local BattleSkillStatePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleSkillStatePlayer")
local BattleCatchPetPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleCatchPetPlayer")
local BattleEvolutionPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleEvolutionPlayer")
local BattleDeathPlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePetDiePlayer")
local BattlePetRevivePlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePetRevivePlayer")
local BattleEffectPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleEffectPlayer")
local BattleChangeModelPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleChangeModelPlayer")
local BattleBoxShieldBreakPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleBoxShieldBreakPlayer")
local BattleCheersSwitchPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleCheersSwitchPlayer")
local BattleCheerPetEscapePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleCheerPetEscapePlayer")
local BattlePlayerSkillPlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePlayerSkillPlayer")
local BattleComboSkillPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleComboSkillPlayer")
local BattlePlayerSkillEscapePlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePlayerSkillEscapePlayer")
local BattleIncreaseBloodPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleIncreaseBloodPlayer")
local BattleDamagePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleDamagePlayer")
local BattleTaskStatePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleTaskStatePlayer")
local BattleSupplyPetPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleSupplyPetPlayer")
local BattleNotifyPerformPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleNotifyPerformPlayer")
local BattlePlayerRunawayPlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePlayerRunawayPlayer")
local BattleChangeSkillPositionPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleChangeSkillPositionPlayer")
local BattlePrepareToBattlePlayer = require("NewRoco.Modules.Core.Battle.Players.BattlePrepareToBattlePlayer")
local BagToPreparePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleBagToPreparePlayer")
local BattleParallelPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleParallelPlayer")
local BattleResonancePlayer = require("NewRoco.Modules.Core.Battle.Players.BattleResonancePlayer")
local BattleFinishPerformPlayer = require("NewRoco.Modules.Core.Battle.Players.BattleFinishPerformPlayer")
local BattlePlayerPool = NRCClass:Extend()

function BattlePlayerPool:Ctor()
  self:Reset()
end

function BattlePlayerPool:Reset()
  self.workingPlayerLst = {}
  self.lstDict = {
    atk = {t = BattleAttackPlayer},
    buff = {t = BattleBuffPlayer},
    buffChange = {t = BattleBuffChangePlayer},
    popup = {t = BattlePopupPlayer},
    spEnergy = {t = BattleSpEnergyPlayer},
    useItem = {t = BattleUseItemPlayer},
    changePet = {t = BattleChangePetPlayer},
    idle = {t = BattleIdlePlayer},
    catchChange = {t = BattleCatchChangePlayer},
    escapeChange = {t = BattleEscapeChangePlayer},
    skillState = {t = BattleSkillStatePlayer},
    catchPet = {t = BattleCatchPetPlayer},
    evolution = {t = BattleEvolutionPlayer},
    death = {t = BattleDeathPlayer},
    revive = {t = BattlePetRevivePlayer},
    effect = {t = BattleEffectPlayer},
    changeModel = {t = BattleChangeModelPlayer},
    boxShieldBreak = {t = BattleBoxShieldBreakPlayer},
    cheersSwitch = {t = BattleCheersSwitchPlayer},
    cheersEscape = {t = BattleCheerPetEscapePlayer},
    playerSkill = {t = BattlePlayerSkillPlayer},
    comboSkill = {t = BattleComboSkillPlayer},
    playerSkillEscape = {t = BattlePlayerSkillEscapePlayer},
    increaseBlood = {t = BattleIncreaseBloodPlayer},
    damage = {t = BattleDamagePlayer},
    battleTaskState = {t = BattleTaskStatePlayer},
    supplyPet = {t = BattleSupplyPetPlayer},
    changeSkillPosition = {
      lst = self.changeSkillPosition,
      t = BattleChangeSkillPositionPlayer
    },
    notifyPerform = {t = BattleNotifyPerformPlayer},
    playerRunaway = {t = BattlePlayerRunawayPlayer},
    prepareToBattle = {t = BattlePrepareToBattlePlayer},
    bagToPrepare = {t = BagToPreparePlayer},
    Parallel = {t = BattleParallelPlayer},
    Resonance = {t = BattleResonancePlayer},
    FinishPerform = {t = BattleFinishPerformPlayer}
  }
end

function BattlePlayerPool:GetAttackPlayer()
  return self:GetPlayerFromDict("atk")
end

function BattlePlayerPool:GetBuffPlayer()
  return self:GetPlayerFromDict("buff")
end

function BattlePlayerPool:GetBuffChangePlayer()
  return self:GetPlayerFromDict("buffChange")
end

function BattlePlayerPool:GetSpEnergyPlayer()
  return self:GetPlayerFromDict("spEnergy")
end

function BattlePlayerPool:GetUseItemPlayer()
  return self:GetPlayerFromDict("useItem")
end

function BattlePlayerPool:GetChangePetPlayer()
  return self:GetPlayerFromDict("changePet")
end

function BattlePlayerPool:GetIdlePlayer()
  return self:GetPlayerFromDict("idle")
end

function BattlePlayerPool:GetCatchChangePlayer()
  return self:GetPlayerFromDict("catchChange")
end

function BattlePlayerPool:GetEscapeChangePlayer()
  return self:GetPlayerFromDict("escapeChange")
end

function BattlePlayerPool:GetSkillStatePlayer()
  return self:GetPlayerFromDict("skillState")
end

function BattlePlayerPool:GetCatchPetPlayer()
  return self:GetPlayerFromDict("catchPet")
end

function BattlePlayerPool:GetEvolutionPlayer()
  return self:GetPlayerFromDict("evolution")
end

function BattlePlayerPool:GetDeathPlayer()
  return self:GetPlayerFromDict("death")
end

function BattlePlayerPool:GetRevivePlayer()
  return self:GetPlayerFromDict("revive")
end

function BattlePlayerPool:GetEffectPlayer()
  return self:GetPlayerFromDict("effect")
end

function BattlePlayerPool:GetChangeModelPlayer()
  return self:GetPlayerFromDict("changeModel")
end

function BattlePlayerPool:GetSurpriseBoxShieldBreakPlayer()
  return self:GetPlayerFromDict("boxShieldBreak")
end

function BattlePlayerPool:GetPopupPlayer()
  return self:GetPlayerFromDict("popup")
end

function BattlePlayerPool:GetCheersSwitchPlayer()
  return self:GetPlayerFromDict("cheersSwitch")
end

function BattlePlayerPool:GetCheersEscapePlayer()
  return self:GetPlayerFromDict("cheersEscape")
end

function BattlePlayerPool:GetPlayerSkillPlayer()
  return self:GetPlayerFromDict("playerSkill")
end

function BattlePlayerPool:GetComboSkillPlayer()
  return self:GetPlayerFromDict("comboSkill")
end

function BattlePlayerPool:GetPlayerSkillEscapePlayer()
  return self:GetPlayerFromDict("playerSkillEscape")
end

function BattlePlayerPool:GetBattleTaskStatePlayer()
  return self:GetPlayerFromDict("battleTaskState")
end

function BattlePlayerPool:GetIncreaseBloodPlayer()
  return self:GetPlayerFromDict("increaseBlood")
end

function BattlePlayerPool:GetDamagePlayer()
  return self:GetPlayerFromDict("damage")
end

function BattlePlayerPool:GetSupplyPetPlayer()
  return self:GetPlayerFromDict("supplyPet")
end

function BattlePlayerPool:GetChangeSkillPositionPlayer()
  return self:GetPlayerFromDict("changeSkillPosition")
end

function BattlePlayerPool:GetNotifyPerformPlayer()
  return self:GetPlayerFromDict("notifyPerform")
end

function BattlePlayerPool:GetPlayerRunawayPerformPlayer(player)
  return self:GetPlayerFromDict("playerRunaway")
end

function BattlePlayerPool:GetPrepareToBattlePlayer()
  return self:GetPlayerFromDict("prepareToBattle")
end

function BattlePlayerPool:GetBagToPreparePlayer()
  return self:GetPlayerFromDict("bagToPrepare")
end

function BattlePlayerPool:GetParallelPlayer()
  return self:GetPlayerFromDict("Parallel")
end

function BattlePlayerPool:GetResonancePlayer()
  return self:GetPlayerFromDict("Resonance")
end

function BattlePlayerPool:GetFinishPerformPlayer()
  return self:GetPlayerFromDict("FinishPerform")
end

function BattlePlayerPool:GetPlayerFromDict(name)
  local lstData = self.lstDict[name]
  local lst = lstData.lst
  if not lst or 0 == #lst then
    local t = lstData.t
    local player = t()
    table.insert(self.workingPlayerLst, player)
    player:Start()
    player.typeName = name
    return player
  else
    local player = lst[#lst]
    table.remove(lst, #lst)
    table.insert(self.workingPlayerLst, player)
    player:Start()
    return player
  end
end

function BattlePlayerPool:ReleasePlayer(player)
  for i = #self.workingPlayerLst, 1, -1 do
    if self.workingPlayerLst[i] == player then
      table.remove(self.workingPlayerLst, i)
    end
  end
  player:Stop()
  self:ReturnToPool(player)
end

function BattlePlayerPool:ReturnToPool(player)
  if player and player.typeName then
    local lstData = self.lstDict[player.typeName]
    if lstData then
      if not lstData.lst then
        lstData.lst = {}
      end
      table.insert(lstData.lst, player)
    end
  end
end

function BattlePlayerPool:ReleaseAll()
  for i = #self.workingPlayerLst, 1, -1 do
    local player = self.workingPlayerLst[i]
    table.remove(self.workingPlayerLst, i)
    player:Stop()
    self:ReturnToPool(player)
  end
end

function BattlePlayerPool:Clear()
  for i = #self.workingPlayerLst, 1, -1 do
    self.workingPlayerLst[i]:Stop()
    self.workingPlayerLst[i]:Clear()
  end
  self:Reset()
end

return BattlePlayerPool
