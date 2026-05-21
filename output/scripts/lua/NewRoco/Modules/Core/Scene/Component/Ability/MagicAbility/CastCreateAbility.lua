local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.MagicAbility.CastMagicAbilityBase")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MagicCreationUtils = require("NewRoco.Modules.System.MagicCreation.MagicCreationUtils")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local CastCreateAbility = Base:Extend("CastCreateAbility")

function CastCreateAbility:Init(AbilityConf)
  Base.Init(self, AbilityConf)
  self._abilityId = AbilityID.MAGIC_CREATE
  self.SoundSource = "CastCreateAbility"
  self.SoundIdCreateFailed = 202705
end

function CastCreateAbility:CastMagic(...)
  self:PlayAnimAndSkill()
end

function CastCreateAbility:Interrupt()
  self:Recover()
end

function CastCreateAbility:Recover()
  if not self.buff then
    self.buff = AbilityHelperManager.GetHelper(self._abilityId):GetBuff(self.caster)
  end
  self:CancelThrow()
  self:Finish()
end

function CastCreateAbility:CancelThrow()
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

function CastCreateAbility:PlayAnimAndSkill()
  self:DoCreate()
  self.buff.magicInfo.mozhangBP:ClearFX()
  local resource = self.buff.magicInfo.mozhangBP.CreateMagicResource
  if resource then
    self.buff.magicInfo.mozhangBP:PlayFX(resource.NS_Create_End, false)
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

function CastCreateAbility:OnTick(DeltaTime)
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

function CastCreateAbility:OnMozhangDisappear()
  Base.OnMozhangDisappear(self)
  if not self.caster.isLocal then
    self.caster.viewObj:SetAimMode(false, 0)
    return
  end
  self.caster.viewObj:ChangeThrowAnim(0)
end

function CastCreateAbility:Finish(Force)
  _G.UpdateManager:UnRegister(self)
  Base.Finish(self, Force)
end

function CastCreateAbility:DoCreate()
  if not self.caster.isLocal then
    return
  end
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    local Key = string.format("Error_Code_%d", ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_VISITOR_CANT_CREATE_MAGIC_NPC)
    local conf = _G.DataConfigManager:GetLocalizationConf(Key)
    if nil ~= conf then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, conf.msg)
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Key .. "\230\156\170\233\133\141\231\189\174")
    end
    local wandConf = self.caster:GetCurWandConf()
    if wandConf then
      _G.NRCAudioManager:SetEmitterSwitch("Suit", wandConf.WandName, self.caster.viewObj, "")
    end
    _G.NRCAudioManager:PlaySound3DWithActorAuto(self.SoundIdCreateFailed, self.caster.viewObj, self.SoundSource)
    self:PrepareClearLocalNpc()
    return
  end
  local itemId = self.buff.magicInfo.abilityHelper.BagItemId
  if nil ~= itemId then
    local refresh_content_id = MagicCreationUtils.GetCreateTargetNpcRefreshId(self.buff.magicInfo)
    if self.buff.magicInfo.valid == MagicCreationUtils.NpcValidType.Valid and nil ~= refresh_content_id then
      self:SendCreateRequest(refresh_content_id)
      return
    end
  end
  self:NotifyInvalidCreate()
end

function CastCreateAbility:PrepareClearLocalNpc()
  if not self.caster.isLocal then
    return
  end
  if self.buff == nil then
    return
  end
  if nil == self.buff.magicInfo then
    return
  end
  local npc = self.buff.magicInfo.npc
  if nil ~= npc then
    MagicCreationUtils.DeleteLocalNpc(npc)
    npc = nil
  end
end

function CastCreateAbility:SendCreateRequest(refreshId)
  local bagItemCreate = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.buff.magicInfo.abilityHelper.BagItemId)
  local gid = bagItemCreate and bagItemCreate.gid
  local item_id = bagItemCreate and bagItemCreate.id
  local npc = self.buff.magicInfo.npc
  if nil == npc then
    Log.Warning("self.buff.magicInfo.npc is nil")
    return
  end
  local transform = npc:GetActorTransform()
  local point = SceneUtils.ConvertVectorToPoint(transform.Translation)
  local rotator = transform.Rotation:ToRotator()
  point.dir = SceneUtils.ClientRotator2ServerPos(rotator)
  local req = _G.ProtoMessage:newZoneSceneEndThrowReq()
  req.throw_type = _G.ProtoEnum.ThrowType.THROW_MAGIC
  req.gid = gid
  req.throw_magic_info.create_npc_info.npc_refresh_conf_id = refreshId
  req.throw_magic_info.create_npc_info.create_pt = point
  req.item_conf_id = item_id or 0
  MagicCreationUtils.PlayCreatingSkill(npc)
  _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.RegisterPreperform, self.buff.magicInfo.npc)
  self.buff.magicInfo.pauseBuff = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_END_THROW_REQ, req, self, self.OnCreateRsp)
end

function CastCreateAbility:OnCreateRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.UnregisterPreperform, self.buff.magicInfo.npc)
    Log.ErrorFormat("MagicCreationUtils.OnServerCreateNPC: failed [%d] reason [%s]", rsp.ret_info.ret_code, rsp.ret_info.ret_msg)
  elseif rsp.throw_magic_create_npc_result == nil then
    Log.ErrorFormat("MagicCreationUtils.OnServerCreateNPC: rsp throw_magic_create_npc_result is nil, server version may not compatible")
  else
    local objId = rsp.throw_magic_create_npc_result.npc_obj_id
    if self.buff and self.buff.magicInfo then
      _G.NRCModuleManager:DoCmd(_G.MagicCreationModuleCmd.MakePreperformPair, self.buff.magicInfo.npc, objId)
    end
  end
end

function CastCreateAbility:NotifyInvalidCreate()
  self:PrepareClearLocalNpc()
  local reason = MagicCreationUtils.GetInvalidReason(self.buff.magicInfo.valid)
  if nil ~= reason then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, reason)
  end
  local wandConf = self.caster:GetCurWandConf()
  if wandConf then
    _G.NRCAudioManager:SetEmitterSwitch("Suit", wandConf.WandName, self.caster.viewObj, "")
  end
  _G.NRCAudioManager:PlaySound3DWithActorAuto(self.SoundIdCreateFailed, self.caster.viewObj, self.SoundSource)
end

return CastCreateAbility
