local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local TipsDisplayCoordinator = require("NewRoco.Modules.System.TipsModule.TipsDisplayCoordinator")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipUtils = require("NewRoco.Modules.System.TipsModule.Utils.TipUtils")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local CampingUtils = require("NewRoco.Modules.System.Camping.CampingUtils")
local PriorityQueue = require("Utils.PriorityQueue")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local NRCPanelDynamicData = require("Core.NRCPanel.NRCPanelDynamicData")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local JsonUtils = require("Common.JsonUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local TipsModule = NRCModuleBase:Extend("TipsModule")

function TipsModule:OnConstruct()
  _G.TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
  self.LoginModule = self
  self.LogoutTime = nil
  self.ResidueTimeRemind = nil
  self.IsCanPVP = true
  self.URLModal = nil
  self.isHasExtraReward = false
  self.bReConnectPopUp = false
  self.TipsCoordinator = TipsDisplayCoordinator(self)
  self.DialogOkText = nil
  self.TipsDisplayControllers = {}
  self.dialogPq = PriorityQueue()
  self.dialogPq:SetCmpFunction(function(a, b)
    return a.context.priority < b.context.priority
  end)
  self.dialogInitStatus = {
    isDialogCreating = false,
    isDialog1Creating = false,
    isDialog2Creating = false
  }
  self.curNetworkContext = nil
  self.networkContextQueue = PriorityQueue()
  self.networkContextQueue:SetCmpFunction(function(a, b)
    return a.priority < b.priority
  end)
  self.instructionType = nil
  local closeTabConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
  if closeTabConf then
    self.CloseTabConfs = closeTabConf:GetAllDatas()
  end
  TipUtils.CreteTipsDisplayController(TipEnum.TipObjectType.LeaderFight, self, self.DoCmdOpenLeaderFight)
  self.TipHandlers = {
    [TipEnum.TipObjectType.TopHudTips] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
      if tip.tipCustomType == TipEnum.TopHudTipsType.ExpTips then
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowLevelUpMain, tip)
        _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.PlayerLevelChange, tip.customData)
      end
    end,
    [TipEnum.TipObjectType.TaskAccept] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
    end,
    [TipEnum.TipObjectType.TaskComplete] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
    end,
    [TipEnum.TipObjectType.DungeonCompleted] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
    end,
    [TipEnum.TipObjectType.DungeonStateCompleted] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
    end,
    [TipEnum.TipObjectType.HandbookTopic] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShowHandbookTopicTips, tip)
    end,
    [TipEnum.TipObjectType.TaskUpdate] = function(tip)
      _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.Tips_LobbyMainTaskUpdate, tip)
    end,
    [TipEnum.TipObjectType.IncreaseUseCount] = function(tip)
      self:DoCmdShowTips(tip:GetDescription())
    end,
    [TipEnum.TipObjectType.AmplifyUseEffect] = function(tip)
      self:DoCmdShowTips(tip:GetDescription())
    end,
    [TipEnum.TipObjectType.LeaderFight] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.StampsChange] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenUnlockGuidBook, tip)
    end,
    [TipEnum.TipObjectType.PetBallCatchAward] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.SetBagChangeInfo, tip.source, tip.CmdID, nil, tip.Timestamp)
    end,
    [TipEnum.TipObjectType.MiracleExchange] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_MiracleExchange, tip)
    end,
    [TipEnum.TipObjectType.HandbookChange] = function(tip)
      _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OpenWorldHandbook, tip)
    end,
    [TipEnum.TipObjectType.Reward] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.PlayRewardTips, tip)
    end,
    [TipEnum.TipObjectType.LobbyDownTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.MainPetTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.LobbyRegionPreUpdate] = function(tip)
      _G.NRCEventCenter:DispatchEvent(TipsModuleEvent.Tips_LobbyRegionPreUpdate, tip.customData, self.TipsCoordinator)
    end,
    [TipEnum.TipObjectType.RolePlayGetTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.LegendaryTaskUnlockTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.MusicCollectUnlockTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.NPCRosterTips] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenNPCRosterTip, tip)
    end,
    [TipEnum.TipObjectType.TaskSummary] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.MonthlyCardDailyRewardTips] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenMonthlyCardTips, tip)
    end,
    [TipEnum.TipObjectType.TaskReturnReward] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.TeachingUnlockTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.PetCertification] = function(tip)
      self:DispatchEvent(TipsModuleEvent.TopHud_AddTips, tip)
    end,
    [TipEnum.TipObjectType.ReceiveBPGiftTips] = function(tip)
      self:SendTipToDisplayController(tip)
    end,
    [TipEnum.TipObjectType.SeasonBeginsTips] = function(tip)
      local Ban = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, false, false, false)
      if Ban then
        Log.Info("TipsModule TipHandlers SeasonBeginsTips IsBan MarkFinished")
        tip:MarkFinished()
        self.seasonBeginsTip = tip
      else
        _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.ShowSeasonBeginsTips, tip)
      end
    end,
    [TipEnum.TipObjectType.ActivityCommonOpenTips] = function(tip)
      _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.TryShowActivityCommonOpenTips, tip.customData.activityId, tip)
    end
  }
end

function TipsModule:OnDestruct()
  self.instructionType = nil
  self.TipsCoordinator:Free()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_HOPE_NOTIFY, self.OnScreenTimeNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_MARQUEE_PLAY_NOTIFY, self.OnZoneMarqueePlayNotify)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ERROR_TIPS_NOTIFY, self.OnZoneErrorCodeNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnReceiveLoginRetOutside, self.OnReceiveLoginRetOutside)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.FinishAntiAddictionTips, self.AntiAddictionFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  _G.NRCEventCenter:UnRegisterEvent(self, TipsModuleEvent.CheckMainPetTips, self.CheckMainPetTips)
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, self, self.CheckSeasonBeginTips)
end

function TipsModule:OnActive()
  self:RegPanel("UMG_TopHUD", "UMG_TopHUD", Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("UMG_Dialog", "UMG_Dialog", Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("UMG_Dialog_IdIp", "UMG_Dialog", Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("UMG_Dialog_PopUp", "UMG_Dialog", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_Dialog_OnlyForNetwork", "UMG_Dialog", Enum.UILayerType.UI_LAYER_ONLY_FOR_NETWORK)
  self:RegPanel("UMG_DialogWithBase", "UMG_DialogWithBase", Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("UMG_Dialog2", "UMG_Dialog", Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("UMG_Dialog_Details", "UMG_Dialog1", Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, true)
  self:RegPanel("UMG_Dialog_PopUpDetails", "UMG_Dialog1_PopUp", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UMG_LongDialog", "UMG_LongDialog", Enum.UILayerType.UI_LAYER_TOP_MSG)
  self:RegPanel("UMG_LongPopUpDialog", "UMG_LongDialog_PopUp", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("UMG_Common_Tips", "UMG_Common_Tips", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UMG_PetFeatureTips", "Tips/UMG_PetFeatureTips", Enum.UILayerType.UI_LAYER_POPUP)
  local RegisterData = self:RegPanel("UMG_Input_Blocker", "UMG_Input_Blocker", Enum.UILayerType.UI_LAYER_TOP_MSG, _G.NRCPanelRegisterData.PanelCacheType.PreCache, nil, false)
  RegisterData.autoSetDesiredCursor = false
  self:RegPanel("LeaderFightTips", "Tips/UMG_BossTips", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("ConfirmTeleportTips", "Tips/UMG_ConfirmTeleportTip", Enum.UILayerType.UI_LAYER_TOP, nil, nil, true)
  self:RegPanel("BagChangeBall", "UMG_ChangeBall_Dialog", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ZoneTip", "Tips/UMG_ZoneTip", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("AntiAddiction_PullDown", "UMG_AntiAddiction_PullDown", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("AntiAddiction", "UMG_AntiAddiction", Enum.UILayerType.UI_LAYER_TOP_MARK, nil, nil, false)
  self:RegPanel("LoadingProgressTip", "UMG_LoadingProgress", Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, true)
  self:RegPanel("MarqueePanel", "UMG_Marquee", Enum.UILayerType.UI_LAYER_TOP_MSG, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("MagicDetailTips", "UMG_Magic_DetailsTips", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("FruitTreeTips", "Tips/UMG_FruittreeTips", Enum.UILayerType.UI_LAYER_POPUP):SetEnableTouchMask(false)
  local TapTapData = self:RegPanel("TapTapTips", "UMG_TapTap_PopUp", Enum.UILayerType.UI_LAYER_TOP_MSG)
  TapTapData.openAnimName = "In"
  TapTapData.closeAnimName = "Out"
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_HOPE_NOTIFY, self.OnScreenTimeNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_MARQUEE_PLAY_NOTIFY, self.OnZoneMarqueePlayNotify)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_ERROR_TIPS_NOTIFY, self.OnZoneErrorCodeNotify)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, LoginModuleEvent.OnReceiveLoginRetOutside, self.OnReceiveLoginRetOutside)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, SceneEvent.OnPlayerDead, self.OnPlayerDead)
  NRCEventCenter:RegisterEvent("TipsModule", self, SceneEvent.OnRelogin, self.OnReLoginUpdate)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, TipsModuleEvent.FinishAntiAddictionTips, self.AntiAddictionFinish)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.OnWebViewOptNotify)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:RegisterEvent("TipsModule", self, TipsModuleEvent.CheckMainPetTips, self.CheckMainPetTips)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_SEASON_AE_SHOW, self, self.CheckSeasonBeginTips)
  local PetPropertyData = _G.NRCPanelRegisterData()
  PetPropertyData.panelName = "UMG_PetUIBackpackTips"
  PetPropertyData.panelPath = "/Game/NewRoco/Modules/System/PetUI/Res/Backpack/UMG_PetUIBackpackTips"
  PetPropertyData.panelLayer = Enum.UILayerType.UI_LAYER_POPUP
  self:RegisterPanel(PetPropertyData)
  local PetCharacterData = _G.NRCPanelRegisterData()
  PetCharacterData.panelName = "UMG_Tips1"
  PetCharacterData.panelPath = "/Game/NewRoco/Modules/System/PetUI/Res/Backpack/UMG_Tips1"
  PetCharacterData.panelLayer = Enum.UILayerType.UI_LAYER_TOP
  self:RegisterPanel(PetCharacterData)
  local PetCharacterRateData = _G.NRCPanelRegisterData()
  PetCharacterRateData.panelName = "UMG_PetRateTip"
  PetCharacterRateData.panelPath = "/Game/NewRoco/Modules/System/PetUI/Res/Backpack/UMG_PetRateTip"
  PetCharacterRateData.panelLayer = Enum.UILayerType.UI_LAYER_TOP
  self:RegisterPanel(PetCharacterRateData)
  local CommonWarningTips = _G.NRCPanelRegisterData()
  CommonWarningTips.panelName = "CommonWarningTips"
  CommonWarningTips.panelPath = "/Game/NewRoco/Modules/System/Common/res/UMG_Common_Warning"
  CommonWarningTips.panelLayer = Enum.UILayerType.UI_LAYER_POPUP
  self:RegisterPanel(CommonWarningTips)
  local MagicData = _G.NRCPanelRegisterData()
  MagicData.panelName = "MagicTips"
  MagicData.panelPath = "/Game/NewRoco/Modules/System/NPC/Res/UMG_SleepingOwlSanctuary_Unlock"
  MagicData.panelLayer = Enum.UILayerType.UI_LAYER_POPUP
  self:RegisterPanel(MagicData)
  self:OpenPanel("UMG_TopHUD")
end

function TipsModule:OpenDialogWithBase(DialogContext)
  if not DialogContext then
    Log.Error("TipsModule:OpenDialogWithBase DialogContext is nil")
    return
  end
  self:OpenPanel("UMG_DialogWithBase", DialogContext)
end

function TipsModule:RegPanel(name, path, layer, cacheType, customDisableRendering, disablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/TipsModule/Res/%s", path)
  registerData.panelLayer = layer
  registerData.panelCacheType = cacheType or _G.NRCPanelRegisterData.PanelCacheType.DonntCache
  registerData.customDisableRendering = customDisableRendering or false
  registerData.enablePcEsc = not disablePcEsc
  self:RegisterPanel(registerData)
  return registerData
end

function TipsModule:AddTip(tip, cmdId)
  if tip then
    self.TipsCoordinator:AddTip(tip, cmdId)
  end
end

function TipsModule:ShowTip(tip)
  local handler = self.TipHandlers[tip.tipType]
  if handler then
    handler(tip, self)
  else
    tip:MarkFinished()
  end
end

function TipsModule:PauseTip(reason)
  self.TipsCoordinator:Pause(reason)
end

function TipsModule:ResumeTip(reason)
  self.TipsCoordinator:Resume(reason)
end

function TipsModule:RegisterDisplayController(controller)
  local tipType = controller and controller:GetTipType()
  if not tipType then
    return
  end
  if self.TipsDisplayControllers[tipType] then
    Log.ErrorFormat("[tipType=%d]\229\183\178\231\187\143\229\173\152\229\156\168\230\142\167\229\136\182\229\153\168\239\188\140\233\187\152\232\174\164\232\166\134\231\155\150!", tipType)
  end
  self.TipsDisplayControllers[tipType] = controller
end

function TipsModule:UnRegisterDisplayController(controller)
  local tipType = controller and controller:GetTipType()
  if not tipType then
    return
  end
  self.TipsDisplayControllers[tipType] = nil
end

function TipsModule:GetDisplayController(tipType)
  if not tipType then
    return
  end
  return self.TipsDisplayControllers[tipType]
end

function TipsModule:HasDisplayingTip(area)
  return self.TipsCoordinator:HasDisplayingTip(area)
end

function TipsModule:SetTipAreaBlock(area, block, flag)
  self.TipsCoordinator:SetTipAreaBlock(area, block, flag)
end

function TipsModule:IsTipDisplayAreaBlock(tip)
  return self.TipsCoordinator:IsTipDisplayAreaBlock(tip)
end

function TipsModule:SendTipToDisplayController(tip)
  if not tip then
    return
  end
  local displayController = self:GetDisplayController(tip.tipType)
  if displayController then
    if not displayController:AddDisplayTip(tip) then
      tip:MarkFinished()
      Log.ErrorFormat("[tipType=%d]\230\183\187\229\138\160\230\152\190\231\164\186tip\229\164\177\232\180\165!", tip.tipType)
    end
  else
    tip:MarkFinished()
    Log.ErrorFormat("[tipType=%d]\230\156\170\230\179\168\229\134\140\230\142\167\229\136\182\229\153\168!", tip.tipType)
  end
end

function TipsModule:DoCmdShowTips(content, delay, Color, showTime, isNotHide, bAsImportTips)
  self:DispatchEvent(TipsModuleEvent.TopHud_ShowTips, content, delay, Color, showTime, isNotHide, bAsImportTips)
end

function TipsModule:DoCmdHideTips()
  self:DispatchEvent(TipsModuleEvent.TopHud_HideTips)
end

function TipsModule:Opendblocker(data, openType)
  self:DispatchEvent(TipsModuleEvent.Opendblocker)
  self:OpenPanel("UMG_Tips1", data, openType)
end

function TipsModule:Closeblocker()
  self:ClosePanel("UMG_Tips1")
end

function TipsModule:OpendPetRateTips(data, openType, ...)
  self:OpenPanel("UMG_PetRateTip", data, openType, ...)
end

function TipsModule:HideTipsPanel(...)
  if self:HasPanel("UMG_Tips1") then
    self:DisablePanel("UMG_Tips1")
  end
  if self:HasPanel("UMG_PetRateTip") then
    self:DisablePanel("UMG_PetRateTip")
  end
end

function TipsModule:CloseTipsPanel(...)
  if self:HasPanel("UMG_Tips1") then
    self:ClosePanel("UMG_Tips1")
  end
  if self:HasPanel("UMG_PetRateTip") then
    self:ClosePanel("UMG_PetRateTip")
  end
end

function TipsModule:ShowTipsPanel(...)
  if self:HasPanel("UMG_Tips1") then
    self:EnablePanel("UMG_Tips1")
  end
  if self:HasPanel("UMG_PetRateTip") then
    self:EnablePanel("UMG_PetRateTip")
  end
end

function TipsModule:DoCmdOpenMagicTips(_Param)
  self:AddTip(TipObject.CreateMagicUnlockTip(_Param))
end

function TipsModule:OpenPetTips(data)
  self:DispatchEvent(TipsModuleEvent.Tips_OpenPetTips)
  self:OpenPanel("UMG_PetUIBackpackTips", data)
end

function TipsModule:ClosePetTips()
  self:DispatchEvent(TipsModuleCmd.Tips_ClosePetTips)
  self:ClosePanel("UMG_PetUIBackpackTips")
end

function TipsModule:OpenPetFeatureTips(data)
  self:DispatchEvent(TipsModuleEvent.Tips_OpenPetFeatureTips)
  self:OpenPanel("UMG_PetFeatureTips", data)
end

function TipsModule:ClosePetFeatureTips()
  self:DispatchEvent(TipsModuleCmd.ClosePetFeatureTips)
  self:ClosePanel("UMG_PetFeatureTips")
end

function TipsModule:IsOpenAllTips(_IsShow)
  if _IsShow then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.IsShowDownTips, true, "TipsModuleOpenAllTips")
    self:IsShowZoneTip(true)
  else
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.IsShowDownTips, false, "TipsModuleOpenAllTips")
    self:IsShowZoneTip(false)
  end
end

function TipsModule:DoCmdShowEnterMapTips(name, area)
  self:DispatchEvent(TipsModuleEvent.TopHud_ShowMapTips, name, area)
end

function TipsModule:DoCmdShowLevelUpTips(level)
  self:DispatchEvent(TipsModuleEvent.TopHud_ShowLevelUpTips, level)
end

function TipsModule:DoCmdShowConfirmTeleportTips(CompOwner)
  self:OpenPanel("ConfirmTeleportTips", CompOwner)
end

function TipsModule:CmdHasConfirmTeleportTips()
  return self:HasPanel("ConfirmTeleportTips")
end

function TipsModule:DoCmdShowCommonWarning(data)
  self:OpenPanel("CommonWarningTips", data)
end

function TipsModule:DoCmdOpenBagChangeBallPanel(equipBallList)
  self:OpenPanel("BagChangeBall", equipBallList)
end

function TipsModule:DoCmdOpenDialog(DialogContext, bReconnect, Layer)
  if not DialogContext then
    Log.Error("TipsModule:DoCmdOpenDialog DialogContext is nil")
    return false
  end
  if self.bReConnectPopUp == false then
    local queueElement = {
      dialogType = 0,
      context = DialogContext,
      layer = Layer
    }
    self.dialogPq:EnQueue(queueElement)
    self:TryShowDialog()
    return true
  end
  if DialogContext.bReconnect == true then
    self.bReConnectPopUp = true
  end
  return false
end

function TipsModule:DoCmdOpenDialog2(DialogContext, Timer, Time, bReconnect)
  if not DialogContext then
    Log.Error("TipsModule:DoCmdOpenDialog2 DialogContext is nil")
    return false
  end
  if self.bReConnectPopUp == false then
    local queueElement = {
      dialogType = 2,
      context = DialogContext,
      timer = Timer,
      time = Time
    }
    self.dialogPq:EnQueue(queueElement)
    self:TryShowDialog()
    return true
  end
  if DialogContext.bReconnect == true then
    self.bReConnectPopUp = true
  end
  return false
end

function TipsModule:OpenDialog(DialogContext, Layer)
  if not DialogContext then
    Log.Error("TipsModule:OpenDialog DialogContext is nil")
    return
  end
  if Layer and Layer == Enum.UILayerType.UI_LAYER_POPUP then
    local isOpening, _ = self:HasPanel("UMG_Dialog_PopUp")
    if isOpening then
      local DialogCtrl = self:GetPanel("UMG_Dialog_PopUp")
      if DialogCtrl and UE.UObject.IsValid(DialogCtrl) and (DialogCtrl:GetVisibility() == UE4.ESlateVisibility.Collapsed or DialogCtrl.isClosing == true) then
        DialogCtrl:TryOpen()
        self:EnablePanel("UMG_Dialog_PopUp")
        DialogCtrl:SetContext(DialogContext)
      else
        self:ClosePanel("UMG_Dialog_PopUp")
        self:OpenPanel("UMG_Dialog_PopUp", DialogContext)
      end
    else
      self:OpenPanel("UMG_Dialog_PopUp", DialogContext)
    end
  else
    local isOpening, _ = self:HasPanel("UMG_Dialog")
    if isOpening then
      local DialogCtrl = self:GetPanel("UMG_Dialog")
      if DialogCtrl and UE.UObject.IsValid(DialogCtrl) and (DialogCtrl:GetVisibility() == UE4.ESlateVisibility.Collapsed or DialogCtrl.isClosing == true) then
        DialogCtrl:TryOpen()
        self:EnablePanel("UMG_Dialog")
        DialogCtrl:SetContext(DialogContext)
      else
        self:ClosePanel("UMG_Dialog")
        self:OpenPanel("UMG_Dialog", DialogContext)
      end
    else
      self.dialogInitStatus.isDialogCreating = true
      NRCProfilerLog:NRCClickBtn(true, "UMG_Dialog")
      self:OpenPanel("UMG_Dialog", DialogContext)
    end
  end
end

function TipsModule:TryShowDialog()
  if self:IsHasDialogPanel() then
    return
  end
  self.isShowDialog = true
  self:CheckIFHasShouldOpenDialog()
end

function TipsModule:CheckIFHasShouldOpenDialog()
  if not self.dialogPq then
    return
  end
  if self.dialogInitStatus.isDialogCreating then
    self.dialogInitStatus.isDialogCreating = false
    return
  end
  if self.dialogInitStatus.isDialog2Creating then
    self.dialogInitStatus.isDialog2Creating = false
    return
  end
  if self.dialogPq:GetTop() then
    local element = self.dialogPq:DeQueue()
    if element.context.panelName and element.context.panelName == "UMG_Dialog_IdIp" then
      self:OpenDialog1(element.context, element.context.panelName)
      return
    end
    if 0 == element.dialogType then
      self:OpenDialog(element.context, element.layer)
    elseif 1 == element.dialogType then
      self:OpenDialog1(element.context, element.panelName)
    elseif 2 == element.dialogType then
      self:OpenDialog2(element.context)
    end
  end
end

function TipsModule:OpenDialog2(DialogContext, Timer, Time)
  if not DialogContext then
    Log.Error("TipsModule:OpenDialog2 DialogContext is nil")
    return
  end
  local isOpening, _ = self:HasPanel("UMG_Dialog2")
  if isOpening then
    local DialogCtrl = self:GetPanel("UMG_Dialog2")
    if DialogCtrl and UE.UObject.IsValid(DialogCtrl) and (DialogCtrl:GetVisibility() == UE4.ESlateVisibility.Collapsed or DialogCtrl.isClosing == true) then
      DialogCtrl:TryOpen()
      self:EnablePanel("UMG_Dialog2")
      DialogCtrl:SetContext(DialogContext)
    else
      self:ClosePanel("UMG_Dialog2")
      self:OpenPanel("UMG_Dialog2")
    end
  else
    self.dialogInitStatus.isDialog2Creating = true
    self:OpenPanel("UMG_Dialog2", DialogContext)
  end
end

function TipsModule:DoCmdOpenDialogDetails(DialogContext, Layer)
  if not DialogContext then
    Log.Error("TipsModule:DoCmdOpenDialogDetails DialogContext is nil")
    return
  end
  local PanelName = "UMG_Dialog_Details"
  if Layer == Enum.UILayerType.UI_LAYER_POPUP then
    PanelName = "UMG_Dialog_PopUpDetails"
  end
  local queueElement = {
    dialogType = 1,
    context = DialogContext,
    panelName = PanelName
  }
  self.dialogPq:EnQueue(queueElement)
  self:TryShowDialog()
end

function TipsModule:OpenDialog1(context, panelName)
  self:ClosePanel(panelName)
  self:OpenPanel(panelName, context)
end

function TipsModule:DoCmdCloseDialogDetails()
  self:ClosePanel("UMG_Dialog_Details")
end

function TipsModule:IsHasDialogPanel()
  local finalResult = false
  local bIsOpening, _ = self:HasPanel("UMG_Dialog")
  if bIsOpening then
    local DialogCtrl = self:GetPanel("UMG_Dialog")
    if bIsOpening and DialogCtrl.enableView and not DialogCtrl.isClosing then
      finalResult = true
    end
  end
  local bIsOpening1, _ = self:HasPanel("UMG_Dialog_Details")
  if bIsOpening1 then
    local panel = self:GetPanel("UMG_Dialog_Details")
    if panel then
      bIsOpening1 = not panel.isClosing
    end
  end
  finalResult = finalResult or bIsOpening1
  local bIsOpening2, _ = self:HasPanel("UMG_Dialog2")
  if bIsOpening2 then
    local DialogCtrl = self:GetPanel("UMG_Dialog2")
    if bIsOpening2 and DialogCtrl.enableView and not DialogCtrl.isClosing then
      finalResult = true
    end
  end
  return finalResult
end

function TipsModule:DoCmdSetDialogCallBack(CallBack, TipsContent, owner)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local dialogContext = DialogContext()
  dialogContext:SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetCloseOnCancel(true):SetCallback(owner, CallBack)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
end

function TipsModule:DoCmdDisableDialog()
  self:DisablePanel("UMG_Dialog")
end

function TipsModule:DoCmdDisableShouldCloseDialog()
  if self:HasPanel("UMG_Dialog") then
    local panel = self:GetPanel("UMG_Dialog")
    if panel and panel.context and panel.context.CloseFlag == true then
      self:DisablePanel("UMG_Dialog")
    end
  end
end

function TipsModule:Dialog_OpenLongDialog(DialogContext, Layer)
  if not DialogContext then
    Log.Error("TipsModule:Dialog_OpenLongDialog DialogContext is nil")
    return
  end
  local PanelName = "UMG_LongDialog"
  if Layer == Enum.UILayerType.UI_LAYER_POPUP then
    PanelName = "UMG_LongPopUpDialog"
  end
  local isOpening, _ = self:HasPanel(PanelName)
  if isOpening then
    local DialogCtrl = self:GetPanel(PanelName)
    if DialogCtrl then
      DialogCtrl:TryOpen()
      self:EnablePanel(PanelName)
      DialogCtrl:SetContext(DialogContext)
    end
  else
    self:OpenPanel(PanelName, DialogContext)
  end
end

function TipsModule:Dialog_CloseLongDialog()
  if self:HasPanel("UMG_LongDialog") then
    self:ClosePanel("UMG_LongDialog")
  end
end

function TipsModule:DoCmdOpenLeaderFight()
  self:OpenPanel("LeaderFightTips")
end

function TipsModule:DoCmdCloseLeaderFight()
  self:ClosePanel("LeaderFightTips")
end

function TipsModule:OnShowZoneTip(zoneId, action)
  if action.Conf and action.Conf.name and action.Conf.broadcast_type then
    self:AddTip(TipObject.CreateZoneTip(zoneId, action))
  end
end

function TipsModule:OnShowActivityZoneTip(desc)
  self:AddTip(TipObject.CreateActivityZoneTip(desc))
end

function TipsModule:OnShowEnterHomeZoneTip(customData)
  self:AddTip(TipObject.CreateEnterHomeZoneTip(customData))
end

function TipsModule:OnShowAddHomeExpTip(customData)
  self:AddTip(TipObject.CreateAddHomeExpTip(customData))
end

function TipsModule:OnShowHomeExpandTip(bFinish)
  self:AddTip(TipObject.CreateHomeExpandTip(bFinish))
end

function TipsModule:OnShowContinuousCatchTip(customData)
  self:AddTip(TipObject.CreateCatchPetTip(customData))
end

function TipsModule:IsShowZoneTip(_IsShow)
  local HasPanel = self:HasPanel("ZoneTip")
  if HasPanel then
    local Panel = self:GetPanel("ZoneTip")
    Panel:IsShowPanel(_IsShow)
  end
end

function TipsModule:OnCmdClearTopHudTipsList()
  self:DispatchEvent(TipsModuleEvent.TopHud_ClearTipsList)
end

function TipsModule:ShowPropTips(tip, CmdID)
  self:AddTip(tip, CmdID)
end

function TipsModule:PushRetInfo(RspCmdID, RetInfo, OverrideTag)
  self:CardInfoPlayFirstGet(RetInfo.goods_reward)
  if RetInfo.goods_reward then
    RetInfo.goods_reward.rewards = self:SortRewards(RetInfo.goods_reward.rewards)
  end
  local ValidCmd = {
    ProtoCMD.ZoneSvrCmd.ZONE_SCENE_GUIDE_BOOK_NOTIFY,
    ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY
  }
  local Rewards = RetInfo.goods_reward and RetInfo.goods_reward.rewards
  if not table.contains(ValidCmd, RspCmdID) and not Rewards then
    return
  end
  local IgnoreCmd = {
    ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_NPC_LOTTERY_GOODS_REWARD_NOTIFY
  }
  if table.contains(IgnoreCmd, RspCmdID) then
    return
  end
  if Rewards then
    local RewardFlowReason2OverrideCmd = {
      [ProtoEnum.FlowReason.FLOW_REASON_TASK_REWARD] = ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY
    }
    for _, reward in ipairs(Rewards) do
      if 6 == reward.tag then
        self.isHasExtraReward = true
        break
      end
    end
    if self.isHasExtraReward then
      local firstRewards = {}
      local secondRewards = {}
      local leaderFightExtraRewards = {}
      local Items = {}
      for i, reward in ipairs(Rewards) do
        if 0 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_AWARD_USE_STAR then
          table.insert(firstRewards, reward)
        elseif 6 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_AWARD_USE_STAR then
          table.insert(secondRewards, reward)
        elseif 0 == reward.tag and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_LEADER_FIGHT_EXTRA_REWARD then
          table.insert(leaderFightExtraRewards, reward)
        end
      end
      
      local function Sorter(a, b)
        if a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
          local vItemConfA = _G.DataConfigManager:GetVisualItemConf(a.id)
          local vItemConfB = _G.DataConfigManager:GetVisualItemConf(b.id)
          if not vItemConfA then
            return true
          end
          if not vItemConfB then
            return false
          end
          return vItemConfA.sort_id < vItemConfB.sort_id
        elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
          local BagItemConfA = _G.DataConfigManager:GetBagItemConf(a.id)
          local BagItemConfB = _G.DataConfigManager:GetBagItemConf(b.id)
          if not BagItemConfA then
            return true
          end
          if not BagItemConfB then
            return false
          end
          return BagItemConfA.sort_id < BagItemConfB.sort_id
        elseif a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
          return true
        elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
          return false
        else
          return a.id < b.id
        end
      end
      
      table.sort(firstRewards, Sorter)
      table.sort(leaderFightExtraRewards, Sorter)
      table.sort(secondRewards, Sorter)
      table.move(firstRewards, 1, #firstRewards, #Items + 1, Items)
      table.move(leaderFightExtraRewards, 1, #leaderFightExtraRewards, #Items + 1, Items)
      table.move(secondRewards, 1, #secondRewards, #Items + 1, Items)
      _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.SetSelectRecoveryItem, nil)
      if Items[1] and Items[1].reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_BATTLE_SETTLEMENT and _G.NPCShopUIModuleCmd then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, Items, LuaText.battlepassmodule_4, nil, true, nil, true)
      end
      self.isHasExtraReward = false
    else
      if Rewards[1].reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_ACTIVITY_STAGE then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, Rewards, LuaText.battlepassmodule_4, nil, true)
        return
      end
      if Rewards[1].reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_HOME_PET_STEAL and _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor() then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.home_kanban_guest_steal_success, Rewards[1].num))
      end
      
      local function AddTips(reward)
        local tip = TipObject.FromGoodsItem(reward, RspCmdID)
        if tip then
          local OverrideCmd = RewardFlowReason2OverrideCmd[reward.reward_reason]
          if OverrideCmd and OverrideCmd ~= RspCmdID then
            tip.UpdateCmdId = OverrideCmd
          end
          self:AddTip(tip, RspCmdID)
        end
      end
      
      for k, reward in ipairs(Rewards) do
        if reward.tag == ProtoEnum.GoodsDsiplayTag.NARMAL_SHOW or OverrideTag then
          AddTips(reward)
        end
        if reward.type == ProtoEnum.GoodsType.GT_RP_BEHAVIOR and _G.RolePlayModuleCmd then
          _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ShowGetNewRolePlayTips, reward.id)
        end
        if reward.reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_MONTH_CARD_SIG then
          local ShopModule = _G.NRCModuleManager:GetModule("ShopModule")
          if _G.ShopModuleCmd and ShopModule then
            _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.TryOpenMonthCardTips, reward, k)
          else
            self.monthCardTipsCache = {reward = reward, index = k}
          end
        end
        if reward.tag == Enum.RewardTag.RTA_ACTIVITY and reward.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_ACTIVITY_DROP then
          Log.Debug("TipsModule:PushRetInfo --- RspCmdID, ItemId, ItemNum, ItemType: ", RspCmdID, reward.id, reward.num, reward.type)
          AddTips(reward)
        end
        if reward.tag == Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
          AddTips(reward)
        end
      end
    end
  end
  self:AddTip(TipObject.CreateLobbyRegionPreUpdateTip(RspCmdID))
end

function TipsModule:TryGetCardTipsCache()
  return self.monthCardTipsCache
end

function TipsModule:CardInfoPlayFirstGet(goods_reward)
  local Rewards = goods_reward and goods_reward.rewards
  local CardLabelList = {}
  if Rewards then
    for i = #Rewards, 1, -1 do
      if Rewards[i] then
        if Rewards[i].type == ProtoEnum.GoodsType.GT_CARD_ICON or Rewards[i].type == ProtoEnum.GoodsType.GT_CARD_SKIN or Rewards[i].type == ProtoEnum.GoodsType.GT_CARD_LABEL then
          if Rewards[i].first_get == false then
            table.remove(Rewards, i)
          elseif Rewards[i].type == ProtoEnum.GoodsType.GT_CARD_LABEL then
            local CardLabel = _G.DataConfigManager:GetCardLabelConf(Rewards[i].id)
            if CardLabel and CardLabel.label_type == Enum.LabelType.LT_LAST then
              local LastLabel = table.remove(Rewards, i)
              CardLabelList[LastLabel.id] = LastLabel
            end
          end
        elseif Rewards[i].type == ProtoEnum.GoodsType.GT_VITEM then
          if Rewards[i].id == Enum.VisualItem.VI_PET_ENERGY then
            table.remove(Rewards, i)
          elseif Rewards[i].id == Enum.VisualItem.VI_STAR then
            table.remove(Rewards, i)
          elseif 0 == Rewards[i].num then
            table.remove(Rewards, i)
          elseif Rewards[i].id == Enum.VisualItem.VI_BOTTLE_TIMES then
            table.remove(Rewards, i)
          else
            local viItemConf = _G.DataConfigManager:GetVisualItemConf(Rewards[i].id)
            if viItemConf and viItemConf.is_no_display_in_main and 1 == viItemConf.is_no_display_in_main then
              table.remove(Rewards, i)
            end
          end
        elseif Rewards[i].type == ProtoEnum.GoodsType.GT_ATTRTYPE or Rewards[i].type == ProtoEnum.GoodsType.GT_CONTENT_NPC then
          table.remove(Rewards, i)
        elseif Rewards[i].type == ProtoEnum.GoodsType.GT_BAGITEM then
          local BagItemConf = _G.DataConfigManager:GetBagItemConf(Rewards[i].id)
          if BagItemConf and BagItemConf.is_no_display_in_main and 1 == BagItemConf.is_no_display_in_main then
            table.remove(Rewards, i)
          end
        end
      end
    end
    for i = #Rewards, 1, -1 do
      if Rewards[i].type == ProtoEnum.GoodsType.GT_CARD_LABEL then
        local CardLabel = _G.DataConfigManager:GetCardLabelConf(Rewards[i].id)
        if CardLabel and CardLabel.label_type == Enum.LabelType.LT_FIRST and CardLabelList[CardLabel.unlock_map] then
          Rewards[i].rewards = CardLabelList[CardLabel.unlock_map]
        end
      end
    end
  end
end

function TipsModule:SortRewards(_Rewards)
  if not _Rewards or 0 == #_Rewards then
    return
  end
  local SortRewardInfo = {}
  for i, Reward in ipairs(_Rewards) do
    table.insert(SortRewardInfo, Reward)
    SortRewardInfo[i].SortId = 0
    if Reward.type == ProtoEnum.GoodsType.GT_CARD_ICON then
      SortRewardInfo[i].SortId = 5
    elseif Reward.type == ProtoEnum.GoodsType.GT_CARD_SKIN then
      SortRewardInfo[i].SortId = 4
    elseif Reward.type == ProtoEnum.GoodsType.GT_CARD_LABEL then
      SortRewardInfo[i].SortId = 3
    elseif Reward.type == ProtoEnum.GoodsType.GT_BAGITEM then
      local BagItemConf = _G.DataConfigManager:GetBagItemConf(Reward.id)
      local ItemUnlockMapConf
      if BagItemConf then
        ItemUnlockMapConf = _G.DataConfigManager:GetItemUnlockMapConf(BagItemConf.id, true)
      end
      if Reward.first_get and BagItemConf and ItemUnlockMapConf and ItemUnlockMapConf.exchange_id and #ItemUnlockMapConf.exchange_id > 0 then
        SortRewardInfo[i].SortId = 2
      elseif Reward.first_get then
        SortRewardInfo[i].SortId = 1
      end
    end
  end
  table.sort(SortRewardInfo, function(a, b)
    if a.SortId > b.SortId then
      return a.SortId > b.SortId
    end
  end)
  for i, Reward in ipairs(SortRewardInfo) do
    Reward.SortId = nil
  end
  return SortRewardInfo
end

function TipsModule:TogglePropTips(on)
  if on then
    self.TipsCoordinator:Resume()
  else
    self.TipsCoordinator:Pause()
  end
end

function TipsModule:ShowGoodsReward(reward, CmdID)
  if not reward then
    return
  end
  if not reward.rewards then
    return
  end
  if 0 == #reward.rewards then
    return
  end
  self:CardInfoPlayFirstGet(reward)
  reward.rewards = self:SortRewards(reward.rewards)
  for _, sub in ipairs(reward.rewards) do
    local tip = TipObject.FromGoodsItem(sub, CmdID)
    if tip then
      self:AddTip(tip, CmdID)
    end
  end
end

function TipsModule:ShowPetChangeToWarehouse(PetChange, CmdID, BackpackInfo)
  local tip = TipObject.FromPetChangeToWarehouse(PetChange, BackpackInfo)
  if tip then
    self:AddTip(tip, CmdID)
    return true
  else
    return false
  end
end

function TipsModule:OpenItemTips(GoodsID, GoodsType, canCharge, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound, GoodsGID, AssignQuality, params)
  self:ClosePanel("UMG_Common_Tips")
  local data
  local bSpecialLogic = false
  if GoodsType == _G.Enum.GoodsType.GT_FASHION then
    local bUseAnyExtraFeature = not not canCharge or not not remainCnt or not not maxCnt or not not isBattleState or not not Position or not not overrideNum or not not Caller or not not CallBack or not not OpenCallBack
    if not bUseAnyExtraFeature then
      local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(GoodsID, true)
      if fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
        bSpecialLogic = true
        local context = {}
        context.bIsWand = true
        context.context = {}
        context.context.WandId = GoodsID
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
      elseif fashionItemConf and fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA then
        local bagCharmConf = _G.DataConfigManager:GetFashionBagcharmConf(GoodsID)
        if bagCharmConf and (bagCharmConf.charm_kind == _G.Enum.BagCharm.BGC_PETCHARM or bagCharmConf.charm_kind == _G.Enum.BagCharm.BGC_PACKAGECHARM) then
          bSpecialLogic = true
          local context = {}
          context.bIsPendanta = true
          context.context = {}
          context.context.itemId = GoodsID
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
        end
      else
        local suitId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetSuitIdFromFashionId, GoodsID)
        if suitId and 0 ~= suitId then
          bSpecialLogic = true
          _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, suitId, GoodsID)
        end
      end
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local bUseAnyExtraFeature = not not canCharge or not not remainCnt or not not maxCnt or not not isBattleState or not not Position or not not overrideNum or not not OpenCallBack
    if not bUseAnyExtraFeature then
      bSpecialLogic = true
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, GoodsID, nil, {Caller = Caller, CallBack = CallBack})
    end
  end
  if bSpecialLogic then
    return
  end
  if GoodsType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.DataConfigManager:GetBagItemConf(GoodsID)
    if nil ~= bagItem then
      local ownedNumber = 0
      local bagItemData = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItem.id)
      if nil ~= bagItemData then
        ownedNumber = bagItemData.num
      end
      if overrideNum then
        ownedNumber = overrideNum
      end
      local real_acquire_struct = {}
      for i = 1, #bagItem.acquire_struct do
        if nil == bagItem.acquire_struct[i].acquire_way_text then
          goto lbl_252
        elseif 0 == bagItem.acquire_struct[i].behavior_id then
          table.insert(real_acquire_struct, bagItem.acquire_struct[i])
        else
          table.insert(real_acquire_struct, bagItem.acquire_struct[i])
        end
        ::lbl_252::
      end
      local hideBagIcon, skillConf
      local itemName = bagItem.name
      local contentText = bagItem.description
      local eggData, updateTime
      if bagItem.type == Enum.BagItemType.BI_SKILL_MACHINE then
        local skillMachineid = bagItem.item_behavior[1].ratio[1]
        skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
        contentText = skillConf.desc
      elseif bagItem.type == Enum.BagItemType.BI_PLANT_SEED then
        hideBagIcon = true
      elseif bagItem.type == Enum.BagItemType.BI_PET_EGG or bagItem.type == Enum.BagItemType.BI_PET_FRUIT then
        local isHaveBook, eggItemName, eggItemDesc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, bagItem.id)
        if isHaveBook then
          itemName = eggItemName
          contentText = eggItemDesc
        end
        if GoodsGID then
          local BagItemData = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, GoodsGID)
          if BagItemData then
            if BagItemData.egg_data and BagItemData.egg_data.src and BagItemData.egg_data.src == _G.Enum.EggAcquireWayType.EAWT_BLESSING then
              local srcDes = string.format(LuaText.interactiontree_cifu_text_1, BagItemData.egg_data.from_player_name, BagItemData.egg_data.from_pet_name)
              contentText = string.format("%s%s", contentText, srcDes)
            end
            if not isHaveBook and BagItemData.egg_data and BagItemData.egg_data.precious_egg_type and BagItemData.egg_data.precious_egg_type == Enum.PreciousEggType.PET_PRECIOUS and not BagItemData.egg_data.random_egg_conf then
              itemName = LuaText.cifu_precious_petegg
            end
            if BagItemData.egg_data and BagItemData.egg_data.precious_egg_type and BagItemData.egg_data.precious_egg_type ~= Enum.PreciousEggType.PET_NONE and nil == AssignQuality then
              AssignQuality = 5
            end
            eggData = BagItemData.egg_data
            updateTime = BagItemData.update_time
          end
        end
      end
      if params and params.EggInfo then
        eggData = params.EggInfo
        if params.EggInfo.precious_egg_type and params.EggInfo.precious_egg_type ~= Enum.PreciousEggType.PET_NONE and nil == AssignQuality then
          AssignQuality = 5
        end
      end
      if canCharge then
        local iconPathCur
        if bagItem.type == Enum.BagItemType.BI_PLAYERSKILL then
          iconPathCur = bagItem.icon
        elseif remainCnt == maxCnt then
          iconPathCur = bagItem.icon
        elseif 0 == remainCnt then
          iconPathCur = bagItem.icon_charging1
        else
          iconPathCur = bagItem.icon_charging2
        end
        data = {
          title = itemName,
          content = contentText,
          flavor = bagItem.flavor_text,
          iconPath = iconPathCur,
          showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
          ownedNumber = ownedNumber,
          expireTime = bagItem.expire_time,
          position = Position,
          canCharge = canCharge,
          remainCnt = remainCnt,
          maxCnt = maxCnt,
          quality = AssignQuality or bagItem.item_quality,
          typeDesc = bagItem.type_desc,
          acquirePath = real_acquire_struct,
          isBattleState = isBattleState,
          Caller = Caller,
          CallBack = CallBack,
          skillConf = skillConf,
          eggData = eggData,
          updateTime = updateTime,
          OpenCallBack = OpenCallBack,
          isHideBagIcon = hideBagIcon,
          goodsId = GoodsID,
          goodsType = GoodsType
        }
      else
        data = {
          title = itemName,
          content = contentText,
          flavor = bagItem.flavor_text,
          iconPath = bagItem.icon,
          showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
          ownedNumber = ownedNumber,
          expireTime = bagItem.expire_time,
          position = Position,
          canCharge = canCharge,
          quality = AssignQuality or bagItem.item_quality,
          typeDesc = bagItem.type_desc,
          acquirePath = real_acquire_struct,
          isBattleState = isBattleState,
          Caller = Caller,
          CallBack = CallBack,
          skillConf = skillConf,
          eggData = eggData,
          updateTime = updateTime,
          OpenCallBack = OpenCallBack,
          isHideBagIcon = hideBagIcon,
          goodsId = GoodsID,
          goodsType = GoodsType
        }
      end
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_VITEM then
    local visualItem = _G.DataConfigManager:GetVisualItemConf(GoodsID)
    if nil ~= visualItem then
      local ownedNumber = _G.DataModelMgr.PlayerDataModel:GetVItemCount(visualItem.id)
      local real_acquire_struct = {}
      local count = #visualItem.acquire_struct
      for i = 1, count do
        if nil == visualItem.acquire_struct[i].acquire_way_text then
          goto lbl_550
        elseif 0 == visualItem.acquire_struct[i].behavior_id then
          table.insert(real_acquire_struct, visualItem.acquire_struct[i])
        else
          table.insert(real_acquire_struct, visualItem.acquire_struct[i])
        end
        ::lbl_550::
      end
      local desc = visualItem.discription
      local hideBagIcon = true
      if GoodsID == _G.Enum.VisualItem.VI_BP_EXP or GoodsID == _G.Enum.VisualItem.VI_BP_EXP_TASK then
        local bp_name = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.GetBattlePassName)
        if bp_name then
          desc = string.format(visualItem.discription, bp_name)
        end
      end
      data = {
        title = visualItem.displayName,
        content = desc,
        iconPath = visualItem.bigIcon,
        showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
        ownedNumber = ownedNumber,
        expireTime = nil,
        position = Position,
        canCharge = canCharge,
        quality = visualItem.item_quality,
        typeDesc = visualItem.displayName,
        typeDesc = visualItem.type_desc,
        acquirePath = real_acquire_struct,
        isBattleState = isBattleState,
        isHideBagIcon = hideBagIcon,
        Caller = Caller,
        CallBack = CallBack,
        OpenCallBack = OpenCallBack
      }
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_CARD_ICON then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(GoodsID)
    if nil ~= CardIconConf then
      local real_acquire_struct = {}
      local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
      local HeadIconPath = CardIconConf.icon_resource_path
      data = {
        title = CardIconConf.icon_resource_name,
        content = CardIconConf.item_description,
        flavor = CardIconConf.bottom_description,
        iconPath = string.format("%s%s.%s'", path, HeadIconPath, HeadIconPath),
        showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
        position = Position,
        canCharge = canCharge,
        remainCnt = remainCnt,
        maxCnt = maxCnt,
        quality = CardIconConf.card_quality,
        isHideBagIcon = true,
        ownedNumber = 0,
        acquirePath = real_acquire_struct,
        isBattleState = isBattleState,
        Caller = Caller,
        CallBack = CallBack,
        OpenCallBack = OpenCallBack
      }
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(GoodsID)
    if nil ~= CardLabelConf then
      local real_acquire_struct = {}
      local path = CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
      local typeDesc = CardLabelConf.label_type == Enum.LabelType.LT_FIRST and LuaText.card_label_des_type1 or LuaText.card_label_des_type2
      data = {
        title = CardLabelConf.label_text,
        content = CardLabelConf.item_description,
        flavor = CardLabelConf.bottom_description or nil,
        typeDesc = typeDesc,
        iconPath = path,
        showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
        position = Position,
        canCharge = canCharge,
        remainCnt = remainCnt,
        maxCnt = maxCnt,
        quality = CardLabelConf.card_quality,
        isHideBagIcon = true,
        ownedNumber = 1,
        acquirePath = real_acquire_struct,
        isBattleState = isBattleState,
        Caller = Caller,
        CallBack = CallBack,
        OpenCallBack = OpenCallBack
      }
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_PET then
    local petInfo = _G.DataConfigManager:GetPetConf(GoodsID, true)
    local baseId = 0
    if petInfo then
      baseId = petInfo.base_id
    else
      local monsterConf = _G.DataConfigManager:GetMonsterConf(GoodsID)
      if monsterConf then
        baseId = monsterConf.base_id
      else
        local petbaseConf = _G.DataConfigManager:GetPetbaseConf(GoodsID)
        if petbaseConf then
          baseId = GoodsID
        end
      end
    end
    local path = ""
    local name = ""
    local real_acquire_struct = {}
    if baseId and 0 ~= baseId then
      local petbaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
      if petbaseConf and petbaseConf.model_conf then
        local modelConf = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf)
        if modelConf then
          if petbaseConf.have_shiny and 1 == petbaseConf.have_shiny and modelConf.shiny_icon then
            path = modelConf.shiny_icon
          else
            path = modelConf.icon
          end
          name = petbaseConf.name
        end
      end
    end
    data = {
      title = name,
      content = LuaText.reward_descripiton_pet,
      typeDesc = LuaText.umg_compassunlocktips_1,
      iconPath = path,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(GoodsID)
    local path = fashionConf.icon
    local name = fashionConf.name
    local typeStr = self:GetCloseTypeName(true, fashionConf.type)
    local grade = fashionConf.item_quality
    local real_acquire_struct = {}
    data = {
      title = name,
      content = fashionConf.description or nil,
      flavor = fashionConf.acquire_way_text or nil,
      typeDesc = typeStr,
      iconPath = path,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = grade,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(GoodsID)
    local salonInfo
    if salonConf and salonConf.colour_id then
      salonInfo = {
        isOther = true,
        lockState = true,
        salonConfId = GoodsID
      }
    end
    local path = salonConf.icon
    local name = salonConf.name
    local typeStr = self:GetCloseTypeName(false, salonConf.type)
    local real_acquire_struct = {}
    data = {
      title = name,
      content = salonConf.description or nil,
      flavor = salonConf.acquire_way_text or nil,
      typeDesc = typeStr,
      iconPath = path,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = salonConf.item_quality,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      salonData = salonInfo,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(GoodsID)
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(cardSkinConf.bagitem_id)
    local path = bagItemConf.icon
    local name = bagItemConf.name
    local real_acquire_struct = {}
    data = {
      title = name,
      content = bagItemConf.description,
      typeDesc = bagItemConf.type_desc,
      iconPath = path,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = cardSkinConf.card_quality,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_SHARE_FORM then
    local isPreview = false
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(GoodsID)
    local real_acquire_struct = {}
    if params then
      real_acquire_struct = {
        {
          acquire_way_text = LuaText.share_card_option_des,
          text = "ActivityModuleCmd.OpenFreeHuggersCardPanel",
          param1 = {
            cardId = GoodsID,
            petBaseConfId = params.petBaseConfId,
            activityId = params.activityId
          },
          isPreviewCard = true
        }
      }
      isPreview = true
    end
    data = {
      title = shareConf.item_name,
      content = shareConf.item_description,
      flavor = shareConf.extra_description,
      iconPath = shareConf.item_icon,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = shareConf.item_quality,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack,
      PreviewParams = isPreview
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(GoodsID)
    local real_acquire_struct = {}
    data = {
      title = ChatEmojiConf.emoji_resource_name,
      content = ChatEmojiConf.bottom_description,
      typeDesc = ChatEmojiConf.type_desc,
      iconPath = ChatEmojiConf.emoji_goods_icon,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = ChatEmojiConf.card_quality,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  elseif GoodsType == _G.Enum.GoodsType.GT_MEDAL then
    local MedalConf = _G.DataConfigManager:GetMedalConf(GoodsID)
    if nil ~= MedalConf then
      local hideBagIcon = true
      local skillConf
      local itemName = MedalConf.name
      local contentText = MedalConf.desc
      local eggData, updateTime
      local real_acquire_struct = {}
      data = {
        title = itemName,
        content = contentText,
        iconPath = MedalConf.icon,
        flavor = MedalConf.flavor_text,
        showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
        ownedNumber = 1,
        position = Position,
        canCharge = canCharge,
        quality = MedalConf.quality,
        typeDesc = LuaText.medal_text_10,
        acquirePath = real_acquire_struct,
        isBattleState = isBattleState,
        Caller = Caller,
        CallBack = CallBack,
        skillConf = skillConf,
        eggData = eggData,
        updateTime = updateTime,
        OpenCallBack = OpenCallBack,
        isHideBagIcon = hideBagIcon,
        goodsId = GoodsID,
        goodsType = GoodsType
      }
    end
  elseif GoodsType == _G.Enum.GoodsType.GT_FASHION_BOND then
    local FashionBondConf = _G.DataConfigManager:GetFashionBondConf(GoodsID) or {}
    local real_acquire_struct = {}
    data = {
      title = FashionBondConf.name,
      content = FashionBondConf.popup_text_interact,
      typeDesc = LuaText.popup_magic_award,
      iconPath = FashionBondConf.fashion_bond_icon,
      showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
      position = Position,
      canCharge = canCharge,
      remainCnt = remainCnt,
      maxCnt = maxCnt,
      isHideBagIcon = true,
      ownedNumber = 1,
      quality = FashionBondConf.fashion_bond_quality == Enum.FashionBondQuality.FBQ_S and 5 or 4,
      acquirePath = real_acquire_struct,
      isBattleState = isBattleState,
      Caller = Caller,
      CallBack = CallBack,
      OpenCallBack = OpenCallBack
    }
  end
  if data then
    self:OpenPanel("UMG_Common_Tips", data, self:GetItemTipsPanelAdaptationLayer())
  else
    Log.Error("TipsModule:OpenItemTips Can't find item tips data, GoodsID:" .. tostring(GoodsID) .. " GoodsType:" .. tostring(GoodsType))
    if showErrorTipsWhenNotFound then
      Log.Info("TipsModule:OpenItemTips showErrorTips")
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2521)
    end
  end
end

function TipsModule:GetItemTipsPanelAdaptationLayer()
  local panelDynamicData = NRCPanelDynamicData()
  if _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.CheckInFightingOrObserver) then
    local isChatMainOpen = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CheckChatMainPanelIsOpen)
    if isChatMainOpen then
      panelDynamicData:SetModifiedPanelLayerType(Enum.UILayerType.UI_LAYER_TOP)
    end
  end
  return panelDynamicData
end

function TipsModule:OpenItemTipsSimplify(params)
  local GoodsID = params.GoodsID
  local GoodsType = params.GoodsType
  local canCharge = params.canCharge
  local remainCnt = params.remainCnt
  local maxCnt = params.maxCnt
  local isBattleState = params.isBattleState
  local Position = params.Position
  local overrideNum = params.overrideNum
  local Caller = params.Caller
  local CallBack = params.CallBack
  local OpenCallBack = params.OpenCallBack
  local showErrorTipsWhenNotFound = params.showErrorTipsWhenNotFound
  local showDefaultIconWhenNotFound = params.showDefaultIconWhenNotFound
  local isShowPetbase = params.isShowPetbase
  if isShowPetbase then
    local data
    if GoodsType == _G.Enum.GoodsType.GT_PET then
      local petbaseConf = _G.DataConfigManager:GetPetbaseConf(GoodsID)
      local modelConf = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf)
      local path
      if petbaseConf.have_shiny and 1 == petbaseConf.have_shiny and modelConf.shiny_icon then
        path = modelConf.shiny_icon
      else
        path = modelConf.icon
      end
      local name = petbaseConf.name
      local real_acquire_struct = {}
      data = {
        title = name,
        content = LuaText.reward_descripiton_pet,
        typeDesc = LuaText.umg_compassunlocktips_1,
        iconPath = path,
        showDefaultIconWhenNotFound = showDefaultIconWhenNotFound,
        position = Position,
        canCharge = canCharge,
        remainCnt = remainCnt,
        maxCnt = maxCnt,
        isHideBagIcon = true,
        ownedNumber = 1,
        acquirePath = real_acquire_struct,
        isBattleState = isBattleState,
        Caller = Caller,
        CallBack = CallBack,
        OpenCallBack = OpenCallBack
      }
    end
    if data then
      self:OpenPanel("UMG_Common_Tips", data, self:GetItemTipsPanelAdaptationLayer())
    else
      Log.Error("TipsModule:OpenItemTips Can't find item tips data, GoodsID:" .. tostring(GoodsID) .. " GoodsType:" .. tostring(GoodsType))
      if showErrorTipsWhenNotFound then
        Log.Info("TipsModule:OpenItemTips showErrorTips")
        _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2521)
      end
    end
  else
    self:OpenItemTips(GoodsID, GoodsType, canCharge, remainCnt, maxCnt, isBattleState, Position, overrideNum, Caller, CallBack, OpenCallBack, showErrorTipsWhenNotFound, showDefaultIconWhenNotFound)
  end
end

function TipsModule:OpenItemTipsBrief(GoodsID, GoodsType, CustomParam)
  self:ClosePanel("UMG_Common_Tips")
  local data
  if GoodsType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.DataConfigManager:GetBagItemConf(GoodsID)
    if not bagItem then
      return
    end
    local quality = bagItem.item_quality
    if CustomParam then
      quality = CustomParam.quality
    end
    local ownedNumber = 0
    local bagItemData = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItem.id)
    if nil ~= bagItemData then
      ownedNumber = bagItemData.num
    end
    local real_acquire_struct = {}
    for i = 1, #bagItem.acquire_struct do
      if nil == bagItem.acquire_struct[i].acquire_way_text then
        goto lbl_67
      elseif 0 == bagItem.acquire_struct[i].behavior_id then
        table.insert(real_acquire_struct, bagItem.acquire_struct[i])
      else
        table.insert(real_acquire_struct, bagItem.acquire_struct[i])
      end
      ::lbl_67::
    end
    local hideBagIcon, skillConf
    local itemName = bagItem.name
    local contentText = bagItem.description
    if bagItem.type == _G.Enum.BagItemType.BI_SKILL_MACHINE then
      local skillMachineid = bagItem.item_behavior[1].ratio[1]
      skillConf = _G.DataConfigManager:GetSkillConf(skillMachineid)
      contentText = skillConf.desc
    elseif bagItem.type == _G.Enum.BagItemType.BI_PLANT_SEED then
      hideBagIcon = true
    elseif bagItem.type == _G.Enum.BagItemType.BI_PET_EGG or bagItem.type == _G.Enum.BagItemType.BI_PET_FRUIT then
      local isHaveBook, eggItemName, eggItemDesc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, bagItem.id)
      if isHaveBook then
        itemName = eggItemName
        contentText = eggItemDesc
        if CustomParam and CustomParam.eggData and CustomParam.eggData.src == _G.Enum.EggAcquireWayType.EAWT_BLESSING then
          local srcDes = string.format(_G.LuaText.interactiontree_cifu_text_1, CustomParam.eggData.from_player_name, CustomParam.eggData.from_pet_name)
          contentText = string.format("%s%s", contentText, srcDes)
        end
      elseif CustomParam and CustomParam.eggData then
        if CustomParam.eggData.precious_egg_type == _G.Enum.PreciousEggType.PET_PRECIOUS then
          itemName = LuaText.cifu_precious_petegg
        end
        if CustomParam.eggData.src == _G.Enum.EggAcquireWayType.EAWT_BLESSING then
          local srcDes = string.format(_G.LuaText.interactiontree_cifu_text_1, CustomParam.eggData.from_player_name, CustomParam.eggData.from_pet_name)
          contentText = string.format("%s%s", contentText, srcDes)
        end
      end
    end
    data = {
      title = itemName,
      content = contentText,
      flavor = bagItem.flavor_text,
      iconPath = bagItem.icon,
      ownedNumber = ownedNumber,
      expireTime = bagItem.expire_time,
      quality = quality,
      typeDesc = bagItem.type_desc,
      acquirePath = real_acquire_struct,
      skillConf = skillConf,
      isHideBagIcon = hideBagIcon,
      goodsId = GoodsID,
      goodsType = GoodsType
    }
  end
  if data then
    self:OpenPanel("UMG_Common_Tips", data, self:GetItemTipsPanelAdaptationLayer())
  end
end

function TipsModule:CloseItemTips()
  self:ClosePanel("UMG_Common_Tips")
end

function TipsModule:ResetTipsDescText()
  if self:HasPanel("UMG_Common_Tips") then
    local panel = self:GetPanel("UMG_Common_Tips")
    panel:ResetDescText()
  end
end

function TipsModule:OpenInputBlocker(tag)
  if tag and (type(tag) == "string" or type(tag) == "number") then
    if self.InputBlockDic == nil then
      self.InputBlockDic = {}
    end
    self.InputBlockDic[tag] = true
  end
  if self:HasPanel("UMG_Input_Blocker") then
    self:EnablePanel("UMG_Input_Blocker")
  else
    self:OpenPanel("UMG_Input_Blocker")
  end
end

function TipsModule:CloseInputBlocker(tag)
  if self.InputBlockDic and tag and (type(tag) == "string" or type(tag) == "number") then
    self.InputBlockDic[tag] = nil
  end
  if self.InputBlockDic == nil or nil == _G.next(self.InputBlockDic) then
    self:DisablePanel("UMG_Input_Blocker")
  end
end

function TipsModule:HasInputBlocker()
  if not self.InputBlockDic then
    return false
  end
  local HasBlock = next(self.InputBlockDic)
  return nil ~= HasBlock
end

function TipsModule:DoCmdShowMiracleExchange(tipObject)
  if not tipObject then
    return
  end
  if tipObject.reason == ProtoEnum.FlowReason.FLOW_REASON_BE_MIRACLE_CHANGE then
    self:DoCmdShowTips(_G.DataConfigManager:GetGlobalConfig("magic_change_succeed").str)
  elseif tipObject.reason == ProtoEnum.FlowReason.FLOW_REASON_MIRACLE_CHANGE_TIMEOUT then
    local _, PropName = tipObject:Resolve()
    self:DoCmdShowTips(string.format(LuaText.tipsmodule_2, PropName))
  end
end

function TipsModule:OnOpenAntiAddictionPullDown(instruction)
  self:OpenPanel("AntiAddiction_PullDown", instruction)
end

function TipsModule:OnOpenAntiAddiction(instruction, IsBan)
  if 1 == instruction.modal then
    _G.ZoneServer:DisConnect()
  end
  self:OpenPanel("AntiAddiction", instruction, IsBan)
end

function TipsModule:OpenMagicDetailTips(param)
  self:OpenPanel("MagicDetailTips", param)
end

function TipsModule:OpenFruitTreeTips(Params)
  self:OpenPanel("FruitTreeTips", Params)
end

function TipsModule:OpenTapTapTips(Params)
  Log.Debug("TipsModule:OpenTapTapTips")
  self:OpenPanel("TapTapTips", Params)
end

function TipsModule:CloseTapTapTips()
  Log.Debug("TipsModule:CloseTapTapTips")
  if self:HasPanel("TapTapTips") then
    self:ClosePanel("TapTapTips")
  end
end

function TipsModule:OnCmdShowExpUpTip(expTip)
  if expTip then
    self:AddTip(expTip)
    local expTipData = expTip.customData
    if expTipData and expTipData.oldLevel < expTipData.newLevel then
      local worldLevelConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
      for i, item in ipairs(worldLevelConf) do
        if expTipData.newLevel == item.update_grade_level and not item.not_broadcast_tips then
          self:AddTip(TipObject.CreateBreakThroughTip(item, expTip))
        end
      end
    end
  end
end

function TipsModule:OnZoneMarqueePlayNotify(_Notify)
  if not self:HasPanel("MarqueePanel") then
    self:OpenPanel("MarqueePanel", _Notify)
  else
    local panel = self:GetPanel("MarqueePanel")
    panel:SetPanelInfo(_Notify)
  end
end

function TipsModule:OnZoneErrorCodeNotify(notify)
  if 1 ~= notify.is_debug_show then
    return
  end
  if _G.RocoEnv.IS_SHIPPING then
    return
  end
  if string.IsNilOrEmpty(notify.err_tips) then
    return
  end
  Log.Error(notify.err_tips)
  local Context = _G.DialogContext()
  Context:SetMode(_G.DialogContext.Mode.OK)
  Context:SetTitle("\230\157\165\232\135\170\229\144\142\229\143\176\231\154\132\230\138\165\233\148\153\228\191\161\230\129\175")
  Context:SetContent(notify.err_tips)
  self:OpenDialog(Context)
end

function TipsModule:OnScreenTimeNotify(_Notify)
  local instruction = _Notify.instruction
  if instruction.type then
    self.instructionType = instruction.type
  end
  if 1 == instruction.type then
    if instruction.title == LuaText.tipsmodule_3 then
      self:OnOpenAntiAddictionPullDown(instruction)
    else
      self:OnOpenAntiAddiction(instruction)
    end
  elseif 2 == instruction.type then
    self:OnOpenAntiAddiction(instruction)
  elseif 3 == instruction.type then
    self.URLModal = instruction.modal
    if RocoEnv.PLATFORM_WINDOWS then
      local extraTable = {is_closable = false, webview_need_toolbar = false}
      local extraJson = JsonUtils.EncodeTable(extraTable)
      local urlStr = instruction.url
      if string.IsNilOrEmpty(urlStr) then
        Log.Error("instruction.url is empty")
        return
      end
      UE4.UWebViewStatics.OpenUrl(instruction.url, 1, true, true, extraJson, false)
    else
      local urlParams = {}
      if 1 == instruction.modal or instruction.modal == "1" then
        urlParams = {
          url = instruction.url,
          show_titlebar = 0,
          show_title = 0,
          buttons = {}
        }
      else
        urlParams = {
          url = instruction.url,
          show_titlebar = 0,
          show_title = 0,
          buttons = {
            buttonId = 1,
            name = LuaText.hope_notify_tips_return or "",
            action = 0
          }
        }
      end
      if not table.isEmpty(urlParams) then
        local urlJsonStr = JsonUtils.EncodeTable(urlParams)
        local newUrlJsonStr = urlJsonStr
        if 1 == instruction.modal or instruction.modal == "1" then
          newUrlJsonStr = urlJsonStr:gsub("\"buttons\":{}", "\"buttons\":[]")
        else
          newUrlJsonStr = urlJsonStr:gsub("\"buttons\":({[^}]*})", "\"buttons\":[%1]")
        end
        UE4.UWebViewStatics.OpenPrajnaWebView(newUrlJsonStr)
        if RocoEnv.PLATFORM_ANDROID then
          self.bOpenPrajnaWebView = 1 == self.URLModal
        end
      end
    end
  elseif 8 == instruction.type then
    self.LogoutTime = instruction.logout_time
    self.ResidueTimeRemind = self.LogoutTime - _G.ZoneServer:GetServerTime()
    Log.Error(self.LogoutTime, self.ResidueTimeRemind, "\230\148\182\229\136\176\231\177\187\229\158\139\228\184\186type8\230\149\176\230\141\174")
  end
end

function TipsModule:OnWebViewOptNotify(webViewRet)
  if webViewRet.msgType == NRCSDKManagerEnum.WebViewMsgType.CloseWebViewURL and self.bOpenPrajnaWebView then
    self.bOpenPrajnaWebView = false
  end
end

function TipsModule:OnEnterBackground()
  if self.bOpenPrajnaWebView then
    self.bOpenPrajnaWebView = false
    if _G.NRCModuleManager:GetModule("LoginModule") then
      local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.LoginFail)
      _G.ZoneServer:CloseWaitingUI("QQVXLogin")
    end
    _G.GlobalConfig.UserKickedOutFromGame = true
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
    _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.Logout)
    _G.AppMain.BackToLogin()
  end
end

function TipsModule:CheckSeasonBeginTips(newState, functionType, Reason)
  if not newState and self.seasonBeginsTip then
    Log.Info("TipsModule CheckSeasonBeginTips AddTip Reason", Reason)
    self:AddTip(self.seasonBeginsTip)
    self.seasonBeginsTip = nil
  end
end

function TipsModule:OnReceiveLoginRetOutside()
  Log.Debug("OnReceiveLoginRetOutside", self.URLModal or "invalid self.URLModal")
  if self.URLModal and 1 == self.URLModal then
    self.URLModal = nil
    _G.GlobalConfig.UserKickedOutFromGame = true
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
    UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
    _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.Logout)
    _G.AppMain.BackToLogin()
  end
end

function TipsModule:OnReLoginUpdate()
  if self:HasPanel("UMG_Dialog") then
    local panel = self:GetPanel("UMG_Dialog")
    if panel and panel.context and panel.context:GetDialogTag() == _G._G.DialogContext.DialogTag.DifferentAccount then
      Log.Info("DifferentAccount keep dialog")
    else
      self:DoCmdDisableDialog()
    end
  end
  self:CloseTipsPanel()
end

function TipsModule:OnReconnect()
  if self:HasPanel("UMG_LongDialog") then
    self:ClosePanel("UMG_LongDialog")
  end
end

function TipsModule:OnPlayerDead()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  self:HideWorldCombatTips()
end

function TipsModule:OnEnterBattle()
  self:HideWorldCombatTips()
end

function TipsModule:HideWorldCombatTips()
  local worldCombatTips = {
    "worldcombat_tips_1",
    "worldcombat_tips_2",
    "worldcombat_tips_3"
  }
  local worldCombatTipMess = {}
  for _, tipId in pairs(worldCombatTips) do
    local Conf = _G.DataConfigManager:GetLocalizationConf(tipId)
    if Conf then
      table.insert(worldCombatTipMess, Conf.msg)
    end
  end
  self:DispatchEvent(TipsModuleEvent.TopHud_HideTargetTips, worldCombatTipMess)
end

function TipsModule:OnTick(deltaTime)
  if self.LogoutTime and self.ResidueTimeRemind then
    self.ResidueTimeRemind = self.ResidueTimeRemind - deltaTime
    local match_banned_duration = _G.DataConfigManager:GetGlobalConfig("pvp_match_banned_duration").num
    if match_banned_duration <= self.ResidueTimeRemind and math.abs(self.ResidueTimeRemind - match_banned_duration) <= 0.5 then
      local instruction = {}
      instruction.msg = _G.DataConfigManager:GetGlobalConfig("logout_preannounce_text").str
      self:OnOpenAntiAddictionPullDown(instruction)
      self.LogoutTime = nil
      self.ResidueTimeRemind = nil
      self.IsCanPVP = false
    elseif match_banned_duration > self.ResidueTimeRemind then
      self.LogoutTime = nil
      self.ResidueTimeRemind = nil
      self.IsCanPVP = false
    end
  end
  if not self.curNetworkContext and self.networkContextQueue:Size() > 0 then
    local dialogContext = self.networkContextQueue:DeQueue()
    self:DoCmdOpenOnlyForNetworkDialog(dialogContext)
  end
end

function TipsModule:GetIsCanPVP()
  return self.IsCanPVP
end

function TipsModule:OnServerNotifyTips(Action)
  local Conf = _G.DataConfigManager:GetLocalizationConf(Action.text_prompts_id)
  local Delay
  if Conf and Conf.id == "worldcombat_tips_1" or Conf.id == "worldcombat_tips_2" or Conf.id == "worldcombat_tips_3" then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
      return
    end
    Delay = 5.5
  else
  end
  if not Conf then
    return
  end
  self:DoCmdShowTips(Conf.msg, Delay)
end

function TipsModule:OnOpenLoadingProgressPanel(bOpen, percent, text)
  local bOpening, _ = self:HasPanel("LoadingProgressTip")
  if bOpening then
    if not bOpen then
      self:ClosePanel("LoadingProgressTip")
    end
  elseif bOpen then
    self:OpenPanel("LoadingProgressTip", percent, text)
  end
end

function TipsModule:OnDialogFinished(bReconnect)
  if bReconnect then
    self.bReConnectPopUp = false
  end
end

function TipsModule:OnCmdCheckHasMapTips()
  local isOpening, _ = self:HasPanel("UMG_TopHUD")
  if isOpening then
    local tipsPanel = self:GetPanel("UMG_TopHUD")
    if tipsPanel then
      local hasMapTips = false
      local tipDisplayExecutor = tipsPanel.tipDisplayExecutor
      if tipDisplayExecutor then
        tipDisplayExecutor:TraverseCacheData(function(_, tip)
          if tip.tipType == TipEnum.TopHudTipsType.ZoneTips then
            hasMapTips = true
            return true
          end
        end)
        return hasMapTips
      end
    end
  end
  return true
end

function TipsModule:GetCloseTypeName(isFashion, type)
  if self.CloseTabConfs then
    for i = 1, #self.CloseTabConfs do
      local closetabConf = self.CloseTabConfs[i]
      if isFashion then
        if _G.Enum.FashionLabelType.FLT_BEGIN == type then
          return ""
        end
        if closetabConf.use_FashionLabelType == type then
          return closetabConf.tabname
        end
      else
        if _G.Enum.SalonLabelType.SLT_BEGIN == type then
          return ""
        end
        if closetabConf.use_SalonLabelType == type then
          return closetabConf.tabname
        end
      end
    end
  end
  return ""
end

function TipsModule:DoCmdOpenOnlyForNetworkDialog(dialogContext, priority, overrideMode)
  if not dialogContext then
    return
  end
  if self.instructionType and 2 == self.instructionType then
    self.instructionType = nil
    return
  end
  dialogContext.priority = priority or 0
  dialogContext:SetIsOnlyForNetwork()
  local panelName = "UMG_Dialog_OnlyForNetwork"
  local readyShowDialogContext = dialogContext
  if self.curNetworkContext then
    local curPriority = self.curNetworkContext.priority or 0
    if not overrideMode or overrideMode == DialogContext.OverrideMode.Default or curPriority <= dialogContext.priority then
      self.networkContextQueue:EnQueue(dialogContext)
      readyShowDialogContext = nil
    elseif overrideMode == DialogContext.OverrideMode.ReplaceAndKeep then
      self.networkContextQueue:EnQueue(self.curNetworkContext)
    end
  else
    self.networkContextQueue:EnQueue(dialogContext)
    readyShowDialogContext = self.networkContextQueue:DeQueue()
  end
  if readyShowDialogContext then
    if self:HasPanel(panelName) then
      self:ClosePanel(panelName)
    end
    self.curNetworkContext = readyShowDialogContext
    local panelDynamicData = NRCPanelDynamicData()
    panelDynamicData:SetCloseCallback(self, self.DoCmdSetOnlyForNetworkDialogClosed)
    self:OpenPanel(panelName, readyShowDialogContext, panelDynamicData)
  end
end

function TipsModule:DoCmdSetOnlyForNetworkDialogClosed()
  self.curNetworkContext = nil
end

function TipsModule:AntiAddictionFinish(type)
  if type == self.instructionType then
    self.instructionType = nil
  end
end

function TipsModule:CheckMainPetTips(GoodsChangeItems)
  local ExpLevelList = {}
  local SkillList = {}
  local EnergyList = {}
  local MedalList = {}
  for _, GoodsChangeItem in ipairs(GoodsChangeItems) do
    if not GoodsChangeItem or GoodsChangeItem.op == ProtoEnum.OpType.OT_SUB then
    else
      local gid, subType, newPetData
      local ItemType = GoodsChangeItem.type
      if ItemType == ProtoEnum.GoodsType.GT_PET then
        if not GoodsChangeItem.pet_data then
        else
          gid = GoodsChangeItem.pet_data.gid
          newPetData = GoodsChangeItem.pet_data
          elseif ItemType == ProtoEnum.GoodsType.GT_PETEXP then
            gid = GoodsChangeItem.gid
            subType = TipEnum.MainPetTipsType.Exp
          elseif ItemType == ProtoEnum.GoodsType.GT_PET_EN then
            gid = GoodsChangeItem.gid
            subType = TipEnum.MainPetTipsType.Energy
          else
            if not (ItemType == ProtoEnum.GoodsType.GT_MEDAL and GoodsChangeItem.medal) or not GoodsChangeItem.medal.detail then
              goto lbl_328
            end
            gid = GoodsChangeItem.medal.detail.obtain_pet_gid
            if GoodsChangeItem.medal.trigger_pet_gid then
              gid = GoodsChangeItem.medal.trigger_pet_gid
            end
            subType = TipEnum.MainPetTipsType.Medal
            goto lbl_81
            goto lbl_328
          end
          ::lbl_81::
          local oldPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
          if not _G.DataModelMgr.PlayerDataModel:GetIsMainTeamPetByGid(gid) or not oldPetData then
          elseif not subType then
            local oldLV, newLV = oldPetData.level, newPetData.level
            if oldLV < newLV then
              ExpLevelList[gid] = {
                subType = TipEnum.MainPetTipsType.Level,
                subData = self:CreateLevelTipsData(oldPetData.exp, newPetData.exp, oldLV, newLV)
              }
            end
            local newSkillData = newPetData.skill and newPetData.skill.skill_data
            local oldSkillData = oldPetData.skill and oldPetData.skill.skill_data
            if newSkillData and oldSkillData then
              local skills = {}
              local oldSkillMap = {}
              for _, oldSkill in pairs(oldSkillData) do
                oldSkillMap[oldSkill.id] = oldSkill.is_learned
              end
              for _, skill in pairs(newSkillData) do
                if skill.unlock_need_lv and oldLV < skill.unlock_need_lv and newLV >= skill.unlock_need_lv and skill.is_learned and not oldSkillMap[skill.id] then
                  table.insert(skills, skill)
                end
              end
              if next(skills) then
                SkillList[gid] = {
                  subType = TipEnum.MainPetTipsType.Skill,
                  subData = self:CreateSkillTipsData(skills)
                }
              end
            end
            local newEnergy = newPetData.energy
            if newEnergy and oldPetData.energy then
              EnergyList[gid] = {
                subType = TipEnum.MainPetTipsType.Energy,
                subData = self:CreateEnergyTipsData(oldPetData.energy, newEnergy, GoodsChangeItem.change_reason)
              }
            end
          elseif subType == TipEnum.MainPetTipsType.Exp then
            local newExp = GoodsChangeItem.num
            if newExp > oldPetData.exp then
              ExpLevelList[gid] = {
                subType = TipEnum.MainPetTipsType.Exp,
                subData = self:CreateExpTipsData(oldPetData.exp, newExp, oldPetData.level)
              }
            end
          elseif subType == TipEnum.MainPetTipsType.Energy then
            local newEnergy = GoodsChangeItem.num
            EnergyList[gid] = {
              subType = TipEnum.MainPetTipsType.Energy,
              subData = self:CreateEnergyTipsData(oldPetData.energy, newEnergy, GoodsChangeItem.reason)
            }
          elseif subType == TipEnum.MainPetTipsType.Medal then
            local medal = GoodsChangeItem.medal
            local conf_id = GoodsChangeItem.medal.conf_id
            local bFirstGot, old_complete_cnt = _G.DataModelMgr.PlayerDataModel:GetMedalInfoByItem(GoodsChangeItem)
            local complete_cnt
            if medal.detail.complete_cnt and old_complete_cnt then
              local medalConf = _G.DataConfigManager:GetMedalConf(conf_id)
              if medalConf and old_complete_cnt ~= medal.detail.complete_cnt then
                for _, item in pairs(medalConf.repeat_get_award or {}) do
                  if old_complete_cnt < item.count and item.count <= medal.detail.complete_cnt then
                    complete_cnt = medal.detail.complete_cnt
                    break
                  end
                end
              end
            end
            if bFirstGot or complete_cnt then
              if not MedalList[gid] then
                MedalList[gid] = {
                  subType = TipEnum.MainPetTipsType.Medal,
                  subData = self:CreateMedalTipsData({}, conf_id, complete_cnt)
                }
              else
                MedalList[gid].subData = self:CreateMedalTipsData(MedalList[gid].subData, conf_id, complete_cnt)
              end
            end
          end
        end
    end
    ::lbl_328::
  end
  if next(EnergyList) then
    self:AddTip(TipObject.CreateMainPetTips(EnergyList))
  end
  if next(ExpLevelList) then
    self:AddTip(TipObject.CreateMainPetTips(ExpLevelList))
  end
  if next(SkillList) then
    self:AddTip(TipObject.CreateMainPetTips(SkillList))
  end
  if next(MedalList) then
    self:AddTip(TipObject.CreateMainPetTips(MedalList))
  end
end

function TipsModule:CreateEnergyTipsData(oldEnergy, newEnergy, reason)
  local energyTipsData = {
    oldEnergy = oldEnergy,
    newEnergy = newEnergy,
    reason = reason
  }
  return energyTipsData
end

function TipsModule:CreateExpTipsData(oldExp, newExp, curLevel)
  local expTipsData = {
    old_exp = oldExp or 0,
    new_exp = newExp or 0,
    level = curLevel or 1
  }
  return expTipsData
end

function TipsModule:CreateLevelTipsData(oldExp, newExp, oldLevel, newLevel)
  local levelTipsData = {
    old_exp = oldExp or 0,
    new_exp = newExp or 0,
    old_level = oldLevel or 1,
    new_level = newLevel or 1
  }
  return levelTipsData
end

function TipsModule:CreateSkillTipsData(skills)
  local skillTipsData = {skills = skills}
  return skillTipsData
end

function TipsModule:CreateMedalTipsData(subData, conf_id, complete_cnt)
  local resList = {}
  for _, data in pairs(subData or {}) do
    if data then
      table.insert(resList, data)
    end
  end
  local medalTipsData = {conf_id = conf_id, complete_cnt = complete_cnt}
  table.insert(resList, medalTipsData)
  return resList
end

function TipsModule:IsTipPaused()
  return not self.TipsCoordinator:CanDisplay()
end

return TipsModule
