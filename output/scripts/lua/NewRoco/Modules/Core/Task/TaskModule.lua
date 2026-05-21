_G.TaskModuleCmd = reload("NewRoco.Modules.Core.Task.TaskModuleCmd")
local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local rapidjson = require("rapidjson")
local ProtoCMD = require("Data.PB.ProtoCMD")
local ProtoMessage = require("Data.PB.ProtoMessage")
local Enum = require("Data.Config.Enum")
local StatusCheckerEnum = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerEnum")
local StatusCheckerGroup = require("NewRoco.Modules.Core.Task.StatusCheckers.StatusCheckerGroup")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local TaskEnum = require("NewRoco.Modules.Core.Battle.Common.TaskEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local TaskUtils = require("NewRoco.Modules.Core.Task.TaskUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ZoneServer
local TaskModule = NRCModuleBase:Extend("TaskModule")

function TaskModule:OnConstruct()
  ZoneServer = _G.ZoneServer
  self.data = self:SetData("TaskModuleData", "NewRoco.Modules.Core.Task.TaskModuleData")
  self.data.TaskModule = self
  self:_RegisterNotify()
  self.PosMap = {}
  self.ExtraTrackingInfo = {}
  self.ReverseSplinePath = {}
  self.queryTaskCb = nil
  self.takeRewardCb = nil
  self.traceTaskCb = nil
  self.SubTaskIDs = nil
  self.OpenTask = nil
  self.PendingActionTask = nil
  self.TeleportingTask = nil
  self.UserSwitchTrackFromActivityToTask_TaskId = 0
  self.IsClickTrackBtn = false
  self.CatchPetTipID = nil
  self._CatchPetTipsDelayTimer = nil
  self._CatchPetFinishDelayTimer = nil
  self.StatusChecker = StatusCheckerGroup({
    StatusCheckerEnum.Scene,
    StatusCheckerEnum.Teleport,
    StatusCheckerEnum.Battle,
    StatusCheckerEnum.Dialogue,
    StatusCheckerEnum.MainPanel,
    StatusCheckerEnum.FullScreen,
    StatusCheckerEnum.Cinematic,
    StatusCheckerEnum.FastLoading,
    StatusCheckerEnum.TaskInArea,
    StatusCheckerEnum.OnlineState
  }, Log.LOG_LEVEL.ELogDebug, "[TaskFlow]")
  _G.IsOpenGleaning = false
  self:RegPanel("TaskMain", "UMG_TaskPanel", Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RegPanel("TaskMainPanel", "NewTask1/UMG_TaskMainPanel", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, "Open", "Close")
  self:RegPanel("Main_Task", "NewTask/UMG_Main_Task", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("Task_Mail", "NewTask/UMG_Task_Mail", _G.Enum.UILayerType.UI_LAYER_TOP)
  self:RegPanel("Task_Gather", "NewTask/UMG_Task_Gather", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("Envelope", "NewTask/UMG_Envelope", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LacquerPrinting_Tips", "NewTask/UMG_LacquerPrinting_Tips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicStampPanel", "NewTask1/UMG_MagicStampPanel", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("LegendaryTaskUnlockTips", "NewTask1/LegendaryTaskPanel/UMG_LegendaryTaskUnlockTips", Enum.UILayerType.UI_LAYER_POPUP, nil, true, nil, nil, true):SetEnableTouchMask(false)
  self:RegPanel("NightmarePotionPanel", "NewTask1/LegendaryTaskPanel/UMG_NightmarePotionPanel", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicExtractPanel", "NewTask1/LegendaryTaskPanel/UMG_MagicExtractPanel", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ScrapBookPanel", "NewTask1/LegendaryTaskPanel/UMG_ScrapbookPanel", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ReturnRewardPanel", "NewTask1/UMG_Task_ReturnReward", Enum.UILayerType.UI_LAYER_FULLSCREEN, true)
  self:RegPanel("TaskSummary_GroupPhoto", "NewTask1/UMG_TaskSummary_GroupPhoto", Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ImageFlowPanel", "UMG_ImageFlowPanel", Enum.UILayerType.UI_LAYER_DIALOGUE)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.BigWorldPrepared, self.OnBigWorldReload)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  _G.NRCEventCenter:RegisterEvent(self.name, self, TaskModuleEvent.OnWorldPetCatchFinish, self.OnWorldPetCatchFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, BattleEvent.BattleOver, self.OnBattleOverOther)
  self.getLegendaryTaskTipsController = TipsDisplayController(TipEnum.TipObjectType.LegendaryTaskUnlockTips, self, self.OnPlayTips)
  self.getTaskSummaryTipsController = TipsDisplayController(TipEnum.TipObjectType.TaskSummary, self, self.OnPlayTaskSummaryTips)
  self.getReturnRewardTipsController = TipsDisplayController(TipEnum.TipObjectType.TaskReturnReward, self, self.OnPlayReturnRewardTips)
  self.bIsImageFlowPlaying = false
  self.bCanRefreshEnter = true
  self.TipsReason = {}
end

function TaskModule:OnActive()
  self:OnCmdTaskPanelAllInfoReq(true)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TOGETHER_TASK_NOTIFY, self.OnPetTogetherTaskNotify)
  self:CheckTaskPetFollow()
end

function TaskModule:RegPanel(name, path, layer, customDisableRendering, disablePcEsc, openAnimName, closeAnimName, disableLoadBlock)
  local Data = _G.NRCPanelRegisterData()
  Data.panelName = name
  Data.panelPath = string.format("/Game/NewRoco/Modules/System/Task/Res/%s", path)
  Data.panelLayer = layer
  Data.customDisableRendering = customDisableRendering or false
  Data.enablePcEsc = not disablePcEsc
  if openAnimName then
    Data.openAnimName = openAnimName
  end
  if closeAnimName then
    Data.closeAnimName = closeAnimName
  end
  Data.disableLoadBlock = disableLoadBlock
  Data.necessaryResList = self:GetDependsRes()
  self:RegisterPanel(Data)
  return Data
end

function TaskModule:SetSplineVisible(Visible)
  for _, Task in pairs(self.data.TaskMap) do
    local Guide = Task:GetGuideActor()
    if Guide then
      Guide:ToggleVisibility(Visible)
    end
  end
end

function TaskModule:SendZoneSetBookReadedReq(booktype, bookid)
  local req = _G.ProtoMessage:newZoneSetBookReadedReq()
  req.book_type = booktype
  req.book_id = bookid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_BOOK_READED_REQ, req, self, self.ZoneSetBookReadedRsp, false, true)
end

function TaskModule:ZoneSetBookReadedRsp()
end

function TaskModule:SendZoneSetBookRewardReq(booktype, bookid)
  local req = _G.ProtoMessage:newZoneBookGetRewardReq()
  req.book_type = booktype
  req.book_id = bookid
  self.BookRewardType = booktype
  self.BookRewardId = bookid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BOOK_GET_REWARD_REQ, req, self, self.ZoneSetBookRewardRsp, false, true)
end

function TaskModule:ZoneSetBookRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if self.BookRewardType == ProtoEnum.TaleTaskType.TALE_BLOOD_MAGIC then
      for i = 1, #self.data.MagicExtractList do
        if self.data.MagicExtractList[i].id == self.BookRewardId then
          self.data.MagicExtractList[i].reward = true
          break
        end
      end
    end
    _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rsp.ret_info.goods_reward.rewards)
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function TaskModule:GetIsActivityTaskByParagraphId(ParagraphId)
  if ParagraphId then
    if self.data.ActivityTimeTaskMap[ParagraphId] then
      return self.data.ActivityTimeTaskMap[ParagraphId]
    else
      local taskMap = self.data.TaskMap
      if taskMap then
        for _, taskInfo in pairs(taskMap) do
          local cfg = taskInfo.Config
          if ParagraphId and ParagraphId == cfg.paragraph_id and cfg.expire_time_type and cfg.expire_time_type ~= Enum.TaskExpireTimeType.TETT_SEASON and cfg.expire_time_type ~= Enum.TaskExpireTimeType.TETT_NONE then
            self.data.ActivityTimeTaskMap[ParagraphId] = true
            return true
          end
        end
      end
    end
  end
  return false
end

function TaskModule:GetOpenTaskPageIdByUnlockTime(BookDatas, OpenPageId)
  local PageId
  local MaxUnlockTime = 0
  for k, v in ipairs(BookDatas) do
    if OpenPageId == v.book_id then
      return OpenPageId
    end
    if v.unlock_timestamp and MaxUnlockTime < v.unlock_timestamp then
      MaxUnlockTime = v.unlock_timestamp
      PageId = v.book_id
    end
  end
  return PageId
end

local function SortLegendaryList(a, b)
  return a.id < b.id
end

function TaskModule:SendZoneBookDataQueryReq(OpenTaskType, _PageId)
  self.OpenTaskType = OpenTaskType
  self.OpenTaskPageId = _PageId
  if self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_NIGHTMARE then
    NRCProfilerLog:NRCClickBtn(true, "NightmarePotionPanel")
  elseif self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_BLOOD_MAGIC then
    NRCProfilerLog:NRCClickBtn(true, "MagicExtractPanel")
  elseif self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_NOTEBOOK_KELI then
    NRCProfilerLog:NRCClickBtn(true, "ScrapBookPanel")
  end
  local req = _G.ProtoMessage:newZoneBookDataQueryReq()
  req.book_type = self.OpenTaskType
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_BOOK_DATA_QUERY_REQ, req, self, self.OpenLegendaryPanel, false, true)
end

function TaskModule:OpenLegendaryPanel(rsp)
  Log.Dump(rsp, 6, "TaskModule:OpenLegendaryPanel")
  local BookDatas = rsp.book_datas
  if not BookDatas and not _G.GlobalConfig.DebugOpenUI then
    return
  end
  if BookDatas then
    self.OpenTaskPageId = self:GetOpenTaskPageIdByUnlockTime(BookDatas, self.OpenTaskPageId) or self.OpenTaskPageId
  end
  if self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_NIGHTMARE then
    table.clear(self.data.NightmareList)
    self.data.NightmareList = {}
    if not _G.GlobalConfig.DebugOpenUI then
      for i = 1, #BookDatas do
        if BookDatas[i].unlock then
          local Temp = {
            id = BookDatas[i].book_id,
            book_type = BookDatas[i].book_type,
            TaskDone = BookDatas[i].nightmare_data.done,
            BookData = BookDatas[i]
          }
          table.insert(self.data.NightmareList, 1, Temp)
        end
      end
    end
    if #self.data.NightmareList > 0 or _G.GlobalConfig.DebugOpenUI then
      table.sort(self.data.NightmareList, SortLegendaryList)
      self:OpenPanel("NightmarePotionPanel", self.OpenTaskPageId)
    end
  elseif self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_BLOOD_MAGIC then
    table.clear(self.data.MagicExtractList)
    self.data.MagicExtractList = {}
    if not _G.GlobalConfig.DebugOpenUI then
      for i = 1, #BookDatas do
        if BookDatas[i].unlock then
          local Temp = {
            id = BookDatas[i].book_id,
            book_type = BookDatas[i].book_type,
            TaskDone = BookDatas[i].blood_magic_data.done,
            BookData = BookDatas[i],
            reward = BookDatas[i].blood_magic_data.reward
          }
          table.insert(self.data.MagicExtractList, 1, Temp)
        end
      end
    end
    if #self.data.MagicExtractList > 0 or _G.GlobalConfig.DebugOpenUI then
      table.sort(self.data.MagicExtractList, SortLegendaryList)
      self:OpenPanel("MagicExtractPanel", self.OpenTaskPageId)
    end
  elseif self.OpenTaskType == ProtoEnum.TaleTaskType.TALE_NOTEBOOK_KELI then
    self.data.ScrapBookList = {}
    if not _G.GlobalConfig.DebugOpenUI then
      for i = 1, #BookDatas do
        if BookDatas[i].unlock then
          local Temp = {
            id = BookDatas[i].book_id,
            book_type = BookDatas[i].book_type,
            BookData = BookDatas[i]
          }
          table.insert(self.data.ScrapBookList, 1, Temp)
        end
      end
    end
    if #self.data.ScrapBookList > 0 or _G.GlobalConfig.DebugOpenUI then
      self:OpenPanel("ScrapBookPanel", self.OpenTaskPageId)
    end
  end
end

function TaskModule:CmdOpenNightmarePotionPanel(_PageId)
  self:SendZoneBookDataQueryReq(ProtoEnum.TaleTaskType.TALE_NIGHTMARE, _PageId)
end

function TaskModule:CmdOpenMagicExtractPanel(_PageId)
  self:SendZoneBookDataQueryReq(ProtoEnum.TaleTaskType.TALE_BLOOD_MAGIC, _PageId)
end

function TaskModule:CmdOpenScrapBookPanel(_PageId)
  self:SendZoneBookDataQueryReq(ProtoEnum.TaleTaskType.TALE_NOTEBOOK_KELI, _PageId)
end

function TaskModule:CmdOpenReturnRewardPanel(tip)
  self:OpenPanel("ReturnRewardPanel", tip)
end

function TaskModule:CmdCreateReturnRewardTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateTaskReturnRewardTips())
end

function TaskModule:CmdReturnRewardPanelPlayInAnim()
  if self:HasPanel("ReturnRewardPanel") then
    local panel = self:GetPanel("ReturnRewardPanel")
    panel:PlayInAnim()
  end
end

function TaskModule:CmdPlayCollectListGetAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayCollectListAnim()
  end
end

function TaskModule:CmdShowNameTagInAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayNameTagInAnim()
  end
end

function TaskModule:CmdShowExpertInAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayExpertInAnim()
  end
end

function TaskModule:CmdShowNameTagNewInAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayNameTagNewInAnim()
  end
end

function TaskModule:CmdShowMapHeadNewInAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayMapHeadNewInAnim()
  end
end

function TaskModule:CmdShowNewLineLinkAnim()
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:LineUpNewClues()
  end
end

function TaskModule:CmdPlayNameTagAnimOnClicked(matchIndex, cluePage)
  if self:HasPanel("ScrapBookPanel") then
    local panel = self:GetPanel("ScrapBookPanel")
    panel:PlayNameTagAnimOnClicked(matchIndex, cluePage)
  end
end

function TaskModule:OnPlayTips()
  if self:HasPanel("LegendaryTaskUnlockTips") then
    self:ClosePanel("LegendaryTaskUnlockTips")
  end
  self:OpenPanel("LegendaryTaskUnlockTips")
end

function TaskModule:OnLegendaryTaskUnlockNotify(notify)
  if notify.is_new then
    local TaskItem = _G.DataConfigManager:GetAllByName("TASK_ITEM")
    local itemId
    for i = 1, #TaskItem do
      if TaskItem[i].task_type == notify.book_data.book_type then
        itemId = TaskItem[i].bag_item_id
        break
      end
    end
    local uiData = {}
    if itemId then
      local ItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
      uiData.title = ItemConf.name
      uiData.iconPath = ItemConf.icon
    end
    if notify.book_data.book_type == ProtoEnum.TaleTaskType.TALE_NIGHTMARE then
      uiData.content = _G.DataConfigManager:GetTaleNightmareConf(notify.book_data.book_id).unlock_text
    elseif notify.book_data.book_type == ProtoEnum.TaleTaskType.TALE_BLOOD_MAGIC then
      uiData.content = _G.DataConfigManager:GetTaleBloodMagicConf(notify.book_data.book_id).unlock_text
    elseif notify.book_data.book_type == ProtoEnum.TaleTaskType.TALE_NOTEBOOK_KELI then
      uiData.content = _G.DataConfigManager:GetTaleNotebookKeliConf(notify.book_data.book_id).page_unlock_text
    end
    uiData.UnlockTipsType = notify.book_data.book_type or 1
    uiData.PageId = notify.book_data.book_id or 1
    uiData.countdown = 5
    uiData.countdownStr = LuaText.taskmoduletips
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateLegendaryTaskUnlockTips(uiData))
  else
    Log.Debug(string.format("\233\161\181\231\173\190\230\149\176\230\141\174\229\143\152\230\155\180,type\230\152\175%d,PageId\230\152\175%d", notify.book_data.book_type, notify.book_data.book_id))
  end
end

function TaskModule:GetTaskPosition(config, player)
  if not config then
    return nil
  end
  local TaskObject = self.data.TaskMap[config.id]
  if not TaskObject then
    return nil
  end
  if not TaskObject.Trackers or not TaskObject:IsTrack() then
    if self.PosMap[config.id] then
      return UE4.FVector.Dist(self.PosMap[config.id], player:GetActorLocation()) / 100
    else
      return nil
    end
  end
  local Near = math.maxinteger
  local valid = false
  for _, tracker in pairs(TaskObject.Trackers) do
    if tracker.GoCondition.type == ProtoEnum.TaskGoActionType.TGAT_BASE_NPC then
      local Pos
      if tracker.Position then
        Pos = UE4.FVector.Dist(tracker.Position, player:GetActorLocation())
        valid = valid or self:CheckPosValid(tracker.Position)
      end
      if Pos and Near > Pos then
        Near = Pos
      end
    end
  end
  if not valid then
    return nil
  end
  if Near ~= math.maxinteger then
    return Near / 100
  else
    return Near
  end
end

function TaskModule:CheckPosValid(Vector)
  if 0 == Vector.X then
    return false
  end
  if 0 == Vector.Y then
    return false
  end
  if 0 == Vector.Z then
    return false
  end
  return true
end

function TaskModule:OnCmdOpenNewTaskPanel()
  self:OpenTaskPanel()
end

function TaskModule:OnCmdSelectTrackTask(TaskId)
  self:OpenTaskPanel(TaskId)
end

function TaskModule:OnCmdGetSelectTaskTabIndex()
  return self.data:GetSelectTaskTabIndex()
end

function TaskModule:OnCmdGetSelectMagicStampIndex()
  return self.data:GetSelectMagicStampIndex()
end

function TaskModule:OnZoneReportTask()
  local req = _G.ProtoMessage:newZoneGetSubTaskReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_SUB_TASK_REQ, req, self, self.OnCmdGetSubTaskRspInfo, false, true)
end

function TaskModule:OnCmdGetSubTaskRspInfo(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local IsShowEnvelope = self.data:IsShowEnvelope(Rsp.last_get_time)
    if Rsp.sub_task_id and 1 == #Rsp.sub_task_id or Rsp.sub_task_id and IsShowEnvelope then
      self.data:SetRandomSubTask(Rsp.sub_task_id)
      self:ConsumeSubTaskIDs()
    else
      self.data:SetRandomSubTask(nil)
    end
  end
  self:GetTaskTokenOwnedInfoOrBaDgeInfo()
end

function TaskModule:DoOnCmdSelectTaskParagraph(ParagraphData, RspHandler)
  self.data:SetParagraphInfo(ParagraphData)
  self.data:SetParagraphStarTask(ParagraphData)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = self.data:GetParagraphAllTask(ParagraphData)
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, RspHandler, false, true)
  self:DispatchEvent(TaskModuleEvent.ClearSelectState, ParagraphData)
end

function TaskModule:DoGetParagraphTaskInfo(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    if Rsp.task_info_list and #Rsp.task_info_list > 0 then
      self:EliminateOpenTask(Rsp.task_info_list)
      self:SetTaskListInfo(Rsp.task_info_list)
    else
    end
  else
    self:DispatchEvent(TaskModuleEvent.NotOpenParagraph, false)
    Log.Warning("\230\178\161\230\156\137\230\137\147\229\188\128\231\154\132\232\138\130\228\187\187\229\138\161")
    return
  end
end

function TaskModule:OnCmdSelectTaskParagraph(ParagraphData)
  self:DoOnCmdSelectTaskParagraph(ParagraphData, self.GetParagraphTaskInfo)
end

function TaskModule:GetParagraphTaskInfo(Rsp)
  self:DoGetParagraphTaskInfo(Rsp)
end

function TaskModule:OnCmdSelectTaskParagraphForDirectTrace(ParagraphData)
  self:DoOnCmdSelectTaskParagraph(ParagraphData, self.GetParagraphTaskInfoForDirectTrace)
end

function TaskModule:GetParagraphTaskInfoForDirectTrace(Rsp)
  self:DoGetParagraphTaskInfo(Rsp)
  self:OnClickTraceBtn(true)
end

function TaskModule:OnCmdTraceByTaskID(TaskId)
  if TaskId and TaskId > 0 then
    local req = _G.ProtoMessage:newZoneTaskQueryReq()
    req.task_list = {TaskId}
    req.task_state = 0
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.HandleRsp_ZoneTaskQueryRsp_ForTraceTask, false, true)
  end
end

function TaskModule:HandleRsp_ZoneTaskQueryRsp_ForTraceTask(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    if Rsp.task_info_list and #Rsp.task_info_list > 0 then
      self:EliminateOpenTask(Rsp.task_info_list)
      local TaskInfo = Rsp.task_info_list[1]
      self:DoTraceTask(TaskInfo, true)
    end
  else
    return
  end
end

function TaskModule:SetTaskListInfo(task_info_list)
  task_info_list = self:RemoveHiddenTask(task_info_list)
  table.sort(task_info_list, function(a, b)
    if a.open_time ~= b.open_time then
      return a.open_time < b.open_time
    else
      return a.id > b.id
    end
  end)
  self.data:SetTaskList(task_info_list)
  self.data:SetMailTask(nil)
  local IsHasOpenTask = self:SetOpenTaskInfo(task_info_list)
  self:OnCmdGetTaskSummaryByTaskId(self:GetPhotoTask(task_info_list, IsHasOpenTask))
end

function TaskModule:SetOpenTaskInfo(task_info_list)
  local IsHasOpenTask = false
  local IsSet = false
  local TrackSubTasks, OpenTask
  for i, Task_Info in ipairs(task_info_list) do
    if Task_Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      IsHasOpenTask = true
      if Task_Info.is_track then
        IsSet = true
        self.data:SetOpenTask(Task_Info)
      end
      local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
      if TaskConf.message_id and 0 ~= TaskConf.message_id then
        IsSet = true
        self.data:SetOpenTask(Task_Info)
        self.data:SetMailTask(TaskConf)
      end
      local TaskObject = self:OnCmdGetTaskObjectByTaskId(Task_Info.id)
      if TaskObject.TrackSubTasks and #TaskObject.TrackSubTasks > 0 and not IsSet then
        TrackSubTasks = Task_Info
      end
      OpenTask = Task_Info
    end
  end
  if not IsSet then
    if TrackSubTasks then
      self.data:SetOpenTask(TrackSubTasks)
    else
      self.data:SetOpenTask(OpenTask)
    end
  end
  if not IsHasOpenTask then
    table.sort(task_info_list, function(a, b)
      if a.done_time ~= b.done_time then
        return a.done_time > b.done_time
      end
      local TaskConf = _G.DataConfigManager:GetTaskConf(a.id)
      if TaskConf.is_para_done then
        return true
      end
      TaskConf = _G.DataConfigManager:GetTaskConf(b.id)
      if TaskConf.is_para_done then
        return false
      end
      return a.id > b.id
    end)
    self.data:SetOpenTask(task_info_list[1])
  end
  return IsHasOpenTask
end

function TaskModule:GetPhotoTask(task_info_list, IsHasOpenTask)
  for i, Task_Info in ipairs(task_info_list) do
    local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
    for _, Condition in ipairs(TaskConf.finish_action) do
      if Condition.type == Enum.TaskStateChangeActionType.TSCAT_TASK_SUMMARY then
        return Task_Info.id
      end
    end
  end
  return self.data:GetOpenTask() and self.data:GetOpenTask().id
end

function TaskModule:RemoveHiddenTask(task_info_list)
  local TaskList = {}
  if not task_info_list then
    return TaskList
  end
  for i, Task_Info in ipairs(task_info_list) do
    local TaskConf = _G.DataConfigManager:GetTaskConf(Task_Info.id)
    if 0 == TaskConf.open and 0 == TaskConf.show then
      table.insert(TaskList, Task_Info)
    end
  end
  return TaskList
end

function TaskModule:SetGleaningsLacquer(uiData)
  local OpenTask = self.data:GetOpenTask()
  if OpenTask then
    local TaskConf = _G.DataConfigManager:GetTaskConf(OpenTask.id)
    if TaskConf.task_class == Enum.TaskClassType.TCT_SUB then
      local ParagraphData = self.data:GetParagraphInfo()
      self.data:SetSelectGleaningParagraphId(ParagraphData.paragraph)
      local LacquerIsUnLock, StartTaskId = self.data:GetLacquerIsUnLockByParagraph(ParagraphData.paragraph)
      if LacquerIsUnLock and 0 == ParagraphData.Type then
        self:GetOngoingSubTaskInfoReq(StartTaskId)
      else
        self:DispatchEvent(TaskModuleEvent.SelectTaskParagraph, OpenTask, self.data:GetParagraphInfo(), uiData)
      end
    else
      self:DispatchEvent(TaskModuleEvent.SelectTaskParagraph, OpenTask, self.data:GetParagraphInfo(), uiData)
    end
  else
    Log.Debug("\230\178\161\230\156\137\230\137\147\229\188\128\231\154\132\228\187\187\229\138\161")
  end
end

function TaskModule:OnCmdOpenMagicStampPanel(_OpenToKenType, TabType)
  self.OpenTokenType = _OpenToKenType
  self.TabType = TabType
  if TabType == TaskEnum.MagicStampTabType.Lacquer then
    local ToKenLocked = self.data:GetTokenLocked()
    if ToKenLocked == ProtoEnum.TaskTokenInfo.TaskTokenState.TTS_LOCK then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.taskmodule_1)
      return
    end
  end
  local req = _G.ProtoMessage:newZoneGetTaskTokenOwnedInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_TASK_TOKEN_OWNED_INFO_REQ, req, self, self.OnGetTaskToKenInfoRsp)
end

function TaskModule:OnGetTaskToKenInfoRsp(_rsp)
  self:OpenPanel("MagicStampPanel", _rsp.task_token_owned_data, self.OpenTokenType, self.TabType)
end

function TaskModule:OnCmdSelectBaDgeInfo(BaDge)
  self:DispatchEvent(TaskModuleEvent.SelectBaDgeInfoEvent, BaDge)
end

function TaskModule:GetTaskTokenOwnedInfoOrBaDgeInfo()
  local req = _G.ProtoMessage:newZoneGetTaskTokenOwnedInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_TASK_TOKEN_OWNED_INFO_REQ, req, self, self.OnGetTaskTokenOwnedInfoOrBaDgeInfo)
end

function TaskModule:OnGetTaskTokenOwnedInfoOrBaDgeInfo(_rsp)
  local MedalList = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_BADGE_MAGIC)
  local TaskTokenInfo = _rsp.task_token_owned_data
  if MedalList and #MedalList > 0 or TaskTokenInfo and #TaskTokenInfo > 0 then
    self.HasCollect = true
  else
    self.HasCollect = false
  end
  Log.Dump(MedalList, 6, "TaskModule:OnGetTaskTokenOwnedInfoOrBaDgeInfo")
  Log.Dump(TaskTokenInfo, 6, "TaskModule:OnGetTaskTokenOwnedInfoOrBaDgeInfo")
  self:OnCmdTaskSheetState()
end

function TaskModule:OnCmdTraceParagraphByID(ParagraphID, TipsId)
  self.TipsId = TipsId
  local TaskMap = self.data and self.data.TaskMap
  local hasFindTask = false
  if not TaskMap then
    return
  end
  local ParagraphList = {}
  if type(ParagraphID) == "number" then
    ParagraphList = {ParagraphID}
  elseif type(ParagraphID) == "table" then
    ParagraphList = ParagraphID
  elseif type(ParagraphID) == "string" then
    ParagraphList = {
      tonumber(ParagraphID)
    }
  end
  local TaskID
  for i, id in ipairs(ParagraphList) do
    if type(id) == "string" then
      id = tonumber(id)
    end
    for ID, Task in pairs(TaskMap) do
      if not Task then
      elseif not Task.Info then
      elseif Task.Info.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      elseif not Task.Config then
      elseif Task.Config.paragraph_id ~= id then
      else
        TaskID = ID
        break
      end
    end
    if TaskID then
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
        local TaskConf = _G.DataConfigManager:GetTaskConf(TaskID)
        if not TaskConf.peer_available then
          local Text = LuaText.Adventure_task_peer_not_available
          _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          return
        end
      end
      _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
      local taskInfo = self:GetTaskByID(TaskID)
      if taskInfo then
        hasFindTask = true
        self:DoTraceTask(taskInfo, true)
      end
      break
    end
  end
  if false == hasFindTask then
    local text = LuaText.task_track_error7
    if self.TipsId then
      local locConf = _G.DataConfigManager:GetLocalizationConf(self.TipsId)
      if locConf then
        text = locConf.msg
      end
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  end
end

function TaskModule:CmdFilterParagraphIDListInCurrTask(ParagraphList)
  local ParagraphID
  local TaskMap = self.data and self.data.TaskMap
  for i, id in ipairs(ParagraphList) do
    if type(id) == "string" then
      id = tonumber(id)
    end
    for ID, Task in pairs(TaskMap) do
      if not Task then
      elseif not Task.Info then
      elseif Task.Info.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
      elseif not Task.Config then
      elseif Task.Config.paragraph_id ~= id then
      else
        ParagraphID = id
        break
      end
    end
    if ParagraphID then
      break
    end
  end
  return ParagraphID
end

function TaskModule:GetTaskInfo(Rsp)
  Log.Dump(Rsp, 6, "TaskModule:GetTaskTypeInfo")
  if 0 == Rsp.ret_info.ret_code and Rsp.task_type_list then
    self.data:SetParagraphData(Rsp.task_type_list)
  end
  self:SelectTaskParagraphByID()
end

function TaskModule:SelectTaskParagraphByID(ParagraphID)
  local paragraphData = self:GetParagraphDataByID(self.ParagraphID)
  if paragraphData then
    self:OnCmdSelectTaskParagraphForDirectTrace(paragraphData)
    NRCModuleManager:DoCmd(MagicManualModuleCmd.CloseMagicManual)
  else
    local text = LuaText.task_track_error7
    if self.TipsId then
      text = _G.DataConfigManager:GetLocalizationConf(self.TipsId).msg
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  end
end

function TaskModule:GetParagraphDataByID(ParagraphID)
  local BaseTaskList = self.data:GetBaseTaskList()
  if BaseTaskList then
    for _, taskList in ipairs(BaseTaskList) do
      if taskList.AllParagraph then
        for _, paragraphData in ipairs(taskList.AllParagraph) do
          if type(ParagraphID) == "table" then
            for _, ID in ipairs(ParagraphID) do
              if paragraphData.paragraph == tonumber(ID) then
                return paragraphData
              end
            end
          elseif paragraphData.paragraph == ParagraphID then
            return paragraphData
          end
        end
      end
    end
  end
  return nil
end

function TaskModule:OnCmdTraceParagraphOpenTaskPanel(ParagraphList, TipsId)
  self.ParagraphList = {}
  self.TipsId = TipsId
  if type(ParagraphList) == "number" then
    self.ParagraphList = {ParagraphList}
  elseif type(ParagraphList) == "table" then
    self.ParagraphList = ParagraphList
  elseif type(ParagraphList) == "string" then
    self.ParagraphList = {
      tonumber(ParagraphList)
    }
  end
  self.IsOpenTaskByParagraphList = true
  self.IsTest = true
  self:OnCmdTaskPanelAllInfoReq()
end

function TaskModule:OpenTaskPanel(TaskId)
  self:MarkPanelWaitingOpen("TaskMainPanel")
  self.IsTest = true
  self.TaskId = TaskId
  self.IsOpenTaskByParagraphList = false
  self.ParagraphList = nil
  self.TipsId = nil
  self.data:SetOpenParagraph(nil)
  self:OnCmdTaskPanelAllInfoReq()
end

function TaskModule:OnCmdGetSubTaskRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local IsShowEnvelope = self.data:IsShowEnvelope(Rsp.last_get_time)
    if Rsp.sub_task_id and 1 == #Rsp.sub_task_id or Rsp.sub_task_id and IsShowEnvelope then
      self.data:SetRandomSubTask(Rsp.sub_task_id)
      self:OnCmdOpenEnvelopePanel()
      self:ConsumeSubTaskIDs()
    else
      self:GetTaskTokenOwnedInfoOrBaDgeInfo()
    end
  end
end

function TaskModule:CheckOpenPanelRspError(_Rsp)
  if nil == _Rsp then
    return false
  end
  if 0 ~= _Rsp.ret_info.ret_code then
    self:HandleOpenPanelRspError()
    return false
  end
  return true
end

function TaskModule:HandleOpenPanelRspError()
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function TaskModule:OnCmdTaskPanelAllInfoReq(onlyUpdateParagraphData)
  local function HandleTaskPanelAllInfoRsp(_, Rsp)
    self:HandleTaskPanelAllInfoRsp(Rsp, onlyUpdateParagraphData)
  end
  
  local req = _G.ProtoMessage:newZoneTaskPanelAllInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_PANEL_ALL_INFO_REQ, req, self, HandleTaskPanelAllInfoRsp)
end

function TaskModule:HandleTaskPanelAllInfoRsp(Rsp, onlyUpdateParagraphData)
  if not self:CheckOpenPanelRspError(Rsp) then
    return
  end
  self.data:SetSubTaskTokenTriggeredInfo(Rsp.sub_task_token_triggered_task_info)
  local IsShowEnvelope = self.data:IsShowEnvelope(Rsp.last_get_time)
  if Rsp.sub_task_id and 1 == #Rsp.sub_task_id or Rsp.sub_task_id and IsShowEnvelope then
    self.data:SetRandomSubTask(Rsp.sub_task_id)
    self:ConsumeSubTaskIDs()
  else
    self.data:SetRandomSubTask(nil)
  end
  local MedalList = BagModuleCmd and _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_BADGE_MAGIC) or nil
  local TaskTokenInfo = Rsp.task_token_owned_data
  if MedalList and #MedalList > 0 or TaskTokenInfo and #TaskTokenInfo > 0 then
    self.HasCollect = true
  else
    self.HasCollect = false
  end
  if Rsp.task_type_list then
    if onlyUpdateParagraphData then
      self.data:SetParagraphData(Rsp.task_type_list)
      self:OnRefreshTaskMainPanel()
      self:DispatchEvent(TaskModuleEvent.OnlyRefreshParagraphData)
    elseif not self.IsTest then
      self.data:SetTaskTypeList(Rsp.task_type_list)
      self:FirstSelectTaskType()
    else
      self.data:SetParagraphData(Rsp.task_type_list)
      self:OpenTaskMainPanel()
    end
  else
    self:HandleOpenPanelRspError()
    Log.Error("ZoneTaskSheetStateRsp\229\141\143\232\174\174\230\149\176\230\141\174\230\156\137\229\183\174\229\188\130,\232\175\183\230\163\128\230\159\165")
  end
end

function TaskModule:OnCmdGetSubTaskTokenTriggeredRsp(_Rsp)
  if self:CheckOpenPanelRspError(_Rsp) then
    return
  end
  self.data:SetSubTaskTokenTriggeredInfo(_Rsp.sub_task_token_triggered_task_info)
  self:OnZoneReportTask()
end

function TaskModule:OnCmdCloseEnvelopePanel()
  self:GetTaskTokenOwnedInfoOrBaDgeInfo()
end

function TaskModule:OnCmdOpenSubTask(_TaskId)
  self.TaskId = _TaskId
  local req = _G.ProtoMessage:newZoneOpenSubTaskReq()
  req.sub_task_id = _TaskId
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_OPEN_SUB_TASK_REQ, req, self, self.OnCmdOpenSubTaskRsp)
end

function TaskModule:OnCmdOpenSubTaskRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    self:GetTaskTokenOwnedInfoOrBaDgeInfo()
  end
end

function TaskModule:OnCmdTaskSheetState()
  local req = _G.ProtoMessage:newZoneTaskSheetStateReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_SHEET_STATE_REQ, req, self, self.GetTaskTypeInfo)
end

function TaskModule:GetTaskTypeInfo(Rsp)
  Log.Dump(Rsp, 6, "TaskModule:GetTaskTypeInfo")
  if not self:CheckOpenPanelRspError(Rsp) then
    return
  end
  if Rsp.task_type_list then
    if not self.IsTest then
      self.data:SetTaskTypeList(Rsp.task_type_list)
      self:FirstSelectTaskType()
    else
      self.data:SetParagraphData(Rsp.task_type_list)
      self:OpenTaskMainPanel()
    end
  else
    self:HandleOpenPanelRspError()
    Log.Error("ZoneTaskSheetStateRsp\229\141\143\232\174\174\230\149\176\230\141\174\230\156\137\229\183\174\229\188\130,\232\175\183\230\163\128\230\159\165")
  end
end

function TaskModule:OpenTaskMainPanel()
  if not self:HasPanel("TaskMainPanel") then
    self.IsClickTrackBtn = false
    if self.IsOpenTaskByParagraphList and not self:OpenTaskPanelByParagraphList() then
      local Text
      if self.TipsId then
        Text = _G.DataConfigManager:GetLocalizationConf(self.TipsId).msg
      else
        Text = LuaText.task_track_error7
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      return
    end
    self:OpenPanel("TaskMainPanel", self.TaskId)
  else
    local RandomSubTask = self.data:GetRandomSubTask()
    if RandomSubTask then
      self:DispatchEvent(TaskModuleEvent.OpenJourneyEnvelope)
    end
    self.data:SetRandomSubTask(nil)
  end
end

function TaskModule:OnCmdCloseTaskMainPanel()
  self:ClosePanel("TaskMainPanel")
end

function TaskModule:OpenTaskPanelByParagraphList()
  local BaseTaskList = self.data:GetBaseTaskList()
  for _, Paragraph in ipairs(self.ParagraphList) do
    for i, BaseTask in ipairs(BaseTaskList) do
      if BaseTask.AllParagraph and #BaseTask.AllParagraph > 0 then
        for j, ParagraphInfo in ipairs(BaseTask.AllParagraph) do
          local ParagraphData = Paragraph
          if type(ParagraphData) == "string" then
            ParagraphData = tonumber(ParagraphData)
          end
          if ParagraphData == ParagraphInfo.paragraph and ParagraphInfo.Type ~= TaskEnum.TaskParagraphFinishState.done then
            self.data:SetOpenParagraph(ParagraphData)
            return true
          end
        end
      end
    end
  end
  return false
end

function TaskModule:EnableTaskMainPanel()
  if self:HasPanel("TaskMainPanel") then
    local Panel = self:GetPanel("TaskMainPanel")
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function TaskModule:PreLoadTaskMainPanel()
  self:PreLoadPanel("TaskMainPanel", 10)
end

function TaskModule:FirstSelectTaskType()
  local AllTask = self:GetAllTraceTask()
  local data = self.data:GetTaskTypeList()
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_SHENHE_ADVANCE_ROLE)
  Log.Debug(Flags, "TaskModule:FirstSelectTaskType")
  local Task_Class, ParagraphId
  local IsSelectTask = false
  for i, Task in ipairs(AllTask) do
    if Task.isTrack == true and (Task.Config.task_class == Enum.TaskClassType.TCT_SUB or Task.Config.task_class == Enum.TaskClassType.TCT_MAIN or Task.Config.task_class == Enum.TaskClassType.TCT_JOURNEY) then
      Task_Class = Task.Config.task_class
      ParagraphId = Task.Config.paragraph_id
      break
    end
  end
  for _, v in ipairs(data) do
    local IsSucceed = false
    if Task_Class then
      if Task_Class == v.task_type then
        IsSucceed = true
        for i, Paragraph in ipairs(v.LeftList) do
          if ParagraphId == Paragraph.paragraph then
            self.data:SetMainTaskTraceParagraph(ParagraphId)
            break
          end
        end
      end
    elseif v.LeftList then
      IsSucceed = true
    end
    local TaskParagraphId = self.data:GetTaskParagraphId()
    if TaskParagraphId then
      if v.task_type == Enum.TaskClassType.TCT_SUB then
        IsSelectTask = true
        self.data:SetSelectIndex(v.PanelIndex)
        self:SelectTaskType(v, v.PanelIndex)
        break
      end
    elseif IsSucceed then
      IsSelectTask = true
      self.data:SetSelectIndex(v.PanelIndex)
      self:SelectTaskType(v, v.PanelIndex)
      break
    end
  end
  if not Flags and false == IsSelectTask then
    Log.Error("\230\178\161\230\156\137\231\180\162\229\143\150\229\136\176\229\175\185\229\186\148\228\187\187\229\138\161\231\177\187\229\158\139,\230\137\128\228\187\165\230\137\147\229\188\128\233\157\162\230\157\191\230\156\137\233\151\174\233\162\152")
  end
end

function TaskModule:GetMapTaskList()
  if self.data then
    return self.data.MapTaskList
  end
end

function TaskModule:OnCmdTaskQueryReq(TaskParagraphIdList)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = TaskParagraphIdList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetSelectTaskTypeInfo)
end

function TaskModule:GetSelectTaskTypeInfo(Rsp)
  Log.Dump(Rsp.task_info_list, 6, "TaskModule:GetSelectTaskTypeInfo")
  if 0 == Rsp.ret_info.ret_code then
    if Rsp.task_info_list then
      self:EliminateOpenTask(Rsp.task_info_list)
      self.data:SetCurrentTaskParagraphInfo(Rsp.task_info_list)
    else
    end
  else
    Log.Error("\228\187\187\229\138\161\230\138\165\233\148\153")
    return
  end
  local TaskPanelInfo = self.data:GetTaskPanelInfo()
  self:DispatchEvent(TaskModuleEvent.SelectTaskTypeEvent, TaskPanelInfo, self.IsUpdateAll)
end

function TaskModule:OnCmdOpenEnvelopePanel()
  local RandomSubTask = self.data:GetRandomSubTask()
  if not RandomSubTask then
    return
  end
  self.IsOpenEnvelope = true
  self:OpenPanel("Envelope", RandomSubTask)
end

function TaskModule:OnCmdOpenGatherPanel(_OpenToKenType)
  local ToKenLocked = self.data:GetTokenLocked()
  if ToKenLocked == ProtoEnum.TaskTokenInfo.TaskTokenState.TTS_LOCK and _OpenToKenType == TaskEnum.OpenToKenType.operation then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.taskmodule_1)
    return
  end
  self.OpenToKenType = _OpenToKenType
  local req = _G.ProtoMessage:newZoneGetTaskTokenOwnedInfoReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_TASK_TOKEN_OWNED_INFO_REQ, req, self, self.OnGetTaskTokenOwnedInfoRsp)
end

function TaskModule:OnGetTaskTokenOwnedInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self:OpenPanel("Task_Gather", _rsp.task_token_owned_data, self.OpenToKenType)
  end
end

function TaskModule:OnCmdOpenTokenDetails(TokenInfo)
  self:OpenPanel("LacquerPrinting_Tips", TokenInfo)
end

function TaskModule:OnCmdSelectTokenInfo(SelectTokenInfo)
  self.data:SetSelectTokenInfo(SelectTokenInfo)
end

function TaskModule:OnCmdGetSelectTokenInfo()
  return self.data:GetSelectTokenInfo()
end

function TaskModule:OnCmdGetRewardByIsUnLockLacquer()
  return self.data:GetRewardByIsUnLockLacquer()
end

function TaskModule:OnCmdGetCurrentSelectParagraphToken()
  return self.data:GetCurrentSelectParagraphToken()
end

function TaskModule:OnCmdGetParagraphStarTask()
  return self.data:GetParagraphStarTask()
end

function TaskModule:OnCmdGetTokenIsLocked()
  return self.data:GetTokenLocked()
end

function TaskModule:OnCmdShowExtraTaskByTokenInfo()
  return self.data:ShowExtraTaskByTokenInfo()
end

function TaskModule:OnCmdGetParagraphContent(Content)
  return self.data:ParagraphFinishShowContent(Content)
end

function TaskModule:OnCmdGetMainTaskTraceParagraph()
  return self.data:GetMainTaskTraceParagraph()
end

function TaskModule:OnCmdGetTaskRedPointList()
  return self.data:GetTaskRedPointList()
end

function TaskModule:OnCmdGetOpenTask()
  return self.data:GetOpenTask()
end

function TaskModule:OnCmdEquipmentToKenInfo(TokenUseType)
  self.IsEquipment = true
  local SelectTokenInfo = self.data:GetSelectTokenInfo()
  self.GetParagraphStarTask = self.data:GetParagraphStarTask()
  local SetSubTaskTokenAction = {}
  local TokenList = {}
  if SelectTokenInfo.sub_task_id and 0 ~= SelectTokenInfo.sub_task_id then
    table.insert(SetSubTaskTokenAction, {
      sub_task_id = SelectTokenInfo.sub_task_id,
      task_token_owned_info = nil
    })
  end
  table.insert(TokenList, {
    task_token_id = SelectTokenInfo.task_token_id,
    task_token_get_time = SelectTokenInfo.task_token_get_time
  })
  table.insert(SetSubTaskTokenAction, {
    sub_task_id = self.GetParagraphStarTask,
    task_token_owned_info = TokenList
  })
  self.TokenUseTYpe = TokenUseType
  local req = _G.ProtoMessage:newZoneSetSubTaskTokenReq()
  req.action = SetSubTaskTokenAction
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SET_SUB_TASK_TOKEN_REQ, req, self, self.SetSubTaskTokenRsp)
end

function TaskModule:OnCmdDisBoardToKenInfo(TokenUseType)
  local CurrentSelectParagraphToken = self.data:GetCurrentSelectParagraphToken()
  if not CurrentSelectParagraphToken or not CurrentSelectParagraphToken.task_token_info then
    return
  end
  self.IsEquipment = false
  self.TokenUseTYpe = TokenUseType
  self.GetParagraphStarTask = self.data:GetParagraphStarTask()
  local SetSubTaskTokenAction = {}
  table.insert(SetSubTaskTokenAction, {
    sub_task_id = self.GetParagraphStarTask,
    task_token_owned_info = nil
  })
  local req = _G.ProtoMessage:newZoneSetSubTaskTokenReq()
  req.action = SetSubTaskTokenAction
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SET_SUB_TASK_TOKEN_REQ, req, self, self.SetSubTaskTokenRsp)
end

function TaskModule:SetSubTaskTokenRsp(_rsp)
  local SelectTokenInfo = self.data:GetSelectTokenInfo()
  if self.IsEquipment then
    self.data:SetEquipmentParagraphTokenToken(SelectTokenInfo, self.GetParagraphStarTask)
  end
  self:DispatchEvent(TaskModuleEvent.SubTaskTokenEvent, self.IsEquipment, SelectTokenInfo and SelectTokenInfo.task_token_id, self.TokenUseTYpe)
  self.data:SetSelectTokenInfo(nil)
end

function TaskModule:EliminateOpenTask(_TaskInfo)
  local TaskData = {}
  for i, Task in ipairs(_TaskInfo) do
    if Task.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      table.insert(TaskData, Task)
    end
  end
  self.data:_UpdateTaskInfos(TaskData)
end

function TaskModule:TaskRewardReq(id)
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  table.insert(req.task_list, id)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.TaskRewardRsp, true, false)
end

function TaskModule:TaskRewardRsp(Rsp)
  self.data:_UpdateTaskInfos(Rsp.rewarded_task_list)
  self.data:_UpdateTaskInfos(Rsp.next_task_list)
  self.data:MakeDirty()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ProcessRetInfo, ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY, ProtoMessage:newRetInfo())
  self:PostTaskUpdate()
  self:OnSetTaskListInfo(Rsp.next_task_list)
end

function TaskModule:OnCmdZoneReportTaskReq(messageId)
  local req = _G.ProtoMessage:newZoneReportTaskReq()
  req.tctt = _G.ProtoEnum.TaskClientTriggerType.TCTT_READ_LETTER
  req.data = messageId
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_REPORT_TASK_REQ, req, self, self.OnZoneReportTaskRsp, true, false)
end

function TaskModule:OnZoneReportTaskRsp(_rsp)
end

function TaskModule:OnCmdGetMainTasks(ExistingList)
  local TaskMap = self.data.TaskMap
  local CurrentTasks
  if TaskMap then
    for _, Task in pairs(TaskMap) do
      if Task.Info.state ~= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
      elseif Task.Config.task_class ~= _G.Enum.TaskClassType.TCT_JOURNEY then
      elseif Task.TrackParentTask then
      else
        CurrentTasks = CurrentTasks or {}
        table.insert(CurrentTasks, Task)
      end
    end
  end
  local RemovedTasks
  if ExistingList and #ExistingList > 0 then
    for _, Exist in pairs(ExistingList) do
      local Found = false
      for _, Task in ipairs(CurrentTasks) do
        if Task.id == Exist then
          Found = true
          break
        end
      end
      if not Found then
        RemovedTasks = RemovedTasks or {}
        table.insert(RemovedTasks, Exist)
      end
    end
  end
  return CurrentTasks, RemovedTasks
end

function TaskModule:OnSetTaskListInfo(task_list)
  local HasPanel = self:HasPanel("TaskMainPanel")
  if HasPanel then
    self:SetTaskListInfo(task_list)
  end
end

function TaskModule:lookLetter(messageId, Action)
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    if Action then
      Action:Finish(false)
    end
    return
  end
  if self:HasPanel("Task_Mail") then
    if Action then
      Action:Finish(false)
    end
    return
  end
  if not messageId or 0 == messageId then
    Log.Error("message_id\233\133\141\231\189\174\230\154\130\230\151\182\230\178\161\230\149\176\230\141\174")
    return
  end
  self.IsOpenEnvelope = true
  self:OpenPanel("Task_Mail", messageId, Action)
end

function TaskModule:CloseMail()
  if self:HasPanel("Task_Mail") then
    self.IsOpenEnvelope = false
    self:ClosePanel("Task_Mail")
  end
end

function TaskModule:SelectTaskType(_data, _index)
  self.data:SetSelectIndex(_index)
  local TaskParagraphIdList = self.data:SetSelectTaskParagraphIdList(_data, _data.LeftList[1])
  self.data:SetSelectTaskParagraphInfo(_data)
  self.IsUpdateAll = true
  self:OnCmdTaskQueryReq(TaskParagraphIdList)
end

function TaskModule:SelectLeGenDaryParagraph(_data)
  local SelectTaskParagraphInfo = self.data:GetSelectTaskParagraphInfo()
  local TaskParagraphIdList = self.data:SetSelectTaskParagraphIdList(SelectTaskParagraphInfo, _data)
  self.IsUpdateAll = false
  self:OnCmdTaskQueryReq(TaskParagraphIdList)
end

function TaskModule:SelectGleaningParagraph(_data)
  if -1 == _data.Type then
    self:DispatchEvent(TaskModuleEvent.SelectWillParagragh)
  else
    self.GleaningParagraph = _data
    local SelectTaskParagraphInfo = self.data:GetSelectTaskParagraphInfo()
    local TaskParagraphIdList = self.data:SetSelectTaskParagraphIdList(SelectTaskParagraphInfo, _data)
    self.data:SetSelectGleaningParagraphId(_data.paragraph)
    self.IsUpdateAll = false
    local LacquerIsUnLock, StartTaskId = self.data:GetLacquerIsUnLockByParagraph(_data.paragraph)
    if LacquerIsUnLock and 0 == _data.Type then
      self:GetOngoingSubTaskInfoReq(StartTaskId)
    else
      self.data:SetCurrentSelectParagraphToken(nil)
      self:OnCmdTaskQueryReq(TaskParagraphIdList)
    end
  end
end

function TaskModule:GetOngoingSubTaskInfoReq(StartTaskId)
  local req = _G.ProtoMessage:newZoneGetOngoingSubTaskInfoReq()
  req.sub_task_id = StartTaskId
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_ONGOING_SUB_TASK_INFO_REQ, req, self, self.GetOngoingSubTaskInfoRsp)
end

function TaskModule:GetOngoingSubTaskInfoRsp(_rsp)
  if 0 == _rsp.ret_info.ret_code then
    self.data:SetTokenLocked(_rsp.ongoing_sub_task_info.task_token_info and _rsp.ongoing_sub_task_info.task_token_info[1].task_token_state)
    self.data:SetCurrentSelectParagraphToken(_rsp.ongoing_sub_task_info)
    self:DispatchEvent(TaskModuleEvent.SelectTaskParagraph, self.data:GetOpenTask(), self.data:GetParagraphInfo())
  end
end

function TaskModule:OnRandomSubTaskNotify(_Notify)
  Log.Error("Random Sub Task Notify")
  local SubTask = _Notify.sub_task_id
  if SubTask and #SubTask > 0 then
    self.SubTaskIDs = SubTask
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ProcessRetInfo, ProtoCMD.ZoneSvrCmd.ZONE_RANDOM_SUB_TASK_NOTIFY, ProtoMessage:newRetInfo())
  else
    self.SubTaskIDs = nil
  end
end

function TaskModule:OnLogin(isRelogin)
  if self.IsOpenEnvelope and isRelogin then
    self.IsOpenEnvelope = false
    _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
    self:CloseMail()
  end
  self.TeleportingTask = nil
end

function TaskModule:GetSubTaskIDs()
  return self.SubTaskIDs
end

function TaskModule:ConsumeSubTaskIDs()
  self.SubTaskIDs = nil
end

function TaskModule:OmCmdRemoveToKenRewardSucceed(_IsPrize, IsTokenChange, IsEquipment)
  self:DispatchEvent(TaskModuleEvent.RemoveToKenRewardSucceed, _IsPrize, IsTokenChange, IsEquipment)
end

function TaskModule:OnClickTraceBtn(bShouldTrack)
  self.IsClickTrackBtn = true
  local TaskInfo = self.data:GetOpenTask()
  self:DoTraceTask(TaskInfo, bShouldTrack)
end

function TaskModule:DoTraceTask(TrackInfo, bShouldTrack)
  if not TrackInfo then
    return
  end
  local Task = self:SetTrack(TrackInfo.id, bShouldTrack, true)
  if not Task then
    return
  end
  if Task.isTrack then
    if Task.TrackSubTasks and #Task.TrackSubTasks > 0 then
      local MinDistance, TrackerInfo
      for i, TrackSubTask in ipairs(Task.TrackSubTasks) do
        if TrackSubTask.Trackers and #TrackSubTask.Trackers > 0 then
          for j, Tracker in ipairs(TrackSubTask.Trackers) do
            if not Tracker:IsCheckConditionDone(Tracker.go_index) then
              if not MinDistance then
                MinDistance = Tracker.DistanceToPlayer
                TrackerInfo = Tracker
              elseif MinDistance > Tracker.DistanceToPlayer then
                MinDistance = Tracker.DistanceToPlayer
                TrackerInfo = Tracker
              end
            end
          end
        end
      end
      if TrackerInfo then
        TrackerInfo:AddEventListener(self, TaskModuleEvent.ON_TASK_TRACK_SCENE_NPC_REFRESH, self.UpdateTrackerInfo)
        return
      end
    elseif Task.Trackers and #Task.Trackers > 0 then
      for i, Tracker in ipairs(Task.Trackers) do
        if not Tracker:IsCheckConditionDone(Tracker.go_index) and Tracker.TaskInfo.id == TrackInfo.id then
          Tracker:AddEventListener(self, TaskModuleEvent.ON_TASK_TRACK_SCENE_NPC_REFRESH, self.UpdateTrackerInfo)
          return
        end
      end
    end
  else
    return
  end
  Log.Error("\232\175\165\228\187\187\229\138\161\229\141\179\230\178\161\230\156\137Trackers\228\185\159\230\178\161\230\156\137\229\173\144\228\187\187\229\138\161\231\154\132Trackers,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
end

function TaskModule:OnSetTraceTaskInfo(trackTaskId, bShouldTrack)
  local Task = self:SetTrack(trackTaskId, bShouldTrack, true)
  if not Task then
    Log.Debug("TaskModule:OnSetTraceTaskInfo -- not found TaskExample trackTaskId:" .. trackTaskId)
    return
  end
  if Task.isTrack then
    if Task:HasTrackInfo() then
      self:CheckOpenMapTrackTask(Task)
    else
      Task:AddEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.CheckOpenMapTrackTask)
    end
  else
    Log.Debug("TaskModule:OnSetTraceTaskInfo -- Task.isTrack is false")
  end
end

function TaskModule:OnAddTaskInfos(taskInfos)
  if taskInfos and #taskInfos > 0 then
    self.data:_UpdateTaskInfos(taskInfos, false)
  end
end

function TaskModule:CheckOpenMapTrackTask(task)
  if not task then
    return
  end
  local TrackInfo = task
  if TrackInfo.isTrack then
    local MinDistance = TrackInfo.Trackers and TrackInfo.Trackers[1] and TrackInfo.Trackers[1].DistanceToPlayer
    if MinDistance then
      for _, TrackItem in ipairs(TrackInfo.Trackers) do
        if MinDistance > TrackItem.DistanceToPlayer then
          MinDistance = TrackItem.DistanceToPlayer
        end
      end
      local BaseDistance = _G.DataConfigManager:GetTaskGlobalConfig("task_distance_range").num
      if MinDistance >= 0 and MinDistance > BaseDistance then
        _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, {
          TaskId = TrackInfo.Config.id,
          IsOpenRightPanel = false,
          WorldFast = true
        })
      else
        _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
      end
    end
    TrackInfo:RemoveEventListener(self, TaskModuleEvent.ON_UPDATE_TRACK, self.CheckOpenMapTrackTask)
  end
end

function TaskModule:SetTaskList(taskList)
  self.displayTaskList = taskList
end

function TaskModule:GetTaskList()
  return self.displayTaskList
end

function TaskModule:SetTrack(taskID, isTrack, UserOperation)
  local task = self.data.TaskMap[taskID]
  if not task then
    return nil
  end
  if isTrack then
    local Changed = false
    if task and task.Config.task_class == Enum.TaskClassType.TCT_CAMPAIGN then
      task:SetTrack(true, nil, UserOperation)
    else
      for i, t in pairs(self.data.TaskMap) do
        if taskID ~= i and t.Config.task_class ~= Enum.TaskClassType.TCT_CAMPAIGN then
          local isChanged = t:SetTrack(false, nil, UserOperation)
          Changed = Changed or isChanged
        end
      end
      local isChanged = task:SetTrack(true, nil, UserOperation)
      if task.Config.task_class ~= Enum.TaskClassType.TCT_CAMPAIGN and UserOperation then
        self.UserSwitchTrackFromActivityToTask_TaskId = taskID
      else
        self.UserSwitchTrackFromActivityToTask_TaskId = 0
      end
      Changed = Changed or isChanged or UserOperation
      if Changed then
        local TrackReq = ProtoMessage.newZoneTaskTrackReq()
        task.Info.is_track = true
        TrackReq.new_track_task = taskID
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_TRACK_REQ, TrackReq, self, self.OnTaskTrackStatus, true, true)
      end
    end
  elseif not isTrack then
    local TrackReq = ProtoMessage.newZoneTaskTrackReq()
    task.Info.is_track = false
    TrackReq.new_track_task = 0
    TrackReq.curr_track_task = taskID
    task:SetTrack(false, nil, UserOperation)
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_TRACK_REQ, TrackReq, self, self.OnTaskTrackStatus, true, true)
  end
  return task
end

function TaskModule:OnUserTrack(taskID, isTrack)
  Log.Debug(taskID, isTrack and "Tracking" or "Untrack")
  return self:SetTrack(taskID, isTrack, true)
end

function TaskModule:OnTaskTrackStatus(rsp)
  if rsp and rsp.ret_info and 0 ~= rsp.ret_info.ret_code then
    Log.Debug("OnTaskTrackStatus failed: " .. rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error4)
    return
  end
end

function TaskModule:GetAllTask()
  local ret = {}
  for _, taskInfo in pairs(self.data.TaskMap) do
    table.insert(ret, taskInfo.Info)
  end
  return ret
end

function TaskModule:OnUpdateTrackingNpc(notify)
  if not RocoEnv.IS_SHIPPING then
    local Recorder = _G.TaskRecorder
    if Recorder and Recorder.bIsRecording then
      Recorder:InsertPayload(notify, "tracking_npcs")
    end
  end
  if not notify.tracking_list then
    local WasEmpty = table.isEmpty(self.ExtraTrackingInfo)
    table.clear(self.ExtraTrackingInfo)
    if not WasEmpty then
      _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_TASK_TRACK_READY)
    end
    return
  end
  local RemoveID = {}
  for ID, _ in pairs(self.ExtraTrackingInfo) do
    local Found = false
    for _, Info in ipairs(notify.tracking_list) do
      if ID == Info.task_id then
        Found = true
      end
    end
    if not Found then
      table.insert(RemoveID, ID)
    end
  end
  for _, ID in ipairs(RemoveID) do
    self.ExtraTrackingInfo[ID] = nil
  end
  local Changed = not table.isEmpty(RemoveID)
  for _, msg in pairs(notify.tracking_list) do
    local ID = msg.task_id
    if ID and 0 ~= ID then
      self.ExtraTrackingInfo[ID] = msg
      Changed = true
    end
  end
  if Changed then
    _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.ON_TASK_TRACK_READY)
  end
end

function TaskModule:GetAllTraceTask(removeHidden)
  removeHidden = removeHidden or false
  local ret = {}
  for _, taskInfo in pairs(self.data.TaskMap) do
    if taskInfo.MarkedFinished then
    elseif 0 ~= taskInfo.Config.show and removeHidden then
    else
      table.insert(ret, taskInfo)
    end
  end
  return ret
end

function TaskModule:OverwriteTrackingActivityTask(_taskId)
  self.data:OverwriteTrackingActivityTask(_taskId)
end

function TaskModule:OnCmdGetActivityTraceTask()
  return self.data:GetActivityTraceTask()
end

function TaskModule:OnCmdSwitchActivityTraceTask(_on, _taskId)
  local TaskModuleInfo = NRCModuleManager:GetModule("TaskModule")
  if TaskModuleInfo and nil ~= _on then
    self:OverwriteTrackingActivityTask(_taskId)
    _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.SwitchActivityTraceTask, _on, _taskId)
  end
end

function TaskModule:GetTrackTask()
  for _, task in pairs(self.data.TaskMap) do
    if task.TrackParentTask and task.TrackParentTask.Info and task.TrackParentTask.Info.is_track then
      return task.TrackParentTask
    elseif task.Info and task.Info.is_track then
      return task
    end
  end
  return nil
end

function TaskModule:GetDataTrackTask()
  return self.data:GetTrackTask()
end

function TaskModule:OnCmdGetTaskObjectByTaskId(TaskId)
  for _, TaskObject in pairs(self.data.TaskMap) do
    if TaskObject.Config.id == TaskId then
      return TaskObject
    end
  end
  Log.Debug("\230\178\161\230\156\137\230\137\190\229\136\176\228\187\187\229\138\161\229\175\185\229\186\148\231\154\132TaskObject")
  return nil
end

function TaskModule:OnTrackReqRsp()
end

function TaskModule:CmdTraceOpenTaskPanel(arg)
  local taskId = 30023002
  if arg then
    taskId = tonumber(arg)
  end
  if self:GetTaskByID(taskId) then
    self:OnSetTraceTaskInfo(taskId, true)
    _G.NRCModeManager:DoCmd(MagicManualModuleCmd.CmdCloseMagicManual)
    _G.NRCModeManager:DoCmd(BattlePassModuleCmd.ClosePassAwardMainPanel)
  else
    local taskConf = _G.DataConfigManager:GetTaskConf(taskId)
    local text = LuaText.task_track_error7
    if taskConf then
      local accept_condition = taskConf.accept_condition[1]
      if accept_condition then
        if accept_condition.type == Enum.TaskAcceptConditionType.TACT_LEVEL then
          text = LuaText.task_track_error5
        elseif accept_condition.type == Enum.TaskAcceptConditionType.TACT_TASK then
          text = string.format(LuaText.task_track_error8, tostring(accept_condition.data1[1]))
        elseif accept_condition.type == Enum.TaskAcceptConditionType.TACT_ITEM then
          text = string.format(LuaText.task_track_error9)
        elseif accept_condition.type == Enum.TaskAcceptConditionType.TACT_DIALOGUE then
          local dialogConf = _G.DataConfigManager:GetDialogueConf(accept_condition.data1[1])
          text = string.format(LuaText.task_track_error10, dialogConf.name)
        end
      end
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  end
end

function TaskModule:CmdTraceOpenPetPanel()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, true)
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    Callback = self.SetPetTeamHid,
    Caller = self
  }, true)
end

function TaskModule:CmdTraceOpenTravelPanel()
  _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenTravelMainMap, nil, true)
end

function TaskModule:CmdTraceOpenFriendPanel()
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenMainPanel)
end

function TaskModule:CmdTraceOpenActivityPanel(arg)
  if arg then
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenMainPanel, tonumber(arg))
  else
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenMainPanel, Enum.ActivityType.ATP_LEGENDARY_BATTLE_EVENT)
  end
end

function TaskModule:OnCmdOpenSeasonTaskPanel(entry_map_id)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_TASK, true) or _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TASK_TEXT, true) or _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TASK, true)
  if isBan then
    return
  end
  
  local function TryOpenWorldMap()
    if entry_map_id then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(tonumber(entry_map_id))
      local npc_refresh_id = worldMapConf and worldMapConf.npc_refresh_ids and worldMapConf.npc_refresh_ids[1]
      local npcData = 0 ~= npc_refresh_id and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, npc_refresh_id)
      if npcData then
        _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap, {centerNPCRefreshId = npc_refresh_id})
      elseif _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.visitor_state_season_slot_skip_unsuccess_tips)
      end
    end
  end
  
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  local seasonId = seasonInfo and seasonInfo.season_id
  local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
  local season_start_task = {}
  if seasonConf then
    season_start_task = seasonConf.season_start_task
    Log.Debug("TaskModule:OnCmdOpenSeasonTaskPanel season_start_task", season_start_task[1])
  end
  for _, taskInfo in pairs(self.data.TaskMap) do
    local cfg = taskInfo.Config
    local ParagraphConf = 0 ~= cfg.paragraph_id and _G.DataConfigManager:GetParagraphConf(cfg.paragraph_id) or {}
    if ParagraphConf and ParagraphConf.season_task and cfg.is_para_start and taskInfo.Info.id ~= season_start_task[1] then
      Log.Debug("TaskModule:OnCmdOpenSeasonTaskPanel TaskMap has season_start_task[1], id = %d state = %d message_id = %d", taskInfo.Info.id, taskInfo.Info.state, cfg.message_id)
      if taskInfo.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        if entry_map_id then
          TryOpenWorldMap()
          return
        end
      elseif taskInfo.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN or taskInfo.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        if cfg.message_id and 0 ~= cfg.message_id then
          self:lookLetter(cfg.message_id)
          return
        elseif entry_map_id then
          TryOpenWorldMap()
          return
        end
      end
    end
  end
  TryOpenWorldMap()
end

function TaskModule:OnCmdLookSeasonTaskLetter()
  local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
  local seasonId = seasonInfo and seasonInfo.season_id
  local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
  local season_start_task = {}
  if seasonConf then
    season_start_task = seasonConf.season_start_task
    Log.Debug("TaskModule:OnCmdLookSeasonTaskLetter season_start_task", season_start_task[1])
  end
  for _, taskInfo in pairs(self.data.TaskMap) do
    local cfg = taskInfo.Config
    local ParagraphConf = 0 ~= cfg.paragraph_id and _G.DataConfigManager:GetParagraphConf(cfg.paragraph_id) or {}
    if ParagraphConf and ParagraphConf.season_task and cfg.is_para_start and taskInfo.Info.id == season_start_task[1] then
      Log.Debug("TaskModule:OnCmdLookSeasonTaskLetter TaskMap has season_start_task[1], id = %d state = %d message_id = %d", taskInfo.Info.id, taskInfo.Info.state, cfg.message_id)
      if taskInfo.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN or taskInfo.Info.state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        self:lookLetter(cfg.message_id)
        return
      end
    end
  end
end

function TaskModule:GetMainTask(removeHidden)
  removeHidden = removeHidden or false
  for _, taskInfo in pairs(self.data.TaskMap) do
    local cfg = taskInfo.Config
    if cfg.task_class == Enum.TaskClassType.TCT_MAIN and (0 == cfg.show or 1 == cfg.show and not removeHidden) then
      return taskInfo.Info, cfg
    end
  end
end

function TaskModule:CheckEvolutionTask(_taskId)
  for _, taskInfo in pairs(self.data.TaskMap) do
    if taskInfo.id == _taskId then
      return true
    end
  end
  return false
end

function TaskModule:GetTaskByID(id)
  if not id then
    return nil
  end
  if 0 == id then
    return nil
  end
  if not self.data then
    return nil
  end
  if not self.data.TaskMap then
    return nil
  end
  for _, taskObj in pairs(self.data.TaskMap) do
    if taskObj.Info.id == id then
      return taskObj.Info
    end
  end
  return nil
end

function TaskModule:GetHiddenTaskByID(id)
  if not id then
    return nil
  end
  if 0 == id then
    return nil
  end
  if not self.data then
    return nil
  end
  if not self.data.HiddenTaskMap then
    return nil
  end
  for _, taskState in pairs(self.data.HiddenTaskMap) do
    if _ == id then
      return taskState
    end
  end
  return nil
end

function TaskModule:OnCmdGetTaskDistanceByID(id, index)
  if not id then
    return nil
  end
  if 0 == id then
    return nil
  end
  if not self.data then
    return nil
  end
  if not self.data.TaskMap then
    return nil
  end
  local SceneModule = TaskUtils:getSceneModule()
  local CurrentMapID
  if SceneModule then
    CurrentMapID = SceneModule.mapResId
  end
  for _, taskObj in pairs(self.data.TaskMap) do
    if taskObj.Info.id == id then
      local Trackers = taskObj:GetTracker(index)
      if not Trackers then
        if not Trackers then
          Log.Debug(id, index, "TaskModule:OnCmdGetTaskDistanceByID")
          return nil
        end
        return nil, nil, Trackers
      end
      if Trackers.TaskObject:IsTrack() and Trackers.TargetInSameSceneGroup and Trackers.Valid then
        local MinDistance = Trackers and Trackers.DistanceToPlayer or 0
        local DirectionSign = Trackers and Trackers.DirectionSign
        return math.round(MinDistance / 100), DirectionSign, Trackers
      end
      local Pos = Trackers:GetPosBySceneID(CurrentMapID)
      if Pos then
        Trackers:UpdateDistance()
        local MinDistance = Trackers and Trackers.DistanceToPlayer or 0
        local DirectionSign = Trackers and Trackers.DirectionSign
        return math.round(MinDistance / 100), DirectionSign, Trackers
      end
    end
  end
  return nil
end

function TaskModule:GetTaskMap()
  return self.data.TaskMap
end

function TaskModule:GetParagraphCfgByTaskId(taskId)
  local taskCfg = _G.DataConfigManager:GetTaskConf(taskId)
  return _G.DataConfigManager:GetParagraphConf(taskCfg.paragraph_id)
end

function TaskModule:GetChapterCfgByTaskId(taskId)
  local taskCfg = _G.DataConfigManager:GetTaskConf(taskId)
  return _G.DataConfigManager:GetChapterConf(taskCfg.chapter_id)
end

function TaskModule:_RegisterNotify()
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY, self._OnTaskInfoNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BOOK_DATA_CHANGE_NTY, self.OnLegendaryTaskUnlockNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_RANDOM_SUB_TASK_NOTIFY, self.OnRandomSubTaskNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_COMMON_TIPS_NOTIFY, self.OnSceneCommonTipsNotify)
end

function TaskModule:OnDestruct()
  if self.getLegendaryTaskTipsController then
    self.getLegendaryTaskTipsController:Free()
    self.getLegendaryTaskTipsController = nil
  end
  if self.getTaskSummaryTipsController then
    self.getTaskSummaryTipsController:Free()
    self.getTaskSummaryTipsController = nil
  end
  if self.getReturnRewardTipsController then
    self.getReturnRewardTipsController:Free()
    self.getReturnRewardTipsController = nil
  end
end

function TaskModule:OnDeactive()
  self:CleanTimerHandle()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAckCallBack)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.BigWorldPrepared, self.OnBigWorldReload)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.OnWorldPetCatchFinish, self.OnWorldPetCatchFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, PlayerModuleEvent.BattleOver, self.OnBattleOverOther)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_BOOK_DATA_CHANGE_NTY, self.OnLegendaryTaskUnlockNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_RANDOM_SUB_TASK_NOTIFY, self.OnRandomSubTaskNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY, self._OnTaskInfoNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_COMMON_TIPS_NOTIFY, self.OnSceneCommonTipsNotify)
  if self.data then
    self.data:Clear()
  end
  self.SubTaskIDs = nil
end

function TaskModule:_OnTaskInfoNotify(rsp)
  local isFull = 1 == rsp.is_all_activity_task
  local hasUpdate = isFull
  hasUpdate = self.data:_RemoveTaskInfos(rsp.delete_task_list) or hasUpdate
  hasUpdate = self.data:_UpdateTaskInfos(rsp.task_info_list, isFull) or hasUpdate
  self.data.first = false
  local hasCountChange = false
  if rsp.open_task_num then
    hasCountChange = self.data.OpenTaskCount ~= (rsp.open_task_num or 0) or hasCountChange
    self.data.OpenTaskCount = rsp.open_task_num or 0
  end
  if rsp.guiding_task_num then
    hasCountChange = self.data.GuideTaskCount ~= (rsp.guiding_task_num or 0) or hasCountChange
    self.data.GuideTaskCount = rsp.guiding_task_num or 0
  end
  if hasUpdate or hasCountChange then
    self.data:CalcSubTrackTasks()
    self.data:MakeDirty()
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ProcessRetInfo, ProtoCMD.ZoneSvrCmd.ZONE_TASK_INFO_NOTIFY, ProtoMessage:newRetInfo())
    self:PostTaskUpdate(rsp.task_info_list)
    self:SetTrackTaskInfo(rsp.task_info_list)
  end
  self:OnCheckIsUpdateParagraph(rsp.task_info_list)
end

function TaskModule:OnCheckIsUpdateParagraph(taskList)
  if not taskList then
    return
  end
  if self:HasPanel("TaskMainPanel") then
    local task
    for _, taskInfo in pairs(taskList) do
      if taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        task = taskInfo
        break
      end
    end
    if not task then
      return
    end
    local conf = _G.DataConfigManager:GetTaskConf(task.id)
    if not conf then
      return
    end
    if not conf.next_task or 0 == #conf.next_task then
      self:OnCmdTaskPanelAllInfoReq(true)
    end
  end
end

function TaskModule:OnRefreshTaskMainPanel()
  if self:HasPanel("TaskMainPanel") then
    local tabIndex = self.data:GetSelectTaskTabIndex()
    self:DispatchEvent(TaskModuleEvent.OnRefreshTaskMainPanel, tabIndex)
  end
end

function TaskModule:UpdateTrackerInfo(TaskTrackInfo)
  if not TaskTrackInfo then
    return
  end
  local TrackInfo = TaskTrackInfo
  if TrackInfo.TaskObject.TrackParentTask and TrackInfo.TaskObject.TrackParentTask.isTrack or TrackInfo.TaskObject.isTrack then
    local MinDistance = TaskTrackInfo.DistanceToPlayer
    local WasInDungeon = TaskTrackInfo.WasInDungeon
    local TaskId
    if TrackInfo.TaskObject.TrackParentTask and TrackInfo.TaskObject.TrackParentTask.isTrack then
      TaskId = TrackInfo.TaskObject.TrackParentTask.Config.id
    else
      TaskId = TrackInfo.TaskConfig.id
    end
    if MinDistance then
      local BaseDistance = _G.DataConfigManager:GetTaskGlobalConfig("task_distance_range").num
      if WasInDungeon then
        _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, {
          TaskId = TaskId,
          IsOpenRightPanel = false,
          WorldFast = true
        })
      elseif MinDistance >= 0 then
        if MinDistance > BaseDistance then
          _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, {
            TaskId = TaskId,
            IsOpenRightPanel = false,
            WorldFast = true
          })
        elseif self:HasPanel("TaskMainPanel") then
          local panel = self:GetPanel("TaskMainPanel")
          panel:OnClickBtnClose(true)
        end
      else
        local panel = self:GetPanel("TaskMainPanel")
        if panel then
          panel:OnClickBtnClose(true)
        end
      end
    else
      local panel = self:GetPanel("TaskMainPanel")
      if panel then
        panel:OnClickBtnClose(true)
      end
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.check_task_info, 1)
    end
    TaskTrackInfo:RemoveEventListener(self, TaskModuleEvent.ON_TASK_TRACK_SCENE_NPC_REFRESH, self.UpdateTrackerInfo)
  end
end

function TaskModule:SetTrackTaskInfo(task_info_list)
  if self:HasPanel("TaskMainPanel") then
    local taskList = {}
    for i, task in ipairs(task_info_list) do
      local taskConfig = _G.DataConfigManager:GetTaskConf(task.id)
      if taskConfig and (taskConfig.task_class == Enum.TaskClassType.TCT_JOURNEY or taskConfig.task_class == Enum.TaskClassType.TCT_MAIN or taskConfig.task_class == Enum.TaskClassType.TCT_SUB) then
        table.insert(taskList, task)
      end
    end
    if 0 == #taskList then
      return
    end
    if not self.IsClickTrackBtn then
      self:SetTaskListInfo(taskList)
    end
    for i, task in ipairs(taskList) do
      if task.is_track then
        self.OpenTask = task
      end
      self:DispatchEvent(TaskModuleEvent.SetTrackTaskState, task.id)
    end
    self.IsClickTrackBtn = false
  end
end

function TaskModule:SetTrackTaskFromRsp(task_info_list)
  if not self.IsClickTrackBtn then
    task_info_list = self:RemoveHiddenTask(task_info_list)
    self.data:SetTaskList(task_info_list)
    self.data:SetMailTask(nil)
    self.data:SetOpenTask(task_info_list[1])
    if task_info_list[1].state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      local TaskConf = _G.DataConfigManager:GetTaskConf(task_info_list[1].id)
      self.data:SetOpenTask(task_info_list[1])
      self.data:SetMailTask(TaskConf)
    elseif task_info_list[2].state == ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
      local TaskConf = _G.DataConfigManager:GetTaskConf(task_info_list[2].id)
      self.data:SetOpenTask(task_info_list[2])
      self.data:SetMailTask(TaskConf)
    end
  end
  self:SetGleaningsLacquer()
  self.IsClickTrackBtn = false
end

function TaskModule:PostTaskUpdate(task_list)
  _G.NRCEventCenter:DispatchEvent(_G.TaskModuleEvent.TaskChangeNotify, task_list)
  self:TriggerSequences()
end

function TaskModule:TriggerSequences()
  local PendingTask
  for _, Task in pairs(self.data.TaskMap) do
    if Task:HasPendingAction() then
      if PendingTask then
        if Task:IsInActionArea() and not PendingTask:IsInActionArea() then
          Log.Debug("[TaskFlow] Replacing Pending Task", PendingTask.Config.id, Task.Config.id)
          PendingTask = Task
          break
        end
      else
        PendingTask = Task
      end
    end
  end
  if PendingTask == self.PendingActionTask then
    Log.Debug("[TaskFlow] Pending Task is the same as the last one")
    return false
  end
  if PendingTask then
    local Checker = self.StatusChecker:FindChecker(StatusCheckerEnum.TaskInArea)
    if Checker then
      Checker:BindTask(PendingTask)
    end
    self.StatusChecker:Check(PendingTask, PendingTask.ExecutePendingAction)
    return false
  end
  return true
end

function TaskModule:MarkPendingTask(Task)
  if self.PendingActionTask == Task then
    return
  end
  if self.PendingActionTask then
    Log.Error("\229\183\178\231\187\143\230\156\137\228\184\128\228\184\170PendingTask\228\186\134", self.PendingActionTask.Config.id)
    return
  end
  Log.Trace("[TaskFlow]Mark Pending Task", Task.Config.id)
  self.PendingActionTask = Task
end

function TaskModule:ClearPendingTask(Task)
  if not self.PendingActionTask then
    return
  end
  if not Task then
    return
  end
  if Task ~= self.PendingActionTask then
    Log.Error("[TaskFlow] Pending Task Error", Task.Config.id)
    return
  end
  Log.Debug("[TaskFlow] Clean up current pending sequence task")
  self.PendingActionTask = nil
end

function TaskModule:MarkAsTeleportingTask(Task)
  if Task == self.TeleportingTask then
    return
  end
  if self.TeleportingTask then
    Log.Error("[TaskFlow] \229\183\178\231\187\143\230\156\137\228\184\128\228\184\170TeleportingTask\228\186\134", self.TeleportingTask.Config.id)
    return
  end
  Log.Debug("[TaskFlow] Mark Teleporting Task", Task.Config.id)
  self.TeleportingTask = Task
end

function TaskModule:ClearTeleportingTask(Task)
  if not self.TeleportingTask then
    return
  end
  if not Task then
    return
  end
  if Task ~= self.TeleportingTask then
    return
  end
  Log.Debug("[TaskFlow] Clean up current teleporting task", Task.Config.id)
  self.TeleportingTask = nil
end

function TaskModule:OnBigWorldReload()
  Log.Debug("[TaskFlow] OnBigWorldReload will trigger sequences")
  self:TriggerSequences()
end

function TaskModule:OnDisconnect()
  if not self.PendingActionTask then
    return
  end
  local PendingTask = self.PendingActionTask
  self.PendingActionTask = nil
  local Conf = PendingTask and PendingTask.Config
  Log.Debug("[TaskFlow] OnDisconnect clear pending task", Conf and Conf.id or "nil")
end

function TaskModule:OnLeaveVisit()
  Log.Debug("[TaskFlow] OnLeaveVisit revoke task areas")
  for _, Task in pairs(self.data.TaskMap) do
    Task:RevokeActionArea()
  end
end

function TaskModule:OnBattleOver()
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.BattleOver)
end

function TaskModule:GetTaskNPCInfo(TaskID)
  if not self.ExtraTrackingInfo then
    return nil
  end
  local Item = self.ExtraTrackingInfo[TaskID]
  if not Item then
    return nil
  end
  return Item
end

function TaskModule:OnEnterSceneFinishNtyAckCallBack(notify, isReconnecting, isEnteringCell)
  if not isEnteringCell and self.SummaryTaskId then
    self:OnCmdGetTaskSummaryData(self.SummaryTaskId)
  end
end

function TaskModule:OnCmdGetTaskSummaryData(task_id)
  if not _G.ZoneServer:CanSendNetworkCmd() then
    self.SummaryTaskId = task_id
  else
    local req = ProtoMessage.newZoneGetTaskSummaryReq()
    req.task_id = task_id
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_TASK_SUMMARY_REQ, req, self, self.GetTaskSummaryDataRsp, true, true)
    self.SummaryTaskId = nil
  end
end

function TaskModule:GetTaskSummaryDataRsp(rsp)
  if 0 == not rsp.ret_info.ret_code then
    return
  end
  Log.Dump(rsp, 6, "TaskModule:GetTaskSummaryDataRsp")
  local uiData = rsp.data
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateTaskSummaryTips(uiData))
end

function TaskModule:OnPlayTaskSummaryTips(tip)
  self:OnCmdOpenTaskPhoto(tip)
end

function TaskModule:OnCmdOpenTaskPhoto(tip)
  if self:HasPanel("TaskSummary_GroupPhoto") then
    self:ClosePanel("TaskSummary_GroupPhoto")
    return
  end
  self:OpenPanel("TaskSummary_GroupPhoto", tip)
end

function TaskModule:OnPlayReturnRewardTips(tip)
  self:OnCmdReturnRewardPanel(tip)
end

function TaskModule:OnCmdReturnRewardPanel(tip)
  if self:HasPanel("ReturnRewardPanel") then
    self:ClosePanel("ReturnRewardPanel")
  end
  self:OpenPanel("ReturnRewardPanel", tip)
end

function TaskModule:OnCmdGetTaskSummaryByTaskId(task_id)
  if nil == task_id then
    return
  end
  local TaskConf = _G.DataConfigManager:GetTaskConf(task_id)
  if nil == TaskConf then
    Log.ErrorFormat("Invalid task_id(%s).", tostring(task_id))
    return
  end
  local request_task_id = task_id
  local bParaLastTask = TaskConf.is_para_done
  local bTaskDone = self.data:FindTask(function(taskInfo)
    return taskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE
  end)
  if bParaLastTask and bTaskDone then
    local summary_id = task_id
    local TaskSummaryConf = _G.DataConfigManager:GetTaskSummary(summary_id, true)
    if nil == TaskSummaryConf then
    else
      request_task_id = TaskSummaryConf.show_paragraph
    end
  end
  local req = ProtoMessage.newZoneGetTaskSummaryReq()
  req.task_id = request_task_id
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GET_TASK_SUMMARY_REQ, req, self, self.OnCmdGetTaskSummaryByTaskIdRsp, true, true)
end

function TaskModule:OnCmdGetTaskSummaryByTaskIdRsp(rsp)
  if 0 == not rsp.ret_info.ret_code then
    return
  end
  local uiData
  if rsp.data and self:HasPanel("TaskMainPanel") then
    local Panel = self:GetPanel("TaskMainPanel")
    uiData = TipObject.CreateTaskSummaryTips(rsp.data)
  end
  self:DispatchEvent(TaskModuleEvent.NotOpenParagraph, true)
  self:SetGleaningsLacquer(uiData)
end

function TaskModule:GetDependsRes()
  local ResListData = _G.NRCPanelResLoadData()
  ResListData.PreLoadResList = {}
  return ResListData
end

function TaskModule:OnCmdSetDefaultSuit(PlayerActor, gender, fashionItems, salonIds, PanelName)
  local defaultSuitClass
  if 2 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  else
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  if salonIds and #salonIds > 0 then
    local salonWearIds = {}
    for k, v in ipairs(salonIds) do
      if v and v.item_wear_id and 0 ~= v.item_wear_id then
        local SalonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        local avatarId = SalonItemConf.avatar_id
        local colorId = SalonItemConf.texture_id
        local fullSalonId = self:GetFullSalonId(avatarId, colorId)
        table.insert(salonWearIds, fullSalonId)
      end
    end
    defaultSuitObj:SetSalons(salonWearIds)
  end
  if fashionItems and #fashionItems > 0 then
    for k, v in pairs(fashionItems) do
      if v and 0 ~= v.wearing_item_id then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v.wearing_item_id)
        if fashionItemConf then
          local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
          if bBodyType then
            defaultSuitObj:SetBody(v.wearing_item_id, 0)
          else
            defaultSuitObj:SetBody(v.wearing_item_id, 0)
          end
        else
          Log.Error("fashion\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
  local CardPlayer = PlayerActor
  if CardPlayer then
    local mesh = CardPlayer:GetComponentByClass(UE4.USkeletalMeshComponent)
    self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    if self.avatarSystem.OnSwitchAvatarSuitComplete then
      self.avatarSystem.OnSwitchAvatarSuitComplete:Add(self.avatarSystem, self.RecoverAllStatus)
    end
    self.ID = self.avatarSystem:StartSwitchAvatarSuit(mesh, defaultSuitObj)
  else
    Log.Error("\230\139\141\231\133\167\228\186\186\231\137\169\231\148\159\230\136\144\229\164\177\232\180\165")
  end
end

function TaskModule:RecoverAllStatus(ID)
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.StarLightPlayerPlayAnimAtFrame)
  local TaskModuleInfo = NRCModuleManager:GetModule("TaskModule")
  if TaskModuleInfo and ID == TaskModuleInfo.ID then
    TaskModuleInfo:DispatchEvent(TaskModuleEvent.SwitchAvatarSuitComplete)
    TaskModuleInfo.ID = nil
    TaskModuleInfo.avatarSystem.OnSwitchAvatarSuitComplete:Remove(TaskModuleInfo.avatarSystem, TaskModuleInfo.RecoverAllStatus)
    TaskModuleInfo.avatarSystem = nil
  end
end

function TaskModule:GetFullSalonId(configId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = configId * 100 + colorIndex
  return fullSalonId
end

local WhiteListStatus = {
  [Enum.SpaceActorLogicStatus.SALS_DUNGEON_FINISH] = true,
  [Enum.SpaceActorLogicStatus.SALS_FASHION_SUITS] = true,
  [Enum.SpaceActorLogicStatus.SALS_PLAYER_IDLE] = true,
  [Enum.SpaceActorLogicStatus.SALS_NIGHT_MODE] = true,
  [Enum.SpaceActorLogicStatus.SALS_DUNGEON] = true,
  [Enum.SpaceActorLogicStatus.SALS_NORMAL] = true
}
local WhiteListCount = table.len(WhiteListStatus)

function TaskModule:CheckPlayerStatus()
  if not self.PlayerStatusChecker then
    self.PlayerStatusChecker = StatusCheckerGroup({
      StatusCheckerEnum.FastLoading,
      StatusCheckerEnum.Dialogue,
      StatusCheckerEnum.Cinematic,
      StatusCheckerEnum.MainPanel,
      StatusCheckerEnum.Battle,
      StatusCheckerEnum.FullScreen,
      StatusCheckerEnum.Teleport
    }, Log.LOG_LEVEL.ELogError)
  end
  if not self.PlayerStatusChecker:CheckPass() then
    return false
  end
  local State = _G.SceneModuleCmd and _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.CheckSceneFullyEntered) or false
  if not State then
    Log.Error("cell not entered")
    return false
  end
  local PanelCount = _G.NRCPanelManager:GetLoadingPanelCount()
  if PanelCount > 0 then
    Log.Error("has loading panel", PanelCount)
    return false
  end
  local PlayerData = _G.DataModelMgr.PlayerDataModel
  if not PlayerData then
    Log.Error("no player data model")
    return false
  end
  local Visiting = PlayerData:IsVisitState()
  if Visiting then
    Log.Error("player visiting...")
    return false
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    Log.Error("player not found")
    return false
  end
  local InterComp = Player.interactionComponent
  if not InterComp then
    Log.Error("player has no interaction component")
    return false
  end
  local Interacting = InterComp:HasInteractingAction()
  if Interacting then
    Log.Error("player is interacting")
    return false
  end
  local HPComp = Player.roleHPComponent
  if not HPComp then
    Log.Error("player has no hp component")
    return false
  end
  if 0 == HPComp:GetRoleHP() then
    Log.Error("player is about to die")
    return false
  end
  local LogicComp = Player.LogicStatusComponent
  if not LogicComp then
    Log.Error("player logic status not found")
    return false
  end
  local StatusInfo = LogicComp.StatusInfo
  if not StatusInfo then
    Log.Error("player logic status invalid")
    return false
  end
  local StatusCount = #StatusInfo
  if StatusCount > WhiteListCount then
    Log.Error("player logic status invalid")
    return false
  end
  for Index, Info in ipairs(StatusInfo) do
    if not WhiteListStatus[Info.status] then
      Log.Error("player does not have normal status", Index, table.getKeyName(Enum.SpaceActorLogicStatus, Info.status))
      return false
    end
  end
  local PlayerView = Player and Player.viewObj
  if not PlayerView or not UE.UObject.IsValid(PlayerView) then
    Log.Error("player has not view obj")
    return false
  end
  local MoveComp = PlayerView.CharacterMovement
  if not MoveComp or not UE.UObject.IsValid(MoveComp) then
    Log.Error("player has no character movement component")
    return false
  end
  if MoveComp.MovementMode == UE4.EMovementMode.MOVE_Falling then
    Log.Error("player is falling")
    return false
  end
  return true
end

function TaskModule:CheckTaskStatus(TaskID)
  if not self.data then
    return false
  end
  if not self.data.TaskMap then
    return false
  end
  if not TaskID or 0 == TaskID then
    return false
  end
  local Task = self.data.TaskMap[TaskID]
  if not Task then
    Log.Error("\230\178\161\230\156\137\230\173\164\228\187\187\229\138\161\230\149\176\230\141\174", TaskID)
    return false
  end
  if not Task.Info then
    Log.Error("\230\178\161\230\156\137\230\173\164\228\187\187\229\138\161\231\154\132\229\144\142\229\143\176\230\149\176\230\141\174", TaskID)
    return false
  end
  if Task.Info.state ~= ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN then
    Log.Error("\230\178\161\230\156\137\230\173\164\228\187\187\229\138\161\230\149\176\230\141\174", TaskID)
    return false
  end
  local OldEnough = Task:IsOldEnough(20000.0)
  if not OldEnough then
    Log.Error("\228\187\187\229\138\161\232\191\152\228\184\141\229\164\159\232\128\129", TaskID)
    return false
  end
  return true
end

function TaskModule:TogglePlayerInput(Enable)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player.inputComponent:SetInputEnable(self, Enable, "Task")
  end
  if Enable then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.CloseInputBlocker, "Task")
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.OpenInputBlocker, "Task")
  end
  if Enable then
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnReceiveDisconnect)
  else
    _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnReceiveDisconnect)
  end
end

function TaskModule:OnReceiveDisconnect()
  self:TogglePlayerInput(true)
end

function TaskModule:ShowDialogue(Callback)
  if self.PopSession then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.general_try_again)
    return
  end
  local PopSession = DialogContext()
  PopSession:SetTitle(LuaText.general_title)
  PopSession:SetContent(LuaText.task_manual_teleport_confirm)
  PopSession:SetButtonText(LuaText.general_confirm, LuaText.general_cancel)
  PopSession:SetMode(DialogContext.Mode.OK_CANCEL)
  PopSession:SetClickAnywhereClose(true)
  PopSession:SetCallback(self, function(self, OK)
    self.PopSession = nil
    Callback(OK)
  end)
  self.PopSession = PopSession
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, PopSession)
end

function TaskModule:HasActionType(ActionList, ActionType)
  if not ActionList then
    return false
  end
  for _, Action in ipairs(ActionList) do
    if Action.type == ActionType then
      return true
    end
  end
  return false
end

function TaskModule:CheckVisitDungeonBlock(TaskID)
  local PlayerData = _G.DataModelMgr.PlayerDataModel
  if not PlayerData then
    return false
  end
  if not PlayerData:IsVisitState() then
    return false
  end
  local TaskConf = _G.DataConfigManager:GetTaskConf(TaskID)
  if not TaskConf then
    return false
  end
  if TaskConf.task_structure_type ~= Enum.TaskStructureType.TSTT_TELEPORT then
    return false
  end
  local DungeonType = Enum.TaskStateChangeActionType.TSCAT_ENTER_DUNGEON
  if not self:HasActionType(TaskConf.accept_action, DungeonType) and not self:HasActionType(TaskConf.finish_action, DungeonType) then
    return false
  end
  if not self.bCanRefreshEnter then
    return true
  end
  self.bCanRefreshEnter = false
  local CurDialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = CurDialogContext()
  Context:SetTitle(LuaText.updateuimodule_26):SetContent(LuaText.task_enter_dungeon_note or ""):SetMode(CurDialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
    if result then
      _G.NRCModuleManager:DoCmd(FriendModuleCmd.CmdZoneDisbandVisitReq)
    else
      self.RefreshEnterHandleID = _G.DelayManager:DelaySeconds(10, function()
        self.bCanRefreshEnter = true
      end)
    end
  end):SetButtonText(LuaText.worldcombatmodule_1, LuaText.worldcombatmodule_2)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  return true
end

function TaskModule:SafeSwitchScene(TaskID)
  if not self:CheckTaskStatus(TaskID) or not self:CheckPlayerStatus() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.TASK_GUARANTEEDTELENOTE)
    return
  end
  if self:CheckVisitDungeonBlock(TaskID) then
    return
  end
  self:ShowDialogue(function(OK)
    self:SendSwitchScene(OK, TaskID)
  end)
end

function TaskModule:SendSwitchScene(OK, TaskID)
  if not OK then
    return
  end
  if not self:CheckTaskStatus(TaskID) or not self:CheckPlayerStatus() then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.TASK_GUARANTEEDTELENOTE)
    return
  end
  if self:CheckVisitDungeonBlock(TaskID) then
    return
  end
  self:TogglePlayerInput(false)
  local Req = _G.ProtoMessage:newZoneTaskTeleportReq()
  Req.teleport_type = Enum.TaskTeleportType.TTT_BIG_WORLD
  Req.task_id = TaskID
  local Success = _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_TELEPORT_REQ, Req, self, self.OnSwitchSceneRsp, true, false)
  if not Success then
    self:TogglePlayerInput(true)
  end
end

function TaskModule:OnSwitchSceneRsp(Rsp)
  self:TogglePlayerInput(true)
end

function TaskModule:TryParseStringArgs(RawArgs)
  if nil == RawArgs then
    return nil
  end
  return rapidjson.decode(RawArgs)
end

function TaskModule:OnClientPublicCmd(RawID, ...)
  local Args = select(1, ...)
  if not RawID then
    Log.Error("TaskModule:OnClientPublicCmd \230\148\182\229\136\176ID\228\184\186nil")
    return
  end
  local ID = tonumber(RawID) or 0
  if 0 == ID then
    Log.ErrorFormat("TaskModule:OnClientPublicCmd \230\148\182\229\136\176ID\228\184\1860\230\136\150\232\128\133\230\151\160\230\179\149\232\167\163\230\158\144:%s", tostring(RawID))
    return
  end
  local Conf = _G.DataConfigManager:GetClientPublicCmd(ID)
  if not Conf then
    Log.ErrorFormat("TaskModule:OnClientPublicCmd \230\148\182\229\136\176ID\228\184\186%s\231\154\132\229\145\189\228\187\164\228\184\141\229\173\152\229\156\168", tostring(RawID))
    return
  end
  local Cmd = Conf.text
  local Arg1 = Conf.param1
  local Arg2 = Conf.param2
  Log.DebugFormat("[TaskFlow]OnClientPublicCmd:%s,%s,%s", Cmd, Arg1, Arg2)
  _G.NRCModuleManager:DoCmd(Cmd, self:TryParseStringArgs(Arg1), self:TryParseStringArgs(Arg2), ...)
end

function TaskModule:GetTrackerPosBySceneID(TaskID, SceneID)
  if self.data then
    local TaskObject = self.data.TaskMap[TaskID]
    if TaskObject then
      return TaskObject:GetTrackerPosBySceneID(SceneID)
    end
  end
end

function TaskModule:GetTrackerPos(TaskID)
  if self.data then
    local TaskObject = self.data.TaskMap[TaskID]
    if TaskObject then
      return TaskObject:GetTrackerPos()
    end
  end
end

function TaskModule:OnCmdTriggerTaskCondition(task_id, task_condition_index, condition_type)
  local Req = ProtoMessage:newZoneTaskConditionTriggerReq()
  Req.taskid = task_id
  Req.task_condition_index = task_condition_index
  Req.condition_type = condition_type
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_CONDITION_TRIGGER_REQ, Req, self, self.OnTaskConditionTriggerRsp, false, false)
end

function TaskModule:OnTaskConditionTriggerRsp(rsp)
end

function TaskModule:CleanTimerHandle()
  if self.RefreshEnterHandleID then
    _G.DelayManager:CancelDelayById(self.RefreshEnterHandleID)
    self.RefreshEnterHandleID = nil
  end
end

function TaskModule:PlayTaskImageFlow(InParam)
  if self:IsImageFlowPlaying() then
    return
  end
  local Conf = _G.DataConfigManager:GetSlideConf(InParam.ImageFlowID, true)
  if not Conf then
    Log.Debug("TaskModule:PlayTaskImageFlow \230\151\160\230\179\149\230\137\190\229\136\176ImageFlowID", InParam.ImageFlowID)
    return
  end
  self:OpenPanel("ImageFlowPanel", InParam)
end

function TaskModule:UpdateImageFlowState(bIsPlaying)
  if self.bIsImageFlowPlaying == bIsPlaying then
    return
  end
  self.bIsImageFlowPlaying = bIsPlaying
end

function TaskModule:IsImageFlowPlaying()
  return self.bIsImageFlowPlaying
end

function TaskModule:OnCmdUpdateGuideTask(Notify)
  if not Notify then
    return
  end
  if not Notify.guide_list then
    self.data:UpdateAcceptTaskList({})
    return
  end
  self.data:UpdateAcceptTaskList(Notify.guide_list)
end

function TaskModule:GetAcceptTaskList()
  return self.data:GetAcceptTaskList()
end

function TaskModule:GetParagraphType(ParagraphID)
  local ParagraphData = self:GetParagraphDataByID(ParagraphID)
  if ParagraphData then
    if ParagraphData.Type == TaskEnum.TaskParagraphFinishState.done then
      return TaskEnum.TaskParagraphFinishState.done
    else
      return TaskEnum.TaskParagraphFinishState.open
    end
  end
  return TaskEnum.TaskParagraphFinishState.notStart
end

function TaskModule:CheckTaskPetFollow()
  local PetTogetherTaskInfos = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTaskInfo()
  if PetTogetherTaskInfos and next(PetTogetherTaskInfos) then
    local TempNotify = {
      gid = nil,
      pet_status_flags = nil,
      task_id = nil
    }
    for _, PetTogetherTaskInfo in ipairs(PetTogetherTaskInfos) do
      TempNotify.gid = PetTogetherTaskInfo.gid
      TempNotify.pet_status_flags = -1
      TempNotify.task_id = PetTogetherTaskInfo.task_id
      self:OnPetTogetherTaskNotify(TempNotify)
    end
  end
end

function TaskModule:OnPetTogetherTaskNotify(Notify)
  if not _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") then
    _G.NRCModuleManager:ActiveModule("TaskPetFollowModule")
  end
  _G.NRCModeManager:DoCmd(_G.TaskPetFollowModuleCmd.OnPetTogetherTaskNotify, Notify)
end

function TaskModule:OnSceneCommonTipsNotify(Notify)
  if Notify then
    if Notify.source == ProtoEnum.CommonTipsSource.CTS_COMBINE_NPC then
      local LocalizationConf = DataConfigManager:GetLocalizationConf(Notify.localization_id)
      if not LocalizationConf then
        return
      end
      local tip = LocalizationConf.msg
      Log.Debug("TaskModule:OnSceneCommonTipsNotify tip=", tip)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip, nil, nil, 3)
    elseif Notify.source == ProtoEnum.CommonTipsSource.CTS_PET_REPORT_LIMIT then
      self.CatchPetTipID = Notify.localization_id
      local bImmediateShow = true
      if Notify.param_list then
        for _, param in ipairs(Notify.param_list) do
          if not self.TipsReason[param] then
            if param == _G.ProtoEnum.FlowReason.FLOW_REASON_SCENE_CATCH_PET then
              bImmediateShow = false
              self:_CancelCatchPetFinishDelayTimer()
              self._CatchPetTipsDelayTimer = _G.DelayManager:DelaySeconds(3, function()
                self._CatchPetTipsDelayTimer = nil
                self:_DirectShowCatchPetTips()
              end)
            end
            self.TipsReason[param] = true
          end
        end
      end
      if bImmediateShow then
        self:ShowCatchPetTips()
      end
    elseif Notify.source == ProtoEnum.CommonTipsSource.CTS_CCC_CHECKER then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Notify.localization_id, nil, nil, 3)
    end
  end
end

function TaskModule:OnWorldPetCatchFinish(bIsSuccess)
  Log.Debug("TaskModule:OnWorldPetCatchFinish bIsSuccess=", bIsSuccess)
  if bIsSuccess and self.CatchPetTipID then
    self:_CancelCatchPetTipsDelayTimer()
    local FlowReason = _G.ProtoEnum.FlowReason.FLOW_REASON_SCENE_CATCH_PET
    if self.TipsReason[FlowReason] then
      self.TipsReason[FlowReason] = false
      self._CatchPetFinishDelayTimer = _G.DelayManager:DelaySeconds(3, function()
        self._CatchPetFinishDelayTimer = nil
        if self.CatchPetTipID then
          self:_DirectShowCatchPetTips()
        end
      end)
      return
    end
    self:ShowCatchPetTips()
  end
end

function TaskModule:OnBattleOverOther()
  if self.CatchPetTipID then
    self:ShowCatchPetTips()
  end
end

function TaskModule:ShowCatchPetTips()
  if _G.BattleManager:IsInBattle() then
    return
  end
  local LocalizationConf = DataConfigManager:GetLocalizationConf(self.CatchPetTipID)
  self.CatchPetTipID = nil
  if not LocalizationConf then
    return
  end
  local tip = LocalizationConf.msg
  Log.Debug("TaskModule:ShowCatchPetTips tip=", tip)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip, nil, nil, 3)
end

function TaskModule:_DirectShowCatchPetTips()
  local tipID = self.CatchPetTipID
  self.CatchPetTipID = nil
  self.TipsReason[_G.ProtoEnum.FlowReason.FLOW_REASON_SCENE_CATCH_PET] = false
  local LocalizationConf = DataConfigManager:GetLocalizationConf(tipID)
  if not LocalizationConf then
    return
  end
  local tip = LocalizationConf.msg
  Log.Debug("TaskModule:_DirectShowCatchPetTips tip=", tip)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tip, nil, nil, 3)
end

function TaskModule:_CancelCatchPetTipsDelayTimer()
  if self._CatchPetTipsDelayTimer then
    _G.DelayManager:CancelDelayById(self._CatchPetTipsDelayTimer)
    self._CatchPetTipsDelayTimer = nil
  end
end

function TaskModule:_CancelCatchPetFinishDelayTimer()
  if self._CatchPetFinishDelayTimer then
    _G.DelayManager:CancelDelayById(self._CatchPetFinishDelayTimer)
    self._CatchPetFinishDelayTimer = nil
  end
end

function TaskModule:UpdateTaskTips()
  if self.data then
    self.data:UpdateTaskTips()
  end
end

function TaskModule:IsSkipTask(TaskID)
  if not self.data then
    return false
  end
  return self.data:IsSkipTask(TaskID)
end

function TaskModule:OnCmdTraceTaskByTaskId(TaskID)
  local taskInfo = self:GetTaskByID(TaskID)
  if taskInfo then
    self:DoTraceTask(taskInfo, true)
  end
end

return TaskModule
