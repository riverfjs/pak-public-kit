local BattleCard = require("NewRoco.Modules.Core.Battle.Entity.Card.BattleCard")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattlePlayerDeck = NRCClass()

function BattlePlayerDeck:Ctor(owner)
  self.cards = {}
  self.Owner = owner
end

function BattlePlayerDeck:Init(params)
  if not params or 0 == #params then
    if BattleUtils.IsFinalBattleP2() then
      return
    end
    Log.Error("BattlePlayerDeck recived nil params")
    local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
    if uin == self.Owner.roleInfo.base.role_uin and not BattleUtils.IsWatchingBattle() then
      local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
      local Ctx = DialogContext():SetTitle("Tips"):SetContent("No BattlePetInfo!!!  "):SetMode(DialogContext.Mode.OK):SetCallback(_G.BattleNetManager, function()
        _G.BattleNetManager:SendEscapeReq(BattleEnum.RunAwayType.NoCardInfo)
      end)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
      return
    else
      params = {}
    end
  end
  for i = 1, #params do
    local petInfo = params[i]
    self.cards[i] = BattleCard(self.Owner, petInfo, i)
  end
end

function BattlePlayerDeck:AdditionalInitByOthers(petInfos)
  if petInfos then
    for i = 1, #petInfos do
      local petInfo = petInfos[i]
      local incommingPetId = petInfo.battle_inside_pet_info.pet_id
      local existingCard = self:GetCardByGuid(incommingPetId)
      if nil == existingCard then
        existingCard = BattleCard(self.Owner, petInfo, #self.cards)
        table.insert(self.cards, existingCard)
      else
        existingCard:ReplaceByServer(petInfo)
        existingCard:RefreshByServer()
      end
    end
  end
end

function BattlePlayerDeck:AddPetDynamic(petInfo)
  table.insert(self.cards, BattleCard(self.Owner, petInfo, #self.cards))
end

function BattlePlayerDeck:ReplaceByServer(petInfos)
  if not petInfos then
    return
  end
  if #petInfos ~= #self.cards then
    if #petInfos > #self.cards then
      Log.Debug("\230\179\168\230\132\143\239\188\154\233\162\132\232\167\136\230\168\161\229\188\143\228\184\139\229\133\129\232\174\184\230\150\176\229\162\158\229\174\160\231\137\169 \229\143\145\229\184\131\228\184\141\229\186\148\229\135\186\231\142\176")
    end
    self:IncrementalRefreshByServer(petInfos)
    return
  end
  for _, PetInfo in ipairs(petInfos) do
    self:ReplaceByServerSingle(PetInfo)
  end
end

function BattlePlayerDeck:ReplaceByServerSingle(petInfo)
  local PetID = petInfo.battle_inside_pet_info.pet_id
  local Card = self:GetCardByGuid(PetID)
  if Card then
    Card:ReplaceByServer(petInfo)
    Card:RefreshByServer()
  else
    Log.Error("Can't find card with provided id", PetID)
  end
end

function BattlePlayerDeck:IncrementalRefreshByServer(petInfos)
  if not petInfos then
    return
  end
  for _, PetInfo in ipairs(petInfos) do
    local PetID = PetInfo.battle_inside_pet_info.pet_id
    local Card = self:GetCardByGuid(PetID)
    if Card then
      Card:OverwriteByServer(PetInfo)
      Card:RefreshByServer()
    else
      local index = #self.cards + 1
      self.cards[index] = BattleCard(self.Owner, PetInfo, index)
    end
  end
end

function BattlePlayerDeck:GetCardByGuid(Guid)
  for _, v in ipairs(self.cards) do
    if v.guid == Guid then
      return v
    end
  end
  return nil
end

function BattlePlayerDeck:ClearRidState()
  for _, v in ipairs(self.cards) do
    v:SetBeRidOf(false)
  end
end

function BattlePlayerDeck:ChangeBattlePet(battlePetId, restPetId)
  local BattleManager = _G.BattleManager
  local pawnManager = BattleManager.battlePawnManager
  local restPet = pawnManager:GetPetByGuid(restPetId)
  local teamEnm = self.Owner.teamEnm
  local team = self.Owner.team
  local index = 1
  local posInField = 1
  if restPet then
    teamEnm = restPet.teamEnm
    team = restPet.team
    index = restPet.index
    posInField = restPet.card.posInField
    restPet.card:RecallBattlePet(restPet)
  else
    local restCard = self:GetCardByGuid(restPetId)
    if restCard then
      index = restCard.pos
      posInField = restCard.posInField
      restCard:RecallBattlePet(nil)
    else
      Log.Error("Can't find pet with id ", battlePetId)
    end
  end
  local card = self:GetCardByGuid(battlePetId)
  if card then
    card.posInField = posInField
    Log.Debug("++++recalled list+++")
    team:PrintGuid()
    card:SummonBattlePet(teamEnm, team, index)
    Log.Debug("++++summoned list+++")
    team:PrintGuid()
  else
    Log.Error("Can't find pet with id ", battlePetId)
  end
end

function BattlePlayerDeck:RecallBattlePet(restPetId)
  local BattleManager = _G.BattleManager
  local pawnManager = BattleManager.battlePawnManager
  local restPet = pawnManager:GetPetByGuid(restPetId)
  restPet.card:RecallBattlePet(restPet)
end

function BattlePlayerDeck:SummonPetOnce(teamEnm, team, petInfos)
  local cards = {}
  for i = 1, #petInfos do
    local card = self:GetCardByGuid(petInfos[i].pet_id)
    if not card then
      Log.Warning("not find pet by id : ", petInfos[i].pet_id)
      return
    end
    if petInfos[i].pet_info.battle_inside_pet_info.pet_id then
      card:OverwriteByServer(petInfos[i].pet_info)
      card:RefreshByServer()
    end
    card.pos = petInfos[i].pet_pos
    card.posInField = petInfos[i].posInField or 1
    card:SetInBattleField(true)
    table.insert(cards, card)
  end
  return _G.BattleManager.battlePawnManager:SummonBattlePet(teamEnm, team, petInfos, cards)
end

function BattlePlayerDeck:GetCanSummonCards()
  local canSummonCards = {}
  for _, v in pairs(self.cards) do
    if v:CanSummon() then
      table.insert(canSummonCards, v)
    end
  end
  return canSummonCards
end

function BattlePlayerDeck:GetInBattleCards()
  local list = {}
  for _, v in pairs(self.cards) do
    if v:IsInBattle() then
      table.insert(list, v)
    end
  end
  return list
end

function BattlePlayerDeck:GetReservesPetCards()
  local list = {}
  for _, v in pairs(self.cards) do
    if not v:IsInBattle() then
      table.insert(list, v)
    end
  end
  return list
end

function BattlePlayerDeck:HasInBattleCards()
  for _, v in pairs(self.cards) do
    if v:IsInBattle() then
      return true
    end
  end
  return false
end

function BattlePlayerDeck:GetAliveCards()
  local aliveCards = {}
  for _, v in pairs(self.cards) do
    if v.hp > 0 then
      table.insert(aliveCards, v)
    end
  end
  return aliveCards
end

function BattlePlayerDeck:GetBattleFieldAliveCards()
  local aliveCards = {}
  for _, v in pairs(self.cards) do
    if not v.petState:GetDead() and v:IsInBattle() and not v:IsBeRidOf() then
      table.insert(aliveCards, v)
    end
  end
  return aliveCards
end

function BattlePlayerDeck:HasPetBeRidOf()
  for _, v in pairs(self.cards) do
    if v:IsInBattle() and v:IsBeRidOf() then
      return true
    end
  end
  return false
end

function BattlePlayerDeck:GetCardByIndex(CardIndex)
  for i = 1, #self.cards do
    if self.cards[i].CardIndex == CardIndex then
      return self.cards[i]
    end
  end
  return nil
end

function BattlePlayerDeck:Destroy()
  for i = 1, #self.cards do
    local card = self.cards[i]
    card:Destroy()
  end
  self.cards = nil
  self.Owner = nil
end

return BattlePlayerDeck
