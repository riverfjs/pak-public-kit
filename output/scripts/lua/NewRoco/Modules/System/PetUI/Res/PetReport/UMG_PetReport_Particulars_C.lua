local UMG_PetReport_Particulars_C = _G.NRCPanelBase:Extend("UMG_PetReport_Particulars_C")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local OnClickBtnType = {
  Close = 0,
  Ok = 1,
  Skip = 2
}
UMG_PetReport_Particulars_C.tickTime = 0.01
UMG_PetReport_Particulars_C.tickNum = 100
UMG_PetReport_Particulars_C.curTimeCnt = 0

function UMG_PetReport_Particulars_C:OnActive(uiData)
  self.uiData = uiData.petReportData
  self.bFinal = uiData.bFinal
  self.bShowCloseBtn = uiData.bShowCloseBtn
  self.OnClickBtn = nil
  self:OnAddEventListener()
  self.PetImage:SetUILocation()
  self:InitUI()
  if self.bShowCloseBtn then
    _G.NRCAudioManager:PlaySound2DAuto(41400002, "UMG_PetReport_Particulars_C:OnActive")
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetReportPanelVisibility, false)
    self.Prompt_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:LoadAnimation(0)
  else
    _G.NRCAudioManager:PlaySound2DAuto(1372, "UMG_PetReport_Particulars_C:OnActive")
    self.curTimeCnt = 0
    self:PlayAnimation(self.Special_in)
    self:ClearChangeNumTimer()
    self.ChangeNumTimer = _G.TimerManager:CreateTimer(self, "ChangeNumTimer", 1, self.OnChangeNum, self.OnChangeNumTimerComplete, 0.01)
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetReportReminder)
  self:CheckShareIsOpen()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
end

function UMG_PetReport_Particulars_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
  self:CancelDelay()
  self:ClearTimer()
end

function UMG_PetReport_Particulars_C:OnAddEventListener()
  self:AddButtonListener(self.ConfirmBtn.btnLevelUp, self.OnClickedOK)
  self:AddButtonListener(self.Button_Skip.Button, self.OnClickedSkip)
  self:AddButtonListener(self.btnClose.btnClose, self.OnClickedClose)
  self:AddButtonListener(self.ShareBtn.btnLevelUp, self.OnClickedShare)
  self:AddButtonListener(self.BtnClose_1, self.OnClickedClose)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
end

function UMG_PetReport_Particulars_C:InitUI()
  self:StopAllAnimations()
  self:CancelDelay()
  self:ClearTimer()
  if self.bShowCloseBtn then
    self.btnClose:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Button_Skip:PlayAnimation(self.Button_Skip.LightOut, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 999)
    self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BtnClose_1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Button_Skip:PlayAnimation(self.Button_Skip.FadeIn, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 999)
    self.ConfirmBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BtnClose_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:InitPetBaseUI()
  self:InitPetRatioUI()
end

function UMG_PetReport_Particulars_C:UpdateUI(data, bFinal)
  _G.NRCAudioManager:PlaySound2DAuto(1372, "UMG_PetReport_Particulars_C:UpdateUI")
  self:StopAllAnimations()
  self:CancelDelay()
  self:ClearTimer()
  self.uiData = data
  self.bFinal = bFinal
  self.bShowCloseBtn = false
  self.OnClickBtn = nil
  self.btnClose:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Button_Skip:PlayAnimation(self.Button_Skip.FadeIn, 0.0, 1, UE4.EUMGSequencePlayMode.Forward, 999)
  self:InitPetBaseUI()
  self:InitPetRatioUI()
  self.curTimeCnt = 0
  self:PlayAnimation(self.Special_change_in)
  self:ClearChangeNumTimer()
  self.ChangeNumTimer = _G.TimerManager:CreateTimer(self, "ChangeNumTimer", 1, self.OnChangeNum, self.OnChangeNumTimerComplete, 0.01)
end

function UMG_PetReport_Particulars_C:InitPetBaseUI()
  if self.uiData and self.uiData.pet_brief then
    if self.uiData.pet_brief.name then
      local name = self.uiData.pet_brief.name
      self.NameText:SetText(name)
    end
    self:SetPetIcon(self.uiData.pet_brief.base_conf_id, self.uiData.pet_brief.mutation_type, self.uiData.pet_brief.glass_info)
    self.Heterochrome:SetMutationIcon(self.uiData.pet_brief)
  end
end

function UMG_PetReport_Particulars_C:SetPetIcon(baseConfID, mutation_type, glass_info)
  if self.uiData.bSpecial then
    self.BgSwitcher:SetActiveWidgetIndex(1)
  else
    self.BgSwitcher:SetActiveWidgetIndex(0)
  end
  self.PetImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PetImage:SetPetIcon(self.bShowCloseBtn, baseConfID, mutation_type, glass_info)
end

function UMG_PetReport_Particulars_C:InitPetRatioUI()
  if self.uiData and self.uiData.report_infos and self.uiData.final_ratio and self.uiData.total_coin then
    self.Prompt_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Number_1:SetText(tostring(self.uiData.total_coin))
    if self.uiData.final_ratio then
      self.final_ratio = self.uiData.final_ratio / 10000
      if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsInteger, self.final_ratio) then
        self.MultiplyingPowerText:SetText(tostring(math.floor(self.final_ratio)))
      else
        self.MultiplyingPowerText:SetText(string.format("%.1f", self.final_ratio))
      end
      local color
      local report_text_super = _G.DataConfigManager:GetPetGlobalConfig("report_text_super")
      local report_text_hard = _G.DataConfigManager:GetPetGlobalConfig("report_text_hard")
      local report_text_middle = _G.DataConfigManager:GetPetGlobalConfig("report_text_middle")
      local report_text_easy = _G.DataConfigManager:GetPetGlobalConfig("report_text_easy")
      if report_text_super and report_text_hard and report_text_middle and report_text_easy then
        if report_text_hard.num and self.final_ratio >= report_text_hard.num then
          color = report_text_super.str
        elseif report_text_hard.num and report_text_middle.num and self.final_ratio >= report_text_middle.num and self.final_ratio < report_text_hard.num then
          color = report_text_hard.str
        elseif report_text_middle.num and report_text_easy.num and self.final_ratio >= report_text_easy.num and self.final_ratio < report_text_middle.num then
          color = report_text_middle.str
        elseif report_text_easy.num and self.final_ratio > 0 and self.final_ratio < report_text_easy.num then
          color = report_text_easy.str
        end
      end
      if color then
        self.QualityBG:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
      end
    end
    local ratioList = {}
    local index = -1
    local needToHide = false
    local talentText = _G.DataConfigManager:GetLocalizationConf("report_ratio_talent_text")
    for _, info in pairs(self.uiData.report_infos or {}) do
      local id = info.id
      if id then
        local ratioConf = _G.DataConfigManager:GetReportCoinRatioConf(id)
        if ratioConf then
          local ratioInfo = {}
          ratioInfo.enum_name = ratioConf.enum_name
          ratioInfo.param_name = ratioConf.param_name
          if ratioConf.enum_ReportCoinRatio == Enum.ReportCoinRatio.RCR_GLASS_HIDDEN then
            local glassName = self:GetHiddenGlassName()
            if glassName then
              ratioInfo.param_name = glassName
            end
          end
          ratioInfo.ratio = info.ratio / 10000
          ratioInfo.id = id
          table.insert(ratioList, ratioInfo)
          if talentText and talentText.msg then
            if -1 == index and talentText.msg == ratioInfo.enum_name then
              index = #ratioList
            end
            if ratioInfo.ratio > 1 and talentText.msg ~= ratioInfo.enum_name then
              needToHide = true
            end
          end
        end
      end
    end
    if #ratioList > 1 and index > 0 and ratioList[index] and 1 == ratioList[index].ratio and needToHide then
      table.remove(ratioList, index)
    end
    table.sort(ratioList, function(a, b)
      return a.id < b.id
    end)
    self.List:InitGridView(ratioList)
  end
  self.itemMoveCurTimeCnt = 0
  self.itemMaxNum = 6
  self:ClearItemMoveInTimer()
  self.ItemMoveInTimer = _G.TimerManager:CreateTimer(self, "ItemMoveInTimer", 0.6, self.OnItemMoveIn, self.OnItemMoveInTimerComplete, 0.1)
end

function UMG_PetReport_Particulars_C:GetHiddenGlassName()
  if self.uiData and self.uiData.pet_brief and self.uiData.pet_brief.glass_info and self.uiData.pet_brief.glass_info.glass_type == ProtoEnum.GlassType.GT_HIDDEN then
    local HiddenGlassID = self.uiData.pet_brief.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        local name = HiddenGlassConf.name
        name = name and name:gsub("<[^>]*>", ""):gsub("</>", "")
        return name
      end
    end
  end
  return nil
end

function UMG_PetReport_Particulars_C:OnItemMoveIn()
  local itemCount = self.List:GetItemCount()
  if itemCount > self.itemMoveCurTimeCnt then
    local item = self.List:GetItemByIndex(self.itemMoveCurTimeCnt)
    if item then
      if self.itemMoveCurTimeCnt < self.itemMaxNum then
        item.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        item:PlayAnimation(item.In)
      else
        item.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
    self.itemMoveCurTimeCnt = self.itemMoveCurTimeCnt + 1
  end
end

function UMG_PetReport_Particulars_C:OnClickedOK()
  if self:CheckIsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetReport_Particulars_C:OnClickedOK")
  self.OnClickBtn = OnClickBtnType.Ok
  if self.bFinal then
    _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetReport_Particulars_C:OnClickedOK")
    self:PlayAnimation(self.Special_out)
  elseif self.bShowCloseBtn then
    _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetReport_Particulars_C:OnClickedOK")
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetReportPanelVisibility, true)
    self:LoadAnimation(2)
  else
    self:PlayAnimation(self.Special_change_out)
  end
end

function UMG_PetReport_Particulars_C:OnClickedSkip()
  if self:CheckIsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetReport_Particulars_C:OnClickedSkip")
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetReport_Particulars_C:OnClickedSkip")
  self.OnClickBtn = OnClickBtnType.Skip
  self:PlayAnimation(self.Special_out)
end

function UMG_PetReport_Particulars_C:OnClickedClose()
  if self:CheckIsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_PetReport_Particulars_C:OnClickedClose")
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetReport_Particulars_C:OnClickedClose")
  self.OnClickBtn = OnClickBtnType.Close
  if self.bShowCloseBtn then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetReportPanelVisibility, true)
    self:LoadAnimation(2)
  else
    self:PlayAnimation(self.Special_out)
  end
end

function UMG_PetReport_Particulars_C:OnClickedShare()
  if self:CheckIsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PetReport_Particulars_C:OnClickedShare")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetReportShare, self.uiData)
end

function UMG_PetReport_Particulars_C:OnAnimationFinished(Anim)
  if Anim == self.Special_out or Anim == self.Special_change_out then
    if self.OnClickBtn == OnClickBtnType.Skip then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.StartShowPetReportTips, true)
    else
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.StartShowPetReportTips)
    end
  elseif Anim == self.Special_in or Anim == self.Special_change_in then
    self:PlayAnimation(self.Special_loop, 0, 0)
  elseif Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_PetReport_Particulars_C:OnChangeNum()
  if self.curTimeCnt + 1 < self.tickNum then
    local ratio = self.final_ratio / self.tickNum * self.curTimeCnt
    self.curTimeCnt = self.curTimeCnt + 1
    if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsInteger, self.final_ratio) then
      self.MultiplyingPowerText:SetText(tostring(math.floor(ratio)))
    else
      self.MultiplyingPowerText:SetText(string.format("%.1f", ratio))
    end
  end
end

function UMG_PetReport_Particulars_C:ChangeBG(bSpecial)
  if bSpecial then
    self.BgSwitcher:SetActiveWidgetIndex(1)
  else
    self.BgSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_PetReport_Particulars_C:CheckIsPlayingAnimation()
  if self:IsAnimationPlaying(self.Special_in) or self:IsAnimationPlaying(self.Special_out) or self:IsAnimationPlaying(self.Special_change_in) or self:IsAnimationPlaying(self.Special_change_out) or self:IsAnimationPlaying(self:GetAnimByIndex(0)) or self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return true
  end
  return false
end

function UMG_PetReport_Particulars_C:OnChangeNumTimerComplete()
  self:ClearChangeNumTimer()
  if _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsInteger, self.final_ratio) then
    self.MultiplyingPowerText:SetText(tostring(math.floor(self.final_ratio)))
  else
    self.MultiplyingPowerText:SetText(string.format("%.1f", self.final_ratio))
  end
  self.Prompt_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.HorizontalBox_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Number_show)
  self:PlayAnimation(self.Word_show)
end

function UMG_PetReport_Particulars_C:OnItemMoveInTimerComplete()
  self:ClearItemMoveInTimer()
  local itemCount = self.List:GetItemCount()
  for i = 1, itemCount do
    local item = self.List:GetItemByIndex(i - 1)
    if item then
      item.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_PetReport_Particulars_C:ClearChangeNumTimer()
  if self.ChangeNumTimer then
    _G.TimerManager:RemoveTimer(self.ChangeNumTimer)
    self.ChangeNumTimer = nil
  end
end

function UMG_PetReport_Particulars_C:ClearItemMoveInTimer()
  if self.ItemMoveInTimer then
    _G.TimerManager:RemoveTimer(self.ItemMoveInTimer)
    self.ItemMoveInTimer = nil
  end
end

function UMG_PetReport_Particulars_C:ClearTimer()
  self:ClearChangeNumTimer()
  self:ClearItemMoveInTimer()
end

function UMG_PetReport_Particulars_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = true
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PetReport_Particulars_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PetReport_Particulars_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_PET_REPORT
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
  if self.ShareIsOpen then
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PetReport_Particulars_C
