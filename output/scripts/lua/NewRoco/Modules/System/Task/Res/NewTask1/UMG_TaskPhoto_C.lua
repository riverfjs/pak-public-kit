local TaskModuleEvent = reload("NewRoco.Modules.Core.Task.TaskModuleEvent")
local UMG_TaskPhoto_C = _G.NRCViewBase:Extend("UMG_TaskPhoto_C")

function UMG_TaskPhoto_C:OnConstruct()
  self.LevelSequence = nil
  self.PlayerData = nil
  self.PlayerActor = nil
  self.gender = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info.sex
  self.panelName = nil
  self.SummaryData = nil
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.bUseAvatarImageCache = false
  self.bRegistedEvent = false
  self:InitializeInfo()
end

function UMG_TaskPhoto_C:SetGender(_gender)
  self.gender = _gender
end

function UMG_TaskPhoto_C:SetpanelName(_panelName)
  self.panelName = _panelName
end

function UMG_TaskPhoto_C:OnAddEventListener()
  if not self.bRegistedEvent then
    self.bRegistedEvent = true
    self:RegisterEvent(self, TaskModuleEvent.SwitchAvatarSuitComplete, self.OnSwitchAvatarSuitComplete)
  end
end

function UMG_TaskPhoto_C:OnRemoveEventListener()
  if self.bRegistedEvent then
    self.bRegistedEvent = false
    self:UnRegisterEvent(self, TaskModuleEvent.SwitchAvatarSuitComplete)
  end
end

function UMG_TaskPhoto_C:InitializeInfo()
  local PetLevelSequence = self.previewWorld:getActorByName("PhotoSequence")
  local CameraActor = self.previewWorld:getActorByName("MainCamera")
  self.camera = self.previewWorld:getActorByName("DefaultSceneCapture")
  if self.camera then
    self.captureComponent = self.camera:GetComponentByClass(UE4.USceneCaptureComponent2D)
    self.captureComponent.bCaptureEveryFrame = false
  else
    Log.Error("\231\139\172\231\171\139\229\156\186\230\153\175\231\155\184\230\156\186\230\178\161\230\156\137\230\137\190\229\136\176,\232\175\183\230\159\165\231\156\139\229\142\159\229\155\160")
  end
  self.MainCamera = CameraActor
  self.LevelSequence = PetLevelSequence
end

function UMG_TaskPhoto_C:SetPlayerData(SummaryData, imageCacheTag)
  self.SummaryData = SummaryData
  self:SetupAvatarImageUsage(imageCacheTag)
  if self:IsUseAvatarImageCache() then
    return
  end
  self:ReleaseResLoadRequest()
  self:LoadPhotoSequence()
end

function UMG_TaskPhoto_C:splitData(states, Index, IsTransition, delimiter)
  local state_pair = string.split(states, delimiter)
  for i, str in ipairs(state_pair) do
    if i == Index then
      if IsTransition then
        return tonumber(str)
      else
        return str
      end
    end
  end
end

function UMG_TaskPhoto_C:OnDestruct()
end

function UMG_TaskPhoto_C:OnActive()
end

function UMG_TaskPhoto_C:SetPlayerAppearanceInfo()
  if self:IsUseAvatarImageCache() then
    return
  end
  if self.SummaryData and self.SummaryData.fashion then
    local fashionIds = self.SummaryData.fashion.wearing_item
    local salonIds = self.SummaryData.fashion.salon_item_data
    _G.NRCModeManager:DoCmd(TaskModuleCmd.SetDefaultSuit, self.PlayerActor, self.gender, fashionIds, salonIds, self.panelName)
  end
end

function UMG_TaskPhoto_C:SetPlayerPath()
  if not self.previewWorld or not UE4.UObject.IsValid(self.previewWorld) then
    Log.Warning("UMG_TaskPhoto_C:SetPlayerPath previewWorld is destroyed")
    return
  end
  if self:IsUseAvatarImageCache() then
    self.previewImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    return
  end
  local AvatarAssetPath = self:GetAssetPath_PlayerAvatar()
  if self:IsLoadedResByPath(AvatarAssetPath) then
    self:TrySetPlayerPath()
  else
    self:LoadPanelRes(AvatarAssetPath, -1, self.OnAssetLoaded_SetPlayerPath)
  end
  local AnimName = self:GetAssetPath_AnimSequence()
  if self:IsLoadedResByPath(AnimName) then
    self:TrySetPlayerPath()
  else
    self:LoadPanelRes(AnimName, -1, self.OnAssetLoaded_ApplyAnimSequence)
  end
end

function UMG_TaskPhoto_C:OnAssetLoaded_SetPlayerPath(resRequest, asset)
  self:TrySetPlayerPath()
end

function UMG_TaskPhoto_C:OnAssetLoaded_ApplyAnimSequence(resRequest, asset)
  self:TrySetPlayerPath()
end

function UMG_TaskPhoto_C:TrySetPlayerPath()
  local BP_CardLocalPlayer_C = self:TryGetLoadedResByPath(self:GetAssetPath_PlayerAvatar())
  if not BP_CardLocalPlayer_C then
    return
  end
  local AnimSequence = self:TryGetLoadedResByPath(self:GetAssetPath_AnimSequence())
  if not AnimSequence then
    return
  end
  local TaskSummaryConf = self:GetTaskSummary()
  if not TaskSummaryConf then
    return
  end
  local Pos = UE4.FVector()
  Pos.X = tonumber(TaskSummaryConf.pc_pos[1])
  Pos.Y = tonumber(TaskSummaryConf.pc_pos[2])
  Pos.Z = tonumber(TaskSummaryConf.pc_pos[3])
  local Rot = UE4.FRotator()
  Rot.Roll = tonumber(TaskSummaryConf.pc_pos[4])
  Rot.Pitch = tonumber(TaskSummaryConf.pc_pos[5])
  Rot.Yaw = tonumber(TaskSummaryConf.pc_pos[6])
  local Transfom = UE4.FTransform(Rot:ToQuat(), Pos)
  self.previewImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.captureComponent.showOnlyActors:Clear()
  if self.PlayerActor then
    self.previewWorld:DestroyActor(self.PlayerActor)
    self.PlayerActor = nil
  end
  self.PlayerActor = self.previewWorld:SpawnActor(BP_CardLocalPlayer_C, Transfom)
  local mesh = self.PlayerActor:GetComponentByClass(UE4.USkeletalMeshComponent)
  mesh:SetAnimationMode(UE4.EAnimationMode.AnimationSingleNode)
  mesh:OverrideAnimationData(AnimSequence, true, true)
  self:SetPlayerAppearanceInfo()
end

function UMG_TaskPhoto_C:GetAssetPath_PlayerAvatar()
  return UEPath.CARD_LOCAL_PLAYER
end

function UMG_TaskPhoto_C:GetAssetPath_AnimSequence()
  local TaskSummaryConf = self:GetTaskSummary()
  if not TaskSummaryConf then
    return
  end
  local AnimName
  if 1 == self.gender then
    AnimName = TaskSummaryConf.pc_action[1]
  else
    AnimName = TaskSummaryConf.pc_action[2]
  end
  return AnimName
end

function UMG_TaskPhoto_C:OnSwitchAvatarSuitComplete()
  self:SetShowOnlyActors()
  self:CreateAvatarImageCache()
end

function UMG_TaskPhoto_C:SetShowOnlyActors()
  self.captureComponent.showOnlyActors:Add(self.PlayerActor)
  if self.PlayerActor and self.PlayerActor.AvatarComponent then
    local Decorators = self.PlayerActor.AvatarComponent:GetDecorators()
    for k, v in tpairs(Decorators) do
      self.captureComponent.showOnlyActors:Add(v)
    end
  end
end

function UMG_TaskPhoto_C:BindingSequenceCamera()
  if self.LevelSequence and UE4.UObject.IsValid(self.LevelSequence) and self.LevelSequence.SequencePlayer and self.LevelSequence.SequencePlayer.Sequence then
    local BindingCapture = self.LevelSequence:FindNamedBindings("SceneCapture")
    if BindingCapture:Length() > 0 then
      local BindingCaptureInfo = self.LevelSequence:FindNamedBinding("SceneCapture")
      if BindingCaptureInfo then
        self.LevelSequence:SetBinding(BindingCaptureInfo, {
          self.camera
        })
      end
    end
  else
    Log.Debug("\229\186\143\229\136\151\231\155\184\230\156\186\230\137\190\228\184\141\229\136\176")
  end
end

function UMG_TaskPhoto_C:LoadPhotoSequence()
  local TaskSummaryConf = self:GetTaskSummary()
  if not TaskSummaryConf then
    return
  end
  local sequence_res = TaskSummaryConf.sequence_res
  if not sequence_res then
    Log.ErrorFormat("[UMG_TaskPhoto_C:LoadPhotoSequence], TaskSummaryConf(%s)\230\178\161\230\156\137\233\133\141\231\189\174sequence_res(\230\137\190\231\173\150\229\136\146)", TaskSummaryConf.id)
    return
  end
  self:UnLoadResByPath(sequence_res)
  self:LoadPanelRes(sequence_res, -1, self.OnAssetLoaded_PlayPhotoSequence)
end

function UMG_TaskPhoto_C:OnAssetLoaded_PlayPhotoSequence(resRequest, asset)
  if self.LevelSequence and UE4.UObject.IsValid(self.LevelSequence) and asset then
    self.LevelSequence.SequencePlayer:Stop()
    self.LevelSequence:SetSequence(asset)
    self:BindingSequenceCamera()
    self.LevelSequence.SequencePlayer:PlayLooping(999999)
  end
end

function UMG_TaskPhoto_C:SetupAvatarImageUsage(imageCacheTag)
  self.bUseAvatarImageCache = false
  self.imageCacheTag = imageCacheTag
  local cacheFilePathName = self:GetAvatarCacheImageFilePathName()
  local bFileExist = UE.UBlueprintPathsLibrary.FileExists(cacheFilePathName)
  if bFileExist then
    local bSucceed = self.previewWorld:NotifyUseAvatarImageCache(self.previewImage, cacheFilePathName)
    self.bUseAvatarImageCache = bSucceed
  else
  end
end

function UMG_TaskPhoto_C:IsUseAvatarImageCache()
  return self.bUseAvatarImageCache
end

function UMG_TaskPhoto_C:CreateAvatarImageCache()
  self.captureComponent:CaptureScene()
  local cacheFilePathName = self:GetAvatarCacheImageFilePathName()
  self.previewWorld:NotifyCreateAvatarImageCache(self.previewImage, cacheFilePathName)
  self.previewImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_TaskPhoto_C:GetAvatarCacheImageFilePathName()
  return string.format("%s%s/%s/%s_tid%s_tm%s.png", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), "TaskPhotoCache", _G.DataModelMgr.PlayerDataModel:GetPlayerUin(), self.imageCacheTag, self.SummaryData.summary_id, self.SummaryData.task_id, self.SummaryData.create_time)
end

function UMG_TaskPhoto_C:GetTaskSummary()
  local TaskSummaryConf = _G.DataConfigManager:GetTaskSummary(self.SummaryData.summary_id)
  if not TaskSummaryConf then
    Log.ErrorFormat("Invalid summary_id(%s).", tostring(summary_id))
    return
  end
  return TaskSummaryConf
end

return UMG_TaskPhoto_C
