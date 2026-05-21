local ShareModuleEnum = {
  ShareChannel = {
    save = "save",
    WeChatFriend = "WeChatFriend",
    WeChatMoments = "WeChatMoments",
    QQFriend = "QQFriend",
    Qzone = "Qzone",
    Tiktok = "Tiktok",
    TiktokFriend = "TiktokFriend",
    Weibo = "Weibo",
    RedNote = "RedNote",
    KuaiShou = "Kuaishou",
    BiliBili = "BiliBili"
  },
  EnableShareChannel = {
    save = "save",
    WeChatFriend = "WeChatFriend",
    WeChatMoments = "WeChatMoments",
    QQFriend = "QQFriend",
    Qzone = "Qzone"
  },
  UpLoadEvent = {RefreshProgrss = 900100, Finished = 900101},
  ShareResult = {
    SUCCESS = "SUCCESS",
    IMG_NOT_EXIST = "IMG_NOT_EXIST",
    VIDEO_NOT_EXIST = "VIDEO_NOT_EXIST"
  },
  NeedAlbumPermissionChannel = {
    save = "save",
    Tiktok = "Tiktok",
    TiktokFriend = "TiktokFriend"
  }
}
return ShareModuleEnum
