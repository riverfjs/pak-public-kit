local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_PlantSeeds_Tab_C = Base:Extend("UMG_PlantSeeds_Tab_C")

function UMG_PlantSeeds_Tab_C:OnConstruct()
end

function UMG_PlantSeeds_Tab_C:OnDestruct()
end

function UMG_PlantSeeds_Tab_C:OnItemUpdate(_data, datalist, index)
  if not _data then
    return
  end
  self.uiData = _data
  local plantTabConf = _G.DataConfigManager:GetPlantTabConf(self.uiData.tabConfId, true)
  local tabName = ""
  if plantTabConf then
    tabName = plantTabConf.name
  end
  self.SeedTitle_1:SetText(tabName)
end

function UMG_PlantSeeds_Tab_C:OnItemSelected(_bSelected, placeHolder, userClick)
  if not self.uiData then
    return
  end
  if _bSelected then
    self:PlayAnimation(self.change1)
    if userClick then
      _G.NRCAudioManager:PlaySound2DAuto(1005, "UMG_PlantSeeds_Tab_C:OnItemSelected")
    end
    if self.uiData and self.uiData.callbackCaller and self.uiData.callbackFunc then
      self.uiData.callbackFunc(self.uiData.callbackCaller, self._index, self.uiData.index)
    end
  else
    self:PlayAnimation(self.change2)
  end
end

function UMG_PlantSeeds_Tab_C:OnDeactive()
end

return UMG_PlantSeeds_Tab_C
