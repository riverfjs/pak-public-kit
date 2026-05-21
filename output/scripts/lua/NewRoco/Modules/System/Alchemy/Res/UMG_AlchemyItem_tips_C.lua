local UMG_AlchemyItem_tips_C = _G.NRCPanelBase:Extend("UMG_AlchemyItem_tips_C")

function UMG_AlchemyItem_tips_C:OnActive(data)
  self:OnAddEventListener()
  local title = _G.DataConfigManager:GetLocalizationConf("alchemy_make_result_title")
  self.Title:SetText(title and title.msg or "\232\175\183\233\133\141\231\189\174alchemy_make_result_title")
  self.exchangeId = data.exchange_id
  self.exchangeNum = data.exchange_num
  local exchangeConf = _G.DataConfigManager:GetExchangeConf(self.exchangeId)
  if #exchangeConf.get_item > 1 then
    Log.Error("\230\137\147\233\128\160\229\135\186\228\186\134\229\164\154\228\184\170\239\188\140\232\191\153\228\184\170UI\231\187\147\230\158\132\228\184\141\230\148\175\230\140\129\239\188\140\232\175\183\230\143\144\228\191\174\230\148\185\233\156\128\230\177\130")
  end
  local get_goods_id = exchangeConf.get_item[1].get_goods_id
  local get_goods_num = exchangeConf.get_item[1].get_goods_num
  local get_goods_type = exchangeConf.get_item[1].get_goods_type
  if get_goods_type == _G.Enum.GoodsType.GT_BAGITEM then
    local BagItem = _G.DataConfigManager:GetBagItemConf(get_goods_id)
    if BagItem then
      self.Icon:SetPath(BagItem.big_icon)
      self.Icon_1:SetPath(BagItem.big_icon)
      local asset = self.module:GetRes(BagItem.big_icon, "AlchemyItem_tips")
      if asset then
        self:SetTextureToGrey(asset)
      end
      self:SetQuality(BagItem.item_quality, BagItem.name, get_goods_num * self.exchangeNum, BagItem.description)
    end
  elseif get_goods_type == _G.Enum.GoodsType.GT_VITEM then
    local vItemConf = _G.DataConfigManager:GetVisualItemConf(get_goods_id)
    if vItemConf then
      self.Icon:SetPath(vItemConf.bigIcon)
      self.Icon_1:SetPath(vItemConf.bigIcon)
      local asset = self.module:GetRes(vItemConf.bigIcon, "AlchemyItem_tips")
      if asset then
        self:SetTextureToGrey(asset)
      end
      self:SetQuality(vItemConf.item_quality, vItemConf.displayName, get_goods_num * self.exchangeNum, vItemConf.discription)
    end
  else
    Log.Error("\230\137\147\233\128\160\231\154\132\231\177\187\229\158\139\230\154\130\228\184\141\230\148\175\230\140\129")
  end
  _G.NRCAudioManager:PlaySound2DAuto(1373, "UMG_AlchemyItem_tips_C:OnActive")
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
end

function UMG_AlchemyItem_tips_C:SetQuality(quality, name, exchangeNum, description)
  if 0 == quality then
  elseif 1 == quality then
    self.Quality:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_pinzhi_lv_png.img_pinzhi_lv_png'")
  elseif 2 == quality then
    self.Quality:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_pinzhi_lv_png.img_pinzhi_lv_png'")
  elseif 3 == quality then
    self.Quality:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_pinzhi_lan_png.img_pinzhi_lan_png'")
  elseif 4 == quality then
    self.Quality:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_pinzhi_zi_png.img_pinzhi_zi_png'")
  elseif 5 == quality then
    self.Quality:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Alchemy/Raw/Frames/img_pinzhi_cheng_png.img_pinzhi_cheng_png'")
  end
  self.item_des:SetText(string.format("x%d", exchangeNum))
  self.BagItemNameText:SetText(string.format("%s", name))
  self.DescribeText:SetText(string.format("%s", self:PreprocessDescription(description)))
end

function UMG_AlchemyItem_tips_C:PreprocessDescription(description)
  local descriptions = string.split(description, "\n")
  local newDescription = ""
  for i, descriptionLine in ipairs(descriptions) do
    if i >= 3 then
      break
    end
    local shortDescription = string.SubStringUTF8(descriptionLine, 1, 18)
    if utf8.len(descriptionLine) > 18 then
      newDescription = string.format("%s%s...\n", newDescription, shortDescription)
    else
      newDescription = string.format("%s%s\n", newDescription, shortDescription)
    end
  end
  return newDescription
end

function UMG_AlchemyItem_tips_C:OnDeactive()
end

function UMG_AlchemyItem_tips_C:OnAddEventListener()
  self:AddButtonListener(self.HotArea, self.CloseBtnClick)
end

function UMG_AlchemyItem_tips_C:OnPcClose()
  if self.HotArea:IsVisible() then
    self:CloseBtnClick()
  end
end

function UMG_AlchemyItem_tips_C:CloseBtnClick()
  if self:IsPlayingAnimation() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_AlchemyItem_tips_C:OnClose")
  self:OnClose()
end

function UMG_AlchemyItem_tips_C:OnAnimFinished(Animation)
  if Animation == self.Out then
    _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ShowRewardFinish)
  end
  if Animation == self.In then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

return UMG_AlchemyItem_tips_C
