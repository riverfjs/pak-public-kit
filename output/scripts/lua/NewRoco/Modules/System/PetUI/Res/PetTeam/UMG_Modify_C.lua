local AlchemyUtils = require("NewRoco.Modules.System.Alchemy.AlchemyUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_Modify_C = _G.NRCPanelBase:Extend("UMG_Modify_C")

function UMG_Modify_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
end

function UMG_Modify_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClosePanel
  CommonPopUpData.Btn_RightHandler = self.OnOK
  CommonPopUpData.ClosePanelHandler = self.OnClosePanel
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_Modify_C:OnActive(openType, ChangeType, NeedHideType, gid)
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
  self.NeedHideType = NeedHideType
  self.ChangeType = ChangeType
  self.openType = openType
  self.CurSelectNatureEffects = {}
  if openType == PetUIModuleEnum.PetTeamShareReviseType.Talent then
    self.NRCText:SetText(LuaText.lineup_code_change_individual)
    self:SetCommonPopUpInfo(self.PopUp2, LuaText.lineup_code_change_individual)
    self:SetChangeTalentInfo(ChangeType, openType)
  end
  if openType == PetUIModuleEnum.PetTeamShareReviseType.Nature then
    self.NRCText:SetText(LuaText.lineup_code_change_nature)
    self:SetCommonPopUpInfo(self.PopUp2, LuaText.lineup_code_change_nature)
    self:SetChangeNatureInfo(ChangeType, openType)
  end
  if openType == PetUIModuleEnum.PetTeamShareReviseType.Blood then
    self.NRCText:SetText(LuaText.lineup_code_change_blood)
    self:SetCommonPopUpInfo(self.PopUp2, LuaText.lineup_code_change_blood)
    self.BloodItem = ChangeType
    self:SetChangeBloodInfo()
  end
  self:LoadAnimation(0)
end

function UMG_Modify_C:SetChangeNatureInfo(ChangeType, openType)
  local changeNatureList = {}
  local share_pos_effect = ChangeType.share_pos_effect
  local share_neg_effect = ChangeType.share_neg_effect
  local pos_effect = ChangeType.pos_effect
  local neg_effect = ChangeType.neg_effect
  local natureName = ChangeType.natureName
  local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100421)
  local IsNagEnough = false
  local NagItemSynthesisInfoList = {}
  local AllItemSynthesisInfoList = {}
  if BagItem and BagItem.num >= 1 then
    IsNagEnough = true
  else
    NagItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100421)
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(NagItemSynthesisInfoList[1] and NagItemSynthesisInfoList[1].exchangeId)
    local exchangeLimitId = exchangeConf and exchangeConf.exchange_time_limit_group
    if exchangeLimitId and 0 ~= exchangeLimitId then
      local exchangeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(exchangeLimitId)
      if exchangeLimitConf then
        local exchangeGroupInfoTable = self.module.exchangeGroupInfoTable or {}
        local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(exchangeLimitId, exchangeGroupInfoTable)
        if remainExchangeTimes then
          NagItemSynthesisInfoList[1].remainExchangeTimes = remainExchangeTimes
        end
      end
    end
  end
  local BagItem1 = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
  local IsAllEnough = false
  if BagItem1 and BagItem1.num >= 1 then
    IsAllEnough = true
  else
    AllItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100420)
  end
  if share_neg_effect ~= neg_effect then
    if share_neg_effect ~= pos_effect then
      table.insert(changeNatureList, {
        Panel = self,
        openType = openType,
        text = LuaText.lineup_code_change_nature_tips2,
        UseType = 1,
        natureName = natureName,
        share_neg_effect = share_neg_effect,
        neg_effect = neg_effect,
        share_pos_effect = pos_effect,
        pos_effect = pos_effect,
        ItemSynthesisInfoList = NagItemSynthesisInfoList,
        Items = {
          {
            itemId = 100421,
            num = 1,
            IsEnough = IsNagEnough
          }
        }
      })
    end
    if pos_effect ~= share_pos_effect then
      table.insert(changeNatureList, {
        Panel = self,
        openType = openType,
        text = LuaText.lineup_code_change_nature_tips3,
        UseType = 3,
        natureName = natureName,
        share_neg_effect = share_neg_effect,
        neg_effect = neg_effect,
        share_pos_effect = share_pos_effect,
        pos_effect = pos_effect,
        ItemSynthesisInfoList = AllItemSynthesisInfoList,
        Items = {
          {
            itemId = 100420,
            num = 1,
            IsEnough = IsAllEnough
          }
        }
      })
    end
  elseif pos_effect ~= share_pos_effect then
    table.insert(changeNatureList, {
      Panel = self,
      openType = openType,
      text = LuaText.lineup_code_change_nature_tips1,
      UseType = 2,
      natureName = natureName,
      share_pos_effect = share_pos_effect,
      pos_effect = pos_effect,
      share_neg_effect = neg_effect,
      neg_effect = neg_effect,
      ItemSynthesisInfoList = AllItemSynthesisInfoList,
      Items = {
        {
          itemId = 100420,
          num = 1,
          IsEnough = IsAllEnough
        }
      }
    })
  end
  table.insert(changeNatureList, {
    Panel = self,
    openType = openType,
    IsEmpty = true
  })
  self.ListView:InitList(changeNatureList)
  self.ListView:SelectItemByIndex(0)
end

function UMG_Modify_C:OnClosePanel()
  self:LoadAnimation(2)
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_Modify_C:OnClosePanel")
end

function UMG_Modify_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Modify_C:GetChangeAttrReqEnum(attribute)
  if not attribute then
    return nil
  end
  if attribute == Enum.AttributeType.AT_HPMAX_PERCENT then
    return Enum.AttributeType.AT_HPMAX
  elseif attribute == Enum.AttributeType.AT_PHYATK_PERCENT then
    return Enum.AttributeType.AT_PHYATK
  elseif attribute == Enum.AttributeType.AT_SPEATK_PERCENT then
    return Enum.AttributeType.AT_SPEATK
  elseif attribute == Enum.AttributeType.AT_PHYDEF_PERCENT then
    return Enum.AttributeType.AT_PHYDEF
  elseif attribute == Enum.AttributeType.AT_SPEDEF_PERCENT then
    return Enum.AttributeType.AT_SPEDEF
  elseif attribute == Enum.AttributeType.AT_SPEED_PERCENT then
    return Enum.AttributeType.AT_SPEED
  end
end

function UMG_Modify_C:OnChangeApply()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.openType == PetUIModuleEnum.PetTeamShareReviseType.Talent then
    local Param = {}
    local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100422)
    if BagItem and BagItem.num > 0 then
      local changeType = self:GetChangeAttrReqEnum(self.ChangeType)
      local attribute = self:GetChangeAttrReqEnum(self.CurSelectAttribute)
      Param.gid = BagItem.gid
      Param.id = BagItem.id
      Param.num = 1
      Param.para = self.petData.gid
      Param.change_attr_type = nil
      Param.target_type = nil
      Param.change_talent_type = attribute
      Param.result_type = changeType
      Param.para2 = nil
      Param.RspParam = {
        ItemConfId = BagItem.id,
        gid = self.petData.gid,
        changeType = changeType
      }
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, Param)
    else
      local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100422)
      if ItemSynthesisInfoList and ItemSynthesisInfoList[1] then
        local exchangeInfoList = {}
        local itemIdList = {}
        for _, NeedItem in pairs(ItemSynthesisInfoList[1].cost_item) do
          local goods = {}
          goods.goods_id = NeedItem.cost_goods_id[1]
          goods.goods_num = NeedItem.cost_goods_num
          goods.goods_type = NeedItem.cost_goods_type
          table.insert(itemIdList, 1, goods)
        end
        local exchangeInfo = {}
        exchangeInfo.id = ItemSynthesisInfoList[1].exchangeId
        exchangeInfo.num = 1
        exchangeInfo.cost_goods = itemIdList
        table.insert(exchangeInfoList, exchangeInfo)
        local changeType = self:GetChangeAttrReqEnum(self.ChangeType)
        local attribute = self:GetChangeAttrReqEnum(self.CurSelectAttribute)
        local useItemList = {}
        local UseItemInfo = {}
        UseItemInfo.gid = 0
        UseItemInfo.id = 100422
        UseItemInfo.num = 1
        UseItemInfo.para = self.petData.gid
        UseItemInfo.change_talent_type = attribute
        UseItemInfo.result_type = changeType
        UseItemInfo.para2 = nil
        UseItemInfo.RspParam = {
          ItemConfId = 100422,
          gid = self.petData.gid,
          changeType = changeType
        }
        table.insert(useItemList, UseItemInfo)
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, exchangeInfoList, useItemList)
      end
    end
  elseif self.openType == PetUIModuleEnum.PetTeamShareReviseType.Nature then
    local PosNature = self:GetChangeAttrReqEnum(self.CurSelectNatureEffects.share_pos_effect)
    local NegNature = self:GetChangeAttrReqEnum(self.CurSelectNatureEffects.share_neg_effect)
    local change_attr_type = {}
    local target_type = {}
    local Param = {}
    if 1 == self.CurSelectNatureEffects.UseType then
      local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100421)
      if BagItem and BagItem.num > 0 then
        change_attr_type = {2}
        target_type = {NegNature}
        Param.gid = BagItem.gid
        Param.id = BagItem.id
        Param.num = 1
        Param.para = self.petData.gid
        Param.change_attr_type = change_attr_type
        Param.target_type = target_type
        Param.RspParam = {
          ItemConfId = BagItem.id,
          gid = self.petData.gid
        }
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, Param)
      else
        local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100421)
        if ItemSynthesisInfoList and ItemSynthesisInfoList[1] then
          local exchangeInfoList = {}
          local itemIdList = {}
          for _, NeedItem in pairs(ItemSynthesisInfoList[1].cost_item) do
            local goods = {}
            goods.goods_id = NeedItem.cost_goods_id[1]
            goods.goods_num = NeedItem.cost_goods_num
            goods.goods_type = NeedItem.cost_goods_type
            table.insert(itemIdList, 1, goods)
          end
          change_attr_type = {2}
          target_type = {NegNature}
          local exchangeInfo = {}
          exchangeInfo.id = ItemSynthesisInfoList[1].exchangeId
          exchangeInfo.num = 1
          exchangeInfo.cost_goods = itemIdList
          table.insert(exchangeInfoList, exchangeInfo)
          local useItemList = {}
          local UseItemInfo = {}
          UseItemInfo.gid = 0
          UseItemInfo.id = 100421
          UseItemInfo.num = 1
          UseItemInfo.para = self.petData.gid
          UseItemInfo.change_attr_type = change_attr_type
          UseItemInfo.target_type = target_type
          UseItemInfo.RspParam = {
            ItemConfId = 100421,
            gid = self.petData.gid
          }
          table.insert(useItemList, UseItemInfo)
          _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, exchangeInfoList, useItemList)
        end
      end
    elseif 2 == self.CurSelectNatureEffects.UseType then
      local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
      if BagItem and BagItem.num > 0 then
        change_attr_type = {1}
        target_type = {PosNature}
        Param.gid = BagItem.gid
        Param.id = BagItem.id
        Param.num = 1
        Param.para = self.petData.gid
        Param.change_attr_type = change_attr_type
        Param.target_type = target_type
        Param.RspParam = {
          ItemConfId = BagItem.id,
          gid = self.petData.gid
        }
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, Param)
      end
    elseif 3 == self.CurSelectNatureEffects.UseType then
      local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
      if BagItem and BagItem.num > 0 then
        change_attr_type = {1, 2}
        target_type = {PosNature, NegNature}
        Param.gid = BagItem.gid
        Param.id = BagItem.id
        Param.num = 1
        Param.para = self.petData.gid
        Param.change_attr_type = change_attr_type
        Param.target_type = target_type
        Param.RspParam = {
          ItemConfId = BagItem.id,
          gid = self.petData.gid
        }
        _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.UseBagItemExistParam, Param)
      end
    end
  elseif self.openType == PetUIModuleEnum.PetTeamShareReviseType.Blood then
    local petGid = self.bloodUIDataList[self.selectBloodIndex].petGid
    if self.selectBloodIndex then
      if self.bloodUIDataList[self.selectBloodIndex].exchangeID then
        local exchangeInfoList = {}
        local itemIdList = {}
        for _, NeedItem in pairs(self.bloodUIDataList[self.selectBloodIndex].NeedItemList) do
          local goods = {}
          goods.goods_id = NeedItem.itemId
          goods.goods_num = NeedItem.needNum
          goods.goods_type = ProtoEnum.GoodsType.GT_BAGITEM
          table.insert(itemIdList, 1, goods)
        end
        local exchangeInfo = {}
        exchangeInfo.id = self.bloodUIDataList[self.selectBloodIndex].exchangeID
        exchangeInfo.num = 1
        exchangeInfo.cost_goods = itemIdList
        table.insert(exchangeInfoList, exchangeInfo)
        local useItemList = {}
        local UseItemInfo = {}
        UseItemInfo.gid = 0
        UseItemInfo.item_conf_id = self.bloodUIDataList[self.selectBloodIndex].BloodItemID
        UseItemInfo.num = 1
        UseItemInfo.para = self.bloodUIDataList[self.selectBloodIndex].petGid
        table.insert(useItemList, UseItemInfo)
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, exchangeInfoList, useItemList, {
          ItemConfId = self.bloodUIDataList[self.selectBloodIndex].BloodItemID,
          gid = self.bloodUIDataList[self.selectBloodIndex].petGid
        })
      elseif self.bloodUIDataList[self.selectBloodIndex].NeedItemList then
        local useItemList = {}
        local UseItemInfo = {}
        local bloodItemID = self.bloodUIDataList[self.selectBloodIndex].BloodItemID
        local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, bloodItemID)
        UseItemInfo.gid = 0
        UseItemInfo.item_conf_id = bloodItemID
        if not bagItem then
          local wannengBagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 102022)
          if wannengBagItem then
            UseItemInfo.gid = wannengBagItem.gid
            UseItemInfo.item_conf_id = 102022
          end
        end
        UseItemInfo.num = 1
        UseItemInfo.para = self.bloodUIDataList[self.selectBloodIndex].petGid
        UseItemInfo.para2 = self.bloodUIDataList[self.selectBloodIndex].tarBloodID
        table.insert(useItemList, UseItemInfo)
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PetTeamShareQuickAdjust, nil, useItemList, {
          ItemConfId = self.bloodUIDataList[self.selectBloodIndex].BloodItemID,
          gid = self.bloodUIDataList[self.selectBloodIndex].petGid
        })
      end
    end
  end
  self:LoadAnimation(2)
end

function UMG_Modify_C:OnOK()
  if self.openType == PetUIModuleEnum.PetTeamShareReviseType.Talent then
    if self.IsIgnore then
      self:DispatchEvent(PetUIModuleEvent.SetIgnoreType, PetUIModuleEnum.PetTeamShareReviseType.Talent, self.petData.gid, self.ChangeType)
      self:LoadAnimation(2)
    else
      local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100422)
      if BagItem and BagItem.num > 0 then
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
        local changeType = self:GetChangeAttrReqEnum(self.ChangeType)
        local attribute_name = _G.DataConfigManager:GetAttributeConf(changeType).attribute_name
        local text = string.format(LuaText.lineup_code_change_nature_tips5, bagItemConf.name, self.petData.name, attribute_name)
        self:OpenDialogPanel(text)
      else
        local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100422)
        if ItemSynthesisInfoList and ItemSynthesisInfoList[1] then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(100422)
          local changeType = self:GetChangeAttrReqEnum(self.ChangeType)
          local attribute_name = _G.DataConfigManager:GetAttributeConf(changeType).attribute_name
          local text = string.format(LuaText.lineup_code_change_nature_tips5, bagItemConf.name, self.petData.name, attribute_name)
          local LineupShareAlchemyParam = self:GetLineupShareAlchemyParam_AlchemyData(ItemSynthesisInfoList[1], text)
          _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLineupShareAlchemy, LineupShareAlchemyParam)
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1028)
        end
      end
    end
  elseif self.openType == PetUIModuleEnum.PetTeamShareReviseType.Nature then
    if self.IsIgnore then
      self:DispatchEvent(PetUIModuleEvent.SetIgnoreType, PetUIModuleEnum.PetTeamShareReviseType.Nature, self.petData.gid)
      self:LoadAnimation(2)
    else
      local PosNature = self:GetChangeAttrReqEnum(self.CurSelectNatureEffects.share_pos_effect)
      local NegNature = self:GetChangeAttrReqEnum(self.CurSelectNatureEffects.share_neg_effect)
      local change_attr_type = {}
      local target_type = {}
      if 1 == self.CurSelectNatureEffects.UseType then
        local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100421)
        if BagItem and BagItem.num > 0 then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
          local attribute_name = _G.DataConfigManager:GetAttributeConf(NegNature).attribute_name
          local text = string.format(LuaText.lineup_code_change_nature_tips6, bagItemConf.name, self.petData.name, attribute_name)
          self:OpenDialogPanel(text)
        else
          local ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100421)
          if ItemSynthesisInfoList and ItemSynthesisInfoList[1] then
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(100421)
            local attribute_name = _G.DataConfigManager:GetAttributeConf(NegNature).attribute_name
            local text = string.format(LuaText.lineup_code_change_nature_tips6, bagItemConf.name, self.petData.name, attribute_name)
            local LineupShareAlchemyParam = self:GetLineupShareAlchemyParam_AlchemyData(ItemSynthesisInfoList[1], text)
            _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLineupShareAlchemy, LineupShareAlchemyParam)
          else
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1028)
          end
        end
      elseif 2 == self.CurSelectNatureEffects.UseType then
        local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
        if BagItem and BagItem.num > 0 then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
          local attribute_name = _G.DataConfigManager:GetAttributeConf(PosNature).attribute_name
          local text = string.format(LuaText.lineup_code_change_nature_tips7, bagItemConf.name, self.petData.name, attribute_name)
          self:OpenDialogPanel(text)
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1028)
        end
      elseif 3 == self.CurSelectNatureEffects.UseType then
        local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100420)
        if BagItem and BagItem.num > 0 then
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
          local attribute_name = _G.DataConfigManager:GetAttributeConf(NegNature).attribute_name
          local attribute_name1 = _G.DataConfigManager:GetAttributeConf(PosNature).attribute_name
          local text = string.format(LuaText.lineup_code_change_nature_tips8, bagItemConf.name, self.petData.name, attribute_name, attribute_name1)
          self:OpenDialogPanel(text)
        else
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1028)
        end
      end
    end
  elseif self.openType == PetUIModuleEnum.PetTeamShareReviseType.Blood then
    local petGid = self.bloodUIDataList[self.selectBloodIndex].petGid
    if self.selectBloodIndex then
      if self.bloodUIDataList[self.selectBloodIndex].IsEmpty then
        self:DispatchEvent(PetUIModuleEvent.SetIgnoreType, PetUIModuleEnum.PetTeamShareReviseType.Blood, petGid)
        NRCEventCenter:DispatchEvent(PetUIModuleEvent.IgnoreBloodDiff, petGid)
        self:OnClose()
      elseif self.bloodUIDataList[self.selectBloodIndex].exchangeID then
        local itemIdList = {}
        local bagItemName = ""
        for i, item in ipairs(self.bloodUIDataList[self.selectBloodIndex].NeedItemList) do
          table.insert(itemIdList, item.itemId)
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(item.itemId)
          bagItemName = string.format("%s%s", bagItemName, bagItemConf.name)
          if i ~= #self.bloodUIDataList[self.selectBloodIndex].NeedItemList then
            bagItemName = bagItemName .. "\227\128\129"
          end
        end
        local text = string.format(LuaText.lineup_code_change_nature_tips4, bagItemName)
        local LineupShareAlchemyParam = self:GetLineupShareAlchemyParam(self.bloodUIDataList[self.selectBloodIndex], text)
        _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenLineupShareAlchemy, LineupShareAlchemyParam)
      elseif self.bloodUIDataList[self.selectBloodIndex].NeedItemList then
        for _, item in pairs(self.bloodUIDataList[self.selectBloodIndex].NeedItemList) do
          local bagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, item.itemId)
          if bagItem and bagItem.num >= item.needNum then
            local bagItemConf = _G.DataConfigManager:GetBagItemConf(bagItem.id)
            local text = string.format(LuaText.lineup_code_change_nature_tips4, bagItemConf.name)
            self:OpenDialogPanel(text)
          else
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_1028)
          end
        end
      end
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_SolveDifferences_C:OnOK")
end

function UMG_Modify_C:GetLineupShareAlchemyParam(UIData, DialogText)
  local LineupShareAlchemyParam = {}
  LineupShareAlchemyParam.exchangeId = UIData.exchangeID
  local Cost_item = {}
  for _, item in pairs(UIData.NeedItemList) do
    local _item = {
      itemId = item.itemId,
      itemNum = item.needNum,
      BagNum = item.itemNum,
      itemType = item.itemType,
      bShowNum = true
    }
    table.insert(Cost_item, _item)
  end
  LineupShareAlchemyParam.Cost_item = Cost_item
  local Get_Item = {}
  Get_Item.itemId = UIData.BloodItemID
  Get_Item.itemNum = 1
  Get_Item.BagNum = 0
  Get_Item.itemType = 1
  Get_Item.bShowNum = true
  LineupShareAlchemyParam.Get_Item = {Get_Item}
  LineupShareAlchemyParam.caller = self
  LineupShareAlchemyParam.callback = self.OnChangeApply
  LineupShareAlchemyParam.DialogText = DialogText
  return LineupShareAlchemyParam
end

function UMG_Modify_C:GetLineupShareAlchemyParam_AlchemyData(UIData, DialogText)
  local LineupShareAlchemyParam = {}
  LineupShareAlchemyParam.exchangeId = UIData.exchangeId
  local Cost_item = {}
  for _, item in pairs(UIData.cost_item) do
    local _item = {}
    _item.itemId = item.cost_goods_id[1]
    _item.BagNum = nil
    _item.itemNum = item.cost_goods_num
    _item.itemType = item.cost_goods_type
    _item.bShowNum = true
    table.insert(Cost_item, _item)
  end
  LineupShareAlchemyParam.Cost_item = Cost_item
  local Get_Item = {}
  Get_Item.itemId = UIData.id
  Get_Item.itemNum = 1
  Get_Item.BagNum = 0
  Get_Item.itemType = 1
  Get_Item.bShowNum = true
  LineupShareAlchemyParam.Get_Item = {Get_Item}
  LineupShareAlchemyParam.caller = self
  LineupShareAlchemyParam.callback = self.OnChangeApply
  LineupShareAlchemyParam.DialogText = DialogText
  return LineupShareAlchemyParam
end

function UMG_Modify_C:OpenDialogPanel(text, callBack)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentText = text
  Context:SetTitle(LuaText.umg_shop_tips_8):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.OnChangeApply):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_shop_tips_9, LuaText.umg_shop_tips_10)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Modify_C:CheckHide(attribute)
  for i, v in ipairs(self.NeedHideType) do
    if v == attribute then
      return true
    end
  end
  return false
end

function UMG_Modify_C:SetChangeTalentInfo(ChangeType, openType)
  local changeTalentList = {}
  local talentNum = 0
  local petData = self.petData
  local petlevel = PetUtils.GetBreakThroughStarsList(self.petData)
  local LevelNum = 0
  if petlevel then
    for i = 1, #petlevel do
      if 1 == petlevel[i].IsShow then
        LevelNum = LevelNum + 1
      end
    end
  else
    Log.Error("UMG_Modify_C petlevel is nil")
  end
  local BagItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, 100422)
  local IsEnough = false
  local ItemSynthesisInfoList = {}
  if BagItem and BagItem.num >= 1 then
    IsEnough = true
  else
    ItemSynthesisInfoList = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetLineupShareAlchemyByItemId, 100422)
    local exchangeConf = _G.DataConfigManager:GetExchangeConf(ItemSynthesisInfoList[1] and ItemSynthesisInfoList[1].exchangeId)
    local exchangeLimitId = exchangeConf and exchangeConf.exchange_time_limit_group
    if exchangeLimitId and 0 ~= exchangeLimitId then
      local exchangeLimitConf = _G.DataConfigManager:GetExchangeTimeLimitConf(exchangeLimitId)
      if exchangeLimitConf then
        local exchangeGroupInfoTable = self.module.exchangeGroupInfoTable or {}
        local remainExchangeTimes = AlchemyUtils.GetRemainExchangeTimes(exchangeLimitId, exchangeGroupInfoTable)
        if remainExchangeTimes then
          ItemSynthesisInfoList[1].remainExchangeTimes = remainExchangeTimes
        end
      end
    end
  end
  if petData.attribute_info.attack.talent and petData.attribute_info.attack.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_PHYATK_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.attack.talent,
        attribute = Enum.AttributeType.AT_PHYATK_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  if petData.attribute_info.defense.talent and petData.attribute_info.defense.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_PHYDEF_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.defense.talent,
        attribute = Enum.AttributeType.AT_PHYDEF_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  if petData.attribute_info.hp.talent and petData.attribute_info.hp.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_HPMAX_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.hp.talent,
        attribute = Enum.AttributeType.AT_HPMAX_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  if petData.attribute_info.special_attack.talent and petData.attribute_info.special_attack.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_SPEATK_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.special_attack.talent,
        attribute = Enum.AttributeType.AT_SPEATK_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  if petData.attribute_info.special_defense.talent and petData.attribute_info.special_defense.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_SPEDEF_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.special_defense.talent,
        attribute = Enum.AttributeType.AT_SPEDEF_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  if petData.attribute_info.speed.talent and petData.attribute_info.speed.talent > 0 then
    if self:CheckHide(Enum.AttributeType.AT_SPEED_PERCENT) then
    else
      table.insert(changeTalentList, {
        Panel = self,
        openType = openType,
        num = petData.attribute_info.speed.talent,
        attribute = Enum.AttributeType.AT_SPEED_PERCENT,
        ChangeType = ChangeType,
        ItemSynthesisInfoList = ItemSynthesisInfoList,
        Items = {
          {
            itemId = 100422,
            num = 1,
            IsEnough = IsEnough
          }
        }
      })
    end
    talentNum = talentNum + 1
  end
  local maxTalentIndex = 0
  local maxTalent = 0
  for i, v in ipairs(changeTalentList) do
    if maxTalent < v.num then
      maxTalent = v.num
      maxTalentIndex = i - 1
    end
  end
  local sub = 3 - talentNum
  if sub > 0 then
    table.insert(changeTalentList, {
      Panel = self,
      openType = openType,
      LevelNum = LevelNum,
      attribute = nil,
      ChangeType = ChangeType,
      ItemSynthesisInfoList = ItemSynthesisInfoList,
      Items = {
        {
          itemId = 100422,
          num = 1,
          IsEnough = IsEnough
        }
      }
    })
  end
  table.insert(changeTalentList, {
    Panel = self,
    openType = openType,
    attribute = nil,
    IsEmpty = true,
    ItemId = nil
  })
  self.ListView:InitList(changeTalentList)
  self.ListView:SelectItemByIndex(maxTalentIndex)
end

function UMG_Modify_C:SetCurSelectTalentItem(attribute, IsIgnore)
  if IsIgnore then
    self.IsIgnore = IsIgnore
  else
    self.IsIgnore = false
    self.CurSelectAttribute = attribute
  end
end

function UMG_Modify_C:SetCurSelectNatureItem(NatureEffects, IsIgnore)
  if IsIgnore then
    self.IsIgnore = IsIgnore
  else
    self.IsIgnore = false
    self.CurSelectNatureEffects = NatureEffects
  end
end

function UMG_Modify_C:SetChangeBloodInfo()
  local bloodUIDataList = {}
  local petGid = self.BloodItem.petGid
  if 23 ~= self.BloodItem.tarBloodID and 24 ~= self.BloodItem.tarBloodID then
    self.BloodItem.openType = self.openType
    self.BloodItem.Panel = self
    table.insert(bloodUIDataList, self.BloodItem)
  end
  table.insert(bloodUIDataList, {
    openType = self.openType,
    IsEmpty = true,
    Panel = self,
    petGid = petGid
  })
  self.ListView:InitList(bloodUIDataList)
  self.bloodUIDataList = bloodUIDataList
  self.ListView:SelectItemByIndex(0)
end

function UMG_Modify_C:SelectBloodChangeIndex(index)
  self.selectBloodIndex = index
end

function UMG_Modify_C:OnDeactive()
end

function UMG_Modify_C:OnAddEventListener()
end

return UMG_Modify_C
