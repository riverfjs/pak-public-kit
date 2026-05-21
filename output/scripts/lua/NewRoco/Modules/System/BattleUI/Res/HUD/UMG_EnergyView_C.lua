require("UnLuaEx")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_EnergyView_C = NRCUmgClass:Extend("")

function UMG_EnergyView_C:Setup()
end

function UMG_EnergyView_C:Construct()
  if _G.BattleUtils.IsB1FinalBattleP2() then
    _G.UpdateManager:Register(self)
  end
end

function UMG_EnergyView_C:Destruct()
  self:ClearDelayWaitPlay()
  if _G.BattleUtils.IsB1FinalBattleP2() then
    _G.UpdateManager:UnRegister(self)
  end
end

function UMG_EnergyView_C:SetSlotsByB1FinalP2P3(Count)
  self.Point:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(BattleConst.BattleEnergyViewColor.TextNormal))
  self:TrySetPointText(Count)
  self.CurrentCount = Count
  self.On:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Off:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.GradePointAverage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_EnergyView_C:SetSlots(Count)
  Count = Count or 0
  if _G.BattleUtils.IsB1FinalBattleP2() or _G.BattleUtils.IsB1FinalBattleP3() then
    if _G.BattleUtils.IsB1FinalBattleP3() then
      Count = _G.DataConfigManager:GetBattleGlobalConfig("B1_FINAL_BATTLE_STATE3_INITIAL_GPA").num
    end
    self:SetSlotsByB1FinalP2P3(Count)
    return
  end
  if self.SyncCount and Count > self.SyncCount then
    Count = self.SyncCount
  end
  if Count > 0 then
    self.On:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.On:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Star:SetVisibility(UE4.ESlateVisibility.Visible)
  if Count < 0 then
    Log.Debug("error min energy found")
    Count = 0
  end
  self:TrySetPointText(Count)
  self.CurrentCount = Count
  if Count > 2 then
    self.Off:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.BackgroundGrey))
    self.Point:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(BattleConst.BattleEnergyViewColor.TextNormal))
    self.Star:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.StarYellow))
    self.On:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.StarYellow))
  else
    self.Off:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.BackgroundRed))
    self.Point:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(BattleConst.BattleEnergyViewColor.TextRed))
    self.Star:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.StarYellow))
    self.On:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.StarYellow))
  end
end

function UMG_EnergyView_C:SetPointText(Count)
  self.Point:SetText(tostring(Count))
  self.CurrentPoint = Count
end

function UMG_EnergyView_C:TrySetPointText(Count, isFormEnergyConvergence)
  if isFormEnergyConvergence then
    self:PlayJiDianEffectAnim(Count)
  else
    self:PlayGradePointAnim(Count)
    self:SetPointText(Count)
  end
end

function UMG_EnergyView_C:GradePointAddAnimInit()
  self.GradePointAnimTime = self.Jidian_Up1:GetEndTime()
  self.animTargetCount = 99
  self.animCurCount = 0
  self.animCurTime = 0
end

function UMG_EnergyView_C:GradePointAddAnimStart()
  self:GradePointAddAnimInit()
  self.GradePointAnimState = true
  _G.UpdateManager:Register(self)
  self:PlayAnimation(self.Jidian_Up1)
end

function UMG_EnergyView_C:OnTick(DeltaTime)
  if self.GradePointAnimState then
    if self.animCurTime + DeltaTime <= self.GradePointAnimTime then
      local ratio = (self.animCurTime + DeltaTime) / self.GradePointAnimTime
      self.animCurTime = self.animCurTime + DeltaTime
      self:SetGradePointByRatio(ratio)
    else
      self:SetGradePointByRatio(1)
      self.GradePointAnimState = false
      _G.UpdateManager:UnRegister(self)
    end
  end
end

function UMG_EnergyView_C:SetGradePointByRatio(ratio)
  self.animCurCount = math.floor(self.animTargetCount * ratio)
  self:TrySetPointText(self.animCurCount)
end

function UMG_EnergyView_C:JiDianLose()
  self:SetPointText(self.TargetPoint)
end

function UMG_EnergyView_C:ClearDelayWaitPlay()
  if self.DelayWaitPlayAnimId then
    _G.DelayManager:CancelDelayById(self.DelayWaitPlayAnimId)
    self.DelayWaitPlayAnimId = nil
  end
end

function UMG_EnergyView_C:CheckWaitPlayAnimQueue()
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  if self.waitPlayAnimQueue and self.waitPlayAnimQueue[1] then
    local animItem = table.remove(self.waitPlayAnimQueue, 1)
    self:SetGradePoint(animItem.Count, animItem.isFormEnergyConvergence)
    table.remove(self.waitPlayAnimQueue, 1)
  end
end

function UMG_EnergyView_C:OnAnimationFinished(Anim)
  self:ClearDelayWaitPlay()
  self.DelayWaitPlayAnimId = _G.DelayManager:DelayFrames(1, self.CheckWaitPlayAnimQueue, self)
end

function UMG_EnergyView_C:PlayJiDianEffectAnim(Count)
  if not _G.BattleUtils.IsB1FinalBattleP2() and not _G.BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if self.CurrentPoint then
    if self.CurrentPoint == Count then
      self:SetPointText(Count)
    elseif Count < self.CurrentPoint then
      self.Point_1:SetText(tostring(self.CurrentPoint - Count))
      if self:IsPlayingAnimation() then
        self:StopAllAnimations()
      end
      self:PlayAnimation(self.JiDian_Lose_2)
    else
      self:SetPointText(Count)
      if self:IsPlayingAnimation() then
        self:StopAllAnimations()
      end
      self:PlayAnimation(self.JiDian_Get)
    end
  else
    self:SetPointText(Count)
  end
  self.CurrentPoint = Count
  self.TargetPoint = Count
end

function UMG_EnergyView_C:PlayGradePointAnim(Count)
  if not _G.BattleUtils.IsB1FinalBattleP2() and not _G.BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if self:IsPlayingAnimation() then
    return
  end
  if self.CurrentPoint and Count < self.CurrentPoint then
    self:PlayAnimation(self.Grade_reduce)
  end
end

function UMG_EnergyView_C:SetEnergy(Count)
  local prevCount = self.CurrentCount
  self:PlayStarUpDownAnim(prevCount, Count)
  self:SetSlots(Count)
end

function UMG_EnergyView_C:PlayStarUpDownAnim(prevCount, nextCount)
  prevCount = prevCount or 0
  nextCount = nextCount or 0
  local isStarDownPlaying = self:IsAnimationPlaying(self.StarDown)
  local isStarUpPlaying = self:IsAnimationPlaying(self.StarUP)
  if isStarDownPlaying or isStarUpPlaying then
    return
  end
  if nil ~= nextCount then
    if prevCount > nextCount then
      self:PlayAnimation(self.StarDown, 0, 1, 0, 1, true)
    elseif prevCount < nextCount then
      self:PlayAnimation(self.StarUP)
    end
  end
end

function UMG_EnergyView_C:PlaySteal()
  self:PlayAnimation(self.Star_Steal)
end

function UMG_EnergyView_C:GetPerformCount()
  return self.CurrentCount
end

function UMG_EnergyView_C:GetSyncCount()
  return self.SyncCount
end

function UMG_EnergyView_C:SetSyncCount(value)
  self.SyncCount = value or 0
end

function UMG_EnergyView_C:GetCurrentPoint()
  return self.CurrentPoint
end

function UMG_EnergyView_C:SetGradePoint(point, isFormEnergyConvergence)
  if _G.BattleUtils.IsB1FinalBattleP3() then
    point = _G.DataConfigManager:GetBattleGlobalConfig("B1_FINAL_BATTLE_STATE3_INITIAL_GPA").num
  end
  if self.CurrentPoint == point then
    return
  end
  if self:IsPlayingAnimation() then
    if not self.waitPlayAnimQueue then
      self.waitPlayAnimQueue = {}
    end
    table.insert(self.waitPlayAnimQueue, {Count = point, isFormEnergyConvergence = isFormEnergyConvergence})
    return
  end
  self:TrySetPointText(point, isFormEnergyConvergence)
  self.CurrentPoint = point
end

function UMG_EnergyView_C:SetMaxGradePoint(point)
  self.maxGradePoint = point
end

function UMG_EnergyView_C:JiDianUp2AnimEnd()
  self:SetGradePoint(self.maxGradePoint)
end

function UMG_EnergyView_C:JiDianUp1AnimEnd()
  self:PlayAnimation(self.Jidian_Up2)
end

function UMG_EnergyView_C:CheckB1FinalBattleP1UI()
  if not _G.BattleUtils.IsB1FinalBattleP1() then
    return
  end
  self.On:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Star:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(BattleConst.BattleEnergyViewColor.StarPurple))
  self.Star:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Off:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.GradePointAverage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Point:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Point_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Infinite:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CanvasPanel_117:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_EnergyView_C
