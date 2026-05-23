local JsonUtils = require("Common.JsonUtils")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
_G.MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local WorldCombatModuleEvent = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEvent")
local OnlineModuleEvent = require("NewRoco.Modules.Core.Online.OnlineModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local BagModuleEnum = require("NewRoco.Modules.System.Bag.BagModuleEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local WishCrystalModuleEvent = require("NewRoco.Modules.System.WishCrystal.WishCrystalModuleEvent")
local PriorityEnum = require("PriorityEnum")
local WidgetPerformanceTier = require("NewRoco.Modules.System.TUI.WidgetPerformanceTier")
local _JoystickConfigFilename = "NrcJoystickConfig"
local CommonUtils = require("NewRoco.Utils.CommonUtils")
local MainPanelMgr = require("NewRoco.Modules.System.MainUI.MainPanelMgr")
local TipUtils = require("NewRoco.Modules.System.TipsModule.Utils.TipUtils")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local MainUIModule = NRCModuleBase:Extend("MainUIModule")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")

function MainUIModule:OnConstruct()
  _G.MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
  _G.MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
  self.autoAimDir = UE4.FVector()
  self.curSelectedPetGid = 0
  self.selectedItemId = 0
  self.ReqItemType = 0
  self.ReqItemGid = 0
  self.SelectPetIndex = 0
  self.PetData = nil
  self.bAiming = false
  self.TickInterval = 0
  self.showNpcLvList = nil
  self.InnerPanelTickInterval = 0
  self.LobbyMainInnerClosing = false
  self.LT = UE4.FVector2D()
  self.RB = UE4.FVector2D()
  self.wndCenterPos = UE4.FVector2D()
  self.LongPressPetIndex = nil
  self.SelectLongPressPetIndex = 0
  self.switcherIndex = 0
  self.CurrentVitra = 0
  self.LastThroowSelectInfo = nil
  self.CurThroowSelectInfo = nil
  local joystickConfig = JsonUtils.LoadSaved(_JoystickConfigFilename, {})
  if joystickConfig.IsLockedJoystick == true or false == joystickConfig.IsLockedJoystick then
    self.IsLockMoveJoystick = joystickConfig.IsLockedJoystick
  else
    self.IsLockMoveJoystick = true
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  self.IsFreedomPropPlaceMode = joystickConfig.bIsFreedomModeMap and joystickConfig.bIsFreedomModeMap[tostring(uin)] or false
  self.NeedDisableLobbyMainPopupList = {}
  self.lockPetLandPos = UE4.FVector(0, 0, 0)
  self.threeFingerPos = {
    UE4.FVector2D(0, 0),
    UE4.FVector2D(0, 0),
    UE4.FVector2D(0, 0)
  }
  self.bBattleHidePanel = false
  self.threeFingerPanelVisible = true
  self.showPetLvMaxNum = _G.DataConfigManager:GetPetGlobalConfig("pet_level_show_num_max").num
  self.bGlobalPetHUDEnabled = true
  self.FollowDataCache = nil
  self.NewFollowDataCache = nil
end

function MainUIModule:GetCurMainPanel()
  return self.MainPanelMgr:GetCurMainUI()
end

function MainUIModule:HasAnyMainUIOpened()
  return self.MainPanelMgr:HasAnyMainUIOpened()
end

function MainUIModule:HasAnyMainUIShowing()
  return self.MainPanelMgr:HasAnyMainUIShowing()
end

function MainUIModule:OnActive()
  self.MainPanelMgr = MainPanelMgr(self)
  self:RegPanel("LobbyMain", "UMG_LobbyMain", Enum.UILayerType.UI_LAYER_MAIN, nil, 4)
  self:RegPanel("LobbyMainLocal", "Ability/UMG_LocalUI", Enum.UILayerType.UI_LAYER_MAIN, nil, 4)
  self:RegPanel("TemperatureHot", "Tempreture/UMG_Tempreture_Hot", Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("TemperatureCold", "Tempreture/UMG_Tempreture_Cold", Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("LobbyMainInner", "UMG_LobbyMainInner", Enum.UILayerType.UI_LAYER_DIALOGUE, true, 1, true)
  self:RegPanel("LobbyMainInnerBlackScreen", "UMG_LobbyMainInnerBlackScreen", Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("LobbyMainInnerNormalBlackScreen", "UMG_LobbyMainInnerBlackScreen_Normal", Enum.UILayerType.UI_LAYER_TOP_LOADING)
  self:RegPanel("AppearanceRolePlay", "UMG_Appearance", Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("CompassUnlockTips", "compass/UMG_CompassUnLockTips", Enum.UILayerType.UI_LAYER_MAIN)
  self:RegPanel("UnlockGuidBook", "UMG_BigManual_Cover", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LobbyPropTips", "UMG_LobbyPropTips", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("LobbyDownTips", "UMG_LobbyDownTips", Enum.UILayerType.UI_LAYER_TOP, nil, nil, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("HUDSimpleList", "UMG_HUDSimpleList", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel_1("AdditionalTarget", "/Game/NewRoco/Modules/System/Common/res/UMG_AdditionalTargetCombat", Enum.UILayerType.UI_LAYER_BG, nil, nil, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("UMG_LeftBottomFunctionEntry", "UMG_LeftBottomFunctionEntry", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("SimpleUseList", "UMG_SimpleUseList", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PartnerAndPeer", "UMG_PartnerAndPeer", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("CreateMagicMessage", "UMG_CreateMagicMessage", Enum.UILayerType.UI_LAYER_POPUP, nil, 1, true, true)
  self:RegPanel("ShowMagicMessage", "UMG_ShowMagicMessage", Enum.UILayerType.UI_LAYER_POPUP, nil, 1, true, true)
  self:RegPanel("MagicMessageCommentPopUp", "UMG_MagicMessageCommentPopUp", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ShowFakeMagicMessage", "UMG_ShowMagicMessage_Fake", Enum.UILayerType.UI_LAYER_POPUP, nil, 1, true, true)
  self:RegPanel("MagicMessageMusicToolbar", "UMG_MusicToolbar", Enum.UILayerType.UI_LAYER_MAIN, nil, nil, nil, false)
  self:RegPanel_1("WaitTogetherPanel", "/Game/NewRoco/Modules/System/BattleUI/Res/BattleUIItem/UMG_Battle_WaitingTeammatesCountdown", Enum.UILayerType.UI_LAYER_GLOBAL_BLACK, nil, 1, true, nil)
  self:RegPanel("PrivilegeIntroductionPopUp", "UMG_Privilege_IntroductionPopUp", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("MyTeamPanel", "UMG_MyTeamPanel", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PropPlacementPanel", "Ability/UMG_PropPlacement", Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("UMG_GvoiceTips", "UMG_GvoiceTips", Enum.UILayerType.UI_LAYER_TOP)
  self:RegUMGNPCInteractMainPanel()
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, SceneEvent.OnPlayerReborn, self.OnPlayerReborn)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.DeadClosePanelWithBlock)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.RebornShowPanelWithBlock)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, SceneEvent.PlayerBornFinish, self.OnMapLoaded)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.RefreshMainPet)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.OnInVisible, self.OnInVisible)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReconnectStar)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.OnLobbyMainInnerOpened, self.OnLobbyMainInnerOpened)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnLobbyMainInnerClosed)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.AfterEnterScene)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, NPCModuleEvent.WorldCombatBoxVisible, self.OnWorldCombatBoxVisible)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, NPCModuleEvent.WorldCombatBoxInvisible, self.OnWorldCombatBoxInvisible)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.OnBarrierShow, self.OpenAdditionalTarget)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_INFO_UPDATE, self.OnStarligthInfoUpdate)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_EXCHANGE, self.OnStarligthExchange)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, MainUIModuleEvent.UI_BeginThrowChangeTeam, self.OnBeginTrowRsp)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnStoryFlagChange)
  self.player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.playerController = self.player:GetUEController()
  self:GetAimRectRange()
  self.LobbyDownTipsController = TipUtils.CreteTipsDisplayController(TipEnum.TipObjectType.LobbyDownTips, self, self.OnCmdOpenLobbyDownTips)
  self.LobbyDownTipsController:GetExecutor():EnableTipSort(function(a, b)
    return a.type < b.type
  end)
  self.MainPetTipsController = TipUtils.CreteTipsDisplayController(TipEnum.TipObjectType.MainPetTips)
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if LocalPlayer then
    LocalPlayer:AddEventListener(self, PlayerModuleEvent.ON_BODY_TEMP_CHANGED, self.OnBodyTempChange)
  end
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_SELECTED_THROW_ITEM_NOTIFY, self.CheckRefreshThrowItemInfo)
  do
    local allAbilityConf = _G.DataConfigManager:GetAllByName("SCENE_ABILITY_CONF")
    if allAbilityConf then
      for _, abilityConf in pairs(allAbilityConf) do
        if not string.IsNilOrEmpty(abilityConf.ability_icon) then
          _G.NRCResourceManager:LoadResAsync(nil, abilityConf.ability_icon, PriorityEnum.UI_PreCache_Image, math.maxinteger)
        end
      end
    end
    local allRideUIConf = _G.DataConfigManager:GetAllByName("ALL_RIDE_UI_CONF")
    if allRideUIConf then
      for _, rideUIConf in pairs(allRideUIConf) do
        if not string.IsNilOrEmpty(rideUIConf.off_button_icon) then
          _G.NRCResourceManager:LoadResAsync(nil, rideUIConf.off_button_icon, PriorityEnum.UI_PreCache_Image, math.maxinteger)
        end
      end
    end
  end
  self:TryShowGameMatrixTips()
  self:OnCmdOpenPermissionTips("")
  _G.NRCPanelManager:InitAllUmgStaticConfig()
end

function MainUIModule:OnCmdShowPermissionTips(bShow, tips)
  Log.Debug("MainUIModule:OnCmdShowPermissionTips", bShow)
  if self:HasPanel("UMG_GvoiceTips") then
    local panel = self:GetPanel("UMG_GvoiceTips")
    panel:ShowTips(bShow, tips)
  else
    Log.Debug("MainUIModule:OnCmdShowPermissionTips", "UMG_GvoiceTips not found")
  end
end

function MainUIModule:OnSelectRidePetToThrow_ChangePetTeam(SelectThrowPetGid)
  if SelectThrowPetGid then
    self.SelectThrowPetGid = SelectThrowPetGid
    local isMainTeamIndex, teamIndex = _G.DataModelMgr.PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(self.SelectThrowPetGid)
    if isMainTeamIndex then
      return
    end
    local req = _G.ProtoMessage:newZonePetChangeMainTeamReq()
    req.main_team_idx = teamIndex
    req.team_type = _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_CHANGE_MAIN_TEAM_REQ, req, self, self.OnChangePetMainTeam)
  end
end

function MainUIModule:OnChangePetMainTeam(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local teamInfo = _rsp.ret_info.goods_change_info.changes
    if teamInfo and #teamInfo > 0 then
      for k, changeItem in ipairs(teamInfo) do
        if changeItem.src_type == ProtoEnum.GoodsType.GT_TEAMINFO then
          _G.DataModelMgr.PlayerDataModel:SetPlayerBigWorldPetTeamMainIndex(changeItem.team_info.main_team_idx)
          local gid = self.SelectThrowPetGid
          local index, petData = _G.DataModelMgr.PlayerDataModel:GetPetDataAndTeamIndexByGid(gid)
          _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.PET_TEAM_CHANGE)
          local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
          _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, index, petData)
          _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, index)
          _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList, true)
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, petData.gid)
        end
      end
    end
  end
  self.SelectThrowPetGid = nil
end

function MainUIModule:OnCmdTestShowPermissionTips()
  UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.RecordAudio, {
    self,
    function(_, bGranted)
      Log.Debug("MainUIModule:OnCmdTestShowPermissionTips", bGranted)
    end
  })
end

function MainUIModule:OnCmdOpenPermissionTips(tips)
  Log.Debug("MainUIModule:OpenPermisssionTips", tips)
  if self:HasPanel("UMG_GvoiceTips") then
    self:ClosePanel("UMG_GvoiceTips")
    self:OpenPanel("UMG_GvoiceTips", tips)
  else
    self:OpenPanel("UMG_GvoiceTips", tips)
  end
end

function MainUIModule:OnCmdClosePermissionTips()
  Log.Debug("MainUIModule:ClosePermisssionTips")
  if self:HasPanel("UMG_GvoiceTips") then
    self:ClosePanel("UMG_GvoiceTips")
  end
end

function MainUIModule:OnBodyTempChange(bt, diffTime, btFinal)
  if _G.AppMain:HasDebug() then
    _G.NRCModeManager:DoCmd(DebugModuleCmd.SetTemperature, bt, diffTime, btFinal)
  end
end

function MainUIModule:OnBeginTrowRsp(ThrowSession, rsp)
  local change_Team = rsp.change_team
  if change_Team and change_Team.main_team_idx and change_Team.team_type == Enum.PlayerTeamType.PTT_BIG_WORLD then
    _G.DataModelMgr.PlayerDataModel:SetPlayerBigWorldPetTeamMainIndex(change_Team.main_team_idx)
    _G.DataModelMgr.PlayerDataModel:OnPetMainTeamChanged(change_Team.main_team_idx)
    local gid = ThrowSession:GetGID()
    local index, petData = _G.DataModelMgr.PlayerDataModel:GetPetDataAndTeamIndexByGid(gid)
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.PET_TEAM_CHANGE)
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, index, petData)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, index)
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList, true)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, petData.gid)
  end
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.Switcher.Slot:SetZOrder(0)
    panel.UMG_MainPet:UpdateThrowPetCanClick(false)
    panel.MainPetScrollList:UpdateThrowPetCanClick(false)
    panel.Switcher:SetActiveWidgetIndex(0)
  end
end

function MainUIModule:OpenInteractMain()
  if not self:HasPanel("NPCInteractMain") then
    self:OpenPanel("NPCInteractMain")
  end
end

function MainUIModule:CmdOpenMyTeamPanel()
  self:OpenPanel("MyTeamPanel")
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:ShowOrCloseMainPet(false)
  end
end

function MainUIModule:CmdCloseMyTeamPanel()
  if self:HasPanel("MyTeamPanel") then
    self:ClosePanel("MyTeamPanel")
  end
end

function MainUIModule:CloseInteractMain()
  self:ClosePanel("NPCInteractMain")
end

function MainUIModule:DoCmdOpenHUDSimpleList(Type)
  local isOpening, _ = self:HasPanel("HUDSimpleList")
  if isOpening then
    local panel = self:GetPanel("HUDSimpleList")
    panel:SetListInfo(Type)
    if panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    else
      self:EnablePanel("HUDSimpleList")
    end
  else
    self:OpenPanel("HUDSimpleList", Type)
  end
end

function MainUIModule:DoCmdCloseHUDSimpleList()
  if self:HasPanel("HUDSimpleList") then
    local panel = self:GetPanel("HUDSimpleList")
    if panel.enableView then
      panel:ClosePanel()
    end
  end
end

function MainUIModule:DoCmdInitHUDSimpleList(Type)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.UMG_HUDSimpleList:SetListInfo(Type)
  end
  self:DoCmdCloseSimpleUseList()
end

function MainUIModule:DoCmdSwitchPetOrMagic(index, success)
  Log.Debug(self.switcherIndex, index, "MainUIModule:DoCmdSwitchPetOrMagic")
  if self.switcherIndex ~= index then
    self.switcherIndex = index
  else
    return
  end
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if index then
      if 1 == index then
        panel.Switcher:SetActiveWidgetIndex(index)
        panel.UMG_HUDSimpleList:PlayAnimation(panel.UMG_HUDSimpleList.open)
      elseif 0 == index then
        panel.UMG_LockMagic:OnCancel(1)
        panel.UMG_HUDSimpleList:StopAllAnimations()
        panel.BallList:ClosePanel()
        if 3 == panel.Switcher:GetActiveWidgetIndex() and not success then
          panel.Switcher:SetActiveWidgetIndex(0)
          panel.Switcher.Slot:SetZOrder(0)
          panel.UMG_MainPet:UpdateThrowPetCanClick(false)
          panel.MainPetScrollList:UpdateThrowPetCanClick(false)
          panel.MainPetScrollList:InitPanelInfo(true, nil, true)
        elseif 3 ~= panel.Switcher:GetActiveWidgetIndex() then
          panel.Switcher.Slot:SetZOrder(0)
          panel.UMG_HUDSimpleList:PlayAnimation(panel.UMG_HUDSimpleList.close)
        end
      elseif 2 == index then
        panel.Switcher:SetActiveWidgetIndex(index)
      elseif 3 == index then
        panel.Switcher.Slot:SetZOrder(2)
        panel.Switcher:SetActiveWidgetIndex(index)
        panel.UMG_MainPet:UpdateThrowPetCanClick(true)
        panel.MainPetScrollList:UpdateThrowPetCanClick(true)
      end
    end
  end
end

function MainUIModule:DoCmdCancelLockMagic()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.UMG_LockMagic:OnCancel(1)
  end
end

function MainUIModule:DoCmdResetMainPetProgress()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    for i = 1, panel.UMG_MainPet.MainPetList:GetItemCount() do
      local item = panel.UMG_MainPet.MainPetList:GetItemByIndex(i - 1)
      item.Progress.CircleFillImage_77:SetFillAmount(0)
      item.Progress:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function MainUIModule:DoCmdGetMainPetListVisibility()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel.UMG_MainPet and panel.UMG_MainPet.MainPetList then
      return panel.UMG_MainPet.MainPetList:GetVisibility()
    end
  end
  return UE4.ESlateVisibility.Collapsed
end

function MainUIModule:DoCmdSwitchPetAfterAnim()
  if self:HasPanel("LobbyMain") then
    Log.Debug(self.switcherIndex, "MainUIModule:DoCmdSwitchPetAfterAnim")
    local panel = self:GetPanel("LobbyMain")
    panel.Switcher:SetActiveWidgetIndex(0)
    panel.UMG_MainPet:UpdateThrowPetCanClick(false)
    panel.MainPetScrollList:UpdateThrowPetCanClick(false)
  end
end

function MainUIModule:DoCmdSetCurrentVitra(value)
  self.CurrentVitra = value
end

function MainUIModule:DoCmdGetCurrentVitra()
  return self.CurrentVitra
end

function MainUIModule:OnCmdGetLobbyMainEnableState()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    return panel.enableView
  end
  return false
end

function MainUIModule:OnCmdGetLobbyMainPanelOpen()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    return panel.PanelOpen
  end
  return false
end

function MainUIModule:OnInVisible()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:OnInVisible()
  end
end

function MainUIModule:OnCmdOpenOrCloseMainUIDownTips(_bOpen, _Reason)
  self:OnCmdIsShowDownTips(_bOpen, _Reason)
end

function MainUIModule:OnPlayerDead()
  self:OnCmdIsShowDownTips(false, "OnPlayerDead")
end

function MainUIModule:OnPlayerReborn(Reason)
  self:OnCmdIsShowDownTips(true, "OnPlayerDead")
end

function MainUIModule:OnWorldCombatEnter()
  self:OnCmdIsShowDownTips(false, "OnWorldCombatEnter")
end

function MainUIModule:OnWorldCombatExit()
  self:OnCmdIsShowDownTips(true, "OnWorldCombatEnter")
end

function MainUIModule:DeadClosePanelWithBlock(bIsBlockPCInput)
  if bIsBlockPCInput then
    self:AddPcInputBlock()
  end
end

function MainUIModule:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self)
end

function MainUIModule:RebornShowPanelWithBlock(bIsBlockPCInput)
  if not bIsBlockPCInput then
    self:RemovePcInputBlock()
  end
end

function MainUIModule:OnMapLoaded()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.playerController = self.player:GetUEController()
end

function MainUIModule:OnMiniMapTimeSync(TimeSync)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:MiniMapTimeSync(TimeSync.game_time)
  end
end

function MainUIModule:SetMainUICanCache(CanCache)
  if self.delayRefreshMainUIId then
    _G.DelayManager:CancelDelayById(self.delayRefreshMainUIId)
    self.delayRefreshMainUIId = nil
  end
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.InvalidationBox_0:SetCanCache(CanCache)
    panel.InvalidationBox_0:InvalidateLayoutAndVolatility()
  end
end

function MainUIModule:RefreshMainUICache()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.InvalidationBox_0:SetCanCache(false)
    panel.InvalidationBox_0:InvalidateLayoutAndVolatility()
    if self.delayRefreshMainUIId then
      _G.DelayManager:CancelDelayById(self.delayRefreshMainUIId)
      self.delayRefreshMainUIId = nil
    end
    self.delayRefreshMainUIId = _G.DelayManager:DelayFrames(2, function()
      panel.InvalidationBox_0:SetCanCache(true)
      panel.InvalidationBox_0:InvalidateLayoutAndVolatility()
    end)
  end
end

function MainUIModule:RefreshMainPet()
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  self:DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
end

function MainUIModule:RegisterNPCFinder()
  _G.NRCModuleManager:DoCmd(NPCModuleCmd.RegisterTopKFinder, self, 1, self, self.ConstValidFunc, self, self.AdjustValidFunc, self, self.CompareFunc, self, self.ChangeToValid, self, self.ChangeToInValid)
end

function MainUIModule:UnRegisterNPCFinder()
  _G.NRCModuleManager:DoCmd(NPCModuleCmd.UnRegisterTopKFinder, self)
end

function MainUIModule:GetAutoAimDirection()
  return self.autoAimDir
end

function MainUIModule:OnCmdOnClickMainTeamBtn(_index)
  self:DispatchEvent(PetUIModuleEvent.OnClickSetMainTeam, _index)
end

function MainUIModule:OnCmdShowCenterRedCross()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:ShowCenterRedCross()
  end
end

function MainUIModule:GetAutoAimNPC()
  local npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetTopKNPC, self)
  if npcs and type(npcs) == "table" and #npcs > 0 then
    if self.selectedItemId > 0 then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.selectedItemId)
      if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
        local ballActConf = _G.DataConfigManager:GetBallAct(self.selectedItemId)
        if ballActConf.Max_Auto_Find_Target_Distance > 0 then
          return npcs[1]
        else
          return nil
        end
      end
    else
      return npcs[1]
    end
  else
    return nil
  end
end

local function ExtractVersionStrNumbers(inputVerString)
  local numbers = table.new(4, 0)
  if inputVerString then
    for num in string.gmatch(inputVerString, "([^%.]+)") do
      table.insert(numbers, tonumber(num))
    end
  end
  return numbers
end

function MainUIModule:OnCmdGetMoreInnerBottomList()
  if not self.ShowMoreInnerTable then
    self.ShowMoreInnerTable = {}
    local PrivilegePanelConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PLATFORM_PRIVILEGES)
    if PrivilegePanelConf then
      local PrivilegePanelData = PrivilegePanelConf:GetAllDatas()
      for k, v in pairs(PrivilegePanelData) do
        if 0 ~= v.system_control_rule_id then
          local IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, v.system_control_rule_id, false)
          if not IsBan then
            table.insert(self.ShowMoreInnerTable, v)
          end
        else
          table.insert(self.ShowMoreInnerTable, v)
        end
      end
    else
      Log.Error("\233\133\141\231\189\174\232\161\168\228\184\141\229\173\152\229\156\168,\230\159\165\231\156\139\229\142\159\229\155\160 RELATIONTREE_CONF")
      return
    end
    table.sort(self.ShowMoreInnerTable, function(a, b)
      if a.rank_id ~= b.rank_id then
        return a.rank_id > b.rank_id
      else
        return a.id > b.id
      end
    end)
  end
  return self.ShowMoreInnerTable
end

function MainUIModule:UpdateSafeZone(isSaveZone)
  Log.Debug("MainUIModule:UpdateSafeZone")
  if not self:HasPanel("LobbyMain") then
    Log.Debug("MainUIModule:UpdateSafeZone no panel")
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:OnGameSecureAreaChanage(isSaveZone)
end

function MainUIModule:OpenUnlockGuidBook(_GuidBookData)
  Log.Debug("MainUIModule:OpenUnlockGuidBook")
  if self:HasPanel("UnlockGuidBook") then
    local panel = self:GetPanel("UnlockGuidBook")
    panel:UpdateGuidBook(_GuidBookData)
  else
    self:OpenPanel("UnlockGuidBook", _GuidBookData)
  end
end

function MainUIModule:OnCmdPlayRewardTips(Data)
  local panel = self:GetPanel("LobbyMain")
  if panel and panel.UMG_LobbyPropTips then
    panel.UMG_LobbyPropTips:PlayTips(Data)
  end
end

function MainUIModule:SetRewardTipsEnabled(bEnable, Reason)
  local panel = self:GetPanel("LobbyMain")
  if panel and panel.UMG_LobbyPropTips then
    panel.UMG_LobbyPropTips:SetTipsEnabled(bEnable, Reason)
  end
end

function MainUIModule:OnCmdGetPropTipsSizeY()
  local panel = self:GetPanel("LobbyMain")
  return panel:GetPropTipsSizeY()
end

function MainUIModule:IsNeedShowPropTips()
  return not self.LobbyPropTipsVisibilityBanReasons or not next(self.LobbyPropTipsVisibilityBanReasons)
end

function MainUIModule:OnCmdIsShowPropTips(_IsShow, Reason)
  Reason = Reason or "Default"
  if not self.LobbyPropTipsVisibilityBanReasons then
    self.LobbyPropTipsVisibilityBanReasons = {}
  end
  if _IsShow then
    self.LobbyPropTipsVisibilityBanReasons[Reason] = nil
  else
    self.LobbyPropTipsVisibilityBanReasons[Reason] = true
  end
  local bDesiredShow = self:IsNeedShowPropTips()
  Log.Trace("MainUITips OnCmdIsShowPropTips", _IsShow, Reason, bDesiredShow)
  if not bDesiredShow then
    for r, v in pairs(self.LobbyPropTipsVisibilityBanReasons) do
      Log.Debug("MainUITips LobbyPropTips has banned by", r)
    end
  end
  local HasPanel = self:HasPanel("LobbyPropTips")
  if HasPanel then
    local Panel = self:GetPanel("LobbyPropTips")
    Panel:IsShowPanel(bDesiredShow)
  end
end

function MainUIModule:OnCmdTipsDisplayTipShow(On)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:TipShowOrHide(On)
    end
  end
end

function MainUIModule:OnCmdUpdateVisitListInfo()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel.UMG_Compass:UpdateVisitIcons()
    end
  end
end

function MainUIModule:OnCmdIsShowDownTips(_IsShow, Reason)
  if not Reason then
    Log.Error("MainUITips OnCmdIsShowDownTips. Reason is nil")
    return
  end
  Log.Debug("MainUITips OnCmdIsShowDownTips", _IsShow, Reason)
  if self.LobbyDownTipsController then
    if not _IsShow then
      self.LobbyDownTipsController:GetExecutor():Pause(Reason)
    else
      self.LobbyDownTipsController:GetExecutor():Resume(Reason)
    end
  end
end

function MainUIModule:OnCmdOpenLobbyDownTips()
  if not self:HasPanel("LobbyDownTips") then
    self:OpenPanel("LobbyDownTips")
  end
end

function MainUIModule:OnCmdOpenMainUIDownTips(TipsType, TipsData, CmdID)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil ~= player then
    local tipsInfo = {}
    tipsInfo.TipsType = TipsType
    tipsInfo.TipsData = TipsData
    tipsInfo.CmdID = CmdID
    if player.AddLobbyDownTipsEffect then
      player:AddLobbyDownTipsEffect(tipsInfo)
    end
  end
end

function MainUIModule:AddUIUnlockToQueue(UnlockData)
end

function MainUIModule:OnCmdOpenPetEvolutionPage()
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {subPanelIndex = 4, subMenuIndex = 2})
end

function MainUIModule:OnCmdOpenPetLevelUpPage()
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    subMenuIndex = 1,
    showLevelUpPanel = true
  })
end

function MainUIModule:OnCmdOpenPetFormationUI()
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.PetFormationUILoadFinished,
    caller = self
  }, nil, nil, true)
end

function MainUIModule:OnOpenPetBagUI()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetBag, true)
end

function MainUIModule:PetFormationUILoadFinished()
end

function MainUIModule:OnCmdUpdateMiniMapNpcInfo(npcInfos, mapAreaInfos)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
    if bigMapModule then
      panel.UMG_Compass:PreUpdateNpcInfo(bigMapModule.data:GetNpcDatas(panel.UMG_Compass.CurSceneResID))
    end
    panel.UMG_Compass:PreUpdateMapAreaInfo(mapAreaInfos)
  end
end

function MainUIModule:OnCmdUpdateMiniMapAll()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    panel.UMG_Compass:UpdateNpc()
  end
  local compassIcon = panel.UMG_CompassIcon
  if panel.UMG_CompassIcon and compassIcon.UMG_Minimap and compassIcon.isContruct and not compassIcon.isDestruct then
    compassIcon.UMG_Minimap:UpdateNpcInfo()
  end
end

function MainUIModule:OnCmdUpdateMiniMapTraceNpcState()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    panel.UMG_Compass:UpdateTraceNpc()
  end
  local compassIcon = panel.UMG_CompassIcon
  if panel.UMG_CompassIcon and compassIcon.UMG_Minimap and compassIcon.isContruct and not compassIcon.isDestruct then
    compassIcon.UMG_Minimap:UpdateTraceNpc()
  end
end

function MainUIModule:OnCmdUpdateMiniMapMarkInfo(markInfo, IsPlayRemoveSound)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if IsPlayRemoveSound then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1363, "UMG_BuildingSettlement_C:OnActive")
  end
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    panel.UMG_Compass:UpdateMarkInfo(markInfo)
  end
  local compassIcon = panel.UMG_CompassIcon
  if panel.UMG_CompassIcon and compassIcon.UMG_Minimap and compassIcon.isContruct and not compassIcon.isDestruct then
    compassIcon.UMG_Minimap:ClearMarkerIcon()
  end
end

function MainUIModule:GetHasNPCInteractMainPanel()
  if self:HasPanel("NPCInteractMain") then
    return true
  end
  return false
end

function MainUIModule:UseMainUIChatBubbleParent()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:UseMainUIChatBubbleParent()
  end
  return nil
end

function MainUIModule:AddNPCInteract(option)
  if not self:HasPanel("NPCInteractMain") then
    if not self.CacheOptions then
      self.CacheOptions = _G.WeakTable()
    end
    if not table.contains(self.CacheOptions, option) then
      table.insert(self.CacheOptions, option)
    end
    return false
  end
  local Panel = self:GetPanel("NPCInteractMain")
  if Panel then
    return Panel:AddNPCInteract(option)
  end
  return false
end

function MainUIModule:RemoveNPCInteract(option)
  if not self:HasPanel("NPCInteractMain") then
    if self.CacheOptions then
      table.removeValue(self.CacheOptions, option)
    end
    return false
  end
  local Panel = self:GetPanel("NPCInteractMain")
  if Panel then
    return Panel:RemoveNPCInteract(option)
  end
  return false
end

function MainUIModule:AutoPlayAction(optionId)
  local panel = self:GetPanel("NPCInteractMain")
  if panel then
    panel:AutoPlayAction(optionId)
  end
end

function MainUIModule:OpenCompassUnLockTips(param)
  if self:HasPanel("CompassUnlockTips") then
    local panel = self:GetPanel("CompassUnlockTips")
    panel:DoShow(param)
  else
    self:OpenPanel("CompassUnlockTips", param)
  end
end

function MainUIModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerReborn, self.OnPlayerReborn)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnMapLoaded)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.RELOGIN_UPDATE_PET, self.RefreshMainPet)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnInVisible, self.OnInVisible)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerOpened, self.OnLobbyMainInnerOpened)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerClosed, self.OnLobbyMainInnerClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.AfterEnterScene)
  _G.NRCEventCenter:UnRegisterEvent(self, WorldCombatModuleEvent.Enter, self.OnWorldCombatEnter)
  _G.NRCEventCenter:UnRegisterEvent(self, WorldCombatModuleEvent.Exit, self.OnWorldCombatExit)
  _G.NRCEventCenter:UnRegisterEvent(self, WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_INFO_UPDATE, self.OnStarligthInfoUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, WishCrystalModuleEvent.WISH_CRYSTAL_STARLIGHT_EXCHANGE, self.OnStarligthExchange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_ADDED, self.OnStoryFlagAdded)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.STORY_FLAG_CHANGE, self.OnStoryFlagChange)
  ScenePlayerInputManager.Clear()
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if LocalPlayer then
    LocalPlayer:RemoveEventListener(self, PlayerModuleEvent.ON_BODY_TEMP_CHANGED, self.OnBodyTempChange)
  end
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_SELECTED_THROW_ITEM_NOTIFY, self.CheckRefreshThrowItemInfo)
  if self.LobbyDownTipsController then
    self.LobbyDownTipsController:Free()
    self.LobbyDownTipsController = nil
  end
  if self.MainPetTipsController then
    self.MainPetTipsController:Free()
    self.MainPetTipsController = nil
  end
end

function MainUIModule:OnTick(deltaTime)
  if self.bAiming == true and self.ReqItemType ~= _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    self.TickInterval = self.TickInterval + deltaTime
    if self.TickInterval > 0.2 then
      self:ShowNPCLv(self.bAiming)
      self.TickInterval = 0
    end
  end
end

function MainUIModule:ConstValidFunc(npc)
  return npc.InteractionComponent:CanBattle()
end

function MainUIModule:AdjustValidFunc(npc)
  return npc.bulkyVisible and self:IsNPCBetweenDistanceandAngleValid(npc)
end

function MainUIModule:CompareFunc(npc1, npc2)
  local dis1 = npc1.squaredDis2LocalIgnoreZ or 1000000
  local dis2 = npc2.squaredDis2LocalIgnoreZ or 1000000
  return dis1 < dis2
end

function MainUIModule:OnCmdSetLongPressPetIndex(_index)
  self.LongPressPetIndex = _index
end

function MainUIModule:OnCmdGetLongPressPetIndex()
  return self.LongPressPetIndex
end

function MainUIModule:OnCmdSelectLongPressPetIndex(_index, _IsUpdate)
  self.SelectLongPressPetIndex = _index
  if _IsUpdate then
    self:DispatchEvent(MainUIModuleEvent.SelectLongPressPetEvent, _index)
  end
end

function MainUIModule:OnCmdGetSelectLongPressPetIndex()
  return self.SelectLongPressPetIndex
end

function MainUIModule:ChangeToValid(npc)
  Log.Debug("MainUIModule:ChangeToValid")
  if npc.PetHUDComponent and not self.player.statusComponent:HasStatus(_G.Enum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    if self.selectedItemId > 0 then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.selectedItemId)
      if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
        local ballActConf = _G.DataConfigManager:GetBallAct(self.selectedItemId)
        if ballActConf.Max_Auto_Find_Target_Distance > 0 then
          npc.PetHUDComponent:ShowAutoLockInfo(true)
        else
          Log.Debug("MainUIModule:ChangeToValid321")
          npc.PetHUDComponent:ShowAutoLockInfo(false)
        end
      end
    else
      npc.PetHUDComponent:ShowAutoLockInfo(true)
    end
  end
end

function MainUIModule:ChangeToInValid(npc)
  Log.Debug("MainUIModule:ChangeToInValid")
  if npc.PetHUDComponent then
    npc.PetHUDComponent:ShowAutoLockInfo(false)
  end
end

function MainUIModule:ShowAutoLockIcon(bool)
  Log.Debug("MainUIModule:ShowAutoLockIcon", self.selectedItemId)
  if self.selectedItemId == nil then
    return
  end
  if 0 == self.selectedItemId then
  end
  local npcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetTopKNPC, self)
  if type(npcs) ~= "boolean" and #npcs > 0 and npcs[1].PetHUDComponent then
    if bool then
      if self.selectedItemId > 0 then
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.selectedItemId)
        if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
          local ballActConf = _G.DataConfigManager:GetBallAct(self.selectedItemId)
          if ballActConf.Max_Auto_Find_Target_Distance > 0 then
            npcs[1].PetHUDComponent:ShowAutoLockInfo(true)
          else
            npcs[1].PetHUDComponent:ShowAutoLockInfo(false)
          end
        end
      else
        npcs[1].PetHUDComponent:ShowAutoLockInfo(true)
      end
    else
      npcs[1].PetHUDComponent:ShowAutoLockInfo(false)
    end
  end
end

function MainUIModule:IsNPCBetweenDistanceandAngleValid(_npc)
  local actor = _npc.viewObj
  if actor then
    local targetPos = actor:Abs_K2_GetActorLocation()
    local MaxDist = 0
    local MinDist = 90000.0
    if self.selectedItemId ~= nil and self.selectedItemId > 0 then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(self.selectedItemId)
      if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
        local ballActConf = _G.DataConfigManager:GetBallAct(self.selectedItemId)
        MaxDist = ballActConf.Max_Auto_Find_Target_Distance ^ 2
      end
    else
      MaxDist = 1000000.0
    end
    if MaxDist > _npc.squaredDis2LocalIgnoreZ and MinDist < _npc.squaredDis2LocalIgnoreZ then
      local playerCameraManager = UE4.UGameplayStatics.GetPlayerControllerFromID(_G.UE4Helper.GetCurrentWorld(), 0).PlayerCameraManager
      if playerCameraManager then
        local cameraLocation = playerCameraManager:Abs_GetCameraLocation()
        local targetDir = targetPos - cameraLocation
        targetDir:Normalize()
        local cameraRoatation = playerCameraManager:GetCameraRotation()
        local cameraDir = UE4.UKismetMathLibrary.GetForwardVector(cameraRoatation)
        local cosAngle = targetDir.X * cameraDir.X + targetDir.Y * cameraDir.Y
        if cosAngle > math.sqrt(2) / 2 then
          return true
        end
      end
    end
  end
  return false
end

function MainUIModule:CalcSquareDis(pos1, pos2)
  local subx = pos1.X - pos2.X
  local suby = pos1.Y - pos2.Y
  return subx * subx + suby * suby
end

function MainUIModule:CalcAngle(pos1, pos2)
  local cosAngle = pos1.X * pos2.X + pos1.Y * pos2.Y
  return math.deg(math.acos(cosAngle))
end

function MainUIModule:SwitchMainPanel(NewMainUIType, bNotTemp, bReBindIA)
  self.MainPanelMgr:SwitchMainPanel(NewMainUIType, bNotTemp, bReBindIA)
end

function MainUIModule:OnCmdOpenLobbyMainPanel()
  local bInDialogue
  if _G.DialogueModuleCmd then
    bInDialogue = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue)
  end
  if _G.BattleManager.isInBattle or bInDialogue then
    self:LogWarning("Open LobbyMainPanel Failed, maybe in battle or dialogue")
    return
  end
  self:Log("OnCmdOpenLobbyMainPanel", NRCModeManager:GetCurMode(), NRCModeManager:GetCurMode().modeName)
  if not NRCEnv:IsLocalMode() then
    self:SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.LobbyMain, false)
    self:OnLobbyMainOpen()
  elseif _G.AppMain:HasDebug() and not NRCModuleManager:DoCmd(DebugModuleCmd.CheckIsInPhotoEditorMode) then
    self:SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.LobbyMainLocal, false)
  end
end

function MainUIModule:OnLobbyMainOpen()
  if self:HasPanel("NPCInteractMain") then
    local panel = self:GetPanel("NPCInteractMain")
    panel.ShouldCollapse = false
  end
  if self:HasPanel("MagicMessageMusicToolbar") then
    self:EnablePanel("MagicMessageMusicToolbar")
  end
  local magicReplayModule = _G.NRCModuleManager:GetModule("MagicReplayModule")
  if magicReplayModule and magicReplayModule:HasPanel("ReplayPanel") then
    magicReplayModule:EnablePanel("ReplayPanel")
  end
end

function MainUIModule:OnCmdCloseLobbyMainPanel()
  self:Log("OnCmdCloseLobbyMainPanel")
  if not NRCEnv:IsLocalMode() then
    self:SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.None, false)
    self:OnCloseLobbyMain()
  else
    self:SwitchMainPanel(MainUIModuleEnum.MainUIPanelType.None, false)
  end
end

function MainUIModule:OnCloseLobbyMain()
  if self:HasPanel("NPCInteractMain") then
    local panel = self:GetPanel("NPCInteractMain")
    panel.ShouldCollapse = true
  end
  self:DoCmdCloseHUDSimpleList()
  self:DoCmdCloseSimpleUseList()
  if self:HasPanel("MagicMessageMusicToolbar") then
    self:DisablePanel("MagicMessageMusicToolbar")
  end
  local magicReplayModule = _G.NRCModuleManager:GetModule("MagicReplayModule")
  if magicReplayModule and magicReplayModule:HasPanel("ReplayPanel") then
    magicReplayModule:DisablePanel("ReplayPanel")
  end
end

function MainUIModule:TryOpenMainPanel()
  if self.MainPanelMgr.CurUIType == MainUIModuleEnum.MainUIPanelType.None then
    self.MainPanelMgr.CurUIType = MainUIModuleEnum.MainUIPanelType.LobbyMain
  end
  self:SwitchMainPanel(self.MainPanelMgr.CurUIType)
end

function MainUIModule:OnCmdOpenLobbyMainInnerPanel(OpenType)
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.FullSpeed, "LobbyMainInner")
  self:OpenPanel("LobbyMainInner", OpenType, resListData)
end

function MainUIModule:ClickOpenPanelLobbyMainInner()
  local panel = self:GetPanel("LobbyMain")
  local CompassIcon = panel and panel.UMG_CompassIcon
  if CompassIcon then
    CompassIcon:OpenLobbyMainCompass()
  end
end

function MainUIModule:OnCmdCloseLobbyMainInnerPanel()
  self:DisablePanel("LobbyMainInner")
end

function MainUIModule:HasCompass()
  return self:HasPanel("LobbyMainInner")
end

function MainUIModule:OnCmdOpenPanelGameInfo(_param)
end

function MainUIModule:OnCmdClosePanelGameInfo()
end

function MainUIModule:OnCmdUIOnDashAbilityVitalityDeficiency()
  self:DispatchEvent(MainUIModuleEvent.UI_OnDashAbilityVitalityDeficiency)
end

function MainUIModule:OnCMDUISetVitalityShow()
  self:DispatchEvent(MainUIModuleEvent.UI_OnSetVitalityShow)
end

function MainUIModule:OnSetVitalityHideFlag(bHide)
  self:DispatchEvent(MainUIModuleEvent.UI_OnSetVitalityHideFlag, bHide)
end

function MainUIModule:OnCmdUIOnAbilitySlotNeedRefresh()
  self:DispatchEvent(MainUIModuleEvent.UI_OnAbilitySlotNeedRefresh)
end

function MainUIModule:OnCmdOpenAppearanceRolePlay(bOpen)
  local isOpening, _ = self:HasPanel("AppearanceRolePlay")
  if bOpen then
    if not isOpening then
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FASHION_CHANGE)
      if isBan then
        return
      end
      self:OpenPanel("AppearanceRolePlay")
    end
  elseif isOpening then
    local panel = self:GetPanel("AppearanceRolePlay")
    panel:OnClickCloseBtn()
  end
end

function MainUIModule:OnCmdOpenWorldWardrobe(bOpen)
  local isOpening, _ = self:HasPanel("LobbyMain")
  if isOpening then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:OpenWorldWardrobe(bOpen)
    end
  end
end

function MainUIModule:RegPanel_1(name, path, layer, customDisableRendering, touchCount, isSingleTouchPanel, enablePcEsc, disableLoadBlock)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.touchCount = touchCount
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = false
  registerData.disableLoadBlock = disableLoadBlock
  self:RegisterPanel(registerData)
  return registerData
end

function MainUIModule:RegPanel(name, path, layer, customDisableRendering, touchCount, isSingleTouchPanel, enablePcEsc, disableLoadBlock)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/MainUI/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.touchCount = touchCount
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = enablePcEsc and enablePcEsc or false
  registerData.disableLoadBlock = disableLoadBlock
  self:RegisterPanel(registerData)
  return registerData
end

function MainUIModule:RegUMGNPCInteractMainPanel()
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = "NPCInteractMain"
  registerData.panelPath = "/Game/NewRoco/Modules/System/NPC/Res/UMG_NPCInteractMain"
  registerData.panelLayer = Enum.UILayerType.UI_LAYER_MAIN
  registerData.customDisableRendering = false
  registerData.enablePcEsc = false
  self:RegisterPanel(registerData)
end

function MainUIModule:OnLogin(isRelogin)
  Log.Debug("MainUIModule:OnLogin")
  self:DispatchEvent(MainUIModuleEvent.MainUIGameLoginEvent, isRelogin)
end

function MainUIModule:OnCmdCloseGuideBook()
  self:DispatchEvent(MainUIModuleEvent.CloseGuideBookEvent)
end

function MainUIModule:OnRefreshLocalPlayerAbilities()
  self:DispatchEvent(MainUIModuleEvent.UI_RefreshPlayerAbilities)
end

function MainUIModule:UpdateEquipItemInfo(bSetThrow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if _G.UE4Helper.IsPCMode() then
    if panel.PCKeyFoundation then
      panel.PCKeyFoundation:UpdateEquipItemInfo(bSetThrow)
    end
  elseif panel.UMG_PlayerInfoHUD then
    panel.UMG_PlayerInfoHUD:UpdateEquipItemInfo(bSetThrow)
  end
end

function MainUIModule:UpdateEquipMagicItemInfo(bSetThrow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if _G.UE4Helper.IsPCMode() then
    if panel.PCKeyFoundation then
      panel.PCKeyFoundation:UpdateEquipMagicItemInfo(bSetThrow)
    end
  elseif panel.UMG_PlayerInfoHUD then
    panel.UMG_PlayerInfoHUD:UpdateEquipMagicItemInfo(bSetThrow)
  end
end

function MainUIModule:ShowFrontSight(show, cancelType, isAbility)
  self:DispatchEvent(MainUIModuleEvent.UI_ShowFrontSight, show, cancelType, isAbility)
  if false == show then
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if self.ReqItemType == _G.MainUIModuleEnum.MainUIChooseType.PET and not isAbility then
      self:OnBeginSelectPetMain()
    end
    if self.ReqItemType ~= _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
      local AllNpcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetAllNPCInIter)
      if type(AllNpcs) == "table" then
        for k, v in pairs(AllNpcs) do
          if v.PetHUDComponent and v.config.throwing_interact_type == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
            v.isAimed = false
            v.bShowAimedLv = false
            v.PetHUDComponent:OnDistanceOptimize(0, 0, 0, 0)
          end
        end
      end
    end
  end
end

function MainUIModule:GetAimJoystickPointerIndex(mode)
  if not self:HasPanel("LobbyMain") then
    return -1
  end
  local panel = self:GetPanel("LobbyMain")
  return panel:GetAimJoystickPointerIndex(mode)
end

function MainUIModule:UpdateFrontSight(isCollision)
  self:DispatchEvent(MainUIModuleEvent.UI_UpdateFrontSight, isCollision)
end

function MainUIModule:SetThrowItem(type, itemInfo, recycleState, Session)
  if (type == _G.MainUIModuleEnum.MainUIChooseType.ITEM or type == _G.MainUIModuleEnum.MainUIChooseType.MAGIC) and itemInfo then
    self.selectedItemId = itemInfo.id
  else
    self.selectedItemId = 0
  end
  if type == _G.MainUIModuleEnum.MainUIChooseType.PET then
    self:SaveCurMainUIThrowSelectInfo(itemInfo.gid)
  end
  self:DispatchEvent(MainUIModuleEvent.UI_SetThrowItem, type, itemInfo, recycleState, Session)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.UI_SetThrowItem, type, itemInfo)
end

function MainUIModule:ReThrowMagic()
  self:DispatchEvent(MainUIModuleEvent.ReThrowMagic)
end

function MainUIModule:OnCmdSetThrowNull()
  self:DispatchEvent(MainUIModuleEvent.UI_SetThrowNull)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.UI_SetThrowNull)
end

function MainUIModule:CmdOpenOrCloseThrowInputPcMode(State)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if _G.UE4Helper.IsPCMode() then
    panel.PCKeyFoundation.AbilitySlot_Throw.UMG_Ability_Slot_Throw:OpenOrCloseThrowIntPut(State)
  else
    panel.UMG_PlayerAbilities.AbilitySlot_Throw:OpenOrCloseThrowIntPut(State)
  end
end

function MainUIModule:SetCompassUpdateTrace(isUpdate)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    panel.UMG_Compass.IsUpdateTraceInfo = isUpdate
    if isUpdate then
      panel.UMG_Compass:UpdateTraceNpc()
    end
  end
  local compassIcon = panel.UMG_CompassIcon
  if panel.UMG_CompassIcon and compassIcon.UMG_Minimap and compassIcon.isContruct and not compassIcon.isDestruct then
    compassIcon.UMG_Minimap:UpdateTraceNpc()
  end
end

function MainUIModule:OnCmdSetSelectPetIndex(_Index, PetData)
  self.SelectPetIndex = _Index
  self.PetData = PetData
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.MainPetScrollList and panel.MainPetScrollList.isContruct and not panel.MainPetScrollList.isDestruct then
    panel.MainPetScrollList:SelectPetByIndex()
  end
end

function MainUIModule:OnCmdGetSelectPetIndex()
  return self.SelectPetIndex, self.PetData
end

function MainUIModule:SetCompassPetSense(sceneNpc, iconPath)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
    panel.UMG_Compass:ShowPetSense(sceneNpc, iconPath)
  end
end

function MainUIModule:SendChangeSelectedThrowItemReq(throwItemType, ThrowItemInfo)
  if ThrowItemInfo and ThrowItemInfo.gid and throwItemType == self.ReqItemType and ThrowItemInfo.gid == self.ReqItemGid then
    return
  end
  if BattleManager and BattleManager.battleRuntimeData:IsOnBattleTest() then
    return
  end
  local throwType, throwGid, magicGid
  local curThrowItemInfo = _G.DataModelMgr.PlayerDataModel:GetThrowItemInfo()
  if curThrowItemInfo.cur_selected_throw_item ~= nil then
    throwGid = curThrowItemInfo.cur_selected_throw_item.cur_selected_gid
    throwType = curThrowItemInfo.cur_selected_throw_item.cur_selected_throw_type
    magicGid = curThrowItemInfo.cur_selected_magic_item_gid
  end
  if ThrowItemInfo then
    if throwItemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
      if throwItemType + 1 == throwType and ThrowItemInfo.gid == throwGid then
        return
      end
      throwType = _G.ProtoEnum.ThrowType.THROW_BAGITEM
      throwGid = ThrowItemInfo.gid
      self.ReqItemType = throwItemType
      self.ReqItemGid = throwGid
    elseif throwItemType == _G.MainUIModuleEnum.MainUIChooseType.PET then
      if throwItemType + 1 == throwType and ThrowItemInfo.gid == throwGid then
        return
      end
      throwType = _G.ProtoEnum.ThrowType.THROW_PET
      throwGid = ThrowItemInfo.gid
      self.ReqItemType = throwItemType
      self.ReqItemGid = throwGid
    elseif throwItemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
      if throwItemType + 1 == throwType and ThrowItemInfo.gid == magicGid then
        return
      end
      throwType = _G.ProtoEnum.ThrowType.THROW_MAGIC
      magicGid = ThrowItemInfo.gid
      self.ReqItemType = throwItemType
      self.ReqItemGid = magicGid
    end
  end
  local req = _G.ProtoMessage:newZoneChangeSelectedThrowItemReq()
  req.cur_selected_throw_item.cur_selected_throw_type = throwType
  req.cur_selected_throw_item.cur_selected_gid = throwGid
  req.cur_selected_magic_item_gid = magicGid
  if -1 == throwItemType then
    if nil ~= ThrowItemInfo then
      magicGid = ThrowItemInfo.gid
      req.cur_selected_throw_item = nil
      req.cur_selected_magic_item_gid = magicGid
    else
      req.cur_selected_magic_item_gid = -1
      self.ReqItemGid = nil
    end
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_CHANGE_SELECTED_THROW_ITEM_REQ, req, self, self.SendChangeSelectedThrowItemRsp, false)
end

function MainUIModule:SendChangeSelectedThrowItemRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    _G.DataModelMgr.PlayerDataModel:RefreshThrowItemInfo(self.ReqItemType, self.ReqItemGid)
  end
end

function MainUIModule:CheckRefreshThrowItemInfo(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.cur_selected_throw_item then
    local bRefreshUI = false
    if rsp.cur_selected_throw_item.cur_selected_throw_type == _G.ProtoEnum.ThrowType.THROW_BAGITEM then
      if rsp.cur_selected_throw_item.cur_selected_gid >= 0 then
        self.ReqItemType = _G.MainUIModuleEnum.MainUIChooseType.ITEM
        self.ReqItemGid = rsp.cur_selected_throw_item.cur_selected_gid
      end
    elseif rsp.cur_selected_throw_item.cur_selected_throw_type == _G.ProtoEnum.ThrowType.THROW_PET then
      if rsp.cur_selected_throw_item.cur_selected_gid >= 0 then
        self.ReqItemType = _G.MainUIModuleEnum.MainUIChooseType.PET
        self.ReqItemGid = rsp.cur_selected_throw_item.cur_selected_gid
        bRefreshUI = true
      end
    elseif rsp.cur_selected_throw_item.cur_selected_throw_type == _G.ProtoEnum.ThrowType.THROW_MAGIC and rsp.cur_selected_magic_item_gid and rsp.cur_selected_magic_item_gid >= 0 then
      self.ReqItemType = _G.MainUIModuleEnum.MainUIChooseType.MAGIC
      self.ReqItemGid = rsp.cur_selected_magic_item_gid
    end
    if bRefreshUI then
      self:RefreshMainPet()
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.ReqItemGid)
      if petData then
        self:SetThrowItem(_G.MainUIModuleEnum.MainUIChooseType.PET, petData)
      end
    end
  end
end

function MainUIModule:RefreshMainPetSelectedState(gid)
  Log.Debug("MainUIModule:RefreshMainPetSelectedState", gid)
  self.curSelectedPetGid = gid
  self:DispatchEvent(MainUIModuleEvent.UI_RefreshMainPetSelectedState, gid)
end

function MainUIModule:GetCurSelectedPetGid()
  return self.curSelectedPetGid
end

function MainUIModule:SetCurSelectedPetGid(_gid)
  self.curSelectedPetGid = _gid
end

function MainUIModule:GetCurSelectedItemId()
  return self.selectedItemId
end

function MainUIModule:RefreshMainPetSelect()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.UMG_MainPet:RefreshSelectedState()
end

function MainUIModule:OnCmdPetMedalUpdate(MedalItem, AcquireType)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.UMG_MainPet:SetMedalGid(MedalItem, AcquireType)
end

function MainUIModule:LeaveAimState()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:LeaveAimState()
end

function MainUIModule:GetAimState()
  return self.bAiming
end

function MainUIModule:ShowNPCLv(bVisible)
  if bVisible then
    local AllNpcs = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetAllNPCInIter)
    if self.showNpcLvList == nil then
      self.showNpcLvList = {}
    end
    for k, v in pairs(AllNpcs) do
      local distSqrr = 0
      if v.config and v.config.throwing_interact_type == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
        local hiddenComp = v.HiddenComponent
        if hiddenComp and hiddenComp:IsHidden() == false or nil == hiddenComp then
          if v.viewObj and type(v.viewObj) ~= "boolean" and v.viewObj:IsValid() then
            local pos = v.viewObj:Abs_K2_GetActorLocation()
            local ScreenPos = UE4.FVector2D()
            local ViewportPos = UE4.FVector2D()
            local result = UE4.UNRCStatics.Abs_ProjectWorldToScreen(self.playerController, pos, ScreenPos)
            if true == result then
              UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), ScreenPos, ViewportPos)
              local InRange = true
              if ViewportPos.X >= self.LT.X and ViewportPos.X <= self.RB.X and ViewportPos.Y >= self.LT.Y and ViewportPos.Y <= self.RB.Y then
                InRange = true
              else
                InRange = false
              end
              local IsCatching = v.hideTrackMark
              if bVisible and InRange and not IsCatching then
                local deltaPosSqrReal = (pos.X - self:GetLockPetLandPos().X) ^ 2 + (pos.Y - self:GetLockPetLandPos().Y) ^ 2 + (pos.Z - self:GetLockPetLandPos().Z) ^ 2
                local deltaPosSqr = (ViewportPos.X - self.wndCenterPos.X) ^ 2 + (ViewportPos.Y - self.wndCenterPos.Y) ^ 2
                table.insert(self.showNpcLvList, {
                  npc = v,
                  disSqr = deltaPosSqr,
                  disSqrReal = deltaPosSqrReal
                })
                distSqrr = deltaPosSqrReal
              else
                v.bShowAimedLv = false
              end
            else
              v.bShowAimedLv = false
            end
          end
        elseif hiddenComp and hiddenComp:IsHidden() == true and v.viewObj then
          v.bShowAimedLv = false
        end
        if v.PetHUDComponent then
          v.PetHUDComponent:OnDistanceOptimize(0, 0, distSqrr, 0)
        end
      end
    end
    table.sort(self.showNpcLvList, function(a, b)
      return a.disSqr < b.disSqr
    end)
    for i = 1, #self.showNpcLvList do
      if self.showNpcLvList[i].npc then
        if i <= self.showPetLvMaxNum or true == self.showNpcLvList[i].npc.isAimed then
          self.showNpcLvList[i].npc.bShowAimedLv = true
        else
          self.showNpcLvList[i].npc.bShowAimedLv = false
        end
        if self.showNpcLvList[i].npc.PetHUDComponent then
          self.showNpcLvList[i].npc.PetHUDComponent:OnDistanceOptimize(0, 0, self.showNpcLvList[i].disSqrReal, 0)
        end
      end
    end
  elseif self.showNpcLvList and #self.showNpcLvList > 0 then
    for k, v in ipairs(self.showNpcLvList) do
      if v.npc then
        v.npc.bShowAimedLv = false
      end
    end
  end
  self.showNpcLvList = nil
end

function MainUIModule:SetLockPetLandPos(pos)
  self.lockPetLandPos = pos
end

function MainUIModule:GetLockPetLandPos()
  return self.lockPetLandPos or FVectorZero
end

function MainUIModule:GetAimRectRange()
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local ScaleX = _G.DataConfigManager:GetPetGlobalConfig("pet_level_show_length").num / 10000
  local ScaleY = _G.DataConfigManager:GetPetGlobalConfig("pet_level_show_width").num / 10000
  local LT = UE4.FVector2D(viewportSize.X / 2 * (1 - ScaleX), viewportSize.Y / 2 * (1 - ScaleY))
  local RB = UE4.FVector2D(LT.X + viewportSize.X * ScaleX, LT.Y + viewportSize.Y * ScaleY)
  self.wndCenterPos = UE4.FVector2D(viewportSize.X / 2, viewportSize.Y / 2)
  self.LT = LT
  self.RB = RB
end

function MainUIModule:SetLockPosition(x, y)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  return panel.UMG_LockBall:SetLockPosition(x, y)
end

function MainUIModule:SetThrowHitTestInvisible(bool, bThrowing)
  local bThrow = bThrowing or false
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:SetThrowHitTestInvisible(bool, bThrow)
end

function MainUIModule:ChangeCompassIconByFunctionBan(bShow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:ChangeCompassIconByFunctionBan(bShow)
end

function MainUIModule:ChangeHUDMagicByFunctionBan(bShow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:ChangeHUDMagicByFunctionBan(bShow)
end

function MainUIModule:ChangeTaskTrackByFunctionBan(bShow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:ChangeTaskTrackByFunctionBan(bShow)
end

function MainUIModule:ChangeCompassByFunctionBan(bShow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:ShowCompass(bShow)
end

function MainUIModule:UpdataMainUIBlockInfo(areaId)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:MainUIBlockByArea(areaId)
end

function MainUIModule:OnCmdShowTemperatureHot(bShowUI, bForce)
  if bShowUI then
    if self:HasPanel("TemperatureHot") then
      local panel = self:GetPanel("TemperatureHot")
      panel:DoCustomOpen()
      return
    end
    Log.Debug("MainUIModule:OnCmdShowTemperatureHot", bShowUI, 2)
    self:OpenPanel("TemperatureHot")
  else
    if not self:HasPanel("TemperatureHot") then
      self:ClosePanel("TemperatureHot")
      return
    end
    Log.Debug("MainUIModule:OnCmdShowTemperatureHot", bShowUI, 2)
    local panel = self:GetPanel("TemperatureHot")
    panel:DoCustomClose(bForce)
  end
end

function MainUIModule:OnCmdShowTemperatureCold(bShowUI, bForce)
  if bShowUI then
    if self:HasPanel("TemperatureCold") then
      local panel = self:GetPanel("TemperatureCold")
      panel:DoCustomOpen()
      return
    end
    Log.Debug("MainUIModule:OnCmdShowTemperatureCold", bShowUI, 2)
    self:OpenPanel("TemperatureCold")
  else
    if not self:HasPanel("TemperatureCold") then
      self:ClosePanel("TemperatureCold")
      return
    end
    Log.Debug("MainUIModule:OnCmdShowTemperatureCold", bShowUI, 2)
    local panel = self:GetPanel("TemperatureCold")
    panel:DoCustomClose(bForce)
  end
end

function MainUIModule:OnCmdSetStartThrowItem()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:GetThrowItem()
  end
end

function MainUIModule:SetSimpleUseListByType(type)
  self:DispatchEvent(MainUIModuleEvent.UI_SetSimpleUseListByType, type)
end

function MainUIModule:SetSimpleUseListVisible(visible)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:SetSimpleUseListVisible(visible)
  end
end

function MainUIModule:AddToDisableLobbyMainPopUpList(PopupName)
  Log.Debug("MainUIModule:AddToDisableLobbyMainPopUpList", PopupName)
  if not self.NeedDisableLobbyMainPopupList then
    self.NeedDisableLobbyMainPopupList = {}
  end
  self.NeedDisableLobbyMainPopupList[PopupName] = true
end

function MainUIModule:RemoveFromDisableLobbyMainPopUpList(PopupName)
  Log.Debug("MainUIModule:RemoveFromDisableLobbyMainPopUpList", PopupName)
  if self.NeedDisableLobbyMainPopupList and self.NeedDisableLobbyMainPopupList[PopupName] then
    self.NeedDisableLobbyMainPopupList[PopupName] = nil
  end
end

function MainUIModule:CheckHasDisableMainPopUp()
  return not table.isEmpty(self.NeedDisableLobbyMainPopupList)
end

function MainUIModule:ChangeLobbyMainStyle(bNew)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:ChangeLobbyMainStyle(bNew)
  end
end

function MainUIModule:OnTaskClicked()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:OnTaskClicked()
  end
end

function MainUIModule:OnCmdCloseCompass(bClose)
  if self:HasPanel("LobbyMainInner") then
    local panel = self:GetPanel("LobbyMainInner")
    panel:ForceCloseCompass()
  else
    if self:IsPanelInOpening("LobbyMainInner") then
      _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "LobbyMainInner")
      _G.NRCAudioManager:SetLobbyMainInnerOpen(false)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnLobbyMainInnerClosed)
    end
    self:ClosePanel("LobbyMainInner")
  end
end

function MainUIModule:CompassChangeToHidde(hiddenState)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
      panel.UMG_Compass:ChangeCompassState(3, hiddenState)
    end
  end
end

function MainUIModule:CompassChangeToLeakage(bClose)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
      panel.UMG_Compass:ChangeCompassState(1)
    end
  end
end

function MainUIModule:CompassChangeToNormal(bClose)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel.UMG_Compass and panel.UMG_Compass.isContruct and not panel.UMG_Compass.isDestruct then
      panel.UMG_Compass:ChangeCompassState(1)
    end
  end
end

function MainUIModule:SetMiniMapOrCompassState(state)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    local compassIcon = panel.UMG_CompassIcon
    if panel.UMG_CompassIcon and compassIcon.UMG_Minimap and compassIcon.isContruct and not compassIcon.isDestruct then
      compassIcon.UMG_Minimap:ChangeMinimapState(state)
    end
  end
end

function MainUIModule:OnCmdPlayCompassAnimation(eventInfo)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnPlayCompassAnimation, eventInfo)
end

function MainUIModule:ChangeMoveJoystickMode(_bSelected)
  if true == _bSelected or false == _bSelected then
    self.IsLockMoveJoystick = _bSelected
  else
    self.IsLockMoveJoystick = not self.IsLockMoveJoystick
  end
  if self.IsLockMoveJoystick then
    self:LogError("\229\136\135\230\141\162\229\136\176\229\155\186\229\174\154\230\145\135\230\157\134")
  else
    self:LogError("\229\136\135\230\141\162\229\136\176\232\135\170\231\148\177\230\145\135\230\157\134")
  end
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.ChangeMoveJoystickMode, self.IsLockMoveJoystick)
  local joystickConfig = JsonUtils.LoadSaved(_JoystickConfigFilename, {})
  joystickConfig.IsLockedJoystick = self.IsLockMoveJoystick
  JsonUtils.DumpSaved(_JoystickConfigFilename, joystickConfig)
  return self.IsLockMoveJoystick
end

function MainUIModule:GetMoveJoystickMode()
  return self.IsLockMoveJoystick
end

function MainUIModule:OnCmdSetPropPlaceMode(_bIsFreedomMode)
  if self.IsFreedomPropPlaceMod == _bIsFreedomMode then
    return
  end
  self.IsFreedomPropPlaceMode = _bIsFreedomMode
  local joystickConfig = JsonUtils.LoadSaved(_JoystickConfigFilename, {})
  if not joystickConfig.bIsFreedomModeMap then
    joystickConfig.bIsFreedomModeMap = {}
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  joystickConfig.bIsFreedomModeMap[tostring(uin)] = _bIsFreedomMode
  JsonUtils.DumpSaved(_JoystickConfigFilename, joystickConfig)
end

function MainUIModule:OnCmdGetPropPlaceMode()
  return self.IsFreedomPropPlaceMode and 1 or 0
end

function MainUIModule:OnCmdMainUIIsShow()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      return true
    else
      return false
    end
  else
    return false
  end
end

function MainUIModule:OnCmdSelectPetByGid(gid)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel:SelectPetByGid(gid)
  end
end

function MainUIModule:DoCompassUnlockShow()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.UMG_CompassIcon:PlayReceive()
end

function MainUIModule:OnCmdShowCompass(bShow)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel:ShowCompass(bShow)
end

function MainUIModule:OnStartMiniGame()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  if not panel.UMG_MiniGame_Task then
    return
  end
  panel.UMG_MiniGame_Task:OnStartMiniGame()
end

function MainUIModule:OnSetLegendaryMatchState(matchState, battleId, starNum, time)
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.UMG_CompassIcon:SetLegendaryMatchState(matchState, battleId, starNum, time)
end

function MainUIModule:OnVisitPlaneClosed()
  if not self:HasPanel("LobbyMain") then
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.UMG_CompassIcon:OnVisitPlaneClosed()
end

function MainUIModule:DoBlackScreenTransition(type, position)
  Log.Debug("DoBlackScreenTransition")
  if self:HasPanel("LobbyMainInnerBlackScreen") then
    local panel = self:GetPanel("LobbyMainInnerBlackScreen")
    panel:PlayTransitions(type, position)
  else
    local res_list_data = _G.NRCPanelResLoadData()
    res_list_data.PreLoadResList = {}
    table.insert(res_list_data.PreLoadResList, "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_DS_367.T_UI_DS_367'")
    self:OpenPanel("LobbyMainInnerBlackScreen", {type = type, position = position}, res_list_data)
  end
end

function MainUIModule:DoNormalBlackScreenTransition()
  Log.Debug("DoNormalBlackScreenTransition")
  if self:HasPanel("LobbyMainInnerNormalBlackScreen") then
    local panel = self:GetPanel("LobbyMainInnerNormalBlackScreen")
    panel:PlayTransitions()
  else
    local res_list_data = _G.NRCPanelResLoadData()
    res_list_data.PreLoadResList = {}
    table.insert(res_list_data.PreLoadResList, "Texture2D'/Game/ArtRes/UI/Effects/Textures/T_UI_DS_367.T_UI_DS_367'")
    self:OpenPanel("LobbyMainInnerNormalBlackScreen", {}, res_list_data)
  end
end

function MainUIModule:DoBlackScreenTransitionOut()
  Log.Debug("DoBlackScreenTransitionOut")
  if self:HasPanel("LobbyMainInnerBlackScreen") then
    local panel = self:GetPanel("LobbyMainInnerBlackScreen")
    panel:PlayTransitionsOut()
  else
    Log.Error("BlackScreen Not Exist? Crash!")
  end
end

function MainUIModule:DoNormalBlackScreenTransitionOut()
  Log.Debug("DoNormalBlackScreenTransitionOut")
  if self:HasPanel("LobbyMainInnerNormalBlackScreen") then
    local panel = self:GetPanel("LobbyMainInnerNormalBlackScreen")
    panel:PlayTransitionsOut()
  else
    Log.Error("BlackScreen Not Exist? Crash!")
  end
end

function MainUIModule:PreLoadBlackScreen()
  self:PreLoadPanel("LobbyMainInnerBlackScreen", 5)
end

function MainUIModule:ShouldDisableForNow()
  if self:HasPanel("LobbyMainInner") then
    local Panel = self:GetPanel("LobbyMainInner")
    return Panel:IsWaitingForSubPanelPrepared()
  else
    return false
  end
end

function MainUIModule:GetIconLoopTime(icon_type)
  if self:HasPanel("LobbyMainInner") then
    local Panel = self:GetPanel("LobbyMainInner")
    return Panel:GetIconLoopTime(icon_type)
  else
    return 0
  end
end

function MainUIModule:OnLobbyMainInnerSubPanelLoaded()
  if self:HasPanel("LobbyMainInner") then
    local Panel = self:GetPanel("LobbyMainInner")
    Panel:OnSubPanelPrepared()
  end
end

function MainUIModule:ShowHandbookTopicTips(tip)
  if not self:HasPanel("LobbyMain") then
    tip:MarkFinished()
    return
  end
  local panel = self:GetPanel("LobbyMain")
  panel.ProjectTask:AddNew(tip)
end

function MainUIModule:GetIsJoystickTouch()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      return panel.PlayerCtrl.UMG_Control_Joystick.isJoystickTouch
    end
  end
  return false
end

function MainUIModule:SetJoystickEnabled(bEnabled)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      if not bEnabled then
        panel.PlayerCtrl.UMG_Control_Joystick:OnInVisible()
        panel.PlayerCtrl.UMG_Control_Joystick:SetVisibility(UE.ESlateVisibility.Collapsed)
      else
        panel.PlayerCtrl.UMG_Control_Joystick:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function MainUIModule:OnTouchMovedCheckHiddenUI()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.viewObj and localPlayer.viewObj:IsValid() then
    local playerController = localPlayer:GetUEController()
    local touchNum = playerController:GetTouchesNum()
    if 3 == touchNum then
      local curPos = {}
      for i = 1, touchNum do
        local locationX, locationY, bPressed = playerController:GetInputTouchState(i - 1)
        table.insert(curPos, UE4.FVector2D(locationX, locationY))
      end
      if curPos[1].X > 0 then
        if self:CheckFingerMove(curPos[1], curPos[2], curPos[3]) == true then
          if true == self:CheckCanHideLobbyMain() then
            self:ShowThreeFingerPanel(false)
          end
        else
          self:ShowThreeFingerPanel(true)
        end
      end
      self.threeFingerPos = curPos
    end
  end
end

function MainUIModule:CheckCanHideLobbyMain()
  if _G.DialogueModuleCmd == nil then
    Log.Error("_G.DialogueModuleCmd is nil??? Amazing")
    return
  end
  local bLobbyMainEnable = self:OnCmdGetLobbyMainEnableState()
  local hasDialogPanel = true
  local bInDialogue = _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue)
  local bBattleHidePanel = self.bBattleHidePanel
  if bLobbyMainEnable or bInDialogue and hasDialogPanel or bBattleHidePanel then
    return true
  else
    return false
  end
end

function MainUIModule:OnCmdSetBattleHidePanelState(bCanHide)
  self.bBattleHidePanel = bCanHide
end

function MainUIModule:CheckFingerMove(pos1, pos2, pos3)
  local centerG = (self.threeFingerPos[1] + self.threeFingerPos[2] + self.threeFingerPos[3]) / 3
  local delta1 = self:CalcSqrDist(pos1, centerG) - self:CalcSqrDist(self.threeFingerPos[1], centerG)
  local delta2 = self:CalcSqrDist(pos2, centerG) - self:CalcSqrDist(self.threeFingerPos[2], centerG)
  local delta3 = self:CalcSqrDist(pos3, centerG) - self:CalcSqrDist(self.threeFingerPos[3], centerG)
  if delta1 >= 0 and delta2 >= 0 and delta3 >= 0 then
    return true
  else
    return false
  end
end

function MainUIModule:ShowThreeFingerPanel(bShow)
  if bShow ~= self.threeFingerPanelVisible then
    if bShow then
      NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
    else
      NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    end
    self.threeFingerPanelVisible = bShow
  end
end

function MainUIModule:CalcSqrDist(pos1, pos2)
  return (pos1.X - pos2.X) ^ 2 + (pos1.Y - pos2.Y) ^ 2
end

function MainUIModule:ShowUIByClick()
  if self.threeFingerPanelVisible == false then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
end

function MainUIModule:OnCmdReleaseAimState()
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) and self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel.PlayerCtrl.UMG_Aim_Joystick:OnInVisible()
    end
  end
end

function MainUIModule:OnCmdFollowUISync(followData)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==CurState==", followData.new_state)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==OldState==", followData.old_state)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==FollowId==", followData.follow_id)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==ConfId==", followData.conf_id)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==TaskId==", followData.task_id)
  if self:HasPanel("PartnerAndPeer") then
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==111")
    local panel = self:GetPanel("PartnerAndPeer")
    if panel then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==222")
      panel:OnShowNPCFollowUI(followData)
    end
  else
    Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==MainUIModule:OnCmdFollowUISync==333")
    self:OnCmdSetNewFollowDataCache(followData)
    self:OpenPanel("PartnerAndPeer", {followData = followData})
  end
end

function MainUIModule:OnCmdFollowUIRelogin()
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnCmdFollowUIRelogin")
  if self:HasPanel("PartnerAndPeer") then
    local panel = self:GetPanel("PartnerAndPeer")
    if panel then
      panel:OnRelogin()
    end
  end
end

function MainUIModule:OnCmdInitFollowUIPanel()
  if self:HasPanel("PartnerAndPeer") then
    local panel = self:GetPanel("PartnerAndPeer")
    if panel then
      panel:InitFollowUI()
    end
  else
    self:OpenPanel("PartnerAndPeer")
  end
end

function MainUIModule:OnCmdSetFollowDataCache(data)
  self.FollowDataCache = data
end

function MainUIModule:OnCmdGetFollowDataCache()
  return self.FollowDataCache
end

function MainUIModule:OnCmdExitVisitPlayFollowUI()
  if self.FollowDataCache then
    local followData = {
      old_state = self.FollowDataCache.old_state,
      new_state = self.FollowDataCache.new_state,
      follow_id = self.FollowDataCache.follow_id,
      conf_id = self.FollowDataCache.conf_id,
      task_id = self.FollowDataCache.task_id
    }
    if self:HasPanel("PartnerAndPeer") then
      local panel = self:GetPanel("PartnerAndPeer")
      if panel then
        panel:VisitExitByPanelHasOpen(followData)
      end
    else
      self:OpenPanel("PartnerAndPeer", {followData = followData, IsVisit = true})
    end
    self.FollowDataCache = nil
  elseif not self:HasPanel("PartnerAndPeer") then
    self:OpenPanel("PartnerAndPeer")
  end
end

function MainUIModule:OnCmdJoinVisitPlayFollowUI()
  if self.FollowDataCache then
    if self:HasPanel("PartnerAndPeer") then
      local panel = self:GetPanel("PartnerAndPeer")
      if panel then
        panel:JoinVisit()
      end
    else
      local followData = {
        old_state = self.FollowDataCache.old_state,
        new_state = self.FollowDataCache.new_state,
        follow_id = self.FollowDataCache.follow_id,
        conf_id = self.FollowDataCache.conf_id,
        task_id = self.FollowDataCache.task_id
      }
      self:OpenPanel("PartnerAndPeer", {IsVisit = true, followData = followData})
    end
  end
end

function MainUIModule:OnCmdZoneSceneGetFollowInfoReq(confId)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:OnCmdZoneSceneGetFollowInfoReq==confId==", confId)
  local req = _G.ProtoMessage:newZoneSceneGetFollowInfoReq()
  if confId then
    req.confirm_talk_id = confId
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_GET_FOLLOW_INFO_REQ, req, self, self.ZoneSceneGetFollowInfoRsp, false, true)
end

function MainUIModule:ZoneSceneGetFollowInfoRsp(rsp)
  Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ZoneSceneGetFollowInfoRsp")
  if 0 == rsp.ret_info.ret_code then
    if 0 ~= rsp.conf_id then
      Log.Debug("\228\188\153\228\188\180\229\144\140\232\161\140==UMG_PartnerAndPeer_C:ZoneSceneGetFollowInfoRsp==\230\150\173\231\186\191\233\135\141\232\191\158\229\136\183\230\150\176\230\149\176\230\141\174")
      local followData = {
        new_state = rsp.new_state,
        follow_id = rsp.follow_id,
        task_id = rsp.task_id,
        conf_id = rsp.conf_id
      }
      if self:HasPanel("PartnerAndPeer") then
        local panel = self:GetPanel("PartnerAndPeer")
        if panel and 0 ~= rsp.conf_id then
          panel:OnReloginRefreshFollowData(followData)
        end
      else
        self:OpenPanel("PartnerAndPeer", {isRelogin = true, followData = followData})
      end
    end
  else
    local desc = _G.LuaText:GetErrorDesc(rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, desc, nil, nil, 1)
  end
end

function MainUIModule:OnReconnectStar()
  self:OnCmdClosePropPlacementPanel()
end

function MainUIModule:OnReconnect()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel.UMG_CompassIcon then
      panel.UMG_CompassIcon:InitStarlight(true)
    end
  end
end

function MainUIModule:TryDisplayAdditionalTarget()
  self:OpenAdditionalTarget()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:RefreshActiveSessions()
    end
  end
end

function MainUIModule:OpenAdditionalTarget()
  local rewards = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetExtraRewardList)
  if rewards then
    self:ClosePanel("AdditionalTarget")
    self:OnCmdOpenAdditionalTarget(rewards)
  end
end

function MainUIModule:OnCmdShowExtraAwardInfo(_Data)
  if _Data and _Data.extra_reward_list and #_Data.extra_reward_list > 0 then
    self:OnCmdOpenAdditionalTarget(_Data.extra_reward_list)
  end
end

function MainUIModule:OnCmdOpenAdditionalTarget(extra_reward_list)
  if self:HasPanel("AdditionalTarget") then
    local Panel = self:GetPanel("AdditionalTarget")
    if extra_reward_list then
      Panel:UpdatePanelInfo(extra_reward_list)
    end
    Panel:SetVisibilityInfo()
  else
    self:OpenPanel("AdditionalTarget", extra_reward_list)
  end
end

function MainUIModule:OnWorldCombatBoxVisible(SceneCharacter, RewardList)
  if not (RewardList and RewardList[1]) or not RewardList[1].extra_reward_id then
    Log.Dump(RewardList, 6, "MainUIModule:OnWorldCombatBoxVisible")
    return
  end
  if self:HasPanel("AdditionalTarget") then
    local Panel = self:GetPanel("AdditionalTarget")
    Panel:UpdatePanelInfo(RewardList, true)
  else
    self:OpenPanel("AdditionalTarget", RewardList)
  end
end

function MainUIModule:OnWorldCombatBoxInvisible(SceneCharacter, RewardList)
  if self:HasPanel("AdditionalTarget") then
    local Panel = self:GetPanel("AdditionalTarget")
    Panel:SetBoxVisible(false)
    Panel:OnBarrierHidden()
    Log.Debug("MainUIModule:OnWorldCombatBoxInvisible OnBarrierHidden")
  end
end

function MainUIModule:OnCmdShowOrHideAdditionalTarget(_IsShow)
  self:OpenAdditionalTarget()
end

function MainUIModule:OnCmdShowOrHideAdditionalTargetPanel(_IsShow)
  if self:HasPanel("AdditionalTarget") then
    local Panel = self:GetPanel("AdditionalTarget")
    Panel:ShowOrHideAdditionalTarget(_IsShow)
  end
end

function MainUIModule:OpenLeftBottomFunctionEntry()
  self:OpenPanel("UMG_LeftBottomFunctionEntry")
end

function MainUIModule:CloseLeftBottomFunctionEntry()
  self:ClosePanel("UMG_LeftBottomFunctionEntry")
end

function MainUIModule:ToggleLeftBottomFunctionEntry()
  if self:HasPanel("UMG_LeftBottomFunctionEntry") then
    self:CloseLeftBottomFunctionEntry()
  else
    self:OpenLeftBottomFunctionEntry()
  end
end

function MainUIModule:TryOpenChatPanel(bOpenByQuickChat)
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008003, "UMG_MainUIRoleHPItem_C:SetHpBt")
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT, true)
  if isBan then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).CHAT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanel, 0, nil, nil, bOpenByQuickChat)
  self:CloseLeftBottomFunctionEntry()
end

function MainUIModule:TryOpenTakePhotosPanel(bQuickShotCut)
  if bQuickShotCut then
    return NRCModuleManager:DoCmd(TakePhotosModuleCmd.QuickShotCut)
  end
  local openResult = NRCModuleManager:DoCmd(TakePhotosModuleCmd.TryOpenMainPanel)
  self:CloseLeftBottomFunctionEntry()
  return openResult
end

function MainUIModule:DoCmdOpenSimpleUseList(Type)
  local isOpening, _ = self:HasPanel("SimpleUseList")
  if isOpening then
    local panel = self:GetPanel("SimpleUseList")
    panel:SetListInfo(Type)
    if panel:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    else
      self:EnablePanel("SimpleUseList")
    end
  else
    self:OpenPanel("SimpleUseList", Type)
  end
end

function MainUIModule:DoCmdCloseSimpleUseList()
  if self:HasPanel("SimpleUseList") then
    local panel = self:GetPanel("SimpleUseList")
    if panel.enableView then
      panel:ClosePanel()
    end
  end
end

function MainUIModule:OnMainUIClose()
  self:DoCmdCloseHUDSimpleList()
  self:DoCmdCloseSimpleUseList()
end

function MainUIModule:SetGlobalPetHUDEnabled(bEnabled)
  if bEnabled ~= self.bGlobalPetHUDEnabled then
    self.bGlobalPetHUDEnabled = bEnabled
    self:DispatchEvent(MainUIModuleEvent.OnGlobalPetHUDEnabledChanged)
  end
end

function MainUIModule:SetGlobalPlayerHudEnabled(enable, opSource)
  local disableOpSource = _G.GlobalConfig.DisableAllPlayerHud or 0
  if enable then
    disableOpSource = disableOpSource & ~opSource
  else
    disableOpSource = disableOpSource | opSource
  end
  _G.GlobalConfig.DisableAllPlayerHud = disableOpSource
  local players = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  if not players then
    return
  end
  for _, player in pairs(players) do
    local hudComponent = player.hudComponent
    if hudComponent then
      hudComponent:SetHeadWidgetRenderStatus(enable, opSource)
    end
  end
end

function MainUIModule:OnLobbyMainInnerOpened()
  self:SetGlobalPlayerHudEnabled(false, _G.MainUIModuleEnum.DisableHudOpSource.LobbyMainOpen)
  self:SetGlobalPetHUDEnabled(false)
end

function MainUIModule:OnLobbyMainInnerClosed()
  self:SetGlobalPlayerHudEnabled(true, _G.MainUIModuleEnum.DisableHudOpSource.LobbyMainOpen)
  self:SetGlobalPetHUDEnabled(true)
end

function MainUIModule:OnCmdRecycleBattlePetByGid(gid)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel.UMG_MainPet:RecyclePetByGid(gid)
    end
  end
end

function MainUIModule:AfterEnterScene()
  self:DoCmdCloseSimpleUseList()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
  _G.NRCEventCenter:DispatchEvent(OnlineModuleEvent.SetIsHavePlayer, true)
end

function MainUIModule:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function MainUIModule:OnWandChanged()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:OnWandChanged()
    end
  end
end

function MainUIModule:GetLockOpenSubUI()
  Log.Info("MainUIModule:GetLockOpenSubUI")
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      return panel:GetLockOpenSubUi()
    end
  end
end

function MainUIModule:SetLockOpenSubUI(isLock)
  Log.Info("MainUIModule:SetLockOpenSubUI")
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      if isLock then
        panel:LockOpenSubUi()
      else
        panel:UnLockOpenSubUi()
      end
    end
  end
end

function MainUIModule:AddInputBlockMappingContext(Reason)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:AddInputBlockMappingContext(Reason)
    end
  end
end

function MainUIModule:RemoveInputBlockMappingContext(Reason)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:RemoveInputBlockMappingContext(Reason)
    end
  end
end

function MainUIModule:CameraSetIsCanClick()
  Log.Info("MainUIModule:CameraSetIsCanClick")
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel then
      panel:CameraSetIsCanClick()
    end
  end
end

function MainUIModule:OnCmdCheckIsShowFrontSight()
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    return panel.IsShowFrontSight
  end
  return false
end

function MainUIModule:OpenCreateMagicMessage(param)
  local umgName = "UMG_CreateMagicMessage"
  if param.ChildConf then
    local conf = param.ChildConf
    if conf.create_magic_message ~= "" then
      umgName = conf.create_magic_message
    end
  end
  local umgPath = string.format("/Game/NewRoco/Modules/System/MainUI/Res/%s", umgName)
  local panelData = self:GetPanelData("CreateMagicMessage")
  panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(umgPath)
  self:OpenPanel("CreateMagicMessage", param)
end

function MainUIModule:OpenShowMagicMessage(feedDetail, Action, SoundSession)
  local param = {
    feedDetail = feedDetail,
    Action = Action,
    SoundSession = SoundSession
  }
  local umgName = "UMG_ShowMagicMessage"
  if feedDetail.feed_info and feedDetail.feed_info.sub_type and 0 ~= feedDetail.feed_info.sub_type then
    local subMarkMessageTable = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
    for k, v in pairs(subMarkMessageTable) do
      local subMarkMessageConf = v
      if subMarkMessageConf.gameplay_type == param.feedDetail.feed_info.category and subMarkMessageConf.child_type == feedDetail.feed_info.sub_type then
        umgName = subMarkMessageConf.show_magic_message
        break
      end
    end
  end
  local umgPath = string.format("/Game/NewRoco/Modules/System/MainUI/Res/%s", umgName)
  local panelData = self:GetPanelData("ShowMagicMessage")
  panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(umgPath)
  self:OpenPanel("ShowMagicMessage", param)
end

function MainUIModule:OpenMagicMessageCommentPopUp(grid_id, feed_id)
  self:OpenPanel("MagicMessageCommentPopUp", grid_id, feed_id)
end

function MainUIModule:OpenShowFakeMagicMessage(fakeMessageId, action)
  self:OpenPanel("ShowFakeMagicMessage", fakeMessageId, action)
end

function MainUIModule:LobbyMainInnerBottonMoreOpenPanel(OpenMessage, Param1)
  OpenMessage = OpenMessage or "PrivilegeIntroductionPopUp"
  self:OpenPanel(OpenMessage, Param1)
end

function MainUIModule:OnCmdInitBallList(Type)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    panel.BallList:SetListInfo(Type)
  end
  self:DoCmdCloseSimpleUseList()
end

function MainUIModule:ReThrowEquipItem()
  self:DispatchEvent(MainUIModuleEvent.ReThrowEquipItem)
end

function MainUIModule:OnCmdCloseQuickChat()
  if self:HasAnyMainUIOpened() then
    local panel = self:GetCurMainPanel()
    panel:CloseQuickChat()
  end
end

function MainUIModule:DoCmdCheckCloseSimpleUseList()
  local flag = false
  if self:HasPanel("SimpleUseList") then
    local panel = self:GetPanel("SimpleUseList")
    if panel.enableView then
      flag = true
      panel:ClosePanel()
    end
  end
  return flag
end

function MainUIModule:OnStarligthInfoUpdate(rsp)
  if self:HasPanel("LobbyMainInner") then
    local panel = self:GetPanel("LobbyMainInner")
    if panel then
      panel:UpdateWishCrystalInfo(rsp.star_light_info)
    end
  end
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel.UMG_CompassIcon and rsp and rsp.star_light_info then
      panel.UMG_CompassIcon:CheckNeedtoShowStarInfoChange(true)
    end
  end
end

function MainUIModule:OnStarligthExchange(rsp)
  if self:HasPanel("LobbyMainInner") then
    local panel = self:GetPanel("LobbyMainInner")
    if panel then
      panel:UpdateWishCrystalInfo(nil, rsp.exchange_num)
    end
  end
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel.UMG_CompassIcon and rsp and rsp.star_light_info then
      panel.UMG_CompassIcon:UpdateStarlight(rsp.star_light_info)
    end
  end
end

function MainUIModule:OnCmdSendTLog(UIType)
  if UIType and UIType ~= _G.MainUIModuleEnum.FunctionID.NoneUI then
    local key = "CompassInnerLog"
    local tempString = "CompassInnerLog|%s|%s|%d|%d|%s|%d|%s|%d|%d"
    local gameTime = os.date("%Y-%m-%d %H:%M:%S")
    local gameAppId = "1110613799"
    local platId = -1
    local zoneId = 0
    local openId = "nil"
    local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
    local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
    local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
    if _G.OnlineModuleCmd then
      local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
      if needData and type(needData) == "table" then
        platId = needData.plat_info.plat_id or -1
        zoneId = needData.zoneId or 0
        openId = needData.openid or "nil"
      end
    end
    local value = string.format(tempString, gameTime, gameAppId, platId, zoneId, openId, uin, roleName, level, UIType)
    _G.GEMPostManager:SendNRCTLog(key, value)
  end
end

function MainUIModule:SetThrowBtnBlock(bSetBlock, Reason)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local ThrowAbilityPanel = MainPanel and MainPanel.UMG_PlayerAbilities and MainPanel.UMG_PlayerAbilities.AbilitySlot_Throw
    if ThrowAbilityPanel then
      ThrowAbilityPanel:SetBlockForReason(bSetBlock, Reason)
    end
  end
end

function MainUIModule:SetPetThrowBlockForReason(bSetBlock, Gid, Reason)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local ThrowAbilityPanel = MainPanel and MainPanel.UMG_PlayerAbilities and MainPanel.UMG_PlayerAbilities.AbilitySlot_Throw
    if ThrowAbilityPanel then
      ThrowAbilityPanel:SetPetThrowBlockForReason(bSetBlock, Gid, Reason)
    end
  end
end

function MainUIModule:SetRideBtnBlock(bSetBlock, Reason)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local RideAbilityPanel = MainPanel and MainPanel.UMG_PlayerAbilities and MainPanel.UMG_PlayerAbilities.AbilitySlot_OnPet
    if RideAbilityPanel then
      RideAbilityPanel:SetBlockForReason(bSetBlock, Reason)
    end
  end
end

function MainUIModule:SetPetRideBlockForReason(bSetBlock, Gid, Reason)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local RideAbilityPanel = MainPanel and MainPanel.UMG_PlayerAbilities and MainPanel.UMG_PlayerAbilities.AbilitySlot_OnPet
    if RideAbilityPanel then
      RideAbilityPanel:SetPetRideBlockForReason(bSetBlock, Gid, Reason)
    end
  end
end

function MainUIModule:SetMainPetTemplateLock(bSetBlock, Gid)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local MainPetPanel = MainPanel and MainPanel.UMG_MainPet
    if MainPetPanel then
      MainPetPanel:UpdatePetLock(bSetBlock, Gid)
    end
  end
end

function MainUIModule:OnCmdPlayHalfInjureFinish()
  self:DispatchEvent(MainUIModuleEvent.PlayHalfInjureFinishEvent)
end

function MainUIModule:OnCmdChangeAbilitySlotTrowBallState(isShow, isEmpty)
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    local ThrowAbilityPanel = MainPanel and MainPanel.UMG_PlayerAbilities and MainPanel.UMG_PlayerAbilities.AbilitySlot_Throw
    if ThrowAbilityPanel then
      ThrowAbilityPanel:ChangeBallState(isShow, isEmpty)
    end
  end
end

function MainUIModule:OnCmdUpdateEquipItemSelect()
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    if MainPanel then
      MainPanel:UpdateEquipItemSelect()
    end
  end
end

function MainUIModule:OnCmdAbilitySlotChangeMagicLimit()
  if self:HasPanel("LobbyMain") then
    local MainPanel = self:GetPanel("LobbyMain")
    if MainPanel then
      MainPanel:OnChangeMagicLimit()
    end
  end
end

function MainUIModule:OnCmdSavePerformanceTier()
  if not (JsonUtils and JsonUtils.LoadSaved) or not JsonUtils.DumpSaved then
    Log.Error("JsonUtils\229\183\165\229\133\183\229\135\189\230\149\176\228\184\141\229\143\175\231\148\168")
    return
  end
  if not WidgetPerformanceTier or not WidgetPerformanceTier.GetTier then
    Log.Error("WidgetPerformanceTier\230\168\161\229\157\151\228\184\141\229\143\175\231\148\168")
    return
  end
  local WidgetPerformanceTierInfo = JsonUtils.LoadSaved("WidgetPerformanceTier", false)
  if not WidgetPerformanceTierInfo then
    local tierData = WidgetPerformanceTier.GetTier()
    if not tierData then
      Log.Error("\232\142\183\229\143\150\230\128\167\232\131\189\229\136\134\230\161\163\230\149\176\230\141\174\229\164\177\232\180\165")
      return
    end
    local saveResult = JsonUtils.DumpSaved("WidgetPerformanceTier", tierData)
    if not saveResult then
      Log.Error("\228\191\157\229\173\152\230\128\167\232\131\189\229\136\134\230\161\163\230\150\135\228\187\182\229\164\177\232\180\165")
      return
    end
  end
end

function MainUIModule:OnCmdSetBottomIconListVisible(isVisible, isStarFocus)
  self.BottomIconListVisible = isVisible
end

function MainUIModule:OnCmdGetBottomIconListVisible(isVisible)
  return self.BottomIconListVisible
end

function MainUIModule:OnCmdExceptMyAbilityErrorCode(MyAbilityErrorCode)
  return 3 ~= MyAbilityErrorCode and 21 ~= MyAbilityErrorCode and 6 ~= MyAbilityErrorCode and 10 ~= MyAbilityErrorCode
end

function MainUIModule:OnCmdGetBallOrMagicShowCountText(count, itemType)
  count = count or 0
  local maxCount = 0
  if itemType == _G.Enum.BagItemType.BI_PET_BALL then
    maxCount = _G.DataConfigManager:GetGlobalConfigNumByKeyType("max_number_display_ball", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 0)
  elseif itemType == _G.Enum.BagItemType.BI_MAGIC then
    maxCount = _G.DataConfigManager:GetGlobalConfigNumByKeyType("max_number_display_magic", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 0)
  end
  if 0 ~= maxCount then
    if count > maxCount then
      return tostring(maxCount) .. "+"
    else
      return tostring(count)
    end
  else
    return tostring(count)
  end
end

function MainUIModule:OnStoryFlagAdded(changeVal, bIsHomeOwner)
  Log.Debug("[MainUIModule:OnStoryFlagAdded] changeVal:", changeVal)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(changeVal)
  if bIsHomeOwner == UseSelf then
    return
  end
  if changeVal == Enum.PlayerStoryFlagEnum.PSF_FUNC_CLOUD_JOUNERY_END then
    self:OnCmdOpenGameMatrixTips()
  end
end

function MainUIModule:OnStoryFlagChange(changeVal, bIsHomeOwner)
  Log.Debug("[MainUIModule:OnStoryFlagChange] changeVal:", changeVal)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(changeVal)
  if bIsHomeOwner == UseSelf then
    return
  end
  if changeVal == Enum.PlayerStoryFlagEnum.PSF_FUNC_CLOUD_JOUNERY_END then
    self:OnCmdOpenGameMatrixTips()
  end
end

function MainUIModule:TryShowGameMatrixTips()
  local Ret = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_CLOUD_JOUNERY_END)
  Log.Debug("[MainUIModule:CheckShowGameMatrixTips] IsAssignStoryFlags :", Ret)
  if Ret then
    self:OnCmdOpenGameMatrixTips()
  end
end

function MainUIModule:OnCmdOpenGameMatrixTips()
  Log.Debug("[MainUIModule:OnCmdOpenGameMatrixTips] ")
  if not CommonUtils.IsGameCloudEnv() then
    return
  end
  local IsHide = true
  if _G.Enum.FunctionEntrance.FE_CLOUD_GAME_TIPS then
    IsHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CLOUD_GAME_TIPS)
  end
  Log.Debug("[MainUIModule:OnCmdOpenGameMatrixTips] IsHide :", IsHide)
  if IsHide then
    return
  end
  CommonUtils.SendClientEventToCGSDK("{\"name\": \"game-event-transfer-end\",\"content\": {\"type\": \"jump-download\",\"value\":1}}")
end

function MainUIModule:OnCmdCloseGameMatrixTips()
end

function MainUIModule:OnCmdGetNewFollowDataCache()
  return self.NewFollowDataCache
end

function MainUIModule:OnCmdSetNewFollowDataCache(cache)
  self.NewFollowDataCache = cache
end

function MainUIModule:OnCmdOpenBallUseBagPanel()
  self:DoCmdOpenSimpleUseList(1)
end

function MainUIModule:OnCmdChangePlayerTags(action)
  if action then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnPlayerTagsChange, action.actor_id, action.player_tags)
  end
end

function MainUIModule:OnCmdOpenPropPlacementPanel(npcId)
  self:OpenPanel("PropPlacementPanel", npcId)
end

function MainUIModule:OnCmdClosePropPlacementPanel()
  if self:HasPanel("PropPlacementPanel") then
    self:ClosePanel("PropPlacementPanel")
  end
end

function MainUIModule:OnCmdMainPetTemplateTipsPlayEnd(index, petGid, petTipsItem)
  if self:HasPanel("LobbyMain") then
    local panel = self:GetPanel("LobbyMain")
    if panel and panel.UMG_MainPet then
      panel.UMG_MainPet:OnMainPetTemplateTipsPlayEnd(index, petGid, petTipsItem)
    end
  end
end

function MainUIModule:OnSetThrowSelectPetInfo(gid, team_idx, idx)
  if gid and team_idx and idx then
    self.CurThroowSelectInfo = {
      gid = gid,
      teamIdx = team_idx,
      selectIdx = idx
    }
  end
end

function MainUIModule:OnCmdGetThrowSelectPetInfo()
  return self.CurThroowSelectInfo
end

function MainUIModule:SaveCurMainUIThrowSelectInfo(gid)
  local isMainTeamIndex, TeamIdx = _G.DataModelMgr.PlayerDataModel:GetIsBigWorldMainTeamIndexByGid(gid)
  if not isMainTeamIndex then
    local SelectIndex, petData = _G.DataModelMgr.PlayerDataModel:GetPetDataAndTeamIndexByGid(gid)
    local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
    if TeamIdx and SelectIndex and PetTeams and PetTeams.teams[TeamIdx] and PetTeams.teams[TeamIdx].pet_infos and PetTeams.teams[TeamIdx].pet_infos[SelectIndex] then
      local gid = PetTeams.teams[TeamIdx].pet_infos[SelectIndex].pet_gid
      self.CurThroowSelectInfo = {
        gid = gid,
        teamIdx = TeamIdx,
        selectIdx = SelectIndex
      }
    end
  end
  return self.CurThroowSelectInfo
end

function MainUIModule:OnBeginSelectPetMain()
  if self.CurThroowSelectInfo and self.LastThroowSelectInfo and self.CurThroowSelectInfo.teamIdx == self.LastThroowSelectInfo.teamIdx then
    return
  end
  if self.CurThroowSelectInfo and self:HasPanel("LobbyMain") then
    local gid = self.CurThroowSelectInfo.gid
    local panel = self:GetPanel("LobbyMain")
    local teamIdx = self.CurThroowSelectInfo.teamIdx
    _G.DataModelMgr.PlayerDataModel:SetPlayerBigWorldPetTeamMainIndex(teamIdx)
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.PET_TEAM_CHANGE)
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, self.CurThroowSelectInfo.selectIdx, petData)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, self.CurThroowSelectInfo.selectIdx)
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList, true)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, teamIdx, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
    panel.Switcher.Slot:SetZOrder(0)
    panel.Switcher:SetActiveWidgetIndex(0)
    panel.UMG_MainPet:UpdateThrowPetCanClick(false)
    panel.MainPetScrollList:UpdateThrowPetCanClick(false)
    self.CurThroowSelectInfo = nil
  end
end

return MainUIModule
