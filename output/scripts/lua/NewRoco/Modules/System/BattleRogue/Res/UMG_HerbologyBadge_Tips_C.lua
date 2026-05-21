local UMG_HerbologyBadge_Tips_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_Tips_C")

function UMG_HerbologyBadge_Tips_C:OnConstruct()
  self.FinishedCallback = nil
  self.bAutoClose = true
  if self.CloseBtn then
    self:AddButtonListener(self.CloseBtn, self.OnCloseBtnClicked)
  end
end

function UMG_HerbologyBadge_Tips_C:OnCloseBtnClicked()
  if not self.bAutoClose then
    self:DoClose()
  end
end

function UMG_HerbologyBadge_Tips_C:OnActive(bNotAutoClose, caller, callback)
  local trialId = self.module.Data.TrialID
  if not trialId then
    Log.Error("UMG_HerbologyBadge_Tips_C: trialId is nil")
    self:DoClose()
    return
  end
  local TrialConf = _G.DataConfigManager:GetGrassTrialConf(trialId)
  if not TrialConf then
    Log.Error("UMG_HerbologyBadge_Tips_C: TrialConf not found for trialId", trialId)
    self:DoClose()
    return
  end
  if caller and callback then
    self.FinishedCallback = _G.MakeWeakFunctor(caller, callback)
  end
  self.bAutoClose = not bNotAutoClose
  self.Title:SetText(LuaText.grass_trial_tips)
  if self.bAutoClose then
    self:PlayAnimation(self.Event)
  else
    self:PlayAnimationTimeRange(self.Event, 0, 1.5)
  end
  local ruleDescs = {}
  if TrialConf.rule then
    for _, ruleId in ipairs(TrialConf.rule) do
      local effectConf = _G.DataConfigManager:GetGrassTrialEffectConf(ruleId)
      if effectConf and effectConf.info and effectConf.info ~= "" then
        table.insert(ruleDescs, effectConf.info)
      end
    end
  end
  if #ruleDescs > 0 then
    self.Title_Describe:SetText(table.concat(ruleDescs, "\n"))
  else
    self.Title_Describe:SetText("")
  end
end

function UMG_HerbologyBadge_Tips_C:OnDestruct()
  self.FinishedCallback = nil
end

function UMG_HerbologyBadge_Tips_C:OnAnimationFinished(Anim)
  if Anim == self.Event and self.bAutoClose then
    if self.FinishedCallback then
      self.FinishedCallback()
      self.FinishedCallback = nil
    end
    self:DoClose()
  end
end

return UMG_HerbologyBadge_Tips_C
