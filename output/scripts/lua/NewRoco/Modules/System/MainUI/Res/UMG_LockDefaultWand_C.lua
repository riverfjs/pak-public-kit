local Base = require("NewRoco/Modules/System/MainUI/Res/UMG_WandLockBase_C")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local UMG_LockDefaultWand_C = Base:Extend("UMG_LockDefaultWand_C")

function UMG_LockDefaultWand_C:OnActive()
end

function UMG_LockDefaultWand_C:OnDeactive()
end

function UMG_LockDefaultWand_C:OnAddEventListener()
end

function UMG_LockDefaultWand_C:OnConstruct()
  self.lastActor = nil
  self.curActor = nil
  self.isLockingState = false
  self.wndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  self.LineTraceDist = 10000
  self.curTickTime = 0
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  _G.NRCEventCenter:RegisterEvent("UMG_LockMagic_C", self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LockDefaultWand_C:RebindPlayer()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function UMG_LockDefaultWand_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
end

function UMG_LockDefaultWand_C:OnShow()
  self:StopAllAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.isLockingState == false then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
    self:PlayAnimation(self.open)
  else
    self:OnEnterLockingState(true)
  end
  self.InnerLine:PlayAnimation(self.InnerLine.loop)
  self.Outline:PlayAnimation(self.Outline.loop)
end

function UMG_LockDefaultWand_C:OnCancel(cancelType)
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  self:StopAllAnim()
  self:PlayAnimation(self.close)
end

function UMG_LockDefaultWand_C:OnEnterLockingState(bool)
  self:StopAllAnim()
  if bool then
    self:PlayAnimation(self.change1)
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_LockDefaultWand_C:OnTick(InDeltaTime)
  if not self.player then
    return
  end
  local playerCtrl = self.player:GetUEController()
  if not playerCtrl then
    return
  end
  if not UE4.UObject.IsValid(playerCtrl) then
    return
  end
  local WorldLocation, CamDir = playerCtrl:Abs_DeprojectScreenPositionToWorld(self.wndSize.X / 2, self.wndSize.Y / 2)
  local endPos = FVectorZero
  if self.LineTraceDist > 0 then
    endPos = WorldLocation + CamDir * self.LineTraceDist
  end
  local TraceChannel = _G.UE4.ECollisionChannel.ECC_GameTraceChannel1
  local OutHit, Res = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(self.player.viewObj, WorldLocation, endPos, TraceChannel, false, nil, 0, nil, true)
  self.curTickTime = self.curTickTime + InDeltaTime
  if self.curTickTime > 0.7 then
    self.curTickTime = 0.0
    if OutHit.Actor ~= self.lastActor then
      self.curActor = OutHit.Actor
      if self.curActor ~= nil and self.curActor.sceneCharacter and self:CanInteract(self.curActor.sceneCharacter) then
        if self:IsAnimationPlaying(self.open) then
          self:OnEnterLockingState(false)
        else
          self:OnEnterLockingState(true)
        end
        self.isLockingState = true
      elseif self.lastActor and self.lastActor.sceneCharacter and self.lastActor.sceneCharacter.config and self.isLockingState then
        self:OnEnterLockingState(false)
        self.isLockingState = false
      end
    end
    self.lastActor = OutHit.Actor
  end
end

function UMG_LockDefaultWand_C:CanInteract(actor)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local buff = AbilityHelperManager.GetHelper(AbilityID.MAGIC_STAR):GetBuff(player)
  local ballNpc
  if buff then
    ballNpc = buff.magicInfo.customMagicInfo.ballLua
  end
  local actorLocation = _G.FVectorZero
  local chargeLv = 0
  local range = 0
  if ballNpc and ballNpc.viewObj then
    actorLocation = ballNpc.viewObj:K2_GetActorLocation()
    chargeLv = ballNpc.viewObj.charge_level or 0
    range = ballNpc.viewObj.BoomRange or 0
  end
  local canInteract = false
  if actor.config then
    local npcCfg = _G.DataConfigManager:GetNpcConf(actor.config.id)
    for k, v in ipairs(npcCfg.option_id) do
      local npcOptionCfg
      npcOptionCfg = _G.DataConfigManager:GetNpcOptionConf(npcCfg.option_id[k])
      if npcOptionCfg and npcOptionCfg.magic_interact_id and npcOptionCfg.magic_interact_id > 0 then
        local magicInteractConf = _G.DataConfigManager:GetMagicInteractConf(npcOptionCfg.magic_interact_id)
        if magicInteractConf and 1 == magicInteractConf.action_struct[1].magic_id and chargeLv >= magicInteractConf.action_struct[1].magic_charge_level then
          canInteract = true
        end
      end
    end
  else
    canInteract = false
  end
  return canInteract
end

function UMG_LockDefaultWand_C:StopAllAnim()
  if self:IsAnyAnimationPlaying() then
    self:StopAllAnimations()
  end
  if self.InnerLine:IsAnyAnimationPlaying() then
    self.InnerLine:StopAllAnimations()
  end
  if self.Outline:IsAnyAnimationPlaying() then
    self.Outline:StopAllAnimations()
  end
end

function UMG_LockDefaultWand_C:ClearActorCache()
  self.lastActor = nil
  self.isLockingState = false
end

function UMG_LockDefaultWand_C:OnAnimationFinished(anim)
  if anim == self.close then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.open or anim == self.change2 then
    self:PlayAnimation(self.normal, 0.0, 0)
  elseif anim == self.change1 then
    self:PlayAnimation(self.select, 0.0, 0)
  end
  if anim == self.open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

return UMG_LockDefaultWand_C
