require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.Instance.BP_NPCInstanceMechanismBase_C")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local BP_NPC_Movable_C = Base:Extend("BP_NPC_Movable_C")

function BP_NPC_Movable_C:Ctor()
  Base.Ctor(self)
  self.targetPos = nil
  self.speed = 0
  self.SoundSession = -1
end

function BP_NPC_Movable_C:UpdateState(bInit)
  local npc = self.sceneCharacter
  if npc then
    local logicStatusComp = npc:EnsureComponent(LogicStatusComponent)
    local state, _, extraData = logicStatusComp:GetStatus(Enum.SpaceActorLogicStatus.SALS_LEVEL_POS_CHANGED)
    if state then
      if extraData and extraData.type == Enum.LogicStatusExtraDataType.LSEDT_LEVEL_POS then
        local pos = extraData.level_pos.pos_info
        local time = extraData.level_pos.time
        if 0 == time then
          time = 1
        end
        self.targetPos = pos and UE.FVector(pos[1], pos[2], pos[3]) or npc.landPos
        if bInit then
          self:Abs_K2_SetActorLocation_WithoutHit(self.targetPos, true)
          Log.Debug("[BP_NPC_Movable] \229\136\157\229\167\139\229\140\150\228\189\141\231\189\174\232\174\190\231\189\174")
        else
          local selfPos = self:Abs_K2_GetActorLocation()
          local distance = UE.FVector.Dist(selfPos, self.targetPos)
          self.speed = distance / time
          if self.speed <= 1.0E-4 then
            Log.Debug("[BP_NPC_Movable] \229\183\178\231\187\143\229\156\168\233\162\132\230\156\159\228\189\141\231\189\174")
            return
          end
          UpdateManager:Register(self)
          self:PlayMoveSound()
          Log.Debug("[BP_NPC_Movable] \229\188\128\229\167\139\231\167\187\229\138\168\239\188\140\233\162\132\232\174\161\230\151\182\233\151\180:%f \232\183\157\231\166\187:%f", time, distance)
        end
      else
        self:Abs_K2_SetActorLocation_WithoutHit(npc.landPos, true)
      end
    elseif bInit then
      self:Abs_K2_SetActorLocation_WithoutHit(npc.landPos, false)
    end
  end
  Base.UpdateState(self)
end

function BP_NPC_Movable_C:OnTick(deltaTime)
  if self.targetPos then
    local selfPos = self:Abs_K2_GetActorLocation()
    local dir = self.targetPos - selfPos
    local dist = dir:Size()
    if dist < 1.0 then
      UpdateManager:UnRegister(self)
      self:Abs_K2_SetActorLocation_WithoutHit(self.targetPos)
      self.targetPos = nil
      self.speed = 0
      Log.Debug("[BP_NPC_Movable] \231\167\187\229\138\168\231\187\147\230\157\159")
      self:StopMoveSound()
      if self.sceneCharacter then
        self.sceneCharacter.luaObj:SendPosToServer()
        _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.ConsumeCachedActorTag, self.sceneCharacter:GetServerId())
      end
      return
    end
    dir:Normalize()
    local ratio = math.min(dist, deltaTime * self.speed)
    dir = dir * ratio
    dir = dir + selfPos
    self:Abs_K2_SetActorLocation_WithoutHit(dir)
  else
    UpdateManager:UnRegister(self)
  end
end

function BP_NPC_Movable_C:ReceiveEndPlay()
  UpdateManager:UnRegister(self)
  self:StopMoveSound()
  Base.ReceiveEndPlay(self)
end

function BP_NPC_Movable_C:Recycle()
  self:StopMoveSound()
  Base.Recycle(self)
end

function BP_NPC_Movable_C:PlayMoveSound()
  self.SoundSession = NRCAudioManager:PlaySound3DWithActor(self.MoveSound, self, "BP_NPC_Movable_C", false, false)
end

function BP_NPC_Movable_C:StopMoveSound()
  if self.SoundSession > 0 then
    NRCAudioManager:ReleaseSession(self.SoundSession, true, "BP_NPC_Movable_C")
    self.SoundSession = -1
  end
end

function BP_NPC_Movable_C:DeactivateEvent()
end

function BP_NPC_Movable_C:ActivateEvent()
end

return BP_NPC_Movable_C
