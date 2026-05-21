local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local Base = BattleActionBase
local BattleOpenCriticalRedPanelAction = Base:Extend("BattleOpenCriticalRedPanelAction")
FsmUtils.MergeMembers(Base, BattleOpenCriticalRedPanelAction, {})

function BattleOpenCriticalRedPanelAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
end

function BattleOpenCriticalRedPanelAction:OnEnter()
  self.isUINeed = false
  local player = self.BattleManager.battlePawnManager:GetPlayerMyTeam()
  if player and not BattleUtils.IsTeam() and not BattleUtils.IsFinalBattle() then
    local hp = player.roleInfo.base.hp or 100
    local cards = player.team:GetInBattleCards()
    local hp_need = 0
    for i, card in ipairs(cards) do
      local baseID = card.petInfo.battle_inside_pet_info.base_conf_id
      local baseConf = _G.DataConfigManager:GetPetbaseConf(baseID)
      if not baseConf then
        Log.Error("Pet base ID not found: ", baseID)
        self:Finish()
        return
      end
      hp_need = hp_need + baseConf.consume_role_hp
    end
    if hp <= hp_need then
      self.isUINeed = true
    else
      self.isUINeed = false
    end
  end
  if self.isUINeed then
    self:ShowUIPanel()
    self:Finish()
  else
    self:Finish()
  end
end

function BattleOpenCriticalRedPanelAction:ShowUIPanel()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattleRedPanel)
end

function BattleOpenCriticalRedPanelAction:HideUIPanel()
end

function BattleOpenCriticalRedPanelAction:OnFinish()
end

function BattleOpenCriticalRedPanelAction:OnExit()
end

return BattleOpenCriticalRedPanelAction
