require("UnLuaEx")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BagModuleCmd = require("NewRoco.Modules.System.Bag.BagModuleCmd")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local UMG_BattleBallEntry_C = require("NewRoco.Modules.System.BattleUI.Res.BallOperation.UMG_BattleBallEntry_C")
local BallEntryData = UMG_BattleBallEntry_C.Data
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_BattleBallOperation_C = NRCPanelBase:Extend("UMG_BattleBallOperation_C")
local ScrollBarMinAngle = -0.5
local ScrollBarMaxAngle = -25.7
local BallCountPerPage = 6

function UMG_BattleBallOperation_C:Construct()
  self.Balls = {
    self.UMG_BattleBallEntry_0,
    self.UMG_BattleBallEntry_1,
    self.UMG_BattleBallEntry_2,
    self.UMG_BattleBallEntry_3,
    self.UMG_BattleBallEntry_4,
    self.UMG_BattleBallEntry_5
  }
  self.ballListIndexToVisibleBall = {}
  self.currentBallDataList = {}
  self.ScrollBarRuntimeMaxAngle = ScrollBarMaxAngle
  self.ArcScrollView.AutoSnapWaitTime = 0.05
  self.ArcScrollView.normalizeMouseWheelData = true
  self.ArcScrollView.EnablePageNation = true
  self.ArcScrollView.PageItemCount = BallCountPerPage
  self.scrollOverThresholdSinceLastPress = false
  self.isUserScrollingSinceLastPress = false
  self.lastFrameScrollingState = false
  self.pageCount = 1
  self.ArcScrollBar:SetRenderOpacity(0)
  self.IsShow = false
  self.hasSign = false
  self.hasFirstOnActive = false
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.battleManager = _G.BattleManager
  _G.NRCEventCenter:RegisterEvent("UMG_BattleBallOperation_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  self:PCKeySetting()
  self:PlayDisplacement()
end

function UMG_BattleBallOperation_C:OnEnable(...)
  self:OnActive(...)
end

function UMG_BattleBallOperation_C:OnActive(pet, playAnim, callback)
  self:PCModeScreenSetting()
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_BALL, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.BATTLE_SCREEN_MOUSE_WHEEL, BattleEvent.UI_INSTANT_UPDATE_ITEM)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:CheckGollumBallState()
  self:SetRenderOpacity(0)
  if not self.isWaitingToShow then
    local delayFrames = self.hasFirstOnActive and 0 or 2
    self.hasFirstOnActive = true
    self.isWaitingToShow = true
    self:DelayFrames(delayFrames, self.Show, self, playAnim, callback)
  end
end

function UMG_BattleBallOperation_C:OnDisable()
  self:Hide(false)
end

function UMG_BattleBallOperation_C:OnDeactive()
  self:Hide(false)
  _G.BattleEventCenter:UnBind(self)
  self:RemoveGollumBallStateEvent()
end

function UMG_BattleBallEntry_C:WaitingRecycle()
  _G.BattleEventCenter:UnBind(self)
end

function UMG_BattleBallOperation_C:PlayDisplacement()
  if BattleUtils.IsTeam() then
    self:StopAllAnimations()
    self:PlayAnimation(self.Displacement)
  end
end

function UMG_BattleBallOperation_C:Destruct()
  table.clear(self.Balls)
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  self:UnBindInputAction()
  NRCUmgClass.Destruct(self)
end

function UMG_BattleBallOperation_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_Battle")
  if mappingContext then
    local actions = {
      {
        name = "IA_BattleMoreStart",
        method = "MoreStart"
      },
      {
        name = "IA_BattleMoreEnd",
        method = "MoreEnd"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
  if "IA_BattleMoreStart" == self.triggerInputActionName then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  end
end

function UMG_BattleBallOperation_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_Battle")
  if mappingContext then
    local actions = {
      {
        name = "IA_BattleMoreStart"
      },
      {
        name = "IA_BattleMoreEnd"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
  end
end

function UMG_BattleBallOperation_C:PCKeySetting()
  self:SetUpPCKey()
end

function UMG_BattleBallOperation_C:GetTriggerInputActionName(type)
  if 1 == type then
    return self.triggerInputActionName
  end
end

function UMG_BattleBallOperation_C:SetUpPCKey()
  if SystemSettingModuleCmd then
    if self.ExtraBallEntry then
      self.ExtraBallEntry.Text_PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleMoreStart")
      if "" ~= image then
        self.ExtraBallEntry.Text_PCKey:SetImageMode(image)
      else
        self.ExtraBallEntry.Text_PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_0 then
      self.UMG_BattleBallEntry_0.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_1")
      if "" ~= image then
        self.UMG_BattleBallEntry_0.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_0.PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_1 then
      self.UMG_BattleBallEntry_1.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_2")
      if "" ~= image then
        self.UMG_BattleBallEntry_1.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_1.PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_2 then
      self.UMG_BattleBallEntry_2.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_3")
      if "" ~= image then
        self.UMG_BattleBallEntry_2.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_2.PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_3 then
      self.UMG_BattleBallEntry_3.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_4")
      if "" ~= image then
        self.UMG_BattleBallEntry_3.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_3.PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_4 then
      self.UMG_BattleBallEntry_4.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_5")
      if "" ~= image then
        self.UMG_BattleBallEntry_4.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_4.PCKey:SetText(text)
      end
    end
    if self.UMG_BattleBallEntry_5 then
      self.UMG_BattleBallEntry_5.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_6")
      if "" ~= image then
        self.UMG_BattleBallEntry_5.PCKey:SetImageMode(image)
      else
        self.UMG_BattleBallEntry_5.PCKey:SetText(text)
      end
    end
    if self.PCKey_Big2 then
      self.PCKey_Big2:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleMoreEnd")
      if "" ~= image then
        self.PCKey_Big2:SetImageMode(image)
      else
        self.PCKey_Big2:SetText(text)
      end
    end
  end
end

function UMG_BattleBallOperation_C:RefreshSelectPCKey(balls, ballListIndexToVisibleBall)
  local visibleBallToVisibleIndex = {}
  local validBallToVisibleIndex = {}
  local currentBallList = self.currentBallDataList or {}
  local currentBallIndexList = {}
  for i, ballData in ipairs(currentBallList) do
    local ballDataIndex = ballData and ballData.index
    local ballDataValid = ballData and ballData:IsValid()
    if ballDataIndex and ballDataValid then
      table.insert(currentBallIndexList, ballDataIndex)
    end
  end
  for i, ball in ipairs(balls) do
    visibleBallToVisibleIndex[ball] = i
  end
  for i, ball in pairs(ballListIndexToVisibleBall) do
    local ballDataListContainIndex = table.contains(currentBallIndexList, i)
    local visibleIndex = visibleBallToVisibleIndex[ball]
    if ballDataListContainIndex then
      validBallToVisibleIndex[ball] = visibleIndex
    end
  end
  for i, ball in ipairs(balls) do
    if not UE.UObject.IsValid(ball) then
    else
      ball.PCKey:SetKeyVisibility(false)
    end
  end
  for ball, index in pairs(validBallToVisibleIndex) do
    if UE.UObject.IsValid(ball) then
      ball.PCKey:SetKeyVisibility(true)
      local keyName = string.format("IA_BattleSelectItemStart_%s", index)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, keyName)
      if "" ~= image then
        ball.PCKey:SetImageMode(image)
      else
        ball.PCKey:SetText(text)
      end
    end
  end
end

function UMG_BattleBallOperation_C:MoreStart()
end

function UMG_BattleBallOperation_C:MoreEnd()
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  self:OpenGollumBallUI()
end

function UMG_BattleBallOperation_C:SelectItem(index, isPressed)
  if self.Balls[index] then
    if isPressed then
      self.Balls[index]:OnItemPressed()
    else
      self.Balls[index]:OnItemRelease()
    end
  end
end

function UMG_BattleBallOperation_C:recordInputActionTrigger(inputActionName)
  self.triggerInputActionName = inputActionName
end

function UMG_BattleBallOperation_C:StopShowHide()
  self:StopAllAnimations()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_BattleBallOperation_C:Show(playAnim, callback)
  if not UE.UObject.IsValid(self) or self.isDestruct then
    return
  end
  self.isWaitingToShow = false
  self.IsShow = true
  self:RefreshCanCatchData()
  self:InitBallData()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SetRenderOpacity(1)
  self.UMG_BattleBallEntry_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_BattleBallEntry_5:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ExtraBallEntry:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TweenOutCallback = nil
  if playAnim then
    self:StopAllAnimations()
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.TweenIn)
    self:PlayAnimation(self.Line_Change_in)
    self:PlayOpenAnim(true)
  end
  self:BindInputAction()
  if callback then
    callback()
  end
  if self.TraceShinyFlowerNpc then
    self.recue:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  else
    self.recue:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if self.bEnableShinyFlowerAgainConstraint then
    self.recue:SetText(LuaText.ShinyFlower_battle_catch_tip2)
  else
    self.recue:SetText(LuaText.ShinyFlower_battle_catch_tip1)
  end
end

function UMG_BattleBallOperation_C:RefreshCanCatchData()
  local bCanCatch = true
  local CatchMsg
  local visitCatchTimes = 1
  local player = _G.BattleManager.battlePawnManager.TeamatePlayer
  local enemyPets = BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  for i, enemy in pairs(enemyPets) do
    local PetInfo = enemy:GetCard().petInfo
    if BattleUtils.IsHighValuePet(PetInfo) and _G.DataModelMgr.PlayerDataModel:IsVisitState() and not BattleUtils.IsOwnerPet(PetInfo) and not player:GetFreeCatch() then
      local PlayerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
      visitCatchTimes = PlayerPetInfo.visit_remain_shiny_catch_times or 0
      if visitCatchTimes <= 0 then
        bCanCatch = false
        CatchMsg = LuaText.visit_xuancai_catch_time_zero_text
      end
      break
    end
  end
  self.ExtraBallEntry:SetCanCatch(bCanCatch, CatchMsg)
  self.bCanCatch = bCanCatch
  self.CatchMsg = CatchMsg
end

function UMG_BattleBallOperation_C:Hide(playAnim, callback)
  self.IsShow = false
  if playAnim then
    self:StopAllAnimations()
    self:PlayAnimation(self.TweenOut)
    self:PlayAnimation(self.Line_Change_out)
    self.TweenOutCallback = callback
    self:PlayOpenAnim(false)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if callback then
      callback()
    end
  end
  self:UnBindInputAction()
end

function UMG_BattleBallOperation_C:OnAnimationFinished(Animation)
  if Animation == self.TweenIn then
  elseif Animation == self.TweenOut and not self.IsShow then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local Callback = self.TweenOutCallback
    self.TweenOutCallback = nil
    if Callback then
      Callback()
    end
  end
end

function UMG_BattleBallOperation_C:CreateBalls(ExcludeZero)
  self.hasSign = false
  self.bEnableShinyFlowerAgainConstraint = false
  local balls = {}
  if self.TraceShinyFlowerNpc == nil then
    self.TraceShinyFlowerNpc = false
    local TraceNpc = BattleUtils.GetTraceNpc()
    if TraceNpc then
      local bFlower = TraceNpc.config.genre == Enum.ClientNpcType.CNT_FLOWER_SEED
      if bFlower then
        local NpcRefreshId = TraceNpc.npc.serverData.npc_base.npc_content_cfg_id
        local FlowerInfo = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcFlowerInfo, NpcRefreshId)
        if FlowerInfo then
          self.TraceShinyFlowerNpc = TraceNpc
        end
      end
    end
  end
  if self.TraceShinyFlowerNpc then
    local ThrowCount = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcTeamBattleThrowCount, self.TraceShinyFlowerNpc.npc.serverData.npc_base.npc_content_cfg_id)
    if ThrowCount > 0 then
      self.bEnableShinyFlowerAgainConstraint = true
    end
  end
  local player = _G.BattleManager.battlePawnManager.TeamatePlayer
  if not player then
    Log.Error("UMG_BattleBallOperation_C:CreateBalls player is nil")
    return balls
  end
  local itemData = player.itemInfo or {}
  Log.Dump(itemData, 2, "Getting Item data!!!!!")
  local tempBallId
  if self.bEnableShinyFlowerAgainConstraint then
    local PetBallIdList = ActivityUtils.GetActivityGlobalConfig("ShinyFlower_again_use_ball").numList
    local PetBallIdMap = {}
    for _, Id in ipairs(PetBallIdList) do
      PetBallIdMap[Id] = true
    end
    for _, v in ipairs(itemData) do
      local flag = ExcludeZero or (v.num or 0) > 0
      if flag and v.item_type == ProtoEnum.BagItemType.BI_PET_BALL and PetBallIdMap[v.item_conf_id] then
        table.insert(balls, BallEntryData(v.item_id, v.item_conf_id, v.gid, v.num))
      end
    end
  else
    tempBallId = DataConfigManager:GetLegendaryGlobalConfig("temp_ball_id").num
    for _, v in ipairs(itemData) do
      local flag = ExcludeZero or (v.num or 0) > 0
      if flag and v.item_type == ProtoEnum.BagItemType.BI_PET_BALL then
        if v.item_conf_id == tempBallId then
          if true == v.is_temp then
            table.insert(balls, BallEntryData(v.item_id, v.item_conf_id, v.gid, v.num))
          end
        else
          table.insert(balls, BallEntryData(v.item_id, v.item_conf_id, v.gid, v.num))
        end
      end
    end
    balls = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.SortEquipBall, balls)
  end
  table.sort(balls, function(ball1, ball2)
    local ans1 = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckBallIsCollectOptimization, ball1.conf_id)
    local ans2 = _G.NRCModeManager:DoCmd(BagModuleCmd.CheckBallIsCollectOptimization, ball2.conf_id)
    if ans1 == ans2 then
      if ball1.ball_list_priority ~= ball2.ball_list_priority then
        return ball1.ball_list_priority < ball2.ball_list_priority
      end
      return ball1.conf_id < ball2.conf_id
    elseif ans1 then
      return true
    else
      return false
    end
  end)
  if tempBallId then
    balls = self:MoveItemToFirstAndSetSign(balls, tempBallId)
  end
  local pageCount = math.ceil(#balls / BallCountPerPage)
  if pageCount < 1 then
    pageCount = 1
  end
  self.pageCount = pageCount
  local totalItemCount = pageCount * BallCountPerPage
  if totalItemCount > #balls then
    for i = #balls + 1, totalItemCount do
      table.insert(balls, BallEntryData(-1, -1, -1, 0))
    end
  end
  return balls
end

function UMG_BattleBallOperation_C:RefreshBallList()
  local balls = self:CreateBalls(true)
  if not balls then
    Log.Error("UMG_BattleBallOperation_C:RefreshBallList  fail to create balls")
    return
  end
  local BallIdNumMap = {}
  for _, ball in pairs(balls) do
    if ball.id and ball.num then
      BallIdNumMap[ball.id] = ball.num
    end
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_INSTANT_UPDATE_BALL_NUM, BallIdNumMap)
end

function UMG_BattleBallOperation_C:InitBallData(bNeedSelect, selectIndex)
  self.ballListIndexToVisibleBall = {}
  local balls = self:CreateBalls()
  if not balls then
    Log.Error("UMG_BattleBallOperation_C:InitBallData  fail to create balls")
    return
  end
  self:UpdateBallDataList(balls)
  if selectIndex then
    if self.hasSign then
      selectIndex = selectIndex + 1
    end
  elseif nil == selectIndex then
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, nil)
  end
  for Index, Ball in ipairs(balls) do
    if Ball and Ball:IsValid() and selectIndex and Ball.index == selectIndex then
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, Ball)
    end
  end
  local selfBalls = self.Balls or {}
  local ballListIndexToVisibleBall = self.ballListIndexToVisibleBall or {}
  self:RefreshSelectPCKey(selfBalls, ballListIndexToVisibleBall)
  local initScrollOffset = _G.BattleManager.battleRuntimeData.ballListScrollOffset or 0
  if initScrollOffset <= 0 then
    initScrollOffset = 0.1
  end
  initScrollOffset = math.min(initScrollOffset, self.ArcScrollView:GetMaxScrollOffset())
  self.ArcScrollView:NRCSetScrollOffset(initScrollOffset)
  self.ArcScrollView:RefreshPageIndexWithOffset()
end

function UMG_BattleBallOperation_C:OpenGollumBallUI()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BATTLE_GET_BALL, true)
  if isBan then
    return
  end
  local state = self.GetGollumBall:GetVisibility()
  if state == UE4.ESlateVisibility.Collapsed or state == UE4.ESlateVisibility.Hidden then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenBattleGetGollumBall)
end

function UMG_BattleBallOperation_C:CheckGollumBallState()
  self.GetGollumBall.btnLevelUp.OnClicked:Add(self, self.OpenGollumBallUI)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BATTLE_GET_BALL, false)
  if isBan then
    self.PCKey_Big2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GetGollumBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.GetGollumBall:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if UE4Helper.IsPCMode() then
    self.PCKey_Big2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BattleBallOperation_C:RemoveGollumBallStateEvent()
  self.GetGollumBall.btnLevelUp.OnClicked:Remove(self, self.OpenGollumBallUI)
end

function UMG_BattleBallOperation_C:OnSelectExtraBall(ballGID)
  local isFound = false
  for Index, Ball in ipairs(self.Balls) do
    isFound = isFound or Ball:OnSelectExtraBall(ballGID)
  end
  local player = _G.BattleManager.battlePawnManager.TeamatePlayer
  local itemData = player.itemInfo or {}
  Log.Dump(itemData, 2, "Getting Item data!!!!!")
  local item
  for _, v in ipairs(itemData) do
    if v.gid == ballGID then
      item = v
    end
  end
  if not item then
    Log.Error("UMG_BattleBallOperation_C: Gid Not Found:", ballGID)
    return
  end
  if not isFound then
    self.ExtraBallEntry:SetData(BallEntryData(item.item_id, item.item_conf_id, item.gid, item.num))
  else
    self.ExtraBallEntry:SetData(nil)
  end
end

function UMG_BattleBallOperation_C:PlayOpenAnim(_IsOpen)
  for i = 1, #self.Balls do
    local BagItemEntry = self.Balls[i]
    if not UE.UObject.IsValid(BagItemEntry) then
    elseif _IsOpen then
      BagItemEntry.CanvasPanel_0:SetRenderOpacity(0)
      self:PlaySkillItemAnim(BagItemEntry, _IsOpen, #self.Balls - i + 1)
    else
      BagItemEntry:PlayOpenAnimation(_IsOpen)
    end
  end
end

function UMG_BattleBallOperation_C:PlaySkillItemAnim(BagItemEntry, _IsOpen, i)
  BagItemEntry:DelayPlayAnim(_IsOpen, i)
end

function UMG_BattleBallOperation_C:MoveItemToFirstAndSetSign(tab, targetConfId)
  for i, item in ipairs(tab) do
    if item.conf_id == targetConfId then
      item.sign = true
      table.remove(tab, i)
      table.insert(tab, 1, item)
      self.hasSign = true
      break
    end
  end
  return tab
end

function UMG_BattleBallOperation_C:PCModeScreenSetting()
  local pcKeyLoaderVisibility = UE.ESlateVisibility.Collapsed
  local arrowVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  if UE.UGameplayStatics.GetGameInstance(self):IsPCMode() then
    local Padding = UE4.FMargin()
    self.CanvasPanel_39:SetRenderScale(UE4.FVector2D(0.88, 0.88))
    Padding.Left = -102
    Padding.Top = -65
    Padding.Right = -110
    Padding.Bottom = -66
    self.CanvasPanel_39.Slot:SetOffsets(Padding)
    pcKeyLoaderVisibility = UE.ESlateVisibility.SelfHitTestInvisible
  else
  end
  self.PCKey_Loader:SetVisibility(pcKeyLoaderVisibility)
  self.PCKey_Loader:SetScrollMode()
  self.Arrow1:SetVisibility(arrowVisibility)
  self.Arrow2:SetVisibility(arrowVisibility)
  self.PCKey_Loader:SetVisibility(pcKeyLoaderVisibility)
end

function UMG_BattleBallOperation_C:OnTick(deltaTime)
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

function UMG_BattleBallOperation_C:OnMouseWheel(MyGeometry, InTouchEvent)
  return self.ArcScrollView:OnMouseWheel(MyGeometry, InTouchEvent)
end

function UMG_BattleBallOperation_C:SetScrollBarLength(percentage)
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

function UMG_BattleBallOperation_C:SetScrollBarBackgroundSegment(segmentCount)
  if not self.scrollBackgroundDynamicMaterial then
    self.scrollBackgroundDynamicMaterial = self.B_line:GetDynamicMaterial()
  end
  if self.scrollBackgroundDynamicMaterial then
    self.scrollBackgroundDynamicMaterial:SetScalarParameterValue("N", segmentCount)
  end
end

function UMG_BattleBallOperation_C:GetScrollBarBackgroundSelectedSegmentIndex(percentage, segmentCount)
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

function UMG_BattleBallOperation_C:SetScrollBarPosition(percentage)
  local alias = 0.05
  local indexValue = LuaMathUtils.LerpWithAlpha(1 - alias, self.pageCount + alias, percentage)
  if indexValue < 1 then
    indexValue = 1
  elseif indexValue > self.pageCount then
    indexValue = self.pageCount
  end
  if UE.UObject.IsValid(self.scrollBackgroundDynamicMaterial) then
    self.scrollBackgroundDynamicMaterial:SetScalarParameterValue("Index", indexValue)
  end
end

function UMG_BattleBallOperation_C:OnClickedBall(newClickedBallData)
  if newClickedBallData then
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallId = newClickedBallData.id
    _G.BattleManager.battleRuntimeData.catchInfo.curUseBallGID = newClickedBallData.gid
  end
  for i, ballData in ipairs(self.currentBallDataList) do
    if not ballData:IsValid() then
    else
      local ballEntry = self.ballListIndexToVisibleBall[ballData.index]
      local previousIsSelected = ballData.isSelected
      if newClickedBallData and newClickedBallData.index == ballData.index then
        ballData.isSelected = true
      elseif ballData.isSelected then
        ballData.isSelected = false
      end
      if previousIsSelected ~= ballData.isSelected and ballEntry then
        ballEntry:RefreshBallSelected()
      end
    end
  end
end

function UMG_BattleBallOperation_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_BALL then
    self:OnClickedBall(...)
  elseif eventName == BattleEvent.BATTLE_SCREEN_MOUSE_WHEEL then
    if self.IsShow then
      local MyGeometry, InTouchEvent = ...
      self:OnMouseWheel(MyGeometry, InTouchEvent)
    end
  elseif eventName == BattleEvent.UI_INSTANT_UPDATE_ITEM then
    self:RefreshBallList()
  end
end

function UMG_BattleBallOperation_C:OnBallItemSpawn(index, ballEntry)
  self:SetVisibleBallData(index, ballEntry)
end

function UMG_BattleBallOperation_C:OnBallItemDespawn(index)
  self:SetVisibleBallData(index, nil)
end

function UMG_BattleBallOperation_C:SetVisibleBallData(index, ballEntry)
  if ballEntry then
    ballEntry.fatherList = self
  end
  local prevBalls = self.Balls or {}
  local prevBallListIndexToVisibleIndex = self.ballListIndexToVisibleBall or {}
  local nextBallListIndexToVisibleIndex = {}
  for ballListIndex, ball in pairs(prevBallListIndexToVisibleIndex) do
    local ballUiIsValid = UE.UObject.IsValid(ball)
    if ballUiIsValid then
      nextBallListIndexToVisibleIndex[ballListIndex] = ball
    end
  end
  nextBallListIndexToVisibleIndex[index] = ballEntry
  local keys = {}
  for k in pairs(nextBallListIndexToVisibleIndex) do
    table.insert(keys, k)
  end
  table.sort(keys)
  local newBallList = {}
  for _, key in ipairs(keys) do
    local ball = nextBallListIndexToVisibleIndex[key]
    if UE.UObject.IsValid(ball) then
      table.insert(newBallList, ball)
    else
      Log.Warning("UMG_BattleBallOperation_C:OnVisibleBallUpdate \229\143\145\231\142\176\230\156\170\232\167\166\229\143\145 despawn \228\189\134\230\152\175\229\183\178\231\187\143\232\162\171\233\148\128\230\175\129\231\154\132\229\146\149\229\153\156\231\144\131 UMG_BattleBallEntry_C")
      nextBallListIndexToVisibleIndex[key] = nil
    end
  end
  self.Balls = newBallList
  self.ballListIndexToVisibleBall = nextBallListIndexToVisibleIndex
  self:OnVisibleBallUpdate(prevBalls, newBallList, prevBallListIndexToVisibleIndex, nextBallListIndexToVisibleIndex)
end

function UMG_BattleBallOperation_C:OnVisibleBallUpdate(prevBalls, nextBalls, prevBallListIndexToVisibleBall, nextBallListIndexToVisibleBall)
  self:RefreshSelectPCKey(nextBalls, nextBallListIndexToVisibleBall)
end

function UMG_BattleBallOperation_C:UpdateIsUserScrollingSinceLastPress(deltaTime)
  local prevIsUserScrollingSinceLastPress = self.isUserScrollingSinceLastPress
  local nextIsUserScrollingSinceLastPress = self:GetIsUserScrollingSinceLastPress()
  self.isUserScrollingSinceLastPress = nextIsUserScrollingSinceLastPress
  if prevIsUserScrollingSinceLastPress ~= nextIsUserScrollingSinceLastPress then
    self:OnIsUserScrollingSinceLastPressChanged(prevIsUserScrollingSinceLastPress, nextIsUserScrollingSinceLastPress)
  end
end

function UMG_BattleBallOperation_C:OnIsUserScrollingSinceLastPressChanged(prevValue, nextValue)
  self:OnWidgetDidUpdate(self.currentBallDataList, self.currentBallDataList, prevValue, nextValue)
end

function UMG_BattleBallOperation_C:UpdateBallDataList(newBallDataList)
  local prevBallDataList = self.currentBallDataList or {}
  self.currentBallDataList = newBallDataList
  self:OnWidgetDidUpdate(prevBallDataList, newBallDataList, self.isUserScrollingSinceLastPress, self.isUserScrollingSinceLastPress)
end

function UMG_BattleBallOperation_C:OnWidgetDidUpdate(prevBallDataList, nextBallDataList, prevIsUserScrollingSinceLastPress, nextIsUserScrollingSinceLastPress)
  local ballDataListLengthChanged = #prevBallDataList ~= #nextBallDataList
  for i, ball in ipairs(nextBallDataList) do
    ball.index = i
  end
  local bCanCatch = true
  if self.bCanCatch ~= nil then
    bCanCatch = self.bCanCatch
  end
  local catchMsg = self.CatchMsg
  local propsList = {}
  local currentBallDataList = nextBallDataList or {}
  for i, ballData in ipairs(currentBallDataList) do
    local props = {}
    props.data = ballData
    props.disableDoLongClick = nextIsUserScrollingSinceLastPress
    props.callbackOwner = self
    props.onSpawnCallback = self.OnBallItemSpawn
    props.onDespawnCallback = self.OnBallItemDespawn
    props.bCanCatch = bCanCatch
    props.catchMsg = catchMsg
    table.insert(propsList, props)
  end
  self.ArcScrollView:InitList(propsList, not ballDataListLengthChanged)
  self.ArcScrollView.HideItemPercentageThreshold = 0.3
  self.ArcScrollView.MouseWheelDataMultiplier = BallCountPerPage
  local barLengthPercentage = 1 - self.ArcScrollView:GetMaxScrollOffset() / self.ArcScrollView:GetSubCanvasPanelSize().Y
  self:SetScrollBarBackgroundSegment(self.pageCount)
  self.ScrollBarRuntimeMaxAngle = LuaMathUtils.LerpWithAlpha(ScrollBarMinAngle, ScrollBarMaxAngle, 1 - barLengthPercentage)
  if self.pageCount <= 1 then
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

function UMG_BattleBallOperation_C:SaveScrollOffset(newOffset)
  _G.BattleManager.battleRuntimeData.ballListScrollOffset = newOffset
end

function UMG_BattleBallOperation_C:IsUserScrolling()
  return self.ArcScrollView.HandlingUserScrollingCurrentFrame
end

function UMG_BattleBallOperation_C:GetIsUserScrollingSinceLastPress()
  return self.scrollOverThresholdSinceLastPress or self:IsUserScrolling()
end

function UMG_BattleBallOperation_C:HandleStartScrolling()
  self.scrollOverThresholdSinceLastPress = false
  self.startPressOffset = nil
  self.endPressOffset = nil
  self.startPressOffset = self.ArcScrollView:GetScrollOffset()
end

function UMG_BattleBallOperation_C:SelectCatchBall(Index)
  local ball = self.ArcScrollView:GetItemByIndex(Index)
  if ball then
    ball:SelectCatchBall()
    self.ArcScrollView:SelectItemByIndex(Index)
  end
end

function UMG_BattleBallOperation_C:HandleScrolling()
  if self.startPressOffset then
    local endPressOffset = self.ArcScrollView:GetScrollOffset()
    local diff = endPressOffset - self.startPressOffset
    if math.abs(diff) > BattleConst.BallOperationScrollToAnotherPageThreshold then
      self.scrollOverThresholdSinceLastPress = true
    end
  end
end

function UMG_BattleBallOperation_C:HandleEndScrolling()
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

return UMG_BattleBallOperation_C
