local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local BattlePlayerSkill = NRCClass()

function BattlePlayerSkill:Ctor()
  self.data = nil
  self.battlePieces = nil
  self.OnClickPet = nil
  self.Up_pet = nil
  self.callback = nil
  self.skillObj = nil
end

function BattlePlayerSkill:Init(data, battlePiecesPath, CurrentPlayer)
  if data then
    self.data = data
  end
  self.battlePiecesPath = battlePiecesPath
  self.CurrentPlayer = CurrentPlayer
end

function BattlePlayerSkill:SetData(data)
  if data then
    self.data = data
  end
end

function BattlePlayerSkill:PlayLinkEffect(BattlePet, callback)
  self.callback = callback
  if nil == BattlePet then
    Log.Error("BattlePlayerSkill:PlayLinkEffect no battlepet")
    self.CurrentPlayer:PreparePlayerSkill({}, true, callback)
  else
    if self.LinkEffectPet then
      self:CancelLinkEffect()
    end
    self:CancelLastEffect()
    self:OnPlay(BattlePet)
    self.CurrentPlayer:PreparePlayerSkill({
      BattlePet.model
    }, true, callback)
  end
  self.LinkEffectPet = BattlePet
end

function BattlePlayerSkill:OnPlay(Caster)
  Log.Debug("BattlePieceCounterSkillPrePlay :OnPlay", Caster.card.name)
  local skillPath = BattleConst.BattlePlayerPetLock
  if BattleSkillManager:IsResLoaded(skillPath) then
    self:OnSkillResLoad(true, skillPath, Caster)
  else
    BattleSkillManager:PreLoadSingleRes(skillPath, true, self, self.OnSkillResLoad, Caster)
  end
end

function BattlePlayerSkill:OnSkillResLoad(isLoadSucceed, skillPath, Caster)
  if not isLoadSucceed then
    return
  end
  local CastParam = CastSkillObject.Create()
  CastParam.ResID = skillPath
  CastParam:SetIsPassive(true)
  CastParam:SetCaster(Caster.model)
  CastParam:SetTargetPets({Caster})
  CastParam:SetSkillBreakCallback(function()
    self:OnFinish()
  end)
  CastParam:SetStartFailedCallback(function()
    self:OnFinish()
  end)
  if Caster.model then
    local _, skillObj = BattleSkillManager:PrepareSkill(Caster, Caster.model.RocoSkill, CastParam)
    self.skillObj = skillObj
    skillObj:RegisterEventCallback("SkillEnd", self, self.OnFinish)
    skillObj.Blackboard:SetValueAsInt("Loop_End", -1)
    BattleSkillManager:PlaySkill(skillObj, true)
  end
end

function BattlePlayerSkill:OnCancelSkill(BattlePet)
  if self.skillObj then
    self.skillObj.Blackboard:SetValueAsInt("Loop_End", 0)
  end
end

function BattlePlayerSkill:OnFinish()
  if self.callback then
    self.callback(self)
  end
end

function BattlePlayerSkill:CancelLinkEffect()
  local BattlePet = self.LinkEffectPet
  if not BattlePet or not BattlePet.model then
    Log.Error("BattlePlayerSkill:CancelLinkEffect no battlepet")
    self.CurrentPlayer:CancelPlayerSkill({})
  else
    self:OnCancelSkill(BattlePet)
    self.CurrentPlayer:CancelPlayerSkill({
      BattlePet.model
    })
  end
  self.LastEffectPet = BattlePet
  self.LinkEffectPet = nil
end

function BattlePlayerSkill:CancelLastEffect()
  if self.LastEffectPet then
    if self.skillObj and self.LastEffectPet.model and UE.UObject.IsValid(self.LastEffectPet.model) then
      self.LastEffectPet.model.RocoSkill:CancelSkill(self.skillObj, UE4.ESkillActionResult.SkillActionResultSuccessful)
    end
    self.LastEffectPet = nil
    self.skillObj = nil
  end
end

function BattlePlayerSkill:SetClickPetAndUpPet(OnClickPet, Up_pet)
  self.OnClickPet = OnClickPet
  self.Up_pet = Up_pet
end

function BattlePlayerSkill:GetClickPetAndUpPet()
  return self.OnClickPet, self.Up_pet
end

function BattlePlayerSkill:Play(...)
  self.battlePieces = BattlePiecesManager:Play(self.battlePiecesPath, ...)
end

function BattlePlayerSkill:Cancel()
  self.battlePieces:Cancel()
end

function BattlePlayerSkill:GetEffectType()
  local itemData = self.data
  if not itemData then
    Log.Error("itemData\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
    return
  end
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.conf_id)
  if BagItemConf and BagItemConf.player_skill_id then
    local PlayerMagicConf = _G.DataConfigManager:GetPlayerMagicConf(BagItemConf.player_skill_id)
    if PlayerMagicConf then
      local SkillConf = _G.DataConfigManager:GetSkillConf(PlayerMagicConf.skill_id)
      if SkillConf and SkillConf.skill_result then
        if 0 == #SkillConf.skill_result then
          return
        end
        if SkillUtils.IsBuff(SkillConf.skill_result[1].effect_id) then
          return -1
        else
          local EffectConf = _G.DataConfigManager:GetEffectConf(SkillConf.skill_result[1].effect_id)
          return EffectConf.effect_order
        end
      else
        Log.Error("SKILL_CONF\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
      end
    else
      Log.Error("PLAYER_MAGIC_CONF\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
    end
  else
    Log.Error("BAG_ITEM_CONF\233\133\141\231\189\174\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139")
  end
end

function BattlePlayerSkill:IsChangePetEffectType()
  local EffectType = self:GetEffectType()
  if EffectType == Enum.EffectType.ET_ROLE_CHANGE_PET then
    return true
  end
  return false
end

function BattlePlayerSkill:GetBloodLimit()
  local itemData = self.data
  local BagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.conf_id)
  if BagItemConf and BagItemConf.player_skill_id then
    local PlayerMagicConf = _G.DataConfigManager:GetPlayerMagicConf(BagItemConf.player_skill_id)
    if PlayerMagicConf then
      local SkillConf = _G.DataConfigManager:GetSkillConf(PlayerMagicConf.skill_id)
      return SkillConf.target_blood_limit
    end
  end
end

return BattlePlayerSkill
