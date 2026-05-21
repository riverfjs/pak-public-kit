local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local MainUIModuleUtils = require("NewRoco.Modules.System.MainUI.MainUIModuleUtils")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local UMG_SimpleUseList_C = _G.NRCPanelBase:Extend("UMG_SimpleUseList_C")

function UMG_SimpleUseList_C:OnActive(type)
  self.ListType = type
  self:SetListInfo(type)
  if self:IsPCMode() then
    self:PlayAnimation(self.open_R)
  else
    self:PlayAnimation(self.open)
  end
  self.IsCollapse = false
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self:OnAddEventListener()
end

function UMG_SimpleUseList_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBallListChange)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.MagicBanStateChanged, self.OnMagicBanStateChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.UI_RefreshPlayerAbilities, self.OnMagicBanStateChanged)
end

function UMG_SimpleUseList_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCPanelEvent.OpenPanel, self.OnOpenPanel)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBallListChange)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.MagicBanStateChanged, self.OnMagicBanStateChanged)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.UI_RefreshPlayerAbilities, self.OnMagicBanStateChanged)
end

function UMG_SimpleUseList_C:OnOpenPanel(PanelData)
  local moduleName = PanelData.moduleName
  if "GuidanceModule" == moduleName then
    return
  end
  local Name = PanelData.panelName
  if "UMG_SimpleUseList" ~= Name then
    self:DoClose()
  end
end

function UMG_SimpleUseList_C:OnEnable()
  self:StopAllAnimations()
  if self.IsCollapse then
    self:Disable()
    return
  end
  UE4Helper.SetDesiredShowCursor(true, "UMG_SimpleUseList_C")
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self:IsPCMode() then
    self:PlayAnimation(self.open_R)
  else
    self:PlayAnimation(self.open)
  end
  if not self.opening then
    self.opening = true
  end
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_SimpleUseList_C", self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
  NRCEventCenter:DispatchEvent(GuidanceModuleEvent.OnPanelLoaded, self.panelData)
end

function UMG_SimpleUseList_C:OnDisable()
  if self.opening then
    self.opening = nil
  end
  UE4Helper.ReleaseDesiredShowCursor("UMG_SimpleUseList_C")
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
  NRCEventCenter:DispatchEvent(GuidanceModuleEvent.OnPanelClosed, self.panelData)
end

function UMG_SimpleUseList_C:OnConstruct()
end

function UMG_SimpleUseList_C:OnDestruct()
end

function UMG_SimpleUseList_C:ClosePanel()
  if self.IsCollapse then
    return
  end
  self.IsCollapse = true
  if self:IsPCMode() then
    self:PlayAnimation(self.close_R)
  else
    self:PlayAnimation(self.close)
  end
end

function UMG_SimpleUseList_C:SetListInfo(type)
  self.ListType = type
  self.IsCollapse = false
  local pos = self.CanvasPanel.Slot:GetPosition()
  if type == ProtoEnum.BagItemType.BI_PET_BALL then
    self:RefreshBallList()
    pos.x = 440
    pos.y = -508
  else
    self.ScrollBox_69:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Panel_Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local itemList = {}
    local itemListFull = {}
    itemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByType, type)
    if itemList and type == ProtoEnum.BagItemType.BI_MAGIC then
      itemList = MainUIModuleUtils.SortMagicListByPriority(itemList)
    end
    if itemList then
      for i = 1, 6 do
        table.insert(itemListFull, {
          itemInfo = itemList[i]
        })
      end
    end
    pos.x = 570
    pos.y = -508
    self.List:InitGridView(itemListFull)
  end
  self.CanvasPanel.Slot:SetPosition(pos)
  self.Particle1:PlayAnimation(self.Particle1.loop, 0)
  self.Particle2:PlayAnimation(self.Particle2.loop, 0)
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    UE4.UNRCTUIStatics.ReleaseCursorCapture(0)
  end
end

function UMG_SimpleUseList_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_SimpleUseList_C:PCModeScreenSetting()
  self.Arrow_Down:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Arrow_Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local Padding = UE4.FMargin()
  Padding.Left = -641
  Padding.Right = 480.399994
  Padding.Bottom = 331.045868
  if self.ListType == ProtoEnum.BagItemType.BI_PET_BALL then
    Padding.Top = -445
  else
    Padding.Top = -585
  end
  self.CanvasPanel:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  self.CanvasPanel.Slot:SetOffsets(Padding)
  local anchors = UE4.FAnchors()
  anchors.Minimum = UE4.FVector2D(1, 1)
  anchors.Maximum = UE4.FVector2D(1, 1)
  self.CanvasPanel.Slot:SetAnchors(anchors)
end

function UMG_SimpleUseList_C:OnAnimationFinished(anim)
  if anim == self.close or anim == self.close_R then
    self:Disable()
  elseif anim == self.open then
    self:PlayAnimation(self.loop)
  elseif anim == self.open_R then
    self:PlayAnimation(self.loop_R)
  end
end

function UMG_SimpleUseList_C:OnPlayerStatusChanged(status, value)
  self:UpdateListItemUI()
end

function UMG_SimpleUseList_C:UpdateListItemUI()
  local totalCount = self.List:GetItemCount()
  for i = 1, totalCount do
    local item = self.List:GetItemByIndex(i - 1)
    if item then
      item:UpdateItemInfo()
    end
  end
end

function UMG_SimpleUseList_C:OnBallListChange(GoodsChangeItems)
  local isRefresh = false
  if GoodsChangeItems then
    for _, GoodsChangeItem in ipairs(GoodsChangeItems) do
      if GoodsChangeItem.bag_item and GoodsChangeItem.bag_item.type == ProtoEnum.BagItemType.BI_PET_BALL then
        isRefresh = true
        break
      end
    end
  end
  if isRefresh and self.ListType == ProtoEnum.BagItemType.BI_PET_BALL then
    self:RefreshBallList()
  end
end

function UMG_SimpleUseList_C:RefreshBallList()
  local itemList = {}
  local itemListFull = {}
  itemList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetEquipBallList)
  if itemList then
    for _, item in ipairs(itemList) do
      if item and item.idx == nil then
        item.idx = 999
      end
      table.insert(itemListFull, {itemInfo = item})
    end
  end
  local curEquipItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetCurEquipItemInfo)
  if curEquipItem and 0 == curEquipItem.num then
    local ballConf = _G.DataConfigManager:GetBallConf(curEquipItem.id)
    if ballConf and ballConf.bigworld_catch ~= false then
      if curEquipItem.idx == nil then
        curEquipItem.idx = 999
      end
      table.insert(itemListFull, {itemInfo = curEquipItem})
    end
  end
  local resultList = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBallNormalSortList, itemListFull)
  if #resultList > 0 then
    self.ScrollBox_69:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Panel_Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.List:InitGridView(resultList)
    local index
    local getEquipItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetCurEquipItemInfo)
    for i, item in ipairs(resultList) do
      if getEquipItem and getEquipItem.gid == item.itemInfo.gid then
        index = i
        break
      end
    end
    if index then
      local curRol = math.ceil(index / 3)
      self.ScrollBox_69:SetScrollOffset(130 * (curRol - 1))
    end
  else
    self.ScrollBox_69:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Panel_Kong:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_SimpleUseList_C:GetGuidanceCustomPanelType()
  return self.ListType
end

function UMG_SimpleUseList_C:OnBagInfoChange()
  self:UpdateListItemUI()
end

function UMG_SimpleUseList_C:UpdateBagItemNumMagicReplayVideo()
  self:UpdateListItemUI()
end

function UMG_SimpleUseList_C:OnMagicBanStateChanged()
  if self.ListType == ProtoEnum.BagItemType.BI_MAGIC then
    self:UpdateListItemUI()
  end
end

return UMG_SimpleUseList_C
