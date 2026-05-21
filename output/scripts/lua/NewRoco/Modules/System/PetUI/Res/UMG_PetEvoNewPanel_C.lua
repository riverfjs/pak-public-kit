local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_PetEvoNewPanel_C = _G.NRCPanelBase:Extend("UMG_PetEvoNewPanel_C")

function UMG_PetEvoNewPanel_C:OnConstruct()
  self:OnAddEventListener()
  self.uiData = nil
  self:DispatchEvent(PetUIModuleEvent.OnNewEvoPanelOpened)
  self:DispatchEvent(PetUIModuleEvent.ShowPetInfoMainUI, false, true)
  self.bResultVisible = false
  self.bTouched = false
  self.startPosition = UE4.FVector2D(0, 0)
  self.isClickClose = false
  self.bCanClose = false
end

function UMG_PetEvoNewPanel_C:OnActive(_param, _param1)
  self:Log("OnActive")
  _G.NRCAudioManager:PlaySound2DAuto(1220002129, "UMG_PetEvoNewPanel_C:OnActive")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetBox").EVO
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetBox", touchReasonType)
  self.uiData = _param
  if 0 == _param1 then
    self:SetStepVisible(false)
  else
    self:SetStepVisible(true)
  end
end

function UMG_PetEvoNewPanel_C:OnDeactive()
end

function UMG_PetEvoNewPanel_C:OnAddEventListener()
  self:AddButtonListener(self.Close.btnClose, self.OnBtnCloseClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.RefreshPetData)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
end

function UMG_PetEvoNewPanel_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.RefreshPetData)
  self:UnRegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
end

function UMG_PetEvoNewPanel_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_PetEvoNewPanel_C:CloseSwitchButton(_IsDisabled)
  if _IsDisabled then
    self.bCanClose = false
    self.Close.btnClose:SetIsEnabled(false)
  else
    self.bCanClose = true
    self.Close.btnClose:SetIsEnabled(true)
  end
end

function UMG_PetEvoNewPanel_C:SetStepVisible(bool)
  if bool then
    if self.bResultVisible == false then
      self.PetEvolutionSelect:Hide()
      self.PetEvolutionResult:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PetEvolutionResult:Show(self.uiData[1], true)
    end
  else
    self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, false)
    self:DispatchEvent(PetUIModuleEvent.ShowHideRecommendedBtn, false)
    self:DispatchEvent(PetUIModuleEvent.ShowHideGiftColleaguesBtn, false)
    self:DispatchEvent(PetUIModuleEvent.ShowHideTimeRewindBtn, false)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetMainShareBtnVisibility, false)
    self.PetEvolutionSelect:Show(self.uiData[1].beforeBaseConfId, self.uiData[1])
    self.PetEvolutionResult:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.bResultVisible = bool
end

function UMG_PetEvoNewPanel_C:RefreshPetData(petData)
  local petEvoInfo = {}
  local petInfo = {}
  for k, v in ipairs(petData) do
    if v.pet_data and v.pet_data.gid == self.uiData[1].petGid then
      petInfo = v.pet_data
    end
  end
  table.insert(petEvoInfo, {
    beforeBaseConfId = self.uiData[1].beforeBaseConfId,
    afterBaseConfigId = petInfo.base_conf_id,
    petGid = petInfo.gid,
    evoIndex = self.uiData[1].evoIndex
  })
  self.uiData = petEvoInfo
end

function UMG_PetEvoNewPanel_C:OnBtnCloseClick()
  if not self.bCanClose then
    return
  end
  local panelName = "PetEvoNewPanel"
  local moduleName = "PetUIModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_PetLeftPanelMenuButton_C:OnTouchEnded")
  self:DispatchEvent(PetUIModuleEvent.OnNewEvoPanelClosed, false)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  self.isClickClose = true
  self:PlayAnimation(self.Out)
end

function UMG_PetEvoNewPanel_C:OnEvoSuccClose()
  self:DispatchEvent(PetUIModuleEvent.OnNewEvoPanelClosed, true)
  self:PlayAnimation(self.Out)
end

function UMG_PetEvoNewPanel_C:ShowReturnBtn(bShow)
  if bShow then
    self.Close:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Close:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetEvoNewPanel_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  self.bTouched = false
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetEvoNewPanel_C:OnAnimationFinished(anim)
  if anim == self.Out then
    if self.isClickClose then
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetEvoNewPanel").CLOSE
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetEvoNewPanel", touchReasonType)
      self.isClickClose = false
    end
    self:DispatchEvent(PetUIModuleEvent.OnNewEvoPanelDestruct)
    self:DoClose()
  end
end

return UMG_PetEvoNewPanel_C
