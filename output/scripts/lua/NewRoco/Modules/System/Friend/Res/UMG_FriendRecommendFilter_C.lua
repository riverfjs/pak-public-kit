local FriendModuleEvent = reload("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UMG_FriendRecommendFilter_C = _G.NRCPanelBase:Extend("UMG_FriendRecommendFilter_C")

function UMG_FriendRecommendFilter_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
  self:OnAddEventListener()
end

function UMG_FriendRecommendFilter_C:GetFriendModuleData()
  return self.module:GetData()
end

function UMG_FriendRecommendFilter_C:OnActive()
  local data = self:GetFriendModuleData()
  local confList = data:GetAllFriendRecommendConfSorted()
  local currentSources = data:GetRecommendFilterSources()
  local selectedMap = {}
  for _, source in ipairs(currentSources) do
    selectedMap[source] = true
  end
  self.FilterMap = {}
  for source, _ in pairs(selectedMap) do
    self.FilterMap[source] = true
  end
  local InfoList = {}
  for i, conf in ipairs(confList) do
    local source = conf.friend_recommend_source
    local itemData = {}
    itemData.index = i
    itemData.text = conf.table_name
    itemData.iconPath = conf.list_icon_path
    itemData.source = source
    itemData.bDisableClickSelect = true
    itemData.OnClick = FPartial(self.OnClickItem, self)
    itemData.bNeedInitSelect = true
    itemData.InitSelected = selectedMap[source] or false
    InfoList[#InfoList + 1] = itemData
  end
  self.SortList:InitGridView(InfoList)
  self:SetCommonPopUpInfo()
  for i = 0, self.SortList:GetItemCount() - 1 do
    local Item = self.SortList:GetItemByIndex(i)
    if Item and Item.data and self.FilterMap[Item.data.source] then
      Item:DoSelect()
    end
  end
  self:RefreshLeftBtnText()
  self:PlayOpenAnim()
end

function UMG_FriendRecommendFilter_C:OnDeactive()
end

function UMG_FriendRecommendFilter_C:OnAddEventListener()
end

function UMG_FriendRecommendFilter_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = LuaText.filter_rule_title
  CommonPopUpData.Btn_LeftText = LuaText.filter_rule_title_cancel
  CommonPopUpData.Btn_RightText = LuaText.filter_rule_title_confirm
  CommonPopUpData.Btn_LeftHandler = self.OnLeftBtnClick
  CommonPopUpData.Btn_RightHandler = self.OnReqConfirm
  CommonPopUpData.ClosePanelHandler = self.OnReqClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp3:SetPanelInfo(CommonPopUpData)
end

function UMG_FriendRecommendFilter_C:OnClickItem(Data, bSelect)
  if not bSelect then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_FriendRecommendFilter_C:OnClickItem")
  local source = Data.source
  local index = Data.index
  local Item = self.SortList:GetItemByIndex(index - 1)
  if not self.FilterMap[source] then
    self.FilterMap[source] = true
    if Item then
      Item:DoSelect()
    end
  else
    self.FilterMap[source] = nil
    if Item then
      Item:DoUnSelect()
    end
  end
  self:RefreshLeftBtnText()
end

function UMG_FriendRecommendFilter_C:OnLeftBtnClick()
  if next(self.FilterMap) then
    self:OnReqReset()
  else
    self:OnReqClose()
  end
end

function UMG_FriendRecommendFilter_C:RefreshLeftBtnText()
  if next(self.FilterMap) then
    self.PopUp3:SetBtnLeftText(LuaText.filter_rule_title_reset)
  else
    self.PopUp3:SetBtnLeftText(LuaText.filter_rule_title_cancel)
  end
end

function UMG_FriendRecommendFilter_C:OnReqReset()
  if not next(self.FilterMap) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_FriendRecommendFilter_C:OnReqReset")
  for i = 0, self.SortList:GetItemCount() - 1 do
    local Item = self.SortList:GetItemByIndex(i)
    if Item and Item.data and self.FilterMap[Item.data.source] then
      Item:DoUnSelect()
    end
  end
  for k, _ in pairs(self.FilterMap) do
    self.FilterMap[k] = nil
  end
  self:RefreshLeftBtnText()
  if self.PopUp3.LastClickTime then
    self.PopUp3.LastClickTime.Btn_Left = nil
  end
end

function UMG_FriendRecommendFilter_C:OnReqConfirm()
  local data = self:GetFriendModuleData()
  if data then
    local sources = {}
    for source, _ in pairs(self.FilterMap) do
      sources[#sources + 1] = source
    end
    data:SetRecommendFilterSources(sources)
    self:DispatchEvent(FriendModuleEvent.OnRecommendFilterConfirmed)
  end
  self:OnReqClose()
end

function UMG_FriendRecommendFilter_C:OnReqClose()
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_FriendRecommendFilter_C:OnReqClose")
  self:PlayCloseAnim()
end

function UMG_FriendRecommendFilter_C:OnAnimationFinished(aim)
  if aim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif aim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_FriendRecommendFilter_C:PlayOpenAnim()
  self:LoadAnimation(0)
end

function UMG_FriendRecommendFilter_C:PlayCloseAnim()
  self:LoadAnimation(2)
end

return UMG_FriendRecommendFilter_C
