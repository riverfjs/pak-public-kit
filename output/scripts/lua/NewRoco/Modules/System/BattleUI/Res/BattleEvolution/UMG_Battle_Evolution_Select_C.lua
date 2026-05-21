local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local PetUIModule = require("NewRoco.Modules.System.PetUI.PetUIModuleCmd")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_Battle_Evolution_Select_C = _G.NRCPanelBase:Extend("UMG_Battle_Evolution_Select_C")

function UMG_Battle_Evolution_Select_C:Construct()
  self._enter = false
  self._press = false
  self:AddListeners()
  self.petBaseConfId = nil
  self.uiData = nil
  self.Gid = nil
  self.battlePetId = nil
end

function UMG_Battle_Evolution_Select_C:Destruct()
  self:RemoveListeners()
  UpdateManager:UnRegister(self)
end

function UMG_Battle_Evolution_Select_C:OnActive()
  self:Show()
  self:BindInputAction()
end

function UMG_Battle_Evolution_Select_C:AddListeners()
  self.BtnConfirm.btnLevelUp.OnClicked:Add(self, self.OnBtnConfirmClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Evolution_Select_C", self, PetUIModuleEvent.PetEvolutionFail, self.OnPetEvolutionFail)
end

function UMG_Battle_Evolution_Select_C:RemoveListeners()
  self.BtnConfirm.btnLevelUp.OnClicked:Remove(self, self.OnBtnConfirmClicked)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.PetEvolutionFail, self.OnPetEvolutionFail)
end

function UMG_Battle_Evolution_Select_C:Show(petBaseConfId, petData)
  UpdateManager:Register(self)
  self.uiData = petData
  self.Gid = petData and petData.petGid
  if not petBaseConfId then
    local battleEvolutionData = _G.BattleManager.battleRuntimeData.evolutionData
    if not battleEvolutionData then
      Log.Warning("No battle evolution info found")
      return
    end
    local ids = {}
    for i, data in ipairs(battleEvolutionData) do
      local pet = _G.BattleManager.battlePawnManager:GetPetByGuid(data.pet_id)
      local card = pet and pet.card
      local petInfo = card and card.petInfo
      local insideInfo = petInfo and petInfo.battle_inside_pet_info
      self.Gid = pet.card.petInfo.battle_common_pet_info.gid
      self.battlePetId = insideInfo and insideInfo.pet_id
      if pet then
        table.insert(ids, pet.card.petInfo.battle_common_pet_info.base_conf_id)
      end
    end
    self:UpdateText(ids)
    self:UpdateIcon()
    self:UpdateIBlackMask()
  else
    local ids = {petBaseConfId}
    self:UpdateText(ids)
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self:UpdateIcon()
    self.petBaseConfId = petBaseConfId
    self:ShowQuestionMark(true)
    self:UpdateIBlackMask()
  end
end

function UMG_Battle_Evolution_Select_C:OnTick(InDeltaTime)
  local petPos = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetHeadSlotScreenPos)
  if petPos and self.QuestionMark and self.QuestionMark.Slot then
    self.QuestionMark.Slot:SetPosition(petPos)
  end
end

function UMG_Battle_Evolution_Select_C:Hide()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Evolution_Select_C:ShowQuestionMark(bShow)
  if bShow then
    self.QuestionMark:PlayAnimation(self.QuestionMark.In)
    self.QuestionMark:PlayAnimation(self.QuestionMark.Loop, 0, 0)
    self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.QuestionMark:PlayAnimation(self.QuestionMark.Out)
  end
end

function UMG_Battle_Evolution_Select_C:UpdateIcon()
  local globalConfigID = _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG
  local path = _G.DataConfigManager:GetGlobalConfigByKeyType("pet_evolution_btn1", globalConfigID).str
end

function UMG_Battle_Evolution_Select_C:UpdateIBlackMask()
  if _G.BattleManager.isInBattle then
    self.BlackMask:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BlackMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Evolution_Select_C:UpdateText(petBaseConfIds)
  self.globalConfigID = _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG
  local confirmBtnTxt = _G.DataConfigManager:GetGlobalConfigByKeyType("pet_evolution_button_1", self.globalConfigID).str
  self.BtnConfirm:SetBtnText(confirmBtnTxt)
  local rawTxt = ""
  for i, id in ipairs(petBaseConfIds) do
    local txt = self:ConstructEvolutionText(id)
    rawTxt = rawTxt .. txt
    rawTxt = rawTxt .. "\n"
  end
  self.UMG_TypeWritter:Writer(rawTxt, 1.0E-5, 1, true)
  self.UMG_TypeWritter:Initiate()
end

function UMG_Battle_Evolution_Select_C:ConstructEvolutionText(petBaseConfId)
  local dialogTxt = _G.DataConfigManager:GetGlobalConfigByKeyType("pet_evolution_text_1", self.globalConfigID).str
  local petName
  if petBaseConfId then
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId)
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.Gid)
    local battleManager = _G.BattleManager
    local battlePawnManager = battleManager and battleManager.battlePawnManager
    local battlePetId = self.battlePetId
    local battleCard = battlePawnManager and battlePawnManager:GetCardByGuid(battlePetId)
    local petInfo = battleCard and battleCard.petInfo
    local insidePetInfo = petInfo and petInfo.battle_inside_pet_info
    if insidePetInfo then
      petName = insidePetInfo and insidePetInfo.name
    elseif PetData then
      petName = PetData.name
    else
      Log.Error("UMG_Battle_Evolution_Select_C:ConstructEvolutionText gid is nil")
    end
  else
    petName = _G.BattleManager.battleRuntimeData.evolutionPetName
  end
  local rawTxt = string.format(dialogTxt, petName)
  return rawTxt
end

function UMG_Battle_Evolution_Select_C:OnBtnConfirmClicked()
  local panelName = "PetEvoNewPanel"
  local moduleName = "PetUIModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    return
  end
  if BattleUtils.IsWatchingBattle() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PetLeftPanelMenuButton_C:OnTouchEnded")
  if self.petBaseConfId == nil then
    _G.BattleEventCenter:Dispatch(BattleEvent.EVOLUTION_CONFIRM)
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleRedPanel)
    self:ClearAllEnhancedInput()
    if self.panelData then
      self:DoClose()
    end
  else
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).EVOLUTIONCONFIRM
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SendPetEvoluteReq, self.uiData.petGid, self.uiData.evoIndex)
    self:ShowQuestionMark(false)
  end
end

function UMG_Battle_Evolution_Select_C:OnPetEvolutionFail()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ShowQuestionMark(true)
end

function UMG_Battle_Evolution_Select_C:OnCinematicEnd()
end

function UMG_Battle_Evolution_Select_C:SetMousePress()
  self._press = true
  self:SetBackGround_Select()
end

function UMG_Battle_Evolution_Select_C:SetMouseRelease()
  self._press = false
  self:SetBackGround()
end

function UMG_Battle_Evolution_Select_C:SetBackGround()
  self.Background:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_Evolution_Select_C:SetBackGround_Select()
  if self._press then
    self.Background:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Battle_Evolution_Select_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_BattleEvolutionSelect")
  if mappingContext then
    mappingContext:BindAction("IA_CloseBattleEvolutionSelect", self, "OnPcClose2")
  end
end

function UMG_Battle_Evolution_Select_C:OnPcClose2()
  self:OnBtnConfirmClicked()
end

return UMG_Battle_Evolution_Select_C
