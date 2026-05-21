local HomeTipsService = Class("HomeTipsService")

function HomeTipsService:Ctor()
  self.GuestEditWarnSeconds = (DataConfigManager:GetHomeGlobalConfig("home_edit_guest_tips_showtime") or {}).num or 10
  self.VisitLockMineHomeLevel = (DataConfigManager:GetHomeGlobalConfig("home_visit_level") or {}).num or 5
end

function HomeTipsService:OnExitHome()
end

function HomeTipsService:ShowEnterHomeZoneTip()
  local TM = NRCModuleManager:GetModule("TipsModule")
  if TM then
    TM:OnShowEnterHomeZoneTip()
  end
  self:CheckAndShowMasterEditNotify()
end

function HomeTipsService:CheckAndShowMasterEditNotify()
  if HomeIndoorSandbox:InOtherHomeIndoor() then
    local allPlayers = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
    if allPlayers then
      for _, Player in pairs(allPlayers) do
        local Uin = Player.serverData.base.logic_id
        if Uin == HomeIndoorSandbox.Server.MasterId and Player:IsServerStatus(ProtoEnum.SpaceActorLogicStatus.SALS_ROOM_EDTING) then
          local Name = Player.serverData.base.name
          local Tips = string.format(LuaText.home_edit_guest_tips, Name)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips, nil, nil, self.GuestEditWarnSeconds)
          return true
        end
      end
    end
  end
end

function HomeTipsService:ShowHomeMasterComingTips(Name)
  local Tips = string.format(LuaText.home_visit_master_onlie_tips, Name)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
end

function HomeTipsService:ShowHomeGuestComingTips(Name)
  local Tips = string.format(LuaText.home_visit_guest_onlie_tips, Name)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
end

function HomeTipsService:ShowHomeMasterLeavingTips(Name)
  local Tips = string.format(LuaText.home_visit_master_off_tips, Name)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
end

function HomeTipsService:ShowHomeGuestLeavingTips(Name)
  local Tips = string.format(LuaText.home_visit_guest_off_tips, Name)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Tips)
end

function HomeTipsService:ShowImportTips(Tips)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Tips, nil, nil, 1, nil, true)
end

function HomeTipsService:ShowAddExpTip(customData)
  local TM = NRCModuleManager:GetModule("TipsModule")
  if TM then
    TM:OnShowAddHomeExpTip(customData)
  end
end

function HomeTipsService:ShowStartExpandTip()
  local TM = NRCModuleManager:GetModule("TipsModule")
  if TM then
    TM:OnShowHomeExpandTip()
  end
end

function HomeTipsService:ShowFinishExpandTip()
  HomeIndoorSandbox.Module:OpenPanel("HomeExpansionFinishTips", function(Panel)
    Panel:Show(true)
  end, true)
end

function HomeTipsService:ShowUnloadPetFurnitureMessageBox()
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO):SetContent(LuaText.furniture_storage_pet_tips1)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function HomeTipsService:ShowUnloadFurnitureGroupMessageBox(OnOkAfterUnload)
  local ContentText = LuaText.furniture_group_storage_tips
  local Ctx = DialogContext()
  Ctx:SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO):SetContent(ContentText):SetCallback(self, function(this, ok)
    if ok and OnOkAfterUnload then
      OnOkAfterUnload()
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function HomeTipsService:ShowUnloadAllFurnitureMessageBox(OnOkAfterUnload)
  local Ctx = DialogContext()
  local ContentText = LuaText.furniture_storage_all_tips
  local EditRoom = HomeIndoorSandbox.HomeEditServ:GetEditRoom()
  if not EditRoom then
    return
  end
  local RoomData = EditRoom:GetRoomData()
  local PropsList = RoomData:GetNoDependencyPropsDataList()
  for i = #PropsList, 1, -1 do
    local PropsData = PropsList[i]
    if PropsData:AnyDynamicNpc() then
      ContentText = string.format([[
%s
%s]], ContentText, LuaText.furniture_storage_pet_tips2)
      break
    end
  end
  Ctx:SetTitle(LuaText.TIPS):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO):SetContent(ContentText):SetCallback(self, function(this, ok)
    if ok and OnOkAfterUnload then
      OnOkAfterUnload()
    end
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function HomeTipsService:ShowUnloadSucceedTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.furniture_storage_succeed)
end

function HomeTipsService:EnterLayoutClearNotify()
  local Ctx = DialogContext()
  Ctx:SetCallback(self, self.OnEditClearedHomeDialog)
  Ctx:SetContent(LuaText.home_contravention_clean_text)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.home_contravention_edit_title)
  Ctx:SetButtonText(_G.LuaText.YES, _G.LuaText.NO)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function HomeTipsService:OnEditClearedHomeDialog(bOk)
  if bOk then
  else
    NRCModuleManager:DoCmd(HomeModuleCmd.ReqLeavePlayerHomeIndoor)
  end
end

function HomeTipsService:UpdateHomePetStatus()
  local tips = LuaText.Error_Code_50400
  if tips then
    local TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
  end
  local homePets = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo)
  if homePets and type(homePets) == "table" and #homePets > 0 then
    for _, pet in ipairs(homePets) do
      if pet.home_pet then
        local PropsData = HomeIndoorSandbox.HomePropsServ:GetPropsDataById(pet.home_pet.home_pet_info.furniture_guid)
        if not PropsData then
          _G.DataModelMgr.PlayerDataModel:UpdatePetInHomeIndoor(pet.home_pet.home_pet_info.pet_gid, false)
        end
      end
    end
  end
end

function HomeTipsService:CheckEnterPublishFailedDuringVisiting(HomeInfo, Reason)
  local bEnterInvalidNotify = not Reason
  if Reason then
    if Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_LAYOUT_CLEAR then
      if HomeIndoorSandbox:InLocalMasterIndoor() then
        if HomeIndoorSandbox.HomeEditServ:InEditMode() then
          HomeIndoorSandbox:LogWarn("Invalid Home, RELOAD_REASON_LAYOUT_CLEAR")
          HomeIndoorSandbox.Module:ClosePanel("Home")
        end
        HomeIndoorSandbox.World:ReloadWorldConditionally(HomeInfo)
        self:EnterLayoutClearNotify()
        self:UpdateHomePetStatus()
      end
      return
    elseif Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_ACCESSIBILITY_CHANGED then
      bEnterInvalidNotify = true
    end
  end
  if bEnterInvalidNotify then
    if HomeIndoorSandbox.Server.WorldData:IsBanned() and Reason == ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_ACCESSIBILITY_CHANGED then
      self:TryProcessHomeBanNotify(HomeIndoorSandbox.Server.WorldData.HomeAccessInfo)
    elseif HomeIndoorSandbox.Server.WorldData:IsViolation() then
      if HomeIndoorSandbox:InLocalMasterIndoor() then
        if HomeIndoorSandbox.HomeEditServ:InEditMode() then
          return
        end
        local Ctx = DialogContext()
        Ctx:SetCallback(self, self.OnEditInvalidHomeDialog)
        Ctx:SetContent(LuaText.home_contravention_edit_text)
        Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
        Ctx:SetTitle(LuaText.home_contravention_edit_title)
        Ctx:SetButtonText(_G.LuaText.YES, _G.LuaText.NO)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
      elseif HomeIndoorSandbox:InOtherHomeIndoor() then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
      end
    end
  end
end

function HomeTipsService:OnEditInvalidHomeDialog(bOk)
  if bOk then
    NRCModuleManager:DoCmd(HomeModuleCmd.OpenHomeMainPanel, true)
  else
    NRCModuleManager:DoCmd(HomeModuleCmd.ReqLeavePlayerHomeIndoor)
  end
end

function HomeTipsService:TryProcessHomeVisitLimits(RetInfo, Rsp)
  if RetInfo then
    if RetInfo.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_MY_HOME_LEVEL_NOT_MATCH then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.home_visit_lock_mine, self.VisitLockMineHomeLevel))
      return true
    elseif self:TryProcessHomeVisitBan(Rsp) then
      return true
    elseif RetInfo.ret_code then
      return self:ConditionalDisplayError(RetInfo)
    end
  end
end

function HomeTipsService:TryProcessHomeVisitBan(rsp)
  if rsp and rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED and rsp.ban_info then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = rsp.ban_info.uin
    if uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
      local ban_time = os.date("%Y-%m-%d %H:%M:%S", rsp.ban_info.ban_time)
      local reasonStr = rsp.ban_info.ban_reason or ""
      local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
      local dialogContext = DialogContext()
      dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true):SetButtonText(_G.LuaText.YES)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      return true
    end
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_HOME_CANNOT_ACCESS then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_contravention_visitor_tips)
    return true
  end
end

function HomeTipsService:TryProcessHomeViolationDuringEditing()
  if HomeIndoorSandbox:InLocalMasterIndoor() and HomeIndoorSandbox.Server.WorldData:IsViolation() then
    local Ctx = DialogContext()
    Ctx:SetCallback(self, self.OnEditInvalidHomeDialog)
    Ctx:SetContent(LuaText.home_contravention_edit_text)
    Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
    Ctx:SetTitle(LuaText.home_contravention_edit_title)
    Ctx:SetButtonText(_G.LuaText.YES, _G.LuaText.NO)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    return true
  end
end

function HomeTipsService:TryProcessHomeBanNotify(AccessInfo)
  local ban_info = AccessInfo and AccessInfo.ban_info
  if ban_info and ban_info.is_banned then
    local banConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
    local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local ban_time = os.date("%Y-%m-%d %H:%M:%S", ban_info.end_time)
    local reasonStr = ban_info.ban_reason or ""
    local contenText = string.format(banConfig.str, uin, ban_time, reasonStr)
    local dialogContext = DialogContext()
    dialogContext:SetTitle(LuaText.TIPS):SetContent(contenText):SetMode(DialogContext.Mode.OK):SetCallback(self, self.OnProcessHomeBanNotifyCallback):SetCloseOnOK(true):SetButtonText(_G.LuaText.YES)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  end
end

function HomeTipsService:OnProcessHomeBanNotifyCallback(bOk)
  if HomeIndoorSandbox:InHomeIndoor() then
    NRCModuleManager:DoCmd(HomeModuleCmd.ReqLeavePlayerHomeIndoor)
  end
end

function HomeTipsService:ConditionalDisplayError(RetInfo)
  local Code = RetInfo and RetInfo.ret_code or 0
  if 50312 == Code then
    local limitHomeLevel = (_G.DataConfigManager:GetHomeGlobalConfig("home_visit_level", false) or {}).num or 5
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.home_visit_lock_mine, limitHomeLevel))
    return true
  elseif Code ~= ProtoEnum.MOBA_RET.ErrorCode.ERR_COMMON_SYS_FUNC_BANNED and Code ~= ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_COMMON_BANNED then
    local Key = "Error_Code_" .. Code
    local LocalizationConf = _G.DataConfigManager:GetLocalizationConf(Key, true)
    if LocalizationConf then
      Log.Debug("[Home] ConditionalDisplayError", Key)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LocalizationConf.msg)
      return true
    end
  end
  return false
end

return HomeTipsService
