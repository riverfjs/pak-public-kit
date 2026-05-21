local UMG_OnlineTeammateTagPanel_C = _G.NRCViewBase:Extend("UMG_OnlineTeammateTagPanel_C")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
UMG_OnlineTeammateTagPanel_C.teammateItems = {}

function UMG_OnlineTeammateTagPanel_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_OnlineTeammateTagPanel_C:OnDestruct()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_INFO_NOTIFY)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.VISIT_OWNER_CHANGED, self.OnVisitOwnerChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnRelogin, self.OnRelogin)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.SetOnlineTeammateTagVisible, self.SetOnlineTeammateTagVisible)
  self:ClearAllTeammateItems()
end

function UMG_OnlineTeammateTagPanel_C:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_ONLINE_VISITOR_INFO_NOTIFY, self.OnOnlineVisitorInfoNotify)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.VISIT_OWNER_CHANGED, self.OnVisitOwnerChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_OnlineTeammateTagPanel_C", self, FriendModuleEvent.OnVisitorChanged, self.OnVisitorChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_OnlineTeammateTagPanel_C", self, SceneEvent.OnRelogin, self.OnRelogin)
  _G.NRCEventCenter:RegisterEvent("UMG_OnlineTeammateTagPanel_C", self, MainUIModuleEvent.SetOnlineTeammateTagVisible, self.SetOnlineTeammateTagVisible)
end

function UMG_OnlineTeammateTagPanel_C:OnOnlineVisitorInfoNotify(notify)
  if not notify or not notify.visitor_info then
    return
  end
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local currentTeammates = {}
  for index, visitorInfo in ipairs(notify.visitor_info) do
    if visitorInfo.uin ~= myUin then
      currentTeammates[visitorInfo.uin] = true
      self:UpdateOrCreateTeammateItem(visitorInfo, index)
    end
  end
  self:RemoveNonExistentTeammates(currentTeammates)
end

function UMG_OnlineTeammateTagPanel_C:UpdateOrCreateTeammateItem(visitorInfo, index)
  if not self.teammateItems[visitorInfo.uin] then
    local newItem = UE4.UWidgetBlueprintLibrary.Create(self, self.TeammateTagItem)
    if newItem then
      self.TrackPanel:AddChildToCanvas(newItem)
      self.teammateItems[visitorInfo.uin] = newItem
      newItem:SetTeammateNumber(index)
      newItem:SetTeammateInfo(visitorInfo)
      newItem.Slot:SetZOrder(index)
    end
  else
    local item = self.teammateItems[visitorInfo.uin]
    if item and UE4.UObject.IsValid(item) then
      item:SetTeammateNumber(index)
      item:SetTeammateInfo(visitorInfo)
    end
  end
end

function UMG_OnlineTeammateTagPanel_C:RemoveNonExistentTeammates(currentTeammates)
  for uin, item in pairs(self.teammateItems) do
    if not currentTeammates[uin] then
      self.TrackPanel:RemoveChild(item)
      self.teammateItems[uin] = nil
    end
  end
end

function UMG_OnlineTeammateTagPanel_C:ClearAllTeammateItems()
  for uin, item in pairs(self.teammateItems) do
    self.TrackPanel:RemoveChild(item)
  end
  self.teammateItems = {}
end

function UMG_OnlineTeammateTagPanel_C:OnVisitorChanged(notify)
  if not (notify and notify.visitors) or 0 == #notify.visitors then
    self:ClearAllTeammateItems()
    return
  end
  local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local hasTeammates = false
  for _, visitorInfo in ipairs(notify.visitors) do
    if visitorInfo.uin ~= myUin then
      hasTeammates = true
      break
    end
  end
  if not hasTeammates then
    self:ClearAllTeammateItems()
  end
end

function UMG_OnlineTeammateTagPanel_C:OnVisitOwnerChanged(oldOwner, newOwner)
  self:ClearAllTeammateItems()
end

function UMG_OnlineTeammateTagPanel_C:OnRelogin()
  self:ClearAllTeammateItems()
end

function UMG_OnlineTeammateTagPanel_C:SetOnlineTeammateTagVisible(bVisible)
  Log.Debug("UMG_OnlineTeammateTagPanel_C:SetOnlineTeammateTagVisible", bVisible)
  self.TrackPanel:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

return UMG_OnlineTeammateTagPanel_C
