local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local async = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local BattleClientBranchActionBase = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattleClientBranchActionBase")
local FsmUtils = require("NewRoco.Modules.Core.Fsm.FsmUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local GamePlayUtils = require("NewRoco/Modules/Core/NPC/NPCUtils/GamePlayUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local Base = BattleClientBranchActionBase
local BattleWeeklyChallengeShowResultUI = Base:Extend("BattleWeeklyChallengeShowResultUI")

function BattleWeeklyChallengeShowResultUI:OnEnter()
  if not BattleUtils.IsWeeklyChallenge() then
    self:Finish()
    return
  end
  self.CurActionActive = true
  self.fsm:Pause()
  _G.UpdateManager:Register(self)
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for _, v in pairs(pets) do
    v:HidePet()
  end
  for i, battleNpc in ipairs(_G.BattleManager.battlePawnManager.battleNpcList) do
    battleNpc:HideNpc()
  end
  self.SettleData = _G.BattleManager.battleRuntimeData.battleSettleData.data.settle_info
  if not self.SettleData.pve_add_info then
    Log.Error("\229\145\168\230\140\145\230\136\152pve_add_info\230\149\176\230\141\174\229\188\130\229\184\184\239\188\140\229\144\142\229\143\176\230\159\165\231\156\139\228\184\139\229\143\145\231\154\132\231\187\147\231\174\151\230\149\176\230\141\174\230\152\175\229\144\166\229\140\133\229\144\171pve_add_info")
    self:Finish()
    return
  end
  self:InitSkillData()
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.CloseBuffInfo)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.ClosePVPValueNumberPanel)
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OnShowBatleResult)
  _G.BattleEventCenter:Bind(self, BattleEvent.CLICKED_Result_Close, BattleEvent.OnSkillResLoaded, BattleEvent.WEEKLY_CHALLENGE_AGAIN, BattleEvent.PET_SPAWNED)
  self.skillResList = {
    self.skillPath
  }
  if self.CurtainSkillPath then
    table.insert(self.skillResList, self.CurtainSkillPath)
  end
  self.loadedSkillResCount = 0
  self:LaunchAsyncTask(function(noUncheckedError, msgOrResult)
  end)
end

function BattleWeeklyChallengeShowResultUI:InitSkillData()
  self.ShowPlayer = _G.BattleManager.battlePawnManager.TeamatePlayer
  self.hasCurtainBg = self.SettleData.pve_add_info.can_take_photo
  if self.hasCurtainBg then
    self.CurtainSkillPath = BattleConst.LeaderChallengeMuBuStart
    self.materialPath = self:GetMaterialPath()
    if not self.materialPath then
      self.materialPath = "/Game/ArtRes/Asset/Environment/Interator/Curtain/TEX/MI_Curtain_001_01_Skeletal.MI_Curtain_001_01_Skeletal"
    end
    self.CurtainLoopAnimPath = "/Game/ArtRes/Asset/Environment/Interator/Curtain/Animation/World_Loop.World_Loop"
  end
  local battleIsWin = _G.BattleManager.battleRuntimeData.battleSettleData:BattleIsWin()
  local LastHitBaseId = self.ShowPlayer.FashionData.LastHitPetBaseId
  local LastHitGID = self.ShowPlayer.FashionData.LastHitGID
  local LastHitPetCard = BattleManager.battlePawnManager:GetCardByCommonGuid(self.ShowPlayer.teamEnm, LastHitGID)
  local preBaseId = -1
  if battleIsWin then
    if LastHitPetCard then
      self.isTriggerSuit = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
      preBaseId = LastHitPetCard.petBaseConf.id
      if not self.isTriggerSuit then
        if preBaseId ~= LastHitBaseId then
          LastHitPetCard:RefreshByBaseConf(LastHitBaseId)
        end
        self.isTriggerSuit = LastHitPetCard.AppearancePath.PVPOverSuiId > 0
      else
        LastHitBaseId = preBaseId
      end
      self.skillPath = LastHitPetCard.AppearancePath:GetWeeklyChallengeOver()
    else
      self.skillPath = BattleConst.LeaderChallengeWinOver
    end
  else
    self.skillPath = BattleConst.LeaderChallengeLoseOver
  end
  self.NeedWaitLoadPet = false
  if self.isTriggerSuit then
    self.winPet = _G.BattleManager.battlePawnManager:GetFirstPet(self.ShowPlayer.teamEnm)
    local winCard
    if not self.winPet then
      winCard = LastHitPetCard or self.ShowPlayer.deck.cards[1]
      if winCard then
        winCard.pos = 1
        winCard.posInField = 1
        self.NeedWaitLoadPet = true
      end
    elseif self.winPet.card.petBaseConf.id ~= LastHitBaseId then
      self.NeedWaitLoadPet = true
      winCard = self.winPet.card
      self.winPet:OnRecall()
    elseif LastHitGID == self.winPet.card.petInfo.battle_common_pet_info.gid and LastHitBaseId ~= preBaseId then
      self.NeedWaitLoadPet = true
      winCard = self.winPet.card
      self.winPet:OnRecall()
    end
    if self.NeedWaitLoadPet then
      winCard:RefreshByBaseConf(LastHitBaseId)
      winCard:SetInBattleField(true)
      self.winPet = _G.BattleManager.battlePawnManager:PawnPet(self.ShowPlayer.teamEnm, self.ShowPlayer.team, winCard, self.ShowPlayer, nil, true)
    end
  end
  self.SkillComponent = _G.BattleManager.vBattleField.battleFieldActor.Skill
end

function BattleWeeklyChallengeShowResultUI:AsyncTask()
  local aLoadResAsyncThunk = async.wrap(_G.BattleResourceManager.LoadResAsyncThunk)
  if self.hasCurtainBg then
    local ok, asset = async.wait(aLoadResAsyncThunk(_G.BattleResourceManager, nil, self.materialPath, nil, nil, nil, nil))
    if ok then
      self.MaterialClass = asset
    else
      Log.Warning("\229\138\160\232\189\189\230\157\144\232\180\168\229\164\177\232\180\165\239\188\140\230\163\128\230\159\165\230\157\144\232\180\168\232\183\175\229\190\132 materialPath=", self.materialPath, "error=", asset)
    end
    local ok1, asset1 = async.wait(aLoadResAsyncThunk(_G.BattleResourceManager, nil, self.CurtainLoopAnimPath, nil, nil, nil, nil))
    if ok1 then
      self.CurtainLoopAnimClass = asset1
    else
      Log.Warning("\229\138\160\232\189\189\229\138\168\231\148\187\232\180\165\239\188\140\230\163\128\230\159\165\229\138\168\231\148\187\232\183\175\229\190\132 materialPath=", self.CurtainLoopAnimPath, "error=", asset)
    end
  end
  async.wait(BattleWeeklyChallengeShowResultUI.LoadSkillTask(self))
  self.loadSkillTaskCallback = nil
  local status, messageOrEvent, skill = async.wait(BattleWeeklyChallengeShowResultUI.PlayOverSkillTask(self))
  assert(status, messageOrEvent)
  local event = messageOrEvent
  self:OnSkillEnd(event, skill)
  if BattleUtils.IsReplayMode() then
    async.wait(au.DelaySeconds(3))
    _G.BattleEventCenter:Dispatch(BattleEvent.CLICKED_Result_Close)
  end
end

local function LoadSkillTask(self, callback)
  self.loadSkillTaskCallback = callback
  _G.BattleSkillManager:PreLoadRes(self.skillResList, true)
end

BattleWeeklyChallengeShowResultUI.LoadSkillTask = async.wrap(LoadSkillTask)

local function PlayOverSkillTask(self, callback)
  if not self.ShowPlayer then
    callback(false, "ShowPlayer is nil")
    return
  end
  self:PlayPlayerSkill(callback)
  if self.hasCurtainBg then
    self:PlayLightSkill()
  end
end

function BattleWeeklyChallengeShowResultUI:PlayLightSkill()
  if not self.hasCurtainBg or self.finished or not self.CurActionActive then
    return
  end
  local skillPath = self.CurtainSkillPath
  local skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    return
  end
  local skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  skill:SetPassive(true)
  self.curtainSkill = skill
  self.SkillComponent:PlaySkill(skill)
end

function BattleWeeklyChallengeShowResultUI:PlayPlayerSkill(callback)
  local skillPath = self.skillPath
  local skillClass = _G.BattleSkillManager:GetLoadedClass(skillPath)
  if not skillClass then
    callback(false, string.format("PlayPlayerSkill Failed to load skill class %s", skillPath))
    return
  end
  self.ShowPlayer:ShowPlayer()
  local skill = self.SkillComponent:FindOrAddSkillObj(skillClass)
  local Characters = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  self:SetBigBoundScale(self.ShowPlayer.model)
  Characters[BattleConst.CharacterIndex.Player1] = self.ShowPlayer.model
  skill:RegisterEventCallback("End", nil, function(event, internalSkill)
    callback(true, event, internalSkill)
  end)
  skill:RegisterEventCallback("PreEnd", nil, function(event, internalSkill)
    callback(true, event, internalSkill)
  end)
  skill:RegisterEventCallback("Start", self, self.SkillStart)
  skill:RegisterEventCallback("SpawnCurtainLoaded", self, self.SpawnCurtainLoaded)
  skill:RegisterEventCallback("CurtainStartAnimFinished", self, self.CurtainStartAnimFinished)
  local blackboard = skill:GetBlackboard()
  if blackboard and UE.UObject.IsValid(blackboard) and self.hasCurtainBg then
    blackboard:SetValueAsString("IsMuBu", "IsMuBu")
    blackboard:SetValueAsString("MuBu", "MuBu")
  end
  if self.winPet then
    self.winPet:ShowPet(false)
    self.winPet:SetIKEnable(false)
    self:SetBigBoundScale(self.winPet.model)
    Characters[BattleConst.CharacterIndex.Player_Pet1] = self.winPet.model
  end
  local hasOpenUiEvent = _G.SkillUtils.SkillObjHasLuaEvent(skill, UE4.ERocoSkillLuaEventType.OpenUI)
  if not hasOpenUiEvent then
    self:OpenUI()
  end
  skill:SetPassive(true)
  skill:SetCharacters(Characters)
  skill:RegisterEventCallback("OpenUI", self, self.OpenUI)
  skill.BattleGenderType = self.ShowPlayer.roleInfo.base.sex
  skill:SetCaster(self.ShowPlayer.model)
  if self.winPet then
    skill:SetTargets({
      self.winPet.model
    })
  end
  self.SkillComponent:PlaySkill(skill)
end

function BattleWeeklyChallengeShowResultUI:OpenUI()
  self.isOpenedUI = true
  _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.OpenWeeklyChallengeSettlement, self.SettleData)
end

function BattleWeeklyChallengeShowResultUI:SetBigBoundScale(actor)
  if actor then
    local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
    if mesh then
      mesh.BoundsScale = 20
      mesh.bNRCUseFixedSkelBounds = false
      mesh.bForceMipStreaming = true
      mesh:SetForcedLOD(BattleEnum.BattleLodModel.Lod0)
    end
  end
end

BattleWeeklyChallengeShowResultUI.PlayOverSkillTask = async.wrap(PlayOverSkillTask)

function BattleWeeklyChallengeShowResultUI:SetCurtainMaterial(curtainActor)
  if not curtainActor then
    return
  end
  if self.MaterialClass then
    local bgMeshComponent = curtainActor:GetComponentByClass(UE4.USkeletalMeshComponent)
    local dynamicAnimMaterial = bgMeshComponent:CreateDynamicMaterialInstance(0, self.MaterialClass)
    bgMeshComponent:SetMaterial(0, dynamicAnimMaterial)
  end
end

function BattleWeeklyChallengeShowResultUI:GetFootPos(pet)
  local MeshComp = pet.model:GetComponentByClass(UE4.USkeletalMeshComponent)
  if MeshComp then
    local footPos = MeshComp:Abs_GetSocketLocation("locator_foot")
    return SceneUtils.ConvertAbsoluteToRelative(footPos)
  else
    Log.Error("BattleWeeklyChallengeShowResultUI:GetFootPos Pet has invalid mesh", pet.guid, "pet name = ", pet.card:GetName())
    return UE4.FVector(0, 0, 0)
  end
  return UE4.FVector(0, 0, 0)
end

function BattleWeeklyChallengeShowResultUI:SetCurtainPosAndRot(curtainActor)
  if not curtainActor then
    return
  end
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  local curCamera = playerController:GetViewTarget()
  if curCamera then
    local cameraLocation = curCamera:K2_GetActorLocation()
    local ForwardVector = curCamera:GetActorForwardVector()
    local distance = 500
    if self.winPet and self.winPet.model then
      local petLoc = self:GetFootPos(self.winPet)
      local anchorDistance = UE4.UKismetMathLibrary.Vector_Distance2D(petLoc, cameraLocation)
      distance = anchorDistance * 2
    end
    ForwardVector.Z = 0
    ForwardVector:Normalize()
    local targetLocation = cameraLocation + ForwardVector * distance
    local actorsToIgnore = {}
    table.insert(actorsToIgnore, curtainActor)
    local newLocation = LineTraceUtils.GetPointValidLocationByLine(SceneUtils.ConvertRelativeToAbsolute(targetLocation), nil, nil, nil, nil, actorsToIgnore)
    local groundPos = SceneUtils.ConvertAbsoluteToRelative(newLocation)
    curtainActor:K2_SetActorLocation(groundPos, false, nil, false)
    local targetDirection = targetLocation - cameraLocation
    targetDirection.Z = 0
    local targetRotation = targetDirection:ToRotator()
    targetRotation.Yaw = targetRotation.Yaw + 90
    targetRotation.Pitch = targetRotation.Pitch
    curtainActor:K2_SetActorRotation(targetRotation, false)
  end
end

function BattleWeeklyChallengeShowResultUI:CurtainStartAnimFinished(Event, Skill)
  do return end
  if not Skill then
    return
  end
  local blackboard = Skill:GetBlackboard()
  if not blackboard then
    return
  end
  local curtainActor = blackboard:GetValueAsObject("MuBuActor_0001")
  if curtainActor then
    local animComponent = curtainActor:GetComponentByClass(UE.USkeletalMeshComponent)
    if animComponent then
      animComponent:PlayAnimation(self.CurtainLoopAnimClass, true)
    end
  end
end

function BattleWeeklyChallengeShowResultUI:OnTick(DeltaTime)
  self:TryCurtainPlayLoop()
end

function BattleWeeklyChallengeShowResultUI:TryCurtainPlayLoop()
  if not (self.hasCurtainBg and self.CurtainActor) or self.hasPlayLoopAnim then
    return
  end
  local Mesh = self.CurtainActor:GetComponentByClass(UE.USkeletalMeshComponent)
  if Mesh:IsPlaying() then
    return
  else
    local animComponent = self.CurtainActor:GetComponentByClass(UE.USkeletalMeshComponent)
    if animComponent then
      self.hasPlayLoopAnim = true
      animComponent:PlayAnimation(self.CurtainLoopAnimClass, true)
    end
  end
end

function BattleWeeklyChallengeShowResultUI:SpawnCurtainLoaded(Event, Skill)
  if not Skill then
    return
  end
  local blackboard = Skill:GetBlackboard()
  if not blackboard then
    return
  end
  local curtainActor = blackboard:GetValueAsObject("MuBuActor_0001")
  self.CurtainActor = curtainActor
  self:SetCurtainMaterial(curtainActor)
end

function BattleWeeklyChallengeShowResultUI:SkillStart(Event, Skill)
  if self.finished then
    Log.Debug("yukahe BattleWeeklyChallengeShowResultUI is finished")
    return
  end
  self.playerSkill = Skill
  self:AdjustPlayer()
end

function BattleWeeklyChallengeShowResultUI:AdjustPlayer()
  local player = self.ShowPlayer.model
  if player and player.GetHalfHeight then
    local HalfHeight = player:GetHalfHeight()
    local pos = player:Abs_K2_GetActorLocation()
    if pos then
      local groundPoint = LineTraceUtils.GetPointValidLocationByLine(pos, HalfHeight) or pos
      local newLocation = UE4.FVector(groundPoint.X, groundPoint.Y, groundPoint.Z + HalfHeight)
      player:Abs_K2_SetActorLocation_WithoutHit(newLocation)
    end
  end
end

function BattleWeeklyChallengeShowResultUI:OnSkillEnd(Event, Skill)
  if self.finished then
    Log.Debug("yukahe BattleWeeklyChallengeShowResultUI is finished")
    return
  end
  if not self.isOpenedUI then
    self:OpenUI()
  end
  local Blackboard = Skill:GetBlackboard()
  self:SaveBlackboard(Blackboard, "camActor_0001")
  self:SaveBlackboard(Blackboard, "camActor_0001_SA")
  self:SaveBlackboard(Blackboard, "MuBuActor_0001")
end

function BattleWeeklyChallengeShowResultUI:SaveBlackboard(blackboard, name)
  if not self.CurActionActive then
    return
  end
  FsmUtils.SaveAsProperty(self.fsm, blackboard, name)
end

function BattleWeeklyChallengeShowResultUI:GetBlackboardValue(name)
  if not self.CurActionActive then
    return
  end
  FsmUtils.GetProperty(self.fsm, name)
end

function BattleWeeklyChallengeShowResultUI:CloseResult()
  self.fsm:Resume()
  self:Finish()
end

function BattleWeeklyChallengeShowResultUI:OnFinish()
  _G.UpdateManager:UnRegister(self)
  self.CurActionActive = nil
  _G.BattleEventCenter:UnBind(self)
  _G.NRCModeManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.CloseWeeklyChallengeSettlement)
  if self.animInstance then
    self.animInstance.OnMontageStarted:Clear()
  end
  self.CurtainActor = nil
  self.animInstance = nil
  self.SkillComponent = nil
  self.loadSkillTaskCallback = nil
  self.materialPath = nil
  self.MaterialClass = nil
  self.hasCurtainBg = nil
  self.CurtainSkillPath = nil
  self.skillPath = nil
  self.winPet = nil
  self.NeedWaitLoadPet = nil
  self.curtainSkill = nil
  self.animComponent = nil
  self.hasPlayCurtainSkill = nil
  self.playerSkill = nil
  self.isTriggerSuit = nil
end

function BattleWeeklyChallengeShowResultUI:OnSkillResLoaded(eventName, resPath)
  for i = 1, #self.skillResList do
    if resPath == self.skillResList[i] then
      self.loadedSkillResCount = self.loadedSkillResCount + 1
    end
  end
  if self.loadedSkillResCount == #self.skillResList and not self.NeedWaitLoadPet and self.loadSkillTaskCallback then
    self.loadSkillTaskCallback()
  end
end

function BattleWeeklyChallengeShowResultUI:OnPawnNewPetFinish(pet)
  if self.winPet == pet then
    self.winPet:SetScale(1)
    self.winPet:HidePet()
    self.winPet:PinOnTheGround()
    self.NeedWaitLoadPet = false
    if self.loadedSkillResCount == #self.skillResList and not self.NeedWaitLoadPet and self.loadSkillTaskCallback then
      self.loadSkillTaskCallback()
    end
  end
end

function BattleWeeklyChallengeShowResultUI:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.CLICKED_Result_Close then
    self:CloseResult()
    return true
  elseif eventName == BattleEvent.WEEKLY_CHALLENGE_AGAIN then
    self.fsm:SendEvent(BattleEvent.EnterWeeklyChallengeAgain)
    self:CloseResult()
    self:Finish()
    return true
  elseif eventName == BattleEvent.OnSkillResLoaded then
    self:OnSkillResLoaded(eventName, ...)
    return true
  elseif eventName == BattleEvent.PET_SPAWNED then
    self:OnPawnNewPetFinish(...)
  end
end

function BattleWeeklyChallengeShowResultUI:GetMaterialPath()
  local SettleData = _G.BattleManager.battleRuntimeData.battleSettleData.data.settle_info
  if SettleData then
    local challengeId = SettleData.pve_add_info.challenge_level_id
    local challengeConf = _G.DataConfigManager:GetWeeklyChallengeConf(challengeId)
    if challengeConf then
      local photoId = challengeConf.photo
      local materialPath = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.GetMaterialPathFromPhotoID, photoId)
      if materialPath then
        return materialPath
      end
      local photoConf = _G.DataConfigManager:GetWeeklyPhotoConf(photoId)
      if photoConf then
        local resPath = "/Game/ArtRes/Asset/Environment/Interator/Curtain/TEX/" .. photoConf.background .. "." .. photoConf.background
        return resPath
      else
        Log.Warning("\230\139\141\231\133\167\233\133\141\231\189\174WEEKLY_PHOTO_CONF\229\188\130\229\184\184challengeId=", challengeId, "photoId=", photoId)
        return nil
      end
    else
      Log.Warning("\229\145\168\230\140\145\230\136\152\233\133\141\231\189\174WEEKLY_CHALLENGE_CONF\229\188\130\229\184\184challengeId=", challengeId)
      return nil
    end
  else
    Log.Warning("\231\187\147\231\174\151\230\149\176\230\141\174\229\188\130\229\184\184")
    return nil
  end
end

return BattleWeeklyChallengeShowResultUI
