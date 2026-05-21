local Base = require("NewRoco.Modules.System.Friend.Res.BusinessCard.UMG_StudentCard_DragableItem_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_StudentCard_Comp_Item_C = Base:Extend("UMG_StudentCard_Comp_Item_C")

function UMG_StudentCard_Comp_Item_C:OnConstruct()
end

function UMG_StudentCard_Comp_Item_C:OnDestruct()
end

function UMG_StudentCard_Comp_Item_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.module = _G.NRCModuleManager:GetModule("FriendModule")
  self.moduleData = self.module:GetData("FriendModuleData")
  if self.data.ComponentType == _G.ProtoEnum.RoleCardModuleType.RCMT_FAVOURITE_PET then
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
    self:InitPetInfo()
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    self:InitBadgeInfo()
  end
end

function UMG_StudentCard_Comp_Item_C:InitPetInfo()
  if self.Name then
    self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.move then
    self.move:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetSelectedState(false)
  if self.data.petInfo and 0 ~= self.data.petInfo.pet_base_id then
    self.Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.IconBg:SetVisibility(UE4.ESlateVisibility.Visible)
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.petInfo.pet_base_id)
    local typeDic = _G.DataConfigManager:GetTypeDictionary(self.data.petInfo.skill_dam_type)
    if typeDic then
      self.IconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(typeDic.rolecard_favorite_pets_colour))
    end
    if PetBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(PetBaseConf.model_conf)
      if modelConf then
        local mutation_type = self.data.petInfo.mutation_diff_type
        if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
          self.Pet:SetPath(modelConf.shiny_icon)
        else
          self.Pet:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
        end
      end
    end
  end
end

function UMG_StudentCard_Comp_Item_C:InitBadgeInfo()
  local fashionData = self.data
  if not (fashionData and fashionData.fashionInfo and fashionData.fashionInfo.fashion_bond_id) or fashionData.fashionInfo.fashion_bond_id <= 0 then
    return
  end
  local bondConf = _G.DataConfigManager:GetFashionBondConf(fashionData.fashionInfo.fashion_bond_id)
  if not bondConf then
    return
  end
  self.Icon_1:SetPath(bondConf.fashion_bond_big_icon)
  UIUtils.SafeSetVisibility(self.Icon_1, UE4.ESlateVisibility.Visible)
  UIUtils.SafeSetVisibility(self.move_1, UE4.ESlateVisibility.Collapsed)
end

function UMG_StudentCard_Comp_Item_C:OnItemSelected(_bSelected)
  self.detectDragStartMs = 0
  if not _bSelected then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_StudentCard_Comp_Item_C:OnItemSelected")
  local validIndex, pageIndex = self.moduleData:GetNextEmptyIndexForCurEditComponent(self.data.ComponentType)
  if not validIndex then
    Log.Error("UMG_StudentCard_Comp_Item_C:OnItemSelected() validIndex is nil")
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.rolecard_module_full)
    return
  end
  self.moduleData:AddOrReplaceCurEditCardInfo(validIndex, self.data)
  self.module:DispatchEvent(FriendModuleEvent.UpdateCardComponentEdit, pageIndex)
end

function UMG_StudentCard_Comp_Item_C:ThresholdMilliTimeForDragStart()
  return 100
end

function UMG_StudentCard_Comp_Item_C:GetDragWidgetInitParam()
  return self.data
end

function UMG_StudentCard_Comp_Item_C:HandleDragStart(MyGeometry, PointerEvent, BP_CardDragDropOperation_C)
  Log.Debug("UMG_StudentCard_Comp_Item_C:HandleDragStart", BP_CardDragDropOperation_C.WidgetRef.className)
  self:SetSelectedState(true)
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_StudentCard_Comp_Item_C:HandleDragStart")
end

function UMG_StudentCard_Comp_Item_C:HandleDrop(MyGeometry, PointerEvent, Operation)
  if not Operation or not Operation.WidgetRef then
    Log.Debug("UMG_StudentCard_Comp_Item_C:HandleDragLeave", "Operation or Operation.WidgetRef is nil")
    return
  end
  Log.Debug("UMG_StudentCard_Comp_Item_C:HandleDragLeave")
  if Operation.WidgetRef.className == "UMG_StudentCard_Comp_Item_C" then
    local compItem = Operation.WidgetRef
    compItem:OnCustomDragFinished()
  elseif Operation.WidgetRef.className == "UMG_StudentCard_Item_C" then
    self.module:DispatchEvent(FriendModuleEvent.UpdateCardComponentEdit)
  end
end

function UMG_StudentCard_Comp_Item_C:HandleDragCancelled(PointerEvent, Operation)
  self:OnCustomDragFinished()
end

function UMG_StudentCard_Comp_Item_C:SetSelectedState(isSelected)
  if isSelected then
    UIUtils.SafeSetVisibility(self.Selected, UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Select)
  else
    UIUtils.SafeSetVisibility(self.Selected, UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Normal)
  end
end

function UMG_StudentCard_Comp_Item_C:OnCustomDragFinished()
  self:SetSelectedState(false)
end

function UMG_StudentCard_Comp_Item_C:OnDeactive()
end

function UMG_StudentCard_Comp_Item_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnCancelOrClose
  CommonPopUpData.Btn_RightHandler = self.OnOK
  CommonPopUpData.ClosePanelHandler = self.CloseBtnClick
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

return UMG_StudentCard_Comp_Item_C
