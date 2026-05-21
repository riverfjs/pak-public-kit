local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local UMG_ComboBox_item_C = Base:Extend("UMG_ComboBox_item_C")

function UMG_ComboBox_item_C:OnConstruct()
end

function UMG_ComboBox_item_C:OnDestruct()
end

function UMG_ComboBox_item_C:OnItemUpdate(_data, datalist, index)
  self.datalist = datalist
  self.uiData = _data
  self.uiIndex = index
  self.Text_PlaceName:SetText(_data.name)
  if _data.isHideRedDot then
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif not self.uiData.ComType or self.uiData.ComType == CommonBtnEnum.ComboBoxType.BigMap then
    self.RedDot:SetupKey(243, {
      self.uiData.mapRedDotExtraKey
    })
  elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.MagicManual then
    self.RedDot:SetupKey(166, {
      self.uiData.RegionId
    })
    self.CompletionProgress:SetState(self.uiData.state)
  elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.PetFeeding then
    self.sequence_default = _data.sequence_default or ""
    self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.uiData.redDotKey and self.uiData.redDotKey > 0 then
    self.RedDot:SetupKey(self.uiData.redDotKey, self.uiData.redDotExtraKey)
  end
  self:InitInfo()
end

function UMG_ComboBox_item_C:InitInfo()
  if not self.uiData.isNotChangColor and self.uiData.ComType ~= CommonBtnEnum.ComboBoxType.MagicManual and self.normalTextColor then
    self.Text_PlaceName:SetColorAndOpacity(self.normalTextColor)
  end
  if self.uiData.text_color then
    self.Text_PlaceName:SetColorAndOpacity(self.uiData.text_color)
  end
end

function UMG_ComboBox_item_C:OnItemSelected(_bSelected)
  if not self.uiData then
    Log.Error("UMG_ComboBox_item_C uiData is nil")
    return
  end
  if _bSelected then
    if not self.uiData.ComType or self.uiData.ComType == CommonBtnEnum.ComboBoxType.BigMap then
      if BigMapModuleCmd then
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.ChangeSelectedScene, self.uiData.sceneResId)
        self.RedDot:EraseRedPoint()
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.MagicManual then
      if MagicManualModuleCmd then
        _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.SetSelectMagicManualRegion, self.uiData.RegionId)
        self:PlayAnimation(self.select)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.PetShare then
      _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.OnShareComboBoxSelectChanged, self.uiIndex, self.datalist)
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ResetRightPanelDescText)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.PetFeeding then
      _G.NRCEventCenter:DispatchEvent(HomeModuleEvent.OnSelectLivePetFilter, self.uiIndex, self.sequence_default or "")
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.FriendVisits then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SendZoneSetVisitPermissionSettingReq, self.uiData.Type)
      self:PlayAnimation(self.select)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.Bag then
      if self.uiData.sortList then
        local item = self.uiData.sortList[self.uiIndex]
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateSort, self.uiIndex, item.data)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.SwapEggs then
      if self.uiData.sortList then
        local item = self.uiData.sortList[self.uiIndex]
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateSort, self.uiIndex, item.data)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.RelationEggs then
      if self.uiData.sortList then
        local item = self.uiData.sortList[self.uiIndex]
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateSort, self.uiIndex, item.data)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.Handbook then
      if self.uiData.sortList then
        local item = self.uiData.sortList[self.uiIndex]
        _G.NRCEventCenter:DispatchEvent(BagModuleEvent.UpdateSort, self.uiIndex, item.data)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.FurnitureCreation then
      HomeIndoorSandbox.Module:DispatchEvent(HomeIndoorSandbox.Event.OnFurnitureCreateSortTitleSelected, self.uiIndex, self.datalist)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.StudentCardMenu then
      _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnCardMenuSelect, self.uiIndex, self.datalist)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.StudentCardPlayerOperation then
      _G.NRCEventCenter:DispatchEvent(FriendModuleEvent.OnCardPlayerOperationSelect, self.uiData.SubType)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.HomePlantGuard then
      _G.NRCEventCenter:DispatchEvent(HomeModuleEvent.OnSelectGuardPetFilter, self.uiIndex, self.sequence_default or "")
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.HomeFurniture then
      _G.NRCEventCenter:DispatchEvent(HomeModuleEvent.OnComboBoxSelectChanged, self.uiIndex)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.GorgeousMedal then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OnGorgeousMedalSortChange, self.uiIndex)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.ShowMagicMessage then
      self:PlayAnimation(self.select)
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.CertificationActivity then
      _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnSelectCertificationPetSort, self.uiIndex - 1)
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType ~= CommonBtnEnum.ComboBoxType.MagicManual then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC65FFF"))
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType == CommonBtnEnum.ComboBoxType.FurnitureCreation then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("DC9827FF"))
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType == CommonBtnEnum.ComboBoxType.GorgeousMedal then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("DC9827FF"))
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType == CommonBtnEnum.ComboBoxType.Bag then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827"))
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType == CommonBtnEnum.ComboBoxType.Handbook then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827"))
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType == CommonBtnEnum.ComboBoxType.HomeFurniture then
      self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827"))
    end
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.OnComboBoxSelectChanged, self.uiIndex, self.datalist)
    if self.uiData.OnSelectDelegate then
      self.uiData.OnSelectDelegate(self.uiData)
    end
  else
    if self.uiData.text_color then
      self.Text_PlaceName:SetColorAndOpacity(self.uiData.text_color)
    end
    if not self.uiData.isNotChangColor and self.uiData.ComType ~= CommonBtnEnum.ComboBoxType.MagicManual then
      if self.normalTextColor then
        self.Text_PlaceName:SetColorAndOpacity(self.normalTextColor)
      end
    elseif self.uiData.ComType == CommonBtnEnum.ComboBoxType.MagicManual or self.uiData.ComType == CommonBtnEnum.ComboBoxType.FriendVisits or self.uiData.ComType == CommonBtnEnum.ComboBoxType.ShowMagicMessage then
      self:PlayAnimationReverse(self.select)
    end
  end
end

function UMG_ComboBox_item_C:OnItemSelectedTextChange(bIsSelected)
  if bIsSelected then
    self.Text_PlaceName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827"))
  elseif self.normalTextColor then
    self.Text_PlaceName:SetColorAndOpacity(self.normalTextColor)
  end
end

function UMG_ComboBox_item_C:OnDeactive()
end

return UMG_ComboBox_item_C
