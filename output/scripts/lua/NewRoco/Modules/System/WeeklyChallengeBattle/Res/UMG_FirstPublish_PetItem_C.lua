local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FirstPublish_PetItem_C = Base:Extend("UMG_FirstPublish_PetItem_C")

function UMG_FirstPublish_PetItem_C:OnConstruct()
end

function UMG_FirstPublish_PetItem_C:OnDestruct()
end

function UMG_FirstPublish_PetItem_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self:_InitPanel()
  self.bShouldPlaySound = true
end

function UMG_FirstPublish_PetItem_C:OnItemSelected(_bSelected)
  if _bSelected then
    self:PlayAnimation(self.select)
    if self.bShouldPlaySound then
      _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_FirstPublish_PetItem_C:OnItemSelected")
    end
    _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.ChangeFirstDebutPet, self.uiData)
  else
    self:PlayAnimation(self.cancel)
  end
end

function UMG_FirstPublish_PetItem_C:OnDeactive()
end

function UMG_FirstPublish_PetItem_C:_InitPanel()
  if self.uiData.gid == nil or 0 == self.uiData.gid then
    return
  end
  local petText = self.uiData.name
  self.SelectedName:SetText(petText)
  local levelText = string.format(_G.LuaText.umg_pass_awarditem1_1, self.uiData.level)
  self.SelectedGrade:SetText(levelText)
  if 1 == self.uiData.gender then
    self.Switcher_gender:SetActiveWidgetIndex(0)
  else
    self.Switcher_gender:SetActiveWidgetIndex(1)
  end
  self.HeadIcon:SetIconPathAndMaterial(self.uiData.base_conf_id, self.uiData.mutation_type, self.uiData.glass_info)
  local hpMax = self.uiData.attribute_new_info.addi_attr_data[_G.Enum.AttributeType.AT_HPMAX].addi_attr
  local hpCur = hpMax
  if self.uiData.attribute_new_info.addi_attr_data[_G.Enum.AttributeType.AT_HPCUR] then
    hpCur = self.uiData.attribute_new_info.addi_attr_data[_G.Enum.AttributeType.AT_HPCUR]
  end
  self.ProgressQuantity:SetText(string.format("%s/%s", hpCur, hpMax))
  self.schedule:SetPercent(hpCur / hpMax)
end

function UMG_FirstPublish_PetItem_C:SetShouldPlaySound(shouldPlaySound)
  self.bShouldPlaySound = shouldPlaySound
end

function UMG_FirstPublish_PetItem_C:OpItem(opType, ...)
  if 1 == opType then
    local firstArg = select(1, ...)
    self:SetShouldPlaySound(firstArg)
  end
end

function UMG_FirstPublish_PetItem_C:OnAnimationFinished(Anim)
  if Anim == self.select then
    self.NRCImage_0:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFC65FFF"))
  elseif Anim == self.cancel then
    self.NRCImage_0:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("272727FF"))
  end
end

return UMG_FirstPublish_PetItem_C
