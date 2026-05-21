local UMG_LobbyDownTips_C = _G.NRCPanelBase:Extend("UMG_LobbyDownTips_C")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")

function UMG_LobbyDownTips_C:OnConstruct()
  self.tipsDisplayController = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.GetDisplayController, TipEnum.TipObjectType.LobbyDownTips)
end

function UMG_LobbyDownTips_C:OnDestruct()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
    self.tipsDisplayController = nil
  end
end

function UMG_LobbyDownTips_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
end

function UMG_LobbyDownTips_C:OnPlayTips(tip)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:TipsPlay(tip)
end

function UMG_LobbyDownTips_C:OnPlayTipStatusChange(pause)
  if pause then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    if tip then
      local tipUmg
      if tip.type == TipEnum.LobbyDownTipsType.BookPrompt then
        tipUmg = self.UMG_BookPrompt
      elseif tip.type == TipEnum.LobbyDownTipsType.PassAccomplish then
        tipUmg = self.UMG_Pass_Accomplish
      end
      if tipUmg then
        self.curPausedTipUmg = tipUmg
        local handled = false
        if tipUmg.SetPaused then
          handled = tipUmg:SetPaused(true)
        end
        if not handled then
          tipUmg:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    end
  else
    local curPausedTipUmg = self.curPausedTipUmg
    self.curPausedTipUmg = nil
    if curPausedTipUmg then
      local handled = false
      if curPausedTipUmg.SetPaused then
        handled = curPausedTipUmg:SetPaused(false)
      end
      if not handled then
        curPausedTipUmg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function UMG_LobbyDownTips_C:OnAllTipsFinished()
  self:TipsEnd()
end

function UMG_LobbyDownTips_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_LobbyMessageDetails")
  if mappingContext then
    mappingContext:BindAction("IA_MessageDetails")
  end
end

function UMG_LobbyDownTips_C:UnBindInputAction()
  self:RemoveInputMappingContext("IMC_LobbyMessageDetails")
end

function UMG_LobbyDownTips_C:OnDisable()
  self:UnBindInputAction()
end

function UMG_LobbyDownTips_C:OnEnable()
  self:BindInputAction()
end

function UMG_LobbyDownTips_C:OpenMessageDetailsUI()
  local CurrentTip = self.tipsDisplayController and self.tipsDisplayController:GetExecutor():GetDisplayingTip()
  if CurrentTip then
    if CurrentTip.type == TipEnum.LobbyDownTipsType.BookPrompt then
      self.UMG_BookPrompt:OnbtnOpenHanbook()
    elseif CurrentTip.type == TipEnum.LobbyDownTipsType.PassAccomplish then
      self.UMG_Pass_Accomplish:OnClickButton_57()
    end
  end
end

function UMG_LobbyDownTips_C:TipsPlay(tip)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008001, "UMG_BookPrompt_C:OnConstruct")
  self:OnSwitcherNRCSwitcher_19(tip.type)
  local isStart = false
  if tip.type == TipEnum.LobbyDownTipsType.BookPrompt then
    isStart = true
    self.UMG_BookPrompt:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_BookPrompt:ConsumeTip(tip, self)
  elseif tip.type == TipEnum.LobbyDownTipsType.PassAccomplish then
    isStart = true
    self.UMG_Pass_Accomplish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Pass_Accomplish:OnActive(tip, self)
  end
  if isStart then
    _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.LOBBY_DOWN_TIPS_START)
  end
end

function UMG_LobbyDownTips_C:TipsEnd()
  _G.NRCEventCenter:DispatchEvent(NRCGlobalEvent.LOBBY_DOWN_TIPS_END)
  self:DoClose()
end

function UMG_LobbyDownTips_C:TipsNext()
  if self.tipsDisplayController then
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  end
end

function UMG_LobbyDownTips_C:OnSwitcherNRCSwitcher_19(SwitcherIndex)
  self.NRCSwitcher_19:SetActiveWidgetIndex(SwitcherIndex)
end

return UMG_LobbyDownTips_C
