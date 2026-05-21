require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.Instance.BP_NPCInstanceMechanismBase_C")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local BP_NPCInstanceMovable_C = Base:Extend("BP_NPCInstanceMovable_C")

function BP_NPCInstanceMovable_C:Ctor()
  Base.Ctor(self)
  self.targetPos = nil
  self.speed = 0
  self.enabledTick = false
end

function BP_NPCInstanceMovable_C:ReceiveEndPlay()
  self:UnRegisterTick()
  Base.ReceiveEndPlay(self)
end

function BP_NPCInstanceMovable_C:UpdateState(bInit)
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
          Log.PrintScreenMsg("[BP_NPCInstanceMovable_C]\231\137\169\228\187\182\228\189\141\231\189\174\229\188\186\229\136\182\230\155\180\230\150\176")
        else
          local selfPos = self:Abs_K2_GetActorLocation()
          local distance = UE.FVector.Dist(selfPos, self.targetPos)
          self.speed = distance / time
          if self.speed <= 1.0E-4 then
            Log.Debug("[BP_NPCInstanceMovable_C] \229\183\178\231\187\143\229\156\168\233\162\132\230\156\159\228\189\141\231\189\174")
            return
          end
          self:RegisterTick()
          Log.PrintScreenMsg("[BP_NPCInstanceMovable_C]\231\137\169\228\187\182\231\167\187\229\138\168\228\184\173\239\188\140\233\162\132\232\174\161\230\151\182\233\151\180:%f \232\183\157\231\166\187:%f", time, distance)
        end
      else
        self:Abs_K2_SetActorLocation_WithoutHit(npc.landPos, true)
      end
    elseif bInit then
      self:Abs_K2_SetActorLocation_WithoutHit(npc.landPos, false)
    end
  end
  Base.UpdateState(self, bInit)
end

function BP_NPCInstanceMovable_C:OnTick(deltaTime)
  if self.targetPos then
    local selfPos = self:Abs_K2_GetActorLocation()
    local dir = self.targetPos - selfPos
    local dist = dir:Size()
    if dist < 1.0 then
      self:UnRegisterTick()
      self:Abs_K2_SetActorLocation_WithoutHit(self.targetPos)
      self.targetPos = nil
      self.speed = 0
      Log.Warning("[BP_NPCInstanceMovable_C]\231\137\169\228\187\182\231\167\187\229\138\168\231\187\147\230\157\159")
      if self.sceneCharacter then
        self.sceneCharacter.luaObj:SendPosToServer()
      end
      return
    end
    dir:Normalize()
    local ratio = math.min(dist, deltaTime * self.speed)
    dir = dir * ratio
    dir = dir + selfPos
    self:Abs_K2_SetActorLocation_WithoutHit(dir)
  else
    self:UnRegisterTick()
  end
end

function BP_NPCInstanceMovable_C:RegisterTick()
  if self.enabledTick then
    return
  end
  UpdateManager:Register(self)
  self.enabledTick = true
end

function BP_NPCInstanceMovable_C:UnRegisterTick()
  if not self.enabledTick then
    return
  end
  self.enabledTick = false
  UpdateManager:UnRegister(self)
end

return BP_NPCInstanceMovable_C
