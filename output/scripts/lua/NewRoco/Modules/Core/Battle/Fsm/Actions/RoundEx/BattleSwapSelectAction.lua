local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleRoundSelectMarkerManager = require("NewRoco.Modules.Core.Battle.BattleRoundSelectMarkerManager")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleSwapSelectAction = BattleActionBase:Extend("BattleSwapSelectAction")
FsmUtils.MergeMembers(BattleActionBase, BattleSwapSelectAction, {})

function BattleSwapSelectAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.battleManager = _G.BattleManager
  self.SwapList = {}
  self.battleSelectMarkerMgr = BattleRoundSelectMarkerManager
  self.CurrentSelectedGuid = 0
  self:SetActionType(BattleActionBase.ActionType.ClientPlayerSelectAction)
  self.timeout = self.timeoutValue
end

function BattleSwapSelectAction:OnEnter()
  self.fsm:Pause()
  self.isBlowBuff = self.fsm:GetProperty("isBlowBuff")
  if self.battleManager.vBattleField.battleCameraManager then
    self.battleManager.vBattleField.battleCameraManager.KontrolEnabled = true
  end
  self.IsFinish = false
  self.CurrentSelectedGuid = 0
  self._player = self.battleManager.battlePawnManager.TeamatePlayer
  if not self._player then
    Log.Error("BattleSwapSelectAction:OnEnter \230\136\152\229\156\186\233\148\153\232\175\175")
    return
  end
  self._team = self._player.team
  if self.battleSelectMarkerMgr then
    self.battleSelectMarkerMgr:HideAllSelectMarkers()
    self.battleSelectMarkerMgr:ClearSelection()
    self.battleSelectMarkerMgr:HideTipTime()
    self.battleSelectMarkerMgr:HideClickTipUI()
  end
  BattleUtils.CheerPetsStartRandomMove()
  if BattleUtils.IsDeepWater() then
    local allPets = _G.BattleManager.battlePawnManager:GetAllPets()
    for _, v in ipairs(allPets) do
      v:SwimSetLockIdle(true)
    end
  end
  local PlayerOpOver = self._player:GetStateBit(ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_CLIENT_OK)
  if not PlayerOpOver and (self._player:NeedSupplyPet() or self.isBlowBuff) then
    if _G.BattleManager.battleRuntimeData:IsInReplayMode() then
      return
    end
    if self:CheckBattleDebugToolAutoSupply() then
      return
    end
    _G.BattleEventCenter:Bind(self, BattleEvent.CHANGE_OPERATE_TYPE, BattleEvent.BATTLE_CLICKED_CHANGEPET, BattleEvent.BATTLE_CLICKED_BAG_PET, BattleEvent.PET_SPAWNED, BattleEvent.SHOW_MAIN_WHEN_SKILLOVER, BattleEvent.ALL_ONLOOKER_SPAWNED)
    self.cacheRidPet = {}
    self.deadPets = {}
    self.deadOriPos = {}
    if self.isBlowBuff then
      self:CollectRidOfSupply()
    else
      self:CollectDeadSupply()
    end
    self.curSelectPetIds = {}
    self.selectPos = {}
    self.transientPets = {}
    Log.Debug("BattleSwapSelectAction ", self.supplyCount, #self.deadPets, self.isBlowBuff)
    if self.supplyCount ~= #self.deadPets then
      Log.Error("\232\161\165\229\174\160\233\152\182\230\174\181 \231\188\186\229\176\145\229\174\160\231\137\169\230\149\176\231\155\174\229\135\186\233\148\153", self.supplyCount, self._player:GetSummonNumber(), #self.deadPets)
    end
    local changePetPanelSelectedPetGuid = _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.GetSwapSelectPetGuid)
    if nil ~= changePetPanelSelectedPetGuid then
      self:UpdateTransientPets(changePetPanelSelectedPetGuid)
    end
    if BattleUtils.IsTeam() then
      _G.BattleManager:CheckForMultiBattleRunAway()
      _G.BattleEventCenter:Dispatch(BattleEvent.TEAM_SWAP_SELECT_START)
    elseif BattleUtils.HasUI("BattleRoleHpDefeatedTipPanel") then
      _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_ROLE_HP_DEFEAT_TIP_END)
    else
      _G.NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel)
    end
  else
    Log.Debug("zgx No op \231\173\137\229\190\133\230\149\140\230\150\185\232\161\165\229\174\160\239\188\140\232\191\155\229\133\165\232\161\168\230\131\133\230\181\129\231\168\139")
    self.battleManager.stateFsm:Resume()
    self.battleManager.stateFsm:SendEvent(BattleEvent.EnterWaitOther, nil, {
      self.state.name
    })
    BattleUtils.ShowPvpWaitSupplyPetTips()
  end
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetBattleHidePanelState, true)
  _G.BattleEventCenter:Dispatch(BattleEvent.SWAP_SELECT_START)
end

function BattleSwapSelectAction:GetStartOperate()
  local operateType = BattleEnum.Operation.ENUM_CHANGE
  if BattleUtils.IsWatchingBattle() then
    local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    local observeMode = 1
    if playerSettings then
      observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
    end
    if 1 == observeMode then
      operateType = BattleEnum.Operation.ENUM_NONE
    end
  end
  return operateType
end

function BattleSwapSelectAction:CollectRidOfSupply()
  for k, pet in pairs(self._player.deck.cards) do
    if pet:IsInBattle() and pet:IsBeRidOf() then
      table.insert(self.deadPets, pet)
      table.insert(self.deadOriPos, {
        pos = pet.pos,
        posInField = pet.posInField
      })
      if not self._team.pets[pet.pos] then
        Log.Warning("BattleSwapSelectAction:CollectRidOfSupply \229\174\160\231\137\169\228\184\141\229\156\168\229\156\186\239\188\140\229\143\175\232\131\189\229\183\178\231\187\143\230\173\187\228\186\161\231\166\187\229\156\186 pet ID ", pet.guid)
      end
      self.cacheRidPet[pet.posInField] = pet
      pet:HideBuffBar()
    end
  end
  if #self.deadPets <= 0 then
    Log.Error("BattleSwapSelectAction:CollectRidOfSupply \230\137\190\228\184\141\229\136\176\230\156\128\229\144\142\228\184\128\229\143\170\229\174\160\231\137\169")
  end
  local startOperate = self:GetStartOperate()
  self.battleManager:ChangeOperateMode(startOperate)
  local mainWindow = BattleUtils.GetMainWindow()
  mainWindow:SwitchToRidOfSelectPet()
  self.supplyCount = #self.deadPets
  self.supplyCount = math.min(self.supplyCount, self._player:GetSummonNumber())
end

function BattleSwapSelectAction:CollectDeadSupply()
  for k, pet in pairs(self._player.deck.cards) do
    local isCantBattle = not pet:IsAlive() or pet:IsBeCatch()
    if pet:IsInBattle() and isCantBattle then
      table.insert(self.deadPets, pet)
      table.insert(self.deadOriPos, {
        pos = pet.pos,
        posInField = pet.posInField
      })
    end
  end
  if #self.deadPets <= 0 then
    Log.Error("BattleSwapSelectAction:CollectDeadSupply \230\137\190\228\184\141\229\136\176\230\156\128\229\144\142\228\184\128\229\143\170\229\174\160\231\137\169")
  end
  local mainWindow = BattleUtils.GetMainWindow()
  if BattleUtils.IsTeam() then
    mainWindow.UMG_Battle_Operate.changeToRunAway = false
  end
  local startOperate = self:GetStartOperate()
  BattleUtils.LockCam("DeadSupply")
  self.battleManager:ChangeOperateMode(startOperate)
  if not BattleUtils.IsSupplyPetState() then
    BattleUtils.UnLockCam()
  end
  mainWindow:FocusOnCurOperate()
  local curTeam = self.battleManager.battlePawnManager.playerTeam
  self.supplyCount = curTeam:GetEmptyPosCount()
  self.supplyCount = math.min(self.supplyCount, self._player:GetSummonNumber())
end

function BattleSwapSelectAction:ChangeOperateType(operateType)
  if not self._player then
    Log.Debug("\230\178\161\230\156\137\231\142\169\229\174\182")
    return
  end
  local data = self.battleManager.battleRuntimeData
  if data.operateType ~= operateType then
    local curOperateType = data.operateType
    data.operateType = operateType
    if self.transientPets then
      for i, v in ipairs(self.deadPets) do
        if self.transientPets[i] and not self.transientPets[i].destroyed then
          self.transientPets[i]:HideClickTipUI()
          self.transientPets[i]:SetClickable(false)
          local isSelect = self:IsSelectPet(self.transientPets[i])
          if not isSelect then
            self.transientPets[i]:OnRecall()
            self.transientPets[i] = nil
          end
        end
      end
    end
    self.battleSelectMarkerMgr:HideClickTipUI()
    self.battleSelectMarkerMgr:HideAllSelectMarkers()
    self.battleSelectMarkerMgr:HideTipTime()
    self.battleManager.vBattleField.battleFieldActor:ToggleDarkScene(false)
    if BattleConst.PlayerTurnAnim[curOperateType] then
      local animName = BattleConst.PlayerTurnAnim[curOperateType][operateType]
      if animName then
        self._player:PlayAnim(animName, 1, -1, 0, 0, -1, -1)
      end
    else
      local animName = BattleConst.PlayerFinalAnim[operateType]
      local blendInTime = 0
      if operateType == BattleEnum.Operation.ENUM_CHANGE then
        blendInTime = 0.2
      end
      if animName and operateType ~= BattleEnum.Operation.ENUM_CHANGE then
        self._player:PlayAnim(animName, 1, 0, blendInTime, 0, -1, 0)
      end
    end
  elseif data.backOperateType ~= BattleEnum.Operation.ENUM_NONE then
    local animName = BattleConst.PlayerFinalAnim[data.backOperateType]
    if animName and self._player.model then
      self._player.model:PlayAnimByName(animName, 1, 0, 0, 0, -1, 0)
    else
      Log.Error("BattleSwapSelectAction:ChangeOperateType \230\137\190\228\184\141\229\136\176\229\138\168\231\148\187 or model is nil", animName, self._player)
    end
    data.backOperateType = BattleEnum.Operation.ENUM_NONE
  else
    Log.Debug("BattleRoundSelectAction: OperateType\228\184\128\232\135\180")
  end
  if operateType == BattleEnum.Operation.ENUM_CHANGE then
    self._player:ShowBag(true)
    self._player:RecallBall()
    self._player:RunAway(false)
  elseif operateType == BattleEnum.Operation.ENUM_ESCAPE then
    self._player:RunAway(true)
    self:OpenEscapeDialog()
  elseif operateType == BattleEnum.Operation.ENUM_SURRENDER then
    self._player:RunAway(true)
    self:OpenSurrenderDialog()
  else
    if operateType == BattleEnum.Operation.ENUM_STEPAWAY then
      self._player:RunAway(true)
      self:OpenStepAwayDialog()
    else
    end
  end
end

function BattleSwapSelectAction:OpenEscapeDialog()
  local EscapeDialog = _G.BattleManager.EscapeContext:SetCallback(self, self.OnDialogCallback)
  local battleType = _G.BattleManager.battleRuntimeData.battleType
  if battleType == Enum.BattleType.BT_CRUCIAL or battleType == Enum.BattleType.BT_PLOT then
    EscapeDialog:SetContent(LuaText.battleswapselectaction_1)
  else
    EscapeDialog:SetContent(LuaText.ASK_ESCAPE_BATTLE)
  end
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, EscapeDialog)
  _G.NRCAudioManager:PlaySound2DAuto(1023, "UMG_BattleMainWindow_C:OpenEscapeDialog")
end

function BattleSwapSelectAction:OpenSurrenderDialog()
  NRCModeManager:DoCmd(BattleUIModuleCmd.Open_SurrenderPanel, self.OnDialogCallback, self)
end

function BattleSwapSelectAction:OnDialogCallback(result)
  _G.BattleEventCenter:Dispatch(BattleEvent.ON_CLICK_ESCAPE, result)
end

function BattleSwapSelectAction:IsSelectPet(battlePet)
  if not self.curSelectPetIds then
    return false
  end
  for i, v in ipairs(self.curSelectPetIds) do
    if v == battlePet.guid and self.selectPos[i] == battlePet.posInField then
      return true
    end
  end
  return false
end

function BattleSwapSelectAction:OnClickBagPetIcon(petGid)
  if self._player then
    local card = self._player.team:GetCardByGuid(petGid)
    self._player:TakeBallWithCard(card, BattleEnum.Operation.ENUM_CHANGE)
    self:UpdateTransientPets(petGid)
  end
end

function BattleSwapSelectAction:UpdateTransientPets(selectedPetGuid)
  local petGid = selectedPetGuid
  for i, v in ipairs(self.deadPets) do
    local needCreate = false
    if self.transientPets[i] and not self.transientPets[i].destroyed then
      local isSelect = self:IsSelectPet(self.transientPets[i])
      if self.transientPets[i].card.guid ~= petGid then
        if isSelect then
          self.transientPets[i]:SetClickable(true)
          self.transientPets[i]:ShowClickTipUI()
          self:SetPetsDark(BattleEnum.Team.ENUM_ENEMY, true)
          self:ToggleDarkScene(true)
        else
          needCreate = true
          self.transientPets[i].team:RecallPet(self.transientPets[i])
          self.transientPets[i] = nil
        end
      elseif isSelect then
        self.transientPets[i]:SetClickable(false)
        self.transientPets[i]:HideClickTipUI()
      else
        self.transientPets[i]:SetClickable(true)
        self.transientPets[i]:ShowClickTipUI()
        self:SetPetsDark(BattleEnum.Team.ENUM_ENEMY, true)
        self:ToggleDarkScene(true)
      end
    else
      needCreate = true
    end
    if needCreate then
      self:SummonTransientPets(i, petGid, self.deadOriPos[i].pos, self.deadOriPos[i].posInField)
      self.CurrentSelectedGuid = petGid
    end
  end
end

function BattleSwapSelectAction:SummonTransientPets(index, petGuid, pos, posInField)
  local team = self.battleManager.battlePawnManager.playerTeam
  local player = team.player
  local supplyInfo = _G.ProtoMessage:newBattleSupplyPetInfo()
  supplyInfo.pet_id = petGuid
  supplyInfo.pet_pos = pos
  supplyInfo.posInField = posInField
  supplyInfo.isTransient = true
  self.transientPets[index] = player.deck:SummonPetOnce(BattleEnum.Team.ENUM_TEAM, team, {supplyInfo})[1]
  if not self.transientPets[index] then
    return
  end
  self.transientPets[index].card:SetInBattleField(false)
  self.transientPets[index].IsSkipHpRefresh = true
  self.transientPets[index].posInField = posInField
  self.transientPets[index].pos = pos
end

function BattleSwapSelectAction:PawnPetOver(pet)
  self.transientPets = self.transientPets or {}
  for idx, v in pairs(self.transientPets) do
    if v == pet then
      v.model:SetActorScale3D(UE4.FVector(1, 1, 1))
      if not self:IsSelectPet(pet) then
        if v.transparentSkill then
          v:HidePet()
          v.transparentSkill:SetEventCallback("ActionStart", self.TransparentSkillStart, self)
          v:ShowTransparent(true, true)
        else
          v:ShowPet(false)
        end
        v:SetClickable(true)
        self:SafeDelaySeconds("d_ShowClickTipUI" .. tostring(idx), 0.1, v.ShowClickTipUI, v)
        self:SetPetsDark(BattleEnum.Team.ENUM_ENEMY, true)
        self:ToggleDarkScene(true)
      else
        v:ShowPet(false)
      end
      v:ChangeBuffVisibility(false)
    end
  end
end

function BattleSwapSelectAction:TransparentSkillStart(skillPlayer)
  if skillPlayer then
    if skillPlayer.Caster then
      for idx, v in pairs(self.transientPets) do
        if v.model == skillPlayer.Caster then
          v:ShowPet(false)
          if skillPlayer.Current then
            local skill = skillPlayer.Current
            local endTime = math.max(0.001, skill:GetLength() - 0.2)
            self:SafeDelaySeconds("d_SetPlayRate" .. tostring(idx), endTime, function()
              if skill == skillPlayer.Current then
                skillPlayer.Current:SetPlayRate(0)
              end
            end)
          end
        end
      end
    end
    skillPlayer:SetEventCallback("Start")
  end
end

function BattleSwapSelectAction:ModifyPetPos()
  if self.isBlowBuff then
    for i, v in ipairs(self.deadPets) do
      v.pos = self.deadOriPos[i].pos
      v.posInField = self.deadOriPos[i].posInField
      self.transientPets[i].pos = self.deadOriPos[i].pos
      self.transientPets[i].posInField = self.deadOriPos[i].posInField
    end
  end
end

function BattleSwapSelectAction:OnChangePet(card, pet)
  local isCanClick = false
  for _, v in pairs(self.transientPets) do
    if pet == v then
      isCanClick = true
    end
  end
  if not isCanClick then
    return
  end
  if card then
    local infieldPetCard = self:TryGetBeRidOfCard(card.posInField)
    if infieldPetCard then
      local isValidIfInfieldPetHasBuff145 = self:IsUpPetValidIfInfieldPetHasBuff145(card, infieldPetCard)
      if not isValidIfInfieldPetHasBuff145 then
        self:ShowBuff145NotMatchTips()
        return
      end
    end
  end
  self:ModifyPetPos()
  for _, v in pairs(self.transientPets) do
    v:HideClickTipUI()
  end
  self:ResetPetsLight()
  self:ToggleDarkScene(false)
  if self:IsSelectPet(pet) then
    for i, v in ipairs(self.curSelectPetIds) do
      if v == pet.guid then
        self.curSelectPetIds[i] = card.guid
        break
      end
    end
  elseif table.contains(self.curSelectPetIds, pet.guid) then
    for i, v in ipairs(self.curSelectPetIds) do
      if v == pet.guid then
        self.selectPos[i] = pet.posInField
        break
      end
    end
  else
    self.supplyCount = self.supplyCount - 1
    table.insert(self.curSelectPetIds, card.guid)
    table.insert(self.selectPos, pet.posInField)
  end
  if self.supplyCount > 0 then
    for i = #self.transientPets, 1, -1 do
      local transientPet = self.transientPets[i]
      if transientPet == pet then
        transientPet:ShowTransparent(false)
        if transientPet.guid ~= card.guid then
          self:SummonTransientPets(i, card.guid, transientPet.pos, transientPet.posInField)
          transientPet.team:RecallPet(transientPet)
        end
      elseif not self:IsSelectPet(transientPet) then
        transientPet.team:RecallPet(transientPet)
        self.transientPets[i] = nil
      elseif transientPet.guid == card.guid then
        transientPet.team:RecallPet(transientPet)
        self.transientPets[i] = nil
      end
    end
  else
    self:SendSwapSelectionReq()
  end
end

function BattleSwapSelectAction:SendSwapSelectionReq()
  self:ClearTransientPets()
  if self.isBlowBuff then
    local req = BattleNetManager:BuildBattleCmdPushbackReq()
    req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET
    local battleList, restList = self:ModifyCrossSwap()
    local BattleRoundFlowReqList = {}
    for i, v in ipairs(battleList) do
      local BattleRoundFlowReq = {}
      BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET
      BattleRoundFlowReq.change_pet = {}
      BattleRoundFlowReq.change_pet.rest_pet_id = restList[i]
      BattleRoundFlowReq.change_pet.battle_pet_id = battleList[i]
      BattleRoundFlowReq.change_pet.player_id = self._player.guid
      table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
    end
    self.cmdPushbackReq = req
    req.req = BattleRoundFlowReqList
    Log.Dump(req, 5, "BattleSwapSelectAction:SendSwapSelectionReq blow")
    _G.BattleNetManager:SendBattleCmdPushbackReq(req, self, self.OnPushbackSent)
  elseif BattleUtils.IsTeam() then
    local req = BattleNetManager:BuildBattleCmdPushbackReq()
    req.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET
    local BattleRoundFlowReqList = {}
    for i = 1, #self.curSelectPetIds do
      for _, v in ipairs(self.deadPets) do
        if self.selectPos[i] == v.posInField then
          local BattleRoundFlowReq = {}
          BattleRoundFlowReq.req_type = _G.ProtoEnum.BATTLE_REQ_TYPE.CMD_CHANGE_PET
          BattleRoundFlowReq.change_pet = {}
          BattleRoundFlowReq.change_pet.rest_pet_id = v.guid
          BattleRoundFlowReq.change_pet.battle_pet_id = self.curSelectPetIds[i]
          BattleRoundFlowReq.change_pet.player_id = self._player.guid
          table.insert(BattleRoundFlowReqList, BattleRoundFlowReq)
        end
      end
    end
    self.cmdPushbackReq = req
    req.req = BattleRoundFlowReqList
    Log.Dump(req, 5, "BattleSwapSelectAction:SendSwapSelectionReq Team")
    _G.BattleNetManager:SendBattleCmdPushbackReq(req, self, self.OnPushbackSent)
  else
    local supplyReq = _G.ProtoMessage:newZoneBattleSupplyPetReq()
    supplyReq.pet_id = self.curSelectPetIds
    for i = 1, #self.curSelectPetIds do
      for _, v in ipairs(self.deadPets) do
        if self.selectPos[i] == v.posInField then
          supplyReq.pet_pos[i] = v.pos
        end
      end
    end
    Log.Dump(supplyReq, 2, "BattleSwapSelectAction:SendSwapSelectionReq Supply")
    _G.BattleNetManager:SendBattleSupplyPetReqWithHandle(supplyReq, self, self.OnSupplyReqBack)
  end
  self:CheckRoleHp()
  self.selectPos = {}
  self.curSelectPetIds = {}
end

function BattleSwapSelectAction:OnSupplyReqBack(rsp)
  local team = BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  if 0 == rsp.ret_info.ret_code and (BattleUtils.IsPvp() or team and #team > 1) then
    self:SafeDelaySeconds("d_OnSupplyReqBack", 0.5, function()
      if not self.IsFinish and 0 == self.fsm:GetEventNumber() and (self.fsm:GetActiveStateName() == BattleEnum.StateNames.RoundSelect or self.fsm:GetActiveStateName() == BattleEnum.StateNames.SwapSelect or self.fsm:GetActiveStateName() == BattleEnum.StateNames.SelectRidPet) and not self.fsm:GetNextStateName() then
        Log.Debug("zgx No op \232\161\165\229\174\160\230\136\144\229\138\159 \232\191\155\229\133\165\232\161\168\230\131\133\230\181\129\231\168\139")
        self.fsm:SendEvent(BattleEvent.EnterWaitOther)
      end
    end)
  end
end

function BattleSwapSelectAction:ModifyCrossSwap()
  local tInsert = table.insert
  local battleList = {}
  local restList = {}
  local tempRestList = {}
  for i = 1, #self.curSelectPetIds do
    for _, v in ipairs(self.deadPets) do
      if self.selectPos[i] == v.posInField and self.cacheRidPet[self.selectPos[i]] then
        local up = self.curSelectPetIds[i]
        local down = self.cacheRidPet[self.selectPos[i]].guid
        if table.contains(battleList, down) then
          tInsert(battleList, 1, up)
          tInsert(restList, 1, down)
          tInsert(tempRestList, 1, down)
        else
          tInsert(battleList, up)
          tInsert(restList, down)
          tInsert(tempRestList, down)
        end
      end
    end
  end
  for i = 1, #battleList do
    table.removeValue(tempRestList, battleList[i])
  end
  if 0 == #tempRestList then
    restList = battleList
  end
  return battleList, restList
end

function BattleSwapSelectAction:CheckRoleHp()
  local hp = self.battleManager.battlePawnManager:GetPlayerMyTeam().roleInfo.base.hp
  local petIDs = self.curSelectPetIds
  local hp_need = 0
  for i, id in ipairs(petIDs) do
    local card = self.battleManager.battlePawnManager:GetPlayerMyTeam().deck:GetCardByGuid(id)
    local baseID = card.petInfo.battle_common_pet_info.base_conf_id
    local baseConf = _G.DataConfigManager:GetPetbaseConf(baseID)
    if not baseConf then
      Log.Error("Pet base ID not found: ", baseID)
      self:Finish()
      return
    end
    hp_need = hp_need + baseConf.consume_role_hp
  end
  if hp > hp_need then
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBattleRedPanel)
  else
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattleRedPanel)
  end
end

function BattleSwapSelectAction:ClearTransientPets()
  if self.transientPets then
    for _, v in pairs(self.transientPets) do
      v.team:RecallPet(v)
    end
    self.transientPets = {}
  end
end

function BattleSwapSelectAction:OnPushbackSent(rsp)
  Log.Dump(rsp, 5, "BattleSwapSelectAction:OnPushbackSent")
  local player = BattleManager.battlePawnManager.TeamatePlayer
  local team = player.team
  local restPet = player.deck:GetCardByGuid(rsp.req.change_pet.rest_pet_id)
  restPet:SetInBattleField(true)
  restPet:SetBeRidOf(false)
  if self.isBlowBuff then
    local restGuid = self.cacheRidPet[restPet.posInField].guid
    team.pets[restPet.pos] = BattleManager.battlePawnManager:GetPetByGuid(restGuid)
    self:ResetRidState()
  end
  local playerTeam = BattleManager.battlePawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  if 0 == rsp.ret_info.ret_code and (BattleUtils.IsPvp() or playerTeam and #playerTeam > 1) then
    self:SafeDelaySeconds("d_OnPushbackSent", 0.5, function()
      if not self.IsFinish and 0 == self.fsm:GetEventNumber() and (self.fsm:GetActiveStateName() == BattleEnum.StateNames.SelectRidPet or self.fsm:GetActiveStateName() == BattleEnum.StateNames.SwapSelect) and not self.fsm:GetNextStateName() then
        Log.Debug("zgx No op \232\161\165\229\174\160\230\136\144\229\138\159 \232\191\155\229\133\165\232\161\168\230\131\133\230\181\129\231\168\139\239\188\136\229\144\185\233\163\158\239\188\137")
        self.fsm:SendEvent(BattleEvent.EnterWaitOther)
      end
    end)
  end
end

function BattleSwapSelectAction:ResetRidState()
  self.cacheRidPet = nil
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:RefreshOperatePanel()
  end
  self.isBlowBuff = false
  self.fsm:SetProperty("isBlowBuff", nil)
end

function BattleSwapSelectAction:OnFinish()
  if self.battleManager.vBattleField.battleCameraManager then
    self.battleManager.vBattleField.battleCameraManager.KontrolEnabled = false
  end
  self.fsm:Resume()
  self:ClearTransientPets()
  if self._player then
    self._player:StopAll()
    self._player.team:ResumeRest()
  end
  if self.isBlowBuff then
    self._player.deck:ClearRidState()
    self:ResetRidState()
  end
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:FreeOperate()
  end
  self.selectPos = {}
  self.curSelectPetIds = {}
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetBattleHidePanelState, false)
  _G.BattleEventCenter:UnBind(self)
  self.IsFinish = true
end

function BattleSwapSelectAction:OnExit()
  if self._player then
    self._player:StopAll()
    self._player.team:ResumeRest()
  end
  self:ResetPetsLight()
  BattleUtils.CheerPetsStopRandomMove()
  self:ClearTransientPets()
  self.deadPets = {}
  self.deadOriPos = {}
  self.selectPos = {}
  self._player = nil
  self._team = nil
  self.CurrentSelectedGuid = 0
  self.IsFinish = true
end

function BattleSwapSelectAction:OnBattleEvent(eventName, ...)
  if not BattleManager:IsInBattle(true) then
    return
  end
  if eventName == BattleEvent.CHANGE_OPERATE_TYPE then
    self:ChangeOperateType(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_CHANGEPET then
    self:OnChangePet(...)
    return true
  elseif eventName == BattleEvent.BATTLE_CLICKED_BAG_PET then
    self:OnClickBagPetIcon(...)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:PawnPetOver(...)
    return true
  elseif eventName == BattleEvent.SHOW_MAIN_WHEN_SKILLOVER then
    if self.battleManager then
      self.battleManager:ChangeOperateMode(BattleEnum.Operation.ENUM_CHANGE)
    end
    return true
  end
end

function BattleSwapSelectAction:ToggleDarkScene(dark)
  if not _G.BattleManager then
    return
  end
  local BattleField = _G.BattleManager.vBattleField
  if not BattleField then
    return
  end
  local BattleFieldActor = BattleField.battleFieldActor
  if not BattleFieldActor then
    return
  end
  BattleFieldActor:ToggleDarkScene(dark)
end

function BattleSwapSelectAction:ResetPetsLight()
  self:SetPetsDark(BattleEnum.Team.ENUM_ENEMY, false)
  self:SetPetsDark(BattleEnum.Team.ENUM_TEAM, false)
end

function BattleSwapSelectAction:SetPetsDark(type, on)
  if type == BattleEnum.Team.ENUM_TEAM then
    local playerTeam = _G.BattleManager.battlePawnManager.playerTeam
    if playerTeam and playerTeam.pets then
      for _, player in pairs(playerTeam.pets) do
        player:SetDark(on)
      end
    end
  elseif type == BattleEnum.Team.ENUM_ENEMY then
    local enemyTeam = _G.BattleManager.battlePawnManager.enemyTeam
    if enemyTeam and enemyTeam.pets then
      for _, enemy in pairs(enemyTeam.pets) do
        enemy:SetDark(on)
      end
    end
  else
    Log.Error("Invalid type of team found")
  end
end

function BattleSwapSelectAction:OpenStepAwayDialog()
  local StepAwayDialog = DialogContext()
  StepAwayDialog:SetCallback(self, self.OnStepAwayDialogCallback)
  StepAwayDialog:SetContent(LuaText.legendary_battle_tips_3)
  StepAwayDialog:SetTitle(LuaText.TIPS)
  StepAwayDialog:SetMode(DialogContext.Mode.OK_CANCEL)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, StepAwayDialog)
  _G.NRCAudioManager:PlaySound2DAuto(1291, "UMG_BattleMainWindow_C:OpenStepAwayDialog")
end

function BattleSwapSelectAction:CheckBattleDebugToolAutoSupply()
  local battleDebugControl = _G.BattleManager.battleRuntimeData.battleDebugControl
  if battleDebugControl and battleDebugControl:NeedAutoSupplyPet() then
    return true
  end
  return false
end

function BattleSwapSelectAction:OnStepAwayDialogCallback(result)
  if result then
    _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_BattleMainWindow_C:ClickYes")
  else
    _G.NRCAudioManager:PlaySound2DAuto(1006, "UMG_BattleMainWindow_C:ClickNo")
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.ON_CLICK_STEPAWAY, result)
end

function BattleSwapSelectAction:TryGetBeRidOfCard(posInField)
  return self.cacheRidPet and self.cacheRidPet[posInField]
end

function BattleSwapSelectAction:IsUpPetValidIfInfieldPetHasBuff145(upPetCard, infieldPetCard)
  local inFieldPetInfo = infieldPetCard and infieldPetCard.petInfo
  local inFieldInsideInfo = inFieldPetInfo and inFieldPetInfo.battle_inside_pet_info
  local buff145SourcePetId = inFieldInsideInfo and inFieldInsideInfo.buff145_source_pet
  local isGenerateByBuff145 = buff145SourcePetId and buff145SourcePetId > 0
  local upPetInfoId = upPetCard and upPetCard.guid
  local isNotValid = isGenerateByBuff145 and buff145SourcePetId ~= upPetInfoId
  local isValid = not isNotValid
  if isValid then
    local currMyPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true) or {}
    local currMyPetsCount = #currMyPets
    if currMyPetsCount > 0 then
      local upPetInfo = upPetCard and upPetCard.petInfo
      local upInsideInfo = upPetInfo and upPetInfo.battle_inside_pet_info
      local upBuff145SourcePetId = upInsideInfo and upInsideInfo.buff145_source_pet
      local upIsGenerateByBuff145 = upBuff145SourcePetId and upBuff145SourcePetId > 0
      local infieldPetInfoId = infieldPetCard and infieldPetCard.guid
      isNotValid = upIsGenerateByBuff145 and upBuff145SourcePetId ~= infieldPetInfoId
      isValid = not isNotValid
    end
  end
  return isValid
end

function BattleSwapSelectAction:ShowBuff145NotMatchTips()
  local currMyPets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true) or {}
  local currMyPetsCount = #currMyPets
  Log.Info("BattleSwapSelectAction:OnChangePet: The in field pet has buff145 and the up pet is not the source pet if it.")
  local buff145SwapErrorTextConf = _G.DataConfigManager:GetLocalizationConf("buff _145_1", true)
  if currMyPetsCount > 0 then
    buff145SwapErrorTextConf = _G.DataConfigManager:GetLocalizationConf("buff _145_2", true)
  end
  local buff145SwapErrorText = buff145SwapErrorTextConf and buff145SwapErrorTextConf.msg
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, buff145SwapErrorText)
end

return BattleSwapSelectAction
