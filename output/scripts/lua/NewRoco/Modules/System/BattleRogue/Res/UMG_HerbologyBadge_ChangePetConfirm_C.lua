local Base = _G.NRCPanelBase
local RogueUtils = require("NewRoco.Modules.System.BattleRogue.RogueModuleUtils")
local UMG_HerbologyBadge_ChangePetConfirm_C = Base:Extend("UMG_HerbologyBadge_Energy_C")

function UMG_HerbologyBadge_ChangePetConfirm_C:OnConstruct()
  Base.OnConstruct(self)
  self:AddButtonListener(self.CloseBtn, self.OnCloseClicked)
  self.SkillList.parentPanel = self
end

function UMG_HerbologyBadge_ChangePetConfirm_C:Active(EventData)
  Base.Active(self)
  self:PlayAnimation(self.TweenIn)
  local MonsterConf = RogueUtils.GetMonsterConfByEventID(EventData.event_conf_id)
  if not MonsterConf then
    self:LogError("Monster Conf is nil")
    return
  end
  self.NameTxt:SetText(MonsterConf.name)
  self.LvTxt:SetText(string.format(LuaText.umg_pass_awarditem1_1, EventData.level or MonsterConf.level or MonsterConf.new_level[1]))
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(MonsterConf.base_id)
  self.Attr:InitGridView(PetBaseConf.unit_type)
  if MonsterConf.gender == Enum.GenderType.GT_FEMALE then
    self.ImagePetGender2:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  elseif MonsterConf.gender == Enum.GenderType.GT_MALE then
    self.ImagePetGender1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  self.HeadIcon:SetIconPathAndMaterial(MonsterConf.base_id)
  self.SizeBox_67:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  local SkillConf = _G.DataConfigManager:GetSkillConf(PetBaseConf.pet_feature)
  self.SkillNameTxt:SetText(SkillConf.name)
  self.NRCTextDes:SetText(SkillConf.desc)
  self.SkillIcon:SetPath(SkillConf.icon)
  local SkillData = self:BuildSkillDataList(EventData.random_skills)
  self.SkillList:InitGridView(SkillData)
end

function UMG_HerbologyBadge_ChangePetConfirm_C:Deactive()
  self:PlayAnimation(self.TweenOut)
end

function UMG_HerbologyBadge_ChangePetConfirm_C:OnAnimationFinished(Animation)
  if Animation == self.TweenOut then
    self:DoClose()
  end
end

function UMG_HerbologyBadge_ChangePetConfirm_C:OnCloseClicked()
  self:StopAllAnimations()
  self:PlayAnimation(self.TweenOut)
end

function UMG_HerbologyBadge_ChangePetConfirm_C:BuildSkillDataList(RandomSkills)
  local SkillDataList = {}
  if not RandomSkills or 0 == #RandomSkills then
    return SkillDataList
  end
  for _, SkillId in ipairs(RandomSkills) do
    local SkillConf = _G.DataConfigManager:GetSkillConf(SkillId)
    if SkillConf.type == Enum.SkillActiveType.SAT_FEATURE then
    elseif SkillId and SkillId > 0 then
      local skillData = {
        id = SkillId,
        skill_id = SkillId,
        cost_energy = 0,
        perform_flag = 0,
        petGuid = nil,
        curBattleBaseId = nil
      }
      table.insert(SkillDataList, skillData)
    end
  end
  return SkillDataList
end

return UMG_HerbologyBadge_ChangePetConfirm_C
