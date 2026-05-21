local Base = require("NewRoco.Modules.Activity.Activity.Template.UMG_Activity_Base_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_Activity_PetPeer_C = Base:Extend("UMG_Activity_PetPeer_C")

function UMG_Activity_PetPeer_C:BindUIElements()
  local uiElements = {}
  uiElements.desireActivityType = Enum.ActivityType.ATP_PET_PARTNER
  uiElements.title = self.Text_Title
  uiElements.promptText = self.Text_Describe
  uiElements.particularsBtn = self.BtnParticulars
  uiElements.bgImage = self.BG
  uiElements.timeRemainingRoot = self.shijian
  uiElements.timeRemaining = self.Text_TimeRemaining
  uiElements.openAnimName = "In"
  uiElements.changeAnimName = "In"
  return uiElements
end

function UMG_Activity_PetPeer_C:OnConstruct()
  Base.OnConstruct(self)
  self:OnAddEventListener()
  if self.Particulars then
    self.Particulars:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RegisterEvent(self, ActivityModuleEvent.RefreshPetPartnerInheritUI, self.OnRefreshItemView)
end

function UMG_Activity_PetPeer_C:OnEnable(firstLoad)
  Base.OnEnable(self, firstLoad)
  local activityInst = {
    self.activityInst
  }
  self.List:InitList(ActivityUtils.CreateActivityItemBaseDataForList(self, activityInst))
end

function UMG_Activity_PetPeer_C:OnDestruct()
  Base.OnDestruct(self)
  self:RemoveAllButtonListener()
end

function UMG_Activity_PetPeer_C:OnAddEventListener()
end

function UMG_Activity_PetPeer_C:OnParticularsClicked()
  self.activityInst:OnBtnShowActivityDesc()
end

function UMG_Activity_PetPeer_C:OnRefreshItemView(isReceived)
  for i = 1, self.List:GetItemCount() do
    local item = self.List:GetItemByIndex(i - 1)
    if item then
      item:OnRefreshItemView()
      if isReceived then
        item:OnPlayerReceiveAnimation()
      end
    end
  end
end

function UMG_Activity_PetPeer_C:OnBtnReceiveClicked()
  local choosePetID, choosePetEggID = self.activityInst:GetChoosedPetBaseIDAndEggID()
  
  local function OnPopUpOk()
    if 0 ~= choosePetID and 0 ~= choosePetEggID then
      self.activityInst:ReceivePartnerPetEggReq()
    end
  end
  
  local extraDesc = LuaText.PET_Partner_13
  if self.activityInst:GetPartnerPetData() and not self.activityInst:IsChooseInheritPet() then
    extraDesc = LuaText.PET_Partner_20
  end
  local popUpData = _G.NRCCommonPopUpData()
  popUpData.Desc = extraDesc
  popUpData.Call = self
  popUpData.Btn_RightHandler = OnPopUpOk
  popUpData.ItemList = {
    [1] = {
      itemType = _G.Enum.GoodsType.GT_BAGITEM,
      itemId = choosePetEggID,
      itemNum = 1,
      BagNum = 1,
      ConsumeNum = 1,
      bShowNum = false,
      titleText = LuaText.PET_Partner_12,
      rightBtnCountdown = 5,
      AssignQuality = 5
    }
  }
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenCommonPopUpWithItem, popUpData)
end

return UMG_Activity_PetPeer_C
