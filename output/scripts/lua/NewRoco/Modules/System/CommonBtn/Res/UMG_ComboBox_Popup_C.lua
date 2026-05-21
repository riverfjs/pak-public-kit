local UMG_ComboBox_Popup_C = _G.NRCPanelBase:Extend("UMG_ComboBox_Popup_C")

function UMG_ComboBox_Popup_C:OnConstruct()
  Log.Debug("UMG_ComboBox_Popup_C OnConstruct")
  self.isLastPressed = false
  self.lastScreenPosX = 0
  self.lastScreenPosY = 0
  self.InAnimCallBack = nil
  self.InAnim = self.In2
  self.OutAnim = self.Out2
  self.OnVisibilityChanged:Add(self, self.HandleOnVisibilityChanged)
end

function UMG_ComboBox_Popup_C:HandleOnVisibilityChanged()
  if self:IsVisible() then
    Log.Debug("UMG_ComboBox_Popup_C is now visible")
    self.isLastPressed = false
    self.lastScreenPosX = 0
    self.lastScreenPosY = 0
    _G.UpdateManager:Register(self)
  else
    Log.Debug("UMG_ComboBox_Popup_C is now hidden")
    self.isLastPressed = false
    self.lastScreenPosX = 0
    self.lastScreenPosY = 0
    _G.UpdateManager:UnRegister(self)
  end
end

function UMG_ComboBox_Popup_C:OnDestruct()
  Log.Debug("UMG_ComboBox_Popup_C OnDestruct")
end

function UMG_ComboBox_Popup_C:OnActive()
end

function UMG_ComboBox_Popup_C:OnDeactive()
end

function UMG_ComboBox_Popup_C:OnAddEventListener()
end

function UMG_ComboBox_Popup_C:SetAutoCheckClose(autoCheckClose)
  self.AutoCheckClose = autoCheckClose or false
  self.isLastPressed = false
  self.lastScreenPosX = 0
  self.lastScreenPosY = 0
end

function UMG_ComboBox_Popup_C:SetListTitle(listInfo)
  if listInfo then
    self.List_title:InitList(listInfo)
  end
end

function UMG_ComboBox_Popup_C:SelectListItem(itemIndex)
  self.List_title:SelectItemByIndex(itemIndex)
end

function UMG_ComboBox_Popup_C:OnTick(InDeltaTime)
  if not self.AutoCheckClose then
    return
  end
  if not self:IsVisible() then
    self.isLastPressed = false
    self.lastScreenPosX = 0
    self.lastScreenPosY = 0
    return
  end
  local isTouchEnded = false
  local locationX, locationY, bPressed = UE.UNRCStatics.GetTouchStateFromRocoPreInputProcessor(0)
  if bPressed then
    self.isLastPressed = true
    self.lastScreenPosX = locationX
    self.lastScreenPosY = locationY
  else
    isTouchEnded = self.isLastPressed
    self.isLastPressed = false
  end
  if isTouchEnded then
    local absPos
    if _G.RocoEnv.IS_EDITOR then
      local ScreenPos = UE4.FVector2D(self.lastScreenPosX, self.lastScreenPosY)
      Log.Debug("UMG_ComboBox_Popup_C:OnTick - EDITOR ScreenPos: " .. tostring(ScreenPos))
      absPos = UE.UNRCStatics.ConvertSceneViewportToAbsolutePosition(ScreenPos)
      Log.Debug("UMG_ComboBox_Popup_C:OnTick - EDITOR Absolute Position: " .. tostring(absPos))
    else
      absPos = UE4.FVector2D(self.lastScreenPosX, self.lastScreenPosY)
      Log.Debug("UMG_ComboBox_Popup_C:OnTick - Game Screen Position: " .. tostring(absPos))
    end
    local targetGeometry = self.CanvasPanel_1 and self.CanvasPanel_1:GetCachedGeometry() or self:GetCachedGeometry()
    if UE4.USlateBlueprintLibrary.IsUnderLocation(targetGeometry, absPos) then
      Log.Debug("UMG_ComboBox_Popup_C:OnTick - Clicked inside the widget")
    else
      Log.Debug("UMG_ComboBox_Popup_C:OnTick - Clicked outside, close the popup")
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ComboBox_Popup_C:PlayAnimationInfo(IsIn)
  self:StopAllAnimations()
  if IsIn then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.InAnim)
  else
    self:PlayAnimation(self.OutAnim)
  end
end

function UMG_ComboBox_Popup_C:OnAnimationFinished(Anim)
  if Anim == self.OutAnim then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Anim == self.InAnim and self.InAnimCallBack then
    self.InAnimCallBack()
  end
end

function UMG_ComboBox_Popup_C:SetInAnimCallBack(cb)
  self.InAnimCallBack = cb
end

function UMG_ComboBox_Popup_C:SetAnimChoice(isDown)
  if isDown then
    self.InAnim = self.In
    self.OutAnim = self.Out
  else
    self.InAnim = self.In2
    self.OutAnim = self.Out2
  end
end

return UMG_ComboBox_Popup_C
