local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local HomeEnum = require("NewRoco.Modules.System.Home.HomeEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local HomePetFeedStatusComponent = Base:Extend("HomePetFeedStatusComponent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")

function HomePetFeedStatusComponent:Attach(owner)
  if not (owner and owner.serverData) or not owner.serverData.home_pet then
    Log.Error("HomePetFeedStatusComponent attach failed")
    return
  end
  Base.Attach(self, owner)
  self:UpdateData(owner.serverData)
  self.actorId = self.owner.serverData.base and self.owner.serverData.base.actor_id
  self.enableInteract = false
  _G.NRCModuleManager:GetModule("HomeModule"):RegisterEvent(self, HomeModuleEvent.OnInteractingItemChange, self.OnActiveInteractNpcChange)
  _G.NRCEventCenter:RegisterEvent("HomePetFeedStatusComponent.instance", self, NPCModuleEvent.OnCharacterHUDLoaded, self.OnWidgetLoad)
  _G.NRCEventCenter:RegisterEvent("HomePetFeedStatusComponent.instance", self, NPCModuleEvent.OnHomePetInfoChanged, self.OnPetInfoChanged)
  self:UpdateHomePetStatusIcon()
end

function HomePetFeedStatusComponent:CalOutput()
  if not self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) and not self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
    return
  end
  if self.homePetInfo and self.homePetInfo.awards_info then
    self.outputInfo = self.homePetInfo.awards_info.goods_infos
  end
end

function HomePetFeedStatusComponent:CalRemainCareTime()
  if not self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
    self.needCareTime = nil
    self.startTime = nil
    self.feedInfo = nil
    return
  end
  self.homePetInfo = self.owner.serverData.home_pet.home_pet_info
  if self.homePetInfo then
    self.feedInfo = self.homePetInfo.feed_info
    if self.feedInfo then
      self.startTime = self.feedInfo.begin_time / 1000
      local serverTime = _G.ZoneServer:GetServerTime()
      self.needCareTime = self.feedInfo.time_cost / 1000 - (serverTime - self.startTime)
      if self.needCareTime > 0 then
        return
      end
      self.needCareTime = 0
    end
  end
end

function HomePetFeedStatusComponent:OnWidgetLoad()
  self:UpdateHomePetStatusIcon()
  if self.owner.viewObj then
    local comp = self.owner.viewObj:GetComponentByClass(UE4.URocoWidgetComponent)
    if comp then
      comp.bReceiveHardwareInput = true
      comp:SetGenerateOverlapEvents(true)
      comp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
      comp:SetCollisionObjectType(UE.ECollisionChannel.ECC_GameTraceChannel10)
    end
  end
end

function HomePetFeedStatusComponent:OnLogicStatusUpdated()
  if self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_WAIT_PRODUCT) then
    self.outputInfo = nil
  elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
    self.outputInfo = nil
  elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) or self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
    self.startTime = nil
    self.needCareTime = nil
  else
    self.outputInfo = nil
  end
  self:CalRemainCareTime()
  self:CalOutput()
  self:UpdateHomePetStatusIcon()
end

function HomePetFeedStatusComponent:OnPetInfoChanged(homePetInfo)
  if not (homePetInfo and homePetInfo.home_pet_info) or homePetInfo.home_pet_info.pet_gid ~= self.owner.serverData.home_pet.home_pet_info.pet_gid then
    return
  end
  local newAwardInfo = homePetInfo.home_pet_info.awards_info
  if newAwardInfo and newAwardInfo.goods_infos then
    self.outputInfo = newAwardInfo.goods_infos
  end
  self:OnLogicStatusUpdated()
end

function HomePetFeedStatusComponent:UpdateData(actorInfo_npc)
  self.homePetInfo = actorInfo_npc.home_pet.home_pet_info
  self:CalRemainCareTime()
  self:CalOutput()
  self:UpdateHomePetStatusIcon()
end

function HomePetFeedStatusComponent:DeAttach()
  self.owner:RemoveEventListener(self, NPCModuleEvent.OnLogicStatusUpdated, self.OnLogicStatusUpdated)
end

function HomePetFeedStatusComponent:OnActiveInteractNpcChange(currentActorId)
  if currentActorId == self.actorId then
    if not self.enableInteract then
      self.enableInteract = true
    end
  else
    self.enableInteract = false
  end
end

function HomePetFeedStatusComponent:UpdateHomePetStatusIcon()
  if self.owner.PetHUDComponent then
    if self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_WAIT_PRODUCT) then
      self.owner.PetHUDComponent:ShowHomeStatus(true, false, self.needCareTime or 0, self.startTime)
    elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
      self.owner.PetHUDComponent:ShowHomeStatus(true, true, self.needCareTime or 0, self.startTime)
    elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) or self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
      if self.outputInfo then
        self.owner.PetHUDComponent:UpdateHomeOutput(false, self.outputInfo)
      end
    else
      self.owner.PetHUDComponent:ShowHomeStatus(false, false, 0)
    end
  end
end

function HomePetFeedStatusComponent:UpdateFeedInfo()
  if self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_WAIT_PRODUCT) then
    self.outputInfo = nil
  elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
    self.outputInfo = nil
  elseif self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) or self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
    self.outputInfo = self.owner.serverData.home_pet.home_pet_info.awards_info and self.owner.serverData.home_pet.home_pet_info.awards_info.goods_infos
  else
    self.outputInfo = nil
  end
  self.homePetInfo = self.owner.serverData.home_pet.home_pet_info
  self:CalRemainCareTime()
  self:CalOutput()
  local bagItemId = self.feedInfo and self.feedInfo.food_info.bag_item_id
  return self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT), self.needCareTime, self.startTime, self.outputInfo, bagItemId
end

function HomePetFeedStatusComponent:UpdateCompassPetIcon()
end

function HomePetFeedStatusComponent:IsInteractEnable()
  return self.enableInteract
end

return HomePetFeedStatusComponent
