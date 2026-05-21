local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UIUtils = {}
local EmojiRanges = {
  {128512, 128591},
  {127744, 128511},
  {128640, 128767},
  {128102, 129535},
  {127462, 127487},
  {9728, 9983},
  {9984, 10175},
  {65024, 65039},
  {917536, 917631},
  {8205, 8205},
  {8592, 8703},
  {11008, 11263},
  {12800, 13055},
  {8960, 9215},
  {9312, 9449},
  {10496, 10623},
  {9632, 9727}
}
local EmojiSingleRanges = {
  8252,
  8265,
  12349,
  8505,
  12336,
  169,
  174,
  8482
}
local AsciiWhiteMap = {}
local Utf8BlackMap = {}
local IsMapInitialized = false

function UIUtils.BuildAsciiWhiteList()
  if IsMapInitialized then
    return
  end
  AsciiWhiteMap = {}
  Utf8BlackMap = {}
  local asciiWhiteChars = (_G.DataConfigManager:GetRoleGlobalConfig("name_ascii_white_list") or {}).str or ""
  local utf8BlackChars = (_G.DataConfigManager:GetRoleGlobalConfig("name_utf8_black_list") or {}).str or ""
  for code = string.byte("a"), string.byte("z") do
    AsciiWhiteMap[code] = true
  end
  for code = string.byte("A"), string.byte("Z") do
    AsciiWhiteMap[code] = true
  end
  for code = string.byte("0"), string.byte("9") do
    AsciiWhiteMap[code] = true
  end
  if "" ~= asciiWhiteChars then
    for i = 1, #asciiWhiteChars do
      local char = asciiWhiteChars:sub(i, i)
      local charCode = string.byte(char)
      if charCode then
        AsciiWhiteMap[charCode] = true
      end
    end
  end
  if "" ~= utf8BlackChars then
    local ranges = string.Split(utf8BlackChars, ";")
    for _, rangeStr in ipairs(ranges) do
      if rangeStr and "" ~= rangeStr then
        if rangeStr:find("~") then
          local startHex, endHex = rangeStr:match("(0x[%x]+)~?(0x[%x]*)")
          if "" == endHex then
            local code = tonumber(startHex)
            if code then
              Utf8BlackMap[code] = true
            end
          else
            local startCode = tonumber(startHex)
            local endCode = tonumber(endHex)
            if startCode and endCode and startCode <= endCode then
              for code = startCode, endCode do
                Utf8BlackMap[code] = true
              end
            end
          end
        else
          local code = tonumber(rangeStr)
          if code then
            Utf8BlackMap[code] = true
          end
        end
      end
    end
  end
  IsMapInitialized = true
end

UIUtils.CheckCoinType = {CI_BagItem = 1, CI_VisualItem = 2}
UIUtils.ScrollPageItemType = {None = 0, PetWareHouseExchange = 1}

function UIUtils.SetIconQuality(iconBg, quality)
  if not iconBg then
    return
  end
  iconBg:SetVisibility(UE4.ESlateVisibility.Visible)
  if 0 == quality then
    iconBg:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    iconBg:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    iconBg:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    iconBg:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    iconBg:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    iconBg:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UIUtils.SetIconQualityColor(iconBg, quality)
  if not iconBg then
    return
  end
  iconBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if 0 == quality then
  elseif 1 == quality then
    iconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    iconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    iconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    iconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality or 6 == quality then
    iconBg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UIUtils.GetQualityColor(quality)
  if 0 == quality then
    return UEPath.Color_QUALITY_1
  elseif 1 == quality then
    return UEPath.Color_QUALITY_1
  elseif 2 == quality then
    return UEPath.Color_QUALITY_2
  elseif 3 == quality then
    return UEPath.Color_QUALITY_3
  elseif 4 == quality then
    return UEPath.Color_QUALITY_4
  elseif 5 == quality or 6 == quality then
    return UEPath.Color_QUALITY_5
  end
end

function UIUtils.SetItemIcon(itemId, type, num, icon, iconBg, numText)
  local iconPath, quality
  if type == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(itemId)
    if nil ~= vItemConf then
      iconPath = vItemConf.bigIcon
      quality = vItemConf.item_quality
    end
  elseif type == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemId)
    if nil ~= bagItemConf then
      iconPath = bagItemConf.icon
      quality = bagItemConf.item_quality
    end
  end
  icon:SetPath(iconPath)
  UIUtils.SetIconQuality(iconBg, quality)
  if numText and num then
    numText:SetText(num)
  end
end

function UIUtils.IsClickable(panel)
  if not panel then
    return false
  end
  local Visibility = panel:GetVisibility()
  if Visibility ~= UE4.ESlateVisibility.HitTestInvisible and Visibility ~= UE4.ESlateVisibility.Collapsed and Visibility ~= UE4.ESlateVisibility.Hidden then
    return true
  end
  return false
end

function UIUtils.SetBtnGary(btn, bIsGary, bIsEnable, normalIconPath)
  if btn then
    if btn.SetClickAble then
      btn:SetClickAble(bIsEnable)
    end
    if btn.BG and btn.BG.SetPath then
      if bIsGary then
        btn.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
      else
        btn.BG:SetPath(normalIconPath or "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
      end
    end
  end
end

function UIUtils.CheckNameIsLegal(_string)
  if not IsMapInitialized then
    UIUtils.BuildAsciiWhiteList()
  end
  if _string and #_string > 0 then
    local chars = string.GetPrintTable(_string)
    for i, char in pairs(chars) do
      local charCode = UIUtils.CharToCode(char)
      if not charCode then
        return false
      end
      if Utf8BlackMap[charCode] then
        return false
      end
      if charCode <= 127 and not AsciiWhiteMap[charCode] then
        return false
      end
    end
  end
  return true
end

function UIUtils.CharToCode(_char)
  if not _char or type(_char) ~= "string" or 0 == #_char then
    return nil
  end
  if #_char > 1 then
    local success, code = pcall(function()
      return utf8.codepoint(_char, 1, 1)
    end)
    return success and code or nil
  else
    return string.byte(_char)
  end
end

function UIUtils.CheckInvalidCharByFont(_char, _fontObject)
  if not UE4.UObject.IsValid(_fontObject) then
    return true
  end
  local fontSize = UE4.UNRCStatics.GetStringHeightSize(_char, _fontObject)
  if fontSize <= 0 and _char and "" ~= _char and " " ~= _char then
    return false
  end
  return true
end

function UIUtils.RemoveInvalidCharsByFont(_string, _fontObject)
  if not UE4.UObject.IsValid(_fontObject) then
    return _string
  end
  local resultString = ""
  if _string and #_string > 0 then
    local chars = string.GetPrintTable(_string)
    for i, char in pairs(chars) do
      if UIUtils.CheckInvalidCharByFont(char, _fontObject) then
        resultString = resultString .. char
      end
    end
  end
  return resultString
end

function UIUtils.RemoveInvalidCharsHandle(_UEditableText)
  if _UEditableText then
    local text = _UEditableText:GetText()
    local resultString = UIUtils.RemoveInvalidCharsByFont(text, _UEditableText.WidgetStyle.Font.FontObject)
    if resultString ~= text then
      _UEditableText:SetText(resultString)
    end
  end
end

function UIUtils.RemoveEmoji(string)
  local resultString = ""
  for _, char in utf8.codes(string) do
    if not UIUtils.CheckIsEmoji(char) then
      resultString = resultString .. utf8.char(char)
    end
  end
  return resultString
end

function UIUtils.CheckEmoji(string)
  local resultString = ""
  for _, char in utf8.codes(string) do
    if UIUtils.CheckIsEmoji(char) then
      return true
    end
  end
  return false
end

function UIUtils.CheckIsEmoji(char)
  for _, single in ipairs(EmojiSingleRanges) do
    if char == single then
      return true
    end
  end
  for k, range in ipairs(EmojiRanges) do
    if char >= range[1] and char <= range[2] or char > 65535 then
      return true
    end
  end
  return false
end

function UIUtils.CheckEnterCondition(coinInfos)
  local enoughCoinType = {}
  if coinInfos and #coinInfos > 0 then
    for k, coinInfo in ipairs(coinInfos) do
      if coinInfo[1] == UIUtils.CheckCoinType.CI_BagItem then
        local curCoinNum = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, coinInfo[2])
        if nil == curCoinNum then
          curCoinNum = 0
        else
          curCoinNum = curCoinNum.num
        end
        if curCoinNum >= coinInfo[3] then
          table.insert(enoughCoinType, {
            CheckType = UIUtils.CheckCoinType.CI_BagItem,
            CoinType = coinInfo[2]
          })
        end
      elseif coinInfo[1] == UIUtils.CheckCoinType.CI_VisualItem then
        local curCoinNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
        if curCoinNum >= coinInfo[3] then
          table.insert(enoughCoinType, {
            CheckType = UIUtils.CheckCoinType.CI_VisualItem,
            CoinType = coinInfo[2]
          })
        end
      end
    end
  end
  return enoughCoinType
end

function UIUtils.GetNpcSceneResIdByPosXY(posX, posY)
  if posX >= -1000000.0 and posX <= -600000.0 and posY >= -1000000.0 and posY <= -600000.0 then
    return 10018
  end
  return 10003
end

function UIUtils.SetAvatarSuit(avatarActor, fashionIds, salonIds, gender)
  if not avatarActor then
    Log.Error("UIUtils.SetAvatarSuit: avatarActor is nil")
    return
  end
  local defaultSuitClass
  if nil == gender then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if nil == localPlayer then
      Log.Error("player is nil")
      return
    end
    gender = localPlayer.gender
  end
  if 1 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  elseif 2 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  local defaultFashionIds, defaultSalonIds
  if nil == fashionIds or 0 == #fashionIds then
    fashionIds, defaultSalonIds = UIUtils.GetDefaultWearIds(gender)
  end
  if nil == salonIds or 0 == #salonIds then
    defaultFashionIds, salonIds = UIUtils.GetDefaultWearIds(gender)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  local fullSalonIds = {}
  for k, v in ipairs(salonIds) do
    local conf = _G.DataConfigManager:GetSalonItemConf(v)
    local salonAvatarId = conf.avatar_id
    table.insert(fullSalonIds, UIUtils.GetFullSalonId(salonAvatarId, conf.texture_id))
  end
  defaultSuitObj:SetSalons(fullSalonIds)
  for k, v in ipairs(fashionIds) do
    defaultSuitObj:SetBody(v, 0)
  end
  avatarActor:SwitchAvatarSuit(defaultSuitObj)
end

function UIUtils.SetPlayerSuit(playerActor, fashionIds, salonIds, gender)
  local defaultSuitClass
  if nil == gender then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if nil == localPlayer then
      Log.Error("player is nil")
      return
    end
    gender = localPlayer.gender
  end
  if 1 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
  elseif 2 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
  end
  local defaultFashionIds, defaultSalonIds
  if nil == fashionIds or 0 == #fashionIds then
    fashionIds, defaultSalonIds = UIUtils.GetDefaultWearIds(gender)
  end
  if nil == salonIds or 0 == #salonIds then
    defaultFashionIds, salonIds = UIUtils.GetDefaultWearIds(gender)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  local fullSalonIds = {}
  for k, v in ipairs(salonIds) do
    local salonAvatarId = _G.DataConfigManager:GetSalonItemConf(v).avatar_id
    table.insert(fullSalonIds, UIUtils.GetFullSalonId(salonAvatarId, 0))
  end
  defaultSuitObj:SetSalons(fullSalonIds)
  for k, v in ipairs(fashionIds) do
    defaultSuitObj:SetBody(v, 0)
  end
  local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  avatarSystem:StartSwitchAvatarSuit(playerActor.Mesh, defaultSuitObj)
end

function UIUtils.GetFullSalonId(salonId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = salonId * 100 + colorIndex
  return fullSalonId
end

function UIUtils.GetSalonIdFromFull(fullSalonId)
  local result = math.floor(fullSalonId / 100)
  return result
end

function UIUtils.MergeRewards(_rspRewards)
  local newRewards = {}
  for _, goodsItem in ipairs(_rspRewards) do
    if goodsItem.reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_LEVEL_REWARD then
      table.insert(newRewards, goodsItem)
    end
  end
  return newRewards
end

function UIUtils.GetDefaultWearIds(gender)
  local fashionIds = {}
  local salonIds = {}
  if gender == ProtoEnum.ESexValue.SEX_MALE then
    local fashionList = _G.DataConfigManager:GetRoleGlobalConfig("fashion_free_item_pc1").numList
    local salonList = _G.DataConfigManager:GetRoleGlobalConfig("salon_free_item_pc1").numList
    for k, v in pairs(fashionList) do
      if v > 100 then
        table.insert(fashionIds, v)
      end
    end
    for k, v in pairs(salonList) do
      if v > 100 then
        table.insert(salonIds, v)
      end
    end
  elseif gender == ProtoEnum.ESexValue.SEX_FEMALE then
    local fashionList = _G.DataConfigManager:GetRoleGlobalConfig("fashion_free_item_pc2").numList
    local salonList = _G.DataConfigManager:GetRoleGlobalConfig("salon_free_item_pc2").numList
    for k, v in pairs(fashionList) do
      if v > 100 then
        table.insert(fashionIds, v)
      end
    end
    for k, v in pairs(salonList) do
      if v > 100 then
        table.insert(salonIds, v)
      end
    end
  end
  return fashionIds, salonIds
end

function UIUtils.SetAvatarFashion(avatarPlayer, fashionId, bChoosed, glassInfo)
  UIUtils.ChangeSkeletalMesh(avatarPlayer, _G.Enum.GoodsType.GT_FASHION, fashionId, bChoosed, glassInfo)
end

function UIUtils.SetAvatarSalon(avatarPlayer, salonId)
  local salonItemConf = _G.DataConfigManager:GetSalonItemConf(salonId)
  local fullSalonId = UIUtils.GetFullSalonId(salonItemConf.avatar_id, salonItemConf.texture_id)
  avatarPlayer:SetAvatarMaterialID(fullSalonId)
end

function UIUtils.ChangeSkeletalMesh(avatarPlayer, itemType, itemId, bChoosed, glassInfo)
  if not avatarPlayer then
    Log.Warning("avatarPlayer is nil")
    return
  end
  local itemConf, bBodyType, avatarEnum
  if itemType == _G.Enum.GoodsType.GT_FASHION then
    itemConf = _G.DataConfigManager:GetFashionItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(itemConf.type)
    end
  elseif itemType == _G.Enum.GoodsType.GT_SALON then
    itemConf = _G.DataConfigManager:GetSalonItemConf(itemId)
    if itemConf then
      bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumSalon(itemConf.type)
    end
  end
  if avatarEnum and itemConf then
    if bBodyType then
      if bChoosed then
        if itemType == _G.Enum.GoodsType.GT_SALON then
          avatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
        else
          local glassId = 0
          if nil ~= glassInfo then
            glassId = UIUtils.GetGlassInfoId(glassInfo)
          end
          avatarPlayer:SetAvatarModelID(itemId, true, glassId)
        end
      else
        local bFashion, configEnum, Enum = UIUtils.GetConfigEnumFromFashionId(itemId)
        avatarPlayer:SetAvatarModelID(Enum, true, 0)
      end
    elseif bChoosed then
      if itemType ~= _G.Enum.GoodsType.GT_FASHION or itemConf.change_bp then
      else
      end
    else
      avatarPlayer:SetAvatarModelID(avatarEnum, true, 0)
    end
  end
end

function UIUtils.GetConfigEnumFromFashionId(Id)
  if Id < 10000000 then
    return
  end
  local bFashion = true
  local configEnum = _G.Enum.FashionLabelType.FLT_BEGIN
  local Base = 0
  if Id > 99999999 then
    Base = 1000000000
  else
    Base = 10000000
  end
  local AvatarEnum = math.floor(Id / (Base / 100) % 100)
  bFashion, configEnum = UIUtils.GetConfigEnumByAvatarEnum(AvatarEnum, Base)
  return bFashion, configEnum, AvatarEnum
end

function UIUtils.GetAvatarEnumByConfigEnumFashion(cfgEnum)
  local avatarEnum, bBodyType
  local Enum = _G.Enum
  local UE4 = _G.UE4
  if cfgEnum == Enum.FashionLabelType.FLT_TOPS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Body
  elseif cfgEnum == Enum.FashionLabelType.FLT_BOTTOMS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Pants
  elseif cfgEnum == Enum.FashionLabelType.FLT_DRESSES then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Body
  elseif cfgEnum == Enum.FashionLabelType.FLT_SOCKS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Socks
  elseif cfgEnum == Enum.FashionLabelType.FLT_SHOES then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Shoes
  elseif cfgEnum == Enum.FashionLabelType.FLT_HATS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Hat
  elseif cfgEnum == Enum.FashionLabelType.FLT_GLASSES then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Faces
  elseif cfgEnum == Enum.FashionLabelType.FLT_MASKES then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Masks
  elseif cfgEnum == Enum.FashionLabelType.FLT_EARRINGS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Earrings
  elseif cfgEnum == Enum.FashionLabelType.FLT_RINGS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Hands
  elseif cfgEnum == Enum.FashionLabelType.FLT_BAGS then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Bag
  elseif cfgEnum == Enum.FashionLabelType.FLT_XIEWA then
  elseif cfgEnum == Enum.FashionLabelType.FLT_PENDANTA then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Bags
  elseif cfgEnum == Enum.FashionLabelType.FLT_WAND then
    bBodyType = true
    avatarEnum = UE4.EAvatarBodyType.Wand
  end
  return bBodyType, avatarEnum
end

function UIUtils.GetAvatarEnumByConfigEnumSalon(cfgEnum)
  local avatarEnum, bBodyType
  local Enum = _G.Enum
  local UE4 = _G.UE4
  if cfgEnum == Enum.SalonLabelType.SLT_SKIN then
    avatarEnum = UE4.EAvatarSalonType.Skin
    bBodyType = false
  elseif cfgEnum == Enum.SalonLabelType.SLT_HAIR then
    avatarEnum = UE4.EAvatarBodyType.Hair
    bBodyType = true
  elseif cfgEnum == Enum.SalonLabelType.SLT_EYEBORWS then
    avatarEnum = UE4.EAvatarBodyType.Brown
    bBodyType = true
  elseif cfgEnum == Enum.SalonLabelType.SLT_EYELASH then
    avatarEnum = UE4.EAvatarBodyType.EyeSocket
    bBodyType = true
  elseif cfgEnum == Enum.SalonLabelType.SLT_EYES then
    avatarEnum = UE4.EAvatarSalonType.EyeBall
    bBodyType = false
  elseif cfgEnum == Enum.SalonLabelType.SLT_MAKEUP then
    avatarEnum = UE4.EAvatarSalonType.MakeUp
    bBodyType = false
  end
  return bBodyType, avatarEnum
end

function UIUtils.GetConfigEnumByAvatarEnum(avatarEnum, Base)
  local bFashion, configEnum
  local Enum = _G.Enum
  local UE4 = _G.UE4
  if avatarEnum == UE4.EAvatarBodyType.Hair then
    bFashion = false
    configEnum = Enum.SalonLabelType.SLT_HAIR
  elseif avatarEnum == UE4.EAvatarBodyType.Face then
    bFashion = false
  elseif avatarEnum == UE4.EAvatarBodyType.Brown then
    bFashion = false
    configEnum = Enum.SalonLabelType.SLT_EYEBORWS
  elseif avatarEnum == UE4.EAvatarBodyType.EyeSocket then
    bFashion = false
    configEnum = Enum.SalonLabelType.SLT_EYELASH
  elseif avatarEnum == UE4.EAvatarBodyType.Eye then
    bFashion = false
    configEnum = Enum.SalonLabelType.SLT_EYES
  elseif avatarEnum == UE4.EAvatarBodyType.Ear then
    bFashion = false
  elseif avatarEnum == UE4.EAvatarBodyType.Body then
    bFashion = true
    if Base > 99999999 then
      configEnum = Enum.FashionLabelType.FLT_DRESSES
    else
      configEnum = Enum.FashionLabelType.FLT_TOPS
    end
  elseif avatarEnum == UE4.EAvatarBodyType.Hands then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_RINGS
  elseif avatarEnum == UE4.EAvatarBodyType.Pants then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_BOTTOMS
  elseif avatarEnum == UE4.EAvatarBodyType.Socks then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_SOCKS
  elseif avatarEnum == UE4.EAvatarBodyType.Shoes then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_SHOES
  elseif avatarEnum == UE4.EAvatarBodyType.Bag then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_BAGS
  elseif avatarEnum == UE4.EAvatarBodyType.Hat then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_HATS
  elseif avatarEnum == UE4.EAvatarBodyType.Heads then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_HATS
  elseif avatarEnum == UE4.EAvatarBodyType.Faces then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_GLASSES
  elseif avatarEnum == UE4.EAvatarBodyType.Masks then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_MASKES
  elseif avatarEnum == UE4.EAvatarBodyType.Earrings then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_EARRINGS
  elseif avatarEnum == UE4.EAvatarBodyType.HandRings then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_RINGS
  elseif avatarEnum == UE4.EAvatarBodyType.Bag then
    bFashion = true
  elseif avatarEnum == UE4.EAvatarBodyType.Wand then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_WAND
  elseif avatarEnum == UE4.EAvatarBodyType.Bags then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_PENDANTA
  elseif avatarEnum == UE4.EAvatarBodyType.Hg then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_HATS
  elseif avatarEnum == UE4.EAvatarBodyType.Hp then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_HATS
  elseif avatarEnum == UE4.EAvatarBodyType.Wh then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_DRESSES
  elseif avatarEnum == UE4.EAvatarBodyType.Wa then
    bFashion = true
    configEnum = Enum.FashionLabelType.FLT_DRESSES
  end
  return bFashion, configEnum
end

function UIUtils.GetShowNameByCheckFriendNote(uin, oriName, isUseNoteColor)
  local noteStr = _G.DataModelMgr.PlayerDataModel:GetFriendNoteByUin(uin)
  local resultName = oriName
  if noteStr and "" ~= noteStr then
    if isUseNoteColor then
      resultName = string.safeFormat("<span color=\"#d87a35\">%s</>", noteStr)
    else
      resultName = noteStr
    end
  end
  return resultName
end

function UIUtils.SetTextPlayerNameByCheckFriendNote(text, uin, oriName, oriColor)
  if not text then
    Log.Error("UIUtils.SetTextPlayerNameByCheckFriendNote: text is nil")
    return
  end
  if not oriName then
    Log.Error("UIUtils.SetTextPlayerNameByCheckFriendNote: oriName is nil")
    return
  end
  if not UE.UObject.IsA(text, UE.UTextBlock) and not UE.UObject.IsA(text, UE.URichTextBlock) then
    Log.Error("UIUtils.SetTextPlayerNameByCheckFriendNote: text is not a UTextBlock and not a URichTextBlock", text)
    return
  end
  if not text.SetText then
    Log.Error("UIUtils.SetTextPlayerNameByCheckFriendNote: text does not have SetText method", text)
    return
  end
  if not text.SetColorAndOpacity then
    Log.Error("UIUtils.SetTextPlayerNameByCheckFriendNote: text does not have SetColorAndOpacity method", text)
    return
  end
  local noteStr = _G.DataModelMgr.PlayerDataModel:GetFriendNoteByUin(uin)
  if noteStr and "" ~= noteStr then
    text:SetText(noteStr)
    text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#d87a35FF"))
  else
    text:SetText(oriName)
    text:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(oriColor))
  end
end

function UIUtils.SetPlayerHeadIcon(headIconWidget, card_icon_selected, bUseBigHeadIcon)
  if not headIconWidget then
    if not _G.RocoEnv.IS_SHIPPING then
      Log.Error("UIUtils.SetPlayerHeadIcon: headIconWidget is nil")
    end
    return
  end
  if not headIconWidget.SetPath then
    Log.Error("UIUtils.SetPlayerHeadIcon: headIconWidget does not have SetPath method")
    return
  end
  if not card_icon_selected or 0 == card_icon_selected then
    Log.Error("UIUtils.SetPlayerHeadIcon: card_icon_selected is nil or 0")
    return
  end
  local CardIconConf = _G.DataConfigManager:GetCardIconConf(card_icon_selected)
  if not CardIconConf then
    Log.Error("UIUtils.SetPlayerHeadIcon: CardIconConf is nil for id", card_icon_selected)
    return
  end
  local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
  if bUseBigHeadIcon then
    path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BigHeadIcon256/"
  end
  local AvatarPath = CardIconConf.icon_resource_path
  AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
  headIconWidget:SetPath(AvatarPath)
end

function UIUtils.SafeSetImagePath(imageWidget, iconPath, ignoreError)
  if not imageWidget then
    if not ignoreError and not _G.RocoEnv.IS_SHIPPING then
      Log.Error("UIUtils.SafeSetImagePath: headIconWidget is nil")
    end
    return
  end
  if not imageWidget.SetPath then
    if not ignoreError then
      Log.Trace("UIUtils.SafeSetImagePath: imageWidget does not have SetPath method")
    end
    return
  end
  imageWidget:SetPath(iconPath)
end

function UIUtils.SafeSetText(textWidget, textStr, ignoreError)
  if not textWidget then
    if not ignoreError and not _G.RocoEnv.IS_SHIPPING then
      Log.Error("UIUtils.SafeSetText: textWidget is nil")
    end
    return
  end
  if textWidget.SetText then
    textWidget:SetText(textStr)
  elseif not ignoreError then
    Log.Error("UIUtils.SafeSetText: textWidget does not have SetText method")
  end
end

function UIUtils.SafeSetVisibility(widget, SlateVisibility, ignoreError)
  if not widget then
    if not ignoreError and not _G.RocoEnv.IS_SHIPPING then
      Log.Error("UIUtils.SafeSetVisibility: widget is nil")
    end
    return
  end
  if not ignoreError and not UE.UObject.IsA(widget, UE.UWidget) then
    Log.Error("UIUtils.SafeSetVisibility: widget is not a UWidget", widget)
    return
  end
  if widget.SetVisibility then
    widget:SetVisibility(SlateVisibility)
  elseif not ignoreError then
    Log.Error("UIUtils.SafeSetVisibility: widget does not have SetVisibility method")
  end
end

local RTCaptureUsed = {}

function UIUtils.AddImageRTInUse(rt, owner)
  if not owner then
    return
  end
  local rtHashCode = rt and UE4.UNRCStatics.GetObjectHashCode(rt) or 0
  if 0 ~= rtHashCode then
    local usedOwners = RTCaptureUsed[rtHashCode]
    if not usedOwners then
      usedOwners = _G.MakeWeakTable()
      RTCaptureUsed[rtHashCode] = usedOwners
    end
    usedOwners[owner] = true
  end
end

function UIUtils.RemoveImageRTNoUse(rt, owner)
  if not owner then
    return false
  end
  local hasOwner = false
  local rtHashCode = rt and UE4.UNRCStatics.GetObjectHashCode(rt) or 0
  if 0 ~= rtHashCode then
    local usedOwners = RTCaptureUsed[rtHashCode]
    if usedOwners then
      usedOwners[owner] = nil
      hasOwner = next(usedOwners)
      if not hasOwner then
        RTCaptureUsed[rtHashCode] = nil
      end
    end
  end
  return hasOwner
end

function UIUtils.ConvertTimeStringToSeconds(timeString)
  if not timeString or type(timeString) ~= "string" then
    return 0
  end
  local hours, minutes, seconds = string.match(timeString, "(%d+):(%d+):(%d+)")
  if hours and minutes and seconds then
    hours = tonumber(hours) or 0
    minutes = tonumber(minutes) or 0
    seconds = tonumber(seconds) or 0
    return hours * 3600 + minutes * 60 + seconds
  end
  local parts = {}
  for part in string.gmatch(timeString, "%d+") do
    table.insert(parts, tonumber(part))
  end
  if 3 == #parts then
    return parts[1] * 3600 + parts[2] * 60 + parts[3]
  elseif 2 == #parts then
    return parts[1] * 60 + parts[2]
  elseif 1 == #parts then
    return parts[1]
  end
  return 0
end

function UIUtils.ParseDateTimeString(dateTimeString)
  if not dateTimeString or type(dateTimeString) ~= "string" then
    return nil
  end
  local year, month, day, hour, min, sec = string.match(dateTimeString, "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
  if year and month and day and hour and min and sec then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = tonumber(sec)
    })
  end
  return nil
end

function UIUtils.FormatTimeString(seconds)
  if seconds <= 0 then
    return "00:00:00"
  end
  local h = math.floor(seconds / 3600)
  local m = math.floor(seconds % 3600 / 60)
  local s = math.floor(seconds % 60)
  return string.format("%02d:%02d:%02d", h, m, s)
end

function UIUtils.GetRemainingTime(targetTime, currentTime)
  local remaining = targetTime - currentTime
  return remaining > 0 and remaining or 0
end

local TimezoneOffset = -1

function UIUtils.GetTimezoneOffset()
  TimezoneOffset = _G.ZoneServer:GetServerTimeZoneOffset()
  return TimezoneOffset
end

function UIUtils.FormatTimeStringToDay(leftTime)
  if leftTime <= 0 then
    return "00:00:00"
  end
  local localSeconds = leftTime
  local day = math.floor(localSeconds / 86400)
  local h = math.floor(localSeconds % 86400 / 3600)
  local m = math.floor(localSeconds % 3600 / 60)
  local s = math.floor(localSeconds % 60)
  if day > 0 then
    return string.format(LuaText.random_shop_time_text_1, day, h)
  elseif h > 0 then
    return string.format(LuaText.random_shop_time_text_2, h, m)
  else
    return string.format(LuaText.random_shop_time_text_3, m, s)
  end
end

function UIUtils.GetTimeFromSeconds(seconds)
  if seconds <= 0 then
    return 0, 0, 0, 0
  end
  local localSeconds = seconds
  local day = math.floor(localSeconds / 86400)
  local h = math.floor(localSeconds % 86400 / 3600)
  local m = math.floor(localSeconds % 3600 / 60)
  local s = math.floor(localSeconds % 60)
  return day, h, m, s
end

function UIUtils.GetSectonsFromDayString(dayString)
  local day, h, m, s = string.match(dayString, "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)")
  if day and h and m and s then
    return tonumber(day) * 86400 + tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
  end
  return 0
end

function UIUtils.GetSecondsFromTimeString(timeStr)
  if not timeStr then
    return nil
  end
  if "24:00:00" == timeStr or "24:00" == timeStr then
    return 86400
  end
  local hours, minutes, seconds = string.match(timeStr, "(%d+):(%d+):(%d+)")
  if hours and minutes and seconds then
    local h = tonumber(hours)
    local m = tonumber(minutes)
    local s = tonumber(seconds)
    if h >= 24 then
      Log.Warning("[UIUtils.GetSecondsFromTimeString] Hours cannot exceed 24:", timeStr)
      return nil
    end
    return h * 3600 + m * 60 + s
  end
  local hours, minutes = string.match(timeStr, "(%d+):(%d+)")
  if hours and minutes then
    local h = tonumber(hours)
    local m = tonumber(minutes)
    if h >= 24 then
      Log.Warning("[UIUtils.GetSecondsFromTimeString] Hours cannot exceed 24:", timeStr)
      return nil
    end
    return h * 3600 + m * 60
  end
  local seconds = tonumber(timeStr)
  if seconds then
    return seconds
  end
  Log.Warning("[UIUtils.GetSecondsFromTimeString] Invalid time format:", timeStr)
  return nil
end

function UIUtils.GetItemInfoByItemData(itemData)
  local iconPath = ""
  local quality = 0
  if itemData.itemType == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(itemData.itemId)
    if vItemConf then
      iconPath = vItemConf.bigIcon or vItemConf.iconPath
      quality = vItemConf.item_quality or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.itemId)
    if bagItemConf then
      iconPath = bagItemConf.icon
      quality = bagItemConf.item_quality or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_PET then
    local petInfo = _G.DataConfigManager:GetPetConf(itemData.itemId)
    if petInfo then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
      if petBaseConf then
        local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
        iconPath = modelConf and modelConf.icon or ""
      end
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemData.itemId)
    if cardSkinConf then
      iconPath = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      quality = cardSkinConf.card_quality or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(itemData.itemId)
    if cardIconConf then
      iconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, cardIconConf.icon_resource_path, cardIconConf.icon_resource_path)
      quality = cardIconConf.card_quality or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local cardLabelConf = _G.DataConfigManager:GetCardLabelConf(itemData.itemId)
    if cardLabelConf then
      iconPath = cardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
      quality = cardLabelConf.card_quality or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(itemData.itemId)
    if fashionConf then
      iconPath = fashionConf.suits_icon
      quality = fashionConf.suit_grade or 0
    end
  elseif itemData.itemType == _G.Enum.GoodsType.GT_REWARD then
    local rewardConf = _G.DataConfigManager:GetRewardConf(itemData.itemId)
    if rewardConf and #rewardConf.RewardItem > 0 then
      local rewardItem = rewardConf.RewardItem[1]
      local tempItemData = {
        itemType = rewardItem.type,
        itemId = rewardItem.id,
        bShowTip = true,
        IsCanClick = true,
        bShowNum = true
      }
      return UIUtils.GetItemInfoByItemData(tempItemData)
    end
  else
    Log.Warning("UIUtils.GetItemInfo itemData goodsType is not supported", itemData.itemType)
  end
  return iconPath, quality
end

function UIUtils.GetGlassInfoId(glassInfo)
  if not glassInfo then
    return 0
  end
  local id = glassInfo.glass_type << 32 | glassInfo.glass_value
  return id
end

function UIUtils.GetGlassInfoFromId(glassId)
  if not glassId or 0 == glassId then
    return nil
  end
  local glass_value = glassId & 4294967295
  local glass_type = glassId >> 32
  local glassInfo = {glass_type = glass_type, glass_value = glass_value}
  return glassInfo
end

function UIUtils.SubUTF8String(str, maxChars)
  if not str then
    return ""
  end
  local chars = {}
  local count = 0
  for char in string.gmatch(str, "([%z\001-\127\239\191\189-\239\191\189][\239\191\189-\239\191\189]*)") do
    count = count + 1
    if maxChars >= count then
      table.insert(chars, char)
    else
      break
    end
  end
  return table.concat(chars)
end

function UIUtils.GetMedalLevelInfo(medalId, count)
  if not medalId then
    return nil
  end
  local medalConf = _G.DataConfigManager:GetMedalConf(medalId)
  if not medalConf then
    return nil
  end
  local levelData
  if count then
    for index = #medalConf.repeat_get_award, 1, -1 do
      if count >= medalConf.repeat_get_award[index].count then
        levelData = medalConf.repeat_get_award[index]
        break
      end
    end
  end
  if not levelData then
    levelData = {}
    levelData.icon2 = medalConf.icon
    levelData.fx_res_2 = medalConf.fx_res
    levelData.big_icon2 = medalConf.big_icon
    levelData.task_desc2 = medalConf.desc
    levelData.ui_param2 = medalConf.ui_param
  end
  return levelData
end

function UIUtils.GetIconAndQualityByItemIDAndItemType(ItemID, ItemType)
  local iconPath
  local quality = 0
  local name
  if ItemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bagitemconf = _G.DataConfigManager:GetBagItemConf(ItemID)
    if bagitemconf then
      iconPath = bagitemconf.big_icon
      quality = bagitemconf.item_quality
      name = bagitemconf.name
      if bagitemconf and bagitemconf.item_behavior and bagitemconf.item_behavior[1] and bagitemconf.is_auto_use then
        local itemBehavior = bagitemconf.item_behavior[1]
        if itemBehavior and itemBehavior.use_action and itemBehavior.use_action == Enum.ItemBehavior.IB_GET_AWARD and itemBehavior.ratio and itemBehavior.ratio[1] then
          local awardConf = _G.DataConfigManager:GetRewardConf(itemBehavior.ratio[1])
          if awardConf and awardConf.RewardItem and awardConf.RewardItem[1] then
            local awardItem = awardConf.RewardItem[1]
            if awardItem.Type == Enum.GoodsType.GT_CARD_SKIN then
              local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(awardItem.Id)
              quality = cardSkinConf.card_quality
            end
          end
        end
      end
    end
  elseif ItemType == _G.Enum.GoodsType.GT_VITEM then
    local Vitemconf = _G.DataConfigManager:GetVisualItemConf(ItemID)
    if Vitemconf then
      iconPath = Vitemconf.bigIcon
      quality = Vitemconf.item_quality
      name = Vitemconf.displayName
    end
  elseif ItemType == _G.Enum.GoodsType.GT_CARD_SKIN then
    local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(ItemID)
    if cardSkinConf then
      quality = cardSkinConf.card_quality
      iconPath = string.format(UEPath.CARD_SKIN_PATH, cardSkinConf.skin_resource_path, cardSkinConf.skin_resource_path)
      name = cardSkinConf.skin_resource_name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_CARD_ICON then
    local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(ItemID)
    if GetCardIconConf then
      quality = GetCardIconConf.card_quality
      iconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, GetCardIconConf.icon_resource_path, GetCardIconConf.icon_resource_path)
      name = GetCardIconConf.icon_resource_name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_CARD_LABEL then
    local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(ItemID)
    if CardLabelConf then
      quality = CardLabelConf.card_quality
      iconPath = CardLabelConf.label_icon or UEPath.CARD_LABEL_PATH
      name = CardLabelConf.label_name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(ItemID)
    if fashionConf then
      local grade = AppearanceUtils.GetSuitQuality(fashionConf.suit_grade)
      quality = grade
      iconPath = fashionConf.suits_icon
      name = fashionConf.name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_FASHION then
    local fashionConf = _G.DataConfigManager:GetFashionItemConf(ItemID)
    if fashionConf then
      quality = fashionConf.item_quality
      iconPath = fashionConf.icon
      name = fashionConf.name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_SALON then
    local salonConf = _G.DataConfigManager:GetSalonItemConf(ItemID)
    if salonConf then
      quality = salonConf.item_quality
      iconPath = salonConf.icon
      name = salonConf.name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_SHARE_FORM then
    local shareConf = _G.DataConfigManager:GetPetShareItemConf(ItemID)
    if shareConf then
      quality = shareConf.item_quality
      iconPath = shareConf.item_icon
      name = shareConf.item_name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_RP_BEHAVIOR then
    local itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(ItemID)
    if itemConf then
      quality = 5
      iconPath = itemConf.icon_path
      name = itemConf.name_text
    end
  elseif ItemType == _G.Enum.GoodsType.GT_EMOJI then
    local ChatEmojiConf = _G.DataConfigManager:GetChatEmojiConf(ItemID)
    if ChatEmojiConf then
      quality = ChatEmojiConf.card_quality
      iconPath = ChatEmojiConf.emoji_goods_icon
      name = ChatEmojiConf.emoji_resource_name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_FASHION_PACKAGE then
    local fashionPackageConf = _G.DataConfigManager:GetFashionPackageConf(ItemID)
    if fashionPackageConf then
      quality = 5
      iconPath = nil
      name = fashionPackageConf.name
    end
  elseif ItemType == _G.Enum.GoodsType.GT_FASHION_BOND then
    local FashionBondConf = _G.DataConfigManager:GetFashionBondConf(ItemID)
    if FashionBondConf then
      quality = 5
      iconPath = FashionBondConf.fashion_bond_icon
      name = FashionBondConf.name
    end
  end
  return iconPath, quality, name
end

function UIUtils.CheckIsHighValuePet(sceneNpc)
  local isHighValue = false
  local serverData = sceneNpc.serverData
  if sceneNpc.config then
    local bWildPet = sceneNpc.config.throwing_interact_type == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET
    if bWildPet and serverData and serverData.npc_base then
      local mutationType = serverData.npc_base.mutation_type
      isHighValue = UIUtils.DoCheckIsHighValuePet(mutationType)
      if false == isHighValue then
        isHighValue = UIUtils.CheckHasHighValuePetLogic(mutationType)
      end
    end
  end
  if false == isHighValue then
    isHighValue = UIUtils.CheckHasHighLogicStatus(serverData)
  end
  return isHighValue
end

function UIUtils.DoCheckIsHighValuePet(mutationType)
  if mutationType and (mutationType == Enum.MutationDiffType.MDT_SHINING or mutationType == Enum.MutationDiffType.MDT_GLASS) then
    return true
  end
  return false
end

function UIUtils.CheckHasHighValuePetLogic(mutationType)
  if mutationType and mutationType ~= Enum.MutationDiffType.MDT_NONE then
    return true
  end
  return false
end

function UIUtils.CheckHasHighLogicStatus(serverData)
  if not serverData then
    return false
  end
  if serverData.status_info and #serverData.status_info > 0 then
    for _, Status in ipairs(serverData.status_info) do
      if Status.status == Enum.SpaceActorLogicStatus.SALS_HIGH_VALUE_NPC then
        return true
      end
    end
  end
  if serverData.npc_base and serverData.npc_base.refresh_src == _G.ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.ContinousCatchBonus then
    return true
  end
  return false
end

function UIUtils.GetHighValuePetTipsAndOwnerName(serverData)
  local tipText = ""
  local tipName = ""
  if serverData and serverData.npc_base then
    local ownerName = serverData.npc_base.create_avatar_name
    if string.IsNilOrEmpty(ownerName) then
      if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
        local ownerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() or 0
        local visitorInfo = NRCModuleManager:DoCmd(FriendModuleCmd.GetOnlineVisitorByUin, ownerUin)
        if visitorInfo and visitorInfo.name then
          tipName = visitorInfo.name
        end
      else
        tipName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
      end
    else
      tipName = ownerName
    end
    local tip = DataConfigManager:GetLocalizationConf("Highvaluepet_Owner_Rule_Nonowner").msg
    tipText = string.format(tip, tipName)
  end
  return tipText, tipName
end

function UIUtils.OpenItemTipsByItemIDAndItemType(itemId, itemType, bagItemGid, bagItem, showDefaultIconWhenConfigError)
  if not itemId or not itemType then
    Log.Error("UIUtils.OpenItemTipsByItemIDAndItemType: itemId or itemType is nil")
    return
  end
  if itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
    _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.OpenAppearanceSuitDetailsPanel, itemId)
  elseif itemType == _G.Enum.GoodsType.GT_REWARD then
    ActivityUtils.ShowRewardPreview(itemId)
  elseif bagItemGid then
    local bagItemInfo = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, bagItemGid)
    bagItemInfo = bagItemInfo or bagItem
    if not bagItemInfo then
      Log.Error("UIUtils.OpenItemTipsByItemIDAndItemType: bagItemGid\229\175\185\229\186\148\231\154\132\231\137\169\229\147\129\228\184\141\229\173\152\229\156\168", bagItemGid)
      return
    end
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.OpenItemTipsBrief, itemId, itemType, {
      eggData = bagItemInfo.egg_data,
      quality = 5
    })
  else
    _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_OpenItemTips, itemId, itemType)
  end
end

function UIUtils:RefreshWaterMaskImmediate()
  if not UE.UObject.IsValid(self) then
    return
  end
  assert(self.MarkCanvas)
  assert(self.Mark)
  if not _G.GlobalConfig.bShowTopMark then
    self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  
  local function RefreshMaskItems()
    self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if self.DelayWaterMarkId then
      _G.DelayManager:CancelDelayById(self.DelayWaterMarkId)
      self.DelayWaterMarkId = nil
    end
    local uid = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.uin
    local ViewPortSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    local LineNum = math.ceil(ViewPortSize.Y / 1080)
    local ColNum = math.ceil(ViewPortSize.X / 2340) * 5
    self.MarkCanvas:ClearChildren()
    for i = 1, LineNum do
      for j = 1, ColNum do
        local pos = UE4.FVector2D(500 * (j - 1), 1080 * (i - 1))
        local size = UE4.FVector2D(500, 1080)
        local MarkItem = UE4.UWidgetBlueprintLibrary.Create(self, self.Mark)
        self.MarkCanvas:AddChildToCanvas(MarkItem)
        MarkItem:UpdateUid(uid)
        MarkItem.Slot:SetPosition(pos)
        MarkItem.Slot:SetSize(size)
      end
    end
  end
  
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel.playerInfo and _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info then
    if _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.close_watermark and _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.end_time then
      if _G.DataModelMgr.PlayerDataModel.playerInfo.client_water_mark_info.end_time > _G.ZoneServer:GetServerTime() / 1000 then
        self.MarkCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        RefreshMaskItems()
      end
    else
      RefreshMaskItems()
    end
  end
end

function UIUtils.ScreenPositionToViewport(screenPosition)
  local viewportPos = UE4.FVector2D()
  local world = _G.UE4Helper.GetCurrentWorld()
  if world then
    local geometry = UE4.UWidgetLayoutLibrary.GetViewportWidgetGeometry(world)
    if geometry then
      viewportPos = UE4.USlateBlueprintLibrary.AbsoluteToLocal(geometry, screenPosition)
    end
  end
  return viewportPos
end

return UIUtils
