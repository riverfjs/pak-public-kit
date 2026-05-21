local ProtoEnum = require("Data.PB.ProtoEnum")
local ProtoMessage = {}

function ProtoMessage:newBuffData_32_Skill()
  return {skill_id = nil, val = nil}
end

function ProtoMessage:newBuffData_32()
  return {
    data = {}
  }
end

function ProtoMessage:newBuffData_55()
  return {skill_id = nil}
end

function ProtoMessage:newBuffData_52()
  return {is_on = nil}
end

function ProtoMessage:newBuffData_56_Skill()
  return {old_skill_id = nil, new_skill_id = nil}
end

function ProtoMessage:newBuffData_56()
  return {
    skill_ids = {}
  }
end

function ProtoMessage:newBuffData_62()
  return {
    skills = {},
    old_stack = nil
  }
end

function ProtoMessage:newBuffData_63()
  return {
    skill_ids = {},
    add = nil
  }
end

function ProtoMessage:newBuffData_72_PetBuff()
  return {
    pet_id = nil,
    buff_id = nil,
    stack = nil
  }
end

function ProtoMessage:newBuffData_72()
  return {
    data = {}
  }
end

function ProtoMessage:newBuffData_77()
  return {
    skill_ids = {},
    add = nil
  }
end

function ProtoMessage:newBuffData_81()
  return {hp_mod = nil, en_mod = nil}
end

function ProtoMessage:newBuffData_89_Buff()
  return {buff_id = nil, stack = nil}
end

function ProtoMessage:newBuffData_89()
  return {
    data = {}
  }
end

function ProtoMessage:newBuffData_90_Convert()
  return {
    src = nil,
    stack = nil,
    dst = nil
  }
end

function ProtoMessage:newBuffData_90_Raw()
  return {dst = nil, stack = nil}
end

function ProtoMessage:newBuffData_90()
  return {
    convert = {},
    raw = {}
  }
end

function ProtoMessage:newBuffData_91()
  return {sum_stacks = nil, skill_id = nil}
end

function ProtoMessage:newBuffData_92()
  return {aura_on = nil}
end

function ProtoMessage:newBuffData_93_Skill_Energy()
  return {skill_id = nil, val = nil}
end

function ProtoMessage:newBuffData_93()
  return {
    energy_info = {},
    is_triggered = nil,
    selected_buffbase_id = nil
  }
end

function ProtoMessage:newBuffData_93_Skill()
  return {
    buffbase_id = nil,
    val = nil,
    side = nil,
    role_uin = nil
  }
end

function ProtoMessage:newBuffData_93_Common()
  return {
    data = {},
    skill_data = {},
    triggered_buff = {}
  }
end

function ProtoMessage:newBuffData_95()
  return {
    triggered_skills = {},
    trigger_times = nil
  }
end

function ProtoMessage:newBuffData_102()
  return {
    old_base_ids = {}
  }
end

function ProtoMessage:newBuffData_103()
  return {
    skill_ids = {},
    add = nil
  }
end

function ProtoMessage:newBuffData_113_Common()
  return {
    pet_id = nil,
    buff_id = nil,
    time_cnt = nil
  }
end

function ProtoMessage:newBuffData_113()
  return {
    pet_info = {}
  }
end

function ProtoMessage:newBuffData_119_Common()
  return {
    used_skill = {}
  }
end

function ProtoMessage:newBuffData_121_Common()
  return {
    type = nil,
    value_inc = nil,
    value_dec = nil,
    time_value_inc = nil,
    time_value_dec = nil,
    last_round_value = nil
  }
end

function ProtoMessage:newBuffData_121()
  return {
    data = {}
  }
end

function ProtoMessage:newBuffData_125()
  return {change_hp = nil, change_energy = nil}
end

function ProtoMessage:newBuffData_126_Common()
  return {buff_id = nil, stack = nil}
end

function ProtoMessage:newBuffData_126()
  return {
    data = {}
  }
end

function ProtoMessage:newBuffData_96()
  return {original_height = nil}
end

function ProtoMessage:newBuffData_132_data()
  return {
    round = nil,
    buff_id = nil,
    types = {},
    pet = nil
  }
end

function ProtoMessage:newBuffData_132_Common()
  return {
    data = {}
  }
end

function ProtoMessage:newBuff_102()
  return {
    pet_id = nil,
    old_base_ids = {}
  }
end

function ProtoMessage:newBuffData_102_Common()
  return {
    pets_info = {}
  }
end

function ProtoMessage:newTargetSkill_Info()
  return {
    target_pet_id = nil,
    target_skill_id = nil,
    is_special = nil
  }
end

function ProtoMessage:newBuffData_6_Common()
  return {
    target_skills = {}
  }
end

function ProtoMessage:newBuffData_6()
  return {
    target_skills = {}
  }
end

function ProtoMessage:newBuffData_134()
  return {round_damage = nil, round = nil}
end

function ProtoMessage:newBuffData_64_Skill()
  return {
    skill_id = {},
    val = nil
  }
end

function ProtoMessage:newBuffData_64()
  return {
    data = {},
    history_start_index = nil
  }
end

function ProtoMessage:newBuffData_146_sks()
  return {skill_a_id = nil, skill_b_id = nil}
end

function ProtoMessage:newBuffData_146_PetBuffMaps()
  return {
    pet_id = nil,
    buff_id = nil,
    skill_maps = {}
  }
end

function ProtoMessage:newBuffData_146_Common()
  return {
    entries = {}
  }
end

function ProtoMessage:newBuffbaseRunningData()
  return {
    idx = nil,
    b6 = ProtoMessage:newBuffData_6(),
    b32 = ProtoMessage:newBuffData_32(),
    b52 = ProtoMessage:newBuffData_52(),
    b55 = ProtoMessage:newBuffData_55(),
    b56 = ProtoMessage:newBuffData_56(),
    b62 = ProtoMessage:newBuffData_62(),
    b63 = ProtoMessage:newBuffData_63(),
    b64 = ProtoMessage:newBuffData_64(),
    b72 = ProtoMessage:newBuffData_72(),
    b77 = ProtoMessage:newBuffData_77(),
    b81 = ProtoMessage:newBuffData_81(),
    b89 = ProtoMessage:newBuffData_89(),
    b90 = ProtoMessage:newBuffData_90(),
    b91 = ProtoMessage:newBuffData_91(),
    b92 = ProtoMessage:newBuffData_92(),
    b93 = ProtoMessage:newBuffData_93(),
    b95 = ProtoMessage:newBuffData_95(),
    b96 = ProtoMessage:newBuffData_96(),
    b102 = ProtoMessage:newBuffData_102(),
    b103 = ProtoMessage:newBuffData_103(),
    b113 = ProtoMessage:newBuffData_113(),
    b121 = ProtoMessage:newBuffData_121(),
    b125 = ProtoMessage:newBuffData_125(),
    b126 = ProtoMessage:newBuffData_126(),
    b134 = ProtoMessage:newBuffData_134()
  }
end

function ProtoMessage:newBuffRunningData()
  return {
    data = {}
  }
end

function ProtoMessage:newCommonBuffData()
  return {
    b6 = ProtoMessage:newBuffData_6_Common(),
    b93 = ProtoMessage:newBuffData_93_Common(),
    b119 = ProtoMessage:newBuffData_119_Common(),
    b132 = ProtoMessage:newBuffData_132_Common(),
    b102 = ProtoMessage:newBuffData_102_Common(),
    b146 = ProtoMessage:newBuffData_146_Common()
  }
end

function ProtoMessage:newPosition()
  return {
    x = nil,
    y = nil,
    z = nil
  }
end

function ProtoMessage:newPosition2D()
  return {x = nil, y = nil}
end

function ProtoMessage:newPoint()
  return {
    pos = ProtoMessage:newPosition(),
    dir = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newRect()
  return {
    beg = ProtoMessage:newPosition(),
    size = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newRect2D()
  return {
    beg = ProtoMessage:newPosition2D(),
    size = ProtoMessage:newPosition2D()
  }
end

function ProtoMessage:newGlassInfo()
  return {
    glass_type = ProtoEnum.GlassType.GT_NULL,
    glass_value = nil
  }
end

function ProtoMessage:newRecordItem()
  return {
    cmd = nil,
    cmd_val = nil,
    content = nil,
    write_time = nil
  }
end

function ProtoMessage:newRecordItemList()
  return {
    item_list = {}
  }
end

function ProtoMessage:newRecordFileData()
  return {
    battle_id = nil,
    uin = nil,
    battle_data = ProtoMessage:newRecordItemList()
  }
end

function ProtoMessage:newPlayerSceneInfo()
  return {
    cell_id = nil,
    pt = ProtoMessage:newPoint(),
    belong_camp = nil,
    entered_cell_in_last_login_progress = nil,
    kickout_type_when_scenesvr_recovering = nil,
    destroy_failed_cellsvr_buspp_inst_ids = {},
    time_of_day = nil,
    weather_type = nil,
    curr_time = nil
  }
end

function ProtoMessage:newPetCarryonInfo()
  return {
    carryon_id = nil,
    carryon_idx = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newPetSkillData()
  return {
    id = nil,
    type = nil,
    is_learned = nil,
    is_equipped = nil,
    pos = nil,
    season_id = nil,
    unlock_need_lv = nil,
    raw_id = nil,
    carryon_info = ProtoMessage:newPetCarryonInfo(),
    conf_idx = nil,
    skill_src = nil,
    unlock_need_base_id = nil,
    use_times = nil
  }
end

function ProtoMessage:newPetSkillRecord()
  return {skill_id = nil, use_times = nil}
end

function ProtoMessage:newSkillRecord()
  return {
    uin = nil,
    skill_id = nil,
    result0 = nil,
    result1 = nil,
    result2 = nil,
    restraint_cnt1 = nil,
    restraint_cnt2 = nil,
    restraint_cnt3 = nil
  }
end

function ProtoMessage:newPetSkillInfo()
  return {
    skill_data = {},
    happy_skill_ids = {},
    angry_skill_ids = {}
  }
end

function ProtoMessage:newPetPosition()
  return {
    pet_id = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newCastInfo()
  return {
    skill_id = nil,
    aura_conf_id = nil,
    group_id = nil,
    cast_moment = nil,
    pet_base_id = nil
  }
end

function ProtoMessage:newPetCastAura()
  return {
    pet_pos_info = ProtoMessage:newPetPosition(),
    cast_info = {}
  }
end

function ProtoMessage:newBattleRemoveAuraInfo()
  return {
    remove_aura_effect = {},
    pet_base_id = nil
  }
end

function ProtoMessage:newPetRemoveAura()
  return {
    pet_pos_info = ProtoMessage:newPetPosition(),
    remove_info = {}
  }
end

function ProtoMessage:newMonsterDiffInfo()
  return {
    height = nil,
    weight = nil,
    nature = nil,
    mutation_type = nil,
    blood_mix_skill_dam_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    voice = nil,
    gender = nil
  }
end

function ProtoMessage:newCheerMonsterInitInfo()
  return {
    conf_id = nil,
    sid = nil,
    tag = nil,
    enter_index = nil,
    level = nil,
    ai_status = nil,
    pre_act_tag = nil,
    pre_act_param = nil,
    monster_diff_info = ProtoMessage:newMonsterDiffInfo()
  }
end

function ProtoMessage:newBoxMonsterInfo()
  return {
    box_type = ProtoEnum.BoxType.BOX_TYPE_INVALID,
    is_shiny = nil,
    is_fantastic = nil,
    box_conf_id = nil,
    pet_content_id = nil,
    is_nightmare = nil,
    belong_season = nil,
    name = nil,
    monster_id = nil,
    pet_rarity_type = ProtoEnum.PetRarityType.PET_RARITY_TYPE_INVALID,
    pet_mutation_type = ProtoEnum.PetMutationType.PET_MUTATION_TYPE_INVALID,
    pet_nature = nil,
    gender = nil,
    height = nil,
    weight = nil,
    voice = nil,
    refresh_batch_id = nil
  }
end

function ProtoMessage:newSeasonPetInfo()
  return {
    is_nightmare = nil,
    is_shiny = nil,
    is_fantastic = nil,
    mix_blood = nil,
    refresh_batch_id = nil
  }
end

function ProtoMessage:newSeasonBattleInfo()
  return {
    box_info = ProtoMessage:newBoxMonsterInfo(),
    season_pet_info = ProtoMessage:newSeasonPetInfo()
  }
end

function ProtoMessage:newPetAttributeData()
  return {
    total_race = nil,
    talent = nil,
    base_value = nil,
    effort_exp = nil,
    effort_lv = nil,
    effort_add = nil,
    talent_add_value = nil
  }
end

function ProtoMessage:newPetAttributeInfo()
  return {
    hp = ProtoMessage:newPetAttributeData(),
    attack = ProtoMessage:newPetAttributeData(),
    special_attack = ProtoMessage:newPetAttributeData(),
    defense = ProtoMessage:newPetAttributeData(),
    special_defense = ProtoMessage:newPetAttributeData(),
    speed = ProtoMessage:newPetAttributeData(),
    break_enhance_enum = {}
  }
end

function ProtoMessage:newPetAbilityData()
  return {
    id = nil,
    vitality = nil,
    last_rest_time = nil
  }
end

function ProtoMessage:newPetAbilityInfo()
  return {
    ability_data = {}
  }
end

function ProtoMessage:newBattleAIInitInfo()
  return {
    tod = nil,
    sleeping = nil,
    new_skill = nil,
    predict_type = nil,
    night_habit = nil,
    ai_status = nil,
    pre_act_tag = nil,
    pre_act_param = nil
  }
end

function ProtoMessage:newPossession()
  return {
    conf_id = nil,
    level = nil,
    stage = nil
  }
end

function ProtoMessage:newPossessionInfo()
  return {
    slot_size = nil,
    item = {},
    auto_supply = nil
  }
end

function ProtoMessage:newPetStatistics()
  return {
    follow_sec = nil,
    ride_sec = nil,
    beat_type_cnt = {},
    collect_item_cnt = nil,
    beat_pet_cnt = nil
  }
end

function ProtoMessage:newPetEvoluteInfo()
  return {
    evolute_time = nil,
    before_base_conf_id = nil,
    after_base_conf_id = nil
  }
end

function ProtoMessage:newPvpFirstWinInfo()
  return {
    win_time = nil,
    enemy_name = nil,
    last_killed_pet_name = nil
  }
end

function ProtoMessage:newLegendFirstWinAloneInfo()
  return {win_time = nil, battle_conf_id = nil}
end

function ProtoMessage:newBlessingInfo()
  return {from_player_name = nil, from_pet_name = nil}
end

function ProtoMessage:newObtainShinyFashionInfo()
  return {obtain_time = nil, pet_base_id = nil}
end

function ProtoMessage:newPetBackTrackRecordInfo()
  return {last_backtrack_time = nil}
end

function ProtoMessage:newPetKeyExperience()
  return {
    evolute_info = {},
    pvp_first_win_info = ProtoMessage:newPvpFirstWinInfo(),
    legend_first_win_alone_info = ProtoMessage:newLegendFirstWinAloneInfo(),
    blessing_info = ProtoMessage:newBlessingInfo(),
    obtain_shiny_fashion_info = ProtoMessage:newObtainShinyFashionInfo(),
    text_desc = {},
    backtrack_record_info = ProtoMessage:newPetBackTrackRecordInfo()
  }
end

function ProtoMessage:newPetAdditionalNewAttrInfo()
  return {addi_attr = nil, type = nil}
end

function ProtoMessage:newPetAdditionalNewAttrList()
  return {
    addi_attr_data = {}
  }
end

function ProtoMessage:newPetClosenessHistoryInfo()
  return {closeness_lv = nil, lv_timestamp = nil}
end

function ProtoMessage:newPetClosenessInfo()
  return {
    closeness_exp = nil,
    closeness_lv = nil,
    history_info_list = {}
  }
end

function ProtoMessage:newDefeatInfo()
  return {pet_base_id = nil, defeat_times = nil}
end

function ProtoMessage:newInteractInfo()
  return {npc_conf_id = nil, interact_times = nil}
end

function ProtoMessage:newPetEvolutionNeedInfo()
  return {
    defeat_info = {},
    interact_info = {},
    battle_star_light_value = nil
  }
end

function ProtoMessage:newPetCheerPointInfo()
  return {
    catch_way = nil,
    mutation_type = nil,
    pet_type = nil,
    cheer_point = nil
  }
end

function ProtoMessage:newPetLLMTagHistoryInfo()
  return {timestamp = nil, tag_desc = nil}
end

function ProtoMessage:newPetLLMSingleNatureTagInfo()
  return {
    nature_tag = nil,
    tag_val = nil,
    tag_history_max_val = nil,
    tag_history = {}
  }
end

function ProtoMessage:newPetLLMNatureTagInfo()
  return {
    tag_info_list = {},
    main_nature_tag = nil,
    llm_interaction_count = nil,
    last_base_week_decay_time = nil,
    last_quick_week_decay_time = nil
  }
end

function ProtoMessage:newPetSceneInfo()
  return {
    npc_id = nil,
    interact_quantity = nil,
    interact_quantity_threshold = nil,
    can_trig_bond_name = nil,
    can_trig_bond_none = nil,
    interact_count = nil,
    llm_nature_tag = ProtoMessage:newPetLLMNatureTagInfo()
  }
end

function ProtoMessage:newPetData()
  return {
    gid = nil,
    conf_id = nil,
    name = nil,
    info_id = nil,
    name_src = ProtoEnum.PetNameSource.PNS_PET_BASE,
    skill_dam_type = {},
    nature = nil,
    gender = nil,
    exp = nil,
    level = nil,
    ball_id = nil,
    skill = ProtoMessage:newPetSkillInfo(),
    ability = ProtoMessage:newPetAbilityInfo(),
    attribute_info = ProtoMessage:newPetAttributeInfo(),
    attribute_new_info = ProtoMessage:newPetAdditionalNewAttrList(),
    base_conf_id = nil,
    unlocked_ultimate_skill = nil,
    evolution_chosen_idx = nil,
    evolution_stage = ProtoEnum.PetEvolutionState.EM_EVOLUTION_ADDED,
    seed = nil,
    ai_info = ProtoMessage:newBattleAIInitInfo(),
    pet_status_flags = nil,
    success_catch_cnt = nil,
    height = nil,
    weight = nil,
    classis = nil,
    last_breakthrough_lv = nil,
    possession = ProtoMessage:newPossessionInfo(),
    add_time = nil,
    energy = nil,
    handbook_threshold = nil,
    synchron_num = {},
    is_first_catch = nil,
    catch_status = nil,
    catch_lv = nil,
    catch_base_id = nil,
    mutation_type = nil,
    catch_ai_status = nil,
    blood_id = nil,
    cheer_info = ProtoMessage:newCheerMonsterInitInfo(),
    habit_group_id = nil,
    habit_level = nil,
    stat = ProtoMessage:newPetStatistics(),
    ride_start_time = nil,
    hb_prob_add = nil,
    talent_rank = nil,
    changed_nature_pos_attr_type = nil,
    changed_nature_neg_attr_type = nil,
    caught_camp = nil,
    all_skill = ProtoMessage:newPetSkillInfo(),
    attr_version = nil,
    skill_version = nil,
    rand_evolu_id = nil,
    speciality_version = nil,
    raw_level = nil,
    grow_times = nil,
    catch_way = nil,
    catch_visit_owner_name = nil,
    nature_desc = nil,
    key_experience = ProtoMessage:newPetKeyExperience(),
    nightmare_elite_id = nil,
    wear_medal_conf_id = nil,
    medal_complete_cnt = nil,
    closeness_info = ProtoMessage:newPetClosenessInfo(),
    partner_mark = ProtoEnum.PetPartnerMarkType.PPMT_NONE,
    evlution_need_info = ProtoMessage:newPetEvolutionNeedInfo(),
    custom_medal_conf_id = {},
    is_trial_pet = nil,
    speciality_id = nil,
    real_speciality_ids = {},
    is_in_badgechallenge = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    cheer_point_info = {},
    bitflag = nil,
    business_identity = nil,
    together_catch_info = ProtoMessage:newTogetherCatchInfo(),
    free_medal_conf_ids = {},
    type = ProtoMessage:newPetTypeInfo(),
    voice = nil,
    activity_partner_pet_data = ProtoMessage:newActivityPartnerPetData(),
    nature_attr_change_way = ProtoEnum.PetNatureAttrChangeWay.EM_PET_NATURE_ATTR_CHANGE_WAY_BEGIN,
    inspire_lv = nil,
    nature_desc_id = nil,
    hide_shine = nil,
    patch_version = nil,
    scene_info = ProtoMessage:newPetSceneInfo(),
    season_add_info = ProtoMessage:newSeasonBattleInfo(),
    llm_nature_tag = ProtoMessage:newPetLLMNatureTagInfo()
  }
end

function ProtoMessage:newActivityPartnerPetData()
  return {
    name = nil,
    add_time = nil,
    catch_lv = nil,
    caught_camp = nil,
    catch_way = nil,
    catch_visit_owner_name = nil,
    nature_desc = nil,
    key_experience = ProtoMessage:newPetKeyExperience(),
    closeness_info = ProtoMessage:newPetClosenessInfo(),
    together_catch_info = ProtoMessage:newTogetherCatchInfo(),
    pet_base_id = nil,
    height = nil,
    weight = nil
  }
end

function ProtoMessage:newTrialPetBrief()
  return {
    library_id = nil,
    refresh_time = nil,
    unit_type = {},
    version = nil
  }
end

function ProtoMessage:newTrialPet()
  return {
    brief = ProtoMessage:newTrialPetBrief(),
    pets = {}
  }
end

function ProtoMessage:newPetTypeInfo()
  return {
    type = ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_NORMAL,
    param = nil
  }
end

function ProtoMessage:newPetSpecialityCondCheck()
  return {
    speciality_id = nil,
    pet_gid = nil,
    no_scene = nil,
    can_do = nil
  }
end

function ProtoMessage:newPetUseInfo()
  return {pet_base_cfg_id = nil, use_times = nil}
end

function ProtoMessage:newPetUseRate()
  return {pet_base_cfg_id = nil, use_rate = nil}
end

function ProtoMessage:newEnvEnergyInfo()
  return {
    source_type = nil,
    env_type = nil,
    env_layer = nil,
    src_id = nil,
    tod_time = nil,
    expire_round = nil
  }
end

function ProtoMessage:newPetEnvEnergyInfo()
  return {
    pet_id = nil,
    env_info = {}
  }
end

function ProtoMessage:newPetHpInfo()
  return {
    pet_gid = nil,
    pet_curr_hp = nil,
    pet_max_hp = nil
  }
end

function ProtoMessage:newTogetherCatchInfo()
  return {
    is_catch_together = nil,
    is_onwer_catch = nil,
    related_uin = nil,
    related_name = nil,
    catch_time = nil,
    transfer_deadline = nil,
    catched_uin = nil,
    catched_name = nil,
    carried_medals = {},
    worn_non_auto_medal = nil
  }
end

function ProtoMessage:newPetSpecialExData()
  return {
    add_time = nil,
    catch_lv = nil,
    caught_camp = nil,
    catch_way = nil,
    catch_visit_owner_name = nil,
    nature_desc = nil,
    key_experience = ProtoMessage:newPetKeyExperience(),
    closeness_info = ProtoMessage:newPetClosenessInfo(),
    together_catch_info = ProtoMessage:newTogetherCatchInfo()
  }
end

function ProtoMessage:newPetBriefInfo()
  return {
    gid = nil,
    conf_id = nil,
    name = nil,
    info_id = nil,
    name_src = ProtoEnum.PetNameSource.PNS_PET_BASE,
    skill_dam_type = {},
    nature = nil,
    gender = nil,
    exp = nil,
    level = nil,
    skill = ProtoMessage:newPetSkillInfo(),
    attribute_info = ProtoMessage:newPetAttributeInfo(),
    base_conf_id = nil,
    height = nil,
    weight = nil,
    last_breakthrough_lv = nil,
    is_first_catch = nil,
    mutation_type = nil,
    blood_id = nil,
    talent_rank = nil,
    changed_nature_pos_attr_type = nil,
    changed_nature_neg_attr_type = nil,
    caught_camp = nil,
    attr_version = nil,
    skill_version = nil,
    speciality_version = nil,
    grow_times = nil,
    wear_medal_conf_id = nil,
    attribute_new_info = ProtoMessage:newPetAdditionalNewAttrList(),
    partner_mark = ProtoEnum.PetPartnerMarkType.PPMT_NONE,
    custom_medal_conf_id = {},
    speciality_id = nil,
    real_speciality_ids = {},
    glass_info = ProtoMessage:newGlassInfo(),
    together_catch_info = ProtoMessage:newTogetherCatchInfo(),
    nature_attr_change_way = ProtoEnum.PetNatureAttrChangeWay.EM_PET_NATURE_ATTR_CHANGE_WAY_BEGIN,
    inspire_lv = nil,
    patch_version = nil
  }
end

function ProtoMessage:newPetBacktrack()
  return {
    last_backtrack_time = nil,
    snap_shot = ProtoMessage:newPetBriefInfo(),
    used_items = {},
    exp_from_item = nil,
    pet_gid = nil,
    last_breakthrough_lv = nil,
    grow_times = nil,
    inspire_lv = nil,
    snapshot_write_db = nil,
    show_info = ProtoMessage:newPetBacktrackShowInfo()
  }
end

function ProtoMessage:newPetBacktrackShowInfo()
  return {
    base_conf_id = nil,
    level = nil,
    skill_dam_type = {},
    blood_id = nil,
    last_breakthrough_lv = nil,
    inspire_lv = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    has_filled_show_info = nil,
    name = nil,
    name_src = ProtoEnum.PetNameSource.PNS_PET_BASE,
    conf_id = nil
  }
end

function ProtoMessage:newPetUsedItems()
  return {id = nil, used_num = nil}
end

function ProtoMessage:newPetTravelInfo()
  return {
    camp_content_id = nil,
    camp_lv = nil,
    pet_gid = {},
    start_travel_sec = nil,
    advance_num = nil,
    travel_complete = nil,
    will_lay_egg = nil,
    pet_briefs = {},
    reward_w_pre = {}
  }
end

function ProtoMessage:newMutationCount()
  return {mutation = nil, cnt = nil}
end

function ProtoMessage:newPetStatisticsInfo_PetStatisticsData()
  return {
    pet_base_id = nil,
    battle_count = nil,
    collect_count = nil,
    follow_duration = nil,
    collected_gender_bit = nil,
    collected_nature_bit = nil,
    collected_blood_bit = nil,
    perfect_talent_count = nil,
    collected_naturebuff_bit = nil,
    complete_progress_gid = {},
    mutation_count = {}
  }
end

function ProtoMessage:newPetStatisticsInfo()
  return {
    pet_statistics_data = {}
  }
end

function ProtoMessage:newPetDataInfoList()
  return {
    pet_data = {}
  }
end

function ProtoMessage:newDeletedPetInfo()
  return {
    delete_time = nil,
    pet_data = ProtoMessage:newPetData()
  }
end

function ProtoMessage:newDeletedPetList()
  return {
    delete_pets = {},
    min_delete_time = nil
  }
end

function ProtoMessage:newPetSpecialData()
  return {
    pet_conf_id = nil,
    monster_conf_id = nil,
    pet_name = nil,
    blood_id = nil,
    nature_id = nil,
    gender = nil,
    height = nil,
    weight = nil,
    mutation_type = nil,
    hp_talent = nil,
    phy_attack_talent = nil,
    spe_attack_talent = nil,
    phy_defense_talent = nil,
    spe_defense_talent = nil,
    speed_talent = nil,
    ball_id = nil,
    glass_type = nil,
    glass_value = nil,
    speciality_id = nil,
    medal_conf_ids = {},
    skill_data = {},
    base_id = nil,
    voice = nil,
    pet_name_src = ProtoEnum.PetNameSource.PNS_PET_BASE
  }
end

function ProtoMessage:newReportInfo()
  return {
    id = nil,
    rcr = ProtoEnum.ReportCoinRatio.RCR_NONE,
    rcr_param = nil,
    ratio = nil
  }
end

function ProtoMessage:newPetReportInfo()
  return {
    pet_brief = ProtoMessage:newPetBriefInfo(),
    report_infos = {},
    final_ratio = nil,
    base_coin = nil,
    total_coin = nil
  }
end

function ProtoMessage:newPetReportBriefInfo()
  return {pet_report_info_version = nil, record_size = nil}
end

function ProtoMessage:newPetHabitGroup()
  return {
    group_id = nil,
    habit_level = nil,
    pet_gid = {}
  }
end

function ProtoMessage:newPetHabitInfo()
  return {
    habit_group = {},
    pet_team_habit_idx = {}
  }
end

function ProtoMessage:newPetAdditionalAttrInfo()
  return {
    addi_attr = {},
    addi_attr_base = {}
  }
end

function ProtoMessage:newPetCatchInfo()
  return {
    pet_base_id = nil,
    success_count = nil,
    fail_count = nil,
    catch_probability = nil,
    threshold_add = nil
  }
end

function ProtoMessage:newPetBoxPetChange()
  return {
    pet_gid = nil,
    is_in_team = nil,
    id = nil,
    pos = nil
  }
end

function ProtoMessage:newPetBox()
  return {
    box_id = nil,
    mark_type = ProtoEnum.WarehouseMarkType.WMT_DEFAULT,
    pet_gid = {},
    vacancy_num = nil,
    box_name = nil,
    lock = nil
  }
end

function ProtoMessage:newPetBackpackInfo()
  return {
    egg_gid = {},
    boxes = {},
    last_open_box_id = nil,
    mark_unlock_info = nil,
    tidy_rules = {}
  }
end

function ProtoMessage:newBallInfo()
  return {
    id = nil,
    name = nil,
    ball_prob = nil,
    history_sup_prob = nil,
    hp_sup_prob = nil,
    pp_sup_prob = nil,
    happy_sup_prob = nil
  }
end

function ProtoMessage:newCatchRateInfo()
  return {
    monster_id = nil,
    ball_id = nil,
    rate = nil
  }
end

function ProtoMessage:newZoneCatchResult()
  return {
    is_catched = nil,
    probability = nil,
    is_tech_satisfied = nil,
    is_detected = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newPetSkillUseInfo()
  return {skill_id = nil, use_times = nil}
end

function ProtoMessage:newRankSeasonPetUseInfo()
  return {
    pet_base_cfg_id = nil,
    use_times = nil,
    pet_skill_use_info = {}
  }
end

function ProtoMessage:newPlayerPetMonitorInfo()
  return {
    daily_info = ProtoMessage:newPlayerPetMonitorDailyInfo()
  }
end

function ProtoMessage:newPlayerPetMonitorDailyInfo()
  return {
    obtain_shiny_cnt = nil,
    obtain_glass_cnt = nil,
    obtain_shiny_glass_cnt = nil
  }
end

function ProtoMessage:newPetTaskInfo()
  return {
    together_task = {}
  }
end

function ProtoMessage:newPetTogetherTaskInfo()
  return {
    gid = nil,
    task_id = nil,
    is_in_task_area = nil
  }
end

function ProtoMessage:newSceneBasePetData()
  return {
    gid = nil,
    nature = nil,
    height = nil,
    weight = nil,
    level = nil,
    mutation_type = nil,
    name = nil,
    base_conf_id = nil,
    blood_type = nil,
    talent_rank = nil,
    medal_conf_id = nil,
    medal_fx_level = nil,
    speciality_id = nil,
    real_speciality_ids = {},
    glass_info = ProtoMessage:newGlassInfo(),
    closeness_lv = nil,
    gender = nil,
    voice = nil,
    closeness_exp = nil,
    scene_info = ProtoMessage:newPetSceneInfo(),
    name_src = ProtoEnum.PetNameSource.PNS_PET_BASE,
    llm_nature_tag = ProtoMessage:newPetLLMNatureTagInfo()
  }
end

function ProtoMessage:newPvp_MuteGroups()
  return {
    mute_group = {}
  }
end

function ProtoMessage:newMatchInfo()
  return {
    pvp_id = nil,
    p = nil,
    r = nil,
    rd = nil,
    pvp_rank_star = nil,
    lose_streak = nil,
    pvp_rank_master_score = nil,
    pvp_prof_score = nil,
    uin = nil,
    zone_inst_id = nil,
    start_ut = nil,
    welfare_team = {},
    pve_battle_conf_id = nil,
    matched_uins = {},
    win_streak = nil,
    pvp_rank_order = nil,
    pvp_rank_season_max_star = nil,
    welfare_team_role_magic_id = nil,
    welfare_team_cnt = nil,
    state = ProtoEnum.PvpMatchState.PMS_NONE,
    max_sec = nil,
    pve_succ_ut = nil,
    pvp_team_score = nil,
    self_mute_groups = ProtoMessage:newPvp_MuteGroups(),
    same_team_mute_groups = {}
  }
end

function ProtoMessage:newMatchSuccInfo()
  return {
    uin = nil,
    zone_inst_id = nil,
    r = nil,
    rd = nil,
    pvp_rank_star = nil,
    welfare_team = {},
    pve_battle_conf_id = nil,
    win_streak = nil,
    pvp_rank_order = nil,
    lose_streak = nil,
    pvp_rank_master_score = nil,
    pvp_rank_season_max_star = nil,
    welfare_team_role_magic_id = nil,
    welfare_team_cnt = nil
  }
end

function ProtoMessage:newSalonItemWearData()
  return {item_wear_id = nil, color_wear_id = nil}
end

function ProtoMessage:newGlassTintChange()
  return {
    fashion_item_id = nil,
    glass = ProtoMessage:newGlassInfo(),
    show_gid = nil
  }
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo_WardrobeData()
  return {
    item_wear_id = {},
    name = nil,
    salon_item_wear_id = {},
    wearing_item = {}
  }
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo_WardrobeItem()
  return {
    wearing_item_id = nil,
    wearing_glass = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo_InitRole()
  return {fashion_item_id = nil, fashion_suit_id = nil}
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo_ItemInfo()
  return {
    item_id = nil,
    unlocked_glass = {},
    claimable_glass = {},
    default_glass = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo_SuitInfo()
  return {
    suit_id = nil,
    petbase_pvp_win_num = nil,
    level = nil,
    components_is_worn = {},
    components_is_owned = {}
  }
end

function ProtoMessage:newPlayerAppearanceInfo_FashionInfo()
  return {
    wardrobe_data = {},
    current_wardrobe_index = nil,
    item_owned_id = {},
    suit_id = nil,
    suit_info = {},
    owned_item_info = {},
    init_role_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo_InitRole()
  }
end

function ProtoMessage:newPlayerAppearanceInfo_SalonInfo()
  return {
    item_owned_id = {},
    item_wear_data = {}
  }
end

function ProtoMessage:newFashionBondItem()
  return {
    id = nil,
    get_time = nil,
    pet_tree_interacted = nil,
    color_suit_state = ProtoEnum.FashionBondColorSuitState.FBCSS_LOCKED
  }
end

function ProtoMessage:newPlayerAppearanceInfo_BondInfo()
  return {
    fashion_bond_item = {}
  }
end

function ProtoMessage:newPlayerAppearanceInfo()
  return {
    fashion_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo(),
    salon_info = ProtoMessage:newPlayerAppearanceInfo_SalonInfo(),
    fashion_bond_info = ProtoMessage:newPlayerAppearanceInfo_BondInfo(),
    patch_version = nil
  }
end

function ProtoMessage:newBattleAppearanceInfo()
  return {
    sex = nil,
    salon_item_data = {},
    fashion_wear_id = {},
    uid = nil,
    sign = nil,
    level_id = nil,
    name = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    wearing_item = {}
  }
end

function ProtoMessage:newBattleFashionInfo()
  return {
    fashion_id = {},
    salon_item_data = {},
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    bond_info = ProtoMessage:newPlayerAppearanceInfo_BondInfo(),
    wearing_item = {},
    npc_title = nil
  }
end

function ProtoMessage:newPlayerOnlineState()
  return {}
end

function ProtoMessage:newPlayerMobileBindData()
  return {
    mobile_num = nil,
    sms_code_time = nil,
    sms_request_id = nil,
    reward_time = nil,
    auth_token = nil
  }
end

function ProtoMessage:newPlayerBattleBriefInfo()
  return {
    battle_state = nil,
    battlesvr_buspp_inst_id = nil,
    bfd_id = nil,
    battle_conf_id = nil
  }
end

function ProtoMessage:newFriendPositionInfo()
  return {
    display_type = ProtoEnum.FriendPositionDisplayType.FPDT_NONE,
    scene_res_cfg_id = nil,
    camp_id = nil
  }
end

function ProtoMessage:newFriendVisitInfo()
  return {visitor_num = nil}
end

function ProtoMessage:newPlayerCardBriefInfo_FavoritePetInfo()
  return {
    skill_dam_type = ProtoEnum.SkillDamType.SDT_INVALID,
    pet_base_id = nil,
    last_shown_timestamp = nil,
    mutation_diff_type = ProtoEnum.MutationDiffType.MDT_NONE
  }
end

function ProtoMessage:newPlayerCardBriefInfo_CollectPetInfo()
  return {
    skill_dam_type = ProtoEnum.SkillDamType.SDT_INVALID,
    pet_base_id = nil,
    mutation_diff_type = ProtoEnum.MutationDiffType.MDT_NONE,
    index = nil
  }
end

function ProtoMessage:newPlayerCardBriefInfo_CollectFashionInfo()
  return {fashion_bond_id = nil, index = nil}
end

function ProtoMessage:newPlayerCardBriefInfo_CollectInfo()
  return {
    card_module_pet_infos = {},
    card_module_fashion_infos = {}
  }
end

function ProtoMessage:newPlayerCardBriefInfo_AppearanceInfo()
  return {
    fashion_wear_id = {},
    pose_selected = nil,
    pose_frame_id = nil,
    card_skin_selected = nil,
    salon_item_data = {}
  }
end

function ProtoMessage:newPlayerCardBriefInfo_PetInfo()
  return {
    version = nil,
    collected_shining_pet_count = nil,
    collected_glass_pet_count = nil
  }
end

function ProtoMessage:newPlayerBusinessCardInfo()
  return {
    cur_card = nil,
    cur_card_url = nil,
    apply_change_time = nil,
    last_card = nil,
    last_card_url = nil,
    apply_daily_changes = nil,
    photo_upload_time = nil,
    photo_upload_counts = nil,
    cur_card_md5 = nil
  }
end

function ProtoMessage:newPlayerCardBriefInfo()
  return {
    card_icon_selected = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_signature = nil,
    card_handbook_collect_num = nil,
    card_favorite_pet_info = {},
    card_appearance_info = ProtoMessage:newPlayerCardBriefInfo_AppearanceInfo(),
    card_music_id = nil,
    card_collect_info = ProtoMessage:newPlayerCardBriefInfo_CollectInfo(),
    business_card_info = ProtoMessage:newPlayerBusinessCardInfo(),
    card_fashion_bond_collect_num = nil,
    card_pet_info = ProtoMessage:newPlayerCardBriefInfo_PetInfo()
  }
end

function ProtoMessage:newPlayerStartUpPrivilegeInfo()
  return {cli_startup_day = nil, cli_startup_channel = nil}
end

function ProtoMessage:newPlayerAdditionalData()
  return {
    world_level = nil,
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo(),
    total_recharge = nil,
    total_pet_count = nil,
    area_mail_flag = nil,
    total_handbook_count = nil,
    mobile_bind_info = ProtoMessage:newPlayerMobileBindData(),
    setting_brief_info = ProtoMessage:newPlayerSettingBriefInfo(),
    deletion_info = ProtoMessage:newPlayerDeletionInfo(),
    online_state_update_times = nil,
    battle_pass_brief_info = ProtoMessage:newPlayerBattlePassBriefInfo(),
    reg_game_channel = nil,
    start_up_privilege_info = ProtoMessage:newPlayerStartUpPrivilegeInfo(),
    player_tags = {},
    together_starlight_bonus_ratio = nil,
    plat_nick_name = nil,
    plat_avatar_url = nil
  }
end

function ProtoMessage:newPlayerBattlePassBriefInfo()
  return {
    gift_grade = ProtoEnum.BattlePassGiftGrade.BPGG_FREE
  }
end

function ProtoMessage:newPlayerDeletionInfo()
  return {finished = nil}
end

function ProtoMessage:newPlayerSettingBriefInfo()
  return {
    can_be_searched = nil,
    can_be_sugguested = nil,
    can_be_add_friend = nil,
    can_stranger_visit = nil,
    ai_coach_status = ProtoEnum.AiCoachStatus.ACS_CLOSED
  }
end

function ProtoMessage:newPlayerBriefInfo()
  return {
    uin = nil,
    openid = nil,
    name = nil,
    sex = nil,
    role_level = nil,
    world_level = nil,
    core_additional_brief_info = ProtoMessage:newPlayerCoreAdditionalBriefInfo(),
    plat_nick_name = nil,
    plat_avatar_url = nil,
    register_time = nil,
    login_time = nil,
    logout_time = nil,
    login_times = nil,
    enter_cell_time = nil,
    leave_cell_time = nil,
    enter_cell_times = nil,
    daily_online_time = nil,
    total_online_time = nil,
    last_sync_time = nil,
    online_state = ProtoEnum.PlayerOnlineState.ENUM.Logouted,
    online_state_update_time = nil,
    online_state_addi_data = nil,
    zonesvr_buspp_inst_id = nil,
    cellsvr_buspp_inst_id = nil,
    battlesvr_buspp_inst_id = nil,
    match_state = nil,
    battle_brief = ProtoMessage:newPlayerBattleBriefInfo(),
    permission = nil,
    additional_data = ProtoMessage:newPlayerAdditionalData(),
    vitem_info = ProtoMessage:newPlayerVItemInfo(),
    plat_info = ProtoMessage:newPlatInfo(),
    home_brief_info = ProtoMessage:newPlayerHomeBriefInfo(),
    home_team_info = ProtoMessage:newPlayerHomeTeamInfo()
  }
end

function ProtoMessage:newPlayerVItemInfo()
  return {
    vitem_list_nouse = {},
    liabilities_num_nouse = {},
    vitem_list = {},
    liabilities_num = {},
    is_finish_data_copy = nil
  }
end

function ProtoMessage:newPlatInfo()
  return {
    plat_id = nil,
    world_id = nil,
    cli_login_channel = nil,
    cli_startup_channel = nil,
    reg_channel = nil,
    reg_game_channel = nil
  }
end

function ProtoMessage:newPlayerBriefSecInfo()
  return {
    score = nil,
    tag_black = nil,
    tag_ugc = nil
  }
end

function ProtoMessage:newPlayerCoreAdditionalBriefInfo()
  return {
    brief_sec_info = ProtoMessage:newPlayerBriefSecInfo()
  }
end

function ProtoMessage:newHomeBanInfo()
  return {
    is_banned = nil,
    begin_time = nil,
    end_time = nil,
    ban_reason = nil
  }
end

function ProtoMessage:newHomeViolationInfo()
  return {is_violation = nil, begin_time = nil}
end

function ProtoMessage:newHomeAccessInfo()
  return {
    ban_info = ProtoMessage:newHomeBanInfo(),
    violation_info = ProtoMessage:newHomeViolationInfo()
  }
end

function ProtoMessage:newPlayerHomeBriefInfo()
  return {
    home_name = nil,
    home_experience = nil,
    home_level = nil,
    room_level = nil,
    home_comfort_level = nil,
    room_expansion_info = ProtoMessage:newRoomExpansionInfo(),
    access_info = ProtoMessage:newHomeAccessInfo(),
    unlocked_furniture_list = {}
  }
end

function ProtoMessage:newPlayerHomeTeamInfo()
  return {
    leader_uin = nil,
    marked = nil,
    mark_timestamp = nil,
    restore_visit_pos = ProtoMessage:newPosition(),
    restore_visit_scene_cfg_id = nil,
    team_init_timestamp = nil,
    team_member_uins = {}
  }
end

function ProtoMessage:newRoomExpansionInfo()
  return {room_level = nil, expansion_start_timestamp = nil}
end

function ProtoMessage:newUnlockedFurniture()
  return {furniture_id = nil, unlock_timestamp = nil}
end

function ProtoMessage:newFurnitureHandBook()
  return {
    handbook_id = nil,
    unlock_timestamp = nil,
    reward_received = nil
  }
end

function ProtoMessage:newHomeUnlockedFurnitureInfo()
  return {
    unlocked_furniture_list = {},
    handbook_list = {}
  }
end

function ProtoMessage:newPlayerHomeFurnitureInfo()
  return {
    unlocked_furniture_list = {},
    hufi_change = ProtoMessage:newHomeUnlockedFurnitureInfo()
  }
end

function ProtoMessage:newPlayerLotteryRewardConfirmItem()
  return {
    lottery_item = nil,
    trans_id = nil,
    lottery_result = nil
  }
end

function ProtoMessage:newPlayerLotteryRewardConfirmBagInfo()
  return {
    item_list = {}
  }
end

function ProtoMessage:newPlayerLotteryRewardItemBagInfo()
  return {
    lottery_confirm = ProtoMessage:newPlayerLotteryRewardConfirmBagInfo()
  }
end

function ProtoMessage:newPlayerPvpHisCli()
  return {
    win_count = nil,
    lose_count = nil,
    draw_count = nil,
    freq_base_id = nil
  }
end

function ProtoMessage:newPlayerSecLightFeatureData()
  return {
    feature_name = nil,
    feature_data = nil,
    data_len = nil,
    data_crc = nil
  }
end

function ProtoMessage:newInvitedUser()
  return {
    uin = nil,
    name = nil,
    icon = nil,
    role_level = nil,
    register_time = nil,
    plat_nick_name = nil
  }
end

function ProtoMessage:newPlayerPhotoAlbumInfo()
  return {
    pet_base_id_list = {},
    include_myself = nil
  }
end

function ProtoMessage:newAttrType()
  return {}
end

function ProtoMessage:newAttrPresentTag()
  return {}
end

function ProtoMessage:newActorAttrMendsPartType()
  return {}
end

function ProtoMessage:newTrigInteractType()
  return {}
end

function ProtoMessage:newCreatureAttrs_SimpleAttr32()
  return {val = nil}
end

function ProtoMessage:newCreatureAttrs_SimpleAttr64()
  return {val = nil}
end

function ProtoMessage:newCreatureAttrs_ComplexAttr32()
  return {
    val = nil,
    base = nil,
    total_addi_amend = nil,
    addi_amends = {},
    total_mul_amend = nil,
    mul_amends = {}
  }
end

function ProtoMessage:newCreatureAttrs_ComplexAttr64()
  return {
    type = nil,
    val = nil,
    base = nil,
    total_addi_amend = nil,
    addi_amends = {},
    total_mul_amend = nil,
    mul_amends = {}
  }
end

function ProtoMessage:newSystemExecuteTime()
  return {
    key = nil,
    value = ProtoMessage:newTimeCost()
  }
end

function ProtoMessage:newTimeCost()
  return {start_time = nil, cost_time = nil}
end

function ProtoMessage:newInnerPet()
  return {
    petbase_id = nil,
    mutation_type = nil,
    pet_lv = nil,
    hp_talent = nil,
    attack_talent = nil,
    special_attack_talent = nil,
    defense_talent = nil,
    special_defense_talent = nil,
    speed_talent = nil,
    gender = nil,
    nature = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newFlowerCatchInfo()
  return {pet_gid = nil}
end

function ProtoMessage:newInnerBattleTask()
  return {
    task_id = nil,
    task_state = nil,
    catch_info = ProtoMessage:newFlowerCatchInfo()
  }
end

function ProtoMessage:newSpecFlowerSeed()
  return {
    spec_flower_seed_id = nil,
    content_cfg_id = nil,
    seed_star = nil,
    inner_pet = ProtoMessage:newInnerPet(),
    catch_vitem_quantity = nil,
    activity_id = nil,
    end_timestamp = nil,
    battle_tasks = {},
    bind_pet_gid = nil,
    bind_petbase_id = nil,
    bind_evolution_id = nil,
    medal_id = nil
  }
end

function ProtoMessage:newTransform()
  return {
    pos = ProtoMessage:newPosition(),
    rot = ProtoMessage:newPosition(),
    scale = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newEnvInfoLabelTag()
  return {Tag = nil, Value = nil}
end

function ProtoMessage:newEnvLabelTags()
  return {
    index_z = nil,
    cell_tags = {}
  }
end

function ProtoMessage:newSubmitPetData()
  return {
    petbase_id = nil,
    evolution_chain_id = nil,
    skill_dam_types = {},
    blood_id = {}
  }
end

function ProtoMessage:newAutoIncrementInfo()
  return {
    type = ProtoEnum.AutoIncrementType.AIIT_ACTIVITY,
    key1 = nil,
    key2 = nil,
    step = nil,
    seq = nil,
    is_minus = nil
  }
end

function ProtoMessage:newCommonTextInfoArgs()
  return {type = nil, param = nil}
end

function ProtoMessage:newCommonTextInfo()
  return {
    text_id = nil,
    args = {}
  }
end

function ProtoMessage:newFuncBlockingConfItem()
  return {
    func_id = nil,
    is_open = nil,
    is_audit = nil,
    version_rule = nil,
    open_client_version_ios = nil,
    open_client_version_android = nil,
    open_client_version_pc = nil,
    channel_conf_id = nil,
    open_client_version_harmony_os = nil,
    open_client_version_harmony_pc = nil,
    login_plat_limit = {}
  }
end

function ProtoMessage:newFuncBlockingChannelConfItem()
  return {
    channel_conf_id = nil,
    display_platform = {},
    pkg_channel_hidden_list = {},
    pkg_channel_show_list = {}
  }
end

function ProtoMessage:newFuncBlockingConfs()
  return {
    func_type = nil,
    func_confs = {},
    channel_confs = {}
  }
end

function ProtoMessage:newObjSyncInfo()
  return {
    id = nil,
    sync_id = nil,
    data = nil
  }
end

function ProtoMessage:newGeneralColumnFieldInfo()
  return {
    column_name = nil,
    column_type = ProtoEnum.GeneralColumnType.COLUMN_TYPE_NONE
  }
end

function ProtoMessage:newGeneralColumnFieldsInfo()
  return {
    field_info_list = {}
  }
end

function ProtoMessage:newGeneralColumnField()
  return {
    bytes_val = nil,
    int32_val = nil,
    int64_val = nil,
    str_val = nil,
    uint64_val = nil
  }
end

function ProtoMessage:newGeneralColumnRecord()
  return {
    id = nil,
    id2 = nil,
    id3 = nil,
    id4 = nil,
    id5 = nil,
    field_list = {},
    lease_info = ProtoMessage:newDataLeaseInfo(),
    version = nil
  }
end

function ProtoMessage:newGeneralColumnRecordList()
  return {
    record_list = {}
  }
end

function ProtoMessage:newSubscriptionBucketLease()
  return {lease_deadline = nil}
end

function ProtoMessage:newGlobalConfInfo()
  return {
    num = nil,
    num_list = {},
    str = nil,
    key = nil,
    id = nil
  }
end

function ProtoMessage:newGlobalConfList()
  return {
    global_list = {}
  }
end

function ProtoMessage:newRobotInfo()
  return {
    id = nil,
    openid = nil,
    dead_time = nil,
    patrol_type = nil,
    bron_area_id = nil,
    target_area_id = nil,
    patrol_interval_time = nil
  }
end

function ProtoMessage:newAIBattlePet()
  return {
    gid = nil,
    conf_id = nil,
    blood_id = nil,
    equip_skills = {}
  }
end

function ProtoMessage:newClientRemoteStorageData()
  return {
    key = nil,
    value = nil,
    expire_time = nil,
    create_time = nil
  }
end

function ProtoMessage:newPlayerClientRSInfo()
  return {
    client_rs_data_list = {}
  }
end

function ProtoMessage:newBytesData()
  return {
    id = nil,
    id2 = nil,
    id3 = nil,
    id4 = nil,
    id5 = nil,
    data_index = {},
    data = nil,
    data2 = nil,
    lease_info = ProtoMessage:newDataLeaseInfo()
  }
end

function ProtoMessage:newBytesColumnData()
  return {
    id = nil,
    column_data = {},
    lease_info = ProtoMessage:newDataLeaseInfo(),
    require_insert = nil
  }
end

function ProtoMessage:newColumnData()
  return {column_name = nil, data = nil}
end

function ProtoMessage:newBytesListData()
  return {
    id = nil,
    id2 = nil,
    id3 = nil,
    id4 = nil,
    id5 = nil,
    index = nil,
    data = nil,
    data2 = nil,
    lease_info = ProtoMessage:newDataLeaseInfo()
  }
end

function ProtoMessage:newDataLeaseInfo()
  return {
    policy = ProtoEnum.DataLeaseInfo.ValidationPolicy.VALIDATION_POLICY_NONE,
    lease_token = ProtoMessage:newLease(),
    lease_data = ProtoMessage:newLease()
  }
end

function ProtoMessage:newLease()
  return {
    lease_instance_id = nil,
    lease_version = nil,
    lease_last_sync_time = nil
  }
end

function ProtoMessage:newDotsComponentData()
  return {
    component_datas = {}
  }
end

function ProtoMessage:newSceneSeasonInfo()
  return {
    season_id = nil,
    season_adv_shining_extra_weight = nil,
    season_adv_catch_prob_add = nil,
    is_open = nil
  }
end

function ProtoMessage:newKeyValueItem()
  return {key = nil, value = nil}
end

function ProtoMessage:newKeyValueList()
  return {
    kvlist = {}
  }
end

function ProtoMessage:newVItem()
  return {
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_num = nil
  }
end

function ProtoMessage:newOfflineOperationConsumeState()
  return {
    consume_offset = nil,
    last_consume_time = nil,
    legacy_message_consume_index = nil,
    consume_all_legacy_message = nil
  }
end

function ProtoMessage:newTeleportReason()
  return {}
end

function ProtoMessage:newCampFruitData()
  return {
    fruit_id = nil,
    fruit_pos = nil,
    npc_refresh_content_id = {},
    used_area_id = {},
    npc_id = {}
  }
end

function ProtoMessage:newCampFruitInfo()
  return {
    fruit_data = {},
    last_fruit_take_out_timestamp = nil
  }
end

function ProtoMessage:newOwlSanctuaryFruitNpcInfo()
  return {
    owl_sanctuary_content_id = nil,
    npc_id = {}
  }
end

function ProtoMessage:newCampFruitNpcInfo()
  return {
    camp_content_id = nil,
    owl_sanctuary_fruit_npc_info = {}
  }
end

function ProtoMessage:newOwlSanctuaryFruitBriefInfo()
  return {
    fruit_id = nil,
    npc_id = {},
    fruit_active_timestamp = nil,
    slot_active_timestamp = nil
  }
end

function ProtoMessage:newVisitorOwlSanctuaryDetectInfo()
  return {uin = nil, is_detected = nil}
end

function ProtoMessage:newOwlSanctuaryDetectInfo()
  return {
    is_detected = nil,
    visitor_detect_info = {}
  }
end

function ProtoMessage:newAvatarOwlSanctuaryInfo()
  return {
    npc_content_id = nil,
    is_upgrade = nil,
    is_detected = nil,
    npc_pos = ProtoMessage:newPosition(),
    fruit_brief_infos = {},
    level = nil,
    fruit_info = ProtoMessage:newOwlSanctuaryFruitInfo(),
    logic_id = nil,
    detect_info = ProtoMessage:newOwlSanctuaryDetectInfo(),
    obj_id = nil
  }
end

function ProtoMessage:newOwlSanctuaryFruitNpcGenerateData()
  return {
    npc_refresh_content_id = nil,
    area_id = nil,
    npc_id = nil,
    refresh_max_num = nil,
    owl_content_id = nil
  }
end

function ProtoMessage:newOwlSanctuaryFruitData()
  return {
    fruit_id = nil,
    fruit_gid = nil,
    is_active = nil,
    npc_generate_data = {},
    fruit_active_timestamp = nil,
    slot_active_timestamp = nil,
    npc_ids = {}
  }
end

function ProtoMessage:newVisitorOwlSanctuaryFruitData()
  return {
    uin = nil,
    fruit_data = {}
  }
end

function ProtoMessage:newOwlSanctuaryFruitInfo()
  return {
    fruit_data = {},
    is_init_fruit_set = nil,
    visitor_fruit_data = {}
  }
end

function ProtoMessage:newFusionOwlSanctuaryFruitNpcGenerateData()
  return {
    npc_refresh_content_id = nil,
    area_id = nil,
    npc_id = nil,
    refresh_max_num = nil
  }
end

function ProtoMessage:newFusionOwlSanctuaryInfo()
  return {
    owl_sanctuary_content_id = nil,
    last_refresh_timestamp = nil,
    npc_generate_datas = {}
  }
end

function ProtoMessage:newRefreshPetEggData()
  return {
    pet_egg_id = nil,
    petbase_id = {}
  }
end

function ProtoMessage:newCampRefreshPetEggInfo()
  return {
    camp_id = nil,
    camp_pet_egg_data = {}
  }
end

function ProtoMessage:newOwlSanctuaryPetEggInfo()
  return {
    owl_sanctuary_id = nil,
    owl_sanctuary_pet_egg_data = {}
  }
end

function ProtoMessage:newNavMeshFilterParams()
  return {
    include_nav_flag = nil,
    exclude_nav_flag = nil,
    model_nav_query_exclude_flags = nil,
    query_area_id = nil,
    query_extent = ProtoMessage:newPosition(),
    layer = nil,
    dynamic_flag = nil
  }
end

function ProtoMessage:newSceneEventInfo()
  return {
    id = nil,
    status = nil,
    hit_times = nil,
    bonus_type = nil,
    bonus_event_pool_cfg_id = nil
  }
end

function ProtoMessage:newHabitatAreaInfo()
  return {
    habitat_areas = {}
  }
end

function ProtoMessage:newGroupAreaIds()
  return {
    area_conf_id = {}
  }
end

function ProtoMessage:newSceneFriendInfo()
  return {friend_uin = nil}
end

function ProtoMessage:newSceneFriendInfoCache()
  return {
    cache_inited = nil,
    game_friends = {},
    plat_friends = {}
  }
end

function ProtoMessage:newFlowerSeedBossData()
  return {
    seed_npc_logic_id = nil,
    seed_star = nil,
    inner_petbase_id = nil,
    inner_glass = nil,
    randed_battle_npc_glass = nil,
    inner_shiny = nil,
    inner_glass_info = ProtoMessage:newGlassInfo(),
    inner_pet_lv = nil,
    inner_pet_hp_talent = nil,
    inner_pet_attack_talent = nil,
    inner_pet_special_attack_talent = nil,
    inner_pet_defense_talent = nil,
    inner_pet_special_defense_talent = nil,
    inner_pet_speed_talent = nil,
    inner_pet_gender = nil,
    inner_pet_nature = nil,
    catch_vitem_quantity = nil,
    spec_flower_seed_id = nil,
    activity_id = nil,
    end_timestamp = nil,
    battle_star_rule = nil,
    battle_star_offset = nil,
    min_star = nil,
    battle_tasks = {},
    bind_pet_gid = nil,
    bind_petbase_id = nil,
    bind_evolution_id = nil,
    owner_id = nil,
    blood = nil,
    camp_cfg_id = nil,
    seed_npc_cfg_id = nil,
    seed_npc_obj_id = nil,
    medal_id = nil
  }
end

function ProtoMessage:newPetSkillEquipInfo()
  return {id = nil, pos = nil}
end

function ProtoMessage:newPetTeam_PetInfo()
  return {
    pet_gid = nil,
    equip_infos = {},
    is_trial_pet = nil,
    type = ProtoMessage:newPetTypeInfo()
  }
end

function ProtoMessage:newPetTeam()
  return {
    pet_infos = {},
    team_name = nil,
    role_magic_gid = nil,
    trial_pet = ProtoMessage:newTrialPetBrief(),
    is_mirror = nil,
    mirror_friend_name = nil,
    team_idx = nil,
    mirror_friend_uin = nil,
    mirror_friend_card_icon_selected = nil,
    mirror_magic_id = nil,
    mirror_boss_evo_items = {}
  }
end

function ProtoMessage:newPetSynchronInfo()
  return {type = nil, number = nil}
end

function ProtoMessage:newPetTeamInfo()
  return {
    main_team_idx = nil,
    teams = {},
    synchron = {},
    team_type = nil
  }
end

function ProtoMessage:newSharedPetTeamInfo()
  return {
    team_name = nil,
    team_type = nil,
    role_magic_id = nil,
    pets = {}
  }
end

function ProtoMessage:newSharedPetInfo()
  return {
    hp_talent = nil,
    attack_talent = nil,
    special_attack_talent = nil,
    defense_talent = nil,
    special_defense_talent = nil,
    speed_talent = nil,
    base_conf_id = nil,
    nature = nil,
    blood_id = nil,
    skills = {},
    changed_nature_pos_attr_type = nil,
    changed_nature_neg_attr_type = nil
  }
end

function ProtoMessage:newAdjustedPetTeamInfo()
  return {
    pets = {}
  }
end

function ProtoMessage:newAdjustedPet()
  return {
    gid = nil,
    skills = {}
  }
end

function ProtoMessage:newAdjustedPetSkill()
  return {
    id = nil,
    pos = nil,
    alternative_skills = {}
  }
end

function ProtoMessage:newRecommendPetTeamInfo()
  return {
    pet_team_info = ProtoMessage:newSharedPetTeamInfo(),
    pet_team_share_id = nil,
    player_name = nil,
    player_headpic = nil,
    pet_level = nil,
    team_name = nil,
    team_id = nil
  }
end

function ProtoMessage:newFriendPetTeamInfo()
  return {
    pets = {},
    teams = {},
    friend_name = nil,
    friend_uin = nil,
    friend_level = nil,
    friend_card_icon_selected = nil,
    friend_is_mirror_unlocked = nil
  }
end

function ProtoMessage:newFriendPetTeamIndex()
  return {index_string = nil}
end

function ProtoMessage:newFriendPetTeamBufferFriendInfo()
  return {
    name = nil,
    level = nil,
    card_icon_selected = nil,
    note = nil
  }
end

function ProtoMessage:newTaskTypeInfo_ParagraphInfo()
  return {
    paragraph = nil,
    time = nil,
    is_hide = nil
  }
end

function ProtoMessage:newTaskTypeInfo()
  return {
    task_type = nil,
    open = nil,
    open_paragraph = {},
    done_paragraph = {},
    will_paragraph = {},
    task_num = nil
  }
end

function ProtoMessage:newSceneTaskActionParaInfo()
  return {
    action_param_id = nil,
    is_finish = nil,
    npc_obj_id = nil
  }
end

function ProtoMessage:newSceneTaskActionNpcDelayInfo()
  return {
    npc_content_id = nil,
    is_finish = nil,
    npc_obj_id = nil,
    task_id = nil,
    task_state = nil,
    action_type = ProtoEnum.TaskStateChangeActionType.TSCAT_NONE,
    option_id = nil
  }
end

function ProtoMessage:newSceneTaskActionNpcDelayList()
  return {
    actions = {}
  }
end

function ProtoMessage:newSceneTaskActionInfo()
  return {
    param = nil,
    action_type = ProtoEnum.TaskStateChangeActionType.TSCAT_NONE,
    str_param = nil,
    action_parainfo_list = {},
    is_all_finish = nil,
    is_retry_after_npc_create = nil
  }
end

function ProtoMessage:newSceneTaskActionList()
  return {
    task_id = nil,
    action_info = {},
    task_state = nil
  }
end

function ProtoMessage:newTaskSummaryInfo()
  return {
    pos_x = nil,
    pos_y = nil,
    pos_z = nil,
    summary_id = nil,
    tod = nil,
    weather1 = nil,
    fashion = ProtoMessage:newBattleFashionInfo(),
    create_time = nil,
    task_id = nil,
    weather2 = nil
  }
end

function ProtoMessage:newTaskStoryFlagItem()
  return {
    story_id = nil,
    is_del = nil,
    last_update_task = nil,
    last_update_seq = nil
  }
end

function ProtoMessage:newTaskStoryFlagInfo()
  return {
    items = {}
  }
end

function ProtoMessage:newTaskContentOptionItem()
  return {
    option_id = nil,
    is_show = nil,
    is_add = nil
  }
end

function ProtoMessage:newTaskContentOptionList()
  return {
    items = {}
  }
end

function ProtoMessage:newTaskUnlockWorldMapItem()
  return {
    world_id = nil,
    last_update_task = nil,
    last_update_seq = nil
  }
end

function ProtoMessage:newTaskUnlockWorldMapList()
  return {
    items = {}
  }
end

function ProtoMessage:newTaskContentItem()
  return {
    npc_content_id = nil,
    is_hide = nil,
    is_del = nil,
    last_update_task = nil,
    last_update_seq = nil,
    options = ProtoMessage:newTaskContentOptionList(),
    sale_lock = nil,
    is_openorclose = nil,
    reward_cnt = nil
  }
end

function ProtoMessage:newTaskNpcOptionItem()
  return {
    npc_cfg_id = nil,
    option_id = nil,
    is_del = nil,
    last_update_task = nil,
    last_update_seq = nil
  }
end

function ProtoMessage:newTaskScenesvrStateList()
  return {
    type = nil,
    content_items = {},
    npc_option_items = {}
  }
end

function ProtoMessage:newTaskScenesvrStateItem()
  return {
    type = nil,
    content_items = {}
  }
end

function ProtoMessage:newTaskContentStateList()
  return {
    scenecfg_id = nil,
    items = {},
    last_sync_time = nil
  }
end

function ProtoMessage:newTaskScenesvrStateData()
  return {
    unlock_worlds = ProtoMessage:newTaskUnlockWorldMapList(),
    npc_state_data = {},
    last_excute_time = nil,
    last_recove_time = nil,
    last_update_seq = nil,
    is_need_recove = nil,
    story_flag_infos = ProtoMessage:newTaskStoryFlagInfo(),
    last_login_times = nil,
    content_state_data = {},
    last_login_time = nil
  }
end

function ProtoMessage:newTaskProgressItem()
  return {
    task_id = nil,
    task_tkt_id = nil,
    val = nil,
    last_update_seq = nil,
    gid = nil
  }
end

function ProtoMessage:newTaskProgressList()
  return {
    type = nil,
    items = {}
  }
end

function ProtoMessage:newTaskProgressData()
  return {
    progress_data = {},
    gid = nil,
    ack = nil,
    last_scenesvr_id = nil,
    last_ack_time = nil
  }
end

function ProtoMessage:newBadgeChallengeReward()
  return {
    level_reward_value = nil,
    coin_reward_value = nil,
    hp_recover_value = nil,
    pet_recover = nil,
    upgrade_reward = {}
  }
end

function ProtoMessage:newChallengeEventCardInfo()
  return {
    event_ids = {},
    is_used = nil,
    is_fixed = nil,
    reward = ProtoMessage:newBadgeChallengeReward(),
    incident_type = {},
    param1s = {},
    param2s = {},
    gid = nil,
    is_selected = nil,
    num_1 = nil,
    num_2 = nil,
    upgrade_select_num = nil
  }
end

function ProtoMessage:newBadgeChallengePetInfo()
  return {
    pet_gid = nil,
    remain_hp = nil,
    remain_energy = nil,
    level = nil,
    max_hp = nil,
    conf_id = nil
  }
end

function ProtoMessage:newBadgeChallengeLevelInfo()
  return {
    card_info = ProtoMessage:newChallengeEventCardInfo(),
    level = nil
  }
end

function ProtoMessage:newBadgeChallengeData()
  return {
    level_id = nil,
    cur_event = ProtoMessage:newChallengeEventCardInfo(),
    remain_coin = nil,
    chosen_upgrade_id = {},
    pet_info = {},
    pet_gids = {},
    cur_node_index = nil,
    available_event_cards = {},
    hands_cards = {},
    refresh_need_coin = nil,
    hands_cards_num = nil,
    show_buff_num = nil,
    reroll_cost_add = nil,
    new_card = ProtoMessage:newChallengeEventCardInfo(),
    available_upgrade_ids = {},
    level_infos = {},
    last_gid = nil,
    used_cards_gid = {},
    cur_pet_level = nil
  }
end

function ProtoMessage:newPlayerSubTaskInfo_OngoingSubTaskInfo_TaskTokenInfo()
  return {
    task_token_id = nil,
    task_token_get_time = nil,
    task_token_state = ProtoEnum.PlayerSubTaskInfo_OngoingSubTaskInfo_TaskTokenInfo.TaskTokenState.TTS_UNLOCK
  }
end

function ProtoMessage:newPlayerSubTaskInfo_OngoingSubTaskInfo()
  return {
    sub_task_id = nil,
    task_token_info = {}
  }
end

function ProtoMessage:newPlayerSubTaskInfo_TaskTokenOwnedInfo()
  return {task_token_id = nil, task_token_get_time = nil}
end

function ProtoMessage:newPlayerSubTaskInfo_SubTaskTokenGrantInfo()
  return {sub_task_id = nil, grant_times = nil}
end

function ProtoMessage:newPlayerSubTaskInfo_SubTaskTokenTriggeredTaskInfo()
  return {triggered_task_id = nil, triggered_sub_task_token_id = nil}
end

function ProtoMessage:newPlayerSubTaskInfo()
  return {
    last_refresh_time = nil,
    random_sub_task_id = {},
    ongoing_sub_task_info = {},
    last_notify_time = nil,
    last_get_time = nil,
    task_token_owned_info = {},
    sub_task_token_grant_info = {},
    sub_task_finished_times = nil,
    sub_task_finished_queue = {},
    sub_task_bonus_num = nil,
    sub_task_token_triggered_task_info = {}
  }
end

function ProtoMessage:newPlayerTaskInfo()
  return {
    id = nil,
    state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT,
    open_time = nil,
    done_time = nil,
    task_target_list = {},
    done_count = nil,
    is_trace = nil,
    state_change = nil,
    is_track = nil,
    pet_gid = nil,
    new_task = nil,
    hide = nil
  }
end

function ProtoMessage:newTaskSummaryList()
  return {
    summary_data = {}
  }
end

function ProtoMessage:newTaskSwitchConditionInfo()
  return {
    type = nil,
    data1 = nil,
    data2 = nil,
    switch_id = nil
  }
end

function ProtoMessage:newTaskSwitchConditionList()
  return {
    condition_data = {}
  }
end

function ProtoMessage:newPlayerTaskSwitchInfo()
  return {
    switch_id = nil,
    switch_times = nil,
    last_switch_update_time = nil
  }
end

function ProtoMessage:newPlayerTaskSwitchGroupInfo()
  return {
    group_id = nil,
    enable_swich_id = nil,
    task_switch_data = {}
  }
end

function ProtoMessage:newPlayerTaskSwitchData()
  return {
    task_switch_info = {},
    conditions = ProtoMessage:newTaskSwitchConditionList()
  }
end

function ProtoMessage:newPlayerInvestTaskData()
  return {
    invest_task_rand_time = nil,
    topic_task_list = {},
    special_reward_item = nil,
    clue_task_list = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityStageData_SubRewardData()
  return {
    stage_index = nil,
    is_reward_taken = nil,
    login_timestamp = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityStageData_SubData()
  return {
    activity_stage_id = nil,
    is_disposable_reward_taken = nil,
    reward_data = {},
    stage_timestamp = nil,
    open_timestamp = nil,
    enter_scene_time = nil,
    total_stage_days = nil,
    active = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityStageData()
  return {
    sub_stage_data = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPartData_ActivityPartParam()
  return {param1 = nil, param2 = nil}
end

function ProtoMessage:newPlayerActivityInfo_ActivityPartData()
  return {
    activity_part_id = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE,
    param = ProtoMessage:newPlayerActivityInfo_ActivityPartData_ActivityPartParam(),
    open_timestamp = nil,
    last_refresh_time = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetCatchData()
  return {
    points = nil,
    received_rewards_index = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityShinyPetDayData()
  return {
    activity_sub_id = nil,
    total_catch_num = nil,
    frist_caught_ranking = nil,
    frist_caught_timestamp = nil,
    frist_caught_camp = nil,
    shiny_caught_timestamps = {},
    received_reward = nil,
    expired = nil,
    flower_seed_content_id = nil,
    petaled = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ChallengeTarget()
  return {
    target_id = nil,
    is_finish = nil,
    temp_state = ProtoEnum.BattleTaskState.BTS_UNKNOW
  }
end

function ProtoMessage:newPlayerActivityInfo_ChallengePetUseRate()
  return {pet_base_id = nil, use_rate = nil}
end

function ProtoMessage:newPlayerActivityInfo_ChallengeLevel()
  return {
    challenge_id = nil,
    is_finish = nil,
    targets = {},
    take_times = nil,
    finish_timestamp = nil,
    level_number = nil,
    is_unlock = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ChallengeReward()
  return {
    star_required_num = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    reward_id = nil,
    magic_lv_required = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityNpcChallengeData_Module()
  return {
    module_id = nil,
    levels = {},
    is_readed = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityNpcChallengeData()
  return {
    event_id = nil,
    modules = {},
    rewards = {},
    perfect_level_number = nil,
    last_level_id = nil,
    pet_use_rate = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityBossChallengeData()
  return {
    event_id = nil,
    levels = {},
    rewards = {},
    buff_rule_id = nil,
    perfect_level_number = nil,
    last_level_id = nil,
    pet_use_rate = {},
    battle_round = nil,
    weakness_attack_count = nil,
    enter_battle_pet_gids = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeTeam()
  return {
    pet_conf_id = {},
    total_cheer_point = nil,
    pet_gid = {},
    team_id = nil,
    photo = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeDataPhoto(),
    fashion_ids = {},
    salon_item_data = {},
    wearing_item = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeDataPhoto()
  return {
    photo_template_id = nil,
    pet_conf_id = {},
    pet_gid = {},
    timestamp = nil,
    anime_percent = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeInfo()
  return {
    challenge_id = nil,
    is_clear = nil,
    highest_cheer_point = nil,
    challenge_times = nil,
    target_cheer_point = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_WeeklyChallengeEquipSkill()
  return {
    pet_gid = nil,
    equip_infos = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeData()
  return {
    event_id = nil,
    challenge_info = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeInfo(),
    rewards = {},
    pet_use_rate = {},
    pet_teams = {},
    team_photo = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeTeam(),
    photo_cheer_point_required = nil,
    equip_skills = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_TerritoryTrialInfo()
  return {
    challenge_id = nil,
    highest_score = nil,
    least_finish_round = nil,
    battle_conf_id = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityTerritoryTrialData()
  return {
    base_id = nil,
    trial_info = ProtoMessage:newPlayerActivityInfo_TerritoryTrialInfo(),
    rewards = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityTreasureHuntData_TreasureData()
  return {
    activity_sub_id = nil,
    reward_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    ride_pet_unlock = {},
    is_enter = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityTreasureHuntData()
  return {
    treasure_data = {},
    unlock = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityUpData_HatchUpStats()
  return {
    egg_id = nil,
    pet_id = nil,
    hatch_finish_time = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityUpData()
  return {
    last_hatch_up_sec = nil,
    hatch_up_stats = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityFlowerAppearData()
  return {
    activity_sub_id = nil,
    flower_seed_content_id = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetCollectionData_Reward()
  return {pet_base_id = nil, reward_type = nil}
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetCollectionData()
  return {
    disposable_reward_taken_time = nil,
    collection_pet = {},
    pet_rewards = {}
  }
end

function ProtoMessage:newActivityScoreRewardItemData()
  return {
    activity_rewards_index = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
  }
end

function ProtoMessage:newActivityScoreRewardCompData()
  return {
    reward_data = {}
  }
end

function ProtoMessage:newPetPartnerItem()
  return {
    pet_base_id = nil,
    egg_id = nil,
    color_random_id = nil,
    particle_random_id = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPartnerData()
  return {
    inherit_pet_data = ProtoMessage:newPetData(),
    pet_partner_items = {},
    select_pet_base_id = nil,
    committed = nil,
    choose_inherit_pet = nil,
    maintain_expression = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivitySpringFestivalData()
  return {
    global_popularity_task_ids = {}
  }
end

function ProtoMessage:newActivityPetTripData_CurPetTripInfo()
  return {
    pet_base_id = nil,
    trip_start_time = nil,
    trip_max_time = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newActivityPetTripData_PetTripRecordInfo()
  return {
    pet_base_id = nil,
    trip_start_time = nil,
    trip_max_time = nil,
    trip_end_time = nil,
    get_happy_value = nil,
    pet_gid = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    mutation_type = nil
  }
end

function ProtoMessage:newActivityPetTripData_PetTripFormationInfo()
  return {
    pet_base_id = nil,
    pet_gid = nil,
    max_trip_time = nil,
    formation_time = nil
  }
end

function ProtoMessage:newActivityPetTripData_LotteryResult()
  return {
    result = nil,
    recieved_award = nil,
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_num = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetTripData()
  return {
    happy_value = nil,
    max_pet_num = nil,
    cur_pet_trip_info = {},
    pet_trip_record_info = {},
    pet_formation_info = {},
    auto_trip = nil,
    wish_choice = nil,
    received_reward_stage = nil,
    rel_wish_choice = nil,
    lottery_result = ProtoMessage:newActivityPetTripData_LotteryResult(),
    wish_shard_id = nil,
    rand_num = nil
  }
end

function ProtoMessage:newInviteeInfo()
  return {
    uin = nil,
    level = nil,
    platform_name = nil,
    platform_openid = nil,
    inviter_uin = nil,
    invite_ts = nil,
    register_ts = nil,
    part_id_claimed_list = {},
    last_update_ts = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityInviteRegisterData()
  return {
    invitee_list = {},
    inviter_uin = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityRecallStarlightData()
  return {open_timestamp = nil, is_show_recall_tag = nil}
end

function ProtoMessage:newRecallBPTask()
  return {
    task_id = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    is_daily = nil
  }
end

function ProtoMessage:newRecallBPReward()
  return {
    bp_level = nil,
    reward1_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    reward2_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityRecallBPData()
  return {
    open_timestamp = nil,
    bp_exp = nil,
    is_paid = nil,
    task_list = {},
    reward_list = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityRecallData()
  return {
    active = nil,
    recall_class = nil,
    open_timestamp = nil,
    close_timestamp = nil,
    is_disposable_reward_taken = nil,
    is_pet_egg_taken = nil,
    pet_egg_id = nil,
    begin_taskid = nil
  }
end

function ProtoMessage:newSeasonPreHeat_Section()
  return {
    idx = nil,
    statue = nil,
    finish_timestamp = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivitySeasonPreHeatData()
  return {
    activity_sub_id = nil,
    final_reward_status = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    section_list = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetCertificationData()
  return {
    activity_sub_id = nil,
    progress = nil,
    task_state = nil,
    choosen_certificate_pet = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPetPhotoData()
  return {
    already_taken_pets = {},
    is_disposable_reward_taken = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPhotoContest_Phase()
  return {
    phase_id = nil,
    photo_url = nil,
    photo_md5 = nil,
    mini_photo_url = nil,
    mini_photo_md5 = nil,
    total_like_count = nil,
    is_disposable_reward_taken = nil,
    total_hot_count = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivitySignRewardData()
  return {
    reward_obtainable = nil,
    reward_received_time = nil,
    last_reset_time = nil,
    pending_reward_count = nil,
    next_refresh_time = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityWeekendChallengeData()
  return {
    recommend_pet_teams = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityGlobalChallengeData_Progress()
  return {
    belong_sign = nil,
    progress = nil,
    received_challenge_ids = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityGlobalChallengeData()
  return {
    challenge_progress = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPhotoContest_PhotoInfo()
  return {
    uin = nil,
    recommend_time = nil,
    like_limit = nil,
    shard_id = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityPhotoContest()
  return {
    phases = {},
    current_phase_id = nil,
    recommend_count = nil,
    history_photos = {},
    last_recommend_time = nil,
    skip_count = nil,
    last_skip_time = nil,
    accuracy_score = nil,
    reward_ids = {},
    last_submit_time = nil,
    last_like_uin = nil,
    is_red_point_cleaned = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_PreDownloadData()
  return {
    resource_prepared = nil,
    already_download = nil,
    rewarded = nil,
    book_download = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityData()
  return {
    activity_id = nil,
    activity_type = ProtoEnum.ActivityType.ATP_ACTIVITY_SPECIAL,
    expired = nil,
    should_disppeared = nil,
    first_open = nil,
    activity_finish_time = nil,
    track_red_point_add_flag = nil,
    activity_unlock_advance = nil,
    lottery_result = nil,
    score_reward_comp_data = ProtoMessage:newActivityScoreRewardCompData(),
    login_accelerate_days = nil,
    last_refresh_content_timestamp = nil,
    popup_played = nil,
    activity_open_time = nil,
    stage_data = ProtoMessage:newPlayerActivityInfo_ActivityStageData(),
    part_data = {},
    legendary_battle_data = ProtoMessage:newPlayerActivityInfo_ActivityPartData(),
    pet_catch_data = ProtoMessage:newPlayerActivityInfo_ActivityPetCatchData(),
    limited_flower_seed_info = ProtoMessage:newPlayerLimitedFlowerSeedInfo(),
    shiny_pet_day_data = ProtoMessage:newPlayerActivityInfo_ActivityShinyPetDayData(),
    npc_challenge_data = ProtoMessage:newPlayerActivityInfo_ActivityNpcChallengeData(),
    boss_challenge_data = ProtoMessage:newPlayerActivityInfo_ActivityBossChallengeData(),
    treasure_hunt_data = ProtoMessage:newPlayerActivityInfo_ActivityTreasureHuntData(),
    up_data = ProtoMessage:newPlayerActivityInfo_ActivityUpData(),
    flower_appear_data = ProtoMessage:newPlayerActivityInfo_ActivityFlowerAppearData(),
    weekly_challenge_data = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeData(),
    pet_collection_data = ProtoMessage:newPlayerActivityInfo_ActivityPetCollectionData(),
    season_checkin_data = ProtoMessage:newPlayerActivityInfo_ActivitySeasonCheckinData(),
    drop_data = ProtoMessage:newPlayerActivityInfo_ActivityDrop(),
    inherit_pet_data = ProtoMessage:newPlayerActivityInfo_ActivityInheritPetData(),
    co_creation_data = ProtoMessage:newPlayerActivityInfo_ActivityCoCreation(),
    mix_data = ProtoMessage:newPlayerActivityInfo_ActivityMixData(),
    cond_group_data = ProtoMessage:newPlayerActivityInfo_ActivityConditionGroupData(),
    pet_partner_data = ProtoMessage:newPlayerActivityInfo_ActivityPartnerData(),
    spring_festival_data = ProtoMessage:newPlayerActivityInfo_ActivitySpringFestivalData(),
    season_preheat_data = ProtoMessage:newPlayerActivityInfo_ActivitySeasonPreHeatData(),
    invite_register_data = ProtoMessage:newPlayerActivityInfo_ActivityInviteRegisterData(),
    territory_trial_data = ProtoMessage:newPlayerActivityInfo_ActivityTerritoryTrialData(),
    pet_photo_data = ProtoMessage:newPlayerActivityInfo_ActivityPetPhotoData(),
    pet_certification_data = ProtoMessage:newPlayerActivityInfo_ActivityPetCertificationData(),
    photo_contest_data = ProtoMessage:newPlayerActivityInfo_ActivityPhotoContest(),
    global_challenge_data = ProtoMessage:newPlayerActivityInfo_ActivityGlobalChallengeData(),
    sign_reward_data = ProtoMessage:newPlayerActivityInfo_ActivitySignRewardData(),
    weekend_challenge_data = ProtoMessage:newPlayerActivityInfo_ActivityWeekendChallengeData(),
    pet_trip_data = ProtoMessage:newPlayerActivityInfo_ActivityPetTripData(),
    recall_starlight_data = ProtoMessage:newPlayerActivityInfo_ActivityRecallStarlightData(),
    recall_bp_data = ProtoMessage:newPlayerActivityInfo_ActivityRecallBPData(),
    recall_data = ProtoMessage:newPlayerActivityInfo_ActivityRecallData(),
    base_mix_data = ProtoMessage:newPlayerActivityInfo_ActivityBaseMixData(),
    pre_download_data = ProtoMessage:newPlayerActivityInfo_PreDownloadData()
  }
end

function ProtoMessage:newPlayerActivityInfo()
  return {
    activity_data = {},
    last_enter_scene_timestamp = nil,
    login_days = nil,
    login_seconds = nil,
    login_single_seconds = nil,
    lost_days = nil,
    last_record_login_day_timestamp = nil,
    npc_challenge_perfect_level_number = nil,
    boss_challenge_perfect_level_number = nil,
    photos = {},
    login_history = ProtoMessage:newPlayerActivityLoginHistory()
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivitySeasonCheckinRewardData()
  return {
    activity_rewards_index = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivitySeasonCheckinData()
  return {
    act_task_list = {},
    reward_data = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityDropItem()
  return {
    item_id = nil,
    item_type = nil,
    item_num_today = nil,
    item_num_total = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityDropOnlineInfo()
  return {
    drop_method_id = nil,
    enter_timestamp = nil,
    online_time = nil,
    last_check_timestamp = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityDropGroup()
  return {
    method_id = nil,
    drop_item_list = {},
    reach_daily_limit = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityDrop()
  return {
    method_drop_list = {},
    online_list = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityCoCreation()
  return {
    first_caught_ranking = nil,
    first_caught_timestamp = nil,
    emoj_type = nil,
    caught_camp = {},
    reward_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    supply_egg_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    task_reward_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    emoj_list = {}
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityInheritPetData()
  return {
    inherit_pet_info = ProtoMessage:newPetBriefInfo(),
    add_redpoint = nil,
    first_uploaded = nil,
    reserved1 = nil
  }
end

function ProtoMessage:newBattleFieldItem()
  return {
    battle_id = nil,
    finish = nil,
    factions = {}
  }
end

function ProtoMessage:newNpcChallengeItem()
  return {
    id = nil,
    battle_field_items = {}
  }
end

function ProtoMessage:newFinishFactionItem()
  return {
    faction = ProtoEnum.ActivityFaction.FACTION_NONE,
    finish_time = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityMixData()
  return {
    faction = ProtoEnum.ActivityFaction.FACTION_NONE,
    refresh_time = nil,
    next_refresh_time = nil,
    main_task_id = nil,
    optional_task_id = {},
    remain_refresh_times = nil,
    npc_challenge_items = {},
    init_faction = nil,
    finished_faction = {},
    can_choose_new_faction = nil,
    experience_card_popup = nil,
    all_finish = nil,
    finish_task_id = {},
    faction_rank_settled = nil,
    first_choose_faction = ProtoEnum.ActivityFaction.FACTION_NONE
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityBaseMixSlotData()
  return {
    slot_id = nil,
    slot_part_datas = {},
    slot_function_type = nil,
    state = ProtoEnum.PlayerActivityInfo.ActivityPartState.APS_NONE
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityBaseMixData()
  return {
    is_must_do_tasks_done = nil,
    slot_datas = {}
  }
end

function ProtoMessage:newPlayerActivityLoginHistory()
  return {
    history_data = {},
    last_record_day = nil
  }
end

function ProtoMessage:newActivityCoCreationEmojItem()
  return {emoj_type = nil, emoj_cnt = nil}
end

function ProtoMessage:newActivityCoCreationEmojInfo()
  return {
    emoj_list = {}
  }
end

function ProtoMessage:newBeastResonanceInfo()
  return {
    uin = nil,
    start_resonance_time = nil,
    ticket_id = nil,
    ticket_num = nil
  }
end

function ProtoMessage:newMinigameProgress()
  return {npc_cfg_id = nil, value = nil}
end

function ProtoMessage:newBossBattleRuleInfo()
  return {
    boss_obj_id = nil,
    rule_ids = {},
    level = nil
  }
end

function ProtoMessage:newSeasonPlayerGrowth()
  return {
    id = nil,
    pet_gid = nil,
    feature_skill_id = nil,
    new_pet_conf_id = nil
  }
end

function ProtoMessage:newSeasonPartData()
  return {part_id = nil, item_id = nil}
end

function ProtoMessage:newSeasonInfo()
  return {
    season_id = nil,
    season_kv_type = nil,
    popup_time = nil,
    boss_battle_rule_infos = {},
    light_growths = {},
    season_pve_id = nil,
    season_part_datas = {},
    season_pv_time = nil,
    season_pop_windows_time = nil,
    season_legendary_id = nil
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo_PreTaskInfo()
  return {
    task_id = nil,
    task_state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo_InvestTaskInfo()
  return {
    task_id = nil,
    task_state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo_SubTaskInfo()
  return {
    task_id = nil,
    task_target = nil,
    task_state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo_FinalTaskInfo()
  return {
    task_id = nil,
    task_target = nil,
    task_state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo_HandbookTaskInfo()
  return {
    pet_raise_task_id = nil,
    final_task_info = ProtoMessage:newPlayerLimitedFlowerSeedInfo_FinalTaskInfo(),
    sub_task_info = {}
  }
end

function ProtoMessage:newPlayerLimitedFlowerSeedInfo()
  return {
    spec_flower_seed_id = nil,
    pre_task_info = ProtoMessage:newPlayerLimitedFlowerSeedInfo_PreTaskInfo(),
    invest_task_info = {},
    handbook_task_info = {},
    flower_seed_content_id = nil
  }
end

function ProtoMessage:newPlayerGPContestInfo()
  return {
    gp_contest_state = nil,
    gp_contest_rank_id = nil,
    gp_num_victory = nil,
    gp_num_add = nil,
    reward_taken = {}
  }
end

function ProtoMessage:newPlayerLevelAwardInfo()
  return {
    valid_awards = {}
  }
end

function ProtoMessage:newClimbChapterItem()
  return {chapter_id = nil, now_finish_stage = nil}
end

function ProtoMessage:newPlayerClimbChapterInfo()
  return {
    chapter_list = {}
  }
end

function ProtoMessage:newPlayerAdventureChapterInfo()
  return {
    pet_id = nil,
    chapters = {}
  }
end

function ProtoMessage:newPlayerAdventureChapterList()
  return {
    open_chapter_list = {}
  }
end

function ProtoMessage:newPlayerAdventureData()
  return {
    open_chapter = nil,
    rewarded_chapter = {},
    chapters = {},
    open_chapters = ProtoMessage:newPlayerAdventureChapterList()
  }
end

function ProtoMessage:newPlayerShinyPetDayInfo()
  return {
    petal_num = nil,
    init = nil,
    last_refresh_timestamp = nil,
    total_double_times = nil,
    remaining_doule_times = nil,
    pre_deduct_double_times = nil,
    has_petal = nil,
    lock_activity = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ConditionGroupConditionData()
  return {
    condition_id = nil,
    reward_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN
  }
end

function ProtoMessage:newPlayerActivityInfo_ConditionGroupSingleData()
  return {
    group_id = nil,
    is_finish_all = nil,
    cond_data = {},
    is_unlock = nil
  }
end

function ProtoMessage:newPlayerActivityInfo_ActivityConditionGroupData()
  return {
    reward_state = ProtoEnum.PlayerActivityInfo.ActivityRewardState.ARS_UNOPEN,
    group_data = {}
  }
end

function ProtoMessage:newFactionRankInfo()
  return {
    rank_list = {}
  }
end

function ProtoMessage:newRankInfo()
  return {
    faction = ProtoEnum.ActivityFaction.FACTION_NONE,
    score = nil
  }
end

function ProtoMessage:newPlayerSeasonAdventureBadge()
  return {badge_lvl = nil}
end

function ProtoMessage:newPlayerSeasonAdventureChapter()
  return {
    chapter_id = nil,
    status = nil,
    normal_progress = nil,
    challenge_progress = nil
  }
end

function ProtoMessage:newSeasonAdventure()
  return {
    season_id = nil,
    chapter_list = {},
    badge_info = ProtoMessage:newPlayerSeasonAdventureBadge(),
    open_time = nil,
    settle_time = nil
  }
end

function ProtoMessage:newDumpSeasonAdventure()
  return {
    season_id = nil,
    badge_info = ProtoMessage:newPlayerSeasonAdventureBadge(),
    open_time = nil,
    settle_time = nil,
    normal_progress = nil,
    challenge_progress = nil,
    finish_chapter_cnt = nil
  }
end

function ProtoMessage:newPlayerSeasonAdventureData()
  return {
    cur_season = ProtoMessage:newSeasonAdventure(),
    dump_season_list = {}
  }
end

function ProtoMessage:newBattleBuffBrefInfo()
  return {buff_id = nil, stack = nil}
end

function ProtoMessage:newTerritoryTrialPetInfo()
  return {
    defeat_point = nil,
    guard_entrys = {},
    is_boss = nil
  }
end

function ProtoMessage:newPetRealInfo()
  return {
    conf_id = nil,
    base_conf_id = nil,
    name = nil
  }
end

function ProtoMessage:newMonsterCreateInfo()
  return {
    conf_id = nil,
    ball_id = nil,
    success_catch_cnt = nil,
    battler_id = nil,
    handbook_threshold = nil,
    handbook_prob_add = nil,
    last_catch_time = nil,
    catch_guarantee_rate = nil,
    npc_obj_id = nil,
    cheer_info = ProtoMessage:newCheerMonsterInitInfo(),
    buff_infos = {},
    belong_camp = nil,
    trial_pet_info = ProtoMessage:newTerritoryTrialPetInfo()
  }
end

function ProtoMessage:newBattleNpcInfo()
  return {
    npc_obj_id = nil,
    last_catch_time = nil,
    catch_guarantee_rate = nil,
    buff_info = {},
    belong_camp = nil,
    creater_uin = nil,
    is_continous_catch_bonus = nil,
    create_visiting_uins = {},
    owner_uin = nil,
    npc_refresh_conf_id = nil,
    season_add_info = ProtoMessage:newSeasonBattleInfo()
  }
end

function ProtoMessage:newKillPetRoundData()
  return {cur_round = nil, cast_skill_count = nil}
end

function ProtoMessage:newPetMedalConditionData()
  return {
    kill_pet_round_list = {},
    cast_skill_count = nil,
    kill_pet_role_hp_list = {},
    continuous_counter_count = nil,
    continuous_no_counter_count = nil,
    continuous_restraint_count = nil,
    continuous_resist_count = nil,
    kill_pet_up_evo = nil,
    kill_pet_same_evo = nil,
    killed_evolution_chains = {},
    win_energy = nil,
    win_hp_percent = nil,
    win_with_inverse_restraint = nil,
    win_caster_role_hp = nil,
    win_enemy_role_hp = nil,
    win_in_battle = nil,
    continuous_counter_cur_count = nil,
    continuous_no_counter_cur_count = nil,
    continuous_restraint_cur_count = nil,
    continuous_resist_cur_count = nil
  }
end

function ProtoMessage:newBattleMedalInfo()
  return {medal_id = nil, param = nil}
end

function ProtoMessage:newBattleMonsterInfo()
  return {
    state = ProtoEnum.BATTLE_MONSTER_RESULT_TYPE.BATTLE_MONSTER_DEFEATED,
    level = nil,
    pet_gid = nil,
    catched_uin = nil,
    caught_monster = ProtoMessage:newPetData(),
    killed_uin = nil,
    sleep = nil,
    world_hide = nil,
    battled = nil,
    conf_id = nil,
    petbase_id = nil,
    uin = nil,
    ori_back_of_head = nil,
    ori_ai_status = nil,
    npc_obj_id = nil,
    killed_pet_gid = nil,
    killed_pet_type = {},
    remain_hp = nil,
    max_hp = nil,
    last_catch_time = nil,
    catch_guarantee_rate = nil,
    remain_buff_infos = {},
    damage_out = nil,
    raw_skill_damage_taken = nil,
    pet_owner_name = nil,
    pet_name = nil,
    mutation_type = nil,
    lowest_hp = nil,
    skill_records = {},
    killed_seq = nil,
    side = nil,
    caught_with_uins = {},
    medal_cond_complete = {},
    kill_new_evo_chain = {},
    in_battle_when_finish = nil,
    pet_medal_cond_data = ProtoMessage:newPetMedalConditionData(),
    glass_info = ProtoMessage:newGlassInfo(),
    pet_id = nil,
    refresh_type = nil
  }
end

function ProtoMessage:newPvpNpcInfo()
  return {
    conf_id = nil,
    name = nil,
    sex = nil,
    fashion = {},
    icon = nil,
    wearing_item = {}
  }
end

function ProtoMessage:newPvpModeCtl()
  return {
    mode = nil,
    matched = nil,
    pvp_id = nil,
    match_infos = {},
    pkagain_cnt = nil,
    welfare_team = {},
    welfare_team_role_magic_id = nil,
    welfare_enemy_pvp_rank_star = nil,
    welfare_enemy_pvp_rank_order = nil,
    welfare_enemy_pvp_rank_name = nil,
    show_enemy_pet = nil,
    light_pk = nil
  }
end

function ProtoMessage:newPvpFightHis_PetInfo()
  return {
    pet_base_id = nil,
    mutation_type = nil,
    pet_level = nil,
    type = ProtoMessage:newPetTypeInfo()
  }
end

function ProtoMessage:newPvpFightHis()
  return {
    enemy = ProtoMessage:newPlayerBriefInfo(),
    enemy_fashion = ProtoMessage:newBattleFashionInfo(),
    npc_enemy = ProtoMessage:newPvpNpcInfo(),
    pvp_rank_star = nil,
    pvp_rank_order = nil,
    result = nil,
    pet_info = {},
    pet_info_self = {},
    pvp_rank_star_self = nil,
    pvp_rank_order_self = nil,
    start_time = nil,
    season_id = nil
  }
end

function ProtoMessage:newPvpRecord_RedPointHistory()
  return {week_win_count = nil, pvp_rank_star = nil}
end

function ProtoMessage:newEffectRecord()
  return {
    uin = nil,
    effect_id = nil,
    result0 = nil,
    result1 = nil,
    result2 = nil
  }
end

function ProtoMessage:newBattlerSettleInfo()
  return {
    id = nil,
    conf_id = nil,
    original_hp = nil,
    hp = nil,
    mod_hp = nil,
    last_damage_pet = nil,
    last_damage_pet_gid = nil,
    settle_hp_loss = nil
  }
end

function ProtoMessage:newBattlerUinBrief()
  return {
    mate_num = nil,
    mate_human_num = nil,
    mate_fri_num = nil,
    enemy_num = nil,
    enemy_human_num = nil,
    enemy_fri_num = nil,
    mate_uins = {},
    enemy_uins = {},
    his_observer_num = nil
  }
end

function ProtoMessage:newBattleAiStats()
  return {
    battle_role_hp = nil,
    pet_ids = {},
    pet_isalive = {},
    num_restraint = nil,
    num_berestraint = nil,
    num_resist = nil,
    num_beresist = nil,
    num_counter = nil,
    num_becounter = nil,
    total_damage_hp = {},
    total_bedamage_hp = {},
    extra_energy_buffs = {},
    extra_energy_buff_sum = {},
    extra_energy_debuffs = {},
    extra_energy_debuff_sum = {},
    num_in_battle = {}
  }
end

function ProtoMessage:newCostlyReward()
  return {reward_id = nil, costly_id = nil}
end

function ProtoMessage:newFightMemberInfo()
  return {
    uin = nil,
    pet_gid = nil,
    npc_id = nil,
    pet_conf_id = nil,
    pet_level = nil,
    help_conf_id = nil,
    team_idx = nil,
    pet_conf_ids = {}
  }
end

function ProtoMessage:newBloodPetFight()
  return {
    member_info = {},
    blood_pet_base_id = nil,
    flower_npc_level = nil,
    is_glass = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    is_shiny = nil,
    blood = nil,
    flower_catch_vitem = nil,
    battle_npc_lv = nil,
    battle_npc_hp_talent = nil,
    battle_npc_attack_talent = nil,
    battle_npc_special_attack_talent = nil,
    battle_npc_defense_talent = nil,
    battle_npc_special_defense_talent = nil,
    battle_npc_speed_talent = nil,
    battle_npc_gender = nil,
    battle_npc_nature = nil,
    catch_vitem_quantity = nil,
    spec_flower_seed_id = nil,
    activity_id = nil,
    is_first_catch = nil,
    star = nil,
    cli_startup_channel = nil,
    battle_tasks = {},
    bind_pet_gid = nil,
    owner_uin = nil,
    medal_id = nil
  }
end

function ProtoMessage:newPlayerZoneId()
  return {
    uin = nil,
    zone_inst_id = nil,
    npc_id = nil
  }
end

function ProtoMessage:newCreateBattleInfo_DoubleInteract()
  return {
    type = nil,
    mate_uins = {}
  }
end

function ProtoMessage:newBadgeChallengeInfo()
  return {
    upgrade_ids = {},
    pet_level = nil,
    incident_type = nil,
    battle_pet_num = nil,
    defend_pet_num = nil
  }
end

function ProtoMessage:newGmBattleNpc()
  return {
    npc_cfg_id = nil,
    monster_ids = {},
    fashion_id = nil,
    sex = nil
  }
end

function ProtoMessage:newGrassBadgeTrialInfo()
  return {pet_gid = nil, energy_ceiling = nil}
end

function ProtoMessage:newWorldCombatExtraReward()
  return {
    uin = nil,
    extra_reward_types = {}
  }
end

function ProtoMessage:newCreateBattleInfo()
  return {
    battle_conf_id = nil,
    option_id = nil,
    battle_type = nil,
    attackers = {},
    defenders = {},
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    npc_obj_id = {},
    npc_conf_id = nil,
    npc_logic_id = nil,
    npc_refresh_conf_id = nil,
    npc_level = nil,
    npc_pos = ProtoMessage:newPosition(),
    npc_born_pos = ProtoMessage:newPosition(),
    ai_status = nil,
    sleeping = nil,
    back_of_head = nil,
    new_skill = nil,
    pre_act_tag = nil,
    pre_act_param = nil,
    rand_num = nil,
    water_battle_type = nil,
    pvp_mode = ProtoMessage:newPvpModeCtl(),
    battle_center = ProtoMessage:newPosition(),
    enter_battle_type = nil,
    tod = nil,
    npc_infos = {},
    monster_diff_info = ProtoMessage:newMonsterDiffInfo(),
    onlooker_npcs = {},
    cheer_npc_info = {},
    monster_leader_conf_id = {},
    blood_pet_fight = ProtoMessage:newBloodPetFight(),
    beast_pet_fight = ProtoMessage:newBeastPetFight(),
    world_leader_fight = ProtoMessage:newWorldLeaderFight(),
    pve_add_info = ProtoMessage:newBattlePveInfo(),
    world_combat_extra_reward_types = {},
    is_in_dungeon = nil,
    double_interact = ProtoMessage:newCreateBattleInfo_DoubleInteract(),
    del_npc_aft_win = nil,
    battle_radius = nil,
    battle_difficult_id = nil,
    season_add_info = ProtoMessage:newSeasonBattleInfo(),
    visit_uins = {},
    uin = nil,
    bfid = nil,
    replay_bfid = nil,
    role_level = nil,
    monster_info = {},
    creater_world_lv = nil,
    rotate = nil,
    pvp_npcs = {},
    team_type = ProtoEnum.PlayerTeamType.PTT_INVALID,
    badge_challenge = ProtoMessage:newBadgeChallengeInfo(),
    dynamic_pve_npcs = {},
    pve_season_info = ProtoMessage:newPveSeasonInfo(),
    battle_game_time = nil,
    start_time = nil,
    final_battle_summon_time = nil,
    disable_hp_dec = nil,
    disable_anti_cheat = nil,
    ai_training = nil,
    guide_battle = nil,
    dynamic_attacker_npcs = {},
    grass_trial_info = ProtoMessage:newGrassBadgeTrialInfo(),
    monster_pet_base_id_list = {}
  }
end

function ProtoMessage:newBattleTaskInfo()
  return {
    task_id = nil,
    task_state = nil,
    uin = nil
  }
end

function ProtoMessage:newBattlePveInfo()
  return {
    task_infos = {},
    challenge_level_id = nil,
    npc_id = nil,
    appearance_info = {},
    rule_ids = {},
    buff_id = nil,
    activity_id = nil,
    pre_level_ids = {},
    is_unfinish = nil,
    round = nil,
    priority_pet_gid = nil,
    battler_remain_hp = nil,
    weakness_attack_count = nil,
    enter_battle_pet_gids = {},
    cheer_point = nil,
    cheer_point_this_week = nil,
    can_take_photo = nil,
    guide_id = nil,
    had_season_talent = nil,
    legendary_battle_id = nil
  }
end

function ProtoMessage:newBattleSettleInfo_DoubleInteract()
  return {
    type = nil,
    mate_uin = nil,
    mate_name = nil,
    zone_inst_id = nil,
    is_mate_creater = nil,
    mate_level = nil
  }
end

function ProtoMessage:newTerritoryTrialSettleInfo()
  return {
    total_point = nil,
    defeat_num = nil,
    defeat_point = nil,
    remain_round = nil,
    round_point = nil,
    used_round = nil
  }
end

function ProtoMessage:newMagicUsedInfo()
  return {player_skill_id = nil, use_times = nil}
end

function ProtoMessage:newBattleSettleInfo()
  return {
    battle_conf_type = nil,
    battle_opposite_type = nil,
    real_pve = nil,
    real_pvp = nil,
    pvp_mode = ProtoMessage:newPvpModeCtl(),
    flower_npc_level = nil,
    result = ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_NULL,
    battle_conf_id = nil,
    monster_info = {},
    interact_npc_id = nil,
    escape_style = nil,
    skill_records = {},
    effect_records = {},
    mod_hp = nil,
    is_surrender = nil,
    battle_id = nil,
    battler_info = {},
    uin_brief = ProtoMessage:newBattlerUinBrief(),
    battle_refresh_content = nil,
    guide_type = nil,
    kill_pet_num = nil,
    ai_stats_info = ProtoMessage:newBattleAiStats(),
    costly_reward = {},
    is_reward = nil,
    visit_owner_name = nil,
    is_in_dungeon = nil,
    pve_add_info = ProtoMessage:newBattlePveInfo(),
    interact_npc_content_id = nil,
    pk_again = nil,
    is_badge_challenge = nil,
    is_first_settle = nil,
    retreat_pet_cnt = nil,
    magic_used = {},
    side = nil,
    rounds = nil,
    seconds = nil,
    ride_id = nil,
    catch_info = {},
    double_interact = ProtoMessage:newBattleSettleInfo_DoubleInteract(),
    daily_pvp_first_win = nil,
    battle_tasks = {},
    battle_difficult_id = nil,
    trial_settle_info = ProtoMessage:newTerritoryTrialSettleInfo(),
    enter_battle_time = nil,
    npc_option_id = nil
  }
end

function ProtoMessage:newInnerBattlePetDisplay()
  return {
    owner_obj_id = nil,
    conf_id = nil,
    nature = nil,
    base_conf_id = nil,
    height = nil,
    weight = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    npc_obj_id = nil,
    battle_pet_id = nil,
    ball_id = nil
  }
end

function ProtoMessage:newInnerBattleInfo()
  return {
    battle_state = ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IDLE,
    world_npc_obj_id = nil,
    side_a_pets = {},
    side_b_pets = {},
    bfd_id = nil,
    battle_conf_id = nil
  }
end

function ProtoMessage:newBattlerNumInfo()
  return {
    mate_num = nil,
    mate_human_num = nil,
    mate_fri_num = nil,
    enemy_num = nil,
    enemy_human_num = nil,
    enemy_fri_num = nil
  }
end

function ProtoMessage:newSourceData()
  return {
    source_type = ProtoEnum.EClientBattleSourceType.ECBST_NONE,
    chapter_id = nil,
    stage_id = nil,
    activity_id = nil,
    challenge_module_id = nil,
    challenge_level_id = nil
  }
end

function ProtoMessage:newBeastPetFight()
  return {
    member_info = {},
    star = nil,
    battle_cfg_id = nil,
    re_entrant = nil,
    ball_num = nil,
    boss_shiny = nil,
    boss = ProtoMessage:newPetData(),
    last_state = nil,
    last_catch_time = nil,
    prev_guarantee_rate = nil,
    is_perform = nil,
    activity_id = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    is_season_battle = nil,
    resonance_infos = {}
  }
end

function ProtoMessage:newBattleOnlookerMonster()
  return {
    base_conf_id = nil,
    nature = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newOnlookerNpcInfo()
  return {
    npc_conf_id = nil,
    npc_obj_id = nil,
    npc_logic_id = nil,
    monster = ProtoMessage:newBattleOnlookerMonster()
  }
end

function ProtoMessage:newBattleFinishPetInfo()
  return {
    pet_gid = nil,
    remain_hp = nil,
    remain_energy = nil,
    mod_energy = nil,
    battle_max_hp = nil,
    uin = nil
  }
end

function ProtoMessage:newWorldLeaderFight()
  return {
    npc_hp = nil,
    npc_hp_max = nil,
    stun_buff_remain_time = nil,
    gain_expose = {},
    npc_lowest_hp = nil,
    round = nil,
    visitor_num = nil,
    world_owner_level = nil,
    world_owner_world_lv = nil,
    cur_gain_expose = ProtoEnum.WorldcombatDoubleBuff.WDB_HP,
    finish_pet_infos = {}
  }
end

function ProtoMessage:newPveSeasonInfo()
  return {
    boss_rule_ids = {},
    player_buffs = {},
    player_feature_skill = {},
    player_attribute_add = {},
    bag_buffs = {},
    player_pet_add = {},
    season_battle_id = nil
  }
end

function ProtoMessage:newBattleWeatherChangeInfo()
  return {
    type = {},
    layer = {}
  }
end

function ProtoMessage:newBeastCatchResult()
  return {
    waiting_catch = nil,
    start_resonance_time = nil,
    high_select_star = nil
  }
end

function ProtoMessage:newMonsterCatchGuaranteeInfo()
  return {
    npc_obj_id = nil,
    last_catch_time = nil,
    catch_guarantee_rate = nil
  }
end

function ProtoMessage:newBossNpcInfos()
  return {
    boss_npcs = {},
    remain_time = nil,
    available_challenge_num_via_star = nil
  }
end

function ProtoMessage:newBossNpcInfo()
  return {
    npc_cfg_id = nil,
    star = nil,
    blood = nil,
    battle_petbase_id = nil,
    npc_logic_id = nil,
    npc_obj_id = nil,
    content_cfg_id = nil,
    mutation_type = nil,
    end_timestamp = nil,
    spec_flower_seed_id = nil,
    activity_id = nil,
    camp_cfg_id = nil,
    pos = ProtoMessage:newPosition(),
    level = nil,
    status = nil,
    next_refresh_time = nil,
    world_map_cfg_id = nil,
    is_camp_unlock = nil,
    season_battle_rules = {},
    is_world_boss_defeated = nil,
    battle_tasks = {},
    visit_flower_seed_boss_datas = {},
    select_flower_owner_id = nil
  }
end

function ProtoMessage:newPkPetData()
  return {
    adjusted = nil,
    pet_data = ProtoMessage:newPetData(),
    base_conf_id = nil
  }
end

function ProtoMessage:newPlayerPkInfo_EnemyPetInfo()
  return {
    level = nil,
    petbase_id = nil,
    mutation_type = nil,
    name = nil,
    skill_dam_type = {},
    last_breakthrough_lv = nil,
    feature_skill = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    type = ProtoMessage:newPetTypeInfo(),
    gid = nil,
    hp_max = nil
  }
end

function ProtoMessage:newPlayerPkInfo()
  return {
    self_state = ProtoEnum.PlayerPkState.PPS_NONE,
    enemy = ProtoMessage:newPlayerBriefInfo(),
    enemy_state = ProtoEnum.PlayerPkState.PPS_NONE,
    start_time = nil,
    end_time = nil,
    first_pet_gid = nil,
    pets = {},
    self_hp = nil,
    enemy_hp = nil,
    self_cancel = nil,
    enemy_cancel = nil,
    enemy_fashion = ProtoMessage:newBattleFashionInfo(),
    flag = nil,
    pvp_id = nil,
    match_infos = {},
    pkagain_cnt = nil,
    npc_enemy = ProtoMessage:newPvpNpcInfo(),
    npc_confirm_ut = nil,
    seq_num = nil,
    enemy_pvp_rank_star = nil,
    enemy_pvp_rank_order = nil,
    welfare_team = {},
    pve_battle_conf_id = nil,
    battle_cfg_id = nil,
    battle_center = ProtoMessage:newPlayerSceneInfo(),
    backup_scene = ProtoMessage:newPlayerSceneInfo(),
    online = nil,
    enemy_pets = {},
    show_enemy_pet = nil,
    teleport_back_cnt = nil,
    role_magic_gid = nil,
    welfare_team_role_magic_id = nil,
    is_mirror = nil,
    mirror_magic_id = nil,
    bfid = nil,
    rotate = nil,
    light_pk = nil,
    light_pk_option_id = nil
  }
end

function ProtoMessage:newPvpRecord()
  return {
    pvp_id = nil,
    team_type = nil,
    k = nil,
    r = nil,
    rd = nil,
    vol = nil,
    pvp_score = nil,
    next_refresh_time = nil,
    battle_count = nil,
    win_count = nil,
    lose_count = nil,
    draw_count = nil,
    freq_base_id = nil,
    kill_pet_num = nil,
    win_streak = nil,
    lose_streak = nil,
    fight_his = {},
    week_win_count = nil,
    week_refresh_ut = nil,
    received_season_awards = {},
    received_week_awards = {},
    rank_season_id = nil,
    rd_history = ProtoMessage:newPvpRecord_RedPointHistory(),
    trial_pet = ProtoMessage:newTrialPet(),
    matched_uins = {},
    his_rts = {},
    season_max_rank_star = nil,
    last_warm_pvp_time = nil,
    prof_score = nil,
    last_finish_game_time = nil,
    magic_used = {},
    season_battle_count = nil,
    season_win_count = nil,
    season_max_win_streak = nil,
    prev_season_star = nil,
    pvp_win_or_lose_streak = nil,
    same_team_mute_groups = {}
  }
end

function ProtoMessage:newPlayerPvpData_BaseId2Cnt()
  return {base_id = nil, cnt = nil}
end

function ProtoMessage:newRankSeasonInfo()
  return {
    season_id = nil,
    battle_cnt = nil,
    win_count = nil,
    max_win_streak = nil,
    pet_use_info = {},
    magic_used = {},
    rank_star = nil,
    rank_order = nil,
    master_score = nil
  }
end

function ProtoMessage:newTopMasterRankInfo()
  return {
    last_query_time = nil,
    top_master_order = nil,
    last_display_type = nil
  }
end

function ProtoMessage:newPvpPetDamageInfo()
  return {idx = nil, damage_out = nil}
end

function ProtoMessage:newPlayerPvpData()
  return {
    pvp_his_cli = ProtoMessage:newPlayerPvpHisCli(),
    pet_base_id2cnt = {},
    records = {},
    pvp_score = nil,
    next_refresh_time = nil,
    received_awards = {},
    pk_info = ProtoMessage:newPlayerPkInfo(),
    daily_pvp_first_win_time = nil,
    last_pvp_battle_ai_desc = nil,
    last_battle_pvp_type = nil,
    rank_season_infos = {},
    last_warm_pvp_time = nil,
    top_master_rank_info = ProtoMessage:newTopMasterRankInfo(),
    pet_damage_info = {}
  }
end

function ProtoMessage:newSpecBattleDifficultyItemInfo()
  return {item_id = nil, win_times = nil}
end

function ProtoMessage:newSpecBattleDifficultyInfo()
  return {
    battle_difficulty_id = nil,
    won_battle_cfg_ids = {},
    won_difficults = {}
  }
end

function ProtoMessage:newBattleSupplyPetPlayerInfo()
  return {
    player_id = nil,
    pet_infos = {}
  }
end

function ProtoMessage:newBattleSupplyPetInfo()
  return {
    pet_id = nil,
    pet_pos = nil,
    pet_info = ProtoMessage:newBattlePetInfo()
  }
end

function ProtoMessage:newBattleCarryonBuffInfo()
  return {
    carryon_id = nil,
    carryon_equip_idx = nil,
    remain_stack = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newSkillCastRecord()
  return {
    caster = nil,
    target = nil,
    skill_id = nil,
    cost_energy = nil,
    cost_hp = nil,
    damage_param = nil,
    round = nil,
    damage_type = nil,
    is_caster_dead = nil,
    is_counter = nil,
    is_rapid_skill = nil,
    is_cmd_skill = nil,
    is_real_cast = nil,
    is_charging = nil,
    restraint_param = ProtoEnum.SkillRestraintType.SRT_RESTRAINTED_ONE,
    is_effect33_pull_up_skill = nil,
    extra_damage_type = {},
    perform_flag = nil,
    is_award_cast = nil,
    adapt_damage_type = nil,
    original_skill_id = nil,
    season_id = nil
  }
end

function ProtoMessage:newRoleMagicRecord()
  return {
    caster_uin = nil,
    skill_id = nil,
    caster_pet = nil,
    round = nil
  }
end

function ProtoMessage:newBuffRecord()
  return {
    caster = nil,
    target = nil,
    buff_id = nil,
    stack = nil,
    source = nil,
    round = nil
  }
end

function ProtoMessage:newDamageRecord()
  return {
    caster = nil,
    target = nil,
    damage = nil,
    source = nil,
    dam_type = nil,
    round = nil,
    is_critical = nil,
    is_shield = nil,
    damage_param = nil
  }
end

function ProtoMessage:newChangePetRecord()
  return {
    down_pet = nil,
    up_pet = nil,
    round = nil
  }
end

function ProtoMessage:newBattleOpHistory()
  return {
    skills = {},
    change_pets = {},
    buffs = {},
    damages = {},
    role_magics = {}
  }
end

function ProtoMessage:newBattleBuffInfo()
  return {
    caster_id = nil,
    buff_id = nil,
    append_round = nil,
    stack = nil,
    cast_moment = nil,
    buff_type = nil,
    last_stack_change_round = {},
    down_round = nil,
    up_round = nil,
    act_count = nil,
    last_trigger_round = nil,
    real_trigger_round = nil,
    is_from_glue_skill = nil,
    from_skill_id = nil,
    buff_data = {},
    append_history = {},
    carryon_info = {},
    desc_param_1 = {},
    desc_param_2 = {},
    group_sign = {},
    event_mark = nil,
    last_stack_append_round = nil,
    skill_count = nil,
    is_hidden = nil,
    hidden_stack = nil,
    pos = nil,
    data = ProtoMessage:newBuffRunningData(),
    del_flag = nil,
    buff_on_field_round = nil,
    buff_left_round = nil,
    last_change_buff_left_round = nil,
    virtual_caster = nil
  }
end

function ProtoMessage:newBattleEffectInfo()
  return {
    effect_id = nil,
    cast_moment = nil,
    result_type = nil,
    result_data1 = nil,
    result_data2 = nil,
    result_arr = {},
    result_arr2 = {},
    process_state = nil,
    trigger_skill_id = nil,
    trigger_skill_target = nil
  }
end

function ProtoMessage:newBattlePetSkillInfo()
  return {
    skill_cfg_id = nil,
    skill_limit = nil,
    skill_pp = nil
  }
end

function ProtoMessage:newDamageParam()
  return {pet_id = nil, damage_param = nil}
end

function ProtoMessage:newRestraintType()
  return {pet_id = nil, restraint_type = nil}
end

function ProtoMessage:newSkillCDInfo()
  return {buff_id = nil, value = nil}
end

function ProtoMessage:newEnhanceEffectInfo()
  return {
    effect_id = nil,
    target_type = nil,
    cm = nil,
    add_round = nil
  }
end

function ProtoMessage:newSkillEnhanceInfo()
  return {
    buff_id = nil,
    buffbase_id = nil,
    effect_ids = {},
    cm = nil,
    tip_id = nil,
    skill_id = nil,
    stack = nil,
    skill_type = nil,
    effects = {},
    caster_pet_base_id = nil
  }
end

function ProtoMessage:newExtraDamTypeInfo()
  return {
    values = {},
    source = nil
  }
end

function ProtoMessage:newCRDamageParam()
  return {pet_id = nil, param = nil}
end

function ProtoMessage:newSkillBuffInfo()
  return {
    hp_per_energy = nil,
    damage_param = nil,
    damage_param_by = nil,
    energy_cost = nil,
    energy_cost_by = nil,
    multiply = nil,
    multiply_by = nil,
    priority = nil,
    cast_cnt = nil,
    trans_time = nil
  }
end

function ProtoMessage:newTransInfo()
  return {trans_time = nil, initial_pos = nil}
end

function ProtoMessage:newSetCostInfo()
  return {reason_id = nil, cost = nil}
end

function ProtoMessage:newPetSkillRoundData()
  return {
    id = nil,
    state = ProtoEnum.SkillState.SKILL_NULL,
    type = nil,
    cast_cnt = nil,
    cost_hp = nil,
    display_hp = nil,
    hp_per_energy = nil,
    last_cast_round = nil,
    cost_energy = nil,
    cost_energy_buff = nil,
    cost_energy_buff_factor = nil,
    cost_energy_buff_mul = nil,
    cost_energy_buff_set = nil,
    sp_energy_skill = nil,
    carryon_slot_idx = nil,
    consume_energy = nil,
    consume_hp = nil,
    ex_damage_param = nil,
    cost_all_energy = nil,
    fever_state = nil,
    rule_energy = nil,
    rule_damage_param = nil,
    effect_damage_param = nil,
    buff_damage_param = nil,
    pos = nil,
    damage_params = {},
    restraint_types = {},
    cd_round = nil,
    flag = nil,
    raw_damage = nil,
    used_cnt = nil,
    used_cnt_for_evolute = nil,
    extra_damage_type = {},
    disable_conf_dam_type = nil,
    cd_info = {},
    enhance_info = {},
    change_times = nil,
    cr_reset_round = nil,
    cr_reset_reason = nil,
    skill_id = nil,
    cr_damage_params = {},
    change_src_skill = nil,
    state_tips = nil,
    must_cost_hp = nil,
    skill_buff = ProtoMessage:newSkillBuffInfo(),
    last_pos = nil,
    trans_info = ProtoMessage:newTransInfo(),
    consume_change_effeciency = nil,
    is_change_effeciency = nil,
    original_pos = nil,
    raw_cost_energy = nil,
    cast_rounds = nil,
    enable_on_charging = nil,
    round_start_pos = nil,
    last_round_pos = nil,
    swap_from_pet = nil,
    priority_display = nil,
    set_cost_info = {},
    perform_flag = nil,
    remove_round = nil,
    original_skill_id = nil,
    damage_type = nil,
    cost_energy_buff_mul_10000 = nil,
    cost_energy_buff_factor_list = {},
    cd_outfield_round = nil,
    season_id = nil
  }
end

function ProtoMessage:newBattleMonsterEscapeInfo()
  return {
    condition_type = nil,
    cur_value = nil,
    threshold = nil
  }
end

function ProtoMessage:newBattleCatchProbInfo()
  return {ball_id = nil, catch_prob = nil}
end

function ProtoMessage:newBattleMonsterCatchInfo()
  return {
    threshold = nil,
    initial_threshold = nil,
    familarity_change = nil,
    catch_prob_list = {}
  }
end

function ProtoMessage:newBattleMonsterCatchCondCounter()
  return {
    condition_id = nil,
    trigger_cnt = nil,
    is_triggered = nil,
    need_sync_client = nil
  }
end

function ProtoMessage:newBattleCatchCondCounters()
  return {
    counters = {}
  }
end

function ProtoMessage:newBattleAISelectSkillInfo()
  return {
    uin = nil,
    hint_level = nil,
    npc_hint_mode = nil,
    skill_feature = nil,
    cost_energy = nil,
    dam_type = nil,
    skill_id = nil,
    skill_targets = {},
    show_skill_feature = nil,
    show_cost_energy = nil,
    show_dam_type = nil,
    show_skill_id = nil,
    no_show = nil,
    show_word = nil,
    skill_id_2 = nil,
    word_conf_id = nil,
    word_conf_index = nil
  }
end

function ProtoMessage:newBattlePetHabitInfo()
  return {
    env_buff_change = {},
    env_enjoy_type_add = {},
    env_enjoy_type_sub = {},
    env_hate_type_add = {},
    env_hate_type_sub = {}
  }
end

function ProtoMessage:newBattleInstantKillInfo()
  return {
    param = nil,
    param_by = nil,
    kill_at_hp = nil
  }
end

function ProtoMessage:newExtraSdtInfo()
  return {
    type = nil,
    result = nil,
    buff_id = nil,
    buffbase_id = nil
  }
end

function ProtoMessage:newFeatureResonance()
  return {skill_id = nil}
end

function ProtoMessage:newBattleInsidePetInfo()
  return {
    pet_id = nil,
    pos = nil,
    buffs = {},
    battle_attr = {},
    state_bits = {},
    skill_round_data = {},
    escape_info = ProtoMessage:newBattleMonsterEscapeInfo(),
    catch_info = ProtoMessage:newBattleMonsterCatchInfo(),
    ai_info = ProtoMessage:newBattleAIInitInfo(),
    position = ProtoMessage:newPosition(),
    sp_energy = {},
    env_enjoy_hate = nil,
    enjoy_hate_buff_ex = {},
    enjoy_hate_buff_ex_stack = {},
    env_enjoy_hate_buff = {},
    ai_skill_info = {},
    conf_id = nil,
    base_conf_id = nil,
    name = nil,
    cheers_tag = nil,
    enter_index = nil,
    habit_info = ProtoMessage:newBattlePetHabitInfo(),
    kill_info = ProtoMessage:newBattleInstantKillInfo(),
    extra_resist_type = {},
    in_battle_round = nil,
    counter_round = nil,
    revive_round = nil,
    revive_rounds = nil,
    charging_skill_id = nil,
    last_catch_time = nil,
    catch_guarantee_rate = nil,
    npc_obj_id = nil,
    remain_buff_infos = {},
    nightmare_elite_id = nil,
    extra_sdt = {},
    blow_pos = nil,
    is_player_enemy = nil,
    replace_pet_id = nil,
    medal_conf_id = nil,
    medal_complete_cnt = nil,
    pet_change_status = ProtoEnum.PetChangeStatus.PCS_OK,
    skill_buff = ProtoMessage:newSkillBuffInfo(),
    dot_suck_effect = {},
    last_hurt_round = nil,
    skill_num = nil,
    max_energy = nil,
    changed_attr = {},
    dead_round = nil,
    dead_cnt = nil,
    refresh_content_id = nil,
    last_pos = nil,
    boss_blood_old_id = nil,
    using_buffs = {},
    boss_blood_id = nil,
    is_protected = nil,
    swap_skills_bak = {},
    cur_passive_skill = nil,
    triggered_buffs = {},
    is_b93_active = nil,
    has_fast_skill_pets = {},
    ai_ev_petbase_id = nil,
    battle_final_attr = ProtoMessage:newPetAdditionalNewAttrList(),
    is_entered = nil,
    speed_min = nil,
    speed_max = nil,
    used_original_skill = {},
    last_position = ProtoMessage:newPosition(),
    trial_pet_info = ProtoMessage:newTerritoryTrialPetInfo(),
    box_info = ProtoMessage:newBoxMonsterInfo(),
    owner_uin = nil,
    last_up_round = nil,
    last_down_round = nil,
    feature_resonance = ProtoMessage:newFeatureResonance(),
    real_info = ProtoMessage:newPetRealInfo(),
    charging_skill_energy = nil,
    height = nil,
    weight = nil,
    buff145_source_pet = nil,
    last_deal_damage_round = nil,
    season_attr_add_percent = {}
  }
end

function ProtoMessage:newInner_FriendTypeInfo()
  return {
    uin = nil,
    type = nil,
    friend_seconds = nil
  }
end

function ProtoMessage:newBattleRoleBaseInfo()
  return {
    role_uin = nil,
    name = nil,
    pos = nil,
    catch_counts = nil,
    seen_monster_bits = nil,
    npc_level = {},
    role_level = nil,
    raw_hp = nil,
    hp = nil,
    cfg_limit_hp = nil,
    mod_hp = nil,
    raw_hp_max = nil,
    state_bit = nil,
    pvp_score = nil,
    world_level = nil,
    first_seen_pets = {},
    npc_id = nil,
    legend_skill_cast_num = nil,
    black_hp = nil,
    battle_hp_max = nil,
    need_supply_pet = nil,
    side = nil,
    sex = nil,
    mate_fri_num = nil,
    enemy_fri_num = nil,
    valid_shiny_catch_uins = {},
    fri_uin_list = {},
    is_visiting = nil,
    visit_owner_uin = nil,
    visit_owner_name = nil,
    scene_pos = ProtoMessage:newPosition(),
    scene_obj_id = nil,
    double_interact = nil,
    ride_id = nil,
    season_adv_prob_add = nil,
    fri_type_list = {},
    role_avatar_id = nil,
    free_catch = nil
  }
end

function ProtoMessage:newBattleItemInfo()
  return {
    item_id = nil,
    item_conf_id = nil,
    gid = nil,
    num = nil,
    is_charge = nil,
    remain_use_cnt = nil,
    max_use_cnt = nil,
    effect_value = nil,
    effect_type = nil,
    allow_use_cnt = nil,
    item_type = nil,
    is_equipped = nil,
    used_num = nil,
    player_skill_id = nil,
    is_temp = nil,
    state = ProtoEnum.BattleItemState.BIS_OK,
    is_permanent = nil,
    battle_use_time_max = nil,
    battle_use_time_remain = nil,
    allow_use_cnt_inbattle = nil
  }
end

function ProtoMessage:newTaskItemInfo()
  return {item_conf_id = nil, item_num = nil}
end

function ProtoMessage:newPackPetInfo()
  return {pet_conf_id = nil, alive_status = nil}
end

function ProtoMessage:newBattlePetPackInfo()
  return {
    pets = {}
  }
end

function ProtoMessage:newBattleRoleMagicOpInfo()
  return {
    state = ProtoEnum.BattleRoleMagicOpInfo_STATE.STATE_NONE,
    pet_id = nil,
    player_skill_id = nil,
    skill_id = {},
    up_pet_id = nil,
    name = nil,
    ret_info = nil,
    boss_petbase_id = nil,
    need_pre_calc = nil,
    random_seed_recorded = nil,
    random_seed = nil
  }
end

function ProtoMessage:newBattleRoleMagicSkillInfo()
  return {
    skill_id = nil,
    last_cast_round = nil,
    state = ProtoEnum.SkillState.SKILL_NULL,
    show_cd_round = nil
  }
end

function ProtoMessage:newBattleTlogInfo()
  return {
    gamesv_id = nil,
    gameapp_id = nil,
    plat_id = nil,
    world_id = nil,
    open_id = nil,
    level = nil,
    pos = ProtoMessage:newPosition(),
    area_id = nil
  }
end

function ProtoMessage:newPvpRankInfo()
  return {
    r = nil,
    rank_star = nil,
    rank_order = nil,
    rank_name = nil,
    rank_season_id = nil,
    rank_master_score = nil,
    last_warm_pvp_time = nil,
    rd = nil,
    vol = nil
  }
end

function ProtoMessage:newBattleRoleInfo()
  return {
    base = ProtoMessage:newBattleRoleBaseInfo(),
    pets = {},
    items = {},
    magic_op_info = ProtoMessage:newBattleRoleMagicOpInfo(),
    magic_skill_info = ProtoMessage:newBattleRoleMagicSkillInfo(),
    req = ProtoMessage:newBattleRoundFlowReq(),
    role_addi_info = ProtoMessage:newBattleRoleAdditionInfo(),
    first_team = {},
    seq_num = nil,
    task_items = {}
  }
end

function ProtoMessage:newEvolutionData()
  return {pet_id = nil, aim_base_id = nil}
end

function ProtoMessage:newFinalBattleData()
  return {
    is_final_battle_energy_full = nil,
    switch_to_p2 = nil,
    P2_battle_cfg_id = nil
  }
end

function ProtoMessage:newB1FinalBattleData()
  return {
    switch_to_p2 = nil,
    P2_battle_cfg_id = nil,
    switch_to_p3 = nil,
    P3_battle_cfg_id = nil,
    b1_phantom_point = nil,
    p3_ulti_skill = nil,
    p1_enemy_pet_num = nil
  }
end

function ProtoMessage:newWorldLeaderFightInfo()
  return {
    execution_trigger = nil,
    execution_round = nil,
    boss_register_skill_cnt = nil,
    execution_trigger_available = nil
  }
end

function ProtoMessage:newObserverFashionInfo()
  return {
    uin = nil,
    pos = nil,
    gender = nil,
    appearance_info = ProtoMessage:newBattleFashionInfo()
  }
end

function ProtoMessage:newObserveBattleInfo()
  return {
    is_observer = nil,
    observer = {},
    observer_appearance_info = {}
  }
end

function ProtoMessage:newBattleStateInfo()
  return {
    battle_id = nil,
    round = nil,
    series_index = nil,
    battle_start_time = nil,
    round_time = nil,
    last_change_pet_round = nil,
    player_team = {},
    enemy_team = {},
    evolution_data = {},
    npc_escape = {},
    boss_register_skill_cnt = nil,
    pvp_round_limit = nil,
    is_player_dishonesty = nil,
    is_enemy_dishonesty = nil,
    final_battle_data = ProtoMessage:newFinalBattleData(),
    world_leader_fight_info = ProtoMessage:newWorldLeaderFightInfo(),
    b1_final_battle_data = ProtoMessage:newB1FinalBattleData()
  }
end

function ProtoMessage:newBattleOnlooker()
  return {
    id = nil,
    npc_conf_id = nil,
    npc_obj_id = nil,
    pos = nil,
    monster = ProtoMessage:newBattleOnlookerMonster()
  }
end

function ProtoMessage:newFinalBattleInfo()
  return {final_battle_energy = nil, is_final_battle_energy_full = nil}
end

function ProtoMessage:newB1FinalBattleInfo()
  return {
    b1_phantom_point = nil,
    p3_ulti_skill = nil,
    p1_enemy_pet_num = nil
  }
end

function ProtoMessage:newLegendaryBattleInfo()
  return {
    is_season_battle = nil,
    season_battle_id = nil,
    legendary_battle_id = nil
  }
end

function ProtoMessage:newBattleSpecialMoveInfo()
  return {
    pet_id = nil,
    id = nil,
    type = nil,
    round = nil,
    skill_id = nil
  }
end

function ProtoMessage:newBattleInitInfo()
  return {
    battle_id = nil,
    battle_cfg_id = {},
    battle_start_time = nil,
    battle_state = ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_NULL,
    player_team = {},
    enemy_team = {},
    state_bit = nil,
    blood_pet_skills = ProtoMessage:newBattleBloodPetSkill(),
    beast_star = nil,
    onlooker_a = {},
    onlooker_b = {},
    final_battle = ProtoMessage:newFinalBattleInfo(),
    world_leader_fight_info = ProtoMessage:newWorldLeaderFightInfo(),
    pve_info = ProtoMessage:newBattlePveInfo(),
    observe_battle = ProtoMessage:newObserveBattleInfo(),
    evolution_data = {},
    special_move = {},
    others = {},
    b1_final_battle = ProtoMessage:newB1FinalBattleInfo(),
    legendary_battle = ProtoMessage:newLegendaryBattleInfo(),
    battle_tasks = {},
    battler_uin = nil
  }
end

function ProtoMessage:newBattlePerformCmd()
  return {
    is_battle_finished = nil,
    perform_info = {},
    round = nil,
    blood_pet_skills = ProtoMessage:newBattleBloodPetSkill(),
    seq_num = nil,
    svr_estimate_time = nil
  }
end

function ProtoMessage:newBattlePerformInfo()
  return {
    type = ProtoEnum.BattlePerformType.BPT_NULL,
    group_id = nil,
    skill_cast = ProtoMessage:newBattleSkillCast(),
    buff_change = ProtoMessage:newBattleBuffChange(),
    buff_trigger = ProtoMessage:newBattleBuffTrigger(),
    damage_info = ProtoMessage:newBattleDamageInfo(),
    heal_info = ProtoMessage:newBattleHealInfo(),
    energy_info = ProtoMessage:newBattleEnergyInfo(),
    dead_info = ProtoMessage:newBattleDeadInfo(),
    revive_info = ProtoMessage:newBattleReviveInfo(),
    is_group_head = nil,
    sync_data = ProtoMessage:newBattleSyncData(),
    effect_trigger = ProtoMessage:newBattleEffectTrigger(),
    cast_moment = nil,
    show_letters = ProtoMessage:newBattleShowLetters(),
    sp_energy_trigger = ProtoMessage:newBattleSpEnergyTrigger(),
    sp_energy_change = ProtoMessage:newBattleSpEnergyChange(),
    change_pet = ProtoMessage:newBattleChangePet(),
    use_item = ProtoMessage:newBattleUseItem(),
    idle_info = ProtoMessage:newBattleIdleInfo(),
    monster_catch_change = ProtoMessage:newBattleMonsterCatchChange(),
    monster_escape_change = ProtoMessage:newBattleMonsterEscapeChange(),
    catch_pet_info = ProtoMessage:newBattleCatchPetInfo(),
    skill_state = ProtoMessage:newBattleSkillStateInfo(),
    pet_evolution = ProtoMessage:newBattlePetEvolution(),
    group_ref = nil,
    is_last_hit = nil,
    skill_aura = ProtoMessage:newBattleSkillAura(),
    weather_change = ProtoMessage:newBattleWeatherChange(),
    notify_perform = ProtoMessage:newBattleNotifyPerform(),
    special_perform = ProtoMessage:newBattleSpecialPerform(),
    change_model = ProtoMessage:newBattleChangeModel(),
    ai_perform = ProtoMessage:newBattleAIPerform(),
    cheers_switch = ProtoMessage:newBattleCheersSwitch(),
    pet_escape = ProtoMessage:newBattlePetEscape(),
    role_skill_cast = ProtoMessage:newBattleRoleSkillCast(),
    combo_skill_cast = ProtoMessage:newBattleComboSkillCast(),
    exec_index = nil,
    cmd_failed = ProtoMessage:newBattleCmdFailed(),
    battler_escape = ProtoMessage:newBattlerEscape(),
    battler_heal_info = ProtoMessage:newBattlerHealInfo(),
    pvp_perform = ProtoMessage:newBattlerPvpPerform(),
    data_update = ProtoMessage:newBattleDataUpdate(),
    supply_pet = ProtoMessage:newBattleSupplyPetPlayerInfo(),
    skill_pos_change = ProtoMessage:newBattleSkillPosChange(),
    special_move = ProtoMessage:newBattleSpecialMoveInfo(),
    runaway = ProtoMessage:newBattleRunawayInfo(),
    prepare_to_battle = ProtoMessage:newBattlePrepareToBattle(),
    bag_to_prepare = ProtoMessage:newBattleBagToPrepare(),
    feature_resonance = ProtoMessage:newBattleFeatureResonance(),
    box_shield_break = ProtoMessage:newBattleBoxShieldBreak()
  }
end

function ProtoMessage:newBattleRunawayInfo()
  return {player_uin = nil, reason = nil}
end

function ProtoMessage:newBattlePetSkillUpdateInfo()
  return {
    pet_id = nil,
    skills = {}
  }
end

function ProtoMessage:newBattleSkillPosChange()
  return {
    pet_id = nil,
    skill_pos_infos = {}
  }
end

function ProtoMessage:newSkillPosInfo()
  return {
    skill_id = nil,
    old_pos = nil,
    new_pos = nil,
    type = ProtoEnum.SkillPosInfo.PosChangeType.ACTIVE_CHANGE
  }
end

function ProtoMessage:newBattleDataUpdate()
  return {
    uin = nil,
    battler = ProtoMessage:newBattleRoleInfo(),
    pet = ProtoMessage:newBattlePetInfo(),
    item = ProtoMessage:newBattleItemInfo(),
    role_magic = ProtoMessage:newBattleRoleMagicInfo(),
    role_simple = ProtoMessage:newBattleRoleSimpleInfo(),
    pet_skill = ProtoMessage:newBattlePetSkillUpdateInfo(),
    other = ProtoMessage:newBattleOtherRoleInfo()
  }
end

function ProtoMessage:newBattleOtherRoleInfo()
  return {
    role_uin = nil,
    pets = {}
  }
end

function ProtoMessage:newBattleRoleMagicInfo()
  return {
    magic_op_info = ProtoMessage:newBattleRoleMagicOpInfo(),
    magic_skill_info = ProtoMessage:newBattleRoleMagicSkillInfo()
  }
end

function ProtoMessage:newBattleRoleSimpleInfo()
  return {
    pet_num = nil,
    dead_pet_num = nil,
    state_bit = nil,
    random_pet_num = nil,
    dead_random_pet_num = nil,
    defeat_point = nil,
    free_catch = nil
  }
end

function ProtoMessage:newBattlerPvpPerform()
  return {
    uin = nil,
    type = ProtoEnum.BattlerPvpPerform.EventType.INSTANT_KILL
  }
end

function ProtoMessage:newBattlerHealInfo()
  return {
    uin = nil,
    hp_change = nil,
    hp_result = nil,
    black_hp_change = nil,
    black_hp_result = nil
  }
end

function ProtoMessage:newBattlerEscape()
  return {
    uin = nil,
    reason = ProtoEnum.BattlerEscape.EscapeReason.MANUALLY
  }
end

function ProtoMessage:newBattleCmdFailed()
  return {
    uin = nil,
    req = ProtoMessage:newBattleRoundFlowReq(),
    ret = nil
  }
end

function ProtoMessage:newBattleBloodPetSkill()
  return {
    pkinfo = ProtoMessage:newSkillPkInfo(),
    skills = {}
  }
end

function ProtoMessage:newSkillPkInfo()
  return {
    skill_id = nil,
    attack_pet_id = nil,
    hide = nil,
    items = {},
    simple_pets = {}
  }
end

function ProtoMessage:newSkillInfo()
  return {skill_id = nil, hide = nil}
end

function ProtoMessage:newBattlePetEscape()
  return {pet_id = nil, perform_type = nil}
end

function ProtoMessage:newBattleAIPerform()
  return {
    pet_id = nil,
    uin = nil,
    onlooker_id = nil,
    type = nil,
    param = nil,
    str_param = nil,
    sound_id = nil,
    audience = nil
  }
end

function ProtoMessage:newBattleSpecialPerform()
  return {
    type = nil,
    sub_type = nil,
    params = {}
  }
end

function ProtoMessage:newBattleSkillAura()
  return {skill_id = nil, cast_moment = nil}
end

function ProtoMessage:newBattleWeatherChange()
  return {
    skill_id = nil,
    weather_id = nil,
    weather_expire_round = nil,
    cast_moment = nil,
    hide_tips = nil
  }
end

function ProtoMessage:newBattleNotifyPerform()
  return {
    notify_type = ProtoEnum.BattleNotifyPerformType.BNPT_COMMON,
    data = {},
    tips_id = nil,
    params = {},
    uin = nil
  }
end

function ProtoMessage:newBattleSkillCast()
  return {
    caster_id = nil,
    target_id = {},
    skill_id = nil,
    restraint_type = {},
    real_perform_id = nil,
    caster_uin = nil,
    type = ProtoEnum.SkillPerformType.SPT_ACTIVE,
    is_interupt = nil,
    change_target_id = nil,
    perform_flag = nil,
    resonance_pet_id = nil,
    season_id = nil
  }
end

function ProtoMessage:newBattleRoleSkillCast()
  return {
    caster_uin = nil,
    skill_id = nil,
    pet_id = nil,
    is_call_success = nil
  }
end

function ProtoMessage:newBattleComboSkillCast()
  return {
    caster_id = nil,
    target_id = {},
    skill_id = nil,
    restraint_type = {},
    real_perform_id = nil,
    caster_uin = nil,
    type = ProtoEnum.SkillPerformType.SPT_ACTIVE,
    combo_index = nil,
    combo_count = nil,
    change_target_id = nil
  }
end

function ProtoMessage:newBattleCheersSwitch()
  return {
    pet_id = nil,
    to_pos = nil,
    old_pet_id = nil,
    type = nil
  }
end

function ProtoMessage:newBattlePrepareToBattle()
  return {
    pet_id = {},
    to_pos = {}
  }
end

function ProtoMessage:newBattleBagToPrepare()
  return {
    pet_id = {},
    to_pos = {}
  }
end

function ProtoMessage:newBattleFeatureResonance()
  return {pet_id = nil}
end

function ProtoMessage:newBattleBoxShieldBreak()
  return {
    pet_id = nil,
    base_conf_id = nil,
    name = nil,
    old_base_conf_id = nil,
    is_shiny = nil,
    is_fantastic = nil,
    is_nightmare = nil,
    belong_season = nil,
    pet_rarity_type = ProtoEnum.PetRarityType.PET_RARITY_TYPE_INVALID,
    pet_mutation_type = ProtoEnum.PetMutationType.PET_MUTATION_TYPE_INVALID,
    pet_attr_type = ProtoEnum.PetAttrType.PET_ATTR_TYPE_INVALID
  }
end

function ProtoMessage:newBattleBuffChange()
  return {
    caster_id = nil,
    target_id = nil,
    buff_id = nil,
    type = ProtoEnum.BuffChangeType.BCT_NULL,
    buff_info = ProtoMessage:newBattleBuffInfo()
  }
end

function ProtoMessage:newBattleBuffTrigger()
  return {
    caster_id = nil,
    target_id = nil,
    buff_id = nil,
    buffbase_ids = {},
    perform_type = nil,
    need_select_pet = nil,
    frozen_death = nil
  }
end

function ProtoMessage:newBattleDamageInfo()
  return {
    caster_id = nil,
    target_id = nil,
    source_id = nil,
    is_critical = {},
    is_hit = nil,
    restraint_type = nil,
    has_shield = nil,
    dam_type = nil,
    execution = nil
  }
end

function ProtoMessage:newBattleHealInfo()
  return {
    caster_id = nil,
    target_id = nil,
    source_id = nil,
    heal_type = nil
  }
end

function ProtoMessage:newBattleEnergyInfo()
  return {
    caster_id = nil,
    target_id = nil,
    source_id = nil
  }
end

function ProtoMessage:newBattleDeadInfo()
  return {
    caster_id = nil,
    target_id = nil,
    dead_type = ProtoEnum.BattleDeadInfo.DeadType.NORMAL_DEAD
  }
end

function ProtoMessage:newBattleReviveInfo()
  return {
    caster_id = nil,
    pet = ProtoMessage:newBattlePetInfo(),
    uin = nil
  }
end

function ProtoMessage:newBattleEffectTrigger()
  return {
    caster_id = nil,
    target_id = nil,
    effect_id = nil,
    result = nil,
    params = {}
  }
end

function ProtoMessage:newBattleShowLetters()
  return {
    caster_id = nil,
    target_id = nil,
    buff_id = nil,
    pet_id = nil
  }
end

function ProtoMessage:newBattleChangePet()
  return {
    player_id = nil,
    rest_pet_id = nil,
    battle_pet_id = nil,
    battle_pet_info = ProtoMessage:newBattlePetInfo(),
    is_cmd = nil,
    perform_type = ProtoEnum.ChangePetPerformType.CPPT_NORMAL
  }
end

function ProtoMessage:newBattleChangeModel()
  return {
    pet_id = nil,
    old_base_id = nil,
    pet_info = ProtoMessage:newBattlePetInfo(),
    role_magic_flag = nil
  }
end

function ProtoMessage:newBattleUseItem()
  return {
    player_id = nil,
    target_id = nil,
    item_id = nil,
    item_num = nil,
    effect_type = nil
  }
end

function ProtoMessage:newBattleIdleInfo()
  return {idle_pet_id = nil}
end

function ProtoMessage:newBattleMonsterEscapeChange()
  return {monster_id = nil, condition_type = nil}
end

function ProtoMessage:newBattleMonsterCatchChange()
  return {monster_id = nil, catch_cond_id = nil}
end

function ProtoMessage:newBattleCatchPetInfo()
  return {
    success = nil,
    player_id = nil,
    monster_id = nil,
    pet_gid = nil,
    ball_id = nil,
    catch_prob = nil,
    is_tech_satisfied = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    ex_reward_id = nil,
    is_quick_catch = nil
  }
end

function ProtoMessage:newBattleSkillStateInfo()
  return {caster_pet_id = nil, state_code = nil}
end

function ProtoMessage:newBattlePetEvolution()
  return {
    pet_id = nil,
    pet_info = ProtoMessage:newBattlePetInfo()
  }
end

function ProtoMessage:newBattleSyncData()
  return {
    role_sync_info = {},
    pet_sync_info = {},
    skill_sync_info = {},
    comm_sync_info = {},
    skill_change_sync_info = {},
    pet_info = {},
    item_sync_info = {},
    task_infos = {}
  }
end

function ProtoMessage:newBattleRoleSyncInfo()
  return {
    role_uin = nil,
    role_energy_change = nil,
    role_energy_result = nil,
    item_id = nil,
    remain_use_cnt = nil,
    item_num = nil,
    allow_use_cnt = nil,
    hp_change = nil,
    hp_result = nil,
    pvp_score_change = nil,
    pvp_score_result = nil,
    black_hp_change = nil,
    black_hp_result = nil,
    legend_skill_cast_num = nil,
    allow_use_cnt_inbattle = nil
  }
end

function ProtoMessage:newBattleSkillChangeSyncInfo()
  return {
    pet_id = nil,
    skill_id = nil,
    skill_data = ProtoMessage:newPetSkillRoundData()
  }
end

function ProtoMessage:newBattlePetSyncInfo()
  return {
    pet_id = nil,
    hp_change = nil,
    hp_result = nil,
    shiled_change = nil,
    shield_result = nil,
    attr_type = nil,
    attr_change = nil,
    attr_result = nil,
    original_damage = nil,
    damage_change = nil,
    damage_result = nil,
    buff_id = nil,
    buff_stack_change = nil,
    buff_stack_result = nil,
    state_bit_change_pos = nil,
    state_bit_results = {},
    catch_threshold_change = nil,
    catch_threshold_result = nil,
    escape_threshold_change = nil,
    escape_threshold_result = nil,
    escape_cur_val_change = nil,
    escape_cur_val_result = nil,
    energy_change = nil,
    energy_result = nil,
    cheers_tag = nil,
    pos = nil,
    instant_kill_change = nil,
    instant_kill_result = nil,
    revive_round = nil,
    revive_rounds = nil,
    charging_skill_id = nil,
    height_change = nil,
    height_result = nil,
    triggered_buffs = {},
    mutation_type = nil,
    max_energy = nil
  }
end

function ProtoMessage:newBattleSkillSyncInfo()
  return {
    pet_id = nil,
    skill_id = nil,
    damage_param_change = nil,
    damage_param_result = nil,
    damage_param_pet_id = nil,
    cast_cnt_change = nil,
    cast_cnt_result = nil,
    pp_change = nil,
    pp_result = nil,
    cost_energy_change = nil,
    cost_energy_result = nil,
    cost_hp_change = nil,
    cost_hp_result = nil,
    display_hp_result = nil,
    sp_energy_skill = nil,
    hp_per_energy = nil,
    state = nil,
    damage_type = nil
  }
end

function ProtoMessage:newBattleItemSyncInfo()
  return {
    item_id = nil,
    num = nil,
    remain_use_cnt = nil,
    allow_use_cnt = nil,
    battle_use_time_max = nil,
    battle_use_time_remain = nil
  }
end

function ProtoMessage:newBattleCommSyncInfo()
  return {
    sp_energy_type = ProtoEnum.SkillDamType.SDT_INVALID,
    sp_energy_change = nil,
    sp_energy_result = nil,
    final_battle_energy_change = nil,
    final_battle_energy_result = nil,
    b1_phantom_point_change = nil,
    b1_phantom_point_result = nil
  }
end

function ProtoMessage:newBattleSpEnergyTrigger()
  return {
    dam_type = ProtoEnum.SkillDamType.SDT_INVALID,
    trigger_type = ProtoEnum.BattleSpEnergyTrigger.SP_TRIGGER_TYPE.SP_TRIGGER_NONE,
    caster_id = nil,
    old_skill_id = nil,
    new_skill_id = nil
  }
end

function ProtoMessage:newBattleSpEnergyChange()
  return {
    type = ProtoEnum.BattleSpEnergyChange.SP_ENERGY_CHANGE_TYPE.SP_ENERGY_NULL,
    ele = ProtoMessage:newSpEnergyElement(),
    src = ProtoEnum.BattleSpEnergyChange.SP_ENERGY_SRC.SRC_NONE,
    caster_id = nil,
    target_id = nil,
    change_value = nil,
    real_change_value = nil,
    replaced_dam_type = ProtoEnum.SkillDamType.SDT_INVALID
  }
end

function ProtoMessage:newBattleCastSkillReq()
  return {
    skill_id = nil,
    caster_pet_id = nil,
    target_pet_id = nil,
    change_pet_id = nil,
    target_pet_pos = nil,
    ignore_restrict = nil,
    fast_skill = nil
  }
end

function ProtoMessage:newBattleChangePetReq()
  return {
    player_id = nil,
    battle_pet_id = nil,
    rest_pet_id = nil
  }
end

function ProtoMessage:newBattleUseItemReq()
  return {
    player_id = nil,
    target_pet_id = nil,
    item_id = nil,
    target_pet_pos = nil
  }
end

function ProtoMessage:newBattleCatchPetReq()
  return {
    player_id = nil,
    monster_id = nil,
    item_id = nil,
    pet_gid = nil,
    flower_catch_vitem = nil
  }
end

function ProtoMessage:newBattleIdleReq()
  return {caster_pet_id = nil}
end

function ProtoMessage:newBattleSkillStateReq()
  return {caster_pet_id = nil, state_code = nil}
end

function ProtoMessage:newBattleRoleMagicOpReq()
  return {
    target_pet_id = nil,
    target_pet_pos = nil,
    up_pet_id = nil,
    name = nil,
    boss_petbase_id = nil
  }
end

function ProtoMessage:newBattleRoundFlowReq()
  return {
    req_type = nil,
    cast_skill = ProtoMessage:newBattleCastSkillReq(),
    change_pet = ProtoMessage:newBattleChangePetReq(),
    use_item = ProtoMessage:newBattleUseItemReq(),
    catch_pet = ProtoMessage:newBattleCatchPetReq(),
    idle = ProtoMessage:newBattleIdleReq(),
    skill_state = ProtoMessage:newBattleSkillStateReq(),
    magic_op = ProtoMessage:newBattleRoleMagicOpReq()
  }
end

function ProtoMessage:newBattlePetInfo()
  return {
    battle_inside_pet_info = ProtoMessage:newBattleInsidePetInfo(),
    battle_common_pet_info = ProtoMessage:newPetData(),
    req = ProtoMessage:newBattleRoundFlowReq(),
    data_level = nil,
    full_for_data_level = nil
  }
end

function ProtoMessage:newBattleCatchPetRsp()
  return {is_caught = nil, catch_probability = nil}
end

function ProtoMessage:newBattleRoundFlowRsp()
  return {
    rsp_type = nil,
    catch_pet_rsp = ProtoMessage:newBattleCatchPetRsp()
  }
end

function ProtoMessage:newBattleRoundPetInfo()
  return {base_conf_id = nil, gid = nil}
end

function ProtoMessage:newBattleRoundSettleInfo()
  return {
    is_evolution_complete = nil,
    world_zone_id = nil,
    caster_pet_info = {},
    target_pet_info = {},
    result = ProtoEnum.BATTLE_RESULT_TYPE.TRUE_BATTLE_RESULT_NULL,
    evolution_base_id = nil,
    battle_id = nil,
    battle_refresh_content = nil,
    guide_type = nil,
    last_damage_info = {}
  }
end

function ProtoMessage:newBattlePosition()
  return {
    x = nil,
    y = nil,
    z = nil
  }
end

function ProtoMessage:newBattlePoint()
  return {
    pos = ProtoMessage:newBattlePosition(),
    dir = nil
  }
end

function ProtoMessage:newBattlerCommentData()
  return {
    name = nil,
    recover_hp = nil,
    recover_energy = nil,
    location = nil
  }
end

function ProtoMessage:newBattlefieldBuffList()
  return {
    buffs = {},
    side = nil,
    pos = nil,
    uin = nil
  }
end

function ProtoMessage:newSpEnergyElement()
  return {
    dam_type = ProtoEnum.SkillDamType.SDT_INVALID,
    stack = nil
  }
end

function ProtoMessage:newSpEnergyData()
  return {
    energy_info = {},
    weather = ProtoMessage:newEnvEnergyInfo(),
    last_used_battle_center = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newBeastBattleAchieves()
  return {
    achieve_type = nil,
    achieve_values = {},
    reward_ball_num = nil,
    cfg_id = nil
  }
end

function ProtoMessage:newBattleRoleAdditionInfo()
  return {
    pet_catch_info = {},
    handbook_id = {},
    handbook_level = {},
    appearance_info = ProtoMessage:newBattleFashionInfo(),
    combo_cmd = {},
    battle_tlog_info = ProtoMessage:newBattleTlogInfo(),
    world_num = {},
    pet_num = nil,
    dead_pet_num = nil,
    pvp_rank_info = ProtoMessage:newPvpRankInfo(),
    ai_skill_event = nil,
    legendary_battle_is_perform = nil,
    is_mirror_team = nil,
    visit_shiny_catch_times = nil,
    last_pvp_battle_ai_desc = nil,
    last_pvp_battle_type = nil,
    random_pet_num = nil,
    dead_random_pet_num = nil,
    last_warm_pvp_time = nil,
    defeat_point = nil,
    ticket_id = nil,
    ticket_num = nil,
    settle_point = nil,
    has_spec_flower_medal = nil
  }
end

function ProtoMessage:newObserverBrief()
  return {
    uin = nil,
    level = nil,
    name = nil,
    icon = nil,
    watch_duration = nil
  }
end

function ProtoMessage:newAiExtraRoleData()
  return {
    uin = nil,
    op_history = ProtoMessage:newBattleOpHistory(),
    skill_results = nil
  }
end

function ProtoMessage:newAiExtraData()
  return {
    data = {}
  }
end

function ProtoMessage:newBattleOpRecord()
  return {
    skill_op = ProtoMessage:newSkillCastRecord(),
    change_pet_op = ProtoMessage:newChangePetRecord(),
    type = ProtoEnum.BattleOpRecord.RoundOpType.TYPE_NONE
  }
end

function ProtoMessage:newCliSimpleBattlePet()
  return {
    pet_id = nil,
    owner_uin = nil,
    pet_conf_id = nil,
    pet_base_id = nil,
    name = nil,
    mutation = nil,
    side = nil,
    level = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newHandbookCoverInfo()
  return {handbook_id = nil, rotate_angle = nil}
end

function ProtoMessage:newAreaHandbookInfo()
  return {
    area_hb_type = nil,
    found_coll_num = nil,
    collect_coll_num = nil,
    hb_award_idx = nil,
    award_get_list = {},
    area_covers = {},
    cover_candidate_data = {},
    topic_rp = {}
  }
end

function ProtoMessage:newPetHandbookSeasonInfo()
  return {season_id = nil, getted_reward = nil}
end

function ProtoMessage:newPetHandbook()
  return {
    record_collection = {},
    cover_candidate_data = {},
    area_hb_infos = {},
    topic_version = nil,
    season_info = {},
    belong_area_version = nil
  }
end

function ProtoMessage:newHandbookStatistics_StatInfo()
  return {data = nil, ratio = nil}
end

function ProtoMessage:newHandbookStatistics_TopStatInfo()
  return {
    top_ids = {},
    top_ratios = {}
  }
end

function ProtoMessage:newHandbookStatistics()
  return {
    team_type = nil,
    top_six_nature = {},
    top_six_talent = {},
    top_six_blood = {},
    top_six_skill = {},
    top_nature = ProtoMessage:newHandbookStatistics_TopStatInfo(),
    top_talent = ProtoMessage:newHandbookStatistics_TopStatInfo(),
    top_blood = ProtoMessage:newHandbookStatistics_TopStatInfo(),
    top_skill = ProtoMessage:newHandbookStatistics_TopStatInfo()
  }
end

function ProtoMessage:newHandbookRecordCollection()
  return {
    handbook_id = nil,
    record = {},
    topic_list = {},
    complete_node_num = nil,
    tot_node_num = nil,
    get_topic_award = {},
    status = nil,
    catch_prob_add = nil,
    catch_thres_add = nil,
    statistics = {}
  }
end

function ProtoMessage:newHandbookRecord()
  return {
    pet_base_id = nil,
    is_boss = nil,
    height_min = nil,
    height_max = nil,
    weight_min = nil,
    weight_max = nil,
    catch_thres_add = nil,
    add_time = nil,
    status = nil,
    caught_camp = {},
    mutation_type = nil,
    had_normal_form = nil,
    other_boss_base_ids = {},
    statistics = {},
    glass_infos = {},
    shine_glass_infos = {},
    boss_status = {},
    form_group = nil,
    catch_mutation = {}
  }
end

function ProtoMessage:newHandbookTopicInfo()
  return {
    finish_cnt = nil,
    node_num = nil,
    topic_type = nil,
    topic_idx = nil,
    topic_id = nil,
    get_award = nil
  }
end

function ProtoMessage:newBossRecordStatus()
  return {boss_base_id = nil, status = nil}
end

function ProtoMessage:newPetEggData()
  return {
    egg_brief = ProtoMessage:newPetEggBrief(),
    egg_core = ProtoMessage:newPetEggCore()
  }
end

function ProtoMessage:newPetEggBrief()
  return {
    conf_id = nil,
    height = nil,
    weight = nil,
    hatched_secs = nil,
    last_hatch_update_sec = nil,
    max_hatched_secs = nil,
    start_hatch_time = nil,
    src = ProtoEnum.EggAcquireWayType.EAWT_NONE,
    is_precious = nil,
    from_player_name = nil,
    from_pet_name = nil,
    from_player_uin = nil,
    from_pet_gid = nil,
    random_egg_conf = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    skill_dam_type = {},
    precious_egg_type = ProtoEnum.PreciousEggType.PET_NONE,
    ball_id = nil,
    egg_piece_id = nil,
    talent_rank = nil
  }
end

function ProtoMessage:newPetEggCore()
  return {
    blood_id = nil,
    nature = nil,
    break_enhance_enum = {},
    speciality_id = nil,
    egg_conf = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    attr_list = {},
    voice = nil,
    pet_info_id = nil,
    name = nil,
    gender = nil,
    nature_attr_id = nil,
    nature_attr_change_way = ProtoEnum.PetNatureAttrChangeWay.EM_PET_NATURE_ATTR_CHANGE_WAY_BEGIN,
    activity_partner_pet_data = ProtoMessage:newActivityPartnerPetData(),
    goods_second_reason = nil,
    name_src = ProtoEnum.PetNameSource.PNS_PET_BASE
  }
end

function ProtoMessage:newPetEggAttributeValue()
  return {
    attr_type = ProtoEnum.AttributeType.AT_NONE,
    attr_value = nil
  }
end

function ProtoMessage:newPetEggCoreRecord()
  return {
    egg_gid = nil,
    egg_core = ProtoMessage:newPetEggCore()
  }
end

function ProtoMessage:newGiftEggInfo()
  return {friend_uin = nil, gift_times = nil}
end

function ProtoMessage:newGiftEggList()
  return {
    last_refresh_time = nil,
    infos = {}
  }
end

function ProtoMessage:newPetMedalExt()
  return {
    num_1 = nil,
    num_2 = nil,
    num_3 = nil,
    str_1 = nil
  }
end

function ProtoMessage:newPetMedalDetail()
  return {
    owner_id = nil,
    add_time = nil,
    is_wear = nil,
    complete_cnt = nil,
    obtain_pet_gid = nil,
    obtain_pet_name = nil,
    wear_pet_gid = nil,
    ext_data = ProtoMessage:newPetMedalExt()
  }
end

function ProtoMessage:newPetMedalBucket()
  return {
    hash_id = nil,
    detail_list = {}
  }
end

function ProtoMessage:newPetMedal()
  return {
    conf_id = nil,
    hash_id = nil,
    detail = ProtoMessage:newPetMedalDetail(),
    trigger_pet_gid = nil
  }
end

function ProtoMessage:newPetMedalRecord()
  return {
    medal_conf_id = nil,
    medal_type = nil,
    buckets = {}
  }
end

function ProtoMessage:newPetMedalCondTask()
  return {id = nil, count = nil}
end

function ProtoMessage:newPetMedalContext()
  return {
    owner_id = nil,
    tasks = {},
    ext_data = ProtoMessage:newPetMedalExt(),
    kill_pet_chain_list = {}
  }
end

function ProtoMessage:newPetMedalAddi()
  return {
    medal_conf_id = nil,
    medal_type = nil,
    context_list = {}
  }
end

function ProtoMessage:newPetMedalData()
  return {
    conf_id = nil,
    medal_type = nil,
    is_wear = nil,
    complete_cnt = nil,
    obtain_pet_gid = nil,
    obtain_pet_name = nil,
    owner_id = nil,
    wear_pet_gid = nil,
    ext_data = ProtoMessage:newPetMedalExt()
  }
end

function ProtoMessage:newPetMedalOwnerTaskInfo()
  return {task_id = nil, task_complete_cnt = nil}
end

function ProtoMessage:newPetMedalTaskInfo_TaskInfo()
  return {
    task_complete_cnt = nil,
    medal_gid = nil,
    owner_id = nil,
    medal_ext = ProtoMessage:newPetMedalExt()
  }
end

function ProtoMessage:newPetMedalOwnerInfo()
  return {
    owner_id = nil,
    medal_gid = nil,
    task_infos = {},
    complete_cnt = nil,
    medal_ext = ProtoMessage:newPetMedalExt()
  }
end

function ProtoMessage:newPetMedalInfo()
  return {
    medal_conf_id = nil,
    medal_type = nil,
    owner_infos = {}
  }
end

function ProtoMessage:newPetMedalTaskInfo()
  return {
    medal_conf_id = nil,
    task_info = {},
    medal_type = nil
  }
end

function ProtoMessage:newH5PlayerInfo()
  return {
    openid = nil,
    callback = nil,
    time = nil,
    pet_nature = nil,
    pet_level = nil
  }
end

function ProtoMessage:newClientDevInfo()
  return {
    device_info = nil,
    plat_id = nil,
    system_software = nil,
    system_hardware = nil,
    telecom_oper = nil,
    network = nil,
    screen_width = nil,
    screen_hight = nil,
    density = nil,
    channel = nil,
    cpu_hardware = nil,
    memory = nil,
    gl_render = nil,
    gl_version = nil,
    device_id = nil,
    language = nil,
    ping = nil,
    area = nil,
    appstore = nil,
    package_channel = nil,
    aid = nil,
    user_agent = nil,
    old_caid = nil,
    is_gamematrix = nil
  }
end

function ProtoMessage:newClientVerInfo()
  return {
    cli_version = nil,
    cli_res_version = nil,
    cli_cfg_version = nil,
    app_version = nil,
    res_version = nil
  }
end

function ProtoMessage:newClientTokenInfo()
  return {
    auth_type = nil,
    access_token = nil,
    pay_token = nil,
    pf = nil,
    tpns_token = nil,
    wg_login_info = nil
  }
end

function ProtoMessage:newClientExtInfo()
  return {bag_item_use_page = nil}
end

function ProtoMessage:newClientInfo()
  return {
    ver_info = ProtoMessage:newClientVerInfo(),
    dev_info = ProtoMessage:newClientDevInfo(),
    token_info = ProtoMessage:newClientTokenInfo(),
    ext_info = ProtoMessage:newClientExtInfo()
  }
end

function ProtoMessage:newDeviceInfo()
  return {
    device = nil,
    lod_level = nil,
    ext = nil,
    screen_scale = nil,
    fps = nil,
    forbid = nil
  }
end

function ProtoMessage:newPlayerNpcRefreshBanInfo()
  return {ban_time = nil, ban_probability = nil}
end

function ProtoMessage:newPlayerBanItem()
  return {permission_date = nil, reason = nil}
end

function ProtoMessage:newPlayerFuncBanItem()
  return {
    func_id = nil,
    permission_date = nil,
    reason = nil
  }
end

function ProtoMessage:newPlayerBanInfo()
  return {
    ban_items = {},
    npc_refresh_ban_info = ProtoMessage:newPlayerNpcRefreshBanInfo(),
    func_ban_items = {}
  }
end

function ProtoMessage:newWebGamePlayerInfo()
  return {
    uin = nil,
    nick_name = nil,
    last_access_time = nil,
    player_level = nil,
    pet_id = nil,
    pet_get_time = nil,
    pet_nature = nil,
    pet_level = nil,
    reg_time = nil
  }
end

function ProtoMessage:newPlayerTitleLBSInfo()
  return {province = nil, rank = nil}
end

function ProtoMessage:newPlayerTitleExtendInfo()
  return {
    lbs_info = ProtoMessage:newPlayerTitleLBSInfo(),
    effect_begin_time = nil
  }
end

function ProtoMessage:newKickoutType()
  return {}
end

function ProtoMessage:newKickoutSubType()
  return {}
end

function ProtoMessage:newLangType()
  return {}
end

function ProtoMessage:newMultiLangPb()
  return {
    langs = {}
  }
end

function ProtoMessage:newLang()
  return {lang_type = nil, lang = nil}
end

function ProtoMessage:newSnsAuthInfo()
  return {
    openid = nil,
    access_token = nil,
    cli_login_channel = nil,
    world_id = nil
  }
end

function ProtoMessage:newSafetyContentID()
  return {
    id_type = nil,
    id_list = {}
  }
end

function ProtoMessage:newSafetyBusinessInfo()
  return {
    report_category = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT,
    report_reason = {},
    report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_CONVERSATION_SPEAKING_SCENE,
    reported_profile_url = nil,
    report_battle_id = nil,
    report_battle_time = nil,
    report_desc = nil,
    report_content = nil,
    pic_url_array = {},
    video_url_array = {},
    voice_url_array = {},
    report_group_id = nil,
    report_group_name = nil,
    language_id = nil,
    callback = nil,
    content_id = ProtoMessage:newSafetyContentID(),
    report_entrance = nil
  }
end

function ProtoMessage:newHopeInstruction()
  return {
    type = nil,
    openid = nil,
    uin = nil,
    title = nil,
    msg = nil,
    url = nil,
    modal = nil,
    rule_name = nil,
    logout_type = nil,
    trace_id = nil,
    logout_time = nil
  }
end

function ProtoMessage:newHopeInstructionReportData()
  return {
    openid = nil,
    rule_name = nil,
    instruction_trace_id = nil,
    exec_time = nil
  }
end

function ProtoMessage:newPlayerHopeData()
  return {
    last_report_time = nil,
    instruction = ProtoMessage:newHopeInstruction(),
    pvp_match_banned_timestamp = nil
  }
end

function ProtoMessage:newOpenIdList()
  return {
    openid = {}
  }
end

function ProtoMessage:newWhitelistTagList()
  return {
    tags = {},
    ori_key = nil,
    wx = nil,
    comment = nil
  }
end

function ProtoMessage:newPlayerSecInfo()
  return {
    score = nil,
    tag_black = nil,
    tag_ugc = nil,
    last_update_time = nil
  }
end

function ProtoMessage:newCreditScoreLimitInfo()
  return {
    scene_entry_list = {}
  }
end

function ProtoMessage:newGroupEntry()
  return {
    group_id = nil,
    threshold_lo = nil,
    threshold_hi = nil,
    is_tag_used = nil,
    tag_type = nil,
    tag_hi = nil,
    tag_lo = nil
  }
end

function ProtoMessage:newSceneEntry()
  return {
    scene_id = nil,
    group_entry_list = {}
  }
end

function ProtoMessage:newSceneIdipActionNpcInfo()
  return {
    type = nil,
    is_finish = nil,
    param1 = nil,
    param2 = nil,
    task_id = nil,
    time = nil,
    seq = nil
  }
end

function ProtoMessage:newSceneIdipActionNpcList()
  return {
    idip_actions = {},
    max_seq = nil,
    finish_seq = nil
  }
end

function ProtoMessage:newWegameAuthResult()
  return {error_code = nil, error_message = nil}
end

function ProtoMessage:newRewardState()
  return {
    id = nil,
    state = ProtoEnum.RewardState.RewardStateType.REWARD_STATE_TYPE_NONE
  }
end

function ProtoMessage:newGoodsReward()
  return {
    rewards = {}
  }
end

function ProtoMessage:newBagItem()
  return {
    gid = nil,
    id = nil,
    num = nil,
    update_time = nil,
    expire_time = nil,
    can_charge = nil,
    remain_use_cnt = nil,
    max_use_cnt = nil,
    effect_value = nil,
    can_in_battle = nil,
    bag_item_flags = nil,
    level = nil,
    stage = nil,
    type = nil,
    egg_data = ProtoMessage:newPetEggBrief(),
    fruit_active_timestamp = nil,
    medal_data = ProtoMessage:newPetMedalData(),
    liabilities_num = nil,
    finished_faction = {}
  }
end

function ProtoMessage:newBagItemTypeList()
  return {
    type = ProtoEnum.BagItemType.BI_ITEM,
    items = {},
    sort_type = ProtoEnum.Sequence.SEQUENCE_DEFAULT,
    total_num = nil,
    total_num_last_update_time = nil
  }
end

function ProtoMessage:newBagItemMaskList()
  return {
    type = ProtoEnum.BagItemType.BI_ITEM,
    id = {}
  }
end

function ProtoMessage:newGoodsItem()
  return {
    type = ProtoEnum.GoodsType.GT_NONE,
    id = nil,
    num = nil,
    tag = nil,
    src_type = ProtoEnum.GoodsType.GT_NONE,
    src_id = nil,
    first_get = nil,
    pet_data = ProtoMessage:newPetData(),
    reward_reason = nil,
    monster_level = nil,
    ball_id = nil,
    is_ambush = nil,
    is_correct_use = nil,
    is_from_battle = nil,
    is_ext_info = nil,
    param = nil,
    coro_id = nil,
    is_together_catch_gift = nil,
    egg_info = ProtoMessage:newPetEggBrief(),
    egg_core = ProtoMessage:newPetEggCore(),
    gids = {},
    npc_refresh_type = nil,
    npc_obj_id = nil,
    battle_id = nil
  }
end

function ProtoMessage:newGoodsChangeItem()
  return {
    type = ProtoEnum.GoodsType.GT_NONE,
    op = ProtoEnum.OpType.OT_ADD,
    num = nil,
    bag_item = ProtoMessage:newBagItem(),
    id = nil,
    pet_data = ProtoMessage:newPetData(),
    src_type = ProtoEnum.GoodsType.GT_NONE,
    src_id = nil,
    handbook_record = ProtoMessage:newHandbookRecord(),
    team_info = ProtoMessage:newPetTeamInfo(),
    change_reason = nil,
    backpack_info = ProtoMessage:newPetBackpackInfo(),
    bag_backpack_info = ProtoMessage:newBagBackpackInfo(),
    gid = nil,
    coro_id = nil,
    medal = ProtoMessage:newPetMedal(),
    box_info = ProtoMessage:newPetBox(),
    box_pet_change = ProtoMessage:newPetBoxPetChange()
  }
end

function ProtoMessage:newGoodsChange()
  return {
    changes = {},
    pet_data_vesion = nil,
    bag_data_vesion = nil,
    mail_data_vesion = nil
  }
end

function ProtoMessage:newHadItemInfo()
  return {
    item_gid = nil,
    item_cfg_id = nil,
    total_num = nil
  }
end

function ProtoMessage:newHadItemList()
  return {
    type = ProtoEnum.BagItemType.BI_ITEM,
    had_item_info = {}
  }
end

function ProtoMessage:newBackpackInfo()
  return {gid = nil, idx = nil}
end

function ProtoMessage:newBagBackpackInfo()
  return {
    ball_list = {},
    magic_list = {},
    ball_max_size = nil,
    magic_max_size = nil
  }
end

function ProtoMessage:newStorageGoodsInfo()
  return {
    npc_cfg_id = nil,
    type = nil,
    id = nil,
    num = nil
  }
end

function ProtoMessage:newGiftData()
  return {
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_num = nil,
    expire_time = nil,
    receive_state = ProtoEnum.GiftData.ReceiveState.RS_NONE,
    gift_unique_id = nil,
    pet_data = ProtoMessage:newPetData(),
    forbid_expire_time = nil
  }
end

function ProtoMessage:newGiftGivingData()
  return {
    receiver_uin = nil,
    gift_unique_id = nil,
    expire_time = nil,
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_num = nil,
    pet_data = ProtoMessage:newPetData(),
    forbid_expire_time = nil
  }
end

function ProtoMessage:newGoodsTransCBTestInfo()
  return {id = nil, num = nil}
end

function ProtoMessage:newGoodsTransItem()
  return {
    type = ProtoEnum.GoodsType.GT_NONE,
    op = ProtoEnum.OpType.OT_ADD,
    id = nil,
    num = nil,
    param = nil,
    goods_param_nouse = nil,
    buff_id = nil,
    buff_value = nil,
    gid = nil
  }
end

function ProtoMessage:newGoodsModifyMsg()
  return {
    need_check_befor_add = nil,
    goods_list = {},
    flow_reason = ProtoEnum.FlowReason.FLOW_REASON_NORMAL,
    need_notify = nil,
    is_not_merge = nil,
    add_goods_params = {},
    display_tag = nil,
    tlog_param = nil
  }
end

function ProtoMessage:newGoodsModifyTransInfo()
  return {
    seq = nil,
    finish = nil,
    type = nil,
    goods_modify_msg = ProtoMessage:newGoodsModifyMsg(),
    test_info = ProtoMessage:newGoodsTransCBTestInfo()
  }
end

function ProtoMessage:newGoodsModifyTransAllInfo()
  return {
    gid = nil,
    ack = nil,
    goods_tran_msg_list = {},
    last_update_time = nil,
    bak_goods_tran_msg_list = {},
    last_sync_time = nil,
    last_tick_time = nil,
    last_scenesvr_id = nil,
    last_ack_time = nil
  }
end

function ProtoMessage:newRpcVoidReq()
  return {}
end

function ProtoMessage:newRpcVoidRsp()
  return {}
end

function ProtoMessage:newRetInfo()
  return {
    ret_code = nil,
    ret_msg = nil,
    goods_reward = ProtoMessage:newGoodsReward(),
    goods_change_info = ProtoMessage:newGoodsChange()
  }
end

function ProtoMessage:newBanInfo()
  return {
    ban_time = nil,
    ban_reason = nil,
    uin = nil,
    ban_type = nil,
    func_id = nil
  }
end

function ProtoMessage:newRpcRetryReqInfo()
  return {
    req_id = nil,
    service_name = nil,
    method_id = nil,
    req_data = nil
  }
end

function ProtoMessage:newRpcRetryReqProcessInfo()
  return {req_id = nil, processed = nil}
end

function ProtoMessage:newRpcRetryInfo()
  return {
    latest_req_id = nil,
    oldest_unresponded_req_id = nil,
    unresponded_req_infos = {},
    latest_processed_req_id = nil,
    req_process_infos = {},
    oldest_processing_req_id = nil
  }
end

function ProtoMessage:newGetRpcRetryDataReq()
  return {latest_req_id = nil}
end

function ProtoMessage:newGetRpcRetryDataRsp()
  return {
    rpc_retry_req_info = {}
  }
end

function ProtoMessage:newSyncRpcRetryDataReq()
  return {
    rpc_retry_req_info = {},
    latest_req_id = nil,
    oldest_processing_req_id = nil,
    latest_processed_req_id = nil
  }
end

function ProtoMessage:newSyncRpcRetryDataRsp()
  return {oldest_processing_req_id = nil}
end

function ProtoMessage:newTestRpcRetryDataReq()
  return {req_data = nil}
end

function ProtoMessage:newTestRpcRetryDataRsp()
  return {rsp_data = nil}
end

function ProtoMessage:newRecoverMsgTaskInfo()
  return {
    action_list = ProtoMessage:newSceneTaskActionList(),
    task_target = {}
  }
end

function ProtoMessage:newRecoverMsgAckInfo()
  return {
    type = ProtoEnum.RecoverMsgType.RECOVER_MSG_TYPE_INTIAL,
    ack = nil,
    recover_msg_list = {},
    finish_gid = nil
  }
end

function ProtoMessage:newRecoverMsgAckList()
  return {
    ack_list = {},
    last_update_time = nil,
    last_sync_time = nil,
    task_progress_data = ProtoMessage:newTaskProgressData()
  }
end

function ProtoMessage:newDBTaskTargetData()
  return {key = nil, data = nil}
end

function ProtoMessage:newRecoverMsgTestInfo()
  return {}
end

function ProtoMessage:newRecoverMsgIdipInfo()
  return {
    action_type = nil,
    param1 = nil,
    param2 = nil
  }
end

function ProtoMessage:newRecoverMsgInfo()
  return {
    key1 = nil,
    key2 = nil,
    seq = nil,
    finish = nil,
    type = nil,
    is_scene_action = nil,
    try_times = nil,
    key3 = nil,
    task_info = ProtoMessage:newRecoverMsgTaskInfo(),
    test_info = ProtoMessage:newRecoverMsgTestInfo(),
    idip_info = ProtoMessage:newRecoverMsgIdipInfo()
  }
end

function ProtoMessage:newRecoverMsgData()
  return {
    type = ProtoEnum.RecoverMsgType.RECOVER_MSG_TYPE_INTIAL,
    gid = nil,
    ack = nil,
    recover_msg_list = {},
    last_update_time = nil,
    bak_recover_msg_list = {},
    finish_gid_old = nil,
    last_sync_time = nil,
    finish_gid = nil,
    last_stat_sync_time = nil,
    last_enter_scene_time = nil,
    last_scenesvr_id = nil,
    last_ack_time = nil,
    have_next_seq_data = nil
  }
end

function ProtoMessage:newTaskTrackRecoverInfo()
  return {
    task_id = nil,
    content_items = {}
  }
end

function ProtoMessage:newTaskTrackRecoverList()
  return {
    items = {}
  }
end

function ProtoMessage:newRecoverMsgList()
  return {
    recover_data_list = {},
    last_update_time = nil,
    delay_npc_actions = ProtoMessage:newSceneTaskActionNpcDelayList(),
    scene_state_data = ProtoMessage:newTaskScenesvrStateData(),
    task_progress_data = ProtoMessage:newTaskProgressData(),
    finish_idip_seq = nil,
    last_tick_time = nil,
    need_recover_all = nil,
    need_recover_all_set_time = nil,
    track_recover_list = ProtoMessage:newTaskTrackRecoverList(),
    home_delay_npc_actions = ProtoMessage:newSceneTaskActionNpcDelayList()
  }
end

function ProtoMessage:newZoneSceneSysFuncBannedNotify()
  return {
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newCellPassDataHome()
  return {home_name = nil, owner_is_online = nil}
end

function ProtoMessage:newCellPassDataPb()
  return {
    home_data = ProtoMessage:newCellPassDataHome()
  }
end

function ProtoMessage:newHomeInfo()
  return {
    home_name = nil,
    home_owner_id = nil,
    home_experience = nil,
    home_level = nil,
    room_level = nil,
    home_comfort_level = nil,
    access_info = ProtoMessage:newHomeAccessInfo(),
    room_layout = ProtoMessage:newRoomLayoutInfo(),
    room_expansion_info = ProtoMessage:newRoomExpansionInfo(),
    lay_egg_couple = ProtoMessage:newHomeLayEggCoupleInfo()
  }
end

function ProtoMessage:newHomeRareLayEggBanInfo()
  return {lay_egg_ban_time = nil, lay_egg_ban_probability = nil}
end

function ProtoMessage:newRoomFurnitureDetails()
  return {
    furniture_guid = nil,
    parent_furniture_guid = nil,
    item_gid = nil,
    config_id = nil,
    position = ProtoMessage:newPoint(),
    npc_id = nil,
    dynamic_npc_ids = {}
  }
end

function ProtoMessage:newRoomPlacementPlane()
  return {
    plane_guid = nil,
    furniture_list = {}
  }
end

function ProtoMessage:newRoomDecorationDetails()
  return {config_id = nil, item_gid = nil}
end

function ProtoMessage:newRoomDetails()
  return {
    room_id = nil,
    room_name = nil,
    room_plane_list = {},
    decoration_list = {}
  }
end

function ProtoMessage:newRoomLayoutInfo()
  return {
    rooms = {}
  }
end

function ProtoMessage:newHomeLayEggCoupleOne()
  return {
    female_obj_id = nil,
    male_obj_id = {}
  }
end

function ProtoMessage:newHomeLayEggCoupleInfo()
  return {
    female_couple = {}
  }
end

function ProtoMessage:newHomeDynamic()
  return {
    type = ProtoEnum.HomeDynamic.HomeDynamicType.UNKNOWN_DYNAMIC_TYPE,
    value = nil
  }
end

function ProtoMessage:newHomeVisitRecord()
  return {
    visitor_uin = nil,
    visit_timestamp = nil,
    visitor_icon = nil,
    visitor_name = nil,
    is_friend = nil,
    home_dynamics = {}
  }
end

function ProtoMessage:newHomeVisitorInfo()
  return {
    uin = nil,
    network_latency_ms = nil,
    tags = {}
  }
end

function ProtoMessage:newHomeVisitHistoryInfo()
  return {
    visit_records = {}
  }
end

function ProtoMessage:newHomeLevelRewardInfo()
  return {
    reward_states = {}
  }
end

function ProtoMessage:newHomeUnlockedHandBookList()
  return {
    unlock_list = {}
  }
end

function ProtoMessage:newHomeUnlockedFurnitureIdList()
  return {
    id_list = {}
  }
end

function ProtoMessage:newHomeRecommendedFurnitureInfo()
  return {
    recommended_id_list = {},
    next_update_timestamp = nil
  }
end

function ProtoMessage:newCraftableFurnitureList()
  return {
    unlocked_furniture_list = {},
    recommended_id_list = {}
  }
end

function ProtoMessage:newHomeCraftableFurnitureFriendInfo()
  return {
    uin = nil,
    name = nil,
    online_state = ProtoEnum.PlayerOnlineState.ENUM.Logouted,
    logout_time = nil,
    card_icon_selected = nil,
    note = nil,
    home_level = nil,
    is_recommended = nil
  }
end

function ProtoMessage:newHomePetFoodInfo()
  return {bag_item_id = nil, num = nil}
end

function ProtoMessage:newHomePetFeedInfo()
  return {
    food_info = ProtoMessage:newHomePetFoodInfo(),
    begin_time = nil,
    time_cost = nil
  }
end

function ProtoMessage:newHomePetGoodsInfo()
  return {
    goods_type = nil,
    goods_id = nil,
    goods_num = nil,
    goods_total_num = nil,
    goods_award_type = nil
  }
end

function ProtoMessage:newHomePetAwardInfo()
  return {
    goods_infos = {}
  }
end

function ProtoMessage:newHomePetOption()
  return {
    option_cfg_id = {}
  }
end

function ProtoMessage:newHomePetDisplayInfo()
  return {
    base_conf_id = nil,
    gender = nil,
    name = nil,
    level = nil,
    mutation_type = nil,
    energy = nil,
    blood_id = nil,
    attribute_new_info = ProtoMessage:newPetAdditionalNewAttrList(),
    attribute_info = ProtoMessage:newPetAttributeInfo(),
    skill = ProtoMessage:newPetSkillInfo(),
    nature = nil,
    changed_nature_neg_attr_type = nil,
    changed_nature_pos_attr_type = nil,
    speciality_id = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    last_breakthrough_lv = nil
  }
end

function ProtoMessage:newHomePetGainData()
  return {
    furni_coin = nil,
    home_exp = nil,
    furni_prob = nil,
    special_furni_prob = nil,
    steal_furni_coin = nil
  }
end

function ProtoMessage:newHomePetData()
  return {
    gid = nil,
    base_conf_id = nil,
    nature = nil,
    attribute_info = ProtoMessage:newPetAttributeInfo(),
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    blood_id = nil,
    height = nil,
    weight = nil,
    gender = nil,
    name = nil,
    level = nil,
    energy = nil,
    attribute_new_info = ProtoMessage:newPetAdditionalNewAttrList(),
    skill = ProtoMessage:newPetSkillInfo(),
    changed_nature_neg_attr_type = nil,
    changed_nature_pos_attr_type = nil,
    speciality_id = nil,
    last_breakthrough_lv = nil,
    voice = nil,
    home_pet_npc_cfg_id = nil,
    real_speciality_ids = {},
    gain_data = ProtoMessage:newHomePetGainData()
  }
end

function ProtoMessage:newHomePetInfo()
  return {
    pet_gid = nil,
    pet_cfg_id = nil,
    furniture_guid = nil,
    feed_info = ProtoMessage:newHomePetFeedInfo(),
    awards_info = ProtoMessage:newHomePetAwardInfo(),
    status = nil,
    speciality_id = nil,
    real_speciality_ids = {},
    name = nil,
    feed_round = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newHomePetBriefInfo()
  return {
    home_pet_info = ProtoMessage:newHomePetInfo(),
    display_info = ProtoMessage:newHomePetDisplayInfo(),
    can_steal = nil,
    have_egg = nil,
    predicted_egg_time = nil
  }
end

function ProtoMessage:newHomePlant_PlantBriefInfo()
  return {
    plant_id = nil,
    plant_state = nil,
    plant_seed_id = nil,
    plant_rip_time = nil,
    plant_harvest_num = nil,
    plant_tab_id = nil,
    plant_steal_players = {},
    plant_steal_account = nil,
    plant_can_steal_account = nil
  }
end

function ProtoMessage:newHomePlant_LandBriefInfo()
  return {
    home_plant_list = {}
  }
end

function ProtoMessage:newHomePlant_BriefInfo()
  return {
    home_plant_land_list = {},
    unlock = nil
  }
end

function ProtoMessage:newCellHomeBriefInfo()
  return {
    uin = nil,
    home_plant_info = ProtoMessage:newHomePlant_BriefInfo(),
    home_pets = {}
  }
end

function ProtoMessage:newHomeTeamInfo()
  return {
    team_type = ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_NONE,
    team_leader_uin = nil,
    status = ProtoEnum.HomeTeamStatus.HOME_TEAM_STATUS_NONE,
    members = {}
  }
end

function ProtoMessage:newHomeTeamMemberInfo()
  return {
    uin = nil,
    name = nil,
    card_icon = nil,
    role_level = nil,
    world_level = nil,
    status = ProtoEnum.HomeTeamMemberStatus.HOME_TEAM_MEMBER_STATUS_NONE
  }
end

function ProtoMessage:newZoneSceneHomeTeamUpdateNotify()
  return {
    team_info = ProtoMessage:newHomeTeamInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamInviteNotify()
  return {
    team_leader_uin = nil,
    status = ProtoEnum.HomeTeamStatus.HOME_TEAM_STATUS_NONE,
    team_leader = ProtoMessage:newHomeTeamMemberInfo(),
    team_type = ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_NONE
  }
end

function ProtoMessage:newZoneSceneHomeTeamEnterNotify()
  return {
    home_owner_id = nil,
    team_type = ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_NONE
  }
end

function ProtoMessage:newZoneSceneHomeTeamEnterCheckResultNotify()
  return {
    home_owner_id = nil,
    team_type = ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_NONE,
    error_code = nil
  }
end

function ProtoMessage:newMoveSegmentInfo()
  return {
    pos = ProtoMessage:newPosition(),
    time_stamp = nil
  }
end

function ProtoMessage:newMoveInfo()
  return {
    time_stamp = nil,
    to_pos = ProtoMessage:newPosition(),
    to_rot = ProtoMessage:newPosition(),
    speed = ProtoMessage:newPosition(),
    acceleration = ProtoMessage:newPosition(),
    move_mode = nil,
    custom_mode = nil,
    stop_move = nil,
    move_seg_list = {},
    platform_actor_id = nil,
    ctrl_rot = ProtoMessage:newPosition(),
    ride_move = nil
  }
end

function ProtoMessage:newThrowItemInfo()
  return {
    cur_selected_throw_type = ProtoEnum.ThrowType.NONE,
    cur_selected_gid = nil,
    last_selected_pet_gid = nil
  }
end

function ProtoMessage:newThrowItem()
  return {
    selected_throw_type = ProtoEnum.ThrowType.NONE,
    selected_gid = nil
  }
end

function ProtoMessage:newThrowPetInfo()
  return {
    gid = nil,
    npc_id = nil,
    related_npc_id = nil,
    related_option_id = nil,
    npc_logic_id = nil,
    throw_timestamp = nil
  }
end

function ProtoMessage:newBeginThrowInfo()
  return {
    id = nil,
    throw_type = nil,
    gid = nil,
    pos = ProtoMessage:newPosition(),
    throw_time = nil,
    conf_id = nil,
    last_collision_pos = ProtoMessage:newPosition(),
    has_broken = nil,
    collision_counts = nil,
    create_ball_npc_id = nil,
    create_ball_npc_logic_id = nil,
    roll_back_ball_conf_id = nil,
    charge_level = nil
  }
end

function ProtoMessage:newClientNpcBlackboard()
  return {
    tod = nil,
    sleeping = nil,
    new_skill = nil,
    ai_status = nil,
    back_of_head = nil,
    pre_act_tag = nil,
    pre_act_param = nil
  }
end

function ProtoMessage:newThrowBattleInfo()
  return {
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    radius = nil,
    npc_ai_blackboard = ProtoMessage:newClientNpcBlackboard(),
    battle_center = ProtoMessage:newPoint(),
    cheer_monster_init_info = {},
    is_battle_action = nil,
    battle_type = nil,
    ride_id = nil,
    onlooker_obj_id = {},
    visit_remain_shiny_catch_times = nil
  }
end

function ProtoMessage:newThrowCreateInfo()
  return {
    create_pt = ProtoMessage:newPoint(),
    need_create_pet = nil
  }
end

function ProtoMessage:newThrowPetData()
  return {
    nature = nil,
    height = nil,
    weight = nil,
    level = nil,
    mutation_type = nil,
    gid = nil
  }
end

function ProtoMessage:newThrowTargetNpcInfo()
  return {
    npc_id = nil,
    npc_conf_id = nil,
    option_id = nil,
    npc_ai_status = nil,
    npc_ai_behavior = nil,
    npc_pos = ProtoMessage:newPosition(),
    weakness_pos_name = nil,
    gain_expose_pos_name = nil,
    is_back_stab = nil,
    npc_logic_id = nil,
    npc_refresh_type = nil
  }
end

function ProtoMessage:newThrowMagicCreateNPCInfo()
  return {
    npc_refresh_conf_id = nil,
    create_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newThrowMagicInfo()
  return {
    strength_level = nil,
    charge_percentage = nil,
    target_avatar_ids = {},
    create_npc_info = ProtoMessage:newThrowMagicCreateNPCInfo(),
    target_avatar_uins = {},
    target_is_friend_list = {}
  }
end

function ProtoMessage:newThrowStatusInfo()
  return {ability_status = nil, mode = nil}
end

function ProtoMessage:newThrowRandomActionInfo()
  return {
    npc_id = nil,
    option_id = nil,
    interact_id = nil
  }
end

function ProtoMessage:newSceneCatchResult()
  return {
    catch_success = nil,
    ball_conf_id = nil,
    probability = nil,
    is_tech_satisfied = nil,
    npc_id = nil,
    npc_cfg_id = nil,
    npc_logic_id = nil,
    caught_ai_status = nil,
    caught_ai_behavior = nil,
    is_detected = nil,
    is_back_stab = nil,
    refresh_source = nil,
    avatar_pt = ProtoMessage:newPoint(),
    is_visiting = nil,
    is_visiting_owner = nil,
    visit_owner_name = nil,
    caught_camp = nil,
    caught_weather = nil,
    is_throw_together = nil,
    diff_info = ProtoMessage:newMonsterDiffInfo(),
    monster_level = nil,
    monster_id = nil,
    gender = nil,
    pet_base_id = nil,
    season_pet_info = ProtoMessage:newSeasonPetInfo()
  }
end

function ProtoMessage:newThrowBagItemResult()
  return {
    is_broken = nil,
    roll_back_conf_id = nil,
    throw_power = nil
  }
end

function ProtoMessage:newThrowPetResult()
  return {is_exceed_interaction_threshold = nil}
end

function ProtoMessage:newThrowMagicCreateNPCResult()
  return {npc_obj_id = nil}
end

function ProtoMessage:newThrowStarMagicResult()
  return {
    star_magic_fail_avatar_uins = {}
  }
end

function ProtoMessage:newThrowSeatInfoOne()
  return {
    npc_cfg_id = nil,
    npc_id = nil,
    is_call_out = nil
  }
end

function ProtoMessage:newThrowSeatInfo()
  return {
    seat_info_list = {}
  }
end

function ProtoMessage:newCreatedRoleplayProp()
  return {
    npc_cfg_id = nil,
    npc_id = nil,
    is_call_out = nil
  }
end

function ProtoMessage:newCreatedRoleplayPropData()
  return {
    created_roleplay_props = {}
  }
end

function ProtoMessage:newEnteredRoleplayPropData()
  return {
    npc_id = nil,
    slot_idx = nil,
    prop_type = nil
  }
end

function ProtoMessage:newPetSubmitRewardInfo()
  return {bonus_id = nil, bonus_param = nil}
end

function ProtoMessage:newInteractActResult()
  return {action_type = nil, act_rsp_params = nil}
end

function ProtoMessage:newInteractCommitResult()
  return {action_type = nil, act_rsp_params = nil}
end

function ProtoMessage:newPlayerInteractBriefInfo()
  return {
    uin = nil,
    level = nil,
    name = nil,
    icon = nil,
    apply_time = nil,
    world_level = nil
  }
end

function ProtoMessage:newPlayerAbilityData()
  return {id = nil, pet_gid = nil}
end

function ProtoMessage:newPlayerAbilityInfo()
  return {
    ability_info = {},
    scene_ability_id = nil
  }
end

function ProtoMessage:newHistoricalInteractInfo()
  return {uin = nil, time = nil}
end

function ProtoMessage:newPlayerInteractInfo()
  return {
    historical_exchange_egg_infos = {},
    historical_sparring_infos = {}
  }
end

function ProtoMessage:newPlayerVisitData_VisitApplyInfo()
  return {apply_uin = nil, apply_time = nil}
end

function ProtoMessage:newPlayerVisitData_BeastBattleInfo()
  return {beast_match_owner = nil, beast_match_dst_id = nil}
end

function ProtoMessage:newPlayerVisitData_RecentVisitPlayer()
  return {visit_uin = nil, visit_time = nil}
end

function ProtoMessage:newPlayerVisitData()
  return {
    visit_time = nil,
    build_visiting = nil,
    visit_owner_obj_id = nil,
    recieve_applys = {},
    send_applys = {},
    backup_scenesvr_inst_id = nil,
    backup_scene_info = ProtoMessage:newPlayerSceneInfo(),
    forbidden_track_task = nil,
    beast_info = ProtoMessage:newPlayerVisitData_BeastBattleInfo(),
    visit_players = {},
    visit_status = nil,
    leave_visiting_time = nil,
    not_visiting_login = nil,
    permission_setting = nil,
    online_visit_teleporting = nil
  }
end

function ProtoMessage:newOnlineVisitorItem()
  return {
    visitor = nil,
    alive_time = nil,
    online_visiting = nil
  }
end

function ProtoMessage:newOnlineVisitReportData()
  return {
    owner_uin = nil,
    visitors = {}
  }
end

function ProtoMessage:newExchangeData()
  return {
    exchange_id = nil,
    exchange_times = nil,
    next_refresh_time = nil,
    exchange_group = nil
  }
end

function ProtoMessage:newPlayerExchangeInfo()
  return {
    exchange_data = {},
    last_refresh_time = nil,
    unlocked_recipes = {}
  }
end

function ProtoMessage:newNpcBattleAssist()
  return {
    id = nil,
    pet_conf_id = nil,
    pet_level = nil,
    npc_id = nil,
    pet_conf_ids = {}
  }
end

function ProtoMessage:newTeamBattleInfo()
  return {
    team_battle_type = nil,
    npc_logic_id = nil,
    npc_obj_id = nil,
    start_battle_time = nil,
    end_timestamp = nil,
    npc_cfg_id = nil,
    star = nil,
    blood = nil,
    battle_petbase_id = nil,
    randed_battle_npc_glass = nil,
    battle_npc_glass = nil,
    battle_npc_glass_info = ProtoMessage:newGlassInfo(),
    battle_npc_shiny = nil,
    camp_cfg_id = nil,
    battle_npc_lv = nil,
    battle_npc_hp_talent = nil,
    battle_npc_attack_talent = nil,
    battle_npc_special_attack_talent = nil,
    battle_npc_defense_talent = nil,
    battle_npc_special_defense_talent = nil,
    battle_npc_speed_talent = nil,
    battle_npc_gender = nil,
    battle_npc_nature = nil,
    battle_cfg_id = nil,
    select_star = nil,
    catch_vitem_quantity = nil,
    spec_flower_seed_id = nil,
    activity_id = nil,
    battle_tasks = {},
    bind_pet_gid = nil,
    bind_petbase_id = nil,
    bind_evolution_id = nil,
    medal_id = nil,
    npc_assists = {},
    visit_flower_seed_boss_datas = {},
    select_flower_owner_id = nil
  }
end

function ProtoMessage:newTeamBattleMateInfo()
  return {
    uin = nil,
    pet_gid = nil,
    pet_cfg_id = nil,
    mutation_type = nil,
    pet_lv = nil,
    prepare_state = nil,
    npc_id = nil,
    helper_id = nil,
    team_idx = nil,
    pet_cfg_ids = {},
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newInteractParam()
  return {
    action_id = nil,
    is_lock = nil,
    picked_egg_gid = nil,
    picked_bagitem_conf_id = nil,
    picked_pet_gid = nil,
    picked_pet_npc_id = nil
  }
end

function ProtoMessage:newRelationshipTreeData()
  return {peer_uin = nil, relationship_bits = nil}
end

function ProtoMessage:newPlayerFriendPinnedItem()
  return {uin = nil, pinned_time = nil}
end

function ProtoMessage:newPlayerFriendInfo()
  return {
    pinned_list = {}
  }
end

function ProtoMessage:newChatSessionInfo()
  return {
    uin = nil,
    name = nil,
    note = nil,
    head_img = nil,
    time_stamp = nil,
    card_icon_selected = nil,
    basic_info = ProtoMessage:newBasicInfo(),
    friend_session_info = ProtoMessage:newFriendSessionInfo()
  }
end

function ProtoMessage:newBasicInfo()
  return {uin = nil, time_stamp = nil}
end

function ProtoMessage:newFriendSessionInfo()
  return {
    name = nil,
    note = nil,
    head_img = nil,
    card_icon_selected = nil,
    online = nil,
    last_logout_time = nil,
    state = ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IDLE,
    battle_brief_info = ProtoMessage:newPlayerBattleBriefInfo(),
    gende = nil,
    level_award_info = nil,
    regist_date = nil,
    world_level = nil,
    offline_msg_num = nil,
    visit_info = ProtoMessage:newFriendVisitInfo(),
    pos_info = ProtoMessage:newFriendPositionInfo()
  }
end

function ProtoMessage:newChatMessageInfo()
  return {
    uin = nil,
    chat_message = nil,
    time_stamp = nil,
    msg_detail_info = ProtoMessage:newMsgDetailInfo(),
    chat_msg_type = ProtoEnum.ChatMessageType.CMT_NORMAL,
    gift_data = ProtoMessage:newGiftData(),
    msg_uid = nil
  }
end

function ProtoMessage:newMsgDetailInfo()
  return {
    session_uin = nil,
    name = nil,
    note = nil,
    card_icon_selected = nil,
    need_cypher = nil,
    is_friend = nil
  }
end

function ProtoMessage:newMapMarkInfo()
  return {
    mark_number = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newLayeredWorldMapExploreInfoOne()
  return {
    npc_id = nil,
    belong_camp = nil,
    explore_num = nil,
    total_num = nil
  }
end

function ProtoMessage:newLayeredWorldMapExploreInfo()
  return {
    explore_infos = {}
  }
end

function ProtoMessage:newLockStatus()
  return {}
end

function ProtoMessage:newWorldMapSyncInterruptReason()
  return {}
end

function ProtoMessage:newWorldMapEntryType()
  return {}
end

function ProtoMessage:newWorldMapPetStatus()
  return {}
end

function ProtoMessage:newWorldMapMarkType()
  return {}
end

function ProtoMessage:newWorldMapNpcInfo()
  return {
    npc_logic_id = nil,
    npc_cfg_id = nil,
    npc_refresh_id = nil,
    npc_pos = ProtoMessage:newPosition(),
    npc_level = nil,
    npc_remain_time = nil,
    status = nil,
    create_avatar_id = nil,
    create_avatar_name = nil,
    layer_id = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    mutation_type = nil,
    npc_born_time = nil
  }
end

function ProtoMessage:newWorldMapPetInfo()
  return {petbase_cfg_id = nil, pet_status = nil}
end

function ProtoMessage:newWorldMapEntry_Npc()
  return {
    world_map_cfg_id = nil,
    world_map_npc_infos = {},
    next_npc_refresh_time = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldMapEntry_Area()
  return {world_map_cfg_id = nil, have_explored = nil}
end

function ProtoMessage:newWorldMapEntry_SceneEvent()
  return {
    event_info = ProtoMessage:newSceneEventInfo()
  }
end

function ProtoMessage:newWorldMapEntry_Task()
  return {
    task_id = nil,
    pos = {}
  }
end

function ProtoMessage:newWorldMapEntry_BText()
  return {
    world_map_cfg_id = nil,
    pet_infos = {}
  }
end

function ProtoMessage:newWorldMapEntry_Mark()
  return {
    mark_id = nil,
    type = ProtoEnum.WorldMapMarkType.ENUM.None,
    world_map_cfg_id = nil,
    name = nil,
    is_track = nil,
    pos = ProtoMessage:newPosition(),
    layer_id = nil,
    scene_id = nil
  }
end

function ProtoMessage:newWorldMapEntry()
  return {
    entry_type = ProtoEnum.WorldMapEntryType.ENUM.MySelf,
    entry_id = nil,
    myself_entry_info = ProtoMessage:newWorldMapEntry_MySelf(),
    btext_entry_info = ProtoMessage:newWorldMapEntry_BText(),
    npc_entry_info = ProtoMessage:newWorldMapEntry_Npc(),
    area_entry_info = ProtoMessage:newWorldMapEntry_Area(),
    scene_event = ProtoMessage:newWorldMapEntry_SceneEvent(),
    task_entry_info = ProtoMessage:newWorldMapEntry_Task(),
    mark_entry_info = ProtoMessage:newWorldMapEntry_Mark()
  }
end

function ProtoMessage:newWorldMapEntry_MySelf()
  return {}
end

function ProtoMessage:newWorldMapEntries()
  return {
    entry_infos = {}
  }
end

function ProtoMessage:newWorldMapAutoTrackNpcInfo()
  return {
    npc_logic_id = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newLogicStatusOpInfo()
  return {op_type = nil, status = nil}
end

function ProtoMessage:newSetNpcPosItem()
  return {
    npc_id = nil,
    pt = ProtoMessage:newPoint(),
    npc_logic_id = nil,
    op_type = ProtoEnum.SetNpcPosType.SNPT_NONE
  }
end

function ProtoMessage:newAreaTrigInfo()
  return {
    area_trig_id = nil,
    option_stage = nil,
    is_done = nil
  }
end

function ProtoMessage:newNpcTraceInfo()
  return {
    content_id = nil,
    npc_obj_id = nil,
    npc_logic_id = nil,
    pt = ProtoMessage:newPoint(),
    pet_base_id = nil,
    npc_cfg_id = nil
  }
end

function ProtoMessage:newAffectNavDynamicNpcData()
  return {npc_point_id = nil, result_id = nil}
end

function ProtoMessage:newAddAuraResult()
  return {
    has_added = nil,
    gen_aura_id = nil,
    reason = nil,
    fail_param = nil
  }
end

function ProtoMessage:newCreateAuraInfo()
  return {
    conf_id = nil,
    pt = ProtoMessage:newPoint(),
    create_actor_id = nil
  }
end

function ProtoMessage:newRemoveAuraInfo()
  return {
    aura_id = nil,
    reason = ProtoEnum.RemoveAuraReason.DAR_NONE,
    mutex_aura_id = {},
    create_info = ProtoMessage:newCreateAuraInfo()
  }
end

function ProtoMessage:newSelfActorAdjustData()
  return {platform_actor_id = nil}
end

function ProtoMessage:newFriendInteractEvent()
  return {
    recommend_uin = nil,
    ev_type = ProtoEnum.FriendInteractEventType.FRIEND_INTERACT_EVENT_TYPE_NONE
  }
end

function ProtoMessage:newFriendInteractRecord()
  return {
    recommend_uin = nil,
    ev_type = ProtoEnum.FriendInteractEventType.FRIEND_INTERACT_EVENT_TYPE_NONE,
    ev_time = nil
  }
end

function ProtoMessage:newFriendInteractRecordList()
  return {
    source = ProtoEnum.FriendSource.FRIEND_SOURCE_NONE,
    records = {}
  }
end

function ProtoMessage:newFriendRecommendInfo()
  return {
    record_lists = {}
  }
end

function ProtoMessage:newStoryFlagChangeType()
  return {}
end

function ProtoMessage:newPlayerStoryFlagInfo()
  return {
    version = nil,
    story_flags = {},
    cached_story_flags = {}
  }
end

function ProtoMessage:newHomePetGuardOp()
  return {
    pet_gid = nil,
    op_type = ProtoEnum.HomePetGuardOpType.HOME_PET_GUARD_DISPATCH,
    pet_base_data = ProtoMessage:newSceneBasePetData()
  }
end

function ProtoMessage:newHomeBasicSyncData()
  return {is_owner_online = nil, home_name = nil}
end

function ProtoMessage:newActorPlantData()
  return {steal_cnt = nil}
end

function ProtoMessage:newPlayerSocialAccountInfo()
  return {
    openid = nil,
    register_time = nil,
    uin = nil
  }
end

function ProtoMessage:newPlayerSocialBaseInfo()
  return {
    name = nil,
    sex = nil,
    level = nil,
    world_level = nil,
    bp_gift_grade = nil
  }
end

function ProtoMessage:newPlayerSocialOnlineInfo()
  return {online_state = nil, logout_time = nil}
end

function ProtoMessage:newPlayerSocialCardInfo()
  return {
    signature = nil,
    card_skin_selected = nil,
    card_icon_selected = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_handbook_collect_num = nil,
    card_music_id = nil,
    card_bussiness_card_url = nil
  }
end

function ProtoMessage:newPlayerSocialHomeInfo()
  return {
    home_name = nil,
    home_experience = nil,
    home_level = nil,
    room_level = nil,
    home_comfort_level = nil,
    room_expansion_info = ProtoMessage:newRoomExpansionInfo()
  }
end

function ProtoMessage:newPlayerSocialBattleInfo()
  return {battle_state = nil, battle_conf_id = nil}
end

function ProtoMessage:newPlayerBattlePassSocialInfo()
  return {
    battle_pass_id = nil,
    theme_id = nil,
    gift_grade = ProtoEnum.BattlePassGiftGrade.BPGG_FREE
  }
end

function ProtoMessage:newPlayerSocialAdditionalInfo()
  return {
    cli_login_channel = nil,
    start_up_privilege_info = ProtoMessage:newPlayerStartUpPrivilegeInfo(),
    setting_brief_info = ProtoMessage:newPlayerSettingBriefInfo(),
    deletion_info = ProtoMessage:newPlayerDeletionInfo(),
    player_tags = {},
    battle_pass_info = ProtoMessage:newPlayerBattlePassSocialInfo()
  }
end

function ProtoMessage:newZonePlayerSocialInfo()
  return {
    account_info = ProtoMessage:newPlayerSocialAccountInfo(),
    base_info = ProtoMessage:newPlayerSocialBaseInfo(),
    online_info = ProtoMessage:newPlayerSocialOnlineInfo(),
    card_info = ProtoMessage:newPlayerSocialCardInfo(),
    home_info = ProtoMessage:newPlayerSocialHomeInfo(),
    battle_info = ProtoMessage:newPlayerSocialBattleInfo(),
    additional_info = ProtoMessage:newPlayerSocialAdditionalInfo()
  }
end

function ProtoMessage:newAvatarSocialPositionInfo()
  return {
    display_type = ProtoEnum.FriendPositionDisplayType.FPDT_NONE,
    scene_res_cfg_id = nil,
    camp_id = nil
  }
end

function ProtoMessage:newAvatarSocialVisitInfo()
  return {visitor_num = nil}
end

function ProtoMessage:newAvatarSocialAdditionalInfo()
  return {}
end

function ProtoMessage:newAvatarSocialInfo()
  return {
    pos_info = ProtoMessage:newAvatarSocialPositionInfo(),
    visit_info = ProtoMessage:newAvatarSocialVisitInfo(),
    additional_info = ProtoMessage:newAvatarSocialAdditionalInfo()
  }
end

function ProtoMessage:newPlayerSocialInfo()
  return {
    player_social = ProtoMessage:newZonePlayerSocialInfo(),
    avatar_social = ProtoMessage:newAvatarSocialInfo(),
    last_update_time = nil
  }
end

function ProtoMessage:newSnapshoot_WorldCombatSkillActionJump()
  return {
    begin_pos = ProtoMessage:newPosition(),
    target_pos = ProtoMessage:newPosition(),
    apex_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSnapshoot_WorldCombatSkillActionRcd()
  return {
    begin_pos = ProtoMessage:newPosition(),
    target_pos = ProtoMessage:newPosition(),
    cur_ray_length = nil,
    ex_target_pos = ProtoMessage:newPosition(),
    ex_target_id = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Curve()
  return {
    launch_pos = ProtoMessage:newPosition(),
    curve_fly_time = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Trace()
  return {
    accelerate_speed = nil,
    max_speed = nil,
    angle_speed = nil,
    cancel_trace_dist = nil,
    trace_dur_time = nil,
    is_keep_land_height = nil,
    land_height = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Normal()
  return {
    accelerate_speed = nil,
    max_speed = nil,
    is_keep_land_height = nil,
    land_height = nil
  }
end

function ProtoMessage:newSnapshoot_WorldCombatSkillActionMissile()
  return {
    master_id = nil,
    cur_speed = nil,
    accelerate_speed = nil,
    max_speed = nil,
    angle_speed = nil,
    cancel_trace_dist = nil,
    trace_dur_time = nil,
    is_keep_land_height = nil,
    land_height = nil,
    cur_launch_time = nil,
    target_pos = ProtoMessage:newPosition(),
    target_id = nil,
    missile_type = nil,
    curve_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Curve(),
    trace_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Trace(),
    normal_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Normal()
  }
end

function ProtoMessage:newSnapshoot_WorldCombatSkillActionCrush()
  return {
    begin_pos = ProtoMessage:newPosition(),
    target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSnapshoot_WorldCombatSkillActionShowHide()
  return {
    show_hide_info = ProtoMessage:newWorldCombatDotsSkillShowHideInfo()
  }
end

function ProtoMessage:newActorInfo_WorldCombatSkillAction()
  return {
    GUID = nil,
    skill_begin_time = nil,
    skill_action_type = ProtoEnum.SkillActionType.WorldCombatDotsSkillJump,
    jump_snapshoot = ProtoMessage:newSnapshoot_WorldCombatSkillActionJump(),
    rcd_snapshoot = ProtoMessage:newSnapshoot_WorldCombatSkillActionRcd(),
    missile_snapshoot = ProtoMessage:newSnapshoot_WorldCombatSkillActionMissile(),
    crush_snapshoot = ProtoMessage:newSnapshoot_WorldCombatSkillActionCrush(),
    show_hide_snapshoot = ProtoMessage:newSnapshoot_WorldCombatSkillActionShowHide()
  }
end

function ProtoMessage:newWorldCombatDotsSkillCastInfo()
  return {
    skill_id = nil,
    target_id = nil,
    target_pos = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newWorldCombatDotsSkillEndInfo()
  return {skill_id = nil, end_reason = nil}
end

function ProtoMessage:newWorldCombatDotsSkillCrushInfo()
  return {
    skill_id = nil,
    rotator = ProtoMessage:newPosition(),
    crush_duration = nil,
    GUID = nil,
    crush_final_pos = ProtoMessage:newPosition(),
    time_stamp = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillCrushEndInfo()
  return {
    skill_id = nil,
    GUID = nil,
    stop_point = ProtoMessage:newPoint(),
    action_time = nil,
    time_stamp = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillHitInfo()
  return {
    skill_id = nil,
    target_id = nil,
    hit_point = ProtoMessage:newPoint(),
    GUID = nil,
    block_type = ProtoEnum.BlockType.BLOCK_NONE,
    hit_type = ProtoEnum.SkillHitType.NORMAL,
    hit_perform_type = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillRotateInfo()
  return {
    skill_id = nil,
    rotator = ProtoMessage:newPosition(),
    GUID = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillLookAtInfo()
  return {
    skill_id = nil,
    target_id = nil,
    attach_point_type = nil,
    GUID = nil,
    target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo()
  return {
    skill_id = nil,
    GUID = nil,
    launch_bullet_id = nil,
    target_id = nil,
    speed = nil,
    accelerate_speed = nil,
    max_speed = nil,
    angle_speed = nil,
    cancel_trace_dist = nil,
    trace_dur_time = nil,
    is_keep_land_height = nil,
    land_height = nil,
    cur_launch_time = nil,
    target_pos = ProtoMessage:newPosition(),
    missile_type = nil,
    curve_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Curve(),
    trace_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Trace(),
    normal_bullet = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo_Normal()
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileStopTraceInfo()
  return {
    skill_id = nil,
    GUID = nil,
    pt = ProtoMessage:newPoint(),
    cur_launch_time = nil,
    launch_bullet_id = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillMissileDestroyInfo()
  return {
    skill_id = nil,
    GUID = nil,
    launch_bullet_id = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillJumpInfo()
  return {
    skill_id = nil,
    GUID = nil,
    target_pos = ProtoMessage:newPosition(),
    apex_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatDotsSkillJumpCancelInfo()
  return {
    skill_id = nil,
    GUID = nil,
    cur_pos = ProtoMessage:newPosition(),
    falling_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatDotsSkillJumpEndInfo()
  return {skill_id = nil, GUID = nil}
end

function ProtoMessage:newWorldCombatDotsSkillRcdInfo()
  return {
    skill_id = nil,
    GUID = nil,
    target_id = nil,
    target_pos = ProtoMessage:newPosition(),
    ray_end_need_move = nil,
    ex_target_id = nil,
    ex_target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatDotsSkillRcdEndInfo()
  return {skill_id = nil, GUID = nil}
end

function ProtoMessage:newWorldCombatDotsSkillSelectPosInfo()
  return {
    skill_id = nil,
    GUID = nil,
    select_pos = {}
  }
end

function ProtoMessage:newSelectPosInfo()
  return {
    point_idx = nil,
    target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatDotsSkillHiddenInfo()
  return {
    skill_id = nil,
    GUID = nil,
    show_state = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillHiddenEndInfo()
  return {
    skill_id = nil,
    GUID = nil,
    show_state = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillShowHideCompInfo()
  return {
    comp_name = nil,
    show_state = nil,
    propagate_to_children = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillShowHideInfo()
  return {
    show_state = nil,
    comp_list = {}
  }
end

function ProtoMessage:newWorldCombatDotsSkillPosLerpSyncInfo()
  return {
    type = ProtoEnum.WorldCombatDotsSkillPosLerpSyncInfo.Type.Skill,
    node_index = nil,
    skill_id = nil,
    GUID = nil,
    cast_point = ProtoMessage:newPoint(),
    lerp_duration = nil,
    pos_threshold = nil,
    dir_threshold = nil,
    lerp_animation_name = nil
  }
end

function ProtoMessage:newWorldCombatDotsSkillAnimCancelInfo()
  return {
    skill_id = nil,
    GUID = nil,
    anim_cancel_pos = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newWorldCombatSkillCastInfo()
  return {skill_id = nil}
end

function ProtoMessage:newWorldCombatSkillSpawnNpcInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    content_id = nil,
    init_pos = ProtoMessage:newPosition(),
    init_dir = ProtoMessage:newPosition(),
    refresh_type = nil
  }
end

function ProtoMessage:newWorldCombatSkillSpawnBulletInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    caster_id = nil,
    init_pos = ProtoMessage:newPosition(),
    init_dir = ProtoMessage:newPosition(),
    target_id = nil,
    target_pos = ProtoMessage:newPosition(),
    bullet_id = nil
  }
end

function ProtoMessage:newWorldCombatSkillFireBulletInfo()
  return {skill_id = nil, bullet_id = nil}
end

function ProtoMessage:newWorldCombatSkillBuffInfo()
  return {
    skill_id = nil,
    operate_type = nil,
    buff_id = nil,
    action_idx = nil,
    caster_id = nil,
    target_id = nil,
    duration_change = nil,
    duration = nil,
    effect_tick_interval = nil
  }
end

function ProtoMessage:newWorldCombatSkillEndInfo()
  return {skill_id = nil, end_reason = nil}
end

function ProtoMessage:newWorldCombatHitInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    attacker_id = nil,
    hit_dir = ProtoMessage:newPosition(),
    impact_force = nil,
    block_type = ProtoEnum.BlockType.BLOCK_NONE
  }
end

function ProtoMessage:newWorldCombatSkillJumpInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    caster_id = nil
  }
end

function ProtoMessage:newWorldCombatSkillJumpEndInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    caster_id = nil,
    pos = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newWorldCombatSkillRcdInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    caster_id = nil
  }
end

function ProtoMessage:newWorldCombatSkillPetCollisionInfo()
  return {
    skill_id = nil,
    action_idx = nil,
    block_skill_id = nil
  }
end

function ProtoMessage:newActorInfo_BornDie()
  return {
    skill_or_anim = nil,
    is_skill = nil,
    start_play_time = nil,
    is_borning = nil,
    is_dying = nil,
    die_reason = nil,
    born_reason = nil,
    create_actor_id = nil
  }
end

function ProtoMessage:newActorInfo_Base()
  return {
    detail_type = nil,
    actor_id = nil,
    logic_id = nil,
    born_time = nil,
    owner_id = nil,
    born_pt = ProtoMessage:newPoint(),
    cell_id = nil,
    pt = ProtoMessage:newPoint(),
    enter_scene_times = nil,
    lv = nil,
    name = nil,
    gender = nil,
    born_die_info = ProtoMessage:newActorInfo_BornDie(),
    platform_actor_id = nil
  }
end

function ProtoMessage:newCompExtendData()
  return {
    comp_type = nil,
    i64_data1 = nil,
    i64_data2 = nil,
    i64_data3 = nil,
    bytes1 = nil,
    bytes2 = nil,
    bytes3 = nil,
    bytes_array1 = {},
    bytes_array2 = {},
    bytes_array3 = {}
  }
end

function ProtoMessage:newCompExtendDatas()
  return {
    datas = {}
  }
end

function ProtoMessage:newActorInfo_NpcBase()
  return {
    npc_cfg_id = nil,
    src_npc_id = nil,
    related_npc_pos = ProtoMessage:newPosition(),
    src_npc_cfg_id = nil,
    src_npc_ref_cfg_id = nil,
    src_npc_pos = ProtoMessage:newPosition(),
    drop_item_num = nil,
    refresh_src = nil,
    pos_need_adjust = nil,
    npc_content_cfg_id = nil,
    height = nil,
    weight = nil,
    nature = nil,
    mutation_type = nil,
    world_nature = nil,
    world_hide = nil,
    refresh_point = nil,
    is_server_ai = nil,
    create_avatar_id = nil,
    blood_mix_skill_dam_type = nil,
    loop_action = nil,
    catch_guarantee_rate = nil,
    last_catch_time = nil,
    win = nil,
    can_be_teleport = nil,
    height_scale = nil,
    blood_normal_skill_dam_type = nil,
    home_plant_land_id = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    voice = nil,
    initial_affectionate = nil,
    create_visiting_uins = {},
    create_avatar_name = nil,
    habitat_id = nil,
    owl_sanctuary_content_cfg_id = nil
  }
end

function ProtoMessage:newActorInfo_DropItem()
  return {
    batch_num = nil,
    drop_count = nil,
    sequence_id_in_batch = nil
  }
end

function ProtoMessage:newActorInfo_AvatarAttrs()
  return {
    hp = nil,
    hp_max = nil,
    stamina = nil,
    stamina_max = nil,
    hp_temporary = nil,
    world_lv = nil,
    half_injure = nil
  }
end

function ProtoMessage:newActorInfo_NpcAttrs()
  return {hp = nil, hp_max = nil}
end

function ProtoMessage:newActorInfo_ThrowedPet()
  return {gid = nil, npcId = nil}
end

function ProtoMessage:newActorInfo_Attr()
  return {
    attr_type = nil,
    attr_val = nil,
    attr_present_tag = nil
  }
end

function ProtoMessage:newActorInfo_Story()
  return {
    story_flags = {},
    visit_owner_story_flags = {}
  }
end

function ProtoMessage:newAvatarSitInfo()
  return {
    sit_npc_id = nil,
    seat_idx = nil,
    sit_before_point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newActorInfo_AvatarInteract()
  return {
    interact_npc_id = nil,
    sit_info = ProtoMessage:newAvatarSitInfo()
  }
end

function ProtoMessage:newResonanceInfo()
  return {
    dancing = nil,
    player_id = {}
  }
end

function ProtoMessage:newPlayerRideStatusParams()
  return {
    ride_pet_id = nil,
    mutation_type = nil,
    relative_emotion = nil,
    active_skill = nil,
    ride_move_mode = nil,
    ride_basic_move_id = nil,
    ride_pet_gid = nil,
    double_ride_1p_id = nil,
    double_ride_2p_id = nil,
    ride_socket_type = nil,
    ride_load_finish = nil,
    unride_flag = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    ride_npc_id = nil,
    owner_id = nil,
    pet_voice = nil,
    pet_gid = nil,
    resonance_info = ProtoMessage:newResonanceInfo(),
    option_id = nil
  }
end

function ProtoMessage:newPlayerThrowAimStatusParams()
  return {
    aim_type = ProtoEnum.AimSyncType.AST_INIT_AIM,
    throw_item_type = nil,
    throw_ball_id = nil,
    is_fast = nil,
    is_throw_success = nil,
    throw_session_id = nil,
    throw_velocity = ProtoMessage:newPosition(),
    charged_level = nil,
    aim_rotation = ProtoMessage:newPosition(),
    throw_start_pos = ProtoMessage:newPosition(),
    magic_conf_id = nil,
    is_magic_cancel = nil
  }
end

function ProtoMessage:newPlayerTransformStatusParams()
  return {
    transform_cfg_id = nil,
    emote_id = nil,
    cancel_reason = ProtoEnum.PlayerTransformCancelReason.PTCR_PLAYER_CANCEL
  }
end

function ProtoMessage:newCircusPetParams()
  return {
    balance_stage = nil,
    balance_roll = nil,
    balance_pitch = nil,
    is_moving_on_ground = nil
  }
end

function ProtoMessage:newPlayerRideSkillStatusParams()
  return {
    skill_id = nil,
    skill_stage = nil,
    target_pos = ProtoMessage:newPosition(),
    circus_pet_params = ProtoMessage:newCircusPetParams()
  }
end

function ProtoMessage:newPlayerRolePlayStatusParams()
  return {
    role_play_id = nil,
    pet_id = nil,
    pet_serverid = nil,
    mutation_type = nil,
    nature = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    skill_interact_id = nil,
    skill_type = ProtoEnum.RolePlaySkillType.RPST_NONE,
    is_stop_loop = nil,
    ball_id = nil
  }
end

function ProtoMessage:newPlayerFashionSuitsStatusParams()
  return {fashion_suits_id = nil, suit_ai_effect = nil}
end

function ProtoMessage:newPlayerInteractStatusParams()
  return {
    interact_id = nil,
    player_uin1 = nil,
    player_uin2 = nil,
    pet_id = nil,
    pet_egg_id = nil,
    inviter_pos = ProtoMessage:newPoint(),
    accept_pos = ProtoMessage:newPoint(),
    pet_pos = ProtoMessage:newPoint(),
    pet_egg_gid = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newPlayerPerceptionParams()
  return {pet_gid = nil}
end

function ProtoMessage:newPlayerStatusCustomParams()
  return {
    ride_param = ProtoMessage:newPlayerRideStatusParams(),
    throw_aim_param = ProtoMessage:newPlayerThrowAimStatusParams(),
    transform_param = ProtoMessage:newPlayerTransformStatusParams(),
    ride_skill_param = ProtoMessage:newPlayerRideSkillStatusParams(),
    role_play_param = ProtoMessage:newPlayerRolePlayStatusParams(),
    fashion_suits_param = ProtoMessage:newPlayerFashionSuitsStatusParams(),
    player_interact_param = ProtoMessage:newPlayerInteractStatusParams(),
    perception_param = ProtoMessage:newPlayerPerceptionParams()
  }
end

function ProtoMessage:newPlayerBehaviorStatusExtraParams()
  return {has_roleplay_behavior = nil}
end

function ProtoMessage:newPlayerStatusSyncInfo()
  return {
    status = nil,
    op_code = nil,
    sub_status = nil,
    is_normal_remove = nil,
    custom_status_param = ProtoMessage:newPlayerStatusCustomParams(),
    server_extra_param = ProtoMessage:newPlayerBehaviorStatusExtraParams()
  }
end

function ProtoMessage:newActorInfo_AvatarDetailStatus()
  return {
    status_list = {},
    sub_status_list = {},
    avatar_status_params = {},
    end_transform_time = nil,
    player_tags = {}
  }
end

function ProtoMessage:newActorInfo_NpcActionInfo()
  return {
    act_type = nil,
    act_status = nil,
    act_exec_success = nil,
    bound_dialog_id = nil,
    btle_cfg_id = nil,
    act_result_type = nil,
    dialog_id = nil,
    camp_pet_report_id = nil,
    next_dialog_id = nil,
    select_infos = {},
    begin_act_params = {},
    dialog_skip_state = nil,
    hand_over_item_conf_id = {}
  }
end

function ProtoMessage:newActorInfo_NpcDialogSelectInfo()
  return {
    select_id = nil,
    enabled = nil,
    remaining_times = nil,
    dialog_id = nil,
    has_been_selected = nil
  }
end

function ProtoMessage:newActorInfo_NpcOptionInfo()
  return {
    option_id = nil,
    enabled = nil,
    executable_times = nil,
    story_flags = {},
    select_infos = {},
    cur_action_info = ProtoMessage:newActorInfo_NpcActionInfo(),
    succ_exec_times = nil,
    first_dialog_id = nil,
    is_shared_opt = nil,
    whitelist_uins = {},
    blacklist_uins = {}
  }
end

function ProtoMessage:newNpcSeatInfoOne()
  return {seat_idx = nil, interact_avatar_id = nil}
end

function ProtoMessage:newActorInfo_NpcSeatInfo()
  return {
    seat_info = {}
  }
end

function ProtoMessage:newActorInfo_NpcInteract()
  return {
    option_infos = {},
    visitor_only_option_infos = {},
    seat_info = ProtoMessage:newActorInfo_NpcSeatInfo()
  }
end

function ProtoMessage:newNpcPropSlotInfo()
  return {slot_idx = nil, holder_avatar_id = nil}
end

function ProtoMessage:newActorInfo_NpcProp()
  return {
    npc_prop_slot_infos = {}
  }
end

function ProtoMessage:newVisitorOnly_NpcOptionInfo()
  return {
    visitor_id = nil,
    option_infos = {}
  }
end

function ProtoMessage:newCombineCondNpcInfo()
  return {
    npc_obj_id = nil,
    npc_pos = ProtoMessage:newPosition(),
    npc_refresh_pt = nil
  }
end

function ProtoMessage:newActorInfo_CombineLock()
  return {
    unlocked_num = nil,
    tot_lock_num = nil,
    cond_npc_infos = {}
  }
end

function ProtoMessage:newActorInfo_PotentialEnergy()
  return {
    enabled = nil,
    potential_energy = {}
  }
end

function ProtoMessage:newActorInfo_PropertyType()
  return {
    property_types = {}
  }
end

function ProtoMessage:newActorInfo_Aura()
  return {
    id = nil,
    aura_conf_id = nil,
    pos = ProtoMessage:newPosition(),
    belong_actor_id = nil,
    is_avatar_in_aura = nil,
    create_actor_id = nil,
    enabled = nil,
    dir = nil,
    params = {},
    radius = nil,
    create_avatar_id = nil,
    avatar_white_list = {}
  }
end

function ProtoMessage:newActorInfo_Buff()
  return {
    id = nil,
    buff_cfg_id = nil,
    buff_val = nil,
    str_params_list = {},
    int_params_list = {},
    add_buff_caster_id = nil,
    create_time = nil
  }
end

function ProtoMessage:newActorInfo_Buffs()
  return {
    buff_infos = {},
    battle_buff_infos = {}
  }
end

function ProtoMessage:newActorInfo_AIStickTo()
  return {
    target_actor_id = nil,
    self_socket = nil,
    target_socket = nil,
    stick_anim = nil,
    rotate = ProtoMessage:newPosition(),
    translate = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newActorInfo_AITurnTo()
  return {
    turn_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newActorInfo_AIJump()
  return {
    jump_pos = ProtoMessage:newPosition(),
    max_height = nil
  }
end

function ProtoMessage:newActorInfo_AIBezierFly()
  return {
    fly_speed = nil,
    to_pos_list = {},
    to_timestamp_list = {}
  }
end

function ProtoMessage:newActorInfo_AINavMove()
  return {
    to_time_list = {},
    to_pos_list = {},
    accept_radius = nil,
    is_backward = nil
  }
end

function ProtoMessage:newActorInfo_AIMoveMode()
  return {
    move_mode = nil,
    move_sub_mode = nil,
    height = nil,
    height_lerp_rate = nil,
    gravity = nil
  }
end

function ProtoMessage:newActorInfo_AIMoveInfo()
  return {
    move_mode = ProtoMessage:newActorInfo_AIMoveMode(),
    nav_move_info = ProtoMessage:newActorInfo_AINavMove(),
    bezier_fly_info = ProtoMessage:newActorInfo_AIBezierFly(),
    jump_info = ProtoMessage:newActorInfo_AIJump(),
    turn_to_info = ProtoMessage:newActorInfo_AITurnTo(),
    stick_to_info = ProtoMessage:newActorInfo_AIStickTo()
  }
end

function ProtoMessage:newActorInfo_AI()
  return {
    battle_ai_status = nil,
    scene_ai_control_flags = nil,
    is_hidden = nil,
    ai_seq_id = nil,
    hud_type = nil,
    hud_target_id = nil,
    anim_id = nil,
    anim_rate = nil,
    anim_is_loop = nil,
    stick_to_info = ProtoMessage:newActorInfo_AIStickTo(),
    look_at_target_id = nil,
    collision_cancel = nil,
    move_mode = ProtoMessage:newActorInfo_AIMoveMode(),
    velocity_oriented_rotation = ProtoMessage:newPosition(),
    is_velocity_oriented_rotation = nil,
    ai_override_perform_group_id = nil,
    world_combat_dots_skill_show_hide_info = ProtoMessage:newWorldCombatDotsSkillShowHideInfo(),
    perceive_player_obj_ids = {},
    ai_move_info = ProtoMessage:newActorInfo_AIMoveInfo()
  }
end

function ProtoMessage:newActorInfo_Mount()
  return {mount_status_type = nil, mount_skill_id = nil}
end

function ProtoMessage:newActorInfo_LogicStatus()
  return {
    status = nil,
    variant = nil,
    extra_data = ProtoMessage:newLogicStatusExtraData()
  }
end

function ProtoMessage:newActorInfo_GameTime()
  return {
    paused = nil,
    ref_game_time = nil,
    ref_real_time = nil,
    accelerative_ratio = nil
  }
end

function ProtoMessage:newActorInfo_NpcPendant()
  return {
    pendant_cfg_id = nil,
    enabled = nil,
    pendant_item_infos = {}
  }
end

function ProtoMessage:newActorInfo_NpcWeather()
  return {weather_type = nil}
end

function ProtoMessage:newActorInfo_AvatarWeather()
  return {weather_type = nil, area_func_cfg_id = nil}
end

function ProtoMessage:newActorInfo_CombinePetInteract()
  return {
    combine_interact_pet_infos = {},
    wait_pet_interact_avatar_id = nil
  }
end

function ProtoMessage:newActorInfo_NpcMisc()
  return {
    throw_id = nil,
    cannot_be_seen = nil,
    box_extra_reward_info_list = {},
    npc_hide_flag = nil,
    size_scale = nil
  }
end

function ProtoMessage:newActorInfo_RelatedNpcInfos()
  return {
    related_npc_infos = {}
  }
end

function ProtoMessage:newActorInfo_RelatedNpcInfo()
  return {
    type = ProtoEnum.ActorInfo_RelatedNpcInfos.RelatedNpcType.PEDAL_PET,
    npc_id = nil
  }
end

function ProtoMessage:newActorInfo_WorldMap()
  return {
    send_in_batches = nil,
    total_entry_batches = nil,
    entries = ProtoMessage:newWorldMapEntries(),
    unlocked_world_map_block_cfg_ids = {},
    main_scene_pt = ProtoMessage:newPoint(),
    layered_world_map_explore_info = ProtoMessage:newLayeredWorldMapExploreInfo(),
    main_scene_pt_effect_areas = {},
    auto_track_npc_infos = {}
  }
end

function ProtoMessage:newActorInfo_Card()
  return {
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_skin_selected = nil,
    card_icon_selected = nil
  }
end

function ProtoMessage:newWorldCombatExtraRewardInfo()
  return {
    extra_reward_id = nil,
    extra_reward_cond_type = nil,
    extra_reward_cond_param1 = nil,
    extra_reward_process = nil,
    extra_reward_status = nil
  }
end

function ProtoMessage:newActorInfo_WorldCombat()
  return {
    world_combat_id = nil,
    world_combat_cfg_id = nil,
    avatar_id = {},
    world_combat_phase = nil,
    extra_reward_info = {}
  }
end

function ProtoMessage:newAvatar2ExtraReward()
  return {
    avatar_id = nil,
    extra_reward_list = {}
  }
end

function ProtoMessage:newNpcGuideInfo()
  return {
    guide_type = nil,
    npc_refresh_point = nil,
    npc_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newWorldCombatSkillTarget()
  return {
    target_id = nil,
    target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newActorInfo_WorldCombatSkill()
  return {
    skill_id = nil,
    caster_pos = ProtoMessage:newPoint(),
    target_id = nil,
    target_pos = ProtoMessage:newPosition(),
    current_time = nil,
    target_group = {},
    actions_data = {},
    show_hide_info = ProtoMessage:newWorldCombatDotsSkillShowHideInfo()
  }
end

function ProtoMessage:newActorInfo_NpcGuide()
  return {
    guide_infos = {}
  }
end

function ProtoMessage:newActorInfo_NpcFollow()
  return {
    follow_id = nil,
    state = nil,
    default_talk_id = nil
  }
end

function ProtoMessage:newActorInfo_Handbook()
  return {
    handbook_records = {}
  }
end

function ProtoMessage:newActorInfo_TaskState()
  return {
    enabled_state_ids = {}
  }
end

function ProtoMessage:newActorInfo_MagicCreateNpc()
  return {
    magic_create_npcs = {}
  }
end

function ProtoMessage:newActorInfo_AOwlSanctuary()
  return {
    owl_sanctuarys = {},
    uin = nil
  }
end

function ProtoMessage:newActorInfo_MoveInfo()
  return {
    move_info = ProtoMessage:newMoveInfo()
  }
end

function ProtoMessage:newActorInfo_CatchRecordInfo()
  return {
    catch_info = ProtoMessage:newCatchRecordInfo()
  }
end

function ProtoMessage:newAvatarEnterdPropInfo()
  return {entered_npc_id = nil, slot_idx = nil}
end

function ProtoMessage:newActorInfo_RoleplayPropInfo()
  return {
    entered_prop_info = ProtoMessage:newAvatarEnterdPropInfo()
  }
end

function ProtoMessage:newCellInfo_HomePlantInfo()
  return {
    home_plant_land_list = {}
  }
end

function ProtoMessage:newActorInfo_HomePlantInfo()
  return {
    cell_home_plant_info = ProtoMessage:newCellInfo_HomePlantInfo(),
    actor_plant_data = ProtoMessage:newActorPlantData()
  }
end

function ProtoMessage:newActorInfo_AirWall()
  return {
    air_wall_info = ProtoMessage:newAirWallInfo()
  }
end

function ProtoMessage:newActorInfo_HomePet()
  return {
    home_pet_info = ProtoMessage:newHomePetInfo()
  }
end

function ProtoMessage:newActorInfo_AttachItem()
  return {attach_item_type = nil, attach_item_id = nil}
end

function ProtoMessage:newActorInfo_RelationInteract()
  return {
    type = ProtoEnum.InteractInviteType.IIT_INVALID,
    sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE,
    status = ProtoEnum.DoubleTogetherStatus.DTS_NONE,
    param = ProtoMessage:newInteractParam(),
    uin1p = nil,
    uin2p = nil
  }
end

function ProtoMessage:newActorInfo_AvatarCamera()
  return {
    skin_id = nil,
    unlock_skin_ids = {}
  }
end

function ProtoMessage:newAIMutualPerformStateInfo()
  return {mutual_perform_id = nil, npc_obj_id = nil}
end

function ProtoMessage:newActorInfo_AvatarAI()
  return {
    mutual_changed_list = {}
  }
end

function ProtoMessage:newActorInfo_Npc()
  return {
    base = ProtoMessage:newActorInfo_Base(),
    attrs = ProtoMessage:newActorInfo_NpcAttrs(),
    npc_base = ProtoMessage:newActorInfo_NpcBase(),
    drop_item = ProtoMessage:newActorInfo_DropItem(),
    npc_interact = ProtoMessage:newActorInfo_NpcInteract(),
    combine_lock = ProtoMessage:newActorInfo_CombineLock(),
    potential_energy_info = ProtoMessage:newActorInfo_PotentialEnergy(),
    pet_info = ProtoMessage:newActorInfo_Pet(),
    property_type_info = ProtoMessage:newActorInfo_PropertyType(),
    status_info = {},
    pendant_info = {},
    weather_info = ProtoMessage:newActorInfo_NpcWeather(),
    combine_interact_info = ProtoMessage:newActorInfo_CombinePetInteract(),
    misc_info = ProtoMessage:newActorInfo_NpcMisc(),
    buff_info = ProtoMessage:newActorInfo_Buffs(),
    ai_info = ProtoMessage:newActorInfo_AI(),
    related_npc_infos = ProtoMessage:newActorInfo_RelatedNpcInfos(),
    world_combat_info = ProtoMessage:newActorInfo_WorldCombat(),
    world_combat_skill_info = ProtoMessage:newActorInfo_WorldCombatSkill(),
    home_pet = ProtoMessage:newActorInfo_HomePet(),
    attach_item_info = ProtoMessage:newActorInfo_AttachItem(),
    npc_prop = ProtoMessage:newActorInfo_NpcProp()
  }
end

function ProtoMessage:newActorInfo_Avatar()
  return {
    base = ProtoMessage:newActorInfo_Base(),
    attrs = ProtoMessage:newActorInfo_AvatarAttrs(),
    mount = ProtoMessage:newActorInfo_Mount(),
    story = ProtoMessage:newActorInfo_Story(),
    avatar_interact = ProtoMessage:newActorInfo_AvatarInteract(),
    avatar_status = ProtoMessage:newActorInfo_AvatarDetailStatus(),
    aura_infos = {},
    throwed_pet_infos = {},
    status_info = {},
    game_time_infos = ProtoMessage:newActorInfo_GameTime(),
    weather_info = ProtoMessage:newActorInfo_AvatarWeather(),
    scene_pet_info = ProtoMessage:newActorInfo_ScenePets(),
    buff_info = ProtoMessage:newActorInfo_Buffs(),
    world_map_info = ProtoMessage:newActorInfo_WorldMap(),
    card_info = ProtoMessage:newActorInfo_Card(),
    guide_info = ProtoMessage:newActorInfo_NpcGuide(),
    follow_info = ProtoMessage:newActorInfo_NpcFollow(),
    handbook_info = ProtoMessage:newActorInfo_Handbook(),
    task_state_info = ProtoMessage:newActorInfo_TaskState(),
    magic_create_npc_info = ProtoMessage:newActorInfo_MagicCreateNpc(),
    fashion_item_wear_data = {},
    salon_item_wear_data = {},
    move_info = ProtoMessage:newActorInfo_MoveInfo(),
    air_wall = ProtoMessage:newActorInfo_AirWall(),
    home_basic_info = ProtoMessage:newActorInfo_HomeBasicInfo(),
    home_plant_info = ProtoMessage:newActorInfo_HomePlantInfo(),
    inner_battle = ProtoMessage:newActorInfo_InnerBattle(),
    steal_home_info = ProtoMessage:newActorInfo_StealHomeInfo(),
    relation_interact = ProtoMessage:newActorInfo_RelationInteract(),
    uin_owl_sanctuary_info = {},
    catch_record_info = ProtoMessage:newActorInfo_CatchRecordInfo(),
    wearing_item = {},
    roleplay_prop_info = ProtoMessage:newActorInfo_RoleplayPropInfo(),
    camera_info = ProtoMessage:newActorInfo_AvatarCamera(),
    avatar_ai_info = ProtoMessage:newActorInfo_AvatarAI()
  }
end

function ProtoMessage:newActorInfo_StealHomeInfo()
  return {
    total_steal_num = nil,
    steal_of_home_pets = {}
  }
end

function ProtoMessage:newActorInfo_HomeBasicInfo()
  return {
    my_home_info = ProtoMessage:newHomeInfo(),
    target_home_info = ProtoMessage:newHomeInfo(),
    reason = ProtoEnum.ActorInfo_HomeBasicInfo.ReloadReason.RELOAD_REASON_NONE
  }
end

function ProtoMessage:newActorInfo_Pet()
  return {
    gid = nil,
    medal_conf_id = nil,
    medal_fx_level = nil,
    pet_base_conf_id = nil,
    ball_id = nil,
    closeness_lv = nil
  }
end

function ProtoMessage:newActorInfo_ScenePet()
  return {
    gid = nil,
    npc_id = nil,
    interact_quantity = nil,
    interact_quantity_threshold = nil,
    interact_count = nil
  }
end

function ProtoMessage:newActorInfo_ScenePets()
  return {
    pet_infos = {}
  }
end

function ProtoMessage:newActorInfo_Monster()
  return {
    base = ProtoMessage:newActorInfo_Base()
  }
end

function ProtoMessage:newActorInfo_Wardrobe()
  return {
    fashion_wear_id = {},
    wardrobe_name = nil
  }
end

function ProtoMessage:newActorInfo_FashionSuitInfo()
  return {suit_id = nil, petbase_pvp_win_num = nil}
end

function ProtoMessage:newActorInfo()
  return {
    actor_detail_type = nil,
    npc = ProtoMessage:newActorInfo_Npc(),
    avatar = ProtoMessage:newActorInfo_Avatar(),
    monster = ProtoMessage:newActorInfo_Monster()
  }
end

function ProtoMessage:newGuideInfo()
  return {
    go_index = nil,
    dest_scene_cfg_id = nil,
    dest_res_cfg_id = nil,
    dest_npc_id = nil,
    dest_refresh_content_id = nil,
    dest_pos = ProtoMessage:newPosition(),
    target_scene_cfg_id = nil,
    target_res_cfg_id = nil,
    target_npc_id = nil,
    target_refresh_content_id = nil,
    target_pos = ProtoMessage:newPosition(),
    map_scene_cfg_id = nil,
    map_res_cfg_id = nil,
    map_npc_id = nil,
    map_refresh_content_id = nil,
    map_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newTaskTrackingItem()
  return {
    task_id = nil,
    type = ProtoEnum.TrackNpcType.TNT_NONE,
    guide_list = {}
  }
end

function ProtoMessage:newNpcInteractRewardItemInfo()
  return {
    item_id = nil,
    item_type = nil,
    display_tag = nil,
    item_num = nil
  }
end

function ProtoMessage:newInteractActionResult()
  return {
    action_type = nil,
    action_result = nil,
    dialog_id = nil,
    bind_dialog_id = nil,
    accept_task_id = nil,
    only_battle_pets = nil,
    include_dead_pets = nil,
    is_fixed_value = nil,
    add_pet_hp_val = nil,
    charge_bagitem_id = nil,
    chapter_id = nil,
    add_role_energy_val = nil,
    pet_exp_award_type = nil,
    pet_exp_award_value = nil,
    award_pet_gid = nil,
    add_role_hp_val = nil,
    add_role_hp_max_val = nil,
    star_award_sub_value = nil,
    action_result_params = nil,
    option_excutable_times = nil,
    award_pet_gid_vec = {},
    star_type = nil,
    pet_gift_id = nil,
    plant_id = nil,
    seed_id = nil,
    item_id = nil,
    item_count = nil,
    experience_gained = nil,
    clear_half_hp_injure = nil
  }
end

function ProtoMessage:newBeginActResult()
  return {
    action_type = nil,
    action_result_params = {}
  }
end

function ProtoMessage:newNpcInteractResult()
  return {
    option_id = nil,
    action_results = {},
    begin_act_results = {},
    is_option_finished = nil,
    trig_interact_type = nil,
    npc_content_cfg_id = nil,
    pet_interact_id = nil,
    throw_pet_gids = {},
    npc_belong_pet_gid = nil
  }
end

function ProtoMessage:newOldFlavorSceneRequiredPlayerInfo()
  return {
    name = nil,
    lv = nil,
    gender = nil,
    ingame_time = nil,
    last_update_ingame = nil,
    hp_max = nil,
    world_lv = nil,
    openid = nil,
    client_version = nil,
    is_reconnect = nil,
    client_ip = nil,
    client_ipv6 = nil,
    quality = nil,
    plat_info = ProtoMessage:newPlatInfo(),
    client_info = ProtoMessage:newClientInfo(),
    player_story_flag_info = ProtoMessage:newPlayerStoryFlagInfo(),
    visit_owner_uin = nil,
    visit_owner_obj_id = nil,
    login_leave_visiting = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_skin_selected = nil,
    card_icon_selected = nil,
    card_music_id = nil,
    handbook_records = {},
    fashion_item_wear_data = {},
    salon_item_wear_data = {},
    fashion_bond_data = {},
    wearing_item = {},
    spec_flower_seeds = {},
    sns_auth_info = ProtoMessage:newSnsAuthInfo(),
    season_info = ProtoMessage:newSceneSeasonInfo(),
    npc_refresh_ban_info = ProtoMessage:newPlayerNpcRefreshBanInfo(),
    func_ban_items = {},
    pet_gids = {},
    current_select_pet_gid = nil,
    big_world_pet_data = {},
    main_team_gids = {}
  }
end

function ProtoMessage:newSceneRequiredPlayerInfo()
  return {
    player_tags = {},
    daily_online_time = nil,
    together_starlight_bonus_ratio = nil
  }
end

function ProtoMessage:newTransformStoryFlagData()
  return {need_delete_story_flag = nil}
end

function ProtoMessage:newSceneCorrectedPlayerInfo()
  return {
    dungeon_corrected_player_info = ProtoMessage:newSceneDungeonCorrectedPlayerInfo()
  }
end

function ProtoMessage:newSpaceObjPartData_InstalledComp()
  return {
    comps = {}
  }
end

function ProtoMessage:newActorPartData_Base()
  return {
    id = nil,
    logic_id = nil,
    born_time = nil,
    enter_scene_times = nil,
    name = nil,
    gender = nil,
    cell_id = nil,
    born_pos = ProtoMessage:newPosition(),
    born_dir = nil,
    born_dir_x = nil,
    born_dir_y = nil,
    pos = ProtoMessage:newPosition(),
    dir = nil,
    dir_x = nil,
    dir_y = nil
  }
end

function ProtoMessage:newActorPartData_NpcBase()
  return {
    npc_cfg_id = nil,
    traverse_data_type = nil,
    height = nil,
    weight = nil,
    nature = nil,
    npc_content_cfg_id = nil,
    mutation_type = nil,
    npc_refresh_source = nil,
    npc_owl_content_id = nil,
    rand = nil,
    src_npc_logic_id = nil,
    src_npc_id = nil,
    src_npc_cfg_id = nil,
    src_npc_ref_cfg_id = nil,
    src_npc_pos = ProtoMessage:newPosition(),
    pos_need_adjust = nil,
    world_nature = nil,
    world_hide = nil,
    related_npc_pos = ProtoMessage:newPosition(),
    refresh_point = nil,
    create_avatar_id = nil,
    blood_mix_skill_dam_type = nil,
    first_create_time = nil,
    loop_action = nil,
    catch_guarantee_rate = nil,
    last_catch_time = nil,
    children_npc_list = {},
    refresh_time = nil,
    deep_delete_reason = nil,
    can_be_teleport = nil,
    height_scale = nil,
    owner_id = nil,
    last_attr_reset_time = nil,
    blood_normal_skill_dam_type = nil,
    block_id = nil,
    home_plant_land_id = nil,
    auto_refresh = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    attach_item_type = nil,
    attach_item_id = nil,
    voice = nil,
    create_visiting_uins = {},
    create_avatar_name = nil,
    npc_belong_owl_content_id = nil,
    refresh_batch_id = nil
  }
end

function ProtoMessage:newActorPartData_AvatarBase()
  return {
    entered_scene_cfg_id = {}
  }
end

function ProtoMessage:newActorPartData_SceneNpc()
  return {scene_npc_cfg_id = nil, is_server_ai = nil}
end

function ProtoMessage:newActorPartData_GrassNpc()
  return {grass_cfg_id = nil, refresh_cfg_id = nil}
end

function ProtoMessage:newActorPartData_TaskNpc()
  return {task_npc_cfg_id = nil}
end

function ProtoMessage:newActorPartData_DropItem()
  return {
    batch_num = nil,
    drop_count = nil,
    sequence_id_in_batch = nil
  }
end

function ProtoMessage:newTriggerMoveHist()
  return {
    combine_id = nil,
    reset_type = nil,
    prev_pos_info = {},
    is_reset = nil
  }
end

function ProtoMessage:newActorPartData_Trigger()
  return {
    move_history = {}
  }
end

function ProtoMessage:newActorCompData_Test()
  return {
    int32_val = nil,
    int64_val = nil,
    int32_arr_val = {},
    str_val1 = nil,
    str_val2 = nil,
    str_arr_val1 = {},
    str_arr_val2 = {},
    test_1 = nil,
    test_2 = nil,
    test_3 = nil
  }
end

function ProtoMessage:newActorCompData_MsgSender()
  return {}
end

function ProtoMessage:newActorCompData_Broadcaster()
  return {ring_bst_limit = nil, ring_be_joined_bst_limit = nil}
end

function ProtoMessage:newActorCompData_AreaMgr()
  return {}
end

function ProtoMessage:newActorCompData_ClientMover()
  return {platform_actor_id = nil}
end

function ProtoMessage:newActorCompData_Owner()
  return {owner_id = nil}
end

function ProtoMessage:newCombineNpcCondInfo()
  return {
    is_deleted = nil,
    is_completed = nil,
    cond_type = nil,
    cond_idx = nil,
    content_point = nil,
    execute_times = nil,
    complete_idx = nil
  }
end

function ProtoMessage:newCombincNpcResultInfo()
  return {
    is_completed = nil,
    npc_guide = nil,
    result_type = nil,
    content_point = nil,
    guide_type = nil,
    lock_guide = nil
  }
end

function ProtoMessage:newCombineNpcInfo()
  return {
    combine_id = nil,
    remain_result_times = nil,
    add_time = nil,
    total_finished_times = nil,
    cond_info = {},
    is_completed = nil,
    result_info = {},
    is_keep = nil,
    version = nil
  }
end

function ProtoMessage:newActorCompData_CombineNpc()
  return {
    combine_npc_info = {},
    finished_combine_id = {}
  }
end

function ProtoMessage:newActorCompData_ServerMover()
  return {}
end

function ProtoMessage:newPermanentNpcInfo()
  return {obj_id = nil, logic_id = nil}
end

function ProtoMessage:newActorCompData_NpcInstantiator()
  return {
    permanent_npc_list = {},
    permanent_npcs = {}
  }
end

function ProtoMessage:newGeneratedContent()
  return {content_id = nil, block_id = nil}
end

function ProtoMessage:newWaitGenerateContentData()
  return {
    content_id = nil,
    point_idx = nil,
    npc_refresh_source = nil
  }
end

function ProtoMessage:newExhaustedContentData()
  return {content_id = nil, exhausted_num = nil}
end

function ProtoMessage:newAvatarNpcRefreshInfo_Refresh()
  return {
    refresh_cfg_id = nil,
    mark_delete = nil,
    last_npc_data_reset_time = nil,
    init_content = nil,
    last_rand_reset_time = nil,
    content_order = nil,
    wave = nil,
    last_wave_time = nil,
    refreshed_scene_cfg_ids = {},
    all_delete_time = nil,
    generated_contents = {},
    wait_generate_contents = {},
    reset_contents = {},
    flower_seed_boss_datas = {},
    exhausted_contents = {},
    opened_content_ids = {},
    rand_rule_reseting = nil
  }
end

function ProtoMessage:newOwlContentMetaData()
  return {
    owl_sanctuary_content_npc_cfg_id = nil,
    owl_sanctuary_content_cfg_id = nil,
    is_owl_sanctuary_content_advantage = nil,
    owl_sanctuary_content_area_id = nil,
    owl_sanctuary_refresh_max_num = nil,
    owl_sanctuary_refresh_storage_num = nil,
    owl_sanctuary_habitat_id = nil
  }
end

function ProtoMessage:newContentMetaData()
  return {
    first_npc_killed_time = nil,
    prev_npc_killed_time = nil,
    last_storage_reset_time = nil,
    remain_storage = nil,
    last_refresh_time = nil,
    last_delete_time = nil,
    excuting = nil,
    scene_id = nil,
    reason = nil,
    unique_id = nil,
    version = nil,
    refresh_source = nil,
    rand_refresh_ingame_time = nil,
    rand_refreshed_today = nil,
    owl_data = ProtoMessage:newOwlContentMetaData()
  }
end

function ProtoMessage:newInGameTimeIntervalRefreshCheckInfo()
  return {
    time_interval_id = nil,
    in_time_checked = nil,
    not_in_time_checked = nil
  }
end

function ProtoMessage:newSceneNpcDynPos()
  return {
    npc_logic_id = nil,
    npc_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newActorCompData_StoryFlag()
  return {
    story_flags = {}
  }
end

function ProtoMessage:newNpcOptionData_SelectInfo()
  return {
    select_id = nil,
    enabled = nil,
    remaining_times = nil,
    last_reset_time = nil,
    reset_after_interact = nil,
    has_been_selected = nil,
    exhausted_time = nil,
    dialog_id = nil,
    has_been_selected_times = nil
  }
end

function ProtoMessage:newNpcOptionData_ActionInfo()
  return {
    act_type = nil,
    act_status = nil,
    act_exec_success = nil,
    bound_dialog_id = nil,
    act_result_type = nil,
    dialog_id = nil,
    btle_cfg_id = nil,
    accept_task_id = nil,
    only_battle_pets = nil,
    include_dead_pets = nil,
    is_fixed_value = nil,
    add_pet_hp_val = nil,
    battle_result = nil,
    charge_bagitem_id = nil,
    chapter_id = nil,
    add_role_energy_val = nil,
    add_role_hp_val = nil,
    add_role_hp_max_val = nil,
    add_exp_pet_gid = nil,
    timeout_time = nil,
    star_award_sub_value = nil,
    can_pet_submit = nil,
    act_param1 = nil,
    act_param2 = nil,
    act_param3 = nil,
    add_exp_pet_gid_vec = {},
    camp_pet_report_id = nil,
    act_params = {},
    next_dialog_id = nil,
    dialog_skip_state = nil,
    clear_half_hp_injure = nil
  }
end

function ProtoMessage:newSubmitItemFreeList()
  return {
    dialog_id = nil,
    item_conf_ids = {}
  }
end

function ProtoMessage:newNpcOptionData_CooldownInfo()
  return {cooldown_enter_time = nil, remaining_times = nil}
end

function ProtoMessage:newNpcOptionExtraData()
  return {
    submit_item_free_list = {},
    battle_difficulty_id = nil,
    battle_cfg_id = nil
  }
end

function ProtoMessage:newNpcOptionStashExtraData()
  return {action_reward_id = nil}
end

function ProtoMessage:newNpcOptionData()
  return {
    option_id = nil,
    enabled = nil,
    executable_times = nil,
    last_reset_time = nil,
    story_flags = {},
    select_infos = {},
    cur_action_info = ProtoMessage:newNpcOptionData_ActionInfo(),
    removed_select_ids = {},
    reset_after_interact = nil,
    cur_selected_select_ids = {},
    dec_executable_times_after_interact = nil,
    ignore_reset = nil,
    trig_interact_type = nil,
    enable_opt_gid = nil,
    succ_exec_times = nil,
    first_dialog_id = nil,
    pet_interact_id = nil,
    interact_avatar_id = nil,
    direct_interact_actor_id = nil,
    exhausted_time = nil,
    trig_interact_pet_gid = nil,
    option_params = {},
    dialog_begin_params = {},
    task_disable_flag = nil,
    dynamic_select_id = nil,
    extra_data = ProtoMessage:newNpcOptionExtraData(),
    need_permanent_npc = nil,
    cooldown_info = ProtoMessage:newNpcOptionData_CooldownInfo(),
    stash_extra_data = ProtoMessage:newNpcOptionStashExtraData(),
    white_list_uins = {},
    black_list_uins = {}
  }
end

function ProtoMessage:newVisitorOnly_NpcOptionData()
  return {
    visitor_id = nil,
    option_datas = {}
  }
end

function ProtoMessage:newCombineInteractPetInfo()
  return {pet_gid = nil, pet_obj_id = nil}
end

function ProtoMessage:newPetCombineInteractData()
  return {
    wait_pet_interact_cfg_id = nil,
    wait_pet_interact_avatar_id = nil,
    wait_pet_interact_option_id = nil,
    combine_interact_pet_infos = {},
    status = nil
  }
end

function ProtoMessage:newSeatNpcSitData()
  return {sit_avatar_id = nil}
end

function ProtoMessage:newActorCompData_NpcInteractor()
  return {
    option_datas = {},
    reset_after_interact = nil,
    del_npc_after_interact = nil,
    pend_del_npc_option_ids = {},
    visitor_only_option_datas = {},
    is_specity_effect = nil,
    combine_interact_data = ProtoMessage:newPetCombineInteractData(),
    del_options = {},
    seat_datas = {},
    del_npc_after_interact_reason = nil
  }
end

function ProtoMessage:newFailTaskAction()
  return {
    action_type = nil,
    npc_obj_id = nil,
    npc_logic_id = nil,
    option_id = nil,
    loop_action = nil,
    refresh_id = nil
  }
end

function ProtoMessage:newTaskState()
  return {task_id = nil, state = nil}
end

function ProtoMessage:newActorCompData_Task()
  return {
    resurrection_id = {},
    enable_guide_task_id = {},
    accepted_guide_task_id = {},
    track_task = nil,
    fail_actions = {},
    tasks = {}
  }
end

function ProtoMessage:newAvatarPetInfo()
  return {
    follow_pet_id = nil,
    pet_base_conf_id = nil,
    pet_name = nil
  }
end

function ProtoMessage:newAreaWeather()
  return {area_id = nil, weather = nil}
end

function ProtoMessage:newActorWeatherInfo()
  return {
    weather_list = {}
  }
end

function ProtoMessage:newAvatarBehaviorStatusInfo()
  return {
    avatar_behavior_status = nil,
    avatar_behavior_sub_status = nil,
    status_params = ProtoMessage:newPlayerStatusCustomParams()
  }
end

function ProtoMessage:newStorageItemInfo()
  return {
    npc_cfg_id = nil,
    goods_type = nil,
    goods_id = nil,
    goods_num = nil
  }
end

function ProtoMessage:newMagicCreateNpcInfo()
  return {
    npc_obj_id = nil,
    npc_logic_id = nil,
    npc_cfg_id = nil,
    npc_refresh_id = nil,
    npc_pos = ProtoMessage:newPosition(),
    world_map_cfg_id = nil,
    teleport_point = ProtoMessage:newPoint(),
    cell_id = nil,
    wand_id = nil
  }
end

function ProtoMessage:newActorCompData_AvatarMisc()
  return {
    pos_sync_flag = nil,
    pet_info = ProtoMessage:newAvatarPetInfo(),
    env_mask = nil,
    owl_sanctuary_npc_refresh_content_id = nil,
    owl_sanctuary_level_up = {},
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_skin_selected = nil,
    card_icon_selected = nil,
    openid = nil,
    client_version = nil,
    handbook_records = {},
    client_ip = nil,
    client_ipv6 = nil,
    quality = nil,
    plat_info = ProtoMessage:newPlatInfo(),
    client_info = ProtoMessage:newClientInfo(),
    sns_auth_info = ProtoMessage:newSnsAuthInfo(),
    test_1 = nil,
    test_2 = nil,
    test_3 = nil,
    enter_strong_storm = nil,
    last_sub_hp_time = nil,
    last_unstuck_time = nil,
    avatar_behavior_status_infos = {},
    end_transform_time = nil,
    transform_area_func_id = nil,
    check_transform_time = nil,
    guide_info = {},
    pvp_match_npc_id = nil,
    pvp_match_pvp_id = nil,
    pvp_match_start_ut = nil,
    pvp_match_dst_inst_id = nil,
    storage_items = {},
    card_music_id = nil,
    magic_create_npcs = {},
    camera_npc_id = nil,
    camera_skin_id = nil,
    unlock_skin_ids = {},
    cave_area_func_id = nil,
    difficulty_infos = {},
    nightmare_records = {},
    consume_states = ProtoMessage:newOfflineOperationConsumeState(),
    scene_required_player_info = ProtoMessage:newSceneRequiredPlayerInfo(),
    trans_form_story_flag_data = ProtoMessage:newTransformStoryFlagData()
  }
end

function ProtoMessage:newPedalData()
  return {
    pet_gid = nil,
    pet_npc_id = nil,
    avatar_id = nil,
    option_id = nil
  }
end

function ProtoMessage:newBoxData()
  return {
    other_box_npc_ids = {},
    inner_npc_content_id = nil,
    bonus_type = nil,
    box_type = ProtoEnum.BoxType.BOX_TYPE_INVALID,
    certain_box_info = ProtoMessage:newBoxMonsterInfo()
  }
end

function ProtoMessage:newActorCompData_NpcMisc()
  return {
    belong_pet_gid = nil,
    magic_change_avatar_name = nil,
    ball_cfg_id = nil,
    throw_id = nil,
    can_be_seen_avatar_id = nil,
    pedal_data = ProtoMessage:newPedalData(),
    cannot_be_seen = nil,
    world_combat_box_extra_reward_list = {},
    ai_override_perform_group_id = nil,
    box_extra_reward_info_list = {},
    pet_catched_ball_id = nil,
    npc_hide_flag = nil,
    property_types = {},
    is_fixed = nil,
    box_data = ProtoMessage:newBoxData(),
    season_pet_info = ProtoMessage:newSeasonPetInfo(),
    size_scale = nil,
    skip_attr_reset = nil
  }
end

function ProtoMessage:newActorCompData_Transform()
  return {}
end

function ProtoMessage:newActorCompData_StatusGuarder()
  return {}
end

function ProtoMessage:newActorCompData_AI()
  return {}
end

function ProtoMessage:newActorCompData_Navigator()
  return {
    affect_nav_dynamic_npc_datas = {}
  }
end

function ProtoMessage:newActorAttrsDatas_Base()
  return {
    lv = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    hp = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    hp_max = ProtoMessage:newCreatureAttrs_ComplexAttr32(),
    move_spd = ProtoMessage:newCreatureAttrs_ComplexAttr32(),
    attrs = {}
  }
end

function ProtoMessage:newActorAttrsDatas_Npc()
  return {
    base_attrs = ProtoMessage:newActorAttrsDatas_Base(),
    attrs = {}
  }
end

function ProtoMessage:newActorAttrsDatas_Avatar()
  return {
    base_attrs = ProtoMessage:newActorAttrsDatas_Base(),
    body_temp = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    world_lv = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    stamina = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    stamina_max = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    hp_temporary = ProtoMessage:newCreatureAttrs_SimpleAttr32(),
    attrs = {}
  }
end

function ProtoMessage:newActorCompData_AttrMgr()
  return {
    base_attrs = ProtoMessage:newActorAttrsDatas_Base(),
    avatar_attrs = ProtoMessage:newActorAttrsDatas_Avatar(),
    npc_attrs = ProtoMessage:newActorAttrsDatas_Npc()
  }
end

function ProtoMessage:newActorCompData_AnimSkillPlayer()
  return {}
end

function ProtoMessage:newActorCompData_Db()
  return {}
end

function ProtoMessage:newContentTraceData()
  return {
    content_id = nil,
    npc_num = nil,
    reset_storage_start_time = nil
  }
end

function ProtoMessage:newNpcTraceData()
  return {
    npc_cfg_id = nil,
    trace_datas = {}
  }
end

function ProtoMessage:newNpcTraceQueryResult()
  return {
    npc_cfg_id = nil,
    pet_base_id = nil,
    content_id = nil,
    area_cfg_id = nil,
    dist = nil
  }
end

function ProtoMessage:newNpcTraceQueryInfo()
  return {
    query_npc_cfg_ids = {},
    final_result = ProtoMessage:newNpcTraceQueryResult(),
    query_npc_content_ids = {}
  }
end

function ProtoMessage:newActorCompData_NpcTrace()
  return {
    npc_trace_datas = {},
    query_info = ProtoMessage:newNpcTraceQueryInfo(),
    fix_data_time = nil
  }
end

function ProtoMessage:newActorCompData_HomeBasic()
  return {
    home_brief_info = ProtoMessage:newPlayerHomeBriefInfo(),
    home_team_info = ProtoMessage:newPlayerHomeTeamInfo()
  }
end

function ProtoMessage:newActorCompData_HomePlant()
  return {
    reset_timestamp = nil,
    actor_plant_data = ProtoMessage:newActorPlantData()
  }
end

function ProtoMessage:newActorCompData_HomePlantNpc()
  return {}
end

function ProtoMessage:newActorCompData_TeamBattle()
  return {
    team = ProtoMessage:newTeamBattleTeamInfo(),
    match_info = ProtoMessage:newTeamBattleMatchInfo(),
    team_battle_results = {}
  }
end

function ProtoMessage:newActorCompData_Feed()
  return {last_notify_time = nil}
end

function ProtoMessage:newActorCompData_VisibleArea()
  return {
    enter_exclude_battle_cfg_id = nil,
    switching_to_dest_area_id = nil,
    switching_to_dest_cell_id = nil,
    last_visible_area_id = nil,
    last_visible_plan_id = nil,
    last_leave_time = nil,
    last_offline_time = nil,
    pre_tele_enter_area_id = nil,
    pre_tele_enter_cell_id = nil
  }
end

function ProtoMessage:newActorCompData_VisibleCircle()
  return {circle_id = nil}
end

function ProtoMessage:newThiefInfo()
  return {uin = nil}
end

function ProtoMessage:newActorCompData_HomePet()
  return {
    home_pet_info = ProtoMessage:newHomePetInfo(),
    display_info = ProtoMessage:newHomePetDisplayInfo(),
    thiefs = {},
    egg_obj_id = nil,
    pet_data = ProtoMessage:newHomePetData()
  }
end

function ProtoMessage:newActorCompData_NpxCollision()
  return {}
end

function ProtoMessage:newActorCompData_NpxCapsuleCCT()
  return {}
end

function ProtoMessage:newActorCompData_Heartbeat()
  return {}
end

function ProtoMessage:newActorCompData_AI_LOD()
  return {}
end

function ProtoMessage:newFriendRideData()
  return {uin = nil, gid = nil}
end

function ProtoMessage:newActorCompData_Rider()
  return {
    is_riding = nil,
    ride_pet_gid = nil,
    added_ride_buff_id = nil,
    ride_pet_base_id = nil,
    ride_friend_pet_gid = nil,
    ride_friend_uin = nil,
    friend_ride_datas = {}
  }
end

function ProtoMessage:newActorCompData_Skill()
  return {}
end

function ProtoMessage:newActorCompData_Battle()
  return {
    battle_npc_id = nil,
    battle_npc_logic_id = nil,
    option_id = nil,
    create_info = ProtoMessage:newCreateBattleInfo(),
    has_battle_settled = nil,
    has_battle_ended = nil,
    is_rt_team_fight = nil,
    battle_type = nil,
    battle_start_game_time = nil,
    info = ProtoMessage:newInnerBattleInfo(),
    enter_battle_time = nil,
    catched_npc_obj_ids = {},
    is_allow_observe = nil,
    visit_owner_uin = nil
  }
end

function ProtoMessage:newShareAuraInfo()
  return {
    is_visible_plan_share = nil,
    src_avatar_uin = nil,
    src_aura_id = nil,
    reason = ProtoEnum.ShareAuraReason.SAR_NONE
  }
end

function ProtoMessage:newAuraInfo()
  return {
    id = nil,
    aura_conf_id = nil,
    pos = ProtoMessage:newPosition(),
    belong_actor_id = nil,
    is_avatar_in_aura = nil,
    time_out_time = nil,
    tick_time_out_time = nil,
    create_actor_id = nil,
    enabled = nil,
    dir = nil,
    create_time = nil,
    params = {},
    radius = nil,
    belong_logic_id = nil,
    create_logic_id = nil,
    create_game_time = nil,
    create_avatar_id = nil,
    from_battle = nil,
    create_scene_cfg_id = nil,
    share_info = ProtoMessage:newShareAuraInfo(),
    is_born_create = nil
  }
end

function ProtoMessage:newActorCompData_AuraMgr()
  return {
    max_aura_id = nil,
    aura_infos = {},
    born_aura_infos = {}
  }
end

function ProtoMessage:newActorCompData_AvatarInteractor()
  return {
    interact_npc_id = nil,
    interact_npc_logic_id = nil,
    is_interact_as_visitor = nil,
    sit_npc_id = nil,
    sit_seat_idx = nil,
    interact_result = ProtoMessage:newNpcInteractResult()
  }
end

function ProtoMessage:newActorCompData_NonAvatarIdGen()
  return {
    actor_max_ids = {}
  }
end

function ProtoMessage:newThrowingMagicInfo()
  return {magic_cfg_id = nil, num = nil}
end

function ProtoMessage:newThrowedBagItemInfo()
  return {
    bagitem_cfg_id = nil,
    npc_id = nil,
    npc_logic_id = nil
  }
end

function ProtoMessage:newThrowCatchResultData()
  return {
    throw_id = nil,
    catch_begin_time = nil,
    scene_catch_result = ProtoMessage:newSceneCatchResult()
  }
end

function ProtoMessage:newActorCompData_Thrower()
  return {
    throw_pet_info = {},
    begin_throw_info = {},
    max_throw_id = nil,
    throwing_magic_info = {},
    bagitem_infos_thrown_in_visiting = {},
    wait_pet_interact_gids = {},
    throw_seat_info = ProtoMessage:newThrowSeatInfo(),
    throw_catch_result_datas = {}
  }
end

function ProtoMessage:newActorCompData_WorldMap()
  return {
    area_infos = {},
    unlocked_world_map_block_cfg_ids = {},
    normal_mark_infos = {},
    pet_mark_infos = {},
    next_mark_id = nil,
    main_scene_pt = ProtoMessage:newPoint(),
    syncing = nil,
    sync_entry_types = nil,
    gamecfg_ver = nil,
    layered_world_map_explore_info = ProtoMessage:newLayeredWorldMapExploreInfo(),
    auto_track_npc_infos = {}
  }
end

function ProtoMessage:newActorCompData_PotentialEnergy()
  return {
    enabled = nil,
    cur_potential_energys = {}
  }
end

function ProtoMessage:newActorCompData_Temperature()
  return {reduce_hp_aura_id = nil}
end

function ProtoMessage:newActorCompData_NpcCamp()
  return {level = nil}
end

function ProtoMessage:newActorCompData_AvatarAI()
  return {}
end

function ProtoMessage:newActorCompData_ActionTag()
  return {}
end

function ProtoMessage:newActorCompData_AreaTrigger()
  return {
    area_trig_infos = {}
  }
end

function ProtoMessage:newActorCompData_BornDieCtrler()
  return {}
end

function ProtoMessage:newActorCompData_Revive()
  return {
    status = nil,
    teleport_id = nil,
    teleport_reason = nil,
    time = nil,
    teleport_point = ProtoMessage:newPoint(),
    telepos_scene_id = nil,
    swim_scene_id = nil,
    swim_pos = ProtoMessage:newPosition(),
    revive_hp = nil,
    fail_times = nil
  }
end

function ProtoMessage:newLogicStatusLevelPos()
  return {
    pos_info = {},
    time = nil
  }
end

function ProtoMessage:newLogicStatusOwlFruit()
  return {num = nil}
end

function ProtoMessage:newLogicStatusBeastBattle()
  return {beast_battle_end = nil}
end

function ProtoMessage:newLogicStatusWaitOthers()
  return {wait_mate_uin = nil}
end

function ProtoMessage:newLogicStatusExtraData()
  return {
    type = nil,
    level_pos = ProtoMessage:newLogicStatusLevelPos(),
    owl_fruit = ProtoMessage:newLogicStatusOwlFruit(),
    beast_status = ProtoMessage:newLogicStatusBeastBattle(),
    last_update_time = nil,
    jelly_target_model_id = nil,
    transform_cfg_id = nil,
    transform_end_reason = nil,
    ai_param = nil,
    wait_others = ProtoMessage:newLogicStatusWaitOthers()
  }
end

function ProtoMessage:newLogicStatusData()
  return {
    status = nil,
    variant = nil,
    extra_data = ProtoMessage:newLogicStatusExtraData()
  }
end

function ProtoMessage:newDelayProcessStatusData()
  return {
    timeout_time = nil,
    process_type = nil,
    status = nil
  }
end

function ProtoMessage:newActorCompData_LogicStatus()
  return {
    status_info = {},
    deley_process_info = {}
  }
end

function ProtoMessage:newActorCompData_GameTime()
  return {
    paused = nil,
    ref_game_time = nil,
    ref_real_time = nil,
    accelerative_ratio = nil,
    last_nty_game_time = nil,
    enter_night_mode = nil
  }
end

function ProtoMessage:newActorCompData_AvatarCamp()
  return {
    unlocked_camp = {},
    camp_pet_egg_info = {}
  }
end

function ProtoMessage:newMinigameTriggerData()
  return {
    minigame_cfg_id = nil,
    trigger_obj_id = nil,
    trigger_logic_id = nil,
    trigger_option_id = nil
  }
end

function ProtoMessage:newPlayingMinigameData()
  return {
    minigame_cfg_id = nil,
    progress = {},
    start_time = nil,
    remain_time = nil,
    trigger = ProtoMessage:newMinigameTriggerData(),
    open_time = nil,
    play_minigame_time = nil,
    pause_minigame_status = nil,
    switching_cell_reason = nil
  }
end

function ProtoMessage:newActorCompData_Minigame()
  return {
    minigame_data = ProtoMessage:newPlayingMinigameData(),
    last_minigame_trigger = ProtoMessage:newMinigameTriggerData(),
    opened_minigame_cfg_ids = {},
    mate_uin = nil
  }
end

function ProtoMessage:newAreaWeatherInfo()
  return {
    area_func_cfg_id = nil,
    weather_type = nil,
    timeout_time = nil,
    pause_time = nil,
    weather_before_pause = nil
  }
end

function ProtoMessage:newBattleWeatherInfo()
  return {
    weather_type = nil,
    is_keep = nil,
    area_func_cfg_id = nil
  }
end

function ProtoMessage:newActorCompData_Weather()
  return {
    weather_info = ProtoMessage:newActorWeatherInfo(),
    area_weather_infos = {},
    battle_weather_info = ProtoMessage:newBattleWeatherInfo(),
    nightmare_weather = nil,
    global_weather = nil,
    pre_pvp_weather = nil,
    gamecfg_ver = nil,
    cave_cfg_id = nil
  }
end

function ProtoMessage:newActorCompData_ClientEvent()
  return {
    opened_ui_name = {}
  }
end

function ProtoMessage:newNpcPendantItemInfo()
  return {
    id = nil,
    enabled = nil,
    point = ProtoMessage:newPoint(),
    status = nil
  }
end

function ProtoMessage:newNpcPendantInfo()
  return {
    pendant_cfg_id = nil,
    enabled = nil,
    disable_time = nil,
    pendant_item_infos = {},
    valid_times = nil
  }
end

function ProtoMessage:newActorCompData_NpcPendantMgr()
  return {
    pendant_infos = {}
  }
end

function ProtoMessage:newActorCompData_OwlSanctuary()
  return {}
end

function ProtoMessage:newActionBonusCond()
  return {
    cond_idx = nil,
    cond_count = nil,
    cond_finish = nil
  }
end

function ProtoMessage:newBonusEventPoolPetCondRecord()
  return {
    bonus_event_pool_cfg_id = {}
  }
end

function ProtoMessage:newBonusContainerCfgRecord()
  return {
    bonus_container_cfg_id = {}
  }
end

function ProtoMessage:newBonusEventPoolPetCondInfo()
  return {
    catch_times = nil,
    cond_satisfied_record = {},
    bonus_container_record = {}
  }
end

function ProtoMessage:newBonusSelectInfo()
  return {
    bonus_event_pool_cfg_id = nil,
    select_times = nil,
    weight = nil,
    rate = nil
  }
end

function ProtoMessage:newBonusSelectTestResult()
  return {
    run_times = nil,
    pending_list = {},
    select_result = {}
  }
end

function ProtoMessage:newActionBonusInfo()
  return {
    action_bonus_id = nil,
    base_cfg_id = nil,
    action_num = nil,
    bonus_num = nil,
    bonus_time = nil,
    open_cond = {},
    close_cond = {},
    prob_scale_up_value = {},
    delta_prob_scale_up_value = {},
    delta_prob = nil,
    reset_timestamp = nil,
    pet_cond_info = ProtoMessage:newBonusEventPoolPetCondInfo(),
    bonus_select_test_result = ProtoMessage:newBonusSelectTestResult()
  }
end

function ProtoMessage:newActionBonusCampPetReportDetailData()
  return {report_id = nil, report_times = nil}
end

function ProtoMessage:newActionBonusCampPetReportData()
  return {
    report_type = ProtoEnum.CampPetReportType.REPORT_PET_UNIT_TYPE,
    report_detail_data = {}
  }
end

function ProtoMessage:newActionBonusCampPetReportInfo()
  return {
    report_data = {},
    report_finish_ids = {},
    report_wait_ids = {}
  }
end

function ProtoMessage:newActionBonusPityAccu()
  return {accu_type = nil, pity_count = nil}
end

function ProtoMessage:newBonusPityRecord()
  return {bonus_event_pool_cfg_id = nil, selected_times = nil}
end

function ProtoMessage:newActionBonusPityInfo()
  return {
    pity_accus = {},
    bonus_pity_records = {}
  }
end

function ProtoMessage:newC1PersistData()
  return {
    c1_bonus_count = nil,
    c1_shining_count = nil,
    c1_inj = nil,
    c1_reset_threshold = nil,
    bonus_shinning_stg_cfg_id = nil
  }
end

function ProtoMessage:newBonusGiftConditionTypeData()
  return {cur_activity_days = nil, last_activity_day = nil}
end

function ProtoMessage:newC2GiftCondData()
  return {
    gift_conf_id = nil,
    activity_day_shining = ProtoMessage:newBonusGiftConditionTypeData()
  }
end

function ProtoMessage:newC2PersistData()
  return {
    c2_judge_gift_set_num = nil,
    c2_factor = nil,
    c2_shining_num = nil,
    c2_gift_cond_data = {}
  }
end

function ProtoMessage:newActorCompData_ActionBonus()
  return {
    action_bonuses = {},
    camp_pet_report_info = ProtoMessage:newActionBonusCampPetReportInfo(),
    pity_info = ProtoMessage:newActionBonusPityInfo(),
    c1_bonus_count = nil,
    c1_shining_count = nil,
    c1_inj = nil,
    c1_reset_threshold = nil,
    bonus_shinning_stg_cfg_id = nil,
    c2_persist_data = ProtoMessage:newC2PersistData(),
    catch_times_until_bonus = nil,
    visiting_catch_times_until_bonus = nil,
    together_catch_times_until_bonus = nil,
    catch_times_until_shin_bonus = nil,
    bonus_timestamp = nil,
    bonus_cnt = nil
  }
end

function ProtoMessage:newActorCompData_CatchBonusCtrl()
  return {}
end

function ProtoMessage:newSceneObjectInfo()
  return {
    pos = ProtoMessage:newPosition(),
    last_reward_time = nil
  }
end

function ProtoMessage:newActorCompData_ObjectAward()
  return {
    scene_objects = {}
  }
end

function ProtoMessage:newActorCompData_AreaDetector()
  return {max_detect_id = nil}
end

function ProtoMessage:newActorCompData_Hidden()
  return {last_reveal_time = nil}
end

function ProtoMessage:newActorCompData_WorldAttack()
  return {}
end

function ProtoMessage:newDungeonStageData()
  return {
    stage_cfg_id = nil,
    stage_state = nil,
    cfg_version = nil
  }
end

function ProtoMessage:newDungeonCollectionData()
  return {
    type = nil,
    content_ids = {}
  }
end

function ProtoMessage:newDungeonData()
  return {
    dungeon_cfg_id = nil,
    stages = {},
    collections = {}
  }
end

function ProtoMessage:newActorCompData_Dungeon()
  return {
    dungeons = {},
    need_reset_stage = nil
  }
end

function ProtoMessage:newActorCompData_Appearance()
  return {
    fashion_item_wear_data = {},
    salon_item_wear_data = {},
    fashion_bond_data = {},
    wearing_item = {}
  }
end

function ProtoMessage:newVisitorData()
  return {visitor_uin = nil, last_alive_time = nil}
end

function ProtoMessage:newMateSettleInfo()
  return {mate_uin = nil, catch_flower = nil}
end

function ProtoMessage:newTeamBattleTeamInfo()
  return {
    mate_infos = {},
    create_team_time = nil,
    battle_info = ProtoMessage:newTeamBattleInfo(),
    settle_infos = {},
    battling = nil
  }
end

function ProtoMessage:newTeamBattleMatchInfo()
  return {
    beast_start_match_time = nil,
    beast_matching = nil,
    can_auto_beast_match = nil,
    found_owner_uin = nil,
    match_dst_inst_id = nil
  }
end

function ProtoMessage:newTeamBattleBossInfo()
  return {
    catch_state = nil,
    catch_ball_num = nil,
    boss_shiny = nil,
    boss = ProtoMessage:newPetData(),
    temp_leave_time = nil,
    last_catch_time = nil,
    prev_guarantee_rate = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    ticket_id = nil,
    ticket_num = nil
  }
end

function ProtoMessage:newTeamBattleResultInfo()
  return {
    content_cfg_id = nil,
    win_times = nil,
    battle_info = ProtoMessage:newTeamBattleInfo(),
    boss_info = ProtoMessage:newTeamBattleBossInfo(),
    last_complete_perform_time = nil
  }
end

function ProtoMessage:newActorCompData_Visit()
  return {
    last_alive_time = nil,
    visitor_datas = {},
    enter_time = nil,
    leave_time = nil
  }
end

function ProtoMessage:newActorCompData_Pet()
  return {}
end

function ProtoMessage:newActorCompData_PetInteract()
  return {
    acquired_chest_contentids = {},
    has_bond_option_gid = nil
  }
end

function ProtoMessage:newBuffInfo()
  return {
    id = nil,
    buff_cfg_id = nil,
    time_out_time = nil,
    tick_time_out_time = nil,
    create_time = nil,
    bind_aura_id = nil,
    buff_val = nil,
    str_params_list = {},
    int_params_list = {},
    add_buff_caster_id = nil,
    overlays = nil
  }
end

function ProtoMessage:newActorCompData_Buff()
  return {
    max_buff_id = nil,
    buff_infos = {}
  }
end

function ProtoMessage:newActorCompData_RoleplayProp()
  return {
    created_roleplay_data = ProtoMessage:newCreatedRoleplayPropData(),
    entered_roleplay_data = ProtoMessage:newEnteredRoleplayPropData()
  }
end

function ProtoMessage:newActorWorldCombatInfo()
  return {}
end

function ProtoMessage:newBossWorldCombatInfo()
  return {
    world_combat_id = nil,
    combat_avatar_list = {},
    sub_status = nil,
    external_combat_phase = nil,
    weakness_pos_list = {},
    weakness_type_list = {},
    hit_weakness_pos = nil,
    barrier_buff_id = nil,
    weakness_buff_id = nil,
    stun_buff_id = nil,
    begin_internal_battle_hp = nil,
    battle_buff_infos = {},
    gain_pos_list = {},
    gain_type_list = {},
    gain_expose_buff_id = nil,
    used_gain_type = {},
    npc_lowest_hp = nil,
    box_refreshed_avatar_list = {},
    finish_pet_infos = {}
  }
end

function ProtoMessage:newAvatarWorldCombatInfoAward()
  return {boss_npc_obj_id = nil, refresh_time = nil}
end

function ProtoMessage:newAvatarWorldCombatInfo()
  return {
    combat_npc = nil,
    extra_reward_list = {},
    combat_npc_logic_id = nil,
    awards = {},
    defeated_boss_content_list = {}
  }
end

function ProtoMessage:newSpawnNpcWorldCombatInfo()
  return {boss_actor_id = nil}
end

function ProtoMessage:newActorCompData_WorldCombat()
  return {
    actor_world_combat_info = ProtoMessage:newActorWorldCombatInfo(),
    boss_world_combat_info = ProtoMessage:newBossWorldCombatInfo(),
    avatar_world_combat_info = ProtoMessage:newAvatarWorldCombatInfo()
  }
end

function ProtoMessage:newActorWorldCombatSkillInfo()
  return {
    skill_buff_id = {},
    skill_spawn_npc_list = {}
  }
end

function ProtoMessage:newActorCompData_WorldCombatSkill()
  return {
    skill_info = ProtoMessage:newActorWorldCombatSkillInfo()
  }
end

function ProtoMessage:newActorCompData_InitAOIWaiter()
  return {}
end

function ProtoMessage:newActorCompData_VoicePlayer()
  return {}
end

function ProtoMessage:newActorCompData_SceneRpcRetryMgr()
  return {
    zonesvr_rpc_retry_data = ProtoMessage:newRpcRetryInfo()
  }
end

function ProtoMessage:newActorCompData_PetPerception()
  return {
    used_content_id = {}
  }
end

function ProtoMessage:newNpcTaskProcessData()
  return {
    task_id = nil,
    actor_id = nil,
    actor_logic_id = nil,
    task_type = nil,
    task_exec_type = nil,
    task_priority = nil,
    raw_pbp_data = nil
  }
end

function ProtoMessage:newActorCompData_NpcTaskProcessor()
  return {
    process_data_list = {},
    last_task_id = nil
  }
end

function ProtoMessage:newActivityPartData()
  return {part_id = nil, all_cond_finish = nil}
end

function ProtoMessage:newActivityData()
  return {
    activity_id = nil,
    part_datas = {}
  }
end

function ProtoMessage:newActivityContentData()
  return {
    activity_id = nil,
    version = nil,
    is_expired = nil,
    content_refresh_infos = {}
  }
end

function ProtoMessage:newActivitySceneContentRefreshInfo()
  return {
    content_id = nil,
    status = nil,
    state_id = nil
  }
end

function ProtoMessage:newActorCompData_Activity()
  return {
    activity = {},
    spec_flower_seed = {},
    use_star = nil,
    unglass_flower_npc_num = nil,
    boss_challenge_id = nil,
    last_challenge_id = nil,
    round_num = nil,
    dungeon_cfg_id = nil,
    activity_contents = {}
  }
end

function ProtoMessage:newActorTriggerEventNpcGenerateData()
  return {
    npc_refresh_content_id = nil,
    area_id = nil,
    npc_id = nil
  }
end

function ProtoMessage:newActorTriggerEventData()
  return {
    event_index = nil,
    npc_generate_data = {}
  }
end

function ProtoMessage:newActorTriggerData()
  return {
    trigger_id = nil,
    is_triggering = nil,
    triggering_end_time = nil,
    next_trigger_check_time = nil,
    event_data = {}
  }
end

function ProtoMessage:newActorCompData_Trigger()
  return {
    trigger_data = {},
    generated_content_ids = {},
    current_used_content_id = nil
  }
end

function ProtoMessage:newActorCompData_DotsLabel()
  return {}
end

function ProtoMessage:newActorCompData_DotsSkill()
  return {}
end

function ProtoMessage:newActorCompData_DotsSkillBullet()
  return {}
end

function ProtoMessage:newActorCompData_AOwlSanctuary()
  return {
    generated_content_ids = {},
    owl_sanctuary_datas = {},
    owl_sanctuary_pet_egg_info = {},
    current_used_content_id = nil
  }
end

function ProtoMessage:newActorCompData_Follower()
  return {
    follow_id = nil,
    state = nil,
    time = nil,
    default_talk_id = nil,
    is_task_track = nil,
    task_id = nil,
    last_talk_id = nil
  }
end

function ProtoMessage:newActorCompData_BagItem()
  return {}
end

function ProtoMessage:newActorCompData_HomePetEgg()
  return {
    egg_data = ProtoMessage:newPetEggData(),
    bag_item_cfg_id = nil,
    need_circuit_break_check = nil,
    mom_petbase_cfg_id = nil
  }
end

function ProtoMessage:newActorCompData_MsgRecover()
  return {
    recover_msg_data = ProtoMessage:newRecoverMsgList()
  }
end

function ProtoMessage:newStaminaCostData()
  return {status = nil, cost = nil}
end

function ProtoMessage:newActorCompData_Stamina()
  return {
    stamina_cost_list = {},
    in_non_land_battle = nil
  }
end

function ProtoMessage:newActorCompData_TaskState()
  return {
    task_state_ids = {},
    enabled_state_ids = {}
  }
end

function ProtoMessage:newActorCompData_CccChecker()
  return {cancel_move_pos_check = nil, open_airwall_dead = nil}
end

function ProtoMessage:newActorCompData_RelationInteract()
  return {
    is_inviter = nil,
    type = ProtoEnum.InteractInviteType.IIT_INVALID,
    status = ProtoEnum.DoubleTogetherStatus.DTS_NONE,
    param = ProtoMessage:newInteractParam(),
    mate_uin = nil,
    is_friend = nil,
    begin_interact_time = nil,
    sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE,
    recover_mate_uin = nil,
    entering_online_visit = nil
  }
end

function ProtoMessage:newActorCompData_BossFlowerSeed()
  return {
    flower_seed_boss_datas = {}
  }
end

function ProtoMessage:newNpcGuardData()
  return {guard_cfg_id = nil, num = nil}
end

function ProtoMessage:newNpcGuardLimitData()
  return {
    guard_cfg_id = nil,
    is_open = nil,
    daily_max_count = nil
  }
end

function ProtoMessage:newActorCompData_NpcGuard()
  return {
    guard_data = {},
    last_clear_time = nil,
    ban_func_list = {},
    npc_refresh_ban_time = nil,
    npc_refresh_ban_probability = nil,
    guard_limit_data = {}
  }
end

function ProtoMessage:newActorCompData_NpcBattle()
  return {
    fighting_uins = {},
    catched_by_uins = {}
  }
end

function ProtoMessage:newNpcPropSlotData()
  return {holder_avatar_id = nil}
end

function ProtoMessage:newActorCompData_NpcProp()
  return {
    slot_datas = {}
  }
end

function ProtoMessage:newActorCompData_AbnormalStatus()
  return {}
end

function ProtoMessage:newNpcInfoChangeData()
  return {content_id = nil, change_detail_cfg_id = nil}
end

function ProtoMessage:newNpcInfoChangeRetryData()
  return {change_detail_cfg_id = nil}
end

function ProtoMessage:newActorCompData_NpcInfoChange()
  return {
    wild_mutation_change_num = nil,
    last_check_time = nil,
    changed_content_list = {},
    wait_change_content_list = {},
    retry_change_content_list = {}
  }
end

function ProtoMessage:newActorData_Npc()
  return {
    base = ProtoMessage:newActorPartData_Base(),
    npc_base = ProtoMessage:newActorPartData_NpcBase(),
    drop_item_data = ProtoMessage:newActorPartData_DropItem(),
    trigger_data = ProtoMessage:newActorPartData_Trigger(),
    comp_extend_datas = ProtoMessage:newCompExtendDatas(),
    installed_comps = ProtoMessage:newSpaceObjPartData_InstalledComp(),
    comp_data_test = ProtoMessage:newActorCompData_Test(),
    comp_data_broadcaster = ProtoMessage:newActorCompData_Broadcaster(),
    comp_data_owner = ProtoMessage:newActorCompData_Owner(),
    comp_data_transform = ProtoMessage:newActorCompData_Transform(),
    comp_data_status_guarder = ProtoMessage:newActorCompData_StatusGuarder(),
    comp_data_attr_mgr = ProtoMessage:newActorCompData_AttrMgr(),
    comp_data_navigator = ProtoMessage:newActorCompData_Navigator(),
    comp_data_anim_skill_player = ProtoMessage:newActorCompData_AnimSkillPlayer(),
    comp_data_capsule_cct = ProtoMessage:newActorCompData_NpxCapsuleCCT(),
    comp_data_skill = ProtoMessage:newActorCompData_Skill(),
    comp_action_tag = ProtoMessage:newActorCompData_ActionTag(),
    comp_data_npc_interactor = ProtoMessage:newActorCompData_NpcInteractor(),
    comp_data_npc_misc = ProtoMessage:newActorCompData_NpcMisc(),
    comp_data_ai = ProtoMessage:newActorCompData_AI(),
    comp_data_potential_energy = ProtoMessage:newActorCompData_PotentialEnergy(),
    comp_data_npc_camp = ProtoMessage:newActorCompData_NpcCamp(),
    comp_data_mover = ProtoMessage:newActorCompData_ServerMover(),
    comp_born_die_ctrler = ProtoMessage:newActorCompData_BornDieCtrler(),
    comp_logic_status = ProtoMessage:newActorCompData_LogicStatus(),
    comp_data_npc_pendant_mgr = ProtoMessage:newActorCompData_NpcPendantMgr(),
    comp_hidden = ProtoMessage:newActorCompData_Hidden(),
    comp_world_attack = ProtoMessage:newActorCompData_WorldAttack(),
    comp_data_buff = ProtoMessage:newActorCompData_Buff(),
    comp_data_world_combat = ProtoMessage:newActorCompData_WorldCombat(),
    comp_data_voice_player = ProtoMessage:newActorCompData_VoicePlayer(),
    comp_data_owl_sanctuary = ProtoMessage:newActorCompData_OwlSanctuary(),
    comp_data_dots_label = ProtoMessage:newActorCompData_DotsLabel(),
    comp_data_dots_skill = ProtoMessage:newActorCompData_DotsSkill(),
    comp_data_world_combat_skill = ProtoMessage:newActorCompData_WorldCombatSkill(),
    comp_data_collision = ProtoMessage:newActorCompData_NpxCollision(),
    comp_data_bullet = ProtoMessage:newActorCompData_DotsSkillBullet(),
    comp_data_home_pet = ProtoMessage:newActorCompData_HomePet(),
    comp_data_home_plant_npc = ProtoMessage:newActorCompData_HomePlantNpc(),
    comp_data_home_pet_egg = ProtoMessage:newActorCompData_HomePetEgg(),
    comp_data_npc_battle = ProtoMessage:newActorCompData_NpcBattle(),
    comp_data_npc_prop = ProtoMessage:newActorCompData_NpcProp()
  }
end

function ProtoMessage:newContentData()
  return {
    content_cfg_id = nil,
    block_id = nil,
    meta_data = ProtoMessage:newContentMetaData(),
    npc_datas = {}
  }
end

function ProtoMessage:newNpcBlockData()
  return {
    block_id = nil,
    content_datas = {},
    use_ref = nil,
    last_update_timestamp_in_us = nil,
    version = nil,
    create_time = nil
  }
end

function ProtoMessage:newNpcBlockDataList()
  return {
    block_datas = {}
  }
end

function ProtoMessage:newPendingDeleteNpc()
  return {npc_obj_id = nil, npc_logic_id = nil}
end

function ProtoMessage:newAreaNpcData()
  return {area_id = nil, refreshed_npc_num = nil}
end

function ProtoMessage:newRulePendingEraseContentList()
  return {
    rule_cfg_id = nil,
    content_ids = {}
  }
end

function ProtoMessage:newPendingEraseContentList()
  return {
    owl_pending_erase_contents = {},
    pending_erase_contents = {}
  }
end

function ProtoMessage:newActorCompData_NpcRefresher()
  return {
    refresh_info_list = {},
    ingame_refresh_check_list = {},
    camp_pet_egg_info = {},
    owl_sanctuary_pet_egg_info = {},
    wide_block_data = ProtoMessage:newNpcBlockData(),
    advance_block_datas = ProtoMessage:newNpcBlockDataList(),
    delete_npc_list = {},
    area_npc_datas = {},
    entered_scene_cfg_id = {},
    regist_time = nil,
    pending_erase_content_list = ProtoMessage:newPendingEraseContentList(),
    last_glass_reset_time = nil,
    create_glass_npc_num = nil,
    last_nightmare_reset_time = nil,
    create_nightmare_npc_num = nil,
    high_value_npc_num = nil
  }
end

function ProtoMessage:newActorCompData_AirWall()
  return {
    air_wall_info = ProtoMessage:newAirWallInfo()
  }
end

function ProtoMessage:newHomePlantInfo()
  return {
    land_list = {}
  }
end

function ProtoMessage:newStealHomePetInfo()
  return {
    pet_gid = nil,
    feed_round = nil,
    award_info = ProtoMessage:newHomePetAwardInfo()
  }
end

function ProtoMessage:newStealHomeInfo()
  return {
    home_uin = nil,
    steal_of_home_pets = {}
  }
end

function ProtoMessage:newActorCompData_HomeInteract()
  return {
    steal_of_homes = {},
    total_stealed_num = nil,
    last_steal_timestamp = nil
  }
end

function ProtoMessage:newActorCompData_AvatarMultiChat()
  return {}
end

function ProtoMessage:newActorCompData_Season()
  return {
    season_id = nil,
    boss_refresh_content_id = nil,
    season_pve_id = nil,
    boss_is_refresh = nil,
    season_adv_shining_extra_weight = nil,
    season_adv_catch_prob_add = nil,
    season_boss_id = nil,
    boss_battle_rule_infos = {},
    next_refresh_word_timestamp = nil
  }
end

function ProtoMessage:newActorCompData_FusionOwlSanctuary()
  return {
    generated_content_ids = {},
    owl_sanctuary_datas = {},
    last_refresh_timestamp = nil,
    current_used_content_id = nil
  }
end

function ProtoMessage:newActorTravelingMerchantData()
  return {
    id = nil,
    content_id = {},
    refresh_time = nil,
    expire_time = nil
  }
end

function ProtoMessage:newActorCompData_TravelingMerchant()
  return {
    merchants = {}
  }
end

function ProtoMessage:newAvatarFriendRecommendInfo()
  return {
    recommend_info = ProtoMessage:newFriendRecommendInfo()
  }
end

function ProtoMessage:newActorCompData_AvatarFriendProxy()
  return {
    friend_recommend_info = ProtoMessage:newAvatarFriendRecommendInfo()
  }
end

function ProtoMessage:newActorCompData_Exchange()
  return {}
end

function ProtoMessage:newActorCompData_TeleportInfoHolder()
  return {}
end

function ProtoMessage:newActorData_Avatar()
  return {
    base = ProtoMessage:newActorPartData_Base(),
    avatar_base = ProtoMessage:newActorPartData_AvatarBase(),
    comp_extend_datas = ProtoMessage:newCompExtendDatas(),
    installed_comps = ProtoMessage:newSpaceObjPartData_InstalledComp(),
    comp_data_test = ProtoMessage:newActorCompData_Test(),
    comp_data_broadcaster = ProtoMessage:newActorCompData_Broadcaster(),
    comp_data_mover = ProtoMessage:newActorCompData_ClientMover(),
    comp_data_owner = ProtoMessage:newActorCompData_Owner(),
    comp_data_transform = ProtoMessage:newActorCompData_Transform(),
    comp_data_status_guarder = ProtoMessage:newActorCompData_StatusGuarder(),
    comp_data_attr_mgr = ProtoMessage:newActorCompData_AttrMgr(),
    comp_data_anim_skill_player = ProtoMessage:newActorCompData_AnimSkillPlayer(),
    comp_data_capsule_cct = ProtoMessage:newActorCompData_NpxCapsuleCCT(),
    comp_data_heartbeat = ProtoMessage:newActorCompData_Heartbeat(),
    comp_data_skill = ProtoMessage:newActorCompData_Skill(),
    comp_data_battle = ProtoMessage:newActorCompData_Battle(),
    comp_data_minigame = ProtoMessage:newActorCompData_Minigame(),
    comp_data_msg_sender = ProtoMessage:newActorCompData_MsgSender(),
    comp_data_area_mgr = ProtoMessage:newActorCompData_AreaMgr(),
    comp_data_npc_refresher = ProtoMessage:newActorCompData_NpcRefresher(),
    comp_data_story_flag = ProtoMessage:newActorCompData_StoryFlag(),
    comp_data_task = ProtoMessage:newActorCompData_Task(),
    comp_data_avatar_misc = ProtoMessage:newActorCompData_AvatarMisc(),
    comp_data_ai = ProtoMessage:newActorCompData_AI(),
    comp_data_ai_lod = ProtoMessage:newActorCompData_AI_LOD(),
    comp_data_combine_npc = ProtoMessage:newActorCompData_CombineNpc(),
    comp_data_rider = ProtoMessage:newActorCompData_Rider(),
    comp_data_navigator = ProtoMessage:newActorCompData_Navigator(),
    comp_data_aura_mgr = ProtoMessage:newActorCompData_AuraMgr(),
    comp_data_avatar_interactor = ProtoMessage:newActorCompData_AvatarInteractor(),
    comp_data_id_genner = ProtoMessage:newActorCompData_NonAvatarIdGen(),
    npc_instantiator = ProtoMessage:newActorCompData_NpcInstantiator(),
    comp_data_thrower = ProtoMessage:newActorCompData_Thrower(),
    comp_data_world_map = ProtoMessage:newActorCompData_WorldMap(),
    comp_data_temperature = ProtoMessage:newActorCompData_Temperature(),
    comp_avatar_ai = ProtoMessage:newActorCompData_AvatarAI(),
    comp_action_tag = ProtoMessage:newActorCompData_ActionTag(),
    comp_born_die_ctrler = ProtoMessage:newActorCompData_BornDieCtrler(),
    comp_revive = ProtoMessage:newActorCompData_Revive(),
    comp_logic_status = ProtoMessage:newActorCompData_LogicStatus(),
    comp_data_game_time = ProtoMessage:newActorCompData_GameTime(),
    comp_data_avatar_camp = ProtoMessage:newActorCompData_AvatarCamp(),
    comp_data_weather = ProtoMessage:newActorCompData_Weather(),
    comp_data_exchange = ProtoMessage:newActorCompData_Exchange(),
    comp_data_action_bonus = ProtoMessage:newActorCompData_ActionBonus(),
    comp_data_catch_bonus_ctrl = ProtoMessage:newActorCompData_CatchBonusCtrl(),
    comp_data_object_award = ProtoMessage:newActorCompData_ObjectAward(),
    comp_data_area_detector = ProtoMessage:newActorCompData_AreaDetector(),
    comp_data_appearance = ProtoMessage:newActorCompData_Appearance(),
    comp_data_dungeon = ProtoMessage:newActorCompData_Dungeon(),
    comp_data_visit = ProtoMessage:newActorCompData_Visit(),
    comp_data_pet = ProtoMessage:newActorCompData_Pet(),
    comp_data_pet_interact = ProtoMessage:newActorCompData_PetInteract(),
    comp_data_buff = ProtoMessage:newActorCompData_Buff(),
    comp_data_world_combat = ProtoMessage:newActorCompData_WorldCombat(),
    comp_data_world_combat_skill = ProtoMessage:newActorCompData_WorldCombatSkill(),
    comp_data_init_aoi_waiter = ProtoMessage:newActorCompData_InitAOIWaiter(),
    comp_data_voice_player = ProtoMessage:newActorCompData_VoicePlayer(),
    comp_data_client_event = ProtoMessage:newActorCompData_ClientEvent(),
    comp_data_rpc_retry_mgr = ProtoMessage:newActorCompData_SceneRpcRetryMgr(),
    comp_data_pet_preception = ProtoMessage:newActorCompData_PetPerception(),
    comp_data_npc_task_processor = ProtoMessage:newActorCompData_NpcTaskProcessor(),
    comp_data_activity = ProtoMessage:newActorCompData_Activity(),
    comp_data_trigger = ProtoMessage:newActorCompData_Trigger(),
    comp_data_dots_label = ProtoMessage:newActorCompData_DotsLabel(),
    comp_data_avatar_owl_sanctuary = ProtoMessage:newActorCompData_AOwlSanctuary(),
    comp_data_avatar_follower = ProtoMessage:newActorCompData_Follower(),
    comp_data_avatar_recover = ProtoMessage:newActorCompData_MsgRecover(),
    comp_data_stamina = ProtoMessage:newActorCompData_Stamina(),
    comp_data_avatar_task_state = ProtoMessage:newActorCompData_TaskState(),
    comp_data_avatar_area_trigger = ProtoMessage:newActorCompData_AreaTrigger(),
    comp_data_ccc_checker = ProtoMessage:newActorCompData_CccChecker(),
    comp_data_dots_skill = ProtoMessage:newActorCompData_DotsSkill(),
    comp_data_collision = ProtoMessage:newActorCompData_NpxCollision(),
    comp_data_db = ProtoMessage:newActorCompData_Db(),
    comp_data_npc_trace = ProtoMessage:newActorCompData_NpcTrace(),
    com_data_air_wall = ProtoMessage:newActorCompData_AirWall(),
    comp_data_home_basic = ProtoMessage:newActorCompData_HomeBasic(),
    comp_data_home_plant = ProtoMessage:newActorCompData_HomePlant(),
    comp_data_team_battle = ProtoMessage:newActorCompData_TeamBattle(),
    comp_data_feed = ProtoMessage:newActorCompData_Feed(),
    comp_data_visible_area = ProtoMessage:newActorCompData_VisibleArea(),
    comp_data_home_interact = ProtoMessage:newActorCompData_HomeInteract(),
    comp_data_relation_interact = ProtoMessage:newActorCompData_RelationInteract(),
    comp_data_avatar_multi_chat = ProtoMessage:newActorCompData_AvatarMultiChat(),
    comp_data_traveling_merchant = ProtoMessage:newActorCompData_TravelingMerchant(),
    comp_data_season = ProtoMessage:newActorCompData_Season(),
    comp_data_fusion_owl_sanctuary = ProtoMessage:newActorCompData_FusionOwlSanctuary(),
    comp_data_bag_item = ProtoMessage:newActorCompData_BagItem(),
    comp_data_flower_seed = ProtoMessage:newActorCompData_BossFlowerSeed(),
    comp_data_avatar_friend_proxy = ProtoMessage:newActorCompData_AvatarFriendProxy(),
    comp_data_visible_circle = ProtoMessage:newActorCompData_VisibleCircle(),
    comp_data_teleport_info_holder = ProtoMessage:newActorCompData_TeleportInfoHolder(),
    comp_data_catch_refresh_record = ProtoMessage:newActorCompData_CatchRefreshRecord(),
    comp_data_social_info_reporter = ProtoMessage:newActorCompData_SocialInfoReporter(),
    comp_data_npc_guard = ProtoMessage:newActorCompData_NpcGuard(),
    comp_data_night_mode = ProtoMessage:newActorCompData_NightMode(),
    comp_data_llm_agent = ProtoMessage:newActorCompData_LlmAgent(),
    comp_data_roleplay_prop = ProtoMessage:newActorCompData_RoleplayProp(),
    comp_data_abnormal_status = ProtoMessage:newActorCompData_AbnormalStatus(),
    comp_data_npc_info_change = ProtoMessage:newActorCompData_NpcInfoChange()
  }
end

function ProtoMessage:newCellPartData_Base()
  return {
    cell_id = nil,
    cell_rect = ProtoMessage:newRect2D(),
    cell_logic_id = nil,
    cell_extra_data = nil
  }
end

function ProtoMessage:newCellCompData_Test()
  return {}
end

function ProtoMessage:newCellCompData_ActionPlayer()
  return {}
end

function ProtoMessage:newNpcRefreshControllerData()
  return {
    refresh_rule_cfg_id = nil,
    formatters = {}
  }
end

function ProtoMessage:newNpcFormatterData()
  return {
    content_cfg_id = nil,
    block_id = nil,
    npc_obj_ids = {}
  }
end

function ProtoMessage:newCellCompData_NpcRefresher()
  return {
    home_npc_datas = {},
    npc_inc_id = nil,
    refresh_controllers = {},
    idel_npc_inc_id = {}
  }
end

function ProtoMessage:newCellCompData_NpcInstantiator()
  return {}
end

function ProtoMessage:newCellCompData_Catcher()
  return {}
end

function ProtoMessage:newCellCompData_Db()
  return {}
end

function ProtoMessage:newCellCompData_ActorManager()
  return {}
end

function ProtoMessage:newCellCompData_AssetBundle()
  return {}
end

function ProtoMessage:newCellCompData_MfbtDebug()
  return {}
end

function ProtoMessage:newAvatarVisibility()
  return {
    avatar_uin = nil,
    visibility = nil,
    recovery_time = nil
  }
end

function ProtoMessage:newVisiblePoolData()
  return {
    visible_list = {},
    pool_id = nil
  }
end

function ProtoMessage:newVisibleZoneData()
  return {
    visible_pools = {},
    area_conf_id = nil
  }
end

function ProtoMessage:newCellCompData_VisibleZoneMgr()
  return {
    visible_zones = {},
    base_pool_id = nil
  }
end

function ProtoMessage:newVisibleCircleMemberData()
  return {
    uin = nil,
    join_type = nil,
    join_time = nil
  }
end

function ProtoMessage:newVisibleCirclePlaceHolderData()
  return {uin = nil, hold_time = nil}
end

function ProtoMessage:newVisibleCircleData()
  return {
    circle_id = nil,
    members = {},
    visible_plan_id = nil,
    last_check_time = nil,
    holders = {}
  }
end

function ProtoMessage:newCellCompData_VisibleCircle()
  return {
    circles = {}
  }
end

function ProtoMessage:newCellCompData_MsgBroadcaster()
  return {}
end

function ProtoMessage:newInnerMsg()
  return {inner_int_val1 = nil}
end

function ProtoMessage:newActor()
  return {
    int_val = nil,
    int_vals = {},
    inner_msg = ProtoMessage:newInnerMsg()
  }
end

function ProtoMessage:newCellCompData_NormalizedPos()
  return {}
end

function ProtoMessage:newCellCompData_NpcFollowMgr()
  return {}
end

function ProtoMessage:newCellCompData_ActorInfoBuilder()
  return {}
end

function ProtoMessage:newCellCompData_DetectorAppender()
  return {}
end

function ProtoMessage:newCellCompData_IdleCellReclaimer()
  return {}
end

function ProtoMessage:newCellData_Normal()
  return {
    base = ProtoMessage:newCellPartData_Base(),
    comp_extend_datas = ProtoMessage:newCompExtendDatas(),
    installed_comps = ProtoMessage:newSpaceObjPartData_InstalledComp(),
    comp_data_test = ProtoMessage:newCellCompData_Test(),
    comp_data_action_player = ProtoMessage:newCellCompData_ActionPlayer(),
    comp_data_npc_refresher = ProtoMessage:newCellCompData_NpcRefresher(),
    comp_data_npc_instantiator = ProtoMessage:newCellCompData_NpcInstantiator(),
    comp_data_db = ProtoMessage:newCellCompData_Db(),
    comp_data_catcher = ProtoMessage:newCellCompData_Catcher(),
    comp_data_actor_mgr = ProtoMessage:newCellCompData_ActorManager(),
    comp_data_asset_bundle = ProtoMessage:newCellCompData_AssetBundle(),
    comp_data_mfbt_debug = ProtoMessage:newCellCompData_MfbtDebug(),
    comp_data_visible_zone_mgr = ProtoMessage:newCellCompData_VisibleZoneMgr(),
    comp_data_visible_circle = ProtoMessage:newCellCompData_VisibleCircle(),
    comp_data_broadcaster = ProtoMessage:newCellCompData_MsgBroadcaster(),
    comp_data_normalized_pos = ProtoMessage:newCellCompData_NormalizedPos(),
    comp_data_npc_follow_mgr = ProtoMessage:newCellCompData_NpcFollowMgr(),
    comp_data_actor_info_builder = ProtoMessage:newCellCompData_ActorInfoBuilder(),
    comp_data_detector_appender = ProtoMessage:newCellCompData_DetectorAppender(),
    comp_data_idle_cell_reclaimer = ProtoMessage:newCellCompData_IdleCellReclaimer(),
    comp_data_home_basic = ProtoMessage:newCellCompData_HomeBasic(),
    comp_data_home_pet = ProtoMessage:newCellCompData_HomePet(),
    comp_data_home_plant = ProtoMessage:newCellCompData_HomePlant(),
    comp_data_home_brief = ProtoMessage:newCellCompData_HomeBrief(),
    comp_data_home = ProtoMessage:newCellCompData_Home(),
    comp_data_invoke_relay = ProtoMessage:newCellCompData_InvokeRelay(),
    comp_data_area_detector = ProtoMessage:newCellCompData_AreaDetector()
  }
end

function ProtoMessage:newCellCompData_HomeBasic()
  return {
    home_name = nil,
    home_experience = nil,
    home_level = nil,
    room_level = nil,
    home_comfort_level = nil,
    home_status = ProtoEnum.CellCompData_HomeBasic.Status.STATUS_NORMAL,
    access_info = ProtoMessage:newHomeAccessInfo(),
    visitor_info_list = {},
    room_layout = ProtoMessage:newRoomLayoutInfo(),
    room_expansion_info = ProtoMessage:newRoomExpansionInfo(),
    visit_history = ProtoMessage:newHomeVisitHistoryInfo(),
    rare_lay_egg_ban_info = ProtoMessage:newHomeRareLayEggBanInfo()
  }
end

function ProtoMessage:newCellCompData_HomeBrief()
  return {}
end

function ProtoMessage:newCellCompData_Home()
  return {}
end

function ProtoMessage:newCellCompData_InvokeRelay()
  return {}
end

function ProtoMessage:newCellCompData_HomePet()
  return {
    furniture_cd = {},
    reward_caches = {},
    fetch_home_pet_award_cnt = nil,
    next_egg_time = nil,
    lay_egg_miss_cnt = nil,
    high_value_pet_lay_records = {},
    lay_egg_seed = nil
  }
end

function ProtoMessage:newFurnitureCD()
  return {
    pet_gid = nil,
    last_time = nil,
    furniture_cd = nil
  }
end

function ProtoMessage:newHighValuePetLayEggRecord()
  return {gid = nil, next_cd_time = nil}
end

function ProtoMessage:newHomePetRewardCache()
  return {
    pet_gid = nil,
    award_info = ProtoMessage:newHomePetAwardInfo()
  }
end

function ProtoMessage:newHomeCraftableFurnitureInfo()
  return {
    furniture_id_list = {},
    recommended_id_list = {},
    next_update_timestamp = nil
  }
end

function ProtoMessage:newCellCompData_HomePlant()
  return {
    unlock = nil,
    home_plant_land_list = {}
  }
end

function ProtoMessage:newCellHomePlant_LandData()
  return {
    land_cfg_id = nil,
    notice_board_actor_id = nil,
    plant_list = {},
    steal_expel = {}
  }
end

function ProtoMessage:newHomePlant_PlantData()
  return {
    plant_id = nil,
    plant_blank_actor_id = nil,
    plant_state = nil,
    plant_seed_id = nil,
    plant_actor_id = nil,
    plant_time = nil,
    plant_rip_time = nil,
    plant_rip_cfg_time = nil,
    plant_harvest_id = nil,
    plant_harvest_num = nil,
    plant_harvest_vitem_type = nil,
    plant_harvest_vitem_value = nil,
    plant_tab_id = nil,
    plant_water_time = nil,
    plant_manure_time = nil,
    plant_manure_add_harvest_per = nil,
    plant_steal_players = {},
    plant_steal_account = nil,
    plant_can_steal_account = nil
  }
end

function ProtoMessage:newHomePlant_StealExpel()
  return {avatar_id = nil, expel_time = nil}
end

function ProtoMessage:newCellCompData_AreaDetector()
  return {}
end

function ProtoMessage:newSceneData_Normal()
  return {
    scene_id = nil,
    comp_extend_datas = ProtoMessage:newCompExtendDatas(),
    installed_comps = ProtoMessage:newSpaceObjPartData_InstalledComp()
  }
end

function ProtoMessage:newSceneMgrCompData_AISubsystem()
  return {}
end

function ProtoMessage:newSceneMgrCompData_Teleporter()
  return {}
end

function ProtoMessage:newSceneMgrCompData_PreCreator()
  return {data_base_id = nil}
end

function ProtoMessage:newSceneMgrCompData_DotsMessenger()
  return {}
end

function ProtoMessage:newSceneMgrCompData_SvrInfoReportor()
  return {}
end

function ProtoMessage:newSceneMgrCompData_PlayActsCombine()
  return {}
end

function ProtoMessage:newSceneMgrData_Normal()
  return {
    comp_extend_datas = ProtoMessage:newCompExtendDatas(),
    installed_comps = ProtoMessage:newSpaceObjPartData_InstalledComp(),
    comp_data_ai_sub_system = ProtoMessage:newSceneMgrCompData_AISubsystem(),
    comp_data_teleporter = ProtoMessage:newSceneMgrCompData_Teleporter(),
    comp_data_pre_data_creator = ProtoMessage:newSceneMgrCompData_PreCreator(),
    comp_data_dots_messeger = ProtoMessage:newSceneMgrCompData_DotsMessenger(),
    comp_data_svr_info_reportor = ProtoMessage:newSceneMgrCompData_SvrInfoReportor(),
    comp_data_play_acts_combine = ProtoMessage:newSceneMgrCompData_PlayActsCombine()
  }
end

function ProtoMessage:newVisitorInfo()
  return {
    uin = nil,
    network = nil,
    pos = ProtoMessage:newPoint(),
    scene_res_id = nil,
    main_scene_pt = ProtoMessage:newPoint(),
    zone_inst_id = nil
  }
end

function ProtoMessage:newAimThrowInfo()
  return {
    throw_item_type = nil,
    throw_ball_id = nil,
    is_fast = nil,
    throw_session_id = nil
  }
end

function ProtoMessage:newAimMagicInfo()
  return {charged_level = nil}
end

function ProtoMessage:newAimSyncInfo()
  return {
    aim_type = ProtoEnum.AimSyncType.AST_INIT_AIM,
    throw_info = ProtoMessage:newAimThrowInfo(),
    is_throw_success = nil,
    throw_velocity = ProtoMessage:newPosition(),
    magic_info = ProtoMessage:newAimMagicInfo()
  }
end

function ProtoMessage:newNpcActionSyncInfo()
  return {
    operation_target_id = nil,
    operation_type = nil,
    action_status = nil,
    option_id = nil,
    fixCoordinateSucceed = nil,
    operator_location = ProtoMessage:newPoint(),
    act_exec_success = nil
  }
end

function ProtoMessage:newPetActionSyncInfo()
  return {
    operation_target_id = nil,
    operation_type = nil,
    operator_owner_id = nil,
    action_status = nil,
    option_id = nil,
    conf_type = ProtoEnum.ClientOperationConfType.COCT_NPC_OPTION_CONF,
    conf_id = nil
  }
end

function ProtoMessage:newCatchPetSyncInfo()
  return {
    pet_id = nil,
    shake_times = nil,
    success = nil,
    use_technique = nil
  }
end

function ProtoMessage:newPlayerPerformSyncInfo()
  return {
    perform_type = ProtoEnum.PlayerPerformType.PPT_IDLE,
    idle_perform_id = nil,
    hit_type = ProtoEnum.PlayerAttackPerformType.PAPT_Light,
    hit_direction = ProtoMessage:newPosition(),
    idle_perform_skill_id = nil
  }
end

function ProtoMessage:newPlayerCinematicSyncInfo()
  return {
    target_npc_id = nil,
    cinematic_id = nil,
    sync_type = ProtoEnum.PlayerOperationSyncType.POST_START
  }
end

function ProtoMessage:newPlayerMovieSyncInfo()
  return {
    target_npc_id = nil,
    movie_id = nil,
    sync_type = ProtoEnum.PlayerOperationSyncType.POST_START
  }
end

function ProtoMessage:newPlayerDialogueSyncInfo()
  return {
    target_npc_id = nil,
    dialogue_id = nil,
    dialogue_npc_id = nil,
    sync_type = ProtoEnum.PlayerOperationSyncType.POST_START,
    select_ids = {},
    last_select_id = nil,
    progress = nil,
    option_conf_id = nil
  }
end

function ProtoMessage:newTakePhotoEmojiPoseSyncInfo()
  return {
    photo_emoji_id = nil,
    photo_pose_id = nil,
    is_end = nil,
    is_mirror = nil
  }
end

function ProtoMessage:newClientOperation()
  return {
    operator_id = nil,
    operator_type = ProtoEnum.ClientOperationType.COT_AIM,
    pet_action_info = ProtoMessage:newPetActionSyncInfo(),
    aim_info = ProtoMessage:newAimSyncInfo(),
    npc_action_info = ProtoMessage:newNpcActionSyncInfo(),
    catch_info = ProtoMessage:newCatchPetSyncInfo(),
    player_perform_info = ProtoMessage:newPlayerPerformSyncInfo(),
    cinematic_info = ProtoMessage:newPlayerCinematicSyncInfo(),
    movie_info = ProtoMessage:newPlayerMovieSyncInfo(),
    dialogue_info = ProtoMessage:newPlayerDialogueSyncInfo(),
    photo_info = ProtoMessage:newTakePhotoEmojiPoseSyncInfo()
  }
end

function ProtoMessage:newSpaceBaseData()
  return {
    space_time_ms = nil,
    operator_obj_id = nil,
    mask = nil
  }
end

function ProtoMessage:newSvrAISyncCommonInfo()
  return {ai_seq_id = nil}
end

function ProtoMessage:newAvatarStatusDataWalking()
  return {type = nil}
end

function ProtoMessage:newAvatarStatusDataFalling()
  return {phase = nil}
end

function ProtoMessage:newAvatarStatusDataInteracting()
  return {type = nil}
end

function ProtoMessage:newAirWallInfo()
  return {
    air_wall_ids = {}
  }
end

function ProtoMessage:newActorInfo_InnerBattle()
  return {
    info = ProtoMessage:newInnerBattleInfo()
  }
end

function ProtoMessage:newContinuousCatchShinyNightmareRecord()
  return {evolution_group_id = nil, nightmare_keep_time = nil}
end

function ProtoMessage:newHabitatCatchRecord()
  return {
    habitat_id = nil,
    acc_try_catch_time = nil,
    acc_catch_succ_time = nil,
    acc_catch_fail_time = nil,
    exist_npc_num = nil,
    can_refresh_npc_num = nil,
    last_try_catch_time = nil,
    last_try_time = nil
  }
end

function ProtoMessage:newEvolutionChainCatchRecord()
  return {
    evolution_chain_id = nil,
    acc_try_catch_time = nil,
    acc_catch_succ_time = nil,
    acc_catch_fail_time = nil,
    last_try_catch_time = nil,
    last_try_time = nil
  }
end

function ProtoMessage:newCatchRecordInfo()
  return {
    habitat_catch_record_datas = {},
    evolution_chain_catch_record_datas = {}
  }
end

function ProtoMessage:newNeighborData()
  return {
    habitat_id = nil,
    distance = nil,
    restrain_relation = {}
  }
end

function ProtoMessage:newHabitatNeighborData()
  return {
    habitat_id = nil,
    first_neighbor = ProtoMessage:newNeighborData(),
    second_neighbor = ProtoMessage:newNeighborData(),
    common_attrs = {},
    common_identity = nil
  }
end

function ProtoMessage:newHabitatNeighborRelationInfo()
  return {
    habitat_neighbor_datas = {}
  }
end

function ProtoMessage:newActorCompData_CatchRefreshRecord()
  return {
    catch_refresh_info = ProtoMessage:newCatchRecordInfo()
  }
end

function ProtoMessage:newActorCompData_SocialInfoReporter()
  return {
    social_info = ProtoMessage:newAvatarSocialInfo()
  }
end

function ProtoMessage:newActorCompData_NightMode()
  return {}
end

function ProtoMessage:newLlmAgent_AvatarInfo()
  return {}
end

function ProtoMessage:newLlmAgent_PetInfo()
  return {
    llm_pet_ids = {}
  }
end

function ProtoMessage:newActorCompData_LlmAgent()
  return {
    avatar_info = ProtoMessage:newLlmAgent_AvatarInfo(),
    pet_info = ProtoMessage:newLlmAgent_PetInfo()
  }
end

function ProtoMessage:newLLMPetBehaviorGroupInfo()
  return {
    world_text = nil,
    emoji_text = nil,
    llm_pet_behavior_id = nil
  }
end

function ProtoMessage:newSceneDungeonCorrectedPlayerInfo()
  return {
    dungeon_cfg_id = nil,
    stages = {}
  }
end

function ProtoMessage:newZoneBattleLoadFinishReq()
  return {
    pos_info = {},
    battle_center = ProtoMessage:newPosition(),
    battle_radius = nil,
    observe_available_pos = {}
  }
end

function ProtoMessage:newZoneBattleLoadFinishRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleSupplyPetReq()
  return {
    pet_id = {},
    pet_pos = {}
  }
end

function ProtoMessage:newZoneBattleSupplyPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleEmojiReq()
  return {emoji = nil, aim_uin = nil}
end

function ProtoMessage:newZoneBattleEmojiRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleEmojiNotify()
  return {
    emoji = nil,
    aim_uin = nil,
    src_uin = nil
  }
end

function ProtoMessage:newZoneBattleCmdPopbackReq()
  return {pet_id = nil, role_magic_op = nil}
end

function ProtoMessage:newZoneBattleCmdPopbackRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    sync_data = ProtoMessage:newBattleSyncData(),
    req = ProtoMessage:newBattleRoundFlowReq(),
    round = nil
  }
end

function ProtoMessage:newZoneBattlePlayerRunawayReq()
  return {runaway_type = nil}
end

function ProtoMessage:newZoneBattlePlayerRunawayRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattlePlayerExitReq()
  return {battle_id = nil}
end

function ProtoMessage:newZoneBattlePlayerExitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleCmdPushbackReq()
  return {
    req_type = nil,
    req = {},
    is_confirm = nil,
    wl_req_id = nil,
    max_err_req_id = nil,
    feature_data = nil
  }
end

function ProtoMessage:newZoneBattleCmdPushbackRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_caught = nil,
    catch_probability = nil,
    fri_type_list = {},
    has_npc_delay = nil,
    state_ret_code = nil,
    sync_data = ProtoMessage:newBattleSyncData(),
    req = ProtoMessage:newBattleRoundFlowReq(),
    magic_op_info = ProtoMessage:newBattleRoleMagicOpInfo(),
    combo_skill_idx = nil,
    wl_req_id = nil,
    max_err_req_id = nil,
    ignored = nil,
    round = nil
  }
end

function ProtoMessage:newZoneBattleRoundFlowFinishReq()
  return {
    pos_info = {},
    battle_center = ProtoMessage:newPosition(),
    battle_radius = nil,
    state = ProtoEnum.BATTLEFIELD_STATE.BATTLEFIELD_STATE_NULL,
    seq_num = nil
  }
end

function ProtoMessage:newZoneBattleRoundFlowFinishRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_finish = nil
  }
end

function ProtoMessage:newZoneBattleEnterNotify()
  return {
    battle_mode = nil,
    round = nil,
    series_index = nil,
    round_time = nil,
    init_info = ProtoMessage:newBattleInitInfo(),
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    npc_id = {},
    is_reconnect = nil,
    enter_battle_type = nil,
    battle_center = ProtoMessage:newPosition(),
    weather_id = nil,
    weather_expire_round = nil,
    water_battle_type = nil,
    max_round = nil,
    rotate = nil,
    creater_uin = nil,
    data_seq_num = nil
  }
end

function ProtoMessage:newZoneBattlePrePlayNotify()
  return {
    perform_cmd = ProtoMessage:newBattlePerformCmd(),
    settle_info = ProtoMessage:newBattleRoundSettleInfo()
  }
end

function ProtoMessage:newZoneBattleRoundStartNotify()
  return {
    state_type = ProtoEnum.BATTLE_STATE_NOTIFY_TYPE.BATTLE_STATE_SELECT_PET,
    state_info = ProtoMessage:newBattleStateInfo(),
    perform_cmd = ProtoMessage:newBattlePerformCmd(),
    ai_extra_data = ProtoMessage:newAiExtraData(),
    has_npc_delay = nil,
    guide_id = nil
  }
end

function ProtoMessage:newZoneBattleInstantPerformNotify()
  return {
    perform_cmd = ProtoMessage:newBattlePerformCmd(),
    settle_info = ProtoMessage:newBattleRoundSettleInfo(),
    has_npc_delay = nil
  }
end

function ProtoMessage:newZoneBattleCmdSyncNotify()
  return {
    player_uin = nil,
    req = ProtoMessage:newBattleRoundFlowReq()
  }
end

function ProtoMessage:newZoneBattleRoleLeaveNotify()
  return {
    player_uin = nil,
    reason = ProtoEnum.ZoneBattleRoleLeaveNotify.LeaveType.NORMAL_LEAVE,
    seq_num = nil
  }
end

function ProtoMessage:newZoneBattlePerformStartNotify()
  return {
    perform_cmd = ProtoMessage:newBattlePerformCmd(),
    settle_info = ProtoMessage:newBattleRoundSettleInfo(),
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattlePvpPerformStartNotify()
  return {
    perform_cmd = ProtoMessage:newBattlePerformCmd(),
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newBattleFinishBagInfo()
  return {
    bag_gid = nil,
    is_charge = nil,
    num = nil,
    remain_use_cnt = nil,
    used_num = nil,
    item_conf_id = nil
  }
end

function ProtoMessage:newPvpScoreRecord()
  return {
    attack_uin = nil,
    attack_conf_id = nil,
    score = nil,
    attack_pet_id = nil,
    attack_pet_gid = nil,
    attack_pet_type = ProtoMessage:newPetTypeInfo(),
    defend_uin = nil,
    defend_conf_id = nil,
    defend_pet_id = nil,
    is_defend_runaway = nil,
    mutation_type = nil,
    blood = nil,
    carry_fantastic_skill = nil,
    type = ProtoMessage:newPetTypeInfo(),
    defend_pet_gid = nil,
    raw_score = nil
  }
end

function ProtoMessage:newObserverPvpScoreRecord()
  return {
    uin = nil,
    score = nil,
    watch_duration = nil,
    get_pvp_score = nil
  }
end

function ProtoMessage:newBattleFinishObtainMedalInfo()
  return {
    pet_gid = nil,
    petbase_id = nil,
    normal_task_reward_id = nil
  }
end

function ProtoMessage:newBattlePvpScoreInfo()
  return {extra_obtain_pvp_score_source = nil}
end

function ProtoMessage:newZoneBattleFinishNotify()
  return {
    settle_info = ProtoMessage:newBattleSettleInfo(),
    seen_monster_id = {},
    ret_info = ProtoMessage:newRetInfo(),
    reward = ProtoMessage:newGoodsReward(),
    evolution_complete = nil,
    pet_info = {},
    bag_info = {},
    will_leave_visit = nil,
    consumed_carryons = {},
    pvp_score_records = {},
    pvp_score = nil,
    fashion_suit_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo_SuitInfo(),
    total_pvp_score = nil,
    max_pvp_score = nil,
    world_nums = {},
    simple_pets = {},
    pvp_rank_settle_info = ProtoMessage:newPvpRankSettleInfo(),
    create_battle_ret = nil,
    cli_startup_channel = nil,
    last_pvp_battle_type = nil,
    last_pvp_battle_ai_desc = nil,
    observer_pvp_score_records = {},
    obtain_medal_info = ProtoMessage:newBattleFinishObtainMedalInfo(),
    battle_pvp_score = ProtoMessage:newBattlePvpScoreInfo()
  }
end

function ProtoMessage:newPvpRankSettleInfo()
  return {
    old_pvp_rank_star = nil,
    new_pvp_rank_star = nil,
    old_pvp_rank_order = nil,
    new_pvp_rank_order = nil,
    old_pvp_rank_master_score = nil,
    new_pvp_rank_master_score = nil,
    win_streak_addtional_rank_star = nil,
    random_pet_addtional_rank_star = nil
  }
end

function ProtoMessage:newZoneBattleForceFinishNotify()
  return {reason = nil}
end

function ProtoMessage:newBattleCatchPetRecord()
  return {
    player_uin = nil,
    ball_id = nil,
    probability = nil,
    random_number = nil
  }
end

function ProtoMessage:newBattleDamageRecord()
  return {
    player_uin = nil,
    damage_type = nil,
    skill_id = nil,
    random_number = nil
  }
end

function ProtoMessage:newBattleInfoChangeReq()
  return {
    info_type = nil,
    weather_info = ProtoMessage:newBattleWeatherChangeInfo(),
    env_info = ProtoMessage:newEnvEnergyInfo()
  }
end

function ProtoMessage:newBattleInfoChangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleAiSelectSkillNotify()
  return {
    pet_id = nil,
    skill_info = ProtoMessage:newBattleAISelectSkillInfo()
  }
end

function ProtoMessage:newZoneBattleRoundOpQueryReq()
  return {}
end

function ProtoMessage:newZoneBattleRoundOpQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    items = {},
    simple_pets = {}
  }
end

function ProtoMessage:newZoneBattleNpcEscapeConfirmReq()
  return {npc_uin = nil, agree = nil}
end

function ProtoMessage:newZoneBattleNpcEscapeConfirmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleCatchConfirmReq()
  return {ticket_id = nil, num = nil}
end

function ProtoMessage:newZoneBattleCatchConfirmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    base_ball_num = nil,
    achieves = {},
    boss_shiny = nil,
    items = {},
    degenerated_boss_base_id = nil,
    boss_data = ProtoMessage:newPetData()
  }
end

function ProtoMessage:newZoneBattleTempLeaveBeastReq()
  return {}
end

function ProtoMessage:newZoneBattleTempLeaveBeastRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattlePkAgainReq()
  return {pk_again = nil}
end

function ProtoMessage:newZoneBattlePkAgainRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattlePkAgainNotify()
  return {uin = nil, pk_again = nil}
end

function ProtoMessage:newZoneBattleFinalBattleP2SummonReq()
  return {
    name = nil,
    confirmed = nil,
    pet = ProtoMessage:newPetData()
  }
end

function ProtoMessage:newZoneBattleFinalBattleP2SummonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet = ProtoMessage:newPetData(),
    perform_cmd = ProtoMessage:newBattlePerformCmd()
  }
end

function ProtoMessage:newZoneBattleCommentTriggerReq()
  return {
    comment_data = ProtoMessage:newBattlerCommentData()
  }
end

function ProtoMessage:newZoneBattleCommentTriggerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleObserverJoinReq()
  return {battler_uin = nil}
end

function ProtoMessage:newZoneBattleObserverJoinRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleObserverLeaveReq()
  return {}
end

function ProtoMessage:newZoneBattleObserverLeaveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleKickOutObserverReq()
  return {uin = nil}
end

function ProtoMessage:newZoneBattleKickOutObserverRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleObserverChangeNotify()
  return {
    observer_num = nil,
    leave_observer = {},
    enter_observer = {},
    observer_appearance_info = {}
  }
end

function ProtoMessage:newZoneBattleObserverKickedOutNotify()
  return {watch_duration = nil}
end

function ProtoMessage:newZoneBattleUpdateItemReq()
  return {
    item_list = {}
  }
end

function ProtoMessage:newPointList()
  return {
    points = {}
  }
end

function ProtoMessage:newTeamBattleNPC()
  return {actor_id = nil}
end

function ProtoMessage:newFBEyeOpen()
  return {IsOpen = nil}
end

function ProtoMessage:newHasP2Win()
  return {HasWin = nil}
end

function ProtoMessage:newLastEquipBall()
  return {EquipBallId = nil}
end

function ProtoMessage:newGoodsPrice()
  return {
    num = nil,
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil
  }
end

function ProtoMessage:newSubGoodsData()
  return {
    goods_id = nil,
    origin_price = ProtoMessage:newGoodsPrice(),
    real_price = ProtoMessage:newGoodsPrice(),
    is_gift = nil
  }
end

function ProtoMessage:newGoodsData()
  return {
    goods_id = nil,
    buy_num = nil,
    next_refresh_time = nil,
    origin_price = ProtoMessage:newGoodsPrice(),
    real_price = ProtoMessage:newGoodsPrice(),
    limit_buy_num = nil,
    disable_time = nil,
    sub_goods = {}
  }
end

function ProtoMessage:newShopData_ConsumeInfo_RewardTakenInfo()
  return {level = nil, is_reward_taken = nil}
end

function ProtoMessage:newShopData_ConsumeInfo()
  return {
    total_consume_num = nil,
    reward_taken_info = {}
  }
end

function ProtoMessage:newShopData()
  return {
    id = nil,
    consume_info = ProtoMessage:newShopData_ConsumeInfo(),
    goods_data = {},
    random_shop_shown_indexes = {},
    max_refresh_count = nil,
    refresh_count = nil,
    version = nil,
    disable_time = nil
  }
end

function ProtoMessage:newShopBuyItemInfo()
  return {goods_item_num = nil, goods_id = nil}
end

function ProtoMessage:newDBShopGoods()
  return {
    id = nil,
    buy_num = nil,
    last_refresh_time = nil,
    next_refresh_time = nil
  }
end

function ProtoMessage:newDBShopConsumeReward()
  return {level = nil, is_taken = nil}
end

function ProtoMessage:newDBShopConsumeInfo()
  return {
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    total_consume_num = nil,
    rewards = {}
  }
end

function ProtoMessage:newDBShopOne()
  return {
    id = nil,
    version = nil,
    goods_list = {},
    random_shop_shown_indexes = {},
    last_refresh_time = nil,
    max_refresh_count = nil,
    refresh_count = nil,
    acc_consume = ProtoMessage:newDBShopConsumeInfo(),
    goods_group = {}
  }
end

function ProtoMessage:newDBGoodsGroupData()
  return {
    group_id = nil,
    buy_num = nil,
    last_refresh_time = nil
  }
end

function ProtoMessage:newDBShopSharedData()
  return {
    goods_group = {}
  }
end

function ProtoMessage:newMonthCardData()
  return {
    id = nil,
    left_days = nil,
    buy_time = nil,
    sign_days = nil,
    last_sign_time = nil,
    continue_time = nil,
    reset_time = nil,
    daily_rewards = nil,
    daily_tips_show = nil
  }
end

function ProtoMessage:newDBShop()
  return {
    shops = {},
    month_card = ProtoMessage:newMonthCardData(),
    seq = nil,
    shared_data = ProtoMessage:newDBShopSharedData()
  }
end

function ProtoMessage:newOssReason()
  return {
    reason = nil,
    sub_reason1 = nil,
    sub_reason2 = nil,
    sub_reason3 = nil
  }
end

function ProtoMessage:newMidasFailRetryPresentInfo()
  return {
    charge_val = nil,
    billno = nil,
    try_times = nil,
    reason = ProtoMessage:newOssReason(),
    bill_no = nil,
    is_finish = nil
  }
end

function ProtoMessage:newMidasFailRetryPresentList()
  return {
    fails = {},
    try_last_time = nil
  }
end

function ProtoMessage:newMidasDistriBillInfo()
  return {
    billno = nil,
    update_time = nil,
    goods_id = nil,
    create_time = nil
  }
end

function ProtoMessage:newMidasDistriBillList()
  return {
    billnos = {}
  }
end

function ProtoMessage:newChargeInfo()
  return {
    money_num = nil,
    charge_times = nil,
    last_update_time = nil
  }
end

function ProtoMessage:newChargeInfoList()
  return {
    charges = {}
  }
end

function ProtoMessage:newMidasFailfo()
  return {
    charge_val = nil,
    billno = nil,
    try_times = nil,
    reason = ProtoMessage:newOssReason(),
    bill_no = nil,
    is_finish = nil,
    last_try_time = nil,
    type = nil
  }
end

function ProtoMessage:newMidasFailRetryList()
  return {
    fails = {}
  }
end

function ProtoMessage:newMidasMoneyInfo()
  return {
    last_recharge_points_num = nil,
    last_recharge_points_time = nil,
    midas_balance = nil,
    midas_save_amt = nil,
    fail_data_nouse = ProtoMessage:newMidasFailRetryPresentList(),
    out_game_buy_num = nil,
    charge_data = ProtoMessage:newChargeInfoList(),
    last_update_time = nil,
    free_balance = nil,
    use_charge_points_num = nil,
    pay_points_num = nil,
    last_charge_money_num = nil,
    last_charge_time = nil,
    last_usecharge_money_num = nil,
    last_usecharge_time = nil,
    gid = nil,
    midas_gen_save_amt = nil,
    distribute_amt = nil,
    total_test_amt = nil,
    is_calc_test_amt = nil,
    fail_data = ProtoMessage:newMidasFailRetryList(),
    last_try_time = nil
  }
end

function ProtoMessage:newAutoParam()
  return {
    key = nil,
    require = nil,
    type = nil,
    param_name = nil,
    param_desc = nil,
    param_str = {}
  }
end

function ProtoMessage:newCommGmCmd()
  return {
    cmd_id = nil,
    cmd_name = nil,
    cmd_desc = nil,
    params = {},
    cmd_belong = nil
  }
end

function ProtoMessage:newGmNpcInfo()
  return {
    obj_id = nil,
    npc_cfg_id = nil,
    npc_detail_type = nil,
    name = nil,
    content_cfg_id = nil,
    pos = ProtoMessage:newPosition(),
    view = nil,
    advance_npc = nil,
    weight = nil,
    distance = nil
  }
end

function ProtoMessage:newGmNpcBlackboard()
  return {actor_id = nil, blackboard_str = nil}
end

function ProtoMessage:newDotsServerAIInfo()
  return {
    actor_id = nil,
    pt = ProtoMessage:newPoint(),
    lod_type = nil,
    owner_id = nil
  }
end

function ProtoMessage:newDotsServerAIOwnerPlayerInfo()
  return {
    player_id = nil,
    pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newDotsServerAIVisualizationInfo()
  return {
    ai_list = {},
    player_list = {},
    total_ai_count = nil,
    total_rsp_num = nil,
    cur_rsp_index = nil
  }
end

function ProtoMessage:newNavFindPathInfo()
  return {
    pos = {}
  }
end

function ProtoMessage:newHomePetGmStealInfo()
  return {
    pet_gid = nil,
    name = nil,
    goods_num = nil,
    goods_total_num = nil
  }
end

function ProtoMessage:newMailCustomContent()
  return {
    excel_id = nil,
    reward_list = {},
    rewards = ProtoMessage:newGoodsReward()
  }
end

function ProtoMessage:newTlogPlayerInfo()
  return {
    game_svr_id = nil,
    event_time = nil,
    app_id = nil,
    plat_id = nil,
    world_id = nil,
    openid = nil,
    uin = nil,
    role_name = nil,
    role_level = nil
  }
end

function ProtoMessage:newMailParamInfo()
  return {key = nil, value = nil}
end

function ProtoMessage:newMailParamList()
  return {
    content_param_list = {},
    title_param_list = {}
  }
end

function ProtoMessage:newMailRecvBrief()
  return {
    mail_gid = nil,
    mail_conf_id = nil,
    params = ProtoMessage:newMailParamList(),
    reward = ProtoMessage:newGoodsReward(),
    title = nil,
    contents = nil,
    reward_id = nil,
    guard_id = nil,
    add_time = nil,
    expire_at = nil,
    mail_serial_num = nil,
    mail_sub_type = nil
  }
end

function ProtoMessage:newMailFailInfo()
  return {
    brief_info = ProtoMessage:newMailRecvBrief(),
    fail_num = nil
  }
end

function ProtoMessage:newMageNpcItem()
  return {
    id = nil,
    unlocked = nil,
    awarded = nil
  }
end

function ProtoMessage:newMageNpcInfo()
  return {
    id = nil,
    items = {},
    unlocked = nil,
    disabled_in_camp = nil,
    assist_times = nil
  }
end

function ProtoMessage:newMageNpcAssignInfo()
  return {
    id = nil,
    type = nil,
    npcs = {}
  }
end

function ProtoMessage:newMageCampAssignInfo()
  return {id = nil, rest_conf_id = nil}
end

function ProtoMessage:newMageNpcCampInfo()
  return {
    id = nil,
    task_finish = nil,
    disabled = nil
  }
end

function ProtoMessage:newBookData_NightmareData()
  return {done = nil}
end

function ProtoMessage:newBookData_BloodMagicData()
  return {done = nil, reward = nil}
end

function ProtoMessage:newBookData_NotebookKeliData_Clew()
  return {
    stage = nil,
    is_new = nil,
    unlock = nil
  }
end

function ProtoMessage:newBookData_NotebookKeliData()
  return {
    to_do_done = {},
    clews = {},
    black_text = ProtoMessage:newBookData_NotebookKeliData_Clew(),
    medal_state = nil
  }
end

function ProtoMessage:newBookData()
  return {
    book_type = ProtoEnum.TaleTaskType.TTT_NONE,
    book_id = nil,
    unlock = nil,
    unlock_timestamp = nil,
    nightmare_data = ProtoMessage:newBookData_NightmareData(),
    blood_magic_data = ProtoMessage:newBookData_BloodMagicData(),
    notebook_keli_data = ProtoMessage:newBookData_NotebookKeliData()
  }
end

function ProtoMessage:newObserveBattle()
  return {
    deny = nil,
    mode = ProtoEnum.ObserveBattleMode.OBM_MODE_1
  }
end

function ProtoMessage:newPlayerSettings_Pvp()
  return {
    observe_battle = ProtoMessage:newObserveBattle(),
    open_rank = nil
  }
end

function ProtoMessage:newPlayerSettings_Friendship()
  return {
    can_be_searched = nil,
    can_be_sugguested = nil,
    can_be_add_friend = nil,
    can_stranger_visit = nil
  }
end

function ProtoMessage:newPlayerSettings_UserSubscribe()
  return {
    hatch_egg = nil,
    travel = nil,
    debris_full = nil,
    new_activity = nil,
    friend_battle = nil,
    exchange_egg = nil,
    friend_visit = nil
  }
end

function ProtoMessage:newPlayerSettings_PersonalizedRecommendations()
  return {friend_pr = nil}
end

function ProtoMessage:newPlayerSettings()
  return {
    observe_battle = ProtoMessage:newObserveBattle(),
    friendship = ProtoMessage:newPlayerSettings_Friendship(),
    quality = nil,
    is_hide_unlock_skill = nil,
    user_subsribe = ProtoMessage:newPlayerSettings_UserSubscribe(),
    pvp = ProtoMessage:newPlayerSettings_Pvp(),
    recommendations = ProtoMessage:newPlayerSettings_PersonalizedRecommendations()
  }
end

function ProtoMessage:newGrassTrialFusedSkillData()
  return {
    base_skill_id = nil,
    fused_power = nil,
    fused_energy_cost = nil,
    fusion_count = nil,
    fusion_max = nil,
    skill_type = nil,
    merged_skill_ids = {},
    slot_pos = nil
  }
end

function ProtoMessage:newGrassTrialPet()
  return {
    pet_gid = nil,
    base_conf_id = nil,
    current_hp = nil,
    max_hp = nil,
    level = nil,
    energy_ceiling = nil,
    growth = nil,
    skills = {},
    acquired_feature_ids = {},
    acquired_shard_effect_ids = {}
  }
end

function ProtoMessage:newGrassTrialNodeRecord()
  return {
    chapter_id = nil,
    node_index = nil,
    event_conf_id = nil,
    opponent_monster_id = nil,
    is_completed = nil
  }
end

function ProtoMessage:newGrassTrialNodeEvent()
  return {
    slot_index = nil,
    event_conf_id = nil,
    reward_id = nil,
    event_refresh_cost = nil,
    reward_refresh_cost = nil,
    random_skills = {},
    level = nil
  }
end

function ProtoMessage:newGrassTrialNodeSelection()
  return {
    node_events = {},
    event_refresh_count = nil,
    reward_refresh_count = nil
  }
end

function ProtoMessage:newGrassTrialEventSelected()
  return {
    event_conf_id = nil,
    reward_id = nil,
    is_waiting_recieve = nil
  }
end

function ProtoMessage:newGrassTrialChallengeData()
  return {
    state = nil,
    trial_conf_id = nil,
    current_chapter_id = nil,
    current_node_index = nil,
    trial_pet_data = ProtoMessage:newGrassTrialPet(),
    initial_skill_id = nil,
    remaining_coin = nil,
    active_trial_effect_ids = {},
    completed_nodes = {},
    chapter_event_pool = {},
    current_selection = ProtoMessage:newGrassTrialNodeSelection(),
    challenge_start_time = nil,
    accumulated_score = nil,
    discovered_monster_ids = {},
    fusion_type = nil,
    event_selected = ProtoMessage:newGrassTrialEventSelected(),
    first_dungeon_id = nil,
    leaved_second_scene = nil
  }
end

function ProtoMessage:newGrassTrialReviewRecord()
  return {
    settle_timestamp = nil,
    petbase_conf_id = nil,
    pet_level = nil,
    pet_growth = nil,
    trial_conf_id = nil,
    is_victory = nil,
    challenge_duration = nil,
    node_records = {},
    review_skills = {},
    review_feature_ids = {},
    review_shard_ids = {}
  }
end

function ProtoMessage:newGrassTrialReviewSkillInfo()
  return {
    base_skill_id = nil,
    fusion_count = nil,
    merged_skill_ids = {}
  }
end

function ProtoMessage:newGrassTrialHandbookSlotReward()
  return {
    trial_conf_id = nil,
    reward_id = nil,
    reward_count = nil
  }
end

function ProtoMessage:newGrassTrialHandbookSlotState()
  return {
    pet_base_id = nil,
    slot_index = nil,
    slot_type = nil,
    slot_reward = {}
  }
end

function ProtoMessage:newGrassTrialLogSceneRecord()
  return {
    log_conf_id = nil,
    discovered_monster_ids = {},
    final_reward_claimed = nil
  }
end

function ProtoMessage:newGrassTrialPeriodReward()
  return {
    required_score = nil,
    state = ProtoMessage:newRewardState()
  }
end

function ProtoMessage:newGrassTrialPeriodData()
  return {
    period_conf_id = nil,
    period_reward = {},
    current_period_score = nil
  }
end

function ProtoMessage:newGrassTrialProgressData()
  return {
    cleared_trial_ids = {},
    first_reward_claimed_trial_ids = {},
    handbook_slots = {},
    review_records = {},
    log_records = {}
  }
end

function ProtoMessage:newGrassTrialData()
  return {
    challenge_data = ProtoMessage:newGrassTrialChallengeData(),
    progress_data = ProtoMessage:newGrassTrialProgressData(),
    period_data = ProtoMessage:newGrassTrialPeriodData()
  }
end

function ProtoMessage:newBadgeTrialData()
  return {
    grass_trial_data = ProtoMessage:newGrassTrialData()
  }
end

function ProtoMessage:newDungeonInfo()
  return {
    dungeon_id = nil,
    last_enter_time = nil,
    dungeon_finish_count = nil,
    total_finish_count = nil,
    dungeon_inst_id = nil,
    scene_inst_id = nil,
    cell_id = nil,
    pt = ProtoMessage:newPoint(),
    destroy = nil,
    last_quit_halfway = nil,
    from_scene_cfg_id = nil,
    from_pos = ProtoMessage:newPoint(),
    current_finish = nil,
    last_leave_time = nil,
    open_stage_ids = {},
    ack_bst_finish = nil,
    finish_stage_ids = {},
    need_reset_stage = nil,
    first_enter_time = nil,
    first_finish_time = nil,
    collect_finish = nil,
    finished_stage_ids = {}
  }
end

function ProtoMessage:newPlayerDungeonInfo()
  return {
    dungeon_infos = {},
    delay_reset_check = nil,
    back_to_bigworld_scene_id = nil,
    back_to_bigworld_pt = ProtoMessage:newPoint(),
    will_to_dungeon_cfg_id = nil
  }
end

function ProtoMessage:newDungeonStateInfo()
  return {
    dungeon_id = nil,
    dungeon_state = nil,
    done_count = nil,
    entered = nil,
    from_scene_cfg_id = nil,
    from_pt = ProtoMessage:newPoint(),
    need_bst_finish = nil,
    finish_stage_ids = {},
    finished_stage_ids = {}
  }
end

function ProtoMessage:newGuideGroup()
  return {
    group_id = nil,
    finish_all = nil,
    finish_index = {}
  }
end

function ProtoMessage:newActivityPetTripLotteryRecord()
  return {
    activity_id = nil,
    result = nil,
    lottery_id = nil,
    total_happy_value = nil,
    wish_choice = nil,
    total_record_num = nil,
    goods_id = nil,
    goods_type = nil,
    num = nil,
    pet_gift_num = nil
  }
end

function ProtoMessage:newSeasonCatchRewardInfo()
  return {reward_refresh_time = nil, reward_daily_num = nil}
end

function ProtoMessage:newPlayerMiscInfo()
  return {
    cur_selected_throw_item = ProtoMessage:newThrowItemInfo(),
    diamond_buy_star_times = nil,
    cur_selected_magic_item_gid = nil,
    star_recover_time = nil,
    player_rp_behavior_list = {},
    minute_send_add_friend_count = nil,
    battle_ai_world_num = {},
    star_debris_recover_time = nil,
    star_debris_state = nil,
    storage_goods = {},
    gp_contest_info = ProtoMessage:newPlayerGPContestInfo(),
    pve_challenge_pet_selected_id = nil,
    friend_num_cache = nil,
    guide_info = {},
    home_level_reward_info = ProtoMessage:newHomeLevelRewardInfo(),
    query_h5_succ = nil,
    last_move_merge_time = nil,
    last_fashionbond_tab = nil,
    ios_rating_popup_time = nil,
    netbar_reward_expiration = nil,
    gift_code = nil,
    plat_friend_num_cache = nil,
    video_recording = nil,
    player_rp_behavior_using_list = {},
    activity_lottery_records = {},
    offline_operation_consume_state = ProtoMessage:newOfflineOperationConsumeState(),
    has_aicoach_shown_notify = nil,
    season_catch_reward_info = ProtoMessage:newSeasonCatchRewardInfo()
  }
end

function ProtoMessage:newPlayerBookData()
  return {
    book_data = {}
  }
end

function ProtoMessage:newGuideBook()
  return {
    id = nil,
    stamps = {},
    unlocked_at = nil
  }
end

function ProtoMessage:newPlayerWorldMapInfo()
  return {
    guide_books = {}
  }
end

function ProtoMessage:newPlayerMageBookInfo()
  return {
    npcs = {},
    delayed_npcs = {},
    delayed_items = {},
    helper_npcs = {},
    helper_assign = {},
    enabled = nil,
    npc_refresh_time = nil,
    helper_assign_time = nil,
    camp_info = {},
    camp_assign = {}
  }
end

function ProtoMessage:newPetTeamShareData()
  return {
    valid_pet_gids = {}
  }
end

function ProtoMessage:newPlayerMailFailInfo()
  return {
    mail_fail_info_list = {}
  }
end

function ProtoMessage:newEvalutionGroupShareForm()
  return {evaluation_group = nil, card_quality = nil}
end

function ProtoMessage:newShareFormItem()
  return {id = nil}
end

function ProtoMessage:newPlayerShareFormInfo()
  return {
    share_form_item = {},
    evaluation_share_form_info = {}
  }
end

function ProtoMessage:newPlayerQQAchievementStats()
  return {use_pet_ball_num = nil}
end

function ProtoMessage:newPlayerQQAchievementInfo()
  return {
    cur_day = nil,
    day_acc_game_duration = nil,
    last_stat_time = nil,
    achievement_reg_channel = nil,
    stats = ProtoMessage:newPlayerQQAchievementStats()
  }
end

function ProtoMessage:newPlayerEmojiItem()
  return {emoji_id = nil, is_unlock = nil}
end

function ProtoMessage:newPlayerEmojiBagInfo()
  return {
    emoji_list = {}
  }
end

function ProtoMessage:newPetCertiMedalHistory()
  return {activity_id = nil, pet_chains = nil}
end

function ProtoMessage:newPlayerPetMedalInfo()
  return {
    medal_infos = {},
    collection = {},
    addi_info = {},
    pet_certi_history = {}
  }
end

function ProtoMessage:newCliPetMedalInfo()
  return {
    collection = {}
  }
end

function ProtoMessage:newPlayerGiftInfo()
  return {
    gift_giving_datas = {},
    check_giving_gift_timestamp = nil
  }
end

function ProtoMessage:newPlayerBattleData_ObserveBattleData()
  return {
    uin = nil,
    flag = nil,
    backup_scene = ProtoMessage:newPlayerSceneInfo(),
    observe_start_time = nil
  }
end

function ProtoMessage:newPlayerBattleData()
  return {
    create_battle_info = ProtoMessage:newCreateBattleInfo(),
    battle_inst_id = nil,
    battle_field_id = nil,
    source_data = ProtoMessage:newSourceData(),
    settle_step = ProtoEnum.PlayerBattleData.SETTLE_STEP.SETTLE_STEP_IDLE,
    settle_info = ProtoMessage:newBattleSettleInfo(),
    scene_rpc_ing = nil,
    scene_rpc_cnt = nil,
    scene_settle_info = ProtoMessage:newPlayerBattleData_SceneSettleInfo(),
    need_check = nil,
    observe_battle = ProtoMessage:newPlayerBattleData_ObserveBattleData(),
    bfid_inc_id = nil,
    z2b_create_ing = nil
  }
end

function ProtoMessage:newPlayerMailDataInfo()
  return {mail_cache_num = nil, last_marquee_check_time = nil}
end

function ProtoMessage:newIdipMailSerialInfo()
  return {serial = nil, update_time = nil}
end

function ProtoMessage:newIdipMailSerialList()
  return {
    serials = {}
  }
end

function ProtoMessage:newPlayerSvrDataInfo()
  return {
    time_offset = nil,
    last_daily_tick_time = nil,
    dungeon_info = ProtoMessage:newPlayerDungeonInfo(),
    hope_data = ProtoMessage:newPlayerHopeData(),
    battle_pass_info = ProtoMessage:newPlayerBattlePassInfo(),
    card_info = ProtoMessage:newPlayerCardInfo(),
    sub_task_info = ProtoMessage:newPlayerSubTaskInfo(),
    appearance_info = ProtoMessage:newPlayerAppearanceInfo(),
    share_form_info = ProtoMessage:newPlayerShareFormInfo(),
    battle_data = ProtoMessage:newPlayerBattleData(),
    received_mail_list = {},
    receive_failed_mail_list = {},
    attachment_receive_fail_mail_list = {},
    next_mail_expire_time = nil,
    send_fail_mail_brief = {},
    adventure_data = ProtoMessage:newPlayerAdventureData(),
    visit_data = ProtoMessage:newPlayerVisitData(),
    invest_task = ProtoMessage:newPlayerInvestTaskData(),
    teleports = {},
    teach_infos = {},
    activity_info = ProtoMessage:newPlayerActivityInfo(),
    copy_data = ProtoMessage:newPlayerCopyData(),
    exchange_info = ProtoMessage:newPlayerExchangeInfo(),
    player_interact_info = ProtoMessage:newPlayerInteractInfo(),
    mage_book_info = ProtoMessage:newPlayerMageBookInfo(),
    task_summary_data = ProtoMessage:newTaskSummaryList(),
    money_info = ProtoMessage:newMidasMoneyInfo(),
    shiny_pet_day_info = ProtoMessage:newPlayerShinyPetDayInfo(),
    distribute_billnos = ProtoMessage:newMidasDistriBillList(),
    last_pet_stat_report_time = nil,
    last_pet_world_stat_update_time = nil,
    spec_flower_seeds = {},
    area_check_infos = {},
    last_pet_battle_stat_update_time = nil,
    crop_fruits = ProtoMessage:newPlayerCropFruitList(),
    npc_idip_action = ProtoMessage:newSceneIdipActionNpcList(),
    gift_limit_info = ProtoMessage:newPlayerGiftLimitList(),
    badge_challenge_data = ProtoMessage:newBadgeChallengeData(),
    mail_version = nil,
    season_info = ProtoMessage:newSeasonInfo(),
    gift_info = ProtoMessage:newPlayerGiftInfo(),
    gifts_limit_info = ProtoMessage:newPlayerTypeGiftLimitList(),
    items_limit_info = {},
    pet_medal_info = ProtoMessage:newPlayerPetMedalInfo(),
    share_info = ProtoMessage:newPlayerShareInfo(),
    pet_egg_data = ProtoMessage:newPlayerPetEggData(),
    goods_trans = ProtoMessage:newGoodsModifyTransAllInfo(),
    pet_team_share_data = ProtoMessage:newPetTeamShareData(),
    shop = ProtoMessage:newDBShop(),
    last_check_exchange_goods_time = nil,
    mail_fail_info = ProtoMessage:newPlayerMailFailInfo(),
    liabilities_mail_send_info = ProtoMessage:newDailySendMailList(),
    season_adventure = ProtoMessage:newPlayerSeasonAdventureData(),
    teaching_tab_info = ProtoMessage:newPlayerTeachingTabInfo(),
    mail_info = ProtoMessage:newPlayerMailDataInfo(),
    npc_lottery_data = {},
    badge_trial_data = ProtoMessage:newBadgeTrialData(),
    idip_mail_serials = ProtoMessage:newIdipMailSerialList(),
    opt_reward_info = ProtoMessage:newOptReWardNumList(),
    flow_gid = nil
  }
end

function ProtoMessage:newPlayerRedPointInfo()
  return {
    group_info = {},
    cached_group_info = {}
  }
end

function ProtoMessage:newMusicApplyInfo()
  return {music_id = nil, apply_list_id = nil}
end

function ProtoMessage:newPlayerMusicInfo()
  return {
    music_id_list = {},
    apply_list = {}
  }
end

function ProtoMessage:newPlayerStarLightInfo()
  return {
    current_progress = nil,
    unexchange_wishing_star_num = nil,
    current_efficiency = nil,
    today_star_light_num = nil,
    need_notify_refresh = nil
  }
end

function ProtoMessage:newPlayerPetInfo()
  return {
    pet_data = {},
    catch_info = {},
    generation_gid = nil,
    fellow_gid = nil,
    bag_pos_gid = {},
    seen_monster_bits = nil,
    team_info = ProtoMessage:newPetTeamInfo(),
    handbook = ProtoMessage:newPetHandbook(),
    backpack_info = ProtoMessage:newPetBackpackInfo(),
    habit_info = ProtoMessage:newPetHabitInfo(),
    statistics_info = ProtoMessage:newPetStatisticsInfo(),
    travel_info = {},
    visit_remain_catch_times = nil,
    next_visit_catch_refresh_time = nil,
    team_infos = {},
    visit_remain_shiny_catch_times = nil,
    last_visit_shiny_catch_refresh_time = nil,
    deleted_pet_list = ProtoMessage:newDeletedPetList(),
    home_pet_info = {},
    version = nil,
    pseudo_egg_shiny_cum_prob = {},
    gift_egg_list = ProtoMessage:newGiftEggList(),
    pet_report_info = {},
    last_write_friend_db_time = nil,
    mirror_pet_data = {},
    pet_once_patch_version = nil,
    pet_use_info = {},
    backtrack_info = {},
    pseudo_egg_glass_cum_prob = {},
    pet_medal_info = ProtoMessage:newCliPetMedalInfo(),
    pet_task_info = ProtoMessage:newPetTaskInfo(),
    monitor_info = ProtoMessage:newPlayerPetMonitorInfo(),
    current_select_pet_gid = nil,
    report_brief_info = ProtoMessage:newPetReportBriefInfo()
  }
end

function ProtoMessage:newPlayerCommonInfo()
  return {
    coupon = nil,
    coin = nil,
    coin_locked = nil,
    elo = nil,
    in_game_time = nil,
    tod_updated_time = nil,
    scene_info = ProtoMessage:newPlayerSceneInfo(),
    level_award_info = ProtoMessage:newPlayerLevelAwardInfo(),
    climb_chapter = ProtoMessage:newPlayerClimbChapterInfo(),
    start_server_ai = nil,
    in_dungeon_id = {},
    online_visit_owner = nil,
    ban_player_reason = nil,
    chat_permission_date = nil,
    ban_chat_reason = nil,
    select_pet_conf_id = nil,
    region_id = nil,
    select_pet_conf_id_list = {},
    next_region_group_id = nil,
    pet_select_region_id = {},
    visit_permission_setting = nil,
    navigation_mode_type = nil,
    home_last_visit_time = nil,
    is_home_visiting = nil,
    home_owner_uin = nil,
    is_online_visiting_home = nil,
    home_source_scene_cfg_id = nil,
    home_source_scene_inst_id = nil,
    home_source_location = ProtoMessage:newPoint(),
    ban_info = ProtoMessage:newPlayerBanInfo()
  }
end

function ProtoMessage:newPlayerBattlePassExpInfo()
  return {
    last_week_exp = nil,
    level = nil,
    exp = nil,
    last_refresh_time = nil
  }
end

function ProtoMessage:newPlayerBattlePassRewardInfo_RewardTakenInfo()
  return {
    is_free_reward_taken = nil,
    is_paid_reward_taken = nil,
    bp_level = nil
  }
end

function ProtoMessage:newPlayerBattlePassRewardInfo()
  return {
    reward_taken_info = {}
  }
end

function ProtoMessage:newPlayerBattlePassTaskInfo()
  return {
    daily_task_ids = {},
    repeat_task_ids = {},
    last_daily_task_reset_time = nil,
    task_info_list = {}
  }
end

function ProtoMessage:newPlayerBattlePassInfo()
  return {
    battle_pass_id = nil,
    theme_id = nil,
    exp_info = ProtoMessage:newPlayerBattlePassExpInfo(),
    reward_info = ProtoMessage:newPlayerBattlePassRewardInfo(),
    task_info = ProtoMessage:newPlayerBattlePassTaskInfo(),
    bought_gift_sub_bag_item_ids = {}
  }
end

function ProtoMessage:newGiftDropWeightBagNumItem()
  return {id = nil, num = nil}
end

function ProtoMessage:newGiftDropWeithBagNumInfo()
  return {
    id_type = nil,
    items = {}
  }
end

function ProtoMessage:newPlayerBagItemIdFlagInfo()
  return {id = nil, flag = nil}
end

function ProtoMessage:newPlayerBagItemIdFlagTypeInfo()
  return {
    type = nil,
    items = {}
  }
end

function ProtoMessage:newPlayerBagItemIdFlagList()
  return {
    bag_flag_items = {}
  }
end

function ProtoMessage:newBagItemExpireInfo()
  return {
    id = nil,
    expire_time = nil,
    num = nil,
    gid = nil,
    is_finish_conver = nil
  }
end

function ProtoMessage:newBagItemExpireList()
  return {
    items = {}
  }
end

function ProtoMessage:newPlayerBagInfo()
  return {
    gid = nil,
    item_list = {},
    equipped_ball_num = nil,
    had_item_info = {},
    bag_backpack = ProtoMessage:newBagBackpackInfo(),
    pet_medal_task_info = {},
    had_item_list = {},
    is_copy = nil,
    version = nil,
    drop_weight_info = {},
    mask_bag_list = {},
    last_check_mask_time = nil,
    bag_item_id_flag = ProtoMessage:newPlayerBagItemIdFlagList(),
    bag_item_expire_list = ProtoMessage:newBagItemExpireList()
  }
end

function ProtoMessage:newPlayerBlackData()
  return {black_uin = nil, block_time = nil}
end

function ProtoMessage:newPlayerObserveBattleBlackData()
  return {
    battle_id = nil,
    black_list = {}
  }
end

function ProtoMessage:newPlayerBlackInfo()
  return {
    black_list = {},
    observe_battle_black_list = ProtoMessage:newPlayerObserveBattleBlackData()
  }
end

function ProtoMessage:newPlayerClientWaterMarkInfo()
  return {close_watermark = nil, end_time = nil}
end

function ProtoMessage:newPlayerInfo()
  return {
    brief_info = ProtoMessage:newPlayerBriefInfo(),
    common_info = ProtoMessage:newPlayerCommonInfo(),
    bag_info = ProtoMessage:newPlayerBagInfo(),
    pet_info = ProtoMessage:newPlayerPetInfo(),
    ability_info = ProtoMessage:newPlayerAbilityInfo(),
    story_flag_info = ProtoMessage:newPlayerStoryFlagInfo(),
    misc_info = ProtoMessage:newPlayerMiscInfo(),
    world_map_info = ProtoMessage:newPlayerWorldMapInfo(),
    svr_data_info = ProtoMessage:newPlayerSvrDataInfo(),
    red_point_info = ProtoMessage:newPlayerRedPointInfo(),
    black_info = ProtoMessage:newPlayerBlackInfo(),
    pvp_his_cli = ProtoMessage:newPlayerPvpHisCli(),
    music_info = ProtoMessage:newPlayerMusicInfo(),
    star_light_info = ProtoMessage:newPlayerStarLightInfo(),
    emoji_bag_info = ProtoMessage:newPlayerEmojiBagInfo(),
    lottery_confirm = ProtoMessage:newPlayerLotteryRewardConfirmBagInfo(),
    client_water_mark_info = ProtoMessage:newPlayerClientWaterMarkInfo(),
    start_up_privilege_info = ProtoMessage:newPlayerStartUpPrivilegeInfo()
  }
end

function ProtoMessage:newPlayerPetEggData()
  return {
    egg_core_records = {}
  }
end

function ProtoMessage:newCDKeyInfo()
  return {cdkey = nil, used = nil}
end

function ProtoMessage:newPlayerCDKeyInfo()
  return {
    cdkey_list = {}
  }
end

function ProtoMessage:newPlayerGiftLimitItem()
  return {
    id = nil,
    cnt = nil,
    last_update_time = nil
  }
end

function ProtoMessage:newPlayerGiftLimitList()
  return {
    items = {}
  }
end

function ProtoMessage:newPlayerTypeGiftLimitItem()
  return {
    items = {},
    type = nil
  }
end

function ProtoMessage:newPlayerTypeGiftLimitList()
  return {
    items = {}
  }
end

function ProtoMessage:newDailySendMailItem()
  return {id = nil, mail_send_times = nil}
end

function ProtoMessage:newDailySendMailInfo()
  return {
    type = nil,
    items = {}
  }
end

function ProtoMessage:newDailySendMailList()
  return {
    items = {}
  }
end

function ProtoMessage:newDailyItemReasonGetInfo()
  return {
    guard_id = nil,
    total_num = nil,
    total_times = nil,
    has_limited = nil
  }
end

function ProtoMessage:newDailyGetItemLimitInfo()
  return {
    id = nil,
    reason_gets = {}
  }
end

function ProtoMessage:newOptReWardNumInfo()
  return {opt_id = nil, num = nil}
end

function ProtoMessage:newOptReWardNumList()
  return {
    items = {}
  }
end

function ProtoMessage:newDailyGetItemLimitlist()
  return {
    goods_type = nil,
    items = {}
  }
end

function ProtoMessage:newPlayerBattleData_RewardNpcInfo()
  return {npc_conf_id = nil, npc_num = nil}
end

function ProtoMessage:newPlayerBattleData_SceneSettleInfo()
  return {
    catch_pet_cnt = nil,
    npc_info = {}
  }
end

function ProtoMessage:newStampInfo()
  return {unlock_num = nil, unlocked_at = nil}
end

function ProtoMessage:newRedPointGroup()
  return {
    reason_type = nil,
    point_data = {}
  }
end

function ProtoMessage:newPlayerTeleportData()
  return {id = nil, lv = nil}
end

function ProtoMessage:newPlayerCopyData()
  return {src_uin = nil, copy_time = nil}
end

function ProtoMessage:newPlayerCropFruitInfo()
  return {
    owl_sanctuary_id = nil,
    num = nil,
    bag_item_id = nil
  }
end

function ProtoMessage:newPlayerCropFruitList()
  return {
    crop_fruit_list = {}
  }
end

function ProtoMessage:newPlayerShareRewardInfo()
  return {
    reward_group_type = nil,
    shared_times = nil,
    last_share_timestamp = nil,
    last_refresh_timestamp = nil
  }
end

function ProtoMessage:newPlayerShareInfo()
  return {
    reward_groups = {}
  }
end

function ProtoMessage:newPlayerSyncInfo()
  return {
    level = nil,
    exp = nil,
    battle_state = ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IDLE,
    coupon = nil,
    coin = nil,
    coin_locked = nil,
    elo = nil,
    servertime = nil,
    name = nil,
    sex = nil,
    in_dungeon_id = {},
    world_level = nil,
    online_visit_owner = nil,
    select_pet_conf_id = nil,
    vitem_info = ProtoMessage:newPlayerVItemInfo(),
    select_pet_conf_id_list = {},
    pet_select_region_id = {}
  }
end

function ProtoMessage:newServerPref()
  return {
    int_value = nil,
    list_value = {},
    str_value = nil,
    key = nil
  }
end

function ProtoMessage:newHeroPref()
  return {
    id = nil,
    prefs = {}
  }
end

function ProtoMessage:newPlayerServerPref()
  return {
    hero_prefs = {}
  }
end

function ProtoMessage:newPlayerCliBuffInfo()
  return {
    buff = nil,
    sever_pref = ProtoMessage:newPlayerServerPref()
  }
end

function ProtoMessage:newPlayerCardInfo_CardItemOwnedInfo()
  return {
    card_item_id = nil,
    card_item_get_timestamp = nil,
    card_item_num = nil
  }
end

function ProtoMessage:newPlayerCardInfo()
  return {
    last_name_changed_time = nil,
    icon_owned = {},
    skin_owned = {},
    label_owned = {},
    cached_name = nil
  }
end

function ProtoMessage:newPlayerCatchBallRewardInfo()
  return {
    last_reward_time = nil,
    next_reward_time = nil,
    catch_ball_reward_num = nil,
    enable_reward = nil,
    red_point_sent = nil
  }
end

function ProtoMessage:newPlayerAreaCheckInfo()
  return {
    area_id = nil,
    radius = nil,
    conf_id = nil
  }
end

function ProtoMessage:newPlayerTeachInfo()
  return {
    teach_id = nil,
    status = ProtoEnum.PlayerTeachInfo.TeachStatus.LOCK,
    unlock_time = nil,
    multi_condi_bit = nil,
    multi_condi_priority = nil
  }
end

function ProtoMessage:newTeachingUnlockProgress()
  return {
    type = ProtoEnum.SkillDamType.SDT_INVALID,
    count = nil,
    break_award_sort = {}
  }
end

function ProtoMessage:newTeachingTask()
  return {
    id = nil,
    is_complete = nil,
    is_rewarded = nil
  }
end

function ProtoMessage:newTeaching()
  return {
    id = nil,
    is_unlock = nil,
    unlock_progress = {}
  }
end

function ProtoMessage:newPlayerTeachingTabInfo()
  return {
    type_advantage = {},
    type_advantage_tasks = {},
    combat_mechanism = {},
    combat_mechanism_tasks = {}
  }
end

function ProtoMessage:newLotteryRewardRecord()
  return {
    reward_conf_id = nil,
    total_claimed = nil,
    daily_claimed = nil,
    last_claim_day = nil,
    weely_claimed = nil
  }
end

function ProtoMessage:newPlayerNpcLotteryData()
  return {
    logic_id = nil,
    logic_version = nil,
    lottery_pool_id = nil,
    reward_records = {},
    logic_ver = nil,
    daily_reset_time = nil,
    weely_reset_time = nil
  }
end

function ProtoMessage:newVisibleAvatarInfo()
  return {
    uin = nil,
    name = nil,
    credit_score = nil,
    relation = ProtoEnum.VisibleAvatarInfo.RelationShip.NONE
  }
end

function ProtoMessage:newVisiblePlanInfo()
  return {
    area_id = nil,
    plan_id = nil,
    avatar_list = {}
  }
end

function ProtoMessage:newRankboardKey()
  return {
    rank_type = ProtoEnum.RankListType.RANK_LIST_TYPE_INVALID,
    rank_id = nil
  }
end

function ProtoMessage:newCSRankUser()
  return {
    rank = nil,
    user_info = ProtoMessage:newRankUserInfo(),
    estimated = ProtoMessage:newRankEstimatedData()
  }
end

function ProtoMessage:newRankUserInfo()
  return {
    info_id = nil,
    score = nil,
    sort_field1 = nil,
    sort_field2 = nil,
    sort_field3 = nil,
    sort_field4 = nil,
    sort_field5 = nil,
    ext_data = ProtoMessage:newRankExtData()
  }
end

function ProtoMessage:newRankEstimatedData()
  return {total_count = nil, rank = nil}
end

function ProtoMessage:newRankExtData()
  return {
    base_data = ProtoMessage:newBaseRankExtData(),
    pvp_data = ProtoMessage:newPvpRankExtData(),
    photo_contest = ProtoMessage:newPhotoContestRankExtData()
  }
end

function ProtoMessage:newBaseRankExtData()
  return {
    game_app_id = nil,
    plat_info = ProtoMessage:newPlatInfo(),
    openid = nil,
    name = nil,
    level = nil,
    card_icon_selected = nil
  }
end

function ProtoMessage:newPvpRankExtData()
  return {
    rd = nil,
    vol = nil,
    r = nil
  }
end

function ProtoMessage:newPhotoContestRankExtData()
  return {
    photo_url = nil,
    photo_md5 = nil,
    mini_photo_url = nil,
    mini_photo_md5 = nil,
    activity_id = nil,
    like_count = nil
  }
end

function ProtoMessage:newDebugDrawParams()
  return {owner_uin = nil, zone_buspp_inst_id = nil}
end

function ProtoMessage:newDebugDrawColor()
  return {
    R = nil,
    G = nil,
    B = nil,
    A = nil
  }
end

function ProtoMessage:newDebugDrawRotator()
  return {
    x = nil,
    y = nil,
    z = nil,
    w = nil
  }
end

function ProtoMessage:newDebugDrawPointData()
  return {
    point_pos = ProtoMessage:newPosition(),
    point_size = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil
  }
end

function ProtoMessage:newDebugDrawLineData()
  return {
    start_pos = ProtoMessage:newPosition(),
    end_pos = ProtoMessage:newPosition(),
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil,
    arrow_size = nil
  }
end

function ProtoMessage:newDebugDrawSphereData()
  return {
    center = ProtoMessage:newPosition(),
    radius = nil,
    segments = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil
  }
end

function ProtoMessage:newDebugDrawBoxData()
  return {
    center = ProtoMessage:newPosition(),
    extent = ProtoMessage:newPosition(),
    color = ProtoMessage:newDebugDrawColor(),
    rotator = ProtoMessage:newDebugDrawRotator(),
    show_time = nil,
    thickness = nil
  }
end

function ProtoMessage:newDebugDrawCapsuleData()
  return {
    center = ProtoMessage:newPosition(),
    half_height = nil,
    radius = nil,
    rotator = ProtoMessage:newDebugDrawRotator(),
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil
  }
end

function ProtoMessage:newDebugDrawMeshData()
  return {
    verts = {},
    indices = {},
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil
  }
end

function ProtoMessage:newDebugDrawWireFrame()
  return {
    start_pos = ProtoMessage:newPosition(),
    end_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newDebugDrawWireFrameData()
  return {
    lines = {},
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil,
    arrow_size = nil
  }
end

function ProtoMessage:newDebugDrawPointSetData()
  return {
    verts = {},
    point_size = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil
  }
end

function ProtoMessage:newNavMeshDebugDraw()
  return {
    tiles = {}
  }
end

function ProtoMessage:newNavMeshBoundary()
  return {
    begin_pos = ProtoMessage:newPosition(),
    end_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newNavMeshPoly()
  return {
    flag = nil,
    color = ProtoMessage:newDebugDrawColor(),
    verts = {}
  }
end

function ProtoMessage:newNavMeshTile()
  return {
    polys = {},
    inner_boundaries = {},
    inner_color = ProtoMessage:newDebugDrawColor(),
    outer_boundaries = {},
    outer_color = ProtoMessage:newDebugDrawColor()
  }
end

function ProtoMessage:newDebugDrawNavMeshData()
  return {
    raw_data = ProtoMessage:newNavMeshDebugDraw(),
    inner_line_thickness = nil,
    outer_line_thickness = nil,
    show_time = nil
  }
end

function ProtoMessage:newDebugDrawCylinderData()
  return {
    center_pos = ProtoMessage:newPosition(),
    half_height = nil,
    radius = nil,
    segments = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil
  }
end

function ProtoMessage:newDebugDrawCircleData()
  return {
    center_pos = ProtoMessage:newPosition(),
    radius = nil,
    segments = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil,
    thickness = nil
  }
end

function ProtoMessage:newDebugDrawTextData()
  return {
    pos = ProtoMessage:newPosition(),
    text = nil,
    color = ProtoMessage:newDebugDrawColor(),
    show_time = nil
  }
end

function ProtoMessage:newSceneGmDebugDrawCall()
  return {
    type = ProtoEnum.DEBUG_DRAW_CALL_TYPE.POINT,
    point_data = ProtoMessage:newDebugDrawPointData(),
    line_data = ProtoMessage:newDebugDrawLineData(),
    sphere_data = ProtoMessage:newDebugDrawSphereData(),
    box_data = ProtoMessage:newDebugDrawBoxData(),
    capsule_data = ProtoMessage:newDebugDrawCapsuleData(),
    mesh_data = ProtoMessage:newDebugDrawMeshData(),
    wire_frame_data = ProtoMessage:newDebugDrawWireFrameData(),
    point_set_data = ProtoMessage:newDebugDrawPointSetData(),
    nav_mesh_data = ProtoMessage:newDebugDrawNavMeshData(),
    cylinder_data = ProtoMessage:newDebugDrawCylinderData(),
    circle_data = ProtoMessage:newDebugDrawCircleData(),
    text_data = ProtoMessage:newDebugDrawTextData()
  }
end

function ProtoMessage:newZoneSceneGmDebugDrawCall()
  return {
    draws = {}
  }
end

function ProtoMessage:newClientAiCommandInfo()
  return {
    actor_id = nil,
    action_id = nil,
    pos = ProtoMessage:newPosition(),
    command_param = nil,
    string_param = nil
  }
end

function ProtoMessage:newSceneAiReportInfo()
  return {
    npc_obj_id = nil,
    report_type = nil,
    ai_seq_id = nil,
    client_point = ProtoMessage:newPoint(),
    attack_obj_id = nil,
    dialog_id = nil
  }
end

function ProtoMessage:newLLM_PETS_FollowPetInfo()
  return {
    npc_actor_id = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newLLM_PETS_BehaviorReportInfo()
  return {npc_actor_id = nil, succ = nil}
end

function ProtoMessage:newAvatarAbnormalStatusInfo()
  return {abnormal_status_id = nil, abnormal_status_duration = nil}
end

function ProtoMessage:newDotsLabelTag()
  return {type = nil, value = nil}
end

function ProtoMessage:newDotsLabelMeshGrid()
  return {
    x = nil,
    y = nil,
    tag_list = {}
  }
end

function ProtoMessage:newDotsLabelTile()
  return {
    x = nil,
    y = nil,
    grid_list = {}
  }
end

function ProtoMessage:newDotsLabelExport()
  return {
    tile_x = nil,
    tile_y = nil,
    tile_list = {}
  }
end

function ProtoMessage:newEnvInfoCell()
  return {
    z = nil,
    tag_list = {}
  }
end

function ProtoMessage:newEnvInfoGrid()
  return {
    cell_list = {}
  }
end

function ProtoMessage:newEnvInfoTile()
  return {
    x = nil,
    y = nil,
    grid_list = {}
  }
end

function ProtoMessage:newEnvInfo()
  return {
    tile_list = {}
  }
end

function ProtoMessage:newMOBA_RET()
  return {}
end

function ProtoMessage:newZoneFeedCtrlData()
  return {
    uin = nil,
    last_attitude_timestamp = nil,
    last_magic_feed_timestamp = nil,
    today_magic_feed_count = nil,
    last_flower_feed_timestamp = nil,
    today_flower_feed_count = nil,
    daily_magic_feed_count = nil,
    video_upload_info = ProtoMessage:newFeedVideoUploadInfo()
  }
end

function ProtoMessage:newZoneMagicFeedInfo()
  return {
    feed_id = nil,
    uin = nil,
    name = nil,
    create_timestamp = nil,
    expire_timestamp = nil,
    comment_num = nil,
    attitude_like_num = nil,
    attitude_hug_num = nil,
    attitude_inspiration_num = nil,
    attitude_perplexity_num = nil,
    content = nil,
    create_pos = ProtoMessage:newPosition(),
    card_icon_selected = nil,
    attitude = nil,
    grid_id = nil,
    ext_info = nil,
    category = nil,
    music_id = nil,
    sub_type = nil
  }
end

function ProtoMessage:newZoneFlowerFeedInfo()
  return {
    feed_id = nil,
    uin = nil,
    name = nil,
    type = nil,
    create_timestamp = nil,
    expire_timestamp = nil,
    create_pos = ProtoMessage:newPosition(),
    grid_id = nil,
    ext_info = nil,
    category = nil
  }
end

function ProtoMessage:newGridFeedDetailInfo()
  return {
    grid_id = nil,
    magic_feeds = {},
    flower_feeds = {},
    my_magic_feeds = {},
    system_magic_feeds = {},
    magic_videos = {},
    my_magic_videos = {}
  }
end

function ProtoMessage:newFeedDetailNotifyData()
  return {
    grid_feed_list = {},
    grid_id = nil,
    grid_list = {}
  }
end

function ProtoMessage:newFeedCommentInfo()
  return {
    feedback_id = nil,
    uin = nil,
    name = nil,
    create_timestamp = nil,
    comment = nil,
    good_num = nil,
    bad_num = nil,
    card_icon_selected = nil,
    comment_attitude = nil
  }
end

function ProtoMessage:newFeedCommentListData()
  return {
    feed_id = nil,
    page_num = nil,
    comment_list = {}
  }
end

function ProtoMessage:newFeedVideoBaseInfo()
  return {
    fashion_id = {},
    pet_base_id = {},
    chat_msg = {},
    player_pos = ProtoMessage:newPosition(),
    version = nil
  }
end

function ProtoMessage:newFeedVideoInfo()
  return {
    file_name = nil,
    file_url = nil,
    file_md5 = nil,
    base_info_md5 = nil
  }
end

function ProtoMessage:newFileUploadInfo()
  return {
    file_name = nil,
    upload_timestamp = nil,
    expire_timestamp = nil,
    create_pos = ProtoMessage:newPosition(),
    content = nil,
    upload_url = nil
  }
end

function ProtoMessage:newFeedVideoUploadInfo()
  return {
    file_list = {},
    expired_file_list = {}
  }
end

function ProtoMessage:newFriendHomeInfo()
  return {
    home_name = nil,
    home_experience = nil,
    home_level = nil,
    room_level = nil,
    home_comfort_level = nil,
    home_pet_can_steal = nil,
    home_plant_can_pick = nil,
    home_pets = {},
    craftable_furniture = ProtoMessage:newCraftableFurnitureList()
  }
end

function ProtoMessage:newFriendRoleInfo()
  return {
    openid = nil,
    uin = nil,
    name = nil,
    note = nil,
    head_img = nil,
    level = nil,
    online = nil,
    gender = nil,
    last_logout_time = nil,
    signature = nil,
    world_level = nil,
    send_visit_apply_time = nil,
    card_skin_selected = nil,
    regist_date = nil,
    source = ProtoEnum.FriendSource.FRIEND_SOURCE_NONE,
    card_icon_selected = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil,
    card_handbook_collect_num = nil,
    card_music_id = nil,
    battle_brief_info = ProtoMessage:newPlayerBattleBriefInfo(),
    home_info = ProtoMessage:newFriendHomeInfo(),
    add_friend_time = nil,
    pinned_time = nil,
    bp_gift_grade = ProtoEnum.BattlePassGiftGrade.BPGG_FREE,
    card_bussiness_card_url = nil,
    friend_type = nil,
    plat_nick_name = nil,
    start_up_privilege_info = ProtoMessage:newPlayerStartUpPrivilegeInfo(),
    cli_login_channel = nil,
    is_chat_node_unlock = nil,
    unlocked_rel_node_num = nil,
    pos_info = ProtoMessage:newFriendPositionInfo(),
    visit_info = ProtoMessage:newFriendVisitInfo(),
    tags = {}
  }
end

function ProtoMessage:newFriendRoleHomeExtInfo()
  return {
    home_pet_can_steal = nil,
    home_plant_can_pick = nil,
    search_ret = nil
  }
end

function ProtoMessage:newFriendRoleExtInfo()
  return {
    uin = nil,
    home_ext_info = ProtoMessage:newFriendRoleHomeExtInfo(),
    search_ret = nil
  }
end

function ProtoMessage:newFriendRequestInfo()
  return {
    openid = nil,
    uin = nil,
    name = nil,
    head_img = nil,
    level = nil,
    world_level = nil,
    online = nil,
    gender = nil,
    signature = nil,
    req_time = nil,
    card_info = ProtoMessage:newPlayerCardBriefInfo(),
    regist_date = nil,
    source = ProtoEnum.FriendSource.FRIEND_SOURCE_NONE
  }
end

function ProtoMessage:newBlackListRoleInfo()
  return {
    openid = nil,
    uin = nil,
    name = nil,
    head_img = nil,
    level = nil,
    online = nil,
    gender = nil,
    signature = nil,
    block_time = nil,
    card_info = ProtoMessage:newPlayerCardBriefInfo(),
    regist_date = nil
  }
end

function ProtoMessage:newHostInfo()
  return {
    host_ip = nil,
    host_port = nil,
    bus_id = nil,
    host_name = nil
  }
end

function ProtoMessage:newGameSetting()
  return {
    game_mode = nil,
    room_create_type = nil,
    arena_id = nil,
    inlet_id = nil,
    arean_buff_id = nil
  }
end

function ProtoMessage:newGameInitInfo()
  return {
    game_id = nil,
    random_seed = nil,
    frame_rate = nil,
    start_time = nil,
    end_time = nil,
    host_info = ProtoMessage:newHostInfo(),
    voip_id = nil,
    ai_hosting_host_list = {},
    room_id = nil
  }
end

function ProtoMessage:newChampionInfo()
  return {
    skin_id1 = nil,
    skin_id2 = nil,
    skin_id3 = nil,
    skin_id4 = nil,
    skin_id5 = nil,
    skin_id6 = nil,
    skin_id7 = nil,
    skin_id8 = nil
  }
end

function ProtoMessage:newSummonerInfo()
  return {
    skin_list = {},
    recently_used_champion = nil,
    recently_joined_team = nil
  }
end

function ProtoMessage:newAiSetting()
  return {
    ai_level = nil,
    salary_rate = nil,
    style = nil,
    aicharacter = nil,
    ai_message = nil,
    atktower_rate = nil,
    atkhero_rate = nil,
    atkplayer_rate = nil,
    atkcreep_rate = nil,
    playerrun_rate = nil,
    otherrun_rate = nil,
    idle_rate = nil,
    randommove_rate = nil
  }
end

function ProtoMessage:newAiChampionSetting()
  return {
    champion_id = nil,
    ai_setting = ProtoMessage:newAiSetting()
  }
end

function ProtoMessage:newAiSettingList()
  return {
    ai_list = {}
  }
end

function ProtoMessage:newPbExtendInfo()
  return {
    clan_battle_times = nil,
    clan_score = nil,
    chosed_title_id = nil,
    clan_logo = nil,
    clan_name = nil,
    chosed_title_extend_info = ProtoMessage:newPlayerTitleExtendInfo(),
    rate_level = nil
  }
end

function ProtoMessage:newPbExtendSvrInfo()
  return {reserve_1 = nil}
end

function ProtoMessage:newFrameData()
  return {frame_id = nil, data = nil}
end

function ProtoMessage:newFrameDataList()
  return {
    frame_list = {}
  }
end

function ProtoMessage:newGamePlayerDiagnosisInfo()
  return {
    uin = nil,
    hang_time = nil,
    offline_time = nil,
    rtt_delay_max = nil,
    rtt_delay_avg = nil,
    disconnected_count = nil
  }
end

function ProtoMessage:newGamePlayerDiagnosisList()
  return {
    diagnosis_list = {}
  }
end

function ProtoMessage:newMailUserData()
  return {}
end

function ProtoMessage:newMailExcelHistory()
  return {
    history = {}
  }
end

function ProtoMessage:newMailSrc()
  return {
    uin = nil,
    name = nil,
    oss_reason = ProtoMessage:newOssReason(),
    has_jump = nil
  }
end

function ProtoMessage:newMailInfo()
  return {
    mail_gid = nil,
    src = ProtoMessage:newMailSrc(),
    title = nil,
    contents = nil,
    add_time = nil,
    expire_time = nil,
    recv_status = ProtoEnum.MailRecvStatusType.MAIL_RECV_STATUS_NO,
    mail_status = ProtoEnum.MailStatusType.MAIL_STATUS_UNREAD,
    mail_conf_id = nil,
    params = ProtoMessage:newMailParamList(),
    reward = ProtoMessage:newGoodsReward(),
    use_svr_data = nil,
    plat_type = nil,
    cond_type = nil,
    reward_id = nil,
    guard_id = nil,
    mail_serial_num = nil,
    mail_sub_type = nil
  }
end

function ProtoMessage:newMailInfoList()
  return {
    uin = nil,
    mails = {},
    byte_mails = {}
  }
end

function ProtoMessage:newIdipInfo()
  return {source = nil, serial = nil}
end

function ProtoMessage:newMailNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_info_no_use = ProtoMessage:newMailInfo(),
    mail_list = ProtoMessage:newMailInfoList()
  }
end

function ProtoMessage:newAreaMailInfo()
  return {
    uid = nil,
    send_time = nil,
    mail_recv_brief = ProtoMessage:newMailRecvBrief()
  }
end

function ProtoMessage:newEventRspData()
  return {
    p1_player_type = ProtoEnum.PlayerType.model,
    p2_player_type = ProtoEnum.PlayerType.model
  }
end

function ProtoMessage:newAIModelWarmControl()
  return {
    warm_control_enable = nil,
    warm_control_restraint_pet = nil,
    warm_control_attack_ratio = nil,
    warm_action_probs_threshold = nil,
    warm_control_energy_thr = nil,
    warm_control_attack_thr = nil,
    warm_control_hurt_thr = nil
  }
end

function ProtoMessage:newAgentStartReqData()
  return {
    ai_type = nil,
    game_settings_path = nil,
    model_path = nil,
    warm_control = ProtoMessage:newAIModelWarmControl()
  }
end

function ProtoMessage:newBattleExtraRoleInfo()
  return {
    op_history = ProtoMessage:newBattleOpHistory(),
    skill_results = nil
  }
end

function ProtoMessage:newExtraBattleStateInfo()
  return {
    request_actions = {},
    player_team = ProtoMessage:newBattleExtraRoleInfo(),
    enemy_team = ProtoMessage:newBattleExtraRoleInfo()
  }
end

function ProtoMessage:newUpdateReqData()
  return {
    battle_state_info = ProtoMessage:newBattleStateInfo(),
    extra_battle_state_info = ProtoMessage:newExtraBattleStateInfo()
  }
end

function ProtoMessage:newPetStartArg()
  return {
    pet_id = nil,
    blood_id = nil,
    skills = {},
    enter_index = nil,
    nature = nil,
    height = nil,
    weight = nil,
    gender = nil,
    breakthrough_cnt = nil,
    hp_max_talent = nil,
    phy_attack_talent = nil,
    spe_attack_talent = nil,
    phy_defence_talent = nil,
    spe_defence_talent = nil,
    speed_talent = nil
  }
end

function ProtoMessage:newStartArg()
  return {
    pets = {},
    magic_skills = {}
  }
end

function ProtoMessage:newPVEStartArg()
  return {pve_battle_id = nil, player_level = nil}
end

function ProtoMessage:newBattleStartArg()
  return {
    start_battle_type = nil,
    pve_start_arg = ProtoMessage:newPVEStartArg(),
    player_type = ProtoEnum.PlayerType.model,
    is_main_agent = nil,
    start_arg_num_pets = nil
  }
end

function ProtoMessage:newUpdateRspData()
  return {
    action = ProtoEnum.InputAction.cast_skill,
    arg = nil,
    start_args = ProtoMessage:newStartArg(),
    battle_start_arg = ProtoMessage:newBattleStartArg()
  }
end

function ProtoMessage:newBattleStats()
  return {
    battle_role_hp = nil,
    pet_ids = {},
    pet_isalive = {},
    num_restraint = nil,
    num_berestraint = nil,
    num_resist = nil,
    num_beresist = nil,
    num_counter = nil,
    num_becounter = nil,
    total_damage_hp = {},
    total_bedamage_hp = {},
    extra_energy_buffs = {},
    extra_energy_buff_sum = {},
    extra_energy_debuffs = {},
    extra_energy_debuff_sum = {},
    num_in_battle = {}
  }
end

function ProtoMessage:newAgentEndData()
  return {
    battle_result = ProtoEnum.BattleResult.Win,
    stats = ProtoMessage:newBattleStats(),
    start_args = ProtoMessage:newStartArg(),
    battle_start_arg = ProtoMessage:newBattleStartArg()
  }
end

function ProtoMessage:newZoneSceneReviveTeleportNotify()
  return {teleport_id = nil, teleport_reason = nil}
end

function ProtoMessage:newZoneSceneStaminaChangeNotify()
  return {
    change_reason = ProtoEnum.STAMINA_CHANGE_REASON.SCR_NONE,
    stamina_change = nil,
    ban_stamina = nil
  }
end

function ProtoMessage:newZoneSceneMovePathCheckNotify()
  return {}
end

function ProtoMessage:newZoneSceneBossChallengeFailNotify()
  return {teleport_reason = nil}
end

function ProtoMessage:newZoneSceneRelationInteractNotify()
  return {
    notify_type = ProtoEnum.RELATION_INTERACT_NOTIFY_TYPE.RINT_NONE,
    target_uin = nil,
    interact_type = nil,
    interact_param = ProtoMessage:newInteractParam(),
    uin1 = nil,
    uin2 = nil,
    interact_sub_type = nil,
    notify_reason = ProtoEnum.RELATION_INTERACT_NOTIFY_REASON.RINR_NONE
  }
end

function ProtoMessage:newZoneSceneFriendRideNotify()
  return {
    friend_uin = nil,
    pet_gid = nil,
    reason = ProtoEnum.FRIEND_NOTIFY_REASON.FNR_NONE
  }
end

function ProtoMessage:newZoneSceneCommonTipsNotify()
  return {
    localization_id = nil,
    source = ProtoEnum.CommonTipsSource.CTS_COMBINE_NPC,
    param_list = {}
  }
end

function ProtoMessage:newSpaceActionType()
  return {}
end

function ProtoMessage:newSpaceAct_ActorEnter()
  return {
    actors = {}
  }
end

function ProtoMessage:newSpaceAct_ActorLeave()
  return {
    actor_ids = {}
  }
end

function ProtoMessage:newSpaceAct_ActorNum()
  return {
    pos = ProtoMessage:newPosition(),
    total_num = nil,
    view_num = nil,
    total_advance_npc_num = nil,
    min_weight = nil
  }
end

function ProtoMessage:newSpaceAct_PlayAnimBeforeRemove()
  return {actor_id = nil}
end

function ProtoMessage:newSpaceAct_ClientMove()
  return {
    actor_id = nil,
    time_stamp = nil,
    to_pos = ProtoMessage:newPosition(),
    to_rot = ProtoMessage:newPosition(),
    speed = ProtoMessage:newPosition(),
    acceleration = ProtoMessage:newPosition(),
    move_mode = nil,
    custom_mode = nil,
    stop_move = nil,
    ctrl_rot = ProtoMessage:newPosition(),
    ride_move = nil,
    mate_point = ProtoMessage:newPoint(),
    mate_move_mode = nil
  }
end

function ProtoMessage:newSpaceAct_ServerMove()
  return {
    actor_id = nil,
    move_mode = nil,
    to_time_list = {},
    to_pos_list = {},
    to_dir_list = {},
    move_sub_mode = nil,
    height = nil,
    height_lerp_rate = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    accept_radius = nil,
    is_backward = nil
  }
end

function ProtoMessage:newSpaceAct_ServerFly()
  return {
    actor_id = nil,
    cur_dir = ProtoMessage:newPosition(),
    cur_pos = ProtoMessage:newPosition(),
    ctrl_pos1 = ProtoMessage:newPosition(),
    ctrl_pos2 = ProtoMessage:newPosition(),
    anchor_pos = ProtoMessage:newPosition(),
    split_num = nil,
    fly_speed = nil,
    to_pos_list = {},
    end_time = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    to_timestamp_list = {}
  }
end

function ProtoMessage:newSpaceAct_InterruptServerMove()
  return {
    actor_id = nil,
    interrupt_reason = nil,
    interrupt_point = ProtoMessage:newPoint(),
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_SetNpcPos()
  return {
    actor_id = nil,
    to_pos = ProtoMessage:newPosition(),
    to_dir = ProtoMessage:newPosition(),
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    reason = ProtoEnum.SpaceAct_SetNpcPosReason.SNPR_NONE
  }
end

function ProtoMessage:newSpaceAct_ServerAttach()
  return {
    actor_id = nil,
    attach_pos = ProtoMessage:newPosition(),
    attach_dir = ProtoMessage:newPosition(),
    move_speed = nil,
    rotate_speed = nil,
    allow_rotate = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_CancelServerAttach()
  return {
    actor_id = nil,
    cancel_point = ProtoMessage:newPoint(),
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_ServerAIJump()
  return {
    actor_id = nil,
    jump_pos = ProtoMessage:newPosition(),
    max_height = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    begin_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_CancelServerAIJump()
  return {
    actor_id = nil,
    cancel_point = ProtoMessage:newPoint(),
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_StickTo()
  return {
    actor_id = nil,
    target_actor_id = nil,
    self_socket = nil,
    target_socket = nil,
    stick_speed = nil,
    stick_anim = nil,
    rotate = ProtoMessage:newPosition(),
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    translate = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_FinishStickTo()
  return {
    actor_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_AIMoveMode()
  return {
    actor_id = nil,
    move_mode = ProtoMessage:newActorInfo_AIMoveMode()
  }
end

function ProtoMessage:newSpaceAct_AITryInteractNpc()
  return {
    actor_id = nil,
    interact_actor_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_SwitchBossAINty()
  return {actor_id = nil, is_server_ai = nil}
end

function ProtoMessage:newSpaceAct_InformClientSwitchAINty()
  return {npc_type = nil}
end

function ProtoMessage:newSpaceAct_ClientSwitchToServerAINty()
  return {
    actor_list = {}
  }
end

function ProtoMessage:newSpaceAct_AIMutualPerformStateChanged()
  return {
    mutual_changed_list = {}
  }
end

function ProtoMessage:newSpaceAct_PlayVoice()
  return {
    actor_id = nil,
    voice_id = nil,
    voice_speed = nil,
    start_pos = nil,
    loop_count = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    high_priority = nil
  }
end

function ProtoMessage:newSpaceAct_StopVoice()
  return {
    actor_id = nil,
    voice_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_AddStoryFlags()
  return {
    actor_id = nil,
    option_id = nil,
    story_flags = {},
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_RemoveStoryFlags()
  return {
    actor_id = nil,
    option_id = nil,
    story_flags = {},
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_OptionBlackOrWhiteListUinsChgNtf()
  return {
    option_id = nil,
    whitelist_uins = {},
    blacklist_uins = {},
    npc_id = nil
  }
end

function ProtoMessage:newSpaceAct_NpcOptionInfoChange()
  return {
    npc_id = nil,
    option_id = nil,
    enabled = nil,
    executable_times = nil,
    act_info = ProtoMessage:newActorInfo_NpcActionInfo(),
    enable_opt_gid = nil,
    succ_exec_times = nil,
    first_dialog_id = nil,
    avatar_id = nil,
    ineteracting_avatar_id = nil,
    is_cancel = nil
  }
end

function ProtoMessage:newSpaceAct_BeginActResultParamsNty()
  return {
    npc_id = nil,
    option_id = nil,
    act_type = nil,
    act_result_params = {},
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_NpcCanbeTeleportNty()
  return {npc_id = nil, can_be_teleport = nil}
end

function ProtoMessage:newSpaceAct_FollowInfoChangedNty()
  return {
    follow_id = nil,
    task_id = nil,
    old_state = nil,
    new_state = nil,
    conf_id = nil
  }
end

function ProtoMessage:newSpaceAct_PositionInvalid()
  return {}
end

function ProtoMessage:newSpaceAct_NpcOptionAddSelects()
  return {
    npc_id = nil,
    option_id = nil,
    select_infos = {},
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_NpcOptionRemoveSelects()
  return {
    npc_id = nil,
    option_id = nil,
    select_ids = {},
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_NpcDialogSelectInfoChange()
  return {
    npc_id = nil,
    option_id = nil,
    select_info = ProtoMessage:newActorInfo_NpcDialogSelectInfo(),
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_AddNpcOption()
  return {
    npc_id = nil,
    opt_info = ProtoMessage:newActorInfo_NpcOptionInfo(),
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_RemoveNpcOption()
  return {
    npc_id = nil,
    option_id = nil,
    avatar_id = nil
  }
end

function ProtoMessage:newSpaceAct_UpdateActorLogicStatus()
  return {
    actor_id = nil,
    change_info = {}
  }
end

function ProtoMessage:newLogicStatusChangeInfo()
  return {
    op_type = nil,
    changed_status = ProtoMessage:newActorInfo_LogicStatus()
  }
end

function ProtoMessage:newSpaceAct_TrackingNpc()
  return {
    tracking_list = {}
  }
end

function ProtoMessage:newSpaceAct_NpcDistribution()
  return {
    distribution = {}
  }
end

function ProtoMessage:newSpaceAct_ChangeLoopAction()
  return {actor_id = nil, new_loop_action = nil}
end

function ProtoMessage:newSpaceAct_VisibleZone()
  return {
    enter = ProtoMessage:newEnterVisible(),
    leave = ProtoMessage:newLeaveVisible(),
    actor_id = nil
  }
end

function ProtoMessage:newVisiblePlayer()
  return {
    id = nil,
    name = nil,
    in_visible = nil
  }
end

function ProtoMessage:newVisiblePool()
  return {
    area_cfg_id = nil,
    pool_id = nil,
    players = {},
    cell_id_str = nil
  }
end

function ProtoMessage:newEnterVisible()
  return {
    entrant_name = nil,
    pool = ProtoMessage:newVisiblePool()
  }
end

function ProtoMessage:newLeaveVisible()
  return {
    leaver_name = nil,
    merge = nil,
    pool = ProtoMessage:newVisiblePool(),
    recycle = nil
  }
end

function ProtoMessage:newSpaceAct_VisibleCircle()
  return {
    uin = nil,
    enter = ProtoMessage:newEnterVisibleCircle(),
    leave = ProtoMessage:newLeaveVisibleCircle()
  }
end

function ProtoMessage:newCircleMember()
  return {uin = nil, name = nil}
end

function ProtoMessage:newVisibleCircle()
  return {
    circle_id = nil,
    members = {}
  }
end

function ProtoMessage:newEnterVisibleCircle()
  return {
    name = nil,
    circle = ProtoMessage:newVisibleCircle()
  }
end

function ProtoMessage:newLeaveVisibleCircle()
  return {
    name = nil,
    circle = ProtoMessage:newVisibleCircle()
  }
end

function ProtoMessage:newSpaceAct_AvatarStoryFlags()
  return {
    story_flags = {},
    visit_owner_story_flags = {}
  }
end

function ProtoMessage:newSpaceAct_CombineLockStateChange()
  return {
    actor_id = nil,
    unlocked_num = nil,
    tot_lock_num = nil,
    cond_npc_infos = {}
  }
end

function ProtoMessage:newSpaceAct_NpcGuideChange()
  return {
    actor_id = nil,
    guide_info = ProtoMessage:newNpcGuideInfo(),
    add_or_delete = nil
  }
end

function ProtoMessage:newSpaceAct_MagicCreateNpcChange()
  return {
    actor_id = nil,
    npc_info = ProtoMessage:newMagicCreateNpcInfo(),
    add_or_delete = nil
  }
end

function ProtoMessage:newSpaceAct_CatchGuaranteeChange()
  return {
    actor_id = nil,
    catch_guarantee_rate = nil,
    last_catch_time = nil
  }
end

function ProtoMessage:newSpaceAct_PlayerMatch()
  return {
    match_type = nil,
    caster_uin = nil,
    start_or_cancel = nil,
    cast_time = nil,
    select_hard = nil,
    battle_cfg_id = nil
  }
end

function ProtoMessage:newSpaceAct_NpcVisualInfoChange()
  return {
    actor_id = nil,
    cannot_be_seen = nil,
    change_reason = ProtoEnum.VisualInfoChangeReason.VICT_CONFIG,
    npc_hide_flag = nil
  }
end

function ProtoMessage:newSpaceAct_PotentialEnergyChange()
  return {
    actor_id = nil,
    potential_energ_info = ProtoMessage:newActorInfo_PotentialEnergy()
  }
end

function ProtoMessage:newSpaceAct_PropertyTypeChange()
  return {
    actor_id = nil,
    property_type_info = ProtoMessage:newActorInfo_PropertyType()
  }
end

function ProtoMessage:newSpaceAct_AuraInfoChange()
  return {
    actor_id = nil,
    aura_info = {},
    removed_auras = {}
  }
end

function ProtoMessage:newSpaceAct_BodyTempNotify()
  return {
    actor_id = nil,
    body_temp_final_val = nil,
    reach_final_time = nil,
    nature_temp = nil
  }
end

function ProtoMessage:newSpaceAct_ActorBornEnd()
  return {actor_id = nil, cur_time = nil}
end

function ProtoMessage:newSpaceAct_ActorDieBegin()
  return {
    actor_id = nil,
    cur_time = nil,
    skill_or_anim = nil,
    is_skill = nil,
    play_time = nil,
    die_reason = nil,
    killer = nil,
    dir = ProtoMessage:newPosition(),
    die_reason_params = {},
    die_reason_params_64 = {}
  }
end

function ProtoMessage:newSpaceAct_BeginDropItem()
  return {
    src_npc_id = nil,
    src_npc_pos = ProtoMessage:newPosition(),
    src_npc_cfg_id = nil,
    src_npc_ref_cfg_id = nil,
    batch_num = nil,
    drop_itme_num = nil,
    drop_item_refresh_source = nil
  }
end

function ProtoMessage:newSpaceAct_EndDropItem()
  return {
    src_npc_id = nil,
    src_npc_pos = ProtoMessage:newPosition(),
    src_npc_cfg_id = nil,
    src_npc_ref_cfg_id = nil,
    batch_num = nil
  }
end

function ProtoMessage:newSpaceAct_AttrChange()
  return {
    actor_id = nil,
    attrs = {}
  }
end

function ProtoMessage:newSpaceAct_EnteredCatcher()
  return {
    actor_id = nil,
    entered_area_id = nil,
    area_func_conf_id = nil,
    area_camp_unlock = nil
  }
end

function ProtoMessage:newSpaceAct_LeftCatcher()
  return {
    actor_id = nil,
    left_area_id = nil,
    area_func_conf_id = nil
  }
end

function ProtoMessage:newSpaceAct_CastSceneSkill()
  return {
    caster_id = nil,
    time_stamp = nil,
    skill_id = nil,
    skill_status_type = nil,
    is_add_status = nil
  }
end

function ProtoMessage:newSpaceAct_FriendRide()
  return {
    friend_ride_data_list = {},
    is_riding = nil,
    friend_ride_info_list = {}
  }
end

function ProtoMessage:newFriendRideInfo()
  return {
    uin = nil,
    gid = nil,
    name = nil
  }
end

function ProtoMessage:newSpaceAct_SyncPlayerStatus()
  return {
    actor_id = nil,
    time_stamp = nil,
    status = nil,
    op_code = nil,
    sub_status = nil,
    status_param = ProtoMessage:newPlayerStatusCustomParams(),
    sync_status_info_list = {}
  }
end

function ProtoMessage:newSpaceAct_LookAt()
  return {
    actor_id = nil,
    target_actor_id = nil,
    target_pos = ProtoMessage:newPosition(),
    enable = nil,
    immediately = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    at_camera = nil
  }
end

function ProtoMessage:newSpaceAct_TurnTo()
  return {
    actor_id = nil,
    turn_pos = ProtoMessage:newPosition(),
    turn_speed = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    use_anim_length = nil,
    anim_speed_scale = nil
  }
end

function ProtoMessage:newSpaceAct_CancelTurnTo()
  return {
    actor_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_ShowPetFaceState()
  return {
    actor_id = nil,
    show = nil,
    face_state = nil,
    progress = nil
  }
end

function ProtoMessage:newSpaceAct_PlayAnimation()
  return {
    actor_id = nil,
    anim_id = nil,
    play_rate = nil,
    start_pos = nil,
    blend_in_time = nil,
    blend_out_time = nil,
    loop_count = nil,
    cur_time = nil,
    override_move = nil,
    movement_mode = nil,
    voice_speed = nil,
    mute = nil,
    pause_on_end = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    actor_dir = ProtoMessage:newPosition(),
    is_rootmotion = nil,
    high_priority = nil
  }
end

function ProtoMessage:newSpaceAct_StopAnimation()
  return {
    actor_id = nil,
    anim_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_AnimPauseOrResume()
  return {
    actor_id = nil,
    is_anim_pause = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_PlaySkill()
  return {
    actor_id = nil,
    skill_path = nil,
    cur_time = nil,
    skill_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    target_id = nil,
    target_is_npc = nil,
    use_specific_pos = nil,
    specific_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_StopSkill()
  return {
    actor_id = nil,
    skill_path = nil,
    cur_time = nil,
    skill_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldHidden()
  return {
    actor_id = nil,
    target_actor_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldUnHidden()
  return {
    actor_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_ModelDisplay()
  return {
    actor_id = nil,
    is_fade_out = nil,
    time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_PlayPerceptionEffect()
  return {
    actor_id = nil,
    effect_id = nil,
    time_stamp = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_PlayPerceptionHud()
  return {
    actor_id = nil,
    hud_type = nil,
    time_stamp = nil,
    is_show = nil,
    target_actor_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    local_player_obj_id = nil,
    show_range = nil
  }
end

function ProtoMessage:newSpaceAct_NpcPerceivePlayer()
  return {
    actor_id = nil,
    time_stamp = nil,
    is_perceive = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_NpcTrace()
  return {
    npc_trace_info = ProtoMessage:newNpcTraceInfo()
  }
end

function ProtoMessage:newSpaceAct_BattleOnOff()
  return {
    actor_id = nil,
    on_or_off = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldAttack()
  return {
    actor_id = nil,
    aim_type = nil,
    attack_type = nil,
    range = nil,
    predict = nil,
    damage = nil,
    hit_strength = nil,
    is_heavy = nil,
    time_stamp = nil,
    target_actor_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    use_specific_pos = nil,
    specific_pos = ProtoMessage:newPosition(),
    hit_perform_type = ProtoEnum.PlayerAttackPerformType.PAPT_Light,
    abnormal_type = nil,
    abnormal_duration = nil
  }
end

function ProtoMessage:newSpaceAct_StopWorldAttack()
  return {
    actor_id = nil,
    time_stamp = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_MfbtDebug()
  return {
    actor_id = nil,
    event_datas = {}
  }
end

function ProtoMessage:newSpaceAct_MfbtDebug_InnerEventData()
  return {
    event_type = ProtoEnum.E_SCENE_MFBT_DEBUG_EVENT_TYPE.E_MFBT_TreeAssetCreatedEvent,
    event_data = {}
  }
end

function ProtoMessage:newSpaceAct_LLMDebug()
  return {
    datas = {}
  }
end

function ProtoMessage:newSpaceAct_LLMDebug_InnerData()
  return {spirit_id = nil, str = nil}
end

function ProtoMessage:newSpaceAct_CollisionCancelRecover()
  return {
    actor_id = nil,
    is_collision_cancel = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_EnvMask()
  return {
    actor_id = nil,
    env_mask = nil,
    ban_type = {},
    ban_ride_sockets = {}
  }
end

function ProtoMessage:newSpaceAct_ChangeSceneNotify()
  return {
    scene_cfg_id = nil,
    self_info = ProtoMessage:newActorInfo(),
    other_actors = {}
  }
end

function ProtoMessage:newSpaceAct_WeatherChange()
  return {actor_id = nil, weather = nil}
end

function ProtoMessage:newSpaceAct_HeadLookAt()
  return {
    actor_id = nil,
    look_at_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_ClientOperation()
  return {
    operation = ProtoMessage:newClientOperation()
  }
end

function ProtoMessage:newSpaceAct_BondFind()
  return {
    actor_id = nil,
    target_actor_id = nil,
    target_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_ScenePetInfoChange()
  return {
    actor_id = nil,
    pet_info = ProtoMessage:newActorInfo_ScenePet()
  }
end

function ProtoMessage:newSpaceAct_SceneDotsComponentSync()
  return {
    npc_id = nil,
    component_datas = {}
  }
end

function ProtoMessage:newSpaceAct_PlayZoomAnimation()
  return {
    actor_id = nil,
    anim_id = nil,
    target_pos = ProtoMessage:newPosition(),
    attach_to_top = nil,
    play_rate = nil,
    blend_in_time = nil,
    blend_out_time = nil,
    decreasing_curve = nil,
    loop_anim_name = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_TaskStateChangeNty()
  return {
    actor_id = nil,
    enabled_state_ids = {}
  }
end

function ProtoMessage:newSpaceAct_PlayRealtimeDialog()
  return {
    actor_id = nil,
    dialog_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_StopRealtimeDialog()
  return {
    actor_id = nil,
    cur_time = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_OptActionNtf()
  return {
    action_type = nil,
    npc_id = nil,
    seat_idx = nil,
    leave_point_idx = nil,
    is_client_req_leave_seat = nil,
    before_sit_point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newSpaceAct_RoleplayHoldInfoChgNtf()
  return {
    npc_id = nil,
    slot_idx = nil,
    is_client_req_cancel_hold = nil,
    reason = ProtoEnum.RoleplayHoldInfoChangeReason.RHICR_NONE,
    op_avatar_uin = nil
  }
end

function ProtoMessage:newSpaceAct_HomePetInfoChangeNotify()
  return {
    action_type = nil,
    home_pet = ProtoMessage:newActorInfo_HomePet()
  }
end

function ProtoMessage:newSpaceAct_HomeInteractNotify()
  return {
    interact_type = ProtoEnum.SpaceAct_HomeInteractNotify.InteractType.ACTION_CROSS_DAY_RESET,
    total_steal_num = nil,
    home_pet_gids = {}
  }
end

function ProtoMessage:newSpaceActionCollection()
  return {
    actor_enter = ProtoMessage:newSpaceAct_ActorEnter(),
    actor_leave = ProtoMessage:newSpaceAct_ActorLeave(),
    actor_num = ProtoMessage:newSpaceAct_ActorNum(),
    client_move = ProtoMessage:newSpaceAct_ClientMove(),
    server_move = ProtoMessage:newSpaceAct_ServerMove(),
    interrupt_server_move = ProtoMessage:newSpaceAct_InterruptServerMove(),
    look_at = ProtoMessage:newSpaceAct_LookAt(),
    turn_to = ProtoMessage:newSpaceAct_TurnTo(),
    cancel_turn_to = ProtoMessage:newSpaceAct_CancelTurnTo(),
    server_fly = ProtoMessage:newSpaceAct_ServerFly(),
    server_attach = ProtoMessage:newSpaceAct_ServerAttach(),
    cancel_server_attach = ProtoMessage:newSpaceAct_CancelServerAttach(),
    add_story_flags = ProtoMessage:newSpaceAct_AddStoryFlags(),
    remove_story_flags = ProtoMessage:newSpaceAct_RemoveStoryFlags(),
    npc_option_info_change = ProtoMessage:newSpaceAct_NpcOptionInfoChange(),
    npc_option_add_selects = ProtoMessage:newSpaceAct_NpcOptionAddSelects(),
    npc_option_remove_selects = ProtoMessage:newSpaceAct_NpcOptionRemoveSelects(),
    npc_dialog_select_info_change = ProtoMessage:newSpaceAct_NpcDialogSelectInfoChange(),
    add_npc_option = ProtoMessage:newSpaceAct_AddNpcOption(),
    remove_npc_option = ProtoMessage:newSpaceAct_RemoveNpcOption(),
    begin_act_result_params_nty = ProtoMessage:newSpaceAct_BeginActResultParamsNty(),
    npc_can_be_teleport_nty = ProtoMessage:newSpaceAct_NpcCanbeTeleportNty(),
    update_actor_logic_status = ProtoMessage:newSpaceAct_UpdateActorLogicStatus(),
    combine_lock_state_change = ProtoMessage:newSpaceAct_CombineLockStateChange(),
    tracking_npcs = ProtoMessage:newSpaceAct_TrackingNpc(),
    visible_players = ProtoMessage:newSpaceAct_VisibleZone(),
    sync_player_status = ProtoMessage:newSpaceAct_SyncPlayerStatus(),
    potential_energy_change = ProtoMessage:newSpaceAct_PotentialEnergyChange(),
    env_mask = ProtoMessage:newSpaceAct_EnvMask(),
    property_type_change = ProtoMessage:newSpaceAct_PropertyTypeChange(),
    actor_born_end = ProtoMessage:newSpaceAct_ActorBornEnd(),
    actor_die_begin = ProtoMessage:newSpaceAct_ActorDieBegin(),
    begin_drop_item = ProtoMessage:newSpaceAct_BeginDropItem(),
    end_drop_item = ProtoMessage:newSpaceAct_EndDropItem(),
    attr_change = ProtoMessage:newSpaceAct_AttrChange(),
    enterted_catcher = ProtoMessage:newSpaceAct_EnteredCatcher(),
    left_catcher = ProtoMessage:newSpaceAct_LeftCatcher(),
    play_animation = ProtoMessage:newSpaceAct_PlayAnimation(),
    stop_animation = ProtoMessage:newSpaceAct_StopAnimation(),
    anim_pause_or_resume = ProtoMessage:newSpaceAct_AnimPauseOrResume(),
    play_skill = ProtoMessage:newSpaceAct_PlaySkill(),
    stop_skill = ProtoMessage:newSpaceAct_StopSkill(),
    world_hidden = ProtoMessage:newSpaceAct_WorldHidden(),
    world_unhidden = ProtoMessage:newSpaceAct_WorldUnHidden(),
    play_zoom_animation = ProtoMessage:newSpaceAct_PlayZoomAnimation(),
    play_anim_before_remove = ProtoMessage:newSpaceAct_PlayAnimBeforeRemove(),
    show_pet_face_state = ProtoMessage:newSpaceAct_ShowPetFaceState(),
    model_show_or_hide = ProtoMessage:newSpaceAct_ModelDisplay(),
    play_perception_effect = ProtoMessage:newSpaceAct_PlayPerceptionEffect(),
    play_perception_hud = ProtoMessage:newSpaceAct_PlayPerceptionHud(),
    npc_trace = ProtoMessage:newSpaceAct_NpcTrace(),
    npc_perceive_player = ProtoMessage:newSpaceAct_NpcPerceivePlayer(),
    battle_on_or_off = ProtoMessage:newSpaceAct_BattleOnOff(),
    world_attack = ProtoMessage:newSpaceAct_WorldAttack(),
    stop_world_attack = ProtoMessage:newSpaceAct_StopWorldAttack(),
    mfbt_debug = ProtoMessage:newSpaceAct_MfbtDebug(),
    battle_ai_status_changed = ProtoMessage:newSpaceAct_BattleAIStatusChanged(),
    scene_ai_control_flags_changed = ProtoMessage:newSpaceAct_SceneAiControlFlagsChanged(),
    server_ai_jump = ProtoMessage:newSpaceAct_ServerAIJump(),
    cancel_server_ai_jump = ProtoMessage:newSpaceAct_CancelServerAIJump(),
    stick_to = ProtoMessage:newSpaceAct_StickTo(),
    finish_stick_to = ProtoMessage:newSpaceAct_FinishStickTo(),
    ai_try_interact_npc = ProtoMessage:newSpaceAct_AITryInteractNpc(),
    switch_boss_ai_nty = ProtoMessage:newSpaceAct_SwitchBossAINty(),
    move_mode = ProtoMessage:newSpaceAct_AIMoveMode(),
    inform_client_switch_ai = ProtoMessage:newSpaceAct_InformClientSwitchAINty(),
    client_switch_to_server_ai = ProtoMessage:newSpaceAct_ClientSwitchToServerAINty(),
    mutual_perform_state_changed = ProtoMessage:newSpaceAct_AIMutualPerformStateChanged(),
    cast_scene_skill = ProtoMessage:newSpaceAct_CastSceneSkill(),
    friend_ride = ProtoMessage:newSpaceAct_FriendRide(),
    collision_cancel_or_recover = ProtoMessage:newSpaceAct_CollisionCancelRecover(),
    change_scene_notify = ProtoMessage:newSpaceAct_ChangeSceneNotify(),
    aura_info_change = ProtoMessage:newSpaceAct_AuraInfoChange(),
    body_temp_notify = ProtoMessage:newSpaceAct_BodyTempNotify(),
    throwed_pet_info = ProtoMessage:newSpaceAct_ThrowedPetInfoChange(),
    del_throwing_magic = ProtoMessage:newSpaceAct_DelThrowingMagic(),
    throw_catch_notify = ProtoMessage:newSpaceAct_DeleteThrowNotify(),
    air_wall_change = ProtoMessage:newSpaceAct_AirWallChange(),
    weather_change = ProtoMessage:newSpaceAct_WeatherChange(),
    game_time_change = ProtoMessage:newSpaceAct_GameTimeChange(),
    minigame = ProtoMessage:newSpaceAct_MinigameNotify(),
    guide_npcs = ProtoMessage:newSpaceAct_GuideTask(),
    client_event_resume = ProtoMessage:newSpaceAct_ClientEventResume(),
    npc_pendant_info_change = ProtoMessage:newSpaceAct_NpcPendantInfoChange(),
    unlock_sleeping_owl = ProtoMessage:newSpaceAct_UnlockSleepingOwl(),
    owl_refuge_info_change = ProtoMessage:newSpaceAct_OwlRefugeInfoChange(),
    npc_distribution = ProtoMessage:newSpaceAct_NpcDistribution(),
    head_look_at = ProtoMessage:newSpaceAct_HeadLookAt(),
    fashion_change = ProtoMessage:newSpaceAct_FashionChange(),
    salon_change = ProtoMessage:newSpaceAct_SalonChange(),
    client_operation = ProtoMessage:newSpaceAct_ClientOperation(),
    bond_find = ProtoMessage:newSpaceAct_BondFind(),
    pet_info_change = ProtoMessage:newSpaceAct_ScenePetInfoChange(),
    dots_component_sync = ProtoMessage:newSpaceAct_SceneDotsComponentSync(),
    game_time_sync = ProtoMessage:newSpaceAct_GameTimeSync(),
    pet_interact_res_nty = ProtoMessage:newSpaceAct_PetInteractResNty(),
    combine_interact_info_change = ProtoMessage:newSpaceAct_CombineInteractInfoChange(),
    buff_info_change = ProtoMessage:newSpaceAct_BuffInfoChange(),
    name_change = ProtoMessage:newSpaceAct_NameChange(),
    relate_npc_infos_change = ProtoMessage:newSpaceAct_RelatedNpcInfosChanged(),
    world_map_infos_change = ProtoMessage:newSpaceAct_WorldMapInfoChanged(),
    set_npc_pos = ProtoMessage:newSpaceAct_SetNpcPos(),
    play_voice = ProtoMessage:newSpaceAct_PlayVoice(),
    stop_voice = ProtoMessage:newSpaceAct_StopVoice(),
    npc_guide_change = ProtoMessage:newSpaceAct_NpcGuideChange(),
    loop_action = ProtoMessage:newSpaceAct_ChangeLoopAction(),
    catch_guarantee_change = ProtoMessage:newSpaceAct_CatchGuaranteeChange(),
    player_match = ProtoMessage:newSpaceAct_PlayerMatch(),
    npc_visual_info = ProtoMessage:newSpaceAct_NpcVisualInfoChange(),
    battle_buff_info_change = ProtoMessage:newSpaceAct_BattleBuffInfoChanged(),
    card_label_change = ProtoMessage:newSpaceAct_CardLabelChange(),
    card_skin_change = ProtoMessage:newSpaceAct_CardSkinChange(),
    same_cell_teleport = ProtoMessage:newSpaceAct_SameCellTeleport(),
    follow_info_changed_nty = ProtoMessage:newSpaceAct_FollowInfoChangedNty(),
    collect_handbook_records_change = ProtoMessage:newSpaceAct_CollectHandbookRecordsChange(),
    position_invalid = ProtoMessage:newSpaceAct_PositionInvalid(),
    task_state_change_nty = ProtoMessage:newSpaceAct_TaskStateChangeNty(),
    play_real_time_dialog = ProtoMessage:newSpaceAct_PlayRealtimeDialog(),
    stop_real_time_dialog = ProtoMessage:newSpaceAct_StopRealtimeDialog(),
    card_music_change = ProtoMessage:newSpaceAct_CardMusicChange(),
    magic_create_npc_change = ProtoMessage:newSpaceAct_MagicCreateNpcChange(),
    velocity_oriented_rotation = ProtoMessage:newSpaceAct_VelocityOrientedRotation(),
    world_launch_player = ProtoMessage:newSpaceAct_WorldLaunchPlayer(),
    ai_perform_group_id_changed = ProtoMessage:newSpaceAct_AIPerformGroupIdChanged(),
    opt_action_ntf = ProtoMessage:newSpaceAct_OptActionNtf(),
    card_icon_change = ProtoMessage:newSpaceAct_CardIconChange(),
    video_record = ProtoMessage:newSpaceAct_VideoRecord(),
    stun = ProtoMessage:newSpaceAct_Stun(),
    catch_record_info_change = ProtoMessage:newSpaceAct_CatchRecordInfoChange(),
    habitat_neighbor_info_change = ProtoMessage:newSpaceAct_HabitatNeighborInfoChange(),
    all_habitat_neighbor_info = ProtoMessage:newSpaceAct_AllHabitatNeighborInfo(),
    play_chat_buble = ProtoMessage:newSpaceAct_PlayChatBubble(),
    player_tags_change = ProtoMessage:newSpaceAct_PlayerTagsChange(),
    abnormal_status_change_ntf = ProtoMessage:newSpaceAct_AbnormalStatusChangeNtf(),
    bonus_catch_limit_tips = ProtoMessage:newSpaceAct_BonusCatchLimitTips(),
    world_combat_enter = ProtoMessage:newSpaceAct_WorldCombatEnter(),
    world_combat_exit = ProtoMessage:newSpaceAct_WorldCombatExit(),
    world_combat_text_prompts = ProtoMessage:newSpaceAct_WorldCombatTextPrompts(),
    world_combat_phase_update = ProtoMessage:newSpaceAct_WorldCombatPhaseUpdate(),
    world_combat_begin = ProtoMessage:newSpaceAct_WorldCombatBegin(),
    world_combat_finish = ProtoMessage:newSpaceAct_WorldCombatFinish(),
    world_combat_dots_skill_cast = ProtoMessage:newSpaceAct_WorldCombatDotsSkillCast(),
    world_combat_dots_skill_end = ProtoMessage:newSpaceAct_WorldCombatDotsSkillEnd(),
    world_combat_dots_skill_crush = ProtoMessage:newSpaceAct_WorldCombatDotsSkillCrush(),
    world_combat_dots_skill_hit = ProtoMessage:newSpaceAct_WorldCombatDotsSkillHit(),
    world_combat_dots_skill_rotate = ProtoMessage:newSpaceAct_WorldCombatDotsSkillRotate(),
    world_combat_dots_skill_lookat = ProtoMessage:newSpaceAct_WorldCombatDotsSkillLookAt(),
    world_combat_dots_skill_crush_end = ProtoMessage:newSpaceAct_WorldCombatDotsSkillCrushEnd(),
    world_combat_dots_skill_missile_launch = ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileLaunch(),
    world_combat_dots_skill_missile_destroy = ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileDestroy(),
    world_combat_dots_skill_missile_stop_trace = ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileStopTrace(),
    world_combat_dots_skill_jump = ProtoMessage:newSpaceAct_WorldCombatDotsSkillJump(),
    world_combat_dots_skill_jump_cancel = ProtoMessage:newSpaceAct_WorldCombatDotsSkillJumpCancel(),
    world_combat_dots_skill_rcd = ProtoMessage:newSpaceAct_WorldCombatDotsSkillRcd(),
    world_combat_extra_reward_update = ProtoMessage:newSpaceAct_WorldCombatExtraRewardUpdate(),
    world_combat_dots_skill_select_pos = ProtoMessage:newSpaceAct_WorldCombatDotsSkillSelectPos(),
    owl_sanctuary_detected = ProtoMessage:newSpaceAct_OwlSanctuaryDetected(),
    world_combat_dots_skill_jump_end = ProtoMessage:newSpaceAct_WorldCombatDotsSkillJumpEnd(),
    world_combat_dots_skill_rcd_end = ProtoMessage:newSpaceAct_WorldCombatDotsSkillRcdEnd(),
    world_combat_dots_skill_hidden = ProtoMessage:newSpaceAct_WorldCombatDotsSkillHidden(),
    world_combat_dots_skill_hidden_end = ProtoMessage:newSpaceAct_WorldCombatDotsSkillHiddenEnd(),
    owl_sanctuary_fruit_info_update = ProtoMessage:newSpaceAct_OwlSanctuaryFruitInfoUpdate(),
    scenesvr_err_echo = ProtoMessage:newSpaceAct_SceneSvrErrEcho(),
    world_combat_dots_skill_show_hide = ProtoMessage:newSpaceAct_WorldCombatDotsSkillShowHideChange(),
    world_combat_dots_skill_pos_lerp_sync = ProtoMessage:newSpaceAct_WorldCombatDotsSkillPosLerpSync(),
    world_combat_dots_skill_anim_cancel = ProtoMessage:newSpaceAct_WorldCombatDotsSkillAnimCancel(),
    home_basic_info_change_notify = ProtoMessage:newSpaceAct_HomeBasicInfoChangeNotify(),
    home_pet_info_change_notify = ProtoMessage:newSpaceAct_HomePetInfoChangeNotify(),
    home_plant_change_notify = ProtoMessage:newSpaceAct_HomePlantChangeNotify(),
    home_plant_plant_crop = ProtoMessage:newSpaceAct_HomePlantPlantCrop(),
    home_plant_role_water = ProtoMessage:newSpaceAct_HomePlantRoleWater(),
    home_plant_pet_water = ProtoMessage:newSpaceAct_HomePlantPetWater(),
    home_plant_role_manure = ProtoMessage:newSpaceAct_HomePlantRoleManure(),
    home_plant_pet_manure = ProtoMessage:newSpaceAct_HomePlantPetManure(),
    home_plant_owner_pick = ProtoMessage:newSpaceAct_HomePlantOwnerPick(),
    home_plant_visitor_pick = ProtoMessage:newSpaceAct_HomePlantVisitorPick(),
    home_basic_visitor_enter_home = ProtoMessage:newSpaceAct_HomeBasicVisitorEnterHome(),
    home_basic_visitor_leaving_home = ProtoMessage:newSpaceAct_HomeBasicVisitorLeavingHome(),
    actor_plant_data_update = ProtoMessage:newSpaceAct_ActorPlantDataUpdate(),
    travel_together_sync = ProtoMessage:newSpaceAct_TravelTogetherSync(),
    inner_battle = ProtoMessage:newSpaceAct_InnerBattle(),
    inner_battle_shield_broken = ProtoMessage:newSpaceAct_InnerBattleShieldBroken(),
    inner_battle_change_pet = ProtoMessage:newSpaceAct_InnerBattleChangePet(),
    actor_keep_model = ProtoMessage:newSpaceAct_ActorKeepModel(),
    home_interact_notify = ProtoMessage:newSpaceAct_HomeInteractNotify(),
    pet_closeness_lv_upgrade = ProtoMessage:newSpaceAct_PetClosenessLvUpgrade(),
    camera_flash = ProtoMessage:newSpaceAct_CameraFlash(),
    idle_skill = ProtoMessage:newSpaceAct_IdleSkill(),
    pet_voice = ProtoMessage:newSpaceAct_PetVoice(),
    visible_circle = ProtoMessage:newSpaceAct_VisibleCircle(),
    story_flags = ProtoMessage:newSpaceAct_AvatarStoryFlags(),
    ai_seq_id_notify = ProtoMessage:newSpaceAct_AISeqIdNotify(),
    llm_pets_query_pets = ProtoMessage:newSpaceAct_LLM_PETS_QueryPets(),
    llm_pets_behavior_notify = ProtoMessage:newSpaceAct_LLM_PETS_BehaviorNotify(),
    llm_debug = ProtoMessage:newSpaceAct_LLMDebug(),
    npc_size_scale_change = ProtoMessage:newSpaceAct_NpcSizeScaleChange(),
    camera_skin_change = ProtoMessage:newSpaceAct_CameraSkinChange(),
    npc_mutation_info_change = ProtoMessage:newSpaceAct_NpcMutationInfoChange(),
    roleplay_hold_info_chg_ntf = ProtoMessage:newSpaceAct_RoleplayHoldInfoChgNtf(),
    option_b_or_w_list_uins_chg_ntf = ProtoMessage:newSpaceAct_OptionBlackOrWhiteListUinsChgNtf()
  }
end

function ProtoMessage:newSpaceActionTag_Battle()
  return {
    battle_id = nil,
    round = nil,
    skill_id = nil,
    group_id = nil,
    cast_moment = nil
  }
end

function ProtoMessage:newSpaceActionTag_Actor()
  return {actor_id = nil}
end

function ProtoMessage:newSpaceActionTags()
  return {
    battle_tag = ProtoMessage:newSpaceActionTag_Battle(),
    actor_tag = ProtoMessage:newSpaceActionTag_Actor()
  }
end

function ProtoMessage:newZoneScenePlayActsNotify()
  return {
    acts = {},
    act_tags = ProtoMessage:newSpaceActionTags(),
    space_base_data = ProtoMessage:newSpaceBaseData()
  }
end

function ProtoMessage:newZoneScenePlayActsBatchNotify()
  return {
    acts = {},
    timestamp = nil
  }
end

function ProtoMessage:newSceneSerializedActsNotify()
  return {serialized_acts = nil}
end

function ProtoMessage:newSpaceAct_ThrowedPetInfoChange()
  return {
    actor_id = nil,
    throwed_pet_infos = {},
    delete_pet_gids = {}
  }
end

function ProtoMessage:newSpaceAct_DelThrowingMagic()
  return {actor_id = nil, throw_id = nil}
end

function ProtoMessage:newSpaceAct_FieldTagChange()
  return {
    change_info = {},
    data_length = nil,
    aura_id = nil
  }
end

function ProtoMessage:newTagChangeInfo()
  return {
    tag_data = {},
    result_tag_type = nil
  }
end

function ProtoMessage:newSpaceAct_GameTimeChange()
  return {
    actor_id = nil,
    game_time_info = ProtoMessage:newActorInfo_GameTime()
  }
end

function ProtoMessage:newSpaceAct_GameTimeSync()
  return {actor_id = nil, game_time = nil}
end

function ProtoMessage:newSpaceAct_MinigameNotify()
  return {
    status = nil,
    minigame_cfg_id = nil,
    progress = {},
    remain_time = nil,
    trigger_npc_obj_id = nil
  }
end

function ProtoMessage:newSpaceAct_GuideTask()
  return {
    guide_list = {}
  }
end

function ProtoMessage:newGuideItem()
  return {
    npcs = {},
    task_id = nil,
    pos = ProtoMessage:newPosition(),
    guide_info = {}
  }
end

function ProtoMessage:newSpaceAct_ClientEventResume()
  return {
    event = nil,
    tag = {}
  }
end

function ProtoMessage:newSpaceAct_NpcPendantInfoChange()
  return {
    npc_id = nil,
    pendant_cfg_id = nil,
    enable = nil,
    changed_pendant_item_infos = {}
  }
end

function ProtoMessage:newChangedNpcPendantItemInfo()
  return {
    id = nil,
    enable = nil,
    status = nil
  }
end

function ProtoMessage:newSpaceAct_OwlRefugeInfoChange()
  return {
    refuge_cfg_id = nil,
    obtained_reward_idxs = {}
  }
end

function ProtoMessage:newSpaceAct_UnlockSleepingOwl()
  return {npc_id = nil, refuge_cfg_id = nil}
end

function ProtoMessage:newSpaceAct_FashionChange()
  return {
    actor_id = nil,
    wearing_item = {},
    fashion_item_wear_data = {}
  }
end

function ProtoMessage:newSpaceAct_SalonChange()
  return {
    actor_id = nil,
    salon_item_wear_data = {}
  }
end

function ProtoMessage:newSpaceAct_PetInteractResNty()
  return {
    npc_id = nil,
    status = ProtoEnum.SpaceAct_PetInteractResNty.PetInteractStatus.SUCCESS,
    pet_interact_cfg_id = nil,
    option_id = nil,
    pet_npc_id = nil,
    combine_interact_pet_npc_ids = {}
  }
end

function ProtoMessage:newSpaceAct_CombineInteractInfoChange()
  return {
    actor_id = nil,
    wait_pet_interact_avatar_id = nil,
    combine_interact_infos = {}
  }
end

function ProtoMessage:newSpaceAct_BuffInfoChange()
  return {
    actor_id = nil,
    removed_buff_id = nil,
    buff_changed_reason = nil,
    changed_buff_info = ProtoMessage:newActorInfo_Buff()
  }
end

function ProtoMessage:newSpaceAct_NameChange()
  return {actor_id = nil, name = nil}
end

function ProtoMessage:newSpaceAct_CardLabelChange()
  return {
    actor_id = nil,
    card_label_first_selected = nil,
    card_label_last_selected = nil
  }
end

function ProtoMessage:newSpaceAct_CardSkinChange()
  return {actor_id = nil, card_skin_selected = nil}
end

function ProtoMessage:newSpaceAct_CardIconChange()
  return {actor_id = nil, card_icon_selected = nil}
end

function ProtoMessage:newSpaceAct_VideoRecord()
  return {actor_id = nil, start_or_end = nil}
end

function ProtoMessage:newSpaceAct_CollectHandbookRecordsChange()
  return {
    handbook_records = {}
  }
end

function ProtoMessage:newSpaceAct_CardMusicChange()
  return {actor_id = nil, card_music_id = nil}
end

function ProtoMessage:newSpaceAct_WorldCombatEnter()
  return {
    npc_id = nil,
    avatar_id = nil,
    world_combat_id = nil,
    world_combat_cfg_id = nil,
    world_combat_phase = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatExit()
  return {
    avatar_id = nil,
    world_combat_id = nil,
    npc_id = nil,
    world_combat_cfg_id = nil,
    world_combat_res = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatTextPrompts()
  return {text_prompts_id = nil}
end

function ProtoMessage:newSpaceAct_WorldCombatPhaseUpdate()
  return {
    world_combat_id = nil,
    npc_id = nil,
    world_combat_phase = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatExtraRewardUpdate()
  return {
    world_combat_id = nil,
    npc_id = nil,
    extra_reward_list = {}
  }
end

function ProtoMessage:newSpaceAct_SceneSvrErrEcho()
  return {err_str = nil}
end

function ProtoMessage:newSpaceAct_WorldCombatBegin()
  return {
    npc_id = nil,
    avatar_id = {},
    world_combat_id = nil,
    world_combat_cfg_id = nil,
    world_combat_phase = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatFinish()
  return {
    world_combat_id = nil,
    npc_id = nil,
    world_combat_cfg_id = nil,
    world_combat_res = nil,
    is_boss_challenge = nil,
    is_combat_avatar = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillCast()
  return {
    actor_id = nil,
    skill_cast_info = ProtoMessage:newWorldCombatDotsSkillCastInfo(),
    cast_point = ProtoMessage:newPoint(),
    is_need_sync_pos = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillCrush()
  return {
    actor_id = nil,
    skill_crush_info = ProtoMessage:newWorldCombatDotsSkillCrushInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillCrushEnd()
  return {
    actor_id = nil,
    skill_crush_end_info = ProtoMessage:newWorldCombatDotsSkillCrushEndInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillHit()
  return {
    actor_id = nil,
    skill_hit_info = ProtoMessage:newWorldCombatDotsSkillHitInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillRotate()
  return {
    actor_id = nil,
    skill_rotate_info = ProtoMessage:newWorldCombatDotsSkillRotateInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillLookAt()
  return {
    actor_id = nil,
    skill_lookat_info = ProtoMessage:newWorldCombatDotsSkillLookAtInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillEnd()
  return {
    actor_id = nil,
    skill_end_info = ProtoMessage:newWorldCombatDotsSkillEndInfo(),
    cast_end_point = ProtoMessage:newPoint(),
    is_need_sync_pos = nil
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileLaunch()
  return {
    actor_id = nil,
    skill_missile_launch = ProtoMessage:newWorldCombatDotsSkillMissileLaunchInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileDestroy()
  return {
    actor_id = nil,
    skill_missile_destroy = ProtoMessage:newWorldCombatDotsSkillMissileDestroyInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillMissileStopTrace()
  return {
    actor_id = nil,
    skill_missile_stop_trace = ProtoMessage:newWorldCombatDotsSkillMissileStopTraceInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillJump()
  return {
    actor_id = nil,
    skill_jump = ProtoMessage:newWorldCombatDotsSkillJumpInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillJumpCancel()
  return {
    actor_id = nil,
    skill_jump_cancel = ProtoMessage:newWorldCombatDotsSkillJumpCancelInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillJumpEnd()
  return {
    actor_id = nil,
    skill_jump_end = ProtoMessage:newWorldCombatDotsSkillJumpEndInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillRcd()
  return {
    actor_id = nil,
    skill_rcd = ProtoMessage:newWorldCombatDotsSkillRcdInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillRcdEnd()
  return {
    actor_id = nil,
    skill_rcd_end = ProtoMessage:newWorldCombatDotsSkillRcdEndInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillSelectPos()
  return {
    actor_id = nil,
    skill_select_pos = ProtoMessage:newWorldCombatDotsSkillSelectPosInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillHidden()
  return {
    actor_id = nil,
    skill_hidden = ProtoMessage:newWorldCombatDotsSkillHiddenInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillHiddenEnd()
  return {
    actor_id = nil,
    skill_hidden_end = ProtoMessage:newWorldCombatDotsSkillHiddenEndInfo()
  }
end

function ProtoMessage:newSpaceAct_BattleAIStatusChanged()
  return {actor_id = nil, battle_ai_status = nil}
end

function ProtoMessage:newSpaceAct_SceneAiControlFlagsChanged()
  return {actor_id = nil, scene_ai_control_flags = nil}
end

function ProtoMessage:newSpaceAct_RelatedNpcInfosChanged()
  return {
    actor_id = nil,
    relate_npcs = ProtoMessage:newActorInfo_RelatedNpcInfos()
  }
end

function ProtoMessage:newSpaceAct_WorldMapInfoChanged()
  return {
    actor_id = nil,
    changed_entries = ProtoMessage:newWorldMapEntries(),
    unlocked_world_map_block_cfg_id = nil,
    changed_layered_explore_info = ProtoMessage:newLayeredWorldMapExploreInfoOne(),
    del_auto_track_npc_logic_id = nil
  }
end

function ProtoMessage:newSpaceAct_BattleBuffInfoChanged()
  return {
    actor_id = nil,
    buff_info = {}
  }
end

function ProtoMessage:newSpaceAct_SameCellTeleport()
  return {
    actor_id = nil,
    to_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newSpaceAct_VelocityOrientedRotation()
  return {
    actor_id = nil,
    rotation = ProtoMessage:newPosition(),
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    enable = nil
  }
end

function ProtoMessage:newSpaceAct_WorldLaunchPlayer()
  return {
    actor_id = nil,
    force_xy = nil,
    force_z = nil,
    direction = ProtoMessage:newPosition(),
    cool_down = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo()
  }
end

function ProtoMessage:newSpaceAct_AIPerformGroupIdChanged()
  return {actor_id = nil, perform_group_id = nil}
end

function ProtoMessage:newSpaceAct_OwlSanctuaryDetected()
  return {
    owl_sanctuary_info = ProtoMessage:newAvatarOwlSanctuaryInfo()
  }
end

function ProtoMessage:newSpaceAct_OwlSanctuaryFruitInfoUpdate()
  return {
    owl_content_id = nil,
    fruit_infos = {},
    uin = nil,
    owl_sanctuary_infos = {}
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillShowHideChange()
  return {
    actor_id = nil,
    show_hide_info = ProtoMessage:newWorldCombatDotsSkillShowHideInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillPosLerpSync()
  return {
    actor_id = nil,
    info = ProtoMessage:newWorldCombatDotsSkillPosLerpSyncInfo()
  }
end

function ProtoMessage:newSpaceAct_WorldCombatDotsSkillAnimCancel()
  return {
    actor_id = nil,
    info = ProtoMessage:newWorldCombatDotsSkillAnimCancelInfo()
  }
end

function ProtoMessage:newSpaceAct_AirWallChange()
  return {
    add_list = {},
    sub_list = {}
  }
end

function ProtoMessage:newSpaceAct_HomeBasicInfoChangeNotify()
  return {
    cell_id = nil,
    home_basic_info = ProtoMessage:newActorInfo_HomeBasicInfo()
  }
end

function ProtoMessage:newSpaceAct_HomeBasicVisitorEnterHome()
  return {
    actor_id = nil,
    name = nil,
    is_home_owner = nil,
    home_owner_online_status = ProtoEnum.HomeOwnerOnlineStatus.HOME_OWNER_ONLINE_STATUS_OUT_HOME
  }
end

function ProtoMessage:newSpaceAct_HomeBasicVisitorLeavingHome()
  return {
    actor_id = nil,
    name = nil,
    is_home_owner = nil,
    home_owner_online_status = ProtoEnum.HomeOwnerOnlineStatus.HOME_OWNER_ONLINE_STATUS_OUT_HOME
  }
end

function ProtoMessage:newSpaceAct_HomePlantChangeNotify()
  return {
    actor_id = nil,
    home_plant_info = ProtoMessage:newCellInfo_HomePlantInfo()
  }
end

function ProtoMessage:newSpaceAct_ActorPlantDataUpdate()
  return {
    actor_plant_data = ProtoMessage:newActorPlantData()
  }
end

function ProtoMessage:newSpaceAct_HomePlantPlantCrop()
  return {
    actor_id = nil,
    land_id = nil,
    seed_id = nil
  }
end

function ProtoMessage:newSpaceAct_HomePlantRoleWater()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_HomePlantPetWater()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_HomePlantRoleManure()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_HomePlantPetManure()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_HomePlantOwnerPick()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_HomePlantVisitorPick()
  return {actor_id = nil, land_id = nil}
end

function ProtoMessage:newSpaceAct_TravelTogetherSync()
  return {
    actor_id = nil,
    pos_diff = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newSpaceAct_Stun()
  return {
    actor_id = nil,
    override_duration = nil,
    duration = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    remain_time = nil
  }
end

function ProtoMessage:newSpaceAct_DeleteThrowNotify()
  return {
    caster_id = nil,
    throw_id = nil,
    npc_id = nil,
    is_catch_success = nil,
    shake_times = nil,
    is_tech_satisfied = nil,
    is_catch = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    is_quick_catch = nil,
    is_create_pet_npc = nil
  }
end

function ProtoMessage:newSpaceAct_InnerBattle()
  return {
    actor_id = nil,
    info = ProtoMessage:newInnerBattleInfo()
  }
end

function ProtoMessage:newSpaceAct_InnerBattleShieldBroken()
  return {
    actor_id = nil,
    world_npc_obj_id = nil,
    pet_info = ProtoMessage:newInnerBattlePetDisplay(),
    bfd_id = nil,
    battle_conf_id = nil
  }
end

function ProtoMessage:newSpaceAct_InnerBattleChangePet()
  return {
    actor_id = nil,
    world_npc_obj_id = nil,
    pet_info = ProtoMessage:newInnerBattlePetDisplay(),
    bfd_id = nil,
    battle_conf_id = nil,
    is_side_b = nil
  }
end

function ProtoMessage:newSpaceAct_ActorKeepModel()
  return {
    keep_model_actor_ids = {}
  }
end

function ProtoMessage:newSpaceAct_PetClosenessLvUpgrade()
  return {
    pet_npc_obj_id = nil,
    closeness_lv = nil,
    owner_avatar_uin = nil
  }
end

function ProtoMessage:newSpaceAct_CameraFlash()
  return {actor_id = nil, camera_npc_id = nil}
end

function ProtoMessage:newSpaceAct_CameraSkinChange()
  return {
    actor_id = nil,
    camera_npc_id = nil,
    camera_skin_id = nil,
    unlock_skin_ids = {},
    new_skin_id = nil,
    bag_item_id = nil
  }
end

function ProtoMessage:newSpaceAct_AISeqIdNotify()
  return {
    actor_id_list = {},
    ai_sed_list = {}
  }
end

function ProtoMessage:newSpaceAct_IdleSkill()
  return {
    actor_id = nil,
    skill_id = nil,
    pet_base_id = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo(),
    nature = nil,
    pet_actor_id = nil,
    gid = nil
  }
end

function ProtoMessage:newSpaceAct_PetVoice()
  return {
    actor_id = nil,
    owner_actor_id = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newSpaceAct_CatchRecordInfoChange()
  return {
    actor_id = nil,
    catch_record_datas = ProtoMessage:newCatchRecordInfo(),
    del_habitat_ids = {},
    del_evolution_chain_ids = {}
  }
end

function ProtoMessage:newSpaceAct_HabitatNeighborInfoChange()
  return {
    actor_id = nil,
    change_habitat_neighbor_datas = ProtoMessage:newHabitatNeighborRelationInfo(),
    del_habitat_ids = {}
  }
end

function ProtoMessage:newSpaceAct_AllHabitatNeighborInfo()
  return {
    actor_id = nil,
    all_habitat_neighbor_datas = ProtoMessage:newHabitatNeighborRelationInfo()
  }
end

function ProtoMessage:newSpaceAct_PlayChatBubble()
  return {
    actor_id = nil,
    sync_common_info = ProtoMessage:newSvrAISyncCommonInfo(),
    message_str = nil,
    play_time = nil
  }
end

function ProtoMessage:newSpaceAct_PlayerTagsChange()
  return {
    actor_id = nil,
    player_tags = {}
  }
end

function ProtoMessage:newSpaceAct_AbnormalStatusChangeNtf()
  return {
    actor_id = nil,
    status_conf_id = nil,
    start_time_ms = nil
  }
end

function ProtoMessage:newSpaceAct_LLM_PETS_QueryPets()
  return {
    pet_gid = {}
  }
end

function ProtoMessage:newSpaceAct_LLM_PETS_BehaviorNotify()
  return {
    behaviors = {},
    is_cd = nil,
    request_id = nil
  }
end

function ProtoMessage:newBehaviorInfo()
  return {
    npc_actor_id = nil,
    behavoir_group_id = {},
    behavior_group_infos = {}
  }
end

function ProtoMessage:newSpaceAct_NpcSizeScaleChange()
  return {npc_id = nil, size_scale = nil}
end

function ProtoMessage:newSpaceAct_BonusCatchLimitTips()
  return {tips_id = nil, current_count = nil}
end

function ProtoMessage:newSpaceAct_NpcMutationInfoChange()
  return {
    npc_obj_id = nil,
    mutation_type = nil,
    glass_info = ProtoMessage:newGlassInfo()
  }
end

function ProtoMessage:newSpaceEnum_SpaceObjType()
  return {}
end

function ProtoMessage:newSpaceEnum_SpaceObjSubType()
  return {}
end

function ProtoMessage:newSpaceEnum_ActorDetailType()
  return {}
end

function ProtoMessage:newSpaceEnum_AvatarSceneChangeReason()
  return {}
end

function ProtoMessage:newSpaceEnum_NpcRefreshSource()
  return {}
end

function ProtoMessage:newSpaceEnum_ActorMoveMode()
  return {}
end

function ProtoMessage:newSpaceEnum_NpcActionStatus()
  return {}
end

function ProtoMessage:newZonePlayerStoryFlagChangeNotify()
  return {
    change_type = nil,
    change_val = nil,
    version = nil
  }
end

function ProtoMessage:newZonePlayerMultiStoryFlagChangeNotify()
  return {
    change_type = nil,
    change_val = {},
    version = nil
  }
end

function ProtoMessage:newZoneSceneWorldMapTeleportReq()
  return {entry_id = nil, use_special_teleport = nil}
end

function ProtoMessage:newZoneSceneWorldMapTeleportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    entry_id = nil,
    target_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneWorldMapTeleportToNpcReq()
  return {npc_obj_id = nil}
end

function ProtoMessage:newZoneSceneWorldMapTeleportToNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    npc_obj_id = nil,
    target_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneWorldMapTeleportToPlayerReq()
  return {uin = nil}
end

function ProtoMessage:newZoneSceneWorldMapTeleportToPlayerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    target_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneWorldMapInfoChangedNty()
  return {
    changed_entries = ProtoMessage:newWorldMapEntries()
  }
end

function ProtoMessage:newZoneSceneWorldMapSyncInterruptNty()
  return {interrupt_reason = nil}
end

function ProtoMessage:newZoneMapMarkOperateReq()
  return {
    op_type = nil,
    mark_id = nil,
    type = nil,
    world_map_cfg_id = nil,
    name = nil,
    pos = ProtoMessage:newPosition(),
    layer_id = nil,
    scene_id = nil
  }
end

function ProtoMessage:newZoneMapMarkOperateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mark_entry = ProtoMessage:newWorldMapEntry_Mark(),
    op_type = nil
  }
end

function ProtoMessage:newZoneSceneGmMapMarkOperateReq()
  return {
    op_type = nil,
    num = nil,
    world_map_cfg_id = nil
  }
end

function ProtoMessage:newZoneSceneGmMapMarkOperateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mark_entry = {}
  }
end

function ProtoMessage:newZoneSceneWorldMapSyncAutoTrackNpcReq()
  return {npc_logic_id = nil}
end

function ProtoMessage:newZoneSceneWorldMapSyncAutoTrackNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    auto_track_npc_info = ProtoMessage:newWorldMapAutoTrackNpcInfo()
  }
end

function ProtoMessage:newSceneWorldMapInfoChangedNty()
  return {
    changed_entries = ProtoMessage:newWorldMapEntries()
  }
end

function ProtoMessage:newSceneWorldMapSyncInterruptNty()
  return {interrupt_reason = nil}
end

function ProtoMessage:newZoneLoginReq()
  return {
    openid = nil,
    plat_info = ProtoMessage:newPlatInfo(),
    cli_info = ProtoMessage:newClientInfo(),
    is_login = nil,
    leaving_online_visiting = nil,
    quality = nil
  }
end

function ProtoMessage:newZoneLoginRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_info = ProtoMessage:newPlayerInfo(),
    svr_time = nil,
    need_reconnect = nil,
    ban_info = ProtoMessage:newBanInfo(),
    feature_data = ProtoMessage:newPlayerSecLightFeatureData(),
    svr_time_zone = nil,
    wg_auth_result = ProtoMessage:newWegameAuthResult()
  }
end

function ProtoMessage:newZoneRegisterReq()
  return {
    openid = nil,
    plat_info = ProtoMessage:newPlatInfo(),
    cli_info = ProtoMessage:newClientInfo(),
    name = nil,
    cdkey = nil,
    label = nil
  }
end

function ProtoMessage:newZoneRegisterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    regist_beg_time = nil,
    regist_end_time = nil
  }
end

function ProtoMessage:newZoneKickoutNty()
  return {
    kickout_type = nil,
    kickout_sub_type = nil,
    kickout_msg = ProtoMessage:newMultiLangPb(),
    kickout_txt_id = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneEnterSceneReq()
  return {}
end

function ProtoMessage:newZoneEnterSceneRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    scene_cfg_id = nil,
    scene_res_cfg_id = nil,
    scene_inst_id = nil,
    home_room_level = nil,
    home_name = nil,
    online_visiting_owner = nil,
    self_info = ProtoMessage:newActorInfo()
  }
end

function ProtoMessage:newZoneSceneMoveReq()
  return {
    time_stamp = nil,
    to_pos = ProtoMessage:newPosition(),
    to_rot = ProtoMessage:newPosition(),
    speed = ProtoMessage:newPosition(),
    acceleration = ProtoMessage:newPosition(),
    move_mode = nil,
    custom_mode = nil,
    stop_move = nil,
    move_seg_list = {},
    platform_actor_id = nil,
    ctrl_rot = ProtoMessage:newPosition(),
    scene_cfg_id = nil,
    ride_move = nil,
    mate_point = ProtoMessage:newPoint(),
    mate_move_mode = nil
  }
end

function ProtoMessage:newZoneSceneMoveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneInteractMoveReq()
  return {
    to_point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneInteractMoveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneSyncPlayerStatusReq()
  return {
    time_stamp = nil,
    status = nil,
    op_code = nil,
    sub_status = nil,
    is_normal_remove = nil,
    custom_status_param = ProtoMessage:newPlayerStatusCustomParams(),
    sync_status_info_list = {}
  }
end

function ProtoMessage:newZoneSceneSyncPlayerStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneNpcNextActReq()
  return {
    trig_interact_type = ProtoEnum.TrigInteractType.ENUM.Normal,
    npc_id = nil,
    option_id = nil,
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    data1 = nil,
    battle_radius = nil,
    cur_dialog_id = nil,
    battle_center = ProtoMessage:newPoint(),
    first_act = nil,
    commit_cur_act_params = nil,
    begin_next_act_params = nil,
    npc_ai_blackboard = ProtoMessage:newClientNpcBlackboard(),
    cheer_monster_init_info = {},
    battle_type = nil,
    ride_id = nil,
    onlooker_obj_id = {},
    extra_data = nil,
    begin_skip_dialog = nil,
    sit_npc_seat_idx = nil,
    before_sit_point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneNpcNextActRsp()
  return {
    fail_dungeon_ret = {},
    ret_info = ProtoMessage:newRetInfo(),
    act_results = {},
    commit_results = {}
  }
end

function ProtoMessage:newZoneSceneNpcsInteractReq()
  return {
    npc_id = nil,
    option_id = nil,
    source_npc_id = nil
  }
end

function ProtoMessage:newZoneSceneNpcsInteractRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneNpcDialogSelectReq()
  return {
    npc_id = nil,
    option_id = nil,
    select_id = nil,
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    battle_center = ProtoMessage:newPoint(),
    battle_radius = nil
  }
end

function ProtoMessage:newZoneSceneNpcDialogSelectRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    act_results = {},
    commit_results = {}
  }
end

function ProtoMessage:newZoneSceneNpcCancelActReq()
  return {
    npc_id = nil,
    option_id = nil,
    force = nil
  }
end

function ProtoMessage:newZoneSceneNpcCancelActRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newQuickChangeMainTeamInfo()
  return {main_team_idx = nil, team_type = nil}
end

function ProtoMessage:newZoneSceneBeginThrowReq()
  return {
    throw_type = ProtoEnum.ThrowType.NONE,
    gid = nil,
    throw_id = nil,
    item_conf_id = nil,
    change_team = ProtoMessage:newQuickChangeMainTeamInfo()
  }
end

function ProtoMessage:newZoneSceneBeginThrowRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    throw_id = nil,
    change_team = ProtoMessage:newQuickChangeMainTeamInfo()
  }
end

function ProtoMessage:newThrowCombineInfo()
  return {
    gid = {}
  }
end

function ProtoMessage:newZoneSceneEndThrowReq()
  return {
    throw_type = ProtoEnum.ThrowType.NONE,
    gid = nil,
    throw_effect = ProtoEnum.ThrowEffect.TE_NONE,
    throw_target_npc_infos = {},
    throw_id = nil,
    end_throw_pos = ProtoMessage:newPosition(),
    fly_distance = nil,
    params = {},
    throw_battle_info = ProtoMessage:newThrowBattleInfo(),
    throw_create_info = ProtoMessage:newThrowCreateInfo(),
    throw_magic_info = ProtoMessage:newThrowMagicInfo(),
    throw_combine_info = ProtoMessage:newThrowCombineInfo(),
    throw_status_info = ProtoMessage:newThrowStatusInfo(),
    item_conf_id = nil
  }
end

function ProtoMessage:newZoneSceneEndThrowRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    throw_bagitem_result = ProtoMessage:newThrowBagItemResult(),
    catch_result = ProtoMessage:newZoneCatchResult(),
    random_result = {},
    throw_pet_result = ProtoMessage:newThrowPetResult(),
    throw_magic_create_npc_result = ProtoMessage:newThrowMagicCreateNPCResult(),
    throw_star_magic_result = ProtoMessage:newThrowStarMagicResult()
  }
end

function ProtoMessage:newZoneSceneThrowCatchFinishReq()
  return {throw_id = nil}
end

function ProtoMessage:newZoneSceneThrowCatchFinishRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneProcessThrowReq()
  return {
    throw_type = ProtoEnum.ThrowType.NONE,
    gid = nil,
    throw_target_npc_infos = {},
    throw_id = nil,
    item_conf_id = nil
  }
end

function ProtoMessage:newZoneSceneProcessThrowRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneCreateScenePetReq()
  return {
    gid = nil,
    create_pt = ProtoMessage:newPoint(),
    throw_id = nil,
    create_reason = ProtoEnum.ClientCreatePetReason.CCPR_NONE
  }
end

function ProtoMessage:newZoneSceneCreateScenePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRecycleThrowPetReq()
  return {
    gid = nil,
    reason = ProtoEnum.RecycleThrowPetReason.RTPR_NONE
  }
end

function ProtoMessage:newZoneSceneRecycleThrowPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneScenePetPowerDashInteractReq()
  return {
    gid = nil,
    npc_actor_id = nil,
    option_id = nil,
    pet_data = ProtoMessage:newSceneBasePetData()
  }
end

function ProtoMessage:newZoneScenePetPowerDashInteractRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneNtyAuraEnableStReq()
  return {aura_id = nil, is_enabled = nil}
end

function ProtoMessage:newZoneSceneNtyAuraEnableStRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChangeSelectedThrowItemReq()
  return {
    cur_selected_throw_item = ProtoMessage:newThrowItemInfo(),
    cur_selected_magic_item_gid = nil
  }
end

function ProtoMessage:newZoneChangeSelectedThrowItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChangeSelectedThrowItemNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    cur_selected_throw_item = ProtoMessage:newThrowItemInfo(),
    cur_selected_magic_item_gid = nil
  }
end

function ProtoMessage:newZoneChangeRoleMagicItemReq()
  return {item_gid = nil, item_conf_id = nil}
end

function ProtoMessage:newZoneChangeRoleMagicItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneSetNpcPosReq()
  return {
    npc_list = {}
  }
end

function ProtoMessage:newZoneSceneSetNpcPosRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    failed_npc_list = {}
  }
end

function ProtoMessage:newZoneSceneSetBroadcastLimitReq()
  return {new_limit = nil}
end

function ProtoMessage:newZoneSceneSetBroadcastLimitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneClientEnterSceneFinishNty()
  return {actor_id = nil, feature_data = nil}
end

function ProtoMessage:newZoneSceneClientEnterSceneFinishNtyAck()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    enabled_no_loading_teleport = nil,
    other_actors = {},
    deleted_other_actor_ids = {},
    add_or_update_other_actors_total_batch = nil,
    adjust_data = ProtoMessage:newSelfActorAdjustData(),
    home_info = ProtoMessage:newHomeInfo()
  }
end

function ProtoMessage:newZoneSceneClientInitAoiIncrUpdateNty()
  return {
    batch_id = nil,
    total_batch = nil,
    other_actors = {}
  }
end

function ProtoMessage:newZoneSceneHeartbeatNty()
  return {heartbeat_seq = nil, server_logic_tick_ivl = nil}
end

function ProtoMessage:newZoneSceneHeartbeatNtyRsp()
  return {heartbeat_seq = nil, pass_data = nil}
end

function ProtoMessage:newZoneSceneHeartbeatResultNty()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    heartbeat_seq = nil,
    server_time = nil,
    trans_delay_time = nil,
    avg_trans_delay_time = nil,
    server_logic_frame = nil,
    pass_data = nil
  }
end

function ProtoMessage:newZoneScenePlayerActNtyReq()
  return {player_act = nil, player_sub_act = nil}
end

function ProtoMessage:newZoneScenePlayerActNtyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneEnableBattleNtyReq()
  return {actor_id = nil, enable_battle = nil}
end

function ProtoMessage:newZoneSceneEnableBattleNtyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneClientAiCommandReq()
  return {
    actor_id = nil,
    action_id = nil,
    pos = ProtoMessage:newPosition(),
    command_param = nil,
    command_list = {}
  }
end

function ProtoMessage:newZoneSceneClientAiCommandRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneClientRemoteStoreReq()
  return {
    meth = nil,
    key = nil,
    value = nil,
    live_time = nil,
    cli_stub = nil
  }
end

function ProtoMessage:newZoneClientRemoteStoreRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    value = nil,
    cli_stub = nil
  }
end

function ProtoMessage:newZoneClientRemoteStorageChangeNty()
  return {
    del_keys = {},
    update_rs_datas = {}
  }
end

function ProtoMessage:newZoneGetBagReq()
  return {ext = nil, type = nil}
end

function ProtoMessage:newZoneGetBagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bag_info = ProtoMessage:newPlayerBagInfo()
  }
end

function ProtoMessage:newZoneUseBagItemReq()
  return {
    gid = nil,
    num = nil,
    para = nil,
    change_attr_type = {},
    target_type = {},
    change_talent_type = nil,
    result_type = nil,
    para2 = nil,
    item_conf_id = nil
  }
end

function ProtoMessage:newZoneUseBagItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = ProtoMessage:newGoodsReward(),
    use_bag_id = nil
  }
end

function ProtoMessage:newZoneUseMultiBagItemReq()
  return {
    item_info = {}
  }
end

function ProtoMessage:newBagItemInfo()
  return {
    gid = nil,
    num = nil,
    para = nil,
    item_conf_id = nil
  }
end

function ProtoMessage:newZoneUseMultiBagItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newBagSellNode()
  return {gid = nil, num = nil}
end

function ProtoMessage:newZoneSellBagItemReq()
  return {
    gid = nil,
    num = nil,
    type = ProtoEnum.BagSellType.SELL_ONE,
    gid_list = {}
  }
end

function ProtoMessage:newZoneSellBagItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = ProtoMessage:newGoodsReward()
  }
end

function ProtoMessage:newZoneModifyBagItemFlagsReq()
  return {
    modify_info = {}
  }
end

function ProtoMessage:newModifyInfo()
  return {
    gid = nil,
    bag_item_flags = nil,
    slot_idx = nil,
    item_conf_id = nil
  }
end

function ProtoMessage:newZoneModifyBagItemFlagsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    items = {}
  }
end

function ProtoMessage:newCSExchangeItem()
  return {
    id = nil,
    num = nil,
    cost_goods = {}
  }
end

function ProtoMessage:newGoods()
  return {
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_num = nil
  }
end

function ProtoMessage:newZoneExchangeReq()
  return {
    exchange_id = nil,
    exchange_num = nil,
    npc_space_obj_id = nil,
    cost_goods_id = {},
    exchange_item = ProtoMessage:newCSExchangeItem()
  }
end

function ProtoMessage:newZoneExchangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = ProtoMessage:newGoodsReward(),
    recipes = ProtoMessage:newCSUnlockedExchangeRecipe()
  }
end

function ProtoMessage:newZoneBatchExchangeReq()
  return {
    exchange_items = {}
  }
end

function ProtoMessage:newZoneBatchExchangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneVisualItemUpgradeReq()
  return {
    visual_item_type = nil,
    visual_item_upgrade_conf_id = nil,
    npc_space_obj_id = nil
  }
end

function ProtoMessage:newZoneVisualItemUpgradeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = ProtoMessage:newGoodsReward()
  }
end

function ProtoMessage:newBattleEnterBattleFieldReq()
  return {}
end

function ProtoMessage:newBattleEnterBattleFieldRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetEvoluteReq()
  return {pet_gid = nil, chosen_evolve_idx = nil}
end

function ProtoMessage:newZonePetEvoluteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetEquipSkillReq()
  return {
    equip_info = {},
    gid = nil,
    team_type = nil
  }
end

function ProtoMessage:newZonePetEquipSkillRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetRenameReq()
  return {gid = nil, name = nil}
end

function ProtoMessage:newZonePetRenameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneShopGetInfoReq()
  return {shop_id = nil}
end

function ProtoMessage:newZoneShopGetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shop_data = ProtoMessage:newShopData()
  }
end

function ProtoMessage:newZoneShopBuyItemReq()
  return {
    buy_item_info = {},
    shop_id = nil,
    content_id = nil,
    version = nil
  }
end

function ProtoMessage:newZoneShopBuyItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shop_id = nil,
    buy_item_info = {},
    shop_data = ProtoMessage:newShopData()
  }
end

function ProtoMessage:newZoneShopExchangeReq()
  return {
    shop_id = nil,
    goods_list = {},
    content_id = nil,
    version = nil
  }
end

function ProtoMessage:newZoneShopExchangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shop_id = nil,
    goods_list = {},
    shop_data = ProtoMessage:newShopData()
  }
end

function ProtoMessage:newZoneShopBatchGetInfoReq()
  return {
    shop_ids = {}
  }
end

function ProtoMessage:newZoneShopBatchGetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shop_datas = {}
  }
end

function ProtoMessage:newZoneSetFashionDataReq()
  return {
    fashion_item_wear_id = {},
    wardrobe_index = nil,
    wardrobe_name = nil,
    use_wardrobe = nil,
    trig_by_interact = nil,
    wear_suit_id = nil,
    salon_item_wear_id = {},
    wearing_item = {}
  }
end

function ProtoMessage:newZoneSetFashionDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    fashion_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo()
  }
end

function ProtoMessage:newZoneSetSalonDataReq()
  return {
    salon_item_wear_data = {}
  }
end

function ProtoMessage:newZoneSetSalonDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    salon_info = ProtoMessage:newPlayerAppearanceInfo_SalonInfo()
  }
end

function ProtoMessage:newZoneTaskRewardReq()
  return {
    task_list = {}
  }
end

function ProtoMessage:newZoneTaskRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    rewarded_task_list = {},
    next_task_list = {}
  }
end

function ProtoMessage:newZoneGetTaskSummaryReq()
  return {task_id = nil}
end

function ProtoMessage:newZoneGetTaskSummaryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    data = ProtoMessage:newTaskSummaryInfo()
  }
end

function ProtoMessage:newZoneTaskQueryReq()
  return {
    task_list = {},
    task_state = nil,
    task_paragraph_id = nil
  }
end

function ProtoMessage:newZoneTaskQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    task_info_list = {}
  }
end

function ProtoMessage:newZoneTaskTrackReq()
  return {curr_track_task = nil, new_track_task = nil}
end

function ProtoMessage:newZoneTaskTrackRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTaskStateReq()
  return {task_id = nil, new_state = nil}
end

function ProtoMessage:newZoneTaskStateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTaskSheetStateReq()
  return {}
end

function ProtoMessage:newZoneTaskSheetStateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    task_type_list = {}
  }
end

function ProtoMessage:newTaskTokenOwnedInfo()
  return {
    task_token_id = nil,
    task_token_get_time = nil,
    sub_task_id = nil,
    is_locked = nil
  }
end

function ProtoMessage:newZoneTaskPanelAllInfoReq()
  return {}
end

function ProtoMessage:newZoneTaskPanelAllInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    task_type_list = {},
    sub_task_token_triggered_task_info = {},
    sub_task_id = {},
    last_get_time = nil,
    task_token_owned_data = {}
  }
end

function ProtoMessage:newZoneWorldLevelTaskOpenReq()
  return {}
end

function ProtoMessage:newZoneWorldLevelTaskOpenRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    world_level_task_id = nil,
    task_state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newZoneWorldLevelTaskQueryReq()
  return {world_level_task_id = nil}
end

function ProtoMessage:newZoneWorldLevelTaskQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    world_level_task_id = nil,
    world_level_task_state = ProtoEnum.WorldLevelTaskState.WLTS_UNABLE_TO_UNLOCK
  }
end

function ProtoMessage:newZoneRewardAdventureChapterReq()
  return {chapter_id = nil}
end

function ProtoMessage:newZoneRewardAdventureChapterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneQueryBossNpcInfoReq()
  return {friend_uin = nil}
end

function ProtoMessage:newZoneSceneQueryBossNpcInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    flower_npcs = ProtoMessage:newBossNpcInfos(),
    world_leader_npcs = ProtoMessage:newBossNpcInfos(),
    legendary_npcs = ProtoMessage:newBossNpcInfos()
  }
end

function ProtoMessage:newZoneSceneSpecFlowerSeedInfoNty()
  return {
    flowers = ProtoMessage:newBossNpcInfos()
  }
end

function ProtoMessage:newZoneQueryInvestTaskReq()
  return {}
end

function ProtoMessage:newZoneQueryInvestTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    invest_task_list = {},
    clue_task_list = {},
    topic_task_list = {},
    remain_time = nil,
    special_reward_item = nil
  }
end

function ProtoMessage:newZoneReportTaskReq()
  return {
    tctt = ProtoEnum.TaskClientTriggerType.TCTT_READ_LETTER,
    data = nil
  }
end

function ProtoMessage:newZoneReportTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFriendDataChangedNotify()
  return {
    action = nil,
    friend_data = ProtoMessage:newFriendRoleInfo()
  }
end

function ProtoMessage:newZoneGameTimeChangeReq()
  return {time = nil}
end

function ProtoMessage:newZoneGameTimeChangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneModGameTimeReq()
  return {
    pause = nil,
    addi_time = nil,
    time_stamp = nil,
    npc_id = nil,
    minigame_cfg_id = nil
  }
end

function ProtoMessage:newZoneSceneModGameTimeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetLevelAwardReq()
  return {level = nil}
end

function ProtoMessage:newZoneGetLevelAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    awards = ProtoMessage:newPlayerLevelAwardInfo()
  }
end

function ProtoMessage:newZoneQueryLevelAwardReq()
  return {}
end

function ProtoMessage:newZoneQueryLevelAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    awards = ProtoMessage:newPlayerLevelAwardInfo()
  }
end

function ProtoMessage:newZoneSceneCreateBattleReq()
  return {
    source_data = ProtoMessage:newSourceData(),
    battle_conf_id = nil,
    npc_conf_id = nil,
    npc_level = nil,
    npc_obj_id = nil,
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    option_id = nil,
    npc_logic_id = nil,
    cheer_npcs = {},
    task_infos = {}
  }
end

function ProtoMessage:newZoneSceneCreateBattleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneMatchNotify()
  return {
    match_start_ut = nil,
    pvp_id = nil,
    state = ProtoEnum.PvpMatchState.PMS_NONE
  }
end

function ProtoMessage:newZoneSceneMatchStartReq()
  return {pvp_id = nil}
end

function ProtoMessage:newZoneSceneMatchStartRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneMatchCancelReq()
  return {}
end

function ProtoMessage:newZoneSceneMatchCancelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneRoleAttrReq()
  return {
    name = nil,
    sex = ProtoEnum.ESexValue.SEX_NOT_SHOW,
    image = nil,
    salon_item_wear_data = {},
    fashion_item_id = nil,
    fashion_suit_id = nil
  }
end

function ProtoMessage:newZoneRoleAttrRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    appearance_info = ProtoMessage:newPlayerAppearanceInfo()
  }
end

function ProtoMessage:newZoneConfirmReviveReq()
  return {}
end

function ProtoMessage:newZoneConfirmReviveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetFreeReq()
  return {
    pet_gid = {}
  }
end

function ProtoMessage:newZonePetFreeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_gid = {}
  }
end

function ProtoMessage:newZoneSceneEndChapterReq()
  return {npc_id = nil, option_id = nil}
end

function ProtoMessage:newZoneSceneEndChapterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTrackTaskNpcReq()
  return {
    task_id_list = {},
    only_not_break_journey = nil
  }
end

function ProtoMessage:newZoneTrackTaskNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    tracking_list = {},
    only_not_break_journey = nil,
    parent_list = {}
  }
end

function ProtoMessage:newParentTask()
  return {task_id = nil, parent_task_id = nil}
end

function ProtoMessage:newZoneGmClearBagItemReq()
  return {}
end

function ProtoMessage:newZoneGmClearBagItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSubRoleHpReq()
  return {
    sub_val = nil,
    sub_reason = nil,
    has_half_injure = nil
  }
end

function ProtoMessage:newZoneSubRoleHpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetBreakthroughReq()
  return {gid = nil}
end

function ProtoMessage:newZonePetBreakthroughRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetInspireReq()
  return {gid = nil}
end

function ProtoMessage:newZonePetInspireRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetGrowReq()
  return {pet_gid = nil, grow_times = nil}
end

function ProtoMessage:newZonePetGrowRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetTeamChangeReq()
  return {
    teams = {},
    team_idxs = {},
    team_type = nil,
    strict_check = nil,
    update_backpack = nil,
    main_team_idx = nil
  }
end

function ProtoMessage:newZonePetTeamChangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetChangeMainTeamReq()
  return {main_team_idx = nil, team_type = nil}
end

function ProtoMessage:newZonePetChangeMainTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneOpenPetBagReq()
  return {
    pet_gid = {}
  }
end

function ProtoMessage:newZoneOpenPetBagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetHandbookAwardReq()
  return {award_pt = nil, hb_area_type = nil}
end

function ProtoMessage:newZoneGetHandbookAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetEquipPossessionReq()
  return {
    equip_item_gid = nil,
    equip_pet_gid = nil,
    equip_slot_idx = nil,
    remove_slot_idx = nil,
    remove_pet_gid = nil,
    equip_item_conf_id = nil
  }
end

function ProtoMessage:newZonePetEquipPossessionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetRemovePossessionReq()
  return {remove_slot_idx = nil, remove_pet_gid = nil}
end

function ProtoMessage:newZonePetRemovePossessionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetMedalCommonReq()
  return {
    pet_gid = nil,
    medal_gid = nil,
    action = nil,
    medal_conf_id = nil
  }
end

function ProtoMessage:newZonePetMedalCommonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneEnterDungeonReq()
  return {dungeon_id = nil}
end

function ProtoMessage:newZoneEnterDungeonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneExitDungeonReq()
  return {teleport_id = nil, initiative_exit = nil}
end

function ProtoMessage:newZoneExitDungeonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAutoSupplyCarryonReq()
  return {is_auto_supply = nil, pet_gid = nil}
end

function ProtoMessage:newZoneAutoSupplyCarryonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneClientEventReq()
  return {
    client_event = {}
  }
end

function ProtoMessage:newClientEvent()
  return {
    event = nil,
    is_start = nil,
    tag = nil
  }
end

function ProtoMessage:newZoneSceneClientEventRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneDotsExecuteDataReq()
  return {
    systems_cost_time = {},
    total_cost_time = nil,
    ai_count = nil
  }
end

function ProtoMessage:newZoneSceneDotsExecuteDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneCampLevelUpReq()
  return {camp_content_id = nil, current_level = nil}
end

function ProtoMessage:newZoneCampLevelUpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneUpgradeCarryonReq()
  return {
    pet_gid = nil,
    slot_idx = nil,
    is_equipped = nil,
    upgrade_item_gid = nil,
    upgrade_item_conf_id = nil
  }
end

function ProtoMessage:newZoneUpgradeCarryonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    res_carryon = ProtoMessage:newPossession()
  }
end

function ProtoMessage:newZoneResonanceCarryonReq()
  return {
    pet_gid = nil,
    result_carryon_idx = nil,
    is_equipped = nil,
    result_item_gid = nil,
    cost_item_gid = nil,
    result_item_conf_id = nil,
    cost_item_conf_id = nil
  }
end

function ProtoMessage:newZoneResonanceCarryonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    res_carryon = ProtoMessage:newPossession()
  }
end

function ProtoMessage:newZoneSceneStartMinigameReq()
  return {minigame_cfg_id = nil}
end

function ProtoMessage:newZoneSceneStartMinigameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneExitMinigameReq()
  return {minigame_cfg_id = nil}
end

function ProtoMessage:newZoneSceneExitMinigameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReopenMinigameReq()
  return {minigame_cfg_id = nil}
end

function ProtoMessage:newZoneReopenMinigameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRewardMinigameReq()
  return {minigame_cfg_id = nil}
end

function ProtoMessage:newZoneSceneRewardMinigameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBackpackTeamUpdateReq()
  return {
    new_team_pet_gid = {}
  }
end

function ProtoMessage:newZoneBackpackTeamUpdateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetStarRecoverTimeReq()
  return {}
end

function ProtoMessage:newZoneGetStarRecoverTimeRsp()
  return {
    next_recover_time = nil,
    total_recover_time = nil,
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetStarDebrisInfoReq()
  return {}
end

function ProtoMessage:newZoneGetStarDebrisInfoRsp()
  return {
    is_recover = nil,
    recover_time = nil,
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneVerifyInteractCondReq()
  return {npc_obj_id = nil, option_id = nil}
end

function ProtoMessage:newZoneSceneVerifyInteractCondRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    need_cond_param = nil
  }
end

function ProtoMessage:newZoneSceneNpcPendantInteractReq()
  return {
    npc_id = nil,
    pendant_cfg_id = nil,
    id = nil
  }
end

function ProtoMessage:newZoneSceneNpcPendantInteractRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneReceiveOwlRefugeRewardReq()
  return {npc_id = nil, reward_idx = nil}
end

function ProtoMessage:newZoneSceneReceiveOwlRefugeRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newCSUnlockedExchangeRecipe()
  return {
    recipes = {}
  }
end

function ProtoMessage:newRecipe()
  return {exchange_id = nil, is_online_shared = nil}
end

function ProtoMessage:newZoneGetExchangeInfoReq()
  return {}
end

function ProtoMessage:newZoneGetExchangeInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    exchange_list = {}
  }
end

function ProtoMessage:newExchange()
  return {
    exchange_group = nil,
    exchange_times = nil,
    next_refresh_time = nil
  }
end

function ProtoMessage:newZoneGetUnlockedExchangeReq()
  return {}
end

function ProtoMessage:newZoneGetUnlockedExchangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    recipes = ProtoMessage:newCSUnlockedExchangeRecipe(),
    exchange_list = {}
  }
end

function ProtoMessage:newZoneUnlockExchangeRecipeNotify()
  return {
    recipes = ProtoMessage:newCSUnlockedExchangeRecipe(),
    is_full = nil
  }
end

function ProtoMessage:newZoneHandbookChangeNotify()
  return {
    record_coll = ProtoMessage:newHandbookRecordCollection(),
    is_new = nil,
    change_pet_base_id = nil,
    area_hb_change_info = {}
  }
end

function ProtoMessage:newAreaHandbookChangeInfo()
  return {
    hb_area_type = nil,
    curr_found_coll_num = nil,
    curr_collect_coll_num = nil
  }
end

function ProtoMessage:newZoneHandbookStatChangeNotify()
  return {
    hb_coll = {}
  }
end

function ProtoMessage:newZoneGetPetStatReq()
  return {
    version = nil,
    cached_pets = {},
    no_cached_pets = {}
  }
end

function ProtoMessage:newZoneGetPetStatRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    hb_coll = {},
    version = nil
  }
end

function ProtoMessage:newZoneGetHandbookTopicAwardReq()
  return {
    hb_id = nil,
    reward_idx = nil,
    area_type = nil,
    topic_id = nil
  }
end

function ProtoMessage:newTopicAwardItem()
  return {
    hb_id = nil,
    reward_idxs = {},
    topic_ids = {}
  }
end

function ProtoMessage:newZoneGetHandbookTopicAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    hb_id = nil,
    reward_idx = nil,
    award_items = {},
    topic_id = nil
  }
end

function ProtoMessage:newZoneGetHandbookSeasonAwardReq()
  return {
    season_id = nil,
    pet_type = ProtoEnum.PetHandbookSeasonPetType.PHSPT_NONE
  }
end

function ProtoMessage:newZoneGetHandbookSeasonAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    pet_type = ProtoEnum.PetHandbookSeasonPetType.PHSPT_NONE
  }
end

function ProtoMessage:newZoneGetPetHabitatReq()
  return {pet_base_id = nil}
end

function ProtoMessage:newZoneGetPetHabitatRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    area_conf_id = {},
    area_info = ProtoMessage:newHabitatAreaInfo()
  }
end

function ProtoMessage:newZoneSceneAIModifyLogicStatusReq()
  return {
    npc_obj_id = nil,
    operation = {}
  }
end

function ProtoMessage:newZoneSceneAIModifyLogicStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneWorldAttackHitReq()
  return {attack_actor_id = nil, hit_actor_id = nil}
end

function ProtoMessage:newZoneSceneWorldAttackHitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneWorldAttackCollideReq()
  return {attack_actor_id = nil}
end

function ProtoMessage:newZoneSceneWorldAttackCollideRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneDotsComponentSyncReq()
  return {
    actor_id = nil,
    component_datas = {}
  }
end

function ProtoMessage:newZoneDotsComponentSyncRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSwitchClientToServerAiReq()
  return {
    actor_list = {},
    comp_data_list = {},
    point_list = {}
  }
end

function ProtoMessage:newZoneSwitchClientToServerAiRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    success_list = {}
  }
end

function ProtoMessage:newZoneHopeNotify()
  return {
    instruction = ProtoMessage:newHopeInstruction()
  }
end

function ProtoMessage:newZoneFriendGetFriendListReq()
  return {
    count = nil,
    friend_type = nil,
    groups = {},
    scene = ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT,
    uin_list = {},
    furniture_id = nil,
    client_data1 = nil,
    client_data2 = nil,
    client_data3 = nil,
    client_data4 = nil
  }
end

function ProtoMessage:newZoneFriendGetFriendListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    friend_role_list = {},
    pack_index = nil,
    is_end = nil,
    recommend_player_list = {},
    refresh_gap = nil,
    friend_type = nil,
    scene = ProtoEnum.ZoneFriendGetFriendListScene.ZONE_FRIEND_GET_FRIEND_LIST_SCENE_DEFAULT,
    uin_list = {},
    furniture_id = nil,
    client_data1 = nil,
    client_data2 = nil,
    client_data3 = nil,
    client_data4 = nil
  }
end

function ProtoMessage:newZoneGetFriendExtInfoListReq()
  return {
    uin_list = {}
  }
end

function ProtoMessage:newZoneGetFriendExtInfoListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ext_info_list = {}
  }
end

function ProtoMessage:newZoneFriendSearchPlayerReq()
  return {uin = nil}
end

function ProtoMessage:newZoneFriendSearchPlayerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_info = ProtoMessage:newFriendRoleInfo(),
    is_friend = nil,
    is_black_role = nil,
    ban_info = ProtoMessage:newBanInfo(),
    can_be_add_friend = nil
  }
end

function ProtoMessage:newZoneFriendBatchSearchPlayerReq()
  return {
    openid_list = {}
  }
end

function ProtoMessage:newZoneSearchPlayerResult()
  return {
    openid = nil,
    player_info = ProtoMessage:newFriendRoleInfo(),
    is_friend = nil,
    is_black_role = nil,
    search_ret = nil
  }
end

function ProtoMessage:newZoneFriendBatchSearchPlayerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    role_list = {},
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneFriendAddOrRemoveFriendReq()
  return {
    uin = nil,
    oper_type = ProtoEnum.ZoneFriendAddOrRemoveFriendReq.TYPE.ADD_FRIEND
  }
end

function ProtoMessage:newZoneFriendAddOrRemoveFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    type = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneFriendConfirmAddFriendReq()
  return {
    uin = nil,
    oper_type = ProtoEnum.ZoneFriendConfirmAddFriendReq.TYPE.AGREE_REQ
  }
end

function ProtoMessage:newZoneFriendConfirmAddFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    change_friend_role = ProtoMessage:newFriendRoleInfo(),
    type = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneFriendAddOrRemoveFriendNotify()
  return {
    uin = nil,
    oper_type = ProtoEnum.ZoneFriendAddOrRemoveFriendNotify.TYPE.ADD_FRIEND_REQ,
    change_friend_role = ProtoMessage:newFriendRoleInfo(),
    new_req_friend = ProtoMessage:newFriendRequestInfo()
  }
end

function ProtoMessage:newZoneReportPlayerReq()
  return {
    uin = nil,
    type_list = {},
    report_text = nil
  }
end

function ProtoMessage:newZoneReportPlayerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFriendUpdateFriendInfoReq()
  return {
    uin = nil,
    note = nil,
    is_pinned = nil,
    type = ProtoEnum.UpdateFriendInfoType.MODIFY_NOTE
  }
end

function ProtoMessage:newZoneFriendUpdateFriendInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    note = nil,
    pinned_time = nil,
    type = ProtoEnum.UpdateFriendInfoType.MODIFY_NOTE
  }
end

function ProtoMessage:newZoneFriendGetBriefFriendListReq()
  return {}
end

function ProtoMessage:newZoneFriendGetBriefFriendListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    friend_uin_list = {},
    friend_list = {}
  }
end

function ProtoMessage:newBriefFriendInfo()
  return {
    uin = nil,
    note = nil,
    pinned_time = nil,
    friend_type = nil,
    plat_nick_name = nil
  }
end

function ProtoMessage:newZoneFriendGetAddFriendListReq()
  return {count = nil}
end

function ProtoMessage:newZoneFriendGetAddFriendListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    add_friend_list = {},
    pack_index = nil,
    is_end = nil
  }
end

function ProtoMessage:newZoneFriendGetBlackListReq()
  return {count = nil}
end

function ProtoMessage:newZoneFriendGetBlackListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    black_role_list = {},
    pack_index = nil,
    is_end = nil
  }
end

function ProtoMessage:newZoneFriendAddOrRemoveBlackListReq()
  return {
    uin = nil,
    oper_type = ProtoEnum.ZoneFriendAddOrRemoveBlackListReq.TYPE.ADD
  }
end

function ProtoMessage:newZoneFriendAddOrRemoveBlackListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    changed_black_info = ProtoMessage:newBlackListRoleInfo(),
    type = nil,
    change_friend_role = ProtoMessage:newFriendRoleInfo()
  }
end

function ProtoMessage:newZoneChatGetChatListReq()
  return {
    uin = nil,
    count = nil,
    visit_owner_uin = nil
  }
end

function ProtoMessage:newZoneChatSyncOfflineRedPointReq()
  return {}
end

function ProtoMessage:newZoneChatSyncOfflineRedPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFriendBatchRemoveFriendReq()
  return {
    uin_list = {}
  }
end

function ProtoMessage:newZoneFriendBatchRemoveFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin_list = {},
    change_friend_role = {}
  }
end

function ProtoMessage:newZoneFriendGetRecommendFriendListReq()
  return {count = nil, source = nil}
end

function ProtoMessage:newZoneFriendGetRecommendFriendListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    recommend_player_list = {}
  }
end

function ProtoMessage:newZoneInviteFriendReq()
  return {friend_uin = nil}
end

function ProtoMessage:newZoneInviteFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetSignedCommArkReq()
  return {business_type = nil}
end

function ProtoMessage:newZoneGetSignedCommArkRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    business_type = nil,
    signed_ark = nil
  }
end

function ProtoMessage:newZoneSceneModifyGuideLogicStatusReq()
  return {
    op = ProtoMessage:newLogicStatusOpInfo()
  }
end

function ProtoMessage:newZoneSceneModifyGuideLogicStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAddPetRecordReq()
  return {
    base_id = nil,
    reason = ProtoEnum.ZoneAddPetRecordReq.Reason.UNKOWN,
    npc_actor_id = nil
  }
end

function ProtoMessage:newZoneAddPetRecordRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAddPetRecordAndShareReq()
  return {base_id = nil}
end

function ProtoMessage:newZoneAddPetRecordAndShareRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivitySelectTrackContentsReq()
  return {
    pet_base_id = {},
    track_content_ids = {},
    cancel_trace = nil
  }
end

function ProtoMessage:newZoneActivitySelectTrackContentsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    npc_trace_info = ProtoMessage:newNpcTraceInfo()
  }
end

function ProtoMessage:newZoneChatGetChatListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    chat_session_list = {},
    first_chat_session_uin = nil,
    first_chat_message_list = {},
    pack_index = nil,
    is_end = nil,
    req_uin = nil
  }
end

function ProtoMessage:newZoneChatSendChatMessageReq()
  return {
    uin = nil,
    chat_message = nil,
    visit_owner_uin = nil
  }
end

function ProtoMessage:newZoneChatSendChatMessageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    chat_message = ProtoMessage:newChatMessageInfo(),
    recv_uin = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneChatUpdateChatInfoNotify()
  return {
    chat_message = ProtoMessage:newChatMessageInfo(),
    chat_session = ProtoMessage:newChatSessionInfo()
  }
end

function ProtoMessage:newZoneChatRemoveChatListReq()
  return {uin = nil}
end

function ProtoMessage:newZoneChatRemoveChatListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil
  }
end

function ProtoMessage:newZoneChatGetChatMessageReq()
  return {
    uin = nil,
    offset = nil,
    count = nil,
    visit_owner_uin = nil
  }
end

function ProtoMessage:newZoneChatGetChatMessageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    chat_message_list = {},
    uin = nil,
    offset = nil,
    count = nil,
    all_msg_fetched = nil
  }
end

function ProtoMessage:newZoneEraseRedPointReq()
  return {
    point_group = {}
  }
end

function ProtoMessage:newZoneEraseRedPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneDungeonInfoQueryReq()
  return {dungeon_cfg_id = nil}
end

function ProtoMessage:newZoneSceneDungeonInfoQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    dungeon_state = nil,
    collections = {}
  }
end

function ProtoMessage:newCollectionInfo()
  return {collecttion_type = nil, collection_num = nil}
end

function ProtoMessage:newZoneSceneKickOutVisitReq()
  return {kick_out_uin = nil}
end

function ProtoMessage:newZoneSceneKickOutVisitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneExitVisitReq()
  return {}
end

function ProtoMessage:newZoneSceneExitVisitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneDisbandVisitReq()
  return {}
end

function ProtoMessage:newZoneSceneDisbandVisitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneVisitNetworkSyncReq()
  return {}
end

function ProtoMessage:newZoneSceneVisitNetworkSyncRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneQueryVisitorInfoReq()
  return {}
end

function ProtoMessage:newZoneQueryVisitorInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    visitor_infos = {}
  }
end

function ProtoMessage:newZoneUnlockPetHabitReq()
  return {group_id = nil, group_num = nil}
end

function ProtoMessage:newZoneUnlockPetHabitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetBattlePassInfoReq()
  return {}
end

function ProtoMessage:newZoneGetBattlePassInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    battle_pass_info = ProtoMessage:newPlayerBattlePassInfo(),
    battle_pass_brief_info = ProtoMessage:newPlayerBattlePassBriefInfo()
  }
end

function ProtoMessage:newZoneSelectBattlePassThemeReq()
  return {theme_id = nil}
end

function ProtoMessage:newZoneSelectBattlePassThemeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    battle_pass_info = ProtoMessage:newPlayerBattlePassInfo()
  }
end

function ProtoMessage:newZoneGetSelectAnotherBattlePassThemeFriendsReq()
  return {is_get_detail = nil, theme_id = nil}
end

function ProtoMessage:newSelectBattlePassThemeFriendsInfo()
  return {theme_id = nil, friend_num = nil}
end

function ProtoMessage:newZoneGetSelectAnotherBattlePassThemeFriendsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    friend_role_list = {},
    pack_index = nil,
    is_end = nil,
    friend_info = ProtoMessage:newSelectBattlePassThemeFriendsInfo()
  }
end

function ProtoMessage:newZoneReceiveBattlePassAllTaskReq()
  return {}
end

function ProtoMessage:newZoneReceiveBattlePassAllTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    task_info_list = {}
  }
end

function ProtoMessage:newZoneReceiveBattlePassRewardReq()
  return {receive_all_reward = nil, index = nil}
end

function ProtoMessage:newZoneReceiveBattlePassRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    battle_pass_info = ProtoMessage:newPlayerBattlePassInfo()
  }
end

function ProtoMessage:newZoneClientOperationReq()
  return {
    operation = ProtoMessage:newClientOperation()
  }
end

function ProtoMessage:newZoneClientOperationRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetHatchStatusReq()
  return {egg_gid = nil}
end

function ProtoMessage:newZoneGetHatchStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    hatched_secs = nil
  }
end

function ProtoMessage:newZoneGetAllHatchStatusReq()
  return {}
end

function ProtoMessage:newZoneGetAllHatchStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    egg_gid = {},
    hatched_secs = {}
  }
end

function ProtoMessage:newZoneStopHatchReq()
  return {egg_gid = nil}
end

function ProtoMessage:newZoneStopHatchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSetPlayerNameReq()
  return {name = nil}
end

function ProtoMessage:newZoneSetPlayerNameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    name = nil,
    last_name_changed_time = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardIconReq()
  return {icon_id = nil}
end

function ProtoMessage:newZoneSetPlayerCardIconRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardSkinReq()
  return {skin_id = nil}
end

function ProtoMessage:newZoneSetPlayerCardSkinRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneUpgradePlayerCardSkinReq()
  return {skin_id = nil}
end

function ProtoMessage:newZoneUpgradePlayerCardSkinRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo(),
    skin_id = nil
  }
end

function ProtoMessage:newZoneSetPlayerCardLabelReq()
  return {label_first_id = nil, label_last_id = nil}
end

function ProtoMessage:newZoneSetPlayerCardLabelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardSignatureReq()
  return {signature = nil}
end

function ProtoMessage:newZoneSetPlayerCardSignatureRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneGetPlayerCardInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPlayerCardInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_card_info = ProtoMessage:newPlayerCardInfo(),
    player_card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneGetPlayerCardBriefInfoReq()
  return {
    uin = nil,
    source = ProtoEnum.ZoneGetPlayerCardBriefInfoReq.GetSource.FRIEND
  }
end

function ProtoMessage:newZoneGetPlayerCardBriefInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_card_brief_info = ProtoMessage:newPlayerCardBriefInfo(),
    note = nil,
    is_friend = nil,
    is_black_role = nil,
    online = nil,
    register_timestamp = nil,
    pinned_time = nil,
    friend_type = nil,
    plat_nick_name = nil,
    start_up_privilege_info = ProtoMessage:newPlayerStartUpPrivilegeInfo(),
    topic_point = nil
  }
end

function ProtoMessage:newZoneSetPlayerCardFavoritePetInfoReq()
  return {
    skill_dam_type = ProtoEnum.SkillDamType.SDT_INVALID,
    pet_base_id = nil,
    mutation_diff_type = ProtoEnum.MutationDiffType.MDT_NONE
  }
end

function ProtoMessage:newZoneSetPlayerCardFavoritePetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardCollectPetInfoReq()
  return {
    card_module_id = nil,
    collect_pet_info = {}
  }
end

function ProtoMessage:newZoneSetPlayerCardCollectPetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardCollectFashionInfoReq()
  return {
    card_module_id = nil,
    collect_fashion_info = {}
  }
end

function ProtoMessage:newZoneSetPlayerCardCollectFashionInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    card_brief_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZonePlayerShareInfoReq()
  return {
    share_base_id = nil,
    share_part_id = nil,
    opt = nil,
    activity_id = nil
  }
end

function ProtoMessage:newZonePlayerShareInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward_received = nil,
    opt = nil,
    share_url = nil
  }
end

function ProtoMessage:newZoneCrackEggReq()
  return {
    egg_gid = nil,
    select_ball_gid = nil,
    select_glass_color = nil,
    select_glass_particle = nil
  }
end

function ProtoMessage:newZoneCrackEggRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    hatched_pet_gid = nil
  }
end

function ProtoMessage:newZoneGmClearDungeonReq()
  return {dungeon_cfg_id = nil}
end

function ProtoMessage:newZoneGmClearDungeonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneRandomSubTaskNotify()
  return {
    sub_task_id = {}
  }
end

function ProtoMessage:newZoneOpenSubTaskReq()
  return {sub_task_id = nil}
end

function ProtoMessage:newZoneOpenSubTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSetSubTaskTokenReq()
  return {
    action = {}
  }
end

function ProtoMessage:newSetSubTaskTokenAction()
  return {
    sub_task_id = nil,
    task_token_owned_info = {}
  }
end

function ProtoMessage:newZoneSetSubTaskTokenRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetSubTaskReq()
  return {}
end

function ProtoMessage:newZoneGetSubTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    sub_task_id = {},
    last_get_time = nil
  }
end

function ProtoMessage:newZoneStartPetTravelReq()
  return {
    camp_content_id = nil,
    pet_gid = {},
    travel_lv = nil
  }
end

function ProtoMessage:newZoneStartPetTravelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneCompletePetTravelReq()
  return {camp_content_id = nil}
end

function ProtoMessage:newZoneCompletePetTravelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneRecallPetTravelReq()
  return {camp_content_id = nil}
end

function ProtoMessage:newZoneRecallPetTravelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetPetTravelInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPetTravelInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    travel_info = {}
  }
end

function ProtoMessage:newZoneCompleteAllPetTravelReq()
  return {}
end

function ProtoMessage:newZoneCompleteAllPetTravelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    travel_info = {}
  }
end

function ProtoMessage:newZoneStartAllPetTravelAgainReq()
  return {
    travel_info = {}
  }
end

function ProtoMessage:newZoneStartAllPetTravelAgainRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    travel_info = {}
  }
end

function ProtoMessage:newZoneGetTaskTokenOwnedInfoReq()
  return {}
end

function ProtoMessage:newZoneGetTaskTokenOwnedInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    task_token_owned_data = {}
  }
end

function ProtoMessage:newTaskTokenOwnedData()
  return {
    task_token_id = nil,
    task_token_get_time = nil,
    sub_task_id = nil,
    is_locked = nil
  }
end

function ProtoMessage:newZoneGetOngoingSubTaskInfoReq()
  return {sub_task_id = nil}
end

function ProtoMessage:newZoneGetOngoingSubTaskInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ongoing_sub_task_info = ProtoMessage:newPlayerSubTaskInfo_OngoingSubTaskInfo()
  }
end

function ProtoMessage:newZoneSceneSetOwlSanctuaryFruitReq()
  return {
    content_id = nil,
    fruit_data = {}
  }
end

function ProtoMessage:newZoneSceneSetOwlSanctuaryFruitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetOwlSanctuaryFruitInfoReq()
  return {content_id = nil}
end

function ProtoMessage:newZoneGetOwlSanctuaryFruitInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    owl_sanctuary_fruit_info = ProtoMessage:newOwlSanctuaryFruitInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattleInfoQueryReq()
  return {npc_logic_id = nil, query_source = nil}
end

function ProtoMessage:newZoneSceneTeamBattleInfoQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_battle_info = ProtoMessage:newTeamBattleInfo(),
    query_source = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleChallengeReq()
  return {
    npc_obj_id = nil,
    npc_logic_id = nil,
    challenge_type = nil,
    battle_cfg_id = nil,
    cancel_current_match = nil,
    blood_type = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    visitors = {},
    challenge_type = nil,
    mate_infos = {},
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattleConfirmInviteReq()
  return {agree = nil, challenge_type = nil}
end

function ProtoMessage:newZoneSceneTeamBattleConfirmInviteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattlePrepareReq()
  return {prepare = nil}
end

function ProtoMessage:newZoneSceneTeamBattlePrepareRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    prepare = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleUpdatePetReq()
  return {new_pet_gid = nil, team_idx = nil}
end

function ProtoMessage:newZoneSceneTeamBattleUpdatePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattlePetQueryReq()
  return {
    to_uin = {},
    to_gid = {}
  }
end

function ProtoMessage:newZoneSceneTeamBattlePetQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_data = {}
  }
end

function ProtoMessage:newZoneSceneTeamBattleCancelReq()
  return {}
end

function ProtoMessage:newZoneSceneTeamBattleCancelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattleStartReq()
  return {
    npc_obj_id = nil,
    npc_logic_id = nil,
    challenge_type = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleStartRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattleQueryReq()
  return {}
end

function ProtoMessage:newZoneSceneTeamBattleQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    flower_logic_id = nil
  }
end

function ProtoMessage:newZoneSceneWorldCombatEnterReq()
  return {
    npc_id = nil,
    npc_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneWorldCombatEnterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneWorldCombatExitReq()
  return {npc_id = nil}
end

function ProtoMessage:newZoneSceneWorldCombatExitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneLeaveWorldCombatAreaReq()
  return {npc_id = nil}
end

function ProtoMessage:newZoneSceneLeaveWorldCombatAreaRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneReEnterWorldCombatAreaReq()
  return {npc_id = nil}
end

function ProtoMessage:newZoneSceneReEnterWorldCombatAreaRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneSyncStaminaReq()
  return {stamina = nil, time_stamp = nil}
end

function ProtoMessage:newZoneSceneSyncStaminaRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    server_stamina = nil,
    server_stamina_max = nil,
    stamina_state = nil
  }
end

function ProtoMessage:newZoneSceneGetStaminaInfoReq()
  return {}
end

function ProtoMessage:newZoneSceneGetStaminaInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    server_stamina = nil,
    server_stamina_max = nil,
    stamina_state = nil
  }
end

function ProtoMessage:newZoneSceneUnstuckTeleportReq()
  return {ignore_cooldown = nil}
end

function ProtoMessage:newZoneSceneUnstuckTeleportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    cooldown = nil
  }
end

function ProtoMessage:newZonePetPerceivingReq()
  return {gid = nil, is_begin = nil}
end

function ProtoMessage:newZonePetPerceivingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneBeastStartMatchReq()
  return {
    battle_cfg_id = nil,
    beast_logic_id = nil,
    beast_obj_id = nil
  }
end

function ProtoMessage:newZoneSceneBeastStartMatchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    result = nil,
    start_match_time = nil,
    beast_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneBeastJoinVisitReq()
  return {
    agree = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneBeastJoinVisitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    agree = nil
  }
end

function ProtoMessage:newZoneSceneBeastCancelMatchReq()
  return {}
end

function ProtoMessage:newZoneSceneBeastCancelMatchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneQueryBeastChallengeReq()
  return {npc_obj_id = nil, npc_logic_id = nil}
end

function ProtoMessage:newZoneSceneQueryBeastChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    resonance_infos = {},
    select_star = nil,
    available_challenge_num_via_star = nil,
    available_challenge_num_via_star_max = nil
  }
end

function ProtoMessage:newZoneSceneQuitBeastCatchReq()
  return {npc_obj_id = nil, npc_logic_id = nil}
end

function ProtoMessage:newZoneSceneQuitBeastCatchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneReentrantBeastCatchReq()
  return {npc_logic_id = nil, npc_obj_id = nil}
end

function ProtoMessage:newZoneSceneReentrantBeastCatchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneTeamBattleSelectPetReq()
  return {select_state = nil}
end

function ProtoMessage:newZoneSceneTeamBattleSelectPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetPlayerTeachInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPlayerTeachInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    teach_infos = {}
  }
end

function ProtoMessage:newZoneSetPlayerTeachReadedReq()
  return {teach_id = nil}
end

function ProtoMessage:newZoneSetPlayerTeachReadedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePlayerTeachUnlockNotify()
  return {teach_id = nil}
end

function ProtoMessage:newZonePkSelectPetReq()
  return {pet_gid = nil}
end

function ProtoMessage:newZonePkSelectPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePkCancelPrepareReq()
  return {}
end

function ProtoMessage:newZonePkCancelPrepareRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePkExitReq()
  return {}
end

function ProtoMessage:newZonePkExitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePvpHisQueryReq()
  return {}
end

function ProtoMessage:newZonePvpHisQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    his = {},
    win_count = nil,
    lose_count = nil
  }
end

function ProtoMessage:newRewardInfo()
  return {
    id = nil,
    reward_id = nil,
    received = nil,
    available = nil,
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newTopMasterInfo()
  return {
    type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE,
    prev_type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE,
    next_type = ProtoEnum.PVP_RANK_MASTER_TYPE.PVP_RANK_MASTER_TYPE_NONE
  }
end

function ProtoMessage:newZonePvpInfoQueryReq()
  return {whole_trial_pets = nil}
end

function ProtoMessage:newZonePvpInfoQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    step = ProtoEnum.PVP_RANK_STEP.STEP_PK,
    step_finish_ut = nil,
    pvp_rank_star = nil,
    pvp_rank_order = nil,
    star_reward = {},
    week_reward = {},
    week_refresh_ut = nil,
    week_win_count = nil,
    week_win_count_required = nil,
    trial_pet = ProtoMessage:newTrialPet(),
    pvp_week_benefit = nil,
    top_master = ProtoMessage:newTopMasterInfo(),
    prev_season_star = nil,
    daily_first_win_time = nil
  }
end

function ProtoMessage:newZoneGetPvpRankWeekTaskRewardReq()
  return {
    id = {}
  }
end

function ProtoMessage:newZoneGetPvpRankWeekTaskRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = {}
  }
end

function ProtoMessage:newZoneGetPvpRankSeasonRewardReq()
  return {
    rank_star = {}
  }
end

function ProtoMessage:newZoneGetPvpRankSeasonRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward = {}
  }
end

function ProtoMessage:newZoneQueryPvpRankSeasonInfoReq()
  return {season_id = nil}
end

function ProtoMessage:newZoneQueryPvpRankSeasonInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    rank_season_info = ProtoMessage:newRankSeasonInfo()
  }
end

function ProtoMessage:newZonePlayerOpenActivityReq()
  return {activity_id = nil}
end

function ProtoMessage:newZonePlayerOpenActivityRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newActivityBriefInfo()
  return {
    activity_id = nil,
    activity_name = nil,
    maintab_id = nil,
    priority = nil,
    popup_played = nil
  }
end

function ProtoMessage:newZoneGetPlayerActivityInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPlayerActivityInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    login_days = nil,
    activity_brief_info = {},
    login_history = ProtoMessage:newPlayerActivityLoginHistory()
  }
end

function ProtoMessage:newZoneGetPlayerActivityDataReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetPlayerActivityDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_data = ProtoMessage:newPlayerActivityInfo_ActivityData()
  }
end

function ProtoMessage:newZonePlayerActivityDataChangeNty()
  return {
    activity_data = ProtoMessage:newPlayerActivityInfo_ActivityData()
  }
end

function ProtoMessage:newZoneGetPlayerActivityHistoryDataReq()
  return {
    activity_type = ProtoEnum.ActivityType.ATP_ACTIVITY_SPECIAL
  }
end

function ProtoMessage:newZoneGetPlayerActivityHistoryDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_data = {}
  }
end

function ProtoMessage:newZoneAddPlayerActivityPartRewardReq()
  return {activity_id = nil, activity_part_id = nil}
end

function ProtoMessage:newZoneAddPlayerActivityPartRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityPartRewardReq()
  return {activity_id = nil, activity_part_id = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityPartRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityConditionRewardReq()
  return {activity_id = nil, activity_part_id = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityConditionRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivitySeasonCheckinRewardReq()
  return {
    activity_id = nil,
    activity_reward_index = nil,
    activity_reward_indexs = {}
  }
end

function ProtoMessage:newZoneReceivePlayerActivitySeasonCheckinRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityStageRewardReq()
  return {
    activity_id = nil,
    activity_stage_id = nil,
    stage_index = {}
  }
end

function ProtoMessage:newZoneReceivePlayerActivityStageRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityDisposableRewardReq()
  return {activity_id = nil, activity_stage_id = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityDisposableRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward_id = nil
  }
end

function ProtoMessage:newZoneReceivePlayerActivityPetCatchRewardReq()
  return {
    activity_id = nil,
    point_index = {}
  }
end

function ProtoMessage:newZonePlayerBattlePassInfoNotify()
  return {
    battle_pass_info = ProtoMessage:newPlayerBattlePassInfo()
  }
end

function ProtoMessage:newZonePlayerBattlePassExpNotify()
  return {level = nil, exp = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityPetCatchRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePlayerNewActivityRewardNotify()
  return {
    activity_id = nil,
    activity_reward_id = nil,
    activity_stage_id = nil
  }
end

function ProtoMessage:newZoneActivityPetTripAddPetReq()
  return {
    activity_id = nil,
    pet_gids = {}
  }
end

function ProtoMessage:newZoneActivityPetTripAddPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPetTripAutoTripReq()
  return {activity_id = nil, auto_trip = nil}
end

function ProtoMessage:newZoneActivityPetTripAutoTripRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPetTripSetWishChoiceReq()
  return {activity_id = nil, wish_choice = nil}
end

function ProtoMessage:newZoneActivityPetTripSetWishChoiceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPetTripGetWishChoiceCountReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityPetTripGetWishChoiceCountRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    wish_choice_counts = {}
  }
end

function ProtoMessage:newWishChoiceCountInfo()
  return {wish_choice = nil, count = nil}
end

function ProtoMessage:newZoneSceneReportAvatarAroundNpcReq()
  return {
    npc_obj_id = nil,
    npc_logic_id = nil,
    enter = nil
  }
end

function ProtoMessage:newZoneSceneReportAvatarAroundNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneAiReportReq()
  return {
    npc_obj_id = nil,
    report_type = nil,
    ai_seq_id = nil,
    client_point = ProtoMessage:newPoint(),
    attack_obj_id = nil,
    dialog_id = nil,
    report_list = {}
  }
end

function ProtoMessage:newZoneSceneAiReportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ai_seq_id = nil
  }
end

function ProtoMessage:newZoneMarqueePlayNotify()
  return {
    content = nil,
    stop_time = nil,
    priority = ProtoEnum.MarqueePriorityType.MARQUEE_PRIORITY_LOW
  }
end

function ProtoMessage:newZoneSetPlayerCardAppearanceInfoReq()
  return {
    appearance_info = ProtoMessage:newPlayerCardBriefInfo_AppearanceInfo()
  }
end

function ProtoMessage:newZoneSetPlayerCardAppearanceInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneScenePerceivingNpcReq()
  return {
    npc_ids = {}
  }
end

function ProtoMessage:newZoneScenePerceivingNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneNewFashionSuitNotify()
  return {fashion_suit_id = nil}
end

function ProtoMessage:newZoneCheckVisualItemUpgradeRedPointReq()
  return {}
end

function ProtoMessage:newZoneCheckVisualItemUpgradeRedPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneCheckStoragePetReq()
  return {
    pet_gids = {}
  }
end

function ProtoMessage:newZoneCheckStoragePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    can_evolve_pets = {},
    can_breakthrough_pets = {},
    evolve_pets = {}
  }
end

function ProtoMessage:newEvolvePet()
  return {pet_gid = nil, evolve_id = nil}
end

function ProtoMessage:newZoneUnlockTeachConditionReq()
  return {
    client_trigger = ProtoEnum.TeachClientTrigger.CT_HIDE_UI
  }
end

function ProtoMessage:newZoneUnlockTeachConditionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneUpdatePetCollectTagReq()
  return {
    collection_info = {}
  }
end

function ProtoMessage:newCollectionInfo()
  return {
    pet_gid = nil,
    is_collect = nil,
    partner_mark = ProtoEnum.PetPartnerMarkType.PPMT_NONE
  }
end

function ProtoMessage:newZoneUpdatePetCollectTagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneMageBookQueryReq()
  return {}
end

function ProtoMessage:newZoneMageBookQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    data = ProtoMessage:newPlayerMageBookInfo()
  }
end

function ProtoMessage:newZoneMageBookAwardReq()
  return {npc_id = nil}
end

function ProtoMessage:newZoneMageBookAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAddPlayerActivityPartRewardNty()
  return {activity_id = nil, activity_part_id = nil}
end

function ProtoMessage:newZoneGetBagItemInfoByPageReq()
  return {page = nil, version = nil}
end

function ProtoMessage:newZoneGetBagItemInfoByPageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    total_page = nil,
    req_page = nil,
    bag_info = ProtoMessage:newPlayerBagInfo(),
    page_num = nil,
    version = nil,
    no_new_data = nil
  }
end

function ProtoMessage:newZoneGetPetInfoByPageReq()
  return {page = nil, version = nil}
end

function ProtoMessage:newZoneGetPetInfoByPageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    total_page = nil,
    req_page = nil,
    pet_info = ProtoMessage:newPetDataInfoList(),
    page_num = nil,
    version = nil,
    no_new_data = nil
  }
end

function ProtoMessage:newZoneGetPetInfoByGidReq()
  return {
    gids = {}
  }
end

function ProtoMessage:newZoneGetPetInfoByGidRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    not_exist_gids = {},
    pet_list = ProtoMessage:newPetDataInfoList()
  }
end

function ProtoMessage:newZoneClientReportData2Req()
  return {report_data = nil, type = nil}
end

function ProtoMessage:newZoneClientReportData2Rsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneClientReportDataReq()
  return {
    report_data = nil,
    type = nil,
    send_type = nil,
    battle_id = nil
  }
end

function ProtoMessage:newZoneClientReportDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReportDataSend2Client()
  return {report_data = nil, type = nil}
end

function ProtoMessage:newZoneClientReportLightFeatureReq()
  return {report_data = nil}
end

function ProtoMessage:newZoneClientReportLightFeatureRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneClientReportNpcForAreaReq()
  return {
    npc_obj_id = {},
    is_enter = nil
  }
end

function ProtoMessage:newZoneClientReportNpcForAreaRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTaskReadedReq()
  return {task_id = nil}
end

function ProtoMessage:newZoneTaskReadedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBookDataQueryReq()
  return {
    book_type = ProtoEnum.TaleTaskType.TTT_NONE
  }
end

function ProtoMessage:newZoneBookDataQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    book_datas = {}
  }
end

function ProtoMessage:newZoneBookDataChangeNty()
  return {
    is_new = nil,
    book_data = ProtoMessage:newBookData()
  }
end

function ProtoMessage:newZoneSetBookReadedReq()
  return {
    book_type = ProtoEnum.TaleTaskType.TTT_NONE,
    book_id = nil
  }
end

function ProtoMessage:newZoneSetBookReadedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBookGetRewardReq()
  return {
    book_type = ProtoEnum.TaleTaskType.TTT_NONE,
    book_id = nil
  }
end

function ProtoMessage:newZoneBookGetRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneCancelPlayerTransformReq()
  return {
    cancel_reason = nil,
    transform_avatar = nil,
    eagle_uin = nil
  }
end

function ProtoMessage:newZoneSceneCancelPlayerTransformRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneCheckNameReq()
  return {name = nil}
end

function ProtoMessage:newZoneCheckNameRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneApplyMusicReq()
  return {
    apply_info = ProtoMessage:newMusicApplyInfo()
  }
end

function ProtoMessage:newZoneApplyMusicRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetCreditScoreReq()
  return {
    openid = nil,
    account_type = nil,
    need_response = nil
  }
end

function ProtoMessage:newZoneGetCreditScoreRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    score = nil,
    tag_black = nil,
    tag_ugc = nil
  }
end

function ProtoMessage:newZoneSelectLimitedFlowerSeedPetReq()
  return {spec_flower_seed_id = nil, activity_id = nil}
end

function ProtoMessage:newZoneSelectLimitedFlowerSeedPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetLimitedFlowerSeedInfoReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetLimitedFlowerSeedInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    limited_flower_seed_info = ProtoMessage:newPlayerLimitedFlowerSeedInfo()
  }
end

function ProtoMessage:newZoneUnsetMusicReq()
  return {music_id = nil}
end

function ProtoMessage:newZoneUnsetMusicRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneQueryBalanceReq()
  return {
    token_info = ProtoMessage:newClientTokenInfo()
  }
end

function ProtoMessage:newZoneQueryBalanceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    money_info = ProtoMessage:newMidasMoneyInfo()
  }
end

function ProtoMessage:newZoneBuyGoodsByMidasReq()
  return {
    goods_id = nil,
    type = nil,
    token_info = ProtoMessage:newClientTokenInfo(),
    shop_id = nil,
    version = nil
  }
end

function ProtoMessage:newZoneBuyGoodsByMidasRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    app_meta_data = nil,
    token = nil,
    url_param = nil,
    goods_id = nil,
    midas_goods_id = nil,
    type = nil,
    shop_id = nil,
    shop_data = ProtoMessage:newShopData(),
    create_time = nil
  }
end

function ProtoMessage:newZoneGetPlayerShinyPetDayInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPlayerShinyPetDayInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    info = ProtoMessage:newPlayerShinyPetDayInfo()
  }
end

function ProtoMessage:newZonePlayerShinyPetDayInfoChangeNty()
  return {
    info = ProtoMessage:newPlayerShinyPetDayInfo()
  }
end

function ProtoMessage:newZonePlayerEnterOrLeaveTreasureHuntAreaNty()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    is_enter = nil
  }
end

function ProtoMessage:newZoneGetMobileVeriCodeReq()
  return {
    op_type = ProtoEnum.MobileOpType.BIND,
    mobile_num = nil
  }
end

function ProtoMessage:newZoneGetMobileVeriCodeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mobile_bind_info = ProtoMessage:newPlayerMobileBindData()
  }
end

function ProtoMessage:newZoneMobileOpReq()
  return {
    op_type = ProtoEnum.MobileOpType.BIND,
    mobile_num = nil,
    veri_code = nil,
    unbind_all_scenes = nil
  }
end

function ProtoMessage:newZoneMobileOpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mobile_bind_info = ProtoMessage:newPlayerMobileBindData()
  }
end

function ProtoMessage:newZoneGetMobileBindInfoReq()
  return {}
end

function ProtoMessage:newZoneGetMobileBindInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mask_mobile_num = nil,
    uin = nil,
    openid = nil,
    bind_flag = nil,
    local_mobile_num = nil,
    bind_use_sms_with_btn = nil,
    unbind = nil,
    unbind_game_confirmation = nil,
    unbind_game_result = nil,
    unbind_channel_confirmation = nil,
    unbind_channel_result = nil,
    unbind_confirmation = nil,
    unbind_result = nil
  }
end

function ProtoMessage:newZoneGetMobileBindingRewardReq()
  return {}
end

function ProtoMessage:newZoneGetMobileBindingRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mobile_bind_info = ProtoMessage:newPlayerMobileBindData()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityShinyPetDayRewardReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityShinyPetDayRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceiveActivityCoCreationRewardReq()
  return {activity_id = nil, is_task_reward = nil}
end

function ProtoMessage:newZoneReceiveActivityCoCreationRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSupplyActivityCoCreationRewardReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneSupplyActivityCoCreationRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivitySetCoCreationEmojReq()
  return {
    activity_id = nil,
    emoj_id = nil,
    is_cancel = nil
  }
end

function ProtoMessage:newZoneActivitySetCoCreationEmojRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    emoj_info = ProtoMessage:newActivityCoCreationEmojInfo(),
    emoj_list = {}
  }
end

function ProtoMessage:newZoneActivityGetCoCreationEmojReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityGetCoCreationEmojRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    emoj_info = ProtoMessage:newActivityCoCreationEmojInfo(),
    emoj_list = {}
  }
end

function ProtoMessage:newZoneReceiveActivityConditionGroupRewardReq()
  return {
    activity_id = nil,
    group_id = nil,
    condition_id = nil
  }
end

function ProtoMessage:newZoneReceiveActivityConditionGroupRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityShinyPetDayPetalReq()
  return {}
end

function ProtoMessage:newZoneReceivePlayerActivityShinyPetDayPetalRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceivePlayerActivityTreasureHuntRewardReq()
  return {activity_id = nil, activity_sub_id = nil}
end

function ProtoMessage:newZoneReceivePlayerActivityTreasureHuntRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceiveShopTotalConsumptionRewardReq()
  return {shop_id = nil, reward_level = nil}
end

function ProtoMessage:newZoneReceiveShopTotalConsumptionRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneReceiveGpContestRewardReq()
  return {final = nil, seq = nil}
end

function ProtoMessage:newZoneReceiveGpContestRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetPlayerGpContestInfoReq()
  return {}
end

function ProtoMessage:newZoneGetPlayerGpContestInfoRsp()
  return {
    gp_contest_info = ProtoMessage:newPlayerGPContestInfo(),
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAckReceiveDungeonFinishReq()
  return {
    dungeon_cfg_id = nil,
    stage_cfg_ids = {}
  }
end

function ProtoMessage:newZoneAckReceiveDungeonFinishRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneMonthCardGetInfoReq()
  return {}
end

function ProtoMessage:newZoneMonthCardGetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    month_data = ProtoMessage:newMonthCardData()
  }
end

function ProtoMessage:newZoneMonthCardGetInfoNty()
  return {
    month_data = ProtoMessage:newMonthCardData()
  }
end

function ProtoMessage:newZoneGetCosUploadUrlReq()
  return {
    type = nil,
    file_name = nil,
    file_size = nil,
    file_md5 = nil,
    battle_id = nil,
    client_version = nil
  }
end

function ProtoMessage:newZoneGetCosUploadUrlRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    url = nil,
    type = nil,
    file_name = nil,
    gen_filename = nil,
    access_url = nil
  }
end

function ProtoMessage:newZoneGetCosSignatureReq()
  return {}
end

function ProtoMessage:newZoneGetCosSignatureRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    signature = nil
  }
end

function ProtoMessage:newZoneQueryPlayerSettingsReq()
  return {}
end

function ProtoMessage:newZoneQueryPlayerSettingsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    settings = ProtoMessage:newPlayerSettings()
  }
end

function ProtoMessage:newZoneModifyPlayerSettingsReq()
  return {
    settings = ProtoMessage:newPlayerSettings()
  }
end

function ProtoMessage:newZoneModifyPlayerSettingsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChallengeCreateBattleReq()
  return {
    source_data = ProtoMessage:newSourceData(),
    avatar_pt = ProtoMessage:newPoint(),
    use_big_world_team = nil,
    dungeon_id = nil,
    priority_pet_gid = nil
  }
end

function ProtoMessage:newZoneChallengeCreateBattleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneExitChallengeReq()
  return {stay_dungeon = nil}
end

function ProtoMessage:newZoneExitChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChallengeStarRewardReq()
  return {activity_id = nil, star_num = nil}
end

function ProtoMessage:newZoneChallengeStarRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChallengeSetBuffReq()
  return {activity_id = nil, buff_rule_id = nil}
end

function ProtoMessage:newZoneChallengeSetBuffRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    buff_rule_id = nil
  }
end

function ProtoMessage:newZoneChallengeSetModuleUnlockReadedReq()
  return {activity_id = nil, module_id = nil}
end

function ProtoMessage:newZoneChallengeSetModuleUnlockReadedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneWeeklyChallengeCreateBattleReq()
  return {
    source_type = ProtoEnum.EClientBattleSourceType.ECBST_NONE,
    activity_id = nil,
    challenge_id = nil,
    avatar_pt = ProtoMessage:newPoint(),
    priority_pet_gid = nil
  }
end

function ProtoMessage:newZoneWeeklyChallengeCreateBattleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneWeeklyChallengeAttrBalanceReq()
  return {activity_id = nil, challenge_id = nil}
end

function ProtoMessage:newZoneWeeklyChallengeAttrBalanceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_need_balance = nil,
    balance_level = nil,
    balance_grow = nil,
    pet_data = {},
    monster_conf_id = {},
    monster_level = {},
    balance_effort = nil
  }
end

function ProtoMessage:newZoneWeeklyChallengePhotoUploadReq()
  return {
    activity_id = nil,
    photo_info = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeDataPhoto(),
    team_id = nil
  }
end

function ProtoMessage:newZoneWeeklyChallengePhotoUploadRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_photo = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeTeam()
  }
end

function ProtoMessage:newZoneWeeklyChallengeHistoryPhotoReq()
  return {}
end

function ProtoMessage:newZoneWeeklyChallengeHistoryPhotoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    history_photos = {}
  }
end

function ProtoMessage:newZoneWeeklyChallengeUpdatePhotoReq()
  return {activity_id = nil, team_id = nil}
end

function ProtoMessage:newZoneWeeklyChallengeUpdatePhotoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_photo = ProtoMessage:newPlayerActivityInfo_ActivityWeeklyChallengeTeam()
  }
end

function ProtoMessage:newZoneReportSafetyDataReq()
  return {
    reported_uin = nil,
    business_data = ProtoMessage:newSafetyBusinessInfo()
  }
end

function ProtoMessage:newZoneReportSafetyDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneNewFashionItemNotify()
  return {
    fashion_item_ids = {},
    is_deduct = nil
  }
end

function ProtoMessage:newZoneNewSalonItemNotify()
  return {
    salon_item_ids = {},
    is_deduct = nil
  }
end

function ProtoMessage:newZoneNewFashionBondNotify()
  return {
    fashion_bond_item = {},
    is_deduct = nil
  }
end

function ProtoMessage:newZoneClaimColorSuitReq()
  return {fashion_bond_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneClaimColorSuitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneColorSuitStateChangeNty()
  return {
    fashion_bond_id = nil,
    color_suit_state = ProtoEnum.FashionBondColorSuitState.FBCSS_LOCKED
  }
end

function ProtoMessage:newZoneClaimGlassTintReq()
  return {
    fashion_bond_id = nil,
    is_shining = nil,
    glass = ProtoMessage:newGlassInfo(),
    fashion_item_id = nil
  }
end

function ProtoMessage:newZoneClaimGlassTintRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    change_to_owned = {}
  }
end

function ProtoMessage:newZoneGlassTintChangeNty()
  return {
    change_to_claimable = {},
    change_to_lock = {}
  }
end

function ProtoMessage:newZoneSceneNpcControlReq()
  return {
    operate_type = nil,
    content_id = nil,
    npc_id = nil,
    point = ProtoMessage:newPoint(),
    skin_id = nil
  }
end

function ProtoMessage:newZoneSceneNpcControlRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    operate_type = nil,
    npc_id = nil
  }
end

function ProtoMessage:newZoneRecallTalentChangeReq()
  return {pet_gid = nil}
end

function ProtoMessage:newZoneRecallTalentChangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSetRandomShopShownIndexesReq()
  return {
    shop_id = nil,
    indexes = {}
  }
end

function ProtoMessage:newZoneSetRandomShopShownIndexesRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBagItemPlayerHasExchangeConcernedNotify()
  return {
    bag_item_id = {}
  }
end

function ProtoMessage:newZoneSetVisitPermissionSettingReq()
  return {permission_type = nil}
end

function ProtoMessage:newZoneSetVisitPermissionSettingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneNewCardIconNotify()
  return {
    card_item_info = ProtoMessage:newPlayerCardInfo_CardItemOwnedInfo()
  }
end

function ProtoMessage:newZoneNewCardSkinNotify()
  return {
    card_item_info = ProtoMessage:newPlayerCardInfo_CardItemOwnedInfo()
  }
end

function ProtoMessage:newZoneNewCardLabelNotify()
  return {
    card_item_info = ProtoMessage:newPlayerCardInfo_CardItemOwnedInfo()
  }
end

function ProtoMessage:newZoneActiveHideOrShowContentReq()
  return {content_id = nil, is_show = nil}
end

function ProtoMessage:newZoneActiveHideOrShowContentRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTryInstantiateNpcReq()
  return {
    content_cfg_id = nil,
    npc_objid = nil,
    taskid = nil,
    traceidx = nil
  }
end

function ProtoMessage:newZoneGuideInfoNotify()
  return {
    guide_info = {}
  }
end

function ProtoMessage:newZoneFinishGuideReq()
  return {
    group_id = nil,
    index = {}
  }
end

function ProtoMessage:newZoneFinishGuideRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    sync_group = ProtoMessage:newGuideGroup()
  }
end

function ProtoMessage:newZoneTryInstantiateNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneClientCaveStateNotify()
  return {
    cave_name = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneClientCaveStateNotifyAck()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneClientCaveStateReq()
  return {
    cave_name = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneClientCaveStateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTaskTeleportReq()
  return {
    teleport_type = nil,
    scene_res_cfg_id = nil,
    to_point = ProtoMessage:newPoint(),
    dungeon_cfg_id = nil,
    task_id = nil
  }
end

function ProtoMessage:newZoneTaskTeleportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneNpcTraceQueryReq()
  return {
    npc_cfg_id = {},
    cancel_trace = nil,
    pet_base_id = {}
  }
end

function ProtoMessage:newZoneNpcTraceQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    npc_trace_info = ProtoMessage:newNpcTraceInfo(),
    pet_base_id = {}
  }
end

function ProtoMessage:newZoneSceneWorldCombatSkillPosLerpSyncReq()
  return {
    actor_id = nil,
    info = ProtoMessage:newWorldCombatDotsSkillPosLerpSyncInfo(),
    allow_wait = nil
  }
end

function ProtoMessage:newZoneSceneWorldCombatSkillPosLerpSyncRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmModifyNpcDataReq()
  return {
    type = nil,
    param1 = nil,
    param2 = nil,
    task_id = nil,
    uin = nil
  }
end

function ProtoMessage:newZoneGmModifyNpcDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeSaveRoomLayoutReq()
  return {
    room_layout_info = ProtoMessage:newRoomLayoutInfo(),
    force_save = nil
  }
end

function ProtoMessage:newZoneSceneHomeSaveRoomLayoutRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    room_layout_info = ProtoMessage:newRoomLayoutInfo()
  }
end

function ProtoMessage:newZoneSceneHomeLoadRoomLayoutReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeLoadRoomLayoutRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    room_layout_info = ProtoMessage:newRoomLayoutInfo()
  }
end

function ProtoMessage:newZoneHomeQueryLevelRewardReq()
  return {}
end

function ProtoMessage:newZoneHomeQueryLevelRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    state = {}
  }
end

function ProtoMessage:newZoneHomeClaimLevelRewardReq()
  return {level = nil}
end

function ProtoMessage:newZoneHomeClaimLevelRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeFurnitureFoldReq()
  return {
    room_id = nil,
    fold_all = nil,
    furniture_info = ProtoMessage:newRoomFurnitureDetails()
  }
end

function ProtoMessage:newZoneHomeFurnitureFoldRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeStartExpandRoomReq()
  return {room_level = nil}
end

function ProtoMessage:newZoneSceneHomeStartExpandRoomRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    room_expansion_info = ProtoMessage:newRoomExpansionInfo()
  }
end

function ProtoMessage:newZoneSceneHomeFinishExpandRoomReq()
  return {room_level = nil}
end

function ProtoMessage:newZoneSceneHomeFinishExpandRoomRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    home_info = ProtoMessage:newHomeInfo()
  }
end

function ProtoMessage:newZoneSceneHomeRenameRoomReq()
  return {room_id = nil, room_name = nil}
end

function ProtoMessage:newZoneSceneHomeRenameRoomRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeEnterEditReq()
  return {is_edit = nil}
end

function ProtoMessage:newZoneSceneHomeEnterEditRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeEnterReq()
  return {
    home_owner_id = nil,
    home_scene_type = ProtoEnum.ZoneSceneHomeEnterReq.HomeSceneType.HomeSceneType_Home,
    world_map_cfg_id = nil
  }
end

function ProtoMessage:newZoneSceneHomeEnterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    home_owner_id = nil
  }
end

function ProtoMessage:newZoneSceneHomeLeaveReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeLeaveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeQueryFriendHomeInfoReq()
  return {uin = nil, query_info_type = nil}
end

function ProtoMessage:newZoneHomeQueryFriendHomeInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    friend_cell_home_brief_info = ProtoMessage:newCellHomeBriefInfo(),
    friend_home_brief_info = ProtoMessage:newPlayerHomeBriefInfo(),
    uin = nil,
    home_feature_opened = nil
  }
end

function ProtoMessage:newZoneSceneHomeGetVistHistoryReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeGetVistHistoryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    visit_history = ProtoMessage:newHomeVisitHistoryInfo()
  }
end

function ProtoMessage:newZoneSceneHomeGetVisitorInfoReq()
  return {home_owner_id = nil}
end

function ProtoMessage:newZoneSceneHomeGetVisitorInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    home_owner_id = nil,
    visitor_info = {}
  }
end

function ProtoMessage:newZoneSceneHomeTeamCreateReq()
  return {
    team_type = ProtoEnum.HomeTeamType.HOME_TEAM_TYPE_NONE,
    world_map_cfg_id = nil
  }
end

function ProtoMessage:newZoneSceneHomeTeamCreateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_info = ProtoMessage:newHomeTeamInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamRespondInviteReq()
  return {
    team_leader_id = nil,
    respond_type = ProtoEnum.HomeTeamRespondType.HOME_TEAM_RESPOND_TYPE_REJECT
  }
end

function ProtoMessage:newZoneSceneHomeTeamRespondInviteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_info = ProtoMessage:newHomeTeamInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamEnterHomeReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeTeamEnterHomeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamLeaveHomeReq()
  return {entry_id = nil, use_special_teleport = nil}
end

function ProtoMessage:newZoneSceneHomeTeamLeaveHomeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamDisbandReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeTeamDisbandRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_info = ProtoMessage:newHomeTeamInfo()
  }
end

function ProtoMessage:newZoneSceneHomeTeamQueryReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeTeamQueryRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    team_info = ProtoMessage:newHomeTeamInfo(),
    team_init_member_count = nil
  }
end

function ProtoMessage:newZoneHomePlantSeedCompoundReq()
  return {seed_id = nil, seed_num = nil}
end

function ProtoMessage:newZoneHomePlantSeedCompoundRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePlantSeedEquipReq()
  return {
    modify_info = {}
  }
end

function ProtoMessage:newHomePlantSeedModifyInfo()
  return {
    gid = nil,
    bag_item_flags = nil,
    item_conf_id = nil,
    plant_tab = nil
  }
end

function ProtoMessage:newZoneHomePlantSeedEquipRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomePlantCropReq()
  return {land_id = nil, seed_gid = nil}
end

function ProtoMessage:newZoneSceneHomePlantCropRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneScenePlayerServerInfoNotify()
  return {
    zonesvr_buspp_inst_id = nil,
    scenesvr_buspp_inst_id = nil,
    battlesvr_buspp_inst_id = nil,
    zone_player_last_sync_time = nil,
    scene_last_update_timestamp_in_us = nil,
    cell_id = nil,
    faketime_offset_in_millis = nil
  }
end

function ProtoMessage:newZoneGetNpcChallengeImageReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetNpcChallengeImageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    npc_challenge_image_info = {}
  }
end

function ProtoMessage:newZoneHomeWarehouseDecompositionReq()
  return {
    target_list = {}
  }
end

function ProtoMessage:newFurnitureInfo()
  return {gid = nil, num = nil}
end

function ProtoMessage:newZoneHomeWarehouseDecompositionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeWarehouseGetBuildListReq()
  return {home_id = nil, need_self_list = nil}
end

function ProtoMessage:newZoneHomeWarehouseGetBuildListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ding_list = {},
    home_list = {},
    next_update_timestamp = nil,
    self_list = {}
  }
end

function ProtoMessage:newZoneHomeWarehouseBuildReq()
  return {bag_item_id = nil, num = nil}
end

function ProtoMessage:newZoneHomeWarehouseBuildRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeClaimUnlockedFurnitureRewardReq()
  return {handbook_id = nil}
end

function ProtoMessage:newZoneHomeClaimUnlockedFurnitureRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeGetUnlockedFurnitureInfoReq()
  return {}
end

function ProtoMessage:newZoneHomeGetUnlockedFurnitureInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    unlocked_furniture_info = ProtoMessage:newHomeUnlockedFurnitureInfo()
  }
end

function ProtoMessage:newZoneHomeGetCraftableFriendListReq()
  return {furniture_id = nil, page = nil}
end

function ProtoMessage:newZoneHomeGetCraftableFriendListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    total_num = nil,
    friend_list = {}
  }
end

function ProtoMessage:newZoneHomePetPlaceReq()
  return {
    pet_gid = nil,
    furniture_guid = nil,
    born_pt = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneHomePetPlaceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    home_pet_info = ProtoMessage:newHomePetInfo()
  }
end

function ProtoMessage:newZoneHomePetUnplaceReq()
  return {
    pet_unplace_info_list = {},
    force = nil
  }
end

function ProtoMessage:newPetUnplaceInfo()
  return {npc_obj_id = nil, furniture_guid = nil}
end

function ProtoMessage:newZoneHomePetUnplaceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    home_pet_info_list = {}
  }
end

function ProtoMessage:newZoneHomePetLoadFoodReq()
  return {item_gid = nil, item_conf_id = nil}
end

function ProtoMessage:newZoneHomePetLoadFoodRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePetReplaceFoodReq()
  return {
    old_item_gid = nil,
    old_item_conf_id = nil,
    new_item_gid = nil,
    new_item_conf_id = nil
  }
end

function ProtoMessage:newZoneHomePetReplaceFoodRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePetUnloadFoodReq()
  return {item_gid = nil, item_conf_id = nil}
end

function ProtoMessage:newZoneHomePetUnloadFoodRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePetFeedReq()
  return {
    npc_obj_id = nil,
    pet_gid = nil,
    bag_item_conf_id = nil,
    bag_item_gid = nil
  }
end

function ProtoMessage:newZoneHomePetFeedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed_info = ProtoMessage:newHomePetFeedInfo()
  }
end

function ProtoMessage:newZoneHomePetFeedCancelReq()
  return {npc_obj_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneHomePetFeedCancelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePetCanStealReq()
  return {npc_obj_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneHomePetCanStealRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    can_steal = nil,
    reason = nil
  }
end

function ProtoMessage:newZoneHomePetStealReq()
  return {npc_obj_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneHomePetStealRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    steal_goods = {},
    pet_gid = nil
  }
end

function ProtoMessage:newZoneHomePetFetchAwardReq()
  return {npc_obj_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneHomePetFetchAwardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    fetch_goods = {}
  }
end

function ProtoMessage:newZoneSetNavigationModeTypeReq()
  return {mode_type = nil}
end

function ProtoMessage:newZoneSetNavigationModeTypeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomePetGuardReq()
  return {
    pet_guard_pids = {}
  }
end

function ProtoMessage:newZoneHomePetGuardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_guard_pids = {}
  }
end

function ProtoMessage:newZoneTaskConditionTriggerReq()
  return {
    condition_type = nil,
    taskid = nil,
    task_condition_idx = nil
  }
end

function ProtoMessage:newZoneTaskConditionTriggerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneStartBadgeChallengeReq()
  return {id = nil}
end

function ProtoMessage:newZoneStartBadgeChallengeRsp()
  return {
    event_infos = {},
    ret_info = ProtoMessage:newRetInfo(),
    remain_coin = nil,
    refresh_need_coin = nil,
    level_infos = {}
  }
end

function ProtoMessage:newZoneSelectBadgeChallengeCardReq()
  return {index = nil}
end

function ProtoMessage:newZoneSelectBadgeChallengeCardRsp()
  return {
    event_infos = {},
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFixedBadgeChallengeCardReq()
  return {index = nil}
end

function ProtoMessage:newZoneFixedBadgeChallengeCardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneCombineBadgeChallengeCardReq()
  return {
    indexes = {}
  }
end

function ProtoMessage:newZoneCombineBadgeChallengeCardRsp()
  return {
    event_infos = {},
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGrassTrialGetInfoReq()
  return {}
end

function ProtoMessage:newZoneGrassTrialGetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    trial_data = ProtoMessage:newGrassTrialData()
  }
end

function ProtoMessage:newZoneGrassTrialStartChallengeReq()
  return {
    trial_conf_id = nil,
    pet_gid = nil,
    initial_skill_id = nil,
    first_dungeon_id = nil
  }
end

function ProtoMessage:newZoneGrassTrialStartChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    challenge_data = ProtoMessage:newGrassTrialChallengeData()
  }
end

function ProtoMessage:newZoneGrassTrialEnterSceneReq()
  return {trial_conf_id = nil, chapter_id = nil}
end

function ProtoMessage:newZoneGrassTrialEnterSceneRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGrassTrialNextNodeReq()
  return {chapter_id = nil, node_index = nil}
end

function ProtoMessage:newZoneGrassTrialNextNodeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    node_selection = ProtoMessage:newGrassTrialNodeSelection()
  }
end

function ProtoMessage:newZoneGrassTrialSelectEventReq()
  return {event_index = nil}
end

function ProtoMessage:newZoneGrassTrialSelectEventRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    battle_id = nil
  }
end

function ProtoMessage:newZoneGrassTrialNodeRefreshReq()
  return {
    node_index = nil,
    slot_index = nil,
    refresh_type = nil
  }
end

function ProtoMessage:newZoneGrassTrialNodeRefreshRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    refresh_type = nil,
    new_selection = ProtoMessage:newGrassTrialNodeSelection(),
    remaining_coin = nil
  }
end

function ProtoMessage:newZoneGrassTrialHandleRewardNotify()
  return {
    event_conf_id = nil,
    reward_id = nil,
    cur_coin = nil
  }
end

function ProtoMessage:newZoneGrassTrialHandleRewardReq()
  return {
    action = nil,
    reward_id = nil,
    target_slot_pos = nil
  }
end

function ProtoMessage:newZoneGrassTrialHandleRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    updated_pet = ProtoMessage:newGrassTrialPet(),
    remaining_coin = nil
  }
end

function ProtoMessage:newZoneGrassTrialPauseChallengeReq()
  return {}
end

function ProtoMessage:newZoneGrassTrialPauseChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGrassTrialResumeChallengeReq()
  return {}
end

function ProtoMessage:newZoneGrassTrialResumeChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    challenge_data = ProtoMessage:newGrassTrialChallengeData()
  }
end

function ProtoMessage:newZoneGrassTrialAbandonChallengeReq()
  return {}
end

function ProtoMessage:newZoneGrassTrialAbandonChallengeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGrassTrialChallengeSettleNotify()
  return {
    review = ProtoMessage:newGrassTrialReviewRecord(),
    total_score = nil,
    weekly_score = nil,
    first_clear = nil
  }
end

function ProtoMessage:newZoneGrassTrialChallengeDataSyncNotify()
  return {
    challenge_data = ProtoMessage:newGrassTrialChallengeData()
  }
end

function ProtoMessage:newZoneFeedMagicCreateReq()
  return {
    uin = nil,
    content = nil,
    create_pos = ProtoMessage:newPosition(),
    ext_info = nil,
    music_id = nil,
    sub_type = nil
  }
end

function ProtoMessage:newZoneFeedMagicCreateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed = ProtoMessage:newZoneMagicFeedInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneFeedMagicFeedbackReq()
  return {
    uin = nil,
    feed_id = nil,
    comment_content = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedMagicFeedbackRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed = ProtoMessage:newZoneMagicFeedInfo(),
    ban_info = ProtoMessage:newBanInfo(),
    comment_info = ProtoMessage:newFeedCommentInfo()
  }
end

function ProtoMessage:newZoneFeedMagicDeleteReq()
  return {
    uin = nil,
    feed_id = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedMagicDeleteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed_id = nil,
    grid_id = nil
  }
end

function ProtoMessage:newZoneFeedMagicAttitudeReq()
  return {
    uin = nil,
    feed_id = nil,
    attitude = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedMagicAttitudeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed = ProtoMessage:newZoneMagicFeedInfo()
  }
end

function ProtoMessage:newZoneFeedCommentAttitudeReq()
  return {
    uin = nil,
    feed_id = nil,
    feedback_id = nil,
    attitude = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedCommentAttitudeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    comment_info = ProtoMessage:newFeedCommentInfo()
  }
end

function ProtoMessage:newZoneFeedHandWritingEnhanceReq()
  return {uin = nil, feed_id = nil}
end

function ProtoMessage:newZoneFeedHandWritingEnhanceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed = ProtoMessage:newZoneMagicFeedInfo()
  }
end

function ProtoMessage:newZoneFeedGetCtrlDataReq()
  return {uin = nil}
end

function ProtoMessage:newZoneFeedGetCtrlDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    data = ProtoMessage:newZoneFeedCtrlData()
  }
end

function ProtoMessage:newZoneFeedGetFeedCommentReq()
  return {
    uin = nil,
    feed_id = nil,
    type = nil,
    page_num = nil
  }
end

function ProtoMessage:newZoneFeedGetFeedCommentRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    comment_info = ProtoMessage:newFeedCommentListData(),
    feed = ProtoMessage:newZoneMagicFeedInfo()
  }
end

function ProtoMessage:newZoneFeedPlayerUninterestedReq()
  return {
    uin = nil,
    feed_id = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedPlayerUninterestedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed_id = nil
  }
end

function ProtoMessage:newZoneFeedFlowerPickupReq()
  return {uin = nil, feed_id = nil}
end

function ProtoMessage:newZoneFeedFlowerPickupRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFeedMagicCommentDeleteReq()
  return {
    uin = nil,
    feed_id = nil,
    feedback_id = nil,
    category = nil
  }
end

function ProtoMessage:newZoneFeedMagicCommentDeleteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed = ProtoMessage:newZoneMagicFeedInfo(),
    feedback_id = nil
  }
end

function ProtoMessage:newZoneFeedVideoBeginReq()
  return {}
end

function ProtoMessage:newZoneFeedVideoBeginRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneFeedVideoGetUploadUrlReq()
  return {
    file_name = nil,
    create_pos = ProtoMessage:newPosition(),
    content = nil
  }
end

function ProtoMessage:newZoneFeedVideoGetUploadUrlRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    file_name = nil,
    upload_url = nil,
    video_upload_info = ProtoMessage:newFeedVideoUploadInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneFeedVideoCreateReq()
  return {
    content = nil,
    create_pos = ProtoMessage:newPosition(),
    file_name = nil,
    file_md5 = nil,
    base_info = ProtoMessage:newFeedVideoBaseInfo(),
    base_info_md5 = nil
  }
end

function ProtoMessage:newZoneFeedVideoCreateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed_info = ProtoMessage:newZoneMagicFeedInfo(),
    feed_video_info = ProtoMessage:newFeedVideoInfo(),
    video_upload_info = ProtoMessage:newFeedVideoUploadInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneGetFeedDetailReq()
  return {feed_id = nil}
end

function ProtoMessage:newZoneGetFeedDetailRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    feed_info = ProtoMessage:newZoneMagicFeedInfo(),
    feed_video_info = ProtoMessage:newFeedVideoInfo()
  }
end

function ProtoMessage:newZoneFeedVideoEndReq()
  return {}
end

function ProtoMessage:newZoneFeedVideoEndRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetSharePetTeamReq()
  return {team_type = nil, team_idx = nil}
end

function ProtoMessage:newZonePetSharePetTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    id = nil,
    team = ProtoMessage:newSharedPetTeamInfo()
  }
end

function ProtoMessage:newZonePetApplySharedPetTeamReq()
  return {
    id = nil,
    team_type = nil,
    shared_team = ProtoMessage:newSharedPetTeamInfo()
  }
end

function ProtoMessage:newZonePetApplySharedPetTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shared_team = ProtoMessage:newSharedPetTeamInfo(),
    adjusted_team = ProtoMessage:newAdjustedPetTeamInfo()
  }
end

function ProtoMessage:newZonePetGetAlternativePetsReq()
  return {
    shared_pet = ProtoMessage:newSharedPetInfo(),
    team_type = nil,
    team_mates = {}
  }
end

function ProtoMessage:newZonePetGetAlternativePetsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pets = {}
  }
end

function ProtoMessage:newZonePetTeamShareAutoCompleteTeamReq()
  return {
    team_type = nil,
    shared_team = ProtoMessage:newSharedPetTeamInfo(),
    current_team = ProtoMessage:newAdjustedPetTeamInfo()
  }
end

function ProtoMessage:newZonePetTeamShareAutoCompleteTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    completed_team = ProtoMessage:newAdjustedPetTeamInfo()
  }
end

function ProtoMessage:newZonePetTeamShareQuickAdjustReq()
  return {
    exchange_info = {},
    item_info = {}
  }
end

function ProtoMessage:newExchangeInfo()
  return {
    exchange_id = nil,
    exchange_num = nil,
    cost_goods_id = {}
  }
end

function ProtoMessage:newBagItemInfo()
  return {
    gid = nil,
    num = nil,
    para = nil,
    item_conf_id = nil,
    change_attr_type = {},
    target_type = {},
    change_talent_type = nil,
    result_type = nil,
    para2 = nil
  }
end

function ProtoMessage:newZonePetTeamShareQuickAdjustRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneOpenMagicBookSheetReq()
  return {}
end

function ProtoMessage:newZoneOpenMagicBookSheetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    chapter_id = nil,
    rewarded = nil,
    chapter_task_list = {},
    invest_task_list = {},
    clue_task_list = {},
    topic_task_list = {},
    remain_time = nil,
    special_reward_item = nil
  }
end

function ProtoMessage:newZoneSetTaskRecoverAllReq()
  return {
    bonus_relocate_positions = {}
  }
end

function ProtoMessage:newZoneSetTaskRecoverAllRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneMoveFinishTaskReq()
  return {
    time_stamp = nil,
    to_pos = ProtoMessage:newPosition(),
    scene_cfg_id = nil
  }
end

function ProtoMessage:newZoneMoveFinishTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationInteractInviteReq()
  return {
    target_uin = nil,
    interact_type = ProtoEnum.InteractInviteType.IIT_INVALID,
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE,
    param = ProtoMessage:newInteractParam()
  }
end

function ProtoMessage:newZoneSceneRelationInteractInviteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSceneRelationInteractInterruptReq()
  return {}
end

function ProtoMessage:newZoneSceneRelationInteractInterruptRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationInteractAcceptReq()
  return {
    target_uin = nil,
    interact_type = ProtoEnum.InteractInviteType.IIT_INVALID,
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE,
    param = ProtoMessage:newInteractParam()
  }
end

function ProtoMessage:newZoneSceneRelationInteractAcceptRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    target_uin = nil,
    interact_type = ProtoEnum.InteractInviteType.IIT_INVALID,
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE,
    param = ProtoMessage:newInteractParam(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSceneRelationInteractChangeReq()
  return {
    target_uin = nil,
    interact_type = ProtoEnum.InteractInviteType.IIT_INVALID,
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE
  }
end

function ProtoMessage:newZoneSceneRelationInteractChangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE
  }
end

function ProtoMessage:newZoneSceneRelationInteractEndReq()
  return {
    target_uin = nil,
    interact_type = ProtoEnum.InteractInviteType.IIT_INVALID,
    interact_sub_type = ProtoEnum.RelationInteractSubType.RIST_NONE
  }
end

function ProtoMessage:newZoneSceneRelationInteractEndRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationRecoverBeginReq()
  return {recover_mate_uin = nil}
end

function ProtoMessage:newZoneSceneRelationRecoverBeginRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationRecoverEndReq()
  return {}
end

function ProtoMessage:newZoneSceneRelationRecoverEndRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationRecoverModifyBuffReq()
  return {buff_val = nil}
end

function ProtoMessage:newZoneSceneRelationRecoverModifyBuffRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRelationTravelTogetherSyncReq()
  return {
    pos_diff = ProtoMessage:newPosition(),
    report_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneSceneRelationTravelTogetherSyncRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneTogetherTeleportConfirmReq()
  return {together_recover = nil}
end

function ProtoMessage:newZoneSceneTogetherTeleportConfirmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneOpenRelationshipTreeReq()
  return {peer_uin = nil}
end

function ProtoMessage:newZoneOpenRelationshipTreeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    tree_data = ProtoMessage:newRelationshipTreeData(),
    unlock_relation_type = nil,
    peer_battle_state = ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IDLE,
    peer_battle_brief_info = ProtoMessage:newPlayerBattleBriefInfo(),
    peer_info = ProtoMessage:newRelationshipTreePeerInfo()
  }
end

function ProtoMessage:newRelationshipTreePeerInfo()
  return {
    openid = nil,
    uin = nil,
    name = nil,
    note = nil,
    level = nil,
    gender = nil,
    signature = nil,
    battle_state = ProtoEnum.PlayerBattleState.PLAYER_BATTLE_STATE_IDLE,
    battle_brief_info = ProtoMessage:newPlayerBattleBriefInfo(),
    card_icon_selected = nil,
    tags = {}
  }
end

function ProtoMessage:newZoneUnlockRelationshipNodeReq()
  return {peer_uin = nil, relationship_type = nil}
end

function ProtoMessage:newZoneUnlockRelationshipNodeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    peer_uin = nil,
    relationship_type = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneConfirmUnlockRelationshipNodeReq()
  return {peer_uin = nil, relationship_type = nil}
end

function ProtoMessage:newZoneConfirmUnlockRelationshipNodeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    peer_uin = nil,
    relationship_type = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneCancelUnlockRelationshipNodeReq()
  return {peer_uin = nil, relationship_type = nil}
end

function ProtoMessage:newZoneCancelUnlockRelationshipNodeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    peer_uin = nil,
    relationship_type = nil
  }
end

function ProtoMessage:newZoneCloseRelationshipTreeReq()
  return {peer_uin = nil}
end

function ProtoMessage:newZoneCloseRelationshipTreeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    peer_uin = nil
  }
end

function ProtoMessage:newZoneScenePetTreeInteractHoldReq()
  return {pet_npc_id = nil}
end

function ProtoMessage:newZoneScenePetTreeInteractHoldRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneCreateRoleplayPropReq()
  return {
    roleplay_prop_config_id = nil,
    create_pts = {}
  }
end

function ProtoMessage:newZoneSceneCreateRoleplayPropRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRecycleRoleplayPropReq()
  return {recycle_npc_id = nil}
end

function ProtoMessage:newZoneSceneRecycleRoleplayPropRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneCreateSceneSeatReq()
  return {
    create_pt = ProtoMessage:newPoint(),
    npc_config_id = nil,
    create_pts = {}
  }
end

function ProtoMessage:newZoneSceneCreateSceneSeatRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRecycleSceneSeatReq()
  return {recycle_npc_id = nil}
end

function ProtoMessage:newZoneSceneRecycleSceneSeatRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneOpSeatReq()
  return {
    op_type = ProtoEnum.OpSeatType.OST_NONE,
    npc_id = nil,
    seat_idx = nil,
    leave_point_idx = nil,
    normal_leave_seat = nil
  }
end

function ProtoMessage:newZoneSceneOpSeatRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    op_type = ProtoEnum.OpSeatType.OST_NONE,
    seat_idx = nil,
    leave_point_idx = nil
  }
end

function ProtoMessage:newZoneFashionSuitsLevelUpReq()
  return {
    fashion_suit_id = nil,
    level = nil,
    components = {}
  }
end

function ProtoMessage:newZoneFashionSuitsLevelUpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    suit_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo_SuitInfo()
  }
end

function ProtoMessage:newZoneChangeWornComponentsReq()
  return {
    suit_id = nil,
    components_is_worn = {}
  }
end

function ProtoMessage:newZoneChangeWornComponentsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    suit_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo_SuitInfo()
  }
end

function ProtoMessage:newZoneChangeWardrobeReq()
  return {wardrobe_index = nil}
end

function ProtoMessage:newZoneChangeWardrobeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    wardrobe_data = ProtoMessage:newPlayerAppearanceInfo_FashionInfo_WardrobeData(),
    current_wardrobe_index = nil
  }
end

function ProtoMessage:newZoneGiftGivingReq()
  return {
    receiver_uin = nil,
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_gid = nil,
    goods_num = nil
  }
end

function ProtoMessage:newZoneGiftGivingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneGiftReceivingReq()
  return {
    giver_uin = nil,
    gift_unique_id = nil,
    goods_type = ProtoEnum.GoodsType.GT_NONE,
    goods_id = nil,
    goods_num = nil
  }
end

function ProtoMessage:newZoneGiftReceivingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneSeasonInfoReq()
  return {}
end

function ProtoMessage:newSeasonPartChangeInfo()
  return {
    instead_start_time = nil,
    instead_red_point_id = nil,
    instead_item_id = nil
  }
end

function ProtoMessage:newSeasonPartInfo()
  return {
    part_id = nil,
    red_point_id = nil,
    item_id = nil,
    change_info = {}
  }
end

function ProtoMessage:newZoneSeasonInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    season_kv_type = nil,
    popup_time = nil,
    season_start_time = nil,
    season_end_time = nil,
    part_info = {},
    light_talent_count = nil,
    season_pv_time = nil,
    season_pop_windows_time = nil
  }
end

function ProtoMessage:newZoneSetSeasonKvTypeReq()
  return {season_id = nil, season_kv_type = nil}
end

function ProtoMessage:newZoneSetSeasonKvTypeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    season_kv_type = nil
  }
end

function ProtoMessage:newZoneSetSeasonFirstPopReq()
  return {season_id = nil, pop_type = nil}
end

function ProtoMessage:newZoneSetSeasonFirstPopRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    pop_type = nil,
    pop_time = nil
  }
end

function ProtoMessage:newZoneSetSeasonPopupReq()
  return {season_id = nil}
end

function ProtoMessage:newZoneSetSeasonPopupRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneLightSeasonTalentPointReq()
  return {
    point_id = nil,
    pet_gid = nil,
    new_pet_conf_id = nil
  }
end

function ProtoMessage:newZoneLightSeasonTalentPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    material_cnt = nil
  }
end

function ProtoMessage:newZoneClearSeasonTalentPointReq()
  return {}
end

function ProtoMessage:newZoneClearSeasonTalentPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    material_cnt = nil
  }
end

function ProtoMessage:newZoneGetSeasonTalentPointReq()
  return {}
end

function ProtoMessage:newZoneGetSeasonTalentPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    material_cnt = nil,
    light_growth_list = {}
  }
end

function ProtoMessage:newZoneGetUserSubscribeTplInfoReq()
  return {
    tpl_type_list = {},
    need_openlink = nil
  }
end

function ProtoMessage:newUserSubscribeTplInfo()
  return {
    tpl_type = nil,
    tpl_id = nil,
    is_subscribed = nil
  }
end

function ProtoMessage:newZoneGetUserSubscribeTplInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    tpl_info_list = {},
    openlink = nil
  }
end

function ProtoMessage:newZoneStarLightInfoNotify()
  return {
    increment_star_light_num = nil,
    star_light_info = ProtoMessage:newPlayerStarLightInfo(),
    is_share_from_wild_no_battle = nil
  }
end

function ProtoMessage:newZoneWishingStarExchangeReq()
  return {}
end

function ProtoMessage:newZoneWishingStarExchangeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    exchange_num = nil,
    star_light_info = ProtoMessage:newPlayerStarLightInfo()
  }
end

function ProtoMessage:newZonePhotoAlbumUploadUrlReq()
  return {
    album_type = nil,
    photo_name = nil,
    photo_md5 = nil
  }
end

function ProtoMessage:newZonePhotoAlbumUploadUrlRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    url = nil,
    photo_name = nil,
    album_type = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZonePhotoAlbumDownloadUrlReq()
  return {
    photo_list = {}
  }
end

function ProtoMessage:newZonePhotoAlbumDownloadUrlRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    download_list = {}
  }
end

function ProtoMessage:newPhotoDownLoadInfo()
  return {photo_name = nil, url = nil}
end

function ProtoMessage:newZonePhotoAlbumPreviewReq()
  return {}
end

function ProtoMessage:newZonePhotoAlbumPreviewRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    photo_list = {}
  }
end

function ProtoMessage:newPhotoFile()
  return {
    photo_name = nil,
    photo_md5 = nil,
    photo_info = ProtoMessage:newPlayerPhotoAlbumInfo()
  }
end

function ProtoMessage:newZonePhotoAlbumDeleteReq()
  return {
    photo_list = {}
  }
end

function ProtoMessage:newZonePhotoAlbumDeleteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    photo_list = {}
  }
end

function ProtoMessage:newZonePhotoAlbumUploadSuccessReq()
  return {
    photo_name = nil,
    photo_md5 = nil,
    photo_info = ProtoMessage:newPlayerPhotoAlbumInfo()
  }
end

function ProtoMessage:newZonePhotoAlbumUploadSuccessRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBusinessCardUploadSuccessReq()
  return {photo_name = nil, photo_md5 = nil}
end

function ProtoMessage:newZoneBusinessCardUploadSuccessRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    business_card_info = ProtoMessage:newPlayerBusinessCardInfo()
  }
end

function ProtoMessage:newZonePetTeamFriendGetListReq()
  return {
    team_type = nil,
    page_num = nil,
    filter = nil
  }
end

function ProtoMessage:newZonePetTeamFriendGetListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    total_page = nil,
    req_page = nil,
    page_num = nil,
    pet_team_info = {},
    team_type = nil,
    filter = nil
  }
end

function ProtoMessage:newZonePetTeamFriendMirrorReq()
  return {
    team_type = nil,
    team_idx = nil,
    target_uin = nil,
    target_team_idx = nil
  }
end

function ProtoMessage:newZonePetTeamFriendMirrorRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZonePetTeamFriendGetMirrorPetDataReq()
  return {}
end

function ProtoMessage:newZonePetTeamFriendGetMirrorPetDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mirror_pet_data = {}
  }
end

function ProtoMessage:newZoneGetFashionBondLastTabReq()
  return {}
end

function ProtoMessage:newZoneGetFashionBondLastTabRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    last_fashionbond_tab = nil
  }
end

function ProtoMessage:newZoneSetFashionBondLastTabReq()
  return {last_fashionbond_tab = nil}
end

function ProtoMessage:newZoneSetFashionBondLastTabRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    last_fashionbond_tab = nil
  }
end

function ProtoMessage:newZoneGetPetReportInfosByPageReq()
  return {page_num = nil}
end

function ProtoMessage:newZoneGetPetReportInfosByPageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    req_page = nil,
    tot_page = nil,
    pet_report_infos = {}
  }
end

function ProtoMessage:newZoneFinishPetReportReq()
  return {}
end

function ProtoMessage:newZoneFinishPetReportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    submit_pet_reward = nil
  }
end

function ProtoMessage:newZoneSceneWorldMapEntryInfoIncrNty()
  return {
    batch_id = nil,
    total_batch = nil,
    entries = ProtoMessage:newWorldMapEntries()
  }
end

function ProtoMessage:newZoneQueryNpcPetDataReq()
  return {
    target_uin = nil,
    target_pet_gid = nil,
    target_pet_npc_id = nil
  }
end

function ProtoMessage:newZoneQueryNpcPetDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_info = ProtoMessage:newFriendRoleInfo(),
    relationship_type = ProtoEnum.PlayerRelationshipType.PRT_SELF,
    target_pet_data = ProtoMessage:newPetData(),
    is_first_interact = nil
  }
end

function ProtoMessage:newZoneQueryGiftingEggTimesReq()
  return {target_uin = nil}
end

function ProtoMessage:newZoneQueryGiftingEggTimesRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    times = nil
  }
end

function ProtoMessage:newZoneSceneGetFollowInfoReq()
  return {confirm_talk_id = nil}
end

function ProtoMessage:newZoneSceneGetFollowInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    follow_id = nil,
    task_id = nil,
    new_state = nil,
    conf_id = nil,
    confirm_talk_id = nil
  }
end

function ProtoMessage:newZoneTogetherCatchPetForGiftingReq()
  return {pet_gid = nil, is_for_check = nil}
end

function ProtoMessage:newZoneTogetherCatchPetForGiftingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_for_check = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newZoneBacktrackPetReq()
  return {pet_gid = nil, is_for_check = nil}
end

function ProtoMessage:newZoneBacktrackPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_for_check = nil,
    pet_gid = nil,
    reward_list = {},
    show_info = ProtoMessage:newPetBacktrackShowInfo()
  }
end

function ProtoMessage:newRewardItem()
  return {
    id = nil,
    num = nil,
    type = ProtoEnum.GoodsType.GT_NONE
  }
end

function ProtoMessage:newZoneQueryBacktrackPetRewardReq()
  return {
    pet_gid = {}
  }
end

function ProtoMessage:newZoneQueryBacktrackPetRewardRsp()
  return {
    pet_gid = {},
    reward_list = {},
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newRewardItem()
  return {
    id = nil,
    num = nil,
    type = ProtoEnum.GoodsType.GT_NONE
  }
end

function ProtoMessage:newZoneSecondaryPasswordGetInfoReq()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordGetInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    status = ProtoEnum.SecondaryPasswordStatus.SPS_None,
    status_timestamp = nil,
    default_free = nil,
    waiting_duration = nil
  }
end

function ProtoMessage:newZoneSecondaryPasswordUnsetNotify()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordGetAuthInfoReq()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordGetAuthInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    salting = nil,
    public_key = nil,
    public_key_md5 = nil,
    sequence = nil,
    status = ProtoEnum.SecondaryPasswordStatus.SPS_None,
    status_timestamp = nil,
    default_free = nil,
    waiting_duration = nil
  }
end

function ProtoMessage:newZoneSecondaryPasswordCheckReq()
  return {
    action = ProtoEnum.ZoneSecondaryPasswordAction.SPA_None,
    encode_secondary_password = nil,
    old_encode_secondary_password = nil,
    pass_action = nil,
    public_key_md5 = nil,
    default_free = nil
  }
end

function ProtoMessage:newZoneSecondaryPasswordCheckRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    status = ProtoEnum.SecondaryPasswordStatus.SPS_None,
    status_timestamp = nil,
    default_free = nil,
    waiting_duration = nil
  }
end

function ProtoMessage:newZoneSecondaryPasswordForceDisableReq()
  return {
    action_type = ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_None
  }
end

function ProtoMessage:newZoneSecondaryPasswordForceDisableRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    action_type = ProtoEnum.ZoneSecondaryPasswordForceDisable.SPFD_None,
    status = ProtoEnum.SecondaryPasswordStatus.SPS_None,
    status_timestamp = nil,
    default_free = nil,
    waiting_duration = nil
  }
end

function ProtoMessage:newZoneSecondaryPasswordNeedCheckNotify()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordSetUnSetReq()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordSetUnSetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSecondaryPasswordSetUnsetReq()
  return {}
end

function ProtoMessage:newZoneSecondaryPasswordSetUnsetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneShareFormNotify()
  return {
    share_form_item = {}
  }
end

function ProtoMessage:newZoneShareFormExpireNotify()
  return {
    expire_ids = {}
  }
end

function ProtoMessage:newZoneGetShareFormInfoReq()
  return {pet_id = nil}
end

function ProtoMessage:newZoneGetShareFormInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    share_form_item = {}
  }
end

function ProtoMessage:newZoneChooseInheritPetReq()
  return {
    pet_gid = nil,
    activity_id = nil,
    take_back = nil
  }
end

function ProtoMessage:newZoneChooseInheritPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneClaimNetbarRewardReq()
  return {
    ip = nil,
    macs = {},
    netbar_token = nil
  }
end

function ProtoMessage:newZoneClaimNetbarRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    netbar_errcode = nil
  }
end

function ProtoMessage:newZoneGetRecommendPetTeamReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetRecommendPetTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    recommend_pet_team = {}
  }
end

function ProtoMessage:newZoneActivitySaveRecommendPetTeamReq()
  return {
    activity_id = nil,
    recommend_pet_team = ProtoMessage:newRecommendPetTeamInfo()
  }
end

function ProtoMessage:newZoneActivitySaveRecommendPetTeamRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    recommend_pet_team = ProtoMessage:newRecommendPetTeamInfo()
  }
end

function ProtoMessage:newZoneChooseActivityFactionReq()
  return {
    activity_id = nil,
    faction = ProtoEnum.ActivityFaction.FACTION_NONE
  }
end

function ProtoMessage:newZoneChooseActivityFactionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneRefreshMixActivityTaskReq()
  return {activity_id = nil, task_id = nil}
end

function ProtoMessage:newZoneRefreshMixActivityTaskRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_data = ProtoMessage:newPlayerActivityInfo_ActivityData()
  }
end

function ProtoMessage:newZoneActivityFactionRankReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityFactionRankRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    rank_info = ProtoMessage:newFactionRankInfo()
  }
end

function ProtoMessage:newZoneActivityUnlockAdvanceReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityUnlockAdvanceRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPreHeatRewardReq()
  return {
    activity_id = nil,
    operate_type = nil,
    section_id = nil
  }
end

function ProtoMessage:newZoneActivityPreHeatRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPetCertificationReq()
  return {activity_id = nil, pet_gid = nil}
end

function ProtoMessage:newZoneActivityPetCertificationRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneConfirmLotteryRewardReq()
  return {lottery_item = nil, trans_id = nil}
end

function ProtoMessage:newZoneConfirmLotteryRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneClientStartUpReq()
  return {cli_startup_channel = nil}
end

function ProtoMessage:newZoneClientStartUpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneRecycleFriendRidePetReq()
  return {friend_uin = nil}
end

function ProtoMessage:newZoneSceneRecycleFriendRidePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetSimShareLuckyBagReq()
  return {}
end

function ProtoMessage:newZoneGetSimShareLuckyBagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    gift_code = nil
  }
end

function ProtoMessage:newZoneErrorCodeNotify()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneChoosePetPartnerReq()
  return {
    pet_base_id = nil,
    is_inherit = nil,
    commit = nil,
    miantain_expression = nil,
    activity_id = nil
  }
end

function ProtoMessage:newZoneChoosePetPartnerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneRewardSeasonAdventureChapterReq()
  return {chapter_id = nil}
end

function ProtoMessage:newZoneRewardSeasonAdventureChapterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneUpgradeSeasonAdventureBadgeReq()
  return {}
end

function ProtoMessage:newZoneUpgradeSeasonAdventureBadgeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    badge_info = ProtoMessage:newSeasonAdventureBadge()
  }
end

function ProtoMessage:newZoneOpenSeasonAdventureReq()
  return {chapter_id = nil}
end

function ProtoMessage:newSeasonAdventureBadge()
  return {
    badge_lvl = nil,
    cur_progress = nil,
    full_progress = nil
  }
end

function ProtoMessage:newZoneOpenSeasonAdventureRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    season_id = nil,
    chapter_id = nil,
    rewarded = nil,
    chapter_task_list = {},
    badge_info = ProtoMessage:newSeasonAdventureBadge(),
    chapter_base_infos = {}
  }
end

function ProtoMessage:newZonePlayerSeasonAdvBadgeEffectNotify()
  return {
    badge_lvl = nil,
    season_adv_prob_add = nil,
    season_adv_shining_extra_weight = nil
  }
end

function ProtoMessage:newZoneSceneSwitchLookAtTargetReq()
  return {target_actor_id = nil, enable = nil}
end

function ProtoMessage:newZoneSceneSwitchLookAtTargetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneNpcChallengeBattleChangeNty()
  return {
    npc_challenge_item = ProtoMessage:newNpcChallengeItem(),
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetBoxLastOpenBoxReq()
  return {box_id = nil}
end

function ProtoMessage:newZonePetBoxLastOpenBoxRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    box_id = nil
  }
end

function ProtoMessage:newZonePetBoxUnlockReq()
  return {box_id = nil, unlock_group = nil}
end

function ProtoMessage:newZonePetBoxUnlockRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    box_info = ProtoMessage:newPetBox()
  }
end

function ProtoMessage:newZonePetBoxTidyReq()
  return {
    last_open_box_id = nil,
    tidy_rules = {}
  }
end

function ProtoMessage:newZonePetBoxTidyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    box_info = {},
    last_open_box_id = nil,
    tidy_rules = {}
  }
end

function ProtoMessage:newZonePetBoxChangePetReq()
  return {
    ori_info = ProtoMessage:newPetBoxPetChange(),
    tar_info = ProtoMessage:newPetBoxPetChange()
  }
end

function ProtoMessage:newZonePetBoxChangePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetBoxSettingUpReq()
  return {
    box_ids = {}
  }
end

function ProtoMessage:newZonePetBoxSettingUpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    box_info = {}
  }
end

function ProtoMessage:newZonePetBoxSetMarkTypeReq()
  return {
    box_id = nil,
    mark_type = ProtoEnum.WarehouseMarkType.WMT_DEFAULT,
    box_name = nil,
    lock = nil
  }
end

function ProtoMessage:newZonePetBoxSetMarkTypeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    box_id = nil,
    mark_type = ProtoEnum.WarehouseMarkType.WMT_DEFAULT,
    box_name = nil,
    lock = nil
  }
end

function ProtoMessage:newZonePetBoxMarkTypeUnlockNty()
  return {mark_type = nil}
end

function ProtoMessage:newZoneQueryPetBalancedAttrReq()
  return {
    gid = {},
    is_weekly_challenge = nil
  }
end

function ProtoMessage:newZoneQueryPetBalancedAttrRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_data = {}
  }
end

function ProtoMessage:newZoneGetInviteUserListReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetInviteUserListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    invited_users = {}
  }
end

function ProtoMessage:newZoneActivityPopupPlayedReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityPopupPlayedRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil
  }
end

function ProtoMessage:newZoneActivityRecallTagSwitchReq()
  return {activity_id = nil, is_show = nil}
end

function ProtoMessage:newZoneActivityRecallTagSwitchRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil
  }
end

function ProtoMessage:newZoneGetActivityOptionalPetsReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneGetActivityOptionalPetsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil,
    optional_pets_id = {}
  }
end

function ProtoMessage:newZoneReceiveActivityRecallBpExpReq()
  return {activity_id = nil, task_id = nil}
end

function ProtoMessage:newZoneReceiveActivityRecallBpExpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil,
    task_id = nil
  }
end

function ProtoMessage:newZoneReceiveActivityRecallBpLevelRewardReq()
  return {activity_id = nil, bp_level = nil}
end

function ProtoMessage:newZoneReceiveActivityRecallBpLevelRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil,
    reward_id_list = {}
  }
end

function ProtoMessage:newZoneUnlockActivityRecallPaidRewardReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneUnlockActivityRecallPaidRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil
  }
end

function ProtoMessage:newZoneTotalPopularityValueReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneTotalPopularityValueRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    value = nil
  }
end

function ProtoMessage:newZoneSceneTeleportToPlayerReq()
  return {
    uin = nil,
    tele_reason = ProtoEnum.TeleportToPlayerReason.TTPR_NONE
  }
end

function ProtoMessage:newZoneSceneTeleportToPlayerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    tele_reason = ProtoEnum.TeleportToPlayerReason.TTPR_NONE,
    point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneGetTeachingTabReq()
  return {}
end

function ProtoMessage:newZoneGetTeachingTabRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    teaching_tab = ProtoMessage:newPlayerTeachingTabInfo()
  }
end

function ProtoMessage:newZoneClaimTeachingRewardReq()
  return {
    teaching_type = ProtoEnum.TeachingType.TT_EMPTY_TEACHING,
    id = nil
  }
end

function ProtoMessage:newZoneClaimTeachingRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTriggerTeachingBattleReq()
  return {
    teaching_type = ProtoEnum.TeachingType.TT_EMPTY_TEACHING,
    id = nil
  }
end

function ProtoMessage:newZoneTriggerTeachingBattleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTypeAdvantageTeachingReadReq()
  return {id = nil}
end

function ProtoMessage:newZoneTypeAdvantageTeachingReadRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneQueryDownloadRewardsReq()
  return {}
end

function ProtoMessage:newZoneQueryDownloadRewardsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    items = {}
  }
end

function ProtoMessage:newRewardItem()
  return {
    id = nil,
    num = nil,
    type = ProtoEnum.GoodsType.GT_NONE
  }
end

function ProtoMessage:newZonePetTreeFirstInteractNty()
  return {pet_base_id = nil, fashion_bond_id = nil}
end

function ProtoMessage:newZoneActivityCommonRewardsReq()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    params = {}
  }
end

function ProtoMessage:newZoneActivityCommonRewardsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    params = {}
  }
end

function ProtoMessage:newZoneSelectMainTeamPetReq()
  return {gid = nil}
end

function ProtoMessage:newZoneSelectMainTeamPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSelectTeamBattleFlowerSeedBossReq()
  return {uin = nil, npc_logic_id = nil}
end

function ProtoMessage:newZoneSelectTeamBattleFlowerSeedBossRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    npc_logic_id = nil
  }
end

function ProtoMessage:newZoneFinishExperienceCardPopupReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneFinishExperienceCardPopupRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePetTogetherTaskNotify()
  return {
    gid = nil,
    pet_status_flags = nil,
    task_id = nil
  }
end

function ProtoMessage:newZoneUpdateFashionInfoNotify()
  return {
    fashion_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo()
  }
end

function ProtoMessage:newZoneSetUsingRpBehaviorReq()
  return {
    player_rp_behavior_using_list = {}
  }
end

function ProtoMessage:newZoneSetUsingRpBehaviorRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_rp_behavior_using_list = {}
  }
end

function ProtoMessage:newZoneSceneSyncPlayerStatusPreCheckReq()
  return {
    sync_status_info = ProtoMessage:newPlayerStatusSyncInfo()
  }
end

function ProtoMessage:newZoneSceneSyncPlayerStatusPreCheckRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneUpdateBagItemIdFlagReq()
  return {
    bag_item_id_flags = {}
  }
end

function ProtoMessage:newZoneUpdateBagItemIdFlagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bag_item_id_flags = ProtoMessage:newPlayerBagItemIdFlagList()
  }
end

function ProtoMessage:newZoneGetBagItemIdFlagReq()
  return {}
end

function ProtoMessage:newZoneGetBagItemIdFlagRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bag_item_id_flags = ProtoMessage:newPlayerBagItemIdFlagList()
  }
end

function ProtoMessage:newZoneActivityPhotoContestSubmitReq()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    photo_name = nil,
    photo_md5 = nil,
    mini_photo_name = nil,
    mini_photo_md5 = nil
  }
end

function ProtoMessage:newZoneActivityPhotoContestSubmitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    phase_data = ProtoMessage:newPlayerActivityInfo_ActivityPhotoContest_Phase(),
    last_submit_time = nil,
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneActivityPhotoContestSubmitRewardNotify()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    rank_no = nil,
    estimated = ProtoMessage:newRankEstimatedData(),
    reward_id = nil,
    hot_value = nil
  }
end

function ProtoMessage:newZoneActivityPhotoContestEvaluationReq()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    skip_like = nil
  }
end

function ProtoMessage:newZoneActivityPhotoContestEvaluationRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneActivityPhotoContestEvaluationNotify()
  return {
    activity_sub_id = nil,
    photos = {},
    skip_count = nil,
    recommend_count = nil
  }
end

function ProtoMessage:newPhotoInfo()
  return {
    uin = nil,
    photo_url = nil,
    photo_md5 = nil,
    mini_photo_url = nil,
    mini_photo_md5 = nil
  }
end

function ProtoMessage:newZoneActivityPhotoContestLikeReq()
  return {
    activity_id = nil,
    activity_sub_id = nil,
    like_photo_uin = nil
  }
end

function ProtoMessage:newZoneActivityPhotoContestLikeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ban_info = ProtoMessage:newBanInfo()
  }
end

function ProtoMessage:newZoneActivityPhotoContestLikeNotify()
  return {
    activity_sub_id = nil,
    photos = {},
    accuracy_score = nil
  }
end

function ProtoMessage:newPhotoLikeInfo()
  return {uin = nil, like_count = nil}
end

function ProtoMessage:newZoneActivityPhotoContestHotReq()
  return {activity_id = nil, activity_sub_id = nil}
end

function ProtoMessage:newZoneActivityPhotoContestHotRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    uin = nil,
    photo_url = nil,
    photo_md5 = nil,
    mini_photo_url = nil,
    mini_photo_md5 = nil,
    hot_count = nil,
    activity_id = nil,
    activity_sub_id = nil,
    rank_no = nil
  }
end

function ProtoMessage:newZoneActivityPetTripReceiveLotteryRewardReq()
  return {activity_id = nil}
end

function ProtoMessage:newZoneActivityPetTripReceiveLotteryRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPetTripGetLotteryResultReq()
  return {}
end

function ProtoMessage:newZoneActivityPetTripGetLotteryResultRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    lottery_records = {}
  }
end

function ProtoMessage:newZoneGetRankUserReq()
  return {
    key = ProtoMessage:newRankboardKey(),
    info_id = nil,
    is_image = nil
  }
end

function ProtoMessage:newZoneGetRankUserRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    key = ProtoMessage:newRankboardKey(),
    info_id = nil,
    view_count = nil,
    rank_user = ProtoMessage:newCSRankUser()
  }
end

function ProtoMessage:newZoneGetRankUserListReq()
  return {
    key = ProtoMessage:newRankboardKey(),
    from = nil,
    count = nil,
    is_image = nil
  }
end

function ProtoMessage:newZoneGetRankUserListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    key = ProtoMessage:newRankboardKey(),
    view_count = nil,
    rank_user_list = {}
  }
end

function ProtoMessage:newZoneLlmPetsAvailablePetsReq()
  return {
    pets = {}
  }
end

function ProtoMessage:newZoneLlmPetsAvailablePetsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneLlmPetsBehaviorReportReq()
  return {
    report_infos = {}
  }
end

function ProtoMessage:newZoneLlmPetsBehaviorReportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneTokenInvalidNotify()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneAiCoachWhiteListReq()
  return {request_id = nil}
end

function ProtoMessage:newZoneAiCoachWhiteListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    is_whitelist = nil,
    version = nil
  }
end

function ProtoMessage:newZoneAiCoachSetStatusReq()
  return {
    request_id = nil,
    status = ProtoEnum.AiCoachStatus.ACS_CLOSED
  }
end

function ProtoMessage:newZoneAiCoachSetStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    status = ProtoEnum.AiCoachStatus.ACS_CLOSED
  }
end

function ProtoMessage:newZoneAiCoachRecommendLineupReq()
  return {
    session_id = nil,
    request_id = nil,
    query_text = nil,
    query_round_idx = nil,
    scene_type = nil,
    lineup_data = nil
  }
end

function ProtoMessage:newZoneAiCoachRecommendLineupNotify()
  return {
    session_id = nil,
    request_id = nil,
    event = nil,
    data = nil
  }
end

function ProtoMessage:newZoneAiCoachRecommendLineupRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    session_id = nil,
    request_id = nil
  }
end

function ProtoMessage:newZoneAiCoachRequestCancelReq()
  return {session_id = nil, request_id = nil}
end

function ProtoMessage:newZoneAiCoachRequestCancelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    session_id = nil,
    request_id = nil,
    cancelled = nil
  }
end

function ProtoMessage:newZoneGetAreaIdReq()
  return {}
end

function ProtoMessage:newZoneGetAreaIdRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    area_id = nil
  }
end

function ProtoMessage:newZoneSceneChangeNpcSizeScaleReq()
  return {
    npc_id = nil,
    npc_content_id = nil,
    type = nil,
    param = nil,
    scale_size_min = nil,
    scale_size_max = nil,
    snow_npc_id = nil
  }
end

function ProtoMessage:newZoneSceneChangeNpcSizeScaleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneActivityPredownloadReadyReq()
  return {
    activity_id = nil,
    resource_prepared = nil,
    already_download = nil,
    book_download = nil
  }
end

function ProtoMessage:newZoneActivityPredownloadReadyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    act_data = ProtoMessage:newPlayerActivityInfo_PreDownloadData()
  }
end

function ProtoMessage:newZonePlayerActivityDropAreaNotify()
  return {activity_id = nil, action_type = nil}
end

function ProtoMessage:newZoneAiAttackAbnormalStatusReq()
  return {
    actor_id = nil,
    abnormal_status_info = ProtoMessage:newAvatarAbnormalStatusInfo()
  }
end

function ProtoMessage:newZoneAiAttackAbnormalStatusRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBagItemExpireConvertReq()
  return {}
end

function ProtoMessage:newZoneBagItemExpireConvertRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bag_item_expire_list = ProtoMessage:newBagItemExpireList()
  }
end

function ProtoMessage:newZoneBagItemExpireCheckReq()
  return {
    gids = {}
  }
end

function ProtoMessage:newZoneBagItemExpireCheckRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bag_item_expire_list = ProtoMessage:newBagItemExpireList()
  }
end

function ProtoMessage:newZoneRptMonthCardTipsShowReq()
  return {}
end

function ProtoMessage:newZoneRptMonthCardTipsShowRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGetDistributeBillReq()
  return {}
end

function ProtoMessage:newZoneGetDistributeBillRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    bill_list = ProtoMessage:newMidasDistriBillList()
  }
end

function ProtoMessage:newZoneReportDistributeReq()
  return {
    goods_id = nil,
    create_time = nil,
    op_type = nil,
    ret = nil
  }
end

function ProtoMessage:newZoneReportDistributeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneDistributeBillNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    goods_id = nil,
    create_time = nil
  }
end

function ProtoMessage:newDisconnectInfo()
  return {system_hardware = nil, channel = nil}
end

function ProtoMessage:newNotifyMsg()
  return {
    dis_info = ProtoMessage:newDisconnectInfo()
  }
end

function ProtoMessage:newZonePlayerSyncNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    sync_info = ProtoMessage:newPlayerSyncInfo()
  }
end

function ProtoMessage:newZoneNotifyModuleMark()
  return {module_mark = nil}
end

function ProtoMessage:newZonePlayerInfoNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    player_info = ProtoMessage:newPlayerInfo()
  }
end

function ProtoMessage:newZonePlayerPetHpChangeNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_info = {},
    change_reason = nil,
    total_change_hp = nil
  }
end

function ProtoMessage:newZonePlayerInSafeZoneNotify()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePlayerInChangePetZoneNotify()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePlayerLeaveChangePetZoneNotify()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZonePlayerAddRoleEnergyNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    config_add_val = nil,
    real_add_val = nil
  }
end

function ProtoMessage:newZoneTaskInfoNotify()
  return {
    task_info_list = {},
    delete_task_list = {},
    ret_info = ProtoMessage:newRetInfo(),
    open_task_num = nil,
    guiding_task_num = nil,
    is_all_activity_task = nil
  }
end

function ProtoMessage:newZoneClimbChapterNotify()
  return {
    chapter_item = ProtoMessage:newClimbChapterItem()
  }
end

function ProtoMessage:newZoneErrorTipsNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    err_tips = nil,
    is_debug_show = nil,
    is_debug = nil
  }
end

function ProtoMessage:newZoneDungeonDataNotify()
  return {
    dungeon_state_list = {}
  }
end

function ProtoMessage:newZoneSceneDungeonStageNotify()
  return {
    dungeon_cfg_id = nil,
    stage_cfg_id = {},
    dungeon_finish = nil
  }
end

function ProtoMessage:newZoneScenePreTeleportNotify()
  return {
    from_scene_res_cfg_id = nil,
    to_scene_cfg_id = nil,
    to_scene_res_cfg_id = nil,
    to_scene_inst_id = nil,
    to_pt = ProtoMessage:newPoint(),
    teleport_stub = nil,
    teleport_id = nil,
    allow_cli_cache_pkg = nil,
    is_no_loading_teleport = nil
  }
end

function ProtoMessage:newZoneScenePreTeleportNotifyAck()
  return {teleport_stub = nil}
end

function ProtoMessage:newZoneSceneCancelPreTeleportNotify()
  return {teleport_stub = nil, err_code = nil}
end

function ProtoMessage:newZoneSceneTeleportNotify()
  return {
    from_scene_cfg_id = nil,
    from_scene_res_cfg_id = nil,
    from_scene_inst_id = nil,
    from_pt = ProtoMessage:newPoint(),
    to_scene_cfg_id = nil,
    to_scene_res_cfg_id = nil,
    to_scene_inst_id = nil,
    to_pt = ProtoMessage:newPoint(),
    self_info = ProtoMessage:newActorInfo(),
    teleport_reason = nil,
    teleport_id = nil,
    teleport_rule_id = nil,
    is_cross_scene = nil,
    home_room_level = nil,
    home_name = nil
  }
end

function ProtoMessage:newZoneSceneGuideBookNotify()
  return {
    type = nil,
    book_id = nil,
    stamp_index = {},
    book_data = ProtoMessage:newGuideBook()
  }
end

function ProtoMessage:newZoneDiamondBuyStarTimesNotify()
  return {buy_times = nil}
end

function ProtoMessage:newZoneGoodsRewardNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reward_source = nil,
    flow_reason = nil,
    goods_id = nil
  }
end

function ProtoMessage:newZoneRedPointNotify()
  return {
    rp_group = {}
  }
end

function ProtoMessage:newZoneSceneBeInteractedNotify()
  return {
    type = ProtoEnum.PlayerInteractType.PIT_None,
    player_info = ProtoMessage:newPlayerInteractBriefInfo(),
    cancel_status = ProtoEnum.InteractCancelStatus.ICS_NORMAL,
    auto_confirm_visiting = nil
  }
end

function ProtoMessage:newZoneSceneInteractResultNotify()
  return {
    type = ProtoEnum.PlayerInteractType.PIT_None,
    uin = nil,
    agree = nil,
    cancel_status = ProtoEnum.InteractCancelStatus.ICS_NORMAL
  }
end

function ProtoMessage:newZoneScenePickEggResultNotify()
  return {
    uin = nil,
    result = ProtoEnum.ZoneScenePickEggResultNotify.Result.FINISH
  }
end

function ProtoMessage:newZoneSceneApplyVisitNotify()
  return {
    level = nil,
    name = nil,
    uin = nil,
    server_time = nil,
    card_info = ProtoMessage:newPlayerCardBriefInfo()
  }
end

function ProtoMessage:newZoneSceneApplyVisitResultNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    owner_name = nil,
    agree = nil,
    owner_uin = nil
  }
end

function ProtoMessage:newZoneSceneLeaveOnlineVisitNotify()
  return {reason = nil}
end

function ProtoMessage:newZoneSceneOnlineVisitorChangeNotify()
  return {
    visitors = {},
    beast_match_success = nil,
    beast_full_visitors = nil,
    beast_star = nil,
    battle_cfg_id = nil,
    change_reason = nil,
    timestamp = nil,
    change_visitor_uin = nil
  }
end

function ProtoMessage:newVisitorBriefInfo()
  return {
    uin = nil,
    name = nil,
    level = nil,
    card_info = ProtoMessage:newPlayerCardBriefInfo(),
    beast_start_match_time = nil,
    check_result = ProtoMessage:newBeastCatchResult(),
    fighting = nil,
    catch_state = nil,
    gender = nil,
    world_lv = nil,
    pvp_rank_star = nil,
    scene_res_cfg_id = nil
  }
end

function ProtoMessage:newZoneSceneOnlineVisitorInfoNotify()
  return {
    visitor_info = {}
  }
end

function ProtoMessage:newZoneSceneVistorOwnerInfoNotify()
  return {owner_uin = nil, pvp_rank_star = nil}
end

function ProtoMessage:newZoneSwitchServerToClientAiNty()
  return {
    actor_list = {},
    comp_data_list = {}
  }
end

function ProtoMessage:newZoneSwitchClientToServerAiNty()
  return {
    actor_list = {}
  }
end

function ProtoMessage:newZoneSceneTeamBattleInviteNotify()
  return {
    server_time = nil,
    npc_logic_id = nil,
    challenge_type = nil,
    battle_cfg_id = nil,
    select_star = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleInviteResultNotify()
  return {uin = nil, agree = nil}
end

function ProtoMessage:newZoneSceneTeamBattleCancelNotify()
  return {uin = nil, overtime = nil}
end

function ProtoMessage:newZoneSceneTeamBattleMateSyncNotify()
  return {
    mate_infos = {},
    sync_reason = nil,
    update_uin = nil,
    challenge_type = nil
  }
end

function ProtoMessage:newZoneSceneTeamBattleStartNotify()
  return {}
end

function ProtoMessage:newZoneSceneBeastCancelMatchNotify()
  return {uin = nil, name = nil}
end

function ProtoMessage:newZoneScenePlayerVisitInfoSyncNotify()
  return {online_visit_owner = nil, first_enter_visiting = nil}
end

function ProtoMessage:newZoneSceneBeastCheckNotify()
  return {
    check_result = ProtoMessage:newBeastCatchResult()
  }
end

function ProtoMessage:newZoneHbCoverChangeNotify()
  return {
    cover_idx = nil,
    hb_area_type = nil,
    cover_info = ProtoMessage:newHandbookCoverInfo()
  }
end

function ProtoMessage:newZonePlayerPkInfoNotify()
  return {
    pk_info = ProtoMessage:newPlayerPkInfo()
  }
end

function ProtoMessage:newZoneMailDeleteNotify()
  return {
    mail_gid_list = {}
  }
end

function ProtoMessage:newZoneVisitRemainCatchTimesNotify()
  return {remain_times = nil, is_glass = nil}
end

function ProtoMessage:newZonePvpHistoryDataNotify()
  return {
    pvp_his_cli = ProtoMessage:newPlayerPvpHisCli()
  }
end

function ProtoMessage:newZoneMageBookNotify()
  return {
    npc_id = nil,
    item_id = nil,
    has_award = nil,
    action = nil
  }
end

function ProtoMessage:newZoneIgnoreC2SCmdNotify()
  return {cmd_id = nil}
end

function ProtoMessage:newZoneMoneyInfoChangeNotity()
  return {
    data = ProtoMessage:newMidasMoneyInfo(),
    ret_info = ProtoMessage:newRetInfo(),
    coupon_change_val = nil
  }
end

function ProtoMessage:newZonePlayerFeedInfoNotify()
  return {
    data = ProtoMessage:newFeedDetailNotifyData(),
    grid_id = nil
  }
end

function ProtoMessage:newZoneBadgeChallengeSettleNotify()
  return {
    is_finish_challenge = nil,
    upgrade_rewards = {},
    coins = nil,
    is_win = nil,
    pet_info = {},
    upgrade_num = nil
  }
end

function ProtoMessage:newZoneTextNotify()
  return {
    text_info = ProtoMessage:newCommonTextInfo()
  }
end

function ProtoMessage:newZoneFuncBlockingConfsChangeNotify()
  return {
    func_blocking_confs_list = {},
    is_audit = nil
  }
end

function ProtoMessage:newZoneRelationshipTreeChangedNotify()
  return {
    tree_data = ProtoMessage:newRelationshipTreeData(),
    unlock_req_finish = nil,
    remove_send_unlock_req = nil,
    remove_recv_unlock_req = nil,
    relationship_tree_add_friend = nil
  }
end

function ProtoMessage:newZoneRelationshipReqUnlockNotify()
  return {
    req_uin = nil,
    relationship_type = nil,
    reset_unlocked_data = nil
  }
end

function ProtoMessage:newZoneRelationshipCancelUnlockNotify()
  return {cancel_uin = nil, relationship_type = nil}
end

function ProtoMessage:newZoneForceResetHomeLayoutNotify()
  return {
    room_layout_info = ProtoMessage:newRoomLayoutInfo()
  }
end

function ProtoMessage:newZoneHomeInfoChangeNotify()
  return {
    is_home_visiting = nil,
    home_owner_uin = nil,
    is_online_visiting_home = nil
  }
end

function ProtoMessage:newZoneDailyLimitNotify()
  return {tips = nil, hour = nil}
end

function ProtoMessage:newZoneBagItemLimitNotify()
  return {item_conf_id = nil, num = nil}
end

function ProtoMessage:newZoneBattlePassTaskUpdateNotify()
  return {
    task_info = ProtoMessage:newPlayerBattlePassTaskInfo()
  }
end

function ProtoMessage:newZoneRatingPopupNotify()
  return {rating_popup_id = nil}
end

function ProtoMessage:newZoneHomeAccessInfoNotify()
  return {
    access_info = ProtoMessage:newHomeAccessInfo()
  }
end

function ProtoMessage:newPlayerStartUpPrivilegeInfoCli()
  return {
    cli_startup_day = nil,
    cli_startup_channel = nil,
    is_first_startup = nil
  }
end

function ProtoMessage:newZoneStartUpPrivilegeInfoNotify()
  return {
    start_up_privilege_info_cli = ProtoMessage:newPlayerStartUpPrivilegeInfoCli()
  }
end

function ProtoMessage:newZoneInteractActionResultNtf()
  return {
    act_type = nil,
    avatar_hp_change = nil,
    pet_or_charge_bag_item_change = nil
  }
end

function ProtoMessage:newZoneLockClientCmdNotify()
  return {cmd_id = nil, msg_idx = nil}
end

function ProtoMessage:newZoneChatEmojiItemChangeNotify()
  return {
    emoji_item_change_list = {}
  }
end

function ProtoMessage:newZoneChatEmojiItemChange()
  return {
    op_type = ProtoEnum.OpType.OT_ADD,
    emoji_item = ProtoMessage:newPlayerEmojiItem()
  }
end

function ProtoMessage:newZoneLotteryRewardResultNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    lottery_item = nil,
    trans_id = nil,
    lottery_result = nil
  }
end

function ProtoMessage:newZoneClientWaterMarkChangeNotify()
  return {
    client_water_mark_info = ProtoMessage:newPlayerClientWaterMarkInfo()
  }
end

function ProtoMessage:newZoneActivityOpenNotify()
  return {activity_id = nil}
end

function ProtoMessage:newZoneChooseNewFactionNotify()
  return {
    activity_id = nil,
    finished_faction = {}
  }
end

function ProtoMessage:newZonePlayerNpcLotteryGoodsRewardNotify()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    lottery_pool_type = nil,
    pool_reward_id = nil,
    npc_id = nil
  }
end

function ProtoMessage:newZoneSceneGmReq()
  return {
    gm_type = nil,
    gm_op_type = nil,
    uin = nil,
    param1 = nil,
    param2 = nil,
    rpt_params = {}
  }
end

function ProtoMessage:newZoneSceneGmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ret_value = nil
  }
end

function ProtoMessage:newZoneSceneGmTeleportReq()
  return {
    to_scene_cfg_id = nil,
    to_scene_inst_id = nil,
    to_point = ProtoMessage:newPoint()
  }
end

function ProtoMessage:newZoneSceneGmTeleportRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmOpenDungeonReq()
  return {dungeon_cfg_id = nil}
end

function ProtoMessage:newZoneGmOpenDungeonRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPlayerInvincibleManageReq()
  return {uin = nil, open_or_close = nil}
end

function ProtoMessage:newZoneGmPlayerInvincibleManageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneGmOperateStaminaReq()
  return {
    op_type = ProtoEnum.ZoneSceneGmOperateStaminaReq.OpType.OT_GET
  }
end

function ProtoMessage:newZoneSceneGmOperateStaminaRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    stamina = nil,
    stamina_low = nil,
    stamina_up = nil,
    stamina_status = nil,
    status = {},
    cost = {}
  }
end

function ProtoMessage:newZoneGmScenesvrErrEchoReq()
  return {uin = nil, status = nil}
end

function ProtoMessage:newZoneGmScenesvrErrEchoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneGmQueryNpcBlackboardReq()
  return {
    actor_list = {}
  }
end

function ProtoMessage:newZoneSceneGmQueryNpcBlackboardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    blackboard_infos = {}
  }
end

function ProtoMessage:newZoneGmGetDungeonCurStageReq()
  return {}
end

function ProtoMessage:newZoneGmGetDungeonCurStageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    cur_stage = nil
  }
end

function ProtoMessage:newZoneSceneGmAutoEnterVisitReq()
  return {owner_uin = nil}
end

function ProtoMessage:newZoneSceneGmAutoEnterVisitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmCreateNpcReq()
  return {
    only_test = nil,
    npc_type = nil,
    npc_pos = ProtoMessage:newPoint(),
    content_cfg_id = nil,
    is_nightmare_elite = nil
  }
end

function ProtoMessage:newZoneGmCreateNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmForbidCreateNpcReq()
  return {uin = nil}
end

function ProtoMessage:newZoneGmForbidCreateNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUnlockWorldMapStaticNpcReq()
  return {npc_refresh_cfg_id = nil, exclude_dungeon = nil}
end

function ProtoMessage:newZoneGmUnlockWorldMapStaticNpcRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmExploreAllAreaNpcsReq()
  return {}
end

function ProtoMessage:newZoneGmExploreAllAreaNpcsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSwitchClientAiToServerReq()
  return {
    actor_list = {},
    comp_data_list = {},
    point_list = {},
    isBatchSwitch = nil
  }
end

function ProtoMessage:newZoneGmSwitchClientAiToServerRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    success_list = {}
  }
end

function ProtoMessage:newZoneGmSwitchServerAiToClientReq()
  return {
    actor_list = {},
    isBatchSwitch = nil
  }
end

function ProtoMessage:newZoneGmSwitchServerAiToClientRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    success_list = {}
  }
end

function ProtoMessage:newZoneGmUnlockAllActivityReq()
  return {}
end

function ProtoMessage:newZoneGmUnlockAllActivityRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneGmSetNpcPosReq()
  return {
    npc_list = {}
  }
end

function ProtoMessage:newZoneSceneGmSetNpcPosRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddAllPetExpReq()
  return {uin = nil, exp = nil}
end

function ProtoMessage:newZoneGmAddAllPetExpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmCreateBattleReq()
  return {
    battle_conf_id = nil,
    npc_conf_id = nil,
    npc_level = nil,
    npc_obj_id = nil,
    avatar_pt = ProtoMessage:newPoint(),
    npc_pt = ProtoMessage:newPoint(),
    friend_uins = {},
    enemy_uins = {},
    enemy_zone_ids = {},
    pvp_mode = ProtoMessage:newPvpModeCtl(),
    dynamic_npcs = {},
    disable_anti_cheat = nil,
    skill_tool_mode = nil,
    dynamic_attacker_npcs = {},
    ai_type = nil,
    first_pet = nil,
    replay_bfid = nil
  }
end

function ProtoMessage:newZoneGmQueryBattleFieldReq()
  return {
    battle_conf_id = nil,
    full_station = nil,
    avatar_pt = ProtoMessage:newPosition(),
    npc_pt = ProtoMessage:newPosition(),
    data_layer = nil
  }
end

function ProtoMessage:newZoneGmCreateBattleRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    status = ProtoEnum.ZoneGmCreateBattleRsp.BattleFieldStatus.BATTLE_FIELD_STATUS_SUCCESS,
    query_pos = ProtoMessage:newPosition(),
    result_pos = ProtoMessage:newPosition(),
    is_full_station = nil,
    data_layer = nil,
    battle_id = nil
  }
end

function ProtoMessage:newZoneGmBattleBotInviteReq()
  return {
    player_uin = nil,
    zone_inst_id = nil,
    uin = nil
  }
end

function ProtoMessage:newZoneGmBattleBotInviteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmBattleBotInviteNotify()
  return {player_uin = nil, zone_inst_id = nil}
end

function ProtoMessage:newZoneGmCreateAiPetReq()
  return {
    pet_conf_id = nil,
    blood_id = nil,
    skill_ids = {},
    nature = nil,
    height = nil,
    weight = nil,
    gender = nil,
    breakthrough_cnt = nil,
    hp_max_talent = nil,
    phy_attack_talent = nil,
    spe_attack_talent = nil,
    phy_defence_talent = nil,
    spe_defence_talent = nil,
    speed_talent = nil,
    battle_conf_id = nil,
    world_lv = nil,
    role_lv = nil,
    npc_lv = nil
  }
end

function ProtoMessage:newZoneGmCreateAiPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pet_data = ProtoMessage:newPetData()
  }
end

function ProtoMessage:newZoneGmMatchStartReq()
  return {pvp_id = nil}
end

function ProtoMessage:newZoneGmMatchStartRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneBattleGmReq()
  return {
    gm_type = nil,
    gm_op_type = nil,
    uin = nil,
    param1 = nil,
    param2 = nil,
    param3 = nil,
    param4 = nil,
    param5 = nil,
    param6 = nil,
    str_param = nil,
    side = nil,
    pos = nil
  }
end

function ProtoMessage:newZoneBattleGmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    ret_value = nil,
    pets = {}
  }
end

function ProtoMessage:newZoneGmPkReq()
  return {uin = nil}
end

function ProtoMessage:newZoneGmPkRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmBattleEndReq()
  return {battle_result = nil}
end

function ProtoMessage:newZoneGmBattleEndRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmBindMageHelpReq()
  return {
    battle_id = nil,
    helper1 = nil,
    helper2 = nil,
    helper3 = nil,
    uin = nil
  }
end

function ProtoMessage:newZoneGmBindMageHelpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmBindMageCampReq()
  return {
    camp_id = nil,
    rest_conf_id = nil,
    uin = nil
  }
end

function ProtoMessage:newZoneGmBindMageCampRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUnlockCampPetsReq()
  return {uin = nil, camp_id = nil}
end

function ProtoMessage:newZoneGmUnlockCampPetsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetGenderReq()
  return {
    gender = ProtoEnum.ESexValue.SEX_NOT_SHOW
  }
end

function ProtoMessage:newZoneGmSetGenderRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmOpenAdventureChapterReq()
  return {uin = nil, chapter_id = nil}
end

function ProtoMessage:newZoneGmOpenAdventureChapterRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSelectAdventurePetReq()
  return {uin = nil, pet_conf_id = nil}
end

function ProtoMessage:newZoneGmSelectAdventurePetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmTaskAddReq()
  return {
    uin = nil,
    task_id = nil,
    extra_task_ids = {}
  }
end

function ProtoMessage:newZoneGmTaskAddRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmTaskRemoveReq()
  return {
    uin = nil,
    task_id = nil,
    extra_task_ids = {}
  }
end

function ProtoMessage:newZoneGmTaskRemoveRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmTaskModifyProgressReq()
  return {
    uin = nil,
    task_id = nil,
    extra_task_ids = {},
    task_progress = nil
  }
end

function ProtoMessage:newZoneGmTaskModifyProgressRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmTaskDoneReq()
  return {
    uin = nil,
    task_id = nil,
    extra_task_ids = {}
  }
end

function ProtoMessage:newZoneGmTaskDoneRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmTaskClearReq()
  return {}
end

function ProtoMessage:newZoneGmTaskClearRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientTaskFinishReq()
  return {task_id = nil}
end

function ProtoMessage:newZoneGmClientTaskFinishRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientTaskClearReq()
  return {task_id = nil}
end

function ProtoMessage:newZoneGmClientTaskClearRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientTaskTktDoneReq()
  return {num = nil}
end

function ProtoMessage:newZoneGmClientTaskTktDoneRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientQueryTaskStateReq()
  return {task_id = nil}
end

function ProtoMessage:newZoneGmClientQueryTaskStateRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    state = ProtoEnum.EMTaskState.EM_TASK_STATE_INIT
  }
end

function ProtoMessage:newZoneGmPetBreakThroughReq()
  return {uin = nil, level = nil}
end

function ProtoMessage:newZoneGmPetBreakThroughRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPetHabitLevelReq()
  return {
    uin = nil,
    level = nil,
    habit_list = {}
  }
end

function ProtoMessage:newZoneGmPetHabitLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClearPetReq()
  return {
    uin = nil,
    pet_gids = {}
  }
end

function ProtoMessage:newZoneGmClearPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetPetLevelReq()
  return {pet_level = nil, pet_gid = nil}
end

function ProtoMessage:newZoneGmSetPetLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUpdatePlayerPetReq()
  return {uin = nil, type = nil}
end

function ProtoMessage:newZoneGmUpdatePlayerPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetEggHatchCompleteReq()
  return {egg_gid = nil}
end

function ProtoMessage:newZoneGmSetEggHatchCompleteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetBpExpReq()
  return {uin = nil, exp = nil}
end

function ProtoMessage:newZoneGmSetBpExpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetPetTravelCompleteReq()
  return {
    pet_gid = {}
  }
end

function ProtoMessage:newZoneGmSetPetTravelCompleteRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetHandbookReq()
  return {}
end

function ProtoMessage:newZoneGmResetHandbookRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddPetClosenessReq()
  return {pet_gid = nil, add_exp = nil}
end

function ProtoMessage:newZoneGmAddPetClosenessRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    closeness_lv = nil,
    closeness_exp = nil
  }
end

function ProtoMessage:newZoneGmQueryPetClosenessReq()
  return {pet_gid = nil}
end

function ProtoMessage:newZoneGmQueryPetClosenessRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    closeness_lv = nil,
    closeness_exp = nil
  }
end

function ProtoMessage:newZoneGmFriendOperReq()
  return {
    uin = nil,
    type = nil,
    name_prefix = nil,
    num = nil
  }
end

function ProtoMessage:newZoneGmFriendOperRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    success_count = nil
  }
end

function ProtoMessage:newZoneGmBatchSendChatMsgReq()
  return {
    send_uin = nil,
    recv_uin = nil,
    chat_msg = nil,
    repeated_count = nil
  }
end

function ProtoMessage:newZoneGmBatchSendChatMsgRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddFriendReq()
  return {player_uin = nil}
end

function ProtoMessage:newZoneGmAddFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddTestPlatFriendReq()
  return {
    uin = nil,
    restful_op = nil,
    openid_prefix = nil,
    ranges = nil
  }
end

function ProtoMessage:newZoneGmAddTestPlatFriendRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGMTestSuggestionPlayerOne()
  return {uin = nil, ev_type = nil}
end

function ProtoMessage:newZoneGmAddTestSuggestionPlayersReq()
  return {
    test_players = {}
  }
end

function ProtoMessage:newZoneGmAddTestSuggestionPlayersRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmOperateItemReq()
  return {
    item_type = nil,
    item_id = nil,
    op_type = nil,
    item_num = nil,
    together_gift_uin = nil
  }
end

function ProtoMessage:newZoneGmOperateItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientAddItemReq()
  return {item_id = nil, num = nil}
end

function ProtoMessage:newZoneGmClientAddItemRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientAddPetReq()
  return {pet_conf_id = nil, num = nil}
end

function ProtoMessage:newZoneGmClientAddPetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientAddTaskTokenReq()
  return {task_token_id = nil, num = nil}
end

function ProtoMessage:newZoneGmClientAddTaskTokenRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientAddRewardReq()
  return {reward_id = nil, num = nil}
end

function ProtoMessage:newZoneGmClientAddRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetShopGoodsBuyNumReq()
  return {
    shop_id = nil,
    goods_id = {}
  }
end

function ProtoMessage:newZoneGmResetShopGoodsBuyNumRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUpdatePlayerRedPointReq()
  return {
    uin = nil,
    op_type = nil,
    rp_group = {}
  }
end

function ProtoMessage:newZoneGmUpdatePlayerRedPointRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetPlayerWorldLevelReq()
  return {uin = nil, world_level = nil}
end

function ProtoMessage:newZoneGmSetPlayerWorldLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetPlayerLevelReq()
  return {uin = nil, level = nil}
end

function ProtoMessage:newZoneGmSetPlayerLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddMailReq()
  return {
    uin = nil,
    mail_id = nil,
    rand_mail = nil,
    mail_num = nil
  }
end

function ProtoMessage:newZoneGmAddMailRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmGetSvrInfoReq()
  return {}
end

function ProtoMessage:newZoneGmGetSvrInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    svr_info = {}
  }
end

function ProtoMessage:newZoneGmQuerySceneAssetSvnVersionReq()
  return {
    scene_res_logic_id = nil,
    asset_type = nil,
    pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneGmQuerySceneAssetSvnVersionRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    scene_res_logic_id = nil,
    asset_type = nil,
    svn_version = nil
  }
end

function ProtoMessage:newZoneGmKickoutReq()
  return {
    uin = nil,
    open_id = nil,
    kickout_type = nil,
    kickout_sub_type = nil,
    kickout_txt_id = nil
  }
end

function ProtoMessage:newZoneGmKickoutRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientSetPlayerLevelReq()
  return {level = nil}
end

function ProtoMessage:newZoneGmClientSetPlayerLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientSetWorldLevelReq()
  return {level = nil}
end

function ProtoMessage:newZoneGmClientSetWorldLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientUnlockAllCampReq()
  return {}
end

function ProtoMessage:newZoneGmClientUnlockAllCampRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPlayerMoveCheckModifyReq()
  return {
    cancel_check_pos = nil,
    open_airwall_dead = nil,
    enable_tips = nil
  }
end

function ProtoMessage:newZoneGmPlayerMoveCheckModifyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetPlayerActivityStageRewardReq()
  return {reset_type = nil, uin = nil}
end

function ProtoMessage:newZoneGmResetPlayerActivityStageRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmOpenStageActivityReq()
  return {uin = nil, activity_id = nil}
end

function ProtoMessage:newZoneGmOpenStageActivityRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetPlayerActivityPartRewardReq()
  return {}
end

function ProtoMessage:newZoneGmResetPlayerActivityPartRewardRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPlayerActivityOptReq()
  return {
    uin = nil,
    activity_id = nil,
    opt_type = ProtoEnum.ZoneGmPlayerActivityOptReq.OptType.OPT_NONE
  }
end

function ProtoMessage:newZoneGmPlayerActivityOptRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDelActivityDataReq()
  return {uin = nil, activity_id = nil}
end

function ProtoMessage:newZoneGmDelActivityDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetBattlePassReq()
  return {}
end

function ProtoMessage:newZoneGmResetBattlePassRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPlayerStoryFlagModifyReq()
  return {
    story_flag = nil,
    extra_story_flags = {},
    is_add = nil
  }
end

function ProtoMessage:newZoneGmPlayerStoryFlagModifyRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmShowNavBoundReq()
  return {
    avatar_pos = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneGmShowNavBoundRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    pos = ProtoMessage:newPosition(),
    extent = ProtoMessage:newPosition()
  }
end

function ProtoMessage:newZoneGmClearAppearanceInfoReq()
  return {}
end

function ProtoMessage:newZoneGmClearAppearanceInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClearPetMedalReq()
  return {
    medal_gid = nil,
    medal_conf_id = nil,
    pet_gid = nil
  }
end

function ProtoMessage:newZoneGmClearPetMedalRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUnlockAppearanceInfoReq()
  return {uin = nil}
end

function ProtoMessage:newZoneGmUnlockAppearanceInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmRefreshRandomShopReq()
  return {uin = nil, shop_id = nil}
end

function ProtoMessage:newZoneGmRefreshRandomShopRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAdventureSettingReq()
  return {uin = nil, chapter_id = nil}
end

function ProtoMessage:newZoneGmAdventureSettingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSeasonAdventureSettingReq()
  return {
    uin = nil,
    chapter_id = nil,
    operate_type = nil,
    badge_lvl = nil
  }
end

function ProtoMessage:newZoneGmSeasonAdventureSettingRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmPvpRankReq()
  return {
    gm_op = ProtoEnum.ZoneGmPvpRankReq.PVP_RANK_GM_OP.PVP_RANK_GM_OP_SET_STAR,
    param1 = nil,
    param2 = nil
  }
end

function ProtoMessage:newZoneGmPvpRankRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClearGuideReq()
  return {
    group_id = nil,
    index = {}
  }
end

function ProtoMessage:newZoneGmClearGuideRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    sync_group = ProtoMessage:newGuideGroup()
  }
end

function ProtoMessage:newZoneSceneHomeGmAddExpReq()
  return {exp = nil}
end

function ProtoMessage:newZoneSceneHomeGmAddExpRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeGmModifyRoomLevelReq()
  return {level = nil}
end

function ProtoMessage:newZoneSceneHomeGmModifyRoomLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeGmSkipExpandWaitReq()
  return {remain_wait_secs = nil}
end

function ProtoMessage:newZoneSceneHomeGmSkipExpandWaitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomePlantGmResetReq()
  return {}
end

function ProtoMessage:newZoneSceneHomePlantGmResetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomePlantGmRipeReq()
  return {}
end

function ProtoMessage:newZoneSceneHomePlantGmRipeRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomePlantGmReapReq()
  return {land_id = nil, reap = nil}
end

function ProtoMessage:newZoneSceneHomePlantGmReapRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    reap = nil
  }
end

function ProtoMessage:newZoneSceneHomePlantGmStealLimitReq()
  return {limit = nil}
end

function ProtoMessage:newZoneSceneHomePlantGmStealLimitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    limit = nil
  }
end

function ProtoMessage:newZoneSceneHomePetGmStealReq()
  return {
    uin = nil,
    is_get = nil,
    steal_info = {}
  }
end

function ProtoMessage:newZoneSceneHomePetGmStealRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    steal_info = {}
  }
end

function ProtoMessage:newZoneHomePetGmHarvestReq()
  return {}
end

function ProtoMessage:newZoneHomePetGmHarvestRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneSceneHomeGmResetHomeLevelReq()
  return {}
end

function ProtoMessage:newZoneSceneHomeGmResetHomeLevelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneHomeGmDecomposeAllFurnitureReq()
  return {}
end

function ProtoMessage:newZoneHomeGmDecomposeAllFurnitureRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmFeedGridPosReq()
  return {reserve = nil}
end

function ProtoMessage:newZoneGmFeedGridPosRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    grid_pos = {}
  }
end

function ProtoMessage:newGridPos()
  return {
    grid_id = nil,
    pos = {}
  }
end

function ProtoMessage:newZoneGmShowTipsNotify()
  return {tips_str = nil}
end

function ProtoMessage:newZoneGmExecClientGmReq()
  return {type = nil, params = nil}
end

function ProtoMessage:newZoneGmExecClientGmRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClientNotify()
  return {
    request_id = nil,
    type = nil,
    params = nil
  }
end

function ProtoMessage:newZoneGmClientResponseReq()
  return {request_id = nil, result = nil}
end

function ProtoMessage:newZoneGmClientResponseRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsSkillCastByAssetReq()
  return {
    actor_id = nil,
    skill_id = nil,
    skill_asset_content = nil
  }
end

function ProtoMessage:newZoneGmDotsSkillCastByAssetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsSkillCastReq()
  return {actor_id = nil, skill_id = nil}
end

function ProtoMessage:newZoneGmDotsSkillCastRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsSkillStopReq()
  return {actor_id = nil, skill_id = nil}
end

function ProtoMessage:newZoneGmDotsSkillStopRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsSkillSnapshotReq()
  return {actor_id = nil}
end

function ProtoMessage:newZoneGmDotsSkillSnapshotRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsMfbtCastReq()
  return {
    actor_id = nil,
    behavior_id = nil,
    perform_group_id = nil
  }
end

function ProtoMessage:newZoneGmDotsMfbtCastRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmDotsMfbtCastByAssetReq()
  return {
    actor_id = nil,
    behavior_id = nil,
    behavior_tree_asset_content = nil
  }
end

function ProtoMessage:newZoneGmDotsMfbtCastByAssetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmLlmPetsBehaviorEvalReq()
  return {
    request_id = nil,
    eval = nil,
    param = nil
  }
end

function ProtoMessage:newZoneGmLlmPetsBehaviorEvalRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmAddStarLightReq()
  return {add_num = nil}
end

function ProtoMessage:newZoneGmAddStarLightRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmClearStarLightInfoReq()
  return {}
end

function ProtoMessage:newZoneGmClearStarLightInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetFashionSuitReq()
  return {suit_id = nil}
end

function ProtoMessage:newZoneGmSetFashionSuitRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    fashion_info = ProtoMessage:newPlayerAppearanceInfo_FashionInfo()
  }
end

function ProtoMessage:newZoneGmTestRandomShopResultReq()
  return {shop_id = nil, random_count = nil}
end

function ProtoMessage:newZoneGmTestRandomShopResultRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    shop_id = nil,
    goods_stats = {}
  }
end

function ProtoMessage:newGoodsStat()
  return {
    goods_id = nil,
    count = nil,
    goods_name = nil
  }
end

function ProtoMessage:newZoneGmDeleteRedPointDataReq()
  return {
    redpoint_reason = {}
  }
end

function ProtoMessage:newZoneGmDeleteRedPointDataRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmGetCommGmCmdsReq()
  return {}
end

function ProtoMessage:newZoneGmGetCommGmCmdsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    cmds = {}
  }
end

function ProtoMessage:newZoneGmExecCommGmCmdReq()
  return {
    cmd = ProtoMessage:newCommGmCmd()
  }
end

function ProtoMessage:newZoneGmExecCommGmCmdRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmGetPlayerBriefInfoReq()
  return {uin = nil}
end

function ProtoMessage:newZoneGmGetPlayerBriefInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    brief_info = ProtoMessage:newPlayerBriefInfo()
  }
end

function ProtoMessage:newZoneGmBatchGetPlayerBriefInfoReq()
  return {
    uin_list = {},
    groups = {}
  }
end

function ProtoMessage:newZoneGmBatchGetPlayerBriefInfoRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    brief_list = {}
  }
end

function ProtoMessage:newZoneGmStopPosCheckReq()
  return {}
end

function ProtoMessage:newZoneGmStopPosCheckRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmResetTeachingTabRewardsReq()
  return {}
end

function ProtoMessage:newZoneGmResetTeachingTabRewardsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmUnlockAllTeachingTabReq()
  return {}
end

function ProtoMessage:newZoneGmUnlockAllTeachingTabRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneGmSetGlobalChallengeProgressReq()
  return {
    activity_id = nil,
    belong_sign = nil,
    value = nil
  }
end

function ProtoMessage:newZoneGmSetGlobalChallengeProgressRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    activity_id = nil,
    belong_sign = nil,
    old_value = nil,
    new_value = nil
  }
end

function ProtoMessage:newZoneGmDistrGoodsReq()
  return {shop_id = nil, goods_id = nil}
end

function ProtoMessage:newZoneGmDistrGoodsRsp()
  return {
    ret_info = ProtoMessage:newRetInfo()
  }
end

function ProtoMessage:newZoneMailGetListReq()
  return {}
end

function ProtoMessage:newZoneMailGetListRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_list = ProtoMessage:newMailInfoList()
  }
end

function ProtoMessage:newZoneMailGetListByPageReq()
  return {page = nil, version = nil}
end

function ProtoMessage:newZoneMailGetListByPageRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_list = ProtoMessage:newMailInfoList(),
    total_page = nil,
    req_page = nil,
    page_num = nil,
    version = nil,
    no_new_data = nil
  }
end

function ProtoMessage:newZoneMailGetReq()
  return {mail_gid = nil}
end

function ProtoMessage:newZoneMailGetRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_info = {},
    version = nil
  }
end

function ProtoMessage:newZoneMailDelReq()
  return {
    mail_gid_list = {}
  }
end

function ProtoMessage:newZoneMailDelRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_gid_list = {},
    version = nil
  }
end

function ProtoMessage:newZoneMailReadReq()
  return {
    mail_gid_list = {}
  }
end

function ProtoMessage:newZoneMailReadRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_gid_list = {},
    version = nil
  }
end

function ProtoMessage:newZoneMailGetAttachmentReq()
  return {
    mail_gid = nil,
    token_info = ProtoMessage:newClientTokenInfo()
  }
end

function ProtoMessage:newZoneMailGetAttachmentRsp()
  return {
    ret_info = ProtoMessage:newRetInfo(),
    mail_brief = {},
    version = nil,
    get_fail_goods = {}
  }
end

function ProtoMessage:newGetFailGoodsInfo()
  return {
    goods_id = nil,
    type = ProtoEnum.GoodsType.GT_NONE,
    pet_base_id = nil
  }
end

return ProtoMessage
