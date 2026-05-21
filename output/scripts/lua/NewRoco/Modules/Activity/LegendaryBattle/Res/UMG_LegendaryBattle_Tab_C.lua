local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_LegendaryBattle_Tab_C = Base:Extend("UMG_LegendaryBattle_Tab_C")

function UMG_LegendaryBattle_Tab_C:OnConstruct()
end

function UMG_LegendaryBattle_Tab_C:OnDestruct()
end

function UMG_LegendaryBattle_Tab_C:OnItemUpdate(_data, datalist, index)
  self.index = index
  self.starNum = _data.starNum
  self:PlayAnimation(self.normal)
  self.TextSelect:SetText(_data.battleRomanNum)
  self.UnselectedText:SetText(_data.battleRomanNum)
end

function UMG_LegendaryBattle_Tab_C:OnItemSelected(_bSelected)
  self:StopAllAnimations()
  if _bSelected then
    _G.NRCAudioManager:PlaySound2DAuto(40007008, "UMG_LegendaryBattle_Tab_C:OnItemSelected")
    self:PlayAnimation(self.change1)
    self:BroadcastMsg("OnItemSelected", self.starNum)
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_LegendaryBattle_Tab_C:OnDeactive()
end

return UMG_LegendaryBattle_Tab_C
