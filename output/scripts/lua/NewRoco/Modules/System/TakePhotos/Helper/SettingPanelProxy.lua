local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")
local Delegate = require("Utils.Delegate")
local WidgetLoaderPanelAdapter = require("NewRoco.Modules.System.TakePhotos.Helper.WidgetLoaderPanelAdapter")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PlayerLookLensProxy = require("NewRoco.Modules.System.TakePhotos.Helper.PlayerLookLensProxy")
local PetLookLensProxy = require("NewRoco.Modules.System.TakePhotos.Helper.PetLookLensProxy")
local CameraRollControlProxy = require("NewRoco.Modules.System.TakePhotos.Helper.CameraRollControlProxy")
local PostProcessFilter = require("NewRoco.Modules.System.TakePhotos.Helper.PostProcessFilter")
local ActionPosePlayer = require("NewRoco.Modules.System.TakePhotos.Helper.ActionPosePlayer")
local EmojiPlayer = require("NewRoco.Modules.System.TakePhotos.Helper.EmojiPlayer")
local SettingPanelProxy = Class("SettingPanelProxy")

function SettingPanelProxy:Ctor(MainPanel)
  self.MainPanel = MainPanel
  self.Adapter = WidgetLoaderPanelAdapter(MainPanel, MainPanel.LoaderSettings)
  self.Adapter.OnPanelOpened:Add(self, self.OnPanelOpened)
  self.Adapter.OnPanelClosed:Add(self, self.OnPanelClosed)
  MainPanel:AddButtonListener(MainPanel.Btn_Set.btnLevelUp, function()
    self:OnReqOpen()
  end)
  MainPanel.OnDestroyMultiDelegate:Add(self, self.OnDestroy)
  MainPanel.OnModeChangedDelegate:Add(self, self.OnModeChanged)
  MainPanel.OnModeChangedDelegate:Add(self, self.OnToggleMode)
  self.Settings = MainPanel:GetPhotoController().TakePhotoSettings
  self.Settings.FilterGroup.OnOptionChanged:Add(self, self.OnFilterOptionChanged)
  self.PetLookLensProxy = PetLookLensProxy(MainPanel)
  self.PlayerLookLensProxy = PlayerLookLensProxy(MainPanel)
  self.CameraRollControlProxy = CameraRollControlProxy(MainPanel)
  self.PostProcessFilter = PostProcessFilter()
  self.bMainUIControlEnabled = false
  self.ShowHideMainSlots = {
    "Jump",
    "Crouch",
    "Main"
  }
  self.Settings.FocalScaleProgress.OnValueChanged:Add(self, self.OnFocalScaleChanged)
  self.Settings.FocalRegionProgress.OnValueChanged:Add(self, self.OnFocalRegionChanged)
  self:OnFocalScaleChanged(self.Settings.FocalScaleProgress:GetValue())
  self:OnFocalRegionChanged(self.Settings.FocalRegionProgress:GetValue())
  self.Settings.ActionGroup.OnOptionChanged:Add(self, self.OnPoseOptionChanged)
  self.Settings.EmojiGroup.OnOptionChanged:Add(self, self.OnEmojiOptionChanged)
  self.Settings.FashionGroup.OnOptionChanged:Add(self, self.OnFashionOptionChanged)
  self.Settings.ActionMirror.OnValueChanged:Add(self, self.OnToggleActionMirror)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.viewObj.SettingLeftHand = self.Settings.ActionMirror:IsEnabled()
end

function SettingPanelProxy:SetShowHideMainUIControlEnabled(bEnabled)
  if bEnabled ~= self.bMainUIControlEnabled then
    self.bMainUIControlEnabled = bEnabled
    for i, Type in ipairs(self.ShowHideMainSlots) do
      NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ReqShowHideAbilitySlotByReason, Type, not bEnabled, "TakePhotoSetting")
    end
  end
end

function SettingPanelProxy:OnDestroy()
  self.bDestroyed = true
  self:SetShowHideMainUIControlEnabled(false)
  if self.Adapter:IsOpened() then
    UE4Helper.ReleaseDesiredShowCursor("UMG_TakePhotos_Settings_C")
  end
  self.Adapter:Reset()
  self:CleanFilter()
  self:ResetFocalRegion()
  self:CleanAction()
  self:CleanEmoji()
  if self.DelayActionMirror then
    self.MainPanel:CancelDelayByID(self.DelayActionMirror)
    self.DelayActionMirror = nil
  end
end

function SettingPanelProxy:OnReqOpen()
  if self.Adapter:IsOpened() then
    return
  end
  if not self.MainPanel.Btn_Set:IsVisible() then
    return
  end
  if self.MainPanel:IsTakingPhotos() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "SettingPanelProxy")
  self.Adapter:Open()
end

function SettingPanelProxy:OnPanelOpened()
  self.MainPanel._BtnTakePhotoVisibilityMutex:SetVisible(false, "SettingOpen")
  self.MainPanel._TripodControlPad:SetVisible(false, "SettingOpen")
  self.MainPanel._BurstNumCanvasVisibilityMutex:SetVisible(false, "SettingOpen")
  self.MainPanel._TaskPanelVisibilityMutex:SetVisible(false, "SettingOpen")
  self.MainPanel._RightUpBtnGroupVisibilityMutex:SetVisible(false, "SettingOpen")
  self.MainPanel._TripodModeBtnGroupCanvasVisibilityMutex:SetVisible(false, "SettingOpen")
  UE4Helper.SetDesiredShowCursor(true, "UMG_TakePhotos_Settings_C")
  self:SetShowHideMainUIControlEnabled(true)
  self:ConditionInitTabList()
  self:RefreshFilterProgressView()
end

function SettingPanelProxy:OnPanelClosed()
  self.MainPanel._BtnTakePhotoVisibilityMutex:SetVisible(true, "SettingOpen")
  self.MainPanel._TripodControlPad:SetVisible(true, "SettingOpen")
  self.MainPanel._BurstNumCanvasVisibilityMutex:SetVisible(true, "SettingOpen")
  self.MainPanel._TaskPanelVisibilityMutex:SetVisible(true, "SettingOpen")
  self.MainPanel._RightUpBtnGroupVisibilityMutex:SetVisible(true, "SettingOpen")
  self.MainPanel._TripodModeBtnGroupCanvasVisibilityMutex:SetVisible(true, "SettingOpen")
  UE4Helper.ReleaseDesiredShowCursor("UMG_TakePhotos_Settings_C")
  self:SetShowHideMainUIControlEnabled(false)
  _G.NRCAudioManager:PlaySound2DAuto(40007009, "OnPanelClosed")
  if self.bSkinListViewDirty then
    self.Settings:RemoveCameraSkinRedDots()
    self.bSkinListViewDirty = false
  end
end

function SettingPanelProxy:ConditionInitTabList()
  if not self.bTabListInitialized then
    self.bTabListInitialized = true
    self.TabList = {
      {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangjishezhi1_png.img_xiangjishezhi1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangjishezhi2_png.img_xiangjishezhi2_png'",
        OnClicked = function()
          self:ToggleTab(1)
        end
      },
      {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_lvjing1_png.img_lvjing1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_lvjing2_png.img_lvjing2_png'",
        OnClicked = function()
          self:ToggleTab(2)
        end,
        OnRefresh = function()
          return self:OnRefreshFilterViewList()
        end
      }
    }
    self.FashionTabIdx = 0
    self.ActionTabIdx = 0
    if self.MainPanel.CurrMode.Mgr:IsSelfieMode() then
      self.TabList[3] = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_dongzuo1_png.img_dongzuo1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_dongzuo2_png.img_dongzuo2_png'",
        OnClicked = function()
          self:ToggleTab(3)
        end,
        OnRefresh = function()
          return self:OnRefreshActionListView()
        end
      }
      self.TabList[4] = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_biaoqing1_png.img_biaoqing1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_biaoqing2_png.img_biaoqing2_png'",
        OnClicked = function()
          self:ToggleTab(4)
        end,
        OnRefresh = function()
          return self:OnRefreshEmojiListView()
        end
      }
      self.TabList[5] = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shangyi1_png.img_shangyi1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shangyi2_png.img_shangyi2_png'",
        OnClicked = function()
          self:ToggleTab(5)
        end,
        OnRefresh = function()
          return self:OnRefreshFashionListView()
        end
      }
      self.FashionTabIdx = 5
      self.ActionTabIdx = 3
    elseif self.MainPanel.CurrMode.Mgr:IsTripodAvailableMode() then
      self.TabList[3] = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_biaoqing1_png.img_biaoqing1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_biaoqing2_png.img_biaoqing2_png'",
        OnClicked = function()
          self:ToggleTab(4, 3)
        end,
        OnRefresh = function()
          return self:OnRefreshEmojiListView()
        end
      }
      self.TabList[4] = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shangyi1_png.img_shangyi1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shangyi2_png.img_shangyi2_png'",
        OnClicked = function()
          self:ToggleTab(5, 4)
        end,
        OnRefresh = function()
          return self:OnRefreshFashionListView()
        end
      }
      self.FashionTabIdx = 4
    end
    if 0 ~= self.FashionTabIdx then
      local TabData = self.TabList[self.FashionTabIdx]
      if TabData then
        local bUnlocked = NRCModuleManager:DoCmd(FunctionBanModuleCmd.IsFunctionEntranceUnLocked, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
        local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
        if not bUnlocked and isBan then
          TabData.NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_shangyi3_png.img_shangyi3_png'"
        end
      end
    end
    if 0 ~= self.ActionTabIdx then
      local TabData = self.TabList[self.ActionTabIdx]
      if TabData and self:InRideAllStatus() then
        TabData.NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_dongzuo3_png.img_dongzuo3_png'"
      end
    end
    local CameraInfo = self.MainPanel.player.serverData.camera_info
    local CameraSkins = CameraInfo and CameraInfo.unlock_skin_ids
    local bHasCameraSkins = CameraSkins and #CameraSkins > 1
    if bHasCameraSkins then
      local DesiredIndex = #self.TabList + 1
      local CameraSkinTabInfo = {
        NormalIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangjiweiguang1_png.img_xiangjiweiguang1_png'",
        BlackIconPath = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangjiweiguang2_png.img_xiangjiweiguang2_png'",
        OnClicked = function()
          self:ToggleTab(6, DesiredIndex)
        end,
        OnRefresh = function()
          return self:OnRefreshCameraSkinList()
        end,
        RedDotKey = 495
      }
      table.insert(self.TabList, CameraSkinTabInfo)
    end
    self:OnInitFilterViewList()
    self:OnInitActionList()
    self:OnInitEmojiList()
    self:OnInitFashionList()
    self:OnInitCameraSkinList()
  end
  self.bDisableToggleTabAudio = true
  local Panel = self.Adapter:GetPanel()
  local GridView = Panel.TabList
  GridView:InitGridView(self.TabList)
  GridView:SelectItemByIndex(0)
  GridView:SetItemCanClickChecker(self.JudeItemCanClick, self)
  self.bDisableToggleTabAudio = false
end

function SettingPanelProxy:InRideAllStatus()
  local LocalPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local bRideAll = LocalPlayer and LocalPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  return bRideAll
end

function SettingPanelProxy:JudeItemCanClick(Item, Index, UserClick)
  if Index + 1 == self.FashionTabIdx then
    local bUnlocked = NRCModuleManager:DoCmd(FunctionBanModuleCmd.IsFunctionEntranceUnLocked, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
    if not bUnlocked then
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP, true)
      if isBan then
        return false
      end
    end
  elseif Index + 1 == self.ActionTabIdx and self:InRideAllStatus() then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.take_photo_allride_pose)
    return false
  end
  return true
end

function SettingPanelProxy:ToggleTab(Index, TabIndex)
  if not self.bDisableToggleTabAudio then
    _G.NRCAudioManager:PlaySound2DAuto(40007003, "ToggleTab")
  end
  if not self.bDisableToggleTabAudio and self.bSkinListViewDirty then
    self.Settings:RemoveCameraSkinRedDots()
    self.bSkinListViewDirty = false
  end
  local Panel = self.Adapter:GetPanel()
  if Panel then
    Panel.NRCSwitcher_85:SetActiveWidgetIndex(Index - 1)
  end
  local Tab = self.TabList[TabIndex or Index]
  if Tab.OnRefresh then
    Tab.OnRefresh()
  end
end

function SettingPanelProxy:OnModeChanged(Mode)
  if Mode.Mgr:IsWorldMode() then
    self.PostProcessFilter:SetFilterPath(nil)
    if self.MainPanel.Text_FilterNme then
      self.MainPanel.Text_FilterNme:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
  else
    local Option = self.Settings.FilterGroup:GetSelectedOption()
    self:InternalRefreshFilter(Option)
  end
  self.Adapter:Close()
end

function SettingPanelProxy:OnInitFilterViewList()
  local Panel = self.Adapter:GetPanel()
  self.FilterListView = Panel.FilterList
  self.DataList = self.Settings:CreateFilterGroupUIDataList()
  self.FilterListView:InitList(self.DataList)
end

function SettingPanelProxy:OnRefreshFilterViewList()
  self.FilterListView:InitList(self.DataList)
  self.FilterListView:SelectItemByIndex(self.Settings.FilterGroup:GetSelectedIndex() - 1)
end

function SettingPanelProxy:OnFilterOptionChanged(Option, OldOption)
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "OnFilterOptionChanged")
  self:InternalRefreshFilter(Option)
end

function SettingPanelProxy:InternalRefreshFilter(Option)
  local FilterConf = Option.CustomData and Option.CustomData.FilterConf
  local Progress = Option.CustomData and Option.CustomData.BlendProgress
  self.PostProcessFilter:SetFilterPath(FilterConf and FilterConf.filter_path)
  if Progress then
    self.PostProcessFilter:SetupFilterParamCollection(self.MainPanel.FilterParamCollection)
    self.PostProcessFilter:SetFilterBlendProgress(Progress)
  end
  self:RefreshFilterProgressView()
end

function SettingPanelProxy:RefreshFilterProgressView()
  local Option = self.Settings.FilterGroup:GetSelectedOption()
  local FilterConf = Option.CustomData and Option.CustomData.FilterConf
  local Progress = Option.CustomData and Option.CustomData.BlendProgress
  local Panel = self.Adapter:GetPanel()
  if self.MainPanel.Text_FilterNme then
    self.MainPanel.Text_FilterNme:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if Progress then
    if Panel then
      Progress:BindProgressBar(Panel, Panel.ScheduleLeft_3, Panel.Slider_2)
      Panel.CanvasPanel_Filter:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      if self.MainPanel.Text_FilterNme then
        self.MainPanel.Text_FilterNme:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.MainPanel.Text_FilterNme:SetText(FilterConf and FilterConf.name)
      end
    end
  elseif Panel then
    Panel.CanvasPanel_Filter:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function SettingPanelProxy:CleanFilter()
  self.PostProcessFilter:Destroy()
end

function SettingPanelProxy:ResetFocalRegion()
  TakePhotosUtils.ResetPostProgressFocalRegion()
end

function SettingPanelProxy:OnFocalScaleChanged(Value)
  TakePhotosUtils.ChangePostProgressFocalScale(Value)
end

function SettingPanelProxy:OnFocalRegionChanged(Value)
  TakePhotosUtils.ChangePostProgressFocalRegion(Value)
end

function SettingPanelProxy:OnInitActionList()
  local Panel = self.Adapter:GetPanel()
  self.PoseListView = Panel.ActionList
  self.PoseDataList = self.Settings:CreatePoseActionGroupUIDataList()
  self.PoseListView:InitGridView(self.PoseDataList)
end

function SettingPanelProxy:OnInitEmojiList()
  local Panel = self.Adapter:GetPanel()
  self.EmojiListView = Panel.ExpressionList
  self.EmojiDataList = self.Settings:CreateEmojiGroupUIDataList()
  self.EmojiListView:InitGridView(self.EmojiDataList)
end

function SettingPanelProxy:OnInitFashionList()
  local Panel = self.Adapter:GetPanel()
  self.FashionListView = Panel.ClothingList
  self.FashionDataList = self.Settings:CreateFashionGroupUIDataList()
  self.FashionListView:InitGridView(self.FashionDataList)
end

function SettingPanelProxy:OnToggleMode()
  self.bTabListInitialized = false
  self.Adapter:Close()
  if not self.MainPanel.CurrMode then
    return
  end
  self:InternalPlayAction()
  self:InternalPlayEmoji()
end

function SettingPanelProxy:OnExitMode()
  if self.ActionPosePlayer then
    self.ActionPosePlayer:StopAnim()
  end
  if self.EmojiPlayer then
    self.EmojiPlayer:StopAnim()
  end
end

function SettingPanelProxy:InternalPlayAction()
  if self.bDestroyed then
    Log.Error("[TakePhoto] invalid")
    return
  end
  if not self.ActionPosePlayer then
    self.ActionPosePlayer = ActionPosePlayer(self.MainPanel.player)
  end
  if not self.MainPanel.CurrMode then
    return
  end
  if not self.MainPanel.CurrMode.Mgr:IsSelfieMode() then
    return
  end
  local bMirror = self.Settings.ActionMirror:IsEnabled()
  if self.MainPanel.CurrMode.Mgr:IsSelfieMode() then
    bMirror = self.MainPanel.player.viewObj.LeftHandCamera
  end
  local Option = self.Settings.ActionGroup:GetSelectedOption()
  local Conf = Option and Option.CustomData and Option.CustomData.PoseConf
  if Conf then
    self.ActionPosePlayer:PlayAnim(Conf, bMirror)
  else
    Log.Error("[TakePhoto] invalid action pose conf")
  end
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.SetSelfiePlayerLookAtOffset)
end

function SettingPanelProxy:OnPoseOptionChanged()
  _G.NRCAudioManager:PlaySound2DAuto(40007001, "OnPoseOptionChanged")
  self:InternalPlayAction()
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.SetSelfiePlayerLookAtOffset)
end

function SettingPanelProxy:InternalPlayEmoji()
  if self.bDestroyed then
    return
  end
  if not self.EmojiPlayer then
    self.EmojiPlayer = EmojiPlayer(self.MainPanel.player)
  end
  local PlaySuccess = true
  if self.MainPanel.CurrMode and (self.MainPanel.CurrMode.Mgr:IsSelfieMode() or self.MainPanel.CurrMode.Mgr:IsTripodAvailableMode()) then
    local NewOption = self.Settings.EmojiGroup:GetSelectedOption()
    local Conf = NewOption and NewOption.CustomData and NewOption.CustomData.EmojiConf
    if Conf then
      self.EmojiPlayer:PlayAnim(Conf)
      PlaySuccess = true
    end
  end
  if not PlaySuccess then
    self.EmojiPlayer:StopAnim()
  end
end

function SettingPanelProxy:OnEmojiOptionChanged(NewOption)
  _G.NRCAudioManager:PlaySound2DAuto(40007001, "OnEmojiOptionChanged")
  self:InternalPlayEmoji()
end

function SettingPanelProxy:OnFashionOptionChanged()
  _G.NRCAudioManager:PlaySound2DAuto(40007001, "OnFashionOptionChanged")
  local Option = self.Settings.FashionGroup:GetSelectedOption()
  local FashionRolePlayItem = Option and Option.CustomData and Option.CustomData.FashionRolePlayItem
  if FashionRolePlayItem then
    TakePhotosUtils.ChangeFashionWardrobe(FashionRolePlayItem.wardrobeIndex, self.MainPanel.CurrMode)
  end
end

function SettingPanelProxy:OnToggleActionMirror(bEnableMirror)
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "OnToggleActionMirror")
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.viewObj.SettingLeftHand = bEnableMirror
  self.DelayActionMirror = self.MainPanel:DelayFrames(1, function()
    self.DelayActionMirror = nil
    self:InternalPlayAction()
  end)
end

function SettingPanelProxy:CleanAction()
  if self.ActionPosePlayer then
    self.ActionPosePlayer:OnDestruct()
  end
end

function SettingPanelProxy:CleanEmoji()
  if self.EmojiPlayer then
    self.EmojiPlayer:OnDestruct()
  end
end

function SettingPanelProxy:ResetEmoji()
  self.Settings.EmojiGroup:Toggle(1)
  if self.EmojiListView then
    self.EmojiListView:SelectItemByIndex(0)
  end
end

function SettingPanelProxy:OnRefreshFashionListView()
  self.FashionListView:InitGridView(self.FashionDataList)
  local SelectedIdx = self.Settings.FashionGroup:GetSelectedIndex()
  self.FashionListView:SelectItemByIndex(SelectedIdx - 1)
end

function SettingPanelProxy:OnRefreshActionListView()
  self.PoseListView:InitGridView(self.PoseDataList)
  self.PoseListView:SelectItemByIndex(self.Settings.ActionGroup:GetSelectedIndex() - 1)
end

function SettingPanelProxy:OnRefreshEmojiListView()
  self.EmojiListView:InitGridView(self.EmojiDataList)
  self.EmojiListView:SelectItemByIndex(self.Settings.EmojiGroup:GetSelectedIndex() - 1)
end

function SettingPanelProxy:OnInitCameraSkinList()
  local Panel = self.Adapter:GetPanel()
  self.SkinListView = Panel.CameraList
  self.SkinDataList = self.Settings:CreateCameraSkinGroupUIDataList()
  self.SkinListView:InitGridView(self.SkinDataList)
end

function SettingPanelProxy:OnRefreshCameraSkinList()
  self.SkinListView:InitGridView(self.SkinDataList)
  self.SkinListView:SelectItemByIndex(self.Settings.CameraSkinGroup:GetSelectedIndex() - 1)
  self.bSkinListViewDirty = true
end

return SettingPanelProxy
