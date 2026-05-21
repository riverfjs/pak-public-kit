local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local CatchPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchPetComponent")
local UMG_LockBall_C = _G.NRCPanelBase:Extend("UMG_LockBall_C")
local LockPetProbability = {
  Low = 0,
  Middle = 1,
  Normal = 2,
  LittleHigh = 3,
  High = 4,
  Ban = 5,
  Empty = 6
}

function UMG_LockBall_C:OnConstruct()
  self.lastActor = nil
  self.curActor = nil
  self.wndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  self.World = _G.UE4Helper.GetCurrentWorld()
  self.isLockingState = false
  self.throwItemSession = {}
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local lineTraceConf = _G.DataConfigManager:GetGlobalConfigByKeyType("throw_linetrace_distance", confID)
  self.LineTraceDist = lineTraceConf.num
  self.curTickTime = 0.0
  self.landPoint = UE4.FVector(0, 0, 0)
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  _G.NRCEventCenter:RegisterEvent("UMG_LockBall_C", self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
  _G.NRCEventCenter:RegisterEvent("UMG_LockBall_C", self, SystemSettingModuleEvent.ChangeResolution, self.OnChangeResolution)
  self.OtherLockOutAnim = {
    self.Lock_AboveAverage_out,
    self.Lock_High_out,
    self.Lock_Middle_out,
    self.Lock_Low_out,
    self.UnLock_out,
    self.Lock_Normal_out
  }
  self.IsStartAnim = false
  self.IsChangeResolution = false
  self.StartLockInCallBack = nil
  self.IsPlayOutAnim = false
  self.NRCSwitcher_Icon:SetActiveWidgetIndex(0)
  self.Dot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.forbid:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ResetState()
end

function UMG_LockBall_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.ChangeResolution, self.OnChangeResolution)
end

function UMG_LockBall_C:RebindPlayer()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function UMG_LockBall_C:OnShow()
  if self.IsPlayOutAnim or self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    self:StopAllAnimations()
    self:ResetState()
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Lock_in, 0)
    self:PauseAnimation(self.Lock_in)
    self.CanTick = false
    self:PlayLockAnim()
  end
end

function UMG_LockBall_C:Tick(MyGeometry, InDeltaTime)
  if not self.CanTick then
    return
  end
  if not self.player then
    return
  end
  local playerCtrl = self.player:GetUEController()
  if not playerCtrl then
    return
  end
  playerCtrl = UE4.UGameplayStatics.GetPlayerControllerFromID(self.player.viewObj, 0)
  if not playerCtrl then
    return
  end
  if self.IsChangeResolution then
    self.wndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
    self.IsChangeResolution = false
  end
  local WorldLocation, CamDir = playerCtrl:Abs_DeprojectScreenPositionToWorld(self.wndSize.X / 2, self.wndSize.Y / 2)
  local endPos = FVectorZero
  if self.LineTraceDist > 0 then
    endPos = WorldLocation + CamDir * self.LineTraceDist
  end
  local TraceChannelLand = UE4.UNRCStatics.ConvertToTraceChannel(_G.UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local OutHitLand, Result = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), WorldLocation, endPos, TraceChannelLand, false, nil, UE4.EDrawDebugTrace.None, nil, true)
  if OutHitLand and OutHitLand.ImpactPoint then
    self.landPoint.X = OutHitLand.ImpactPoint.X or 0
    self.landPoint.Y = OutHitLand.ImpactPoint.Y or 0
    self.landPoint.Z = OutHitLand.ImpactPoint.Z or 0
    _G.NRCModuleManager:GetModule("MainUIModule"):SetLockPetLandPos(self.landPoint)
  end
  local TraceChannel = _G.UE4.ECollisionChannel.ECC_GameTraceChannel1
  local OutHit, Res = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(self.player.viewObj, WorldLocation, endPos, TraceChannel, false, nil, UE4.EDrawDebugTrace.None, nil, true)
  self.curTickTime = self.curTickTime + InDeltaTime
  if self.curTickTime > 0.2 then
    self.curTickTime = 0.0
    if OutHit.Actor then
      self.curActor = OutHit.Actor
      if self.curActor ~= nil and self.curActor.sceneCharacter and self.curActor.sceneCharacter.GetThrowInteractType then
        local throwType = self.curActor.sceneCharacter:GetThrowInteractType()
        if throwType == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
          local CatchComp = self.curActor.sceneCharacter:EnsureComponent(CatchPetComponent)
          local canCatch, isEmpty = CatchComp:CheckCanCatchPet(self.curActor.sceneCharacter)
          if canCatch then
            self:LockingNPC()
          elseif isEmpty then
            self:LockingEmpty()
          else
            self:LockingBanNPC()
          end
        else
          self:LockingEmpty()
        end
      else
        local flag = false
        if self.lastActor and self.lastActor.sceneCharacter and self.lastActor.sceneCharacter.GetThrowInteractType then
          local throwType = self.lastActor.sceneCharacter:GetThrowInteractType()
          if throwType == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
            local HiddenComp = self.lastActor.sceneCharacter.HiddenComponent
            if not HiddenComp or false == HiddenComp:IsHidden() then
              flag = true
            end
          end
        end
        if flag then
          self:lastActorSetState()
        else
          self:LockingEmpty()
        end
      end
    else
      self:LockingEmpty()
    end
    self.lastActor = OutHit.Actor
  end
end

function UMG_LockBall_C.IsResistCapture(npc)
  if npc and npc.AIComponent then
    return npc.AIComponent:IsResistCapture()
  end
  return false
end

function UMG_LockBall_C:LockingNPC()
  if self.curActor ~= nil and self.curActor.sceneCharacter and self.curActor.sceneCharacter.GetThrowInteractType then
    local throwType = self.curActor.sceneCharacter:GetThrowInteractType()
    if throwType == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
      local HiddenComp = self.curActor.sceneCharacter.HiddenComponent
      if not HiddenComp or not HiddenComp:IsHidden() then
        self:SetCatchHardLv(self.curActor.sceneCharacter, self.IsResistCapture(self.curActor.sceneCharacter))
      end
    end
  end
  self.curActor:ShowThrowInterInfo(true, true)
  local isZero = false
  if self.IsResistCapture(self.curActor.sceneCharacter) then
    isZero = true
  end
  self:SetCatchHardLv(self.curActor.sceneCharacter, isZero)
  self.curActor.sceneCharacter.isAimed = true
  self.isLockingState = true
  self:PlayLockAnim()
end

function UMG_LockBall_C:LockingBanNPC()
  self.CurLockPetProbability = LockPetProbability.Ban
  self:PlayLockAnim()
end

function UMG_LockBall_C:LockingEmpty()
  self.CurLockPetProbability = LockPetProbability.Empty
  self:PlayLockAnim()
end

function UMG_LockBall_C:lastActorSetState()
  if self.lastActor and self.lastActor.sceneCharacter and self.lastActor.sceneCharacter.config then
    local throwType = self.lastActor.sceneCharacter:GetThrowInteractType()
    if throwType == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
      self.lastActor:ShowThrowInterInfo(false)
      self:LockingEmpty()
      self.isLockingState = false
      self.lastActor.sceneCharacter.isAimed = false
    end
  end
end

function UMG_LockBall_C:IsHidden(Actor)
  local HiddenComp = Actor.sceneCharacter.HiddenComponent
  if HiddenComp and HiddenComp:IsHidden() then
    return HiddenComp, true
  end
  return nil, false
end

function UMG_LockBall_C:SetCatchHardLv(targetNPC, isZero)
  if targetNPC and self.throwItemSession ~= nil and self.throwItemSession.itemData and self.throwItemSession.itemData.id then
    local catchRate, petBaseID = SceneUtils.GetCatchRate(self.throwItemSession, targetNPC)
    local catchLowConf = _G.DataConfigManager:GetBattleGlobalConfig("catch_bigworld_low_1")
    local catchLow
    if catchLowConf and catchLowConf.numList then
      catchLow = catchLowConf.numList
    end
    local catchMiddle1Conf = _G.DataConfigManager:GetBattleGlobalConfig("catch_bigworld_middle_2")
    local catchMiddle1
    if catchMiddle1Conf and catchMiddle1Conf.numList then
      catchMiddle1 = catchMiddle1Conf.numList
    end
    local catchMiddle2Conf = _G.DataConfigManager:GetBattleGlobalConfig("catch_bigworld_middle_3")
    local catchMiddle2
    if catchMiddle2Conf and catchMiddle2Conf.numList then
      catchMiddle2 = catchMiddle2Conf.numList
    end
    local catchHigh1Conf = _G.DataConfigManager:GetBattleGlobalConfig("catch_bigworld_high_4")
    local catchHigh1
    if catchHigh1Conf and catchHigh1Conf.numList then
      catchHigh1 = catchHigh1Conf.numList
    end
    local catchHigh2Conf = _G.DataConfigManager:GetBattleGlobalConfig("catch_bigworld_high_5")
    local catchHigh2
    if catchHigh2Conf and catchHigh2Conf.numList then
      catchHigh2 = catchHigh2Conf.numList
    end
    if isZero then
      catchRate = 0
    end
    if catchLow and catchRate >= catchLow[1] / 10000.0 and catchRate < catchLow[2] / 10000.0 then
      self.CurLockPetProbability = LockPetProbability.Low
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("c7494a"))
    elseif catchMiddle1 and catchRate >= catchMiddle1[1] / 10000.0 and catchRate < catchMiddle1[2] / 10000.0 then
      self.CurLockPetProbability = LockPetProbability.Middle
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("fcb641ff"))
    elseif catchMiddle2 and catchRate >= catchMiddle2[1] / 10000.0 and catchRate < catchMiddle2[2] / 10000.0 then
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
      self.CurLockPetProbability = LockPetProbability.Normal
    elseif catchHigh1 and catchRate >= catchHigh1[1] / 10000.0 and catchRate < catchHigh1[2] / 10000.0 then
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
      self.CurLockPetProbability = LockPetProbability.LittleHigh
    elseif catchHigh2 and catchRate >= catchHigh2[1] / 10000.0 and catchRate <= catchHigh2[2] / 10000.0 then
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
      self.CurLockPetProbability = LockPetProbability.High
    else
      self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
      self.CurLockPetProbability = LockPetProbability.Normal
    end
  end
end

function UMG_LockBall_C:ClearActorCache()
  if self.lastActor and self.lastActor.ShowThrowInterInfo then
    self.lastActor:ShowThrowInterInfo(false)
  end
  self.lastActor = nil
  self.isLockingState = false
end

function UMG_LockBall_C:PlayLockOutAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanTick = false
  self.AnimCallBack = nil
  self.IsStartAnim = false
  self.IsPlayOutAnim = true
  if self.CurPlayAnimState == LockPetProbability.Low then
    self:OnPlayAnim(self.Lock_Low_out)
  elseif self.CurPlayAnimState == LockPetProbability.Middle then
    self:OnPlayAnim(self.Lock_Middle_out)
  elseif self.CurPlayAnimState == LockPetProbability.LittleHigh then
    self:OnPlayAnim(self.Lock_AboveAverage_out)
  elseif self.CurPlayAnimState == LockPetProbability.High then
    self:OnPlayAnim(self.Lock_High_out)
  elseif self.CurPlayAnimState == LockPetProbability.Ban then
    self:OnPlayAnim(self.UnLock_out)
  elseif self.CurPlayAnimState == LockPetProbability.Normal then
    self:OnPlayAnim(self.Lock_Normal_out)
  elseif self.CurPlayAnimState == LockPetProbability.Empty then
    self:OnPlayAnim(self.Lock_out)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LockBall_C:ChangeColor(color)
  self.lu:SetColorAndOpacity(color)
  self.ru:SetColorAndOpacity(color)
  self.rd:SetColorAndOpacity(color)
  self.ld:SetColorAndOpacity(color)
end

function UMG_LockBall_C:OnAnimationFinished(anim)
  if anim == self.Lock_out then
    self:ResetState()
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  elseif self:IsPlayingOtherLockOut(anim) then
    self:OnPlayAnim(self.Lock_out)
  end
  if not self.IsStartAnim then
    return
  end
  if self.CurLockPetProbability == LockPetProbability.Low and anim == self.Lock_Low_in then
    self:OnPlayAnim(self.Lock_Low_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Low and anim == self.Lock_Low_loop then
    self:OnPlayAnim(self.Lock_Low_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Middle and anim == self.Lock_Middle_in then
    self:OnPlayAnim(self.Lock_Middle_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Middle and anim == self.Lock_Middle_loop then
    self:OnPlayAnim(self.Lock_Middle_loop)
  elseif self.CurLockPetProbability == LockPetProbability.LittleHigh and anim == self.Lock_AboveAverage_in then
    self:OnPlayAnim(self.Lock_AboveAverage_loop)
  elseif self.CurLockPetProbability == LockPetProbability.LittleHigh and anim == self.Lock_AboveAverage_loop then
    self:OnPlayAnim(self.Lock_AboveAverage_loop)
  elseif self.CurLockPetProbability == LockPetProbability.High and anim == self.Lock_High_in then
    self:OnPlayAnim(self.Lock_High_loop)
  elseif self.CurLockPetProbability == LockPetProbability.High and anim == self.Lock_High_loop then
    self:OnPlayAnim(self.Lock_High_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Ban and anim == self.UnLock_in then
    self:OnPlayAnim(self.UnLock_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Ban and anim == self.UnLock_loop then
    self:OnPlayAnim(self.UnLock_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Normal and anim == self.Lock_Normal_in then
    self:OnPlayAnim(self.Lock_Normal_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Normal and anim == self.Lock_Normal_loop then
    self:OnPlayAnim(self.Lock_Normal_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Empty and anim == self.Lock_in then
    if not self.CanTick then
      self.CanTick = true
    end
    self:OnPlayAnim(self.Lock_loop)
  elseif self.CurLockPetProbability == LockPetProbability.Empty and anim == self.Lock_loop then
    self:OnPlayAnim(self.Lock_loop)
  elseif self.CurLockPetProbability ~= LockPetProbability.Empty and anim == self.Lock_in then
    if self.StartLockInCallBack then
      self.StartLockInCallBack()
      self.StartLockInCallBack = nil
    else
      self:OnPlayAnim(self.Lock_loop)
    end
  end
end

function UMG_LockBall_C:PlayLockAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.IsStartAnim = true
  if self.CurLockPetProbability == LockPetProbability.Low and self.CurPlayAnimState ~= LockPetProbability.Low then
    self:ShowSwitchIcon(true)
    self:ShowArrow(true)
    if not self:IsAnimationPlaying(self.Lock_Low_in) or not self:IsAnimationPlaying(self.Lock_Low_loop) then
      self.CurPlayAnimState = LockPetProbability.Low
      self:OnPlayAnim(self.Lock_Low_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.Middle and self.CurPlayAnimState ~= LockPetProbability.Middle then
    self:ShowSwitchIcon(true)
    self:ShowArrow(true)
    if not self:IsAnimationPlaying(self.Lock_Middle_in) or not self:IsAnimationPlaying(self.Lock_Middle_loop) then
      self.CurPlayAnimState = LockPetProbability.Middle
      self:OnPlayAnim(self.Lock_Middle_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.LittleHigh and self.CurPlayAnimState ~= LockPetProbability.LittleHigh then
    self:ShowSwitchIcon(true)
    self:ShowArrow(true)
    if not self:IsAnimationPlaying(self.Lock_AboveAverage_in) or not self:IsAnimationPlaying(self.Lock_AboveAverage_loop) then
      self.CurPlayAnimState = LockPetProbability.LittleHigh
      self:OnPlayAnim(self.Lock_AboveAverage_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.High and self.CurPlayAnimState ~= LockPetProbability.High then
    self:ShowSwitchIcon(true)
    self:ShowArrow(true)
    if not self:IsAnimationPlaying(self.Lock_High_in) or not self:IsAnimationPlaying(self.Lock_High_loop) then
      self.CurPlayAnimState = LockPetProbability.High
      self:OnPlayAnim(self.Lock_High_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.Ban and self.CurPlayAnimState ~= LockPetProbability.Ban then
    self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
    self:ShowSwitchIcon(false)
    self:ShowArrow(false)
    if not self:IsAnimationPlaying(self.UnLock_in) or not self:IsAnimationPlaying(self.UnLock_loop) then
      self.CurPlayAnimState = LockPetProbability.Ban
      self:OnPlayAnim(self.UnLock_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.Normal and self.CurPlayAnimState ~= LockPetProbability.Normal then
    self:ShowSwitchIcon(true)
    self:ShowArrow(false)
    if not self:IsAnimationPlaying(self.Lock_Normal_in) or not self:IsAnimationPlaying(self.Lock_Normal_loop) then
      self.CurPlayAnimState = LockPetProbability.Normal
      self:OnPlayAnim(self.Lock_Normal_in)
    end
  elseif self.CurLockPetProbability == LockPetProbability.Empty and self.CurPlayAnimState ~= LockPetProbability.Empty then
    self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
    self:ShowSwitchIcon(false)
    self:ShowArrow(false)
    if not self:IsAnimationPlaying(self.Lock_in) or not self:IsAnimationPlaying(self.Lock_loop) then
      if self.CurPlayAnimState then
        self.CurPlayAnimState = LockPetProbability.Empty
        self:OnPlayAnim(self.Lock_loop)
      else
        self.CurPlayAnimState = LockPetProbability.Empty
        self:OnPlayAnim(self.Lock_in)
      end
    end
  end
end

function UMG_LockBall_C:OnPlayAnim(anim, cb)
  self:StopAllAnimations()
  self.AnimCallBack = cb
  self.CanvasPanel_75:SetRenderOpacity(1)
  self:PlayAnimation(anim)
end

function UMG_LockBall_C:ShowSwitchIcon(show)
  if show then
    self.right:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#f4eee1ff"))
    self.left:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#f4eee1ff"))
    self.NRCSwitcher_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LockBall_C:CheckIsOtherLockOut(anim)
  return table.contains(self.OtherLockOutAnim, anim)
end

function UMG_LockBall_C:ShowArrow(isShow)
  if isShow then
    self.Arrow_UP1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Arrow_UP2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Arrow_Down2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Arrow_Down1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Arrow_UP1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Arrow_UP2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Arrow_Down2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Arrow_Down1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LockBall_C:ResetState()
  self.CurLockPetProbability = LockPetProbability.Empty
  self:ShowSwitchIcon(false)
  self:ShowArrow(false)
  self:ChangeColor(UE4.UNRCStatics.HexToLinearColor("ffffffff"))
  self.AnimCallBack = nil
  self:StopAllAnimations()
  self.CurPlayAnimState = nil
  self.IsPlayOutAnim = false
  self.rightE:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#f4eee1ff"))
  self.leftE:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#f4eee1ff"))
  self.rightE:SetRenderOpacity(1)
  self.leftE:SetRenderOpacity(1)
  self.right:SetRenderOpacity(0)
  self.left:SetRenderOpacity(0)
end

function UMG_LockBall_C:IsPlayingOtherLockOut(animation)
  for _, anim in ipairs(self.OtherLockOutAnim) do
    if animation == anim then
      return true
    end
  end
  return false
end

function UMG_LockBall_C:OnChangeResolution()
  self.IsChangeResolution = true
end

return UMG_LockBall_C
