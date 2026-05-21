local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_LobbyMainInnerBottomIconListItem_C = Base:Extend("UMG_LobbyMainInnerBottomIconListItem_C")

function UMG_LobbyMainInnerBottomIconListItem_C:OnConstruct()
  self:AddButtonListener(self.Button, self.OnItemSelected)
  self.Button.OnPressed:Add(self, self.UpdateMoreListFocus)
  self.Button.OnReleased:Add(self, self.UpdateMorListFocusFalse)
  self.Button.OnHovered:Add(self, self.ChangeItemState)
  self.Button.OnUnhovered:Add(self, self.RecoveryItemState)
end

function UMG_LobbyMainInnerBottomIconListItem_C:OnDestruct()
end

function UMG_LobbyMainInnerBottomIconListItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self:UpdateUI()
end

function UMG_LobbyMainInnerBottomIconListItem_C:UpdateUI()
  if not self.data then
    return
  end
  if self.data.button_name and self.data.button_name ~= "" then
    self.NRCText_35:SetText(self.data.button_name)
  else
    local Text = string.format("ID\228\184\186 %d \231\154\132 \230\140\137\233\146\174\229\144\141\231\167\176\230\178\161\230\156\137\233\133\141\231\189\174", self.data.id)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    Log.Error(Text)
  end
  if self.data.icon and "" ~= self.data.icon then
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Icon:SetPathWithCallback(self.data.icon, function()
      self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end)
  else
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local Text = string.format("ID\228\184\186 %d \231\154\132 \229\155\190\231\137\135\232\183\175\229\190\132\230\178\161\230\156\137\233\133\141\231\189\174", self.data.id)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    Log.Error(Text)
  end
end

function UMG_LobbyMainInnerBottomIconListItem_C:OnItemSelected(_bSelected)
  self:ReleaseTimer()
  if self.data then
    if self.data.ui then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LobbyMainInnerBottomIconListItem_C:OnItemSelected OpenUI")
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.LobbyMainInnerBottonMoreOpenPanel, self.data.ui)
    elseif self.data.target_url then
      _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_LobbyMainInnerBottomIconListItem_C:OnItemSelected OpenURL")
      self._timer = _G.TimerManager:CreateTimer(self, "UMG_LobbyMainInnerBottomIconListItem_C:OnItemSelected is OpenURL", 0.3, nil, function()
        local url = self.data.target_url
        if not RocoEnv.IS_SHIPPING and self.data.dev_target_url and self.data.dev_target_url ~= "" then
          url = self.data.dev_target_url
        end
        if _G.BinDataUtils.IsPropertyExist(self.data, "add_role_info") and self.data.add_role_info then
          url = self:AddParms(url)
        end
        local screen_type = self.data.screen_type or 1
        self:ReleaseTimer()
        _G.NRCSDKManager:OpenWebView(url, screen_type, false, false)
      end, 1)
    elseif 3 == self.data.id then
      Log.Info("UMG_LobbyMainInnerBottomIconListItem_C:OnItemSelected ")
      _G.NRCSDKManager:ShowGRobot()
    else
      local Text = string.format("ID\228\184\186 %d \231\154\132 \230\140\135\229\174\154UI \229\146\140 target_url \233\131\189\230\178\161\230\156\137\233\133\141\231\189\174 \230\178\161\230\156\137\231\155\184\229\133\179\229\138\159\232\131\189", self.data.id)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      Log.Error(Text)
      return
    end
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUIVisibileBottomIconList, false)
  end
end

function UMG_LobbyMainInnerBottomIconListItem_C:AddParms(Url)
  local strLen = #Url
  local findStr = string.find(Url, "??", strLen - 2, true)
  if nil ~= findStr then
    Url = string.sub(Url, 1, strLen - 2)
    log("change:" .. Url)
    return Url
  end
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  if OnlineModule then
    local onlineModuleData = OnlineModule.data
    if onlineModuleData then
      if onlineModuleData.loginChannelType == Enum.CliLoginChannel.CLC_WX then
        TempAppId = "wxdca9f9a612d43085"
      elseif onlineModuleData.loginChannelType == Enum.CliLoginChannel.CLC_QQ then
        TempAppId = "1110613799"
      end
    end
  end
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local TempRole = ""
  local TempRoleId = ""
  if PlayerInfo then
    TempRole = self:urlEncode(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
    TempRoleId = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  end
  local ParamsTable = {
    gopenid = TempOpenId,
    channelid = UE.ULoginStatics.GetConfigChannel(),
    openid = accountInfo.openid,
    panel_id = 0,
    qi = UE4.ULoginStatics.IsQQInstalled() and 1 or 0,
    wi = UE4.ULoginStatics.IsVxInstalled() and 1 or 0,
    platid = (not RocoEnv.PLATFORM_ANDROID or not "1") and (not RocoEnv.PLATFORM_IOS or not "0") and (not RocoEnv.PLATFORM_WINDOWS or not "2") and RocoEnv.PLATFORM_OPENHARMONY and "12",
    appVersion = _G.App:GetAppVersion() or 1.0
  }
  local UrlParamsStr = ""
  for Key, Value in pairs(ParamsTable) do
    UrlParamsStr = UrlParamsStr .. string.format("&%s=%s", tostring(Key), tostring(Value))
  end
  local CodeUrl = string.format("%s%s", Url, UrlParamsStr)
  return CodeUrl
end

function UMG_LobbyMainInnerBottomIconListItem_C:UpdateMoreListFocus()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.ChangeMoreServiceClickState, true)
end

function UMG_LobbyMainInnerBottomIconListItem_C:UpdateMorListFocusFalse()
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.ChangeMoreServiceClickState, false)
end

function UMG_LobbyMainInnerBottomIconListItem_C:ChangeItemState()
  if self.data then
  end
end

function UMG_LobbyMainInnerBottomIconListItem_C:RecoveryItemState()
  if self.data then
  end
end

function UMG_LobbyMainInnerBottomIconListItem_C:ReleaseTimer()
  if self._timer then
    _G.TimerManager:RemoveTimer(self._timer)
    self._timer = nil
  end
end

function UMG_LobbyMainInnerBottomIconListItem_C:OnDeactive()
  self:ReleaseTimer()
  self:RemoveButtonListener(self.Button, self.OnItemSelected)
  self.Button.OnPressed:Remove(self, self.UpdateMoreListFocus)
  self.Button.OnRelease:Remove(self, self.UpdateMorListFocusFalse)
  self.Button.OnHovered:Remove(self, self.ChangeItemState)
  self.Button.OnUnhovered:Remove(self, self.RecoveryItemState)
end

return UMG_LobbyMainInnerBottomIconListItem_C
