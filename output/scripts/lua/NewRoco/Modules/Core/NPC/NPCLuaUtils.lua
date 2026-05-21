local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCLuaUtils = {}

function NPCLuaUtils.GetSenseInfo(option)
  local CompassConf = _G.DataConfigManager:GetNpcCompassOption(option.config.id)
  if not CompassConf then
    return 0, NPCModuleEnum.SenseTypeEnum.NoSense
  end
  local action = CompassConf.action
  local first_compass_option_type = action.first_compass_option_type
  local next_compass_option_type = action.next_compass_option_type
  local num = action.sense_dist
  local dist = num * num * 10000
  local opt_dist = option:GetSquaredDistance()
  dist = math.max(dist, opt_dist)
  if 0 == option.optionInfo.succ_exec_times then
    if first_compass_option_type == _G.Enum.CompassType.CT_ALL_DISTANCE then
      return dist, NPCModuleEnum.SenseTypeEnum.TotalSense
    elseif first_compass_option_type == _G.Enum.CompassType.CT_OPT_DISTANCE then
      return opt_dist, NPCModuleEnum.SenseTypeEnum.InteractableSense
    elseif first_compass_option_type == _G.Enum.CompassType.CT_NO_DISTANCE then
      return 0, NPCModuleEnum.SenseTypeEnum.NoSense
    end
  elseif next_compass_option_type == _G.Enum.CompassType.CT_ALL_DISTANCE then
    return dist, NPCModuleEnum.SenseTypeEnum.TotalSense
  elseif next_compass_option_type == _G.Enum.CompassType.CT_OPT_DISTANCE then
    return opt_dist, NPCModuleEnum.SenseTypeEnum.InteractableSense
  elseif next_compass_option_type == _G.Enum.CompassType.CT_NO_DISTANCE then
    return 0, NPCModuleEnum.SenseTypeEnum.NoSense
  end
  return 0, NPCModuleEnum.SenseTypeEnum.NoSense
end

function NPCLuaUtils.HasValidPoint(npcInfo)
  if not npcInfo then
    return false
  end
  local BaseInfo = npcInfo.base
  if not BaseInfo then
    return false
  end
  local NPCBase = npcInfo.npc_base
  if NPCBase and NPCBase.pos_need_adjust then
    return false
  end
  local Point = npcInfo.base.pt
  if not Point then
    return false
  end
  local Pos = Point.pos
  if not Pos then
    return false
  end
  if 0 == Pos.x and 0 == Pos.y and 0 == Pos.z then
    return false
  end
  return true
end

NPCLuaUtils.PreLoadMap = {}

function NPCLuaUtils.PreLoad(url, priority)
  if NPCLuaUtils.PreLoadMap[url] then
    Log.Warning("Already Request PreLoad")
    return
  end
  priority = priority or 1
  _G.NRCResourceManager:LoadResAsync(NPCLuaUtils.PreLoadMap, url, priority, 0, NPCLuaUtils.OnResLoadSucc, nil, nil)
end

function NPCLuaUtils:OnResLoadSucc(req, class)
  req.class = class
  req.classRef = class and UnLua.Ref(class)
  NPCLuaUtils.PreLoadMap[req.assetPath] = req
end

function NPCLuaUtils.GetClass(url)
  if NPCLuaUtils.PreLoadMap[url] then
    return NPCLuaUtils.PreLoadMap[url].class
  else
    Log.Error("\230\178\161\230\156\137\229\138\160\232\189\189\229\165\189\232\181\132\230\186\144\239\188\140\229\144\140\230\173\165\229\138\160\232\189\189\239\188\140\232\176\131\231\148\168\229\136\176\232\191\153\233\135\140\232\175\180\230\152\142\228\184\141\229\164\170\229\175\185\229\138\178", url)
    return UE4.UClass.Load(url)
  end
end

NPCLuaUtils.BallResRefMap = {}
NPCLuaUtils.BallResHandlerMap = {}
NPCLuaUtils.BallResHandlerRefMap = {}

function NPCLuaUtils.BatchLoadBallRes(ball_id, ball_view, priority)
  if not UE.UObject.IsValid(ball_view) then
    return
  end
  local batchLoader = NPCLuaUtils.BallResHandlerMap[ball_id]
  if batchLoader and UE.UObject.IsValid(batchLoader) then
    if not NPCLuaUtils.BallResRefMap[ball_id] then
      NPCLuaUtils.BallResRefMap[ball_id] = {}
    end
    local RefMap = NPCLuaUtils.BallResRefMap[ball_id]
    RefMap[ball_view] = true
    return
  end
  local BatchLoader = NewObject(UE4.UASyncResourceRequestBatch, UE4.UNRCPlatformGameInstance.GetInstance())
  local BatchLoaderRef = UnLua.Ref(BatchLoader)
  ball_view:PreLoadResMap(BatchLoader, priority, "", false, nil, nil, nil, true)
  if not NPCLuaUtils.BallResRefMap[ball_id] then
    NPCLuaUtils.BallResRefMap[ball_id] = {}
  end
  local RefMap = NPCLuaUtils.BallResRefMap[ball_id]
  RefMap[ball_view] = true
  NPCLuaUtils.BallResHandlerMap[ball_id] = BatchLoader
  NPCLuaUtils.BallResHandlerRefMap[ball_id] = BatchLoaderRef
end

function NPCLuaUtils.BatchReleaseBallRes(ball_id, ball_view)
  local refMap = NPCLuaUtils.BallResRefMap[ball_id]
  if refMap then
    refMap[ball_view] = nil
  end
  if table.isEmpty(refMap) then
    NPCLuaUtils.BallResRefMap[ball_id] = nil
    local batchLoader = NPCLuaUtils.BallResHandlerMap[ball_id]
    local batchLoaderRef = NPCLuaUtils.BallResHandlerRefMap[ball_id]
    if UE.UObject.IsValid(batchLoader) then
      batchLoader:Cancel()
    end
    if UE4.UObject.IsValid(batchLoaderRef) then
      UnLua.Unref(batchLoaderRef)
    end
    NPCLuaUtils.BallResHandlerMap[ball_id] = nil
    NPCLuaUtils.BallResHandlerRefMap[ball_id] = nil
  end
end

function NPCLuaUtils.BindNpcViewObj(Npc, ViewObj)
  if Npc.viewObj or ViewObj.sceneCharacter then
    Log.Error("[PlaceableNpc] sceneNpc or viewNpc is not clear when placeable npc bind")
  end
  Npc:SetViewObj(ViewObj)
  if Npc.luaObj then
    Npc.luaObj:SetViewObj(ViewObj)
  end
  ViewObj:Init()
  ViewObj:SetSceneCharacter(Npc)
  ViewObj:LuaBeginPlay()
end

local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")

function NPCLuaUtils.SetCharacterAlpha(CharacterView, TargetAlpha, Duration, OnFinishedCallback)
  local Task = NPCLuaUtils.MakeSetAlphaTask(CharacterView, TargetAlpha, Duration)
  if Task then
    Task(OnFinishedCallback)
  elseif OnFinishedCallback then
    OnFinishedCallback(false, false)
  end
end

function NPCLuaUtils.MakeSetAlphaTask(CharacterView, TargetAlpha, Duration)
  if not (CharacterView and UE.UObject.IsValid(CharacterView) and CharacterView.SetMeshAlpha and TargetAlpha) or not Duration then
    return nil
  end
  local Task = a.task(function()
    if not UE.UObject.IsValid(CharacterView) then
      return false
    end
    local StartAlpha = CharacterView.alpha
    local CurAlpha = StartAlpha
    local Elapsed = 0
    local Dt = 0
    local Alpha2Set = 0
    while Elapsed <= Duration do
      if not UE.UObject.IsValid(CharacterView) then
        return false
      end
      Elapsed = Elapsed + Dt
      Alpha2Set = math.clamp(Elapsed / Duration, 0, 1)
      CurAlpha = LuaMathUtils.LerpWithAlpha(StartAlpha, TargetAlpha, Alpha2Set)
      CharacterView:SetMeshAlpha(CurAlpha)
      Dt = a.wait(au.NextTick())
    end
    CharacterView:SetMeshAlpha(TargetAlpha)
    return true
  end)
  return Task
end

function NPCLuaUtils.ResetPet(CharacterView, Duration, TargetPos, TargetRotation, OnTeleportedCallback)
  if not (CharacterView and UE.UObject.IsValid(CharacterView) and CharacterView.SetMeshAlpha) or not Duration then
    return
  end
  local TeleportTask = a.task(function()
    local SceneNpc = CharacterView.sceneCharacter
    if not (CharacterView and UE.UObject.IsValid(CharacterView)) or not SceneNpc then
      return
    end
    if SceneNpc.InteractionComponent then
      SceneNpc.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.ANY, false)
    end
    if SceneNpc.AIComponent then
      SceneNpc.AIComponent:ForceLockForReason(true, false, _G.AIDefines.LockReason.HIDDEN)
    end
    a.wait(NPCLuaUtils.MakeSetAlphaTask(CharacterView, 1, Duration))
    if not (CharacterView and UE.UObject.IsValid(CharacterView)) or not SceneNpc then
      return
    end
    CharacterView:SetActorLocation(TargetPos or SceneNpc.serverPos)
    CharacterView:K2_SetActorRotation(TargetRotation or SceneNpc.serverDataRotate, false)
    if OnTeleportedCallback then
      OnTeleportedCallback()
    end
    if SceneNpc.AIComponent then
      SceneNpc.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.HIDDEN)
    end
    a.wait(au.NextTick())
    a.wait(NPCLuaUtils.MakeSetAlphaTask(CharacterView, 0, Duration))
  end)
  return TeleportTask(function()
    local SceneNpc = CharacterView.sceneCharacter
    if not (CharacterView and UE.UObject.IsValid(CharacterView)) or not SceneNpc then
      return
    end
    if SceneNpc.InteractionComponent then
      SceneNpc.InteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.ANY, false)
    end
    if SceneNpc.AIComponent then
      SceneNpc.AIComponent:ForceLockForReason(false, false, _G.AIDefines.LockReason.HIDDEN)
    end
  end)
end

function NPCLuaUtils.SetCustomDepth(Actor, Depth)
  if not UE4.UObject.IsValid(Actor) then
    return
  end
  local Comps = Actor:K2_GetComponentsByClass(UE.UMeshComponent)
  for _, Comp in tpairs(Comps) do
    if not Comp:IsA(UE.UWidgetComponent) then
      NPCLuaUtils.SetCompCustomDepth(Comp, Depth)
    end
  end
  local ChildActorComps = Actor:K2_GetComponentsByClass(UE.UChildActorComponent)
  for _, Comp in tpairs(ChildActorComps) do
    if Comp:IsA(UE.UChildActorComponent) then
      local childActor = Comp:GetChildActor()
      if UE4.UObject.IsValid(childActor) then
        NPCLuaUtils.SetCustomDepth(childActor, Depth)
      end
    end
  end
end

function NPCLuaUtils.SetCompCustomDepth(Comp, Depth)
  if not Comp or not UE.UObject.IsValid(Comp) then
    return
  end
  if nil == Depth then
    Comp:SetRenderCustomDepth(false)
    Comp:SetCustomDepthStencilValue(0)
    Comp:SetCastShadow(true)
  else
    Comp:SetRenderCustomDepth(true)
    Comp:SetCustomDepthStencilValue(Depth)
    Comp:SetCastShadow(false)
    Log.Debug("[NPCLuaUtils] SetCompCustomDepth", Depth)
  end
end

return NPCLuaUtils
