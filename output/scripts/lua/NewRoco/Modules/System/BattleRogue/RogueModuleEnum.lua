local RogueModuleEnum = {}
RogueModuleEnum.RogueStateEnum = {
  None = 0,
  Init = 1,
  ChooseLevel = 2,
  SelectPet = 3,
  AffirmPet = 4,
  ChallengeLobby = 5,
  ChallengeBattle = 6,
  Exit = 7
}
RogueModuleEnum.ChallengeInfoFlag = {
  PetInfo = 1,
  EventList = 2,
  Chapter = 4,
  All = 7
}
RogueModuleEnum.EventState = {
  None = 0,
  Done = 1,
  InProcess = 2,
  Future = 3,
  Boss = 4
}
return RogueModuleEnum
