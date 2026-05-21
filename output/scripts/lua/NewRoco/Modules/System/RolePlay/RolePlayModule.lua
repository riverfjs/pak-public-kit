local RolePlayModule = NRCModuleBase:Extend("RolePlayModule")
local RolePlayModuleEvent = require("NewRoco.Modules.System.RolePlay.RolePlayModuleEvent")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local TipsDisplayController = require("NewRoco.Modules.System.TipsModule.TipsDisplayController")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local RolePlayComponent = require("NewRoco.Modules.Core.Scene.Component.RolePlay.RolePlayComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")

function RolePlayModule:OnConstruct()
  _G.RolePlayModuleCmd = reload("NewRoco.Modules.System.RolePlay.RolePlayModuleCmd")
  self.joystickTouchStartTime = 0
  self.data = self:SetData("RolePlayModuleData", "NewRoco.Modules.System.RolePlay.RolePlayModuleData")
  self.rolePlayTipsController = TipsDisplayController(TipEnum.TipObjectType.RolePlayGetTips, self, self.OpenRolePlayGetTipsPanel)
  self.timeInterval = 0
  self:RegPanel("RolePlayMainPanel", "/Game/NewRoco/Modules/System/RolePlay/Res/UMG_RolePlayMainPanel", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "Open", "Close", true)
  self:RegPanel("RolePlay_GetTips", "/Game/NewRoco/Modules/System/RolePlay/Res/UMG_RolePlay_GetTips", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "Appear", "Disappear", true, true):SetEnableTouchMask(false)
end

function RolePlayModule:OnActive()
  _G.NRCEventCenter:RegisterEvent("RolePlayModule", self, BagModuleEvent.GoodChangeTypeEnum.GT_RP_BEHAVIOR, self.OnGetNewRPBehavior)
  _G.NRCEventCenter:RegisterEvent("TipsDisplayCoordinator", self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.CloseMainPanel)
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NEW_FASHION_SUIT_NOTIFY, self.OnGetNewSuit)
  local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  end
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnRolePlayBanStateChangeHandler)
  _G.NRCEventCenter:RegisterEvent("RolePlayModule", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:RegisterEvent("RolePlayModule", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  _G.NRCEventCenter:RegisterEvent("RolePlayModule", self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroy)
end

function RolePlayModule:OnRelogin()
end

function RolePlayModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_RP_BEHAVIOR, self.OnGetNewRPBehavior)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_OPENED, self.CloseMainPanel)
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_SCENE_NEW_FASHION_SUIT_NOTIFY, self.OnGetNewSuit)
  local playerModule = _G.NRCModuleManager:GetModule("PlayerModule")
  if playerModule then
    playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_TOUCH_START, self.OnInputTouchStart)
  end
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, self, self.OnRolePlayBanStateChangeHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReConnect)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.AfterEnterScene)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_Destroy, self.OnNpcDestroy)
end

function RolePlayModule:OnDestruct()
end

function RolePlayModule:OnReConnect()
  self:SetInPutPropNpcId(0)
  self:SetInRecycleNpcId(0)
  self:InitCurPutPropNpcId()
end

function RolePlayModule:AfterEnterScene()
  self:InitCurPutPropNpcId()
end

function RolePlayModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, disablePcEsc, disableLoadBlock)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = not disablePcEsc
  registerData.disableLoadBlock = disableLoadBlock
  self:RegisterPanel(registerData)
  return registerData
end

local function CheckRolePlayStoryFlag()
  return _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_FASHION_BIGWORLD)
end

function RolePlayModule:CheckCanOpenMainPanel()
  if not CheckRolePlayStoryFlag() then
    return false
  end
  if self:IsMainPanelOpen() then
    return false
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return false
  end
  if localPlayer.statusComponent and localPlayer.statusComponent:HasAnyStatusExclude(_G.ProtoEnum.WorldPlayerStatusType.WPST_TAKE_PHOTO_TRIPOD, _G.ProtoEnum.WorldPlayerStatusType.WPST_LANDED, _G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND, _G.ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P) then
    return false
  end
  if _G.NRCModuleManager:DoCmd(_G.TakePhotosModuleCmd.IfInTakePhotoTripodMode) then
    return false
  end
  local controller = localPlayer:GetUEController()
  if UE4.UObject.IsValid(controller) and UE4.UObject.IsValid(localPlayer.viewObj) then
    local cameraManager = controller.playerCameraManager
    if UE4.UObject.IsValid(cameraManager) then
      local fadeInfo = cameraManager:GetCurActorFadeInfo(localPlayer.viewObj)
      if 0 == fadeInfo or -1 == fadeInfo then
        return false
      end
    end
  end
  return true
end

function RolePlayModule:OpenMainPanel(_rolePlayType)
  if self:HasPanel("RolePlayMainPanel") then
    return
  end
  self:OpenPanel("RolePlayMainPanel", _rolePlayType)
end

function RolePlayModule:IsMainPanelOpen()
  return self:HasPanel("RolePlayMainPanel")
end

function RolePlayModule:CloseMainPanel()
  if self:HasPanel("RolePlayMainPanel") then
    self:ClosePanel("RolePlayMainPanel")
  end
end

function RolePlayModule:OpenRolePlayGetTipsPanel()
  if self:HasPanel("RolePlay_GetTips") or self:IsPanelInOpening("RolePlay_GetTips") then
    return
  end
  self:OpenPanel("RolePlay_GetTips")
end

function RolePlayModule:GetRolePlayData(_rolePlayType, _customData)
  return self.data:GetRolePlayData(_rolePlayType, _customData)
end

function RolePlayModule:ExecuteRolePlay(params)
  if not params then
    return
  end
  local stopMove = false
  local type = params.statusParams and params.statusParams.role_play_param and params.statusParams.role_play_param.skill_type
  local behavior_with_pet = false
  local RPbehavior_type
  if params.id then
    local conf = _G.DataConfigManager:GetRoleplayBehaviorConf(params.id or 0, true)
    RPbehavior_type = conf and conf.RPbehavior_type
    if conf and not conf.is_movable then
      stopMove = true
    end
  elseif params.skill_interact_id and type == ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE then
    local conf = _G.DataConfigManager:GetSkillInteractConf(params.skill_interact_id or 0, true)
    RPbehavior_type = conf and conf.RPbehavior_type
    behavior_with_pet = true
  end
  if not RPbehavior_type then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.statusComponent then
    local scenePet
    local petActorId = params.pet_actor_id
    if petActorId then
      scenePet = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, petActorId)
    end
    local petBaseId = params.statusParams and params.statusParams.role_play_param and params.statusParams.role_play_param.pet_id
    if not scenePet and petBaseId then
      local throwManagementCpt = player.ThrowManagementComponent
      if throwManagementCpt and throwManagementCpt.ThrownSessions then
        for _, v in pairs(throwManagementCpt.ThrownSessions) do
          if v and v.NPC and v.NPC:GetPetbaseId() == petBaseId then
            scenePet = v.NPC
            break
          end
        end
      end
    end
    if scenePet then
      local isPetRelax = scenePet.AIComponent and scenePet.AIComponent:HasBattleState(Enum.BattleAIStatus.BAS_SING) or true
      if not isPetRelax and not _G.GlobalConfig.ForceSuitRelax then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, _G.LuaText.rolepaly_fashion_conflict)
        return
      end
      local petServerId = scenePet:GetServerId()
      if petServerId and 0 ~= petServerId then
        params.statusParams.role_play_param.pet_serverid = petServerId
      end
    end
    if behavior_with_pet then
      player.statusComponent:ClearStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
    end
    if stopMove then
      player:Stop()
      self.joystickTouchStartTime = _G.ZoneServer:GetServerTime()
    end
    local rideComponent = player:GetRideComponent()
    if rideComponent then
      rideComponent:TryChangeToLink()
    end
    player.statusComponent:ApplyStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, RPbehavior_type, params.statusParams)
  end
end

function RolePlayModule:AbortRolePlay(behaviorType)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.statusComponent then
    local canAbort = true
    if behaviorType then
      local RolePlayCpt = player:GetComponent(RolePlayComponent)
      if RolePlayCpt then
        local playingRpId = RolePlayCpt:GetPlayingRpBehaviorId()
        local RpConf = playingRpId and _G.DataConfigManager:GetRoleplayBehaviorConf(playingRpId)
        if RpConf and RpConf.behavior_type ~= behaviorType then
          canAbort = false
        end
      end
    end
    if canAbort then
      player.statusComponent:ClearStatus(Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR)
    end
  end
end

function RolePlayModule:GetConfByBehaviorType(behaviorType)
  return self.data:GetRolePlayConfByBehaviorType(behaviorType)
end

function RolePlayModule:PreventJoystickFalseInterrupt()
  local inProtecting = false
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local RolePlayCpt = player:GetComponent(RolePlayComponent)
    if RolePlayCpt then
      local isPlayingRpBehavior, interruptType = RolePlayCpt:CheckMoveCanInterruptRpBehavior()
      if isPlayingRpBehavior then
        if interruptType == RolePlayModuleDef.InterruptType.CanInterrupt then
          inProtecting = false
          local timeDelta = _G.ZoneServer:GetServerTime() - self.joystickTouchStartTime
          if timeDelta < self.data.joystickProtectTime then
            inProtecting = true
          end
          if not inProtecting then
            self:AbortRolePlay()
          end
        elseif interruptType == RolePlayModuleDef.InterruptType.CanNotInterrupt then
          inProtecting = true
        elseif interruptType == RolePlayModuleDef.InterruptType.CanParallel then
          inProtecting = false
        end
      end
    end
  end
  return inProtecting
end

function RolePlayModule:ShowGetNewRolePlayTips(id)
  local conf = _G.DataConfigManager:GetRoleplayBehaviorConf(id or 0)
  if conf then
    local uiData = {}
    uiData.content = conf.toast_text
    uiData.iconPath = conf.icon_path
    local roleConfigTableId = _G.DataConfigManager.ConfigTableId.ROLE_GLOBAL_CONFIG
    local configTime = _G.DataConfigManager:GetGlobalConfigByKeyType("roleplay_reward_toast_time", roleConfigTableId).num / 1000
    uiData.countdown = 0 == configTime % 1 and math.floor(configTime) or configTime
    if conf.behavior_type == Enum.BehaviorType.BT_CALL then
      uiData.rolePlayType = RolePlayModuleDef.RolePlayType.Sound
      uiData.title = _G.LuaText.roleplay_reward_text2
      uiData.countdownStr = _G.DataConfigManager:GetGlobalConfigByKeyType("roleplay_reward_toast_text2", roleConfigTableId).str
    elseif conf.behavior_type == Enum.BehaviorType.BT_PROP then
      uiData.rolePlayType = RolePlayModuleDef.RolePlayType.PutProp
      uiData.title = _G.LuaText.roleplay_reward_text3
      uiData.countdownStr = _G.DataConfigManager:GetGlobalConfigByKeyType("roleplay_reward_toast_text3", roleConfigTableId).str
    else
      uiData.rolePlayType = RolePlayModuleDef.RolePlayType.Action
      uiData.title = _G.LuaText.roleplay_reward_text1
      uiData.countdownStr = _G.DataConfigManager:GetGlobalConfigByKeyType("roleplay_reward_toast_text1", roleConfigTableId).str
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.AddTip, TipObject.CreateRolePlayTips(uiData))
  end
end

function RolePlayModule:OnInputTouchStart(Input)
  self.joystickTouchStartTime = _G.ZoneServer:GetServerTime()
end

function RolePlayModule:OnGetNewRPBehavior(goodsChangeItem, cmdID)
  if not goodsChangeItem then
    return
  end
  local conf = self.data:GetRolePlayConfByBehaviorType(goodsChangeItem.id or 0)
  if conf then
    self.data:AddNewGetBehaviors(conf.id)
    self:DispatchEvent(RolePlayModuleEvent.GetNewRolePlay, conf)
  end
end

function RolePlayModule:OnRolePlayBanStateChangeHandler(isBan, functionType)
  if isBan then
    self:AbortRolePlay()
  end
end

function RolePlayModule:OnGetNewSuit(notify)
  local newFashionID = notify.fashion_suit_id
  local conf = _G.DataConfigManager:GetFashionSuitsConf(newFashionID)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if tonumber(conf.gender) ~= player.gender then
    return
  end
  if self.data:CheckAndRemoveHiddenSuitTipsId(newFashionID) then
    return
  end
  local uiData = {}
  local title = _G.DataConfigManager:GetLocalizationConf("fashion_suits_collect").msg
  uiData.rolePlayType = RolePlayModuleDef.RolePlayType.Suit
  uiData.title = title
  uiData.content = conf.name
  uiData.iconPath = conf.suits_icon
  local roleConfigTableId = _G.DataConfigManager.ConfigTableId.ROLE_GLOBAL_CONFIG
  uiData.countdownStr = _G.DataConfigManager:GetGlobalConfigByKeyType("fashion_suits_reward_toast", roleConfigTableId).str
  local configTime = _G.DataConfigManager:GetGlobalConfigByKeyType("fashion_suits_reward_toast_time", roleConfigTableId).num / 1000
  uiData.countdown = 0 == configTime % 1 and math.floor(configTime) or configTime
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.AddTip, TipObject.CreateRolePlayTips(uiData, string.format("IA_QuickDressUP")))
end

function RolePlayModule:OnPutPropResponse(result)
  if result then
    self:SetCurPutPropNpcId(self.data.inPutPropNpcId)
  else
    self.data.nextPutPropTime = _G.ZoneServer:GetServerTime() / 1000 + 1.5
  end
  self:SetInPutPropNpcId(0)
  local panel = self:GetPanel("RolePlayMainPanel")
  if panel then
    local rolePlayDataList = self:GetRolePlayData(RolePlayModuleDef.RolePlayType.PutProp)
    panel:RefreshTabData(rolePlayDataList)
  end
end

function RolePlayModule:OnRecyclePropResponse(result)
  if result then
    self:SetCurPutPropNpcId(0)
  end
  self.data.nextPutPropTime = _G.ZoneServer:GetServerTime() / 1000 + 1.5
  self:SetInRecycleNpcId(0)
  local panel = self:GetPanel("RolePlayMainPanel")
  if panel then
    local rolePlayDataList = self:GetRolePlayData(RolePlayModuleDef.RolePlayType.PutProp)
    panel:RefreshTabData(rolePlayDataList)
  end
end

function RolePlayModule:RefreshNextPutPropTime(curTime)
  curTime = curTime or _G.ZoneServer:GetServerTime() / 1000
  local cdConf = _G.DataConfigManager:GetGlobalConfig("put_prop_cd")
  if cdConf then
    self.data.nextPutPropTime = curTime + cdConf.num
  else
    self.data.nextPutPropTime = curTime + 10
  end
end

function RolePlayModule:GetNextPutPropTime()
  return self.data.nextPutPropTime
end

function RolePlayModule:SetInPutPropNpcId(_inPutPropNpcId)
  self.data.inPutPropNpcId = _inPutPropNpcId
end

function RolePlayModule:SetInRecycleNpcId(_inRecycleNpcId)
  self.data.inRecycleNpcId = _inRecycleNpcId
end

function RolePlayModule:GetCurPutPropNpcId()
  return self.data.curPutPropNpcId
end

function RolePlayModule:SetCurPutPropNpcId(npcId)
  self.data.curPutPropNpcId = npcId
end

function RolePlayModule:InitCurPutPropNpcId()
  self:SetCurPutPropNpcId(0)
  for i, conf in pairs(self.data.propItemConfMap) do
    local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.FindNPCByConfigId, conf.id)
    if npc then
      local playerID = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
      if npc.serverData.npc_base.create_avatar_id == playerID then
        self:SetCurPutPropNpcId(conf.id)
        break
      end
    end
  end
end

function RolePlayModule:OnTick(deltaTime)
  self.timeInterval = self.timeInterval + deltaTime
  if self.timeInterval <= 5 then
    return
  end
  self.timeInterval = 0
  local npcId = self:GetCurPutPropNpcId()
  if npcId > 0 then
    local playerID = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.OnFindNPCByConfigIDAndUin, npcId, playerID)
    if npc then
      local limitDis = self.data.propItemConfMap[npcId] and self.data.propItemConfMap[npcId].prop_recycle_distance * 100 * (self.data.propItemConfMap[npcId].prop_recycle_distance * 100) or 100000000
      if limitDis < npc.squaredDis2Local then
        self:SetInRecycleNpcId(npcId)
        local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
        if Player and Player.playerToyComponent then
          Player.playerToyComponent:RecycleRolePlayProp(npcId, playerID)
        end
      end
    end
  end
end

function RolePlayModule:OnNpcDestroy(npc)
  if npc and npc.serverData and npc.serverData.npc_base.npc_cfg_id == self:GetCurPutPropNpcId() then
    local playerID = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    if npc.serverData.npc_base.create_avatar_id == playerID then
      self:SetCurPutPropNpcId(0)
      if self:HasPanel("RolePlayMainPanel") then
        local panel = self:GetPanel("RolePlayMainPanel")
        if panel then
          local rolePlayDataList = self:GetRolePlayData(RolePlayModuleDef.RolePlayType.PutProp)
          panel:RefreshTabData(rolePlayDataList)
        end
      end
    end
  end
end

function RolePlayModule:ShowPlaceFrequentlyTips()
  local curTime = _G.ZoneServer:GetServerTime() / 1000
  if curTime > self.data.nextFrequentlyTipsTime then
    self.data.nextFrequentlyTipsTime = curTime + 1
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_cd_warn)
  end
end

function RolePlayModule:ReqUseRpTypeInGroup(Type)
  Log.Debug("RolePlay ReqUseRpTypeInGroup", Type)
  local Conf = self.data:GetRolePlayConfByBehaviorType(Type)
  if not Conf then
    return
  end
  local Group = self.data:GetGroupByRoleplayConf(Conf)
  if not Group then
    return
  end
  local Req = _G.ProtoMessage:newZoneSetUsingRpBehaviorReq()
  local Cmd = _G.ProtoCMD.ZoneSvrCmd.ZONE_SET_USING_RP_BEHAVIOR_REQ
  local rspWrapper = {}
  rspWrapper.reqMsg = Req
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    if _protoData and _protoData.ret_info and 0 == _protoData.ret_info.ret_code then
      self:OnRspUseRpTypeInGroup(Type, _protoData.player_rp_behavior_using_list)
    else
      self:LogError("ZoneSetUsingRpBehaviorReq Failed", _protoData and _protoData.ret_info and _protoData.ret_info.ret_code, "Type", Type)
    end
  end
  
  local RolePlayTypeList = _G.DataModelMgr.PlayerDataModel:GetUsingRolePlayList()
  local RequestPolePlayTypeList
  if not next(RolePlayTypeList) then
    RequestPolePlayTypeList = {Type}
  else
    RequestPolePlayTypeList = table.copy(RolePlayTypeList, {})
    if not table.contains(RequestPolePlayTypeList, Type) then
      local GroupId = self.data:GetGroupInfoByType(Type)
      for i, TestType in pairs(RequestPolePlayTypeList) do
        local TestGroupId = self.data:GetGroupInfoByType(TestType)
        if TestGroupId == GroupId then
          table.remove(RequestPolePlayTypeList, i)
        end
      end
      table.insert(RequestPolePlayTypeList, Type)
    end
  end
  Log.Debug("RolePlay ReqUseRpTypeInGroup", Type, table.concat(RequestPolePlayTypeList, ";"))
  Req.player_rp_behavior_using_list = RequestPolePlayTypeList
  _G.ZoneServer:SendWithHandler(Cmd, Req, rspWrapper, OnSvrRspHandle)
end

function RolePlayModule:OnRspUseRpTypeInGroup(Type, ServerUpdatedList)
  Log.Debug("RolePlay OnRspUseRpTypeInGroup", Type, table.concat(ServerUpdatedList, ";"))
  _G.DataModelMgr.PlayerDataModel:SetUsingRolePlayList(ServerUpdatedList)
  self:DispatchEvent(RolePlayModuleEvent.OnRefreshRoleplayGroupSelection, Type)
end

function RolePlayModule:GetDisplayRolePlayMap()
  return self.data:GetDisplayRolePlayMap()
end

function RolePlayModule:GetGroupByRoleplayConf(RoleplayConf)
  return self.data:GetGroupByRoleplayConf(RoleplayConf)
end

function RolePlayModule:CreateLockedRoleplayAction(RoleplayConf)
  return self.data:CreateLockedRoleplayAction(RoleplayConf)
end

function RolePlayModule:AddHiddenSuitTipsId(suitId)
  self.data:AddHiddenSuitTipsId(suitId)
end

function RolePlayModule:RemoveHiddenSuitTipsId(suitId)
  self.data:RemoveHiddenSuitTipsId(suitId)
end

function RolePlayModule:OnRolePlayHoldInfoChange(Action, Tag, BaseData)
  Log.Debug("RolePlayModule:OnRolePlayHoldInfoChange", Action, Tag, BaseData)
  if not Action then
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, BaseData.operator_obj_id)
  if not Player then
    return
  end
  local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.npc_id)
  if not NPC then
    return
  end
  if -1 == Action.slot_idx then
    if Action.reason then
      if Action.reason == ProtoEnum.RoleplayHoldInfoChangeReason.RHICR_ClENT_REQ_CANCEL_HOLD then
      elseif Action.reason == ProtoEnum.RoleplayHoldInfoChangeReason.RHICR_OTHER_OPEN_BLIND_BOX then
        local OutPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Action.op_avatar_uin)
        if OutPlayer and not OutPlayer.isLocal and Player.playerToyComponent then
          Player.playerToyComponent:PlayJumpBoxAnim(OutPlayer, NPC)
        end
      else
        if Player.playerToyComponent then
          Player.playerToyComponent:RevertPLayer()
        end
        if Player.isLocal then
          _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
        end
      end
    else
      if Player.playerToyComponent then
        Player.playerToyComponent:RevertPLayer()
      end
      if Player.isLocal then
        _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
      end
    end
    if Player.playerToyComponent then
      Player.playerToyComponent:OnPlayerLeaveBox()
      local PropPlayerInfo = {}
      PropPlayerInfo.slot_idx = 0
      PropPlayerInfo.entered_npc_id = 0
      local PropNPCInfo = {}
      PropNPCInfo.slot_idx = 0
      PropNPCInfo.holder_avatar_id = 0
      Player.playerToyComponent:SavePropNpcServerData(Player, NPC, {PropNPCInfo}, PropPlayerInfo)
    end
  elseif Player.playerToyComponent then
    Player.playerToyComponent:OnPlayerEnterBox()
    local PropPlayerInfo = {}
    PropPlayerInfo.slot_idx = 0
    PropPlayerInfo.entered_npc_id = NPC.serverData.base.actor_id
    local PropNPCInfo = {}
    PropNPCInfo.slot_idx = 0
    PropNPCInfo.holder_avatar_id = Player.serverData.base.actor_id
    Player.playerToyComponent:SavePropNpcServerData(Player, NPC, {PropNPCInfo}, PropPlayerInfo)
  end
end

return RolePlayModule
