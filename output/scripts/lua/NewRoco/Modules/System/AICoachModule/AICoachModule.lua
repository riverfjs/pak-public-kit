local AICoachModuleUtils = require("NewRoco.Modules.System.AICoachModule.AICoachModuleUtils")
local AICoachModuleEvent = require("NewRoco.Modules.System.AICoachModule.AICoachModuleEvent")
local AICoachModule = NRCModuleBase:Extend("AICoachModule")

function AICoachModule:OnConstruct()
  _G.AICoachModuleCmd = reload("NewRoco.Modules.System.AICoachModule.AICoachModuleCmd")
  self.data = self:SetData("AICoachModuleData", "NewRoco.Modules.System.AICoachModule.AICoachModuleData")
  self.isInWhiteList = false
  self.currAICoachState = ProtoEnum.AiCoachStatus.ACS_CLOSED
  self.isAICoachActive = false
  self.isVoicePlaying = false
  self.sceneTypeList = {}
  self.currEmotion = AICoachModuleUtils.EnumAICoachEmotion.Idle
  self.sessionId = nil
  self.requestId = nil
  self.requestTime = 0
  self.isMsgPushed = false
  self.cacheMainVolume = 0
  self.cacheMusicVolume = 0
  self.cacheSFXVolume = 0
  self.cachePetVolume = 0
  self.isAudioStreamPlay = false
end

function AICoachModule:OnActive()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_RECOMMEND_LINEUP_NOTIFY, self.OnReceiveAICoachAnswer)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_WHITE_LIST_RSP, self.OnRequestPlayerInWhiteListRsp)
  _G.NRCEventCenter:RegisterEvent("AICoachModule::OnVoiceFinishCallBack", self, AICoachModuleEvent.OnPlayRecordedFileFinished, self.OnVoiceFinishCallBack)
  local settingData = DataModelMgr.PlayerDataModel:GetPlayerSettingData()
  if settingData then
    self.currAICoachState = settingData.ai_coach_status or ProtoEnum.AiCoachStatus.ACS_CLOSED
  end
  self:OnRequestPlayerInWhiteList()
end

function AICoachModule:OnRelogin()
end

function AICoachModule:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_RECOMMEND_LINEUP_NOTIFY, self.OnReceiveAICoachAnswer)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_WHITE_LIST_RSP, self.OnRequestPlayerInWhiteListRsp)
  _G.NRCEventCenter:UnRegisterEvent(self, AICoachModuleEvent.OnPlayRecordedFileFinished, self.OnVoiceFinishCallBack)
end

function AICoachModule:OnDestruct()
end

function AICoachModule:GetIsCurrAICoachOpen()
  return self.currAICoachState == ProtoEnum.AiCoachStatus.ACS_QA
end

function AICoachModule:GetIsPlayerInWhiteList()
  return self.isInWhiteList
end

function AICoachModule:GetCurrAICoachScene()
  if self.sceneTypeList and #self.sceneTypeList > 0 then
    return self.sceneTypeList[1]
  end
  return 0
end

function AICoachModule:GetSysAICoachSceneIsOpen(scene)
  local isAICoachBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_AI_COACH, false)
  local isAICoachTeamBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, scene, false)
  return not isAICoachBan and not isAICoachTeamBan
end

function AICoachModule:Clear()
  self.sceneTypeList = {}
  self.sessionId = ""
  self:OnStop()
end

function AICoachModule:OnStop()
  self.data:Clear()
  self.requestId = ""
  if self.isVoicePlaying then
    self.isVoicePlaying = false
    AICoachModuleUtils.StopPlayVoice()
  end
end

function AICoachModule:OnUpdateAICoachEmotion(emotion)
  if self.currEmotion == emotion then
    return
  end
  self.currEmotion = emotion
  _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachEmotionChange, emotion)
end

function AICoachModule:SetAICoachTeamDiffJson(json)
  self.data:OnSetRecommendDiffJson(json)
end

function AICoachModule:OnCacheGameAudio()
  if 0 == self.cacheMainVolume then
    self.cacheMainVolume = _G.NRCAudioManager:GetGlobalRTPC("Backstage_Master_RTPC")
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Master_RTPC", 2)
  end
  if 0 == self.cacheMusicVolume then
    self.cacheMusicVolume = _G.NRCAudioManager:GetGlobalRTPC("Backstage_Music_RTPC")
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Music_RTPC", 2)
  end
  if 0 == self.cacheSFXVolume then
    self.cacheSFXVolume = _G.NRCAudioManager:GetGlobalRTPC("Backstage_SFX_RTPC")
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_SFX_RTPC", 2)
  end
  if 0 == self.cachePetVolume then
    self.cachePetVolume = _G.NRCAudioManager:GetGlobalRTPC("Backstage_Pet_RTPC")
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Pet_RTPC", 2)
  end
end

function AICoachModule:OnRecoverGameAudio()
  if self.cacheMainVolume > 0 then
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Master_RTPC", self.cacheMainVolume)
    self.cacheMainVolume = 0
  end
  if self.cacheMusicVolume > 0 then
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Music_RTPC", self.cacheMusicVolume)
    self.cacheMusicVolume = 0
  end
  if self.cacheSFXVolume > 0 then
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_SFX_RTPC", self.cacheSFXVolume)
    self.cacheSFXVolume = 0
  end
  if self.cachePetVolume > 0 then
    _G.NRCAudioManager:SetGlobalRTPC("Backstage_Pet_RTPC", self.cachePetVolume)
    self.cachePetVolume = 0
  end
end

function AICoachModule:GetAICoachReplyText()
  return self.data:GetShowText()
end

function AICoachModule:OnOpenAICoachBySceneType(sceneType)
  if not self.isInWhiteList or self.currAICoachState == ProtoEnum.AiCoachStatus.ACS_CLOSED then
    return false
  end
  table.insert(self.sceneTypeList, 1, sceneType)
  local PlayUin = DataModelMgr.PlayerDataModel:GetPlayerUin()
  self.sessionId = string.format("session_%d_%d", PlayUin, os.time())
  self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
  return true
end

function AICoachModule:OnOpenAICoachBySceneTypeWithoutSession(sceneType)
  if not self.isInWhiteList or self.currAICoachState == ProtoEnum.AiCoachStatus.ACS_CLOSED then
    return false
  end
  table.insert(self.sceneTypeList, 1, sceneType)
  self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
  return true
end

function AICoachModule:OnCloseAICoachByScene(sceneType)
  if self.isAICoachActive then
    self:OnInterruptAICoachReq()
    self.isAICoachActive = false
  end
  for i, scene in ipairs(self.sceneTypeList) do
    if scene == sceneType then
      table.remove(self.sceneTypeList, i)
      break
    end
  end
  if 0 == #self.sceneTypeList then
    self:Clear()
  else
    self:OnStop()
  end
  self:OnRecoverGameAudio()
end

function AICoachModule:OnOpenRecodeVoice()
  if self.isAICoachActive then
    self:OnInterruptAICoachReq()
    self:OnStop()
    self.isAICoachActive = false
    self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
  end
end

function AICoachModule:OnRequestPlayerInWhiteList()
  if os.time() - self.requestTime < 60 then
    return
  end
  self.requestTime = os.time()
  local req = ProtoMessage:newZoneAiCoachWhiteListReq()
  req.request_id = string.format("request_%d", os.time())
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_WHITE_LIST_REQ, req)
end

function AICoachModule:OnRequestPlayerInWhiteListRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.isInWhiteList = rsp.is_whitelist
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachStateChange, self.isInWhiteList, self:GetIsCurrAICoachOpen())
  else
    self.requestTime = 0
  end
end

function AICoachModule:OnSetAICoachState(state)
  local req = ProtoMessage:newZoneAiCoachSetStatusReq()
  req.status = state
  req.request_id = string.format("request_%d", os.time())
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_SET_STATUS_REQ, req, self, self.OnSetAICoachStateRsp)
  if state == ProtoEnum.AiCoachStatus.ACS_QA then
    self:OnPointReportLog("coach_trigger_on_click")
  elseif state == ProtoEnum.AiCoachStatus.ACS_CLOSED then
    self:OnPointReportLog("coach_trigger_off_click")
  end
end

function AICoachModule:OnSetAICoachStateRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.currAICoachState = rsp.status
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachStateChange, self.isInWhiteList, self:GetIsCurrAICoachOpen())
  else
    Log.Error("AICoachModule:OnSetAICoachStateRsp failed, ret_code: " .. rsp.ret_info.ret_code .. "")
  end
end

function AICoachModule:OnSendAICoachQuestion(questionStr)
  if not self.isInWhiteList or self.currAICoachState == ProtoEnum.AiCoachStatus.ACS_CLOSED then
    return false
  end
  if not self.sceneTypeList or 0 == #self.sceneTypeList then
    return false
  end
  if self.isAICoachActive then
    self:OnStop()
  end
  self.data:OnClearShowText()
  self.data:OnClearShowNarrationText()
  self.isMsgPushed = false
  self.isAICoachActive = true
  self.requestId = string.format("request_%d", os.time())
  local req = ProtoMessage:newZoneAiCoachRecommendLineupReq()
  req.session_id = self.sessionId or "session_1111_1111"
  req.request_id = self.requestId
  req.query_text = questionStr
  req.scene_type = self.sceneTypeList[1]
  req.lineup_data = self.data:OnGetRecommendDiffJson() or ""
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_RECOMMEND_LINEUP_REQ, req, self, self.OnSendAICoachQuestionRsp)
  Log.Dump(req, 6, "AICoachModule:OnSendAICoachQuestion")
  self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Think)
end

function AICoachModule:OnReceiveAICoachAnswer(rsp)
  if self.requestId ~= rsp.request_id or self.sessionId ~= rsp.session_id then
    return
  end
  Log.Debug("AICoachModule:OnReceiveAICoachAnswer", rsp.session_id, rsp.request_id, rsp.data)
  local eventData = AICoachModuleUtils.ParseJSON(rsp.data)
  local result = {
    emotion = nil,
    textChunks = {},
    ttsChunks = {},
    lineup = nil,
    richText = nil,
    image = nil,
    done = nil,
    fullText = "",
    error = nil,
    narrationTextChunks = {},
    narrationTtsChunks = {}
  }
  AICoachModuleUtils.ProcessEventData(result, eventData.type, eventData)
  if not result then
    Log.Error("AICoachModule:OnReceiveAICoachAnswer failed, result is nil")
    return
  end
  local beginAnswer = false
  if result.emotion then
  end
  if result.narrationTextChunks and #result.narrationTextChunks > 0 then
    local fullText = ""
    table.sort(result.narrationTextChunks, function(a, b)
      return a.index < b.index
    end)
    for i, v in pairs(result.narrationTextChunks) do
      fullText = fullText .. v.content
    end
    self.data:OnUpdateShowText(fullText)
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachTextUpdate, self.data:GetShowText())
    beginAnswer = true
  end
  if result.textChunks and #result.textChunks > 0 then
    local fullText = ""
    table.sort(result.textChunks, function(a, b)
      return a.index < b.index
    end)
    for i, v in pairs(result.textChunks) do
      fullText = fullText .. v.content
    end
    self.data:OnUpdateShowText(fullText)
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachTextUpdate, self.data:GetShowText())
    beginAnswer = true
  end
  if result.ttsChunks and #result.ttsChunks > 0 then
    table.sort(result.ttsChunks, function(a, b)
      return a.index < b.index
    end)
    for i, v in pairs(result.ttsChunks) do
      self:OnSaveAICoachVoice(v.audioBase64)
    end
    self:OnPlayAICoachVoice()
    beginAnswer = true
  end
  if result.narrationTtsChunks and #result.narrationTtsChunks > 0 then
    table.sort(result.narrationTtsChunks, function(a, b)
      return a.index < b.index
    end)
    for i, v in pairs(result.narrationTtsChunks) do
      self:OnSaveAICoachVoice(v.audioBase64)
    end
    self:OnPlayAICoachVoice()
    beginAnswer = true
  end
  if result.lineup then
    local teamData = AICoachModuleUtils.ConvertLineupData(result.lineup)
    self.data:OnSetRecommendName(result.lineup.lineup_name)
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachTeamRecommend, teamData)
    beginAnswer = true
  end
  if result.richText then
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachRichTextUpdate, result.richText.content)
    beginAnswer = true
  end
  if beginAnswer then
    self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Answer)
  end
  if result.done then
    self.isMsgPushed = true
    self.isAudioStreamPlay = false
  end
  if result.error then
    Log.Error("AICoachModule:OnReceiveAICoachAnswer failed, error: " .. result.error .. "")
    self.isAICoachActive = false
    self.isMsgPushed = true
    self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
  end
end

function AICoachModule:OnSendAICoachQuestionRsp(rsp)
  self:SetAICoachTeamDiffJson("")
  if 0 == rsp.ret_info.ret_code then
  else
    Log.Error("AICoachModule:OnSendAICoachQuestionRsp failed, ret_code: " .. rsp.ret_info.ret_code .. "")
    self.isAICoachActive = false
    self.isMsgPushed = true
    self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
  end
end

function AICoachModule:OnUseAICoachTeamReq(useType, teamID)
end

function AICoachModule:OnUseAICoachTeamRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
  else
    Log.Error("AICoachModule:OnUseAICoachTeamRsp failed, ret_code: " .. rsp.ret_info.ret_code .. "")
  end
end

function AICoachModule:OnInterruptAICoachReq()
  local req = ProtoMessage:newZoneAiCoachRequestCancelReq()
  req.session_id = self.sessionId
  req.request_id = self.requestId
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_AI_COACH_REQUEST_CANCEL_REQ, req, self, self.OnInterruptAICoachRsp)
end

function AICoachModule:OnInterruptAICoachRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
  else
    Log.Error("AICoachModule:OnInterruptAICoachRsp failed, ret_code: " .. rsp.ret_info.ret_code .. "")
  end
end

function AICoachModule:OnPlayAICoachVoice()
  local voiceList = self.data:OnGetPlayVoiceItems()
  if 0 == voiceList:Size() and self.isMsgPushed then
    self.isAICoachActive = false
    self:OnUpdateAICoachEmotion(AICoachModuleUtils.EnumAICoachEmotion.Idle)
    _G.NRCEventCenter:DispatchEvent(AICoachModuleEvent.OnNotifyAICoachRequestFinish)
    self:OnRecoverGameAudio()
    return
  end
  if not self.isVoicePlaying and voiceList:Size() > 0 then
    self.isVoicePlaying = true
    self:OnCacheGameAudio()
    AICoachModuleUtils.PlayAICoachVoice(voiceList:First())
    voiceList:RemoveAt(1)
  end
end

function AICoachModule:OnSaveAICoachVoice(base64Code)
  local filename = "AICoachVoice_" .. tostring(os.msTime())
  local filepath = AICoachModuleUtils.SaveAICoachVoiceFile(base64Code, filename)
  self.data:OnAddPlayVoiceItem(filepath)
end

function AICoachModule:OnPlayAICoachVoiceByStream()
  if self.isAudioStreamPlay then
    return
  end
  self.isAudioStreamPlay = true
end

function AICoachModule:OnSaveAICoachVoiceByStream(base64Code)
  local decoData = UE4.TArray
  decoData = UE4.UNRCStatics.DecodeBase64(base64Code, decoData)
  self.data:OnAddAICoachVoiceStream(decoData)
end

function AICoachModule:GetAICoachReplyVoiceStream(length)
  local isEnd = 0
  local arrayVoice = UE4.TArray(UE4.uint8)
  self.data:OnGetAICoachVoiceStreamByLength(arrayVoice, length)
  isEnd = 0 == arrayVoice:Length() and self.isMsgPushed and 1 or 0
  return arrayVoice, isEnd
end

function AICoachModule:OnVoiceFinishCallBack(code, filePath)
  Log.Debug(string.format("AICoachModule:OnVoiceFinishCallBack, code: %d, filePath: %s", code, filePath or ""))
  self.isVoicePlaying = false
  UE.UNRCStatics.DeleteToFile(filePath)
  self:OnPlayAICoachVoice()
end

function AICoachModule:IsVoicePlaying()
  return self.isVoicePlaying
end

function AICoachModule:OnRecommendTeamReportLog(key, value)
  local logName = "AICoachRecommandTeamLog"
  if not value.pet_team_info then
    Log.Error("AICoachModule:OnRecommendTeamReportLog failed, value is nil")
    return
  end
  local teamPetStr = ""
  
  local function teamPetStrFun(teamInfo)
    local teamStr = string.format("%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d", teamInfo.base_conf_id or 0, teamInfo.nature or 0, teamInfo.attack_talent or 0, teamInfo.defense_talent or 0, teamInfo.hp_talent or 0, teamInfo.special_attack_talent or 0, teamInfo.special_defense_talent or 0, teamInfo.speed_talent or 0, teamInfo.blood_id or 0, teamInfo.skills and teamInfo.skills[1] and teamInfo.skills[1].id or 0, teamInfo.skills and teamInfo.skills[2] and teamInfo.skills[2].id or 0, teamInfo.skills and teamInfo.skills[3] and teamInfo.skills[3].id or 0, teamInfo.skills and teamInfo.skills[4] and teamInfo.skills[4].id or 0)
    return teamStr
  end
  
  if value.pet_team_info.pets then
    for i, v in pairs(value.pet_team_info.pets) do
      if "" == teamPetStr then
        teamPetStr = teamPetStrFun(v)
      else
        teamPetStr = teamPetStr .. "|" .. teamPetStrFun(v)
      end
    end
  end
  local valueStr = string.format("%s|%s|%d|%s|%d|%s", logName, value.team_name or "", value.team_id or 0, value.player_name or "", value.pet_team_info.role_magic_id or 0, teamPetStr)
end

function AICoachModule:OnTrailPetReportLog(key, value)
end

function AICoachModule:OnPointReportLog(key, teamId, pageName, missingData)
  local logName = "AICoachPointEventLog"
  local valueStr = ""
  local sceneType = self.sceneTypeList and self.sceneTypeList[1] or 0
  teamId = teamId and type(teamId) == "number" and teamId or 0
  local teamName = self.data:OnGetRecommendName()
  pageName = pageName and type(pageName) == "string" and pageName or ""
  missingData = missingData and type(missingData) == "string" and missingData or ""
  valueStr = string.format("%s|%s|%d|%d|%s|%s|%s", logName, key, sceneType, teamId, teamName, pageName, missingData)
  _G.GEMPostManager:SendNRCTLog(logName, valueStr)
end

function AICoachModule:DebugTestJsonStr(jsonStr)
  local result = AICoachModuleUtils.ParseSSEStream(jsonStr)
  Log.Dump(result, 6, "AICoachModule:DebugTestJsonStr")
end

return AICoachModule
