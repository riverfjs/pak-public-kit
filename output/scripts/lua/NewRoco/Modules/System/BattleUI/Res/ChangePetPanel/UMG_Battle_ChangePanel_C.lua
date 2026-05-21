local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_Battle_ChangePanel_C = NRCPanelBase:Extend("UMG_Battle_ChangePanel_C")
local ValueEquals = WidgetStateManager.ValueEquals
local ScrollBarMinAngle = -0.5
local ScrollBarMaxAngle = -25.7
local ItemCountPerPage = 5

function UMG_Battle_ChangePanel_C:Construct()
  self.battleManager = _G.BattleManager
  self:AddListener()
  self.items = {}
  self.Item1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Item2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Item3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Item4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Item5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Item6:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.widgetType = BattleEnum.WidgetType.ENUM_CHANGE_PET_PANEL
  self.visibleCount = 0
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_ChangePanel_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  self.BloodLimit = nil
  self.ScrollBarRuntimeMaxAngle = ScrollBarMaxAngle
  self.ArcScrollView.AutoSnapWaitTime = 0.05
  self.ArcScrollView.normalizeMouseWheelData = true
  self.ArcScrollView.EnablePageNation = true
  self.ArcScrollView.PageItemCount = ItemCountPerPage
  self.ArcScrollView.HideItemPercentageThreshold = 0.3
  self.ArcScrollView.MouseWheelDataMultiplier = ItemCountPerPage
  self.scrollOverThresholdSinceLastPress = false
  self.isUserScrollingSinceLastPress = false
  self.lastFrameScrollingState = false
  self.ArcScrollBar:SetRenderOpacity(0)
  self.stateManager = WidgetStateManager()
  local initState = {}
  initState.onPetClickCallback = self.OnPetIconClicked
  initState.onPetClickCallbackOwner = self
  initState.onSpawnCallback = _G.MakeWeakFunctor(self, self.OnItemSpawn)
  initState.onDeSpawnCallback = _G.MakeWeakFunctor(self, self.OnItemDeSpawn)
  self.stateManager:Init({
    owner = self,
    RenderWidget = self.RenderWidget,
    OnWidgetDidUpdate = self.OnWidgetDidUpdate,
    UpdateDerivedState = self.UpdateDerivedState,
    DeriveStateFromProps = self.DeriveStateFromProps,
    GetChildWidgets = self.GetChildWidgets,
    initState = initState,
    autoCreateDebugger = false
  })
end

function UMG_Battle_ChangePanel_C:OnDestruct()
  self:DisposeShowAndHideContext(false)
  self.stateManager:DeInit()
end

function UMG_Battle_ChangePanel_C:Destruct()
  self:RemoveListener()
  table.clear(self.items)
  self.items = nil
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  NRCUmgClass.Destruct(self)
end

function UMG_Battle_ChangePanel_C:OnEnable(...)
  self:OnActive(...)
end

function UMG_Battle_ChangePanel_C:OnActive(pet, playAnim, callback)
  self:PCModeScreenSetting()
  self:DisposeShowAndHideContext()
  local currState, nextState = self:GetCurrAndNextState()
  local changingBetweenSubPanels = BattleUtils.IsMainWindowChangingBetweenSubPanels()
  local nextContext = {}
  local contextId = os.msTime()
  nextContext.id = contextId
  nextContext.playAnim = playAnim
  nextContext.callback = callback
  if changingBetweenSubPanels then
    nextContext.reverseItemShowOrder = true
  end
  local delayShowId = self:DelayFrames(2, self.DelayShowTimeout, self, contextId)
  nextContext.delayShowId = delayShowId
  nextState.battlePet = pet
  nextState.showContext = nextContext
  nextState.changingBetweenSubPanels = changingBetweenSubPanels
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:OnDisable()
  self:Hide(false)
end

function UMG_Battle_ChangePanel_C:OnDeactive()
  self:Hide(false)
end

function UMG_Battle_ChangePanel_C:WaitingRecycle()
  self:RemoveListener()
end

function UMG_Battle_ChangePanel_C:AddListener()
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_BAG_PET, BattleEvent.BATTLE_BEGING_USE_CHANGE_PET_SKILL, BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL, BattleEvent.UI_HIDE, BattleEvent.UI_USE_PLAYERSKILL_UPDATE, BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL, BattleEvent.UPDATE_DATA, BattleEvent.BATTLE_CLICKED_PET)
end

function UMG_Battle_ChangePanel_C:RemoveListener()
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Battle_ChangePanel_C:SelectItem(index, isPressed)
  local currState, nextState = self:GetCurrAndNextState()
  local reIndex = index + currState.visibleStartIndex - 1
  local item = self.ArcScrollView:GetItemByIndex(reIndex - 1)
  local itemInstance = UE.UObject.IsValid(item) and item.UMG_Battle_Card
  if itemInstance then
    if isPressed then
      itemInstance:OnItemPressed()
    else
      itemInstance:OnItemRelease()
    end
  end
end

function UMG_Battle_ChangePanel_C:PCKeySetting()
  local _, nextState = self:GetCurrAndNextState()
  nextState.updatePcKeyFlag = {}
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:SetUpPCKey()
  if SystemSettingModuleCmd then
    if self.Item1 then
      self.Item1.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_1")
      if "" ~= image then
        self.Item1.Text_PCKey:SetImageMode(image)
      else
        self.Item1.Text_PCKey:SetText(text)
      end
    end
    if self.Item2 then
      self.Item2.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_2")
      if "" ~= image then
        self.Item2.Text_PCKey:SetImageMode(image)
      else
        self.Item2.Text_PCKey:SetText(text)
      end
    end
    if self.Item3 then
      self.Item3.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_3")
      if "" ~= image then
        self.Item3.Text_PCKey:SetImageMode(image)
      else
        self.Item3.Text_PCKey:SetText(text)
      end
    end
    if self.Item4 then
      self.Item4.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_4")
      if "" ~= image then
        self.Item4.Text_PCKey:SetImageMode(image)
      else
        self.Item4.Text_PCKey:SetText(text)
      end
    end
    if self.Item5 then
      self.Item5.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_5")
      if "" ~= image then
        self.Item5.Text_PCKey:SetImageMode(image)
      else
        self.Item5.Text_PCKey:SetText(text)
      end
    end
    if self.Item6 then
      self.Item6.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_6")
      if "" ~= image then
        self.Item6.Text_PCKey:SetImageMode(image)
      else
        self.Item6.Text_PCKey:SetText(text)
      end
    end
  end
end

function UMG_Battle_ChangePanel_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_BAG_PET then
  elseif eventName == BattleEvent.BATTLE_BEGING_USE_CHANGE_PET_SKILL then
    self:UpdatePetInfo(...)
  elseif eventName == BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL then
    self:InitializedPlyaerSkill()
  elseif eventName == BattleEvent.UI_HIDE then
    self:InitializedPlyaerSkill()
  elseif eventName == BattleEvent.UI_USE_PLAYERSKILL_UPDATE then
    self:UsePlayerSkillSuccess(...)
  elseif eventName == BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL then
    self:InitializedPlyaerSkill()
  elseif eventName == BattleEvent.UPDATE_DATA then
    self:UpdatePlayerData(...)
  elseif eventName == BattleEvent.BATTLE_CLICKED_PET then
  end
end

function UMG_Battle_ChangePanel_C:InitializedPlyaerSkill()
  self.IsUsePlayerSkill = false
  self.BloodLimit = nil
end

function UMG_Battle_ChangePanel_C:UpdatePetInfo(_BloodLimit)
  self.IsUsePlayerSkill = true
  self.BloodLimit = _BloodLimit
  self:UpdateData(self.battleManager.battlePawnManager.playerTeam.player)
end

function UMG_Battle_ChangePanel_C:UsePlayerSkillSuccess(PlayerSkillData)
  if PlayerSkillData.EffectConf.effect_order == Enum.EffectType.ET_ROLE_CHANGE_PET then
    self.IsUsePlayerSkill = false
    self.BloodLimit = nil
    self:UpdateData(self.battleManager.battlePawnManager.playerTeam.player)
  end
end

function UMG_Battle_ChangePanel_C:UpdatePlayerData(pet)
  local _, nextState = self:GetCurrAndNextState()
  nextState.battlePet = pet
  self:SetState(nextState)
  self:UpdateData(pet.team.player)
end

function UMG_Battle_ChangePanel_C:UpdateData(player)
  if not player then
    Log.Error("zgx player Not Found")
    return
  end
  local typeOfVisible = self:GetVisibility()
  if typeOfVisible == UE4.ESlateVisibility.Collapsed or typeOfVisible == UE4.ESlateVisibility.Hidden then
    return
  end
  local deck = player and player.deck
  local cards = deck and deck.cards or {}
  local battleManager = self.battleManager
  local pawnManager = battleManager and battleManager.battlePawnManager
  local currentMyPets = pawnManager and pawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true) or {}
  local petGidToCurrentAliveMyPets = {}
  for i, pet in ipairs(currentMyPets) do
    local petGid = pet and pet.guid
    local isDead = pet and pet:IsDead()
    if petGid and not isDead then
      petGidToCurrentAliveMyPets[petGid] = pet
    end
  end
  local currState, nextState = self:GetCurrAndNextState()
  local currPet = currState and currState.battlePet
  local currPetId = currPet and currPet.guid
  local cardList = {}
  local changeCount = 1
  local restPets = player.team.RestPets
  for _, v in ipairs(cards) do
    if restPets[v.pos] then
      if v ~= restPets[v.pos].card then
        if self.IsUsePlayerSkill then
          if self:IsBloodLimit(v) then
            table.insert(cardList, v)
          end
        else
          table.insert(cardList, v)
        end
      end
    elseif not v:IsInBattle() and not v:IsBeCatch() and not v:IsBeRidOf() and not v:GetIsRunAway() then
      local satisfy = not self.IsUsePlayerSkill or self:IsBloodLimit(v)
      if satisfy then
        table.insert(cardList, v)
      end
    end
  end
  local filterCardList = {}
  for _, card in ipairs(cardList) do
    local petInfo = card and card.petInfo
    local insideInfo = petInfo and petInfo.battle_inside_pet_info
    local sourcePetId = insideInfo and insideInfo.buff145_source_pet or 0
    if 0 == sourcePetId then
      table.insert(filterCardList, card)
    else
      local sourcePet = petGidToCurrentAliveMyPets and petGidToCurrentAliveMyPets and petGidToCurrentAliveMyPets[sourcePetId]
      if sourcePet then
        table.insert(filterCardList, card)
      end
    end
  end
  nextState.dataUpdateFlag = {}
  nextState.battleCardList = filterCardList
  self:SetState(nextState)
  for i = changeCount, #self.items do
  end
  if self.RoleHPMini and self.RoleHPMini.Update then
    self.RoleHPMini:Update(player)
  else
    Log.Error("self.RoleHPMini or self.RoleHPMini.Update Not Found")
  end
end

function UMG_Battle_ChangePanel_C:IsBloodLimit(CardEntity)
  for i, BloodId in ipairs(self.BloodLimit or {}) do
    if BloodId == CardEntity.petInfo.battle_common_pet_info.blood_id then
      return true
    end
  end
  return false
end

function UMG_Battle_ChangePanel_C:SetColor(color)
  for k, v in ipairs(self.items) do
    v:SetColor(color)
  end
end

function UMG_Battle_ChangePanel_C:CheckShouldTip(item, isCover)
  if isCover then
    if self.curTipPetBtn and not self.curTipPetBtn:GetIsCover() and item ~= self.curTipPetBtn then
      self:SetCurTipSkill(item)
      item:OnPetInfoUpdate()
      return true
    end
  elseif not self.curTipPetBtn then
    self:SetFirstTipSkill(item)
    self:SetCurTipSkill(item)
    return true
  end
  return false
end

function UMG_Battle_ChangePanel_C:CheckHideTip(item)
  if self.firstTipPetBtn and self.firstTipPetBtn == item then
    self:HideCurTipSkill()
  end
end

function UMG_Battle_ChangePanel_C:SetFirstTipSkill(item)
  self.firstTipPetBtn = item
end

function UMG_Battle_ChangePanel_C:SetCurTipSkill(item)
  self.curTipPetBtn = item
end

function UMG_Battle_ChangePanel_C:HideCurTipSkill()
  if self.curTipPetBtn then
    self.curTipPetBtn:OnPetInfoClose()
    self.firstTipPetBtn = nil
    self.curTipPetBtn = nil
  end
end

function UMG_Battle_ChangePanel_C:StopShowHide()
  self:StopAllAnimations()
  self:DisposeShowAndHideContext()
  local currState, nextState = self:GetCurrAndNextState()
  nextState.isShow = false
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:Show(playAnim, callback)
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  self:StopAllAnimations()
  if self.RoleHPMini and self.RoleHPMini.SetVisibility then
    self.RoleHPMini:SetVisibility(BattleUtils.IsTeam() and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.isShow = true
  self:SetState(nextState)
  if playAnim then
    if self.RoleHPMini and self.RoleHPMini.SetVisibility and self.RoleHPMini.Show then
      if not BattleUtils.IsTeam() then
        self.RoleHPMini:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.RoleHPMini:Show()
      end
    else
      Log.Error("self.RoleHPMini or self.RoleHPMini.SetVisibility Not Found")
    end
  end
  self.TweenInCallback = callback
  self:UpdateData(self.battleManager.battlePawnManager:GetPlayerMyTeam())
end

function UMG_Battle_ChangePanel_C:Hide(playAnim, callback)
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  self:StopAllAnimations()
  self:DisposeShowAndHideContext()
  local currState, nextState = self:GetCurrAndNextState()
  nextState.isShow = false
  nextState.selectPetGid = nil
  self:SetState(nextState)
  if playAnim then
    currState, nextState = self:GetCurrAndNextState()
    local nextContext = {}
    local contextId = os.msTime()
    nextContext.id = contextId
    nextContext.playAnim = playAnim
    nextContext.callback = callback
    local delayCompleteId = self:DelaySeconds(0.25, self.DelayHideCompleteTimeout, self, contextId)
    nextContext.delayCompleteId = delayCompleteId
    nextState.hideContext = nextContext
    self:SetState(nextState)
    if self.RoleHPMini and self.RoleHPMini.Hide then
      self.RoleHPMini:Hide()
    else
      Log.Error("self.RoleHPMini or self.RoleHPMini.Hide Not Found")
    end
  elseif callback then
    callback()
  end
end

function UMG_Battle_ChangePanel_C:OnAnimationFinished(Animation)
  if Animation == self.TweenIn then
    local Callback = self.TweenInCallback
    self.TweenInCallback = nil
    if Callback then
      Callback()
    end
  elseif Animation == self.TweenOut then
    local Callback = self.TweenOutCallback
    self.TweenOutCallback = nil
    if Callback then
      Callback()
    end
  end
end

function UMG_Battle_ChangePanel_C:OnPetIconClicked(id)
  local currState, nextState = self:GetCurrAndNextState()
  local currSelectPetGid = currState and currState.selectPetGid
  if currSelectPetGid == id then
    return
  end
  nextState.selectPetGid = id
  self:SetState(nextState)
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BAG_PET, id)
end

function UMG_Battle_ChangePanel_C:OnItemSpawn(index)
  local currState, nextState = self:GetCurrAndNextState()
  local visibleIndexSet = currState and currState.visibleIndexSet or {}
  local nextSet = {}
  table.copy(visibleIndexSet, nextSet)
  if index then
    nextSet[index] = true
    nextState.visibleIndexSet = nextSet
    self:SetState(nextState)
  end
end

function UMG_Battle_ChangePanel_C:OnItemDeSpawn(index)
  local currState, nextState = self:GetCurrAndNextState()
  local visibleIndexSet = currState and currState.visibleIndexSet or {}
  local nextSet = {}
  table.copy(visibleIndexSet, nextSet)
  if index then
    nextSet[index] = nil
    nextState.visibleIndexSet = nextSet
    self:SetState(nextState)
  end
end

function UMG_Battle_ChangePanel_C:OnPetClicked(pet)
  local card = pet and pet.card
  local guid = card and card.guid
  local currState, nextState = self:GetCurrAndNextState()
  local currSelectPetGid = currState and currState.selectPetGid
  if currSelectPetGid ~= guid then
    nextState.selectPetGid = nil
    self:SetState(nextState)
  end
end

function UMG_Battle_ChangePanel_C:PCModeScreenSetting()
  local pcKeyLoaderVisibility = UE.ESlateVisibility.Collapsed
  local arrowVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  if UE.UGameplayStatics.GetGameInstance(self):IsPCMode() then
    local Padding = UE4.FMargin()
    self.CanvasPanel_58:SetRenderScale(UE4.FVector2D(0.88, 0.88))
    Padding.Left = -52
    Padding.Top = 0
    Padding.Right = 0
    Padding.Bottom = 0
    self.CanvasPanel_58.Slot:SetOffsets(Padding)
    self.RoleHPMini:SetRenderScale(UE4.FVector2D(1.12, 1.12))
    Padding.Left = 68
    Padding.Top = -132
    Padding.Right = 115.46
    Padding.Bottom = 30
    self.RoleHPMini.Slot:SetOffsets(Padding)
    pcKeyLoaderVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  end
  self.PCKey_Loader:SetVisibility(pcKeyLoaderVisibility)
  self.PCKey_Loader:SetScrollMode()
  self.Arrow1:SetVisibility(arrowVisibility)
  self.Arrow2:SetVisibility(arrowVisibility)
  self.PCKey_Loader:SetVisibility(pcKeyLoaderVisibility)
end

function UMG_Battle_ChangePanel_C:CancelOnOpenAnimDelay()
  if self.onOpenAnimFinishedDelayId then
    self:CancelDelayByID(self.onOpenAnimFinishedDelayId)
    self.onOpenAnimFinishedDelayId = nil
  end
end

function UMG_Battle_ChangePanel_C:OnOpenAnimFinished()
  self:OnAnimationFinished(self.TweenIn)
end

function UMG_Battle_ChangePanel_C:PlayOpenAnim(_IsOpen)
  for i, item in ipairs(self.items) do
    if _IsOpen then
      item:SetRenderOpacity(1)
      item:SetRenderScale(UE4.FVector2D(1, 1))
      item.CanvasPanel_0:SetRenderOpacity(0)
      item:DelayPlayOpenAnimation(_IsOpen, #self.items - i + 1)
    else
      item:PlayOpenAnimation(_IsOpen)
    end
  end
end

function UMG_Battle_ChangePanel_C:DisposeShowAndHideContext(clearContextObject)
  clearContextObject = clearContextObject or true
  local state = self:GetState()
  local showContext = state and state.showContext
  if showContext then
    self:DisposeShowContext(showContext)
  end
  local hideContext = state and state.hideContext
  if hideContext then
    self:DisposeHideContext(hideContext)
  end
  if clearContextObject then
    local _, nextState = self:GetCurrAndNextState()
    nextState.showContext = nil
    nextState.hideContext = nil
    self:SetState(nextState)
  end
end

function UMG_Battle_ChangePanel_C:CancelOpenAnim()
  for i, item in ipairs(self.items) do
    item:SetRenderOpacity(1)
    item.CanvasPanel_0:SetRenderOpacity(1)
  end
end

function UMG_Battle_ChangePanel_C:OnVisibleRangeChangedCallback(newFirstVisibleIndex, newLastVisibleIndex, oldFirstVisibleIndex, oldLastVisibleIndex)
  newFirstVisibleIndex = newFirstVisibleIndex + 1
  newLastVisibleIndex = newLastVisibleIndex + 1
  local _, nextState = self:GetCurrAndNextState()
  nextState.visibleStartIndex = newFirstVisibleIndex
  nextState.visibleEndIndex = newLastVisibleIndex
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:GetItems()
  local items = self.items or {}
  local itemsToReturn = {}
  for i, item in ipairs(items) do
    if UE.UObject.IsValid(item) then
      table.insert(itemsToReturn, item)
    end
  end
  return itemsToReturn
end

function UMG_Battle_ChangePanel_C:DelayShowTimeout(contextId)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.showContext
  local currContextId = currContext and currContext.id
  if contextId ~= currContextId then
    return
  end
  local nextContext = {}
  table.copy(currContext, nextContext)
  nextContext.delayShowId = nil
  nextContext.delayShowTimeout = true
  nextState.showContext = nextContext
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:DelayItemShowTimeout(contextId, itemIndex)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.showContext
  local currContextId = currContext and currContext.id
  if contextId ~= currContextId then
    return
  end
  local currItemShowMap = currContext and currContext.itemShowMap or {}
  local currItemShowDelayIdMap = currContext and currContext.itemShowDelayIdMap or {}
  local nextItemShowMap = {}
  table.copy(currItemShowMap, nextItemShowMap)
  nextItemShowMap[itemIndex] = true
  local nextItemShowDelayIdMap = {}
  table.copy(currItemShowDelayIdMap, nextItemShowDelayIdMap)
  nextItemShowDelayIdMap[itemIndex] = nil
  local nextContext = {}
  table.copy(currContext, nextContext)
  nextContext.itemShowMap = nextItemShowMap
  nextContext.itemShowDelayIdMap = nextItemShowDelayIdMap
  nextState.showContext = nextContext
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:DelayHideCompleteTimeout(contextId)
  local currState, nextState = self:GetCurrAndNextState()
  local currContext = currState and currState.hideContext
  local currContextId = currContext and currContext.id
  if contextId ~= currContextId then
    return
  end
  local nextContext = {}
  table.copy(currContext, nextContext)
  nextContext.delayCompleteId = nil
  nextContext.delayCompleteTimeout = true
  nextState.hideContext = nextContext
  self:SetState(nextState)
end

function UMG_Battle_ChangePanel_C:DisposeShowContext(showContext)
  local delayShowId = showContext and showContext.delayShowId
  if delayShowId then
    self:CancelDelayByID(delayShowId)
  end
  local itemShowDelayIdMap = showContext and showContext.itemShowDelayIdMap or {}
  for i, id in pairs(itemShowDelayIdMap) do
    self:CancelDelayByID(id)
  end
end

function UMG_Battle_ChangePanel_C:DisposeHideContext(hideContext)
  local delayCompleteId = hideContext and hideContext.delayCompleteId
  if delayCompleteId then
    self:CancelDelayByID(delayCompleteId)
  end
end

function UMG_Battle_ChangePanel_C:OnTick(deltaTime)
  self.ArcScrollView:OnTick(deltaTime)
  local scrollPercentage = self.ArcScrollView:GetScrollOffset() / self.ArcScrollView:GetMaxScrollOffset()
  self:SetScrollBarPosition(scrollPercentage)
  self:SaveScrollOffset(self.ArcScrollView:GetScrollOffset())
  self.ArcScrollView.VelocityScale = 0
  self.ArcScrollView:SetScrollVelocityScale()
  local currentFrameScrollingState = self.ArcScrollView:GetScrollBoxHandleScrollingState()
  if currentFrameScrollingState and not self.lastFrameScrollingState then
    self:HandleStartScrolling()
  elseif currentFrameScrollingState and self.lastFrameScrollingState then
    self:HandleScrolling()
  elseif not currentFrameScrollingState and self.lastFrameScrollingState then
    self:HandleEndScrolling()
  end
  self.lastFrameScrollingState = currentFrameScrollingState
  self:UpdateIsUserScrollingSinceLastPress(deltaTime)
end

function UMG_Battle_ChangePanel_C:OnMouseWheel(MyGeometry, InTouchEvent)
  return self.ArcScrollView:OnMouseWheel(MyGeometry, InTouchEvent)
end

function UMG_Battle_ChangePanel_C:SetScrollBarLength(percentage)
  local maskVOffset = LuaMathUtils.LerpWithAlpha(0.47, 0, percentage)
  local maskUVRotation = 0
  if percentage < 0.5 then
    maskUVRotation = LuaMathUtils.LerpWithAlpha(-4, 12, percentage)
  else
    maskUVRotation = LuaMathUtils.LerpWithAlpha(8, 0, percentage)
  end
  if not self.arcScrollBarImageMaterial then
    self.arcScrollBarImageMaterial = self.W_line:GetDynamicMaterial()
  end
  if self.arcScrollBarImageMaterial then
    self.arcScrollBarImageMaterial:SetScalarParameterValue("MaskV_Offset", maskVOffset)
    self.arcScrollBarImageMaterial:SetScalarParameterValue("MaskUVRotation", maskUVRotation)
  end
end

function UMG_Battle_ChangePanel_C:SetScrollBarBackgroundSegment(segmentCount)
  if not self.scrollBackgroundDynamicMaterial then
    self.scrollBackgroundDynamicMaterial = self.B_line:GetDynamicMaterial()
  end
  if self.scrollBackgroundDynamicMaterial then
    self.scrollBackgroundDynamicMaterial:SetScalarParameterValue("N", segmentCount)
  end
end

function UMG_Battle_ChangePanel_C:GetScrollBarBackgroundSelectedSegmentIndex(percentage, segmentCount)
  local index = 0
  local segmentLeftValues = {0}
  if segmentCount > 1 then
    local middleSegmentLength = 1 / (segmentCount - 1)
    local sideSegmentLength = middleSegmentLength / 2
    table.insert(segmentLeftValues, sideSegmentLength)
    for i = 1, segmentCount do
      local leftValue = sideSegmentLength + i * middleSegmentLength
      if leftValue >= 1 then
        break
      end
      table.insert(segmentLeftValues, leftValue)
    end
    table.insert(segmentLeftValues, 1)
  end
  if #segmentLeftValues ~= segmentCount + 1 then
    Log.Info("UMG_BattleBallOperation_C:SetScrollBarBackgroundSegment \229\136\134\230\174\181\229\140\186\233\151\180\232\174\161\231\174\151\230\156\137\232\175\175\239\188\140\232\175\183\230\163\128\230\159\165", percentage, segmentCount)
    return index
  end
  if percentage <= 0 then
    index = 1
  elseif percentage >= 1 then
    index = segmentCount
  else
    for i = 1, #segmentLeftValues do
      local value = segmentLeftValues[i]
      if percentage > value then
        index = i
      else
        break
      end
    end
  end
  return index
end

function UMG_Battle_ChangePanel_C:SetScrollBarPosition(percentage)
  local alias = 0.05
  local state = self:GetState()
  local pageCount = state and state.pageCount or 1
  local indexValue = LuaMathUtils.LerpWithAlpha(1 - alias, pageCount + alias, percentage)
  if indexValue < 1 then
    indexValue = 1
  elseif pageCount < indexValue then
    indexValue = pageCount
  end
  if UE.UObject.IsValid(self.scrollBackgroundDynamicMaterial) then
    self.scrollBackgroundDynamicMaterial:SetScalarParameterValue("Index", indexValue)
  end
end

function UMG_Battle_ChangePanel_C:UpdateIsUserScrollingSinceLastPress(deltaTime)
  local prevIsUserScrollingSinceLastPress = self.isUserScrollingSinceLastPress
  local nextIsUserScrollingSinceLastPress = self:GetIsUserScrollingSinceLastPress()
  self.isUserScrollingSinceLastPress = nextIsUserScrollingSinceLastPress
  if prevIsUserScrollingSinceLastPress ~= nextIsUserScrollingSinceLastPress then
    self:OnIsUserScrollingSinceLastPressChanged(prevIsUserScrollingSinceLastPress, nextIsUserScrollingSinceLastPress)
  end
end

function UMG_Battle_ChangePanel_C:OnIsUserScrollingSinceLastPressChanged(prevValue, nextValue)
end

function UMG_Battle_ChangePanel_C:SaveScrollOffset(newOffset)
end

function UMG_Battle_ChangePanel_C:IsUserScrolling()
  return self.ArcScrollView.HandlingUserScrollingCurrentFrame
end

function UMG_Battle_ChangePanel_C:GetIsUserScrollingSinceLastPress()
  return self.scrollOverThresholdSinceLastPress or self:IsUserScrolling()
end

function UMG_Battle_ChangePanel_C:HandleStartScrolling()
  self.scrollOverThresholdSinceLastPress = false
  self.startPressOffset = nil
  self.endPressOffset = nil
  self.startPressOffset = self.ArcScrollView:GetScrollOffset()
end

function UMG_Battle_ChangePanel_C:HandleScrolling()
  if self.startPressOffset then
    local endPressOffset = self.ArcScrollView:GetScrollOffset()
    local diff = endPressOffset - self.startPressOffset
    if math.abs(diff) > BattleConst.BallOperationScrollToAnotherPageThreshold then
      self.scrollOverThresholdSinceLastPress = true
    end
  end
end

function UMG_Battle_ChangePanel_C:HandleEndScrolling()
  self.endPressOffset = self.ArcScrollView:GetScrollOffset()
  if self.startPressOffset and self.endPressOffset then
    local diff = self.endPressOffset - self.startPressOffset
    if math.abs(diff) > BattleConst.BallOperationScrollToAnotherPageThreshold then
      if diff > 0 then
        self.ArcScrollView:ScrollToNextPage()
      elseif diff < 0 then
        self.ArcScrollView:ScrollToLastPage()
      end
    end
  end
  self.scrollOverThresholdSinceLastPress = false
  self.startPressOffset = nil
  self.endPressOffset = nil
end

function UMG_Battle_ChangePanel_C.DeriveStateFromProps(prevState, nextProps)
  return prevState
end

function UMG_Battle_ChangePanel_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevBattleCardList = prevState and prevState.battleCardList
  local currBattleCardList = currState and currState.battleCardList
  local prevSelectPetGid = prevState and prevState.selectPetGid
  local currSelectPetGid = currState and currState.selectPetGid
  local prevBattleCardItemDataList = prevState and prevState.battleCardItemDataList or {}
  local currBattleCardItemDataList = currState and currState.battleCardItemDataList or {}
  local prevVisibleStartIndex = prevState and prevState.visibleStartIndex
  local currVisibleStartIndex = currState and currState.visibleStartIndex
  local prevVisibleEndIndex = prevState and prevState.visibleEndIndex
  local currVisibleEndIndex = currState and currState.visibleEndIndex
  local prevIndexToInputActionName = prevState and prevState.indexToInputActionName
  local currIndexToInputActionName = currState and currState.indexToInputActionName
  local prevVisibleIndexSet = prevState and prevState.visibleIndexSet
  local currVisibleIndexSet = currState and currState.visibleIndexSet
  local prevUpdatePcKeyFlag = prevState and prevState.updatePcKeyFlag
  local currUpdatePcKeyFlag = currState and currState.updatePcKeyFlag
  local prevShowContext = prevState and prevState.showContext
  local currShowContext = currState and currState.showContext
  local prevHideContext = prevState and prevState.hideContext
  local currHideContext = currState and currState.hideContext
  local prevIsShow = prevState and prevState.isShow
  local currIsShow = currState and currState.isShow
  local prevDataUpdateFlag = prevState and prevState.dataUpdateFlag
  local currDataUpdateFlag = currState and currState.dataUpdateFlag
  if not ValueEquals(prevBattleCardItemDataList, currBattleCardItemDataList) or prevIndexToInputActionName ~= currIndexToInputActionName or prevSelectPetGid ~= currSelectPetGid or prevUpdatePcKeyFlag ~= currUpdatePcKeyFlag or prevShowContext ~= currShowContext or prevHideContext ~= currHideContext or prevIsShow ~= currIsShow or prevDataUpdateFlag ~= currDataUpdateFlag then
    local deriveList = {}
    local sourceList = currBattleCardItemDataList
    local hasAnyChange = false
    local cardUpdateFlag = currDataUpdateFlag
    for i, item in ipairs(sourceList) do
      local currIsSelect = item and item.isSelect or false
      local currInputActionName = item and item.inputActionName
      local currItemUpdatePcKeyFlag = item and item.updatePcKeyFlag
      local curIsShow = item and item.isShow
      local currCardUpdateFlag = item and item.cardUpdateFlag
      local card = item and item.card
      local petGid = card and card.guid
      local nextIsSelect = petGid == currSelectPetGid and petGid or false
      local nextInputActionName = petGid and currIndexToInputActionName and currIndexToInputActionName[i]
      local nextIsShow = true
      local nextCardUpdateFlag = cardUpdateFlag
      if currShowContext then
        local itemShowMap = currShowContext and currShowContext.itemShowMap
        nextIsShow = false
        if itemShowMap and nil ~= itemShowMap[i] then
          nextIsShow = itemShowMap[i]
        end
      elseif currHideContext then
        nextIsShow = false
      else
        nextIsShow = currIsShow
      end
      if currIsSelect == nextIsSelect and currInputActionName == nextInputActionName and currUpdatePcKeyFlag == currItemUpdatePcKeyFlag and curIsShow == nextIsShow and currCardUpdateFlag == nextCardUpdateFlag then
        table.insert(deriveList, item)
      else
        hasAnyChange = true
        local nextItem = {}
        table.copy(item, nextItem)
        nextItem.isSelect = nextIsSelect
        nextItem.inputActionName = nextInputActionName
        nextItem.updatePcKeyFlag = currUpdatePcKeyFlag
        nextItem.isShow = nextIsShow
        nextItem.cardUpdateFlag = nextCardUpdateFlag
        table.insert(deriveList, nextItem)
      end
    end
    if hasAnyChange then
      derivedState.battleCardItemDataList = deriveList
    end
  end
  if prevBattleCardList ~= currBattleCardList then
    local onPetClickCallback = currState and currState.onPetClickCallback
    local onPetClickCallbackOwner = currState and currState.onPetClickCallbackOwner
    local onSpawnCallback = currState and currState.onSpawnCallback
    local onDeSpawnCallback = currState and currState.onDeSpawnCallback
    local changingBetweenSubPanels = currState and currState.changingBetweenSubPanels or false
    local cardList = currBattleCardList or {}
    local itemDataList = {}
    for i, card in ipairs(cardList) do
      local itemData = {}
      itemData.card = card
      local petGid = card and card.guid
      itemData.key = petGid
      itemData.index = i
      itemData.changingBetweenSubPanels = changingBetweenSubPanels
      itemData.onPetClickCallbackOwner = onPetClickCallbackOwner
      itemData.onPetClickCallback = onPetClickCallback
      itemData.onSpawnCallback = onSpawnCallback
      itemData.onDeSpawnCallback = onDeSpawnCallback
      table.insert(itemDataList, itemData)
    end
    local cardListLength = #cardList
    local pageCount = math.ceil(cardListLength / ItemCountPerPage)
    pageCount = math.max(pageCount, 1)
    local totalItemCount = pageCount * ItemCountPerPage
    for i = cardListLength + 1, totalItemCount do
      local itemData = {}
      itemData.key = string.format("pet-card-empty-slot-%s", i)
      itemData.index = i
      itemData.changingBetweenSubPanels = changingBetweenSubPanels
      itemData.onPetClickCallbackOwner = onPetClickCallbackOwner
      itemData.onPetClickCallback = onPetClickCallback
      itemData.onSpawnCallback = onSpawnCallback
      itemData.onDeSpawnCallback = onDeSpawnCallback
      table.insert(itemDataList, itemData)
    end
    derivedState.battleCardItemDataList = itemDataList
  end
  if not ValueEquals(prevBattleCardItemDataList, currBattleCardItemDataList) or prevVisibleStartIndex ~= currVisibleStartIndex or prevVisibleEndIndex ~= currVisibleEndIndex then
    local itemDataList = {}
    local startIndex = currVisibleStartIndex or 0
    local endIndex = currVisibleEndIndex or 0
    local indexToInputActionName = {}
    for i = startIndex, endIndex do
      local inputActionIndex = i - startIndex + 1
      local inputActionName = string.format("IA_BattleSelectItemStart_%s", tostring(inputActionIndex))
      indexToInputActionName[i] = inputActionName
    end
    derivedState.indexToInputActionName = indexToInputActionName
  end
  if not ValueEquals(prevVisibleIndexSet, currVisibleIndexSet) then
    local indexList = {}
    local indexSet = currVisibleIndexSet or {}
    for k, v in pairs(indexSet) do
      table.insert(indexList, k)
    end
    table.sort(indexList)
    local firstIndex = indexList and indexList[1] or 0
    local listLength = #indexList
    local lastIndex = indexList and indexList[listLength] or 0
    derivedState.visibleStartIndex = firstIndex
    derivedState.visibleEndIndex = lastIndex
  end
  if prevIsShow ~= currIsShow or prevShowContext ~= currShowContext or prevHideContext ~= currHideContext then
    local nextIsShowDisplay = currIsShow or nil ~= currShowContext or nil ~= currHideContext
    derivedState.isShowDisplay = nextIsShowDisplay
  end
  if not ValueEquals(prevBattleCardItemDataList, currBattleCardItemDataList) then
    local dataList = currBattleCardItemDataList or {}
    local itemCount = #dataList
    local pageCount = math.ceil(itemCount / ItemCountPerPage)
    pageCount = math.max(pageCount, 1)
    derivedState.pageCount = pageCount
  end
end

function UMG_Battle_ChangePanel_C:RenderWidget(prevProps, currProps, prevState, currState)
end

function UMG_Battle_ChangePanel_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevKey = prevProps and prevProps.key
  local currKey = currProps and currProps.key
  local prevVisibleStartIndex = prevState and prevState.visibleStartIndex
  local currVisibleStartIndex = currState and currState.visibleStartIndex
  local prevVisibleEndIndex = prevState and prevState.visibleEndIndex
  local currVisibleEndIndex = currState and currState.visibleEndIndex
  local prevShowContext = prevState and prevState.showContext
  local currShowContext = currState and currState.showContext
  local prevHideContext = prevState and prevState.hideContext
  local currHideContext = currState and currState.hideContext
  local prevPageCount = prevState and prevState.pageCount
  local currPageCount = currState and currState.pageCount
  local prevIsShow = prevState and prevState.isShow or false
  local currIsShow = currState and currState.isShow or false
  if prevKey == currKey or currKey == WidgetStateManager.InitKey then
  end
  local prevBattleCardItemDataList = prevState and prevState.battleCardItemDataList or {}
  local currBattleCardItemDataList = currState and currState.battleCardItemDataList or {}
  local prevIsShowDisplay = prevState and prevState.isShowDisplay or false
  local nextIsShowDisplay = currState and currState.isShowDisplay or false
  if prevIsShowDisplay ~= nextIsShowDisplay then
    local visibility = UE.ESlateVisibility.Collapsed
    if nextIsShowDisplay then
      visibility = UE4.ESlateVisibility.SelfHitTestInvisible
    end
    self:SetVisibility(visibility)
  end
  if prevKey ~= currKey and currKey == WidgetStateManager.InitKey then
    self.ArcScrollView:InitList({})
  end
  if prevBattleCardItemDataList ~= currBattleCardItemDataList then
    if #prevBattleCardItemDataList == #currBattleCardItemDataList then
      local listLength = #currBattleCardItemDataList
      for i = 1, listLength do
        local prevItem = prevBattleCardItemDataList[i]
        local nextItem = currBattleCardItemDataList[i]
        if prevItem ~= nextItem then
          local itemRef = {}
          itemRef.props = nextItem
          self.ArcScrollView:UpdateList(itemRef, i)
        end
      end
    else
      local itemRefList = {}
      for i, item in ipairs(currBattleCardItemDataList) do
        local itemRef = {}
        itemRef.props = item
        table.insert(itemRefList, itemRef)
      end
      self.ArcScrollView:InitList(itemRefList)
      self.ArcScrollView:NRCSetScrollOffset(0.1)
    end
    if #currBattleCardItemDataList > 0 then
      self.ArcScrollView:SetVisibility(UE.ESlateVisibility.Visible)
    end
  end
  if prevVisibleStartIndex ~= currVisibleStartIndex or prevVisibleEndIndex ~= currVisibleEndIndex then
    local startIndex = currVisibleStartIndex or 0
    local endIndex = currVisibleEndIndex or 0
    self.items = self.items or {}
    table.clear(self.items)
    for i = startIndex, endIndex do
      local item = self.ArcScrollView:GetItemByIndex(i - 1)
      local itemInstance = UE.UObject.IsValid(item) and item.UMG_Battle_Card
      if UE.UObject.IsValid(itemInstance) then
        table.insert(self.items, itemInstance)
      end
    end
  end
  if prevShowContext ~= currShowContext then
    local prevContextId = prevShowContext and prevShowContext.id
    local currContextId = currShowContext and currShowContext.id
    if prevContextId and currContextId then
      if prevContextId == currContextId then
        local prevDelayShowTimeout = prevShowContext and prevShowContext.delayShowTimeout or false
        local currDelayShowTimeout = currShowContext and currShowContext.delayShowTimeout or false
        local currPlayAnim = currShowContext and currShowContext.playAnim
        local prevShowDelayIdMap = prevShowContext and prevShowContext.itemShowDelayIdMap or {}
        local currShowDelayIdMap = currShowContext and currShowContext.itemShowDelayIdMap or {}
        local prevIsDelayStartPlayAnim = prevShowContext and prevShowContext.isDelayStartPlayAnim or false
        local currIsDelayStartPlayAnim = currShowContext and currShowContext.isDelayStartPlayAnim or false
        if not prevDelayShowTimeout and currDelayShowTimeout then
          local nextContext = {}
          table.copy(currShowContext, nextContext)
          nextContext.isWaitingForListUpdate = true
          local _, nextState = self:GetCurrAndNextState()
          nextState.showContext = nextContext
          self:SetState(nextState)
          self:Show(currPlayAnim)
        end
        if next(prevShowDelayIdMap) and next(currShowDelayIdMap) == nil then
          local nextContext = {}
          table.copy(currShowContext, nextContext)
          nextContext.isDelayStartPlayAnim = false
          local _, nextState = self:GetCurrAndNextState()
          nextState.showContext = nextContext
          self:SetState(nextState)
        end
        if prevIsDelayStartPlayAnim and not currIsDelayStartPlayAnim then
          Log.Info("[UMG_Battle_ChangePanel_C] delay show \230\147\141\228\189\156\230\137\167\232\161\140\229\174\140\230\136\144")
          local callback = currShowContext and currShowContext.callback
          if callback then
            tcall(nil, callback)
          end
          local _, nextState = self:GetCurrAndNextState()
          nextState.showContext = nil
          self:SetState(nextState)
        end
      end
    elseif nil == prevContextId and currContextId then
    else
      if not prevContextId or nil == currContextId then
      else
      end
    end
  end
  if prevBattleCardItemDataList ~= currBattleCardItemDataList then
    local contextId = currShowContext and currShowContext.id
    local isWaitingForListUpdate = currShowContext and currShowContext.isWaitingForListUpdate
    if isWaitingForListUpdate then
      local localState = self:GetState()
      local startIndex = localState and localState.visibleStartIndex or 0
      local endIndex = localState and localState.visibleEndIndex or 0
      local intervalSeconds = _G.BattleManager.battleRuntimeData.widgetSpeed.MainWindowSubPanelItemOpenInterval or 0.04
      local itemShowMap = {}
      local itemShowDelayIdMap = {}
      local showItemIndexList = {}
      for i, itemData in ipairs(currBattleCardItemDataList) do
        if i >= startIndex and i <= endIndex then
          table.insert(showItemIndexList, i)
        else
          itemShowMap[i] = true
        end
      end
      local reverseItemShowOrder = currShowContext and currShowContext.reverseItemShowOrder
      if reverseItemShowOrder then
        table.reverse(showItemIndexList)
      end
      for showAnimIndex, index in ipairs(showItemIndexList) do
        itemShowMap[index] = false
        local delayTime = intervalSeconds * showAnimIndex
        local delayId = self:DelaySeconds(delayTime, function()
          self:DelayItemShowTimeout(contextId, index)
        end)
        itemShowDelayIdMap[index] = delayId
      end
      local nextContext = {}
      table.copy(currShowContext, nextContext)
      nextContext.isWaitingForListUpdate = false
      nextContext.isDelayStartPlayAnim = true
      nextContext.itemShowMap = itemShowMap
      nextContext.itemShowDelayIdMap = itemShowDelayIdMap
      local _, nextState = self:GetCurrAndNextState()
      nextState.showContext = nextContext
      self:SetState(nextState)
    end
  end
  if prevHideContext ~= currHideContext then
    local prevContextId = prevHideContext and prevHideContext.id
    local currContextId = currHideContext and currHideContext.id
    if prevContextId and currContextId then
      if prevContextId == currContextId then
        local prevDelayCompleteTimeout = prevHideContext and prevHideContext.delayCompleteTimeout or false
        local currDelayCompleteTimeout = currHideContext and currHideContext.delayCompleteTimeout or false
        if not prevDelayCompleteTimeout and currDelayCompleteTimeout then
          Log.Info("[UMG_Battle_ChangePanel_C] hide \229\138\168\231\148\187 \230\147\141\228\189\156\230\137\167\232\161\140\229\174\140\230\136\144")
          local callback = currHideContext and currHideContext.callback
          if callback then
            tcall(nil, callback)
          end
          local _, nextState = self:GetCurrAndNextState()
          nextState.hideContext = nil
          self:SetState(nextState)
        end
      end
    elseif nil == prevContextId and currContextId then
    else
      if not prevContextId or nil == currContextId then
      else
      end
    end
  end
  if prevPageCount ~= currPageCount then
    local pageCount = currPageCount or 1
    pageCount = math.max(pageCount, 1)
    self:SetScrollBarBackgroundSegment(pageCount)
    if pageCount <= 1 then
      self.B_line:SetRenderOpacity(0)
      self.Arrow1:SetRenderOpacity(0)
      self.Arrow2:SetRenderOpacity(0)
      self.PCKey_Loader:SetRenderOpacity(0)
    else
      self.B_line:SetRenderOpacity(1)
      self.Arrow1:SetRenderOpacity(1)
      self.Arrow2:SetRenderOpacity(1)
      self.PCKey_Loader:SetRenderOpacity(1)
    end
  end
  if prevKey ~= currKey then
    self:ResetLineChange()
  end
  if prevIsShow ~= currIsShow then
    self:PlayLineShowAnim(currIsShow)
  end
end

function UMG_Battle_ChangePanel_C:ResetLineChange()
  local endTime = self.Line_Change_Out:GetEndTime()
  self:PlayAnimation(self.Line_Change_Out, endTime)
end

function UMG_Battle_ChangePanel_C:PlayLineShowAnim(isShow)
  if self:IsAnimationPlaying(self.Line_Change_in) then
    self:StopAnimation(self.Line_Change_in)
  end
  if self:IsAnimationPlaying(self.Line_Change_Out) then
    self:StopAnimation(self.Line_Change_Out)
  end
  if isShow then
    self:PlayAnimation(self.Line_Change_in)
  else
    self:PlayAnimation(self.Line_Change_Out)
  end
end

function UMG_Battle_ChangePanel_C:SelectChangePet(index)
  if index < 1 or index > self.ArcScrollView:GetItemCount() then
    return
  end
  local item = self.ArcScrollView:GetItemByIndex(index - 1)
  local itemInstance = UE.UObject.IsValid(item) and item.UMG_Battle_Card
  if UE.UObject.IsValid(itemInstance) then
    itemInstance:DoClick()
  end
end

function UMG_Battle_ChangePanel_C:GetChildWidgets()
  local childWidgets = {}
  local viewChildViews = self.viewChildViews or {}
  for i, viewChildView in ipairs(viewChildViews) do
    table.insert(childWidgets, viewChildView)
  end
  local itemCount = self.ArcScrollView:GetItemCount()
  for i = 1, itemCount do
    local itemView = self.ArcScrollView:GetItemByIndex(i - 1)
    table.insert(childWidgets, itemView)
  end
  return childWidgets
end

function UMG_Battle_ChangePanel_C:GetProps()
  return self.stateManager:GetProps()
end

function UMG_Battle_ChangePanel_C:GetState()
  return self.stateManager:GetProps()
end

function UMG_Battle_ChangePanel_C:GetState()
  return self.stateManager:GetState()
end

function UMG_Battle_ChangePanel_C:GetCurrAndNextState()
  return self.stateManager:GetCurrAndNextState()
end

function UMG_Battle_ChangePanel_C:SetProps(nextProps)
  self.stateManager:SetProps(nextProps)
end

function UMG_Battle_ChangePanel_C:SetState(nextState)
  self.stateManager:SetState(nextState)
end

return UMG_Battle_ChangePanel_C
