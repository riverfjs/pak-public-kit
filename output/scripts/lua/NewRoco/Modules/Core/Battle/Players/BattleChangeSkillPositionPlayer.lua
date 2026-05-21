local BattlePlayerBase = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePlayerBase")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local PriorityEnum = require("PriorityEnum")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local Base = BattlePlayerBase
local BattleChangeSkillPositionPlayer = Base:Extend("BattleChangeSkillPositionPlayer")
local LerpToTargetTolerance = 1
local skillItemTeleportAnimationSpeed = 555
local edgeAngleOffset = 6
local maxMovingSpeedMultiplier = BattleConst.ChangeSkillPositionParams.SkillMovingSpeedMultiplier

function BattleChangeSkillPositionPlayer:Ctor(skillListWidget, skillItemClass)
  Base.Ctor(self)
  self.skillListWidget = skillListWidget
  self.skillItemClass = skillItemClass
  self.skill_pos_infos = {}
  local transmissionSpeedRate = _G.BattleManager.battleRuntimeData.widgetSpeed.TransmissionSpeedRate
  local ChangeSkillPositionParams = BattleConst.ChangeSkillPositionParams
  local timeMultiplier = 1
  if transmissionSpeedRate > 0 then
    timeMultiplier = 1 / transmissionSpeedRate
  else
    timeMultiplier = 999
  end
  self.TimeBeforeAnimation = ChangeSkillPositionParams.TimeBeforeAnimation * timeMultiplier
  self.SkillGoOutTime = ChangeSkillPositionParams.SkillGoOutTime * timeMultiplier
  maxMovingSpeedMultiplier = ChangeSkillPositionParams.SkillMovingSpeedMultiplier * transmissionSpeedRate
  self.TimeBetweenMovingAndGoBack = ChangeSkillPositionParams.TimeBetweenMovingAndGoBack * timeMultiplier
  self.SkillGaBackTime = ChangeSkillPositionParams.SkillGaBackTime * timeMultiplier
end

function BattleChangeSkillPositionPlayer:Reset()
  self.skill_pos_infos = {}
  self.performNode = nil
end

function BattleChangeSkillPositionPlayer:Play(performNode)
  self:Reset()
  if self.isTestMode then
    local changeInfo1 = {
      type = 3,
      old_pos = 1,
      new_pos = 3,
      skill_id = 707001000
    }
    local changeInfo2 = {
      type = 2,
      old_pos = 2,
      new_pos = 2,
      skill_id = 707001000
    }
    local changeInfo3 = {
      type = 4,
      old_pos = 3,
      new_pos = 1,
      skill_id = 707001000
    }
    local changeInfo4 = {
      type = 2,
      old_pos = 4,
      new_pos = 4,
      skill_id = 707001000
    }
    local originalChangeInfoList = {
      changeInfo1,
      changeInfo2,
      changeInfo3,
      changeInfo4
    }
    self.skill_pos_infos = originalChangeInfoList
    au.Launch(self:PlayAsync(), function(ok, resultOrErrorMessage)
      if not ok then
        Log.Error("BattleChangeSkillPositionPlayer:Play error ", resultOrErrorMessage)
      end
    end)
    return
  end
  self.performNode = performNode
  local performInfo = performNode:GetInfo()
  self.skill_pos_change = performInfo.skill_pos_change
  self.skill_pos_infos = performInfo.skill_pos_change.skill_pos_infos
  local petId = performInfo.skill_pos_change.pet_id
  local battlePet = _G.BattleManager.battlePawnManager:GetPetByGuid(petId)
  local battlePetCard = battlePet and battlePet.card
  local battlePetOwner = battlePetCard and battlePetCard.owner
  local skillComponent = battlePet and battlePet.skillComponent
  local battleMainWindow = BattleUtils.GetMainWindow()
  if battleMainWindow then
    battleMainWindow.SkillPanelLoader:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.skillListWidget = battleMainWindow.SkillPanelLoader:GetPanel()
  end
  local teamPlayer = _G.BattleManager.battlePawnManager:GetTeamPlayer(BattleEnum.Team.ENUM_TEAM)
  if not battlePetOwner or battlePetOwner ~= teamPlayer then
    Log.Info("BattleChangeSkillPositionPlayer:Play \228\184\141\230\152\175\229\183\177\230\150\185\231\142\169\229\174\182\233\152\159\228\188\141\231\154\132\228\188\160\229\138\168\232\161\168\230\188\148\229\183\178\232\183\179\232\191\135")
    self:Finish()
    return
  end
  if not self.skillListWidget then
    self:Finish()
    return
  end
  if not self.skill_pos_infos then
    self:Finish()
    return
  end
  if BattleUtils.IsPvp() and BattleUtils.IsWatchingBattle() then
    local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    if playerSettings then
      local observeMode = BattleUtils.GetObserveModeFromSystemSettings(playerSettings)
      if observeMode == ProtoEnum.ObserveBattleMode.OBM_MODE_1 then
      elseif observeMode == ProtoEnum.ObserveBattleMode.OBM_MODE_2 then
        Log.Info("BattleChangeSkillPositionPlayer:Play PVP \232\167\130\230\136\152\229\164\132\228\186\142\230\168\161\229\188\143 2\239\188\140\228\188\160\229\138\168\232\161\168\230\188\148\229\183\178\232\183\179\232\191\135")
        self:Finish()
        return
      end
    end
  end
  local skillPoseInfosBackup = self.skill_pos_infos
  if skillComponent then
    local prevSkillDisplayInfo = skillComponent:GetSkillDisplayInfo()
    local prevGlobalSkillList = prevSkillDisplayInfo and prevSkillDisplayInfo.globalSkillList or {}
    local prevSlotIndexToSkill = prevSkillDisplayInfo and prevSkillDisplayInfo.slotIndexToSkill or {}
    local nextSlotIndexToSkill = {}
    local newSkillPoseInfos = {}
    local oldPosToNewPosMap = {}
    for i, info in ipairs(self.skill_pos_infos) do
      local skillId = info and info.skill_id
      skillId = skillId and _G.SkillUtils.CheckSkillId(skillId)
      local skillEntity = skillComponent:GetSkillBySkillID(skillId)
      local skillEntitySrc = skillComponent:GetHeadOfChangeSrcSkillChain(skillEntity)
      local skillIdSrc = skillEntitySrc and skillEntitySrc.skill_id
      skillIdSrc = skillIdSrc and _G.SkillUtils.CheckSkillId(skillIdSrc)
      local oldPos = info and info.old_pos or -1
      local newPos = info and info.new_pos or -1
      local skillInOldPos = prevSlotIndexToSkill[oldPos]
      local skillIdOldPos = skillInOldPos and skillInOldPos.skill_id
      skillIdOldPos = skillIdOldPos and _G.SkillUtils.CheckSkillId(skillIdOldPos)
      local skillInOldPosSrc = skillComponent:GetHeadOfChangeSrcSkillChain(skillInOldPos)
      local skillIdInOldPosSrc = skillInOldPosSrc and skillInOldPosSrc.skill_id
      skillIdInOldPosSrc = skillIdInOldPosSrc and _G.SkillUtils.CheckSkillId(skillIdInOldPosSrc)
      local oldPosSkillMatch = skillIdSrc and skillIdSrc == skillIdInOldPosSrc or false
      local newPosSlotAvailable = nil == nextSlotIndexToSkill[newPos]
      local nextInfo = {}
      table.copy(info, nextInfo)
      if oldPosSkillMatch and skillIdOldPos ~= skillIdInOldPosSrc and skillIdOldPos then
        nextInfo.skill_id = skillIdOldPos
      end
      if not oldPosSkillMatch then
        do
          local infoString = table.tostring(nextInfo)
          Log.ErrorFormat("BattleChangeSkillPositionPlayer:Play \228\188\160\229\138\168\230\149\176\230\141\174 %s old pos \228\184\142\229\142\159\228\189\141\231\189\174\230\138\128\232\131\189 id \228\184\141\231\155\184\231\172\166\239\188\140\229\142\159\228\189\141\231\189\174\230\138\128\232\131\189 id \228\184\186 %s", infoString, tostring(skillIdInOldPosSrc))
        end
      elseif not newPosSlotAvailable then
        do
          local skillInNewPos = nextSlotIndexToSkill[newPos]
          local skillIdINewPos = skillInNewPos and skillInNewPos.skill_id
          local infoString = table.tostring(nextInfo)
          Log.ErrorFormat("BattleChangeSkillPositionPlayer:Play \228\188\160\229\138\168\230\149\176\230\141\174 %s \231\154\132\231\155\174\230\160\135\228\189\141\231\189\174\229\183\178\231\187\143\232\162\171\229\133\182\228\187\150\230\138\128\232\131\189\229\141\160\231\148\168\239\188\140\231\155\174\230\160\135\228\189\141\231\189\174\230\138\128\232\131\189 id \228\184\186 %s", infoString, tostring(skillIdINewPos))
        end
      else
        table.insert(newSkillPoseInfos, nextInfo)
        nextSlotIndexToSkill[newPos] = skillInOldPos
        oldPosToNewPosMap[oldPos] = newPos
      end
    end
    for i = 1, 4 do
      local skillInOldPos = prevSlotIndexToSkill[i]
      local skillInNewPos = nextSlotIndexToSkill[i]
      local slotAvailable = nil == skillInNewPos
      local hasOldPosToNewPos = nil ~= oldPosToNewPosMap[i]
      if skillInOldPos and slotAvailable and not hasOldPosToNewPos then
        nextSlotIndexToSkill[i] = skillInOldPos
        local skillId = skillInOldPos and skillInOldPos.skill_id
        local info = {}
        info.skill_id = skillId
        info.old_pos = i
        info.new_pos = i
        info.type = ProtoEnum.SkillPosInfo.PosChangeType.PASSIVE_CHANGE
        table.insert(newSkillPoseInfos, info)
      end
    end
    local nextSkillDisplayInfo = {}
    nextSkillDisplayInfo.slotIndexToSkill = nextSlotIndexToSkill
    nextSkillDisplayInfo.globalSkillList = prevGlobalSkillList
    self.skill_pos_infos = newSkillPoseInfos
    skillComponent:SetSkillDisplayInfo(nextSkillDisplayInfo)
  end
  do
    local ok, errorMessage = self:CheckChangeInfoValid(self.skill_pos_infos)
    if not ok then
      Log.Error("\228\188\160\229\138\168\230\149\176\230\141\174\228\184\141\229\144\136\230\179\149\239\188\140\229\183\178\232\183\179\232\191\135\232\161\168\230\188\148", errorMessage)
      Log.Error("\229\142\159\229\167\139\232\161\168\230\188\148\230\149\176\230\141\174: ", table.tostring(skillPoseInfosBackup), "\231\187\143\232\191\135\228\191\174\233\165\176\231\154\132\232\161\168\230\188\148\230\149\176\230\141\174: ", table.tostring(self.skill_pos_infos))
      self:Finish()
      return
    end
  end
  self.performNode.performPlayer.hadChangeSkillPositionPlayer = true
  au.Launch(self:PlayAsync(battlePet), function(ok, resultOrErrorMessage)
    if not ok then
      Log.Error("BattleChangeSkillPositionPlayer:Play error", resultOrErrorMessage)
    end
    self:Finish()
  end)
end

local function LerpWithAlpha(source, target, alpha)
  return source + (target - source) * alpha
end

function BattleChangeSkillPositionPlayer:MoveSkillItemWithAngleAndRadius(currentSkillItem, originalAngle, targetAngle, originalRadius, targetRadius, originalRenderAngle, targetRenderAngle, time, enableElastic)
  time = time and time or 1
  local skillListWidget = self.skillListWidget
  local currentRadius = originalRadius
  local currentAngle = originalAngle
  local currentRenderAngle = originalRenderAngle
  local canvasPanelSlot = currentSkillItem.Slot
  local position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(currentRadius, currentAngle)
  canvasPanelSlot:SetPosition(position)
  local renderAngle = originalRenderAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
  local targetPosition = skillListWidget:CalculateSlotPositionByRadiusAndAngle(targetRadius, targetAngle)
  local FVector2D = UE.FVector2D
  local distance = FVector2D.Dist(targetPosition, position)
  local k = 0.75
  distance = math.max(1, distance)
  local interpSpeed = k * 1000 / distance
  local loopCount = 0
  local maxLoopCount = 500
  local currentTime = 0
  while time > currentTime do
    local deltaTime = a.wait(au.NextTick())
    currentTime = currentTime + deltaTime
    local percent = currentTime / time
    percent = math.clamp(percent, 0, 1)
    local currentRadiusAlpha = 0
    if enableElastic then
      currentRadiusAlpha = 1 - LuaMathUtils.Elastic(1 - percent, BattleConst.ChangeSkillPositionParams.SkillGaBackAmp, BattleConst.ChangeSkillPositionParams.SkillGaBackPeriod)
    else
      currentRadiusAlpha = 1 - LuaMathUtils.Expo(1 - percent)
    end
    currentRadius = LerpWithAlpha(originalRadius, targetRadius, currentRadiusAlpha)
    local currentAngleAlpha = 1 - LuaMathUtils.Quad(1 - percent)
    currentAngle = LerpWithAlpha(originalAngle, targetAngle, currentAngleAlpha)
    currentRenderAngle = LuaMathUtils.FInterpTo(currentRenderAngle, targetRenderAngle, deltaTime, 10)
    position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(currentRadius, currentAngle)
    distance = FVector2D.Dist(targetPosition, position)
    canvasPanelSlot:SetPosition(position)
    renderAngle = currentRenderAngle
    currentSkillItem:SetRenderTransformAngle(renderAngle)
    interpSpeed = k * 1000 / math.max(distance, 100)
    loopCount = loopCount + 1
  end
  currentRadius = targetRadius
  currentAngle = targetAngle
  position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(currentRadius, currentAngle)
  canvasPanelSlot:SetPosition(position)
  renderAngle = targetRenderAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
  return currentSkillItem
end

function BattleChangeSkillPositionPlayer:MoveSkillItemWithAngleSimple(currentSkillItem, originalAngle, targetAngle, radius, originalLinearVelocity, targetLinearVelocity, renderAngleAlign)
  local skillListWidget = self.skillListWidget
  local currentAngle = originalAngle
  local canvasPanelSlot = currentSkillItem.Slot
  local position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
  canvasPanelSlot:SetPosition(position)
  local renderAngle = currentAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
  currentSkillItem.currentAngle = nil
  local targetPosition = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, targetAngle)
  local FVector2D = UE.FVector2D
  local distance = FVector2D.Dist(targetPosition, position)
  local loopCount = 0
  local maxLoopCount = 500
  local currentLinearVelocity = originalLinearVelocity
  local targetDeltaAngleRad = math.rad(targetAngle - originalAngle)
  local targetDeltaArcLength = targetDeltaAngleRad * radius
  local currentDeltaArcLength = 0
  local accelerateLength = math.rad(edgeAngleOffset) * radius
  local currentLinearAcceleration = 0
  local maxLinearAcceleration = (originalLinearVelocity - targetLinearVelocity) * (originalLinearVelocity - targetLinearVelocity) / (2 * radius * math.rad(edgeAngleOffset))
  if targetLinearVelocity < originalLinearVelocity and accelerateLength > math.abs(currentDeltaArcLength - targetDeltaArcLength) then
    currentLinearAcceleration = maxLinearAcceleration
  elseif originalLinearVelocity < targetLinearVelocity and accelerateLength > math.abs(currentDeltaArcLength) then
    currentLinearAcceleration = maxLinearAcceleration
  end
  while math.abs(currentDeltaArcLength - targetDeltaArcLength) > LerpToTargetTolerance and loopCount <= maxLoopCount do
    local deltaTime = a.wait(au.NextTick())
    currentLinearVelocity = LuaMathUtils.LerpWithLength(currentLinearVelocity, targetLinearVelocity, currentLinearAcceleration * deltaTime)
    if 0 == currentLinearVelocity and currentLinearAcceleration then
      break
    end
    currentDeltaArcLength = LuaMathUtils.LerpWithLength(currentDeltaArcLength, targetDeltaArcLength, currentLinearVelocity * deltaTime)
    currentAngle = originalAngle + math.deg(currentDeltaArcLength / radius)
    position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
    distance = FVector2D.Dist(targetPosition, position)
    canvasPanelSlot:SetPosition(position)
    renderAngle = currentAngle
    currentSkillItem:SetRenderTransformAngle(renderAngle)
    currentLinearAcceleration = 0
    if targetLinearVelocity < originalLinearVelocity and accelerateLength > math.abs(currentDeltaArcLength - targetDeltaArcLength) then
      currentLinearAcceleration = maxLinearAcceleration
    elseif originalLinearVelocity < targetLinearVelocity and accelerateLength > math.abs(currentDeltaArcLength) then
      currentLinearAcceleration = maxLinearAcceleration
    end
    loopCount = loopCount + 1
  end
  currentSkillItem.currentAngle = currentAngle
  currentAngle = targetAngle
  position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
  renderAngle = currentAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
end

local function GenerateSmoothMovementCurveFunction(params)
  if params.t1 and params.v1 then
    params.x1 = 0.6666666666666666 * params.t1 * params.v1
  end
  if params.t1 and params.x1 then
    params.v1 = 1.5 * params.x1 / params.t1
  end
  if params.v1 and params.x1 then
    params.t1 = 1.5 * params.x1 / params.v1
  end
  local k = params.v1 / (params.t1 * params.t1)
  return {
    0,
    0,
    k * params.t1,
    -k / 3
  }
end

local function GenerateSmoothAccelerateMovementCurveFunction(accelerateLength, originalSpeed, targetSpeed)
  local aList = {
    0,
    0,
    0,
    0
  }
  local params = {}
  if 0 == originalSpeed then
    params.x1 = accelerateLength
    params.v1 = targetSpeed
    aList = GenerateSmoothMovementCurveFunction(params)
    
    local function f(t)
      return aList[4] * t * t * t + aList[3] * t * t + aList[2] * t + aList[1]
    end
    
    return {
      0,
      params.t1,
      f
    }
  else
    params.x1 = accelerateLength
    params.v1 = originalSpeed
    aList = GenerateSmoothMovementCurveFunction(params)
    
    local function f(t)
      return aList[4] * t * t * t + aList[3] * t * t + aList[2] * t + aList[1]
    end
    
    return {
      0,
      params.t1,
      f
    }
  end
end

function BattleChangeSkillPositionPlayer:MoveSkillItemWithAngleCurve(currentSkillItem, originalAngle, targetAngle, radius, originalLinearVelocity, targetLinearVelocity, accelerationLength)
  local skillListWidget = self.skillListWidget
  local currentAngle = originalAngle
  local canvasPanelSlot = currentSkillItem.Slot
  local position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
  canvasPanelSlot:SetPosition(position)
  local renderAngle = currentAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
  currentSkillItem.currentAngle = nil
  local targetPosition = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, targetAngle)
  local targetDeltaAngleRad = math.rad(targetAngle - originalAngle)
  local targetDeltaArcLength = math.abs(targetDeltaAngleRad * radius)
  local functionResult = GenerateSmoothAccelerateMovementCurveFunction(accelerationLength, originalLinearVelocity, targetLinearVelocity)
  local accelerateTime = functionResult[2]
  local commonMovementTime = math.max(0, (targetDeltaArcLength - accelerationLength) / math.max(originalLinearVelocity, targetLinearVelocity))
  local totalTime = accelerateTime + commonMovementTime
  local accelerateCurveFunction = functionResult[3]
  local curveFunction
  if originalLinearVelocity < targetLinearVelocity then
    function curveFunction(t)
      if t <= accelerateTime then
        return accelerateCurveFunction(t)
      elseif t >= totalTime then
        return targetDeltaArcLength
      else
        return accelerationLength + (t - accelerateTime) * targetLinearVelocity
      end
    end
  elseif targetLinearVelocity < originalLinearVelocity then
    function curveFunction(t)
      if t <= commonMovementTime then
        return t * originalLinearVelocity
      elseif t >= totalTime then
        return targetDeltaArcLength
      else
        return accelerateCurveFunction(t - commonMovementTime + accelerateTime) - accelerateCurveFunction(accelerateTime) + originalLinearVelocity * commonMovementTime
      end
    end
  elseif originalLinearVelocity == targetLinearVelocity then
    accelerateTime = 0
    totalTime = commonMovementTime
    
    function curveFunction(t)
      if t <= 0 then
        return 0
      elseif t >= totalTime then
        return targetDeltaArcLength
      else
        return t * originalLinearVelocity
      end
    end
  else
    return
  end
  local currentTime = 0
  local currentDeltaArcLength = 0
  while totalTime > currentTime do
    local deltaTime = a.wait(au.NextTick())
    currentTime = currentTime + deltaTime
    currentDeltaArcLength = curveFunction(currentTime)
    if targetAngle < originalAngle then
      currentDeltaArcLength = -currentDeltaArcLength
    end
    currentAngle = originalAngle + math.deg(currentDeltaArcLength / radius)
    position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
    canvasPanelSlot:SetPosition(position)
    renderAngle = currentAngle
    currentSkillItem:SetRenderTransformAngle(renderAngle)
  end
  currentAngle = targetAngle
  position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(radius, currentAngle)
  renderAngle = currentAngle
  currentSkillItem:SetRenderTransformAngle(renderAngle)
end

function BattleChangeSkillPositionPlayer:MoveSkillItemWithTeleportAnimation(currentSkillItem, moveInfo, currentRadius, linearSpeed)
  local skillListWidget = self.skillListWidget
  local originalAngle = moveInfo.originalAngle
  local targetAngle = moveInfo.targetAngle
  local newSkillItem = skillListWidget:TryGetNextPerformSkillItem(self.skillItemClass)
  self:InitSkillItem(newSkillItem, currentSkillItem.skillId)
  do
    local canvasPanelSlot = currentSkillItem.Slot
    local position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(currentRadius, originalAngle)
    canvasPanelSlot:SetPosition(position)
    local renderAngle = originalAngle
    currentSkillItem:SetRenderTransformAngle(renderAngle)
  end
  do
    local canvasPanelSlot = newSkillItem.Slot
    local position = skillListWidget:CalculateSlotPositionByRadiusAndAngle(currentRadius, targetAngle)
    canvasPanelSlot:SetPosition(position)
    local renderAngle = targetAngle
    newSkillItem:SetRenderTransformAngle(renderAngle)
  end
  local currentItemCutAnim = 1 == moveInfo.direction and currentSkillItem.Cut_up1 or currentSkillItem.Cut_down1
  local newItemCutAnim = 1 == moveInfo.direction and newSkillItem.Cut_up2 or newSkillItem.Cut_down2
  local currentAnimationPlayRate = linearSpeed / skillItemTeleportAnimationSpeed
  currentSkillItem:PlayAnimation(currentItemCutAnim, 0, 1, 0, currentAnimationPlayRate, false)
  newSkillItem:PlayAnimation(newItemCutAnim, 0, 1, 0, currentAnimationPlayRate, false)
  a.wait_all({
    a.wrap(function(callback)
      local Delegate = {
        currentSkillItem,
        function()
          currentSkillItem:UnbindAllFromAnimationFinished(currentItemCutAnim)
          callback()
        end
      }
      currentSkillItem:BindToAnimationFinished(currentItemCutAnim, Delegate)
    end)(),
    a.wrap(function(callback)
      local Delegate = {
        newSkillItem,
        function()
          newSkillItem:UnbindAllFromAnimationFinished(newItemCutAnim)
          callback()
        end
      }
      newSkillItem:BindToAnimationFinished(newItemCutAnim, Delegate)
    end)()
  })
  if currentSkillItem:IsAnimationPlaying(currentItemCutAnim) then
    currentSkillItem:StopAnimation(currentItemCutAnim)
  end
  if newSkillItem:IsAnimationPlaying(newItemCutAnim) then
    newSkillItem:StopAnimation(newItemCutAnim)
  end
  currentSkillItem:SetRenderOpacity(0)
  currentSkillItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  currentSkillItem:SetRenderOpacity(1)
  skillListWidget:RecyclePerformSkillItem(currentSkillItem)
  return newSkillItem
end

local function ChangeFirstStep(self, changeInfo, currentSkillItem)
  local newSkillItem = currentSkillItem
  local skillListWidget = self.skillListWidget
  local originalRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Main]
  local targetRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
  local angle = self.skillListWidget:GetAngleByTrackPosition({
    trackType = self.skillListWidget.TrackType.Main,
    index = changeInfo.old_pos
  })
  if changeInfo.old_pos == changeInfo.new_pos or changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.ACTIVE_CHANGE then
    targetRadius = originalRadius
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_DOWN then
    targetRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_UP then
    targetRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Internal] + 50
  end
  self:MoveSkillItemWithAngleAndRadius(currentSkillItem, angle, angle, originalRadius, targetRadius, skillListWidget:CalculateItemRenderAngleOnTrackWithAnyTrackAngle(skillListWidget.TrackType.Main, angle), angle, self.SkillGoOutTime)
  return newSkillItem
end

BattleChangeSkillPositionPlayer.ChangeFirstStep = a.sync(ChangeFirstStep)

local function ChangeSecondStep(self, changeInfo, currentSkillItem, noChangeInfoList)
  local newSkillItem = currentSkillItem
  if changeInfo.old_pos == changeInfo.new_pos then
    return newSkillItem
  end
  local skillListWidget = self.skillListWidget
  local noChangeMap = {}
  for i, info in ipairs(noChangeInfoList) do
    noChangeMap[info.old_pos] = true
  end
  if changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.ACTIVE_CHANGE then
    local moveInfoList = {}
    local originalAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.old_pos
    })
    local targetAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.new_pos
    })
    local currentRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Main]
    local currentIndex = changeInfo.old_pos
    local lastBeginIndex = currentIndex
    local lastEndIndex = -1
    while currentIndex ~= changeInfo.new_pos do
      local nextIndex = currentIndex + 1
      if nextIndex > skillListWidget.TrackSkillItemCount[skillListWidget.TrackType.Main] then
        nextIndex = 1
      end
      if currentIndex > nextIndex then
        local bottomEdge = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = currentIndex
        })
        local topEdge = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = nextIndex
        })
        local moveInfoFirst = {
          originalAngle = bottomEdge,
          targetAngle = bottomEdge - edgeAngleOffset,
          moveType = noChangeMap[currentIndex] and 2 or 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfoFirst)
        local moveInfoMiddle = {
          originalAngle = bottomEdge - edgeAngleOffset,
          targetAngle = topEdge + edgeAngleOffset,
          moveType = 2,
          direction = 2
        }
        table.insert(moveInfoList, moveInfoMiddle)
        local moveInfoLast = {
          originalAngle = topEdge + edgeAngleOffset,
          targetAngle = topEdge,
          moveType = noChangeMap[nextIndex] and 2 or 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfoLast)
      elseif not noChangeMap[currentIndex] and noChangeMap[nextIndex] then
        local edgeAngle = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = currentIndex
        }) - edgeAngleOffset
        local moveInfo = {
          originalAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = currentIndex
          }),
          targetAngle = edgeAngle,
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
        moveInfo = {
          originalAngle = edgeAngle,
          targetAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = nextIndex
          }),
          moveType = 2,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
      elseif noChangeMap[currentIndex] and not noChangeMap[nextIndex] then
        local edgeAngle = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = nextIndex
        }) + edgeAngleOffset
        local moveInfo = {
          originalAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = currentIndex
          }),
          targetAngle = edgeAngle,
          moveType = 2,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
        moveInfo = {
          originalAngle = edgeAngle,
          targetAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = nextIndex
          }),
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
      elseif noChangeMap[currentIndex] and noChangeMap[nextIndex] then
        local moveInfo = {
          originalAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = currentIndex
          }),
          targetAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = nextIndex
          }),
          moveType = 2,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
      else
        local moveInfo = {
          originalAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = currentIndex
          }),
          targetAngle = skillListWidget:GetAngleByTrackPosition({
            trackType = self.skillListWidget.TrackType.Main,
            index = nextIndex
          }),
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo)
      end
      currentIndex = nextIndex
    end
    local newMoveInfoList = {}
    local currentMoveType = -1
    local currentOriginalAngle = -1
    for i, info in ipairs(moveInfoList) do
      if -1 == currentMoveType then
        currentMoveType = info.moveType
        currentOriginalAngle = info.originalAngle
      end
      if i == #moveInfoList then
        local moveInfo = {
          originalAngle = currentOriginalAngle,
          targetAngle = info.targetAngle,
          moveType = currentMoveType,
          direction = 2
        }
        table.insert(newMoveInfoList, moveInfo)
      else
        local nextIndex = i + 1
        if moveInfoList[nextIndex].moveType ~= info.moveType then
          local moveInfo = {
            originalAngle = currentOriginalAngle,
            targetAngle = info.targetAngle,
            moveType = currentMoveType,
            direction = 2
          }
          table.insert(newMoveInfoList, moveInfo)
          currentMoveType = -1
          currentOriginalAngle = -1
        end
      end
    end
    moveInfoList = newMoveInfoList
    if 1 == #moveInfoList then
      local tmpOriginalAngle = moveInfoList[1].originalAngle
      do
        local tmpTargetAngle = moveInfoList[1].targetAngle
        local middleAngle = (tmpOriginalAngle + tmpTargetAngle) / 2
        moveInfoList = {}
        local moveInfo1 = {
          originalAngle = tmpOriginalAngle,
          targetAngle = middleAngle,
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo1)
        local moveInfo2 = {
          originalAngle = middleAngle,
          targetAngle = tmpTargetAngle,
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo2)
      end
    end
    local maxMovingSpeed = currentRadius * maxMovingSpeedMultiplier
    for i, moveInfo in ipairs(moveInfoList) do
      if 1 == moveInfo.moveType then
        if 1 == i then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, 0, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        elseif i == #moveInfoList then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, 0, edgeAngleOffset * math.rad(currentRadius))
        else
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        end
      elseif 2 == moveInfo.moveType then
        currentSkillItem = self:MoveSkillItemWithTeleportAnimation(currentSkillItem, moveInfo, currentRadius, maxMovingSpeed)
        newSkillItem = currentSkillItem
      end
    end
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.PASSIVE_CHANGE then
    local moveInfoList = {}
    local originalAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.old_pos
    })
    local targetAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.new_pos
    })
    local currentRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
    if originalAngle < targetAngle then
      local middleAngle = (originalAngle + targetAngle) / 2
      local moveInfo1 = {
        originalAngle = originalAngle,
        targetAngle = middleAngle,
        moveType = 1,
        direction = 1
      }
      table.insert(moveInfoList, moveInfo1)
      local moveInfo2 = {
        originalAngle = middleAngle,
        targetAngle = targetAngle,
        moveType = 1,
        direction = 1
      }
      table.insert(moveInfoList, moveInfo2)
    else
      local topAngle = skillListWidget:GetAngleByTrackPosition({
        trackType = self.skillListWidget.TrackType.Main,
        index = 1
      })
      do
        local bottomAngle = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = 4
        })
        local moveInfo1 = {
          originalAngle = originalAngle,
          targetAngle = topAngle + edgeAngleOffset,
          moveType = 1,
          direction = 1
        }
        local moveInfo2 = {
          originalAngle = topAngle + edgeAngleOffset,
          targetAngle = bottomAngle - edgeAngleOffset,
          moveType = 2,
          direction = 1
        }
        local moveInfo3 = {
          originalAngle = bottomAngle - edgeAngleOffset,
          targetAngle = targetAngle,
          moveType = 1,
          direction = 1
        }
        table.insert(moveInfoList, moveInfo1)
        table.insert(moveInfoList, moveInfo2)
        table.insert(moveInfoList, moveInfo3)
      end
    end
    local maxMovingSpeed = currentRadius * maxMovingSpeedMultiplier
    for i, moveInfo in ipairs(moveInfoList) do
      if 1 == moveInfo.moveType then
        if 1 == i then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, 0, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        elseif i == #moveInfoList then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, 0, edgeAngleOffset * math.rad(currentRadius))
        else
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        end
      elseif 2 == moveInfo.moveType then
        currentSkillItem = self:MoveSkillItemWithTeleportAnimation(currentSkillItem, moveInfo, currentRadius, maxMovingSpeed)
        newSkillItem = currentSkillItem
      end
    end
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_DOWN then
    local moveInfoList = {}
    local originalAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.old_pos
    })
    local targetAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.new_pos
    })
    local currentRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
    if originalAngle > targetAngle then
      local middleAngle = (originalAngle + targetAngle) / 2
      local moveInfo1 = {
        originalAngle = originalAngle,
        targetAngle = middleAngle,
        moveType = 1,
        direction = 2
      }
      table.insert(moveInfoList, moveInfo1)
      local moveInfo2 = {
        originalAngle = middleAngle,
        targetAngle = targetAngle,
        moveType = 1,
        direction = 2
      }
      table.insert(moveInfoList, moveInfo2)
    else
      local topAngle = skillListWidget:GetAngleByTrackPosition({
        trackType = self.skillListWidget.TrackType.Main,
        index = 1
      })
      do
        local bottomAngle = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = 4
        })
        local moveInfo1 = {
          originalAngle = originalAngle,
          targetAngle = bottomAngle - edgeAngleOffset,
          moveType = 1,
          direction = 2
        }
        local moveInfo2 = {
          originalAngle = bottomAngle - edgeAngleOffset,
          targetAngle = topAngle + edgeAngleOffset,
          moveType = 2,
          direction = 2
        }
        local moveInfo3 = {
          originalAngle = topAngle + edgeAngleOffset,
          targetAngle = targetAngle,
          moveType = 1,
          direction = 2
        }
        table.insert(moveInfoList, moveInfo1)
        table.insert(moveInfoList, moveInfo2)
        table.insert(moveInfoList, moveInfo3)
      end
    end
    local maxMovingSpeed = currentRadius * maxMovingSpeedMultiplier
    for i, moveInfo in ipairs(moveInfoList) do
      if 1 == moveInfo.moveType then
        if 1 == i then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, 0, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        elseif i == #moveInfoList then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, 0, edgeAngleOffset * math.rad(currentRadius))
        else
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        end
      elseif 2 == moveInfo.moveType then
        currentSkillItem = self:MoveSkillItemWithTeleportAnimation(currentSkillItem, moveInfo, currentRadius, maxMovingSpeed)
        newSkillItem = currentSkillItem
      end
    end
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_UP then
    local moveInfoList = {}
    local originalAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.old_pos
    })
    local targetAngle = skillListWidget:GetAngleByTrackPosition({
      trackType = self.skillListWidget.TrackType.Main,
      index = changeInfo.new_pos
    })
    local currentRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Internal] + 50
    if originalAngle < targetAngle then
      local middleAngle = (originalAngle + targetAngle) / 2
      local moveInfo1 = {
        originalAngle = originalAngle,
        targetAngle = middleAngle,
        moveType = 1,
        direction = 1
      }
      table.insert(moveInfoList, moveInfo1)
      local moveInfo2 = {
        originalAngle = middleAngle,
        targetAngle = targetAngle,
        moveType = 1,
        direction = 1
      }
      table.insert(moveInfoList, moveInfo2)
    else
      local topAngle = skillListWidget:GetAngleByTrackPosition({
        trackType = self.skillListWidget.TrackType.Main,
        index = 1
      })
      do
        local bottomAngle = skillListWidget:GetAngleByTrackPosition({
          trackType = self.skillListWidget.TrackType.Main,
          index = 4
        })
        local moveInfo1 = {
          originalAngle = originalAngle,
          targetAngle = topAngle + edgeAngleOffset,
          moveType = 1,
          direction = 1
        }
        local moveInfo2 = {
          originalAngle = topAngle + edgeAngleOffset,
          targetAngle = bottomAngle - edgeAngleOffset,
          moveType = 2,
          direction = 1
        }
        local moveInfo3 = {
          originalAngle = bottomAngle - edgeAngleOffset,
          targetAngle = targetAngle,
          moveType = 1,
          direction = 1
        }
        table.insert(moveInfoList, moveInfo1)
        table.insert(moveInfoList, moveInfo2)
        table.insert(moveInfoList, moveInfo3)
      end
    end
    local maxMovingSpeed = currentRadius * maxMovingSpeedMultiplier
    for i, moveInfo in ipairs(moveInfoList) do
      if 1 == moveInfo.moveType then
        if 1 == i then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, 0, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        elseif i == #moveInfoList then
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, 0, edgeAngleOffset * math.rad(currentRadius))
        else
          self:MoveSkillItemWithAngleCurve(currentSkillItem, moveInfo.originalAngle, moveInfo.targetAngle, currentRadius, maxMovingSpeed, maxMovingSpeed, edgeAngleOffset * math.rad(currentRadius))
        end
      elseif 2 == moveInfo.moveType then
        currentSkillItem = self:MoveSkillItemWithTeleportAnimation(currentSkillItem, moveInfo, currentRadius, maxMovingSpeed)
        newSkillItem = currentSkillItem
      end
    end
  end
  return newSkillItem
end

BattleChangeSkillPositionPlayer.ChangeSecondStep = a.sync(ChangeSecondStep)

local function ChangeThirdStep(self, changeInfo, currentSkillItem)
  local newSkillItem = currentSkillItem
  local skillListWidget = self.skillListWidget
  local originalRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
  local targetRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Main]
  local angle = self.skillListWidget:GetAngleByTrackPosition({
    trackType = self.skillListWidget.TrackType.Main,
    index = changeInfo.new_pos
  })
  if currentSkillItem.currentAngle then
    angle = currentSkillItem.currentAngle
    currentSkillItem.currentAngle = nil
  end
  if changeInfo.old_pos == changeInfo.new_pos or changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.ACTIVE_CHANGE then
    originalRadius = targetRadius
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_DOWN then
    originalRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.External]
  elseif changeInfo.type == ProtoEnum.SkillPosInfo.PosChangeType.SWAP_POS_UP then
    originalRadius = skillListWidget.TrackRadius[skillListWidget.TrackType.Internal] + 50
  end
  self:MoveSkillItemWithAngleAndRadius(currentSkillItem, angle, angle, originalRadius, targetRadius, angle, skillListWidget:CalculateItemRenderAngleOnTrackWithAnyTrackAngle(skillListWidget.TrackType.Main, angle), self.SkillGaBackTime, true)
  return newSkillItem
end

BattleChangeSkillPositionPlayer.ChangeThirdStep = a.sync(ChangeThirdStep)

local function PlayAsync(self, battlePet)
  local assetPath = "/Game/NewRoco/Modules/System/BattleUI/Res/Skill/UMG_Battle_Skill_Item_2.UMG_Battle_Skill_Item_2_C"
  local skillItemClass, skillItemClassRef
  do
    local request = _G.BattleResourceManager:GetCacheAsset(assetPath)
    if request then
      skillItemClass = request.assert
    end
  end
  if not UE.UObject.IsValid(skillItemClass) then
    local aLoadResource = a.wrap(_G.BattleResourceManager.LoadResAsyncThunk)
    local status, messageOrResult = a.wait(aLoadResource(_G.BattleResourceManager, nil, assetPath, nil, nil, nil, _G.PriorityEnum.UI_LoadRes_Default))
    if status then
      local res = messageOrResult
      skillItemClass = res
    end
  end
  if UE.UObject.IsValid(skillItemClass) then
    skillItemClassRef = UnLua.Ref(skillItemClass)
  else
    assert(false, "BattleChangeSkillPositionPlayer skillItemClass \232\181\132\230\186\144\230\151\160\230\149\136")
  end
  if not skillItemClass then
    Log.Error("BattleChangeSkillPositionPlayer:PlayAsync skillItemClass asset is nil")
    return
  end
  self.skillItemClass = skillItemClass
  if not UE.UObject.IsValid(self.skillListWidget) then
    Log.Error("BattleChangeSkillPositionPlayer:PlayAsync skillItemClass is not valid, stop playing")
    return
  end
  local aLoadResource = a.wrap(_G.BattleResourceManager.LoadResAsyncThunk)
  local thunks = {}
  for i, info in ipairs(self.skill_pos_infos) do
    local skillId = _G.SkillUtils.CheckSkillId(info.skill_id)
    local skillConf = _G.SkillUtils.GetSkillConf(skillId, true)
    local iconPath = skillConf and skillConf.icon
    local resCacheTime = 10
    if iconPath then
      table.insert(thunks, aLoadResource(_G.BattleResourceManager, nil, iconPath, nil, nil, resCacheTime, PriorityEnum.Passive_Battle_Panel))
    end
  end
  local iconLoadResList = {
    a.wait_all(thunks)
  }
  for _, res in ipairs(iconLoadResList) do
    if not res[1] then
      Log.Error("BattleChangeSkillPositionPlayer:PlayAsync Preload icon failed", res[2])
    end
  end
  a.wait(au.DelayFrames(1))
  Log.Info("BattleChangeSkillPositionPlayer:PlayAsync Preload icon completed")
  self.skillListWidget:ShowForPerformChangeSkillPosition()
  local skillItemLoaderContainerList = {
    self.skillListWidget.SkillItemLoaderContainer,
    self.skillListWidget.SkillItemLoaderContainer_1,
    self.skillListWidget.SkillItemLoaderContainer_2,
    self.skillListWidget.SkillItemLoaderContainer_3
  }
  local changeInfoList = {}
  local noChangeInfoList = {}
  for i, info in ipairs(self.skill_pos_infos) do
    if info.old_pos == info.new_pos then
      table.insert(noChangeInfoList, info)
    end
    table.insert(changeInfoList, info)
  end
  local firstStepThunks = {}
  local skillItemList = {}
  local noChangeSkillItemList = {}
  local currentTargetSkillItems = self.skillListWidget:GetItemList()
  for i, changeInfo in ipairs(changeInfoList) do
    local skillItem
    local skill_pos_change = self.skill_pos_change
    local petGuid = skill_pos_change and skill_pos_change.pet_id
    for j, sourceSkillItem in ipairs(currentTargetSkillItems) do
      local skillIdToPerformItem = self.skillListWidget.petSkillIdToChangePositionPerformItem[petGuid]
      local skillId = _G.SkillUtils.CheckSkillId(changeInfo.skill_id)
      local performItem = skillIdToPerformItem and skillIdToPerformItem[skillId]
      if performItem then
        skillIdToPerformItem[skillId] = nil
        skillItem = performItem
        break
      end
    end
    skillItem = skillItem or self.skillListWidget:TryGetNextPerformSkillItem(self.skillItemClass)
    self:InitSkillItem(skillItem, changeInfo.skill_id)
    local container = skillItemLoaderContainerList[changeInfo.old_pos]
    local skillItem1Slot = container.Slot
    local newSkillItemSlot = skillItem.Slot
    local position = skillItem1Slot:GetPosition()
    newSkillItemSlot:SetPosition(position)
    skillItem:SetRenderTransformAngle(container:GetRenderTransformAngle())
    table.insert(skillItemList, skillItem)
    table.insert(firstStepThunks, self:ChangeFirstStep(changeInfo, skillItem))
  end
  self.skillListWidget:RecycleAndHideAllBindChangePositionSkillItem()
  for i, sourceSkillItem in ipairs(currentTargetSkillItems) do
    if i <= 4 then
      sourceSkillItem:SetWidgetVisibilityByName("EmptyCanvas", UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  currentTargetSkillItems = {}
  a.wait(au.DelaySeconds(self.TimeBeforeAnimation))
  _G.NRCAudioManager:PlaySound2DAuto(BattleConst.ChangeSkillPositionParams.SkillGoOutAudioId, "BattleChangeSkillPositionPlayer:PlayAsync")
  local resultList = {
    a.wait_all(firstStepThunks)
  }
  firstStepThunks = {}
  skillItemList = {}
  for i, result in ipairs(resultList) do
    if result[1] then
      table.insert(skillItemList, result[2])
    else
      Log.Error("BattleChangeSkillPositionPlayer:PlayAsync ChangeFirstStep error", i, result[2])
      table.insert(skillItemList, {})
    end
  end
  a.wait(au.DelaySeconds(BattleConst.ChangeSkillPositionParams.TimeBetweenGoOutAndMoving))
  local secondStepThunks = {}
  for i, changeInfo in ipairs(changeInfoList) do
    local skillItem = skillItemList[i]
    table.insert(skillItemList, skillItem)
    table.insert(secondStepThunks, self:ChangeSecondStep(changeInfo, skillItem, noChangeInfoList))
  end
  _G.NRCAudioManager:PlaySound2DAuto(BattleConst.ChangeSkillPositionParams.SkillMovingAudioId, "BattleChangeSkillPositionPlayer:PlayAsync")
  resultList = {
    a.wait_all(secondStepThunks)
  }
  secondStepThunks = {}
  skillItemList = {}
  for i, result in ipairs(resultList) do
    if result[1] then
      table.insert(skillItemList, result[2])
    else
      Log.Error("BattleChangeSkillPositionPlayer:PlayAsync ChangeSecondStep error", i, result[2])
      table.insert(skillItemList, {})
    end
  end
  a.wait(au.DelaySeconds(self.TimeBetweenMovingAndGoBack))
  local thirdStepThunks = {}
  for i, changeInfo in ipairs(changeInfoList) do
    local skillItem = skillItemList[i]
    table.insert(skillItemList, skillItem)
    table.insert(thirdStepThunks, self:ChangeThirdStep(changeInfo, skillItem))
  end
  _G.NRCAudioManager:PlaySound2DAuto(BattleConst.ChangeSkillPositionParams.SkillGoBackAudioId, "BattleChangeSkillPositionPlayer:PlayAsync")
  resultList = {
    a.wait_all(thirdStepThunks)
  }
  thirdStepThunks = {}
  skillItemList = {}
  for i, result in ipairs(resultList) do
    if result[1] then
      table.insert(skillItemList, result[2])
    else
      Log.Error("BattleChangeSkillPositionPlayer:PlayAsync ChangeThirdStep error", i, result[2])
      table.insert(skillItemList, {})
    end
  end
  local skillComponent = battlePet and battlePet.skillComponent
  local skillItems = self.skillListWidget:GetItemList()
  for i, changeInfo in ipairs(changeInfoList) do
    local sourceItem = skillItems[changeInfo.new_pos]
    local targetItem = skillItemList[i]
    local skill_pos_change = self.skill_pos_change
    local petGuid = skill_pos_change and skill_pos_change.pet_id
    local skillId = _G.SkillUtils.CheckSkillId(changeInfo.skill_id)
    local skillIdSrc = skillId
    if skillComponent then
      local skillEntity = skillComponent:GetSkillBySkillID(skillId)
      local skillEntitySrc = skillComponent:GetHeadOfChangeSrcSkillChain(skillEntity)
      if skillEntitySrc then
        skillIdSrc = _G.SkillUtils.CheckSkillId(skillEntitySrc.skill_id)
      end
    end
    self.skillListWidget:BindSkillItemToPerformItem(petGuid, skillIdSrc, targetItem)
  end
  if UE.UObject.IsValid(skillItemClassRef) then
    UnLua.Unref(skillItemClassRef)
  end
  skillItemClassRef = nil
  if self.isTestMode then
    au.Launch(self:PlayAsync(battlePet), function(ok, resultOrErrorMessage)
      if not ok then
        Log.Error("BattleChangeSkillPositionPlayer:Play error", resultOrErrorMessage)
      end
    end)
  end
end

BattleChangeSkillPositionPlayer.PlayAsync = a.sync(PlayAsync)

function BattleChangeSkillPositionPlayer:InitSkillItem(skillItem, skillId)
  skillItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  skillItem.isUsing = true
  skillItem.skillId = _G.SkillUtils.CheckSkillId(skillId)
  skillItem.Icon:SetRenderTranslation(UE.FVector2D(0, 0))
  skillItem.Icon:ForceLayoutPrepass()
  local skillConf = _G.SkillUtils.GetSkillConf(skillId)
  if skillConf and skillConf.icon then
    skillItem.Icon:SetPath(skillConf.icon)
  end
end

function BattleChangeSkillPositionPlayer:Finish()
  Log.Debug("BattleChangeSkillPositionPlayer:Finish")
  if self.performNode then
    self.performNode:PerformComplete()
  end
end

function BattleChangeSkillPositionPlayer:CheckChangeInfoValid(changeInfoList)
  local oldPosToInfo = {}
  local newPosToInfo = {}
  local allNewPosAndOldPosAreTheSame = true
  for i, info in ipairs(changeInfoList) do
    if oldPosToInfo[info.old_pos] then
      local otherInfo = oldPosToInfo[info.old_pos]
      return false, string.format("\230\138\128\232\131\189 %s \229\146\140 %s \231\154\132\229\136\157\229\167\139\228\189\141\231\189\174\231\155\184\229\144\140", tostring(otherInfo.skill_id), tostring(info.skill_id))
    end
    if newPosToInfo[info.new_pos] then
      local otherInfo = newPosToInfo[info.new_pos]
      return false, string.format("\230\138\128\232\131\189 %s \229\146\140 %s \231\154\132\231\155\174\230\160\135\228\189\141\231\189\174\231\155\184\229\144\140", tostring(otherInfo.skill_id), tostring(info.skill_id))
    end
    oldPosToInfo[info.old_pos] = info
    newPosToInfo[info.new_pos] = info
    if info.old_pos ~= info.new_pos then
      allNewPosAndOldPosAreTheSame = false
    end
  end
  if allNewPosAndOldPosAreTheSame then
    return false, string.format("\230\137\128\230\156\137\230\138\128\232\131\189\231\154\132\232\181\183\229\167\139\228\189\141\231\189\174\228\184\142\231\155\174\230\160\135\228\189\141\231\189\174\231\155\184\229\144\140\239\188\140\230\151\160\233\156\128\228\188\160\229\138\168")
  end
  return true, nil
end

return BattleChangeSkillPositionPlayer
