local UMG_BloodPulse_Tips_C = _G.NRCPanelBase:Extend("UMG_BloodPulse_Tips_C")

function UMG_BloodPulse_Tips_C:OnActive(_petData)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_Battle_ChangePetConfirm_C:Show")
  self:OnAddEventListener()
  self.petData = _petData
  self:SetPaneInfo()
  self:PlayAnimation(self:GetAnimByIndex(0))
end

function UMG_BloodPulse_Tips_C:SetPaneInfo()
  if not self.petData then
    Log.Error("\231\178\190\231\129\181\230\149\176\230\141\174\230\178\161\230\156\137")
    return
  end
  local skillList = {}
  self.Pet:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  if PetBloodConf then
    self.BloodPulse:SetPath(PetBloodConf.icon)
    for i, v in ipairs(PetBloodConf.blood_skill) do
      local skillConf = _G.DataConfigManager:GetSkillConf(v)
      if skillConf then
        table.insert(skillList, {
          conf = skillConf,
          textDesc = "team_battle_text_5",
          parent = self
        })
      end
    end
  end
  local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.petData.base_conf_id)
  if LevelSkillConf then
    local skillConf = self:GetSkillData(self.petData.blood_id, LevelSkillConf)
    if skillConf then
      table.insert(skillList, {
        conf = skillConf,
        textDesc = "team_battle_text_6",
        parent = self
      })
    end
  end
  if skillList and #skillList > 0 then
    self.List:InitGridView(skillList)
  end
end

function UMG_BloodPulse_Tips_C:GetSkillData(blood_id, LevelSkillConf)
  if not LevelSkillConf then
    return
  end
  if blood_id == Enum.PetBloodType.PBT_COMMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_COMMON)
  elseif blood_id == Enum.PetBloodType.PBT_GRASS then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GRASS)
  elseif blood_id == Enum.PetBloodType.PBT_FIRE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIRE)
  elseif blood_id == Enum.PetBloodType.PBT_WATER then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WATER)
  elseif blood_id == Enum.PetBloodType.PBT_LIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_LIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_STONE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_STONE)
  elseif blood_id == Enum.PetBloodType.PBT_ICE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ICE)
  elseif blood_id == Enum.PetBloodType.PBT_DRAGON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DRAGON)
  elseif blood_id == Enum.PetBloodType.PBT_ELECTRIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_ELECTRIC)
  elseif blood_id == Enum.PetBloodType.PBT_TOXIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_TOXIC)
  elseif blood_id == Enum.PetBloodType.PBT_INSECT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_INSECT)
  elseif blood_id == Enum.PetBloodType.PBT_FIGHT then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_FIGHT)
  elseif blood_id == Enum.PetBloodType.PBT_WING then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_WING)
  elseif blood_id == Enum.PetBloodType.PBT_MOE then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MOE)
  elseif blood_id == Enum.PetBloodType.PBT_GHOST then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_GHOST)
  elseif blood_id == Enum.PetBloodType.PBT_DEMON then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_DEMON)
  elseif blood_id == Enum.PetBloodType.PBT_MECHANIC then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_MECHANIC)
  elseif blood_id == Enum.PetBloodType.PBT_PHANTOM then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.blood_skill_PHANTOM)
  elseif blood_id == Enum.PetBloodType.PBT_LEGENDARY then
    return _G.DataConfigManager:GetSkillConf(LevelSkillConf.legendary_skill)
  end
end

function UMG_BloodPulse_Tips_C:OnDeactive()
end

function UMG_BloodPulse_Tips_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseTips, self.OnClickbtnCloseTips)
  if self.CloseHyperLink then
    self.CloseHyperLink.OnClicked:Add(self, self.OnCloseHyperLink)
  end
end

function UMG_BloodPulse_Tips_C:OnClickbtnCloseTips()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002014, "UMG_BloodPulse_Tips_C:OnClickbtnCloseTips")
  self:PlayAnimation(self:GetAnimByIndex(2))
end

function UMG_BloodPulse_Tips_C:OnCloseHyperLink()
end

function UMG_BloodPulse_Tips_C:OnDescTextClicked(descText)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_BloodPulse_Tips_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_BloodPulse_Tips_C:OnPcClose()
  self:OnClickbtnCloseTips()
end

return UMG_BloodPulse_Tips_C
