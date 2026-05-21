local NPCActionModelBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local Base = NPCActionModelBase
local NPCActionExitAlchemy = Base:Extend("NPCActionOpenAlchemy")

function NPCActionExitAlchemy:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

local HandInHandSkill = "/Game/ArtRes/Effects/G6Skill/Alchemy/ExitAlchemy.ExitAlchemy"
local SingleSkill = "/Game/ArtRes/Effects/G6Skill/Alchemy/ExitAlchemySingle.ExitAlchemySingle"

function NPCActionExitAlchemy:ExecuteWithModel()
  local IronPan = self:GetOwnerNPCView()
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RegisterIronPan, IronPan)
  local player = self:GetPlayer()
  local playerView = player and player.viewObj
  local skillComp = playerView and playerView.RocoSkill
  local statusComponent = player and player.statusComponent
  local isHandInHand = statusComponent and statusComponent:HasAnyStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND, _G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) or false
  local skillProxy, performId
  if isHandInHand then
    skillProxy = RocoSkillProxy.Create(HandInHandSkill, skillComp, _G.PriorityEnum.Active_Player_Action)
    skillProxy:RegisterEventCallback("Recover", self, self.RecoverPlayerPos)
    skillProxy:RegisterEventCallback("BlackScreen", self, self.BlackScreen)
    performId = 113
  else
    skillProxy = RocoSkillProxy.Create(SingleSkill, skillComp, _G.PriorityEnum.Active_Player_Action)
    performId = 115
    player:ForgetPlayerPos()
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.PlayPerformById, performId, self, self.EndAction, skillProxy)
end

function NPCActionExitAlchemy:RecoverPlayerPos()
  local player = self:GetPlayer()
  if player then
    player:RecoverPlayerPos()
  end
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ReleaseCamera)
end

function NPCActionExitAlchemy:EndAction()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:K2_DetachFromActor(UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld)
  localPlayer.viewObj:SetActorEnableCollision(true)
  _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UnRegisterIronPan)
  localPlayer:StopAllMontage(0.1)
  self:ReLinkHand()
  self:Finish()
end

function NPCActionExitAlchemy:BlackScreen(Event, Skill)
  local DialogueConf = {}
  local ExtraConf = {}
  DialogueConf.speed = 0
  ExtraConf.fade_in_speed = 100
  ExtraConf.fade_out_speed = 4
  ExtraConf.show_time = 0.1
  ExtraConf.numberCharacter = 30
  ExtraConf.autoCloseOff = true
  _G.NRCModuleManager:DoCmd(_G.CampingModuleCmd.ShowBlackScreen, DialogueConf, nil, ExtraConf)
end

return NPCActionExitAlchemy
