local MagicReplayModuleEnum = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEnum")
local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.MagicAbility.CastMagicAbilityBase")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local CastVideoAbility = Base:Extend("CastVideoAbility")

function CastVideoAbility:Init(AbilityConf)
  Base.Init(self, AbilityConf)
  self._abilityId = AbilityID.MAGIC_VIDEO
  self.SoundSource = "CastVideoAbility"
  self.SoundIdCreateFailed = 202705
end

function CastVideoAbility:CastMagic(...)
  self:PlayAnimAndSkill()
end

function CastVideoAbility:Interrupt()
  self:Recover()
end

function CastVideoAbility:Recover()
  if not self.buff then
    self.buff = AbilityHelperManager.GetHelper(self._abilityId):GetBuff(self.caster)
  end
  self:CancelThrow()
  self:Finish()
end

function CastVideoAbility:CancelThrow()
  self:PrepareClearLocalNpc()
  if self.buff and not self.buff.is_magic_cancel then
    self.buff:GetController().PlayerCameraManager:Reset()
  end
  if self.buff.magicInfo.SoundIdCreateLoop then
    _G.NRCAudioManager:ReleaseSession(self.buff.magicInfo.SoundIdCreateLoop, true, self.buff.magicInfo.SoundSourceCreate)
  end
  if not self.caster.isLocal then
    self.caster.viewObj:SetAimMode(false, 0)
    return
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_INTERRUPT_THROW)
  self.caster.viewObj:ChangeThrowAnim(0)
end

function CastVideoAbility:PlayAnimAndSkill()
  self:DoCreate()
  self.buff.magicInfo.mozhangBP:ClearFX()
  if self.buff.magicInfo.mozhangBP.VideoMagicResource then
    local paths = {}
    table.insert(paths, UE4.UNRCStatics.GetSoftObjPath(self.buff.magicInfo.mozhangBP.VideoMagicResource.NS_Create_End))
    self.buff.magicInfo.mozhangBP:PlayFXWithLevel(paths)
  end
  if self.buff.magicInfo.SoundIdCreateLoop then
    _G.NRCAudioManager:ReleaseSession(self.buff.magicInfo.SoundIdCreateLoop, true, self.buff.magicInfo.SoundSourceCreate)
  end
  self.SkillTime = 0
  self.hasOnMozhangDisappear = false
  _G.UpdateManager:Register(self)
  self.Anim = self.caster.viewObj:GetAnimComponent():GetAnimSequenceByName("MagicWindCast")
  local AnimInstance = self.caster.viewObj.Mesh:GetAnimInstance()
  local ThrowAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("Locomotion"):GetLinkedAnimGraphInstanceByTag("Aim")
  if nil == ThrowAnimInstance then
    AnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
  else
    ThrowAnimInstance:PlaySlotAnimation(self.Anim, "UpperBody", 0, 0)
  end
  if self.caster.isLocal then
    self.buff:GetController():ChangeThrowAimStat(false)
  end
end

function CastVideoAbility:OnTick(DeltaTime)
  self.SkillTime = self.SkillTime + DeltaTime
  if self.SkillTime > 0.5 and not self.hasOnMozhangDisappear then
    self.hasOnMozhangDisappear = true
    self:OnMozhangDisappear()
    return
  end
  if self.SkillTime > 0.67 then
    self:Finish()
    return
  end
end

function CastVideoAbility:OnMozhangDisappear()
  Base.OnMozhangDisappear(self)
  if not self.caster.isLocal then
    self.caster.viewObj:SetAimMode(false, 0)
    return
  end
  self.caster.viewObj:ChangeThrowAnim(0)
end

function CastVideoAbility:Finish(Force)
  _G.UpdateManager:UnRegister(self)
  Base.Finish(self, Force)
end

function CastVideoAbility:DoCreate()
  if not self.caster.isLocal then
    return
  end
  if _G.MagicReplayModuleCmd and not _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.HasFreeDiskSpace) then
    local conf = _G.DataConfigManager:GetLocalizationConf("mark_video_no_disk")
    if nil ~= conf then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, conf.msg)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "mark_video_no_disk")
    end
    _G.NRCAudioManager:PlaySound2DAuto(self.SoundIdCreateFailed, self.SoundSource)
    self:PrepareClearLocalNpc()
    return
  end
  local magicInfo = self.buff.magicInfo
  if magicInfo.valid == MagicMessageUtils.NpcValidType.Valid or magicInfo.valid == MagicMessageUtils.NpcValidType.Water then
    magicInfo.npc.viewObj:Fall()
    self:StartMagicVideo()
    return
  end
  self:NotifyInvalidCreate()
end

function CastVideoAbility:PrepareClearLocalNpc()
  if not self.caster.isLocal then
    return
  end
  if self.buff == nil then
    return
  end
  if nil == self.buff.magicInfo then
    return
  end
  self.buff.magicInfo.pauseBuff = true
  local npc = self.buff.magicInfo.npc
  if self.buff.magicInfo.valid == MagicMessageUtils.NpcValidType.UnInited then
    MagicMessageUtils.DeleteLocalNpc(npc)
    return
  end
  local viewObj = npc.viewObj
  if viewObj then
    viewObj:SetCancel()
    MagicMessageUtils.DeleteLocalNpc(npc)
  end
end

function CastVideoAbility:StartMagicVideo()
  local npc = self.buff.magicInfo.npc
  if nil == npc then
    Log.Warning("self.buff.magicInfo.npc is nil")
    return
  end
  local transform = npc:GetActorTransform()
  local point = SceneUtils.ConvertVectorToPoint(transform.Translation)
  local rotator = transform.Rotation:ToRotator()
  point.dir = SceneUtils.ClientRotator2ServerPos(rotator)
  local create_pos = _G.ProtoMessage:newPoint()
  create_pos = point
  local temp = MagicMessageUtils.GetNpcLandInfo(npc)
  if temp then
    create_pos.pos.z = temp
  end
  self.buff.magicInfo.pauseBuff = true
  _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.RegisterPreperform, self.buff.magicInfo.npc)
  if npc.serverData and npc.serverData.base and npc.serverData.base.actor_id then
    local param = MagicMessageUtils.CreateParam(ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO, npc, create_pos, self.buff.magicInfo.valid)
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.SetRecordFeedInitInfo, param)
    _G.NRCModuleManager:DoCmd(_G.MagicReplayModuleCmd.StartMagicReplay, MagicReplayModuleEnum.ModuleOpType.Record)
  end
end

function CastVideoAbility:OnCreateRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.ErrorFormat("CastVideoAbility.StartMagicVideo: failed [%d] reason [%s]", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
  elseif rsp.throw_magic_create_npc_result == nil then
    Log.ErrorFormat("CastVideoAbility.StartMagicVideo: rsp throw_magic_create_npc_result is nil, server version may not compatible")
  end
end

function CastVideoAbility:NotifyInvalidCreate()
  self:PrepareClearLocalNpc()
  local reason = MagicMessageUtils.GetVideoInvalidReason(self.buff.magicInfo.valid)
  if nil ~= reason then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, reason)
  end
  _G.NRCAudioManager:PlaySound2DAuto(self.SoundIdCreateFailed, self.SoundSource)
end

return CastVideoAbility
