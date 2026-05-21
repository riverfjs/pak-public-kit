local Base = require("NewRoco.Modules.System.TipsModule.Res.Tips.Season_BonusCatch.UMG_ContinuousCapture_Tips_Base_C")
local UMG_CircusOpeningAnnouncementTips_C = Base:Extend("UMG_CircusOpeningAnnouncementTips_C")

function UMG_CircusOpeningAnnouncementTips_C:SetTipsContent(tip)
  if tip and tip.text then
    self.Title:SetText(tip.text)
  end
  self:PlayAnimation(self.In)
end

function UMG_CircusOpeningAnnouncementTips_C:OnAnimationFinished(Animation)
  if self.In == Animation then
    self:OnTipsEnd()
  end
end

return UMG_CircusOpeningAnnouncementTips_C
