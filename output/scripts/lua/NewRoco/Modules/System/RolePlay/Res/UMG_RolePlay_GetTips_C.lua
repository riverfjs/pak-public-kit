local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local UMG_RolePlay_GetTips_C = _G.NRCPanelBase:Extend("UMG_RolePlay_GetTips_C")

function UMG_RolePlay_GetTips_C:OnConstruct()
  self:AddButtonListener(self.clickbtn, self.OnClickTips)
  self:AddEventListener()
  self.iconWidgets = {
    [RolePlayModuleDef.RolePlayType.Action] = self.Icon,
    [RolePlayModuleDef.RolePlayType.Sound] = self.Icon_1,
    [RolePlayModuleDef.RolePlayType.Suit] = self.Icon_2,
    [RolePlayModuleDef.RolePlayType.PutProp] = self.Icon
  }
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.tipsDisplayController = _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.GetDisplayController, TipEnum.TipObjectType.RolePlayGetTips)
  if self.tipsDisplayController then
    self.tipsDisplayController:BindView(self)
    self.tipsDisplayController:GetExecutor():StartTipDispatchStateListener()
  end
  self:PCKeySetting()
end

function UMG_RolePlay_GetTips_C:OnDestruct()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
end

function UMG_RolePlay_GetTips_C:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_RolePlay_GetTips_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_RolePlay_GetTips_C:TryClose()
  if self.tipsDisplayController then
    self.tipsDisplayController:UnBindView()
  end
  if self:GetVisibility() ~= UE4.ESlateVisibility.Collapsed then
    self:OnClose()
  else
    self:DoClose()
  end
end

function UMG_RolePlay_GetTips_C:OnPlayTips(tip)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008001, "UMG_RolePlay_GetTips_C:OnPlayTips")
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local tipData = tip.customData
  if tipData.rolePlayType == RolePlayModuleDef.RolePlayType.PutProp then
    self.NRCSwitcher_56:SetActiveWidgetIndex(0)
  else
    self.NRCSwitcher_56:SetActiveWidgetIndex(tipData.rolePlayType - 1)
  end
  self.title:SetText(tipData.title)
  self.content:SetText(tipData.content)
  local icon = self.iconWidgets[tipData.rolePlayType]
  if icon then
    icon:SetPath(tipData.iconPath)
  end
  if tip.timeLeft then
    self.time:SetText(string.format(tipData.countdownStr, tip.timeLeft))
  end
end

function UMG_RolePlay_GetTips_C:PCKeySetting()
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_MessageDetails")
    local tip = self.tipsDisplayController:GetExecutor():GetNextTip()
    if tip and tip.pcKeyIAName and tip.pcKeyIAName ~= "" then
      InputAction = tip.pcKeyIAName
    end
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    self.PCKey:SetKeyVisibility(true)
  end
end

function UMG_RolePlay_GetTips_C:OnUpdateTips(tip, interval)
  if tip and tip.timeLeft then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local tipData = tip.customData
    self.time:SetText(string.format(tipData.countdownStr, tip.timeLeft))
  end
end

function UMG_RolePlay_GetTips_C:OnAllTipsFinished()
  self:TryClose()
end

function UMG_RolePlay_GetTips_C:OnPlayTipStatusChange(pause)
  if pause then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RolePlay_GetTips_C:OnClickTips(bPcMode)
  _G.NRCProfilerLog:NRCClickBtn(true, "RolePlayMainPanel")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401004, "UMG_RolePlay_GetTips_C:OnClickTips")
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    if tip then
      local tipData = tip.customData
      if tip.customData.rolePlayType == RolePlayModuleDef.RolePlayType.Suit then
        if nil == bPcMode or false == bPcMode then
          local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
          local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
          if not isBan and not isHide then
            _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true)
          else
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.umg_gameinfomain_1)
          end
        else
          return
        end
      elseif _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.CheckCanOpenMainPanel) then
        _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OpenMainPanel, tipData.rolePlayType)
      end
    end
    self.tipsDisplayController:GetExecutor():ConsumeNextTip()
  else
    self:TryClose()
  end
end

function UMG_RolePlay_GetTips_C:HasValidData()
  if self.tipsDisplayController then
    local tip = self.tipsDisplayController:GetExecutor():GetDisplayingTip()
    return nil ~= tip
  end
  return false
end

return UMG_RolePlay_GetTips_C
