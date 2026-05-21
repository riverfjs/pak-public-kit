local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local UMG_Battle_BuffBox_C = NRCClass:Extend("UMG_Battle_BuffBox_C")
local ValueEqual = WidgetStateManager.ValueEquals
local ShowOnlyOneBuffTypeList = {
  ProtoEnum.BuffType.BFT_O_THIRTYTWO
}

function UMG_Battle_BuffBox_C.MakeBuffItemKey(buff)
  local buffType = buff:GetBuffBaseOrder()
  if table.contains(ShowOnlyOneBuffTypeList, buffType) then
    return "type_" .. tostring(buffType)
  end
  return "id_" .. tostring(buff.id)
end

function UMG_Battle_BuffBox_C:Construct()
  self.battleManager = _G.BattleManager
  self.buffs = {}
  self.buffsRef = {}
  self.buffInfos = {}
  self.realShowBuffCount = 0
  self.delayTimerIds = {}
  setmetatable(self.buffs, {__mode = "k"})
  local stateManager = self:GetStateManager()
  self:OnAddEventListener()
  if not self.pet then
    local allPets = self.battleManager.battlePawnManager:GetAllPets()
    for _, pet in ipairs(allPets) do
      if pet.battlePetComponents and (pet.battlePetComponents.BuffBoxWidget == self or pet.battlePetComponents.BuffBox2DWidget == self) then
        self.pet = pet
        break
      end
    end
  end
  if self.pet then
    self:SyncBuffSourceFromPet()
  end
end

function UMG_Battle_BuffBox_C:TryInitStateManager()
  local canShowNumConf = _G.DataConfigManager:GetBattleGlobalConfig("buff_list_show_num")
  local canShowNum = canShowNumConf and canShowNumConf.num or 5
  local stateManager = WidgetStateManager()
  self.stateManager = stateManager
  local initState = {}
  initState.showType = BattleConst.BuffIconShowType.None
  initState.buffSourceList = {}
  initState.maxShowCount = canShowNum
  initState.buffItemDataList = {}
  local initOption = {}
  initOption.owner = self
  initOption.UpdateDerivedState = self.UpdateDerivedState
  initOption.DeriveStateFromProps = self.DeriveStateFromProps
  initOption.RenderWidget = self.RenderWidget
  initOption.OnWidgetDidUpdate = self.OnWidgetDidUpdate
  initOption.initState = initState
  stateManager:Init(initOption)
  return stateManager
end

function UMG_Battle_BuffBox_C:GetStateManager()
  local stateManager = self.stateManager
  stateManager = stateManager or self:TryInitStateManager()
  return stateManager
end

function UMG_Battle_BuffBox_C:SyncBuffSourceFromPet()
  local pet = self.pet
  local buffComponent = pet and pet.buffComponent
  local buffs = buffComponent and buffComponent.buffs or {}
  local newList = {}
  for i, buff in ipairs(buffs) do
    newList[i] = buff
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.buffSourceList = newList
  self:SetState(nextState)
end

function UMG_Battle_BuffBox_C:Destruct()
  self.pet = nil
  local stateManager = self.stateManager
  if stateManager then
    stateManager:DeInit()
    self.stateManager = nil
  end
  if self.delayTimerIds then
    for _, timerId in ipairs(self.delayTimerIds) do
      _G.DelayManager:CancelDelayById(timerId)
    end
    self.delayTimerIds = nil
  end
  local allBuffs = {}
  for buff, v in pairs(self.buffs) do
    table.insert(allBuffs, buff)
  end
  if self.buffsRef then
    for index, buffMode in pairs(self.buffsRef) do
      if buffMode and UE.UObject.IsValid(buffMode) then
        UnLua.Unref(buffMode)
      end
      self.buffsRef[index] = nil
    end
  end
  for _, buff in ipairs(allBuffs) do
    self:RemoveBuff(buff, true)
  end
  allBuffs = nil
  self:OnRemoveEventListener()
  self.battleManager = nil
  table.clear(self.buffs)
  self.buffs = nil
  self.buffInfos = nil
  self.buffsRef = nil
  self.realShowBuffCount = 0
  NRCUmgClass.Destruct(self)
end

function UMG_Battle_BuffBox_C:OnAddEventListener()
  BattleEventCenter:Bind(self, BattlePerformEvent.BuffChange, BattleEvent.REFRESH_BUFF, BattleEvent.REMOVE_BUFF)
  self.BtnDetails.OnClicked:Add(self, self.onBtnBuffClick)
end

function UMG_Battle_BuffBox_C:SetShowType(type)
  self.ShowType = type
  local _, nextState = self:GetCurrAndNextState()
  nextState.showType = type
  self:SetState(nextState)
end

function UMG_Battle_BuffBox_C:RefreshUIByShowType()
  local state = self:GetState()
  local showType = state.showType
  local isBtnDetailShow = state.isBtnDetailShow
  if not showType or showType == BattleConst.BuffIconShowType.None then
    self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.NRCImage_38:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif showType == _G.BattleConst.BuffIconShowType.WorldUI then
    if isBtnDetailShow then
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.NRCImage_38:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif showType == _G.BattleConst.BuffIconShowType.ScreenBtn then
    if isBtnDetailShow then
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.NRCImage_38:SetVisibility(UE4.ESlateVisibility.Hidden)
  elseif showType == _G.BattleConst.BuffIconShowType.ScreenBtnAndUI then
    if isBtnDetailShow then
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BtnDetails:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.NRCImage_38:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Battle_BuffBox_C:CheckBtnDetailsShow(state)
end

function UMG_Battle_BuffBox_C:OnRemoveEventListener()
  BattleEventCenter:UnBind(self)
  self.BtnDetails.OnClicked:Remove(self, self.onBtnBuffClick)
end

function UMG_Battle_BuffBox_C:BindPet(pet)
  self.pet = pet
end

function UMG_Battle_BuffBox_C:RefreshAttachingPivotScale(model, widgetScale)
  do return end
  if not model then
    return
  end
  local CapsuleComponent = model:GetComponentByClass(UE4.UCapsuleComponent)
  local radius = 50
  if CapsuleComponent then
    radius = CapsuleComponent:GetScaledCapsuleRadius()
  end
  radius = radius * 4 / 5
  self.sourcePos = self.BuffListingBox.Slot:GetPosition()
  if self.ShowType == _G.BattleConst.BuffIconShowType.WorldUI then
    self.BuffListingBox.Slot:SetPosition(UE4.FVector2D(radius, self.sourcePos.Y))
  else
    self.BuffListingBox.Slot:SetPosition(UE4.FVector2D(radius, self.sourcePos.Y))
  end
end

function UMG_Battle_BuffBox_C:OnBattleEvent(eventName, ...)
  if eventName == BattlePerformEvent.BuffChange and self.pet then
    local arg = {
      ...
    }
    local battlePet = arg[1]
    if self.pet == battlePet then
      self:SyncBuffSourceFromPet()
    end
    return true
  elseif eventName == BattleEvent.REFRESH_BUFF then
    local battlePet = (...)
    if self.pet == battlePet then
      self:SyncBuffSourceFromPet()
    end
    return true
  elseif eventName == BattleEvent.REMOVE_BUFF then
    local battlePet = (...)
    if self.pet == battlePet then
      self:SyncBuffSourceFromPet()
    end
    return true
  end
end

function UMG_Battle_BuffBox_C:RefreshBuff(battlePet)
  if self.pet == battlePet then
    self:SyncBuffSourceFromPet()
  end
end

function UMG_Battle_BuffBox_C:AddBuff(buff, pos)
  if not self.pet then
    return
  end
  local isMimic, MimicType = self.pet.card:CheckIsMimic()
  if isMimic and MimicType == ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC then
    return
  end
  if not buff:NeedShow() then
    return
  end
  local isNeedDelay
  if self.pet and self.pet.battlePetComponents then
    isNeedDelay = self.pet.battlePetComponents:PreAddBuffVisible()
  end
  if not isNeedDelay then
    self:LoadBuff(buff, pos)
  else
    local timerId
    timerId = _G.DelayManager:DelayFrames(2, function()
      table.removeValue(self.delayTimerIds, timerId)
      if not self.pet then
        return
      end
      self:LoadBuff(buff, pos)
    end)
    table.insert(self.delayTimerIds, timerId)
  end
end

function UMG_Battle_BuffBox_C:LoadBuff(buff, pos)
  local asset = _G.BattleResourceManager:GetCacheAssetDirect(_G.UEPath.UMG_Battle_Buff, true)
  if asset then
    self:LoadBuffOver(asset, buff, pos)
  else
    _G.BattleResourceManager:LoadResAsyncWithParam(self, _G.UEPath.UMG_Battle_Buff, self.LoadBuffOver, nil, buff, pos)
  end
end

function UMG_Battle_BuffBox_C:LoadBuffOver(res, buff, pos)
  if not self.pet then
    return
  end
  if not UE.UObject.IsValid(self.BuffListingBox) then
    return
  end
  buff = self.pet.buffComponent:GetBuff(buff.id)
  if buff and buff.buffInfo then
    for m, _ in pairs(self.buffs) do
      if m.id == buff.id then
        self:ChangeBuff(buff)
        return
      end
    end
    local buffModel = UE4.UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), res)
    local Slot = self.BuffListingBox:InsertChildToHorizontalBox(pos - 1, buffModel)
    buffModel:SetBuffInfo(buff)
    buffModel:SetCallBack(self, self.RefreshVisible)
    buffModel:SetShowType(self.ShowType)
    buffModel:UpdateStack(buff:GetShowStack(), true)
    buffModel:UpdateBurial(buff)
    buffModel:UpdateCornerIcon()
    local Padding = UE4.FMargin()
    Padding.Left = 0
    Padding.Top = 0
    Padding.Right = -20
    Padding.Bottom = 0
    Slot:SetPadding(Padding)
    if buffModel.btnBuff and buffModel.btnBuff.OnClicked then
      buffModel.btnBuff.OnClicked:Add(buffModel, buffModel.OnBtnBuffClick)
    else
      Log.Error("zgx onclick is nil , this is weird!!!")
    end
    buffModel.call = self.onBtnBuffClick
    buffModel.caller = self
    buffModel:TriggerConstructAnimation()
    local buffIconPath = buff.config.icon
    buffModel:ChangeIcon(buffIconPath)
    local NeedShow = buff:NeedShow()
    buffModel:SetShowState(NeedShow)
    self.buffs[buff] = buffModel
    self.buffsRef[buff] = UnLua.Ref(buffModel)
    if NeedShow then
      self:RefreshBuffModeShow()
    end
  end
end

function UMG_Battle_BuffBox_C:RefreshBuffModeShow()
  local childNum = self.BuffListingBox:GetChildrenCount()
  local canShowNum = _G.DataConfigManager:GetBattleGlobalConfig("buff_list_show_num").num
  local curShowNum = 0
  local willShowNum = 0
  local lastBuffMode
  local Padding = UE4.FMargin()
  Padding.Left = 0
  Padding.Top = 0
  Padding.Right = -20
  Padding.Bottom = 0
  for index = 0, childNum do
    local buffMode = self.BuffListingBox:GetChildAt(index)
    if buffMode then
      local isExist = buffMode:GetNeedShow() and self.buffs[buffMode.buff]
      if isExist then
        willShowNum = willShowNum + 1
      end
      if isExist and canShowNum > curShowNum then
        curShowNum = curShowNum + 1
        buffMode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        lastBuffMode = buffMode
        buffMode.Slot:SetPadding(Padding)
      else
        buffMode:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  if lastBuffMode then
    Padding.Right = -14
    lastBuffMode.Slot:SetPadding(Padding)
  end
end

function UMG_Battle_BuffBox_C:RefreshVisible()
  if self.pet and self.pet.battlePetComponents then
    self.pet.battlePetComponents:AfterRemoveBuffVisible()
  end
end

function UMG_Battle_BuffBox_C:ChangeBuff(buff, isAdd)
  if self.buffs[buff] then
    local buffModel = self.buffs[buff]
    local Conf = _G.DataConfigManager:GetBuffConf(buff.id)
    local buffIconPath = Conf.icon
    local stackPre = buffModel.stack
    buffModel:SetBuffInfo(buff)
    local newStack = buff:GetShowStack()
    buffModel:UpdateStack(newStack, false)
    buffModel:UpdateBurial(buff)
    buffModel:UpdateCornerIcon()
    buffModel:ChangeIcon(buffIconPath)
    local NeedShow = buff:NeedShow()
    buffModel:SetShowState(NeedShow)
    if NeedShow then
      self:RefreshBuffModeShow()
    end
    if nil == isAdd then
      buffModel:ClearAnimPlayQueue()
      buffModel:UpdateStackDisplay(newStack)
      return
    elseif stackPre > buffModel.stack then
      buffModel:OnTriggerNumberChange(false)
    elseif stackPre < buffModel.stack then
      buffModel:OnTriggerNumberChange(true)
    end
  end
end

function UMG_Battle_BuffBox_C:RemoveBuff(buff, immediate)
  if self.buffs[buff] then
    local buffModel = self.buffs[buff]
    if buffModel.btnBuff and buffModel.btnBuff.OnClicked then
      buffModel.btnBuff.OnClicked:Remove(buffModel, buffModel.OnBtnBuffClick)
    else
      Log.Error("zgx onclick is nil , this is weird!!!")
    end
    buffModel.call = nil
    buffModel.caller = nil
    self.buffs[buff] = nil
    local buffMode = self.buffsRef[buff]
    if buffMode and UE.UObject.IsValid(buffMode) then
      UnLua.Unref(buffMode)
    end
    self.buffsRef[buff] = nil
    local visState = buffModel:GetVisibility()
    if visState == UE4.ESlateVisibility.Hidden or visState == UE4.ESlateVisibility.Collapsed then
      buffModel:Remove(true, self, self.RemoveBuffCallBack)
    else
      buffModel:Remove(immediate, self, self.RemoveBuffCallBack)
    end
    if buff.config and self.pet then
      for _, v in ipairs(buff.config.buff_groupsigns) do
        if v == ProtoEnum.BuffGroupSign.BGS_MIMIC and not self.pet.card.petState:GetMimic() then
          self:RefreshBuff(self.pet)
        end
      end
    end
  end
end

function UMG_Battle_BuffBox_C:RemoveBuffCallBack()
  self:RefreshBuffModeShow()
end

function UMG_Battle_BuffBox_C:RemoveBuffs(battlePet, immediate)
  if self.pet == battlePet then
    for i, v in pairs(self.buffs) do
      self:RemoveBuff(i, immediate)
    end
  end
end

function UMG_Battle_BuffBox_C:onBtnBuffClick()
  Log.Debug("UMG_Battle_BuffBox_C:onBtnBuffClick")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1060, "UMG_Battle_BuffBox_C:ClickBuff")
  if self.pet and self.buffInfos and #self.buffInfos > 0 then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBuffInfo, {
      buffData = self.buffInfos
    })
  end
end

function UMG_Battle_BuffBox_C:GetBuffInfos()
  return self.realShowBuffCount
end

function UMG_Battle_BuffBox_C:GetBuffInfosByType(buffType)
  local buffs = {}
  for i, buff in ipairs(self.buffInfos) do
    if buff:GetBuffBaseOrder() == buffType then
      table.insert(buffs, buff)
    end
  end
  return buffs
end

function UMG_Battle_BuffBox_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevMaxShowCount = prevState and prevState.maxShowCount
  local currMaxShowCount = currState and currState.maxShowCount
  local prevBuffItemDataList = prevState and prevState.buffItemDataList
  local currBuffItemDataList = currState and currState.buffItemDataList
  if prevMaxShowCount ~= currMaxShowCount or prevBuffItemDataList ~= currBuffItemDataList then
    UMG_Battle_BuffBox_C.DeriveVisibleItemDataListAndDetailButtonShow(currMaxShowCount, currBuffItemDataList, derivedState)
  end
end

function UMG_Battle_BuffBox_C.DeriveVisibleItemDataListAndDetailButtonShow(maxShowCount, buffItemDataList, derivedState)
  maxShowCount = maxShowCount or 5
  buffItemDataList = buffItemDataList or {}
  local visibleList = {}
  for i = 1, math.min(#buffItemDataList, maxShowCount) do
    visibleList[i] = buffItemDataList[i]
  end
  derivedState.visibleItemDataList = visibleList
  derivedState.isBtnDetailShow = maxShowCount < #buffItemDataList
end

function UMG_Battle_BuffBox_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevShowType = prevState and prevState.showType
  local currShowType = currState and currState.showType
  local prevIsBtnDetailShow = prevState and prevState.isBtnDetailShow
  local currIsBtnDetailShow = currState and currState.isBtnDetailShow
  if prevIsBtnDetailShow ~= currIsBtnDetailShow or prevShowType ~= currShowType or prevKey ~= currKey then
    self:RefreshUIByShowType()
  end
end

function UMG_Battle_BuffBox_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevBuffItemDataList = prevState and prevState.buffItemDataList
  local currBuffItemDataList = currState and currState.buffItemDataList
  local prevBuffSourceList = prevState and prevState.buffSourceList
  local currBuffSourceList = currState and currState.buffSourceList
  if prevBuffSourceList ~= currBuffSourceList then
    self:UpdateBuffItemDataList(currBuffSourceList)
  end
  if prevBuffItemDataList ~= currBuffItemDataList then
    self:UpdateBuffInfoByBuffItemDataList(currBuffItemDataList)
  end
  local prevVisibleItemDataList = prevState and prevState.visibleItemDataList or {}
  local currVisibleItemDataList = currState and currState.visibleItemDataList or {}
  if prevVisibleItemDataList ~= currVisibleItemDataList then
    self:OnVisibleItemDateUpdate(prevVisibleItemDataList, currVisibleItemDataList)
  end
end

function UMG_Battle_BuffBox_C:UpdateBuffItemDataList(buffSourceList)
  local itemDataList = {}
  local seenOnlyOneTypes = {}
  buffSourceList = buffSourceList or {}
  for i, buff in ipairs(buffSourceList) do
    if buff:NeedShow() then
      local buffType = buff:GetBuffBaseOrder()
      local isOnlyOne = table.contains(ShowOnlyOneBuffTypeList, buffType)
      local config = buff and buff.config
      local iconPath = config and config.icon or ""
      if isOnlyOne then
        if not seenOnlyOneTypes[buffType] then
          seenOnlyOneTypes[buffType] = true
          table.insert(itemDataList, {
            key = UMG_Battle_BuffBox_C.MakeBuffItemKey(buff),
            buff = buff,
            iconPath = iconPath,
            stack = buff:GetShowStack(),
            buffType = buffType
          })
        end
      else
        table.insert(itemDataList, {
          key = UMG_Battle_BuffBox_C.MakeBuffItemKey(buff),
          buff = buff,
          iconPath = iconPath,
          stack = buff:GetShowStack(),
          buffType = buffType
        })
      end
    end
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.buffItemDataList = itemDataList
  self:SetState(nextState)
end

function UMG_Battle_BuffBox_C:UpdateBuffInfoByBuffItemDataList(buffItemDataList)
  buffItemDataList = buffItemDataList or {}
  local newBuffInfos = {}
  for i, itemData in ipairs(buffItemDataList) do
    local buff = itemData and itemData.buff
    if buff then
      table.insert(newBuffInfos, buff)
    end
  end
  self.buffInfos = newBuffInfos
end

function UMG_Battle_BuffBox_C:OnVisibleItemDateUpdate(prevVisibleItemDataList, currVisibleItemDataList)
  prevVisibleItemDataList = prevVisibleItemDataList or {}
  currVisibleItemDataList = currVisibleItemDataList or {}
  local prevMap = {}
  for i, item in ipairs(prevVisibleItemDataList) do
    local key = item and item.key
    if key then
      prevMap[key] = item
    end
  end
  local currMap = {}
  for i, item in ipairs(currVisibleItemDataList) do
    local key = item and item.key
    if key then
      currMap[key] = item
    end
  end
  for _, item in ipairs(prevVisibleItemDataList) do
    local key = item and item.key
    local buff = item and item.buff
    if key and buff and not currMap[key] then
      self:RemoveBuff(buff, false)
    end
  end
  for i, item in ipairs(currVisibleItemDataList) do
    local key = item and item.key
    local buff = item and item.buff
    if key and buff and not prevMap[key] then
      self:AddBuff(buff, i)
    end
  end
  for _, item in ipairs(currVisibleItemDataList) do
    local key = item and item.key
    local prevItem = key and prevMap[key]
    if prevItem then
      local prevBuff = prevItem and prevItem.buff
      local currBuff = item and item.buff
      local prevStack = prevItem and prevItem.stack
      local currStack = item and item.stack
      local prevIconPath = prevItem and prevItem.iconPath
      local currIconPath = item and item.iconPath
      if prevBuff ~= currBuff then
        self:TransferBuffWidget(prevBuff, currBuff)
      end
      if prevStack ~= currStack then
        local stack = currStack or 0
        local isAdd = stack > (prevStack or 0)
        self:ChangeBuff(currBuff, isAdd)
      elseif prevBuff ~= currBuff or prevIconPath ~= currIconPath then
        self:ChangeBuff(currBuff)
      end
    end
  end
  self.realShowBuffCount = #currVisibleItemDataList
end

function UMG_Battle_BuffBox_C:TransferBuffWidget(oldBuff, newBuff)
  local buffs = self.buffs
  local buffsRef = self.buffsRef
  local buffModel = oldBuff and buffs and buffs[oldBuff]
  if not buffModel then
    return
  end
  if not buffs then
    return
  end
  if not buffsRef then
    return
  end
  buffs[oldBuff] = nil
  buffs[newBuff] = buffModel
  buffsRef[newBuff] = buffsRef[oldBuff]
  buffsRef[oldBuff] = nil
  buffModel:SetBuffInfo(newBuff)
end

function UMG_Battle_BuffBox_C:GetProps()
  local stateManager = self:GetStateManager()
  return stateManager and stateManager:GetProps() or {}
end

function UMG_Battle_BuffBox_C:SetProps(nextProps)
  local stateManager = self:GetStateManager()
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_Battle_BuffBox_C:GetState()
  local stateManager = self:GetStateManager()
  return stateManager and stateManager:GetState() or {}
end

function UMG_Battle_BuffBox_C:SetState(nextState)
  local stateManager = self:GetStateManager()
  if stateManager then
    stateManager:SetState(nextState)
  end
end

function UMG_Battle_BuffBox_C:GetCurrAndNextState()
  local stateManager = self:GetStateManager()
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
  return {}, {}
end

return UMG_Battle_BuffBox_C
