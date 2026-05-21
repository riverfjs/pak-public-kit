local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_ExclusiveMarkButton_C = Base:Extend("UMG_ExclusiveMarkButton_C")

function UMG_ExclusiveMarkButton_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_ExclusiveMarkButton_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_ExclusiveMarkButton_C:OnAddEventListener()
  self:AddButtonListener(self.ClickItemBtn, self.OnClickItemBtn)
end

function UMG_ExclusiveMarkButton_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.ClickItemBtn, self.OnClickItemBtn)
end

function UMG_ExclusiveMarkButton_C:OnClickItemBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401007, "UMG_ExclusiveMarkButton_C:OnClickItemBtn")
  if self.ItemId < 100000 then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ItemId, _G.Enum.GoodsType.GT_VITEM, false)
  else
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, self.ItemId, _G.Enum.GoodsType.GT_BAGITEM, false)
  end
end

function UMG_ExclusiveMarkButton_C:OnItemUpdate(_data, datalist, index)
  if not _data then
    return
  end
  local costItemId, costNum = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, _data.content_cfg_id)
  local hasNum = (_G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItemId) or {}).num or 0
  self.ItemId = costItemId
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId)
  if bagItemConf then
    self.MoneyIcon:SetPath(bagItemConf.icon)
  end
  self.SumNum:SetText(hasNum)
end

function UMG_ExclusiveMarkButton_C:OnItemSelected(_bSelected)
end

function UMG_ExclusiveMarkButton_C:OnDeactive()
end

return UMG_ExclusiveMarkButton_C
