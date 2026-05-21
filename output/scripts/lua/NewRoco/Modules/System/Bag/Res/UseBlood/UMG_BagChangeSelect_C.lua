local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local UMG_BagChangeSelect_C = _G.NRCPanelBase:Extend("UMG_BagChangeSelect_C")

function UMG_BagChangeSelect_C:OnConstruct()
  self:SetChildViews(self.PopUp1)
end

function UMG_BagChangeSelect_C:OnDestruct()
end

function UMG_BagChangeSelect_C:OnActive()
  self.data = self.module:GetData("BagModuleData")
  self.descText = ""
  self:SetCommonPopUpInfo(self.PopUp1)
  self.PetItemData = self.data.PetBloodItem
  self:SetItemList()
  self.PopUp1:SetDescInfo("\232\175\183\233\128\137\230\139\169\233\156\128\232\166\129\228\191\174\230\148\185\231\154\132\232\161\128\232\132\137\229\177\158\230\128\167")
  self.NRCImage_87:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BagChangeSelect_C:SetItemList()
  local BloodList = {}
  local ChangeBlood = self.data.ChangeBlood
  local petBloodConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_BLOOD_CONF):GetAllDatas()
  for i, v in pairs(petBloodConfs) do
    if v.id <= 18 then
      table.insert(BloodList, {
        BloodId = v.id,
        IsCurrentBloodId = self.PetItemData and self.PetItemData.blood_id == v.id
      })
    end
  end
  self.SortList:InitGridView(BloodList)
  self:OnAddEventListener()
  self:LoadAnimation(0)
end

function UMG_BagChangeSelect_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.SetPetBloodChangeItemSelect, self.OnItemSelected)
end

function UMG_BagChangeSelect_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCancel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_BagChangeSelect_C:OnItemSelected(Data)
  self.selectType = Data
  if Data then
    self.NRCImage_87:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.selectType)
    local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.PetItemData.base_conf_id)
    local skillConf = PetUtils.GetSkillBloodData(PetBloodConf.id, LevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.PetItemData)
    self.ChangeSkillId = skillConf.id
    self.SkillIcon:SetPath(skillConf.icon)
    self.Type:SetText(skillConf.name)
    self.descText = skillConf.desc
    self.Type_5:SetText(skillConf.desc)
    if 1 ~= skillConf.damage_type then
      self.NumericalValue:SetText(tostring(skillConf.dam_para[1]))
    else
      self.NumericalValue:SetText("-")
    end
    self.NumericalValue_1:SetText(skillConf.energy_cost[1])
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    if typeDic then
      self.SkillShuIcon:SetPath(typeDic.type_icon)
    end
    self.Department:SetPath(self:GetSkillTypePath(skillConf.Skill_Type, skillConf.damage_type))
    local allTextStr = string.format(LuaText.all_nature_blood_attribute_choose, self.PetItemData.name, PetBloodConf.blood_name)
    self.PopUp1:SetDescInfo(allTextStr)
  else
    self.NRCImage_87:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SkillCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BagChangeSelect_C:ResetDescText()
end

function UMG_BagChangeSelect_C:GetSkillTypePath(type, damage_type)
  if type == Enum.SkillType.ST_DAMAGE then
    if damage_type == Enum.DamageType.DT_SPC then
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04_png.ui_pet_attribute_04_png'"
    else
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02_png.ui_pet_attribute_02_png'"
    end
  elseif type == Enum.SkillType.ST_DEFEND then
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_DEFENSE_png.AT_DEFENSE_png'"
  else
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_CLASSIFICATION_png.AT_CLASSIFICATION_png'"
  end
end

function UMG_BagChangeSelect_C:OnAddEventListener()
  self:AddButtonListener(self.Btn1.btnLevelUp, self.OnOk)
  self:AddButtonListener(self.Btn2.btnLevelUp, self.OnCancel)
  _G.NRCEventCenter:RegisterEvent("UMG_BagChangeSelect_C", self, BagModuleEvent.SetPetBloodChangeItemSelect, self.OnItemSelected)
  _G.NRCEventCenter:RegisterEvent("UMG_BagChangeSelect_C", self, BagModuleEvent.ResetDescText, self.ResetDescText)
  self.Type_5.OnRichTextClick:Add(self, self.OnDescTextClicked)
end

function UMG_BagChangeSelect_C:OnCancel()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Bag_BXTips_C:OnClose")
  self:LoadAnimation(2)
  self.IsOkBtn = false
end

function UMG_BagChangeSelect_C:OnOk()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Bag_BXTips_C:OnClose")
  if not self.selectType then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.change_attribute_select_tip)
    return
  end
  self:LoadAnimation(2)
  self.IsOkBtn = true
end

function UMG_BagChangeSelect_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    if self.IsOkBtn then
      self.data.ChangeBlood = self.selectType
      _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.TalentChange, false)
    else
      self.data.ChangeBlood = nil
      _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenOrCloseCharacterPanelToList, self.data.CharacterPanelEnum.TalentChange, false)
    end
  end
end

function UMG_BagChangeSelect_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_BagChangeSelect_C:OnCloseHyperLink()
end

return UMG_BagChangeSelect_C
