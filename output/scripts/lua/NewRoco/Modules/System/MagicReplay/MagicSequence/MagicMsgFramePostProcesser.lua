local ParentTypeMask = 196608

function MakeFakeActorId(actorId)
  if nil == actorId or 0 == actorId then
    return actorId
  end
  if type(actorId) ~= "number" then
    Log.Error("MakeFakeActorId only for number!")
    return actorId
  end
  local newActorId = actorId | ParentTypeMask
  Log.Debug("[MagicSequence] MakeFakeActorId", actorId, "->", newActorId)
  return newActorId
end

local UIN_WORLD_SHARD_MASK = 4261412864

function MakeFakeUin(playerUin)
  if type(playerUin) ~= "number" then
    Log.Error("MakeFakeUin only for number!")
    return playerUin
  end
  local worldShardId = playerUin & UIN_WORLD_SHARD_MASK
  local reversedUniqueId = 0
  for i = 0, 24 do
    local currentBit = playerUin >> i & 1
    reversedUniqueId = reversedUniqueId | currentBit << 24 - i
  end
  local newUin = worldShardId | reversedUniqueId
  Log.Debug("[MagicSequence] MakeFakeUin", playerUin, "->", newUin)
  return newUin
end

function CheckOutRange(enterPos, centerPos, recordRadius, recordHeight)
  if recordHeight < math.abs(enterPos.z - centerPos.z) then
    return true
  end
  local squareXY = (enterPos.x - centerPos.x) * (enterPos.x - centerPos.x) + (enterPos.y - centerPos.y) * (enterPos.y - centerPos.y)
  if squareXY > recordRadius * recordRadius then
    return true
  end
  return false
end

local MagicMsgFramePostProcesser = {
  [".Next.ZoneChatUpdateChatInfoNotify"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      local baseInfo = seqForRecord.baseInfo
      local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if localPlayer and notify and notify.chat_message and notify.chat_message.uin == localPlayer:GetLogicId() and notify.chat_message.chat_message then
        table.insert(baseInfo.chat_msg, notify.chat_message.chat_message)
        return true
      end
      return false
    end,
    OutFunc = function(msg, seq)
      local notify = msg
      local seqForReplay = seq
      if notify and notify.chat_message and seqForReplay then
        if seqForReplay and table.contains(seqForReplay.baseInfo.chat_msg, notify.chat_message.chat_message) then
          notify.chat_message.uin = MakeFakeUin(notify.chat_message.uin)
          notify.chat_session.basic_info.uin = 0
          notify.chat_session.uin = 0
          Log.Debug("[MagicSequence][Validate] chat message ", notify.chat_message.chat_message)
          return true, nil
        else
          return false, "[Validate] Invalid chat message " .. notify.chat_message.chat_message
        end
      else
        return false, "ZoneChatUpdateChatInfoNotify is nil!"
      end
    end
  },
  [".Next.ZoneScenePlayActsNotify_actor_enter"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      local baseInfo = seqForRecord.baseInfo
      if notify and notify.acts and notify.acts[1] and notify.acts[1].actor_enter and notify.acts[1].actor_enter.actors[1] then
        local actor = notify.acts[1].actor_enter.actors[1]
        if actor.actor_detail_type == _G.ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal and actor.avatar then
          if CheckOutRange(actor.avatar.base.pt.pos, seqForRecord.createPos, seqForRecord.recordRadius, seqForRecord.recordHeight) then
            Log.Debug("[MagicSequence][Record] actor_enter not in range", actor.avatar.base.name, actor.avatar.base.actor_id)
            return false
          end
          if actor.avatar.wearing_item then
            for _, v in ipairs(actor.avatar.wearing_item) do
              if not table.contains(baseInfo.fashion_id, v.wearing_item_id) then
                table.insert(baseInfo.fashion_id, v.wearing_item_id)
              end
            end
          end
          table.insert(seqForRecord.associatedActorIds, actor.avatar.base.actor_id)
          Log.Debug("[MagicSequence][Record] actor_enter", actor.avatar.base.name, actor.avatar.base.actor_id)
          return true
        elseif actor.npc then
          if CheckOutRange(actor.npc.base.pt.pos, seqForRecord.createPos, seqForRecord.recordRadius, seqForRecord.recordHeight) then
            Log.Debug("[MagicSequence][Record] actor_enter not in range", actor.npc.base.name, actor.npc.base.actor_id)
            return false
          end
          if actor.npc and actor.npc.pet_info and actor.npc.pet_info.pet_base_conf_id and not table.contains(baseInfo.pet_base_id, actor.npc.pet_info.pet_base_conf_id) then
            table.insert(baseInfo.pet_base_id, actor.npc.pet_info.pet_base_conf_id)
          end
          table.insert(seqForRecord.associatedActorIds, actor.npc.base.actor_id)
          Log.Debug("[MagicSequence][Record] actor_enter", actor.npc.base.name, actor.npc.base.actor_id)
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg, seq)
      local notify = msg
      local seqForReplay = seq
      if notify and notify.acts and notify.acts[1] and notify.acts[1].actor_enter and notify.acts[1].actor_enter.actors[1] and seqForReplay then
        local actor_enter = notify.acts[1].actor_enter
        if actor_enter and actor_enter.actors and actor_enter.actors[1] then
          local actor = actor_enter.actors[1]
          if actor.actor_detail_type == _G.ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal and actor.avatar then
            actor.avatar.base.actor_id = MakeFakeActorId(actor.avatar.base.actor_id)
            actor.avatar.is_magic_replay = true
            _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.SetMainMagicActorId, actor.avatar.base.actor_id)
            actor.avatar.base.logic_id = MakeFakeUin(actor.avatar.base.logic_id)
            if actor.avatar.wearing_item then
              for _, v in ipairs(actor.avatar.wearing_item) do
                if not table.contains(seqForReplay.baseInfo.fashion_id, v.wearing_item_id) then
                  return false, "[Validate] Invalid fashion_id " .. v.wearing_item_id
                else
                  Log.Debug("[MagicSequence][Validate] Valid fashion_id " .. v.wearing_item_id)
                end
              end
            elseif seqForReplay.baseInfo.fashion_id and #seqForReplay.baseInfo.fashion_id > 0 then
              return false, "[Validate] actor.avatar.wearing_item not equal to baseInfo.fashion_id"
            end
          elseif actor.npc then
            actor.npc.base.actor_id = MakeFakeActorId(actor.npc.base.actor_id)
            actor.npc.base.owner_id = MakeFakeActorId(actor.npc.base.owner_id)
            actor.npc.npc_base.create_avatar_id = MakeFakeActorId(actor.npc.npc_base.create_avatar_id)
            actor.npc.is_magic_replay = true
            if actor.npc.pet_info and actor.npc.pet_info.pet_base_conf_id then
              if not table.contains(seqForReplay.baseInfo.pet_base_id, actor.npc.pet_info.pet_base_conf_id) then
                return false, "[Validate] Invalid pet_base_id " .. actor.npc.pet_info.pet_base_conf_id
              else
                Log.Debug("[MagicSequence][Validate] Valid pet_base_id", actor.npc.pet_info.pet_base_conf_id)
              end
            end
          end
        end
        return true, nil
      else
        return false, "Invalid ZoneScenePlayActsNotify actor enter!"
      end
    end
  },
  [".Next.ZoneScenePlayActsNotify_actor_leave"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local actor_leave = notify.acts[1].actor_leave
        if actor_leave.actor_ids and #actor_leave.actor_ids > 0 and table.contains(seqForRecord.associatedActorIds, actor_leave.actor_ids[1]) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local actor_leave = notify.acts[1].actor_leave
        if actor_leave and actor_leave.actor_ids and #actor_leave.actor_ids > 0 then
          actor_leave.actor_ids[1] = MakeFakeActorId(actor_leave.actor_ids[1])
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_idle_skill"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local idle_skill = notify.acts[1].idle_skill
        if idle_skill and idle_skill.actor_id and table.contains(seqForRecord.associatedActorIds, idle_skill.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local idle_skill = notify.acts[1].idle_skill
        if idle_skill then
          if idle_skill.actor_id then
            idle_skill.actor_id = MakeFakeActorId(idle_skill.actor_id)
          end
          if idle_skill.pet_actor_id then
            idle_skill.pet_actor_id = MakeFakeActorId(idle_skill.pet_actor_id)
          end
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_client_move"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local client_move = notify.acts[1].client_move
        if client_move and client_move.actor_id and table.contains(seqForRecord.associatedActorIds, client_move.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local client_move = notify.acts[1].client_move
        if client_move and client_move.actor_id then
          client_move.actor_id = MakeFakeActorId(client_move.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_sync_player_status"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local sync_player_status = notify.acts[1].sync_player_status
        if sync_player_status and sync_player_status.actor_id and table.contains(seqForRecord.associatedActorIds, sync_player_status.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local sync_player_status = notify.acts[1].sync_player_status
        if sync_player_status and sync_player_status.actor_id then
          sync_player_status.actor_id = MakeFakeActorId(sync_player_status.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_update_actor_logic_status"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local update_actor_logic_status = notify.acts[1].update_actor_logic_status
        if update_actor_logic_status and update_actor_logic_status.actor_id and table.contains(seqForRecord.associatedActorIds, update_actor_logic_status.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local update_actor_logic_status = notify.acts[1].update_actor_logic_status
        if update_actor_logic_status and update_actor_logic_status.actor_id then
          update_actor_logic_status.actor_id = MakeFakeActorId(update_actor_logic_status.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_throw_catch_notify"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local throw_catch_notify = notify.acts[1]
        if throw_catch_notify and throw_catch_notify.caster_id and table.contains(seqForRecord.associatedActorIds, throw_catch_notify.caster_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local throw_catch_notify = notify.acts[1]
        if throw_catch_notify and throw_catch_notify.caster_id then
          throw_catch_notify.caster_id = MakeFakeActorId(throw_catch_notify.caster_id)
        end
        if throw_catch_notify and throw_catch_notify.npc_id then
          throw_catch_notify.npc_id = MakeFakeActorId(throw_catch_notify.npc_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_fashion_change"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      local baseInfo = seqForRecord.baseInfo
      if notify and notify.acts and notify.acts[1] then
        local fashion_change = notify.acts[1].fashion_change
        if fashion_change and fashion_change.actor_id and table.contains(seqForRecord.associatedActorIds, fashion_change.actor_id) then
          if fashion_change.wearing_item then
            for _, v in ipairs(fashion_change.wearing_item) do
              if not table.contains(baseInfo.fashion_id, v.wearing_item_id) then
                table.insert(baseInfo.fashion_id, v.wearing_item_id)
              end
            end
          end
          return true
        end
      end
    end,
    OutFunc = function(msg, seq)
      local notify = msg
      local seqForReplay = seq
      if notify and notify.acts and notify.acts[1] and seqForReplay then
        local fashion_change = notify.acts[1].fashion_change
        if fashion_change and fashion_change.actor_id then
          fashion_change.actor_id = MakeFakeActorId(fashion_change.actor_id)
        end
        if fashion_change.wearing_item then
          for _, v in ipairs(fashion_change.wearing_item) do
            if not table.contains(seqForReplay.baseInfo.fashion_id, v.wearing_item_id) then
              return false, "[Validate] Invalid fashion_id " .. v.wearing_item_id
            else
              Log.Debug("[MagicSequence][Validate] Valid fashion_id ", v.wearing_item_id)
            end
          end
        end
        return true, nil
      else
        return false, "Invalid ZoneScenePlayActsNotify fashion_change!"
      end
    end
  },
  [".Next.ZoneScenePlayActsNotify_salon_change"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local salon_change = notify.acts[1].salon_change
        if salon_change and salon_change.actor_id and table.contains(seqForRecord.associatedActorIds, salon_change.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local salon_change = notify.acts[1].salon_change
        if salon_change and salon_change.actor_id then
          salon_change.actor_id = MakeFakeActorId(salon_change.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_animation"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_animation = notify.acts[1].play_animation
        if play_animation and play_animation.actor_id and table.contains(seqForRecord.associatedActorIds, play_animation.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_animation = notify.acts[1].play_animation
        if play_animation and play_animation.actor_id then
          play_animation.actor_id = MakeFakeActorId(play_animation.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_stop_animation"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local stop_animation = notify.acts[1].stop_animation
        if stop_animation and stop_animation.actor_id and table.contains(seqForRecord.associatedActorIds, stop_animation.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local stop_animation = notify.acts[1].stop_animation
        if stop_animation and stop_animation.actor_id then
          stop_animation.actor_id = MakeFakeActorId(stop_animation.actor_id)
        end
      end
    end
  },
  [".Next.ZoneScenePlayActsNotify_anim_pause_or_resume"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local anim_pause_or_resume = notify.acts[1].anim_pause_or_resume
        if anim_pause_or_resume and anim_pause_or_resume.actor_id and table.contains(seqForRecord.associatedActorIds, anim_pause_or_resume.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local anim_pause_or_resume = notify.acts[1].anim_pause_or_resume
        if anim_pause_or_resume and anim_pause_or_resume.actor_id then
          anim_pause_or_resume.actor_id = MakeFakeActorId(anim_pause_or_resume.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_server_move"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local server_move = notify.acts[1].server_move
        if server_move and server_move.actor_id and table.contains(seqForRecord.associatedActorIds, server_move.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local server_move = notify.acts[1].server_move
        if server_move and server_move.actor_id then
          server_move.actor_id = MakeFakeActorId(server_move.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_interrupt_server_move"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local interrupt_server_move = notify.acts[1].interrupt_server_move
        if interrupt_server_move and interrupt_server_move.actor_id and table.contains(seqForRecord.associatedActorIds, interrupt_server_move.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local interrupt_server_move = notify.acts[1].interrupt_server_move
        if interrupt_server_move and interrupt_server_move.actor_id then
          interrupt_server_move.actor_id = MakeFakeActorId(interrupt_server_move.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_turn_to"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local turn_to = notify.acts[1].turn_to
        if turn_to and turn_to.actor_id and table.contains(seqForRecord.associatedActorIds, turn_to.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local turn_to = notify.acts[1].turn_to
        if turn_to and turn_to.actor_id then
          turn_to.actor_id = MakeFakeActorId(turn_to.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_cancel_turn_to"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local cancel_turn_to = notify.acts[1].cancel_turn_to
        if cancel_turn_to and cancel_turn_to.actor_id and table.contains(seqForRecord.associatedActorIds, cancel_turn_to.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local cancel_turn_to = notify.acts[1].cancel_turn_to
        if cancel_turn_to and cancel_turn_to.actor_id then
          cancel_turn_to.actor_id = MakeFakeActorId(cancel_turn_to.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_world_attack"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local world_attack = notify.acts[1].world_attack
        if world_attack and world_attack.actor_id and table.contains(seqForRecord.associatedActorIds, world_attack.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local world_attack = notify.acts[1].world_attack
        if world_attack and world_attack.actor_id then
          world_attack.actor_id = MakeFakeActorId(world_attack.actor_id)
          world_attack.target_actor_id = MakeFakeActorId(world_attack.target_actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_stop_world_attack"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local stop_world_attack = notify.acts[1].stop_world_attack
        if stop_world_attack and stop_world_attack.actor_id and table.contains(seqForRecord.associatedActorIds, stop_world_attack.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local stop_world_attack = notify.acts[1].stop_world_attack
        if stop_world_attack and stop_world_attack.actor_id then
          stop_world_attack.actor_id = MakeFakeActorId(stop_world_attack.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_perception_effect"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_perception_effect = notify.acts[1].play_perception_effect
        if play_perception_effect and play_perception_effect.actor_id and table.contains(seqForRecord.associatedActorIds, play_perception_effect.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_perception_effect = notify.acts[1].play_perception_effect
        if play_perception_effect and play_perception_effect.actor_id then
          play_perception_effect.actor_id = MakeFakeActorId(play_perception_effect.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_skill"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_skill = notify.acts[1].play_skill
        if play_skill and play_skill.actor_id and table.contains(seqForRecord.associatedActorIds, play_skill.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_skill = notify.acts[1].play_skill
        if play_skill and play_skill.actor_id then
          play_skill.actor_id = MakeFakeActorId(play_skill.actor_id)
          play_skill.target_id = MakeFakeActorId(play_skill.target_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_stop_skill"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local stop_skill = notify.acts[1].stop_skill
        if stop_skill and stop_skill.actor_id and table.contains(seqForRecord.associatedActorIds, stop_skill.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local stop_skill = notify.acts[1].stop_skill
        if stop_skill and stop_skill.actor_id then
          stop_skill.actor_id = MakeFakeActorId(stop_skill.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_world_hidden"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local world_hidden = notify.acts[1].world_hidden
        if world_hidden and world_hidden.actor_id and table.contains(seqForRecord.associatedActorIds, world_hidden.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local world_hidden = notify.acts[1].world_hidden
        if world_hidden and world_hidden.actor_id then
          world_hidden.actor_id = MakeFakeActorId(world_hidden.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_world_unhidden"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local world_unhidden = notify.acts[1].world_unhidden
        if world_unhidden and world_unhidden.actor_id and table.contains(seqForRecord.associatedActorIds, world_unhidden.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local world_unhidden = notify.acts[1].world_unhidden
        if world_unhidden and world_unhidden.actor_id then
          world_unhidden.actor_id = MakeFakeActorId(world_unhidden.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_look_at"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local look_at = notify.acts[1].look_at
        if look_at and look_at.actor_id and table.contains(seqForRecord.associatedActorIds, look_at.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local look_at = notify.acts[1].look_at
        if look_at and look_at.actor_id then
          look_at.actor_id = MakeFakeActorId(look_at.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_server_fly"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local server_fly = notify.acts[1].server_fly
        if server_fly and server_fly.actor_id and table.contains(seqForRecord.associatedActorIds, server_fly.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local server_fly = notify.acts[1].server_fly
        if server_fly and server_fly.actor_id then
          server_fly.actor_id = MakeFakeActorId(server_fly.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_zoom_animation"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_zoom_animation = notify.acts[1].play_zoom_animation
        if play_zoom_animation and play_zoom_animation.actor_id and table.contains(seqForRecord.associatedActorIds, play_zoom_animation.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_zoom_animation = notify.acts[1].play_zoom_animation
        if play_zoom_animation and play_zoom_animation.actor_id then
          play_zoom_animation.actor_id = MakeFakeActorId(play_zoom_animation.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_voice"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_voice = notify.acts[1].play_voice
        if play_voice and play_voice.actor_id and table.contains(seqForRecord.associatedActorIds, play_voice.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_voice = notify.acts[1].play_voice
        if play_voice and play_voice.actor_id then
          play_voice.actor_id = MakeFakeActorId(play_voice.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_server_ai_jump"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local server_ai_jump = notify.acts[1].server_ai_jump
        if server_ai_jump and server_ai_jump.actor_id and table.contains(seqForRecord.associatedActorIds, server_ai_jump.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local server_ai_jump = notify.acts[1].server_ai_jump
        if server_ai_jump and server_ai_jump.actor_id then
          server_ai_jump.actor_id = MakeFakeActorId(server_ai_jump.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_cancel_server_ai_jump"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local cancel_server_ai_jump = notify.acts[1].cancel_server_ai_jump
        if cancel_server_ai_jump and cancel_server_ai_jump.actor_id and table.contains(seqForRecord.associatedActorIds, cancel_server_ai_jump.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local cancel_server_ai_jump = notify.acts[1].cancel_server_ai_jump
        if cancel_server_ai_jump and cancel_server_ai_jump.actor_id then
          cancel_server_ai_jump.actor_id = MakeFakeActorId(cancel_server_ai_jump.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_play_real_time_dialog"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local play_real_time_dialog = notify.acts[1].play_real_time_dialog
        if play_real_time_dialog and play_real_time_dialog.actor_id and table.contains(seqForRecord.associatedActorIds, play_real_time_dialog.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local play_real_time_dialog = notify.acts[1].play_real_time_dialog
        if play_real_time_dialog and play_real_time_dialog.actor_id then
          v.actor_id = MakeFakeActorId(play_real_time_dialog.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_stop_real_time_dialog"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local stop_real_time_dialog = notify.acts[1].stop_real_time_dialog
        if stop_real_time_dialog and stop_real_time_dialog.actor_id and table.contains(seqForRecord.associatedActorIds, stop_real_time_dialog.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local stop_real_time_dialog = notify.acts[1].stop_real_time_dialog
        if stop_real_time_dialog and stop_real_time_dialog.actor_id then
          stop_real_time_dialog.actor_id = MakeFakeActorId(stop_real_time_dialog.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_stick_to"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local stick_to = notify.acts[1].stick_to
        if stick_to and stick_to.actor_id and table.contains(seqForRecord.associatedActorIds, stick_to.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local stick_to = notify.acts[1].stick_to
        if stick_to and stick_to.actor_id then
          stick_to.actor_id = MakeFakeActorId(stick_to.actor_id)
          stick_to.target_actor_id = MakeFakeActorId(stick_to.target_actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_finish_stick_to"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local finish_stick_to = notify.acts[1].finish_stick_to
        if finish_stick_to and finish_stick_to.actor_id and table.contains(seqForRecord.associatedActorIds, finish_stick_to.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local finish_stick_to = notify.acts[1].finish_stick_to
        if finish_stick_to and finish_stick_to.actor_id then
          finish_stick_to.actor_id = MakeFakeActorId(finish_stick_to.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_ai_try_interact_npc"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local ai_try_interact_npc = notify.acts[1].ai_try_interact_npc
        if ai_try_interact_npc and ai_try_interact_npc.actor_id and table.contains(seqForRecord.associatedActorIds, ai_try_interact_npc.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local ai_try_interact_npc = notify.acts[1].ai_try_interact_npc
        if ai_try_interact_npc and ai_try_interact_npc.actor_id then
          ai_try_interact_npc.actor_id = MakeFakeActorId(ai_try_interact_npc.actor_id)
          ai_try_interact_npc.interact_actor_id = MakeFakeActorId(ai_try_interact_npc.interact_actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_velocity_oriented_rotation"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local velocity_oriented_rotation = notify.acts[1].velocity_oriented_rotation
        if velocity_oriented_rotation and velocity_oriented_rotation.actor_id and table.contains(seqForRecord.associatedActorIds, velocity_oriented_rotation.actor_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local velocity_oriented_rotation = notify.acts[1].velocity_oriented_rotation
        if velocity_oriented_rotation and velocity_oriented_rotation.actor_id then
          velocity_oriented_rotation.actor_id = MakeFakeActorId(velocity_oriented_rotation.actor_id)
        end
      end
      return true, nil
    end
  },
  [".Next.ZoneScenePlayActsNotify_client_operation"] = {
    InFunc = function(msg, seq)
      local notify = msg
      local seqForRecord = seq
      if notify and notify.acts and notify.acts[1] then
        local client_operation = notify.acts[1].client_operation
        if client_operation and client_operation.operation.operator_id and table.contains(seqForRecord.associatedActorIds, client_operation.operation.operator_id) then
          return true
        end
      end
      return false
    end,
    OutFunc = function(msg)
      local notify = msg
      if notify and notify.acts and notify.acts[1] then
        local client_operation = notify.acts[1].client_operation
        if client_operation and client_operation.operation.operator_id then
          client_operation.operation.operator_id = MakeFakeActorId(client_operation.operation.operator_id)
        end
      end
      return true, nil
    end
  }
}
return MagicMsgFramePostProcesser
