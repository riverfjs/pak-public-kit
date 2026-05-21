local UMG_SkillLearning_C = _G.NRCPanelBase:Extend("UMG_SkillLearning_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local enum = reload("Data.Config.Enum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")

function UMG_SkillLearning_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
  self:OnAddEventListener()
end

function UMG_SkillLearning_C:OnActive(_data, autoLevel, autoUnLock)
  if not _data then
    return
  end
  if autoUnLock then
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.skipCloseCallBackType = nil
  self:LoadAnimation(0)
  self:PlayAnimation(self.open)
  self:SetCommonPopUpInfo()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseBagSKillTips)
  self.data = _data and _data or self.data
  self.autoUnLevel = autoLevel and autoLevel or self.autoUnLevel
  self.autoUnLock = autoUnLock and autoUnLock or self.autoUnLock
  self.LockSuccess = false
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
  self.bCanLock = false
  self.synthesisList = {}
  self.curSynthesisIndex = 1
  self.materialsList = {}
  self.curMaterialsIndex = 1
  self.showItemList = {}
  self.curPetLevelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.petData.base_conf_id)
  if self.curPetLevelSkillConf then
    self.curPetBloodSkillConf = PetUtils.GetSkillBloodData(self.petData.blood_id, self.curPetLevelSkillConf) or PetUtils.GetPetCurBloodSkillConf(self.petData)
  end
  self.unLockSkillAutoEquipPos = self:GetCurUnLockSkillAutoEquipPos()
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
    self:LevelUpShowHandle()
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
    self:SkillBookShowHandle()
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    self:PetBloodShowHandle()
  end
  self:SetCommonPopUpInfo()
  self:RefreshTitleAndDesc()
  if self.autoUnLock then
    self:OnConFirm(true)
  end
end

function UMG_SkillLearning_C:OnAddEventListener()
  self:AddButtonListener(self.ChangeBtn, self.OnChangeFormulaClick)
  self:AddButtonListener(self.ChangeBtn_1, self.OnChangeMaterialsClick)
  self:AddButtonListener(self.Tipsbtn, self.OnTipsbtnClick)
  self:AddButtonListener(self.OpenSkillDetailsBtn, self.OnOpenSkillDetailsBtnClick)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpItemSuccess)
end

function UMG_SkillLearning_C:OnClose(skipAudio)
  if not skipAudio then
    _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_SkillLearning_C:OnClose")
  end
  self:RemoveAllButtonListener()
  self:RemoveAllDelegateListener()
  self.skipCloseCallBackType = nil
  self:LoadAnimation(2)
  self:PlayAnimation(self.Close)
  _G.NRCAudioManager:PlaySound2DAuto(41400010, "UMG_SkillLearning_C:OnClose")
end

function UMG_SkillLearning_C:OnDestruct()
  self:DispatchEvent(PetUIModuleEvent.OnSkillLearningClose)
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  if self.ExDelayId then
    _G.DelayManager:CancelDelayById(self.ExDelayId)
    self.ExDelayId = nil
  end
  if self.SelectDelayId then
    _G.DelayManager:CancelDelayById(self.SelectDelayId)
    self.SelectDelayId = nil
  end
end

function UMG_SkillLearning_C:CalculateCost(data)
  self.data = data
  local ItemDosageInfoList, exchangeID
  if data.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
    ItemDosageInfoList = self:LevelUpShowHandle()
  elseif data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK then
    ItemDosageInfoList = self:SkillBookShowHandle()
  elseif data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    ItemDosageInfoList, exchangeID = self:PetBloodShowHandle()
  end
  NRCEventCenter:DispatchEvent(PetUIModuleEvent.UpdatePetTeamCost, ItemDosageInfoList, exchangeID)
  return ItemDosageInfoList, exchangeID
end

function UMG_SkillLearning_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.TitleText = self.Title
  CommonPopUpData.Desc = self.Desc
  CommonPopUpData.ClosePanelHandler = self.OnClose
  CommonPopUpData.Btn_LeftHandler = self.OnCancel
  CommonPopUpData.Btn_RightHandler = self.OnConFirm
  CommonPopUpData.Btn_RightTitle = self.Btn_RightTitle
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp4:SetPanelInfo(CommonPopUpData)
  if self.bCanLock then
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.PopUp4.Btn_Right_GrayState:SetIsEnabled(false)
    self.PopUp4.Btn_Right_GrayState.Title_1:SetText(LuaText.umg_dialog_2)
    self.PopUp4.Btn_Right_GrayState.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SkillLearning_C:RefreshTitleAndDesc()
  self.PopUp4:SetTitleTextInfo(self.Title)
  self.PopUp4:SetDescInfo(self.Desc)
end

function UMG_SkillLearning_C:LevelUpShowHandle()
  local ItemDosageInfoList = {}
  self.bCanLock, ItemDosageInfoList, self.Desc = self:CheckCanLockByLevelUp(tonumber(self.data.text))
  self.Title = LuaText.umg_petbaseinfo_1
  self.Switcher:SetActiveWidgetIndex(1)
  self:RefreshItemListShow(ItemDosageInfoList)
  return ItemDosageInfoList
end

function UMG_SkillLearning_C:SkillBookShowHandle()
  local bCanLock, itemSynthesisInfos, desc = self:CheckCanLockByCostBagItem(self.data.bagItemIds[1])
  self.bCanLock = bCanLock
  self.Title = LuaText.skill_unlock_title_1
  self.Desc = desc
  self.synthesisList = itemSynthesisInfos
  local ItemDosageInfoList
  if #self.synthesisList > 0 and self.synthesisList[1].exchangeId then
    self.Title = LuaText.skill_unlock_title_2
    self.Switcher:SetActiveWidgetIndex(0)
    self.ChangeBtn:SetVisibility(#self.synthesisList > 1 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.ChangeBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    ItemDosageInfoList = self:RefreshFormulaShow(1)
  else
    self.Switcher:SetActiveWidgetIndex(1)
    local dosageInfo = self:CreateItemDosageInfo(self.synthesisList[1].id, nil, 1, self.synthesisList[1].type)
    local ItemDosageInfoList = {dosageInfo}
    self:RefreshItemListShow(ItemDosageInfoList)
  end
  return ItemDosageInfoList
end

function UMG_SkillLearning_C:PetBloodShowHandle()
  self.Switcher:SetActiveWidgetIndex(0)
  local bCanLock, itemSynthesisInfo, desc = self:CheckCanLockByCostBagItems(self.data.bagItemIds)
  self.bCanLock = bCanLock
  self.Title = LuaText.skill_unlock_title_3
  self.Desc = desc
  self.synthesisList = {itemSynthesisInfo}
  local ItemDosageInfoList, exchangeID
  if #self.synthesisList > 0 and self.synthesisList[1].exchangeId then
    self.Title = LuaText.skill_unlock_title_4
    self.Switcher:SetActiveWidgetIndex(0)
    self.Switcher:SetActiveWidgetIndex(0)
    self.ChangeBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ChangeBtn_1:SetVisibility(#self.synthesisList > 1 and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    ItemDosageInfoList = self:RefreshFormulaShow(1)
    exchangeID = self.synthesisList[1].exchangeId
  else
    self.Switcher:SetActiveWidgetIndex(1)
    local dosageInfo = self:CreateItemDosageInfo(self.synthesisList[1].id, nil, 1, self.synthesisList[1].type)
    ItemDosageInfoList = {dosageInfo}
    self:RefreshItemListShow(ItemDosageInfoList)
  end
  return ItemDosageInfoList, exchangeID
end

function UMG_SkillLearning_C:RefreshItemListShow(itemDosageInfoList)
  if itemDosageInfoList then
    self.showItemList = itemDosageInfoList
    local showItemList = {}
    for i, v in ipairs(itemDosageInfoList) do
      local itemIconData = self:CreateCommonItemIconData(v)
      table.insert(showItemList, itemIconData)
    end
    self.List_1:InitGridView(showItemList)
  end
end

function UMG_SkillLearning_C:RefreshFormulaShow(index)
  self.curSynthesisIndex = index
  if self.synthesisList and index <= #self.synthesisList then
    local itemSynthesisInfo = self.synthesisList[self.curSynthesisIndex]
    local showItems = {}
    local bHasAlternate = false
    for i, costItem in ipairs(itemSynthesisInfo.cost_item) do
      if #costItem.cost_goods_id > 1 then
        bHasAlternate = true
        _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.ResetAlternateMaterials)
        showItems[2] = self:GetAlternateMaterial()
      else
        local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, costItem.cost_goods_id[1], costItem.cost_goods_type)
        table.insert(showItems, self:CreateItemDosageInfo(costItem.cost_goods_id[1], num, costItem.cost_goods_num, costItem.cost_goods_type))
      end
    end
    local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, itemSynthesisInfo.id, _G.Enum.GoodsType.GT_BAGITEM)
    showItems[3] = self:CreateItemDosageInfo(itemSynthesisInfo.id, num, 1, _G.Enum.GoodsType.GT_BAGITEM)
    if showItems[1] then
      self.PetGrowUp_Icon:OnItemUpdate(self:CreateCommonItemIconData(showItems[1]))
      self.PetGrowUp_Icon.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal1_png.img_daojukuangnormal1_png'")
    end
    if showItems[2] then
      self.ItemIcon2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PetGrowUp_Icon_1:OnItemUpdate(self:CreateCommonItemIconData(showItems[2]))
      self.PetGrowUp_Icon_1.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal1_png.img_daojukuangnormal1_png'")
    else
      self.ItemIcon2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.ChangeBtn_1:SetVisibility(bHasAlternate and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.PetGrowUp_Icon_2:OnItemUpdate(self:CreateCommonItemIconData(showItems[3]))
    self.PetGrowUp_Icon_2.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/Raw/Frames/img_daojukuangnormal1_png.img_daojukuangnormal1_png'")
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(itemSynthesisInfo.exchangeId)
    if exchangeConf then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(exchangeConf.visual_item_cost_type)
      if nil ~= vItemConf then
        self.NRCImage_442:SetPath(vItemConf.iconPath)
        self.PopUp4.Btn_Right:SetTitleTextAndIcon(vItemConf.iconPath, exchangeConf.visual_item_cost_num)
        self.PopUp4:SetRightBtnTitleTextAndIconShow(true)
        self.Btn_RightTitle = true
      end
      self.Number:SetText(exchangeConf.visual_item_cost_num)
      local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(exchangeConf.visual_item_cost_type) or 0
      local moneyInfo = {}
      table.insert(moneyInfo, {
        moneyType = exchangeConf.visual_item_cost_type,
        sum = coin_num,
        IsShowBuyIcon = false
      })
      self.MoneyBtn:InitGridView(moneyInfo)
    end
    self.showItemList = showItems
    return self.showItemList
  end
end

function UMG_SkillLearning_C:OnTipsbtnClick()
  if self.petData then
    _G.NRCModeManager:DoCmd(PetUIModuleCmd.ShowChangePetConfirm, self.petData)
  end
end

function UMG_SkillLearning_C:OnOpenSkillDetailsBtnClick()
  if self.data then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenBagSKillTips, self.data.skillId)
  end
end

function UMG_SkillLearning_C:OnChangeMaterialsClick()
  _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_SkillLearning_C:OnChangeMaterialsClick")
  self.skipCloseCallBackType = 1
  self:LoadAnimation(2)
  self:PlayAnimation(self.Close)
end

function UMG_SkillLearning_C:SetExchangeMaterial()
  self.ExDelayId = _G.DelayManager:DelaySeconds(0.2, function()
    self:LoadAnimation(0)
    self:PlayAnimation(self.open)
  end)
  local data = self:GetAlternateMaterial()
  if data then
    self.PetGrowUp_Icon_1:OnItemUpdate(self:CreateCommonItemIconData(data))
    self.showItemList[2] = data
    if data.itemNum < data.needNum then
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_SkillLearning_C:OnChangeFormulaClick()
  _G.NRCAudioManager:PlaySound2DAuto(41401016, "UMG_SkillLearning_C:OnChangeFormulaClick")
  self.skipCloseCallBackType = 2
  self:LoadAnimation(2)
  self:PlayAnimation(self.Close)
end

function UMG_SkillLearning_C:OnSelectFormula(exchangeId)
  self.SelectDelayId = _G.DelayManager:DelaySeconds(0.2, function()
    self:LoadAnimation(0)
    self:PlayAnimation(self.open)
  end)
  if exchangeId then
    for i, v in ipairs(self.synthesisList) do
      if v.exchangeId == exchangeId then
        self.curSynthesisIndex = i
      end
    end
    self:RefreshFormulaShow(self.curSynthesisIndex)
  end
end

function UMG_SkillLearning_C:OnUseExpItemSuccess()
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
  self.Title = LuaText.skill_unlock_title_5
  local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    if self:IsAutoEquipSkill() then
      self.Desc = string.format(LuaText.skill_blood_tips_9, self.petData.name, self.petData.level, self.data.text, skillConf.name)
    else
      self.Desc = string.format(LuaText.skill_blood_tips_10, self.petData.name, self.petData.level, self.data.text, skillConf.name)
    end
  elseif self:IsAutoEquipSkill() then
    self.Desc = string.format(LuaText.skill_feed_tips_5, self.petData.name, self.petData.level, skillConf.name)
  else
    self.Desc = string.format(LuaText.skill_feed_tips_2, self.petData.name, self.petData.level, skillConf.name)
  end
  self.skipCloseCallBackType = 3
  self:LoadAnimation(2)
end

function UMG_SkillLearning_C:OnUseBagItemSuccess()
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
  self.Title = LuaText.skill_unlock_title_6
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    if self.curPetLevelSkillConf and self.petData.level < self.curPetLevelSkillConf.blood_skill_level_point then
      if self.autoUnLevel then
        local upLevelNeedItem = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetSkillUnLockInfoByLevelUp, self.curPetLevelSkillConf.blood_skill_level_point, self.data.petGid)
        self:UseFoodItemHandle(upLevelNeedItem)
      else
        local newSkillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
        if newSkillConf then
          self.Desc = string.format(LuaText.skill_blood_tips_5, self.petData.name, self.data.text, self.curPetLevelSkillConf.blood_skill_level_point, newSkillConf.name)
          self.RedDot:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    else
      local newSkillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
      if newSkillConf then
        if self:IsAutoEquipSkill() then
          self.Desc = string.format(LuaText.skill_blood_tips_6, self.petData.name, self.data.text, newSkillConf.name)
        else
          self.Desc = string.format(LuaText.skill_blood_tips_4, self.petData.name, self.data.text, newSkillConf.name)
        end
      end
    end
  else
    local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
    if self:IsAutoEquipSkill() then
      self.Desc = string.format(LuaText.skill_stone_tips_5, self.petData.name, skillConf.name)
    else
      self.Desc = string.format(LuaText.skill_stone_tips_4, self.petData.name, skillConf.name)
    end
  end
  self.skipCloseCallBackType = 3
  self:LoadAnimation(2)
end

function UMG_SkillLearning_C:OnUseFormulaSuccess()
  if self.data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK or self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    self:UseItemHandle(self.synthesisList[self.curSynthesisIndex].id)
  end
end

function UMG_SkillLearning_C:RefreshLockSuccessShow()
  if self.autoUnLock then
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_SkillLearning_C:RefreshLockSuccessShow")
  self.LockSuccess = true
  self.Switcher:SetActiveWidgetIndex(2)
  self.PopUp4:SetRightBtnTitleTextAndIconShow(false)
  self.HeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  self.NumText:SetText(self.petData.level)
  local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
  if skillConf then
    self.TxtSkillName:SetText(skillConf.name)
    self.SkillIcon:SetPath(skillConf.icon)
    self.TxtPnum:SetText(skillConf.energy_cost[1])
    local Name, Path
    if skillConf.damage_type == enum.DamageType.DT_NONE then
      Name = "--"
    else
      Name = skillConf.dam_para[1]
    end
    local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
    if typeDic then
      Path = typeDic.tips_res
    end
    local typeList = {
      {Name = Name, Path = Path}
    }
    self.Attr:InitGridView(typeList)
    self.RedDot.RedPointNode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local petBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  if petBloodConf then
    self.BloodPulse:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.icon:SetPath(petBloodConf.icon)
  end
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    self.icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self:IsAutoEquipSkill() then
    self:AutoEquipSkillHandle()
    self.PopUp4:ShowOrHideBtnLeft(false)
    self.PopUp4:ShowOrHideBtnRight(false)
  else
    self.PopUp4.Btn_Left.Title_1:SetText(LuaText.skill_change_title_1)
  end
end

function UMG_SkillLearning_C:AutoEquipSkillHandle()
  if not self.petData then
    return
  end
  local posToIdDic, _ = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid)
  if posToIdDic then
    for i, v in pairs(posToIdDic) do
      if v == self.data.skillId then
        return
      end
    end
    posToIdDic[self.unLockSkillAutoEquipPos] = self.data.skillId
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.AutoCheckEnvironmentEquipPetSkill, self.petData.gid, posToIdDic)
  end
end

function UMG_SkillLearning_C:RemoveNilPos(ids)
  if not ids then
    return {}
  end
  local newSkillIds = {}
  for i, v in pairs(ids) do
    newSkillIds[#newSkillIds + 1] = v
  end
  return newSkillIds
end

function UMG_SkillLearning_C:OnCancel()
  if self.LockSuccess and self.PopUp4.Btn_Left.Title_1:GetText() == LuaText.skill_change_title_1 then
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_SkillLearning_C:OnCancel")
    self.skipCloseCallBackType = 4
    self:LoadAnimation(2)
    self:PlayAnimation(self.Close)
  else
    self:OnClose()
  end
end

function UMG_SkillLearning_C:UseFoodItemHandle(ItemList)
  local UseItemList = {}
  if ItemList then
    for i, dosageInfo in pairs(ItemList) do
      if dosageInfo.needNum > 0 then
        table.insert(UseItemList, {
          gid = dosageInfo.gid,
          num = dosageInfo.needNum,
          para = self.data.petGid
        })
      end
    end
  end
  if #UseItemList > 0 then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.UseExpItem, UseItemList)
  end
end

function UMG_SkillLearning_C:UseItemHandle(itemId)
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, itemId)
  if bagItem then
    local targetBlood
    local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId, true)
    if skillConf then
      targetBlood = PetUtils.GetPetBloodBySkillDamType(skillConf.skill_dam_type)
    end
    local extraParam = {}
    extraParam.para2 = targetBlood
    _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItem, bagItem.gid, bagItem.id, 1, self.petData.gid, extraParam)
  end
end

function UMG_SkillLearning_C:OnConFirm(skipAudio)
  if not skipAudio then
    _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_SkillLearning_C:OnConFirm")
  end
  if self.LockSuccess then
    self:OnClose(true)
    return
  end
  if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_LEVEL_UP then
    self:UseFoodItemHandle(self.showItemList)
  elseif self.data.type == Enum.PetNewSkillSrc.PNSS_SKILL_BOOK or self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
    local itemSynthesisInfo = self.synthesisList[self.curSynthesisIndex]
    if itemSynthesisInfo.exchangeId then
      local itemIdList = {}
      for _, item in pairs(self.showItemList) do
        if item.gid and item.itemType and item.itemId and item.needNum then
          table.insert(itemIdList, {
            goods_type = item.itemType,
            goods_id = item.itemId,
            goods_num = item.needNum
          })
        end
      end
      table.sort(itemIdList, function(a, b)
        local aValue = self:GetItemByCostConfListIndex(itemSynthesisInfo, a.goods_id)
        local bValue = self:GetItemByCostConfListIndex(itemSynthesisInfo, b.goods_id)
        return aValue < bValue
      end)
      _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.RequestForExchange, itemSynthesisInfo.exchangeId, 1, itemIdList)
    else
      self:UseItemHandle(itemSynthesisInfo.id)
    end
  end
  self.PopUp4.Btn_Right:SetIsEnabled(false)
end

function UMG_SkillLearning_C:GetItemByCostConfListIndex(ItemSynthesisInfo, itemId)
  if ItemSynthesisInfo and ItemSynthesisInfo.cost_item then
    for index, item in pairs(ItemSynthesisInfo.cost_item) do
      if #item.cost_goods_id > 0 then
        for j, id in ipairs(item.cost_goods_id) do
          if id == itemId then
            return index
          end
        end
      end
    end
  end
  return 0
end

function UMG_SkillLearning_C:CheckCanLockByLevelUp(unLockLv)
  local bCanLock = false
  local dosageInfoList = {}
  local Desc
  local bHaveEnoughExp = false
  local upLevel = 0
  if self.petData then
    local petCurExp = self.petData.exp
    local petLevelConf = _G.DataConfigManager:GetPetLevelConf(unLockLv - 1)
    local goalNeedExp = petLevelConf and petLevelConf.pet_exp or 0
    local curNeedExp = goalNeedExp - petCurExp
    local useItemAddExp = 0
    bHaveEnoughExp, dosageInfoList, useItemAddExp = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetUseExpItemDosage, curNeedExp)
    local tempExp = petCurExp + useItemAddExp
    local petInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(nil, self.petData)
    for i, v in pairs(petInfo.petLevelExpList) do
      if tempExp < v.pet_exp then
        upLevel = i
        break
      end
    end
  end
  local maxLevel, MaxLevelInfo = PetUtils.GetPetMaxLevel()
  if unLockLv > maxLevel then
    local WorldLevelConfList = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_LEVEL_CONF):GetAllDatas()
    for i, v in pairs(WorldLevelConfList) do
      if unLockLv <= v.pet_level_limit then
        Desc = string.format(LuaText.skill_feed_tips_4, v.title)
        break
      end
    end
    bCanLock = false
  elseif bHaveEnoughExp then
    local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
    if skillConf then
      Desc = string.format(LuaText.skill_feed_tips_1, upLevel, skillConf.name)
    end
    bCanLock = true
  else
    Desc = LuaText.skill_feed_tips_3
    bCanLock = false
  end
  return bCanLock, dosageInfoList, Desc
end

function UMG_SkillLearning_C:CheckCanLockByCostBagItem(bagItemId)
  local Desc
  local ItemSynthesisInfos = {}
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if bagItem and bagItem.num > 0 then
    local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
    if skillConf then
      Desc = string.format(LuaText.skill_stone_tips_1, self.petData.name, skillConf.name)
    end
    table.insert(ItemSynthesisInfos, {id = bagItemId})
    return true, ItemSynthesisInfos, Desc
  end
  ItemSynthesisInfos = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, bagItemId)
  if #ItemSynthesisInfos > 0 then
    Desc = LuaText.skill_stone_tips_2
    return true, ItemSynthesisInfos, Desc
  end
  Desc = LuaText.skill_stone_tips_3
  table.insert(ItemSynthesisInfos, {id = bagItemId})
  return false, ItemSynthesisInfos, Desc
end

function UMG_SkillLearning_C:CheckCanLockByCostBagItems(bagItemIds)
  local Desc
  local ItemSynthesisInfo = {}
  for i, bagItemId in ipairs(bagItemIds) do
    local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
    if bagItem and bagItem.num > 0 then
      if self.petData then
        local newSkillConf = _G.DataConfigManager:GetSkillConf(self.data.skillId)
        if newSkillConf then
          if self.curPetBloodSkillConf then
            Desc = string.format(LuaText.skill_blood_tips_1, self.petData.name, self.curPetBloodSkillConf.name, newSkillConf.name, self.petData.name, self.data.text)
          else
            Desc = string.format(LuaText.skill_blood_tips_17, self.petData.name, newSkillConf.name, self.petData.name, self.data.text)
          end
        end
      end
      ItemSynthesisInfo.id = bagItemId
      return true, ItemSynthesisInfo, Desc
    end
  end
  for k, bagItemId in ipairs(bagItemIds) do
    local ItemSynthesisInfos = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetItemSynthesisInfo, bagItemId)
    if #ItemSynthesisInfos > 0 then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItemId)
      if bagItemConf then
        Desc = string.format(LuaText.skill_blood_tips_2, bagItemConf.name)
      end
      return true, ItemSynthesisInfos[1], Desc
    end
  end
  local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItemIds[1])
  if bagItemConf then
    Desc = string.format(LuaText.skill_blood_tips_3, bagItemConf.name)
  end
  ItemSynthesisInfo.id = bagItemIds[1]
  return false, ItemSynthesisInfo, Desc
end

function UMG_SkillLearning_C:GetSortGoodsList(costItem)
  local itemList = {}
  local goodsList = costItem.cost_goods_id
  local costType = costItem.cost_goods_type
  local needNum = costItem.cost_goods_num
  for i = 1, #goodsList do
    local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, goodsList[i], costType)
    local itemData = self:CreateItemDosageInfo(goodsList[i], num, needNum, costType)
    table.insert(itemList, itemData)
  end
  itemList = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetSortGoodsList, itemList, costType)
  for i, v in ipairs(itemList) do
    if needNum <= v.itemNum then
      return itemList, i
    end
  end
  return itemList, 1
end

function UMG_SkillLearning_C:CreateItemDosageInfo(bagItemId, itemNum, useNum, type)
  local dosageInfo = {}
  dosageInfo.itemId = bagItemId
  dosageInfo.itemNum = itemNum
  dosageInfo.needNum = useNum
  dosageInfo.itemType = type or _G.Enum.GoodsType.GT_BAGITEM
  local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bagItemId)
  if bagItem then
    dosageInfo.gid = bagItem.gid
    if not itemNum then
      dosageInfo.itemNum = bagItem.num
    end
  end
  return dosageInfo
end

function UMG_SkillLearning_C:CreateCommonItemIconData(ItemDosageInfo)
  local itemIconData = _G.NRCCommonItemIconData()
  itemIconData.itemType = ItemDosageInfo.itemType or _G.Enum.GoodsType.GT_BAGITEM
  itemIconData.itemId = ItemDosageInfo.itemId
  itemIconData.BagNum = ItemDosageInfo.itemNum
  itemIconData.itemNum = ItemDosageInfo.needNum
  itemIconData.bShowNum = true
  itemIconData.bShowTip = false
  return itemIconData
end

function UMG_SkillLearning_C:DeepCopyCostItem(source)
  if not source then
    return {}
  end
  local result = {}
  for i, costItem in ipairs(source) do
    local copiedItem = {
      cost_goods_type = costItem.cost_goods_type,
      cost_goods_num = costItem.cost_goods_num
    }
    if costItem.cost_goods_id and #costItem.cost_goods_id > 0 then
      copiedItem.cost_goods_id = {}
      for j, goodsId in ipairs(costItem.cost_goods_id) do
        copiedItem.cost_goods_id[j] = goodsId
      end
    else
      copiedItem.cost_goods_id = nil
    end
    table.insert(result, copiedItem)
  end
  return result
end

function UMG_SkillLearning_C:GetCurUnLockSkillAutoEquipPos()
  if self.petData then
    local curEquippedBloodSkillId
    if self.data.type == Enum.PetNewSkillSrc.PNSS_PET_BLOOD and self.curPetBloodSkillConf then
      curEquippedBloodSkillId = self.curPetBloodSkillConf.id
    end
    local posToIdDic, _ = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetEquipSkillMap, self.petData.gid)
    if posToIdDic then
      if curEquippedBloodSkillId then
        for pos, id in pairs(posToIdDic) do
          if curEquippedBloodSkillId == id then
            return pos
          end
        end
      end
      for pos = 1, 4 do
        if nil == posToIdDic[pos] then
          return pos
        end
      end
    end
  end
  return 0
end

function UMG_SkillLearning_C:IsAutoEquipSkill()
  return self.unLockSkillAutoEquipPos > 0 and self.unLockSkillAutoEquipPos < 5
end

function UMG_SkillLearning_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    if 1 == self.skipCloseCallBackType then
      self.skipCloseCallBackType = nil
      _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.UpdateMaterialItems, self.synthesisList[self.curSynthesisIndex].exchangeId, 1)
      _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.OpenAlternateMaterial, true)
    elseif 2 == self.skipCloseCallBackType then
      self.skipCloseCallBackType = nil
      _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.OpenAlternativeFormula, self.synthesisList, self.curSynthesisIndex - 1)
    elseif 3 == self.skipCloseCallBackType then
      self.skipCloseCallBackType = nil
      self.DelayId = _G.DelayManager:DelaySeconds(0.1, function()
        self:RefreshTitleAndDesc()
        self:RefreshLockSuccessShow()
        self:LoadAnimation(0)
        self:PlayAnimation(self.Study_In)
      end)
    elseif 4 == self.skipCloseCallBackType then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenSkillOperationPanel, self.petData.gid, PetUIModuleEnum.PetSkillOperationType.Replacement, self.data.skillId)
      self:DoClose()
    else
      self:DoClose()
    end
  elseif Anim == self:GetAnimByIndex(0) then
    self.PopUp4.Btn_Right:SetIsEnabled(true)
  end
end

function UMG_SkillLearning_C:GetAlternateMaterial()
  local costItems = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetCostMaterialItems, self.synthesisList[self.curSynthesisIndex].exchangeId, 1)
  for i, v in ipairs(costItems) do
    if v.bAlternate then
      local num = _G.NRCModuleManager:DoCmd(_G.AlchemyModuleCmd.GetMaterialNum, v.goods_id, v.goods_type)
      return self:CreateItemDosageInfo(v.goods_id, num, v.goods_num, v.goods_type)
    end
  end
  return nil
end

return UMG_SkillLearning_C
