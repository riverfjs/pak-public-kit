local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetFoodTemple_C = Base:Extend("UMG_PetFoodTemple_C")

function UMG_PetFoodTemple_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data
  self.index = index
  self.Parent = nil
  self.IsSelect = false
  self.IsUseExpSucceed = false
  self.asset = nil
  self.Count = 0
  self.IsOnClick = false
  self.IsPlayFruit = false
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 750
  _G.UpdateManager:UnRegister(self)
  self:PlayAnimation(self.In)
  self:UpdateItemInfo()
  self:OnAddEventListener()
end

function UMG_PetFoodTemple_C:OnDestruct()
  if self.request then
    NRCResourceManager:UnLoadRes(self.request)
    self.request = nil
  end
end

function UMG_PetFoodTemple_C:OnAddEventListener()
  self.btnDelItem.OnClicked:Add(self, self.OnClickDelItem)
  self.btnDelItem.OnPressed:Add(self, self.OnBtnDelItemPressed)
  self.btnDelItem.OnReleased:Add(self, self.OnBtnDelItemReleased)
end

function UMG_PetFoodTemple_C:OnClickDelItem()
  _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_PetFoodTemple_C:OnBtnDelItemClick")
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.FoodClickAddOrDelItem, false, self.uiData, PetUIModuleEnum.AddAutomaticallyType.NuLL)
end

function UMG_PetFoodTemple_C:OnBtnDelItemPressed()
  self:StopAnimation(self.Del_press)
  self:StopAnimation(self.Del_up)
  self:PlayAnimation(self.Del_press)
end

function UMG_PetFoodTemple_C:OnBtnDelItemReleased()
  self:StopAnimation(self.Del_press)
  self:StopAnimation(self.Del_up)
  self:PlayAnimation(self.Del_up)
end

function UMG_PetFoodTemple_C:AddAutomatically(IsAddAutomaticallyType, AddAutomaticallyType, num)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.FoodClickAddOrDelItem, IsAddAutomaticallyType, self.uiData, AddAutomaticallyType, num)
end

function UMG_PetFoodTemple_C:AddOrDelItem(UseCount)
  if UseCount > 0 then
    self:SetSelected(true)
    self.IsSelect = true
  end
  self:SetItemNum(UseCount)
end

function UMG_PetFoodTemple_C:SetItemNum(_Count)
  if _Count then
    self.Count = _Count
  end
  local SumCount = self.uiData.Item and self.uiData.Item.num or 0
  self.itemUseCount:SetText(string.format("%d/%d", self.Count, SumCount))
  if self.Count <= 0 then
    self.btnDelItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.uiData.Item and self.uiData.Item.num > 0 and not self:IsAnimationPlaying(self.Eat) and not self:IsAnimationPlaying(self.NewFruit) and not self:IsAnimationPlaying(self.NewFruitNell) then
      self:StopAllAnimations()
      self:PlayAnimation(self.Cancel)
    end
    self.IsSelect = false
  else
    self.btnDelItem:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetFoodTemple_C:GetBagItemCount()
  return self.Count
end

function UMG_PetFoodTemple_C:SetAddBtnState(_IsEnabled)
end

function UMG_PetFoodTemple_C:OnTouchStarted(MyGeometry, InTouchEvent)
  self.IsOnClick = true
  _G.UpdateManager:Register(self)
  Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
  return UE.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetFoodTemple_C:OnMouseLeave(MyGeometry, MouseEvent)
  self:LongPressBreak()
end

function UMG_PetFoodTemple_C:OnTick(InDeltaTime)
  if self.IsOnClick then
    if self.StartPressTime == nil then
      self.StartPressTime = 0
    end
    self.StartPressTime = self.StartPressTime + InDeltaTime
  end
  if self.StartPressTime and self.LongPressTime and self.StartPressTime >= self.LongPressTime then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.uiData.itemConf.id, _G.Enum.GoodsType.GT_BAGITEM, false)
    self:LongPressBreak()
  end
end

function UMG_PetFoodTemple_C:LongPressBreak()
  self.IsOnClick = false
  self.StartPressTime = 0
  _G.UpdateManager:UnRegister(self)
end

function UMG_PetFoodTemple_C:SetData(_data)
  self.uiData.num = _data.num
  self.uiData.Item.num = _data.num
  if 0 == _data.num then
    self.uiData.IsHasNum = false
  end
  self.IsUseExpSucceed = true
  self:SetItemNum(0)
end

function UMG_PetFoodTemple_C:SetParent(Parent, asset)
  self.Parent = Parent
  self.asset = asset
  self:SetIconPath()
end

function UMG_PetFoodTemple_C:UpdateItemInfo()
  self:SetUseActionIcon()
  self:SetItemNum()
  if self.uiData.itemConf.effect_description then
  end
end

function UMG_PetFoodTemple_C:SetIconPath(_IsOperation)
  local IconInfo
  if self.uiData.IsHasNum then
    IconInfo = self.uiData.itemConf.icon
    self.Icon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.itemIcon_xiangao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.asset then
      self:SetModelAnimation(self.asset)
    end
  else
    if self.uiData.itemConf.outline_icon then
      IconInfo = self.uiData.itemConf.outline_icon
    else
      IconInfo = self.uiData.itemConf.icon
    end
    if not _IsOperation then
      self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.itemIcon_xiangao:SetPath(IconInfo)
  end
end

function UMG_PetFoodTemple_C:SetUseActionIcon()
  local BagItemConf = self.uiData.itemConf
  if BagItemConf.item_behavior then
    for i, item in ipairs(BagItemConf.item_behavior) do
      local UseAction = item.use_action
      if UseAction == Enum.ItemBehavior.IB_GET_VITEM then
        local ratio = item.ratio[1]
      end
    end
  end
end

function UMG_PetFoodTemple_C:OnBtnAddItemClick()
  if self.uiData.num <= 0 then
    _G.NRCAudioManager:PlaySound2DAuto(41401013, "UMG_PetFoodTemple_C:OnBtnAddItemClick")
    self:StopAllAnimations()
    self:PlayAnimation(self.Empty_2)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_PetFoodTemple_C:OnBtnAddItemClick")
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.FoodClickAddOrDelItem, true)
end

function UMG_PetFoodTemple_C:OnBtnDelItemClick()
  if self.uiData.num <= 0 then
    _G.NRCAudioManager:PlaySound2DAuto(41401013, "UMG_PetFoodTemple_C:OnBtnAddItemClick")
    self:StopAllAnimations()
    self:PlayAnimation(self.Empty_2)
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_PetFoodTemple_C:OnBtnDelItemClick")
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.FoodClickAddOrDelItem, false)
end

function UMG_PetFoodTemple_C:OnClickBtn()
  if self.IsSelect and not self.IsUseExpSucceed then
    self:OnBtnItemIconClick()
  else
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.SelectPetFood, self.index)
  end
end

function UMG_PetFoodTemple_C:OnBtnItemIconClick()
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, self.uiData.itemConf.id, _G.Enum.GoodsType.GT_BAGITEM)
end

function UMG_PetFoodTemple_C:SetSelected(_bSelected)
  if _bSelected and self.uiData.IsHasNum then
    if not self.IsSelect then
      self:StopAllAnimations()
      self:PlayAnimation(self.Select)
    else
      if not self:IsAnimationPlaying(self.Add_press) and not self:IsAnimationPlaying(self.Add_up) and not self:IsAnimationPlaying(self.Del_press) and not self:IsAnimationPlaying(self.Del_up) then
        self:StopAllAnimations()
        self:PlayAnimation(self.Add_press)
      else
      end
    end
  end
end

function UMG_PetFoodTemple_C:OnItemSelected(_bSelected)
  if _bSelected then
    if self:IsAnimationPlaying(self.Eat) or self:IsAnimationPlaying(self.NewFruit) or self:IsAnimationPlaying(self.NewFruitNell) then
      return
    end
    if self.uiData.IsHasNum then
      _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_PetFoodTemple_C:OnItemSelected")
      _G.NRCModeManager:DoCmd(PetUIModuleCmd.FoodClickAddOrDelItem, true, self.uiData, PetUIModuleEnum.AddAutomaticallyType.NuLL)
    else
      _G.NRCAudioManager:PlaySound2DAuto(41401013, "UMG_PetFoodTemple_C:OnBtnAddItemClick")
      self:StopAllAnimations()
      self:PlayAnimation(self.Empty_2)
    end
  else
    self.IsSelect = false
  end
  self:LongPressBreak()
end

function UMG_PetFoodTemple_C:PlayEatAnima()
  if not self:IsAnimationPlaying(self.Eat) then
    _G.NRCAudioManager:PlaySound2DAuto(40002012, "UMG_PetFoodTemple_C:OnItemSelected")
    self:StopAllAnimations()
    self:PlayAnimation(self.Eat)
    self.Count = 0
  end
end

function UMG_PetFoodTemple_C:GetEatTime()
  return self.Eat:GetEndTime() - self.Eat:GetStartTime() + (self.Cancel:GetEndTime() - self.Cancel:GetStartTime())
end

function UMG_PetFoodTemple_C:OnAnimationFinished(Animation)
  if Animation == self.Eat then
    self.IsPlayFruit = true
    self:StopAllAnimations()
    self:PlayAnimation(self.Cancel)
    if self.uiData.IsHasNum then
      self:PlayAnimation(self.NewFruit)
    else
      self.itemIcon_xiangao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.NewFruitNell)
    end
  elseif Animation == self.Select then
  elseif Animation == self.Add_press then
    self:PlayAnimation(self.Add_up)
  elseif Animation == self.Add_loop then
    self:PlayAnimation(self.Eat)
  elseif Animation == self.Cancel then
  end
end

return UMG_PetFoodTemple_C
