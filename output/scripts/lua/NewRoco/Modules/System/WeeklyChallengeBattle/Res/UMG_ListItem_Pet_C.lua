local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")
local UMG_ListItem_Pet_C = Base:Extend("UMG_ListItem_Pet_C")
UMG_ListItem_Pet_C.OpType = {
  EnterSwapMode = 0,
  QuitSwapMode = 1,
  EnterEditMode = 2,
  QuitEditMode = 3,
  HasValidData = 4,
  IsSamePetGid = 5,
  SetCanPlayOutAnim = 6,
  ReInit = 7,
  UpdateDataAndReInit = 8
}

function UMG_ListItem_Pet_C:OnDestruct()
end

function UMG_ListItem_Pet_C:OnItemUpdate(_data, datalist, index)
  self.uiData = _data.petData
  self.bIsWarehouse = _data.bIsWarehouse
  self.parent = _data.parent
  self.bCanPlayOut = true
  self.index = index
  self._cachedTeamSlotIndex = 0
  if self.parent and self.parent.IsTeamEditing and self.parent:IsTeamEditing() and self.uiData and self.uiData.gid and 0 ~= self.uiData.gid and self.parent.GetEditModeTeamSlotIndexByGid then
    self._cachedTeamSlotIndex = self.parent:GetEditModeTeamSlotIndexByGid(self.uiData.gid) or 0
  end
  if not self.parent then
    Log.Error("UMG_ListItem_Pet_C:OnItemUpdate \229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\140parent\230\149\176\230\141\174\228\184\186\231\169\186\239\188\140\232\191\153\228\184\141\230\173\163\229\184\184")
  end
  self:ResetItem()
  self:_InitItem()
end

function UMG_ListItem_Pet_C:OnItemSelected(_bSelected, bScrolled)
  if _bSelected and not bScrolled then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_ListItem_Pet_C:_HandleTeamListItemSelection")
  end
  self:StopAllAnimations()
  if self.bIsWarehouse and bScrolled then
    if _bSelected then
      self:PlayAnimation(self.In)
      if self.parent:IsTeamEditing() then
        self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      local showIndex = self._cachedTeamSlotIndex or 0
      if showIndex <= 0 and self.parent and self.parent.GetEditModeTeamSlotIndexByGid and self.uiData and self.uiData.gid and 0 ~= self.uiData.gid then
        showIndex = self.parent:GetEditModeTeamSlotIndexByGid(self.uiData.gid) or 0
        self._cachedTeamSlotIndex = showIndex
      end
      self.Text_number:SetText(showIndex)
    else
      self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    return
  end
  if self.bIsWarehouse then
    self:_HandleWarehouseItemSelection(_bSelected, bScrolled)
  else
    self:_HandleTeamListItemSelection(_bSelected, bScrolled)
  end
end

function UMG_ListItem_Pet_C:_HandleWarehouseItemSelection(_bSelected, bScrolled)
  if not self.parent then
    Log.Error("UMG_ListItem_Pet_C:_HandleWarehouseItemSelection parent is nil, skip handling selection")
    return
  end
  if _bSelected then
    if self.parent:IsTeamEditing() then
      self:PlayAnimation(self.In)
      local index = self.parent:OnEditModeSelect(self.uiData)
      self._cachedTeamSlotIndex = index
      if index < 1 or index > 6 then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(_G.LuaText.umg_pet_teamreplace_7, 6))
        self.parent:DeselectWarehousePetByGid(self.uiData and self.uiData.gid or 0)
        return
      end
      self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_number:SetText(index)
      self.parent:UpdatePetDetailPanel(self.uiData, self.bIsWarehouse, index)
      self:_HideCollectCanvas()
    elseif self.parent:IsTeamSwapping() then
      self.parent:QuitSwapMode(true)
      self:PlayAnimation(self.In)
      self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.parent:UpdatePetDetailPanel(self.uiData, self.bIsWarehouse, self.index)
    else
      self:PlayAnimation(self.In)
      self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.parent:UpdatePetDetailPanel(self.uiData, self.bIsWarehouse, self.index)
    end
  else
    self._cachedTeamSlotIndex = 0
    if not bScrolled then
      self:PlayAnimation(self.out)
    end
    self:_TryShowCollectCanvas()
    if self.parent:IsTeamEditing() then
      self.parent:OnEditModeDeselect(self.uiData.gid)
    end
  end
end

function UMG_ListItem_Pet_C:_HandleTeamListItemSelection(_bSelected)
  if not self.parent then
    Log.Error("UMG_ListItem_Pet_C:_HandleTeamListItemSelection parent is nil, skip handling selection")
    return
  end
  if _bSelected then
    if self.parent:IsTeamEditing() then
      self:PlayAnimation(self.In)
      local index = self.parent:OnEditModeSelect(self.uiData)
      self._cachedTeamSlotIndex = index
      if index < 1 or index > 6 then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(_G.LuaText.umg_pet_teamreplace_7, 6))
        self.parent:DeselectWarehousePetByGid(self.uiData and self.uiData.gid or 0)
        return
      end
      self.number:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_number:SetText(index)
      self.parent:UpdatePetDetailPanel(self.uiData, false, index)
      self:_HideCollectCanvas()
    elseif self.parent:IsTeamSwapping() then
      if self:IsItemValid() then
        self.parent:OnSwapPetDuringSwapMode(self.index)
      else
        self.parent:OnAddPetDuringSwapMode(self.index)
      end
    else
      self:PlayAnimation(self.In)
      self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.parent:UpdatePetDetailPanel(self.uiData, false, self.index)
    end
  else
    self._cachedTeamSlotIndex = 0
    if not self.parent:IsTeamSwapping() then
      if self.bCanPlayOut then
        self:PlayAnimation(self.out)
      end
    elseif self:IsItemValid() then
      self:PlayAnimation(self.out)
    end
    self:_TryShowCollectCanvas()
    if self.parent:IsTeamEditing() then
      self.parent:OnEditModeDeselect(self.uiData.gid)
    end
  end
end

function UMG_ListItem_Pet_C:OnDeactive()
end

function UMG_ListItem_Pet_C:_InitItem()
  self.Switcher_bg:SetActiveWidgetIndex(0)
  self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Travel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self:IsItemValid() then
    self.pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_Quantity:SetText("--")
    self.Cheers:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local bIsNeedBalance = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsNeedBalance)
    local _, level = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetBalanceInfo)
    if bIsNeedBalance then
      self.Text_Quantity:SetText(level or self.uiData.level or 0)
    else
      self.Text_Quantity:SetText(self.uiData.level or 0)
    end
    self.pet:SetIconPathAndMaterial(self.uiData.base_conf_id, self.uiData.mutation_type, self.uiData.glass_info)
    self:_TryShowCollectCanvas()
    self:InitCheerUpPoint()
  end
end

function UMG_ListItem_Pet_C:_TryShowCollectCanvas()
  self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ListItem_Pet_C:_HideCollectCanvas()
  self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ListItem_Pet_C:EnterSwapMode()
  self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Obturation_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.uiData.gid and 0 ~= self.uiData.gid then
    self.Switcher:SetActiveWidgetIndex(0)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.uiData.base_conf_id)
    if petBaseConf then
      self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      self.Obturation_Pet:SetPath(modelConf.icon)
    end
  else
    self.Switcher:SetActiveWidgetIndex(1)
    self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ListItem_Pet_C:QuitSwapMode()
  self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Obturation_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ListItem_Pet_C:UpdatePartnerMark(partnerMark)
  self.CollectCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ListItem_Pet_C:OnAnimationFinished(Anim)
  if Anim == self.In then
    self:PlayAnimation(self.select, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  elseif Anim == self.out then
    self:PlayAnimation(self.Normal, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
end

function UMG_ListItem_Pet_C:IsItemValid()
  return self.uiData and self.uiData.gid and 0 ~= self.uiData.gid
end

function UMG_ListItem_Pet_C:UpdatePetData(newPetData)
  if not newPetData or not newPetData.gid then
    return
  end
  if not self.uiData or not self.uiData.gid then
    return
  end
  if self.uiData.gid ~= newPetData.gid then
    return
  end
  self.uiData = newPetData
  self:_InitItem()
end

function UMG_ListItem_Pet_C:IsSamePetGid(gid)
  if not self:IsItemValid() then
    return false
  end
  return self.uiData.gid == gid
end

function UMG_ListItem_Pet_C:SetCanPlayOutAnim(bCanPlay)
  self.bCanPlayOut = bCanPlay
end

function UMG_ListItem_Pet_C:OpItem(opType, ...)
  if opType == UMG_ListItem_Pet_C.OpType.EnterSwapMode then
    self:EnterSwapMode()
  elseif opType == UMG_ListItem_Pet_C.OpType.QuitSwapMode then
    self:QuitSwapMode()
  elseif opType == UMG_ListItem_Pet_C.OpType.EnterEditMode then
  elseif opType == UMG_ListItem_Pet_C.OpType.QuitEditMode then
  elseif opType == UMG_ListItem_Pet_C.OpType.HasValidData then
    return self:IsItemValid()
  elseif opType == UMG_ListItem_Pet_C.OpType.IsSamePetGid then
    local firstArg = select(1, ...)
    return self:IsSamePetGid(firstArg)
  elseif opType == UMG_ListItem_Pet_C.OpType.SetCanPlayOutAnim then
    local firstArg = select(1, ...)
    return self:SetCanPlayOutAnim(firstArg)
  elseif opType == UMG_ListItem_Pet_C.OpType.ReInit then
    self:_InitItem()
  elseif opType == UMG_ListItem_Pet_C.OpType.UpdateDataAndReInit then
    local newPetData = select(1, ...)
    self.uiData = newPetData or {}
    self:ResetItem()
    self:_InitItem()
  end
end

function UMG_ListItem_Pet_C:InitCheerUpPoint()
  self.Cheers:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local totalStarCount = 0
  if self.uiData.cheer_point_info and #self.uiData.cheer_point_info > 0 then
    for k, v in ipairs(self.uiData.cheer_point_info) do
      if v.cheer_point and v.cheer_point > 0 then
        totalStarCount = totalStarCount + v.cheer_point
      end
    end
  end
  self.CheersNumber:SetText(string.format("x%s", totalStarCount))
end

function UMG_ListItem_Pet_C:ResetItem()
  self:StopAllAnimations()
  self:PlayAnimation(self.Normal, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self.number:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Obturation_Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Obturation_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_ListItem_Pet_C
