local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = require("NewRoco.Modules.System.Dialogue.Action.Timeline.DialogueTimelineActionEvent")
local DialogueTimelineCameraSetupEvent = Base:Extend("DialogueTimelineCameraSetupEvent")
FsmUtils.MergeMembers(Base, DialogueTimelineCameraSetupEvent, {
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
  },
  {
    name = "BlendType",
    type = Enum.CameraBlendType,
    default = Enum.CameraBlendType.CBT_NONE,
    display_name = "\229\136\135\230\141\162\230\150\185\229\188\143"
  },
  {
    name = "BlendExp",
    type = "float",
    default = 1.0,
    display_name = "\231\188\147\229\138\168\229\143\130\230\149\176"
  },
  {
    name = "SkipUserClick",
    type = "bool",
    default = false,
    display_name = "\229\191\189\231\149\165\229\189\147\229\137\141\233\149\156\229\164\180\232\183\179\232\191\135"
  }
})

function DialogueTimelineCameraSetupEvent:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.CameraType = nil
end

function DialogueTimelineCameraSetupEvent:OnEnter()
  Base.OnEnter(self)
  if DialogueUtils.SkipDialogue then
    self:Finish()
    return
  end
  self.Player = DialogueUtils.GetPlayer()
  self.TargetNPC = self.fsm:GetProperty("TargetNPC")
  self.ParentModule = self.fsm:GetProperty("ParentModule")
  self.Controller = DialogueUtils.GetController(self.Player)
  if self.ParentModule.CameraParent then
    local CameraActor = DialogueUtils.GetController(self.Player).CameraActor
    if CameraActor then
      local CameraComp = CameraActor:GetComponentByClass(UE4.UCameraComponent)
      CameraComp:K2_AttachTo(self.ParentModule.CameraParent)
      self.ParentModule.CameraParent = nil
    end
  end
  if not self.Controller then
    self:Finish()
    return
  end
  self.Controller:SetFadeEnable(false)
  self:OnSwitchInStart()
end

function DialogueTimelineCameraSetupEvent:OnFinish()
  Base.OnFinish(self)
end

function DialogueTimelineCameraSetupEvent:OnSwitchInStart()
  self:OnSwitchInFinish()
end

function DialogueTimelineCameraSetupEvent:OnSwitchInFinish()
  self:SetupCamera()
end

function DialogueTimelineCameraSetupEvent:SetupCamera()
  local Config = NRCModuleManager:DoCmd(CameraModuleCmd.CreateCameraRequestConfig)
  Config.NpcTarget = self.TargetNPC
  Config.PlayerTarget = DialogueUtils.GetHero()
  Config.InputComponent = self.Player.inputComponent
  Config.bTickCameraInModule = false
  Config.CameraType = self.CameraType
  Config.CameraUser = self.ParentModule
  Config.CallbackCaller = self
  Config.bSetUpAndFinish = true
  Config.BlendType = self.BlendType
  if self.BlendType == Enum.CameraBlendType.CBT_NONE then
    Config.BlendTime = 0
    Config.BlendExp = 0
  else
    Config.BlendTime = math.abs(self.EndTime - self.StartTime)
    Config.BlendExp = self.BlendExp
  end
  Config.fsm = self.fsm
  self:FillCameraRequestParams(Config)
  NRCModuleManager:DoCmd(CameraModuleCmd.RequestCamera, Config)
end

function DialogueTimelineCameraSetupEvent:FillCameraRequestParams()
end

return DialogueTimelineCameraSetupEvent
