local UMG_ChooseAlternativePet_C = _G.NRCPanelBase:Extend("UMG_ChooseAlternativePet_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")

function UMG_ChooseAlternativePet_C:OnActive(petList, startIndex)
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_ChooseAlternativePet_C:OnActive")
  self.petList = petList
  self:UpdateUI()
  self.startIndex = startIndex
  self:OnAddEventListener()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtnClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  CommonPopUpData.Btn_LeftHandler = self.OnCloseBtnClick
  CommonPopUpData.Btn_RightHandler = self.OnSaveBtnClick
  self.PopUp3:SetPanelInfo(CommonPopUpData)
  self:LoadAnimation(0)
end

function UMG_ChooseAlternativePet_C:OnDeactive()
end

function UMG_ChooseAlternativePet_C:OnAddEventListener()
  NRCEventCenter:RegisterEvent("UMG_ChooseAlternativePet", self, PetUIModuleEvent.ChangeChoosePetIndex, self.ChangeIndex)
end

function UMG_ChooseAlternativePet_C:OnCloseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_ChooseAlternativePet_C:OnCloseBtnClick")
  self:OnClose()
end

function UMG_ChooseAlternativePet_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
end

function UMG_ChooseAlternativePet_C:UpdateUI()
  self.NRCGridView_54:InitGridView(self.petList)
  self.NRCGridView_54:SelectItemByIndex(0)
  self.selectIndex = 1
  self.PopUp3.Btn_Right.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ChooseAlternativePet_C:ChangeIndex(index)
  self.selectIndex = index
end

function UMG_ChooseAlternativePet_C:OnSaveBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ChooseAlternativePet_C:OnSaveBtnClick")
  if self.selectIndex then
    self:DispatchEvent(PetUIModuleEvent.AdjustLostPet, self.startIndex, self.petList[self.selectIndex])
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_select_recommend_pet)
    self:OnClose()
  end
end

return UMG_ChooseAlternativePet_C
