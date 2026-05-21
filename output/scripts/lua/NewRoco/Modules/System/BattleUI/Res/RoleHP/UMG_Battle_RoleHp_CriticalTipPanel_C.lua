local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local RoleHpData = require("NewRoco.Modules.System.BattleUI.Res.RoleHP.RoleHPMinItem_Data")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_RoleHp_CriticalTipPanel_C = _G.NRCPanelBase:Extend("UMG_Battle_RoleHp_CriticalTipPanel_C")

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnConstruct()
  self.battleManager = _G.BattleManager
  self.uiData = {}
  self:AddListener()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnDestruct()
  self:RemoveListener()
  self.uiData = nil
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnActive()
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self:Show()
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnDeactive()
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:AddListener()
  _G.BattleEventCenter:Bind(self, BattleEvent.REFRESH_ROLE_HP_CRITICAL_TIP)
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:RemoveListener()
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.REFRESH_ROLE_HP_CRITICAL_TIP then
    self:RefreshInfo()
  end
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:RefreshInfo()
  local teamPlayer = self.battleManager.battlePawnManager:GetPlayerMyTeam()
  if not teamPlayer then
    return
  end
  self:UpdateGridViewInfo(teamPlayer)
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:UpdateGridViewInfo(player)
  local num = player.roleInfo.base.hp
  local rawHp = player.roleInfo.base.battle_hp_max or player.roleInfo.base.raw_hp
  Log.Dump(rawHp, 6, "UMG_Battle_RoleHp_CriticalTipPanel_C:UpdateGridViewInfo")
  local dataList = {}
  if nil == num or num <= 0 then
    Log.Error("UMG_Battle_PVERoleHpShow_C: no raw hp found")
    return
  end
  for i = 1, rawHp do
    local info = RoleHpData(player.teamEnm, true)
    if i <= num then
      info.isFull = true
    else
      info.isFull = false
    end
    table.insert(dataList, info)
  end
  if player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    self.NRCGridView_Hp:Clear()
    self.NRCGridView_Hp:InitGridView(dataList)
  else
    return
  end
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -164
  Padding.Top = -74
  Padding.Right = -164
  Padding.Bottom = -74
  self.NRCSafeZone_62:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  self.NRCSafeZone_62.Slot:SetOffsets(Padding)
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:OnAnimationFinished(Animation)
  if Animation == self.open then
    self:StopAllAnimations()
    self:PlayAnimation(self.loop, 0, 0)
    self:DelaySeconds(BattleConst.Show.RoleHpCriticalShowTime, self.Hide, self)
    return
  elseif Animation == self.close then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_ROLE_HP_CRITICAL_TIP_END)
  elseif Animation == self.loop then
  end
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:Show()
  self:RefreshInfo()
  self:StopAllAnimations()
  self:PlayAnimation(self.open)
  self.HpScreenFx:Show()
end

function UMG_Battle_RoleHp_CriticalTipPanel_C:Hide()
  self:StopAllAnimations()
  self:PlayAnimation(self.close)
end

return UMG_Battle_RoleHp_CriticalTipPanel_C
