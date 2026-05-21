local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local UMG_Pass_SelectFriend_C = _G.NRCPanelBase:Extend("UMG_Pass_SelectFriend_C")

function UMG_Pass_SelectFriend_C:OnActive()
  self.module = _G.NRCModuleManager:GetModule("BattlePassModule")
  self.moduleData = self.module.data
  self:SetCommonPopUpInfo()
  _G.NRCAudioManager:PlaySound2DAuto(1079, "UMG_Pass_SelectFriend_C:OnActive")
  self:RefreshFriendList()
  self:OnAddEventListener()
  self:PlayOpenAnim()
end

function UMG_Pass_SelectFriend_C:SetCommonPopUpInfo()
  local petName = self.moduleData:GetAnotherThemePetName()
  local titleConf = _G.DataConfigManager:GetLocalizationConf("bp_friend_another_title")
  local titleText
  if titleConf then
    titleText = string.format(titleConf.msg, petName)
  end
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.TitleText = titleText
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClickCloseBtn
  CommonPopUpData.HideBtn = true
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_Pass_SelectFriend_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
end

function UMG_Pass_SelectFriend_C:OnDestruct()
end

function UMG_Pass_SelectFriend_C:OnClickCloseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(1008, "UMG_Pass_SelectFriend_C:OnClickCloseBtn")
  self:PlayCloseAnim()
end

function UMG_Pass_SelectFriend_C:OnPcClose()
  if self.OnPcCloseHandler then
    self.OnPcCloseHandler(self)
  end
end

function UMG_Pass_SelectFriend_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.RefreshAnotherThemeFriendUI, self.OnRefreshAnotherThemeFriendUI)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed, self.OnFriendRelationChanged)
  self.module = nil
  self.moduleData = nil
end

function UMG_Pass_SelectFriend_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_SelectFriend_C", self, BattlePassModuleEvent.RefreshAnotherThemeFriendUI, self.OnRefreshAnotherThemeFriendUI)
  _G.NRCEventCenter:RegisterEvent("UMG_Pass_SelectFriend_C", self, FriendModuleEvent.AddFriendOrRemoveFriendSucceed, self.OnFriendRelationChanged)
end

function UMG_Pass_SelectFriend_C:OnRefreshAnotherThemeFriendUI()
  self:RefreshFriendList()
end

function UMG_Pass_SelectFriend_C:PlayOpenAnim()
  self:LoadAnimation(0)
end

function UMG_Pass_SelectFriend_C:PlayCloseAnim()
  self:LoadAnimation(2)
end

function UMG_Pass_SelectFriend_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Pass_SelectFriend_C:RefreshFriendList()
  if not self.moduleData then
    return
  end
  local friendList = self.moduleData:GetAnotherThemeFriendList()
  if not friendList or 0 == #friendList then
    self.Switcher_73:SetActiveWidgetIndex(1)
  else
    self.Switcher_73:SetActiveWidgetIndex(0)
    self.ItemList_Friend_4:InitList(friendList)
  end
end

function UMG_Pass_SelectFriend_C:OnFriendRelationChanged()
  if not self.moduleData then
    return
  end
  self.moduleData:ResetReqFriendThemeCD()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.ReqGetAnotherThemeFriends, true)
end

return UMG_Pass_SelectFriend_C
