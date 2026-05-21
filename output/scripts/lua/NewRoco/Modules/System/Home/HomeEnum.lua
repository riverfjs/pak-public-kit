local HomeEnum = {}
HomeEnum.EnmPanelMode = {
  Init = 1,
  Manager = 2,
  Placing = 3
}
HomeEnum.EnmPanelTickSource = {Placing = 1}
HomeEnum.AssetRegistry = "/Game/NewRoco/Modules/System/Home/PlacementAsset/BP_NRCHomeAssetRegistry.BP_NRCHomeAssetRegistry"
HomeEnum.GroundViewIcon = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_LookingDown_png.img_HomeDecoration_LookingDown_png'"
HomeEnum.WallViewIcon = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_FrontalView_png.img_HomeDecoration_FrontalView_png'"
HomeEnum.FurnitureCreationCapture_C = "/Game/NewRoco/Modules/System/Home/Res/BP_FurnitureCreationSceneCapture.BP_FurnitureCreationSceneCapture_C"
HomeEnum.HomeLightLevel = "World'/Game/ArtRes/Level/Game/Homeworld/A1_Home/MainLevel_Editor_Lights.MainLevel_Editor_Lights'"
HomeEnum.Create_Idle_Sequence = "LevelSequence'/Game/NewRoco/Modules/System/Home/Res/RuntimeSequences/Create_Idle.Create_Idle'"
HomeEnum.Create_Up_Sequence = "LevelSequence'/Game/NewRoco/Modules/System/Home/Res/RuntimeSequences/Create_Up.Create_Up'"
HomeEnum.Create_Down_Sequence = "LevelSequence'/Game/NewRoco/Modules/System/Home/Res/RuntimeSequences/Create_Down.Create_Down'"
HomeEnum.EnmEditPropsStatus = {
  PROJECTILE_FAILED = "HomePropsService.PROJECTILE_FAILED",
  PRE_CHECK_FAILED = "HomePropsService.PRE_CHECK_FAILED",
  PRE_CHECK_FAILED_GUID = "HomePropsService.PRE_CHECK_FAILED_GUID",
  PRE_CHECK_FAILED_ONLY_GROUND = "HomePropsService.PRE_CHECK_FAILED_ONLY_GROUND",
  PRE_CHECK_FAILED_ONLY_WALL = "HomePropsService.PRE_CHECK_FAILED_ONLY_WALL",
  PRE_CHECK_FAILED_NO_HOME_PLANE = "HomePropsService.PRE_CHECK_FAILED_NO_HOME_PLANE",
  PRE_CHECK_FAILED_OTHER_ROOM_HOME_PLANE = "HomePropsService.PRE_CHECK_FAILED_OTHER_ROOM_HOME_PLANE",
  PRE_LOAD = "HomePropsService.Edit.PRE_LOAD",
  PRE_CHECK_FAILED_ESTABLISH = "HomePropsService.Edit.PRE_CHECK_FAILED_ESTABLISH",
  PRE_CHECK_FAILED_MAX_NUM = "HomePropsService.Edit.PRE_CHECK_FAILED_MAX_NUM",
  PRE_CHECK_FAILED_NO_CONF = "HomePropsService.Edit.PRE_CHECK_FAILED_NO_CONF",
  PRE_CHECK_FAILED_EDIT_ONLY_ONE = "HomePropsService.Edit.PRE_CHECK_FAILED_EDIT_ONLY_ONE",
  LOAD_FAILED = "HomePropsService.Edit.LOAD_FAILED",
  SPAWN_FAILED = "HomePropsService.Edit.SPAWN_FAILED",
  SPAWN_FAILED_BY_INVALID_AREA = "HomePropsService.SPAWN_FAILED_BY_INVALID_AREA",
  SPAWN_SUCCESS = "HomePropsService.Edit.SPAWN_SUCCESS",
  UNLOAD_PACK_UP = "HomePropsService.Edit.UNLOAD_PACK_UP"
}
HomeEnum.PropsDisableMask = {Normal = 2, Culling = 4}
HomeEnum.EnmExpandStatus = {
  None = "HomeEnum.EnmExpandStatus.None",
  Expanding = "HomeEnum.EnmExpandStatus.Expanding",
  ExpandEstablished = "HomeEnum.EnmExpandStatus.ExpandEstablished"
}
HomeEnum.FURNITURE_NPC_STATE = {
  Free = "Free",
  OccupiedWithPet = "OccupiedWithPet"
}
HomeEnum.SEED_BAG_TAB = {Bag = 1, Craft = 2}
HomeEnum.HomePetStatus = {
  Unknown = "Unknown",
  Free = "Free",
  InProduce = "InProduce",
  ProduceFinished = "ProduceFinished"
}
HomeEnum.HomeownerWaitConfirmation = {
  VisitorEnterHome = 1,
  VisitorLeaveHome = 2,
  OwnerEnterHome = 3,
  OwnerLeaveHome = 4
}
HomeEnum.HomeOwnershipStatus = {
  OffLineSelf = 1,
  OffLineOther = 2,
  OnLineOwnerSelf = 3,
  OnLineOwnerOther = 4,
  OnLineMemberOther = 5
}
HomeEnum.Color_PlaceEnabled = UE.FLinearColor(0, 1, 0, 1)
HomeEnum.Color_PlaceDisabled = UE.FLinearColor(1, 0, 0, 1)
HomeEnum.Color_ManagerSelect = UE.FLinearColor(0, 1, 0, 1)
HomeEnum.Color_ComfortInc = UE4.UNRCStatics.HexToSlateColor("#73C615FF")
HomeEnum.Color_ComfortDec = UE4.UNRCStatics.HexToSlateColor("#C6362EFF")
HomeEnum.Color_HomeItem_BgIconList = {
  "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_IconBgWhite_png.img_HomeDecoration_IconBgWhite_png'",
  "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_IconBgGreen_png.img_HomeDecoration_IconBgGreen_png'",
  "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_IconBgBlue_png.img_HomeDecoration_IconBgBlue_png'",
  "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_IconBgPurple_png.img_HomeDecoration_IconBgPurple_png'",
  "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeMain/Frames/img_HomeDecoration_IconBgOrange_png.img_HomeDecoration_IconBgOrange_png'"
}

function HomeEnum.GetHomeItemQualityBgIcon(QualityVal)
  QualityVal = QualityVal or 1
  return HomeEnum.Color_HomeItem_BgIconList[QualityVal] or HomeEnum.Color_HomeItem_BgIconList[1]
end

local CACHE_QUALITY_COLOR = {}

function HomeEnum.GetItemQualityColor(QualityVal)
  QualityVal = QualityVal or 0
  local Color = CACHE_QUALITY_COLOR[QualityVal]
  if Color then
    return Color
  end
  if 0 == QualityVal then
    Color = UE.FLinearColor(1, 1, 1, 1)
  elseif 1 == QualityVal then
    Color = UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1)
  elseif 2 == QualityVal then
    Color = UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2)
  elseif 3 == QualityVal then
    Color = UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3)
  elseif 4 == QualityVal then
    Color = UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4)
  elseif 5 == QualityVal then
    Color = UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5)
  end
  CACHE_QUALITY_COLOR[QualityVal] = Color
  return Color
end

function HomeEnum.GetItemQualityBgImgPath(QualityVal)
  QualityVal = QualityVal or 1
  local PathFmt = "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_FurnitureAtlas_ItemSelect%d_png.img_FurnitureAtlas_ItemSelect%d_png'"
  local Path = string.format(PathFmt, QualityVal, QualityVal)
  return Path
end

HomeEnum.FurnitureFilterMode = {}
HomeEnum.FurnitureFilterMode.Bag = 1
HomeEnum.FurnitureFilterMode.BagDecompose = 2
HomeEnum.FurnitureFilterMode.Craft = 3
HomeEnum.FurnitureFilterMode.Atlas = 4

function HomeEnum.MakeFurniturePhotoViewData()
  return {TexturePath = "", FurnitureName = ""}
end

return HomeEnum
