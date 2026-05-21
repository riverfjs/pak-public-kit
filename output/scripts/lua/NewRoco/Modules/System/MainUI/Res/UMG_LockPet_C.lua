local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local UMG_LockPet_C = _G.NRCPanelBase:Extend("UMG_LockPet_C")

function UMG_LockPet_C:OnConstruct()
  self.lastActor = nil
  self.lastPetActor = nil
  self.wndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
  self.World = _G.UE4Helper.GetCurrentWorld()
  self.isLockingState = false
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local lineTraceConf = _G.DataConfigManager:GetGlobalConfigByKeyType("throw_linetrace_distance", confID)
  self.LineTraceDist = lineTraceConf.num
  self.curTickTime = 0.0
  self.landPoint = UE4.FVector(0, 0, 0)
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  _G.NRCEventCenter:RegisterEvent("UMG_LockPet_C", self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
  _G.NRCEventCenter:RegisterEvent("UMG_LockPet_C", self, SystemSettingModuleEvent.ChangeResolution, self.OnChangeResolution)
  self.IsChangeResolution = false
  self.ObjectTypes = {
    UE.EObjectTypeQuery.WorldDynamic,
    UE.EObjectTypeQuery.Pawn,
    UE.EObjectTypeQuery.WorldStatic
  }
  self.IsUnInteractionIn = false
end

UMG_LockPet_C.LockingType = {
  NAD_NONE = 1,
  NAD_NORMAL = 2,
  NAD_WILD_PET = 3,
  NAD_REWARD = 4,
  NAD_SPEOBJ = 5
}

function UMG_LockPet_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.RebindPlayer)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.ChangeResolution, self.OnChangeResolution)
  self:CancelDelay()
end

function UMG_LockPet_C:OnActive()
end

function UMG_LockPet_C:OnDeactive()
end

function UMG_LockPet_C:RebindPlayer()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function UMG_LockPet_C:OnShow(isAbility)
  self:ClearActorCache()
  self:StopAllAnim()
  if self:IsAnimationPlaying(self.close) then
    Log.Error(self:IsAnimationPlaying(self.close), "UMG_LockPet_C:OnShow")
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.open)
  self.LockPetPart1:PlayOpenAnim()
  self.LockPetPart2:PlayOpenAnim()
  self.LockPetPart3:PlayOpenAnim()
  self.isAbility = isAbility
  self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  self.LockingType = nil
end

function UMG_LockPet_C:UpdateUI(isCollision)
  if isCollision then
    self.LockPetPart2.lu:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC65FFF"))
    self.LockPetPart2.ru:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC65FFF"))
    self.LockPetPart2.rd:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC65FFF"))
    self.LockPetPart2.ld:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#FFC65FFF"))
  else
    self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
    self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
    self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
    self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  end
end

function UMG_LockPet_C:OnCancel(cancelType)
  Log.Debug("UMG_LockPet_C:OnCancel", self.isLockingState)
  self:StopAllAnim()
  if self.isLockingState == true then
    self:PlayAnimation(self.close)
    self.LockPetPart1:PlayLockCancelAnim()
    self.LockPetPart2:PlayLockCancelAnim()
    self.LockPetPart3:PlayLockCancelAnim()
  else
    self:PlayAnimation(self.close)
    self.LockPetPart1:PlayCloseAnim()
    self.LockPetPart2:PlayCloseAnim()
    self.LockPetPart3:PlayCloseAnim()
  end
end

function UMG_LockPet_C:OnEnterLockingState(bool, isUnInteraction)
  if self:IsAnimationPlaying(self.close) then
    return
  end
  self:StopAllAnim()
  if not self:IsAnimationPlaying(self.open) then
    if bool then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1121, "UMG_LockPet_C:OnEnterLockingState")
      if isUnInteraction then
        self.IsUnInteractionIn = true
        self.LockPetPart1:PlayLockCancelAnim()
        self.LockPetPart2:PlayUnInteractionIn()
        self.LockPetPart3:PlayOpenAnim()
      else
        self.LockPetPart1:PlayLockAnim()
        self.LockPetPart3:PlayLockAnim()
        if isUnInteraction then
          self.IsUnInteractionIn = false
          self.LockPetPart2:PlayUnInteractionOut(true)
        else
          self.LockPetPart2:PlayLockAnim()
        end
      end
    else
      self.LockPetPart1:PlayLockCancelAnim()
      self.LockPetPart3:PlayOpenAnim()
      if self.IsUnInteractionIn then
        self.IsUnInteractionIn = false
        self.LockPetPart2:PlayUnInteractionOut(false)
      else
        self.LockPetPart2:PlayLockCancelAnim()
      end
    end
  end
end

function UMG_LockPet_C:GetCurrentPetData()
  local CurrentPetID = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  return _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(CurrentPetID)
end

function UMG_LockPet_C:Tick(MyGeometry, InDeltaTime)
  if not self.player then
    return
  end
  local playerCtrl = self.player:GetUEController()
  playerCtrl = UE4.UGameplayStatics.GetPlayerControllerFromID(self.player.viewObj, 0)
  if not playerCtrl then
    return
  end
  if self.IsChangeResolution then
    self.wndSize = UE4.UWidgetLayoutLibrary.GetViewportSize(_G.UE4Helper.GetCurrentWorld())
    self.IsChangeResolution = false
  end
  local WorldLocation, CamDir = playerCtrl:Abs_DeprojectScreenPositionToWorld(self.wndSize.X / 2, self.wndSize.Y / 2)
  local endPos = FVectorZero
  if self.LineTraceDist > 0 then
    endPos = WorldLocation + CamDir * self.LineTraceDist
  end
  local TraceChannelLand = UE4.UNRCStatics.ConvertToTraceChannel(_G.UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local OutHitLand, Result = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), WorldLocation, endPos, TraceChannelLand, false, nil, UE4.EDrawDebugTrace.None, nil, true)
  if OutHitLand and OutHitLand.ImpactPoint then
    self.landPoint.X = OutHitLand.ImpactPoint.X or 0
    self.landPoint.Y = OutHitLand.ImpactPoint.Y or 0
    self.landPoint.Z = OutHitLand.ImpactPoint.Z or 0
    _G.NRCModuleManager:GetModule("MainUIModule"):SetLockPetLandPos(self.landPoint)
  end
  if not self.isAbility then
    local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(self.player.viewObj, WorldLocation, endPos, self.ObjectTypes, false, nil, 0, nil, true)
    self.curTickTime = self.curTickTime + InDeltaTime
    if self.curTickTime > 0.2 then
      self.curTickTime = 0.0
      local NPCActor
      for i = 1, hitResults:Length() do
        local hitResult = hitResults:Get(i)
        local hitActor = hitResult.Actor
        local Character = hitActor and hitActor.sceneCharacter
        if Character and Character.InteractionComponent then
          NPCActor = hitActor
          break
        end
      end
      local Character = NPCActor and NPCActor.sceneCharacter
      if self.lastActor and self.lastActor.ShowThrowInterInfo then
        self.lastActor:ShowThrowInterInfo(false)
      end
      if nil ~= NPCActor and NPCActor.ShowThrowInterInfo and Character then
        local HiddenComponent = NPCActor.sceneCharacter.HiddenComponent
        if HiddenComponent and HiddenComponent:IsHidden() then
        else
          NPCActor:ShowThrowInterInfo(true, true)
        end
      end
      local lockType
      if Character then
        self.isLockingState = true
        local aimType = Character:GetAimDisplay()
        local isHasPet = false
        local isHasSpeObj = false
        local isHasReward = false
        if aimType then
          for _, type in pairs(aimType) do
            if type == _G.Enum.NPC_AIM_DISPLAY.NAD_WILD_PET then
              isHasPet = true
            elseif type == _G.Enum.NPC_AIM_DISPLAY.NAD_SPEOBJ then
              isHasSpeObj = true
            elseif type == _G.Enum.NPC_AIM_DISPLAY.NAD_REWARD then
              isHasReward = true
            end
          end
          if isHasPet then
            local isFighting = Character:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING)
            if isFighting then
              lockType = UMG_LockPet_C.LockingType.NAD_NORMAL
            else
              lockType = UMG_LockPet_C.LockingType.NAD_WILD_PET
            end
          elseif isHasSpeObj then
            lockType = UMG_LockPet_C.LockingType.NAD_SPEOBJ
          elseif isHasReward then
            lockType = UMG_LockPet_C.LockingType.NAD_REWARD
          else
            lockType = UMG_LockPet_C.LockingType.NAD_NORMAL
          end
        else
          lockType = UMG_LockPet_C.LockingType.NAD_NONE
        end
      elseif self:CheckLockingTypeIsNone() then
        lockType = UMG_LockPet_C.LockingType.NAD_NONE
      end
      if lockType ~= self.LockingType then
        self.LockingType = lockType
        self.LockPetPart3:SetShowIcon(self.LockingType)
        if lockType == UMG_LockPet_C.LockingType.NAD_WILD_PET then
          self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          self.isLockingState = true
          self:EnterLockingState()
          self.lastPetActor = NPCActor
        elseif lockType == UMG_LockPet_C.LockingType.NAD_REWARD then
          if self.LockPetPart2.lu and self.LockPetPart2.ru and self.LockPetPart2.rd and self.LockPetPart2.ld then
            self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          end
          self.isLockingState = true
          self:EnterLockingState()
          self.lastPetActor = NPCActor
        elseif lockType == UMG_LockPet_C.LockingType.NAD_SPEOBJ then
          if self.LockPetPart2.lu and self.LockPetPart2.ru and self.LockPetPart2.rd and self.LockPetPart2.ld then
            self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          end
          self.isLockingState = true
          self:EnterLockingState()
          self.lastPetActor = NPCActor
        elseif lockType == UMG_LockPet_C.LockingType.NAD_NONE then
          self.isLockingState = false
          self:OnEnterLockingState(false)
        elseif lockType == UMG_LockPet_C.LockingType.NAD_NORMAL then
          if self.LockPetPart2.lu and self.LockPetPart2.ru and self.LockPetPart2.rd and self.LockPetPart2.ld then
            self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          end
          self.isLockingState = true
          self:EnterLockingState(true)
          self.lastPetActor = NPCActor
        end
      else
        local character = NPCActor and NPCActor.sceneCharacter
        if self.lastActor and self.lastActor.ShowThrowInterInfo then
          self.lastActor:ShowThrowInterInfo(false)
        end
        if character and character.GetThrowInteractType then
          local throwType = character:GetThrowInteractType()
          if throwType == _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
            self.isLockingState = true
            self.LockPetPart2.lu:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ru:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.rd:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
            self.LockPetPart2.ld:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
          end
        end
      end
      self.lastActor = NPCActor
    end
  end
end

function UMG_LockPet_C:EnterLockingState(isUnInteraction)
  if self:IsAnimationPlaying(self.open) then
    self:DelaySeconds(0.17, function()
      self:OnEnterLockingState(true, isUnInteraction)
    end)
  else
    self:OnEnterLockingState(true, isUnInteraction)
  end
end

function UMG_LockPet_C:OnAnimationFinished(anim)
  if anim == self.open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    self:PlayAnimation(self.loop, 0.0, 0)
  elseif anim == self.close then
    self:StopAllAnim()
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:ClearActorCache()
  end
end

function UMG_LockPet_C:ClearActorCache()
  if self.lastPetActor and self.lastPetActor.ShowThrowInterInfo then
    self.lastPetActor:ShowThrowInterInfo(false)
  end
  self.lastActor = nil
  self.isLockingState = false
  self.lastPetActor = nil
end

function UMG_LockPet_C:StopAllAnim()
  if self:IsAnyAnimationPlaying() then
    self:StopAllAnimations()
  end
  self.LockPetPart1:StopAllAnim()
  self.LockPetPart2:StopAllAnim()
  self.LockPetPart3:StopAllAnim()
end

function UMG_LockPet_C:CheckLockingTypeIsNone()
  if self.lastActor and self.lastActor.sceneCharacter and self.lastActor.sceneCharacter.config and self.lastActor.sceneCharacter.config.throwing_interact_type then
    return true
  end
  return false
end

function UMG_LockPet_C:OnChangeResolution()
  self.IsChangeResolution = true
end

return UMG_LockPet_C
