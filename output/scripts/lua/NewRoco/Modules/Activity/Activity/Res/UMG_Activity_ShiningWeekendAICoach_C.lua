local JsonUtils = require("Common.JsonUtils")
local UMG_Activity_ShiningWeekendAICoach_C = _G.NRCPanelBase:Extend("UMG_Activity_ShiningWeekendAICoach_C")

function UMG_Activity_ShiningWeekendAICoach_C:OnConstruct()
  self:SetChildViews(self.PopUp)
end

function UMG_Activity_ShiningWeekendAICoach_C:OnActive()
  self:SetChildViews(self.PopUp)
  self:OnAddEventListener()
  self:RefreshInfo()
  self:LoadAnimation(0)
end

function UMG_Activity_ShiningWeekendAICoach_C:OnDeactive()
end

function UMG_Activity_ShiningWeekendAICoach_C:OnAddEventListener()
  self.Text1.OnRichTextClick:Add(self, self.OnRichTextClick)
  self:AddButtonListener(self.Btn.btnLevelUp, self.OnAgreeAndOpen)
  self:AddButtonListener(self.PopUp.btnClose.btnClose, self.OnCloseClick)
end

function UMG_Activity_ShiningWeekendAICoach_C:OnAgreeAndOpen()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_ShiningWeekendAICoach_C:OnAgreeAndOpen")
  _G.NRCModuleManager:DoCmd(_G.AICoachModuleCmd.OnSetAICoachState, ProtoEnum.AiCoachStatus.ACS_QA)
  local playerInfo = DataModelMgr.PlayerDataModel:GetPlayerInfo()
  local key = "AICoachAgreeRecode" .. tostring(playerInfo.brief_info.uin)
  JsonUtils.DumpSaved(key, {Agree = true})
  self:LoadAnimation(2)
end

function UMG_Activity_ShiningWeekendAICoach_C:OnCloseClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Activity_ShiningWeekendAICoach_C:OnCloseClick")
  self:LoadAnimation(2)
end

function UMG_Activity_ShiningWeekendAICoach_C:RefreshInfo()
  local commonPopUpData = _G.NRCCommonPopUpData()
  commonPopUpData.Call = self
  commonPopUpData.btnClose = true
  commonPopUpData.ClosePanelHandler = self.OnCloseClick
  commonPopUpData.TitleText = _G.LuaText.ai_coach_15
  self.PopUp:SetPanelInfo(commonPopUpData)
  self.Btn:SetBtnText(LuaText.ai_coach_17)
  self.Text1:SetText(LuaText.ai_coach_16)
end

function UMG_Activity_ShiningWeekendAICoach_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Activity_ShiningWeekendAICoach_C:OnRichTextClick(id)
end

return UMG_Activity_ShiningWeekendAICoach_C
