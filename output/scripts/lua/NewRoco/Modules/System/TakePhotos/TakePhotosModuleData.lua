local TakePhotosModuleEvent = require("NewRoco/Modules/System/TakePhotos/TakePhotosModuleEvent")
local TakePhotosModuleData = _G.NRCData:Extend("TakePhotosModuleData")
local SaveName = "TakePhotosSaveGame"
local SaveGameClassPath = "/Game/NewRoco/Modules/System/TakePhotos/Res/BP_TakePhotosSaveGame.BP_TakePhotosSaveGame_C"

local function bytes_to_string(bytes)
  local parts = {}
  for i = 1, bytes:Num() do
    parts[i] = string.char(bytes:Get(i))
  end
  return table.concat(parts)
end

function TakePhotosModuleData:Ctor()
  NRCData.Ctor(self)
  self.TheRT = nil
  self.TheRTRef = nil
  self.PhotoExternFileName = ".png"
  self.PhotoRTFormat = UE.ETextureRenderTargetFormat.RTF_RGBA8
  self.RefCount = 0
  self.ThePhotoBigTexture = nil
  self.ThePhotoBigTextureRef = nil
  self.CurPhotoMode = 0
  self.KEY = UE.UClass.Load("'/Game/NewRoco/Modules/System/TakePhotos/Res/BP_Key.BP_Key_C'")
  if self.KEY then
    self.KEY_REF = UnLua.Ref(self.KEY)
  end
  self:InitPetHandBookIndices()
end

function TakePhotosModuleData:GetPKey()
  if self.KEY and UE.UObject.IsValid(self.KEY) and self.KEY.GetDefaultObject then
    local CDO = self.KEY:GetDefaultObject()
    if CDO and CDO.PKey then
      local pkey = CDO.PKey
      local parts = {}
      for i = 1, pkey:Num() do
        parts[i] = string.char(pkey:Get(i))
      end
      return table.concat(parts)
    end
  end
  Log.Error("Invalid PKey")
end

function TakePhotosModuleData:InitSaveData()
  if UE.UAsyncSaveGameHandle then
    self.SaveDataProxy = NewObject(UE.UAsyncSaveGameHandle, UE4.UNRCPlatformGameInstance.GetInstance(), SaveName)
    self.SaveDataProxyRef = UnLua.Ref(self.SaveDataProxy)
    self.SaveDataProxy.Completed:Add(self.SaveDataProxy, function(_)
      self.SaveDataProxy.Completed:Clear()
      self.module.Controller.PhotoManager:InitLocalBriefList()
    end)
    self.SaveDataProxy:AsyncLoadByRawClassPath(SaveGameClassPath, SaveName)
  end
end

function TakePhotosModuleData:GetSaveData()
  if not self.SaveData then
    self.SaveData = self.SaveDataProxy and self.SaveDataProxy.SaveGameObject
  end
  return self.SaveData
end

function TakePhotosModuleData:IsSaveGameDataReady()
  return self:GetSaveData()
end

function TakePhotosModuleData:AsyncSaveGameData()
  if self.DelaySaveGameTimer then
    Log.Debug("[TakePhoto] pending save data")
    return
  end
  self.DelaySaveGameTimer = DelayManager:DelayFrames(1, function()
    self.DelaySaveGameTimer = nil
    Log.Debug("[TakePhoto] start save data")
    self.SaveDataProxy.Completed:Add(self.SaveDataProxy, function()
      self.SaveDataProxy.Completed:Clear()
      Log.Debug("[TakePhoto] save data completed")
    end)
    self.SaveDataProxy:AsyncSaveGameToSlot()
  end)
end

function TakePhotosModuleData:IfNeedNotifyDelete()
  local timestamp = self:GetSaveData().disable_notify_timestamp
  if not timestamp then
    return true
  end
  local Now = _G.ZoneServer:GetServerTime() // 1000
  local date1 = os.date("*t", timestamp)
  local date2 = os.date("*t", Now)
  Log.Info("[TakePhoto] IfNeedNotifyDelete", timestamp, " <> ", Now)
  return date1.year ~= date2.year or date1.month ~= date2.month or date1.day ~= date2.day
end

function TakePhotosModuleData:OnDeleteNotifyConfirm(bNeedDisableNotify)
  if bNeedDisableNotify then
    self:GetSaveData().disable_notify_timestamp = _G.ZoneServer:GetServerTime() // 1000
    self:AsyncSaveGameData()
  end
end

local DEFAULT_ENCRYPTION_KEY = "cG(.^TNRC9hY,DkX1KX2w)p(^Yo>}n}3"

local function ConvertStringToUint8Array(str)
  if not str or "" == str then
    return {}
  end
  local bytes = {}
  for i = 1, string.len(str) do
    local b = string.byte(str, i)
    bytes[i] = b
  end
  return bytes
end

local function ConvertUint8ArrayToString(bytes)
  local chars = {}
  for i = 1, bytes:Num() do
    local c = bytes:Get(i)
    chars[i] = string.char(c)
  end
  return table.concat(chars)
end

local UnixEpochTicks = 621355968000000000

local function GetLocalFileTime(PhotoFilePath)
  local Ticks = UEGetFileDateTime(PhotoFilePath) or 0
  if 0 == Ticks then
    return 0
  end
  return (Ticks - UnixEpochTicks) // 10000000
end

local TIME_OFFSET

local function GetTimeOffset()
  if not TIME_OFFSET then
    local File = UE.UBlueprintPathsLibrary.Combine({
      UE.UBlueprintPathsLibrary.ProjectSavedDir(),
      "a"
    })
    UE.UNRCStatics.SaveByteArrayToFile({
      math.random()
    }, File)
    TIME_OFFSET = GetLocalFileTime(File) - _G.ZoneServer:GetServerTime() // 1000
    UE.UNRCStatics.DeleteToFile(File)
  end
  return TIME_OFFSET
end

local function GetPhotoTimeName(PhotoPath)
  local Names = string.Split(PhotoPath, "/")
  local Name = Names[#Names]
  local EndIdx = string.find(Name, "%.") or #Name + 1
  local Len = 13
  local J = EndIdx - 1
  local I = J - Len + 1
  local T = math.tointeger(string.sub(Name, I, J) or "") or 0
  local Timestamp = T // 1000
  return Timestamp
end

function TakePhotosModuleData:GetLocalPhotoStats(PhotoFilePath)
  if not self:GetSaveData() then
    return nil, nil
  end
  local Uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local Key = PhotoFilePath .. Uin
  local Map = self:GetSaveData().local_photo_files
  local Val = Map:Find(Key)
  local InfoMap = self:GetSaveData().file_info_map
  local FileInfo = InfoMap and InfoMap:Find(Key)
  if FileInfo then
    local EncryptInfoCode = self:GetSaveData().encrypt_info_code
    local bValid = true
    if EncryptInfoCode then
      local CodeStruct = EncryptInfoCode:Find(Key)
      local DecryptInfo = UE.UCloudGameUtils.DecryptData(CodeStruct.Code, self:GetPKey())
      if DecryptInfo ~= FileInfo then
        bValid = false
        Log.Error("Invalid FileInfo", Key, FileInfo, "Expected:", DecryptInfo)
      end
      Log.Debug("DecryptInfo", DecryptInfo, "By", Key, FileInfo)
    end
    local Elems = string.split(FileInfo, ";")
    local PhotoInfo = _G.ProtoMessage:newPlayerPhotoAlbumInfo()
    PhotoInfo.pet_base_id_list = {}
    if bValid then
      PhotoInfo.include_myself = "1" == Elems[1]
      if Elems[2] then
        local PetBaseIds = string.split(Elems[2], ",")
        for i, PetBaseId in ipairs(PetBaseIds) do
          PetBaseId = math.tointeger(PetBaseId)
          if PetBaseId then
            table.insert(PhotoInfo.pet_base_id_list, PetBaseId)
          end
        end
      end
    else
      PhotoInfo.include_myself = false
    end
    FileInfo = PhotoInfo
  end
  if string.EndsWith(PhotoFilePath, "x") then
    Val = ""
  else
    local EncryptMd5File = PhotoFilePath .. "x"
    if string.EndsWith(Val, "_1") then
      Val = ""
    elseif string.EndsWith(Val, "_2") then
      local PKey = self:GetPKey()
      local EncryptMd5 = PKey and UE4.UCloudGameUtils.LoadDecryptedData(EncryptMd5File, PKey) or ""
      if string.EndsWith(EncryptMd5, "_2") then
        Log.Debug("[PhotoData] DecryptMd5 2:", PhotoFilePath, EncryptMd5, Val)
        if EncryptMd5 == Val then
          Val = string.sub(EncryptMd5, 1, string.len(EncryptMd5) - 2)
        else
          Val = ""
        end
      else
        Val = ""
      end
    else
      Log.Error("[PhotoData] Invalid Photo", PhotoFilePath, Val)
      Val = ""
    end
  end
  Log.Debug("[PhotoData] DecryptMd5:", PhotoFilePath, Val)
  return Val, FileInfo
end

function TakePhotosModuleData:RecoverPhoto()
end

function TakePhotosModuleData:RecordLocalPhotoStats(PhotoFilePath, Md5, PhotoInfo)
  if not self:GetSaveData() then
    return
  end
  local Uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local Key = PhotoFilePath .. Uin
  local EncryptMd5 = Md5
  local PKey = self:GetPKey()
  if PKey then
    EncryptMd5 = Md5 .. "_2"
    local EncryptMd5File = PhotoFilePath .. "x"
    if not UE.UCloudGameUtils.SaveEncryptedData(EncryptMd5, EncryptMd5File, PKey) then
      Log.Error("Invalid EncryptData", EncryptMd5File)
      return
    end
  else
    EncryptMd5 = Md5 .. "_1"
    local EncryptMd5File = PhotoFilePath .. "x"
    if not UE.UCloudGameUtils.SaveEncryptedData(EncryptMd5, EncryptMd5File, DEFAULT_ENCRYPTION_KEY) then
      Log.Error("Invalid EncryptData", EncryptMd5File)
      return
    end
  end
  local Map = self:GetSaveData().local_photo_files
  Map:Add(Key, EncryptMd5)
  self:GetSaveData().local_photo_files = Map
  if PhotoInfo then
    local PhotoInfoString = string.format("%s;%s", PhotoInfo.include_myself and 1 or 0, table.concat(PhotoInfo.pet_base_id_list, ","))
    local Info = self:GetSaveData().file_info_map
    if Info then
      Info:Add(Key, PhotoInfoString)
      self:GetSaveData().file_info_map = Info
    end
    local EncryptInfoCode = self:GetSaveData().encrypt_info_code
    if EncryptInfoCode then
      local Template = self:GetSaveData().code_template
      Template.Code = UE.UCloudGameUtils.EncryptData(PhotoInfoString, PKey)
      EncryptInfoCode:Add(Key, Template)
      Template.Code = UE.TArray(0)
      self:GetSaveData().encrypt_info_code = EncryptInfoCode
    end
  else
    Log.Error(" Cannot found photo info", PhotoFilePath)
  end
  self:AsyncSaveGameData()
end

function TakePhotosModuleData:RemoveLocalPhotoStats(PhotoFilePath)
  if not self:GetSaveData() then
    return
  end
  local Uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  local Key = PhotoFilePath .. Uin
  local Map = self:GetSaveData().local_photo_files
  Map:Remove(Key)
  self:GetSaveData().local_photo_files = Map
  local Info = self:GetSaveData().file_info_map
  Info:Remove(Key)
  self:GetSaveData().file_info_map = Info
  local EncryptInfoCode = self:GetSaveData().encrypt_info_code
  if EncryptInfoCode then
    EncryptInfoCode:Remove(Key)
    self:GetSaveData().encrypt_info_code = EncryptInfoCode
  end
  self:AsyncSaveGameData()
end

function TakePhotosModuleData:GetScreenSize()
  local Size = UE.FIntPoint(0, 0)
  local viewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local borderWidth = UE4.USlateBlueprintLibrary.GetNRCBorderWidth()
  local borderHeight = UE4.USlateBlueprintLibrary.GetNRCBorderHeight()
  viewportSize.X = viewportSize.X - borderWidth * 2
  viewportSize.Y = viewportSize.Y - borderHeight * 2
  Size.X = math.floor(viewportSize.X)
  Size.Y = math.floor(viewportSize.Y)
  return Size
end

function TakePhotosModuleData:CreateRT(Size)
  if not TEST_PHOTO_RT or not _G.RocoEnv.IS_EDITOR then
    local TestRT = UE.UKismetRenderingLibrary.CreateRenderTarget2D(UE4.UNRCPlatformGameInstance.GetInstance(), Size.X, Size.Y, self.PhotoRTFormat)
    local TestRTRef = UnLua.Ref(TestRT)
    return TestRT, TestRTRef
  else
    local TestRT = UE.UObject.Load("/Game/NewRoco/Modules/System/TakePhotos/TestCapture.TestCapture")
    local TestRTRef = UnLua.Ref(TestRT)
    UE.UNRCStatics.ChangeTextureToMatchScene(TestRT)
    return TestRT, TestRTRef
  end
end

function TakePhotosModuleData:Preload()
  if self.TheRT and not UE.UObject.IsValid(self.TheRT) then
    self.TheRT = nil
    Log.Error("Preload Invalid RenderTarget, need create, ref count", self.RefCount)
  end
  if not self.TheRT then
    local Size = self:GetScreenSize()
    self.TheRT, self.TheRTRef = self:CreateRT(Size)
    if self.TheRT then
      Log.Debug("TakePhoto RT Size=", self.TheRT.SizeX, self.TheRT.SizeY)
    end
  end
end

function TakePhotosModuleData:RequestRT()
  if self.TheRT and not UE.UObject.IsValid(self.TheRT) then
    self.TheRT = nil
    Log.Error("RequestRT Invalid RenderTarget, need create, ref count", self.RefCount)
  end
  if not self.TheRT then
    local Size = self:GetScreenSize()
    self.TheRT, self.TheRTRef = self:CreateRT(Size)
    if self.TheRT then
      Log.Debug("TakePhoto RT Size=", self.TheRT.SizeX, self.TheRT.SizeY)
    end
  end
  return self.TheRT
end

function TakePhotosModuleData:ReleaseRT()
  if self.TheRTRef and UE.UObject.IsValid(self.TheRTRef) then
    UnLua.Unref(self.TheRTRef)
  end
  self.TheRTRef = nil
  self.TheRT = nil
end

function TakePhotosModuleData:AddRef()
  self.RefCount = self.RefCount + 1
end

function TakePhotosModuleData:RemoveRef()
  self.RefCount = self.RefCount - 1
  if 0 == self.RefCount then
    self:Clear()
  end
end

function TakePhotosModuleData:Clear()
  Log.Debug("[TakePhoto] Clear Resources")
  self.RefCount = 0
  self.ThePhotoBigTexture = nil
  if self.ThePhotoBigTextureRef and UE.UObject.IsValid(self.ThePhotoBigTextureRef) then
    UnLua.Unref(self.ThePhotoBigTextureRef)
  end
  self.ThePhotoBigTextureRef = nil
  self:ReleaseRT()
end

function TakePhotosModuleData:InitPetHandBookIndices()
  local AllData = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_HANDBOOK):GetAllDatas()
  local PetBaseIdSet = {}
  for k, v in pairs(AllData) do
    if v.include_petbase_id then
      for i, idsWrap in ipairs(v.include_petbase_id) do
        local ids = idsWrap.petbase_id
        for _, id in ipairs(ids) do
          PetBaseIdSet[id] = true
        end
      end
    end
  end
  self.PetBaseIdSet = PetBaseIdSet
end

function TakePhotosModuleData:IsPetInHandbook(PetBaseId)
  return self.PetBaseIdSet and self.PetBaseIdSet[PetBaseId]
end

return TakePhotosModuleData
