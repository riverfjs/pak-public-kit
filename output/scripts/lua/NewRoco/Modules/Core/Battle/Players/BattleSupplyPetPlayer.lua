local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local PawnManager
local BattleSupplyPetPlayer = BattlePlayerBase:Extend("BattleSupplyPetPlayer")

function BattleSupplyPetPlayer:Ctor()
  BattlePlayerBase.Ctor(self)
  PawnManager = _G.BattleManager.battlePawnManager
  self.PetIndex = 0
  self.SupplyIndex = 0
end

function BattleSupplyPetPlayer:RunSupply(infos, owner, callback)
  self.SupplyInfos = infos
  self.CompleteCallbackOwner = owner
  self.CompleteCallback = callback
  self.PetIndex = 0
  self.SupplyIndex = 0
  _G.BattleEventCenter:Bind(self, BattleEvent.PET_SPAWNED)
  self:Finish()
end

function BattleSupplyPetPlayer:PlaySupply(info)
  BattleUtils.UnLockCam()
  self.CurrentSupplyInfo = info
  if not self.CurrentSupplyInfo then
    Log.Error("BattleSupplyPetPlayer:PlaySupply ", "SupplyInfo Is Nil")
    self:Finish()
    return
  end
  local player = PawnManager:GetPlayerByGuid(self.CurrentSupplyInfo.player_id)
  if not player then
    self:Finish()
    return
  end
  local pet_infos = self.CurrentSupplyInfo.pet_infos
  if not pet_infos or 0 == #pet_infos then
    self:Finish()
    return
  end
  table.insert(self.Players, player)
  player:PrepareForG6()
  self.CurPetNum = 0
  self.TeamEnm = player.teamEnm
  for _, v in ipairs(self.CurrentSupplyInfo.pet_infos) do
    v.posInField = player.FirstPetPosInField + (v.pet_pos <= 0 and 1 or v.pet_pos)
  end
  local petInfos = {}
  for i = 1, #self.CurrentSupplyInfo.pet_infos do
    petInfos[i] = self.CurrentSupplyInfo.pet_infos[i].pet_info
  end
  player.deck:IncrementalRefreshByServer(petInfos)
  local petArray = player.deck:SummonPetOnce(player.teamEnm, player.team, self.CurrentSupplyInfo.pet_infos)
  if petArray then
    for _, v in ipairs(petArray) do
      table.insert(self.PetArray, v)
    end
  end
  if BattleUtils.IsFinalBattleP1() then
    _G.BattleManager.battleRuntimeData:SetFBP1SupplyInfo(#self.PetArray)
  end
end

function BattleSupplyPetPlayer:Play(performNode)
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  local supplyPet = performInfo.supply_pet
  local petInfos = supplyPet.pet_infos
  local infos = {supplyPet}
  if petInfos and #petInfos > 1 then
    for i = #petInfos, 1, -1 do
      local suit = BattleManager.battlePawnManager:GetPetChangeSuitIdByGuid(petInfos[i].pet_id)
      if suit > 0 then
        table.insert(infos, {
          player_id = supplyPet.player_id,
          pet_infos = {
            petInfos[i]
          }
        })
        table.remove(petInfos, i)
      end
    end
  end
  Log.Dump(infos, 5, "BattleSupplyPetPlayer:Play")
  self:RunSupply(infos)
end

function BattleSupplyPetPlayer:CheckNextSupply()
  local nextIndex = self.SupplyIndex + 1
  if nextIndex <= #self.SupplyInfos then
    local nexInfo = self.SupplyInfos[nextIndex]
    local player = PawnManager:GetPlayerByGuid(nexInfo.player_id)
    if player.teamEnm == self.TeamEnm then
      self.SupplyIndex = self.SupplyIndex + 1
      self:PlaySupply(self.SupplyInfos[self.SupplyIndex])
    end
  end
end

function BattleSupplyPetPlayer:PawnPetOver(pet)
  if self.PetArray and #self.PetArray > 0 then
    self.CurPetNum = self.CurPetNum + 1
    if #self.PetArray == self.CurPetNum then
      self:ConsumeSupply()
    end
  end
end

function BattleSupplyPetPlayer:ConsumeSupply()
  for _, v in ipairs(self.PetArray) do
    self:ShowPopup(v)
  end
  if self:IsWildEnemy() then
    self:PlayWildEnemyEntrance()
  else
    self:PlayPetEntrance()
  end
end

function BattleSupplyPetPlayer:PlayWildEnemyEntrance()
  for i, v in ipairs(self.PetArray) do
    v:ShowPet()
  end
  local BattleConf = BattleUtils.GetCurrentBattleConf()
  local ShowRes = BattleConf and BattleConf.show_res
  if string.IsNilOrEmpty(ShowRes) then
    self:Finish()
    return
  end
  local skillClass = BattleSkillManager:GetLoadedClass(BattleUtils.GetWildSupplySkillRes(BattleConf))
  BattleManager.vBattleField.battleFieldActor:PlayAnimWithClass(skillClass, self, self.Finish)
end

function BattleSupplyPetPlayer:PlayPetEntrance()
  local skillPath = self:GetSkillPath()
  if skillPath then
    local skillClass = BattleSkillManager:GetLoadedClass(skillPath)
    self:OnSkillLoad(skillClass)
  else
    Log.Error("\229\174\160\231\137\169\231\154\132\230\149\176\231\155\174\233\148\153\232\175\175\239\188\129\239\188\129 ", self.CurPetNum)
    self:Finish()
  end
end

function BattleSupplyPetPlayer:OnSkillLoad(skillClass)
  if skillClass and BattleManager:IsInBattle(true) then
    _G.BattleManager:CheckPvpFinalBattleBGM()
    local player = self.Players[1]
    if not (player and player.model) or not player.model.RocoSkill then
      self:RestoreCamera()
      self:SupplyEnd()
      return
    end
    local Skill = player.model.RocoSkill:AddSkillObjFromClassAndReturn(skillClass)
    if not Skill then
      self:RestoreCamera()
      self:SupplyEnd()
      return
    end
    local characters
    if BattleUtils.IsFinalBattleP1() then
      characters = {
        [UE4.EBattleStaticActorType.Player_1] = self.Players[1].model
      }
    else
      characters = self:GetAllPawnActorForSkill()
    end
    local targets = {}
    for i, v in ipairs(self.PetArray) do
      v:SetScale(1)
      v:SwimSetLockIdle(false)
      if v.model then
        BattleUtils.SetParticleKeyForSkillObj(v.model, Skill, v.card.medalBlackBoard)
      end
      targets[i] = v.model
      local petIndex = UE4.EBattleStaticActorType.Pet_1_1 + v.card.posInField - 1
      characters[petIndex] = v.model
    end
    if 1 == #targets then
      Skill.PlayerAmountType = 1
    else
      Skill.PlayerAmountType = 2
    end
    local ballAddPath = {"None", "None"}
    for i = 2, #self.PetArray do
      ballAddPath[i - 1] = self.PetArray[i]:GetBallPath()
    end
    if not BattleUtils.IsFinalBattleP1() then
      local playerStartIndex = UE4.EBattleStaticActorType.Player_1
      local petStartIndex = UE4.EBattleStaticActorType.Pet_1_1
      local MaxPlaterIndex = UE4.EBattleStaticActorType.Player_1_4
      local capacity = self.Players[1].team.capacity
      if self.Players[1].teamEnm == BattleEnum.Team.ENUM_ENEMY then
        playerStartIndex = UE4.EBattleStaticActorType.Player_2
        petStartIndex = UE4.EBattleStaticActorType.Pet_2_1
        MaxPlaterIndex = UE4.EBattleStaticActorType.Player_2_4
      end
      for i, v in ipairs(self.Players) do
        local playerIndex = i - 1
        if characters[playerStartIndex + playerIndex] ~= v.model then
          local oldPlayer = characters[playerStartIndex + playerIndex]
          characters[playerStartIndex + playerIndex] = v.model
          for i = playerStartIndex + playerIndex + 1, MaxPlaterIndex do
            if characters[i] == v.model then
              characters[i] = oldPlayer
              break
            end
          end
        end
        local petPos = 1
        for j = 1, #self.PetArray do
          local pet = self.PetArray[j]
          if pet.player == v then
            characters[petStartIndex + petPos - 1 + playerIndex * capacity] = pet.model
            petPos = petPos + 1
          end
        end
      end
    end
    if BattleUtils.IsB1FinalBattleP1() then
      local bpBall = _G.BattleManager.battleRuntimeData:GetB1P1BallActor()
      if bpBall then
        Skill:GetBlackboard():SetValueAsNoDestroyObject(BattleConst.B1BallBlackboardKey, bpBall)
      end
    end
    local caster = self.Players[1].model
    Skill:SetCaster(caster)
    Skill:SetTargets(targets)
    Skill:SetCharacters(characters)
    Skill:SetDynamicData({
      BallPath = self.PetArray[1]:GetBallPath(),
      BallAdditionalPaths = ballAddPath
    })
    Skill:RegisterEventCallback("ActionStart", self, self.OnSupplyPostStart)
    Skill:RegisterEventCallback("PostStart", self, self.OnSupplyPostStart)
    Skill:RegisterEventCallback("AdjustCamera", self, self.RestoreCamera)
    Skill:RegisterEventCallback("End", self, self.SupplyEnd)
    Skill:RegisterEventCallback("PreEnd", self, self.SupplyEnd)
    Skill:RegisterEventCallback("AdjustCameraInMulti", self, self.AdjustCameraInMulti)
    Skill.BattleGenderType = self.Players[1].roleInfo.base.sex
    player.model.RocoSkill:StopCurrentSkill()
    player:PlaySkillObject(Skill)
  end
end

function BattleSupplyPetPlayer:GetAllPawnActorForSkill()
  local character = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  if BattleUtils.IsNpcAssist() and self.Players[1]:IsAssistNpc() then
    character[UE4.EBattleStaticActorType.Player_2] = character[UE4.EBattleStaticActorType.Player_1]
    character[UE4.EBattleStaticActorType.Pet_2_1] = character[UE4.EBattleStaticActorType.Pet_1_1]
  end
  return character
end

function BattleSupplyPetPlayer:AdjustCameraInMulti(name, skill)
  local Blackboard
  if skill then
    Blackboard = skill:GetBlackboard()
  else
    return
  end
  local Kamera = Blackboard:GetValueAsObject("camActor_0002")
  local KameraBone = Blackboard:GetValueAsObject("camActor_0002_SA")
  local topPos, footPos
  local cameraPos = UE4.FVector(0, 0, 0)
  local socketNameHead = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Head)
  local socketNamePos = UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(UE4.EFXAttachPointType.Pos)
  for _, v in ipairs(self.PetArray) do
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
  cameraPos = cameraPos / #self.PetArray
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

function BattleSupplyPetPlayer:OnSupplyPostStart(name, skill)
  if BattleUtils.IsFinalBattle() then
    return
  end
  for i, v in ipairs(self.PetArray) do
    v.card.IgnoreAnimCheck = true
    v:ActiveSwimComponent(false)
    v.buffComponent:OnPetBeCatch()
    v:ShowPet()
    v:PrepareForG6()
    v:ResetToBornPosition()
  end
end

function BattleSupplyPetPlayer:RestoreCamera(name, skill)
  for i, v in ipairs(self.PetArray) do
    v:ShowPet()
  end
  local Blackboard
  if skill then
    Blackboard = skill:GetBlackboard()
  else
    return
  end
  BattleManager.vBattleField.battleCameraManager:CalcPosCache()
  BattleManager.vBattleField.battleCameraManager:ClearTemporaryPosData()
  if self.TeamEnm == BattleEnum.Team.ENUM_TEAM then
    if Blackboard then
      self.Kamera = Blackboard:GetValueAsObject("camActor_0002")
      self.KameraBone = Blackboard:GetValueAsObject("camActor_0002_SA")
    end
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, true)
    if self.Kamera then
      self.Kamera:Abs_K2_SetActorTransform_WithoutHit(BattleManager.vBattleField:GetPCGCamTransform())
      local cameraComponent = self.Kamera:GetComponentByClass(UE4.UCameraComponent)
      if cameraComponent then
        cameraComponent.FieldOfView = BattleManager.vBattleField.battleCameraManager.FOV
      end
    end
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  else
    if Blackboard then
      self.Kamera = Blackboard:GetValueAsObject("camActor_Save1")
      self.KameraBone = Blackboard:GetValueAsObject("camActor_Save1_SA")
    end
    BattleUtils.GetMainWindow().counter = 0
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0, nil, nil, true)
    if self.Kamera then
      self.Kamera:Abs_K2_SetActorTransform_WithoutHit(BattleManager.vBattleField:GetPCGCamTransform())
      local cameraComponent = self.Kamera:GetComponentByClass(UE4.UCameraComponent)
      if cameraComponent then
        cameraComponent.FieldOfView = BattleManager.vBattleField.battleCameraManager.FOV
      end
    end
    BattleManager.vBattleField.battleCameraManager:ChangeToSkill(0)
  end
end

function BattleSupplyPetPlayer:SupplyEnd()
  self:HidePopup()
  if self.Kamera and UE.UObject.IsValid(self.Kamera) then
    self.Kamera:K2_DestroyActor()
  end
  if self.KameraBone and UE.UObject.IsValid(self.KameraBone) then
    self.KameraBone:K2_DestroyActor()
  end
  self.Kamera = nil
  self.KameraBone = nil
  for _, player in ipairs(self.Players or {}) do
    player:RecoverFromG6()
  end
  for _, battlePet in ipairs(self.PetArray or {}) do
    battlePet.card.IgnoreAnimCheck = false
    battlePet:ActiveSwimComponent(true)
    battlePet.buffComponent:RestartBattleState()
    battlePet:RecoverFromG6()
  end
  self:Finish()
end

function BattleSupplyPetPlayer:IsWildEnemy()
  return self.TeamEnm == BattleEnum.Team.ENUM_ENEMY and BattleUtils.IsWildEnemy()
end

function BattleSupplyPetPlayer:IsB1P1Enemy()
  return self.TeamEnm == BattleEnum.Team.ENUM_ENEMY and BattleUtils.IsB1FinalBattleP1()
end

function BattleSupplyPetPlayer:ShowPopup(pet)
  if self:IsB1P1Enemy() then
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
    BattleEnum.InfoPopupType.SummonPet,
    pet.player,
    pet.card
  })
end

function BattleSupplyPetPlayer:HidePopup()
  if self:IsB1P1Enemy() then
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.UI_HIDE_INFO_POPUP, self.Players[1])
end

function BattleSupplyPetPlayer:Finish()
  self.CurrentSupplyInfo = nil
  if self.SupplyInfos and self.SupplyIndex + 1 <= #self.SupplyInfos then
    self.SupplyIndex = self.SupplyIndex + 1
    self.Players = {}
    self.PetArray = {}
    self:PlaySupply(self.SupplyInfos[self.SupplyIndex])
  else
    local Callback = self.CompleteCallback
    local Owner = self.CompleteCallbackOwner
    self.CompleteCallback = nil
    self.CompleteCallbackOwner = nil
    _G.BattleEventCenter:UnBind(self)
    if Callback then
      Callback(Owner)
    end
    if self.performNode then
      self.performNode:PerformComplete()
    end
  end
end

function BattleSupplyPetPlayer:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.PET_SPAWNED then
    self:PawnPetOver(...)
    return true
  end
end

function BattleSupplyPetPlayer:GetSkillPath()
  if BattleUtils.IsFinalBattleP1() then
    return BattleConst.FinalBattleHuanChong
  elseif BattleUtils.IsFinalBattleP2() then
    return BattleConst.FinalBattleP2Debut
  else
    if self.TeamEnm == BattleEnum.Team.ENUM_ENEMY and BattleUtils.IsB1FinalBattleP1() then
      return BattleConst.B1P1EnemyCallOutG6
    end
    if BattleUtils.IsNpcAssist() and self.Players[1]:IsAssistNpc() then
      return BattleConst.EnemyHuanChong
    else
      if self.PetArray then
        if 1 == #self.PetArray then
          return self.PetArray[1].card.AppearancePath:GetHuanChong()
        else
          return self.PetArray[1].card.AppearancePath:GetHuanChong(true)
        end
      end
      Log.Error("zgx \230\178\161\230\156\137\232\161\165\229\133\133\229\174\160\231\137\169\231\154\132\231\155\174\230\160\135")
    end
  end
end

return BattleSupplyPetPlayer
