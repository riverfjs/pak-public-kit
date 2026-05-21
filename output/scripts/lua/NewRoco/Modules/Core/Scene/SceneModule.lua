local Base = require("Common.Singleton.Singleton")
local ScenePoolManager = require("NewRoco.Modules.Core.Scene.ScenePoolManager")
local SceneDataModel = require("NewRoco.Modules.Core.Scene.SceneDataModel")
local BlockingArea = require("NewRoco.Modules.Core.Scene.Common.BlockingArea")
_G.SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local StoryFlagModuleCmd = require("NewRoco.Modules.System.StoryFlag.StoryFlagModuleCmd")
local NPCModuleCmd = require("NewRoco.Modules.Core.NPC.NPCModuleCmd")
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local AreaAndZoneModuleCmd = require("NewRoco.Modules.Core.Scene.Map.AreaAndZoneModuleCmd")
local EnvSystemModuleCmd = require("NewRoco.Modules.System.EnvSystem.EnvSystemModuleCmd")
local TaskModuleCmd = require("NewRoco.Modules.Core.Task.TaskModuleCmd")
local BigMapModuleCmd = require("NewRoco.Modules.System.BigMap.BigMapModuleCmd")
local MiniGameModuleCmd = require("NewRoco.Modules.System.MiniGame.MiniGameModuleCmd")
local FunctionBanModuleCmd = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleCmd")
local SleepingOwlModuleCmd = require("NewRoco.Modules.System.SleepingOwl.SleepingOwlModuleCmd")
local MarkerModuleCmd = require("NewRoco.Modules.Core.Marker.MarkerModuleCmd")
local WorldCombatModuleCmd = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleCmd")
local SeasonIntegrationModuleCmd = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleCmd")
local DebugModuleCmd
if _G.AppMain:HasDebug() then
  DebugModuleCmd = require("NewRoco.Modules.System.Debug.DebugModuleCmd")
end
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local BattleField = require("NewRoco.Modules.Core.Battle.Common.BattleField")
local TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
local LegendaryBattleModuleCmd = require("NewRoco.Modules.Activity.LegendaryBattle.LegendaryBattleModuleCmd")
local FriendModuleCmd = require("NewRoco.Modules.System.Friend.FriendModuleCmd")
local OnlineState = require("Core.Service.NetManager.OnlineState")
local StaticAreaDetectionManager = require("NewRoco.Modules.Core.Scene.Common.StaticAreaDetectionManager")
local FarmModuleCmd = require("NewRoco.Modules.System.Farm.FarmModuleCmd")
local HomeModuleCmd = require("NewRoco.Modules.System.Home.HomeModuleCmd")
local AirWallModuleCmd = require("NewRoco.Modules.System.AirWall.AirWallModuleCmd")
local BattleSpectatorModuleCmd = require("NewRoco.Modules.System.BattleSpectator.BattleSpectatorModuleCmd")
local MagicReplayModuleCmd = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleCmd")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local TakePhotosModuleCmd = reload("NewRoco.Modules.System.TakePhotos.TakePhotosModuleCmd")
local RolePlayModuleCmd = require("NewRoco.Modules.System.RolePlay.RolePlayModuleCmd")
local MAX_SPACE_ACT_CACHE_TIME = 300000
local SceneModule = NRCModuleBase:Extend("SceneModule")

function SceneModule:AlwaysToFirst()
  return true
end

function SceneModule:DispatchOperation(Action)
  return self:CheckIsNpc(Action.operation.operator_id)
end

function SceneModule:OnConstruct()
  self.preMapId = 0
  self.mapID = 0
  self.mapInstId = 0
  self.mapResId = 0
  self.poolManager = ScenePoolManager()
  self.sceneDataModel = SceneDataModel(self)
  self.blockingArea = BlockingArea()
  self.PlayerDetector = StaticAreaDetectionManager()
  self.ActionCaches = {}
  self.TempCacheProcessArray = {}
  self.ProtoKeyFunctionMap = {
    actor_enter = {
      "actors",
      self.GetEnterActorType,
      NPCModuleCmd.ActorEnterAction,
      PlayerModuleCmd.ActorEnterAction
    },
    actor_leave = {
      "actor_ids",
      "",
      NPCModuleCmd.ActorLeaveAction,
      PlayerModuleCmd.ActorLeaveAction
    },
    combine_lock_state_change = {
      "",
      "actor_id",
      NPCModuleCmd.CombineLockAction,
      NPCModuleCmd.CombineLockAction
    },
    npc_guide_change = {
      "",
      self.AlwaysToFirst,
      MarkerModuleCmd.CombineGuideAction,
      MarkerModuleCmd.CombineGuideAction
    },
    move = {
      "",
      "actor_id",
      NPCModuleCmd.ActorMoveAction,
      PlayerModuleCmd.ActorMoveAction
    },
    teleport = {
      "",
      "actor_id",
      NPCModuleCmd.ActorTeleportAction,
      PlayerModuleCmd.ActorTeleportAction
    },
    update_actor_logic_status = {
      "",
      "actor_id",
      NPCModuleCmd.ActorUpdateLogicStatus,
      PlayerModuleCmd.ActorUpdateLogicStatus
    },
    add_story_flags = {
      "",
      "actor_id",
      NPCModuleCmd.AddStoryFlagsAction,
      ""
    },
    remove_story_flags = {
      "",
      "actor_id",
      NPCModuleCmd.RemoveStoryFlagsAction,
      ""
    },
    npc_option_info_change = {
      "",
      "npc_id",
      NPCModuleCmd.NpcOptionInfoChangeAction,
      ""
    },
    npc_dialog_select_info_change = {
      "",
      "npc_id",
      NPCModuleCmd.NpcDialogSelectInfoChangeAction,
      ""
    },
    begin_drop_item = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.BeginDropItem,
      ""
    },
    end_drop_item = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.EndDropItem,
      ""
    },
    attr_change = {
      "",
      "actor_id",
      NPCModuleCmd.ChangeNpcAttr,
      PlayerModuleCmd.PlayerAttrChange
    },
    npc_option_add_selects = {
      "",
      "npc_id",
      NPCModuleCmd.AddSelectAction,
      ""
    },
    npc_option_remove_selects = {
      "",
      "npc_id",
      NPCModuleCmd.RemoveSelectAction,
      ""
    },
    enterted_catcher = {
      "",
      self.AlwaysToFirst,
      AreaAndZoneModuleCmd.OnCatcherEnter,
      ""
    },
    left_catcher = {
      "",
      self.AlwaysToFirst,
      AreaAndZoneModuleCmd.OnCatcherLeave,
      ""
    },
    weather_change = {
      "",
      "actor_id",
      NPCModuleCmd.ActorWeatherChange,
      AreaAndZoneModuleCmd.OnWeatherChange
    },
    add_npc_option = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.AddOptionAction,
      ""
    },
    remove_npc_option = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.RemoveOptionAction,
      ""
    },
    play_anim_before_remove = {
      "",
      "actor_id",
      NPCModuleCmd.PlayAnimBeforeRemove,
      ""
    },
    tracking_npcs = {
      "",
      self.AlwaysToFirst,
      TaskModuleCmd.UpdateTrackingNpc,
      ""
    },
    potential_energy_change = {
      "",
      "actor_id",
      NPCModuleCmd.PotentialEnergyChange,
      ""
    },
    property_type_change = {
      "",
      "actor_id",
      NPCModuleCmd.PropertyTypeChange,
      ""
    },
    actor_born_end = {
      "",
      "actor_id",
      NPCModuleCmd.ActorBornEnd,
      ""
    },
    actor_die_begin = {
      "",
      "actor_id",
      NPCModuleCmd.ActorDieBegin,
      PlayerModuleCmd.PlayerDieBegin
    },
    begin_act_result_params_nty = {
      "",
      "npc_id",
      NPCModuleCmd.NotifyBeginActionParams,
      ""
    },
    opt_action_ntf = {
      "",
      "npc_id",
      NPCModuleCmd.NpcOptionNotify,
      ""
    },
    switch_boss_ai_nty = {
      "",
      "actor_id",
      NPCModuleCmd.ActorSwitchBossAINty,
      ""
    },
    ai_perform_group_id_changed = {
      "",
      "actor_id",
      NPCModuleCmd.ActorAIPerformGroupChanged,
      ""
    },
    move_mode = {
      "",
      "actor_id",
      NPCModuleCmd.ActorAISetMoveMode,
      ""
    },
    velocity_oriented_rotation = {
      "",
      "actor_id",
      NPCModuleCmd.ActorVelocityOrientedRotation,
      ""
    },
    world_launch_player = {
      "",
      "actor_id",
      NPCModuleCmd.ActorWorldLaunchPlayer,
      ""
    },
    play_animation = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayAnimationAction,
      ""
    },
    stop_animation = {
      "",
      "actor_id",
      NPCModuleCmd.ActorStopAnimationAction,
      ""
    },
    play_zoom_animation = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayZoomAnimationAction,
      ""
    },
    look_at = {
      "",
      "actor_id",
      NPCModuleCmd.ActorLookAtAction,
      PlayerModuleCmd.ActorLookAtAction
    },
    head_look_at = {
      "",
      "actor_id",
      NPCModuleCmd.ActorHeadLookAtAction,
      ""
    },
    turn_to = {
      "",
      "actor_id",
      NPCModuleCmd.ActorTurnToAction,
      ""
    },
    cancel_turn_to = {
      "",
      "actor_id",
      NPCModuleCmd.ActorCancelTurnToAction,
      ""
    },
    model_show_or_hide = {
      "",
      "actor_id",
      NPCModuleCmd.ActorModelShowHideAction,
      ""
    },
    battle_on_or_off = {
      "",
      "actor_id",
      NPCModuleCmd.ActorBattleOnOffAction,
      ""
    },
    set_npc_pos = {
      "",
      "actor_id",
      NPCModuleCmd.ActorSetNpcPos,
      ""
    },
    play_voice = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayVoice,
      ""
    },
    stop_voice = {
      "",
      "actor_id",
      NPCModuleCmd.ActorStopVoice,
      ""
    },
    show_pet_face_state = {
      "",
      "actor_id",
      NPCModuleCmd.ActorShowPetFaceStateAction,
      ""
    },
    world_attack = {
      "",
      "actor_id",
      NPCModuleCmd.ActorWorldAttack,
      ""
    },
    stop_world_attack = {
      "",
      "actor_id",
      NPCModuleCmd.ActorStopWorldAttack,
      ""
    },
    play_perception_effect = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayPerceptionEffect,
      ""
    },
    play_perception_hud = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayPerceptionHud,
      ""
    },
    npc_perceive_player = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPerceivePlayer,
      ""
    },
    ai_seq_id_notify = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ActorAiSeqIdNotify,
      ""
    },
    npc_trace = {
      "",
      self.AlwaysToFirst,
      BigMapModuleCmd.UpdateNpcTraceInfo,
      ""
    },
    play_skill = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlaySkill,
      ""
    },
    stop_skill = {
      "",
      "actor_id",
      NPCModuleCmd.ActorStopSkill,
      ""
    },
    server_move = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerMoveAction,
      ""
    },
    interrupt_server_move = {
      "",
      "actor_id",
      NPCModuleCmd.ActorInterruptServerMove,
      ""
    },
    server_fly = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerFly,
      ""
    },
    world_hidden = {
      "",
      "actor_id",
      NPCModuleCmd.ActorWorldHidden,
      ""
    },
    world_unhidden = {
      "",
      "actor_id",
      NPCModuleCmd.ActorWorldUnhidden,
      ""
    },
    server_attach = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerAttach,
      ""
    },
    cancel_server_attach = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerCancelAttach,
      ""
    },
    server_ai_jump = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerJump,
      ""
    },
    cancel_server_ai_jump = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerCancelJump,
      ""
    },
    stick_to = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerStickTo,
      ""
    },
    finish_stick_to = {
      "",
      "actor_id",
      NPCModuleCmd.ActorServerFinishStickTo,
      ""
    },
    ai_try_interact_npc = {
      "",
      "actor_id",
      NPCModuleCmd.ActorAiTryInteractNpc,
      ""
    },
    play_real_time_dialog = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayRealtimeDialog,
      ""
    },
    stop_real_time_dialog = {
      "",
      "actor_id",
      NPCModuleCmd.ActorStopRealtimeDialog,
      ""
    },
    collision_cancel_or_recover = {
      "",
      "actor_id",
      NPCModuleCmd.ActorCollisionCancelRecover,
      ""
    },
    anim_pause_or_resume = {
      "",
      "actor_id",
      NPCModuleCmd.ActorAnimPauseOrResume,
      ""
    },
    npc_pendant_info_change = {
      "",
      "npc_id",
      NPCModuleCmd.ActorPendantInfoChange,
      ""
    },
    battle_ai_status_changed = {
      "",
      "actor_id",
      NPCModuleCmd.BattleAiStatusChanged,
      ""
    },
    scene_ai_control_flags_changed = {
      "",
      "actor_id",
      NPCModuleCmd.BattleAiControlFlagsChanged,
      ""
    },
    stun = {
      "",
      "actor_id",
      NPCModuleCmd.StunServerNty,
      ""
    },
    play_chat_buble = {
      "",
      "actor_id",
      NPCModuleCmd.ActorPlayChatBubble,
      ""
    },
    inform_client_switch_ai = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.InformClientSwitchAi,
      ""
    },
    client_switch_to_server_ai = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ClientSwitchToServerAi,
      ""
    },
    catch_record_info_change = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.OnCatchRecordInfoChange,
      ""
    },
    habitat_neighbor_info_change = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.HabitatNeighborInfoChange,
      ""
    },
    all_habitat_neighbor_info = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.AllHabitatNeighborInfoChange,
      ""
    },
    mutual_perform_state_changed = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.OnAIMutualPerformStateChanged,
      ""
    },
    mfbt_debug = {
      "",
      "actor_id",
      NPCModuleCmd.ActorMfbtDebugInfo,
      ""
    },
    client_move = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.ActorMoveAction
    },
    mount = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.Mount
    },
    unmount = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.UnMount
    },
    cast_scene_skill = {
      "",
      "caster_id",
      "",
      PlayerModuleCmd.CastSceneSkill
    },
    visible_players = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.DebugVisibleZoneInfo
    },
    sync_player_status = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.SyncPlayerStatus
    },
    aura_info_change = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.AuraInfoChange
    },
    body_temp_notify = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.BodyTempChange
    },
    env_mask = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.EnvMask
    },
    throwed_pet_info = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.ThrownPetInfoChange
    },
    game_time_change = {
      "",
      self.AlwaysToFirst,
      EnvSystemModuleCmd.OnSyncTimeAction,
      ""
    },
    field_tag_change = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.FieldTagChange,
      ""
    },
    minigame = {
      "",
      self.AlwaysToFirst,
      MiniGameModuleCmd.OnMinigameNotify,
      ""
    },
    guide_npcs = {
      "",
      self.AlwaysToFirst,
      TaskModuleCmd.UpdateGuideTask,
      ""
    },
    client_event_resume = {
      "",
      self.AlwaysToFirst,
      FunctionBanModuleCmd.ClientEventResume,
      ""
    },
    unlock_sleeping_owl = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.UnlockSleepingOwl,
      ""
    },
    owl_refuge_info_change = {
      "",
      self.AlwaysToFirst,
      SleepingOwlModuleCmd.UpdateSleepOwlRefuge,
      ""
    },
    npc_distribution = {
      "",
      self.AlwaysToFirst,
      MarkerModuleCmd.UpdateNPCBeam,
      ""
    },
    friend_ride = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.FriendRideStateChange,
      ""
    },
    task_state_change_nty = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.TaskStateChangeNty
    },
    bond_find = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.IntimateBondFind,
      ""
    },
    pet_info_change = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.PetInfoChange,
      ""
    },
    dots_component_sync = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.DotsComponentSync,
      ""
    },
    pet_closeness_lv_upgrade = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.PetClosenessLvUpgrade,
      ""
    },
    fashion_change = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.PlayerFashionChange,
      ""
    },
    salon_change = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.PlayerSalonChange,
      ""
    },
    client_operation = {
      "",
      self.DispatchOperation,
      NPCModuleCmd.ActorClientOperation,
      PlayerModuleCmd.SyncPlayerOperation
    },
    game_time_sync = {
      "",
      self.AlwaysToFirst,
      MainUIModuleCmd.CmdMiniGameTimeSet,
      ""
    },
    name_change = {
      "",
      "actor_id",
      NPCModuleCmd.OnPetNameChange,
      PlayerModuleCmd.OnCmdAvatarNameChange
    },
    pet_interact_res_nty = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.UpdatePetInteractionResult,
      ""
    },
    combine_interact_info_change = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.UpdateCombineInteractInfo,
      ""
    },
    relate_npcs = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.UpdateRelatedNPCInfo,
      ""
    },
    buff_info_change = {
      "",
      "actor_id",
      NPCModuleCmd.WorldCombatBuffChange,
      PlayerModuleCmd.WorldCombatBuffChange
    },
    world_combat_enter = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatEnter,
      ""
    },
    world_combat_exit = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatExit,
      ""
    },
    world_combat_skill_cast = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatSkillCast,
      ""
    },
    world_combat_skill_spawn_npc = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatSkillSpawnNpc,
      ""
    },
    world_combat_skill_spawn_bullet = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatSkillSpawnBullet,
      ""
    },
    world_combat_skill_fire_bullet = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatSkillFireBullet,
      ""
    },
    world_combat_hit = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatSkillHit,
      ""
    },
    world_combat_text_prompts = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.ServerNotifyTips,
      ""
    },
    world_combat_phase_update = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatPhaseUpdate,
      ""
    },
    world_combat_begin = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatBegin,
      ""
    },
    world_combat_finish = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatFinish,
      ""
    },
    world_combat_extra_reward_update = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.ExtraRewardUpdate,
      ""
    },
    world_combat_dots_skill_cast = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillCast,
      ""
    },
    world_combat_dots_skill_end = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillEnd,
      ""
    },
    world_combat_dots_skill_crush = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillCrush,
      ""
    },
    world_combat_dots_skill_rotate = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillRotate,
      ""
    },
    world_combat_dots_skill_hit = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillHit,
      ""
    },
    world_combat_dots_skill_lookat = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillLookAt,
      ""
    },
    world_combat_dots_skill_crush_end = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillCrushEnd,
      ""
    },
    world_combat_dots_skill_missile_launch = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillMissileLaunch,
      ""
    },
    world_combat_dots_skill_missile_destroy = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillMissileDestroy,
      ""
    },
    world_combat_dots_skill_missile_stop_trace = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillMissileStopTrace,
      ""
    },
    world_combat_dots_skill_jump = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillJump,
      ""
    },
    world_combat_dots_skill_jump_end = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillJumpEnd,
      ""
    },
    world_combat_dots_skill_jump_cancel = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillJumpCancel,
      ""
    },
    world_combat_dots_skill_rcd = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillRcd,
      ""
    },
    world_combat_dots_skill_rcd_end = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillRcdEnd,
      ""
    },
    world_combat_dots_skill_show_hide = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsShowHideChange,
      ""
    },
    world_combat_dots_skill_pos_lerp_sync = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillPosLerpSync,
      ""
    },
    world_combat_dots_skill_anim_cancel = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillAnimCancel,
      ""
    },
    world_combat_dots_skill_select_pos = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.WorldCombatDotsSkillSelectPos,
      ""
    },
    scenesvr_err_echo = {
      "",
      self.AlwaysToFirst,
      WorldCombatModuleCmd.ShowServerError,
      ""
    },
    actor_num = {
      "",
      self.AlwaysToFirst,
      "DebugModuleCmd.ShowActorNum",
      ""
    },
    world_map_infos_change = {
      "",
      self.AlwaysToFirst,
      BigMapModuleCmd.UpdateWorldMapDatas,
      ""
    },
    magic_create_npc_change = {
      "",
      self.AlwaysToFirst,
      BigMapModuleCmd.UpdateMagicCreateNpcInfo,
      ""
    },
    catch_guarantee_change = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.UpdateCatchGuaranteeRateInfo,
      ""
    },
    loop_action = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ChangeLoopAction,
      ""
    },
    player_match = {
      "",
      self.AlwaysToFirst,
      LegendaryBattleModuleCmd.CancelMatchNotify,
      ""
    },
    npc_visual_info = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ShowHideNPC,
      ""
    },
    battle_buff_info_change = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ChangeBattleBuff,
      ""
    },
    card_label_change = {
      "",
      self.AlwaysToFirst,
      FriendModuleCmd.ChangeCardLabel,
      ""
    },
    card_skin_change = {
      "",
      self.AlwaysToFirst,
      FriendModuleCmd.ChangeCardSkin,
      ""
    },
    card_icon_change = {
      "",
      self.AlwaysToFirst,
      FriendModuleCmd.ChangeCardIcon,
      ""
    },
    card_music_change = {
      "",
      self.AlwaysToFirst,
      FriendModuleCmd.ChangeCardMusic,
      ""
    },
    follow_info_changed_nty = {
      "",
      self.AlwaysToFirst,
      MainUIModuleCmd.FollowUISync,
      ""
    },
    position_invalid = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.PosInvalidOutOfStuck,
      ""
    },
    owl_sanctuary_detected = {
      "",
      self.AlwaysToFirst,
      SleepingOwlModuleCmd.OnReceiveSanctuaryDetected,
      ""
    },
    owl_sanctuary_fruit_info_update = {
      "",
      self.AlwaysToFirst,
      SleepingOwlModuleCmd.OnReceiveUpdateOwlSanctuaryFruit,
      ""
    },
    home_plant_change_notify = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantChangeNotify,
      ""
    },
    home_plant_plant_crop = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantPlantCrop,
      ""
    },
    home_plant_role_water = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantRoleWater,
      ""
    },
    home_plant_role_manure = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantRoleManure,
      ""
    },
    home_plant_owner_pick = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantOwnerPick,
      ""
    },
    home_plant_visitor_pick = {
      "",
      self.AlwaysToFirst,
      FarmModuleCmd.OnHomePlantVisitorPick,
      ""
    },
    home_basic_info_change_notify = {
      "",
      self.AlwaysToFirst,
      HomeModuleCmd.OnHomeBasicInfoChangeNotify,
      ""
    },
    home_pet_info_change_notify = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.OnHomePetSvrInfoChange,
      ""
    },
    home_interact_notify = {
      "",
      self.AlwaysToFirst,
      HomeModuleCmd.OnInteractWithHomePet,
      ""
    },
    home_basic_visitor_enter_home = {
      "",
      self.AlwaysToFirst,
      HomeModuleCmd.OnHomeBasicVisitorEnterHomeNotify,
      ""
    },
    home_basic_visitor_leaving_home = {
      "",
      self.AlwaysToFirst,
      HomeModuleCmd.OnHomeBasicVisitorLeavingHomeNotify,
      ""
    },
    actor_plant_data_update = {
      "",
      self.AlwaysToFirst,
      HomeModuleCmd.OnActorPlantDataUpdate,
      ""
    },
    air_wall_change = {
      "",
      self.AlwaysToFirst,
      AirWallModuleCmd.ServerAirWallChange,
      ""
    },
    throw_catch_notify = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.ThrowCatchNotify,
      ""
    },
    travel_together_sync = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.TravelTogetherSync
    },
    actor_keep_model = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.ActorKeepModel,
      ""
    },
    inner_battle = {
      "",
      self.AlwaysToFirst,
      BattleSpectatorModuleCmd.OnInnerBattleNotify,
      ""
    },
    inner_battle_shield_broken = {
      "",
      self.AlwaysToFirst,
      BattleSpectatorModuleCmd.OnInnerBattleShieldBroken,
      ""
    },
    inner_battle_change_pet = {
      "",
      self.AlwaysToFirst,
      BattleSpectatorModuleCmd.OnInnerBattleChangePet,
      ""
    },
    idle_skill = {
      "",
      "actor_id",
      "",
      PlayerModuleCmd.PlayIdleSkill
    },
    pet_voice = {
      "",
      "actor_id",
      NPCModuleCmd.OnPetResponseVoice,
      PlayerModuleCmd.OnPetResponseVoice
    },
    visible_circle = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.OnVisibleCircleChanged,
      ""
    },
    story_flags = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.OnHomeOwnerStoryFlagChange,
      ""
    },
    video_record = {
      "",
      self.AlwaysToFirst,
      MagicReplayModuleCmd.OnVideoRecordNotify,
      ""
    },
    camera_flash = {
      "",
      self.AlwaysToFirst,
      TakePhotosModuleCmd.OnSyncPhotoToken,
      ""
    },
    llm_pets_query_pets = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.OnLLMPETSQueryPets,
      ""
    },
    llm_pets_behavior_notify = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.OnLLMPETSBehaviorNotify,
      ""
    },
    llm_debug = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.OnLLMPETSDebug,
      ""
    },
    npc_size_scale_change = {
      "",
      "npc_id",
      NPCModuleCmd.NpcSizeScaleChange,
      ""
    },
    roleplay_hold_info_chg_ntf = {
      "",
      self.AlwaysToFirst,
      RolePlayModuleCmd.OnRolePlayHoldInfoChange,
      ""
    },
    option_b_or_w_list_uins_chg_ntf = {
      "",
      self.AlwaysToFirst,
      NPCModuleCmd.OnOptionBlacklistAndWhitelist,
      ""
    },
    player_tags_change = {
      "",
      self.AlwaysToFirst,
      MainUIModuleCmd.ChangePlayerTags,
      ""
    },
    abnormal_status_change_ntf = {
      "",
      self.AlwaysToFirst,
      PlayerModuleCmd.OnAbnormalStatusChange
    },
    camera_skin_change = {
      "",
      self.AlwaysToFirst,
      TakePhotosModuleCmd.OnSyncCameraTextureChanged
    },
    bonus_catch_limit_tips = {
      "",
      self.AlwaysToFirst,
      SeasonIntegrationModuleCmd.OnBonusCatchLimitTips,
      ""
    }
  }
  self.bNoLoadingTeleport = false
  self.bAllowCliCachePkg = false
  self.bWaitingForAckEnd = false
  self.CurTeleportNotify = nil
  self:AddListener()
  self.sceneDataModel:Init()
  self.blockingArea:Init()
  local allPikaShopSceneResIdConfig = _G.DataConfigManager:GetMapGlobalConfig("all_tailor_scene")
  if allPikaShopSceneResIdConfig then
    self.AllPikaShopSceneResId = allPikaShopSceneResIdConfig.numList
  end
end

function SceneModule:OnDestruct()
  self.blockingArea:UnInit()
  self.sceneDataModel:UnInit()
  self:UnRegisterAllCmd()
  self:RemoveListener()
  self.sceneDataModel = nil
  self.poolManager = nil
end

function SceneModule:OnActive()
end

function SceneModule:OnDeactive()
end

function SceneModule:OnLogin(isRelogin)
  self:Log("SceneModule OnLogin", isRelogin)
  if isRelogin then
    self:RequestEnterScene(self.requestEnterSceneAsyncData)
  end
end

function SceneModule:RequestEnterScene(asyncData)
  self:Log("SceneModule:RequestEnterScene")
  self.requestEnterSceneAsyncData = asyncData
  local enterReq = ProtoMessage:newZoneEnterSceneReq()
  if _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_ENTER_SCENE_REQ, enterReq, self, self.OnEnterRsp, false) then
    local isReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnReqEnterScene, isReconnecting)
  end
  return
end

function SceneModule:OnPreTeleportNotify(notify)
  Log.DebugFormat("SceneModule:OnPreTeleportNotify[PlayerAOI][NpcAOI] From(cfg_id:%d, inst_id:%d, res_cfg_id:%d)->To(cfg_id:%d, inst_id:%d, res_cfg_id:%d), is_no_loading_teleport(%d)", self.mapID, self.mapInstId, notify.from_scene_res_cfg_id, notify.to_scene_cfg_id, notify.to_scene_inst_id, notify.to_scene_res_cfg_id, notify.is_no_loading_teleport and 1 or 0)
  self.CurTeleportStub = notify.teleport_stub
  self.bNoLoadingTeleport = notify.is_no_loading_teleport
  self.bAllowCliCachePkg = notify.allow_cli_cache_pkg
  if self.bNoLoadingTeleport then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnPreTeleportNotify, true, false)
    _G.NRCNetworkManager:FlushSendMessage(_G.ZoneServer.connectID)
    local req = ProtoMessage:newZoneScenePreTeleportNotifyAck()
    req.teleport_stub = self.CurTeleportStub
    local ret = _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY_ACK, req, false, true)
    if ret then
      _G.ZoneServer:LockUpstream(true, true)
      self:Log("SceneModule:OnPreTeleportNotify[PlayerAOI][NpcAOI] lock upstream for switching zone!")
      if not self.bAllowCliCachePkg then
        _G.ZoneServer:SetOnlineState(OnlineState.SwitchingCell)
      end
    end
    return
  end
  if self.CurTeleportStub ~= nil then
    local req = ProtoMessage:newZoneScenePreTeleportNotifyAck()
    req.teleport_stub = self.CurTeleportStub
    local isSame = false
    if self.mapID == notify.to_scene_cfg_id and notify.from_scene_res_cfg_id == notify.to_scene_res_cfg_id then
      isSame = true
    end
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnPreTeleportNotify, isSame, false)
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetBeforeLockUpstream, isSame, false)
    _G.NRCNetworkManager:FlushSendMessage(_G.ZoneServer.connectID)
    local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      localPlayer.serverData.base.platform_actor_id = 0
      localPlayer:ForceSendMoveReq(true)
    end
    local ret = _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY_ACK, req, false, true)
    if ret then
      _G.ZoneServer:LockUpstream(true, true)
      self:Log("SceneModule:OnPreTeleportNotify[PlayerAOI][NpcAOI] lock upstream after send ack.")
      _G.ZoneServer:SetOnlineState(OnlineState.SwitchingCell)
      self.triggerEnterScene = true
    end
  end
end

function SceneModule:OnCancelPreTeleportNotify(notify)
  self:Log("SceneModule:OnCancelPreTeleportNotify[PlayerAOI][NpcAOI]")
  local teleport_stub = notify.teleport_stub
  if teleport_stub ~= self.CurTeleportStub then
    Log.Error("SceneModule:OnCancelPreTeleportNotify[PlayerAOI][NpcAOI] teleport stub not match, cur stub=", self.CurTeleportStub, "notify stub=", teleport_stub)
  end
  _G.ZoneServer:LockUpstream(false)
  self.CurTeleportStub = nil
  _G.ZoneServer:SetOnlineState(OnlineState.EnteredCell)
  self:Log("SceneModule:OnCancelPreTeleportNotify unlock upstream")
  if notify.err_code and type(notify.err_code) == "number" and notify.err_code > 0 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText[string.format("Error_Code_%d", notify.err_code)])
  end
end

function SceneModule:OnTeleportNotify(notify)
  self:Log("SceneModule:OnTeleportNotify[PlayerAOI][NpcAOI], to_scene_cfg_id=", notify.to_scene_cfg_id)
  self.CurTeleportNotify = notify
  SceneUtils.FixActorPoint(notify.self_info)
  self.TeleportLoadingCustomData = {
    TeleportHomeName = notify.to_scene_res_cfg_id == 30001 and notify.home_name,
    TeleportFarmName = notify.to_scene_res_cfg_id == 30002 and notify.home_name
  }
  _G.NRCModeManager:DoCmd(PlayerModuleCmd.AddSelfPlayer, notify.self_info.avatar)
  _G.NRCModuleManager:DoCmd(AreaAndZoneModuleCmd.OnTeleportClearAreaInfo)
  if self.bNoLoadingTeleport then
    local localPlayer = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer then
      localPlayer:UpdateData(notify.self_info.avatar, false)
    end
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnTeleportNotify, notify, true)
    if notify.self_info and notify.self_info.avatar and notify.self_info.avatar.world_map_info and notify.self_info.avatar.world_map_info.send_in_batches and notify.self_info.avatar.world_map_info.total_entry_batches > 0 then
      local world_map_info = notify.self_info.avatar.world_map_info
      Log.Debug("SceneModule:OnTeleportNotify[PlayerAOI][NpcAOI] for switching zone, waiting for batched world_map_info!", world_map_info.send_in_batches, world_map_info.total_entry_batches)
    else
      Log.Debug("SceneModule:OnTeleportNotify[PlayerAOI][NpcAOI] for switching zone, no batch world_map_info!")
      local clientReadyMsg = ProtoMessage:newZoneSceneClientEnterSceneFinishNty()
      if notify.teleport_reason and (0 == notify.teleport_reason or 3 == notify.teleport_reason) then
        clientReadyMsg.feature_data = _G.NRCSDKManager:GetLightFeaturePacket()
      end
      _G.NRCNetworkManager:FlushRecvMessage(_G.ZoneServer.connectID)
      _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY, clientReadyMsg)
    end
    if not self.bAllowCliCachePkg then
      self.teleport_to_pt = notify.to_pt
    end
    return
  end
  self.triggerEnterScene = true
  local AvatarInfo = notify.self_info.avatar
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartX %d", AvatarInfo.base.pt.pos.x))
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartY %d", AvatarInfo.base.pt.pos.y))
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartZ %d", AvatarInfo.base.pt.pos.z + 90))
  if not self.bNoLoadingTeleport and LoadingUIModuleCmd then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 0.4, nil, nil, notify.teleport_reason, notify.teleport_id, self.mapResId, notify.to_scene_res_cfg_id, false, notify.teleport_rule_id)
    local AreaQueryManager = UE4.UAreaQueryManager.Get(_G.UE4Helper.GetCurrentWorld())
    if AreaQueryManager then
      AreaQueryManager:ResetCurrentSceneResId()
    end
  end
  _G.NRCEventCenter:DispatchEvent(SceneEvent.OnTeleportNotify, notify, false)
  local bIsSkip = false
  if TaskModuleCmd then
    local TrackTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.GetTrackTask)
    if TrackTask then
      local SkipTask = _G.NRCModuleManager:DoCmd(TaskModuleCmd.IsSkipTask, TrackTask.Config.id)
      if SkipTask then
        for Index, Cond in ipairs(TrackTask.Config.task_condition) do
          if Cond.type == ProtoEnum.TaskKeyType.TKT_REACH_POINT then
            local PosCheckData = Cond.data1
            if PosCheckData[1] and PosCheckData[1] == notify.to_scene_cfg_id then
              bIsSkip = true
            end
          end
        end
      end
    end
  end
  if bIsSkip then
    Log.Debug("SceneModule:OnTeleportNotify[PlayerAOI][NpcAOI] bIsSkip")
    self:EnterMap(notify)
  else
    _G.DelayManager:DelaySeconds(0.3, function()
      self:EnterMap(notify)
    end)
  end
end

function SceneModule:OnZoneSceneWorldMapEntryInfoIncrNty(notify)
  self:Log("SceneModule:OnZoneSceneWorldMapEntryInfoIncrNty [PlayerAOI][NpcAOI]", notify.batch_id, notify.total_batch, #notify.entries.entry_infos)
  if 0 == notify.total_batch then
    return
  end
  if not self.bNoLoadingTeleport then
    Log.Error("SceneModule:OnZoneSceneWorldMapEntryInfoIncrNty [PlayerAOI][NpcAOI] bNoLoadingTeleport is false!")
    return
  end
  local selfPlayerInfo = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetSelfPlayerInfo)
  if selfPlayerInfo and selfPlayerInfo.world_map_info and selfPlayerInfo.world_map_info.entries then
    if not selfPlayerInfo.world_map_info.entries.entry_infos then
      selfPlayerInfo.world_map_info.entries.entry_infos = {}
    end
    local selfEntryInfos = selfPlayerInfo.world_map_info.entries.entry_infos
    table.move(notify.entries.entry_infos, 1, #notify.entries.entry_infos, #selfEntryInfos + 1, selfEntryInfos)
  else
    Log.Error("SceneModule:OnZoneSceneWorldMapEntryInfoIncrNty [PlayerAOI][NpcAOI] selfPlayerInfo is nil!")
  end
  if notify.batch_id == notify.total_batch - 1 then
    self:Log("SceneModule:OnZoneSceneWorldMapEntryInfoIncrNty [PlayerAOI][NpcAOI] over, send ClientEnterSceneFinishNty!", notify.batch_id, notify.total_batch)
    local clientReadyMsg = ProtoMessage:newZoneSceneClientEnterSceneFinishNty()
    _G.NRCNetworkManager:FlushRecvMessage(_G.ZoneServer.connectID)
    _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY, clientReadyMsg)
  end
end

function SceneModule:OnEnterSceneFinishNtyAck(notify)
  self:Log("SceneModule:OnEnterSceneFinishNtyAck [PlayerAOI][NpcAOI], self.bNoLoadingTeleport = ", self.bNoLoadingTeleport, ",enabled_no_loading_teleport = ", notify.enabled_no_loading_teleport, ",add_or_update_other_actors_total_batch = ", notify.add_or_update_other_actors_total_batch)
  if self.bNoLoadingTeleport then
    self:ProcessClientEnterSceneFinishNtyAck(notify)
    local player = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not self.bAllowCliCachePkg and self.teleport_to_pt then
      local toPos = self.teleport_to_pt.pos
      local playerPos = SceneUtils.ServerPos2PlayerPos(toPos)
      local playerRot = UE4.FRotator(0, (self.teleport_to_pt.dir.z or 0.0) / 10.0, 0)
      if player then
        if not player:IsTogetherMove2P() then
          player:SetActorLocation(playerPos)
          player:SetActorRotation(playerRot)
        end
        local bForMiniGame = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsOpenCamera) or _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsInNightmare)
        if not bForMiniGame then
          local Controller = player:GetUEController()
          if Controller then
            Controller:ReleaseRocoCamera(0, UE4.EViewTargetBlendFunction.VTBlend_EaseOut, 0, true)
            Controller:ResetCtrlRotation(10000.0)
          end
        end
      end
    end
    if not notify.add_or_update_other_actors_total_batch or 0 == notify.add_or_update_other_actors_total_batch then
      _G.ZoneServer:LockUpstream(false)
      _G.ZoneServer:SetOnlineState(OnlineState.EnteredCell)
      self.bNoLoadingTeleport = false
      self.bAllowCliCachePkg = false
      self.CurTeleportStub = nil
    end
    if player.InviteComponent then
      player.InviteComponent:OnNoLoadingTeleport()
    end
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnEnterSceneFinishNtyAck, notify, false, false, self.preMapId, self.mapID)
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnEnterSceneFinishNtyAckEnd, notify, false, false, self.preMapId, self.mapID)
    if player then
      player:ForceSendMoveReq(false, player.serverData.base.platform_actor_id)
    end
    return
  end
  self.triggerEnterScene = false
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and notify.adjust_data then
    Log.Debug("[SceneLocalPlayer]OnEnterSceneFinishNtyAck, [LandOnActor] adjust_data.platform_actor_id = ", notify.adjust_data.platform_actor_id)
    localPlayer.serverData.base.platform_actor_id = notify.adjust_data.platform_actor_id or 0
  end
  self:ProcessClientEnterSceneFinishNtyAck(notify)
  _G.ZoneServer:LockUpstream(false)
  self.CurTeleportStub = nil
  local isReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
  local curOnlineState = _G.ZoneServer:GetOnlineState()
  local isEnteringCell = curOnlineState == OnlineState.EnteringCell
  _G.ZoneServer:SetOnlineState(OnlineState.EnteredCell)
  _G.NRCEventCenter:DispatchEvent(SceneEvent.OnEnterSceneFinishNtyAck, notify, isReconnecting, isEnteringCell, self.preMapId, self.mapID)
  if not _G.NRCEnv:IsLocalMode() then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.BigWorldPrepared)
  end
  _G.ZoneServer:Pause("WaitingForAckEnd")
  self.bWaitingForAckEnd = true
  self.WaitingForAckEndParam = {}
  self.WaitingForAckEndParam.notify = notify
  self.WaitingForAckEndParam.isReconnecting = isReconnecting
  self.WaitingForAckEndParam.isEnteringCell = isEnteringCell
  self.WaitingForAckEndParam.preMapId = self.preMapId
  self.WaitingForAckEndParam.mapID = self.mapID
end

function SceneModule:ProcessClientEnterSceneFinishNtyAck(notify)
  Log.Debug("SceneModule:ProcessClientEnterSceneFinishNtyAck [PlayerAOI][NpcAOI] enabled_no_loading_teleport=", notify.enabled_no_loading_teleport)
  _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.ClearInReconnect)
  if notify.enabled_no_loading_teleport then
    if notify.deleted_other_actor_ids and #notify.deleted_other_actor_ids > 0 then
      for _, v in ipairs(notify.deleted_other_actor_ids) do
        if self:CheckIsPlayer(v) then
          _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.ActorLeaveAction, v, false)
        else
          _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorLeaveAction, v, false)
        end
      end
    end
    if notify.add_or_update_other_actors_total_batch and 0 == notify.add_or_update_other_actors_total_batch then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorEnterFinishAction)
    end
  else
    local togetherPlayerUin
    local curOnlineState = _G.ZoneServer:GetOnlineState()
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and curOnlineState == OnlineState.SwitchingCell and localPlayer.statusComponent:IsInTogetherTeleport() then
      togetherPlayerUin = localPlayer.statusComponent:GetTogetherPlayerUin()
      if togetherPlayerUin and 0 ~= togetherPlayerUin then
        Log.Debug("[SceneModule]Is In [TogetherTeleport], togetherPlayerUin = ", togetherPlayerUin)
        _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.SetFastLoadingUIHeadLineText, LuaText.teleport_wait_others)
      end
    end
    if notify.other_actors then
      for _, v in ipairs(notify.other_actors) do
        SceneUtils.FixActorPoint(v)
      end
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ClearActorInReconnect, notify.other_actors)
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SortActors, notify.other_actors)
      for _, v in ipairs(notify.other_actors) do
        local actorInfo = v
        if v.actor_detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal then
          _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.ActorEnterAction, actorInfo)
          if togetherPlayerUin and 0 ~= togetherPlayerUin and togetherPlayerUin == actorInfo.avatar.base.logic_id then
            _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.SetFastLoadingUIHeadLineText, LuaText.teleport_partner_done)
          end
        else
          _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorEnterAction, actorInfo, nil, nil, true)
        end
      end
    else
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ClearActorInReconnect, notify.other_actors)
    end
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorEnterFinishAction)
  end
end

function SceneModule:OnZoneSceneClientInitAOIIncrUpdateNty(notify)
  self:Log("SceneModule:OnZoneSceneClientInitAOIIncrUpdateNty [PlayerAOI][NpcAOI]", notify.total_batch, notify.batch_id, #notify.other_actors)
  if not self.bNoLoadingTeleport then
    Log.Error("SceneModule:OnZoneSceneClientInitAOIIncrUpdateNty [PlayerAOI][NpcAOI] bNoLoadingTeleport is false!")
    return
  end
  if notify.other_actors then
    for _, v in ipairs(notify.other_actors) do
      SceneUtils.FixActorPoint(v)
      local actorInfo = v
      if v.actor_detail_type == ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal then
        _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.ActorEnterAction, actorInfo)
      else
        _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorEnterAction, actorInfo, nil, nil, true)
      end
    end
  end
  if notify.batch_id == notify.total_batch - 1 then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ActorEnterFinishAction)
    _G.ZoneServer:LockUpstream(false)
    _G.ZoneServer:SetOnlineState(OnlineState.EnteredCell)
    self.bNoLoadingTeleport = false
    self.bAllowCliCachePkg = false
    self.CurTeleportStub = nil
  end
end

function SceneModule:OnEnterSceneFinishNtyAckEnd()
  if _G.GlobalConfig.DisableNPCModule then
    _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.CloseLoadingUI, 0)
  elseif self.bWaitingForAckEnd and self.WaitingForAckEndParam then
    self:Log("[ZoneServer][NetMsg] SceneModule:OnEnterSceneFinishNtyAckEnd [PlayerAOI][NpcAOI]")
    _G.DelayManager:DelaySeconds(2, function()
      _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.SetFastLoadingUIHeadLineText, nil)
    end)
    _G.NRCEventCenter:DispatchEvent(SceneEvent.OnEnterSceneFinishNtyAckEnd, self.WaitingForAckEndParam.notify, self.WaitingForAckEndParam.isReconnecting, self.WaitingForAckEndParam.isEnteringCell, self.WaitingForAckEndParam.preMapId, self.WaitingForAckEndParam.mapID)
    _G.NRCModuleManager:DoCmd(_G.LoadingUIModuleCmd.CloseLoadingUI, 0)
  else
    Log.Error("[ZoneServer][NetMsg] SceneModule:OnEnterSceneFinishNtyAckEnd do nothing [PlayerAOI][NpcAOI], self.bWaitingForAckEnd", self.bWaitingForAckEnd, ", self.WaitingForAckEndParam", self.WaitingForAckEndParam)
  end
  self.bWaitingForAckEnd = false
  self.WaitingForAckEndParam = nil
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and UE4.UObject.IsValid(localPlayer.viewObj) then
    localPlayer:ForceSendMoveReq(false, localPlayer.serverData.base.platform_actor_id)
    localPlayer:SetCharacterMovementTickEnable(self, true)
    Log.Debug("[ZoneServer][NetMsg] SceneModule:OnEnterSceneFinishNtyAckEnd localPlayer.viewObj.CharacterMovement:SetComponentTickEnabled(true)!")
  end
end

function SceneModule:CheckSceneFullyEntered()
  local State = _G.ZoneServer:GetOnlineState()
  if State ~= OnlineState.EnteredCell then
    return false
  end
  if self.bWaitingForAckEnd then
    return false
  end
  return true
end

function SceneModule:OnEnterRsp(rsp)
  self:Log("SceneModule:OnEnterRsp ", rsp.ret_info.ret_code)
  if 0 == rsp.ret_info.ret_code then
    local isReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.NetBeforeLockUpstream, false, isReconnecting)
    _G.ZoneServer:LockUpstream(true, true)
    self:Log("SceneModule:OnEnterRsp lock upstream.")
    _G.ZoneServer:SetOnlineState(OnlineState.EnteringCell)
    _G.DataModelMgr.PlayerDataModel.playerInfo.common_info.online_visit_owner = rsp.online_visiting_owner
    _G.DataModelMgr.PlayerDataModel:RefreshPlayerOnlineVisitState()
  else
    _G.ZoneServer:SetOnlineState(OnlineState.Logouted)
    self:Log("SceneModule:OnEnterRsp ignore, waiting for KickOut, ret_code=", rsp.ret_info.ret_code)
  end
end

function SceneModule:ReconnectRoom(isOk)
  local function LoginRspFunc(_caller, rsp)
    local Func_LoginModule = _G.NRCModuleManager:GetModule("OnlineModule")
    
    if Func_LoginModule then
      Func_LoginModule:OnLoginRsp(rsp)
    end
  end
  
  local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
  local data = OnlineModule.data
  local loginReq = ProtoMessage:newZoneLoginReq()
  loginReq.openid = _G.GameSetting.LastLogin
  loginReq.plat_info = data.plat_info
  loginReq.cli_info = data.cli_info
  loginReq.is_login = OnlineModule.isLoginFromUI
  loginReq.leaving_online_visiting = not isOk
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_LOGIN_REQ, loginReq, self, LoginRspFunc, true)
end

function SceneModule:ReturnToLoginMode()
  self:Log("ReturnToLoginMode")
  NRCModeManager:ActiveMode("LoginMode")
end

function SceneModule:AddListener()
  self:Log("Regist OnMapLoaded Event")
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY, self.OnSceneActionNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY, self.OnPreTeleportNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CANCEL_PRE_TELEPORT_NOTIFY, self.OnCancelPreTeleportNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TELEPORT_NOTIFY, self.OnTeleportNotify)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK, self.OnEnterSceneFinishNtyAck)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_ENTRY_INFO_INCR_NTY, self.OnZoneSceneWorldMapEntryInfoIncrNty)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_INIT_AOI_INCR_UPDATE_NTY, self.OnZoneSceneClientInitAOIIncrUpdateNty)
  ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_BATCH_NOTIFY, self.OnZoneScenePlayActsBatchNotify)
  NRCEventCenter:RegisterEvent("OnMapLoaded", self, NRCGlobalEvent.PostLoadMapWithWorld, self.OnPostLoadMapWithWorld)
  _G.NRCEventCenter:RegisterEvent("SceneModule", self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
end

function SceneModule:RemoveListener()
  NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.PostLoadMapWithWorld, self.OnPostLoadMapWithWorld)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_NOTIFY, self.OnSceneActionNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PRE_TELEPORT_NOTIFY, self.OnPreTeleportNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CANCEL_PRE_TELEPORT_NOTIFY, self.OnCancelPreTeleportNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_TELEPORT_NOTIFY, self.OnTeleportNotify)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY_ACK, self.OnEnterSceneFinishNtyAck)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_MAP_ENTRY_INFO_INCR_NTY, self.OnZoneSceneWorldMapEntryInfoIncrNty)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_INIT_AOI_INCR_UPDATE_NTY, self.OnZoneSceneClientInitAOIIncrUpdateNty)
  ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PLAY_ACTS_BATCH_NOTIFY, self.OnZoneScenePlayActsBatchNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_DISCONNECT, self.OnDisconnect)
end

function SceneModule:OnDisconnect()
  self.bNoLoadingTeleport = false
  self.bAllowCliCachePkg = false
  self.bWaitingForAckEnd = false
  self.CurTeleportNotify = nil
end

function SceneModule:GetActionCacheQueueByName(Name)
  local NotifyCache = self.ActionCaches[Name]
  if not NotifyCache then
    NotifyCache = {}
    self.ActionCaches[Name] = NotifyCache
  end
  return NotifyCache
end

function SceneModule:OnZoneScenePlayActsBatchNotify(notify)
  if notify and notify.acts then
    if #notify.acts > 0 then
      Log.Debug("[ZoneServer][NetMsg][SpaceActionNotify] OnZoneScenePlayActsBatchNotify #notify.acts=", #notify.acts, "timestamp=", notify.timestamp or "nil")
      for i = 1, #notify.acts do
        local act = notify.acts[i]
        self:OnSceneActionNotify(act)
      end
    else
      Log.Error("[ZoneServer][NetMsg][SpaceActionNotify] OnZoneScenePlayActsBatchNotify #notify.acts <= 0 or nil", notify.timestamp or "nil")
    end
  end
end

function SceneModule:OnSceneActionNotify(notify)
  local Actions = notify.acts
  if not Actions then
    return
  end
  if 0 == #Actions then
    return
  end
  local Tag = notify.act_tags
  if Tag then
    local Name, Content = next(Tag, nil)
    if nil ~= Name and nil ~= Content then
      if "battle_tag" == Name and not _G.BattleManager.isInBattle then
        Log.Error("[ZoneServer][NetMsg][SpaceActionNotify][SpaceActTags]OnSceneActionNotify \230\156\137\230\136\152\230\150\151tag\228\189\134\230\152\175\228\184\141\229\156\168\230\136\152\230\150\151\228\184\173..")
      else
        local NotifyCache = self:GetActionCacheQueueByName(Name)
        notify.receiveTime = os.msTime()
        table.insert(NotifyCache, notify)
        if not _G.RocoEnv.IS_SHIPPING then
          local actName, _ = next(Actions[1], nil)
          Log.Debug("[ZoneServer][NetMsg][SpaceActionNotify][SpaceActTags]OnSceneActionNotify cached,", Name, actName)
        end
        return
      end
    end
  end
  self:ProcessSceneActions(notify.acts, notify.act_tags, notify.space_base_data)
end

function SceneModule:ProcessSceneActions(Actions, Tag, BaseData)
  if not Actions then
    return
  end
  if 0 == #Actions then
    return
  end
  for _, Action in ipairs(Actions) do
    local Key, Value = next(Action)
    if not Key or not Value then
    else
      local Instruction = self.ProtoKeyFunctionMap[Key]
      if not Instruction then
        Log.Error("[ZoneServer][NetMsg][SpaceActionNotify]Cannot find ProtoKeyFunction for", Key)
        goto lbl_115
      else
      end
      local ArrayKey = Instruction[1]
      local ItemKey = Instruction[2]
      local ItemFunction = type(ItemKey) == "function" and ItemKey
      if string.IsNilOrEmpty(ArrayKey) then
        if ItemFunction then
          self:DispatchActionItem(Instruction, ItemFunction(self, Value), Value, Tag, BaseData)
        else
          self:DispatchActionItem(Instruction, self:CheckIsNpc(Value[ItemKey]), Value, Tag, BaseData)
        end
      else
        local Array = Value[ArrayKey]
        if not Array then
        elseif 0 == #Array then
        else
          for _, ArrayItem in ipairs(Array) do
            local IsNPC
            if ItemFunction then
              IsNPC = ItemFunction(self, ArrayItem)
            elseif "" == ItemKey then
              IsNPC = self:CheckIsNpc(ArrayItem)
            else
              IsNPC = self:CheckIsNpc(ArrayItem[ItemKey])
            end
            if nil ~= IsNPC then
              self:DispatchActionItem(Instruction, IsNPC, ArrayItem, Tag, BaseData)
            end
          end
        end
      end
    end
    ::lbl_115::
  end
end

function SceneModule:DispatchActionItem(Instruction, ToNPC, ArrayItem, Tag, BaseData)
  local Cmd = ToNPC and Instruction[3] or Instruction[4]
  if string.IsNilOrEmpty(Cmd) then
    return
  end
  _G.NRCModeManager:DoCmd(Cmd, ArrayItem, Tag, BaseData)
end

function SceneModule:ConsumeCachedNotify(Name, Owner, ValidFunc, ...)
  if string.IsNilOrEmpty(Name) then
    Log.Error("not a valid name", Name)
    return
  end
  if not Owner or not ValidFunc then
    Log.Error("[ZoneServer][NetMsg]SceneModule:ConsumeCache You need to supply an Owner and ValidFunc")
    return
  end
  local Caches = self.ActionCaches[Name]
  if not Caches or 0 == #Caches then
    return
  end
  local ProcessQueue = self.TempCacheProcessArray
  for i = #Caches, 1, -1 do
    if ValidFunc(Owner, Caches[i], ...) then
      local Notify = table.remove(Caches, i)
      table.insert(ProcessQueue, Notify)
    end
  end
  if 0 == #ProcessQueue then
    return
  end
  for i = #ProcessQueue, 1, -1 do
    if not _G.RocoEnv.IS_SHIPPING then
      local actName, _ = next(ProcessQueue[i], nil)
      Log.Debug("[ZoneServer][NetMsg][SpaceActionNotify][SpaceActTags]ConsumeCachedNotify", Name, actName)
    end
    self:ProcessSceneActions(ProcessQueue[i].acts, ProcessQueue[i].act_tags, ProcessQueue[i].space_base_data)
  end
  table.clear(ProcessQueue)
end

function SceneModule:ConsumeCachedActorTag(ActorID)
  self:ConsumeCachedNotify("actor_tag", self, self.ProcessCachedActorTag, ActorID)
end

function SceneModule:ProcessCachedActorTag(Notify, ActorID)
  if not Notify then
    return false
  end
  local Tag = Notify.act_tags
  if not Tag then
    return false
  end
  if not Tag.actor_tag then
    return false
  end
  return Tag.actor_tag.actor_id == ActorID
end

function SceneModule:ConsumeCachedBattleTag(Tag)
  self:ConsumeCachedNotify("battle_tag", self, self.ProcessCachedBattleTag, Tag)
end

function SceneModule:ProcessCachedBattleTag(Notify, GivenTag)
  if not Notify then
    return false
  end
  if not GivenTag then
    return false
  end
  local NotifyTag = Notify.act_tags and Notify.act_tags.battle_tag
  if not NotifyTag then
    return false
  end
  if GivenTag.battle_id and GivenTag.battle_id ~= NotifyTag.battle_id then
    return false
  end
  if GivenTag.round and GivenTag.round ~= NotifyTag.round then
    return false
  end
  if GivenTag.group_id and GivenTag.group_id ~= NotifyTag.group_id then
    return false
  end
  if GivenTag.cast_moment and GivenTag.cast_moment ~= NotifyTag.cast_moment then
    return false
  end
  for _, act in ipairs(Notify.acts) do
    if act.npc_guide_change ~= nil then
      return false
    end
  end
  return true
end

function SceneModule:ConsumeCachedBattleTagForNpcGuideChange(Tag)
  self:ConsumeCachedNotify("battle_tag", self, self.ProcessCachedBattleTagForNpcGuideChange, Tag)
end

function SceneModule:ProcessCachedBattleTagForNpcGuideChange(Notify, GivenTag)
  if not Notify then
    return false
  end
  if not GivenTag then
    return false
  end
  local NotifyTag = Notify.act_tags and Notify.act_tags.battle_tag
  if not NotifyTag then
    return false
  end
  if GivenTag.battle_id and GivenTag.battle_id ~= NotifyTag.battle_id then
    return false
  end
  if GivenTag.round and GivenTag.round ~= NotifyTag.round then
    return false
  end
  if GivenTag.group_id and GivenTag.group_id ~= NotifyTag.group_id then
    return false
  end
  if GivenTag.cast_moment and GivenTag.cast_moment ~= NotifyTag.cast_moment then
    return false
  end
  for _, act in ipairs(Notify.acts) do
    if act.npc_guide_change ~= nil then
      return true
    end
  end
  return false
end

function SceneModule:GetActorType(id)
  if 0 == id then
    return 0
  end
  return (id & -1152921504606846976) >> 60 & 15
end

function SceneModule:CheckIsNpc(id)
  local Type = self:GetActorType(id)
  return Type ~= ProtoEnum.SpaceEnum_SpaceObjSubType.ENUM.Actor_Avatar
end

function SceneModule:CheckIsPlayer(id)
  local Type = self:GetActorType(id)
  return Type == ProtoEnum.SpaceEnum_SpaceObjSubType.ENUM.Actor_Avatar
end

function SceneModule:GetPlayerUin(id)
  if not self:CheckIsPlayer(id) then
    return 0
  end
  local shifted = id >> 26
  local uin = shifted & 4294967295
  return uin
end

function SceneModule:GetEnterActorType(actor)
  return actor.actor_detail_type ~= ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal
end

function SceneModule:OnTick(DeltaTime)
  if self._isLoading or self.triggerEnterScene then
    return
  end
  for Name, NotifyCaches in pairs(self.ActionCaches) do
    if NotifyCaches and #NotifyCaches > 0 then
      while #NotifyCaches > 0 and NotifyCaches[1].receiveTime and os.msTime() - NotifyCaches[1].receiveTime > MAX_SPACE_ACT_CACHE_TIME do
        if not _G.RocoEnv.IS_SHIPPING then
          local NotifyCache = NotifyCaches[1]
          local strActs = ""
          for i = 1, #NotifyCache.acts do
            local act = NotifyCache.acts[i]
            for k, _ in pairs(act) do
              strActs = strActs .. k .. ","
            end
          end
          Log.Error("[ZoneServer][NetMsg][SpaceActionNotify][SpaceActTags] TimeOut SpaceAction ", strActs)
        end
        table.remove(NotifyCaches, 1)
      end
    end
  end
  if _G.GlobalConfig.DisableNPCModule then
    self:OnEnterSceneFinishNtyAckEnd()
  else
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if self.bWaitingForAckEnd and self._isMainUIReady and _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CheckInitialNPCsReady) and localPlayer and localPlayer.statusComponent and not localPlayer.statusComponent._shouldWaitRecover then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.ClearInitialNPCsList)
      if _G.ZoneServer:IsPausedBy("WaitingForAckEnd") then
        _G.ZoneServer:Resume("WaitingForAckEnd")
      end
      local bInTogetherTeleport = false
      if localPlayer and localPlayer.statusComponent:IsInTogetherTeleport() then
        bInTogetherTeleport = true
      end
      if not bInTogetherTeleport then
        self:OnEnterSceneFinishNtyAckEnd()
      end
    end
  end
end

function SceneModule:Free()
  Base.Free(self)
  if self._eventDispatcher then
    self._eventDispatcher:RemoveAllListeners()
    self._eventDispatcher = nil
  end
end

function SceneModule:EnterScene(rsp)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.EnterScene)
  self.TeleportLoadingCustomData = {
    TeleportHomeName = rsp.scene_res_cfg_id == 30001 and rsp.home_name,
    TeleportFarmName = rsp.scene_res_cfg_id == 30002 and rsp.home_name
  }
  self.triggerEnterScene = true
  Log.Debug(rsp.self_info.avatar.game_time_infos, "SceneModule:EnterScene")
  SceneUtils.FixActorPoint(rsp.self_info)
  _G.NRCModeManager:DoCmd(PlayerModuleCmd.AddSelfPlayer, rsp.self_info.avatar)
  local AvatarInfo = rsp.self_info.avatar
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartX %d", AvatarInfo.base.pt.pos.x))
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartY %d", AvatarInfo.base.pt.pos.y))
  UE.UNRCStatics.ExecConsoleCommand(string.format("NRCCustomPlayerStartZ %d", AvatarInfo.base.pt.pos.z + 90))
  if NRCEnv:IsLocalBattleMode() then
    return
  end
  if _G.GlobalConfig.MemoryAutoTest then
    local serverPos = rsp.self_info.avatar.base.pt.pos
    self.avatarLocation = UE4.FVector(serverPos.x, serverPos.y, serverPos.z)
  end
  if not _G.ZoneServer.ZoneServerGCloud:IsReconnecting() then
    _G.GlobalConfig.SetFastLoadingWorldRendering = false
  end
  _G.DelayManager:DelaySeconds(0.3, function()
    local EnterMapInfo = _G.ProtoMessage:newZoneSceneTeleportNotify()
    EnterMapInfo.to_scene_cfg_id = rsp.scene_cfg_id
    EnterMapInfo.to_scene_res_cfg_id = rsp.scene_res_cfg_id
    EnterMapInfo.to_scene_inst_id = rsp.scene_inst_id
    EnterMapInfo.to_pt = rsp.self_info.avatar.base.pt
    EnterMapInfo.home_room_level = rsp.home_room_level
    EnterMapInfo.self_info = rsp.self_info
    self:EnterMap(EnterMapInfo)
  end)
end

function SceneModule:EnterMap(notify)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.EnterMap)
  self.ZoneSceneTeleportNotify = notify
  local id = notify.to_scene_cfg_id
  local switch_reason = notify.teleport_reason
  Log.Trace("SceneModule:EnterMap, preMapId=", self.preMapId, ",toMapId=", self.mapID, ",switch_reason=", switch_reason)
  if 0 ~= self.mapID and self.mapID ~= id then
    Log.Debug("\232\183\168\229\155\190\228\188\160\233\128\129\239\188\140\228\191\157\229\186\149\229\188\186\229\136\182\229\188\128\229\144\175\229\138\160\232\189\189\231\149\140\233\157\162...")
    _G.GlobalConfig.SetFastLoadingWorldRendering = false
    if LoadingUIModuleCmd then
      NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 0.4, nil, nil, switch_reason)
    end
  end
  if switch_reason == _G.ProtoEnum.TeleportReason.ENUM.LEAVE_ONLINE_VISIT then
    NRCEventCenter:DispatchEvent(SceneEvent.OnEnterMapForLeaveVisit)
  end
  if switch_reason == _G.ProtoEnum.TeleportReason.ENUM.ENTER_ONLINE_VISIT then
    NRCEventCenter:DispatchEvent(SceneEvent.OnEnterMapForEnterVisit)
  end
  local bReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
  _G.ZoneServer:Pause("ChangeMap")
  _G.DelayManager:DelaySeconds(1, function()
    self.config = _G.DataConfigManager:GetSceneConf(id)
    if self.config == nil then
      self.preMapId = 0
      self.mapID = 103
      self.mapInstId = 0
      self.config = _G.DataConfigManager:GetSceneConf(self.mapID)
      self.mapResId = self.config.scene_res_id
    end
    if notify.to_scene_res_cfg_id and 0 ~= notify.to_scene_res_cfg_id then
      self.sceneResConf = _G.DataConfigManager:GetSceneResConf(notify.to_scene_res_cfg_id)
    else
      self.sceneResConf = _G.DataConfigManager:GetSceneResConf(self.config.scene_res_id)
    end
    local curLevelName = LevelHelper:GetLevelName(true)
    local nameTable = string.Split(self.sceneResConf.source, "/")
    local SameSceneRes = curLevelName == nameTable[#nameTable]
    if self.mapID ~= id or self.mapID == id and notify.from_scene_res_cfg_id ~= notify.to_scene_res_cfg_id or switch_reason == _G.ProtoEnum.TeleportReason.ENUM.ENTER_ONLINE_VISIT or switch_reason == _G.ProtoEnum.TeleportReason.ENUM.LEAVE_ONLINE_VISIT then
      self:Log("LevelHelper OpenLevel try")
      self._isLoading = true
      self.preMapId = self.mapID
      self.mapID = id
      self.mapInstId = notify.to_scene_inst_id
      self.mapResId = notify.to_scene_res_cfg_id
      _G.NRCEventCenter:DispatchEvent(SceneEvent.PreLoadMapStart, SameSceneRes, bReconnecting, id)
      _G.NRCEventCenter:DispatchEvent(SceneEvent.LoadMapStart, SameSceneRes, bReconnecting, id, self.mapResId)
      _G.NRCEventCenter:DispatchEvent(SceneEvent.PostLoadMapStart, SameSceneRes, bReconnecting, id)
      BattleField.ChangeScene(self.config.scene_res_id)
      self:Log("OpenLevel", curLevelName, nameTable[#nameTable])
      local serverPos = notify.to_pt.pos
      local beginWorldOrigin = SceneUtils.ServerPos2PlayerPos(serverPos)
      if SameSceneRes then
        self:Log("curLevelName == nameTable[#nameTable]")
        _G.DelayManager:DelayFrames(1, self.OnMapLoaded, self)
      else
        self:Log("LevelHelper OpenLevel", self.sceneResConf.source)
        if _G.GlobalConfig.MemoryAutoTest then
          local loadLevelPath = UE4.UNRCStatics.GetLoadLevelPath()
          self:Log(loadLevelPath)
          if "None" == loadLevelPath then
            _G.LevelHelper:OpenLevelWithOrigin(self.sceneResConf.source, beginWorldOrigin)
          else
            _G.LevelHelper:OpenLevelWithOrigin(loadLevelPath, beginWorldOrigin)
          end
        elseif not _G.GlobalConfig.OpenTestUIScene then
          _G.LevelHelper:OpenLevelWithOrigin(self.sceneResConf.source, beginWorldOrigin)
        else
          _G.LevelHelper:OpenLevelWithOrigin("/Game/Levels/UITestScene", beginWorldOrigin)
        end
      end
    else
      self:Log("SceneModule LevelHelper OpenLevel _isLoading:", self._isLoading)
      if self._isLoading == false then
        _G.NRCEventCenter:DispatchEvent(SceneEvent.PreLoadMapStart, SameSceneRes, bReconnecting, id)
        _G.NRCEventCenter:DispatchEvent(SceneEvent.LoadMapStart, SameSceneRes, bReconnecting, id, self.mapResId)
        _G.NRCEventCenter:DispatchEvent(SceneEvent.PostLoadMapStart, SameSceneRes, bReconnecting, id)
        self:Log("SceneModule LevelHelper OpenLevel _isLoading load succ")
        _G.DelayManager:DelayFrames(1, self.OnMapLoaded, self)
      end
    end
    local AreaQueryManager = UE4.UAreaQueryManager.Get(_G.UE4Helper.GetCurrentWorld())
    if AreaQueryManager then
      AreaQueryManager:SetCurrentSceneResID(self.mapResId)
    end
  end)
end

function SceneModule:GetCurrentZoneSceneTeleportNotify()
  return self.ZoneSceneTeleportNotify
end

function SceneModule:GetTeleportLoadingCustomData()
  return self.TeleportLoadingCustomData
end

function SceneModule:GetCurrentMapId()
  return self.mapID
end

function SceneModule:GetCurrentMapResId()
  return self.mapResId
end

function SceneModule:OnPostLoadMapWithWorld(World)
  if not World then
    Log.Error("\231\130\184\228\186\134\231\130\184\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129World\228\184\141\229\173\152\229\156\168\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129")
    return
  end
  local SceneResConf
  local Mode = _G.NRCModeManager:GetCurMode()
  local ModeName = Mode and Mode.modeName
  if _G.GlobalConfig.OpenTestUIScene or "LocalMode" == ModeName then
    self:Log("Running in testing/local mode skip world name check")
  else
    SceneResConf = _G.DataConfigManager:GetSceneResConf(self.mapResId)
    if not SceneResConf then
      return
    end
    local WorldName = UE.UObject.GetName(World)
    if WorldName ~= SceneResConf.main_source then
      Log.Error("\231\130\184\228\186\134\231\130\184\228\186\134\239\188\129\239\188\129\239\188\129\229\138\160\232\189\189\231\154\132World\228\184\141\229\175\185\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129", SceneResConf.main_source, "~=", WorldName)
      return
    end
  end
  UE.UNRCStatics.ExecConsoleCommand("NRCCustomPlayerStartX 0", nil)
  UE.UNRCStatics.ExecConsoleCommand("NRCCustomPlayerStartY 0", nil)
  UE.UNRCStatics.ExecConsoleCommand("NRCCustomPlayerStartZ 0", nil)
  self:OnMapLoaded()
  if not SceneResConf or string.IsNilOrEmpty(SceneResConf.all_dynamic_load_sublevel_path) then
    return
  end
  local Split = string.split(SceneResConf.all_dynamic_load_sublevel_path, ";")
  local StoryFlagConf = _G.NRCModuleManager:DoCmd(StoryFlagModuleCmd.GetLoadSceneList, self.mapResId)
  local HasLoad = false
  if StoryFlagConf then
    for i = 1, #Split do
      local Current = Split[i]
      if Current == StoryFlagConf.action_string_param then
        HasLoad = true
        _G.LevelHelper:LoadStreamLevel(Current, true, false)
      else
        _G.LevelHelper:UnloadStreamLevel(Current, false)
      end
    end
  else
    for i = 1, #Split do
      local Current = Split[i]
      if Current == SceneResConf.default_load_sublevel_path then
        HasLoad = true
        _G.LevelHelper:LoadStreamLevel(Current, true, false)
      else
        _G.LevelHelper:UnloadStreamLevel(Current, false)
      end
    end
  end
  if HasLoad then
    UE.UNRCStatics.BlockTillLevelStreamingCompleted(_G.UE4Helper.GetCurrentWorld())
  end
end

function SceneModule:SwitchDynamicLevel(LevelName)
  if string.IsNilOrEmpty(LevelName) then
    return
  end
  local SceneResConf = _G.DataConfigManager:GetSceneResConf(self.mapResId)
  if not SceneResConf then
    return
  end
  if string.IsNilOrEmpty(SceneResConf.all_dynamic_load_sublevel_path) then
    return
  end
  local Split = string.split(SceneResConf.all_dynamic_load_sublevel_path, ";")
  for i = 1, #Split do
    if Split[i] == LevelName then
      _G.LevelHelper:LoadStreamLevel(Split[i], true, false)
    else
      _G.LevelHelper:UnloadStreamLevel(Split[i], false)
    end
  end
end

function SceneModule:OnMapLoaded()
  self:Log("SceneManager:_OnMapLoaded", self._isLoading)
  if self._isLoading then
    self._isLoading = false
  end
  self:PostMapLoaded()
  if self.triggerEnterScene and _G.ZoneServer:IsEnteringOrSwitchingCell() then
    local clientReadyMsg = ProtoMessage:newZoneSceneClientEnterSceneFinishNty()
    clientReadyMsg.feature_data = _G.NRCSDKManager:GetLightFeaturePacket()
    _G.NRCNetworkManager:FlushRecvMessage(_G.ZoneServer.connectID)
    _G.ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CLIENT_ENTER_SCENE_FINISH_NTY, clientReadyMsg)
  end
  if _G.NRCEnv:IsLocalMode() then
    _G.NRCEventCenter:DispatchEvent(SceneEvent.BigWorldPrepared)
  end
  _G.ZoneServer:Resume("ChangeMap")
  if _G.GlobalConfig.MemoryAutoTest then
    self:Abs_SpawnPlaneUnderPlayer(self.avatarLocation)
  end
  if _G.GlobalConfig.DebugOpenUI then
    local playerController = UE4.UGameplayStatics.GetPlayerController(_G.UE4Helper.GetCurrentWorld(), 0)
    _G.GlobalConfig.GhostMode = true
    if _G.GlobalConfig.GhostMode then
      UE4.UNRCStatics.ExecConsoleCommand("NRCGhost 3000", playerController)
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, "\229\183\178\231\187\143\232\191\155\229\133\165ghost\230\168\161\229\188\143")
    end
  end
end

function SceneModule:Abs_SpawnPlaneUnderPlayer(location)
  local curLocation = location
  local BP_Plane = UE4.UClass.Load("/Game/Game/NRC/GameMode/AutoTest/BP_Plane.BP_Plane")
  local trans = UE4.FTransform()
  local translation = UE4.FVector()
  translation = curLocation
  translation.z = translation.z - 86
  trans.Translation = translation
  UE4Helper.GetCurrentWorld():Abs_SpawnActor(BP_Plane, trans)
end

function SceneModule:PostMapLoaded()
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.PostMapLoaded)
  if _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.TryClearTabCache)
  end
  if self.requestEnterSceneAsyncData then
    self.requestEnterSceneAsyncData.callback(self.requestEnterSceneAsyncData.owner, true)
    self.requestEnterSceneAsyncData = nil
  end
  self:CheckSceneBan()
  self:CheckSpecialScene()
  _G.LevelHelper:SetLevelVisibility(_G.LevelHelper.Flags.Default | _G.LevelHelper.Flags.Main)
  local notify = self:GetCurrentZoneSceneTeleportNotify()
  if notify and notify.self_info.avatar and notify.self_info.avatar.story then
    _G.NRCModuleManager:DoCmd(PlayerModuleCmd.OnHomeOwnerStoryFlagChange, notify.self_info.avatar.story)
  end
  local bReconnecting = _G.ZoneServer.ZoneServerGCloud:IsReconnecting()
  _G.NRCEventCenter:DispatchEvent(SceneEvent.BeforeLandPos, bReconnecting)
  _G.NRCEventCenter:DispatchEvent(SceneEvent.PreLoadMapFinish, bReconnecting)
  _G.NRCEventCenter:DispatchEvent(SceneEvent.LoadMapFinish, bReconnecting)
end

function SceneModule:SamplePosition(actor, pos)
  pos.Z = pos.Z + 100
  local QueryExtent = UE4.FVector(100, 100, 400)
  local ProjectedLocation, resValue = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(actor, pos, nil, nil, nil, QueryExtent)
  if resValue then
    return ProjectedLocation
  end
  return UE4.FVector(self.config.born_pos_x, self.config.born_pos_y, self.config.born_pos_z)
end

function SceneModule:ClearAll()
  NRCModuleManager:DoCmd(PlayerModuleCmd.CLEAR_ALL)
end

function SceneModule:OnSceneBankLoaded(bankName, result)
  Log.DebugFormat("[SceneModule]  load bank %s result %d", bankName, result)
  if result == UE4.EAkResult.Success or result ~= UE4.EAkResult.BankAlreadyLoaded or bankName == self.BGMBank then
  end
end

function SceneModule:GetBlockingArea()
  return self.blockingArea.area_dict
end

function SceneModule:GetRelatedBlockingArea(center, radius)
  local relatedArea = {}
  for i, v in pairs(self.blockingArea.area_dict) do
    if UE4.UKismetMathLibrary.Vector_Distance(v.location, center) < v.radius + radius then
      table.insert(relatedArea, v)
    end
  end
  return relatedArea
end

function SceneModule:RegisterBlockingArea(caller, center, radius, forceEnable, priority)
  return self.blockingArea:RegisterArea(caller, center, radius, forceEnable, priority)
end

function SceneModule:UnregisterBlockingArea(caller)
  self.blockingArea:UnregisterArea(caller)
end

function SceneModule:IsInPikaShop()
  if type(self.AllPikaShopSceneResId) ~= "table" then
    return false
  end
  for i, resId in ipairs(self.AllPikaShopSceneResId) do
    if self.mapResId == resId then
      return true
    end
  end
  return false
end

function SceneModule:CheckSceneBan()
  local PreSceneResID = self.RecordSceneResID or 0
  local CurSceneResID = self.mapResId
  if PreSceneResID == CurSceneResID then
    return
  end
  self.RecordSceneResID = CurSceneResID
  local PreSceneResConf = _G.DataConfigManager:GetSceneResConf(PreSceneResID, true)
  local CurSceneResConf = _G.DataConfigManager:GetSceneResConf(CurSceneResID, true)
  Log.DebugFormat("[CheckSceneBan]\229\156\186\230\153\175\229\136\135\230\141\162    \230\151\167\229\156\186\230\153\175: %s;    \230\150\176\229\156\186\230\153\175: %s", PreSceneResConf and PreSceneResConf.editor_name or "\228\184\141\229\173\152\229\156\168", CurSceneResConf and CurSceneResConf.editor_name or "\228\184\141\229\173\152\229\156\168")
  if 0 ~= PreSceneResID and PreSceneResConf then
    if PreSceneResConf.function_ban_id and 0 ~= PreSceneResConf.function_ban_id then
      _G.FunctionBanManager:RemovePlayerConditionType(PreSceneResConf.function_ban_id, "Scene_" .. PreSceneResID)
      Log.DebugFormat("[CheckSceneBan]\231\167\187\233\153\164\230\151\167\229\156\186\230\153\175FunctionBan    \230\151\167\229\156\186\230\153\175\239\188\154%s;    \230\151\167\229\156\186\230\153\175FunctionBan\231\177\187\229\158\139\239\188\154%s ", PreSceneResConf.editor_name, table.getKeyName(Enum.PlayerConditionType, PreSceneResConf.function_ban_id))
    end
    local BanVitality = PreSceneResConf.ban_vitality and 1 == PreSceneResConf.ban_vitality
    if BanVitality then
      _G.GlobalConfig.FreeVitality = not BanVitality
      Log.DebugFormat("[CheckSceneBan]\231\167\187\233\153\164\230\151\167\229\156\186\230\153\175\228\189\147\229\138\155\233\153\144\229\136\182    \230\151\167\229\156\186\230\153\175\239\188\154%s;    \230\151\167\229\156\186\230\153\175FreeVitality\239\188\154%s ", PreSceneResConf.editor_name, tostring(BanVitality))
    end
    self.BanMagicTypes = nil
    self.BanRolePlayProps = nil
  end
  if 0 ~= CurSceneResID and CurSceneResConf then
    if CurSceneResConf.function_ban_id and 0 ~= CurSceneResConf.function_ban_id then
      Log.DebugFormat("[CheckSceneBan]\230\183\187\229\138\160\229\189\147\229\137\141\229\156\186\230\153\175\231\166\129\231\148\168\230\128\129    \229\189\147\229\137\141\229\156\186\230\153\175\239\188\154%s;    \229\189\147\229\137\141\229\156\186\230\153\175\231\166\129\231\148\168\231\177\187\229\158\139\239\188\154%s ", CurSceneResConf.editor_name, table.getKeyName(Enum.PlayerConditionType, CurSceneResConf.function_ban_id))
      _G.FunctionBanManager:AddPlayerConditionType(CurSceneResConf.function_ban_id, "Scene_" .. CurSceneResID)
    end
    local BanVitality = CurSceneResConf.ban_vitality and 1 == CurSceneResConf.ban_vitality
    _G.GlobalConfig.FreeVitality = not not BanVitality
    Log.DebugFormat("[CheckSceneBan]\230\183\187\229\138\160\229\189\147\229\137\141\229\156\186\230\153\175\228\189\147\229\138\155\233\153\144\229\136\182    \229\189\147\229\137\141\229\156\186\230\153\175\239\188\154%s;    \229\189\147\229\137\141\229\156\186\230\153\175FreeVitality\239\188\154%s ", CurSceneResConf.editor_name, tostring(BanVitality))
    self.BanMagicTypes = CurSceneResConf.ban_magic
    self.BanRolePlayProps = CurSceneResConf.ban_roleplay_tools
  end
end

function SceneModule:IsMagicBanned(MagicType)
  return self.BanMagicTypes and table.contains(self.BanMagicTypes, MagicType)
end

function SceneModule:IsRolePlayPropBanned(PropId)
  return self.BanRolePlayProps and table.contains(self.BanRolePlayProps, PropId)
end

function SceneModule:CheckSpecialScene()
  if self.mapResId == 10030 then
    _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_PRECLOSED, self.OnEnterDarkSoulRiver)
  end
end

function SceneModule:OnEnterDarkSoulRiver()
  local magicItemInfo = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, 100701)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, magicItemInfo)
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
  _G.NRCModuleManager:DoCmd(BagModuleCmd.SetEquipMagicInfo, magicItemInfo, true)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_PRECLOSED, self.OnEnterDarkSoulRiver)
end

return SceneModule
