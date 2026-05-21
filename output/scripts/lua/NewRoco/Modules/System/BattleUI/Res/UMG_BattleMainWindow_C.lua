local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BuffUtils = require("NewRoco.Modules.Core.Battle.Entity.Components.Buff.BuffUtils")
local BattleField = require("NewRoco.Modules.Core.Battle.Common.BattleField")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local ProtoEnum = require("Data.PB.ProtoEnum")
local PVEModuleCmd = require("NewRoco.Modules.System.PVE.PVEModuleCmd")
local WidgetStateManager = require("Common.UI.WidgetStateManager")
local FsmEnum = require("NewRoco.Modules.Core.Fsm.FsmEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local UMG_BattleMainWindow_C = _G.NRCPanelBase:Extend("UMG_BattleMainWindow_C")
local WidgetShowType = {
  Hide = 0,
  Entering = 1,
  Show = 2,
  Exiting = 3
}
local chatButtonCanShowStateNameList = {
  BattleEnum.StateNames.RoundSelect,
  BattleEnum.StateNames.SwapSelect,
  BattleEnum.StateNames.SelectRidPet,
  BattleEnum.StateNames.EvolutionSelect,
  BattleEnum.StateNames.SwapPlay,
  BattleEnum.StateNames.RoundPlay,
  BattleEnum.StateNames.WaitingOther,
  BattleEnum.StateNames.TeamBattleCatch,
  BattleEnum.StateNames.TeamBeastBattleCatch,
  BattleEnum.StateNames.SeamlessOver,
  BattleEnum.StateNames.PVPOver,
  BattleEnum.StateNames.PVPRankOver,
  BattleEnum.StateNames.TerritoryTrialOver,
  BattleEnum.StateNames.WeeklyChallengeOver,
  BattleEnum.StateNames.TrainBattleOver,
  BattleEnum.StateNames.TeamBloodBattleOver,
  BattleEnum.StateNames.TeamBeastBattleOver
}
local recordButtonCanShowStateNameList = {
  BattleEnum.StateNames.RoundSelect,
  BattleEnum.StateNames.SwapSelect,
  BattleEnum.StateNames.SelectRidPet,
  BattleEnum.StateNames.EvolutionSelect,
  BattleEnum.StateNames.SwapPlay,
  BattleEnum.StateNames.RoundPlay,
  BattleEnum.StateNames.TeamBattleCatch,
  BattleEnum.StateNames.TeamBeastBattleCatch,
  BattleEnum.StateNames.SeamlessOver,
  BattleEnum.StateNames.PVPOver,
  BattleEnum.StateNames.PVPRankOver,
  BattleEnum.StateNames.TerritoryTrialOver,
  BattleEnum.StateNames.WeeklyChallengeOver,
  BattleEnum.StateNames.TrainBattleOver,
  BattleEnum.StateNames.TeamBloodBattleOver,
  BattleEnum.StateNames.TeamBeastBattleOver
}
local imcBattleName = BattleConst.ImcBattleName
local inputActionInfoListWhenIsShow = {
  {
    name = "IA_BattleSelectItemStart_1",
    method = "SelectBattleItemStart1"
  },
  {
    name = "IA_BattleSelectItemStart_2",
    method = "SelectBattleItemStart2"
  },
  {
    name = "IA_BattleSelectItemStart_3",
    method = "SelectBattleItemStart3"
  },
  {
    name = "IA_BattleSelectItemStart_4",
    method = "SelectBattleItemStart4"
  },
  {
    name = "IA_BattleSelectItemStart_5",
    method = "SelectBattleItemStart5"
  },
  {
    name = "IA_BattleSelectItemStart_6",
    method = "SelectBattleItemStart6"
  },
  {
    name = "IA_BattleSelectItemEnd_1",
    method = "SelectBattleItemEnd1"
  },
  {
    name = "IA_BattleSelectItemEnd_2",
    method = "SelectBattleItemEnd2"
  },
  {
    name = "IA_BattleSelectItemEnd_3",
    method = "SelectBattleItemEnd3"
  },
  {
    name = "IA_BattleSelectItemEnd_4",
    method = "SelectBattleItemEnd4"
  },
  {
    name = "IA_BattleSelectItemEnd_5",
    method = "SelectBattleItemEnd5"
  },
  {
    name = "IA_BattleSelectItemEnd_6",
    method = "SelectBattleItemEnd6"
  },
  {
    name = "IA_BattleSure",
    method = "OpenBattleSelectSure"
  },
  {
    name = "IA_BattleLeftSelect",
    method = "SelectPrePet"
  },
  {
    name = "IA_BattleRightSelect",
    method = "SelectNextPet"
  }
}
local battleRecordInputActionInfo = {
  name = "IA_BattleRecord",
  method = "OpenBattleRecord"
}
local battleChatInputActionInfo = {
  name = "IA_BattleChat",
  method = "OpenBattleChat"
}

function UMG_BattleMainWindow_C:OnConstruct()
  self.stateManager = WidgetStateManager()
  local initOption = {}
  initOption.owner = self
  initOption.UpdateDerivedState = self.UpdateDerivedState
  initOption.DeriveStateFromProps = self.DeriveStateFromProps
  initOption.RenderWidget = self.RenderWidget
  initOption.OnWidgetDidUpdate = self.OnWidgetDidUpdate
  local initState = {}
  initState.isShow = false
  initState.isInfoShow = false
  initState.infoShowType = WidgetShowType.Hide
  initState.isChatButtonShow = false
  initState.chatButtonShowType = WidgetShowType.Hide
  initState.isChatButtonShowDisplay = false
  initState.isRecordButtonShow = false
  initState.recordButtonShowType = WidgetShowType.Hide
  initState.isRecordButtonShowDisplay = false
  local petHpInfoList = {}
  for i = 1, 3 do
    local petHpInfo = {}
    petHpInfo.index = i
    petHpInfo.teamEnum = BattleEnum.Team.ENUM_TEAM
    table.insert(petHpInfoList, petHpInfo)
  end
  for i = 1, 2 do
    local petHpInfo = {}
    petHpInfo.index = i
    petHpInfo.teamEnum = BattleEnum.Team.ENUM_ENEMY
    table.insert(petHpInfoList, petHpInfo)
  end
  initState.petHpInfoList = petHpInfoList
  local petHpInfoListDisplay = {}
  for i, petHpInfo in ipairs(petHpInfoList) do
    table.insert(petHpInfoListDisplay, petHpInfo)
  end
  initState.petHpInfoListDisplay = petHpInfoListDisplay
  initState.hpBarsAndCardDecksConstructed = false
  initState.renderOpacity = 1
  initOption.initState = initState
  self.stateManager:Init(initOption)
  self.UmgLoaders = {
    [BattleEnum.Operation.ENUM_CATCH] = self.BallOperationLoader,
    [BattleEnum.Operation.ENUM_ITEM] = self.ItemOperationLoader,
    [BattleEnum.Operation.ENUM_CHANGE] = self.ChangePetPanelLoader,
    [BattleEnum.Operation.ENUM_SKILL] = self.SkillPanelLoader
  }
  self.isHpBarsAndCardDecksConstructed = false
  self.TeammateHPList = {}
  self.EnemyHPList = {}
  self.EnemyHpListAnimUMG = {}
  self.TeammateEnergies = {}
  self.EnemyEnergies = {}
  self.EnemyEnergiesAnimUMG = {}
  self.TeammateCardDecks = {}
  self.EnemyCardDecks = {}
  self.EnemyCardDecksAnimUMG = {}
  self.EnemyHpListShowAnim = {
    self.Change_right_1,
    self.Change_right_2
  }
  self.EnemyHpListHideAnim = {
    self.xiaoshi_right_1,
    self.xiaoshi_right_2
  }
  self.LeaderHpList = {}
  self.LeaderEnergies = {}
  self.LeaderCardDeck = {}
  self.is_show_resonance = false
  self.first_open_battle_rule = false
  self.isCanCatch = false
  self.TerritoryTrialEnemyInformationProps = {}
  if BattleUtils.IsTerritoryTrialBattle() then
    self.isTerritoryTrialEnemyInformationNeedLoad = true
  end
  self.ConstructHealthBarContext = au.Launch(UMG_BattleMainWindow_C.ConstructHealthBarAsync(self), function(ok, resultOrMessage)
    if not ok then
      Log.Error(resultOrMessage)
    end
    self.isHpBarsAndCardDecksConstructed = true
    self:OnHpBarsAndCardDecksConstructed(ok)
  end)
  self.ArriveTargetedPlayAnim = false
  self.IsPlayerSkillSuccess = false
  self._selectMarkerMgr = nil
  self.battleRules = nil
  local recordButtonSlotDelta = UE4.FMargin()
  if self:IsPCMode() then
    local Padding = UE4.FMargin()
    Padding.Left = 0
    Padding.Top = 22
    Padding.Right = 0
    Padding.Bottom = 0
    self.UMG_Battle_Operate.Slot:SetOffsets(Padding)
    recordButtonSlotDelta.Left = 100
    recordButtonSlotDelta.Top = recordButtonSlotDelta.Top + 60
  end
  do
    local BtnRecordSlot = self.Btn_Record.Slot
    local currentOffset = BtnRecordSlot:GetOffsets()
    local nextOffset = UE4.FMargin()
    nextOffset.Left = currentOffset.Left + recordButtonSlotDelta.Left
    nextOffset.Right = currentOffset.Right
    nextOffset.Top = currentOffset.Top + recordButtonSlotDelta.Top
    nextOffset.Bottom = currentOffset.Bottom
    BtnRecordSlot:SetOffsets(nextOffset)
    local BtnChatSlot = self.Btn_Chat.Slot
    local chatCurrentOffset = BtnChatSlot:GetOffsets()
    local chatNextOffset = UE4.FMargin()
    chatNextOffset.Left = chatCurrentOffset.Left + recordButtonSlotDelta.Left
    chatNextOffset.Right = chatCurrentOffset.Right
    chatNextOffset.Top = chatCurrentOffset.Top + recordButtonSlotDelta.Top
    chatNextOffset.Bottom = chatCurrentOffset.Bottom
    BtnChatSlot:SetOffsets(chatNextOffset)
  end
  self.RedDot:SetupKey(83)
  if _G.GlobalConfig.DebugOpenUI then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ClosePanelLobbyMain)
    self.UMG_Battle_Operate:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:LoadSubPanel(BattleEnum.Operation.ENUM_SKILL, nil, false)
  end
  self.counter = 0
  self.SpEnergyList.BattleMainWindow = self
  self.MultiPlayerTips:SetText("")
  self.PVPRoundRestTime = 0
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  _G.NRCEventCenter:RegisterEvent("UMG_BattleMainWindow_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:RegisterEvent("UMG_BattleMainWindow_C", self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  self:SetBattlePos()
  self.imcPriority = -1
  self:BindInputAction()
  self:ShowWeatherUI()
  BattleUtils.FixClickByVolatileOnPC(self.UMG_Battle_Operate)
end

function UMG_BattleMainWindow_C:SetBattleChatState(isShow)
  local isHide, _ = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_BATTLE_CHAT)
  if isHide then
    isShow = false
  end
  if isShow then
  else
  end
end

function UMG_BattleMainWindow_C:WaitingRecycle()
  if self.TeamHp then
    self.TeamHp:WaitingRecycle()
  end
  for _, v in ipairs(self.TeammateHPList) do
    local hpBar = v
    hpBar:WaitingRecycle()
  end
  for _, v in ipairs(self.EnemyHPList) do
    local hpBar = v
    hpBar:WaitingRecycle()
  end
  for _, v in ipairs(self.LeaderHpList) do
    local hpBar = v
    hpBar:WaitingRecycle()
  end
  self:UiRemoveInputMappingContext()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  if self.UMG_Battle_Operate and self.UMG_Battle_Operate.WaitingRecycle then
    self.UMG_Battle_Operate:WaitingRecycle()
  end
  if self.ChangePetPanel and self.ChangePetPanel.WaitingRecycle then
    self.ChangePetPanel:WaitingRecycle()
  end
  if self.BallOperation and self.BallOperation.WaitingRecycle then
    self.BallOperation:WaitingRecycle()
  end
  if self.ItemOperation and self.ItemOperation.WaitingRecycle then
    self.ItemOperation:WaitingRecycle()
  end
end

function UMG_BattleMainWindow_C:OnDestruct()
  if _G.GlobalConfig.DebugOpenUI then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OpenPanelLobbyMain)
  end
  local stateManager = self.stateManager
  if stateManager then
    stateManager:DeInit()
  end
  self:ReleaseDamageNumbers()
  table.clear(self.UmgLoaders)
  table.clear(self.TeammateEnergies)
  table.clear(self.TeammateHPList)
  table.clear(self.EnemyEnergies)
  table.clear(self.EnemyEnergiesAnimUMG)
  table.clear(self.EnemyHPList)
  table.clear(self.EnemyHpListAnimUMG)
  table.clear(self.EnemyCardDecksAnimUMG)
  table.clear(self.EnemyHpListShowAnim)
  table.clear(self.EnemyHpListHideAnim)
  table.clear(self.LeaderHpList)
  if self.ConstructHealthBarContext and a.live(self.ConstructHealthBarContext) then
    a.kill(self.ConstructHealthBarContext)
  end
  self.ConstructHealthBarContext = nil
  self.TeammateHPList = nil
  self.EnemyHPList = nil
  self.LeaderHpList = nil
  self.UmgLoaders = nil
  self.TeammateEnergies = nil
  self.EnemyEnergies = nil
  self.EnemyEnergiesAnimUMG = nil
  self.EnemyCardDecksAnimUMG = nil
  self.EnemyHpListAnimUMG = nil
  self.EnemyHpListShowAnim = nil
  self.EnemyHpListHideAnim = nil
  self.battleRules = nil
  self:CloseWeatherAnimDelay()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBuffInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnOnlineStateChanged, self.OnOnlineStateChanged)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_BattleSkillPlay")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
  if _G.EnableFakePVPRecord then
    _G.EnableFakePVPRecord = false
  end
end

function UMG_BattleMainWindow_C:OnActive()
  self.battleManager = _G.BattleManager
  self:OnAddEventListener()
  self.curRound = 1
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  self:PCKeySetting()
  self:InitChatBubbles()
  self._curOperateType = BattleEnum.Operation.ENUM_NONE
  self._validOperateType = BattleEnum.Operation.ENUM_NONE
  self._opBeforeHide = BattleEnum.Operation.ENUM_NONE
  self._opBeforeEscape = BattleEnum.Operation.ENUM_NONE
  self._inPanelChanging = false
  self._toOperateType = BattleEnum.Operation.ENUM_NONE
  self._isFocus = false
  self.roundUIStable = false
  self.needProcessEnergyTrack = false
  self.processEnergyTrackCount = 0
  self.battleRules = nil
  self.lastLoadedSubPanelOpType = BattleEnum.Operation.ENUM_NONE
  self.currentLoadedSubPanelOpType = BattleEnum.Operation.ENUM_NONE
  self.isShowing = false
  self.isBattleInputMappingContextAdded = false
  self.isRecordButtonInputAdded = false
  self:UpdateStateWithBattleType()
  self:UpdateStateWithFunctionBan()
  self:HideAll()
  self:TryInitData()
  if self.battleManager.isDefaultShowVisible then
    self:InitProcessVisible()
  end
  self:InitPopUpTips()
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    UE4.UNRCTUIStatics.ReleaseCursorCapture(0)
  end
end

function UMG_BattleMainWindow_C:SetPanelRenderOpacityState(renderOpacity)
  renderOpacity = renderOpacity or 1
  local _, nextState = self:GetCurrAndNextState()
  nextState.renderOpacity = renderOpacity
  self:SetState(nextState)
end

function UMG_BattleMainWindow_C:SetPanelRenderOpacity()
  if _G.IsSetRenderOpacity then
    local TeamPet, EnemyPet
    TeamPet = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
    EnemyPet = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY, true)
    if TeamPet then
      for i = 1, #TeamPet do
        if TeamPet[i].battlePetComponents then
          if 0 == _G.RenderOpacity then
            TeamPet[i].battlePetComponents:SetActorHiddenInGame(true)
          else
            TeamPet[i].battlePetComponents:SetActorHiddenInGame(false)
          end
        end
      end
    end
    if EnemyPet then
      for i = 1, #EnemyPet do
        if EnemyPet[i].battlePetComponents then
          if 0 == _G.RenderOpacity then
            EnemyPet[i].battlePetComponents:SetActorHiddenInGame(true)
          else
            EnemyPet[i].battlePetComponents:SetActorHiddenInGame(false)
          end
        end
      end
    end
    self:SetRenderOpacity(_G.RenderOpacity)
  end
end

function UMG_BattleMainWindow_C:RefreshRecordButtonShowState()
  if self.isRecordButtonShow == self.isRecordButtonShowDisplay then
    return
  end
  if self:IsAnimationPlaying(self.closeInfo) then
    return
  end
  if self.isRecordButtonShow ~= self.isRecordButtonShowDisplay then
    self.isRecordButtonShowDisplay = self.isRecordButtonShow
    if self.isRecordButtonShowDisplay then
    else
    end
  end
end

function UMG_BattleMainWindow_C:RefreshChatButtonShowState()
  if self.isChatButtonShow == self.isChatButtonShowCached then
    return
  end
  if self:IsAnimationPlaying(self.closeInfo) then
    return
  end
  self.isChatButtonShowCached = self.isChatButtonShow
  if self.isChatButtonShowCached then
    self:SetBattleChatState(true)
  else
    self:SetBattleChatState(false)
  end
end

function UMG_BattleMainWindow_C:OnDeactive()
  self:OnRemoveEventListener()
  self:ReleaseChatBubbles()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattlePopUpTips)
  if self.TeammateHPList then
    for _, v in pairs(self.TeammateHPList) do
      v:ClearTimer()
    end
  end
  if self.EnemyHPList then
    for _, v in pairs(self.EnemyHPList) do
      v:ClearTimer()
    end
  end
  if self.LeaderHpList then
    for _, v in pairs(self.LeaderHpList) do
      v:ClearTimer()
    end
  end
  self:CloseWeatherAnimDelay()
end

function UMG_BattleMainWindow_C:UiAddInputMappingContext()
  self:recordInputActionTrigger()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
  end
  self.isBattleInputMappingContextAdded = true
end

function UMG_BattleMainWindow_C:UiRemoveInputMappingContext()
  self:recordInputActionTrigger()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    mappingContext:DisableInputMappingContext()
  end
  self.isBattleInputMappingContextAdded = false
end

function UMG_BattleMainWindow_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext(imcBattleName, self.imcPriority)
  if mappingContext then
  end
end

function UMG_BattleMainWindow_C:BindInputActionWhenIsShow()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local actions = inputActionInfoListWhenIsShow or {}
    for _, action in ipairs(actions) do
      local name = action and action.name
      local method = action and action.method
      mappingContext:BindAction(name, self, method, UE.ETriggerEvent.Triggered)
    end
    self.UMG_Battle_Operate:BindInputAction()
  end
end

function UMG_BattleMainWindow_C:UnBindInputActionWhenIsHide()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local actions = inputActionInfoListWhenIsShow or {}
    for _, action in ipairs(actions) do
      local name = action and action.name
      mappingContext:UnBindAction(name)
    end
    self.UMG_Battle_Operate:UnBindInputAction()
  end
end

function UMG_BattleMainWindow_C:BindBattleRecordInputAction()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local action = battleRecordInputActionInfo
    local name = action and action.name
    local method = action and action.method
    mappingContext:BindAction(name, self, method, UE.ETriggerEvent.Triggered)
  end
end

function UMG_BattleMainWindow_C:UnBindBattleRecordInputAction()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local action = battleRecordInputActionInfo
    local name = action and action.name
    mappingContext:UnBindAction(name)
  end
end

function UMG_BattleMainWindow_C:BindBattleChatInputAction()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local action = battleChatInputActionInfo
    local name = action and action.name
    local method = action and action.method
    mappingContext:BindAction(name, self, method, UE.ETriggerEvent.Triggered)
  end
end

function UMG_BattleMainWindow_C:UnBindBattleChatInputAction()
  local mappingContext = self:GetInputMappingContext(imcBattleName)
  if mappingContext then
    local action = battleChatInputActionInfo
    local name = action and action.name
    mappingContext:UnBindAction(name)
  end
end

function UMG_BattleMainWindow_C:recordInputActionTrigger(inputActionName)
  self.triggerInputActionName = inputActionName
  self.UMG_Battle_Operate:recordInputActionTrigger(inputActionName)
  if self.UmgLoaders then
    for panelType, panelLoader in pairs(self.UmgLoaders) do
      local panel = self:GetSubPanel(panelType)
      if panel and panel.recordInputActionTrigger then
        panel:recordInputActionTrigger(inputActionName)
      end
    end
  end
end

function UMG_BattleMainWindow_C:SelectBattleItem(index, isPressd)
  if isPressd then
    if self.triggerInputActionName then
      return
    else
      self:recordInputActionTrigger("IA_BattleSelectItemStart_" .. index)
    end
    self.lastSelectOperateType = self._toOperateType
    self.laseSelectItemIndex = index
  else
    if self.triggerInputActionName ~= "IA_BattleSelectItemStart_" .. index then
      return
    end
    self:recordInputActionTrigger()
    self.lastSelectOperateType = nil
    self.laseSelectItemIndex = nil
  end
  if self.UmgLoaders[self._toOperateType] then
    local panel = self:GetSubPanel(self._toOperateType)
    if panel then
      panel:SelectItem(index, isPressd)
    end
  end
end

function UMG_BattleMainWindow_C:OpenBattleRecord()
  if self.triggerInputActionName then
    return
  end
  if self.Btn_Record:GetVisibility() == UE4.ESlateVisibility.Visible or self.Btn_Record:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self:TryCloseSubPanelTips()
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
    self.triggerInputActionName = "btn_record"
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Open_Information_Recording, self.curRound)
  end
end

function UMG_BattleMainWindow_C:OpenBattleChat()
  self:OnBtnChatClicked()
end

function UMG_BattleMainWindow_C:OpenBattleSelectSure()
  if BattleManager.SelectTargetManager:GetCurSelectPet() then
    BattleManager.SelectTargetManager:EnsureCurSelect()
  end
end

function UMG_BattleMainWindow_C:SelectPrePet()
  if BattleManager.SelectTargetManager:GetCurSelectPet() then
    BattleManager.SelectTargetManager:SelectPre()
  end
end

function UMG_BattleMainWindow_C:SelectNextPet()
  if BattleManager.SelectTargetManager:GetCurSelectPet() then
    BattleManager.SelectTargetManager:SelectNext()
  end
end

function UMG_BattleMainWindow_C:SelectBattleItemStart1()
  self:SelectBattleItem(1, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemStart2()
  self:SelectBattleItem(2, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemStart3()
  self:SelectBattleItem(3, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemStart4()
  self:SelectBattleItem(4, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemStart5()
  self:SelectBattleItem(5, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemStart6()
  self:SelectBattleItem(6, true)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd1()
  self:SelectBattleItem(1)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd2()
  self:SelectBattleItem(2)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd3()
  self:SelectBattleItem(3)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd4()
  self:SelectBattleItem(4)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd5()
  self:SelectBattleItem(5)
end

function UMG_BattleMainWindow_C:SelectBattleItemEnd6()
  self:SelectBattleItem(6)
end

function UMG_BattleMainWindow_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Record, self.TryOpenRecord)
  self:AddButtonListener(self.Btn_Chat, self.OnBtnChatClicked)
  self:AddButtonListener(self.Btn_characteristic, self.OnBtnCharacteristic)
  self:AddButtonListener(self.Btn_GiveUp, self.OnBtnGiveUp)
  self.Btn_GiveUp.OnPressed:Add(self, self.OnGiveUpPressed)
  self.Btn_GiveUp.OnReleased:Add(self, self.OnGiveUpReleased)
  self.TerritoryTrialEnemyInformationLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnTerritoryTrialUILoaded)
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_PET_CATCH_SUCCESS, BattleEvent.BATTLE_PET_DIE, BattleEvent.PLAYER_SPAWNED, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.PET_SPAWNED, BattleEvent.PET_DISTROYED, BattleEvent.ON_CLICK_ESCAPE, BattleEvent.MULTI_PLAYER_TIP_CHANGE, BattleEvent.UPDATE_DATA, BattleEvent.PLAYER_LEAVE_GAME, BattleEvent.START_PVP_ROUND_TIME, BattleEvent.END_PVP_ROUND_TIME, BattleEvent.Show_RecordingBtn, BattleEvent.ARRIVE_TARGETED_SHOW_ENEMY_HP, BattleEvent.CHEER_SWITCH, BattleEvent.CHEER_ESCAPE, BattleEvent.SHOW_NO_MOVE_HP, BattleEvent.UI_SET_BATTLE_POS, BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL, BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL, BattleEvent.START_BATTLE_PERFORM, BattleEvent.BATTLE_PLAYERSKILL_ISHIDE_HP, BattleEvent.BATTLE_PLAYERSKILL_PERFORMING_UPDATE, BattleEvent.ON_CLICK_STEPAWAY, BattleEvent.ON_CLICK_GIVEUP, BattleEvent.INPUT_ACTION_TRIGGER, BattleEvent.ROUND_START, BattleEvent.SimulateClickBag, BattleEvent.PlayUIAnimation, BattleEvent.ReconnetBattle_RoundStrart, BattleEvent.REFRESH_BUFF, BattleEvent.ShowResonanceTip, BattleEvent.NightmareShieldBreak, BattleEvent.BoxShieldBreak, BattlePerformEvent.AiPerformStart, BattlePerformEvent.AiPerformOver)
  local battleManager = _G.BattleManager
  local battleStateFsm = battleManager and battleManager.stateFsm
  if battleStateFsm then
    battleStateFsm:RegisterEvent(FsmEnum.Events.EnterState, self, self.HandleBattleFsmStateChanged)
    battleStateFsm:RegisterEvent(FsmEnum.Events.ExitAction, self, self.HandleBattleFsmActionExit)
  end
end

function UMG_BattleMainWindow_C:OnRemoveEventListener()
  local battleManager = _G.BattleManager
  local battleStateFsm = battleManager and battleManager.stateFsm
  if battleStateFsm then
    battleStateFsm:RemoveEvent(FsmEnum.Events.EnterState, self, self.HandleBattleFsmStateChanged)
    battleStateFsm:RemoveEvent(FsmEnum.Events.ExitAction, self, self.HandleBattleFsmActionExit)
  end
  self:RemoveButtonListener(self.Btn_characteristic, self.OnBtnCharacteristic)
  self:RemoveButtonListener(self.Btn_GiveUp, self.OnBtnGiveUp)
  self.Btn_GiveUp.OnPressed:Remove(self, self.OnGiveUpPressed)
  self.Btn_GiveUp.OnReleased:Remove(self, self.OnGiveUpReleased)
  self.TerritoryTrialEnemyInformationLoader.OnLoadPanelCallbackDelegate:Remove(self, self.OnTerritoryTrialUILoaded)
  _G.BattleEventCenter:UnBind(self)
end

function UMG_BattleMainWindow_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_PET_CATCH_SUCCESS then
    self:RefreshCardDeck(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PET_DIE then
    self:RefreshCardDeck(...)
    return true
  elseif eventName == BattleEvent.PLAYER_SPAWNED then
    self:OnPlayerSpawnEvent(...)
    return true
  elseif eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    BattleUtils.IgnoreLocking(true)
    self:OnOperatePanelChangedClick(...)
    BattleUtils.IgnoreLocking(false)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:OnPetSpawnEvent(...)
    return true
  elseif eventName == BattleEvent.PET_DISTROYED then
    self:RefreshCardDeck(...)
    return true
  elseif eventName == BattleEvent.ON_CLICK_ESCAPE then
    self:OnDialogCallback((...), BattleEnum.RunAwayType.ClickEscape)
    return true
  elseif eventName == BattleEvent.MULTI_PLAYER_TIP_CHANGE then
    local context = (...)
    context = context or {}
    local content = context.content or ""
    self:ChangeMultiPlayer(content)
    return true
  elseif eventName == BattleEvent.UPDATE_DATA then
    self:UpdateData(...)
    return true
  elseif eventName == BattleEvent.PLAYER_LEAVE_GAME then
    self:PlayerLeaveGame(...)
    return true
  elseif eventName == BattleEvent.START_PVP_ROUND_TIME then
    self:StartPVPRoundTime(...)
    return true
  elseif eventName == BattleEvent.END_PVP_ROUND_TIME then
    self:EndPVPRoundTime()
    return true
  elseif eventName == BattleEvent.Show_RecordingBtn then
    self.triggerInputActionName = nil
    return true
  elseif eventName == BattleEvent.ARRIVE_TARGETED_SHOW_ENEMY_HP then
    self:ArriveTargetedShowPetInfo()
    return true
  elseif eventName == BattleEvent.CHEER_SWITCH then
    self:OnCheerSwitch(...)
    return true
  elseif eventName == BattleEvent.CHEER_ESCAPE then
    self:RefreshCardDeck(...)
    return true
  elseif eventName == BattleEvent.SHOW_NO_MOVE_HP then
    self:ShowNoMoveHP(...)
    return true
  elseif eventName == BattleEvent.UI_SET_BATTLE_POS then
    self:SetBattlePos()
    return true
  elseif eventName == BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL then
    self:BeginUsePlayerSkill()
    return true
  elseif eventName == BattleEvent.BATTLE_CANCEL_USE_PLAYERSKILL then
    self:CancelUsePlayerSkill(...)
    return true
  elseif eventName == BattleEvent.START_BATTLE_PERFORM then
    self:StartPerform(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PLAYERSKILL_ISHIDE_HP then
    self:IsHideHp(...)
    return true
  elseif eventName == BattleEvent.BATTLE_PLAYERSKILL_PERFORMING_UPDATE then
    local isPlayerSkillPerforming = (...)
    local _, nextState = self:GetCurrAndNextState()
    nextState.isPlayerSkillPerforming = isPlayerSkillPerforming
    self:SetState(nextState)
    return true
  elseif eventName == BattleEvent.ON_CLICK_STEPAWAY then
    self:OnStepAwayDialogCallback(...)
    return true
  elseif eventName == BattleEvent.ON_CLICK_GIVEUP then
    self:OnDialogCallback((...), BattleEnum.RunAwayType.ClickEscape)
    return true
  elseif eventName == BattleEvent.INPUT_ACTION_TRIGGER then
    self:recordInputActionTrigger(...)
    return true
  elseif eventName == BattleEvent.ROUND_START then
    self:CheckTerritoryTrialBattleHp()
    self:RefreshFinalBattleUI()
    self:RefreshCardDeck(...)
    self:UpdateCanCatchState()
    self:StopHpWarning()
    self:TryShowEnemyPetsDifferentColors()
    local _, nextState = self:GetCurrAndNextState()
    nextState.isPlayerSkillPerforming = false
    self:SetState(nextState)
    return true
  elseif eventName == BattleEvent.SimulateClickBag then
    self:ChangeOperateMode(BattleEnum.Operation.ENUM_ITEM)
    return true
  elseif eventName == BattleEvent.PlayUIAnimation then
    self:EffectPlayUIAnimation(...)
    return true
  elseif eventName == BattleEvent.ReconnetBattle_RoundStrart then
    self.UMG_Battle_Operate:InitializePlayerSkill()
    local SkillPanel = self:GetSubPanel(BattleEnum.Operation.ENUM_SKILL)
    if SkillPanel then
      SkillPanel:CheckShowB1FinalBattleP3GuideLight(true)
    end
    return true
  elseif eventName == BattleEvent.REFRESH_BUFF then
    local battlePet = (...)
    if battlePet == self.pet then
      self:OnBuffRefresh()
    end
    return true
  elseif eventName == BattlePerformEvent.AiPerformStart then
    local aiPerform = (...)
    self:HandleAiPerformStart(aiPerform)
    return true
  elseif eventName == BattlePerformEvent.AiPerformOver then
    local aiPerform = (...)
    self:HandleAiPerformOver(aiPerform)
    return true
  elseif eventName == BattleEvent.ShowResonanceTip then
    self:ShowResonanceTip()
  elseif eventName == BattleEvent.NightmareShieldBreak then
    local battlePet = (...)
    self:OnPetShieldBreak(battlePet)
  elseif eventName == BattleEvent.BoxShieldBreak then
    local battlePet = (...)
    self:OnPetShieldBreak(battlePet)
  end
end

function UMG_BattleMainWindow_C:ShowResonanceTip()
  if self.is_show_resonance then
    return
  end
  local isPrePlay = _G.BattleManager.stateFsm:GetProperty("IsPreplay")
  if not isPrePlay then
    return
  end
  local battle_config = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleConfig or nil
  if battle_config and 0 == battle_config.feature_resonance then
    return
  end
  if UE4.ESlateVisibility.Collapsed == self.ResonancePlane:GetVisibility() then
    self.is_show_resonance = true
    self.ResonancePlane:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Resonance_In)
    _G.NRCAudioManager:PlaySound2DAuto(1152, "UMG_BattleMainWindow_C:ShowResonanceTip")
  end
end

function UMG_BattleMainWindow_C:HideResonanceTip()
  self.ResonancePlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleMainWindow_C:OnPetShieldBreak(battlePet)
  self:UpdateCanCatchState()
  local battleCard = battlePet and battlePet.card
  local petInfo = battleCard and battleCard.petInfo
  local commonPetInfo = petInfo and petInfo.battle_common_pet_info
  local mutationType = commonPetInfo and commonPetInfo.mutation_type
  if PetMutationUtils.GetMutationValue(mutationType, _G.Enum.MutationDiffType.MDT_SHINING) then
    _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.OpenBattlePopUpDiscoveringDifferentlyColoredPetTips, 2.5)
  end
  self:TryShowPetDifferentColors(battlePet)
end

function UMG_BattleMainWindow_C:TryShowEnemyPetsDifferentColors()
  local state = self:GetState()
  local enemyPetMap = state and state.enemyPetPosMap or {}
  for i, enemyPet in pairs(enemyPetMap) do
    self:TryShowPetDifferentColors(enemyPet)
  end
end

function UMG_BattleMainWindow_C:TryShowPetDifferentColors(battlePet)
  local battleCard = battlePet and battlePet.card
  local petInfo = battleCard and battleCard.petInfo
  local commonPetInfo = petInfo and petInfo.battle_common_pet_info
  local mutationType = commonPetInfo and commonPetInfo.mutation_type
  local isShining = PetMutationUtils.GetMutationValue(mutationType, _G.Enum.MutationDiffType.MDT_SHINING)
  local battlePetComponents = battlePet and battlePet.battlePetComponents
  local isCanCatch = self.isCanCatch or false
  local showShining = isCanCatch and isShining
  if battlePetComponents then
    battlePetComponents:SetIsDifferentColorsPet(showShining)
  end
end

function UMG_BattleMainWindow_C:ShowBattleSkillPickPanel(_IsShow)
  if BattleUtils.IsWorldLeaderFight() then
    local rewardCount = BattleUtils.GetWorldLeaderRewardCount()
    if rewardCount > 1 then
      _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.OpenSkillPickPanel, _IsShow)
    end
  end
end

function UMG_BattleMainWindow_C:StartPerform(performPlayer, cmd)
  NRCModeManager:DoCmd(BattleUIModuleCmd.SavePreProcessCmd, cmd)
end

function UMG_BattleMainWindow_C:IsHideHp(IsShow)
  Log.Debug(IsShow, self:IsAnimationPlaying(self.closeInfo), self:IsAnimationPlaying(self.openInfo), "UMG_BattleMainWindow_C:IsHideHp")
  local _, nextState = self:GetCurrAndNextState()
  nextState.isInfoShow = IsShow or false
  self:SetState(nextState)
  if IsShow then
    if not self:IsAnimationPlaying(self.openInfo) then
      self:ShowHPBars()
      self:PlayAnimation(self.openInfo)
    end
  elseif not self:IsAnimationPlaying(self.closeInfo) then
    self:HideHPBars()
  end
end

function UMG_BattleMainWindow_C:ChangeHpTypeByBattleType()
  local isHideSpPanel = false
  if BattleUtils.IsTeam() then
    isHideSpPanel = true
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetGroupWarfare, true)
  else
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetGroupWarfare, false)
  end
  if BattleUtils.IsB1FinalBattleP3() then
    isHideSpPanel = true
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetTheFinalBattle, true)
  else
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetTheFinalBattle, false)
  end
  if isHideSpPanel then
    self.HpPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    self.HpPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BattleMainWindow_C:UnBindHpEvent()
end

function UMG_BattleMainWindow_C:SetBattlePos()
  local lastBattleEnterPoint = BattleField.debugLastEnterBattlePoint
  local lastForward = BattleField.debugLastEnterBattleRotateBit or -1
  if lastBattleEnterPoint then
    local Text
    local AnsStr = ""
    if BattleField.debugBattleFieldResultPrint then
      local debugLastBattleFieldAns = BattleField.debugLastBattleFieldAns
      AnsStr = string.format(" / \231\187\147\230\158\156:X = %s,Y = %s,Z = %s,Rotate:%d", debugLastBattleFieldAns.X, debugLastBattleFieldAns.Y, debugLastBattleFieldAns.Z, BattleField.debugLastBattleFieldRotateAns)
    end
    if BattleField.debugLastUseFullStation == true then
      Text = string.format("\230\136\152\230\150\151\229\133\165\229\143\163\229\157\144\230\160\135:X = %s,Y = %s,Z = %s(\229\133\168\231\171\153\228\189\141, \230\150\185\229\144\145:%d)%s", lastBattleEnterPoint.X, lastBattleEnterPoint.Y, lastBattleEnterPoint.Z, lastForward, AnsStr)
    elseif BattleField.debugLastUseFullStation == false then
      Text = string.format("\230\136\152\230\150\151\229\133\165\229\143\163\229\157\144\230\160\135:X = %s,Y = %s,Z = %s(\233\157\158\229\133\168\231\171\153\228\189\141, \230\150\185\229\144\145:%d)%s", lastBattleEnterPoint.X, lastBattleEnterPoint.Y, lastBattleEnterPoint.Z, lastForward, AnsStr)
    else
      Text = string.format("\230\136\152\230\150\151\229\133\165\229\143\163\229\157\144\230\160\135:X = %s,Y = %s,Z = %s(\230\156\170\231\159\165\231\171\153\228\189\141, \230\150\185\229\144\145:%d)%s", lastBattleEnterPoint.X, lastBattleEnterPoint.Y, lastBattleEnterPoint.Z, lastForward, AnsStr)
    end
    self.Position:SetText(Text)
  else
    local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      local playerLoc = player.viewObj:Abs_K2_GetActorLocation()
      if playerLoc then
        local Text = string.format("\230\156\170\230\156\137\228\184\138\230\172\161\230\136\152\230\150\151\230\159\165\232\175\162\229\157\144\230\160\135\239\188\140\231\142\169\229\174\182\228\189\141\231\189\174:X = %s,Y = %s,Z = %s", playerLoc.X, playerLoc.Y, playerLoc.Z)
        self.Position:SetText(Text)
      else
        self.Position:SetText("\230\156\170\230\156\137\228\184\138\230\172\161\230\136\152\230\150\151\230\159\165\232\175\162\229\157\144\230\160\135\239\188\140\230\156\170\230\137\190\229\136\176\231\142\169\229\174\182\228\189\141\231\189\174")
      end
    else
      Log.Error("MG_BattleMainWindow_C:SetBattlePos, Local player is not exist")
    end
  end
  if not _G.BattlePosition and not RocoEnv.IS_SHIPPING then
    self.BattlePosition:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BattlePosition:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BattleMainWindow_C:BeginUsePlayerSkill()
  self:UnLoadSubPanelWithAnim(BattleEnum.Operation.ENUM_ITEM, false)
  self:LoadSubPanel(BattleEnum.Operation.ENUM_CHANGE, self.pet, true)
end

function UMG_BattleMainWindow_C:CancelUsePlayerSkill(curIndex)
  Log.Debug(self._curOperateType, curIndex, "UMG_BattleMainWindow_C:CancelUsePlayerSkill")
  local curSubPanelOpType = self.currentLoadedSubPanelOpType
  if 1 == curIndex then
    self:LoadSubPanel(BattleEnum.Operation.ENUM_ITEM, self.pet, true)
  end
  if curSubPanelOpType == BattleEnum.Operation.ENUM_CHANGE then
    self:UnLoadSubPanelWithAnim(BattleEnum.Operation.ENUM_CHANGE, false)
  end
end

function UMG_BattleMainWindow_C:ShowWeatherUI()
  do return end
  local weatherConf = _G.DataConfigManager:GetWeatherConf(_G.BattleManager.battleRuntimeData.curWeatherID)
  if not weatherConf or not weatherConf.show_icon then
  else
    self.WeatherIcon:SetPath(weatherConf.show_icon)
  end
end

function UMG_BattleMainWindow_C:UpdateWeatherUI()
  do return end
  local weatherConf = _G.DataConfigManager:GetWeatherConf(_G.BattleManager.battleRuntimeData.curWeatherID)
  if not weatherConf or not weatherConf.show_icon then
  else
    self.WeatherIcon:SetPath(weatherConf.show_icon)
    self:CloseWeatherAnimDelay()
    self.WeatherAnimId = _G.DelayManager:DelaySeconds(0.2, function()
      if self and UE4.UObject.IsValid(self) then
        self:PlayAnimation(self.WeatherButton_In)
      end
    end)
  end
end

function UMG_BattleMainWindow_C:CloseWeatherAnimDelay()
  if self.WeatherAnimId then
    _G.DelayManager:CancelDelayById(self.WeatherAnimId)
  end
  self.WeatherAnimId = nil
end

function UMG_BattleMainWindow_C:TryOpenWeather()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenWeatherTips)
end

function UMG_BattleMainWindow_C:TryCloseWeather()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseWeatherTips)
end

function UMG_BattleMainWindow_C:TryOpenRecord()
  Log.Warning("UMG_BattleMainWindow_C:TryOpenRecord")
  if _G.BattleManager.battleRuntimeData.IsWaitRoundFlowFinishRSP then
    return
  end
  if self.lastSelectOperateType == self._curOperateType and self.laseSelectItemIndex then
    self:SelectBattleItem(self.laseSelectItemIndex)
  end
  if self.UmgLoaders[self._curOperateType] then
    local panel = self:GetSubPanel(self._curOperateType)
    if panel and panel.ReleasePcKey then
      panel:ReleasePcKey()
    end
  end
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Open_Information_Recording, self.curRound)
end

function UMG_BattleMainWindow_C:OnBtnChatClicked()
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed or self:GetVisibility() == UE4.ESlateVisibility.Hidden then
    return
  end
  if self.Btn_Chat and self.Btn_Chat:GetVisibility() ~= UE4.ESlateVisibility.Visible then
    return
  end
  local isUIFunctionBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_BATTLE_CHAT, true)
  if isUIFunctionBan then
    Log.Warning("UMG_BattleMainWindow_C:OnBtnChatClicked, Chat function is banned in battle.")
    return
  end
  local bOpenByQuickChat = false
  local bOpenInBattle = true
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenChatMainPanel, 0, nil, nil, bOpenByQuickChat, bOpenInBattle)
end

function UMG_BattleMainWindow_C:SetShowForRecordingAndChatBtn(isShow, isChatButtonShow)
  if nil == isChatButtonShow then
    isChatButtonShow = isShow
  end
  if BattleUtils.IsB1FinalBattleP3() or BattleUtils.IsB1FinalBattleP2() then
    isShow = false
    isChatButtonShow = false
  end
  if BattleUtils.IsTeam() then
    isShow = false
  end
  self.isRecordButtonShow = isShow
  self.isChatButtonShow = isChatButtonShow
  local prevRecordButtonInputAdded = self.isRecordButtonInputAdded
  local nextRecordButtonInputAdded = self.isRecordButtonShow and not self.isBattleInputMappingContextAdded
  self.isRecordButtonInputAdded = nextRecordButtonInputAdded
  if nextRecordButtonInputAdded ~= prevRecordButtonInputAdded then
    if nextRecordButtonInputAdded then
      self:AddInputMappingContext("IMC_BattleSkillPlay")
    else
      self:RemoveInputMappingContext("IMC_BattleSkillPlay")
    end
  end
  self:RefreshRecordButtonShowState()
  self:RefreshChatButtonShowState()
end

function UMG_BattleMainWindow_C:InitProcessVisible()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleProcessUI)
end

function UMG_BattleMainWindow_C:ReleaseDamageNumbers()
  if not self.DamageNumber then
    return
  end
  for _, Widget in wpairs(self.DamageNumber) do
    if Widget and Widget:IsValid() then
      Widget:Release()
    end
  end
  self.DamageNumber:ClearChildren()
end

function UMG_BattleMainWindow_C:TryInitData()
  local teamPlayers = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  if teamPlayers then
    for _, v in ipairs(teamPlayers) do
      self:SetCardDeck(v.player)
    end
  end
  local enemyPlayers = _G.BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)
  if enemyPlayers then
    for _, v in ipairs(enemyPlayers) do
      self:SetCardDeck(v.player)
    end
  end
  self.SpEnergyList:InitByData()
  self:SetupHPAndEnergy()
  if not _G.BattleManager.battleRuntimeData:IsInReplayMode() then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Close_ReplayPanel)
  else
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Open_ReplayPanel)
  end
end

function UMG_BattleMainWindow_C:SetSelectMarkerMgr(selectMarkerMgr)
  self._selectMarkerMgr = selectMarkerMgr
end

function UMG_BattleMainWindow_C:UpdateData(pet, isUpdateChange)
  self.pet = pet
  self.UMG_Battle_Operate:SetGuid(pet.card.guid, pet)
  self:OnBuffRefresh()
  self:UpdateStateWithBattleType()
end

function UMG_BattleMainWindow_C:PlayerLeaveGame(player, forceHideHP)
  local hpList, energyList, cardDeckList
  if player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    hpList = self.TeammateHPList
    energyList = self.TeammateEnergies
    cardDeckList = self.TeammateCardDecks
  elseif BattleUtils.IsWorldLeaderFight() then
    hpList = self.LeaderHpList
    energyList = self.LeaderEnergies
    cardDeckList = self.LeaderCardDeck
  else
    hpList = self.EnemyHPList
    energyList = self.EnemyEnergies
    cardDeckList = self.EnemyCardDecks
  end
  for _, v in ipairs(hpList) do
    if v.battlePet and v.battlePet.player == player then
      v:PlayerLeave(forceHideHP)
      v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  for _, v in ipairs(energyList) do
    if v.battlePet and v.battlePet.player == player then
      v:PlayerLeave()
      v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  for _, v in ipairs(cardDeckList) do
    if v.player and v.player == player then
      v:PlayerLeave()
      v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_BattleMainWindow_C:InactivePetUI(pet)
  if pet then
    local hpList
    if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
      hpList = self.TeammateHPList
    elseif BattleUtils.IsWorldLeaderFight() then
      hpList = self.LeaderHpList
    else
      hpList = self.EnemyHPList
    end
    for _, v in ipairs(hpList) do
      if v.battlePet and v.battlePet == pet then
        v:PetNone()
      end
    end
  end
end

function UMG_BattleMainWindow_C:HidePetUI(pet, isDelayHideHp)
  local petGuid = pet and pet.guid
  local currState, nextState = self:GetCurrAndNextState()
  local currPetHpInfoList = currState and currState.petHpInfoList or {}
  local nextPetHpInfoList = {}
  table.copy(currPetHpInfoList, nextPetHpInfoList)
  local hasAnyChange = false
  for i, petHpInfo in ipairs(currPetHpInfoList) do
    local petHpInfoPetGuid = petHpInfo and petHpInfo.petGid
    if petHpInfoPetGuid == petGuid then
      local nextPetHpInfo = {}
      table.copy(petHpInfo, nextPetHpInfo)
      nextPetHpInfo.petGid = nil
      nextPetHpInfo.battlePet = nil
      nextPetHpInfo.updateFlag = {}
      nextPetHpInfoList[i] = nextPetHpInfo
      hasAnyChange = true
    end
  end
  if hasAnyChange then
    nextState.petHpInfoList = nextPetHpInfoList
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:HidePetInfoUI(pet)
  if pet then
    local hpList = {}
    local energyList, cardDeckList
    if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
      hpList = self.TeammateHPList
      energyList = self.TeammateEnergies
      cardDeckList = self.TeammateCardDecks
    elseif BattleUtils.IsWorldLeaderFight() then
      hpList = self.LeaderHpList
      energyList = self.LeaderEnergies
      cardDeckList = self.LeaderCardDeck
    else
      hpList = self.EnemyHPList
      energyList = self.EnemyEnergies
      cardDeckList = self.EnemyCardDecks
    end
    if hpList then
      for i, v in ipairs(hpList or {}) do
        if v.battlePet and v.battlePet == pet then
          v:PetNone()
          v:TryHide()
          v:PlayerLeave()
          if cardDeckList[i] and cardDeckList[i].player == pet.player then
            cardDeckList[i]:PlayerLeave()
            cardDeckList[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
            if not BattleUtils.IsCrowdBattle() or pet.teamEnm ~= BattleEnum.Team.ENUM_ENEMY then
              local length = #hpList
              for j = 1, length do
                local index = i + j
                if length < index then
                  index = index % length
                  if 0 == index then
                    index = length
                  end
                end
                if hpList[index] and hpList[index].battlePet and hpList[index].battlePet.player == pet.player and cardDeckList[index] then
                  if hpList[index].shouldHide then
                    cardDeckList[index]:SetVisibility(UE4.ESlateVisibility.Collapsed)
                  else
                    cardDeckList[index]:InitView(pet.player)
                    cardDeckList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                  end
                end
              end
            end
          end
        end
      end
    end
    for _, v in ipairs(energyList or {}) do
      if v.battlePet and v.battlePet == pet then
        v:PlayerLeave()
        v:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    NRCModuleManager:DoCmd(BattleUIModuleCmd.HideBattleRunAwayTip)
  end
end

function UMG_BattleMainWindow_C:ChangeOperateMode(enum)
  self.UMG_Battle_Operate:ChangeToIndex(enum)
  self:ShowAll()
end

function UMG_BattleMainWindow_C:HideAll(option)
  do
    local _, nextState = self:GetCurrAndNextState()
    nextState.isShow = false
    self:SetState(nextState)
  end
  local excludeDeck = option and option.excludeDeck
  local excludeSkillTransmissionItems = option and option.excludeSkillTransmissionItems
  local excludeRecordButton = option and option.excludeRecordButton
  local excludeChatButton = option and option.excludeChatButton
  local excludeChatBubbles = option and option.excludeChatBubbles
  local excludeTerritoryTrialUi = option and option.excludeTerritoryTrialUi
  if nil == excludeSkillTransmissionItems then
    excludeSkillTransmissionItems = true
  end
  if nil == excludeChatBubbles then
    excludeChatBubbles = true
  end
  if nil == excludeTerritoryTrialUi then
    excludeTerritoryTrialUi = false
  end
  local withAnim = option and option.withAnim
  local callback = option and option.callback
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE, withAnim)
  local SkillPanel = self:GetSubPanel(BattleEnum.Operation.ENUM_SKILL)
  if SkillPanel then
    SkillPanel.EnergyBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.NRCImage_16:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.isShowing or nil == self.isShowing then
    self.UMG_Battle_Operate:PlayClose()
    self.UMG_Battle_Operate:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  self:ShowBattleSkillPickPanel(false)
  self.isShowing = false
  if not excludeDeck then
    self:HideHPBars()
  end
  if excludeDeck or nil == excludeDeck then
    self.SpEnergyList:Show()
    self.SpEnergyList:ToHalfAlpha(true)
  else
    self.SpEnergyList:Hide()
  end
  if not self.UmgLoaders then
    return
  end
  for panelType, panelLoader in pairs(self.UmgLoaders) do
    if panelType ~= self._curOperateType then
      local panel = self:GetSubPanel(panelType)
      if panelType == BattleEnum.Operation.ENUM_SKILL then
        local skillList = panel
        if skillList and not excludeSkillTransmissionItems then
          skillList:RecycleAndHideAllBindChangePositionSkillItem()
          skillList:SetShowState(nil, false)
        end
      end
      if panel then
        panel:Hide()
      end
    end
  end
  self.lastLoadedSubPanelOpType = BattleEnum.Operation.ENUM_NONE
  self.currentLoadedSubPanelOpType = BattleEnum.Operation.ENUM_NONE
  _G.BattleManager:HideBattleAdditionalTarget()
  self:HideBattleRuleTip()
  self:HideBtnGiveUp()
  self._opBeforeHide = self._curOperateType
  self:ChangePanelByOperateType(BattleEnum.Operation.ENUM_NONE, withAnim, callback)
  self:TryCloseSubPanelTips()
  if not excludeChatBubbles then
    self:HideChatBubbles()
  end
  if not excludeTerritoryTrialUi then
    self:HideTerritoryTrialUI()
  end
  local prevIsRecordButtonShow = self.isRecordButtonShow
  local nextIsRecordButtonShow = false
  if prevIsRecordButtonShow and excludeRecordButton then
    nextIsRecordButtonShow = true
  end
  local prevIsChatButtonShow = self.isChatButtonShow
  local nextIsChatButtonShow = false
  if prevIsChatButtonShow and excludeChatButton then
    nextIsChatButtonShow = true
  end
  self.module:OnCmdHideWarningPrompt()
end

function UMG_BattleMainWindow_C:ShowAll()
  do
    local _, nextState = self:GetCurrAndNextState()
    nextState.isShow = true
    self:SetState(nextState)
  end
  NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  self:SetAllInputMappingContextActive(true)
  if BattleUtils.IsWorldLeaderFight() then
    self.module:ShowOrHideAdditionalTarget(true)
  end
  if _G.BattleManager.battleRuntimeData:IsShowFlowerTask() then
    self.module:ShowFlowerTask()
  end
  if not self.isShowing then
    self:ChangeHpTypeByBattleType()
    self.UMG_Battle_Operate:PlayOpen()
  end
  self.isShowing = true
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW)
  self.UMG_Battle_Operate:ConditionalShow()
  self.NRCImage_16:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowBattleRunAwayTip)
  if BattleUtils.IsCurrentBattleCanBeWatch() then
    _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.OpenPVPValueNumberPanel)
  end
  _G.BattleManager:OpenBattleAdditionalTarget()
  self:ShowBattleRuleTip()
  self:ShowBtnGiveUp()
  self:ShowHPBars()
  self.SpEnergyList:ToHalfAlpha(false)
  self:CheckFinalBattleUI()
  self:CheckB1FinalBattleP1UI()
  self:CheckB1FinalBattleP2UI()
  self:CheckB1FinalBattleP3UI()
  self:ShowTerritoryTrialUI()
  self:ShowChatBubbles()
end

function UMG_BattleMainWindow_C:GetBattleRuleIds()
  if not self.battleRules then
    self.battleRules = BattleUtils.GetBattleRuleIds()
  end
  return self.battleRules
end

function UMG_BattleMainWindow_C:ConfirmBtnGiveUp()
  _G.BattleEventCenter:Dispatch(BattleEvent.ON_CLICK_GIVEUP, true)
end

function UMG_BattleMainWindow_C:OnBtnGiveUp()
  if BattleUtils.IsNpcChallenge() then
    local title = LuaText.battlepassmodule_1
    local des = LuaText.ASK_ESCAPE_BATTLE
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.ConfirmBtnGiveUp):SetCloseOnCancel(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  elseif BattleUtils.IsLeaderChallenge() then
    local title = LuaText.battlepassmodule_1
    local des = LuaText.ASK_ESCAPE_BATTLE
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.SendStopBossChallenge):SetCloseOnCancel(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_BattleMainWindow_C:OnStopBossRsp()
end

function UMG_BattleMainWindow_C:SendStopBossChallenge()
  local Request = ProtoMessage:newZoneExitChallengeReq()
  Request.stay_dungeon = true
  self.battleManager:SetLeaderChallengeGiveUp(true)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_EXIT_CHALLENGE_REQ, Request, self, self.OnStopBossRsp)
end

function UMG_BattleMainWindow_C:OnBtnCharacteristic()
  if _G.BattleUtils.IsNpcChallenge() or _G.BattleUtils.IsLeaderChallenge() then
    BattleBossChallengeUtils.ShowUmgMechanismClick()
  else
    self:OpenBattleRuleTip()
  end
end

function UMG_BattleMainWindow_C:ShowBattleRuleTip()
  local battleRules = self:GetBattleRuleIds()
  if #battleRules > 0 or _G.BattleUtils.IsNpcChallenge() or _G.BattleUtils.IsLeaderChallenge() then
    self.Btn_characteristic:SetVisibility(UE4.ESlateVisibility.Visible)
    if not self.first_open_battle_rule then
      self.first_open_battle_rule = true
      self:OpenBattleRuleTip(true)
      self.open_battle_rule_id = _G.DelayManager:DelaySeconds(2, self.CloseBattleRuleTip, self)
    end
  end
end

function UMG_BattleMainWindow_C:OpenBattleRuleTip(auto_close)
  local battleRules = self:GetBattleRuleIds()
  if #battleRules > 0 then
    if BattleUtils.IsNpcChallenge() or BattleUtils.IsLeaderChallenge() then
      _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenWarningPrompt, battleRules)
    else
      _G.NRCModuleManager:DoCmd(PVEModuleCmd.OpenPveWarningPrompt, battleRules, auto_close)
    end
  end
end

function UMG_BattleMainWindow_C:CloseBattleRuleTip()
  if self.open_battle_rule_id then
    _G.DelayManager:CancelDelayById(self.open_battle_rule_id)
    _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.CloseWarningPrompt)
  end
  self.open_battle_rule_id = nil
end

function UMG_BattleMainWindow_C:HideBattleRuleTip()
  self.Btn_characteristic:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleMainWindow_C:ShowBtnGiveUp()
  if BattleUtils.IsLeaderChallenge() then
    self.Btn_GiveUp:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_BattleMainWindow_C:HideBtnGiveUp()
  self.Btn_GiveUp:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleMainWindow_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_BattleMainWindow_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -40
  Padding.Top = -196
  Padding.Right = 0
  Padding.Bottom = 0
  self.UMG_Battle_Operate.HorizontalBox_1:SetRenderScale(UE4.FVector2D(0.82, 0.82))
  self.UMG_Battle_Operate.HorizontalBox_1.Slot:SetOffsets(Padding)
  self.HpPanel:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  Padding.Left = -249
  Padding.Top = -61
  Padding.Right = -243
  Padding.Bottom = 0
  self.HpPanel.Slot:SetOffsets(Padding)
end

function UMG_BattleMainWindow_C:PCKeySetting()
  if SystemSettingModuleCmd then
    if self.PCKey_1 then
      self.PCKey_1:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleRecord")
      if "" ~= image then
        self.PCKey_1:SetImageMode(image)
      else
        self.PCKey_1:SetText(text)
      end
    end
    if self.PCKey_3 then
      self.PCKey_3:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleChat")
      if "" ~= image then
        self.PCKey_3:SetImageMode(image)
      else
        self.PCKey_3:SetText(text)
      end
    end
    local SelectPet = BattleManager.SelectTargetManager:GetCurSelectPet()
    if SelectPet then
      SelectPet:RefreshSelectSureKeyUI()
    end
  end
end

function UMG_BattleMainWindow_C:HideHPBars()
  local _, nextState = self:GetCurrAndNextState()
  nextState.isInfoShow = false
  self:SetState(nextState)
  if self.isShowingHP then
    self.isShowingHP = false
    self:StopAnimation(self.openInfo)
    self:PlayAnimation(self.closeInfo)
  else
    self:ForceHideHP()
  end
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Close_Information_Recording)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideChangePetConfirm3, true, true)
  if BattleUtils.IsTeam() then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetGroupWarfare, false)
  elseif BattleUtils.IsB1FinalBattleP3() then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ActivatePetTheFinalBattle, false)
  end
end

function UMG_BattleMainWindow_C:RefreshOperatePanel()
  self.UMG_Battle_Operate:RefreshPanel()
end

function UMG_BattleMainWindow_C:SwitchToRidOfSelectPet()
  self.UMG_Battle_Operate:SwitchToRidOfSelectPet()
end

function UMG_BattleMainWindow_C:SwitchToRunAway()
  self.UMG_Battle_Operate:SwitchToRunAway()
end

function UMG_BattleMainWindow_C:SwitchToWatchBattleMode()
  self.UMG_Battle_Operate:SwitchToWatchBattleMode()
end

function UMG_BattleMainWindow_C:ForceHideHP()
  for _, v in ipairs(self.EnemyCardDecks) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.TeammateCardDecks) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.TeammateEnergies) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.EnemyEnergies) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.TeammateHPList) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.EnemyHPList) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  for _, v in ipairs(self.LeaderHpList) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  NRCModuleManager:DoCmd(BattleUIModuleCmd.HideBattleRunAwayTip)
  for _, v in ipairs(self.LeaderCardDeck) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_BattleMainWindow_C:ShowHPBars()
  local _, nextState = self:GetCurrAndNextState()
  nextState.isInfoShow = true
  self:SetState(nextState)
  if self.isShowingHP then
    return
  end
  self:StopAnimation(self.closeInfo)
  self.isShowingHP = true
  if self.TeammateHPList then
    for _, v in ipairs(self.TeammateHPList) do
      if v.battlePet then
        v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if self.TeammateEnergies then
    for _, v in ipairs(self.TeammateEnergies) do
      if v.battlePet then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if self.TeammateCardDecks then
    for _, v in ipairs(self.TeammateCardDecks) do
      if v.player and not BattleUtils.IsFinalBattle() then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if self.LeaderHpList then
    for _, v in ipairs(self.LeaderHpList) do
      if v.battlePet then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if self.LeaderCardDeck then
    for _, v in ipairs(self.LeaderCardDeck) do
      if v.player then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  if not BattleUtils.IsFinalBattleP1() then
    if self.EnemyHPList then
      for _, v in ipairs(self.EnemyHPList) do
        if v.battlePet then
          v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
    if self.EnemyEnergies then
      for _, v in ipairs(self.EnemyEnergies) do
        if v.battlePet then
          v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
    if self.EnemyCardDecks then
      for _, v in ipairs(self.EnemyCardDecks) do
        if v.player then
          v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
  end
  self:ShowWeatherUI()
  self:ChangeHpTypeByBattleType()
  self:PlayAnimation(self.openInfo)
end

function UMG_BattleMainWindow_C:ShowNoMoveHP()
  self:StopAnimation(self.closeInfo)
  self.isShowingHP = true
  for _, v in ipairs(self.TeammateHPList) do
    if v.battlePet then
      v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.EnemyHPList) do
    if v.battlePet and not v.battlePet:IsMoving() then
      v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.LeaderHpList) do
    if v.battlePet and not v.battlePet:IsMoving() then
      v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.TeammateEnergies) do
    if v.battlePet then
      v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.EnemyEnergies) do
    if v.battlePet and not v.battlePet:IsMoving() then
      v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.TeammateCardDecks) do
    if v.player then
      v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  if not BattleUtils.IsFinalBattleP1() then
    for _, v in ipairs(self.EnemyCardDecks) do
      if v.player then
        v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
  self:PlayAnimation(self.openInfo)
end

function UMG_BattleMainWindow_C:ArriveTargetedShowPetInfo()
  local enemyPets = self.battleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY)
  for _, pet in ipairs(enemyPets) do
    self:ShowPetHP(pet)
  end
  for _, v in ipairs(self.EnemyHPList) do
    if v.battlePet then
      v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.LeaderHpList) do
    if v.battlePet then
      v:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.EnemyEnergies) do
    if v.battlePet then
      v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  for _, v in ipairs(self.EnemyCardDecks) do
    if v.player then
      v:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_BattleMainWindow_C:SetupHPAndEnergy()
  local pawnManager = self.battleManager.battlePawnManager
  local myPets = pawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM, false, true)
  for _, pet in ipairs(myPets) do
    self:ShowPetHP(pet)
  end
  local enemyPets = pawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY)
  for _, pet in ipairs(enemyPets) do
    self:ShowPetHP(pet)
  end
end

function UMG_BattleMainWindow_C:ShowEvolutionSelectPanel()
  self.EvolutionSelectPanel:Show()
end

function UMG_BattleMainWindow_C:HideEvolutionSelectPanel()
  self.EvolutionSelectPanel:Hide()
end

function UMG_BattleMainWindow_C:SetRound(round)
  self.curRound = round
end

function UMG_BattleMainWindow_C:ShowChangePetConfirmPanel(card)
  self.ChangePetConfirmPanel:Show(card)
  self.ChangePetConfirmPanel:HideClose()
end

function UMG_BattleMainWindow_C:HideChangePetConfirmPanel(withAnim, bInBattle)
  self.ChangePetConfirmPanel:Hide(withAnim, bInBattle)
end

function UMG_BattleMainWindow_C:FocusOnCurOperate()
  self.UMG_Battle_Operate:FocusOnCurOperate()
  self._isFocus = true
end

function UMG_BattleMainWindow_C:FreeOperate()
  self.UMG_Battle_Operate:FreeOperate()
  self._isFocus = false
end

function UMG_BattleMainWindow_C:ChangeBattleOperateEnable(flag)
  if BattleUtils.IsTeam() or BattleUtils.IsB1FinalBattleP3() then
    self:ChangeHpTypeByBattleType()
  else
    self:ChangeBattleOperate(flag)
  end
end

function UMG_BattleMainWindow_C:ChangeBattleOperate(flag)
  if flag then
    self.UMG_Battle_Operate:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_Battle_Operate:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_BattleMainWindow_C:OnDialogCallback(result, runAwayType)
  if result and _G.BattleNetManager:SendEscapeReqWithHandle(self, self.GetEscapeRsp, runAwayType) then
    self.waitEscapeReq = true
    return
  end
  self:ReturnBeforeEscape()
end

function UMG_BattleMainWindow_C:GetEscapeRsp(rsp)
  self.waitEscapeReq = false
  if not rsp or 0 ~= rsp.ret_info.ret_code then
    self:ReturnBeforeEscape()
  end
end

function UMG_BattleMainWindow_C:OnOnlineStateChanged(oldOnlineState, newOnlineState, disOnlineState)
  if disOnlineState == OnlineState.EnteredCell and self.waitEscapeReq then
    self:ReturnBeforeEscape()
  end
end

function UMG_BattleMainWindow_C:OpIsEscape(opState)
  return opState == BattleEnum.Operation.ENUM_ESCAPE or opState == BattleEnum.Operation.ENUM_SURRENDER or opState == BattleEnum.Operation.ENUM_STEPAWAY or opState == BattleEnum.Operation.ENUM_GIVEUP
end

function UMG_BattleMainWindow_C:ReturnBeforeEscape()
  if self.isShowing and self:OpIsEscape(self._curOperateType) then
    self:ChangeOperateMode(self._opBeforeEscape)
    if self._isFocus then
      self:FocusOnCurOperate()
    end
  end
end

function UMG_BattleMainWindow_C:OnStepAwayDialogCallback(result)
  if result then
    BattleNetManager:SendStepAwayReq()
  elseif self.isShowing then
    self:ChangeOperateMode(self._opBeforeEscape)
    if self._isFocus then
      self:FocusOnCurOperate()
    end
  end
end

function UMG_BattleMainWindow_C:StopHpWarning()
  for _, v in ipairs(self.TeammateHPList) do
    if not v.Battle_Hp.WarnRound or BattleManager.curRound > v.Battle_Hp.WarnRound then
      v.Battle_Hp:StopAnimation(v.Battle_Hp.EarlyWarning)
    end
  end
  for _, v in ipairs(self.EnemyHPList) do
    if not v.Battle_Hp.WarnRound or BattleManager.curRound > v.Battle_Hp.WarnRound then
      v.Battle_Hp:StopAnimation(v.Battle_Hp.EarlyWarning)
    end
  end
end

function UMG_BattleMainWindow_C:EffectPlayUIAnimation(animId, card, warnRound)
  if animId == BattleConst.EffectAnimation.KeepWarning then
    local hpLists = self.TeammateHPList
    if card.owner.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      return
    end
    for _, v in ipairs(hpLists) do
      if v.battlePet and v.battlePet.card == card then
        v.Battle_Hp.WarnRound = warnRound
        v.Battle_Hp:PlayAnimation(v.Battle_Hp.EarlyWarning, 0, 0)
      end
    end
  else
    local CardDecks = self.TeammateCardDecks
    if card.owner.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      CardDecks = self.EnemyCardDecks
    end
    for _, v in ipairs(CardDecks) do
      if v.player and v.player == card.owner then
        v:PlayEffectAnimation(animId, card)
      end
    end
  end
end

function UMG_BattleMainWindow_C:CheckTerritoryTrialBattleHp()
  if BattleUtils.IsTerritoryTrialBattle() then
    local currState, nextState = self:GetCurrAndNextState()
    local currPetHpInfoList = currState and currState.petHpInfoList or {}
    for i, petHpInfo in ipairs(currPetHpInfoList) do
      local petHpInfoPet = petHpInfo and petHpInfo.battlePet
      if petHpInfoPet and petHpInfoPet.teamEnm == BattleEnum.Team.ENUM_ENEMY and petHpInfoPet.card and not petHpInfoPet.card:IsExistAtField() then
        self:HidePetUI(petHpInfoPet)
      end
    end
  end
end

function UMG_BattleMainWindow_C:RefreshCardDeck(pet)
  if not pet then
    return
  end
  if BattleUtils.IsFinalBattleP1() then
    return
  end
  if BattleUtils.IsCrowdBattle() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    if pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      for i, v in ipairs(self.EnemyCardDecks) do
        local flag = math.floor(pet.card.petInfo.battle_inside_pet_info.cheers_tag / 10)
        if v.pet and v.pet.card.petInfo.battle_inside_pet_info.cheers_tag / 10 == flag then
          v:UpdateDataFor1VN()
        end
      end
      local cheers
      if BattleUtils.Is1VN() then
        cheers = self.battleManager.battlePawnManager:GetEnemyAllCheerPets()
      else
        cheers = self.battleManager.battlePawnManager:GetCheerPets(pet)
      end
      if 0 == #cheers then
        for _, v in ipairs(self.EnemyCardDecks) do
          if v.pet and not v.pet.card:IsExistAtField() then
            self:HidePetUI(v.pet)
          end
        end
      end
    end
    return
  end
  if BattleUtils.IsTerritoryTrialBattle() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return
  end
  local summon = 0
  if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
    if self.TeammateCardDecks then
      for i, v in ipairs(self.TeammateCardDecks) do
        if v.player == pet.player then
          v:UpdateData()
          summon = v:GetRealSummonNumber()
        end
      end
    else
      Log.Warning("self.TeammateCardDecks is nil")
    end
  end
  if pet.teamEnm == BattleEnum.Team.ENUM_ENEMY and self.EnemyCardDecks then
    for i, v in ipairs(self.EnemyCardDecks) do
      if v.player == pet.player then
        if v.player then
          v.player:RefreshDeadPetNum()
        end
        v:UpdateData()
        summon = v:GetRealSummonNumber()
      end
    end
  end
  if summon <= 0 then
    self:HidePetUI(pet, true)
  else
    self:InactivePetUI(pet)
  end
end

function UMG_BattleMainWindow_C:UpdateCanCatchState()
  local isTeam = BattleUtils.IsTeam()
  local isCatchBattleMode = BattleUtils.IsCatchBattleMode()
  local isBadgeChallenge = false
  local battleManager = _G.BattleManager
  local isTeamBossToCatch = battleManager and battleManager.IsTeamBossToCatch or false
  local isCanCatch = false
  if isCatchBattleMode or isTeam and isTeamBossToCatch then
    isCanCatch = true
  end
  if isBadgeChallenge then
    isCanCatch = false
  end
  self.isCanCatch = isCanCatch
end

function UMG_BattleMainWindow_C:SetCardDeck(player)
  if BattleUtils.IsCrowdBattle() and player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return
  end
  if not player.team then
    return
  end
  local hpList, cardDeckList
  if player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    hpList = self.TeammateHPList
    cardDeckList = self.TeammateCardDecks
  elseif BattleUtils.IsWorldLeaderFight() then
    hpList = self.LeaderHpList
    cardDeckList = self.LeaderCardDeck
  else
    hpList = self.EnemyHPList
    cardDeckList = self.EnemyCardDecks
  end
  local pets = player.team:GetAllPets() or {}
  if 0 == player:GetSummonNumber() then
    for i, v in pairs(pets) do
      if not v.card:IsCanSelect() then
        pets[i] = nil
      end
    end
  end
  local summonNumber = 0
  local index = player.teamEnm == BattleEnum.Team.ENUM_TEAM and 1 or #pets
  if pets[index] then
    index = pets[index].card.posInField
  else
    index = player.FirstPetPosInField or 0
    index = index + 1
  end
  if player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    local capacity = math.min(_G.BattleManager.battleRuntimeData.enemyPetNumber, #cardDeckList)
    index = capacity - (index - 1)
  end
  if cardDeckList[index] then
    cardDeckList[index]:InitView(player)
    summonNumber = cardDeckList[index]:GetRealSummonNumber()
  end
  if 0 == summonNumber then
    for _, v in ipairs(hpList) do
      if v.battlePet and v.battlePet.player == player and not v.battlePet.card:IsCanSelect() then
        self:HidePetUI(v.battlePet)
      end
    end
  end
end

function UMG_BattleMainWindow_C:OnPlayerSpawnEvent(player)
  local team = player.teamEnm
  if team == BattleEnum.Team.ENUM_TEAM and (not self.battleManager.battlePawnManager.playerTeam or self.battleManager.battlePawnManager.playerTeam == player.team) then
    self.SpEnergyList:InitByData()
  end
  self:SetCardDeck(player)
end

function UMG_BattleMainWindow_C:OnCheerSwitch(newPet)
  if newPet and not newPet.card:IsCheerPet() then
    self:ShowPetHP(newPet)
    local pets = self.battleManager.battlePawnManager:GetCanSelectAllPet(newPet.teamEnm)
    for _, v in ipairs(pets) do
      self:RefreshCardDeck(v)
    end
    if BattleUtils.IsTerritoryTrialBattle() and newPet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      local card = newPet and newPet.card
      local petInfo = card and card.petInfo
      local insideInfo = petInfo and petInfo.battle_inside_pet_info
      local trialInfo = insideInfo and insideInfo.trial_pet_info
      local isBoss = trialInfo and trialInfo.is_boss
      local bossHpListIndex = card and card.posInField
      if isBoss then
        local enemyHpList = self.EnemyHPList or {}
        for index, v in ipairs(enemyHpList) do
          local pet = v and v.battlePet
          local petCard = pet and pet.card
          local isExistAtField = petCard and petCard:IsExistAtField() or false
          if bossHpListIndex ~= index and not isExistAtField then
            self:HidePetUI(pet)
          end
        end
      end
    end
  else
    for _, v in ipairs(self.EnemyCardDecks) do
      if v.pet then
        self:RefreshCardDeck(v.pet)
      end
    end
  end
end

function UMG_BattleMainWindow_C:OnPetSpawnEvent(pet)
  self:SetPanelRenderOpacity()
  local restPet = pet.team.RestPets
  if restPet[pet.card.pos] or pet.IsSkipHpRefresh then
    return
  end
  if pet.card:IsCheerPet() then
    self:RefreshCardDeck(pet.card:GetMasterPet())
    return
  end
  if (pet.card:IsBeCatch() or pet.card.hp <= 0) and BattleUtils.IsCrowdBattle() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return
  end
  self:ShowPetHP(pet)
  if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
    local battlePetCard = pet and pet.card
    local displayRoundSkills = battlePetCard and battlePetCard:GetDisplayAndReadySkills() or {}
    for _, skillData in ipairs(displayRoundSkills) do
      local skillId = _G.SkillUtils.CheckSkillId(skillData.skill_id)
      _G.SkillUtils.PreLoadSkillIconRes(skillId)
    end
  end
end

function UMG_BattleMainWindow_C:ShowPetHP(pet)
  if pet.card:WillMove() then
    return
  end
  local team = pet.teamEnm
  local index = pet.card.posInField
  local petGuid = pet and pet.guid
  if team == BattleEnum.Team.ENUM_TEAM then
  else
    local capacity = math.min(_G.BattleManager.battleRuntimeData.enemyPetNumber, #self.EnemyHPList)
    index = capacity - (index - 1)
  end
  local currState, nextState = self:GetCurrAndNextState()
  local currPetHpInfoList = currState and currState.petHpInfoList or {}
  local nextPetHpInfoList = {}
  table.copy(currPetHpInfoList, nextPetHpInfoList)
  local hasAnyChange = false
  for i, petHpInfo in ipairs(currPetHpInfoList) do
    local petHpInfoTeamEnum = petHpInfo and petHpInfo.teamEnum
    local petHpInfoIndex = petHpInfo and petHpInfo.index
    if petHpInfoTeamEnum == team and petHpInfoIndex == index then
      local nextPetHpInfo = {}
      table.copy(petHpInfo, nextPetHpInfo)
      nextPetHpInfo.petGid = petGuid
      nextPetHpInfo.battlePet = pet
      nextPetHpInfo.updateFlag = {}
      nextPetHpInfoList[i] = nextPetHpInfo
      hasAnyChange = true
    end
  end
  if hasAnyChange then
    nextState.petHpInfoList = nextPetHpInfoList
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:ShowPetHpInfo(petHpInfo)
  local team = petHpInfo and petHpInfo.teamEnum
  local index = petHpInfo and petHpInfo.index
  local pet = petHpInfo and petHpInfo.battlePet
  local hpList, hpAnimList, cardDeckList, energyViewList, energyAnimList, cardDeckAnimList, showAnimList, hideAnimList
  self:CheckFinalBattleUI()
  if team == BattleEnum.Team.ENUM_TEAM then
    hpList = self.TeammateHPList
    cardDeckList = self.TeammateCardDecks
    energyViewList = self.TeammateEnergies
  else
    if team == BattleEnum.Team.ENUM_ENEMY and BattleUtils.IsFinalBattleP2() then
      self.finalBattlePet = pet
      return
    end
    if BattleUtils.IsWorldLeaderFight() then
      hpList = self.LeaderHpList
      cardDeckList = self.LeaderCardDeck
    else
      hpList = self.EnemyHPList
      cardDeckList = self.EnemyCardDecks
      hpAnimList = self.EnemyHpListAnimUMG
      energyViewList = self.EnemyEnergies
      showAnimList = self.EnemyHpListShowAnim
      hideAnimList = self.EnemyHpListHideAnim
      energyAnimList = self.EnemyEnergiesAnimUMG
      cardDeckAnimList = self.EnemyCardDecksAnimUMG
    end
  end
  if index > #hpList or index <= 0 then
    return
  end
  for _, v in ipairs(cardDeckList) do
    if v.player == pet.player and 0 == v:GetRealSummonNumber() then
      for _, hp in ipairs(hpList) do
        if hp.battlePet and not hp.battlePet.card:IsCanSelect() and not hp.battlePet.card.posInField == pet.card.posInField then
          self:HidePetUI(hp.battlePet)
        end
      end
      if not pet.card:IsCanSelect() then
        return
      end
    end
  end
  local isCanShowEnemyEnergies = true
  if self.isShowingHP then
    hpList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if energyViewList and energyViewList[index] then
      if isCanShowEnemyEnergies then
        energyViewList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        energyViewList[index]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    cardDeckList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if hpAnimList and showAnimList and hideAnimList and hpList[index].battlePet and hpList[index].battlePet ~= pet then
      hpList[index]:PlayerLeave()
      self:PlayAnimation(hideAnimList[index])
      self:PlayAnimation(showAnimList[index])
      self:OnSetHpAnimInfo(index, hpAnimList, energyAnimList, cardDeckAnimList, pet, true, true)
    else
      self:SetHpInfo(index, pet)
    end
  else
    self:SetHpInfo(index, pet)
  end
  if team == BattleEnum.Team.ENUM_ENEMY then
    self.enemyPet = pet
    NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowBattleRunAwayTip)
    if _G.BattleManager.battleRuntimeData.battleType == Enum.BattleType.BT_LEADERFIGHT or _G.BattleManager.battleRuntimeData.battleType == Enum.BattleType.BT_DUNGEONBOSS then
      hpList[index]:SwitchToLeaderBattle()
      hpList[index]:RefreshHp()
    else
      hpList[index]:SwitchToNormalBattle()
    end
  end
  self:CheckB1FinalBattleP2UI()
  self:CheckB1FinalBattleP3UI()
end

function UMG_BattleMainWindow_C:SetHpInfo(index, pet)
  local hpList, cardDeckList, energyViewList
  if pet.teamEnm == BattleEnum.Team.ENUM_TEAM then
    hpList = self.TeammateHPList
    cardDeckList = self.TeammateCardDecks
    energyViewList = self.TeammateEnergies
  elseif BattleUtils.IsWorldLeaderFight() then
    hpList = self.LeaderHpList
    energyViewList = self.LeaderEnergies
    cardDeckList = self.LeaderCardDeck
  else
    hpList = self.EnemyHPList
    energyViewList = self.EnemyEnergies
    cardDeckList = self.EnemyCardDecks
  end
  hpList[index]:CancelDelayHide()
  hpList[index]:InitView(pet)
  hpList[index]:CalLimitPos(self.UMG_Battle_Operate)
  if energyViewList[index] then
    energyViewList[index]:InitView(pet)
  end
  if BattleUtils.IsCrowdBattle() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    cardDeckList[index]:InitViewFor1VN(pet)
  end
end

function UMG_BattleMainWindow_C:OnSetHpAnimInfo(index, hpList, eneryList, cardDeckList, pet, IsShow, IsInit, IsClear)
  if IsInit then
    if pet then
      hpList[index]:InitView(pet)
      hpList[index]:CalLimitPos(self.UMG_Battle_Operate)
      eneryList[index]:InitView(pet)
      if BattleUtils.IsCrowdBattle() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
        cardDeckList[index]:InitViewFor1VN(pet)
      end
    end
  elseif IsClear then
    hpList[index]:PlayerLeave()
    eneryList[index]:PlayerLeave()
  end
  if nil ~= IsShow then
    if IsShow then
      hpList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      cardDeckList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      hpList[index]:SetRenderOpacity(1)
      eneryList[index]:SetRenderOpacity(1)
      cardDeckList[index]:SetRenderOpacity(1)
    else
      hpList[index]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      cardDeckList[index]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local isCanShowEnemyEnergies = true
    if IsShow and isCanShowEnemyEnergies then
      eneryList[index]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      eneryList[index]:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_BattleMainWindow_C:CheckA1FinalCallingNamesRemainEffects(operateType)
  if not BattleUtils.IsFinalBattleP1() then
    return
  end
  local playerPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true, false)
  local nameBuffId = _G.DataConfigManager:GetBattleGlobalConfig("a1_finalbattle_name_buff_ID").num
  local hasNamedBuff = false
  for _, pet in pairs(playerPets) do
    local flag = false
    if pet.card and pet.card.petInfo and pet.card.petInfo.battle_inside_pet_info and pet.card.petInfo.battle_inside_pet_info.buffs then
      for i, v in ipairs(pet.card.petInfo.battle_inside_pet_info.buffs) do
        if nameBuffId == v.buff_id then
          flag = true
          break
        end
      end
    end
    if flag then
      hasNamedBuff = true
      break
    end
  end
  if hasNamedBuff and BattleUtils.CheckMyPlayerItemRemainCount(104009) then
    if operateType == BattleEnum.Operation.ENUM_ITEM then
      self.UMG_Battle_Operate:StopCallingNamesEffect()
    else
      self.UMG_Battle_Operate:PlayCallingNamesEffect()
    end
  else
    self.UMG_Battle_Operate:StopCallingNamesEffect()
  end
end

function UMG_BattleMainWindow_C:OnOperatePanelChangedClick(operateType, isChecked, IsPlayerSkillSuccess)
  self.IsPlayerSkillSuccess = IsPlayerSkillSuccess
  local State
  if operateType == BattleEnum.Operation.ENUM_SKILL then
    State = true
  else
    State = false
    if BattleUtils.IsWatchingBattle() then
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.Clear_SkillList)
    end
  end
  self:ShowBattleSkillPickPanel(State)
  local prevOpType = self._curOperateType
  self:ChangePanelByOperateType(operateType, true)
  self:CheckA1FinalCallingNamesRemainEffects(operateType)
  if operateType ~= prevOpType then
    self:TryCloseSubPanelTips()
  end
end

function UMG_BattleMainWindow_C:ChangeByOperateType(operateType)
  if self.IsPlayerSkillSuccess and operateType == BattleEnum.Operation.ENUM_ITEM then
    if _G.BattleManager.vBattleField.battleCameraManager then
      if BattleUtils.IsFinalBattleP1() and BattleUtils.CheckMyPlayerItemRemainCount(104009) then
        _G.BattleManager.vBattleField.battleCameraManager:ChangeByOperateType(operateType)
      else
        _G.BattleManager.vBattleField.battleCameraManager:ChangeByOperateType(BattleEnum.Operation.ENUM_PLAYERSKILL)
      end
    end
  elseif _G.BattleManager.vBattleField.battleCameraManager then
    _G.BattleManager.vBattleField.battleCameraManager:ChangeByOperateType(operateType)
  end
end

function UMG_BattleMainWindow_C:OnTick(DeltaTime)
  if self.waitFunc and self.waitFunc() then
    self.waitFunc = nil
  end
  if self.PVPRoundRestTime > 0 then
    local curRestTime = math.max(0, self.PVPRoundEndTime - _G.ZoneServer:GetServerTime())
    local pvpCountDown = _G.DataConfigManager:GetBattleGlobalConfig("pvp_countdown").num
    if self.PVPRoundRestTime <= pvpCountDown * 1000 then
      _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenAndSet_Battle_Round_Start, curRestTime / 1000, (self.PVPRoundRestTime - curRestTime) / 1000)
    end
    self.PVPRoundRestTime = curRestTime
  end
  if self._curOperateType == BattleEnum.Operation.ENUM_CATCH then
    local CatchPanel = self:GetSubPanel(BattleEnum.Operation.ENUM_CATCH)
    if CatchPanel then
      CatchPanel:OnTick(DeltaTime)
    end
  end
  if self._curOperateType == BattleEnum.Operation.ENUM_CHANGE then
    local changePanel = self:GetSubPanel(BattleEnum.Operation.ENUM_CHANGE)
    if changePanel then
      changePanel:OnTick(DeltaTime)
    end
  end
end

function UMG_BattleMainWindow_C:StartPVPRoundTime(serverEndTime)
  local curTime = _G.ZoneServer:GetServerTime()
  self.PVPRoundEndTime = serverEndTime
  self.PVPRoundRestTime = math.max(0, self.PVPRoundEndTime - curTime)
end

function UMG_BattleMainWindow_C:TransformTime(time)
  local minute = math.floor(time / 60)
  time = math.floor(time % 60)
  if minute < 10 then
    minute = "0" .. minute
  end
  if time < 10 then
    time = "0" .. time
  end
  return minute .. ":" .. time
end

function UMG_BattleMainWindow_C:EndPVPRoundTime()
  self.PVPRoundRestTime = 0
  local hidePanel = true
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.Close_Battle_Round_Start, BattleEnum.UmgBattleRoundStartDisplayType.CountDown, hidePanel)
end

function UMG_BattleMainWindow_C:ChangeMultiPlayer(content)
  if self.MultiPlayerTips and (self.battleManager.battleRuntimeData.subBattleType == BattleEnum.SubBattleType.MultiPlayer or BattleUtils.IsPvp()) then
    if content then
      self.MultiPlayerTips:SetText(tostring(content))
    else
      self.MultiPlayerTips:SetText("")
    end
  end
  self:OpenRunAwayTips()
end

function UMG_BattleMainWindow_C:ChangePanelByOperateType(operateType, withAnim, force)
  Log.Debug("UMG_BattleMainWindow_C: Operate Change Start", withAnim)
  Log.Debug("Cur OperateType: " .. tostring(self._curOperateType))
  Log.Debug("To OperateType: " .. tostring(operateType))
  if not force then
    if not self._inPanelChanging and operateType == self._curOperateType then
      Log.Debug("zgx \230\178\161\230\156\137\230\173\163\229\156\168\232\191\155\232\161\140\231\154\132\229\138\168\231\148\187\239\188\140\231\155\174\230\160\135\233\157\162\230\157\191\228\184\142\229\189\147\229\137\141\233\157\162\230\157\191\231\155\184\229\144\140\239\188\140\229\143\152\230\141\162\233\157\162\230\157\191\230\156\170\231\148\159\230\149\136")
      self:ChangeByOperateType(operateType)
      return
    elseif self._inPanelChanging and operateType == self._toOperateType then
      Log.Debug("zgx \230\156\137\230\173\163\229\156\168\232\191\155\232\161\140\231\154\132\229\138\168\231\148\187\239\188\140\233\128\137\230\139\169\228\184\142\231\155\174\230\160\135\228\184\128\232\135\180")
      return
    end
  end
  
  local function finishFunc()
    Log.Debug("UMG_BattleMainWindow_C: Operate Change Finish")
    self._curOperateType = operateType
    self.waitEscapeReq = false
    self._inPanelChanging = false
    if operateType == BattleEnum.Operation.ENUM_CATCH then
      if _G.BattleManager.battleRuntimeData.battleType ~= Enum.BattleType.BT_LEGENDARY_BATTLE then
        NRCModeManager:DoCmd(BattleUIModuleCmd.ShowRecoveryItemSelect)
      end
      if _G.BattleManager.battleRuntimeData:IsShowFlowerTaskCatchTip() then
        local rules = {10129}
        self.module:OnCmdOpenWarningPrompt(rules, nil, nil, true)
      end
    end
    if operateType ~= BattleEnum.Operation.ENUM_NONE then
      self._validOperateType = operateType
    end
  end
  
  local function newPanelFunc()
    if self.UmgLoaders[operateType] and not self.UMG_Battle_Operate.changeToRunAway then
      self:LoadSubPanel(operateType, self.pet, true, finishFunc)
    else
      finishFunc()
    end
  end
  
  local function cameraFunc()
    newPanelFunc()
    self:ChangeByOperateType(operateType)
  end
  
  if not self:OpIsEscape(operateType) and operateType ~= BattleEnum.Operation.ENUM_NONE then
    self._opBeforeEscape = operateType
  end
  if not withAnim then
    self:UnLoadSubPanel(self._curOperateType, false)
    self._toOperateType = operateType
    self:ChangeByOperateType(operateType)
    if not self.UMG_Battle_Operate.changeToRunAway then
      self:LoadSubPanel(operateType, self.pet)
    end
    finishFunc()
  elseif self.UmgLoaders[self._curOperateType] and not self._inPanelChanging then
    self._inPanelChanging = true
    self._toOperateType = operateType
    self:UnLoadSubPanelWithAnim(self._curOperateType, false)
    cameraFunc()
  else
    if self._inPanelChanging then
      for panelType, panelLoader in pairs(self.UmgLoaders) do
        self:UnLoadSubPanel(panelType, false)
      end
      self._inPanelChanging = false
    end
    self._inPanelChanging = true
    self._toOperateType = operateType
    cameraFunc()
  end
end

function UMG_BattleMainWindow_C:OnAnimationStarted(Animation)
  if Animation == self.openInfo then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isOpenInfoAnimPlaying = true
    self:SetState(nextState)
  elseif Animation == self.closeInfo then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isCloseInfoAnimPlaying = true
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:OnAnimationFinished(Animation)
  if Animation == self.closeInfo then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isCloseInfoAnimPlaying = false
    self:SetState(nextState)
    self:ForceHideHP()
  elseif Animation == self.openInfo then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isOpenInfoAnimPlaying = false
    self:SetState(nextState)
  elseif Animation == self.Change_right_1 then
    if not BattleUtils.IsWorldLeaderFight() then
      self:OnSetHpAnimInfo(1, self.EnemyHPList, self.EnemyEnergies, self.EnemyCardDecks, nil, true, false)
    end
    self:OnSetHpAnimInfo(1, self.EnemyHpListAnimUMG, self.EnemyEnergiesAnimUMG, self.EnemyCardDecksAnimUMG, nil, false, false, true)
    self:PlayAnimation(self.Change_right_1_Loop)
  elseif Animation == self.Change_right_2 then
    self:OnSetHpAnimInfo(2, self.EnemyHPList, self.EnemyEnergies, self.EnemyCardDecks, nil, true, false)
    self:OnSetHpAnimInfo(2, self.EnemyHpListAnimUMG, self.EnemyEnergiesAnimUMG, self.EnemyCardDecksAnimUMG, nil, false, false, true)
    self:PlayAnimation(self.Change_right_2_Loop)
  elseif Animation == self.xiaoshi_right_1 then
    self:OnSetHpAnimInfo(1, self.EnemyHPList, self.EnemyEnergies, self.EnemyCardDecks, self.EnemyHpListAnimUMG[1].battlePet, nil, true)
  elseif Animation == self.xiaoshi_right_2 then
    self:OnSetHpAnimInfo(2, self.EnemyHPList, self.EnemyEnergies, self.EnemyCardDecks, self.EnemyHpListAnimUMG[2].battlePet, nil, true)
  elseif Animation == self.openInfo then
    self:OnBattleSettlement()
  elseif Animation == self.Resonance_In then
    self:HideResonanceTip()
  end
end

function UMG_BattleMainWindow_C:OpenRunAwayTips()
  if self.enemyPet and not self.HasInitRunAwayTip then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleRunAwayTip, self.enemyPet)
    self.HasInitRunAwayTip = true
  end
end

function UMG_BattleMainWindow_C:InitPopUpTips()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattlePopUpTips)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenHudPerceptionPanel)
end

function UMG_BattleMainWindow_C:OpenWishPowerTutorial()
  self.WishPowerBg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.Text_reminder:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CloseWishPowerTutorialBtn:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_BattleMainWindow_C:CloseWishPowerTutorial()
  self.WishPowerBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Text_reminder:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CloseWishPowerTutorialBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleMainWindow_C:CheckShouldOpenCallNameTutorial()
  if not BattleUtils.IsFinalBattle() then
    return
  end
  local roundIndex
  if _G.BattleManager.battleRuntimeData.roundIndex then
    roundIndex = _G.BattleManager.battleRuntimeData.roundIndex
  end
  if roundIndex then
    local targetIndex = _G.DataConfigManager:GetGlobalConfigByKeyType("a1_finalbattle_introduce_turn", _G.DataConfigManager.ConfigTableId.BATTLE_GLOBAL_CONFIG).num
    if 2 == roundIndex then
      local guideWidget = self.UMG_Battle_Operate.ItemToggle
      NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleTutorialPanel, 0, guideWidget)
    end
  end
end

function UMG_BattleMainWindow_C:CheckFinalBattleEnergyIsFull()
  if BattleUtils.CheckFinalBattleEnergyIsFull() then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleTutorialPanel, 2)
    NRCModuleManager:DoCmd(BattleUIModuleCmd.WishPowerMaxShineOut)
  end
end

function UMG_BattleMainWindow_C:LoadSubPanel(_SubPanel, ...)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    self.lastLoadedSubPanelOpType = self.currentLoadedSubPanelOpType
    self.currentLoadedSubPanelOpType = _SubPanel
    UmgLoader:LoadPanel(nil, ...)
  end
end

function UMG_BattleMainWindow_C:UnLoadSubPanel(_SubPanel, _forceUnload, ...)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    local panel = self:GetSubPanel(_SubPanel)
    if panel then
      return UmgLoader:UnLoadPanel(_forceUnload, ...)
    else
      return UmgLoader:UnLoadPanel(true, ...)
    end
  end
end

function UMG_BattleMainWindow_C:UnLoadSubPanelWithAnim(_SubPanel, _forceUnload, ...)
  local panel = self:GetSubPanel(_SubPanel)
  if panel and panel.Hide then
    panel:Hide(true, function()
      self:UnLoadSubPanel(_SubPanel, _forceUnload)
    end)
  else
    self:UnLoadSubPanel(_SubPanel, _forceUnload)
  end
end

function UMG_BattleMainWindow_C:GetSubPanel(_SubPanel)
  local UmgLoader = _SubPanel and self.UmgLoaders and self.UmgLoaders[_SubPanel]
  if UmgLoader then
    return UmgLoader:GetPanel()
  end
end

function UMG_BattleMainWindow_C:GetSubPanelTriggerInputActionName()
  local triggerInputActionName
  local UmgLoader = self._curOperateType and self.UmgLoaders and self.UmgLoaders[self._curOperateType]
  if UmgLoader then
    local panel = UmgLoader:GetPanel()
    if self._curOperateType == BattleEnum.Operation.ENUM_ITEM then
      triggerInputActionName = panel:GetTriggerInputActionName(0)
    elseif self._curOperateType == BattleEnum.Operation.ENUM_CATCH then
      triggerInputActionName = panel:GetTriggerInputActionName(1)
    end
  end
  return triggerInputActionName
end

function UMG_BattleMainWindow_C:SetSkillPanelUndoCallback(undoCaller, undoCallback, undoBattleSelect)
  self.undoCaller = undoCaller
  self.undoCallback = undoCallback
  self.undoBattleSelect = undoBattleSelect
end

function UMG_BattleMainWindow_C:CloseSubPanel()
  for panelType, panelLoader in pairs(self.UmgLoaders or {}) do
    self:UnLoadSubPanel(panelType, true)
  end
end

function UMG_BattleMainWindow_C:IsChangingBetweenSubPanels()
  local result = self.lastLoadedSubPanelOpType ~= BattleEnum.Operation.ENUM_NONE and self.currentLoadedSubPanelOpType ~= self.lastLoadedSubPanelOpType
  return result
end

local function LoadPanelByUmgLoaderAsync(self, loader, defaultVisibility, priority, callback)
  local OnLoadPanelCallback = function(ok, widget)
    loader.OnLoadPanelCallbackDelegate:Remove(nil, OnLoadPanelCallback)
    local widgetName = ""
    if ok then
      widgetName = widget:GetName()
    end
    Log.Debug("UMG_BattleMainWindow_C:LoadPanelByUmgLoaderAsync OnLoadPanelCallback ", widgetName)
    if ok and nil ~= defaultVisibility then
      widget:SetVisibility(defaultVisibility)
    end
    callback(ok, widget)
  end
  loader.OnLoadPanelCallbackDelegate:Add(nil, OnLoadPanelCallback)
  loader:SetPriority(priority)
  loader:LoadPanel()
end

UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync = a.wrap(LoadPanelByUmgLoaderAsync)

local function ConstructHealthBarAsync(self)
  local SlateVisibility = UE4.ESlateVisibility.Collapsed
  if _G.GlobalConfig.DebugOpenUI then
    SlateVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  local param = PriorityEnum.Passive_Battle_Panel
  local HPBar_Teammate_Result, HPBar_Teammate_1_Result, HPBar_Teammate_2_Result, TeammateCardDeck_Result, TeammateCardDeck_1_Result, TeammateCardDeck_2_Result, TeamEnergyView_Result, TeamEnergyView_1_Result, TeamEnergyView_2_Result, HPBar_Enemy_Result, HPBar_Enemy_1_Result, EnemyEnergyView_Result, EnemyEnergyView_1_Result, EnemyCardDeck_Result, EnemyCardDeck_1_Result, EnemyCardDeck_4_Result, HPBar_Enemy_4_Result, HPBar_Enemy_2_Result, HPBar_Enemy_3_Result, EnemyEnergyView_2_Result, EnemyEnergyView_3_Result, EnemyCardDeck_2_Result, EnemyCardDeck_3_Result = a.wait_all({
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Teammate_Loader, SlateVisibility, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Teammate_1_Loader, SlateVisibility, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Teammate_2_Loader, SlateVisibility, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeammateCardDeck_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeammateCardDeck_1_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeammateCardDeck_2_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeamEnergyView_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeamEnergyView_1_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.TeamEnergyView_2_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Enemy_Loader, SlateVisibility, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Enemy_1_Loader, SlateVisibility, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyEnergyView_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyEnergyView_1_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyCardDeck_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyCardDeck_1_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyCardDeck_4_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Enemy_4_Loader, UE4.ESlateVisibility.Collapsed, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Enemy_2_Loader, UE4.ESlateVisibility.Hidden, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.HPBar_Enemy_3_Loader, UE4.ESlateVisibility.Hidden, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyEnergyView_2_Loader, UE4.ESlateVisibility.Hidden, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyEnergyView_3_Loader, UE4.ESlateVisibility.Hidden, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyCardDeck_2_Loader, UE4.ESlateVisibility.Hidden, param),
    UMG_BattleMainWindow_C.LoadPanelByUmgLoaderAsync(self, self.EnemyCardDeck_3_Loader, UE4.ESlateVisibility.Hidden, param)
  })
  local HPBar_Teammate = HPBar_Teammate_Result[1] and HPBar_Teammate_Result[2] or nil
  local HPBar_1_Teammate = HPBar_Teammate_1_Result[1] and HPBar_Teammate_1_Result[2] or nil
  local HPBar_2_Teammate = HPBar_Teammate_2_Result[1] and HPBar_Teammate_2_Result[2] or nil
  local TeammateCardDeck = TeammateCardDeck_Result[1] and TeammateCardDeck_Result[2] or nil
  local TeammateCardDeck_1 = TeammateCardDeck_Result[1] and TeammateCardDeck_1_Result[2] or nil
  local TeammateCardDeck_2 = TeammateCardDeck_Result[1] and TeammateCardDeck_2_Result[2] or nil
  local TeamEnergyView = TeamEnergyView_Result[1] and TeamEnergyView_Result[2] or nil
  local TeamEnergyView_1 = TeamEnergyView_1_Result[1] and TeamEnergyView_1_Result[2] or nil
  local TeamEnergyView_2 = TeamEnergyView_2_Result[1] and TeamEnergyView_2_Result[2] or nil
  self.TeammateHPList = {
    HPBar_Teammate,
    HPBar_1_Teammate,
    HPBar_2_Teammate
  }
  self.TeammateEnergies = {
    TeamEnergyView,
    TeamEnergyView_1,
    TeamEnergyView_2
  }
  self.TeammateCardDecks = {
    TeammateCardDeck,
    TeammateCardDeck_1,
    TeammateCardDeck_2
  }
  local HPBar_Enemy = HPBar_Enemy_Result[1] and HPBar_Enemy_Result[2] or nil
  local HPBar_Enemy_1 = HPBar_Enemy_1_Result[1] and HPBar_Enemy_1_Result[2] or nil
  local EnemyEnergyView = EnemyEnergyView_Result[1] and EnemyEnergyView_Result[2] or nil
  local EnemyEnergyView_1 = EnemyEnergyView_1_Result[1] and EnemyEnergyView_1_Result[2] or nil
  local EnemyCardDeck = EnemyCardDeck_Result[1] and EnemyCardDeck_Result[2] or nil
  local EnemyCardDeck_1 = EnemyCardDeck_1_Result[1] and EnemyCardDeck_1_Result[2] or nil
  self.EnemyHPList = {HPBar_Enemy_1, HPBar_Enemy}
  self.EnemyEnergies = {EnemyEnergyView, EnemyEnergyView_1}
  self.EnemyCardDecks = {EnemyCardDeck, EnemyCardDeck_1}
  local EnemyCardDeck_4 = EnemyCardDeck_4_Result[1] and EnemyCardDeck_4_Result[2] or nil
  local HPBar_Enemy_4 = HPBar_Enemy_4_Result[1] and HPBar_Enemy_4_Result[2] or nil
  if HPBar_Enemy_4 then
    HPBar_Enemy_4:ReceiveProps({mainWindow = self})
  end
  self.LeaderHpList = {HPBar_Enemy_4}
  self.LeaderEnergies = {
    HPBar_Enemy_4.Battle_EnergyView
  }
  self.LeaderCardDeck = {EnemyCardDeck_4}
  local HPBar_Enemy_2 = HPBar_Enemy_2_Result[1] and HPBar_Enemy_2_Result[2] or nil
  if HPBar_Enemy_2 then
    HPBar_Enemy_2:SetRenderOpacity(0)
  end
  local HPBar_Enemy_3 = HPBar_Enemy_3_Result[1] and HPBar_Enemy_3_Result[2] or nil
  if HPBar_Enemy_3 then
    HPBar_Enemy_3:SetRenderOpacity(0)
  end
  local EnemyEnergyView_2 = EnemyEnergyView_2_Result[1] and EnemyEnergyView_2_Result[2] or nil
  if EnemyEnergyView_2 then
    EnemyEnergyView_2:SetRenderOpacity(0)
  end
  local EnemyEnergyView_3 = EnemyEnergyView_3_Result[1] and EnemyEnergyView_3_Result[2] or nil
  if EnemyEnergyView_3 then
    EnemyEnergyView_3:SetRenderOpacity(0)
  end
  local EnemyCardDeck_2 = EnemyCardDeck_2_Result[1] and EnemyCardDeck_2_Result[2] or nil
  if EnemyCardDeck_2 then
    EnemyCardDeck_2:SetRenderOpacity(0)
  end
  local EnemyCardDeck_3 = EnemyCardDeck_3_Result[1] and EnemyCardDeck_3_Result[2] or nil
  if EnemyCardDeck_3 then
    EnemyCardDeck_3:SetRenderOpacity(0)
  end
  self.EnemyHpListAnimUMG = {HPBar_Enemy_3, HPBar_Enemy_2}
  self.EnemyEnergiesAnimUMG = {EnemyEnergyView_3, EnemyEnergyView_2}
  self.EnemyCardDecksAnimUMG = {EnemyCardDeck_3, EnemyCardDeck_2}
  if BattleUtils.IsWorldLeaderFight() then
    self.LeaderHpList[1]:AssignEnergyBar(EnemyCardDeck_4)
  else
    self.EnemyHPList[1]:AssignEnergyBar(EnemyCardDeck)
  end
  a.wait(au.DelayFrames(1))
end

UMG_BattleMainWindow_C.ConstructHealthBarAsync = a.sync(ConstructHealthBarAsync)

function UMG_BattleMainWindow_C:IsFullyConstructed()
  return self.isHpBarsAndCardDecksConstructed
end

function UMG_BattleMainWindow_C:OnHpBarsAndCardDecksConstructed(ok)
  self.ConstructHealthBarContext = nil
  local _, nextState = self:GetCurrAndNextState()
  nextState.hpBarsAndCardDecksConstructed = true
  self:SetState(nextState)
  if ok then
    self:TryInitData()
  end
end

function UMG_BattleMainWindow_C:CheckFinalBattleUI()
  if BattleUtils.IsFinalBattle() then
    for _, enemyHP in pairs(self.EnemyHPList) do
      enemyHP:SetVisibility(UE4.ESlateVisibility.Collapsed)
      enemyHP:SetRenderOpacity(0)
    end
    for _, enemyEnergy in pairs(self.EnemyEnergies) do
      enemyEnergy:SetVisibility(UE4.ESlateVisibility.Collapsed)
      enemyEnergy:SetRenderOpacity(0)
    end
    for _, EnemyCardDeck in pairs(self.EnemyCardDecks) do
      EnemyCardDeck:SetVisibility(UE4.ESlateVisibility.Collapsed)
      EnemyCardDeck:SetRenderOpacity(0)
    end
    for _, CardDeck in pairs(self.TeammateCardDecks) do
      CardDeck:SetVisibility(UE4.ESlateVisibility.Collapsed)
      CardDeck:SetRenderOpacity(0)
    end
  end
end

function UMG_BattleMainWindow_C:CheckB1FinalBattleP1UI()
end

function UMG_BattleMainWindow_C:CheckB1FinalBattleP3UI()
  if not BattleUtils.IsB1FinalBattleP3() then
    return
  end
end

function UMG_BattleMainWindow_C:CheckB1FinalBattleP2UI()
  if not BattleUtils.IsB1FinalBattleP2() then
    return
  end
  for _, enemyEnergy in pairs(self.EnemyEnergies) do
    enemyEnergy:SetVisibility(UE4.ESlateVisibility.Collapsed)
    enemyEnergy:SetRenderOpacity(0)
  end
  for _, v in pairs(self.TeammateCardDecks) do
    v:SetVisibility(UE4.ESlateVisibility.Collapsed)
    v:SetRenderOpacity(0)
  end
  for _, EnemyCardDeck in pairs(self.EnemyCardDecks) do
    EnemyCardDeck:SetVisibility(UE4.ESlateVisibility.Collapsed)
    EnemyCardDeck:SetRenderOpacity(0)
  end
end

function UMG_BattleMainWindow_C:OpenFinalBattleWishPowerPanel()
  if BattleUtils.IsFinalBattleP1() then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenWishPowerPanel)
    NRCModuleManager:DoCmd(BattleUIModuleCmd.CheckOpenWishPowerTutorial)
  end
end

function UMG_BattleMainWindow_C:CheckOpenFinalBattleP2HPBar()
  if BattleUtils.IsFinalBattleP2() then
    local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
    if player and player.deck:HasInBattleCards() and self.finalBattlePet then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenFinalBattleLifeBar, self.finalBattlePet)
    end
  end
end

function UMG_BattleMainWindow_C:RefreshFinalBattleUI()
  if not BattleUtils.IsFinalBattle() then
    return
  end
  self:CheckShouldOpenCallNameTutorial()
  self:CheckFinalBattleEnergyIsFull()
  self:OpenFinalBattleWishPowerPanel()
  self:CheckOpenFinalBattleP2HPBar()
end

function UMG_BattleMainWindow_C:ShowTerritoryTrialUI()
  if not self.isTerritoryTrialEnemyInformationNeedLoad then
    return
  end
  local battleConfig = BattleUtils.GetBattleConfig()
  local battleMaxRound = battleConfig and battleConfig.max_round or 9999
  local nextTerritoryTrialEnemyInformationProps = {}
  nextTerritoryTrialEnemyInformationProps.isShow = true
  nextTerritoryTrialEnemyInformationProps.maxRoundCount = battleMaxRound
  self:UpdateTerritoryTrialUI(nextTerritoryTrialEnemyInformationProps)
end

function UMG_BattleMainWindow_C:HideTerritoryTrialUI()
  if not self.isTerritoryTrialEnemyInformationNeedLoad then
    return
  end
  local battleConfig = BattleUtils.GetBattleConfig()
  local battleMaxRound = battleConfig and battleConfig.max_round or 9999
  local nextTerritoryTrialEnemyInformationProps = {}
  nextTerritoryTrialEnemyInformationProps.isShow = false
  nextTerritoryTrialEnemyInformationProps.maxRoundCount = battleMaxRound
  self:UpdateTerritoryTrialUI(nextTerritoryTrialEnemyInformationProps)
end

function UMG_BattleMainWindow_C:OnTerritoryTrialUILoaded(isOk, panelInstance)
  self.isTerritoryTrialEnemyInformationLoading = false
  if isOk then
    self.TerritoryTrialEnemyInformation = panelInstance
  end
  self:UpdateTerritoryTrialUI(self.TerritoryTrialEnemyInformationProps)
end

function UMG_BattleMainWindow_C:UpdateTerritoryTrialUI(nextProps)
  self.TerritoryTrialEnemyInformationProps = nextProps
  local TerritoryTrialEnemyInformation = self.TerritoryTrialEnemyInformation
  local TerritoryTrialEnemyInformationLoader = self.TerritoryTrialEnemyInformationLoader
  if UE.UObject.IsValid(TerritoryTrialEnemyInformation) then
    TerritoryTrialEnemyInformation:SetProps(nextProps)
  elseif self.isTerritoryTrialEnemyInformationLoading then
  elseif UE.UObject.IsValid(TerritoryTrialEnemyInformationLoader) and self.isTerritoryTrialEnemyInformationNeedLoad then
    self.isTerritoryTrialEnemyInformationLoading = true
    TerritoryTrialEnemyInformationLoader:LoadPanel()
  end
end

function UMG_BattleMainWindow_C.UpdateDerivedState(prevProps, currProps, prevState, currState, derivedState)
  local prevInfoShowType = prevState and prevState.infoShowType
  local currInfoShowType = currState and currState.infoShowType
  local prevIsInfoShow = prevState and prevState.isInfoShow or false
  local currIsInfoShow = currState and currState.isInfoShow or false
  local prevChatButtonShowType = prevState and prevState.chatButtonShowType
  local currChatButtonShowType = currState and currState.chatButtonShowType
  local prevRecordButtonShowType = prevState and prevState.recordButtonShowType
  local currRecordButtonShowType = currState and currState.recordButtonShowType
  local prevBattleFsmActiveStateName = prevState and prevState.battleFsmActiveStateName
  local currBattleFsmActiveStateName = currState and currState.battleFsmActiveStateName
  local prevIsAiPerformCam = prevState and prevState.isAiPerformCam
  local currIsAiPerformCam = currState and currState.isAiPerformCam
  local prevIsTeamBattle = prevState and prevState.isTeamBattle
  local currIsTeamBattle = currState and currState.isTeamBattle
  local prevIsB1FinalBattleP2 = prevState and prevState.isB1FinalBattleP2
  local currIsB1FinalBattleP2 = currState and currState.isB1FinalBattleP2
  local prevIsB1FinalBattleP3 = prevState and prevState.isB1FinalBattleP3
  local currIsB1FinalBattleP3 = currState and currState.isB1FinalBattleP3
  local prevIsFunctionBanChatButton = prevState and prevState.isFunctionBanChatButton
  local currIsFunctionBanChatButton = currState and currState.isFunctionBanChatButton
  local prevRenderOpacity = prevState and prevState.renderOpacity
  local currRenderOpacity = currState and currState.renderOpacity
  local prevPetHpInfoList = prevState and prevState.petHpInfoList
  local currPetHpInfoList = currState and currState.petHpInfoList
  if prevChatButtonShowType ~= currChatButtonShowType then
    UMG_BattleMainWindow_C.DeriveChatButtonShowDisplay(currChatButtonShowType, derivedState)
  end
  if prevRecordButtonShowType ~= currRecordButtonShowType then
    UMG_BattleMainWindow_C.DeriveRecordButtonShowDisplay(currRecordButtonShowType, derivedState)
  end
  local battleFsmActiveStateNameChangedAndNotStandbyState = prevBattleFsmActiveStateName ~= currBattleFsmActiveStateName and currBattleFsmActiveStateName ~= BattleEnum.StateNames.Standby
  if battleFsmActiveStateNameChangedAndNotStandbyState or prevIsInfoShow ~= currIsInfoShow or prevIsAiPerformCam ~= currIsAiPerformCam or prevIsB1FinalBattleP2 ~= currIsB1FinalBattleP2 or prevIsB1FinalBattleP3 ~= currIsB1FinalBattleP3 or prevIsFunctionBanChatButton ~= currIsFunctionBanChatButton or prevRenderOpacity ~= currRenderOpacity then
    UMG_BattleMainWindow_C.DeriveChatButtonShow(currBattleFsmActiveStateName, currIsInfoShow, currIsAiPerformCam, currIsB1FinalBattleP2, currIsB1FinalBattleP3, prevIsFunctionBanChatButton, currRenderOpacity, derivedState)
  end
  if battleFsmActiveStateNameChangedAndNotStandbyState or prevIsInfoShow ~= currIsInfoShow or prevIsAiPerformCam ~= currIsAiPerformCam or prevIsTeamBattle ~= currIsTeamBattle or prevIsB1FinalBattleP2 ~= currIsB1FinalBattleP2 or prevIsB1FinalBattleP3 ~= currIsB1FinalBattleP3 or prevRenderOpacity ~= currRenderOpacity then
    UMG_BattleMainWindow_C.DeriveRecordButtonShow(currBattleFsmActiveStateName, currIsInfoShow, currIsAiPerformCam, currIsTeamBattle, currIsB1FinalBattleP2, currIsB1FinalBattleP3, currRenderOpacity, derivedState)
  end
  if prevPetHpInfoList ~= currPetHpInfoList then
    UMG_BattleMainWindow_C.DeriveEnemyPetPosMap(currPetHpInfoList, derivedState)
  end
end

function UMG_BattleMainWindow_C.DeriveStateFromProps(prevState, nextProps)
  return prevState
end

function UMG_BattleMainWindow_C.DeriveChatButtonShowDisplay(recordButtonShowType, derivedState)
  local isShowDisplay = false
  if recordButtonShowType and recordButtonShowType ~= WidgetShowType.Hide then
    isShowDisplay = true
  end
  derivedState.isChatButtonShowDisplay = isShowDisplay
end

function UMG_BattleMainWindow_C.DeriveRecordButtonShowDisplay(chatButtonShowType, derivedState)
  local isShowDisplay = false
  if chatButtonShowType and chatButtonShowType ~= WidgetShowType.Hide then
    isShowDisplay = true
  end
  derivedState.isRecordButtonShowDisplay = isShowDisplay
end

function UMG_BattleMainWindow_C.DeriveChatButtonShow(battleFsmActiveStateName, isInfoShow, isAiPerformCam, isB1FinalBattleP2, isB1FinalBattleP3, isFunctionBanChatButton, mainWindowRenderOpacity, derivedState)
  isAiPerformCam = isAiPerformCam or false
  isB1FinalBattleP2 = isB1FinalBattleP2 or false
  isB1FinalBattleP3 = isB1FinalBattleP3 or false
  isFunctionBanChatButton = isFunctionBanChatButton or false
  mainWindowRenderOpacity = mainWindowRenderOpacity or 1
  local localChatButtonCanShowStateNameList = chatButtonCanShowStateNameList or {}
  local containName = table.contains(localChatButtonCanShowStateNameList, battleFsmActiveStateName)
  local isChatButtonShow = false
  if containName and isInfoShow and not isAiPerformCam and not isB1FinalBattleP2 and not isB1FinalBattleP3 and not isFunctionBanChatButton and mainWindowRenderOpacity > 0 then
    isChatButtonShow = true
  end
  derivedState.isChatButtonShow = isChatButtonShow
end

function UMG_BattleMainWindow_C.DeriveRecordButtonShow(battleFsmActiveStateName, isInfoShow, isAiPerformCam, isTeamBattle, isB1FinalBattleP2, isB1FinalBattleP3, mainWindowRenderOpacity, derivedState)
  isAiPerformCam = isAiPerformCam or false
  isTeamBattle = isTeamBattle or false
  isB1FinalBattleP2 = isB1FinalBattleP2 or false
  isB1FinalBattleP3 = isB1FinalBattleP3 or false
  mainWindowRenderOpacity = mainWindowRenderOpacity or 1
  local localRecordButtonCanShowStateNameList = recordButtonCanShowStateNameList or {}
  local containName = table.contains(localRecordButtonCanShowStateNameList, battleFsmActiveStateName)
  local isRecordButtonShow = false
  if containName and isInfoShow and not isAiPerformCam and not isTeamBattle and not isB1FinalBattleP2 and not isB1FinalBattleP3 and mainWindowRenderOpacity > 0 then
    isRecordButtonShow = true
  end
  derivedState.isRecordButtonShow = isRecordButtonShow
end

function UMG_BattleMainWindow_C.DeriveEnemyPetPosMap(petHpInfoList, derivedState)
  local enemyPetPosMap = {}
  petHpInfoList = petHpInfoList or {}
  for i, petHpInfo in ipairs(petHpInfoList) do
    local teamEnum = petHpInfo and petHpInfo.teamEnum
    local index = petHpInfo and petHpInfo.index
    local battlePet = petHpInfo and petHpInfo.battlePet
    if teamEnum == BattleEnum.Team.ENUM_ENEMY and index then
      enemyPetPosMap[index] = battlePet
    end
  end
  derivedState.enemyPetPosMap = enemyPetPosMap
end

function UMG_BattleMainWindow_C:RenderWidget(prevProps, currProps, prevState, currState)
  local prevIsChatButtonShowDisplay = prevState and prevState.isChatButtonShowDisplay
  local currIsChatButtonShowDisplay = currState and currState.isChatButtonShowDisplay
  local prevIsRecordButtonShowDisplay = prevState and prevState.isRecordButtonShowDisplay
  local currIsRecordButtonShowDisplay = currState and currState.isRecordButtonShowDisplay
  local prevRenderOpacity = prevState and prevState.renderOpacity
  local currRenderOpacity = currState and currState.renderOpacity
  if prevIsChatButtonShowDisplay ~= currIsChatButtonShowDisplay then
    self:RenderChatButtonVisibility(currIsChatButtonShowDisplay)
  end
  if prevIsRecordButtonShowDisplay ~= currIsRecordButtonShowDisplay then
    self:RenderRecordButtonVisibility(currIsRecordButtonShowDisplay)
  end
  if prevRenderOpacity ~= currRenderOpacity then
    self:RenderMainWindowRenderOpacity(currRenderOpacity)
  end
end

function UMG_BattleMainWindow_C:RenderChatButtonVisibility(isChatButtonShowDisplay)
  local chatButtonVisibility = UE.ESlateVisibility.Collapsed
  if isChatButtonShowDisplay then
    chatButtonVisibility = UE.ESlateVisibility.Visible
  end
  self.Btn_Chat:SetVisibility(chatButtonVisibility)
end

function UMG_BattleMainWindow_C:RenderRecordButtonVisibility(isRecordButtonShowDisplay)
  local recordButtonVisibility = UE.ESlateVisibility.Collapsed
  if isRecordButtonShowDisplay then
    recordButtonVisibility = UE.ESlateVisibility.Visible
  end
  self.Btn_Record:SetVisibility(recordButtonVisibility)
end

function UMG_BattleMainWindow_C:RenderMainWindowRenderOpacity(renderOpacity)
  renderOpacity = renderOpacity or 1
  self:SetRenderOpacity(renderOpacity)
end

function UMG_BattleMainWindow_C:OnWidgetDidUpdate(prevProps, currProps, prevState, currState)
  local prevIsShow = prevState and prevState.isShow or false
  local currIsShow = currState and currState.isShow or false
  local prevIsOpenInfoAnimPlaying = prevState and prevState.isOpenInfoAnimPlaying or false
  local currIsOpenInfoAnimPlaying = currState and currState.isOpenInfoAnimPlaying or false
  local prevIsCloseInfoAnimPlaying = prevState and prevState.isCloseInfoAnimPlaying or false
  local currIsCloseInfoAnimPlaying = currState and currState.isCloseInfoAnimPlaying or false
  local prevIsInfoShow = prevState and prevState.isInfoShow
  local currIsInfoShow = currState and currState.isInfoShow
  local prevInfoShowType = prevState and prevState.infoShowType
  local currInfoShowType = currState and currState.infoShowType
  local prevIsChatButtonShow = prevState and prevState.isChatButtonShow or false
  local currIsChatButtonShow = currState and currState.isChatButtonShow or false
  local prevChatButtonShowType = prevState and prevState.chatButtonShowType
  local currChatButtonShowType = currState and currState.chatButtonShowType
  local prevIsRecordButtonShow = prevState and prevState.isRecordButtonShow or false
  local currIsRecordButtonShow = currState and currState.isRecordButtonShow or false
  local prevRecordButtonShowType = prevState and prevState.recordButtonShowType
  local currRecordButtonShowType = currState and currState.recordButtonShowType
  local prevPetHpInfoList = prevState and prevState.petHpInfoList or {}
  local currPetHpInfoList = currState and currState.petHpInfoList or {}
  local prevHpBarsAndCardDecksConstructed = prevState and prevState.hpBarsAndCardDecksConstructed or false
  local currHpBarsAndCardDecksConstructed = currState and currState.hpBarsAndCardDecksConstructed or false
  local prevIsPlayerSkillPerforming = prevState and prevState.isPlayerSkillPerforming or false
  local currIsPlayerSkillPerforming = currState and currState.isPlayerSkillPerforming or false
  if prevIsInfoShow ~= currIsInfoShow or prevIsOpenInfoAnimPlaying ~= currIsOpenInfoAnimPlaying or prevIsCloseInfoAnimPlaying ~= currIsCloseInfoAnimPlaying or prevInfoShowType ~= currInfoShowType then
    self:UpdateInfoShowType(currIsInfoShow, currInfoShowType, currIsOpenInfoAnimPlaying, currIsCloseInfoAnimPlaying)
  end
  if prevIsChatButtonShow ~= currIsChatButtonShow or prevIsOpenInfoAnimPlaying ~= currIsOpenInfoAnimPlaying or prevIsCloseInfoAnimPlaying ~= currIsCloseInfoAnimPlaying or prevChatButtonShowType ~= currChatButtonShowType then
    self:UpdateChatButtonShowType(currIsChatButtonShow, currChatButtonShowType, currIsOpenInfoAnimPlaying, currIsCloseInfoAnimPlaying)
  end
  if prevIsRecordButtonShow ~= currIsRecordButtonShow or prevIsOpenInfoAnimPlaying ~= currIsOpenInfoAnimPlaying or prevIsCloseInfoAnimPlaying ~= currIsCloseInfoAnimPlaying or prevRecordButtonShowType ~= currRecordButtonShowType then
    self:UpdateRecordButtonShowType(currIsRecordButtonShow, currRecordButtonShowType, currIsOpenInfoAnimPlaying, currIsCloseInfoAnimPlaying)
  end
  if prevIsShow ~= currIsShow then
    self:recordInputActionTrigger()
    if currIsShow then
      self:BindInputActionWhenIsShow()
    else
      self:UnBindInputActionWhenIsHide()
    end
  end
  if prevIsRecordButtonShow ~= currIsRecordButtonShow then
    if currIsRecordButtonShow then
      self:BindBattleRecordInputAction()
    else
      self:UnBindBattleRecordInputAction()
    end
  end
  if prevIsChatButtonShow ~= currIsChatButtonShow then
    if currIsChatButtonShow then
      self:BindBattleChatInputAction()
    else
      self:UnBindBattleChatInputAction()
    end
  end
  if prevPetHpInfoList ~= currPetHpInfoList or prevIsOpenInfoAnimPlaying ~= currIsOpenInfoAnimPlaying or prevIsCloseInfoAnimPlaying ~= currIsCloseInfoAnimPlaying or prevHpBarsAndCardDecksConstructed ~= currHpBarsAndCardDecksConstructed or prevIsPlayerSkillPerforming ~= currIsPlayerSkillPerforming or prevIsInfoShow ~= currIsInfoShow then
    local isInfoShow = currIsInfoShow or false
    if not currIsOpenInfoAnimPlaying and not currIsCloseInfoAnimPlaying and currHpBarsAndCardDecksConstructed and (not currIsPlayerSkillPerforming or not currIsInfoShow) then
      self:UpdatePetHpInfoDisplayState(currPetHpInfoList)
    end
  end
end

function UMG_BattleMainWindow_C:UpdateInfoShowType(isInfoShow, infoShowType, isOpenInfoAnimPlaying, isCloseInfoAnimPlaying)
  local nextInfoShowType = infoShowType
  if infoShowType == WidgetShowType.Hide then
    if isInfoShow then
      if isOpenInfoAnimPlaying then
        nextInfoShowType = WidgetShowType.Entering
      else
        nextInfoShowType = WidgetShowType.Show
      end
    end
  elseif infoShowType == WidgetShowType.Entering then
    if not isOpenInfoAnimPlaying then
      nextInfoShowType = WidgetShowType.Show
    end
  elseif infoShowType == WidgetShowType.Show then
    if not isInfoShow then
      if isCloseInfoAnimPlaying then
        nextInfoShowType = WidgetShowType.Exiting
      else
        nextInfoShowType = WidgetShowType.Hide
      end
    end
  elseif infoShowType == WidgetShowType.Exiting and not isCloseInfoAnimPlaying then
    nextInfoShowType = WidgetShowType.Hide
  end
  if infoShowType ~= nextInfoShowType then
    local _, nextState = self:GetCurrAndNextState()
    nextState.infoShowType = nextInfoShowType
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:UpdateChatButtonShowType(isChatButtonShow, chatButtonShowType, isOpenInfoAnimPlaying, isCloseInfoAnimPlaying)
  local nextChatButtonShowType = chatButtonShowType
  if chatButtonShowType == WidgetShowType.Hide then
    if isChatButtonShow then
      if isOpenInfoAnimPlaying then
        nextChatButtonShowType = WidgetShowType.Entering
      else
        nextChatButtonShowType = WidgetShowType.Show
      end
    end
  elseif chatButtonShowType == WidgetShowType.Entering then
    if not isOpenInfoAnimPlaying then
      nextChatButtonShowType = WidgetShowType.Show
    end
  elseif chatButtonShowType == WidgetShowType.Show then
    if not isChatButtonShow then
      if isCloseInfoAnimPlaying then
        nextChatButtonShowType = WidgetShowType.Exiting
      else
        nextChatButtonShowType = WidgetShowType.Hide
      end
    end
  elseif chatButtonShowType == WidgetShowType.Exiting and not isCloseInfoAnimPlaying then
    nextChatButtonShowType = WidgetShowType.Hide
  end
  if chatButtonShowType ~= nextChatButtonShowType then
    local _, nextState = self:GetCurrAndNextState()
    nextState.chatButtonShowType = nextChatButtonShowType
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:UpdateRecordButtonShowType(isRecordButtonShow, recordButtonShowType, isOpenInfoAnimPlaying, isCloseInfoAnimPlaying)
  local nextRecordButtonShowType = recordButtonShowType
  if recordButtonShowType == WidgetShowType.Hide then
    if isRecordButtonShow then
      if isOpenInfoAnimPlaying then
        nextRecordButtonShowType = WidgetShowType.Entering
      else
        nextRecordButtonShowType = WidgetShowType.Show
      end
    end
  elseif recordButtonShowType == WidgetShowType.Entering then
    if not isOpenInfoAnimPlaying then
      nextRecordButtonShowType = WidgetShowType.Show
    end
  elseif recordButtonShowType == WidgetShowType.Show then
    if not isRecordButtonShow then
      if isCloseInfoAnimPlaying then
        nextRecordButtonShowType = WidgetShowType.Exiting
      else
        nextRecordButtonShowType = WidgetShowType.Hide
      end
    end
  elseif recordButtonShowType == WidgetShowType.Exiting and not isCloseInfoAnimPlaying then
    nextRecordButtonShowType = WidgetShowType.Hide
  end
  if recordButtonShowType ~= nextRecordButtonShowType then
    local _, nextState = self:GetCurrAndNextState()
    nextState.recordButtonShowType = nextRecordButtonShowType
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:UpdateStateWithBattleType()
  local _, nextState = self:GetCurrAndNextState()
  nextState.isB1FinalBattleP1 = BattleUtils.IsB1FinalBattleP1()
  nextState.isB1FinalBattleP2 = BattleUtils.IsB1FinalBattleP2()
  nextState.isB1FinalBattleP3 = BattleUtils.IsB1FinalBattleP3()
  nextState.isTeamBattle = BattleUtils.IsTeam()
  self:SetState(nextState)
end

function UMG_BattleMainWindow_C:UpdateStateWithFunctionBan()
  local _, nextState = self:GetCurrAndNextState()
  local isBanChat, _ = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_BATTLE_CHAT)
  isBanChat = isBanChat or false
  nextState.isFunctionBanChatButton = isBanChat
  self:SetState(nextState)
end

function UMG_BattleMainWindow_C:HandleBattleFsmStateChanged()
  local battleManager = _G.BattleManager
  local battleStateFsm = battleManager and battleManager.stateFsm
  local activeStateName
  if battleStateFsm then
    activeStateName = battleStateFsm:GetActiveStateName()
  end
  local _, nextState = self:GetCurrAndNextState()
  nextState.battleFsmActiveStateName = activeStateName
  self:SetState(nextState)
end

function UMG_BattleMainWindow_C:HandleBattleFsmActionExit(battleFsm, fsmAction)
  local fsmStateName = fsmAction and fsmAction:GetName()
  local battleSwitchConfigActionNames = BattleConst and BattleConst.BattleSwitchConfigActionNames or {}
  if table.contains(battleSwitchConfigActionNames, fsmStateName) then
    self:UpdateStateWithBattleType()
  end
end

function UMG_BattleMainWindow_C:UpdatePetHpInfoDisplayState(petHpInfoList)
  local currState, nextState = self:GetCurrAndNextState()
  local currPetHpInfoListDisplay = currState and currState.petHpInfoListDisplay or {}
  local nextPetHpInfoListDisplay = {}
  table.copy(currPetHpInfoListDisplay, nextPetHpInfoListDisplay)
  local needShowHpPetGidList = {}
  local needHideHpPetGidList = {}
  for i, petHpInfo in ipairs(petHpInfoList) do
    local currPetDisplay = currPetHpInfoListDisplay[i]
    local currPetGuid = currPetDisplay and currPetDisplay.petGid
    local currBattlePet = currPetDisplay and currPetDisplay.battlePet
    local currUpdateFlag = currPetDisplay and currPetDisplay.updateFlag
    local nextPetGuid = petHpInfo and petHpInfo.petGid
    local nextBattlePet = petHpInfo and petHpInfo.battlePet
    local nextUpdateFlag = petHpInfo and petHpInfo.updateFlag
    if currUpdateFlag ~= nextUpdateFlag then
      local nextPetDisplay = {}
      table.copy(currPetDisplay, nextPetDisplay)
      nextPetDisplay.petGid = nextPetGuid
      nextPetDisplay.battlePet = nextBattlePet
      nextPetDisplay.updateFlag = nextUpdateFlag
      nextPetHpInfoListDisplay[i] = nextPetDisplay
      if currPetGuid and nil == nextPetGuid then
        table.insert(needHideHpPetGidList, currPetGuid)
      elseif nextPetGuid then
        table.insert(needShowHpPetGidList, nextPetGuid)
      end
    end
  end
  local needShowHpPetGidCount = #needShowHpPetGidList
  local needHideHpPetGidCount = #needHideHpPetGidList
  if needShowHpPetGidCount > 0 or needHideHpPetGidCount > 0 then
    nextState.petHpInfoListDisplay = nextPetHpInfoListDisplay
    self:SetState(nextState)
    local prevPetGidToPetHpInfo = {}
    for i, petHpInfo in ipairs(currPetHpInfoListDisplay) do
      local petGid = petHpInfo and petHpInfo.petGid
      if petGid then
        prevPetGidToPetHpInfo[petGid] = petHpInfo
      end
    end
    local petGidToPetHpInfo = {}
    for i, petHpInfo in ipairs(nextPetHpInfoListDisplay) do
      local petGid = petHpInfo and petHpInfo.petGid
      if petGid then
        petGidToPetHpInfo[petGid] = petHpInfo
      end
    end
    for i, petGid in ipairs(needShowHpPetGidList) do
      local petHpInfo = petGid and petGidToPetHpInfo and petGidToPetHpInfo[petGid]
      self:ShowPetHpInfo(petHpInfo)
    end
    for i, petGid in ipairs(needHideHpPetGidList) do
      local petHpInfo = petGid and prevPetGidToPetHpInfo and prevPetGidToPetHpInfo[petGid]
      local pet = petHpInfo and petHpInfo.battlePet
      self:HidePetInfoUI(pet)
    end
  end
end

function UMG_BattleMainWindow_C:GetProps()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetProps() or {}
end

function UMG_BattleMainWindow_C:SetProps(nextProps)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetProps(nextProps)
  end
end

function UMG_BattleMainWindow_C:GetState()
  local stateManager = self.stateManager
  return stateManager and stateManager:GetState() or {}
end

function UMG_BattleMainWindow_C:SetState(nextState)
  local stateManager = self.stateManager
  if stateManager then
    stateManager:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:GetCurrAndNextState()
  local stateManager = self.stateManager
  if stateManager then
    return stateManager:GetCurrAndNextState()
  end
  return {}, {}
end

function UMG_BattleMainWindow_C:OnBuffRefresh()
  local showPlayerSkillTutorialHighLight = BuffUtils.IsPetHasPlayerSkillBuff(self.pet)
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_UPDATE_PLAYERSKILL_TUTORIAL, showPlayerSkillTutorialHighLight)
  if BuffUtils.IsPetHasBuffByType(self.pet, Enum.BuffType.BFT_O_FORTY) then
    self.IsCatchGuiding = true
    _G.NRCModuleManager:DoCmd(_G.NewbieGuideModuleCmd.EnterGuide, 1)
  elseif self.IsCatchGuiding then
    self.IsCatchGuiding = nil
    _G.NRCModuleManager:DoCmd(_G.NewbieGuideModuleCmd.GuideFinishById, 1)
  end
end

function UMG_BattleMainWindow_C:HandleAiPerformStart(aiPerform)
  if not aiPerform then
    return
  end
  if aiPerform.type == ProtoEnum.AIPerformType.AI_PERFORM_CAM then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isAiPerformCam = true
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:HandleAiPerformOver(aiPerform)
  if not aiPerform then
    return
  end
  if aiPerform.type == ProtoEnum.AIPerformType.AI_PERFORM_CAM then
    local _, nextState = self:GetCurrAndNextState()
    nextState.isAiPerformCam = false
    self:SetState(nextState)
  end
end

function UMG_BattleMainWindow_C:OnGiveUpPressed()
  self:PlayAnimation(self.GiveUpBtn_Press)
end

function UMG_BattleMainWindow_C:OnGiveUpReleased()
  self:PlayAnimation(self.GiveUpBtn_Up)
end

function UMG_BattleMainWindow_C:TryCloseSubPanelTips()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseSkillTips)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideChangePetConfirm, true, true)
  _G.NRCModeManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
end

function UMG_BattleMainWindow_C:OpenInfoAnimStart()
  if not _G.BattleUtils.IsB1FinalBattleP3() then
    return
  end
  local isFirstEnter = _G.NRCModeManager:DoCmd(_G.B1FinalBattleModuleCmd.GetFirstEnterP2Battle)
  if not isFirstEnter then
    return
  end
  _G.NRCModeManager:DoCmd(_G.B1FinalBattleModuleCmd.SetFirstEnterP2Battle, false)
  if not self.hasPlayGradePointAnim then
    for _, Energy in ipairs(self.TeammateEnergies) do
      if Energy.battlePet and Energy.EnergyView then
        Energy.EnergyView:SetGradePoint(0)
        local maxPoint = _G.BattleManager.battleRuntimeData:GetB1PhantomPoint()
        Energy.EnergyView:SetMaxGradePoint(maxPoint)
      end
    end
    self.hasPlayGradePointAnim = true
  end
end

function UMG_BattleMainWindow_C:OpenInfoAnimEnd()
  if not _G.BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if self.hasPlayGradePointAnim then
    for _, Energy in ipairs(self.TeammateEnergies) do
      if Energy.battlePet and Energy.EnergyView then
        Energy.EnergyView:GradePointAddAnimStart()
      end
    end
    self.hasPlayGradePointAnim = nil
  end
end

function UMG_BattleMainWindow_C:InitChatBubbles()
  local FriendModule = NRCModuleManager:GetModule("FriendModule")
  if FriendModule then
    local c = FriendModule.chatBubbleController
    c:SetAutoUpdatePivot(false)
    c:SetupViewportDepth(nil, _G.UILayerCtrlCenter.ENUM_LAYER.MAIN, false)
    local battleCenter = _G.BattleManager.battleRuntimeData.TeleportBattleCenter or FVectorZero
    c:UpdatePivot(battleCenter)
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, true)
  end
end

function UMG_BattleMainWindow_C:ReleaseChatBubbles()
  local FriendModule = NRCModuleManager:GetModule("FriendModule")
  if FriendModule then
    local c = FriendModule.chatBubbleController
    c:SetAutoUpdatePivot(true)
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdUseUMGChatBubblesParent, self, false)
end

function UMG_BattleMainWindow_C:ShowChatBubbles()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdSwitchUMGChatBubblesParentVisible, true)
end

function UMG_BattleMainWindow_C:HideChatBubbles()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdSwitchUMGChatBubblesParentVisible, false)
end

function UMG_BattleMainWindow_C:OnBattleSettlement()
end

function UMG_BattleMainWindow_C:TrySelectChangePet(Index)
  local CatchPanel = self:GetSubPanel(BattleEnum.Operation.ENUM_CHANGE)
  if CatchPanel then
    CatchPanel:SelectChangePet(Index)
  end
end

function UMG_BattleMainWindow_C:TrySelectCatchBall(Index)
  local CatchPanel = self:GetSubPanel(BattleEnum.Operation.ENUM_CATCH)
  if CatchPanel then
    CatchPanel:SelectCatchBall(Index)
  end
end

function UMG_BattleMainWindow_C:TrySelectItem(Index, isPressed)
  local Panel = self:GetSubPanel(BattleEnum.Operation.ENUM_ITEM)
  if Panel then
    Panel:SelectItem(Index, isPressed)
  end
end

function UMG_BattleMainWindow_C:TrySelectSkillInfo(Index)
  local Panel = self:GetSubPanel(BattleEnum.Operation.ENUM_SKILL)
  if Panel then
    Panel:DoLongClickItem(Index)
  end
end

function UMG_BattleMainWindow_C:TrySelectSkillRun(Index, IsPressed)
  local Panel = self:GetSubPanel(BattleEnum.Operation.ENUM_SKILL)
  if Panel then
    Panel:SelectItem(Index, IsPressed)
  end
end

function UMG_BattleMainWindow_C:IsShowing()
  return self.isShowing
end

return UMG_BattleMainWindow_C
