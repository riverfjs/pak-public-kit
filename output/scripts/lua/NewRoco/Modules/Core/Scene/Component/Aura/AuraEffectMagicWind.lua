local Base = require("NewRoco.Modules.Core.Scene.Component.Aura.AuraEffectObject")
local BlowAwayComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.BlowAwayComponent")
local PetStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusComponent")
local PetStatusType = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusType")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneAIUtils = require("NewRoco.AI.SceneAIUtils")
local WindClassPath = {
  "/Game/NewRoco/Modules/Core/Scene/BP_RocoWindVolume.BP_RocoWindVolume_C",
  "/Game/NewRoco/Modules/Core/Scene/BP_SceneWindVolume1.BP_SceneWindVolume1_C",
  "/Game/NewRoco/Modules/Core/Scene/BP_SceneWindVolume2.BP_SceneWindVolume2_C",
  "/Game/NewRoco/Modules/Core/Scene/BP_MiniGameWindVolume.BP_MiniGameWindVolume_C"
}
local WindChargeLevelEventMap = {
  [1] = Enum.DotsAIWorldEventType.DAWET_WIND_DROP,
  [2] = Enum.DotsAIWorldEventType.DAWET_WIND_DROP
}
local TaskModuleEvent = require("NewRoco.Modules.Core.Task.TaskModuleEvent")
local AuraEffectMagicWind = Base:Extend("AuraEffectMagicWind")

function AuraEffectMagicWind:Ctor(Owner, Index, Effect)
  self.Owner = Owner
  self.Index = Index
  self.Effect = Effect
end

local DispatchRunawayInterval = 1

function AuraEffectMagicWind:CheckNeedView()
  return false
end

function AuraEffectMagicWind:OnViewReady(View)
  self.volumeIndex = self.Effect.params[1] or 0
  local resName = string.format("RocoWindVolume%d", self.volumeIndex)
  local asset = _G.NRCBigWorldPreloader:Get(resName)
  self:OnLoadWindAsset(nil, asset)
end

function AuraEffectMagicWind:OnLoadWindAsset(req, asset)
  if not asset then
    return
  end
  local rotation = UE4.FQuat(0, 0, 0, 1)
  local position = SceneUtils.ServerPos2ClientPos(self.Owner.Info.pos)
  local params = self.Owner.Info.params
  local scale = UE4.FVector(1, 1, 1)
  local xfm = UE4.FTransform(rotation, position, scale)
  local windClass = asset
  self:OnRemove()
  self.wind = UE4Helper.GetCurrentWorld():Abs_SpawnActor(windClass, xfm, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, nil, nil, nil, true)
  self.windRef = self.wind and UnLua.Ref(self.wind)
  local creatorId = self.Owner.Info.create_avatar_id
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, creatorId)
  if not player then
    Log.WarningFormat("AuraEffectMagicWind creator is nil, creatorId = %d", creatorId or 0)
  elseif not UE.UObject.IsValid(player.viewObj) then
    Log.WarningFormat("AuraEffectMagicWind creator viewObj invalid, creatorId = %d", creatorId or 0)
  else
    UE4.UNRCStatics.SetActorOwner(self.wind, player.viewObj)
  end
  local radius = self.Owner.Config.aura_distance[1]
  local height = self.Owner.Config.aura_distance[2]
  local windAcc = self.Effect.params[2] or 3000
  local windMaxSpeedXY = self.Effect.params[3]
  if windMaxSpeedXY then
    self.wind.LimitXYSpeed = windMaxSpeedXY
  end
  local windInitSpeedZ = self.Effect.params[4]
  if windInitSpeedZ then
    self.wind.InSpeedZ = windInitSpeedZ
  end
  local windMaxSpeedZ = self.Effect.params[5]
  if windMaxSpeedZ then
    self.wind.LimitZSpeed = windMaxSpeedZ
  end
  local visible = true
  local level = 0
  local percent = 0
  if params then
    local paramLen = #params
    if paramLen > 2 then
      local chargeRadius = params[1]
      if chargeRadius and chargeRadius > 0 then
        radius = chargeRadius
      end
      local chargeAcc = params[3]
      if chargeAcc and chargeAcc > 0 then
        windAcc = chargeAcc
      end
    end
    if paramLen > 3 then
      visible = not params[4] or 1 ~= params[4]
    end
    if paramLen > 4 then
      level = params[5]
    end
    if paramLen > 5 then
      percent = params[6]
    end
  end
  local _NRCModuleManager = _G.NRCModuleManager
  local localPlayer = _NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local effectPath = UEPath.DefaultWindEffect
  self.isThrewMagicWind = params
  if self.isThrewMagicWind then
    local ownerPlayer = _NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, creatorId)
    if ownerPlayer then
      local wandConf = ownerPlayer:GetCurWandConf()
      local wandData = ownerPlayer:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_WIND)
      if wandData then
        if wandData.NS_Wind_Cylinder then
          local wandEffectPath = UE.UNRCStatics.GetSoftObjPath(wandData.NS_Wind_Cylinder)
          if wandEffectPath and "" ~= wandEffectPath then
            effectPath = wandEffectPath
          end
        end
        self.wandName = wandConf.WandName
      end
    end
  end
  self.wind.Radius = radius
  self.wind.Height = height
  local effectSizeXY = radius / 300
  local effectSizeZ = height / 4000
  local effectScale = UE4.FVector(effectSizeXY, effectSizeXY, effectSizeZ)
  self.wind.Effect:SetRelativeScale3D(effectScale)
  if self.wind.Effect_Water then
    self.wind.Effect_Water:SetRelativeScale3D(effectScale)
  end
  self.wind.WindAcceleration = windAcc
  self.wind:UpdateSize()
  if not visible then
    self.wind:SetActorHiddenInGame(true)
  else
    _G.NRCAudioManager:PlaySound3DWithActorAuto(10070202, self.wind, "Wind")
    if self.isThrewMagicWind then
      _G.NRCAudioManager:SetEmitterSwitch("Suit", self.wandName, self.wind)
    end
  end
  local bIsAuraFromLocalPlayer = true
  if bIsAuraFromLocalPlayer then
    if player and player.IsMagicReplayActor and player:IsMagicReplayActor() then
    else
      _NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, position, Enum.DotsAIWorldEventType.DAWET_WIND_DROP, nil, level + 1)
    end
    local SpecificEvent = WindChargeLevelEventMap[level + 1]
    if not SpecificEvent or player and player.IsMagicReplayActor and player:IsMagicReplayActor() then
    else
      _NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, position, SpecificEvent, nil, level + 1)
    end
    self:BlowAwayCharacters(level, percent)
  end
  if self.volumeIndex <= 1 and visible then
    Log.Debug("LoadWindEffect ", effectPath)
    _G.PlayerResourceManager:LoadResources_PlayerPerform(self, effectPath, bIsAuraFromLocalPlayer, self.OnLoadEffectSuccess, self.OnLoadEffectFailed, nil, 100)
  end
  self:OnAddWindVolume()
end

function AuraEffectMagicWind:OnLoadWindAssetFail(req, msg)
  Log.ErrorFormat("AuraEffectMagicWind:OnLoadWindAssetFail ")
end

function AuraEffectMagicWind:OnLoadEffectSuccess(asset)
  if self.wind then
    self.wind.Effect:SetAsset(asset)
    if self.wind.Effect_Water then
      self.wind.Effect_Water:SetAsset(asset)
    end
  end
end

function AuraEffectMagicWind:OnLoadEffectFailed(asset)
  Log.ErrorFormat("AuraEffectMagicWind:OnLoadWindEffectFail ")
end

local QueryingArray = UE.TArray(UE.AActor)

function AuraEffectMagicWind:BlowAwayCharacters(level, percent)
  if not self.wind then
    Log.Warning("AuraEffectMagicWind:BlowAway missing wind actor")
    return
  end
  local windConf = _G.DataConfigManager:GetMagicBaseConf(21, true)
  if not windConf then
    return
  end
  local radial_force = SceneAIUtils.ParseMagicParamByLevel(windConf, level, percent, 3, 4)
  local axial_force = SceneAIUtils.ParseMagicParamByLevel(windConf, level, percent, 2, 4)
  axial_force = math.max(axial_force - 980, 0)
  if 0 == radial_force then
    radial_force = 600
  end
  if 0 == axial_force then
    axial_force = 800
  end
  local center = self.wind:Abs_K2_GetActorLocation()
  self.wind:GetOverlappingActors(QueryingArray, UE.ANPCBaseCharacter)
  for _, actor in tpairs(QueryingArray) do
    local npc = actor.sceneCharacter
    if npc then
      local canBlowAway = AuraEffectMagicWind.BlowAwayFilter(npc)
      if canBlowAway then
        local blow = npc:EnsureComponent(BlowAwayComponent)
        local result = blow:LaunchByWindArea(center, radial_force, axial_force)
        if result then
          npc.module.SceneAIManager:SendDotsEvent(npc, 0, Enum.DotsAIWorldEventType.DAWET_HIT_BY_WIND, level, center)
        else
          npc.module.SceneAIManager:SendDotsEvent(npc, 0, Enum.DotsAIWorldEventType.DAWET_HIT_BY_WIND, -1, center)
        end
      end
    end
  end
  QueryingArray:Clear()
end

function AuraEffectMagicWind.BlowAwayFilter(npc)
  if not npc:IsPet() then
    return false
  end
  if npc:IsMagicReplayActor() then
    return false
  end
  local genre = npc.config.genre
  if genre ~= Enum.ClientNpcType.CNT_NPC and genre ~= Enum.ClientNpcType.CNT_HOME_NPC then
    return false
  end
  if npc.AIComponent and npc.AIComponent:IsLocked() then
    return false
  end
  local petStatus = npc:GetComponent(PetStatusComponent)
  if petStatus and (petStatus.Type == PetStatusType.Wait or petStatus.bInteractingWithSwitch) then
    return false
  end
  if npc.ThrowSession and npc.ThrowSession.Status ~= ThrowSessionStatusEnum.PostInteract then
    return false
  end
  return true
end

function AuraEffectMagicWind:OnRemove(Killer, RemoveInfo)
  if self.wind then
    self:OnRemoveWindVolume()
    _G.NRCAudioManager:PlaySound3DWithActor(3028, self.wind, "Wind", true, false, "", true, 0, false)
    if self.isThrewMagicWind then
      _G.NRCAudioManager:SetEmitterSwitch("Suit", self.wandName, self.wind, "")
    end
    self.wind:K2_DestroyActor()
    self.wind = nil
  end
  self.windRef = nil
end

function AuraEffectMagicWind:Destroy()
  self:OnRemove()
end

function AuraEffectMagicWind:OnAddWindVolume()
  NRCEventCenter:RegisterEvent("AuraEffectMagicWind", self, TaskModuleEvent.BattleStart, self.OnEnterBattle)
  NRCEventCenter:RegisterEvent("AuraEffectMagicWind", self, TaskModuleEvent.BattleOver, self.OnExitBattle)
  if _G.BattleManager.isInBattle then
    self:OnEnterBattle()
  end
end

function AuraEffectMagicWind:OnRemoveWindVolume()
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.BattleStart, self.OnEnterBattle)
  NRCEventCenter:UnRegisterEvent(self, TaskModuleEvent.BattleOver, self.OnExitBattle)
end

function AuraEffectMagicWind:OnEnterBattle()
  if self.wind and UE.UObject.IsValid(self.wind) then
    self.IsHiddenBeforeEnterBattle = self.wind.bHidden
    self.wind:SetActorHiddenInGame(true)
  end
end

function AuraEffectMagicWind:OnExitBattle()
  if self.wind and UE.UObject.IsValid(self.wind) then
    self.wind:SetActorHiddenInGame(self.IsHiddenBeforeEnterBattle)
  end
end

return AuraEffectMagicWind
