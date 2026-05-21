local EnumMeta = {
  __index = function(t, k)
    local v = rawget(t, k)
    if not v then
      Log.ErrorFormat("\230\137\190\228\184\141\229\136\176\229\144\141\229\173\151\228\184\186%s\231\154\132\230\158\154\228\184\190", k)
    end
    return v
  end,
  __newindex = function(t, k, v)
    Log.ErrorFormat("\228\184\141\229\133\129\232\174\184\229\138\168\230\128\129\228\191\174\230\148\185\230\158\154\228\184\190\229\128\188%s", k)
  end
}
local ActivityEnum = {}
ActivityEnum.MainPanelOpenSource = setmetatable({RecallActivity = 1, LobbyMainInner = 2}, EnumMeta)
ActivityEnum.ActivityStatus = setmetatable({
  WaitingActive = 1,
  Active = 2,
  Available = 3,
  Complete = 4,
  Expired = 5
}, EnumMeta)
ActivityEnum.ActivityShowStatus = setmetatable({
  Enable = 1,
  Disable_NotActive = 2,
  Disable_CompleteDisappear = 3,
  Disable_Expired = 4,
  Disable_AdditionalCond = 5,
  Disable_Shielding = 6,
  Disable_ConfigHide = 7,
  Disable_BelongSeason = 8
}, EnumMeta)
ActivityEnum.ActivitySvrStatus = setmetatable({
  Unknown = 1,
  Available = 2,
  UnAvailable = 3
}, EnumMeta)
ActivityEnum.ActivityInteractionType = setmetatable({
  Auto = 1,
  Join = 2,
  GetReward = 3
}, EnumMeta)
ActivityEnum.ActivityJoinStatus = setmetatable({
  Available = 1,
  Unsatisfied = 2,
  Expired = 3
}, EnumMeta)
ActivityEnum.RewardStatus = setmetatable({
  UnAvailable = 1,
  Available = 2,
  Received = 3
}, EnumMeta)
ActivityEnum.RedPointKey = setmetatable({NewActivity = 214, DetailReward = 215}, EnumMeta)
ActivityEnum.TLogActionType = setmetatable({Join = 0, Finish = 1}, EnumMeta)
ActivityEnum.TLogInteractionType = setmetatable({Show = 0, Click = 1}, EnumMeta)
ActivityEnum.MapActivityIconGroup = setmetatable({TreasureDig = 1}, EnumMeta)
ActivityEnum.ActivityTypeSpecial = setmetatable({UnknownActivity = -1, PandoraActivity = -2}, EnumMeta)
ActivityEnum.ActivitySource = setmetatable({Svr = 1, Pandora = 2}, EnumMeta)
ActivityEnum.ActivityTabOpType = setmetatable({GetHasRedPoint = 1}, EnumMeta)
ActivityEnum.MixActivityJoinStatus = {
  Init = 0,
  InGuidTask = 1,
  Normal = 3
}
ActivityEnum.ItemOpType = {
  Enable = 1,
  RefreshData = 2,
  RewardStatusChange = 3,
  ProgressChange = 4,
  RefreshPartData1 = 5,
  RefreshPartData2 = 6,
  RefreshPartData3 = 7,
  RefreshPartData4 = 8,
  RefreshPartData5 = 9,
  RefreshPartData6 = 10
}
ActivityEnum.ItemStatus = {
  Unknown = 0,
  Locked = 1,
  UnLocked = 2,
  Available = 3,
  Finished = 4
}
ActivityEnum.SprintTaskType = {
  None = 0,
  OnlineTask = 1,
  ServerPopularityTask = 2,
  PersonalPopularityTask = 3
}
ActivityEnum.SprintSubActivityState = {
  NotStarted = 1,
  InProgress = 2,
  Ended = 3
}
ActivityEnum.TakePhotoCompetitionStage = {
  None = 0,
  Preparation = 1,
  PhotoCheck = 2,
  Competition = 3,
  CurPhaseEnd = 4
}
ActivityEnum.TakePhotoCompetitionBigPhotoType = {
  None = 0,
  MySubmission = 1,
  HotPhoto = 2,
  RankPhoto = 3,
  VotePhoto = 4,
  RewardPhoto = 5
}
ActivityEnum.OnlineActivityMonitorEvent = {
  Enum.ActivityMonitorEvent.AME_PLAYER_ONLINE_TIME,
  Enum.ActivityMonitorEvent.AME_PLAYER_TRANSFORM_ONLINE_TIME,
  Enum.ActivityMonitorEvent.AME_PLAYER_TRANSFORM_EAGLE_CAPTURE
}
return ActivityEnum
