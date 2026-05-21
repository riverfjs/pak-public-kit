local rapidjson = require("rapidjson")
local AICoachModuleUtils = {}
AICoachModuleUtils.EnumAICoachEmotion = {
  Idle = 0,
  Think = 1,
  Answer = 2
}
AICoachModuleUtils.SSEEventType = {
  Emotion = "emotion",
  TextChunk = "text",
  TTSChunk = "tts",
  Lineup = "lineup",
  RichText = "rich_text",
  Image = "image",
  Done = "done",
  Error = "error_code",
  NarrationTextChunk = "narration_text",
  NarrationTTSChunk = "narration_tts"
}
AICoachModuleUtils.EnumTalentType = {
  None = 0,
  Attack = Enum.AttributeType.AT_PHYATK,
  Defense = Enum.AttributeType.AT_PHYDEF,
  Speed = Enum.AttributeType.AT_SPEED,
  HP = Enum.AttributeType.AT_HPMAX,
  SpecialAttack = Enum.AttributeType.AT_SPEATK,
  SpecialDefense = Enum.AttributeType.AT_SPEDEF
}

function AICoachModuleUtils.ParseJSON(jsonStr)
  if not jsonStr or "" == jsonStr then
    return nil
  end
  local success, result = pcall(rapidjson.decode, jsonStr)
  if success then
    return result
  else
    Log.Error("[AICoachModuleUtils] ParseJSON failed: " .. tostring(result))
    return nil
  end
end

function AICoachModuleUtils.ParseSSELine(line)
  if not line or "" == line then
    return nil, nil
  end
  local eventType = string.match(line, "^event:%s*(.+)$")
  if eventType then
    return eventType, nil
  end
  local dataStr = string.match(line, "^data:%s*(.+)$")
  if dataStr then
    local data = AICoachModuleUtils.ParseJSON(dataStr)
    return nil, data
  end
  return nil, nil
end

function AICoachModuleUtils.ParseSSEStream(sseContent)
  local result = {
    emotion = nil,
    textChunks = {},
    ttsChunks = {},
    lineup = nil,
    richText = nil,
    image = nil,
    done = nil,
    fullText = ""
  }
  if not sseContent or "" == sseContent then
    return result
  end
  local currentEvent
  local lines = {}
  for line in string.gmatch(sseContent, "[^\r\n]+") do
    table.insert(lines, line)
  end
  for _, line in ipairs(lines) do
    local eventType, eventData = AICoachModuleUtils.ParseSSELine(line)
    if eventType then
      currentEvent = eventType
    elseif eventData and currentEvent then
      AICoachModuleUtils.ProcessEventData(result, currentEvent, eventData)
      currentEvent = nil
    end
  end
  return result
end

function AICoachModuleUtils.ProcessEventData(result, eventType, eventData)
  if eventType == AICoachModuleUtils.SSEEventType.Emotion then
    result.emotion = {
      type = eventData.type,
      emotion = eventData.emotion,
      emotionName = eventData.emotion_name,
      emotionUrl = eventData.emotion_url
    }
  elseif eventType == AICoachModuleUtils.SSEEventType.TextChunk then
    local chunk = {
      type = eventData.type,
      content = eventData.content,
      index = eventData.index
    }
    table.insert(result.textChunks, chunk)
  elseif eventType == AICoachModuleUtils.SSEEventType.NarrationTextChunk then
    local chunk = {
      type = eventData.type,
      content = eventData.content,
      index = eventData.index
    }
    table.insert(result.narrationTextChunks, chunk)
  elseif eventType == AICoachModuleUtils.SSEEventType.TTSChunk then
    local chunk = {
      type = eventData.type,
      audioBase64 = eventData.audio_base64,
      index = eventData.index
    }
    table.insert(result.ttsChunks, chunk)
  elseif eventType == AICoachModuleUtils.SSEEventType.NarrationTTSChunk then
    local chunk = {
      type = eventData.type,
      audioBase64 = eventData.audio_base64,
      index = eventData.index
    }
    table.insert(result.narrationTtsChunks, chunk)
  elseif eventType == AICoachModuleUtils.SSEEventType.Lineup then
    local lineupData = AICoachModuleUtils.ParseJSON(eventData.lineup_data)
    result.lineup = {
      type = eventData.type,
      lineupId = eventData.lineup_id,
      lineupData = lineupData
    }
    if lineupData then
      result.lineup.magicId = lineupData.magicid
      result.lineup.teamType = lineupData.team_type
      result.lineup.pets = AICoachModuleUtils.ParsePetsData(lineupData.pets)
    end
  elseif eventType == AICoachModuleUtils.SSEEventType.RichText then
    result.richText = {
      type = eventData.type,
      content = eventData.content
    }
  elseif eventType == AICoachModuleUtils.SSEEventType.Image then
    result.image = {
      type = eventData.type,
      imageUrl = eventData.image_url,
      imageDesc = eventData.image_desc
    }
  elseif eventType == AICoachModuleUtils.SSEEventType.Done then
    result.done = {
      type = eventData.type,
      totalChunks = eventData.total_chunks,
      requestId = eventData.request_id,
      sessionId = eventData.session_id
    }
  elseif eventType == AICoachModuleUtils.SSEEventType.Error then
    result.error = {
      code = eventData.ret_code
    }
  end
end

function AICoachModuleUtils.ParsePetsData(petsData)
  local pets = {}
  if not petsData then
    return pets
  end
  for _, petData in ipairs(petsData) do
    local pet = {
      petbaseId = petData.petbase_id,
      bloodline = petData.bloodline,
      upCharacterId = petData.nature_up,
      downCharacterId = petData.nature_down,
      talentAName = petData.talent_a_name,
      talentBName = petData.talent_b_name,
      talentCName = petData.talent_c_name,
      skillAId = petData.skill_a_id,
      skillBId = petData.skill_b_id,
      skillCId = petData.skill_c_id,
      skillDId = petData.skill_d_id,
      nature = petData.nature_id
    }
    table.insert(pets, pet)
  end
  return pets
end

function AICoachModuleUtils.CreateEmptySSEResult()
  return {
    emotion = nil,
    textChunks = {},
    ttsChunks = {},
    lineup = nil,
    richText = nil,
    image = nil,
    done = nil,
    fullText = ""
  }
end

function AICoachModuleUtils.ParseSSEEventIncremental(result, eventType, dataStr)
  result = result or AICoachModuleUtils.CreateEmptySSEResult()
  local eventData = AICoachModuleUtils.ParseJSON(dataStr)
  if eventData then
    AICoachModuleUtils.ProcessEventData(result, eventType, eventData)
  end
  return result
end

local AICoachName = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_player_name", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
local AICoachTeamName = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_team_name", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
local AICoachHeadPicture = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_head_picture", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
local AICoachPetLevel = _G.DataConfigManager:GetGlobalConfigByKeyType("ai_coach_pet_level", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num

function AICoachModuleUtils.ConvertLineupData(lineup)
  local teamInfo = ProtoMessage:newRecommendPetTeamInfo()
  if not lineup then
    return teamInfo
  end
  teamInfo.player_name = AICoachName
  teamInfo.player_headpic = AICoachHeadPicture
  teamInfo.pet_level = AICoachPetLevel
  teamInfo.team_name = AICoachTeamName
  teamInfo.team_id = tonumber(lineup.lineupId) or 10001
  local petTeamInfo = teamInfo.pet_team_info
  petTeamInfo.team_name = AICoachTeamName
  petTeamInfo.team_type = 5
  petTeamInfo.role_magic_id = tonumber(lineup.magicId)
  for _, pet in ipairs(lineup.pets) do
    local petInfo = ProtoMessage:newSharedPetInfo()
    petInfo.base_conf_id = tonumber(pet.petbaseId)
    petInfo.nature = tonumber(pet.nature)
    petInfo.blood_id = tonumber(pet.bloodline)
    petInfo.changed_nature_pos_attr_type = tonumber(pet.upCharacterId or "0")
    petInfo.changed_nature_neg_attr_type = tonumber(pet.downCharacterId or "0")
    AICoachModuleUtils.InitTalentData(petInfo)
    AICoachModuleUtils.SetTalentData(petInfo, tonumber(pet.talentAName))
    AICoachModuleUtils.SetTalentData(petInfo, tonumber(pet.talentBName))
    AICoachModuleUtils.SetTalentData(petInfo, tonumber(pet.talentCName))
    AICoachModuleUtils.SetSkillData(petInfo.skills, pet.skillAId, 1)
    AICoachModuleUtils.SetSkillData(petInfo.skills, pet.skillBId, 2)
    AICoachModuleUtils.SetSkillData(petInfo.skills, pet.skillCId, 3)
    AICoachModuleUtils.SetSkillData(petInfo.skills, pet.skillDId, 4)
    table.insert(petTeamInfo.pets, petInfo)
  end
  return teamInfo
end

function AICoachModuleUtils.SetSkillData(skillInfo, skillID, pos)
  local Info = ProtoMessage:newPetSkillEquipInfo()
  Info.id = tonumber(skillID)
  Info.pos = pos
  table.insert(skillInfo, Info)
end

function AICoachModuleUtils.InitTalentData(petInfo)
  petInfo.attack_talent = 0
  petInfo.defense_talent = 0
  petInfo.hp_talent = 0
  petInfo.special_attack_talent = 0
  petInfo.special_defense_talent = 0
  petInfo.speed_talent = 0
end

function AICoachModuleUtils.SetTalentData(petInfo, talentType)
  if talentType == AICoachModuleUtils.EnumTalentType.Attack then
    petInfo.attack_talent = 1
  elseif talentType == AICoachModuleUtils.EnumTalentType.Defense then
    petInfo.defense_talent = 1
  elseif talentType == AICoachModuleUtils.EnumTalentType.HP then
    petInfo.hp_talent = 1
  elseif talentType == AICoachModuleUtils.EnumTalentType.SpecialAttack then
    petInfo.special_attack_talent = 1
  elseif talentType == AICoachModuleUtils.EnumTalentType.SpecialDefense then
    petInfo.special_defense_talent = 1
  elseif talentType == AICoachModuleUtils.EnumTalentType.Speed then
    petInfo.speed_talent = 1
  end
end

function AICoachModuleUtils.PlayAICoachVoice(filePath)
  _G.GVoiceManager:PlayRecordedFile(filePath)
end

function AICoachModuleUtils.SaveAICoachVoiceFile(base64Audio, fileName)
  local decoData = {}
  decoData = UE4.UNRCStatics.DecodeBase64(base64Audio, decoData)
  local filePath, PathSegs
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "UE4Game",
      "NRC",
      "NRC",
      "Saved"
    }
    filePath = UE.UBlueprintPathsLibrary.Combine(PathSegs)
  else
    filePath = UE.UNRCStatics.ConvertToAbsolutePath(UE4.UBlueprintPathsLibrary.ProjectSavedDir(), false)
  end
  fileName = fileName or "AICoachVoice"
  filePath = filePath .. fileName .. ".opus"
  UE4.UNRCStatics.SaveByteArrayToFile(decoData, filePath)
  Log.Debug(string.format("AICoachModuleUtils.PlayAICoachVoice, final filePath:%s", filePath))
  return filePath
end

function AICoachModuleUtils.ConvertHtmlToUERichText(htmlText)
  if not htmlText then
    return ""
  end
  local result = htmlText
  result = string.gsub(result, "<p>", "")
  result = string.gsub(result, "</p>", "\n")
  result = string.gsub(result, "<strong>", "<RichText.Bold>")
  result = string.gsub(result, "</strong>", "</>")
  result = string.gsub(result, "<em>", "<RichText.Italic>")
  result = string.gsub(result, "</em>", "</>")
  result = string.gsub(result, "<br>", "\n")
  result = string.gsub(result, "<br/>", "\n")
  result = string.gsub(result, "<br />", "\n")
  result = string.gsub(result, "<[^>]+>", "")
  return result
end

function AICoachModuleUtils.StopPlayVoice()
  _G.GVoiceManager:StopPlayRecordedFile()
end

function AICoachModuleUtils.ConvertTeamDataToJson(fullData, OriginData)
  local lineupJson = {}
  lineupJson.magicid = tostring(magicid)
  lineupJson.lineup_data = lineup.lineupData
  local success, result = pcall(rapidjson.encode, lineupJson)
  if not success then
    Log.Error("AICoachModuleUtils.ConvertLineupDataToJson failed~")
    return nil
  end
  return result
end

function AICoachModuleUtils.GetTalentValue(hp, attack, specialAttack, defense, specialDefense, speed)
  local talentList = {}
  if hp and hp > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.HP)
  end
  if attack and attack > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.Attack)
  end
  if specialAttack and specialAttack > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.SpecialAttack)
  end
  if defense and defense > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.Defense)
  end
  if specialDefense and specialDefense > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.SpecialDefense)
  end
  if speed and speed > 0 then
    table.insert(talentList, AICoachModuleUtils.EnumTalentType.Speed)
  end
  return talentList
end

return AICoachModuleUtils
