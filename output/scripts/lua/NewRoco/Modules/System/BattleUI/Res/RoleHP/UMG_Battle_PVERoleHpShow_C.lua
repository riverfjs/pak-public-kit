local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local RoleHpData = require("NewRoco.Modules.System.BattleUI.Res.RoleHP.RoleHPMinItem_Data")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_PVERoleHpShow_C = _G.NRCPanelBase:Extend("UMG_Battle_PVERoleHpShow_C")

function UMG_Battle_PVERoleHpShow_C:Construct()
  self.battleManager = _G.BattleManager
end

function UMG_Battle_PVERoleHpShow_C:Destruct()
  NRCUmgClass.Destruct(self)
end

function UMG_Battle_PVERoleHpShow_C:ClearGridView(player, index)
  local dataList = {}
  if player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    if 0 == index then
      self.NRCGridView_enemy:Clear()
      self.NRCGridView_enemy:InitGridView(dataList)
    elseif 1 == index then
      self.NRCGridView_enemy_1:Clear()
      self.NRCGridView_enemy_1:InitGridView(dataList)
    end
  elseif player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    self.NRCGridView_team:Clear()
    self.NRCGridView_team:InitGridView(dataList)
  else
    return
  end
end

function UMG_Battle_PVERoleHpShow_C:ClearInfo()
  self.playerTeams = self.battleManager.battlePawnManager.AllPlayerTeam
  for i = 1, #self.playerTeams do
    self:ClearGridView(self.playerTeams[i].player, i - 1)
  end
  self.enemyTeams = self.battleManager.battlePawnManager.AllEnemyTeam
  for i = 1, #self.enemyTeams do
    self:ClearGridView(self.enemyTeams[i].player, i - 1)
  end
  if 1 == #self.enemyTeams then
    self.NRCGridView_enemy_1:Clear()
    self.NRCGridView_enemy_1:InitGridView({})
  end
end

function UMG_Battle_PVERoleHpShow_C:InsertHpDataByRule2(player, needShine)
  local blackHp = player.roleInfo.base.black_hp
  local curHp = player.roleInfo.base.battle_hp_max or player.roleInfo.base.raw_hp
  local useHp = curHp - blackHp
  if player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    local count = #self.teamHpDataList
    for i = 1, count do
      local info = self.teamHpDataList[i]
      info.isFull = nil
      info.isShow = nil
      if i <= blackHp then
        info.isFull = true
        info.isLock = true
      else
        info.isFull = true
        info.isShine = needShine
      end
    end
  elseif player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    for _, info in pairs(self.enemyHpDataList) do
      info.isFull = true
      info.isShine = needShine
      info.isShow = nil
    end
  end
end

function UMG_Battle_PVERoleHpShow_C:InsertHpDataByRule1(player)
  local totalConsumeHp = player.roleInfo.base.battle_hp_max
  for i = totalConsumeHp, 1, -1 do
    local info = RoleHpData(player.teamEnm, false, false)
    info.isShow = true
    info.isFull = true
    if player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      table.insert(self.enemyHpDataList, info)
    else
      table.insert(self.teamHpDataList, info)
    end
  end
  Log.Dump(player.roleInfo.base, 6, "UMG_Battle_PVERoleHpShow_C:InsertHpDataByRule1")
end

function UMG_Battle_PVERoleHpShow_C:RefreshHpList()
  local curIndex = 1
  local teamListCount = #self.teamHpDataList
  while curIndex <= teamListCount do
    local item = self["TeamHPItem_" .. curIndex]
    if item then
      item:SetVisibility(UE4.ESlateVisibility.Visible)
      item:OnItemUpdate(self.teamHpDataList[curIndex])
    end
    curIndex = curIndex + 1
  end
  while curIndex <= 8 do
    local item = self["TeamHPItem_" .. curIndex]
    if item then
      item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    curIndex = curIndex + 1
  end
  curIndex = 1
  teamListCount = #self.enemyHpDataList
  while curIndex <= teamListCount do
    local item = self["EnemyHPItem_" .. curIndex]
    if item then
      item:SetVisibility(UE4.ESlateVisibility.Visible)
      item:OnItemUpdate(self.enemyHpDataList[curIndex])
    end
    curIndex = curIndex + 1
  end
  while curIndex <= 8 do
    local item = self["EnemyHPItem_" .. curIndex]
    if item then
      item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    curIndex = curIndex + 1
  end
end

function UMG_Battle_PVERoleHpShow_C:RefreshInfoShow()
  if not self.playerTeams then
    return
  end
  if not self.enemyTeams then
    return
  end
  self.teamHpDataList = {}
  self.enemyHpDataList = {}
  local teamPlayer = self.battleManager.battlePawnManager.TeamatePlayer
  for i = #self.playerTeams, 1, -1 do
    if self.playerTeams[i].player == teamPlayer then
      self:InsertHpDataByRule1(self.playerTeams[i].player)
      break
    end
  end
  for i = 1, #self.enemyTeams do
    self:InsertHpDataByRule1(self.enemyTeams[i].player)
  end
  self:RefreshHpList()
  local config = BattleUtils.GetBattleConfig()
  if config.available_hp_rule == Enum.AvailableHpRule.AHR_BLACK_MAN then
    self:PlayAnimation(self.Delay0_2sPlayShine)
  else
    self:PlayAnimation(self.Delay0_2sHide)
  end
end

function UMG_Battle_PVERoleHpShow_C:RefreshInfoShine()
  if not UE4.UObject.IsValid(self) then
    return
  end
  self:RefreshInfoWithAnim(true)
  self:PlayAnimation(self.Delay1sHide)
end

function UMG_Battle_PVERoleHpShow_C:RefreshInfoWithAnim(needShine)
  if not self.playerTeams then
    return
  end
  if not self.enemyTeams then
    return
  end
  for i = 1, #self.playerTeams do
    self:InsertHpDataByRule2(self.playerTeams[i].player, needShine)
  end
  for i = 1, #self.enemyTeams do
    self:InsertHpDataByRule2(self.enemyTeams[i].player, needShine)
  end
  self:RefreshHpList()
end

function UMG_Battle_PVERoleHpShow_C:UpdateDes()
  local cfg_battle_id = BattleUtils.GetBattleInitInfo().battle_cfg_id[1]
  local cfg = _G.DataConfigManager:GetBattleConf(cfg_battle_id)
  local hp_max = "~"
  if cfg then
    hp_max = cfg.role_available_HP
  end
  local cfgText = _G.DataConfigManager:GetGlobalConfigByKeyType("battle_people_hp_rules", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG).str
  local text = "<color>" .. tostring(hp_max) .. "</>"
  cfgText = string.format(cfgText, text)
  self.RoleHpShow_Des:SetText(cfgText)
end

function UMG_Battle_PVERoleHpShow_C:UpdateSelfIcon(player)
  self.RoleHPMini:Update(player)
end

function UMG_Battle_PVERoleHpShow_C:AddListeners()
  self.battleManager:AddEventListener(self, BattleEvent.REFRESH_PVE_ENTER_ROLE_HP, self.RefreshInfo)
end

function UMG_Battle_PVERoleHpShow_C:RemoveListeners()
end

function UMG_Battle_PVERoleHpShow_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    local player = _G.BattleManager.battlePawnManager.TeamatePlayer
    self:UpdateSelfIcon(player)
    self.RoleHPMini:Show()
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1151, "UMG_Battle_PVERoleHpShow_C.OpenFinish")
    self:RefreshInfoShow()
    return
  elseif Animation == self.close then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_PVE_ENTER_ROLE_HP_END)
  elseif Animation == self.Delay1sHide then
    self:Hide()
  elseif Animation == self.Delay0_2sHide then
    self:Hide()
  elseif Animation == self.Delay0_2sPlayShine then
    self:RefreshInfoShine()
  end
end

function UMG_Battle_PVERoleHpShow_C:Show()
  self.RoleHPMini:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:ClearInfo()
  self:UpdateDes()
  self:StopAllAnimations()
  self:PlayAnimation(self.open)
  _G.NRCAudioManager:PlaySound2DAuto(1220002091, "UMG_Battle_PVE_RoleHpPanel_C:OnActive")
end

function UMG_Battle_PVERoleHpShow_C:Hide()
  if not UE4.UObject.IsValid(self) then
    return
  end
  self:StopAllAnimations()
  self:PlayAnimation(self.close)
  self.RoleHPMini:Hide()
end

return UMG_Battle_PVERoleHpShow_C
