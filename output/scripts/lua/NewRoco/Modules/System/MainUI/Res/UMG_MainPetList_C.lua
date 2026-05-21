local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_MainPetList_C = _G.NRCPanelBase:Extend("UMG_MainPetList_C")

function UMG_MainPetList_C:OnConstruct()
  self.touchScrollSensitivity = 5
  self.pageScrollTime = 0.2
  self.ItemWidth = 217
  self.ItemHeight = 110
  self.PageHeight = self.ScrollBox_65.Slot:GetSize().Y + 19.5
  self:InitPanelInfo(false)
  self.MainPetList:SetItemCanClickChecker(self.CheckItemCanClick, self)
  self.MainPetList:SetItemCanSelectChecker(self.CheckItemCanClick, self)
  self:OnAddEventListener()
end

function UMG_MainPetList_C:CheckItemCanClick(Item, tabIndex)
  local isAmining = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
  if isAmining and Item.uiData and Item.uiData.RecycleState == true then
    return false
  end
  return true
end

function UMG_MainPetList_C:GetCurTeamIndex()
  return self.PageToTeamIndexMap and self.PageToTeamIndexMap[self.curPage]
end

function UMG_MainPetList_C:IsCurMainTeamIndex()
  local teamIndex = self.PageToTeamIndexMap and self.PageToTeamIndexMap[self.curPage]
  local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  return PetTeams.main_team_idx == teamIndex
end

function UMG_MainPetList_C:UpdateThrowPetCanClick(bThrow)
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item and item.uiData and item.uiData.PetData and item.uiData.PetData ~= "nil" then
      item:OpItem(PetUIModuleEnum.MainPetTemplateOpType.updateThrowPetSelect, {bThrow = bThrow})
    end
  end
end

function UMG_MainPetList_C:ForceUpdatePetRiderState()
  local count = self.MainPetList:GetItemCount()
  local RidePetGid
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local RidePet = player.viewObj.BP_RideComponent.ScenePet
    if RidePet then
      RidePetGid = RidePet.gid
    end
  end
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item and item.uiData and item.uiData.PetData and item.uiData.PetData ~= "nil" then
      item:ForceUpdatePetRiderState(RidePetGid)
    end
  end
end

function UMG_MainPetList_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnMainPetRecycleSelect, self.OnPetRecycleSelect)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPet_C", self, MainUIModuleEvent.OnForceUpdateFriendRideState, self.OnForceUpdateFriendRideState)
end

function UMG_MainPetList_C:UpdataRecycleState(Session, Status)
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item and item.uiData and item.uiData.PetData and item.uiData.PetData ~= "nil" and Session.petData.gid == item.uiData.PetData.gid then
      if Status == ThrowSessionStatusEnum.InHand or Status == ThrowSessionStatusEnum.Destroyed then
        item.uiData.RecycleState = false
        if Status == ThrowSessionStatusEnum.Destroyed then
          item.uiData.Session = nil
        end
      else
        item.uiData.Session = Session
        item.uiData.RecycleState = true
      end
      self.MainPetList:OpItemByIndex(i, PetUIModuleEnum.MainPetTemplateOpType.RecycleState)
    end
  end
end

function UMG_MainPetList_C:UpdateFriendRideState(ridingPetGid, IsFriendRiding)
  if nil == ridingPetGid then
    return
  end
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item and item.uiData and item.uiData.PetData and item.uiData.PetData ~= "nil" and ridingPetGid == item.uiData.PetData.gid then
      item:UpdateFriendRideStateShow(IsFriendRiding)
    end
  end
end

function UMG_MainPetList_C:OnForceUpdateFriendRideState()
  local count = self.MainPetList:GetItemCount()
  for i = 1, count do
    local item = self.MainPetList:GetItemByIndex(i - 1)
    if item then
      item:UpdateFriendRideStateShow()
    end
  end
end

function UMG_MainPetList_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainPetRecycleSelect, self.OnPetRecycleSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnForceUpdateFriendRideState, self.OnForceUpdateFriendRideState)
end

function UMG_MainPetList_C:InitPanelInfo(NeedThrowSession, bForceInit, cancelThrow)
  if NeedThrowSession then
    if not self.DelayInitID then
      self.DelayInitID = self:DelayFrames(1, function()
        self:InitPanelInfo(true, true, cancelThrow)
        self.DelayInitID = nil
      end)
      return
    elseif not bForceInit then
      return
    end
  end
  local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  local retPets = {}
  local PageNum = 0
  local curPage = 0
  self.PageToTeamIndexMap = {}
  if PetTeams and PetTeams.teams and #PetTeams.teams > 0 then
    for i, team in ipairs(PetTeams.teams) do
      local gid = PetUtils.PetTeamGetPetGidList(team)
      if gid then
        PageNum = PageNum + 1
        local mainIndex = PetTeams.main_team_idx or 0
        if mainIndex + 1 == i then
          curPage = PageNum
        end
        self.PageToTeamIndexMap[PageNum] = i - 1
        for j = 1, 6 do
          local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid[j])
          if petData then
            table.insert(retPets, petData)
          else
            table.insert(retPets, "nil")
          end
        end
      end
    end
  end
  if cancelThrow then
    self.curPage = curPage
    self.PageNum = PageNum
    self:ScrollToPage(curPage)
    local selectPetIndex = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
    if selectPetIndex and selectPetIndex > 0 then
      local selectIndex = (self.curPage - 1) * 6 + selectPetIndex
      self.MainPetList:SelectItemByIndex(selectIndex - 1)
    end
    return
  end
  local MainPetInfo = {}
  for i = 1, #retPets do
    local _Session = {}
    local _RecycleState = false
    if NeedThrowSession and retPets[i] and "table" == type(retPets[i]) then
      local throwSession = ThrowSession.GetWithGID(retPets[i].gid)
      _Session = throwSession or {}
      if throwSession and not throwSession:IsDestroyed() and not throwSession:IsInHand() then
        _RecycleState = true
      end
    end
    table.insert(MainPetInfo, {
      PetData = retPets[i],
      RecycleState = _RecycleState,
      SelectedState = false,
      IsNewPet = false,
      Session = _Session,
      IsScrollPet = true
    })
  end
  local isPCMode = UE4Helper.IsPCMode()
  if not isPCMode then
    self.NRCSwitcher_33:SetActiveWidgetIndex(0)
  else
    self.PCKey:SetScrollMode()
    self.NRCSwitcher_33:SetActiveWidgetIndex(1)
  end
  self.MainPetList:InitGridView(MainPetInfo)
  if PageNum > 1 then
    self.NRCSwitcher_33:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NRCSwitcher_33:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.curPage = curPage
  self.PageNum = PageNum
  self:ScrollToPage(curPage)
  local selectPetIndex = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  if selectPetIndex and selectPetIndex > 0 then
    local selectIndex = (self.curPage - 1) * 6 + selectPetIndex
    self.MainPetList:SelectItemByIndex(selectIndex - 1)
  end
  self.CanPress = true
end

function UMG_MainPetList_C:SelectPetByIndex()
  local selectPetIndex, petData = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  if selectPetIndex and selectPetIndex > 0 and self:IsCurMainTeamIndex() then
    local selectIndex = (self.curPage - 1) * 6 + selectPetIndex
    local item = self.MainPetList:GetItemByIndex(selectIndex - 1)
    if item and petData and item.uiData and item.uiData.PetData and item.uiData.PetData.gid == petData.gid and not self.MainPetList:IsItemIndexSelected(selectIndex) then
      self.MainPetList:SelectItemByIndex(selectIndex - 1)
    end
  end
end

function UMG_MainPetList_C:OnPetRecycleSelect()
  local selectIndex = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetSelectPetIndex)
  if selectIndex <= 0 then
    return
  end
  local index = (self.curPage - 1) * 6 + selectIndex
  local item = self.MainPetList:GetItemByIndex(index - 1)
  item:StopAllAnimations()
  item:ShowSelected(true)
end

function UMG_MainPetList_C:IsScrollIng()
  return self.scrollingTimeLeft and self.scrollingTimeLeft > 0
end

function UMG_MainPetList_C:OnPCSelectPet0(action_type, index)
  if 0 == action_type then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    if self.CanPress then
      self.CanPress = false
      for i = 1, 6 do
        if index == i then
          local selectIndex = (self.curPage - 1) * 6 + i
          self.MainPetList:SelectItemByIndex(selectIndex - 1)
        end
      end
    end
  else
    self.CanPress = true
  end
end

function UMG_MainPetList_C:ScrollNextPage(wheelData)
  if self.scrollingTimeLeft and self.scrollingTimeLeft > 0 then
    return false
  end
  if -1 == wheelData then
    if self.curPage < self.PageNum then
      self.curPage = self.curPage + 1
    else
      self.curPage = 1
    end
  elseif 1 == wheelData then
    if self.curPage > 1 then
      self.curPage = self.curPage - 1
    else
      self.curPage = self.PageNum
    end
  end
  self:ScrollToPage(self.curPage)
end

function UMG_MainPetList_C:ScrollToPage(_page, _animateTime)
  if _page >= 0 and _page <= self.PageNum then
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetMainUICanCache, false)
    self.curPage = _page
    self.scrollingTimeLeft = _animateTime or self.pageScrollTime
    self.desiredScrollOffset = (self.curPage - 1) * self.PageHeight
    return true
  end
  return false
end

function UMG_MainPetList_C:OnTick(deltaTime)
  if not self.scrollingTimeLeft or self.scrollingTimeLeft <= 0 then
    return
  end
  if deltaTime < self.scrollingTimeLeft then
    local curOffset = self.ScrollBox_65:GetScrollOffset()
    local distOffset = self.desiredScrollOffset - curOffset
    local targetOffset = curOffset + distOffset / self.scrollingTimeLeft * deltaTime
    self.scrollingTimeLeft = self.scrollingTimeLeft - deltaTime
    self.ScrollBox_65:SetScrollOffset(targetOffset)
  else
    self.scrollingTimeLeft = 0
    self.ScrollBox_65:SetScrollOffset(self.desiredScrollOffset)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.RefreshMainUICache)
  end
end

function UMG_MainPetList_C:OnTouchStarted(_MyGeometry, _TouchEvent)
  return self:HandlePressStart(_MyGeometry, _TouchEvent)
end

function UMG_MainPetList_C:HandlePressStart(_MyGeometry, _PointerEvent)
  local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_PointerEvent)
  self.pressPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(_MyGeometry, screenPos)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainPetList_C:OnTouchMoved(_MyGeometry, _MouseEvent)
  return self:HandlePressMove(_MyGeometry, _MouseEvent)
end

function UMG_MainPetList_C:HandlePressMove(_MyGeometry, _PointerEvent)
  if self.scrollingTimeLeft and self.scrollingTimeLeft > 0 then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  if self.pressPos then
    local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_PointerEvent)
    local curPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(_MyGeometry, screenPos)
    local pressMoveOffset = 0
    if self.ScrollBox_65.Orientation == UE4.EOrientation.Orient_Horizontal then
      pressMoveOffset = curPos.X - self.pressPos.X
    else
      pressMoveOffset = curPos.Y - self.pressPos.Y
    end
    if math.abs(pressMoveOffset) > self.touchScrollSensitivity then
      local pageToScroll = pressMoveOffset > 0 and self.curPage - 1 or self.curPage + 1
      if pressMoveOffset > 0 then
        if self.curPage > 1 then
          pageToScroll = self.curPage - 1
        else
          pageToScroll = self.PageNum
        end
      elseif self.curPage < self.PageNum then
        pageToScroll = self.curPage + 1
      else
        pageToScroll = 1
      end
      self:ScrollToPage(pageToScroll)
    end
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainPetList_C:OnTouchEnded(_MyGeometry, _TouchEvent)
  return self:HandlePressEnd(_MyGeometry, _TouchEvent)
end

function UMG_MainPetList_C:HandlePressEnd(_MyGeometry, _PointerEvent)
  if self.scrollingTimeLeft and self.scrollingTimeLeft > 0 then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local prePos = self.pressPos
  if prePos then
    local screenPos = UE4.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(_PointerEvent)
    local curPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(_MyGeometry, screenPos)
    if math.abs(curPos.X - prePos.X) <= self.touchScrollSensitivity and math.abs(curPos.Y - prePos.Y) <= self.touchScrollSensitivity then
      local AllRow = curPos.Y
      local clickRow = math.floor(AllRow / self.ItemHeight)
      if AllRow < 101.5 then
        clickRow = 0
      elseif AllRow < 655 and AllRow > 553.5 then
        clickRow = 5
      end
      local index = (self.curPage - 1) * 6 + clickRow
      local item = self.MainPetList:GetItemByIndex(index)
      if self:IsCurMainTeamIndex() and item and item.clickable then
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, clickRow + 1)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, clickRow + 1)
      end
      self.MainPetList:SelectItemByIndex(index)
    else
      Log.InfoFormat("UMG_ScrollPageController_C: curPos=(%s,%s), pressPos=(%s,%s)", tostring(curPos.X), tostring(curPos.Y), tostring(prePos.X), tostring(prePos.Y))
    end
  end
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainPetList_C:OnDeactive()
end

return UMG_MainPetList_C
