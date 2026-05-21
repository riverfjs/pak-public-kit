local a = require("Common.Coroutine.async")
local SystemSettingEnum = require("NewRoco.Modules.System.SystemSetting.SystemSettingEnum")
local UMG_SystemSettingDropDownList_C = _G.NRCViewBase:Extend("UMG_SystemSettingDropDownList_C")

function UMG_SystemSettingDropDownList_C:Construct()
  _G.NRCViewBase.Construct(self)
  self:OnAddEventListener()
  self.CurShieldGroupName = nil
  self.ShieldGroupName = {
    "ImageQuality",
    "SceneDetailQuality",
    "ViewDistanceQuality",
    "ShadingQuality",
    "LightQuality",
    "EffectsQuality",
    "ShadowQuality",
    "PostProcessQuality",
    "BloomQuality",
    "AntiAliasingQuality",
    "VsyncQuality"
  }
end

function UMG_SystemSettingDropDownList_C:Destruct()
  self:OnRemoveEventListener()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  _G.NRCViewBase.Destruct(self)
end

function UMG_SystemSettingDropDownList_C:OnAddEventListener()
  self.SelectButton.OnClicked:Add(self, self.OnShowBtnClick)
end

function UMG_SystemSettingDropDownList_C:OnRemoveEventListener()
end

function UMG_SystemSettingDropDownList_C:InitUI(caller)
  self.IsOpenMenu = false
  self:SwitchState(self.IsOpenMenu)
  self.caller = caller
end

function UMG_SystemSettingDropDownList_C:OnItemSelected(optionData, index)
  self.IsOpenMenu = false
  self:SwitchState(false, true)
  self.caller:ShowDropDownListCallback(self)
  local task = a.task(function()
    if optionData ~= self.selectedOption then
      local ParamSet
      
      local function Func(DropDownList, bSure)
        if bSure then
          DropDownList:SetSelectedOption(optionData)
          if optionData.Value ~= UE4.ENRCImageQuality.Custom and DropDownList.key == "ImageQuality" then
            if not DropDownList.caller.DisableClick then
              Log.Error("UMG_SystemSettingDropDownList_C:OnItemSelected Caller No DisableClick")
            end
            DropDownList.caller:DisableClick()
          end
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ApplyConfig, DropDownList.key, optionData.Value, DropDownList.extraKey)
          if ParamSet then
            _G.GEMPostManager:SendOptionChangeTLog(ParamSet)
          end
        else
          DropDownList:SetSelectedOption(DropDownList.selectedOption)
        end
      end
      
      local QualityGroupIndex = optionData.QualityID
      local Table = {}
      local bInquiry = false
      if QualityGroupIndex then
        local CurLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
        local SuggestLevel = 0
        for i, v in ipairs(_G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()) do
          if v.id == QualityGroupIndex then
            Table = v
            break
          end
        end
        if RocoEnv.PLATFORM ~= "PLATFORM_WINDOWS" then
          if QualityGroupIndex == SystemSettingEnum.QualityID.ImageQuality then
            if optionData.Value ~= UE4.ENRCImageQuality.Custom then
              SuggestLevel = UE4.UNRCQualityLibrary.GetCurMaxSuggestImageQuality()
              for i, v in pairs(Table.Qualities) do
                if v.Level and v.Level == optionData.Value then
                  if SuggestLevel > v.SuggestUnifiedDeviceLevel then
                    SuggestLevel = v.SuggestUnifiedDeviceLevel
                  end
                  break
                end
              end
            end
          else
            SuggestLevel = UE4.UNRCQualityLibrary.GetCurMaxSuggestImageGroupQualityValue(self.key)
            for i, v in pairs(Table.Qualities) do
              if v.Level and v.Level == optionData.Value then
                if SuggestLevel > v.SuggestUnifiedDeviceLevel then
                  SuggestLevel = v.SuggestUnifiedDeviceLevel
                end
                break
              end
            end
          end
        end
        bInquiry = CurLevel < SuggestLevel
        ParamSet = {}
        ParamSet.QualityId = QualityGroupIndex
        ParamSet.QualityName = Table.name
        ParamSet.QualityLevel = optionData.Value
      end
      if self.key == "Resoluction" then
        ParamSet = {}
        ParamSet.QualityId = -1
        ParamSet.QualityName = "\229\136\134\232\190\168\231\142\135"
        ParamSet.QualityLevel = optionData.Value
      end
      if bInquiry then
        local Ctx = DialogContext()
        Ctx:SetContent(string.format(LuaText.setting_options_overloading, Table.name, optionData.Name))
        Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
        Ctx:SetTitle(LuaText.player_unstuck_confirm_title)
        Ctx:SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel)
        Ctx:SetCloseFlagWhenPlayerDie()
        Ctx:SetCallback(self, Func)
        NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
      else
        Func(self, true)
      end
    end
  end)
  task(function()
  end)
end

function UMG_SystemSettingDropDownList_C:SetSelectedOption(optionData)
  self.selectedOption = optionData
  if self.selectedOption.Recommend then
    self.TText:SetText(optionData.Name .. LuaText.umg_systemsettingdropdownlist_1)
  else
    self.TText:SetText(optionData.Name)
  end
  local index = self:FindOptionIndex(optionData)
  self.CandidateListScroll:SelectItemByIndex(index - 1)
  self.CandidateListScroll_1:SelectItemByIndex(index - 1)
  self:ScrollToSelectOption(index)
end

function UMG_SystemSettingDropDownList_C:SelectItemByIndexDirectly(index)
  self.selectedOption = self.options[index + 1]
  if self.selectedOption.Recommend then
    self.TText:SetText(self.selectedOption.Name .. LuaText.umg_systemsettingdropdownlist_1)
  else
    self.TText:SetText(self.selectedOption.Name)
  end
  for i = 1, self.CandidateListScroll:GetItemCount() do
    local item = self.CandidateListScroll:GetItemByIndex(i - 1)
    if i - 1 == index then
      item.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827FF"))
    else
      item:CancelSelect()
    end
  end
  for i = 1, self.CandidateListScroll_1:GetItemCount() do
    local item = self.CandidateListScroll_1:GetItemByIndex(i - 1)
    if i - 1 == index then
      item.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827FF"))
    else
      item:CancelSelect()
    end
  end
end

function UMG_SystemSettingDropDownList_C:SelectItemByKeyDirectly(key)
  local index = self:FindOptionIndexByValue(key)
  local selectIndex = self:FindOptionIndex(self.options[index])
  self.selectedOption = self.options[selectIndex]
  if self.selectedOption.Recommend then
    self.TText:SetText(self.selectedOption.Name .. LuaText.umg_systemsettingdropdownlist_1)
  else
    self.TText:SetText(self.selectedOption.Name)
  end
  for i = 1, self.CandidateListScroll:GetItemCount() do
    local item = self.CandidateListScroll:GetItemByIndex(i - 1)
    if i == selectIndex then
      item.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827FF"))
    else
      item:CancelSelect()
    end
  end
  for i = 1, self.CandidateListScroll_1:GetItemCount() do
    local item = self.CandidateListScroll_1:GetItemByIndex(i - 1)
    if i == selectIndex then
      item.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("dc9827FF"))
    else
      item:CancelSelect()
    end
  end
end

function UMG_SystemSettingDropDownList_C:ScrollToSelectOption(selectValue)
  if self.CandidateListScroll:GetItemCount() > 5 then
    self.ScrollBox_3:EndInertialScrolling()
    self.ScrollBox_1:EndInertialScrolling()
    self.DelayId = _G.DelayManager:DelaySeconds(0.06, function()
      if self then
        self.ScrollBox_3:ScrollWidgetIntoView(self.CandidateListScroll:GetItemByIndex(selectValue - 1), false, UE4.EDescendantScrollDestination.TopOrLeft)
        self.ScrollBox_1:ScrollWidgetIntoView(self.CandidateListScroll_1:GetItemByIndex(selectValue - 1), false, UE4.EDescendantScrollDestination.TopOrLeft)
        self.ScrollBox_3:ForceLayoutPrepass()
        self.ScrollBox_1:ForceLayoutPrepass()
      end
    end)
  end
end

function UMG_SystemSettingDropDownList_C:SetSelectedIndex(index)
  self:SetSelectedOption(self.options[index])
end

function UMG_SystemSettingDropDownList_C:SetSelectedValue(inValue)
  local index = self:FindOptionIndexByValue(inValue)
  self:SetSelectedOption(self.options[index])
end

function UMG_SystemSettingDropDownList_C:GetSelectedValue()
  if self.selectedOption then
    for _, option in ipairs(self.options) do
      if option == self.selectedOption then
        return option.Value
      end
    end
  end
end

function UMG_SystemSettingDropDownList_C:GetOptionByIndex(index)
  return self.options[index]
end

function UMG_SystemSettingDropDownList_C:FindOptionIndex(inOption)
  for index, option in ipairs(self.options) do
    if option == inOption then
      return index
    end
  end
  return 1
end

function UMG_SystemSettingDropDownList_C:FindOptionIndexByValue(inValue)
  if self.options then
    for index, option in ipairs(self.options) do
      if option.Value == inValue then
        return index
      end
    end
  end
  return 1
end

function UMG_SystemSettingDropDownList_C:SwitchState(isOpen, needAnimation)
  local geo = self.SelectButton:GetCachedGeometry()
  local PPosition, Position = UE4.USlateBlueprintLibrary.LocalToViewport(UE4Helper.GetCurrentWorld(), geo, UE4.FVector2D(0, 0))
  local isUp = false
  if PPosition.Y / UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld()).Y > 0.55 then
    isUp = true
  end
  _G.NRCAudioManager:PlaySound2DAuto(40007003, "UMG_SystemSettingDropDownList_C:SwitchState")
  if not isOpen then
    self.DownArrow:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DownArrow_up:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if needAnimation then
      if isUp then
        self:PlayAnimationReverse(self.OpenUpAnim)
      else
        self:PlayAnimationReverse(self.OpenDownAnim)
      end
      self.CandidateListScroll:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.CandidateListScroll_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    else
      self.DropdownListOverlay:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.DropdownListOverlay_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.DownArrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DownArrow_up:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if isUp then
      self.DropdownListOverlay:SetVisibility(UE4.ESlateVisibility.Visible)
      self.DropdownListOverlay_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if needAnimation then
        self:PlayAnimation(self.OpenUpAnim)
      end
    else
      self.DropdownListOverlay:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.DropdownListOverlay_1:SetVisibility(UE4.ESlateVisibility.Visible)
      if needAnimation then
        self:PlayAnimation(self.OpenDownAnim)
      end
    end
  end
end

function UMG_SystemSettingDropDownList_C:OnShowBtnClick()
  self.IsOpenMenu = not self.IsOpenMenu
  self:SwitchState(self.IsOpenMenu, true)
  if self.caller then
    self.caller:ShowDropDownListCallback(self)
  end
end

function UMG_SystemSettingDropDownList_C:SetDisableGrey(bDisable)
  if bDisable then
    self.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605eFF"))
    self.DownArrow:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605eFF"))
    self.DownArrow_up:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605eFF"))
  else
    self.TText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#c4c2b6FF"))
    self.DownArrow:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
    self.DownArrow_up:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFFFFFFF"))
  end
end

function UMG_SystemSettingDropDownList_C:SetKeyAndOptions(key, options, extraKey)
  self.key = key
  self.extraKey = extraKey
  if "Resoluction" == key then
    self.OpenUpAnim = self.OpenUp
    self.OpenDownAnim = self.OpenDown
  else
    self.OpenUpAnim = self.OpenUp
    self.OpenDownAnim = self.OpenDown
  end
  local listData = {}
  for index, value in ipairs(options) do
    listData[index] = {caller = self, option = value}
  end
  self.options = options
  self:SetCurShieldGroupName(key)
  self.CandidateListScroll:InitGridView(listData)
  self.CandidateListScroll_1:InitGridView(listData)
end

function UMG_SystemSettingDropDownList_C:OnAnimationFinished(Animation)
  if Animation == self.OpenUpAnim or Animation == self.OpenDownAnim then
    self.CandidateListScroll:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CandidateListScroll_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.IsOpenMenu == false then
      self.DropdownListOverlay:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.DropdownListOverlay_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_SystemSettingDropDownList_C:SetCurShieldGroupName(key)
  for _, groupName in ipairs(self.ShieldGroupName) do
    if groupName == key then
      self.CurShieldGroupName = key
      break
    end
  end
end

function UMG_SystemSettingDropDownList_C:IsPCMode()
  if RocoEnv.IS_EDITOR then
    return false
  else
    return RocoEnv.PLATFORM == "PLATFORM_WINDOWS"
  end
end

return UMG_SystemSettingDropDownList_C
