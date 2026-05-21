local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PetSwapPositions_C = Base:Extend("UMG_PetSwapPositions_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local WeeklyChallengeBattleModuleEvent = require("NewRoco.Modules.System.WeeklyChallengeBattle.WeeklyChallengeBattleModuleEvent")

function UMG_PetSwapPositions_C:OnConstruct()
end

function UMG_PetSwapPositions_C:OnDestruct()
end

function UMG_PetSwapPositions_C:OnItemUpdate(_data, datalist, index)
  self.petID = _data.petID
  self.petGID = _data.petGID
  self.realIDIndex = _data.realIDIndex
  self.petData = _data
  if 0 == self.petGID then
    self.EmptyState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.EmptyState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.petGID and _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID) then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petGID)
    self.HeadIcon:SetIconPathAndMaterial(self.petID, petData.mutation_type, petData.glass_info)
  else
    self.HeadIcon:SetIconPathAndMaterial(self.petID)
  end
  self.index = index
  self.TeamSequenceNumber.NumberText:SetText(self.index)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petID)
  if petBaseConf then
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    if modelConf then
      local path = modelConf.icon
      self.headicon_mask:SetPath(path)
    end
  end
end

function UMG_PetSwapPositions_C:OnItemSelected(_bSelected)
end

function UMG_PetSwapPositions_C:OnDeactive()
end

function UMG_PetSwapPositions_C:OnTouchStarted(_MyGeometry, _TouchEvent)
  if 0 == self.petGID then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  self:CancelAllDelay()
  self:StopAllAnimations()
  self:PlayAnimation(self.select)
  self.TeamSequenceNumber:StopAllAnimations()
  self.TeamSequenceNumber:PlayAnimation(self.TeamSequenceNumber.select)
  _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_PetSwapPositions_C:OnTouchStarted")
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.StarLightPetItemTouchStarted, self.index)
  local pressTimeConf = _G.DataConfigManager:GetGlobalConfigByKeyType("drag_mode_press_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
  local pressTime = 0.1
  self.DelayHandle = _G.DelayManager:DelaySeconds(pressTime, self.LongPress, self)
  Base.OnTouchStarted(self, _MyGeometry, _TouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetSwapPositions_C:OnMouseLeave(_MyGeometry, _TouchEvent)
  self:CancelAllDelay()
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetSwapPositions_C:CancelAllDelay()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self:StopAllAnimations()
    self:PlayAnimation(self.unselect)
    self.TeamSequenceNumber:StopAllAnimations()
    self.DelayHandle = nil
  end
end

function UMG_PetSwapPositions_C:LongPress()
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.StartDragStarLightPet, self.petData, self.index)
end

function UMG_PetSwapPositions_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  self:CancelAllDelay()
  _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.ReleaseStarLightDragItem, self.petData, self.index)
  _G.NRCEventCenter:DispatchEvent(WeeklyChallengeBattleModuleEvent.ReleaseStarLightDragItemPlayAnim, self.index)
  Base.OnTouchEnded(self, _MyGeometry, _TouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetSwapPositions_C:AsDragItemInitInfo(_data, index)
  self:OnItemUpdate(_data, nil, index)
end

function UMG_PetSwapPositions_C:StartDrag()
  if 0 == self.petGID then
    return
  end
  if 0 ~= self.petGID then
    self.headIcon_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Change:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.headIcon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Change:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSwapPositions_C:EndDrag()
  self.headIcon_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Change:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_PetSwapPositions_C
