local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Friend_ApplyFor_Item_C = Base:Extend("UMG_Friend_ApplyFor_Itme_C")

function UMG_Friend_ApplyFor_Item_C:OnConstruct()
end

function UMG_Friend_ApplyFor_Item_C:OnDestruct()
  if self._deleteFriendTimerId then
    _G.DelayManager:CancelDelayById(self._deleteFriendTimerId)
    self._deleteFriendTimerId = nil
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_Friend_ApplyFor_Item_C:OnItemUpdate(_data, datalist, index)
  if self.LockUin and self.LockUin ~= _data.uin then
    self.IsLock = false
  end
  self.data = _data
  self.index = index
  self:SetHeadInfo()
  self:OnAddEventListener()
end

function UMG_Friend_ApplyFor_Item_C:OnAddEventListener()
  self.Btn_Consent.btnLevelUp.OnClicked:Add(self, self.OnClickConsent)
  self.Btn_TurnDown.btnLevelUp.OnClicked:Add(self, self.OnClickTurnDown)
  self.Btn_Remove.btnLevelUp.OnClicked:Add(self, self.OnClickRemove)
end

function UMG_Friend_ApplyFor_Item_C:OnClickConsent()
  if self.IsLock == true then
    return
  end
  self.IsLock = true
  self.LockUin = self.data.uin
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Plane_ExchangeVisits_C:OnActive")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendConfirmAddFriend, self.data.uin, _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.AGREE_REQ)
end

function UMG_Friend_ApplyFor_Item_C:OnClickTurnDown()
  if self.IsLock then
    return
  end
  self.IsLock = true
  self.LockUin = 0
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Plane_ExchangeVisits_C:OnActive")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.FriendConfirmAddFriend, self.data.uin, _G.ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.REFUSE_REQ)
end

function UMG_Friend_ApplyFor_Item_C:OnClickRemove()
  if self.IsLock then
    return
  end
  self.IsLock = true
  self.LockUin = self.data.uin
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_Plane_ExchangeVisits_C:OnActive")
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnEnableOrDisableBlackListOnPopUpOpen, false)
  self:OnDeleteFriendOrAddBlack(self.OnOnAddBlackListCallback)
end

function UMG_Friend_ApplyFor_Item_C:OnDeleteFriendOrAddBlack(Callback)
  if self._deleteFriendTimerId then
    _G.DelayManager:CancelDelayById(self._deleteFriendTimerId)
    self._deleteFriendTimerId = nil
  end
  self._deleteFriendTimerId = _G.DelayManager:DelaySeconds(0.17, function()
    self._deleteFriendTimerId = nil
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local dialogContext = DialogContext()
    local Text = _G.DataConfigManager:GetLocalizationConf("blacklist_delete_content").msg
    local TipsContent = string.format(Text, self.data.name)
    dialogContext:SetTitle(LuaText.TIPS):SetContent(TipsContent):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.YES, LuaText.NO):SetClickAnywhereClose(true):SetCloseOnCancel(true):SetCallback(self, Callback)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end)
end

function UMG_Friend_ApplyFor_Item_C:OnOnAddBlackListCallback(_ok)
  if _ok then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnEnableOrDisableBlackListOnPopUpOpen, false, true)
    _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Plane_ExchangeVisits_C:OnActive")
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddOrRemoveBlackList, self.data.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.REMOVE)
  else
    self.DelayId = _G.DelayManager:DelaySeconds(0.17, function()
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.OnEnableOrDisableBlackListOnPopUpOpen, true)
    end)
    self:SetLock()
  end
end

function UMG_Friend_ApplyFor_Item_C:SetLock()
  self.IsLock = false
end

function UMG_Friend_ApplyFor_Item_C:SetSwitcherState(_IsFriendApply)
  if _IsFriendApply then
    self.Switcher:SetActiveWidgetIndex(0)
  else
    self.Switcher:SetActiveWidgetIndex(1)
  end
  self:SetInfo()
end

function UMG_Friend_ApplyFor_Item_C:SetInfo()
  local data = self.data
  self.Name_1:SetText(data.name)
  if data.online then
    self.State:SetActiveWidgetIndex(0)
  else
    self.State:SetActiveWidgetIndex(1)
    local LastLogoutTime
    if 0 == self.Switcher:GetActiveWidgetIndex() then
      LastLogoutTime = data.req_time
    else
      LastLogoutTime = data.block_time
    end
    local nowTime = math.floor(_G.ZoneServer:GetServerTime() / 1000)
    local TimeDiff = nowTime - LastLogoutTime
    local min = math.floor(TimeDiff / 60)
    local hour = math.floor(min / 60)
    local day = math.floor(hour / 24)
    if day >= 7 then
      self.Offline:SetText(LuaText.umg_friend_applyfor_item_1)
    else
      local Text
      if day < 7 and hour >= 24 then
        Text = string.format(LuaText.umg_friend_applyfor_item_2, day)
      elseif hour < 24 and hour > 0 then
        Text = string.format(LuaText.umg_friend_applyfor_item_3, hour)
      elseif min <= 60 and min >= 0 then
        Text = LuaText.umg_friend_applyfor_item_4
      end
      self.Offline:SetText(Text)
    end
  end
end

function UMG_Friend_ApplyFor_Item_C:SetLabel()
  local Path = "PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Skin/Frames/"
  local CardInfo = self.data.card_info
  if CardInfo and CardInfo.card_appearance_info and CardInfo.card_appearance_info.card_skin_selected then
    local CardIconConf = _G.DataConfigManager:GetCardSkinConf(CardInfo.card_appearance_info.card_skin_selected)
    local LabelPath = string.format("%s%s_png.%s_png'", Path, CardIconConf.skin_resource_path, CardIconConf.skin_resource_path)
    local SkinPath = string.format("%s_1_png", CardIconConf.skin_resource_path)
    SkinPath = string.format("%s%s.%s'", Path, SkinPath, SkinPath)
    Log.Debug(LabelPath, SkinPath, "UMG_Friend_Item_C:SetLabel")
    self.Label:SetPath(LabelPath)
    self.Skin:SetPath(SkinPath)
  end
end

function UMG_Friend_ApplyFor_Item_C:SetHeadInfo()
  local data = self.data
  self.HeadItem:SetInfo(data, self.index)
end

function UMG_Friend_ApplyFor_Item_C:SetParentInfo(_Parent, _ParentSwitcherOffset)
  self.HeadItem:SetParentInfo(_Parent, _ParentSwitcherOffset)
  self.HeadItem:SetItemSize(self.ItemSize.Slot:GetSize())
end

function UMG_Friend_ApplyFor_Item_C:OnItemSelected(_bSelected)
end

function UMG_Friend_ApplyFor_Item_C:OnDeactive()
end

return UMG_Friend_ApplyFor_Item_C
