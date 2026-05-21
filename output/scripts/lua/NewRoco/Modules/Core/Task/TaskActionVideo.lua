local TaskActionGroupEnum = require("NewRoco.Modules.Core.Task.TaskActionGroupEnum")
local TaskActionBase = require("NewRoco.Modules.Core.Task.TaskActionBase")
local Base = TaskActionBase
local TaskActionVideo = Base:Extend("TaskActionVideo")

function TaskActionVideo:Ctor(Task, ActionGroup, ActionIndex, Conf)
  Base.Ctor(self, Task, ActionGroup, ActionIndex, Conf)
  local Data1 = tonumber(Conf.data1[1] or 0) or 0
  local Data2 = tonumber(Conf.data1[2] or 0) or 0
  if 0 == Data2 then
    Data2 = Data1
  end
  self.VideoID = self:IsMale() and Data1 or Data2
  if 0 == self.VideoID then
    self:LogError("\228\187\187\229\138\161\230\146\173\231\137\135ID\233\148\153\232\175\175,\229\189\147\229\137\141\229\128\188\228\184\186%d", Conf.data1[1])
  end
end

function TaskActionVideo:ShouldExecute()
  if self.Task.Config.task_structure_type == ProtoEnum.TaskStructureType.TSTT_CINEMA then
    if self.ActionGroup == TaskActionGroupEnum.Finish then
      self:LogError("\233\133\141\231\189\174\233\148\153\232\175\175,\233\133\141\231\189\174\228\186\134TaskStructureType.TSTT_CINEMA\231\154\132\228\187\187\229\138\161\228\184\141\232\131\189\230\138\138\230\146\173\231\137\135\233\133\141\229\156\168\229\174\140\230\136\144\230\151\182\232\161\140\228\184\186")
      return false
    end
    local State = self.Task.Info.state
    local AllowState = State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN or State == ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN_PLAY
    if not AllowState then
      return false
    end
    if not self.Task:IsInActionArea() then
      self:LogWarning("\228\184\141\229\156\168\230\140\135\229\174\154\231\154\132\229\140\186\229\159\159\239\188\140\228\184\141\232\131\189\232\167\166\229\143\145")
      return false
    end
    return true
  else
    return Base.ShouldExecute(self)
  end
end

function TaskActionVideo:OnExecute()
  local param = {}
  param.Conf = _G.DataConfigManager:GetMovieConf(self.VideoID)
  param.Caller = self
  param.Callback = self.OnVideoFinish
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.PlayVideo, param)
end

function TaskActionVideo:OnVideoFinish(Success)
  _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.VideoOnlyDialogueOver)
  if not Success then
    self:Log("\230\146\173\230\148\190\229\164\177\232\180\165\239\188\140\229\135\134\229\164\135\230\160\135\232\174\176\231\187\147\230\157\159\229\185\182\228\184\148\229\143\145\232\181\183\233\135\141\232\175\149")
    self:Finish()
    self.Task:RevokeActionArea()
    return
  end
  self:SendFinishReq()
end

function TaskActionVideo:SendFinishReq()
  if self.Task.Config.task_structure_type == ProtoEnum.TaskStructureType.TSTT_CINEMA then
    local InfoList = self:GetClientConditionInfo()
    if #InfoList > 0 then
      local Info = InfoList[1]
      local Req = ProtoMessage:newZoneTaskConditionTriggerReq()
      Req.taskid = Info.taskid
      Req.condition_type = Info.condition_type
      Req.task_condition_idx = Info.task_condition_idx
      Log.Debug("[TaskActionVideo:SendFinishReq] Send Finish Req", Info.taskid, Info.condition_type, Info.task_condition_idx)
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_CONDITION_TRIGGER_REQ, Req, self, self.OnSendFinish, false, false)
    end
  else
    Base.SendFinishReq(self)
  end
end

function TaskActionVideo:OnSendFinish(rsp)
  self:Finish()
end

function TaskActionVideo:IsMale()
  return _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex == _G.ProtoEnum.ESexValue.SEX_MALE
end

return TaskActionVideo
