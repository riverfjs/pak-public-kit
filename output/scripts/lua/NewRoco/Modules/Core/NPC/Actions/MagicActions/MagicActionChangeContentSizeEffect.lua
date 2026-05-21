local MagicActionBase = require("NewRoco.Modules.Core.NPC.Actions.MagicActions.MagicActionBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local Base = MagicActionBase
local MagicActionChangeContentSizeEffect = Base:Extend("MagicActionChangeContentSizeEffect")

function MagicActionChangeContentSizeEffect:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.target_refresh_id = nil
  self.skillProxy = nil
end

function MagicActionChangeContentSizeEffect:Execute()
  Base.Execute(self)
  self.target_refresh_id = tonumber(self.Config and self.Config.action_param1) or 0
  if 0 == self.target_refresh_id then
    self:Finish(false)
    return
  end
  local targetNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, self.target_refresh_id)
  local targetView = targetNpc and targetNpc.viewObj
  local ownerNpc = self:GetOwnerNPC()
  local ownerNpcView = self:GetOwnerNPCView()
  ownerNpc:SetNotDestroyFlag(true)
  self.skillProxy = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/NPC/G6_NPC_XueGuai.G6_NPC_XueGuai", ownerNpcView.RocoSkill, _G.PriorityEnum.Active_Player_Action)
  self.skillProxy:SetCaster(ownerNpcView)
  if targetView then
    self.skillProxy:SetTargets({targetView})
  end
  self.skillProxy:RegisterEventCallback("End", self, self.OnSkillFinish)
  self.skillProxy:RegisterEventCallback("PreEnd", self, self.OnSkillFinish)
  self.skillProxy:RegisterEventCallback("Interrupt", self, self.OnSkillFinish)
  self.skillProxy:PlaySkill()
end

function MagicActionChangeContentSizeEffect:OnSkillFinish()
  local ownerNpc = self:GetOwnerNPC()
  ownerNpc:SetNotDestroyFlag(false)
  local req = _G.ProtoMessage:newZoneSceneChangeNpcSizeScaleReq()
  local targetNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, self.target_refresh_id)
  req.npc_id = targetNpc and targetNpc:GetServerId() or 0
  req.npc_content_id = self.target_refresh_id
  req.snow_npc_id = ownerNpc:GetServerId() or 0
  local param2Str = self.Config and self.Config.action_param2 or ""
  local param3Str = self.Config and self.Config.action_param3 or ""
  local typeVal, paramVal = param2Str:match("([^;]+);([^;]+)")
  local scaleMin, scaleMax = param3Str:match("([^;]+);([^;]+)")
  req.type = tonumber(typeVal)
  req.param = tonumber(paramVal)
  req.scale_size_min = tonumber(scaleMin)
  req.scale_size_max = tonumber(scaleMax)
  if not (req.type and req.param and req.scale_size_min) or not req.scale_size_max then
    Log.ErrorFormat("[MagicActionChangeContentSizeEffect] \233\133\141\231\189\174\229\143\130\230\149\176\228\184\141\229\144\136\230\179\149, action_param2=%s, action_param3=%s", param2Str, param3Str)
    self:Finish(false)
    return
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CHANGE_NPC_SIZE_SCALE_REQ, req)
  self:Finish(true)
end

return MagicActionChangeContentSizeEffect
