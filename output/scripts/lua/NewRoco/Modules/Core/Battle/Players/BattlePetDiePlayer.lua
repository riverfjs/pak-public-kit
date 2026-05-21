local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local EventDispatcher = require("Common.EventDispatcher")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local CastSkillObject = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.CastSkillObject")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattlePetDiePlayer = BattlePlayerBase:Extend("BattlePetDiePlayer")

function BattlePetDiePlayer:Ctor(Owner)
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.BattleManager = _G.BattleManager
  self.PawnManager = _G.BattleManager.battlePawnManager
end

function BattlePetDiePlayer:Reset()
  self.team = nil
  self.player = nil
  self.deadInfo = nil
  self.performNode = nil
  self.deadPosition = nil
  self.target = nil
  self.targets = {}
  self.isRoleHpDefeated = false
end

function BattlePetDiePlayer:GetDeadSkillClass(player)
  local deathExist = BattleUtils.IsDeathExist(self.target.card)
  if deathExist then
    local value = self.target.card:GetMonsterConfigIsNightmareValue()
    if value and 2 == value and 1 == deathExist then
      return BattleSkillManager:GetLoadedClass(BattleConst.NightmarePetDeadWithStun)
    end
    if BattleUtils.IsSkipRecycleBall() then
      return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStunNoBall)
    else
      return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStun)
    end
  end
  if BattleUtils.IsWorldLeaderFight() and player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return BattleSkillManager:GetLoadedClass(BattleConst.WorldLeaderDie)
  elseif self.deadInfo and self.deadInfo.dead_type == ProtoEnum.BattleDeadInfo.DeadType.BLOW_AWAY then
    return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadBlowAway)
  elseif self.deadInfo and self.deadInfo.dead_type == ProtoEnum.BattleDeadInfo.DeadType.DIE_WITH_CASTER then
    return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadBomb)
  elseif BattleUtils.IsFinalBattleP1() then
    return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadFinalBattle)
  elseif BattleUtils.IsB1FinalBattleP1() and player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return BattleSkillManager:GetLoadedClass(BattleConst.B1P1EnemyDeadG6)
  elseif player:IsSpecialNoPcSelfDead() then
    return BattleSkillManager:GetLoadedClass(BattleConst.PetDeadNoPc)
  elseif player and player.model then
    local skillID = ""
    if player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      skillID = BattleConst.SkillID.PetDeadWithPlayerEnemy
      if self.performNode.IsLastDeadNode then
        _G.BattleManager.battleRuntimeData.lastDeadNpcIdx = player.team.npcid
      end
    elseif player.teamEnm == BattleEnum.Team.ENUM_TEAM then
      skillID = BattleConst.SkillID.PetDeadWithPlayerTeam
    else
      return
    end
    local SkillResConf = DataConfigManager:GetSkillResConf(skillID)
    local skillPath = SkillResConf.res_id
    return BattleSkillManager:GetLoadedClass(skillPath)
  else
    local SkillResConf = DataConfigManager:GetSkillResConf(BattleConst.SkillID.PetDead)
    if not SkillResConf then
      return nil
    end
    return BattleSkillManager:GetLoadedClass(SkillResConf.res_id)
  end
end

function BattlePetDiePlayer:Play(performNode)
  Log.Debug("zgx BattlePetDiePlayer:Play playDie")
  self:Reset()
  self:InitFromNode(performNode)
  self.isFinish = false
  self.RemainDeadPet = false
  _G.BattleManager:SaveCraneCameraTemporaryPosData()
  local targetCard
  if BattleUtils.IsFinalBattleP1() then
    if self.performNode.IsFastPlay then
      self:OnDieSkillFinish()
      return nil
    end
    for i, v in ipairs(self.deadInfo.deadPets) do
      local target = self.PawnManager:GetPetByGuid(v.target_id)
      if target then
        targetCard = target.card
        target:SwimSetLockIdle(false)
        target:Die(v)
        table.insert(self.targets, target)
      elseif not targetCard then
        targetCard = self.PawnManager:GetCardByGuid(v.target_id)
        if targetCard then
          targetCard:Die(v)
        end
      end
    end
  elseif BattleUtils.IsB1FinalBattleP2() or BattleUtils.IsB1FinalBattleP3() then
    if self.performNode.IsFastPlay then
      self:Finish()
      return nil
    end
  else
    local target = self.PawnManager:GetPetByGuid(self.deadInfo.target_id)
    if target then
      targetCard = target.card
      target:SwimSetLockIdle(false)
      target:Die(self.deadInfo)
      table.insert(self.targets, target)
    else
      targetCard = self.PawnManager:GetCardByGuid(self.deadInfo.target_id)
      if targetCard then
        targetCard:Die(self.deadInfo)
      end
      Log.Error("zgx can not find pet", self.deadInfo.target_id)
    end
  end
  if not targetCard then
    self:Finish()
    return
  end
  self.team = targetCard.owner.team
  self.player = targetCard.owner
  self.target = self.targets[1]
  if not self.target or not self.target.model then
    if targetCard.BattlePet then
      self.target = targetCard.BattlePet
    end
    self:TryOpenRoleHpAndDelayClose()
    return
  end
  self.target:StopAllSkill()
  if self.performNode.IsFastPlay then
    self:OnDieSkillFinish()
    return nil
  end
  if self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, false)
  end
  BattleUtils.ModifyPetDeathPendingCnt(true)
  if BattleUtils.IsCrowdBattle() and self.team.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    BattleUtils.CheerPetsPerform(BattleEnum.CheerPetPerformState.BeCatch)
  end
  if BattleUtils.IsFinalBattleP2() and self.team.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    _G.BattleManager.stateFsm:SendEvent(BattleEvent.FinalBattleOver)
    _G.BattleManager.battlePawnManager:IsShowPetBuffs(false)
    self.target:SetPopupVisibility(false)
    au.Launch(self:PerformFinalBattleEnemyDie(), function(ok, errorOrMessage)
      if not ok then
        Log.Error(errorOrMessage)
      end
    end)
    self:Finish()
    return
  end
  if BattleUtils.IsWorldLeaderFight() and self.team.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    BattleUtils.ModifyPetDeathPendingCnt(false)
    self:CallTimeDilation()
    self:SafeDelaySeconds("d_Finish", BattleConst.Show.HitTimeDilationTime, self.Finish, self)
    self.target:SwimSetLockIdle(false)
    self.target:Die(self.deadInfo)
    local CastSkill = CastSkillObject.Create()
    CastSkill:SetIsPassive(true)
    CastSkill:SetCallbackOwner(self.target)
    self.target.IsPlayLeaderDie = true
    CastSkill:SetCompleteCallback(function(target)
      target.IsPlayLeaderDie = false
    end)
    local skillClass = self:GetDeadSkillClass(self.player)
    if BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStun, true) == skillClass or BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStunNoBall, true) == skillClass or BattleSkillManager:GetLoadedClass(BattleConst.NightmarePetDeadWithStun, true) == skillClass then
      self.target.card.petState:SetDiePerformType(BattleEnum.DiePerformType.WithStun)
      if BattleSkillManager:GetLoadedClass(BattleConst.NightmarePetDeadWithStun, true) == skillClass then
        CastSkill:SetExtraEvents({
          ActionStart = self.target.ClearNightmareEffect
        })
      end
    end
    self.target:PlaySkillWithClass(skillClass, nil, nil, CastSkill)
    return
  end
  if self.player and self.player.model then
    self:SetModelRotation(self.player.model, self.target.model, self.player.teamEnm == BattleEnum.Team.ENUM_TEAM and self.player.model.CustomTurn)
    local skillObj = self:PrepareSkillObj(self.player.model, false, self.targets)
    if skillObj then
      if BattleUtils.IsFinalBattleP1() then
        local characters = {
          [UE4.EBattleStaticActorType.Player_1] = self.player.model
        }
        for i, v in ipairs(self.targets) do
          local petIndex = UE4.EBattleStaticActorType.Pet_1_1 + v.card.posInField - 1
          characters[petIndex] = v.model
        end
        skillObj:SetCharacters(characters)
      else
        skillObj:SetDynamicData({
          BallPath = self.target:GetBallPath()
        })
        skillObj:RegisterEventCallback("ProcessRoleHp", self, self.ProcessRoleHp)
        skillObj:RegisterEventCallback("ProcessRoleHpEnd", self, self.ProcessRoleHpEnd)
        if BattleUtils.IsB1FinalBattleP1() then
          local characters = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
          local petIndex = UE4.EBattleStaticActorType.Pet_2_1 + self.target.card.posInField - 1
          characters[petIndex] = self.target.model
          skillObj:SetCharacters(characters)
        end
      end
      BattleSkillManager:PlaySkill(skillObj, true)
    else
      self:TryOpenRoleHpAndDelayClose()
      return nil
    end
    _G.NRCAudioManager:PlaySound2DAuto(BattleConst.SoundId.RecallPet)
  else
    local playerModel = _G.BattleManager.battlePawnManager.TeamatePlayer.model
    local killPet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.deadInfo.caster_id)
    local petModel = killPet and killPet.model
    self:SetModelRotation(playerModel, petModel, false)
    local targets = {
      killPet or {},
      killPet and killPet.player or {}
    }
    if self.performNode.IsLastDeadNode and killPet then
      killPet:ChangeBuffVisibility(false)
    end
    if killPet and not self.performNode.IsLastDeadNode then
      local killPetAnimComponent = killPet:GetAnimComponent()
      if killPetAnimComponent and killPetAnimComponent:IsAnyAnimPlaying() then
        targets = {
          {},
          killPet.player
        }
      end
    end
    local skillObj = self:PrepareSkillObj(self.target.model, true, targets)
    if skillObj then
      local result = BattleSkillManager:PlaySkill(skillObj, true)
      if result ~= UE4.ESkillStartResult.Success then
        self:OnDieSkillFinish()
      end
    else
      self:OnDieSkillFinish()
      return nil
    end
  end
end

function BattlePetDiePlayer:SetModelRotation(playerModel, petModel, needTurn)
  if BattleUtils.IsFinalBattleP1() then
    return
  end
  if not (playerModel and petModel and UE4.UObject.IsValid(playerModel)) or not UE4.UObject.IsValid(petModel) then
    return
  end
  if playerModel.CharacterMovement then
    playerModel.CharacterMovement:StopMovementImmediately()
  end
  playerModel.AllowToTurn = false
  local aPos = playerModel:Abs_K2_GetActorLocation() or FVectorZero
  local bPos = petModel:Abs_K2_GetActorLocation()
  local dir = bPos - aPos
  if dir then
    dir.Z = 0
    local Rot = dir:ToRotator():Clamp()
    if needTurn then
      playerModel:CustomTurn(Rot)
      self.deadPosition = bPos
    else
      playerModel:K2_SetActorRotation(Rot, false)
    end
  end
end

function BattlePetDiePlayer:PrepareSkillObj(casterModel, isPassive, targets)
  local skillClass = self:GetDeadSkillClass(self.player)
  if not skillClass then
    Log.ErrorFormat("Dead Skill Class not found")
    return nil
  end
  if BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStun, true) == skillClass or BattleSkillManager:GetLoadedClass(BattleConst.PetDeadWithStunNoBall, true) == skillClass or BattleSkillManager:GetLoadedClass(BattleConst.NightmarePetDeadWithStun, true) == skillClass then
    self.RemainDeadPet = true
    self.target.card.petState:SetDiePerformType(BattleEnum.DiePerformType.WithStun)
  end
  local playerPetBallPath = self:GetPlayerPetBallPath()
  local CastParam = CastSkillObject.Create()
  CastParam.SkillClass = skillClass
  CastParam:SetIsPassive(isPassive):SetCaster(casterModel):SetInterrupt(true):SetCallbackOwner(self):SetSkillBreakCallback(self.OnDieSkillFinish):SetTargetPets(targets):SetDynamicData({BallPath = playerPetBallPath})
  local CharactersList = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  if self.performNode.IsLastDeadNode then
    if 1 == _G.BattleManager.battleRuntimeData.playerNumber then
      local tInfo = CharactersList[UE4.EBattleStaticActorType.Pet_1_2]
      if type(tInfo) ~= "string" or "nil" ~= tInfo then
        CastParam:AddBlackStringValue("FinalHitSecondPet", "FinalHitSecondPet")
        CastParam:AddBlackStringValue("FinalHit", "FinalHit")
      end
    else
      CharactersList = self:InitFinalHitCharacters()
    end
    local tInfo = CharactersList[UE4.EBattleStaticActorType.Pet_1_1]
    if type(tInfo) ~= "string" or "nil" ~= tInfo then
      CastParam:AddBlackStringValue("FinalHit", "FinalHit")
    end
  end
  if self.performNode.IsFastPlay or not self.performNode.IsLastDeadNode and self.team.teamEnm == BattleEnum.Team.ENUM_ENEMY and self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
  elseif self.team.player == BattleManager.battlePawnManager.TeamatePlayer and not BattleUtils.IsFinalBattle() then
    CastParam:AddBlackStringValue("ChangeToPlayerChangePet", "ChangeToPlayerChangePet")
  end
  local _, skillObj = BattleSkillManager:PrepareSkill(self.target, self.target.model.RocoSkill, CastParam, false)
  if not self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    skillObj.IsIgnoreCameraAction = true
  elseif BattleUtils.IsTeam() and self.player ~= self.PawnManager.TeamatePlayer then
    skillObj.IsIgnoreCameraAction = true
  end
  if BattleSkillManager:GetLoadedClass(BattleConst.NightmarePetDeadWithStun, true) == skillClass then
    skillObj:RegisterEventCallback("ActionStart", self.target, self.target.ClearNightmareEffect)
  end
  skillObj:SetCharacters(CharactersList)
  skillObj:RegisterEventCallback("PreEnd", self, self.OnDieSkillFinish)
  skillObj:RegisterEventCallback("End", self, self.OnDieSkillFinish)
  skillObj:RegisterEventCallback("SaveBattleCam", self, self.OnSaveBattleCam)
  self.skillObj = skillObj
  self:CallTimeDilation()
  return skillObj
end

function BattlePetDiePlayer:InitFinalHitCharacters()
  local CharactersList = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local LocalPlayer = _G.BattleManager.battlePawnManager:GetTeamPlayer(BattleEnum.Team.ENUM_TEAM)
  if CharactersList[UE4.EBattleStaticActorType.Player_1].battlePlayer == LocalPlayer then
    CharactersList[UE4.EBattleStaticActorType.Player_1_2] = "nil"
  else
    CharactersList[UE4.EBattleStaticActorType.Player_1] = CharactersList[UE4.EBattleStaticActorType.Player_1_2]
    CharactersList[UE4.EBattleStaticActorType.Player_1_2] = "nil"
  end
  local pet1 = CharactersList[UE4.EBattleStaticActorType.Pet_1_1]
  local pet2 = CharactersList[UE4.EBattleStaticActorType.Pet_1_2]
  if type(pet1) ~= "string" or "nil" ~= pet1 then
    if pet1.BattlePet.player == LocalPlayer then
      CharactersList[UE4.EBattleStaticActorType.Pet_1_2] = "nil"
    elseif (type(pet2) ~= "string" or "nil" ~= pet2) and pet2.BattlePet.player == LocalPlayer then
      CharactersList[UE4.EBattleStaticActorType.Pet_1_1] = pet2
      CharactersList[UE4.EBattleStaticActorType.Pet_1_2] = "nil"
    else
      CharactersList[UE4.EBattleStaticActorType.Pet_1_1] = "nil"
      CharactersList[UE4.EBattleStaticActorType.Pet_1_2] = "nil"
    end
  end
  return CharactersList
end

function BattlePetDiePlayer:GetPlayerPetBallPath()
  if self.player.teamEnm == BattleEnum.Team.ENUM_TEAM then
    return self.target:GetBallPath()
  else
    local killPet = _G.BattleManager.battlePawnManager:GetPetByGuid(self.deadInfo.caster_id)
    if killPet then
      return killPet:GetBallPath()
    end
    local firstPet = _G.BattleManager.battlePawnManager:GetFirstPet(BattleEnum.Team.ENUM_TEAM)
    if firstPet then
      return firstPet:GetBallPath()
    end
    Log.Error("\230\173\187\228\186\161\232\161\168\230\188\148\229\155\158\230\148\182\231\144\131\229\188\130\229\184\184,\232\142\183\229\143\150\228\184\141\229\136\176killPet\227\128\129firstPet caster_id=", self.deadInfo.caster_id)
    return self.target:GetBallPath()
  end
end

function BattlePetDiePlayer:CallTimeDilation()
  if self.performNode.IsLastDeadNode then
    _G.NRCAudioManager:PlaySound2DAuto(1503, "BattlePetDiePlayer:OnLastHit")
  end
  self.LastHitTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.ActionPerform, UE.EBulletTimeChangeType.Change, _G.UE4Helper.GetCurrentWorld(), BattleConst.Show.HitTimeDilation, UE.EBulletTimeChangeType.None, {}, 1)
  self:SafeDelaySeconds("d_RestoreTimeDilation", BattleConst.Show.HitTimeDilationTime, self.RestoreTimeDilation, self)
end

function BattlePetDiePlayer:RestoreTimeDilation()
  if self.LastHitTimeId and self.LastHitTimeId > 0 then
    _G.BattleBulletTimeManager:LeaveBulletTime(self.LastHitTimeId)
    self.LastHitTimeId = -1
  end
end

function BattlePetDiePlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.performInfo = performInfo
  self.deadInfo = performInfo.dead_info
  if not self.deadInfo.dead_type then
    self.deadInfo.dead_type = ProtoEnum.BattleDeadInfo.DeadType.NORMAL_DEAD
  end
end

function BattlePetDiePlayer:TryOpenRoleHpAndDelayClose()
  self:ProcessRoleHp()
  if self.isRoleHpDefeated then
    self:SafeDelaySeconds("d_OnDieSkillFinish", 2, self.OnDieSkillFinish, self)
  else
    self:OnDieSkillFinish()
  end
end

function BattlePetDiePlayer:OnDieSkillFinish(event, skill)
  if not BattleManager:IsInBattle() then
    return
  end
  if self.isFinish then
    return
  end
  self.isFinish = true
  if self.targets and #self.targets > 0 then
    local targets = self.targets
    self.targets = {}
    for i, v in pairs(targets) do
      if v and v.health then
        v.health.hp = 0
      end
      if not self.RemainDeadPet then
        self.team:RecallPet(v)
      end
    end
  end
  if not self.performNode.IsFastPlay then
    if not self.performNode.IsLastDeadNode and self.team.teamEnm == BattleEnum.Team.ENUM_ENEMY and self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
      if _G.BattleManager.vBattleField and _G.BattleManager.vBattleField.battleCameraManager then
        _G.BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, false)
      end
    elseif self.team.player == BattleManager.battlePawnManager.TeamatePlayer and not BattleUtils.IsFinalBattle() and not BattleUtils.IsMultiBattle() then
      BattleUtils.LockCam("ChangePet")
    end
  end
  BattleUtils.ModifyPetDeathPendingCnt(false)
  self:Finish()
end

function BattlePetDiePlayer:ProcessRoleHp()
  if self.performNode.IsLastDeadNode then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleRedPanel)
  end
  if self.player and self.player.model then
    self:OpenRoleHpDefeatedPanel()
  else
    self:Finish()
  end
end

function BattlePetDiePlayer:ProcessRoleHpEnd()
  self:CloseRoleHpDefeatedPanel()
  if self.performNode.IsLastDeadNode then
    self:SaveCams()
    self.skillObj.Blackboard:SetValueAsInt("RestoreCam", -1)
  end
end

function BattlePetDiePlayer:OnSaveBattleCam()
  local Blackboard = self.skillObj.Blackboard
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
end

function BattlePetDiePlayer:SaveBlackboard(blackboard, name)
  local fsm = _G.BattleManager.stateFsm
  FsmUtils.SaveAsProperty(fsm, blackboard, name)
end

function BattlePetDiePlayer:OpenRoleHpDefeatedPanel()
  local diePlayer = self.player
  local asyncData = {
    player = diePlayer,
    diePet = self.target,
    isLast = self.performNode.IsLastDeadNode,
    isShowLetter = true
  }
  local hadData = false
  if diePlayer.teamEnm == BattleEnum.Team.ENUM_TEAM and diePlayer ~= BattleManager.battlePawnManager.TeamatePlayer then
    return
  end
  if self.performNode.performInfo.sync_data and self.performNode.performInfo.sync_data.role_sync_info then
    for _, v in ipairs(self.performNode.performInfo.sync_data.role_sync_info) do
      if v.role_uin == diePlayer.guid and v.hp_result then
        asyncData.black_hp_result = diePlayer.roleInfo.base.black_hp
        asyncData.hp_result = v.hp_result
        asyncData.hp_change = v.hp_change
        hadData = true
      end
      if v.pvp_change then
        asyncData.pvpPlayer = self.BattleManager.battlePawnManager:GetPlayerByGuid(v.role_uin)
        asyncData.pvp_result = v.pvp_score_result
        asyncData.pvp_change = v.pvp_score_change
        hadData = true
      end
    end
  end
  if hadData then
    self.isRoleHpDefeated = true
    _G.NRCModuleManager:DoCmdAsync(asyncData, BattleUIModuleCmd.OpenRoleHpDefeatedTipPanel)
  end
end

function BattlePetDiePlayer:CloseRoleHpDefeatedPanel()
  if self.player and self.player.model and self.isRoleHpDefeated then
    self.isRoleHpDefeated = false
    if BattleUtils.HasUI("BattleRoleHpDefeatedTipPanel") then
      _G.BattleEventCenter:Dispatch(BattleEvent.REFRESH_ROLE_HP_DEFEAT_TIP_END)
    else
      _G.NRCModuleManager:DoCmdAsync(nil, BattleUIModuleCmd.CloseRoleHpDefeatedTipPanel)
    end
  end
end

function BattlePetDiePlayer:Finish()
  self.isFinish = true
  if self.performNode then
    self:CloseRoleHpDefeatedPanel()
    self.performNode:PerformComplete()
  end
  self:Reset()
end

function BattlePetDiePlayer:OnSkillCastMoment(castMoment)
  self.performNode:DispatchPerformCallback(castMoment)
end

function BattlePetDiePlayer:SaveCams()
  self:DestroyCams()
  if self.skillObj then
    self.cameraSA = self:GetBlackboardValue(self.skillObj, "camActor_02_SA", true)
    self.camera = self:GetBlackboardValue(self.skillObj, "camActor_02", true)
  end
end

function BattlePetDiePlayer:DestroyCams()
  if self.camera and UE4.UObject.IsValid(self.camera) then
    self.camera:K2_DestroyActor()
    self.camera = nil
  end
  if self.cameraSA and UE4.UObject.IsValid(self.cameraSA) then
    self.cameraSA:K2_DestroyActor()
    self.cameraSA = nil
  end
end

function BattlePetDiePlayer:GetBlackboardValue(Skill, blackboardKey, remove)
  local blackboard = Skill:GetBlackboard()
  local obj = blackboard:GetValueAsObject(blackboardKey)
  if remove then
    blackboard:RemoveObjectValue(blackboardKey)
  end
  return obj
end

local function PerformFinalBattleBulletTime(self, bulletTimeCurve)
  local beforeBulletTimeWaitTime = BattleConst.FinalBattleBossDieBeforeBulletTimeSpan
  Log.Debug("BattlePetDiePlayer.PerformFinalBattleBulletTime: \229\135\134\229\164\135\232\191\155\229\133\165\229\173\144\229\188\185\230\151\182\233\151\180")
  a.wait(au.DelaySeconds(beforeBulletTimeWaitTime))
  Log.Debug("BattlePetDiePlayer.PerformFinalBattleBulletTime: \229\188\128\229\167\139\232\191\155\229\133\165\229\173\144\229\188\185\230\151\182\233\151\180")
  local bulletTimeSpan = BattleConst.FinalBattleBossDieBulletTimeSpan
  local timeLapsed = 0
  while bulletTimeSpan > timeLapsed do
    local deltaTime = a.wait(au.NextTick())
    timeLapsed = timeLapsed + deltaTime
    local alpha = timeLapsed / bulletTimeSpan
    alpha = math.clamp(alpha, 0, 1)
    local timeDilation = BattleConst.Show.HitTimeDilation
    if bulletTimeCurve then
      timeDilation = bulletTimeCurve:GetFloatValue(alpha)
    else
      timeDilation = _G.LuaMathUtils.LerpWithAlpha(0.5, BattleConst.Show.HitTimeDilation, alpha)
    end
    Log.Debug("BattlePetDiePlayer.PerformFinalBattleBulletTime alpha =", alpha, "timeDilation = ", timeDilation)
    _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), timeDilation)
  end
  Log.Debug("BattlePetDiePlayer.PerformFinalBattleBulletTime: \229\173\144\229\188\185\230\151\182\233\151\180\231\187\147\230\157\159")
  return true
end

BattlePetDiePlayer.PerformFinalBattleBulletTime = a.sync(PerformFinalBattleBulletTime)

local function PerformFinalBattleEnemyDie(self)
  BattleConst.FinalBattleBossDieBeforeBlackScreenTimeSpan = 0.4
  BattleConst.FinalBattleBossDieBlackScreenTimeSpan = 1
  BattleConst.FinalBattleBossDieBeforeBulletTimeSpan = 0.1
  BattleConst.FinalBattleBossDieBulletTimeSpan = 1
  local ok, request, assetOrMessage = a.wait(au.LoadResource(BattleConst.FinalBattleBossDieBulletTimeCurve, 4, 0))
  local bulletTimeCurve, bulletTimeCurveRef
  if ok then
    bulletTimeCurve = assetOrMessage
    bulletTimeCurveRef = UnLua.Ref(bulletTimeCurve)
    Log.Debug("BattlePetDiePlayer.PerformFinalBattleEnemyDie now using bullet time curve")
  else
    Log.Error(assetOrMessage)
  end
  local bulletTimeResult, errorOrMessage = a.wait(self:PerformFinalBattleBulletTime(bulletTimeCurve))
  Log.Debug("BattlePetDiePlayer.PerformFinalBattleEnemyDie bulletTimeResult", bulletTimeResult, errorOrMessage)
  Log.Debug("BattlePetDiePlayer.PerformFinalBattleEnemyDie: \233\135\141\231\189\174\230\151\182\233\151\180\232\134\168\232\131\128")
  _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), 1.0)
  _G.BattleManager.battleRuntimeData.finalBattleInfo.isBossDead = true
  bulletTimeCurve = nil
  bulletTimeCurveRef = nil
end

BattlePetDiePlayer.PerformFinalBattleEnemyDie = a.sync(PerformFinalBattleEnemyDie)

function BattlePetDiePlayer:Clear()
  self:DestroyCams()
end

return BattlePetDiePlayer
