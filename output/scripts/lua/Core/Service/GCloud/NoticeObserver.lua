local rapidjson = require("rapidjson")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local NoticeObserver = Class()

function NoticeObserver:Ctor()
  self.NoticeList = {}
end

function NoticeObserver:OnLoadNoticeData(NoticeRet)
  Log.Info("NoticeObserver:OnLoadNoticeData")
  if not NoticeRet then
    return
  end
  local NoticeInfo = NoticeRet:GetNoticeInfoList()
  self.NoticeList = {}
  Log.Info("NoticeObserver:OnLoadNoticeData NoticeInfo Len ", NoticeInfo:Length())
  for i = 1, NoticeInfo:Length() do
    local Metadata = NoticeInfo:Get(i)
    local Info = {}
    Info.ID = Metadata.noticeID
    Info.Content, Info.bSetCenter = self:ConvertRichText(tostring(Metadata.textInfo.noticeContent))
    Info.Title = tostring(Metadata.textInfo.noticeTitle)
    Info.Order = Metadata.order
    local extraJson = tostring(Metadata.extraJson)
    Log.Info("NoticeObserver: extraJson " .. extraJson)
    if extraJson and "" ~= extraJson and "nil" ~= extraJson then
      local status, extraTable = pcall(rapidjson.decode, extraJson)
      Log.Info("status ", status, " extraTable ", extraTable)
      if status and extraTable then
        Info.OnlyOnce = extraTable.onlyonce
        local platform = extraTable.platform
        Log.Info("platform ", platform)
        if platform and "" ~= platform then
          Info.Platforms = string.Split(tostring(platform), ",")
        else
          Info.Platforms = nil
        end
        Info.Version = extraTable.version
        local channel_str = extraTable.channel
        Log.Info("channel_str ", channel_str)
        if channel_str and "" ~= channel_str then
          Info.Channels = string.Split(tostring(channel_str), ",")
        else
          Info.Channels = nil
        end
      else
        Log.Warning("NoticeObserver: Failed to parse extraJson", extraJson)
      end
    end
    if self:CheckPlatformsValid(Info) and self:CheckVersionValid(Info) and self:CheckChannelsValid(Info) then
      self.NoticeList[#self.NoticeList + 1] = Info
    end
  end
  table.sort(self.NoticeList, function(A, B)
    return A.Order < B.Order
  end)
  if UE4.UNoticeStatics.IsLoginNotice() then
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.OnLoadLoginNoticeData, self.NoticeList)
  elseif _G.EmailModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.UpdateNoticeList, self.NoticeList)
  else
    Log.Error("NoticeObserver:OnLoadNoticeData EmailModuleCmd is nil")
  end
end

function NoticeObserver:CheckVersionValid(noticeInfo)
  if not noticeInfo then
    return false
  end
  if not noticeInfo.Version then
    return true
  end
  local CurAppVer = _G.AppMain:GetAppVersion()
  Log.Info("CurAppVer = ", CurAppVer, " NoticeInfo.Version = ", noticeInfo.Version)
  return CurAppVer == noticeInfo.Version
end

function NoticeObserver:CheckChannelsValid(noticeInfo)
  Log.Info("NoticeObserver:CheckChannelsValid")
  if not noticeInfo then
    return false
  end
  if not noticeInfo.Channels then
    return true
  end
  local curChannel = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetPackageChannel)
  Log.Info("NoticeObserver:CheckChannelsValid curChannel = ", curChannel)
  if not curChannel then
    return false
  end
  for _, v in ipairs(noticeInfo.Channels) do
    Log.Info("channel v = ", v)
    if curChannel == tostring(v) then
      return true
    end
  end
  return false
end

function NoticeObserver:CheckPlatformsValid(noticeInfo)
  Log.Info("NoticeObserver:CheckPlatformsValid")
  if not noticeInfo then
    return false
  end
  if not noticeInfo.Platforms then
    return true
  end
  for _, v in ipairs(noticeInfo.Platforms) do
    local platformValue = tonumber(v)
    if not platformValue then
      Log.Warning("NoticeObserver:CheckPlatformsValid invalid platform value", v)
    else
      Log.Info("Platforms v = ", v)
      if _G.RocoEnv.PLATFORM_ANDROID and (platformValue == _G.ProtoEnum.PlatType.PT_ANDROID or platformValue == _G.ProtoEnum.PlatType.PT_ALL_PLATFORM) then
        return true
      end
      if _G.RocoEnv.PLATFORM_IOS and (platformValue == _G.ProtoEnum.PlatType.PT_IOS or platformValue == _G.ProtoEnum.PlatType.PT_ALL_PLATFORM) then
        return true
      end
      if _G.RocoEnv.PLATFORM_WINDOWS and (platformValue == _G.ProtoEnum.PlatType.PT_PC or platformValue == _G.ProtoEnum.PlatType.PT_ALL_PLATFORM) then
        return true
      end
      if _G.RocoEnv.PLATFORM_OPENHARMONY and (platformValue == _G.ProtoEnum.PlatType.PT_HARMONY_OS or platformValue == _G.ProtoEnum.PlatType.PT_HARMONY_PC or platformValue == _G.ProtoEnum.PlatType.PT_ALL_PLATFORM) then
        return true
      end
    end
  end
  return false
end

local function HslToRgb(h, s, l)
  local function HueToRgb(p, q, t)
    if t < 0 then
      t = t + 1
    end
    if t > 1 then
      t = t - 1
    end
    if t < 0.16666666666666666 then
      return p + (q - p) * 6 * t
    end
    if t < 0.5 then
      return q
    end
    if t < 0.6666666666666666 then
      return p + (q - p) * (0.6666666666666666 - t) * 6
    end
    return p
  end
  
  if 0 == s then
    return l, l, l
  end
  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  return HueToRgb(p, q, h + 0.3333333333333333), HueToRgb(p, q, h), HueToRgb(p, q, h - 0.3333333333333333)
end

local function ConvertStyleAttributes(fullMatch, styleAttr)
  if type(styleAttr) ~= "string" or "" == styleAttr then
    return fullMatch
  end
  local h, s, l = styleAttr:match("color:hsl%((%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*%)")
  local fontSize = styleAttr:match("font%-size:(%d+)px")
  if not h and not fontSize then
    return fullMatch
  end
  local colorStr, sizeStr
  if h then
    local r, g, b = HslToRgb(tonumber(h) / 360, tonumber(s) / 100, tonumber(l) / 100)
    local R = math.floor(r * 255 + 0.5)
    local G = math.floor(g * 255 + 0.5)
    local B = math.floor(b * 255 + 0.5)
    colorStr = string.format("color=\"#%02x%02x%02x\"", R, G, B)
  end
  if fontSize then
    sizeStr = "size=\"" .. fontSize .. "\""
  end
  if colorStr and sizeStr then
    return colorStr .. " " .. sizeStr
  elseif colorStr then
    return colorStr
  else
    return sizeStr
  end
  return fullMatch
end

function NoticeObserver:ConvertRichText(Text)
  local bSetCenter = false
  Text = Text:gsub("(style=\"([^\"]+)\")", ConvertStyleAttributes)
  Text = Text:gsub("<strong>(.-)</strong>", "<span style=\"bold\">%1</>")
  if Text:find("<p style=\"text%-align:center;\">(.-)</p>") then
    bSetCenter = true
    Text = Text:gsub("<p style=\"text%-align:center;\">(.-)</p>", "%1\n")
  end
  Text = Text:gsub("(<img src=\".-\">)", "%1</>")
  Text = Text:gsub("<p>(.-)</p>", "%1\n")
  Text = Text:gsub("&nbsp;", "")
  Text = Text:gsub("</span>", "</>")
  Text = Text:gsub("<br>", "\n")
  return Text, bSetCenter
end

function NoticeObserver:ParseAndCalculateImageSHA1(Content)
  if not Content or "" == Content then
    return
  end
  for ImageUrl in Content:gmatch("<img src=\"([^\"]+)\"></?>") do
    Log.Info("NoticeObserver: Found image URL:", ImageUrl)
    local FileName = ImageUrl:match("([^/]+)$")
    if FileName then
      local SavedDir = UE4.UBlueprintPathsLibrary.ProjectSavedDir()
      local LocalPath = SavedDir .. "ImageCache/" .. FileName
      local FullPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(LocalPath)
      local bFileExists = UE4.UNRCStatics.FileExists(FullPath)
      if not bFileExists then
        Log.Info("NoticeObserver: \230\150\135\228\187\182\228\184\141\229\173\152\229\156\168,\232\183\179\232\191\135SHA1\233\170\140\232\175\129 - File:", FileName)
      else
        local ExpectedSHA1 = FileName:match("^([^%.]+)")
        local ActualSHA1, bGetSuccess = UE.UHotUpdateUtils.TryGetResFileHash(FullPath)
        Log.Info("NoticeObserver: Image SHA1 , FileName:", FileName, "ActualSHA1:", ActualSHA1)
        if not bGetSuccess then
          Log.Warning("NoticeObserver: \232\174\161\231\174\151SHA1\229\164\177\232\180\165,\229\136\160\233\153\164\230\150\135\228\187\182 - File:", FileName)
          self:ClearFile(FullPath)
        elseif ExpectedSHA1 and ActualSHA1 then
          if ActualSHA1:lower() ~= ExpectedSHA1:lower() then
            Log.Error("NoticeObserver: SHA1\228\184\141\229\140\185\233\133\141,\229\136\160\233\153\164\230\141\159\229\157\143\230\150\135\228\187\182 - File:", FileName, "actual:", ActualSHA1, "expected:", ExpectedSHA1)
            self:ClearFile(FullPath)
          else
            Log.Info("NoticeObserver: \226\156\147 SHA1\233\170\140\232\175\129\233\128\154\232\191\135 - File:", FileName)
          end
        end
      end
    end
  end
end

function NoticeObserver:ClearFile(FilePath)
  if not FilePath or "" == FilePath then
    return
  end
  local Success, Err = pcall(function()
    local FullPath = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(FilePath)
    local bDeleted = UE4.UNRCStatics.DeleteToFile(FullPath)
    if bDeleted then
      Log.Info("ClearFile: Successfully deleted file:", FullPath)
    else
      local bRemoved = os.remove(FullPath)
      if bRemoved then
        Log.Info("ClearFile: Successfully removed file using os.remove:", FullPath)
      else
        Log.Error("ClearFile: Failed to delete file:", FullPath)
      end
    end
  end)
  if not Success then
    Log.Error("ClearFile: Error occurred while deleting file:", FilePath, "Error:", Err)
  end
end

return NoticeObserver
