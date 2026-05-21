local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetHatchingItem_C = Base:Extend("UMG_PetHatchingItem_C")
UMG_PetHatchingItem_C.animType = {
  None = 0,
  In = 1,
  Loop = 2,
  Select = 3
}
UMG_PetHatchingItem_C.eggType = {
  None = 0,
  Normal = 1,
  Nightmare = 2,
  Glassy = 3,
  Shining = 4,
  ShiningGlass = 5,
  CustomGlass = 6
}

function UMG_PetHatchingItem_C:OnConstruct()
  _G.NRCEventCenter:RegisterEvent(self.name, self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
end

function UMG_PetHatchingItem_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnUpdateHatchSecs, self.OnUpdateHatchSecs)
end

function UMG_PetHatchingItem_C:Init()
  self.EggNameList = {
    self.UnSelectedName,
    self.SelectedName
  }
  self.EggGradeList = {
    self.UnSelectedGrade,
    self.SelectedGrade_1,
    self.SelectedGrade
  }
  self.EggNengList = {
    self.SelectedTxtNeng,
    self.SelectedTxtNeng_1,
    self.UnSelectedTxtNeng
  }
end

function UMG_PetHatchingItem_C:SetName(name)
  for i, v in pairs(self.EggNameList) do
    v:SetText(name)
  end
end

function UMG_PetHatchingItem_C:SetGrade(grade)
  if self:CheckIsCustomClassEgg() then
    grade = "???"
  end
  for i, v in pairs(self.EggGradeList) do
    v:SetText(grade)
  end
end

function UMG_PetHatchingItem_C:SetNeng(neng)
  if self:CheckIsCustomClassEgg() then
    neng = "???"
  end
  for i, v in pairs(self.EggNengList) do
    v:SetText(neng)
  end
end

function UMG_PetHatchingItem_C:UpdateIncubating(redPointDatas)
  if self.itemInfo then
    local isEggUp = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetEggSpeedActiveOpenState, self.itemInfo.gid)
    if false == isEggUp then
      self:StopAnimation(self.SpeedUp_loop)
    end
    local isFinishHatch = false
    if redPointDatas and self.index and redPointDatas[self.index] and self.itemInfo and self.itemInfo.gid == tonumber(redPointDatas[self.index]) then
      isFinishHatch = true
    end
    self.jiasuzhong:SetVisibility(not (not isEggUp or isFinishHatch) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    self.Arrow:SetVisibility(not (not isEggUp or isFinishHatch) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    self.Arrow_1:SetVisibility(not (not isEggUp or isFinishHatch) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
    self.Arrow_2:SetVisibility(not (not isEggUp or isFinishHatch) and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHatchingItem_C:OnItemUpdate(_data, datalist, index)
  self:Init()
  self.index = index
  self.uiData = _data
  self.itemInfo = self.uiData.data
  self.SelectedName_1:SetText(string.format(LuaText.umg_pethatching15, self.uiData.positionIndex))
  self.jiasuzhong:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Arrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Arrow_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Arrow_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.itemInfo then
    self.RedDot:SetupKey(191, {
      self.itemInfo.gid
    })
    self.PetEggTypeIconItem:SetItemIcon(self.itemInfo.gid, false)
    self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_EGG_HATCH_COMPLETE)
    self.eggInfo = self.uiData.data.bagItem.egg_data
    local itemConf = _G.DataConfigManager:GetBagItemConf(self.itemInfo.bagItem.id)
    local isHaveBook, Name, Desc
    if self.eggInfo and self.eggInfo.conf_id and 0 ~= self.eggInfo.conf_id then
      isHaveBook, Name, Desc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, self.itemInfo.bagItem.id)
      if isHaveBook then
        self:SetName(Name)
      end
    end
    if not isHaveBook and itemConf and itemConf.name then
      local eggName = itemConf.name
      if not self.eggInfo.random_egg_conf and self.eggInfo.precious_egg_type and self.eggInfo.precious_egg_type == _G.Enum.PreciousEggType.PET_PRECIOUS then
        eggName = LuaText.cifu_precious_petegg
      end
      self:SetName(eggName)
    end
    if self.eggInfo then
      if self.eggInfo.weight then
        self:SetGrade(string.format("%s", self.eggInfo.weight * 0.001))
      elseif self:CheckIsCustomClassEgg() then
        self:SetGrade()
      end
      if self.eggInfo.height then
        self:SetNeng(string.format("%s", self.eggInfo.height * 0.01))
      elseif self:CheckIsCustomClassEgg() then
        self:SetNeng()
      end
    end
    if itemConf and itemConf.icon then
      self.ICON:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ICON:SetEggIcon(self.eggInfo, itemConf.icon)
    end
    self:SetClickable(true)
    self.NotSelected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    local oldEggType = self:GetEggType()
    if oldEggType ~= self.eggType.Normal and self.bSelected then
      if oldEggType == self.eggType.Glassy or oldEggType == self.eggType.CustomGlass then
        self:PlayAnimation(self.Xc_normal)
      elseif oldEggType == self.eggType.Nightmare then
        self:PlayAnimation(self.Em_normal)
      elseif oldEggType == self.eggType.Shining then
        self:PlayAnimation(self.YS_normal)
      elseif oldEggType == self.eggType.ShiningGlass then
        self:PlayAnimation(self.Ysxc_normal)
      end
    end
    self.eggInfo = nil
    self:SetClickable(false)
    self.ICON:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if UE4.UKismetSystemLibrary.IsValid(self.NotSelected) then
      self.NotSelected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.UnSelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UnSelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HorizontalBox_Selected_Height:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HorizontalBox_NotSelected_Height:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HorizontalBox_Selected_Weight:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HorizontalBox_NotSelected_Weight:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RedDot:SetupKey(0)
    self.PetEggTypeIconItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHatchingItem_C:PlayInAnimation()
  if self.bSelected then
    self.bPlayInAnim = true
    return
  end
  if self.itemInfo then
    local isEggUp = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetEggSpeedActiveOpenState, self.itemInfo.gid)
    if redpointDatas and #redpointDatas > 0 then
      for i, data in pairs(redpointDatas) do
        if data == tostring(self.itemInfo.gid) then
          isEggUp = false
          break
        end
      end
    end
    local eggType = self:GetEggType()
    if eggType == self.eggType.Normal then
      self:PlayAnimation(isEggUp and self.SpeedUp_In or self.In)
    elseif eggType == self.eggType.Nightmare then
      self:PlayAnimation(self.Em_In)
      if isEggUp then
        self:PlayAnimation(self.SpeedUp_In_2)
      end
    elseif eggType == self.eggType.Glassy or eggType == self.eggType.CustomGlass then
      self:PlayAnimation(self.Xc_In)
      if isEggUp then
        self:PlayAnimation(self.SpeedUp_In_2)
      end
    elseif eggType == self.eggType.Shining then
      self:PlayAnimation(self.YS_In)
      if isEggUp then
        self:PlayAnimation(self.SpeedUp_In_2)
      end
    elseif eggType == self.eggType.ShiningGlass then
      self:PlayAnimation(self.Ysxc_In)
      if isEggUp then
        self:PlayAnimation(self.SpeedUp_In_2)
      end
    end
    self.bPlayInAnim = true
    return
  end
  local eggType = self:GetEggType()
  if eggType == self.eggType.Normal then
    self:PlayAnimation(self.In)
  elseif eggType == self.eggType.Nightmare then
    self:PlayAnimation(self.Em_In)
  elseif eggType == self.eggType.Glassy or eggType == self.eggType.CustomGlass then
    self:PlayAnimation(self.Xc_In)
  elseif eggType == self.eggType.Shining then
    self:PlayAnimation(self.YS_In)
  elseif eggType == self.eggType.ShiningGlass then
    self:PlayAnimation(self.Ysxc_In)
  end
  self.bPlayInAnim = true
end

function UMG_PetHatchingItem_C:RemoveSelect()
  self.IsRemoveSelect = true
end

function UMG_PetHatchingItem_C:OnItemSelected(_bSelected)
  self.bSelected = _bSelected
  if _bSelected then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGITEM
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
    if self.IsRemoveSelect then
      self.IsRemoveSelect = false
    end
    self:StopAnimation(self.Select_Out)
    self:StopAnimation(self.Em_normal)
    self:StopAnimation(self.Em_loop)
    self:StopAnimation(self.Em_Select_loop)
    self:StopAnimation(self.Xc_normal)
    self:StopAnimation(self.Xc_loop)
    self:StopAnimation(self.Xc_Select_loop)
    self:StopAnimation(self.YS_normal)
    self:StopAnimation(self.YS_loop)
    self:StopAnimation(self.YS_Select_loop)
    self:StopAnimation(self.Ysxc_normal)
    self:StopAnimation(self.Ysxc_loop)
    self:StopAnimation(self.Ysxc_Select_loop)
    self:StopAnimation(self.Select_loop)
    if self.itemInfo ~= nil then
      _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", false)
      self.Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCSwitcher_113:SetActiveWidgetIndex(0)
    else
      self.Select:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCSwitcher_113:SetActiveWidgetIndex(1)
    end
    local eggType = self:GetEggType()
    if eggType == self.eggType.Normal then
      if not self.bPlayInAnim then
        self:UnLockPanel()
        self:PlayAnimation(self.Select_loop)
      else
        self:PlayAnimation(self.Select_In)
      end
    elseif eggType == self.eggType.Nightmare then
      if not self.bPlayInAnim then
        self:UnLockPanel()
        self:PlayAnimation(self.Em_Select_loop)
      else
        self:PlayAnimation(self.Em_Select)
      end
    elseif eggType == self.eggType.Glassy or eggType == self.eggType.CustomGlass then
      if not self.bPlayInAnim then
        self:UnLockPanel()
        self:PlayAnimation(self.Xc_Select_loop)
      else
        self:PlayAnimation(self.Xc_Select)
      end
    elseif eggType == self.eggType.Shining then
      if not self.bPlayInAnim then
        self:UnLockPanel()
        self:PlayAnimation(self.YS_Select_loop)
      else
        self:PlayAnimation(self.YS_Select)
      end
    elseif eggType == self.eggType.ShiningGlass then
      if not self.bPlayInAnim then
        self:UnLockPanel()
        self:PlayAnimation(self.Ysxc_Select_loop)
      else
        self:PlayAnimation(self.Ysxc_Select)
      end
    end
    _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_Pet_Attribute_C:RemoveEggCallblack")
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.SelectPetEgg, self.itemInfo, self.index)
  else
    self:StopAnimation(self.Select_In)
    self:StopAnimation(self.Em_Select)
    self:StopAnimation(self.Em_loop)
    self:StopAnimation(self.Em_Select_loop)
    self:StopAnimation(self.Xc_Select)
    self:StopAnimation(self.Xc_loop)
    self:StopAnimation(self.Xc_Select_loop)
    self:StopAnimation(self.YS_Select)
    self:StopAnimation(self.YS_loop)
    self:StopAnimation(self.YS_Select_loop)
    self:StopAnimation(self.Ysxc_Select)
    self:StopAnimation(self.Ysxc_loop)
    self:StopAnimation(self.Ysxc_Select_loop)
    self:StopAnimation(self.Select_loop)
    if self.itemInfo ~= nil then
      self.NotSelected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Empty:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NotSelected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local eggType = self:GetEggType()
    if eggType == self.eggType.Normal then
      self:PlayAnimation(self.Select_Out)
    elseif eggType == self.eggType.Nightmare then
      self:PlayAnimation(self.Em_normal)
    elseif eggType == self.eggType.Glassy or eggType == self.eggType.CustomGlass then
      self:PlayAnimation(self.Xc_normal)
    elseif eggType == self.eggType.Shining then
      self:PlayAnimation(self.YS_normal)
    elseif eggType == self.eggType.ShiningGlass then
      self:PlayAnimation(self.Ysxc_normal)
    end
  end
end

function UMG_PetHatchingItem_C:OnItemClicked(bool)
end

function UMG_PetHatchingItem_C:ForceUpdateSelectPetEgg()
  local bUpdateEggModel = true
  if self.index and self.itemInfo then
    _G.NRCModuleManager:GetModule("PetUIModule"):DispatchEvent(PetUIModuleEvent.SelectPetEgg, self.itemInfo, self.index, bUpdateEggModel)
  end
end

function UMG_PetHatchingItem_C:OnAnimationFinished(aim)
  local eggType = self:GetEggType()
  if aim == self.Select_In or aim == self.Em_Select or aim == self.Xc_Select or aim == self.YS_Select or aim == self.Ysxc_Select then
    self:UnLockPanel()
    self.NotSelected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if eggType == self.eggType.Normal then
      if aim == self.Select_In then
        self:PlayAnimation(self.Select_loop, 0, 0)
      end
    elseif eggType == self.eggType.Nightmare then
      if aim == self.Em_Select then
        self:PlayAnimation(self.Em_Select_loop, 0, 0)
      end
    elseif eggType == self.eggType.Glassy or eggType == self.eggType.CustomGlass then
      if aim == self.Xc_Select then
        self:PlayAnimation(self.Xc_Select_loop, 0, 0)
      end
    elseif eggType == self.eggType.Shining then
      if aim == self.YS_Select then
        self:PlayAnimation(self.YS_Select_loop, 0, 0)
      end
    elseif eggType == self.eggType.ShiningGlass and aim == self.Ysxc_Select then
      self:PlayAnimation(self.Ysxc_Select_loop, 0, 0)
    end
  elseif aim == self.Select_Out or aim == self.Em_normal or aim == self.Xc_normal or aim == self.YS_normal or aim == self.Ysxc_normal then
    if self.itemInfo ~= nil then
      self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCSwitcher_113:SetActiveWidgetIndex(0)
      self.Empty:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Select:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NotSelected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if eggType == self.eggType.Nightmare then
      if aim == self.Em_normal then
        self:PlayAnimation(self.Em_loop, 0, 0)
      end
    elseif eggType == self.eggType.Glassy then
      if aim == self.Xc_normal then
        self:PlayAnimation(self.Xc_loop, 0, 0)
      end
    elseif eggType == self.eggType.Shining then
      if aim == self.YS_normal then
        self:PlayAnimation(self.YS_loop, 0, 0)
      end
    elseif eggType == self.eggType.ShiningGlass and aim == self.Ysxc_normal then
      self:PlayAnimation(self.Ysxc_loop, 0, 0)
    end
  elseif aim == self.In then
  elseif aim == self.SpeedUp_In or aim == self.SpeedUp_In_2 then
    self:PlayAnimation(self.SpeedUp_loop, 0, 0)
  elseif aim == self.Em_In then
    if not self.bSelected then
      self:PlayAnimation(self.Em_loop, 0, 0)
    end
  elseif aim == self.Xc_In then
    if not self.bSelected then
      self:PlayAnimation(self.Xc_loop, 0, 0)
    end
  elseif aim == self.YS_In then
    if not self.bSelected then
      self:PlayAnimation(self.YS_loop, 0, 0)
    end
  elseif aim == self.Ysxc_In and not self.bSelected then
    self:PlayAnimation(self.Ysxc_loop, 0, 0)
  end
end

function UMG_PetHatchingItem_C:OnUpdateHatchSecs(rsp)
  if self.eggInfo == nil then
    return
  end
  local index
  for i = 1, #rsp.egg_gid do
    if rsp.egg_gid[i] == self.itemInfo.gid then
      index = i
    end
  end
  local secs = 0
  if index and rsp.hatched_secs[index] then
    secs = rsp.hatched_secs[index]
  end
  local targetProgerss = 0
  local eggMaxSeces
  if 0 == self.eggInfo.conf_id and self.eggInfo.random_egg_conf then
    eggMaxSeces = self.eggInfo.max_hatched_secs
  else
    local eggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.conf_id)
    eggMaxSeces = eggConf.hatch_data
  end
  targetProgerss = math.clamp(secs / eggMaxSeces * 100, 0, 100)
  targetProgerss = math.floor(targetProgerss)
  self.TargetProgerss = targetProgerss
  if 100 == targetProgerss then
    self.UnSelectedTxtComplete:SetText(LuaText.umg_towermain_5)
    self.SelectedTxtComplete:SetText(LuaText.umg_towermain_5)
  else
    self.UnSelectedTxtComplete:SetText(targetProgerss .. "%")
    self.SelectedTxtComplete:SetText(targetProgerss .. "%")
    self:UpdateIncubating()
  end
  self.UnSelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_Selected_Height:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_NotSelected_Height:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_Selected_Weight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_NotSelected_Weight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UnSelectedCompleteProgress:SetPercent(targetProgerss / 100)
  self.SelectedCompleteProgress:SetPercent(targetProgerss / 100)
  self.UnSelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHatchingItem_C:RefreshUpdateHatchSecs(NewHatchSecs)
  if self.eggInfo == nil then
    return
  end
  local secs = NewHatchSecs
  local targetProgerss = 0
  local eggMaxSeces
  if 0 == self.eggInfo.conf_id and self.eggInfo.random_egg_conf then
    eggMaxSeces = self.eggInfo.max_hatched_secs
  else
    local eggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.conf_id)
    eggMaxSeces = eggConf.hatch_data
  end
  targetProgerss = math.clamp(secs / eggMaxSeces * 100, 0, 100)
  targetProgerss = math.floor(targetProgerss)
  self.TargetProgerss = targetProgerss
  if 100 == targetProgerss then
    self.UnSelectedTxtComplete:SetText(LuaText.umg_towermain_5)
    self.SelectedTxtComplete:SetText(LuaText.umg_towermain_5)
  else
    self.UnSelectedTxtComplete:SetText(targetProgerss .. "%")
    self.SelectedTxtComplete:SetText(targetProgerss .. "%")
    self:UpdateIncubating()
  end
  self.UnSelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedTxtComplete:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_Selected_Height:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_NotSelected_Height:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_Selected_Weight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_NotSelected_Weight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UnSelectedCompleteProgress:SetPercent(targetProgerss / 100)
  self.SelectedCompleteProgress:SetPercent(targetProgerss / 100)
  self.UnSelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedCompleteProgress:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHatchingItem_C:UpdateGreenProgressBar(PreviewProgress)
  if nil == PreviewProgress then
    Log.Debug("UMG_PetHatchingItem_C:UpdateGreenProgressBar PreviewProgress is nil")
    return
  end
  if nil == self.TargetProgerss then
    self.TargetProgerss = 0
  end
  self.UnSelectedCompleteProgress0:SetPercent((self.TargetProgerss + PreviewProgress) / 100)
  self.SelectedCompleteProgress0:SetPercent((self.TargetProgerss + PreviewProgress) / 100)
  self.UnSelectedCompleteProgress0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.SelectedCompleteProgress0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHatchingItem_C:ClearGreenProgressBar()
  self.UnSelectedCompleteProgress0:SetPercent(0)
  self.SelectedCompleteProgress0:SetPercent(0)
  self.UnSelectedCompleteProgress0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SelectedCompleteProgress0:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetHatchingItem_C:OnDeactive()
end

function UMG_PetHatchingItem_C:GetEggType()
  local type = self.eggType.Normal
  if self.itemInfo and self.itemInfo.gid then
    local PetEggAppearanceType = PetUtils.GetPetEggAppearanceType(self.itemInfo.gid)
    if PetEggAppearanceType == PetUIModuleEnum.PetEggAppearanceType.VisiblyGlass then
      type = self.eggType.Glassy
    elseif PetEggAppearanceType == PetUIModuleEnum.PetEggAppearanceType.VisiblyShining then
      type = self.eggType.Shining
    elseif PetEggAppearanceType == PetUIModuleEnum.PetEggAppearanceType.VisiblyGlassAndShining then
      type = self.eggType.ShiningGlass
    elseif PetEggAppearanceType == PetUIModuleEnum.PetEggAppearanceType.Chaos then
      type = self.eggType.Nightmare
    elseif PetEggAppearanceType == PetUIModuleEnum.PetEggAppearanceType.CustomGlass then
      type = self.eggType.CustomGlass
    elseif self.eggInfo.random_egg_conf then
      local randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(self.eggInfo.random_egg_conf)
      if randomEggConf then
        local mutation_type = randomEggConf.mutation_type
        if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
          type = self.eggType.Glassy
        elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) then
          type = self.eggType.Nightmare
        elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
          type = self.eggType.Shining
        end
      end
    end
  end
  return type
end

function UMG_PetHatchingItem_C:CheckIsCustomClassEgg()
  local CheckIsCustomClassEgg = false
  if self.eggInfo and self.eggInfo.conf_id then
    local eggConf = _G.DataConfigManager:GetPetEggConf(self.eggInfo.conf_id)
    if eggConf and eggConf.precious_egg_type and eggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
      CheckIsCustomClassEgg = true
    end
  end
  return CheckIsCustomClassEgg
end

function UMG_PetHatchingItem_C:UnLockPanel()
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetHatchingPanel").EGGITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetHatchingPanel", touchReasonType)
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.SetPetItemClickAble, "PetHatchingPanel", true)
end

return UMG_PetHatchingItem_C
