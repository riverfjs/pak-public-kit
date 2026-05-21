local TaskActionBase = require("NewRoco.Modules.Core.Task.TaskActionBase")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local Base = TaskActionBase
local TaskActionNeedDownload = Base:Extend("TaskActionNeedDownload")

function TaskActionNeedDownload:Ctor(Task, ActionGroup, ActionIndex, Conf)
  Base.Ctor(self, Task, ActionGroup, ActionIndex, Conf)
end

function TaskActionNeedDownload:ShouldExecute()
  return true
end

function TaskActionNeedDownload:OnExecute()
  self:TempCheckIfNeedDownloadBaseRes()
end

function TaskActionNeedDownload:TempCheckIfNeedDownloadBaseRes()
  if not AppMain.IsMobilePlatform() then
    self:SendFinishReq()
    return
  end
  local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
  if NeedToDownloadBasePakList and #NeedToDownloadBasePakList > 0 then
    Log.Debug("[TaskActionNeedDownload:TempCheckIfNeedDownloadBaseRes]Need To Download Base Paks")
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local GB = string.format("%.2f", SizeNeedToDownload / 1024 / 1024 / 1024)
    local Content
    if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
      local AppendText = string.format([[

%s]], LuaText.Download_All_tips3)
      Content = string.format(LuaText.Download_All_tips1, AppendText, GB)
    else
      Content = string.format(LuaText.Download_All_tips1, "", GB)
    end
    Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetIfHideCloseBtn(true):SetCallback(self, function(this, result)
      if result then
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.BaseDownloadBtn)
        _G.AppMain:SetIfDownloadBasePaksWithoutLogin(true)
      else
        _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.RefuseBaseDownloadBtn)
      end
      _G.ZoneServer:DisConnect(true, false)
      _G.AppMain.BackToLogin(true)
    end):SetButtonText(LuaText.Download_All_button2, LuaText.Download_All_button1)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    local BasePakList = _G.PufferDownloadInfo:GetBasePakListWithPatch()
    if _G.PufferUpdateResTask:MountPakList(BasePakList) then
      self:SendFinishReq()
    else
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadFail, LoginEnum.DownloadReportType.BaseDownloadFail, "Mount Failed")
      Log.Error("[TaskActionNeedDownload:TempCheckIfNeedDownloadBaseRes] mount failed")
      local ErrorCode = -3
      local PufferErrorCodeDesc = require("Core.Service.GCloud.PufferErrorCodeDesc")
      _G.GEMPostManager:GEMPostStepEvent("UpdateResSuccess", PufferErrorCodeDesc:GetDesc(ErrorCode))
      local Context = DialogContext()
      Context:SetTitle(LuaText.updateuimodule_26):SetContent(PufferErrorCodeDesc:GetDesc(ErrorCode)):SetMode(DialogContext.Mode.OK):SetCallback(self, function(this, result)
        UE4.UNRCStatics.QuitGame()
      end):SetButtonText(LuaText.onlinemodule_6)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
    end
  end
end

function TaskActionNeedDownload:SendFinishReq()
  local bFlag = false
  local CondIndex = 0
  for Index, Cond in ipairs(self.Task.Config.task_condition) do
    if Cond.type == ProtoEnum.TaskKeyType.TKT_MINI_PACKAGE_DONE then
      bFlag = true
      CondIndex = Index
      break
    end
  end
  if bFlag then
    local Req = ProtoMessage:newZoneTaskConditionTriggerReq()
    Req.taskid = self.Task.Config.id
    Req.condition_type = ProtoEnum.TaskKeyType.TKT_MINI_PACKAGE_DONE
    Req.task_condition_idx = CondIndex
    Log.Debug("[TaskActionNeedDownload:SendFinishReq] Send Finish Req")
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_CONDITION_TRIGGER_REQ, Req, self, self.OnSendFinish, false, false)
  else
    Base.SendFinishReq(self)
  end
end

function TaskActionNeedDownload:OnSendFinish(Rsp)
  self:Finish()
end

function TaskActionNeedDownload:Destroy()
end

return TaskActionNeedDownload
