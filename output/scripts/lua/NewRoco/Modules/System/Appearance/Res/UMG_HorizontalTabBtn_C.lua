local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_HorizontalTabBtn_C = Base:Extend("UMG_HorizontalTabBtn_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")

function UMG_HorizontalTabBtn_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_HorizontalTabBtn_C", self, AppearanceModuleEvent.OnEnterFilterGlassItem, self.OnEnterFilterGlassItem)
end

function UMG_HorizontalTabBtn_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnEnterFilterGlassItem, self.OnEnterFilterGlassItem)
end

function UMG_HorizontalTabBtn_C:OnEnterFilterGlassItem(bEnter)
  self.bEnterFilterGlassItemState = bEnter
  if bEnter then
    local canShow = false
    if self.uiData and self.uiData.LabelType and (self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_DRESSES or self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_TOPS or self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_HATS) then
      canShow = true
    end
    if not canShow then
      self:SetClickable(false)
      self.Unclickable:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.RedDot:SetupKey(0)
      self.RedDot:Refresh()
      self:SetupSpecialRedDot(false)
    else
      self:SetClickable(true)
      self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetupSpecialRedDot(true)
    end
  else
    self:SetClickable(true)
    self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetupRedDot(self.bHasRedDot)
    self:SetupSpecialRedDot(true)
  end
end

function UMG_HorizontalTabBtn_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data.data
  self.parent = _data.parent
  self.uiData.index = index
  self.bHasRedDot = _data.bHasRedDot
  self.RedDot:SetupKey(0)
  self.RedDot_1:SetupKey(0)
  local iconPath = ""
  if _data.data.Icon then
    iconPath = _data.Icon
  else
    local tabConf = _G.DataConfigManager:GetClosetTabConf(_data.data.tabConfId)
    iconPath = tabConf.icon
  end
  self.Tire_Ordinary:SetPath(iconPath)
  self.Tire_Selected:SetPath(iconPath)
  self.Unclickable:SetPath(iconPath)
  self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:HandleDressPrompt(_data.data.bFashion, _data.data.LabelType, _data.parent)
  if self.parent and self.uiData.bFashion then
    self:OnEnterFilterGlassItem(self.parent.bEnterFilterGlassItemState)
  end
end

function UMG_HorizontalTabBtn_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local ret = Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(1303, "UMG_HorizontalTabBtn_C:OnTouchEnded")
  return ret
end

function UMG_HorizontalTabBtn_C:SetupRedDot(hasDot)
  if not self.clickable and hasDot then
    return
  end
  self.bHasRedDot = hasDot
  if hasDot then
    self.RedDot:SetupKey(406)
  else
    self.RedDot:SetupKey(0)
  end
  self.RedDot:Refresh()
  self:SetDressPrompt(self.bShowDressPrompt)
end

function UMG_HorizontalTabBtn_C:SetupSpecialRedDot(bSetUp)
  if not self.uiData.bFashion then
    return
  end
  if bSetUp then
    local bClaimable = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckPetGlassTintIsClaimableByType, self.uiData.LabelType)
    if self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_DRESSES or self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_TOPS or self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_HATS then
      local glassItemList = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.GetGlassItemListByType, self.uiData.LabelType)
      if bClaimable then
        self.RedDot_1:SetupKey(460, nil, glassItemList)
      elseif glassItemList and #glassItemList > 0 then
        self.RedDot_1:SetupKey(464, nil, glassItemList)
      end
    end
  else
    self.RedDot_1:SetupKey(0)
  end
  self.RedDot_1:Refresh()
  if bSetUp then
    if self.RedDot_1:IsRed() then
      self:SetDressPrompt(false)
    else
      self:SetDressPrompt(self.bShowDressPrompt)
    end
  else
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HorizontalTabBtn_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.Btn_Hats_A)
    if self.uiData then
      if self.uiData.Icon then
        _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.SetFashionCrossTabEnum, self.uiData.Type)
      else
        _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.ChooseClosetSubTab, self.uiData.tabConfId, self.uiData)
      end
    end
  else
    self:PlayAnimation(self.Btn_Hats_Out)
  end
end

function UMG_HorizontalTabBtn_C:OnDeactive()
end

function UMG_HorizontalTabBtn_C:SetDressPrompt(bShouldShow)
  if not self.clickable and bShouldShow then
    return
  end
  self.bShowDressPrompt = bShouldShow
  if bShouldShow and self.uiData.bFashion and not self.RedDot:IsRed() and not self.RedDot_1:IsRed() then
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HorizontalTabBtn_C:UpdateDressPrompt()
  if self.uiData then
    self:HandleDressPrompt(self.uiData.bFashion, self.uiData.LabelType, self.parent)
  end
end

function UMG_HorizontalTabBtn_C:HandleDressPrompt(bFashion, labelType, parent)
  local itemId = parent.data:GetWearIdByType(bFashion, labelType)
  local bIsOwned = self:_CheckIsOwnedItem(itemId, bFashion, labelType, parent)
  local bShouldShow = 0 ~= itemId and bIsOwned
  self:SetDressPrompt(bShouldShow)
end

function UMG_HorizontalTabBtn_C:_CheckIsOwnedItem(itemId, bFashion, labelType, parent)
  if not (bFashion and itemId) or 0 == itemId then
    return false
  end
  return parent.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, itemId)
end

return UMG_HorizontalTabBtn_C
