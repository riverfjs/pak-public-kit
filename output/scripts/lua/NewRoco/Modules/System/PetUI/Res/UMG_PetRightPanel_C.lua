local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local HandbookModuleEnum = require("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local UMG_PetRightPanel_C = _G.NRCPanelBase:Extend("UMG_PetRightPanel_C")
local FULL_SCREEN_SHOW_TIME = 1

function UMG_PetRightPanel_C:OnConstruct()
  self:SetChildViews(self.petBaseInfo, self.PetSkillMain, self.Impression, self.btnMenu1, self.btnMenu2, self.btnMenu3, self.btnMenu4, self.btnMenu5, self.PetGrowUp, self.UMG_MedalPanel)
  self.Pet_HatchingAttribute:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.menuButtons = {
    self.btnMenu1,
    self.btnMenu2,
    self.btnMenu3,
    self.btnMenu4,
    self.btnMenu5,
    self.btnMenu6
  }
  self.petInfoMainCtrl = nil
  self.petLeftPanel = nil
  self.IsShowShareBox = false
  self:InitComboBox()
  self.isEnterScreen = false
  self.isEnterFree = false
end

function UMG_PetRightPanel_C:OnActive(petInfoMain, petData, bShowSendMark)
  petData = petData or self.module:GetCurrPetData()
  local icon1 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_basci_icon3_png.ui_petinfo_basci_icon3_png'"
  local icon2 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_basci_icon3_png.ui_petinfo_basci_icon3_png'"
  local icon3 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petAttri_png.umg_petAttri_png'"
  local icon4 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petAttri_2_png.umg_petAttri_2_png'"
  local icon5 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petskill_3_png.umg_petskill_3_png'"
  local icon6 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petskill_3_png.umg_petskill_3_png'"
  local icon7 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_icon_having_png.ui_petinfo_icon_having_png'"
  local icon8 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_icon_having2_png.ui_petinfo_icon_having2_png'"
  local icon9 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_PetImpression_icon_png.img_PetImpression_icon_png'"
  local icon10 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_PetImpression_icon_png.img_PetImpression_icon_png'"
  local icon11 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_petinfo_medal_png.img_petinfo_medal_png'"
  local icon12 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_petinfo_medal_png.img_petinfo_medal_png'"
  self.bShowSendMark = bShowSendMark
  self.btnMenu1:SetData({
    index = 1,
    icon1 = icon1,
    icon2 = icon2,
    title = LuaText.umg_petleftpanel_1,
    callbackCaller = self,
    callbackFunc = self.OnMenuButtonClick,
    soundId = 40002004
  })
  self.btnMenu2:SetData({
    index = 2,
    icon1 = icon5,
    icon2 = icon6,
    title = LuaText.umg_petleftpanel_2,
    callbackCaller = self,
    callbackFunc = self.OnMenuButtonClick,
    soundId = 40002004
  })
  local activeIconLocation2 = UE4.FVector2D(-58.0, -2)
  local activeIconScale2 = UE4.FVector2D(0.62, 0.62)
  local normalIconLocaiton2 = UE4.FVector2D(-60.0, -6)
  local normalIconScale2 = UE4.FVector2D(0.62, 0.62)
  self.btnMenu2.activeIcon_1.Slot:SetPosition(activeIconLocation2)
  self.btnMenu2.activeIcon_1:SetRenderScale(activeIconScale2)
  self.btnMenu2.normalIcon_1.Slot:SetPosition(normalIconLocaiton2)
  self.btnMenu2.normalIcon_1:SetRenderScale(normalIconScale2)
  self:SetButtonsVisibility(nil ~= petData and true or false)
  local isHidden = nil ~= petData and _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdIsTrailPet, petData.gid) or false
  if isHidden then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.btnMenu6:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if self.ShareIsOpen then
      self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.btnMenu6:SetData({
      index = 6,
      icon1 = icon11,
      icon2 = icon12,
      title = "\229\165\150\231\137\140",
      callbackCaller = self,
      callbackFunc = self.OnMenuButtonClick,
      soundId = 40002004
    })
  end
  self.btnMenu6:SetData({
    index = 6,
    icon1 = icon11,
    icon2 = icon12,
    title = "\229\165\150\231\137\140",
    callbackCaller = self,
    callbackFunc = self.OnMenuButtonClick,
    soundId = 40002004
  })
  self.btnMenu3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.btnMenu4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.btnMenu5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.curMenuButtonIndex = 0
  self:OnAddEventListener()
  self.subPanels = {
    self.petBaseInfo,
    self.PetSkillMain,
    self.PetSkillMain,
    self.Impression,
    self.PetGrowUp,
    self.UMG_MedalPanel
  }
  self.defaultDistrict = {
    [self.PetSkillMain] = HandbookModuleEnum.District.Skill
  }
  self.uiData = {}
  self.uiItem = {}
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    petData = friendInfo.petData
  end
  self.uiData.petData = petData
  self.curSubPanelIndex = 0
  self.IsReverseAnimation = false
  self:setPetInfoMainCtrl(petInfoMain)
  self:ShowSubPanel(1)
  self:updateSubPanelVisible()
  self:InitAndShowRadarInfo()
  self:OnSelectPetChange(self.uiData.petData)
  self:CheckCanSendToFriend()
  self:UpdateTimeRewindBtnVisibility()
  if 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:OnMenuButtonClick(2)
  else
    local openPetData, index, bIsRevertMainPanel, OpenTip, OpenSkillInfo = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
    if index then
      if 2 == index then
        self:OnMenuButtonClick(index)
        if OpenSkillInfo then
          local AllSkillList = {}
          if self.PetSkillMain.ItemList then
            for i = 1, self.PetSkillMain.ItemList:GetItemCount() do
              if self.PetSkillMain.ItemList:GetItemByIndex(i) and self.PetSkillMain.ItemList:GetItemByIndex(i).skillConfig then
                table.insert(AllSkillList, self.PetSkillMain.ItemList:GetItemByIndex(i).skillConfig)
              end
            end
            for index, skillItem in ipairs(AllSkillList) do
              if skillItem.id == OpenSkillInfo.id then
                self.PetSkillMain.ItemList:SelectItemByIndex(index)
                self.PetSkillMain.ItemList:ScrollToStart()
              end
            end
          end
        end
      else
        self:OnMenuButtonClick(index)
      end
    else
      self:OnMenuButtonClick(1)
    end
  end
  self.petBaseInfo:SetCulCanEvo(self.module.data.CulCanEvo, self.module.data.CulCanBreakThrough)
  self.petBaseInfo:RefreshEvoState()
  self.UMG_btnClose:SetStyle(1)
  if not _G.GlobalConfig.DebugOpenUI then
    local PetInfoMain = self.module:GetPanel("PetInfoMain")
    if PetInfoMain and PetInfoMain.IsFirstOpen then
      PetInfoMain.IsFirstOpen = false
      PetInfoMain:HideLeftPanel(false)
    end
  end
  if self.module.IsBagToOpenPanel then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowTipsPanel)
  end
  if self.module:GetPetBagPanelIsChangeState() then
    self.MarkBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.MarkBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if petInfoMain and petInfoMain.bHideSkill and self.petBaseInfo.UMG_PetLeftPanel then
    self.petBaseInfo.UMG_PetLeftPanel:SetSkillShow(false)
  end
  local enterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  if enterType == PetUIModuleEnum.EnterType.PetInheritance then
    self.buttons:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SwitchButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TopBtnPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:CheckShareIsOpen()
  self:PetFriendInterfaceDisplay()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
  self.bOpenNewPetBag = self.module:HasPanel("NewPetBag")
  local isFreeMode = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode)
  local CacheFilter = self.module:GetCachePetBoxFilterData()
  local isScreen = self.module:IsFilteringCondition(CacheFilter.Condition)
  self:OnChangeCloseBtnStyle(isScreen, isFreeMode)
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:CheckCanSendToFriend()
  end
end

function UMG_PetRightPanel_C:OnAttachToParent(petInfoMain, petData)
end

function UMG_PetRightPanel_C:PlayAnimationIn()
  self:DelaySeconds(2.12, function()
    self:PlayAnimation(self.Qiehuan)
  end)
end

function UMG_PetRightPanel_C:PlayAnimationInReverse()
  self.IsReverseAnimation = true
  self:PlayAnimationReverse(self.In)
end

function UMG_PetRightPanel_C:OnDeactive()
  self:CancelDelay()
  self.petBaseInfo:OnDeactive()
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_PetRightPanel_C:OnDestruct()
  table.clear(self.subPanels)
  self.subPanels = nil
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  table.clear(self.uiItem)
  self.uiData = nil
  self.uiItem = nil
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClearModuleDescText)
  self:CancelDelay()
  self:OnRemoveEventListener()
end

function UMG_PetRightPanel_C:OnPlayerDataUpdate(UpdateGoodType)
  if UpdateGoodType and UpdateGoodType == _G.Enum.GoodsType.GT_PET and self.uiData.petData then
    self.uiData.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
    self.module:SetCurrPetData(self.uiData.petData)
    self:OnSelectPetChange(self.uiData.petData, true, true)
  end
end

function UMG_PetRightPanel_C:OnEnable()
end

function UMG_PetRightPanel_C:OnDisable()
end

function UMG_PetRightPanel_C:OnAddEventListener()
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:AddButtonListener(self.SwitchButton, self.ClosePanel)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.backBtn.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.ShareMaskBtn, self.OnShareMaskBtn)
  self:AddButtonListener(self.RecommendedBtn.btnLevelUp, self.OnRecommendedBtnClick)
  self:AddButtonListener(self.MarkBtn, self.CancelPetBagChangeState)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpItemSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.OnEvolutionSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_BTNCLICK, self.OnLeftSubPanelMenuBtnClick)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_RIGHTGROWUP_SUBPANEL_CHANGE, self.OnRightPanelChange)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_POSSESION_SUCCESS, self.OnEquipPossesionSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.UpdateImpressionGroup, self.OnUpdateImpressionGroup)
  self:RegisterEvent(self, PetUIModuleEvent.AUTO_SUPPLY_CARRYON, self.OnAutoSupplyChangeSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.HavingUpgradeAndResonanceEvent, self.HavingUpgradeAndResonanceEvent)
  self:RegisterEvent(self, PetUIModuleEvent.GetOpenPanelPetDataRedPoint, self.RefreshRedPointWithOne)
  self:RegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.OnSelectPetEgg)
  self:RegisterEvent(self, PetUIModuleEvent.PET_GROWUP_SUCCESS, self.OnPetGroUpSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.SwitchToThumbVersion, self.HideAll)
  self:RegisterEvent(self, PetUIModuleEvent.SwitchToDetailVersion, self.ShowAll)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelSetPetInfoMainCtrl, self.setPetInfoMainCtrl)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelSelectPetChange, self.OnSelectPetChange)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelPlayAnimationIn, self.PlayAnimationIn)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelSetVisibility, self.SetVisibility)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelMenuBtnSetVisibility, self.MenuBtnSetVisibility)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelMenuBtnSetAllVisibility, self.MenuBtnSetAllVisibility)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelMenuBtnSetPoint, self.MenuBtnSetPoint)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelShowSubPanel, self.ShowSubPanel)
  self:RegisterEvent(self, PetUIModuleEvent.RightPanelHideSubPanel, self.HideSubPanel)
  self:RegisterEvent(self, PetUIModuleEvent.OpenGrowUpSwitchCloseBtn, self.OpenGrowUpSwitchCloseBtn)
  self:RegisterEvent(self, PetUIModuleEvent.CloseGrowUpSwitchCloseBtn, self.CloseGrowUpSwitchCloseBtn)
  self:RegisterEvent(self, PetUIModuleEvent.HideRightPanel_CloseBtn, self.OnHideCloseBtn)
  self:RegisterEvent(self, PetUIModuleEvent.ResetRightPanelDescText, self.ResetDescText)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
  self:RegisterEvent(self, PetUIModuleEvent.OnNewPetBagEnterScreenState, self.OnChangeCloseBtnStyle)
  self:RegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBag, self.OnOpenNewPetBag)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnShareClick)
  self:AddButtonListener(self.GiftColleaguesBtn.btnLevelUp, self.OnGiftBtnClick)
  self:AddButtonListener(self.TimeRewindBtn.btnLevelUp, self.OnTimeRewindBtnClicked)
  self:RegisterEvent(self, PetUIModuleEvent.OnSendPetFailed, self.OnSendPetFailed)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  _G.NRCEventCenter:RegisterEvent(self.name, self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
end

function UMG_PetRightPanel_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.ShareBtn.btnLevelUp)
  self:RemoveButtonListener(self.TimeRewindBtn.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnNewPetBagReleaseLifeModeChanged, self.OnNewPetBagReleaseLifeModeChanged)
end

function UMG_PetRightPanel_C:ShowSubPanel(_index, _subIndex, _isOpenPetBag)
  if _index > 0 and _index <= #self.subPanels then
    if self.subPanels[_index] == self.PetGrowUp then
      self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.isShopFriendPet then
      self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if self.curSubPanelIndex ~= _index then
      if 3 == _index then
        Log.Error("_index\228\184\141\229\186\148\232\175\165\228\184\1863\239\188\140\232\175\165\233\157\162\230\157\191\229\183\178\229\186\159\229\188\131\239\188\140\228\184\141\229\186\148\232\175\165\229\134\141\232\191\155\229\133\165\239\188\140\232\139\165\229\135\186\231\142\176\230\173\164bug\232\175\183\229\145\138\232\175\137jobhuang")
        if true == _isOpenPetBag then
        else
        end
      end
      self:ChangeSubPanelState(self.curSubPanelIndex, false)
      self.curSubPanelIndex = _index
      self:updateCloseButtonVisible()
      if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CheckIsPetHatchingPanelShow) then
        self:ChangeSubPanelState(self.curSubPanelIndex, false)
      else
        local isAttributeOpen = UE4.UObject.IsValid(self.petInfoMainCtrl) and self.petInfoMainCtrl:GetAttributeOpenState()
        if false == isAttributeOpen then
          self:PlayAnimation(self.Qiehuan)
        end
        self:ChangeSubPanelState(self.curSubPanelIndex, true)
      end
      if 5 == self.curSubPanelIndex then
        self.PetGrowUp.ScrollBox:ScrollToStart()
        self:DispatchEvent(PetUIModuleEvent.PET_UI_RIGHTGROWUP_SUBPANEL_CHANGE, true)
      end
      if 2 == self.curMenuButtonIndex then
        self.PetSkillMain.ItemList:ScrollToStart()
      end
      self:DispatchEvent(PetUIModuleEvent.PET_UI_RIGHT_SUBPANEL_CHANGE, self.curSubPanelIndex or 0)
    end
  end
end

function UMG_PetRightPanel_C:HideAll()
  self:IsHiddenPane(true)
  self:SetPetModelLocationInfo(true)
  if 4 == self.curSubPanelIndex then
    self.Impression:OnPlayMinOutPanel()
  end
end

function UMG_PetRightPanel_C:ShowAll()
  self:IsHiddenPane(false)
  self:PlayAnimation(self.Qiehuan)
  self.petBaseInfo:PlayIn()
  self:SetPetModelLocationInfo(false)
  if 1 == self.curSubPanelIndex then
    self.petBaseInfo.PetRadarInfo:PlayAnimation(self.petBaseInfo.PetRadarInfo.In)
    self.petBaseInfo.PetRadarInfo:OnShowPetRadar()
  elseif 4 == self.curSubPanelIndex then
    self.Impression:OnPlayMinInPanel()
  end
end

function UMG_PetRightPanel_C:ShowDescRightPanel(id)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowDescRightPanel, id)
end

function UMG_PetRightPanel_C:OnDescTextClicked(id)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetSkillTipDescText)
  local descText = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetDescText)
  if descText[1] then
    for i = 1, #descText do
      if descText[i] == id then
        return
      else
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetDescText, id)
      end
    end
  else
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetDescText, id)
  end
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ShowBtnClosePanel)
  local descNote = _G.DataConfigManager:GetDescNoteConf(tonumber(id))
  if descNote then
    local descText = string.format("\227\128\144%s\227\128\145\n%s", descNote.note, descNote.desc)
  end
end

function UMG_PetRightPanel_C:ResetDescText()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClearDescText)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.HideBtnClosePanel)
end

function UMG_PetRightPanel_C:InitAndShowRadarInfo()
  self:IsHiddenPane(false)
  self:DispatchEvent(PetUIModuleEvent.PlayAttributeOutAnim)
  self:DelaySeconds(0.1, function()
    self:PlayAnimation(self.Qiehuan)
  end)
  self:SetPetModelLocationInfo(false)
  if 1 == self.curSubPanelIndex then
    self.petBaseInfo.PetRadarInfo.InitShowRadarFlag = true
  elseif 4 == self.curSubPanelIndex then
    self.Impression:OnPlayMinInPanel()
  end
end

function UMG_PetRightPanel_C:IsHiddenPane(_IsHiddenPanel)
  if true == _IsHiddenPanel then
    self:PlayAnimation(self.Qiehuan_Out)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetRightPanel_C:HideSubPanel()
  if self.curSubPanelIndex > 0 then
    self:ChangeSubPanelState(self.curSubPanelIndex, false)
    self.curSubPanelIndex = 0
    self:updateCloseButtonVisible()
    self:DispatchEvent(PetUIModuleEvent.PET_UI_RIGHT_SUBPANEL_CHANGE, self.curSubPanelIndex)
  end
end

function UMG_PetRightPanel_C:updateCloseButtonVisible()
end

function UMG_PetRightPanel_C:updateSubPanelVisible()
  for panelIndex, subPanel in pairs(self.subPanels) do
    if subPanel then
      if panelIndex == self.curSubPanelIndex then
        subPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        subPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetRightPanel_C:ChangeSubPanelState(_index, _isShow)
  if _index then
    local subPanel = self.subPanels[_index]
    if subPanel then
      if subPanel.OnPanelStateChange then
        tcall(subPanel, subPanel.OnPanelStateChange, _isShow)
      end
      if _isShow then
        subPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        subPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetRightPanel_C:setPetInfoMainCtrl(_petInfoMainCtrl)
  self.petInfoMainCtrl = _petInfoMainCtrl
  self.petLeftPanel = UE4.UObject.IsValid(_petInfoMainCtrl) and _petInfoMainCtrl.petLeftPanel
  self.petBaseInfo:setPetInfoMainCtrl(_petInfoMainCtrl)
end

function UMG_PetRightPanel_C:OnPetGroUpSuccess(_changes)
  local changes = _changes
  self:checkCurPetInfoChange(changes)
  if 5 == self.curSubPanelIndex then
    self.PetGrowUp:OnPanelStateChange(true, true)
  end
end

function UMG_PetRightPanel_C:OnEquippedSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetRightPanel_C:OnUseExpItemSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetRightPanel_C:OnEvolutionSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetRightPanel_C:OnEquipPossesionSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetRightPanel_C:OnUpdateImpressionGroup(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetRightPanel_C:HavingUpgradeAndResonanceEvent(_changes, _res_carryon)
  self:checkCurPetInfoChange(_changes)
  if _res_carryon then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(PetUIModuleEvent.HavingUpgradeAndResonanceUpdateEvent, _res_carryon)
  end
end

function UMG_PetRightPanel_C:RefreshRedPointWithOne(CanEvo, CanBreakThrough)
  self.petBaseInfo:SetCulCanEvo(CanEvo, CanBreakThrough)
  self.petBaseInfo:RefreshEvoState()
end

function UMG_PetRightPanel_C:OnAutoSupplyChangeSuccess(_changes)
end

function UMG_PetRightPanel_C:checkCurPetInfoChange(_changes)
  local curPetData = self.uiData.petData
  if not curPetData or not _changes then
    return
  end
  local petData
  for i, changItem in ipairs(_changes) do
    if changItem.type == _G.ProtoEnum.GoodsType.GT_PET then
      petData = changItem.pet_data
      self:ChangesInfo(curPetData, petData)
    elseif changItem.type == ProtoEnum.GoodsType.GT_PETEXP then
      petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(changItem.gid)
      self:ChangesInfo(curPetData, petData)
    end
  end
end

function UMG_PetRightPanel_C:ChangesInfo(curPetData, petData)
  if curPetData.gid == petData.gid then
    self.module:SetCurrPetData(petData)
    self:OnSelectPetChange(petData, true, true)
  end
end

function UMG_PetRightPanel_C:OnSelectPetChange(_petData, isCheck, bOnlyPetDataRefresh)
  if not _petData then
    self:OnSelectEmpty()
  else
    self:OnSelectPet(_petData, isCheck, bOnlyPetDataRefresh)
  end
end

function UMG_PetRightPanel_C:OnSelectPet(_petData, isCheck, bOnlyPetDataRefresh)
  self.uiData.petData = _petData
  if _petData then
    self.uiData.petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
  else
    self.uiData.petBaseConf = nil
  end
  self:SetShowPanel()
  self:SetButtonsVisibility(true)
  self:SetTopBtnPanelVisibility(true)
  self:UpdateTimeRewindBtnVisibility()
  if not bOnlyPetDataRefresh then
    self:OnErasePetSkillRedPoint()
  end
  self.petBaseInfo:OnSelectPetChange(self.uiData.petData)
  local petBaseConf = self.uiData.petBaseConf
  self.PetGrowUp:updatePetInfo(self.uiData, petBaseConf)
  self.UMG_MedalPanel:updatePetInfo(self.uiData.petData)
  self.PetSkillMain:updatePetInfo(self.uiData.petData, self.uiData.petBaseConf)
  local Attribute = UE4.UObject.IsValid(self.petLeftPanel) and self.petLeftPanel.Attribute
  if Attribute and 3 == self.curSubPanelIndex and not Attribute.showing then
    self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
  end
  self.Impression:UpdatePetInfo(self.uiData.petData, self.petInfoMainCtrl)
  if not isCheck then
    self:ShowPetEggPanel(false)
  end
  if self.uiData.petData then
    self:SetXiXingBtn(self.uiData.petData.base_conf_id)
  end
  self:SetSkillRedPointState()
  self:SetImpressionPointState()
  self:SetPetEvoPointState()
  self:CheckCanSendToFriend()
end

function UMG_PetRightPanel_C:OnSelectEmpty()
  self.uiData.petData = nil
  self:SetButtonsVisibility(false)
  self:SetTopBtnPanelVisibility(false)
  self.petBaseInfo:OnSelectPetChange(nil)
  self.PetGrowUp:updatePetInfo(nil)
  self.UMG_MedalPanel:updatePetInfo(nil)
  self.PetSkillMain:updatePetInfo(nil)
  self:ChangeSubPanelState(self.curSubPanelIndex, true)
  self.IsShowShareBox = false
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:SetShowPanel()
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
  if nil ~= select_pet_conf_id then
    local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
    if not hideMagicManua then
      local ResidueGrowCount, GrowOrder = PetUtils.GetResidueGrowCountAndGrowOrder(self.uiData.petData)
      local BreakNumberAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.BREAK_NUMBER_CONF):GetAllDatas()
      local InspireLevelAllConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.INSPIRE_LEVEL_CONF):GetAllDatas()
      if (GrowOrder and GrowOrder - 1 >= #BreakNumberAllConf and nil == self.uiData.petData.inspire_lv or nil ~= self.uiData.petData.inspire_lv and self.uiData.petData.inspire_lv >= #InspireLevelAllConf) and 4 == self.PetGrowUp.Visibility then
        self.PetGrowUp:DispatchEvent(PetUIModuleEvent.RightPanelHideSubPanel)
        self.PetGrowUp:DispatchEvent(PetUIModuleEvent.RightPanelShowSubPanel, 1)
      end
    end
  end
end

function UMG_PetRightPanel_C:OnSelectPetEgg(index, eggInfo)
  self:ShowPetEggPanel(true)
  self.Pet_HatchingAttribute:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Pet_HatchingAttribute:UpdateEggInfo(eggInfo)
end

function UMG_PetRightPanel_C:ShowPetEggPanel(isShow)
  if isShow then
    for i = 1, #self.subPanels do
      local subPanel = self.subPanels[i]
      subPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Pet_HatchingAttribute:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Pet_HatchingAttribute:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:ChangeSubPanelState(self.curSubPanelIndex, true)
  end
end

function UMG_PetRightPanel_C:SetPetModelLocationInfo(IsShow)
  if 3 == self.curSubPanelIndex then
    if IsShow then
      self:DispatchEvent(PetUIModuleEvent.DestroyHavingModelInfoEvent)
      self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, nil)
    else
      self:ChangeSubPanelState(self.curSubPanelIndex, true)
      self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
    end
  end
end

function UMG_PetRightPanel_C:OnRightPanelChange(_index)
  if false == _index then
    self.curSubPanelIndex = 1
    self.petBaseInfo:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.petBaseInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetSkillMain:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Impression:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pet_HatchingAttribute:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetRightPanel_C:SetButtonsVisibility(bVisible)
  if bVisible then
    self.buttons:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.buttons:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetRightPanel_C:SetTopBtnPanelVisibility(Visible)
  self.TopBtnPanel:SetVisibility(Visible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:OnBtnCloSkillseSubPanelClick()
end

function UMG_PetRightPanel_C:OnLeftSubPanelMenuBtnClick(_index, _isOpenPetBag)
  self:DispatchEvent(PetUIModuleEvent.DestroyHavingModelInfoEvent)
  if 2 ~= _index then
    self:DispatchEvent(PetUIModuleEvent.ExitSkillEquipMode)
  elseif self.module:GetData("PetUIModuleData"):GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PvpPetTeamUmg then
    self:DispatchEvent(PetUIModuleEvent.ExitSkillEquipMode)
  end
  if 1 == _index then
    self:ShowSubPanel(1)
  elseif 2 == _index then
    self:ShowSubPanel(2)
  elseif 3 == _index then
    self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
    self:ShowSubPanel(3, nil, _isOpenPetBag)
  elseif 4 == _index then
    self:ShowSubPanel(4)
  elseif 6 == _index then
    self:ShowSubPanel(6)
  end
end

function UMG_PetRightPanel_C:OnAnimFinished(Animation)
  if Animation == self.Qiehuan and self.IsReverseAnimation == true then
    if UE4.UObject.IsValid(self.petInfoMainCtrl) then
      self.petInfoMainCtrl:ClosePanelInfo()
    end
    self.IsReverseAnimation = false
  elseif Animation == self.OpenXqAni then
    Log.Debug(Animation:GetName(), "UMG_PetRightPanel_C:OnAnimationFinished")
  elseif Animation == self.Qiehuan_Out then
  elseif Animation == self.Qiehuan then
    self.module:SetPetMainBtnIsEnabled(true)
    self:DispatchEvent(PetUIModuleEvent.SwitchPetInfoMainRecommendedBtn, false)
  end
end

function UMG_PetRightPanel_C:OnCloseBtnClick()
  self:PlayAnimation(self.Qiehuan_Out)
end

function UMG_PetRightPanel_C:OnMenuButtonClick(_index)
  if nil == _index or _index > 0 and _index == self.curMenuButtonIndex then
    return
  end
  local petLeftPanel = UE4.UObject.IsValid(self.petLeftPanel) and self.petLeftPanel
  self:OnErasePetSkillRedPoint()
  self:ChangeCurButtonState(false)
  if petLeftPanel then
    petLeftPanel:ChangeCurButtonState(false)
  end
  if self.uiData then
    self:SetPetNewSkillInfo(self.uiData.petData, self.curMenuButtonIndex)
  end
  self.curMenuButtonIndex = _index
  if petLeftPanel then
    petLeftPanel.curMenuButtonIndex = _index
  end
  self:ChangeCurButtonState(true)
  self:DispatchEvent(PetUIModuleEvent.OnShowPetRadar, self.uiData.petData)
  local bagPanelOpen = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBagOpenState)
  self:DispatchEvent(PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_BTNCLICK, _index, bagPanelOpen)
  if petLeftPanel then
    petLeftPanel:setActive(self.changeTeambuttons, 1 == self.curMenuButtonIndex)
  end
end

function UMG_PetRightPanel_C:SetPetNewSkillInfo(_PetData)
  local PetData = _PetData
  if 3 == self.curMenuButtonIndex then
    PetUtils.UpdatePetNewSkill(PetData)
  end
end

function UMG_PetRightPanel_C:ChangeCurButtonState(_select)
  if self.curMenuButtonIndex ~= nil then
    local curMenuBtton = self.menuButtons[self.curMenuButtonIndex]
    if curMenuBtton then
      curMenuBtton:SetSelectState(_select)
      if _select then
        self.IsShowShareBox = false
        self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetUiMenuIndex, tonumber(self.curMenuButtonIndex))
      end
    end
  end
end

function UMG_PetRightPanel_C:ClosePanel()
  if 1 == self.PetSkillMain.uiData.mode then
    self.PetSkillMain:OnExitSkillEquipMode()
  end
  if UE4.UObject.IsValid(self.petLeftPanel) then
    self.petLeftPanel.Attribute:SwitchVersion()
  else
    Log.Error("\229\133\179\233\151\173\233\157\162\230\157\191\230\151\182\239\188\140self.petInfoMainCtrl\228\184\186\231\169\186\239\188\140\229\188\130\229\184\184\239\188\140\232\175\183\232\129\148\231\179\187jobhuang")
  end
  self:OnErasePetSkillRedPoint()
end

function UMG_PetRightPanel_C:CloseSwitchButton(_IsDisabled)
  if _IsDisabled then
    self.SwitchButton:SetIsEnabled(false)
  else
    self.SwitchButton:SetIsEnabled(true)
  end
end

function UMG_PetRightPanel_C:OnOpenNewPetBag(bOpen)
  self.bOpenNewPetBag = bOpen
  self:OnChangeCloseBtnStyle()
end

function UMG_PetRightPanel_C:OnChangeCloseBtnStyle(isEnterScreen, isEnterFree)
  if nil ~= isEnterFree then
    self.isEnterFree = isEnterFree
  end
  if self.isEnterScreen or self.isEnterFree or self.bOpenNewPetBag then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_PetRightPanel_C:MenuBtnSetVisibility(index, visibility)
  self.menuButtons[index]:SetVisibility(visibility)
end

function UMG_PetRightPanel_C:MenuBtnSetAllVisibility(visibility)
  for i, menuBtn in pairs(self.menuButtons) do
    menuBtn.NrcRedPoint:SetVisibility(visibility)
  end
end

function UMG_PetRightPanel_C:MenuBtnSetPoint(index, gid)
  self.menuButtons[index]:SetPoint(gid)
end

function UMG_PetRightPanel_C:SetSkillRedPointState()
  if self.uiData then
    local gid = self.uiData.petData.gid
    self.btnMenu2:SetPoint(gid)
  end
end

function UMG_PetRightPanel_C:SetImpressionPointState()
  if self.uiData then
    local gid = self.uiData.petData.gid
    self.btnMenu4:SetImpressionPoint(gid)
  end
end

function UMG_PetRightPanel_C:SetPetEvoPointState()
  if self.uiData then
    local gid = self.uiData.petData.gid
    self.btnMenu1:SetPetEvoPoint(gid)
    self.btnMenu1:SetBagEvoPoint(gid)
  end
end

function UMG_PetRightPanel_C:CancelPetBagChangeState()
  self.MarkBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:DispatchEvent(PetUIModuleEvent.PetBagCancelAddToBattleTeam)
end

function UMG_PetRightPanel_C:OnEmptyClose()
  self:OnErasePetSkillRedPoint()
  self:DoClose()
end

function UMG_PetRightPanel_C:OnCloseButtonClicked()
  if self.module:GetData("PetUIModuleData"):GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PvpPetTeamUmg then
    self:DispatchEvent(PetUIModuleEvent.PetEquipSkillFinished)
  end
  if self.bOpenNewPetBag and UE4.UObject.IsValid(self.petLeftPanel) then
    self.petLeftPanel.Attribute:SwitchVersion()
    return
  end
  if self.isEnterFree then
    self:DispatchEvent(PetUIModuleEvent.OnNewPetBagExitFree)
    return
  elseif self.isEnterScreen then
    self:DispatchEvent(PetUIModuleEvent.OnNewPetBagExitScreen)
    return
  end
  if UE4.UObject.IsValid(self.petInfoMainCtrl) then
    local emptyClose = self.petInfoMainCtrl:OnCloseButtonClicked()
    if emptyClose then
      return
    end
  end
  self:OnErasePetSkillRedPoint()
  self:DoClose()
end

function UMG_PetRightPanel_C:OnRecommendedBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_PetRightPanel_C:OnRecommendedBtnClick")
  local selectIconType
  local curSubPanel = self.curSubPanelIndex or 0
  if curSubPanel > 0 and curSubPanel <= #self.subPanels then
    local subPanel = self.subPanels[curSubPanel]
    if subPanel then
      selectIconType = self.defaultDistrict[subPanel]
    end
  end
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDistrictMapGuide, self.uiData.petData, selectIconType)
  self:ResetDescText()
end

function UMG_PetRightPanel_C:SetXiXingBtn(base_conf_id)
  if nil == base_conf_id then
    return
  end
  local PetConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
  if 0 == PetConf.belong_habit_group then
    self.btnMenu4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 4 == self.curMenuButtonIndex then
      self:OnMenuButtonClick(1)
    end
  elseif 5 == self.curMenuButtonIndex then
    self:OnMenuButtonClick(1)
  else
    self.btnMenu4:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetRightPanel_C:OpenGrowUpSwitchCloseBtn()
  self.bOpenGrowUp = true
  self.SwitchButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ShowOrHideCloseBtn(false)
  self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:CloseGrowUpSwitchCloseBtn()
  self.bOpenGrowUp = false
  self.SwitchButton:SetVisibility(UE4.ESlateVisibility.Visible)
  self:ShowOrHideCloseBtn(true)
  self:CheckCanSendToFriend()
end

function UMG_PetRightPanel_C:OnHideCloseBtn(bHide)
  self:ShowOrHideCloseBtn(not bHide)
end

function UMG_PetRightPanel_C:ShowOrHideCloseBtn(bShow)
  local bOpenEvoPanel = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsOpenEvoPanel)
  if bShow and not bOpenEvoPanel then
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetRightPanel_C:OnErasePetSkillRedPoint()
  if 2 == self.curSubPanelIndex then
    self:DispatchEvent(PetUIModuleEvent.ErasePetSkillRedPoint)
  end
end

function UMG_PetRightPanel_C:OnPcClose()
  if self.PetGrowUp:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.PetGrowUp:OnCloseBtnClick()
  elseif self.PetSkillMain:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible and self.PetSkillMain.backBtn:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.PetSkillMain:OnBackBtnClick()
  else
    self:OnCloseButtonClicked()
  end
end

function UMG_PetRightPanel_C:OnTimeRewindBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetRightPanel_C:OnTimeRewindBtnClicked")
  if self.uiData and self.uiData.petData and self.uiData.petData.gid then
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.OpenPetTraceBackPopup, self.uiData.petData.gid)
  end
end

function UMG_PetRightPanel_C:SetFullScreenMaskShow(bShow)
  if self.FullScreenMask == nil then
    return
  end
  if self.FullScreenCollapsedDelayId then
    _G.DelayManager:CancelDelay(self.FullScreenCollapsedDelayId)
    self.FullScreenCollapsedDelayId = nil
  end
  if bShow then
    self.FullScreenMask:SetVisibility(UE4.ESlateVisibility.Visible)
    self.FullScreenCollapsedDelayId = _G.DelayManager:DelaySeconds(FULL_SCREEN_SHOW_TIME, function()
      self:SetFullScreenMaskShow(false)
    end)
  else
    self.FullScreenMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetRightPanel_C:OnShareClick()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_SHARE, true)
  if isBan then
    return
  end
  if not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetCanSharePet) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetRightPanel_C:OnShareClick")
  self:ResetDescText()
  if self.IsShowShareBox then
    self.IsShowShareBox = false
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.IsShowShareBox = true
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Visible)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetCanListenShareType)
    self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetRightPanel_C:ResetShareComboBox()
  self.IsShowShareBox = false
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:OnShareMaskBtn()
  if self.IsShowShareBox then
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsShowShareBox = false
  end
  self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:PetFriendInterfaceDisplay()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  self.isShopFriendPet = false
  if openPetData and friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    self.RecommendedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareMaskBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ShareIsOpen = false
    self.isShopFriendPet = true
  end
end

function UMG_PetRightPanel_C:CheckCanSendToFriend()
  self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local canShow = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetCanShowSendBtn)
  local bOpenEvoPanel = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsOpenEvoPanel)
  if self.bShowSendMark and not self.bOpenGrowUp and canShow and not bOpenEvoPanel and self.uiData and self.uiData.petData and self.uiData.petData.together_catch_info and self.uiData.petData.together_catch_info.is_onwer_catch then
    local timeStamp = self.uiData.petData.together_catch_info.transfer_deadline
    if timeStamp then
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      if currentTime and timeStamp > currentTime then
        local text = LuaText.peer_pet_give_btn_text
        self.GiftColleaguesBtn:SetText(text)
        self.GiftColleaguesBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      end
    end
  end
end

function UMG_PetRightPanel_C:OnGiftBtnClick()
  if self.uiData and self.uiData.petData and self.uiData.petData.gid then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SendPetToFriend, self.uiData.petData.gid, true)
  end
end

function UMG_PetRightPanel_C:OnSendPetFailed()
  self:CheckCanSendToFriend()
end

function UMG_PetRightPanel_C:UpdateTimeRewindBtnVisibility()
  if self.uiData == nil then
    Log.Error("UMG_PetRightPanel_C:UpdateTimeRewindBtnVisibility uiData is nil")
    return
  end
  if nil == self.uiData.petData then
    Log.Error("UMG_PetRightPanel_C:UpdateTimeRewindBtnVisibility petData is nil")
    return
  end
  local bCanShow = true
  local EnterType = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetEnterPetPanelType)
  if EnterType == PetUIModuleEnum.EnterType.PetInheritance or EnterType == PetUIModuleEnum.EnterType.PetAltar then
    bCanShow = false
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    bCanShow = false
  end
  local bCanTraceBack = PetUtils.CheckPetIsCanTraceBack(self.uiData.petData, true, true, true)
  self.TimeRewindBtn:SetVisibility(bCanTraceBack and bCanShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:OnNewPetBagReleaseLifeModeChanged()
  if _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetPortableBagReleaseLifeMode) and 5 == self.curSubPanelIndex then
    self:ShowSubPanel(1)
  else
  end
end

function UMG_PetRightPanel_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = true
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PetRightPanel_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PetRightPanel_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_PET
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  self:ShowShareBtn()
end

function UMG_PetRightPanel_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SetPanelCanScroll, true)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_PetRightPanel_C:InitComboBox()
  self.IsShowShareBox = false
  local selectList = {}
  local shareBaseConf = _G.DataConfigManager:GetShareBaseConf(_G.Enum.ShareButtonType.SBT_PET)
  if shareBaseConf and shareBaseConf.base_id and #shareBaseConf.base_id > 1 then
    for index, v in ipairs(shareBaseConf.base_id) do
      local channelBanId = shareBaseConf.system_control_limit[index + 1]
      local isBan = false
      if channelBanId and not _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckShareChannelIsOpen, channelBanId) then
        isBan = true
      end
      if not isBan then
        local sharePartConf = _G.DataConfigManager:GetSharePartConf(v)
        if sharePartConf then
          local selectData = {
            name = sharePartConf.tab_name,
            isHideRedDot = true,
            isNotChangColor = true,
            ComType = CommonBtnEnum.ComboBoxType.PetShare,
            SharePartId = v
          }
          table.insert(selectList, selectData)
        end
      end
    end
  end
  if RocoEnv.IS_EDITOR or RocoEnv.PLATFORM_WINDOWS or RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS or RocoEnv.PLATFORM_OPENHARMONY then
    self.ComboBox_Popup.List_title:InitList(selectList)
  end
  self.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetRightPanel_C:ShowShareBtn()
  if self.ShareIsOpen then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetRightPanel_C
