local UMG_RelationTree_Pet_C = _G.NRCPanelBase:Extend("UMG_RelationTree_Pet_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local PetStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.PetStatusComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local MAX_RELATION_INTERACT_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("interactiontree_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num

function UMG_RelationTree_Pet_C:OnActive()
  _G.NRCAudioManager:PlaySound2DAuto(1013, "UMG_RelationTree_Pet_C:OnActive")
  UE4Helper.SetDesiredShowCursor(true, "UMG_RelationTree_Pet_C")
  self:CheckColorSuitState()
  self:RelationTreeShowPlayAnim()
  self:OnAddEventListener()
  self:BindInputAction()
  self:ActiveUpdateUI()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_PANEL_OPEN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CameraSetIsCanClick)
  self.IsOpening = true
end

function UMG_RelationTree_Pet_C:CheckColorSuitState()
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
  if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) and ParamData.PetInfo then
    self.IntimacyButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local petInfo = ParamData.PetInfo
    local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
    local BondId = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, PetbaseId)
    if BondId then
      _G.NRCModeManager:DoCmd(RelationTreeCmd.GetPetBondColorSuitState, BondId)
    end
  end
end

function UMG_RelationTree_Pet_C:RelationTreeShowPlayAnim()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  player:SendEvent(PlayerModuleEvent.ON_INTERRUPT_THROW)
  player:SendEvent(PlayerModuleEvent.ON_INTERRUPT_AIM)
end

function UMG_RelationTree_Pet_C:OnTick(DetalTime)
  local CurCD = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationItemSelectCD)
  if CurCD > 0 then
    _G.NRCModeManager:DoCmd(RelationTreeCmd.SetRelationItemSelectCD, CurCD - DetalTime * 1000)
  elseif CurCD < 0 then
    _G.NRCModeManager:DoCmd(RelationTreeCmd.SetRelationItemSelectCD, 0)
  end
  if self.IsOpening then
    local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
    if ParamData and ParamData.PetInfo and ParamData.PetInfo.squaredDis2Local then
      local Dis, DisIgnoreZ = ParamData.PetInfo:CalSquaredDis2Local()
      if Dis >= MAX_RELATION_INTERACT_DISTANCE * MAX_RELATION_INTERACT_DISTANCE then
        _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnPetInfoRideSuccessClose, true)
        self.IsOpening = false
        return
      end
      local CurAnge = math.acos(ParamData.PetInfo.PlayerForwardDotCache) * (180 / math.pi)
      _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnPetInfoEnableTouch, ParamData.PetInfo, Dis, CurAnge)
    end
  end
end

function UMG_RelationTree_Pet_C:ActiveUpdateUI()
  self:UpdateRelationTreeScrollUI()
  self:UpdatePetInfo()
  self:UpdateRecommendation()
  self:UpdateCoinUI()
  self:InitScrollPosition()
  self:UpdateClosenessUI()
end

function UMG_RelationTree_Pet_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseClick)
  self:AddButtonListener(self.RecommendationList.btnLevelUp, self.OnRecommendationClicked)
  self:AddButtonListener(self.ParticularsBtn.btnLevelUp, self.OnParticularsClicked)
  self:AddButtonListener(self.IntimacyButton, self.OnIntimacyButtonClicked)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoinUIAndPetInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, RelationTreeEvent.OnPetInfoChangeEvent, self.ReqUpdatePetInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, RelationTreeEvent.OnPetInfoRideSuccessClose, self.OnCloseClick)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.UpdateRelationTreeScrollUI)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, NPCModuleEvent.On_NPC_LEAVE, self.OnPetNPCLeaveClosePanel)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, RelationTreeEvent.OnUpdatePetClosenessInfo, self.UpdateClosenessUI)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, _G.NRCGlobalEvent.UPDATE_PLAYER_BOND_INFO, self.UpdateRelationTreeScrollUI)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
  end
end

function UMG_RelationTree_Pet_C:OnStatusApply(status, statusValue, opCode, customParam, ...)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND or status == ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P or status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL then
    self:OnCloseClick(true, false)
  end
end

function UMG_RelationTree_Pet_C:BindInputAction()
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

function UMG_RelationTree_Pet_C:UnBindInputAction()
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

function UMG_RelationTree_Pet_C:RelationInteractionStart()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionStart)
end

function UMG_RelationTree_Pet_C:RelationInteractionEnd()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionEnd)
end

function UMG_RelationTree_Pet_C:RelationInteractionNext()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionNext, true)
end

function UMG_RelationTree_Pet_C:RelationInteractionPrevious()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RelationInteractionPrevious, true)
end

function UMG_RelationTree_Pet_C:UpdateRelationTreeScrollUI()
  local PetRelationTreeTable = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetPetRelationTreeData)
  if PetRelationTreeTable then
    self.Branch:InitGridView(PetRelationTreeTable)
    self.Branch:RefreshGridViewLayout()
  end
end

function UMG_RelationTree_Pet_C:InitScrollPosition()
  self.ContentScrollBox:ScrollToEnd()
end

function UMG_RelationTree_Pet_C:OpenClosenessDetailUI()
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  if ParamData then
    local PetNpcCreateAvatarId = ParamData.AvatarID
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, PetNpcCreateAvatarId)
    if player then
      local PlayerUin = player.serverData and player.serverData.base and player.serverData.base.logic_id or 0
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Pet_C:OpenClosenessDetailUI")
      _G.NRCModuleManager:DoCmd(RelationTreeCmd.OpenRelationTreeIntimacyTipsPanel, PlayerUin, ParamData)
      _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnUpdatePetClosenessInfo, self.UpdateClosenessUI)
    end
  end
end

function UMG_RelationTree_Pet_C:CloseClosenessDetailUI()
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Pet_C", self, RelationTreeEvent.OnUpdatePetClosenessInfo, self.UpdateClosenessUI)
  self:UpdateClosenessUI()
end

function UMG_RelationTree_Pet_C:UpdateClosenessUI()
  local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
  if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
    if ParamData.PetInfo then
      self.IntimacyButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local petInfo = ParamData.PetInfo
      local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
      local PetGid = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.gid or 0
      local PetStatusComponent = petInfo:EnsureComponent(PetStatusComponent)
      if PetStatusComponent then
        local closenessLv = PetData and PetData.closeness_info and PetData.closeness_info.closeness_lv or 0
        if not self.PetClosenessLv then
          self.PetClosenessLv = closenessLv
          self.IntimacyText:SetText(self.PetClosenessLv)
          self.IntimacyText_1:SetText(self.PetClosenessLv)
        elseif closenessLv ~= self.PetClosenessLv then
          self.IntimacyText:SetText(self.PetClosenessLv)
          self.IntimacyText_1:SetText(closenessLv)
          self:PlayerClosenessChangeLvAnim(closenessLv)
        else
          self.IntimacyText:SetText(self.PetClosenessLv)
          self.IntimacyText_1:SetText(self.PetClosenessLv)
        end
      else
        self.IntimacyText:SetText(0)
      end
    end
  else
    self.IntimacyButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RelationTree_Pet_C:PlayerClosenessChangeLvAnim(closenessLv)
  self.PetClosenessLv = closenessLv
  _G.NRCAudioManager:PlaySound2DAuto(1065, "UMG_RelationTree_Pet_C:PlayerClosenessChangeLvAnim")
  self:PlayAnimation(self.intimacy_up)
end

function UMG_RelationTree_Pet_C:ReqUpdatePetInfo()
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  if ParamData then
    local PetNpcCreateAvatarId = ParamData.AvatarID
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, PetNpcCreateAvatarId)
    if player then
      local PlayerUin = player.serverData and player.serverData.base and player.serverData.base.logic_id or 0
      _G.NRCModuleManager:DoCmd(RelationTreeCmd.SearchPetReq, PlayerUin, ParamData)
    end
  end
end

function UMG_RelationTree_Pet_C:UpdatePetInfo()
  local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
  if PetData then
    local Name = PetData.name or ""
    self.Name_content_3:SetText(Name)
    local level = PetData.level or 0
    self.Class:SetText(level)
    local TargetPetBaseId = PetData.base_conf_id or 0
    local MutationType = PetData.mutation_type or 0
    local GlassInfo = PetData.glass_info
    self.HeadPortrait:SetIconPathAndMaterial(TargetPetBaseId, MutationType, GlassInfo)
  end
end

function UMG_RelationTree_Pet_C:UpdateRecommendation()
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
  if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
    self.BtnSwitcher:SetActiveWidgetIndex(1)
  else
    self.BtnSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_RelationTree_Pet_C:UpdateCoinUIAndPetInfo()
  self:UpdateCoinUI()
  self:ReqUpdatePetInfo()
end

function UMG_RelationTree_Pet_C:UpdateCoinUI()
  local coin_num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_BRAVE_STAR) or 0
  local moneyInfo = {}
  table.insert(moneyInfo, {
    moneyType = _G.Enum.VisualItem.VI_BRAVE_STAR,
    sum = coin_num,
    IsShowBuyIcon = false
  })
  self.MoneyBtn:InitGridView(moneyInfo)
end

function UMG_RelationTree_Pet_C:OnRecommendationClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Pet_C:OnRecommendationClicked")
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.statusComponent and player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING) then
    local Text = LuaText.relationtree_abnormal_status_tip
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpcCreateAvatarId = ParamData.AvatarID
  if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
    _G.NRCProfilerLog:NRCClickBtn(true, "StudentCard")
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
  else
    _G.NRCProfilerLog:NRCClickBtn(true, "StudentCard")
    local pet_target_uin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerUin)
    if pet_target_uin then
      local req = _G.ProtoMessage:newZoneFriendSearchPlayerReq()
      req.uin = pet_target_uin
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_FRIEND_SEARCH_PLAYER_REQ, req, self, self.OnReadyOpenOpenStudentCardPanel, false, true)
    end
  end
end

function UMG_RelationTree_Pet_C:OnParticularsClicked()
  local Context = DialogContext()
  local title = LuaText.interactiontree_love_title
  local des = LuaText.interactiontree_love_tip
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.NotBtn):SetContentTextJustify(UE4.ETextJustify.Left):SetCloseOnCancel(true):SetCloseOnOK(true)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_RelationTree_Pet_C:OnIntimacyButtonClicked()
  self:OpenClosenessDetailUI()
end

function UMG_RelationTree_Pet_C:OnReadyOpenOpenStudentCardPanel(rsp)
  if 0 == rsp.ret_info.ret_code and rsp.player_info then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, rsp.player_info, FriendEnum.AdminFriendType.Others, rsp.is_friend and FriendEnum.Source.Friend or FriendEnum.Source.Scene, nil)
  end
end

function UMG_RelationTree_Pet_C:OnPetNPCLeaveClosePanel(npc)
  if npc then
    local NPCId = npc and npc.serverData and npc.serverData.base and npc.serverData.base.actor_id or 0
    local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
    local PetNpcId = ParamData and ParamData.PetInfo and ParamData.PetInfo.serverData and ParamData.PetInfo.serverData.base and ParamData.PetInfo.serverData.base.actor_id or 0
    if PetNpcId == NPCId then
      self:OnCloseClick(true, true)
    end
  end
end

function UMG_RelationTree_Pet_C:OnPcCloseUI()
  local IntimacyPanel = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetRelationTreeIntimacyTipsPanel)
  if IntimacyPanel then
    IntimacyPanel:OnCloseClick()
    return
  end
  self:OnCloseClick()
end

function UMG_RelationTree_Pet_C:OpenTeamPanel()
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OpenTeamPanel)
end

function UMG_RelationTree_Pet_C:OnCloseClick(isNotSound, isNotPlayOut)
  if not isNotSound then
    _G.NRCAudioManager:PlaySound2DAuto(40008006, "UMG_RelationTree_Pet_C:OnDeactive")
  end
  self:UnBindInputAction()
  if not isNotPlayOut then
    self:PlayAnimation(self.Out)
  else
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ClosePetRelationCover)
  end
end

function UMG_RelationTree_Pet_C:GetNRCImagePostion()
  if self.NRCImage_1 then
    local pos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.NRCImage_1:GetCachedGeometry(), UE4.FVector2D(0, 0))
    return pos
  end
  return nil
end

function UMG_RelationTree_Pet_C:OnAnimationFinished(anim)
  if anim == self.Out then
    _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.ClosePetRelationCover)
  elseif anim == self.In then
    local Pos = self:GetNRCImagePostion()
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, false, Pos)
    _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, false)
  elseif anim == self.intimacy_up then
    self.IntimacyText:SetText(self.PetClosenessLv)
    self.IntimacyText_1:SetText(self.PetClosenessLv)
  end
end

function UMG_RelationTree_Pet_C:UpdateSelectPetItemChange(NodeId)
  local ItemCount = self.Branch:GetItemCount()
  for i = 1, ItemCount do
    local ItemView = self.Branch:GetItemByIndex(i - 1)
    ItemView:UpdateSelectItemChange(NodeId)
  end
end

function UMG_RelationTree_Pet_C:OnDeactive()
  self.IsOpening = false
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveInputBlockMappingContext, "RelationTreePanelOpen")
  self:UnBindInputAction()
  UE4Helper.ReleaseDesiredShowCursor("UMG_RelationTree_Pet_C")
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
  if PetNpc then
    PetNpc:SetPetBondActive(false, 1)
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnStatusApply)
  end
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetOpeningRelationPanel, false)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_OPEN_PLAYER_RELATIONSHIP_TREE, nil, true)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetPetRelationTreeUIData, nil)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetPetInfoData, nil)
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.SetCurOpenPetPanelPlayerUin, nil)
  _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.SetRelationItemSelectCD, 0)
  self:RemoveButtonListener(self.CloseBtn.btnClose, self.OnCloseClick)
  self:RemoveButtonListener(self.RecommendationList.btnLevelUp, self.OnRecommendationClicked)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoinUIAndPetInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnPetInfoChangeEvent, self.ReqUpdatePetInfo)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnPetInfoRideSuccessClose, self.OnCloseClick)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.On_NPC_LEAVE, self.OnPetNPCLeaveClosePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ADD_OR_REMOVE_BRIEF_FRIEND, self.UpdateRelationTreeScrollUI)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnUpdatePetClosenessInfo, self.UpdateClosenessUI)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.UPDATE_PLAYER_BOND_INFO, self.UpdateRelationTreeScrollUI)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_PANEL_CLOSE)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OffSetNPCInteractObjectList, true)
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.RELATION_TREE_OPENING_PANEL_TAG, false)
end

return UMG_RelationTree_Pet_C
