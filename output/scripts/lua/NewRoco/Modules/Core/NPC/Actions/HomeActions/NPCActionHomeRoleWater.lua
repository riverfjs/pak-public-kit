local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmConst = require("NewRoco.Modules.System.Farm.FarmConst")
local ResQueue = require("NewRoco.Utils.ResQueue")
local Base = NPCActionBase
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local NPCActionHomeRoleWater = Base:Extend("NPCActionHomeRoleWater")

function NPCActionHomeRoleWater:Ctor(Owner, Config, Info, View)
  Base.Ctor(self, Owner, Config, Info, View)
  self.shouldSync = true
end

function NPCActionHomeRoleWater:Execute(playerId, needSendReq)
  Base.Execute(self, playerId, needSendReq)
  local Player = self:GetPlayer()
  self.LoadQueue = ResQueue()
  self.LoadQueue:InsertObject("Wand", Player:GetCurWandPath(), _G.PriorityEnum.Active_Player_Action)
  self.LoadQueue:InsertObject("MoZhang", "Blueprint'/Game/NewRoco/Modules/Core/NPC/MagicStar/BP_MoZhang.BP_MoZhang_C'", _G.PriorityEnum.Active_Player_Action)
  self.LoadQueue:StartLoad(self, self.OnLoadFinish)
  self.ReduceTime = FarmUtils.GetWateringReduceTimeCurrent(self.OwnerNpc:GetFarmLandId())
end

function NPCActionHomeRoleWater:OnSubmit(rsp)
  Base.OnSubmit(self, rsp)
end

function NPCActionHomeRoleWater:OnLoadFinish(Queue, Success)
  if not Success then
    Log.Error("NPCActionHomeRoleWater Load Failed!!!!")
    self:Finish(false)
    return
  end
  Log.Debug("NPCActionHomeRoleWater:StartSkill")
  local player = self:GetPlayer()
  if not player then
    Log.Error("NPCActionHomeRoleWater:StartSkill \230\137\190\228\184\141\229\136\176player")
    self:Finish(false)
    return
  end
  local owner = self:GetOwnerNPC()
  if not owner or not owner.viewObj then
    Log.Error("NPCActionHomeRoleWater:StartSkill \230\137\190\228\184\141\229\136\176owner")
    self:Finish(false)
    return
  end
  local land_id = self.OwnerNpc:GetFarmLandId()
  if not land_id then
    Log.Error("NPCActionHomeRoleWater:StartSkill \230\137\190\228\184\141\229\136\176land_id")
    self:Finish(false)
    return
  end
  local targets = {}
  local landNPC = FarmUtils.GetLandNPC(land_id)
  table.insert(targets, landNPC and landNPC.viewObj)
  local skillComp = player.viewObj.RocoSkill
  local skill = RocoSkillProxy.Create(FarmConst.SkillPath.Watering, skillComp)
  if not skill then
    Log.Error("NPCActionHomeRoleWater:StartSkill \230\137\190\228\184\141\229\136\176Skill")
    self:Finish(false)
    return
  end
  skill:SetWithLoadAndPlay(true)
  skill:SetCaster(player.viewObj)
  skill:SetTargets(targets)
  skill:SetPassive(true)
  skill:RegisterEventCallback("PreStart", self, self.OnSetupBlackboard)
  skill:RegisterEventCallback("PreEndAnim", self, self.SkillComplete)
  skill:RegisterEventCallback("PreEnd", self, self.SkillComplete)
  skill:RegisterEventCallback("End", self, self.SkillComplete)
  skill:RegisterEventCallback("Interrupt", self, self.OnInterrupted)
  skill:PlaySkill(self, self.OnSkillStart)
  _G.NRCEventCenter:RegisterEvent("NPCActionHomeRoleWater", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function NPCActionHomeRoleWater:OnSkillStart(Skill, Result)
  if Result == UE.ESkillStartResult.Success then
    self.SkillStarted = true
  else
    self:SkillFailed()
  end
end

function NPCActionHomeRoleWater:OnSetupBlackboard(Name, Skill)
  if not Skill or not Skill.Blackboard then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local fTransform = UE4.FTransform(UE4.FQuat(), UE4.FVector(-10000, -10000, -10000))
  local MoZhangActor = World:Abs_SpawnActor(self.LoadQueue:Get("MoZhang"), fTransform, UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, nil, nil, nil, {})
  MoZhangActor.SkeletalMesh:SetSkeletalMesh(self.LoadQueue:Get("Wand"))
  Skill.Blackboard:SetValueAsObject("mozhang", MoZhangActor)
end

function NPCActionHomeRoleWater:SkillFailed()
  Log.Error("NPCActionHomeRoleWater:SkillFailed")
  self.SkillStarted = false
  self:SkillComplete()
end

function NPCActionHomeRoleWater:SkillComplete(Name, Skill)
  self.SkillStarted = false
  if self.ReduceTime then
    local LandID = self.OwnerNpc:GetFarmLandId()
    local ReduceTime = self.ReduceTime
    self.ReduceTime = nil
    a.task(function()
      a.wait(au.DelaySeconds(0.3))
      FarmUtils.AddFloatingText(LandID, ReduceTime)
    end)()
  end
  self:Finish(true)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

function NPCActionHomeRoleWater:OnInterrupted(Name, Skill)
  Log.Error("NPCActionHomeRoleWater:OnInterrupted")
  self.SkillStarted = false
  self:SkillComplete()
end

function NPCActionHomeRoleWater:OnReconnect()
  Log.Error("NPCActionHomeRoleWater:OnReconnect need to complete skill!")
  self.SkillStarted = false
  self:Finish(true)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
end

return NPCActionHomeRoleWater
