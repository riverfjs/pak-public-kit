local UMG_SeasonAssignment_WidgetLoader_C = _G.NRCPanelBase:Extend("UMG_SeasonAssignment_WidgetLoader_C")

function UMG_SeasonAssignment_WidgetLoader_C:OnActive(uiData)
  self.umgName = ""
  self.param = uiData
  self:OnLoadSeasonAssignmentView()
end

function UMG_SeasonAssignment_WidgetLoader_C:OnDeactive()
end

function UMG_SeasonAssignment_WidgetLoader_C:OnAddEventListener()
end

function UMG_SeasonAssignment_WidgetLoader_C:OnLoadSeasonAssignmentView()
  local data = self.module.data
  local umgPath = "WidgetBlueprint'/Game/NewRoco/Modules/System/MagicManual/Res/UMG_SeasonAssignment.UMG_SeasonAssignment_C'"
  if data then
    local uiConf = data:GetSeasonChapterData() and data:GetSeasonChapterData().seasonUICfg
    umgPath = uiConf and uiConf.chapter_start_style or umgPath
  end
  self.umgName = ""
  if not string.IsNilOrEmpty(umgPath) then
    local parts = {}
    for part in string.gmatch(umgPath, "[^/.]+") do
      table.insert(parts, part)
    end
    if #parts > 1 then
      self.umgName = parts[#parts - 1]
    end
    _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.FullSpeed, self.umgName)
    if string.EndsWith(umgPath, "_C'") then
      local resRequest = self:LoadPanelRes(umgPath, 255, self.OnSeasonAssignmentViewClassLoaded)
      if resRequest then
        self:Log("load umg res success: ", umgPath)
      else
        self:LogError("load umg res failed: ", umgPath)
      end
    else
      self:LogError("umg res invalid: ", umgPath)
    end
  end
end

function UMG_SeasonAssignment_WidgetLoader_C:OnSeasonAssignmentViewClassLoaded(resRequest, viewClass)
  _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, self.umgName)
  if viewClass then
    local assignmentView = UE4.UWidgetBlueprintLibrary.Create(UE4Helper.GetCurrentWorld(), viewClass)
    self:DynamicAddChildView(assignmentView)
    local contentSlot = self.CanvasPanel_0:AddChild(assignmentView)
    if contentSlot then
      local anchors = UE4.FAnchors()
      anchors.Minimum = UE4.FVector2D(0, 0)
      anchors.Maximum = UE4.FVector2D(1, 1)
      contentSlot:SetAnchors(anchors)
      contentSlot:SetOffsets(UE4.FMargin())
      contentSlot:SetAlignment(UE4.FVector2D(0.5, 0.5))
    end
    if assignmentView and assignmentView.OnActive then
      if not self.param then
        self.param = {}
      end
      self.param.widgetLoader = self
      assignmentView:OnActive(self.param)
    end
  end
end

return UMG_SeasonAssignment_WidgetLoader_C
