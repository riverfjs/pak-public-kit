local Base = require("NewRoco.Modules.System.Home.Res.NRCHomePlacementActor_C")
local BehaviourTriggerFurniture = Base:Extend("BehaviourTriggerFurniture")
local EnmBehaviourStatus = {
  None = 0,
  Playing = 1,
  Stopping = 2
}

function BehaviourTriggerFurniture:OnConstruct()
  self.BehaviourStatus = EnmBehaviourStatus.None
  self.DesiredBehaviourStatus = EnmBehaviourStatus.None
end

function BehaviourTriggerFurniture:ReceiveBeginPlay()
  Base.ReceiveBeginPlay(self)
  self.TriggerActors = {}
end

function BehaviourTriggerFurniture:ReceiveEndPlay()
  Base.ReceiveEndPlay(self)
end

function BehaviourTriggerFurniture:CanTrigger(OverlappedActor)
  local RoomId = self.PropsData and self.PropsData.RoomId
  if RoomId and RoomId == HomeIndoorSandbox.World:GetPlayerRoomId() and not HomeIndoorSandbox.HomeEditServ:InEditMode() then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.viewObj == OverlappedActor then
      return true
    end
  end
end

function BehaviourTriggerFurniture:OnBeginTriggerBehaviour(OverlappedActor)
  if self:CanTrigger(OverlappedActor) then
    local BeforeNoTriggers = not next(self.TriggerActors)
    self.TriggerActors[OverlappedActor] = true
    if BeforeNoTriggers then
      self:StartBehaviour()
    end
  end
end

function BehaviourTriggerFurniture:OnEndTriggerBehaviour(OverlappedActor)
  self.TriggerActors[OverlappedActor] = nil
  local AfterNoTriggers = not next(self.TriggerActors)
  if AfterNoTriggers then
    self:StopBehaviour()
  end
end

function BehaviourTriggerFurniture:StartBehaviour()
  if self.BehaviourStatus ~= EnmBehaviourStatus.Playing then
    self.DesiredBehaviourStatus = EnmBehaviourStatus.Playing
    self:SingleStep()
  end
end

function BehaviourTriggerFurniture:StopBehaviour()
  if self.BehaviourStatus == EnmBehaviourStatus.Playing then
    self.DesiredBehaviourStatus = EnmBehaviourStatus.Stopping
    self:SingleStep()
  end
end

function BehaviourTriggerFurniture:OnBehaviourBegin()
  self.BehaviourStatus = EnmBehaviourStatus.Playing
  self:SingleStep()
end

function BehaviourTriggerFurniture:OnBehaviourFinish()
  self.BehaviourStatus = EnmBehaviourStatus.Stopping
  self:SingleStep()
end

function BehaviourTriggerFurniture:SingleStep()
  if self.BehaviourStatus == EnmBehaviourStatus.Playing then
    if self.DesiredBehaviourStatus == EnmBehaviourStatus.Stopping then
      self:DoStopBehaviour()
    end
  elseif self.DesiredBehaviourStatus == EnmBehaviourStatus.Playing then
    self:DoStartBehaviour()
  end
end

function BehaviourTriggerFurniture:DoStartBehaviour()
end

function BehaviourTriggerFurniture:DoStopBehaviour()
end

return BehaviourTriggerFurniture
