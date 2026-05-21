local BattleCraneCameraData = NRCClass()
local BattleCraneCameraDefine = require("NewRoco.Modules.Core.Battle.CraneCamera.BattleCraneCameraDefine")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local JsonUtils = require("Common.JsonUtils")
local LineTraceUtils = require("NewRoco.Modules.Core.Battle.Common.LineTraceUtils")
local BattleDebugger = require("NewRoco.Modules.Core.Battle.Debugger.BattleDebugger")

function BattleCraneCameraData:Ctor()
  self:LoadGlobalConf()
  self.GetPosFuncMap = {}
  self:InitPosCache()
  self.GetValueFuncMap = {}
  self.CameraCfg = {}
  self:InitGetTargetPos()
  self:InitGetValueFuncMap()
  self:ClearCamCurveInfo()
  self.HasBaseDirect = false
  self.PawnManager = _G.BattleManager.battlePawnManager
  self.cameraCurveLoading = -1
  self.DefaultCurveLoading = true
  if not _G.NRCEditorEntranceEnable then
    local resRequest = _G.NRCResourceManager:LoadResAsync(self, BattleCraneCameraDefine.DefaultCameraCurve, PriorityEnum.Passive_Camera_Default, 0, function(caller, resRequest, asset)
      self.CameraDefaultCurve = asset
      self.CameraDefaultCurveRef = UnLua.Ref(asset)
      self.DefaultCurveLoading = false
    end, self.LoadCurveFailed)
  end
  self:InitCameraMode()
  self.curveAssetCache = {}
end

function BattleCraneCameraData:InitPosCache()
  self.GetPosCache = {}
  self.PetPosCache = {}
  self.PetPosCache[BattleEnum.Team.ENUM_TEAM] = {}
  self.PetPosCache[BattleEnum.Team.ENUM_ENEMY] = {}
  self.PetAverageHeight = {}
end

function BattleCraneCameraData:LoadCurveFailed(req, errMsg)
  Log.Error("LoadCameraCurveFailed errMsg=", errMsg)
end

function BattleCraneCameraData:GetCameraDefaultCurve()
  return self.CameraDefaultCurve
end

function BattleCraneCameraData:GetTargetCameraCurve()
  return self.targetCameraCurve
end

function BattleCraneCameraData:GetRatioByCameraCurve(ratio)
  if self.cameraCurveLoading > -1 then
    Log.Debug("BattleCraneCameraData.GetRatioByCameraCurve cameraCurveLoading = ", self.cameraCurveLoading)
    return ratio
  end
  if self.DefaultCurveLoading then
    Log.Debug("BattleCraneCameraData.GetRatioByCameraCurve DefaultCurveLoading = true")
    return ratio
  end
  local CameraDefaultCurve = self:GetCameraDefaultCurve()
  local targetCameraCurve = self:GetTargetCameraCurve()
  local value = ratio
  if targetCameraCurve then
    value = targetCameraCurve:GetFloatValue(ratio)
  elseif CameraDefaultCurve then
    value = CameraDefaultCurve:GetFloatValue(ratio)
  end
  return value
end

function BattleCraneCameraData:LoadTargetCameraCurve(CameraCurveEnum)
  self.targetCameraCurve = nil
  if CameraCurveEnum then
    if self.curveAssetCache[CameraCurveEnum] then
      self:SetCameraCurve(self.curveAssetCache[CameraCurveEnum].asset)
    else
      self.curCameraCurveEnum = CameraCurveEnum
      local CameraCurvePath = BattleCraneCameraDefine.CameraCurves[CameraCurveEnum]
      if CameraCurvePath then
        self.cameraCurveLoading = CameraCurveEnum
        _G.NRCResourceManager:LoadResAsync(self, CameraCurvePath, PriorityEnum.Passive_Camera_Default, 0, self.LoadCameraCurveSuccess, self.LoadCurveFailed)
      end
    end
  end
end

function BattleCraneCameraData:LoadCameraCurveSuccess(Request, Asset)
  self.curveAssetCache[self.curCameraCurveEnum] = {
    asset = Asset,
    ref = UnLua.Ref(Asset)
  }
  self:SetCameraCurve(Asset)
end

function BattleCraneCameraData:SetCameraCurve(Asset)
  self.targetCameraCurve = Asset
  self.cameraCurveLoading = -1
end

function BattleCraneCameraData:GetRotationTargetValue()
  return self.GlobalConf.RotationTargetValue or 0
end

function BattleCraneCameraData:GetZoomCfg()
  return self.GlobalConf.Length_Battle_Zoom_Rate, _G.BattleConst.BattleZoomMin, _G.BattleConst.BattleZoomMax
end

function BattleCraneCameraData:GetRotationLimitCfg()
  local RightMin = self.GlobalConf.CameraRotationGradientMapping_left1
  local RightMax = self.GlobalConf.CameraRotationGradientMapping_left2
  local LeftMin = self.GlobalConf.CameraRotationGradientMapping_right1
  local LeftMax = self.GlobalConf.CameraRotationGradientMapping_right2
  if RightMin > RightMax then
    Log.Warning("CameraRotationGradientMapping_left1 or CameraRotationGradientMapping_left2 config is error, please check BattleCraneCamera_Settings_Global.cam CameraRotationGradientMapping_left1\227\128\129CameraRotationGradientMapping_left2")
  end
  if LeftMin > LeftMax then
    Log.Warning("CameraRotationGradientMapping_right1 or CameraRotationGradientMapping_right2 config is error, please check BattleCraneCamera_Settings_Global.cam CameraRotationGradientMapping_right1\227\128\129CameraRotationGradientMapping_right2")
  end
  if RightMax > 180 or LeftMax > 180 then
    Log.Warning("CameraRotationGradientMapping_left2 or CameraRotationGradientMapping_right2 config is error, please check BattleCraneCamera_Settings_Global.cam CameraRotationGradientMapping_left2\227\128\129CameraRotationGradientMapping_right2")
  end
  return RightMin, RightMax, LeftMin, LeftMax
end

function BattleCraneCameraData:LoadGlobalConf()
  local globalDefault = {
    Slope = {X = -20, Y = 0},
    TeamPetHeight = {X = 20, Y = 140},
    EnemyPetHeight = {X = 20, Y = 210},
    PetHeightRatio = {X = 0.25, Y = 2},
    DirectPitchAngle = {X = 0, Y = 90},
    PitchX = 10,
    PitchY = 30,
    YawX = 30,
    YawY = 30,
    XSpeed = 42,
    YSpeed = 42,
    EnableDepthOfField = true,
    DepthOfFieldScale = 0.25,
    DepthOfFieldNear = 500,
    DepthOfFieldFar = 5000
  }
  local globalConf = JsonUtils.LoadCameraSettings(BattleCraneCameraDefine.CameraJsonGlobalName, nil)
  if not globalConf then
    Log.Warning("BattleCraneCameraData can't open file=" .. BattleCraneCameraDefine.CameraJsonGlobalName)
    globalConf = globalDefault
  end
  self.GlobalConf = {}
  local InputParam = BattleCraneCameraDefine.InputParam
  self.GlobalConf[InputParam.Slope] = {
    Min = math.min(globalConf.Slope.X, globalConf.Slope.Y),
    Max = math.max(globalConf.Slope.X, globalConf.Slope.Y)
  }
  self.GlobalConf[InputParam.TeamPetHeight] = {
    Min = math.min(globalConf.TeamPetHeight.X, globalConf.TeamPetHeight.Y),
    Max = math.max(globalConf.TeamPetHeight.X, globalConf.TeamPetHeight.Y)
  }
  self.GlobalConf[InputParam.EnemyPetHeight] = {
    Min = math.min(globalConf.EnemyPetHeight.X, globalConf.EnemyPetHeight.Y),
    Max = math.max(globalConf.EnemyPetHeight.X, globalConf.EnemyPetHeight.Y)
  }
  self.GlobalConf[InputParam.PetHeightRatio] = {
    Min = math.min(globalConf.PetHeightRatio.X, globalConf.PetHeightRatio.Y),
    Max = math.max(globalConf.PetHeightRatio.X, globalConf.PetHeightRatio.Y)
  }
  self.GlobalConf[InputParam.DirectPitchAngle] = {
    Min = math.min(globalConf.DirectPitchAngle.X, globalConf.DirectPitchAngle.Y),
    Max = math.max(globalConf.DirectPitchAngle.X, globalConf.DirectPitchAngle.Y)
  }
  if not globalConf.Slope2 then
    globalConf.Slope2 = {X = -20, Y = 20}
  end
  self.GlobalConf[InputParam.Slope2] = {
    Min = math.min(globalConf.Slope2.X, globalConf.Slope2.Y),
    Max = math.max(globalConf.Slope2.X, globalConf.Slope2.Y)
  }
  if not globalConf.TeamPet1Pet2HeightRatio then
    globalConf.TeamPet1Pet2HeightRatio = {X = 0.1, Y = 2}
  end
  self.GlobalConf[InputParam.TeamPet1Pet2HeightRatio] = {
    Min = math.min(globalConf.TeamPet1Pet2HeightRatio.X, globalConf.TeamPet1Pet2HeightRatio.Y),
    Max = math.max(globalConf.TeamPet1Pet2HeightRatio.X, globalConf.TeamPet1Pet2HeightRatio.Y)
  }
  self.GlobalConf.DepthOfFieldScale = globalConf.DepthOfFieldScale
  self.GlobalConf.DepthOfFieldNear = globalConf.DepthOfFieldNear
  self.GlobalConf.DepthOfFieldFar = globalConf.DepthOfFieldFar
  self.GlobalConf.EnableDepthOfField = globalConf.EnableDepthOfField
  self.GlobalConf.DefaultBlendDuration = globalConf.DefaultBlendDuration
  self.GlobalConf.CameraRotationGradientMapping_left1 = globalConf.CameraRotationGradientMapping_left1
  self.GlobalConf.CameraRotationGradientMapping_left2 = globalConf.CameraRotationGradientMapping_left2
  self.GlobalConf.CameraRotationGradientMapping_right1 = globalConf.CameraRotationGradientMapping_right1
  self.GlobalConf.CameraRotationGradientMapping_right2 = globalConf.CameraRotationGradientMapping_right2
  self.GlobalConf.Length_Battle_Zoom_Rate = globalConf.Length_Battle_Zoom_Rate
  self.GlobalConf.RotationTargetValue = globalConf.RotationTargetValue
  self.CameraFreedom = {
    PitchX = globalConf.PitchX,
    PitchY = globalConf.PitchY,
    YawX = globalConf.YawX,
    YawY = globalConf.YawY,
    XSpeed = globalConf.XSpeed,
    YSpeed = globalConf.YSpeed
  }
end

function BattleCraneCameraData:GetDefaultBlendDuration()
  return self.GlobalConf.DefaultBlendDuration or 0.5
end

function BattleCraneCameraData:ReloadCameraTag(CameraTag)
  local jsonName = BattleCraneCameraDefine.CameraJsonCfg[CameraTag]
  if not jsonName then
    return
  end
  self.CameraCfg[CameraTag] = JsonUtils.LoadCameraSettings(jsonName, {})
end

function BattleCraneCameraData:SwitchCameraMode(mode)
  self.cameraMode = mode or nil
end

function BattleCraneCameraData:GetJsonNameByCameraMode(CameraTag)
  if not self.cameraMode then
    return nil
  end
  local data = BattleCraneCameraDefine.CameraModeJson
  if data[self.cameraMode] and data[self.cameraMode][CameraTag] then
    return data[self.cameraMode][CameraTag]
  else
    return nil
  end
end

function BattleCraneCameraData:GetJsonNameByCameraTag(CameraTag)
  local jsonName = self:GetJsonNameByCameraMode(CameraTag)
  if jsonName then
    return jsonName
  end
  local battleType = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleType or 0
  if battleType == Enum.BattleType.BT_TEAM_BATTLE and BattleCraneCameraDefine.CameraJsonTeamFightCfg[CameraTag] then
    jsonName = BattleCraneCameraDefine.CameraJsonTeamFightCfg[self.CurCameraTag]
  elseif battleType == Enum.BattleType.BT_LEGENDARY_BATTLE and BattleCraneCameraDefine.CameraJsonLegendaryTeamFightCfg[CameraTag] then
    jsonName = BattleCraneCameraDefine.CameraJsonLegendaryTeamFightCfg[CameraTag]
  else
    jsonName = BattleCraneCameraDefine.CameraJsonCfg[CameraTag]
  end
  return jsonName
end

function BattleCraneCameraData:ClearCamCurveInfo()
  self.nextCameraCurveIndex = nil
  self.nextCameraCurveDuration = nil
end

function BattleCraneCameraData:UpdateCamCurveInfo(CameraTag)
  self:ClearCamCurveInfo()
  if self.CameraCurveMap and self.CameraCurveMap[CameraTag] then
    self.nextCameraCurveIndex = self.CameraCurveMap[CameraTag].Curve
    self.nextCameraCurveDuration = self.CameraCurveMap[CameraTag].Duration
  end
end

function BattleCraneCameraData:GetLastCameraTag()
  return self.lastCameraTag
end

function BattleCraneCameraData:ChangeCameraTag(CameraTag)
  self:UpdateCamCurveInfo(CameraTag)
  self.lastCameraTag = self.CurCameraTag
  self.CurCameraTag = CameraTag
  if not self.CameraCfg[self.CurCameraTag] then
    local jsonName = self:GetJsonNameByCameraTag(CameraTag)
    if not jsonName then
      Log.Error("BattleCraneCameraData.ChangeCameraTag\239\188\154jsonName\239\188\154", jsonName, "not exist")
      return
    end
    local ans = JsonUtils.LoadCameraSettings(jsonName, nil)
    if not ans then
      Log.Error("BattleCraneCameraData.ChangeCameraTag\239\188\154jsonName=", jsonName, "ans is nil")
    end
    self.CameraCfg[self.CurCameraTag] = ans
  end
  self.CraneParam = self.CameraCfg[self.CurCameraTag]
  self:InitCraneParam()
end

function BattleCraneCameraData:ChangeCameraTagByG6(G6Actors, CameraTag)
  self.G6Actors = G6Actors
  self.CurCameraTag = CameraTag
  local jsonName = self:GetJsonNameByCameraTag(CameraTag)
  if not jsonName then
    Log.Error("BattleCraneCameraData.ChangeCameraTagByG6\239\188\154jsonName\239\188\154", jsonName, "not exist")
    return
  end
  local ans = JsonUtils.LoadCameraSettings(jsonName, nil)
  self.CraneParam = ans
  self:InitCraneParam()
end

function BattleCraneCameraData:GetCurCameraTag()
  return self.CurCameraTag
end

function BattleCraneCameraData:InitCraneParam()
  local craneParam = self.CraneParam
  self.CameraName = craneParam.Desc
  self.TargetA = craneParam.TargetA
  self.TargetB = craneParam.TargetB
  if not craneParam.TargetA or not craneParam.TargetB then
    Log.Error("BattleCraneCameraDataTestLog:self.CurCameraTag=", self.CurCameraTag, "TargetA=", craneParam.TargetA, "TargetB", craneParam.TargetB, "jsonName =", self:GetJsonNameByCameraTag(self.CurCameraTag))
  end
  self.SpringArmRotation = craneParam.SpringArmRotation or {
    X = 0,
    Y = 0,
    Z = 0
  }
  self.SpringArmOffset = craneParam.SpringArmOffset or {
    X = 0,
    Y = 0,
    Z = 0
  }
  self.SprintArmLength = craneParam.SprintArmLength or 500
  self.CameraFov = craneParam.CameraFov
  local controllerCfg = craneParam.ControllerArray
  local controllerArray = {}
  if controllerCfg then
    for _, cfg in pairs(controllerCfg) do
      local tmp = {}
      tmp.IsEnable = cfg.IsEnable
      tmp.InputType = cfg.InputType
      tmp.EffectType = cfg.EffectType
      tmp.Interval = cfg.Interval
      table.insert(controllerArray, tmp)
    end
  end
  self.ControllerArray = controllerArray
  self:ResetCameraCurveMap(craneParam.CurvesArray)
end

function BattleCraneCameraData:ResetCameraCurveMap(CurvesArray)
  local CameraCurveMap = {}
  if CurvesArray then
    for _, cfg in pairs(CurvesArray) do
      if cfg.IsEnable then
        CameraCurveMap[cfg.TargetCameraId] = {
          Curve = cfg.CurveId,
          Duration = cfg.Duration
        }
      end
    end
  end
  self.CameraCurveMap = CameraCurveMap
end

function BattleCraneCameraData:ResetEnableDepthOfField(EnableDepthOfField, DepthOfFieldScale)
  self.globalConf.EnableDepthOfField = EnableDepthOfField
  self.globalConf.DepthOfFieldScale = DepthOfFieldScale
end

function BattleCraneCameraData:CacheTemporaryPosData()
  self.CacheTemporaryPos = {}
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.TeamPet] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.TeamPet1] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet1)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.TeamPet2] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet2)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.TeamPet3] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet3)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.TeamPet4] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet4)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.EnemyPet] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.EnemyPet1] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet1)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.EnemyPet2] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet2)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.EnemyPet3] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet3)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.EnemyPet4] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet4)
  self.CacheTemporaryPos[BattleCraneCameraDefine.TargetType.MySelfPet] = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.MySelfPet)
end

function BattleCraneCameraData:ClearTemporaryPosData()
  self.CacheTemporaryPos = nil
end

function BattleCraneCameraData:GetPosByTargetType(TargetType)
  if self.CacheTemporaryPos and self.CacheTemporaryPos[TargetType] then
    return self.CacheTemporaryPos[TargetType]
  end
  if (TargetType == BattleCraneCameraDefine.TargetType.TeamPlayer or TargetType == BattleCraneCameraDefine.TargetType.EnemyPlayer) and self.GetPosCache[TargetType] then
    return self.GetPosCache[TargetType]
  end
  local func = self.GetPosFuncMap[TargetType]
  if func then
    local ret = func()
    if not ret then
      if self.GetPosCache[TargetType] then
        ret = self.GetPosCache[TargetType]
      end
      if not ret then
        Log.Error("BattleCraneCameraData:GetPosByTargetType is nil 1, TargetType=", TargetType)
        return nil
      end
    end
    self.GetPosCache[TargetType] = UE4.FVector(ret.X, ret.Y, ret.Z)
    return ret
  else
    Log.Error("BattleCraneCameraData:GetPosByTargetType is nil 2, TargetType=", TargetType)
  end
  return nil
end

function BattleCraneCameraData:InitGetTargetPos()
  local targetType = BattleCraneCameraDefine.TargetType
  self.GetPosFuncMap = {
    [targetType.TeamPet] = function()
      return self:GetTeamPetPos(BattleEnum.Team.ENUM_TEAM, 0)
    end,
    [targetType.EnemyPet] = function()
      return self:GetTeamPetPos(BattleEnum.Team.ENUM_ENEMY, 0)
    end,
    [targetType.TeamPlayer] = function()
      return self:GetTeamPlayerPos()
    end,
    [targetType.EnemyPlayer] = function()
      return self:GetEnemyPlayerPos()
    end,
    [targetType.TeamPet1] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_TEAM, 1)
    end,
    [targetType.TeamPet2] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_TEAM, 2)
    end,
    [targetType.EnemyPet1] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_ENEMY, 1)
    end,
    [targetType.EnemyPet2] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_ENEMY, 2)
    end,
    [targetType.TeamPet3] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_TEAM, 3)
    end,
    [targetType.EnemyPet3] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_ENEMY, 3)
    end,
    [targetType.TeamPet4] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_TEAM, 4)
    end,
    [targetType.EnemyPet4] = function()
      return self:GetPetPosByIndex(BattleEnum.Team.ENUM_ENEMY, 4)
    end,
    [targetType.MySelfPet] = function()
      return self:GetAppointTeamPetPos(_G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM), 0)
    end
  }
end

function BattleCraneCameraData:GetTeamPetPosInG6Editor(Type, IsGround)
  local pets
  if Type == BattleEnum.Team.ENUM_TEAM then
    pets = self.G6Actors.TeamPets
  else
    pets = self.G6Actors.EnemyPets
  end
  local petNum = 0
  local locations = UE4.FVector(0, 0, 0)
  for _, pet in pairs(pets) do
    local pos = pet:K2_GetActorLocation()
    if pos then
      petNum = petNum + 1
      locations = locations + pos
    end
  end
  if 0 == petNum then
    return locations
  end
  local ret = locations / petNum
  if 1 == IsGround then
    ret.Z = 0
  end
  return ret
end

function BattleCraneCameraData:GetAppointTeamPetPos(team, IsGround)
  if not team then
    Log.Error("BattleCraneCameraData\227\128\130GetAppointTeamPetPos.Func \232\142\183\229\143\150\230\136\152\229\156\186\229\134\133\229\157\144\230\160\135\229\164\177\232\180\165")
    return BattleManager.vBattleField:GetBattleFieldCenter()
  end
  local Type = team.teamEnm
  local pets = team:GetPets()
  local petNum = 0
  local locations = _G.FVectorZero
  for _, pet in pairs(pets) do
    if not pet:IsDead() then
      local Loc = self:GetValidPosByPet(pet, true)
      if Loc then
        locations = locations + Loc
        petNum = petNum + 1
      end
    end
  end
  if 0 == petNum then
    local petPos = team.player.FirstPetPosInField or 0
    local answer = self:GetPosByTeamIndex(Type, petPos + 1)
    if not answer then
      Log.Error("BattleCraneCameraData\227\128\130GetAppointTeamPetPos.Func \232\142\183\229\143\150\230\136\152\229\156\186\229\134\133\229\157\144\230\160\135\229\164\177\232\180\165 Type=", Type)
    end
    if 0 == IsGround then
      answer.Z = answer.Z + self:GetTeamPlayerHeight(team.teamEnm)
    end
    return answer
  end
  local ret = locations / petNum
  if 1 == IsGround then
    local ret1, _ = LineTraceUtils.GetPointValidLocationByLine(ret, 1000, false)
    if not ret1 then
      Log.Warning("BattleCraneCameraData\227\128\130GetAppointTeamPetPos.Func \229\175\187\230\137\190\232\180\180\229\156\176\229\164\177\232\180\165\239\188\140\229\143\175\232\131\189\230\178\161\230\156\137\229\156\176\229\189\162\239\188\140\229\143\175\232\131\189\230\136\152\229\156\186\231\154\132\229\157\144\230\160\135\228\189\141\231\189\174\229\164\170\233\171\152")
      self.PetPosCache[Type][IsGround] = ret
      return ret
    else
      self.PetPosCache[Type][IsGround] = ret1
      return ret1
    end
  else
    self.PetPosCache[Type][IsGround] = ret
    return ret
  end
end

function BattleCraneCameraData:GetTeamPetPos(Type, IsGround)
  if _G.NRCEditorEntranceEnable then
    return self:GetTeamPetPosInG6Editor(Type, IsGround)
  end
  if self.CacheTemporaryPos and self.CacheTemporaryPos[Type] then
    local ret = self.CacheTemporaryPos[Type]
    if 1 == IsGround then
      local ret1, _ = LineTraceUtils.GetPointValidLocationByLine(ret, 1000, false)
      if ret1 then
        return ret1
      else
        return ret
      end
    else
      return ret
    end
  end
  local PawnManager = _G.BattleManager.battlePawnManager
  local pets = {}
  if Type == BattleEnum.Team.ENUM_TEAM then
    pets = PawnManager:GetPlayerTeamPets()
  else
    pets = PawnManager:GetEnemyAllPets()
  end
  local petNum = 0
  local locations = _G.FVectorZero
  for _, pet in pairs(pets) do
    if not pet:IsDead() and not pet.card:IsCheerPet() and not pet.card:IsPetInPrepareZone() then
      local Loc = self:GetValidPosByPet(pet, true)
      if 1 == BattleDebugger.enableVisualizeEnterBattleCamera then
        UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), Loc - UE4.FVector(0, 0, 150), Loc + UE4.FVector(0, 0, 150), UE4.FLinearColor(0, 1, 0, 1), 30, 3)
      end
      if Loc then
        locations = locations + Loc
        petNum = petNum + 1
      end
    end
  end
  if 0 == petNum then
    local answer = self:GetPosByTeamIndex(Type, 1)
    if not answer then
      Log.Error("BattleCraneCameraData\227\128\130GetTeamPetPos.Func \232\142\183\229\143\150\230\136\152\229\156\186\229\134\133\229\157\144\230\160\135\229\164\177\232\180\165 Type=", Type)
    end
    if 0 == IsGround then
      answer.Z = answer.Z + self:GetTeamPlayerHeight(Type)
    end
    return answer
  end
  local ret = locations / petNum
  if 1 == BattleDebugger.enableVisualizeEnterBattleCamera then
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), ret - UE4.FVector(0, 0, 100), ret + UE4.FVector(0, 0, 100), UE4.FLinearColor(0, 1, 0, 1), 30, 5)
  end
  if 1 == IsGround then
    local ret1, _ = LineTraceUtils.GetPointValidLocationByLine(ret, 1000, false)
    if not ret1 then
      Log.Warning("BattleCraneCameraData\227\128\130GetTeamPetPos.Func \229\175\187\230\137\190\232\180\180\229\156\176\229\164\177\232\180\165\239\188\140\229\143\175\232\131\189\230\178\161\230\156\137\229\156\176\229\189\162\239\188\140\229\143\175\232\131\189\230\136\152\229\156\186\231\154\132\229\157\144\230\160\135\228\189\141\231\189\174\229\164\170\233\171\152")
      self.PetPosCache[Type][IsGround] = ret
      return ret
    else
      self.PetPosCache[Type][IsGround] = ret1
      return ret1
    end
  else
    self.PetPosCache[Type][IsGround] = ret
    return ret
  end
end

function BattleCraneCameraData:GetTeamPlayerPosInG6Editor()
  if #self.G6Actors.TeamPlayers > 0 then
    return self.G6Actors.TeamPlayers[1]:K2_GetActorLocation()
  else
    Log.Error("\229\176\157\232\175\149\232\142\183\229\143\150\230\136\145\230\150\185\228\186\186\231\137\169\228\189\141\231\189\174\239\188\140G6\233\135\140\228\184\141\229\173\152\229\156\168\230\136\145\230\150\185\228\186\186\231\137\169")
  end
end

function BattleCraneCameraData:GetTeamPlayerHeight(Team)
  if _G.NRCEditorEntranceEnable then
    return 0
  end
  local player
  if Team == BattleEnum.Team.ENUM_TEAM then
    player = _G.BattleManager.battlePawnManager:GetPlayerMyTeam()
  else
    player = _G.BattleManager.battlePawnManager:GetPlayerEnemyTeam()
  end
  if not player then
    return 0
  end
  if player.model and UE.UObject.IsValid(player.model) then
    local answer = player.model:GetHalfHeight() or 0
    return answer
  end
  return 0
end

function BattleCraneCameraData:GetTeamPlayerPos()
  if _G.NRCEditorEntranceEnable then
    return self:GetTeamPlayerPosInG6Editor()
  end
  local team = _G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  if not team then
    Log.Error("\230\136\152\230\150\151\229\134\133\231\155\184\230\156\186\229\176\157\232\175\149\232\142\183\229\143\150\230\149\140\230\150\185\233\152\159\228\188\141\231\178\190\231\129\181\229\164\177\232\180\165\239\188\140\230\163\128\230\159\165\231\155\184\229\133\179\233\128\187\232\190\145")
    return _G.BattleManager.vBattleField:GetBattleFieldCenter()
  end
  local playerActor = team.player
  if not playerActor or not playerActor.model then
    Log.Error("BattleCraneCameraData:GetTeamPlayerPos playerActor is nil")
    return self:GetTeamPetPos(BattleEnum.Team.ENUM_TEAM, 1)
  end
  if playerActor.model and UE.UObject.IsValid(playerActor.model) then
    return playerActor.model:Abs_K2_GetActorLocation()
  end
  return _G.BattleManager.vBattleField:GetBattleFieldCenter()
end

function BattleCraneCameraData:GetEnemyPlayerPosInG6Editor()
  if self.G6Actors.EnemyPlayers:Length() > 0 then
    return self.G6Actors.EnemyPlayers[1]:K2_GetActorLocation()
  else
    Log.Error("\229\176\157\232\175\149\232\142\183\229\143\150\230\136\145\230\150\185\228\186\186\231\137\169\228\189\141\231\189\174\239\188\140G6\233\135\140\228\184\141\229\173\152\229\156\168\230\136\145\230\150\185\228\186\186\231\137\169")
  end
end

function BattleCraneCameraData:GetEnemyPlayerPos()
  local playerActor = _G.BattleManager.battlePawnManager:GetTeam(BattleEnum.Team.ENUM_ENEMY).player
  if not playerActor or not playerActor.model then
    Log.Error("BattleCraneCameraData:GetEnemyPlayerPos playerActor is nil")
    return self:GetTeamPetPos(BattleEnum.Team.ENUM_ENEMY, 1)
  end
  if playerActor.model then
    return playerActor.model:Abs_K2_GetActorLocation()
  end
  return _G.BattleManager.vBattleField:GetBattleFieldCenter()
end

function BattleCraneCameraData:GetPosByTeamIndex(TeamEnm, Index)
  local PosTransForm = _G.BattleManager.vBattleField:GetPositionInBattleMap(TeamEnm, Index)
  if PosTransForm then
    return UE4.FVector(PosTransForm.Translation.X, PosTransForm.Translation.Y, PosTransForm.Translation.Z)
  else
    return _G.BattleManager.vBattleField:GetBattleFieldCenter()
  end
end

function BattleCraneCameraData:GetPetPosByIndexInG6Editor(Type, Index)
  local pets
  if Type == BattleEnum.Team.ENUM_TEAM then
    pets = self.G6Actors.TeamPets
  else
    pets = self.G6Actors.EnemyPets
  end
  if pets[Index] then
    return pets[Index]:K2_GetActorLocation()
  else
    if pets[1] then
      return pets[1]:K2_GetActorLocation()
    end
    Log.Error("\229\176\157\232\175\149\232\142\183\229\143\150\231\172\172", Index, "\229\143\170\231\178\190\231\129\181\231\154\132\229\157\144\230\160\135\239\188\140G6\233\135\140\229\185\182\228\184\141\229\173\152\229\156\168\232\175\165\228\189\141\231\189\174\231\178\190\231\129\181")
    return self:GetCraneCamBattleFieldCenter()
  end
end

function BattleCraneCameraData:GetPetPosByIndex(Type, Index)
  if _G.NRCEditorEntranceEnable then
    local ans = self:GetPetPosByIndexInG6Editor(Type, Index)
    return ans
  end
  local Pet, Location
  local PawnManager = _G.BattleManager.battlePawnManager
  if not PawnManager:IsValid() then
    return self:GetValidPosByPet(nil)
  end
  if Type == BattleEnum.Team.ENUM_TEAM then
    Pet = PawnManager:GetPetByPos(Type, Index)
    if not Pet then
      if 1 == Index then
        Pet = PawnManager:GetFirstPet(Type)
      else
        Pet = PawnManager:GetLastPet(Type)
      end
    end
    if not Pet then
      Location = self:GetPosByTeamIndex(BattleEnum.Team.ENUM_TEAM, Index)
      return Location
    end
  elseif Type == BattleEnum.Team.ENUM_ENEMY then
    Pet = PawnManager:GetPetByPos(Type, Index)
    if not Pet then
      if 1 == Index then
        Pet = PawnManager:GetFirstPet(Type)
      else
        Pet = PawnManager:GetLastPet(Type)
      end
    end
    if not Pet then
      Location = self:GetPosByTeamIndex(BattleEnum.Team.ENUM_ENEMY, Index)
      return Location
    end
  end
  return self:GetValidPosByPet(Pet, true)
end

function BattleCraneCameraData:GetValidPosByPet(Pet, bIsFinal)
  local Location
  if Pet then
    local PModel = Pet.model
    local FinalPetTransform = _G.BattleManager.vBattleField:GetPetBornPosition(Pet.teamEnm, Pet.card.posInField, Pet.card, bIsFinal)
    if FinalPetTransform then
      Location = UE4.FVector(FinalPetTransform.Translation.X, FinalPetTransform.Translation.Y, FinalPetTransform.Translation.Z)
    end
    if Location then
      if PModel and UE4.UObject.IsValid(PModel) and not self:IsStandInLeaf(Pet) then
        Location.Z = Location.Z + (PModel:GetHalfHeight() or 0)
      end
    elseif PModel and UE4.UObject.IsValid(PModel) then
      Location = PModel:Abs_K2_GetActorLocation()
    end
  end
  return Location
end

function BattleCraneCameraData:IsStandInLeaf(Pet)
  if _G.BattleUtils.IsDeepWater() and Pet:GetCanSwimming() then
    return true
  end
  return false
end

function BattleCraneCameraData:GetSlopeByPos(pos1, pos2)
  if nil == pos1 or nil == pos2 then
    return 0
  end
  local teamPetPos2D = UE.FVector2D(pos1.X, pos1.Y)
  local enemyPetPos2D = UE.FVector2D(pos2.X, pos2.Y)
  local distance2d = UE4.UKismetMathLibrary.Distance2D(teamPetPos2D, enemyPetPos2D)
  local Height = pos1.Z - pos2.Z
  if 0 == distance2d then
    return 0
  end
  return math.atan(Height, distance2d) * (180 / math.pi)
end

function BattleCraneCameraData:CalcSlope()
  local teamPetPos = self:GetTeamPetPos(BattleEnum.Team.ENUM_TEAM, 1)
  local enemyPetPos = self:GetTeamPetPos(BattleEnum.Team.ENUM_ENEMY, 1)
  if nil == teamPetPos or nil == enemyPetPos then
    return 0
  end
  return self:GetSlopeByPos(teamPetPos, enemyPetPos)
end

function BattleCraneCameraData:CalcSlope2()
  local pos1, pos2
  if _G.NRCEditorEntranceEnable then
    pos1 = self.G6Actors.PreviewCameraActor:K2_GetActorLocation()
    pos2 = self.CurLookPos
  else
    pos1, pos2 = _G.BattleManager.vBattleField.battleCraneCamera:GetCameraComponentAndActorPos()
  end
  if not pos1 or not pos2 then
    return 0
  end
  return self:GetSlopeByPos(pos1, pos2)
end

function BattleCraneCameraData:GetTeamPet1Pet2HeightRatioInG6Editor(Team)
  local pets
  if Team == BattleEnum.Team.ENUM_TEAM then
    pets = self.G6Actors.TeamPets
  else
    pets = self.G6Actors.EnemyPets
  end
  if pets[1] and pets[2] then
    local height1 = pets[1]:GetHalfHeight()
    local height2 = pets[2]:GetHalfHeight()
    return height1 / height2
  end
  return 1
end

function BattleCraneCameraData:GetTeamPet1Pet2HeightRatio()
  local Team = BattleEnum.Team.ENUM_TEAM
  if _G.NRCEditorEntranceEnable then
    local ans = self:GetTeamPet1Pet2HeightRatioInG6Editor(Team)
    return ans
  end
  local PawnManager = _G.BattleManager.battlePawnManager
  local pets = {}
  if Team == BattleEnum.Team.ENUM_TEAM then
    pets = PawnManager:GetTeamAllPets()
  else
    pets = PawnManager:GetEnemyAllPets()
  end
  if pets[1] and pets[2] then
    local height1 = pets[1]:GetHalfHeight()
    local height2 = pets[2]:GetHalfHeight()
    return height1 / height2
  end
  return 1
end

function BattleCraneCameraData:GetPetHeightByTypeInG6Editor(Type)
  local pets
  if Type == BattleEnum.Team.ENUM_TEAM then
    pets = self.G6Actors.TeamPets
  else
    pets = self.G6Actors.EnemyPets
  end
  local petHeight = 0
  local petNum = 0
  for _, pet in pairs(pets) do
    if pet and pet:GetHalfHeight() then
      petHeight = petHeight + pet:GetHalfHeight()
      petNum = petNum + 1
    end
  end
  if 0 == petNum then
    return 0
  end
  return petHeight / petNum
end

function BattleCraneCameraData:GetPetHeightByType(Team)
  if _G.NRCEditorEntranceEnable then
    local ans = self:GetPetHeightByTypeInG6Editor(Team)
    return ans
  end
  if self.PetAverageHeight[Team] then
    return self.PetAverageHeight[Team]
  end
  local PawnManager = _G.BattleManager.battlePawnManager
  local pets = {}
  if Team == BattleEnum.Team.ENUM_TEAM then
    pets = PawnManager:GetTeamAllPets()
  else
    pets = PawnManager:GetEnemyAllPets()
  end
  local petNum = 0
  local petHeight = 0
  for _, pet in pairs(pets) do
    if not pet:IsDead() then
      local PModel = pet and pet.model
      if PModel and PModel:GetHalfHeight() then
        petHeight = petHeight + PModel:GetHalfHeight()
        petNum = petNum + 1
      end
    end
  end
  if 0 == petNum then
    return self:GetTeamPlayerHeight(Team)
  end
  local answer = petHeight / petNum
  self.PetAverageHeight[Team] = answer
  return answer
end

function BattleCraneCameraData:GetPetHeightRatio()
  local fz = self:GetPetHeightByType(BattleEnum.Team.ENUM_TEAM)
  local fm = self:GetPetHeightByType(BattleEnum.Team.ENUM_ENEMY)
  if 0 == fm then
    return 0
  end
  return fz / fm
end

function BattleCraneCameraData:GetDirectPitchAngle()
  if self.BaseRotation then
    return self.BaseRotation.Pitch
  else
    return 0
  end
end

function BattleCraneCameraData:InitGetValueFuncMap()
  local controllerInputType = BattleCraneCameraDefine.InputParam
  self.GetValueFuncMap = {
    [controllerInputType.Slope] = function()
      return self:CalcSlope()
    end,
    [controllerInputType.TeamPetHeight] = function()
      return self:GetPetHeightByType(BattleEnum.Team.ENUM_TEAM)
    end,
    [controllerInputType.EnemyPetHeight] = function()
      return self:GetPetHeightByType(BattleEnum.Team.ENUM_ENEMY)
    end,
    [controllerInputType.PetHeightRatio] = function()
      return self:GetPetHeightRatio()
    end,
    [controllerInputType.DirectPitchAngle] = function()
      return self:GetDirectPitchAngle()
    end,
    [controllerInputType.Slope2] = function()
      return self:CalcSlope2()
    end,
    [controllerInputType.TeamPet1Pet2HeightRatio] = function()
      return self:GetTeamPet1Pet2HeightRatio()
    end
  }
end

function BattleCraneCameraData:GetValueByInputType(InputType)
  local func = self.GetValueFuncMap and self.GetValueFuncMap[InputType] or nil
  if func then
    return func()
  end
  return 0
end

function BattleCraneCameraData:CalcValueByType(InputType, Interval)
  local globalConf = self.GlobalConf
  local interVal = globalConf[InputType]
  local a1 = math.min(interVal.Min, interVal.Max)
  local b1 = math.max(interVal.Min, interVal.Max)
  local a2 = Interval.X
  local b2 = Interval.Y
  local x = self:GetValueByInputType(InputType)
  x = math.max(x, interVal.Min)
  x = math.min(x, interVal.Max)
  local fm = b1 - a1
  if 0 == fm then
    Log.Error("BattleCraneCameraData CalcValueByType is zero: InputType=", InputType, "interVal=", interVal, "\232\175\183\230\163\128\230\159\165\230\145\135\232\135\130\231\155\184\230\156\186\229\133\168\229\177\128\233\133\141\231\189\174")
    return 0
  end
  local res = a2 - (a2 - b2) * (x - a1) / (b1 - a1)
  Log.Debug("BattleCraneCameraData.res is :" .. res)
  return res
end

function BattleCraneCameraData:GetEnvParam()
  local function checkFunc(interVal, x)
    x = math.max(x, interVal.Min)
    
    x = math.min(x, interVal.Max)
    return x
  end
  
  local globalConf = self.GlobalConf
  local InputParam = BattleCraneCameraDefine.InputParam
  local info = {}
  info.slope = self:CalcSlope()
  info.TeamPetHeight = self:GetPetHeightByType(BattleEnum.Team.ENUM_TEAM)
  info.EnemyPetHeight = self:GetPetHeightByType(BattleEnum.Team.ENUM_ENEMY)
  info.TeamEnemyRatio = self:GetPetHeightRatio()
  info.DirectPitchAngle = self:GetDirectPitchAngle()
  info.slopeClamp = checkFunc(globalConf[InputParam.Slope], info.slope)
  info.TeamPetHeightClamp = checkFunc(globalConf[InputParam.TeamPetHeight], info.TeamPetHeight)
  info.EnemyPetHeightClamp = checkFunc(globalConf[InputParam.EnemyPetHeight], info.EnemyPetHeight)
  info.TeamEnemyRatioClamp = checkFunc(globalConf[InputParam.PetHeightRatio], info.TeamEnemyRatio)
  info.DirectPitchAngleClamp = checkFunc(globalConf[InputParam.DirectPitchAngle], info.DirectPitchAngle)
  info.slope2 = self:CalcSlope2()
  if globalConf[InputParam.Slope2] then
    info.slope2Clamp = checkFunc(globalConf[InputParam.Slope2], info.slope2)
  else
    info.slope2Clamp = 0
  end
  info.TeamPet1Pet2HeightRatio = self:GetTeamPet1Pet2HeightRatio()
  if globalConf[InputParam.TeamPet1Pet2HeightRatio] then
    info.TeamPet1Pet2HeightRatioClamp = checkFunc(globalConf[InputParam.TeamPet1Pet2HeightRatio], info.TeamPet1Pet2HeightRatio)
  else
    info.TeamPet1Pet2HeightRatioClamp = 0
  end
  return info
end

function BattleCraneCameraData:GetCurCraneParam()
  return self.CraneParam
end

function BattleCraneCameraData:ResetCameraBaseInfo(TargetA, TargetB, SpringArmOffset, SpringArmRotation, SprintArmLength, CameraFov)
  self.TargetA = TargetA
  self.TargetB = TargetB
  self.SpringArmOffset = {
    X = SpringArmOffset.X,
    Y = SpringArmOffset.Y,
    Z = SpringArmOffset.Z
  }
  self.SpringArmRotation = SpringArmRotation
  self.SprintArmLength = SprintArmLength
  self.CameraFov = CameraFov
end

function BattleCraneCameraData:ResetGlobalInfo(SlopeX, SlopeY, TeamPetHeightX, TeamPetHeightY, EnemyPetHeightX, EnemyPetHeightY, HeightRatioX, HeightRatioY, PitchX, PitchY, YawX, YawY, XSpeed, YSpeed, PitchAngleX, PitchAngleY)
  local InputParam = BattleCraneCameraDefine.InputParam
  self.GlobalConf[InputParam.Slope] = {
    Min = math.min(SlopeX, SlopeY),
    Max = math.max(SlopeX, SlopeY)
  }
  self.GlobalConf[InputParam.TeamPetHeight] = {
    Min = math.min(TeamPetHeightX, TeamPetHeightY),
    Max = math.max(TeamPetHeightX, TeamPetHeightY)
  }
  self.GlobalConf[InputParam.EnemyPetHeight] = {
    Min = math.min(EnemyPetHeightX, EnemyPetHeightY),
    Max = math.max(EnemyPetHeightX, EnemyPetHeightY)
  }
  self.GlobalConf[InputParam.PetHeightRatio] = {
    Min = math.min(HeightRatioX, HeightRatioY),
    Max = math.max(HeightRatioX, HeightRatioY)
  }
  self.GlobalConf[InputParam.DirectPitchAngle] = {
    Min = math.min(PitchAngleX, PitchAngleY),
    Max = math.max(PitchAngleX, PitchAngleY)
  }
  self.CameraFreedom.PitchX = PitchX
  self.CameraFreedom.PitchY = PitchY
  self.CameraFreedom.YawX = YawX
  self.CameraFreedom.YawY = YawY
  if XSpeed then
    self.CameraFreedom.XSpeed = XSpeed
  end
  if YSpeed then
    self.CameraFreedom.YSpeed = YSpeed
  end
end

function BattleCraneCameraData:ResetGlobalInfoTwo(Slope2X, Slope2Y, MyPet1Pet2HeightRatioX, MyPet1Pet2HeightRatioY)
  local InputParam = BattleCraneCameraDefine.InputParam
  self.GlobalConf[InputParam.Slope2] = {
    Min = math.min(Slope2X, Slope2Y),
    Max = math.max(Slope2X, Slope2Y)
  }
  self.GlobalConf[InputParam.TeamPet1Pet2HeightRatio] = {
    Min = math.min(MyPet1Pet2HeightRatioX, MyPet1Pet2HeightRatioY),
    Max = math.max(MyPet1Pet2HeightRatioX, MyPet1Pet2HeightRatioY)
  }
end

function BattleCraneCameraData:ResetControlArray(controllerCfg)
  local controllerArray = {}
  for _, cfg in tpairs(controllerCfg) do
    local tmp = {}
    tmp.IsEnable = cfg.IsEnable
    tmp.InputType = cfg.InputType
    tmp.EffectType = cfg.EffectType
    local Interval = {}
    Interval.X = cfg.IntervalX
    Interval.Y = cfg.IntervalY
    tmp.Interval = Interval
    table.insert(controllerArray, tmp)
  end
  self.ControllerArray = controllerArray
end

function BattleCraneCameraData:GetCurPointRatio()
  return self.CurPointRatio or 0.5
end

function BattleCraneCameraData:GetCraneCamBattleFieldCenter()
  if _G.NRCEditorEntranceEnable then
    return self.G6Actors.CenterLocation
  else
    return _G.BattleManager.vBattleField:GetBattleFieldCenter()
  end
end

function BattleCraneCameraData:CalcBaseLookPos(TargetType1, TargetType2, TargetOffset)
  local battleCenter = self:GetCraneCamBattleFieldCenter()
  self.targetPos1 = self:GetPosByTargetType(TargetType1) or battleCenter
  self.targetPos2 = self:GetPosByTargetType(TargetType2) or battleCenter
  if not self.targetPos1 then
    return
  end
  if not self.targetPos2 then
    return
  end
  self.targetHeight1 = self.targetPos1
  self.targetHeight2 = self.targetPos2
  self.BasePointRatio = 0.5
  self.CurPointRatio = 0.5
  self.BaseTargetOffset = TargetOffset
  local posDiff = self.targetPos2 - self.targetPos1
  self.BaseLookPos = UE4.UKismetMathLibrary.Add_VectorVector(UE4.UKismetMathLibrary.Multiply_VectorFloat(posDiff, self.CurPointRatio), self.targetPos1)
end

function BattleCraneCameraData:CalcCurLookPosByRatio(CurRatio)
  local posDiff = self.targetPos2 - self.targetPos1
  local BaseLookPos = UE4.UKismetMathLibrary.Add_VectorVector(UE4.UKismetMathLibrary.Multiply_VectorFloat(posDiff, CurRatio), self.targetPos1)
  local springArmRot = UE4.FRotator(self.BaseSprintArmRotation.Pitch, self.BaseSprintArmRotation.Yaw, self.BaseSprintArmRotation.Roll)
  local RotVect = springArmRot:ToVector()
  RotVect:Normalize()
  local UpVector = UE4.FVector(0, 0, 1)
  local xDirect = UE4.UKismetMathLibrary.ProjectVectorOnToPlane(RotVect, UpVector)
  local yDirect = UE4.UKismetMathLibrary.Cross_VectorVector(xDirect, UpVector)
  local zDirect = -UpVector
  local targetOffset = xDirect * self.BaseTargetOffset.X + yDirect * self.BaseTargetOffset.Y + zDirect * self.BaseTargetOffset.Z
  self.CurLookPos = UE4.UKismetMathLibrary.Add_VectorVector(BaseLookPos, targetOffset)
  return self.CurLookPos
end

function BattleCraneCameraData:GetCurLookPos()
  return self.CurLookPos
end

function BattleCraneCameraData:ModifyCurLookPos(x, y, z)
  self.CurLookPos.X = self.CurLookPos.X + x
  self.CurLookPos.Y = self.CurLookPos.Y + y
  self.CurLookPos.Z = self.CurLookPos.Z + z
end

function BattleCraneCameraData:GetBaseLookPos()
  return self.BaseLookPos
end

function BattleCraneCameraData:CalcBaseRotation()
  self.HasBaseDirect = true
  self.TeamPetPos = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.TeamPet)
  self.EnemyPetPos = self:GetPosByTargetType(BattleCraneCameraDefine.TargetType.EnemyPet)
  if self.TeamPetPos and self.EnemyPetPos then
    local PetDirect = self.EnemyPetPos - self.TeamPetPos
    if 1 == BattleDebugger.enableVisualizeEnterBattleCamera then
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.EnemyPetPos, self.TeamPetPos, UE4.FLinearColor(1, 0, 0, 1), 30, 5)
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.TeamPetPos, self.TeamPetPos - UE4.FVector(0, 0, 100), UE4.FLinearColor(1, 0, 0, 1), 30, 5)
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), self.EnemyPetPos, self.EnemyPetPos - UE4.FVector(0, 0, 100), UE4.FLinearColor(1, 0, 0, 1), 30, 5)
    end
    PetDirect:Normalize()
    self.BasePetDirect = PetDirect
    self.BaseRotation = PetDirect:ToRotator()
  end
end

function BattleCraneCameraData:GetBaseRotation()
  return self.BaseRotation
end

function BattleCraneCameraData:CalcBaseSpringArmRot(SpringArmRotation)
  self.SpringArmRotOffset = SpringArmRotation
  self.BaseSprintArmRotation = UE4.FRotator(0, self.BaseRotation.Yaw, self.BaseRotation.Roll)
  self.BaseSprintArmRotation.Roll = self.BaseSprintArmRotation.Roll + (SpringArmRotation and SpringArmRotation.X or 0)
  self.BaseSprintArmRotation.Pitch = self.BaseSprintArmRotation.Pitch + (SpringArmRotation and SpringArmRotation.Y or 0)
  self.BaseSprintArmRotation.Yaw = self.BaseSprintArmRotation.Yaw + (SpringArmRotation and SpringArmRotation.Z or 0)
  self.SpringArmRotPlus = UE4.FRotator(0, 0, 0)
  return self.BaseSprintArmRotation
end

function BattleCraneCameraData:GetBaseSpringArmRotation()
  return self.BaseSprintArmRotation
end

function BattleCraneCameraData:ModifySprintArmRotationPlus(Pitch, Yaw, Roll)
  self.SpringArmRotPlus.Pitch = self.SpringArmRotPlus.Pitch + Pitch
  self.SpringArmRotPlus.Yaw = self.SpringArmRotPlus.Yaw + Yaw
  self.SpringArmRotPlus.Roll = self.SpringArmRotPlus.Roll + Roll
end

function BattleCraneCameraData:GetBattleSprintArmRotationPlus()
  return self.SpringArmRotPlus or UE4.FRotatorZero
end

function BattleCraneCameraData:SetPointRatio(Ratio)
  self.CurPointRatio = Ratio
  local CurLookPos = self:CalcCurLookPosByRatio(Ratio)
  self.CurLookPos = CurLookPos
  local camTransform = UE4.UKismetMathLibrary.MakeTransform(CurLookPos, _G.FRotatorZero, UE4.FVector(1, 1, 1))
  return camTransform
end

function BattleCraneCameraData:GetTargetPos()
  return self.targetPos1, self.targetPos2
end

function BattleCraneCameraData:GetTargetHeight()
  return self.targetHeight1, self.targetHeight2
end

function BattleCraneCameraData:ModifyTargetHeight(x, y)
  self.targetHeight1 = self.targetHeight1 + x
  self.targetHeight2 = self.targetHeight2 + y
end

function BattleCraneCameraData:GetCtrlArrayInputVal()
  return self.ctrlArrayInputVal
end

function BattleCraneCameraData:GetGlobalDepthInfo()
  local globalConf = self.GlobalConf
  return globalConf.EnableDepthOfField, globalConf.DepthOfFieldScale, globalConf.DepthOfFieldNear, globalConf.DepthOfFieldFar
end

function BattleCraneCameraData:InitCameraMode()
  self.cameraMode = BattleCraneCameraDefine.CameraMode.default
  local battleType = _G.BattleManager.battleRuntimeData and _G.BattleManager.battleRuntimeData.battleType or 0
  if battleType == Enum.BattleType.BT_TEAM_BATTLE then
    self.cameraMode = BattleCraneCameraDefine.CameraMode.teamBattle
  elseif battleType == Enum.BattleType.BT_LEGENDARY_BATTLE then
    self.cameraMode = BattleCraneCameraDefine.CameraMode.legendaryTeamFight
  elseif 1 == _G.BattleManager.battleRuntimeData.playerNumber and 2 == _G.BattleManager.battleRuntimeData.playerPetNumber then
    self.cameraMode = BattleCraneCameraDefine.CameraMode.onePlayerTwoPet
  end
end

return BattleCraneCameraData
