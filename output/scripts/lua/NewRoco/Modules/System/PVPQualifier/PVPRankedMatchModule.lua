local PVPRankedMatchModule = NRCModuleBase:Extend("PVPRankedMatchModule")
local PVPRankedMatchModuleEvent = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PVPRankedMatchModuleEnum = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleEnum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local UMG_PVP_Cutto_C = require("NewRoco.Modules.System.PVPQualifier.Res.UMG_PVP_Cutto_C")

function PVPRankedMatchModule:OnConstruct()
  _G.PVPRankedMatchModuleCmd = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleCmd")
  self.data = self:SetData("PVPRankedMatchModuleData", "NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleData")
  self.__debugSeasonOpenStarNum = 0
  self.__debugSeasonOpenPrevStarNum = 0
end

function PVPRankedMatchModule:OnActive()
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPRankedMatch, self.OnCmdOpenPVPQualifier)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CheckHasPVPRankedMatch, self.OnCmdCheckHasPVPQualifier)
  self:RegisterCmd(PVPRankedMatchModuleCmd.ShowUmgPVPQualifier, self.OnCmdShowUmgPVPQualifier)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdHideUmgPVPQualifier, self.OnCmdHideUmgPVPQualifier)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdTryReshowUmgPVPQualifier, self.OnCmdTryReshowUmgPVPQualifier)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPDailyChallenge, self.OnCmdOpenPVPDailyChallenge)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPFirstReward, self.OnCmdOpenPVPFirstReward)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPHistoricalRecord, self.OnCmdOpenPVPHistoricalRecord)
  self:RegisterCmd(PVPRankedMatchModuleCmd.TryOpenPVPHistoricalRecord, self.OnCmdTryOpenPVPHistoricalRecord)
  self:RegisterCmd(PVPRankedMatchModuleCmd.TryOpenPVPRankedMatch, self.OnCmdTryOpenPVPRankedMatch)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdTrySwitch_UMG_SeasonOpen, self.CmdTrySwitch_UMG_SeasonOpen)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdPlaySeasonOpen, self.CmdPlaySeasonOpen)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdTrySwitch_UMG_SeasonRank, self.CmdTrySwitch_UMG_SeasonRank)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPCutto, self.OnCmdOpenPVPCutto)
  self:RegisterCmd(PVPRankedMatchModuleCmd.ClosePVPCutto, self.OnCmdClosePVPCutto)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdGetRankGrade, self.OnCmdGetRankGrade)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendZonePvpHisQueryReq, self.OnCmdZonePvpHisQueryReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdResetTrialPetDataReq, self.OnCmdResetTrialPetDataReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendZonePvpInfoQueryReq, self.OnCmdZonePvpInfoQueryReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendZoneSceneMatchStartReq, self.OnCmdZoneSceneMatchStartReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendZoneGetPvpRankWeekTaskRewardReq, self.OnCmdZoneGetPvpRankWeekTaskRewardReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendZoneGetPvpRankSeasonRewardReq, self.OnCmdZoneGetPvpRankSeasonRewardReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.TransferToRankMatchTutor, self.OnCmdTransferToRankMatchTutor)
  self:RegisterCmd(PVPRankedMatchModuleCmd.RankMatchRecoverCamera, self.OnCmdRankMatchRecoverCamera)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OpenPVPCongratulation, self.OnCmdOpenPVPCongratulation)
  self:RegisterCmd(PVPRankedMatchModuleCmd.ClosePVPCongratulation, self.OnCmdOClosePVPCongratulation)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdClosePVPQualifierCondition, self.OnCmdClosePVPQualifierCondition)
  self:RegisterCmd(PVPRankedMatchModuleCmd.SendPVPSeasonRecordQueryReq, self.OnCmdZonePVPSeasonInfoQueryReq)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurSeasonId, self.OnCmdGetCurSeasonId)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurSeasonStep, self.OnCmdGetCurSeasonStep)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurStepFinishTime, self.OnCmdGetCurStepFinishTime)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurPvpRankStar, self.OnCmdGetCurPvpRankStar)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurPvpRankOrder, self.OnCmdGetCurPvpRankOrder)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurStarReward, self.OnCmdGetCurStarReward)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurWeekReward, self.OnCmdGetCurWeekReward)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurWeekRefreshTime, self.OnCmdGetCurWeekRefreshTime)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetCurWeekWinCount, self.OnCmdGetCurWeekWinCount)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetMaxRankStar, self.OnCmdGetMaxRankStar)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetTrialPetBriefRefreshTime, self.OnCmdGetTrialPetBriefRefreshTime)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetTrialPets, self.OnCmdGetTrialPets)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdIsTrailPet, self.OnCmdIsTrailPet)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetTrialPetBrief, self.OnCmdGetTrialPetBrief)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetRandomPets, self.OnCmdGetRandomPets)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdIsRandomPet, self.OnCmdIsRandomPet)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetAnyRandomPetGid, self.OnCmdGetAnyRandomPetGid)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdDistributeGidForRandomPetInPetTeamInfo, self.OnCmdDistributeGidForRandomPetInPetTeamInfo)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdDistributeGidForRandomPetInPetTeam, self.OnCmdDistributeGidForRandomPetInPetTeam)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdDistributeGidForRandomPetInAdjustedAndSharedTeam, self.OnCmdDistributeGidForRandomPetInAdjustedAndSharedTeam)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetRandomPetRewordConf, self.OnCmdGetRandomPetRewordConf)
  self:RegisterCmd(PVPRankedMatchModuleCmd.ShowNpcRankedMatchUiAction, self.OnCmdShowNpcRankedMatchUiAction)
  self:RegisterCmd(PVPRankedMatchModuleCmd.WaitBattleEndShowRankedMatchUi, self.OnCmdWaitBattleEndShowRankedMatchUi)
  self:RegisterCmd(PVPRankedMatchModuleCmd.GetPvPQualifierEnableState, self.GetPvPQualifierEnableState)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfig, self.CmdGetGradingAnimConfig)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, self.CmdGetGradingAnimConfigWhenDanGrading)
  self:RegisterCmd(PVPRankedMatchModuleCmd.CmdGetTopMaster, self.CmdGetTopMaster)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdIsAlreadyWonToday, self.OnCmdIsAlreadyWonToday)
  self:RegisterCmd(PVPRankedMatchModuleCmd.OnCmdIsInWeekendBenefitsPeriod, self.OnCmdIsInWeekendBenefitsPeriod)
  self:RegisterCmd(PVPRankedMatchModuleCmd.ShiningWeekendGetTrialPet, self.ShiningWeekendGetTrialPet)
  self:RegPanel("PVPQualifier", "UMG_PVPQualifier", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, true)
  self:RegPanel("PVPDailyChallenge", "UMG_PVP_DailyChallenge", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true)
  self:RegPanel("PVPFirstReward", "UMG_PVP_FirstReward", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true)
  self:RegPanel("PVPHistoricalRecord", "UMG_PVP_HistoricalRecord", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true)
  self:RegPanel("SeasonOpen", "UMG_SeasonOpen", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING, nil, true)
  self:RegPanel("SeasonRank", "UMG_SeasonRank", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING, nil, true, nil, nil, true)
  self:RegPanel("SeasonRankS2", "UMG_SeasonRank_S2", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING, nil, true, nil, nil, true)
  self:RegPanel("PVPCutto", "UMG_PVP_Cutto", _G.Enum.UILayerType.UI_LAYER_TOP_LOADING, nil, true, nil, nil, true)
  self:RegPanel("PVPCongratulation", "UMG_PVPcongratulation", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true)
  _G.NRCEventCenter:RegisterEvent("PVPRankedMatchModule", self, SceneEvent.LoadMapStart, self.OnChangeScene)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
  self:InitTeamInfoRandomPet()
  self:OnCmdZonePvpInfoQueryReq()
end

function PVPRankedMatchModule:OnChangeScene()
  self:CloseAllPanel()
end

function PVPRankedMatchModule:OnPlayerDataUpdate()
  self:InitTeamInfoRandomPet()
end

function PVPRankedMatchModule:RegPanel(name, path, layer, IsCapture, bCustomDisableRendering, openAnim, closeAnim, disablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/PVPQualifier/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = bCustomDisableRendering or false
  registerData.openAnimName = openAnim
  registerData.closeAnimName = closeAnim
  registerData.enablePcEsc = not disablePcEsc
  self:RegisterPanel(registerData)
end

function PVPRankedMatchModule:OnEnterSceneFinishNtyAckCallBack()
end

function PVPRankedMatchModule:OnCmdShowUmgPVPQualifier()
  local panel = self:GetPanel("PVPQualifier")
  if panel then
    panel:Show()
  end
end

function PVPRankedMatchModule:OnCmdHideUmgPVPQualifier()
  local panel = self:GetPanel("PVPQualifier")
  if panel then
    panel:Hide()
  end
end

function PVPRankedMatchModule:OnCmdTryReshowUmgPVPQualifier()
  local panel = self:GetPanel("PVPQualifier")
  if panel then
    panel:TryReshow()
  end
end

function PVPRankedMatchModule:OnCmdOpenPVPQualifier()
  local resListData = _G.NRCPanelResLoadData()
  resListData.PreLoadResList = {}
  table.insert(resListData.PreLoadResList, UEPath.PVP_SpineAtlasAsset)
  table.insert(resListData.PreLoadResList, UEPath.PVP_SpineSkeletonDataAsset)
  self:OpenPanel("PVPQualifier", resListData)
end

function PVPRankedMatchModule:OnCmdCheckHasPVPQualifier()
  return table.contains(self.moduleLivingPanelLst, "PVPQualifier")
end

function PVPRankedMatchModule:GetZonePvpInfoQueryReq()
  local req = _G.ProtoMessage:newZonePvpInfoQueryReq()
  if not _G.RankMatchTrialPet then
    req.whole_trial_pets = true
  else
    req.whole_trial_pets = false
  end
  return req
end

function PVPRankedMatchModule:OnCmdTryOpenPVPRankedMatch()
  local req = self:GetZonePvpInfoQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_INFO_QUERY_REQ, req, self, self.OnCmdTryOpenPVPRankedMatchRsp)
end

function PVPRankedMatchModule:OnCmdTryOpenPVPRankedMatchRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpInfoQueryData(rsp)
    NRCModeManager:DoCmd(PetUIModuleCmd.OnChangePetTeamsInfoForTeam, rsp)
    self:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:ShiningWeekendGetTrialPet()
  local req = self:GetZonePvpInfoQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_INFO_QUERY_REQ, req, self, self.OnShiningWeekendGetTrialPet)
end

function PVPRankedMatchModule:OnShiningWeekendGetTrialPet(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpInfoQueryData(rsp)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.ShiningWeekendGetTrialPet)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:GetPvPQualifierEnableState()
  if self:HasPanel("PVPQualifier") then
    local panel = self:GetPanel("PVPQualifier")
    return panel.enableView
  end
  return false
end

function PVPRankedMatchModule:CmdGetGradingAnimConfig(starNum)
  local TopMasterInfo = self.data:GetTopMaster()
  local bTopMaster = TopMasterInfo.type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
  return self.data:GetGradingAnimConfig(starNum, bTopMaster, false)
end

function PVPRankedMatchModule:CmdGetGradingAnimConfigWhenDanGrading(starNum)
  local TopMasterInfo = self.data:GetTopMaster()
  local bTopMaster = TopMasterInfo.type == _G.ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_TOP_MASTER
  return self.data:GetGradingAnimConfig(starNum, bTopMaster, true)
end

function PVPRankedMatchModule:CmdGetTopMaster()
  return self.data:GetTopMaster()
end

function PVPRankedMatchModule:OnCmdIsAlreadyWonToday()
  local timestap = self.data:GetDailyFirstWinTime()
  if timestap > 0 then
    local now = os.time()
    local lastWinDate = os.date("*t", timestap)
    local currentDate = os.date("*t", now)
    return lastWinDate.year == currentDate.year and lastWinDate.month == currentDate.month and lastWinDate.day == currentDate.day
  end
  return false
end

function PVPRankedMatchModule:OnCmdIsInWeekendBenefitsPeriod()
  return self.data:GetPvpWeekBenefit()
end

function PVPRankedMatchModule:OnCmdOpenPVPCutto(CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
  Log.Debug("SeasonOpen Progress: OnCmdOpenPVPCutto", CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
  if not self.bOpeningPVPCutto then
    self.bOpeningPVPCutto = true
    if self:HasPanel("PVPCutto") then
      Log.Debug("SeasonOpen Progress: OnCmdOpenPVPCutto:ClosePanel", CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
      self:ClosePanel("PVPCutto")
    end
    Log.Debug("SeasonOpen Progress: OnCmdOpenPVPCutto:OpenPanel", CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
    self:OpenPanel("PVPCutto", CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
    self.bOpeningPVPCutto = false
  else
    local panel = self:GetPanel("PVPCutto")
    if panel and UE4.UObject.IsValid(panel) then
      Log.Debug("SeasonOpen Progress: OnCmdOpenPVPCutto:ReplaceCallBack", CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
      panel:ReplaceCallBack(CallerName, Caller, CallBack, bSkipShowSeaon, bUObjectCaller)
    else
      Log.Debug("SeasonOpen Progress: OnCmdOpenPVPCutto:ReplaceCallBack, SafeDoCallBackImpl! panel is nil or destroyed!!")
      UMG_PVP_Cutto_C.SafeDoCallBackImpl(Caller, CallBack, bUObjectCaller)
    end
  end
end

function PVPRankedMatchModule:OnCmdClosePVPCutto()
  Log.Debug("SeasonOpen Progress: OnCmdClosePVPCutto, self.bClosingPVPCutto", self.bClosingPVPCutto)
  if not self.bClosingPVPCutto then
    self.bClosingPVPCutto = true
    if self:HasPanel("PVPCutto") then
      Log.Debug("SeasonOpen Progress: OnCmdClosePVPCutto:PlayCloseAnim")
      local panel = self:GetPanel("PVPCutto")
      panel:PlayCloseAnim()
    else
      Log.Debug("SeasonOpen Progress: panel(PVPCutto) dose NOT exist!")
    end
    self.bClosingPVPCutto = false
  end
end

function PVPRankedMatchModule:OnCmdGetRankGrade(curStarNum)
  return self.data:GetRankGrade(curStarNum)
end

function PVPRankedMatchModule:DebugSeasonOpen(curSeasonId, starNum, prevNum)
  self.data:DebugSeasonId(curSeasonId)
  self.__debugSeasonOpenStarNum = starNum
  self.__debugSeasonOpenPrevStarNum = prevNum
end

function PVPRankedMatchModule:DebugFirstSeason(bFirst)
  self.__debugFirstSeason = bFirst
end

function PVPRankedMatchModule:DebugNewWeek(bNewWeek)
  self.__debugNewWeek = bNewWeek
end

function PVPRankedMatchModule:DebugTopMaster(p, c, n)
  self.__debugTopMasterPrev = p
  self.__debugTopMasterCur = c
  self.__debugTopMasterNext = n
end

function PVPRankedMatchModule:CmdTrySwitch_UMG_SeasonOpen(bShow)
  if bShow then
    local bNewSeason = self:CheckNewSeasonLocally()
    if (bNewSeason or self.__debugSeasonOpenStarNum > 0) and not self:HasPanel("SeasonOpen") then
      local resListData = _G.NRCPanelResLoadData()
      resListData.PreLoadResList = {}
      table.insert(resListData.PreLoadResList, UEPath.PVP_SpineAtlasAsset)
      table.insert(resListData.PreLoadResList, UEPath.PVP_SpineSkeletonDataAsset)
      local bChanged, oldRank, resetToRank = self:CheckRankStarChanged()
      if bChanged then
        table.insert(resListData.PreLoadResList, "WidgetBlueprint'/Game/NewRoco/Modules/System/PVPQualifier/Res/UMG_SeasonRank.UMG_SeasonRank'")
      end
      self:OpenPanel("SeasonOpen", resListData)
      return true
    end
    return false
  else
    self:ClosePanel("SeasonOpen")
    return true
  end
end

function PVPRankedMatchModule:CmdPlaySeasonOpen()
  local panel = self:GetPanel("SeasonOpen")
  if panel then
    panel:TryPlayVideo()
  else
    Log.Error("SeasonOpen Progress: PVPRankedMatchModule:CmdPlaySeasonOpen(error! panel(SeasonOpen) doesn't exist!!)")
  end
end

function PVPRankedMatchModule:CmdTrySwitch_UMG_SeasonRank(bShow)
  local panelName = self:GetPanelName_SeasonRank()
  if bShow then
    local bChanged, oldRank, resetToRank = self:CheckRankStarChanged()
    if bChanged and not self:HasPanel(panelName) then
      self:OpenPanel(panelName, oldRank, resetToRank)
      return true
    end
    return false
  else
    self:ClosePanel(panelName)
    return true
  end
end

function PVPRankedMatchModule:GetPanelName_SeasonRank()
  local currentSeasonId = self.data:GetCurSeasonId() or 0
  local firstSeasonId = self.data:GetFirstSeasonId() or 0
  if currentSeasonId == firstSeasonId then
    return "SeasonRank"
  else
    return "SeasonRankS2"
  end
end

function PVPRankedMatchModule:CheckNewSeasonLocally()
  local step = self.data:GetCurSeasonStep()
  local seasonId = self.data:GetCurSeasonId()
  if seasonId and step ~= ProtoEnum.PVP_RANK_STEP.STEP_IDLE then
    local kLastShowSeasonId = "LastShowSeasonId"
    local lastSeasonId = self.data:GetTimestamp(kLastShowSeasonId)
    if seasonId and seasonId > lastSeasonId then
      self.data:SetTimestamp(kLastShowSeasonId, seasonId)
      return true
    end
  end
  return false
end

function PVPRankedMatchModule:CheckNewWeekLocally(bNeedSave)
  if self.__debugNewWeek then
    return true
  end
  local now = os.time()
  local date = os.date("*t", now)
  local currentDay = date.wday
  local offset = (currentDay - 5) % 7
  local lastThursday = now - offset * 24 * 60 * 60
  local thursdayDate = os.date("*t", lastThursday)
  local thursdayTimestamp = os.time({
    year = thursdayDate.year,
    month = thursdayDate.month,
    day = thursdayDate.day,
    hour = 4,
    min = 0,
    sec = 0
  })
  local kTimeStampName = "TimestampForLastShowTopMaster"
  local last = self.data:GetTimestamp(kTimeStampName)
  if thursdayTimestamp < last then
    return false
  else
    if bNeedSave then
      self.data:SetTimestamp(kTimeStampName, now)
    end
    return true
  end
end

function PVPRankedMatchModule:CheckRankStarChanged()
  local oldRank = self.data:GetPrevSeasonRankStar()
  local oldRankConf = _G.DataConfigManager:GetPvpRankConf(oldRank, true)
  if oldRankConf then
    local resetToRank = oldRankConf.reset
    if oldRank ~= resetToRank then
      return true, oldRank, resetToRank
    end
  end
  return false
end

function PVPRankedMatchModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnPlayerDataUpdate)
end

function PVPRankedMatchModule:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnChangeScene)
  self.data:OnDestruct()
end

function PVPRankedMatchModule:OnCmdTryOpenPVPHistoricalRecord()
  self.isTryOpenPVPHistoricalRecord = true
  local req = _G.ProtoMessage:newZonePvpHisQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_HIS_QUERY_REQ, req, self, self.OnCmdTryZonePvpHisQueryRsp)
end

function PVPRankedMatchModule:OnCmdTryZonePvpHisQueryRsp(rsp)
  self.isTryOpenPVPHistoricalRecord = nil
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpHisQueryData(rsp)
    self:OpenPanel("PVPHistoricalRecord")
  else
    rsp.his = {}
    rsp.win_count = 0
    rsp.lose_count = 0
    self.data:SetPvpHisQueryData(rsp)
    self:OpenPanel("PVPHistoricalRecord")
  end
end

function PVPRankedMatchModule:OnCmdOpenPVPFirstReward()
  self:OpenPanel("PVPFirstReward")
end

function PVPRankedMatchModule:OnCmdOpenPVPHistoricalRecord()
  self:OpenPanel("PVPHistoricalRecord")
end

function PVPRankedMatchModule:OnCmdOpenPVPDailyChallenge()
  local WeekReward = self.data:GetCurWeekReward()
  if WeekReward then
    self:OpenPanel("PVPDailyChallenge")
  else
    local req = self:GetZonePvpInfoQueryReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_INFO_QUERY_REQ, req, self, self.OnCmdOpenPVPDailyChallengeRsp)
  end
end

function PVPRankedMatchModule:OnCmdOpenPVPDailyChallengeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpInfoQueryData(rsp)
    NRCModeManager:DoCmd(PetUIModuleCmd.OnChangePetTeamsInfoForTeam, rsp)
    self:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
    self:OpenPanel("PVPDailyChallenge")
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZonePvpHisQueryReq()
  local req = _G.ProtoMessage:newZonePvpHisQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_HIS_QUERY_REQ, req, self, self.OnCmdZonePvpHisQueryRsp)
end

function PVPRankedMatchModule:OnCmdZonePvpHisQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpHisQueryData(rsp)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function PVPRankedMatchModule:OnCmdResetTrialPetDataReq()
  local req = self:GetZonePvpInfoQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_INFO_QUERY_REQ, req, self, self.OnCmdResetTrialPetDataRsp)
end

function PVPRankedMatchModule:OnCmdResetTrialPetDataRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpInfoQueryData(rsp)
    NRCModeManager:DoCmd(PetUIModuleCmd.OnChangePetTeamsInfoForTeam, rsp)
    self:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData, true)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData, true)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZonePvpInfoQueryReq()
  local req = self:GetZonePvpInfoQueryReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_PVP_INFO_QUERY_REQ, req, self, self.OnCmdZonePvpInfoQueryRsp)
end

function PVPRankedMatchModule:OnCmdZonePvpInfoQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:SetPvpInfoQueryData(rsp)
    NRCModeManager:DoCmd(PetUIModuleCmd.OnChangePetTeamsInfoForTeam, rsp)
    self:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpInfoQueryData)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZoneSceneMatchStartReq(PvpId)
  Log.Debug("PVPRankedMatchModule \229\143\145\233\128\129\229\140\185\233\133\141\229\141\143\232\174\174")
  local req = _G.ProtoMessage:newZoneSceneMatchStartReq()
  req.pvp_id = PvpId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MATCH_START_REQ, req, self, self.OnCmdZoneSceneMatchStartRsp, true)
end

function PVPRankedMatchModule:OnCmdZoneSceneMatchStartRsp(rsp)
  Log.Debug("PVPRankedMatchModule \229\188\128\229\167\139\229\140\185\233\133\141 ret_code=", rsp.ret_info.ret_code)
  if 0 == rsp.ret_info.ret_code then
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZoneGetPvpRankWeekTaskRewardReq(Reward)
  local req = _G.ProtoMessage:newZoneGetPvpRankWeekTaskRewardReq()
  table.insert(req.id, Reward.id)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PVP_RANK_WEEK_TASK_REWARD_REQ, req, self, self.OnCmdZoneGetPvpRankWeekTaskRewardRsp, true)
end

function PVPRankedMatchModule:OnCmdZoneGetPvpRankWeekTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:UpdateOneWeekReward(rsp.reward)
    local rewardMap = {}
    for _, item in pairs(rsp.reward) do
      rewardMap[item.id] = item
    end
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.UpdateWeekReward, rewardMap)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZoneGetPvpRankSeasonRewardReq(RewardId)
  local req = _G.ProtoMessage:newZoneGetPvpRankSeasonRewardReq()
  self.dataList = self.data:GetCurStarReward()
  local rewardTable = {}
  for _, reward in pairs(self.dataList) do
    if reward.available and not reward.received then
      table.insert(rewardTable, reward.id)
    end
  end
  req.rank_star = rewardTable
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_PVP_RANK_SEASON_REWARD_REQ, req, self, self.OnCmdZoneGetPvpRankSeasonRewardRsp, true)
end

function PVPRankedMatchModule:OnCmdZoneGetPvpRankSeasonRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.reward then
      self.data:UpdateStarReward(rsp.reward)
    end
    local curList = self.data:GetCurStarReward()
    local rewardMap = {}
    for _, item in pairs(curList) do
      rewardMap[item.id] = item
    end
    self:DispatchEvent(PVPRankedMatchModuleEvent.UpdateSeasonStarReward, rewardMap)
    _G.NRCEventCenter:DispatchEvent(PVPRankedMatchModuleEvent.UpdateSeasonStarReward, rewardMap)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:OnCmdZonePVPSeasonInfoQueryReq(season_id)
  local req = _G.ProtoMessage:newZoneQueryPvpRankSeasonInfoReq()
  req.season_id = season_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PVP_RANK_SEASON_INFO_REQ, req, self, self.OnCmdZonePVPSeasonInfoQueryRsp)
end

function PVPRankedMatchModule:OnCmdZonePVPSeasonInfoQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:DispatchEvent(PVPRankedMatchModuleEvent.SetPvpSeasonRecordData, rsp.rank_season_info)
  else
    self:ErrorTips(rsp.ret_info.ret_code)
  end
end

function PVPRankedMatchModule:ErrorTips(retCode)
  local Desc = LuaText:GetErrorDesc(retCode)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Desc)
end

function PVPRankedMatchModule:OnCmdGetCurSeasonId()
  return self.data:GetCurSeasonId()
end

function PVPRankedMatchModule:OnCmdGetCurSeasonStep()
  return self.data:GetCurSeasonStep()
end

function PVPRankedMatchModule:OnCmdGetCurStepFinishTime()
  return self.data:GetCurStepFinishTime()
end

function PVPRankedMatchModule:OnCmdGetCurPvpRankStar()
  return self.data:GetCurPvpRankStar()
end

function PVPRankedMatchModule:OnCmdGetCurPvpRankOrder()
  return self.data:GetCurPvpRankOrder()
end

function PVPRankedMatchModule:OnCmdGetCurStarReward()
  return self.data:GetCurStarReward()
end

function PVPRankedMatchModule:OnCmdGetCurWeekReward()
  return self.data:GetCurWeekReward()
end

function PVPRankedMatchModule:OnCmdGetCurWeekRefreshTime()
  return self.data:GetCurWeekRefreshTime()
end

function PVPRankedMatchModule:OnCmdGetCurWeekWinCount()
  return self.data:GetCurWeekWinCount()
end

function PVPRankedMatchModule:OnCmdGetMaxRankStar()
  return self.data:GetMaxRankStar()
end

function PVPRankedMatchModule:OnCmdGetTrialPetBriefRefreshTime()
  return self.data:GetTrialPetBriefRefreshTime()
end

function PVPRankedMatchModule:OnCmdTransferToRankMatchTutor()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    return
  end
  local infos = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_npc_position").numList
  local action = {
    to_pt = {
      pos = {
        x = 431677.09375,
        y = 685770.25,
        z = 7516.114746
      }
    }
  }
  action.to_pt.pos.x = tonumber(infos[2])
  action.to_pt.pos.y = tonumber(infos[3])
  action.to_pt.pos.z = tonumber(infos[4])
  local pos = UE4.FVector(infos[2], infos[3], infos[4])
  Player:SetActorLocation(pos)
  local targetRotation = UE4.FRotator(0, 180, 0)
  Player:SetActorRotation(targetRotation)
  Player:GetUEController():ResetCamera()
end

function PVPRankedMatchModule:OnCmdRankMatchRecoverCamera()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player:GetUEController():ResetCamera()
  player:GetUEController():ReleaseRocoCamera(1)
end

function PVPRankedMatchModule:RankMatchRecoverCameraSkillLoaded(resRequest, skillAsset)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.skillClass = skillAsset
  local myPlayer = _G.BattleUtils.GetPlayerModel()
  self.skillComponent = myPlayer.RocoSkill
  self.skillComponent:ClearAllPassiveSkillObjs()
  self.skill = self.skillComponent:FindOrAddSkillObj(self.skillClass)
  self.skill:SetCaster(player.viewObj)
  self.skill:SetPassive(true)
  self.skillComponent:PlaySkill(self.skill)
end

function PVPRankedMatchModule:OnCmdShowNpcRankedMatchUiAction()
  Log.Debug("SeasonOpen Progress: PVPRankedMatchModule:OnCmdShowNpcRankedMatchUiAction")
  self.easyAction = reload("NewRoco.Modules.Core.NPC.Actions.NPCActionOpenPVPRankedMatchUI")
  self.easyAction:SetNoNpc(self, self.ClearEasyAction)
  self.easyAction:ExecuteWithModel()
end

function PVPRankedMatchModule:OnCmdWaitBattleEndShowRankedMatchUi()
  Log.Debug("SeasonOpen Progress: PVPRankedMatchModule:OpenPVPCuttoCallBack")
  _G.NRCEventCenter:RegisterEvent("PVPRankedMatchModule", self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnBattleRealEnd)
end

function PVPRankedMatchModule:OnBattleRealEnd()
  Log.Debug("SeasonOpen Progress: PVPRankedMatchModule:OnBattleRealEnd")
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnBattleRealEnd)
  self:OnCmdShowNpcRankedMatchUiAction()
end

function PVPRankedMatchModule:OnCmdClosePVPQualifierCondition()
  if self.isTryOpenPVPHistoricalRecord then
    return false
  end
  local flag = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CheckIsAnyUmgIsOpening)
  if flag then
    return false
  end
  flag = self:CheckIsAnyUmgIsOpening()
  if flag then
    return false
  end
  return true
end

function PVPRankedMatchModule:CheckIsAnyUmgIsOpening()
  if self.moduleOpeningPanelLst and #self.moduleOpeningPanelLst > 0 then
    return true
  end
  return false
end

function PVPRankedMatchModule:OnCmdOpenPVPCongratulation()
  self:OpenPanel("PVPCongratulation")
end

function PVPRankedMatchModule:OnCmdOClosePVPCongratulation()
  self:ClosePanel("PVPCongratulation")
end

function PVPRankedMatchModule:ClearEasyAction()
  if self.easyAction then
    self.easyAction = nil
  end
end

function PVPRankedMatchModule:OnCmdIsTrailPet(petGid)
  return self.data:IsTrailPet(petGid)
end

function PVPRankedMatchModule:OnCmdGetTrialPets()
  return self.data:GetTrialPets()
end

function PVPRankedMatchModule:OnCmdGetTrialPetBrief()
  return self.data:GetTrialPetBrief()
end

function PVPRankedMatchModule:OnCmdIsRandomPet(petGid)
  return self.data:IsRandomPet(petGid)
end

function PVPRankedMatchModule:OnCmdGetAnyRandomPetGid(option)
  return self.data:GetAnyRandomPetGid(option)
end

function PVPRankedMatchModule:OnCmdDistributeGidForRandomPetInPetTeamInfo(teamInfo)
  local teams = teamInfo and teamInfo.teams or {}
  for i, petTeamInfo in ipairs(teams) do
    self:OnCmdDistributeGidForRandomPetInPetTeam(petTeamInfo)
  end
end

function PVPRankedMatchModule:OnCmdDistributeGidForRandomPetInPetTeam(petTeam)
  local randomPetGidInTeam = {}
  local petInfoList = petTeam and petTeam.pet_infos or {}
  for j, petInfo in ipairs(petInfoList) do
    local petTypeInfo = petInfo and petInfo.type
    local petTypeInfoType = petTypeInfo and petTypeInfo.type
    if petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
      local petGid = petInfo and petInfo.pet_gid
      if petGid then
        randomPetGidInTeam[petGid] = petGid
      end
    end
  end
  for j, petInfo in ipairs(petInfoList) do
    local petTypeInfo = petInfo and petInfo.type
    local petTypeInfoType = petTypeInfo and petTypeInfo.type
    if petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
      local petGid = petInfo and petInfo.pet_gid
      local petInfoType = petInfo and petInfo.type
      local petInfoTypeParam = petInfoType and petInfoType.param
      local skillDamType = petInfoTypeParam
      local option = {
        filterSameSkillDamType = true,
        skillDamType = skillDamType,
        filterNotInTeam = true,
        inTeamGidDic = randomPetGidInTeam
      }
      if nil == petGid then
        petGid = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetAnyRandomPetGid, option)
      end
      if petGid then
        petInfo.pet_gid = petGid
        randomPetGidInTeam[petGid] = petGid
      end
    end
  end
end

function PVPRankedMatchModule:OnCmdDistributeGidForRandomPetInAdjustedAndSharedTeam(adjustedPetTeamInfo, sharedPetTeamInfo)
  local sharedPetTeamInfoPetList = sharedPetTeamInfo and sharedPetTeamInfo.pets or {}
  local adjustedPetTeamInfoPetList = adjustedPetTeamInfo and adjustedPetTeamInfo.pets or {}
  local randomPetGidInTeam = {}
  for i, adjustedPetTeamInfoPet in ipairs(adjustedPetTeamInfoPetList) do
    local sharedPetTeamInfoPet = sharedPetTeamInfoPetList[i]
    local petBaseConfId = sharedPetTeamInfoPet and sharedPetTeamInfoPet.base_conf_id
    local isRandomPet = PetUtils.CheckIsRandomPetBase(petBaseConfId)
    if isRandomPet then
      local petGid = adjustedPetTeamInfoPet and adjustedPetTeamInfoPet.gid
      if petGid and 0 ~= petGid then
        randomPetGidInTeam[petGid] = petGid
      end
    end
  end
  for i, adjustedPetTeamInfoPet in ipairs(adjustedPetTeamInfoPetList) do
    local sharedPetTeamInfoPet = sharedPetTeamInfoPetList[i]
    local petBaseConfId = sharedPetTeamInfoPet and sharedPetTeamInfoPet.base_conf_id
    local isRandomPet = PetUtils.CheckIsRandomPetBase(petBaseConfId)
    if isRandomPet then
      local petGid = adjustedPetTeamInfoPet and adjustedPetTeamInfoPet.gid
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseConfId, true)
      local unitTypeList = petBaseConf and petBaseConf.unit_type or {}
      local skillDamType = unitTypeList and unitTypeList[1] or 0
      local option = {
        filterSameSkillDamType = true,
        skillDamType = skillDamType,
        filterNotInTeam = true,
        inTeamGidDic = randomPetGidInTeam
      }
      if nil == petGid or 0 == petGid then
        petGid = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetAnyRandomPetGid, option)
      end
      if petGid and 0 ~= petGid then
        randomPetGidInTeam[petGid] = petGid
        if adjustedPetTeamInfoPet then
          adjustedPetTeamInfoPet.gid = petGid
        end
      end
    end
  end
end

function PVPRankedMatchModule:OnCmdGetRandomPets(option)
  return self.data:GetRandomPets(option)
end

function PVPRankedMatchModule:OnCmdGetRandomPetRewordConf(pureRandomPetCount, typeRandomPetCount)
  local RandomPetRewordIndexMap = self.data and self.data.RandomPetRewordIndexMap
  local randomPetNum = pureRandomPetCount + typeRandomPetCount
  typeRandomPetCount = 0
  local row = RandomPetRewordIndexMap and RandomPetRewordIndexMap[randomPetNum]
  local conf = row and row[typeRandomPetCount]
  return conf
end

function PVPRankedMatchModule:InitTeamInfoRandomPet()
  local playerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfoList = playerPetInfo and playerPetInfo.team_infos or {}
  for i, teamInfo in ipairs(teamInfoList) do
    self:OnCmdDistributeGidForRandomPetInPetTeamInfo(teamInfo)
  end
end

return PVPRankedMatchModule
