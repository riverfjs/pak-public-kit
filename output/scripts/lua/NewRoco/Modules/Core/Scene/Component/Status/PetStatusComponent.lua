local PetStatusType = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusType")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local BubbleComponent = require("NewRoco.Modules.Core.Scene.Component.Bubble.BubbleComponent")
local AIComponent = require("NewRoco.Modules.Core.Scene.Component.AI.AIComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = ActorComponent
local PetStatusComponent = Base:Extend("PetStatusComponent")

function PetStatusComponent:Ctor()
  Base.Ctor(self)
  self.PlayerPet = nil
  self.CurrentPetData = nil
  self.PrevLocation = nil
  self.PrevSyncTime = 0
  self.WaitStartTime = -1
  self.Type = PetStatusType.None
  self.registeredVisibilityNotify = false
  self.bInteractingWithSwitch = false
end

function PetStatusComponent:Attach(owner)
  Base.Attach(self, owner)
  self:SetEnable(false)
  local Data = self.owner.serverData
  if not Data then
    return
  end
  if self.owner.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME then
    self.GID = Data.home_pet.home_pet_info.pet_gid
  else
    local info = Data.pet_info
    if info then
      self.GID = info.gid
    end
  end
  if self.owner:IsControlledByPlayer() then
    self.CurrentPetData = self:GetPetData()
    _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_DATA, self.OnPetUpdate)
    self.IsControlledByPlayer = true
    self.registeredVisibilityNotify = true
    SceneUtils.RegisterNPCVisibilityNotify(self, true)
  else
    self.IsControlledByPlayer = false
  end
end

function PetStatusComponent:DeAttach()
  if self.registeredVisibilityNotify then
    SceneUtils.UnregisterNPCVisibilityNotify(self)
  end
end

function PetStatusComponent:OnVisible()
  self.owner:SetSignificant(false, UE.ESignificanceValue.Highest)
  if not self.CurrentPetData then
    return
  end
  local Habit = ThrowUtils:GetPetHabitat(self.CurrentPetData)
  if Habit == Enum.HABITAT_FLAG.HAB_LAND then
    local view = self.owner.viewObj
    view:SetShouldCheckWaterSurface(true)
  end
end

function PetStatusComponent:OnInvisible()
  local view = self.owner.viewObj
  if view then
    view:SetShouldCheckWaterSurface(true)
  end
end

function PetStatusComponent:OnPetUpdate()
  if not self.CurrentPetData then
    return
  end
  local New = self:GetPetData()
  if not New then
    return
  end
  if self.CurrentPetData == New then
    return
  end
  if self.CurrentPetData.level ~= New.level then
    self.owner.serverData.base.lv = New.level
    if self.owner.PetHUDComponent then
      self.owner.PetHUDComponent:ForceUpdate()
    end
  end
  if self.CurrentPetData.name ~= New.name then
    self.owner.serverData.base.name = New.name
    if self.owner.PetHUDComponent then
      self.owner.PetHUDComponent:ForceUpdate()
    end
  end
  self:OnPetClosenessUpdate(self.CurrentPetData, New, nil)
  self.CurrentPetData = New
end

function PetStatusComponent:OnSyncPetUpdate(Action)
  local syncNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.pet_npc_obj_id)
  local ownerAvatarUin = Action and Action.owner_avatar_uin and Action.owner_avatar_uin or 0
  local selfUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  if ownerAvatarUin == selfUin then
    self.CurrentPetData = self:GetPetData()
  else
    self.CurrentPetData = _G.ProtoMessage:newPetData()
    self.CurrentPetData.closeness_info.closeness_lv = syncNpc.serverData.pet_info.closeness_lv
  end
  local New = _G.ProtoMessage:newPetData()
  New.closeness_info.closeness_lv = Action.closeness_lv
  self:OnPetClosenessUpdate(self.CurrentPetData, New, syncNpc)
end

function PetStatusComponent:OnPetClosenessUpdate(CurrentPetData, New, syncNpc)
  if CurrentPetData.closeness_info == nil then
    CurrentPetData.closeness_info = {closeness_exp = 0, closeness_lv = 0}
  end
  if nil == CurrentPetData.closeness_info.closeness_lv then
    CurrentPetData.closeness_info.closeness_lv = 0
  end
  if New.closeness_info == nil then
    New.closeness_info = {closeness_exp = 0, closeness_lv = 0}
  end
  if nil == New.closeness_info.closeness_lv then
    New.closeness_info.closeness_lv = 0
  end
  if CurrentPetData.closeness_info.closeness_lv ~= New.closeness_info.closeness_lv then
    self.HeartNum = tostring(New.closeness_info.closeness_lv)
    self.Throw = ThrowSession.GetWithGID(New.gid)
    local PetView
    if self.Throw and self.Throw.NPC then
      PetView = self.Throw.NPC.viewObj
    elseif syncNpc then
      PetView = syncNpc.viewObj
    end
    local SkillComp
    if PetView then
      SkillComp = PetView.RocoSkill
    end
    self.Skill = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/NPC/NPC_Favorability", SkillComp, PriorityEnum.Active_Throw_Pet)
    if not self.Skill then
      Log.Error("PlayerDataModule\230\137\190\228\184\141\229\136\176Skill")
      return
    end
    self.Skill:SetPassive(true)
    self.Skill:SetCaster(PetView)
    self.Skill:RegisterEventCallback("PreStart", self, self.OnSetupBlackboard)
    local isHomePet = self.owner.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME
    local IsPlayingFlag = SkillComp:IsPlayingSkill()
    if IsPlayingFlag or self.Throw and self.Throw.Status == ThrowSessionStatusEnum.Interacting or isHomePet and self.Type == PetStatusType.Wait or nil == self.Throw and self.Type ~= PetStatusType.None then
      if self.Throw then
        self.Throw:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnCheckIsComplete)
      end
      if isHomePet then
        self.owner:AddEventListener(self, NPCModuleEvent.HOME_FEED_SKILL_END, self.OnHomeSkillEnd)
      end
      if syncNpc then
        self.owner:AddEventListener(self, NPCModuleEvent.OnPetStatusChange, self.OnSyncSkillEnd)
      end
    else
      self.Skill:PlaySkill(self, self.OnSkillCallBack)
      if self.Throw then
        self.Throw:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnCheckIsInterup)
      end
    end
    CurrentPetData.closeness_info.closeness_lv = New.closeness_info.closeness_lv
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnUpdatePetClosenessInfo)
  end
end

function PetStatusComponent:OnSetupBlackboard(Name, Skill)
  if not Skill or not Skill.Blackboard then
    return
  end
  local Blackboard = Skill.Blackboard
  Blackboard:SetValueAsString("HeartNum", self.HeartNum)
end

function PetStatusComponent:OnSkillCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("NPCActionOpenPetAltar failed to play skill!", result, skillProxy)
  end
  if self.Throw then
    self.Throw:RemoveEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnCheckIsComplete)
  end
end

function PetStatusComponent:OnCheckIsComplete(Session, Status)
  if not Status or Status == ThrowSessionStatusEnum.PostInteract or Status == ThrowSessionStatusEnum.Interacting then
    self.Skill:PlaySkill(self, self.OnSkillCallBack)
    if self.Throw then
      self.Throw:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnCheckIsInterup)
    end
  end
end

function PetStatusComponent:OnCheckIsInterup(Session, Status)
  if Status == ThrowSessionStatusEnum.Destroyed then
    self.Skill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    if self.Throw then
      self.Throw:RemoveEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnCheckIsInterup)
    end
  elseif Status == ThrowSessionStatusEnum.CriticalInteracting then
    self.Skill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
end

function PetStatusComponent:OnHomeSkillEnd()
  self:OnCheckIsComplete()
  self.owner:RemoveEventListener(self, NPCModuleEvent.HOME_FEED_SKILL_END, self.OnHomeSkillEnd)
end

function PetStatusComponent:OnSyncSkillEnd(NewStatus, OldStatus)
  if NewStatus == PetStatusType.None and OldStatus == PetStatusType.Interact then
    self:OnCheckIsComplete()
    self.owner:RemoveEventListener(self, NPCModuleEvent.OnPetStatusChange, self.OnSyncSkillEnd)
  end
end

function PetStatusComponent:GetPetData()
  return _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.GID)
end

function PetStatusComponent:SetStatus(Type)
  Log.Debug("PetStatusComponent:SetStatus", self.owner.ThrowSession and self.owner.ThrowSession.SeqID, table.getKeyName(PetStatusType, Type))
  if Type == self.Type then
    return
  end
  if self.Type == PetStatusType.Wait then
    local Comp = self.owner:EnsureComponent(BubbleComponent)
    Comp:StopAll()
    local AIComp = self.owner:EnsureComponent(AIComponent)
    if AIComp then
      AIComp:ForceLockForReason(false, false, AIDefines.LockReason.WAITING)
    end
    self.WaitStartTime = -1
  end
  if Type == PetStatusType.Wait then
    local Comp = self.owner:EnsureComponent(BubbleComponent)
    Comp:Play(nil, Enum.EmotionType.EMT_DENGDAI)
    local AIComp = self.owner:EnsureComponent(AIComponent)
    if AIComp then
      AIComp:ForceLockForReason(true, false, AIDefines.LockReason.WAITING)
    end
    self.WaitStartTime = _G.UpdateManager.Timestamp
    local Session = self.owner.ThrowSession
    if Session then
      Session:ForceSetCanBeRecycle(true)
    end
  end
  if Type == PetStatusType.Interact then
    if self.owner and self.owner.InteractionComponent then
      self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.NPC_IS_BUSY)
    end
  else
    self.owner.InteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.NPC_IS_BUSY)
  end
  local OldType = self.Type
  self.Type = Type
  self.owner:SendEvent(NPCModuleEvent.OnPetStatusChange, Type, OldType)
end

function PetStatusComponent:OnDistanceOptimize(sqrDistanceIgnoreZ, viewDotValue, sqrDistance, distanceRatio)
  if not self.IsControlledByPlayer then
    return
  end
  if not self.owner then
    self.PrevLocation = nil
    return
  end
  local LuaObj = self.owner.luaObj
  if not LuaObj then
    self.PrevLocation = nil
    return
  end
  local CurrentTime = os.time()
  if CurrentTime - self.PrevSyncTime <= 2 then
    return
  end
  if self.owner and self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() then
    return
  end
  local CurrentLocation = self.owner:GetActorLocation()
  if self.PrevLocation then
    local DX = CurrentLocation.X - self.PrevLocation.X
    local DY = CurrentLocation.Y - self.PrevLocation.Y
    if DX * DX + DY * DY > 100.0 then
      LuaObj:SendPosToServer(_G.ProtoEnum.SetNpcPosType.SNPT_AI_PET_FOLLOW)
      self.PrevSyncTime = CurrentTime
    end
  end
  self.PrevLocation = CurrentLocation
  if self.Type == PetStatusType.Wait then
    if self.WaitStartTime > 0 then
      if _G.UpdateManager.Timestamp - self.WaitStartTime > 30 and self.owner.ThrowSession then
        self.owner.ThrowSession:Recycle()
      end
    else
      self.WaitStartTime = _G.UpdateManager.Timestamp
    end
  end
end

function PetStatusComponent:DeAttach()
  self.Throw = nil
  Base.DeAttach(self)
end

function PetStatusComponent:Destroy()
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_DATA, self.OnPetUpdate)
  self.PlayerPet = nil
  self.CurrentPetData = nil
  Base.Destroy(self)
end

function PetStatusComponent:CanInteract()
  return self.Type == PetStatusType.None
end

return PetStatusComponent
