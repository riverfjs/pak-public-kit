local BigMapModuleEnum = {}
BigMapModuleEnum.NpcInfoType = {
  NONE = 1,
  NPC = 2,
  TASK = 3
}
BigMapModuleEnum.TaskShowType = {
  ACCEPTED = 1,
  UNDO = 2,
  TRACING = 3
}
BigMapModuleEnum.MarksType = {
  TaskMark = 0,
  HeadMark = 1,
  CustomMark = 2
}
BigMapModuleEnum.OpenType = {
  None = 0,
  Task = 1,
  Npc = 2
}
BigMapModuleEnum.TraceAniAction = {Play = 1, Stop = 2}
BigMapModuleEnum.TraceAniType = {
  TraceStart = 1,
  TraceLoop = 2,
  TraceEnd = 3
}
BigMapModuleEnum.CreatorPriority = {
  Map = 1,
  Mask = 2,
  AreaIcons = 3,
  NpcIcons = 4,
  TaskIcons = 5,
  MarkerIcons = 6,
  VisitorIcons = 7,
  TraceIcons = 8
}
BigMapModuleEnum.TraceType = {
  Self = 1,
  NPC = 2,
  Task = 3,
  Marker = 4,
  Visitor = 5,
  AutoTrace = 6,
  TempTrace = 7,
  ForceTrace = 8,
  Travel = 9
}
BigMapModuleEnum.IconDirection = {
  None = 1,
  Up = 2,
  Down = 3
}
BigMapModuleEnum.CircleIconType = {Task = 1, Activity = 2}
BigMapModuleEnum.MapTileLoadStatus = {
  Loading = 1,
  Loaded = 2,
  Failed = 3
}
BigMapModuleEnum.NpcInfoButtonType = {
  Hidden = 0,
  Trace = 1,
  Teleport_1 = 2,
  CancelTrace = 3,
  WaitTime = 4,
  Mark = 5,
  View = 6,
  Teleport_2 = 7
}
return BigMapModuleEnum
