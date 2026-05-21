local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BagModuleCmd = require("NewRoco.Modules.System.Bag.BagModuleCmd")
local luaText = require("LuaText")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local UMG_PetLevelUp_C = _G.NRCPanelBase:Extend("UMG_PetLevelUp_C")

function UMG_PetLevelUp_C:Initialize(Initializer)
end

function UMG_PetLevelUp_C:InitializeData()
  self.UseItemNum = 0
  self.UseItemInfo = nil
  self.uiData.useItemExp = 0
  self.uiData.tempUpLevel = 0
  self.uiData.IsCanAddItem = true
  self.SelectIndex = nil
  self.BagItemList = nil
  self.hasFruit = false
  self.IsUpgrade = false
end

function UMG_PetLevelUp_C:OnConstruct()
  self:SetChildViews(self.PopUp3)
  self.uiData = {
    useItemExp = 0,
    lastPetInfo = {},
    IsUseExpSucceed = false,
    IsUpGradeSucceed = false
  }
  self.uiData.Upexp = nil
  self.UseBagItemList = {}
  self.UseItemNum = 0
  self.UseItemInfo = nil
  self.PetbeforeInfo = nil
  self.SelectIndex = nil
  self.BagItemList = nil
  self.hasFruit = false
  self.PlaybackSpeed = 0
  self.OldItemType = nil
  self.IsClearSelectedFruit = false
  self.AddAutomaticallyType = PetUIModuleEnum.AddAutomaticallyType.NuLL
  self.StarFrame = 0
  self.EndFrame = 0.1
  self.DelFrame = 0
  self.DelEntFrame = 0.1
  self.IsAdd = false
  self.IsDelItem = false
  self._pressedAdd = false
  self._pressedDel = false
  self.totalAddLevel = 0
  self.IsUpgrade = false
  _G.UpdateManager:UnRegister(self)
  self.SetBeforeLevel = true
  self:OnAddEventListener()
  self:SetBtn2Info()
  self:SetAutomaticallySwitcher()
end

function UMG_PetLevelUp_C:SetBagItemList(IsUpdatePetInfo)
  local itemList = NRCModeManager:DoCmd(BagModuleCmd.GetCanFeedItem)
  for i, Item in ipairs(itemList) do
    local PetInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(Item, self.uiData.PetData)
    if IsUpdatePetInfo then
      if self.UseBagItemList[Item.itemConf.id] then
        self.UseBagItemList[Item.itemConf.id].PetInfo = PetInfo
        self.UseBagItemList[Item.itemConf.id].Item = Item
      end
    else
      self.UseBagItemList[Item.itemConf.id] = {
        Item = Item,
        UseCount = 0,
        PetInfo = PetInfo,
        Index = i
      }
    end
  end
  self.uiData.petInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(nil, self.uiData.PetData)
end

function UMG_PetLevelUp_C:OnActive(petInfoMain, uiData)
  self:SetCommonPopUpInfo()
  self:setPetInfoMainCtrl(petInfoMain)
  self:updatePetInfo(uiData.petData)
  self:SetBagItemList(false)
  self:UpdatePanelInfo()
  self:BindInputAction()
  self:SetAutomaticallySwitcher()
  self:LoadAnimation(0)
end

function UMG_PetLevelUp_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.Desc = LuaText.umg_petlevelup_22
  CommonPopUpData.ClosePanelHandler = self.ClosePanelInfo
  CommonPopUpData.Btn_LeftHandler = self.ClearSelectedFruit
  CommonPopUpData.Btn_RightHandler = self.OnConFirm
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp3:SetPanelInfo(CommonPopUpData)
end

function UMG_PetLevelUp_C:OnDeactive()
  self:CancelDelay()
  self:StopAllAnimations()
end

function UMG_PetLevelUp_C:OnDestruct()
  self.module:SetPetMainBtnIsEnabled(true)
  table.clear(self.uiData)
  self.uiData = nil
  _G.UpdateManager:UnRegister(self)
end

function UMG_PetLevelUp_C:OnEnable()
end

function UMG_PetLevelUp_C:OnDisable()
end

function UMG_PetLevelUp_C:OnAddEventListener()
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnCancel)
  self:AddButtonListener(self.Btn_plus5, self.AddAutomatically5)
  self:AddButtonListener(self.Btn_plus10, self.AddAutomatically10)
  self:RegisterEvent(self, PetUIModuleEvent.ClearUpGradeUseItemNum, self.OnClearUpGradeUseItemNum)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpSucceed)
  self:RegisterEvent(self, PetUIModuleEvent.IsCloseMask, self.OnIsCloseMask)
  self:RegisterEvent(self, PetUIModuleEvent.SELECT_LEVELUP_ITEM, self.OnSelectLevelUpItem)
end

function UMG_PetLevelUp_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, PetUIModuleEvent.ClearUpGradeUseItemNum, self.OnClearUpGradeUseItemNum)
  self:UnRegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpSucceed)
  self:UnRegisterEvent(self, PetUIModuleEvent.IsCloseMask, self.OnIsCloseMask)
end

function UMG_PetLevelUp_C:OnCancel()
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetLevelUp_C:OnCancel")
end

function UMG_PetLevelUp_C:AddAutomatically5()
  local index = self.NRCSwitcher_79:GetActiveWidgetIndex()
  if 0 == index then
    self:AddAutomatically(self.totalAddLevel + 5)
  end
end

function UMG_PetLevelUp_C:AddAutomatically10()
  local index = self.NRCSwitcher:GetActiveWidgetIndex()
  if 0 == index then
    self:AddAutomatically(self.totalAddLevel + 10)
  end
end

function UMG_PetLevelUp_C:AddAutomatically(upLevel)
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_PetLevelUp_C:OnCancel")
  local petInfo = self.uiData.petInfo
  local curLevel = petInfo.curLevel
  local maxLevel = petInfo.maxLevel
  local petLevelExpList = petInfo.petLevelExpList
  local goalLevel = (curLevel or 0) + math.min(upLevel, maxLevel - (curLevel or 0))
  local goalNeedExp = petLevelExpList[goalLevel - 1].pet_exp
  local curPetExp = petInfo.curPetExp or 0
  local curNeedExp = goalNeedExp - curPetExp - self:GetResidueExp()
  local reversed = {}
  local length = #self.BagItemList
  for i = 1, length do
    local item = self.BagItemList[length - i + 1]
    local UseBagItem = self.UseBagItemList[item.itemConf.id]
    if item.Item and item.Item.num - UseBagItem.UseCount > 0 then
      local index = #reversed + 1
      reversed[index] = item
    end
  end
  local gap1, gap2, gap3 = 9999999
  local doFloor1, dosageInfo, virtualExp1 = self:AutomaticallyHandle(reversed, curNeedExp, 0)
  gap1 = self:GetLevelByExp(curPetExp + virtualExp1) - goalLevel
  if gap1 < 0 and doFloor1 > 0 then
    local doFloor2, dosageInfo2, virtualExp2 = self:AutomaticallyHandle(reversed, curNeedExp, doFloor1)
    gap2 = self:GetLevelByExp(curPetExp + virtualExp2) - goalLevel
    if gap2 < 0 and doFloor2 > 0 then
      local _, dosageInfo3, virtualExp3 = self:AutomaticallyHandle(reversed, curNeedExp, doFloor2)
      gap3 = self:GetLevelByExp(curPetExp + virtualExp3) - goalLevel
      if gap3 >= 0 and gap3 < 1 then
        dosageInfo = dosageInfo3
      else
        local gap = math.min(gap1, gap2, gap3)
        if gap == gap2 then
          dosageInfo = dosageInfo2
        elseif gap == gap3 then
          dosageInfo = dosageInfo3
        end
      end
    elseif gap2 >= 0 and gap2 < 1 or math.abs(gap2) < math.abs(gap1) then
      dosageInfo = dosageInfo2
    end
  end
  for index, num in pairs(dosageInfo) do
    local Item = self.ItemList:GetItemByIndex(index)
    if Item and num > 0 then
      Item:AddAutomatically(true, PetUIModuleEnum.AddAutomaticallyType.Add, num)
    end
  end
  self:SetBtn2Info()
  self:SetAutomaticallySwitcher()
end

function UMG_PetLevelUp_C:AutomaticallyHandle(bagItemList, needExp, lastDoFloorId)
  local dosageInfo = {}
  local CoconutNum = 0
  local FigNum = 0
  local MagicFruitNum = 0
  local virtualExp = 0
  local _lastDoFloorId = 0
  for i, BagItem in pairs(bagItemList) do
    local UseBagItem = self.UseBagItemList[BagItem.itemConf.id]
    local num = 0
    self.IsClearSelectedFruit = true
    local PetMaxNeedExp = needExp - virtualExp
    local id = UseBagItem.Item.itemConf.id
    local limitNum = UseBagItem.Item.Item.num - UseBagItem.UseCount
    if 100211 == id then
      CoconutNum = math.ceil(PetMaxNeedExp / UseBagItem.PetInfo.itemPetExp)
      if limitNum < CoconutNum then
        CoconutNum = limitNum
      end
      num = CoconutNum
    elseif 100212 == id then
      if i ~= #bagItemList and lastDoFloorId < id then
        _lastDoFloorId = id
        FigNum = math.floor(PetMaxNeedExp / UseBagItem.PetInfo.itemPetExp)
      else
        FigNum = math.ceil(PetMaxNeedExp / UseBagItem.PetInfo.itemPetExp)
      end
      if limitNum < FigNum then
        FigNum = limitNum
      end
      num = FigNum
    elseif 100213 == id then
      if i ~= #bagItemList and lastDoFloorId < id then
        _lastDoFloorId = id
        MagicFruitNum = math.floor(PetMaxNeedExp / UseBagItem.PetInfo.itemPetExp)
      else
        MagicFruitNum = math.ceil(PetMaxNeedExp / UseBagItem.PetInfo.itemPetExp)
      end
      if limitNum < MagicFruitNum then
        MagicFruitNum = limitNum
      end
      num = MagicFruitNum
    end
    if UseBagItem and UseBagItem.Index then
      local Item = self.ItemList:GetItemByIndex(UseBagItem.Index - 1)
      if Item and num > 0 then
        dosageInfo[UseBagItem.Index - 1] = num + UseBagItem.UseCount
        virtualExp = virtualExp + num * UseBagItem.PetInfo.itemPetExp
      end
    end
  end
  return _lastDoFloorId, dosageInfo, virtualExp
end

function UMG_PetLevelUp_C:GetLevelByExp(exp)
  local petInfo = self.uiData.petInfo
  if petInfo then
    for level, cfg in pairs(petInfo.petLevelExpList) do
      if exp < cfg.pet_exp then
        local lastCfg = petInfo.petLevelExpList[level - 1]
        if lastCfg then
          local lcLv = (exp - lastCfg.pet_exp) / (cfg.pet_exp - lastCfg.pet_exp)
          return level + lcLv
        end
        return level - 1 + exp / cfg.pet_exp
      end
    end
  end
  return 0
end

function UMG_PetLevelUp_C:ClearSelectedFruit()
  if self.IsClearSelectedFruit then
    for i, BagItem in pairs(self.BagItemList) do
      local Item = self.ItemList:GetItemByIndex(i - 1)
      if Item and Item:GetBagItemCount() > 0 then
        Item:AddAutomatically(false, PetUIModuleEnum.AddAutomaticallyType.Reduce, 0)
      end
    end
    self.IsClearSelectedFruit = false
    self:SetBtn2Info()
    self:SetAutomaticallySwitcher()
  else
    self:LoadAnimation(2)
  end
end

function UMG_PetLevelUp_C:ClosePanelInfo()
  _G.NRCAudioManager:PlaySound2DAuto(41400008, "UMG_PetLevelUp_C:OnCancel")
  self:LoadAnimation(2)
end

function UMG_PetLevelUp_C:GetResidueExp()
  local Exp = 0
  for i, BagItem in pairs(self.UseBagItemList) do
    Exp = Exp + BagItem.UseCount * BagItem.PetInfo.itemPetExp
  end
  return Exp
end

function UMG_PetLevelUp_C:SetBtn2Info()
  if self.IsClearSelectedFruit then
    self.PopUp3:SetBtnLeftText(LuaText.umg_petlevelup_21)
  else
    self.PopUp3:SetBtnLeftText(LuaText.CANCEL)
  end
end

function UMG_PetLevelUp_C:SetAutomaticallySwitcher()
  local petInfo = self.uiData.petInfo
  if not (nil ~= petInfo and petInfo.curLevel) or not petInfo.maxLevel then
    return
  end
  local curLevel = petInfo.curLevel
  local maxLevel = petInfo.maxLevel
  local tempUpLevel = self.uiData.tempUpLevel
  local canAddSelect = false
  for i, BagItem in pairs(self.BagItemList) do
    if BagItem.Item and BagItem.itemConf then
      local UseBagItem = self.UseBagItemList[BagItem.itemConf.id]
      if UseBagItem and UseBagItem.UseCount < BagItem.Item.num then
        canAddSelect = true
        break
      end
    end
  end
  if not self.hasFruit or maxLevel <= curLevel + tempUpLevel or not canAddSelect then
    self.NRCSwitcher_79:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.NRCSwitcher:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.NRCSwitcher_79:SetActiveWidgetIndex(1)
    self.NRCSwitcher:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_79:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCSwitcher_79:SetActiveWidgetIndex(0)
    self.NRCSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_PetLevelUp_C:OnConFirm()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_ADD_PET_EXP, true)
  if isBan then
    return
  end
  if self:IsReachImpose() then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petlevelup_1)
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_PetLevelUp_C:OnCancel")
    return
  end
  local num = 0
  for i, BagItem in pairs(self.UseBagItemList) do
    if BagItem.UseCount then
      num = num + BagItem.UseCount
    end
  end
  if num <= 0 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petlevelup_3)
    _G.NRCAudioManager:PlaySound2DAuto(41401015, "UMG_PetLevelUp_C:OnCancel")
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PetLevelUp_C:OnCancel")
  self:OnBtnUseItemClick()
end

function UMG_PetLevelUp_C:OnClickAddItem(BagItem, AddAutomatically, Count)
  self.UseItemInfo = BagItem
  self.AddAutomaticallyType = AddAutomatically
  if AddAutomatically == PetUIModuleEnum.AddAutomaticallyType.Add then
    self.UseItemNum = Count
  else
    if not self:SetAddBtnState() then
      return
    end
    self.UseItemNum = 0
  end
  self.uiData.petInfo = self.UseBagItemList[BagItem.itemConf.id].PetInfo
  self:OnItemListChangeCount(true, true, self.UseBagItemList[BagItem.itemConf.id].UseCount)
  self:SetUseBagItemCount(BagItem)
  self:AddOrDelItem()
  if self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL then
    self:UpdateBtn2State()
  end
end

function UMG_PetLevelUp_C:OnClickDelItem(BagItem, AddAutomatically, Count)
  self.UseItemInfo = BagItem
  self.AddAutomaticallyType = AddAutomatically
  if AddAutomatically == PetUIModuleEnum.AddAutomaticallyType.Reduce then
    self.UseItemNum = Count
    self.uiData.useItemExp = 0
  else
    if not self:SetDelBtnState() then
      return
    end
    self.UseItemNum = 0
  end
  self.uiData.petInfo = self.UseBagItemList[BagItem.itemConf.id].PetInfo
  self:OnItemListChangeCount(false, true)
  self:SetUseBagItemCount(BagItem)
  self:AddOrDelItem()
  self:UpdateBtn2State()
end

function UMG_PetLevelUp_C:UpdateBtn2State()
  local curSelectCnt = 0
  for i, UseBagItem in pairs(self.UseBagItemList) do
    curSelectCnt = curSelectCnt + UseBagItem.UseCount
  end
  if curSelectCnt > 0 then
    self.IsClearSelectedFruit = true
  else
    self.IsClearSelectedFruit = false
  end
  self:SetBtn2Info()
  self:SetAutomaticallySwitcher()
end

function UMG_PetLevelUp_C:SetUseBagItemCount(BagItem)
  if not self.UseBagItemList then
    return
  end
  if self.UseBagItemList[BagItem.itemConf.id] then
    if self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL then
      self.UseBagItemList[BagItem.itemConf.id].UseCount = self.UseBagItemList[BagItem.itemConf.id].UseCount + self.UseItemNum
    else
      self.UseBagItemList[BagItem.itemConf.id].UseCount = self.UseItemNum
    end
  else
    self.UseBagItemList[BagItem.itemConf.id] = {}
    self.UseBagItemList[BagItem.itemConf.id].Item = BagItem
    if self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL then
      self.UseBagItemList[BagItem.itemConf.id].UseCount = self.UseBagItemList[BagItem.itemConf.id].UseCount + self.UseItemNum
    else
      self.UseBagItemList[BagItem.itemConf.id].UseCount = self.UseItemNum
    end
    self.UseBagItemList[BagItem.itemConf.id].PetInfo = PetUtils.GetPetBaseInfoByUseItemVisualType(BagItem, self.uiData.PetData)
  end
end

function UMG_PetLevelUp_C:AddOrDelItem()
  if self.UseBagItemList then
    for i, UseBagItem in pairs(self.UseBagItemList) do
      if UseBagItem.Item.itemConf.id == self.UseItemInfo.itemConf.id then
        local Item = self.ItemList:GetItemByIndex(UseBagItem.Index - 1)
        if Item then
          Item:AddOrDelItem(UseBagItem.UseCount)
        end
      end
    end
  end
  self:UpdatePropertyList()
end

function UMG_PetLevelUp_C:SetDelBtnState()
  if self.uiData and self.uiData.petInfo then
    local Text
    if self.UseItemInfo.num <= 0 then
      self.IsDelItem = false
      Text = LuaText.umg_petlevelup_5
    elseif self.uiData.petInfo.curLevel >= self.uiData.petInfo.MaxLevelInfo then
      self.IsDelItem = false
      Text = string.format(LuaText.umg_petlevelup_9, self.uiData.petInfo.LevelName)
    elseif self.uiData.petInfo.curLevel >= self.uiData.petInfo.maxLevel then
      self.IsDelItem = false
      Text = LuaText.umg_petlevelup_7
    elseif self.UseBagItemList[self.UseItemInfo.itemConf.id].UseCount <= 0 then
      self.IsDelItem = false
      Text = LuaText.umg_petlevelup_6
    else
      self.IsDelItem = true
    end
    if not self.IsDelItem then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    end
  end
  return self.IsDelItem
end

function UMG_PetLevelUp_C:SetAddBtnState()
  local Text
  if self.UseItemInfo.num <= 0 then
    self.IsAdd = false
    Text = LuaText.umg_petlevelup_5
  elseif self.UseBagItemList[self.UseItemInfo.itemConf.id].UseCount >= self.UseItemInfo.num or not self.uiData.IsCanAddItem then
    self.IsAdd = false
    Text = LuaText.umg_petlevelup_8
  elseif self.uiData.petInfo.curLevel and self.uiData.petInfo.MaxLevelInfo and self.uiData.petInfo.curLevel >= self.uiData.petInfo.MaxLevelInfo then
    self.IsAdd = false
    Text = string.format(LuaText.umg_petlevelup_9, self.uiData.petInfo.LevelName)
  elseif self.uiData.petInfo.curLevel and self.uiData.petInfo.maxLevel and self.uiData.petInfo.curLevel >= self.uiData.petInfo.maxLevel then
    self.IsAdd = false
    Text = LuaText.umg_petlevelup_10
  else
    self.IsAdd = true
  end
  if not self.IsAdd then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
  return self.IsAdd
end

function UMG_PetLevelUp_C:SetMoneyInfo()
  if not self.uiData then
    Log.Error("\230\178\161\230\156\137\229\136\157\229\167\139\230\149\176\230\141\174,\230\159\165\231\156\139\229\160\134\230\160\136")
    return
  end
  local num = self.uiData.petInfo.ItemConsumeGold * self.UseItemNum
  local OwnMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_COIN)
  if num > OwnMoney then
  else
  end
end

function UMG_PetLevelUp_C:IsHasMoney()
  local num = 0
  for i, UseBagItem in pairs(self.UseBagItemList) do
    if UseBagItem.UseCount > 0 then
      num = num + UseBagItem.PetInfo.ItemConsumeGold * UseBagItem.UseCount
    end
  end
  local OwnMoney = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_COIN)
  if num > OwnMoney then
    return false
  else
    return true
  end
end

function UMG_PetLevelUp_C:OnClearUpGradeUseItemNum(_SelectItem, SelectIndex)
end

function UMG_PetLevelUp_C:UseExpSucceedUpdateInfo()
  if self.uiData.IsUseExpSucceed then
    self.SetBeforeLevel = true
    self.UseItemNum = 0
    self.uiData.useItemExp = 0
    self.uiData.tempUpLevel = 0
    self:OnItemListChangeCount(true, false)
  end
end

function UMG_PetLevelUp_C:SetUseActionIcon()
  local BagItemConf = self.UseItemInfo.itemConf
  if BagItemConf.item_behavior then
    for i, item in ipairs(BagItemConf.item_behavior) do
      local UseAction = item.use_action
      if UseAction == Enum.ItemBehavior.IB_GET_VITEM then
        local ratio = item.ratio[1]
      end
    end
  end
end

function UMG_PetLevelUp_C:SetSwitcher_98(_Index)
end

function UMG_PetLevelUp_C:OnUseExpSucceed(_changes)
  self.uiData.IsUseExpSucceed = true
  self:UpdateItemListInfo(_changes)
  self:SetBagItemList(true)
  self:UseExpSucceedUpdateInfo()
  self:SetCurMoney()
end

function UMG_PetLevelUp_C:OnSelectLevelUpItem(Index)
  self.ItemList:SelectItemByIndex(Index - 1)
end

function UMG_PetLevelUp_C:UpdateItemListInfo(_changes)
  if not _changes or not self.BagItemList then
    return
  end
  for i, changItem in ipairs(_changes) do
    if changItem.type == _G.ProtoEnum.GoodsType.GT_BAGITEM then
      self:UpdateItemList(changItem)
    elseif changItem.type == _G.ProtoEnum.GoodsType.GT_PET then
      if self.uiData.PetData.gid == changItem.pet_data.gid then
        self.uiData.PetData = changItem.pet_data
      end
    elseif changItem.type == _G.ProtoEnum.GoodsType.GT_PETEXP then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(changItem.gid)
      if self.uiData.PetData.gid == petData.gid then
        self.uiData.PetData = petData
      end
    end
  end
end

function UMG_PetLevelUp_C:UpdateItemList(changeItemInfo)
  for i, Item in ipairs(self.BagItemList) do
    if changeItemInfo and Item.itemConf.id == changeItemInfo.id then
      local ItemInfo = self.ItemList:GetItemByIndex(i - 1)
      ItemInfo:SetData(changeItemInfo)
      if Item.Item.num > 0 then
        Item.Item.num = changeItemInfo.num
      end
    end
  end
end

function UMG_PetLevelUp_C:OnIsCloseMask(_IsCloseMask)
  if _IsCloseMask then
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Mask:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetLevelUp_C:OnBtnUseItemClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetLevelUp_C:OnBtnUseItemClick")
  self:OnUseItemOk()
end

function UMG_PetLevelUp_C:OnUseItemOk()
  local petInfo = self.uiData.petInfo
  local UseItemList = {}
  if not petInfo then
    return
  end
  if self.UseBagItemList then
    for i, UseBagItem in pairs(self.UseBagItemList) do
      if UseBagItem.UseCount > 0 and UseBagItem.Item and UseBagItem.Item.Item then
        table.insert(UseItemList, {
          gid = UseBagItem.Item.Item.gid,
          num = UseBagItem.UseCount,
          para = petInfo.gid,
          item_conf_id = UseBagItem.Item.Item.id
        })
      end
    end
  end
  self:OnIsCloseMask(false)
  if UseItemList then
    NRCModuleManager:DoCmd(PetUIModuleCmd.UseExpItem, UseItemList)
  else
    Log.Error("UMG_PetLevelUp_C:OnUseItemOk no item used")
  end
  self:DispatchEvent(PetUIModuleEvent.PET_UI_MODEL_PLAY_ANIM, "Happy")
end

function UMG_PetLevelUp_C:UpdatePropertyList()
  if not self.uiData.PetData or not self.uiData.PetData.attribute_info then
    Log.Warning("\232\175\183\230\159\165\231\156\139\228\184\186\228\187\128\228\185\136\230\178\161\230\156\137PetData\230\136\150\232\128\133attribute_info\230\149\176\230\141\174--UMG_PetLevelUp_C:UpdatePropertyList")
    return
  end
  local PetProperty = {
    {},
    {},
    {}
  }
  for i = 1, 6 do
    local attribute = _G.DataConfigManager:GetAttributeConf(i)
    local PetLaterProperty
    local Index = 1
    if 1 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.hp.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_add_level").num) + self.uiData.PetData.attribute_info.hp.talent * (_G.DataConfigManager:GetAttrGlobalConfig("hp_max_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("hp_max_race_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("hp_max_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local HpPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_HPMAX_PERCENT) / 10000
      HpPercentAdd = math.floor(HpPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + HpPercentAdd + math.floor(self.uiData.PetData.attribute_info.hp.effort_add + 0.5)
      Index = 1
    elseif 2 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.attack.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_add_level").num) + self.uiData.PetData.attribute_info.attack.talent * (_G.DataConfigManager:GetAttrGlobalConfig("phy_attack_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("phy_attack_race_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("phy_attack_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local PhyAttackPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_PHYATK_PERCENT) / 10000
      PhyAttackPercentAdd = math.floor(PhyAttackPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + PhyAttackPercentAdd + math.floor(self.uiData.PetData.attribute_info.attack.effort_add + 0.5)
      Index = 1
    elseif 3 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.special_attack.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_add_level").num) + self.uiData.PetData.attribute_info.special_attack.talent * (_G.DataConfigManager:GetAttrGlobalConfig("spe_attack_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("spe_attack_race_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("spe_attack_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local SpeAttackPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_SPEATK_PERCENT) / 10000
      SpeAttackPercentAdd = math.floor(SpeAttackPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + SpeAttackPercentAdd + math.floor(self.uiData.PetData.attribute_info.special_attack.effort_add + 0.5)
      Index = 2
    elseif 4 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.defense.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_add_level").num) + self.uiData.PetData.attribute_info.defense.talent * (_G.DataConfigManager:GetAttrGlobalConfig("phy_defence_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("phy_defence_race_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("phy_defence_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local DefPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_PHYDEF_PERCENT) / 10000
      DefPercentAdd = math.floor(DefPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + DefPercentAdd + math.floor(self.uiData.PetData.attribute_info.defense.effort_add + 0.5)
      Index = 2
    elseif 5 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.special_defense.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_add_level").num) + self.uiData.PetData.attribute_info.special_defense.talent * (_G.DataConfigManager:GetAttrGlobalConfig("spe_defence_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("spe_defence_race_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("spe_defence_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local SpeDefPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_SPEDEF_PERCENT) / 10000
      SpeDefPercentAdd = math.floor(SpeDefPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + SpeDefPercentAdd + math.floor(self.uiData.PetData.attribute_info.special_defense.effort_add + 0.5)
      Index = 3
    elseif 6 == i then
      PetLaterProperty = self.uiData.PetData.attribute_info.speed.total_race * (_G.DataConfigManager:GetAttrGlobalConfig("speed_race_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("speed_talent_add_level").num) + self.uiData.PetData.attribute_info.speed.talent * (_G.DataConfigManager:GetAttrGlobalConfig("speed_talent_constant").num / 10000) * (self.uiData.PetData.level + self.uiData.tempUpLevel + _G.DataConfigManager:GetAttrGlobalConfig("speed_talent_add_level").num) + _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id).hp_max_first + (self.uiData.PetData.level + self.uiData.tempUpLevel) * (_G.DataConfigManager:GetAttrGlobalConfig("speed_level_constant").num / 10000)
      PetLaterProperty = math.floor(PetLaterProperty + 0.5)
      local SpeedPercentAdd = PetLaterProperty * PetUtils.GetPetAdditionalByType(self.uiData.PetData, Enum.AttributeType.AT_SPEED_PERCENT) / 10000
      SpeedPercentAdd = math.floor(SpeedPercentAdd + 0.5)
      PetLaterProperty = PetLaterProperty + SpeedPercentAdd + math.floor(self.uiData.PetData.attribute_info.speed.effort_add + 0.5)
      Index = 3
    end
    table.insert(PetProperty[Index], {
      icon = attribute.attribute_icon,
      attributevalue = attribute.attribute_name,
      petbeforeproperty = PetUtils.GetPetAdditionalByType(self.uiData.PetData, i),
      petlaterproperty = PetLaterProperty,
      tempUpLevel = self.uiData.tempUpLevel
    })
  end
  self.List:InitGridView(PetProperty)
end

function UMG_PetLevelUp_C:OnItemListChangeCount(_isAddItem, _IsAddNum, UseSucceedNum)
  if not self.uiData or not self.uiData.petInfo then
    return
  end
  if not (self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL and _isAddItem) or self.uiData.IsUseExpSucceed or 0 == self.UseItemInfo.num then
  else
    if self.UseBagItemList[self.UseItemInfo.itemConf.id].UseCount >= self.UseItemInfo.num then
      local BagItemConf = self.UseItemInfo.itemConf
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.umg_petlevelup_11, BagItemConf.name))
      return
    else
    end
  end
  local petInfo = self.uiData.petInfo
  local curLevel = petInfo.curLevel
  local maxLevel = petInfo.maxLevel
  local curPetExp = petInfo.curPetExp or 0
  local maxNeedExp = petInfo.maxNeedExp
  local petLevelExpList = petInfo.petLevelExpList
  local itemPetExp = petInfo.itemPetExp or 0
  local curTotalExp = self.uiData.useItemExp or 0
  local changeCount
  if self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL then
    if _IsAddNum then
      changeCount = _isAddItem and 1 or -1
    else
      changeCount = 0
    end
  else
    changeCount = self.UseItemNum - (UseSucceedNum or 0)
  end
  if self.SetBeforeLevel and not self.uiData.IsUseExpSucceed then
    self.SetBeforeLevel = false
    self.beforeInfoLevel = tostring(curLevel)
  end
  self.uiData.IsCanAddItem = true
  curTotalExp = curTotalExp + itemPetExp * changeCount
  Log.Debug("----------OnItemListChangeCount[itemid, itemExp, curPetExp, maxNeedExp]:", itemPetExp, curPetExp, maxNeedExp, curTotalExp, curTotalExp + curPetExp)
  if not (curTotalExp and curPetExp and maxNeedExp and maxNeedExp <= curTotalExp + curPetExp) or curTotalExp <= 0 then
  else
    self.uiData.IsCanAddItem = false
  end
  local upLevel = 0
  local tempExp = curTotalExp + curPetExp
  for level = curLevel, maxLevel - 1 do
    local petLevelConf = petLevelExpList[level]
    local petExp
    petExp = petLevelConf.pet_exp
    if tempExp < petExp then
      break
    end
    upLevel = upLevel + 1
  end
  if _isAddItem then
    self:PlayAnimation(self.ExpAdd)
  end
  self.uiData.Upexp = upLevel
  Log.Debug("----------OnItemListChangeCount[upLevel, curTotalExp]:", upLevel)
  self.uiData.tempUpLevel = upLevel
  self.uiData.useItemExp = curTotalExp
  if self.AddAutomaticallyType == PetUIModuleEnum.AddAutomaticallyType.NuLL then
    if self.UseItemInfo.num > 0 then
      self.UseItemNum = self.UseItemNum + changeCount
    else
      self.uiData.useItemExp = 0
    end
  end
  self:updatePetLevelAndExp(_isAddItem, _IsAddNum)
end

function UMG_PetLevelUp_C:updatePetLevelAndExp(isAddItem, _IsAddNum)
  local petData = self.uiData.PetData
  local lastPetInfo = self.uiData.lastPetInfo
  if petData then
    local IsReachImpose = self:IsReachImpose()
    local maxPetLevel = self.uiData.petInfo.maxLevel
    local petTempUpExp = self.uiData.useItemExp or 0
    if IsReachImpose then
      petTempUpExp = 0
    end
    local petTempUpLevel = self.uiData.tempUpLevel or 0
    local curLevel = self.uiData.petInfo.curLevel
    local maxExp, curExp = self:GetMaxAndCurExp()
    local expInfo, levelInfo
    self.totalAddLevel = 0
    if petTempUpExp > 0 then
      self.Text_PetQuantity_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      expInfo = string.format("(+%s)", petTempUpExp)
      self.Text_PetQuantity_1:SetText(expInfo)
      if petTempUpLevel > 0 then
        self.totalAddLevel = petTempUpLevel
        self.Text_PetClass_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        levelInfo = string.format("(+%s)", petTempUpLevel)
        self.Text_PetClass_1:SetText(levelInfo)
      else
        self.Text_PetClass_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.Text_PetQuantity_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Text_PetClass_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    expInfo = string.format("/%d", maxExp)
    self.Text_PetQuantity:SetText(curExp)
    self.Text_PetQuantity_2:SetText(expInfo)
    levelInfo = string.format("%s%s", self.uiData.petInfo.LevelName, curLevel)
    self.Text_PetClass:SetText(levelInfo)
    local expPercent = curExp / maxExp
    lastPetInfo.isContinueExpEffect = false
    if self:IsAnimationPlaying(self.Exp_ADD) then
      self:StopAnimation(self.Exp_ADD)
    end
    if lastPetInfo.gid == petData.gid and self.uiData.IsUseExpSucceed then
      self.uiData.IsUseExpSucceed = false
      self.uiData.IsUpGradeSucceed = false
      self:playPetExpAnimation(self.uiData.petInfo.curLevel, expPercent)
    elseif IsReachImpose then
      self:StopAllAnimations()
      self.progressPetExp:SetPercent(expPercent)
    else
      self.progressPetExp:SetPercent(expPercent)
    end
    self:PlayPetPreViewExp(petTempUpExp, curExp, maxExp, expPercent, _IsAddNum)
    lastPetInfo.gid = petData.gid
    lastPetInfo.level = curLevel
    lastPetInfo.expPercent = expPercent
    lastPetInfo.exp = curExp
  else
    lastPetInfo.gid = 0
  end
end

function UMG_PetLevelUp_C:PlayPetPreViewExp(petTempUpExp, curExp, maxExp, expPercent, _IsAddNum)
  if not _IsAddNum and petTempUpExp <= 0 then
    self:StopGreenAnim()
    self.progressPetExp:SetIncreasePercent(0)
    return
  end
  local CurPercent = self.progressPetExp.IncreasePercent
  local curTempExp = petTempUpExp + curExp
  self.expTempPercent = curTempExp / maxExp - expPercent
  if self.expTempPercent > 1 then
    self.expTempPercent = 1
  end
  _G.UpdateManager:Register(self)
end

function UMG_PetLevelUp_C:OnTick(InDeltaTime)
  local lodPercent = self.progressPetExp.IncreasePercent
  if lodPercent ~= self.expTempPercent then
    local AllPercent
    if lodPercent > self.expTempPercent then
      AllPercent = lodPercent - InDeltaTime * 2
      if AllPercent <= self.expTempPercent then
        AllPercent = self.expTempPercent
        _G.UpdateManager:UnRegister(self)
      end
    else
      AllPercent = lodPercent + InDeltaTime * 2
      if AllPercent >= self.expTempPercent then
        AllPercent = self.expTempPercent
        _G.UpdateManager:UnRegister(self)
      end
    end
    self.progressPetExp:SetIncreasePercent(AllPercent)
  end
end

function UMG_PetLevelUp_C:StopGreenAnim()
  if self:IsAnimationPlaying(self.Exp_Add_Green) then
    self:StopAnimation(self.Exp_Add_Green)
  end
  if self:IsAnimationPlaying(self.Exp_Reduce_Green) then
    self:StopAnimation(self.Exp_Reduce_Green)
  end
end

function UMG_PetLevelUp_C:GetAnimStarAndEndTime(Anim, StarPercent, EndPercent)
  local ani = Anim
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime() + aniTime * StarPercent
  local endTime = ani:GetStartTime() + aniTime * EndPercent
  return beginTime, endTime
end

function UMG_PetLevelUp_C:GetReduceAnimStarAndEndTime(Anim, StarPercent, EndPercent)
  local ani = Anim
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = aniTime - (ani:GetStartTime() + aniTime * StarPercent)
  local endTime = aniTime - (ani:GetStartTime() + aniTime * EndPercent)
  return beginTime, endTime
end

function UMG_PetLevelUp_C:playPetExpAnimation(_petLevel, _petExpPercent)
  if not self.uiData then
    self.progressPetExp:SetPercent(_petExpPercent)
    return
  end
  local lastPetInfo = self.uiData.lastPetInfo
  local oldLevel = lastPetInfo.level or 0
  local newLevel = _petLevel
  local oldPercent = lastPetInfo.expPercent or 0
  local newPercent = _petExpPercent
  local ani = self.Exp_Add
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime() + aniTime * oldPercent
  local endTime = ani:GetStartTime() + aniTime * newPercent
  Log.Debug(newLevel, oldLevel, "UMG_PetBaseInfo_C:playPetExpAnimation")
  if newLevel ~= oldLevel then
    lastPetInfo.isContinueExpEffect = true
    endTime = ani:GetEndTime()
  else
  end
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  local EatTime = self:PlayEatAnima()
  if lastPetInfo.isContinueExpEffect == false then
    self.PlaybackSpeed = (endTime - beginTime) / EatTime
  else
    self.PlaybackSpeed = (endTime - beginTime + aniTime * lastPetInfo.expPercent) / EatTime
  end
  Log.Debug(self.PlaybackSpeed, "UMG_PetLevelUp_C:playPetExpAnimation")
  self:PlayAnimationTimeRange(ani, beginTime, endTime, 1, UE4.EUMGSequencePlayMode.Forward, self.PlaybackSpeed, false)
end

function UMG_PetLevelUp_C:OnPetExpEffectPlayEnd()
  local lastPetInfo = self.uiData.lastPetInfo
  local maxPetLevel = self.uiData.petInfo.maxLevel
  if maxPetLevel <= self.uiData.petInfo.curLevel then
    self.SetBeforeLevel = true
    NRCModuleManager:DoCmd(PetUIModuleCmd.PetUpgradePopout, self.PetbeforeInfo, self.uiData, self.petInfoMainCtrl, self.beforeInfoLevel)
    self.PetbeforeInfo = self.uiData.PetData
    self:CloseParticleResult()
    self.uiData.IsUpGradeSucceed = true
    self:updatePetLevelAndExp()
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:UpdateGradeSucceedPanelInfo()
    self:IsCanLevelUp()
    return
  end
  if not lastPetInfo.isContinueExpEffect then
    if not self.IsUpgrade then
      self:OnIsCloseMask(true)
    end
    self:CloseParticleResult()
    self:updatePetLevelAndExp()
    self:UpdateGradeSucceedPanelInfo()
    self:IsCanLevelUp()
    self.IsUpgrade = false
    return
  end
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime()
  local endTime = ani:GetStartTime() + aniTime * lastPetInfo.expPercent
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  self:PlayAnimationTimeRange(ani, beginTime, endTime, 1, UE4.EUMGSequencePlayMode.Forward, self.PlaybackSpeed, false)
  self:PlayAnimation(self.LevelUp)
  lastPetInfo.isContinueExpEffect = false
  self.IsUpgrade = true
end

function UMG_PetLevelUp_C:PlayEatAnima()
  local EatTime = 0.63
  for i, UseBagItem in pairs(self.UseBagItemList) do
    if UseBagItem.UseCount > 0 then
      local Item = self.ItemList:GetItemByIndex(UseBagItem.Index - 1)
      if Item then
        Item:PlayEatAnima()
        EatTime = Item:GetEatTime()
      end
    end
  end
  return EatTime
end

function UMG_PetLevelUp_C:GetMaxAndCurExp()
  local curExp = self.uiData.petInfo.curPetExp or 0
  local curLevel = self.uiData.petInfo.curLevel
  local maxExp
  if self.uiData.petInfo.petLevelExpList[curLevel] ~= nil then
    maxExp = self.uiData.petInfo.petLevelExpList and self.uiData.petInfo.petLevelExpList[curLevel] and self.uiData.petInfo.petLevelExpList[curLevel].pet_exp or self.uiData.petInfo.petLevelExpList[curLevel].pet_exp or 1
  else
    maxExp = 1
  end
  local BaseLevel = 1
  local BeforeLevel
  if BaseLevel < (curLevel or 0) and self.uiData.petInfo.petLevelExpList and self.uiData.petInfo.petLevelExpList[curLevel - 1] then
    BeforeLevel = self.uiData.petInfo.petLevelExpList[curLevel - 1].pet_exp
    maxExp = maxExp - BeforeLevel
    curExp = curExp - BeforeLevel
  end
  return maxExp, curExp
end

function UMG_PetLevelUp_C:IsReachImpose()
  local maxLevel, MaxLevelInfo = PetUtils.GetPetMaxLevel()
  if nil == maxLevel then
    return false
  end
  if not self.uiData or not self.uiData.PetData then
    return false
  end
  if maxLevel <= (self.uiData.PetData.level or 0) then
    return true
  end
  return false
end

function UMG_PetLevelUp_C:updatePetInfo(_petData)
  self:updateCurPetInfo(_petData)
end

function UMG_PetLevelUp_C:SetExpInfo()
end

function UMG_PetLevelUp_C:updateCurPetInfo(_petData)
  self.PetbeforeInfo = self.uiData.PetData or _petData
  self.uiData.PetData = _petData or {}
end

function UMG_PetLevelUp_C:UpdatePanelInfo()
  self:InitializeData()
  self:updateItemList()
  self:SetCurMoney()
  self:IsCanLevelUp()
  self:SetLevelAndExpInfo()
  self:UpdatePropertyList()
end

function UMG_PetLevelUp_C:IsCanLevelUp()
  local IsReachImpose = self:IsReachImpose()
  if IsReachImpose then
    self.NRCSwitcher_0:SetActiveWidgetIndex(1)
    local Text
    local maxLevel, MaxLevelInfo = PetUtils.GetPetMaxLevel()
    if MaxLevelInfo <= self.uiData.PetData.level then
      Text = LuaText.umg_petlevelup_13
    else
      local NeedStar, title = PetUtils.NeedUpgradeWorldLevel()
      Text = string.format(LuaText.umg_petlevelup_14, title)
    end
    self.PopUp3:SetDescInfo(Text)
    self.PopUp3:ShowOrHideBtnLeft(false)
    self.PopUp3:ShowOrHideBtnRight(false)
  else
    self.NRCSwitcher_0:SetActiveWidgetIndex(0)
  end
end

function UMG_PetLevelUp_C:updateItemList()
  local itemList = NRCModeManager:DoCmd(BagModuleCmd.GetCanFeedItem)
  self.BagItemList = itemList
  self.ItemList:InitGridView(self.BagItemList)
  for i, Item in ipairs(self.BagItemList) do
    local ItemInfo = self.ItemList:GetItemByIndex(i - 1)
    ItemInfo:SetParent(self, self.module:GetRes(Item.itemConf.icon, self.panelName))
    if Item.IsHasNum then
      self.hasFruit = true
    end
  end
end

function UMG_PetLevelUp_C:SetLevelAndExpInfo()
  local maxExp, curExp = self:GetMaxAndCurExp()
  if not maxExp then
    Log.Debug("\232\175\183\230\159\165\231\156\139\228\184\186\228\187\128\228\185\136maxExp\230\178\161\230\156\137\230\149\176\230\141\174")
    maxExp = 1
  end
  local expPercent = curExp / maxExp
  if self.uiData.PetData.level then
    self.Text_PetClass:SetText(string.format(LuaText.umg_petaltaritem_1, self.uiData.PetData.level))
  else
    Log.Error("UMG_PetLevelUp_C PetData.level is nil")
  end
  self.Text_PetQuantity_2:SetText(string.format("/%d", maxExp))
  self.Text_PetQuantity:SetText(curExp)
  self.Text_PetQuantity_1:SetText(0)
  self.progressPetExp:SetPercent(expPercent)
  self.progressPetExp:SetIncreasePercent(0)
end

function UMG_PetLevelUp_C:SelectItemIndex()
  local SelectIndex = self.SelectIndex or 1
  local Item = self.ItemList:GetItemByIndex(SelectIndex - 1)
  if Item then
    self.ItemList:SelectItemByIndex(SelectIndex - 1)
  else
    self.ItemList:SelectItemByIndex(0)
  end
end

function UMG_PetLevelUp_C:SetCurMoney()
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLevelUp_C:getItemPetExp(_itemCfg)
  if _itemCfg and _itemCfg.item_behavior then
    for _, itemBehavior in pairs(_itemCfg.item_behavior) do
      if itemBehavior.use_action == ProtoEnum.ItemBehavior.IB_ADD_PET_EXP then
        return itemBehavior.ratio[1] or 0
      end
    end
  end
  return 0
end

function UMG_PetLevelUp_C:setPetInfoMainCtrl(_petInfoMainCtrl)
  self.petInfoMainCtrl = _petInfoMainCtrl
end

function UMG_PetLevelUp_C:CloseParticleResult()
end

function UMG_PetLevelUp_C:UpdateGradeSucceedPanelInfo()
  if not self.UseBagItemList then
    return
  end
  for i, UseBagItem in pairs(self.UseBagItemList) do
    if UseBagItem.UseCount > 0 then
      UseBagItem.UseCount = 0
    end
  end
  self:UpdatePropertyList()
  self.IsClearSelectedFruit = false
  self:SetBtn2Info()
  self:SetAutomaticallySwitcher()
end

function UMG_PetLevelUp_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif Animation == self.Exp_Add then
    self:OnPetExpEffectPlayEnd()
  elseif Animation == self.LevelUp then
    if self.uiData.IsUpGradeSucceed == false then
      self.SetBeforeLevel = true
      local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetInfoMain").PETUPGRADEOPEN
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "PetInfoMain", touchReasonType)
      NRCModuleManager:DoCmd(PetUIModuleCmd.PetUpgradePopout, self.PetbeforeInfo, self.uiData, self.petInfoMainCtrl, self.beforeInfoLevel)
      self.PetbeforeInfo = self.uiData.PetData
      self:SetVisibility(UE4.ESlateVisibility.Hidden)
      self:UpdateGradeSucceedPanelInfo()
    else
      self:CloseParticleResult()
    end
    self.uiData.IsUpGradeSucceed = false
    self:updatePetLevelAndExp()
  elseif Animation == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_PetLevelUp_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_PetLevelUp")
  if mappingContext then
    mappingContext:BindAction("IA_ClosePetLevelUp", self, "OnPcClose2")
  end
end

function UMG_PetLevelUp_C:OnPcClose2()
  if self.Mask:GetVisibility() == UE4.ESlateVisibility.Visible then
    return
  end
  self:ClosePanelInfo()
end

return UMG_PetLevelUp_C
