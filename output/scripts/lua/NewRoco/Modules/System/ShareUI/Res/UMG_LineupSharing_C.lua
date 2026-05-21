local UMG_LineupSharing_C = _G.NRCPanelBase:Extend("UMG_LineupSharing_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ShareModuleCmd = require("NewRoco.Modules.System.Share.ShareModuleCmd")

function UMG_LineupSharing_C:OnActive(data)
  _G.NRCAudioManager:PlaySound2DAuto(40002009, "UMG_LineupSharing_C:OnActive")
  self.data = data
  self.teamType = data.teamData.team_type
  self.id = ""
  local petData = {}
  local teamDataPets = data.teamData and data.teamData.pets or {}
  for i, teamDataPet in ipairs(teamDataPets) do
    local petDataItem = {}
    table.copy(teamDataPet, petDataItem)
    table.insert(petData, petDataItem)
  end
  self.petData = petData
  self.magicID = data.teamData.role_magic_id
  self:UpdateUI()
  self:UpdateShareData()
end

function UMG_LineupSharing_C:UpdateUI()
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
  self.PhotoSub.NRCGridView_54:InitGridView(petData1)
  self.PhotoSub.NRCGridView_55:InitGridView(petData2)
  local teamName = self.data.teamData.team_name
  if "" == teamName then
    teamName = LuaText.umg_petteam_1 .. self.data.teamIndex + 1
  end
  self.teamName = teamName
  self.PhotoSub.Text_1:SetText(teamName)
  if self.magicID then
    local magicItemConf = _G.DataConfigManager:GetBagItemConf(self.magicID)
    if magicItemConf then
      self.PhotoSub.Icon:SetPath(magicItemConf.icon)
    end
  else
    self.PhotoSub.CanvasPanel_73:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LineupSharing_C:UpdateShareData()
  if not self.petData then
    Log.Error("UMG_Lineup_Share petData nil")
    return
  end
  local encodePetData = NRCModuleManager:DoCmd(PetUIModuleCmd.EncodeShareTeamCode, self.petData, self.magicID, self.teamType, self.data.teamData.team_name)
  self.id = encodePetData
  local link = "https://rocom.qq.com/act/a20250703array/index.html"
  link = link .. "?" .. "shareData=" .. encodePetData .. "&name=" .. self.data.teamData.team_name
  Log.Debug("final link is " .. link)
  self.link = link
  if self.data.IsBanQRCode then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local qrCodeTexture = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetQRCodeTexture, link)
  if qrCodeTexture then
    self.PhotoSub.QRCodeImage:SetBrushFromTexture(qrCodeTexture, false)
  else
    Log.Error("No qrCodeTexture" .. link)
    local replacedTeamName = _G.DataConfigManager:GetLocalizationConf("lineup_code_roco_team") and _G.DataConfigManager:GetLocalizationConf("lineup_code_roco_team").msg or ""
    link = link .. "?" .. "shareData=" .. encodePetData .. "&name=" .. replacedTeamName
    local replaceQrTexture = _G.NRCModuleManager:DoCmd(ShareModuleCmd.GetQRCodeTexture, link)
    if replaceQrTexture then
      self.PhotoSub.QRCodeImage:SetBrushFromTexture(replaceQrTexture, false)
    else
      Log.Error("No qrCodeTexture with replace " .. link)
    end
  end
end

function UMG_LineupSharing_C:DecodePetInfo(petStr, attrStr)
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

function UMG_LineupSharing_C:AddCodeAnnotation()
  local shareCode = self.id
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

function UMG_LineupSharing_C:ShowShareChannelCode(qrcodeShow, qrcodeLink)
  if self.data.IsBanQRCode then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif qrcodeShow and qrcodeShow == Enum.ShareQRcodeScenario.SQRS_HIDE then
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PhotoSub.QRCode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LineupSharing_C:ResetShareChannelCode()
  self:UpdateShareData()
end

return UMG_LineupSharing_C
