local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local InstanceEnum = require("NewRoco.Modules.Core.Instance.InstanceEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local DungeonStatusComponent = Base:Extend("DungeonStatusComponent")

function DungeonStatusComponent:Ctor()
  Base.Ctor(self)
  self.DungeonStatus = 0
end

function DungeonStatusComponent:Attach(owner)
  Base.Attach(self, owner)
end

function DungeonStatusComponent:DeAttach()
  self:ClearAllDungeonStatus()
  Base.DeAttach(self)
end

function DungeonStatusComponent:Destroy()
  self:ClearAllDungeonStatus()
  Base.Destroy(self)
end

function DungeonStatusComponent:CheckCurDungeonStatus(Status)
  return 0 ~= self.DungeonStatus & 1 << Status
end

function DungeonStatusComponent:SetDungeonStatus(bAdd, Status, Caster)
  if not self:StatusSetCheck(Status) then
    return
  end
  local PreStatus = self.DungeonStatus
  if bAdd then
    self.DungeonStatus = self.DungeonStatus | 1 << Status
  else
    self.DungeonStatus = self.DungeonStatus & ~(1 << Status)
  end
  self:OnDungeonStatusChanged(PreStatus, self.DungeonStatus, Caster)
end

function DungeonStatusComponent:StatusSetCheck(Status)
  if Status == InstanceEnum.DungeonPlayerStatusType.DPST_TOXICITY and _G.NRCModuleManager:DoCmd(MainUIModuleCmd.HasCompass) then
    Log.Debug("[DungeonStatus] \229\188\128\229\144\175\231\189\151\231\155\152\228\184\173\230\139\146\231\187\157\228\184\173\230\175\146")
    return false
  end
  return true
end

function DungeonStatusComponent:ClearAllDungeonStatus()
  if 0 == self.DungeonStatus then
    return
  end
  local PreStatus = self.DungeonStatus
  self.DungeonStatus = 0
  self:OnDungeonStatusChanged(PreStatus, self.DungeonStatus)
end

function DungeonStatusComponent:OnDungeonStatusChanged(PreStatus, NewStatus, Caster)
  local HadToxicity = 0 ~= PreStatus & 1 << InstanceEnum.DungeonPlayerStatusType.DPST_TOXICITY
  local HasToxicity = 0 ~= NewStatus & 1 << InstanceEnum.DungeonPlayerStatusType.DPST_TOXICITY
  if HadToxicity ~= HasToxicity then
    if HadToxicity then
      self:OnRemoveToxicity(Caster)
    else
      self:OnAddToxicity(Caster)
    end
  end
end

function DungeonStatusComponent:OnAddToxicity(Caster)
  self.RocoSkillComp = self.owner.viewObj.RocoSkill
  self.UseServerID = Caster:GetServerId()
  self:AddToxicityEffect()
  self.CreatePetsTimer = _G.TimerManager:CreateTimer(self, "OnAddToxicity", 99999999, function()
    self:CreateSpecialPets()
  end, nil, 5)
  
  function self.OnSwitchAvatar()
    self:OnAvatarChange()
  end
  
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.BattleOver, self.OnBattleOver)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.SceneEvent.OnPlayerDead, self.OnBornDie)
  local AvatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if AvatarSystem.OnSwitchAvatarSuitComplete then
    AvatarSystem.OnSwitchAvatarSuitComplete:Add(AvatarSystem, self.OnSwitchAvatar)
  end
end

function DungeonStatusComponent:AddToxicityEffect()
  _G.NRCResourceManager:LoadResAsync(self, "/Game/ArtRes/Effects/G6Skill/SceneEffect/Pet/Ecology/G6_Scene_Ecology_Toxicity01_Loop.G6_Scene_Ecology_Toxicity01_Loop_C", _G.PriorityEnum.Active_Player_Action, 0, self.OnLoadedSkill, self.FailedLoad, nil)
end

function DungeonStatusComponent:OnLoadedSkill(_, LoadSkillClass)
  self.RocoSkillComp = self.owner.viewObj.RocoSkill
  self.ToxicitySkillObj = self.RocoSkillComp:FindOrAddSkillObj(LoadSkillClass)
  self.ToxicitySkillObj:SetCaster(self.owner.viewObj)
  self.ToxicitySkillObj:SetPassive(true)
  self.ToxicitySkillObj._playInBigworld = true
  self.RocoSkillComp:PlaySkill(self.ToxicitySkillObj)
  self:CreateSpecialPets(self.TempCaster)
end

function DungeonStatusComponent:TryGetValidAIServerId()
  local ValidServerAI = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByFilter, nil, function(v)
    return v.AIComponent ~= nil
  end)
  if ValidServerAI then
    return ValidServerAI:GetServerId()
  end
  return nil
end

function DungeonStatusComponent:CheckCurAIValid()
  if not self.UseServerID then
    return false
  end
  local NpcDic = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetAllNPC)
  return table.containsKey(NpcDic, self.UseServerID)
end

function DungeonStatusComponent:CreateSpecialPets()
  if not self:CheckCurAIValid() then
    self.UseServerID = self:TryGetValidAIServerId()
    if not self.UseServerID then
      _G.TimerManager:RemoveTimer(self.CreatePetsTimer)
      self.CreatePetsTimer:Clear()
      self.CreatePetsTimer = nil
      return
    end
  end
  local ObjectPos = self.owner.viewObj.sceneCharacter:GetServerPosition()
  local AIManager = _G.SceneAIUtils.GetSceneAIManager()
  
  local function SendRefreshCommand(RefreshId)
    local info = _G.ProtoMessage:newClientAiCommandInfo()
    info.actor_id = self.UseServerID
    info.action_id = _G.Enum.NpcSceneCommandType.NSC_REFRESH_NPC
    info.command_param = RefreshId
    info.pos.x = ObjectPos.x
    info.pos.y = ObjectPos.y
    info.pos.z = ObjectPos.z
    AIManager:EnqueueMessage_SceneCommand(info)
  end
  
  for _ = 0, 3 do
    SendRefreshCommand(5500482)
    SendRefreshCommand(5500483)
  end
end

function DungeonStatusComponent:OnEnterBattle()
  self.CreatePetsTimer:Stop()
  self.RocoSkillComp:CancelSkill(self.ToxicitySkillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
end

function DungeonStatusComponent:OnBattleOver()
  self.CreatePetsTimer:Restart()
  self.RocoSkillComp:CancelSkill(self.ToxicitySkillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
  a.task(function()
    a.wait(au.DelaySeconds(0.5))
    if UE.UObject.IsValid(self.ToxicitySkillObj) then
      self.RocoSkillComp:PlaySkill(self.ToxicitySkillObj)
    else
      self:AddToxicityEffect()
    end
  end)()
end

function DungeonStatusComponent:OnBornDie()
  self:ClearAllDungeonStatus()
end

function DungeonStatusComponent:OnReConnect()
  self.RocoSkillComp:CancelSkill(self.ToxicitySkillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
  a.task(function()
    a.wait(au.DelaySeconds(1))
    if UE.UObject.IsValid(self.ToxicitySkillObj) then
      self.RocoSkillComp:PlaySkill(self.ToxicitySkillObj)
    else
      self:AddToxicityEffect()
    end
  end)()
end

function DungeonStatusComponent:OnAvatarChange()
  self.RocoSkillComp:CancelSkill(self.ToxicitySkillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
  self:AddToxicityEffect()
end

function DungeonStatusComponent:OnRemoveToxicity()
  if self.RocoSkillComp then
    self.RocoSkillComp:CancelSkill(self.ToxicitySkillObj, UE.ESkillActionResult.SkillActionResultInterrupted)
    self.RocoSkillComp = nil
    self.ToxicitySkillObj = nil
    self.UseServerID = nil
  end
  if self.CreatePetsTimer then
    _G.TimerManager:RemoveTimer(self.CreatePetsTimer)
    self.CreatePetsTimer:Clear()
    self.CreatePetsTimer = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.OnBattleOver)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnPlayerDead, self.OnBornDie)
  local AvatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(_G.UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if AvatarSystem.OnSwitchAvatarSuitComplete then
    AvatarSystem.OnSwitchAvatarSuitComplete:Remove(AvatarSystem, self.OnSwitchAvatar)
    self.OnSwitchAvatar = nil
  end
end

return DungeonStatusComponent
