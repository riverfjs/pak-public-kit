local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_VerticalTabBtn_C = Base:Extend("UMG_VerticalTabBtn_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")

function UMG_VerticalTabBtn_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_HorizontalTabBtn_C", self, AppearanceModuleEvent.OnEnterFilterGlassItem, self.OnEnterFilterGlassItem)
end

function UMG_VerticalTabBtn_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, AppearanceModuleEvent.OnEnterFilterGlassItem, self.OnEnterFilterGlassItem)
end

function UMG_VerticalTabBtn_C:OnEnterFilterGlassItem(bEnter)
  self.bEnterFilterGlassItemState = bEnter
  if bEnter then
    if self.uiData.LabelType ~= Enum.FashionLabelType.FLT_CLOTHES then
      self.Unclickable:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:SetClickable(false)
      self.RedDot:SetupKey(0)
      self.RedDot:Refresh()
      self:SetupSpecialRedDot(false)
    else
      self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:SetClickable(true)
      self:SetupRedDot(self.bHasRedDot)
      self:SetupSpecialRedDot(true)
    end
  else
    self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetClickable(true)
    self:SetupRedDot(self.bHasRedDot)
    self:SetupSpecialRedDot(true)
  end
end

function UMG_VerticalTabBtn_C:SetupSpecialRedDot(bSetup)
  if bSetup then
    if self.tabType then
      if self.tabType == Enum.FashionLabelType.FLT_SUIT then
        self.RedDot_1:SetupKey(467)
      elseif self.tabType == Enum.FashionLabelType.FLT_CLOTHES then
        local bClaimable = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CheckPetGlassTintIsClaimableByType)
        if bClaimable then
          self.RedDot_1:SetupKey(460)
        else
          self.RedDot_1:SetupKey(464)
        end
      end
    end
  else
    self.RedDot_1:SetupKey(0)
  end
  self.RedDot_1:Refresh()
  if bSetup then
    if self.RedDot_1:IsRed() then
      self:SetDressPrompt(false)
    else
      self:SetDressPrompt(self.bShowDressPrompt)
    end
  else
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_VerticalTabBtn_C:OnItemUpdate(_data, datalist, index)
  if not _data.data or not _data.parent then
    return
  end
  self:SetupMap()
  self.uiData = _data.data
  self.parent = _data.parent
  self.bHasRedDot = _data.bHasRedDot
  self:HandleDressPrompt(_data.data.bFashion, _data.data.LabelType, _data.parent)
  local iconPath = ""
  if _data.Icon then
    iconPath = _data.Icon
  else
    local tabConf = _G.DataConfigManager:GetClosetTabConf(self.uiData.tabConfId)
    iconPath = tabConf.icon
    self.tabType = tabConf.use_FashionLabelType
  end
  self.Suit_Ordinary:SetPath(iconPath)
  local tabConf = _G.DataConfigManager:GetClosetTabConf(self.uiData.tabConfId)
  if tabConf then
    self.Unclickable:SetPath(tabConf.gray_icon)
  end
  self.Unclickable:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local pathArray = string.split(iconPath, "/")
  local nameArray = string.split(pathArray[#pathArray], "_png")
  local bgName1 = nameArray[1] .. 1
  local bgName2 = nameArray[2] .. 1
  local bgPath = ""
  for i = 1, #pathArray - 1 do
    bgPath = bgPath .. pathArray[i] .. "/"
  end
  local bgPathTable = {
    bgPath,
    bgName1,
    "_png",
    bgName2,
    "_png'"
  }
  bgPath = table.concat(bgPathTable)
  self.Suit_Selected:SetPath(bgPath)
  if self.parent then
    self:OnEnterFilterGlassItem(self.parent.bEnterFilterGlassItemState)
  end
end

function UMG_VerticalTabBtn_C:OnTouchEnded(MyGeometry, InTouchEvent)
  local ret = Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(1303, "UMG_VerticalTabBtn_C:OnTouchEnded")
  return ret
end

function UMG_VerticalTabBtn_C:SetupRedDot(hasDot)
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

function UMG_VerticalTabBtn_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    self:PlayAnimation(self.Btn_Suit_A)
    if self.uiData.Icon then
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.SetFashionVerticalTabEnum, self.uiData.Type)
    else
      _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.ChooseClosetTab, self.uiData.tabConfId, self.uiData)
    end
  else
    self:PlayAnimation(self.Btn_Suit_A_Out)
  end
end

function UMG_VerticalTabBtn_C:OnDeactive()
end

function UMG_VerticalTabBtn_C:SetupMap()
  self.ClothToComponentMap = {}
  self.AccessortToComponentMap = {}
  local closetTabConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.CLOSET_TAB_CONF)
  local closetTabTable = closetTabConf:GetAllDatas()
  for _, conf in pairs(closetTabTable) do
    if not string.IsNilOrEmpty(conf.fathertab) then
      local fathertab = tonumber(conf.fathertab)
      if 3 == fathertab then
        if conf.use_FashionLabelType and conf.use_FashionLabelType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
          table.insert(self.ClothToComponentMap, conf.use_FashionLabelType)
        end
      elseif 9 == fathertab and conf.use_FashionLabelType and conf.use_FashionLabelType ~= _G.Enum.FashionLabelType.FLT_BEGIN then
        table.insert(self.AccessortToComponentMap, conf.use_FashionLabelType)
      end
    end
  end
end

function UMG_VerticalTabBtn_C:SetDressPrompt(bShouldShow)
  if not self.clickable and bShouldShow then
    return
  end
  self.bShowDressPrompt = bShouldShow
  if bShouldShow and not self.RedDot:IsRed() and not self.RedDot_1:IsRed() then
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UpgradePrompt:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_VerticalTabBtn_C:UpdateDressPrompt(bIsChoose)
  if self.uiData.LabelType == _G.Enum.FashionLabelType.FLT_SUIT then
    self:HandleDressPrompt(true, self.uiData.LabelType, self.parent, bIsChoose)
  else
    self:HandleDressPrompt(self.uiData.bFashion, self.uiData.LabelType, self.parent)
  end
end

function UMG_VerticalTabBtn_C:HandleDressPrompt(bFashion, labelType, parent, bIsChoose)
  local bShouldShow = false
  if labelType == _G.Enum.FashionLabelType.FLT_CLOTHES then
    for k, v in ipairs(self.ClothToComponentMap) do
      local itemId = parent.data:GetWearIdByType(bFashion, v)
      local bIsOwned = self:_CheckIsOwnedItem(itemId, bFashion, labelType)
      if 0 ~= itemId and bIsOwned then
        bShouldShow = true
        break
      end
    end
  elseif labelType == _G.Enum.FashionLabelType.FLT_ACCESSORIES then
    for k, v in ipairs(self.AccessortToComponentMap) do
      local itemId = parent.data:GetWearIdByType(bFashion, v)
      local bIsOwned = self:_CheckIsOwnedItem(itemId, bFashion, labelType)
      if 0 ~= itemId and bIsOwned then
        bShouldShow = true
        break
      end
    end
  elseif labelType == _G.Enum.FashionLabelType.FLT_SALON or not bFashion then
  elseif labelType == _G.Enum.FashionLabelType.FLT_SUIT then
    local itemId = parent.data:GetWearIdByType(bFashion, labelType)
    if 0 ~= itemId then
      bShouldShow = true
    end
  elseif labelType == _G.Enum.FashionLabelType.FLT_WAND then
    bShouldShow = true
  else
    local itemId = parent.data:GetWearIdByType(bFashion, labelType)
    if 0 ~= itemId or labelType == _G.Enum.FashionLabelType.FLT_WAND then
      bShouldShow = true
    end
  end
  self:SetDressPrompt(bShouldShow)
end

function UMG_VerticalTabBtn_C:_CheckIsOwnedItem(itemId, bFashion, labelType)
  if not (bFashion and itemId) or 0 == itemId then
    return false
  end
  return self.parent.module:OnCmdCheckHasOwned(_G.Enum.GoodsType.GT_FASHION, itemId)
end

return UMG_VerticalTabBtn_C
