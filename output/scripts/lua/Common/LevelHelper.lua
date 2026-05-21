local LevelHelper = {}
LevelHelper.Flags = {
  Default = 1,
  Main = 2,
  Battle = 4
}
LevelHelper.NavigationSource = {Dynamic = 0, Cooked = 1}
LevelHelper.NavigationSourcePreset = {
  ["/Game/ArtRes/Level/Game/BigWorld/L_Bigworld_01_Release/L_Bigworld_01_Release"] = LevelHelper.NavigationSource.Cooked,
  ["/Game/ArtRes/Level/Game/MagicAcademy/Release/MA_Release"] = LevelHelper.NavigationSource.Cooked
}

function LevelHelper:SwitchNavigationSourceByPreset(LevelName)
  if LevelHelper.NavigationSourcePreset[LevelName] == LevelHelper.NavigationSource.Cooked then
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.UseCookedNavigationData 1")
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "ai.navmesh.GNavMeshSpanShrink 1")
    Log.Debug("[NRC]SwitchNavigationSourceByPreset Cooked")
  else
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "n.UseCookedNavigationData 0")
    UE4.UKismetSystemLibrary.ExecuteConsoleCommand(nil, "ai.navmesh.GNavMeshSpanShrink 0")
    Log.Debug("[NRC]SwitchNavigationSourceByPreset Dynamic")
  end
end

function LevelHelper:IsLevelOpen(LevelName)
end

function LevelHelper:SetLevelVisibility(value)
  UE4.UGameplayStatics.SetNRCWorldVisibilityMask(_G.UE4Helper.GetCurrentWorld(), value)
end

function LevelHelper:IsStreamLevelLoaded(LevelName)
  local levelStreaming = UE4.UGameplayStatics.GetStreamingLevel(_G.UE4Helper.GetCurrentWorld(), LevelName)
  if levelStreaming and levelStreaming:IsLevelLoaded() then
    return true
  end
  return false
end

function LevelHelper:OpenLevel(LevelName, Options)
  if nil == Options then
    Options = ""
  end
  local beginWorldOrigin = UE4.FVector(0, 0, 0)
  LevelHelper:SwitchNavigationSourceByPreset(LevelName)
  UE4.UGameplayStatics.OpenLevel(_G.UE4Helper.GetCurrentWorld(), LevelName, true, Options, beginWorldOrigin)
end

function LevelHelper:OpenLevelWithOrigin(LevelName, beginWorldOrigin, Options)
  beginWorldOrigin.Z = 0
  if nil == Options then
    Options = ""
  end
  LevelHelper:SwitchNavigationSourceByPreset(LevelName)
  UE4.UNRCStatics.PreLoadMap(UE4Helper.GetCurrentWorld())
  UE4.UGameplayStatics.OpenLevel(_G.UE4Helper.GetCurrentWorld(), LevelName, true, Options, beginWorldOrigin)
end

function LevelHelper:LoadStreamLevel(LevelName, bMakeVisibleAfterLoad, bShouldBlockOnLoad, callback, callbackOwner)
  if self:IsStreamLevelLoaded(LevelName) and bMakeVisibleAfterLoad then
    self:SetShouldBeVisible(LevelName, true)
    if callback then
      if callbackOwner then
        callback(callbackOwner, true)
      else
        callback(true)
      end
    end
  else
    coroutine.resume(coroutine.create(LevelHelper._DoLatentLoad), self, LevelName, bMakeVisibleAfterLoad, bShouldBlockOnLoad, callback, callbackOwner)
  end
end

function LevelHelper:UnloadStreamLevel(LevelName, bShouldBlockOnLoad)
  coroutine.resume(coroutine.create(LevelHelper._DoLatentUnload), self, LevelName, bShouldBlockOnLoad)
end

function LevelHelper:SetShouldBeVisible(LevelName, bShouldBeVisible)
  local streamingLevel = UE4.UGameplayStatics.GetStreamingLevel(_G.UE4Helper.GetCurrentWorld(), LevelName)
  if nil ~= streamingLevel then
    streamingLevel:SetShouldBeVisible(bShouldBeVisible)
  end
end

function LevelHelper:_DoLatentLoad(LevelName, bMakeVisibleAfterLoad, bShouldBlockOnLoad, callback, callbackOwner)
  Log.DebugFormat("Start Load Level %s", LevelName)
  UE4.UGameplayStatics.LoadStreamLevel(_G.UE4Helper.GetCurrentWorld(), LevelName, bMakeVisibleAfterLoad, bShouldBlockOnLoad)
  if callback then
    if callbackOwner then
      callback(callbackOwner, true)
    else
      callback(true)
    end
  end
  Log.DebugFormat("Finish Load Level %s", LevelName)
end

function LevelHelper:_DoLatentUnload(LevelName, bShouldBlockOnLoad)
  UE4.UGameplayStatics.UnloadStreamLevel(_G.UE4Helper.GetCurrentWorld(), LevelName, bShouldBlockOnLoad)
  UE4.UKismetSystemLibrary.PrintString(_G.UE4Helper.GetCurrentWorld(), "LevelHelper:_DoLatentUnload" .. LevelName)
end

function LevelHelper:GetLevelName(bRemovePrefixString)
  if nil == bRemovePrefixString then
    bRemovePrefixString = true
  end
  return UE4.UGameplayStatics.GetCurrentLevelName(_G.UE4Helper.GetCurrentWorld(), bRemovePrefixString)
end

return LevelHelper
