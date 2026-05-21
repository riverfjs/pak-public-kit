local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local EventDispatcher = require("Common.EventDispatcher")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleChangePetPlayer = BattlePlayerBase:Extend()

function BattleChangePetPlayer:Ctor()
  BattlePlayerBase.Ctor(self)
  EventDispatcher():Attach(self)
  self.BattleManager = _G.BattleManager
  self.PawnManager = _G.BattleManager.battlePawnManager
end

function BattleChangePetPlayer:Play(performNode)
  BattleUtils.UnLockCam()
  self:Reset()
  self:InitFromNode(performNode)
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED, BattleEvent.PET_LOAD_MODE_LOVER)
  Log.Debug("Show Change Pet Params: ", "New: ", self.change_pet.battle_pet_id, " Old: ", self.change_pet.rest_pet_id)
  self.Player = self.PawnManager:GetPlayerByGuid(self.change_pet.player_id)
  self.NewPetID = self.change_pet.battlePets or {}
  self.OldPetID = self.change_pet.restPets or {}
  self:SetHpVisible(false)
  self:CheckPetReturn()
  if not self.NewPetID or #self.NewPetID <= 0 then
    self:CheckFinish()
    return
  end
  if not self.Player then
    self:CheckFinish()
    return
  end
  self.Player:PrepareForG6()
  self.deck = self.Player.deck
  self.battlePetInfo = self.change_pet.battleInfos
  self.isRecallFinish = false
  if not self.Player.model or not self.Player.model.RocoSkill then
    self:OnRecallFinish()
    return
  end
  if self.change_pet.is_cmd == true and not self.performNode.IsFastPlay then
    self:RecallPet()
  else
    self:OnRecallFinish()
  end
end

function BattleChangePetPlayer:SetHpVisible(isShow)
  if not self.Player then
    return
  end
  if BattleUtils.IsFinalBattleP2() and self.Player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
    return
  end
  if BattleUtils.IsTeam() then
    if isShow and not BattleManager.IsTeamBossToCatch then
      _G.BattleEventCenter:Dispatch(BattleEvent.SHOW_TEAMBATTLE_HP)
    end
    if self.Player.guid ~= self.PawnManager.TeamatePlayer.guid then
      return
    end
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAYERSKILL_ISHIDE_HP, isShow)
end

function BattleChangePetPlayer:CheckPetReturn()
  local toRemove = {}
  for i, v in ipairs(self.NewPetID) do
    if self.BattleManager.battleRuntimeData:GetHasPetReturn(v) then
      table.insert(toRemove, v)
    end
  end
  for __, toRemove in ipairs(toRemove) do
    for i, newPetId in ipairs(self.NewPetID) do
      if toRemove == newPetId then
        table.remove(self.NewPetID, i)
        table.remove(self.OldPetID, i)
        break
      end
    end
  end
end

function BattleChangePetPlayer:Reset()
  self.Player = nil
  self.change_pet = nil
  self.battlePetInfo = nil
  self.NewPetID = {}
  self.OldPetID = {}
  self.performNode = nil
  self.deck = nil
  self.isRecallFinish = true
  self.NewPet = {}
end

function BattleChangePetPlayer:InitFromNode(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.PerformInfo = performInfo
  self.change_pet = performInfo.change_pet
end

function BattleChangePetPlayer:RecallPet()
  Log.Debug("Show Change Pet Params: ", "New: ", self.change_pet.battle_pet_id, " Old: ", self.change_pet.rest_pet_id)
  for _, v in ipairs(self.OldPetID) do
    local restPet = self.PawnManager:GetPetByGuid(v)
    if restPet then
      restPet:ChangeBuffVisibility(false)
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(BattleConst.SoundId.RecallPet)
  self.Player.model.RocoSkill:StopCurrentSkill()
  local targets = {}
  local extraParams = {}
  local ballAddPath = {}
  for i, v in ipairs(self.OldPetID) do
    local old = self.PawnManager:GetPetByGuid(v)
    if old and old.model then
      table.insert(targets, old.model)
      if not extraParams.BallPath then
        extraParams.BallPath = old:GetBallPath()
      else
        ballAddPath[#ballAddPath + 1] = old:GetBallPath()
      end
    end
  end
  extraParams.BallAdditionalPaths = ballAddPath
  if #targets > 0 then
    if self.Player.TakeBallSkill then
      self.Player.TakeBallSkill:ClearCachedObjects()
    end
    if self.Player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
      self.Player:PlaySkill(BattleConst.EnemyRecallPet, nil, self, self.OnRecallFinish, extraParams, nil, targets)
    else
      self.Player:PlaySkill(BattleConst.SkillID.RecallPet, nil, self, self.OnRecallFinish, extraParams, nil, targets)
    end
  else
    self:OnRecallFinish()
  end
end

function BattleChangePetPlayer:OnRecallFinish()
  if not self.isRecallFinish then
    self.isRecallFinish = true
    local newPet = self.NewPetID
    local oldPet = self.OldPetID
    local deck = self.deck
    local player = self.Player
    if deck then
      deck:IncrementalRefreshByServer(self.battlePetInfo)
    else
      Log.Debug("BattleChangePetPlayer:OnRecallFinish deck is nil")
    end
    for i = 1, #newPet do
      deck:ChangeBattlePet(newPet[i], oldPet[i])
    end
    for _, v in ipairs(self.NewPetID) do
      local battlePetCard = deck:GetCardByGuid(v)
      if battlePetCard then
        _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
          BattleEnum.InfoPopupType.SummonPet,
          player,
          battlePetCard
        })
      end
    end
  end
end

function BattleChangePetPlayer:GetSkillPath()
  if self.change_pet and self.change_pet.perform_type == ProtoEnum.ChangePetPerformType.CPPT_NO_BALL then
    return BattleConst.NoBallHuanChong
  elseif BattleUtils.IsNpcAssist() and self.Player:IsAssistNpc() then
    return BattleConst.EnemyHuanChong
  elseif self.NewPet then
    if 1 == #self.NewPet then
      if self.NewPet[1].card and self.NewPet[1].card.AppearancePath then
        return self.NewPet[1].card.AppearancePath:GetHuanChong()
      end
    elseif self.NewPet[1].card and self.NewPet[1].card.AppearancePath then
      return self.NewPet[1].card.AppearancePath:GetHuanChong(true)
    end
  else
    Log.Error("zgx \230\178\161\230\156\137\230\141\162\229\174\160\231\154\132\229\174\160\231\137\169!!!")
  end
end

function BattleChangePetPlayer:PawnPetModelOver(pet)
  if #self.NewPet < #self.NewPetID then
    for i = 1, #self.NewPetID do
      if self.NewPetID[i] == pet.guid then
        pet:HidePet()
        pet:ChangeBuffVisibility(false)
        pet:ResetToBornPosition()
      end
    end
  end
end

function BattleChangePetPlayer:PawnPetOver(pet)
  if #self.NewPet < #self.NewPetID then
    for i = 1, #self.NewPetID do
      if self.NewPetID[i] == pet.guid then
        self.NewPet[i] = pet
      end
    end
    if #self.NewPet == #self.NewPetID then
      for i, battlePet in ipairs(self.NewPet) do
        battlePet:ChangeBuffVisibility(false)
        if not self.battlePetInfo[i] then
          battlePet.card:ClearBuffs()
        end
        battlePet.buffComponent:RemoveBuffs(true)
        battlePet.buffComponent:InitByCard(battlePet.card)
        battlePet:SetIKEnable(false)
      end
      self:ReplacePet()
    end
  end
end

function BattleChangePetPlayer:ReplacePet()
  if self.performNode and self.performNode.IsFastPlay then
    self:OnCallPet()
    self:CheckFinish()
    return
  end
  if not self.Player.model or not UE4.UObject.IsValid(self.Player.model) then
    self:OnCallPet()
    self:CheckFinish()
    return
  end
  local activeSkill = self.Player.model.RocoSkill:GetActiveSkill()
  if activeSkill then
    self.Player.model.RocoSkill:CancelSkill(activeSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
  end
  local skillPath = self:GetSkillPath()
  local skillClass
  if skillPath then
    skillClass = BattleSkillManager:GetLoadedClass(skillPath)
  end
  local validPetNum = 0
  for _, v in ipairs(self.NewPet) do
    if v and v.model then
      validPetNum = validPetNum + 1
    end
  end
  if skillClass and skillPath and validPetNum > 0 then
    local Skill = self.Player.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
    if Skill then
      local ballAddPath = {}
      local ballPath
      local targets = {}
      local petNumber = 1
      local characters = self:GetAllPawnActorForSkill()
      if self.Player.teamEnm == BattleEnum.Team.ENUM_TEAM then
        petNumber = _G.BattleManager.battleRuntimeData.playerPetNumber
      else
        petNumber = _G.BattleManager.battleRuntimeData.enemyPetNumber
      end
      for i = 1, petNumber do
        for _, v in ipairs(self.NewPet) do
          if v.card.posInField == i then
            if not ballPath then
              ballPath = BattleUtils.GetPetBallPath(v.card.petInfo.battle_common_pet_info)
            else
              table.insert(ballAddPath, BattleUtils.GetPetBallPath(v.card.petInfo.battle_common_pet_info))
            end
            table.insert(targets, v.model)
            BattleUtils.SetParticleKeyForSkillObj(v.model, Skill, v.card.medalBlackBoard)
          end
        end
      end
      do
        local playerStartIndex = UE4.EBattleStaticActorType.Player_1
        local petStartIndex = UE4.EBattleStaticActorType.Pet_1_1
        local MaxPlaterIndex = UE4.EBattleStaticActorType.Player_1_4
        if self.Player.teamEnm == BattleEnum.Team.ENUM_ENEMY then
          playerStartIndex = UE4.EBattleStaticActorType.Player_2
          petStartIndex = UE4.EBattleStaticActorType.Pet_2_1
          MaxPlaterIndex = UE4.EBattleStaticActorType.Player_2_4
        end
        if characters[playerStartIndex] ~= self.Player.model then
          local oldPlayer = characters[playerStartIndex]
          characters[playerStartIndex] = self.Player.model
          for i = playerStartIndex + 1, MaxPlaterIndex do
            if characters[i] == self.Player.model then
              characters[i] = oldPlayer
              break
            end
          end
        end
        for i = 1, #targets do
          characters[petStartIndex + i - 1] = targets[i]
        end
      end
      if 1 == #self.NewPet then
        Skill.PlayerAmountType = 1
      else
        Skill.PlayerAmountType = 2
      end
      if not self.performNode.performPlayer.turnPlayer.IsMySelfPerform and self.Player ~= self.PawnManager.TeamatePlayer then
        Skill.IsIgnoreCameraAction = true
      elseif BattleUtils.IsTeam() and self.Player ~= self.PawnManager.TeamatePlayer then
        Skill.IsIgnoreCameraAction = true
      end
      Skill:SetCaster(self.Player.model)
      Skill:SetTargets(targets)
      Skill:SetCharacters(characters)
      Skill:SetDynamicData({BallPath = ballPath, BallAdditionalPaths = ballAddPath})
      Skill:RegisterEventCallback("ActionStart", self, self.OnCallPetPostStart)
      Skill:RegisterEventCallback("PostStart", self, self.OnCallPetPostStart)
      Skill:RegisterEventCallback("AdjustCamera", self, self.OnCallPet)
      Skill:RegisterEventCallback("AdjustCameraInMulti", self, self.AdjustCameraInMulti)
      Skill:RegisterEventCallback("PreEnd", self, self.OnSKillComplete)
      Skill:RegisterEventCallback("End", self, self.OnSKillComplete)
      Skill:RegisterEventCallback("HideBuffBar", self, self.HideBuffBar)
      Skill:RegisterEventCallback("ShowBuffBar", self, self.ShowBuffBar)
      Skill.BattleGenderType = self.Player.roleInfo.base.sex
      local BattleUMG = BattleUtils.GetMainWindow()
      if BattleUMG then
        BattleUMG.counter = 0
      end
      if BattleUtils.IsDeepWater() then
        Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Water
      else
        Skill.BattleFieldLimitType = UE.EBattleFieldLimitType.Ground
      end
      self.Player:PlaySkillObject(Skill)
    else
      Log.Error("zgx Skill is nil", skillPath or "nil")
      self:OnCallPet()
      self:CheckFinish()
    end
  else
    self:OnCallPet()
    self:CheckFinish()
  end
end

function BattleChangePetPlayer:GetAllPawnActorForSkill()
  local character = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  if BattleUtils.IsNpcAssist() and self.Player:IsAssistNpc() then
    character[UE4.EBattleStaticActorType.Player_2] = character[UE4.EBattleStaticActorType.Player_1]
    character[UE4.EBattleStaticActorType.Pet_2_1] = character[UE4.EBattleStaticActorType.Pet_1_1]
  end
  return character
end

function BattleChangePetPlayer:HideBuffBar()
  for _, battlePet in ipairs(self.PawnManager:GetAllPets()) do
    if battlePet then
      battlePet:ChangeBuffVisibility(false)
    end
  end
end

function BattleChangePetPlayer:ShowBuffBar()
  for _, battlePet in ipairs(self.PawnManager:GetAllPets()) do
    if battlePet then
      battlePet:ChangeBuffVisibility(true)
    end
  end
end

function BattleChangePetPlayer:AdjustCameraInMulti(name, skill)
  local Blackboard
  if skill then
    Blackboard = skill:GetBlackboard()
  else
    return
  end
  local Kamera = Blackboard:GetValueAsObject("camActor_0002")
  local KameraBone = Blackboard:GetValueAsObject("camActor_0002_SA")
  if not Kamera or not KameraBone then
    return
  end
  local topPos, footPos
  local cameraPos = UE4.FVector(0, 0, 0)
  local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
  local socketNamePos = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Pos)
  for _, v in ipairs(self.NewPet) do
    local meshComp = v.model:GetComponentByClass(UE4.USkeletalMeshComponent)
    local posHead = meshComp:Abs_GetSocketLocation(socketNameHead)
    local posPos = meshComp:Abs_GetSocketLocation(socketNamePos)
    if not topPos or topPos < posHead.Z then
      topPos = posHead.Z
    end
    if not footPos or footPos > posPos.Z then
      footPos = posPos.Z
    end
    local petPos = v.model:Abs_K2_GetActorLocation()
    cameraPos = UE4.FVector(cameraPos.X + petPos.X, cameraPos.Y + petPos.Y, cameraPos.Z + petPos.Z)
  end
  cameraPos = cameraPos / #self.NewPet
  local heightGap = 0
  if footPos and topPos then
    cameraPos.Z = (footPos + topPos) / 2
    heightGap = topPos - footPos
  end
  local eyeHeight = 0.6 * heightGap
  local cameraDistance = UE4.FVector(147, -137, 359)
  local screenWidth = math.tan(math.rad(Kamera.CameraComponent.FieldOfView / 2)) * UE4.UKismetMathLibrary.Vector_Distance2D(cameraDistance, UE4.FVector(0, 0, 0))
  local screenheight = screenWidth / Kamera.CameraComponent.AspectRatio
  local cameraScale = math.max(1, eyeHeight / screenheight)
  KameraBone:Abs_K2_SetActorLocation_WithoutHit(cameraPos)
  KameraBone:SetActorScale3D(UE4.FVector(cameraScale, cameraScale, cameraScale))
end

function BattleChangePetPlayer:OnCallPetPostStart(eventName, skill)
  self:HideBuffBar()
  for _, battlePet in ipairs(self.NewPet) do
    battlePet.card.IgnoreAnimCheck = true
    battlePet:ActiveSwimComponent(false)
    battlePet.buffComponent:OnPetBeCatch()
    battlePet:ShowPet(false)
    battlePet:PrepareForG6()
  end
end

function BattleChangePetPlayer:OnCallPet(Event, Skill)
  local battleManager = _G.BattleManager
  if self.performNode and self.performNode.performPlayer.turnPlayer.IsMySelfPerform then
    battleManager.vBattleField.battleCameraManager:CalcPosCache()
    BattleManager.vBattleField.battleCameraManager:ClearTemporaryPosData()
    battleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end
  self:ShowNewPet()
end

function BattleChangePetPlayer:ShowNewPet()
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.Player)
  for _, battlePet in ipairs(self.NewPet or {}) do
    battlePet:ChangeBuffVisibility(true)
    battlePet:ShowPet()
    battlePet:SetIKEnable(true)
    battlePet:PinOnTheGround()
  end
end

function BattleChangePetPlayer:OnSKillComplete()
  self:ShowNewPet()
  self:ShowBuffBar()
  self:CheckFinish()
end

function BattleChangePetPlayer:CheckFinish()
  if self.performNode then
    _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.Player)
    self.PauseNum = 0
    if not self.performNode.IsFastPlay and self.NewPetID then
      for _, v in ipairs(self.NewPetID) do
        BattleEventCenter:Dispatch(BattleEvent.DefenceOtherEnd, v, self)
      end
    end
    if self.Player then
      self.Player:RecoverFromG6()
    end
    for _, battlePet in ipairs(self.NewPet) do
      battlePet.card.IgnoreAnimCheck = false
      battlePet:ActiveSwimComponent(true)
      battlePet.buffComponent:RestartBattleState()
      battlePet:RecoverFromG6()
    end
    if 0 == self.PauseNum then
      self:Finish()
    end
  end
end

function BattleChangePetPlayer:Finish()
  if self.performNode then
    self:SetHpVisible(true)
    Log.Debug("BattleChangePetPlayer Play OnSkillComplete:", self.performNode:GetNodeIdx())
    _G.BattleEventCenter:UnBind(self)
    self.performNode:PerformComplete()
  end
  self:Reset()
end

function BattleChangePetPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:PawnPetOver(...)
    return true
  elseif eventName == BattleEvent.PET_LOAD_MODE_LOVER then
    self:PawnPetModelOver(...)
  end
end

function BattleChangePetPlayer:OnSkillCastMoment(castMoment, LimitType)
  if self.performNode then
    self.performNode:DispatchPerformCallback(castMoment, LimitType)
  end
end

return BattleChangePetPlayer
