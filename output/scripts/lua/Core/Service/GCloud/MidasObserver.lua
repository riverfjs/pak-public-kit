local PayEnum = require("NewRoco.Modules.System.ChargePay.PayEnum")
local PayModuleEvent = require("NewRoco.Modules.System.ChargePay.PayModuleEvent")
local PayModuleCmd = require("NewRoco.Modules.System.ChargePay.PayModuleCmd")
local JsonUtils = require("Common.JsonUtils")
local MidasObserver = NRCClass()

function MidasObserver:Initialize(Parent)
  self.Parent = Parent
end

function MidasObserver:OnMidasLoginExpired()
  Log.Debug("OnMidasLoginExpired invoked")
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayInfo, PayEnum.PayStatus.None)
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayGoodsInfo, nil)
  NRCEventCenter:DispatchEvent(PayModuleEvent.MidasPayFailed, -1, PayEnum.FailType.NEED_LOGIN)
end

function MidasObserver:OnMidasPayFinished(APMidasResponse)
  _G.ZoneServer:CloseWaitingUI("Pay")
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayStatus, PayEnum.PayStatus.None)
  _G.NRCModuleManager:DoCmd(PayModuleCmd.ReportPayStatus, PayEnum.PayOpType.FinishPay, APMidasResponse and APMidasResponse.resultCode or -999)
  Log.Debug("APMidasResponse.retCode is", APMidasResponse.resultCode)
  local extTable = _G.NRCModuleManager:DoCmd(PayModuleCmd.GetPayGoodsInfo)
  _G.NRCModuleManager:DoCmd(PayModuleCmd.UpdateBalance)
  if APMidasResponse.resultCode == PayEnum.MidasCodeAndroid.PAY_SUCCESS or APMidasResponse.resultCode == PayEnum.MidasCodeIOS.PAY_SUCCESS then
    NRCEventCenter:DispatchEvent(PayModuleEvent.MidasPaySuccess, table.contains(PayEnum.PayType, extTable.GoodsType) and extTable.GoodsType or -1, extTable.ShopID ~= nil and extTable.ShopID or 0)
    local payingGoodsId = _G.NRCModuleManager:DoCmd(PayModuleCmd.GetGoodsId)
    _G.NRCModuleManager:DoCmd(PayModuleCmd.StartLimitPay, payingGoodsId)
    _G.NRCModuleManager:DoCmd(PayModuleCmd.SetGoodsId, nil)
    _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayGoodsInfo, nil)
    return
  elseif APMidasResponse.resultCode == PayEnum.MidasCodeAndroid.USER_CANCELED and RocoEnv.PLATFORM_ANDROID or APMidasResponse.resultCode == PayEnum.MidasCodeIOS.USER_CANCELED and RocoEnv.PLATFORM_IOS or APMidasResponse.resultCode == PayEnum.MidasCodeOpenHarmony.USER_CANCELLED and RocoEnv.PLATFORM_OPENHARMONY then
    NRCEventCenter:DispatchEvent(PayModuleEvent.MidasPayFailed, table.contains(PayEnum.PayType, extTable.GoodsType) and extTable.GoodsType or -1, PayEnum.FailType.USER_CANCEL)
  elseif APMidasResponse.resultCode == PayEnum.MidasCodeAndroid.LOGIN_EXPIRED then
    NRCEventCenter:DispatchEvent(PayModuleEvent.MidasPayFailed, table.contains(PayEnum.PayType, extTable.GoodsType) and extTable.GoodsType or -1, PayEnum.FailType.NEED_LOGIN)
  else
    Log.Debug("OnMidasPayFinishedAndroid with resultCode ", APMidasResponse.resultCode)
    NRCEventCenter:DispatchEvent(PayModuleEvent.MidasPayFailed, table.contains(PayEnum.PayType, extTable.GoodsType) and extTable.GoodsType or -1, PayEnum.FailType.OTHER)
  end
  _G.GEMPostManager:SendPayFailEvent(APMidasResponse.resultCode or PayEnum.FailType.OTHER, not string.IsNilOrEmpty(APMidasResponse.resultMsg) and APMidasResponse.resultMsg or "")
  _G.NRCModuleManager:DoCmd(PayModuleCmd.ShowFailTips, APMidasResponse.resultCode)
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetPayGoodsInfo, nil)
  _G.NRCModuleManager:DoCmd(PayModuleCmd.SetGoodsId, nil)
end

return MidasObserver
