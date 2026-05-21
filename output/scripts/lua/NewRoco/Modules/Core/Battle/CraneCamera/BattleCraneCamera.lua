local BattleCraneCameraBase = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraBase")
local BattleCraneCameraDebug = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraDebug")
local BattleCraneCameraData = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraData")
local BattleCraneCameraDefine = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraDefine")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleAIStandManager = require("NewRoco.Modules.Core.Battle.AI.BattleAIStandManager")
local Base = BattleCraneCameraBase
local BattleCraneCamera = BattleCraneCameraBase:Extend("BattleCraneCamera")

function BattleCraneCamera:Construct()
  Base.Construct(self)
  Base.InitCameraFromBattleField(self)
  self:ClearPlayerInputOffset()
  self.debugDef = BattleCraneCameraDebug()
  self.ShowDebugLine = false
  self:InitEffectValueFuncMap()
  self.FOV = 75
  self.AspectRatio = 2.15
  self.bConstrainAspectRatio = false
  Base.InitCameraInfo(self, self.FOV, self.AspectRatio, self.bConstrainAspectRatio)
  self.standManager = BattleAIStandManager()
  self.KontrolEnabled = false
  UpdateManager:Register(self)
end

function BattleCraneCamera:InitUI()
  if BattleManager.vBattleField.panelCameraController then
    local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    self.CameraKontrol = BattleManager.vBattleField.panelCameraController.KameraKontrol
    if self.CameraKontrol then
      self.CameraKontrol:SetDrawSize(UE4.FVector2D(viewportSize.X * 10, viewportSize.Y * 10))
    else
      Log.Error("BattleCraneCamera CameraKontrol is nil")
    end
  end
end

function BattleCraneCamera:SetTickEnable(State)
  self.tickEnable = State
end

function BattleCraneCamera:OnTick(DeltaTime)
  if not self.tickEnable then
    return
  end
  if self.ShowDebugLine then
    self.debugDef:DrawDebugLine()
  end
  Base.OnTick(self, DeltaTime)
end

function BattleCraneCamera:GetCameraComponentAndActorPos()
  local CameraActor = self.CameraActor
  if CameraActor then
    self.CameraComponent = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    local pos1 = self.CameraComponent:Abs_K2_GetComponentLocation()
    local pos2 = CameraActor:Abs_K2_GetActorLocation()
    return pos1, pos2
  end
  return nil, nil
end

function BattleCraneCamera:DrawDebugLineInG6Editor(EditorWorld)
  local CameraActor = self.CameraActor
  if CameraActor then
    self.CameraComponent = CameraActor:GetComponentByClass(UE4.UCameraComponent)
    local pos1 = self.CameraComponent:Abs_K2_GetComponentLocation()
    local pos2 = CameraActor:Abs_K2_GetActorLocation()
    local World = EditorWorld
    if pos1 and pos2 then
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(World, pos1, 5, 10, UE4.FLinearColor(0, 1, 0, 1), 100000, 2)
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(World, pos2, pos1, UE4.FLinearColor(1, 0, 0, 1), 100000, 1)
    end
    local pet1 = self.confData.targetPos1
    local pet2 = self.confData.targetPos2
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(World, pet1, pet2, UE4.FLinearColor(1, 0, 0, 1), 100000, 1)
  end
end

function BattleCraneCamera:Destruct()
  Base.StopShake(self, true)
  Base.StopWaterShake(self, true)
  self:UnBindCamera()
  Base.Destruct(self)
  self.EffectValueFuncMap = {}
  self.standManager = nil
  self:ClearCheckJumpAnim()
  UpdateManager:UnRegister(self)
  self:ClearDelayControlCamId()
  _G.BattleManager:CloseDepthCfg()
end

function BattleCraneCamera:InitCameraFromBattleField()
  Base.InitCameraFromBattleField(self)
  self:ClearPlayerInputOffset()
end

function BattleCraneCamera:ClearPlayerInputOffset()
  self.SpringArmXOffset = 0
  self.SpringArmYOffset = 0
end

function BattleCraneCamera:BindCamera(DeltaTime, BlendFunc, BlendExp)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:GetUEController():ChangeToCustomCamera(self.CameraActor, DeltaTime, BlendFunc, BlendExp, true)
  end
  self:StartShake()
end

function BattleCraneCamera:UnBindCamera()
  self:StopShake()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:GetUEController():ReleaseRocoCamera(0, nil, nil)
  end
end

function BattleCraneCamera:InitEffectValueFuncMap()
  local outputParam = BattleCraneCameraDefine.OutputParam
  self.EffectValueFuncMap = {
    [outputParam.PitchAngle] = function(value)
      Base.ModifyCameraPitchAnglePlus(self, value)
    end,
    [outputParam.YawAngle] = function(value)
      Base.ModifyCameraYawAnglePlus(self, value)
    end,
    [outputParam.RollAngle] = function(value)
      Base.ModifyCameraRollAnglePlus(self, value)
    end,
    [outputParam.TargetPointHeight] = function(value)
      Base.ModifyLookPosPlus(self, value)
    end,
    [outputParam.SpringArmLength] = function(value)
      Base.ModifySpringArmLengthPlus(self, value)
    end,
    [outputParam.FOV] = function(value)
      Base.ModifyCameraFovPlus(self, value)
    end,
    [outputParam.PointRatio] = function(value)
      Base.ModifyPointRatio(self, value)
    end
  }
end

function BattleCraneCamera:ChangeByOperateType(operateType, callback)
  local BlendFunc = true
  local DefaultTime = 0.5
  self.CurOperateType = operateType
  if operateType == BattleEnum.Operation.ENUM_CATCH then
    self:ChangeToPlayerCatch(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_ITEM then
    self:ChangeToPlayerItem(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_PLAYERSKILL then
    self:ChangeToPlayerSkill(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_CHANGE then
    self:ChangeToPlayerChangePet(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_SKILL then
    self:ChangeToPlayerPet(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_ESCAPE or operateType == BattleEnum.Operation.ENUM_SURRENDER or operateType == BattleEnum.Operation.ENUM_STEPAWAY or operateType == BattleEnum.Operation.ENUM_GIVEUP then
    self:ChangeToPlayerEscape(DefaultTime, BlendFunc, callback)
  elseif operateType == BattleEnum.Operation.ENUM_NONE and callback then
    callback()
  end
  if operateType ~= BattleEnum.Operation.ENUM_NONE then
    BattleCraneCameraHost.SendCameraCfgToUmg()
  end
end

function BattleCraneCamera:EffectValueByType(EffectType, value)
  local func = self.EffectValueFuncMap and self.EffectValueFuncMap[EffectType] or nil
  if func then
    func(value)
  end
end

function BattleCraneCamera:Init(conf)
  Base.Init(self, conf)
  self.PetIndex = 1
  self.PetVictim = 2
end

function BattleCraneCamera:ChangeBindPlayerLocation(location)
  Log.Debug("BattleCameraBase:ChangeBindPlayerLocation")
  local playerActor = _G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM).player
  if not playerActor or not playerActor.model then
    Log.Error("BattleCameraBase:ChangeBindPlayerLocation playerActor is nil")
    return FVectorZero
  end
  local newLocation = LineTraceUtils.GetPointValidLocationByLine(location)
  local targetLocation = UE4.FVector(0, 0, 0)
  if newLocation then
    targetLocation.X = newLocation.X
    targetLocation.Y = newLocation.Y
    targetLocation.Z = newLocation.Z + (playerActor.model:GetHalfHeight() or 0)
  else
    targetLocation.X = location.X
    targetLocation.Y = location.Y
    targetLocation.Z = location.Z
  end
  if BattleConst.PlayerFollowPet == false then
    playerActor.model:Abs_K2_SetActorLocation_WithoutHit(targetLocation)
  end
  Log.Debug("Show Player New Location", targetLocation)
  return targetLocation
end

function BattleCraneCamera:SetCraneCamPlus()
  local controllerArray = self.confData.ControllerArray
  for _, data in pairs(controllerArray) do
    if data.IsEnable then
      local value = self.confData:CalcValueByType(data.InputType, data.Interval)
      self.confData.ctrlArrayInputVal = value
      self:EffectValueByType(data.EffectType, value)
    end
  end
end

function BattleCraneCamera:ChangeToSkill(DeltaTime, BlendFunc, CallBack, hidden, imm)
  local RoundRecord = _G.BattleManager.RoundStartRecord
  self.PrevTag = self.CurrentTag
  if 0 == RoundRecord then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerPet
    if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
      self.CurrentTag = UE4.EBattleCameraTags.PlayerNpcAssistSelectSkill
    elseif BattleUtils.IsFinalBattleP1() then
      self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkill
    elseif BattleUtils.IsB1FinalBattleP1() then
      self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP1
    elseif BattleUtils.IsB1FinalBattleP2() then
      self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP2
    elseif BattleUtils.IsB1FinalBattleP3() then
      self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP3
    end
  elseif self:IsMultiplayer() and not BattleUtils.IsTeam() then
    self.PetIndex = 1
    self.PetVictim = 2
    self.CurrentTag = UE4.EBattleCameraTags.PlayerSkillMult
    self:CalcPos(nil, nil, true)
  elseif BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill
  elseif BattleUtils.IsFinalBattleP1() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkill
  elseif BattleUtils.IsFinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP1() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP1
  elseif BattleUtils.IsB1FinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP3() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP3
  elseif BattleUtils.Is1VN() then
    self.CurrentTag = UE4.EBattleCameraTags.OneVsAll_PerformSkill
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self.CurrentTag = UE4.EBattleCameraTags.TerritoryTrial_PerformSkill
  else
    self.CurrentTag = UE4.EBattleCameraTags.PlayerSkill
  end
  self:ChangeCameraTag(self.CurrentTag, DeltaTime, BlendFunc, CallBack, hidden)
end

function BattleCraneCamera:ChangeToPlayerSkill(DeltaTime, BlendFunc, CallBack)
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsFinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.A1FBPerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsFinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP1, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsB1FinalBattleP2() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP2, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsB1FinalBattleP3() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP3, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.Is1VN() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.OneVsAll_PerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.TerritoryTrial_PerformSkill, DeltaTime, BlendFunc, CallBack)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerSkill, DeltaTime, BlendFunc, CallBack)
  end
end

function BattleCraneCamera:ChangeToPlayerSkillMulti(DeltaTime, BlendFunc, CallBack)
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsFinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.A1FBPerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsFinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP1, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsB1FinalBattleP2() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP2, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsB1FinalBattleP3() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBPerformSkillP3, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.Is1VN() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.OneVsAll_PerformSkill, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.TerritoryTrial_PerformSkill, DeltaTime, BlendFunc, CallBack)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerSkillMult, DeltaTime, BlendFunc, CallBack)
  end
end

function BattleCraneCamera:ChangeToPlayerPet(DeltaTime, BlendFunc, CallBack, hidden, imm, IsBindCamera)
  self.PrevTag = self.confData:GetCurCameraTag()
  self.CurrentTag = UE4.EBattleCameraTags.PlayerPet
  if self:IsMultiplayer() then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerPetMult1
  end
  if 1 ~= self.PetIndex then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerPetMult2
  end
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerNpcAssistSelectSkill
  end
  if BattleUtils.IsFinalBattleP1() then
    if 1 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.A1FBSSelectSkill_Pet1
    elseif 2 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.A1FBSSelectSkill_Pet2
    elseif 3 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.A1FBSSelectSkill_Pet3
    else
      self.CurrentTag = UE4.EBattleCameraTags.A1FBSSelectSkill
    end
  elseif BattleUtils.IsFinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBSSelectSkillP2_Pet1
  elseif BattleUtils.IsB1FinalBattleP1() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBSSelectSkillP1_Pet1
  elseif BattleUtils.IsB1FinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBSSelectSkillP2_Pet1
  elseif BattleUtils.IsB1FinalBattleP3() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBSSelectSkillP3_Pet1
  elseif BattleUtils.Is1VN() then
    if 1 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.OneVsAll_SelectSkill_Pet1
    elseif 2 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.OneVsAll_SelectSkill_Pet2
    end
  elseif BattleUtils.IsTerritoryTrialBattle() then
    if 1 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.TerritoryTrial_SelectSkill_Pet1
    elseif 2 == self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.TerritoryTrial_SelectSkill_Pet2
    end
  end
  self:ChangeCameraTag(self.CurrentTag, DeltaTime, BlendFunc, CallBack, hidden, IsBindCamera)
end

function BattleCraneCamera:ChangeCameraTagOnG6(CameraTag, DeltaTime, BlendFunc, cameraBlendParam)
  self.PrevTag = self.confData:GetCurCameraTag()
  self.CurrentTag = CameraTag
  local IsBindCamera = true
  if BlendFunc and DeltaTime > 0 then
    IsBindCamera = false
  end
  self:ChangeCameraTag(self.CurrentTag, DeltaTime, BlendFunc, nil, nil, IsBindCamera, cameraBlendParam)
end

function BattleCraneCamera:ChangeCameraTagDirect(CameraTag, DeltaTime, BlendFunc)
  self.PrevTag = self.confData:GetCurCameraTag()
  self.CurrentTag = CameraTag
  self:ChangeCameraTag(self.CurrentTag, DeltaTime, BlendFunc)
end

function BattleCraneCamera:IsMultiplayer()
  if BattleUtils.Is1V1V1() then
    return true
  end
  local battleConfig = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleConfig or nil
  if battleConfig and 2 == battleConfig.challanger_unit_num then
    return true
  end
  return false
end

function BattleCraneCamera:ChangeToPlayerItemToTeam(DeltaTime, BlendFunc, CallBack)
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerNpcAssistSelectItem, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsFinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.A1FBSelectItem, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsB1FinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBSelectItem, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.Is1VN() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.OneVsAll_PlayerItem, DeltaTime, BlendFunc, CallBack)
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.TerritoryTrial_PlayerItem, DeltaTime, BlendFunc, CallBack)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerItemToTeam, DeltaTime, BlendFunc, CallBack)
  end
end

function BattleCraneCamera:ChangeToSpecialCamera(team, DeltaTime, BlendFunc, CallBack)
  if team == BattleEnum.Team.ENUM_TEAM then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_ENEMY)
    for _, pet in ipairs(pets) do
      pet:HidePet()
    end
    self:ChangeCameraTag(UE4.EBattleCameraTags.SpecialToTeam, DeltaTime, BlendFunc, CallBack)
  elseif team == BattleEnum.Team.ENUM_ENEMY then
    local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM)
    for _, pet in ipairs(pets) do
      pet:HidePet()
    end
    self:ChangeCameraTag(UE4.EBattleCameraTags.SpecialToEnemy, DeltaTime, BlendFunc, CallBack)
  end
end

function BattleCraneCamera:ChangeCameraTag(CameraTag, DeltaTime, BlendFunc, CallBack, IsJustCalPos, IsBindCamera, cameraBlendParam)
  if self:IsLockingCam() then
    return
  end
  if not self.SpringArmComponent or not self.CameraComponent then
    self:InitCameraFromBattleField()
  end
  if not self.CameraComponent or not UE.UObject.IsValid(self.CameraComponent) then
    return
  end
  if self.isLockCamera and not cameraBlendParam then
    return
  end
  self.cameraBlendParam = cameraBlendParam
  Log.DebugFormat("BattleCraneCameraLog.ChangeCameraTag Traceback = %s, DeltaTime = %s, IsJustCalPos = %s,IsBindCamera = %s", CameraTag, DeltaTime, IsJustCalPos, IsBindCamera)
  if not self.confData then
    self.confData = BattleCraneCameraData()
  end
  self:SetControlEnabled(false)
  self.BattleZoom = 0
  self.confData:ChangeCameraTag(CameraTag)
  local lastCameraTag = self.confData:GetLastCameraTag()
  local duration = self.confData:GetDefaultBlendDuration()
  if self.confData.nextCameraCurveDuration and self.confData.nextCameraCurveIndex then
    duration = self.confData.nextCameraCurveDuration
  end
  self:CheckPetShow()
  if IsBindCamera then
    self:ResetCamera(IsJustCalPos, DeltaTime, BlendFunc, true)
  elseif BlendFunc then
    if self.cameraBlendParam then
      if DeltaTime > 0 then
        self:ResetCameraByCurveParam(BlendFunc, DeltaTime)
      else
        self:ResetCamera(IsJustCalPos, DeltaTime, BlendFunc, false)
      end
    elseif lastCameraTag and duration > 0 then
      self:ResetCameraByCurve(BlendFunc, duration)
    else
      self:ResetCamera(IsJustCalPos, DeltaTime, BlendFunc, false)
    end
  else
    self:ResetCamera(IsJustCalPos, DeltaTime, BlendFunc, false)
  end
  if CallBack then
    CallBack()
  end
end

function BattleCraneCamera:CheckPetShow()
  if not self.confData.lastCameraTag or self.confData.lastCameraTag ~= UE4.EBattleCameraTags.SpecialToTeam and self.confData.lastCameraTag ~= UE4.EBattleCameraTags.SpecialToEnemy then
    return
  end
  if not self.confData.CurCameraTag or self.confData.CurCameraTag == self.confData.lastCameraTag then
    return
  end
  local EnemyTeamEnum = BattleEnum.Team.ENUM_TEAM
  if self.confData.lastCameraTag == UE4.EBattleCameraTags.SpecialToTeam then
    EnemyTeamEnum = BattleEnum.Team.ENUM_ENEMY
  end
  local pets = _G.BattleManager.battlePawnManager:GetCanSelectAllPet(BattleEnum.Team.ENUM_TEAM)
  for _, pet in ipairs(pets) do
    pet:ShowPet()
  end
end

function BattleCraneCamera:ResetCameraInG6SkillEditor(G6Actors, CameraTag)
  if not self.confData then
    self.confData = BattleCraneCameraData()
  end
  Base.InitCameraComponent(self, G6Actors.PreviewCameraActor)
  self.confData:ChangeCameraTagByG6(G6Actors, CameraTag)
  Base.CalCameraBaseInfo(self, self.confData.TargetA, self.confData.TargetB, self.confData.SpringArmRotation, self.confData.SpringArmOffset, self.confData.SprintArmLength, self.confData.CameraFov, self.confData.nextCameraCurveIndex)
  self:SetCraneCamPlus()
  Base.SetCameraBaseInfo(self, true)
  return self.curLookPos, self.CurSprintArmRotation, self.FOV, self.CurSpringArmLength
end

function BattleCraneCamera:LockCamera(reason)
  self.lockCam = true
  self.lockCamReason = reason
end

function BattleCraneCamera:UnlockCamera()
  self.lockCam = false
  self.lockCamReason = ""
end

function BattleCraneCamera:IgnoreLocking(value)
  self.ignoreLocking = value
end

function BattleCraneCamera:IsLockingCam()
  return self.lockCam and not self.ignoreLocking
end

function BattleCraneCamera:HotReloadData()
  Base.confData = BattleCraneCameraData()
  self:ResetCamera()
end

function BattleCraneCamera:ResetCameraByCurve(BlendFunc, DeltaTime)
  Log.Debug("BattleCraneCamera:ResetCameraByCurve", BlendFunc, DeltaTime)
  self:ClearPlayerInputOffset()
  Base.ResetCameraByCurveBase(self)
  Base.BlendFuncStart(self, BlendFunc, DeltaTime)
  Base.CalCameraBaseInfo(self, self.confData.TargetA, self.confData.TargetB, self.confData.SpringArmRotation, self.confData.SpringArmOffset, self.confData.SprintArmLength, self.confData.CameraFov, self.confData.nextCameraCurveIndex)
  self:SetCraneCamPlus()
  self:HeightAdjustSimple()
  self:BumpCollisionAdjust()
  self:BindCamera()
end

function BattleCraneCamera:ResetCameraByCurveParam(BlendFunc, DeltaTime)
  Log.Debug("BattleCraneCamera:ResetCameraByCurveParam", BlendFunc, DeltaTime)
  self:ClearPlayerInputOffset()
  Base.RecordFormDataCameraByCurveParam(self)
  if not (self.CameraActor and self.SpringArmComponent) or not self.CameraComponent then
    self:InitCameraFromBattleField()
  end
  Base.BlendFuncStart(self, BlendFunc, DeltaTime)
  Base.CalCameraBaseInfo(self, self.confData.TargetA, self.confData.TargetB, self.confData.SpringArmRotation, self.confData.SpringArmOffset, self.confData.SprintArmLength, self.confData.CameraFov, self.confData.nextCameraCurveIndex)
  self:SetCraneCamPlus()
  self:HeightAdjustSimple()
  self:BumpCollisionAdjust()
  Base.SetCameraBaseInfo(self, false, true)
  self.CameraBlendFunc = nil
  UE4.UNRCStatics.UpdateSpringArmComponent(self.SpringArmComponent)
  self:CameraByCurveParamStart()
end

function BattleCraneCamera:CameraByCurveParamStart()
  if not self.CameraComponent or not UE.UObject.IsValid(self.CameraComponent) then
    return
  end
  self.curCameraRotation = self.CameraComponent:K2_GetComponentRotation()
  self.curCameraLocation = self.CameraComponent:K2_GetComponentLocation()
  Base.RestoreCameraFromData(self)
  self:BindCamera()
  self.CameraBlendFunc = true
end

function BattleCraneCamera:BumpCollisionAdjust()
  if not BattleCraneCameraDefine.BumpCollisionParam.IsOpen then
    return
  end
  local curCamTag = self.confData:GetCurCameraTag()
  if curCamTag ~= UE4.EBattleCameraTags.PlayerPet and curCamTag ~= UE4.EBattleCameraTags.PlayerPetMult1 and curCamTag ~= UE4.EBattleCameraTags.PlayerPetMult2 then
    return
  end
  local actors = _G.BattleManager.battlePawnManager:GetAllPawnActorForSkill()
  local index = 1
  while index <= 20 do
    local targetA, targetB = self.confData:GetTargetHeight()
    local Hit = self:Collide(targetA, targetB, actors)
    if BattleCraneCameraDefine.BumpCollisionParam.IsDebugLine then
      local World = UE4Helper.GetCurrentWorld()
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(World, targetA, targetB, UE4.FLinearColor(1, 1, 0, 1), 1000, 1)
    end
    if Hit then
      Base.ModifyCameraPitchAnglePlus(self, BattleCraneCameraDefine.BumpCollisionParam.pitch)
      self.confData:ModifyTargetHeight(BattleCraneCameraDefine.BumpCollisionParam.Height, BattleCraneCameraDefine.BumpCollisionParam.Height)
      index = index + 1
    else
      break
    end
  end
end

function BattleCraneCamera:ResetCamera(IsJustCalPos, DeltaTime, BlendFunc, IsBindCamera)
  Log.Debug("BattleCraneCamera:ResetCamera", IsJustCalPos, DeltaTime, BlendFunc, IsBindCamera)
  if not self.confData.TargetA or not self.confData.TargetB then
    local tag = self.confData:GetCurCameraTag()
    Log.Error("BattleCraneCamera .func", self.confData.TargetA, self.confData.TargetB, tag, self.confData:GetJsonNameByCameraTag(tag))
  end
  local isSuccess = Base.CalCameraBaseInfo(self, self.confData.TargetA, self.confData.TargetB, self.confData.SpringArmRotation, self.confData.SpringArmOffset, self.confData.SprintArmLength, self.confData.CameraFov, self.confData.nextCameraCurveIndex)
  if not isSuccess then
    return
  end
  self:SetCraneCamPlus()
  self:HeightAdjustSimple()
  self:BumpCollisionAdjust()
  Base.SetCameraBaseInfo(self)
  self:ClearPlayerInputOffset()
  if IsJustCalPos then
    return
  end
  if type(BlendFunc) == "boolean" and BlendFunc then
    BlendFunc = UE4.EViewTargetBlendFunction.VTBlend_EaseOut
  end
  if IsBindCamera then
    self:BindCamera(DeltaTime, BlendFunc, 2)
  else
    self:BindCamera()
  end
  self:DelayEnableControl()
  self:UpdateCameraInfoUmg()
  self:InitUI()
  self:CheckDepthCfg()
end

function BattleCraneCamera:DelayEnableControl(DeltaTime)
  self:ClearDelayControlCamId()
  self.SetControlEnabledTimer = true
  local delayTime = DeltaTime or 0.2
  self.delayControlCamId = _G.DelayManager:DelaySeconds(delayTime, self.RunEnableControl, self)
end

function BattleCraneCamera:RunEnableControl()
  if self then
    self.delayControlCamId = nil
    if self.SetControlEnabledTimer then
      self:SetControlEnabled(true)
      self.SetControlEnabledTimer = false
    end
  end
end

function BattleCraneCamera:ClearDelayControlCamId()
  if self.delayControlCamId then
    _G.DelayManager:CancelDelayById(self.delayControlCamId)
  end
  self.SetControlEnabledTimer = false
  self.delayControlCamId = nil
end

function BattleCraneCamera:GetCameraFreedom()
  return self.confData.CameraFreedom or {}
end

function BattleCraneCamera:IsLoadedConf()
  return self.confData ~= nil
end

function BattleCraneCamera:IsCanRotate()
  if not self:IsLoadedConf() then
    return false
  end
  if not self.aidCamInitState then
    return false
  end
  local curTag = self.confData:GetCurCameraTag()
  if BattleCraneCameraDefine.ControllerCameraTagFilter and BattleCraneCameraDefine.ControllerCameraTagFilter[curTag] then
    return false
  end
  return true
end

function BattleCraneCamera:SetAidRotationCamInitState()
  self.aidCamInitState = true
end

function BattleCraneCamera:Collide(Begin, End, ActorsToIgnore)
  local debugType = UE4.EDrawDebugTrace.None
  local ObjectTypes = {
    UE4.ECollisionChannel.ECC_WorldStatic
  }
  if BattleUtils.IsDeepWater() then
    table.insert(ObjectTypes, UE4.ECollisionChannel.ECC_EngineTraceChannel3)
  end
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), Begin, End, ObjectTypes, false, ActorsToIgnore, debugType, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), 9999)
  if isHit then
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      local hitActor = hitResult.Actor
      if hitActor and UE.UObject.IsValid(hitActor) and hitActor:GetName() ~= nil then
        local foundIdx = string.find(hitActor:GetName(), "Game_Landscape_")
        local foundIdx1 = string.find(hitActor:GetName(), "SM_Env")
        local foundIdx2 = string.find(hitActor:GetName(), "SM_Stlmt")
        local foundIdx3 = string.find(hitActor:GetName(), "SM_Water")
        local foundIdx4 = string.find(hitActor:GetName(), "Ground")
        
        local function checkFunc(index)
          return index and index >= 0
        end
        
        if checkFunc(foundIdx) or checkFunc(foundIdx1) or checkFunc(foundIdx2) or checkFunc(foundIdx3) or checkFunc(foundIdx4) then
          return hitResult
        end
      end
    end
  end
  return nil
end

function BattleCraneCamera:HeightAdjustSimple()
  do return end
  if not self.CameraComponent or not UE.UObject.IsValid(self.CameraComponent) then
    return
  end
  local Rad = BattleCraneCameraDefine.GeneralParameters.CameraCollisionRadius
  local lineBegin, lineEnd, Hit
  local Success = true
  local ticks = 0
  while Success do
    Success = false
    lineBegin = Base.GetSpringCameraEndLocation(self)
    lineEnd = UE4.FVector(lineBegin.X, lineBegin.Y, lineBegin.Z - Rad)
    Hit = self:Collide(lineBegin, lineEnd)
    if Hit then
      Success = true
    end
    local RotVect, Rot, FoV
    if not Success then
      FoV = 35
    end
    if not Success then
      Rot = self.CameraComponent:K2_GetComponentRotation()
      if not Rot then
        return
      end
      Rot.Pitch = Rot.Pitch - FoV
      RotVect = Rot:ToVector()
      lineBegin = Base.GetSpringCameraEndLocation(self)
      lineEnd = UE4.UKismetMathLibrary.Add_VectorVector(lineBegin, UE4.UKismetMathLibrary.Multiply_VectorFloat(RotVect, Rad))
      Hit = self:Collide(lineBegin, lineEnd)
      if Hit then
        Success = true
      end
    end
    if not Success then
      Rot = self.CameraComponent:K2_GetComponentRotation()
      if not Rot then
        return
      end
      Rot.Yaw = Rot.Yaw - FoV
      RotVect = Rot:ToVector()
      lineBegin = Base.GetSpringCameraEndLocation(self)
      lineEnd = UE4.UKismetMathLibrary.Add_VectorVector(lineBegin, UE4.UKismetMathLibrary.Multiply_VectorFloat(RotVect, Rad))
      Hit = self:Collide(lineBegin, lineEnd)
      if Hit then
        Success = true
      end
    end
    if not Success then
      Rot = self.CameraComponent:K2_GetComponentRotation()
      if not Rot then
        return
      end
      Rot.Yaw = Rot.Yaw + FoV
      RotVect = Rot:ToVector()
      lineBegin = Base.GetSpringCameraEndLocation(self)
      lineEnd = UE4.UKismetMathLibrary.Add_VectorVector(lineBegin, UE4.UKismetMathLibrary.Multiply_VectorFloat(RotVect, Rad))
      Hit = self:Collide(lineBegin, lineEnd)
      if Hit then
        Success = true
      end
    end
    if not Success then
      lineBegin = Base.GetSpringCameraEndLocation(self)
      lineEnd = UE4.FVector(lineBegin.X, lineBegin.Y, lineBegin.Z)
      lineBegin = UE4.FVector(lineBegin.X, lineBegin.Y, lineBegin.Z + Rad)
      Hit = self:Collide(lineBegin, lineEnd)
      if Hit then
        Success = true
      end
    end
    local LocNew = Base.GetSpringCameraEndLocation(self)
    if Success then
      LocNew = UE4.FVector(LocNew.X, LocNew.Y, LocNew.Z + 10)
    end
    Base.ModifySpringArmLengthByNewPos(self, LocNew)
    ticks = ticks + 1
    if ticks >= 5000 then
      break
    end
  end
end

function BattleCraneCamera:GetInputOffset()
  return self.SpringArmXOffset, self.SpringArmYOffset
end

function BattleCraneCamera:UpdateCameraInfoUmg()
  BattleCraneCameraHost.SendInputParamToUmg()
  BattleCraneCameraHost.SendCameraParamToUmg()
  BattleCraneCameraHost.SendCameraAdditionalToUmg()
  BattleCraneCameraHost.SendEnvParamToUmg()
end

function BattleCraneCamera:TryInitBaseCamRelativeRot()
  self.hasInitBaseAidCamState = nil
  UE4.UNRCStatics.UpdateSpringArmComponent(self.SpringArmComponent)
  self:InitBaseCamRelativeRot()
end

function BattleCraneCamera:InitBaseCamRelativeRot()
  if not self then
    return
  end
  if not self.CameraComponent or not UE.UObject.IsValid(self.CameraComponent) then
    return
  end
  local AidRotationCam = _G.BattleManager:GetAidRotationCam()
  if not AidRotationCam or not UE.UObject.IsValid(AidRotationCam) then
    return
  end
  self.hasInitBaseAidCamState = true
  local SpringArmComponent = AidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
  self.BaseAidSprintArmRotation = SpringArmComponent:K2_GetComponentRotation()
  self.BaseAidSprintArmLength = SpringArmComponent.TargetArmLength
  self:ChangeCamParent(true, true)
  local ResultTransform = self.CameraComponent:GetRelativeTransform()
  local CurRot = ResultTransform.Rotation:ToRotator()
  self.BaseCamRelativeRot = UE4.FRotator(CurRot.Pitch, CurRot.Yaw, CurRot.Roll)
  local targetYaw = self.confData:GetRotationTargetValue()
  self.TargetCamRelativeRot = UE4.FRotator(self.BaseCamRelativeRot.Pitch, targetYaw, self.BaseCamRelativeRot.Roll)
  self:ChangeCamParent(false, true)
end

function BattleCraneCamera:ChangeCamParent(IsOpen, force)
  if not force and not self:IsControlEnabled() then
    return
  end
  self.IsAidCameraOpen = IsOpen
  local GetAidRotationCam = _G.BattleManager:GetAidRotationCam()
  if GetAidRotationCam and UE.UObject.IsValid(GetAidRotationCam) then
    local NewSpringArmComponent = GetAidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
    if NewSpringArmComponent then
      self.CraneCameraDef = BattleManager.vBattleField.battleCraneCamera
      local CameraComponent = self.CameraComponent
      local OldSpringArmComponent = self.SpringArmComponent
      if not CameraComponent or not OldSpringArmComponent then
        return
      end
      BattleCraneCameraHost.ChangeCameraComponentParent(OldSpringArmComponent, NewSpringArmComponent, CameraComponent, IsOpen)
    end
  end
end

function BattleCraneCamera:JumpAnimCallBack()
  if not self.standManager then
    Log.Error("BattleCraneCamera:JumpAnimCallBack  standManager is nil")
    return
  end
  self.standManager:CheckOver()
  self.CheckJumpAnimId = _G.DelayManager:DelaySeconds(0.2, function()
    self.CheckJumpAnimId = nil
    self:CheckJumpAnim()
  end)
end

function BattleCraneCamera:ClearCheckJumpAnim()
  if self.CheckJumpAnimId then
    _G.DelayManager:CancelDelay(self.CheckJumpAnimId)
    self.CheckJumpAnimId = nil
  end
end

function BattleCraneCamera:CheckJumpAnim(Caller, CallBack)
  if self and self.standManager then
    self.standManager:CheckJumpAnim(Caller, CallBack)
  end
end

function BattleCraneCamera:JumpToOriginForce(Caller, CallBack)
  self.standManager:JumpToOriginForce(Caller, CallBack)
end

function BattleCraneCamera:CheckDepthCfg()
  local EnableDepthOfField, DepthOfFieldScale, DepthOfFieldNear, DepthOfFieldFar = self.confData:GetGlobalDepthInfo()
  if EnableDepthOfField then
    _G.BattleManager:OpenDepthCfg(DepthOfFieldScale, DepthOfFieldNear, DepthOfFieldFar)
  else
    _G.BattleManager:CloseDepthCfg()
  end
end

function BattleCraneCamera:ChangeSettingsBoss()
end

function BattleCraneCamera:ChangeSettingsTeam()
end

function BattleCraneCamera:ChangeSettingsWorldBoss()
end

function BattleCraneCamera:SaveCameraSettings()
end

function BattleCraneCamera:ChangeSettingsNormal()
end

function BattleCraneCamera:ToggleCameraSetting()
end

function BattleCraneCamera:ChangeToPlayerCatch(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  if BattleUtils.IsBeastTeam() then
    if BattleManager.battlePawnManager:GetTeamPlayer(BattleEnum.Team.ENUM_TEAM).QuicklyCatchBallId > 0 then
      self:ChangeCameraTag(UE4.EBattleCameraTags.LegenderyTeamFight_Player_QuicklyCatch, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
    else
      self:ChangeCameraTag(UE4.EBattleCameraTags.LegenderyTeamFight_PlayerCatch, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
    end
  elseif BattleUtils.Is1VN() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.OneVsAll_PlayerCatch, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerCatch, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  end
end

function BattleCraneCamera:PetSelectIndexUpdate(Index)
  self.PetIndex = Index
  self.PetVictim = 1
  if 1 == self.PetIndex then
    self.PetVictim = 2
  end
end

function BattleCraneCamera:PetSelectCameraUpdate(Index)
  self:PetSelectIndexUpdate(Index)
  self:ChangeToPlayerPet(BattleConst.CameraTransTime, true)
end

function BattleCraneCamera:ChangeToPlayerItem(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  self:ChangeToPlayerItemToTeam(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
end

function BattleCraneCamera:ChangeToPlayerChangePet(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerNpcAssistSwitchPet, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  elseif BattleUtils.IsB1FinalBattleP1() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.B1FBSP1_ChangePet, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  elseif BattleUtils.Is1VN() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.OneVsAll_PlayerChangePet, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.TerritoryTrial_PlayerChangePet, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  elseif 1 == _G.BattleManager.battleRuntimeData.playerNumber and 2 == _G.BattleManager.battleRuntimeData.playerPetNumber then
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerChange2V2, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerChange, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  end
end

function BattleCraneCamera:ChangeToPlayerEscape(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  if BattleUtils.IsTeam() then
    self:ChangeCameraTag(UE4.EBattleCameraTags.TeamFight_PlayerEscape, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  else
    self:ChangeCameraTag(UE4.EBattleCameraTags.PlayerEscape, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  end
end

function BattleCraneCamera:ChangeToPlayerPetByCopeSkill(deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
  self.PrevTag = self.CurrentTag
  self.CurrentTag = UE4.EBattleCameraTags.PlayerSkill
  if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
    self.CurrentTag = UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill
  elseif BattleUtils.IsFinalBattleP1() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkill
  elseif BattleUtils.IsFinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.A1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP1() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP1
  elseif BattleUtils.IsB1FinalBattleP2() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP2
  elseif BattleUtils.IsB1FinalBattleP3() then
    self.CurrentTag = UE4.EBattleCameraTags.B1FBPerformSkillP3
  elseif BattleUtils.IsBloodTeam() then
    self.CurrentTag = UE4.EBattleCameraTags.TeamFight_PlayerSkill
  elseif BattleUtils.IsBeastTeam() then
    self.CurrentTag = UE4.EBattleCameraTags.LegenderyTeamFight_PlayerSkill
  elseif BattleUtils.Is1VN() then
    self.CurrentTag = UE4.EBattleCameraTags.OneVsAll_PerformSkill
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self.CurrentTag = UE4.EBattleCameraTags.TerritoryTrial_PerformSkill
  else
    if self:IsMultiplayer() then
      self:CalcPos()
      self.CurrentTag = UE4.EBattleCameraTags.PlayerPetMult1
    end
    if 1 ~= self.PetIndex then
      self.CurrentTag = UE4.EBattleCameraTags.PlayerSkillMult
    end
  end
  Log.Debug("ChangeToPlayerPetByCopeSkill ", self.CurrentTag)
  deltaTime = 0
  self:ChangeCameraTag(self.CurrentTag, deltaTime, blendFunc, callback, IsJustCalPos, IsBindCamera)
end

function BattleCraneCamera:ClearCurrentTag()
end

function BattleCraneCamera:CalcPos(FauxPet1, FauxPet2, AllPets, SkipPet1, SkipPet2)
end

function BattleCraneCamera:CalcPosCache()
  self.confData:InitPosCache()
end

function BattleCraneCamera:CheckSkillInChangeCamera()
  local teamPlayer = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  if not teamPlayer.model then
    Log.Debug("BattleCraneCamera.CheckSkillInChangeCamera1 model is nil")
    return
  end
  local skillComponent = teamPlayer.model.RocoSkill
  if not skillComponent then
    Log.Debug("BattleCraneCamera.CheckSkillInChangeCamera2 skillComponent is nil")
    return
  end
  local activeSkill = skillComponent:GetActiveSkill()
  if activeSkill then
    Log.Debug("BattleCraneCamera.CheckSkillInChangeCamera3 activeSkill = ", activeSkill:GetName())
    return
  end
end

function BattleCraneCamera:ChangeToPlayerMagic(DeltaTime, BlendFunc, CallBack)
  self.PrevTag = self.CurrentTag
  self.CurrentTag = UE4.EBattleCameraTags.PlayerMagic
  local battleConfig = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleConfig or nil
  if battleConfig then
    if 2 == battleConfig.challanger_unit_num then
      self.CurrentTag = UE4.EBattleCameraTags.PlayerMagicMulti
    elseif 3 == battleConfig.challanger_unit_num then
      self.CurrentTag = UE4.EBattleCameraTags.A1FBSPlayerMagicP1
    end
  end
  self:ChangeCameraTag(self.CurrentTag, DeltaTime, BlendFunc, CallBack)
end

function BattleCraneCamera:SwitchDefaultMode()
  Base.SwitchCameraMode(BattleCraneCameraDefine.CameraMode.default)
end

function BattleCraneCamera:SwitchAdditionalSkillsMode()
  Base.SwitchCameraMode(BattleCraneCameraDefine.CameraMode.additionalSkills)
end

function BattleCraneCamera:SwitchTeamBattleMode()
  Base.SwitchCameraMode(BattleCraneCameraDefine.CameraMode.teamBattle)
end

function BattleCraneCamera:GetBlendCameraIng()
  return self.blendCameraState
end

function BattleCraneCamera:SwitchLegendaryTeamFightMode()
  Base.SwitchCameraMode(BattleCraneCameraDefine.CameraMode.legendaryTeamFight)
end

function BattleCraneCamera:SetLockCameraByG6(isLock)
  self.isLockCamera = isLock
end

function BattleCraneCamera:GetAidCamAngleRatio()
  local AidRotationCam = _G.BattleManager:GetAidRotationCam()
  if not AidRotationCam or not UE.UObject.IsValid(AidRotationCam) then
    return
  end
  if not self.CurSprintArmRotation then
    return
  end
  local SpringArmComponent = AidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
  local AidSprintArmRotation = SpringArmComponent:K2_GetComponentRotation()
  local DeltaYaw = (AidSprintArmRotation.Yaw - self.BaseAidSprintArmRotation.Yaw + 180) % 360 - 180
  local RightMin, RightMax, LeftMin, LeftMax = self.confData:GetRotationLimitCfg()
  local ratio
  if DeltaYaw >= -LeftMin and DeltaYaw <= RightMin then
    ratio = 0
  elseif DeltaYaw >= RightMin and DeltaYaw <= RightMax then
    ratio = (DeltaYaw - RightMin) / (RightMax - RightMin)
  elseif DeltaYaw >= -LeftMax and DeltaYaw <= -LeftMin then
    ratio = (-DeltaYaw - LeftMin) / (LeftMax - LeftMin)
  else
    ratio = 1
  end
  return ratio
end

function BattleCraneCamera:UpdateCamBattleZoom(BattleZoomInputAxis)
  if not self.BaseAidSprintArmLength then
    return
  end
  local Length_Battle_Zoom_Rate, Battle_Zoom_Min, Battle_Zoom_Max = self.confData:GetZoomCfg()
  BattleZoomInputAxis = BattleZoomInputAxis * Length_Battle_Zoom_Rate
  local targetBattleZoom = self.BattleZoom + BattleZoomInputAxis
  if targetBattleZoom < Battle_Zoom_Min * Length_Battle_Zoom_Rate or targetBattleZoom > Battle_Zoom_Max * Length_Battle_Zoom_Rate then
    return
  end
  local AidRotationCam = _G.BattleManager:GetAidRotationCam()
  if not AidRotationCam or not UE.UObject.IsValid(AidRotationCam) then
    return
  end
  local aidSpringArmComponent = AidRotationCam:GetComponentByClass(UE4.URocoSpringArmComponent)
  if not aidSpringArmComponent or not UE4.UObject.IsValid(aidSpringArmComponent) then
    return
  end
  local targetValue = self.BaseAidSprintArmLength + targetBattleZoom
  if targetValue < 0 then
    return
  end
  local lastLength = aidSpringArmComponent.TargetArmLength
  self.lastCamComRotForCollision = self.CameraComponent:Abs_K2_GetComponentLocation()
  self:ChangeCamParent(true)
  aidSpringArmComponent.TargetArmLength = self.BaseAidSprintArmLength + targetBattleZoom
  UE4.UNRCStatics.UpdateSpringArmComponent(aidSpringArmComponent)
  if self:CheckIsCollisionLand() then
    aidSpringArmComponent.TargetArmLength = lastLength
    UE4.UNRCStatics.UpdateSpringArmComponent(aidSpringArmComponent)
  else
    self.BattleZoom = targetBattleZoom
  end
end

function BattleCraneCamera:UpdateCamRelativeRot()
  if not self.hasInitBaseAidCamState or not self.CameraComponent then
    return
  end
  if not self.BaseCamRelativeRot or not self.TargetCamRelativeRot then
    return
  end
  local AidRotationCam = _G.BattleManager:GetAidRotationCam()
  if not AidRotationCam or not UE.UObject.IsValid(AidRotationCam) then
    return
  end
  local ratio = self:GetAidCamAngleRatio()
  if not ratio then
    return
  end
  local cameraRot = UE4.FQuat.Slerp(self.BaseCamRelativeRot:ToQuat(), self.TargetCamRelativeRot:ToQuat(), ratio):ToRotator()
  self.CameraComponent:K2_SetRelativeRotation(cameraRot, false, nil, false)
end

function BattleCraneCamera:CheckIsCollisionLand()
  local pos = self.CameraComponent:Abs_K2_GetComponentLocation()
  local Hit = self:TouchMoveCollide(self.lastCamComRotForCollision, pos, true)
  if Hit then
    return Hit
  end
  if self:CheckIsInAnyPetSquare(pos) then
    return true
  end
  local GetAidRotationCam = _G.BattleManager:GetAidRotationCam()
  if GetAidRotationCam then
    local aidCamPos = GetAidRotationCam:Abs_K2_GetActorLocation()
    local Pos1 = UE4.FVector(aidCamPos.X, aidCamPos.Y, aidCamPos.Z)
    Hit = self:TouchMoveCollide(Pos1, pos, nil)
    return Hit
  end
  return false
end

function BattleCraneCamera:CheckIsInAnyPetSquare(pos)
  local pets = _G.BattleManager.battlePawnManager:GetAllPets()
  for i, pet in ipairs(pets) do
    if not pet:IsDead() then
      local PModel = pet and pet.model
      if PModel then
        local Location = PModel:Abs_K2_GetActorLocation()
        local halfHeight = pet:GetHalfHeight()
        local radius = 20
        local CapsuleComponent = PModel:GetComponentByClass(UE4.UCapsuleComponent)
        if CapsuleComponent then
          radius = CapsuleComponent:GetScaledCapsuleRadius()
        end
        local Left = UE4.FVector(Location.X - radius, Location.Y - radius, Location.Z - halfHeight)
        local Right = UE4.FVector(Location.X + radius, Location.Y + radius, Location.Z + halfHeight)
        if Left.X <= pos.X and Left.Y <= pos.Y and Left.Z <= pos.Z and pos.X <= Right.X and pos.Y <= Right.Y and pos.Z <= Right.Z then
          return true
        end
      end
    end
  end
  local players = _G.BattleManager.battlePawnManager:GetAllPlayers()
  for i, player in pairs(players) do
    local PModel = player and player.model
    if PModel and UE.UObject.IsValid(player.model) then
      local Location = PModel:Abs_K2_GetActorLocation()
      local halfHeight = player:GetHalfHeight()
      local radius = 20
      local CapsuleComponent = PModel:GetComponentByClass(UE4.UCapsuleComponent)
      if CapsuleComponent then
        radius = CapsuleComponent:GetScaledCapsuleRadius() + 10
      end
      local Left = UE4.FVector(Location.X - radius, Location.Y - radius, Location.Z - halfHeight)
      local Right = UE4.FVector(Location.X + radius, Location.Y + radius, Location.Z + halfHeight)
      if Left.X <= pos.X and Left.Y <= pos.Y and Left.Z <= pos.Z and pos.X <= Right.X and pos.Y <= Right.Y and pos.Z <= Right.Z then
        return true
      end
    end
  end
  return false
end

function BattleCraneCamera:TouchMoveCollide(Begin, End, IsCollideSphere)
  local debugType = UE4.EDrawDebugTrace.None
  local World = _G.UE4Helper.GetCurrentWorld()
  local ObjectTypes = {
    UE4.ECollisionChannel.ECC_WorldStatic,
    UE.EObjectTypeQuery.Character,
    UE.EObjectTypeQuery.Pawn
  }
  if BattleUtils.IsDeepWater() then
    table.insert(ObjectTypes, UE4.ECollisionChannel.ECC_EngineTraceChannel3)
  end
  if IsCollideSphere then
    local ResultArray = UE4.TArray(UE.AActor)
    local Success = UE4.UKismetSystemLibrary.Abs_SphereOverlapActors(World, End, 20, ObjectTypes, nil, nil, ResultArray)
    if Success then
      for i = ResultArray:Length(), 1, -1 do
        local actor = ResultArray:Get(i)
        if not actor.bHidden then
          return true
        end
      end
    end
  end
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(World, Begin, End, ObjectTypes, false, nil, debugType, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), 9999)
  if isHit then
    for i = hitResults:Length(), 1, -1 do
      local Hit = hitResults:Get(i)
      local actor = Hit.Actor
      if not actor.bHidden then
        return true
      end
    end
  end
  return false
end

function BattleCraneCamera:CacheTemporaryPosData()
  self.confData:CacheTemporaryPosData()
end

function BattleCraneCamera:ClearTemporaryPosData()
  self.confData:ClearTemporaryPosData()
end

function BattleCraneCamera:CheckCurIsCraneCamera()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  local curCamera = playerController:GetViewTarget()
  if not self.CameraActor then
    return false
  end
  return self.CameraActor == curCamera
end

return BattleCraneCamera
