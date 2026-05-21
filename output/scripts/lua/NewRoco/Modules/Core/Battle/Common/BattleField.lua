local kdTree = require("Utils.KdTree")()
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleFieldConst = require("NewRoco.Modules.Core.Battle.Common.BattleFieldConst")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local DebugUtils = require("NewRoco.Modules.Core.Scene.Common.DebugUtils")
local BattleData = {}
local BattleField = {}
BattleField.debugClientContrast = true
BattleField.EncounterRotateTable = {
  180,
  225,
  -90,
  -45,
  0,
  45,
  90,
  135
}
BattleField.OffsetTable = {
  UE4.FVector(0, -250, 0),
  UE4.FVector(158, -158, 0),
  UE4.FVector(250, 0, 0),
  UE4.FVector(158, 158, 0),
  UE4.FVector(0, 250, 0),
  UE4.FVector(-158, 158, 0),
  UE4.FVector(-250, 0, 0),
  UE4.FVector(-158, -158, 0)
}
BattleField.debugBattlePointLine = false
BattleField.debugHitWallLine = false
BattleField.debugLastEnterBattlePoint = nil
BattleField.debugLastEnterBattleRotateAns = nil
BattleField.debugLastEnterBattleOriRotate = nil
BattleField.debugLastEnterBattleRotateBit = nil
BattleField.debugLastUseFullStation = nil
BattleField.debugLastUseDataLayer = nil

function BattleField.PrepareBattleField()
  Log.Debug("BattleField.PrepareBattleField")
end

function BattleField.CalcEncounterRotate(rotate)
  local ans = 0
  local rotate = rotate or 0
  for i = 1, 8 do
    if 1 == i or 5 == i then
      if 1 == rotate % 2 then
        ans = ans + (1 << i - 1)
      end
    elseif 3 == i or 7 == i then
      if 1 == rotate / 2 % 2 then
        ans = ans + (1 << i - 1)
      end
    elseif 2 == i or 6 == i then
      if 1 == rotate / 4 % 2 then
        ans = ans + (1 << i - 1)
      end
    elseif 1 == rotate / 8 % 2 then
      ans = ans + (1 << i - 1)
    end
  end
  return ans
end

BattleField.mapData = nil
BattleField.lastDataFileName = nil
BattleField.lastDataMapID = -1

function BattleField.ChangeScene(id)
  if BattleField.lastDataFileName then
    BattleField.mapData = nil
    BattleField.lastDataFileName = nil
    BattleField.lastDataMapID = -1
  end
  local scene_res_conf = _G.DataConfigManager:GetSceneResConf(id)
  if 10003 ~= id then
    BattleField.lastDataFileName = string.format("NewRoco.Modules.Core.Battle.Data.BattleFieldData.BattleField_%s_Layer1", scene_res_conf.main_source)
    BattleField.lastDataMapID = id
  end
  UE4.UNRCBattleFieldDataManager.ClearDisplayActor()
end

function BattleField.LoadCurSceneData()
  Log.Debug("BattleField.LoadCurSceneData", BattleField.lastDataMapID, BattleField.lastDataFileName)
  if -1 ~= BattleField.lastDataMapID and BattleField.lastDataMapID ~= 10003 then
    if pcall(function(filename)
      BattleField.mapData = require(filename)
    end, BattleField.lastDataFileName) then
      Log.Debug("\230\136\152\230\150\151\233\128\137\231\130\185\230\149\176\230\141\174\229\138\160\232\189\189\230\136\144\229\138\159 ", BattleField.lastDataMapID)
    else
      Log.Error("BattleField.ChangeScene \229\189\147\229\137\141\229\133\179\229\141\161\229\143\175\232\131\189\230\178\161\230\156\137\230\136\152\230\150\151\233\128\137\231\130\185\230\149\176\230\141\174\239\188\140\232\175\183\230\163\128\230\159\165\229\175\188\229\135\186\230\181\129\230\176\180\231\186\191\230\136\150\233\133\141\231\189\174", BattleField.lastDataMapID)
    end
  end
end

function BattleField.TransAns(playerLocation, nearest, rotate)
  local squareDisToPlayer = -1
  local ans, rotateAns
  ans = nearest
  rotateAns = rotate
  BattleField.debugLastEnterBattleRotateBit = nil
  if not BattleField.debugForceForward then
    for i = 0, 7 do
      if 0 ~= rotate & 1 << i then
        local foward = i + 1
        local center = nearest + BattleField.OffsetTable[foward]
        local sqdis = (center.X - playerLocation.X) * (center.X - playerLocation.X) + (center.Y - playerLocation.Y) * (center.Y - playerLocation.Y)
        if squareDisToPlayer > sqdis or squareDisToPlayer < 0 then
          squareDisToPlayer = sqdis
          ans = center
          rotateAns = BattleField.EncounterRotateTable[foward]
          BattleField.debugLastEnterBattleRotateBit = i
        end
      end
    end
  else
    local i = BattleField.debugForceForward + 1
    if 0 == rotate & 1 << BattleField.debugForceForward then
      Log.Error("\230\179\168\230\132\143\239\188\154\232\175\165\229\188\186\229\136\182\230\150\185\229\144\145\229\174\158\233\153\133\228\184\141\229\173\152\229\156\168\239\188\140\230\181\139\232\175\149\229\143\175\232\131\189\230\151\160\230\132\143\228\185\137")
    end
    if nearest and BattleField.OffsetTable[i] then
      ans = nearest + BattleField.OffsetTable[i]
      rotateAns = BattleField.EncounterRotateTable[i]
      BattleField.debugLastEnterBattleRotateBit = BattleField.debugForceForward
    end
  end
  return ans, rotateAns
end

function BattleField.PostUseDataFromServerOrClientLocal(pos, playerLocation, bSitu, nearest, rotate, debugFlag)
  local bMoved
  if bSitu then
    nearest = pos
  end
  bMoved = not bSitu
  local ans, rotateAns
  ans, rotateAns = BattleField.TransAns(playerLocation, nearest, rotate)
  if not ans then
    Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176\229\143\175\230\136\152\230\150\151\231\130\185", pos.X, pos.Y, pos.Z)
  elseif debugFlag then
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), ans, 50, 12, UE4.FLinearColor(1, 1, 1, 1), 100)
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), UE4.FVector(ans.X, ans.Y, ans.Z + 200), 50, 12, UE4.FLinearColor(0, 0, 1, 1), 100)
  end
  local channel = {
    UE4.UNRCStatics.ConvertToObjectType(UE4.ECollisionChannel.ECC_WorldStatic)
  }
  table.insert(channel, UE4.UNRCStatics.ConvertToObjectType(UE4.ECollisionChannel.ECC_GameTraceChannel13))
  local oriAns = ans
  ans = SceneUtils.GetPosInLand_ByVisible(ans, nil, 200, 60000, nil, channel, true, debugFlag)
  if ans then
    ans = UE4.FVector(ans.X, ans.Y, ans.Z + 10)
  else
    Log.Debug("\233\128\137\231\130\185\230\151\182\232\176\131\231\148\168\232\180\180\229\156\176\229\135\189\230\149\176\229\164\177\232\180\165\239\188\140\232\153\189\231\132\182\229\143\175\232\131\189\228\184\141\229\189\177\229\147\141\230\156\128\231\187\136\231\187\147\230\158\156\239\188\140\228\189\134\229\143\175\232\131\189\230\156\137\233\154\144\230\130\163")
    ans = oriAns
  end
  Log.Debug("Final Pos", ans)
  if debugFlag or BattleField.debugBattlePointLine then
    local lineBegin = UE4.FVector(ans.X, ans.Y, ans.Z)
    local lineEnd = UE4.FVector(ans.X, ans.Y, ans.Z + 10000)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, UE4.FLinearColor(1, 0, 0, 1), 100)
    lineBegin = UE4.FVector(nearest.X, nearest.Y, nearest.Z)
    lineEnd = UE4.FVector(ans.X, ans.Y, ans.Z)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, UE4.FLinearColor(1, 1, 0, 1), 100)
    local disx = (pos.X - ans.X) / 100
    local disy = (pos.Y - ans.Y) / 100
    local disz = (pos.Z - ans.Z) / 100
    local disxy = math.sqrt(disx * disx + disy * disy)
    local disxyz = math.sqrt(disx * disx + disy * disy + disz * disz)
    local disSquare = disx * disx + disy * disy + 3 * disz * disz
    if BattleField.debugLastEnterBattleRotateBit then
      Log.PrintScreenMsgRed(string.format("rotate:%d \230\151\139\232\189\172Bit:%d", rotate, BattleField.debugLastEnterBattleRotateBit))
    else
      Log.PrintScreenMsgRed(string.format("rotate:%d", rotate))
    end
    Log.PrintScreenMsgRed(string.format("\229\185\179\233\157\162\232\183\157\231\166\187: %f, \228\184\137\231\187\180\232\183\157\231\166\187: %f, disSquare: %f", disxy, disxyz, disSquare))
    Log.PrintScreenMsgRed(string.format("Final Pos: %f, %f, %f", ans.X, ans.Y, ans.Z))
    Log.PrintScreenMsgRed(string.format("Enter Pos: %f, %f, %f", pos.X, pos.Y, pos.Z))
  end
  BattleField.debugLastEnterBattlePoint = UE4.FVector(pos.X, pos.Y, pos.Z)
  BattleField.debugLastBattleFieldAns = UE4.FVector(ans.X, ans.Y, ans.Z)
  BattleField.debugLastBattleFieldRotateAns = rotateAns
  return ans, rotateAns, bMoved
end

function BattleField.FindNearestBattlePoint(pos, playerTransform, bUseFullStation, dataLayer, debugFlag)
  if NRCEnv:IsLocalBattleMode() then
    return UE4.FVector(playerTransform.Translation.X, playerTransform.Translation.Y, playerTransform.Translation.Z)
  end
  if BattleField.debugForceEnterLocation then
    pos = BattleField.debugForceEnterLocation
  end
  if not pos then
    Log.Error("\228\189\191\231\148\168FindNearestBattlePoint\230\142\165\229\143\163\230\151\182\230\156\170\228\188\160\229\133\165\229\143\130\230\149\176")
    return
  end
  if pos.Z > 200000 then
    Log.Debug("BattleField.FindNearestBattlePoint pos.Z > 200000(@poan) ")
    return pos, 0
  end
  if nil == bUseFullStation then
    bUseFullStation = true
  end
  if 1 == BattleField.debugForceStation then
    bUseFullStation = true
  elseif 2 == BattleField.debugForceStation then
    bUseFullStation = false
  end
  BattleField.debugLastUseFullStation = bUseFullStation
  dataLayer = dataLayer or 0
  BattleField.debugLastUseDataLayer = dataLayer
  if 0 == pos.X and 0 == pos.Y then
    Log.Error("\228\189\191\231\148\168FindNearestBattlePoint\230\142\165\229\143\163\230\151\182\231\150\145\228\188\188\228\188\160\229\133\165\228\186\134\231\155\184\229\175\185\229\157\144\230\160\135 \230\179\168\239\188\154\232\175\165\230\142\165\229\143\163\229\191\133\233\161\187\228\189\191\231\148\168\231\187\157\229\175\185\229\157\144\230\160\135", pos.X, pos.Y, pos.Z)
  end
  Log.Debug("BattleField.FindNearestBattlePoint Enter pos ", pos.X, pos.Y, pos.Z)
  if BattleConst.CanBattleEverywhere then
    local rotateWhenClose = 0
    Log.Debug("BattleConst.debugForceForwardWhenClose", BattleConst.debugForceForwardWhenClose)
    if nil ~= BattleConst.debugForceForwardWhenClose then
      Log.Debug("BattleField.FindNearestBattlePoint CanBattleEverywhere Index", BattleConst.debugForceForwardWhenClose)
      rotateWhenClose = BattleField.EncounterRotateTable[BattleConst.debugForceForwardWhenClose]
    end
    Log.Debug("BattleField.FindNearestBattlePoint CanBattleEverywhere", rotateWhenClose)
    return pos, rotateWhenClose
  else
    Log.Debug("BattleField.FindNearestBattlePoint Close CanBattleEverywhere")
  end
  local sceneModule = NRCModuleManager:GetModule("SceneModule")
  if sceneModule.config and sceneModule.config.scene_res_id ~= 10003 or -1 ~= BattleField.lastDataMapID and 10003 ~= BattleField.lastDataMapID then
    if BattleField.debugUseServerBattleField then
      return pos, 0
    end
    return BattleField.FindNearestBattlePoint3D(pos, playerTransform, bUseFullStation, BattleField.mapData, debugFlag)
  end
  local playerLocation
  if playerTransform then
    playerLocation = UE4.FVector(playerTransform.Translation.X, playerTransform.Translation.Y, playerTransform.Translation.Z)
  else
    local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  end
  local nearest, rotate, oriRotate
  UE4.UNRCBattleFieldDataManager.Update(false)
  local bFind, bSitu
  local bFail = false
  if not BattleField.debugClientContrast then
    bSitu = true
    nearest = pos
    rotate = 0
    oriRotate = 0
  elseif not BattleField.debugUseServerBattleField then
    bSitu, nearest, rotate, oriRotate, bFind = UE4.UNRCBattleFieldDataManager.FindNearest(UE4.FVector(pos.X, pos.Y, pos.Z + 5), dataLayer, bUseFullStation, nil, nil, nil, nil, 1000, 33000, BattleField.debugHitWallLine)
    if UE4.UNRCBattleFieldDataManager.IsCreateAnyOne() then
      if bFind == UE4.EBattleNearestLevel.Fail then
        bFail = true
        Log.Error("\232\176\131\231\148\168\230\136\152\229\156\186\233\128\137\231\130\185\230\142\165\229\143\163\230\151\182\230\156\170\230\137\190\229\136\176\230\136\152\229\156\186\231\130\185\239\188\136\230\145\134\231\131\130\228\186\134\239\188\140330m\229\141\138\229\190\132\228\185\159\230\178\161\230\137\190\229\136\176\239\188\137")
      elseif bFind == UE4.EBattleNearestLevel.Level1 then
        bFail = true
        Log.Warning("\233\128\154\232\191\135\229\138\160\229\188\186\230\144\156\231\180\162\230\137\141\230\137\190\229\136\176\230\136\152\229\156\186\231\130\185\239\188\140\229\145\168\229\155\180\229\156\176\229\189\162\228\184\141\230\152\175\230\156\128\231\144\134\230\131\179\230\131\133\229\134\181\239\188\136Level1\239\188\137,\231\173\150\229\136\146\230\136\150\233\156\128\229\133\179\230\179\168\229\184\131\230\128\170\229\145\168\229\155\180\229\156\186\230\153\175\230\131\133\229\134\181")
      elseif bFind == UE4.EBattleNearestLevel.Level2 then
        bFail = true
        Log.Warning("\233\128\154\232\191\135\229\138\160\229\188\186\230\144\156\231\180\162\230\137\141\230\137\190\229\136\176\230\136\152\229\156\186\231\130\185\239\188\140\229\145\168\229\155\180\229\156\176\229\189\162\228\184\141\230\152\175\230\156\128\231\144\134\230\131\179\230\131\133\229\134\181\239\188\136Level2\239\188\137,\231\173\150\229\136\146\230\136\150\233\156\128\229\133\179\230\179\168\229\184\131\230\128\170\229\145\168\229\155\180\229\156\186\230\153\175\230\131\133\229\134\181")
      elseif bFind == UE4.EBattleNearestLevel.TimeOut then
        bFail = true
        Log.Error("\230\136\152\230\150\151\233\128\137\231\130\185\230\159\165\232\175\162\232\182\133\230\151\182\239\188\140\229\188\186\229\136\182\229\164\177\232\180\165\239\188\140\229\176\134\228\189\191\231\148\168\229\143\175\232\131\189\229\184\166\230\156\137\232\183\175\229\190\132\231\188\186\233\153\183\231\154\132\231\187\147\230\158\156")
      end
    end
  end
  if debugFlag then
    if bFail then
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), pos, 50, 12, UE4.FLinearColor(1, 1, 1, 1), 100)
      local lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z)
      local lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z + 10000)
      UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, UE4.FLinearColor(1, 0, 0, 1), 100)
    else
      UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), nearest, 50, 12, UE4.FLinearColor(0, 1, 0, 1), 100)
    end
  end
  return BattleField.PostUseDataFromServerOrClientLocal(pos, playerLocation, bSitu, nearest, rotate, debugFlag)
end

function BattleField.IsSuitableForFighting(pos)
  Log.Debug("SceneUtils:IsSuitableForFighting")
  local mapWidth = BattleFieldConst.mapWidth
  local mapHeight = BattleFieldConst.mapHeight
  local minx = BattleFieldConst.minx
  local miny = BattleFieldConst.miny
  local x = (pos.X / 100 - minx) / mapWidth * 4096
  local y = (pos.Y / 100 - miny) / mapHeight * 4096
  Log.Debug(x, y, 4096 - y)
  if 0 ~= color.R or 0 ~= color.G or 0 ~= color.B then
    return true
  else
    return false
  end
end

function BattleField.FindNearestBattlePoint3D(pos, playerTransform, bUseFullStation, mapData, debugFlag)
  Log.Debug("BattleField.FindNearestBattlePoint3D")
  if debugFlag or BattleField.debugBattlePointLine then
    local lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z)
    local lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z + 10000)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, UE4.FLinearColor(0, 0, 1, 1), 100)
  end
  local x = -pos.X / 100
  local y = pos.Z / 100
  local z = -pos.Y / 100
  Log.Debug("coord", x, y, z)
  local DebugQueryData = {
    x = 0,
    y = 0,
    z = 0
  }
  local data = {
    x = 0,
    y = 0,
    z = 0
  }
  local rotate = 0
  local BoundSize = 500
  local near = (BoundSize * BoundSize * BoundSize + 1) * (BoundSize * BoundSize * BoundSize + 1)
  local extendType, playerLocation
  if playerTransform then
    playerLocation = UE4.FVector(playerTransform.Translation.X, playerTransform.Translation.Y, playerTransform.Translation.Z)
  else
    local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  end
  ans, rotate, extendType = UE4.UNRCBattleFieldStatics.DebugNearestBattlePoint_SubLevel(pos, bUseFullStation, debugFlag or BattleField.debugBattlePointLine)
  local rotateAns, forwardvec
  Log.Debug("extendType", extendType)
  if -1 ~= extendType then
    forwardvec = pos - playerLocation
    forwardvec = UE4.FVector(forwardvec.X, forwardvec.Y, 0)
    forwardvec:Normalize()
    local yaxis = UE4.FVector(0, 1, 0)
    local dot = UE4.FVector.Dot(forwardvec, yaxis)
    ans = ans - forwardvec * 250
    Log.Dump(forwardvec, "forwardvec")
    Log.Debug(math.deg(math.acos(dot)))
    if forwardvec.X < 0 then
      rotateAns = math.deg(math.acos(dot)) + 180
    else
      rotateAns = -math.deg(math.acos(dot)) + 180
    end
  else
    ans, rotateAns = BattleField.TransAns(playerLocation, ans, rotate)
  end
  Log.Debug("ans", ans.X, ans.Y, ans.Z)
  if debugFlag or BattleField.debugBattlePointLine then
    local lineBegin = UE4.FVector(ans.X, ans.Y, ans.Z)
    local lineEnd = UE4.FVector(ans.X, ans.Y, ans.Z + 10000)
    UE4.UKismetSystemLibrary.Abs_DrawDebugLine(_G.UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, UE4.FLinearColor(1, 0, 0, 1), 100)
  end
  BattleField.debugLastEnterBattlePoint = UE4.FVector(pos.X, pos.Y, pos.Z)
  BattleField.debugLastBattleFieldAns = UE4.FVector(ans.X, ans.Y, ans.Z)
  BattleField.debugLastBattleFieldRotateAns = rotateAns
  BattleField.debugLastEnterBattleRotateAns = rotateAns
  return ans, rotateAns, true
end

function BattleField.GetPetSlope(debug)
  debug = debug or true
  local pet = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_TEAM, 1)
  local enemyPet = BattleManager.battlePawnManager:GetTeamPet(BattleEnum.Team.ENUM_ENEMY, 1)
  local oldCollision = true
  if oldCollision then
    pet.model:SetActorEnableCollision(false)
    enemyPet.model:SetActorEnableCollision(false)
  end
  local p1 = pet.model:Abs_K2_GetActorLocation()
  p1 = SceneUtils.GetPosInNearLand(p1, 0, nil, {pet, enemyPet}) or p1
  local p2 = enemyPet.model:Abs_K2_GetActorLocation()
  p2 = SceneUtils.GetPosInNearLand(p2, 0, nil, {pet, enemyPet}) or p2
  local xx = p1.X - p2.X
  local yy = p1.Y - p2.Y
  local zzl = p1.Z - p2.Z
  local divl = zzl * zzl / (xx * xx + yy * yy)
  local yaw, pitch1 = UE4.UKismetMathLibrary.GetYawPitchFromVector(p1 - p2)
  if debug then
    DebugUtils.DebugSegmentBox(p1, p2)
  end
  p1.Z = p1.Z + pet:GetHalfHeight()
  p2.Z = p2.Z + enemyPet:GetHalfHeight()
  local zzc = p1.Z - p2.Z
  local divc = zzc * zzc / (xx * xx + yy * yy)
  local yaw, pitch2 = UE4.UKismetMathLibrary.GetYawPitchFromVector(p1 - p2)
  if debug then
    DebugUtils.DebugSegmentBox(p1, p2)
  end
  if oldCollision then
    pet.model:SetActorEnableCollision(true)
    enemyPet.model:SetActorEnableCollision(true)
  end
  return pitch1, pitch2, divc, divl
end

function BattleField.CheckCurrent(debug)
  local valid = true
  local pitch1, pitch2, divc, divl = BattleField.GetPetSlope(debug)
  if pitch1 > BattleFieldConst.sublevelPetSlope then
    if debug then
      Log.Error("\229\157\161\229\186\166\228\184\141\230\187\161\232\182\179\232\166\129\230\177\130")
    end
    valid = false
  end
  return valid
end

local upVec = UE4.FVector(0, 0, 1)
local playerTest = {
  UE4.FVector(0, 680, 0),
  "playerPos"
}
local enemyTest = {
  UE4.FVector(0, -680, 0),
  "enemyPos"
}
local PointTests = {playerTest, enemyTest}
local EllipseTests = {
  UE4.FVector(1, 0, 0),
  UE4.FVector(0.7071, 0.7071, 0),
  UE4.FVector(0, 1, 0),
  UE4.FVector(-0.7071, 0.7071, 0),
  UE4.FVector(-1, 0, 0),
  UE4.FVector(-0.7071, -0.7071, 0),
  UE4.FVector(0, -1, 0),
  UE4.FVector(0.7071, -0.7071, 0)
}

function BattleField.UnitTest3D(pos, rotate, forceDraw)
  pos = UE4.FVector(pos.X, pos.Y, pos.Z)
  pos.Z = pos.Z + BattleFieldConst.sublevelEllipseRadius * 100 * BattleFieldConst.subLevelStepHeight
  local valid = true
  local draws = {}
  for _, test in ipairs(PointTests) do
    local vec = test[1]
    local debugInfo = test[2]
    local rotateVec = UE4.UKismetMathLibrary.RotateAngleAxis(vec, rotate, upVec)
    local endPoint = pos + rotateVec
    local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), pos, endPoint, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, false, nil, 0)
    table.insert(draws, {
      pos,
      endPoint,
      1
    })
    if Success then
      table.insert(draws, {
        Hit.ImpactPoint,
        nil,
        3
      })
      Log.Error("\229\141\149\229\133\131\230\181\139\232\175\149\233\157\158\230\179\149,\230\181\139\232\175\149\233\161\185\239\188\154", debugInfo, "\228\184\173\229\191\131\231\130\185:", DebugUtils.GetPosCopyStr(pos))
      UE4.UNRCStatics.ClipboardCopy(DebugUtils.GetPosCopyStr(pos))
      valid = false
    end
  end
  for _, test in pairs(EllipseTests) do
    local vec = UE4.FVector(test.X, test.Y, test.Z) * BattleFieldConst.sublevelEllipseRadius * 100
    vec.X = vec.X / BattleFieldConst.sublevelEllipseRatio
    local rotateVec = UE4.UKismetMathLibrary.RotateAngleAxis(vec, rotate, upVec)
    local endPoint = pos + rotateVec
    local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), pos, endPoint, UE4.ETraceTypeQuery.TraceTypeQuery_MAX, false, nil, 0)
    table.insert(draws, {
      pos,
      endPoint,
      2
    })
    if Success then
      table.insert(draws, {
        Hit.ImpactPoint,
        nil,
        3
      })
      Log.Error("\229\141\149\229\133\131\230\181\139\232\175\149\230\164\173\229\156\134\233\157\158\230\179\149, \228\184\173\229\191\131\231\130\185:", DebugUtils.GetPosCopyStr(pos))
      UE4.UNRCStatics.ClipboardCopy(DebugUtils.GetPosCopyStr(pos))
      valid = false
    end
  end
  if not valid or forceDraw then
    for _, data in pairs(draws) do
      if 1 == data[3] then
        DebugUtils.DebugSegmentSphere(data[1], data[2], 100, UE4.FLinearColor(0, 1, 0, 1))
      elseif 2 == data[3] then
        DebugUtils.DebugSegmentBox(data[1], data[2], 100, UE4.FLinearColor(0, 1, 0, 1))
      else
        DebugUtils.DebugDrawBox(data[1], 100, UE4.FLinearColor(1, 0, 0, 1))
      end
    end
  end
  return valid
end

function BattleField.RunUnitTest3D()
  local finalValid = true
  for i, d in ipairs(BattleField.mapData) do
    local data = {
      x = 0,
      y = 0,
      z = 0
    }
    local rotate, extendType
    data.x = d[4]
    data.y = d[5]
    data.z = d[6]
    rotate = d[7]
    extendType = d[8]
    if not extendType then
      local erotate = BattleField.CalcEncounterRotate(rotate)
      local ans = UE4.FVector(-data.x * 100, -data.z * 100, data.y * 100)
      local rotateAns
      for i = 0, 7 do
        if 0 ~= erotate & 1 << i then
          local foward = i + 1
          rotateAns = BattleField.EncounterRotateTable[foward]
          if not BattleField.UnitTest3D(ans, rotateAns) then
            return false
          end
        end
      end
    end
  end
  return finalValid
end

return BattleField
