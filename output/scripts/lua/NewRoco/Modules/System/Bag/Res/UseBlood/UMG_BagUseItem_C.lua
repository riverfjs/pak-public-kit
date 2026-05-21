local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_BagUseItem_C = Base:Extend("UMG_BagUseItem_C")

function UMG_BagUseItem_C:OnConstruct()
end

function UMG_BagUseItem_C:OnDestruct()
  self.HeadBtn.OnClicked:Remove(self, self.OnHeadBtnClicked)
  self.SkillBtn.OnClicked:Remove(self, self.OnSkillBtnClicked)
end

function UMG_BagUseItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data[1]
  self.index = index
  self.HeadBtn.OnClicked:Remove(self, self.OnHeadBtnClicked)
  self.HeadBtn.OnClicked:Add(self, self.OnHeadBtnClicked)
  self.SkillBtn.OnClicked:Remove(self, self.OnSkillBtnClicked)
  self.SkillBtn.OnClicked:Add(self, self.OnSkillBtnClicked)
  self.SkillBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HeadBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetData()
end

function UMG_BagUseItem_C:SetData()
  local petBloodConf = _G.DataConfigManager:GetPetBloodConf(self.data.blood_id)
  self.BloodIcon:SetPath(petBloodConf.icon)
  self.Num:SetText(self.data.level)
  if petBloodConf.blood < Enum.PetBloodType.PBT_BOSS or petBloodConf.blood == Enum.PetBloodType.PBT_FANTASTIC then
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local skillConf
    if petBloodConf.blood == Enum.PetBloodType.PBT_FANTASTIC then
      local skill_data = self.data.skill.skill_data
      for _, skill in pairs(skill_data) do
        if skill.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
          break
        end
      end
    else
      local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.data.base_conf_id)
      skillConf = self:GetSkillData(petBloodConf.id, LevelSkillConf)
    end
    self.Attr:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if skillConf then
      self.SkillConfId = skillConf.id
      self.SkillIcon:SetPath(skillConf.icon)
      self.TxtSkillName:SetText(skillConf.name)
      local TypeText = ""
      if 1 ~= skillConf.damage_type then
        TypeText = tostring(skillConf.dam_para[1])
      else
        TypeText = "-"
      end
      self.TxtPnum:SetText(skillConf.energy_cost[1])
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
      local typeList = {
        {
          Name = TypeText,
          Path = typeDic.tips_res
        }
      }
      self.Attr:InitGridView(typeList)
    else
    end
  elseif petBloodConf.blood == Enum.PetBloodType.PBT_BOSS then
    self.SkillIcon:SetPath("Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BagItem/7010070.7010070'")
    self.TxtSkillName:SetText("\232\191\155\229\140\150\228\185\139\229\138\155")
    self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TxtPnumCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.base_conf_id)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if modelConf then
      self.HeadIcon:SetIconPathAndMaterial(self.data.base_conf_id, self.data.mutation_type, self.data.glass_info)
    end
  end
end

function UMG_BagUseItem_C:GetSkillData(blood_id, LevelSkillConf)
  if not LevelSkillConf then
    Log.Error("UMG_BagUseItem_C:GetSkillData  LevelSkillConf is nil")
    return nil
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
  end
end

function UMG_BagUseItem_C:OnItemSelected(_bSelected)
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_PetCharacterTemplate_C:OnItemSelected")
    self:StopAllAnimations()
    self:PlayAnimation(self.Select_In)
    self.SkillBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HeadBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    _G.NRCEventCenter:DispatchEvent(BagModuleEvent.SetPetBloodItemSelect, self.data)
  else
    self:StopAllAnimations()
    self.SkillBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Select_Out)
  end
end

function UMG_BagUseItem_C:OnHeadBtnClicked()
  local isLock = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagBloodIsSelected)
  if isLock then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").PETTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.ShowChangePetConfirm, self.data)
end

function UMG_BagUseItem_C:OnSkillBtnClicked()
  local isLock = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagBloodIsSelected)
  if isLock then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BagBlood").SKILLTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "BagModule", "BagBlood", touchReasonType)
  if self.data.blood_id < Enum.PetBloodType.PBT_BOSS or self.data.blood_id == Enum.PetBloodType.PBT_FANTASTIC then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, self.SkillConfId, false)
  elseif self.data.blood_id == Enum.PetBloodType.PBT_BOSS then
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPetBloodPulse, self.data)
  end
end

function UMG_BagUseItem_C:OnAnimationFinished(Animation)
end

function UMG_BagUseItem_C:OnDeactive()
end

return UMG_BagUseItem_C
