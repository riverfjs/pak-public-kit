local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_FurnitureAtlasItem_C = Base:Extend("UMG_FurnitureList_C")

function UMG_FurnitureAtlasItem_C:OnConstruct()
  self.bSelected = false
  self.bNeedNormal = true
end

function UMG_FurnitureAtlasItem_C:OnDestruct()
end

function UMG_FurnitureAtlasItem_C:OnItemUpdate(_data, datalist, index)
  self.itemData = _data
  self.parent = _data.parent
  self.index = index
  local furnitureHandbookConf = _G.DataConfigManager:GetFurnitureHandbookConf(self.itemData.id)
  if not furnitureHandbookConf then
    Log.ErrorFormat("\228\184\186\228\187\128\228\185\136\230\178\161\230\156\137FurnitureHandbookConf%d\231\154\132\233\133\141\231\189\174", self.itemData.id)
    return
  end
  local furniture_id = furnitureHandbookConf.furniture_id
  local furnitureItemConf = _G.DataConfigManager:GetFurnitureItemConf(furniture_id)
  if furnitureItemConf then
    self.Icon:SetPath(furnitureItemConf.icon)
    self.Title:SetText(furnitureItemConf.name)
  else
    Log.Error("\230\137\190\228\184\141\229\136\176\229\174\182\229\133\183\239\188\140\230\163\128\230\159\165\233\133\141\231\189\174")
  end
  if 1 == self.itemData.reward_status then
    self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.LockIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LockIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.bNeedNormal then
    self:PlayAnimation(self.normal)
    self.bNeedNormal = false
    self.bSelected = false
  end
  self.RedDot:SetupKey(344, _data.id)
  local BagItemConf = DataConfigManager:GetBagItemConf(furniture_id)
  local Quality = (BagItemConf or {}).item_quality
  local Color = HomeIndoorSandbox.Enum.GetItemQualityColor(Quality)
  self.QualityColor:SetColorAndOpacity(Color)
  local ColorBgPath = HomeIndoorSandbox.Enum.GetItemQualityBgImgPath(Quality)
  self.Selected:SetPath(ColorBgPath)
end

function UMG_FurnitureAtlasItem_C:OnDespawn()
  if self._parent and self._parent._selectedItemIndex == self.index then
    self.bNeedNormal = true
  end
end

function UMG_FurnitureAtlasItem_C:OnItemSelected(_bSelected, bScrolled)
  if _bSelected and not bScrolled then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401006, "UMG_FurnitureAtlasItem_C:OnItemSelected")
  end
  local previousSelected = self.bSelected
  self.bSelected = _bSelected
  if _bSelected then
    if bScrolled then
      self:StopAnimation(self.normal)
      self:PlayAnimation(self.change, self.change:GetEndTime() - 0.05)
    else
      self:StopAnimation(self.normal)
      self:PlayAnimation(self.change)
      if previousSelected ~= self.bSelected then
        self:InvokeParentFunc("OnItemSelected")
      end
    end
  else
    self:StopAnimation(self.change)
    self:PlayAnimation(self.normal)
  end
end

function UMG_FurnitureAtlasItem_C:OnDeactive()
end

function UMG_FurnitureAtlasItem_C:InvokeParentFunc(_funcName, ...)
  if not _funcName then
    return
  end
  if UE4.UObject.IsValid(self.parent) and self.parent[_funcName] then
    self.parent[_funcName](self.parent, self)
  end
end

return UMG_FurnitureAtlasItem_C
