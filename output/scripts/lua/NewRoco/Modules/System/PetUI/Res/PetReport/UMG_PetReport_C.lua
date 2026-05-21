local UMG_PetReport_C = _G.NRCPanelBase:Extend("UMG_PetReport_C")

function UMG_PetReport_C:OnConstruct()
  self.Clickable = false
  self:OnAddEventListener()
end

function UMG_PetReport_C:OnActive(param)
  self.uiData = param
  self.PetSubmitAction = self.uiData.PetSubmitAction
  self:ClearTimer()
  self:InitUI()
  _G.NRCAudioManager:PlaySound2DAuto(1372, "UMG_PetReport_C:OnActive")
  self:PlayAnimation(self.In)
end

function UMG_PetReport_C:OnDeactive()
  self:ClearTimer()
end

function UMG_PetReport_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose, self.OnClickedClose)
end

function UMG_PetReport_C:InitUI()
  if self.uiData and self.uiData.reportData and self.uiData.submitPetReward then
    local cnt = #self.uiData.reportData
    self.Number:SetText(tostring(cnt))
    self.Number_1:SetText("0")
    local petList = {}
    for index, data in pairs(self.uiData.reportData or {}) do
      if data then
        local singleInfo = {}
        singleInfo.index = index
        singleInfo.final_ratio = data.final_ratio / 10000
        singleInfo.total_coin = data.total_coin
        if data.pet_brief then
          singleInfo.pet_brief = data.pet_brief
        end
        table.insert(petList, singleInfo)
      end
    end
    table.sort(petList, function(a, b)
      if a.final_ratio == b.final_ratio then
        return a.total_coin > b.total_coin
      else
        return a.final_ratio > b.final_ratio
      end
    end)
    self.List:InitList(petList)
  end
end

function UMG_PetReport_C:OnClickedClose()
  if self:IsAnimationPlaying(self.In) or self:IsAnimationPlaying(self.Out) then
    return
  end
  self.bReadToClose = true
  if self:IsAnimationPlaying(self.Collect_1) or self.GetCoinTimer then
    if self.coinSoundID then
      _G.NRCAudioManager:ReleaseSession(self.coinSoundID, true, "UMG_PetReport_C:OnClickedClose", false, 0.2)
      self.coinSoundID = nil
    end
    self:StopAnimation(self.Collect_1)
    self:StopAnimation(self.In)
    self:ClearTimer()
    self:OnTimerComplete()
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_PetReport_C:OnClickedClose")
  self:PlayAnimation(self.Out)
  if self.PetSubmitAction then
    self.PetSubmitAction:BeginEnd()
    self.PetSubmitAction = nil
  end
end

function UMG_PetReport_C:OnAnimationFinished(Animation)
  if Animation == self.In and not self.bReadToClose then
    self.coinSoundID = _G.NRCAudioManager:PlaySound2DAuto(41401021, "UMG_PetReport_C:OnAnimationFinished In")
    self:PlayAnimation(self.Collect_1)
  elseif Animation == self.Collect_1 and not self.bReadToClose then
    self:PlayGetCoinAnim()
  elseif Animation == self.Out then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.ClosePetReportPanel)
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.EndPetSubmitAction)
  end
end

function UMG_PetReport_C:PlayGetCoinAnim()
  self:PlayAnimation(self.Collect_2)
  self:ClearTimer()
  if self.uiData and self.uiData.submitPetReward then
    self.curNum = 0
    self.tickNum = 200
    self.curTimeCnt = 0
    self.finalNum = self.uiData.submitPetReward
    self.Number_1:SetText(tostring(self.curNum))
    self.GetCoinTimer = _G.TimerManager:CreateTimer(self, "GetCoinTimer", 2, self.OnTimerUpdate, self.OnTimerComplete, 0.01)
  end
end

function UMG_PetReport_C:OnTimerUpdate()
  self.curNum = tonumber(self.Number_1:GetText())
  if self.curTimeCnt + 1 < self.tickNum then
    local num = (self.finalNum - self.curNum) / self.tickNum * self.curTimeCnt + self.curNum
    self.curTimeCnt = self.curTimeCnt + 1
    self.Number_1:SetText(math.floor(num + 0.5))
  elseif self.uiData.submitPetReward then
    self.Number_1:SetText(tostring(self.uiData.submitPetReward))
  end
end

function UMG_PetReport_C:OnTimerComplete()
  if self.uiData and self.uiData.submitPetReward then
    self.Number_1:SetText(tostring(self.uiData.submitPetReward))
  end
  self:ClearTimer()
end

function UMG_PetReport_C:ClearTimer()
  if self.GetCoinTimer then
    _G.TimerManager:RemoveTimer(self.GetCoinTimer)
    self.GetCoinTimer = nil
  end
end

return UMG_PetReport_C
