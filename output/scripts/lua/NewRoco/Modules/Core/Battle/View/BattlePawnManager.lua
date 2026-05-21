local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleTeam = require("NewRoco.Modules.Core.Battle.Entity.BattleTeam")
local BattlePlayer = require("NewRoco.Modules.Core.Battle.Entity.BattlePlayer")
local BattlePet = require("NewRoco.Modules.Core.Battle.Entity.BattlePet")
local BattleNpc = require("NewRoco.Modules.Core.Battle.Entity.BattleNpc")
local BattlePlayerInspector = require("NewRoco.Modules.Core.Battle.Entity.BattlePlayerInspector")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattlePawnManager = {}
BattlePawnManager.BattleOnLookerType = {Npc = 0, PlayerInspector = 1}
local tInsert = table.insert

function BattlePawnManager:Init(VBattleField)
  Log.Warning("BattlePawnManager Init")
  self.VBattleField = VBattleField
  self.EnemyPlayer = nil
  self.TeamatePlayer = nil
  self.AllPlayerTeam = {}
  self.AllEnemyTeam = {}
  self.battleNpcList = {}
  self.battleOnLookerDataList = {}
  self.battleOnLookerDataListDisplay = {}
  self.battleOnLookerDisplayIsRefreshing = false
  self.PendingKillBattlePets = {}
  self.ReplaceAllBattlePets = {}
  self.seralizeId = 0
  self.loadingArgs = {}
  self.requestDict = {}
  self.invalidRes = {}
  self.unluaRef = {}
end

function BattlePawnManager:ClearPawnObj(bIsSendLeave)
  if self.AllPlayerTeam then
    for _, v in pairs(self.AllPlayerTeam) do
      if bIsSendLeave and v.player then
        _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_LEAVE_GAME, v.player, true)
      end
      v:LeaveBattle()
    end
  end
  if self.AllEnemyTeam then
    for _, v in pairs(self.AllEnemyTeam) do
      if bIsSendLeave and v.player then
        _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_LEAVE_GAME, v.player, true)
      end
      v:LeaveBattle()
    end
  end
  self:ClearBattleNpcSpawnContext()
  if self.battleNpcList then
    for i, battleNpc in ipairs(self.battleNpcList) do
      battleNpc:Destroy()
    end
  end
  _G.BattleManager.battleRuntimeData.battleOnLookerInfo.onLookersSpawnExecuted = false
  self:ClearPendingKillModels()
  if self.ReplaceAllBattlePets then
    for _, battlePet in ipairs(self.ReplaceAllBattlePets) do
      battlePet:Destroy()
    end
  end
  self.ReplaceAllBattlePets = {}
  self.AllPlayerTeam = {}
  self.AllEnemyTeam = {}
  self.battleNpcList = {}
  self.battleOnLookerDataList = {}
  self.battleOnLookerDataListDisplay = {}
  self.enemyTeam = nil
  self.playerTeam = nil
  self.TeamatePlayer = nil
  self.EnemyPlayer = nil
  self.loadingArgs = {}
  for _, objRef in pairs(self.unluaRef) do
    if UE.UObject.IsValid(objRef) then
      UnLua.Unref(objRef)
    end
  end
  self.unluaRef = {}
end

function BattlePawnManager:ClearPawnSkill()
  if self.AllPlayerTeam then
    for _, v in pairs(self.AllPlayerTeam) do
      v:ClearSkill()
    end
  end
  if self.AllEnemyTeam then
    for _, v in pairs(self.AllEnemyTeam) do
      v:ClearSkill()
    end
  end
end

function BattlePawnManager:ClearPawnObjDelay()
  if self.AllPlayerTeam then
    for _, v in pairs(self.AllPlayerTeam) do
      local opTeam = v
      BattleBudget:PushTask(nil, function()
        if opTeam then
          opTeam:LeaveBattle()
        end
      end)
    end
  end
  if self.AllEnemyTeam then
    for _, v in pairs(self.AllEnemyTeam) do
      local opTeam = v
      BattleBudget:PushTask(nil, function()
        if opTeam then
          opTeam:LeaveBattle()
        end
      end)
    end
  end
  self:ClearBattleNpcSpawnContext()
  BattleBudget:PushTask(nil, function()
    for i, battleNpc in ipairs(self.battleNpcList or {}) do
      battleNpc:Destroy()
    end
    if _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleOnLookerInfo then
      _G.BattleManager.battleRuntimeData.battleOnLookerInfo.onLookersSpawnExecuted = false
    end
    self:ClearPendingKillModels()
    if self.ReplaceAllBattlePets then
      for _, battlePet in ipairs(self.ReplaceAllBattlePets) do
        battlePet:Destroy()
      end
    end
    self.ReplaceAllBattlePets = {}
    self.AllPlayerTeam = {}
    self.AllEnemyTeam = {}
    self.battleNpcList = {}
    self.battleOnLookerDataList = {}
    self.battleOnLookerDataListDisplay = {}
    self.enemyTeam = nil
    self.playerTeam = nil
    self.TeamatePlayer = nil
    self.EnemyPlayer = nil
    self.loadingArgs = {}
    for _, objRef in pairs(self.unluaRef or {}) do
      if UE.UObject.IsValid(objRef) then
        UnLua.Unref(objRef)
      end
    end
    self.unluaRef = {}
  end)
end

function BattlePawnManager:GetMyServerSide()
  if self.TeamatePlayer then
    return self.TeamatePlayer.roleInfo.base.side
  end
  return 0
end

function BattlePawnManager:LeaveBattle()
  self:Clear()
end

function BattlePawnManager:LeaveBattleDelay()
  self:ClearDelay()
end

function BattlePawnManager:SetBattleInitInfo(battleInitInfo, PrepareTable)
  if not battleInitInfo then
    Log.Error("battleInitInfo is nil")
    return
  end
  self.battleConfig = _G.DataConfigManager:GetBattleConf(battleInitInfo.battle_cfg_id[1])
  if not self.battleConfig then
    Log.Error("unknown battle config : ", battleInitInfo.battle_cfg_id[1])
    return
  end
  if not _G.BattleManager.vBattleField.battleFieldConf then
    Log.Error("unknown battle Field : ", battleInitInfo.battle_cfg_id[1])
    return
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  if BattleUtils.IsDeepWater() then
    self.VBattleField:SpawnWaterBattleReflection()
  end
  self:PreProcessTeamBattle(battleInitInfo)
  local real_player = 0
  local myPetPos = 0
  for playerPos, v in ipairs(battleInitInfo.player_team) do
    Log.Dump(v, 3, "BattlePawnManager SetBattleInitInfo battleInitInfo " .. playerPos)
    local Team = BattleTeam(BattleEnum.Team.ENUM_TEAM, self.battleConfig)
    Team:InitWithData()
    local player = self:PawnBattlePlayer(BattleEnum.Team.ENUM_TEAM, Team, v, playerPos)
    if v.base and battleInitInfo.others then
      for i = 1, #battleInitInfo.others do
        local other = battleInitInfo.others[i]
        if other.role_uin == v.base.role_uin then
          player.deck:AdditionalInitByOthers(other.pets)
        end
      end
    end
    if player.isNeedLoad then
      tInsert(PrepareTable, player)
    end
    player.FirstPetPosInField = myPetPos
    if not player:IsRunAwayBattle() then
      local teammatePets = player.deck.cards
      for i = 1, #teammatePets do
        if teammatePets[i]:IsInBattle() then
          teammatePets[i].posInField = myPetPos + (teammatePets[i].pos <= 0 and 1 or teammatePets[i].pos)
          local pet = self:PawnPet(BattleEnum.Team.ENUM_TEAM, Team, teammatePets[i], player)
          if pet and pet.isNeedLoad then
            tInsert(PrepareTable, pet)
          else
            Team:RecallPet(pet)
          end
        end
      end
    end
    myPetPos = Team.capacity * playerPos
    tInsert(self.AllPlayerTeam, Team)
    if player:IsRealPlayer() then
      real_player = real_player + 1
      if real_player > 1 then
        _G.BattleManager.battleRuntimeData.is_online_multiplayer = true
      end
    end
  end
  self:InitTeamAndPlayer(BattleEnum.Team.ENUM_TEAM)
  local enemyPetPos = 0
  for playerPos, v in ipairs(battleInitInfo.enemy_team) do
    local Team = BattleTeam(BattleEnum.Team.ENUM_ENEMY, self.battleConfig)
    Team:InitWithData()
    local player
    if _G.BattleManager.battleRuntimeData.subBattleType ~= BattleEnum.SubBattleType.Single and 1 == #battleInitInfo.enemy_team then
      player = self:PawnBattlePlayer(BattleEnum.Team.ENUM_ENEMY, Team, v, _G.BattleManager.battleRuntimeData.enemyPetNumber)
    else
      player = self:PawnBattlePlayer(BattleEnum.Team.ENUM_ENEMY, Team, v, playerPos)
    end
    if player.isNeedLoad then
      tInsert(PrepareTable, player)
    end
    player.FirstPetPosInField = enemyPetPos
    if not player:IsRunAwayBattle() then
      local enemyPets = player.deck.cards
      for i = 1, #enemyPets do
        if enemyPets[i]:IsInBattle() then
          enemyPets[i].posInField = enemyPetPos + (enemyPets[i].pos <= 0 and 1 or enemyPets[i].pos)
          local pet = self:PawnPet(BattleEnum.Team.ENUM_ENEMY, Team, enemyPets[i], player)
          if pet and pet.isNeedLoad then
            tInsert(PrepareTable, pet)
          else
            Team:RecallPet(pet)
          end
        end
      end
    end
    enemyPetPos = Team.capacity * playerPos
    tInsert(self.AllEnemyTeam, Team)
  end
  self:InitTeamAndPlayer(BattleEnum.Team.ENUM_ENEMY)
  for _, team in ipairs(self.AllEnemyTeam) do
    team.npcid = self:GetTeamIdxByPlayer(team.player, BattleEnum.Team.ENUM_ENEMY) or nil
  end
  _G.BattleManager.battleInfoManager:HandleBattleInitInfo(battleInitInfo)
  return true
end

function BattlePawnManager:PreProcessTeamBattle(battleInitInfo)
  if not battleInitInfo.player_team or #battleInitInfo.player_team <= 1 then
    return
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local playerIndex = 0
  for i, v in ipairs(battleInitInfo.player_team) do
    v.teamNumber = i
    if v.base.role_uin == uin then
      playerIndex = i
    end
  end
  for i, v in ipairs(battleInitInfo.enemy_team) do
    v.teamNumber = i
  end
  if playerIndex > 0 then
    local playerData = battleInitInfo.player_team[playerIndex]
    table.remove(battleInitInfo.player_team, playerIndex)
    if BattleUtils.IsTeam() or BattleUtils.IsB1FinalBattleP3() then
      tInsert(battleInitInfo.player_team, 1, playerData)
    else
      tInsert(battleInitInfo.player_team, playerData)
    end
  end
end

function BattlePawnManager:PreProcessB1P3(battleInitInfo)
  if not BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if not battleInitInfo.player_team or #battleInitInfo.player_team <= 1 then
    return
  end
  local uin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local playerIndex = 0
  for i, v in ipairs(battleInitInfo.player_team) do
    if v.base.role_uin == uin then
      playerIndex = i
    end
  end
  if playerIndex > 0 then
    local playerData = battleInitInfo.player_team[playerIndex]
    table.remove(battleInitInfo.player_team, playerIndex)
    tInsert(battleInitInfo.player_team, 3, playerData)
  end
end

function BattlePawnManager:RefreshBattleFieldInReplayByEnter(initInfo)
  for _, v in ipairs(self.AllPlayerTeam) do
    for _, n in ipairs(initInfo.player_team) do
      if v.player.guid == n.base.role_uin then
        v:ReplaceByServer(n)
        break
      end
    end
  end
  for _, v in ipairs(self.AllEnemyTeam) do
    for _, n in ipairs(initInfo.enemy_team) do
      if v.player.guid == n.base.role_uin then
        v:ReplaceByServer(n)
        break
      end
    end
  end
end

function BattlePawnManager:RefreshBattleField(stateInfo)
  if not self.TeamatePlayer or not self.EnemyPlayer then
    Log.Error("zgx Battle has completed, could not refresh")
    return
  end
  if _G.EnableRoundStartNotify then
    for _, v in ipairs(self.AllPlayerTeam) do
      for _, n in ipairs(stateInfo.player_team) do
        if v.player.guid == n.base.role_uin then
          v:ReplaceByServer(n)
          break
        end
      end
    end
    for _, v in ipairs(self.AllEnemyTeam) do
      for _, n in ipairs(stateInfo.enemy_team) do
        if v.player.guid == n.base.role_uin then
          v:ReplaceByServer(n)
          break
        end
      end
    end
  else
  end
  local teamateFlag = false
  local enemyFlag = false
  local teamatePets = self.TeamatePlayer.deck.cards
  for _, pet in pairs(teamatePets) do
    if pet.bInBattleField and pet:GetHpPercent() <= 0.25 then
      teamateFlag = true
    end
  end
  local enemyPets = self.EnemyPlayer.deck.cards
  for _, pet in pairs(enemyPets) do
    if pet.bInBattleField and pet:GetHpPercent() <= 0.25 then
      enemyFlag = true
    end
  end
  if teamateFlag and enemyFlag then
    UE4.UAudioManager.SetGlobalRTPC("White_Hot", 100, "BattlePawnManager:RefreshBattleField", 0)
  else
    UE4.UAudioManager.SetGlobalRTPC("White_Hot", 0, "BattlePawnManager:RefreshBattleField", 0)
  end
  BattleBudget:PushTask(nil, function()
    _G.BattleEventCenter:Dispatch(BattleEvent.ROUND_START)
  end)
end

function BattlePawnManager:PawnBattlePlayer(teamEnm, Team, spawnData, posInField)
  local playerPos, modelConfig
  local player = BattlePlayer()
  player.teamEnm = teamEnm
  if spawnData.base then
    local roleInfo = spawnData.base
    local roleID = self:GetRoleId(spawnData, Team.teamEnm)
    local hasModel = 0 ~= roleID and 0 == (roleInfo.state_bit or 0) & 1 << ProtoEnum.BATTLER_BIT_TYPE.BT_BATTLER_RUNAWAY
    if hasModel then
      player.posInField = posInField
      playerPos = player:GetPosInField()
      modelConfig = _G.DataConfigManager:GetModelConf(roleID)
      if not playerPos or not modelConfig then
        hasModel = false
      end
    end
    if hasModel then
      if modelConfig.model_scale ~= nil and 0 ~= modelConfig.model_scale then
        player.modelScale = modelConfig.model_scale / 100.0
      else
        player.modelScale = 1.0
      end
      Log.Debug("player path : ", modelConfig.path, spawnData.base.role_uin, roleID)
      player.isNeedLoad = true
      if BattleUtils.IsDeepWater() then
        self.VBattleField:PawnWaterPlatform(teamEnm + 10, posInField, playerPos:Abs_K2_GetActorLocation(), false)
      end
      local req = _G.BattleResourceManager:LoadResAsyncWithParam(self, modelConfig.path, self.PawnBattlePlayerOver, self.PawnBattlePlayerFailed, playerPos:Abs_GetTransform(), player, modelConfig.path)
      self.requestDict[req] = {playerPos, player}
    else
      player.isNeedLoad = false
      player:SetLoadOver()
    end
    player:Spawn(spawnData, Team, spawnData.pets)
  else
    player.team = Team
    player.isNeedLoad = false
    player:SetLoadOver()
  end
  Team.player = player
  return player
end

function BattlePawnManager:GetRoleId(spawnData, teamEnm)
  if not spawnData then
    return 0
  end
  local roleID = BattleUtils.GetPlayerModelId(spawnData)
  if _G.EnableFakePVPRecord and teamEnm == BattleEnum.Team.ENUM_ENEMY then
    roleID = 1010002
  elseif BattleUtils.IsB1FinalBattleP3() and teamEnm == BattleEnum.Team.ENUM_TEAM then
    roleID = 0
  elseif BattleUtils.IsSpecialNoPc() and teamEnm == BattleEnum.Team.ENUM_TEAM and (not spawnData.base.npc_id or 0 == spawnData.base.npc_id) then
    roleID = 0
  end
  return roleID
end

function BattlePawnManager:PawnBattlePlayerOver(resClass, playerPos, player, resPath)
  local world = _G.UE4Helper.GetCurrentWorld()
  local bp_battlePlayer_C = world:Abs_SpawnActor(resClass, playerPos, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil)
  if nil == bp_battlePlayer_C or not bp_battlePlayer_C.BindBattlePlayer then
    Log.Error("zgx \230\136\152\230\150\151\232\167\146\232\137\178\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\129spawn player failed bp_battlePlayer_C is nil! or BindBattlePlayer function is nil!", player.guid, resPath)
    if resClass and resClass.__name then
      Log.Error("zgx \229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\231\154\132 NPC ID \228\184\186:", player.roleInfo.base.npc_id, "\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\231\154\132\230\136\152\230\150\151\232\167\146\232\137\178\231\177\187\229\144\141\230\152\175:", resClass.__name, "\232\175\183\230\163\128\230\159\165\230\136\152\230\150\151\233\133\141\231\189\174\230\152\175\229\144\166\230\173\163\231\161\174")
    end
    self.invalidRes[resPath] = true
    if not self.invalidRes[BattleConst.DefaultBattlePlayerPath] then
      _G.BattleResourceManager:LoadResAsyncWithParam(self, BattleConst.DefaultBattlePlayerPath, self.PawnBattlePlayerOver, self.PawnBattlePlayerFailed, playerPos, player, BattleConst.DefaultBattlePlayerPath)
    else
      _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_SPAWNED, nil)
    end
    return
  end
  bp_battlePlayer_C:InitOutSceneAsync(self, function()
    UE4.UNRCCharacterUtils.SetCharacterMeshScale(bp_battlePlayer_C, player.modelScale)
    bp_battlePlayer_C:SetInSignificance(false)
    bp_battlePlayer_C:BindBattlePlayer(player)
    bp_battlePlayer_C:BindAnimConf()
    if BattleUtils.IsDeepWater() then
      bp_battlePlayer_C.CharacterMovement:DisableMovement()
      bp_battlePlayer_C:EnableCanStandOnWaterSurface(true)
    else
      bp_battlePlayer_C.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Walking)
      bp_battlePlayer_C:EnableCanStandOnWaterSurface(false)
    end
    bp_battlePlayer_C:DisableFalling()
    bp_battlePlayer_C:K2_GetRootComponent():SetCollisionProfileName("NoCollision")
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Battle", bp_battlePlayer_C)
    local skeletalMeshComponent = bp_battlePlayer_C:GetComponentByClass(UE.USkeletalMeshComponent)
    if skeletalMeshComponent then
      skeletalMeshComponent.bEabledAuxiliaryAnimGraphThread = false
      skeletalMeshComponent:SetForcedLOD(BattleEnum.BattleLodModel.Lod0)
      if skeletalMeshComponent.SkeletalMesh then
        UE4.UNRCStatics.ForceUpdateStreamingAssets(skeletalMeshComponent.SkeletalMesh, 30)
      end
    end
    bp_battlePlayer_C.Mesh:SetForcedLOD(BattleEnum.BattleLodModel.Lod0)
    bp_battlePlayer_C:ForceHidden()
    bp_battlePlayer_C:SetLoadPriority(PriorityEnum.Passive_Battle_Players)
    bp_battlePlayer_C:ForceVisible()
    tInsert(self.unluaRef, UnLua.Ref(bp_battlePlayer_C))
    player:SetModel(bp_battlePlayer_C)
    player:PinOnTheGround()
    player.isNeedLoad = false
    player:LoadBPComponents()
    if self:IsLocalPlayer(player) and not BattleUtils.IsReplayMode() then
      player:CopyLocalPlayerAppearance()
      _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_LOAD_MODEL_OVER, player)
      self:PawnBattlePlayerOverAndSuited(player)
    else
      local setFashionResult = player:SetFashionSuit(self, function()
        self:PawnBattlePlayerOverAndSuited(player)
      end)
      _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_LOAD_MODEL_OVER, player)
      if not setFashionResult then
        self:PawnBattlePlayerOverAndSuited(player)
      else
        player:SetLoadOver()
      end
    end
  end)
  bp_battlePlayer_C:DisableFalling()
  bp_battlePlayer_C:SetForceHidden(true)
end

function BattlePawnManager:PawnBattlePlayerOverAndSuited(player)
  _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_SPAWNED, player)
  player:SetLoadOver()
  local lmotion = player.model.RocoAnim:GetAnimInstance("Locomotion")
  if lmotion then
    lmotion.IsInBattle = true
  end
end

function BattlePawnManager:PawnBattlePlayerFailed(req)
  self.invalidRes[req.request.assetPath] = true
  Log.Error("\229\136\155\229\187\186PawnBattlePlayerFailed\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\129\239\188\154", req)
  local param = self.requestDict[req]
  local resPath = "Blueprint'/Game/NewRoco/Modules/Core/Battle/Player/C001_0001/BP_Battle_C001_0001.BP_Battle_C001_0001_C'"
  if not self.invalidRes[resPath] then
    _G.BattleResourceManager:LoadResAsyncWithParam(self, resPath, self.PawnBattlePlayerOver, self.PawnBattlePlayerFailed, param[1], param[2], resPath)
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.PLAYER_SPAWNED, nil)
  end
end

function BattlePawnManager:PawnPet(teamEnm, Team, card, player, isInited, ForcePawn, isTransient)
  local pos = card.pos <= 0 and 1 or card.pos
  local params = {}
  params.index = pos
  params.team = Team
  params.player = player
  params.inBattle = true
  if not self.VBattleField then
    Log.Error("BattlePawnManager:PawnPet \230\136\152\229\156\186\230\156\170\229\136\157\229\167\139\229\140\150", self.battleConfig.id)
    return
  end
  local pet = BattlePet()
  if ForcePawn or card:GetHp() > 0 and not card:IsBeCatch() then
    pet.isNeedLoad = true
    Log.Debug("BattlePawnManager load actor:", card.name, card.posInField, card.resourcePath)
    local petTransform, willMove = self.VBattleField:GetPetBornPosition(teamEnm, card.posInField or 1, card, _G.BattleManager.PrepareOver)
    if not petTransform then
      Log.Error("BattlePawnManager:PawnPet petTransform is nil", self.battleConfig.id, card.posInField or 1)
      return
    end
    card:SetWillMove(willMove or false)
    local petPos = UE4.FVector(petTransform.Translation.X, petTransform.Translation.Y, petTransform.Translation.Z)
    local modelPath = card.resourcePath
    local isMimic, MimicType, buffInfo = card:CheckIsMimic()
    if isMimic then
      if MimicType == ProtoEnum.BuffGroupSign.BGS_MIMIC then
        local mimicId = card.petBaseConf and card.petBaseConf.mimic_target
        if mimicId then
          local modelConf = _G.DataConfigManager:GetModelConf(mimicId)
          if modelConf then
            card:RefreshName(card.petInfo)
            card:RefreshResource()
            modelPath = UEPath.BP_BattleMimic
            card.mimicResourcePath = modelConf.path
          end
        end
      elseif MimicType == ProtoEnum.BuffGroupSign.BGS_BATTLE_MIMIC then
        buffInfo = buffInfo or card:GetBuffInfoByGroupSign(MimicType)
        if buffInfo and buffInfo.buff_data then
          local mimicPetId = buffInfo.buff_data[1]
          local petConf = _G.DataConfigManager:GetPetConf(mimicPetId or 0, true)
          if petConf then
            card:RefreshByBaseConf(petConf.base_id)
            modelPath = card.resourcePath
          end
        end
      end
    end
    if BattleUtils.IsDeepWater() then
      local platformPos = petPos
      if willMove then
        local FinalPetTransform = self.VBattleField:GetPetBornPosition(teamEnm, card.posInField or 1, card, true)
        platformPos = UE4.FVector(FinalPetTransform.Translation.X, FinalPetTransform.Translation.Y, FinalPetTransform.Translation.Z)
      end
      self.VBattleField:PawnWaterPlatform(teamEnm, card.posInField or 1, platformPos)
      pet:SetPlatFormPos(platformPos)
    end
    pet.CachePetBaseId = card.petBaseConf and card.petBaseConf.id or 0
    Log.Debug("BattleResourceManager:LoadActorAsyncWithParam:", modelPath, petPos)
    local req = _G.BattleResourceManager:LoadActorAsyncWithParam(self, modelPath, petTransform, PriorityEnum.Passive_Battle_Pets, params, self.PawnPetOver, self.PawnPetFailed, pet, player, card, petPos, isTransient)
    self.requestDict[req] = {
      petTransform,
      params,
      pet,
      player,
      card,
      petPos
    }
  else
    pet.isNeedLoad = false
    pet:SetModel(nil)
    pet.dead = true
  end
  pet:Spawn(card.guid, card, params)
  if Team.pets[pos] then
    table.insert(self.ReplaceAllBattlePets, Team.pets[pos])
  end
  Team.pets[pos] = pet
  Log.DebugFormat("Pawn Pet @ Index %d", pos)
  pet.CardIndex = card.CardIndex
  return pet
end

local function SpawnBattleNpcListTask(self, battleOnLookerList, onLookerDataList)
  local battleConfig = BattleUtils.GetBattleConfig()
  local npc_round_scale = (tonumber(battleConfig and battleConfig.npc_round_scale) or 100) / 100
  local npc_round_tip_scale = (tonumber(battleConfig and battleConfig.npc_round_tip_scale) or 100) / 100
  for i, data in ipairs(onLookerDataList) do
    local attachPoint = data.attachPoint
    if data.type == BattlePawnManager.BattleOnLookerType.Npc then
      local npcData = data.npcData
      if npcData.type == BattleNpc.Type.SingleOnLooker then
        local npcOnLookerInfo = npcData.npcInfo
        local battleNpc = BattleNpc(BattleNpc.Type.SingleOnLooker)
        tInsert(battleOnLookerList, battleNpc)
        battleNpc:SetBattleOnLookerInfo(npcOnLookerInfo, attachPoint, npc_round_scale, npc_round_tip_scale)
        local aBattleNpcInit = a.wrap(battleNpc.Init)
        local ok, errorOrTaskOk, errorOrMessage = a.wait(aBattleNpcInit(battleNpc))
        if ok and errorOrTaskOk then
          tInsert(self.unluaRef, UnLua.Ref(battleNpc.model))
          battleNpc:TurnToBattleFieldCenter()
          battleNpc:ShowNpcWithFadeAndAnim()
        else
          if not ok then
            Log.Error("BattlePawnManager:SpawnBattleNpc", i, errorOrTaskOk)
          elseif not errorOrTaskOk then
            Log.Error("BattlePawnManager:SpawnBattleNpc", i, errorOrMessage)
          end
          self:RemoveBattleNpc(battleNpc)
          battleNpc:Destroy()
        end
      elseif npcData.type == BattleNpc.Type.CrowdOnLooker then
        local crowdInfo = npcData.crowdInfo
        local npcModel = crowdInfo and crowdInfo.crowdNpcModel
        local battleNpc = BattleNpc(BattleNpc.Type.CrowdOnLooker)
        tInsert(battleOnLookerList, battleNpc)
        do
          local scale = BattleConst.BattleCrowdNpc.ActorScale
          local EmotionCaster = npcModel.EmotionCaster
          local emotionCaster = EmotionCaster and EmotionCaster:GetChildActor()
          if UE4.UObject.IsValid(emotionCaster) then
            emotionCaster:SetActorScale3D(UE4.FVector(scale, scale, scale))
          end
        end
        battleNpc:SetBattleCrowdOnLookerInfo(crowdInfo, 1)
        local aBattleNpcInit = a.wrap(battleNpc.Init)
        local result1, result2, result3 = a.wait(aBattleNpcInit(battleNpc))
        local ok = false
        local errorMessage = ""
        if not result1 then
          ok = false
          errorMessage = result2
        elseif not result2 then
          ok = false
          errorMessage = result3
        else
          ok = true
        end
        if ok then
          tInsert(self.unluaRef, UnLua.Ref(battleNpc.model))
        else
          Log.Error("BattlePawnManager:SpawnBattleNpc crowd npc error", errorMessage)
          self:RemoveBattleNpc(battleNpc)
          battleNpc:Destroy()
        end
      end
    elseif data.type == BattlePawnManager.BattleOnLookerType.PlayerInspector then
      local inspectorData = data.playerInspectorData
      local fashionInfo = inspectorData and inspectorData.fashionInfo
      local uin = inspectorData and inspectorData.uin or 0
      local battlePlayerInspector = BattlePlayerInspector()
      tInsert(battleOnLookerList, battlePlayerInspector)
      battlePlayerInspector:SetInfo(uin, fashionInfo, attachPoint)
      local aBattleNpcInit = a.wrap(battlePlayerInspector.Init)
      local ok, errorOrTaskOk, errorOrMessage = a.wait(aBattleNpcInit(battlePlayerInspector))
      if ok and errorOrTaskOk then
        tInsert(self.unluaRef, UnLua.Ref(battlePlayerInspector.model))
        battlePlayerInspector:TurnToBattleFieldCenter()
        battlePlayerInspector:ShowNpcWithFadeAndAnim()
      else
        if not ok then
          Log.Error("BattlePawnManager:SpawnBattlePlayerInspector", i, errorOrTaskOk)
        elseif not errorOrTaskOk then
          Log.Error("BattlePawnManager:SpawnBattlePlayerInspector", i, errorOrMessage)
        end
        self:RemoveBattleNpc(battlePlayerInspector)
        battlePlayerInspector:Destroy()
      end
    end
  end
end

function BattlePawnManager:SpawnBattleNpcList(battleOnLookerListA, battleOnLookerListB, crowdNpcModelList, fashionInfoList, callback)
  _G.BattleManager.battleRuntimeData.battleOnLookerInfo.onLookersSpawnExecuted = true
  local onLookerDataList = self:GetBattleOnLookerDataList(battleOnLookerListA, battleOnLookerListB, crowdNpcModelList, fashionInfoList, {})
  self:SetBattleOnLookerData(onLookerDataList)
end

function BattlePawnManager:GetBattleOnLookerDataList(battleOnLookerListA, battleOnLookerListB, crowdNpcModelList, fashionInfoList)
  local onLookerDataList = {}
  for i, battleOnLooker in ipairs(battleOnLookerListA) do
    local attachPoint = BattleNpc.IndexToAttachPointEnumA[i]
    local npcData = {
      type = BattleNpc.Type.SingleOnLooker,
      npcInfo = battleOnLooker
    }
    local onLookerData = {
      type = BattlePawnManager.BattleOnLookerType.Npc,
      npcData = npcData,
      attachPoint = attachPoint
    }
    table.insert(onLookerDataList, onLookerData)
  end
  for i, battleOnLooker in ipairs(battleOnLookerListB) do
    local attachPoint = BattleNpc.IndexToAttachPointEnumB[i]
    local npcData = {
      type = BattleNpc.Type.SingleOnLooker,
      npcInfo = battleOnLooker
    }
    local onLookerData = {
      type = BattlePawnManager.BattleOnLookerType.Npc,
      npcData = npcData,
      attachPoint = attachPoint
    }
    table.insert(onLookerDataList, onLookerData)
  end
  for i, fashionInfo in ipairs(fashionInfoList) do
    local attachPoint = BattleNpc.IndexToAttachPointEnumA[fashionInfo.pos]
    local uin = fashionInfo and fashionInfo.uin or 0
    local inspectorData = {uin = uin, fashionInfo = fashionInfo}
    local onLookerData = {
      type = BattlePawnManager.BattleOnLookerType.PlayerInspector,
      playerInspectorData = inspectorData,
      attachPoint = attachPoint
    }
    local targetIndex = -1
    for j, data in ipairs(onLookerDataList) do
      if data.attachPoint == onLookerData.attachPoint then
        targetIndex = j
        break
      end
    end
    if -1 == targetIndex then
      table.insert(onLookerDataList, onLookerData)
    else
      onLookerDataList[targetIndex] = onLookerData
    end
  end
  for i, model in ipairs(crowdNpcModelList) do
    local crowdInfo = {
      id = 2000 + i,
      crowdNpcModel = model
    }
    local npcData = {
      type = BattleNpc.Type.CrowdOnLooker,
      crowdInfo = crowdInfo
    }
    local onLookerData = {
      type = BattlePawnManager.BattleOnLookerType.Npc,
      npcData = npcData
    }
    table.insert(onLookerDataList, onLookerData)
  end
  return onLookerDataList
end

function BattlePawnManager:SetBattlePlayerInspectorData(fashionInfoList)
  local initInfo = BattleUtils.GetBattleInitInfo()
  local battleOnLookerListA = initInfo and initInfo.onlooker_a or {}
  local battleOnLookerListB = initInfo and initInfo.onlooker_b or {}
  local onLookerDataList = self:GetBattleOnLookerDataList(battleOnLookerListA, battleOnLookerListB, {}, fashionInfoList)
  self:SetBattleOnLookerData(onLookerDataList)
end

function BattlePawnManager:SetBattleOnLookerData(nextDataList)
  self.battleOnLookerDataList = nextDataList
  self:RefreshBattleOnLookerData()
end

function BattlePawnManager:RefreshBattleOnLookerData()
  if self.battleOnLookerDataListDisplay == self.battleOnLookerDataList then
    return
  end
  if self.battleOnLookerDisplayIsRefreshing then
    Log.Info("BattlePawnManager:RefreshBattleOnLookerData \229\155\180\232\167\130\232\128\133\230\184\178\230\159\147\230\173\163\229\156\168\230\155\180\230\150\176\239\188\140\230\154\130\228\184\141\230\137\167\232\161\140\230\149\176\230\141\174\230\155\180\230\150\176")
    return
  end
  local prevDataList = self.battleOnLookerDataListDisplay or {}
  local nextDataList = self.battleOnLookerDataList or {}
  local nextDataMap = {}
  local prevDataMap = {}
  for i, data in ipairs(nextDataList) do
    local id = self:GetBattleOnLookerId(data)
    nextDataMap[id] = data
  end
  for i, data in ipairs(prevDataList) do
    local id = self:GetBattleOnLookerId(data)
    prevDataMap[id] = data
  end
  local dataListToAdd = {}
  local dataListToRemove = {}
  local dataListToUpdate = {}
  for id, data in pairs(nextDataMap) do
    if prevDataMap[id] then
      table.insert(dataListToUpdate, data)
    else
      table.insert(dataListToAdd, data)
    end
  end
  for id, data in pairs(prevDataMap) do
    if not nextDataMap[id] then
      table.insert(dataListToRemove, data)
    end
  end
  self.battleOnLookerDataListDisplay = nextDataList
  local shouldUpdate = false
  if #dataListToAdd > 0 or #dataListToRemove > 0 then
    shouldUpdate = true
  end
  if not shouldUpdate then
    return
  end
  self.battleOnLookerDisplayIsRefreshing = true
  self:RefreshBattleOnLookerDisplay(dataListToAdd, dataListToRemove, dataListToUpdate, function(ok, errorMessage)
    if not ok then
      Log.Error("BattlePawnManager:RefreshBattleOnLookerData SpawnBattleOnLookerList error", errorMessage)
    end
    self.battleOnLookerDisplayIsRefreshing = false
    self:RefreshBattleOnLookerData()
  end)
end

function BattlePawnManager:GetBattleOnLookerId(data)
  local id
  if data.type == BattlePawnManager.BattleOnLookerType.Npc then
    local npcData = data.npcData
    local info = npcData and npcData.npcInfo
    local crowdInfo = npcData and npcData.crowdInfo
    if info then
      id = info.id
    end
    if crowdInfo then
      id = crowdInfo.id
    end
  elseif data.type == BattlePawnManager.BattleOnLookerType.PlayerInspector then
    local playerInspectorData = data.playerInspectorData
    id = playerInspectorData and playerInspectorData.uin
  end
  return id
end

function BattlePawnManager:RefreshBattleOnLookerDisplay(dataListToAdd, dataListToRemove, dataListToUpdate, callback)
  local idToBattleOnLooker = {}
  local battleOnLookerList = self.battleNpcList or {}
  for i, npc in ipairs(battleOnLookerList) do
    local id = npc:GetId()
    if id then
      idToBattleOnLooker[id] = npc
    end
  end
  for i, data in ipairs(dataListToRemove) do
    local id = self:GetBattleOnLookerId(data)
    if id then
      local onLooker = idToBattleOnLooker[id]
      if onLooker then
        onLooker:ModelFadeOut(function(ok, errorMessage)
          if ok then
            onLooker:Destroy()
          else
            Log.Error(errorMessage)
          end
        end)
      end
      idToBattleOnLooker[id] = nil
    end
  end
  local nextBattleOnLookerList = {}
  for i, data in ipairs(dataListToUpdate) do
    local id = self:GetBattleOnLookerId(data)
    if id then
      local onLooker = idToBattleOnLooker[id]
      table.insert(nextBattleOnLookerList, onLooker)
    end
  end
  self.battleNpcList = nextBattleOnLookerList
  if #dataListToAdd > 0 then
    local battleOnLookerInfo = _G.BattleManager.battleRuntimeData.battleOnLookerInfo
    local task = a.sync(SpawnBattleNpcListTask)
    battleOnLookerInfo.spawnBattleOnLookerAsyncContext = au.Launch(task(self, self.battleNpcList, dataListToAdd), callback)
  else
    self:TryCancelRefreshBattleOnLookCallbackDelayId()
    local refreshBattleOnLookCallbackDelayId = _G.DelayManager:DelayFrames(1, function()
      self.refreshBattleOnLookCallbackDelayId = nil
      tcall(nil, callback, true)
    end)
    self.refreshBattleOnLookCallbackDelayId = refreshBattleOnLookCallbackDelayId
  end
end

function BattlePawnManager:RemoveBattleNpc(targetNpc)
  for i = #self.battleNpcList, 1, -1 do
    if self.battleNpcList[i] == targetNpc then
      table.remove(self.battleNpcList, i)
    end
  end
end

function BattlePawnManager:MimicOutSceneComplete(model)
  local parent = model:GetParentActor()
  if parent then
    self:InitOutSceneComplete(parent)
  else
    Log.Error("zgx mimic no parent")
  end
end

function BattlePawnManager:InitOutSceneComplete(model)
  if self.loadingArgs[model] and UE4.UObject.IsValid(model) then
    local args = self.loadingArgs[model]
    local model = args.tmodel
    local pet = args.tpet
    local card = args.tcard
    local isTransient = args.tisTransient
    if not isTransient then
      if card.petInfo and not card:CheckIsMimic() then
        local mutationPetData = PetMutationUtils.GetDisplayMutationData(card)
        PetMutationUtils.DoMutation(model, mutationPetData)
      elseif card:CheckIsMimic() and model.ChangeXray then
        model:ChangeXray(false)
      end
    end
    model:SetInSignificance(false)
    if model.RibbonState then
      model.RibbonState = UE.ENPCRibbonState.Close
    end
    local Mesh = model.Mesh or model:GetComponentByClass(UE4.USkeletalMeshComponent)
    if Mesh then
      local relativeLocation = Mesh:GetRelativeTransform().Translation
      if BattleUtils.IsBloodTeam() and pet.teamEnm == BattleEnum.Team.ENUM_ENEMY then
        card.resourceScale = BattleUtils.GetBloodTeamPetScale(card.petInfo.battle_common_pet_info.height + math.abs(relativeLocation.z))
      end
      Log.Debug("BattlePawnManager:InitOutSceneComplete", pet.card.name, math.abs(relativeLocation.z))
      Mesh:SetForcedLOD(BattleEnum.BattleLodModel.Lod0)
      if Mesh.CullDistanceForAdditionalMaterial then
        Mesh.CullDistanceForAdditionalMaterial.Default = 9999999
      end
      Mesh.bUseAttachParentBound = false
      Mesh.bNRCUseFixedSkelBounds = false
      if Mesh.SkeletalMesh then
        UE4.UNRCStatics.ForceUpdateStreamingAssets(Mesh.SkeletalMesh, 30)
      end
    end
    if model:IsA(UE.ARocoCharacter) then
      if card.petState:GetNightmare() then
        model:SetExpression(22)
        model:SetIKEnable(true)
        local pos = model:K2_GetActorLocation()
        pet.CacheNormalPos = UE4.UNRCStatics.PinActorOnGround(nil, model, pos, model)
        local nightmare_elite_id = card.petInfo.battle_inside_pet_info.nightmare_elite_id
        if nightmare_elite_id then
          local Conf = _G.DataConfigManager:GetNightmareEliteConf(nightmare_elite_id, true)
          if Conf then
            local heightModelScale = (Conf.model_scale or 100) / 100 * card.resourceScale
            UE.UNRCCharacterUtils.SetCharacterMeshScale(model, heightModelScale)
          end
        end
      else
        UE.UNRCCharacterUtils.SetCharacterMeshScale(model, card.resourceScale)
      end
    end
    if model.InitHeadLookAt then
      model.EnableHeadLookAt = true
      model:InitHeadLookAt()
    end
    pet:SetModel(model)
    pet:SetOutLineMaterial()
    pet:UpdateLocalRoundPerformInfo()
    pet:LoadOther()
    pet:ProcessMimic()
    pet.InitRotator = model:K2_GetActorRotation()
    pet.buffComponent:TriggerStateOnPawn()
    pet:SetIKEnable(true)
    local skinMeshComp = model:GetComponentByClass(UE.USkinnedMeshComponent)
    if skinMeshComp then
      skinMeshComp.VisibilityBasedAnimTickOption = UE.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    end
    local skeletalMeshComponent = model:GetComponentByClass(UE.USkeletalMeshComponent)
    if skeletalMeshComponent then
      skeletalMeshComponent.bEabledAuxiliaryAnimGraphThread = false
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.PET_LOAD_MODE_LOVER, pet)
    self.loadingArgs[model] = nil
  else
    Log.Error("\229\183\178\229\138\160\232\189\189\230\168\161\229\158\139\231\188\186\228\185\143\228\188\160\229\143\130\239\188\129\239\188\129\230\151\160\230\179\149\232\191\155\232\161\140\230\156\137\230\149\136\229\136\157\229\167\139\229\140\150:", model)
  end
end

function BattlePawnManager:PawnPetOver(model, pet, player, card, initPos, isTransient)
  if not model then
    Log.Error("pet model create fail")
    return
  end
  tInsert(self.unluaRef, UnLua.Ref(model))
  _G.NRCAudioManager:SetAttenuationScalingFactor(model, 10)
  model.inBattle = true
  self.loadingArgs[model] = {
    tmodel = model,
    tpet = pet,
    tplayer = player,
    tcard = card,
    tinitPos = initPos,
    tisTransient = isTransient,
    isHidden = model.bHidden
  }
  if card.mimicResourcePath then
    local req = _G.BattleResourceManager:LoadResAsyncWithParam(self, card.mimicResourcePath, self.PawnMimicActorOver, self.PawnMimicActorFail, model)
    self.requestDict[req] = {model}
  else
    model:SetLoadPriority(PriorityEnum.Passive_Battle_Pets)
    local mutationPetData = PetMutationUtils.GetDisplayMutationData(card)
    PetMutationUtils.PrepareMutationAssets(model, mutationPetData)
    model:InitOutSceneAsync(self, self.InitOutSceneComplete)
  end
  model:SetActorHiddenInGame(true)
end

function BattlePawnManager:PawnPetFailed(req)
  self.invalidRes[req.request.assetPath] = true
  Log.Error("PawnPet\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\129")
  local param = self.requestDict[req]
  local resPath = BattleConst.YajijiPath
  if not self.invalidRes[resPath] then
    _G.BattleResourceManager:LoadActorAsyncWithParam(self, resPath, param[1], PriorityEnum.Passive_Battle_Pets, param[2], self.PawnPetOver, self.PawnPetFailed, param[3], param[4], param[5], param[6])
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.PET_LOAD_MODE_LOVER, nil)
  end
end

function BattlePawnManager:PawnMimicActorOver(resClass, pet)
  local childActor = pet.MimicActor
  if not childActor then
    childActor = pet:GetComponentByClass(UE.UNRCChildActorComponent)
    pet.MimicActor = childActor
  end
  if childActor then
    pet:SetActorNeedTick(true)
    childActor:SetChildActorClass(resClass)
    local mimic = childActor:GetChildActor()
    if mimic then
      mimic:SetLoadPriority(PriorityEnum.Passive_Battle_Mimic)
      mimic:InitOutSceneAsync(self, self.MimicOutSceneComplete)
    else
      Log.Error("zgx there is no ChildActor")
      pet:SetLoadPriority(PriorityEnum.Passive_Battle_Pets)
      pet:InitOutSceneAsync(self, self.InitOutSceneComplete)
      self:InitOutSceneComplete(pet)
    end
  else
    Log.Error("zgx there is no UNRCChildActorComponent")
    pet:SetLoadPriority(PriorityEnum.Passive_Battle_Pets)
    pet:InitOutSceneAsync(self, self.InitOutSceneComplete)
    self:InitOutSceneComplete(pet)
  end
end

function BattlePawnManager:PawnMimicActorFail(req)
  self.invalidRes[req.request.assetPath] = true
  Log.Error("zgx \229\136\155\229\187\186\229\140\191\232\184\170actor\229\164\177\232\180\165\239\188\129\239\188\129\239\188\129\239\188\129")
  local param = self.requestDict[req]
  local mimicResourcePath = ""
  if not self.invalidRes[mimicResourcePath] then
    _G.BattleResourceManager:LoadResAsyncWithParam(self, mimicResourcePath, self.PawnMimicActorOver, self.PawnMimicActorFail, param[1])
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.PET_LOAD_MODE_LOVER, nil)
  end
end

function BattlePawnManager:RecallBattlePet(team, pet)
  team:RecallPet(pet)
end

function BattlePawnManager:SummonBattlePet(teamEnm, Team, petInfos, cards)
  local team = Team
  local newPets = {}
  for i = 1, #cards do
    cards[i].pos = petInfos[i].pet_pos
    local pet = self:PawnPet(teamEnm, Team, cards[i], team.player, nil, nil, petInfos[i].isTransient)
    if pet then
      tInsert(newPets, pet)
    end
  end
  return newPets
end

function BattlePawnManager:SetTeam(teamEnm, team)
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    self.playerTeam = team
  else
    self.enemyTeam = team
  end
end

function BattlePawnManager:GetTeam(teamEnm)
  local team
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    team = self.playerTeam
  else
    team = self.enemyTeam
  end
  return team
end

function BattlePawnManager:SetTeamPlayer(teamEnm, battlePlayer)
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    self.TeamatePlayer = battlePlayer
  else
    self.EnemyPlayer = battlePlayer
  end
end

function BattlePawnManager:GetTeamPlayer(teamEnm)
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    return self.TeamatePlayer
  else
    return self.EnemyPlayer
  end
end

function BattlePawnManager:InitTeamAndPlayer(teamEnm)
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    local initInfo = BattleUtils.GetBattleInitInfo()
    local battlerUin = initInfo and initInfo.battler_uin
    local playerTeamPlayer = self:GetBattlePlayerByUin(battlerUin)
    if not playerTeamPlayer then
      local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo()
      local briefInfo = playerInfo and playerInfo.brief_info
      local playerUin = briefInfo and briefInfo.uin
      playerTeamPlayer = self:GetBattlePlayerByUin(playerUin)
    end
    if not playerTeamPlayer then
      local allTeamPlayer = {}
      local allTeamPlayerWithoutRunAway = {}
      local allPlayerTeam = self.AllPlayerTeam or {}
      for i, team in ipairs(allPlayerTeam) do
        local battlePlayer = team and team.player
        if battlePlayer then
          if not battlePlayer:IsRunAwayBattle() then
            table.insert(allTeamPlayerWithoutRunAway, battlePlayer)
          end
          table.insert(allTeamPlayer, battlePlayer)
        end
      end
      playerTeamPlayer = allTeamPlayerWithoutRunAway and allTeamPlayerWithoutRunAway[1]
      playerTeamPlayer = playerTeamPlayer or allTeamPlayer and allTeamPlayer[1]
    end
    local playerTeam = playerTeamPlayer and playerTeamPlayer.team
    self:SetTeamPlayer(BattleEnum.Team.ENUM_TEAM, playerTeamPlayer)
    self:SetTeam(BattleEnum.Team.ENUM_TEAM, playerTeam)
  end
  if teamEnm == BattleEnum.Team.ENUM_ENEMY then
    local enemyTeamPlayer
    if not enemyTeamPlayer then
      local allEnemyPlayer = {}
      local allEnemyPlayerWithoutRunAway = {}
      local allEnemyTeam = self.AllEnemyTeam or {}
      for i, team in ipairs(allEnemyTeam) do
        local battlePlayer = team and team.player
        if battlePlayer then
          if not battlePlayer:IsRunAwayBattle() then
            table.insert(allEnemyPlayerWithoutRunAway, battlePlayer)
          end
          table.insert(allEnemyPlayer, battlePlayer)
        end
      end
      enemyTeamPlayer = allEnemyPlayerWithoutRunAway and allEnemyPlayerWithoutRunAway[1]
      enemyTeamPlayer = enemyTeamPlayer or allEnemyPlayer and allEnemyPlayer[1]
    end
    local enemyTeam = enemyTeamPlayer and enemyTeamPlayer.team
    self:SetTeamPlayer(BattleEnum.Team.ENUM_ENEMY, enemyTeamPlayer)
    self:SetTeam(BattleEnum.Team.ENUM_ENEMY, enemyTeam)
  end
end

function BattlePawnManager:GetBattlePlayerByUin(player_uin)
  local allPlayerTeam = self.AllPlayerTeam or {}
  local battlerUinPlayer
  for i, team in ipairs(allPlayerTeam) do
    local battlePlayer = team and team.player
    local roleInfo = battlePlayer and battlePlayer.roleInfo
    local baseInfo = roleInfo and roleInfo.base
    local playerUin = baseInfo and baseInfo.role_uin
    if player_uin and player_uin == playerUin then
      battlerUinPlayer = battlePlayer
      break
    end
  end
  return battlerUinPlayer
end

function BattlePawnManager:GetEnemyTeam(teamEnm)
  local team
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    team = self.enemyTeam
  else
    team = self.playerTeam
  end
  return team
end

function BattlePawnManager:GetBattleTeam(battlePlayer)
  if not battlePlayer then
    return nil
  end
  for i = 1, #self.AllPlayerTeam do
    local playerTeam = self.AllPlayerTeam[i]
    if playerTeam.player == battlePlayer then
      return playerTeam
    end
  end
  for i = 1, #self.AllEnemyTeam do
    local playerTeam = self.AllEnemyTeam[i]
    if playerTeam.player == battlePlayer then
      return playerTeam
    end
  end
  return nil
end

function BattlePawnManager:GetAllTeam(teamEnm)
  local team
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    team = self.AllPlayerTeam
  else
    team = self.AllEnemyTeam
  end
  return team
end

function BattlePawnManager:GetAllEnemyTeam(teamEnm)
  local team
  if teamEnm == BattleEnum.Team.ENUM_TEAM then
    team = self.AllEnemyTeam
  else
    team = self.AllPlayerTeam
  end
  return team
end

function BattlePawnManager:GetInFieldPet(teamEnum)
  local Team = self:GetTeam(teamEnum)
  if Team then
    local Pets = Team.pets
    if Pets then
      for _, Pet in pairs(Pets) do
        if Pet:GetCard():IsInBattle() then
          return Pet
        end
      end
    end
  end
  return nil
end

function BattlePawnManager:GetCheerPets(battlePet)
  local fieldPets = {}
  if battlePet and not battlePet.card:IsCheerPet() then
    local CheerCards = battlePet.card:GetCheerPets()
    local Pets = battlePet.player.team.pets
    for _, Pet in pairs(Pets) do
      for _, Cheer in ipairs(CheerCards) do
        if Pet.card == Cheer then
          tInsert(fieldPets, Pet)
        end
      end
    end
  end
  return fieldPets
end

function BattlePawnManager:GetEnemyAllCheerPets()
  local fieldPets = {}
  local EnemyPets = self:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  for _, enemy in ipairs(EnemyPets) do
    if enemy.card:IsCheerPet() then
      tInsert(fieldPets, enemy)
    end
  end
  return fieldPets
end

function BattlePawnManager:GetCanSelectPetsByPlayer(player)
  local fieldPets = {}
  local Pets = player and player.team.pets or {}
  for _, Pet in pairs(Pets) do
    if Pet:GetCard():IsCanSelect() then
      tInsert(fieldPets, Pet)
    end
  end
  return fieldPets
end

function BattlePawnManager:GetCanSelectAllPet(teamEnum, onlyFirst, isNoFilter)
  local Teams
  if onlyFirst then
    if teamEnum == BattleEnum.Team.ENUM_TEAM then
      Teams = {
        self.playerTeam
      }
    elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
      Teams = {
        self.enemyTeam
      }
    else
      Log.Error("BattlePawnManager: Get wrong team type", teamEnum)
      return nil
    end
  else
    Teams = self:GetAllTeam(teamEnum)
    Teams = Teams or {}
  end
  local fieldPets = {}
  for _, Team in ipairs(Teams) do
    local Pets = Team.pets
    for _, Pet in pairs(Pets) do
      if isNoFilter or Pet:GetCard():IsCanSelect() then
        tInsert(fieldPets, Pet)
      end
    end
  end
  return fieldPets
end

function BattlePawnManager:GetInFieldAllPetByServer(teamEnum, onlyFirst, isNoFilter)
  local Teams
  if onlyFirst then
    if teamEnum == BattleEnum.Team.ENUM_TEAM then
      Teams = {
        self.playerTeam
      }
    elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
      Teams = {
        self.enemyTeam
      }
    else
      Log.Error("BattlePawnManager: Get wrong team type", teamEnum)
      return nil
    end
  else
    Teams = self:GetAllTeam(teamEnum)
    Teams = Teams or {}
  end
  local fieldPets = {}
  for _, Team in ipairs(Teams) do
    local Pets = Team.pets
    for _, Pet in pairs(Pets) do
      if isNoFilter or Pet:GetCard():IsInBattle() then
        tInsert(fieldPets, Pet)
      end
    end
  end
  return fieldPets
end

function BattlePawnManager:GetInFieldAllPet(teamEnum, onlyFirst, isNoFilter)
  local Teams
  if onlyFirst then
    if teamEnum == BattleEnum.Team.ENUM_TEAM then
      Teams = {
        self.playerTeam
      }
    elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
      Teams = {
        self.enemyTeam
      }
    else
      Log.Error("BattlePawnManager: Get wrong team type", teamEnum)
      return nil
    end
  else
    Teams = self:GetAllTeam(teamEnum)
    Teams = Teams or {}
  end
  local fieldPets = {}
  for _, Team in ipairs(Teams) do
    local Pets = Team.pets
    for _, Pet in pairs(Pets) do
      if Pet then
        if isNoFilter or Pet:GetCard():IsExistAtField() then
          tInsert(fieldPets, Pet)
        end
      else
        Log.Warning("BattlePawnManager:GetInFieldAllPet Pet is nil")
      end
    end
  end
  return fieldPets
end

function BattlePawnManager:GetInFieldAllPlayers()
  local lst = {}
  if self.AllPlayerTeam then
    for i = 1, #self.AllPlayerTeam do
      local playerTeam = self.AllPlayerTeam[i]
      tInsert(lst, playerTeam.player)
    end
  end
  if self.AllEnemyTeam then
    for i = 1, #self.AllEnemyTeam do
      local enemyTeam = self.AllEnemyTeam[i]
      tInsert(lst, enemyTeam.player)
    end
  end
  return lst
end

function BattlePawnManager:GetPlayerMyTeam()
  if self.playerTeam then
    return self.playerTeam.player
  else
    Log.Error("\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
  end
end

function BattlePawnManager:GetPlayerEnemyTeam()
  if self.enemyTeam then
    return self.enemyTeam.player
  else
    Log.Error("Data get error, please find reason")
  end
end

function BattlePawnManager:GetPlayerByGuid(playerGuid)
  if not self:IsValid() then
    return
  end
  local player
  for _, v in ipairs(self.AllPlayerTeam) do
    if v then
      player = v:GetPlayerByGuid(playerGuid)
      if player then
        return player
      end
    end
  end
  if not player then
    for _, v in ipairs(self.AllEnemyTeam) do
      if v then
        player = v:GetPlayerByGuid(playerGuid)
        if player then
          return player
        end
      end
    end
  end
end

function BattlePawnManager:GetBattleNpcById(battleNpcId)
  local battleNpc
  for _, currentBattleNpc in ipairs(self.battleNpcList or {}) do
    if currentBattleNpc.battlePawnId == battleNpcId then
      battleNpc = currentBattleNpc
    end
  end
  return battleNpc
end

function BattlePawnManager:GetAllPawn()
  local ret = table.join({
    self:GetPlayerMyTeam(),
    self:GetPlayerEnemyTeam()
  }, self.playerTeam.pets, self.enemyTeam.pets)
  return ret
end

function BattlePawnManager:GetAllPlayers()
  local allPlayers = {}
  if self.AllPlayerTeam then
    for _, v in ipairs(self.AllPlayerTeam) do
      table.insert(allPlayers, v.player)
    end
  end
  if self.AllEnemyTeam then
    for _, v in ipairs(self.AllEnemyTeam) do
      table.insert(allPlayers, v.player)
    end
  end
  return allPlayers
end

function BattlePawnManager:GetAllPets()
  local allPets = {}
  if self.AllPlayerTeam then
    for _, v in ipairs(self.AllPlayerTeam) do
      for _, p in pairs(v:GetPets()) do
        tInsert(allPets, p)
      end
    end
  end
  if self.AllEnemyTeam then
    for _, v in ipairs(self.AllEnemyTeam) do
      for _, p in pairs(v:GetPets()) do
        tInsert(allPets, p)
      end
    end
  end
  return allPets
end

function BattlePawnManager:GetAllBattleNpc()
  return self.battleNpcList
end

function BattlePawnManager:GetAllBattleOnLookers()
  local battleOnLookers = {}
  for i, battleNpc in ipairs(self.battleNpcList) do
    if battleNpc.type == BattleNpc.Type.SingleOnLooker then
      tInsert(battleOnLookers, battleNpc)
    end
  end
  return battleOnLookers
end

function BattlePawnManager:GetBattlePlayerInspectorByUin(uni)
  local battlePlayerInspector
  local battleNpcList = self.battleNpcList or {}
  for i, battleNpc in ipairs(battleNpcList) do
    if battleNpc:GetId() == uni then
      battlePlayerInspector = battleNpc
    end
  end
  return battlePlayerInspector
end

function BattlePawnManager:GetAllBattleCrowdOnLookers()
  local battleOnLookers = {}
  for i, battleNpc in ipairs(self.battleNpcList) do
    if battleNpc.type == BattleNpc.Type.CrowdOnLooker then
      tInsert(battleOnLookers, battleNpc)
    end
  end
  return battleOnLookers
end

function BattlePawnManager:GetPetByPos(team, pos)
  local player = self.playerTeam
  if team == BattleEnum.Team.ENUM_ENEMY then
    player = self.enemyTeam
  end
  for p, v in pairs(player:GetPets()) do
    if v.card.posInField == pos then
      return v
    end
  end
end

function BattlePawnManager:GetAllPawnActorForSkill()
  local ret = {
    [0] = "nil"
  }
  local index = 0
  local team = self:GetAllTeam(BattleEnum.Team.ENUM_TEAM)
  local pets = self:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, false)
  for i = 1, 4 do
    if team[i] and team[i].player then
      ret[index] = team[i].player.model
      if not ret[index] then
        ret[index] = "nil"
        Log.DebugFormat("Player %d Is Nil", index)
      end
    else
      ret[index] = "nil"
    end
    index = index + 1
  end
  for i = 1, 4 do
    if pets[i] then
      ret[index] = pets[i].model
      if not ret[index] then
        ret[index] = "nil"
        Log.DebugFormat("Pet %d Is Nil", i)
      end
    else
      ret[index] = "nil"
    end
    index = index + 1
  end
  team = self:GetAllTeam(BattleEnum.Team.ENUM_ENEMY)
  pets = self:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY, false)
  for i = 1, 4 do
    if team[i] and team[i].player then
      ret[index] = team[i].player.model
      if not ret[index] then
        ret[index] = "nil"
        Log.DebugFormat("Player %d Is Nil", index)
      end
    else
      ret[index] = "nil"
    end
    index = index + 1
  end
  for i = 1, 4 do
    if pets[i] then
      ret[index] = pets[i].model
      if not ret[index] then
        ret[index] = "nil"
        Log.DebugFormat("Pet %d Is Nil", i)
      end
    else
      ret[index] = "nil"
    end
    index = index + 1
  end
  return ret
end

function BattlePawnManager:GetBattlePetByActor(actor, ignoreDead)
  if self.AllPlayerTeam then
    for i = 1, #self.AllPlayerTeam do
      local team = self.AllPlayerTeam[i]
      local pets = team:GetPets()
      for _, v in pairs(pets) do
        if (not v:IsDead() or ignoreDead) and v.model == actor then
          return v
        end
      end
      local restPets = team:GetRestPets()
      for _, v in pairs(restPets) do
        if (not v:IsDead() or ignoreDead) and v.model == actor then
          return v
        end
      end
    end
  end
  if self.AllEnemyTeam then
    for i = 1, #self.AllEnemyTeam do
      local team = self.AllEnemyTeam[i]
      local pets = team:GetPets()
      for _, v in pairs(pets) do
        if (not v:IsDead() or ignoreDead) and v.model == actor then
          return v
        end
      end
      local restPets = team:GetRestPets()
      for _, v in pairs(restPets) do
        if (not v:IsDead() or ignoreDead) and v.model == actor then
          return v
        end
      end
    end
  end
  return nil
end

function BattlePawnManager:GetBattlePlayerByActor(actor)
  local player
  if self.AllPlayerTeam then
    Log.Debug("AllPlayerTeam:", #self.AllPlayerTeam)
    for _, v in ipairs(self.AllPlayerTeam) do
      player = v:GetPlayer()
      if player and player.model == actor then
        Log.Debug("BattlePawnManager:GetBattlePlayerByActor:", actor, player.model)
        return player
      end
    end
  end
  if self.AllEnemyTeam then
    for _, v in ipairs(self.AllEnemyTeam) do
      player = v:GetPlayer()
      if player and player.model == actor then
        Log.Debug("BattlePawnManager:GetBattlePlayerByActor:", actor, player.model)
        return player
      end
    end
  end
  return nil
end

function BattlePawnManager:GetPetActor(petGuid)
  local ret = {}
  if self:GetPlayerEnemyTeam().model then
    ret = {
      self:GetPlayerMyTeam().model,
      self:GetPlayerEnemyTeam().model
    }
  else
    ret = {
      self:GetPlayerMyTeam().model,
      self:GetPlayerMyTeam().model
    }
  end
  local pet = self:GetPetByGuid(petGuid)
  tInsert(ret, pet.model)
  return ret
end

function BattlePawnManager:GetPetActorByArray(petIds)
  local ret = {}
  if self:GetPlayerEnemyTeam().model then
    ret = {
      self:GetPlayerMyTeam().model,
      self:GetPlayerEnemyTeam().model
    }
  else
    ret = {
      self:GetPlayerMyTeam().model,
      self:GetPlayerMyTeam().model
    }
  end
  Log.Dump(petIds)
  for i = 1, #petIds do
    local pet = self:GetPetByGuid(petIds[i])
    if not pet then
      Log.Error("pet not found : ", petIds[i])
    else
      tInsert(ret, pet.model)
    end
  end
  return ret
end

function BattlePawnManager:GetPetByGuid(petGuid)
  local pet
  if self.AllPlayerTeam then
    for _, v in ipairs(self.AllPlayerTeam) do
      pet = v:GetPetByGuid(petGuid)
      if pet then
        break
      end
    end
  end
  if self.AllEnemyTeam and not pet then
    for _, v in ipairs(self.AllEnemyTeam) do
      pet = v:GetPetByGuid(petGuid)
      if pet then
        break
      end
    end
  end
  return pet
end

function BattlePawnManager:GetCurPlayerPet(petGuid)
  if self.playerTeam then
    return self.playerTeam:GetPetByGuid(petGuid)
  end
end

function BattlePawnManager:GetCardByPetBaseId(teamEnum, petBaseId)
  local Teams = self:GetAllTeam(teamEnum)
  Teams = Teams or {}
  for _, Team in ipairs(Teams) do
    local cards = Team.player.deck.cards
    for _, card in pairs(cards) do
      if card.petBaseConf and card.petBaseConf.id == petBaseId then
        return card
      end
    end
  end
end

function BattlePawnManager:GetCardByGuid(petGuid)
  if not self:IsValid() then
    return nil
  end
  local card
  for _, v in ipairs(self.AllPlayerTeam) do
    card = v:GetCardByGuid(petGuid)
    if card then
      break
    end
  end
  if not card then
    for _, v in ipairs(self.AllEnemyTeam) do
      card = v:GetCardByGuid(petGuid)
      if card then
        break
      end
    end
  end
  return card
end

function BattlePawnManager:GetCardByCommonGuid(teamEnum, petGuid)
  local Teams = self:GetAllTeam(teamEnum)
  Teams = Teams or {}
  for _, Team in ipairs(Teams) do
    local cards = Team.player.deck.cards
    for _, card in pairs(cards) do
      if card.petInfo and card.petInfo.battle_common_pet_info and card.petInfo.battle_common_pet_info.gid == petGuid then
        return card
      end
    end
  end
end

function BattlePawnManager:GetPetChangeSuitIdByGuid(petGuid)
  local card = self:GetCardByGuid(petGuid)
  if card then
    return card.AppearancePath.HuanchongSuiId or -1
  end
  return -1
end

function BattlePawnManager:GetCardTeamByGuid(petGuid)
  local card
  for _, v in ipairs(self.AllPlayerTeam) do
    card = v:GetCardByGuid(petGuid)
    if card then
      return card
    end
  end
  for _, v in ipairs(self.AllEnemyTeam) do
    card = v:GetCardByGuid(petGuid)
    if card then
      return card
    end
  end
  return card
end

function BattlePawnManager:GetTeamByPetGuid(petGuid)
  local pet = self:GetPetByGuid(petGuid)
  if not pet then
    return nil
  end
  return pet.team
end

function BattlePawnManager:GetLuaPetByCPPActor(Performer)
  if not Performer then
    Log.Error("Performer is nil!!")
    return nil
  end
  if not (self.playerTeam and self.playerTeam.pets and self.enemyTeam) or not self.enemyTeam.pets then
    Log.ErrorFormat("Can't find a proper lua object for performer %s", Performer)
    return nil
  end
  for i = 1, 4 do
    local pet = self.playerTeam.pets[i]
    if pet and pet.model == Performer then
      return pet
    end
    pet = self.enemyTeam.pets[i]
    if pet and pet.model == Performer then
      return pet
    end
  end
  Log.ErrorFormat("Can't find a proper lua object for performer %s", Performer)
  return nil
end

function BattlePawnManager:GetLuaPlayerCPPActor(Performer)
  if not (self.playerTeam and self:GetPlayerMyTeam() and self.enemyTeam) or not self:GetPlayerEnemyTeam() then
    return
  end
  if self:GetPlayerMyTeam().model == Performer then
    return self:GetPlayerMyTeam()
  elseif self:GetPlayerEnemyTeam().model == Performer then
    return self:GetPlayerEnemyTeam()
  end
end

function BattlePawnManager:IsLocalPlayer(player)
  return player.guid == _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
end

function BattlePawnManager:Clear()
  Log.Debug("Clearing Battle Pawns")
  self:TryCancelRefreshBattleOnLookCallbackDelayId()
  self:ClearPawnObj()
  self.VBattleField = nil
end

function BattlePawnManager:ClearDelay()
  Log.Debug("Clearing Battle Pawns")
  self:TryCancelRefreshBattleOnLookCallbackDelayId()
  self:ClearPawnSkill()
  self:ClearPawnObjDelay()
  self.VBattleField = nil
end

function BattlePawnManager:GetLastPet(teamType, LimitTeam)
  local teams
  if teamType == BattleEnum.Team.ENUM_ENEMY then
    teams = LimitTeam or self.AllEnemyTeam
  end
  if teamType == BattleEnum.Team.ENUM_TEAM then
    teams = LimitTeam or self.AllPlayerTeam
  end
  if not teams then
    return nil
  end
  local maxPos = -1
  local maxPet
  for _, v in ipairs(teams) do
    for _, pet in pairs(v:GetPets()) do
      if pet.card:IsCanSelect() and maxPos < pet.card.posInField then
        maxPos = pet.card.posInField
        maxPet = pet
      end
    end
  end
  if BattleUtils.IsCrowdBattle() and maxPos < 2 then
    for _, v in ipairs(teams) do
      for _, pet in pairs(v:GetPets()) do
        if pet.card:IsExistAtField() and maxPos < pet.card.petInfo.battle_inside_pet_info.cheers_tag then
          maxPos = pet.card.petInfo.battle_inside_pet_info.cheers_tag
          maxPet = pet
        end
      end
    end
  end
  return maxPet
end

function BattlePawnManager:GetFirstPet(teamType, LimitTeam)
  local teams
  if teamType == BattleEnum.Team.ENUM_ENEMY then
    teams = LimitTeam or self.AllEnemyTeam
  end
  if teamType == BattleEnum.Team.ENUM_TEAM then
    teams = LimitTeam or self.AllPlayerTeam
  end
  if not teams then
    return nil
  end
  local minPos = 100
  local minPet
  for _, v in ipairs(teams) do
    for _, pet in pairs(v:GetPets()) do
      if pet.card:IsCanSelect() and minPos > pet.card.posInField then
        minPos = pet.card.posInField
        minPet = pet
      end
    end
  end
  return minPet
end

function BattlePawnManager:IsValid(bSkipLogError)
  if self.playerTeam and self.enemyTeam and self.AllPlayerTeam and self.AllEnemyTeam and BattleManager.isInBattle then
    return true
  end
  if not bSkipLogError then
    Log.ErrorFormat("BattlePawnManager \230\136\152\229\156\186\230\156\137\233\151\174\233\162\152\239\188\140\230\136\152\229\156\186\229\175\185\232\177\161\228\184\141\229\173\152\229\156\168\228\186\134 playerTeam:%s, enemyTeam:%s, AllPlayerTeam:%s, AllEnemyTeam:%s, isInBattle:%s", self.playerTeam, self.enemyTeam, self.AllPlayerTeam, self.AllEnemyTeam, _G.BattleManager.isInBattle)
  end
  return false
end

function BattlePawnManager:GetTeamPet(teamType, petIndex)
  local team = self:GetTeam(teamType)
  if not team then
    return nil
  end
  local pets = team.pets
  if not pets or 0 == #pets then
    return nil
  end
  return pets[petIndex]
end

function BattlePawnManager:TogglePetBuffsVisibility(visible, cleanBuffEffect)
  for _, playerTeam in pairs(self.AllPlayerTeam) do
    if cleanBuffEffect then
      playerTeam:ClearBuffsEffect()
    end
    playerTeam:TogglePetBuffsVisible(visible)
  end
  for _, enemyTeam in pairs(self.AllEnemyTeam) do
    if cleanBuffEffect then
      enemyTeam:ClearBuffsEffect()
    end
    enemyTeam:TogglePetBuffsVisible(visible)
  end
end

function BattlePawnManager:HideAll(petOnly)
  if self.AllPlayerTeam then
    for i, team in ipairs(self.AllPlayerTeam) do
      team:HideAll(petOnly)
    end
  end
  if self.AllEnemyTeam then
    for i, team in ipairs(self.AllEnemyTeam) do
      team:HideAll(petOnly)
    end
  end
end

function BattlePawnManager:GetTeamIdxByPlayer(player, teamEnum)
  local teams
  if teamEnum == BattleEnum.Team.ENUM_TEAM then
    teams = self.AllPlayerTeam
  elseif teamEnum == BattleEnum.Team.ENUM_ENEMY then
    teams = self.AllEnemyTeam
  else
    return nil
  end
  for i = 1, #teams do
    if teams[i].player.roleInfo.base.role_uin == player.roleInfo.base.role_uin then
      return i
    end
  end
  return nil
end

function BattlePawnManager:ConvertActorToBattlePet(actor)
end

function BattlePawnManager:ConvertBattlePetToActor(battlePet)
end

function BattlePawnManager:IsBattlePetInState(actor, state)
  local battlePet = self:GetBattlePetByActor(actor)
  if battlePet then
    return battlePet.card.petState[state] ~= nil
  end
  return false
end

function BattlePawnManager:IsEnemyTeam(guid)
  local result = guid / 400
  if result > 1 then
    return true
  end
  return false
end

function BattlePawnManager:GetTeamAllPets()
  local allPets = {}
  if self.AllPlayerTeam then
    for _, v in ipairs(self.AllPlayerTeam) do
      for _, p in pairs(v:GetPets()) do
        tInsert(allPets, p)
      end
    end
  end
  return allPets
end

function BattlePawnManager:GetPlayerTeamPets()
  local allPets = {}
  if self.playerTeam then
    for _, pet in pairs(self.playerTeam:GetPets()) do
      tInsert(allPets, pet)
    end
  else
    Log.Warning("BattlePawnManager:GetPlayerTeamPets playerTeam is nil")
  end
  return allPets
end

function BattlePawnManager:GetEnemyAllPets()
  local allPets = {}
  if self.AllEnemyTeam then
    for _, v in ipairs(self.AllEnemyTeam) do
      for _, p in pairs(v:GetPets()) do
        tInsert(allPets, p)
      end
    end
  end
  return allPets
end

function BattlePawnManager:IsSkipWorldLeaderSeamless()
  return self:IsReviveAfterBattle() or BattleUtils.IsDeathExist(self:GetPetByPos(BattleEnum.Team.ENUM_ENEMY, 1))
end

function BattlePawnManager:IsReviveAfterBattle()
  if self.TeamatePlayer then
    if 0 == self.TeamatePlayer.roleInfo.base.hp then
      return true
    else
      local cards = self.TeamatePlayer.deck.cards
      for _, v in pairs(cards) do
        if v.hp > 0 then
          return false
        end
      end
      return true
    end
  end
end

function BattlePawnManager:IsShowPetBuffs(_IsShow)
  _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_PLAYERSKILL_ISHIDE_HP, _IsShow)
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ShowOrHideAdditionalTargetPanel, _IsShow)
  local EnemyPetList = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_ENEMY)
  local BattlePetList = _G.BattleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM)
  if BattlePetList and #BattlePetList > 0 then
    for k, v in ipairs(BattlePetList) do
      v:ChangeBuffVisibility(_IsShow)
    end
  end
  if EnemyPetList and #EnemyPetList > 0 then
    for k, v in ipairs(EnemyPetList) do
      v:ChangeBuffVisibility(_IsShow)
    end
  end
end

function BattlePawnManager:ClearPendingKillModels()
  for _, pet in ipairs(self.PendingKillBattlePets or {}) do
    pet:Destroy()
  end
  table.clear(self.PendingKillBattlePets)
end

function BattlePawnManager:ClearRequestDict()
  self.requestDict = {}
  self.invalidRes = {}
end

function BattlePawnManager:ClearBattleNpcSpawnContext()
  local battleOnLookerInfo = _G.BattleManager.battleRuntimeData.battleOnLookerInfo
  if battleOnLookerInfo and battleOnLookerInfo.spawnBattleOnLookerAsyncContext then
    a.kill(battleOnLookerInfo.spawnBattleOnLookerAsyncContext)
    battleOnLookerInfo.spawnBattleOnLookerAsyncContext = nil
  end
  self.battleOnLookerDisplayIsRefreshing = false
end

function BattlePawnManager:TryCancelRefreshBattleOnLookCallbackDelayId()
  local refreshBattleOnLookCallbackDelayId = self.refreshBattleOnLookCallbackDelayId
  if refreshBattleOnLookCallbackDelayId then
    _G.DelayManager:CancelDelayById(refreshBattleOnLookCallbackDelayId)
  end
end

return BattlePawnManager
