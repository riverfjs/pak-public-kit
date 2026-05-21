require("UnLuaEx")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local WeakPointRevealComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.WeakPointRevealComponent")
local CatchPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchPetComponent")
local WORLD_COMBAT_CONF = _G.DataConfigManager:GetAllByName("WORLD_COMBAT_CONF")
local BattlePet = require("NewRoco.Modules.Core.Battle.Entity.BattlePet")
local ShieldComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.ShieldComponent")
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ThrowUtils = require("NewRoco.Modules.Core.NPC.ThrowUtils")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local BP_NPCCharacter_C = Base:Extend("BP_NPCCharacter_C")
local OutLineVisibleRangeSqr = _G.DataConfigManager:GetGlobalConfigByKeyType("outline_visible_range", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
OutLineVisibleRangeSqr = OutLineVisibleRangeSqr * OutLineVisibleRangeSqr
local PET_BALL_KEY = "_ID_AUTOGENERATE_BALL0"
local NightmareBossEffectPath = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Scene/BossBattle/NMBoss/NS_Scene_NMBoss_ZishenLoop.NS_Scene_NMBoss_ZishenLoop'"
local NightmareBossRemoveEffectPath = "NiagaraSystem'/Game/ArtRes/Effects/Particle/Scene/BossBattle/NMBoss/NS_Scene_NMBoss_ZishenEnd.NS_Scene_NMBoss_ZishenEnd'"
local NightmareBossMoveEffectPath
local CD2Conf = _G.DataConfigManager:GetBattleGlobalConfig("touch_battle_min_cd")
local CD2 = 3
if CD2Conf and CD2Conf.num then
  CD2 = CD2Conf.num
end

function BP_NPCCharacter_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.bPlayingReleaseSkill = false
  self.LastActionMode = nil
  self.inBattle = Initializer and Initializer.inBattle
  self.OverridePetBallID = 0
  self.alpha = 0
  self.entered_deep_water = false
  if Initializer and self.sceneCharacter then
    self.sceneCharacter.viewObj = self
  end
  self.NightmareFxPathToInst = {}
  self.FxIDs = {}
  self.PendingFx = {}
  self.isPlayingRecycling = false
end

function BP_NPCCharacter_C:Init()
  Base.Init(self)
  if self.sceneCharacter then
    UE.UNRCCharacterUtils.SetCharacterMeshScale(self, self.sceneCharacter:GetConfigScale())
  else
    UE.UNRCCharacterUtils.RestoreAll(self)
  end
  self.RocoFX:Activate(true)
  self._bNavGenerated = false
end

function BP_NPCCharacter_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  if self.inBattle then
  else
    self:SetActorNeedTick(false)
  end
  if self.RocoBattleSwim then
    self.RocoBattleSwim:SetComponentTickEnabled(false)
  end
  if self.inBattle then
    local halfHeight = self:GetHalfHeight()
    local transform = self:Abs_GetTransform()
    local translation = transform.Translation
    translation.Z = translation.Z + halfHeight
    transform.Translation = translation
    self:Abs_K2_SetActorTransform_WithoutHit(transform)
    self.Mesh:SetCollisionProfileName("UI")
    self.Mesh:SetForcedLOD(1)
    self.HeadWidget:SetCollisionProfileName("NoCollision")
    self.ActionArea:SetCollisionProfileName("NoCollision")
    self.HeadWidget:SetHiddenInGame(true)
    if _G.NRCAudioManager then
      _G.NRCAudioManager:SetEmitterSwitch("Pet_Switch", "Pet_Battle", self)
    end
    if self.CharacterMovement then
      self.CharacterMovement.MaxWalkSpeed = 0
      if not BattleUtils.IsDeepWater() then
        self.CharacterMovement.IsEnableSwim = false
      end
      self.CharacterMovement:SetComponentTickEnabled(false)
    end
    if self.SignificanceComponent then
      self.SignificanceComponent.bAlwaysTickAnim = true
    end
    self.AutoPossessAI = UE4.EAutoPossessAI.PlacedInWorld
    self.AIControllerClass = nil
  end
  local SceneCharacter = self.sceneCharacter
  if SceneCharacter and not SceneCharacter:IsControlledByPlayer() then
    local PetInfo = SceneCharacter.serverData.pet_info
    if PetInfo and nil ~= PetInfo.gid then
      SceneCharacter.bDisappearPerform = true
    end
  end
  if not RocoEnv.IS_SHIPPING and SceneCharacter and SceneCharacter.IsPet and SceneCharacter:IsPet() and self.SetNRCTypeHash then
    self:SetNRCTypeHash(6)
  end
end

function BP_NPCCharacter_C:OnFrameLoad(distanceRatio)
  if not SceneUtils.debugCloseNPCFacialAndWidget then
    local Character = self.sceneCharacter
    if Character then
      local hud = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetHudFromPool, NPCModuleEnum.HudPoolType.PetHud)
      if not hud then
        local hudClass = _G.NRCBigWorldPreloader:Get("PET_HUD")
        hud = UE4.UWidgetBlueprintLibrary.Create(self, hudClass)
      end
      Log.Debug("BP_NPCCharacter_C:OnFrameLoad SetWidget")
      if UE.UObject.IsValid(hud) then
        self.HeadWidget:SetWidget(hud)
        hud:SetParentHUD(self.HeadWidget)
      end
      if Character.PetHUDComponent then
        Character.PetHUDComponent:OnFrameLoaded()
      else
      end
    end
  end
  Base.OnFrameLoad(self, distanceRatio)
end

function BP_NPCCharacter_C:OnLoadResource()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.Mesh and self.Mesh.SkeletalMesh then
    if not self.FxIDs then
      self.FxIDs = {}
      self.PendingFx = {}
      self.NightmareFxPathToInst = {}
    end
    local fxList = self.SelfFxList
    local npc = self.sceneCharacter
    if npc and npc:IsPet() and npc.serverData and npc.serverData.npc_base then
      do
        local mutation_type = npc.serverData.npc_base.mutation_type
        if mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
          local fxListColorDiff = self.SelfFxListColorDiff
          if fxListColorDiff and fxListColorDiff:Num() > 0 then
            fxList = fxListColorDiff
          end
        end
      end
    end
    for _, FXSetting in tpairs(fxList) do
      if FXSetting then
        local AssetPath = tostring(FXSetting.Template)
        if _G.NRCResourceManager:IsValidLoad() then
          local req = _G.NRCResourceManager:LoadResAsync(self, AssetPath, PriorityEnum.Active_World_Combat_Boss, 10, self.FxLoadSucc, self.FxLoadFail)
          self.PendingFx[req] = FXSetting
        elseif _G.RocoEnv.IS_EDITOR then
          local InstID = self.RocoFX:PlayFx_Name_Transform(UE.UObject.Load(AssetPath), FXSetting.BoneName, FXSetting.Transform, true, 0)
          table.insert(self.FxIDs, InstID)
        end
      end
    end
  end
  self:ConfigureWaterCheckStatus()
  if self.ReceiveHitSetting then
    self.ReceiveHitSetting.bSkipSelfMoveTrue = true
  end
  local MoveComp = self.CharacterMovement
  if MoveComp and UE.UObject.IsValid(MoveComp) and MoveComp:IsA(UE.UCharacterNavMovementComponent) then
    local PetbaseConfRow = self.sceneCharacter and self.sceneCharacter:GetConfPetData()
    MoveComp.FallingResist = PetbaseConfRow and PetbaseConfRow.falling_resistance or 0
    local FallingSpeedUp = _G.DataConfigManager:GetNpcGlobalConfig("falling_speed_uplimit")
    MoveComp.FallingSpeedUpLimit = FallingSpeedUp and FallingSpeedUp.num or 500
  end
  Base.OnLoadResource(self)
  self:ModifySpecialEffect()
end

function BP_NPCCharacter_C:FxLoadSucc(req, fxClass)
  local FXSetting = self.PendingFx and self.PendingFx[req]
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  local FXComp = self.RocoFX
  if not FXSetting or not FXComp then
    return
  end
  self.PendingFx[req] = nil
  NRCResourceManager:UnLoadRes(req)
  local InstID = FXComp:PlayFx_Name_Transform(fxClass, FXSetting.BoneName, FXSetting.Transform, true, 0)
  if self.needHideSelf then
    self.RocoFX:ShowHideFxByID(InstID, false)
  end
  table.insert(self.FxIDs, InstID)
  local Comp = self.RocoFX
  if not Comp then
    return
  end
  local FxCom = Comp:GetFxSystemComponentById(InstID)
  if FxCom then
    FxCom:SetFloatParameter("Common_Xray", 1 - self.alpha)
  end
end

function BP_NPCCharacter_C:SetSelfFXVisible(isShow)
  for i, v in pairs(self.FxIDs) do
    self.RocoFX:ShowHideFxByID(v, isShow)
  end
  self.needHideSelf = isShow
end

function BP_NPCCharacter_C:SetMeshAlpha(Alpha)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  self.alpha = Alpha
  Base.SetMeshAlpha(self, Alpha)
  local Comp = self.RocoFX
  if not Comp or not UE.UObject.IsValid(Comp) then
    return
  end
  if self.FxIDs == nil then
    return
  end
  for _, Fx in pairs(self.FxIDs) do
    local FxCom = Comp:GetFxSystemComponentById(Fx)
    if FxCom then
      FxCom:SetFloatParameter("Common_Xray", 1 - Alpha)
    end
  end
end

function BP_NPCCharacter_C:PlayGradualChangeFade(from, to, duration, callback)
  if duration <= 0 then
    self:SetMeshAlpha(to)
    if callback then
      callback()
    end
    return
  end
  self.fadeFrom = from
  self.fadeTo = to
  self.fadeDuration = duration
  self.fadeStartTime = 0
  self.fadeCallback = callback
  self:SetMeshAlpha(from)
  self:SetActorNeedTick(true)
end

function BP_NPCCharacter_C:BreakFadeCallback()
  self.fadeDuration = nil
  self.fadeCallback = nil
end

function BP_NPCCharacter_C:TickGradualFade(DeltaSeconds)
  if not self.fadeDuration then
    return true
  end
  self.fadeStartTime = self.fadeStartTime + DeltaSeconds
  local percentage = self.fadeStartTime / self.fadeDuration
  percentage = math.clamp(percentage, 0, 1)
  self:SetMeshAlpha(self.fadeFrom + (self.fadeTo - self.fadeFrom) * percentage)
  if self.fadeStartTime >= self.fadeDuration then
    self.fadeDuration = 0
    self:SetMeshAlpha(self.fadeTo)
    return true
  end
  return false
end

function BP_NPCCharacter_C:ProcessGradualCallBack()
  if self.fadeDuration and self.fadeDuration > 0 then
    return
  end
  if self.fadeCallback then
    self.fadeCallback()
    self.fadeCallback = nil
  end
end

function BP_NPCCharacter_C:FxLoadFail(req, msg)
  if not self.PendingFx then
    return
  end
  self.PendingFx[req] = nil
  NRCResourceManager:UnLoadRes(req)
end

function BP_NPCCharacter_C:NightmareFxLoadSucc(req, fxClass)
  local FXSetting = self.PendingFx and self.PendingFx[req]
  local FXComp = self.RocoFX
  if not FXSetting or not FXComp then
    return
  end
  if not self.PendingFx then
    self.PendingFx = {}
  end
  self.PendingFx[req] = nil
  NRCResourceManager:UnLoadRes(req)
  local InstID = FXComp:PlayFx_Name_Transform(fxClass, FXSetting.BoneName, FXSetting.Transform, true, 0)
  if self.needHideSelf then
    FXComp:ShowHideFxByID(InstID, false)
  end
  if self.FxIDs then
    table.insert(self.FxIDs, InstID)
  end
  if self.NightmareBossFXIDs then
    table.insert(self.NightmareBossFXIDs, InstID)
  end
  if not self.NightmareFxPathToInst then
    self.NightmareFxPathToInst = {}
  end
  self.NightmareFxPathToInst[req.assetPath] = InstID
end

function BP_NPCCharacter_C:OnUnLoadResource()
  local FXComp = self.RocoFX
  if self.FxIDs and FXComp then
    for _, ID in ipairs(self.FxIDs) do
      FXComp:StopFx(ID)
    end
  end
  table.clear(self.FxIDs)
  table.clear(self.PendingFx)
  table.clear(self.NightmareBossFXIDs)
  table.clear(self.NightmareFxPathToInst)
  Base.OnUnLoadResource(self)
end

function BP_NPCCharacter_C:SetVisibleInternal(visible)
  Base.SetVisibleInternal(self, visible)
  if UE.UObject.IsValid(self.MoveFXComponent) and self.MoveFXComponent.SetFxVisible then
    self.MoveFXComponent:SetFxVisible(visible)
  end
end

function BP_NPCCharacter_C:OnVisible()
  Base.OnVisible(self)
  local SC = self.sceneCharacter
  local Conf = SC and SC.config
  if Conf and Conf.genre == Enum.ClientNpcType.CNT_PETBOSS and self.PreventOverlap then
    self:PreventOverlap()
  end
end

function BP_NPCCharacter_C:ShowThrowInterInfo(visible, bAimShowLv)
  local SC = self.sceneCharacter
  local InterComp = SC and SC.InteractionComponent
  if not InterComp then
    return
  end
  local HUDComp = SC and SC.PetHUDComponent
  if not HUDComp then
    return
  end
  local Conf = SC and SC.config
  local ThrowInterType = Conf and Conf.throwing_interact_type
  if ThrowInterType ~= _G.Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET then
    return
  end
  if visible then
    self.sceneCharacter.isAimed = true
  else
    self.sceneCharacter.isAimed = false
  end
  if nil == bAimShowLv then
  else
    self.sceneCharacter.bShowAimedLv = bAimShowLv
  end
end

function BP_NPCCharacter_C:CanThrowInter(Item)
  if not self.sceneCharacter then
    return false
  end
  local ThrowInteractType = self.sceneCharacter:GetThrowInteractType()
  if ThrowInteractType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET or ThrowInteractType == Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
    local SceneCharacter = self.sceneCharacter
    local AIDisable = false
    if SceneCharacter.AIComponent then
      if Item and Item.ThrowSession and Item.ThrowSession:HasPet() then
        AIDisable = SceneCharacter.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_THROW_BATTLE)
        Log.Debug("\230\138\149\230\142\183\232\191\155\230\136\152\230\150\151\229\164\177\232\180\165\239\188\140\231\155\174\230\160\135AI\231\166\129\231\148\168\228\186\134\230\138\149\230\142\183\232\191\155\230\136\152")
      else
        AIDisable = SceneCharacter.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_CAPTURE)
        Log.Debug("\230\138\149\230\142\183\230\141\149\230\141\137\229\164\177\232\180\165\239\188\140\231\155\174\230\160\135AI\231\166\129\231\148\168\228\186\134\230\138\149\230\142\183\230\141\149\230\141\137")
      end
    end
    if AIDisable then
      return false
    end
    return true
  end
  if ThrowInteractType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL then
    return true
  end
  return false
end

function BP_NPCCharacter_C:CanEnterThrowInter(Comp)
  if self.CapsuleComponent == Comp then
    return true
  end
  local WeakComponent = self.sceneCharacter:GetComponent(WeakPointRevealComponent)
  if WeakComponent then
    local IsSelfInWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsSelfInWorldCombat)
    if not IsSelfInWorldCombat then
      return false
    end
    if WeakComponent:CanEnterThrowInter(Comp) then
      return true
    end
  end
  return self.Mesh and self.Mesh == Comp
end

function BP_NPCCharacter_C:OnThrowItemEnter(item, OtherComp, HitLocation, HitNormal)
  Log.Debug("BP_NPCCharacter_C:OnThrowItemEnter")
  local SceneCharacter = self.sceneCharacter
  local Session = item.ThrowSession
  local ThrowType = SceneCharacter:GetThrowInteractType()
  local HumanInteract = ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL
  local InterComp = SceneCharacter.InteractionComponent
  local PetData = Session and Session:HasPet() and Session.petData
  local BaseConf = PetData and _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  if HumanInteract and BaseConf and InterComp:CanInteractWithPet(BaseConf) then
    local RandOpt = InterComp:GetRandomOption()
    if RandOpt then
      item:GetPetBallComp():DoRandomHumanOptions({RandOpt})
      item:SetThrowFuncInValid()
      return
    end
  end
  local CanBattle, _ = SceneCharacter.InteractionComponent:CanBattleWithBox()
  local hasPet = Session:HasPet()
  local ReadyToBattle = CanBattle and hasPet
  if ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET and ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_CHIEF and not ReadyToBattle then
    if Session:HasPet() then
      item:ReleaseFailedIfStop()
    else
      item:ThrowRecycle()
    end
    return
  end
  if _G.GlobalConfig.DisableBattle then
    if Session:HasPet() then
      item:ThrowRecycle()
    else
      item:ReleaseFailedIfStop()
    end
    return
  end
  if Session:HasPet() then
    Log.Debug("BP_NPCCharacter_C:OnThrowItemEnter has pet")
    local HiddenComp = SceneCharacter.HiddenComponent
    if ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_CHIEF and HiddenComp and HiddenComp:IsHidden() then
      if HiddenComp.hiddenType == Enum.WorldHide.WH_MIMIC_OPTION then
        local _, Special = InterComp:GetPetOption(PetData)
        if Special then
          local BallComp = item:GetPetBallComp()
          BallComp:DoSpecialPetAction(false, Special)
          return
        else
          item:ThrowRecycle()
          return
        end
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_THUNDER then
        item:ThrowRecycle()
        return
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_DIVING then
        item:ThrowRecycle()
        return
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_FISHJUMP then
        item:ThrowRecycle()
        return
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_FALLING and not SceneCharacter:GetVisible() then
        item:ThrowRecycle()
        return
      end
    end
    if InterComp then
      local bCanBattle, failedReason = InterComp:CanBattleWithReason()
      if bCanBattle then
        Log.Debug("BP_NPCCharacter_C:OnThrowItemEnter CanBattle Sending Request")
        local WeakPointComponent = self.sceneCharacter:GetComponent(WeakPointRevealComponent)
        local WeakPointName
        if WeakPointComponent then
          WeakPointName = WeakPointComponent:TryGetWeakPoint(OtherComp, item)
          if not WeakPointName or self.sceneCharacter.IsMagicReplayActor and self.sceneCharacter:IsMagicReplayActor() then
          else
            _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self:Abs_K2_GetActorLocation(), Enum.DotsAIWorldEventType.DAWET_BOSS_WEAKPOINT_HITTED)
          end
        end
        if not WeakPointComponent then
          local Ban, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_THROW_BATTLE, false, false, CD2)
          if Ban then
            Log.Debug("\228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
            item:ThrowRecycle()
            return
          end
          local AIDisable = false
          if SceneCharacter.AIComponent then
            AIDisable = SceneCharacter.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_THROW_BATTLE)
          end
          if AIDisable then
            Log.Debug("\230\138\149\230\142\183\232\191\155\230\136\152\230\150\151\229\164\177\232\180\165\239\188\140\231\155\174\230\160\135AI\231\166\129\231\148\168\228\186\134\230\138\149\230\142\183\232\191\155\230\136\152")
            return
          end
        end
        local SubmitResult = InterComp:SubmitBattleOption(Session, WeakPointName)
        if SubmitResult then
          if ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
            self:OnEnterWorldLeaderShow()
          else
            local FxRes = _G.NRCBigWorldPreloader:Get("BallHitFx")
            if FxRes then
              UE.UNiagaraFunctionLibrary.SpawnSystemAtLocation(self, FxRes, HitLocation, HitNormal:ToRotator(), _G.FVectorOne)
            end
          end
          item:SetThrowFuncInValid()
        else
          item:ThrowRecycle()
        end
      else
        InterComp:TryShowBattleFailedTips(failedReason)
        item:ThrowRecycle()
      end
    else
      item:ThrowRecycle()
    end
  elseif Session:HasItem() then
    if ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
      item:ThrowRecycle()
    else
      local SrcActorType = SceneCharacter:GetActorType()
      if SrcActorType ~= ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.forbid_capture_otherspet)
        item:ThrowRecycle()
        return
      end
      if SceneCharacter:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.forbid_capture_battlepet)
        item:ThrowRecycle()
        return
      end
      local canCatch = SceneCharacter.InteractionComponent and SceneCharacter.InteractionComponent:CanCatch()
      if not canCatch then
        item:ThrowRecycle()
        return
      end
      local BaseInfo = SceneCharacter:GetNpcBaseInfo()
      local mutation_type = BaseInfo.mutation_type or 0
      local IsGlass = PetUtils.CheckIsShiningGlass(mutation_type) or 0 ~= mutation_type & _G.Enum.MutationDiffType.MDT_GLASS
      if IsGlass then
        local BallID = Session:GetItemID()
        local ForbidBallsConf = _G.DataConfigManager:GetNpcGlobalConfig("catch_pet_world_cant_colorpet_ball")
        local ForbidBalls = ForbidBallsConf and ForbidBallsConf.numList
        if ForbidBalls and table.contains(ForbidBalls, BallID) then
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.forbid_capture_colorfulpet)
          item:ThrowRecycle()
          return
        end
      end
      if not _G.DataModelMgr.PlayerDataModel:HasPetVacancy() then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.PetBag_Full2)
        item:ThrowRecycle()
        return
      end
      local CatchComp = item.sceneCharacter:EnsureComponent(CatchPetComponent)
      CatchComp:StartCatchPet(SceneCharacter)
    end
  end
end

function BP_NPCCharacter_C:OnRemoveSelf()
  Log.Debug("BP_NPCCharacter_C OnThrowItemEnter OnRemoveSelf:")
  self.sceneCharacter:SetNotDestroyFlag(false)
  if self.sceneCharacter:IsLocal() or self.sceneCharacter.ThrowSession then
    _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RecycleThrowPet, self)
  else
    local serverID = self.sceneCharacter:GetServerId()
    _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, serverID)
  end
  if self.sceneCharacter then
    self.sceneCharacter:Destroy()
  end
end

function BP_NPCCharacter_C:OnThrowEnterBattleRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  if not rsp.throw_battle_result then
    return
  end
  Log.Debug("BP_NPCCharacter_C:OnThrowEnterBattleRsp")
end

function BP_NPCCharacter_C:OnEnterWorldLeaderShow()
  local skillPath = BattleConst.Define.LeaderHitShow
  
  local function registerEvent(skill)
    skill:RegisterEventCallback("PreStart", self, self.OnEnterWorldLeaderShowLoad)
  end
  
  self:PlaySkill(skillPath, self, self, registerEvent, self.OnEnterWorldLeaderShowEnd, true)
end

function BP_NPCCharacter_C:OnEnterWorldLeaderShowLoad(Name, skillObject)
  UE4.RocoSkillUtils.SetBranchJumpFrames(skillObject, "RemoveWorldLeaderShow", 120)
  _G.BattleManager.battleRuntimeData:SetWorldLeaderShowSkill(skillObject)
  BattleSkillManager:PreLoadSingleResInternal(BattleConst.Define.LeaderBattleEnterShow1, true)
end

function BP_NPCCharacter_C:OnEnterWorldLeaderShowEnd()
  _G.BattleManager.battleRuntimeData:StopWorldLeaderShowSkill()
end

function BP_NPCCharacter_C:OnEnterBattle(center, radius, disSqr)
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    Log.Error("\232\191\153\228\184\141\230\173\163\229\184\184\239\188\140OnEnterBattle\230\152\175\233\128\154\232\191\135SceneNpc\232\176\131\232\191\135\230\157\165\231\154\132\239\188\140\228\189\134\230\152\175\229\143\145\231\142\176\230\178\161\230\156\137")
    return
  end
  if SceneCharacter.ThrowSession then
    SceneCharacter.ThrowSession:RecycleDirect()
  elseif SceneCharacter.AIComponent then
    local bKeepAiInBattlefield = SceneCharacter.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_KEEP_AI_IN_BATTLEFIELD)
    local bLogicStatusBattle = SceneCharacter:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_FIGHTING)
    if bLogicStatusBattle or not bKeepAiInBattlefield and disSqr < radius * radius then
      SceneCharacter:SetVisibleForBattleReason(false)
      SceneCharacter.AIComponent:LockForBattleReason()
      self.hidedWhenEnterBattle = true
    elseif not SceneCharacter.AIComponent.isDots and SceneCharacter.AIComponent:IsActive() then
      SceneCharacter.AIComponent:LockForBattleReason()
    end
  else
    Log.Debug("BP_NPCCharacter_C:OnEnterBattle", center, radius, disSqr)
    Base.OnEnterBattle(self, center, radius, disSqr)
  end
end

function BP_NPCCharacter_C:SetCollisionEnableInternal(Flag)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.bBlockCollision then
    return
  end
  local SceneCharacter = self.sceneCharacter
  if SceneCharacter then
    SceneCharacter:SetNPCCollision(Flag)
    self:SetActorEnableCollision(true)
  else
    self:SetActorEnableCollision(Flag)
  end
end

function BP_NPCCharacter_C:OnLeaveBattle()
  Log.Debug("BP_NPCCharacter_C:OnLeaveBattle")
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  if self.entered_deep_water then
    SceneCharacter:OnEnterDeepWater()
  end
  if SceneCharacter.AIComponent then
    SceneCharacter.AIComponent:OnLeaveBattle()
  end
  SceneCharacter:SetVisibleForBattleReason(true)
end

function BP_NPCCharacter_C:Recycle()
  local HUD = self.HeadWidget:GetWidget()
  if UE.UObject.IsValid(HUD) then
    HUD.ParentHeadWidget = nil
    self.HeadWidget:SetWidget(nil)
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ReturnHudToPool, NPCModuleEnum.HudPoolType.PetHud, HUD)
  end
  self.ThrowSession = nil
  self.RocoFX:Deactivate()
  self:ClearMaterials()
  self.RocoSkill:StopCurrentSkill()
  self.RocoSkill:ClearAllPassiveSkillObjs()
  self.RocoSkill:StopPendingSkill()
  self.RocoSkill:ClearSkillObj()
  Base.Recycle(self)
end

function BP_NPCCharacter_C:ClearMaterials()
  self.RocoMaterial:ClearMaterials()
end

function BP_NPCCharacter_C:GetRadius()
  return self.CapsuleComponent:GetScaledCapsuleRadius()
end

function BP_NPCCharacter_C:GetClassType()
  return 1
end

function BP_NPCCharacter_C:ReceiveTick(DeltaSeconds)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self.Overridden then
    self.Overridden.ReceiveTick(self, DeltaSeconds)
  end
  local canStopTick = true
  if not self:TickUpdateRotate(DeltaSeconds) then
    canStopTick = false
  end
  if not self:TickFlyProperty(DeltaSeconds) then
    canStopTick = false
  end
  if not self:TickGradualFade(DeltaSeconds) then
    canStopTick = false
  end
  if self.inBattle and (self.MimicActor or self.MimicMesh) then
    canStopTick = false
  end
  if canStopTick then
    self:SetActorNeedTick(false)
  end
  self:ProcessGradualCallBack()
end

function BP_NPCCharacter_C:PlayAnimByType(type, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  rate = rate or 1
  position = position or 0
  BlendInTime = BlendInTime or 0.25
  BlendOutTime = BlendOutTime or 0.25
  LoopCount = LoopCount or 1
  endPosition = endPosition or 0
  local animName = UE4.RocoEnumUtils.EnumToStringLua("EBattlePetAnimType", type)
  if not self.RocoAnim then
    Log.Error("can't find roco anim on actor!")
    return 0.0
  end
  return self.RocoAnim:PlayAnimByName(animName, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
end

function BP_NPCCharacter_C:PlayAnimByName(name, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  rate = rate or 1
  position = position or 0
  BlendInTime = BlendInTime or 0.25
  BlendOutTime = BlendOutTime or 0.25
  LoopCount = LoopCount or 1
  endPosition = endPosition or 0
  if not self.RocoAnim then
    Log.Error("can't find roco anim on actor!")
    return 0.0
  end
  return self.RocoAnim:PlayAnimByName(name, rate, position, BlendInTime, BlendOutTime, LoopCount, endPosition)
end

function BP_NPCCharacter_C:PlayAnimByNameUsePercent(name, rate, percent, BlendInTime, BlendOutTime, LoopCount, endPosition)
  rate = rate or 1
  percent = percent or 0
  if percent >= 1 then
    percent = 0
  end
  BlendInTime = BlendInTime or 0.25
  BlendOutTime = BlendOutTime or 0.25
  LoopCount = LoopCount or 1
  endPosition = endPosition or 0
  if not self.RocoAnim then
    Log.Error("can't find roco anim on actor!")
    return 0.0
  end
  return self.RocoAnim:PlayAnimByNameUsePercent(name, rate, percent, BlendInTime, BlendOutTime, LoopCount, endPosition)
end

function BP_NPCCharacter_C:GetAnimNameLengthMap()
  return self.RocoAnim:GetAnimNameLengthMap()
end

function BP_NPCCharacter_C:GetCurrentAnimPercent()
  return self.RocoAnim:GetCurrentAnimPercent()
end

function BP_NPCCharacter_C:GetCurrAnimDuration()
  return self.RocoAnim:GetCurrAnimDuration()
end

function BP_NPCCharacter_C:OnActorClick()
  Log.Debug("BP_NPCCharacter_C:OnPetClick")
end

function BP_NPCCharacter_C:ReceiveDestroyed()
  if self.sceneCharacter then
    self.sceneCharacter:OnDestroyedByEngine()
  end
end

function BP_NPCCharacter_C:GetRadius()
  if self.CapsuleComponent then
    return self.CapsuleComponent:GetUnscaledCapsuleRadius()
  else
    return -1
  end
end

function BP_NPCCharacter_C:ClearTargetRotator()
  self.targetRotator = nil
end

function BP_NPCCharacter_C:LerpToRotation(targetRotator)
  if targetRotator.Pitch < 0 then
    targetRotator.Pitch = 360 + targetRotator.Pitch
  end
  if targetRotator.Yaw < 0 then
    targetRotator.Yaw = 360 + targetRotator.Yaw
  end
  if targetRotator.Roll < 0 then
    targetRotator.Roll = 360 + targetRotator.Roll
  end
  self.targetRotator = targetRotator
  if self.targetRotator then
    self:SetActorNeedTick(true)
  end
end

function BP_NPCCharacter_C:SetBpRotateRate(rotateRate)
  self.rotateRate = rotateRate
end

function BP_NPCCharacter_C:TickUpdateRotate(deltaTime)
  if self.targetRotator and self.rotateRate then
    local DeltaRot = self:GetDeltaRotation(deltaTime)
    if not DeltaRot then
      return
    end
    local AngleTolerance = 0.001
    local CurrentRotation = self:K2_GetActorRotation()
    if not CurrentRotation then
      Log.ErrorFormat("BP_Pet is wrong.. Show Type %s", tostring(type(self)))
      Log.DebugFormat("Checking if self is valid %s", self:IsValid() and "valid" or "not valid")
      Log.Dump(self, 2, "Show Self")
      return
    end
    if CurrentRotation.Pitch < 0 then
      CurrentRotation.Pitch = 360 + CurrentRotation.Pitch
    end
    if CurrentRotation.Yaw < 0 then
      CurrentRotation.Yaw = 360 + CurrentRotation.Yaw
    end
    if CurrentRotation.Roll < 0 then
      CurrentRotation.Roll = 360 + CurrentRotation.Roll
    end
    local DesiredRotation = self.targetRotator
    if AngleTolerance >= math.abs(CurrentRotation.Pitch - DesiredRotation.Pitch) and AngleTolerance >= math.abs(CurrentRotation.Yaw - DesiredRotation.Yaw) and AngleTolerance >= math.abs(CurrentRotation.Roll - DesiredRotation.Roll) then
      self.targetRotator = nil
    else
      if AngleTolerance < math.abs(CurrentRotation.Pitch - DesiredRotation.Pitch) then
        CurrentRotation.Pitch = UE4.LuaMathUtils.FixedTurn(CurrentRotation.Pitch, DesiredRotation.Pitch, DeltaRot.Pitch)
      end
      if AngleTolerance < math.abs(CurrentRotation.Yaw - DesiredRotation.Yaw) then
        CurrentRotation.Yaw = UE4.LuaMathUtils.FixedTurn(CurrentRotation.Yaw, DesiredRotation.Yaw, DeltaRot.Yaw)
      end
      if AngleTolerance < math.abs(CurrentRotation.Roll - DesiredRotation.Roll) then
        CurrentRotation.Roll = UE4.LuaMathUtils.FixedTurn(CurrentRotation.Roll, DesiredRotation.Roll, DeltaRot.Roll)
      end
      self:K2_SetActorRotation(CurrentRotation, true)
    end
  end
  return self.targetRotator == nil
end

function BP_NPCCharacter_C:GetDeltaRotation(deltaTime)
  if self.rotateRate then
    return UE4.FRotator(self:GetAxisDeltaRotation(self.rotateRate.Pitch, deltaTime), self:GetAxisDeltaRotation(self.rotateRate.Yaw, deltaTime), self:GetAxisDeltaRotation(self.rotateRate.Roll, deltaTime))
  end
  return nil
end

function BP_NPCCharacter_C:GetAxisDeltaRotation(inAxisRotationRate, deltaTime)
  if inAxisRotationRate and type(inAxisRotationRate) == "number" and inAxisRotationRate >= 0 then
    return math.min(inAxisRotationRate * deltaTime, 360.0)
  else
    return 360.0
  end
end

function BP_NPCCharacter_C:TryHelmetOn()
  if self.HelmetOn then
    self:HelmetOn()
  end
end

function BP_NPCCharacter_C:TryHelmetOff()
  if self.HelmetOff then
    self:HelmetOff()
  end
end

function BP_NPCCharacter_C:GetAnimComponent()
  local Comp = self.RocoAnim
  if not Comp then
    return nil
  end
  if not UE.UObject.IsValid(Comp) then
    return nil
  end
  return Comp
end

function BP_NPCCharacter_C:IsOnTheGround()
  local MoveComp = self.CharacterMovement
  return MoveComp.MovementMode == UE4.EMovementMode.MOVE_Walking or MoveComp.MovementMode == UE4.EMovementMode.MOVE_NavWalking
end

function BP_NPCCharacter_C:RecycleThrowSession()
  self.sceneCharacter:TryRecycle()
end

function BP_NPCCharacter_C:FlyBackToPlayer(Hide, OverrideBall, Caller, Callback)
  local SceneCharacter = self.sceneCharacter
  if self.sceneCharacter then
    self.sceneCharacter.shouldDestroy = not Hide
  end
  local AIComponent = SceneCharacter and SceneCharacter.AIComponent
  if AIComponent then
    AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.INTERACT)
  end
  local HiddenComp = SceneCharacter and SceneCharacter.HiddenComponent
  if HiddenComp then
    HiddenComp:ResetHide()
  end
  local BubbleComp = SceneCharacter and SceneCharacter.BubbleComponent
  if BubbleComp then
    BubbleComp:StopAll()
  end
  local ThrowSession = SceneCharacter and SceneCharacter.ThrowSession
  if ThrowSession and (ThrowSession:IsRecycling() or ThrowSession:IsDestroyed()) then
    if not self.isPlayingRecycling then
      self:MarkThrowDestroyed()
      self:FlyComplete()
    end
    return
  end
  self:TogglePhysics(false)
  if self.bHidden then
    self:MarkThrowDestroyed()
    self:FlyComplete()
    return
  end
  local player = SceneUtils.GetPlayer(SceneCharacter:GetCreatorID())
  local playerView = SceneUtils.GetPlayerView(player)
  local SkillComponent = self.RocoSkill
  local Skill = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Yuancheng/CallBack_False", SkillComponent, PriorityEnum.Active_Player_Action)
  if not Skill then
    Log.Error("\230\151\160\230\179\149\230\173\163\229\184\184\232\142\183\229\143\150\229\155\158\230\148\182\231\178\190\231\129\181\228\189\191\231\148\168\231\154\132\230\138\128\232\131\189\229\175\185\232\177\161\239\188\140\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
    ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    if Hide then
      self.sceneCharacter:SetVisibleForServerReason(true)
    else
      self.sceneCharacter:Destroy()
    end
    return
  end
  if not playerView then
    Log.Error("FlyBackToPlayer: \230\151\160\230\179\149\230\173\163\229\184\184\232\142\183\229\143\150\231\142\169\229\174\182\232\167\134\229\155\190")
    self:FlyComplete()
    return
  end
  Skill:SetCaster(playerView)
  Skill:SetPassive(true)
  Skill:SetTargets({self})
  if Caller and Callback then
    Skill:SetAdditions("Callback", WeakTable({Caller = Caller, Callback = Callback}))
  end
  if ThrowSession and ThrowSession.petData then
    Skill:SetDynamicData({
      BallPath = BattleUtils.GetPetBallPath(ThrowSession.petData)
    })
  elseif self.OverridePetBallID and self.OverridePetBallID > 0 then
    Skill:SetDynamicData({
      BallPath = BattleUtils.GetPetBallPath({
        ball_id = self.OverridePetBallID
      })
    })
  elseif OverrideBall and OverrideBall.viewObj then
    Skill:SetAdditions("Ball", OverrideBall)
  elseif self.sceneCharacter.serverData and self.sceneCharacter.serverData.pet_info then
    Skill:SetDynamicData({
      BallPath = BattleUtils.GetPetBallPath({
        ball_id = self.sceneCharacter.serverData.pet_info.ball_id
      })
    })
  end
  Skill:SetAdditions("ShouldHide", Hide and true or false)
  Skill:RegisterEventCallback("End", self, self.FlyComplete)
  Skill:RegisterEventCallback("PreEndAnim", self, self.FlyComplete)
  Skill:RegisterEventCallback("PreEnd", self, self.FlyComplete)
  Skill:RegisterEventCallback("Interrupt", self, self.FlyComplete)
  Skill:RegisterEventCallback("Destroy", self, self.MarkThrowDestroyed)
  Skill:RegisterEventCallback("PreStart", self, self.FlySkillPreStart)
  Skill:RegisterEventCallback("CheckCaster", self, self.CheckFlyBackSkillCaster)
  self.isPlayingRecycling = true
  Skill:PlaySkill(self, self.OnSkillCallBack)
  if ThrowSession then
    ThrowSession:SetRecycling()
  end
  if SkillComponent then
    local CurrentActiveSkill = SkillComponent:GetActiveSkill()
    if CurrentActiveSkill then
      SkillComponent:CancelSkill(CurrentActiveSkill, UE.ESkillActionResult.SkillActionResultInterrupted)
    end
    SkillComponent:CancelAllPassiveSkillObjs(UE.ESkillActionResult.SkillActionResultInterrupted)
  end
end

function BP_NPCCharacter_C:FlySkillPreStart(Name, Skill)
  local OverrideBall = Skill:GetAddition("Ball")
  Skill:SetAdditions("Ball", nil)
  if OverrideBall and OverrideBall.viewObj then
    Skill.Blackboard:SetValueAsObject("_ID_AUTOGENERATE_BALL0", OverrideBall.viewObj)
    if OverrideBall.BallID and OverrideBall.BallID > 0 then
      local effectBlackboard = "Normal"
      local ballConfig = _G.DataConfigManager:GetBallConf(OverrideBall.BallID, true)
      if ballConfig then
        effectBlackboard = ballConfig.catch_effect_blackboard
      end
      Skill.Blackboard:SetValueAsString(effectBlackboard, effectBlackboard)
    end
  else
    local effectBlackboard = "Normal"
    local throwSession = self.sceneCharacter and self.sceneCharacter.ThrowSession
    local petData = throwSession and throwSession.petData
    local ball_id = petData and petData.ball_id or 0
    local ballConfig = _G.DataConfigManager:GetBallConf(ball_id, true)
    if ballConfig then
      effectBlackboard = ballConfig.catch_effect_blackboard
    end
    Skill.Blackboard:SetValueAsString(effectBlackboard, effectBlackboard)
  end
end

function BP_NPCCharacter_C:CheckFlyBackSkillCaster(Name, Skill)
  local SkillComponent = self.RocoSkill
  if SkillComponent and Skill then
    local caster = Skill:GetCaster()
    if not caster or not UE.UObject.IsValid(caster) then
      SkillComponent:CancelSkill(Skill, UE.ESkillActionResult.SkillActionResultInterrupted)
    end
  end
end

function BP_NPCCharacter_C:PlayDisappearPerform()
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter:IsControlledByPlayer() and not SceneCharacter:IsHidden() then
    local PetInfo = SceneCharacter.serverData.pet_info
    if PetInfo and PetInfo.gid ~= nil then
      SceneCharacter.bDisappearPerform = false
      self:FlyBackToPlayer()
      return
    end
  end
  Base.PlayDisappearPerform(self)
end

function BP_NPCCharacter_C:MarkThrowDestroyed(Name, Skill)
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  local ThrowSession = SceneCharacter.ThrowSession
  if not ThrowSession then
    return
  end
  ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
end

function BP_NPCCharacter_C:TogglePhysics(on)
  Base.TogglePhysics(self, on)
  if not self.SetActorEnableCollision then
    return
  end
  self:SetActorEnableCollision(on)
end

function BP_NPCCharacter_C:FlyComplete(Name, Skill)
  self.isPlayingRecycling = false
  if not self.sceneCharacter then
    return
  end
  if not Skill then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPet, self.sceneCharacter)
    return
  end
  if Skill:GetAddition("ShouldHide") then
    self.sceneCharacter:SetVisibleForServerReason(false)
  else
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPet, self.sceneCharacter)
  end
  local WeakPack = Skill:GetAddition("Callback")
  if WeakPack then
    local Caller = WeakPack.Caller
    local Callback = WeakPack.Callback
    if Caller and Callback then
      Callback(Caller)
    end
  end
  Skill:SetAdditions("Callback", nil)
end

function BP_NPCCharacter_C:OnSkillCallBack(skillProxy, result)
  if result ~= UE4.ESkillStartResult.Success then
    Log.Error("Throw pet failed to play FlyBackToPlayer skill!", result, skillProxy)
    if self.sceneCharacter and (not self.ThrowSession or not self.ThrowSession:IsRecycling() and not self.ThrowSession:IsDestroyed()) then
      self.sceneCharacter:Destroy()
    end
    if self.ThrowSession then
      self.ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
  end
end

function BP_NPCCharacter_C:SetIKEnable(boo)
  self.IkOverride = boo
end

function BP_NPCCharacter_C:ConfigureInitStatus()
  local SceneCharacter = self.sceneCharacter
  local MoveComp = self.CharacterMovement
  if not MoveComp then
    return
  end
  if MoveComp.GravityScaleInDeepWater then
    MoveComp.GravityScaleInDeepWater = 0.1
  end
  local serverData = SceneCharacter and SceneCharacter.serverData
  if not serverData or 0 == serverData.npc_base.npc_content_cfg_id then
    return
  end
  local contentData = DataConfigManager:GetNpcRefreshContentConf(serverData.npc_base.npc_content_cfg_id, true)
  if not contentData then
    return
  end
  if contentData.npc_initial_status == Enum.NpcInitialStatus.NIS_NONE then
  elseif contentData.npc_initial_status == Enum.NpcInitialStatus.NIS_CLIMB_TREE then
    MoveComp:OverrideNextDefaultMovementMode(UE4.EMovementMode.MOVE_None)
  elseif contentData.npc_initial_status == Enum.NpcInitialStatus.NIS_SWIM then
    MoveComp:OverrideNextDefaultMovementMode(UE4.EMovementMode.MOVE_Falling)
  elseif contentData.npc_initial_status == Enum.NpcInitialStatus.NIS_FLY then
    MoveComp:OverrideNextDefaultMovementMode(UE4.EMovementMode.MOVE_Flying)
    MoveComp:LuaRequestDirectMove(self:GetActorForwardVector(), true)
  end
end

function BP_NPCCharacter_C:ConfigureWaterCheckStatus()
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  local NeedWaterCheck = SceneCharacter:IsPet() and SceneCharacter.config.genre == Enum.ClientNpcType.CNT_NPC
  if NeedWaterCheck then
    local modelId = SceneCharacter and SceneCharacter.config.model_conf or 0
    local modelConf = DataConfigManager:GetModelConf(modelId, true)
    if modelConf and (modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_LAND or modelConf.habitat_flag == Enum.HABITAT_FLAG.HAB_FLY) then
      self:SetShouldCheckWaterSurface(true)
    end
  end
end

function BP_NPCCharacter_C:EnableBossFade(bEnable)
  bEnable = bEnable or false
  local ImageQualityLevel = UE4.UNRCQualityLibrary.GetImageQuality()
  if self.sceneCharacter and (self.sceneCharacter.config.genre == Enum.ClientNpcType.CNT_PETBOSS or self.sceneCharacter.config.genre == Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM) then
    if ImageQualityLevel == UE.ENRCImageQuality.Low then
      Log.Debug("BP_NPCCharacter_C:ModifySpecialEffect222", self.sceneCharacter:DebugNPCNameAndID(), ImageQualityLevel)
      bEnable = false
    else
      Log.Debug("BP_NPCCharacter_C:ModifySpecialEffect333", self.sceneCharacter:DebugNPCNameAndID(), ImageQualityLevel)
      bEnable = true
    end
    if UE.UObject.IsValid(self.RocoMaterial) and self.RocoMaterial.SetFadeEnable then
      Log.Debug("BP_NPCCharacter_C:ModifySpecialEffect666", self.sceneCharacter:DebugNPCNameAndID(), ImageQualityLevel, bEnable)
      self.RocoMaterial:SetFadeEnable(bEnable)
    end
  end
end

function BP_NPCCharacter_C:ModifySpecialEffect()
  if not _G.WorldCombatModuleCmd then
    return
  end
  if self.sceneCharacter and (self.sceneCharacter.config.genre == Enum.ClientNpcType.CNT_PETBOSS or self.sceneCharacter.config.genre == Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM) then
    Log.Debug("BP_NPCCharacter_C:ModifySpecialEffect111", self.sceneCharacter:DebugNPCNameAndID())
    self:EnableBossFade()
    _G.NRCEventCenter:RegisterEvent("BP_NPCCharacter_C", self, SystemSettingModuleEvent.RefreshDropDownList, self.EnableBossFade)
  end
  local InWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInWorldCombat)
  if self.sceneCharacter and SceneUtils.IsLogicStatusNightmareBossActivated(self.sceneCharacter) then
    self:ClearMaterials()
    PetMutationUtils.SetNightmareSecondMutation(self)
    if not self.NightmareBossFXIDs then
      self.NightmareBossFXIDs = {}
    end
    self:CreateNightmareFxs()
  end
  if SceneUtils.IsLogicStatusNightmareEliteActivated(self.sceneCharacter) and InWorldCombat then
    PetMutationUtils.SetNightmareSecondMutation(self)
  end
end

function BP_NPCCharacter_C:CreateNightmareFxs()
  if not self.NightmareFxPathToInst then
    self.NightmareFxPathToInst = {}
  end
  if not self.PendingFx then
    self.PendingFx = {}
  end
  if not self.NightmareFxPathToInst[NightmareBossEffectPath] then
    local FXSetting = UE4.FParticleSystemElement()
    FXSetting.BoneName = "locator_body"
    FXSetting.Transform = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
    if _G.NRCResourceManager:IsValidLoad() then
      local req = _G.NRCResourceManager:LoadResAsync(self, NightmareBossEffectPath, PriorityEnum.Active_World_Combat_Boss, 10, self.NightmareFxLoadSucc, self.FxLoadFail)
      self.PendingFx[req] = FXSetting
    elseif _G.RocoEnv.IS_EDITOR then
      local InstID = self.RocoFX:PlayFx_Name_Transform(UE.UObject.Load(NightmareBossEffectPath), FXSetting.BoneName, FXSetting.Transform, true, 0)
      table.insert(self.FxIDs, InstID)
      table.insert(self.NightmareBossFXIDs, InstID)
      self.NightmareFxPathToInst[NightmareBossEffectPath] = InstID
    end
  end
  if not NightmareBossMoveEffectPath then
    return
  end
  if not self.NightmareFxPathToInst[NightmareBossMoveEffectPath] then
    local FXSetting = UE4.FParticleSystemElement()
    FXSetting.BoneName = "locator_pos"
    FXSetting.Transform = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
    if _G.NRCResourceManager:IsValidLoad() then
      local req = _G.NRCResourceManager:LoadResAsync(self, NightmareBossMoveEffectPath, PriorityEnum.Active_World_Combat_Boss, 10, self.NightmareFxLoadSucc, self.FxLoadFail)
      self.PendingFx[req] = FXSetting
    elseif _G.RocoEnv.IS_EDITOR then
      local InstID = self.RocoFX:PlayFx_Name_Transform(UE.UObject.Load(NightmareBossMoveEffectPath), FXSetting.BoneName, FXSetting.Transform, true, 0)
      table.insert(self.FxIDs, InstID)
      table.insert(self.NightmareBossFXIDs, InstID)
      self.NightmareFxPathToInst[NightmareBossMoveEffectPath] = InstID
    end
  end
end

function BP_NPCCharacter_C:HideNightmareBossEffect(bHide)
  if self.NightmareBossFXIDs and self.RocoFX then
    for _, ID in ipairs(self.NightmareBossFXIDs) do
      self.RocoFX:ShowHideFxByID(ID, not bHide)
    end
  end
  if bHide then
    self:ClearMaterials()
    local FXSetting = UE4.FParticleSystemElement()
    FXSetting.BoneName = "locator_body"
    FXSetting.Transform = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0))
    if _G.NRCResourceManager:IsValidLoad() then
      local req = _G.NRCResourceManager:LoadResAsync(self, NightmareBossRemoveEffectPath, PriorityEnum.Active_World_Combat_Boss, 10, self.FxLoadSucc, self.FxLoadFail)
      self.PendingFx[req] = FXSetting
    elseif _G.RocoEnv.IS_EDITOR then
      local InstID = self.RocoFX:PlayFx_Name_Transform(UE.UObject.Load(NightmareBossRemoveEffectPath), FXSetting.BoneName, FXSetting.Transform, true, 0)
      table.insert(self.FxIDs, InstID)
    end
  else
    self:SetNightmare2Mutation()
    self:CreateNightmareFxs()
  end
end

function BP_NPCCharacter_C:SetFlyProperty(pitchFactor, speedFactor, flyRow)
  self.targetFlyPitch = pitchFactor or 0
  self.targetFlySpeed = speedFactor or 0
  self:SetActorNeedTick(true)
end

function BP_NPCCharacter_C:TickFlyProperty(deltaTime)
  local canStop = self.ActionMode ~= UE4.EPetActionMode.Fly
  if self.targetFlyPitch and self.targetFlySpeed and not canStop then
    if math.abs(self.targetFlySpeed - self.FlySpeed) > 0.001 then
      self.FlySpeed = LuaMathUtils.LerpWithMin(self.FlySpeed, self.targetFlySpeed, 0.01, deltaTime)
      canStop = false
    end
    if math.abs(self.targetFlyPitch - self.FlyPitch) > 0.001 then
      self.FlyPitch = LuaMathUtils.LerpWithMin(self.FlyPitch, self.targetFlyPitch, 0.01, deltaTime)
      canStop = false
    end
  end
  return canStop
end

function BP_NPCCharacter_C:OnEnterDeepWaterForAWhile()
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  Log.Debug("NPC\230\173\163\229\190\128\230\176\180\230\155\180\230\183\177\229\164\132\231\167\187\229\138\168", SceneCharacter.config.name)
  if _G.BattleManager.isSendWaiting or SceneCharacter:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_FIGHTING) then
    self.entered_deep_water = true
    return
  end
  SceneCharacter:OnEnterDeepWater()
end

function BP_NPCCharacter_C:Show()
  self.createdNPC = self.sceneCharacter.luaObj.createdNPC
  if self.createdNPC then
    Log.Debug("BP_NPCCharacter_C:Show", #self.createdNPC, self:GetDebugInfo())
  else
    Log.Debug("BP_NPCCharacter_C:Show with nil", self:GetDebugInfo())
  end
  self.ActorEmitter:ExplodeToAround(self, self:GetRadius(), self:GetHalfHeight(), self:Abs_K2_GetActorLocation(), self.createdNPC, self, self.OnItemExplode)
end

function BP_NPCCharacter_C:OnItemExplode()
  if self.sceneCharacter then
    self.sceneCharacter:SetNotDestroyFlag(false)
  else
    Log.Error("BP_NPCCharacter_C:OnItemExplode with no sceneCharacter")
  end
end

function BP_NPCCharacter_C:LoadLockEffect()
end

function BP_NPCCharacter_C:PlayLoopPerform()
  if not self.sceneCharacter then
    return
  end
  local config = self.sceneCharacter.config
  if config and config.original_emotion and self.RocoAnim then
    Log.Debug("BP_NPCCharacter_C:PlayLoopPerform", config.original_emotion, self:GetDebugInfo())
    local anim = self.RocoAnim:GetAnimSequenceByName(config.original_emotion)
    if anim and self.SetNPCIdleAdditiveAnim then
      self:SetNPCIdleAdditiveAnim(anim)
    elseif self.ClearNPCIdleAdditiveAnim then
      self:ClearNPCIdleAdditiveAnim()
    end
  end
  local serverData = self.sceneCharacter.serverData
  local npc_base = serverData and serverData.npc_base
  local loop_action = npc_base and npc_base.loop_action
  if loop_action and self.RocoAnim and UE.UObject.IsValid(self.RocoAnim) then
    Log.Debug("BP_NPCCharacter_C:PlayLoopPerform", loop_action, self:GetDebugInfo())
    local anim_sequence = self.RocoAnim:GetAnimSequenceByName(loop_action)
    if anim_sequence then
      if self.SetNPCIdleAnim then
        self:SetNPCIdleAnim(anim_sequence)
      end
      return
    end
  end
  if self.ClearNPCIdleAnim then
    self:ClearNPCIdleAnim()
  end
end

function BP_NPCCharacter_C:SetExpression(exId)
  local Value = PetMutationUtils.GetOverrideExpression(exId)
  self.OverrideExpression = Value
  local Mesh = self.Mesh
  local MatComp = self.RocoMaterial
  if Mesh and MatComp then
    MatComp:SetOverrideNature(exId)
    MatComp:UpdateOverrideNature(Mesh, exId)
  end
end

function BP_NPCCharacter_C:AskCanEnterThrow(Ball, Component)
  if self.ThrowSession then
    return false
  end
  if not self:CanThrowInter(Ball) then
    return false
  end
  if not self:CanEnterThrowInter(Component) then
    return false
  end
  local SceneCharacter = self.sceneCharacter
  local Session = Ball.ThrowSession
  local ThrowType = SceneCharacter:GetThrowInteractType()
  local HumanInteract = ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_NORMAL
  local InterComp = SceneCharacter.InteractionComponent
  local PetData = Session and Session:HasPet() and Session.petData
  local BaseConf = PetData and _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
  if HumanInteract and BaseConf and InterComp:CanInteractWithPet(BaseConf) then
    local RandOpt = InterComp:GetRandomOption()
    if RandOpt then
      return false
    end
  end
  if ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET and ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
    return false
  end
  if _G.DataModelMgr.PlayerDataModel:BattleDisabled() then
    return false
  end
  if Session:HasPet() then
    local HiddenComp = SceneCharacter.HiddenComponent
    if ThrowType ~= Enum.THROWING_INTERACT_TYPE.TIT_CHIEF and HiddenComp and HiddenComp:IsHidden() then
      if HiddenComp.hiddenType == Enum.WorldHide.WH_MIMIC_OPTION then
        local _, Special = InterComp:GetPetOption(PetData)
        if Special then
          return true
        else
          return false
        end
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_THUNDER then
        return false
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_DIVING then
        return false
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_FISHJUMP then
        return false
      elseif HiddenComp.hiddenType == Enum.WorldHide.WH_FALLING and not SceneCharacter:GetVisible() then
        return false
      end
    end
    if InterComp and InterComp:CanBattle() then
      Log.Debug("BP_NPCCharacter_C:OnThrowItemEnter CanBattle Sending Request")
      local WeakPointComponent = self.sceneCharacter:GetComponent(WeakPointRevealComponent)
      if not WeakPointComponent then
        local Ban, Msg = _G.FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_THROW_BATTLE, false, false, CD2)
        if Ban then
          return false
        end
        local AIDisable = false
        if SceneCharacter.AIComponent then
          AIDisable = SceneCharacter.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_DISABLE_THROW_BATTLE)
        end
        if AIDisable then
          Log.Debug("\230\138\149\230\142\183\232\191\155\230\136\152\230\150\151\229\164\177\232\180\165\239\188\140\231\155\174\230\160\135AI\231\166\129\231\148\168\228\186\134\230\138\149\230\142\183\232\191\155\230\136\152")
          return false
        end
      end
      return true
    else
      return false
    end
  elseif Session:HasItem() then
    if ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
      return false
    else
      local SrcActorType = SceneUtils.GetActorDetailType(SceneCharacter:GetServerId())
      if SrcActorType ~= ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene then
        return false
      end
      if SceneCharacter:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_FIGHTING) then
        return false
      end
      local BaseInfo = SceneCharacter:GetNpcBaseInfo()
      local IsGlass = (BaseInfo.mutation_type or 0) & Enum.MutationDiffType.MDT_GLASS > 0
      if IsGlass then
        local BallID = Session:GetItemID()
        local ForbidBallsConf = _G.DataConfigManager:GetNpcGlobalConfig("catch_pet_world_cant_colorpet_ball")
        local ForbidBalls = ForbidBallsConf and ForbidBallsConf.numList
        if ForbidBalls and table.contains(ForbidBalls, BallID) then
          return false
        end
      end
    end
    local CatchTarget = self.sceneCharacter
    if not CatchTarget.canTriggerInteraction then
      return false
    end
    local IsDisableByMutation = ThrowUtils.IsDisableByMutation(CatchTarget, Ball and Ball.BallId)
    if IsDisableByMutation then
      return false
    end
    local HiddenComp = CatchTarget.HiddenComponent
    if HiddenComp and HiddenComp:IsResistCapture(Session and Session:GetBallId()) then
      return false
    end
    local AIComp = CatchTarget.AIComponent
    if AIComp and AIComp:IsResistCapture() then
      return false
    end
    local socketSnapComponent = CatchTarget.SocketSnapComponent
    if socketSnapComponent and (socketSnapComponent:IsSnapping() or socketSnapComponent:IsBeingSnapped()) then
      return false
    end
    return true
  end
  return false
end

function BP_NPCCharacter_C:IsHigherThanPlayer(player)
  if not player or not player.viewObj then
    return false
  end
  local PlayerMesh = player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  local head_location = PlayerMesh:GetSocketLocation("locator_Head")
  local player_head_z = head_location.Z
  local CapsuleComponent = self:GetComponentByClass(UE4.UCapsuleComponent)
  local CapsuleLocation = self:Abs_K2_GetActorLocation()
  local CapsuleHalfHeight = CapsuleComponent:GetScaledCapsuleHalfHeight()
  local petHeight = CapsuleLocation.Z + CapsuleHalfHeight * 0.3
  if player_head_z > petHeight then
    return false
  else
    return true
  end
end

function BP_NPCCharacter_C:TriggerWeakPointHitAnim()
  local AnimInst = self.Mesh:GetAnimInstance()
  if not AnimInst then
    Log.Error("BP_NPCCharacter_C:TriggerWeakPointHit AnimInst is nil")
    return
  end
  local Anim = self.RocoAnim:GetAnimSequenceByName("Hit1Add")
  if not Anim then
    Log.Error("BP_NPCCharacter_C:TriggerWeakPointHit Hit1Add Anim is nil")
    return
  end
  if AnimInst.TriggerWeakHit and type(AnimInst.TriggerWeakHit) == "function" then
    local WorldCombatConf
    for k, v in pairs(WORLD_COMBAT_CONF) do
      if v.refresh_content_id == self.sceneCharacter.serverData.npc_base.npc_content_cfg_id then
        WorldCombatConf = v
        break
      end
    end
    local hitAnimAlpha = 0.2
    if WorldCombatConf and WorldCombatConf.hit_anim_alpha > 0 then
      hitAnimAlpha = WorldCombatConf.hit_anim_alpha / 100
    end
    local length = Anim:GetPlayLength()
    AnimInst:TriggerWeakHit(Anim, hitAnimAlpha)
    self.delayStopWeakPointHitAnimId = _G.DelayManager:DelaySeconds(length, self.StopWeakPointHitAnim, self)
  end
end

function BP_NPCCharacter_C:StopWeakPointHitAnim()
  if self.delayStopWeakPointHitAnimId then
    _G.DelayManager:CancelDelayById(self.delayStopWeakPointHitAnimId)
    self.delayStopWeakPointHitAnimId = nil
  end
  if UE4.UObject.IsValid(self.Mesh) then
    local AnimInst = self.Mesh:GetAnimInstance()
    if not AnimInst then
      Log.Error("BP_NPCCharacter_C:StopWeakPointHitAnim AnimInst is nil")
      return
    end
    if AnimInst.TriggerWeakHit and type(AnimInst.TriggerWeakHit) == "function" then
      AnimInst:TriggerWeakHit(nil, 0)
    end
  end
end

return BP_NPCCharacter_C
