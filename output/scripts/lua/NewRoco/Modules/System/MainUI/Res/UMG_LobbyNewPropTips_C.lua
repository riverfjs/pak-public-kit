require("UnLuaEx")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local CampingUtils = require("NewRoco.Modules.System.Camping.CampingUtils")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local UMG_LobbyNewPropTips_C = NRCViewBase:Extend("UMG_LobbyNewPropTips_C")

function UMG_LobbyNewPropTips_C:OnConstruct()
  self.TipsQueue = {}
  self:AddButtonListener(self.btnShowPetPanel, self.OnBtnShowPetPanelClick)
  self.Holder:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CallbackOwner = nil
  self.FinishCallback = nil
  local icon1 = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xinhuode1_png.img_xinhuode1_png'"
  local icon2 = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xinhuode2_png.img_xinhuode2_png'"
  local icon3 = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xinhuode3_png.img_xinhuode3_png'"
  local icon4 = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xinhuode4_png.img_xinhuode4_png'"
  local icon5 = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xinhuode5_png.img_xinhuode5_png'"
  self.QualityIcon = {
    icon1,
    icon2,
    icon3,
    icon4,
    icon5
  }
  self.isShow = false
  self.MagicId = 100701
end

function UMG_LobbyNewPropTips_C:OnDestruct()
  self:RemoveButtonListener(self.btnShowPetPanel)
end

function UMG_LobbyNewPropTips_C:PushTip(tipsData)
  table.insert(self.TipsQueue, tipsData)
  if self.isShow == false then
    self:StartQueue()
  end
end

function UMG_LobbyNewPropTips_C:SetFinishCallback(owner, callback)
  self.CallbackOwner = owner
  self.FinishCallback = callback
end

function UMG_LobbyNewPropTips_C:OnFinish()
  self:PlayAnimation(self.Disappear)
end

function UMG_LobbyNewPropTips_C:OnEnd()
  if #self.TipsQueue > 0 then
    self:StartQueue()
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.isShow = false
    self:FireFinishCallback()
  end
end

function UMG_LobbyNewPropTips_C:FireFinishCallback()
  local Owner = self.CallbackOwner
  local Callback = self.FinishCallback
  self.CallbackOwner = nil
  self.FinishCallback = nil
  if Callback then
    Callback(Owner)
  end
end

function UMG_LobbyNewPropTips_C:TipsCount()
  return self.TipsQueue and #self.TipsQueue or 0
end

function UMG_LobbyNewPropTips_C:StartQueue()
  if 0 == #self.TipsQueue then
    return
  end
  local Current = self.TipsQueue[1]
  local flavor
  local res = ""
  local ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc, Prompt, Owner = Current:Resolve()
  NRCModuleManager:DoCmd(TipsModuleCmd.Tips_MiracleExchange, Current)
  if ItemConf then
    if Current.type == Enum.GoodsType.GT_BAGITEM then
      flavor = ItemConf.flavor_text
    end
    if Desc then
      local des = string.gsub(Desc, "\n", "")
      if flavor then
        res = string.format("%s%s", des, flavor)
      else
        res = des
      end
    end
  end
  Log.Debug(ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc, Owner, Prompt, Current:IsPlayerCard(), "UMG_LobbyNewPropTips_C:StartQueue")
  local ItemUnlockMapConf
  if ItemConf then
    ItemUnlockMapConf = _G.DataConfigManager:GetItemUnlockMapConf(ItemConf.id, true)
  end
  if ItemConf and ItemUnlockMapConf and ItemUnlockMapConf.exchange_id and #ItemUnlockMapConf.exchange_id > 0 then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_ALCHEMY_MAIN_TIPS)
    self.PromptCrafting:SetVisibility(isBan and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    local make_item_recipe = _G.DataConfigManager:GetLocalizationConf("make_item_recipe")
    local make_item_recipe_text = make_item_recipe and make_item_recipe.msg or "\232\175\183\233\133\141\231\189\174make_item_recipe"
    local ExchangeConf = _G.DataConfigManager:GetExchangeConf(ItemUnlockMapConf.exchange_id[1], true)
    if ExchangeConf then
      local PromptName = _G.DataConfigManager:GetBagItemConf(ExchangeConf.get_item[1] and ExchangeConf.get_item[1].get_goods_id).name
      self.Prompt:SetText(string.format(make_item_recipe_text, PromptName))
      self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Friend/Raw/Images/Frames/img_dazao_png.img_dazao_png'")
    end
  elseif Current:IsPlayerCard() then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Prompt:SetText(Prompt)
    self.Icon:SetPath(Current:GetCardIconPath())
  elseif ItemConf and Current.type ~= ProtoEnum.GoodsType.GT_SHARE_FORM and ItemConf.type == Enum.BagItemType.BI_FURNITURE and _G.DataConfigManager:GetExchangeConf(ItemConf.id, true) then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Prompt:SetText(string.format(LuaText.Furniture_build_get_blueprint_text, ItemConf.name))
    self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_jiajudazao_png.img_jiajudazao_png'")
  elseif ItemConf and Current.type ~= ProtoEnum.GoodsType.GT_SHARE_FORM and ItemConf.type == Enum.BagItemType.BI_MUSIC then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Prompt:SetText(LuaText.music_set_interface_main_desc)
    self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_Music_png.img_Music_png'")
  elseif ItemConf and Current.type == ProtoEnum.GoodsType.GT_SHARE_FORM then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Prompt:SetText(Prompt)
    self.Icon:SetPath(Current:GetCardIconPath())
  elseif ItemConf and ItemConf.type == Enum.BagItemType.BI_BOSS_EVO then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Prompt:SetText(LuaText.BossEvoItem_Tips)
    self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_shouling_png.img_shouling_png'")
  elseif ItemConf and ItemConf.type == Enum.BagItemType.BI_CAMERA_SKIN then
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Prompt:SetText(LuaText.takephoto_camera_skin_bottom_tips)
    self.Icon:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_xiangji_png.img_xiangji_png'")
  else
    self.PromptCrafting:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.PropName:SetText(PropName or "")
  local text, IsSurpass = self:GetMaxText(res)
  if IsSurpass then
    text = string.format("%s%s", text, "......")
  end
  Log.Debug(IsSurpass, text, "UMG_LobbyNewPropTips_C:StartQueue")
  self.LongDesc:SetText(text)
  self.Holder:SetVisibility(UE4.ESlateVisibility.Visible)
  self.NRCImage_quality:SetPath(self.QualityIcon[Quality])
  if Current.id == self.MagicId then
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(Current.id)
    PropIcon = bagItemInfo.big_icon
  end
  if Current:IsPlayerCard() then
    if Current:IsCardSkinAndCardLabel() then
      self.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ItemSwitcher:SetActiveWidgetIndex(0)
      self.NRCImage_icon:SetPath(PropIcon)
    else
      self.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Visible)
      self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.HeadPortrait.HeadPortrait:SetPath(PropIcon)
    end
  else
    self.HeadPortrait:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
    local bagItemInfo = _G.DataConfigManager:GetBagItemConf(Current.id)
    self:SetPropIcon(PropIcon, bagItemInfo, Current)
  end
  if string.IsNilOrEmpty(Owner) then
    self.SubIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SubIcon:SetPath(Owner)
    self.SubIcon:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.petGameId = Current and Current.source and Current.source.pet_data and Current.source.pet_data.gid
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008022, "UMG_LobbyNewPropTips_C:StartQueue")
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Show)
  self.isShow = true
end

function UMG_LobbyNewPropTips_C:GetMaxText(_Text)
  local str = string.GetPrintTable(_Text)
  local len = 0
  local Text
  for i = 1, #str do
    if str[i] then
      if not str[i]:match("[%w]") and not str[i]:match("[\239\191\189-\239\191\189][\239\191\189-\239\191\189][\239\191\189-\239\191\189]") and not str[i]:match("[%s]") then
        len = len + 3
      else
        len = len + 2
      end
      if not Text then
        Text = str[i]
      else
        Text = string.format("%s%s", Text, str[i])
      end
      if len >= 64 then
        return Text, true
      end
    end
  end
  return _Text, false
end

function UMG_LobbyNewPropTips_C:IconAnimation()
end

function UMG_LobbyNewPropTips_C:OnAnimationFinished(Animation)
  if Animation == self.Disappear then
    self:OnEnd()
  else
    table.remove(self.TipsQueue, 1)
    if 0 == #self.TipsQueue then
      self:OnFinish()
      return
    end
    self:StartQueue()
  end
end

function UMG_LobbyNewPropTips_C:OnBtnShowPetPanelClick()
  local Current = self.TipsQueue[1]
  if nil == Current then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BAG, true)
  if isBan then
    return
  end
  local isCanOpen = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not isCanOpen then
    return
  end
  if Current.type == ProtoEnum.GoodsType.GT_BAGITEM then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(Current.id)
    if BagItemConf and BagItemConf.type == ProtoEnum.BagItemType.BI_MUSIC then
      _G.NRCModuleManager:DoCmd(MusicCollectionModuleCmd.OnOpenMainPanel, BagItemConf.item_behavior[1].ratio[1])
    elseif BagItemConf and BagItemConf.type == ProtoEnum.BagItemType.BI_BOSS_EVO then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenLeaderItemPanel)
    elseif BagItemConf and 1 == BagItemConf.can_see then
      if BagItemConf.type == ProtoEnum.BagItemType.BI_PLANT_SEED then
        self:DelaySeconds(0.2, function()
          _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OpenSeedBagPanel, Current.id)
        end)
      else
        self:DelaySeconds(0.2, function()
          _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanel, BagModuleEnum.DisplayMode.NewItemIn, BagItemConf)
        end)
      end
    end
  elseif Current.type == ProtoEnum.GoodsType.GT_SHARE_FORM and Current.petData then
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.OpenShareUIPanel, {
      petData = Current.petData,
      shareBaseId = 1,
      sharePartId = 103
    })
  end
  if Current.tipType == TipEnum.TipObjectType.PetEvolution then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
      subPanelIndex = 4,
      pet_gid = Current.petData.gid
    })
  elseif self.petGameId and self.petGameId > 0 then
    NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
      subPanelIndex = 4,
      pet_gid = self.petGameId
    })
  end
end

function UMG_LobbyNewPropTips_C:SetPropIcon(icon_path, bag_item_conf, TipData)
  local TipItemGID
  if TipData and TipData.source and TipData.source.gids and TipData.source.gids[1] then
    TipItemGID = TipData.source.gids[1]
  end
  if icon_path and bag_item_conf and bag_item_conf.type == _G.Enum.BagItemType.BI_PET_EGG then
    if bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
      local eggInfo = {}
      eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
      self.ItemSwitcher:SetActiveWidgetIndex(1)
      self.PetEggItem:SetEggIcon(eggInfo, icon_path)
      return
    elseif TipItemGID then
      local BagItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByGid, TipItemGID)
      if BagItem then
        local EggData = BagItem.egg_data
        if EggData then
          self.ItemSwitcher:SetActiveWidgetIndex(1)
          self.PetEggItem:SetEggIcon(EggData, icon_path)
          return
        end
      end
    end
  end
  if icon_path then
    self.ItemSwitcher:SetActiveWidgetIndex(0)
    self.NRCImage_icon:SetPath(icon_path)
  end
end

return UMG_LobbyNewPropTips_C
