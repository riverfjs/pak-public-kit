local StarChainModuleEvent = require("NewRoco.Modules.System.StarChain.StarChainModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local NavigationComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.NavigationComponent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local StarChainModule = NRCModuleBase:Extend("StarChainModule")

function StarChainModule:OnConstruct()
  _G.StarChainModuleCmd = reload("NewRoco.Modules.System.StarChain.StarChainModuleCmd")
  self.data = self:SetData("StarChainModuleData", "NewRoco.Modules.System.StarChain.StarChainModuleData")
  self:RegisterCmd(_G.StarChainModuleCmd.OpenStarChainPanel, self.DoCmdOpenStarChainPanel)
  self:RegisterCmd(_G.StarChainModuleCmd.SelectItemChange, self.DoCmdSelectItemChange)
  self:RegisterCmd(_G.StarChainModuleCmd.OpenStarChainAwardPanel, self.DoCmdOpenStarChainAwardPanel)
  self:RegisterCmd(_G.StarChainModuleCmd.GetCurrentAwardId, self.DoCmdGetCurrentAwardId)
  self:RegisterCmd(_G.StarChainModuleCmd.OpenRecoveryTime, self.OnCmdOpenRecoveryTime)
  self:RegisterCmd(_G.StarChainModuleCmd.OpenStarDebrisRecoveryTime, self.OnCmdOpenStarDebrisRecoveryTime)
  self:RegisterCmd(_G.StarChainModuleCmd.StarChainChangeUpdateTime, self.OnCmdStarChainChangeUpdateTime)
  self:RegisterCmd(_G.StarChainModuleCmd.SetShopSourceReturnFlag, self.OnCmdSetShopSourceReturnFlag)
  self:RegisterCmd(_G.StarChainModuleCmd.GetShopSourceReturnFlag, self.OnCmdGetShopSourceReturnFlag)
  self:RegisterCmd(_G.StarChainModuleCmd.GetShopSourceReturnFunc, self.OnCmdGetShopSourceReturnFunc)
  self:RegisterCmd(_G.StarChainModuleCmd.SetShopSourceReturnFunc, self.OnCmdSetShopSourceReturnFunc)
  self:RegisterCmd(_G.StarChainModuleCmd.ShowStarDebrisText, self.OnCmdShowStarDebrisText)
  self:RegisterCmd(_G.StarChainModuleCmd.ShowOrHideMoneyBtn, self.OnCmdShowOrHideMoneyBtn)
  self:RegisterCmd(_G.StarChainModuleCmd.RefreshConfirmation, self.OnCmdRefreshConfirmation)
  self:RegisterCmd(_G.StarChainModuleCmd.OpenUseItemPanel, self.CmdOpenUseItemPanel)
  self:RegisterCmd(_G.StarChainModuleCmd.SendExchangeReq, self.SendExchangeReq)
  self:RegisterCmd(_G.StarChainModuleCmd.ShowOrHideMapRecoveryTime, self.ShowOrHideMapRecoveryTime)
  self:RegPanel("UMG_StarChain", "UMG_StarChain", _G.Enum.UILayerType.UI_LAYER_POPUP, "open", "close")
  self:RegPanel("UMG_StarChainAward", "UMG_StarChainAward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true)
  self:RegPanel("UMG_Map_RecoveryTime", "UMG_Map_RecoveryTime", Enum.UILayerType.UI_LAYER_POPUP, "FadeIn", "FadeOut")
  self:RegPanel("UMG_UseItemPanel", "UMG_UseItemPanel", Enum.UILayerType.UI_LAYER_POPUP)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  _G.NRCEventCenter:RegisterEvent("MainUIModule", self, SceneEvent.OnPlayerDead, self.DeadCloseStarChainPanel)
  _G.NRCEventCenter:RegisterEvent("StarChainModule", self, SceneEvent.OnRelogin, self.DeadCloseStarChainPanel)
end

function StarChainModule:OnActive()
end

function StarChainModule:OnRelogin()
end

function StarChainModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnPlayerDead, self.DeadCloseGamePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.DeadCloseStarChainPanel)
end

function StarChainModule:OnDestruct()
end

function StarChainModule:DoCmdOpenStarChainPanel(_data)
  self:OpenPanel("UMG_StarChain", _data)
end

function StarChainModule:OnCmdOpenRecoveryTime(_Param, OpenType, IsCall, touchLimitData)
  self.OpenType = OpenType
  self.PlayIsMove = _Param
  self.IsCall = IsCall
  self.touchLimitData = touchLimitData
  self:GetStarChainRecoverTime()
end

function StarChainModule:GetStarChainRecoverTime()
  local req = _G.ProtoMessage:newZoneGetStarRecoverTimeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_STAR_RECOVER_TIME_REQ, req, self, self.OnStarChainRecoverTime)
end

function StarChainModule:OnStarChainRecoverTime(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:OpenPanel("UMG_Map_RecoveryTime", rsp, self.PlayIsMove, self.OpenType, self.IsCall, nil, self.touchLimitData)
  elseif self.touchLimitData then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, self.touchLimitData.panel).MONEYTIMECLICK
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, self.touchLimitData.module, self.touchLimitData.panel, touchReasonType)
  end
end

function StarChainModule:ShowOrHideMapRecoveryTime(_IsVisibility)
  if self.data:GetIsOpenBuyDiamondGiftItem() and self.data:GetIsCall() and self:HasPanel("UMG_Map_RecoveryTime") then
    local Panel = self:GetPanel("UMG_Map_RecoveryTime")
    if Panel then
      Panel:SetVisibilityInfo(_IsVisibility)
    end
  end
end

function StarChainModule:OnCmdOpenStarDebrisRecoveryTime(_Param, OpenType, IsCall, recoveryItemType, touchLimitData)
  self.OpenType = OpenType
  self.PlayIsMove = _Param
  self.IsCall = IsCall
  self.recoveryItemType = recoveryItemType
  self.touchLimitData = touchLimitData
  self:GetStarDebrisRecoverTime()
end

function StarChainModule:GetStarDebrisRecoverTime()
  local req = _G.ProtoMessage:newZoneGetStarDebrisInfoReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_STAR_DEBRIS_INFO_REQ, req, self, self.OnStarDebrisRecoverTime)
end

function StarChainModule:OnStarDebrisRecoverTime(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:OpenPanel("UMG_Map_RecoveryTime", rsp, self.PlayIsMove, self.OpenType, self.IsCall, self.recoveryItemType, self.touchLimitData)
  elseif self.touchLimitData then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, self.touchLimitData.panel).MONEYTIMECLICK
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, self.touchLimitData.module, self.touchLimitData.panel, touchReasonType)
  end
end

function StarChainModule:OnCmdStarChainChangeUpdateTime(_num)
  self:DispatchEvent(StarChainModuleEvent.StarChainChangeUpdateTimeEvent, _num)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.UpdateStarChain)
end

function StarChainModule:OnCmdSetShopSourceReturnFlag(Flag)
  self.data:SetShopSourceReturnFlag(Flag)
end

function StarChainModule:OnCmdGetShopSourceReturnFlag()
  return self.data:GetShopSourceReturnFlag()
end

function StarChainModule:OnCmdSetShopSourceReturnFunc(Func, Call)
  self.data:SetShopSourceReturnFunc(Func, Call)
end

function StarChainModule:CmdOpenUseItemPanel(Item)
  self:OpenPanel("UMG_UseItemPanel", Item)
end

function StarChainModule:OnCmdShowStarDebrisText(bIsShow)
  if self:HasPanel("UMG_StarChainAward") then
    local panel = self:GetPanel("UMG_StarChainAward")
    if bIsShow then
    else
    end
  end
end

function StarChainModule:OnCmdShowOrHideMoneyBtn(bIsHide)
  if self:HasPanel("UMG_StarChainAward") then
    local panel = self:GetPanel("UMG_StarChainAward")
    panel:ShowOrHideMoneyBtn(bIsHide)
  end
end

function StarChainModule:OnCmdRefreshConfirmation(recoveryItemType, _data, _index)
  local panel = self:GetPanel("UMG_StarChainAward")
  if panel then
    panel:RefreshConfirmation(recoveryItemType, _data, _index)
  else
    Log.Error("StarChainModule:OnCmdRefreshConfirmation UMG_StarChainAward is not exist")
  end
end

function StarChainModule:SendExchangeReq(exchangeId, exchangeNum, Type, actor_id, cost_goods_id)
  self.ExChangeType = Type
  local req = _G.ProtoMessage:newZoneExchangeReq()
  req.npc_space_obj_id = actor_id
  req.exchange_item.id = exchangeId
  req.exchange_item.num = exchangeNum
  local exchangeConf = _G.DataConfigManager:GetExchangeConf(exchangeId)
  if not exchangeConf then
    return
  end
  if 1 ~= #exchangeConf.cost_item then
    Log.Error("\230\152\159\228\185\139\233\147\190\231\154\132cost_item\233\149\191\229\186\166\229\191\133\233\161\187\228\184\1861\239\188\140\232\175\183\230\179\168\230\132\143")
    return
  end
  local costItem = exchangeConf.cost_item[1]
  for _, itemId in ipairs(cost_goods_id) do
    table.insert(req.exchange_item.cost_goods, {
      goods_type = costItem.cost_goods_type,
      goods_id = itemId,
      goods_num = costItem.cost_goods_num * exchangeNum
    })
  end
  Log.Debug("StarChainModule:SendExchangeReq", exchangeId)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_EXCHANGE_REQ, req, self, self.OnZoneExchangeRsp, true, true)
end

function StarChainModule:OnZoneExchangeRsp(_rsp)
  Log.Debug(_rsp.ret_info.ret_code, "StarChainModule:OnZoneExchangeRsp")
  if 0 == _rsp.ret_info.ret_code then
    local itemInfos = {}
    local rewards = _rsp.ret_info.goods_reward.rewards
    for _, v in ipairs(rewards) do
      local itemId = v.id
      local itemText = tostring(v.num)
      table.insert(itemInfos, {
        itemId = itemId,
        itemText = itemText,
        id = itemId,
        num = v.num,
        type = v.type
      })
    end
    if #itemInfos > 0 and 0 == self.ExChangeType then
    elseif #itemInfos > 0 and 1 == self.ExChangeType then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, itemInfos)
      _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.StarChainChangeUpdateTime, itemInfos[1].num)
    end
    self:OnPurchaseSucceed()
    self:DispatchEvent(StarChainModuleEvent.PurchaseSucceed)
    _G.NRCModuleManager:GetModule("NPCShopUIModule"):DispatchEvent(StarChainModuleEvent.PurchaseSucceed)
  elseif _rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_EXCHANGE_TIMES_LIMIT then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_starchain_3)
  else
    local key = string.format("Error_Code_%d", _rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function StarChainModule:OnCmdGetShopSourceReturnFunc()
  return self.data:GetShopSourceReturnFunc()
end

function StarChainModule:OnPurchaseSucceed()
  if self:HasPanel("UMG_Map_RecoveryTime") then
    local Panel = self:GetPanel("UMG_Map_RecoveryTime")
    if Panel then
      Panel:Cancel()
    end
  end
  self:OnCmdShowOrHideMoneyBtn(false)
  _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OnCmdSetShopSourceReturnFlag, false)
  _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.VisiblePrewarInformationPanel)
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.ShowPetRecoveryTime)
end

function StarChainModule:DeadCloseStarChainPanel()
  local IsRecover = false
  if self:HasPanel("UMG_StarChainAward") then
    IsRecover = true
    self:ClosePanel("UMG_StarChainAward")
  end
  if self:HasPanel("UMG_StarChain") then
    IsRecover = true
    self:ClosePanel("UMG_StarChain")
  end
  if self:HasPanel("UMG_Map_RecoveryTime") then
    self:ClosePanel("UMG_Map_RecoveryTime")
  end
  if self:HasPanel("UMG_UseItemPanel") then
    self:ClosePanel("UMG_UseItemPanel")
  end
  if self.CurrentAction then
    self.CurrentAction:Finish(false)
  end
  self.CurrentAction = nil
  if IsRecover then
    self:PlayerUpdate()
  end
end

function StarChainModule:PlayerUpdate()
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, true)
  localPlayer.inputComponent:SetCameraControlEnable(self, true)
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  if _G.BattleManager.isInBattle then
    _G.BattleManager.NeedOpenMain = true
    NRCModuleManager:DoCmd(MainUIModuleCmd.ClosePanelLobbyMain)
  end
end

function StarChainModule:DoCmdSelectItemChange(_index, uiData)
  self:DispatchEvent(StarChainModuleEvent.Tips_SelectItemChange, _index, uiData)
end

function StarChainModule:OnPlayerDataUpdate()
  self:DispatchEvent(StarChainModuleEvent.Tips_PlayerDataChange, true)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.UpdateStarChain)
end

function StarChainModule:DoCmdGetCurrentAwardId()
  return self.CurrentAwardId
end

function StarChainModule:DoCmdOpenStarChainAwardPanel(Action, InstanceID)
  local localPlayer = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.inputComponent:SetInputEnable(self, false)
  localPlayer.inputComponent:SetCameraControlEnable(self, false)
  self:OpenPanel("UMG_StarChainAward")
  if Action then
    self.CurrentAction = Action
  end
  if InstanceID then
    self.CurrentAwardId = InstanceID
  end
  self:RegisterEvent(self, StarChainModuleEvent.EnterPanelClosed, self.OnCloseEnterPanel)
end

function StarChainModule:OnCloseEnterPanel(Ret_Param, IsReplenish)
  if nil == Ret_Param or nil == IsReplenish then
    return
  end
  if false == IsReplenish then
    self:PlayerUpdate()
  else
    _G.NRCModuleManager:DoCmd(_G.StarChainModuleCmd.OpenRecoveryTime, true)
  end
  self.Ret_Param = Ret_Param
  self:ReachTheGoal(true)
end

function StarChainModule:ReachTheGoal(Success)
  if Success and self.CurrentAction then
    self.CurrentAction:Finish(nil, nil, self.Ret_Param)
    self.CurrentAction = nil
    self:UnRegisterEvent(self, StarChainModuleEvent.EnterPanelClosed)
  end
end

function StarChainModule:RegPanel(name, path, layer, openAnim, closeAnim, isSingleTouchPanel)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/StarChain/Res/%s", path)
  registerData.panelLayer = layer
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  registerData.isSingleTouchPanel = isSingleTouchPanel
  self:RegisterPanel(registerData)
end

return StarChainModule
