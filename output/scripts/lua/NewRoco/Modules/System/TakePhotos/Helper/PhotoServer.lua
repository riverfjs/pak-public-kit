local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local PhotoServer = Class("PhotoServer")
local EnmPhotoServerStatus = {
  None = 0,
  Initializing = 1,
  Initialized = 2
}

function PhotoServer:Ctor(TakePhotosModule)
  self.AlbumFileList = {}
  self.AlbumFileTable = {}
  
  function self.DummyFunction()
  end
  
  self.UploadServiceRefMap = {}
  self.DownloadServiceRefMap = {}
  self.Status = EnmPhotoServerStatus.None
end

function PhotoServer:InitBriefs()
  if self:IsInitialized() then
    return
  end
  
  local function OnAlbumFileListBriefEstablished(bSuccess)
    if bSuccess then
      Log.Debug("[PhotoServer] InitBriefs Success")
      self.Status = EnmPhotoServerStatus.Initialized
      NRCModuleManager:GetModule("TakePhotosModule"):DispatchEvent(TakePhotosModuleEvent.OnRemotePhotoFullEstablished)
    else
      Log.Error("[PhotoServer] InitBriefs Failed, wait for enter scene retry")
    end
  end
  
  Log.Debug("[PhotoServer] InitBriefs")
  self.Status = EnmPhotoServerStatus.Initializing
  self:ReqAlbumFileList(OnAlbumFileListBriefEstablished)
end

function PhotoServer:OnEnterSceneFinish()
  self:InitBriefs()
end

function PhotoServer:IsInitialized()
  return self.Status ~= EnmPhotoServerStatus.None and self.Status ~= EnmPhotoServerStatus.Initializing
end

function PhotoServer:ReqDownloadFile(File, OnDownloadFinish)
  if self.DownloadServiceRefMap[File.PhotoName] then
    return
  end
  Log.Debug("[PhotoServer] Start Download File", File.PhotoPath, File.FileUrl)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  self.DownloadServiceRefMap[File.PhotoName] = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetUrl(File.FileUrl)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(Service, Status)
      if Status == UE4.EHttpServiceStatus.RspSuccess then
        Service:SaveToFile(File.PhotoPath)
        Log.Debug("[PhotoServer] DownloadFile Success", File.PhotoPath)
      else
        Log.Debug("[PhotoServer] DownloadFile Failed", File.PhotoPath)
      end
      self.DownloadServiceRefMap[File.PhotoName] = nil
      OnDownloadFinish(Status == UE4.EHttpServiceStatus.RspSuccess, File)
    end
  })
end

function PhotoServer:HasPhotoName(Name)
  return self.AlbumFileTable[Name]
end

function PhotoServer:IfReceiveSuccess(Proto, RspName)
  if Proto and Proto.ret_info then
    if 0 ~= Proto.ret_info.ret_code then
      Log.Error("[PhotoServer]", RspName, "err:", Proto.ret_info.ret_code, Proto.ret_info.ret_msg)
    else
      return true
    end
  else
    Log.Error("[PhotoServer]", RspName, "err: not ret_info")
  end
end

function PhotoServer:ReqAlbumFileList(Callback)
  Callback = Callback or self.DummyFunction
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_PHOTO_ALBUM_PREVIEW_REQ
  local Req = ProtoMessage:newZonePhotoAlbumPreviewReq()
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZonePhotoAlbumPreviewRsp")
    if bSuccess then
      local PersistentPhotos = UE.UBlueprintPathsLibrary.Combine({
        UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
        "RemotePhotos"
      })
      local photo_list = protoData.photo_list or {}
      for i, v in ipairs(photo_list) do
        local FileName = v.photo_name
        local File = self.AlbumFileTable[FileName]
        if File then
          File.bUpdate = true
          assert(File.PhotoName == FileName)
          assert(File.PhotoMd5 == v.photo_md5)
        else
          local PhotoPath = UE.UBlueprintPathsLibrary.Combine({PersistentPhotos, FileName})
          PhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(PhotoPath)
          File = {
            SerialId = i,
            PhotoName = v.photo_name,
            PhotoMd5 = v.photo_md5,
            PhotoInfo = v.photo_info,
            PhotoPath = PhotoPath,
            bUpdate = true
          }
          self.AlbumFileTable[v.photo_name] = File
        end
        self.AlbumFileList[i] = File
        Log.Debug("[PhotoServer] File=", v.photo_name, v.photo_md5)
      end
      while #self.AlbumFileList > #photo_list do
        table.remove(self.AlbumFileList)
      end
      for k, v in pairs(self.AlbumFileTable) do
        if not v.bUpdate then
          self.AlbumFileTable[k] = nil
        end
        v.bUpdate = nil
      end
      for i, v in ipairs(self.AlbumFileList) do
        v.SerialId = i
      end
      if #self.AlbumFileList > 0 then
        local function OnFileUrlEstablish(bUrlSuccess)
          Callback(bUrlSuccess, protoData)
        end
        
        self:ReqAlumDownloadList(self.AlbumFileList, OnFileUrlEstablish)
      else
        Callback(true, protoData)
      end
    else
      Callback(bSuccess, protoData)
    end
  end
  
  Log.Debug("[PhotoServer] ReqAlbumFileList")
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ReqAlbumFileList ZonePhotoAlbumPreviewReq send failed")
    Callback(bSuccess)
  end
  return bSuccess
end

function PhotoServer:ReqAlumDownloadList(NeedDownloadFileList, Callback)
  Callback = Callback or self.DummyFunction
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_PHOTO_ALBUM_DOWNLOAD_URL_REQ
  local Req = ProtoMessage:newZonePhotoAlbumDownloadUrlReq()
  local PhotoNameList = {}
  for i, v in ipairs(NeedDownloadFileList) do
    PhotoNameList[i] = v.PhotoName
  end
  Req.photo_list = PhotoNameList
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZonePhotoAlbumDownloadUrlRsp")
    if bSuccess then
      local DownloadList = protoData.download_list
      if not DownloadList or not next(DownloadList) then
      else
        for i, v in ipairs(DownloadList) do
          local FileName = v.photo_name
          local File = self.AlbumFileTable[FileName]
          if not File then
            Log.Error("ZonePhotoAlbumDownloadUrlRsp cannot found file by name", FileName)
          else
            File.FileUrl = v.url
          end
        end
      end
    end
    Callback(bSuccess, protoData)
  end
  
  Log.Debug("[PhotoServer] ReqAlumDownloadList")
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ReqAlumDownloadList ZonePhotoAlbumDownloadUrlReq send failed")
    Callback(bSuccess)
  end
  return bSuccess
end

function PhotoServer:ReqRemovePhotos(RemoveNames, Callback)
  Callback = Callback or self.DummyFunction
  Log.Debug("[PhotoServer] ReqRemovePhotos", table.concat(RemoveNames, ";"))
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_PHOTO_ALBUM_DELETE_REQ
  local Req = ProtoMessage:newZonePhotoAlbumDeleteReq()
  Req.photo_list = RemoveNames
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZonePhotoAlbumDeleteRsp")
    if bSuccess then
      local PhotoNames = protoData.photo_list
      if PhotoNames then
        for i, PhotoName in ipairs(PhotoNames) do
          self.AlbumFileTable[PhotoName] = nil
        end
        for i = #self.AlbumFileList, 1, -1 do
          local File = self.AlbumFileList[i]
          if not self.AlbumFileTable[File.PhotoName] then
            Log.Debug("[PhotoServer] ZonePhotoAlbumDeleteRsp remove", File.PhotoName)
            table.remove(self.AlbumFileList, i)
          end
        end
      else
        Log.Error("[PhotoServer] cannot found names by ZonePhotoAlbumDeleteRsp")
      end
    end
    for i = #self.AlbumFileList, 1, -1 do
      local File = self.AlbumFileList[i]
      File.SerialId = i
    end
    Callback(bSuccess, protoData)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ZonePhotoAlbumDeleteReq send failed")
    Callback(bSuccess)
  end
  return bSuccess
end

function PhotoServer:ReqUploadTempPhoto(PhotoPath, Type, Callback, CustomName, PhotoInfo)
  if not self:IsInitialized() then
    Callback(false)
    return
  end
  if Type ~= ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_PHOTO and Type ~= ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_CARD and Type ~= ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_ACT_TAKE_PHOTO then
    Callback(false)
    return
  end
  Callback = Callback or self.DummyFunction
  if self.UploadServiceRefMap[PhotoPath] then
    Callback(false)
    Log.Debug("[PhotoServer] uploading ...", PhotoPath)
    return
  end
  if not UE.UNRCStatics.FileExists(PhotoPath) then
    Callback(false)
    return
  end
  local MD5 = UE.UNRCStatics.HashFileMD5(PhotoPath)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_PHOTO_ALBUM_UPLOAD_URL_REQ
  local Req = ProtoMessage:newZonePhotoAlbumUploadUrlReq()
  local Names = string.split(PhotoPath, "/")
  local Name = CustomName or Names[#Names]
  Req.photo_name = Name
  Req.album_type = Type
  Req.photo_md5 = MD5
  Log.Debug("[PhotoServer] upload", PhotoPath, Name, Type, "Md5=", MD5)
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZonePhotoAlbumUploadUrlRsp")
    if bSuccess then
      Log.Debug("[PhotoServer] ZonePhotoAlbumUploadUrlRsp", protoData.photo_name, protoData.url, Type, PhotoPath)
      
      local function OnUploadFinish(bUploadSuccess)
        if bUploadSuccess then
          if UE.UNRCStatics.FileExists(PhotoPath) then
            if Type == ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_PHOTO then
              self:InternalNotifyServerAlbum(Callback, protoData.photo_name, Type, MD5, PhotoPath, PhotoInfo)
            elseif Type == ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_CARD then
              self:InternalNotifyServerCard(Callback, protoData.photo_name, Type, MD5)
            else
              Callback(true, protoData)
            end
          else
            Log.Error("[PhotoServer] cannot found photo after upload", PhotoPath)
            Callback(false)
          end
        else
          Callback(false)
        end
      end
      
      self:InternalUploadFile(PhotoPath, protoData.url, OnUploadFinish, MD5)
    else
      local isIdipBan = protoData.ban_info and protoData.ban_info.uin and 0 ~= protoData.ban_info.uin
      if isIdipBan then
        local timeStr = os.date("%Y-%m-%d %H:%M:%S", protoData.ban_info.ban_time)
        local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
        local tipStr = string.format(GlobalConfig.str, protoData.ban_info.uin, timeStr, protoData.ban_info.ban_reason)
        local dialogContext = DialogContext()
        dialogContext:SetTitle(LuaText.TIPS):SetContent(tipStr):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      end
      Callback(false, nil, isIdipBan)
    end
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ZonePhotoAlbumUploadUrlReq send failed")
    Callback(bSuccess)
  end
end

local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function PhotoServer:Hex2Bin(Md5)
  return Md5:gsub("..", function(c)
    return string.char(tonumber(c, 16))
  end)
end

function PhotoServer:GetMd5Base64(Md5)
  local BinMd5 = self:Hex2Bin(Md5)
  local pad = #BinMd5 % 3
  local res = {}
  for i = 1, #BinMd5, 3 do
    local a = BinMd5:byte(i)
    local b = BinMd5:byte(i + 1) or 0
    local c = BinMd5:byte(i + 2) or 0
    local n = a * 65536 + b * 256 + c
    local n1 = n >> 18 & 63
    local n2 = n >> 12 & 63
    local n3 = n >> 6 & 63
    local n4 = n & 63
    res[#res + 1] = BASE64_CHARS:sub(n1 + 1, n1 + 1)
    res[#res + 1] = BASE64_CHARS:sub(n2 + 1, n2 + 1)
    res[#res + 1] = BASE64_CHARS:sub(n3 + 1, n3 + 1)
    res[#res + 1] = BASE64_CHARS:sub(n4 + 1, n4 + 1)
  end
  if 1 == pad then
    res[#res] = "="
    res[#res - 1] = "="
  elseif 2 == pad then
    res[#res] = "="
  end
  local Base64 = table.concat(res)
  Log.Debug("PhotoServer:GetMd5Base64", Md5, BinMd5, Base64)
  return Base64
end

function PhotoServer:InternalUploadFile(FullPath, Url, Callback, Md5)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  self.UploadServiceRefMap[FullPath] = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetHeader("Content-Type", "image/png")
  HttpService:SetFile(FullPath)
  HttpService:SetUrl(Url)
  HttpService:SetHeader("Content-MD5", self:GetMd5Base64(Md5))
  HttpService:SetVerb("PUT")
  HttpService:Request({
    HttpService,
    function(_, Status)
      self.UploadServiceRefMap[FullPath] = nil
      if Status == UE.EHttpServiceStatus.RspSuccess then
        Log.Debug("[PhotoServer] upload success,", FullPath, Url)
        Callback(true)
      else
        Log.Error("[PhotoServer] upload failed,", FullPath, Url)
        Callback(false)
      end
    end
  })
end

function PhotoServer:InternalNotifyServerCard(Callback, Name, Type, MD5)
  Log.Debug("[PhotoServer] InternalNotifyServerAlbumToCard", Name, Type, MD5)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_BUSINESS_CARD_UPLOAD_SUCCESS_REQ
  local Req = ProtoMessage:newZoneBusinessCardUploadSuccessReq()
  Req.photo_name = Name
  Req.album_type = Type
  Req.photo_md5 = MD5
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZoneBusinessCardUploadSuccessRsp")
    Log.Debug("[PhotoServer] ZoneBusinessCardUploadSuccessReq", bSuccess)
    if bSuccess then
      local briefInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
      briefInfo.business_card_info = protoData.business_card_info
      _G.DataModelMgr.PlayerDataModel:SetCardBriefInfo(briefInfo)
      Log.Debug("[PhotoServer] ZoneBusinessCardUploadSuccessReq", briefInfo.business_card_info.cur_card_url)
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ZoneBusinessCardUploadSuccessReq send failed")
    Callback(bSuccess)
  end
end

function PhotoServer:InternalNotifyServerAlbum(Callback, Name, Type, MD5, SrcPhotoPath, PhotoInfo)
  Log.Debug("[PhotoServer] InternalNotifyServerAlbumToCard", Name, Type, MD5, PhotoInfo and PhotoInfo.include_myself, PhotoInfo and PhotoInfo.pet_base_id_list and PhotoInfo.pet_base_id_list[1])
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_PHOTO_ALBUM_UPLOAD_SUCCESS_REQ
  local Req = ProtoMessage:newZonePhotoAlbumUploadSuccessReq()
  Req.photo_name = Name
  Req.album_type = Type
  Req.photo_md5 = MD5
  Req.photo_info = PhotoInfo
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZonePhotoAlbumUploadSuccessRsp")
    Log.Debug("[PhotoServer] ZonePhotoAlbumUploadSuccessRsp", bSuccess)
    local File
    if bSuccess then
      local PersistentPhotos = UE.UBlueprintPathsLibrary.Combine({
        UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
        "RemotePhotos"
      })
      local PhotoPath = UE.UBlueprintPathsLibrary.Combine({PersistentPhotos, Name})
      PhotoPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(PhotoPath)
      UE.UNRCStatics.CopyFile(SrcPhotoPath, PhotoPath)
      if Type == ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_PHOTO then
        File = {
          SerialId = #self.AlbumFileList + 1,
          PhotoName = Name,
          PhotoMd5 = MD5,
          PhotoPath = PhotoPath
        }
        table.insert(self.AlbumFileList, File)
        self.AlbumFileTable[Name] = File
      end
      
      local function OnDownloadUrlEstablish(ProtoData)
        File = self.AlbumFileTable[Name]
        Callback(bSuccess, File)
      end
      
      self:ReqAlumDownloadList({File}, OnDownloadUrlEstablish)
    else
      Callback(false)
    end
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ZonePhotoAlbumUploadSuccessReq send failed")
    Callback(bSuccess)
  end
end

function PhotoServer:ReqDownloadCard(Url, Callback)
  local HttpService = UE4.UMoreFunPlatformKits.CreateSimpleHttpService()
  local HttpServiceRef = UnLua.Ref(HttpService)
  self.UploadServiceRefMap[Url] = HttpServiceRef
  HttpService:ResetHeaders()
  HttpService:ResetFields()
  HttpService:SetHeader("Content-Type", "image/png")
  HttpService:SetUrl(Url)
  HttpService:SetVerb("GET")
  HttpService:Request({
    HttpService,
    function(_, Status)
      if Status == UE.EHttpServiceStatus.RspSuccess then
        Log.Debug("[PhotoServer] download success,", Url)
        self:InternalBuildCardTexture(HttpService, Callback, Url)
        self.UploadServiceRefMap[Url] = nil
      else
        Log.Error("[PhotoServer] download failed,", Url)
        Callback(false)
      end
    end
  })
end

function PhotoServer:InternalBuildCardTexture(HttpService, Callback, Url)
  local Names = string.split(Url, "/")
  local Name = Names[#Names]
  Log.Debug("[PhotoServer] InternalBuildCardTexture Url:", Url, Name)
  local PersistentPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "CommonUrlImages",
    "CardPhotos"
  })
  if not UE.UNRCStatics.DirectoryExists(PersistentPhotos) then
    UE.UNRCStatics.MakeDirectory(PersistentPhotos)
  end
  local FileName = Name
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({PersistentPhotos, FileName})
  local ImageSavePath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(PhotoPath)
  if not HttpService:SaveToFile(ImageSavePath) then
    Log.Error("[PhotoServer] cannot save file", ImageSavePath)
  end
  Callback(true, ImageSavePath)
end

function PhotoServer:ReqUploadReportActivityPhoto(PhotoPath, SrcMd5, ClipPhotoPath, ClipFileMd5, Callback, CustomData)
  local timestamp = os.time()
  local BigPhotoName = string.format("%s_%s_%d_%d_%d", timestamp, CustomData.activity_sub_id, CustomData.RawWidth, CustomData.RawHeight, CustomData.NameFlag)
  local MiniPhotoName = string.format("%s_%s_%d_%d_M_%d", timestamp, CustomData.activity_sub_id, CustomData.RawWidth, CustomData.RawHeight, CustomData.NameFlag)
  Log.Debug("[PhotoServer] ReqUploadReportActivityPhoto", PhotoPath, SrcMd5, ClipPhotoPath, ClipFileMd5, BigPhotoName, "NameFlag:", CustomData.NameFlag)
  
  local function OnBigPhotoUploaded(bBigSuccess, bigProtoData)
    if not bBigSuccess then
      Log.Error("[PhotoServer] Cannot upload activity photo path", PhotoPath)
      Callback(false)
      return
    end
    
    local function OnMiniPhotoUploaded(bMiniSuccess, miniProtoData)
      if not bMiniSuccess then
        Log.Error("[PhotoServer] Cannot upload mini activity photo path", ClipPhotoPath)
        Callback(false)
        return
      end
      self:InternalNotifyServerActivity(Callback, bigProtoData.photo_name, SrcMd5, miniProtoData.photo_name, ClipFileMd5, CustomData)
    end
    
    self:ReqUploadTempPhoto(ClipPhotoPath, ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_ACT_TAKE_PHOTO, OnMiniPhotoUploaded, MiniPhotoName)
  end
  
  self:ReqUploadTempPhoto(PhotoPath, ProtoEnum.PlayerPhotoAlbumType.PLAYER_PHOTO_ALBUM_TYPE_ACT_TAKE_PHOTO, OnBigPhotoUploaded, BigPhotoName)
end

function PhotoServer:InternalNotifyServerActivity(Callback, BigProtoDataName, SrcMd5, MiniProtoDataName, ClipFileMd5, CustomData)
  local Cmd = ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_PHOTO_CONTEST_SUBMIT_REQ
  local Req = ProtoMessage:newZoneActivityPhotoContestSubmitReq()
  Req.photo_name = BigProtoDataName
  Req.photo_md5 = SrcMd5
  Req.mini_photo_name = MiniProtoDataName
  Req.mini_photo_md5 = ClipFileMd5
  Req.activity_id = CustomData.activity_id
  Req.activity_sub_id = CustomData.activity_sub_id
  Log.Debug("[PhotoServer] InternalNotifyServerActivity", Req.photo_name, Req.photo_md5, Req.mini_photo_name, Req.mini_photo_md5, Req.activity_id, Req.activity_sub_id)
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  local bSuccess = false
  
  local function OnSvrRspHandle(_, protoData)
    bSuccess = self:IfReceiveSuccess(protoData, "ZoneActivityPhotoContestSubmitRsp")
    Log.Debug("[PhotoServer] ZoneActivityPhotoContestSubmitRsp", bSuccess)
    if bSuccess then
      NRCModuleManager:DoCmd(TakePhotosModuleCmd.GetPhotoActivityManager):UpdateSubmitContest(protoData.phase_data, protoData.last_submit_time)
    else
      local isIdipBan = protoData.ban_info and protoData.ban_info.uin and 0 ~= protoData.ban_info.uin
      if isIdipBan then
        local timeStr = os.date("%Y-%m-%d %H:%M:%S", protoData.ban_info.ban_time)
        local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("banned_notice")
        local tipStr = string.format(GlobalConfig.str, protoData.ban_info.uin, timeStr, protoData.ban_info.ban_reason)
        local dialogContext = DialogContext()
        dialogContext:SetTitle(LuaText.TIPS):SetContent(tipStr):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true)
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, dialogContext)
      end
    end
    Callback(bSuccess)
  end
  
  bSuccess = _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
  if not bSuccess then
    Log.Error("[PhotoServer] ZoneActivityPhotoContestSubmitRsp send failed")
    Callback(bSuccess)
  end
end

return PhotoServer
