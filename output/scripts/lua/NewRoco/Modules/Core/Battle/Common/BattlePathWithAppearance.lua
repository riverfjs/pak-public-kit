local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePathWithAppearance = NRCClass()

function BattlePathWithAppearance:Ctor()
  local Empty = ""
  self.Owner = nil
  self.HuanChong = Empty
  self.EnemyZhaoHuan = Empty
  self.EnemyHuanChong = Empty
  self.HuanchongSuiId = -1
  self.PVPOver = Empty
  self.PVPOverSuiId = -1
  self.WeeklyChallengeOver = Empty
end

function BattlePathWithAppearance:ResetDefaultValue()
  self.DefaultHuanChong = BattleConst.HuanChong
  self.DefaultEnemyZhaoHuan = BattleConst.EnemyZhaoHuan
  self.DefaultEnemyHuanChong = BattleConst.EnemyHuanChong
  self.DefaultPVPOver = BattleConst.PVPOver
  self.DefaultWeeklyChallengeOver = BattleConst.LeaderChallengeWinOver
  if self.Owner and self.Owner.owner then
    local roleInfo = self.Owner.owner.roleInfo
    if not BattleUtils.IsPlayerUseHumanResByBit(roleInfo.base.state_bit) then
      self.DefaultHuanChong = BattleConst.NPCHuanChong
    end
  end
end

function BattlePathWithAppearance:Reset()
  self:ResetDefaultValue()
  self.HuanChong = self.DefaultHuanChong
  self.EnemyZhaoHuan = self.DefaultEnemyZhaoHuan
  self.EnemyHuanChong = self.DefaultEnemyHuanChong
  self.HuanchongSuiId = -1
  self.PVPOver = self.DefaultPVPOver
  self.PVPOverSuiId = -1
  self.WeeklyChallengeOver = self.DefaultWeeklyChallengeOver
end

function BattlePathWithAppearance:SetOwner(card)
  self.Owner = card
end

function BattlePathWithAppearance:GetZhaoHuan(ignoreSuit)
  if BattleUtils.IsTeam() and self.Owner.owner.guid ~= _G.BattleManager.battlePawnManager.TeamatePlayer.guid then
    return BattleConst.TeamNpcHuanChong
  end
  if self.Owner.owner.teamEnm == BattleEnum.Team.ENUM_TEAM then
    if ignoreSuit then
      return self.DefaultHuanChong
    end
    return self.HuanChong
  else
    if ignoreSuit then
      return self.DefaultEnemyZhaoHuan
    end
    return self.EnemyZhaoHuan
  end
end

function BattlePathWithAppearance:GetHuanChong(ignoreSuit)
  if BattleUtils.IsTeam() and self.Owner.owner.guid ~= _G.BattleManager.battlePawnManager.TeamatePlayer.guid then
    return BattleConst.TeamNpcHuanChong
  end
  if self.Owner.owner.teamEnm == BattleEnum.Team.ENUM_TEAM then
    if ignoreSuit then
      return self.DefaultHuanChong
    end
    return self.HuanChong
  else
    if ignoreSuit then
      return self.DefaultEnemyHuanChong
    end
    return self.EnemyHuanChong
  end
end

function BattlePathWithAppearance:GetPVPOver(ignoreSuit)
  if ignoreSuit then
    return self.DefaultPVPOver
  end
  return self.PVPOver
end

function BattlePathWithAppearance:GetWeeklyChallengeOver()
  return self.WeeklyChallengeOver
end

return BattlePathWithAppearance
