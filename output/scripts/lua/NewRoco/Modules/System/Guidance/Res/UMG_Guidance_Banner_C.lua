local GuideConfigTypes = require("NewRoco.Modules.System.Guidance.Types.GuideConfigTypes")
local Base = require("Core.NRCModule.NRCPanelBase")
local UMG_Guidance_Banner_C = Base:Extend("UMG_Guidance_Banner_C")

function UMG_Guidance_Banner_C:OnActive(style, bannerConf)
  local text = ""
  if _G.UE4Helper.IsPCMode() then
    text = bannerConf.pc_text
  else
    text = bannerConf.mobile_text
  end
  self.Text_Hint:SetText(text)
  local panelWidget, panelData = GuideConfigTypes.GetTargetWidget({
    bannerConf.show_panel
  }, nil, true)
  if not panelWidget then
    Log.Warning("UMG_Guidance_Banner_C:OnActive panelWidget is nil", bannerConf.show_panel)
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    _G.NRCModuleManager:DoCmd(_G.GuidanceModuleCmd.SubGuideFocusTargetLost)
    return
  end
  self.targetPanel = panelWidget
  self.targetPanelData = panelData
end

function UMG_Guidance_Banner_C:CheckPanelOnTop()
  if not self.targetPanelData then
    return
  end
  if GuideConfigTypes.CheckIsTopPanel(self.targetPanelData) then
    if not self:IsVisible() then
      Log.Debug("UMG_Guidance_Banner_C:CheckPanelOnTop", "panel is on top")
      self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  elseif self:IsVisible() then
    Log.Debug("UMG_Guidance_Banner_C:CheckPanelOnTop", "panel is not on top")
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Guidance_Banner_C
