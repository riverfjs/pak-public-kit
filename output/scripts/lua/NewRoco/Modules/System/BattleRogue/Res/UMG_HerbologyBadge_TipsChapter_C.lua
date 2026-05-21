local Base = require("NewRoco.Modules.System.BattleRogue.Res.UMG_HerbologyBadge_Tips_C")
local UMG_HerbologyBadge_TipsChapter_C = Base:Extend("UMG_HerbologyBadge_TipsChapter_C")

function UMG_HerbologyBadge_TipsChapter_C:OnActive(caller, callback)
  local chapterConfId = self.module.Data.CurChapterID
  if not chapterConfId then
    Log.Error("\231\171\160\232\138\130\228\184\186\231\169\186")
    self:DoClose()
    return
  end
  local chapterConf = _G.DataConfigManager:GetGrassTrialChapterConf(chapterConfId)
  if not chapterConf then
    Log.Error("\228\188\160\229\133\165\231\154\132id\229\156\168GrassTrialChapterConf\232\161\168\228\184\173\230\178\161\230\156\137\230\137\190\229\136\176", chapterConfId)
    self:DoClose()
    return
  end
  self.Title:SetText(chapterConf.chapter)
  self.Title_Describe:SetText(chapterConf.name)
  self:PlayAnimation(self.Event)
  if caller and callback then
    self.FinishedCallback = _G.MakeWeakFunctor(caller, callback)
  end
end

return UMG_HerbologyBadge_TipsChapter_C
