local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local TeamBattleModuleEvent = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEvent")
local UMG_SharedFriendsHeadItem_C = Base:Extend("UMG_SharedFriendsHeadItem_C")

function UMG_SharedFriendsHeadItem_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent("UMG_SharedFriendsHeadItem_C", self, FriendModuleEvent.OnVisitorChanged, self.VisitorChanged)
end

function UMG_SharedFriendsHeadItem_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.VisitorChanged)
end

function UMG_SharedFriendsHeadItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data and _data.data
  self.isTip = _data and _data.isTip
  self.Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
  local level, IsReCom = MagicManualUtils.GetFlowerLevel(self.data.seed_star, self.data.spec_flower_seed_id)
  self.PetLevel:SetText(level)
  local VisitIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, self.data.owner_id) or 0
  local StarNumText
  if 1 ~= VisitIndex then
    self.Switcher:SetActiveWidgetIndex(0)
    StarNumText = self.SerialNumber
  else
    StarNumText = self.SerialNumber_1
    self.Switcher:SetActiveWidgetIndex(1)
  end
  StarNumText:SetText(string.format("%dp", VisitIndex))
  if IsReCom then
    self.PetLevel:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE2FF"))
  else
    self.PetLevel:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
  end
  local mutation_type = Enum.MutationDiffType.MDT_NONE
  if self.data.randed_battle_npc_glass then
    if self.data.inner_glass then
      mutation_type = Enum.MutationDiffType.MDT_GLASS
    elseif self.data.inner_shiny then
      mutation_type = Enum.MutationDiffType.MDT_SHINING
    elseif self.data.inner_shiny and self.data.inner_glass then
      mutation_type = Enum.MutationDiffType.MDT_SHINING | Enum.MutationDiffType.MDT_GLASS
    end
  end
  self.HeadIcon:SetIconPathAndMaterial(self.data.inner_petbase_id, mutation_type, self.data.inner_glass_info)
end

function UMG_SharedFriendsHeadItem_C:OnItemSelected(_bSelected)
  if _bSelected then
    if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      self.Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
      _G.NRCEventCenter:DispatchEvent(TeamBattleModuleEvent.SetVisitSelectTeamBattlePet, self.data.owner_id, self.data.seed_npc_logic_id)
    end
  elseif _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    self.Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_SharedFriendsHeadItem_C:VisitorChanged()
  if self.data then
    local VisitInfo = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorByUin, self.data.owner_id)
    if not VisitInfo then
      self:SetClickable(false)
    end
  end
end

function UMG_SharedFriendsHeadItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  if not self.clickable then
    if self.isTip then
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.data.inner_petbase_id, true)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.team_battle_visit_no_master_text)
    end
  end
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_SharedFriendsHeadItem_C
