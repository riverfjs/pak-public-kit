local FriendEnum = {}
FriendEnum.FriendTab = {
  GameFriend = 0,
  PlatformFriend = 1,
  SearchFriend = 2,
  WeGameFriend = 3
}
FriendEnum.TAB_TYPE = {
  Material = 0,
  AddFriend = 1,
  AddBlackList = 2,
  Report = 3,
  Remark = 4,
  RemoveFriend = 5,
  RemoveBlackList = 6,
  ChangeHeadIcon = 7,
  ChangeCardBG = 8,
  ChangeLabel = 9,
  ChangeSign = 10,
  Chitchat = 11,
  WorldInfo = 12,
  RequestAccess = 13,
  Invitation = 14,
  Fight = 15,
  InteractiveEggs = 16
}
FriendEnum.SELECT_TAB = {
  None = -1,
  FriendList = 0,
  AddFriend = 1,
  FriendApply = 2,
  BlackList = 3,
  VisitPanelList = 4,
  StudentCardList = 5,
  FaceToFaceInteraction = 6,
  Chat = 7,
  WeGameFriend = 8
}
FriendEnum.AdminFriendType = {Own = 1, Others = 2}
FriendEnum.InformationEditorType = {
  ChangeHeadTab = 0,
  ChangeLabelTab = 1,
  ChangeNickNameTab = 2,
  ChangeSignTab = 3
}
FriendEnum.ExchangeVisitsType = {
  ApplyVisit = 0,
  TeamBattle = 1,
  InviteVisit = 2,
  RequireCompetition = 3,
  ResponseCompetition = 4,
  RequireSwapEggs = 5,
  ResponseSwapEggs = 6,
  DoubleRide = 7,
  EnterHome = 8,
  ReturnBigWorld = 9
}
FriendEnum.ImageEditorType = {
  Theme = 0,
  Clothing = 1,
  PlayerAction = 2
}
FriendEnum.Source = {Friend = 1, Scene = 2}
FriendEnum.CardEntrance = {
  Null = 0,
  MainPanel = 1,
  InformationEditorPanel = 2,
  ImageEditorPanel = 3,
  Photograph = 4
}
FriendEnum.ChatItemRefreshType = {FriendRemarkUpdate = 1, HideReportBtn = 2}
FriendEnum.ChatMsgSource = {Client = 1, DirtyMsgForSend = 2}
FriendEnum.CardComponentShowType = {
  None = 0,
  CardNormal = 1,
  CardModified = 2,
  EditComponent = 3
}
FriendEnum.ChatMode = {GeneralChatting = 1, QuickAnnouncement = 2}
FriendEnum.OpenFriendEntrance = {Compass = 1, Chat = 2}
FriendEnum.PlayerOperationEntrance = {
  ChangeNickname = 0,
  FriendTop = 1,
  CancelTop = 2,
  RemoveFriend = 3,
  Black = 4,
  CancelBlack = 5,
  Report = 6
}
FriendEnum.CardInteractionEntrance = {
  None = 0,
  AddFriend = 1,
  Chitchat = 2,
  HomeInfo = 3,
  WorldInfo = 4,
  RequestAccess = 5,
  Invitation = 6,
  Teleport = 7
}
FriendEnum.ClientFriendRoleInfoScene = {
  None = 0,
  FriendPanelDefault = 1,
  BattlePassGift = 2,
  FurnitureInfo = 3
}
FriendEnum.ChatFunctionTabList = {
  CheckCard = 0,
  WorldInformation = 1,
  HomeInformation = 2,
  ApplicationVisit = 3,
  InviteVisit = 4,
  ChangeNickname = 5,
  BlockFriend = 6,
  ReportFriend = 7,
  RemoveSession = 8,
  Teleport = 9
}
FriendEnum.TypingFlag = {
  None = 0,
  QuickChatFlag = 1,
  MultiChannelChatFlag = 2,
  AllFlag = 3
}
FriendEnum.VoiceInputScene = {Default = 0, AICoach = 1}
return FriendEnum
