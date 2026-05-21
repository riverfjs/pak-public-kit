local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local AudioCustomSettingComponent = Base:Extend("AudioCustomSettingComponent")

function AudioCustomSettingComponent:Attach(owner)
  Base.Attach(self, owner)
  self.special_pet_token = nil
  if self:GetOwnerView() then
    self:OnSetViewObj()
  end
end

function AudioCustomSettingComponent:OnSetViewObj()
  self:SetActorAudioTag()
  self:TryRegisterSpecialPet()
  self:InitNpcSettings()
end

function AudioCustomSettingComponent:Destroy()
  self:TryUnRegisterSpecialPet()
end

function AudioCustomSettingComponent:SetActorAudioTag()
  local owner = self:GetOwner()
  local ownerView = self:GetOwnerView()
  if not owner or not ownerView then
    Log.Error("Init with no owner or ownerView", owner, ownerView)
    return
  end
  if not owner.config or not owner.config.special_audio_tag then
    return
  end
  if next(owner.config.special_audio_tag) == nil then
    return
  end
  if not ownerView or not ownerView.SetActorAudioTag then
    return
  end
  local actor_tag = 0
  for i, flag in ipairs(owner.config.special_audio_tag) do
    actor_tag = actor_tag | 1 << flag
  end
  ownerView:SetActorAudioTag(actor_tag)
end

function AudioCustomSettingComponent:TryRegisterSpecialPet()
  local owner = self:GetOwner()
  if owner and owner.config.genre == _G.Enum.ClientNpcType.CNT_PETBOSS then
    self.special_pet_token = _G.NRCAudioManager:StartRegisterSpecialPet()
    local ownerView = self:GetOwnerView()
    _G.NRCAudioManager:RegisterSpecialPet(self.special_pet_token, ownerView)
  end
end

function AudioCustomSettingComponent:TryUnRegisterSpecialPet()
  if self.special_pet_token then
    _G.NRCAudioManager:EndRegisterSpecialPet(self.special_pet_token)
  end
end

function AudioCustomSettingComponent:InitNpcSettings()
  local owner = self:GetOwner()
  local ownerView = self:GetOwnerView()
  if not owner or not ownerView then
    Log.Error("Init with no owner or ownerView", owner, ownerView)
    return
  end
  local genre = owner.config and owner.config.genre
  if genre == _G.Enum.ClientNpcType.CNT_PETBOSS or genre == _G.Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
    _G.NRCAudioManager:SetEmitterRTPC("Npc_State", 1, ownerView)
    _G.NRCAudioManager:SetEmitterSwitch("Boss_Switch", "Boss", ownerView)
  elseif owner:IsHuman() then
    _G.NRCAudioManager:SetEmitterRTPC("Npc_State", 2, ownerView)
    _G.NRCAudioManager:SetEmitterSwitch("Boss_Switch", "NPC", ownerView)
  else
    _G.NRCAudioManager:SetEmitterRTPC("Npc_State", 0, ownerView)
    _G.NRCAudioManager:SetEmitterSwitch("Boss_Switch", "NPC", ownerView)
  end
  if ownerView and UE4.UObject.IsValid(ownerView) and ownerView:IsA(UE.ARocoCharacter) then
    _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_World", ownerView)
  end
  local nature = owner.serverData.npc_base.nature
  if nature then
    if ownerView.SetPetNature then
      ownerView:SetPetNature(nature)
    end
    local audioNatureConf = _G.DataConfigManager:GetAudioNatureConf(nature, true)
    if audioNatureConf and ownerView.SetPetVoiceCoolDown then
      if _G.NRCAudioManager:GetIsInHome() then
        ownerView:SetPetVoiceCoolDown(audioNatureConf.cool_down_min_home, audioNatureConf.cool_down_max_home)
      elseif owner:IsAThrownPet() and owner:IsControlledByPlayer() then
        ownerView:SetPetVoiceCoolDown(audioNatureConf.cool_down_min, audioNatureConf.cool_down_max)
      elseif owner:IsAThrownPet() then
        ownerView:SetPetVoiceCoolDown(audioNatureConf.cool_down_min_Others, audioNatureConf.cool_down_max_Others)
      else
        ownerView:SetPetVoiceCoolDown(audioNatureConf.cool_down_min_Wild, audioNatureConf.cool_down_max_Wild)
      end
    end
  end
  local npc_base = owner.serverData and owner.serverData.npc_base
  local voice = npc_base and npc_base.voice
  if voice then
    _G.NRCAudioManager:SetEmitterRTPC("Pet_Vo_Pitch", voice, ownerView)
  end
  local pet_info = owner.serverData and owner.serverData.pet_info
  local pet_base_conf_id = pet_info and pet_info.pet_base_conf_id
  if pet_base_conf_id and 0 ~= pet_base_conf_id then
    local Character = ownerView
    Character:SetPetBaseId(pet_base_conf_id)
  end
  if owner:IsAThrownPet() and owner:IsControlledByPlayer() then
    local Character = ownerView
    if Character and Character.SetIsLocalPlayerPet then
      Character:SetIsLocalPlayerPet(true)
    else
      Log.Error("AudioCustomSettingComponent:InitNpcSettings Character is nil", owner:DebugNPCNameAndID(), Character)
    end
  end
end

return AudioCustomSettingComponent
