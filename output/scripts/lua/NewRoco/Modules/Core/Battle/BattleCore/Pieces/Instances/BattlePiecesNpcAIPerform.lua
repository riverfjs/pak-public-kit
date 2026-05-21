local BattlePiecesBase = require("NewRoco.Modules.Core.Battle.BattleCore.Pieces.BattlePiecesBase")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local DialogueModuleCmd = require("NewRoco.Modules.System.Dialogue.DialogueModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local Base = BattlePiecesBase
local BattlePiecesNpcAIPerform = Base:Extend("BattlePiecesNpcAIPerform")

function BattlePiecesNpcAIPerform:Ctor(pieceData, node)
  Base.Ctor(self, pieceData, node)
end

function BattlePiecesNpcAIPerform:Play()
  if self.pieceData.performInfo.type ~= ProtoEnum.BattlePerformType.BPT_AI then
    return
  end
  self.isRunning = true
  self.ai_perform = self.pieceData.performInfo.ai_perform
  if _G.BattleManager.battleRuntimeData:IsJumpAiPerform() or _G.BattleManager.battleRuntimeData:IsOnBattleTest() then
    Log.Warning("BattlePiecesNpcAIPerform:Play \232\182\133\230\151\182\232\183\179\232\191\135\232\138\130\231\130\185", self.ai_perform.type, self.ai_perform.str_param)
    self.node:DispatchPerformCallback(ProtoEnum.Buffbasetrigger_type.OnHit)
    self.node:PerformComplete()
    return
  end
  _G.BattleEventCenter:Dispatch(BattlePerformEvent.AiPerformStart, self.ai_perform)
  if self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CG then
    self.isPausePerformPlayer = true
    self.performPlayer:Pause()
    local param = {}
    param.caller = self
    param.callback = self.DelayComplete
    param.file_path = self.ai_perform.str_param
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.PlayVideo, param)
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_ACT then
    self:HandlePerformACT()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_DIALOG then
    self:HandlePerformDialog()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CAM then
    self:HandlePerformCam()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CHANGE_BGM then
    self.isPausePerformPlayer = false
    self:Complete()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_TIPS then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, self.ai_perform.str_param, 3)
    local sound_id = tonumber(self.ai_perform.sound_id or 0)
    if sound_id and sound_id > 0 then
      _G.NRCAudioManager:PlaySound2DAuto(self.ai_perform.sound_id)
    end
    self:Complete()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_ATTENTION then
    self:Complete()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEVEL_SEQUENCE then
    if BattleUtils.IsFinalBattle() then
      if BattleManager.CacheSequencer then
        NRCModeManager:DoCmd(BattleUIModuleCmd.CloseTransformLoadingUI)
        BattleManager.CacheSequencer:Stop()
        BattleManager.CacheSequencer = nil
      end
      if _G.BattleManager.debugEnv.closeA1FBSeq then
        self:Complete()
        return
      end
    end
    local filePath = self.ai_perform.str_param
    if BattleUtils.IsFinalBattle() then
      filePath = BattleConst.FinalBattleP1ToP2Seq
      _G.RocoSkillEventCenter:DispatchEvent(_G.RocoSkillEventCenter.evenName.CancelFBBossShield)
      _G.BattleManager.battleRuntimeData:SetFBP1ToP2State(1)
    end
    if string.IsNilOrEmpty(filePath) then
      self:Complete()
      return
    end
    Log.Debug("BattlePiecesNpcAIPerform:Play ", filePath)
    self.isPausePerformPlayer = true
    self.performPlayer:Pause()
    BattleResourceManager:LoadResAsync(self, filePath, self.OnLoadSequence, self.OnLoadSequenceFailed)
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_VOID then
    local delayTime = 0
    if self.ai_perform.param > 0 then
      delayTime = self.ai_perform.param
    end
    self:SafeDelaySeconds("d_Complete", delayTime, self.Complete, self)
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEAVE_BATTLE then
    self:HandlePerformPlayerLeaveBattle()
  end
end

function BattlePiecesNpcAIPerform:HandlePerformACT()
  self.isPausePerformPlayer = false
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  local battleOnLooker = _G.BattleManager.battlePawnManager:GetBattleNpcById(self.ai_perform.onlooker_id)
  if player then
    player.BubbleComponent:Play(nil, self.ai_perform.param)
    self:Complete()
  elseif battleOnLooker then
    battleOnLooker:TryPerformAct(self.ai_perform.param)
    self:Complete()
  elseif self.ai_perform.audience then
    local allCrowdOnLooker = _G.BattleManager.battlePawnManager:GetAllBattleCrowdOnLookers()
    local emotionTypeList = {}
    local str_param = self.ai_perform.str_param
    local soundIdString = self.ai_perform.sound_id or ""
    local soundId = tonumber(soundIdString)
    if str_param and "" ~= str_param then
      local str_emotions = string.Split(str_param, ";")
      for i, str_emotion in ipairs(str_emotions) do
        local number_emotion = tonumber(str_emotion)
        if number_emotion then
          table.insert(emotionTypeList, number_emotion)
        end
      end
    end
    if 0 == #emotionTypeList and self.ai_perform.param then
      emotionTypeList = {
        self.ai_perform.param
      }
    end
    if #emotionTypeList > 0 then
      for i, onLooker in ipairs(allCrowdOnLooker) do
        local randomIndex = math.random(#emotionTypeList)
        local emotionType = emotionTypeList[randomIndex]
        if -1 ~= emotionType then
          onLooker:TryPerformAct(emotionType)
        end
      end
    end
    if soundId then
      local model = _G.BattleManager.vBattleField.battleFieldActor
      if UE.UObject.IsValid(model) then
        _G.NRCAudioManager:PlaySound3DWithActorAuto(soundId, model)
      end
    end
    self:Complete()
  else
    self:Complete()
  end
end

function BattlePiecesNpcAIPerform:HandlePerformDialog()
  self.isPausePerformPlayer = false
  if self.ai_perform.sound_id then
    _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.ai_perform.sound_id)
  end
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  local battleOnLooker = _G.BattleManager.battlePawnManager:GetBattleNpcById(self.ai_perform.onlooker_id)
  if player then
    player:UpdateDialogBox(self.ai_perform.str_param)
    player:ShowDialogBox()
    player:HideEmoji()
    player:HideSkillPrediction()
    local time = _G.DataConfigManager:GetGlobalConfigNumByKeyType("texbox_show_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000) / 1000
    if time <= 0 then
      self:Complete()
    else
      self:SafeDelaySeconds("d_Complete", time, self.Complete, self)
    end
  elseif battleOnLooker then
    battleOnLooker:TryPerformDialog(self.ai_perform.str_param)
    self:Complete()
  else
    self:Complete()
  end
end

function BattlePiecesNpcAIPerform:HandlePerformCam()
  if BattleUtils.IsFinalBattle() and _G.BattleManager.debugEnv.closeA1FBDialogue then
    self:Complete()
    return
  end
  if BattleUtils.IsB1FinalBattle() and _G.BattleManager.debugEnv.closeB1FBDialogue then
    self:Complete()
    return
  end
  if 0 == self.ai_perform.param then
    Log.Error("BattlePiecesNpcAIPerform:HandlePerformCam Dialogue Id Error")
    self:Complete()
    return
  end
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(self.ai_perform.param)
  if not DialogueConf then
    Log.Error("BattlePiecesNpcAIPerform:HandlePerformCam Dialogue Config Not Find")
    self:Complete()
    return
  end
  if self.performPlayer and self.performPlayer.turnPlayer and self.performPlayer.turnPlayer:GetArriveTimeOut() then
    self:Complete()
    return
  end
  if BattleUtils.IsWatchingBattle() and BattleManager:IsReceiveNextProcessSeq() then
    self:Complete()
    return
  end
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  local EnemyPet = _G.BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  if BattleUtils.IsTeam() and (not player or player.teamEnm == BattleEnum.Team.ENUM_ENEMY) and EnemyPet then
    EnemyPet:SetTurnTo(_G.BattleManager.battlePawnManager.TeamatePlayer, true)
  end
  if BattleUtils.IsFinalBattleP1() and self.ai_perform.pet_id and self.ai_perform.pet_id > 0 then
    local performPet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.ai_perform.pet_id)
    if performPet then
      _G.BattleManager.battleRuntimeData:SetFBP1DialogPet(performPet)
    end
  end
  self.isPausePerformPlayer = true
  self.performPlayer:Pause()
  _G.BattleEventCenter:Bind(self, BattleEvent.WAIT_PERFORM_END, BattleEvent.RECEIVE_SERVER_SEQ, BattleEvent.WILL_ARRIVE_PERFORM_TIMEOUT)
  if player and player.model then
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.StartDialogueInBattle, player, self.ai_perform.param, self, self.DelayComplete, EnemyPet and EnemyPet)
    if BattleUtils.IsFinalBattleP1() then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.HideFinalBattleWishPower)
    end
  else
    _G.NRCModuleManager:DoCmd(DialogueModuleCmd.StartDialogueInBattle, EnemyPet and EnemyPet, self.ai_perform.param, self, self.DelayComplete, EnemyPet and EnemyPet)
  end
end

function BattlePiecesNpcAIPerform:OnDialogTimeOut()
  if self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CAM then
    if _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
      _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.CloseDialogueInBattle)
    end
    self:Complete()
  end
end

function BattlePiecesNpcAIPerform:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.BATTLE_ROUND_START then
    if self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_ATTENTION then
      self:Complete()
      return true
    end
  elseif eventName == BattleEvent.WAIT_PERFORM_END or eventName == BattleEvent.WILL_ARRIVE_PERFORM_TIMEOUT then
    self:OnDialogTimeOut()
    return true
  elseif eventName == BattleEvent.RECEIVE_SERVER_SEQ then
    if BattleUtils.IsWatchingBattle() and BattleManager:IsReceiveNextProcessSeq() then
      self:OnDialogTimeOut()
    end
    return true
  elseif eventName == BattleEvent.TransformLoadingOpened then
    if self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEVEL_SEQUENCE then
      self:Complete()
    end
    _G.BattleEventCenter:UnBind(self)
    return true
  end
end

function BattlePiecesNpcAIPerform:OnLoadSequence(leveSequenceRes)
  if not _G.BattleManager.isInBattle then
    self:Complete()
    return
  end
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow then
    mainWindow:SetShowForRecordingAndChatBtn(false)
  end
  NRCModeManager:DoCmd(BattleUIModuleCmd.MainHideAll, false)
  NRCModeManager:DoCmd(BattleUIModuleCmd.CloseWishPowerPanel)
  local Settings = UE4.FMovieSceneSequencePlaybackSettings()
  local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
  if BattleUtils.IsFinalBattle() then
    Settings.bPauseAtEnd = true
  end
  self.levelSequenceActor = {}
  local levelSequenceActor, levelSequencePlayer = UE4.ULevelSequencePlayer.CreateLevelSequencePlayer(battleFieldActor, leveSequenceRes, Settings, self.levelSequenceActor)
  self.levelSequence = levelSequencePlayer
  if self.levelSequence then
    self:HideBattlePawn()
    if BattleUtils.IsFinalBattle() then
      self.levelSequence:SetTimeRange(0, 61.15)
      if levelSequenceActor then
        local player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
        if player and UE4.UObject.IsValid(player.model) then
          player:ShowPlayer()
          local sceneComp = player.model:GetComponentByClass(UE4.USceneComponent)
          if sceneComp then
            sceneComp:SetVisibility(true)
          end
          levelSequenceActor:SetBindingByTag("Player1", {
            player.model
          }, false)
          levelSequenceActor:SetBindingByTag("Player2", {
            player.model
          }, false)
        end
      end
      _G.BattleManager:ModifySceneSpotLight(false)
    end
    battleFieldActor:SetCacheLSCall(self, self.OnSequenceOver)
    self.levelSequence.OnFinished:Add(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
    local CurrentWorld = _G.UE4Helper.GetCurrentWorld()
    local EnableRebasing = UE4.UNRCStatics.IsEnabledWorldRebasing(CurrentWorld)
    if true == EnableRebasing then
      levelSequenceActor:ApplyWorldOffsetToSequence()
    end
    self.levelSequence:Play()
  else
    self:Complete()
  end
end

function BattlePiecesNpcAIPerform:OnSequenceOver(leveSequenceRes)
  _G.BattleManager.battleRuntimeData:SetFBP1ToP2State(2)
  _G.BattleEventCenter:Bind(self, BattleEvent.TransformLoadingOpened)
  NRCModeManager:DoCmd(BattleUIModuleCmd.OpenTransformLoadingUI)
end

function BattlePiecesNpcAIPerform:OnLoadSequenceFailed(leveSequenceRes)
  _G.BattleEventCenter:Bind(self, BattleEvent.TransformLoadingOpened)
  NRCModeManager:DoCmd(BattleUIModuleCmd.OpenTransformLoadingUI)
end

function BattlePiecesNpcAIPerform:HideBattlePawn()
  local pawnManager = _G.BattleManager.battlePawnManager
  for i, v in ipairs(pawnManager:GetAllTeam(BattleEnum.Team.ENUM_TEAM)) do
    if v.player and v.player.model then
      v.player:HidePlayer()
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(false)
      end
    end
    if #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          p:ChangeBuffVisibility(false)
          p:HidePet()
        end
      end
    end
  end
  for i, v in ipairs(pawnManager:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)) do
    if v.player and v.player.model then
      v.player:HidePlayer()
      local sceneComp = v.player.model:GetComponentByClass(UE4.USceneComponent)
      if sceneComp then
        sceneComp:SetVisibility(false)
      end
    end
    if #v.pets > 0 then
      for _, p in pairs(v.pets) do
        if p.model and p.card:IsExistAtField() then
          p:ChangeBuffVisibility(false)
          p:HidePet()
        end
      end
    end
  end
end

function BattlePiecesNpcAIPerform:OnPlay()
  if self.isPausePerformPlayer then
    self.performPlayer:Pause()
  end
end

function BattlePiecesNpcAIPerform:HideDialogBox()
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  if player then
    player:HideDialogBox()
    player:TryShowThinking()
    player:TryShowSkillPrediction()
  end
end

function BattlePiecesNpcAIPerform:HandlePerformPlayerLeaveBattle()
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  if player then
    player:PlaySkill(BattleConst.BattlePlayerLeaveBattleFadeOut, nil, self, self.OnPlayerLeaveBattleComplete, nil, nil, {})
  else
    Log.Error("BattlePiecesNpcAIPerform:HandlePerformPlayerLeaveBattle: \230\137\190\228\184\141\229\136\176\231\142\169\229\174\182\239\188\140uin =", self.ai_perform.uin)
    self:Complete()
  end
end

function BattlePiecesNpcAIPerform:OnPlayerLeaveBattleComplete()
  local player = _G.BattleManager.battlePawnManager:GetPlayerByGuid(self.ai_perform.uin)
  if player then
    player.team:QuitBattle()
    player:HidePlayer()
    for _, v in ipairs(player.components:Items()) do
      if v then
        v:Destroy()
      end
    end
    player.components:Clear()
  end
  self:Complete()
end

function BattlePiecesNpcAIPerform:DelayComplete()
  if self.isRunning then
    self:SafeDelayFrames("d_Complete", 1, self.Complete, self)
    if BattleUtils.IsFinalBattleP1() then
      NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowFinalBattleWishPower)
    end
  end
end

function BattlePiecesNpcAIPerform:Complete()
  _G.BattleEventCenter:UnBind(self)
  _G.BattleManager:ModifySceneSpotLight(true)
  if self.isRunning then
    Base.Complete(self)
  end
end

function BattlePiecesNpcAIPerform:OnComplete()
  self.isRunning = false
  if self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CG then
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_ACT then
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_DIALOG then
    self:HideDialogBox()
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CAM then
    local BattleMain = BattleUtils.GetMainWindow()
    if BattleMain then
      BattleMain:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if BattleUtils.IsFinalBattleP1() then
      _G.BattleManager.battleRuntimeData:SetFBP1DialogPet(nil)
    end
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_CHANGE_BGM then
    _G.NRCAudioManager:BatchSetState(self.ai_perform.str_param)
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_ATTENTION then
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_LEVEL_SEQUENCE then
    if self.levelSequence then
      BattleManager.CacheSequencer = self.levelSequence
      local battleFieldActor = _G.BattleManager.vBattleField.battleFieldActor
      if battleFieldActor and UE4.UObject.IsValid(battleFieldActor) then
        self.levelSequence.OnFinished:Remove(battleFieldActor, battleFieldActor.OnLevelSequenceEnd)
      end
      self.levelSequence:Stop()
      self.levelSequence = nil
    end
    Log.Debug("BattlePiecesNpcAIPerform:OnComplete ")
  elseif self.ai_perform.type == ProtoEnum.AIPerformType.AI_PERFORM_VOID then
  end
  self:SetPerformComplete()
end

function BattlePiecesNpcAIPerform:SetPerformComplete()
  _G.BattleEventCenter:Dispatch(BattlePerformEvent.AiPerformOver, self.ai_perform)
  self.node:DispatchPerformCallback(ProtoEnum.Buffbasetrigger_type.OnHit)
  self.node:PerformComplete()
  if self.isPausePerformPlayer then
    self.performPlayer:Resume()
  end
end

return BattlePiecesNpcAIPerform
