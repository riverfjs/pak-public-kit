local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local EndTransformAbility = Base:Extend("EndTransformAbility")

function EndTransformAbility:Init(abilityConf)
  Base.Init(self, abilityConf)
end

function EndTransformAbility:ShowTransformCancelTips(cancel_reason)
  if not cancel_reason then
    return
  end
  local tips
  if cancel_reason == ProtoEnum.PlayerTransformCancelReason.PTCR_TIMEOUT then
    tips = _G.LuaText.transformed_ended_timeout
  elseif cancel_reason == ProtoEnum.PlayerTransformCancelReason.PTCR_LEAVE_AREA then
    tips = _G.LuaText.quit_undo_transform
  elseif cancel_reason == ProtoEnum.PlayerTransformCancelReason.PTCR_EAGLE_HIT_CHICKEN then
    tips = _G.LuaText.collide_undo_transform
  elseif cancel_reason == ProtoEnum.PlayerTransformCancelReason.PTCR_EAGLE_CHICKEN_ACTIVITY_FINISH then
    tips = _G.LuaText.end_undo_transform
  end
  if tips then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  end
end

function EndTransformAbility:Start(onFinished, params)
  self._buffName = "Transform_Buff"
  Log.Debug("EndTransformAbility:Start")
  local cancel_reason
  if params and params.transform_param then
    cancel_reason = params.transform_param.cancel_reason
  end
  local buff = self.caster.buffComponent:GetBuff(self._buffName)
  if not self.caster.isLocal then
    cancel_reason = buff.cancel_reason
  end
  if buff then
    if cancel_reason and cancel_reason == ProtoEnum.PlayerTransformCancelReason.PTCR_EAGLE_HIT_CHICKEN then
      buff:PlayDizzyAnimBeforeExit()
    elseif buff.isCustomPerform then
      buff:LiquefyPerformEnd()
    else
      self.caster.buffComponent:RemoveBuff(self._buffName)
    end
  end
  if self.caster.isLocal and params and params.transform_param then
    self:ShowTransformCancelTips(cancel_reason)
  end
  if self.caster.isLocal then
    _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_TRANSFORMED)
    local LogicStatusList = self.caster.serverData.status_info
    for _, v in ipairs(LogicStatusList) do
      if v.status == ProtoEnum.SpaceActorLogicStatus.SALS_TRANSFORM then
        local req = _G.ProtoMessage:newZoneSceneCancelPlayerTransformReq()
        req.cancel_reason = ProtoEnum.PlayerTransformCancelReason.PTCR_STATUS_BAN
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CANCEL_PLAYER_TRANSFORM_REQ, req, self, self.OnLocaleCancelPlayerTransformRSP, false, true)
        return
      end
    end
  end
end

function EndTransformAbility:OnLocaleCancelPlayerTransformRSP(rsp)
end

function EndTransformAbility:Interrupt()
  self:Start()
end

function EndTransformAbility:Recover(owner)
  self:Start()
end

return EndTransformAbility
