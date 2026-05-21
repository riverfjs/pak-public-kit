local NPCActionModelBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ResQueue = require("NewRoco.Utils.ResQueue")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local Base = NPCActionModelBase
local NPCActionTeleportSuitcase = Base:Extend("NPCActionTeleportSuitcase")

function NPCActionTeleportSuitcase:Ctor(Owner, Config, Info, View)
  Base.Ctor(self, Owner, Config, Info, View)
  self.TeleportFailed = false
  self.TeleportSuccess = false
end

function NPCActionTeleportSuitcase:OnSubmit(Rsp)
  Base.OnSubmit(self, Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    self:Finish(false)
    return
  end
  local Player = self:GetPlayer()
  if not Player then
    self:Finish(false)
    return
  end
  if Player:IsInTogetherMove() then
    self.bIsDoubleJump = true
    self.bIsDoubleJump2P = Player:IsTogetherMove2P()
    self.Player2P = Player:GetAnotherTogetherMovePlayer()
  end
  if Player.isLocal then
    self:SyncAction()
  end
  self:PlayJumpBoxAnim()
end

function NPCActionTeleportSuitcase:GetSkillPath()
  local Player = self:GetPlayer()
  local SkillPath = "/Game/ArtRes/Effects/G6Skill/ScenePlay/G6_JumpInBox.G6_JumpInBox"
  if self.bIsDoubleJump then
    self.Player2P = Player:GetAnotherTogetherMovePlayer()
    if self.Player2P then
      self.Player2PPos = self.Player2P:GetActorLocation()
      SkillPath = "/Game/ArtRes/Effects/G6Skill/ScenePlay/G6_JumpInBox_2P.G6_JumpInBox_2P"
    end
  end
  return SkillPath
end

function NPCActionTeleportSuitcase:PlayJumpBoxAnim()
  local OwnerView = self:GetOwnerNPCView()
  local Player = self:GetPlayer()
  if not Player or not OwnerView then
    self:Finish(false)
    return
  end
  if OwnerView.SwitchMesh then
    OwnerView:SwitchMesh(false)
  end
  self.PlayerPos = Player:GetActorLocation()
  local SkillPath = self:GetSkillPath()
  self.Skill = RocoSkillProxy.Create(SkillPath, OwnerView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not self.Skill then
    self:Finish(false)
    return
  end
  if Player.inputComponent then
    Player.inputComponent:SetInputEnable(self, false, "ActionTeleportSuitcase")
  end
  if Player.playerHomeInteractionComponent then
    Player.playerHomeInteractionComponent:SetCollisionEnable(false)
  end
  self.Skill:SetCaster(Player.viewObj)
  local Characters = {}
  Characters[UE4.EBattleStaticActorType.Player_1] = Player.viewObj
  Player:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, false, PlayerModuleEvent.LinkReasonFlags.ACT_OPEN_SUITCASE)
  if self.Player2P then
    Characters[UE4.EBattleStaticActorType.Player_2] = self.Player2P.viewObj
  end
  self.Skill:SetCharacters(Characters)
  self.Skill:SetTargets({OwnerView})
  self.Skill:RegisterEventCallback("PreStart", self, self.OnSetupBlackboard)
  self.Skill:RegisterEventCallback("StartTeleport", self, self.OnStartTeleport)
  self.Skill:RegisterEventCallback("FailedTeleport", self, self.OnFailedTeleport)
  self.Skill:RegisterEventCallback("End", self, self.OnSkillFinished)
  self.Skill:PlaySkill()
  self.OwnerNpc.InteractionComponent:TryDisableInteraction()
  self.OwnerNpc:SetNotDestroyFlag(true)
end

function NPCActionTeleportSuitcase:OnSetupBlackboard(Name, Skill)
  local Player = self:GetPlayer()
  if Player and Player.isLocal then
    Skill.Blackboard:SetValueAsString("Is1P", "Is1P")
  end
end

function NPCActionTeleportSuitcase:OnSkillFinished()
  self.OwnerNpc:SetNotDestroyFlag(false)
  self.OwnerNpc.InteractionComponent:TryEnableInteraction()
  local Player = self:GetPlayer()
  if Player then
    Player:SendEvent(PlayerModuleEvent.ON_SET_LINK_STATE, true, PlayerModuleEvent.LinkReasonFlags.ACT_OPEN_SUITCASE)
    if Player.inputComponent then
      Player.inputComponent:SetInputEnable(self, true, "ActionTeleportSuitcase")
    end
    if Player.playerHomeInteractionComponent then
      Player.playerHomeInteractionComponent:SetCollisionEnable(true)
    end
  end
  if self.TeleportSuccess then
    return
  end
  if not self.TeleportFailed then
    self:Finish(false)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.S1_prop_teleport_fail)
  local Owner = self:GetOwnerNPC()
  local OwnerView = self:GetOwnerNPCView()
  if not (Owner and Player) or not OwnerView then
    return
  end
  local SkillPath = "/Game/ArtRes/Effects/G6Skill/ScenePlay/G6_JumpInBox_False.G6_JumpInBox_False"
  self.FailedSkill = RocoSkillProxy.Create(SkillPath, OwnerView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not self.FailedSkill then
    return
  end
  self.FailedSkill:SetCaster(Player.viewObj)
  if self.Player2P then
    self.FailedSkill:SetTargets({
      self.Player2P.viewObj
    })
  else
    self.FailedSkill:SetTargets({})
  end
  self.FailedSkill:RegisterEventCallback("End", self, self.OnFailedSkillFinished)
  self.FailedSkill:PlaySkill()
end

function NPCActionTeleportSuitcase:OnStartTeleport()
  if self:IsLocalAction() then
    self:Finish(true)
  else
    self.Skill:CancelSkill(UE4.ESkillActionResult.SkillActionResultSuccessful)
  end
end

function NPCActionTeleportSuitcase:OnFailedTeleport()
  self.TeleportFailed = true
end

function NPCActionTeleportSuitcase:OnFailedSkillFinished()
  local Player = self:GetPlayer()
  if not Player then
    return
  end
  Player:SetActorLocation(self.PlayerPos)
  if self.Player2P and self.Player2PPos then
    self.Player2P:SetActorLocation(self.Player2PPos)
  end
end

function NPCActionTeleportSuitcase:OnCommit(rsp)
  Base.OnCommit(self, rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.S1_prop_teleport_fail)
  else
    self.TeleportSuccess = true
  end
end

return NPCActionTeleportSuitcase
