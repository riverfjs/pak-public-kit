local UMG_SeasonIntegrationPanel_C = _G.NRCPanelBase:Extend("UMG_SeasonIntegrationPanel_C")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")
local BattlePassModuleEvent = require("NewRoco.Modules.System.BattlePass.BattlePassModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local aOpenSeasonPVFirstTime = a.sync(function(self)
  self.CanvasPanel_34:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SpineWidget_Common:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCImage_164:SetVisibility(UE4.ESlateVisibility.Visible)
  
  local function asyncPlayPVThunk(callback)
    self:PlaySeasonPV(self, function(_)
      Log.Info("UMG_NRCMedia_C:OnPVOpened")
      _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.SendZoneSetSeasonFirstPopReq, ProtoEnum.SeasonPagePlayType.SPPT_PV)
    end, function(_, bSuccess)
      Log.Info("UMG_NRCMedia_C:OnPVFinished")
      _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.SendZoneSetSeasonFirstPopReq, ProtoEnum.SeasonPagePlayType.SPPT_PV)
    end, function(_)
      Log.Info("UMG_NRCMedia_C:OnPVClosed")
      if callback then
        callback(bSuccess)
      end
    end)
  end
  
  local result = a.wait(a.wrap(asyncPlayPVThunk)())
  Log.Info("UMG_SeasonIntegrationPanel_C:aOpenSeasonPVFirstTime result", result)
  self.CanvasPanel_34:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  a.wait(au.DelaySeconds(0.1))
  if self:CheckShouldPlayPopup() then
    self:ShowSeasonPopup()
  end
  Log.Info("UMG_SeasonIntegrationPanel_C:aOpenSeasonPVFirstTime InitUI")
  self:InitUI()
  self:PlayAnimation(self.In)
  self:PlaySpineAnimation()
  self:PlayLoopAnimation()
  self.NRCImage_164:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self._playPVFirstTimeAsyncContext = nil
  Log.Info("UMG_SeasonIntegrationPanel_C:aOpenSeasonPVFirstTime Finished")
end)

function UMG_SeasonIntegrationPanel_C:OnActive()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnActive")
  self.seasonInfo = table.deepCopy(_G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo))
  if self.seasonInfo == nil then
    Log.Error("UMG_SeasonIntegrationPanel_C:OnActive seasonInfo is nil")
    return
  end
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if nil == seasonConf then
    Log.Error("UMG_SeasonIntegrationPanel_C:OnActive seasonConf is nil season_id = ", self.seasonInfo.season_id)
    return
  end
  if 0 ~= seasonConf.pv_id and self:CheckShouldPlayPV() then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnActive:CheckShouldPlayPV")
    if self._playPVFirstTimeAsyncContext then
      a.kill(self._playPVFirstTimeAsyncContext)
      self._playPVFirstTimeAsyncContext = nil
    end
    self._playPVFirstTimeAsyncContext = au.Launch(aOpenSeasonPVFirstTime(self), function()
    end)
  else
    if self:CheckShouldPlayPopup() then
      Log.Info("UMG_SeasonIntegrationPanel_C:OnActive CheckShouldPlayPopup")
      self:ShowSeasonPopup()
    end
    Log.Info("UMG_SeasonIntegrationPanel_C:OnActive InitUI")
    self:InitUI()
    self:PlayAnimation(self.In)
    self:PlaySpineAnimation()
    self:PlayLoopAnimation()
  end
end

function UMG_SeasonIntegrationPanel_C:CheckShouldPlayPV()
  Log.Info("UMG_SeasonIntegrationPanel_C:CheckShouldPlayPV season_pv_time =", self.seasonInfo.season_pv_time)
  if self.seasonInfo and self.seasonInfo.season_pv_time and self.seasonInfo.season_pv_time > 0 then
    local currentSec = _G.ZoneServer:GetServerTime() / 1000
    if currentSec >= self.seasonInfo.season_pv_time then
      return false
    end
  end
  return true
end

function UMG_SeasonIntegrationPanel_C:CheckShouldPlayPopup()
  Log.Info("UMG_SeasonIntegrationPanel_C:CheckShouldPlayPopup season_pop_windows_time =", self.seasonInfo.season_pop_windows_time)
  if not self.enableView then
    return false
  end
  if self.seasonInfo and self.seasonInfo.season_pop_windows_time and self.seasonInfo.season_pop_windows_time > 0 then
    local currentSec = _G.ZoneServer:GetServerTime() / 1000
    if currentSec >= self.seasonInfo.season_pop_windows_time then
      return false
    end
  end
  return true
end

function UMG_SeasonIntegrationPanel_C:ShowSeasonPopup()
  Log.Info("UMG_SeasonIntegrationPanel_C:ShowSeasonPopup")
  _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonPopup, self.seasonInfo.season_id)
end

function UMG_SeasonIntegrationPanel_C:PlaySeasonPV(caller, mediaOpenCallback, mediaFinishCallback, beginFadeoutCallback)
  Log.Info("UMG_SeasonIntegrationPanel_C:PlaySeasonPV")
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if nil == seasonConf then
    return
  end
  local conf = _G.DataConfigManager:GetMovieConf(seasonConf.pv_id)
  if conf then
    local param = {}
    param.Conf = conf
    param.Caller = caller
    param.MediaOpenCallback = mediaOpenCallback
    param.Callback = mediaFinishCallback
    param.BeginFadeOutCallback = beginFadeoutCallback
    _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.PlayVideo, param)
  end
end

function UMG_SeasonIntegrationPanel_C:OnPVDialogueVideoOpenCallback()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnPVDialogueVideoOpenCallback")
end

function UMG_SeasonIntegrationPanel_C:OnPVDialogueVideoFinishCallback(bSuccess)
  Log.Info("UMG_SeasonIntegrationPanel_C:OnPVDialogueVideoFinishCallback", bSuccess)
end

function UMG_SeasonIntegrationPanel_C:OnTick(deltaTime)
  if self.SpineWidget_Common then
    self.SpineWidget_Common:Tick(deltaTime, false)
  end
end

function UMG_SeasonIntegrationPanel_C:OnDeactive()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnDeactive")
  if self._playPVFirstTimeAsyncContext then
    a.kill(self._playPVFirstTimeAsyncContext)
  end
  self._playPVFirstTimeAsyncContext = nil
end

function UMG_SeasonIntegrationPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseUMG.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.PV.btnLevelUp, self.OnClickVideoBtn)
  self:AddButtonListener(self.Button_Switch, self.OnClickSwitchBtn)
  self:AddButtonListener(self.SeasonTips, self.OnClickSeasonTipsBtn)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnBattlePassInfoUpdate)
end

function UMG_SeasonIntegrationPanel_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.OnSeasonInfoChange)
  _G.NRCEventCenter:UnRegisterEvent(self, BattlePassModuleEvent.UpdateBattlePassInfo, self.OnBattlePassInfoUpdate)
end

function UMG_SeasonIntegrationPanel_C:OnSeasonInfoChange()
  self.bSeasonOver = false
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  if nil == seasonInfo then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnSeasonInfoChange seasonInfo is nil")
    self.bSeasonOver = true
  elseif self.seasonInfo and self.seasonInfo.season_id ~= seasonInfo.season_id then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnSeasonInfoChange oldSeason newSeason", self.seasonInfo.season_id, seasonInfo.season_id)
    self.bSeasonOver = true
  else
    Log.Info("UMG_SeasonIntegrationPanel_C:OnSeasonInfoChange")
    self.seasonInfo = table.deepCopy(_G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo))
  end
  if self.bSeasonOver then
    if self.RedDot_PopUp then
      self.RedDot_PopUp:EraseRedPoint()
    end
    self.Text_TimeTips:SetText(_G.LuaText.season_days_remaining_5)
  end
end

function UMG_SeasonIntegrationPanel_C:OnBattlePassInfoUpdate()
  if self.bpLevelText then
    local BPModule = _G.NRCModuleManager:GetModule("BattlePassModule")
    local BPData = BPModule:GetData("BattlePassModuleData")
    local bpInfo = BPData:GetPlayerBattlePassInfo()
    if bpInfo.exp_info and bpInfo.exp_info.level then
      self.bpLevelText:SetText(bpInfo.exp_info.level)
    end
  end
end

function UMG_SeasonIntegrationPanel_C:OnUnDoFoldCollapsed()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnUnDoFoldCollapsed")
  if not self:CheckShouldPlayPopup() and not self:CheckShouldPlayPV() then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.LookSeasonTaskLetter)
  end
  self:RefreshSlotUI()
end

function UMG_SeasonIntegrationPanel_C:OnConstruct()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnConstruct")
  self:OnAddEventListener()
  self:BindInputAction()
end

function UMG_SeasonIntegrationPanel_C:OnDestruct()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnDestruct")
  self:OnRemoveEventListener()
  local mappingContext = self:GetInputMappingContext("IMC_SeasonIntegration")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseSeason")
    mappingContext:UnBindAction("IA_EscCloseSeason")
  end
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SEASON)
end

function UMG_SeasonIntegrationPanel_C:OnDisable()
  Log.Trace("UMG_SeasonIntegrationPanel_C:OnDisable")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.CloseVideo)
end

function UMG_SeasonIntegrationPanel_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_SeasonIntegration")
  if mappingContext then
    mappingContext:BindAction("IA_CloseSeason", self, "OnPcClose")
    mappingContext:BindAction("IA_EscCloseSeason", self, "OnPcClose")
  end
end

function UMG_SeasonIntegrationPanel_C:PlayLoopAnimation()
  if self.seasonInfo == nil then
    Log.Error("UMG_SeasonIntegrationPanel_C:PlayLoopAnimation seasonInfo is nil")
    return
  end
  if nil == self.seasonInfo.part_info then
    Log.Error("UMG_SeasonIntegrationPanel_C:PlayLoopAnimation seasonInfo.part_info is nil")
    return
  end
  for i = 1, #self.seasonInfo.part_info do
    local slotIndex
    local partConf = _G.DataConfigManager:GetSeasonPartConf(self.seasonInfo.part_info[i].part_id)
    if partConf then
      slotIndex = partConf.slot_position
    end
    if slotIndex then
      local loopAnim = self["Slot_" .. slotIndex .. "_Loop"]
      if loopAnim then
        self:PlayAnimation(loopAnim, 0, 0)
      end
    end
  end
end

function UMG_SeasonIntegrationPanel_C:PlaySpineAnimation()
  self.SpineWidget_Common:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:DelayFrames(1, function()
    self.SpineWidget_Common:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SpineWidget_Common:SetAnimation(0, "idle1", false)
    local duration = self.SpineWidget_Common:GetAnimationDuration("idle1")
    self:DelaySeconds(duration, function()
      self.SpineWidget_Common:SetAnimation(1, "idle2", true)
    end)
  end)
end

function UMG_SeasonIntegrationPanel_C:RefreshSlotUI()
  if self.seasonInfo then
    for i = 1, #self.seasonInfo.part_info do
      self:SetItemInfo(self.seasonInfo.part_info[i])
    end
  end
end

function UMG_SeasonIntegrationPanel_C:InitUI()
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if nil == seasonConf then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008040, "UMG_SeasonIntegrationPanel_C:InitUI")
  local bgm_state = seasonConf and seasonConf.bgm_state or ""
  if "" ~= bgm_state then
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SEASON)
    local isPauseBgm = _G.NRCModeManager:DoCmd(MusicCollectionModuleCmd.IsPauseUiBgm)
    if not isPauseBgm then
      _G.NRCAudioManager:SetStateByName("UI_Music", "UI_Music")
      _G.NRCAudioManager:SetStateByName("UI_Type", bgm_state)
    end
  end
  local seasonName = seasonConf.s_title or LuaText.season_title_text
  self.TitleUMG:Set_MainTitle(seasonName)
  self.TitleUMG:SetBg(seasonConf.s_title_icon)
  self.TitleUMG:SetSubtitle(seasonConf.s_title_subtitle)
  self.Text_Slogan:SetText(seasonConf.season_slogan)
  local endTimeStamp = self.seasonInfo.season_end_time
  local timeDetail = ActivityUtils.ToTimeDetailData(endTimeStamp)
  self.Text_Time:SetText(string.format(_G.LuaText.season_end_time, timeDetail.year, timeDetail.month, timeDetail.day, timeDetail.hour, timeDetail.minute))
  local currentSec = _G.ZoneServer:GetServerTime() / 1000
  local span = endTimeStamp - currentSec
  local day = span // 86400
  local hour = (span - 86400 * day) // 3600
  local minute = (span - 86400 * day - 3600 * hour) // 60
  if day > 0 then
    self.Text_TimeTips:SetText(string.format(_G.LuaText.season_days_remaining, day))
  elseif hour > 0 then
    self.Text_TimeTips:SetText(string.format(_G.LuaText.season_days_remaining_2, hour))
  elseif minute > 0 then
    self.Text_TimeTips:SetText(string.format(_G.LuaText.season_days_remaining_3, minute))
  else
    self.Text_TimeTips:SetText(_G.LuaText.season_days_remaining_4)
  end
  if seasonConf.kv_type == Enum.SeasonKVType.SKVT_COMMON then
    self.Image_KV:SetPath(seasonConf.param_kv_common)
    self.Button_Switch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif seasonConf.kv_type == Enum.SeasonKVType.SKVT_GENDER then
    self:UpdateKVType()
    self.Button_Switch:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if 0 ~= seasonConf.pv_id then
    self.PV:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PV:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local tipsConf = _G.DataConfigManager:GetSeasonTipsTabConf(seasonConf.season_tips_id)
  if tipsConf then
    self.TipsText:SetText(tipsConf.tips_name)
    self.TipsIcon:SetPath(tipsConf.tips_icon)
    self.RedDot_PopUp:SetupKey(415)
  end
  for i = 1, 10 do
    if self["CanvasPanel_Slot_" .. i] then
      self["CanvasPanel_Slot_" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:RefreshSlotUI()
  if not self:CheckShouldPlayPopup() and not self:CheckShouldPlayPV() then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.LookSeasonTaskLetter)
  end
end

function UMG_SeasonIntegrationPanel_C:OnPcClose()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnPcClose")
  if self.bClickedClose then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnPcClose return")
    return
  end
  self.bClickedClose = true
  self:PlayAnimation(self.Out)
end

function UMG_SeasonIntegrationPanel_C:OnClickCloseBtn()
  Log.Info("UMG_SeasonIntegrationPanel_C:OnClickCloseBtn")
  _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_SeasonIntegrationPanel_C:OnClickCloseBtn")
  if self.bClickedClose then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnClickCloseBtn return")
    return
  end
  self.bClickedClose = true
  self:PlayAnimation(self.Out)
end

function UMG_SeasonIntegrationPanel_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoClose()
  end
end

function UMG_SeasonIntegrationPanel_C:OnClickVideoBtn()
  if self.bClickedClose then
    Log.Info("UMG_SeasonIntegrationPanel_C:OnClickVideoBtn return")
    return
  end
  if self.bSeasonOver then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.season_expire_tips)
    return
  end
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if seasonConf and 0 == seasonConf.pv_id then
    Log.Error("UMG_SeasonIntegrationPanel_C:OnClickVideoBtn pv_id is nil")
    return
  end
  self:PlaySeasonPV()
end

function UMG_SeasonIntegrationPanel_C:OnClickSwitchBtn()
  local req = _G.ProtoMessage:newZoneSetSeasonKvTypeReq()
  req.season_id = self.seasonInfo.season_id
  if self.seasonInfo.season_kv_type == Enum.ESexValue.SEX_NOT_SHOW then
    local bIsMale = _G.DataModelMgr.PlayerDataModel:IsMale()
    if bIsMale then
      req.season_kv_type = Enum.ESexValue.SEX_FEMALE
    else
      req.season_kv_type = Enum.ESexValue.SEX_MALE
    end
  elseif self.seasonInfo.season_kv_type == Enum.ESexValue.SEX_MALE then
    req.season_kv_type = Enum.ESexValue.SEX_FEMALE
  else
    req.season_kv_type = Enum.ESexValue.SEX_MALE
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_SEASON_KV_TYPE_REQ, req, self, self.OnSeasonKVTypeRsp, false, false)
end

function UMG_SeasonIntegrationPanel_C:OnSeasonKVTypeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.seasonInfo.season_kv_type = rsp.season_kv_type
    self:UpdateKVType()
  end
end

function UMG_SeasonIntegrationPanel_C:UpdateKVType()
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if nil == seasonConf then
    Log.Error("UMG_SeasonIntegrationPanel_C:UpdateKVType seasonConf is nil season_id = ", self.seasonInfo.season_id)
    return
  end
  if 0 == self.seasonInfo.season_kv_type then
    local bIsMale = _G.DataModelMgr.PlayerDataModel:IsMale()
    if bIsMale then
      self.Image_KV:SetPath(seasonConf.param_kv_male)
    else
      self.Image_KV:SetPath(seasonConf.param_kv_felmale)
    end
  elseif self.seasonInfo.season_kv_type == Enum.ESexValue.SEX_MALE then
    self.Image_KV:SetPath(seasonConf.param_kv_male)
  elseif self.seasonInfo.season_kv_type == Enum.ESexValue.SEX_FEMALE then
    self.Image_KV:SetPath(seasonConf.param_kv_felmale)
  end
end

function UMG_SeasonIntegrationPanel_C:OnClickSeasonTipsBtn()
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if seasonConf then
    self.RedDot_PopUp:EraseRedPoint()
    local tipsID = seasonConf.season_tips_id
    local seasonId = seasonConf and seasonConf.id
    _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPopUp, tipsID, seasonId)
  end
end

function UMG_SeasonIntegrationPanel_C:SetItemInfo(partInfo)
  local slot, redId, itemId
  local partConf = _G.DataConfigManager:GetSeasonPartConf(partInfo.part_id)
  if partConf then
    slot = partConf.slot_position
    redId = partInfo.red_point_id
    itemId = partInfo.item_id
  else
    Log.Error("UMG_SeasonIntegrationPanel_C:SetItemInfo partConf is nil part_id = ", partInfo.part_id)
  end
  if nil == slot then
    Log.Error("UMG_SeasonIntegrationPanel_C:SetItemInfo slot is nil part_id = ", partInfo.part_id)
    return
  end
  local itemConf = _G.DataConfigManager:GetSeasonItemConf(itemId)
  if nil == itemConf then
    Log.Error("UMG_SeasonIntegrationPanel_C:SetItemInfo itemConf is nil itemId = ", itemId)
    return
  end
  self["CanvasPanel_Slot_" .. slot]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self["NRCText_" .. slot] then
    self["NRCText_" .. slot]:SetText(itemConf.item_name)
  end
  local bUnlock = true
  if itemConf.lock_flag then
    for i = 1, #itemConf.lock_flag do
      if not _G.DataModelMgr.PlayerDataModel:HasStoryFlag(itemConf.lock_flag[i]) then
        bUnlock = false
        break
      end
    end
  end
  local bOpen = false
  local timeStr = ""
  if itemConf.time_show_type == Enum.ActivitySeasonTimeShow.ASTS_NONE then
    bOpen = true
    timeStr = ""
  elseif itemConf.time_show_type == Enum.ActivitySeasonTimeShow.ASTS_FIND_END_TIME then
    local activityConf = _G.DataConfigManager:GetActivityConf(tonumber(itemConf.param2))
    if activityConf then
      local startTime = ActivityUtils.ToTimestamp(activityConf.appear_time)
      local endTime = ActivityUtils.ToTimestamp(activityConf.disappear_time)
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      if startTime <= currentTime and endTime > currentTime then
        if "" ~= activityConf.ban_text then
          timeStr = activityConf.ban_text
        else
          timeStr = self:GetTimeStr(startTime, endTime)
        end
        bOpen = true
      else
        timeStr = self:GetTimeStr(startTime, endTime)
      end
    end
  elseif itemConf.time_show_type == Enum.ActivitySeasonTimeShow.ASTS_SETTING_TIME then
    local startTime = ActivityUtils.ToTimestamp(itemConf.time_show_param)
    if not itemConf.time_show_param2 or "" == itemConf.time_show_param2 then
      local endTime = ActivityUtils.ToTimestamp(itemConf.time_show_param2)
      local currentTime = _G.ZoneServer:GetServerTime() / 1000
      if startTime <= currentTime then
        timeStr = ""
        bOpen = true
      else
        timeStr = self:GetTimeStr(startTime, endTime)
        bOpen = false
      end
    else
      local endTime = ActivityUtils.ToTimestamp(itemConf.time_show_param2)
      timeStr, bOpen = self:GetTimeStr(startTime, endTime)
    end
  elseif itemConf.time_show_type == Enum.ActivitySeasonTimeShow.ASTS_SEASON_TASK_NEXT_TIME then
    bOpen = true
    if bUnlock then
      local paragraphIDs = itemConf.time_show_param3
      local bInParagraph = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.FilterParagraphIDListInCurrTask, paragraphIDs)
      if bInParagraph then
        timeStr = ""
      else
        local function IsSeasonParagraph(paragraph_id)
          for i = 1, #paragraphIDs do
            if paragraphIDs[i] == paragraph_id then
              return true
            end
          end
          return false
        end
        
        local latestTaskTimeStamp = 0
        local AllTasks = _G.DataConfigManager:GetAllByName("TASK_CONF")
        for id, taskConf in pairs(AllTasks) do
          if 0 ~= taskConf.paragraph_id and IsSeasonParagraph(taskConf.paragraph_id) then
            local taskObj = _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.getTaskByID, id)
            if not taskObj and taskConf.accept_condition and #taskConf.accept_condition > 0 then
              for i = 1, #taskConf.accept_condition do
                if taskConf.accept_condition[i].type == Enum.TaskAcceptConditionType.TACT_TIME then
                  local taskTimeStamp = ActivityUtils.ToTimestamp(taskConf.accept_condition[i].available_time)
                  if 0 == latestTaskTimeStamp or latestTaskTimeStamp > taskTimeStamp then
                    latestTaskTimeStamp = taskTimeStamp
                  end
                end
              end
            end
          end
        end
        local currentTime = _G.ZoneServer:GetServerTime() / 1000
        if latestTaskTimeStamp - currentTime > 0 then
          local span = latestTaskTimeStamp - currentTime
          local day = span // 86400
          local hour = (span - 86400 * day) // 3600
          local minute = (span - 86400 * day - 3600 * hour) // 60
          if day > 0 then
            timeStr = string.format(_G.LuaText.season_task_time_show, day)
          elseif hour > 0 then
            timeStr = string.format(_G.LuaText.season_task_time_show2, hour)
          elseif minute > 0 then
            timeStr = string.format(_G.LuaText.season_task_time_show3, minute)
          else
            timeStr = string.format(_G.LuaText.season_task_time_show4)
          end
        end
      end
    else
      timeStr = ""
    end
  end
  if "" ~= timeStr then
    self["Text_Time_" .. slot]:SetText(timeStr)
    self["Text_Time_NotOpen_" .. slot]:SetText(timeStr)
    self["WidgetSwitcher_Time_" .. slot]:SetActiveWidgetIndex(bOpen and 1 or 0)
  else
    self["WidgetSwitcher_Time_" .. slot]:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if bOpen then
    if bUnlock then
      if itemConf.textbox and "" ~= itemConf.textbox then
        self["WidgetSwitcher_Icon_" .. slot]:SetActiveWidgetIndex(1)
        self["Image_Icon_" .. slot]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self["Image_Icon_" .. slot]:SetPath(itemConf.textbox)
      else
        self["WidgetSwitcher_Icon_" .. slot]:SetActiveWidgetIndex(2)
      end
    else
      self["WidgetSwitcher_Icon_" .. slot]:SetActiveWidgetIndex(0)
      self["Image_NotOpen_" .. slot]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self["Image_NotOpen_" .. slot]:SetPath(itemConf.textbox_disable)
      self["Text_UnLock_" .. slot]:SetText(itemConf.unlock_tips)
    end
  else
    self["WidgetSwitcher_Icon_" .. slot]:SetActiveWidgetIndex(0)
    self["Image_NotOpen_" .. slot]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self["Image_NotOpen_" .. slot]:SetPath(itemConf.textbox_disable)
    self["Text_UnLock_" .. slot]:SetText("")
  end
  local additionalStr = ""
  if bUnlock and bOpen then
    if itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_NONE then
      additionalStr = ""
    elseif itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_VITEM then
      local vItemNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(tonumber(itemConf.additional_param)) or 0
      additionalStr = tostring(vItemNum)
    elseif itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_TXT then
      additionalStr = itemConf.additional_param
    elseif itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_BP_LEVEL then
      local BPModule = _G.NRCModuleManager:GetModule("BattlePassModule")
      local BPData = BPModule:GetData("BattlePassModuleData")
      local bpInfo = BPData:GetPlayerBattlePassInfo()
      if bpInfo.exp_info and bpInfo.exp_info.level then
        additionalStr = tostring(bpInfo.exp_info.level)
      end
      self.bpLevelText = self["Text_Additional_" .. slot]
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OnCmdGetNewBattlePassInfo)
    elseif itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_DAILY_TASK then
    elseif itemConf.additional_show == Enum.SeasonItemAdditionalShow.SIAS_TALENT then
    end
  end
  self["Text_Additional_" .. slot]:SetText(additionalStr)
  if bUnlock and bOpen then
    if 0 ~= redId then
      if itemConf.jump_type == Enum.ActivitySeasonItemJump.ASIJ_ACTIVITY then
        local activityId = itemConf.jump_param
        local activityInst = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstById, tonumber(activityId))
        if activityInst then
          local extraKeyList = activityInst:GetTabRedPointExtraKeyList()
          self["RedDot_" .. slot]:SetupKey(redId, nil, extraKeyList)
          self["RedDot_" .. slot]:SetRedStatusChangeListener(self, self.OnRedPointSpecialStatusChange, self["RedDot_" .. slot], partInfo)
        end
      else
        self["RedDot_" .. slot]:SetupKey(redId)
        self["RedDot_" .. slot]:SetRedStatusChangeListener(self, self.OnRedPointSpecialStatusChange, self["RedDot_" .. slot], partInfo)
      end
    end
    self:OnRedPointSpecialStatusChange(self["RedDot_" .. slot], partInfo)
  end
  local jumpBtn = self["Button_" .. slot]
  jumpBtn.OnClicked:Add(self, function()
    if self.bClickedClose then
      Log.Info("OnClickedJumpBtn return")
      return
    end
    if self.bSeasonOver then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.season_expire_tips)
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 442, {
        partInfo.part_id,
        partInfo.item_id
      })
      return
    end
    if bUnlock and bOpen then
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SeasonIntegrationPanel_C:SetItemInfo ClickSlot")
      local pressAnim = self["Slot_" .. slot .. "_Press"]
      if pressAnim then
        self:PlayAnimation(pressAnim)
      end
      _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.EraseRedPoint, 442, {
        partInfo.part_id,
        partInfo.item_id
      })
      if itemConf.jump_type == Enum.ActivitySeasonItemJump.ASIJ_TXT_POPTOP then
        local contentText = DialogContext()
        contentText:SetTitle(itemConf.item_name):SetContent(itemConf.jump_param):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.NotBtn)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, contentText)
      elseif itemConf.jump_type == Enum.ActivitySeasonItemJump.ASIJ_SKIP_INSTRUCTION or itemConf.jump_type == Enum.ActivitySeasonItemJump.ASIJ_ACTIVITY then
        _G.NRCModuleManager:DoCmd(itemConf.jump_param, itemConf.param1, itemConf.param2, itemConf.param3)
      elseif itemConf.jump_type == Enum.ActivitySeasonItemJump.ASIJ_WORLD_MAP then
        local bNpcRefreshed = false
        local worldMapIds = string.split(itemConf.jump_param, ";")
        for _, worldMapId in pairs(worldMapIds) do
          local worldMapConf = _G.DataConfigManager:GetWorldMapConf(tonumber(worldMapId))
          if worldMapConf then
            local refreshIds = worldMapConf.npc_refresh_ids
            if refreshIds and #refreshIds > 0 then
              local refresh_content_id = refreshIds[1]
              Log.Info("UMG_SeasonIntegrationPanel_C:SetItemInfo jumpBtn.OnClicked refresh_content_id", refresh_content_id)
              local npcData = _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.GetNpcInfoByRefreshId, refresh_content_id)
              if npcData then
                bNpcRefreshed = true
                local bIsIndoor = false
                local seasonLegendaryID = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetSeasonLegendaryID, refresh_content_id)
                if seasonLegendaryID then
                  local seasonLegendaryDataConf = _G.DataConfigManager:GetSeasonLegendaryBattleEvent(seasonLegendaryID)
                  if seasonLegendaryDataConf then
                    bIsIndoor = seasonLegendaryDataConf.is_indoor
                    Log.Info("UMG_SeasonIntegrationPanel_C:SetItemInfo jumpBtn.OnClicked bIsIndoor", bIsIndoor)
                  end
                end
                if bIsIndoor then
                  do
                    local bBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
                    if not bBan then
                      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.DoCommonTransfer, npcData.entry_id, npcData.worldMapConf)
                      break
                    end
                    Log.Info("UMG_SeasonIntegrationPanel_C:SetItemInfo jumpBtn.OnClicked ASIJ_WORLD_MAP bIsIndoor forbid transfer")
                  end
                  break
                end
                _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, {centerNPCRefreshId = refresh_content_id})
                break
              end
            end
          end
        end
        if not bNpcRefreshed then
          local strTips
          if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
            strTips = LuaText.visitor_state_season_slot_skip_unsuccess_tips
          else
            strTips = itemConf.param1
          end
          if not string.IsNilOrEmpty(strTips) then
            _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, strTips)
          end
        end
      end
    end
  end)
end

function UMG_SeasonIntegrationPanel_C:OnRedPointSpecialStatusChange(redPoint, partInfo)
  local partConf = _G.DataConfigManager:GetSeasonPartConf(partInfo.part_id)
  if partConf then
    local slot = partConf.slot_position
    if redPoint:IsRed() then
      self["ClickRedDot_" .. slot]:SetupKey(0)
    else
      self["ClickRedDot_" .. slot]:SetupKey(442, {
        partInfo.part_id,
        partInfo.item_id
      })
    end
  end
end

function UMG_SeasonIntegrationPanel_C:GetTimeStr(startTime, endTime)
  local function GetTimeSpan(span)
    local day = span // 86400
    
    local hour = (span - 86400 * day) // 3600
    local minute = (span - 86400 * day - 3600 * hour) // 60
    if day > 0 then
      return string.format(_G.LuaText.activity_RTS1, day, hour)
    elseif hour > 0 or minute > 0 then
      return string.format(_G.LuaText.activity_RTS2, hour, minute)
    else
      return _G.LuaText.activity_RTS3
    end
  end
  
  local currentTime = _G.ZoneServer:GetServerTime() / 1000
  if startTime > currentTime then
    local span = GetTimeSpan(startTime - currentTime)
    return string.format(_G.LuaText.season_unlock_time, span)
  elseif startTime <= currentTime and endTime > currentTime then
    local span = GetTimeSpan(endTime - currentTime)
    return string.format(_G.LuaText.season_remaining_time, span), true
  elseif endTime <= currentTime then
    return _G.LuaText.activity_expired_show_tip
  end
end

return UMG_SeasonIntegrationPanel_C
