local UMG_Shop_CollectProgress_C = _G.NRCPanelBase:Extend("UMG_Shop_CollectProgress_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")

function UMG_Shop_CollectProgress_C:OnConstruct()
  self:AddButtonListener(self.BtnApparel.btnLevelUp, self.OnClickBtnApparel)
  self:AddButtonListener(self.BtnNotarize.btnLevelUp, self.OnClickBtnNotarize)
  self.isCollectPlaying = false
end

function UMG_Shop_CollectProgress_C:OnActive(ShopID, itemArray, isSuit)
  self.ShopID = ShopID
  self.ItemArray = itemArray
  self.BuyItemID = 0
  local SuitID = 0
  if nil == itemArray or 0 == #itemArray then
    return
  end
  if 1 == #itemArray then
    local shopConf = _G.DataConfigManager:GetShopConf(ShopID)
    if shopConf and shopConf.shop_type == Enum.ShopType.ST_FASHION_RANDOM then
      local fashionId = itemArray[1].id
      if isSuit then
        SuitID = fashionId
      else
        SuitID = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromFashionId, fashionId)
      end
      self.BuyItemID = fashionId
    end
  end
  if nil == SuitID or 0 == SuitID then
    return
  end
  self.SuitID = SuitID
  local suitConf = _G.DataConfigManager:GetFashionSuitsConf(SuitID)
  if suitConf then
    self.suitConf = suitConf
    self.Pose:SetPath(suitConf.suits_icon_big)
    if suitConf.name and self.TextTitle then
      self.TextTitle:SetText(suitConf.name)
    end
  end
  local packageId = suitConf and suitConf.package_id
  if packageId then
    local packageConf = _G.DataConfigManager:GetFashionPackageConf(packageId)
    if packageConf and packageConf.name and self.Subtitle then
      self.Subtitle:SetText(packageConf.name)
      if self.LeftBG and packageConf.bg_colour then
        self.LeftBG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(packageConf.bg_colour))
      else
        Log.Warning("UMG_Shop_CollectProgress_C:OnActive packageConf.bg_colour is nil")
      end
      if self.TearTheCard and packageConf.bg_image then
        self.TearTheCard:SetPath(packageConf.bg_image)
      else
        Log.Warning("UMG_Shop_CollectProgress_C:OnActive packageConf.bg_image is nil")
      end
    end
  end
  local ownedFashionIds, notOwnedFashionIds = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetFashionOwnedBySuitId, SuitID)
  local totalCount = 0
  if ownedFashionIds then
    totalCount = #ownedFashionIds
  end
  if notOwnedFashionIds then
    totalCount = totalCount + #notOwnedFashionIds
  end
  if #notOwnedFashionIds > 0 then
    self.BtnApparel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GorgeousMagic:SwitchToSetBrushFromMaterialInstanceMode(true)
    self.bPlayCollect = false
  else
    self.GorgeousMagic:SwitchToSetBrushFromMaterialInstanceMode(false)
    self.BtnApparel:SetVisibility(UE4.ESlateVisibility.Visible)
    self.bPlayCollect = true
  end
  local Path = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Monthly/Textures/img_xingxing1.img_xingxing1'"
  self.GorgeousMagic:SetPath(Path)
  self.Text_Schedule:SetText(string.format("%d/%d", #ownedFashionIds, totalCount))
  local gridDataList = {}
  for _, fashionId in ipairs(ownedFashionIds) do
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
    if nil ~= fashionConf then
      table.insert(gridDataList, {
        id = fashionId,
        name = fashionConf.name,
        icon = fashionConf.icon,
        type = fashionConf.type,
        collected = true,
        isNewlyAcquired = fashionId == self.BuyItemID
      })
    end
  end
  if notOwnedFashionIds then
    for _, fashionId in ipairs(notOwnedFashionIds) do
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(fashionId)
      if nil ~= fashionConf then
        table.insert(gridDataList, {
          id = fashionId,
          name = fashionConf.name,
          icon = fashionConf.icon,
          type = fashionConf.type,
          collected = false,
          isNewlyAcquired = fashionId == self.BuyItemID
        })
      end
    end
  end
  local typeOrder = {
    [_G.Enum.FashionLabelType.FLT_DRESSES] = 1,
    [_G.Enum.FashionLabelType.FLT_TOPS] = 1,
    [_G.Enum.FashionLabelType.FLT_BOTTOMS] = 2,
    [_G.Enum.FashionLabelType.FLT_RINGS] = 3,
    [_G.Enum.FashionLabelType.FLT_SOCKS] = 4,
    [_G.Enum.FashionLabelType.FLT_SHOES] = 5,
    [_G.Enum.FashionLabelType.FLT_BAGS] = 6,
    [_G.Enum.FashionLabelType.FLT_HATS] = 7
  }
  table.sort(gridDataList, function(a, b)
    local orderA = typeOrder[a.type] or 99
    local orderB = typeOrder[b.type] or 99
    if orderA == orderB then
      return a.id < b.id
    else
      return orderA < orderB
    end
  end)
  self.IconList:InitGridView(gridDataList)
  if self.In then
    self:PlayAnimation(self.In)
    if self.bPlayCollect then
      _G.NRCAudioManager:PlaySound2DAuto(40010013, "UMG_Shop_CollectProgress_C:OnActive collect")
    else
      _G.NRCAudioManager:PlaySound2DAuto(40010014, "UMG_Shop_CollectProgress_C:OnActive not collect")
    end
  end
end

function UMG_Shop_CollectProgress_C:OnDeactive()
  if self.Out then
    _G.NRCAudioManager:PlaySound2DAuto(40010012, "UMG_Shop_CollectProgress_C:OnDeactive out not collect")
    self:PlayAnimation(self.Out)
  end
end

function UMG_Shop_CollectProgress_C:OnAddEventListener()
end

function UMG_Shop_CollectProgress_C:OnClickBtnApparel()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Shop_CollectProgress_C:OnClickBtnApparel")
  if self.suitConf ~= nil then
    local curSelectedIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().current_wardrobe_index
    local salonIds
    local fashionInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo()
    if fashionInfo and fashionInfo.wardrobe_data and fashionInfo.wardrobe_data[curSelectedIndex] and fashionInfo.wardrobe_data[curSelectedIndex].salon_item_wear_id and 0 ~= #fashionInfo.wardrobe_data[curSelectedIndex].salon_item_wear_id then
      salonIds = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().wardrobe_data[curSelectedIndex].salon_item_wear_id
    end
    if not salonIds then
      salonIds = {}
      local curSalonIds = _G.DataModelMgr.PlayerDataModel:GetPlayerSalonInfo().item_wear_data
      if curSalonIds and 0 ~= #curSalonIds then
        for k, v in ipairs(curSalonIds) do
          table.insert(salonIds, v.item_wear_id)
        end
      else
        local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        local gender = 1
        if localPlayer then
          gender = localPlayer.gender
        end
        salonIds = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetAvatarDefaultSalonIdsByGender, gender)
      end
    end
    local fashionIds = {}
    local wandId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetCurSuitWandId)
    for k, v in ipairs(self.suitConf.item_id) do
      table.insert(fashionIds, v)
    end
    table.insert(fashionIds, wandId)
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.BuyAndWearSuitReq, curSelectedIndex, fashionIds, salonIds)
  else
    Log.Error("[UMG_Shop_CollectProgress_C:OnClickBtnApparel] self.suitConf is nil!")
  end
  self:DoClose()
end

function UMG_Shop_CollectProgress_C:OnClickBtnNotarize()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Shop_CollectProgress_C:OnClickBtnNotarize")
  if self:IsAnimationPlaying(self.Out) then
    Log.Info("UMG_Shop_CollectProgress_C:OnClickBtnNotarize Out is playing")
    return
  end
  if self.Out then
    self:PlayAnimation(self.Out)
  end
end

function UMG_Shop_CollectProgress_C:OnAnimationFinished(Anim)
  if Anim == self.In then
    local itemCount = self.IconList:GetItemCount()
    for i = 0, itemCount - 1 do
      local item = self.IconList:GetItemByIndex(i)
      if item and item.OnPlaySticker then
        item:OnPlaySticker(self)
      end
    end
    if self.bPlayCollect then
      self:PlayCollect()
    end
  end
  if Anim == self.Out then
    self:DoClose()
  end
  if Anim == self.Collect then
    self.isCollectPlaying = false
  end
end

function UMG_Shop_CollectProgress_C:OnDestruct()
end

function UMG_Shop_CollectProgress_C:PlayCollect()
  if self.bPlayCollect and not self.isCollectPlaying then
    self.isCollectPlaying = true
    self:PlayAnimation(self.Collect)
  end
end

function UMG_Shop_CollectProgress_C:OnPcClose()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  self:DoClose()
end

return UMG_Shop_CollectProgress_C
