local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local BornDieComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.BornDieComponent")
local Base = NPCActionBase
local NPCActionShowContent = Base:Extend("NPCActionShowContent")

function NPCActionShowContent:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  self.Contents = false
  self.Finished = false
  self.Handler = -1
  self.WaitList = nil
  self.StartWaitTime = -1
end

function NPCActionShowContent:Execute(playerId, needSendReq)
  Base.Execute(self, playerId, needSendReq)
  self.Finished = false
  self.Handler = -1
  self.WaitList = nil
  self.StartWaitTime = -1
  if not self.Contents then
    local NumberStrings = string.Split(self.Config.action_param1, ";")
    NumberStrings = NumberStrings or {
      self.Config.action_param1
    }
    for Index, Str in ipairs(NumberStrings) do
      NumberStrings[Index] = tonumber(Str)
    end
    self.Contents = NumberStrings
  end
  if self:WaitForContents() then
    self:OnContentsReady()
  else
    self.StartWaitTime = os.msTime()
    _G.UpdateManager:Register(self)
  end
end

function NPCActionShowContent:WaitForContents()
  local ContentsReady = true
  if self.Contents then
    for _, ContentID in ipairs(self.Contents) do
      local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, ContentID)
      if not NPC then
        ContentsReady = false
        self:Log("NPC\229\176\154\228\184\141\229\173\152\229\156\168", ContentID)
        break
      end
    end
  end
  return ContentsReady
end

function NPCActionShowContent:OnTick()
  local HasTimeout = os.msTime() - self.StartWaitTime < 10000
  if not HasTimeout and not self:WaitForContents() then
    return
  end
  _G.UpdateManager:UnRegister(self)
  self:OnContentsReady()
end

function NPCActionShowContent:OnContentsReady()
  self.StartWaitTime = -1
  local ShouldWait = not string.IsNilOrEmpty(self.Config.action_param2)
  local WaitList
  if self.Contents then
    for _, ContentID in ipairs(self.Contents) do
      local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, ContentID)
      if NPC and self:ShowNpc(NPC) then
        if ShouldWait then
          WaitList = WaitList or MakeWeakTable()
          WaitList[NPC] = true
        end
      elseif not NPC then
        self:LogError("NPC\228\184\141\229\173\152\229\156\168", ContentID)
      end
    end
  end
  if ShouldWait and not table.isEmpty(WaitList) then
    self.WaitList = WaitList
    for NPC, _ in pairs(WaitList) do
      NPC:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBornPerformFinished)
      NPC:AddEventListener(self, NPCModuleEvent.OnBornPerformFinished, self.OnBornPerformFinished)
    end
    self.Handler = _G.DelayManager:DelaySeconds(10, self.MarkFinished, self, false)
  else
    self:MarkFinished(true)
  end
end

function NPCActionShowContent:OnBornPerformFinished(NPC)
  if not self.WaitList then
    self:LogError("\229\135\186\231\142\176\228\184\165\233\135\141\233\148\153\232\175\175\239\188\140WaitList\228\184\141\229\173\152\229\156\168")
    self:MarkFinished(false)
    return
  end
  local HasNPC = self.WaitList[NPC]
  if HasNPC then
    self.WaitList[NPC] = nil
    NPC:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBornPerformFinished)
    NPC:RemoveEventListener(self, NPCModuleEvent.OnBornPerformFinished, self.OnBornPerformFinished)
  else
    self:LogError("\229\135\186\231\142\176\228\184\165\233\135\141\233\148\153\232\175\175\239\188\140\232\161\168\230\188\148\229\174\140\230\136\144\231\154\132NPC\228\184\141\229\156\168WaitList\229\134\133", NPC:DebugNPCNameAndID())
  end
  if table.isEmpty(self.WaitList) then
    self:MarkFinished(true)
  else
    self:Log("\231\187\167\231\187\173\231\173\137\229\190\133\229\138\160\232\189\189\229\174\140")
  end
end

function NPCActionShowContent:MarkFinished(Success)
  if self.Handler > 0 then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = -1
  end
  if not self.Finished then
    if not Success then
      self:LogError("\229\188\130\229\184\184\231\187\147\230\157\159")
    end
    self.Finished = true
    self:Finish(true)
  end
  if self.WaitList then
    self.WaitList = nil
  end
  self.StartWaitTime = -1
end

function NPCActionShowContent:ShowNpc(npc)
  if not npc then
    return false
  end
  if not npc:IsHidden(NPCModuleEnum.NpcReasonFlags.SERVER_TASK) then
    Log.Error("\230\173\164NPC\228\184\141\231\148\177\228\187\187\229\138\161\230\142\167\229\136\182\230\152\190\233\154\144\239\188\140\230\151\160\230\179\149\230\152\190\231\164\186", npc:DebugNPCNameAndID(), npc.hiddenFlag)
    return false
  end
  npc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  npc:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  local View = npc.viewObj
  if not View or not UE.UObject.IsValid(View) then
    return false
  end
  local AppearSkill = npc.config.emerge_skill
  local AppearAni = npc.config.emerge_ani
  if string.IsNilOrEmpty(AppearSkill) and string.IsNilOrEmpty(AppearAni) then
    local Comps = View:K2_GetComponentsByClass(UE.UNiagaraComponent)
    for _, Comp in tpairs(Comps) do
      Comp:SetActive(false, true)
      Comp:SetActive(true, true)
    end
    return false
  end
  local BornDieComp = npc:EnsureComponent(BornDieComponent)
  local HasPerform = BornDieComp:OnBeginBorn()
  return HasPerform and BornDieComp:IsPerforming()
end

function NPCActionShowContent:UpdateInfo(Info, Reconnect, InteractingAvatarID)
  Base.UpdateInfo(self, Info, Reconnect, InteractingAvatarID)
  if Reconnect then
    self:Log("Reconnect")
    _G.UpdateManager:UnRegister(self)
    if self.WaitList then
      self.WaitList = nil
    end
  end
end

function NPCActionShowContent:ExecuteWhenSkipping()
  if not self.Contents then
    local NumberStrings = string.Split(self.Config.action_param1, ";")
    NumberStrings = NumberStrings or {
      self.Config.action_param1
    }
    for Index, Str in ipairs(NumberStrings) do
      NumberStrings[Index] = tonumber(Str)
    end
    self.Contents = NumberStrings
  end
  if self.Contents then
    for _, ContentID in ipairs(self.Contents) do
      local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, ContentID)
      if NPC then
        self:ShowNpcWhenSkipping(NPC)
      end
    end
  end
end

function NPCActionShowContent:ShowNpcWhenSkipping(npc)
  if not npc then
    return false
  end
  npc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  npc:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.SERVER_TASK)
  local View = npc.viewObj
  if not View or not UE.UObject.IsValid(View) then
    return false
  end
  local AppearSkill = npc.config.emerge_skill
  local AppearAni = npc.config.emerge_ani
  if string.IsNilOrEmpty(AppearSkill) and string.IsNilOrEmpty(AppearAni) then
    local Comps = View:K2_GetComponentsByClass(UE.UNiagaraComponent)
    for _, Comp in tpairs(Comps) do
      Comp:SetActive(false, true)
      Comp:SetActive(true, true)
    end
    return false
  end
  local BornDieComp = npc:EnsureComponent(BornDieComponent)
  BornDieComp:OnBornWhenSkipping()
end

return NPCActionShowContent
