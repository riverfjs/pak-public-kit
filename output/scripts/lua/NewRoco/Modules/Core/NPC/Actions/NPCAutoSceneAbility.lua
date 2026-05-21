local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local Base = NPCActionBase
local NPCAutoSceneAbility = Base:Extend("NPCAutoSceneAbility")

function NPCAutoSceneAbility:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.petBaseId = tonumber(self.Config.action_param1)
  self.vitality = tonumber(self.Config.action_param2)
  self.bIsWild = self.Config.action_type == Enum.ActionType.ACT_WILD_RIDING
  self.bIsTempRide = self.Config.action_type == Enum.ActionType.ACT_TEMP_RIDING
  if self.bIsWild then
    self.rideAllCustomGid = _G.ProtoEnum.SceneRideAllCustomGid.SRCG_Wild
  elseif self.bIsTempRide then
    self.rideAllCustomGid = _G.ProtoEnum.SceneRideAllCustomGid.SRCG_Interact
  else
    self.rideAllCustomGid = _G.ProtoEnum.SceneRideAllCustomGid.SRCG_MiniGame
  end
end

function NPCAutoSceneAbility:OnNpcAction()
  if self.bIsWild then
    local Owner = self:GetOwnerNPC()
    if Owner then
      local BaseInfo = Owner:GetNpcBaseInfo()
      local MutationType = BaseInfo and BaseInfo.mutation_type
      if MutationType and MutationType > 0 then
        if self.Owner:GetInteractType() == Enum.InteractType.IT_MANUAL then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.forbid_ride_glassnpc)
        end
        return false
      end
    end
  end
  if self.bIsTempRide then
    local player = self:GetPlayer()
    local rideComponent = player and player:GetRideComponent()
    local petBaseId = rideComponent and rideComponent:GetPetBaseID() or 0
    if petBaseId == self.petBaseId then
      return false
    end
  end
  return Base.OnNpcAction(self)
end

function NPCAutoSceneAbility:DoExecute(...)
  if not self.bIsWild and self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if not self.bIsWild then
    local View = self:GetOwnerNPCView()
    if View and View.UpdateOpacity then
      View:UpdateOpacity(false)
    end
    self.DelayId = _G.DelayManager:DelaySeconds(3, self.OnRide, self)
  end
  _G.NRCAudioManager:PlaySound2DAuto(1220002023, self.name)
  _G.NRCEventCenter:DispatchEvent(SceneEvent.OnMiniGameRide, self.petBaseId, self.vitality, self.rideAllCustomGid, self:GetOwnerNPC():GetServerId(), self:GetOwnerConfig().id)
  self:Finish(true, nil, nil)
end

function NPCAutoSceneAbility:OnSubmit(rsp)
  Base.OnSubmit(self, rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("NPCAutoSceneAbility OnSubmit ret_code ~= 0", rsp.ret_info.ret_code)
    self:Finish(false)
    return
  end
  self:DoExecute()
end

function NPCAutoSceneAbility:OnRide()
  self.DelayId = nil
  if self.bIsWild then
    return
  end
  local View = self:GetOwnerNPCView()
  if not View then
    return
  end
  self.Owner.inActionArea = false
  if View.UpdateOpacity then
    View:UpdateOpacity(true)
  end
end

return NPCAutoSceneAbility
