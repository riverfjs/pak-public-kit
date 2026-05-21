local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MusicCollectionUtils = require("NewRoco.Modules.System.MusicCollection.MusicCollectionUtils")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattlePassModule = NRCModuleBase:Extend("BattlePassModule")

function BattlePassModule:OnConstruct()
  _G.BattlePassModuleCmd = reload("NewRoco.Modules.System.BattlePass.BattlePassModuleCmd")
  self.data = self:SetData("BattlePassModuleData", "NewRoco.Modules.System.BattlePass.BattlePassModuleData")
end

function BattlePassModule:OnActive()
  self:RegisterCmd(_G.BattlePassModuleCmd.ShowDescPanel, self.OnCmdShowDescPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetDescText, self.OnCmdSetDescText)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetDescText, self.OnCmdGetDescText)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetDescTextTable, self.OnCmdSetDescTextTable)
  self:RegisterCmd(_G.BattlePassModuleCmd.ClearDescText, self.OnCmdClearDescText)
  self:RegisterCmd(_G.BattlePassModuleCmd.ResetDescText, self.OnCmdResetDescText)
  self:RegisterCmd(_G.BattlePassModuleCmd.ShowBtnClosePanel, self.OnCmdShowBtnClosePanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.HideBtnClosePanel, self.OnCmdHideBtnClosePanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenBattlePass, self.OnCmdOpenBattlePass)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenBattlePassActivity, self.OnCmdOpenBattlePassActivity)
  self:RegisterCmd(_G.BattlePassModuleCmd.EnableBattlePass, self.EnableBattlePass)
  self:RegisterCmd(_G.BattlePassModuleCmd.PreLoadBattlePass, self.PreLoadBattlePass)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenLevelUpgradePanel, self.OnCmdOpenLevelUpgradePanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenLevelUpShowPanel, self.OnCmdOpenLevelUpShowPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, self.OnCmdOpenPassAwardMainPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.ClosePassAwardMainPanel, self.OnCmdClosePassAwardMainPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.OnCmdOpenPetDetailPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPassPurchasePanel, self.OnCmdOpenPassPurchasePanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPassSelectPanel, self.OnCmdOpenPassSelectPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.ClosePassSelectPanel, self.OnCmdClosePassSelectPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenTipsPanel, self.OnCmdOpenTipsPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPassActivity, self.OnCmdOpenPassActivity)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPassGift, self.OnCmdOpenPassGift)
  self:RegisterCmd(_G.BattlePassModuleCmd.IsActivitePass, self.IsActivitePass)
  self:RegisterCmd(_G.BattlePassModuleCmd.DoDeactiveBattlepass, self.DoDeactiveBattlepass)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenAccomplishPanel, self.OnCmdOpenAccomplishPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetCurrentThemeImagePath, self.GetCurrentThemeImagePath)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetPetSelectTabIndex, self.OnCmdGetPetSelectTabIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetPetSelectTabIndex, self.OnCmdSetPetSelectTabIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, self.ConvertToTimeSeconds)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetCurServerTime, self.GetCurServerTime)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnCmdGetPassTaskOpenState, self.OnCmdGetPassTaskOpenState)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnCmdEvolutionaryChainPanel, self.OnCmdEvolutionaryChainPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetCurrentBattlePassInfo, self.OnCmdGetCurrentBattlePassInfo)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetActiveSelectTabIndex, self.OnCmdGetActiveSelectTabIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetActiveSelectTabIndex, self.OnCmdSetActiveSelectTabIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetActiveSelectWeekIndex, self.OnCmdGetActiveSelectWeekIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetActiveSelectWeekIndex, self.OnCmdSetActiveSelectWeekIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekParaGraphId, self.OnCmdGetWeekParaGraphId)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetWeekParaGraphId, self.OnCmdSetWeekParaGraphId)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekIndexByTaskId, self.OnCmdGetWeekIndexByTaskId)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekDoneState, self.OnCmdGetWeekDoneState)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekWaitState, self.OnCmdGetWeekWaitState)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekTasks, self.OnCmdGetWeekTasks)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetTasksByType, self.OnCmdGetTasksByType)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnZoneTaskQueryReq, self.ZoneTaskQueryReq)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnZoneTaskRewardReq, self.ZoneTaskRewardReq)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetWeekZoneTaskReward, self.GetWeekZoneTaskReward)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetAllZoneTaskReward, self.GetAllZoneTaskReward)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetAllFinshTaskIds, self.OnGetAllFinshTaskIds)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetThemeResPath, self.GetThemeResPath)
  self:RegisterCmd(_G.BattlePassModuleCmd.SetPassActiveTaskDic, self.SetPassActiveTaskDic)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetBattlePassName, self.GetBattlePassName)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetEvolutionaryPetIds, self.GetPetEvoIds)
  self:RegisterCmd(_G.BattlePassModuleCmd.TriggerCacheRewardPanel, self.OnTriggerCacheRewardPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.OffActiveSelectTabIndex, self.IsSelectTabIndex)
  self:RegisterCmd(_G.BattlePassModuleCmd.CanAwardTablTipsTirgger, self.CanAwardTablTipsTirgger)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnCmdGetTaskCountdown, self.OnCmdGetTaskCountdown)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnCmdSetActivityPassBgmState, self.SetActivityPassBgmState)
  self:RegisterCmd(_G.BattlePassModuleCmd.IsLobbyMainInnerOpenPass, self.IsLobbyMainInnerOpenPass)
  self:RegisterCmd(_G.BattlePassModuleCmd.ChangeThemeAndUnlockGift, self.ChangeThemeAndUnlockGift)
  self:RegisterCmd(_G.BattlePassModuleCmd.IsThemeA, self.IsThemeA)
  self:RegisterCmd(_G.BattlePassModuleCmd.ChangeThemeColor, self.OnCmdChangeThemeColor)
  self:RegisterCmd(_G.BattlePassModuleCmd.ReceiveBattlePassReward, self.OnCmdReceiveBattlePassReward)
  self:RegisterCmd(_G.BattlePassModuleCmd.ZoneSelectBattlePassThemeReq, self.ZoneSelectBattlePassThemeReq)
  self:RegisterCmd(_G.BattlePassModuleCmd.BuyLevelReq, self.OnBuyLevelReq)
  self:RegisterCmd(_G.BattlePassModuleCmd.UnlockReq, self.OnUnlockBattlePass)
  self:RegisterCmd(_G.BattlePassModuleCmd.IsDisTaskRewardReq, self.IsDisTaskRewardReq)
  self:RegisterCmd(_G.BattlePassModuleCmd.ChangeRegisterPopUpReveal, self.OnCmdChangeRegisterPopUpReveal)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo, self.GetNewBattlePassInfo)
  self:RegisterCmd(_G.BattlePassModuleCmd.IsHaveBattlePassPanel, self.OnCmdIsHavelPassPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.GetAllRewardConfig, self.OnCmdGetAllRewardConf)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnPetSkillFilterRuleChange, self.OnPetSkillFilterRuleChange)
  self:RegisterCmd(_G.BattlePassModuleCmd.OnPetSkillSortRuleChange, self.OnPetSkillSortRuleChange)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenPurchaseSuccessfulTips, self.OnCmdOpenPurchaseSuccessfulTips)
  self:RegisterCmd(_G.BattlePassModuleCmd.ClosePurchaseSuccessfulTips, self.OnCmdClosePurchaseSuccessfulTips)
  self:RegisterCmd(_G.BattlePassModuleCmd.CloseBattlePassPurchasePanel, self.OnCloseBattlePassPurchasePanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.ReqGetAnotherThemeFriends, self.OnCmdReqGetAnotherThemeFriends)
  self:RegisterCmd(_G.BattlePassModuleCmd.OpenSelectFriendPanel, self.OnCmdOpenSelectFriendPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.CloseSelectFriendPanel, self.OnCmdCloseSelectFriendPanel)
  self:RegisterCmd(_G.BattlePassModuleCmd.ReqBattlePassShopData, self.OnCmdReqBattlePassShopData)
  self:RegPanel("BattlePassUpgrade", "UMG_Pass_Upgrade", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePassAwardMain", "UMG_Pass_AwardMain", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Page_Out")
  self:RegPanel("BattlePassLevelUpShow", "UMG_Pass_levelUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePassPetDetail", "UMG_Pass_PetDetail", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", "Out")
  self:RegPanel("BattlePurchasePanel", "UMG_Pass_Purchase", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "In", "Out")
  self:RegPanel("BattlePassSelectPanel", "UMG_Pass_Select", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, "Page_In")
  self:RegPanel("BattlePassTips", "UMG_Pass_Explain", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattleAccomplish", "UMG_Pass_Accomplish", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, true)
  self:RegPanel("BattlePassActivity", "Umg_Pass_Activity", _G.Enum.UILayerType.UI_LAYER_POPUP, "Huodong_In", "Huodong_Out", true)
  self:RegPanel("BattlePassGift", "Umg_Pass_PresentAGift", _G.Enum.UILayerType.UI_LAYER_POPUP, "Kuili_In", "Kuili_Out", true)
  self:RegPanel("EvolutionaryChainPanel", "UMG_EvolutionaryChainPanel", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("BattlePurchaseSuccessfulTips", "UMG_PurchaseSuccessfulTips", _G.Enum.UILayerType.UI_LAYER_POPUP, "Finish", true)
  self:RegPanel("BattlePassSelectFriend", "UMG_Pass_SelectFriend", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, false)
  self:RegisterRevealPopUpPanel()
  _G.NRCModuleManager:GetModule("NPCShopUIModule"):RegisterEvent(self, NPCShopUIModuleEvent.NPCSHOP_ITEM_REWARS_CLOSE, self.Test)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, SceneEvent.OnRelogin, self.OnRest)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpened)
  _G.NRCEventCenter:RegisterEvent("BattlePassModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
  self:GetNewBattlePassInfo()
  self.evoIds = nil
  self.isGetAwardMsg = false
  self.descText = {}
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.ZoneGoodsRewardNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PASS_TASK_UPDATE_NOTIFY, self.ZoneBattlePassTaskUpdateNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_BATTLE_PASS_EXP_NOTIFY, self.OnZonePlayerBattlePassExpNotify)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SELECT_ANOTHER_BATTLE_PASS_THEME_FRIENDS_RSP, self.OnGetAnotherThemeFriendsRsp)
  self.ShowDeactivePassTips = false
  self.preLoadThemeResMap = {}
  Log.Info("[BattlePassSpine] PreLoadThemeRes start")
  self:PreLoadThemeRes()
end

function BattlePassModule:GetBattlePassShopDataRspHandler(ShopRsp)
end

function BattlePassModule:OnCmdReqBattlePassShopData()
  local allBattlePassGiftConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_GIFT_CONF)
  local ShopID = 9001
  for _, giftConf in ipairs(allBattlePassGiftConf) do
    if giftConf.gift_goods_id then
      local goodsConf = _G.DataConfigManager:GetNormalShopConf(giftConf.gift_goods_id)
      if goodsConf then
        ShopID = goodsConf.shop_id
        break
      end
    end
  end
  local reqShopData = {
    shopId = ShopID,
    Caller = self,
    rspHandler = self.GetBattlePassShopDataRspHandler,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "BattlePassModule:OnCmdReqBattlePassShopData"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
end

function BattlePassModule:RegPanel(name, path, layer, openAnimName, closeAnimName, disablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = "/Game/NewRoco/Modules/System/BattlePass/Res/" .. path
  registerData.panelLayer = layer
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  registerData.enablePcEsc = not disablePcEsc
  self:RegisterPanel(registerData)
end

function BattlePassModule:OnRelogin()
  self:GetNewBattlePassInfo()
end

function BattlePassModule:OnDeactive()
end

function BattlePassModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnRest)
end

function BattlePassModule:Test()
end

function BattlePassModule:IsSelectTabIndex()
  local settingTime = 0.4
  local curClickTime = _G.UE4Helper.GetTime()
  if self.lastClickTime == nil then
    self.lastClickTime = curClickTime
    return true
  end
  if curClickTime >= self.lastClickTime + settingTime then
    self.lastClickTime = curClickTime
    return true
  end
  return false
end

function BattlePassModule:CanAwardTablTipsTirgger()
  local delayedTime = 1
  local curTime = _G.UE4Helper.GetTime()
  if not self.tableTipsLastTime then
    self.tableTipsLastTime = curTime
    return true
  end
  if delayedTime < curTime - self.tableTipsLastTime then
    self.tableTipsLastTime = curTime
    return true
  end
  return false
end

function BattlePassModule:OnCmdShowDescPanel(id)
  if self:HasPanel("BattlePassPetDetail") then
    local panel = self:GetPanel("BattlePassPetDetail")
    if id then
      panel:OnDescTextClicked(id)
    end
  end
end

function BattlePassModule:OnCmdSetDescText(descText)
  self:DispatchEvent(BattlePassModuleEvent.SetDescText, descText)
end

function BattlePassModule:OnCmdGetDescText()
  return self.descText
end

function BattlePassModule:OnCmdSetDescTextTable(descText)
  self.descText = descText
end

function BattlePassModule:OnCmdClearDescText()
  self:DispatchEvent(BattlePassModuleEvent.ClearDescText)
end

function BattlePassModule:OnCmdResetDescText()
  self:DispatchEvent(BattlePassModuleEvent.ResetDescText)
end

function BattlePassModule:OnCmdShowBtnClosePanel()
  self:DispatchEvent(BattlePassModuleEvent.ShowBtnClosePanel)
end

function BattlePassModule:OnCmdHideBtnClosePanel()
  self:DispatchEvent(BattlePassModuleEvent.HideBtnClosePanel)
end

function BattlePassModule:OnOpenBattlePassActivity(_rsp)
  Log.Dump(_rsp, 9, "#OnOpenBattlePassActivity")
  if 0 ~= _rsp.ret_info.ret_code then
    Log.Warning("BattlePassModule:OnOpenBattlePassActivity bpInfo is nil")
    return
  end
  if _rsp.battle_pass_info and 0 ~= _rsp.battle_pass_info.battle_pass_id then
    self.data:SetPlayerBattlePassInfo(_rsp)
  end
  local bpInfo = self.data:GetPlayerBattlePassInfo()
  if not bpInfo then
    Log.Warning("BattlePassModule:OnCmdOpenBattlePassActivity bpInfo is nil")
    return
  end
  if 0 == bpInfo.theme_id or bpInfo.theme_id == nil then
    self:OnCmdOpenBattlePass(nil, true, nil)
    return
  end
  local taskInfo = bpInfo.task_info
  if nil == taskInfo then
    Log.Warning("BattlePassModule:OnOpenBattlePassActivity taskInfo is nil")
    return
  end
  local taskInfoList = taskInfo.task_info_list
  if taskInfoList then
    self.data:SetPassAllTaskDic(taskInfoList)
    Log.Debug("BattlePassModuleEvent.UpdateActivityTaskDatas", #taskInfoList)
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateActivityTaskDatas, taskInfoList)
    self.data:SetLastTaskListInfo(taskInfoList)
  end
  local hasRewardRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 142)
  local hasActivityRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 147)
  local targetTabIndex = 0
  if hasRewardRedPoint == hasActivityRedPoint then
    local isDailyTaskAllDone = self:CheckDailyTaskAllDone(taskInfoList)
    if isDailyTaskAllDone then
      targetTabIndex = 0
    else
      targetTabIndex = 1
    end
  elseif hasActivityRedPoint then
    targetTabIndex = 1
  else
    targetTabIndex = 0
  end
  self:OnCmdOpenBattlePass(nil, true, targetTabIndex)
end

function BattlePassModule:CheckDailyTaskAllDone(taskInfoList)
  local dailyTasks = taskInfoList
  if not dailyTasks or 0 == #dailyTasks then
    return true
  end
  for i = 1, #dailyTasks do
    local task = dailyTasks[i]
    if task.state ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      return false
    end
  end
  return true
end

function BattlePassModule:OnCmdOpenBattlePassActivity()
  if not self:IsActivitePass() then
    self:DoDeactiveBattlepass()
    return
  end
  local req = ProtoMessage:newZoneGetBattlePassInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BATTLE_PASS_INFO_REQ, req, self, self.OnOpenBattlePassActivity)
end

function BattlePassModule:OnCmdOpenBattlePass(Tips, isLobbyOpen, tabIndex, isCompassOpen)
  if self:HasPanel("BattlePassSelectPanel") or self:HasPanel("BattlePassAwardMain") then
    local needCloseFirst = _G.NRCPanelManager:CheckNeedCloseFirst(self:GetPanelData("BattlePassAwardMain"))
    if needCloseFirst then
      self:ClosePanel("BattlePassAwardMain")
    end
    local needCloseFirst1 = _G.NRCPanelManager:CheckNeedCloseFirst(self:GetPanelData("BattlePassSelectPanel"))
    if needCloseFirst1 then
      self:ClosePanel("BattlePassSelectPanel")
    end
    if needCloseFirst or needCloseFirst1 then
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
      return
    end
  end
  if not self:IsActivitePass() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.bp_umg_close)
    return
  end
  if self.data.PlayerBattlePassInfo and self.data.PlayerBattlePassInfo.battle_pass_id then
    local battlePassConf = _G.DataConfigManager:GetBattlePassConf(self.data.PlayerBattlePassInfo.battle_pass_id)
    local close_time = battlePassConf.close_time
    local open_time = battlePassConf.open_time
    if ActivityUtils.ToTimestamp(close_time) < ActivityUtils.GetSvrTimestamp() or ActivityUtils.ToTimestamp(open_time) > ActivityUtils.GetSvrTimestamp() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
      return
    end
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bagitem_BP_upgrade_tips6)
    return
  end
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip2)
    elseif Tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
    end
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BP, true)
  if isBan then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip2)
    elseif Tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
    end
    if isCompassOpen then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false, false)
    end
    return
  end
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    if _G.DataModelMgr.PlayerDataModel:GetIsTraceByBag() then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip2)
    elseif Tips then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
    end
    if isCompassOpen then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
    end
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).PASS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  if isLobbyOpen then
    self:OpenBattlePassPanel(tabIndex)
  else
    self:ReqZoneGetBattlePassInfoReq()
  end
end

function BattlePassModule:EnableBattlePass()
  local panel = self:GetPanel("BattlePassSelectPanel") or self:GetPanel("BattlePassAwardMain")
  if panel then
    panel:EnableAndShouldBanWorldRendering()
    if self.isLobbyMainInnerOpenPass then
      self.isLobbyMainInnerOpenPass = nil
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.SetActiveSelectTabIndex, 0)
      _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateActiveTableView, 0)
    end
  end
end

function BattlePassModule:PreLoadThemeRes(resList)
  if not resList then
    local resListData = self:GetCurrentActivePassThemeResList()
    resList = resListData.PreLoadResList
  end
  if nil == resList or 0 == #resList then
    Log.Info("[BattlePassSpine] PreLoadThemeRes: resList is nil or empty")
    return
  end
  Log.Info("[BattlePassSpine] PreLoadThemeRes: total resources:", #resList)
  for i = 1, #resList do
    local cachedAsset = self.preLoadThemeResMap[resList[i]]
    if cachedAsset and UE4.UObject.IsValid(cachedAsset) then
    else
      _G.NRCResourceManager:LoadResAsync(self, resList[i], 255, 0, function(caller, resRequest, asset)
        if asset then
          self.preLoadThemeResMap[resRequest.assetPath] = asset
          Log.Info("[BattlePassSpine] PreLoadThemeRes: loaded OK", resRequest.assetPath)
        else
          Log.Warning("[BattlePassSpine] PreLoadThemeRes: loaded but asset is nil", resRequest.assetPath)
        end
      end, function(caller, resRequest, errorMsg)
        Log.Error("[BattlePassSpine] PreLoadThemeRes: FAILED", resRequest.assetPath, errorMsg)
      end)
    end
  end
end

function BattlePassModule:PreLoadBattlePass()
  self:PreLoadPanel("BattlePassSelectPanel", 10)
  self:PreLoadPanel("BattlePassAwardMain", 10)
end

function BattlePassModule:OpenBattlePassPanel(tabIndex)
  local bpInfo = self.data:GetPlayerBattlePassInfo()
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  if bpInfo then
    if 0 == bpInfo.theme_id or bpInfo.theme_id == nil then
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassSelectPanel)
    else
      _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, nil, false, tabIndex)
    end
  else
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PASS
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
  end
end

function BattlePassModule:ReqZoneGetBattlePassInfoReq()
  local req = ProtoMessage:newZoneGetBattlePassInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BATTLE_PASS_INFO_REQ, req, self, self.OnZoneGetBattlePassInfoRsp)
end

function BattlePassModule:OnZoneGetBattlePassInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    if _rsp.battle_pass_info and 0 ~= _rsp.battle_pass_info.battle_pass_id then
      self.data:SetPlayerBattlePassInfo(_rsp)
      _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
      MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
      if 0 == _rsp.battle_pass_info.theme_id or _rsp.battle_pass_info.theme_id == nil then
        _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassSelectPanel)
      else
        _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, nil, false)
      end
    else
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PASS
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.bp_out_of_date)
    end
  else
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PASS
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed)
  end
end

function BattlePassModule:OnCmdOpenPassActivity(arg)
  self:OpenPanel("BattlePassActivity", arg)
end

function BattlePassModule:OnCmdOpenPassGift(arg)
  if not self:HasPanel("BattlePurchasePanel") then
    self:OpenPanel("BattlePassGift", arg)
  end
end

function BattlePassModule:OnCmdEvolutionaryChainPanel(arg, unLock, isShining)
  self:OpenPanel("EvolutionaryChainPanel", arg, unLock, isShining)
end

function BattlePassModule:OnCmdOpenLevelUpgradePanel()
  self:OpenPanel("BattlePassUpgrade")
end

function BattlePassModule:OnCmdOpenLevelUpShowPanel(oldLv, newLv)
  Log.Info("BattlePassModule:OnCmdOpenLevelUpShowPanel", oldLv, newLv)
  if self:HasPanel("BattlePassAwardMain") then
    if self:HasPanel("BattlePassLevelUpShow") then
      local panel = self:GetPanel("BattlePassLevelUpShow")
      panel:OnUpdatePanel(oldLv, newLv)
    elseif oldLv < newLv then
      self:OpenPanel("BattlePassLevelUpShow", oldLv, newLv)
    end
  end
end

function BattlePassModule:ShowOrHideMainTime(IsShow)
  if self:HasPanel("BattlePassAwardMain") then
    local Panel = self:GetPanel("BattlePassAwardMain")
    Panel:ShowOrHideTime(IsShow)
  end
end

function BattlePassModule:IsDisTaskRewardReq()
  local isDisabled = self.DisTaskRewardReq or false
  return isDisabled
end

function BattlePassModule:RegisterRevealPopUpPanel()
  self.RevealPopUpName = {
    "BattlePassActivity",
    "BattlePassGift"
  }
end

function BattlePassModule:OnCmdChangeRegisterPopUpReveal(isEnable)
  if self:HasPanel("BattlePassSelectPanel") then
    return
  end
  for i = 1, #self.RevealPopUpName do
    local panelName = self.RevealPopUpName[i]
    if self:HasPanel(panelName) then
      local panel = self:GetPanel(panelName)
      panel:SetVisibility(isEnable and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    end
  end
end

function BattlePassModule:OnCmdOpenPassAwardMainPanel(arg1, arg2, tabIndex)
  local resListData = self:GetCurrentActivePassThemeResList()
  self:PreLoadThemeRes(resListData.PreLoadResList)
  self:OpenPanel("BattlePassAwardMain", arg1, arg2, tabIndex, resListData)
end

function BattlePassModule:OnCmdClosePassAwardMainPanel()
  self:ClosePanel("BattlePassAwardMain")
end

function BattlePassModule:OnCmdOpenPetDetailPanel(petbaseId, unLock, shinyDefault, petData)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  local modelFxType = petBaseConf.unit_type[1]
  if modelFxType < Enum.SkillDamType.SDT_COMMON then
    modelFxType = Enum.SkillDamType.SDT_COMMON
  end
  local Path = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_colour
  local Path_2 = _G.DataConfigManager:GetSkillColorConf(modelFxType).JL_background_clear
  local ResListData = PetUtils.GetDefaultPetImage3DResListData()
  table.insert(ResListData.PreLoadResList, Path)
  table.insert(ResListData.PreLoadResList, Path_2)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    table.insert(ResListData.PreLoadResList, modelConf.path)
  end
  self:OpenPanel("BattlePassPetDetail", petbaseId, unLock, shinyDefault, ResListData, petData)
end

function BattlePassModule:OnCmdOpenPassPurchasePanel()
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  MusicCollectionUtils.GetBgmStateGroupByApplyType(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_BP)
  self.IsOpenBattlePurchasePanel = true
  local resListData = self:GetCurrentActivePassThemeResList()
  self:PreLoadThemeRes(resListData.PreLoadResList)
  self:OpenPanel("BattlePurchasePanel", resListData)
end

function BattlePassModule:GetCurrentActivePassThemeResList()
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  resListData.PreparingResList = {}
  local currentActivePassCfg = self:GetCurrentActivePass()
  if currentActivePassCfg then
    local themeIds = currentActivePassCfg.theme_id
    for key, value in ipairs(themeIds) do
      local themeUIConf = _G.DataConfigManager:GetBattlePassUiTheme(value)
      if themeUIConf then
        if themeUIConf.spine_atlas then
          table.insert(resListData.PreLoadResList, themeUIConf.spine_atlas)
        end
        if themeUIConf.spine_skeletondata then
          table.insert(resListData.PreLoadResList, themeUIConf.spine_skeletondata)
        end
      end
    end
  end
  return resListData
end

function BattlePassModule:OnCmdOpenPassSelectPanel()
  if not self.IsOpenBattlePurchasePanel then
    local resListData = self:GetCurrentActivePassThemeResList()
    self:PreLoadThemeRes(resListData.PreLoadResList)
    self:OpenPanel("BattlePassSelectPanel", resListData)
  end
end

function BattlePassModule:OnCmdGetPassTaskOpenState(task_id)
  local passConf = _G.DataConfigManager:GetBattlePassConf(self.data.PlayerBattlePassInfo.battle_pass_id)
  local taskEndTime = self.data:GetWeekTaskEndTimeByTaskId(task_id)
  if taskEndTime then
    local curTime = _G.ZoneServer:GetServerTime() / 1000
    local endTime = self:ConvertToTimeSeconds(taskEndTime)
    return curTime < endTime
  end
  return false
end

function BattlePassModule:OnCmdClosePassSelectPanel()
  if self:HasPanel("BattlePassSelectPanel") then
    self:ClosePanel("BattlePassSelectPanel")
  end
end

function BattlePassModule:OnCmdOpenTipsPanel(arg)
  self:OpenPanel("BattlePassTips", arg)
end

function BattlePassModule:OnCmdOpenAccomplishPanel(arg)
  self:OpenPanel("BattleAccomplish", arg)
end

function BattlePassModule:OnCmdGetPetSelectTabIndex()
  return self.data:GetPetSelectTabIndex()
end

function BattlePassModule:OnCmdSetPetSelectTabIndex(index)
  self.data:SetPetSelectTabIndex(index)
end

function BattlePassModule:OnCmdGetActiveSelectTabIndex()
  return self.data:GetActiveSelectTabIndex()
end

function BattlePassModule:OnCmdSetActiveSelectTabIndex(index)
  self.data:SetActiveSelectTabIndex(index)
end

function BattlePassModule:OnCmdGetActiveSelectWeekIndex()
  return self.data:GetActiveSelectWeekIndex()
end

function BattlePassModule:OnCmdSetActiveSelectWeekIndex(index)
  self.data:SetActiveSelectWeekIndex(index)
end

function BattlePassModule:OnCmdGetWeekParaGraphId()
  return self.data:GetWeekParaGraphId()
end

function BattlePassModule:OnCmdSetWeekParaGraphId(id)
  self.data:SetWeekParaGraphId(id)
end

function BattlePassModule:OnCmdGetWeekIndexByTaskId(task_id)
  return self.data:GetWeekIndexByTaskId(task_id)
end

function BattlePassModule:GetThemeResPath()
  return self.data:GetThemeResPath()
end

function BattlePassModule:OnCmdGetWeekDoneState(paragraph_id)
  return self.data:GetWeekDoneState(paragraph_id)
end

function BattlePassModule:OnCmdGetWeekWaitState(paragraph_id)
  return self.data:GetWeekWaitState(paragraph_id)
end

function BattlePassModule:OnCmdGetWeekTasks(paragraph_id)
  return self.data:GetWeekTasks(paragraph_id)
end

function BattlePassModule:OnCmdGetTasksByType(type)
  return self.data:GetTasksByType(type)
end

function BattlePassModule:SetPassActiveTaskDic(taskInfo)
  self.data:SetPassActiveTaskDic(taskInfo)
end

function BattlePassModule:SetActivityPassBgmState(boo)
  self.ActivityPassBgmState = boo
end

function BattlePassModule:IsLobbyMainInnerOpenPass()
  self.isLobbyMainInnerOpenPass = true
end

function BattlePassModule:GetBattlePassName()
  local battlePassName
  if self.data and self.data.PlayerBattlePassInfo then
    local battlePassConf = _G.DataConfigManager:GetBattlePassConf(self.data.PlayerBattlePassInfo.battle_pass_id)
    if battlePassConf then
      battlePassName = battlePassConf.bp_name
    end
  end
  return battlePassName
end

function BattlePassModule:OnCmdGetTaskCountdown(taskId)
  local conf = _G.DataConfigManager:GetBattlePassConf(self.data.PlayerBattlePassInfo.battle_pass_id)
  local paragraph_id = _G.DataConfigManager:GetTaskConf(taskId).paragraph_id
  if conf and paragraph_id then
    local curTime = self:GetCurServerTime()
    local bpCloseTime = self:ConvertToTimeSeconds(conf.close_time)
    for i, bp_week_task in pairs(conf.bp_week_task) do
      if paragraph_id == bp_week_task.task_set_id then
        local starTime = self:ConvertToTimeSeconds(bp_week_task.task_set_start_time)
        local endTime = self:ConvertToTimeSeconds(bp_week_task.task_set_end_time)
        if endTime == bpCloseTime then
          return 0
        end
        if curTime >= starTime and curTime <= endTime then
          return endTime - curTime
        end
      end
    end
  end
  return 0
end

function BattlePassModule:GetPetEvoIds(id)
  self.evoIds = {}
  self.evoBaseId = id
  self:GetPetEvoIdDown(id)
  if #self.evoIds > 1 then
    self.evoIds = self:Reverse(self.evoIds)
  end
  table.insert(self.evoIds, id)
  self:GetPetEvoIdUp(id)
  return self.evoIds
end

function BattlePassModule:Reverse(list)
  for i = 0, (#list - 1) / 2 do
    local temp = list[i + 1]
    list[i + 1] = list[#list - i]
    list[#list - i] = temp
  end
  return list
end

function BattlePassModule:GetPetEvoIdUp(id)
  local baseConf = _G.DataConfigManager:GetPetbaseConf(id)
  local cfg_evo = baseConf.evolution_pet_id
  for i = 1, #cfg_evo do
    table.insert(self.evoIds, cfg_evo[i])
  end
  if #cfg_evo > 0 then
    if self.evoBaseId ~= cfg_evo then
      self:GetPetEvoIdUp(cfg_evo[1])
    else
      Log.Error("\232\191\155\229\140\150\233\147\190\229\144\145\228\184\138\230\159\165\230\137\190PetbaseId\230\151\182\228\184\142\230\159\165\232\175\162id\233\135\141\229\164\141\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165PetBaseId:", self.evoBaseId)
    end
  end
end

function BattlePassModule:GetPetEvoIdDown(id)
  local baseConf = _G.DataConfigManager:GetPetbaseConf(id)
  if not baseConf then
    return
  end
  local cfg_evo = baseConf.degenerate_pet_id
  if cfg_evo > 0 and self.evoBaseId ~= cfg_evo then
    if self.evoBaseId ~= cfg_evo then
      table.insert(self.evoIds, cfg_evo)
      self:GetPetEvoIdDown(cfg_evo)
    else
      Log.Error("\232\191\155\229\140\150\233\147\190\229\144\145\228\184\139\230\159\165\230\137\190PetbaseId\230\151\182\228\184\142\230\159\165\232\175\162id\233\135\141\229\164\141\239\188\140\232\175\183\231\173\150\229\136\146\230\163\128\230\159\165PetBaseId:", self.evoBaseId)
    end
  end
end

function BattlePassModule:ConvertToTimeSeconds(timeStr)
  if nil == timeStr then
    return 0
  end
  local year, month, day, hour, min, sec = timeStr:match("(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
  if nil == year or nil == month or nil == day or nil == hour or nil == min or nil == sec then
    return 0
  end
  local local_time = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec)
  })
  return local_time
end

function BattlePassModule:GetCurServerTime()
  local svr_time = math.floor(_G.ZoneServer:GetServerTime() / 1000)
  return svr_time
end

function BattlePassModule:OnCmdGetCurrentBattlePassInfo()
  return self.data:GetPlayerBattlePassInfo()
end

function BattlePassModule:ZoneSelectBattlePassThemeReq(theme_id)
  local req = _G.ProtoMessage:newZoneSelectBattlePassThemeReq()
  req.theme_id = theme_id
  self.theme_id = theme_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SELECT_BATTLE_PASS_THEME_REQ, req, self, self.ZoneSelectBattlePassThemeRsp)
end

function BattlePassModule:ZoneSelectBattlePassThemeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPlayerBattlePassInfo(rsp)
    if self.theme_id then
      self.data.PlayerBattlePassInfo.theme_id = self.theme_id
      _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateBattlePassInfo)
      self.theme_id = nil
    end
    if self:HasPanel("BattlePassAwardMain") then
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ClosePassSelectPanel)
    else
      _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.OpenPassAwardMainPanel, nil, false)
    end
  else
  end
end

function BattlePassModule:ZoneTaskQueryReq(task_id_list)
  Log.Dump(task_id_list, 4, "BattlePassModule:ZoneTaskQueryReq")
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = task_id_list
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.ZoneTaskQueryRsp)
end

function BattlePassModule:ZoneTaskQueryRsp(rsp)
  Log.Dump(rsp, 4, "BattlePassModule:ZoneTaskQueryRsp")
  local taskInfoList = {}
  if 0 == rsp.ret_info.ret_code and rsp.task_info_list then
    taskInfoList = rsp.task_info_list
  end
  self.data:SetPassAllTaskDic(taskInfoList)
  Log.Debug("BattlePassModuleEvent.UpdateActivityTaskDatas", #taskInfoList)
  _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateActivityTaskDatas, taskInfoList)
  self.data:SetLastTaskListInfo(taskInfoList)
end

function BattlePassModule:GetWeekZoneTaskReward(paragraph_id)
  local weekTaskList = self.data:GetWeekTasks(paragraph_id)
  local finshTaskIdList = {}
  for i, task in pairs(weekTaskList) do
    if task.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      table.insert(finshTaskIdList, task.id)
    end
  end
  self:ZoneTaskRewardReq(finshTaskIdList)
end

function BattlePassModule:GetAllZoneTaskReward()
  if self:OpenReceiveBattlePassTips() then
    return
  end
  local req = _G.ProtoMessage:newZoneReceiveBattlePassAllTaskReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_BATTLE_PASS_ALL_TASK_REQ, req, self, self.ZoneReceiveBattlePassAllTaskRsp)
end

function BattlePassModule:ShowBPRewardLimitTips()
  local battlePassInfo = self.data:GetPlayerBattlePassInfo()
  local lv = battlePassInfo.exp_info.level or 0
  local maxBpExp = self.data:GetMaxWeekExp()
  local curBpExp = battlePassInfo.exp_info.last_week_exp or 0
  local maxBpLevel = self.data:GetBpMaxLevel()
  if lv >= maxBpLevel then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.bp_max_level)
  elseif maxBpExp <= curBpExp then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.bp_no_more_exp)
  end
end

function BattlePassModule:HandleBattlePassAllRewardTask(task_list)
  if task_list then
    local rewardsDic = {}
    local reward_list = {}
    for i = 1, #task_list do
      local taskConf = _G.DataConfigManager:GetTaskConf(task_list[i].id)
      if taskConf then
        local rewardId = taskConf.Reward
        local rewardConf = _G.DataConfigManager:GetRewardConf(rewardId)
        local rewardItems = rewardConf.RewardItem
        for j = 1, #rewardItems do
          local rewardItem = {}
          rewardItem.id = rewardItems[j].Id
          rewardItem.num = rewardItems[j].Count
          rewardItem.type = rewardItems[j].Type
          if rewardsDic[rewardItem.id] then
            rewardsDic[rewardItem.id].num = rewardsDic[rewardItem.id].num + rewardItem.num
          else
            rewardsDic[rewardItem.id] = rewardItem
          end
        end
      end
    end
    for i, v in pairs(rewardsDic) do
      table.insert(reward_list, v)
    end
    self.data:SetPassAllTaskDic(task_list)
    local LastTaskListInfo = self.data:GetLastTaskListInfo()
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.RemoveActivityTaskDatas, task_list, reward_list, LastTaskListInfo)
    self.data:SetLastTaskListInfo(task_list)
  end
end

function BattlePassModule:ZoneReceiveBattlePassAllTaskRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:GetNewBattlePassInfo(true)
    if rsp.task_info_list then
      self:HandleBattlePassAllRewardTask(rsp.task_info_list)
    end
  else
    self:UnlockIsSelectBtn()
  end
  self.DisTaskRewardReq = false
end

function BattlePassModule:OnGetAllFinshTaskIds()
  return self.data:GetAllFinshTaskIds()
end

function BattlePassModule:ZoneTaskRewardReq(task_id_list)
  for i, taskId in pairs(task_id_list) do
    local taskEndTime = self.data:GetWeekTaskEndTimeByTaskId(taskId)
    if taskEndTime then
      local curTime = _G.ZoneServer:GetServerTime() / 1000
      local endTime = self:ConvertToTimeSeconds(taskEndTime)
      if curTime > endTime then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_out_of_date)
        return
      end
    end
  end
  if self:OpenReceiveBattlePassTips(task_id_list) then
    return
  end
  self.DisTaskRewardReq = true
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = task_id_list
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.ZoneTaskRewardRsp)
end

function BattlePassModule:ZoneTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:GetNewBattlePassInfo(true)
    if rsp.rewarded_task_list then
      self:HandleBattlePassAllRewardTask(rsp.rewarded_task_list)
    end
  else
    self:UnlockIsSelectBtn()
  end
  self.DisTaskRewardReq = false
end

function BattlePassModule:IsContainActiveTasks()
  for _, taskTypeList in pairs(self.data.AllTaskDic) do
    for _, taskInfo in pairs(taskTypeList) do
      if taskInfo.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT or taskInfo.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAITING then
        local taskConf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
        if 0 ~= taskConf.Reward then
          local rewardConf = _G.DataConfigManager:GetRewardConf(taskConf.Reward)
          local goods = rewardConf.RewardItem
          for _, item in pairs(goods) do
            if item.type == _G.Enum.GoodsType.GT_VITEM and item.id == _G.Enum.VisualItem.VI_BP_PK_POINTS then
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function BattlePassModule:IsShowTips()
  local battlePassInfo = self.data:GetPlayerBattlePassInfo()
  local curGrade = battlePassInfo.battle_pass_brief_info and battlePassInfo.battle_pass_brief_info.gift_grade or _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE
  local isLocked = battlePassInfo.pk_info and battlePassInfo.pk_info.is_theme_select_locked or false
  local isShowTips = curGrade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE and not isLocked
  return isShowTips
end

function BattlePassModule:OpenReceiveBattlePassTips(taskId)
  local battlePassInfo = self.data:GetPlayerBattlePassInfo()
  local isShowTips = self:IsShowTips()
  local isContainActiveTask = false
  if nil == taskId then
    isContainActiveTask = self:IsContainActiveTasks()
  else
    local taskConf = _G.DataConfigManager:GetTaskConf(taskId[1])
    if taskConf and 0 ~= taskConf.Reward then
      local rewardConf = _G.DataConfigManager:GetRewardConf(taskConf.Reward)
      local goods = rewardConf.RewardItem
      for _, item in pairs(goods) do
        if item.type == _G.Enum.GoodsType.GT_VITEM and item.id == _G.Enum.VisualItem.VI_BP_PK_POINTS then
          isContainActiveTask = true
        end
      end
    end
  end
  if isShowTips and isContainActiveTask then
    self.cacheTaskId = taskId
    local battleThemConf = _G.DataConfigManager:GetBattlePassThemeConf(battlePassInfo.theme_id)
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local conf = _G.DataConfigManager:GetLocalizationConf("BP_theme_locked_tips")
    local okbtnStr = _G.DataConfigManager:GetLocalizationConf("tips_dialog_butten_accept").msg
    local noBtnStr = _G.DataConfigManager:GetLocalizationConf("tips_dialog_butten_cancel").msg
    if battleThemConf then
      local curPassName = battleThemConf.theme_name
      local title = LuaText.battlepassmodule_1
      local des = string.format(conf.msg, curPassName, curPassName)
      local leftText = noBtnStr or LuaText.battlepassmodule_2
      local rightText = okbtnStr or LuaText.battlepassmodule_3
      local Context = DialogContext()
      Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.GetAllRewardCallblack):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
  return isShowTips and isContainActiveTask
end

function BattlePassModule:GetAllRewardCallblack(isOk)
  if isOk then
    if self.cacheTaskId then
      self.DisTaskRewardReq = true
      local req = _G.ProtoMessage:newZoneTaskRewardReq()
      req.task_list = self.cacheTaskId
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.ZoneTaskRewardRsp)
    else
      local req = _G.ProtoMessage:newZoneReceiveBattlePassAllTaskReq()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_BATTLE_PASS_ALL_TASK_REQ, req, self, self.ZoneReceiveBattlePassAllTaskRsp)
    end
  end
end

function BattlePassModule:SendZoneReceiveBattlePassRewardReq(receiveAll, index)
  local req = _G.ProtoMessage:newZoneReceiveBattlePassRewardReq()
  if receiveAll then
    req.receive_all_reward = true
  else
    req.index = index
    req.receive_all_reward = false
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_RECEIVE_BATTLE_PASS_REWARD_REQ, req, self, self.OnZoneReceiveBattlePassRewardRsp, true)
end

function BattlePassModule:OnCmdReceiveBattlePassReward(receiveAll, index)
  if self.isGetAwardMsg then
    self:UnlockIsSelectBtn()
    return
  end
  self.isGetAwardMsg = true
  self:SendZoneReceiveBattlePassRewardReq(receiveAll, index)
end

function BattlePassModule:OnZoneReceiveBattlePassRewardRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data:SetPlayerBattlePassInfo(_rsp)
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateBattlePassInfo)
    if _rsp.ret_info.goods_reward.rewards and #_rsp.ret_info.goods_reward.rewards > 0 then
      local newRewards = self:MergeRewards(_rsp.ret_info.goods_reward.rewards)
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
    else
      self:UnlockIsSelectBtn()
    end
  else
    self:UnlockIsSelectBtn()
  end
  self.isGetAwardMsg = false
end

function BattlePassModule:MergeRewards(_rspRewards)
  local rewardsDic = {}
  for _, goodsItem in ipairs(_rspRewards) do
    local itemId = goodsItem.id
    if goodsItem.type == _G.Enum.GoodsType.GT_PET then
      itemId = goodsItem.pet_data.conf_id
    end
    local mergeKey = tostring(goodsItem.type) .. "_" .. tostring(itemId)
    if rewardsDic[mergeKey] then
      rewardsDic[mergeKey].num = rewardsDic[mergeKey].num + goodsItem.num
    else
      rewardsDic[mergeKey] = goodsItem
    end
  end
  local newRewards = {}
  for _, goodsItem in pairs(rewardsDic) do
    table.insert(newRewards, goodsItem)
  end
  return newRewards
end

function BattlePassModule:OnBuyLevelReq(_goodsShopId, _levelNum, Caller, Callback)
  local goodsShopConf = DataConfigManager:GetNormalShopConf(_goodsShopId)
  if nil == goodsShopConf then
    Log.Error("Invalid GoodsId", _goodsShopId)
    return
  end
  local curTime = self:GetCurServerTime()
  local bpConf = _G.DataConfigManager:GetBattlePassConf(self.data.PlayerBattlePassInfo.battle_pass_id)
  local bpCloseTime = self:ConvertToTimeSeconds(bpConf.close_time)
  if curTime > bpCloseTime then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error6)
    return
  end
  local req = _G.ProtoMessage:newZoneShopBuyItemReq()
  table.insert(req.buy_item_info, {
    goods_shop_id = _goodsShopId,
    goods_item_num = _levelNum,
    goods_id = _goodsShopId
  })
  req.shop_id = goodsShopConf.shop_id
  self.buyLevelCallback = Callback
  self.buyLevelCaller = Caller
  local reqBuyItemData = {
    req = req,
    Caller = self,
    rspHandler = self.ZoneShopBuyItemRsp,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "BattlePassModule:OnCmdBuyLevelReq"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdBuyItemReq, reqBuyItemData)
end

function BattlePassModule:ZoneShopBuyItemRsp(_rsp)
  if self.buyLevelCaller and self.buyLevelCallback then
    self.buyLevelCallback(self.buyLevelCaller, _rsp)
  end
  if 0 == _rsp.ret_info.ret_code then
    self:GetNewBattlePassInfo()
    self:ShowOrHideMainTime(true)
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function BattlePassModule:OnUnlockBattlePass(goodsShoopId)
  local goodsShopConf = DataConfigManager:GetNormalShopConf(goodsShoopId)
  if nil == goodsShopConf then
    Log.Error("Invalid GoodsId", goodsShoopId)
    return
  end
  local req = _G.ProtoMessage:newZoneShopBuyItemReq()
  self.goodsShoopId = goodsShoopId
  table.insert(req.buy_item_info, {
    goods_shop_id = goodsShoopId,
    goods_item_num = 1,
    goods_id = goodsShoopId
  })
  req.shop_id = goodsShopConf.shop_id
  local reqBuyItemData = {
    req = req,
    Caller = self,
    rspHandler = self.UnlockBattlePassRsp,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "BattlePassModule:OnUnlockBattlePass"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdBuyItemReq, reqBuyItemData)
end

function BattlePassModule:ShowUnlockPassSuccessReward(_rsp)
  self:GetNewBattlePassInfo()
  local theme_id = self.data.PlayerBattlePassInfo.theme_id
  local gift_id = _G.DataConfigManager:GetBattlePassThemeConf(theme_id).collection_gift_id
  local goods_id = _G.DataConfigManager:GetBattlePassGiftConf(gift_id).gift_goods_id
  if goods_id == self.goodsShoopId then
    local rewards = {}
    if _rsp.ret_info.goods_reward.rewards and #_rsp.ret_info.goods_reward.rewards > 0 then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1066, "BattlePassModule:UnlockBattlePassRsp")
      for i, v in pairs(_rsp.ret_info.goods_reward.rewards) do
        local reward = {}
        reward.type = v.type
        reward.num = v.num
        if reward.type == _G.Enum.GoodsType.GT_PET then
          reward.id = v.pet_data.conf_id
        else
          reward.id = v.id
        end
        table.insert(rewards, reward)
      end
    end
    self:CacheRewardPanel(rewards)
  end
  _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.OnUnlockPassSuccess, _rsp.shop_id)
  self.goodsShoopId = nil
end

function BattlePassModule:UnlockBattlePassRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    local function callback()
      self:ShowUnlockPassSuccessReward(_rsp)
    end
    
    local desStr = _G.DataConfigManager:GetLocalizationConf("MALL_BUY_ITEM_SUCCESS").msg
    local titleStr = _G.DataConfigManager:GetLocalizationConf("player_unstuck_confirm_title").msg
    local Context = DialogContext()
    Context:SetTitle(titleStr):SetContent(desStr):SetMode(DialogContext.Mode.NotBtn):SetCallback(self, callback):SetCloseOnCancel(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function BattlePassModule:CacheRewardPanel(reward)
  self.cacheReward = reward
end

function BattlePassModule:OnTriggerCacheRewardPanel()
  if self.cacheReward then
    _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, self.cacheReward, LuaText.battlepassmodule_4)
  end
  self.cacheReward = nil
end

function BattlePassModule:GetNewBattlePassInfo(rewardTips)
  self.isShowPassRewardTips = rewardTips
  local req = ProtoMessage:newZoneGetBattlePassInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BATTLE_PASS_INFO_REQ, req, self, self.OnGetNewBattlePassInfo)
end

function BattlePassModule:OnGetNewBattlePassInfo(_rsp)
  Log.Dump(_rsp, 9, "#OnGetNewBattlePassInfo")
  if 0 == _rsp.ret_info.ret_code then
    self.data:SetPlayerBattlePassInfo(_rsp)
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateBattlePassInfo)
  end
  if self.isShowPassRewardTips then
    self:ShowBPRewardLimitTips()
    self.isShowPassRewardTips = nil
  end
end

function BattlePassModule:OnZonePlayerBattlePassExpNotify(notify)
  local battlePassInfo = self.data:GetPlayerBattlePassInfo()
  if battlePassInfo and battlePassInfo.exp_info then
    battlePassInfo.exp_info.level = notify.level
    battlePassInfo.exp_info.exp = notify.exp
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateBattlePassInfo)
  end
end

function BattlePassModule:GetCurrentThemeImagePath(filename)
  local bpInfo = self.data:GetPlayerBattlePassInfo()
  local themeId = bpInfo.theme_id
  if nil == themeId or 0 == themeId then
    return
  end
  local themeCfg = _G.DataConfigManager:GetBattlePassThemeConf(themeId)
  if nil == themeCfg then
    return
  end
  local newPath = string.format("%s/%s'", themeCfg.theme_art_set, filename)
  return newPath, themeId
end

function BattlePassModule:DoDeactiveBattlepass()
  if self:IsActivitePass() then
    return
  end
  if self.ShowDeactivePassTips then
    return
  end
  local Context = DialogContext()
  local titleStr = _G.LuaText.TIPS
  local desStr = _G.LuaText.bp_umg_close
  Context:SetTitle(titleStr):SetContent(desStr):SetMode(DialogContext.Mode.NotBtn):SetCallback(self, function()
    self.ShowDeactivePassTips = false
    self:CloseAllPanel()
  end):SetCloseOnCancel(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  self.ShowDeactivePassTips = true
end

function BattlePassModule:IsActivitePass()
  local bpTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_CONF)
  local bpCfgs = bpTable:GetAllDatas()
  local t = {}
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  for _, cfg in pairs(bpCfgs) do
    local open_time = self:ConvertToTimeSeconds(cfg.open_time)
    local close_time = self:ConvertToTimeSeconds(cfg.close_time)
    if curTime >= open_time and curTime <= close_time then
      t[#t + 1] = {
        id = cfg.id,
        open_time = open_time,
        close_time = close_time
      }
    end
  end
  table.sort(t, function(a, b)
    return a.id < b.id
  end)
  for _, cfg in ipairs(t) do
    if curTime >= cfg.open_time and curTime <= cfg.close_time then
      return true
    end
  end
  return false
end

function BattlePassModule:GetCurrentActivePass()
  local bpTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.BATTLE_PASS_CONF)
  local bpCfgs = bpTable:GetAllDatas()
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  local activePasses = {}
  for _, cfg in pairs(bpCfgs) do
    local open_time = self:ConvertToTimeSeconds(cfg.open_time)
    local close_time = self:ConvertToTimeSeconds(cfg.close_time)
    if curTime >= open_time and curTime <= close_time then
      activePasses[#activePasses + 1] = cfg
    end
  end
  if #activePasses > 0 then
    table.sort(activePasses, function(a, b)
      return a.id < b.id
    end)
    return activePasses[1]
  end
  return nil
end

function BattlePassModule:ZoneTaskInfoNotify(notify)
  if self.data == nil then
    return
  end
  if self:HasPanel("BattlePassAwardMain") then
    return
  end
  local playerPassInfo = self.data:GetPlayerBattlePassInfo()
  if nil == playerPassInfo or nil == playerPassInfo.battle_pass_id then
    return
  end
  local passId = playerPassInfo.battle_pass_id
  if 0 == passId then
    return
  end
  local theme_id = playerPassInfo.theme_id
  if nil == theme_id or 0 == theme_id then
    return
  end
  if notify.task_info_list then
    for i, taskInfo in pairs(notify.task_info_list) do
      local lastTaskInfo = self.data:GetPassTaskInfoById(taskInfo.id)
      local lastTaskState = lastTaskInfo and lastTaskInfo.state or 0
      if lastTaskState ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT and taskInfo.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        local taskConf = _G.DataConfigManager:GetTaskConf(taskInfo.id)
        if taskConf and (taskConf.task_class == _G.Enum.TaskClassType.TCT_BP or taskConf.task_class == _G.Enum.TaskClassType.TCT_BP_ROUTINE or taskConf.task_class == _G.Enum.TaskClassType.TCT_BP_REPEAT) then
          _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenMainUIDownTips, 1, taskInfo, _G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY)
        end
      end
    end
    if #notify.task_info_list > 0 then
      self.data:SetPassAllTaskDic(notify.task_info_list)
    end
  end
end

function BattlePassModule:ZoneGoodsRewardNotify(notify)
  local RewardList = {}
  local info = notify.ret_info
  local goods_reward = info and info.goods_reward
  local GoodsItems = goods_reward and goods_reward.rewards
  if GoodsItems then
    for _, GoodsItem in ipairs(GoodsItems) do
      if GoodsItem.reward_reason == ProtoEnum.FlowReason.FLOW_REASON_BATTLE_PASS_BUY then
        table.insert(RewardList, GoodsItem)
      end
    end
  end
  if notify.flow_reason == ProtoEnum.FlowReason.FLOW_REASON_BATTLE_PASS_BUY then
    self:GetNewBattlePassInfo()
  end
  if #RewardList > 0 then
    Log.Info("BattlePassModule:ZoneGoodsRewardNotify", #RewardList)
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.OnDirectPurchase, RewardList)
  end
end

function BattlePassModule:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").GET)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TIPS)
end

function BattlePassModule:RemoveNewRedPoints(list)
  local pointData = {}
  for i = 1, #list do
    table.insert(pointData, tostring(list[i]))
  end
  _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, 143, pointData)
end

function BattlePassModule:UpdateRedPointData()
  local tasks = self:OnCmdGetTasksByType(_G.Enum.TaskClassType.TCT_BP)
  local passInfo = self.data.PlayerBattlePassInfo
  local curActiveTaskSetIdDic = {}
  for i = 1, #tasks do
    local taskConf = tasks[i].conf
    local setId = taskConf.paragraph_id
    if setId and setId > 0 then
      curActiveTaskSetIdDic[setId] = setId
    end
  end
  local redList = {}
  for _, value in pairs(curActiveTaskSetIdDic) do
    local setId = value
    local redState = self:GetRedDataState(setId)
    if redState then
      table.insert(redList, setId)
    end
  end
  self:ChangePassActiveTaskRedPoint(redList)
end

function BattlePassModule:GetRedDataState(taskSetId)
  local localPlayerId = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local isShowRed = true
  if localPlayerId then
    local redJson = JsonUtils.LoadSaved(string.format("BattlePass/SetId_Red_%s_%s", localPlayerId, taskSetId), {})
    if redJson.state == nil then
      JsonUtils.DumpSaved(string.format("BattlePass/SetId_Red_%s_%s", localPlayerId, taskSetId), {task_set_id = taskSetId, state = true})
      isShowRed = true
    else
      JsonUtils.DumpSaved(string.format("BattlePass/SetId_Red_%s_%s", localPlayerId, taskSetId), {
        task_set_id = taskSetId,
        redJson.state
      })
      isShowRed = redJson.state
    end
  end
  return isShowRed
end

function BattlePassModule:ChangePassActiveTaskRedPoint(red_list)
  _G.NRCModuleManager:DoCmd(RedPointModuleCmd.UpdateWithReasonPointData, _G.Enum.RedPointReason.RPR_BATTLE_PASS_NEW_TASK, red_list)
end

function BattlePassModule:OnCmdIsHavelPassPanel()
  return self:HasPanel("BattlePassSelectPanel") or self:HasPanel("BattlePassAwardMain")
end

function BattlePassModule:OnCmdGetAllRewardConf()
  return self.data.PassRewardCfgs
end

function BattlePassModule:OnRest()
  self.DisTaskRewardReq = false
  self.isGetAwardMsg = false
  self:CloseAllPanel()
  UE4Helper.SetEnableWorldRendering(true)
  self:OnRelogin()
end

function BattlePassModule:OnEnterSceneFinishNtyAckEnd(notify, isReconnecting, isEnteringCell, preMapId, mapID)
  if isEnteringCell and not self.firstGetInfo then
    self:GetNewBattlePassInfo()
    self.firstGetInfo = true
  end
end

function BattlePassModule:OnLoadingUIOpened()
  if self:HasPanel("BattlePassAwardMain") then
    self:CloseAllPanel()
  end
end

function BattlePassModule:OnPetSkillFilterRuleChange(filterRule)
  if self:HasPanel("BattlePassPetDetail") then
    local panel = self:GetPanel("BattlePassPetDetail")
    if panel then
      panel.PetSkillMain:OnPetSkillFilterRuleChange(filterRule)
    end
  end
end

function BattlePassModule:OnPetSkillSortRuleChange(id, skillSortReverse)
  if self:HasPanel("BattlePassPetDetail") then
    local panel = self:GetPanel("BattlePassPetDetail")
    if panel then
      panel.PetSkillMain:OnPetSkillSortRuleChange(id, skillSortReverse)
    end
  end
end

function BattlePassModule:OnCmdOpenPurchaseSuccessfulTips(purchaseData)
  if self:HasPanel("BattlePurchaseSuccessfulTips") then
    local panel = self:GetPanel("BattlePurchaseSuccessfulTips")
  else
    self:OpenPanel("BattlePurchaseSuccessfulTips", purchaseData)
  end
end

function BattlePassModule:OnCmdClosePurchaseSuccessfulTips()
  if self:HasPanel("BattlePurchaseSuccessfulTips") then
    self:ClosePanel("BattlePurchaseSuccessfulTips")
  end
end

function BattlePassModule:ChangeThemeAndUnlockGift(ItemsID, ItemsUniqueId)
  local itemConf = _G.DataConfigManager:GetBagItemConf(ItemsID)
  if not itemConf then
    Log.Error("itemConf is nil")
    return
  end
  local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
  local bagModule = _G.NRCModuleManager:GetModule("BagModule")
  if not bagModule then
    Log.Error("bagModule is nil")
    return
  end
  local expireStatus = bagModule.data:CheckItemExpireStatus(itemConf, expireThreshold)
  if expireStatus.isExpired then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_expired)
    return
  end
  local use_action = itemConf.item_behavior[1] and itemConf.item_behavior[1].use_action
  if use_action ~= _G.Enum.ItemBehavior.IB_UNLOCK_BP_BASICS_SPECIFIC and use_action ~= _G.Enum.ItemBehavior.IB_UNLOCK_BP_UPGRADE_SPECIFIC then
    Log.Error("itemConf is not IB_UNLOCK_BP_BASICS_SPECIFIC or IB_UNLOCK_BP_UPGRADE or IB_UNLOCK_BP_UPGRADE_SPECIFIC")
    return
  end
  local ratio = itemConf.item_behavior[1] and itemConf.item_behavior[1].ratio
  if nil == ratio or 0 == ratio then
    Log.Error("ratio is nil or 0")
    return
  end
  local themeId = ratio[2]
  local BPID = ratio[1]
  local BPConf = _G.DataConfigManager:GetBattlePassConf(BPID)
  if not BPConf then
    Log.Error("BPConf is nil")
    return
  end
  local open_time = self:ConvertToTimeSeconds(BPConf.open_time)
  local close_time = self:ConvertToTimeSeconds(BPConf.close_time)
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  if close_time < curTime or open_time > curTime then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetLocalizationConf("bp_close").msg)
    return
  end
  local curPassInfo = self.data:GetPlayerBattlePassInfo()
  if curPassInfo.theme_id == themeId then
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassPurchasePanel)
    return
  end
  self.ChangeThemeAndUnlockGoodsId = ItemsID
  self.ChangeThemeAndUnlockGoodsUniqueId = ItemsUniqueId
  local req = _G.ProtoMessage:newZoneSelectBattlePassThemeReq()
  req.theme_id = themeId
  self.theme_id = themeId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SELECT_BATTLE_PASS_THEME_REQ, req, self, self.OnChangeThemeRsp)
end

function BattlePassModule:OnChangeThemeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPlayerBattlePassInfo(rsp)
    if self.theme_id then
      self.data.PlayerBattlePassInfo.theme_id = self.theme_id
      _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.UpdateBattlePassInfo)
      self.theme_id = nil
    end
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPassPurchasePanel)
  end
end

function BattlePassModule:InitSpineWidgetForPanel(panel, panelName, umgName)
  Log.Info("[BattlePassSpine] InitSpineWidgetForPanel: panelName:", panelName, "umgName:", umgName)
  if not panel then
    Log.Warning("[BattlePassModule] InitSpineWidgetForPanel: panel is nil")
    return
  end
  local currentActivePassCfg = self:GetCurrentActivePass()
  if not currentActivePassCfg then
    Log.Warning("[BattlePassModule] InitSpineWidgetForPanel: currentActivePassCfg is nil")
    return
  end
  local themeIds = currentActivePassCfg.theme_id
  if not themeIds then
    Log.Warning("[BattlePassModule] InitSpineWidgetForPanel: themeIds is nil")
    return
  end
  Log.Info("[BattlePassSpine] InitSpineWidgetForPanel: themeIds count:", #themeIds)
  self:DoInitSpineWidgetForPanel(panel, themeIds, panelName, umgName)
end

function BattlePassModule:DoInitSpineWidgetForPanel(panel, themeIds, panelName, umgName)
  for index, themeId in ipairs(themeIds) do
    local themeUIConf = _G.DataConfigManager:GetBattlePassUiTheme(themeId)
    if not themeUIConf then
      Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: themeUIConf is nil for themeId:", themeId)
    elseif not themeUIConf.spine_atlas or not themeUIConf.spine_skeletondata then
      Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: spine_atlas or spine_skeletondata is nil for themeId:", themeId)
    else
      local atlas = self.preLoadThemeResMap[themeUIConf.spine_atlas]
      local skeletonData = self.preLoadThemeResMap[themeUIConf.spine_skeletondata]
      if atlas and not UE4.UObject.IsValid(atlas) then
        Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: PreLoaded atlas is invalid(GC), clearing. path:", themeUIConf.spine_atlas)
        self.preLoadThemeResMap[themeUIConf.spine_atlas] = nil
        atlas = nil
      end
      if skeletonData and not UE4.UObject.IsValid(skeletonData) then
        Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: PreLoaded skeletonData is invalid(GC), clearing. path:", themeUIConf.spine_skeletondata)
        self.preLoadThemeResMap[themeUIConf.spine_skeletondata] = nil
        skeletonData = nil
      end
      if not atlas or not skeletonData then
        Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: PreLoadRes not found or invalid, using async load. atlas:", nil ~= atlas, "skeletonData:", nil ~= skeletonData, "path:", themeUIConf.spine_atlas)
        self:LoadSpineWidgetAsyncForPanel(panel, themeUIConf, panelName, umgName)
      elseif themeUIConf.widget_group then
        for _, widgetGroup in ipairs(themeUIConf.widget_group) do
          if widgetGroup.umgname == umgName then
            local spineWidgetName = widgetGroup.spinewigetname
            if spineWidgetName then
              local spineWidget = panel[spineWidgetName]
              if spineWidget then
                self:SetupSpineWidget(spineWidget, atlas, skeletonData, spineWidgetName)
              else
                Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: SpineWidget not found:", spineWidgetName, "for themeId:", themeId)
              end
            end
          end
        end
      else
        Log.Warning("[BattlePassModule] DoInitSpineWidgetForPanel: widget_group is nil for themeId:", themeId)
      end
    end
  end
end

function BattlePassModule:SetupSpineWidget(spineWidget, atlas, skeletonData, widgetName)
  if not spineWidget or not UE4.UObject.IsValid(spineWidget) then
    Log.Warning("[BattlePassModule] SetupSpineWidget: spineWidget is nil or invalid for", widgetName)
    return false
  end
  if not atlas or not UE4.UObject.IsValid(atlas) then
    Log.Warning("[BattlePassModule] SetupSpineWidget: atlas is nil or invalid for", widgetName)
    return false
  end
  if not skeletonData or not UE4.UObject.IsValid(skeletonData) then
    Log.Warning("[BattlePassModule] SetupSpineWidget: skeletonData is nil or invalid for", widgetName)
    return false
  end
  spineWidget:ClearTrack(0)
  spineWidget.skeletondata = skeletonData
  spineWidget.atlas = atlas
  spineWidget:LuaSynchronizeProperties()
  spineWidget:SetRenderOpacity(1.0)
  spineWidget:SetAnimation(0, "Idle", true)
  Log.Debug("[BattlePassModule] SetupSpineWidget: Successfully initialized", widgetName, "SpineWidget")
  return true
end

function BattlePassModule:LoadSpineWidgetAsyncForPanel(panel, themeUIConf, panelName, umgName)
  Log.Info("[BattlePassSpine] LoadSpineWidgetAsyncForPanel: panelName:", panelName, "umgName:", umgName)
  if not panel then
    Log.Warning("[BattlePassModule] LoadSpineWidgetAsyncForPanel: panel is nil")
    return
  end
  if not themeUIConf or not themeUIConf.widget_group then
    Log.Warning("[BattlePassModule] LoadSpineWidgetAsyncForPanel: themeUIConf or widget_group is nil")
    return
  end
  for _, widgetGroup in ipairs(themeUIConf.widget_group) do
    if widgetGroup.umgname == umgName then
      local spineWidgetName = widgetGroup.spinewigetname
      if spineWidgetName then
        local spineWidget = panel[spineWidgetName]
        if spineWidget and UE4.UObject.IsValid(spineWidget) then
          spineWidget:SetRenderOpacity(0.0)
        end
      end
    end
  end
  for _, widgetGroup in ipairs(themeUIConf.widget_group) do
    if widgetGroup.umgname == umgName then
      local spineWidgetName = widgetGroup.spinewigetname
      if spineWidgetName then
        local spineWidget = panel[spineWidgetName]
        if spineWidget then
          self:LoadSingleSpineWidgetAsync(panel, spineWidget, themeUIConf, spineWidgetName)
        else
          Log.Warning("[BattlePassModule] LoadSpineWidgetAsyncForPanel: SpineWidget not found:", spineWidgetName)
        end
      end
    end
  end
end

function BattlePassModule:LoadSingleSpineWidgetAsync(panel, spineWidget, themeUIConf, widgetName)
  if not panel then
    Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: panel is nil for", widgetName)
    return
  end
  if not spineWidget then
    Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: spineWidget is nil for", widgetName)
    return
  end
  local atlasLoaded = false
  local skeletonLoaded = false
  local loadedAtlas, loadedSkeletonData
  local module = self
  
  local function CheckSpineReady()
    Log.Info("[BattlePassSpine] LoadSingleAsync CheckSpineReady: atlasLoaded:", atlasLoaded, "skeletonLoaded:", skeletonLoaded, "for", widgetName)
    if atlasLoaded and skeletonLoaded then
      if not UE4.UObject.IsValid(panel) then
        Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: panel already destroyed for", widgetName)
        return
      end
      if not UE4.UObject.IsValid(spineWidget) then
        Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: spineWidget already destroyed for", widgetName)
        return
      end
      if loadedAtlas and loadedSkeletonData then
        local success = module:SetupSpineWidget(spineWidget, loadedAtlas, loadedSkeletonData, widgetName)
        if success then
          Log.Info("[BattlePassSpine] LoadSingleAsync: success for", widgetName)
        else
          Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: SetupSpineWidget failed for", widgetName)
        end
      else
        Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: Resources not loaded for", widgetName)
      end
    end
  end
  
  panel:LoadPanelRes(themeUIConf.spine_skeletondata, 255, function(caller, resRequest, asset)
    Log.Info("[BattlePassSpine] LoadSingleAsync: skeletonData callback, asset:", nil ~= asset, "for", widgetName)
    if asset then
      loadedSkeletonData = asset
      skeletonLoaded = true
      CheckSpineReady()
    else
      Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: Failed to load skeletonData for", widgetName)
    end
  end, nil, nil)
  panel:LoadPanelRes(themeUIConf.spine_atlas, 255, function(caller, resRequest, asset)
    Log.Info("[BattlePassSpine] LoadSingleAsync: atlas callback, asset:", nil ~= asset, "for", widgetName)
    if asset then
      loadedAtlas = asset
      atlasLoaded = true
      CheckSpineReady()
    else
      Log.Warning("[BattlePassModule] LoadSingleSpineWidgetAsync: Failed to load atlas for", widgetName)
    end
  end, nil, nil)
end

function BattlePassModule:IsThemeA(theme_id)
  if nil == theme_id then
    Log.Warning("IsThemeA: theme_id is nil")
    return false
  end
  local themeCfg = _G.DataConfigManager:GetBattlePassUiTheme(theme_id)
  if nil ~= themeCfg then
    return themeCfg.is_theme_a
  else
    Log.Warning("IsThemeA: themeCfg is nil")
    return false
  end
end

function BattlePassModule:OnCmdChangeThemeColor(PanelName, PanelInstane, theme_id)
  self.data:ChangeThemeColor(PanelName, PanelInstane, theme_id)
end

function BattlePassModule:OnCloseBattlePassPurchasePanel()
  if self:HasPanel("BattlePurchasePanel") then
    self:ClosePanel("BattlePurchasePanel")
  end
end

function BattlePassModule:OnCmdReqGetAnotherThemeFriends(isGetDetail)
  if isGetDetail and not self.data:CanReqFriendTheme() then
    Log.Debug("BattlePassModule:OnCmdReqGetAnotherThemeFriends CD\228\184\173\239\188\140\228\189\191\231\148\168\231\188\147\229\173\152\230\149\176\230\141\174")
    return
  end
  local battlePassInfo = self.data:GetPlayerBattlePassInfo()
  if not battlePassInfo or battlePassInfo.battle_pass_brief_info.gift_grade == _G.ProtoEnum.BattlePassGiftGrade.BPGG_FREE then
    Log.Warning("BattlePassModule:OnCmdReqGetAnotherThemeFriends \230\156\170\233\148\129\229\174\154\228\184\187\233\162\152")
    return
  end
  local req = _G.ProtoMessage:newZoneGetSelectAnotherBattlePassThemeFriendsReq()
  req.is_get_detail = isGetDetail or false
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SELECT_ANOTHER_BATTLE_PASS_THEME_FRIENDS_REQ, req)
end

function BattlePassModule:OnGetAnotherThemeFriendsRsp(rsp)
  if rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
    Log.Warning("OnGetAnotherThemeFriendsRsp error:", rsp.ret_info.ret_code)
    return
  end
  local friendList = rsp.friend_role_list or {}
  local isFirst = 1 == rsp.pack_index
  local isEnd = rsp.is_end
  if isFirst then
    self.data:ClearAnotherThemeFriendTempList()
    self.data:SetAnotherThemeFriendCount(rsp.friend_info.friend_num)
  end
  self.data:AppendAnotherThemeFriendTempList(friendList)
  if isEnd then
    local isOnlyGetNum = rsp.friend_info.friend_num > 0 and 0 == #friendList
    if not isOnlyGetNum then
      local fullList = self.data:GetAnotherThemeFriendTempList()
      local sortedList = self.data:SortFriendList(fullList)
      self.data:SetAnotherThemeFriendList(sortedList)
    end
    self.data:ClearAnotherThemeFriendTempList()
    _G.NRCEventCenter:DispatchEvent(BattlePassModuleEvent.RefreshAnotherThemeFriendUI)
  end
end

function BattlePassModule:OnCmdOpenSelectFriendPanel()
  self:OpenPanel("BattlePassSelectFriend")
end

function BattlePassModule:OnCmdCloseSelectFriendPanel()
  if self:HasPanel("BattlePassSelectFriend") then
    self:ClosePanel("BattlePassSelectFriend")
  end
end

function BattlePassModule:ZoneBattlePassTaskUpdateNotify(notify)
  Log.Info("ZoneBattlePassTaskUpdateNotify")
  self.data:ClearPassAllTaskDic()
  Log.Dump(notify, 4, "ZoneBattlePassTaskUpdateNotify")
  if notify then
    local taskIDs = {}
    if notify.task_info and notify.task_info.daily_task_ids then
      for _, taskID in ipairs(notify.task_info.daily_task_ids) do
        table.insert(taskIDs, taskID)
      end
    end
    if notify.task_info and notify.task_info.repeat_task_ids then
      for _, taskID in ipairs(notify.task_info.repeat_task_ids) do
        table.insert(taskIDs, taskID)
      end
    end
    if #taskIDs > 0 then
      self:ZoneTaskQueryReq(taskIDs)
    end
  end
  Log.Info("ZoneBattlePassTaskUpdateNotify,\233\135\141\230\150\176\232\142\183\229\143\150bp\228\191\161\230\129\175,\229\136\183\230\150\176\231\187\143\233\170\140\231\173\137")
  self:GetNewBattlePassInfo()
end

function BattlePassModule:OnEnterBattle()
  if self:HasPanel("BattlePassAwardMain") then
    self:CloseAllPanel()
    UE4.UNRCTUIStatics.SetEnableUIOnlyRendering(false)
  end
end

return BattlePassModule
