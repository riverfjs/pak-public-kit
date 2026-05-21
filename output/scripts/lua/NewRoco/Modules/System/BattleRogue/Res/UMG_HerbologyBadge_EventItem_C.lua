local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ModuleEnum = require("NewRoco.Modules.System.BattleRogue.RogueModuleEnum")
local EventState = ModuleEnum.EventState
local UMG_HerbologyBadge_EventItem_C = Base:Extend("UMG_HerbologyBadge_EventItem_C")

function UMG_HerbologyBadge_EventItem_C:OnConstruct()
  self.State = EventState.None
end

function UMG_HerbologyBadge_EventItem_C:OnUpdate(_data, datalist, index)
  if self.State ~= _data then
    self:ShowIconByState(_data)
    self.State = _data
  end
end

local StateWidgetIndexMap = {
  [EventState.Done] = 0,
  [EventState.InProcess] = 1,
  [EventState.Future] = 2,
  [EventState.Boss] = 3
}

function UMG_HerbologyBadge_EventItem_C:ShowIconByState(State)
  if State == EventState.None then
    Log.Error("ShowIconByState\230\151\182 State\230\156\170\229\161\171\229\133\133")
    return
  end
  local TargetWidgetIndex = StateWidgetIndexMap[State]
  if TargetWidgetIndex then
    self.NRCSwitcher_24:SetActiveWidgetIndex(TargetWidgetIndex)
  end
end

return UMG_HerbologyBadge_EventItem_C
