local EventDispatcher = require("Common.EventDispatcher")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local RankDataHandler = {}
local RankDataEventDispatcher

function RankDataEventDispatcher(handler, event, ...)
  if handler then
    if handler[event] then
      handler[event](...)
    end
    if handler.NextHandler then
      RankDataEventDispatcher(handler.NextHandler, event, ...)
    end
  end
end

local function FormatRankboardKey(key)
  return string.format("%d_%d", key.rank_type, key.rank_id)
end

local RankDataPageStatusBit = {Dirty = 2, Refreshing = 4}
local RankDataObject = Class("RankDataObject")

function RankDataObject:Ctor(rankType, rankId, isImage, totalRankNum, pageRankNum)
  assert(rankType and 0 ~= rankType, "rankType is nil or 0")
  assert(rankId and 0 ~= rankId, "rankId is nil or 0")
  assert(totalRankNum and 0 ~= totalRankNum, "totalRankNum is nil or 0")
  pageRankNum = pageRankNum or totalRankNum
  assert(pageRankNum > 0 and pageRankNum <= 100, "pageRankNum is greater than 100")
  EventDispatcher():Attach(self)
  self.key = _G.ProtoMessage.newRankboardKey()
  self.key.rank_type = rankType
  self.key.rank_id = rankId
  self.logTag = FormatRankboardKey(self.key)
  self.isImage = isImage or false
  self.totalRankNum = totalRankNum
  self.pageRankNum = pageRankNum
  self.viewCount = totalRankNum
  self.cacheRankDataPage = {}
  self.cacheUserRankQuery = {}
  self.pagesRefreshingTimestamp = {}
end

function RankDataObject:SetEventHandler(eventHandler)
  self.eventHandler = eventHandler
end

function RankDataObject:GetLogTag()
  return self.logTag
end

function RankDataObject:IsImage()
  return self.isImage
end

function RankDataObject:GetPageRankNum()
  return self.pageRankNum
end

function RankDataObject:GetPageCount()
  return math.ceil(self.totalRankNum / self.pageRankNum)
end

function RankDataObject:GetPlayerRankData(fromRankListFirst)
  if fromRankListFirst then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
    local playerRankDataFromRankList = self:GetUserRankData(playerUin)
    if playerRankDataFromRankList then
      return playerRankDataFromRankList
    end
  end
  return self.playerRankData
end

function RankDataObject:PrefetchPlayerRankData(refresh)
  Log.Debug("[RankData][RankDataObject] PrefetchPlayerRankData:", self:GetLogTag(), refresh)
  if refresh or not self.playerRankData then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
    RankDataHandler.SendZoneGetRankUserReq(self.key, self.isImage, playerUin, self, self.OnSvrRefreshPlayerRankData)
  end
end

function RankDataObject:OnSvrRefreshPlayerRankData(success, key, userId, rankData, viewCount)
  if self.key ~= key then
    return
  end
  Log.Debug("[RankData][RankDataObject] OnSvrRefreshPlayerRankData:", self:GetLogTag(), success, userId, viewCount)
  if success then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    if userId == playerUin then
      self.playerRankData = rankData
      self.viewCount = viewCount or 0
      self:RefreshUserRank(userId, rankData.rank)
      RankDataEventDispatcher(self.eventHandler, "OnPlayerRankDataChanged", self, rankData, false)
    end
  end
end

function RankDataObject:CheckPageRankDataValid(page, pageCount)
  for i = page, page + pageCount - 1 do
    local rankDataPage = self.cacheRankDataPage[i]
    if not rankDataPage or self:CheckPageStatusBit(i, RankDataPageStatusBit.Dirty) then
      return false
    end
  end
  return true
end

function RankDataObject:GetPageRankData(page, pageCount)
  if not (page and not (page <= 0) and pageCount) or pageCount <= 0 then
    return
  end
  pageCount = math.min(pageCount, self:GetPageCount())
  local isValid = self:CheckPageRankDataValid(page, pageCount)
  if not isValid then
    return
  end
  local rankDataList = table.new(pageCount * self.pageRankNum, 0)
  for i = page, page + pageCount - 1 do
    local rankDataPage = self.cacheRankDataPage[i]
    if rankDataPage then
      for _, rankData in ipairs(rankDataPage.rankDataList) do
        table.insert(rankDataList, rankData)
      end
    end
  end
  return rankDataList
end

function RankDataObject:GetUserRankData(userId)
  if not userId then
    return
  end
  for _, rankDataPage in pairs(self.cacheRankDataPage) do
    for _, rankData in ipairs(rankDataPage.rankDataList) do
      if rankData.user_info and rankData.user_info.info_id == userId then
        return rankData
      end
    end
  end
end

function RankDataObject:MarkPageRankDataDirty(page, pageCount)
  Log.Debug("[RankData][RankDataObject] MarkPageRankDataDirty:", self:GetLogTag(), page, pageCount)
  for i = page, page + pageCount - 1 do
    self:SetPageStatusBit(i, RankDataPageStatusBit.Dirty, false)
  end
end

function RankDataObject:PrefetchPageRankData(page, pageCount, refresh)
  Log.Debug("[RankData][RankDataObject] PrefetchPageRankData:", self:GetLogTag(), page, pageCount, refresh)
  if not (page and not (page <= 0) and pageCount) or pageCount <= 0 then
    return false
  end
  pageCount = math.min(pageCount, self:GetPageCount())
  local isValid = self:CheckPageRankDataValid(page, pageCount)
  if refresh or not isValid then
    local refreshPageBegin = page
    local refreshPageEnd = page + pageCount - 1
    local svrTimestamp = ActivityUtils.GetSvrTimestamp()
    for i = refreshPageBegin, refreshPageEnd do
      if self:CanRefreshPage(i, svrTimestamp) then
        break
      end
      refreshPageBegin = i + 1
    end
    for i = refreshPageEnd, refreshPageBegin, -1 do
      if self:CanRefreshPage(i, svrTimestamp) then
        break
      end
      refreshPageEnd = i - 1
    end
    if refreshPageBegin <= refreshPageEnd then
      for i = refreshPageBegin, refreshPageEnd do
        self:SetPageRefreshing(i, svrTimestamp)
      end
      local from = (refreshPageBegin - 1) * self.pageRankNum + 1
      local count = (refreshPageEnd - refreshPageBegin + 1) * self.pageRankNum
      count = math.min(count, self.totalRankNum)
      return RankDataHandler.SendZoneGetRankUserListReq(self.key, self.isImage, from, count, self, self.OnSvrRefreshPageRankData)
    end
  end
end

function RankDataObject:OnSvrRefreshPageRankData(success, key, from, rankDataList, viewCount)
  if self.key ~= key then
    return
  end
  Log.Debug("[RankData][RankDataObject] OnSvrRefreshPageRankData:", self:GetLogTag(), success, from, rankDataList and #rankDataList or 0, viewCount)
  RankDataEventDispatcher(self.eventHandler, "OnSvrRspPageRankData", self, success)
  if not success or not rankDataList then
    return
  end
  self.viewCount = viewCount or 0
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local page = math.floor(from / self.pageRankNum) + 1
  local pageCount = math.ceil(#rankDataList / self.pageRankNum)
  for i = page, page + pageCount - 1 do
    local rankDataPage = self.cacheRankDataPage[i]
    if not rankDataPage then
      rankDataPage = {}
      rankDataPage.rankDataList = {}
      rankDataPage.status = 0
      self.cacheRankDataPage[i] = rankDataPage
    end
    for j = 1, self.pageRankNum do
      local newRankData = rankDataList[(i - page) * self.pageRankNum + j]
      rankDataPage.rankDataList[j] = newRankData
      if newRankData then
        local newRankDataUserId = newRankData.user_info.info_id
        self:RefreshUserRank(newRankDataUserId, newRankData.rank)
        if newRankDataUserId == playerUin then
          self.playerRankData = newRankData
          RankDataEventDispatcher(self.eventHandler, "OnPlayerRankDataChanged", self, newRankData, true)
        end
      end
    end
    self:SetPageStatusBit(i, RankDataPageStatusBit.Dirty | RankDataPageStatusBit.Refreshing, false)
    RankDataEventDispatcher(self.eventHandler, "OnPageRankDataChanged", self, page, rankDataPage.rankDataList)
  end
end

function RankDataObject:PrefetchAllRankData(refresh)
  Log.Debug("[RankData][RankDataObject] PrefetchAllRankData:", self:GetLogTag(), refresh)
  return self:PrefetchPageRankData(1, self:GetPageCount(), refresh)
end

function RankDataObject:MarkAllRankDataDirty()
  Log.Debug("[RankData][RankDataObject] MarkAllRankDataDirty:", self:GetLogTag())
  if not self.isImage and self.viewCount < self.totalRankNum then
    self.viewCount = self.totalRankNum
  end
  self:MarkPageRankDataDirty(1, self:GetPageCount())
end

function RankDataObject:RefreshUserRank(userId, rank)
  local cacheRank = userId and self.cacheUserRankQuery[userId]
  if cacheRank and cacheRank ~= rank then
    self.cacheUserRankQuery[userId] = rank
    local cachePage = math.floor(cacheRank / self.pageRankNum) + 1
    self:SetPageStatusBit(cachePage, RankDataPageStatusBit.Dirty, true)
  end
end

function RankDataObject:SetPageStatusBit(page, statusBit, enable)
  if page and statusBit then
    local rankDataPage = self.cacheRankDataPage[page]
    if rankDataPage then
      local oldStatus = rankDataPage.status
      if enable then
        rankDataPage.status = oldStatus | statusBit
      else
        rankDataPage.status = oldStatus & ~statusBit
      end
      if rankDataPage.status ~= oldStatus then
        RankDataEventDispatcher(self.eventHandler, "OnCachePageStatusChanged", self, page, rankDataPage.status)
      end
    end
  end
end

function RankDataObject:CheckPageStatusBit(page, statusBit)
  if page and statusBit then
    local rankDataPage = self.cacheRankDataPage[page]
    if rankDataPage then
      return 0 ~= rankDataPage.status & statusBit
    end
  end
  return false
end

function RankDataObject:CanRefreshPage(page, svrTimestamp)
  if page then
    if not self:CheckPageStatusBit(page, RankDataPageStatusBit.Refreshing) then
      return true
    end
    if svrTimestamp then
      local lastPageRefreshTimestamp = self.pagesRefreshingTimestamp[page]
      if lastPageRefreshTimestamp then
        return svrTimestamp - lastPageRefreshTimestamp >= 1
      end
    end
  end
  return false
end

function RankDataObject:SetPageRefreshing(page, svrTimestamp)
  if page then
    self.pagesRefreshingTimestamp[page] = svrTimestamp
    self:SetPageStatusBit(page, RankDataPageStatusBit.Refreshing, true)
  end
end

local RankDataController = Class("RankDataController")

function RankDataController:Ctor(scrollPage)
  self.eventHandler = {}
  self.eventHandler.OnPageRankDataChanged = _G.MakeWeakFunctor(self, self.OnPageRankDataChangedHandler)
  self.scrollPage = scrollPage
  self.scrollPageFrom = 1
  self:OnConstruct()
end

function RankDataController:__Dctor()
  self:Free()
end

function RankDataController:SetEventHandler(eventHandler)
  self.eventHandler.NextHandler = eventHandler
end

function RankDataController:BindView(view)
  local preBindView = self.bindView
  if preBindView ~= view then
    self.bindView = view
    self:OnBindViewChanged(preBindView)
    self:InitViewData()
  end
end

function RankDataController:BindRankDataObject(rankDataObject)
  if self.rankDataObject == rankDataObject then
    return
  end
  local preRankDataObject = self.rankDataObject
  if preRankDataObject then
    preRankDataObject:SetEventHandler(nil)
  end
  self.rankDataObject = rankDataObject
  if rankDataObject then
    rankDataObject:SetEventHandler(self.eventHandler)
    local showPage = self.scrollPage or rankDataObject:GetPageCount()
    rankDataObject:PrefetchPageRankData(1, showPage, false)
  end
  self.logTag = rankDataObject and rankDataObject:GetLogTag()
  self:InitViewData()
end

function RankDataController:Free()
  self:BindView(nil)
  self:BindRankDataObject(nil)
end

function RankDataController:GetLogTag()
  return self.logTag
end

function RankDataController:GetRankDataObject()
  return self.rankDataObject
end

function RankDataController:GetViewData(pageFrom)
  local rankDataObject = self.rankDataObject
  if rankDataObject then
    local pageCount = self.scrollPage or self.rankDataObject:GetPageCount()
    return rankDataObject:GetPageRankData(pageFrom, pageCount, false)
  end
end

function RankDataController:InitViewData()
  if UE4.UObject.IsValid(self.bindView) and self.rankDataObject then
    self.scrollPageFrom = 1
    local rankDataList = self:GetViewData(1)
    self:RefreshViewData(rankDataList, true)
    if rankDataList and #rankDataList > 0 then
      self.bindView:SelectItemByIndex(0)
    end
  end
end

function RankDataController:RefreshViewData(rankDataList, initFlag)
  Log.Debug("[RankData][RankDataController] RefreshViewData:", self:GetLogTag(), rankDataList and #rankDataList or 0, initFlag)
  local view = self.bindView
  if UE4.UObject.IsValid(view) then
    if view.InitList then
      view:InitList(rankDataList or {})
    elseif view.InitGridView then
      view:InitGridView(rankDataList or {})
    end
  else
    Log.Debug("[RankData][RankDataController] RefreshViewData view is invalid", self:GetLogTag())
  end
  RankDataEventDispatcher(self.eventHandler, "OnViewDataRefreshed", self, rankDataList and #rankDataList or 0, initFlag)
end

function RankDataController:OnConstruct()
end

function RankDataController:OnBindViewChanged(preBindView)
end

function RankDataController:OnPageRankDataChangedHandler(rankDataObject, page, rankDataList)
  Log.Debug("[RankData][RankDataController] OnPageRankDataChangedHandler:", rankDataObject:GetLogTag(), page, rankDataList and #rankDataList or 0, self.scrollPage)
  if rankDataObject == self.rankDataObject and not self.scrollPage then
    self:RefreshViewData(rankDataList, false)
    local view = self.bindView
    if UE4.UObject.IsValid(view) then
      view:SelectItemByIndex(0)
    end
  end
end

local RankDataController_ScrollPull = RankDataController:Extend("RankDataController_ScrollPull")

function RankDataController_ScrollPull:OnConstruct()
end

function RankDataController_ScrollPull:OnBindViewChanged(preBindView)
  if UE4.UObject.IsValid(preBindView) then
    preBindView.OnUserScrolled:Remove(self, self.OnScroll)
  end
  local view = self.bindView
  if UE4.UObject.IsValid(view) then
    view.OnUserScrolled:Add(self, self.OnScroll)
  end
end

function RankDataController_ScrollPull:OnScroll(offset)
  local scrollView = self.scrollView
  if not UE4.UObject.IsValid(scrollView) then
    return
  end
  local maxOffset = scrollView:GetScrollOffsetOfEndData()
  if 0 == maxOffset or offset >= maxOffset then
  end
  if offset <= 0 then
  end
end

local function OnZoneGetRankUserRsp(rsp, req, callback)
  Log.Dump(rsp, 9, "[RankData] OnZoneGetRankUserRsp")
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if callback then
      callback(true, req.key, req.info_id, rsp.rank_user, rsp.view_count)
    end
  elseif callback then
    callback(false, req.key, req.info_id)
  end
end

local function OnZoneGetRankUserListRsp(rsp, req, callback)
  Log.Dump(rsp, 9, "[RankData] OnZoneGetRankUserListRsp")
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if callback then
      callback(true, req.key, req.from, rsp.rank_user_list, rsp.view_count)
    end
  elseif callback then
    callback(false, req.key, req.from)
  end
end

function RankDataHandler.SendZoneGetRankUserReq(key, isImage, userId, caller, callback, ...)
  if key and userId and 0 ~= userId then
    Log.Debug("[RankData][RankDataHandler] SendZoneGetRankUserReq:", FormatRankboardKey(key), isImage, userId)
    local req = _G.ProtoMessage.newZoneGetRankUserReq()
    req.key = key
    req.is_image = isImage or false
    req.info_id = userId
    local callbackFunctor = callback and _G.MakeWeakFunctor(caller, callback, ...)
    return ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_RANK_USER_REQ, req, nil, OnZoneGetRankUserRsp, callbackFunctor)
  end
end

function RankDataHandler.SendZoneGetRankUserListReq(key, isImage, from, count, caller, callback, ...)
  if key and from and count then
    Log.Debug("[RankData][RankDataHandler] SendZoneGetRankUserListReq:", FormatRankboardKey(key), isImage, from, count)
    if from > 0 and count > 0 then
      local req = _G.ProtoMessage.newZoneGetRankUserListReq()
      req.key = key
      req.is_image = isImage or false
      req.from = from
      req.count = count
      local callbackFunctor = callback and _G.MakeWeakFunctor(caller, callback, ...)
      return ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_RANK_USER_LIST_REQ, req, nil, OnZoneGetRankUserListRsp, callbackFunctor)
    end
  end
end

function RankDataHandler.CreateRankDataObject(rankType, rankId, isImage, totalRankNum, pageRankNum)
  return RankDataObject(rankType, rankId, isImage, totalRankNum, pageRankNum)
end

function RankDataHandler.CreateRankDataController(scrollPage)
  if not scrollPage then
    return RankDataController()
  else
    assert(scrollPage > 0, "scrollPage must be greater than 0")
    return RankDataController_ScrollPull(scrollPage)
  end
end

return RankDataHandler
