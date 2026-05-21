local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local SeasonIntegrationModule = NRCModuleBase:Extend("SeasonIntegrationModule")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")

function SeasonIntegrationModule:OnConstruct()
  _G.SeasonIntegrationModuleCmd = reload("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleCmd")
  self.data = self:SetData("SeasonIntegrationModuleData", "NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleData")
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnEnterSceneFinishNtyAckEnd)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SEASON_INFO_RSP, self.OnSeasonInfoRsp)
  self.seasonInfo = nil
  self:RegPanel("SeasonIntegrationPopUp", "UMG_SeasonIntegrationPopUp", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("SeasonalActivities", "UMG_SeasonalActivities", Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, false)
  self:RegPanel("S2_KnockMessageTips", "S2/UMG_KnockMessageTips", Enum.UILayerType.UI_LAYER_POPUP)
  self:SetPaneDisableLoadBlock("S2_KnockMessageTips", true)
end

function SeasonIntegrationModule:OnDestruct()
  if self.delayHandler then
    _G.DelayManager:CancelDelayById(self.delayHandler)
    self.delayHandler = nil
  end
  if self.boundCatchLimitTipsDelayHandle then
    _G.DelayManager:CancelDelayById(self.boundCatchLimitTipsDelayHandle)
    self.boundCatchLimitTipsDelayHandle = nil
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.OnLoadingUIOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingUIClose)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SEASON_INFO_RSP, self.OnSeasonInfoRsp)
end

function SeasonIntegrationModule:OpenSeasonIntegrationPanel()
  if self.seasonInfo then
    local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
    if seasonConf then
      local umgPath = string.format("/Game/NewRoco/Modules/System/SeasonIntegration/Res/%s", seasonConf.umg_part)
      local panelData = self:GetPanelData("SeasonIntegrationPanel")
      panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(umgPath)
      self:OpenPanel("SeasonIntegrationPanel")
    end
  end
end

function SeasonIntegrationModule:GetSeasonInfo()
  return self.seasonInfo
end

function SeasonIntegrationModule:OnActive()
end

function SeasonIntegrationModule:OnRelogin()
end

function SeasonIntegrationModule:OnDeactive()
end

function SeasonIntegrationModule:OnEnterSceneFinishNtyAckEnd(notify, isReconnecting, isEnteringCell)
  Log.Info("SeasonIntegrationModule:OnEnterSceneFinishNtyAckEnd isEnteringCell", isEnteringCell)
  if isEnteringCell then
    local reqMsg = _G.ProtoMessage:newZoneSeasonInfoReq()
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SEASON_INFO_REQ, reqMsg, self, self.OnSeasonInfoRsp, nil, false)
  end
end

function SeasonIntegrationModule:OnLoadMapStart()
  self:CloseAllPanel()
end

function SeasonIntegrationModule:OnSeasonInfoRsp(rsp)
  Log.Info("SeasonIntegrationModule:OnSeasonInfoRsp ret_code season_id", rsp.ret_info.ret_code, rsp.season_id)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    if rsp.season_id and 0 ~= rsp.season_id then
      if not self.bRegPanel then
        self:RegPanel("SeasonIntegrationPanel", "", Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, nil, nil, false)
        self:RegPanel("SeasonBeginsTips", "", Enum.UILayerType.UI_LAYER_POPUP):SetEnableTouchMask(false)
        self.bRegPanel = true
      end
      self.seasonInfo = rsp
      if self.seasonInfo then
        _G.NRCEventCenter:DispatchEvent(SeasonIntegrationModuleEvent.OnSeasonInfoChange)
        self:UpdateBonusCatchEffect(self.seasonInfo.season_id)
      end
    elseif self.seasonInfo then
      self.seasonInfo = nil
      _G.NRCEventCenter:DispatchEvent(SeasonIntegrationModuleEvent.OnSeasonInfoChange)
    end
  end
end

function SeasonIntegrationModule:ShowSeasonBeginsTips(tipObject)
  if not self.seasonInfo then
    Log.Warning("SeasonIntegrationModule:ShowSeasonBeginsTips season info is nil")
    return
  end
  local seasonConf = _G.DataConfigManager:GetSeasonConf(self.seasonInfo.season_id)
  if seasonConf and seasonConf.popup_path then
    local umgPath = string.format("/Game/NewRoco/Modules/System/SeasonIntegration/Res/%s", seasonConf.popup_path)
    local panelData = self:GetPanelData("SeasonBeginsTips")
    panelData.panelPath = NRCUtils.FormatBlueprintAssetPath(umgPath)
    local delaySec = _G.DataConfigManager:GetSeasonGlobalConfig(9).num / 1000
    self.delayHandler = _G.DelayManager:DelaySeconds(delaySec, function()
      self:OpenPanel("SeasonBeginsTips", tipObject)
      local req = _G.ProtoMessage:newZoneSetSeasonPopupReq()
      req.season_id = self.seasonInfo.season_id
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_SEASON_POPUP_REQ, req, self, self.OnSetSeasonPopupRsp, false, false)
    end)
  end
end

function SeasonIntegrationModule:SendZoneSetSeasonFirstPopReq(seasonPagePlayType)
  if not self.seasonInfo then
    Log.Error("SeasonIntegrationModule:SendZoneSetSeasonFirstPopReq seasonInfo is nil")
    return
  end
  Log.Info("SeasonIntegrationModule:SendZoneSetSeasonFirstPopReq", self.seasonInfo.season_id, seasonPagePlayType)
  local req = _G.ProtoMessage.newZoneSetSeasonFirstPopReq()
  req.season_id = self.seasonInfo.season_id
  req.pop_type = seasonPagePlayType
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_SEASON_FIRST_POP_REQ, req, self, self.OnZoneSetSeasonFirstPopRsp, false, false)
end

function SeasonIntegrationModule:OpenSeasonPopup(seasonId)
  if not self.seasonInfo then
    Log.Error("SeasonIntegrationModule:OpenSeasonPopup seasonInfo is nil")
    return
  end
  seasonId = seasonId or self.seasonInfo.season_id
  local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
  if not seasonConf then
    Log.Error("SeasonIntegrationModule:OpenSeasonPopup seasonConf is nil season_id = ", seasonId)
    return
  end
  self:OpenPanel("SeasonalActivities", seasonId)
end

function SeasonIntegrationModule:OpenSeasonIntegrationPopUp(tipsID, seasonId)
  self:OpenPanel("SeasonIntegrationPopUp", tipsID, seasonId)
end

function SeasonIntegrationModule:OnZoneSetSeasonFirstPopRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    Log.Info("SeasonIntegrationModule:OnZoneSetSeasonFirstPopRsp", rsp.season_id, rsp.pop_type, rsp.pop_time)
    if self.seasonInfo ~= nil and self.seasonInfo.season_id == rsp.season_id then
      if rsp.pop_type == ProtoEnum.SeasonPagePlayType.SPPT_PV then
        self.seasonInfo.season_pv_time = rsp.pop_time
      elseif rsp.pop_type == ProtoEnum.SeasonPagePlayType.SPPT_POP_WINDOWS then
        self.seasonInfo.season_pop_windows_time = rsp.pop_time
      end
      _G.NRCEventCenter:DispatchEvent(SeasonIntegrationModuleEvent.OnSeasonInfoChange)
    end
  else
    Log.Error("SeasonIntegrationModule:OnZoneSetSeasonFirstPopRsp", rsp.ret_info.ret_code)
  end
end

function SeasonIntegrationModule:OnSetSeasonPopupRsp(rsp)
  if rsp.ret_info and 0 == rsp.ret_info.ret_code and self.seasonInfo then
    self.seasonInfo.popup_time = 1
  end
end

function SeasonIntegrationModule:UpdateSeasonInfo(seasonInfo)
  self.seasonInfo = seasonInfo
end

function SeasonIntegrationModule:RegPanel(name, path, layer, customDisableRendering, touchCount, isSingleTouchPanel, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = string.format("/Game/NewRoco/Modules/System/SeasonIntegration/Res/%s", path)
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.touchCount = touchCount
  registerData.isSingleTouchPanel = isSingleTouchPanel
  registerData.enablePcEsc = enablePcEsc and enablePcEsc or false
  self:RegisterPanel(registerData)
  return registerData
end

function SeasonIntegrationModule:OnLoadingUIOpen()
  self.finishLoading = false
end

function SeasonIntegrationModule:OnLoadingUIClose()
  self.finishLoading = true
  if self.cachedBoundCatchLimitTipsAction then
    Log.Info("SeasonIntegrationModule:OnLoadingUIClose ProcessBonusCatchLimitTips")
    self:ProcessBonusCatchLimitTips(self.cachedBoundCatchLimitTipsAction)
    self.cachedBoundCatchLimitTipsAction = nil
  end
end

function SeasonIntegrationModule:IsMapLoading()
  return not self.finishLoading
end

function SeasonIntegrationModule:UpdateBonusCatchEffect(seasonId)
  self:ClearBonusCatchEffect()
  if not seasonId then
    return
  end
  local seasonCatchConfs = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.SEASON_BONUSCATCH_EFFECTS_CONF)
  if not seasonCatchConfs then
    Log.Debug("SeasonIntegrationModule:UpdateBonusCatchEffect Can't find SEASON_BONUSCATCH_EFFECTS_CONF")
    return
  end
  local effectPath
  for _, Conf in pairs(seasonCatchConfs) do
    if Conf and Conf.season == seasonId then
      effectPath = Conf.catch_skill
      if Conf.sound_id and 0 ~= Conf.sound_id then
        self.BonusCatchSoundId = Conf.sound_id
        Log.Debug("SeasonIntegrationModule:UpdateBonusCatchEffect sound id", self.BonusCatchSoundId)
      end
      break
    end
  end
  if not effectPath then
    Log.Debug("SeasonIntegrationModule:UpdateBonusCatchEffect Can't find effect path")
    return
  end
  Log.Debug("SeasonIntegrationModule:UpdateBonusCatchEffect effect path", effectPath)
  local _, idx = effectPath:find(".*/")
  local package = effectPath:sub(1, idx)
  local asset = effectPath:sub(idx + 1, effectPath:len())
  local loadPath = package .. asset .. "." .. asset
  self.bonusCatchParticleLoadRequest = _G.NRCResourceManager:LoadResAsync(self, loadPath, _G.PriorityEnum.Active_Player_CatchRelated, 120, self.OnBonusCatchEffectLoadSuccess, self.OnBonusCatchEffectLoadFailed)
end

function SeasonIntegrationModule:ClearBonusCatchEffect()
  if self.bonusCatchParticleLoadRequest then
    _G.NRCResourceManager:UnLoadRes(self.bonusCatchParticleLoadRequest)
    self.bonusCatchParticleLoadRequest = nil
  end
  if UE.UObject.IsValid(self.BonusCatchParticleClassRef) then
    UnLua.Unref(self.BonusCatchParticleClassRef)
  end
  self.BonusCatchParticleClass = nil
  self.BonusCatchParticleClassRef = nil
  self.BonusCatchSoundId = nil
end

function SeasonIntegrationModule:OnBonusCatchEffectLoadSuccess(request, res)
  Log.Debug("SeasonIntegrationModule:OnBonusCatchEffectLoadSuccess", request.assetPath)
  self.bonusCatchParticleLoadRequest = nil
  self.BonusCatchParticleClass = res
  self.BonusCatchParticleClassRef = res and UnLua.Ref(res)
end

function SeasonIntegrationModule:OnBonusCatchEffectLoadFailed(request, message)
  Log.Debug("SeasonIntegrationModule:OnBonusCatchEffectLoadFailed", message)
  _G.NRCResourceManager:UnLoadRes(request)
  self:ClearBonusCatchEffect()
end

function SeasonIntegrationModule:PlayBonusCatchEffect()
  if not self.BonusCatchParticleClass then
    Log.Debug("SeasonIntegrationModule:PlayOnCatchSuccess Can't find CatchSuccessSkill")
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:PlayerBonusCatchParticle(player, self.BonusCatchParticleClass)
  self:PlayerBonusCatchSound(player, self.BonusCatchSoundId)
end

function SeasonIntegrationModule:PlayerBonusCatchParticle(player, effectClass)
  if not player or not effectClass then
    Log.Debug("SeasonIntegrationModule:PlayerBonusCatchParticle Can't find player or skillClass")
    return
  end
  local playerViewObj = player.viewObj
  if not playerViewObj or not UE4.UObject.IsValid(playerViewObj) then
    Log.Debug("SeasonIntegrationModule:PlayerBonusCatchParticle Can't find playerViewObj")
    return
  end
  local fxComponent = playerViewObj:GetComponentByClass(UE4.URocoFXComponent)
  fxComponent = fxComponent or playerViewObj:AddComponentByClass(UE4.URocoFXComponent, false, UE4.FTransform(), false)
  if not fxComponent then
    Log.Debug("SeasonIntegrationModule:PlayerBonusCatchParticle Can't find RocoFXComponent")
    return
  end
  if self.playEffectId then
    fxComponent:StopFx(self.playEffectId)
  end
  self.playEffectId = fxComponent:PlayFx_Location(effectClass, playerViewObj:GetTransform(), true)
end

function SeasonIntegrationModule:PlayerBonusCatchSound(player, soundId)
  if not player or not soundId then
    Log.Debug("SeasonIntegrationModule:PlayerBonusCatchSound Can't find player or soundId")
    return
  end
  local playerViewObj = player.viewObj
  if not playerViewObj or not UE4.UObject.IsValid(playerViewObj) then
    Log.Debug("SeasonIntegrationModule:PlayerBonusCatchSound Can't find playerViewObj")
    return
  end
  if self.playSoundId then
    _G.NRCAudioManager:ReleaseSession(self.playSoundId)
  end
  self.playSoundId = _G.NRCAudioManager:PlaySound3DWithActor(soundId, playerViewObj, "SeasonIntegrationModule:PlayerBonusCatchSound")
end

function SeasonIntegrationModule:OnBonusCatchLimitTips(action)
  if self:IsMapLoading() then
    Log.Debug("SeasonIntegrationModule:OnBonusCatchLimitTips map loading, cache action")
    self.cachedBoundCatchLimitTipsAction = action
    return
  end
  self:ProcessBonusCatchLimitTips(action)
end

function SeasonIntegrationModule:ProcessBonusCatchLimitTips(action)
  if self.bTipsInCooldown then
    Log.Debug("SeasonIntegrationModule:OnBonusCatchLimitTips in cooldown, skip")
    return
  end
  if not action then
    Log.Debug("SeasonIntegrationModule:OnBonusCatchLimitTips action is nil")
    return
  end
  local tipsId = action.tips_id
  if not tipsId then
    Log.Debug("SeasonIntegrationModule:OnBonusCatchLimitTips tipsId is nil")
    return
  end
  local conf = _G.DataConfigManager:GetSeasonBonuscatchLimitConf(tipsId, true)
  if not conf then
    Log.Debug("SeasonIntegrationModule:OnBonusCatchLimitTips conf not found for tips_id:", tipsId)
    return
  end
  local cd = conf.tips_gap or 0
  local tipsText = conf.tips_text
  if conf.bonus_limit_number and action.current_count >= conf.bonus_limit_number * 0.9 then
    tipsText = conf.limit_tips_text
  end
  Log.Info("SeasonIntegrationModule:OnBonusCatchLimitTips", tipsId, cd, tipsText, action.current_count, conf.bonus_limit_number, conf.trig_tips_number)
  if cd > 0 then
    self.bTipsInCooldown = true
    self.boundCatchLimitTipsDelayHandle = _G.DelayManager:DelaySeconds(cd, function()
      if not self then
        return
      end
      self.boundCatchLimitTipsDelayHandle = nil
      self.bTipsInCooldown = nil
    end)
  end
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipsText, nil, nil, 1.2)
end

local S2_BoxKnockAnimName = "Idle2"
local S2_BoxAnimBlendTime = 0.1

function SeasonIntegrationModule:SetPaneDisableLoadBlock(panelName, bDisableLoadBlock)
  local panelData = self:GetPanelData(panelName)
  if panelData then
    panelData.disableLoadBlock = bDisableLoadBlock
  end
end

function SeasonIntegrationModule:S2_GetCurrentKnockBoxInfo()
  return self.S2_CurrentKnockBoxInfo
end

function SeasonIntegrationModule:S2_OpenKnockBoxMessage(npc, dialogueId)
  if self.S2_CurrentKnockBoxInfo then
    self:EndKnock(self.S2_CurrentKnockBoxInfo.Npc)
  end
  self.S2_CurrentKnockBoxInfo = {Npc = npc, DialogueId = dialogueId}
  self:BeginKnock(npc)
  if self:HasPanel("S2_KnockMessageTips") then
    local panel = self:GetPanel("S2_KnockMessageTips")
    if panel then
      panel:UpdateTipsInfo(self.S2_CurrentKnockBoxInfo)
    end
    return
  end
  if not self:IsPanelInOpening("S2_KnockMessageTips") then
    self:OpenPanel("S2_KnockMessageTips")
  end
end

function SeasonIntegrationModule:BeginKnock(npc)
  if not npc then
    return
  end
  npc:PlayAnim(S2_BoxKnockAnimName, 1, 0, S2_BoxAnimBlendTime, S2_BoxAnimBlendTime, -1)
  Log.Debug("SeasonIntegrationModule:BeginKnock", npc:DebugNPCNameAndID())
end

function SeasonIntegrationModule:S2_CloseKnockBoxMessage(npc, dialogueId)
  if not self.S2_CurrentKnockBoxInfo then
    return
  end
  if self.S2_CurrentKnockBoxInfo.Npc ~= npc then
    return
  end
  self:EndKnock(npc)
  if self:HasPanel("S2_KnockMessageTips") then
    local panel = self:GetPanel("S2_KnockMessageTips")
    if panel then
      panel:EndKnock()
    end
  end
  self.S2_CurrentKnockBoxInfo = nil
end

function SeasonIntegrationModule:EndKnock(npc)
  if not npc then
    return
  end
  npc:StopAnim(S2_BoxKnockAnimName, S2_BoxAnimBlendTime)
  Log.Debug("SeasonIntegrationModule:EndKnock", npc:DebugNPCNameAndID())
end

return SeasonIntegrationModule
