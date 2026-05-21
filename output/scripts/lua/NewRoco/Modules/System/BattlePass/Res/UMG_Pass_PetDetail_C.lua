local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattlePassModuleEvent = reload("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local UMG_Pass_PetDetail_C = _G.NRCPanelBase:Extend("UMG_Pass_PetDetail_C")

function UMG_Pass_PetDetail_C:OnActive(petbaseId, unLock, shinyDefault, ResListData, petData)
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_Pass_PetDetail_C:OnActive")
  self.petData = petData
  self.IsShowHeterBtn = false
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  if petBaseConf and petBaseConf.relate_boss_id and 0 ~= petBaseConf.relate_boss_id then
    petbaseId = petBaseConf.relate_boss_id
  end
  if petBaseConf and petBaseConf.have_shiny and 1 == petBaseConf.have_shiny and not petData then
    self.Heterochrome:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImage:SetVisibility(shinyDefault and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.NRCImage_28:SetVisibility(shinyDefault and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.IsShining = not not shinyDefault
    self.IsShowHeterBtn = true
  else
    self.Heterochrome:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.UMG_PetImage3D:OnActive(petbaseId, "BattlePassPetDetail")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetIsFirstLoadBackground, true)
  self:UpdateSelectPetData(petbaseId)
  self.isInitPet3D = false
  self.isUnlock = unLock
  self.skillList = self:CreatePetSkills()
  self.OldTabIndex = 0
  self.Tab_Property:OnActive(0)
  if self.skillList then
    self.Tab_Skill:OnActive(1)
  else
    self.Tab_Skill:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Tab_Property:OnClickButton()
  self:BindInputAction()
  local SelectPetShowSkill = self.module:GetRes("SkillBlueprint'/Game/NewRoco/Modules/System/PetUI/Raw/G6/G6_SwitchPetShow_UI.G6_SwitchPetShow_UI_C'", "BattlePassPetDetail")
  self.UMG_PetImage3D.SelectPetShowSkill = SelectPetShowSkill
  self.UMG_PetImage3D:OpenDetailCameraLocation(1, true, false)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").PET)
end

function UMG_Pass_PetDetail_C:CreatePetData(petbaseId)
  local data = {}
  data.base_conf_id = petbaseId
  if self.petData then
    data.mutation_type = self.petData.mutation_type
    data.glass_info = self.petData.glass_info
    data.nature = self.petData.nature
  else
    data.mutation_type = _G.Enum.MutationDiffType.MDT_NONE
    data.glass_info = nil
  end
  return data
end

function UMG_Pass_PetDetail_C:CreatePetSkills()
  if self.curSelectId == nil then
    return nil
  end
  local LevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.curSelectId)
  local skillList = {}
  if LevelSkillConf and LevelSkillConf.level then
    for i, level in pairs(LevelSkillConf.level) do
      table.insert(skillList, level.param)
    end
  end
  return skillList
end

function UMG_Pass_PetDetail_C:OnConstruct()
  self:OnAddEventListener()
  self:SetChildViews(self.PetSkillMain, self.Tab_Property, self.Tab_Skill, self.UMG_PetImage3D)
end

function UMG_Pass_PetDetail_C:OnDestruct()
  self:UnBindInputAction()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, true)
end

function UMG_Pass_PetDetail_C:OnDeactive()
  self:UnBindInputAction()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateSelectPetData, self.UpdateSelectPetData)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdatePetTableView, self.UpdatePetTableView)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.ClearSelection, self.ClearSelection)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.OnShowEvolutionaryBtn, self.OnShowEvolutionaryBtn)
end

function UMG_Pass_PetDetail_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PassPetDetailUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local actions = {
    {
      name = "IA_ClosePassPetDetailUI",
      method = "OnPcClose"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, action.method)
  end
end

function UMG_Pass_PetDetail_C:UnBindInputAction()
  local actions = {
    {
      name = "IA_ClosePassPetDetailUI"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  end
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PassPetDetailUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_Pass_PetDetail_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnClickCloseBtn()
end

function UMG_Pass_PetDetail_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.Heterochrome, self.OnHeterochromeBtn)
  self:AddButtonListener(self.EvolutionaryChain.btnLevelUp, self.OnOpenEvolutionaryChain)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, BattlePassModuleEvent.UpdateSelectPetData, self.UpdateSelectPetData)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, BattlePassModuleEvent.UpdatePetTableView, self.UpdatePetTableView)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, BattlePassModuleEvent.ClearSelection, self.ClearSelection)
  self:RegisterEvent(self, BattlePassModuleEvent.ResetDescText, self.ResetDescText)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PetDetail_C", self, PetUIModuleEvent.SelectSkill, self.OnSelectSkill)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_PetDetail_C", self, BattlePassModuleEvent.OnShowEvolutionaryBtn, self.OnShowEvolutionaryBtn)
end

function UMG_Pass_PetDetail_C:OnSelectSkill()
  if self.EvolutionaryChain and self.EvolutionaryChain:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.EvolutionaryChain:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pass_PetDetail_C:OnHeterochromeBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1073, "UMG_Pass_PetDetail_C:OnHeterochromeBtn")
  self:ResetDescText()
  if self.curPetData == nil then
    return
  end
  self.IsShining = not self.IsShining
  if self.IsShining then
    self.curPetData.mutation_type = _G.Enum.MutationDiffType.MDT_SHINING
  else
    self.curPetData.mutation_type = self.petData and self.petData.mutation_type or _G.Enum.MutationDiffType.MDT_NONE
  end
  if self.IsShining then
    self.curPetData.mutation_type = _G.Enum.MutationDiffType.MDT_SHINING
    self.NRCImage:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCImage_28:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.curPetData.mutation_type = self.petData and self.petData.mutation_type or _G.Enum.MutationDiffType.MDT_NONE
    self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_28:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:UpdateShinyPetData()
end

function UMG_Pass_PetDetail_C:OnOpenEvolutionaryChain()
  self:ResetDescText()
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_Pass_PetDetail_C:OnOpenEvolutionaryChain")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdEvolutionaryChainPanel, self.curSelectId, self.isUnlock, self.IsShining)
end

function UMG_Pass_PetDetail_C:UpdateSelectPetData(petbaseId)
  if nil == petbaseId or self.curSelectId == petbaseId then
    return
  end
  self.curSelectId = petbaseId
  self.curPetData = self:CreatePetData(petbaseId)
  if self.IsShining then
    self.curPetData.mutation_type = _G.Enum.MutationDiffType.MDT_SHINING
  else
    self.curPetData.mutation_type = self.petData and self.petData.mutation_type or _G.Enum.MutationDiffType.MDT_NONE
  end
  self:ShowPetModel3D(self.curPetData)
  if self.isInitPet3D == false then
    self.UMG_PetImage3D:OpenDetailCameraLocation(1)
    self.isInitPet3D = true
  end
  local petTabIndex = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetPetSelectTabIndex)
  self:UpdatePetTableView(petTabIndex)
  self.PetSkillMain.ItemList:ClearSelection()
end

function UMG_Pass_PetDetail_C:UpdateShinyPetData()
  self:ShowPetModel3D(self.curPetData)
  if self.isInitPet3D == false then
    self.UMG_PetImage3D:OpenDetailCameraLocation(1)
    self.isInitPet3D = true
  end
end

function UMG_Pass_PetDetail_C:UpdatePetTableView(tabIndex)
  if self.curPetData == nil then
    return
  end
  local petData = self.curPetData
  if not petData then
    return
  end
  local petBaseId = petData.base_conf_id
  local isSwitch = self.OldTabIndex ~= tabIndex
  if isSwitch then
    if 0 == self.OldTabIndex then
      self.Pass_Property:PlayOutAnimation()
    else
      if 1 == self.OldTabIndex then
        self.PetSkillMain:PlayOutAnimation()
      else
      end
    end
  end
  if 0 == tabIndex then
    self:UpdatePetProperty(petBaseId)
    if isSwitch then
      self.Pass_Property:PlayInAnimation()
    end
    self.Pass_Property:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetSkillMain:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:ClearSelection()
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsHavePetSkillTips)
  elseif 1 == tabIndex then
    self:UpdatePetSkill(petBaseId)
    if isSwitch then
      self.PetSkillMain:PlayInAnimation()
    end
    self.Pass_Property:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetSkillMain:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.OldTabIndex = tabIndex
  self:ResetDescText()
end

function UMG_Pass_PetDetail_C:OnDescTextClicked(id)
  local descText = _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.GetDescText)
  if descText[1] then
    for i = 1, #descText do
      if descText[i] == id then
        return
      else
        _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.SetDescText, id)
      end
    end
  else
    _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.SetDescText, id)
  end
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.ShowBtnClosePanel)
  local descNote = _G.DataConfigManager:GetDescNoteConf(tonumber(id))
  local descText = string.format("\227\128\144%s\227\128\145\n%s", descNote.note, descNote.desc)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
end

function UMG_Pass_PetDetail_C:ResetDescText()
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.ClearDescText)
  _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.HideBtnClosePanel)
end

function UMG_Pass_PetDetail_C:ClearSelection()
  if self.PetSkillMain then
    self.PetSkillMain.ItemList:ClearSelection()
  end
  self.EvolutionaryChain:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.curSelectId then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.curSelectId)
    if petBaseConf and petBaseConf.have_shiny and 1 == petBaseConf.have_shiny then
      self.Heterochrome:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.HeadPortrait_in)
    end
  end
end

function UMG_Pass_PetDetail_C:UpdatePetBasics(petBaseId)
  self.Pass_Basics:UpdatePanel(petBaseId)
end

function UMG_Pass_PetDetail_C:UpdatePetProperty(petBaseId)
  self.Pass_Property:UpdatePanel(petBaseId)
end

function UMG_Pass_PetDetail_C:UpdatePetSkill(petBaseId)
  if self.skillList then
    self.PetSkillMain:UpdatePanel(petBaseId, self.skillList)
  end
end

function UMG_Pass_PetDetail_C:ShowPetModel3D(petData)
  local baseId = petData.base_conf_id
  local petBaseCfg = _G.DataConfigManager:GetPetbaseConf(baseId)
  if petBaseCfg then
    local modelScale = petBaseCfg.pet_ui_percentage and petBaseCfg.pet_ui_percentage > 0 and petBaseCfg.pet_ui_percentage or 1
    local heightModelScale = self:GetHeightModelScaleByPetData(baseId)
    modelScale = modelScale * heightModelScale
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseCfg.model_conf)
    if modelConf then
      self.UMG_PetImage3D.PetBaseConf = petBaseCfg
      self.UMG_PetImage3D:SetPath(modelConf.path, false, nil, petData, false)
    end
  end
  self.UMG_PetImage3D:SetAnimList({"Alert", "Relax"}, 2, {
    "Alert",
    "Becute",
    "Happy",
    "Fear",
    "Relax",
    "Shock",
    "Sad"
  })
end

function UMG_Pass_PetDetail_C:GetHeightModelScaleByPetData(petBaseId)
  if not petBaseId then
    return 1
  end
  local petbaseId = petBaseId
  local petBaseCfg = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  local height = petBaseCfg.height_high
  local heightModelScale = PetMutationUtils.GetHeightModelScale(petbaseId, height)
  return heightModelScale
end

function UMG_Pass_PetDetail_C:OnClickCloseBtn()
  if self:IsAnimationPlaying(self.Out) then
    Log.Info("UMG_Pass_PetDetail_C:OnClickCloseBtn isPlayingAnimation")
    return
  end
  self:ResetDescText()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Pass_PetDetail_C:OnClickCloseBtn")
  self:OnClose()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClosePetSKillTips)
end

function UMG_Pass_PetDetail_C:OnShowEvolutionaryBtn(isShow)
  if isShow then
    if self.IsShowHeterBtn then
      self.Heterochrome:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.EvolutionaryChain:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    if self.IsShowHeterBtn then
      self.Heterochrome:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.EvolutionaryChain:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Pass_PetDetail_C
