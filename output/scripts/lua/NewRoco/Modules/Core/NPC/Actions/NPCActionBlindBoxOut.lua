local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionModelBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local Base = NPCActionBase
local NPCActionBlindBoxOut = Base:Extend("NPCActionBlindBoxOut")

function NPCActionBlindBoxOut:Ctor(Owner, Config, Info, OwnerNpc)
  Base.Ctor(self, Owner, Config, Info, OwnerNpc)
end

function NPCActionBlindBoxOut:Execute(PlayerID, NeedSendReq)
  if not self.OwnerNpc then
    Log.Error("NPCActionBlindBoxOut:Execute - OwnerNpc\228\184\141\229\173\152\229\156\168")
    return
  end
  local Player = self:GetPlayer()
  if not Player then
    Log.Error("NPCActionBlindBoxOut:Execute - \232\142\183\229\143\150Player\229\164\177\232\180\165")
    return
  end
  Base.Execute(self, PlayerID, NeedSendReq)
end

function NPCActionBlindBoxOut:OnSubmit(Rsp)
  Base.OnSubmit(self, Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    self:Finish(false)
    return
  end
  Log.Debug("NPCActionBlindBoxOut:OnSubmit", "\231\142\169\229\174\182\230\136\144\229\138\159\231\166\187\229\188\128\231\174\177\229\173\144")
  local Player = self:GetPlayer()
  if not Player then
    self:Finish(false)
    return
  end
  self:PlayJumpBoxAnim()
end

function NPCActionBlindBoxOut:PlayJumpBoxAnim()
  local OwnerView = self:GetOwnerNPCView()
  local Player = self:GetPlayer()
  if not Player or not OwnerView then
    self:Finish(false)
    return
  end
  local Conf = _G.DataConfigManager:GetRoleplayPropConf(self.OwnerNpc.config.id)
  if not Conf then
    return
  end
  local SkillPath = Conf.blindbox_out_pos or "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_WanJu_XiaRenXiang_Out.G6_WanJu_XiaRenXiang_Out"
  self.Skill = RocoSkillProxy.Create(SkillPath, OwnerView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not self.Skill then
    self:Finish(false)
    return
  end
  if Player.inputComponent then
    Player.inputComponent:SetInputEnable(self, false, "NPCActionBlindBoxOut")
  end
  self.Skill:SetCaster(Player.viewObj)
  self.Skill:SetTargets({OwnerView})
  self.Skill:RegisterEventCallback("End", self, self.OnSkillFinished)
  self.Skill:PlaySkill(self, self.OnSkillStart)
  self.OwnerNpc.InteractionComponent:TryDisableInteraction()
  self.OwnerNpc:SetNotDestroyFlag(true)
end

function NPCActionBlindBoxOut:OnSkillStart()
  local Player = self:GetPlayer()
  if Player then
    Player.viewObj:SetHiddenMask(false, UE4.EPlayerForceHiddenType.BlindBox)
  end
end

function NPCActionBlindBoxOut:OnSkillFinished()
  local Player = self:GetPlayer()
  if Player then
    if Player.isLocal then
      _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
    end
    if Player.playerHomeInteractionComponent then
      Player.playerHomeInteractionComponent:SetCollisionEnable(true)
    end
    Player:SetVisible(true)
  end
  self:Finish(true)
end

function NPCActionBlindBoxOut:Finish(success, data, param)
  if self.OwnerNpc and self.OwnerNpc.InteractionComponent then
    self.OwnerNpc.InteractionComponent:TryEnableInteraction()
    self.OwnerNpc:SetNotDestroyFlag(false)
  end
  local Player = self:GetPlayer()
  if Player then
    if Player.inputComponent then
      Player.inputComponent:SetInputEnable(self, true, "NPCActionBlindBoxOut")
    end
    if not success then
      Player.viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.BlindBox)
    end
  end
  Base.Finish(self, success, data, param)
end

function NPCActionBlindBoxOut:OnCommit(rsp)
  Base.OnCommit(self, rsp)
  local Player = self:GetPlayer()
  if not Player then
    return
  end
  if 0 ~= rsp.ret_info.ret_code then
    Player.viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.BlindBox)
  elseif Player.isLocal then
    self:SyncAction()
  end
end

return NPCActionBlindBoxOut
