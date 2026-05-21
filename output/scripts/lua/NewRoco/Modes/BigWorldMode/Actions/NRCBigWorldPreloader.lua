local StoryFlagPreloadLists = require("NewRoco.Modules.Core.Task.PreloadRes.StoryFlagPreloadLists")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local PlayerToyComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PlayerToyComponent")
local NRCBigWorldPreloader = NRCClass("NRCBigWorldPreloader")

function NRCBigWorldPreloader:Ctor()
  self.PreloadAssetList = {
    EQS_Runner = "/Game/NewRoco/Modules/Core/NPC/EQS/BP_EQSRunner.BP_EQSRunner_C",
    EQS_CloseRelease = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_PetRelease.EQ_PetRelease",
    EQS_FarRelease = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_FarRelease.EQ_FarRelease",
    EQS_FanFront = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_PetReleaseFanFront.EQ_PetReleaseFanFront",
    EQS_BallHeadBounce = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_BallHeadBounce.EQ_BallHeadBounce",
    EQS_PetBlessing = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_Pet_Blessing.EQ_Pet_Blessing",
    EQS_Iceberg = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_PutIceberg.EQ_PutIceberg",
    EQS_FlyLandingPos = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_FlyLandingPos.EQ_FlyLandingPos",
    EQS_SenseRelease = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_SenseRelease.EQ_SenseRelease",
    EQS_StaticMeshSocket = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_StaticMeshSocket.EQ_StaticMeshSocket",
    EQS_StaticMeshSocketNoTrace = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_StaticMeshSocketNoTrace.EQ_StaticMeshSocketNoTrace",
    EQS_TaggedFoliage = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_TaggedFoliage.EQ_TaggedFoliage",
    EQS_Dialogue = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_Dialogue.EQ_Dialogue",
    EQS_NavPoly = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_NavPoly.EQ_NavPoly",
    EQS_Spiral = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_Spiral.EQ_Spiral",
    EQS_SceneSeat = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_SceneSeat.EQ_SceneSeat",
    EQS_PosForServer = "/Game/NewRoco/Modules/Core/NPC/EQS/EQ_PosForServer.EQ_PosForServer",
    Quality1 = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Scene/NS_Item_Drop_White.NS_Item_Drop_White'",
    Quality2 = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Scene/NS_Item_Drop_Green.NS_Item_Drop_Green'",
    Quality3 = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Scene/NS_Item_Drop_Blue.NS_Item_Drop_Blue'",
    Quality4 = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Scene/NS_Item_Drop_Violet.NS_Item_Drop_Violet'",
    Quality5 = "ParticleSystem'/Game/ArtRes/Effects/Particle/Res/Scene/NS_Item_Drop_Orange.NS_Item_Drop_Orange'",
    CinematicPlayer = "/Game/NewRoco/Modules/Core/Cinematic/BP_CinematicPlayer.BP_CinematicPlayer_C",
    AirWall = "/Game/NewRoco/Modules/System/WorldCombat/AirWalls/BP_AirWall_Gen.BP_AirWall_Gen_C",
    AuraObject = "/Game/NewRoco/Modules/Core/NPC/Aura/BP_AuraBase.BP_AuraBase_C",
    DialogueUICamera = "/Game/NewRoco/Modules/Core/Character/DialogueUICameraActor.DialogueUICameraActor_C",
    PET_HUD = "WidgetBlueprint'/Game/NewRoco/Modules/System/MainUI/Res/UMG_Hud_Pet.UMG_Hud_Pet_C'",
    CAM_SplineManger = "/Game/NewRoco/Modules/System/Camera/BP_RocoCameraSplineManager.BP_RocoCameraSplineManager_C",
    CAM_SpringArmActor = "/Game/NewRoco/Modules/System/MiniGame/Res/BP_MiniGameSpringArmActor.BP_MiniGameSpringArmActor_C",
    Ball = "Blueprint'/Game/NewRoco/Modules/Core/NPC/PetBall/BP_NPCItemPetBall_A001.BP_NPCItemPetBall_A001_C'",
    Ball2 = "Blueprint'/Game/NewRoco/Modules/Core/NPC/PetBall/BP_NPCItemFairyBall_001.BP_NPCItemFairyBall_001_C'",
    Ball3 = "Blueprint'/Game/NewRoco/Modules/Core/NPC/PetBall/BP_NPCItemFairyBall_003.BP_NPCItemFairyBall_003_C'",
    DungeonLight = "Blueprint'/Game/ArtRes/BP/SpotLightActor/BP_Player_SpotLight.BP_Player_SpotLight_C'",
    PET_HUD_HOME = "WidgetBlueprint'/Game/NewRoco/Modules/System/Home/Res/HomeFeeding/UMG_Home_Pet.UMG_Home_Pet_C'",
    Font_ShangShouDunDun = "/Game/NewRoco/Font/244-ShangShouDunDun.244-ShangShouDunDun",
    Font_FangZhengLanTing_ZhongChu = "/Game/NewRoco/Font/FangZhengLanTing_ZhongChu.FangZhengLanTing_ZhongChu",
    Font_Rune_Regular = "/Game/NewRoco/Font/Rune-Regular.Rune-Regular",
    Font_Obj_FangZhengLanTing_ZhongChu = "/Game/NewRoco/Font/FangZhengLanTing_ZhongChu_Font.FangZhengLanTing_ZhongChu_Font",
    Font_Obj_Rune_Regular = "/Game/NewRoco/Font/Rune-Regular_Font.Rune-Regular_Font",
    BallHitFx = "/Game/ArtRes/Effects/Particle/Res/Scene/HitPet/NS_HitPet_Fx01.NS_HitPet_Fx01",
    GuardSphere = "Blueprint'/Game/NewRoco/Modules/Core/NPC/GuardArea/BP_NPCGuardSphere.BP_NPCGuardSphere_C'",
    img_duihua_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_duihua_png.img_duihua_png'",
    img_caiji_png = "PaperSprite'/Game/NewRoco/Modules/System/NPC/Raw/Frames/img_caiji_png.img_caiji_png'",
    img_baoxiang_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_baoxiang_png.img_baoxiang_png'",
    img_zhandou_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_zhandou_png.img_zhandou_png'",
    img_jiangli_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_jiangli_png.img_jiangli_png'",
    img_luopan_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_luopan_png.img_luopan_png'",
    img_caiji_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_caiji_png.img_caiji_png'",
    img_shilian_png = "PaperSprite'/Game/NewRoco/Modules/System/Dialogue/Raw/Frames/img_shilian_png.img_shilian_png'"
  }
  self.PreloadAssetList[UEPath.DEFAULT_AVATAR_SUIT_MALE] = UEPath.DEFAULT_AVATAR_SUIT_MALE
  self.PreloadAssetList[UEPath.DEFAULT_AVATAR_SUIT_FEMALE] = UEPath.DEFAULT_AVATAR_SUIT_FEMALE
  self.PreloadAssetList[UEPath.DEFAULT_AVATAR_PLAYER_MALE] = UEPath.DEFAULT_AVATAR_PLAYER_MALE
  self.PreloadAssetList[UEPath.DEFAULT_AVATAR_PLAYER_FEMALE] = UEPath.DEFAULT_AVATAR_PLAYER_FEMALE
  if RocoEnv.IS_EDITOR then
    self.PreloadAssetList[UEPath.DEFAULT_AVATAR_SUIT_MALE_EDITOR] = UEPath.DEFAULT_AVATAR_SUIT_MALE_EDITOR
    self.PreloadAssetList[UEPath.DEFAULT_AVATAR_SUIT_FEMALE_EDITOR] = UEPath.DEFAULT_AVATAR_SUIT_FEMALE_EDITOR
  end
  self.PreloadAssetList[UEPath.ABP_PLAYER_MALE] = UEPath.ABP_PLAYER_MALE
  self.PreloadAssetList[UEPath.ABP_PLAYER_FEMALE] = UEPath.ABP_PLAYER_FEMALE
  self.PreloadAssetList[UEPath.ABP_PLAYER_MALE_OTHER] = UEPath.ABP_PLAYER_MALE_OTHER
  self.PreloadAssetList[UEPath.ABP_PLAYER_FEMALE_OTHER] = UEPath.ABP_PLAYER_FEMALE_OTHER
  self.PreloadAssetList[UEPath.ANIM_CONFIG_MALE] = UEPath.ANIM_CONFIG_MALE
  self.PreloadAssetList[UEPath.ANIM_CONFIG_FEMALE] = UEPath.ANIM_CONFIG_FEMALE
  self.PreloadAssetList[UEPath.LEDGE_CLIMB_MONTAGE_MALE] = UEPath.LEDGE_CLIMB_MONTAGE_MALE
  self.PreloadAssetList[UEPath.JUMP_OUT_MONTAGE_MALE] = UEPath.JUMP_OUT_MONTAGE_MALE
  self.PreloadAssetList[UEPath.CLIMB_DOWN_MONTAGE_MALE] = UEPath.CLIMB_DOWN_MONTAGE_MALE
  self.PreloadAssetList[UEPath.LEDGE_CLIMB_MONTAGE_FEMALE] = UEPath.LEDGE_CLIMB_MONTAGE_FEMALE
  self.PreloadAssetList[UEPath.JUMP_OUT_MONTAGE_FEMALE] = UEPath.JUMP_OUT_MONTAGE_FEMALE
  self.PreloadAssetList[UEPath.CLIMB_DOWN_MONTAGE_FEMALE] = UEPath.CLIMB_DOWN_MONTAGE_FEMALE
  self.PreloadAssetList[UEPath.MARKER_PATH] = UEPath.MARKER_PATH
  self.PreloadAssetList[UEPath.BP_GRASS_TRIGGER] = UEPath.BP_GRASS_TRIGGER
  self.PreloadAssetList[UEPath.BPPerceptionPath] = UEPath.BPPerceptionPath
  self.PreloadAssetList.G6DashSkill = "/Game/NewRoco/Modules/Core/Scene/Ability/Dash/BP_G6DashSkill.BP_G6DashSkill_C"
  self.PreloadAssetList.G6MagicSkillCreate = "/Game/NewRoco/Modules/Core/Scene/Ability/Magic/BP_MagicSkill_Create.BP_MagicSkill_Create_C"
  self.PreloadAssetList.G6MagicSkillLight = "/Game/NewRoco/Modules/Core/Scene/Ability/Magic/BP_MagicSkill_Light.BP_MagicSkill_Light_C"
  self.PreloadAssetList.G6MagicSkillStar = "/Game/NewRoco/Modules/Core/Scene/Ability/Magic/BP_MagicSkill_Star.BP_MagicSkill_Star_C"
  self.PreloadAssetList.G6MagicSkillWind = "/Game/NewRoco/Modules/Core/Scene/Ability/Magic/BP_MagicSkill_Wind.BP_MagicSkill_Wind_C"
  self.PreloadAssetList.G6GlidingThrowSkill = "/Game/NewRoco/Modules/Core/Scene/Ability/ThrowBall/BP_GlidingThrowSkill.BP_GlidingThrowSkill_C"
  self.PreloadAssetList.G6RidingThrowSkill = "/Game/NewRoco/Modules/Core/Scene/Ability/ThrowBall/BP_RidingThrowSkill.BP_RidingThrowSkill_C"
  self.PreloadAssetList.G6ThrowSkill = "/Game/NewRoco/Modules/Core/Scene/Ability/ThrowBall/BP_ThrowSkill.BP_ThrowSkill_C"
  self.PreloadAssetList.RocoWindVolume0 = "/Game/NewRoco/Modules/Core/Scene/BP_RocoWindVolume.BP_RocoWindVolume_C"
  self.PreloadAssetList.RocoWindVolume1 = "/Game/NewRoco/Modules/Core/Scene/BP_SceneWindVolume1.BP_SceneWindVolume1_C"
  self.PreloadAssetList.RocoWindVolume2 = "/Game/NewRoco/Modules/Core/Scene/BP_SceneWindVolume2.BP_SceneWindVolume2_C"
  self.PreloadAssetList.RocoWindVolume3 = "/Game/NewRoco/Modules/Core/Scene/BP_MiniGameWindVolume.BP_MiniGameWindVolume_C"
  if RocoEnv.IS_EDITOR then
    self.PreloadAssetList.DialogueStage = "/Game/Editor/Dialogue/BP_DialogueStageActor.BP_DialogueStageActor_C"
  end
  local petMutationList = PetMutationUtils.GetPreloadList()
  if petMutationList then
    for key, value in pairs(petMutationList) do
      self.PreloadAssetList[key] = value
    end
  end
  local playerToyList = PlayerToyComponent.GetPreloadList()
  if playerToyList then
    for key, value in pairs(playerToyList) do
      self.PreloadAssetList[key] = value
    end
  end
  local PVPRankedMatchModulePreloadList = PVPRankedMatchModuleUtils.GetPreloadList()
  if PVPRankedMatchModulePreloadList then
    local PreloadAssetList = self.PreloadAssetList or {}
    for key, value in pairs(PVPRankedMatchModulePreloadList) do
      PreloadAssetList[key] = value
    end
  end
  self.Requests = {}
  self.LoadedAssets = {}
  self.LoadedAssetsRef = {}
  self.CallbackOwner = nil
  self.Callback = nil
  self.StartTime = -1
end

function NRCBigWorldPreloader:Get(Key)
  local Asset = self.LoadedAssets[Key]
  if NRCEnv:IsLocalMode() and not Asset then
    Asset = UE.UObject.Load(Key)
    self.LoadedAssets[Key] = Asset
    self.LoadedAssetsRef[Key] = Asset and UnLua.Ref(Asset)
  end
  return Asset
end

function NRCBigWorldPreloader:StartPreload(CallbackOwner, Callback)
  if _G.GlobalConfig.DisablePreLoadAsset then
    return
  end
  if self.Callback or self.CallbackOwner then
    Log.Error("NRCBigWorldPreloader\229\156\168\232\181\132\230\186\144\229\133\168\233\131\168\229\138\160\232\189\189\229\174\140\230\136\144\229\137\141\229\143\136\233\135\141\229\164\141\229\143\145\232\181\183\228\186\134\229\138\160\232\189\189...")
    if Callback then
      if CallbackOwner then
        Callback(CallbackOwner)
      else
        Callback()
      end
    end
    return
  end
  local PlayerData = _G.DataModelMgr.PlayerDataModel
  if PlayerData then
    for Flag, List in pairs(StoryFlagPreloadLists) do
      if PlayerData:HasStoryFlag(Flag) then
        for Key, Path in pairs(List) do
          self.PreloadAssetList[Key] = Path
        end
      end
    end
  end
  self.CallbackOwner = CallbackOwner
  self.Callback = Callback
  self.StartTime = os.msTime()
  ::lbl_60::
  self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
  if self.avatarSystem then
    self.avatarSystem:PreLoadAvatarConfigAsync({
      self.avatarSystem,
      SimpleDelegateFactory:CreateCallback(self, function()
        self.OnLoadAvatarAssets(self)
      end)
    })
    goto lbl_90
    goto lbl_88
    goto lbl_60
  end
  ::lbl_88::
  self:OnLoadAvatarAssets()
  ::lbl_90::
end

function NRCBigWorldPreloader:OnLoadAvatarAssets()
  Log.Debug("NRCBigWorldPreloader:OnLoadAvatarAssets")
  for _, Path in pairs(self.PreloadAssetList) do
    self.Requests[Path] = _G.NRCResourceManager:LoadResAsync(self, Path, 0, 0, self.OnLoadSuccess, self.OnLoadFailed)
  end
  self:CheckFinish()
end

function NRCBigWorldPreloader:OnLoadSuccess(Request, Res)
  local Path = Request.assetPath
  local Name = table.getKeyName(self.PreloadAssetList, Path)
  self.LoadedAssets[Name] = Res
  self.LoadedAssetsRef[Name] = Res and UnLua.Ref(Res)
  self:CheckFinish()
end

function NRCBigWorldPreloader:OnLoadFailed(Request, Message)
  Log.Warning("\233\162\132\229\138\160\232\189\189\232\181\132\230\186\144\229\164\177\232\180\165", Message)
  _G.NRCResourceManager:UnLoadRes(Request)
  self.Requests[Request.assetPath] = nil
  self:CheckFinish()
end

function NRCBigWorldPreloader:CheckFinish()
  local TotalCount = table.len(self.Requests)
  local CurrentCount = table.len(self.LoadedAssets)
  local Done = TotalCount <= CurrentCount
  local Diff = os.msTime() - self.StartTime
  if Done then
    Log.Debug("\233\162\132\229\138\160\232\189\189\229\133\168\229\177\128\232\181\132\230\186\144", TotalCount, "\232\128\151\230\151\182", Diff / 1000)
    self:FireCallback()
  else
    Log.Debug("\230\173\163\229\156\168\233\162\132\229\138\160\232\189\189\229\133\168\229\177\128\232\181\132\230\186\144", TotalCount, CurrentCount, Diff / 1000)
  end
end

function NRCBigWorldPreloader:FireCallback()
  local Owner = self.CallbackOwner
  local Callback = self.Callback
  self.CallbackOwner = nil
  self.Callback = nil
  if not Callback then
    return
  end
  if Owner then
    Callback(Owner)
  else
    Callback()
  end
end

return NRCBigWorldPreloader
