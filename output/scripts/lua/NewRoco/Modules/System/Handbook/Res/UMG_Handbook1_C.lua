local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_Handbook1_C = _G.NRCPanelBase:Extend("UMG_Handbook1_C")

function UMG_Handbook1_C:OnConstruct()
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self.areaHandbookConfs = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.AREA_HANDBOOK):GetAllDatas()
  self.handbookRewardConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_HANDBOOK_REWARD):GetAllDatas()
  self.CoverItems = {
    self.UMG_Cover_Item_1,
    self.UMG_Cover_Item_2,
    self.UMG_Cover_Item_3,
    self.UMG_Cover_Item_5,
    self.UMG_Cover_Item_6,
    self.UMG_Cover_Item_4
  }
  self:OnUpdateTopicPoint()
  self:OnAddEventListener()
  self:AddInputMappingContext("IMC_HandBookMainUI")
  self:PreLoadCoverRes()
end

function UMG_Handbook1_C:OnDestruct()
  if not self.IsPlayAnimOpen then
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
  end
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnUpdateTopicPoint)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCloseAreaHandbookChangPanel, true)
end

function UMG_Handbook1_C:OnActive(arg)
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_PET_ALBUM)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.AreaHandbookChangePanel, false)
  self.data = self.module:GetData("HandbookModuleData")
  self.module:UpdateSelectPageRedPoint()
  self:OnShowAwardText()
  if UE4.UObject.IsValid(self.ParticleSystemWidget2_48) then
    self.ParticleSystemWidget2_48:SetActivate(false)
    self.ParticleSystemWidget2_48:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.CloseBtn:SetStyle(1)
  self:ShowRewardCount()
  self:ShowCoverItems()
  self.data:ChangeAreaHandbookInfo()
  local areaConf = _G.DataConfigManager:GetAreaHandbook(self.data.CurHandbookAreaId)
  self:SetCommonTitle()
  self.Title1:SetSubtitle(areaConf.name)
  self.Title1:SetBg(areaConf.icon)
  self.NRCImage_76:SetPath(areaConf.trophy_res)
  self.NRCImage_3:SetPath(areaConf.cover_res)
  self.OpenIcon:SetPath(areaConf.cover_open_btn)
  self.OpenIcon_1:SetPath(areaConf.cover_open_btn_bg)
  self:UpdatePanelInfo()
  if arg and type(arg) == "table" and arg.isPlayCompass and _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  if arg and type(arg) == "table" and arg.openCollectRewards then
    self:OnOpenCollectRewards()
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").BOOK
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  self:PlayAnimation(self.Open)
end

function UMG_Handbook1_C:OnEnable()
end

function UMG_Handbook1_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_HandBookMainUI")
  if mappingContext then
    mappingContext:DisableInputMappingContext()
    mappingContext:EnableInputMappingContext(self.depth)
    mappingContext:BindAction("IA_CloseHandBookMainUI", self, "OnPcClose", UE.ETriggerEvent.Triggered)
    mappingContext:BindAction("IA_CloseHandBookQuick", self, "OnPcClose", UE.ETriggerEvent.Triggered)
    self.bindActionSucceed = true
  end
end

function UMG_Handbook1_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_HandBookMainUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseHandBookMainUI")
    mappingContext:UnBindAction("IA_CloseHandBookQuick")
  end
end

function UMG_Handbook1_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Handbook1_C:OnPcClose()
  if self.AreaPanel and self.AreaPanel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
    self.AreaPanel:OnClosePanel()
  else
    self:OnClosePanel()
  end
end

function UMG_Handbook1_C:ShowCoverItems()
  local coverInfos = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetHandbookCoverInfos)
  for i = 1, #self.CoverItems do
    if coverInfos[i] then
      if 0 == coverInfos[i].handbook_id then
        self.CoverItems[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local info = {
          HandbookId = coverInfos[i].handbook_id,
          PetBaseId = coverInfos[i].pet_base_id,
          State = coverInfos[i].state,
          IconPath = coverInfos[i].iconPath
        }
        self.CoverItems[i]:SetVisibility(UE4.ESlateVisibility.Visible)
        self.CoverItems[i]:ShowCoverItem(info, coverInfos[i].rotate_angle, self)
      end
    else
      self.CoverItems[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Handbook1_C:ShowRewardCount()
  local handbookRewardConf = self.handbookRewardConfs
  local handbookRewardInfos = {}
  for i, v in pairs(handbookRewardConf) do
    local info = {
      handbook_number = v.handbook_number,
      belong_area_handbook = v.belong_area_handbook
    }
    table.insert(handbookRewardInfos, info)
  end
  table.sort(handbookRewardInfos, function(a, b)
    return a.handbook_number < b.handbook_number
  end)
  local handbookModuleData = _G.NRCModuleManager:GetModule("HandbookModule").data
  self.Lihe:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local handbookType = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookEnum)
  local areaInfo = handbookModuleData:GetCurAreaHandbookInfo()
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 0, 1)
  self.Dot:SetupKey(redId)
  if areaInfo and areaInfo.collect_coll_num ~= nil then
    local curCount = areaInfo.collect_coll_num
    local maxCount = 300
    local isRewardCount = 0
    for i = 1, #handbookRewardInfos do
      if handbookType == handbookRewardInfos[i].belong_area_handbook and curCount < handbookRewardInfos[i].handbook_number then
        maxCount = handbookRewardInfos[i].handbook_number
        isRewardCount = i - 1
        break
      end
    end
    self.shuliang:SetText(maxCount - curCount)
  end
end

function UMG_Handbook1_C:OnDeactive()
  self:UnRegisterEvent(self, HandbookModuleEvent.OnUpdateHandbookCover)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangeAreaData)
  if self.data then
    self.data.CurHandbookAreaType = _G.Enum.AreaHandbookType.AHT_KINGDOM
  end
end

function UMG_Handbook1_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClosePanel)
  self:AddButtonListener(self.Btnjiangbei, self.OnOpenCollectRewards)
  self:AddButtonListener(self.openBtn, self.OpenMainPanel)
  self:AddButtonListener(self.openBtn_1, self.OnOpenMainPanel)
  self:AddButtonListener(self.CollectionProgressBtn, self.ClickCollectionProgressBtn)
  self:RegisterEvent(self, HandbookModuleEvent.OnUpdateHandbookCover, self.UpdateRewardText)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangeAreaData, self.OnChangeArea)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnUpdateTopicPoint)
end

function UMG_Handbook1_C:ClickCollectionProgressBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Handbook1_C:ClickCollectionProgressBtn")
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenCollectionProgressTips)
end

function UMG_Handbook1_C:OnChangeArea(areaData)
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 0, 1)
  self.Dot:SetupKey(redId)
  self.cacheAreaData = areaData.conf
  self.OpenIcon:SetPath(areaData.conf.cover_open_btn)
  self.OpenIcon_1:SetPath(areaData.conf.cover_open_btn_bg)
  self:PlayAnimation(self.Change1)
  self.MoneyButton:SetVisibility(areaData.conf.area_handbook_type == _G.Enum.AreaHandbookType.AHT_KINGDOM and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Handbook1_C:OnChangeAnimationFinshed()
  self:PlayAnimation(self.Change2)
  if self.cacheAreaData then
    self.Title1:SetSubtitle(self.cacheAreaData.name)
    self.Title1:SetBg(self.cacheAreaData.icon)
    self.NRCImage_76:SetPath(self.cacheAreaData.trophy_res)
    self.NRCImage_3:SetPath(self.cacheAreaData.cover_res)
    self:UpdatePanelInfo()
  end
end

function UMG_Handbook1_C:OnOpenCollectRewards()
  _G.NRCAudioManager:PlaySound2DAuto(40004001, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self:PlayAnimation(self.Lizi)
  if UE4.UObject.IsValid(self.ParticleSystemWidget2_48) then
    self.ParticleSystemWidget2_48:SetActivate(true)
    self.ParticleSystemWidget2_48:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookTrophyPanel)
end

function UMG_Handbook1_C:OpenMainPanel()
  self:PlayAnimation(self.Open_click)
  self:Enable()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004001, "UMG_Handbook1_C:OpenMainPanel")
  self:PlayAnimation(self.Book_Open)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnHideAreaHandbookChangPanel, true)
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookPanel, {isShowBookAim = true})
  self.IsPlayAnimOpen = true
end

function UMG_Handbook1_C:OnOpenMainPanel()
  if self:IsAnimationPlaying(self.Book_Open) then
    return
  end
  self:Enable()
  self:PlayAnimation(self.Book_Open)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnHideAreaHandbookChangPanel, true)
  _G.NRCProfilerLog:NRCClickBtn(true, "HandbookMain")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookPanel, {isShowBookAim = true})
  self.IsPlayAnimOpen = true
end

function UMG_Handbook1_C:OnOpenAimMainPanel()
  self:Enable()
  self:PlayAnimation(self.Book_Open)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnHideAreaHandbookChangPanel, true)
  self.IsPlayAnimOpen = true
end

function UMG_Handbook1_C:ReverseAnimation()
  self:UpdatePanelInfo()
  if self.enableView == false then
    self:PlayAnimationReverse(self.Book_Open)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnHideAreaHandbookChangPanel, false)
  end
  self:Enable()
  self.IsPlayAnimOpen = false
end

function UMG_Handbook1_C:UpdatePanelInfo()
  self:ShowRewardCount()
  self:ShowCoverItems()
  self:OnShowAwardText()
end

function UMG_Handbook1_C:UpdateRewardText()
  self:ShowRewardCount()
  self:OnShowAwardText()
end

function UMG_Handbook1_C:OnShowAwardText()
  if self.data == nil then
    return
  end
  local handBookType = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookEnum)
  self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  local isAward, isCollectAll = self.data:CheckAwardRedPoint()
  if isCollectAll then
    self.chengjiu:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.shuliang:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.shuliang_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.chengjiu_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.chengjiu_1:SetText(LuaText.handbook_collect_progress_4)
  else
    self.chengjiu:SetVisibility(isAward and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.shuliang:SetVisibility(isAward and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.shuliang_1:SetVisibility(isAward and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.chengjiu_1:SetVisibility(isAward and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.chengjiu:SetText(_G.DataConfigManager:GetLocalizationConf("handbook_collect_progress").msg)
    self.chengjiu_1:SetText(_G.DataConfigManager:GetLocalizationConf("handbook_collect_progress_3").msg)
  end
  self.Quantity:SetText(self.data.CollectedCount)
end

function UMG_Handbook1_C:OnClosePanel()
  self:UnBindInputAction()
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_Handbook1_C:OnClosePanel")
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnMainUISubPanelClosed, false)
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.CloseHandbookCover)
end

function UMG_Handbook1_C:OnAnimationFinished(anim)
  if anim == self.Lizi then
    if UE4.UObject.IsValid(self.ParticleSystemWidget2_48) then
      self.ParticleSystemWidget2_48:SetActivate(false)
      self.ParticleSystemWidget2_48:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif anim == self.Book_Open then
    if self.IsPlayAnimOpen then
      self:Disable()
      self:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  elseif anim == self.Change1 then
    self:OnChangeAnimationFinshed()
  elseif anim == self.Change2 then
  elseif anim == self.Open then
    if not self.bindActionSucceed then
      self:BindInputAction()
    end
    if self.module:HasPanel("SeasonHandBookPhoto") then
      self.module:ClosePanel("SeasonHandBookPhoto")
    end
  end
end

function UMG_Handbook1_C:PreLoadCoverRes()
  for _, cfg in pairs(self.areaHandbookConfs or {}) do
    if 1 ~= cfg.id then
      _G.NRCResourceManager:LoadResAsync(self, cfg.cover_res, -1, -1, nil, nil)
    end
  end
end

function UMG_Handbook1_C:OnUpdateTopicPoint()
  local moneyCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_TOPIC_POINT)
  self.MoneyButton:SetInfo(_G.Enum.VisualItem.VI_TOPIC_POINT, moneyCount)
end

function UMG_Handbook1_C:OnClickedSeasonHandBook()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Handbook1_C:OnClickedSeasonHandBook")
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenHandbookSeasonList)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenSeasonHandBook)
end

return UMG_Handbook1_C
