local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_Lineup_Share_C = _G.NRCPanelBase:Extend("UMG_Lineup_Share_C")
local JsonUtils = require("Common.JsonUtils")
local ShareModuleEnum = require("NewRoco.Modules.System.Share.ShareModuleEnum")
local ShareModuleCmd = require("NewRoco.Modules.System.Share.ShareModuleCmd")

function UMG_Lineup_Share_C:OnConstruct(Rsp, teamIndex)
  self:SetChildViews(self.Share)
end

function UMG_Lineup_Share_C:OnActive(team, teamIndex)
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_Lineup_Share_C:OnActive")
  self.teamData = team
  self.teamType = team.team_type
  self.teamIndex = teamIndex
  self.id = ""
  local petData = {}
  local teamDataPets = self.teamData and self.teamData.pets or {}
  for i, teamDataPet in ipairs(teamDataPets) do
    local petDataItem = {}
    table.copy(teamDataPet, petDataItem)
    table.insert(petData, petDataItem)
  end
  self.petData = petData
  self.magicID = self.teamData.role_magic_id
  Log.Dump(self.petData, 5, "UMG_Lineup_Share_C")
  self:SetCommonTitle()
  self:OnAddEventListener()
  self:UpdateUI()
  self:UpdateShareData()
  self:SendTLog(team)
end

function UMG_Lineup_Share_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Lineup_Share_C:UpdateUI()
  for i, data in ipairs(self.petData) do
    local petBaseConfId = data and data.base_conf_id
    local isRandomPet = PetUtils.CheckIsRandomPetBase(petBaseConfId)
    data.isRandomPet = isRandomPet
    local NatureDataList = {}
    if data.attack_talent and 0 ~= data.attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
        num = data.attack_talent
      })
    end
    if data.defense_talent and 0 ~= data.defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
        num = data.defense_talent
      })
    end
    if data.hp_talent and 0 ~= data.hp_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
        num = data.hp_talent
      })
    end
    if data.special_attack_talent and 0 ~= data.special_attack_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
        num = data.special_attack_talent
      })
    end
    if data.special_defense_talent and 0 ~= data.special_defense_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
        num = data.special_defense_talent
      })
    end
    if data.speed_talent and 0 ~= data.speed_talent then
      table.insert(NatureDataList, {
        type = 1,
        attribute = Enum.AttributeType.AT_SPEED_PERCENT,
        num = data.speed_talent
      })
    end
    data.NatureDataList = NatureDataList
  end
  if self.teamType == Enum.PlayerTeamType.PTT_PVP_BATTLE_5 then
    while #self.petData < 3 do
      table.insert(self.petData, {empty = true})
    end
  else
    while #self.petData < 6 do
      table.insert(self.petData, {empty = true})
    end
  end
  local teamData = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfoByTeamType(self.teamType)
  for i = 1, #self.petData do
    if self.petData[i].blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or self.petData[i].blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      local fantasticID
      local skillData = teamData[i].skill.skill_data
      for _, skill in ipairs(skillData) do
        if skill.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          fantasticID = skill.id
          break
        end
      end
      if self.petData[i].skills then
        for _, v in ipairs(self.petData[i].skills) do
          if v.id == fantasticID then
            v.bFantastic = true
            local petData = teamData and teamData[i]
            local petGid = petData and petData.gid
            local skillId = v and v.id
            local seasonId = PetUtils.TryGetPetSkillSeasonId(petGid, skillId)
            v.fantasticSeasonId = seasonId
            break
          end
        end
      end
    end
  end
  local petData1 = {}
  local petData2 = {}
  for i, v in ipairs(self.petData) do
    if i <= 3 then
      petData1[i] = v
    else
      petData2[i - 3] = v
    end
  end
  self.Share.NRCGridView_54:InitGridView(petData1)
  self.Share.NRCGridView_55:InitGridView(petData2)
  local teamName = self.teamData.team_name
  if "" == teamName then
    teamName = LuaText.umg_petteam_1 .. self.teamIndex + 1
  end
  self.teamName = teamName
  self.Share.Text_1:SetText(teamName)
  if self.magicID then
    local magicItemConf = _G.DataConfigManager:GetBagItemConf(self.magicID)
    if magicItemConf then
      self.Share.Icon:SetPath(magicItemConf.icon)
    end
  else
    self.Share.CanvasPanel_73:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local playerInfoData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local appIconData
  if RocoEnv.PLATFORM_WINDOWS then
    appIconData = {
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_miyao1_png.img_miyao1_png'",
        caller = self,
        callback = self.ClipboardCopy
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Download_png.img_Share_Download_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.save
      }
    }
  elseif playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_WX then
    appIconData = {
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_miyao1_png.img_miyao1_png'",
        caller = self,
        callback = self.ClipboardCopy
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Download_png.img_Share_Download_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.save
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Wechat_png.img_Share_Wechat_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.WeChatFriend
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_CircleFriends_png.img_Share_CircleFriends_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.WeChatMoments
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Tiktok_png.img_Share_Tiktok_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.Tiktok
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_TiktokFriends_png.img_Share_TiktokFriends_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.TiktokFriend
      }
    }
  elseif playerInfoData.loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    appIconData = {
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_miyao1_png.img_miyao1_png'",
        caller = self,
        callback = self.ClipboardCopy
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Download_png.img_Share_Download_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.save
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_QQ_png.img_Share_QQ_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.QQFriend
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Qzone_png.img_Share_Qzone_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.Qzone
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_Tiktok_png.img_Share_Tiktok_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.Tiktok
      },
      {
        path = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/PetTeam/Frames/img_Share_TiktokFriends_png.img_Share_TiktokFriends_png'",
        caller = self,
        callback = self.ShareToChannel,
        way = ShareModuleEnum.ShareChannel.TiktokFriend
      }
    }
  end
  self.ShareList:InitGridView(appIconData)
end

function UMG_Lineup_Share_C:OnDeactive()
end

function UMG_Lineup_Share_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
end

function UMG_Lineup_Share_C:OnClickCloseBtn()
  self:OnClose()
end

function UMG_Lineup_Share_C:ClipboardCopy()
  local FullCode = self:AddCodeAnnotation(self.id)
  UE4.UNRCStatics.ClipboardCopy(FullCode)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.lineup_code_copy)
end

function UMG_Lineup_Share_C:ShareToChannel(way)
  if not table.contains(ShareModuleEnum.ShareChannel, way) then
    Log.Error("UMG_Lineup_Share_C ShareToChannel invalid channel" .. way)
    return
  end
  local scale = 1.4395
  local TempPhotos = UE.UBlueprintPathsLibrary.Combine({
    UE4.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
    "TempPhotos"
  })
  if not UE.UNRCStatics.DirectoryExists(TempPhotos) then
    UE.UNRCStatics.MakeDirectory(TempPhotos)
  end
  local PhotoPath = UE.UBlueprintPathsLibrary.Combine({
    TempPhotos,
    string.format("ShareTeam_%d.png", _G.ZoneServer:GetServerTime())
  })
  
  local function OnPermissionCallback(moveToAlbum)
    if UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), self.Share, PhotoPath, false, scale) then
      if moveToAlbum then
        local destPath = UE.UPlatformImageLibrary.SaveImageToAlbum(PhotoPath)
        if RocoEnv.PLATFORM_WINDOWS then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.save_success_location, destPath), nil, nil, 2)
        elseif RocoEnv.PLATFORM_OPENHARMONY then
          return
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_success_tips, nil, nil, 2)
        end
      end
    else
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_fail_tips, nil, nil, 2)
    end
  end
  
  if self.requestCode then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self.requestCode)
    self.requestCode = nil
  end
  local bGranted = UE.UNRCPermissionMgr.IfPermissionGranted(UE.ENRCPermissionType.AccessAlbum)
  if not bGranted and (RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS) then
    if not NRCModuleManager:DoCmd(ShareModuleCmd.CheckPermission, way, UE.ENRCPermissionType.AccessAlbum) then
      return
    end
    self.requestCode = UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.AccessAlbum, {
      self,
      function(_, bGranted)
        self.requestCode = nil
        if bGranted then
          OnPermissionCallback("save" == way)
        else
          self:LogError("!!!Permission!!!")
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.save_fail_tips, nil, nil, 2)
        end
      end
    })
  else
    OnPermissionCallback("save" == way)
  end
  if "save" ~= way then
    local absolutePath = UE.UNRCStatics.ConvertToAbsolutePath(PhotoPath, true)
    if UE.UNRCStatics.FileExists(PhotoPath) then
      NRCModuleManager:DoCmd(ShareModuleCmd.SharePic, absolutePath, way)
    elseif UE.UPlatformImageLibrary.SaveUserWidgetToImage(UE4Helper.GetCurrentWorld(), self.Share, PhotoPath, false, scale) then
      NRCModuleManager:DoCmd(ShareModuleCmd.SharePic, absolutePath, way)
    else
      Log.Error("save widget error")
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.share_fail_tips, nil, nil, 2)
    end
  end
end

function UMG_Lineup_Share_C:AddCodeAnnotation(shareCode)
  local magicItemConf = _G.DataConfigManager:GetBagItemConf(self.magicID)
  local FullCode = "### " .. self.teamName .. "\n"
  local DebugData = {
    "# \233\173\148\230\179\149\239\188\154",
    "\239\188\154",
    "#\230\131\179\232\166\129\228\189\191\231\148\168\232\191\153\229\165\151\233\152\181\229\174\185\239\188\140\232\175\183\229\133\136\229\164\141\229\136\182\229\136\176\229\137\170\232\180\180\230\157\191\239\188\140\231\132\182\229\144\142\229\156\168\230\184\184\230\136\143\228\184\173\231\154\132\231\188\150\233\152\159\231\149\140\233\157\162\232\191\155\232\161\140\231\178\152\232\180\180\227\128\130"
  }
  if magicItemConf then
    FullCode = FullCode .. DebugData[1] .. magicItemConf.name .. "\n" .. "#\n"
  else
    FullCode = FullCode .. "#\n"
  end
  for i, pet in ipairs(self.petData) do
    if not pet.empty then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(pet.base_conf_id)
      local bloodConf = _G.DataConfigManager:GetPetBloodConf(pet.blood_id)
      if bloodConf then
        FullCode = FullCode .. "# " .. petBaseConf.name .. DebugData[2] .. bloodConf.name
      else
        FullCode = FullCode .. "# " .. petBaseConf.name .. DebugData[2]
      end
      FullCode = FullCode .. "\227\128\129{"
      if pet.skills then
        for j, skill in ipairs(pet.skills) do
          local skillConf = _G.DataConfigManager:GetSkillConf(skill.id)
          FullCode = FullCode .. skillConf.name
          if j ~= #pet.skills then
            FullCode = FullCode .. "\227\128\129"
          end
        end
      end
      FullCode = FullCode .. "}\n"
    end
  end
  FullCode = FullCode .. "#\n"
  FullCode = FullCode .. shareCode .. "\n" .. "#\n"
  FullCode = FullCode .. DebugData[3]
  return FullCode
end

function UMG_Lineup_Share_C:UpdateShareData()
  if not self.petData then
    Log.Error("UMG_Lineup_Share petData nil")
    return
  end
  local encodePetData = NRCModuleManager:DoCmd(PetUIModuleCmd.EncodeShareTeamCode, self.petData, self.magicID, self.teamType, self.teamData.team_name)
  self.id = encodePetData
  local link = "https://rocom.qq.com/act/a20250703array/index.html"
  link = link .. "?" .. "shareData=" .. encodePetData .. "&name=" .. self.teamData.team_name
  Log.Debug("final link is " .. link)
  self.link = link
  local qrCodeTexture = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetQRCodeTexture, link)
  if qrCodeTexture then
    self.Share.QRCodeImage:SetBrushFromTexture(qrCodeTexture, false)
  else
    Log.Error("No qrCodeTexture" .. link)
    local replacedTeamName = _G.DataConfigManager:GetLocalizationConf("lineup_code_roco_team") and _G.DataConfigManager:GetLocalizationConf("lineup_code_roco_team").msg or ""
    link = link .. "?" .. "shareData=" .. encodePetData .. "&name=" .. replacedTeamName
    local replaceQrTexture = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetQRCodeTexture, link)
    if replaceQrTexture then
      self.Share.QRCodeImage:SetBrushFromTexture(replaceQrTexture, false)
    else
      Log.Error("No qrCodeTexture with replace " .. link)
    end
  end
end

function UMG_Lineup_Share_C:DecodeShareData(encodedStr)
  self.newPetData = {}
  self.decodedMagicID = nil
  self.decodedTeamType = nil
  local versionLength = 2
  local petDataLength = 210
  local magicIDLength = 4
  local teamTypeLength = 1
  local attrDataLength = 24
  local expectedLength = versionLength + petDataLength + magicIDLength + teamTypeLength + attrDataLength
  if #encodedStr ~= expectedLength then
    Log.Error("Invalid encoded string length: " .. #encodedStr .. ", expected: " .. expectedLength)
    return false
  end
  local petDataStr = string.sub(encodedStr, 1, petDataLength)
  local magicIDStr = string.sub(encodedStr, petDataLength + 1, petDataLength + magicIDLength)
  local teamTypeStr = string.sub(encodedStr, petDataLength + magicIDLength + 1, petDataLength + magicIDLength + teamTypeLength)
  local attrDataStr = string.sub(encodedStr, petDataLength + magicIDLength + teamTypeLength + 1)
  self.decodedMagicID = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, magicIDStr)
  self.decodedTeamType = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, teamTypeStr)
  for i = 0, 5 do
    local petStr = string.sub(petDataStr, i * 35 + 1, (i + 1) * 35)
    local attrStr = string.sub(attrDataStr, i * 4 + 1, (i + 1) * 4)
    if petStr ~= string.rep("0", 35) then
      local petInfo = self:DecodePetInfo(petStr, attrStr)
      table.insert(self.newPetData, petInfo)
    end
  end
  return true
end

function UMG_Lineup_Share_C:DecodePetInfo(petStr, attrStr)
  local petInfo = ProtoMessage:newSharedPetInfo()
  local baseConfIdStr = string.sub(petStr, 1, 5)
  local bloodIdStr = string.sub(petStr, 6, 7)
  local natureStr = string.sub(petStr, 8, 9)
  local natureDataStr = string.sub(petStr, 10, 15)
  local skillsStr = string.sub(petStr, 16, 35)
  local posAttrStr = string.sub(attrStr, 1, 2)
  local negAttrStr = string.sub(attrStr, 3, 4)
  petInfo.base_conf_id = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, baseConfIdStr)
  petInfo.blood_id = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, bloodIdStr)
  petInfo.nature = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, natureStr)
  petInfo.NatureDataList = {}
  petInfo.hp_talent = 0
  petInfo.attack_talent = 0
  petInfo.special_attack_talent = 0
  petInfo.defense_talent = 0
  petInfo.special_defense_talent = 0
  petInfo.speed_talent = 0
  for i = 1, 3 do
    local naturePart = string.sub(natureDataStr, (i - 1) * 2 + 1, i * 2)
    if "00" ~= naturePart then
      local attribute = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, naturePart)
      table.insert(petInfo.NatureDataList, {
        type = 1,
        attribute = attribute,
        num = 1
      })
      if attribute == Enum.AttributeType.AT_PHYATK_PERCENT then
        petInfo.attack_talent = 1
      elseif attribute == Enum.AttributeType.AT_PHYDEF_PERCENT then
        petInfo.defense_talent = 1
      elseif attribute == Enum.AttributeType.AT_HPMAX_PERCENT then
        petInfo.hp_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEATK_PERCENT then
        petInfo.special_attack_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEDEF_PERCENT then
        petInfo.special_defense_talent = 1
      elseif attribute == Enum.AttributeType.AT_SPEED_PERCENT then
        petInfo.speed_talent = 1
      end
    end
  end
  petInfo.skills = {}
  for i = 1, 4 do
    local skillPart = string.sub(skillsStr, (i - 1) * 5 + 1, i * 5)
    if "00000" ~= skillPart then
      local skillId = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, skillPart)
      table.insert(petInfo.skills, {id = skillId})
    end
  end
  petInfo.changed_nature_pos_attr_type = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, posAttrStr)
  petInfo.changed_nature_neg_attr_type = _G.NRCModuleManager:DoCmd(ShareModuleCmd.DecodeFilledBase64, negAttrStr)
  return petInfo
end

local base64 = {}
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function UMG_Lineup_Share_C:encode(data)
  local bytes = {}
  for i = 1, #data do
    bytes[#bytes + 1] = string.byte(data, i)
  end
  local result = {}
  for i = 1, #bytes, 3 do
    local b1, b2, b3 = bytes[i], bytes[i + 1], bytes[i + 2]
    local padding = 0
    if not b2 then
      b2, b3 = 0, 0
      padding = 2
    elseif not b3 then
      b3 = 0
      padding = 1
    end
    local group1 = math.floor(b1 / 4) + 1
    local group2 = b1 % 4 * 16 + math.floor(b2 / 16) + 1
    local group3 = b2 % 16 * 4 + math.floor(b3 / 64) + 1
    local group4 = b3 % 64 + 1
    table.insert(result, chars:sub(group1, group1))
    table.insert(result, chars:sub(group2, group2))
    if padding < 2 then
      table.insert(result, chars:sub(group3, group3))
    else
      table.insert(result, "=")
    end
    if padding < 1 then
      table.insert(result, chars:sub(group4, group4))
    else
      table.insert(result, "=")
    end
  end
  return table.concat(result)
end

function UMG_Lineup_Share_C:decode(b64str)
  local char_map = {}
  for i = 1, #chars do
    char_map[chars:sub(i, i)] = i - 1
  end
  char_map["="] = 0
  local result = {}
  local data = b64str:gsub("[^%w+/=]", "")
  for i = 1, #data, 4 do
    local c1, c2, c3, c4 = data:sub(i, i), data:sub(i + 1, i + 1), data:sub(i + 2, i + 2), data:sub(i + 3, i + 3)
    local v1, v2, v3, v4 = char_map[c1], char_map[c2], char_map[c3], char_map[c4]
    local byte1 = v1 * 4 + math.floor(v2 / 16)
    local byte2 = v2 % 16 * 16 + math.floor(v3 / 4)
    local byte3 = v3 % 4 * 64 + v4
    if "=" == c3 then
      table.insert(result, string.char(byte1))
    elseif "=" == c4 then
      table.insert(result, string.char(byte1, byte2))
    else
      table.insert(result, string.char(byte1, byte2, byte3))
    end
  end
  return table.concat(result)
end

function UMG_Lineup_Share_C:test()
  local DebugData = {
    {
      input = "",
      expected = "",
      desc = "\231\169\186\229\173\151\231\172\166\228\184\178"
    },
    {
      input = "A",
      expected = "QQ==",
      desc = "\229\141\149\229\173\151\232\138\130"
    },
    {
      input = "AB",
      expected = "QUI=",
      desc = "\229\143\140\229\173\151\232\138\130"
    },
    {
      input = "ABC",
      expected = "QUJD",
      desc = "\229\174\140\230\149\180\228\184\137\229\173\151\232\138\130"
    },
    {
      input = "Hello",
      expected = "SGVsbG8=",
      desc = "\232\139\177\230\150\135\230\150\135\230\156\172"
    },
    {
      input = "\230\181\139\232\175\149123",
      expected = "5rWL6K+VMTIz",
      desc = "\228\184\173\230\150\135+\230\149\176\229\173\151"
    },
    {
      input = "\000\239\191\189",
      expected = "AP8=",
      desc = "\228\186\140\232\191\155\229\136\182\229\173\151\232\138\130"
    }
  }
  print("Base64 \231\188\150\231\160\129\230\181\139\232\175\149:")
  print("-----------------")
  local DebugData = {}
  for i, test in ipairs(DebugData) do
    local encoded = base64.encode(test.input)
    local decoded = base64.decode(encoded)
    local status = encoded == test.expected and decoded == test.input
    print(string.format("\230\181\139\232\175\149 %d [%s]: %s -> %s | \232\167\163\231\160\129: %s | %s", i, test.desc, #test.input > 0 and string.format("%q", test.input) or DebugData[1], encoded, #decoded > 0 and string.format("%q", decoded) or DebugData[1], status and "\226\156\147" or "\226\156\151"))
  end
end

function UMG_Lineup_Share_C:SendTLog(PetTeamInfo)
  local key = "PVPTeamShareLog"
  local tempString = "PVPTeamShareLog|%s|%s|%s|%d|%d|%s|%s|%s|%d|%d|%d|%d|%s"
  local gameServerId = "nil"
  local deEventTime = os.date("%Y-%m-%d %H:%M:%S")
  local gameAppId = "1110613799"
  local platId = -1
  local zoneId = 0
  local openId = "nil"
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin() or 0
  local roleName = _G.DataModelMgr.PlayerDataModel:GetPlayerName() or "nil"
  local level = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  if _G.OnlineModuleCmd then
    local needData = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if needData and type(needData) == "table" then
      gameServerId = needData.serverName or "nil"
      platId = needData.plat_info.plat_id or -1
      zoneId = needData.zoneId or 0
      openId = needData.openid or "nil"
    end
  end
  local ActionType = 0
  local ShareFrom = PetTeamInfo.team_type
  local ShareType = 0
  if PetTeamInfo.team_type == Enum.PlayerTeamType.PTT_PVP_BATTLE_5 then
    ShareType = 1
  end
  local ShareCode = self.id
  local value = string.format(tempString, gameServerId, deEventTime, gameAppId, platId, zoneId, openId, uin, roleName, level, ActionType, ShareFrom, ShareType, ShareCode)
  for i = 1, 6 do
    if PetTeamInfo.pets[i] and PetTeamInfo.pets[i].base_conf_id then
      value = value .. "|" .. PetTeamInfo.pets[i].base_conf_id
    else
      value = value .. "|0"
    end
  end
  for i = 1, 6 do
    if PetTeamInfo.pets[i] then
      for j = 1, 4 do
        if PetTeamInfo.pets[i].skills and PetTeamInfo.pets[i].skills[j] then
          value = value .. "|" .. PetTeamInfo.pets[i].skills[j].id
        else
          value = value .. "|0"
        end
      end
    end
  end
  local TeamMagicID = PetTeamInfo.role_magic_id or 0
  local TeamName = self.teamName
  value = value .. "|" .. TeamMagicID
  value = value .. "|" .. TeamName
  _G.GEMPostManager:SendNRCTLog(key, value)
end

return UMG_Lineup_Share_C
