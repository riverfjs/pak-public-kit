local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_PetCardShare_C = _G.NRCPanelBase:Extend("UMG_PetCardShare_C")

function UMG_PetCardShare_C:OnConstruct()
  self.index = -1
  self.cardIndex = 1
  self.canChange = true
  self.MatchIndex = nil
  self.iconPath = nil
  self.petData = nil
  self.maskVisibility = nil
  self:OnAddEventListener()
end

function UMG_PetCardShare_C:SetMaskVisibility(visibility)
  self.maskVisibility = visibility
end

function UMG_PetCardShare_C:GetCanChange()
  return self.canChange
end

function UMG_PetCardShare_C:Init(petData, card_ids, unlockData)
  self.petData = petData
  self.card_ids = card_ids
  self.unlockData = unlockData
  local mutation_type = petData.mutation_type
  local glass_info = petData.glass_info
  self.glass_info = glass_info
  if mutation_type and PetUtils.CheckIsShiningChaos(mutation_type) then
    self.ColourIcon_1:SetActiveWidgetIndex(6)
    self.ColourIcon:SetActiveWidgetIndex(6)
  elseif mutation_type and PetUtils.CheckIsCHAOS(mutation_type) then
    self.ColourIcon_1:SetActiveWidgetIndex(5)
    self.ColourIcon:SetActiveWidgetIndex(5)
  elseif mutation_type and glass_info and PetUtils.CheckIsHiddenShiningGlass(mutation_type, glass_info) then
    self.ColourIcon_1:SetActiveWidgetIndex(3)
    self.ColourIcon:SetActiveWidgetIndex(3)
    local path = self:GetHiddenGlassIcon(true)
    if "" ~= path then
      self.ColourIcon_04:SetPath(path)
      self.ColourIcon_5:SetPath(path)
    end
  elseif mutation_type and PetUtils.CheckIsShiningGlass(mutation_type) then
    self.ColourIcon_1:SetActiveWidgetIndex(1)
    self.ColourIcon:SetActiveWidgetIndex(1)
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.ColourIcon_1:SetActiveWidgetIndex(0)
    self.ColourIcon:SetActiveWidgetIndex(0)
  elseif mutation_type and glass_info and PetUtils.CheckIsHiddenGlass(mutation_type, glass_info) then
    self.ColourIcon_1:SetActiveWidgetIndex(4)
    self.ColourIcon:SetActiveWidgetIndex(4)
    local path = self:GetHiddenGlassIcon(false)
    if "" ~= path then
      self.ColourIcon_05:SetPath(path)
      self.ColourIcon_6:SetPath(path)
    end
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.ColourIcon_1:SetActiveWidgetIndex(2)
    self.ColourIcon:SetActiveWidgetIndex(2)
  else
    self.ColourIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ColourIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local dateText = _G.DataConfigManager:GetLocalizationConf("medal_text_5").msg
  local Text, AddTime, Count
  local add_time = petData.activity_partner_pet_data and petData.activity_partner_pet_data.add_time or petData.add_time
  if add_time then
    AddTime = os.date(dateText, add_time)
    Text = string.format(_G.DataConfigManager:GetLocalizationConf("pet_experience_text_9").msg, AddTime)
  end
  local catchData = petData.activity_partner_pet_data or petData
  local PetCatchWay = self:GetPetCatchWay(catchData)
  Text = string.format("%s%s", Text, PetCatchWay)
  if catchData.catch_lv then
    Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_8_card").msg
    Count = string.format(Count, catchData.catch_lv)
    Text = string.format("%s%s", Text, Count)
  end
  self.Card2Text_1:SetText(Text)
  self.Card2Text_11:SetText(Text)
  local natureDesc = petData.activity_partner_pet_data and petData.activity_partner_pet_data.nature_desc or PetUtils.GetNatureDes(petData)
  if natureDesc then
    Text = natureDesc
    self.Card2Text_3:SetText(Text)
    self.Card2Text_13:SetText(Text)
  end
  local partnerDataEvoluteInfo = petData.activity_partner_pet_data and petData.activity_partner_pet_data.key_experience and petData.activity_partner_pet_data.key_experience.evolute_info
  local petDataEvoluteInfo = petData.key_experience and petData.key_experience.evolute_info
  local evoluteInfo = partnerDataEvoluteInfo or petDataEvoluteInfo
  if evoluteInfo then
    Text = ""
    for i, Evolute in ipairs(evoluteInfo) do
      AddTime = os.date(dateText, Evolute.evolute_time)
      local BeforePetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.before_base_conf_id)
      local AfterPetBaseConf = _G.DataConfigManager:GetPetbaseConf(Evolute.after_base_conf_id)
      local msg = _G.DataConfigManager:GetLocalizationConf("pet_experience_form_1_card").msg
      local Text_Info = string.format(msg, AddTime, BeforePetBaseConf.name, AfterPetBaseConf.name)
      Text = string.format("%s%s", Text, Text_Info)
      if i ~= #evoluteInfo then
        Text = string.format("%s%s", Text, "\n")
      end
    end
    if "" ~= Text then
      self.Card2Text_5:SetText(Text)
      self.Card2Text_15:SetText(Text)
      self.Evolution_1:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      self.Evolution:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      self.Spacer1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Spacer1_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local bExp = false
  local card2Text_array = {
    self.Card2Text_6,
    self.Card2Text_7,
    self.Card2Text_8
  }
  local card2Text_array2 = {
    self.Card2Text_16,
    self.Card2Text_17,
    self.Card2Text_18
  }
  local card2Text_index = 1
  local partnerBlessingInfo = petData.activity_partner_pet_data and petData.activity_partner_pet_data.key_experience and petData.activity_partner_pet_data.key_experience.blessing_info
  if partnerBlessingInfo and card2Text_index <= 3 and partnerBlessingInfo.from_player_name and partnerBlessingInfo.from_pet_name then
    Text = string.format(LuaText.interactiontree_cifu_text_1, partnerBlessingInfo.from_player_name, partnerBlessingInfo.from_pet_name)
    card2Text_array2[card2Text_index]:SetText(Text)
    card2Text_array[card2Text_index]:SetText(Text)
    card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
    card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
    card2Text_index = card2Text_index + 1
    bExp = true
  end
  local partnerClosenessInfo = petData.activity_partner_pet_data and petData.activity_partner_pet_data.closeness_info
  if partnerClosenessInfo and partnerClosenessInfo.closeness_lv and 0 ~= partnerClosenessInfo.closeness_lv and card2Text_index <= 3 then
    Text = ""
    local PetCloseLevelEffectConf = _G.DataConfigManager:GetPetCloseLevelEffectConf(partnerClosenessInfo.closeness_lv + 1)
    if PetCloseLevelEffectConf.localization_id and "" ~= PetCloseLevelEffectConf.localization_id then
      local LocalizationConf = _G.DataConfigManager:GetLocalizationConf(PetCloseLevelEffectConf.localization_id)
      Text = string.format(LocalizationConf.msg, petData.activity_partner_pet_data.name)
      card2Text_array2[card2Text_index]:SetText(Text)
      card2Text_array[card2Text_index]:SetText(Text)
      card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_index = card2Text_index + 1
      bExp = true
    end
  end
  local partnerTextDesc = petData.activity_partner_pet_data and petData.activity_partner_pet_data.key_experience and petData.activity_partner_pet_data.key_experience.text_desc
  if partnerTextDesc and card2Text_index <= 3 then
    for _, ExperienceID in pairs(partnerTextDesc or {}) do
      if ExperienceID then
        local ExperienceConf = _G.DataConfigManager:GetTextExpConf(ExperienceID)
        if ExperienceConf then
          local ExperienceText = ""
          if 1 == ExperienceID then
            ExperienceText = string.format(LuaText[ExperienceConf.exp_localization_id], petData.name)
          end
          if "" ~= ExperienceText and nil ~= card2Text_array2[card2Text_index] and nil ~= card2Text_array[card2Text_index] then
            card2Text_array2[card2Text_index]:SetText(ExperienceText)
            card2Text_array[card2Text_index]:SetText(ExperienceText)
            card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
            card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
            card2Text_index = card2Text_index + 1
            bExp = true
          end
        end
      end
    end
    bExp = true
  end
  if petData.key_experience and petData.key_experience.blessing_info and card2Text_index <= 3 then
    local blessing_info = petData.key_experience.blessing_info
    if blessing_info.from_player_name and blessing_info.from_pet_name then
      Text = string.format(LuaText.interactiontree_cifu_text_1, blessing_info.from_player_name, blessing_info.from_pet_name)
      card2Text_array2[card2Text_index]:SetText(Text)
      card2Text_array[card2Text_index]:SetText(Text)
      card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_index = card2Text_index + 1
      bExp = true
    end
  end
  if petData.closeness_info and petData.closeness_info.closeness_lv and 0 ~= petData.closeness_info.closeness_lv and card2Text_index <= 3 then
    Text = ""
    local PetCloseLevelEffectConf = _G.DataConfigManager:GetPetCloseLevelEffectConf(petData.closeness_info.closeness_lv + 1)
    if PetCloseLevelEffectConf.localization_id and "" ~= PetCloseLevelEffectConf.localization_id then
      local LocalizationConf = _G.DataConfigManager:GetLocalizationConf(PetCloseLevelEffectConf.localization_id)
      Text = string.format(LocalizationConf.msg, petData.name)
      card2Text_array2[card2Text_index]:SetText(Text)
      card2Text_array[card2Text_index]:SetText(Text)
      card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
      card2Text_index = card2Text_index + 1
      bExp = true
    end
  end
  if petData.key_experience and petData.key_experience.text_desc then
    for _, ExperienceID in pairs(petData.key_experience.text_desc or {}) do
      if ExperienceID then
        local ExperienceConf = _G.DataConfigManager:GetTextExpConf(ExperienceID)
        if ExperienceConf then
          local ExperienceText = ""
          if 1 == ExperienceID then
            ExperienceText = string.format(LuaText[ExperienceConf.exp_localization_id], petData.name)
          end
          if "" ~= ExperienceText and nil ~= card2Text_array2[card2Text_index] and nil ~= card2Text_array[card2Text_index] then
            card2Text_array2[card2Text_index]:SetText(ExperienceText)
            card2Text_array[card2Text_index]:SetText(ExperienceText)
            card2Text_array2[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
            card2Text_array[card2Text_index]:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
            card2Text_index = card2Text_index + 1
            bExp = true
          end
        end
      end
    end
  end
  if not bExp then
    self.Spacer2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Spacer2_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Recording:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Recording_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local _, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(petData.gid)
  if WearMedal then
    local medalConf = _G.DataConfigManager:GetMedalConf(WearMedal.conf_id)
    self.Icon2_1:SetPath(medalConf.big_icon)
    self.Icon2:SetPath(medalConf.big_icon)
  else
    self.Medal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Medal_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  Text = string.format(_G.DataConfigManager:GetLocalizationConf("card_PetShare_desc_uid").msg, uin)
  self.Card2Text_9:SetText(Text)
  self.Card2Text_19:SetText(Text)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local percentage = petBaseConf.card_res_ui_percentage
  local offset = petBaseConf.card_res_offset
  if 1 == petBaseConf.card_res_horizontal_flip_data then
    self:SetIconScaleAndPosition(UE4.FVector2D(-percentage, percentage), UE4.FVector2D(offset[1], offset[2]))
  else
    self:SetIconScaleAndPosition(UE4.FVector2D(percentage, percentage), UE4.FVector2D(offset[1], offset[2]))
  end
  local unit_type = petBaseConf.unit_type
  local typeList = {}
  for _, Type in ipairs(unit_type) do
    table.insert(typeList, Type)
  end
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petData.blood_id)
  table.insert(typeList, PetBloodConf.icon)
  self.Attr:InitGridView(typeList)
  self.Attr_1:InitGridView(typeList)
  self.Card1Text_1:SetText(petData.name)
  self.Card1Text_7:SetText(petData.name)
  Text = petBaseConf.description
  Text = string.gsub(Text, "\n", "")
  self.Card1Text_3:SetText(Text)
  self.Card1Text_9:SetText(Text)
  local weight = string.format("%.2f", petData.weight * 0.001)
  local height = string.format("%.2f", petData.height)
  Text = string.format(_G.DataConfigManager:GetLocalizationConf("card_PetShare_desc_height_weight").msg, height, weight)
  self.Card1Text_4:SetText(Text)
  self.Card1Text_10:SetText(Text)
  local gidStr = tostring(petData.gid)
  local gidLen = #gidStr
  for _ = 1, 8 - gidLen do
    gidStr = "0" .. gidStr
  end
  self.Card1Text_5:SetText(gidStr)
  self.Card1Text_11:SetText(gidStr)
  local handBookId = petBaseConf.pictorial_book_id
  if handBookId > 0 then
    Text = _G.DataConfigManager:GetPetHandbook(handBookId).type_desc
    self.Card1Text_2:SetText(Text)
    self.Card1Text_8:SetText(Text)
    local nums = {
      {
        self.XuHao3,
        self.XuHao3_1
      },
      {
        self.XuHao2,
        self.XuHao2_1
      },
      {
        self.XuHao1,
        self.XuHao1_1
      }
    }
    for i = 1, 3 do
      local num = handBookId % 10
      local path = string.format("PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_xuhao%d_png.img_xuhao%d_png'", num, num)
      local path2 = string.format("PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_shuzi%d_png.img_shuzi%d_png'", num, num)
      nums[i][1]:SetPath(path)
      nums[i][2]:SetPath(path2)
      handBookId = handBookId // 10
    end
  end
end

function UMG_PetCardShare_C:GetHiddenGlassIcon(bShiningGlass)
  local petData = self.petData
  if petData and petData.glass_info then
    local HiddenGlassID = petData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if bShiningGlass and HiddenGlassConf.yise_icon then
          return HiddenGlassConf.yise_icon
        elseif HiddenGlassConf.icon then
          return HiddenGlassConf.icon
        end
      end
    end
  end
  return ""
end

function UMG_PetCardShare_C:ChangeCard(cardIndex)
  self.canChange = false
  self.cardIndex = cardIndex
  if -1 == self.index then
    self:InitCard(cardIndex)
  elseif 0 == self.index then
    self:PlayAnimation(self.Out)
  elseif 1 == self.index then
    self:PlayAnimation(self.Out_0)
  end
end

function UMG_PetCardShare_C:InitCard(cardIndex)
  if not cardIndex or not self.card_ids[cardIndex] then
    return
  end
  local cardConf = _G.DataConfigManager:GetPetShareItemConf(self.card_ids[cardIndex])
  local cardType = cardConf.share_pattern
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  if cardType == Enum.SharePattern.ASP_CARD_COMMON then
    self:SetPetIcon(self.petData)
    local unit_type = petbaseConf.unit_type[1]
    local globalConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.GLOBAL_CONFIG):GetAllDatas()
    local bgPath
    for _, v in pairs(globalConf) do
      if v.id >= 646 and v.id <= 663 and v.num == unit_type then
        bgPath = v.str
        break
      end
    end
    self.Bg1:SetPath(bgPath)
    self.Atmosphere1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Level:SetActiveWidgetIndex(0)
    self.Border1:SetActiveWidgetIndex(0)
    self.Border1_1:SetActiveWidgetIndex(0)
    self.Loop1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.In1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.index = 0
    self.CardSwitcher_0:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.In)
  elseif cardType == Enum.SharePattern.ASP_CARD_UNCOMMON then
    self:SetPetIcon(self.petData)
    self.Bg1:SetPath(petbaseConf.share_uncommon_card_bg)
    self.Atmosphere1:SetPath(petbaseConf.share_uncommon_card_fg)
    self.Atmosphere1:SetVisibility(UE4.ESlateVisibility.selfHitTestInvisible)
    self.Level:SetActiveWidgetIndex(1)
    self.Border1:SetActiveWidgetIndex(1)
    self.Border1_1:SetActiveWidgetIndex(1)
    if self.unlockData[cardIndex] then
      self.Loop1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.In1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Loop1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.In1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.index = 0
    self.CardSwitcher_0:SetActiveWidgetIndex(0)
    self:PlayAnimation(self.In)
  elseif cardType == Enum.SharePattern.ASP_CARD_RARE then
    if self.petData.mutation_type == Enum.MutationDiffType.MDT_SHINING or self.petData.mutation_type == Enum.MutationDiffType.MDT_SHINING_GLASS then
      self.Bg1_1:SetPath(cardConf.card_shiny_pet_img)
    else
      self.Bg1_1:SetPath(cardConf.card_pet_img)
    end
    self.Level_1:SetActiveWidgetIndex(3)
    self.index = 1
    self.CardSwitcher_0:SetActiveWidgetIndex(1)
    if self.unlockData[cardIndex] then
      self.Loop2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.In1_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Loop2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.In1_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:PlayAnimation(self.In_0)
  end
  self:SetMask(self.maskVisibility)
end

function UMG_PetCardShare_C:SetPetIcon(petData)
  local mutation_type
  if petData.mutation_type and self.unlockData[self.cardIndex] then
    mutation_type = petData.mutation_type
  elseif petData.mutation_type and (0 ~= petData.mutation_type & _G.Enum.MutationDiffType.MDT_SHINING or PetUtils.CheckIsShiningGlass(petData.mutation_type)) then
    mutation_type = _G.Enum.MutationDiffType.MDT_SHINING
  else
    mutation_type = _G.Enum.MutationDiffType.MDT_NONE
  end
  local glass_info = petData.glass_info
  self.glass_info = glass_info
  local materialPath
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local petPicture = {
    petbaseConf.JL_res,
    petbaseConf.JL_shiny_res
  }
  if mutation_type and PetUtils.CheckIsShiningChaos(mutation_type) then
    self.iconPath = petPicture[2]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_InnerLineCloseUp.MI_UI_InnerLineCloseUp'"
  elseif mutation_type and PetUtils.CheckIsCHAOS(mutation_type) then
    self.iconPath = petPicture[1]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_InnerLineCloseUp.MI_UI_InnerLineCloseUp'"
  elseif mutation_type and glass_info and PetUtils.CheckIsHiddenShiningGlass(mutation_type, glass_info) then
    self.iconPath = petPicture[2]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = self:GetHiddenGlassMaterialPath(glass_info)
  elseif mutation_type and PetUtils.CheckIsShiningGlass(mutation_type) then
    self.iconPath = petPicture[2]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_PetDazzleCloseUp.MI_UI_PetDazzleCloseUp'"
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(false)
    self.Icon1:SetPath(petPicture[2])
  elseif mutation_type and glass_info and PetUtils.CheckIsHiddenGlass(mutation_type, glass_info) then
    self.iconPath = petPicture[1]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = self:GetHiddenGlassMaterialPath(glass_info)
  elseif mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.iconPath = petPicture[1]
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(true)
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_PetDazzleCloseUp.MI_UI_PetDazzleCloseUp'"
  else
    self.Icon1:SwitchToSetBrushFromMaterialInstanceMode(false)
    self.Icon1:SetPath(petPicture[1])
  end
  if materialPath then
    self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed)
  end
end

function UMG_PetCardShare_C:SetIconScaleAndPosition(scale, position)
  if scale then
    self.Icon1:SetRenderScale(scale)
  end
  if position then
    self.Icon1.Slot:SetPosition(position)
  end
end

function UMG_PetCardShare_C:OnLoadIconMaterialSucceed(_, asset)
  if self.iconPath and asset then
    self.Icon1.MaterialInstance = asset
    self.Icon1:SetPath(self.iconPath)
    if self.glass_info and self.glass_info.glass_type == ProtoEnum.GlassType.GT_COMMON then
      self:SetCommonGlass()
    end
  end
end

function UMG_PetCardShare_C:SetCommonGlass()
  if self.glass_info and self.glass_info.glass_value then
    local shineId = self.glass_info.glass_value
    local ParticleIndex
    if shineId then
      ParticleIndex, shineId = PetUtils.GetShineDataValue(shineId, 20)
      self.MatchIndex, shineId = PetUtils.GetShineDataValue(shineId, 0)
      local particleConf = _G.DataConfigManager:GetParticleRandomConf(ParticleIndex)
      if particleConf and particleConf.headicon_particle_res then
        local res = particleConf.headicon_particle_res
        self:LoadPanelRes(res, 255, self.LoadGlassResSuccess)
      end
    end
  end
end

function UMG_PetCardShare_C:LoadGlassResSuccess(_, asset)
  local function cb()
    if not self or not UE4.UObject.IsValid(self) then
      return
    end
    self:SetShinyType(asset, self.Icon1)
  end
  
  self:CancelAllDelay()
  self.Handler = _G.DelayManager:DelaySeconds(0.5, cb, self)
end

function UMG_PetCardShare_C:SetShinyType(asset, image)
  local material = image:GetDynamicMaterial()
  if material then
    material:SetTextureParameterValue("StarTex", asset)
  end
  local matchConf = _G.DataConfigManager:GetColorRandomConf(self.MatchIndex)
  if matchConf and matchConf.mat_color_1 then
    local color1 = matchConf.mat_color_1
    if material then
      material:SetVectorParameterValue("Color01", UE4.FLinearColor(color1[1], color1[2], color1[3], color1[4]))
    end
  end
  if matchConf and matchConf.mat_color_2 then
    local color2 = matchConf.mat_color_2
    if material then
      material:SetVectorParameterValue("Color02", UE4.FLinearColor(color2[1], color2[2], color2[3], color2[4]))
    end
  end
end

function UMG_PetCardShare_C:GetHiddenGlassMaterialPath(glass_info)
  if glass_info and glass_info.glass_value then
    local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(glass_info.glass_value)
    if HiddenGlassConf and HiddenGlassConf.pet_art_mat_path then
      return HiddenGlassConf.pet_art_mat_path
    end
  end
  return ""
end

function UMG_PetCardShare_C:SetMask(visible)
  if 0 == self.index then
    self.Mask1:SetVisibility(visible)
    self.Mask2:SetVisibility(visible)
    self.TipsBtn:SetVisibility(visible)
  elseif 1 == self.index then
    self.TipsBtn_1:SetVisibility(visible)
    self.Mask1_1:SetVisibility(visible)
    self.Mask2_1:SetVisibility(visible)
  end
end

function UMG_PetCardShare_C:ShowTips()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.DataConfigManager:GetPetShareItemConf(self.card_ids[self.cardIndex]).ban_tips)
end

function UMG_PetCardShare_C:SetExp(bExp)
  self.canChange = false
  if bExp then
    if 0 == self.index then
      self:PlayAnimation(self.Flip2_1, self.Flip2_1:GetEndTime() - 0.01)
      self:PlayAnimation(self.Flip_1)
    elseif 1 == self.index then
      self:PlayAnimation(self.Flip_1, self.Flip_1:GetEndTime() - 0.01)
      self:PlayAnimation(self.Flip2_1)
    end
  elseif 0 == self.index then
    self:PlayAnimation(self.Flip2, self.Flip2:GetEndTime() - 0.01)
    self:PlayAnimation(self.Flip)
  elseif 1 == self.index then
    self:PlayAnimation(self.Flip, self.Flip:GetEndTime() - 0.01)
    self:PlayAnimation(self.Flip2)
  end
end

function UMG_PetCardShare_C:GetPetCatchWay(petData)
  if petData then
    if petData.catch_way == Enum.PetCatchWay.PCW_WILD then
      local Count
      if petData.caught_camp then
        local CampConf = _G.DataConfigManager:GetCampConf(petData.caught_camp)
        if CampConf then
          Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_7_card").msg
          return string.format(Count, CampConf.camp_name)
        end
      end
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_VISIT then
      local Count = _G.DataConfigManager:GetLocalizationConf("pet_experience_text_2_card").msg
      return string.format(Count, petData.catch_visit_owner_name)
    elseif petData.catch_way == Enum.PetCatchWay.PCW_EGGHATCH then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_3").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_DUNGEON then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_6_card").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_TEAMBATTLE then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_4_card").msg
    elseif petData.catch_way == Enum.PetCatchWay.PCW_LEGEND then
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_5_card").msg
    else
      return _G.DataConfigManager:GetLocalizationConf("pet_experience_text_1").msg
    end
  end
end

function UMG_PetCardShare_C:OnAnimationFinished(Anim)
  if Anim == self.Out or Anim == self.Out_0 then
    self:InitCard(self.cardIndex)
    if 0 == self.index then
      self:PlayAnimation(self.In)
    elseif 1 == self.index then
      self:PlayAnimation(self.In_0)
    end
  elseif Anim == self.In or Anim == self.In_0 then
    self.canChange = true
  elseif Anim == self.Flip_1 or Anim == self.Flip then
    if 0 == self.index then
      self.canChange = true
    end
  elseif (Anim == self.Flip2 or Anim == self.Flip2_1) and 1 == self.index then
    self.canChange = true
  end
end

function UMG_PetCardShare_C:OnDestruct()
  self:OnRemoveEventListener()
  self:CancelAllDelay()
end

function UMG_PetCardShare_C:OnAddEventListener()
  self:AddButtonListener(self.TipsBtn, self.ShowTips)
  self:AddButtonListener(self.TipsBtn_1, self.ShowTips)
end

function UMG_PetCardShare_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.TipsBtn)
  self:RemoveButtonListener(self.TipsBtn_1)
end

function UMG_PetCardShare_C:CancelAllDelay()
  if self.Handler then
    _G.DelayManager:CancelDelayById(self.Handler)
    self.Handler = nil
  end
end

return UMG_PetCardShare_C
