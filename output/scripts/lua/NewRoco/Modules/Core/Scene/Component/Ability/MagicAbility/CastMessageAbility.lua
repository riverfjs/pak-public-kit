local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.MagicAbility.CastMagicAbilityBase")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MagicMessageUtils = require("NewRoco.Modules.System.MagicMessage.MagicMessageUtils")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local CastMessageAbility = Base:Extend("CastMessageAbility")

function CastMessageAbility:Init(AbilityConf)
  Base.Init(self, AbilityConf)
  self._abilityId = AbilityID.MAGIC_MESSAGE
  self.SoundSource = "CastMessageAbility"
  self.SoundIdCreateFailed = 202705
end

function CastMessageAbility:CastMagic(...)
  self:PlayAnimAndSkill()
end

function CastMessageAbility:Interrupt()
  self:Recover()
end

function CastMessageAbility:Recover()
  if not self.buff then
    self.buff = AbilityHelperManager.GetHelper(self._abilityId):GetBuff(self.caster)
  end
  self:CancelThrow()
  self:Finish()
end

function CastMessageAbility:CancelThrow()
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

function CastMessageAbility:PlayAnimAndSkill()
  self:DoCreate()
  self.buff.magicInfo.mozhangBP:ClearFX()
  if self.buff.magicInfo.mozhangBP.MessageMagicResource then
    local paths = {}
    table.insert(paths, UE4.UNRCStatics.GetSoftObjPath(self.buff.magicInfo.mozhangBP.MessageMagicResource.NS_Create_End))
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

function CastMessageAbility:OnTick(DeltaTime)
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

function CastMessageAbility:OnMozhangDisappear()
  Base.OnMozhangDisappear(self)
  if not self.caster.isLocal then
    self.caster.viewObj:SetAimMode(false, 0)
    return
  end
  self.caster.viewObj:ChangeThrowAnim(0)
end

function CastMessageAbility:Finish(Force)
  _G.UpdateManager:UnRegister(self)
  Base.Finish(self, Force)
end

function CastMessageAbility:DoCreate()
  if not self.caster.isLocal then
    return
  end
  local magicInfo = self.buff.magicInfo
  if magicInfo.valid == MagicMessageUtils.NpcValidType.Valid or magicInfo.valid == MagicMessageUtils.NpcValidType.Water then
    magicInfo.npc.viewObj:Fall()
    self:OpenCommonPanel()
    return
  end
  self:NotifyInvalidCreate()
end

function CastMessageAbility:PrepareClearLocalNpc()
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

function CastMessageAbility:OpenCommonPanel()
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
  MagicMessageUtils.PlayMessageSkill(npc)
  _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.RegisterPreperform, self.buff.magicInfo.npc)
  local bagItemCreate = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.buff.magicInfo.abilityHelper.BagItemId)
  local gid = bagItemCreate and bagItemCreate.gid
  local item_id = bagItemCreate and bagItemCreate.id
  local refresh_content_id = MagicMessageUtils.GetNpcRefreshContentConf(self.buff.magicInfo)
  local req = _G.ProtoMessage:newZoneSceneEndThrowReq()
  req.throw_type = _G.ProtoEnum.ThrowType.THROW_MAGIC
  req.gid = gid
  req.throw_magic_info.create_npc_info.npc_refresh_conf_id = refresh_content_id
  req.throw_magic_info.create_npc_info.create_pt = point
  req.item_conf_id = item_id or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, self, self.OnCreateRsp)
  if npc.serverData and npc.serverData.base and npc.serverData.base.actor_id then
    local param = MagicMessageUtils.CreateParam(ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE, npc, create_pos, self.buff.magicInfo.valid)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenCreateMagicMessage, param)
  end
end

function CastMessageAbility:OnCreateRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.ErrorFormat("CastMessageAbility.OpenCommonPanel: failed [%d] reason [%s]", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
  elseif rsp.throw_magic_create_npc_result == nil then
    Log.ErrorFormat("CastMessageAbility.OpenCommonPanel: rsp throw_magic_create_npc_result is nil, server version may not compatible")
  end
end

function CastMessageAbility:NotifyInvalidCreate()
  self:PrepareClearLocalNpc()
  local reason = MagicMessageUtils.GetInvalidReason(self.buff.magicInfo.valid)
  if nil ~= reason then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, reason)
  end
  local wandConf = self.caster:GetCurWandConf()
  if wandConf then
    _G.NRCAudioManager:SetEmitterSwitch("Suit", wandConf.WandName, self.caster.viewObj, "")
  end
  _G.NRCAudioManager:PlaySound3DWithActorAuto(self.SoundIdCreateFailed, self.caster.viewObj, self.SoundSource)
end

return CastMessageAbility
