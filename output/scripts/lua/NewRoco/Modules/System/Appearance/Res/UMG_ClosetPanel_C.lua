local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local RedPointModuleEvent = require("NewRoco.Modules.System.RedPoint.RedPointModuleEvent")
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")

local function IsSameGlassInfo(a, b)
  if (nil == a or nil == next(a)) and (nil == b or nil == next(b)) then
    return true
  end
  if nil == a or nil == b then
    return false
  end
  return (a.glass_type or 0) == (b.glass_type or 0) and (a.glass_value or 0) == (b.glass_value or 0)
end

local UMG_ClosetPanel_C = _G.NRCPanelBase:Extend("UMG_ClosetPanel_C")
local FunctionEntranceMain = 0

function UMG_ClosetPanel_C:OnConstruct()
  self.data = self.module:GetData("AppearanceModuleData")
  self.shopItemsList = {}
  self.npcAction = nil
  self.TouchStartTime = 0
  self.functionBanUIController = FunctionBanUIController()
  local functionBanUIController = self.functionBanUIController
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnTabVisibilityChangeHandler, self, -1)
  end
  functionBanUIController:Activate()
end

function UMG_ClosetPanel_C:OnActive(npcAction, bFastDressUp, bDirectToUpgrade, suitId, defaultUpgradeSelectIndex, defaultTabIndex, defaultSubTabIndex, bSkipSaveOnExit)
  if self.module.animManager and not bDirectToUpgrade then
    local animPriorityTable = {
      ShiningMedalOpen = 2,
      ShiningMedalLoop = 2,
      ShiningMedalEnd = 2
    }
    self.module.animManager:InitPriorityTable(animPriorityTable)
  end
  self.module:SetChangeSuitWorld(false)
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(1)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, true)
  if not bFastDressUp then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_OPTION)
  else
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_QUICK_FASHION)
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_QUICK_FASHION)
    if StateGroup then
      _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPause)
      _G.NRCAudioManager:BatchSetState(StateGroup)
    end
  end
  self.NRCSwitcher_620:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCSwitcher_620:SetActiveWidgetIndex(0)
  self.bEnterFilterGlassItemState = false
  self.data:BuildAllClothShopInfoMap()
  self:RequestExchangeShopData()
  self.data:BuildTimeTokenDic()
  self.redDotMap, self.needToEraseSet = self:_GetRedDotLabelMap()
  self.lastTryOnId = 0
  self.originalSalon = nil
  self.originalFashion = nil
  self.bIsWandTabSelected = false
  self.bIsOpeningUpgradeComponent = false
  self.bUpgradeZoomIn = false
  self.lastSelectHorizontalTabIndex = -1
  self.lastSelectTabType = 0
  self.data.curTryOnItemInfo = {
    type = _G.Enum.GoodsType.GT_NONE,
    id = 0
  }
  self.bCanUpdateCloset = true
  self.bClosetDirty = false
  self:_CacheOwnedItemCount()
  if npcAction then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.module:CreateClosetAvatarPlayer(npcAction)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if bFastDressUp then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.QuickChangeSubLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadPanelCallback)
    self.QuickChangeSubLoader:LoadPanel(nil)
    self.QuickChangeSubLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.QuickChangeSubLoader:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OnCmdZoneGetFashionBondLastTabReq)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurrentSelectItemInfo, nil)
  self.ColorfulDyeing.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadGlassDetailPanelCallBack)
  self.ColorfulDyeing:LoadPanel(nil)
  self.npcAction = npcAction
  self.bFastDressUp = bFastDressUp
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.defaultTabIndex = defaultTabIndex
  self.defaultSubTabIndex = defaultSubTabIndex
  self:UpdatePanelInfo()
  self.bTouchEnded = true
  self:SetUpDateRegister(false)
  self.curFashionUIData = nil
  self.tabConfId = 0
  if self.Suit then
    self.Suit:InitPanel(self)
  end
  self.MedalEntrance.RedDot:SetupKey(409)
  self.bDirectToUpgrade = bDirectToUpgrade
  self.bDirectToUpgradeSuitId = suitId
  self.directToUpgradeDefaultIndex = defaultUpgradeSelectIndex
  self.bSkipSaveOnExit = bSkipSaveOnExit or false
  if self.bDirectToUpgrade then
    self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.InitCurSelectedItemGlassMap)
end

function UMG_ClosetPanel_C:OnLoadGlassDetailPanelCallBack()
  self.GlassDetailPanel = self.ColorfulDyeing:GetPanel()
  self:CheckNeedToShowGlassDetails()
end

function UMG_ClosetPanel_C:CheckNeedToShowGlassDetails()
  if self.GlassDetailPanel then
    self.GlassDetailPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local itemInfo = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurrentSelectItemInfo)
    if itemInfo and itemInfo.unlockedGlassInfo and #itemInfo.unlockedGlassInfo > 0 and self.GlassDetailPanel then
      self.GlassDetailPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.GlassDetailPanel:UpdateState(itemInfo.itemID, itemInfo.wearingGlassInfo, itemInfo.unlockedGlassInfo)
    end
  end
end

function UMG_ClosetPanel_C:UpdateDazzling(item_id, glass_info)
  local itemCount = self.Buy_List:GetTotalItemNumber()
  for i = 0, itemCount - 1 do
    local item = self.Buy_List:GetItemByIndex(i)
    if item and item.uiData.id == item_id then
      item.Dazzling:UpdateState(true, glass_info)
    end
  end
end

function UMG_ClosetPanel_C:CheckNeedToShowClaimGlassTintBtn()
  local itemInfo = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurrentSelectItemInfo)
  if itemInfo and itemInfo.claimableGlassInfo and #itemInfo.claimableGlassInfo > 0 then
    self.Btn_ReceiveFuel.RedDot:SetupKey(458, {
      itemInfo.itemID
    })
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_1:SetActiveWidgetIndex(2)
    return true
  end
  return false
end

function UMG_ClosetPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  if self.bFastDressUp then
    self.Title1:SetBg("PaperSprite'/Game/NewRoco/Modules/System/Appearance/Raw/Frames/img_bianjiehuanzhuang_png.img_bianjiehuanzhuang_png'")
    self.Title1:SetSubtitle(_G.LuaText.quick_dressup_title)
  else
    self.Title1:SetBg(self.titleConf.head_icon)
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
end

function UMG_ClosetPanel_C:OnLoadPanelCallback()
  self.QuickChangeSubPanel = self.QuickChangeSubLoader:GetPanel()
  self.TargetFOV = nil
  self.CurrentFOV = 70.0
  self.FOVInterpSpeed = 130.0
  self.FastDressUpSkillCamera = nil
  self.FastDressUpMainCamera = self.QuickChangeSubPanel:GetActorByName("MainCamera")
  self.LogoActor_Top, self.LogoActor_Middle, self.LogoActor_Down = nil, nil, nil
  self.LogoMeshComponent_Top, self.LogoMeshComponent_Middle, self.LogoMeshComponent_Down = nil, nil, nil
  self.logoDefaultMaterial_Top, self.logoTransparencyMaterial_Top, self.logoDefaultMaterial_Middle, self.logoTransparencyMaterial_Middle, self.logoDefaultMaterial_Down, self.logoTransparencyMaterial_Down = nil, nil, nil, nil, nil, nil
  self.FastDressUpLogoAssetMap = {}
  self:CreateFastDressUpAvatarPlayer()
  self:GetFastDressUpLogoComponent()
  self:LoadFastDressUpLogoAsset()
end

function UMG_ClosetPanel_C:GetFastDressUpLogoComponent()
  local LogoTop = self.QuickChangeSubPanel:GetActorByName("LogoTop")
  if LogoTop then
    local MeshComponent = LogoTop:GetComponentByClass(UE4.UStaticMeshComponent)
    if MeshComponent then
      self.logoDefaultMaterial_Top = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(MeshComponent:GetMaterial(0), "")
      UE4.UNRCStatics.AddToRoot(self.logoDefaultMaterial_Top)
    end
    self.LogoActor_Top = LogoTop
    self.LogoMeshComponent_Top = MeshComponent
  end
  local LogoMiddle = self.QuickChangeSubPanel:GetActorByName("LogoMiddle")
  if LogoMiddle then
    local MeshComponent = LogoMiddle:GetComponentByClass(UE4.UStaticMeshComponent)
    if MeshComponent then
      self.logoDefaultMaterial_Middle = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(MeshComponent:GetMaterial(0), "")
      UE4.UNRCStatics.AddToRoot(self.logoDefaultMaterial_Middle)
    end
    self.LogoActor_Middle = LogoMiddle
    self.LogoMeshComponent_Middle = MeshComponent
  end
  local LogoDown = self.QuickChangeSubPanel:GetActorByName("LogoDown")
  if LogoDown then
    local MeshComponent = LogoDown:GetComponentByClass(UE4.UStaticMeshComponent)
    if MeshComponent then
      self.logoDefaultMaterial_Down = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(MeshComponent:GetMaterial(0), "")
      UE4.UNRCStatics.AddToRoot(self.logoDefaultMaterial_Down)
    end
    self.LogoActor_Down = LogoDown
    self.LogoMeshComponent_Down = MeshComponent
  end
end

function UMG_ClosetPanel_C:LoadFastDressUpLogoAsset()
  local logoPath1 = "Texture2D'/Game/ArtRes/Level/UI/QuickChange/Tex/T_Logo_V1.T_Logo_V1'"
  local logoPath2 = "Texture2D'/Game/ArtRes/Level/UI/QuickChange/Tex/T_Logo_V2.T_Logo_V2'"
  local logoPath3 = "Texture2D'/Game/ArtRes/Level/UI/QuickChange/Tex/T_Logo_V3.T_Logo_V3'"
  local logoPath4 = "Texture2D'/Game/ArtRes/Level/UI/QuickChange/Tex/T_Logo_V4.T_Logo_V4'"
  local logoPath5 = "Texture2D'/Game/ArtRes/Level/UI/QuickChange/Tex/T_Logo_V5.T_Logo_V5'"
  local logoTranMtl = "MaterialInstanceConstant'/Game/ArtRes/Level/UI/QuickChange/Materials/FBB_BLACK/MI_FBB_BLACK_Tran.MI_FBB_BLACK_Tran'"
  local logoDecTranMtl = "MaterialInstanceConstant'/Game/ArtRes/Level/UI/QuickChange/Materials/MI_Logo_V2_Decorate_Tran.MI_Logo_V2_Decorate_Tran'"
  local logoTopMtl = "MaterialInstanceConstant'/Game/ArtRes/Level/UI/QuickChange/Materials/Black/MI_Black_Tran.MI_Black_Tran'"
  self:LoadPanelRes(logoPath1, 255, self.OnLoadLogoAsset1Success)
  self:LoadPanelRes(logoPath2, 255, self.OnLoadLogoAsset2Success)
  self:LoadPanelRes(logoPath3, 255, self.OnLoadLogoAsset3Success)
  self:LoadPanelRes(logoPath4, 255, self.OnLoadLogoAsset4Success)
  self:LoadPanelRes(logoPath5, 255, self.OnLoadLogoAsset5Success)
  self:LoadPanelRes(logoTranMtl, 255, self.OnLoadMiddleLogoMtlSuccess)
  self:LoadPanelRes(logoDecTranMtl, 255, self.OnLoadDownLogoDecMtlSuccess)
  self:LoadPanelRes(logoTopMtl, 255, self.OnLoadTopLogoMtlSuccess)
end

function UMG_ClosetPanel_C:OnBlandLoadSuccess(resRequest, Asset, blandId)
  self.FastDressUpLogoAssetMap[blandId] = Asset
  if self.curSuitBrand == blandId then
    self:RefreshBrandLogoByBrandId(self.curSuitBrand, true)
  end
end

function UMG_ClosetPanel_C:OnLoadLogoAsset1Success(resRequest, Asset)
  local brand = Enum.FashionBondBand.FBB_OPERA
  self:OnBlandLoadSuccess(resRequest, Asset, brand)
end

function UMG_ClosetPanel_C:OnLoadLogoAsset2Success(resRequest, Asset)
  local brand = Enum.FashionBondBand.FBB_NATURE
  self:OnBlandLoadSuccess(resRequest, Asset, brand)
end

function UMG_ClosetPanel_C:OnLoadLogoAsset3Success(resRequest, Asset)
  local brand = Enum.FashionBondBand.FBB_FANTASY
  self:OnBlandLoadSuccess(resRequest, Asset, brand)
end

function UMG_ClosetPanel_C:OnLoadLogoAsset4Success(resRequest, Asset)
  local brand = Enum.FashionBondBand.FBB_VINTAGE
  self:OnBlandLoadSuccess(resRequest, Asset, brand)
end

function UMG_ClosetPanel_C:OnLoadLogoAsset5Success(resRequest, Asset)
  local brand = Enum.FashionBondBand.FBB_BLACK
  self:OnBlandLoadSuccess(resRequest, Asset, brand)
end

function UMG_ClosetPanel_C:OnLoadMiddleLogoMtlSuccess(resRequest, material)
  if material:IsA(UE4.UMaterialInstanceConstant) then
    self.logoTransparencyMaterial_Middle = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(material, "")
    UE4.UNRCStatics.AddToRoot(self.logoTransparencyMaterial_Middle)
    if self.curSuitBrand then
      self:RefreshBrandLogoByBrandId(self.curSuitBrand, true)
    end
  end
end

function UMG_ClosetPanel_C:OnLoadDownLogoDecMtlSuccess(resRequest, material)
  if material:IsA(UE4.UMaterialInstanceConstant) then
    self.logoTransparencyMaterial_Down = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(material, "")
    UE4.UNRCStatics.AddToRoot(self.logoTransparencyMaterial_Down)
    if self.curSuitBrand then
      self:RefreshBrandLogoByBrandId(self.curSuitBrand, true)
    end
  end
end

function UMG_ClosetPanel_C:OnLoadTopLogoMtlSuccess(resRequest, material)
  if material:IsA(UE4.UMaterialInstanceConstant) then
    self.logoTransparencyMaterial_Top = self.QuickChangeSubPanel:CreateDynamicMaterialInstance(material, "")
    UE4.UNRCStatics.AddToRoot(self.logoTransparencyMaterial_Top)
    if self.curSuitBrand then
      self:RefreshBrandLogoByBrandId(self.curSuitBrand, true)
    end
  end
end

function UMG_ClosetPanel_C:SetBlandLogoHide(bHideBrand)
  if self.LogoActor_Middle then
    self.LogoActor_Middle:SetActorHiddenInGame(bHideBrand)
  end
  if self.LogoActor_Down then
    self.LogoActor_Down:SetActorHiddenInGame(bHideBrand)
  end
end

function UMG_ClosetPanel_C:RefreshBrandLogoByFashionConf(fashionId, fashionItemConf)
  fashionItemConf = fashionItemConf or _G.DataConfigManager:GetFashionItemConf(fashionId)
  if fashionItemConf then
    if fashionItemConf.suits_id then
      local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(tonumber(fashionItemConf.suits_id))
      if fashionSuitConf then
        self:RefreshBrandLogoByBrandId(fashionSuitConf.fashion_bond_band)
      end
    elseif fashionItemConf.fashion_bond_band then
      self:RefreshBrandLogoByBrandId(fashionItemConf.fashion_bond_band)
    end
  end
end

function UMG_ClosetPanel_C:RefreshBrandLogoByBrandId(brand, forceRefresh)
  if self.curSuitBrand == brand and not forceRefresh then
    return
  end
  self.curSuitBrand = brand
  if self.FastDressUpLogoAssetMap and self.FastDressUpLogoAssetMap[brand] and self.logoDefaultMaterial_Middle and self.logoTransparencyMaterial_Middle and self.logoTransparencyMaterial_Down and self.logoTransparencyMaterial_Top then
    self.logoDefaultMaterial_Middle:SetTextureParameterValue("Tex", self.FastDressUpLogoAssetMap[brand])
    self.logoTransparencyMaterial_Middle:SetTextureParameterValue("Tex", self.FastDressUpLogoAssetMap[brand])
    self.logoTransparencyMaterial_Middle:SetScalarParameterValue("Opacoty", 0)
    self.logoTransparencyMaterial_Top:SetScalarParameterValue("Opacity", 0)
    self.LogoMeshComponent_Middle:SetMaterial(0, self.logoTransparencyMaterial_Middle)
    UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Middle)
    self.LogoMeshComponent_Down:SetMaterial(0, self.logoTransparencyMaterial_Down)
    UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Down)
    self.LogoMeshComponent_Top:SetMaterial(0, self.logoTransparencyMaterial_Top)
    UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Top)
    self.starLogoChange = true
    self:SetUpDateRegister(true)
  end
end

function UMG_ClosetPanel_C:CreateFastDressUpAvatarPlayer()
  if not UE4.UObject.IsValid(self.fastDressUpAvatarPlayer) then
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local path
    if player.gender == Enum.ESexValue.SEX_MALE then
      path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer.BP_AvatarPlayer_C'"
    elseif player.gender == Enum.ESexValue.SEX_FEMALE then
      path = "Blueprint'/Game/NewRoco/Modules/Core/Character/Player/BP_AvatarPlayer2.BP_AvatarPlayer2_C'"
    end
    if path then
      self:LoadPanelRes(path, 255, self.FastDressUpModelLoadSucceed, nil, nil)
    end
  end
end

function UMG_ClosetPanel_C:FastDressUpModelLoadSucceed(resRequest, modelClass)
  if not modelClass then
    Log.ErrorFormat("UMG_ClosetPanel_C:FastDressUpModelLoadSucceed \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", resRequest or "")
    return
  end
  Log.Debug("UMG_ClosetPanel_C:FastDressUpModelLoadSucceed")
  local trans = UE4.FTransform(UE4.FQuat(0, 0, 0, 1), UE4.FVector(73, 207, 0), UE4.FVector(1, 1, 1))
  local trans2 = UE4.FTransform(UE4.FQuat.FromAxisAndAngle(UE4.FVector(0, 0, 1), math.rad(50)), UE4.FVector(300, 0, 0))
  self.fastDressUpAvatarPlayer = self.QuickChangeSubPanel:SpawnActor(modelClass, trans)
  if self.fastDressUpAvatarPlayer then
    self.fastDressUpAvatarPlayer:SetIsPlayerModel(true)
    self.fastDressUpAvatarPlayer.Hands.BoundsScale = 10
  end
  self.fastDressUpAvatarWardrobe = self.QuickChangeSubPanel:SpawnActor(modelClass, trans2)
  if self.fastDressUpAvatarWardrobe then
    self.fastDressUpAvatarWardrobe:SetActorHiddenInGame(true)
  end
  local fashionItems, salonIds
  if self.bDirectToUpgrade then
    local suitId = self.bDirectToUpgradeSuitId
    local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
    fashionItems = {}
    if fashionSuitConf then
      for k, v in ipairs(fashionSuitConf.item_id) do
        local temp = {
          wearing_item_id = v,
          wearing_glass = self.module:GetCurSelectedItemGlassMap(v)
        }
        table.insert(fashionItems, temp)
      end
    end
    if self.data.SuitComponentData[suitId] then
      for k, v in pairs(self.data.SuitComponentData[suitId]) do
        if v.bFashion then
          local temp = {
            wearing_item_id = v.id,
            wearing_glass = self.module:GetCurSelectedItemGlassMap(v.id)
          }
          table.insert(fashionItems, temp)
        end
      end
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    salonIds = player:GetSalonIds()
    if self.data.SuitComponentData[suitId] then
      for k, v in ipairs(self.data.SuitComponentData[suitId]) do
        if not v.bFashion then
          table.insert(salonIds, {
            item_wear_id = v.id
          })
        end
      end
    end
  end
  self.module:SetFastDressUpAvatarPlayer(self.fastDressUpAvatarPlayer, self.fastDressUpAvatarWardrobe, true, fashionItems, salonIds)
  if self.bDirectToUpgrade then
    self:GoToSuitUpgrade(self.bDirectToUpgradeSuitId, true)
  end
  UE4Helper.SetEnableWorldRendering(false, false, "UMG_ClosetPanel_C")
  self.defaultSubTabIndex = nil
  self.defaultTabIndex = nil
end

function UMG_ClosetPanel_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SwitchGorgeousMagicUMG, false)
  if self.bFastDressUp == true then
    local subPanelUWorld = self.QuickChangeSubPanel and self.QuickChangeSubPanel:GetViewportWorld() or nil
    self.module:CloseFastDressUpPanelHandle(subPanelUWorld)
  else
    self.module:SyncClosetAvatar2Player()
    self.module:ShowClosetLocalPlayer()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player.viewObj:SetForceHidden(false)
  end
  if self.npcAction then
    self.npcAction:Finish(true)
    self.npcAction = nil
  end
end

function UMG_ClosetPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtnClicked)
  self:AddButtonListener(self.Btn_Confirm.btnLevelUp, self.OnConfirmBtnClicked)
  self:AddButtonListener(self.Return.btnLevelUp, self.OnReturnBtnClicked)
  self.Return.btnLevelUp.OnPressed:Add(self, self.OnClickBtnPressed)
  self.Return.btnLevelUp.OnReleased:Add(self, self.OnClickBtnReleased)
  self:AddButtonListener(self.GorgeousMagicBtn, self.OnClickedGorgeousMagicBtn)
  self:AddButtonListener(self.Btn_UpgradeComponent.btnLevelUp, self.OnUpgradeBtnClicked)
  self:AddButtonListener(self.Btn_ViewComponents.btnLevelUp, self.OnUpgradeBtnClicked)
  self:AddButtonListener(self.Particulars.btnLevelUp, self.OnDetailBtnClicked)
  self:AddButtonListener(self.PurchaseBtn.btnLevelUp, self.OnPurchaseBtnClick)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  self:AddButtonListener(self.MedalEntrance.btnLevelUp, self.OnMedalEntranceBtnClicked)
  self:AddButtonListener(self.Ununlocked.btnLevelUp, self.OnLockButtonClicked)
  self:AddButtonListener(self.Inproperly.btnLevelUp, self.OnInproperlyBtnClicked)
  self:AddButtonListener(self.Btn_Obtain.btnLevelUp, self.OnObtainBtnClicked)
  self:AddButtonListener(self.Btn_ReqColorSuit.btnLevelUp, self.OnReqColorSuitBtnClicked)
  self:AddButtonListener(self.WardrobeBtn.btnLevelUp, self.OnClickedWardrobeBtn)
  self:AddButtonListener(self.ColorfulClothingBtn.btnLevelUp, self.OnClickedColorfulClothingBtn)
  self:AddButtonListener(self.Btn_ReceiveFuel.btnLevelUp, self.OnClickedClaimGlassTint)
  self:AddButtonListener(self.Btn_ClaimVoucher.btnLevelUp, self.OnVoucherClaimButtonClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:RegisterEvent(self, AppearanceModuleEvent.UpdateUpgradeMall, self.UpdatePanelInfoOnUpdateUpgradeMall)
  self:RegisterEvent(self, AppearanceModuleEvent.OnClosetPlayerInitOver, self.OnClosetPlayerInitOver)
  self:RegisterEvent(self, AppearanceModuleEvent.OnOpenClosetPanelSkillEnded, self.OnOpenClosetPanelSkillEnded)
  self:RegisterEvent(self, AppearanceModuleEvent.OnFastDressUpSetSkillCamera, self.OnFastDressUpSetSkillCamera)
  self:RegisterEvent(self, AppearanceModuleEvent.OnFastDressUpChangeViewSkillEnd, self.OnFastDressUpChangeViewSkillEnd)
  self:RegisterEvent(self, AppearanceModuleEvent.OnUnlockNewHeterochromeSuit, self.OnUnlockNewHeterochromeSuit)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, AppearanceModuleEvent.OnGorgeousMedalOpen, self.OnGorgeousMedalOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, AppearanceModuleEvent.OnGorgeousMedalClose, self.OnGorgeousMedalClose)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, AppearanceModuleEvent.OnUpgradeComponentOpen, self.OnUpgradeComponentOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, AppearanceModuleEvent.OnUpgradeComponentClose, self.OnUpgradeComponentClose)
  _G.NRCEventCenter:RegisterEvent("UMG_ClosetPanel_C", self, RedPointModuleEvent.RedPointChange, self.OnRedPointChanged)
  NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:RegisterEvent("UMG_GorgeousMedal_C", self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  self:RegisterEvent(self, AppearanceModuleEvent.OnSelectEmptySuitIndex, self.OnSelectEmptySuitIndex)
  self:RegisterEvent(self, AppearanceModuleEvent.SetAppearanceTabSelectedIndex, self.SetAppearanceTabSelectedIndex)
end

function UMG_ClosetPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:UnRegisterEvent(self, AppearanceModuleEvent.UpdateUpgradeMall, self.UpdatePanelInfoOnUpdateUpgradeMall)
  self:UnRegisterEvent(self, AppearanceModuleEvent.OnClosetPlayerInitOver, self.OnClosetPlayerInitOver)
  self:UnRegisterEvent(self, AppearanceModuleEvent.OnOpenClosetPanelSkillEnded, self.OnOpenClosetPanelSkillEnded)
  self:UnRegisterEvent(self, AppearanceModuleEvent.OnFastDressUpSetSkillCamera, self.OnFastDressUpSetSkillCamera)
  self:UnRegisterEvent(self, AppearanceModuleEvent.OnFastDressUpChangeViewSkillEnd, self.OnFastDressUpChangeViewSkillEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnGorgeousMedalOpen, self.OnGorgeousMedalOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnGorgeousMedalClose, self.OnGorgeousMedalClose)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnUpgradeComponentOpen, self.OnUpgradeComponentOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnUpgradeComponentClose, self.OnUpgradeComponentClose)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagChange)
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagChange)
  self:UnRegisterEvent(self, AppearanceModuleEvent.OnSelectEmptySuitIndex, self.OnSelectEmptySuitIndex)
  self:UnRegisterEvent(self, AppearanceModuleEvent.SetAppearanceTabSelectedIndex, self.SetAppearanceTabSelectedIndex)
end

function UMG_ClosetPanel_C:OnReConnectStart()
  if not self.bFastDressUp then
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    player.viewObj:SetActorHiddenInGame(true)
  end
  self:ConfirmClose()
end

function UMG_ClosetPanel_C:OnDestruct()
  if self.module then
    self.module:SetChangeSuitWorld(true)
  end
  if self.bFastDressUp then
    UE4Helper.SetEnableWorldRendering(nil, false, "UMG_ClosetPanel_C")
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_QUICK_FASHION)
    if StateGroup then
      _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.MusicUPanelPlay)
    end
    _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_QUICK_FASHION)
  end
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.HIDE_OTHER_PLAYER, false)
  if not self.bFastDressUp then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_OPTION)
  end
  self.module:ClearRotAvatarPlayer("Closet")
  self.data.closetChooseOutterTab = -1
  self.data.closetChooseTabType = -1
  self.data.bChooseClosetFashionTab = true
  self:OnRemoveEventListener()
  self.FastDressUpMainCamera = nil
  self.FastDressUpSkillCamera = nil
  if self.FastDressUpLogoAssetMap then
    for i, v in pairs(self.FastDressUpLogoAssetMap) do
      if v and v.Release then
        v:Release()
      end
    end
    self.FastDressUpLogoAssetMap = nil
  end
  UE4.UNRCStatics.RemoveFromRoot(self.logoDefaultMaterial_Top)
  UE4.UNRCStatics.RemoveFromRoot(self.logoTransparencyMaterial_Top)
  UE4.UNRCStatics.RemoveFromRoot(self.logoDefaultMaterial_Middle)
  UE4.UNRCStatics.RemoveFromRoot(self.logoTransparencyMaterial_Middle)
  UE4.UNRCStatics.RemoveFromRoot(self.logoDefaultMaterial_Down)
  UE4.UNRCStatics.RemoveFromRoot(self.logoTransparencyMaterial_Down)
  local functionBanUIController = self.functionBanUIController
  if functionBanUIController then
    functionBanUIController:Deactivate()
  end
end

function UMG_ClosetPanel_C:OnCloseBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_ClosetPanel_C:OnCloseBtnClicked")
  if not self.npcAction and self.bFastDressUp ~= true then
    self:DoClose()
    return
  end
  local bIsProperly = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckOutfitProperly)
  if not bIsProperly then
    self:OpenOutfitProperlyRemindPanel()
    return
  end
  local hasChanged = self:HasChanged()
  if hasChanged then
    self:OpenRemindPanel()
  else
    self:ConfirmClose()
  end
end

function UMG_ClosetPanel_C:OpenOutfitProperlyRemindPanel()
  local text1 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text").msg
  local text2 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text_small").msg
  local text = text1 .. "\n" .. "<orange>" .. text2 .. "</>"
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  CommonPopUpData.ContentText = text
  CommonPopUpData.TitleText = LuaText.TIPS
  CommonPopUpData.Btn_LeftText = LuaText.dressup_popup_giveup
  CommonPopUpData.Btn_RightText = LuaText.dressup_popup_autosave
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.OnOutfitProperlyPanelConfirmBtnClicked
  CommonPopUpData.Btn_LeftHandler = self.OnOutfitProperlyPanelConfirmBtnClicked
  CommonPopUpData.Btn_CloseHandler = self.OnPopUpCloseButton
  CommonPopUpData.bPlayBtnSound = false
  _G.NRCModeManager:DoCmd(CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
end

function UMG_ClosetPanel_C:OnOutfitProperlyPanelConfirmBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ClosetPanel_C:OnOk")
  if self.module then
    self.module:OnCmdCloseAppearanceClosetPanel()
  else
    Log.Error("UMG_ClosetPanel_C module is nil")
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.dressup_replace_pajamas_tips)
end

function UMG_ClosetPanel_C:OpenRemindPanel()
  local text1 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text").msg
  local text2 = _G.DataConfigManager:GetLocalizationConf("fashion_close_text_small").msg
  local text = text1 .. "\n" .. "<orange>" .. text2 .. "</>"
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  CommonPopUpData.ContentText = text
  CommonPopUpData.TitleText = LuaText.TIPS
  CommonPopUpData.Btn_LeftText = LuaText.dressup_popup_giveup
  CommonPopUpData.Btn_RightText = LuaText.dressup_popup_autosave
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.SaveAndClosePanel
  CommonPopUpData.Btn_LeftHandler = self.OnOk
  CommonPopUpData.Btn_CloseHandler = self.OnPopUpCloseButton
  CommonPopUpData.bPlayBtnSound = false
  _G.NRCModeManager:DoCmd(CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
end

function UMG_ClosetPanel_C:SaveAndClosePanel()
  self:OnConfirmBtnClicked()
  self:ConfirmClose()
end

function UMG_ClosetPanel_C:OnOk()
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_ClosetPanel_C:OnOk")
  if self.module then
    self.module:OnCmdCloseAppearanceClosetPanel()
  else
    Log.Error("UMG_ClosetPanel_C module is nil")
  end
end

function UMG_ClosetPanel_C:OnCancel()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClosetPanel_C:OnCancel")
end

function UMG_ClosetPanel_C:OnPopUpCloseButton()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_ClosetPanel_C:OnPopUpCloseButton")
end

function UMG_ClosetPanel_C:ConfirmClose()
  if self.bFastDressUp == true then
    local subPanelUWorld = self.QuickChangeSubPanel and self.QuickChangeSubPanel:GetViewportWorld() or nil
    self.module:CloseFastDressUpPanelHandle(subPanelUWorld)
  else
    self.module:SyncClosetAvatar2Player()
    self.module:ShowClosetLocalPlayer()
  end
  if self.npcAction then
    self.npcAction:Finish(true)
    self.npcAction = nil
  end
  self:DoClose()
end

function UMG_ClosetPanel_C:OnSuitButtonClicked(bIsOpened)
  if 15 == self.tabConfId or not self.data.bChooseClosetFashionTab and self.data.closetChooseTabType == _G.Enum.SalonLabelType.SLT_EYEBORWS then
    if bIsOpened then
      self.ColorBottle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.ColorBottle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_ClosetPanel_C:OnVoucherClaimButtonClicked()
  local itemId = self.data:GetExchangeVoucherIdBySuitId(self.lastTryOnId)
  _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanelByTableIndex, 3, itemId)
end

function UMG_ClosetPanel_C:OnPurchaseBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ClosetPanel_C:OnPurchaseBtnClick")
  local storeIds = {
    AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG,
    AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION
  }
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckIfSuitPurchasableReq, storeIds)
end

function UMG_ClosetPanel_C:OnPurchaseBtnClickCallback()
  local bCanBuy, storeType, goodsId = self:IsSuitPurchasable(self.canBuySuitId)
  if bCanBuy then
    local suitConf = _G.DataConfigManager:GetFashionSuitsConf(self.canBuySuitId)
    local packageId = suitConf and suitConf.package_id
    if storeType == AppearanceModuleEnum.FashionMallShopId.RANDOM_FASHION then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop, storeType, packageId)
    elseif storeType == AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenTryOnByPackageId, packageId, self.canBuySuitId)
    elseif storeType == AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION and goodsId then
      self:OpenExchangeShopWithGoods(storeType, goodsId)
    end
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.bp_gift_expired)
    self:SetConfirmBtnState()
  end
end

function UMG_ClosetPanel_C:ReturnBeginAppearance()
  local currentSelectedIndex = self.Suit.Suit_List:GetSelectedIndex()
  local lastWardrobeData, lastSalonWardrobeData = self.data:GetWardrobeDataByIndex(currentSelectedIndex)
  lastWardrobeData = lastWardrobeData or {}
  lastSalonWardrobeData = lastSalonWardrobeData or {}
  if self.data.TempAppearData == nil and nil == self.data.TempBeautyData then
    self:PlayAnimation(self.Btn_Press)
    self:SetConfirmBtnState()
    return false
  end
  local SameNum = 0
  local change = false
  local wardrobeDataCount = #lastWardrobeData
  self:PlayAnimation(self.Btn_Press)
  if self.data.TempAppearData and wardrobeDataCount ~= #self.data.TempAppearData then
    change = true
  end
  if not change and self.data.TempAppearData and #self.data.TempAppearData > 0 then
    for i = 1, #self.data.TempAppearData do
      if lastWardrobeData and #lastWardrobeData > 0 then
        for k, v in ipairs(lastWardrobeData) do
          if v and 0 ~= v.wearing_item_id and self.data.TempAppearData[i].FashionId == v.wearing_item_id then
            local tempGlassInfo = self.data.TempAppearData[i].glassInfo
            local storageGlassInfo = v.wearing_glass
            if IsSameGlassInfo(tempGlassInfo, storageGlassInfo) then
              SameNum = SameNum + 1
            end
          end
        end
      end
    end
    if wardrobeDataCount > SameNum then
      change = true
    else
      change = false
    end
  end
  if not change then
    local sameSalonSum = 0
    if self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
      for i = 1, #self.data.TempBeautyData do
        if lastSalonWardrobeData and #lastSalonWardrobeData > 0 then
          for k, v in ipairs(lastSalonWardrobeData) do
            if self.data.TempBeautyData[i].SalonId == v then
              sameSalonSum = sameSalonSum + 1
            end
          end
        end
      end
    end
    if #lastSalonWardrobeData and sameSalonSum < #lastSalonWardrobeData or 0 == #lastSalonWardrobeData and self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
      change = true
    end
  end
  if change then
    local itemsToRemove = {}
    if self.data.TempAppearData then
      for k, v in ipairs(self.data.TempAppearData) do
        table.insert(itemsToRemove, {
          FashionType = v.FashionType,
          FashionId = v.FashionId
        })
      end
      for k, v in ipairs(itemsToRemove) do
        if v.FashionType ~= _G.Enum.FashionLabelType.FLT_WAND then
          self.module:OnCmdSetClosetAvatar(true, v.FashionType, v.FashionId, nil, false)
        end
      end
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    local gender = 1
    if player then
      gender = player.gender
    end
    local defaultSalons = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAvatarDefaultSalonIdsByGender, gender)
    self.data.TempAppearData = nil
    self.data.TempBeautyData = nil
    local fashionItems = {}
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.InitCurSelectedItemGlassMap)
    if lastWardrobeData and #lastWardrobeData > 0 then
      for k, v in ipairs(lastWardrobeData) do
        if v and 0 ~= v.wearing_item_id then
          table.insert(fashionItems, {
            wearing_item_id = v.wearing_item_id,
            wearing_glass = v.wearing_glass
          })
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurSelectedItemGlassMap, v.wearing_item_id, v.wearing_glass)
        end
      end
    end
    local salonIds = {}
    if lastSalonWardrobeData and #lastSalonWardrobeData > 0 then
      for k, v in ipairs(lastSalonWardrobeData) do
        if 0 ~= v then
          table.insert(salonIds, {item_wear_id = v, color_wear_id = 0})
        end
      end
    else
      for k, v in pairs(defaultSalons) do
        if 0 ~= v then
          table.insert(salonIds, {item_wear_id = v, color_wear_id = 0})
        end
      end
    end
    self.module:SetDefaultSuitAvatar(nil, fashionItems, salonIds, self.module.closetAvatarPlayer)
  end
  self:SetConfirmBtnState()
  return change
end

function UMG_ClosetPanel_C:OnReturnBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1179, "UMG_ClosetPanel_C:OnReturnBtnClicked")
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  CommonPopUpData.ContentText = _G.LuaText.revert_dress_up_popup_text
  CommonPopUpData.TitleText = LuaText.TIPS
  CommonPopUpData.Btn_LeftText = LuaText.CANCEL
  CommonPopUpData.Btn_RightText = LuaText.umg_bag_popup_2
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.OnReturnConfirmed
  CommonPopUpData.Btn_LeftHandler = self.OnPopUpCloseButton
  CommonPopUpData.Btn_CloseHandler = self.OnPopUpCloseButton
  CommonPopUpData.bPlayBtnSound = false
  CommonPopUpData.FullScreen_Close = false
  _G.NRCModeManager:DoCmd(CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
end

function UMG_ClosetPanel_C:OnReturnConfirmed()
  self:ReturnBeginAppearance()
  _G.NRCAudioManager:PlaySound2DAuto(1070, "UMG_Appearance_Main_C:OnReturnBtnClicked")
  self.lastTryOnId = 0
  self:ChooseClosetTab(self.curTabConfId, self.curTabInfo, true)
end

function UMG_ClosetPanel_C:OnClickBtnPressed()
  self.Return:StopAllAnimations()
  self.Return:PlayAnimation(self.Return.Press)
end

function UMG_ClosetPanel_C:OnClickBtnReleased()
  self.Return:StopAllAnimations()
  self.Return:PlayAnimation(self.Return.Up)
end

function UMG_ClosetPanel_C:OnConfirmBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40002007, "UMG_ClosetPanel_C:OnConfirmBtnClicked")
  local filterItemList = self.data:FilterHasAndInitFashion()
  if filterItemList and #filterItemList > 0 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText.lv_up_dress_fail)
    self:SaveHasFashionAndSalon()
  else
    self.module:LoadClosetAvatarTransform()
    local fashionIds = {}
    local bHasWand = false
    if self.data.TempAppearData and #self.data.TempAppearData > 0 then
      for k, v in ipairs(self.data.TempAppearData) do
        local itemConf
        if not bHasWand then
          itemConf = _G.DataConfigManager:GetFashionItemConf(v.FashionId)
        end
        if itemConf and itemConf.type == _G.Enum.FashionLabelType.FLT_WAND then
          bHasWand = true
        end
        table.insert(fashionIds, v.FashionId)
      end
    end
    if not bHasWand then
      local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
      table.insert(fashionIds, wandId)
    end
    if 0 == self.data.lastSelectedWardrobeIndex then
      self.data.lastSelectedWardrobeIndex = 1
    end
    local salonIds = {}
    if self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
      for k, v in ipairs(self.data.TempBeautyData) do
        table.insert(salonIds, v.SalonId)
      end
    end
    self.module:OnCmdSetFashionDataReq(self.data.lastSelectedWardrobeIndex, fashionIds, nil, nil, nil, nil, nil, salonIds)
  end
end

function UMG_ClosetPanel_C:SaveHasFashionAndSalon()
  local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local lastFashionIds, lastSalonIds
  if fashionInfo and fashionInfo.wardrobe_data then
    local wardrobeIndex = fashionInfo.current_wardrobe_index or 0
    lastFashionIds = (fashionInfo.wardrobe_data[wardrobeIndex] or {}).wearing_item
    lastSalonIds = (fashionInfo.wardrobe_data[wardrobeIndex] or {}).salon_item_wear_id
  end
  local fashionMap = {}
  local salonMap = {}
  local fashionIds = {}
  local salonIds = {}
  if lastFashionIds then
    for i, v in ipairs(lastFashionIds) do
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
      if fashionConf then
        fashionMap[fashionConf.type] = v.wearing_item_id
      end
    end
  end
  if lastSalonIds then
    for i, v in ipairs(lastSalonIds) do
      local salonConf = _G.DataConfigManager:GetSalonItemConf(v)
      if salonConf then
        salonMap[salonConf.type] = v
      end
    end
  end
  if self.data and self.data.TempAppearData and #self.data.TempAppearData > 0 then
    for k, v in ipairs(self.data.TempAppearData) do
      local bHasOwned = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasOwned, _G.Enum.GoodsType.GT_FASHION, v.FashionId)
      if bHasOwned then
        if v.FashionType == Enum.FashionLabelType.FLT_TOPS or v.FashionType == Enum.FashionLabelType.FLT_BOTTOMS then
          fashionMap[Enum.FashionLabelType.FLT_DRESSES] = 0
        elseif v.FashionType == Enum.FashionLabelType.FLT_DRESSES then
          fashionMap[Enum.FashionLabelType.FLT_TOPS] = 0
          fashionMap[Enum.FashionLabelType.FLT_BOTTOMS] = 0
        end
        fashionMap[v.FashionType] = v.FashionId
      end
    end
  end
  if self.data and self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
    for k, v in ipairs(self.data.TempBeautyData) do
      local bHasOwned = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasOwned, _G.Enum.GoodsType.GT_SALON, v.SalonId)
      if bHasOwned then
        salonMap[v.SalonType] = v.SalonId
      end
    end
  end
  local requiredFashionTypes = {
    _G.Enum.FashionLabelType.FLT_TOPS,
    _G.Enum.FashionLabelType.FLT_BOTTOMS,
    _G.Enum.FashionLabelType.FLT_SHOES,
    _G.Enum.FashionLabelType.FLT_BAGS
  }
  
  local function HasFashionType(t)
    return nil ~= fashionMap[t] and 0 ~= fashionMap[t]
  end
  
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local gender = 1
  if player then
    gender = player.gender
  end
  local defaultFashionMap = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAvatarDefaultFashionIdsByGender, gender)
  for _, t in ipairs(requiredFashionTypes) do
    if not HasFashionType(t) and defaultFashionMap and defaultFashionMap[t] and 0 ~= defaultFashionMap[t] then
      fashionMap[t] = defaultFashionMap[t]
    end
  end
  if fashionMap[_G.Enum.FashionLabelType.FLT_DRESSES] and 0 ~= fashionMap[_G.Enum.FashionLabelType.FLT_DRESSES] then
    fashionMap[_G.Enum.FashionLabelType.FLT_TOPS] = 0
    fashionMap[_G.Enum.FashionLabelType.FLT_BOTTOMS] = 0
  else
    local hasTops = HasFashionType(_G.Enum.FashionLabelType.FLT_TOPS)
    local hasBottoms = HasFashionType(_G.Enum.FashionLabelType.FLT_BOTTOMS)
    if hasTops or hasBottoms then
      fashionMap[_G.Enum.FashionLabelType.FLT_DRESSES] = 0
    end
  end
  for i, v in pairs(fashionMap) do
    if v > 0 then
      table.insert(fashionIds, v)
    end
  end
  for i, v in pairs(salonMap) do
    table.insert(salonIds, v)
  end
  self.module:OnCmdSetFashionDataReq(self.data.lastSelectedWardrobeIndex, fashionIds, nil, nil, nil, nil, nil, salonIds)
end

function UMG_ClosetPanel_C:OnSaveFashionDataCallback(newFashionItems, newSalonIds)
  local tipText = _G.DataConfigManager:GetLocalizationConf("fashion_save_nothingnew").msg
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipText)
  local suitIconPath
  if newFashionItems and #newFashionItems > 0 then
    for k, v in ipairs(newFashionItems) do
      local itemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
      if itemConf and (itemConf.type == _G.Enum.FashionLabelType.FLT_DRESSES or itemConf.type == _G.Enum.FashionLabelType.FLT_TOPS) then
        suitIconPath = itemConf.icon
      end
    end
  end
  if not suitIconPath then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if 1 == player.gender then
      suitIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/10700001.10700001'"
    else
      suitIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/20700001.20700001'"
    end
  end
  self.Suit:UpdateSuitBtnIconOnSelection(suitIconPath)
end

function UMG_ClosetPanel_C:UpdateListSelectionAfterSave()
  local bFashion = self.data.bChooseClosetFashionTab
  local typeEnum = self.data.closetChooseTabType
  if nil == bFashion or nil == typeEnum then
    return
  end
  local wearingId = 0
  if bFashion then
    if typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      wearingId = self.data:GetWearIdByType(true, _G.Enum.FashionLabelType.FLT_SUIT)
    elseif self.data.TempAppearData then
      for _, v in ipairs(self.data.TempAppearData) do
        if v.FashionType == typeEnum and v.FashionId > 0 then
          wearingId = v.FashionId
          break
        end
      end
    end
  elseif self.data.TempBeautyData then
    for _, v in ipairs(self.data.TempBeautyData) do
      if v.SalonType == typeEnum and v.SalonId > 0 then
        wearingId = v.SalonId
        break
      end
    end
  end
  local itemCount = self.Buy_List:GetTotalItemNumber()
  local chooseItemIndex = -1
  for i = 0, itemCount - 1 do
    local item = self.Buy_List:GetItemByIndex(i)
    if item then
      item:SetEnableSound(false)
      item:SetEnableUpgradeButtonAnim(false)
      if item.uiData then
        if bFashion then
          if item.uiData.id == wearingId and wearingId > 0 then
            chooseItemIndex = i
          end
        elseif type(item.uiData.id) == "table" then
          for _, subId in ipairs(item.uiData.id) do
            if subId == wearingId and wearingId > 0 then
              chooseItemIndex = i
              break
            end
          end
        elseif item.uiData.id == wearingId and wearingId > 0 then
          chooseItemIndex = i
        end
      end
    end
  end
  local curSelectedItem = self.Buy_List:GetSelectedItem()
  local curSelectedIndex0Based = self.Buy_List:GetSelectedIndex() - 1
  if curSelectedItem and curSelectedIndex0Based ~= chooseItemIndex then
    curSelectedItem.bChose = false
    curSelectedItem:ResetItemState()
  end
  if chooseItemIndex >= 0 then
    if curSelectedIndex0Based == chooseItemIndex then
    else
      local targetItem = self.Buy_List:GetItemByIndex(chooseItemIndex)
      if targetItem then
        targetItem:IgnoreNextWear()
      end
      self.Buy_List:SelectItemByIndex(chooseItemIndex)
    end
  else
    self.Buy_List:ClearSelection()
    self:UpdateViewButtonState(false, false)
    self:UpdateTitlesAndCurrentDetailId(nil, nil, nil, true)
    self:UpdateGorgeousMagicBtnVisible(false)
  end
  for i = 0, itemCount - 1 do
    local item = self.Buy_List:GetItemByIndex(i)
    if item then
      item:SetEnableSound(true)
      item:SetEnableUpgradeButtonAnim(true)
    end
  end
end

function UMG_ClosetPanel_C:OnClickedGorgeousMagicBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClosetPanel_C:OnClickedGorgeousMagicBtn")
  if 0 == self.NRCSwitcher_2:GetActiveWidgetIndex() then
    local sgSuitId = self:FindSGSuitId()
    if sgSuitId then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicVideoDetailsPanel, Enum.GoodsType.GT_FASHION_SUITS, sgSuitId)
    end
  elseif 1 == self.NRCSwitcher_2:GetActiveWidgetIndex() or 2 == self.NRCSwitcher_2:GetActiveWidgetIndex() then
    if not self.curPendantaId or 0 == self.curPendantaId then
      Log.Error("\229\189\147\229\137\141\230\178\161\230\156\137\229\140\133\230\140\130\239\188\140\232\191\153\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local context = {}
    context.bIsPendanta = true
    context.context = {}
    context.context.itemId = self.curPendantaId
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
  elseif 3 == self.NRCSwitcher_2:GetActiveWidgetIndex() then
    if not self.curWandId or 0 == self.curWandId then
      Log.Error("\229\189\147\229\137\141\230\178\161\230\156\137\229\140\133\230\140\130\239\188\140\232\191\153\230\156\137\233\151\174\233\162\152\239\188\129")
      return
    end
    local context = {}
    context.bIsWand = true
    context.context = {}
    context.context.WandId = self.curWandId
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenMagicWandPopUp, context)
  end
end

function UMG_ClosetPanel_C:OnDetailBtnClicked()
  if not self.curFashionUIData then
    return
  end
  if self.curFashionUIData.bFashion then
    if self.curFashionUIData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, self.curFashionUIData.id)
    else
      local suitId = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetSuitIdFromFashionId, self.curFashionUIData.id)
      if suitId then
        _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, suitId, self.curFashionUIData.id)
      end
    end
  end
end

function UMG_ClosetPanel_C:OnPlayerDataUpdate()
  self:UpdateMoney()
  if not self:_HasOwnedItemChanged() then
    return
  end
  self:_CacheOwnedItemCount()
  if self.bCanUpdateCloset then
    self.bClosetDirty = false
    if not self.module:HasPanel("AppearanceUpgrade") then
      Log.Info("AppearanceCloset \232\167\166\229\143\145\230\155\180\230\150\176")
      local item = self.Appearance_Tab1:GetSelectedItem()
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.ChooseClosetTab, item.uiData.tabConfId, item.uiData)
    end
  else
    self.bClosetDirty = true
  end
end

function UMG_ClosetPanel_C:_CacheOwnedItemCount()
  local fashionOwned = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedFashion()
  local salonOwned = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedSalon()
  self._cachedFashionCount = fashionOwned and #fashionOwned or 0
  self._cachedSalonCount = salonOwned and #salonOwned or 0
end

function UMG_ClosetPanel_C:_HasOwnedItemChanged()
  local fashionOwned = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedFashion()
  local salonOwned = _G.DataModelMgr.PlayerDataModel:GetPlayerOwnedSalon()
  local curFashionCount = fashionOwned and #fashionOwned or 0
  local curSalonCount = salonOwned and #salonOwned or 0
  return curFashionCount ~= (self._cachedFashionCount or 0) or curSalonCount ~= (self._cachedSalonCount or 0)
end

function UMG_ClosetPanel_C:OnBagChange()
  self:UpdateMoney()
end

function UMG_ClosetPanel_C:UpdateTitlesAndCurrentDetailId(petTitle, suitTitle, uiData, bShouldShowTitle, btnIconPath, btnText)
  self.Particulars:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PetTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SuitTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if bShouldShowTitle then
    self.PetTitle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SuitTitle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if uiData then
      self.Particulars:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.PetTitle:SetText(petTitle)
    self.SuitTitle:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if suitTitle then
      self.SuitTitle:SetText(suitTitle)
    else
      self.SuitTitle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.curFashionUIData = uiData
    if btnIconPath and not string.IsNilOrEmpty(btnIconPath) then
      self.MagicIcon:SetPath(btnIconPath)
    end
    if btnText and not string.IsNilOrEmpty(btnText) then
      self.NRCText_1:SetText(btnText)
    end
  end
end

function UMG_ClosetPanel_C:UpdateViewButtonState(bShouldShow, bIsUpdate, updateIconPath, bIsGoods, bFashion, itemType, bEnableAnim)
  if self:CheckNeedToShowClaimGlassTintBtn() then
    return
  end
  if bShouldShow then
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if bIsUpdate then
      if itemType == _G.Enum.GoodsType.GT_FASHION_BOND then
        self.Btn_UpgradeComponent.Purchase:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCSwitcher_1:SetActiveWidgetIndex(0)
        self.Btn_UpgradeComponent.NRCSwitcher_0:SetActiveWidgetIndex(1)
        self.Btn_UpgradeComponent.Badge:SetPath(updateIconPath)
      else
        self.Btn_UpgradeComponent.Purchase:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.NRCSwitcher_1:SetActiveWidgetIndex(0)
        self.Btn_UpgradeComponent.NRCSwitcher_0:SetActiveWidgetIndex(0)
        self.Btn_UpgradeComponent.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_UpgradeComponent.Icon_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_UpgradeComponent.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_UpgradeComponent.Lock_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_UpgradeComponent.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if not bIsGoods then
          if bFashion and itemType == _G.Enum.FashionLabelType.FLT_GLASSES or not bFashion and itemType ~= _G.Enum.SalonLabelType.SLT_HAIR then
            if bFashion and itemType == _G.Enum.FashionLabelType.FLT_GLASSES then
              local scale = UE4.FVector2D(1.5, 1.5)
              self.Btn_UpgradeComponent.Icon_2:SetRenderScale(scale)
            else
              local scale = UE4.FVector2D(1, 1)
              self.Btn_UpgradeComponent.Icon_2:SetRenderScale(scale)
            end
            self.Btn_UpgradeComponent.Icon_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Btn_UpgradeComponent.Icon_2:SetPath(updateIconPath)
          elseif not bFashion and itemType == _G.Enum.SalonLabelType.SLT_HAIR then
            self.Btn_UpgradeComponent.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Btn_UpgradeComponent.Icon:SetPath(updateIconPath)
          else
            self.Btn_UpgradeComponent.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.Btn_UpgradeComponent.Icon_1:SetPath(updateIconPath)
          end
        else
          self.Btn_UpgradeComponent.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Btn_UpgradeComponent.Icon_1:SetPath(updateIconPath)
        end
      end
      if bEnableAnim then
        self:PlayAnimation(self.Btn_N_change)
      end
    else
      self.Btn_ViewComponents.Title_1:SetText(LuaText.btn_view_fashion_item)
      self.NRCSwitcher_1:SetActiveWidgetIndex(1)
      self.Btn_ViewComponents.NRCSwitcher_0:SetActiveWidgetIndex(1)
      self.Btn_ViewComponents.Badge:SetPath(updateIconPath)
      if bEnableAnim then
        self:PlayAnimation(self.Btn_S_change)
      end
    end
  else
    self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ClosetPanel_C:_UpdateGorgeousBtn(bShouldShow, typeEnum)
  if typeEnum ~= _G.Enum.FashionLabelType.FLT_PENDANTA and typeEnum ~= _G.Enum.FashionLabelType.FLT_WAND then
    self:UpdateGorgeousMagicBtnVisible(bShouldShow, 0)
  end
end

function UMG_ClosetPanel_C:_UpdateHandInHandBtn(bShouldShow, index, pendantaId)
  if 1 ~= self.NRCSwitcher_2:GetActiveWidgetIndex() or 2 ~= self.NRCSwitcher_2:GetActiveWidgetIndex() then
    return
  end
  self:UpdateGorgeousMagicBtnVisible(bShouldShow, index, pendantaId)
end

function UMG_ClosetPanel_C:UpdateGorgeousMagicBtnVisible(bShouldShow, index, pendantaId, wandId)
  if nil == bShouldShow then
    local sgSuitId = self:FindSGSuitId()
    self.GorgeousMagicBtn:SetVisibility(sgSuitId and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  elseif bShouldShow then
    self.NRCSwitcher_2:SetActiveWidgetIndex(index)
    if 1 == index then
      self:PlayAnimation(self.Privilege_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    else
      self:StopAnimation(self.Privilege_loop)
    end
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.curPendantaId = pendantaId
    self.curWandId = wandId
  else
    self.GorgeousMagicBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.curPendantaId = nil
    self.curWandId = nil
  end
end

function UMG_ClosetPanel_C:FindSGSuitId()
  local selectedItem = self.Buy_List:GetSelectedItem()
  if self.data.closetChooseTabType == _G.Enum.FashionLabelType.FLT_SUIT and selectedItem and selectedItem.bChose then
    local sgSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckSGSuitId, self.lastTryOnId)
    return sgSuitId
  elseif self.data.closetChooseTabType == _G.Enum.FashionLabelType.FLT_PENDANTA and selectedItem and selectedItem.bChose then
    return true
  end
end

function UMG_ClosetPanel_C:OnTouchStarted(MyGeometry, InTouchEvent)
  self.TouchStartTime = 0
  self:SetUpDateRegister(true)
  if not self.bTouchEnded then
    self.bTouchEnded = true
    self.Appearance_Tab1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.VerticalBox_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_ClosetPanel_C:LuaOnTouchMoved(dir)
  if self.TouchStartTime and self.TouchStartTime < 0.1 then
    return
  end
  if self.bTouchEnded then
    self.bTouchEnded = false
    self.Appearance_Tab1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.VerticalBox_0:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self.module:SetAvatarRotation(dir.X, self.module.closetAvatarPlayer)
end

function UMG_ClosetPanel_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if self.TouchStartTime < 0.3 and self.GlassDetailPanel then
    self.GlassDetailPanel:CheckOpenState()
  end
  self.TouchStartTime = 0
  self:SetUpDateRegister(false)
  if not self.bTouchEnded then
    self.bTouchEnded = true
    self.Appearance_Tab1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.VerticalBox_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_ClosetPanel_C:UpdateMoney()
  local viConf = _G.DataConfigManager:GetFashionViConf(1)
  if not viConf then
    return
  end
  local sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNumByType(viConf.goods_type, viConf.goods_id)
  local costGoodType = viConf.goods_type
  local bShowBuyIcon = false
  if costGoodType == _G.Enum.GoodsType.GT_VITEM then
    bShowBuyIcon = viConf.goods_id == Enum.VisualItem.VI_COUPON or viConf.goods_id == Enum.VisualItem.VI_DIAMOND or viConf.goods_id == Enum.VisualItem.VI_PIKA_POINT
  end
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = viConf.goods_type,
    currencyId = viConf.goods_id,
    currencyType = viConf.goods_type,
    sum = sumMoneyNum,
    showColor = 0,
    IsShowBuyIcon = bShowBuyIcon,
    bigIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_ClosetPanel_C:SkillEndShowPanel()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:UpdatePanelInfo()
  self:StopAnimation(self.open)
  self:StopAnimation(self.close)
  self:PlayAnimation(self.open)
end

function UMG_ClosetPanel_C:OnOpenClosetPanelSkillEnded()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_ClosetPanel_C:OnFastDressUpSetSkillCamera(Skill)
  self.FastDressUpSkillCamera = Skill.Blackboard:GetValueAsObject("camActor_0001")
  if self.FastDressUpSkillCamera then
    local mainCamComp = self.FastDressUpSkillCamera:GetComponentByClass(UE4.UCameraComponent)
    if mainCamComp then
      self.CurrentFOV = mainCamComp.FieldOfView
    end
  end
  self:SetUpDateRegister(true)
end

function UMG_ClosetPanel_C:OnFastDressUpChangeViewSkillEnd(Skill)
  self.FastDressUpSkillCamera = nil
  self:SetUpDateRegister(false)
end

function UMG_ClosetPanel_C:OnUnlockNewHeterochromeSuit(suitId)
  self.bCanUpdateCloset = true
  if self.bClosetDirty then
    self:OnPlayerDataUpdate()
  end
  if 1 == self.tabConfId then
    local size = self.Buy_List:GetItemCount()
    for i = 0, size - 1 do
      local item = self.Buy_List:GetItemByIndex(i)
      if item and item.uiData.id == suitId then
        item.CanvasPanel_249:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        item:PlayNewCardAnim()
      end
    end
  end
end

function UMG_ClosetPanel_C:SetUpDateRegister(bOpen)
  if bOpen then
    _G.UpdateManager:Register(self)
  elseif self.FastDressUpSkillCamera then
  elseif self.starLogoChange then
  else
    _G.UpdateManager:UnRegister(self)
  end
end

function UMG_ClosetPanel_C:OnTick(deltaTime)
  if self.TouchStartTime then
    self.TouchStartTime = self.TouchStartTime + deltaTime
  end
  if self.FastDressUpSkillCamera and UE.UObject.IsValid(self.FastDressUpSkillCamera) and UE.UObject.IsValid(self.FastDressUpMainCamera) then
    local curTrans = self.FastDressUpSkillCamera:Abs_GetTransform()
    self.FastDressUpMainCamera:Abs_K2_SetActorTransform_WithoutHit(curTrans)
    local camera = self.FastDressUpSkillCamera:GetComponentByClass(UE4.UCameraComponent)
    if camera then
      self.TargetFOV = camera.FieldOfView
    end
    if self.TargetFOV then
      self.CurrentFOV = UE4.UKismetMathLibrary.FInterpTo(self.CurrentFOV, self.TargetFOV, deltaTime, self.FOVInterpSpeed)
      local mainCamComp = self.FastDressUpMainCamera:GetComponentByClass(UE4.UCameraComponent)
      if mainCamComp then
        mainCamComp.FieldOfView = self.CurrentFOV
      end
    end
  end
  if self.starLogoChange and self.logoTransparencyMaterial_Middle and self.logoTransparencyMaterial_Down and self.logoTransparencyMaterial_Top then
    local curValue = self.logoTransparencyMaterial_Middle:K2_GetScalarParameterValue("Opacoty")
    if curValue then
      local newVal = curValue + 0.1
      if newVal < 1 then
        self.logoTransparencyMaterial_Middle:SetScalarParameterValue("Opacoty", newVal)
        self.logoTransparencyMaterial_Down:SetScalarParameterValue("Opacoty", newVal)
        self.logoTransparencyMaterial_Top:SetScalarParameterValue("Opacity", newVal)
      else
        self.LogoMeshComponent_Middle:SetMaterial(0, self.logoDefaultMaterial_Middle)
        UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Middle)
        self.LogoMeshComponent_Down:SetMaterial(0, self.logoDefaultMaterial_Down)
        UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Down)
        self.LogoMeshComponent_Top:SetMaterial(0, self.logoDefaultMaterial_Top)
        UE4.UNRCStatics.MarkRenderStateDirty(self.LogoMeshComponent_Top)
        self.starLogoChange = false
        self:SetUpDateRegister(false)
      end
    else
      self.starLogoChange = false
      self:SetUpDateRegister(false)
    end
  end
end

function UMG_ClosetPanel_C:UpdatePanelInfo()
  self.Ununlocked:SetShowLockIcon(false)
  self.Inproperly:SetShowLockIcon(false)
  self.Btn_ClaimVoucher:SetCommonText(_G.LuaText.dressup_suits_ticket_btn_text)
  self:UpdateTitlesAndCurrentDetailId(nil, nil, nil, false)
  self.NRCSwitcher_44:SetActiveWidgetIndex(1)
  self.NRCSwitcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_ViewComponents.Title_1:SetText(_G.LuaText.btn_view_fashion_item)
  self.Btn_UpgradeComponent.Title_1:SetText(_G.LuaText.btn_escalate_fashion_item)
  self.PurchaseBtn.Title_1:SetText(_G.LuaText.btn_shop_direction)
  self:UpdateMoney()
  self.tabIndexToConfId = {}
  local tabIndexToConfId = self.tabIndexToConfId
  local closetTabTable = {}
  for k, v in ipairs(self.data.closetTabTypeList) do
    local bRedDot = self.redDotMap[v.bFashion][v.LabelType] and #self.redDotMap[v.bFashion][v.LabelType] > 0
    table.insert(closetTabTable, {
      data = v,
      parent = self,
      bHasRedDot = bRedDot
    })
    tabIndexToConfId[k - 1] = v.tabConfId
  end
  self.Appearance_Tab1:InitGridView(closetTabTable)
  self.Appearance_Tab1:SetItemCanClickChecker(self.CheckTabCanClick, self)
  if self.defaultTabIndex then
    self.Appearance_Tab1:SelectItemByIndex(self.defaultTabIndex)
  else
    self.Appearance_Tab1:SelectItemByIndex(0)
  end
  local playerFashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  local playerSalonInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerSalonInfo()
  if self.Suit.UpdateList then
    self.Suit:UpdateList(playerFashionInfo, false, true)
  end
  if not self.curSuitBrand then
    local selectedItem = self.Buy_List:GetSelectedItem()
    if selectedItem and selectedItem.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(selectedItem.uiData.id)
      if fashionSuitConf then
        self:RefreshBrandLogoByBrandId(fashionSuitConf.fashion_bond_band)
      end
    end
  end
end

function UMG_ClosetPanel_C:UpdatePanelInfoOnUpdateUpgradeMall()
  self:UpdateMoney()
end

function UMG_ClosetPanel_C:OnClosetPlayerInitOver()
  local curTabType = self.data.closetTabTypeList[1] and self.data.closetTabTypeList[1].labelType
  local curWandId = self.module:OnCmdGetCurSuitWandId()
  self.module:HideOrShowAppearanceById(true, curWandId, curTabType == Enum.FashionLabelType.FLT_WAND)
end

function UMG_ClosetPanel_C:UpdateTabBtnPromptByCurrentSuit(fashionItems)
  if not fashionItems then
    return
  end
  local hasTypeList = {}
  if 0 == #fashionItems then
    table.insert(hasTypeList, _G.Enum.FashionLabelType.FLT_WAND)
  end
  local bIsAccessoriesAdded = false
  local bIsClothesAdded = false
  for k, v in ipairs(fashionItems) do
    local itemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
    if itemConf then
      table.insert(hasTypeList, itemConf.type)
      if not bIsAccessoriesAdded and (itemConf.type == _G.Enum.FashionLabelType.FLT_SHOES or itemConf.type == _G.Enum.FashionLabelType.FLT_SOCKS or itemConf.type == _G.Enum.FashionLabelType.FLT_GLASSES or itemConf.type == _G.Enum.FashionLabelType.FLT_HATS or itemConf.type == _G.Enum.FashionLabelType.FLT_RINGS) then
        bIsAccessoriesAdded = true
        table.insert(hasTypeList, _G.Enum.FashionLabelType.FLT_ACCESSORIES)
      end
      if not bIsClothesAdded and (itemConf.type == _G.Enum.FashionLabelType.FLT_DRESSES or itemConf.type == _G.Enum.FashionLabelType.FLT_TOPS or itemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS or itemConf.type == _G.Enum.FashionLabelType.FLT_BAGS or itemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA) then
        bIsClothesAdded = true
        table.insert(hasTypeList, _G.Enum.FashionLabelType.FLT_CLOTHES)
      end
    end
  end
  local suitId = self.data:GetWearIdByType(true, _G.Enum.FashionLabelType.FLT_SUIT)
  if suitId and 0 ~= suitId then
    table.insert(hasTypeList, _G.Enum.FashionLabelType.FLT_SUIT)
  end
  local count = self.Appearance_Tab1:GetItemCount()
  for i = 0, count - 1 do
    local item = self.Appearance_Tab1:GetItemByIndex(i)
    item:SetDressPrompt(false)
  end
  for i = 0, count - 1 do
    local item = self.Appearance_Tab1:GetItemByIndex(i)
    for k, v in ipairs(hasTypeList) do
      local shouldShow = item.uiData.LabelType == v and item.uiData.bFashion
      if shouldShow then
        item:SetDressPrompt(true)
        break
      end
    end
  end
  count = self.HorizontalTab1:GetItemCount()
  for i = 0, count - 1 do
    local item = self.HorizontalTab1:GetItemByIndex(i)
    item:SetDressPrompt(false)
  end
  for i = 0, count - 1 do
    local item = self.HorizontalTab1:GetItemByIndex(i)
    for k, v in ipairs(hasTypeList) do
      if item.uiData and item.uiData.LabelType == v then
        item:SetDressPrompt(true)
        break
      end
    end
  end
end

function UMG_ClosetPanel_C:UpdateCurClosetTab(fashionItems, selectedSuitIndex)
  if not self.bCanUpdateCloset then
    return
  end
  self.lastTryOnId = 0
  self:ChooseClosetTab(self.curTabConfId, self.curTabInfo, true)
  self:UpdateTabBtnPromptByCurrentSuit(fashionItems)
  local playerFashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
  if self.Suit.UpdateList then
    self.Suit:UpdateList(playerFashionInfo, false, true, nil, selectedSuitIndex)
  end
end

function UMG_ClosetPanel_C:UpdateCurClosetTabAfterGetGlassTint()
  self:ChooseClosetTab(self.curTabConfId, self.curTabInfo, true)
  self.selectedGlassItemIndex = nil
end

function UMG_ClosetPanel_C:ChooseClosetTab(tabConfId, tabInfo, bIgnoreInit)
  local isBan = self:CheckIfTabBan(tabConfId, false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if not (tabInfo and self.curTabInfo) or tabInfo.LabelType ~= self.curTabInfo.LabelType then
    self.lastSelectHorizontalTabIndex = -1
  end
  self.curTabConfId = tabConfId
  self.curTabInfo = tabInfo
  if not tabInfo then
    return
  end
  if self.curTabInfo.LabelType == _G.Enum.FashionLabelType.FLT_CLOTHES or self.curTabInfo.LabelType == _G.Enum.FashionLabelType.FLT_SUIT then
    self.NRCSwitcher_620:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher_620:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.data.closetChooseOutterTab = tabInfo.LabelType
  self.tabConfId = tabConfId
  local hasSubTab = false
  for k, v in pairs(self.data.closetTabMap) do
    if tabConfId == k then
      hasSubTab = true
      local initTable = {}
      for index, value in ipairs(v) do
        local bHasRedDot = self.redDotMap[value.bFashion][value.LabelType] and #self.redDotMap[value.bFashion][value.LabelType] > 0
        table.insert(initTable, {
          data = value,
          parent = self,
          bHasRedDot = bHasRedDot
        })
      end
      self.HorizontalTab1:InitGridView(initTable)
      if self.bEnterFilterGlassItemState then
        local filterTab
        local ownedGlassItemTabList = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetOwnedGlassItemTabList)
        for _, type in pairs(ownedGlassItemTabList or {}) do
          if type == Enum.FashionLabelType.FLT_DRESSES or type == Enum.FashionLabelType.FLT_TOPS or type == Enum.FashionLabelType.FLT_HATS then
            local closetTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
            local closetTabTable = closetTabConf:GetAllDatas()
            for _, data in pairs(closetTabTable or {}) do
              if data.use_FashionLabelType == type and data.subrank_value then
                if self.lastSelectTabType == tabInfo.LabelType and data.subrank_value - 1 == self.lastSelectHorizontalTabIndex then
                  filterTab = data.subrank_value - 1
                  break
                else
                  filterTab = math.min(filterTab or 0, data.subrank_value - 1)
                end
              end
            end
            if filterTab then
              break
            end
          end
        end
        self.HorizontalTab1:SelectItemByIndex(filterTab or 0)
      elseif self.lastSelectTabType == tabInfo.LabelType and -1 ~= self.lastSelectHorizontalTabIndex then
        self.HorizontalTab1:SelectItemByIndex(self.lastSelectHorizontalTabIndex)
      elseif self.defaultSubTabIndex then
        self.HorizontalTab1:SelectItemByIndex(self.defaultSubTabIndex)
      else
        self.HorizontalTab1:SelectItemByIndex(0)
      end
    end
  end
  self.lastSelectTabType = tabInfo.LabelType
  if hasSubTab then
    self.TabCross:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TabCross:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:UpdateListByType(tabInfo.bFashion, tabInfo.LabelType, bIgnoreInit)
  end
  local bHideBrand = tabInfo.bFashion ~= true or tabInfo.LabelType == _G.Enum.FashionLabelType.FLT_SALON
  self:SetBlandLogoHide(bHideBrand)
  self:RefreshCommonTitle(tabConfId)
end

function UMG_ClosetPanel_C:RefreshCommonTitle(tabConfId)
  if self.bFastDressUp then
    self.Title1:SetSubtitle(_G.LuaText.quick_dressup_title)
    return
  end
  if 1 == tabConfId then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == tabConfId then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif 3 == tabConfId then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    end
  elseif 9 == tabConfId then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
    end
  elseif 15 == tabConfId then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[5].subtitle)
    end
  elseif 16 == tabConfId and self.titleConf and self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[6].subtitle)
  end
end

function UMG_ClosetPanel_C:ChooseClosetSubTab(tabConfId, tabInfo)
  local bIsTheSame = tabInfo.index - 1 == self.lastSelectHorizontalTabIndex and not self.bNeedToForceInit
  self.bNeedToForceInit = false
  self.lastSelectHorizontalTabIndex = tabInfo.index - 1
  self:UpdateListByType(tabInfo.bFashion, tabInfo.LabelType, bIsTheSame)
end

function UMG_ClosetPanel_C:UpdateListByType(bFashion, typeEnum, bIgnoreInit, bSkipTurnAround)
  self.data.bChooseClosetFashionTab = bFashion
  self.data.closetChooseTabType = typeEnum
  local curWandId = self.module:OnCmdGetCurSuitWandId()
  if false == bFashion and typeEnum == Enum.SalonLabelType.SLT_HAIR then
  elseif bFashion and typeEnum == Enum.FashionLabelType.FLT_SUIT then
    self.module:HideOrShowAppearanceById(true, curWandId, false)
  elseif bFashion and typeEnum == Enum.FashionLabelType.FLT_WAND then
    self.module:HideOrShowAppearanceById(true, curWandId, true)
  else
    self.module:HideOrShowAppearanceById(true, curWandId, false)
  end
  if not bSkipTurnAround then
    self.module:SetPlayerAngle(typeEnum, self.module.closetAvatarPlayer, "Closet")
  end
  self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local showItemList = self.data:GetClosetShowItemList(bFashion, typeEnum)
  local showTable = {}
  for k, v in ipairs(showItemList) do
    local element = {
      id = v,
      bFashion = bFashion,
      typeEnum = typeEnum,
      ownedPanel = self
    }
    if bFashion then
      if typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
        element.redDotKey = 407
        element.redDotExtra = {v}
      else
        element.redDotKey = 408
        element.redDotExtra = {v}
        element.needToErase = self.needToEraseSet[v] ~= nil
      end
      if typeEnum == _G.Enum.FashionLabelType.FLT_TOPS or typeEnum == _G.Enum.FashionLabelType.FLT_DRESSES or typeEnum == _G.Enum.FashionLabelType.FLT_HATS then
        local isGlassItem, wearingGlassInfo, unlockedGlassInfo, claimableGlassInfo = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetFashionItemGlassInfo, v)
        if isGlassItem then
          element.isGlassItem = true
          element.wearingGlassInfo = wearingGlassInfo
          element.unlockedGlassInfo = unlockedGlassInfo
          element.claimableGlassInfo = claimableGlassInfo
        end
      end
    end
    if not self.bEnterFilterGlassItemState then
      table.insert(showTable, element)
    elseif element.isGlassItem then
      table.insert(showTable, element)
    end
  end
  self:SortShowList(bFashion, typeEnum, showTable, bIgnoreInit)
  if bFashion then
    self:_UpdateGorgeousBtn(nil, typeEnum)
  end
  if not self.bEnterFilterGlassItemState then
    self.bShowFilterGlassItem = false
  else
    self.bShowFilterGlassItem = true
  end
end

local function _GetSuitGroupKey(v)
  if v.originalSuitId and 0 ~= v.originalSuitId then
    return v.originalSuitId
  elseif v.upgradeSrcSuitId and 0 ~= v.upgradeSrcSuitId then
    local srcConf = _G.DataConfigManager:GetFashionSuitsConf(v.upgradeSrcSuitId)
    if srcConf and srcConf.suits_original_id and 0 ~= srcConf.suits_original_id then
      return srcConf.suits_original_id
    end
    return v.upgradeSrcSuitId
  else
    return v.id
  end
end

function UMG_ClosetPanel_C:_BuildSuitComparator(initSuitIdSet)
  return function(a, b)
    if a.isClaimable ~= b.isClaimable then
      return a.isClaimable
    end
    if a.bHas ~= b.bHas then
      return a.bHas
    end
    if a.bHas and b.bHas then
      local aIsInit = initSuitIdSet[a.id] or false
      local bIsInit = initSuitIdSet[b.id] or false
      if aIsInit ~= bIsInit then
        return aIsInit
      end
    end
    local aGroup = _GetSuitGroupKey(a)
    local bGroup = _GetSuitGroupKey(b)
    if aGroup ~= bGroup then
      return aGroup < bGroup
    end
    
    local function _GetSuitSortKey(v)
      if v.upgradeSrcSuitId and 0 ~= v.upgradeSrcSuitId then
        return v.upgradeSrcSuitId, 1
      else
        return v.id, 0
      end
    end
    
    local aSortKey, aIsUpgrade = _GetSuitSortKey(a)
    local bSortKey, bIsUpgrade = _GetSuitSortKey(b)
    if aSortKey ~= bSortKey then
      return aSortKey < bSortKey
    end
    if aIsUpgrade ~= bIsUpgrade then
      return aIsUpgrade < bIsUpgrade
    end
    return a.id < b.id
  end
end

function UMG_ClosetPanel_C:SortShowList(bFashion, typeEnum, showTable, bIgnoreInit)
  self:UpdateTitlesAndCurrentDetailId(nil, nil, nil, true)
  if not self.bCanUpdateCloset then
    return
  end
  self.suitClaimable = false
  local upgradeSuitSrcMap = {}
  for k, v in ipairs(showTable) do
    if v.bFashion then
      if v.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
        local hasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, v.id)
        Log.Info(string.format("id %s \230\152\175\229\144\166\230\139\165\230\156\137\239\188\154%s", v.id, hasSuit))
        v.bHas = hasSuit
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(v.id)
        local suitClaimable = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsHeterochromeSuitClaimable, v.id)
        self.suitClaimable = self.suitClaimable or suitClaimable
        v.isClaimable = suitClaimable
        if suitConf and 0 ~= suitConf.suits_original_id then
          v.originalSuitId = suitConf.suits_original_id
        end
        if suitConf and suitConf.lv_up_closet then
          for _, closetItem in ipairs(suitConf.lv_up_closet) do
            if closetItem.lv_item_type == _G.Enum.GoodsType.GT_FASHION_SUITS then
              upgradeSuitSrcMap[closetItem.lv_item_id] = v.id
            end
          end
        end
      else
        local hasFashion = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasOwned, _G.Enum.GoodsType.GT_FASHION, v.id)
        v.bHas = hasFashion
      end
    else
      v.bHas = true
    end
  end
  for k, v in ipairs(showTable) do
    if v.bFashion and v.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      local srcId = upgradeSuitSrcMap[v.id]
      if srcId then
        v.upgradeSrcSuitId = srcId
      end
    end
  end
  if bFashion then
    if typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, player.gender)
      local initSuitIdSet = {}
      if initSuitIds then
        for _, initId in ipairs(initSuitIds) do
          initSuitIdSet[initId] = true
        end
      end
      table.sort(showTable, self:_BuildSuitComparator(initSuitIdSet))
    else
      table.sort(showTable, function(a, b)
        if a.bHas ~= b.bHas then
          return a.bHas
        else
          return a.id < b.id
        end
      end)
    end
  else
    table.sort(showTable, function(a, b)
      return a.id[1] < b.id[1]
    end)
  end
  local chooseItemIndex = 0
  local chooseColorIndex = 0
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetCurrentSelectItemInfo, nil)
  self:UpdateViewButtonState()
  if bFashion then
    if typeEnum ~= Enum.FashionLabelType.FLT_SUIT or typeEnum ~= Enum.FashionLabelType.FLT_WAND then
      local bUpgradeOpen = self.module:HasPanel("AppearanceUpgrade")
      if bUpgradeOpen and typeEnum == Enum.FashionLabelType.FLT_SUIT and 0 ~= self.lastTryOnId then
        for k, v in ipairs(showTable) do
          if v.id == self.lastTryOnId then
            chooseItemIndex = k
          end
        end
      else
        local fashionId = self.data:GetWearIdByType(bFashion, typeEnum)
        if fashionId > 0 then
          for k, v in ipairs(showTable) do
            if v.id == fashionId then
              chooseItemIndex = k
            end
          end
        end
      end
    end
    if 0 == chooseItemIndex and typeEnum == Enum.FashionLabelType.FLT_SUIT and 0 ~= self.lastTryOnId then
      for k, v in ipairs(showTable) do
        if v.id == self.lastTryOnId then
          chooseItemIndex = k
        end
      end
    end
    if self.bDirectToUpgrade then
      for k, v in ipairs(showTable) do
        if v.id == self.bDirectToUpgradeSuitId then
          chooseItemIndex = k
        end
      end
    end
  else
    local bWearingHelmet = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsClosetAvatarWearingHelmet)
    local bSkipHairAutoSelect = typeEnum == _G.Enum.SalonLabelType.SLT_HAIR and bWearingHelmet
    local salonId = self.data:GetWearIdByType(bFashion, typeEnum)
    if salonId > 0 and not bSkipHairAutoSelect then
      for k, v in ipairs(showTable) do
        if v.id and #v.id > 0 then
          if #v.id > 1 then
            for key, subItemId in ipairs(v.id) do
              if subItemId == salonId then
                chooseItemIndex = k
                chooseColorIndex = key
              end
            end
          elseif v.id[1] == salonId then
            chooseItemIndex = k
          end
        end
      end
    end
  end
  if not bIgnoreInit then
    self.Buy_List:InitList(showTable)
  else
    self.Buy_List:InitList(showTable, true)
  end
  local bIgnoreSelection = false
  self.Buy_List:SetItemClickAble(true)
  if chooseItemIndex > 0 then
    if bFashion and typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
      local item = self.Buy_List:GetItemByIndex(chooseItemIndex - 1)
      item:IgnoreNextWear()
      bIgnoreSelection = true
    end
    local size = 0
    if showTable and #showTable > 0 then
      size = #showTable
    end
    for i = 0, size - 1 do
      local item = self.Buy_List:GetItemByIndex(i)
      if item then
        item:SetEnableSound(false)
        item:SetEnableUpgradeButtonAnim(false)
      end
    end
    self.Buy_List:SetScrollOffset(0)
    if self.selectedGlassItemIndex then
      self.Buy_List:SelectItemByIndex(self.selectedGlassItemIndex)
    else
      self.Buy_List:SelectItemByIndex(chooseItemIndex - 1)
    end
    if self.suitClaimable then
      self.Buy_List:SetScrollOffset(0)
    end
    for i = 0, size - 1 do
      local item = self.Buy_List:GetItemByIndex(i)
      if item then
        item:SetEnableSound(true)
        item:SetEnableUpgradeButtonAnim(true)
      end
    end
  end
  if self.bIsWandTabSelected then
    self.bIsWandTabSelected = false
    if chooseItemIndex <= 0 or bIgnoreSelection then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, false, self.module:OnCmdGetCurSuitWandId(), self.module.closetAvatarPlayer, false)
    end
  end
  if typeEnum == _G.Enum.FashionLabelType.FLT_WAND and bFashion then
    self.bIsWandTabSelected = true
  end
  if chooseColorIndex > 0 then
    for i = 1, self.Props_List:GetItemCount() do
      self.Props_List:OpItemByIndex(i, 1, false)
    end
    self.Props_List:SelectItemByIndex(chooseColorIndex - 1)
    for i = 1, self.Props_List:GetItemCount() do
      self.Props_List:OpItemByIndex(i, 1, true)
    end
  end
end

function UMG_ClosetPanel_C:SetUnlockListVisible(id)
  local fashionSuitsConf = _G.DataConfigManager:GetFashionSuitsConf(id)
  if fashionSuitsConf.lv_up_closet and #fashionSuitsConf.lv_up_closet > 0 then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(2)
  end
  self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ClosetPanel_C:SetCurSelectItem(labelType, id, colorIndex, bChoose, bIgnoreAnim, bRefreshBrand, glassInfo, bFashionType)
  if self.data.bChooseClosetFashionTab == false and not bFashionType then
    if type(id) == "table" and #id > 0 then
      if #id > 1 and labelType ~= Enum.SalonLabelType.SLT_EYES then
        self:RefreshHairColorList(id)
      else
        self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.module:OnCmdSetClosetAvatar(false, labelType, id[1], 0, bChoose, nil, glassInfo)
      end
    elseif type(id) == "number" then
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(id)
      if salonItemConf then
        self.module:OnCmdSetClosetAvatar(false, labelType, id, salonItemConf.texture_id, bChoose, glassInfo)
      end
    end
  elseif labelType == _G.Enum.FashionLabelType.FLT_SUIT then
    self.SuitUnlockList_1:ClearSelection()
    self:SetUnlockListVisible(id)
    local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(id)
    self:RemoveExtraFashions(id)
    local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, player.gender)
    local initSuitIdSet = {}
    if initSuitIds then
      for _, initId in ipairs(initSuitIds) do
        initSuitIdSet[initId] = true
      end
    end
    local isInitialSuit = initSuitIdSet[id]
    local bottomIdToKeep
    if isInitialSuit and self.data.TempAppearData then
      for _, wearItem in ipairs(self.data.TempAppearData) do
        if wearItem.FashionId > 0 then
          local wearItemConf = _G.DataConfigManager:GetFashionItemConf(wearItem.FashionId, true)
          if wearItemConf and wearItemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS then
            local wearBelongSuitId = self.data.fashionIdToSuitIdMap[wearItem.FashionId]
            if wearBelongSuitId and initSuitIdSet[wearBelongSuitId] and wearBelongSuitId ~= id then
              bottomIdToKeep = wearItem.FashionId
              self.data:SetInitialSuitBottomCache(player.gender, wearBelongSuitId)
            end
            break
          end
        end
      end
      if not bottomIdToKeep then
        local cachedSuitId = self.data:GetInitialSuitBottomCache(player.gender)
        if cachedSuitId and initSuitIdSet[cachedSuitId] and cachedSuitId ~= id then
          local cachedSuitConf = _G.DataConfigManager:GetFashionSuitsConf(cachedSuitId, true)
          if cachedSuitConf then
            for _, itemId in ipairs(cachedSuitConf.item_id) do
              local itemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
              if itemConf and itemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS then
                bottomIdToKeep = itemId
                break
              end
            end
          end
        end
      end
    end
    local fashionItems = {}
    for k, v in ipairs(fashionSuitConf.item_id) do
      local itemConf = _G.DataConfigManager:GetFashionItemConf(v, true)
      if isInitialSuit and bottomIdToKeep and itemConf and itemConf.type == _G.Enum.FashionLabelType.FLT_BOTTOMS then
      else
        local temp = {
          wearing_item_id = v,
          wearing_glass = self.module:GetCurSelectedItemGlassMap(v)
        }
        table.insert(fashionItems, temp)
      end
    end
    if bottomIdToKeep then
      local temp = {
        wearing_item_id = bottomIdToKeep,
        wearing_glass = self.module:GetCurSelectedItemGlassMap(bottomIdToKeep)
      }
      table.insert(fashionItems, temp)
    end
    if self.data.SuitComponentData[id] then
      for k, v in pairs(self.data.SuitComponentData[id]) do
        if v.bFashion then
          local temp = {
            wearing_item_id = v.id,
            wearing_glass = self.module:GetCurSelectedItemGlassMap(v.id)
          }
          table.insert(fashionItems, temp)
        end
      end
    end
    local salonIds = {}
    if self.data.TempBeautyData then
      for k, v in ipairs(self.data.TempBeautyData) do
        table.insert(salonIds, {
          item_wear_id = v.SalonId
        })
      end
    end
    if self.data.SuitComponentData[id] then
      for k, v in ipairs(self.data.SuitComponentData[id]) do
        if not v.bFashion then
          table.insert(salonIds, {
            item_wear_id = v.id
          })
        end
      end
    end
    self.module:SetDefaultSuitAvatar(true, fashionItems, salonIds, self.module.closetAvatarPlayer, function()
      if not bIgnoreAnim then
        self.module:PlayReloadingSkill(self.module.closetAvatarPlayer)
      end
      if self._pendingAfterSuitSwitch then
        local pending = self._pendingAfterSuitSwitch
        self._pendingAfterSuitSwitch = nil
        pending()
      end
    end)
    if not bIgnoreAnim and not self.bDirectToUpgrade then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, true, nil, self.module.closetAvatarPlayer)
    end
    if bRefreshBrand then
      self:RefreshBrandLogoByBrandId(fashionSuitConf.fashion_bond_band)
    end
    NRCGCManager:TryGC(false, 5)
  else
    self.module:OnCmdSetClosetAvatar(true, labelType, id, nil, bChoose, glassInfo)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PlayAvatarAnim, false, id, self.module.closetAvatarPlayer, bChoose)
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(id)
    if fashionItemConf then
      if fashionItemConf.type == _G.Enum.FashionLabelType.FLT_PENDANTA and bChoose then
        self.module:SetPlayerAngle(fashionItemConf.type, self.module.closetAvatarPlayer, "Closet")
      end
      if bRefreshBrand then
        if bChoose then
          self:RefreshBrandLogoByFashionConf(fashionItemConf.id, fashionItemConf)
        elseif 1 == #self.data.TempAppearData and self.data.TempAppearData[1].FashionType == _G.Enum.FashionLabelType.FLT_WAND then
          self:RefreshBrandLogoByFashionConf(self.data.TempAppearData[1].FashionId)
        elseif 0 == #self.data.TempAppearData then
          local wandId = self.module:OnCmdGetCurSuitWandId()
          if wandId then
            self:RefreshBrandLogoByFashionConf(wandId)
          end
        end
      end
    end
  end
  self:UpdateTopTabButtonState()
  self:UpdateLeftTabButtonState()
  self:SetConfirmBtnState()
end

function UMG_ClosetPanel_C:RemoveExtraFashions(suitId)
  local fashionSuitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  local hasType = {}
  for k, v in ipairs(fashionSuitConf.item_id) do
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
    table.insert(hasType, fashionItemConf.type)
  end
  if self.data.TempAppearData and #self.data.TempAppearData > 0 then
    local itemsToRemove = {}
    for k, v in ipairs(self.data.TempAppearData) do
      local bWear = false
      for key, type in ipairs(hasType) do
        if v.FashionType == type then
          bWear = true
          break
        end
      end
      if not bWear then
        table.insert(itemsToRemove, {
          FashionType = v.FashionType,
          FashionId = v.FashionId
        })
      end
    end
    for _, item in ipairs(itemsToRemove) do
      self.module:OnCmdSetClosetAvatar(true, item.FashionType, item.FashionId, nil, false)
    end
  end
end

function UMG_ClosetPanel_C:RemoveExtraUnit()
  if self.curShowUnitListInfo then
    for k, v in ipairs(self.curShowUnitListInfo) do
      local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(v.goods_id)
      if fashionGoodsConf.Type == _G.Enum.GoodsType.GT_SALON and 0 == v.buy_num then
        local curIndex = self.data:GetCurSelectWardrobeIndex()
        _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SetTryOnAppearance, false, {curIndex}, true)
        break
      end
    end
  end
end

function UMG_ClosetPanel_C:OnHelmetAutoRemoved()
  Log.Debug("UMG_ClosetPanel_C:OnHelmetAutoRemoved - Helmet auto-removed for hair selection")
  if 0 ~= self.lastTryOnId then
    local currentSuitId = self.data:GetWearIdByType(true, _G.Enum.FashionLabelType.FLT_SUIT)
    if currentSuitId ~= self.lastTryOnId then
      self.lastTryOnId = 0
    end
  end
  self:UpdateLeftTabButtonState()
end

function UMG_ClosetPanel_C:SetConfirmBtnState()
  self.NRCSwitcher_44:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Ununlocked.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Inproperly.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local bIsHeterochromeSuit = false
  local bHeterochromeSuitId = 0
  if 0 ~= self.lastTryOnId then
    bIsHeterochromeSuit, bHeterochromeSuitId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.IsSuitHeterochrome, self.lastTryOnId)
  end
  if bIsHeterochromeSuit then
    self:HandleHeterochromeSuitConfirmButton()
  else
    self:HandleNormalConfirmButton()
  end
end

function UMG_ClosetPanel_C:RefreshHairColorList(ids)
  local colorList = {}
  for k, v in ipairs(ids) do
    local hasOwned = self.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_SALON, v)
    table.insert(colorList, {
      salonConfId = v,
      lockState = hasOwned,
      ownedPanel = self
    })
  end
  if #colorList > 0 then
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self.NRCSwitcher_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Props_List:InitGridView(colorList)
    for i = 1, self.Props_List:GetItemCount() do
      self.Props_List:OpItemByIndex(i, 1, false)
    end
    self.Props_List:SelectItemByIndex(0)
    for i = 1, self.Props_List:GetItemCount() do
      self.Props_List:OpItemByIndex(i, 1, true)
    end
  end
  Log.Dump(colorList, 3, "UMG_ClosetPanel_C:RefreshHairColorList")
end

function UMG_ClosetPanel_C:RefreshTryOnUnlockShop(shopItemList, shopId)
  self.shopItemsList = shopItemList
  self.curShowUnitListInfo = self:GetUnlockListShowType(shopItemList, false)
  self.data.allClothShopInfoMap[shopId] = shopItemList
  self:UpdatePetIconBackground()
  local bFashion = self.data.bChooseClosetFashionTab
  local typeEnum = self.data.closetChooseTabType
  if not bFashion or typeEnum == _G.Enum.FashionLabelType.FLT_SUIT then
  end
  self:UpdateMoney()
end

function UMG_ClosetPanel_C:UpdatePetIconBackground()
  local itemCount = self.Buy_List:GetItemCount()
  for i = 0, itemCount - 1 do
    local item = self.Buy_List:GetItemByIndex(i)
    if item then
      item:UpdatePetIconBackground()
    end
  end
end

function UMG_ClosetPanel_C:UpdateLeftTabButtonState()
  local itemCount = self.Appearance_Tab1:GetItemCount()
  for i = 0, itemCount - 1 do
    local item = self.Appearance_Tab1:GetItemByIndex(i)
    if item then
      item:UpdateDressPrompt(0 ~= self.lastTryOnId)
    end
  end
end

function UMG_ClosetPanel_C:UpdateTopTabButtonState()
  local itemCount = self.HorizontalTab1:GetItemCount()
  for i = 0, itemCount - 1 do
    local item = self.HorizontalTab1:GetItemByIndex(i)
    if item then
      item:UpdateDressPrompt()
    end
  end
end

function UMG_ClosetPanel_C:GetUnlockListShowType(shopItemList, bNewPanel)
  local showItems = {}
  local curGoodsItemId = self.data.curTryOnItemInfo.id
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(curGoodsItemId, true)
  if suitConf then
    for key, closet in ipairs(suitConf.lv_up_closet) do
      for k, shopItem in ipairs(shopItemList) do
        shopItem.newPanel = bNewPanel
      end
    end
  end
  return showItems
end

function UMG_ClosetPanel_C:HasChanged()
  if not self.module then
    return false
  end
  local curIndex = self.data:GetCurSelectWardrobeIndex()
  local wardrobeFashionList, wardrobeSalonList = self.data:GetWardrobeDataByIndex(curIndex)
  if 0 == curIndex then
    return false
  end
  local savedFashionMap = {}
  local savedFashionCount = 0
  if wardrobeFashionList then
    for _, v in ipairs(wardrobeFashionList) do
      if v and v.wearing_item_id and 0 ~= v.wearing_item_id then
        savedFashionMap[v.wearing_item_id] = {
          glassInfo = v.wearing_glass
        }
        savedFashionCount = savedFashionCount + 1
      end
    end
  end
  local bSavedHasWand = false
  for fashionId, _ in pairs(savedFashionMap) do
    local item = _G.DataConfigManager:GetFashionItemConf(fashionId)
    if item and item.type == _G.Enum.FashionLabelType.FLT_WAND then
      bSavedHasWand = true
      break
    end
  end
  if not bSavedHasWand then
    local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
    if wandId and 0 ~= wandId then
      savedFashionMap[wandId] = {glassInfo = nil}
      savedFashionCount = savedFashionCount + 1
    end
  end
  local wearingFashionMap = {}
  local wearingFashionCount = 0
  if self.data.TempAppearData and #self.data.TempAppearData > 0 then
    for _, v in ipairs(self.data.TempAppearData) do
      if v.FashionId and 0 ~= v.FashionId then
        wearingFashionMap[v.FashionId] = {
          glassInfo = v.glassInfo
        }
        wearingFashionCount = wearingFashionCount + 1
      end
    end
  end
  local bWearingHasWand = false
  for fashionId, _ in pairs(wearingFashionMap) do
    local item = _G.DataConfigManager:GetFashionItemConf(fashionId)
    if item and item.type == _G.Enum.FashionLabelType.FLT_WAND then
      bWearingHasWand = true
      break
    end
  end
  if not bWearingHasWand then
    local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
    if wandId and 0 ~= wandId then
      local goodsId = self.module.data.FashionIdToGoodsIdMap[wandId] or 0
      wearingFashionMap[wandId] = {glassInfo = nil}
      wearingFashionCount = wearingFashionCount + 1
      if not self.data.TempAppearData then
        self.data.TempAppearData = {}
      end
      table.insert(self.data.TempAppearData, {
        FashionId = wandId,
        FashionType = _G.Enum.FashionLabelType.FLT_WAND,
        FashionGoodsId = goodsId
      })
    end
  end
  local initItemEquivalenceMap = {}
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local initSuitIds = _G.NRCModuleManager:DoCmd(_G.AppearanceLoginModuleCmd.GetInitialOptionalSuitIds, player.gender)
    if initSuitIds and #initSuitIds > 1 then
      local typeToItems = {}
      for _, suitId in ipairs(initSuitIds) do
        local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId, true)
        if suitConf and suitConf.item_id then
          for _, itemId in ipairs(suitConf.item_id) do
            local itemConf = _G.DataConfigManager:GetFashionItemConf(itemId, true)
            if itemConf and itemConf.type ~= _G.Enum.FashionLabelType.FLT_BOTTOMS then
              if not typeToItems[itemConf.type] then
                typeToItems[itemConf.type] = {}
              end
              table.insert(typeToItems[itemConf.type], itemId)
            end
          end
        end
      end
      for _, items in pairs(typeToItems) do
        if #items > 1 then
          for i = 1, #items do
            for j = 1, #items do
              if i ~= j then
                initItemEquivalenceMap[items[i]] = items[j]
              end
            end
          end
        end
      end
    end
  end
  if savedFashionCount ~= wearingFashionCount then
    return true
  end
  for fashionId, wearingData in pairs(wearingFashionMap) do
    local savedData = savedFashionMap[fashionId]
    if not savedData then
      local equivalentId = initItemEquivalenceMap[fashionId]
      if equivalentId then
        savedData = savedFashionMap[equivalentId]
      end
    end
    if not savedData then
      return true
    end
    if not IsSameGlassInfo(wearingData.glassInfo, savedData.glassInfo) then
      return true
    end
  end
  local savedSalonSet = {}
  local savedSalonCount = 0
  if wardrobeSalonList then
    for _, salonId in ipairs(wardrobeSalonList) do
      if salonId and 0 ~= salonId then
        savedSalonSet[salonId] = true
        savedSalonCount = savedSalonCount + 1
      end
    end
  end
  local wearingSalonSet = {}
  local wearingSalonCount = 0
  if self.data.TempBeautyData and #self.data.TempBeautyData > 0 then
    for _, v in ipairs(self.data.TempBeautyData) do
      if v.SalonId and 0 ~= v.SalonId then
        wearingSalonSet[v.SalonId] = true
        wearingSalonCount = wearingSalonCount + 1
      end
    end
  end
  if savedSalonCount ~= wearingSalonCount then
    return true
  end
  for salonId, _ in pairs(wearingSalonSet) do
    if not savedSalonSet[salonId] then
      return true
    end
  end
  return false
end

function UMG_ClosetPanel_C:OnAnimationFinished(anim)
  if anim == self.close then
    if self.bIsOpeningUpgradeComponent then
      self:GoToSuitUpgrade(self.curFashionUIData.id)
    end
  elseif anim == self.open then
    print("Animation open played")
  end
end

function UMG_ClosetPanel_C:SelectSuitItemByIndex(index)
  self.Suit:SetWardrobeIndex(index)
end

function UMG_ClosetPanel_C:GetDefaultSalonData()
  if self.module and self.module.OnCmdGetTempAppearOrBeautyData then
    return self.module:OnCmdGetTempAppearOrBeautyData(_G.Enum.GoodsType.GT_SALON)
  end
  return {}
end

function UMG_ClosetPanel_C:GetDefaultFashionData()
  if not self.originalFashion then
    self.originalFashion = {}
    local temp = self.module:OnCmdGetTempAppearOrBeautyData(_G.Enum.GoodsType.GT_FASHION)
    if temp then
      for k, v in pairs(temp) do
        table.insert(self.originalFashion, k, {
          FashionGoodsId = v.FashionGoodsId,
          FashionId = v.FashionId,
          FashionType = v.FashionType
        })
      end
    end
  end
  return self.originalFashion
end

function UMG_ClosetPanel_C:RequestExchangeShopData()
  local reqShopData = {
    shopId = AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION,
    Caller = self,
    rspHandler = self.OnExchangeShopDataRsp,
    needModal = false,
    ignoreErrorTip = true,
    reqTag = "ClosetExchangeShop"
  }
  _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdReqGetShopData, reqShopData)
end

function UMG_ClosetPanel_C:OnExchangeShopDataRsp(shopRsp)
  Log.Info("UMG_ClosetPanel_C:OnExchangeShopDataRsp received shop data for shop_id " .. tostring(AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION))
end

function UMG_ClosetPanel_C:OpenExchangeShopWithGoods(shopId, goodsId)
  Log.Info(string.format("UMG_ClosetPanel_C:OpenExchangeShopWithGoods shopId=%s, goodsId=%s", tostring(shopId), tostring(goodsId)))
  _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OpenMainPanel, 3)
end

function UMG_ClosetPanel_C:CheckSuitInExchangeShop(suitId)
  local goodsId = self.data:GetExchangeGoodsIdBySuitId(suitId)
  if not goodsId then
    return nil
  end
  local goodsData = _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION, goodsId, true)
  if goodsData then
    Log.Info(string.format("UMG_ClosetPanel_C:CheckSuitInExchangeShop suitId=%d found in exchange shop, goodsId=%d", suitId, goodsId))
    return goodsId
  end
  return nil
end

function UMG_ClosetPanel_C:HasExchangeVoucher(suitId)
  local voucherId = self.data:GetExchangeVoucherIdBySuitId(suitId)
  if not voucherId then
    return false
  end
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, voucherId)
  return nil ~= bagItem
end

function UMG_ClosetPanel_C:IsSuitPurchasable(suitId)
  Log.Info(string.format("UMG_ClosetPanel_C:IsSuitPurchasable %s \230\173\163\229\156\168\229\136\164\230\150\173\230\152\175\229\144\166\232\131\189\232\180\173\228\185\176", suitId))
  local bIsFunctionBanned = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FASHION_STORE)
  if bIsFunctionBanned then
    return false
  end
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(suitId)
  if not suitConf then
    return false
  end
  if suitConf.package_id and 0 ~= suitConf.package_id then
    local packageId = suitConf.package_id
    if self.data.allClothShopInfoMap[AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG] then
      for k, v in pairs(self.data.allClothShopInfoMap[AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG]) do
        local fashionGoodsConf = _G.DataConfigManager:GetNormalShopConf(v.goods_id, true)
        if fashionGoodsConf and fashionGoodsConf.Type == _G.Enum.GoodsType.GT_FASHION_PACKAGE and fashionGoodsConf.item_id == packageId then
          Log.Info(string.format("UMG_ClosetPanel_C:IsSuitPurchasable %s \229\143\175\232\180\173\228\185\176\239\188\140\231\155\174\229\137\141\231\187\132\229\144\136\229\140\133\230\173\163\232\167\163\233\148\129", suitId))
          return true, AppearanceModuleEnum.FashionMallShopId.SEASONAL_COMBINATION_BAG
        end
      end
    end
  end
  local exchangeGoodsId = self:CheckSuitInExchangeShop(suitId)
  if exchangeGoodsId then
    Log.Info(string.format("UMG_ClosetPanel_C:IsSuitPurchasable %s \229\143\175\232\180\173\228\185\176\239\188\140\229\156\168\229\133\145\230\141\162\229\149\134\229\186\151\228\184\173 goodsId=%d", suitId, exchangeGoodsId))
    return true, AppearanceModuleEnum.FashionMallShopId.EXCHANGE_FASHION, exchangeGoodsId
  end
  return false
end

function UMG_ClosetPanel_C:OnUncancelableItemSelected(index)
  self.Buy_List:SetItemClickAble(true)
  self.Buy_List:SetItemClickAbleByIndex(false, index)
end

function UMG_ClosetPanel_C:CheckIfTabBan(tabConfId, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if isBan or tabConfId then
  end
  return isBan
end

function UMG_ClosetPanel_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  if userClick then
    local tabIndexToConfId = self.tabIndexToConfId
    local tabConfId = tabIndexToConfId and tabIndexToConfId[tabIndex]
    return not self:CheckIfTabBan(tabConfId, true)
  end
  return true
end

function UMG_ClosetPanel_C:OnTabVisibilityChangeHandler(tabConfId, funcId, bHide)
  if funcId == FunctionEntranceMain or tabConfId == self.curTabConfId then
    local isBan = bHide or self:CheckIfTabBan(tabConfId, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ClosetPanel_C:OnBlockBtnClicked()
  local isBan = self:CheckIfTabBan(self.curTabConfId, true)
  if not isBan then
    Log.Error("UMG_ClosetPanel_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_ClosetPanel_C:OnUpgradeBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClosetPanel_C:OnUpgradeBtnClicked")
  NRCProfilerLog:NRCClickBtn(true, "AppearanceUpgrade")
  self.bIsOpeningUpgradeComponent = true
  self:PlayCloseAnimation()
end

function UMG_ClosetPanel_C:OnMedalEntranceBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1220002026, "UMG_ClosetPanel_C:OnMedalEntranceBtnClicked")
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenGorgeousMedalPanel)
end

function UMG_ClosetPanel_C:OnLockButtonClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_ClosetPanel_C:OnLockButtonClicked")
  local title = ""
  local content = _G.LuaText.popup_dressup_unlocked_item
  local context = _G.DialogContext()
  context:SetMode(DialogContext.Mode.OK_CANCEL):SetTitle(title):SetContent(content):SetCloseOnOK(true):SetCallback(self, self.OnClickLockButtonCallback):SetDialogType(DialogContext.DialogType.GeneralTip)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, context)
end

function UMG_ClosetPanel_C:OnInproperlyBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_ClosetPanel_C:OnLockButtonClicked")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.dressup_wear_pajamas_tips)
end

function UMG_ClosetPanel_C:OnClickLockButtonCallback(bIsOk)
  if bIsOk then
    self:SaveHasFashionAndSalon()
  else
  end
end

function UMG_ClosetPanel_C:GetUpgradeZoomIn()
  return self.bUpgradeZoomIn
end

function UMG_ClosetPanel_C:SetUpgradeZoomIn(bZoomIn)
  if self.bUpgradeZoomIn == bZoomIn then
    return
  end
  self.bUpgradeZoomIn = bZoomIn
  self.module:OnCmdPlayMeiRongSkillByType(not bZoomIn)
end

function UMG_ClosetPanel_C:RefreshUpgradeZoomState()
  self.module:OnCmdPlayMeiRongSkillByType(not self.bUpgradeZoomIn)
end

function UMG_ClosetPanel_C:OnUpgradeComponentOpen()
  if self.NRCSafeZone_1:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:StopAnimation(self.close)
  self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ClosetPanel_C:OnUpgradeComponentClose(bSkipSetVisibility)
  self.bIsOpeningUpgradeComponent = false
  if self.bDirectToUpgrade then
    self.bUpgradeZoomIn = false
    self:DoClose()
    return
  end
  local isOpen = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GorgeousMedalPanelIsOpen)
  if isOpen then
    return
  end
  self.bUpgradeZoomIn = false
  if not bSkipSetVisibility then
    self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Suit:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:PlayOpenAnimation()
end

function UMG_ClosetPanel_C:OnGorgeousMedalOpen()
  self.MedalEntrance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.NRCSafeZone_1:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  if self.bFastDressUp then
    self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:PlayCloseAnimation()
  end
end

function UMG_ClosetPanel_C:OnGorgeousMedalClose()
  self.MedalEntrance:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local isOpen = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.FashionUpgradePanelIsOpen)
  if isOpen then
    return
  end
  self.Suit:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayOpenAnimation()
end

function UMG_ClosetPanel_C:PlayOpenAnimation()
  self:StopAnimation(self.close)
  self:StopAnimation(self.open)
  self:PlayAnimation(self.open)
end

function UMG_ClosetPanel_C:PlayCloseAnimation()
  self:StopAnimation(self.close)
  self:PlayAnimation(self.close)
end

function UMG_ClosetPanel_C:GoToSuitUpgrade(suitId, bIgnoreSelectionAnim, defaultSelectIndex)
  if self.data.closetChooseTabType ~= Enum.FashionLabelType.FLT_SUIT then
    self:UpdateListByType(true, Enum.FashionLabelType.FLT_SUIT)
  end
  local upgradeDefaultIndex = self.directToUpgradeDefaultIndex or defaultSelectIndex
  local curSuitId = self.curFashionUIData and self.curFashionUIData.id
  local bNeedSwitchSuit = nil == curSuitId or curSuitId ~= suitId
  if bNeedSwitchSuit then
    function self._pendingAfterSuitSwitch()
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionUpgradePanel, suitId, self, upgradeDefaultIndex)
    end
    
    local index = 0
    local count = self.Buy_List:GetScrollViewLength()
    for i = 0, count - 1 do
      local item = self.Buy_List:GetItemByIndex(i)
      if item and item.uiData.typeEnum == _G.Enum.FashionLabelType.FLT_SUIT and item.uiData.id == suitId then
        index = i
        break
      end
    end
    self.Buy_List:SetScrollOffset(0)
    self.Buy_List:SelectItemByIndex(index)
  else
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenFashionUpgradePanel, suitId, self, upgradeDefaultIndex)
  end
end

function UMG_ClosetPanel_C:OnRedPointChanged(notify)
  if self.data then
    self.data:BuildTimeTokenDic()
    self.redDotMap, self.needToEraseSet = self:_GetRedDotLabelMap()
    local size = self.Appearance_Tab1:GetItemCount()
    for i = 0, size - 1 do
      local item = self.Appearance_Tab1:GetItemByIndex(i)
      if item then
        if self.redDotMap[item.uiData.bFashion][item.uiData.LabelType] and #self.redDotMap[item.uiData.bFashion][item.uiData.LabelType] > 0 then
          item:SetupRedDot(true)
        else
          item:SetupRedDot(false)
        end
      end
    end
    size = self.HorizontalTab1:GetItemCount()
    for i = 0, size - 1 do
      local item = self.HorizontalTab1:GetItemByIndex(i)
      if item then
        if item.uiData and self.redDotMap[item.uiData.bFashion][item.uiData.LabelType] and #self.redDotMap[item.uiData.bFashion][item.uiData.LabelType] > 0 then
          item:SetupRedDot(true)
        else
          item:SetupRedDot(false)
        end
      end
    end
    size = self.Buy_List:GetItemCount()
    for i = 0, size - 1 do
      local item = self.Buy_List:GetItemByIndex(i)
      if item then
        item:UpdateRedDotMutex()
      end
    end
  end
end

function UMG_ClosetPanel_C:_GetRedDotLabelMap()
  local fashionKey = true
  local salonKey = false
  local result = {
    [fashionKey] = {},
    [salonKey] = {}
  }
  local clothSubType = {}
  local accessoriesSubType = {}
  local salonSubType = {}
  local closetTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
  local closetTabTable = closetTabConf:GetAllDatas()
  for _, conf in pairs(closetTabTable) do
    if not string.IsNilOrEmpty(conf.fathertab) then
      local fathertab = tonumber(conf.fathertab)
      if 3 == fathertab then
        if conf.use_FashionLabelType and conf.use_FashionLabelType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
          clothSubType[conf.use_FashionLabelType] = true
        end
      elseif 9 == fathertab then
        if conf.use_FashionLabelType and conf.use_FashionLabelType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
          accessoriesSubType[conf.use_FashionLabelType] = true
        end
      elseif 16 == fathertab and conf.use_SalonLabelType and conf.use_SalonLabelType ~= _G.Enum.SalonLabelType.SLT_BEGIN then
        salonSubType[conf.use_SalonLabelType] = true
      end
    end
  end
  local suitRedPoint = self.data.suitItemIdToTimeTokenDic
  local itemRedPoint = self.data.itemIdToTimeTokenDic
  result[fashionKey][_G.Enum.FashionLabelType.FLT_SUIT] = {}
  for k, v in pairs(suitRedPoint) do
    table.insert(result[fashionKey][_G.Enum.FashionLabelType.FLT_SUIT], k)
  end
  local needToEraseSet = {}
  local needToEraseExtraKeyList = {}
  
  local function AddNeedToErase(itemId)
    if not needToEraseSet[itemId] then
      local extraKey = {
        tostring(itemId)
      }
      needToEraseSet[itemId] = extraKey
      table.insert(needToEraseExtraKeyList, extraKey)
    end
  end
  
  local suitComponentSet = {}
  if result[fashionKey][_G.Enum.FashionLabelType.FLT_SUIT] then
    for k, v in ipairs(result[fashionKey][_G.Enum.FashionLabelType.FLT_SUIT]) do
      local conf = _G.DataConfigManager:GetFashionSuitsConf(v)
      if conf and conf.item_id then
        for _, itemId in ipairs(conf.item_id) do
          suitComponentSet[itemId] = true
        end
      end
    end
  end
  for k, v in pairs(itemRedPoint) do
    local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(k)
    if fashionItemConf then
      if true == suitComponentSet[fashionItemConf.id] then
        AddNeedToErase(fashionItemConf.id)
      else
        if not result[fashionKey][fashionItemConf.type] then
          result[fashionKey][fashionItemConf.type] = {}
        end
        table.insert(result[fashionKey][fashionItemConf.type], k)
        if true == clothSubType[fashionItemConf.type] then
          if not result[fashionKey][_G.Enum.FashionLabelType.FLT_CLOTHES] then
            result[fashionKey][_G.Enum.FashionLabelType.FLT_CLOTHES] = {}
          end
          table.insert(result[fashionKey][_G.Enum.FashionLabelType.FLT_CLOTHES], k)
        end
        if true == accessoriesSubType[fashionItemConf.type] then
          if not result[fashionKey][_G.Enum.FashionLabelType.FLT_ACCESSORIES] then
            result[fashionKey][_G.Enum.FashionLabelType.FLT_ACCESSORIES] = {}
          end
          table.insert(result[fashionKey][_G.Enum.FashionLabelType.FLT_ACCESSORIES], k)
        end
      end
    else
      local salonItemConf = _G.DataConfigManager:GetSalonItemConf(k)
      if salonItemConf then
        if true == suitComponentSet[salonItemConf.id] then
          AddNeedToErase(salonItemConf.id)
        else
          if not result[salonKey][salonItemConf.type] then
            result[salonKey][salonItemConf.type] = {}
          end
          table.insert(result[salonKey][salonItemConf.type], k)
          if true == salonSubType[salonItemConf.type] then
            if not result[fashionKey][_G.Enum.FashionLabelType.FLT_SALON] then
              result[fashionKey][_G.Enum.FashionLabelType.FLT_SALON] = {}
            end
            table.insert(result[fashionKey][_G.Enum.FashionLabelType.FLT_SALON], k)
          end
        end
      end
    end
  end
  if #needToEraseExtraKeyList > 0 then
    _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPointWithExtraKeyList, 408, needToEraseExtraKeyList, true)
  end
  return result, needToEraseSet
end

function UMG_ClosetPanel_C:EnterSuitUpgradePanel(suitId, packageId)
  self.bIsFromTryOn = true
  self.TempPackageId = packageId
  self.NRCSafeZone_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Suit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:GoToSuitUpgrade(suitId)
end

function UMG_ClosetPanel_C:OnSelectEmptySuitIndex(selectedSuitIndex)
  local itemsToRemove = {}
  if self.data.TempAppearData then
    for k, v in ipairs(self.data.TempAppearData) do
      table.insert(itemsToRemove, {
        FashionType = v.FashionType,
        FashionId = v.FashionId
      })
    end
    for k, v in ipairs(itemsToRemove) do
      if v.FashionType ~= _G.Enum.FashionLabelType.FLT_WAND then
        self.module:OnCmdSetClosetAvatar(true, v.FashionType, v.FashionId, nil, false)
      end
    end
  end
  local salonIds = {}
  if self.data.TempBeautyData then
    for k, v in ipairs(self.data.TempBeautyData) do
      table.insert(salonIds, {
        item_wear_id = v.SalonId
      })
    end
  end
  self.module:SetDefaultSuitAvatar(true, nil, salonIds, self.module.closetAvatarPlayer, nil, true)
  self:UpdateCurClosetTab({}, selectedSuitIndex)
  self:SetConfirmBtnState()
  self:UpdateViewButtonState(false)
  self:SetConfirmBtnState()
  self:UpdateTitlesAndCurrentDetailId("", "", nil, false)
  self.Suit:UpdateSuitBtnIconOnSelection(nil)
end

function UMG_ClosetPanel_C:HasFashionConflict(newItemType, newItemTag, newItemFashionId, bIncludeBodyType)
  if not self.data.TempAppearData then
    return false
  end
  if nil == bIncludeBodyType then
    bIncludeBodyType = true
  end
  local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
  local ids = {}
  local types = {}
  local newTagMap = AppearanceUtils.BuildTagMapFromAppearData(newItemType, newItemTag)
  if next(newTagMap) then
    for _, v in ipairs(self.data.TempAppearData) do
      if v.tag then
        local existTagMap = AppearanceUtils.BuildTagMapFromAppearData(v.FashionType, v.tag)
        if AppearanceUtils.CheckTagConflict(newTagMap, existTagMap) then
          table.insert(ids, v.FashionId)
          table.insert(types, v.FashionType)
        end
      end
    end
  end
  if bIncludeBodyType and newItemFashionId then
    local newAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(newItemFashionId)
    if newAvatarEnum then
      local conflictBodyTypes = AppearanceUtils.GetConflictBodyTypes(newAvatarEnum)
      if conflictBodyTypes and #conflictBodyTypes > 0 then
        for _, v in ipairs(self.data.TempAppearData) do
          if v.FashionId ~= newItemFashionId then
            local existAvatarEnum = AppearanceUtils.GetAvatarEnumFromFashionId(v.FashionId)
            if existAvatarEnum then
              for _, conflictType in ipairs(conflictBodyTypes) do
                if existAvatarEnum == conflictType then
                  table.insert(ids, v.FashionId)
                  table.insert(types, v.FashionType)
                  break
                end
              end
            end
          end
        end
      end
    end
  end
  if #ids > 0 then
    return true, ids, types
  end
  return false
end

function UMG_ClosetPanel_C:HandleNormalConfirmButton()
  local filterItemList = self.data:FilterHasAndInitFashion()
  local filterSalonList = self.data:FilterHasAndInitSalon()
  if filterItemList and #filterItemList > 0 or filterSalonList and #filterSalonList > 0 then
    if 1 == self.tabConfId then
      if self.lastTryOnId and self:HasExchangeVoucher(self.lastTryOnId) then
        self.NRCSwitcher_44:SetActiveWidgetIndex(7)
      elseif self.lastTryOnId and self:IsSuitPurchasable(self.lastTryOnId) then
        self.canBuySuitId = self.lastTryOnId
        self.NRCSwitcher_44:SetActiveWidgetIndex(2)
        self.PurchaseBtn.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.PurchaseBtn.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local bHasVoucher = false
        local bCanBuy = true
        local canBuySuitId = 0
        for k, v in ipairs(filterItemList) do
          local suitId = self.data.fashionIdToSuitIdMap[v.FashionId] or 0
          if self:HasExchangeVoucher(suitId) then
            bHasVoucher = true
            break
          end
          bCanBuy = bCanBuy and self:IsSuitPurchasable(suitId)
          if not bCanBuy then
            break
          end
          canBuySuitId = suitId
        end
        if bHasVoucher then
          self.NRCSwitcher_44:SetActiveWidgetIndex(7)
        elseif bCanBuy then
          self.canBuySuitId = canBuySuitId
          self.NRCSwitcher_44:SetActiveWidgetIndex(2)
          self.PurchaseBtn.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.PurchaseBtn.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.NRCSwitcher_44:SetActiveWidgetIndex(0)
          self.Ununlocked.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    else
      self.NRCSwitcher_44:SetActiveWidgetIndex(0)
    end
  else
    local bIsProperly = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckOutfitProperly)
    if bIsProperly then
      self.NRCSwitcher_44:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_44:SetActiveWidgetIndex(3)
    end
  end
end

function UMG_ClosetPanel_C:HandleHeterochromeSuitConfirmButton()
  local bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, self.lastTryOnId)
  if bHasSuit then
    local bIsProperly = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckOutfitProperly)
    if bIsProperly then
      self.NRCSwitcher_44:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_44:SetActiveWidgetIndex(3)
    end
  else
    local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(self.lastTryOnId)
    if not suitsConf then
      Log.Error("UMG_ClosetPanel_C:HandleHeterochromeSuitConfirmButton \229\164\132\231\144\134\229\188\130\232\137\178\229\165\151\232\163\133\231\161\174\232\174\164\230\140\137\233\146\174\229\135\186\231\142\176\233\148\153\232\175\175\239\188\140\229\175\185\229\186\148\231\154\132\229\188\130\232\137\178\229\165\151\232\163\133Id\228\184\141\229\173\152\229\156\168 Id\228\184\186%s", self.lastTryOnId)
      return
    end
    local bHasShining = false
    local petGid = 0
    if suitsConf and suitsConf.petbase_id then
      for _, petBaseId in pairs(suitsConf.petbase_id or {}) do
        local petData = _G.DataModelMgr.PlayerDataModel:GetPetDatasByPetBaseId(petBaseId)
        for _, v in ipairs(petData) do
          if 0 ~= v.mutation_type & _G.Enum.MutationDiffType.MDT_SHINING then
            petGid = v.gid
            bHasShining = true
            break
          end
        end
        if bHasShining then
          break
        end
      end
    end
    if not bHasShining and not petGid then
      return
    end
    if not bHasShining then
      self.NRCSwitcher_44:SetActiveWidgetIndex(4)
      return
    end
    local bHasBond = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.HasFashionBond, suitsConf.bond_id)
    if not bHasBond then
      local bHasOriginalSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, suitsConf.suits_original_id)
      if bHasOriginalSuit then
        self.obtainSuitId = suitsConf.suits_original_id
        self.NRCSwitcher_44:SetActiveWidgetIndex(5)
      elseif self:IsSuitPurchasable(suitsConf.suits_original_id) then
        self.canBuySuitId = suitsConf.suits_original_id
        self.NRCSwitcher_44:SetActiveWidgetIndex(2)
        self.PurchaseBtn.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.PurchaseBtn.TextPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.NRCSwitcher_44:SetActiveWidgetIndex(0)
      end
      return
    end
    if bHasShining and bHasBond then
      self.claimColorSuitBondId = suitsConf.bond_id
      self.claimColorSuitPetGid = petGid
      self.NRCSwitcher_44:SetActiveWidgetIndex(6)
      local extraKey = string.format("%s", self.claimColorSuitBondId)
      self.Btn_ReqColorSuit.RedDot:SetupKey(466, extraKey)
    end
  end
end

function UMG_ClosetPanel_C:OnObtainBtnClicked()
  local defaultSelectIndex
  local suitsConf = _G.DataConfigManager:GetFashionSuitsConf(self.obtainSuitId)
  if suitsConf and suitsConf.lv_up_closet and #suitsConf.lv_up_closet > 0 then
    for k, v in ipairs(suitsConf.lv_up_closet) do
      if v.lv_item_type == _G.Enum.GoodsType.GT_FASHION_BOND then
        defaultSelectIndex = k - 1
        break
      end
    end
  end
  self:GoToSuitUpgrade(self.obtainSuitId, nil, defaultSelectIndex)
end

function UMG_ClosetPanel_C:OnReqColorSuitBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClosetPanel_C:OnReqColorSuitBtnClicked")
  self.Btn_ReqColorSuit.RedDot:EraseRedPoint(true)
  self.bCanUpdateCloset = false
  local item = self.Buy_List:GetSelectedItem()
  if item then
    item.CanvasPanel_249:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.ClaimHeterochromeSuitReq, self.claimColorSuitBondId, self.claimColorSuitPetGid, true)
end

function UMG_ClosetPanel_C:OnClickedWardrobeBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_ClosetPanel_C:OnClickedWardrobeBtn")
  self.NRCSwitcher_620:SetActiveWidgetIndex(1)
  self.bEnterFilterGlassItemState = true
  self.bNeedToForceInit = true
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.filter_color_tint_fashion_items)
  self.Appearance_Tab1:SelectItemByIndex(1)
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnEnterFilterGlassItem, self.bEnterFilterGlassItemState)
end

function UMG_ClosetPanel_C:OnClickedColorfulClothingBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_ClosetPanel_C:OnClickedColorfulClothingBtn")
  self.NRCSwitcher_620:SetActiveWidgetIndex(0)
  self.bEnterFilterGlassItemState = false
  self.bNeedToForceInit = true
  self.Appearance_Tab1:SelectItemByIndex(1)
  _G.NRCEventCenter:DispatchEvent(AppearanceModuleEvent.OnEnterFilterGlassItem, self.bEnterFilterGlassItemState)
end

function UMG_ClosetPanel_C:OnClickedClaimGlassTint()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_ClosetPanel_C:OnClickedClaimGlassTint")
  self.Btn_ReqColorSuit.RedDot:EraseRedPoint(true)
  local itemInfo = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurrentSelectItemInfo)
  if itemInfo then
    local itemID = itemInfo.itemID
    self.selectedGlassItemIndex = self.Buy_List:GetSelectedIndex() - 1
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SendClaimGlassTintReq, nil, nil, nil, itemID)
  end
end

function UMG_ClosetPanel_C:RefreshCurrentConflictUIShow()
  for i = 1, self.Buy_List:GetTotalItemNumber() do
    self.Buy_List:OpItemByIndex(i, 2)
  end
end

function UMG_ClosetPanel_C:SetAppearanceTabSelectedIndex(index)
  if self.Appearance_Tab1:GetSelectedIndex() == index then
    return
  end
  self.Appearance_Tab1:SelectItemByIndex(index)
end

return UMG_ClosetPanel_C
