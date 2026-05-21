local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleRoundAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Round.BattleRoundAction")
local ClickTipData = require("NewRoco.Modules.System.BattleUI.Res.HUD.UMG_Battle_ClickTipUI_C").Data
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local Base = BattleRoundAction
local BallEntryData = require("NewRoco.Modules.System.BattleUI.Res.BallOperation.UMG_BattleBallEntry_C").Data
local RoundCatchAction = Base:Extend("RoundCatchAction")
FsmUtils.MergeMembers(Base, RoundCatchAction, {})

function RoundCatchAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.isWaitRsp = 0
  self.catch_pet_owner_uni = nil
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
end

function RoundCatchAction:OnEnter()
  Base.OnEnter(self)
  _G.BattleManager.vBattleField.battleCraneCamera:CheckJumpAnim()
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_CLICKED_BALL, BattleEvent.BATTLE_CLICKED_PET, BattleEvent.ReconnetBattle_RoundStrart)
  if self.CurrentEnemyPets and self.CurrentPlayer then
    for _, v in ipairs(self.CurrentEnemyPets) do
      v:SetLookAt(self.CurrentPlayer.model)
    end
  end
  if self.CurrentPlayer then
    self.CurrentPlayer:ShowBag(true)
    local Ball = self:GetFirstBall()
    if Ball then
      self.CurrentPlayer:TakeBallWithID(Ball.item_conf_id, BattleEnum.Operation.ENUM_CATCH)
    else
      self.CurrentPlayer:TakeBall(nil, BattleEnum.Operation.ENUM_CATCH)
    end
  end
  _G.BattleManager.battleRuntimeData.catchInfo.curUseBallGID = nil
  _G.BattleManager.battleRuntimeData.catchInfo.curUseBallId = nil
  self:HideTeamBattleHp()
end

function RoundCatchAction:HideTeamBattleHp()
  if BattleUtils.IsTeam() then
    _G.BattleEventCenter:Dispatch(BattleEvent.HIDE_TEAMBATTLE_HP)
  end
end

function RoundCatchAction:DefaultSelectBall()
  local EquipItem = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetCurEquipItemInfo)
  if EquipItem then
    local ballData = BallEntryData(nil, EquipItem.id, EquipItem.gid, EquipItem.num)
    self:OnClickedBall(ballData)
  end
end

function RoundCatchAction:IsCanCatch()
  if BattleUtils.IsBloodTeam() then
    if BattleUtils:TeamIsCanCatch() then
      return true
    end
    local showTipIfSelectItemNotEnough = true
    if _G.NRCModeManager:DoCmd(BattleUIModuleCmd.IsSelectRecoveryItemEnough, showTipIfSelectItemNotEnough) then
      Log.Debug("RoundCatchAction:IsCanCatch show selected recovery item is not enough tips")
    end
    return false
  end
  return true
end

function RoundCatchAction:OnClickedBall(ballData)
  Log.Debug("BattleRoundSelectAction:OnClickedBall")
  _G.BattleManager.battleRuntimeData.catchInfo.currentBallData = ballData
  if nil == ballData then
    self.SelectMarkerManager:HideClickTipUI()
    return
  elseif not self:IsCanCatch() then
    self:SafeDelayFrames("d_UndoClickBall", 1, function()
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, nil)
    end)
    return
  end
  if self.CurrentPlayer.QuicklyCatchBallId > 0 and self.CurrentPlayer.QuicklyCatchBallId ~= ballData.conf_id then
    self.CurrentPlayer:SetQuicklyCatchBall(-1, true)
  end
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:ShowSelectMarkers(BattleEnum.SelectMarkerType.ENUM_ENEMY)
  local runtimeData = _G.BattleManager.battleRuntimeData
  local catchRates = {}
  _G.BattleManager.battleRuntimeData.catchInfo.lastCatchRatesClient = {}
  local CatchTargets = {}
  if self.CurrentEnemyPets then
    for _, enemy in pairs(self.CurrentEnemyPets) do
      if enemy.card:IsCanSelect() then
        table.insert(CatchTargets, enemy.model)
        local Card = enemy:GetCard()
        local catchRate = BattleUtils.CalculateCatchMonsterRateBattle(ballData.conf_id, Card.guid)
        local Anim = Card:GetCatchAnimByCatchRate(catchRate)
        local CatchGrade = BattleUtils.GetCatchRateGrade(catchRate)
        if not enemy.card.petState:GetStatic() and not enemy.card.petState:GetDrill() and not enemy.card.petState:GetMimic() then
          enemy:PlayAnimByName(Anim, 1, -1, 0, 0, 1, -1)
          enemy:SetHighlight(true, true)
        end
        table.insert(catchRates, {
          guid = enemy.card.guid,
          name = enemy.card.petBaseConf.name,
          rate = catchRate,
          ballConfID = ballData.conf_id
        })
        local params = {}
        local isCatchRateLow = BattleUtils.IsCatchRateInvalidLow(catchRate)
        if isCatchRateLow then
          table.insert(params, true)
        end
        if BattleUtils.IsTeam() then
          enemy:ShowClickTipUI(ClickTipData(nil, nil, 3))
        else
          enemy:ShowClickTipUI(ClickTipData(nil, nil, CatchGrade))
        end
        local is_high_value = BattleUtils.IsHighValuePet(Card.petInfo)
        local isInVisitCatch = false
        if is_high_value and _G.DataModelMgr.PlayerDataModel:IsVisitState() and not BattleUtils.IsOwnerPet(Card.petInfo) and not BattleUtils.IsBeastTeam() then
          local PlayerPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
          local visitCatchTimes = is_high_value and PlayerPetInfo.visit_remain_shiny_catch_times or 1
          isInVisitCatch = true
          params.isInVisitCatch = visitCatchTimes
          params.isInVisitGlassCatch = is_high_value
          params.is_high_value = is_high_value
          params.free_catch = self.CurrentPlayer:GetFreeCatch()
        end
        if isInVisitCatch and is_high_value then
          enemy:ShowTipTime(1, BattleEnum.Operation.ENUM_CATCH, params)
        else
          enemy:ShowTipTime(-1, BattleEnum.Operation.ENUM_CATCH, params)
        end
      end
    end
    self:ToggleDarkScene(true, CatchTargets)
    self:SetPetsDark(BattleEnum.Team.ENUM_TEAM, true)
  end
  runtimeData.catchInfo.lastCatchRatesClient = catchRates
  self.CurrentPlayer:ShowBag(false)
  self.CurrentPlayer:TakeBallWithID(ballData.conf_id or 0, BattleEnum.Operation.ENUM_CATCH)
  _G.BattleEventCenter:Dispatch(BattleEvent.OnBallChanged, ballData.conf_id)
end

function RoundCatchAction:OnPetClicked(Pet)
  if os.time() - self.isWaitRsp < 0.5 then
    return
  end
  Log.Debug("BattleRoundSelectAction:OnPetClicked")
  local data = _G.BattleManager.battleRuntimeData
  self.SelectMarkerManager:HideClickTipUI()
  if data.catchInfo.curUseBallId and data.catchInfo.curUseBallId < 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.NO_SELECT_BALL)
    return
  end
  Log.DebugFormat("show catch count (%d/%d)", data.catchInfo.curCatchTime, data.catchInfo.maxCatchTime)
  if data.catchInfo.curCatchTime <= 0 then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.CATCH_INFO_CATCH_TIME_OVER)
    return
  end
  if BattleUtils.IsTeam() and not BattleUtils.TeamIsCanCatch() then
    local showTipIfSelectItemNotEnough = true
    if _G.NRCModeManager:DoCmd(BattleUIModuleCmd.IsSelectRecoveryItemEnough, showTipIfSelectItemNotEnough) then
      Log.Debug("RoundCatchAction:OnPetClicked show selected recovery item is not enough tips")
    end
    return
  end
  if data.catchInfo.currentBallData == nil then
    Log.Error("[kunfu] data.catchInfo.currentBallData is nil")
    return
  end
  self:ResetPetsLight()
  self:ToggleDarkScene(false)
  if self.CurrentPet then
    self.CurrentPet:SetHighlight(false)
  end
  self:SetEnemyPetHighlight(false)
  self.SelectMarkerManager:ClearSelection()
  local Card = Pet.card
  local req = BattleNetManager:BuildBattleCmdPushbackReq()
  req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CATCH_PET
  local BattleRoundFlowReq = {}
  BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CATCH_PET
  BattleRoundFlowReq.catch_pet = {}
  BattleRoundFlowReq.catch_pet.item_id = data.catchInfo.curUseBallId
  BattleRoundFlowReq.catch_pet.monster_id = Card.petInfo.battle_inside_pet_info.pet_id
  local selectRecoveryItemType = _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.GetSelectRecoveryItem)
  if selectRecoveryItemType then
    BattleRoundFlowReq.catch_pet.flower_catch_vitem = selectRecoveryItemType
  end
  table.insert(req.req, BattleRoundFlowReq)
  self.CatchPet = Pet
  self.CatchPetId = Card.guid
  self.catch_pet_owner_uni = Card.petInfo.battle_inside_pet_info.owner_uin
  self.fsm:SetProperty("WillCatchPet", true)
  self.isWaitRsp = os.time()
  self:SendPushbackReq(req)
end

function RoundCatchAction:OnPushbackSent(rsp)
  self.isWaitRsp = 0
  if 0 ~= rsp.ret_info.ret_code then
    if ProtoEnum.MOBA_RET.BattleErr.ERR_BATTLE_CATCH_BALL_CAN_NOT_USE == rsp.ret_info.ret_code then
      local ballId = rsp.req.catch_pet.item_id
      local player = self.CurrentPlayer or BattleManager.battlePawnManager.TeamatePlayer
      local ball_item_id = 1
      if player then
        for _, v in ipairs(player.itemInfo) do
          if v.item_type == ProtoEnum.BagItemType.BI_PET_BALL and v.item_id == ballId then
            ball_item_id = v.item_conf_id
            break
          end
        end
      end
      local ball_name = tostring(ball_item_id)
      local bag_item = _G.DataConfigManager:GetBagItemConf(ball_item_id, true)
      if bag_item then
        ball_name = bag_item.name
      end
      local ErrorText = string.format(_G.LuaText.cant_use_glass_ball, ball_name)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, ErrorText)
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL)
    elseif ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_SHINY_CATCH_TIMES_LIMIT == rsp.ret_info.ret_code then
      _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, nil)
    elseif ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_VISIT_HIGH_VALUE_PET_CATCH_NEED_FRIEND_TIMES == rsp.ret_info.ret_code then
      if self.catch_pet_owner_uni then
        local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
        local tips
        local pet_owner_player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.catch_pet_owner_uni)
        if pet_owner_player then
          local pet_owner_player_name = pet_owner_player:GetName()
          if _G.DataModelMgr.PlayerDataModel:IsFriend(self.catch_pet_owner_uni) then
            local seconds = player:GetFriendSeconds(self.catch_pet_owner_uni)
            local friend_timecheck = _G.DataConfigManager:GetGlobalConfigByKey("highvalue_pet_battle_rule_friend_timecheck")
            if friend_timecheck and seconds < friend_timecheck.num then
              local tip = _G.DataConfigManager:GetLocalizationConf("Highvaluepet_Owner_Rule_Friendtime").msg
              tips = string.format(tip, pet_owner_player_name, math.floor(friend_timecheck.num / 3600))
            end
          else
            local tip = _G.DataConfigManager:GetLocalizationConf("Highvaluepet_Owner_Rule_Nonfriend").msg
            tips = string.format(tip, pet_owner_player_name)
          end
          if nil ~= tips then
            _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tips)
          else
            Log.Error(string.format("lsr ZoneSceneCatchMonsterRsp error!!! code is %s, catch_pet_owner_uni is %s", rsp.ret_info.ret_code, self.catch_pet_owner_uni))
          end
        else
          Log.Error(string.format("lsr ZoneSceneCatchMonsterRsp error!!! pet_owner_player is nil, catch_pet_owner_uni is %s", self.catch_pet_owner_uni))
        end
        self.catch_pet_owner_uni = nil
      else
        Log.Error(string.format("lsr ZoneSceneCatchMonsterRsp error!!! CatchPet is nil"))
      end
    else
      Log.Error("zgx ZoneSceneCatchMonsterRsp error!!! code is ", rsp.ret_info.ret_code)
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL)
    return
  end
  local runtimeData = _G.BattleManager.battleRuntimeData
  self.SelectMarkerManager:HideTipTime()
  runtimeData.catchInfo.curCatchTime = runtimeData.catchInfo.curCatchTime - 1
  _G.BattleEventCenter:Dispatch(BattleEvent.HIDE_TEAM_HP)
  Base.OnPushbackSent(self, rsp)
end

function RoundCatchAction:GetFirstBall()
  local player = _G.BattleManager.battlePawnManager.TeamatePlayer
  local ItemInfos = player.itemInfo or {}
  local sortedItems = {}
  for i, item in ipairs(ItemInfos) do
    sortedItems[i] = item
  end
  table.sort(sortedItems, function(a, b)
    return a.item_conf_id < b.item_conf_id
  end)
  for _, item in ipairs(sortedItems) do
    if item.item_type == ProtoEnum.BagItemType.BI_PET_BALL then
      return item
    end
  end
  return nil
end

function RoundCatchAction:OnReconnectBattleRoundStart()
  local catchInfo = _G.BattleManager.battleRuntimeData.catchInfo
  local ballData = catchInfo and catchInfo.currentBallData
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_CLICKED_BALL, ballData)
end

function RoundCatchAction:OnExit()
  _G.BattleEventCenter:UnBind(self)
  self:ResetPetsLight()
  self.SelectMarkerManager:ClearSelection()
  self.SelectMarkerManager:HideClickTipUI()
  if self.CurrentPet then
    self.CurrentPet:SetHighlight(false)
  end
  self.CatchPet = nil
  _G.BattleManager.battleRuntimeData.catchInfo.currentBallData = nil
  _G.BattleManager.vBattleField.battleCraneCamera:CheckJumpAnim()
  Base.OnExit(self)
end

function RoundCatchAction:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_CLICKED_BALL then
    self:OnClickedBall(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_PET then
    self:OnPetClicked(...)
    return true
  elseif eventName == BattleEvent.ReconnetBattle_RoundStrart then
    self:OnReconnectBattleRoundStart()
    return true
  end
end

return RoundCatchAction
