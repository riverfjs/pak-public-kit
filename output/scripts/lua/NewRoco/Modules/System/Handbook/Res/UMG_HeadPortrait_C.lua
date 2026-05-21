local PetUtils = require("NewRoco.Utils.PetUtils")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UMG_HeadPortrait_C = Base:Extend("UMG_HeadPortrait_C")

function UMG_HeadPortrait_C:OnConstruct()
end

function UMG_HeadPortrait_C:OnUpdateTaskState()
  self.data.UnfinishedTaskCount, self.data.FinishedTaskCount, self.data.TaskCount = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetHandbookTaskFinishCountById, self.data.HandbookId)
  self.ProjectAgreed:SetVisibility(0 == self.data.UnfinishedTaskCount and self.data.FinishedTaskCount == self.data.TaskCount and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_HeadPortrait_C:OnItemUpdate(_data, datalist, index)
  if not UE.UObject.IsValid(self) then
    return
  end
  self.data = _data
  self:OnUpdateTaskState()
  self.curIndex = index
  self.Bg_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Bg:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Bg_5:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Bg_6:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.data then
    local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 1, 2)
    self.Dot:SetupKey(redId, {
      tostring(self.data.HandbookId)
    })
    self:SetPetHeadInfo()
  end
end

function UMG_HeadPortrait_C:SetPetHeadIcon(_petId, _state, _mutation, _glass_info)
  if not UE.UObject.IsValid(self) then
    return
  end
  local state = _state
  self:ResetVisibility()
  self.NRCSwitcher_77:SetActiveWidgetIndex(0)
  local handbookConf = self.data.PetBaseConf
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petId)
  local petModuleCof = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
  local petName = petBaseConf.name
  local petNumber = self.data.HandbookNumber
  local iconPath = NRCUtils:FormatConfIconPath(petModuleCof.icon, _G.UIIconPath.HeadIconPath)
  if _mutation and (0 ~= _mutation & _G.Enum.MutationDiffType.MDT_SHINING or PetUtils.CheckIsShiningGlass(_mutation)) then
    iconPath = NRCUtils:FormatConfIconPath(petModuleCof.shiny_icon, _G.UIIconPath.HeadIconPath)
  end
  self.NRCpetIcon3_2:SetPath("")
  if PetUtils.CheckIsCHAOS(_mutation) then
    _mutation = _G.Enum.MutationDiffType.MDT_CHAOS
  elseif _mutation and (0 ~= _mutation & _G.Enum.MutationDiffType.MDT_GLASS or PetUtils.CheckIsShiningGlass(_mutation)) then
    _mutation = _G.Enum.MutationDiffType.MDT_GLASS
  end
  self.NRCpetIcon3_1:SetBookHeadPetIconPathAndMaterial(iconPath, _mutation, _glass_info or {}, self)
  if state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    self.NRCSwitcher:SetActiveWidgetIndex(2)
    self.Name:SetText("???")
    self.NRCpetIcon3_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCpetIcon3_2:SetPathWithCallBack(NRCUtils:FormatConfIconPath(iconPath, _G.UIIconPath.HeadIconPath), {
      self,
      self.LoadImageFindEnd
    })
    self.Name_1:SetText(petNumber)
  elseif self.data.State == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self.NRCSwitcher:SetActiveWidgetIndex(1)
    self.Name:SetText(petName)
    self.Name_1:SetText(petNumber)
  else
    self.NRCSwitcher:SetActiveWidgetIndex(0)
    self.Name:SetText(petName)
    self.Name_1:SetText(petNumber)
  end
  self.PetIconPath = iconPath
  self:SetSelectedPetHeadInfo(true)
end

function UMG_HeadPortrait_C:SetStampImage(image)
  local material = image:GetDynamicMaterial()
  material:SetTextureParameterValue("SpriteTexture", self.NRCpetIcon3_2.Brush.ResourceObject)
  image:SetBrushFromMaterial(material, false)
end

function UMG_HeadPortrait_C:OnIconResLoadComplete(req, Texture2D)
  if self and self.NRCpetIcon3_2 then
    self.NRCpetIcon3_2:SetBrushFromTexture(Texture2D, false)
  end
end

function UMG_HeadPortrait_C:RevertDefaultIcon()
  self:SetPetHeadInfo()
end

function UMG_HeadPortrait_C:SetPetHeadInfo()
  if not UE.UObject.IsValid(self) then
    return
  end
  local data = self.data
  if nil == data then
    return
  end
  self:ResetVisibility()
  local mutation = _G.Enum.MutationDiffType.MDT_NONE
  if data.IsShowShiningIcon then
    mutation = _G.Enum.MutationDiffType.MDT_SHINING
    self.PetIconPath = data.HandbookPetIcon.shiny_icon
  else
    self.PetIconPath = data.HandbookPetIcon.icon
  end
  local path = NRCUtils:FormatConfIconPath(self.PetIconPath, _G.UIIconPath.HeadIconPath)
  self.NRCpetIcon3_1:SetBookHeadPetIconPathAndMaterial(path, mutation, {}, self)
  local petName = self.data.PetBaseConf.name
  if self.data.State == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    self.NRCpetIcon3_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCpetIcon3_2:SetPathWithCallBack(NRCUtils:FormatConfIconPath(self.PetIconPath, _G.UIIconPath.HeadIconPath), {
      self,
      self.LoadImageFindEnd
    })
    self.NRCSwitcher:SetActiveWidgetIndex(2)
    self.Name:SetText("???")
    self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#908F85FF"))
    self.Name_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#908F85FF"))
    self.Name_1:SetText(self.data.HandbookNumber)
  elseif self.data.State == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self.NRCSwitcher:SetActiveWidgetIndex(1)
    self.Name:SetText(petName)
    self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#908F85FF"))
    self.Name_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#908F85FF"))
    self.NRCpetIcon3_2:SetPathWithCallBack(NRCUtils:FormatConfIconPath(self.PetIconPath, _G.UIIconPath.HeadIconPath), {
      self,
      self.LoadImageFindEnd
    })
    self.Name_1:SetText(self.data.HandbookNumber)
  else
    self.NRCSwitcher:SetActiveWidgetIndex(0)
    self.Name:SetText(petName)
    self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    self.Name_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    self.Name_1:SetText(self.data.HandbookNumber)
  end
end

function UMG_HeadPortrait_C:ResetVisibility()
  self.NRCSwitcher_77:SetActiveWidgetIndex(0)
  self.SerialNumber:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.imageSelect then
    self.imageSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_HeadPortrait_C:LoadImageEnd()
  self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_HeadPortrait_C:LoadImageFindEnd()
  self.Bg_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetStampImage(self.NRCpetIcon3_3)
  self.Bg_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.NRCpetIcon3_3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_HeadPortrait_C:SetSelectedPetHeadInfo(_flag)
  if _flag then
    if self.imageSelect then
      self.imageSelect:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    if self.Name then
      self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    end
    if self.Name_1 then
      self.Name_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    end
  else
    if self.imageSelect then
      self.imageSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    if self.data and self.data.State == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    else
      if self.Name then
      end
      if self.Name_1 then
      end
      if self.Line then
      end
    end
  end
end

function UMG_HeadPortrait_C:OnItemSelected(_bSelected)
  if not UE.UObject.IsValid(self) then
    return
  end
  self:StopAnimation(self.Press)
  self:StopAnimation(self.Cancel)
  if _bSelected then
    local size_Y = self.CanvasPanel_2.Slot:GetPosition().Y + self.CanvasPanel_2.Slot:GetSize().Y
    local lastSelectedIndex = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetCurIndex)
    if lastSelectedIndex ~= self.curIndex then
    end
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1236, "UMG_HeadPortrait_C:OnItemSelected")
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetSelectedItem, self.data, self._index, size_Y, self)
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
    self:PlayAnimation(self.Press)
  else
    self:PlayAnimation(self.Cancel)
  end
  self:SetSelectedPetHeadInfo(_bSelected)
end

function UMG_HeadPortrait_C:StopDelay()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
  end
end

function UMG_HeadPortrait_C:PlayLoopAnimation()
  if self.curIndex then
    self:StopDelay()
    self.delayId = _G.DelayManager:DelaySeconds(0.05 * self.curIndex, function()
      self:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.Book_Open)
    end, self)
  end
end

function UMG_HeadPortrait_C:HideItem()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_HeadPortrait_C:PlayBookOpenAnimation()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.Book_Open)
end

function UMG_HeadPortrait_C:OnDeactive()
  self:StopDelay()
end

function UMG_HeadPortrait_C:OnDestruct()
  self:StopDelay()
end

function UMG_HeadPortrait_C:OnDisable()
  self:StopDelay()
end

function UMG_HeadPortrait_C:OnAnimationFinished(anim)
  if anim == self.Cancel then
  elseif anim == self.Cancel_1 then
  elseif anim == self.Book_Open then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_HeadPortrait_C:OnMouseLeave(MouseEvent)
  self:PlayCancel()
end

function UMG_HeadPortrait_C:PlayCancel()
  if self.IsStarted then
    self.IsStarted = false
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.SetStartState, self.IsStarted, 0)
    self:StopAllAnimations()
  end
end

return UMG_HeadPortrait_C
