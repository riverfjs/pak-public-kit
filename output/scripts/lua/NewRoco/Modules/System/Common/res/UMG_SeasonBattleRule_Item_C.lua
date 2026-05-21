local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_SeasonBattleRule_Item_C = Base:Extend("UMG_SeasonBattleRule_Item_C")

function UMG_SeasonBattleRule_Item_C:OnConstruct()
  if self.addNumTxt then
    self.addNumTxt.OnRichTextClick:Add(self, self.OnAddNumTxtClicked)
  end
  self.linkDesc = ""
end

function UMG_SeasonBattleRule_Item_C:OnDestruct()
  if self.addNumTxt then
    self.addNumTxt.OnRichTextClick:Remove(self, self.OnAddNumTxtClicked)
  end
end

function UMG_SeasonBattleRule_Item_C:OnItemUpdate(_data, datalist, index)
  local battleRuleConf = _G.DataConfigManager:GetBattleRuleConf(_data)
  if battleRuleConf then
    local ruleStr = battleRuleConf.desc
    local titleStr = battleRuleConf.title
    self.linkDesc = string.format("%s\239\188\154%s", tostring(titleStr), tostring(ruleStr))
    self.addNumTxt:SetText(self.linkDesc)
  else
    self.addNumTxt:SetText("")
  end
end

function UMG_SeasonBattleRule_Item_C:OnAddNumTxtClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.linkDesc
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

return UMG_SeasonBattleRule_Item_C
