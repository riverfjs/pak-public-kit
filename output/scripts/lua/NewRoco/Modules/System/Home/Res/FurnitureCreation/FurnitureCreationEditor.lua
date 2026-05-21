local FurnitureCreationEditor = Class("FurnitureCreationEditor")

function FurnitureCreationEditor:Ctor(Panel)
  self.FurnitureCreationPanel = Panel
  self.FurnitureContext = {}
  self:Init()
end

function FurnitureCreationEditor:Init()
  self.bEnabled = false
  if self.bEnabled then
    local Panel = self.FurnitureCreationPanel
    Panel.Slider_72.OnValueChanged:Add(Panel, function()
      return self:OnDebugScaleSliderValChanged()
    end)
    Panel.Slider.OnValueChanged:Add(Panel, function()
      return self:OnDebugRotateSliderValChanged()
    end)
    Panel:AddButtonListener(Panel.Button, function()
      return self:OnDebugCopyRotation()
    end)
    Panel:AddButtonListener(Panel.Button_125, function()
      return self:OnDebugCopyLocation()
    end)
    Panel.UsernameDisplay.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeX()
    end)
    Panel.UsernameDisplay_1.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeY()
    end)
    Panel.UsernameDisplay_2.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeZ()
    end)
    Panel.UsernameDisplay_3.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeRX()
    end)
    Panel.UsernameDisplay_4.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeRY()
    end)
    Panel.UsernameDisplay_5.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeRZ()
    end)
    Panel.UsernameDisplay_6.OnTextCommitted:Add(Panel, function()
      return self:OnDebugChangeScale()
    end)
    Panel.CanvasPanel_211:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
end

function FurnitureCreationEditor:ForceHide()
  self.FurnitureCreationPanel.CanvasPanel_211:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function FurnitureCreationEditor:ConditionShow()
  if self.bEnabled then
    self.FurnitureCreationPanel.CanvasPanel_211:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:RefreshEditorView()
  end
end

function FurnitureCreationEditor:RefreshEditorView()
  if self.bEnabled then
    local Panel = self.FurnitureCreationPanel
    Panel.TextBlock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    Panel.TextBlock_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    Panel.Button_125:SetVisibility(UE.ESlateVisibility.Visible)
    Panel.Button:SetVisibility(UE.ESlateVisibility.Visible)
    local FurnitureView = self:GetFurnitureView()
    local Transform = FurnitureView and FurnitureView:K2_GetRootComponent():GetRelativeTransform()
    local Location = Transform and Transform.Translation or FVectorZero
    local Rotation = Transform and Transform.Rotation and Transform.Rotation:ToRotator() or FRotatorZero
    Panel.Slider:SetMaxValue(1)
    Panel.Slider:SetMinValue(0)
    local V = Rotation.Yaw
    if V < 0 then
      V = V + 360
    end
    Panel.Slider:SetValue(V / 360)
    Panel.TextBlock:SetText(string.format("%d;%d;%d", math.floor(Location.X * 100), math.floor(Location.Y * 100), math.floor(Location.Z * 100)))
    Panel.TextBlock_1:SetText(string.format("%d;%d;%d", math.floor(Rotation.Roll * 100), math.floor(Rotation.Pitch * 100), math.floor(Rotation.Yaw * 100)))
    Panel.UsernameDisplay:SetText(math.floor(Location.X * 100))
    Panel.UsernameDisplay_1:SetText(math.floor(Location.Y * 100))
    Panel.UsernameDisplay_2:SetText(math.floor(Location.Z * 100))
    Panel.UsernameDisplay_3:SetText(math.floor(Rotation.Roll * 100))
    Panel.UsernameDisplay_4:SetText(math.floor(Rotation.Pitch * 100))
    Panel.UsernameDisplay_5:SetText(math.floor(Rotation.Yaw * 100))
    local Scale = (FurnitureView and FurnitureView:K2_GetRootComponent():GetRelativeTransform().Scale3D.X or 1) * 10
    Panel.Slider_72:SetMaxValue(2)
    Panel.Slider_72:SetMinValue(0.1)
    Panel.Slider_72:SetValue(Scale)
    Panel.UsernameDisplay_6:SetTexT(math.floor(Scale * 10000))
  end
end

function FurnitureCreationEditor:OnDebugScaleSliderValChanged()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local Panel = self.FurnitureCreationPanel
  local Scale = Panel.Slider_72:GetValue()
  local View = self:GetFurnitureView()
  View:K2_GetRootComponent():SetRelativeScale3D((UE.FVector(Scale / 10, Scale / 10, Scale / 10)))
  Scale = math.floor(Scale * 10000)
  Panel.UsernameDisplay_6:SetText(tostring(Scale))
  Context.Scale = Scale
end

function FurnitureCreationEditor:GetContext()
  if not self.bEnabled then
    return
  end
  local Manager = self.FurnitureCreationPanel.FurnitureManager
  if not Manager.FurnitureConf then
    return
  end
  local ContextId = Manager.FurnitureConf.id
  local Context = self.FurnitureContext[ContextId]
  return Context
end

function FurnitureCreationEditor:ResetDebuggingFurniture()
  if self.bEnabled then
    local Context = self:GetContext()
    if Context then
      Context.bDebug = false
    end
  end
end

function FurnitureCreationEditor:GetOrCreateContext()
  if not self.bEnabled then
    return
  end
  local Manager = self.FurnitureCreationPanel.FurnitureManager
  if not Manager.FurnitureConf then
    return
  end
  local ContextId = Manager.FurnitureConf.id
  local Context = self.FurnitureContext[ContextId]
  if not Context then
    Context = {}
    self.FurnitureContext[ContextId] = Context
  end
  if not Context.bDebug then
    Context.bDebug = true
    local FurnitureView = Manager.FurniturePreview
    for k, v in pairs(Manager.SequencePlayers) do
      v:GetSequencePlayer():Stop()
    end
    if FurnitureView and UE.UObject.IsValid(FurnitureView) then
      FurnitureView:K2_SetActorRelativeTransform(Manager.FurnitureInitTransform, false, nil, false)
      Manager.FurnitureRootView:K2_SetActorRelativeTransform(Manager.FurnitureRootInitTransform, false, nil, false)
    end
  end
  return Context
end

function FurnitureCreationEditor:GetFurnitureView()
  return self.FurnitureCreationPanel.FurnitureManager.FurnitureView
end

function FurnitureCreationEditor:OnDebugRotateSliderValChanged()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Value = self.FurnitureCreationPanel.Slider:GetValue()
  local r = Value * 360
  local rot = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Rotation:ToRotator()
  rot.Yaw = r
  FurnitureView:K2_GetRootComponent():K2_SetRelativeRotation(rot, false, nil, false)
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugCopyRotation()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local Panel = self.FurnitureCreationPanel
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\229\183\178\231\187\143\230\139\183\232\180\157\230\156\157\229\144\145\228\191\161\230\129\175\239\188\154" .. Panel.TextBlock_1:GetText())
  UE4.UNRCStatics.ClipboardCopy(Panel.TextBlock_1:GetText())
  Context.RotationString = Panel.TextBlock_1:GetText()
  local FurnitureView = self:GetFurnitureView()
  local Transform = FurnitureView:GetTransform()
  self.FurnitureCreationPanel.FurnitureManager.FurnitureInitTransform = UE.FTransform(Transform.Rotation, Transform.Translation, Transform.Scale3D)
end

function FurnitureCreationEditor:OnDebugCopyLocation()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local Panel = self.FurnitureCreationPanel
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\229\183\178\231\187\143\230\139\183\232\180\157\228\189\141\231\189\174\228\191\161\230\129\175\239\188\154" .. Panel.TextBlock:GetText())
  UE4.UNRCStatics.ClipboardCopy(Panel.TextBlock:GetText())
  Context.LocationString = Panel.TextBlock:GetText()
  local FurnitureView = self:GetFurnitureView()
  local Transform = FurnitureView:GetTransform()
  self.FurnitureCreationPanel.FurnitureManager.FurnitureInitTransform = UE.FTransform(Transform.Rotation, Transform.Translation, Transform.Scale3D)
end

function FurnitureCreationEditor:OnDebugChangeX()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local loc = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Translation
      loc.X = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeLocation(loc, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeY()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_1:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local loc = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Translation
      loc.Y = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeLocation(loc, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeZ()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_2:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local loc = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Translation
      loc.Z = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeLocation(loc, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeRX()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_3:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local rot = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Rotation:ToRotator()
      rot.Roll = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeRotation(rot, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeRY()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_4:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local rot = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Rotation:ToRotator()
      rot.Pitch = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeRotation(rot, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeRZ()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_5:GetText()
  if math.tointeger(v) then
    v = math.tointeger(v) / 100
    if FurnitureView then
      local rot = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Rotation:ToRotator()
      rot.Yaw = v
      FurnitureView:K2_GetRootComponent():K2_SetRelativeRotation(rot, false, nil, false)
    end
  end
  self:RefreshEditorView()
end

function FurnitureCreationEditor:OnDebugChangeScale()
  local Context = self:GetOrCreateContext()
  if not Context then
    return
  end
  local FurnitureView = self:GetFurnitureView()
  local Panel = self.FurnitureCreationPanel
  local v = Panel.UsernameDisplay_6:GetText()
  if math.tointeger(v) then
    Context.Scale = math.tointeger(v)
    v = math.tointeger(v) / 10000 / 10
    local Scale = FurnitureView:K2_GetRootComponent():GetRelativeTransform().Scale3D
    Scale.X = v
    Scale.Y = v
    Scale.Z = v
    FurnitureView:K2_GetRootComponent():SetRelativeScale3D(Scale)
    self.FurnitureCreationPanel.Slider_72:SetValue(v)
    local Transform = self.FurnitureCreationPanel.FurnitureManager.FurnitureInitTransform
    self.FurnitureCreationPanel.FurnitureManager.FurnitureInitTransform = UE.FTransform(Transform.Rotation, Transform.Translation, Transform.Scale3D)
  end
  self:RefreshEditorView()
end

return FurnitureCreationEditor
