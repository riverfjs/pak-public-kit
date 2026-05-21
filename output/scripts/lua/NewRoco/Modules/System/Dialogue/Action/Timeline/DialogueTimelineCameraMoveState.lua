local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionState")
local DialogueTimelineCameraMoveState = Base:Extend("DialogueTimelineCameraMoveState")
FsmUtils.MergeMembers(Base, DialogueTimelineCameraMoveState, {
  {
    name = "OwnerActorID",
    type = "SheetRef.NPC_CONF",
    default = -101,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ID"
  },
  {
    name = "NPCContentID",
    type = "SheetRef.NPC_REFRESH_CONTENT_CONF",
    default = -1,
    display_name = "\230\137\128\229\177\158\232\167\146\232\137\178ContentID"
  }
})

function DialogueTimelineCameraMoveState:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.CameraMotionType = nil
end

function DialogueTimelineCameraMoveState:OnEnter()
  Base.OnEnter(self)
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  self.Player = DialogueUtils.GetPlayer()
  self.bInBattle = self.fsm:GetProperty("bInBattle")
  self.TargetNPC = self.fsm:GetProperty("TargetNPC")
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.TargetNPCBP = self.fsm:GetProperty("TargetNpcBp")
  if not self.bInBattle and self.TargetNPC then
    self.TargetNPCBP = self.TargetNPC.viewObj
  end
  if self.bInBattle then
    self.Controller = UE4.UGameplayStatics.GetPlayerController(UE4Helper.GetCurrentWorld(), 0)
  else
    self.Controller = DialogueUtils.GetController(self.Player)
  end
  if not self.Controller or not self.TargetNPCBP then
    self:Finish()
    return
  end
  local CameraHolder = _G.NRCModuleManager:DoCmd(_G.CameraModuleCmd.GetCameraHolder)
  if CameraHolder then
    CameraActor = CameraHolder:GetCurrentCamera()
  end
  if not UE.UObject.IsValid(CameraActor) then
    CameraActor = DialogueUtils.GetController(self.Player).CameraActor
  end
  if CameraActor then
    self.CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    self.SpringArmComp = CameraActor:GetComponentByClass(UE4.URocoSpringArmComponent)
  else
    Log.Error("DialogueTimelineCameraMoveState:OnEnter no CameraActor found")
  end
  local CameraMotionInfo = NRCModuleManager:DoCmd(CameraModuleCmd.FillCameraMotionInfo, self.CameraMotionType)
  if self:FillCameraMotionRequestParams(CameraMotionInfo) then
    NRCModuleManager:DoCmd(CameraModuleCmd.StartCameraMotion, CameraMotionInfo)
  end
end

function DialogueTimelineCameraMoveState:OnFinish()
  Base.OnFinish(self)
end

function DialogueTimelineCameraMoveState:FillCameraMotionRequestParams(CameraMotionInfo)
end

return DialogueTimelineCameraMoveState
