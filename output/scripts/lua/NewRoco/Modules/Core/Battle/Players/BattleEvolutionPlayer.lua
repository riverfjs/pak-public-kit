local EventDispatcher = require("Common.EventDispatcher")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUIModuleEvent = require("NewRoco.Modules.System.BattleUI.BattleUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvolutionPlayer = BattlePlayerBase:Extend("BattleEvolutionPlayer")

function BattleEvolutionPlayer:Ctor(owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.newPet = nil
end

function BattleEvolutionPlayer:Reset()
  self.evolutionInfo = nil
  self.target = nil
  self.Player = nil
  self.type = nil
  self.performNode = nil
  self.evolutionBaseId = nil
  self.evolutionAttrs = nil
  self.newPet = nil
  self.oldPetName = nil
end

function BattleEvolutionPlayer:Play(performNode)
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer:Play")
  _G.BattleManager.battleRuntimeData:ClearEvolutionCachedData()
  self:Reset()
  self:InitFromNode(performNode)
  self.BattlePet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.evolutionInfo.pet_id)
  self.EnemyPetList = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  self.BattlePetList = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  if not self.BattlePet then
    Log.Debug("BattleEvolutionPlayer cannt find battlepet")
    self:OnFinish()
    return
  end
  self.Player = self.BattlePet.player
  local evolutionBaseId = self.evolutionInfo.pet_info.battle_inside_pet_info.base_conf_id
  self.evolutionBaseId = evolutionBaseId
  self.oldPetName = self.BattlePet.card.name
  local oldAttributes = self.BattlePet.card.petInfo.battle_inside_pet_info
  local newAttributes = self.evolutionInfo.pet_info.battle_inside_pet_info
  self:CompareEvolutionAttrs(oldAttributes, newAttributes)
  local resultName = _G.DataConfigManager:GetPetbaseConf(self.evolutionBaseId).name
  _G.BattleManager.battleRuntimeData:SetEvolutionResultInfo(resultName, self.evolutionAttrs)
  if self.performNode.IsFastPlay then
    Log.Debug("Battle Evo Progress: BattleEvolutionPlayer FastPlay")
    self:OpenResultPanel()
  else
    Log.Debug("Battle Evo Progress: BattleEvolutionPlayer Performance(Load G6 Asset)")
    _G.BattleResourceManager:LoadClassAsync(self, BattleConst.Evolution.PetEvolutionAnimWorldStart, self.LoadSkillClassOver)
  end
end

function BattleEvolutionPlayer:LoadSkillClassOver(skillClass)
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer skillClass Loaded")
  local Caster = self.BattlePet
  local model
  if Caster and Caster.model then
    Log.Debug("BattlePlayAnimBaseAction SceneCharacter")
    model = Caster.model
  else
    Log.Error("no model found for evolution")
    self:OnSkillComplete()
  end
  if self.BattlePetList and #self.BattlePetList > 0 then
    for k, v in ipairs(self.BattlePetList) do
      v:ChangeBuffVisibility(false)
    end
  end
  if self.EnemyPetList and #self.EnemyPetList > 0 then
    for k, v in ipairs(self.EnemyPetList) do
      v:ChangeBuffVisibility(false)
    end
  end
  if skillClass and model then
    local skillObj = model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
    skillObj:SetCaster(model)
    skillObj:RegisterEventCallback("OpenEvoPanel", self, self.OpenBattleEvoPanel)
    skillObj:SetPassive(true)
    skillObj.Blackboard:SetValueAsInt("Nextok", -1)
    Log.Debug("Battle Evo Progress: BattleEvolutionPlayer model.RocoSkill:LoadAndPlaySkill")
    model.RocoSkill:LoadAndPlaySkill(skillObj)
    _G.BattleManager.battleRuntimeData.isEvolutionWaiting = true
  else
    Log.Debug("Battle Evo Progress: BattleEvolutionPlayer skill class or model not found, force OnSkillComplete")
    self:OnSkillComplete()
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED, BattleEvent.EVOLUTION_OPEN_RESULT)
end

function BattleEvolutionPlayer:OpenBattleEvoPanel(event, skill)
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer skillEvent(OpenEvoPanel) -> BattleUIModuleCmd.OpenBattleEvolutionPanel")
  self.skillObjInLoop = skill
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleUIModuleEvent.OnBattleEvolutionPanelShown, self.HandleEvent_OnBattleEvolutionPanelShown)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleEvolutionPanel, self.BattlePet, self.evolutionInfo, false, skill)
  self:SafeDelaySeconds("d_SkillObjTimeout", 3, function()
    self:NotifySkillJumpToEnd()
  end)
end

function BattleEvolutionPlayer:HandleEvent_OnBattleEvolutionPanelShown()
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer HandleEvent_OnBattleEvolutionPanelShown -> NotifySkillJumpToEnd")
  self:NotifySkillJumpToEnd()
end

function BattleEvolutionPlayer:NotifySkillJumpToEnd()
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer NotifySkillJumpToEnd")
  _G.NRCEventCenter:UnRegisterEvent(self, BattleUIModuleEvent.OnBattleEvolutionPanelShown, self.HandleEvent_OnBattleEvolutionPanelShown)
  self:SafeCancelDelayById("d_SkillObjTimeout")
  if self.skillObjInLoop and UE4.UObject.IsValid(self.skillObjInLoop) then
    self.skillObjInLoop.Blackboard:SetValueAsInt("Nextok", 0)
  else
    self:OnSkillComplete()
  end
  self.skillObjInLoop = nil
end

function BattleEvolutionPlayer:CompareEvolutionAttrs(oldAttrs, newAttrs)
  local oldTypes = PetUtils.GetPetTypes(oldAttrs)
  local newTypes = PetUtils.GetPetTypes(newAttrs)
  if oldTypes[1] ~= newTypes[1] or oldTypes[2] ~= newTypes[2] or oldTypes[3] ~= newTypes[3] then
    self.evolutionAttrs = newTypes
  end
end

function BattleEvolutionPlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.evolutionInfo = performInfo.pet_evolution
end

function BattleEvolutionPlayer:OnSkillComplete()
  Log.Debug("BattleEvolutionPlayer Play OnSkillComplete:", self.performNode:GetNodeIdx())
  if self.BattlePet then
    self.BattlePet:Destroy()
    self.BattlePet = nil
  end
  if self.newPet then
    self.newPet:ShowPet()
    self.newPet = nil
  end
  if self.EnemyPetList and #self.EnemyPetList > 0 then
    for k, v in ipairs(self.EnemyPetList) do
      v:ChangeBuffVisibility(true)
    end
  end
  self.performNode:PerformComplete()
  self:OnFinish()
end

function BattleEvolutionPlayer:OpenResultPanel(name, skill)
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer OpenResultPanel")
  local petInfo = self.evolutionInfo.pet_info
  local card = self.Player.deck:GetCardByGuid(self.evolutionInfo.pet_id)
  if not card then
    Log.Warning("not find pet by id : ", self.evolutionInfo.pet_id)
    return
  end
  if petInfo.battle_inside_pet_info.pet_id then
    card:OverwriteByServer(petInfo)
    card:RefreshByServer()
    card:RefreshByInfoAndBaseConf(petInfo, self.evolutionBaseId)
  end
  card.pos = petInfo.battle_inside_pet_info.pos
  card:SetInBattleField(true)
  _G.BattleManager:AddEventListener(self, BattleEvent.PET_SPAWNED, self.OnPawnNewPetFinish)
  self.newPet = _G.BattleManager.battlePawnManager:PawnPet(card.owner.teamEnm, self.Player.team, card, self.Player)
end

function BattleEvolutionPlayer:OnPawnNewPetFinish(pet)
  if self.newPet == pet then
    self:DoOnPawnNewPetFinish()
  end
end

function BattleEvolutionPlayer:DoOnPawnNewPetFinish()
  self.newPet:SetScale(1)
  self.newPet:HidePet()
  self.newPet:PinOnTheGround()
  if self.performNode.IsFastPlay or self.newPet.player ~= _G.BattleManager.battlePawnManager.TeamatePlayer or BattleUtils.IsWatchingBattle() or BattleUtils.IsReplayMode() then
    self:TimeOutFinish()
  else
    self.performNode:AddTimeoutDuration(20)
    local asyncData = {
      owner = self,
      callback = self.ResultFinish
    }
    NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenBattlePetEvolutionFinishPanel, self.evolutionBaseId, self.oldPetName, self.newPet:GetPetGid())
    local TimeOutTime = _G.DataConfigManager:GetBattleGlobalConfig("exit_evolve_finish_time").num
    self:SafeDelaySeconds("d_TimeOutFinish", TimeOutTime, self.TimeOutFinish, self)
  end
end

function BattleEvolutionPlayer:TimeOutFinish()
  Log.Debug("Battle Evo Progress: TimeOutFinish")
  NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleEvolutionPanel)
  _G.BattleManager.battleRuntimeData.isEvolutionWaiting = false
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PROCESS_EVOLUTION_END)
  if self.performNode and not self.performNode.IsPerformOver then
    self:ResultFinish()
  end
end

function BattleEvolutionPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
  elseif eventName == BattleEvent.EVOLUTION_OPEN_RESULT then
    Log.Debug("Battle Evo Progress: BattleEvolutionPlayer BattleEvent.EVOLUTION_OPEN_RESULT")
    self:OpenResultPanel()
    return true
  end
end

function BattleEvolutionPlayer:OnFinish()
  _G.BattleEventCenter:UnBind(self)
  self:SafeCancelDelayById("d_TimeOutFinish")
  UE4.UNRCStatics.ToggleSkybox(true)
  _G.BattleManager.battleRuntimeData.isEvolutionWaiting = false
end

function BattleEvolutionPlayer:ResultFinish()
  Log.Debug("Battle Evo Progress: BattleEvolutionPlayer:ResultFinish")
  NRCModeManager:DoCmd(BattleUIModuleCmd.TryDestroyBattleEvoActors)
  if _G.BattleManager.vBattleField.battleCameraManager then
    _G.BattleManager.vBattleField.battleCameraManager:CalcPos()
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet(nil, nil, nil, true)
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerPet()
  end
  UE4.UNRCStatics.ToggleSkybox(true)
  self:OnSkillComplete()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattlePetEvolutionFinishPanel)
end

return BattleEvolutionPlayer
