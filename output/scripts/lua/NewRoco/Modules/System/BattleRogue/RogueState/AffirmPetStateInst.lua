local Base = require("NewRoco.Modules.System.BattleRogue.RogueState.StateInstBase")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local AffirmPetStateInst = Base:Extend("AffirmPetStateInst")

function AffirmPetStateInst:Ctor(State, ...)
  Base.Ctor(self, State, ...)
  self.PetGid = nil
  self.PetRef = nil
end

function AffirmPetStateInst:OnDoEnter()
  self.PetGid = self.Context.TrialPetInfo.pet_gid
end

local LoadRes = {}

function AffirmPetStateInst:GetPreLoadResList()
  local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.PetGid)
  if not PetData then
    return
  end
  local PetBaseID = _G.DataConfigManager:GetPetConf(PetData.conf_id).base_id
  local NpcConfID = _G.DataConfigManager:GetPetbaseConf(PetBaseID).npc_id
  local ModelConfID = _G.DataConfigManager:GetNpcConf(NpcConfID).model_conf
  local ModelConf = _G.DataConfigManager:GetModelConf(ModelConfID)
  LoadRes.Pet = ModelConf.path
  return LoadRes
end

function AffirmPetStateInst:OnResReady(LoadedAssets, Rsp)
  local PetClass = LoadedAssets.Pet
  if not PetClass then
    self:WarningLog("Loading Pet failed")
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local Pos = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER):GetActorLocation()
  Pos.Y = Pos.Y + 100
  local Transform = UE4.FTransform(UE4.FQuat(), Pos)
  self.PetRef = World:Abs_SpawnActor(PetClass, Transform, UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn)
  self:OpenPanel("AffirmPet")
end

function AffirmPetStateInst:OnEnter()
end

function AffirmPetStateInst:OnExit()
  if -1 == self.Direction then
    self:HidePanel("AffirmPet")
  else
    self:FoldPanel("AffirmPet")
  end
  self.PetRef:K2_DestroyActor()
  self.PetRef = nil
end

return AffirmPetStateInst
