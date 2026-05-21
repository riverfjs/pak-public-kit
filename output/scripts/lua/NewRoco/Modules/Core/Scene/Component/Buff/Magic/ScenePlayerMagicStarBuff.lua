local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.Magic.ScenePlayerMagicBaseBuff")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerMagicStarBuff = Base:Extend("ScenePlayerMagicStarBuff")

function ScenePlayerMagicStarBuff:OnBegin(owner, MagicInfo)
  Base.OnBegin(self, owner, MagicInfo)
  local WandData = owner:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_STAR)
  self.magicInfo.mozhangBP.DisappearFx = WandData.NS_Star_Disappead
  if self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() then
  else
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.owner:GetActorLocationFrameCache(), Enum.DotsAIWorldEventType.DAWET_MAGIC_STAR_UPLEVEL, nil, 0)
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_BEGIN)
end

function ScenePlayerMagicStarBuff:OnUpdate(deltaTime)
  Base.OnUpdate(self, deltaTime)
  if self.magicInfo.customMagicInfo.ballLua then
    self.magicInfo.customMagicInfo.ballLua.viewObj:SetChargeMagicStarProcess(self.currentLevelProcess)
  end
end

function ScenePlayerMagicStarBuff:OnCharged(newChargedLevel)
  if not self.magicInfo then
    Log.Error("\230\152\159\230\152\159\233\173\148\230\179\149\232\147\132\229\138\155\230\136\144\229\138\159\239\188\140\228\189\134\230\178\161\230\156\137magic info")
    return
  end
  if self.owner.isLocal then
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_MAGIC
    local customParams = self.owner.statusComponent._statusParams[Id]
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    customParams.throw_aim_param.aim_type = ProtoEnum.AimSyncType.AST_MODE_CHANGE
    customParams.throw_aim_param.charged_level = newChargedLevel
    self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC, self.magicInfo.abilityHelper.config.add_status[1], ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  end
  if not self.magicInfo.customMagicInfo.ballLua then
    return
  end
  self.magicInfo.customMagicInfo.ballLua.viewObj:SetChargeLevel(newChargedLevel)
  if self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() then
  else
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.owner:GetActorLocationFrameCache(), Enum.DotsAIWorldEventType.DAWET_MAGIC_STAR_UPLEVEL, nil, newChargedLevel + 1)
  end
  if 1 == newChargedLevel then
    self.magicInfo.mozhangBP:PlayFX(self.magicInfo.mozhangBP.StarXuli1Loop, false)
    self.magicInfo.mozhangBP:PlayFXOnce(self.magicInfo.mozhangBP.StarXuli1)
  elseif 2 == newChargedLevel then
    self.magicInfo.mozhangBP:PlayFX(self.magicInfo.mozhangBP.StarXuli2Loop, false)
    self.magicInfo.mozhangBP:PlayFXOnce(self.magicInfo.mozhangBP.StarXuli2)
    self:ChangeChargedAnim("MagicStarAim2")
  elseif 3 == newChargedLevel then
    self.magicInfo.mozhangBP:PlayFX(self.magicInfo.mozhangBP.StarXuli3Loop, false)
    self.magicInfo.mozhangBP:PlayFXOnce(self.magicInfo.mozhangBP.StarXuli3)
    self:ChangeChargedAnim("MagicStarAim3")
    self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_FULL)
  end
end

function ScenePlayerMagicStarBuff:ChangeChargedAnim(AnimName)
  local Montage = self.owner.viewObj:GetAnimComponent():PrepareMontageByName(AnimName, "DefaultSlot", 0.25, 0.25)
  if not UE.UObject.IsValid(self.owner.viewObj.Mesh:GetAnimInstance()) then
    Log.Error("\232\147\132\229\138\155\230\151\182\228\184\187\232\167\146ABP\228\184\162\228\186\134\239\188\140\232\175\183\230\136\170\229\155\190\232\129\148\231\179\187minot")
    return
  end
  local ThrowAnimInstance = self.owner.viewObj.Mesh:GetAnimInstance():GetLinkedAnimGraphInstanceByTag("Locomotion"):GetLinkedAnimGraphInstanceByTag("Aim")
  if ThrowAnimInstance then
    ThrowAnimInstance:Montage_Play(Montage)
    ThrowAnimInstance:Montage_SetNextSection("Default", "Default", Montage)
  end
end

return ScenePlayerMagicStarBuff
