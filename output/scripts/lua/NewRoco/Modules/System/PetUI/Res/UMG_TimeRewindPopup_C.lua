local UMG_TimeRewindPopup_C = _G.NRCPanelBase:Extend("UMG_TimeRewindPopup_C")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = reload("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_TimeRewindPopup_C:OnConstruct()
  self.petGID = nil
  self.traceBackShowInfo = nil
  self.rewardList = nil
  self:SetChildViews(self.PopUp2)
end

function UMG_TimeRewindPopup_C:OnActive(petGID)
  Log.Debug("UMG_TimeRewindPopup_C:OnActive")
  self:LoadAnimation(0)
  self:SetCommonPopUpInfo(self.PopUp2)
  self:SetLoadingView(petGID)
end

function UMG_TimeRewindPopup_C:OnDeactive()
  self:RemoveButtonListener(self.DetailsBtn.btnLevelUp)
end

function UMG_TimeRewindPopup_C:OnAddEventListener()
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnClickDetailsBtn)
end

function UMG_TimeRewindPopup_C:ReceiveRspData(petGID, traceBackShowInfo, rewardList)
  if nil == petGID then
    Log.Error("UMG_TimeRewindPopup_C:OnActive petData is nil")
    return
  end
  if nil == traceBackShowInfo then
    Log.Error("UMG_TimeRewindPopup_C:OnActive traceBackShowInfo is nil")
    return
  end
  if nil == rewardList then
    Log.Error("UMG_TimeRewindPopup_C:OnActive rewardList is nil")
    return
  end
  self.petGID = petGID
  self.traceBackShowInfo = traceBackShowInfo
  self.rewardList = rewardList
  self:OnAddEventListener()
  self:UpdateView()
end

function UMG_TimeRewindPopup_C:OnAnimationFinished()
end

function UMG_TimeRewindPopup_C:SetLoadingView(petGid)
  if self.Switcher then
    self.Switcher:SetActiveWidgetIndex(1)
  end
  if self.Text then
    self.Text:SetText(LuaText.Loading)
  end
  if self.Loading then
    self:PlayAnimation(self.Loading, 0, 0)
  end
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.SendPetTraceBackReq, petGid, true)
end

function UMG_TimeRewindPopup_C:OnClickDetailsBtn()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentText = _G.DataConfigManager:GetLocalizationConf("pet_return_special_tip").msg
  local ContentTitle = _G.DataConfigManager:GetLocalizationConf("pet_return_special_title").msg
  Context:SetTitle(ContentTitle):SetContent(ContentText):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_TimeRewindPopup_C:UpdateView()
  if self.Switcher then
    self.Switcher:SetActiveWidgetIndex(0)
  end
  self:SetCommonPopUpInfo(self.PopUp2)
  self:SetTextContent()
  self:SetCurPetInfoView()
  self:SetBackTracePetInfoView()
  self:SetRewardListView()
end

function UMG_TimeRewindPopup_C:SetTextContent()
  if self.petGID == nil then
    Log.Error("UMG_TimeRewindPopup_C:SetTextContent curPetData is nil")
    return
  end
  local CurPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID)
  if nil == CurPetData then
    Log.Error("UMG_TimeRewindPopup_C:SetTextContent curPetData is nil")
    return
  end
  local TargetPetRollBackConfig = PetUtils.GetTargetPetRollBackConfig(CurPetData)
  if nil == TargetPetRollBackConfig then
    Log.Error("UMG_TimeRewindPopup_C:SetTextContent TargetPetRollBackConfig is nil")
    return
  end
  if TargetPetRollBackConfig.end_time and CurPetData.name then
    local BaseContent = LuaText.pet_return_describe_tip
    local year, month, day, hour, min = TargetPetRollBackConfig.end_time:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
    self.MainText:SetText(string.format(BaseContent, CurPetData.name, year, month, day, hour, min))
  end
end

function UMG_TimeRewindPopup_C:SetCurPetInfoView()
  if self.petGID == nil then
    Log.Error("UMG_TimeRewindPopup_C:SetCurPetInfoView curPetData is nil")
    return
  end
  local CurPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID)
  if nil == CurPetData then
    Log.Error("UMG_TimeRewindPopup_C:SetCurPetInfoView curPetData is nil")
    return
  end
  self.Name:SetText(CurPetData.name)
  self.PetLevel:SetText(CurPetData.level)
  local PetStarsList = PetUtils.GetPetStarsListByPetGID(CurPetData.gid)
  if PetStarsList then
    self.CatchHardLv:InitGridView(PetStarsList)
  end
  self.Pet:SetIconPathAndMaterial(CurPetData.base_conf_id, CurPetData.mutation_type, CurPetData.glass_info)
  self:SetPetTypeIcon(self.Attr, CurPetData)
end

function UMG_TimeRewindPopup_C:SetBackTracePetInfoView()
  if self.traceBackShowInfo == nil then
    Log.Error("UMG_TimeRewindPopup_C:SetBackTracePetInfoView traceBackShowInfo is nil")
    return
  end
  self.Name1:SetText(self.traceBackShowInfo.name)
  self.PetLevel1:SetText(self.traceBackShowInfo.level)
  local TempPetData = self.traceBackShowInfo
  local PetStarsList = PetUtils.GetPetStarsListByPetGID(nil, TempPetData)
  if PetStarsList then
    self.CatchHardLv1:InitGridView(PetStarsList)
  end
  self.Pet1:SetIconPathAndMaterial(self.traceBackShowInfo.base_conf_id, self.traceBackShowInfo.mutation_type, self.traceBackShowInfo.glass_info)
  self:SetPetTypeIcon(self.Attr1, self.traceBackShowInfo)
end

function UMG_TimeRewindPopup_C:SetRewardListView()
  if self.rewardList == nil then
    Log.Error("UMG_TimeRewindPopup_C:SetRewardListView rewardList is nil")
    return
  end
  self.RewardListTitleText:SetText(LuaText.pet_return_check_title)
  local rewardsTable = _G.NRCCommonItemIconData():FromGoodsItem(self.rewardList)
  self.RewardGridView:InitList(rewardsTable)
end

function UMG_TimeRewindPopup_C:SetPetTypeIcon(attrList, PetData)
  if PetData and PetData.base_conf_id and attrList then
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
    if PetBaseConf then
      local UnitType = PetBaseConf.unit_type
      local TypeList = {}
      for i, type in ipairs(UnitType or {}) do
        table.insert(TypeList, {Type = type})
      end
      if PetData.blood_id then
        local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(PetData.blood_id)
        if PetBloodConf then
          table.insert(TypeList, {
            Name = PetBloodConf.blood_name,
            Path = PetBloodConf.icon
          })
        end
      end
      attrList:InitGridView(TypeList)
      attrList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  end
end

function UMG_TimeRewindPopup_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = LuaText.pet_return_free_title
  CommonPopUpData.Btn_LeftText = LuaText.CANCEL
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnBtnCancelClicked
  CommonPopUpData.Btn_RightHandler = self.OnBtnOkClicked
  CommonPopUpData.ClosePanelHandler = self.OnPanelClose
  CommonPopUpData.Btn_RightGrayStatHandler = self.OnBtnOkClicked
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_TimeRewindPopup_C:OnBtnCancelClicked()
  self:ClosePanel()
end

function UMG_TimeRewindPopup_C:OnBtnOkClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_TimeRewindPopup_C:OnBtnOkClicked")
  Log.Debug("UMG_TimeRewindPopup_C:OnBtnOkClicked")
  if self.petGID == nil then
    return
  end
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID)
  if PetData and PetUtils.CheckPetIsCanTraceBack(PetData, false, false, false, self, self.ApplyTraceBackPvpOrPvePetCallback) then
    self:HandlePetTraceBack()
  end
end

function UMG_TimeRewindPopup_C:HandlePetTraceBack()
  Log.Debug("UMG_TimeRewindPopup_C:HandlePetTraceBack")
  if self.petGID == nil then
    Log.Error("UMG_TimeRewindPopup_C:HandlePetTraceBack petGID is nil")
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendPetTraceBackReq, self.petGID, false)
end

function UMG_TimeRewindPopup_C:ApplyTraceBackPvpOrPvePetCallback()
  Log.Debug("UMG_TimeRewindPopup_C:ApplyTraceBackPvpOrPvePetCallback")
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID)
  if PetData and PetUtils.CheckPetIsCanTraceBack(PetData, false, true, true) then
    self:HandlePetTraceBack()
  end
end

function UMG_TimeRewindPopup_C:OnPanelClose()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_TimeRewindPopup_C:OnActive")
  self:ClosePanel()
end

function UMG_TimeRewindPopup_C:ClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_TimeRewindPopup_C:OnActive")
  _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.ClosePetTraceBackPopup)
end

return UMG_TimeRewindPopup_C
