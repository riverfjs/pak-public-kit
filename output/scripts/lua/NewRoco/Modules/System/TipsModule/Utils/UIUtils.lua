local UIUtils = {}
local AppearanceUtils = require("NewRoco.Modules.System.Appearance.AppearanceUtils")
UIUtils.QualityColors = {
  "#FFFFFF",
  "#b8eb58",
  "#8ed8fb",
  "#dfaBe8",
  "#EFA012",
  "#e29816",
  "#de9826"
}
UIUtils.QualityPressedColors = {
  "#292929FF",
  "#b8eb58",
  "#8ed8fb",
  "#dfaBe8",
  "#EFA012",
  "#e29816",
  "#de9826"
}
UIUtils.QualityTextColors = {
  "#565f70",
  "#6ec300",
  "#1e74c3",
  "#aa5dd2",
  "#e78101"
}
local DebugData = {
  "\233\148\153\229\149\166!!!",
  "\232\153\154\230\139\159\231\137\169\229\147\129ID:%d",
  "ID:%d"
}

function UIUtils.SetGroupVisiblity(group, visibleType)
  for _, widget in tpairs(group) do
    if widget then
      widget:SetVisibility(visibleType)
    end
  end
end

function UIUtils.GetCenterPos(widget)
  widget:ForceLayoutPrepass()
  local world = widget:GetWorld()
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(world)
  local viewportScale = UE4.UWidgetLayoutLibrary.GetViewportScale(world)
  local screenSize = viewportSize / viewportScale
  local desiredSize = widget:GetDesiredSize()
  local widgetSize = desiredSize / viewportScale
  local centerPos = UE4.FVector2D()
  centerPos.X = screenSize.X / 2 - widgetSize.X / 2
  centerPos.Y = screenSize.Y / 2 - widgetSize.Y / 2
  return centerPos
end

function UIUtils.GetAssetPath(path)
  return path
end

function UIUtils.GetClassPath(path)
  if path:StartsWith("WidgetBlueprint") then
    local index = string.find(path, "%.[^%.]*$")
    return path:sub(17, index - 1)
  end
  return path
end

function UIUtils.LoadWindowRes(path, syncLoad, finishCb)
end

function UIUtils.UnLoadWidgetScript(widget)
end

function UIUtils.GetSplit(Data, _delimiter)
  local delimiter = _delimiter
  local subValues = {}
  for subValue in string.gmatch(Data, "([^" .. delimiter .. "]+)") do
    table.insert(subValues, subValue)
  end
  return subValues
end

function UIUtils.SetTextWithQuality(widget, content, quality, pressed, size)
  if content then
    local output
    if pressed then
      if size then
        output = string.format("<span color=\"%s\" size=\"%d\">%s</>", UIUtils.QualityPressedColors[quality] or UIUtils.QualityPressedColors[1], size, content)
      else
        output = string.format("<span color=\"%s\">%s</>", UIUtils.QualityPressedColors[quality] or UIUtils.QualityPressedColors[1], content)
      end
    elseif size then
      output = string.format("<span color=\"%s\" size=\"%d\">%s</>", UIUtils.QualityColors[quality] or UIUtils.QualityColors[1], size, content)
    else
      output = string.format("<span color=\"%s\">%s</>", UIUtils.QualityColors[quality] or UIUtils.QualityColors[1], content)
    end
    widget:SetText(output)
  else
    widget:SetText("")
  end
end

function UIUtils.SetTextWithValidation(widget, content, validation, pressed)
  if content then
    local color = ""
    if pressed then
      if validation then
        color = "#272727"
      else
        color = "#af3d3e"
      end
    elseif validation then
      color = "#f4eee1"
    else
      color = "#af3d3e"
    end
    local output = string.format("<span color=\"%s\">%s</>", color, content)
    widget:SetText(output)
  else
    widget:SetText("")
  end
end

function UIUtils.GetTipsDetails(type, id)
  local itemConf, propName
  local propIconPath = ""
  local containerIcon
  local quality = 0
  local desc
  local Prompt = ""
  if type == Enum.GoodsType.GT_BAGITEM then
    itemConf = _G.DataConfigManager:GetBagItemConf(id)
    if itemConf then
      if itemConf.type == _G.Enum.BagItemType.BI_PET_EGG or itemConf.type == _G.Enum.BagItemType.BI_PET_FRUIT then
        local isHaveBook, itemName, itemDesc = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCheckItemInHandbook, id)
        if isHaveBook then
          propName = itemName
          desc = itemDesc
        else
          propName = itemConf.name
          desc = itemConf.description
        end
      else
        propName = itemConf.name
        desc = itemConf.description
      end
      propIconPath = itemConf.icon
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.item_quality
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_VITEM then
    itemConf = _G.DataConfigManager:GetVisualItemConf(id)
    if itemConf then
      propName = itemConf.displayName
      propIconPath = itemConf.bigIcon
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.item_quality
      desc = itemConf.discription
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_PET then
    itemConf = _G.DataConfigManager:GetPetbaseConf(id, true)
    if not itemConf then
      local PetConf = _G.DataConfigManager:GetPetConf(id, true)
      if not PetConf then
        Log.Error("PET_CONF\229\146\140PETBASE_CONF\228\184\173\233\131\189\230\137\190\228\184\141\229\136\176\232\191\153\228\184\170ID", id)
      end
      itemConf = _G.DataConfigManager:GetPetbaseConf(PetConf and PetConf.base_id or 0, true)
    end
    if itemConf then
      local model = _G.DataConfigManager:GetModelConf(itemConf.model_conf)
      propName = itemConf.name
      propIconPath = model.ui_icon
      containerIcon = UEPath.PROP_PET_BALL_ICON
      desc = itemConf.description
      if itemConf.quality == Enum.PetQuality.PQ_PURPLE then
        quality = 4
      elseif itemConf.quality == Enum.PetQuality.PQ_ORANGE then
        quality = 5
      else
        quality = 3
      end
    else
      propName = DebugData[1]
      desc = string.format(DebugData[3], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_FASHION then
    itemConf = _G.DataConfigManager:GetFashionItemConf(id)
    if itemConf then
      propName = itemConf.name
      propIconPath = itemConf.icon
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.item_quality
      if itemConf.description ~= nil then
        desc = itemConf.description
      end
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_FASHION_SUITS then
    itemConf = _G.DataConfigManager:GetFashionSuitsConf(id)
    if itemConf then
      propName = itemConf.name
      propIconPath = itemConf.suits_icon
      containerIcon = UEPath.PROP_BAG_ICON
      quality = AppearanceUtils.GetSuitQuality(itemConf.suit_grade)
      desc = itemConf.flavor_text
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 3
    end
  elseif type == Enum.GoodsType.GT_SALON then
    itemConf = _G.DataConfigManager:GetSalonItemConf(id)
    if itemConf then
      propName = itemConf.name
      propIconPath = itemConf.icon
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.item_quality
      desc = itemConf.discription
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_CARD_ICON then
    itemConf = _G.DataConfigManager:GetCardIconConf(id)
    if itemConf then
      propName = itemConf.icon_resource_name
      propIconPath = string.format("%s%s.%s'", UEPath.CARD_HEAD_PATH, itemConf.icon_resource_path, itemConf.icon_resource_path)
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.card_quality
      desc = itemConf.item_description
      Prompt = itemConf.bottom_description
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_CARD_SKIN then
    itemConf = _G.DataConfigManager:GetCardSkinConf(id)
    if itemConf then
      propName = itemConf.skin_resource_name
      local HeadlinePath = string.format(UEPath.CARD_SKIN_PATH, itemConf.skin_resource_path, itemConf.skin_resource_path)
      propIconPath = HeadlinePath
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.card_quality
      desc = itemConf.item_description
      Prompt = itemConf.bottom_description
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_CARD_LABEL then
    itemConf = _G.DataConfigManager:GetCardLabelConf(id)
    if itemConf then
      propName = itemConf.label_name
      propIconPath = UEPath.CARD_LABEL_PATH
      containerIcon = UEPath.PROP_BAG_ICON
      quality = itemConf.card_quality
      desc = itemConf.item_description
      Prompt = itemConf.bottom_description
    else
      propName = DebugData[1]
      desc = string.format(DebugData[2], id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_RP_BEHAVIOR then
    itemConf = _G.DataConfigManager:GetRoleplayBehaviorConf(id)
    if itemConf then
      propName = itemConf.name_text
      propIconPath = itemConf.icon_path
      desc = itemConf.toast_text
      quality = 5
    else
      propName = ""
      desc = string.format("RolePlay:%d", id)
      containerIcon = UEPath.PROP_PET_BALL_ICON
      quality = 5
    end
  elseif type == Enum.GoodsType.GT_SHARE_FORM then
    itemConf = _G.DataConfigManager:GetPetShareItemConf(id)
    Prompt = itemConf.extra_description
    propName = itemConf.item_name
    desc = itemConf.item_description
    quality = itemConf.item_quality
    propIconPath = itemConf.item_icon
  elseif type == Enum.GoodsType.GT_FASHION_BOND then
    itemConf = _G.DataConfigManager:GetFashionBondConf(id)
    propName = itemConf.name
    propIconPath = itemConf.fashion_bond_icon
    quality = itemConf.fashion_bond_quality
    desc = itemConf.popup_text
  elseif type == Enum.GoodsType.GT_EMOJI then
    itemConf = _G.DataConfigManager:GetChatEmojiConf(id)
    if itemConf then
      propName = itemConf.emoji_resource_name
      propIconPath = itemConf.emoji_goods_icon
      quality = itemConf.card_quality
    end
  end
  if not propIconPath or not containerIcon then
    Log.Warning("IconPath is nil", type, id, propName, propIconPath, containerIcon, quality, desc, Prompt)
  end
  propName = UIUtils.TruncateUTF8(propName, 16, 4)
  return itemConf, propName, propIconPath, containerIcon, quality, desc, Prompt
end

function UIUtils.TruncateUTF8(text, maxWidth, blackNum)
  if not text or 0 == #text or nil == maxWidth then
    return ""
  end
  blackNum = blackNum or 0
  local totalWidth = 0
  local bytePos = 1
  local n = #text
  while bytePos <= n do
    local firstByte = text:byte(bytePos)
    local charWidth, charBytes = 0, 0
    if firstByte < 128 then
      charWidth = 1
      charBytes = 1
    elseif firstByte >= 240 then
      charWidth = 2
      charBytes = 4
    elseif firstByte >= 224 then
      charWidth = 2
      charBytes = 3
    elseif firstByte >= 192 then
      charWidth = 1
      charBytes = 2
    else
      charWidth = 0
      charBytes = 1
    end
    if n < bytePos + charBytes - 1 then
      break
    end
    totalWidth = totalWidth + charWidth
    bytePos = bytePos + charBytes
  end
  if maxWidth >= totalWidth then
    return text
  end
  local displayWidth = maxWidth - blackNum
  local currentWidth = 0
  bytePos = 1
  local lastValidPos = 0
  while n >= bytePos do
    local firstByte = text:byte(bytePos)
    local charWidth, charBytes = 0, 0
    if firstByte < 128 then
      charWidth = 1
      charBytes = 1
    elseif firstByte >= 240 then
      charWidth = 2
      charBytes = 4
    elseif firstByte >= 224 then
      charWidth = 2
      charBytes = 3
    elseif firstByte >= 192 then
      charWidth = 1
      charBytes = 2
    else
      charWidth = 0
      charBytes = 1
    end
    if n < bytePos + charBytes - 1 or displayWidth < currentWidth + charWidth then
      break
    end
    currentWidth = currentWidth + charWidth
    lastValidPos = bytePos + charBytes - 1
    bytePos = bytePos + charBytes
  end
  if lastValidPos <= 0 then
    return ""
  end
  return text:sub(1, lastValidPos) .. "..."
end

function UIUtils.GetItemQuality(widget, quality)
  widget:SetVisibility(UE4.ESlateVisibility.Visible)
  if 0 == quality then
    widget:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    widget:SetPath(UEPath.PROP_QUALITY_1)
  elseif 2 == quality then
    widget:SetPath(UEPath.PROP_QUALITY_2)
  elseif 3 == quality then
    widget:SetPath(UEPath.PROP_QUALITY_3)
  elseif 4 == quality then
    widget:SetPath(UEPath.PROP_QUALITY_4)
  elseif 5 == quality then
    widget:SetPath(UEPath.PROP_QUALITY_5)
  end
end

function UIUtils.GetPetQuality(widget, quality)
  widget:SetVisibility(UE4.ESlateVisibility.Visible)
  if quality == _G.Enum.PetQuality.PQ_BLUE then
    widget:SetPath(UEPath.PROP_QUALITY_3)
  elseif quality == _G.Enum.PetQuality.PQ_PURPLE then
    widget:SetPath(UEPath.PROP_QUALITY_4)
  elseif quality == _G.Enum.PetQuality.PQ_ORANGE then
    widget:SetPath(UEPath.PROP_QUALITY_5)
  else
    widget:SetPath(UEPath.PROP_QUALITY_NONE)
  end
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

return UIUtils
