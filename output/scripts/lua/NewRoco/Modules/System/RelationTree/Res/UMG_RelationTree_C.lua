local RelationTreeEvent = require("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local UMG_RelationTree_C = _G.NRCPanelBase:Extend("UMG_RelationTree_C")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local JsonUtils = require("Common.JsonUtils")
local CoinType = _G.Enum.VisualItem.VI_DIAMOND
local FloorItemSizeY_1 = 389
local FloorItemSizeY_2 = 223
local FloorItemSizeY_3 = 175

function UMG_RelationTree_C:OnConstruct()
  self.Offset = 0
  self.isShowMoreUI = false
  self.module = _G.NRCModuleManager:GetModule("RelationTreeModule")
  self:BindInputAction()
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.OnZoneQueryGiftingEggTimesReq)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CameraSetIsCanClick)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_PANEL_OPEN)
end

function UMG_RelationTree_C:OnActive()
  _G.NRCAudioManager:PlaySound2DAuto(1013, "UMG_RelationTree_C:OnActive")
  UE4Helper.SetDesiredShowCursor(true, "UMG_RelationTree_C")
  self.PlayerUid = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetCurPlayerUID)
  self:UpdatePlayerInfoUI()
  self:RelationTreeShowPlayAnim()
  self:OnAddEventListener()
  self:ActiveUpdateUI(true)
  self:UpdateCoinUI()
end

function UMG_RelationTree_C:RelationTreeShowPlayAnim()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local targetPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, self.PlayerUid)
  if targetPlayer then
    player:OnRelationTreeTargetChanged(targetPlayer.viewObj)
  end
  player:SendEvent(PlayerModuleEvent.ON_INTERRUPT_THROW)
  player:SendEvent(PlayerModuleEvent.ON_INTERRUPT_AIM)
  local MyRequest = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMyRequest)
  if MyRequest then
    return
  end
  if player.statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE, ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM, ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING, ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
    return
  end
  local req = _G.ProtoMessage:newZoneClientOperationReq()
  req.operation.operator_id = player.serverData.base.actor_id
  req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
  req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_HELLO
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
  if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    local AnimInstance = player.viewObj.Mesh:GetAnimInstance()
    local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
    if RideAllAnimInstance then
      local ScenePet = player.viewObj.BP_RideComponent.ScenePet
      local Config = ScenePet and ScenePet.config and _G.DataConfigManager:GetAllRidePet(ScenePet.config.id)
      if Config and not Config.throw_switch then
        RideAllAnimInstance.isHello = true
      end
    end
    return
  end
  self.PlayingTime = 0
  self.PlayerHelloTime = player:PlayAnim("RlttHello", 1, 0, 0.1, 0.1, 1)
end

function UMG_RelationTree_C:OnTick(DetalTime)
  local CurCD = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationItemSelectCD)
  if CurCD > 0 then
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.SetRelationItemSelectCD, CurCD - DetalTime * 1000)
  elseif CurCD < 0 then
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.SetRelationItemSelectCD, 0)
  end
  if self.PlayerHelloTime and self.PlayerHelloTime > 0 then
    self.PlayingTime = self.PlayingTime + DetalTime
    if self.PlayingTime >= self.PlayerHelloTime then
      self.PlayerHelloTime = 0
    end
  end
end

function UMG_RelationTree_C:OnSkillComplete()
  if self.skillProxy then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not player then
      return
    end
    player:StopAllMontage()
    local ctrl = player and player:GetUEController()
    if ctrl then
      ctrl:SetUICameraState(_G.MainUIModuleEnum.MainUICameraState.Normal)
    end
    self.skillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.skillProxy:Destroy()
    self.skillProxy = nil
  end
end

function UMG_RelationTree_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_RelationTree")
  mappingContext = mappingContext or self:AddInputMappingContext("IMC_RelationTree")
  if mappingContext then
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
    mappingContext:BindAction("IA_ChangeWalkRun")
    mappingContext:BindAction("IA_RelationTreeExit", self, "OnPcCloseUI", UE.ETriggerEvent.Triggered)
    mappingContext:BindAction("IA_TeamPanel_Relation", self, "OpenTeamPanel")
    mappingContext:BindAction("IA_InteractionStart_Relation", self, "RelationInteractionStart")
    mappingContext:BindAction("IA_InteractionEnd_Relation", self, "RelationInteractionEnd")
    mappingContext:BindAction("IA_InteractionNext_Relation", self, "RelationInteractionNext")
    mappingContext:BindAction("IA_InteractionPrevious_Relation", self, "RelationInteractionPrevious")
  else
    Log.Error("IMC_RelationTree  is nil")
  end
end

function UMG_RelationTree_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_RelationTree")
  if mappingContext then
    mappingContext:UnBindAction("IA_RelationTreeExit", self, "OnPcCloseUI", UE.ETriggerEvent.Triggered)
    mappingContext:UnBindAction("IA_TeamPanel_Relation", self, "OpenTeamPanel")
    mappingContext:UnBindAction("IA_InteractionStart_Relation", self, "RelationInteractionStart")
    mappingContext:UnBindAction("IA_InteractionEnd_Relation", self, "RelationInteractionEnd")
    mappingContext:UnBindAction("IA_InteractionNext_Relation", self, "RelationInteractionNext")
    mappingContext:UnBindAction("IA_InteractionPrevious_Relation", self, "RelationInteractionPrevious")
  end
end

function UMG_RelationTree_C:UnBindInputSpecialAction()
  local mappingContext = self:GetInputMappingContext("IMC_RelationTree")
  if mappingContext then
    mappingContext:UnBindAction("IA_TeamPanel_Relation", self, "OpenTeamPanel")
    mappingContext:UnBindAction("IA_InteractionStart_Relation", self, "RelationInteractionStart")
    mappingContext:UnBindAction("IA_InteractionEnd_Relation", self, "RelationInteractionEnd")
    mappingContext:UnBindAction("IA_InteractionNext_Relation", self, "RelationInteractionNext")
    mappingContext:UnBindAction("IA_InteractionPrevious_Relation", self, "RelationInteractionPrevious")
  end
end

function UMG_RelationTree_C:ResetInputSpecialAction()
  local mappingContext = self:GetInputMappingContext("IMC_RelationTree")
  mappingContext = mappingContext or self:AddInputMappingContext("IMC_RelationTree")
  if mappingContext then
    mappingContext:BindAction("IA_TeamPanel_Relation", self, "OpenTeamPanel")
    mappingContext:BindAction("IA_InteractionStart_Relation", self, "RelationInteractionStart")
    mappingContext:BindAction("IA_InteractionEnd_Relation", self, "RelationInteractionEnd")
    mappingContext:BindAction("IA_InteractionNext_Relation", self, "RelationInteractionNext")
    mappingContext:BindAction("IA_InteractionPrevious_Relation", self, "RelationInteractionPrevious")
  else
    Log.Error("IMC_RelationTree  is nil")
  end
end

function UMG_RelationTree_C:RelationInteractionStart()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionStart)
end

function UMG_RelationTree_C:RelationInteractionEnd()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionEnd)
end

function UMG_RelationTree_C:RelationInteractionNext()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionNext, true)
end

function UMG_RelationTree_C:RelationInteractionPrevious()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionPrevious, true)
end

function UMG_RelationTree_C:OnAddEventListener()
  self:OnAddPlayerDataModelEventListener()
  self:DynamicAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseClick)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
    player:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
  end
end

function UMG_RelationTree_C:OnStatusApply(status, statusValue, opCode, customParam, ...)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND or status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P or status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    self:OnCloseClick(true, false)
  end
end

function UMG_RelationTree_C:OnRideMoveTypeChange()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local rideComp = player.viewObj.BP_RideComponent
    if rideComp and rideComp:IsInDoubleRide() then
      self:OnCloseClick(true, false)
    end
  end
end

function UMG_RelationTree_C:DynamicAddEventListener()
  self:AddButtonListener(self.EvenMore.btnLevelUp, self.ShowMoreClick)
end

function UMG_RelationTree_C:OnInputMove()
  if self.PlayerHelloTime and self.PlayerHelloTime > 0 then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if not player then
      return
    end
    local req = _G.ProtoMessage:newZoneClientOperationReq()
    req.operation.operator_id = player.serverData.base.actor_id
    req.operation.operator_type = ProtoEnum.ClientOperationType.COT_PLAYER_PERFORM
    req.operation.player_perform_info.perform_type = ProtoEnum.PlayerPerformType.PPT_HELLO_STOP
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_CLIENT_OPERATION_REQ, req)
    player:StopAnim("RlttHello", 0.1)
    self.PlayerHelloTime = 0
  end
end

function UMG_RelationTree_C:OnAddPlayerDataModelEventListener(isRemove)
  local FriendModule = NRCModuleManager:GetModule("FriendModule")
  local playerModule = NRCModuleManager:GetModule("PlayerModule")
  if isRemove then
    if playerModule then
      playerModule:UnRegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
    end
    if FriendModule then
      FriendModule:UnRegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.ReqPlayerInfo)
    end
    _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoinUI)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.UpdateRelationTreeMoreUI)
    _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  else
    if playerModule then
      playerModule:RegisterEvent(self, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY, self.OnInputMove)
    end
    if FriendModule then
      FriendModule:RegisterEvent(self, FriendModuleEvent.ModifyFriendRemarkUpdate, self.ReqPlayerInfo)
    end
    _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoinUI)
    _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_C", self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.UpdateRelationTreeMoreUI)
    _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_C", self, _G.SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinishNtyAck)
  end
end

function UMG_RelationTree_C:ActiveUpdateUI()
  self:UpdateRelationTreeScrollUI()
  self:UpdateRelationTreeMoreUI()
  self:ActiveBranchOffset()
end

function UMG_RelationTree_C:UpdateUI(IsMove)
  self:UpdateRelationTreeScrollUI()
  self:UpdateRelationTreeMoreUI()
end

function UMG_RelationTree_C:UpdateMaskVisibile()
  local OherRelationRequestEnumType = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, self.PlayerUid)
  if OherRelationRequestEnumType then
    self.MaskImage:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.MaskImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RelationTree_C:UpdateRelationTreeScrollUI()
  if self.ContentScrollBox then
    local RelationTreeData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNode, self.PlayerUid)
    if RelationTreeData then
      self.MaxItemNum = #RelationTreeData.RelationTree
      table.reverse(RelationTreeData.RelationTree)
      local activityObject = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL_STARLIGHT)[1]
      if activityObject then
        local local_uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
        self:InitNodeRecallData(RelationTreeData, local_uin)
      else
        local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
        if playerInfo and playerInfo.tags then
          for _, tag in ipairs(playerInfo.tags) do
            if tag == _G.ProtoEnum.PlayerTag.PT_RECALL then
              self:InitNodeRecallData(RelationTreeData, self.PlayerUid)
            end
          end
        end
      end
      self.Branch:InitGridView(RelationTreeData.RelationTree)
      self.Branch:RefreshGridViewLayout()
    end
  end
end

function UMG_RelationTree_C:InitNodeRecallData(RelationTreeData, targetUin)
  local bPlayRecallAnim = true
  local recordTable = JsonUtils.LoadSaved("RecallFriendsRecord", {})
  if #recordTable > 0 then
    for _, uin in ipairs(recordTable) do
      if uin == targetUin then
        bPlayRecallAnim = false
        break
      end
    end
  end
  for _, nodeList in ipairs(RelationTreeData.RelationTree) do
    for _, node in ipairs(nodeList) do
      if node.RelationTreeTypeDefault == _G.Enum.RelationTreeTypeDefault.RLTTD_INVITE_TOGETHER or node.RelationTreeTypeDefault == _G.Enum.RelationTreeTypeDefault.RLTTD_REQUEST_TOGETHER then
        node.bShowRecall = true
        node.bPlayRecallAnim = bPlayRecallAnim
        if bPlayRecallAnim and node.Unlock then
          self.bNeedJsonRecord = true
        end
      end
    end
  end
end

function UMG_RelationTree_C:ActiveBranchOffset()
  local RelationTreeData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNode, self.PlayerUid)
  if RelationTreeData then
    local ToFloor = 1
    local RelationRequestPlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
    if RelationRequestPlayerUin and RelationRequestPlayerUin == self.PlayerUid then
      ToFloor = self:GetMyRequestFloor(RelationTreeData)
    else
      ToFloor = self:GetOtherRequestFloor(RelationTreeData)
    end
    if ToFloor <= 2 then
      self.ContentScrollBox:ScrollToEnd()
    elseif ToFloor >= 3 then
      self.ContentScrollBox:ScrollToStart()
    else
      self.ContentScrollBox:ScrollToStart()
    end
  end
end

function UMG_RelationTree_C:GetMyRequestFloor(RelationTreeData)
  local MyRequest = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetMyRequest)
  local PlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
  if RelationTreeData and RelationTreeData.RelationTree then
    if PlayerUin == self.PlayerUid then
      for floor, floorValue in ipairs(RelationTreeData.RelationTree) do
        for node, nodeValue in ipairs(floorValue) do
          if nodeValue.RelationTreeType == MyRequest then
            return floor
          end
        end
      end
    end
    return 1
  end
end

function UMG_RelationTree_C:GetOtherRequestFloor(RelationTreeData)
  if RelationTreeData and RelationTreeData.RelationTree then
    for floor, floorValue in ipairs(RelationTreeData.RelationTree) do
      for node, nodeValue in ipairs(floorValue) do
        local NodeApplied = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurrentNodeApplied, self.PlayerUid, nodeValue.RelationTreeType)
        if NodeApplied then
          return floor
        end
      end
    end
    return 1
  end
end

function UMG_RelationTree_C:UpdateBranchOffset(IsMove)
  if IsMove then
    local RelationTreeData = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNode, self.PlayerUid)
    table.reverse(RelationTreeData.RelationTree)
    if RelationTreeData then
      local ToFloor = RelationTreeData.MaxUnLockFloor
      local Offset = 0
      for floor, floorvalue in ipairs(RelationTreeData.RelationTree) do
        if floor <= self.MaxItemNum - ToFloor then
          if #floorvalue < 3 then
            Offset = Offset + FloorItemSizeY_2
          else
            Offset = Offset + FloorItemSizeY_1
          end
        end
      end
      if IsMove then
        self.Offset = Offset
      else
        self.Offset = 0
        self.ContentScrollBox:SetScrollOffset(Offset)
      end
    end
  end
end

function UMG_RelationTree_C:MoveContentScrollBox(deltaTime)
  if self.ContentScrollBox then
    local CurOffset = self.ContentScrollBox:GetScrollOffset()
    if math.abs(CurOffset - self.Offset) > 1 then
      local newOffsetOffset = LuaMathUtils.FInterpTo(CurOffset, self.Offset, deltaTime, 5)
      if math.abs(newOffsetOffset - self.Offset) <= 1 then
        newOffsetOffset = self.Offset
        self.Offset = 0
      end
      self.ContentScrollBox:SetScrollOffset(newOffsetOffset)
    else
      local newOffsetOffset = self.Offset
      self.ContentScrollBox:SetScrollOffset(newOffsetOffset)
      self.Offset = 0
    end
  end
end

function UMG_RelationTree_C:ReqPlayerInfo()
  if self.PlayerUid then
    local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
    req.uin = self.PlayerUid
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.ChangePlayerInfo)
  end
end

function UMG_RelationTree_C:ChangePlayerInfo(Rsp)
  if 0 == Rsp.ret_info.ret_code and Rsp.player_info then
    local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
    if playerInfo then
      playerInfo.name = Rsp.player_info.name
      playerInfo.level = Rsp.player_info.level
      playerInfo.card_icon_selected = Rsp.player_info.card_icon_selected
      _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetOpenPlayerInfo, playerInfo)
      self:UpdatePlayerInfoUI()
    end
  end
end

function UMG_RelationTree_C:UpdatePlayerInfoUI()
  local playerInfo = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetOpenPlayerInfo)
  if playerInfo then
    local Name = string.ExtralongandOmitted(playerInfo.name, 7)
    self.Name_content_3:SetText(Name)
    local isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(self.PlayerUid)
    if isFriend then
      self.Class:SetText(playerInfo.level)
      self.Class:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Class:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(playerInfo.card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
      Log.Debug(AvatarPath, "UMG_RelationTree_C:SetHeadInfo")
      self.HeadPortrait:SetPath(AvatarPath)
    end
  end
end

function UMG_RelationTree_C:OnEnterSceneFinishNtyAck()
  self:OnCloseClick()
end

function UMG_RelationTree_C:UpdateRelationTreeMoreUI()
  local isFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(self.PlayerUid)
  local MoreItemTable = _G.NRCModeManager:DoCmd(RelationTreeCmd.GetMoreElementData, isFriend)
  self.More:UpdateMoreItemList(MoreItemTable)
  self:UpdatePlayerInfoUI()
end

function UMG_RelationTree_C:CollapsedMoreUI()
  self:RemoveButtonListener(self.EvenMore.btnLevelUp, self.ShowMoreClick)
  self.More:PlayAnimation(self.More.Out)
end

function UMG_RelationTree_C:ShowMoreClick()
  self.More:PlayAnimationIn()
  local PlayerController = _G.UE4Helper.GetPlayerCharacter(0):GetController()
  self.More:SetUserFocus(PlayerController)
end

function UMG_RelationTree_C:UpdateSelectItemChange(NodeID)
  local ItemCount = self.Branch:GetItemCount()
  for i = 1, ItemCount do
    local ItemView = self.Branch:GetItemByIndex(i - 1)
    ItemView:UpdateSelectItemChange(NodeID)
  end
end

function UMG_RelationTree_C:UpdateCoinUI()
  local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(CoinType) or 0
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = CoinType,
    sum = coin_num,
    IsShowBuyIcon = true,
    currencyId = CoinType
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_RelationTree_C:UpdatePlayerData()
  local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
  req.uin = self.PlayerUid
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnFriendSearchPlayerRsp, false, true)
end

function UMG_RelationTree_C:OnFriendSearchPlayerRsp(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    Log.Debug(Rsp.player_info)
  end
end

function UMG_RelationTree_C:OnPcCloseUI()
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.CloseRelationTreeTipsPanel)
  self:OnCloseClick()
end

function UMG_RelationTree_C:OpenTeamPanel()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OpenTeamPanel)
end

function UMG_RelationTree_C:OnCloseClick(isNotSound, isNotPlayOut)
  self:UnBindInputAction()
  if not isNotSound then
    _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_RelationTree_C:OnDeactive")
  end
  if not isNotPlayOut then
    self:PlayAnimation(self.Out)
  else
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.CloseRelationCover, self.PlayerUid)
  end
  if self.bNeedJsonRecord then
    local recordTable = JsonUtils.LoadSaved("RecallFriendsRecord", {})
    local activityObject = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_ACTIVITY_RECALL_STARLIGHT)[1]
    if activityObject then
      table.insert(recordTable, _G.DataModelMgr.PlayerDataModel:GetPlayerUin())
    else
      table.insert(recordTable, self.PlayerUid)
    end
    JsonUtils.DumpSaved("RecallFriendsRecord", recordTable)
  end
end

function UMG_RelationTree_C:GetNRCImagePostion()
  if self.NRCImage_1 then
    local pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.NRCImage_1:GetCachedGeometry(), UE4.FVector2D(0, 0))
    return pos
  end
  return nil
end

function UMG_RelationTree_C:OnAnimationFinished(anim)
  if anim == self.Out then
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.CloseRelationCover, self.PlayerUid)
  elseif anim == self.In then
    local Pos = self:GetNRCImagePostion()
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, false, Pos)
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, false)
  end
end

function UMG_RelationTree_C:OnDeactive()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:OnRelationTreeTargetChanged(nil)
    player:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
    player:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRideMoveTypeChange)
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.CloseFriendWold)
  UE4Helper.ReleaseDesiredShowCursor("UMG_RelationTree_C")
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetOpeningRelationPanel, false)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE, nil, true)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetCurOpenPanelPlayerUID, nil)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetOpenPlayerInfo, nil)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetCurOtherLevelData, nil)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetCurUnLockMaxFloor, nil)
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.CloseRelationTreeTipsPanel)
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.RestRelationTreeCloseState)
  if not _G.BattleManager.isInBattle then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "RelationTreePanelOpen")
  end
  self:UnBindInputAction()
  self:RemoveButtonListener(self.EvenMore.btnLevelUp, self.ShowMoreClick)
  self:RemoveButtonListener(self.CloseBtn.btnClose, self.OnCloseClick)
  self:OnAddPlayerDataModelEventListener(true)
  self:OnSkillComplete()
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.SetRelationItemSelectCD, 0)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_PANEL_CLOSE)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, true)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, false)
end

return UMG_RelationTree_C
