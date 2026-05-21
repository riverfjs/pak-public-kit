local UE4Helper = {}

function UE4Helper.GetCurrentWorld()
  if RocoEnv.IS_EDITOR and _G.NRCEditorEntranceEnable then
    return nil
  end
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    return GameInstance:GetWorld()
  else
  end
  return nil
end

UE4Helper.UpVector = UE4.FVector(0, 0, 1)
UE4Helper.ZeroVector = UE4.FVector(0, 0, 0)
UE4Helper.OneVector = UE4.FVector(1, 1, 1)
UE4Helper.InvalidVector = UE4.FVector()
UE4Helper.IdentityRotator = UE4.FRotator(0, 0, 0)

function UE4Helper.IsZeroVector(InVector)
  if InVector and InVector == UE4Helper.ZeroVector then
    return true
  end
  return false
end

function UE4Helper.IsNonZeroVector(InVector)
  return InVector and not UE4Helper.IsZeroVector(InVector)
end

function UE4Helper.GetPlayerCharacter(PlayerIndex)
  return UE4.UGameplayStatics.GetPlayerCharacter(UE4Helper.GetCurrentWorld(), PlayerIndex)
end

function UE4Helper.GetTime()
  return _G.UpdateManager.Timestamp
end

function UE4Helper.PrintScreenMsg(Msg)
  UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), Msg, true, true, UE4.FLinearColor(1, 1, 0, 1), 20)
end

function UE4Helper.PrintScreenMsgRed(Msg)
  UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), Msg, true, true, UE4.FLinearColor(1, 0, 0, 1), 20)
end

function UE4Helper.PrintScreenMsgBlue(Msg)
  UE4.UKismetSystemLibrary.PrintString(UE4Helper.GetCurrentWorld(), Msg, true, true, UE4.FLinearColor(0, 0.4, 1, 1), 20)
end

local WorldRenderingPersistentFlag = _G.MakeWeakTable({}, "k")

local function ShouldEnableWorldRendering(enableDesired)
  local enable = enableDesired
  if not enableDesired then
    if next(WorldRenderingPersistentFlag) then
      for _, _desiredEnable in pairs(WorldRenderingPersistentFlag) do
        if _desiredEnable then
          Log.Debug("ShouldEnableWorldRendering persistentFlag: ", _)
          enable = true
          break
        end
      end
    elseif nil == enableDesired then
      enable = true
    end
  end
  return enable
end

function UE4Helper.SetEnableWorldRendering(enableDesired, delay, persistentFlag)
  delay = delay and true or false
  if _G.RocoEnv.IS_EDITOR then
    Log.Trace("SetEnableWorldRendering", enableDesired, delay, persistentFlag)
  else
    Log.Debug("SetEnableWorldRendering", enableDesired, delay, persistentFlag)
  end
  if persistentFlag then
    local persistentFlagExists = WorldRenderingPersistentFlag[persistentFlag]
    if nil ~= persistentFlagExists and persistentFlagExists ~= enableDesired then
      WorldRenderingPersistentFlag[persistentFlag] = nil
    else
      WorldRenderingPersistentFlag[persistentFlag] = enableDesired
    end
  end
  local shouldEnable = ShouldEnableWorldRendering(enableDesired)
  if shouldEnable ~= enableDesired then
    enableDesired = shouldEnable
    delay = false
  end
  UE4.UNRCTUIStatics.SetEnableUIOnlyRendering(not enableDesired, delay)
  return enableDesired
end

function UE4Helper.GetEnableWorldRendering()
  return not UE4.UNRCTUIStatics.GetEnableUIOnlyRendering()
end

function UE4Helper.GetWorldRenderingDebugData()
  local debugData = {}
  debugData.WorldRendering = UE4Helper.GetEnableWorldRendering()
  debugData.PersistentFlag = WorldRenderingPersistentFlag
  return debugData
end

function UE4Helper.IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(UE4Helper.GetCurrentWorld()):IsPCMode()
end

function UE4Helper.SetPCInputEnable(caller, enable, flag)
  local isPCMode = UE4Helper.IsPCMode()
  if not isPCMode then
    return
  end
  if _G.PlayerModuleCmd then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      localPlayer.inputComponent:SetInputEnable(caller, enable, flag)
    end
  end
end

function UE4Helper.ToggleInput(caller, enabled, flag)
  if string.IsNilOrEmpty(flag) then
    Log.Error("UE4Helper.ToggleInput\228\188\160\229\133\165\231\154\132flag\228\184\141\229\135\134\228\184\186\231\169\186\239\188\129")
    return
  end
  if not _G.PlayerModuleCmd then
    return
  end
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  enabled = enabled and true or false
  localPlayer.inputComponent:SetInputEnable(caller, enabled, flag)
  if enabled then
    return
  end
  localPlayer:Stop()
  local View = localPlayer.viewObj
  if UE.UObject.IsValid(View) then
    View.CharacterMovement:ConsumeInputVector()
    View.CharacterMovement:ConsumeInputVector()
  end
end

function UE4Helper.ToggleCursor(show, flag)
  Log.Error("UE4Helper.ToggleCursor \229\183\178\231\187\143\229\186\159\229\188\131\239\188\140\228\189\191\231\148\168SetDesiredShowCursor\229\146\140ReleaseDesiredShowCursor\239\188\140\228\189\191\231\148\168\232\175\180\230\152\142\232\167\129\229\175\185\229\186\148\229\135\189\230\149\176")
end

function UE4Helper.InitCursorFlag()
  UE.UNRCEnhancedInputHelper.InitCursor()
end

function UE4Helper.SetDesiredShowCursor(desiredShowCursor, flag, bForce)
  if string.IsNilOrEmpty(flag) then
    Log.Error("UE4Helper.SetDesiredShowCursor\228\188\160\229\133\165\231\154\132flag\228\184\141\229\135\134\228\184\186\231\169\186\239\188\129")
    return
  end
  if desiredShowCursor and RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    UE4.UNRCTUIStatics.ReleaseCursorCapture(0)
  end
  UE.UNRCEnhancedInputHelper.SetDesiredShowCursor(desiredShowCursor, flag, bForce)
end

function UE4Helper.ReleaseDesiredShowCursor(flag)
  if string.IsNilOrEmpty(flag) then
    Log.Error("UE4Helper.ReleaseDesiredShowCursor\228\188\160\229\133\165\231\154\132flag\228\184\141\229\135\134\228\184\186\231\169\186\239\188\129")
    return
  end
  UE.UNRCEnhancedInputHelper.ReleaseDesiredShowCursor(flag)
end

UE4Helper.ResLoadMode = {
  Default = math.maxinteger,
  LowSpeed = 1,
  FullSpeed = 2
}

function UE4Helper.SetDesiredResLoadMode(mode, flag)
  if not mode then
    Log.Error("UE4Helper.SetDesiredResLoadMode. mode should not be nil\239\188\129")
    return
  end
  if string.IsNilOrEmpty(flag) then
    Log.Error("UE4Helper.SetDesiredResLoadMode. flag should not be empty\239\188\129")
    return
  end
  local DesiredResLoadModeFlags = UE4Helper.DesiredResLoadModeFlags
  if not DesiredResLoadModeFlags then
    DesiredResLoadModeFlags = {}
    UE4Helper.DesiredResLoadModeFlags = DesiredResLoadModeFlags
  end
  
  local function GetEffectingResLoadMode()
    local retMode = UE4Helper.ResLoadMode.Default
    for m, v in pairs(DesiredResLoadModeFlags) do
      if next(v) and m < retMode then
        retMode = m
      end
    end
    return retMode
  end
  
  local effectingMode = GetEffectingResLoadMode()
  for _, v in pairs(DesiredResLoadModeFlags) do
    v[flag] = nil
  end
  if mode ~= UE4Helper.ResLoadMode.Default then
    local v = DesiredResLoadModeFlags[mode]
    if not v then
      v = {}
      DesiredResLoadModeFlags[mode] = v
    end
    v[flag] = true
  end
  local curEffectingMode = GetEffectingResLoadMode()
  if curEffectingMode ~= effectingMode then
    if curEffectingMode == UE4Helper.ResLoadMode.FullSpeed then
      UE4.UNRCStatics.ExecConsoleCommand("s.HeavyToRenderThreadPostLoadMask 0")
    else
      UE4.UNRCStatics.ExecConsoleCommand("s.HeavyToRenderThreadPostLoadMask 7")
    end
  end
end

function UE4Helper.GetDesiredResLoadModeDebugData()
  local modeNames = {}
  for str, v in pairs(UE4Helper.ResLoadMode) do
    modeNames[v] = str
  end
  local debugData = {}
  local resLoadModeFlags = {}
  debugData.ResLoadModeFlags = resLoadModeFlags
  local curMode = UE4Helper.ResLoadMode.Default
  local DesiredResLoadModeFlags = UE4Helper.DesiredResLoadModeFlags
  if DesiredResLoadModeFlags then
    for m, v in pairs(DesiredResLoadModeFlags) do
      if v and next(v) then
        local modeName = modeNames[m]
        local modeFlags = {}
        resLoadModeFlags[modeName] = modeFlags
        for flag, flagStatus in pairs(v) do
          if flagStatus then
            table.insert(modeFlags, flag)
          end
        end
        if m < curMode then
          curMode = m
        end
      end
    end
  end
  debugData.CurResLoadMode = modeNames[curMode]
  return debugData
end

_G.UE4Helper = UE4Helper
