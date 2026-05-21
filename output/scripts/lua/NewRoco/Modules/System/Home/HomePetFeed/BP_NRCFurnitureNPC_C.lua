require("UnLua")
local Base = require("NewRoco.Modules.System.Home.HomeNPC.BP_HomeInteractBase_C")
local HomeEnum = require("NewRoco.Modules.System.Home.HomeEnum")
local HomeModuleEvent = require("NewRoco/Modules/System/Home/HomeModuleEvent")
local HomeModuleCmd = require("NewRoco.Modules.System.Home.HomeModuleCmd")
local HomeUtils = require("NewRoco/Modules/System/Home/IndoorSandbox/HomeUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local InitialIconHeight
local DefaultIconHeight = 70
local IconMoreHeightIfWithEgg = 40
local BP_NRCFurnitureNPC_C = Base:Extend("BP_NRCFurnitureNPC_C")

function BP_NRCFurnitureNPC_C:Ctor()
  self.bShouldShowEmptyWidget = false
  self.bShouldShowWidget = false
  self.bShouldShowEmptyWidget = false
  self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.Free
  self:OnAddEventListener()
end

function BP_NRCFurnitureNPC_C:OnPostLoad(data)
  Base.OnPostLoad(self, data)
  if self.HighlightCollision then
    local highlightRadius = _G.DataConfigManager:GetHomeGlobalConfig("home_owner_visible_distance").num or 200
    self.HighlightCollision:SetCapsuleRadius(highlightRadius)
  end
  if self.IconShowDis then
    local showIconRadius = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_bed_icon_distance").num or 200
    self.IconShowDis:SetCapsuleRadius(showIconRadius)
  end
  if self.EmptyStatusShowDis then
    local emptyStatusRadius = _G.DataConfigManager:GetHomeGlobalConfig("home_pet_bed_none_distance").num or 1000
    self.EmptyStatusShowDis:SetCapsuleRadius(emptyStatusRadius)
  end
  self:LoadWidget()
  self:OnHomeLevelStatusChanged(HomeEnum.EnmEditPropsStatus.SPAWN_SUCCESS, data)
end

function BP_NRCFurnitureNPC_C:LoadWidget()
  if self.bIsFurnitureInHome and not UE4.UObject.IsValid(self.rocoWidget:GetWidget()) then
    local hud = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetHudFromPool, "UMG_Home_Pet")
    if not hud then
      local hudCls = _G.NRCBigWorldPreloader:Get("PET_HUD_HOME")
      hud = UE4.UWidgetBlueprintLibrary.Create(self, hudCls)
    end
    if UE.UObject.IsValid(hud) then
      self.rocoWidget:SetWidget(hud)
      hud:SetParentHUD(self.rocoWidget)
      hud:SetAttachActor(self)
    end
    if not self:NeedShowWidget() then
      self.rocoWidget:SetVisibility(false, true)
    end
  end
  local rocoWidgetRelativeTransform = self.rocoWidget:GetRelativeTransform()
  if rocoWidgetRelativeTransform and rocoWidgetRelativeTransform.Translation and rocoWidgetRelativeTransform.Translation.Z and not InitialIconHeight then
    InitialIconHeight = rocoWidgetRelativeTransform.Translation.Z
  end
end

function BP_NRCFurnitureNPC_C:OnAddEventListener()
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.HomePetStatusChanged, self.OnHomePetChanged)
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.SwitchDetailPanelData, self.OnHomePetPreview)
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.ClosePetLivePanel, self.OnCloseHomePetPreview)
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnEnterHomeEditMode, self.OnEnterHomeEditMode)
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnExitHomeEditMode, self.OnExitHomeEditMode)
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_PROMPTION, self, self.OnFunctionBan)
  _G.NRCEventCenter:RegisterEvent("BP_NRCFurnitureNPC_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function BP_NRCFurnitureNPC_C:RemoveEventListener()
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.HomePetStatusChanged)
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.SwitchDetailPanelData)
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.ClosePetLivePanel)
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeEditMode)
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.OnExitHomeEditMode)
  _G.NRCModuleManager:GetModule("HomeModule"):UnRegisterEvent(self, HomeModuleEvent.OnActiveFurnitureChange)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_PROMPTION, self, self.OnFunctionBan)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function BP_NRCFurnitureNPC_C:OnReconnectFinish()
  self:QueryCurrentStatus()
  self:MakeWidgetFlashInPreviewPanel(nil)
end

function BP_NRCFurnitureNPC_C:OnEnterHomeEditMode()
  if self.currentStatus == HomeEnum.FURNITURE_NPC_STATE.Free then
    self:RefreshWidgetVisibility(false, true)
  elseif self.currentStatus == HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet then
    self:RefreshWidgetVisibility(true, true)
  end
end

function BP_NRCFurnitureNPC_C:OnExitHomeEditMode()
  self:QueryCurrentStatus()
end

function BP_NRCFurnitureNPC_C:RefreshWidgetVisibility(enableVisible, bForce)
  if bForce and self.rocoWidget then
    self.rocoWidget:SetVisibility(enableVisible)
  end
  if enableVisible and (self.bShouldShowWidget or self.bShouldShowEmptyWidget and self:NeedShowWidget()) then
    if self.rocoWidget then
      self.rocoWidget:SetVisibility(true, true)
    end
    return
  end
  if self.rocoWidget then
    self.rocoWidget:SetVisibility(false, true)
  end
end

function BP_NRCFurnitureNPC_C:UpdateWidgetComponent(bShow, petData)
  local bVisible = self:NeedShowWidget()
  self:RefreshWidgetVisibility(bVisible)
  if not petData and self.flashTimer then
    self.flashTimer:Stop()
    self.flashTimer = nil
  end
  if bShow and not petData then
    local rocoWidgetC = self.rocoWidget:GetWidget()
    if rocoWidgetC and rocoWidgetC.UpdateIcon then
      rocoWidgetC:UpdateIcon(nil)
      self.rocoWidget:SetVisibility(true, true)
      self.rocoWidget:RequestRedraw()
    end
    return
  end
  if self.rocoWidget and UE4.UObject.IsValid(self.rocoWidget) then
    self.rocoWidget:SetVisibility(false, true)
    if not bShow then
      return
    end
    local rocoWidgetC = self.rocoWidget:GetWidget()
    if rocoWidgetC and rocoWidgetC.UpdateIcon then
      rocoWidgetC:UpdateIcon(petData)
    end
    self:ModifyIconHeightIfWithEgg()
  end
end

function BP_NRCFurnitureNPC_C:ReceiveBeginPlay()
  Base.ReceiveBeginPlay(self)
  self:QueryCurrentStatus()
end

function BP_NRCFurnitureNPC_C:ReceiveEndPlay()
  Log.Debug("BP_NRCFurnitureNPC_C ReceiveEndPlay")
  self:OnHomeLevelStatusChanged(HomeEnum.EnmEditPropsStatus.UNLOAD_PACK_UP)
  if self.flashTimer then
    self.flashTimer:Stop()
    self.flashTimer = nil
  end
  Base.ReceiveEndPlay(self)
end

function BP_NRCFurnitureNPC_C:GetComponent(ClassTable)
  local memberName = ClassTable.className
  local instance = rawget(self, memberName)
  if instance then
    return instance
  end
  if self.components then
    for _, v in ipairs(self.components:Items()) do
      if v:InstanceOf(ClassTable) then
        return v
      end
    end
  end
  return nil
end

function BP_NRCFurnitureNPC_C:OnHighlightActive(OtherActor, bShow)
end

function BP_NRCFurnitureNPC_C:OnIconPrepared()
  if not self.rocoWidget then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj then
    local curPos = self:Abs_K2_GetActorLocation()
    local playerPos = player.viewObj:Abs_K2_GetActorLocation()
    local dis = UE4.FVector.DistSquared2D(curPos, playerPos)
    local capsuleRadius = self.IconShowDis and self.IconShowDis:GetUnscaledCapsuleRadius() or 200
    if dis <= capsuleRadius * capsuleRadius then
      self.bShouldShowWidget = true
      self.rocoWidget:SetVisibility(true)
    else
      self.bShouldShowWidget = false
    end
  end
end

function BP_NRCFurnitureNPC_C:OnIconShowActive(OtherActor, bShow)
  if bShow then
    self.bShouldShowWidget = true
    if self:NeedShowWidget() then
      self:QueryCurrentStatus()
      self:MakeWidgetFlashByPetType(true)
    end
  else
    self.bShouldShowWidget = false
    if not self:NeedShowWidget() then
      self.rocoWidget:SetVisibility(false)
      self:MakeWidgetFlashByPetType(false)
    end
  end
end

function BP_NRCFurnitureNPC_C:OnEmptyStatusShowActive(OtherActor, bShow)
  if bShow then
    self.bShouldShowEmptyWidget = true
    if self:NeedShowWidget() then
      self:QueryCurrentStatus()
    end
  else
    self.bShouldShowEmptyWidget = false
    if not self:NeedShowWidget() then
      self.rocoWidget:SetVisibility(false)
    end
  end
end

function BP_NRCFurnitureNPC_C:OnHomeLevelStatusChanged(Status, PropsData)
  if Status == HomeEnum.EnmEditPropsStatus.SPAWN_SUCCESS then
    if PropsData and PropsData.Id then
      self.furnitureId = PropsData.Id
    end
    self:QueryCurrentStatus()
  elseif Status == HomeEnum.EnmEditPropsStatus.UNLOAD_PACK_UP then
    self:RemoveEventListener()
    _G.NRCModuleManager:DoCmd(HomeModuleCmd.InteractiveFurnitureLeave, self.furnitureId, self)
  end
end

function BP_NRCFurnitureNPC_C:OnHomePetChanged(petInfo, bEnter)
  Log.Debug("OnHomePetChanged invoked with homePetInfo.furniture_guid" .. petInfo.home_pet.home_pet_info.furniture_guid .. " self.furnitureId " .. self.furnitureId)
  if petInfo and petInfo.home_pet.home_pet_info.furniture_guid == self.furnitureId then
    local petData = HomeUtils.GetHomePetAdditionalInfo(petInfo.home_pet.home_pet_info.pet_gid)
    if bEnter then
      self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet
      if petData then
        self:UpdatePairPetInfo(true, petData)
      end
      _G.NRCModuleManager:DoCmd(HomeModuleCmd.UpdatePairNestAndPet, self.furnitureId, petInfo)
    else
      self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.Free
      self:UpdatePairPetInfo(self:NeedShowWidget(), nil)
      _G.NRCModuleManager:DoCmd(HomeModuleCmd.UpdatePairNestAndPet, self.furnitureId, nil)
    end
    self:UpdateEventListerOnPet()
  end
end

function BP_NRCFurnitureNPC_C:OnHomePetPreview(petData, furnitureId)
  if not furnitureId or furnitureId ~= self.furnitureId then
    return
  end
  local preViewPetData = {}
  if petData then
    preViewPetData = {
      name = petData.name or "",
      base_conf_id = petData.base_conf_id or 0,
      mutation_type = petData.mutation_type or 0,
      glass_info = petData.glass_info,
      gender = petData.gender or 1,
      actor_id = petData.actor_id or 0
    }
  end
  if preViewPetData and table.len(preViewPetData) > 0 then
    self:UpdatePairPetInfo(true, preViewPetData)
    self:MakeWidgetFlashInPreviewPanel(preViewPetData)
  else
    Log.Error("invalid petData")
  end
end

function BP_NRCFurnitureNPC_C:OnCloseHomePetPreview()
  self:MakeWidgetFlashInPreviewPanel(nil)
  self:QueryCurrentStatus()
end

function BP_NRCFurnitureNPC_C:OnFunctionBan()
  local isBan = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_HOME_PET_PROMPTION)
  self:RefreshWidgetVisibility(isBan)
  local sceneCharacter = self.sceneCharacter
  if sceneCharacter then
    sceneCharacter.InteractionComponent:SetMarkShouldShow(isBan)
  end
end

function BP_NRCFurnitureNPC_C:QueryCurrentStatus()
  Log.Debug("current nest status query with self.furnitureId: ", self.furnitureId)
  if not self.furnitureId then
    return
  end
  local pairPetData = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, self.furnitureId)
  if not pairPetData then
    self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.Free
  elseif pairPetData.home_pet and pairPetData.home_pet.home_pet_info.furniture_guid == self.furnitureId then
    self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet
  else
    self.currentStatus = HomeEnum.FURNITURE_NPC_STATE.Free
  end
  Log.Debug("QueryCurrentStatus with currentStatus: ", self.currentStatus)
  if self.currentStatus == HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet then
    if not pairPetData or not pairPetData.home_pet then
      return
    end
    local petData = HomeUtils.GetHomePetAdditionalInfo(pairPetData.home_pet.home_pet_info.pet_gid)
    if petData and table.len(petData) > 0 then
      self:UpdatePairPetInfo(true, petData)
    end
  else
    self:UpdatePairPetInfo(self:NeedShowWidget(), nil)
  end
  self:UpdateEventListerOnPet()
end

function BP_NRCFurnitureNPC_C:UpdateEventListerOnPet()
  local pairPetData = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, self.furnitureId)
  if not pairPetData then
    self:RemoveEventListenerOnOldPet(self.pairPet)
    return
  end
  local pairPet
  if pairPetData then
    pairPet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pairPetData.base.actor_id)
  end
  if not pairPet then
    self:RemoveEventListenerOnOldPet(self.pairPet)
    return
  end
  if self.pairPet == pairPet then
    return
  end
  self:RemoveEventListenerOnOldPet(self.pairPet)
  self.pairPet = pairPet
  self:AddEventListenerOnNewPet(pairPet)
end

function BP_NRCFurnitureNPC_C:RemoveEventListenerOnOldPet(petNpc)
  if not petNpc then
    return
  end
  petNpc:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnPetStatusChanged)
end

function BP_NRCFurnitureNPC_C:AddEventListenerOnNewPet(pairPet)
  if pairPet then
    pairPet:AddEventListener(self)
  end
end

function BP_NRCFurnitureNPC_C:UpdatePairPetInfo(visibility, petData)
  self:UpdateWidgetComponent(visibility, petData)
end

function BP_NRCFurnitureNPC_C:GetCurStatus()
  return self.currentStatus
end

function BP_NRCFurnitureNPC_C:SetNewStatus(newStatus)
  self.currentStatus = newStatus
end

function BP_NRCFurnitureNPC_C:MakeWidgetFlashByPetType(bFlash)
  if not bFlash then
    if self.flashTimer then
      _G.TimerManager:RemoveTimer(self.flashTimer)
      self.flashTimer = nil
      self.rocoWidget.bRedrawRequested = false
    end
    return
  end
  if self.flashTimer then
    return
  end
  local pairPetData = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetPairNestAndPet, self.furnitureId)
  local pairPet
  if pairPetData then
    pairPet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pairPetData.base.actor_id)
    if pairPet and pairPet.serverData and 0 ~= pairPet.serverData.mutation_type then
      self.flashTimer = _G.TimerManager:CreateTimer(self, "BP_NRCFurnitureNPC" .. pairPetData.base.actor_id, math.maxinteger, function()
        if self.rocoWidget and UE4.UObject.IsValid(self.rocoWidget) and self.rocoWidget:IsWidgetVisible() then
          self.rocoWidget:RequestRedraw()
        end
      end, nil, 0.1)
    end
  end
end

function BP_NRCFurnitureNPC_C:MakeWidgetFlashInPreviewPanel(previewData)
  if not previewData then
    if self.previewTimer then
      self.previewTimer:Stop()
      self.previewTimer = nil
    end
    return
  end
  
  local function MakeWidgetFlash()
    if self.rocoWidget and UE4.UObject.IsValid(self.rocoWidget) and self.rocoWidget:IsWidgetVisible() then
      self.rocoWidget:RequestRedraw()
    end
  end
  
  if 0 ~= previewData.mutation_type then
    if not self.previewTimer then
      self.previewTimer = _G.TimerManager:CreateTimer(self, "BP_NRCFurnitureNPC" .. previewData.actor_id, math.maxinteger, MakeWidgetFlash, nil, 0.1)
      return
    end
    MakeWidgetFlash()
  elseif self.previewTimer then
    self.previewTimer:Stop()
    self.previewTimer = nil
  end
end

function BP_NRCFurnitureNPC_C:NeedShowWidget()
  local curStatus = self:GetCurStatus()
  if _G.FunctionBanManager:GetConditionCounter(Enum.PlayerConditionType.PCT_EDITING_HOME) then
    if curStatus == HomeEnum.FURNITURE_NPC_STATE.Free then
      return false
    elseif curStatus == HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet then
      return true
    end
  end
  local emptyIconShowRadius, _ = self.EmptyStatusShowDis:GetScaledCapsuleSize()
  local iconShowRadius, _ = self.IconShowDis:GetScaledCapsuleSize()
  if emptyIconShowRadius < iconShowRadius then
    if self.bShouldShowEmptyWidget and curStatus == HomeEnum.FURNITURE_NPC_STATE.Free then
      return true
    elseif self.bShouldShowWidget and curStatus == HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet then
      return true
    else
      return false
    end
  elseif self.bShouldShowWidget and curStatus == HomeEnum.FURNITURE_NPC_STATE.OccupiedWithPet then
    return true
  elseif self.bShouldShowEmptyWidget and curStatus == HomeEnum.FURNITURE_NPC_STATE.Free then
    return true
  else
    return false
  end
end

function BP_NRCFurnitureNPC_C:Destroy()
end

function BP_NRCFurnitureNPC_C:ModifyIconHeightIfWithEgg()
  local pairPetData = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, self.furnitureId)
  local pairPet
  if pairPetData then
    pairPet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, pairPetData.base.actor_id)
  end
  if not pairPet then
    return
  end
  local iconHeight = InitialIconHeight or DefaultIconHeight
  if pairPet:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_HOLD_EGG) then
    iconHeight = iconHeight + IconMoreHeightIfWithEgg
  end
  if self.rocoWidget and UE4.UObject.IsValid(self.rocoWidget) then
    self.rocoWidget:K2_SetRelativeLocation(UE4.FVector(0, 0, iconHeight), false, nil, false)
  end
end

function BP_NRCFurnitureNPC_C:OnPetStatusChanged()
  self:ModifyIconHeightIfWithEgg()
end

return BP_NRCFurnitureNPC_C
