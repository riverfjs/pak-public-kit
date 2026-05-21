local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local AppearanceModuleEvent = require("NewRoco.Modules.System.Appearance.AppearanceModuleEvent")
local UMG_Appearance_SuitItem_C = Base:Extend("UMG_Appearance_SuitItem_C")
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")

function UMG_Appearance_SuitItem_C:Initialize(Initializer)
  self:OnAddEventListener()
end

function UMG_Appearance_SuitItem_C:OnConstruct()
end

function UMG_Appearance_SuitItem_C:OnAddEventListener()
end

function UMG_Appearance_SuitItem_C:RemoveEventListener()
end

function UMG_Appearance_SuitItem_C:OnDestruct()
  self.Btn_Named.OnClicked:Remove(self, self.OnNameBtnClicked)
  self:RemoveEventListener()
end

function UMG_Appearance_SuitItem_C:OnItemUpdate(_data, datalist, index)
  self.Btn_Named.OnClicked:Add(self, self.OnNameBtnClicked)
  self.data = _data
  self.index = index
  self:UpdateItemInfo()
  if self.data and self.data.Clicked == false then
    self:PlayAnimation(self.Rename_In)
  end
end

function UMG_Appearance_SuitItem_C:OnNameBtnClicked()
  local param = {}
  local name = self.Name:GetText()
  table.insert(param, {
    Index = self.index,
    Name = name
  })
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenTips, AppearanceModuleEnum.OpenTipType.FASHION_CHANGENAME, param)
  _G.NRCAudioManager:PlaySound2DAuto(1082, "UMG_Appearance_SuitItem_C:OnNameBtnClicked")
end

function UMG_Appearance_SuitItem_C:UpdateItemInfo()
  if not self.data then
    return
  end
  self.Dazzling:UpdateState(false)
  if (self.data.current_wardrobe_data_index or 0) + 1 ~= self.index and not self.bIsSelected then
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not string.IsNilOrEmpty(self.data.fashion_data.name) then
    self.Name:SetText(self.data.fashion_data.name)
  else
    self.Name:SetText(LuaText.umg_appearance_suititem_1 .. self.index)
  end
  local fashionIds = self.data.fashion_data.wearing_item or {}
  local bHasData = self.data.fashion_data.wearing_item ~= nil or nil ~= self.data.fashion_data.salon_item_wear_id
  if bHasData then
    self.dressIconPath = AppearanceUtils.GetWardrobeIconPath(self.data.fashion_data.wearing_item)
    self.isGlassItem, self.dressGlassInfo = AppearanceUtils.GetWardrobeGlassInfo(self.data.fashion_data.wearing_item)
    if not self.dressIconPath then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if 1 == player.gender then
        self.dressIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/10700001.10700001'"
      else
        self.dressIconPath = "Texture2D'/Game/NewRoco/Modules/System/Appearance/Raw/Icon/20700001.20700001'"
      end
    end
    self.Dazzling:UpdateState(self.isGlassItem, self.dressGlassInfo)
    self:SetIcon(true, self.dressIconPath)
  else
    self:SetIcon(false, nil)
  end
  if self.data.bLobbyMain then
    self.Btn_Named:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Named:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Appearance_SuitItem_C:SetIcon(bVisible, path)
  if bVisible then
    self.icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.icon:SetPath(path)
  else
    self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Appearance_SuitItem_C:OnItemClicked(bClicked)
  if bClicked then
    if self.data and self.data.parent._firstOpenSuitList then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnWardrobeIndexChanged, self.index, self.data.bLobbyMain)
    end
    local canChange = _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.CanChangeSuitWardrobeIndex)
    if canChange then
      self:SetSelectable(true)
    else
      self:SetSelectable(false)
    end
  end
end

function UMG_Appearance_SuitItem_C:OnItemSelected(_bSelected)
  self.bIsSelected = _bSelected
  if _bSelected then
    self:OnItemClicked(_bSelected)
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFC65FFF"))
    self:PlayAnimation(self.Rename_In)
    if self.data and self.data.IsPlaySound then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Appearance_SuitItem_C:OnItemSelected")
    end
    if self.data then
      self.data.parent:UpdateSuitBtnIconOnSelection(self.dressIconPath)
    end
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.ClearFashionItemSelection)
  else
    self:StopAllAnimations()
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Rename_Out)
    self.Bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("1E1F21FF"))
  end
end

function UMG_Appearance_SuitItem_C:SetPlaySoundState(_IsPlaySound)
  if self.data then
    self.data.IsPlaySound = _IsPlaySound
  end
end

function UMG_Appearance_SuitItem_C:OnDeactive()
end

function UMG_Appearance_SuitItem_C:OnAnimationFinished(anim)
  if anim == self.Rename_Out then
  end
  if anim == self.Rename_In and self.bIsSelected then
    self:PlayAnimation(self.Selected_loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
end

return UMG_Appearance_SuitItem_C
