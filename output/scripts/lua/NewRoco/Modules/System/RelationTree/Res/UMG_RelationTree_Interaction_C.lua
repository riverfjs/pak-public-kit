local UMG_RelationTree_Interaction_C = _G.NRCPanelBase:Extend("UMG_RelationTree_Interaction_C")
local State = {Dark = 1, Bright = 2}

function UMG_RelationTree_Interaction_C:OnConstruct()
  Log.Debug("UMG_RelationTree_Interaction_C:OnConstruct")
end

function UMG_RelationTree_Interaction_C:OnActive()
  self.BubbleState = State.Dark
  self.PendingCollapse = false
end

function UMG_RelationTree_Interaction_C:OnAddEventListener()
end

function UMG_RelationTree_Interaction_C:StopAllAnims()
  self.stopingAnim = true
  self:StopAllAnimations()
  self.stopingAnim = false
end

function UMG_RelationTree_Interaction_C:PlayLoopByState()
  if self.IsNotLoopAnim then
    return
  end
  if self.BubbleState == State.Bright then
    if self.BrightLoop then
      self:StopAllAnims()
      self:PlayAnimation(self.BrightLoop, 0, 0)
    end
  elseif self.DarkLoop then
    self:StopAllAnims()
    self:PlayAnimation(self.DarkLoop, 0, 0)
  end
end

function UMG_RelationTree_Interaction_C:PlayerAnimIn()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:StopAllAnims()
  if self.BubbleState == State.Bright then
    if self.BrightIn then
      self:PlayAnimation(self.BrightIn)
      if not self.forbiddenAudio then
        UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction_C:Anim.BrightIn")
      end
    else
      self:PlayLoopByState()
    end
  elseif self.DarkIn then
    self:PlayAnimation(self.DarkIn)
    if not self.forbiddenAudio then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction_C:Anim.DarkIn")
    end
  else
    self:PlayLoopByState()
  end
  self.forbiddenAudio = nil
end

function UMG_RelationTree_Interaction_C:PlayerAnimOut()
  self.PendingCollapse = true
  self:StopAllAnims()
  local outAnim
  if self.BubbleState == State.Bright then
    outAnim = self.BrightOut
  else
    outAnim = self.DarkOut
  end
  if outAnim then
    self:PlayAnimation(outAnim)
  else
    self.PendingCollapse = false
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RelationTree_Interaction_C:SetHeadHUD_BGYellow(IsYellow)
  if IsYellow then
    if self.Bright2Dark then
      self:StopAnimation(self.Bright2Dark)
    end
    local vis = self:GetVisibility()
    local isVisible = vis ~= UE4.ESlateVisibility.Collapsed and vis ~= UE4.ESlateVisibility.Hidden
    if isVisible and self.BubbleState == State.Dark then
      self.BubbleState = State.Bright
      self:StopAllAnims()
      if self.Dark2Bright then
        self:PlayAnimation(self.Dark2Bright)
        UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction_C:Anim.Dark2Bright")
      else
        self:PlayLoopByState()
      end
    else
      self.BubbleState = State.Bright
    end
  else
    if self.Dark2Bright then
      self:StopAnimation(self.Dark2Bright)
    end
    local isBubbleStateOriNil = self.BubbleState == nil
    local wasBright = self.BubbleState == State.Bright
    self.BubbleState = State.Dark
    local vis = self:GetVisibility()
    local isVisible = vis ~= UE4.ESlateVisibility.Collapsed and vis ~= UE4.ESlateVisibility.Hidden
    if isVisible and (wasBright or isBubbleStateOriNil) then
      self:StopAllAnims()
      if self.Bright2Dark then
        self:PlayAnimation(self.Bright2Dark)
      else
        self:PlayLoopByState()
      end
    end
  end
end

function UMG_RelationTree_Interaction_C:PlayerAnimChangeOut(IsRequests, RelationTreeType, ActionID, IsNotLoopAnim)
  self.ChangeData = {
    IsRequests = IsRequests,
    RelationTreeType = RelationTreeType,
    ActionID = ActionID,
    IsNotLoopAnim = IsNotLoopAnim
  }
  self.IsNotLoopAnim = IsNotLoopAnim
  self:StopAllAnims()
  self:UpdateHeadHUD(IsRequests, RelationTreeType, ActionID, IsNotLoopAnim, false, false)
  self:PlayerAnimChangeIn()
end

function UMG_RelationTree_Interaction_C:PlayerAnimChangeIn()
  self.BubbleState = State.Bright
  self:StopAllAnims()
  if self.Dark2Bright then
    self:PlayAnimation(self.Dark2Bright)
    if not self.forbiddenAudio then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40004007, "UMG_RelationTree_Interaction_C:Anim.Dark2Bright")
    end
  else
    self:PlayLoopByState()
  end
  self.forbiddenAudio = nil
end

function UMG_RelationTree_Interaction_C:UpdateHeadHUD(IsRequests, RelationTreeType, ActionID, IsNotLoopAnim, IsPlayAnimIn, IsChangeAnimIn, forbiddenAudio)
  if RelationTreeType then
    local RelationNode = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNodeByEnum, RelationTreeType)
    if RelationNode then
      self.IconPath = RelationNode.StateStruct[1].icon
    end
  elseif ActionID then
    local Config = _G.DataConfigManager:GetRelationtreeAnimConf(ActionID)
    if Config and Config.name_icon_struct and Config.name_icon_struct[2] then
      self.IconPath = Config.name_icon_struct[2].icon
    end
  end
  self.IsNotLoopAnim = IsNotLoopAnim
  if IsRequests then
    self.NRCSwitcher:SetActiveWidgetIndex(0)
    self:UpdateUI(IsPlayAnimIn, IsChangeAnimIn, forbiddenAudio)
  else
    self.NRCSwitcher:SetActiveWidgetIndex(1)
  end
  self.ChangeData = nil
end

function UMG_RelationTree_Interaction_C:UpdateUI(IsPlayAnimIn, IsChangeAnimIn, forbiddenAudio)
  if self.IconPath and self.IconPath ~= "" then
    if IsPlayAnimIn then
      self.forbiddenAudio = forbiddenAudio
      self.Icon:SetPathWithCallBack(self.IconPath, {
        self,
        self.PlayerAnimIn
      })
    elseif IsChangeAnimIn then
      self.forbiddenAudio = forbiddenAudio
      self.Icon:SetPathWithCallBack(self.IconPath, {
        self,
        self.PlayerAnimChangeIn
      })
    else
      self.Icon:SetPath(self.IconPath)
    end
  end
end

function UMG_RelationTree_Interaction_C:OnAnimationFinished(anim)
  if self.stopingAnim then
    Log.DebugFormat("UMG_RelationTree_Interaction_C:OnAnimationFinished stopingAnim, ignore anim finish event for anim %s", anim and anim:GetName() or "nil")
    return
  end
  if anim == self.DarkIn then
    self:PlayLoopByState()
    return
  end
  if anim == self.BrightIn then
    self:PlayLoopByState()
    return
  end
  if anim == self.Dark2Bright then
    self.BubbleState = State.Bright
    self:PlayLoopByState()
    return
  end
  if anim == self.Bright2Dark then
    self.BubbleState = State.Dark
    self:PlayLoopByState()
    return
  end
  if anim == self.DarkOut then
    if self.PendingCollapse then
      self.PendingCollapse = false
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    return
  end
  if anim == self.BrightOut then
    if self.PendingCollapse then
      self.PendingCollapse = false
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    return
  end
end

function UMG_RelationTree_Interaction_C:OnDeactive()
end

return UMG_RelationTree_Interaction_C
