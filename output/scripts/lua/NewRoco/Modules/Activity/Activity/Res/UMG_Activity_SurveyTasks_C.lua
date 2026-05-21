local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Activity_SurveyTasks_C = _G.NRCPanelBase:Extend("UMG_Activity_SurveyTasks_C")

function UMG_Activity_SurveyTasks_C:OnActive(data)
  self.TaskData = data.taskSlotData
  self.RedPointId = data.redPointId
  self.RedPointExtraKey = data.redPointExtraKey
  self:InitInfo()
  self:InitPetList()
  self:InitTaskList()
  self:OnAddEventListener()
end

function UMG_Activity_SurveyTasks_C:InitInfo()
  self.NxRichText_Instruction:SetText(LuaText.activity_pet_information_catch_tips)
  self:SetTitle()
end

function UMG_Activity_SurveyTasks_C:InitPetList()
  local dropPetList = ActivityUtils.GetActivityGlobalConfig("activity_fangfanghu_petbase_drop").numList
  self.Tab_List:InitList(dropPetList)
end

function UMG_Activity_SurveyTasks_C:InitTaskList()
  self.ParticularsList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local taskList = {}
  for _, task in ipairs(self.TaskData) do
    table.insert(taskList, task)
  end
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = taskList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.ShowTaskList, false, true)
end

function UMG_Activity_SurveyTasks_C:ShowTaskList(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local taskDataList = {}
    local taskList = rsp.task_info_list
    if taskList then
      for _, taskData in ipairs(taskList) do
        if self.RedPointExtraKey then
          table.insert(self.RedPointExtraKey, tostring(taskData.id))
        end
        local data = {
          taskData = taskData,
          redPointId = self.RedPointId,
          redPointExtraKey = self.RedPointExtraKey
        }
        table.insert(taskDataList, data)
      end
    end
    self.ParticularsList:InitList(taskDataList)
  end
  
  local function cb()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    self.ParticularsList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  
  self:CancelAllDelay()
  self.Handler = _G.DelayManager:DelaySeconds(0.1, cb, self)
end

function UMG_Activity_SurveyTasks_C:OnDeactive()
  self:RemoveButtonListener(self.CloseBtn.btnClose)
end

function UMG_Activity_SurveyTasks_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnCloseClick)
end

function UMG_Activity_SurveyTasks_C:OnBtnCloseClick()
  self:DoClose()
end

function UMG_Activity_SurveyTasks_C:CancelAllDelay()
  if self.Handler then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = nil
  end
end

function UMG_Activity_SurveyTasks_C:SetTitle()
  local titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  if titleConf then
    self.Title1:Set_MainTitle(titleConf.title)
    self.Title1:SetBg(titleConf.head_icon)
    self.Title1:SetSubtitle(titleConf.subtitle[1].subtitle)
  end
end

return UMG_Activity_SurveyTasks_C
