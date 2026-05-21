local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local ModuleUtils = require("NewRoco.Modules.System.BattleRogue.RogueModuleUtils")
local UMG_HerbologyBadge_SelectOpponent_Item_C = Base:Extend("UMG_HerbologyBadge_SelectOpponent_Item_C")
local RewardType = {
  None = 0,
  Skill = 1,
  Feature = 2,
  Badge = 3
}
local RefreshReq = ProtoMessage:newZoneGrassTrialNodeRefreshReq()
local ModuleData = _G.NRCModuleManager:GetModule("BattleRogueModule").Data

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnConstruct()
  self:AddButtonListener(self.Btn_RefreshMonster, function()
    self:Refresh(true)
  end)
  self:AddButtonListener(self.Btn_RefreshReward, function()
    self:Refresh(false)
  end)
  self:AddButtonListener(self.MonsterBtn, self.OnMonsterBtnClicked)
  self:AddButtonListener(self.RewardBtn, self.OnRewardBtnClicked)
  self.bMonsterNotEnough = true
  self.bRewardNotEnough = true
  self.ShowType = RewardType.None
  self.AttrInfo = {}
  self.EventData = nil
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnItemUpdate(ItemData, _, _)
  if not ItemData or not next(ItemData) then
    return
  end
  self.MonsterText:SetText(ItemData.event_refresh_cost)
  self.RewardText:SetText(ItemData.reward_refresh_cost)
  self.bMonsterNotEnough = ItemData.event_refresh_cost > ModuleData.RemainingCoin
  self.bRewardNotEnough = ItemData.reward_refresh_cost > ModuleData.RemainingCoin
  self:UpdateRefreshUI(self.MonsterBGSwitcher, self.MonsterText, self.bMonsterNotEnough)
  self:UpdateRefreshUI(self.RewardBGSwitcher, self.RewardText, self.bRewardNotEnough)
  if self:IsSameEvent(self.EventData, ItemData) then
    return
  end
  self.EventData = ItemData
  local EventConf = _G.DataConfigManager:GetGrassTrialEventConf(ItemData.event_conf_id)
  local BattleConf = _G.DataConfigManager:GetBattleConf(EventConf.param1)
  local MonsterID = BattleConf.npc_battle_list[1].pos1_1st[1]
  local PetBaseID = _G.DataConfigManager:GetMonsterConf(MonsterID).base_id
  local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetBaseID)
  local SkillConf = _G.DataConfigManager:GetSkillConf(ItemData.reward_id)
  if SkillConf then
    if SkillConf.type == Enum.SkillActiveType.SAT_FEATURE then
      self.ShowType = RewardType.Feature
      self.RewardSwitcher:SetActiveWidgetIndex(0)
      self.FeatureIcon:SetPath(SkillConf.icon)
      self.SkillInfoPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.ShowType = RewardType.Skill
      self.RewardSwitcher:SetActiveWidgetIndex(1)
      self.SkillIcon:SetPath(SkillConf.icon)
      self.SkillInfoPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.HerbologyBadge_Energy:SetEnergyInfo(SkillConf.energy_cost[1], true)
      local TypeDic = _G.DataConfigManager:GetTypeDictionary(SkillConf.skill_dam_type)
      self.AttrInfo.Name = TypeDic.short_name
      self.AttrInfo.Path = TypeDic.tips_res
      self.Attr:SetInfo(self.AttrInfo)
    end
    self.SkillNameTxt:SetText(SkillConf.name)
  else
    self.ShowType = RewardType.Badge
    self.RewardSwitcher:SetActiveWidgetIndex(2)
    self.SkillInfoPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local TrialEffectConf = _G.DataConfigManager:GetGrassTrialEffectConf(self.EventData.reward_id)
    if TrialEffectConf then
      self.BadgeIcon:SetPath(TrialEffectConf.icon)
      self.SkillNameTxt:SetText(TrialEffectConf.name)
    end
  end
  self.TextName:SetText(PetBaseConf.name)
  self.HeadIcon:SetIconPathAndMaterial(PetBaseID)
  if PetBaseConf.unit_type[1] then
    local TypeDic = _G.DataConfigManager:GetTypeDictionary(PetBaseConf.unit_type[1])
    self.DepartmentIcon:SetPath(TypeDic.type_icon)
    self.DepartmentIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.DepartmentIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if PetBaseConf.unit_type[2] then
    local TypeDic = _G.DataConfigManager:GetTypeDictionary(PetBaseConf.unit_type[2])
    self.DepartmentIcon_1:SetPath(TypeDic.type_icon)
    self.DepartmentIcon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.DepartmentIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:IsSameEvent(Data, NewData)
  if Data and next(Data) then
    return Data.event_conf_id == NewData.event_conf_id and Data.reward_id == NewData.reward_id
  end
  return false
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:UpdateRefreshUI(Switcher, Text, bNotEnough)
  Switcher:SetActiveWidgetIndex(bNotEnough and 1 or 0)
  Text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(bNotEnough and "DE4040FF" or "F7F7F7FF"))
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnItemSelected(bSelected, bScrollChoose, bUserClick)
  if bSelected then
    self.Image_Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Image_Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnItemClicked(Index)
  Base.OnItemClicked(self, Index)
  self:BroadcastMsg("OnItemSelected", self._index)
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:Refresh(bMonster)
  local bNotEnough
  if bMonster then
    bNotEnough = self.bMonsterNotEnough
  else
    bNotEnough = self.bRewardNotEnough
  end
  if bNotEnough then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_30036)
    return
  end
  RefreshReq.node_index = ModuleData.CurNodeIndex
  RefreshReq.refresh_type = bMonster and ProtoEnum.NodeRefreshType.NRT_EVENT or ProtoEnum.NodeRefreshType.NRT_REWARD
  RefreshReq.slot_index = self._index
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_NODE_REFRESH_REQ, RefreshReq, self, self.OnRefreshItemRsp)
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnRefreshItemRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    ModuleData:UpdateCoinNum(Rsp.remaining_coin)
    self:BroadcastMsg("OnItemRefreshed", Rsp)
  end
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnMonsterBtnClicked()
  _G.NRCModeManager:DoCmd(BattleRogueModuleCmd.OpenMonsterInfoPanel, self.EventData)
end

function UMG_HerbologyBadge_SelectOpponent_Item_C:OnRewardBtnClicked()
  if self.ShowType ~= RewardType.Badge then
    _G.NRCModuleManager:DoCmd(BattleRogueModuleCmd.OpenPeculiarityTips, self.EventData.reward_id, ModuleUtils.GetBaseConfIDByEventID(self.EventData.event_conf_id))
  end
end

return UMG_HerbologyBadge_SelectOpponent_Item_C
