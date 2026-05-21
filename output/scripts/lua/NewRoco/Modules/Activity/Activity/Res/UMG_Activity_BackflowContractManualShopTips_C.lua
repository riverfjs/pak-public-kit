local UMG_Activity_BackflowContractManualShopTips_C = _G.NRCPanelBase:Extend("UMG_Activity_BackflowContractManualShopTips_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Activity_BackflowContractManualShopTips_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
end

function UMG_Activity_BackflowContractManualShopTips_C:OnActive(activity_id)
  self.activity_id = activity_id
  local activity_inst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, activity_id)
  local base_id = _G.DataConfigManager:GetActivityConf(activity_id).base_id[1]
  local tips_data = _G.DataConfigManager:GetActivityRecallbpConf(base_id)
  self.uiData = tips_data
  self.Icon:SetPath(tips_data.advanced_bp_icon)
  self.Title_1:SetText(tips_data.bp_name)
  self.ItemDesc.ScrollTextBlock:SetText(tips_data.advanced_bp_description)
  local iconPath = ActivityUtils.GetItemIconAndQuality(_G.Enum.GoodsType.GT_VITEM, tips_data.advanced_bp_buy_vitem)
  self.Gold_Icon:SetPath(iconPath)
  self.Money_1:SetText(tips_data.advanced_bp_price)
  local hasNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(tips_data.advanced_bp_buy_vitem)
  self.bEnough = hasNum >= tips_data.advanced_bp_price
  if not self.bEnough then
    self.Money_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("C7494AFF"))
  end
  local PopUpData = _G.NRCCommonPopUpData()
  PopUpData.Call = self
  PopUpData.Btn_RightHandler = self.TryUnlock
  PopUpData.Btn_LeftHandler = self.ClosePanel
  PopUpData.ClosePanelHandler = self.ClosePanel
  PopUpData.TitleText = _G.LuaText.recall_bp_buy_window
  PopUpData.Btn_LeftText = _G.LuaText.recall_bp_consider_button
  PopUpData.Btn_RightText = _G.LuaText.recall_bp_buyconfirm_button
  self.PopUp3:SetPanelInfo(PopUpData)
  self.MoneyBtn:InitGridView({
    {
      moneyType = tips_data.advanced_bp_buy_vitem,
      sum = hasNum,
      IsShowBuyIcon = true,
      currencyId = tips_data.advanced_bp_buy_vitem
    }
  })
  if activity_inst then
    activity_inst:BindActivityTimeLeft(self.TimerTest)
  else
    self.TimerTest:SetText(_G.LuaText.activity_expired_show_tip)
  end
  self:LoadAnimation(0)
end

function UMG_Activity_BackflowContractManualShopTips_C:TryUnlock()
  if self.bEnough then
    local req = _G.ProtoMessage:newZoneUnlockActivityRecallPaidRewardReq()
    req.activity_id = self.activity_id
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UNLOCK_ACTIVITY_RECALL_PAID_REWARD_REQ, req, self, self.OnUnlock)
  else
    _G.NRCModeManager:DoCmd(_G.ShopModuleCmd.OnCmdOpenTopUpShop)
  end
end

function UMG_Activity_BackflowContractManualShopTips_C:OnUnlock(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(ActivityModuleEvent.OnBPUnlock)
    self.PopUp3:OnBtnClose()
  end
end

function UMG_Activity_BackflowContractManualShopTips_C:ClosePanel()
  self:LoadAnimation(2)
end

function UMG_Activity_BackflowContractManualShopTips_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    local activity_inst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, self.activity_id)
    if activity_inst then
      activity_inst:UnBindActivityTimeLeft(self.TimerTest)
    end
    self:DoClose()
  end
end

function UMG_Activity_BackflowContractManualShopTips_C:OnPcClose()
  self.PopUp3:OnBtnClose()
end

return UMG_Activity_BackflowContractManualShopTips_C
