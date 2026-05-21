local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local LevelUpUtils = require("NewRoco.Modules.System.LevelUpUI.LevelUpUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local OnlineConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local LegendaryBattleModuleEnum = require("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleEnum")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local BattlePassModuleCmd = reload("NewRoco.Modules.System.BattlePass.BattlePassModuleCmd")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
local FarmModuleEvent = require("NewRoco.Modules.System.Farm.FarmModuleEvent")
local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local WishCrystalModuleEvent = require("NewRoco.Modules.System.WishCrystal.WishCrystalModuleEvent")
local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")
local LoadinguIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RelationTreeEvent = require("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local UMG_CompassIcon_C = _G.NRCViewBase:Extend("UMG_CompassIcon_C")
local ExpDisplayState = {
  Waiting = 1,
  ChargeToMax = 2,
  Displaying = 3,
  ChargeNormal = 4,
  ChargeElsePart = 5,
  PostDisplay = 6
}
local CompassMode = {
  SenseMode = 1,
  ExpUpShowMode = 2,
  UIUnlockShowMode = 3
}

function UMG_CompassIcon_C:Initialize(Initializer)
end

function UMG_CompassIcon_C:OnConstruct()
  Log.Debug("UMG_CompassIcon_C:OnConstruct")
  self.DisplayState = ExpDisplayState.Waiting
  self.CompassMode = CompassMode.SenseMode
  self.CompassResponseType = 0
  self.sense_level = 0
  self.sense_switch_count_down_time = 0.3
  self.sense_switch_count_down = 0.3
  self.VisitNumMax = 4
  for i = 1, #OnlineConf do
    if OnlineConf[i].key == "online_member_max" then
      self.VisitNumMax = OnlineConf[i].num
      break
    end
  end
  self:InitUI()
  self:OnAddEventListener()
  self.isPanelActive = true
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RegisterTopKFinder, self, 1, nil, function(sceneNpc)
    if not sceneNpc then
      return nil
    end
    local InterComp = sceneNpc.InteractionComponent
    if not InterComp then
      return nil
    end
    local Opt = InterComp:GetValidSenseOption()
    return Opt
  end)
  self.sense_dis_knowledge_stele = _G.DataConfigManager:GetMapGlobalConfig("sense_dis_knowledge_stele").numList
  self.sense_dis_document_stele = _G.DataConfigManager:GetMapGlobalConfig("sense_dis_document_stele").numList
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ableToShow = false
  if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() then
    self:InitCompassVisible()
  else
    self:InitCompassHidden()
  end
  self.VisitIconSate = 0
  self.unlockUIMap = {}
  self.Btn_MagicManua:SetRedDot(2)
  self.Btn_Pet:SetRedDot(3)
  self.Btn_HandBook:SetRedDot(4)
  self.Btn_Activity:ClearIgnoreRedPointDataList()
  self.Btn_Activity:SetIgnoreRedPointDataList(Enum.RedPointReason.RPR_ACTIVITY_TAB_NOTIFY, {300006})
  self.Btn_Activity:SetIgnoreRedPointDataList(Enum.RedPointReason.RPR_ACTIVITY_TAB_REWARD, {300006})
  self.Btn_Activity:SetRedDot(217)
  self.Btn_Pass:SetRedDot(149)
  self.Btn_FurnitureAtlas_1:SetRedDot(101)
  self.Btn_SeasonIntegration:SetRedDot(395)
  self:SetVisitBtn()
  self:SetMinIcons(true)
  self:BindInputAction()
  _G.NRCAudioManager:PlaySound2DAuto(1220002042, "UMG_CompassIcon_C:OnLobbyMainReady")
  if self:IsPCMode() then
    local Padding = UE4.FMargin()
    Padding.Left = 1000
    Padding.Top = 0
    Padding.Right = 113.904762
    Padding.Bottom = 98.412704
    self.VisitListBtn.Slot:SetOffsets(Padding)
    Padding.Left = 4
    Padding.Top = 19
    Padding.Right = 0
    Padding.Bottom = 0
    self.CanvasPanel_86.Slot:SetPadding(Padding)
  end
  self:PCKeySetting()
  local IsHiddenRed = _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnGetIsHiddenShopItemRed)
  if IsHiddenRed then
    self.NrcRedPoint:SetupKey(1, nil, nil, Enum.RedPointReason.RPR_MALLGOODS_POINT_REWARD)
  else
    self.NrcRedPoint:SetupKey(1)
  end
  self:RefreshFurnitureAtlasVisible()
  self.ProgressBar_46:SetPercent(0)
  self.ProgressBar1:SetPercent(0)
  self.Rise:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:InitStarlight()
  self.bHasScriptImplementedTick = true
end

function UMG_CompassIcon_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_CompassIcon_C:SetBriefVersion(briefVersion)
  if briefVersion then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAIN_BRIEF_SETTTING)
    local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAIN_BRIEF_SETTTING)
    self.FunctionBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    if isBan or isHide then
      self.BriefBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self.BriefBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.PanelProgressHeroExp:SetVisibility(UE.ESlateVisibility.Collapsed)
  else
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_COMPASS)
    local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_COMPASS)
    self.BriefBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.FunctionBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if isBan or isHide then
      self.PanelProgressHeroExp:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
      self.PanelProgressHeroExp:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_CompassIcon_C:NotifyHomeMinIconChange()
  self:SetMinIcons()
end

function UMG_CompassIcon_C:RefreshPetVisibility()
  local isBan = not _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_PET) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_PET)
  self.Btn_Pet:SetVisibility(isBan and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_CompassIcon_C:RefreshHandbookVisibility()
  local isBan = not _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_HANDBOOK) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_HANDBOOK)
  self.Btn_HandBook:SetVisibility(isBan and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_CompassIcon_C:RefreshActivityVisibility()
  local isBan = not _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_ACTIVITY) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_ACTIVITY)
  self.Btn_Activity:SetVisibility(isBan and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_CompassIcon_C:RefreshTaskVisibility()
  local isBan = not _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_TASK) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_TASK)
  self.Btn_Task:SetVisibility(isBan and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_CompassIcon_C:SetMinIcons(bRefreshImmediately)
  self.bIconsLayoutDirty = true
end

function UMG_CompassIcon_C:Tick(MyGeometry, InDeltaTime)
  if self.bIconsLayoutDirty then
    self.bIconsLayoutDirty = false
    self:InternalRefreshMinIcons()
  end
end

function UMG_CompassIcon_C:InternalRefreshMinIcons()
  self:Log("UMG_CompassIcon_C:SetMinIcons")
  self:SetMagicManualIcon()
  self:RefreshPetVisibility()
  self:RefreshHandbookVisibility()
  self:RefreshActivityVisibility()
  self:RefreshTaskVisibility()
  self:UpdatePassActive()
  self:SetSeasonIntegrationIcon()
  self:RefreshEditHomeVisible()
  self:RefreshFurnitureAtlasVisible()
  self:RefreshFriendVisible()
end

function UMG_CompassIcon_C:OnServerTimeUpdate()
  self:UpdatePassActive()
end

function UMG_CompassIcon_C:UpdatePassActive()
  local isBan = not _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_BP) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_BP)
  local isActivePass = _G.NRCModuleManager:DoCmd(BattlePassModuleCmd.IsActivitePass)
  local isOpenPass = not isBan and isActivePass
  self.Btn_Pass:SetVisibility(isOpenPass and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_CompassIcon_C:InitUI()
  self:SetMinIcons()
  local curLBMatchStage, matchInfo = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.GetCurMatchInfo)
  if curLBMatchStage == LegendaryBattleModuleEnum.CurStage.Matching then
    self:SetMatchTag(true)
  else
    self:SetMatchTag(false)
  end
  if matchInfo then
    self:SetLegendaryMatchState(curLBMatchStage, matchInfo.battleId, matchInfo.starNum, 0)
  end
end

function UMG_CompassIcon_C:OnDestruct()
  Log.Debug("UMG_CompassIcon_C:OnDestruct")
  _G.NRCAudioManager:PlaySound2DAuto(1220002043, "UMG_CompassIcon_C:OnLobbyMainClosed")
  self.isPanelActive = false
  self:OnRemoveEventListener()
  self:UnBindInputAction()
end

function UMG_CompassIcon_C:OnNavigationModeUpdate(mode)
  if self.NavigationMode ~= mode then
    self.NavigationMode = mode
    if self.NavigationMode == ProtoEnum.NavigationModeType.NMT_COMPASS then
      self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.NavigationMode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
      self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_CompassIcon_C:OnAddEventListener()
  self:AddButtonListener(self.BtnCompass, self.OpenLobbyMainCompass)
  self:AddButtonListener(self.VisitListBtn, self.OpenVisitPlane)
  self:AddButtonListener(self.Btn_MagicManua.btnLevelUp, self.OnBtnClick)
  self:AddButtonListener(self.Btn_Pet.btnLevelUp, self.OnBtnPetClick)
  self:AddButtonListener(self.Btn_HandBook.btnLevelUp, self.OnBtnBookClick)
  self:AddButtonListener(self.Btn_Activity.btnLevelUp, self.OnBtnActivityClick)
  self:AddButtonListener(self.Btn_Task.btnLevelUp, self.OnBtnTaskClick)
  self:AddButtonListener(self.Btn_Pass.btnLevelUp, self.OnBtnBPClick)
  self:AddButtonListener(self.Btn_Set.btnLevelUp, self.OnBtnSettingClick)
  self:AddButtonListener(self.Btn_FurnitureAtlas_1.btnLevelUp, self.OnBtnOpenFurnitureAtlasPanel)
  self:AddButtonListener(self.Btn_Decoration_1.btnLevelUp, self.OnBtnOpenFurnitureEditPanel)
  self:AddButtonListener(self.Btn_SeasonIntegration.btnLevelUp, self.OnBtnSeasonClick)
  self:AddButtonListener(self.Btn_friends.btnLevelUp, self.OnBtnFriendsClick)
  self:RegisterEvent(self, MainUIModuleEvent.SetUiAlpha, self.ChangBG)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataChange)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.VISIT_OWNER_CHANGED, self.SetVisitBtn)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryState)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, FriendModuleEvent.OnVisitorChanged, self.SetVisitBtn)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, SceneEvent.OnRelogin, self.SetVisitBtn)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, MainUIModuleEvent.MAINUICLOSE, self.OnLobbyMainClosed)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.OnEnterHomeMap)
  NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnExitHomeMap, self.OnExitHomeMap)
  NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnReEnterHomeMap, self.OnReEnterHomeMap)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, FarmModuleEvent.OnEnterFarmMap, self.OnEnterFarmMap)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, FarmModuleEvent.OnExitFarmMap, self.OnExitFarmMap)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, _G.NRCGlobalEvent.OnServerTimeUpdate, self.OnServerTimeUpdate)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdd)
  self:OnNavigationModeUpdate(_G.DataModelMgr.PlayerDataModel:GetNavigationMode())
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, LoadinguIModuleEvent.LOADING_UI_OPENED, self.OnEnterLoading)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, LoadinguIModuleEvent.LOADING_UI_CLOSED, self.OnLeaveLoading)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, RelationTreeEvent.OpenTeamPanel, self.OpenTeamPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_CompassIcon_C", self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
  NRCModuleManager:GetModule("TakePhotosModule"):RegisterEvent(self, TakePhotosModuleEvent.OnEnterTakePhotos, self.OnEnterTakePhotos)
  NRCModuleManager:GetModule("TakePhotosModule"):RegisterEvent(self, TakePhotosModuleEvent.OnExitTakePhotos, self.OnExitTakePhotos)
end

function UMG_CompassIcon_C:OnRemoveEventListener()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.VISIT_OWNER_CHANGED, self.SetVisitBtn)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryState)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.SetVisitBtn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnNetPlayerSpawn, self.OnNetPlayerSpawn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.SetVisitBtn)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnLobbyMainClosed)
  _G.NRCModuleManager:DoCmd(NPCModuleCmd.UnRegisterTopKFinder, self)
  self:UnRegisterEvent(self, MainUIModuleEvent.SetUiAlpha, self.ChangBG)
  local HomeModule = NRCModuleManager:GetModule("HomeModule")
  if HomeModule then
    HomeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
    HomeModule:UnRegisterEvent(self, HomeModuleEvent.OnExitHomeMap)
    HomeModule:UnRegisterEvent(self, HomeModuleEvent.OnReEnterHomeMap)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, FarmModuleEvent.OnEnterFarmMap, self.OnEnterFarmMap)
  _G.NRCEventCenter:UnRegisterEvent(self, FarmModuleEvent.OnExitFarmMap, self.OnExitFarmMap)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnServerTimeUpdate, self.OnServerTimeUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdd)
  _G.NRCEventCenter:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadinguIModuleEvent.LOADING_UI_OPENED, self.OnEnterLoading)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadinguIModuleEvent.LOADING_UI_CLOSED, self.OnLeaveLoading)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OpenTeamPanel, self.OpenTeamPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
  NRCModuleManager:GetModule("TakePhotosModule"):UnRegisterEvent(self, TakePhotosModuleEvent.OnEnterTakePhotos, self.OnEnterTakePhotos)
  NRCModuleManager:GetModule("TakePhotosModule"):UnRegisterEvent(self, TakePhotosModuleEvent.OnExitTakePhotos, self.OnExitTakePhotos)
end

function UMG_CompassIcon_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:BindAction("IA_OpenMenu", self, "OnOpenCompassUI")
    mappingContext:BindAction("IA_Compass", self, "IteractionCompass")
    mappingContext:BindAction("IA_TeamPanel", self, "OpenTeamPanel")
    mappingContext:BindAction("IA_FurnitureHandbook", self, "OnBtnOpenFurnitureAtlasPanel")
    mappingContext:BindAction("IA_DecorateMode", self, "OnBtnOpenFurnitureEditPanel")
    mappingContext:BindAction("IA_Setting", self, "OnOpenCompassUI")
    mappingContext:BindAction("IA_OpenSeason", self, "OpenSeason")
  end
end

function UMG_CompassIcon_C:UnBindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:UnBindAction("IA_OpenMen")
    mappingContext:UnBindAction("IA_Compass")
    mappingContext:UnBindAction("IA_TeamPane")
    mappingContext:UnBindAction("IA_FurnitureHandbook")
    mappingContext:UnBindAction("IA_DecorateMode")
    mappingContext:UnBindAction("IA_Setting")
    mappingContext:UnBindAction("IA_OpenSeason")
  end
end

function UMG_CompassIcon_C:UpdateBindInputAction()
  self:UnBindInputAction()
  self:BindInputAction()
end

function UMG_CompassIcon_C:PCKeySetting()
  if SystemSettingModuleCmd then
    if self.Text_PCKey_1 then
      self.Text_PCKey_1:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_TeamPanel")
      if "" ~= image then
        self.Text_PCKey_1:SetImageMode(image)
      else
        self.Text_PCKey_1:SetText(text)
      end
    end
    self.Btn_Activity:SetPCKey("IA_OpenActivityUI")
    self.Btn_SeasonIntegration:SetPCKey("IA_OpenSeason")
    self.Btn_MagicManua:SetPCKey("IA_OpenMagicManualUI")
    self.Btn_HandBook:SetPCKey("IA_OpenHandbookUI")
    self.Btn_Task:SetPCKey("IA_OpenTaskUI")
    self.Btn_Pet:SetPCKey("IA_OpenPetUI")
    self.Btn_FurnitureAtlas_1:SetPCKey("IA_FurnitureHandbook")
    self.Btn_Decoration_1:SetPCKey("IA_DecorateMode")
    self.Btn_Set:SetPCKey("IA_Setting")
    self.Btn_friends:SetPCKey("IA_OpenFriendUI")
  end
end

function UMG_CompassIcon_C:OnOpenCompassUI()
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  if ScenePlayerInputManager.IsPause() then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.inputComponent and player.inputComponent:GetPlayDialogueVideo() then
    return
  end
  if _G.NRCModeManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) then
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenMainPanel)
    return
  end
  if self:IsInMiniGamePerform() then
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_COMPASS) then
    Log.Debug("Open Compass Failed, Compass Hide!")
    return
  end
  if 4 ~= self.sense_level then
    self.ableToShow = false
    if _G.NRCModuleManager:DoCmd(MainUIModuleCmd.CheckCloseSimpleUseList) then
      return
    end
    if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() and self:GetWindow() ~= nil then
      self.ableToShow = true
      if self:OpenLobbyMainCompass() then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
      end
    else
      return
    end
  end
end

function UMG_CompassIcon_C:OpenTeamPanel()
  if self.VisitListBtn:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:OpenVisitPlane()
end

function UMG_CompassIcon_C:OpenBP()
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BP, true)
  if self.Btn_Pass:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  if self:IsInMiniGamePerform() then
    return
  end
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
  _G.NRCProfilerLog:NRCClickBtn(true, "BattlePassAwardMain")
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenBattlePass, nil, true, nil, false)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Pass_C:OnBtnClick()")
end

function UMG_CompassIcon_C:IteractionCompass()
  if 4 == self.sense_level then
    local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
    if isLockOpen then
      return
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    self.ableToShow = false
    if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() and self:GetWindow() ~= nil then
      self.ableToShow = true
      if self:OpenLobbyMainCompass() then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.LockOpenSubUiEvent)
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
      end
    else
      return
    end
  end
end

function UMG_CompassIcon_C:OnWorldPlayerStatusChange()
end

function UMG_CompassIcon_C:OnNetPlayerSpawn(_player)
end

function UMG_CompassIcon_C:SetVisitBtnInHomeState(InHomeState)
  local newPos = UE4.FVector2D(738, 0)
  if InHomeState then
    newPos = UE4.FVector2D(644.0, 16.0)
  end
  self.VisitListBtn.Slot:SetPosition(newPos)
end

function UMG_CompassIcon_C:OnEnterTakePhotos()
  self.bEnterTakePhotos = true
  self.ParticleSystemWidget2_85:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:StopAnimation(self.StarlightAlert__Animation)
  self:StopAnimation(self.StarlightBonus_Animation)
end

function UMG_CompassIcon_C:OnExitTakePhotos()
  self.bEnterTakePhotos = false
  self:SetVisitBtn()
  self:CheckNeedtoShowStarInfoChange()
end

function UMG_CompassIcon_C:SetVisitBtn()
  self:SetMagicManualIcon()
  Log.Debug("UMG_CompassIcon_C:SetVisitBtn", _G.DataModelMgr.PlayerDataModel:IsVisitState(), self.bEnterTakePhotos)
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not self.bEnterTakePhotos then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if visitorList and #visitorList < 1 and _G.DataModelMgr.PlayerDataModel.visitList then
      visitorList = _G.DataModelMgr.PlayerDataModel.visitList
    end
    Log.Debug("UMG_CompassIcon_C:SetVisitBtnVisible", visitorList and #visitorList > 0)
    if visitorList and #visitorList > 0 then
      self.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      local text = string.format("%d/4", #visitorList)
      self.PeopleCounting:SetText(text)
    else
      self:SetVisitBtnWidgetIndex(0)
      self.VisitBtnIndex = nil
      self.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendPanelTeam)
    end
  else
    Log.Debug("UMG_CompassIcon_C:SetCollapsedVisitBtn")
    self.HomePlayerList = nil
    self:SetVisitBtnWidgetIndex(0)
    self.VisitBtnIndex = nil
    self.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.bEnterTakePhotos then
    else
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendPanelTeam)
    end
  end
  self:SetVisitBtnIcon()
end

function UMG_CompassIcon_C:GetVisitBtnAnim(OldIndex, NewIndex)
  local Anim
  local IsReverse = false
  if OldIndex and NewIndex then
    if 0 == OldIndex then
      if 1 == NewIndex then
        Anim = self.Normalcy_to_Select
      end
      if 2 == NewIndex then
        Anim = self.Normalcy_to_Lighten
      end
      if 3 == NewIndex then
        Anim = self.Normalcy_to_Select_Lighten
      end
    end
    if 1 == OldIndex then
      if 0 == NewIndex then
        IsReverse = true
        Anim = self.Normalcy_to_Select
      end
      if 2 == NewIndex then
        IsReverse = true
        Anim = self.Lighten_to_Normalcy_Select
      end
      if 3 == NewIndex then
        Anim = self.Select_to_Lighten
      end
    end
    if 2 == OldIndex then
      if 0 == NewIndex then
        Anim = self.Lighten_to_Normalcy
      end
      if 1 == NewIndex then
        Anim = self.Lighten_to_Normalcy_Select
      end
      if 3 == NewIndex then
        Anim = self.Lighten_to_Select
      end
    end
    if 3 == OldIndex then
      if 0 == NewIndex then
        IsReverse = true
        Anim = self.Normalcy_to_Select_Lighten
      end
      if 1 == NewIndex then
        Anim = self.Lighten_to_Select_2
      end
      if 2 == NewIndex then
        IsReverse = true
        Anim = self.Lighten_to_Select
      end
    end
  else
    if 0 == NewIndex then
      Anim = self.Normalcy_Normal
    end
    if 1 == NewIndex then
      Anim = self.Select_Normal
    end
    if 2 == NewIndex then
      Anim = self.Lighten_Normal
    end
    if 3 == NewIndex then
      Anim = self.Lighten_Select_Normal
    end
  end
  return IsReverse, Anim
end

function UMG_CompassIcon_C:SetVisitBtnWidgetIndex(index)
  if self.VisitBtnIndex == index then
    return
  end
  if self.CurPlayAnim and self:IsAnimationPlaying(self.CurPlayAnim) then
    self:StopAnimation(self.CurPlayAnim)
  end
  local isReverse, Anim = self:GetVisitBtnAnim(self.VisitBtnIndex, index)
  if Anim then
    if isReverse then
      self:PlayAnimationReverse(Anim)
    else
      self:PlayAnimation(Anim)
    end
  end
  self.CurPlayAnim = Anim
  self.VisitBtnIndex = index
end

function UMG_CompassIcon_C:SetVisitBtnIcon()
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    if visitorList and #visitorList < 1 and _G.DataModelMgr.PlayerDataModel.visitList then
      visitorList = _G.DataModelMgr.PlayerDataModel.visitList
    end
    if visitorList and #visitorList > 0 then
      self:SetVisitIconState(0)
    end
  end
end

function UMG_CompassIcon_C:SetVisitIconState(State)
  if self.VisitIconSate == State then
    return
  end
  self.VisitIconSate = State
  self:PlayAnimation(self.VisitIconRefresh)
end

function UMG_CompassIcon_C:SetMatchTag(bVisible)
  if bVisible then
    self.MatchTag:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.MatchTag:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:SetLegendaryMatchState(matchState, battleId, starNum, time)
  if nil ~= matchState and nil ~= battleId and battleId > 0 then
    self:SetMatchTag(matchState == LegendaryBattleModuleEnum.CurStage.Matching or matchState == LegendaryBattleModuleEnum.CurStage.Full)
  end
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if visitorList and #visitorList == self.VisitNumMax then
    self:SetVisitBtnWidgetIndex(2)
  else
    self:SetVisitBtnWidgetIndex(0)
  end
  if nil ~= battleId and battleId > 0 then
    local monsterConfId = _G.DataConfigManager:GetBattleConf(battleId).npc_battle_list[1].pos1_1st[1]
    local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    self.HeadPortrait:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
  end
  if nil ~= starNum then
    if 0 == starNum then
      self:SetMatchTag(false)
    end
    self.Text_GradeOfDifficulty:SetText(starNum)
  end
  if time > 0 and nil ~= battleId and battleId > 0 then
    self.Panel_Matchmaking:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local sec = math.floor(time % 60)
    local min = math.floor(time / 60)
    local timeText = string.format("%d:%02d", min, sec)
    self.TextCountDown:SetText(timeText)
  else
    self.Panel_Matchmaking:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:OpenVisitPlane()
  NRCProfilerLog:NRCClickBtn(true, "Plane_Team")
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendPanelTeam)
  else
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenFriendPanelTeam, self.HomePlayerList)
  end
  self:SetMatchTag(false)
  local curLBMatchStage, matchInfo = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.GetCurMatchInfo)
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if visitorList and #visitorList == self.VisitNumMax then
    self:SetVisitBtnWidgetIndex(3)
  else
    self:SetVisitBtnWidgetIndex(1)
  end
end

function UMG_CompassIcon_C:OnVisitPlaneClosed()
  local curLBMatchStage, matchInfo = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.GetCurMatchInfo)
  if (curLBMatchStage == LegendaryBattleModuleEnum.CurStage.Matching or curLBMatchStage == LegendaryBattleModuleEnum.CurStage.Full) and matchInfo.battleId and matchInfo.battleId > 0 then
    self:SetMatchTag(true)
  end
  local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
  if visitorList and #visitorList == self.VisitNumMax then
    self:SetVisitBtnWidgetIndex(2)
  else
    self:SetVisitBtnWidgetIndex(0)
  end
end

function UMG_CompassIcon_C:OnLobbyMainReady()
  self:SetSenseLevel(0, 100)
  self:UpdateSenseRTPC()
  self.isEnable = true
  self:CheckNeedtoShowStarInfoChange()
end

function UMG_CompassIcon_C:OnLobbyMainClosed()
  self:InitUI()
  if self.UnlockDelayId then
    _G.DelayManager:CancelDelayById(self.UnlockDelayId)
    self.CompassMode = CompassMode.SenseMode
  end
  self.isEnable = false
end

function UMG_CompassIcon_C:UpdateStoryState(flag, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flag)
  if bIsHomeOwner == UseSelf then
    return
  end
  self:SetMinIcons()
  if not self.ableToShow then
    if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() then
      self:InitCompassVisible()
    else
      self:InitCompassHidden()
    end
  end
  if flag == _G.Enum.PlayerStoryFlagEnum.PSF_FUNC_WISH_STAR then
    local starlightFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_WISH_STAR)
    if starlightFlag then
      local wishExchangeConf = _G.DataConfigManager:GetWishExchangeConf(1)
      if wishExchangeConf then
        local path = wishExchangeConf.icon
        if path and "" ~= path then
          self.Rise:SetPath(path)
          self.Rise:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
  end
end

function UMG_CompassIcon_C:InitCompassVisible()
  self.ableToShow = true
  self:SetBriefVersion(false)
end

function UMG_CompassIcon_C:InitCompassHidden()
  self.ableToShow = false
  self:SetBriefVersion(true)
end

function UMG_CompassIcon_C:Show(VisibleMode)
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_WORLD_MAP_UI, false, false)
  if Ban then
    Log.Debug("UMG_CompassIcon_C.show \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  if VisibleMode then
    self:SetVisibility(VisibleMode)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.OnCmdGetIsInFarm) then
    self:OnEnterFarmMap()
  end
  if HomeIndoorSandbox and HomeIndoorSandbox:InHomeIndoor() then
    self:OnEnterHomeMap()
  end
end

function UMG_CompassIcon_C:Hide(HideMode)
  if HideMode then
    self:SetVisibility(HideMode)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:OnPlayerDataChange()
  self:SetVisitBtn()
  self:SetMinIcons()
end

function UMG_CompassIcon_C:UpdateUIBan()
  local banCompass = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_COMPASS)
  local hideCompass = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_COMPASS)
  if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() and not hideCompass and not banCompass then
    self.PanelProgressHeroExp:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PanelProgressHeroExp:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:UpdateMiniMapUIBan()
  local NavigationMode = _G.DataModelMgr.PlayerDataModel:GetNavigationMode()
  local isHide = NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAP_TOP) or not NavigationMode or NavigationMode ~= ProtoEnum.NavigationModeType.NMT_MINIMAP
  if isHide then
    self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.CanvasPanel_86:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_CompassIcon_C:OpenLobbyMainCompass()
  self.isInSpecialDungeon = DataModelMgr.PlayerDataModel:GetDungeonID() == 120205
  if self.isInSpecialDungeon and self.sense_level < 1 then
    local str = _G.DataConfigManager:GetGlobalConfigByKeyType("dark_river_soul_compass_ban", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, str)
    return false
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_COMPASS, true) or _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_COMPASS, false, true)
  if isBan then
    return false
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008007, "UMG_CompassIcon_C:OnBtnBookClick")
  if self.CompassMode == CompassMode.SenseMode then
    if 4 == self.sense_level then
      local npc
      local npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetTopKNPC, self)
      if #npcs > 0 then
        npc = npcs[1]
      end
      if npc then
        local option = self:GetOptionCanSense(npc)
        if option and option.CurrentAction then
          local squared_dis = npc.squaredDis2Local
          local option_squared_dis = option:GetSquaredDistance()
          if squared_dis < option_squared_dis and option.CurrentAction:OnNpcAction() then
            self:SetSenseLevel(0, 100)
            option:OnOptionAction()
            return false
          else
            Log.Debug("\233\152\178\228\189\143\228\186\134", squared_dis, option_squared_dis)
          end
        else
          Log.Debug("option\232\186\171\228\184\138CurrentAction\230\152\175\231\169\186\239\188\159\232\191\152\230\152\175\232\175\180optionCanSense\230\152\175\231\169\186\239\188\159", option)
        end
      else
        Log.Debug("\230\136\145\229\143\175\228\187\165\228\186\164\228\186\146\231\154\132NPC\230\182\136\229\164\177\228\186\134?")
      end
    else
      Log.Debug("\230\132\159\231\159\165\231\173\137\231\186\167\228\184\141\229\164\159", self.sense_level)
    end
  else
    Log.Debug("\229\189\147\229\137\141\231\154\132\231\138\182\230\128\129\228\184\141\230\152\175\230\132\159\231\159\165", self.CompassMode)
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player or not player.viewObj then
    return false
  end
  local playerMoveComp = player.viewObj.CharacterMovement
  if player.viewObj.RidePet then
    playerMoveComp = player.viewObj.RidePet.CharacterMovement
  end
  local PCM = player.viewObj:GetController().PlayerCameraManager
  local bCheckSkillAndAnim = not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
  local bThrowing = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)
  local bFalling = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_FALLING)
  local bInRide = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  local bInDoubleRide = bInRide and player.viewObj.BP_RideComponent:IsInDoubleRide()
  local bInTransform = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
  local bRidingInAir = playerMoveComp.MovementMode == UE.EMovementMode.MOVE_Falling or playerMoveComp.MovementMode == UE.EMovementMode.MOVE_Custom and playerMoveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Gliding
  local bInClimbStart = false
  if playerMoveComp.IsInClimbStart then
    bInClimbStart = playerMoveComp:IsInClimbStart()
  end
  local bIsSitDown = player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN)
  local bIsBlindBox = player:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX)
  local bSkillPlaying = not bIsSitDown and bCheckSkillAndAnim and player.viewObj.RocoSkill:IsPlayingSkill()
  local bCamCheckFail = not PCM:PreMainUiCameraCheck()
  local bAnyAnimPlaying = bCheckSkillAndAnim and player:GetAnimComponent():IsAnyAnimPlaying()
  local bInputNotEnable = not player.inputComponent:GetInputEnable()
  local PlayerCamera = PCM and PCM:GetCameraAnimInstance()
  local bInCustomCameraVolume = PlayerCamera and PlayerCamera.GM_Camera
  local bInHoldHandsGuest = player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P)
  local bInInteract = player.statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM, ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING)
  local bIsAiming = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming)
  local bIsInInteract = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) or _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasBattleDialogue) or _G.NRCModuleManager:DoCmd(_G.BattleModuleCmd.IsInBattle)
  local cantOpen = bSkillPlaying or bInputNotEnable or bThrowing or bFalling or bRidingInAir or bInDoubleRide or bInInteract or bIsAiming or bInClimbStart or bIsInInteract
  local tips
  if cantOpen then
    Log.Warning("CantOpen Reason: ", bSkillPlaying or false, bAnyAnimPlaying or false, bInputNotEnable or false, bThrowing or false, bFalling or false, bRidingInAir or false, bInDoubleRide or false, bInInteract or false, bIsAiming or false)
    tips = LuaText.Unable_exhale_compass_state
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
    return false
  else
    if self:CheckIsSelectBtn() then
      return false
    end
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").COMPASS
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    player:Stop()
    local OpenType
    if bIsSitDown then
      OpenType = MainUIModuleEnum.CompassOpenType.COMPASS_2D_WITH_PLAYER
    elseif bIsBlindBox then
      OpenType = MainUIModuleEnum.CompassOpenType.COMPASS_2D_IGNORE_PLAYER
    elseif bCamCheckFail or bInTransform or bInCustomCameraVolume or bInHoldHandsGuest or bInRide or bAnyAnimPlaying then
      OpenType = MainUIModuleEnum.CompassOpenType.COMPASS_2D_NO_PLAYER
    else
      OpenType = MainUIModuleEnum.CompassOpenType.COMPASS_3D
    end
    player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_IDLE_RELAX)
    _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnLobbyMainInnerOpened)
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "LobbyMainInner")
    _G.NRCAudioManager:SetLobbyMainInnerOpen(true)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMainInner, OpenType)
    return true
  end
end

function UMG_CompassIcon_C:GetWindow()
  local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if not MainUIModule then
    self.MainPanelVisible = false
    return nil
  end
  if MainUIModule:HasPanel("LobbyMain") then
    local panel = MainUIModule:GetPanel("LobbyMain")
    if panel and panel.enableView then
      return panel
    else
      self.MainPanelVisible = false
      return nil
    end
  else
    self.MainPanelVisible = false
    return nil
  end
end

function UMG_CompassIcon_C:PlayReceive()
  self:PlayAnimation(self.Receive)
end

function UMG_CompassIcon_C:OnTick(DeltaTime)
  if not self.isPanelActive then
    return
  end
  local npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetTopKNPC, self)
  if npcs and #npcs > 0 then
    local npc = npcs[1]
    self:UpdateSenseLevel(npc, DeltaTime)
  else
    self:UpdateSenseLevel(nil, DeltaTime)
  end
end

function UMG_CompassIcon_C:ShowDebugString(debug_string)
  local World = _G.UE4Helper.GetCurrentWorld()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player or not player.viewObj then
    return
  end
  UE4.UKismetSystemLibrary.Abs_DrawDebugString(World, player.viewObj:Abs_K2_GetActorLocation(), debug_string, nil, UE4.FLinearColor(1, 1, 1, 1), 0, false, 3.0)
end

function UMG_CompassIcon_C:GetOptionCanSense(sceneNpc)
  if not sceneNpc then
    return nil
  end
  local InterComp = sceneNpc.InteractionComponent
  if not InterComp then
    return nil
  end
  local Opt = InterComp:GetValidSenseOption()
  return Opt
end

function UMG_CompassIcon_C:SwitchToSenseMode()
  if 1 == self.sense_level then
    self:StopAllAnimations()
    self:PlayAnimation(self.Breathing_Level1)
    if self:IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    end
  elseif 2 == self.sense_level then
    self:StopAllAnimations()
    self:PlayAnimation(self.Breathing_Level2)
    if self:IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    end
  elseif 3 == self.sense_level then
    self:StopAllAnimations()
    self:PlayAnimation(self.Breathing_Level3)
    if self:IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    end
  elseif 4 == self.sense_level then
    self:StopAllAnimations()
    self:PlayAnimation(self.Breathing_Level4)
    if self:IsPCMode() and SystemSettingModuleCmd and self.Text_PCKey then
      self.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_Compass")
      if "" ~= image then
        self.Text_PCKey:SetImageMode(image)
      else
        self.Text_PCKey:SetText(text)
      end
    end
  else
    self:StopAllAnimations()
    self:PlayAnimation(self.Idle)
    if self:IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    end
  end
  self:UpdateSenseRTPC()
end

function UMG_CompassIcon_C:UpdateSenseRTPC()
  local interpolateTime = 2
  if 1 == self.sense_level then
    _G.NRCAudioManager:SetGlobalRTPC("UI_System_Compass_LuoPanShanDong", 130, interpolateTime, "UMG_CompassIcon_C:UpdateSenseRTPC")
  elseif 2 == self.sense_level then
    _G.NRCAudioManager:SetGlobalRTPC("UI_System_Compass_LuoPanShanDong", 90, interpolateTime, "UMG_CompassIcon_C:UpdateSenseRTPC")
  elseif 3 == self.sense_level then
    _G.NRCAudioManager:SetGlobalRTPC("UI_System_Compass_LuoPanShanDong", 50, interpolateTime, "UMG_CompassIcon_C:UpdateSenseRTPC")
  elseif 4 == self.sense_level then
    _G.NRCAudioManager:SetGlobalRTPC("UI_System_Compass_LuoPanShanDong", 10, interpolateTime, "UMG_CompassIcon_C:UpdateSenseRTPC")
  else
    _G.NRCAudioManager:SetGlobalRTPC("UI_System_Compass_LuoPanShanDong", 180, interpolateTime, "UMG_CompassIcon_C:UpdateSenseRTPC")
  end
end

function UMG_CompassIcon_C:OnAnimationFinished(Animation)
  if Animation == self.LuoPan_Add then
    local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
    if data then
      local starlightInfo = data:GetStarlightInfo()
      if starlightInfo then
        if starlightInfo.unexchange_wishing_star_num and starlightInfo.unexchange_wishing_star_num > 0 then
          self.ProgressBar_46:SetPercent(1)
          self.ProgressBar1:SetPercent(1)
          self:PlayAnimation(self.LuoPan_Full, 0, 0)
        elseif starlightInfo.current_progress then
          self.ProgressBar_46:SetPercent(starlightInfo.current_progress / 10000)
          self.ProgressBar1:SetPercent(starlightInfo.current_progress / 10000)
          self:PlayAnimation(self.LuoPan_Normal, 0, 0)
        end
      end
    end
  elseif Animation == self.StarlightBonus_Animation or Animation == self.StarlightAlert__Animation then
    self:CheckNeedtoShowStarInfoChange(true)
  elseif Animation == self.Idle then
    self:PlayAnimation(self.Idle)
  end
end

function UMG_CompassIcon_C:ExitSenseMode()
  self:StopAllAnimations()
  self:PlayAnimation(self.Idle)
end

function UMG_CompassIcon_C:SetSenseLevel(sense_level, DeltaTime)
  if self.sense_level == sense_level then
    self.sense_switch_count_down = self.sense_switch_count_down_time
    return
  end
  if sense_level > self.sense_level then
    self.sense_switch_count_down = self.sense_switch_count_down_time
    self.sense_level = sense_level
  else
    self.sense_switch_count_down = self.sense_switch_count_down - DeltaTime
    if self.sense_switch_count_down > 0 then
      return
    end
    self.sense_switch_count_down = self.sense_switch_count_down_time
    self.sense_level = sense_level
  end
  if self.CompassMode == CompassMode.SenseMode then
    self:SwitchToSenseMode()
  end
end

function UMG_CompassIcon_C:UpdateSenseLevel(sceneNpc, DeltaTime)
  if _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.IsPlaying) then
    self:SetSenseLevel(0, DeltaTime)
    return
  end
  if nil == sceneNpc then
    self:SetSenseLevel(0, DeltaTime)
    return
  end
  local option = self:GetOptionCanSense(sceneNpc)
  if nil == option then
    self:SetSenseLevel(0, DeltaTime)
    return
  end
  local squared_dis = sceneNpc.squaredDis2Local
  self:UpdateSenseLevelInner(squared_dis, DeltaTime, option, sceneNpc)
end

function UMG_CompassIcon_C:GetNpcPlayerDegree(sceneNpc)
  local local_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local player_view = local_player and local_player.viewObj
  if not player_view or not UE.UObject.IsValid(player_view) then
    return 0
  end
  local forward = UE4.FVector(1, 0, 0)
  local player_forward = UE4.UKismetMathLibrary.RotateAngleAxis(forward, player_view:K2_GetActorRotation().Yaw, _G.FVectorUp)
  player_forward.Z = 0
  player_forward:Normalize()
  local scene_location = sceneNpc:GetActorLocation()
  local player_location = player_view:Abs_K2_GetActorLocation()
  local direction_vector = 0
  if scene_location and player_location then
    direction_vector = scene_location - player_location
  else
    return 0
  end
  direction_vector.Z = 0
  direction_vector:Normalize()
  if _G.GlobalConfig.ShowCompassSensing then
    UE4.UKismetSystemLibrary.DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), player_view:K2_GetActorLocation(), player_view:K2_GetActorLocation() + player_forward * 100, UE.FLinearColor(0, 1, 0, 1), 0, 2)
    UE4.UKismetSystemLibrary.DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), player_view:K2_GetActorLocation(), player_view:K2_GetActorLocation() + direction_vector * 100, UE.FLinearColor(1, 0, 0, 1), 0, 2)
  end
  local dot = UE4.FVector.Dot(player_forward, direction_vector)
  local degree = math.deg(math.acos(dot))
  return degree
end

function UMG_CompassIcon_C:GetPreferSenseLevel(sense_type, distance, option_squared_distance, CompassConf, degree)
  if sense_type == NPCModuleEnum.SenseTypeEnum.TotalSense then
    if distance < option_squared_distance then
      return 4
    elseif distance < CompassConf.action.sense_dist * CompassConf.action.sense_dist * 10000 then
      if degree < CompassConf.action.high_sense_degree then
        return 3
      elseif degree < CompassConf.action.medium_sense_degree then
        return 2
      elseif degree < CompassConf.action.low_sense_degree then
        return 1
      else
        return 0
      end
    else
      return 0
    end
  elseif sense_type == NPCModuleEnum.SenseTypeEnum.InteractableSense then
    if distance < option_squared_distance then
      return 4
    else
      return 0
    end
  else
    return 0
  end
end

function UMG_CompassIcon_C:UpdateSenseLevelInner(distance, DeltaTime, option, sceneNpc)
  local CompassConf = _G.DataConfigManager:GetNpcCompassOption(option.config.id)
  if not CompassConf then
    return 0, NPCModuleEnum.SenseTypeEnum.NoSense
  end
  self:UpdateCompassStyle(CompassConf.action.action_style_type)
  local SenseType
  _, SenseType = NPCLuaUtils.GetSenseInfo(option)
  local SquaredDist = option:GetSquaredDistance()
  local local_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not local_player or not local_player.viewObj then
    return 0, NPCModuleEnum.SenseTypeEnum.NoSense
  end
  local degree = self:GetNpcPlayerDegree(sceneNpc)
  local sense_level = self:GetPreferSenseLevel(SenseType, distance, SquaredDist, CompassConf, degree)
  self:SetSenseLevel(sense_level, DeltaTime)
  if _G.GlobalConfig.ShowCompassSensing then
    local debug_string = string.format("%d %d %s %d (%s %s) (%d %d %d %d) (%d %d %d)", CompassConf.id, sceneNpc.serverData and sceneNpc.serverData.npc_base and sceneNpc.serverData.npc_base.npc_content_cfg_id, sceneNpc.serverData and sceneNpc.serverData.base and sceneNpc.serverData.base.name, sense_level, table.getKeyName(_G.Enum.CompassType, CompassConf.action.first_compass_option_type), table.getKeyName(_G.Enum.CompassType, CompassConf.action.next_compass_option_type), CompassConf.action.low_sense_degree, CompassConf.action.medium_sense_degree, CompassConf.action.high_sense_degree, CompassConf.action.sense_dist, math.floor(math.sqrt(distance) / 100), math.floor(math.sqrt(SquaredDist) / 100), math.floor(degree))
    self:ShowDebugString(debug_string)
  end
end

function UMG_CompassIcon_C:UpdateCompassStyle(action_style_type)
  if self.CompassResponseType ~= action_style_type then
    if action_style_type == _G.Enum.CompassStyleType.AST_LEGENDARY then
      self.Icon_6:SetPath("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_LXY_158.T_UI_LXY_158")
      self.Icon_2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("B8B14BFF"))
      self.Icon_3:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("B8B14BFF"))
      self:SetDynamicMaterial("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_LXY_158.T_UI_LXY_158")
    elseif action_style_type == _G.Enum.CompassStyleType.AST_DUNGEON then
      self.Icon_6:SetPath("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_DS_340.T_UI_DS_340")
      self.Icon_2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("39A8A3FF"))
      self.Icon_3:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("39A8A3FF"))
      self:SetDynamicMaterial("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_DS_340.T_UI_DS_340")
    else
      self.Icon_6:SetPath("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_DS_340.T_UI_DS_340")
      self.Icon_2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("39A8A3FF"))
      self.Icon_3:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("39A8A3FF"))
      self:SetDynamicMaterial("/Game/NewRoco/Modules/System/MainUI/Raw/Texture/T_UI_DS_340.T_UI_DS_340")
    end
  end
  self.CompassResponseType = action_style_type
end

function UMG_CompassIcon_C:SetDynamicMaterial(changeIconPath)
  self:LoadPanelRes(changeIconPath, 255, self.SetDynamicMaterialSucc)
end

function UMG_CompassIcon_C:SetDynamicMaterialSucc(resRequest, changeIcon)
  local material = self.Icon_1:GetDynamicMaterial()
  material:SetTextureParameterValue("Maintex", changeIcon)
  material:SetTextureParameterValue("Mask_Texture", changeIcon)
  self.Icon_1:SetBrushFromMaterial(material, false)
end

function UMG_CompassIcon_C:OnBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnBookClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK, true)
  if isBan then
    return
  end
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  NRCProfilerLog:NRCClickBtn(true, "MagicManualMainPanel")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).MAGICMANUA
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  if self:MagicManualIsOpenToTeachType() then
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManualByIndex, "MMT_TYPE_DAVANTAGE_TEACH")
  else
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManual)
  end
end

function UMG_CompassIcon_C:MagicManualIsOpenToTeachType()
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_TYPE_BATTLE_TRAIN)
  if not Flags then
    return false
  end
  local IsOpenToTeachType = false
  local RedPointList = _G.DataModelMgr.PlayerDataModel:GetRedPointInfo()
  for k, v in ipairs(RedPointList) do
    if v.reason_type == _G.Enum.RedPointReason.RPR_LOCK_TYPE_DAVANTAGE and v.point_data and #v.point_data > 0 then
      IsOpenToTeachType = true
    end
    if (v.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_REGION_REWARD or v.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_CHAPTER_REWARD or v.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_CHAPTER or v.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_TASK or v.reason_type == _G.Enum.RedPointReason.RPR_SEASON_ADVENTURE_CHAPTER or v.reason_type == _G.Enum.RedPointReason.RPR_SEASON_ADVENTURE_TASK) and v.point_data and #v.point_data > 0 then
      return false
    end
  end
  return IsOpenToTeachType
end

function UMG_CompassIcon_C:OnBtnPetClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnPetClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET, true)
  if isBan then
    return
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if not battlePetList[1] then
    return
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "PetInfoMain")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PET
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  }, nil, nil, true)
end

function UMG_CompassIcon_C:OnBtnBookClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnBookClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK, true)
  if isBan then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").BOOK
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  _G.NRCProfilerLog:NRCClickBtn(true, "HandbookCover")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookCover, {isPlayCompass = true})
end

function UMG_CompassIcon_C:OnBtnActivityClick()
  _G.NRCProfilerLog:NRCClickBtn(true, "ActivityMainPanel")
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnActivityClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_ACTIVITY, true)
  if isBan then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").ACTIVITY
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenMainPanel)
end

function UMG_CompassIcon_C:OnBtnTaskClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnActivityClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TASK, true)
  if isBan then
    return
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "TaskMainPanel")
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASK
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.OpenTaskPanel)
end

function UMG_CompassIcon_C:OnBtnBPClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnActivityClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  if self:CheckIsSelectBtn() then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenBattlePass, nil, true, nil, false)
end

function UMG_CompassIcon_C:OnBtnSettingClick()
  if self.BriefBox:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenMainPanel)
  end
end

function UMG_CompassIcon_C:OnBtnSeasonClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnSeasonClick")
  _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPanel)
end

function UMG_CompassIcon_C:OpenSeason()
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.statusComponent and (localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC)) then
    return
  end
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  if seasonInfo then
    local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_SEASON)
    if not bHide then
      _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPanel)
    end
  end
end

function UMG_CompassIcon_C:OnBtnFriendsClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnFriendsClick")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenMainPanel)
end

function UMG_CompassIcon_C:IsInMiniGamePerform()
  local status = _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
  if "Perform" == miniGameStage or status == ProtoEnum.MinigameStatus.MS_FINISH then
    return true
  end
  return false
end

function UMG_CompassIcon_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_CompassIcon_C:SetMagicManualIcon()
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
  if nil ~= select_pet_conf_id then
    local hideMagicManua = not _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK) and _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
    self.Btn_MagicManua:SetVisibility(hideMagicManua and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  else
    self.Btn_MagicManua:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:SetSeasonIntegrationIcon()
  self.Btn_SeasonIntegration:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  if seasonInfo then
    local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_SEASON)
    local bHomeHide = _G.HomeModuleCmd and _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_SEASON)
    bHide = bHide or bHomeHide
    if not bHide then
      self.Btn_SeasonIntegration:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonInfo.season_id)
      if nil ~= seasonConf then
        self.Btn_SeasonIntegration:SetPath(seasonConf.s_icon, seasonConf.s_icon, seasonConf.s_icon)
      end
      if 0 == seasonInfo.popup_time and not self.bShowSeasonBegin then
        self.bShowSeasonBegin = true
        Log.Info("UMG_CompassIcon_C SeasonBeginsTips AddTip")
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateSeasonBeginsTips())
      end
    end
  end
end

function UMG_CompassIcon_C:ChangBG()
  self.VisitListBtn:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.PanelProgressHeroExp:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.Btn_MagicManua.Ordinary:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
  self.Btn_Pass.Btn_Pass:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#FFFFFF00"))
end

function UMG_CompassIcon_C:CheckIsSelectBtn()
  return _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
end

function UMG_CompassIcon_C:OnEnterHomeMap()
  if self.bInHomeInitialized then
    return
  end
  self:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
  self.bInHomeInitialized = true
  self:NotifyHomeMinIconChange()
end

function UMG_CompassIcon_C:OnReEnterHomeMap()
  self:OnExitHomeMap()
  self:OnEnterHomeMap()
end

function UMG_CompassIcon_C:OnBtnOpenFurnitureAtlasPanel()
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  if ScenePlayerInputManager.IsPause() then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.inputComponent and player.inputComponent:GetPlayDialogueVideo() then
    return
  end
  if _G.NRCModeManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) then
    return
  end
  if self:IsInMiniGamePerform() then
    return
  end
  if HomeIndoorSandbox and HomeIndoorSandbox:InHomeIndoor() and HomeIndoorSandbox.HomeEditServ.bPendingEnterEditMode then
    return
  end
  if self.Btn_FurnitureAtlas_1:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnOpenFurnitureAtlasPanel")
    NRCModuleManager:DoCmd(HomeModuleCmd.OpenFurnitureAtlasPanel)
  end
end

function UMG_CompassIcon_C:OnBtnOpenFurnitureEditPanel()
  local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
  if isLockOpen then
    return
  end
  if ScenePlayerInputManager.IsPause() then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.inputComponent and player.inputComponent:GetPlayDialogueVideo() then
    return
  end
  if _G.NRCModeManager:DoCmd(_G.CinematicModuleCmd.IsPlaying) then
    return
  end
  if self:IsInMiniGamePerform() then
    return
  end
  if self.Btn_Decoration_1:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    NRCModuleManager:DoCmd(HomeModuleCmd.OpenHomeMainPanel)
  end
end

function UMG_CompassIcon_C:OnExitHomeMap()
  if not self.bInHomeInitialized then
    return
  end
  self:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
  self.HomePlayerList = nil
  self.bInHomeInitialized = false
  self:NotifyHomeMinIconChange()
end

function UMG_CompassIcon_C:OnEnterFarmMap()
  if self.bInFarmInitialized then
    return
  end
  self:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
  self.bInFarmInitialized = true
  self:NotifyHomeMinIconChange()
end

function UMG_CompassIcon_C:OnExitFarmMap()
  if not self.bInFarmInitialized then
    return
  end
  self:DispatchEvent(MainUIModuleEvent.RefreshTaskDungeon)
  self.bInFarmInitialized = false
  self:NotifyHomeMinIconChange()
end

function UMG_CompassIcon_C:OnStoryFlagAdd(flag, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flag)
  if bIsHomeOwner == UseSelf then
    return
  end
  if flag == _G.Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_FURNITURE_HANDBOOK then
    self:RefreshFurnitureAtlasVisible()
  end
end

function UMG_CompassIcon_C:RefreshFurnitureAtlasVisible()
  local bHasStoryFlag = _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_FURNITURE_HANDBOOK)
  local bHide = not _G.HomeModuleCmd or _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FURNITURE_HANDBOOK)
  if not (not bHide and bHasStoryFlag) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FURNITURE_HANDBOOK) then
    self.Btn_FurnitureAtlas_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_FurnitureAtlas_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_CompassIcon_C:RefreshEditHomeVisible()
  local bHide = not _G.HomeModuleCmd or _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_EDIT_HOME)
  if bHide or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_EDIT_HOME) then
    self.Btn_Decoration_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Decoration_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_CompassIcon_C:RefreshFriendVisible()
  if _G.HomeModuleCmd then
    local bInHome = _G.NRCModeManager:DoCmd(_G.HomeModuleCmd.IsInHomeScene)
    if not bInHome then
      self.Btn_friends:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FRIEND, true)
    if isBan then
      self.Btn_friends:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn_friends:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.Btn_friends:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_CompassIcon_C:OnQuickChatOpen()
  self._cachedTextPCKeyVisible = self.Text_PCKey and self.Text_PCKey:GetVisibility() ~= UE4.ESlateVisibility.Collapsed
  self._cachedTextPCKey1Visible = self.Text_PCKey_1 and self.Text_PCKey_1:GetVisibility() ~= UE4.ESlateVisibility.Collapsed
  self._cachedBtnActivityVisible = self.Btn_Activity and self.Btn_Activity:IsPCKeyVisible()
  self._cachedBtnSeasonIntegrationVisible = self.Btn_SeasonIntegration and self.Btn_SeasonIntegration:IsPCKeyVisible()
  self._cachedBtnMagicManuaVisible = self.Btn_MagicManua and self.Btn_MagicManua:IsPCKeyVisible()
  self._cachedBtnHandBookVisible = self.Btn_HandBook and self.Btn_HandBook:IsPCKeyVisible()
  self._cachedBtnTaskVisible = self.Btn_Task and self.Btn_Task:IsPCKeyVisible()
  self._cachedBtnPetVisible = self.Btn_Pet and self.Btn_Pet:IsPCKeyVisible()
  self._cachedBtnFurnitureAtlas1Visible = self.Btn_FurnitureAtlas_1 and self.Btn_FurnitureAtlas_1:IsPCKeyVisible()
  self._cachedBtnDecoration1Visible = self.Btn_Decoration_1 and self.Btn_Decoration_1:IsPCKeyVisible()
  self._cachedBtnSetVisible = self.Btn_Set and self.Btn_Set:IsPCKeyVisible()
  self._cachedBtnFriendsVisible = self.Btn_friends and self.Btn_friends:IsPCKeyVisible()
  if self.Text_PCKey then
    self.Text_PCKey:SetKeyVisibility(false)
  end
  if self.Text_PCKey_1 then
    self.Text_PCKey_1:SetKeyVisibility(false)
  end
  if self.Btn_Activity then
    self.Btn_Activity:ShowOrHidePCKey(false)
  end
  if self.Btn_SeasonIntegration then
    self.Btn_SeasonIntegration:ShowOrHidePCKey(false)
  end
  if self.Btn_MagicManua then
    self.Btn_MagicManua:ShowOrHidePCKey(false)
  end
  if self.Btn_HandBook then
    self.Btn_HandBook:ShowOrHidePCKey(false)
  end
  if self.Btn_Task then
    self.Btn_Task:ShowOrHidePCKey(false)
  end
  if self.Btn_Pet then
    self.Btn_Pet:ShowOrHidePCKey(false)
  end
  if self.Btn_FurnitureAtlas_1 then
    self.Btn_FurnitureAtlas_1:ShowOrHidePCKey(false)
  end
  if self.Btn_Decoration_1 then
    self.Btn_Decoration_1:ShowOrHidePCKey(false)
  end
  if self.Btn_Set then
    self.Btn_Set:ShowOrHidePCKey(false)
  end
  if self.Btn_friends then
    self.Btn_friends:ShowOrHidePCKey(false)
  end
end

function UMG_CompassIcon_C:OnQuickChatClose()
  if self.Text_PCKey and self._cachedTextPCKeyVisible then
    self.Text_PCKey:SetKeyVisibility(true)
  end
  if self.Text_PCKey_1 and self._cachedTextPCKey1Visible then
    self.Text_PCKey_1:SetKeyVisibility(true)
  end
  if self.Btn_Activity and self._cachedBtnActivityVisible then
    self.Btn_Activity:ShowOrHidePCKey(true)
  end
  if self.Btn_SeasonIntegration and self._cachedBtnSeasonIntegrationVisible then
    self.Btn_SeasonIntegration:ShowOrHidePCKey(true)
  end
  if self.Btn_MagicManua and self._cachedBtnMagicManuaVisible then
    self.Btn_MagicManua:ShowOrHidePCKey(true)
  end
  if self.Btn_HandBook and self._cachedBtnHandBookVisible then
    self.Btn_HandBook:ShowOrHidePCKey(true)
  end
  if self.Btn_Task and self._cachedBtnTaskVisible then
    self.Btn_Task:ShowOrHidePCKey(true)
  end
  if self.Btn_Pet and self._cachedBtnPetVisible then
    self.Btn_Pet:ShowOrHidePCKey(true)
  end
  if self.Btn_FurnitureAtlas_1 and self._cachedBtnFurnitureAtlas1Visible then
    self.Btn_FurnitureAtlas_1:ShowOrHidePCKey(true)
  end
  if self.Btn_Decoration_1 and self._cachedBtnDecoration1Visible then
    self.Btn_Decoration_1:ShowOrHidePCKey(true)
  end
  if self.Btn_Set and self._cachedBtnSetVisible then
    self.Btn_Set:ShowOrHidePCKey(true)
  end
  if self.Btn_friends and self._cachedBtnFriendsVisible then
    self.Btn_friends:ShowOrHidePCKey(true)
  end
end

function UMG_CompassIcon_C:OnSeasonInfoChange()
  self:SetSeasonIntegrationIcon()
end

function UMG_CompassIcon_C:InitStarlight(bReconnect)
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if not bReconnect and data and data.PlayerStarInfo and data.IncrementStarlight then
    self:UpdateStarlight(data.PlayerStarInfo, data.IncrementStarlight)
  else
    local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
    if PlayerInfo then
      if PlayerInfo.star_light_info then
        _G.NRCEventCenter:DispatchEvent(WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_INIT, PlayerInfo.star_light_info)
        self:UpdateStarlight(PlayerInfo.star_light_info)
      else
        self:UpdateStarlight(nil, nil)
      end
    end
  end
end

function UMG_CompassIcon_C:UpdateStarlight(InStarlightInfo, IncrementStarlight, index)
  self.Rise:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NrcRedPoint_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if InStarlightInfo and nil == IncrementStarlight or 0 == IncrementStarlight then
    self:InitStarlightUI(InStarlightInfo)
  end
  if InStarlightInfo and next(InStarlightInfo) then
    local efficiency = InStarlightInfo.current_efficiency or 1
    if efficiency then
      local wishExchangeConf = _G.DataConfigManager:GetWishExchangeConf(efficiency)
      if wishExchangeConf then
        local path = wishExchangeConf.icon
        if path and "" ~= path then
          self.Rise:SetPath(path)
          self.Rise:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
  end
  if self.isEnable and self.isLeaveLoading then
    if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() then
      if IncrementStarlight and 0 == IncrementStarlight then
        local text = _G.DataConfigManager:GetLocalizationConf("wish_exchange_daily_refresh").msg
        self.DescriptionStarlight:SetText(text)
        self:PlayAnimation(self.StarlightAlert__Animation)
      elseif IncrementStarlight and IncrementStarlight > 0 then
        self:OnStarlightChange(InStarlightInfo, IncrementStarlight)
      end
      self:MarkUsedStarlightInfo(IncrementStarlight, index)
    else
      self:MarkUsedStarlightInfo()
    end
  end
end

function UMG_CompassIcon_C:CheckNeedtoShowStarInfoChange(bNotNeedAdd)
  if self:IsAnimationPlaying(self.StarlightBonus_Animation) or self:IsAnimationPlaying(self.StarlightAlert__Animation) then
    return
  end
  if not (self.isEnable and self.isLeaveLoading) or self.bEnterTakePhotos then
    return
  end
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data then
    data:RemoveUsedStarlightInfo()
    if data.StarlightInfoList then
      local starlightInfo = {}
      starlightInfo.IncrementStarlight = nil
      local index = {}
      for i, info in pairs(data.StarlightInfoList) do
        if info.Unlock then
          if info.IncrementStarlight and 0 == info.IncrementStarlight then
            self:UpdateStarlight(info.PlayerStarInfo, info.IncrementStarlight)
            return
          elseif info.IncrementStarlight and info.IncrementStarlight > 0 then
            starlightInfo.PlayerStarInfo = info.PlayerStarInfo
            if starlightInfo.IncrementStarlight == nil then
              starlightInfo.IncrementStarlight = 0
            end
            starlightInfo.IncrementStarlight = starlightInfo.IncrementStarlight + info.IncrementStarlight
            table.insert(index, i)
          end
          if bNotNeedAdd then
            break
          end
        end
      end
      if starlightInfo.PlayerStarInfo and starlightInfo.IncrementStarlight then
        self:UpdateStarlight(starlightInfo.PlayerStarInfo, starlightInfo.IncrementStarlight, index)
      end
    end
  end
end

function UMG_CompassIcon_C:MarkUsedStarlightInfo(IncrementStarlight, index)
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data then
    for i, info in pairs(data.StarlightInfoList or {}) do
      if not info.MarkUsed and info.Unlock then
        if nil == IncrementStarlight then
          info.MarkUsed = true
          break
        elseif 0 == IncrementStarlight then
          if 0 == info.IncrementStarlight then
            info.MarkUsed = true
            break
          end
        elseif 0 ~= info.IncrementStarlight then
          if index and #index > 0 then
            for _, v in pairs(index or {}) do
              if i == v then
                info.MarkUsed = true
                break
              end
            end
          else
            info.MarkUsed = true
          end
        end
      end
    end
  end
end

function UMG_CompassIcon_C:InitStarlightUI(InStarlightInfo)
  if InStarlightInfo and self.ProgressBar_46 and self.ProgressBar1 then
    if InStarlightInfo.unexchange_wishing_star_num and InStarlightInfo.unexchange_wishing_star_num > 0 then
      self:StopAllAnimations()
      self.ProgressBar_46:SetPercent(1)
      self.ProgressBar1:SetPercent(1)
      self.ProgressBar_46:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ProgressBar1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.LuoPan_Full, 0, 0)
    elseif InStarlightInfo.current_progress and InStarlightInfo.current_progress >= 0 then
      self:StopAllAnimations()
      self.ProgressBar_46:SetPercent(InStarlightInfo.current_progress / 10000)
      self.ProgressBar1:SetPercent(InStarlightInfo.current_progress / 10000)
      self.ProgressBar_46:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ProgressBar1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.LuoPan_Normal, 0, 0)
    end
  end
end

function UMG_CompassIcon_C:OnStarlightChange(InStarlightInfo, IncrementStarlight)
  self:PlayStarlightChangeAnim(InStarlightInfo, IncrementStarlight)
  self:PlayStarlightChangeSkill()
end

function UMG_CompassIcon_C:PlayStarlightChangeAnim(InStarlightInfo, IncrementStarlight)
  if self.ProgressBar_46 and self.ProgressBar1 then
    self.ProgressBar_46:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ProgressBar1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if InStarlightInfo.unexchange_wishing_star_num and InStarlightInfo.unexchange_wishing_star_num > 0 then
      local curPercent = self.ProgressBar_46.Percent
      if curPercent >= 1 then
        self.ProgressBar_46:SetPercent(1)
        self.ProgressBar1:SetPercent(1)
      else
        local animEndTime = self.LuoPan_Add:GetEndTime()
        self:StopAllAnimations()
        self:PlayAnimationTimeRange(self.LuoPan_Add, curPercent * animEndTime, animEndTime)
      end
    elseif InStarlightInfo.current_progress then
      local curPercent = self.ProgressBar_46.Percent
      local newPercent = InStarlightInfo.current_progress / 10000
      local animEndTime = self.LuoPan_Add:GetEndTime()
      self:StopAllAnimations()
      self:PlayAnimationTimeRange(self.LuoPan_Add, curPercent * animEndTime, newPercent * animEndTime)
    end
  end
  self.DescriptionStarlight_1:SetText(string.format("+%d", IncrementStarlight))
  self.ParticleSystemWidget2_85:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.StarlightBonus_Animation)
end

function UMG_CompassIcon_C:PlayStarlightChangeSkill()
  _G.NRCEventCenter:DispatchEvent(WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_ON_STARLIGHT_CHANGE)
end

function UMG_CompassIcon_C:OnEnterLoading()
  self.isLeaveLoading = false
end

function UMG_CompassIcon_C:OnLeaveLoading()
  self.isLeaveLoading = true
  self:CheckNeedtoShowStarInfoChange()
end

return UMG_CompassIcon_C
