local UMG_PVE_Talent_C = _G.NRCPanelBase:Extend("UMG_PVE_Talent_C")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local TalentNodeLayoutInfo = {
  [1] = 3,
  [2] = 5,
  [3] = 7,
  [4] = 7,
  [5] = 7,
  [6] = 7
}

function UMG_PVE_Talent_C:OnConstruct()
  self:AddButtonListener(self.btnClose.btnClose, self.OnClose)
  self:AddButtonListener(self.LexiconBtn.btnLevelUp, self.OnClickOpenPveCurrentPeriod)
  self:AddButtonListener(self.RefreshDataBtn.btnLevelUp, self.OnClickReset)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnClickShowBrief)
  self:AddButtonListener(self.Btn_Return.btnClose, self.OnClickBtnReturn)
  self:RegisterEvent(self, PVEModuleEvent.TalentNodeLockStatusChange, self.OnTalentNodeLockStatusChange)
  self:RegisterEvent(self, PVEModuleEvent.TalentMaterialCntChange, self.OnTalentMaterialCntChange)
  self:RegisterEvent(self, PVEModuleEvent.TalentNodeUnlockCntChange, self.OnTalentNodeUnlockCntChange)
  self:RegisterEvent(self, PVEModuleEvent.SwitchCurrentTalentNode, self.OnSwitchCurrentTalentNode)
  self:RegisterEvent(self, PVEModuleEvent.ShowInnerPanels, self.ShowInnerPanels)
  self.Text_Lexicon:SetText(_G.LuaText.season_battle_rule_entry)
  self.lastSelectedItem = nil
end

function UMG_PVE_Talent_C:ShowInnerPanels(bVisible)
  if self.bInnerPanelShowFlag == bVisible then
    return
  end
  self.bInnerPanelShowFlag = bVisible
  self.CanvasPanel_175:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.LexiconBtn:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.ScrollBox_0:SetVisibility(bVisible and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.Text_Lexicon:SetVisibility(bVisible and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if self.NRCSwitcher_Btn then
    self.NRCSwitcher_Btn:SetActiveWidgetIndex(bVisible and 0 or 1)
  end
end

function UMG_PVE_Talent_C:OnDestruct()
end

function UMG_PVE_Talent_C:OnActive(talentData)
  self.talentData = talentData
  self:SetCommonTitle()
  self:OnTalentNodeUnlockCntChange(talentData.unlockNodeCnt, talentData.totalNodeCnt)
  local materialList = {
    {
      moneyType = talentData.material,
      sum = talentData.materialCnt
    }
  }
  self.MoneyBtn:InitGridView(materialList)
  local initNodeCallback = _G.MakeWeakFunctor(self, self.RefreshTalentNodeLinkLine)
  local nodeSortToId = talentData.nodeSortToId
  
  local function initNodeImpl(nodeSortId)
    local nodeCtrl = self[tostring(nodeSortId)]
    if nodeCtrl then
      local nodeId = nodeSortToId[nodeSortId]
      if nodeId then
        local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeId, true)
        if nodeConf then
          local umgCls = PVEModuleEnum.TalentNodeUmgCls[nodeConf.level]
          if not string.IsNilOrEmpty(umgCls) then
            nodeCtrl:SetWidgetClass(UE4.UKismetSystemLibrary.MakeSoftClassPath(umgCls))
            nodeCtrl:LoadPanel(nil, nodeConf, initNodeCallback)
          else
            Log.ErrorFormat("can not get node umgCls. nodeId=%d, nodeLevel=%d.", nodeId, nodeConf.level)
          end
        else
          Log.ErrorFormat("can not get node conf. nodeId=%d", nodeId)
        end
      else
        nodeCtrl:UnLoadPanel()
      end
    else
      Log.ErrorFormat("not valid widget ctrl. name=%d", nodeSortId)
    end
  end
  
  initNodeImpl(0)
  for row, nodeCnt in ipairs(TalentNodeLayoutInfo) do
    for col = 1, nodeCnt do
      initNodeImpl(row * 10 + col)
    end
  end
  self:BindInputAction()
  ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_GET_SEASON_TALENT_POINT_REQ, {})
end

function UMG_PVE_Talent_C:OnDeactive()
  self:UnBindInputAction()
end

function UMG_PVE_Talent_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_CommonCloseUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseUI", self, "OnPcClose2")
  end
end

function UMG_PVE_Talent_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_CommonCloseUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseUI")
  end
  self:RemoveInputMappingContext("IMC_CommonCloseUI")
end

function UMG_PVE_Talent_C:SetCommonTitle()
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName(), true)
  if titleConf then
    self.Title1:Set_MainTitle(titleConf.title)
    self.Title1:SetBg(titleConf.head_icon)
    self.Title1:SetSubtitle(titleConf.subtitle[1].subtitle)
  end
end

function UMG_PVE_Talent_C:RefreshTalentNodeLinkLine(nodeConf, status)
  local talentData = self.talentData
  local nodeSortId = nodeConf.sort
  for _, neighborSortId in ipairs(nodeConf.neighbor_sort) do
    local lineCtrlName = neighborSortId > nodeSortId and nodeSortId .. "_" .. neighborSortId or neighborSortId .. "_" .. nodeSortId
    local lineCtrl = self[lineCtrlName]
    if lineCtrl then
      lineCtrl:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      local bothUnlock = false
      if status == PVEModuleEnum.TalentNodeStatus.Unlocked and talentData then
        local neighborId = talentData.nodeSortToId[neighborSortId]
        if neighborId then
          local neighborData = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentNodeDataById, neighborId)
          if neighborData and neighborData.status == PVEModuleEnum.TalentNodeStatus.Unlocked then
            bothUnlock = true
          end
        end
      end
      lineCtrl:SetActiveWidgetIndex(bothUnlock and 1 or 0)
    else
      Log.ErrorFormat("missing widget! name=%s", lineCtrlName)
    end
  end
end

function UMG_PVE_Talent_C:OnTalentNodeLockStatusChange(nodeData, isInit)
  if not nodeData then
    return
  end
  local nodeCtrl = self[tostring(nodeData.sort)]
  if nodeCtrl then
    local itemInst = nodeCtrl:GetPanel()
    if UE4.UObject.IsValid(itemInst) then
      itemInst:RefreshLockStatus(nodeData, isInit)
    end
  end
  local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeData.id)
  if nodeConf then
    self:RefreshTalentNodeLinkLine(nodeConf, nodeData.status)
  end
end

function UMG_PVE_Talent_C:OnTalentMaterialCntChange(materialCnt)
  local materialItemInst = self.MoneyBtn:GetItemByIndex(0)
  if materialItemInst then
    materialItemInst:SetSumText(materialCnt)
  end
  self:RefreshAllCanUnlockNodeRipple()
end

function UMG_PVE_Talent_C:RefreshAllCanUnlockNodeRipple()
  local talentData = self.talentData
  if not talentData then
    return
  end
  
  local function refreshNode(sortId)
    local nodeCtrl = self[tostring(sortId)]
    if nodeCtrl then
      local itemInst = nodeCtrl:GetPanel()
      if UE4.UObject.IsValid(itemInst) and itemInst.itemData and itemInst.itemData.status == PVEModuleEnum.TalentNodeStatus.CanUnlock then
        itemInst:RefreshLockStatus(itemInst.itemData, true, true)
      end
    end
  end
  
  refreshNode(0)
  for row, nodeCnt in ipairs(TalentNodeLayoutInfo) do
    for col = 1, nodeCnt do
      refreshNode(row * 10 + col)
    end
  end
end

function UMG_PVE_Talent_C:OnTalentNodeUnlockCntChange(unLockCnt, totalCnt)
  self.ActivationQuantity:SetText(string.format("%d/%d", unLockCnt or 0, totalCnt or 0))
end

function UMG_PVE_Talent_C:GetItemInst(sortId)
  local nodeCtrl = self[tostring(sortId)]
  local itemInst = nodeCtrl and nodeCtrl:GetPanel()
  return itemInst
end

function UMG_PVE_Talent_C:OnSwitchCurrentTalentNode(newItem)
  local lastItem = self.lastSelectedItem
  if lastItem == newItem then
    return
  end
  local itemInst = lastItem and self:GetItemInst(lastItem.sort)
  if itemInst then
    itemInst:ChangeSelect(false)
  end
  itemInst = newItem and self:GetItemInst(newItem.sort)
  if itemInst then
    itemInst:ChangeSelect(true)
  end
  self.lastSelectedItem = newItem
end

function UMG_PVE_Talent_C:OnClickOpenPveCurrentPeriod()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_PVE_Talent_C:OnClickOpenPveCurrentPeriod")
  _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.OpenPveCurrentPeriod)
end

function UMG_PVE_Talent_C:OnClickReset()
  local returnMaterialCnt = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentResetReturnMaterialCnt)
  if returnMaterialCnt <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.season_talent_none_reset)
    return
  end
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(_G.LuaText.TIPS):SetContent(string.format(_G.LuaText.seasontalent_reset, "<img id=\"Research_Point\"/>" .. tostring(returnMaterialCnt or 0))):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(_G.LuaText.tips_dialog_butten_accept, _G.LuaText.tips_dialog_butten_cancel):SetClickAnywhereClose(true):SetCallbackOkOnly(nil, function()
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "PVEModule:OnZoneClearSeasonTalentPointRsp")
    local req = _G.ProtoMessage:newZoneClearSeasonTalentPointReq()
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLEAR_SEASON_TALENT_POINT_REQ, req)
  end)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_PVE_Talent_C:OnClickShowBrief()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(_G.LuaText.seasontalent_text_1):SetContent(_G.LuaText.seasontalent_text_2):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_PVE_Talent_C:OnClickBtnReturn()
  _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.ClosePveParticulars)
end

function UMG_PVE_Talent_C:OnPcClose2()
  self:OnClose()
end

return UMG_PVE_Talent_C
