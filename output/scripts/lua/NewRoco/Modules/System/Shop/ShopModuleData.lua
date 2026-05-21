local ShopModuleData = _G.NRCData:Extend("ShopModuleData")
local ShopModuleEvent = require("NewRoco.Modules.System.Shop.ShopModuleEvent")

function ShopModuleData:Ctor()
  NRCData.Ctor(self)
  self.ShopList = {}
  self.itemListData = {}
  self.ShopId = 0
  self.monthCardData = nil
  self.clientMonthCardConf = nil
  self.bInShopRechargePanel = false
  self.goodsReturnConfMapping = nil
  self.globalConfigNumToKeyMapping = nil
  self:InitGlobalConfigNumToKeyMapping()
end

local function SortShopList(a, b)
  return a.shopConf[1].tab_id_1 > b.shopConf[1].tab_id_1
end

function ShopModuleData:InitShopList()
  if #self.ShopList > 0 then
    return
  end
  local _list = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MALL_FRAME_CONF):GetAllDatas()
  local shopList = {}
  for i, v in pairs(_list) do
    local shopItem = {}
    if 0 == _list[i].tab_id_2 then
      shopItem = {
        hasTab = false,
        shopConf = {
          _list[i]
        }
      }
      table.insert(shopList, #shopList + 1, shopItem)
    end
    if 1 == _list[i].tab_id_2 then
      shopItem = {
        hasTab = true,
        shopConf = {
          _list[i]
        }
      }
      table.insert(shopList, #shopList + 1, shopItem)
    end
  end
  for i = 1, #shopList do
    if shopList[i].hasTab then
      for j, v in pairs(_list) do
        if _list[j].tab_id_2 > 1 then
          table.insert(shopList[i].shopConf, #shopList[i].shopConf + 1, _list[j])
        end
      end
    end
  end
  table.sort(shopList, SortShopList)
  Log.Dump(shopList, 6, "ShopModuleData:SetShopList")
  self.ShopList = shopList
end

function ShopModuleData:GetShopList()
  if 0 == #self.ShopList then
    self:InitShopList()
  end
  return self.ShopList
end

function ShopModuleData:GetItemListData()
  return self.itemListData
end

function ShopModuleData:SetItemListData(list)
  self.itemListData = list
end

function ShopModuleData:GetShopId()
  return self.ShopId
end

function ShopModuleData:SetShopId(shopid)
  self.ShopId = shopid
end

function ShopModuleData:GetShopSourceReturnFlag()
  return self.SourceReturnFlag
end

function ShopModuleData:SetShopSourceReturnFlag(SourceReturnFlag)
  self.SourceReturnFlag = SourceReturnFlag
end

function ShopModuleData:GetShopSourceReturnFunc()
  return self.SourceReturnFunc
end

function ShopModuleData:SetShopSourceReturnFunc(SourceReturnFunc)
  self.SourceReturnFunc = SourceReturnFunc
end

function ShopModuleData:InitGlobalConfigNumToKeyMapping()
  if self.globalConfigNumToKeyMapping then
    return
  end
  self.globalConfigNumToKeyMapping = {}
  local globalConfigTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG)
  if globalConfigTable then
    local allGlobalConfigs = globalConfigTable:GetAllDatas()
    for _, config in pairs(allGlobalConfigs) do
      if config.num and 0 ~= config.num then
        self.globalConfigNumToKeyMapping[config.num] = config.key
      end
    end
  end
end

function ShopModuleData:GetGlobalConfigKeyByNum(num)
  self:InitGlobalConfigNumToKeyMapping()
  if not num then
    return nil
  end
  return self.globalConfigNumToKeyMapping[num]
end

function ShopModuleData:InitGoodsReturnConfMapping()
  if self.goodsReturnConfMapping then
    return
  end
  self.goodsReturnConfMapping = {}
  local goodsReturnConfTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.GOODS_RETURN_CONF)
  if goodsReturnConfTable then
    local allGoodsReturnConf = goodsReturnConfTable:GetAllDatas()
    for confId, returnConf in pairs(allGoodsReturnConf) do
      local goodsType = returnConf.need_goods_type
      local goodsId = returnConf.need_goods_id
      local gender = returnConf.gender
      if not self.goodsReturnConfMapping[goodsType] then
        self.goodsReturnConfMapping[goodsType] = {}
      end
      if not self.goodsReturnConfMapping[goodsType][goodsId] then
        self.goodsReturnConfMapping[goodsType][goodsId] = {}
      end
      local genderKey = gender or "any"
      self.goodsReturnConfMapping[goodsType][goodsId][genderKey] = returnConf
    end
  end
end

function ShopModuleData:GetGoodsReturnConf(goodsType, goodsId, playerGender)
  self:InitGoodsReturnConfMapping()
  if not self.goodsReturnConfMapping[goodsType] then
    return nil
  end
  if not self.goodsReturnConfMapping[goodsType][goodsId] then
    return nil
  end
  local confByGender = self.goodsReturnConfMapping[goodsType][goodsId]
  if playerGender and confByGender[playerGender] then
    return confByGender[playerGender]
  end
  if confByGender.any then
    return confByGender.any
  end
  if playerGender then
    for _, conf in pairs(confByGender) do
      return conf
    end
  end
  return nil
end

function ShopModuleData:GetGoodsReturnAmount(goodsType, goodsId, playerGender)
  local conf = self:GetGoodsReturnConf(goodsType, goodsId, playerGender)
  return conf and conf.return_num or 0
end

function ShopModuleData:UpdateMonthCardData(_newMonthCardData)
  _newMonthCardData = _newMonthCardData or {}
  local _curMonthCardData = self.monthCardData
  self.monthCardData = _newMonthCardData
  self:DispatchEvent(ShopModuleEvent.RefreshMonthCardData, _newMonthCardData)
  if _curMonthCardData then
    local _curLeftDays = _curMonthCardData.left_days or 0
    local _newLeftDays = _newMonthCardData.left_days or 0
    if _curLeftDays < _newLeftDays then
      local _clientMonthCardConf = self:GetClientMonthCardConf()
      local _rewards = {
        _clientMonthCardConf.buyRewardId
      }
      if _curLeftDays <= 0 then
        table.insert(_rewards, _clientMonthCardConf.dayRewardId)
      end
      local _rewardsList = {}
      for _, _rewardId in ipairs(_rewards) do
        local _rewardConf = _rewardId and 0 ~= _rewardId and _G.DataConfigManager:GetRewardConf(_rewardId)
        if _rewardConf then
          for _, _rewardItem in ipairs(_rewardConf.RewardItem) do
            local _rewardsItemData = {}
            _rewardsItemData.type = _rewardItem.Type
            _rewardsItemData.id = _rewardItem.Id
            _rewardsItemData.num = _rewardItem.Count
            table.insert(_rewardsList, _rewardsItemData)
          end
        end
      end
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, _rewardsList, "")
    end
  end
end

function ShopModuleData:GetMonthCardData()
  return self.monthCardData or {}
end

function ShopModuleData:GetClientMonthCardConf()
  if self.clientMonthCardConf == nil then
    local _clientMonthCardConf = {}
    _clientMonthCardConf.maxSignDay = 0
    _clientMonthCardConf.signDays = {}
    _clientMonthCardConf.signRewards = {}
    _clientMonthCardConf.previewSlot1Id = 0
    _clientMonthCardConf.previewSlot2Ids = {}
    _clientMonthCardConf.StarRatio = 0
    _clientMonthCardConf.Price = 0
    _clientMonthCardConf.GoodsId = 0
    _clientMonthCardConf.ShopId = 0
    local signRewardsConf = _G.DataConfigManager:GetAllByName("MALL_MONTHLY_PASS_REWARD")
    for _, _conf in ipairs(signRewardsConf) do
      if _conf.monthly_pass_reward_type == Enum.MonthlyPassRewardType.MPRT_RIGHT_AWAY_AFTER_BUY then
        _clientMonthCardConf.buyRewardId = _conf.reward_id
      elseif _conf.monthly_pass_reward_type == Enum.MonthlyPassRewardType.MPRT_DAILY_LOGIN then
        _clientMonthCardConf.dayRewardId = _conf.reward_id
      elseif _conf.monthly_pass_reward_type == Enum.MonthlyPassRewardType.MPRT_ACCUMULATE_LOGIN then
      elseif _conf.monthly_pass_reward_type == Enum.MonthlyPassRewardType.MPRT_PREVIEW_REWARD then
      elseif _conf.monthly_pass_reward_type == Enum.MonthlyPassRewardType.MPRT_STAR_RATIO then
        _clientMonthCardConf.StarRatio = math.floor((_conf.param / 10000.0 - 1) * 100)
      end
    end
    local ShopConf = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.MALL_FRAME_CONF)
    local ShopID = 8000
    for _, _Conf in pairs(ShopConf) do
      if _Conf.mall_type and _Conf.mall_type == Enum.MallType.MT_MONTHLY_PASS then
        ShopID = _Conf.shop_id
        break
      end
    end
    local MallGoods = _G.DataConfigManager:GetAllByName("NORMAL_SHOP_CONF")
    if MallGoods then
      for _, v in pairs(MallGoods) do
        if v.shop_id == ShopID and v.enable then
          local goodsSevData = _G.NRCModuleManager:DoCmd(NPCShopUIModuleCmd.OnCmdGetGoodsSeverData, v.shop_id, v.id)
          if goodsSevData then
            _clientMonthCardConf.Price = goodsSevData.real_price.num
            _clientMonthCardConf.GoodsId = goodsSevData.goods_id
          else
            Log.Warning("ShopModuleData:GetClientMonthCardConf goodsSevData is nil")
          end
          _clientMonthCardConf.ShopId = v.shop_id
          break
        end
      end
    end
    table.sort(_clientMonthCardConf.signDays, function(a, b)
      return a < b
    end)
    self.clientMonthCardConf = _clientMonthCardConf
  end
  return self.clientMonthCardConf
end

return ShopModuleData
