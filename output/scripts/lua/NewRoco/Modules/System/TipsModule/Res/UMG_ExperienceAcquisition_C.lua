local LevelUpUtils = require("NewRoco.Modules.System.LevelUpUI.LevelUpUtils")
local UMG_ExperienceAcquisition_C = _G.NRCPanelBase:Extend("UMG_ExperienceAcquisition_C")

function UMG_ExperienceAcquisition_C:OnActive()
end

function UMG_ExperienceAcquisition_C:OnConstruct()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ExperienceAcquisition_C:OnDestruct()
end

function UMG_ExperienceAcquisition_C:SetParent(parent)
  self.ParentPanel = parent
end

function UMG_ExperienceAcquisition_C:GetExpText(expInfo)
  return string.format(LuaText.umg_experienceacquisition_1, expInfo.addExp)
end

function UMG_ExperienceAcquisition_C:SetExpUpInfo(expInfo)
  self.DeltaTimer = 0.0
  self.FinishTime = 1.0
  self:StopAllAnimations()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCAudioManager:PlaySound2DAuto(1220002122, "UMG_ExperienceAcquisition_C:SetExpUpInfo")
  local targetMaxExp = expInfo.targetMaxExp
  local MaxLevel
  if not targetMaxExp then
    local targetRoleExpConf = LevelUpUtils.GetRoleExpConfByPlayerLevel(expInfo.newLevel)
    targetMaxExp = targetRoleExpConf and targetRoleExpConf.need_exp or -1
    local RoleExpConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ROLE_EXP_CONF):GetAllDatas()
    MaxLevel = RoleExpConf[#RoleExpConf].id
  end
  if MaxLevel and expInfo.oldLevel == MaxLevel and expInfo.newLevel == MaxLevel then
    local targetRoleExpConf = LevelUpUtils.GetRoleExpConfByPlayerLevel(expInfo.newLevel - 1)
    targetMaxExp = targetRoleExpConf and targetRoleExpConf.need_exp or -1
    if expInfo.addExp < 0 then
      expInfo.addExp = targetMaxExp + expInfo.addExp
      expInfo.newExp = targetMaxExp + expInfo.newExp
    end
    self:NoUpgrade(expInfo, targetMaxExp)
    return
  end
  if expInfo.newLevel ~= expInfo.oldLevel then
    self:PlayAnimation(self.Exp_levelup)
    self.newExp = expInfo.oldExp
    self.targetMaxExp = expInfo.newExp
    self.Text_Lv:SetText(expInfo.oldLevel)
    self.Text_Lv_up:SetText(expInfo.newLevel)
    self.Text_Lv_up:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_Lv:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ProgressBar_44:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.LevelUpBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_Lv_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.IconBg:SetRenderScale(UE4.FVector2D(0.85, 0.85))
    self.IconBg1:SetRenderScale(UE4.FVector2D(0.85, 0.85))
    local LevelUpText = string.format("%d%s%d", expInfo.newExp, "/", targetMaxExp)
    self.TextHeroLV_1:SetText(LevelUpText)
    self.ProgressBarBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:NoUpgrade(expInfo, targetMaxExp)
  end
end

function UMG_ExperienceAcquisition_C:NoUpgrade(expInfo, targetMaxExp)
  self:PlayAnimation(self.Exp_open)
  local expText = self:GetExpText(expInfo)
  self.TextHeroLV:SetText(expText)
  self.newExp = expInfo.oldExp
  self.targetMaxExp = expInfo.newExp
  self.targetExp = targetMaxExp
  self.Text_Lv:SetText(expInfo.newLevel)
  self.Text_Lv_up:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.LevelUpBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Text_Lv_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.IconBg:SetRenderScale(UE4.FVector2D(0.73, 0.73))
  self.IconBg1:SetRenderScale(UE4.FVector2D(0.73, 0.73))
  self.Text_Lv:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ProgressBar_44:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ProgressBarBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ProgressBar_44:SetFillAmount(expInfo.oldExp / targetMaxExp * 0.8 + 0.1)
  local LevelUpText = string.format("%d%s%d", expInfo.newExp, "/", targetMaxExp)
  self.TextHeroLV_1:SetText(LevelUpText)
  self.TextHint:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_ExperienceAcquisition_C:OnTick(InDeltaTime)
  if self.tipsPaused then
    return
  end
  if self.LerpToNewFillAmount and self.DeltaTimer and self.FinishTime then
    self.DeltaTimer = self.DeltaTimer + InDeltaTime
    local ratio = self.DeltaTimer / self.FinishTime
    local percent = math.clamp(ratio, 0, 1)
    local Exp = self.newExp * (1 - percent) + self.targetMaxExp * percent
    if math.abs(Exp - self.targetMaxExp) < 0.01 then
      Exp = self.targetMaxExp
      self.LerpToNewFillAmount = false
      self.DeltaTimer = 0
      self:DelaySeconds(1, function()
        self:PlayAnimation(self.Exp_close)
      end)
    else
      self.ProgressBar_44:SetFillAmount(Exp / self.targetExp * 0.8 + 0.1)
    end
  end
end

function UMG_ExperienceAcquisition_C:SetExpTextVisible(bVisible)
  if bVisible then
    self.TextHint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TextHeroLV:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TextHint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TextHeroLV:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ExperienceAcquisition_C:OnAnimationFinished(Anim)
  if Anim == self.Exp_open then
    self.LerpToNewFillAmount = true
  elseif Anim == self.Exp_levelup then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ParentPanel:ConsumeNext()
  elseif Anim == self.Exp_close then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ParentPanel:ConsumeNext()
  end
end

function UMG_ExperienceAcquisition_C:SetPaused(pause, desireRecoverable)
  self.tipsPaused = pause
  if pause then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  return true
end

return UMG_ExperienceAcquisition_C
