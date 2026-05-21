local UMG_LiqueFactionLoader_C = _G.NRCPanelBase:Extend("UMG_LiqueFactionLoader_C")
local UpVector = UE.FVector(0, 0, 60)
local LogicStatusToPlayerCondition = {
  [ProtoEnum.SpaceActorLogicStatus.SALS_TEST] = ProtoEnum.PlayerConditionType.PCT_TEST,
  [ProtoEnum.SpaceActorLogicStatus.SALS_DUNGEON] = ProtoEnum.PlayerConditionType.PCT_DUNGEON,
  [ProtoEnum.SpaceActorLogicStatus.SALS_OPEN_UI_NOT_FULL_SCENE] = ProtoEnum.PlayerConditionType.PCT_UI,
  [ProtoEnum.SpaceActorLogicStatus.SALS_OPEN_UI_FULL_SCENE] = ProtoEnum.PlayerConditionType.PCT_FULLSCREEN_UI,
  [ProtoEnum.SpaceActorLogicStatus.SALS_PLAY_CG] = ProtoEnum.PlayerConditionType.PCT_CG,
  [ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING] = ProtoEnum.PlayerConditionType.PCT_BATTLE,
  [ProtoEnum.SpaceActorLogicStatus.SALS_INTERACTING] = ProtoEnum.PlayerConditionType.PCT_OPTION,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TELEPORT] = ProtoEnum.PlayerConditionType.PCT_TELEPORT,
  [ProtoEnum.SpaceActorLogicStatus.SALE_REVIVE] = ProtoEnum.PlayerConditionType.PCT_REVIVE,
  [ProtoEnum.SpaceActorLogicStatus.SALS_MATCHING] = ProtoEnum.PlayerConditionType.PCT_MATCHING,
  [ProtoEnum.SpaceActorLogicStatus.SALS_MINI_GAME] = ProtoEnum.PlayerConditionType.PCT_MINI_GAME,
  [ProtoEnum.SpaceActorLogicStatus.SALS_UNINTERRUPTIBLE_INTERACTING] = ProtoEnum.PlayerConditionType.PCT_UNINTERRUPTIBLE_INTERACTING,
  [ProtoEnum.SpaceActorLogicStatus.SALS_VISITING] = ProtoEnum.PlayerConditionType.PCT_VISITING,
  [ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT] = ProtoEnum.PlayerConditionType.PCT_WORLD_COMBATING,
  [ProtoEnum.SpaceActorLogicStatus.SALS_CHANGE_EGG] = ProtoEnum.PlayerConditionType.PCT_CHANGE_EGG,
  [ProtoEnum.SpaceActorLogicStatus.SALS_PK_PREPARE] = ProtoEnum.PlayerConditionType.PCT_PK_PREPARE,
  [ProtoEnum.SpaceActorLogicStatus.SALS_INVITE] = ProtoEnum.PlayerConditionType.PCT_INVITE,
  [ProtoEnum.SpaceActorLogicStatus.SALS_PLAYER_INTERACT_INVITE] = ProtoEnum.PlayerConditionType.PCT_PLAYER_INTERACT_INVITE,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TRANSFORM] = ProtoEnum.PlayerConditionType.PCT_TRANSFORMED,
  [ProtoEnum.SpaceActorLogicStatus.SALS_DOUBLE_RIDE_GUEST] = ProtoEnum.PlayerConditionType.PCT_DOUBLE_RIDE_GUEST,
  [ProtoEnum.SpaceActorLogicStatus.SALS_STATIC_SCENE_NOPK] = ProtoEnum.PlayerConditionType.PCT_STATIC_SCENE_NOPK,
  [ProtoEnum.SpaceActorLogicStatus.SALS_STATIC_SCENE_TYPEA] = ProtoEnum.PlayerConditionType.PCT_STATIC_SCENE_TYPEA,
  [ProtoEnum.SpaceActorLogicStatus.SALS_STATIC_SCENE_TYPEB] = ProtoEnum.PlayerConditionType.PCT_STATIC_SCENE_TYPEB,
  [ProtoEnum.SpaceActorLogicStatus.SALS_STATIC_SCENE_TYPEC] = ProtoEnum.PlayerConditionType.PCT_STATIC_SCENE_TYPEC,
  [ProtoEnum.SpaceActorLogicStatus.SALS_STATIC_SCENE_TYPED] = ProtoEnum.PlayerConditionType.PCT_STATIC_SCENE_TYPED,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_HANDHELD] = ProtoEnum.PlayerConditionType.PCT_TAKE_PHOTO_HANDHELD,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_TRIPOD_CAMERA] = ProtoEnum.PlayerConditionType.PCT_TAKE_PHOTO_TRIPOD_CAMERA,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_TRIPOD_WORLD] = ProtoEnum.PlayerConditionType.PCT_TAKE_PHOTO_TRIPOD_WORLD,
  [ProtoEnum.SpaceActorLogicStatus.SALS_TAKE_PHOTO_MYSELF] = ProtoEnum.PlayerConditionType.PCT_TAKE_PHOTO_MYSELF,
  [ProtoEnum.SpaceActorLogicStatus.SALS_HOLD_HANDS_LEADER] = ProtoEnum.PlayerConditionType.PCT_HOLD_HANDS_LEADER,
  [ProtoEnum.SpaceActorLogicStatus.SALS_HOLD_HANDS_GUEST] = ProtoEnum.PlayerConditionType.PCT_HOLD_HANDS_GUEST,
  [ProtoEnum.SpaceActorLogicStatus.SALS_SIT_DOWN] = ProtoEnum.PlayerConditionType.PCT_SITDOWN,
  [ProtoEnum.SpaceActorLogicStatus.SALS_OPEN_PLAYER_RELATIONSHIP_TREE] = ProtoEnum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE
}

function UMG_LiqueFactionLoader_C:OnConstruct()
  self:BindAimUMG()
  self.AimUmgLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
end

function UMG_LiqueFactionLoader_C:OnLoadWidgetCallback()
  self:OnCancel(true)
end

function UMG_LiqueFactionLoader_C:OnWandChanged()
  self:BindAimUMG()
end

function UMG_LiqueFactionLoader_C:OnShow(LobbyMain)
  self.LobbyMain = LobbyMain
  self.LockedPlayer = nil
  self.CD = _G.DataConfigManager:GetGlobalConfigNumByKey("being_liquefied_cool_down", 10000)
  local panelInst = self.AimUmgLoader:GetPanel()
  if panelInst and panelInst.OnShow then
    panelInst:OnShow(LobbyMain)
  end
end

function UMG_LiqueFactionLoader_C:OnCancel(bFromInit)
  local panelInst = self.AimUmgLoader:GetPanel()
  if panelInst and panelInst.OnCancel then
    panelInst:OnCancel(bFromInit)
  end
end

function UMG_LiqueFactionLoader_C:ClearActorCache()
  self.LockedPlayer = nil
  self.LastEnable = nil
  self.inOrOut = false
  local panelInst = self.AimUmgLoader:GetPanel()
  if panelInst and panelInst.ClearActorCache then
    panelInst:ClearActorCache()
  end
end

function UMG_LiqueFactionLoader_C:BindAimUMG()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.player then
    self.wandData = self.player:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_LIQUEFY)
    self:LoadAimPanel(self.wandData.MagicTransformUMGClassAim)
  else
    Log.Error("UI\229\136\157\229\167\139\229\140\150\230\151\182\230\151\160player")
  end
end

function UMG_LiqueFactionLoader_C:LoadAimPanel(classPath)
  if not classPath then
    return
  end
  local packagePath = tostring(classPath)
  local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(packagePath)
  if self.widgetClassPath == packagePath then
    Log.Debug("UMG_LiqueFactionLoader_C:LoadAimPanel classPath is same skip load", packagePath)
    return
  end
  Log.Debug("UMG_LiqueFactionLoader_C:LoadAimPanel new classPath", packagePath)
  self.widgetClassPath = packagePath
  self.AimUmgLoader:UnLoadPanel(true)
  self.AimUmgLoader:SetWidgetClass(softClassPath)
  self.AimUmgLoader:LoadPanel(nil)
end

function UMG_LiqueFactionLoader_C:SetVisibility(InVisibility)
  if InVisibility == UE4.ESlateVisibility.Collapsed or InVisibility == UE4.ESlateVisibility.Hidden then
    self.isActive = false
  else
    self.isActive = true
  end
  local panelInst = self.AimUmgLoader:GetPanel()
  if panelInst and panelInst.SetVisibility then
    panelInst:SetVisibility(InVisibility)
  end
  self.Overridden.SetVisibility(self, InVisibility)
end

function UMG_LiqueFactionLoader_C:OnTick(InDeltaTime)
  if not self.isActive then
    return
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return
  end
  local buff = localPlayer.buffComponent:GetBuff("MagicTransformBuff")
  if buff then
    self.LockedPlayer = buff.LockedPlayer
  else
    self.LockedPlayer = nil
  end
  if self.LockedPlayer and self.LockedPlayer.viewObj then
    if not self.inOrOut then
      self.inOrOut = true
      local panelInst = self.AimUmgLoader:GetPanel()
      if panelInst and panelInst.OnAppear then
        panelInst:OnAppear()
      end
    end
    local statusInfo = self.LockedPlayer.LogicStatusComponent.StatusInfo
    local Enable = true
    if _G.ZoneServer:GetServerTime() - (self.LockedPlayer.serverData.avatar_status.end_transform_time or 0) < self.CD and not _G.DataModelMgr.PlayerDataModel:IsFriend(self.LockedPlayer.serverData.base.logic_id) then
      Enable = false
      buff:SetDisableReason("Error_Code_50739")
    end
    if Enable then
      for _, item in pairs(statusInfo) do
        local Condition = LogicStatusToPlayerCondition[item.status]
        if Condition then
          local cfg = _G.DataConfigManager:GetFunctionBanConf(Condition, true)
          if cfg then
            local function_ban_list = cfg.function_ban_list
            if function_ban_list and function_ban_list[59] and function_ban_list[59].function_ban_switch then
              Enable = false
              buff:SetDisableReason("Error_Code_50740")
            end
          end
        end
      end
    end
    if Enable and self.LockedPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
      Enable = false
      buff:SetDisableReason("Error_Code_50738")
    end
    if Enable then
      local canApplyRide, _, _ = self.LockedPlayer.statusComponent:PreApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      local canApplyTrans, _, _ = self.LockedPlayer.statusComponent:PreApplyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
      if not canApplyRide or not canApplyTrans then
        Enable = false
        buff:SetDisableReason("Error_Code_50740")
      end
    end
    if self.LastEnable ~= Enable then
      self.LastEnable = Enable
      buff.LastEnable = Enable
      local panelInst = self.AimUmgLoader:GetPanel()
      if Enable then
        if panelInst and panelInst.OnEnable then
          panelInst:OnEnable()
        end
      elseif panelInst and panelInst.OnDisable then
        panelInst:OnDisable()
      end
    end
    local Ctrl = localPlayer:GetUEController()
    local ScreenPos = UE4.FVector2D()
    local ViewportPos = UE4.FVector2D()
    local result = UE.UGameplayStatics.ProjectWorldToScreen(Ctrl, self.LockedPlayer.viewObj:K2_GetActorLocation() + UpVector, ScreenPos, false)
    UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), ScreenPos, ViewportPos)
    if UE4Helper.IsPCMode() then
      local PCScale = UE4.FVector2D(0.88, 0.88)
      self:SetRenderScale(PCScale)
    end
    if self.LobbyMain then
      self.LobbyMain.UMG_LiqueFaction.Slot:SetPosition(ViewportPos)
    end
  else
    self.LastEnable = nil
    if self.inOrOut then
      self.inOrOut = false
      self:OnCancel()
    end
  end
end

return UMG_LiqueFactionLoader_C
