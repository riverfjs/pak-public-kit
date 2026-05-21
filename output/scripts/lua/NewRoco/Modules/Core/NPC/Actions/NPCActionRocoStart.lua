require("UnLua")
local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local ResQueue = require("NewRoco.Utils.ResQueue")
local Base = NPCActionBase
local NPCActionRocoStart = Base:Extend("NPCActionRocoStart")

function NPCActionRocoStart:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.LoadQueue = nil
end

function NPCActionRocoStart:Execute()
  Base.Execute(self)
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.ShowStartupPanel, self)
  if self.LoadQueue then
    self.LoadQueue:Release()
  else
    self.LoadQueue = ResQueue(30, ResQueue.RunMode.Concurrent, _G.PriorityEnum.Active_Player_Action)
  end
  self.ContentId = tonumber(self.Config.action_param1)
  local npc_refresh_content = _G.DataConfigManager:GetNpcRefreshContentConf(self.ContentId)
  if npc_refresh_content.refresh_param then
    local area_conf = _G.DataConfigManager:GetAreaConf(npc_refresh_content.refresh_param)
    if area_conf.pos then
      self.PosAndRot = area_conf.pos[1]
      local position = ProtoMessage:newPosition()
      local pos = self.PosAndRot.position_xyz
      position.x = pos[1]
      position.y = pos[2]
      position.z = pos[3]
      self.LoadQueue:InsertNPC("NPC", 19002, position, 0)
      self.LoadQueue:StartLoad(self, self.OnRocoStartup)
    end
  end
end

function NPCActionRocoStart:OnRocoStartup(Queue, Success)
  if not Success then
    Queue:Release()
    self:Finish(false)
    return
  end
  local NPC = Queue:Get("NPC")
  self.NPCView = NPC.viewObj
  self.NPCView:SetupAction(self)
  NPC.serverData.npc_base.npc_content_cfg_id = self.ContentId
  local rot = self.PosAndRot.rotation_xyz
  NPC:SetActorRotation(UE.FRotator(rot[2], rot[3], rot[1]))
end

function NPCActionRocoStart:PlayStartSkill()
  if self.NPCView then
    self.NPCView:PlayLevel2()
  end
end

function NPCActionRocoStart:StopStartSkill()
  if self.NPCView then
    self.NPCView:StopAnim()
  end
end

function NPCActionRocoStart:PlayLevel4()
  if self.NPCView then
    self.NPCView:PlayLevel4()
  end
end

function NPCActionRocoStart:OnCommit(rsp)
  Base.OnCommit(self, rsp)
end

return NPCActionRocoStart
