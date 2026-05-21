local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local RocoSkillAction = NRCClass()

function RocoSkillAction:Initialize()
end

function RocoSkillAction:Ctor()
  self.SkillObject = nil
end

function RocoSkillAction:OnActionInitialized()
  self:CheckEnableInWorldCombat()
end

function RocoSkillAction:OnActionDestruct()
end

function RocoSkillAction:GetSkill()
  return self:GetSkillObj()
end

function RocoSkillAction:GetCasterActor()
  local Skill = self:GetSkill()
  if not Skill then
    return nil
  end
  local Data = Skill.DynamicData
  if not Data then
    return nil
  end
  return Data.Caster
end

function RocoSkillAction:GetBattleFieldConf()
  local skill = self:GetSkill()
  if not UE.UObject.IsValid(skill) then
    return nil
  end
  local battleFieldConf = skill:GetBattleFieldConf()
  if not UE.UObject.IsValid(battleFieldConf) then
    return nil
  end
  return battleFieldConf
end

function RocoSkillAction:ConvertCharacterIndex(InputEnum)
  if InputEnum == UE4.EBattleStaticActorType.Player_1 then
    return 0
  elseif InputEnum == UE4.EBattleStaticActorType.Player_1_2 then
    return 1
  elseif InputEnum == UE4.EBattleStaticActorType.Player_1_3 then
    return 2
  elseif InputEnum == UE4.EBattleStaticActorType.Player_1_4 then
    return 3
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_1 then
    return 4
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_2 then
    return 5
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_3 then
    return 6
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_4 then
    return 7
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2 then
    return 8
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_2 then
    return 9
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_3 then
    return 10
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_4 then
    return 11
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_1 then
    return 12
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_2 then
    return 13
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_3 then
    return 14
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_4 then
    return 15
  end
  return -1
end

function RocoSkillAction:GetTeam(InputEnum)
  if InputEnum == UE4.EBattleStaticActorType.Player_1 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player1_2 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_1 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_2 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_1 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_2 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_3 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_2_4 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_2 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_3 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player_2_4 then
    return UE4.EBattleFieldTeam.EnemyTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player1_3 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Player1_4 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_3 then
    return UE4.EBattleFieldTeam.PlayerTeam
  elseif InputEnum == UE4.EBattleStaticActorType.Pet_1_4 then
    return UE4.EBattleFieldTeam.PlayerTeam
  end
  return UE4.EBattleFieldTeam.PlayerTeam
end

function RocoSkillAction:GetActorByActorInfo(ActorInfo)
  if not UE.UObject.IsValid(self) then
    return nil
  end
  local cacheDict = self:GetSkill().GetActorCacheDict
  local selfCache
  if self.EnableGetActorCache then
    if not cacheDict[self] then
      cacheDict[self] = {}
    end
    selfCache = cacheDict[self]
    local actor = selfCache[ActorInfo]
    if actor then
      if "NIL" ~= actor then
        return actor
      end
      return nil
    end
  end
  if self.TestGetActorByActorInfo then
    local Actor = self:TestGetActorByActorInfo(ActorInfo)
    if Actor and "nil" ~= Actor and UE4.UObject.IsValid(Actor) and Actor:IsA(UE4.AActor) then
      if self.EnableGetActorCache then
        selfCache[ActorInfo] = Actor
      end
      return Actor
    else
      if self.EnableGetActorCache then
        selfCache[ActorInfo] = "NIL"
      end
      return nil
    end
  elseif self.Overridden and self.Overridden.GetActorByActorInfo then
    local actor = self.Overridden.GetActorByActorInfo(self, ActorInfo)
    if self.EnableGetActorCache then
      selfCache[ActorInfo] = actor
    end
    return actor
  else
    if self.EnableGetActorCache then
      selfCache[ActorInfo] = "NIL"
    end
    return nil
  end
end

function RocoSkillAction:GetLocationByActorInfo(ActorInfo, idx)
  if ActorInfo.ActorType == UE.ERocoSkillActorType.SelectGroupPoints then
    local SkillObject = self:GetSkill()
    if not SkillObject then
      return nil
    end
    return SkillObject:GetSelectLocationByIdx(idx)
  end
end

function RocoSkillAction:GetActorsByType(type, Actor)
  local result = UE.TSet(UE.AActor)
  if BattleManager and BattleManager:IsInBattle(true) then
    local function Get_Players(teamEnum)
      local teams = teamEnum == BattleEnum.Team.ENUM_TEAM and BattleManager.battlePawnManager.AllPlayerTeam or BattleManager.battlePawnManager.AllEnemyTeam
      
      for i, v in ipairs(teams) do
        result:Add(v.player.model)
      end
    end
    
    local function Get_Pets(teamEnum)
      local pets = BattleManager.battlePawnManager:GetInFieldAllPet(teamEnum)
      for i, v in ipairs(pets) do
        result:Add(v.model)
      end
    end
    
    if type == UE4.EGetActorsType.AllPets then
      Get_Pets(BattleEnum.Team.ENUM_ENEMY)
      Get_Pets(BattleEnum.Team.ENUM_TEAM)
    elseif type == UE4.EGetActorsType.AllActors then
      Get_Players(BattleEnum.Team.ENUM_ENEMY)
      Get_Pets(BattleEnum.Team.ENUM_ENEMY)
      Get_Players(BattleEnum.Team.ENUM_TEAM)
      Get_Pets(BattleEnum.Team.ENUM_TEAM)
    elseif type == UE4.EGetActorsType.AllPlayers then
      Get_Players(BattleEnum.Team.ENUM_ENEMY)
      Get_Players(BattleEnum.Team.ENUM_TEAM)
    else
      local friendTeamEnum, player
      local pet = BattleManager.battlePawnManager:GetBattlePetByActor(Actor, true)
      if pet then
        friendTeamEnum = pet.teamEnm
        player = pet.player
      else
        player = BattleManager.battlePawnManager:GetBattlePlayerByActor(Actor, true)
        if player then
          friendTeamEnum = player.teamEnm
        end
      end
      if friendTeamEnum then
        local enemyTeamEnum = friendTeamEnum == BattleEnum.Team.ENUM_TEAM and BattleEnum.Team.ENUM_ENEMY or BattleEnum.Team.ENUM_TEAM
        if type == UE4.EGetActorsType.AllEnemyPets then
          Get_Pets(enemyTeamEnum)
        elseif type == UE4.EGetActorsType.AllFriendPets then
          Get_Pets(friendTeamEnum)
        elseif type == UE4.EGetActorsType.AllEnemyPlayers then
          Get_Players(enemyTeamEnum)
        elseif type == UE4.EGetActorsType.AllFriendPlayers then
          Get_Players(friendTeamEnum)
        elseif type == UE4.EGetActorsType.AllEnemyPlayersAndPets then
          Get_Players(enemyTeamEnum)
          Get_Pets(enemyTeamEnum)
        elseif type == UE4.EGetActorsType.AllFriendPlayersAndPets then
          Get_Players(friendTeamEnum)
          Get_Pets(friendTeamEnum)
        elseif type == UE4.EGetActorsType.AllMySelfPets then
          local pets = BattleManager.battlePawnManager:GetInFieldAllPet(friendTeamEnum)
          for i, v in ipairs(pets) do
            if v.player == player then
              result:Add(v.model)
            end
          end
        end
      end
    end
    result:Remove(nil)
    return result
  end
  local Characters = self:GetSkill().DynamicData.Characters
  if Characters then
    local function Group1_Players()
      for j = UE4.EBattleStaticActorType.Player_1, UE4.EBattleStaticActorType.Player_1_4 do
        result:Add(Characters[j])
      end
    end
    
    local function Group1_Pets()
      for j = UE4.EBattleStaticActorType.Pet_1_1, UE4.EBattleStaticActorType.Pet_1_4 do
        result:Add(Characters[j])
      end
    end
    
    local function Group2_Players()
      for j = UE4.EBattleStaticActorType.Player_2, UE4.EBattleStaticActorType.Player_2_4 do
        result:Add(Characters[j])
      end
    end
    
    local function Group2_Pets()
      for j = UE4.EBattleStaticActorType.Pet_2_1, UE4.EBattleStaticActorType.Pet_2_4 do
        result:Add(Characters[j])
      end
    end
    
    if type == UE4.EGetActorsType.AllPets then
      Group1_Pets()
      Group2_Pets()
    elseif type == UE4.EGetActorsType.AllActors then
      for j = UE4.EBattleStaticActorType.Player_1, UE4.EBattleStaticActorType.Pet_2_4 do
        result:Add(Characters[j])
      end
    elseif type == UE4.EGetActorsType.AllPlayers then
      Group1_Players()
      Group2_Players()
    else
      for i, v in pairs(Characters) do
        if v == Actor then
          if i < UE4.EBattleStaticActorType.Player_2 then
            if type == UE4.EGetActorsType.AllEnemyPets then
              Group2_Pets()
            elseif type == UE4.EGetActorsType.AllEnemyPlayers then
              Group2_Players()
            elseif type == UE4.EGetActorsType.AllFriendPlayers then
              Group1_Players()
            elseif type == UE4.EGetActorsType.AllFriendPets then
              Group1_Pets()
            elseif type == UE4.EGetActorsType.AllEnemyPlayersAndPets then
              Group2_Players()
              Group2_Pets()
            elseif type == UE4.EGetActorsType.AllFriendPlayersAndPets then
              Group1_Players()
              Group1_Pets()
            elseif type == UE4.EGetActorsType.AllMySelfPets then
              local playerNum, petNum = 0, 0
              for j = UE4.EBattleStaticActorType.Pet_1_1, UE4.EBattleStaticActorType.Pet_1_4 do
                if Characters[j] then
                  petNum = petNum + 1
                end
              end
              for j = UE4.EBattleStaticActorType.Player_1, UE4.EBattleStaticActorType.Player_1_4 do
                if Characters[j] then
                  playerNum = playerNum + 1
                end
              end
              local perPetNum = math.floor(petNum / playerNum)
              local teamIndex = 1
              local curTeamNum = 1
              local petTeam = {}
              for j = UE4.EBattleStaticActorType.Pet_1_1, UE4.EBattleStaticActorType.Pet_1_4 do
                if Characters[j] then
                  if not petTeam[teamIndex] then
                    petTeam[teamIndex] = {}
                  end
                  petTeam[teamIndex][curTeamNum] = Characters[j]
                  curTeamNum = curTeamNum + 1
                  if perPetNum < curTeamNum then
                    teamIndex = teamIndex + 1
                    curTeamNum = 1
                  end
                end
              end
              if i <= UE4.EBattleStaticActorType.Player_1_4 then
                local index = i - UE4.EBattleStaticActorType.Player_1 + 1
                for _, v in ipairs(petTeam[index]) do
                  if v ~= Actor then
                    result:Add(v)
                  end
                end
              else
                for _, v in ipairs(petTeam) do
                  if table.contains(v, Actor) then
                    for _, v in ipairs(v) do
                      if v ~= Actor then
                        result:Add(v)
                      end
                    end
                  end
                end
              end
            end
          elseif type == UE4.EGetActorsType.AllEnemyPets then
            Group1_Pets()
          elseif type == UE4.EGetActorsType.AllEnemyPlayers then
            Group1_Players()
          elseif type == UE4.EGetActorsType.AllFriendPlayers then
            Group2_Players()
          elseif type == UE4.EGetActorsType.AllFriendPets then
            Group2_Pets()
          elseif type == UE4.EGetActorsType.AllEnemyPlayersAndPets then
            Group1_Players()
            Group1_Pets()
          elseif type == UE4.EGetActorsType.AllFriendPlayersAndPets then
            Group2_Players()
            Group2_Pets()
          elseif type == UE4.EGetActorsType.AllMySelfPets then
            local playerNum, petNum = 0, 0
            for j = UE4.EBattleStaticActorType.Pet_2_1, UE4.EBattleStaticActorType.Pet_2_4 do
              if Characters[j] then
                petNum = petNum + 1
              end
            end
            for j = UE4.EBattleStaticActorType.Player_2, UE4.EBattleStaticActorType.Player_2_4 do
              if Characters[j] then
                playerNum = playerNum + 1
              end
            end
            local perPetNum = math.floor(petNum / playerNum)
            local teamIndex = 1
            local curTeamNum = 1
            local petTeam = {}
            for j = UE4.EBattleStaticActorType.Pet_2_1, UE4.EBattleStaticActorType.Pet_2_4 do
              if Characters[j] then
                if not petTeam[teamIndex] then
                  petTeam[teamIndex] = {}
                end
                petTeam[teamIndex][curTeamNum] = Characters[j]
                curTeamNum = curTeamNum + 1
                if perPetNum < curTeamNum then
                  teamIndex = teamIndex + 1
                  curTeamNum = 1
                end
              end
            end
            if i <= UE4.EBattleStaticActorType.Player_2_4 then
              local index = i - UE4.EBattleStaticActorType.Player_2 + 1
              for _, v in ipairs(petTeam[index]) do
                if v ~= Actor then
                  result:Add(v)
                end
              end
            else
              for _, v in ipairs(petTeam) do
                if table.contains(v, Actor) then
                  for _, v in ipairs(v) do
                    if v ~= Actor then
                      result:Add(v)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  result:Remove(nil)
  return result
end

function RocoSkillAction:TestGetActorByActorInfo(ActorInfo)
  if not self.GetSkill then
    return nil
  end
  local SkillObject = self:GetSkill()
  if ActorInfo.ActorType == UE4.ERocoSkillActorType.DefaultCaster then
    return self:GetDefaultCasterActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.DynamicTarget then
    return self:GetDynamicTargetActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.StaticCharacter then
    local Index = self:ConvertCharacterIndex(ActorInfo.CharacterActorType)
    if not SkillObject.DynamicData then
      return nil
    end
    if not SkillObject.DynamicData.Characters then
      return nil
    end
    return SkillObject.DynamicData.Characters[Index]
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.StaticPos then
    return self:GetStaticPosActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.Camera then
    return self:GetBattleFieldCameraByType(ActorInfo.BattleCameraType)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.Blackboard then
    if not SkillObject.Blackboard then
      return nil
    end
    return SkillObject.Blackboard:GetValueAsObject(ActorInfo.BlackboardActorKey)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.PathSpawnActor then
    return self:GetPathSpawnActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.RocoBall then
    return self:GetRocoBallActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.RocoItem then
    return self:GetRocoItemActor()
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.Counter then
    return self:GetDynamicCounterActor(ActorInfo)
  elseif ActorInfo.ActorType == UE4.ERocoSkillActorType.BeCounter then
    return self:GetDynamicBeCounterActor(ActorInfo)
  end
end

function RocoSkillAction:GetDefendHitPointActor()
  if not self:IsA(UE4.URocoPlayFxSystemAction) then
    return nil
  end
  local action = self
  if not action.bIsHitEffect then
    return nil
  end
  if action.SkillHitPointType == UE4.ERocoSkillHitPointType.None then
    return nil
  end
  local SkillObject = self:GetSkill()
  if not SkillObject.Blackboard or not UE.UObject.IsValid(SkillObject.Blackboard) then
    return nil
  end
  local HitPointActor = SkillObject.Blackboard:GetValueAsObject("HitPointActor")
  if not HitPointActor then
    return nil
  end
  return HitPointActor:GetHitPoint(action.SkillHitPointType)
end

function RocoSkillAction:GetDefaultCasterActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if SkillObject.IsSkillEditor then
    if not SkillObject.CounterType or 0 == SkillObject.CounterType then
      return self.Overridden.GetActorByActorInfo(self, ActorInfo)
    else
      return SkillObject.DynamicData.Caster
    end
  end
  if not SkillObject.DynamicData then
    Log.Error("Cast is nil", self:GetName())
    return self.Overridden.GetActorByActorInfo(self, ActorInfo)
  end
  return SkillObject.DynamicData.Caster
end

function RocoSkillAction:GetDynamicTargetActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if not SkillObject.DynamicData or not SkillObject.DynamicData.Targets then
    Log.Error("need targets, but can't find it", SkillObject:GetName(), self:GetName(), SkillObject)
    Log.Dump(SkillObject.DynamicData, 1, "SkillObject.DynamicData:")
    Log.Dump(SkillObject, 1, "SkillObject:")
    return nil
  end
  return SkillObject.DynamicData.Targets[ActorInfo.DynamicTargetActorType + 1]
end

function RocoSkillAction:GetDynamicCounterActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if not SkillObject.DynamicData or not SkillObject.DynamicData.CounterActor then
    return self:GetDefaultCasterActor(ActorInfo)
  end
  return SkillObject.DynamicData.CounterActor
end

function RocoSkillAction:GetDynamicBeCounterActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if not SkillObject.DynamicData or not SkillObject.DynamicData.BeCounterActor then
    return self:GetDefaultCasterActor(ActorInfo)
  end
  return SkillObject.DynamicData.BeCounterActor
end

function RocoSkillAction:GetStaticPosActor(ActorInfo)
  local SkillObject = self:GetSkill()
  local attachPoint = ActorInfo.BattleFieldAttachPoint
  if ActorInfo.BattleFieldAttachPoint == UE.EBattleFieldAttachPoint.Pos_Target then
    local target = SkillObject.DynamicData.Targets[1]
    local pet = BattleManager.battlePawnManager:GetBattlePetByActor(target)
    if pet then
      attachPoint = pet:GetAttachPoint()
    end
  elseif ActorInfo.BattleFieldAttachPoint == UE.EBattleFieldAttachPoint.Pos_Caster then
    local caster = SkillObject.DynamicData.Caster
    local pet = BattleManager.battlePawnManager:GetBattlePetByActor(caster)
    if pet then
      attachPoint = pet:GetAttachPoint()
    end
  else
    attachPoint = ActorInfo.BattleFieldAttachPoint
  end
  local team = 0
  return self:GetBattleFieldStaticPosActorWithTeam(attachPoint, team)
end

function RocoSkillAction:PreLoadUObjects()
  local ActorInfo = self.DefaultExecuteActorInfo
  local ActorType = ActorInfo.ActorType
  if ActorType == UE4.ERocoSkillActorType.RocoBall then
    local SkillObject = self:GetSkill()
    local BallActor = SkillObject.Blackboard:GetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", ActorInfo.BallAttachIndex))
    if not BallActor then
      local BallPath = self:GetBallPath(ActorInfo, SkillObject)
      if not string.IsNilOrEmpty(BallPath) then
        self:AddStringPathToAsyncList(BallPath)
      end
    end
  elseif ActorType == UE4.ERocoSkillActorType.RocoItem then
    local SkillObject = self:GetSkill()
    local ItemActor = SkillObject.Blackboard:GetValueAsObject("_ID_AUTOGENERATE_ITEM")
    if not ItemActor then
      local ItemPath = self:GetRocoItemPath(SkillObject)
      self:AddStringPathToAsyncList(ItemPath)
    end
  elseif ActorType == UE4.ERocoSkillActorType.PathSpawnActor then
    local SkillObject = self:GetSkill()
    local SpawnActorPath = self:GetSpawnActorPath(ActorInfo, SkillObject)
    local SpawnActor = SkillObject.Blackboard:GetValueAsObject(SpawnActorPath)
    if not SpawnActor and not string.IsNilOrEmpty(SpawnActorPath) then
      self:AddStringPathToAsyncList(SpawnActorPath)
    end
  end
end

function RocoSkillAction:GetPathSpawnActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if not SkillObject.Blackboard then
    return nil
  end
  local ActorPath = self:GetSpawnActorPath(ActorInfo, SkillObject)
  if string.IsNilOrEmpty(ActorPath) then
    return nil
  end
  local Actor = SkillObject.Blackboard:GetValueAsObject(ActorPath)
  if Actor then
    return Actor
  end
  Actor = self:EnsureGetObjectByPath(ActorPath)
  if Actor and SkillObject.Blackboard then
    SkillObject.Blackboard:SetValueAsObject(ActorPath, Actor)
  end
  return Actor
end

function RocoSkillAction:GetSpawnActorPath(ActorInfo, SkillObject)
  if not SkillObject.Blackboard then
    return nil
  end
  local Key = ActorInfo.BlackboardActorKey
  local Auto = "_AUTO_ACTOR_"
  if not string.StartsWith(Key, Auto) then
    Key = Auto .. Key
  end
  return SkillObject.DynamicData[Key]
end

function RocoSkillAction:GetRocoBallActor(ActorInfo)
  local SkillObject = self:GetSkill()
  if not SkillObject.Blackboard then
    return nil
  end
  local ballKey = string.format("_ID_AUTOGENERATE_BALL%d", ActorInfo.BallAttachIndex)
  local Actor = SkillObject.Blackboard:GetValueAsObject(ballKey)
  if UE.UObject.IsValid(Actor) then
    self:InitBpBall(Actor, ActorInfo, SkillObject)
    return Actor
  end
  local BallPath = self:GetBallPath(ActorInfo, SkillObject)
  local BallResGroup = self:GetBallResGroup(ActorInfo, SkillObject)
  if not string.IsNilOrEmpty(BallPath) then
    Actor = self:EnsureGetObjectByPath(BallPath)
  end
  if UE.UObject.IsValid(Actor) then
    if BallResGroup then
      Actor:SetResGroup(BallResGroup)
    end
    self:InitBpBall(Actor, ActorInfo, SkillObject)
    Log.Debug("\229\146\149\229\153\156\231\144\131\231\148\159\229\145\189\229\145\168\230\156\159: \231\148\177\230\138\128\232\131\189\229\136\155\229\187\186", SkillObject.GetDisplayName and SkillObject:GetDisplayName(), Actor:GetFullName())
  end
  return Actor
end

function RocoSkillAction:GetBallPath(ActorInfo, SkillObject)
  local BallPath = SkillObject.DynamicData.BallPath
  if ActorInfo.BallAttachIndex > 0 and SkillObject.DynamicData.BallAdditionalPaths and #SkillObject.DynamicData.BallAdditionalPaths >= ActorInfo.BallAttachIndex then
    BallPath = SkillObject.DynamicData.BallAdditionalPaths[ActorInfo.BallAttachIndex]
  end
  if BallPath == BattleConst.BallPaths.None then
    BallPath = ""
  elseif string.IsNilOrEmpty(BallPath) or string.find(BallPath, "None") then
    BallPath = BattleConst.BallPaths.Default
  end
  return BallPath
end

function RocoSkillAction:GetBallResGroup(ActorInfo, SkillObject)
  local BallResGroup = SkillObject.DynamicData.BallResGroup
  if ActorInfo.BallAttachIndex > 0 and SkillObject.DynamicData.BallAdditionalResGroup and #SkillObject.DynamicData.BallAdditionalResGroup >= ActorInfo.BallAttachIndex then
    BallResGroup = SkillObject.DynamicData.BallAdditionalResGroup[ActorInfo.BallAttachIndex]
  end
  return BallResGroup
end

function RocoSkillAction:GetActorLinkWithBall(BallAttachIndex)
  local SkillObject = self:GetSkill()
  if SkillObject and BallAttachIndex > 0 and SkillObject.DynamicData.BallAdditionalPaths and BallAttachIndex <= #SkillObject.DynamicData.BallAdditionalPaths and SkillObject.DynamicData.BallAddLinkActors and BallAttachIndex <= #SkillObject.DynamicData.BallAddLinkActors then
    return SkillObject.DynamicData.BallAddLinkActors[BallAttachIndex]
  end
  return nil
end

function RocoSkillAction:InitBpBall(Actor, ActorInfo, SkillObject)
  if SkillObject.Blackboard then
    SkillObject.Blackboard:SetValueAsObject(string.format("_ID_AUTOGENERATE_BALL%d", ActorInfo.BallAttachIndex), Actor)
    local kInitedKey = string.format("_ID_AUTOGENERATE_BALL%d_Init_%s", ActorInfo.BallAttachIndex, tostring(Actor))
    local isBallInit = SkillObject.Blackboard:GetValueAsBool(kInitedKey)
    if isBallInit then
      return
    end
    SkillObject.Blackboard:SetValueAsBool(kInitedKey, true)
  end
  local Component = Actor:K2_GetRootComponent()
  if Component then
    Component:SetCollisionProfileName("NoCollision", false)
  end
  if not Actor.resourceLoaded then
    Actor.runtimeCreate = false
    if Actor.InitOutSceneAsync then
      Actor:InitOutSceneAsync()
    end
  end
  if _G.BattleManager and _G.BattleManager.isInBattle or self:IsSkillEditor() then
    if Actor.SkeletalMesh then
      Actor.SkeletalMesh.BoundsScale = 100
      Actor.SkeletalMesh.bNRCUseFixedSkelBounds = false
    end
    if Actor.SignificanceComponent then
      Actor.SignificanceComponent:UnregisterWithManager(true)
    end
  end
end

function RocoSkillAction:GetRocoItemPath(SkillObject)
  local ItemPath = SkillObject.DynamicData.ItemPath
  if string.IsNilOrEmpty(ItemPath) then
    ItemPath = "StaticMesh'/Game/ArtRes/Asset/Environment/Interator/FBX/SM_EnvComInte_Fruit02.SM_EnvComInte_Fruit02'"
  end
  return ItemPath
end

function RocoSkillAction:GetRocoItemActor()
  local SkillObject = self:GetSkill()
  if not SkillObject.Blackboard then
    return nil
  end
  local Actor = SkillObject.Blackboard:GetValueAsObject("_ID_AUTOGENERATE_ITEM")
  if Actor then
    return Actor
  end
  local ItemPath = self:GetRocoItemPath(SkillObject)
  Actor = self:EnsureGetObjectByPath(ItemPath)
  if Actor then
    Actor:SetActorEnableCollision(false)
    SkillObject.Blackboard:SetValueAsObject("_ID_AUTOGENERATE_ITEM", Actor)
  end
  return Actor
end

function RocoSkillAction:GetCasterTeamType()
  local Caster = self:GetCasterActor()
  if not Caster then
    return UE4.ERocoSkillTeamType.AllTeam
  end
  local Characters = self:GetSkill().DynamicData.Characters
  if not Characters then
    return UE4.ERocoSkillTeamType.AllTeam
  end
  for i, v in pairs(Characters) do
    if v == Caster then
      if i < UE4.EBattleStaticActorType.Player_2 then
        return UE4.ERocoSkillTeamType.SelfTeam
      else
        return UE4.ERocoSkillTeamType.EnemyTeam
      end
    end
  end
  return UE4.ERocoSkillTeamType.AllTeam
end

function RocoSkillAction:GetExecuteBossType()
  if BattleManager:IsInBattle(true) then
    local Actor = self:GetActorByActorInfo(self.DefaultExecuteActorInfo)
    local pet = BattleManager.battlePawnManager:GetBattlePetByActor(Actor, true)
    local petBaseConf = pet and pet.card and pet.card.petBaseConf
    if petBaseConf and petBaseConf.is_boss and 1 == petBaseConf.is_boss then
      return UE4.EPetBossType.Boss
    end
  end
  return UE4.EPetBossType.Pet
end

function RocoSkillAction:GetDefaultTargetActor()
  local SkillObject = self:GetSkill()
  if SkillObject.DynamicData and SkillObject.DynamicData.Targets then
    local Target = SkillObject.DynamicData.Targets[1]
    if UE.UObject.IsValid(Target) then
      return Target
    end
  end
  return nil
end

function RocoSkillAction:GetAllTargetActor()
  local SkillObject = self:GetSkill()
  return SkillObject.DynamicData.Targets
end

local IS_EDITOR = _G.RocoEnv.IS_EDITOR

function RocoSkillAction:IsSkillEditor()
  if not IS_EDITOR then
    return false
  end
  local SkillObject = self:GetSkill()
  if not SkillObject then
    return false
  end
  return SkillObject.IsSkillEditor
end

function RocoSkillAction:CheckEnableInWorldCombat()
  if self.m_WorldCombatOnlyEnableForParticipant then
    local caster = self:GetCasterActor()
    if not caster then
      return
    end
    local sceneCharacter = caster.sceneCharacter
    if not sceneCharacter then
      return
    end
    if not sceneCharacter then
      return
    end
    local config = sceneCharacter.config
    if not config then
      return
    end
    local bossId
    if config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
      bossId = sceneCharacter:GetServerId()
    elseif config.genre == _G.Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
      if not sceneCharacter.serverData then
        return
      end
      if not sceneCharacter.serverData.npc_base then
        return
      end
      bossId = sceneCharacter.serverData.npc_base.src_npc_id
    else
      return
    end
    if _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsACombatingBoss, bossId) then
      self.m_Enable = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsWorldCombatTarget, bossId)
    else
      self.m_Enable = true
    end
    Log.Debug("RocoSkillAction:OnActionInitialized", self.m_Enable, self:GetSkillObj():GetDisplayName(), self.GUID, config.id, config.genre)
  end
end

return RocoSkillAction
