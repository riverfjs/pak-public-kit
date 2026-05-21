local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = NPCActionBase
local NPCActionBlindBoxIn = Base:Extend("NPCActionBlindBoxIn")

function NPCActionBlindBoxIn:Ctor(Owner, Config, Info, OwnerNpc)
  Base.Ctor(self, Owner, Config, Info, OwnerNpc)
end

function NPCActionBlindBoxIn:Execute(PlayerID, NeedSendReq)
  if not self.OwnerNpc then
    return
  end
  local Player = self:GetPlayer()
  if Player.statusComponent:HasAnyStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM, Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING) then
    if self.Owner then
      self.Owner:SetNeedStatusNotify(false)
    end
    local Msg = LuaText.relationtree_abnormal_status_tip
    if Msg then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Msg)
    end
    return
  end
  if Player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_HAND_IN_HAND) then
    Player.InviteComponent:InteractCancel()
  end
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RecycleAllThrowPets)
  Base.Execute(self, PlayerID, NeedSendReq)
end

function NPCActionBlindBoxIn:OnSubmit(Rsp)
  Base.OnSubmit(self, Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    self:Finish(false)
    return
  end
  Log.Debug("NPCActionBlindBoxIn:UpdateInfo", "\231\142\169\229\174\182\230\136\144\229\138\159\233\146\187\229\133\165\231\174\177\229\173\144")
  local Player = self:GetPlayer()
  if not Player then
    self:Finish(false)
    return
  end
  self:PlayJumpBoxAnim()
end

function NPCActionBlindBoxIn:PlayJumpBoxAnim()
  local OwnerView = self:GetOwnerNPCView()
  local Player = self:GetPlayer()
  if not Player or not OwnerView and not self.OwnerNpc then
    self:Finish(false)
    return
  end
  local Conf = _G.DataConfigManager:GetRoleplayPropConf(self.OwnerNpc.config.id)
  if not Conf then
    self:Finish(false)
    return
  end
  local SkillPath = Conf.blindbox_open_pos or "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_WanJu_XiaRenXiang_Open.G6_WanJu_XiaRenXiang_Open"
  local Skill = RocoSkillProxy.Create(SkillPath, OwnerView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not Skill then
    self:Finish(false)
    return
  end
  if Player.inputComponent then
    Player.inputComponent:SetInputEnable(self, false, "ActionBlindBoxIn")
  end
  if Player.playerHomeInteractionComponent then
    Player.playerHomeInteractionComponent:SetCollisionEnable(false)
  end
  Player:SetCharacterMovementTickEnable(self, false)
  Skill:SetCaster(Player.viewObj)
  Skill:SetTargets({OwnerView})
  Skill:RegisterEventCallback("End", self, self.OnSkillFinished)
  Skill:PlaySkill()
  self.OwnerNpc.InteractionComponent:TryDisableInteraction()
  self.OwnerNpc:SetNotDestroyFlag(true)
end

function NPCActionBlindBoxIn:OnSkillFinished()
  local Player = self:GetPlayer()
  if not Player then
    self:Finish(false)
    return
  end
  Player:SetCharacterMovementTickEnable(self, true)
  local OwnerView = self:GetOwnerNPCView()
  if not OwnerView then
    self:Finish(false)
    return
  end
  if Player.isLocal then
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
  end
  self:Finish(true)
end

function NPCActionBlindBoxIn:Finish(success, data, param)
  local Player = self:GetPlayer()
  if self.OwnerNpc then
    self.OwnerNpc:SetNotDestroyFlag(false)
    if self.OwnerNpc.InteractionComponent then
      self.OwnerNpc.InteractionComponent:TryEnableInteraction()
    end
    if Player and Player.inputComponent then
      Player.inputComponent:SetInputEnable(self, true, "ActionBlindBoxIn")
    end
  end
  if not success and Player and Player.playerToyComponent then
    Player.playerToyComponent:RevertPLayer()
  end
  Base.Finish(self, success, data, param)
end

function NPCActionBlindBoxIn:OnCommit(rsp)
  Base.OnCommit(self, rsp)
  local Player = self:GetPlayer()
  if not Player then
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    if Player.playerToyComponent then
      Player.playerToyComponent:RevertPLayer()
    end
  else
    if Player.isLocal then
      self:SyncAction()
    end
    Player.viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.BlindBox)
  end
end

return NPCActionBlindBoxIn
