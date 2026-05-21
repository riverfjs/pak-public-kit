local JsonUtils = require("Common.JsonUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local ServerData = require("Common.LocalServer.LocalBattleRSPTable")
local CopingSkillPerformAutoBattle = {}
local configFilename = "AutoPerformBattleCount"
local TestNodeIdx = 1

function CopingSkillPerformAutoBattle:Enable()
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_STATE_SELECT, BattleEvent.FX_PERF_ON_SKILL_PLAY_START, BattleEvent.FX_PERF_ON_SKILL_PLAY_PAUSE, BattleEvent.PLAYER_SPAWNED, BattleEvent.PET_LOAD_MODE_LOVER, BattleEvent.StartSkill_AutoPerform)
  self.fileName = configFilename
  self.isRunning = true
  self.skillIndex = 0
  self.isFirstEnter = true
  self.isFinished = false
  self.isStarted = false
  self.BulletTimeId = -1
  ServerData.values.CurSelectedPetPlayer = 1
  ServerData.values.CurSelectedPetEnemy = 401
  ServerData.AutoTestOver = false
  ServerData.values.CopingSkillAutoPerform = self
  self.roundSkillList = {}
  self:LoadFile()
  self.config = _G.DataConfigManager:GetSceneResConf(10003)
  self.config.source = "/Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/L_Bigworld_01_Release"
  if self.performData.worldPath then
    self.config.source = self.performData.worldPath
  end
  if self.performData.vfxQuality then
    local vfxQuality = string.lower(self.performData.vfxQuality)
    Log.Debug("setting effects graphic quality: " .. vfxQuality)
    self:SetEffectGraphicQuality(vfxQuality)
  end
  _G.StartAutoGCByTick = 0
end

function CopingSkillPerformAutoBattle:SetEnterBattleInfo(RSPTable)
  RSPTable.SetEnterBattleInfo(self.performData.weather, self.performData.pos, self.performData.water_type)
end

function CopingSkillPerformAutoBattle:SetEffectGraphicQuality(vfxQuality)
  if "high" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.High)
  elseif "medium" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.Medium)
  elseif "low" == vfxQuality then
    UE4.USkillBlueprintLibrary.SetEffectsQuality(UE4.ESkillEffectsQuality.Low)
  end
end

function CopingSkillPerformAutoBattle:GetOpenID()
  if self.performData and self.performData.openID then
    return self.performData.openID
  else
    self.performData = JsonUtils.LoadSaved(configFilename, {})
    if self.performData then
      return self.performData.openID
    end
  end
end

function CopingSkillPerformAutoBattle:LoadFile()
  self.performData = JsonUtils.LoadSaved(self.fileName)
  if not self.performData then
    Log.Error("CopingSkillPerformAutoBattle:LoadFile")
    self.performData = {}
    self.performData.worldPath = "/Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/L_Bigworld_01_Release"
    self.performData.openID = "zgx601"
    self.performData.pos = {
      x = 443038,
      y = 669758,
      z = 1154
    }
    self.performData.vfxQuality = "high"
    self.performData.IsShowBattleUI = true
    self.performData.IsShowBattleEffect = true
    self.performData.IsShowBattleModel = true
    self.performData.enableUnrealStats = false
    self.performData.enableOverdrawProfiling = false
    self.performData.enableConsoleCommand = false
    self.performData.playSkillStopAt = 500
    self.performData.playSkillStartAt = 0
    self.performData.blackSkillPath = {
      "/Game/ArtRes/Effects/G6Skill/Jineng/200001",
      "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Wat_7050310_QSDT",
      "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Mar_FT_714004",
      "/Game/ArtRes/Effects/G6Skill/Jineng/G6_Wor_YH_212015"
    }
    self.performData.weather = 7
    self.performData.water_type = 0
    JsonUtils.DumpSaved(self.fileName, self.performData)
  end
  if not self.performData.IsShowBattleUI then
    function _G.BattleManager.OpenBattleMainWindow()
    end
    
    function NRCModuleBase.LogError()
    end
    
    local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
    
    function BattleUtils.HasMainWindow()
      return true
    end
    
    local BuffAEffectPopupComponent = require("NewRoco.Modules.Core.Battle.Entity.Components.BuffEffectPopup.BuffAEffectPopupComponent")
    
    function BuffAEffectPopupComponent.DoPopup()
    end
  end
  self.skillIndex = self.performData.playSkillStartAt or 0
  self:CollectPerformSkillList()
  if self.performData.playSkillStopAt then
    Log.Debug("CopingSkillPerformAutoBattle:LoadFile() playSkillStopAt = " .. self.performData.playSkillStopAt, #self.roundSkillList)
  else
    Log.Debug("CopingSkillPerformAutoBattle:LoadFile() Num of Skills to perform = " .. #self.roundSkillList)
  end
end

function CopingSkillPerformAutoBattle:CollectPerformSkillList()
  local blackSkillDict = {}
  for _, black in ipairs(self.performData.blackSkillPath or {}) do
    blackSkillDict[black] = true
  end
  local roundSkillList = JsonUtils.LoadSaved(self.fileName .. "_performSkillList")
  if roundSkillList and #roundSkillList > 0 then
    self.roundSkillList = {}
    for i, v in ipairs(roundSkillList) do
      local roundSkill = roundSkillList[i]
      local beCountId = roundSkill.beCountId
      local beCountConfig = _G.SkillUtils.GetSkillConf(beCountId)
      local countId = roundSkill.countId
      local countConfig = _G.SkillUtils.GetSkillConf(countId)
      if beCountConfig and countConfig and not blackSkillDict[beCountConfig.res_id] and not blackSkillDict[countConfig.res_id] then
        table.insert(self.roundSkillList, roundSkill)
      end
    end
    return
  end
  self.roundSkillList = {}
  local tInsert = table.insert
  local counterSkillList, beCounterSkillList = SkillPerformAutoBattleUtils:GetCoping()
  local countSkillMap = {}
  for i, v in ipairs(counterSkillList) do
    if not blackSkillDict[v.res_id] then
      if not countSkillMap[v.skillType] then
        countSkillMap[v.skillType] = {}
      end
      tInsert(countSkillMap[v.skillType], v)
    end
  end
  for i, v in ipairs(beCounterSkillList) do
    if not blackSkillDict[v.res_id] then
      local skillCfg = _G.SkillUtils.GetSkillConf(v.id)
      local countSkillType = self:GetCountSkillType(skillCfg.Skill_Type)
      local countSkillArray = countSkillMap[countSkillType]
      local countSkill = countSkillArray[math.random(1, #countSkillArray)]
      tInsert(self.roundSkillList, {
        beCountId = skillCfg.id,
        countId = countSkill.id
      })
    end
  end
  JsonUtils.DumpSaved(self.fileName .. "_performSkillList", self.roundSkillList)
end

function CopingSkillPerformAutoBattle:GetCountSkillType(beCountSkillType)
  if beCountSkillType == Enum.SkillType.ST_DAMAGE then
    return Enum.SkillType.ST_DEFEND
  elseif beCountSkillType == Enum.SkillType.ST_STATUS then
    return Enum.SkillType.ST_DAMAGE
  elseif beCountSkillType == Enum.SkillType.ST_DEFEND then
    return Enum.SkillType.ST_STATUS
  end
end

function CopingSkillPerformAutoBattle:GetBattlePosition()
  if self.performData and self.performData.pos then
    return UE4.FVector(self.performData.pos.x, self.performData.pos.y, self.performData.pos.z)
  end
end

function CopingSkillPerformAutoBattle:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.ROUND_STATE_SELECT then
    Log.Warning("CopingSkillPerformAutoBattle:OnBattleEvent ", ...)
    BattleSkillManager:PreLoadSingleResInternal(BattleConst.CounterSkillPreFx)
    BattleSkillManager:PreLoadSingleResInternal(BattleConst.CounterSkillPreNpc)
    self.isStarted = true
    _G.DelayManager:DelayFrames(30, self.ReleaseSkillRes, self)
    _G.DelayManager:DelayFrames(60, self.PerformNextSkill, self)
  elseif eventName == BattleEvent.FX_PERF_ON_SKILL_PLAY_START then
    if self.performData.enableConsoleCommand then
      local cmd = string.format("FxPerf.Start %s_%s %f", self.skill_cast.skill_id, self.SkillObject:GetDisplayName(), 0)
      UE4.UNRCStatics.ExecConsoleCommand(cmd)
    end
  elseif eventName == BattleEvent.FX_PERF_ON_SKILL_PLAY_PAUSE then
    if self.performData.enableConsoleCommand then
      local cmd = string.format("FxPerf.Pause")
      UE4.UNRCStatics.ExecConsoleCommand(cmd)
    end
  elseif eventName == BattleEvent.PLAYER_SPAWNED then
    if self.performData and not self.performData.IsShowBattleModel then
      local player = (...)
      self:HideModel(player.model)
    end
  elseif eventName == BattleEvent.PET_LOAD_MODE_LOVER then
    if self.performData and not self.performData.IsShowBattleModel then
      local pet = (...)
      self:HideModel(pet.model)
    end
  elseif eventName == BattleEvent.StartSkill_AutoPerform and self.performData and not self.performData.IsShowBattleEffect then
    local skillObject = (...)
    self:HideSkillEffect(skillObject)
  end
end

function CopingSkillPerformAutoBattle:HideModel(model)
  if not model then
    return
  end
  local mesh = model:GetComponentByClass(UE.USkeletalMeshComponent)
  if mesh then
    mesh:SetVisibility(false)
    mesh:SetHiddenInGame(true)
  end
end

function CopingSkillPerformAutoBattle:HideSkillEffect(skillObject)
  if not skillObject then
    return
  end
  local actions = skillObject:GetAllActions()
  for i = 1, actions:Length() do
    local action = actions:Get(i)
    if action:IsA(UE.URocoPlayFxSystemAction) or action:IsA(UE.URocoPlayParticleEffectAction) or action:IsA(UE.URocoPlayProjectileEffectAction) or action:IsA(UE.URocoSpawnAction) or action:IsA(UE.URocoPlayAnimationAction) then
      action.m_Enable = false
    end
  end
end

function CopingSkillPerformAutoBattle:ReleaseSkillRes()
  local allPets = BattleManager.battlePawnManager:GetAllPets()
  for i = 1, #allPets do
    allPets[i].model:ClearMaterials()
  end
  collectgarbage("collect")
  UE4.UNRCStatics.ForceGarbageCollection(true)
  UE4.USkillRecordLibrary.ReleaseAllSkill()
end

function CopingSkillPerformAutoBattle:RefreshAllPets()
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for i, v in ipairs(pets) do
    self:RefreshSelfForSkillTest(v)
  end
  UE4.UNRCStatics.DisableBulletTime()
  local casterModel = self.caster and self.caster.model
  local targetModel = self.target and self.target.model
  if UE.UObject.IsValid(casterModel) then
    casterModel:K2_SetActorLocation(self.casterInitPosition, false, nil, false)
  end
  if UE.UObject.IsValid(targetModel) then
    targetModel:K2_SetActorLocation(self.targetInitPosition, false, nil, false)
  end
end

function CopingSkillPerformAutoBattle:RefreshSelfForSkillTest(pet)
  if pet.model then
    pet:SetScale(1.0)
    if not pet.card:CheckIsMimic() then
      pet.perception:PinOnTheGround()
    end
    pet:ResetRotation(true)
    pet.model:SetActorHiddenInGame(false)
    local mesh = pet.model:GetComponentByClass(UE4.USkeletalMeshComponent)
    if mesh then
      mesh:SetVisibility(true)
    end
    pet.model.RocoSkill:StopCurrentSkill()
    pet.model.CustomTimeDilation = 1
    local childs = pet.model.Children
    for i = 1, childs:Length() do
      local actor = childs:Get(i)
      actor.CustomTimeDilation = 1
    end
  end
end

function CopingSkillPerformAutoBattle:ClearAllPetsSkill()
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for _, pet in ipairs(pets) do
    pet:ClearSkill()
  end
end

function CopingSkillPerformAutoBattle:BattleFieldLeaveBattle()
  BattleManager:ClearBattle()
end

function CopingSkillPerformAutoBattle:PerformNextSkill()
  self:InitOnFirstEnter()
  self:RefreshAllPets()
  _G.BattleSkillManager:ClearCache()
  _G.BattleResourceManager:ReleaseAllCastSkillObject()
  _G.BattleResourceManager:ClearUClass()
  self.skillIndex = self.skillIndex + 1
  local playStopAt = self.performData.playSkillStopAt or #self.roundSkillList
  if self.performData and playStopAt >= self.skillIndex and self.skillIndex <= #self.roundSkillList then
    self:ClearState()
    self.delayForStuck = _G.DelayManager:DelayFrames(450, function(self)
      local skillData = self.roundSkillList[self.skillIndex]
      Log.Debug(string.format("CopingSkillPerformAutoBattle:PerformDelay %d_%d_%d", self.skillIndex, skillData.beCountId, skillData.countId))
      self.delayForStuck = nil
      self:PerformNextSkill()
    end, self)
    self:PlayBeCountSkill()
  else
    _G.DelayManager:DelayFrames(150, self.Disable, self)
  end
end

function CopingSkillPerformAutoBattle:ClearState()
  self.currentCompleteIdx = 0
  self.isCount = false
  self:ClearStuckDelay()
  self:LeaveBulletTime()
  if self.delayNextId then
    _G.DelayManager:CancelDelayById(self.delayNextId)
    self.delayNextId = nil
  end
end

function CopingSkillPerformAutoBattle:InitOnFirstEnter()
  if not self.isFirstEnter then
    return
  end
  self.isFirstEnter = false
  local battlePawnManager = _G.BattleManager.battlePawnManager
  self.caster = battlePawnManager:GetPetByGuid(1)
  self.target = battlePawnManager:GetPetByGuid(401)
  self.casterInitPosition = self.caster.model:K2_GetActorLocation()
  self.targetInitPosition = self.target.model:K2_GetActorLocation()
  if not self.caster or not self.target then
    Log.Error("CopingSkillPerformAutoBattle:Enable Error PerformPlay Is Null")
    return
  end
  local weather = self.performData.weather or 4
  local Instance = UE.UNRCPlatformGameInstance.GetInstance()
  local EnvSys = Instance and Instance:GetWorldSubSystem()
  EnvSys:SetWeatherStat(weather, true, false)
  if self.performData.enableConsoleCommand then
    if self.performData.enableUnrealStats then
      UE4.UNRCStatics.ExecConsoleCommand("FxPerf.Start stats")
    else
      UE4.UNRCStatics.ExecConsoleCommand("FxPerf.Start")
    end
    UE4.UNRCStatics.ExecConsoleCommand("memreport -full")
    UE4.UNRCStatics.ExecConsoleCommand("WorldTileTool.FreezeWorldComposition 1")
    UE4.UNRCStatics.ExecConsoleCommand("show DynamicShadows")
    UE4.UNRCStatics.ExecConsoleCommand("r.TriangleBasedShadowing 0")
    UE4.UNRCStatics.ExecConsoleCommand("DisableAllScreenMessages")
    if self.performData.enableOverdrawProfiling then
      UE4.UFxPerfToolEditorFunctionLibrary.SetViewMode("simpleoverdraw")
      UE4.UNRCStatics.ExecConsoleCommand("r.ShaderComplexity.PostProcess.Enable 1")
    end
  end
end

function CopingSkillPerformAutoBattle:PlayBeCountSkill()
  if not (self.caster and self.caster.model) or not self.caster.model.RocoSkill then
    self.caster = battlePawnManager:GetPetByGuid(1)
    if not (self.caster and self.caster.model) or not self.caster.model.RocoSkill then
      return
    end
  end
  local skillData = self.roundSkillList[self.skillIndex]
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillData.beCountId, true)
  if not SkillConf then
    Log.Error("CopingSkillPerformAutoBattle: Skill is not exist ", skillData.beCountId)
    self:PerformNextSkill()
    return
  end
  BattleResourceManager:LoadClassAsync(self, SkillConf.res_id, self.OnBeCountSkillLoad, function(_caller)
    self:PerformNextSkill()
  end)
end

function CopingSkillPerformAutoBattle:OnBeCountSkillLoad(skillClass)
  local skillData = self.roundSkillList[self.skillIndex]
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillData.beCountId, true)
  if not skillClass then
    Log.Error("CopingSkillPerformAutoBattle: skillClass is not exist ", SkillConf.res_id)
    self:PerformNextSkill()
    return
  end
  local skillObj = self.caster.model.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("CopingSkillPerformAutoBattle: skillObj is not exist ", SkillConf.res_id)
    self:PerformNextSkill()
    return
  end
  local hasCopingEvent = SkillUtils.SkillObjHasLuaEvent(skillObj, UE4.ERocoSkillLuaEventType.SkillCoping) or SkillUtils.SkillObjHasLuaEvent(skillObj, UE4.ERocoSkillLuaEventType.SkillCounter)
  if not hasCopingEvent then
    Log.Error("CopingSkillPerformAutoBattle: skillObj is not Coping Event ", SkillConf.res_id)
    self:PerformNextSkill()
    return
  end
  local countSkillConf = _G.DataConfigManager:GetSkillConf(skillData.countId, true)
  if not countSkillConf then
    Log.Error("CopingSkillPerformAutoBattle: countId is not Exit ", skillData.countId)
    self:PerformNextSkill()
    return
  end
  skillObj:SetBeCounter(TestNodeIdx, countSkillConf.Skill_Type)
  skillObj:SetCaster(self.caster.model)
  skillObj:SetTargets({
    self.target.model
  })
  skillObj:RegisterEventCallback("End", self, self.BeCountSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.BeCountSkillComplete)
  skillObj:RegisterEventCallback("AllHitEnd", self, self.OnAllHitEnd)
  skillObj:RegisterEventCallback("SkillCoping", self, self.OnCountSkill)
  skillObj:RegisterEventCallback("SkillCounter", self, self.OnCountSkill)
  self:SetSkillBySkillType(skillObj, SkillConf.Skill_Type)
  UE4Helper.PrintScreenMsg(string.format("CopingSkillPerformAutoBattle:PlayBeCountSkill %d_%d\239\188\140resPath:%s", self.skillIndex, SkillConf.id, SkillConf.res_id))
  self.beCounterSkill = skillObj
  self.caster.model.RocoSkill:LoadAndPlaySkill(skillObj)
end

function CopingSkillPerformAutoBattle:BeCountSkillComplete(event, skillObj)
  if self.counterSkill then
    UE4.RocoCopingSkillUtils.ClearDefendShieldActor(self.counterSkill)
  end
  self:OnSkillComplete(event, skillObj)
  self.beCountSkill = nil
end

function CopingSkillPerformAutoBattle:OnAllHitEnd()
  if self.counterSkill then
    UE4.RocoCopingSkillUtils.ClearDefendShieldActor(self.counterSkill)
  end
end

function CopingSkillPerformAutoBattle:SetSkillBySkillType(skillObj, skillType)
  if skillType == Enum.SkillType.ST_DAMAGE then
    SkillUtils.SetRangedMultiAtkTimes(skillObj, 3)
  end
  if skillType == Enum.SkillType.ST_DEFEND then
    UE4.RocoCopingSkillUtils.ActiveDefendShieldLoop(skillObj)
  end
end

function CopingSkillPerformAutoBattle:OnCountSkill(skillObj, skillType)
  if self.isCount then
    Log.Debug("CopingSkillPerformAutoBattle:OnCountSkill, \229\186\148\229\175\185\230\138\128\229\183\178\231\187\143\229\156\168\230\146\173\230\148\190\228\184\173\228\186\134  \233\133\141\228\186\134\229\164\154\228\184\170\228\186\139\228\187\182\230\136\150\232\183\179\232\189\172\229\143\175\232\131\189\228\188\154\229\175\188\232\135\180\232\191\153\228\184\170\233\151\174\233\162\152")
    return
  end
  if not self.target.model or not self.target.model.RocoSkill then
    Log.Debug("CopingSkillPerformAutoBattle:OnCountSkill, \231\155\174\230\160\135\229\174\160\231\137\169\233\148\153\232\175\175 ", self.target:GetName())
    return
  end
  self.isCount = true
  local skillData = self.roundSkillList[self.skillIndex]
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillData.countId, true)
  self.BulletTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.Counter, UE.EBulletTimeChangeType.Change, _G.UE4Helper.GetCurrentWorld(), BattleConst.Show.CounterSkillTimeDilation, UE.EBulletTimeChangeType.Keep, {
    self.target.model
  }, 1)
  local preCountSkill = "NewRoco.Modules.Core.Battle.BattleCore.Pieces.Instances.BattlePieceCounterSkillPrePlay"
  BattlePiecesManager:Play(preCountSkill, self.target, self.PlayCountSkill, self, true)
  Log.Debug(string.format("CopingSkillPerformAutoBattle:OnCountSkill %d_%d", self.skillIndex, SkillConf.id))
end

function CopingSkillPerformAutoBattle:PlayCountSkill()
  local skillData = self.roundSkillList[self.skillIndex]
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillData.countId, true)
  if not SkillConf then
    Log.Error("CopingSkillPerformAutoBattle:PlayCountSkill SkillConf is not exist ", skillData.countId)
    self:OnSkillComplete()
    return
  end
  BattleResourceManager:LoadClassAsync(self, SkillConf.res_id, self.OnCountSkillLoad, function(_caller)
    self:OnSkillComplete()
  end)
end

function CopingSkillPerformAutoBattle:OnCountSkillLoad(skillClass)
  local skillData = self.roundSkillList[self.skillIndex]
  local SkillConf = _G.DataConfigManager:GetSkillConf(skillData.countId, true)
  if not SkillConf then
    Log.Error("CopingSkillPerformAutoBattle:PlayCountSkill SkillConf is not exist ", skillData.countId)
    self:OnSkillComplete()
    return
  end
  if not skillClass then
    Log.Error("CopingSkillPerformAutoBattle:PlayCountSkill skillClass is not exist ", SkillConf.res_id)
    self:OnSkillComplete()
    return
  end
  local skillObj = self.target.model.RocoSkill:FindOrAddSkillObj(skillClass)
  if not skillObj then
    Log.Error("CopingSkillPerformAutoBattle:PlayCountSkill skillObj is not exist ", SkillConf.res_id)
    self:OnSkillComplete()
    return
  end
  skillObj:SetCounter(true)
  skillObj:SetCaster(self.target.model)
  skillObj:SetTargets({
    self.caster.model
  })
  skillObj:RegisterEventCallback("StopBulletTime", self, self.LeaveBulletTime)
  skillObj:RegisterEventCallback("StateEffectEnd", self, self.OnStateEffectEnd)
  skillObj:RegisterEventCallback("End", self, self.CountSkillComplete)
  skillObj:RegisterEventCallback("PreEnd", self, self.CountSkillComplete)
  self:SetSkillBySkillType(skillObj, SkillConf.Skill_Type)
  UE4Helper.PrintScreenMsg(string.format("CopingSkillPerformAutoBattle:PlayCountSkill %d_%d\239\188\140resPath:%s", self.skillIndex, SkillConf.id, SkillConf.res_id))
  self.counterSkill = skillObj
  self.target.model.RocoSkill:LoadAndPlaySkill(skillObj)
end

function CopingSkillPerformAutoBattle:LeaveBulletTime()
  if self.BulletTimeId and self.BulletTimeId >= 0 then
    _G.BattleBulletTimeManager:LeaveBulletTime(self.BulletTimeId)
    self.BulletTimeId = -1
  end
end

function CopingSkillPerformAutoBattle:CountSkillComplete(event, skillObj)
  skillObj:SetCounter(false)
  self:LeaveBulletTime()
  self:OnSkillComplete(event, skillObj)
  self.counterSkill = nil
  if self.beCountSkill then
    self.beCountSkill:SetBeCounter(0, Enum.SkillType.ST_NONE)
  end
end

function CopingSkillPerformAutoBattle:OnStateEffectEnd()
  if self.beCounterSkill then
    UE4.RocoCopingSkillUtils.ClearDefendShieldEffect(self.beCounterSkill)
  end
end

function CopingSkillPerformAutoBattle:OnSkillComplete(event, skillObj)
  self.currentCompleteIdx = self.currentCompleteIdx + 1
  if 2 == self.currentCompleteIdx then
    self:ClearState()
    self.delayNextId = _G.DelayManager:DelayFrames(30, self.PerformNextSkill, self)
  end
end

function CopingSkillPerformAutoBattle:ClearStuckDelay()
  if self.delayForStuck then
    _G.DelayManager:CancelDelayById(self.delayForStuck)
    self.delayForStuck = nil
  end
end

function CopingSkillPerformAutoBattle:Disable()
  UE4.UNRCStatics.ExecConsoleCommand("nrc.DebugAutoBattle 0")
  _G.BattleEventCenter:UnBind(self)
  if not self.isFirstEnter then
    self.isFinished = true
    Log.Debug("CopingSkillPerformAutoBattle:Disable, auto battle test finished")
    if self.performData.enableConsoleCommand then
      UE4.UNRCStatics.ExecConsoleCommand("FxPerf.Stop")
      UE4.UNRCStatics.ExecConsoleCommand("memreport -full")
      if self.performData.enableOverdrawProfiling then
        UE4.UFxPerfToolEditorFunctionLibrary.SetViewMode("lit")
        UE4.UNRCStatics.ExecConsoleCommand("r.ShaderComplexity.PostProcess.Enable 0")
      end
      UE4.UNRCStatics.ExecConsoleCommand("WorldTileTool.FreezeWorldComposition 0")
      UE4.UNRCStatics.ExecConsoleCommand("show DynamicShadows")
      UE4.UNRCStatics.ExecConsoleCommand("r.TriangleBasedShadowing 0")
      UE4.UNRCStatics.ExecConsoleCommand("EnableAllScreenMessages")
    end
  end
  self.isRunning = false
  self.roundSkillList = {}
end

return CopingSkillPerformAutoBattle
