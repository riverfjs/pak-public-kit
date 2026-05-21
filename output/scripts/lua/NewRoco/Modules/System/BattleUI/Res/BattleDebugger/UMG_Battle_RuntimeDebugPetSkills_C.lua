local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Battle_RuntimeDebugPetSkills_C = Base:Extend("UMG_Battle_RuntimeDebugPetSkills_C")

function UMG_Battle_RuntimeDebugPetSkills_C:OnConstruct()
  self.debugControl = _G.BattleManager.battleRuntimeData.battleDebugControl
  self.allSkill = self.debugControl:GetAllSkillList()
  for i, v in pairs(self.allSkill) do
    if v:find("7000010") then
      self.defaultSkill = v
    end
  end
  self.ComboBoxStringSkills:ClearOptions()
  self.ComboBoxStringSkills.OnOpening:Add(self, self.FilterOptions)
  self.EditableTextBoxAttackCount:SetText("1")
end

function UMG_Battle_RuntimeDebugPetSkills_C:OnDestruct()
  self.ComboBoxStringSkills.OnOpening:Remove(self, self.FilterOptions)
end

function UMG_Battle_RuntimeDebugPetSkills_C:FilterOptions()
  local filter = self.EditableTextBoxSearch:GetText()
  local filterCoping
  local isFilterCoping = self.CheckBoxCoping:IsChecked()
  if isFilterCoping then
    local targetSkillId = self.skillPanel:GetFirstSelectSkill(self.team)
    local skillCfg = _G.SkillUtils.GetSkillConf(targetSkillId, true)
    if skillCfg then
      local countType = self.debugControl:GetSkillCountTypeTostring(skillCfg.Skill_Type)
      filterCoping = self.debugControl:SkillTypeTostring(countType)
    end
    Log.Debug("UMG_Battle_RuntimeDebugPetSkills_C:FilterOptions", filterCoping, targetSkillId)
  end
  for i, v in pairs(self.allSkill) do
    if (string.IsNilOrEmpty(filter) or v:find(string.lower(filter))) and (string.IsNilOrEmpty(filterCoping) or v:find(filterCoping)) then
      if self.ComboBoxStringSkills:FindOptionIndex(v) < 0 then
        self.ComboBoxStringSkills:AddOption(v)
      end
    elseif self.ComboBoxStringSkills:FindOptionIndex(v) >= 0 then
      self.ComboBoxStringSkills:RemoveOption(v)
    end
  end
end

function UMG_Battle_RuntimeDebugPetSkills_C:OnItemUpdate(_data, datalist, index)
  self.pos = _data.pos
  self.team = _data.team
  self.skillPanel = _data.skillPanel
  self.index = index
  self:FilterOptions()
  self.ComboBoxStringSkills:SetSelectedOption(self.defaultSkill)
end

function UMG_Battle_RuntimeDebugPetSkills_C:GetSkillCmd()
  local skillKey = self.ComboBoxStringSkills:GetSelectedOption()
  local skillId = self.debugControl:GetSkillIdByKey(skillKey) or 7000010
  local attackCount = tonumber(self.EditableTextBoxAttackCount:GetText()) or 1
  local isKill = self.CheckBoxKill:IsChecked()
  return skillId, attackCount, isKill
end

return UMG_Battle_RuntimeDebugPetSkills_C
