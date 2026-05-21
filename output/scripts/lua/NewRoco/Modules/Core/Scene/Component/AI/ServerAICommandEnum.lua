local ServerAICommandEnum = {}
ServerAICommandEnum.ServerAICommandEvent = {
  Empty = 0,
  PlayAnimation = 1,
  StopAnimation = 2,
  AnimPauseOrResume = 3,
  ServerMove = 4,
  InterruptServerMove = 5,
  TurnTo = 6,
  CancelTurnTo = 7,
  WorldAttack = 8,
  StopWorldAttack = 9,
  PlayPerceptionEffect = 10,
  PlayPerceptionHud = 11,
  ServerAttach = 12,
  CancelServerAttach = 13,
  PlaySkill = 14,
  StopSkill = 15,
  CollisionCancelRecover = 16,
  WorldHidden = 17,
  WorldUnhidden = 18,
  LookAt = 19,
  ServerFly = 20,
  PlayZoomAnimation = 21,
  PlayVoice = 22,
  Launch = 23,
  CancelLaunch = 24,
  PlayRealtimeDialog = 25,
  StopRealtimeDialog = 26,
  StickTo = 27,
  FinishStickTo = 28,
  TryInteractNpc = 29,
  VelocityOrientRotation = 30,
  WorldLaunchPlayer = 31,
  SetNpcPos = 50,
  PerceivePlayer = 32,
  PlayChatBubble = 33
}
ServerAICommandEnum.ServerAICommand = nil

function ServerAICommandEnum.newServerAICommand()
  return {
    command_enum = 0,
    time_stamp = 0,
    seq_id = 0,
    server_data = nil
  }
end

return ServerAICommandEnum
