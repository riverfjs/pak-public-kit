local UMG_Activity_Base_C = _G.NRCPanelBase:Extend("UMG_Activity_Base_C")

function UMG_Activity_Base_C:BindUIElements()
  self:LogError("Inherited class must implement BindUIElements function!")
end

function UMG_Activity_Base_C:ReBindUIElements(onlyChangeAnimation, replacePlayingAnimation)
  local oldElements = self.uiElements
  self.uiElements = self:BindUIElements()
  self:OnBindUIElementsChanged(oldElements, onlyChangeAnimation, replacePlayingAnimation)
end

function UMG_Activity_Base_C:OnBindUIElementsChanged(oldElements, onlyChangeAnimation, replacePlayingAnimation)
  local _uiElements = self.uiElements
  local oldLoopAnimName = oldElements and oldElements.loopAnimName
  local newLoopAnimName = _uiElements and _uiElements.loopAnimName
  if oldLoopAnimName ~= newLoopAnimName then
    self:StopAnimationByName(oldLoopAnimName)
    if self.isShowing then
      self:PlayAnimationByName(newLoopAnimName, true)
    end
  end
  local _activityInst = self.activityInst
  if _uiElements and _activityInst then
    if not onlyChangeAnimation then
      if _uiElements.timeRemaining then
        _activityInst:UnBindActivityTimeLeft(_uiElements.timeRemaining)
        local timeRemainingRoot = _uiElements.timeRemainingRoot or _uiElements.timeRemaining:GetParent()
        local leftTime = _activityInst:GetActivityTimeLeft()
        if leftTime == math.maxinteger then
          if timeRemainingRoot then
            timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
        else
          if timeRemainingRoot then
            timeRemainingRoot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          end
          _activityInst:BindActivityTimeLeft(_uiElements.timeRemaining)
        end
      end
      if _uiElements.particularsBtn then
        _activityInst:UnBindActivityDesc(_uiElements.particularsBtn)
        _activityInst:BindActivityDesc(_uiElements.particularsBtn, self)
      end
      if _uiElements.title then
        _uiElements.title:SetText(_activityInst:GetActivityName())
      end
      if _uiElements.promptText then
        _uiElements.promptText:SetText(_activityInst:GetActivityPromptText())
      end
      if _uiElements.titleLabelIcon then
        local titleIcon = _activityInst:GetTitleIcon()
        if not string.IsNilOrEmpty(titleIcon) then
          _uiElements.titleLabelIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          _uiElements.titleLabelIcon:SetPath(titleIcon)
        else
          _uiElements.titleLabelIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      if _uiElements.titleLabelText then
        _uiElements.titleLabelText:SetText(_activityInst:GetTitleIconText())
      end
      if _uiElements.bgImage then
        local imagePath = _activityInst:GetUmgImagePath()
        if not string.IsNilOrEmpty(imagePath) then
          _uiElements.bgImage:SetPath(imagePath)
        end
      end
    end
    if string.IsNilOrEmpty(_uiElements.openAnimName) or not self[_uiElements.openAnimName] then
      _uiElements.openAnimName = _activityInst:GetOpenAnimationName()
    end
    if string.IsNilOrEmpty(_uiElements.closeAnimName) or not self[_uiElements.closeAnimName] then
      _uiElements.closeAnimName = _activityInst:GetCloseAnimationName()
    end
    if string.IsNilOrEmpty(_uiElements.changeAnimName) or not self[_uiElements.changeAnimName] then
      _uiElements.changeAnimName = _activityInst:GetOpenAnimationName()
    end
    if string.IsNilOrEmpty(_uiElements.loopAnimName) or not self[_uiElements.loopAnimName] then
      _uiElements.loopAnimName = _activityInst:GetLoopAnimationName()
    end
    if string.IsNilOrEmpty(_uiElements.openAnimName) then
      _uiElements.openAnimName = "Open"
    end
    if string.IsNilOrEmpty(_uiElements.closeAnimName) then
      _uiElements.closeAnimName = "Close"
    end
    if string.IsNilOrEmpty(_uiElements.changeAnimName) then
      _uiElements.changeAnimName = "Change"
    end
    if replacePlayingAnimation and oldElements then
      if oldElements.openAnimName ~= _uiElements.openAnimName and self:CheckIsAnimationPlaying(oldElements.openAnimName) then
        self:StopAnimationByName(oldElements.openAnimName)
        self:PlayAnimationByName(_uiElements.openAnimName)
      end
      if oldElements.changeAnimName ~= _uiElements.changeAnimName and self:CheckIsAnimationPlaying(oldElements.changeAnimName) then
        self:StopAnimationByName(oldElements.changeAnimName)
        self:PlayAnimationByName(_uiElements.changeAnimName)
      end
    end
  end
end

function UMG_Activity_Base_C:OnOpenView()
  local _uiElements = self.uiElements
  self:PlayAnimationByName(_uiElements and _uiElements.openAnimName)
end

function UMG_Activity_Base_C:OnCloseView()
  local _uiElements = self.uiElements
  self:PlayAnimationByName(_uiElements and _uiElements.closeAnimName)
end

function UMG_Activity_Base_C:OnConstruct()
  local _uiElements = self:BindUIElements()
  if not _uiElements then
    self:LogError("BindUIElements function must return valid table!")
  else
    self.uiElements = _uiElements
    self:OnBindUIElementsChanged()
    local activityInst = self.activityInst
    if _uiElements.desireActivityType and activityInst and _uiElements.desireActivityType ~= activityInst:GetActivityType() then
      NRCUtils.LuaFatalError(string.format("\233\133\141\231\189\174\233\148\153\232\175\175!! %s bind activity_type=%d, but config activity_type=%d in activity=%d", activityInst:GetUmgPath(), _uiElements.desireActivityType, activityInst:GetActivityType(), activityInst:GetActivityId()), "Activity type mismatch!")
    end
  end
end

function UMG_Activity_Base_C:OnEnable(firstLoad)
  self.isShowing = true
  _G.NRCAudioManager:PlaySound2DAuto(40010023, "UMG_Activity_Base_C:OnEnable")
  if not firstLoad then
    local _uiElements = self.uiElements
    if _uiElements then
      local canPlayChangeAnim = true
      if self:CheckIsAnimationPlaying(_uiElements.openAnimName) and _uiElements.openAnimName ~= _uiElements.changeAnimName then
        canPlayChangeAnim = false
      end
      if canPlayChangeAnim then
        self:StopAnimationByName(_uiElements.changeAnimName)
        self:PlayAnimationByName(_uiElements.changeAnimName)
      end
    end
  end
  if self.activityInst then
    local bgm = self.activityInst:GetActivityBgm()
    if not string.IsNilOrEmpty(bgm) then
      _G.NRCAudioManager:SetStateByName(bgm, "Enter", "UMG_Activity_Base_C")
    end
  end
  local _uiElements = self.uiElements
  if _uiElements then
    self:PlayAnimationByName(_uiElements.loopAnimName, true)
  end
end

function UMG_Activity_Base_C:OnDisable()
  self.isShowing = false
  if self.activityInst then
    local bgm = self.activityInst:GetActivityBgm()
    if not string.IsNilOrEmpty(bgm) then
      _G.NRCAudioManager:SetStateByName(bgm, "None", "UMG_Activity_Base_C")
    end
  end
  local _uiElements = self.uiElements
  if _uiElements then
    self:StopAnimationByName(_uiElements.loopAnimName)
  end
end

function UMG_Activity_Base_C:OnDestruct()
end

function UMG_Activity_Base_C:PlayAnimationByName(animName, loop)
  if not string.IsNilOrEmpty(animName) then
    local anim = self[animName]
    if anim then
      if loop then
        self:PlayAnimation(anim, 0, 0)
      else
        self:PlayAnimation(anim)
      end
    end
  end
end

function UMG_Activity_Base_C:StopAnimationByName(animName)
  if not string.IsNilOrEmpty(animName) then
    local anim = self[animName]
    if anim then
      self:StopAnimation(anim)
    end
  end
end

function UMG_Activity_Base_C:CheckIsAnimationPlaying(animName)
  if not string.IsNilOrEmpty(animName) then
    local anim = self[animName]
    if anim then
      return self:IsAnimationPlaying(anim)
    end
  end
  return false
end

function UMG_Activity_Base_C:GetCloseBtnImagePath()
  return _G.UEPath.CLOSE_BTN_WHITE
end

function UMG_Activity_Base_C:OnItemUpdate(_itemInst, _index, _customData)
end

function UMG_Activity_Base_C:OnItemSelected(_itemInst, _index, _customData, _bSelected)
end

function UMG_Activity_Base_C:OnItemOp(_itemInst, _index, _customData, _opType)
end

function UMG_Activity_Base_C:OnItemRefreshView(_itemInst, _index, _customData)
end

return UMG_Activity_Base_C
