local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Sanctuary_TipsItem1_C = Base:Extend("UMG_Sanctuary_TipsItem1_C")

function UMG_Sanctuary_TipsItem1_C:OnConstruct()
  self.playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  self.isSelect = false
  self.isInitRegister = false
  self.VisitItem = {}
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.CloseOwlTips, self.RemoveNpcIcon)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.HideOwlTips, self.RemoveSelect)
end

function UMG_Sanctuary_TipsItem1_C:OnActive()
  self:PlayAnimation(self.List_In)
end

function UMG_Sanctuary_TipsItem1_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
  end
  if self.data then
    _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.UnRegisterSanctuaryChildItem, self.data.conf.id)
  end
end

function UMG_Sanctuary_TipsItem1_C:OnDisable()
end

local deepCopy = function(obj)
  if type(obj) ~= "table" then
    return obj
  end
  local newTable = {}
  for k, v in pairs(obj) do
    newTable[k] = deepCopy(v)
  end
  return newTable
end

function UMG_Sanctuary_TipsItem1_C:OnItemUpdate(_data, datalist, index)
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if _data and #_data > 1 then
    table.sort(_data, function(a, b)
      local indexA = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, a.uin) or 999999
      local indexB = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, b.uin) or 999999
      return indexA < indexB
    end)
  end
  self.data = _data[1]
  for i, v in pairs(_data) do
    self.TextTitle:SetText(_data[1].conf.second_area_name[1])
    table.sort(v.fruits, function(a, b)
      local a_isfruit = a.fruit_id > 0 and 1 or 0
      local b_isfruit = b.fruit_id > 0 and 1 or 0
      if a_isfruit == b_isfruit then
        local a_petid = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OnCmdGetFruitFristPetBaseId, a.fruit_id)
        local b_petid = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OnCmdGetFruitFristPetBaseId, b.fruit_id)
        return a_petid < b_petid
      else
        return a_isfruit > b_isfruit
      end
    end)
    for _, value in pairs(v.fruits) do
      value.contentId = v.contentId
    end
    if v.uin == playerUin then
      self.List:InitGridView(v.fruits)
    else
      for _, fruit in pairs(v.fruits) do
        table.insert(self.VisitItem, fruit)
      end
    end
    if 0 == i % #_data then
      self.List_1:InitGridView(self.VisitItem)
      self.VisitItem = {}
    end
    self:SetIcon(v)
    local playTime = index * 0.025
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DelayId = _G.DelayManager:DelaySeconds(playTime, function()
      if self and UE4.UObject.IsValid(self) then
        self:SetVisibility(UE4.ESlateVisibility.Visible)
        self:PlayAnimation(self.List_In)
      end
    end, self)
    if not self.isInitRegister then
      _G.NRCModeManager:DoCmd(_G.BigMapModuleCmd.UnRegisterSanctuaryChildItem, self.data.conf.id)
    end
  end
end

function UMG_Sanctuary_TipsItem1_C:OpItem(opType, ...)
  if 0 == opType then
    self.Pattern:SetActiveWidgetIndex(opType)
    self.Online:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif 1 == opType then
    self.Pattern:SetActiveWidgetIndex(opType)
    self.Online:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif 2 == opType and self.isSelect then
    self:PlayAnimationReverse(self.Select_In)
    self.isSelect = false
  end
end

function UMG_Sanctuary_TipsItem1_C:SetIcon(data)
  if data.uin ~= self.playerUin then
    return
  end
  local isSingular = 1 == #data.fruits
  local validNum = 0
  local upgrade = data.is_upgrade
  for i, v in pairs(data.fruits) do
    if 0 ~= v.fruit_id then
      validNum = validNum + 1
    end
  end
  if isSingular then
    if not upgrade then
      self.NRCSwitcher_87:SetActiveWidgetIndex(0)
    elseif 0 == validNum then
      self.NRCSwitcher_87:SetActiveWidgetIndex(1)
    else
      self.NRCSwitcher_87:SetActiveWidgetIndex(2)
    end
  elseif not upgrade then
    self.NRCSwitcher_87:SetActiveWidgetIndex(3)
  elseif 0 == validNum then
    self.NRCSwitcher_87:SetActiveWidgetIndex(4)
  elseif 1 == validNum then
    self.NRCSwitcher_87:SetActiveWidgetIndex(5)
  else
    self.NRCSwitcher_87:SetActiveWidgetIndex(6)
  end
end

function UMG_Sanctuary_TipsItem1_C:OnItemSelected(_bSelected)
  if _bSelected then
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    if self.isSelect then
      return
    end
    local curSceneResId = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetCurShowSceneResId)
    if 10003 ~= curSceneResId then
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.ChangeMapScene, 10003)
    end
    self:PlayAnimation(self.Select_In)
    self.isSelect = true
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SwitchSelectItem, self.data.conf.id, true)
    local InFogFlag = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, self.data.conf.id)
    if not InFogFlag then
      local npcInfo = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, self.data.conf.id)
      self.entry_id = npcInfo and npcInfo.entry_id
      _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SetMapCenterByNPC, self.data.conf.id, 0.5, true)
    end
  else
    if not UE4.UObject.IsValid(self) then
      return
    end
    self:RemoveNpcIcon()
    self:PlayAnimationReverse(self.Select_In)
    self.isSelect = false
  end
end

function UMG_Sanctuary_TipsItem1_C:OnSelectAnim()
end

function UMG_Sanctuary_TipsItem1_C:OnUnselectAnim()
end

function UMG_Sanctuary_TipsItem1_C:RemoveSelect()
  if not UE4.UObject.IsValid(self) or not self.isSelect then
    return
  end
  self:PlayAnimationReverse(self.Select_In)
  self.isSelect = false
end

function UMG_Sanctuary_TipsItem1_C:RemoveNpcIcon()
  if self.entry_id then
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OnCmdRemoveNpcIconByNpcId, self.entry_id)
    self.entry_id = nil
  end
end

function UMG_Sanctuary_TipsItem1_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.CloseOwlTips, self.RemoveNpcIcon)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.HideOwlTips, self.RemoveSelect)
end

function UMG_Sanctuary_TipsItem1_C:OnAnimationFinished(anim)
end

return UMG_Sanctuary_TipsItem1_C
