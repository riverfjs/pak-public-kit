local AppearanceModuleEnum = {}
AppearanceModuleEnum.OpenTipType = {
  None = 0,
  FASHION_CHANGENAME = 1,
  FASHION_CHANGESUIT = 2,
  FASHION_CLOSE = 3,
  SALON_CONFIRM = 4,
  SALON_CLOSE = 5
}
AppearanceModuleEnum.FashionMallShopId = {
  SEASONAL_COMBINATION_BAG = 103,
  RANDOM_FASHION = 104,
  DISCOUNT_FASHION = 105,
  CLOSET = 106,
  EXCHANGE_FASHION = 8070
}
AppearanceModuleEnum.FashionMedalState = {
  Unlocked = 1,
  NotUpgraded = 2,
  UnLockable = 3,
  NotUnLockable = 4,
  NotShow = 5
}
AppearanceModuleEnum.FashionMedalSortType = {
  UnLockTime = 1,
  Pet = 2,
  Style = 3
}
AppearanceModuleEnum.Sort_typeToPriority = {
  [_G.Enum.GoodsType.GT_FASHION_SUITS] = 1,
  [_G.Enum.GoodsType.GT_FASHION] = 2,
  [_G.Enum.GoodsType.GT_CARD_SKIN] = 3,
  [_G.Enum.GoodsType.GT_NONE] = math.maxinteger
}
AppearanceModuleEnum.Sort_fashionTypePriority = {
  [_G.Enum.FashionLabelType.FLT_WAND] = 1,
  [_G.Enum.FashionLabelType.FLT_PENDANTA] = 2,
  [_G.Enum.FashionLabelType.FLT_BEGIN] = math.maxinteger
}
AppearanceModuleEnum.SuitState = {
  Obtained = 1,
  NotOnShelf = 2,
  OnShelf = 3,
  OffShelf = 4,
  NotPurchasable = 5
}
AppearanceModuleEnum.ExclusionPanelType = {
  None = 0,
  GorgeousMedal = 1,
  UpgradeComponent = 2
}
return AppearanceModuleEnum
