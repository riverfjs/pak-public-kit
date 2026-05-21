local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleExitHelper = require("NewRoco.Modules.Core.Battle.Players.BattleExitHelper")
local BattleCatchPetPlayer = BattlePlayerBase:Extend("BattleCatchPetPlayer")
BattleCatchPetPlayer.CatchState = {
  SUCCESS = 1,
  FAILED = 2,
  FAILED_LOW = 3
}

function BattleCatchPetPlayer:Ctor()
  BattlePlayerBase.Ctor(self)
  self.CallbackOwner = nil
  self.Callback = nil
  self.player = nil
  self.target = nil
  self.catch_pet = nil
  self.ballId = nil
  self.TickCamera = false
  self.BattleManager = _G.BattleManager
  self.PawnManager = self.BattleManager.battlePawnManager
  self.vBattleField = self.BattleManager.vBattleField
  self.waitingForClearPlayerCatchBall = false
end

function BattleCatchPetPlayer:PopupTeamCatch()
  if not self.player then
    return
  end
  if self.player.teamEnm == BattleEnum.Team.ENUM_TEAM and not self.IsMySelfCatch then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
      BattleEnum.InfoPopupType.TeamCatch,
      self.player,
      self.ballId
    }, self)
  end
end

function BattleCatchPetPlayer:Play(performNode)
  self:Reset()
  self:InitFromNode(performNode)
  Log.Debug("BattleCatchPetPlayer HandleCatchPet:", performNode)
  self.player = self.PawnManager:GetPlayerByGuid(self.catch_pet.player_id)
  self.target = self.PawnManager:GetPetByGuid(self.catch_pet.monster_id)
  self.ballId = self.catch_pet.ball_id
  self.ballResGroup = nil
  self.catchType = BattleCatchPetPlayer.CatchState.FAILED
  self.IsMySelfCatch = self.player == BattleManager.battlePawnManager:GetPlayerMyTeam()
  if BattleUtils.IsWatchingBattle() then
    self.IsMySelfCatch = false
  end
  if self.catch_pet and self.catch_pet.glass_info and self.catch_pet.glass_info.glass_type == ProtoEnum.GlassType.GT_HIDDEN then
    local hiddenGlass = DataConfigManager:GetHiddenGlassConf(self.catch_pet.glass_info.glass_value, true)
    if hiddenGlass then
      self.ballResGroup = hiddenGlass and hiddenGlass.ball_fx or ""
    end
  end
  self.IsExecuteExit = false
  self.NeedWaitLoadPet = false
  self.TriggerAppearance = false
  self.CallbackOver = false
  self:HideTeamBattleHp()
  _G.BattleManager:SaveCraneCameraTemporaryPosData()
  self:PopupTeamCatch()
  _G.BattleEventCenter:Bind(self, BattleEvent.CLICKED_Result_Close, BattleEvent.OnSkillResLoaded, BattleEvent.PET_SPAWNED)
  NRCModeManager:DoCmd(BattleUIModuleCmd.HideMainWindow, false, true)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
  if self.player and self.target then
    self.IsPartnerPerform = self.player.teamEnm == BattleEnum.Team.ENUM_TEAM and self.player ~= BattleManager.battlePawnManager:GetPlayerMyTeam()
    self.target:SwimSetLockIdle(false)
    self.target:SetIKEnable(false)
    self:UpdateBattleConfPos(self.target, self.player)
    self.waitingForClearPlayerCatchBall = true
    if BattleUtils.IsCrowdBattle() and self.target.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      BattleUtils.CheerPetsPerform(BattleEnum.CheerPetPerformState.BeCatch)
    end
    if self.catch_pet.success then
      if BattleUtils.IsTeam() then
        self.target.battlePetComponents:HideCatchConsume(false)
        self:PlaySuccess(self.target, self.ballId, self, self.TeamCatchOver)
        self:PreLoadAppearanceRes()
      else
        self:PlaySuccess(self.target, self.ballId, self, self.OnCatchSuccess)
      end
    elseif self.performNode.IsFastPlay then
      self:OnSkillComplete()
    else
      self:PlayFailed(self.target, self.ballId, self.catch_pet.catch_prob, self, self.OnCatchFailed)
    end
  else
    self:OnSkillComplete()
  end
  self:CheckShouldQuicklyCatch()
end

function BattleCatchPetPlayer:CheckShouldQuicklyCatch()
  if not BattleUtils.IsBeastTeam() or not self.player then
    return
  end
  if self.catch_pet and not self.catch_pet.success and self.performNode and self.performNode.performInfo and self.performNode.performInfo.sync_data then
    local ballNum = self.performNode.performInfo.sync_data.role_sync_info[1].item_num
    if ballNum > 0 then
      self.player:SetQuicklyCatchBall(self.catch_pet.ball_id)
    end
  end
end

function BattleCatchPetPlayer:HideTeamBattleHp()
  if BattleUtils.IsTeam() then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ActivatePetGroupWarfare)
  end
end

function BattleCatchPetPlayer:UpdateBattleConfPos(pet, player)
  local posInField = pet.card.posInField or 1
  local petPos = _G.BattleManager.battlePawnManager.VBattleField:GetTeamPositionMap(pet.teamEnm)
  if not petPos then
    return
  end
  local petPosMap = petPos:Get(posInField)
  if not petPosMap or not UE4.UObject.IsValid(petPosMap) then
    return
  end
  if not (player and player.model) or not UE4.UObject.IsValid(player.model) then
    return
  end
  local aPos = petPosMap:Abs_K2_GetActorLocation()
  local bPos = player.model:Abs_K2_GetActorLocation()
  if not aPos then
    return
  end
  local dir = bPos - aPos
  if dir then
    dir.Z = 0
    local Rot = dir:ToRotator():Clamp()
    petPosMap:K2_SetActorRotation(Rot, true)
  else
    Log.Error("dir is nil")
  end
end

function BattleCatchPetPlayer:Reset()
  self.player = nil
  self.target = nil
  self.catch_pet = nil
  self.battlePetInfo = nil
  self.performNode = nil
  self.ballId = nil
end

function BattleCatchPetPlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.catch_pet = performInfo.catch_pet_info
end

function BattleCatchPetPlayer:OnCatchPostStart()
  self:TryClearPlayerCatchBall()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdSwitchChatBubbles, self.player.model, false)
  if self.target and self.catch_pet and self.catch_pet.success then
    self.target.card.petState:SetCatchStun(false)
  end
  self.target.buffComponent:OnPetBeCatch(self.catch_pet.success)
end

function BattleCatchPetPlayer:TryClearPlayerCatchBall()
  if self.waitingForClearPlayerCatchBall then
    self.player:ClearCatchBall()
    self.waitingForClearPlayerCatchBall = false
  end
end

function BattleCatchPetPlayer:AppearancePerformOver()
  if self.AppearancePet then
    self.AppearancePet.card.IgnoreAnimCheck = false
  end
  self:OnCatchSuccess()
end

function BattleCatchPetPlayer:AppearancePerformWillOver()
  if BattleUtils.IsBeastTeam() then
    self.DelayIdAppearancePerform = _G.DelayManager:DelaySeconds(1, self.OnCatchSuccess, self)
  else
    self:OnCatchSuccess()
  end
end

function BattleCatchPetPlayer:OnCatchSuccess()
  _G.BattleManager.battleRuntimeData.battleExitParam.IsCatchSuccess = true
  _G.BattleManager.battleRuntimeData.IsCatchSuccessInBloodTeam = true
  self:OnSkillComplete()
end

function BattleCatchPetPlayer:DelayCloseTeamCatch()
  if self.performNode and not self.performNode.IsPerformOver then
    self:OnSkillComplete()
  end
end

function BattleCatchPetPlayer:OnCatchFailed()
  self.target.buffComponent:RestartBattleState()
end

function BattleCatchPetPlayer:IsQuickCatch()
  if not BattleUtils.IsTeam() and self.catch_pet and self.catch_pet.is_quick_catch then
    return true
  else
    return false
  end
end

function BattleCatchPetPlayer:GetSkillPath()
  return _G.BattleConst.Define.CATCH_SKILL
end

function BattleCatchPetPlayer:OnSkillComplete()
  _G.BattleEventCenter:UnBind(self)
  Log.Debug("BattleCatchPetPlayer Play OnSkillComplete:", self.performNode:GetNodeIdx())
  if self.target then
    self.target:SetIKEnable(true)
  end
  if self.DelayIdAppearancePerform then
    _G.DelayManager:CancelDelayById(self.DelayIdAppearancePerform)
    self.DelayIdAppearancePerform = nil
  end
  self.AppearancePet = nil
  self:TryClearPlayerCatchBall()
  self.performNode:PerformComplete()
end

function BattleCatchPetPlayer:PreLoadAppearanceRes()
  if not self.player then
    return
  end
  local LastHitBaseId = self.player.FashionData.LastHitPetBaseId
  local LastHitGID = self.player.FashionData.LastHitGID
  local LastHitPetCard = self.BattleManager.battlePawnManager:GetCardByCommonGuid(self.player.teamEnm, LastHitGID)
  local skillPath
  local preBaseId = -1
  if LastHitPetCard then
    preBaseId = LastHitPetCard.petBaseConf.id
    self.TriggerAppearance = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
    if not self.TriggerAppearance then
      if preBaseId ~= LastHitBaseId then
        LastHitPetCard:RefreshByBaseConf(LastHitBaseId)
      end
      self.TriggerAppearance = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
    else
      LastHitBaseId = preBaseId
    end
    skillPath = LastHitPetCard.AppearancePath:GetPVPOver()
  end
  if self.TriggerAppearance then
    self.AppearancePet = _G.BattleManager.battlePawnManager:GetFirstPet(self.player.teamEnm)
    local AppearanceCard
    if not self.AppearancePet then
      AppearanceCard = LastHitPetCard or self.player.deck.cards[1]
      if AppearanceCard then
        AppearanceCard.pos = 1
        AppearanceCard.posInField = 1
        self.NeedWaitLoadPet = true
      end
    elseif self.AppearancePet.card.petBaseConf.id ~= LastHitBaseId then
      self.NeedWaitLoadPet = true
      AppearanceCard = self.AppearancePet.card
      self.AppearancePet:OnRecall()
    elseif LastHitGID == self.AppearancePet.card.petInfo.battle_common_pet_info.gid and LastHitBaseId ~= preBaseId then
      self.NeedWaitLoadPet = true
      AppearanceCard = self.AppearancePet.card
      self.AppearancePet:OnRecall()
    end
    if self.NeedWaitLoadPet then
      AppearanceCard:RefreshByBaseConf(LastHitBaseId)
      AppearanceCard:SetInBattleField(true)
      if self.AppearancePet then
        self.AppearancePet:HidePet()
      end
      self.AppearancePet = BattleManager.battlePawnManager:PawnPet(self.player.teamEnm, self.player.team, AppearanceCard, self.player, nil, true)
    end
    self.appearanceSkillResList = {skillPath}
    self.appearanceSkillResCount = 0
    _G.BattleSkillManager:PreLoadRes(self.appearanceSkillResList, true)
  end
end

function BattleCatchPetPlayer:OnSkillResLoaded(eventName, resPath)
  if not self.appearanceSkillResList then
    return
  end
  for i = 1, #self.appearanceSkillResList do
    if resPath == self.appearanceSkillResList[i] then
      self.appearanceSkillResCount = self.appearanceSkillResCount + 1
      if self.appearanceSkillResCount == #self.appearanceSkillResList then
        self:TryPlayAppearancePerform()
        return
      end
    end
  end
end

function BattleCatchPetPlayer:OnPawnNewPetFinish(pet)
  if self.AppearancePet == pet then
    self.AppearancePet:SetScale(1)
    self.AppearancePet:HidePet()
    self.AppearancePet:SetClickable(false)
    self.AppearancePet:PinOnTheGround()
    self.NeedWaitLoadPet = false
    self:TryPlayAppearancePerform()
  end
end

function BattleCatchPetPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.OnSkillResLoaded then
    self:OnSkillResLoaded(eventName, ...)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
  end
end

function BattleCatchPetPlayer:SetBlackBoardForCatch(ShakeTimes, blackboard, BallConfig)
  if not blackboard or not self.catch_pet then
    return
  end
  local actionBlackboard = BallConfig.catch_action or "NoColorFul"
  local isSuccess = ShakeTimes < 0
  local SkipEnd = isSuccess and (not self.IsMySelfCatch or BattleUtils.IsTeam()) and "BuZhuo_End" or ""
  local Baoji_Battle = self.catch_pet.is_tech_satisfied and "Battle_BuZhuo_BaoJi" or ""
  local HuiXinCatch = self:IsQuickCatch() and "Battle_BuZhuo_HX" or ""
  local Battle_BuZhuo = self:IsQuickCatch() and "" or "Battle_BuZhuo"
  local QuicklyCatch = self.player.QuicklyCatchBallId > 0 and "QuicklyCatch" or ""
  ShakeTimes = "Battle_BuZhuo_HX" == HuiXinCatch and not isSuccess and 0 or ShakeTimes
  if BattleUtils.IsTeam() and isSuccess then
    blackboard:SetValueAsString("Battle_BuZhuo_XM", "Battle_BuZhuo_XM")
  elseif "QuicklyCatch" == QuicklyCatch then
    blackboard:SetValueAsString(QuicklyCatch, QuicklyCatch)
    blackboard:SetValueAsString(HuiXinCatch, HuiXinCatch)
    blackboard:SetValueAsString(Battle_BuZhuo, Battle_BuZhuo)
  else
    blackboard:SetValueAsString(actionBlackboard, actionBlackboard)
    blackboard:SetValueAsString(HuiXinCatch, HuiXinCatch)
    blackboard:SetValueAsString(Battle_BuZhuo, Battle_BuZhuo)
  end
  blackboard:SetValueAsString(SkipEnd, SkipEnd)
  blackboard:SetValueAsString(Baoji_Battle, Baoji_Battle)
  blackboard:SetValueAsInt("Seg0", not isSuccess and 0 == ShakeTimes and 1 or 0)
  blackboard:SetValueAsInt("Seg1", not isSuccess and ShakeTimes <= 1 and 1 or 0)
  blackboard:SetValueAsInt("Fail", isSuccess and 0 or 1)
  blackboard:SetValueAsInt("Success", isSuccess and 1 or 0)
  blackboard:SetValueAsString("IsSuccess", isSuccess and "True" or "False")
end

function BattleCatchPetPlayer:IsBattleOverAfterCatch()
  if not self.performNode then
    return false
  end
  local turnPlayer = self.performNode.performPlayer.turnPlayer
  local result = turnPlayer.SettleInfo and 0 ~= turnPlayer.SettleInfo.result
  result = result and 0 == self.performNode.performPlayer:GetNonePerformCluster()
  return result
end

function BattleCatchPetPlayer:GetBallPath(ballId)
  local BallConfig = _G.DataConfigManager:GetBallConf(ballId or 0)
  if BallConfig then
    local ModelConfig = _G.DataConfigManager:GetModelConf(BallConfig.fx_source)
    if ModelConfig then
      return ModelConfig.path
    end
  end
end

function BattleCatchPetPlayer:PlaySuccess(Target, BallID, CallbackOwner, Callback)
  self.PawnManager:TogglePetBuffsVisibility(false)
  self.target = Target
  self.CallbackOwner = CallbackOwner
  self.Callback = Callback
  self.target.card:SetBeCatch(true)
  self.catchType = BattleCatchPetPlayer.CatchState.SUCCESS
  if self.performNode.IsFastPlay then
    self:SuccessOver()
    return
  end
  local characters = self.PawnManager:GetAllPawnActorForSkill()
  local Klass = BattleSkillManager:GetLoadedClass(self:GetSkillPath())
  if not Klass or not self.player.model then
    self:SuccessOver()
    return
  end
  if not UE4.UObject.IsValid(self.player.model) or not self.player.model.RocoSkill then
    self:SuccessOver()
    return
  end
  local activeSkill = self.player.model.RocoSkill:GetActiveSkill()
  if activeSkill then
    self.player.model.RocoSkill:CancelSkill(activeSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  local Skill = self.player.model.RocoSkill:AddSkillObjFromClassAndReturn(Klass)
  if not Skill then
    self:SuccessOver()
    return
  end
  local player = BattleUtils.GetPlayer()
  if not player then
    self:SuccessOver()
    return
  end
  Skill:SetDynamicData({
    BallPath = self:GetBallPath(BallID)
  })
  if self.ballResGroup then
    Skill:SetDynamicData({
      BallResGroup = self.ballResGroup
    })
  end
  local blackboard = Skill:GetBlackboard()
  if blackboard then
    self:SetBlackBoardForCatch(-1, blackboard, _G.DataConfigManager:GetBallConf(BallID))
    local result = self:IsBattleOverAfterCatch()
    if result and not BattleUtils.IsTeam() and not BattleUtils.IsWatchingBattle() then
      self.IsStayBattleField = false
      blackboard:SetValueAsNoDestroyObject("CurrentPlayer", player.viewObj)
      _G.BattleManager:RevertWorldPlayer()
      Skill:RegisterEventCallback("RestoreCamera", self, self.RestoreBigWorldCam)
      if self.IsMySelfCatch then
        Skill:RegisterEventCallback("Exit", self, self.ExitSuccess)
      else
        Skill:RegisterEventCallback("Exit", self, self.FriendExitSuccess)
      end
    else
      self.IsStayBattleField = true
      blackboard:SetValueAsNoDestroyObject("CurrentPlayer", self.player.model)
      Skill:RegisterEventCallback("Exit", self, self.ExitInMultiPet)
      if not BattleUtils.IsTeam() then
        Skill:RegisterEventCallback("RestoreCamera", self, self.RestoreBattleCam)
      end
    end
  end
  local targets = {}
  local pets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, pet in ipairs(pets) do
    table.insert(targets, pet.model)
  end
  table.insert(targets, 1, self.target.model)
  Skill:SetCaster(self.player.model)
  Skill:SetTargets(targets)
  Skill:SetCharacters(characters)
  Skill:SetPassive(false)
  Skill.BattleGenderType = self.player.roleInfo.base.sex or 0
  Skill:RegisterEventCallback("ActionStart", self, self.OnCatchPostStart)
  Skill:RegisterEventCallback("End", self, self.Exit)
  if self.catch_pet.glass_info and self.catch_pet.glass_info.glass_type == ProtoEnum.GlassType.GT_COMMON then
    Skill:RegisterEventCallback("SpawnBuZhuoFx", self, self.SpawnBallEffectBP)
  end
  Skill:SetSkillUseCase(UE4.ESkillUseCase.Battle)
  if BattleUtils.IsDeepWater() then
    Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Water
  else
    Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Ground
  end
  BattleUtils.SetSkillNoWaitTilLoading(Skill)
  BattleBudget:GC()
  self.player.model.RocoSkill:LoadAndPlaySkill(Skill)
end

local colorIdBitNum = 20

function BattleCatchPetPlayer:SpawnBallEffectBP(Event, Skill)
  local EffectBp = self:GetBlackboardValue(Skill, "Buzhuo_Fx_Zhuti")
  if EffectBp and self.target and self.catch_pet.glass_info and self.catch_pet.glass_info.glass_value then
    local particle = self.catch_pet.glass_info.glass_value >> colorIdBitNum
    local colorId = self.catch_pet.glass_info.glass_value - (particle << colorIdBitNum)
    local colorConf = _G.DataConfigManager:GetColorRandomConf(colorId, true)
    if colorConf then
      EffectBp.Color1.R = colorConf.mat_color_1[1]
      EffectBp.Color1.G = colorConf.mat_color_1[2]
      EffectBp.Color1.B = colorConf.mat_color_1[3]
      EffectBp.Color1.A = colorConf.mat_color_1[4] or 1
      EffectBp.Color2.R = colorConf.mat_color_2[1]
      EffectBp.Color2.G = colorConf.mat_color_2[2]
      EffectBp.Color2.B = colorConf.mat_color_2[3]
      EffectBp.Color2.A = colorConf.mat_color_2[4] or 1
    end
    local particleConf = _G.DataConfigManager:GetParticleRandomConf(particle, true)
    if particleConf then
      EffectBp.Icon = particleConf.id
    end
    EffectBp:ReceiveBeginPlay()
  end
end

function BattleCatchPetPlayer:TeamCatchOver()
  if self.TriggerAppearance then
    self:TryPlayAppearancePerform()
  else
    self:PlayTeamCatchSuccess()
  end
end

function BattleCatchPetPlayer:TryPlayAppearancePerform()
  if not BattleManager:IsInBattle(true) then
    return
  end
  if not self.CallbackOver then
    return
  end
  if self.NeedWaitLoadPet then
    return
  end
  if self.appearanceSkillResCount < #self.appearanceSkillResList then
    return
  end
  local skillPath = self.appearanceSkillResList[1]
  local class = BattleSkillManager:GetLoadedClass(skillPath)
  if not class then
    Log.WarningFormat("Can't load skill class %s", skillPath)
    self:OnCatchSuccess()
    return
  end
  local player = self.player
  if not player.model then
    Log.Warning("There is no model in my player !!!")
    self:OnCatchSuccess()
    return
  end
  local skillComponent = player.model.RocoSkill
  local skill = skillComponent:AddSkillObjFromClassAndReturn(class)
  if not skill then
    Log.WarningFormat("Can't find or load skill object %s %s", class, skillPath)
    self:OnCatchSuccess()
    return
  end
  local Characters = BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  if Characters[BattleConst.CharacterIndex.Player1] and Characters[BattleConst.CharacterIndex.Player1] ~= self.player.model then
    for i = BattleConst.CharacterIndex.Player1, BattleConst.CharacterIndex.Player_Pet4 do
      local cache = Characters[i]
      Characters[i] = Characters[i + BattleConst.CharacterIndex.Player_Pet4 + 1]
      Characters[i + BattleConst.CharacterIndex.Player_Pet4 + 1] = cache
    end
  end
  local targets = {}
  if self.AppearancePet then
    self.AppearancePet:ShowPet(false)
    self.AppearancePet:SetIKEnable(false)
    Characters[BattleConst.CharacterIndex.Player_Pet1] = self.AppearancePet.model
    if self.AppearancePet.model and self.AppearancePet.model.mesh then
      self.AppearancePet.model.mesh.BoundsScale = 20
      self.AppearancePet.model.mesh.bNRCUseFixedSkelBounds = false
    end
    self.AppearancePet.card.IgnoreAnimCheck = true
    targets = {
      self.AppearancePet.model
    }
  end
  if self.player.model and self.player.model.mesh then
    self.player.model.mesh.BoundsScale = 20
    self.player.model.mesh.bNRCUseFixedSkelBounds = false
  end
  skill:SetCaster(player.model)
  skill:SetTargets(targets)
  skill:SetCharacters(Characters)
  skill:RegisterEventCallback("ActionStart", self, self.OnCatchPostStart)
  skill:RegisterEventCallback("End", self, self.AppearancePerformOver)
  skill:RegisterEventCallback("PreEnd", self, self.AppearancePerformWillOver)
  skill.BattleGenderType = self.player.roleInfo.base.sex
  skillComponent:StopCurrentSkill()
  skillComponent:LoadAndPlaySkill(skill)
end

function BattleCatchPetPlayer:PlayTeamCatchSuccess()
  if not BattleManager:IsInBattle(true) then
    return
  end
  local skillPath = BattleConst.TeamBloodCatchSuccess
  local class = BattleSkillManager:GetLoadedClass(skillPath)
  if not class then
    Log.WarningFormat("Can't load skill class %s", skillPath)
    self:OnCatchSuccess()
    return
  end
  local player = self.player
  if not player.model then
    Log.Warning("There is no model in my player !!!")
    self:OnCatchSuccess()
    return
  end
  local skillComponent = player.model.RocoSkill
  local skill = skillComponent:AddSkillObjFromClassAndReturn(class)
  if not skill then
    Log.WarningFormat("Can't find or load skill object %s %s", class, skillPath)
    self:OnCatchSuccess()
    return
  end
  local myPets = BattleManager.battlePawnManager:GetCanSelectPetsByPlayer(BattleManager.battlePawnManager.TeamatePlayer)
  if myPets then
    for _, pet in pairs(myPets) do
      pet:HidePet()
    end
  end
  skill:SetDynamicData({
    BallPath = self:GetBallPath(self.ballId or 0)
  })
  if self.ballResGroup then
    skill:SetDynamicData({
      BallResGroup = self.ballResGroup
    })
  end
  skill:SetCaster(player.model)
  skill:SetTargets({
    player.model
  })
  local characters = BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local blackboard = skill:GetBlackboard()
  if blackboard then
    if BattleUtils.IsBloodTeam() then
      blackboard:SetValueAsString("XueMai", "XueMai")
    else
      blackboard:SetValueAsString("Default", "Default")
    end
  end
  skill:SetCharacters(characters)
  skill:RegisterEventCallback("ActionStart", self, self.OnCatchPostStart)
  skill:RegisterEventCallback("End", self, self.OnCatchSuccess)
  skill:RegisterEventCallback("PreEnd", self, self.OnCatchSuccess)
  skillComponent:StopCurrentSkill()
  skillComponent:LoadAndPlaySkill(skill)
end

function BattleCatchPetPlayer:SuccessOver()
  local turnPlayer = self.performNode.performPlayer.turnPlayer
  if turnPlayer.SettleInfo and 0 ~= turnPlayer.SettleInfo.result then
    _G.BattleManager:RevertWorldPlayer()
    self:RestoreBigWorldCam()
    self:ExitSuccess()
  else
    self:ExitInMultiPet()
  end
  self:Exit()
end

function BattleCatchPetPlayer:RestoreCamera(Event, Skill)
  BattleExitHelper.ResetPlayerCamera()
end

function BattleCatchPetPlayer:RestoreBigWorldCam(Event, Skill)
  BattleExitHelper.ResetPlayerCamera()
end

function BattleCatchPetPlayer:HideEffect(Event, Skill)
  if self.target and self.target.model then
    self.target.model.RocoSkill:StopCurrentSkill()
    local passiveSkills = self.target.model.RocoSkill:GetCurrentPassiveSkillObjs()
    if passiveSkills then
      for i = 1, passiveSkills:Length() do
        local skill = passiveSkills:Get(i)
        self.target.model.RocoSkill:CancelSkill(skill, UE4.ESkillActionResult.SkillActionResultInterrupted)
      end
    end
  end
end

function BattleCatchPetPlayer:RestoreBattleCam(Event, Skill)
  if _G.BattleManager.vBattleField.battleCraneCamera then
    _G.BattleManager.vBattleField.battleCraneCamera:ChangeToSkill(0)
  else
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end
end

function BattleCatchPetPlayer:ExitSuccess(Event, Skill)
  self.PawnManager:TogglePetBuffsVisibility(false)
  self.PawnManager:HideAll(false)
  self.vBattleField:HideAllWaterPlatforms()
  self:DestroyCameras()
  if Skill then
    self.CameraAnim = self:GetBlackboardValue(Skill, "camActor_0002_SA", true)
    self.Camera = self:GetBlackboardValue(Skill, "camActor_0002", true)
    if self.CameraAnim then
      self.CameraAnim:DetachRootComponentFromParent(true)
    end
    self.CameraAnimOther = self:GetBlackboardValue(Skill, "camActor_0001_SA", true)
    self.CameraOther = self:GetBlackboardValue(Skill, "camActor_0001", true)
    if self.CameraAnimOther then
      self.CameraAnimOther:DetachRootComponentFromParent(true)
    end
  end
  _G.BattleManager:StopBattleBGM()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleRedPanel)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.HideMain, false)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.HideBattlePopupPanel)
end

function BattleCatchPetPlayer:FriendExitSuccess(Event, Skill)
  self:ExitSuccess(Event, Skill)
  self:Exit(Event, Skill)
end

function BattleCatchPetPlayer:ExitSuccessRestoreCamera()
  local player = BattleUtils.GetPlayer()
  if not player then
    return
  end
  local controller = player:GetUEController()
  if not controller then
    return
  end
  controller:ResetCamera()
  UE4.UNRCStatics.ForceTickCamera(0.0)
end

function BattleCatchPetPlayer:ExitInMultiPet(Event, Skill)
  if self.target then
    self.target.dead = true
    self.target:HidePet()
    if not BattleUtils.IsTeam() then
      self.target:Destroy()
    end
  end
  if not BattleUtils.IsTeam() then
    BattleManager.battlePawnManager:TogglePetBuffsVisibility(true)
    _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ShowHPBars)
  end
end

function BattleCatchPetPlayer:PlayFailed(Target, BallID, SuccessRate, CallbackOwner, Callback)
  self.target = Target
  self.CallbackOwner = CallbackOwner
  self.Callback = Callback
  self.catchType = BattleCatchPetPlayer.CatchState.FAILED
  self.target.card:SetBeCatch(false)
  self.target:ChangeBuffVisibility(false)
  _G.BattleManager.vBattleField.battleCraneCamera:JumpToOriginForce()
  SuccessRate = SuccessRate / 100.0
  if BattleConst.OverrideCatchRate >= 0 then
    SuccessRate = BattleConst.OverrideCatchRate
  end
  local ShakeTimes = BattleUtils.GetShakeTimes(SuccessRate, false)
  local Klass = BattleSkillManager:GetLoadedClass(self:GetSkillPath())
  if not Klass or not self.player.model then
    self:Finish()
    return nil
  end
  local activeSkill = self.player.model.RocoSkill:GetActiveSkill()
  if activeSkill then
    self.player.model.RocoSkill:CancelSkill(activeSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  local Skill = self.player.model.RocoSkill:AddSkillObjFromClassAndReturn(Klass)
  if not Skill then
    self:Finish()
    return nil
  end
  local characters = self.PawnManager:GetAllPawnActorForSkill()
  characters[0] = self.player.model
  Skill:SetDynamicData({
    BallPath = self:GetBallPath(BallID)
  })
  if self.ballResGroup then
    Skill:SetDynamicData({
      BallResGroup = self.ballResGroup
    })
  end
  Skill:SetCaster(self.player.model)
  local targets = {}
  local pets = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, pet in ipairs(pets) do
    table.insert(targets, pet.model)
  end
  table.insert(targets, 1, self.target.model)
  Skill:SetTargets(targets)
  Skill:SetCharacters(characters)
  Skill:SetPassive(false)
  local blackboard = Skill:GetBlackboard()
  if blackboard then
    self:SetBlackBoardForCatch(ShakeTimes, blackboard, _G.DataConfigManager:GetBallConf(BallID))
    blackboard:SetValueAsNoDestroyObject("CurrentPlayer", self.player.model)
  end
  Skill:SetSkillUseCase(UE4.ESkillUseCase.Battle)
  Skill:RegisterEventCallback("ActionStart", self, self.OnCatchPostStart)
  Skill:RegisterEventCallback("UnBind", self, self.OnUnbind)
  Skill:RegisterEventCallback("End", self, self.FailSkillFinish)
  Skill:RegisterEventCallback("End", self, self.SaveCamera)
  if BattleUtils.IsDeepWater() then
    Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Water
  else
    Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Ground
  end
  Skill.BattleGenderType = self.player.roleInfo.base.sex or 0
  BattleUtils.SetSkillNoWaitTilLoading(Skill)
  self.player.model.RocoSkill:LoadAndPlaySkill(Skill)
  return Skill
end

function BattleCatchPetPlayer:HidePopup()
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, nil, self)
end

function BattleCatchPetPlayer:PetStatusPopup(Event, Skill)
  if self.target.card.petState:GetDrill() then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
      BattleEnum.InfoPopupType.IsCatchDrill,
      self.target
    }, self)
    if self.DelayIdDrill then
      _G.DelayManager:CancelDelayById(self.DelayIdDrill)
      self.DelayIdDrill = nil
    end
    self.DelayIdDrill = _G.DelayManager:DelaySeconds(1, self.HidePopup, self)
  elseif self.target.card.petState:GetStatic() then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
      BattleEnum.InfoPopupType.IsCatchStatic,
      self.target
    }, self)
    if self.DelayIdStatic then
      _G.DelayManager:CancelDelayById(self.DelayIdStatic)
      self.DelayIdStatic = nil
    end
    self.DelayIdStatic = _G.DelayManager:DelaySeconds(1, self.HidePopup, self)
  elseif self.target.card.petState:GetMimic() then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
      BattleEnum.InfoPopupType.IsCatchMimic,
      self.target
    }, self)
    if self.DelayIdMimic then
      _G.DelayManager:CancelDelayById(self.DelayIdMimic)
      self.DelayIdMimic = nil
    end
    self.DelayIdMimic = _G.DelayManager:DelaySeconds(1, self.HidePopup, self)
  end
end

function BattleCatchPetPlayer:SaveCamera(Event, Skill)
  self:DestroyCameras()
  self.CameraAnim = self:GetBlackboardValue(Skill, "camActor_0006_SA", true)
  self.Camera = self:GetBlackboardValue(Skill, "camActor_0006", true)
  if self.target then
    self.target:ChangeBuffVisibility(true)
  end
end

function BattleCatchPetPlayer:OnTick(DeltaTime)
  if self.TickCamera then
    self.time = self.time + DeltaTime * 1.5
    local alpha = self.time / self.timeRemain
    if alpha >= 1 then
      alpha = 1
      self.TickCamera = false
      _G.BattleManager.vBattleField.battleCameraManager.KontrolEnabled = true
    end
    local CamVec = _G.BattleManager.vBattleField:GetPCGCamTransform()
    local FOVDiff = _G.BattleManager.vBattleField.battleCameraManager.FOV - self.FOV
    self.KamVec = self.KameraBone.SkeletalMeshComponent:GetSocketTransform("cam_01")
  end
end

function BattleCatchPetPlayer:RunCallBack()
  local CallbackOwner = self.CallbackOwner
  local Callback = self.Callback
  self.CallbackOwner = nil
  self.Callback = nil
  self.CallbackOver = true
  if Callback then
    Callback(CallbackOwner)
  end
end

function BattleCatchPetPlayer:Exit(Event, Skill)
  if self.IsExecuteExit then
    return
  end
  self.IsExecuteExit = true
  if self.target and self.target.card:IsBeCatch() then
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PET_CATCH_SUCCESS, self.target)
  end
  if Skill then
    self:GetBlackboardValue(Skill, "CurrentPlayer", true)
  end
  if self.IsStayBattleField then
    if BattleUtils.IsBloodTeam() then
      self.CameraAnim = self:GetBlackboardValue(Skill, "camActor_0002_SA", true)
      self.Camera = self:GetBlackboardValue(Skill, "camActor_0002", true)
      if self.CameraAnim then
        self.CameraAnim:DetachRootComponentFromParent(true)
      end
      self:HideEffect()
    end
    if self.target and self.target.card:IsBeCatch() then
      self:RunCallBack()
    else
      _G.BattleManager.vBattleField.battleCraneCamera:JumpToOriginForce(self, self.RunCallBack)
    end
  else
    self:RunCallBack()
  end
end

function BattleCatchPetPlayer:OnUnbind(Event, Skill)
  if BattleUtils.IsTeam() then
    if _G.BattleManager.vBattleField.battleCraneCamera then
      _G.BattleManager.vBattleField.battleCraneCamera:ChangeToPlayerCatch(0)
    else
      _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerCatch(0)
    end
  else
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToPlayerSkill(0)
  end
  if self.target then
    self.target:ChangeBuffVisibility(true)
  end
end

function BattleCatchPetPlayer:FailSkillFinish(Event, Skill)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ShowHPBars)
  self:GetBlackboardValue(Skill, "CurrentPlayer", true)
  self:RunCallBack()
  self:Finish()
end

function BattleCatchPetPlayer:Finish()
  self:OnSkillComplete()
end

function BattleCatchPetPlayer:GetBlackboardValue(Skill, blackboardKey, remove)
  if not Skill then
    return
  end
  local blackboard = Skill:GetBlackboard()
  if not blackboard then
    return
  end
  local obj = blackboard:GetValueAsObject(blackboardKey)
  if remove then
    blackboard:RemoveObjectValue(blackboardKey)
  end
  return obj
end

function BattleCatchPetPlayer:DestroyCameras()
  if self.Camera then
    self.Camera:K2_DestroyActor()
    self.Camera = nil
  end
  if self.CameraAnim then
    self.CameraAnim:K2_DestroyActor()
    self.CameraAnim = nil
  end
  if self.CameraAnimOther then
    self.CameraAnimOther:K2_DestroyActor()
    self.CameraAnim = nil
  end
  if self.CameraOther then
    self.CameraOther:K2_DestroyActor()
    self.CameraOther = nil
  end
  if self.Kamera then
    self.Kamera:K2_DestroyActor()
    self.Kamera = nil
  end
  if self.KameraBone then
    self.KameraBone:K2_DestroyActor()
    self.KameraBone = nil
  end
end

function BattleCatchPetPlayer:Clear()
  self:DestroyCameras()
end

return BattleCatchPetPlayer
