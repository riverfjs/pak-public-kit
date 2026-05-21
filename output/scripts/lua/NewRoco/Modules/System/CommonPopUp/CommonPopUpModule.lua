local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local CommonPopUpModule = NRCModuleBase:Extend("CommonPopUpModule")

function CommonPopUpModule:OnConstruct()
  _G.CommonPopUpModuleCmd = reload("NewRoco.Modules.System.CommonPopUp.CommonPopUpModuleCmd")
  _G.NRCEventCenter:RegisterEvent("CommonPopUpModule", self, BattleEvent.EnterBattle, self.OnEnterBattle)
  self.data = self:SetData("CommonPopUpModuleData", "NewRoco.Modules.System.CommonPopUp.CommonPopUpModuleData")
end

function CommonPopUpModule:OnActive()
  self:RegisterCmd(CommonPopUpModuleCmd.ChangeScene, self.ChangeScene)
  self:RegisterCmd(CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, self.OnCmdOpenNPCShopItemRewardsPanel)
  self:RegisterCmd(CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, self.OnCmdOpenNounInterpretationTipsPanel)
  self:RegisterCmd(CommonPopUpModuleCmd.CloseNounInterpretationTipsPanel, self.OnCmdCloseNounInterpretationTipsPanel)
  self:RegisterCmd(CommonPopUpModuleCmd.ActionOpenNPCShopItemRewardsPanel, self.ActionOpenNPCShopItemRewardsPanel)
  self:RegisterCmd(CommonPopUpModuleCmd.CloseNPCShopItemRewardsPanel, self.CmdCloseNPCShopItemRewardsPanel)
  self:RegisterCmd(CommonPopUpModuleCmd.IsItemRewardsPanelOpen, self.IsItemRewardsPanelOpen)
  self:RegPanel("Common_Remind", "UMG_Common_Remind", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("ItemRewardsPanel", "UMG_ReceiveAward_PopUp", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self.HiddenRedPointList = {}
  self:RegPanel("CommonPopUp_WithItem", "UMG_CommonPopUp_WithItem", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, true, true)
  self:RegPanel("NounInterpretationTips", "UMG_Common_NounInterpretationTips", _G.Enum.UILayerType.UI_LAYER_TOP, nil, nil, true, true)
  self:RegPanel("ActivityCommon", "UMG_Activity_Common", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("CommonExplanation", "UMG_Common_Explanation", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
end

function CommonPopUpModule:OnRelogin()
end

function CommonPopUpModule:OnDeactive()
end

function CommonPopUpModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.EnterBattle, self.OnEnterBattle)
end

function CommonPopUpModule:OnCmdOpenRemindPanel(Param)
  self:OpenPanel("Common_Remind", Param)
end

function CommonPopUpModule:OnCmdCloseRemindPanel()
  self:ClosePanel("Common_Remind")
end

function CommonPopUpModule:OpenCommonPopUpWithItem(itemList)
  self:OpenPanel("CommonPopUp_WithItem", itemList)
end

function CommonPopUpModule:OnCmdOpenNounInterpretationTipsPanel(data)
  self:OpenPanel("NounInterpretationTips", data)
end

function CommonPopUpModule:OnCmdCloseNounInterpretationTipsPanel()
  self:ClosePanel("NounInterpretationTips")
end

function CommonPopUpModule:OnEnterBattle()
  self:ClosePanel("NounInterpretationTips")
end

function CommonPopUpModule:RegPanel(name, path, layer, openAnimName, closeAnimName, bCustomDisableRendering, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/CommonPopUp/Res/%s", path)
  registerData.panelLayer = layer
  if openAnimName then
    registerData.openAnimName = openAnimName
  end
  if closeAnimName then
    registerData.closeAnimName = closeAnimName
  end
  registerData.enablePcEsc = enablePcEsc
  registerData.customDisableRendering = bCustomDisableRendering or false
  self:RegisterPanel(registerData)
end

function CommonPopUpModule:ChangeScene()
  local hasPanel = self:HasPanel("ItemRewardsPanel")
  if hasPanel then
    self:ClosePanel("ItemRewardsPanel")
  end
end

function CommonPopUpModule:OnCmdOpenNPCShopItemRewardsPanel(param, _param1, IsLevelReward, IsOpenByBattleRewardPanel, IsOpenLegendaryBattleClosePanel, IsWorldOpen, bIsSpecialAward, PopUpData, IsBestowBlessings)
  local _param = table.deepCopy(param or {})
  if _param and "table" == type(_param) then
    local finalGoodsItemList, hasFiltered, removeItemIdList = self:FilterGoodsItemShowByVisualItemConfig(_param)
    if hasFiltered then
      if removeItemIdList and #removeItemIdList > 0 then
        Log.Info("CommonPopUpModule:OnCmdOpenNPCShopItemRewardsPanel filter items by visual item config, remove item ids: ", table.concat(removeItemIdList, ","))
      else
        Log.Error("CommonPopUpModule:OnCmdOpenNPCShopItemRewardsPanel filter items by visual item config, but removeItemIdList is empty")
      end
      if not finalGoodsItemList or #finalGoodsItemList <= 0 then
        Log.Info("CommonPopUpModule:OnCmdOpenNPCShopItemRewardsPanel all items are filtered, not open panel")
        return
      end
      _param = finalGoodsItemList
    end
  end
  if IsLevelReward then
    self:OpenPanel("NPCShopItemRewards", _param, _param1, IsLevelReward, nil, nil, nil, bIsSpecialAward)
  else
    local panelName = "ItemRewardsPanel"
    if IsOpenByBattleRewardPanel then
      self:OpenPanel(panelName, _param, _param1, nil, nil, IsOpenByBattleRewardPanel, nil, bIsSpecialAward)
    else
      self:OpenPanel(panelName, _param, _param1, IsLevelReward, nil, IsOpenByBattleRewardPanel, IsOpenLegendaryBattleClosePanel, bIsSpecialAward, PopUpData, IsWorldOpen, IsBestowBlessings)
    end
  end
end

function CommonPopUpModule:FilterGoodsItemShowByVisualItemConfig(goodsItemList)
  if not goodsItemList or #goodsItemList <= 0 then
    return goodsItemList, false, {}
  end
  local finalGoodsItemList = {}
  local removeItemIdList = {}
  for i, item in ipairs(goodsItemList) do
    if item and item.type and item.type == _G.ProtoEnum.GoodsType.GT_BP_GIFT then
      table.insert(removeItemIdList, item.id)
    else
      if item and item.type and item.type == _G.ProtoEnum.GoodsType.GT_VITEM then
        local visualItemConfig = _G.DataConfigManager:GetVisualItemConf(item.id)
        if visualItemConfig and visualItemConfig.is_hidetips then
          table.insert(removeItemIdList, item.id)
      end
      else
        table.insert(finalGoodsItemList, item)
      end
    end
  end
  return finalGoodsItemList, table.isNotEmpty(removeItemIdList), removeItemIdList
end

function CommonPopUpModule:ActionOpenNPCShopItemRewardsPanel(reward_id, action, IsWorldOpen)
  if IsWorldOpen then
    self:OpenPanel("ItemRewardsPanel", nil, nil, reward_id, action, nil, nil, nil, nil, IsWorldOpen)
  else
    self:OpenPanel("ItemRewardsPanel", nil, nil, reward_id, action)
  end
end

function CommonPopUpModule:CmdCloseNPCShopItemRewardsPanel()
  if self:HasPanel("ItemRewardsPanel") then
    self:ClosePanel("ItemRewardsPanel")
  end
end

function CommonPopUpModule:IsItemRewardsPanelOpen()
  return self:HasPanel("ItemRewardsPanel")
end

function CommonPopUpModule:OpenActivityCommonPanel(data)
  if not (data and data.entries) or #data.entries <= 0 then
    return
  end
  local allEntryHasImage = true
  for _, entry in ipairs(data.entries) do
    if string.IsNilOrEmpty(entry.imagPath) then
      allEntryHasImage = false
      break
    end
  end
  if allEntryHasImage then
    self:OpenPanel("ActivityCommon", data)
  else
    self:OpenPanel("CommonExplanation", data)
  end
end

return CommonPopUpModule
