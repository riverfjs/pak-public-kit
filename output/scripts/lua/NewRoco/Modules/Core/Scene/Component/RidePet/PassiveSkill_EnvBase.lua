local Base = require("NewRoco.Modules.Core.Scene.Component.RidePet.PassiveSkill_Base")
local PassiveSkill_EnvBase = Base:Extend("PassiveSkill_EnvBase")
local Stat = require("NewRoco.Modules.Core.Scene.Component.Stat.Stat")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")

function PassiveSkill_EnvBase:Ctor(owner, config)
  Base.Ctor(self, owner, config)
  self._stat_ids = {}
  self._stat_kvs = {}
end

function PassiveSkill_EnvBase:ParseConfig(config)
  local env_type = tonumber(config.param_1)
  local stat_kvs = {}
  if config.param_2 then
    for k, v in string.gmatch(config.param_2, "(%w+)=([^,\239\188\140]+)") do
      stat_kvs[k] = tonumber(v)
    end
  end
  self._stat_kvs[env_type] = self._stat_kvs[env_type] or {}
  table.insert(self._stat_kvs[env_type], stat_kvs)
end

function PassiveSkill_EnvBase:TryPlayEffect(envType)
  if self._cur_env_type and self._cur_env_type == envType then
    return
  end
  self._cur_env_type = envType
  self:StopCommonEffect()
  local stat_kv_list = self._stat_kvs[envType]
  if not stat_kv_list or table.isEmpty(stat_kv_list) then
    return
  end
  self:PlayCommonEffect()
end

function PassiveSkill_EnvBase:AddEnvBuff(envType)
  if self._cur_env_type and self._cur_env_type == envType then
    return
  end
  self._cur_env_type = envType
  self:RemoveEnvBuff()
  local stat_kv_list = self._stat_kvs[envType]
  if not stat_kv_list or table.isEmpty(stat_kv_list) then
    self:StopCommonEffect()
    return
  end
  local statComponent = self.owner.owner.statComponent
  if not UE.UObject.IsValid(self.owner.viewObj) then
    Log.Error("PassiveSkill_EnvBase:AddEnvBuff: owner.viewObj is nil")
    return
  end
  local currentMovement = self.owner.viewObj.CharacterMovement.CurrentMovement
  currentMovement = currentMovement or self.owner.viewObj.CharacterMovement
  if statComponent and currentMovement then
    for _, stat_kv in ipairs(stat_kv_list) do
      for k, v in pairs(stat_kv) do
        local statId = -1
        if k == StatType.VITALITY_COST_RATIO then
          statId = statComponent:ApplyStat(k, v)
        else
          statId = statComponent:ApplyStat(k, v, Stat.StatApplyType.BaseValueOverride, currentMovement)
        end
        self._stat_ids[k] = statId
      end
    end
  end
  if table.isNotEmpty(self._stat_ids) then
    self:PlayCommonEffect()
  end
end

function PassiveSkill_EnvBase:RemoveEnvBuff()
  self:StopCommonEffect()
  if self.owner and self.owner.owner then
    if not UE.UObject.IsValid(self.owner.viewObj) then
      Log.Error("PassiveSkill_EnvBase:RemoveEnvBuff: owner.viewObj is nil")
      return
    end
    local statComponent = self.owner.owner.statComponent
    local currentMovement = self.owner.viewObj.CharacterMovement.CurrentMovement
    currentMovement = currentMovement or self.owner.viewObj.CharacterMovement
    if statComponent and currentMovement then
      for k, v in pairs(self._stat_ids) do
        if k == StatType.VITALITY_COST_RATIO then
          statComponent:RemoveStat(k, v)
        else
          statComponent:RemoveStat(k, v, currentMovement)
        end
      end
    end
    self._stat_ids = {}
    self._cur_env_type = nil
  end
end

function PassiveSkill_EnvBase:PlayCommonEffect()
end

function PassiveSkill_EnvBase:StopCommonEffect()
  if UE.UObject.IsValid(self.owner.viewObj) and self._env_effect_id then
    self.owner.viewObj.RocoFX:StopFx(self._env_effect_id)
    self._env_effect_id = nil
  end
end

function PassiveSkill_EnvBase:Stop()
  self:StopCommonEffect()
end

return PassiveSkill_EnvBase
