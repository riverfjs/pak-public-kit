local PlayerModuleCmd = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleCmd")
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerOption = require("NewRoco.Modules.Core.NPC.Executors.PlayerOption")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local MAX_DELTA_TIME = _G.DataConfigManager:GetGlobalConfigByKeyType("player_option_tick", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local MAX_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("players_interact_distance", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
local MAX_INTERACT_NUMBER = _G.DataConfigManager:GetGlobalConfigByKeyType("players_interact_option_num", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).num
local MAX_RELATION_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_interact_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local MAX_RELATION_OPEN_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local DEBUG_HIDE = false
local Player2PlayerInteractionComponent = Base:Extend("Player2PlayerInteractionComponent")

function Player2PlayerInteractionComponent:Attach(owner)
  Base.Attach(self, owner)
  self.InPVPMatchState = false
  self.IsOpeningRelationPanel = false
  self.TotalTime = 0
  self.OptionMap = {}
  self.RelationOptionMap = {}
  _G.NRCEventCenter:RegisterEvent(self.name, self, RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, self.UpdateRelationOpation)
  _G.NRCEventCenter:RegisterEvent(self.name, self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.UpdateOpeningRelationPanelTag)
  _G.NRCEventCenter:RegisterEvent(self.name, self, PlayerModuleEvent.ON_PLAYER_DESTROY, self.OnPlayerDestroy)
  _G.NRCEventCenter:RegisterEvent(self.name, self, NRCGlobalEvent.PlayerPVPMatchStateChange, self.UpdateSelfPVPMatchState)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.ClearOptionMap)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnVisitorChanged, self.ClearOptionMap)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PET_GANZHI, self, self.ClearOptionMap)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MINIGAME_UI, self, self.ClearOptionMap)
end

function Player2PlayerInteractionComponent:UpdateOpeningRelationPanelTag(IsOpeningRelationPanel)
  self.IsOpeningRelationPanel = IsOpeningRelationPanel
end

function Player2PlayerInteractionComponent:UpdateSelfPVPMatchState(State)
  if State == ProtoEnum.PvpMatchState.PMS_MATCHING then
    self.InPVPMatchState = true
    self:ClearOptionMap()
  else
    self.InPVPMatchState = false
  end
end

function Player2PlayerInteractionComponent:ClearOptionMap()
  for i, Option in pairs(self.OptionMap) do
    if Option then
      Option:RemoveFromInteractUI()
    end
  end
  self.OptionMap = {}
  if self.IsOpeningRelationPanel then
    return
  end
  for i, Option in pairs(self.RelationOptionMap) do
    if Option then
      Option:RemoveFromInteractUI()
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, i.serverData.base.logic_id, true)
    end
  end
  self.RelationOptionMap = {}
end

function Player2PlayerInteractionComponent:DeAttach()
  Base.DeAttach(self)
  self.IsOpeningRelationPanel = false
  if not _G.RelationTreeCmd then
    Log.Warning("Check if it is local mode")
    return
  end
  local MyRequest = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetMyRequest)
  local PlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
  if MyRequest and PlayerUin then
    _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.CancelUnlockRelationshipNodeReqAndInvite, PlayerUin)
  end
  self:ClearOptionMap()
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_UNLOCK_REQ_UPDATE_OPATION, self.UpdateRelationOpation)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, self.UpdateOpeningRelationPanelTag)
  _G.NRCEventCenter:UnRegisterEvent(self, PlayerModuleEvent.ON_PLAYER_DESTROY, self.OnPlayerDestroy)
  _G.NRCEventCenter:UnRegisterEvent(self, NRCGlobalEvent.PlayerPVPMatchStateChange, self.UpdateSelfPVPMatchState)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.ClearOptionMap)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnVisitorChanged, self.ClearOptionMap)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_PET_GANZHI, self, self.ClearOptionMap)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MINIGAME_UI, self, self.ClearOptionMap)
end

function Player2PlayerInteractionComponent:Update(deltaTime)
  DEBUG_HIDE = _G.GlobalConfig.IsShowPlayer
  if DEBUG_HIDE then
    return
  end
  self.TotalTime = self.TotalTime + deltaTime * 1000
  if self.TotalTime < MAX_DELTA_TIME then
    return
  end
  self.TotalTime = 0
  local MeshComp = self.owner.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  if not MeshComp then
    return
  end
  local OwnerLocation = MeshComp:Abs_K2_GetComponentLocation()
  local OwnerYaw = self.owner.viewObj:K2_GetActorRotation().Yaw
  local PlayerList = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_ALL_PLAYER)
  local RelationRequestPlayerUin
  if _G.RelationTreeCmd ~= nil then
    RelationRequestPlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
  end
  local IsOpenRelationTargetUin
  if _G.RelationTreeCmd ~= nil then
    IsOpenRelationTargetUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurPlayerUID)
  end
  if PlayerList then
    local InteractPlayerList = {}
    local InteractPlayerDistance = {}
    local InteractPlayerYawOffset = {}
    local NoInteractPlayerList = {}
    local RelationRequestPlayer
    local IsHaveRelationPlayer = false
    local RelationOpenPlayer
    local IsHaveRelationOpenPlayer = false
    for _, Player in pairs(PlayerList) do
      if Player and not Player:IsMagicReplayActor() and Player ~= self.owner then
        if Player:IsServerStatus(_G.Enum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX) then
          table.insert(NoInteractPlayerList, Player)
        elseif Player.viewObj and UE.UObject.IsValid then
          local PlayerMeshComp = Player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
          if PlayerMeshComp then
            local Loc = PlayerMeshComp:Abs_K2_GetComponentLocation()
            local Rot = UE4.UKismetMathLibrary.Conv_VectorToRotator(UE4.UKismetMathLibrary.Subtract_VectorVector(Loc, OwnerLocation))
            local a, b, YawOffset = _G.LuaMathUtils.DiffAngle(Rot.Yaw, OwnerYaw)
            YawOffset = math.abs(YawOffset)
            local Dist = UE4.FVector.Dist(OwnerLocation, Loc)
            if Dist < MAX_INTERACT_DISTANCE and YawOffset <= 60 then
              table.insert(InteractPlayerList, Player)
              Player.Dist = Dist
              InteractPlayerDistance[Player] = Dist
              InteractPlayerYawOffset[Player] = YawOffset
            else
              table.insert(NoInteractPlayerList, Player)
            end
            if RelationRequestPlayerUin and Player.serverData.base.logic_id == RelationRequestPlayerUin then
              RelationRequestPlayer = Player
              if RelationRequestPlayer then
                IsHaveRelationPlayer = true
                if Dist > MAX_RELATION_INTERACT_DISTANCE then
                  self:MyOwnerInviteCancel(RelationRequestPlayerUin)
                end
              end
            end
            if IsOpenRelationTargetUin and Player.serverData.base.logic_id == IsOpenRelationTargetUin then
              RelationOpenPlayer = Player
              if RelationOpenPlayer then
                IsHaveRelationOpenPlayer = true
                if Dist > MAX_RELATION_OPEN_INTERACT_DISTANCE then
                  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeIsOpenAndClose)
                end
              end
            end
          end
        end
      end
    end
    if RelationRequestPlayerUin and not IsHaveRelationPlayer then
      self:MyOwnerInviteCancel(RelationRequestPlayerUin)
    end
    if IsOpenRelationTargetUin and not IsHaveRelationOpenPlayer then
      _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeIsOpenAndClose)
    end
    if #InteractPlayerList > 0 then
      table.sort(InteractPlayerList, function(A, B)
        if InteractPlayerDistance[A] ~= InteractPlayerDistance[B] then
          return InteractPlayerDistance[A] < InteractPlayerDistance[B]
        else
          return InteractPlayerYawOffset[A] < InteractPlayerYawOffset[B]
        end
      end)
      for i = 1, #InteractPlayerList do
        local Player = InteractPlayerList[i]
        if Player then
          if i > MAX_INTERACT_NUMBER then
            table.insert(NoInteractPlayerList, Player)
          elseif Player.viewObj then
            local HeadWidget = Player.viewObj.HeadWidget
            if HeadWidget then
              local HeadHud = HeadWidget:GetUserWidgetObject()
              if HeadHud then
                local bOptionsVisible = true
                if _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdHasAnyChatBubble, Player.viewObj) then
                  bOptionsVisible = false
                end
                if Player:IsInTogetherMove() or Player:IsTogetherMove2P() then
                  bOptionsVisible = false
                end
                if self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_SIT_DOWN) then
                  bOptionsVisible = false
                end
                if self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX) then
                  bOptionsVisible = false
                end
                HeadHud:SetInteractionOptionsVisible(bOptionsVisible, Player)
                if not _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsSelfInWorldCombat) and not self.owner:IsLogicStatus(_G.Enum.SpaceActorLogicStatus.SALS_PLAYER_IN_BLINDBOX) and _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetHasNPCInteractMainPanel) then
                  local Option = self.OptionMap[Player]
                  if not Option and not self.InPVPMatchState then
                    local PlayerName = LuaText.relationtree_player_stranger_option
                    if Player.serverData then
                      local UIN = Player.serverData.base.logic_id
                      local bIsFriend = _G.DataModelMgr.PlayerDataModel:IsFriend(UIN)
                      local bIsVisitor = _G.DataModelMgr.PlayerDataModel:IsVisitor(UIN)
                      if bIsFriend or bIsVisitor then
                        PlayerName = Player.serverData.base.name or ""
                      end
                    end
                    local Name = string.ExtralongandOmitted(PlayerName, 9)
                    Option = PlayerOption(Player, 130001, {CustomName = Name})
                    local addSuccess = Option:AddToInteractUI()
                    if addSuccess then
                      self.OptionMap[Player] = Option
                    end
                  end
                  local OtherRelationReuqest = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, Player.serverData.base.logic_id)
                  if OtherRelationReuqest then
                    local RelationOption = self.RelationOptionMap[Player]
                    if not RelationOption and not self.InPVPMatchState then
                      local OptionRelationValue = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNodeByEnum, OtherRelationReuqest)
                      local OptionName = OptionRelationValue and OptionRelationValue.OptionName or ""
                      RelationOption = PlayerOption(Player, 140014, {
                        IsYellow = true,
                        CustomName = OptionName,
                        IsYellowBG = true
                      })
                      local addSuccess = RelationOption:AddToInteractUI()
                      if addSuccess then
                        self.RelationOptionMap[Player] = RelationOption
                        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, true, Player.serverData.base.logic_id, true)
                      end
                    end
                  end
                  if self.owner then
                    local InvitePlayerUin = Player and Player.serverData and Player.serverData.base and Player.serverData.base.logic_id or nil
                    local InviteComponent = self.owner:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
                    local bInInvite = Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
                    if bInInvite and InvitePlayerUin and InviteComponent then
                      local InviteInfo = InviteComponent:GetInvviterByUin(InvitePlayerUin)
                      if InviteInfo then
                        local PlayerInteractState = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetPlayerInteractStateCache)
                        local BannedByState = false
                        if InviteInfo.Player then
                          local OptionID = 140012
                          local Option = InviteInfo.Option
                          local InteractParam = InviteInfo.InteractParam
                          local Config = _G.DataConfigManager:GetRelationtreeAnimConf(InteractParam.action_id)
                          if Config and Config.option_key and Config.option_key > 0 then
                            OptionID = Config.option_key
                            InteractParam.IsYellow = true
                            InteractParam.IsYellowBG = true
                          end
                          Option = PlayerOption(InviteInfo.Player, OptionID, InviteInfo.InteractParam)
                          BannedByState = Option and Option:IsInteractBanState(PlayerInteractState)
                        end
                        if BannedByState then
                          if InviteInfo.Option then
                            InviteInfo.Option:RemoveFromInteractUI()
                            if InviteComponent.YellowBubblesList[InvitePlayerUin] then
                              InviteComponent.YellowBubblesList[InvitePlayerUin] = nil
                              _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, InvitePlayerUin)
                            end
                            InviteInfo.Option = nil
                          end
                        elseif InviteInfo.Player then
                          local Option = InviteInfo.Option
                          if not Option then
                            local OptionID = 140012
                            local InteractParam = InviteInfo.InteractParam
                            if InteractParam and InteractParam.action_id then
                              local Config = _G.DataConfigManager:GetRelationtreeAnimConf(InteractParam.action_id)
                              if Config and Config.option_key and Config.option_key > 0 then
                                OptionID = Config.option_key
                                InteractParam.IsYellow = true
                                InteractParam.IsYellowBG = true
                              end
                            end
                            Option = PlayerOption(InviteInfo.Player, OptionID, InviteInfo.InteractParam)
                            local addSuccess = Option:AddToInteractUI()
                            if addSuccess then
                              InviteInfo.Option = Option
                              InviteComponent.YellowBubblesList[InvitePlayerUin] = true
                              _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, true, InvitePlayerUin)
                            end
                          end
                        else
                          InviteInfo.Player = nil
                          if InviteInfo.Option then
                            InviteInfo.Option:RemoveFromInteractUI()
                            if self.YellowBubblesList[InvitePlayerUin] then
                              self.YellowBubblesList[InvitePlayerUin] = nil
                              _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, InvitePlayerUin)
                            end
                            InviteInfo.Option = nil
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if #NoInteractPlayerList > 0 then
      for _, Player in pairs(NoInteractPlayerList) do
        if Player.viewObj then
          local HeadWidget = Player.viewObj.HeadWidget
          if HeadWidget then
            local HeadHud = HeadWidget:GetUserWidgetObject()
            if HeadHud then
              HeadHud:SetInteractionOptionsVisible(false, Player)
            end
            local Option = self.OptionMap[Player]
            if Option then
              Option:RemoveFromInteractUI()
              self.OptionMap[Player] = nil
            end
            local RelationOption = self.RelationOptionMap[Player]
            if RelationOption then
              RelationOption:RemoveFromInteractUI()
              self.RelationOptionMap[Player] = nil
              _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, Player.serverData.base.logic_id, true)
            end
            local InvitePlayerUin = Player and Player.serverData and Player.serverData.base and Player.serverData.base.logic_id or nil
            local InviteComponent = self.owner:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
            if InvitePlayerUin and InviteComponent then
              local InviteInfo = InviteComponent:GetInvviterByUin(InvitePlayerUin)
              if InviteInfo and InviteInfo.Option then
                InviteInfo.Option:RemoveFromInteractUI()
                if InviteComponent.YellowBubblesList[InvitePlayerUin] then
                  InviteComponent.YellowBubblesList[InvitePlayerUin] = nil
                  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, InvitePlayerUin)
                end
                InviteInfo.Option = nil
              end
            end
          end
        end
      end
    end
  end
end

function Player2PlayerInteractionComponent:UpdateRelationOpation(RequestPlayerUin)
  if not self.owner then
    return
  end
  local MeshComp = self.owner.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  if not MeshComp then
    return
  end
  local OwnerLocation = MeshComp:Abs_K2_GetComponentLocation()
  local OwnerYaw = self.owner.viewObj:K2_GetActorRotation().Yaw
  local PlayerList = _G.NRCModeManager:DoCmd(PlayerModuleCmd.GET_ALL_PLAYER)
  if PlayerList then
    for _, Player in pairs(PlayerList) do
      if Player and Player ~= self.owner and Player.serverData.base.logic_id == RequestPlayerUin then
        local PlayerMeshComp = Player.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
        if PlayerMeshComp then
          local Dist = UE4.FVector.Dist(OwnerLocation, PlayerMeshComp:Abs_K2_GetComponentLocation())
          local Loc = PlayerMeshComp:Abs_K2_GetComponentLocation()
          local Rot = UE4.UKismetMathLibrary.Conv_VectorToRotator(UE4.UKismetMathLibrary.Subtract_VectorVector(Loc, OwnerLocation))
          local a, b, YawOffset = _G.LuaMathUtils.DiffAngle(Rot.Yaw, OwnerYaw)
          YawOffset = math.abs(YawOffset)
          if Dist <= MAX_INTERACT_DISTANCE and YawOffset <= 60 then
            local OtherRelationReuqest = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetOtherRequestsByUin, Player.serverData.base.logic_id)
            if OtherRelationReuqest and not self.InPVPMatchState then
              if self.RelationOptionMap[Player] then
                self.RelationOptionMap[Player]:UpdateDist(Dist)
                local addSuccess = self.RelationOptionMap[Player]:AddToInteractUI()
                if addSuccess then
                  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, true, Player.serverData.base.logic_id, true)
                end
              else
                local RelationOption = self.RelationOptionMap[Player]
                if not RelationOption and not self.InPVPMatchState then
                  local OptionRelationValue = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeNodeByEnum, OtherRelationReuqest)
                  local OptionName = OptionRelationValue.OptionName or ""
                  RelationOption = PlayerOption(Player, 140014, {
                    IsYellow = true,
                    CustomName = OptionName,
                    IsYellowBG = true
                  })
                  if RelationOption then
                    local addSuccess = RelationOption:AddToInteractUI()
                    if addSuccess then
                      self.RelationOptionMap[Player] = RelationOption
                      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, true, Player.serverData.base.logic_id, true)
                    end
                  end
                end
              end
            elseif self.RelationOptionMap[Player] then
              self.RelationOptionMap[Player]:RemoveFromInteractUI()
              self.RelationOptionMap[Player] = nil
              _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, Player.serverData.base.logic_id, true)
            end
          elseif self.RelationOptionMap[Player] then
            self.RelationOptionMap[Player]:RemoveFromInteractUI()
            self.RelationOptionMap[Player] = nil
            _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, Player.serverData.base.logic_id, true)
          end
        end
      end
    end
  end
end

function Player2PlayerInteractionComponent:MyOwnerInviteCancel(RelationRequestPlayerUin)
  if RelationRequestPlayerUin then
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.CancelUnlockRelationshipNodeReqAndInvite, RelationRequestPlayerUin)
  end
end

function Player2PlayerInteractionComponent:OnPlayerDestroy(Player)
  if _G.RelationTreeCmd then
    local MyRequest = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetMyRequest)
    local PlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurRequestPlayerUID)
    local TargetPlayerUin = Player and Player.serverData and Player.serverData.base and Player.serverData.base.logic_id or nil
    if MyRequest and PlayerUin and TargetPlayerUin and PlayerUin == TargetPlayerUin then
      _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.CancelUnlockRelationshipNodeReqAndInvite, TargetPlayerUin)
    end
  end
  local Option = self.OptionMap[Player]
  if Option then
    Option:RemoveFromInteractUI()
    self.OptionMap[Player] = nil
  end
  local RelationOption = self.RelationOptionMap[Player]
  if RelationOption then
    RelationOption:RemoveFromInteractUI()
    self.RelationOptionMap[Player] = nil
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.UPDATE_RELATION_BUBBLE_BY_OPTION, false, Player.serverData.base.logic_id, true)
  end
end

function Player2PlayerInteractionComponent:GetDoubleRidePlayer()
  local StatusID = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local CustomParams = self.owner.statusComponent:GetCustomParams(StatusID)
  if not CustomParams then
    return
  end
  local OtherPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, CustomParams.ride_param.double_ride_1p_id)
  if OtherPlayer == self.owner then
    OtherPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, CustomParams.ride_param.double_ride_2p_id)
  end
  return OtherPlayer
end

return Player2PlayerInteractionComponent
