local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local BehaviorConfBase = require("NewRoco.Modules.Core.Behavior.BehaviorConfBase")
local BehaviorConfFactory = require("NewRoco.Modules.Core.Behavior.BehaviorConfFactory")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_Common_Tips_C = _G.NRCPanelBase:Extend("UMG_Common_Tips_C")
UMG_Common_Tips_C.ContextData = nil

function UMG_Common_Tips_C:OnConstruct()
  self.CanClose = false
  self.uiData = {}
  self:AddButtonListener(self.HotArea, self.OnClose)
  self:AddButtonListener(self.Btn_GlobalClose, self.OnClose)
  if self.CloseHyperLink then
    self:AddButtonListener(self.CloseHyperLink, self.OnCloseHyperLink)
  end
  self.ContentText.OnRichTextClick:Add(self, self.OnDescTextClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_Common_Tips_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnDisconnected)
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Common_Tips_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnDisconnected)
  self:RemoveButtonListener(self.HotArea)
  self:RemoveButtonListener(self.Btn_GlobalClose)
  if self.CloseHyperLink then
    self:RemoveButtonListener(self.CloseHyperLink, self.OnCloseHyperLink)
  end
  self.uiData = {}
  self:OnRemoveEventListener()
end

function UMG_Common_Tips_C:OnDisconnected()
  self:DoClose()
end

function UMG_Common_Tips_C:OnActive(context)
  self.ItemSwitcher:SetActiveWidgetIndex(1)
  self.ItemType = context.goodsType
  self.ItemId = context.goodsId
  self:OnAddEventListener()
  self.Btn_GlobalClose:SetVisibility(UE4.ESlateVisibility.Visible)
  _G.NRCAudioManager:PlaySound2DAuto(40007008, "UMG_Common_Tips_C:OnActive")
  self:LoadAnimation(0)
  self.TitleText:SetText(context.title)
  self.ExpireText:SetText(context.expireTime)
  if context.content then
    self.descText = context.content
    self.ContentText:SetText(context.content)
    self.ContentText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ContentText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if context.flavor then
    self.NRCTextDes_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCTextDes_1:SetText(context.flavor)
  else
    self.NRCTextDes_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if context.content == nil and context.flavor == nil then
    if UE.UObject.IsValid(self.VerticalBox_107) then
      self.VerticalBox_107:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.bgnew:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if UE.UObject.IsValid(self.VerticalBox_107) then
      self.VerticalBox_107:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.bgnew:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.EggItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if context.eggData and context.updateTime then
    self:SetEggInfo(context.eggData, context.updateTime)
  end
  if context.quality then
    self:SetQuality(context.quality)
    self.Quality_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Quality_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if context.typeDesc then
    self.HorizontalBox_72:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Type:SetText(context.typeDesc)
  else
    self.HorizontalBox_72:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.OwnedText:SetText(tostring(context.ownedNumber))
  if #context.acquirePath > 0 then
    local acquirePath = {}
    for i = 1, #context.acquirePath do
      table.insert(acquirePath, {
        acquire_struct = context.acquirePath[i],
        ItemType = self.ItemType,
        ItemId = self.ItemId
      })
    end
    self.ItemSourceList:InitList(acquirePath)
  end
  self.uiData.acquirePath = context.acquirePath
  self.Caller = context.Caller
  self.CallBack = context.CallBack
  if context.skillConf then
    self.SkillAttributes:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SkillIcon:SetPath(context.skillConf.icon)
    self.NumericalValue_1:SetText(context.skillConf.energy_cost[1])
    self.Department_1:SetPath(self:GetSkillTypePath(context.skillConf.Skill_Type, context.skillConf.damage_type))
    if 1 ~= context.skillConf.damage_type then
      self.NumericalValue_4:SetText(tostring(context.skillConf.dam_para[1]))
    else
      self.NumericalValue_4:SetText("-")
    end
  else
    self.SkillAttributes:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetBagItemNumVisibility(context)
  if context.salonData then
    self.ItemSwitcher:SetActiveWidgetIndex(2)
    self.Icon1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.MakeupProp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local salonId = context.salonData.salonConfId
    local salonConf = _G.DataConfigManager:GetSalonItemConf(salonId)
    if salonConf and #salonConf.colour_id > 0 then
      self.Bg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Closet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Closet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if not string.IsNilOrEmpty(context.iconPath) then
      self.Icon_Makeup:SetPath(context.iconPath)
      self.Closet:OnItemUpdate(context.salonData)
    end
  elseif context.eggData or self:GetRandomEggData() then
    self.ItemSwitcher:SetActiveWidgetIndex(3)
    if context.eggData then
      self.PetEggItem:SetEggIcon(context.eggData, context.iconPath)
    else
      self.PetEggItem:SetEggIcon(self.randomEggData, context.iconPath)
    end
  else
    self.MakeupProp:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Icon1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if string.IsNilOrEmpty(context.iconPath) and context.showDefaultIconWhenNotFound then
      local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
      if commonIconConfig and commonIconConfig.str then
        Log.Debug("UMG_Common_Tips_C:SetInfo showDefaultIconWhenNotFound, iconpath is empty, set to default", tostring(commonIconConfig.str))
        context.iconPath = commonIconConfig.str
      else
        Log.Error("UMG_Common_Tips_C:SetInfo showDefaultIconWhenNotFound no default image config for common_reward_icon in activity_global_config")
      end
    end
    if not string.IsNilOrEmpty(context.iconPath) then
      local iconPath = context.iconPath
      if context.showDefaultIconWhenNotFound then
        Log.Debug("UMG_Common_Tips_C:SetInfo showDefaultIconWhenNotFound", tostring(iconPath))
        self.itemIconPath = iconPath
        self.Icon1:SetPathWithSuccessAndFailedCallBack(iconPath, {
          self,
          self.IconSetPathSuccess
        }, {
          self,
          self.IconSetPathFailed
        })
      else
        self.Icon1:SetPath(iconPath)
      end
    end
  end
  if context.canCharge and context.remainCnt < 99 then
    self.UseTimes:SetVisibility(UE4.ESlateVisibility.Visible)
    local UseTimesText = LuaText.umg_common_tips_1 .. "  " .. string.format("%d / %d", context.remainCnt, context.maxCnt)
    self.UseTimes:SetText(UseTimesText)
    self.Desc_1:SetVisibility(UE4.ESlateVisibility.visible)
    self.Desc_2:SetVisibility(UE4.ESlateVisibility.visible)
  else
    self.UseTimes:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Desc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Desc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local IsBattle = _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle)
  if context.isBattleState or 0 == #self.uiData.acquirePath or IsBattle then
    self.Canvas_Bottom:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.ItemSourceList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Canvas_Bottom:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemSourceList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if context.isBattleState then
    self.HotArea:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CommonBgBlack:SetBackgroundVisible(false)
  else
    self.HotArea:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_CommonBgBlack:SetBackgroundVisible(true)
  end
  self.isInBattle = context.isBattleState
  self:BindInputAction()
  if context.position then
    local CanvasSlot = self.Content.Slot
    CanvasSlot:SetPosition(context.position)
  end
  if context.OpenCallBack and self.Caller then
    context.OpenCallBack(self.Caller)
  end
  if context.PreviewParams then
    self.VerticalBox_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ItemSourceList_2:InitList({
      context.real_acquire_struct
    })
  else
    self.VerticalBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:ShowGiftInfo(context)
end

function UMG_Common_Tips_C:IconSetPathSuccess()
  Log.Debug("UMG_Common_Tips_C:IconSetPathSuccess")
end

function UMG_Common_Tips_C:IconSetPathFailed()
  Log.Warning("UMG_Common_Tips_C:IconSetPathFailed", tostring(self.itemIconPath))
  local commonIconConfig = ActivityUtils.GetActivityGlobalConfig("common_reward_icon")
  if commonIconConfig and commonIconConfig.str then
    self.itemDefaultIconPath = commonIconConfig.str
    self.Icon1:SetPathWithSuccessAndFailedCallBack(commonIconConfig.str, {
      self,
      self.IconSetDefaultPathSuccess
    }, {
      self,
      self.IconSetDefaultPathFailed
    })
  else
    Log.Error("UMG_Common_Tips_C:IconSetPathFailed no default image config for common_reward_icon in activity_global_config")
  end
end

function UMG_Common_Tips_C:IconSetDefaultPathSuccess()
  Log.Debug("UMG_Common_Tips_C:IconSetDefaultPathSuccess")
end

function UMG_Common_Tips_C:IconSetDefaultPathFailed()
  Log.Error("UMG_Common_Tips_C:IconSetDefaultPathFailed", tostring(self.itemDefaultIconPath))
end

function UMG_Common_Tips_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_Common_Tips_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_Common_Tips_C:GetSkillTypePath(type, damage_type)
  if type == Enum.SkillType.ST_DAMAGE then
    if damage_type == Enum.DamageType.DT_SPC then
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_04_png.ui_pet_attribute_04_png'"
    else
      return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/ui_pet_attribute_02_png.ui_pet_attribute_02_png'"
    end
  elseif type == Enum.SkillType.ST_DEFEND then
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_DEFENSE_png.AT_DEFENSE_png'"
  else
    return "PaperSprite'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/PetSystem/Frames/AT_CLASSIFICATION_png.AT_CLASSIFICATION_png'"
  end
end

function UMG_Common_Tips_C:SetBagItemNumVisibility(context)
  local bVisible = true
  if context.goodsId then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(context.goodsId)
    if BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_BOSS_EVO then
        bVisible = false
      elseif BagItemType == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
        bVisible = true
      else
        bVisible = not BagItemConf.tips_not_show_inventory
      end
    end
  end
  if context.isHideBagIcon and context.isHideBagIcon == true then
    bVisible = false
  end
  if self.HorizontalBox_0 then
    self.HorizontalBox_0:SetVisibility(bVisible and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_Tips_C:OnAddEventListener()
end

function UMG_Common_Tips_C:OnRemoveEventListener()
end

function UMG_Common_Tips_C:OnAnimationFinished(Animation)
  if self:GetAnimByIndex(0) == Animation then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "BattlePassModule", "BattlePassAwardMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "BattlePassAwardMain").TIPS)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "StarChain", "UMG_StarChainAward", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "UMG_StarChainAward").TIPSITEM)
  elseif self:GetAnimByIndex(2) == Animation then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OnCloseCommonTips)
    self:DoClose()
  end
end

function UMG_Common_Tips_C:OnDeactive()
  self:UnBindInputAction()
  if self.Caller and self.CallBack then
    self.CallBack(self.Caller)
  end
end

function UMG_Common_Tips_C:SetQuality(quality)
  self.IconQuality:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if 0 == quality then
    self.IconQuality:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif 1 == quality then
    self.Quality_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_1))
  elseif 2 == quality then
    self.Quality_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_2))
  elseif 3 == quality then
    self.Quality_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_3))
  elseif 4 == quality then
    self.Quality_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_4))
  elseif 5 == quality then
    self.Quality_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(UEPath.Color_QUALITY_5))
  end
end

function UMG_Common_Tips_C:SetEggInfo(EggData, UpdateTime)
  if nil == EggData then
    Log.Error("UMG_Common_Tips_C:SetEggInfo EggData = nil")
    return
  end
  if nil == EggData.height or nil == EggData.weight then
    Log.Error("UMG_Common_Tips_C:SetEggInfo no height or weight")
    return
  end
  UpdateTime = os.date("%Y-%m-%d", UpdateTime)
  local eggFindTimeInfo = {
    name = LuaText.umg_bag_1,
    type = 2,
    des = UpdateTime
  }
  local eggHeightInfo = {
    name = LuaText.umg_bag_2,
    type = 0,
    des = EggData.height * 0.01
  }
  local eggWeightInfo = {
    name = LuaText.umg_bag_4,
    type = 1,
    des = EggData.weight * 0.001
  }
  local eggInfoList = {
    eggHeightInfo,
    eggWeightInfo,
    eggFindTimeInfo
  }
  self.EggItem:SetVisibility(UE.ESlateVisibility.Visible)
  for i = 1, 3 do
    local name = string.format("EggItem%d", i)
    self[name]:OnShowItem(eggInfoList[i])
  end
end

function UMG_Common_Tips_C:OnClose()
  self:RemoveButtonListener(self.HotArea)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40007009, "UMG_Common_Tips_C:OnClose")
  self:LoadAnimation(2)
end

function UMG_Common_Tips_C:BindInputAction()
  if self.isInBattle then
    local mappingContext = self:AddInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:BindAction("IA_CloseUI", self, "OnPcClose2")
    end
  else
    local mappingContext = self:AddInputMappingContext("IMC_CommonTips")
    if mappingContext then
      mappingContext:BindAction("IA_CloseCommonTips", self, "OnPcClose2")
    end
  end
end

function UMG_Common_Tips_C:UnBindInputAction()
  if self.isInBattle then
    local mappingContext = self:GetInputMappingContext("IMC_CloseBattleTips")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseUI")
    end
    self:RemoveInputMappingContext("IMC_CloseBattleTips")
  else
    local mappingContext = self:GetInputMappingContext("IMC_CommonTips")
    if mappingContext then
      mappingContext:UnBindAction("IA_CloseCommonTips")
    end
    self:RemoveInputMappingContext("IMC_CommonTips")
  end
end

function UMG_Common_Tips_C:OnDescTextClicked(id)
  local nounInterpretationTipsInfo = {}
  nounInterpretationTipsInfo.text = self.descText
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNounInterpretationTipsPanel, nounInterpretationTipsInfo)
end

function UMG_Common_Tips_C:ResetDescText()
end

function UMG_Common_Tips_C:OnCloseHyperLink()
end

function UMG_Common_Tips_C:OnPcClose2()
  if self:IsPlayingAnimation() then
    return
  end
  self:OnClose()
end

function UMG_Common_Tips_C:ShowGiftInfo(context)
  if context.goodsId and context.goodsType and context.goodsType == Enum.GoodsType.GT_BAGITEM then
    local bagItem = _G.DataConfigManager:GetBagItemConf(context.goodsId)
    if bagItem then
      if bagItem.type == Enum.BagItemType.BI_BP_GIFT_SUB then
        self.deadline:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:UpdateExpireTimeDisplay(bagItem)
      else
        self.deadline:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_Common_Tips_C:UpdateExpireTimeDisplay(giftBagItem)
  if not giftBagItem then
    Log.Warning("[BP] UpdateExpireTimeDisplay: giftBagItem is nil")
    return
  end
  local BagData = NRCModuleManager:GetModule("BagModule"):GetData()
  if not BagData then
    return
  end
  local expireThreshold = _G.DataConfigManager:GetGlobalConfig("bp_gift_time_runs_out")
  local color = "#F4EEE1FF"
  self.OutputText1_3:SetText(LuaText.item_expired_text03)
  self.OutputText_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(color))
  local expireStatus = BagData:CheckItemExpireStatus(giftBagItem, expireThreshold)
  if self.NRCImage_1 then
    self.NRCImage_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
  end
  if expireStatus.isExpired then
    self.OutputText_1:SetText(LuaText.item_expired_text04)
  elseif expireStatus.isNearExpire then
    self.OutputText_1:SetText(giftBagItem.expire_time)
    local color = "#AF3D3EFF"
    self.OutputText_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(color))
    if self.NRCImage_1 then
      self.NRCImage_1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(color))
    end
  else
    self.OutputText_1:SetText(giftBagItem.expire_time)
  end
  local acquirePath = giftBagItem.acquire_struct
  local IsBattle = _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle)
  if acquirePath and #acquirePath > 0 and not IsBattle then
    local acquirePathList = {}
    for i = 1, #acquirePath do
      table.insert(acquirePathList, {
        acquire_struct = acquirePath[i],
        ItemType = self.ItemType,
        ItemId = self.ItemId
      })
    end
    self.ItemSourceList_1:InitList(acquirePathList)
    self.ItemSourceList_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if self.ItemSourceList then
      self.ItemSourceList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.ItemSourceList_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Common_Tips_C:GetRandomEggData()
  if self.ItemType == _G.Enum.GoodsType.GT_BAGITEM then
    local bag_item_conf = _G.DataConfigManager:GetBagItemConf(self.ItemId)
    if bag_item_conf and bag_item_conf.type == Enum.BagItemType.BI_PET_EGG and bag_item_conf.item_behavior and bag_item_conf.item_behavior[1] and bag_item_conf.item_behavior[1].ratio2 and bag_item_conf.item_behavior[1].ratio2[1] then
      local eggInfo = {}
      eggInfo.random_egg_conf = bag_item_conf.item_behavior[1].ratio2[1]
      self.randomEggData = eggInfo
      return self.randomEggData
    end
  end
  return nil
end

function UMG_Common_Tips_C:CheckIsCustomGlassPiece(context)
  local ret = false
  if context.goodsId then
    local BagItemConf = _G.DataConfigManager:GetBagItemConf(context.goodsId)
    if BagItemConf then
      local BagItemType = BagItemConf.type
      if BagItemType == _G.Enum.BagItemType.BI_GLASS_EGG_PIECE then
        ret = true
      end
    end
  end
  return ret
end

return UMG_Common_Tips_C
