local PayEnum = {}
PayEnum.MidasCodeAndroid = {
  SYSTEM_ERROR = -1,
  PAY_SUCCESS = 0,
  USER_CANCELED = 2,
  PARAM_ERROR = 3,
  STATUS_UNKNOWN = 5,
  STATUS_UNKNOWN_1 = 100,
  SDK_NOT_DISTRIBUTED = 7,
  LOGIN_EXPIRED = 1018,
  OFFER_ID_ERR = 1016,
  OFFER_ENV_ERR = 1001,
  BACKGROUND_ERR = 1003,
  NETWORK_ERR = 20101,
  WECHAT_PAY_FAIL = 210001,
  QQ_PAY_FAIL = 230000,
  NRC_INIT_MIDAS_FAIL = -99,
  TOKEN_URL_EXPIRED = 1005
}
PayEnum.MidasCodeIOS = {
  RISK_CONTROL = -5,
  BACKGROUND_ERR = -1,
  PAY_SUCCESS = 0,
  USER_CANCELED = 2,
  PARAM_ERROR = 3,
  LAUNCH_APPLE_PAY_FAIL = 4,
  NEED_RESTART_GAME = 5,
  IN_PROGRESS = 6,
  OS_SYSTEM_LOW = 8,
  TESTFLIGHT_VER_ERR = 9,
  GET_APPLE_GOODS_OVERTIME = 10,
  GET_APPLE_GOODS_OVERTIME_1 = 11,
  NOT_IN_MAIN_THREAD = 12,
  APPLE_GOODS_IN_PURCHASE_PROGRESS = 13,
  NRC_INIT_MIDAS_FAIL = -99,
  TOKEN_URL_EXPIRED = 1005
}
PayEnum.MidasCodeOpenHarmony = {
  PURCHASED_FAILURE = -1,
  USER_CANCELLED = 2,
  PARAMS_INVALID = 3,
  UNKOWN_ERROR = 4,
  NETWORK_ERROR = 5,
  LOGIN_EXPIRED = 6,
  HIT_ORDER_RISK_CONTROL = 7,
  HIT_PROVIDE_RISK_CONTROL = 8
}
PayEnum.MidasCodePC = {USER_CANCELED = 2, PAGE_ERROR = 1}
PayEnum.CodeNetErr = {
  PayEnum.MidasCodeAndroid.STATUS_UNKNOWN,
  PayEnum.MidasCodeAndroid.STATUS_UNKNOWN_1,
  PayEnum.MidasCodeAndroid.NETWORK_ERR,
  PayEnum.MidasCodeIOS.PARAM_ERROR
}
PayEnum.PayStatus = {
  None = 0,
  PayForItemSvrReq = 2,
  PayForItemMidasReq = 3
}
PayEnum.PayType = {PurchaseTool = 0, DirectPurchase = 1}
PayEnum.FailType = {
  OTHER = -1,
  NEED_LOGIN = 1,
  BACKGROUND_ERROR = 2,
  USER_CANCEL = 3,
  INIT_SDK_FAIL = 4
}
PayEnum.PayOpType = {
  QueryGoods = 0,
  QueryGoodsFinish = 1,
  LaunchPay = 2,
  FinishPay = 3,
  RequestReLogin = 4
}
return PayEnum
