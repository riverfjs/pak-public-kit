local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local Base = BattleActionBase
local BattleShowTalentTreeAction = Base:Extend("BattleShowTalentTreeAction")
FsmUtils.MergeMembers(Base, BattleShowTalentTreeAction, {})

function BattleShowTalentTreeAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self:SetActionType(BattleActionBase.ActionType.ClientSkipableAction)
end

function BattleShowTalentTreeAction:GetSeasonPVEBaseConf()
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  local seasonId = seasonInfo and seasonInfo.season_id
  local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId, true)
  local seasonPveBaseConf = seasonConf and _G.DataConfigManager:GetSeasonPveBaseConf(seasonConf.season_pve_id, true)
  return seasonPveBaseConf
end

function BattleShowTalentTreeAction:OnEnter()
  local initData = BattleUtils.GetBattleInitInfo()
  if not (initData and initData.pve_info) or not initData.pve_info.had_season_talent then
    self:Finish()
    return
  end
  local seasonPveBaseConf = self:GetSeasonPVEBaseConf()
  if not seasonPveBaseConf then
    self:Finish()
    return
  end
  local pawnManager = _G.BattleManager.battlePawnManager
  local teamPets = pawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  local enemyPets = pawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  self.playingEffectCount = 0
  for _, pet in ipairs(teamPets) do
    if seasonPveBaseConf.res_id_0 and pet and UE.UObject.IsValid(pet.model) then
      self.playingEffectCount = self.playingEffectCount + 1
      local CastSkill = CastSkillObject.Create()
      CastSkill:SetCallbackOwner(self)
      CastSkill:SetCompleteCallback(self.OnEffectFinish)
      CastSkill:SetIsPassive(true)
      CastSkill:SetTargetPets({pet})
      pet:PlaySkillByPath(seasonPveBaseConf.res_id_0, self, self.OnEffectFinish, CastSkill)
    end
  end
  for _, pet in ipairs(enemyPets) do
    if seasonPveBaseConf.res_id_1 and pet and UE.UObject.IsValid(pet.model) then
      self.playingEffectCount = self.playingEffectCount + 1
      local CastSkill = CastSkillObject.Create()
      CastSkill:SetCallbackOwner(self)
      CastSkill:SetCompleteCallback(self.OnEffectFinish)
      CastSkill:SetIsPassive(true)
      CastSkill:SetTargetPets({pet})
      pet:PlaySkillByPath(seasonPveBaseConf.res_id_1, self, self.OnEffectFinish, CastSkill)
    end
  end
  if 0 == self.playingEffectCount then
    self:Finish()
  end
end

function BattleShowTalentTreeAction:OnEffectFinish()
  self.playingEffectCount = self.playingEffectCount - 1
  if self.playingEffectCount <= 0 then
    self:Finish()
  end
end

return BattleShowTalentTreeAction
