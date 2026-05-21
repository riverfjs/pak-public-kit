local Base = NRCPanelBase
local ModuleEvent = require("NewRoco/Modules/System/BattleRogue/BattleRogueModuleEvent")
local UMG_HerbologyBadge_SelectOpponent_C = Base:Extend("UMG_HerbologyBadge_SelectOpponent_C")

function UMG_HerbologyBadge_SelectOpponent_C:OnConstruct()
  Base.OnConstruct(self)
  self.CurSelectIndex = nil
  self.EventList = nil
  self.OpponentList:SetMsgHandler({
    OnItemSelected = _G.MakeWeakFunctor(self, self.OnItemSelected),
    OnItemRefreshed = _G.MakeWeakFunctor(self, self.OnItemRefreshed)
  })
  self:AddButtonListener(self.Btn_Affirm.btnLevelUp, self.OnAffirmEnemyBtn)
end

function UMG_HerbologyBadge_SelectOpponent_C:OnActive(_, PanelRsp)
  self.EventList = PanelRsp.node_selection.node_events
  Base.OnActive(self)
  self.OpponentList:InitGridView(self.EventList)
  self.module.Data.CacheNodeData = nil
end

function UMG_HerbologyBadge_SelectOpponent_C:OnItemSelected(Index)
  if self.CurSelectIndex == nil then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(1)
  end
  self.CurSelectIndex = Index
end

function UMG_HerbologyBadge_SelectOpponent_C:OnItemRefreshed(Rsp)
  self.OpponentList:InitGridView(Rsp.new_selection.node_events)
end

function UMG_HerbologyBadge_SelectOpponent_C:OnAffirmEnemyBtn()
  self:DispatchEvent(ModuleEvent.OnNodeFinished)
  local Req = ProtoMessage:newZoneGrassTrialSelectEventReq()
  Req.event_index = self.CurSelectIndex
  ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_SELECT_EVENT_REQ, Req, self, self.OnAffirmedEnemy)
end

function UMG_HerbologyBadge_SelectOpponent_C:OnAffirmedEnemy()
  if self.panelData then
    self:DoClose()
  end
end

return UMG_HerbologyBadge_SelectOpponent_C
