local TeamBattleModuleEvent = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_TeamBattle_Preparation_C = _G.NRCPanelBase:Extend("UMG_TeamBattle_Preparation_C")

function UMG_TeamBattle_Preparation_C:OnActive(param, challengeType)
  self.bStartTick = true
  _G.NRCAudioManager:PlaySound2DAuto(1011, "UMG_TeamBattle_Preparation_C:OnActive")
  self.uiData = param
  self.challengeType = self.module.CurChallengeType
  self.data = self.module:GetData("TeamBattleModuleData")
  self:SetCommonPopUpInfo(self.PopUp4)
  self.PopUp4:SetDescInfo("\231\130\185\229\135\187\231\178\190\231\129\181\229\164\180\229\131\143\239\188\140\229\143\175\230\155\180\230\141\162\229\135\186\230\136\152\231\178\190\231\129\181")
  self.PrepareInfoList = {}
  self:OnAddEventListener()
  self:InitPanelInfo(param)
  self:LoadAnimation(0)
  UE4Helper.SetDesiredShowCursor(true, "UMG_TeamBattle_Preparation_C")
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    _G.BattleLevelHelper:LoadBloodTeamLevelStream()
  end
  _G.NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
end

function UMG_TeamBattle_Preparation_C:OnDeactive()
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  self:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_CloseDialog)
end

function UMG_TeamBattle_Preparation_C:OnAddEventListener()
  self:RegisterEvent(self, TeamBattleModuleEvent.StarNumChange, self.UpdateHealth)
  _G.NRCEventCenter:RegisterEvent("UMG_TeamBattle_Preparation_C", self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
end

function UMG_TeamBattle_Preparation_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, TeamBattleModuleEvent.StarNumChange, self.UpdateHealth)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_START, self.OnReConnectStart)
end

function UMG_TeamBattle_Preparation_C:OnConstruct()
  self.bStartTick = false
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "PreparationPanel")
  self:SetChildViews(self.PopUp4)
  _G.NRCEventCenter:DispatchEvent(TeamBattleModuleEvent.PreparationPanelOpen)
end

function UMG_TeamBattle_Preparation_C:OnDestruct()
  self:OnRemoveEventListener()
  self.module:ClearTeamMateInfoList()
  self.module:ClearFusionInfo(true)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "PreparationPanel")
  UE4Helper.ReleaseDesiredShowCursor("UMG_TeamBattle_Preparation_C")
  self.bStartTick = false
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    _G.BattleLevelHelper:StartWait(10)
  end
  _G.NRCEventCenter:DispatchEvent(TeamBattleModuleEvent.PreparationPanelClose)
end

function UMG_TeamBattle_Preparation_C:SetCommonPopUpInfo(PopUp, TitleText, TitleIcon)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  if TitleText then
    CommonPopUpData.TitleText = TitleText
  end
  if TitleIcon then
    CommonPopUpData.TitleIcon = TitleIcon
  end
  CommonPopUpData.FullScreen_Close = false
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnCancelBtnClicked
  CommonPopUpData.Btn_RightHandler = self.OnConfirmBtnClicked
  CommonPopUpData.ClosePanelHandler = self.OnCancelBtnClicked
  CommonPopUpData.SkipCloseAnim = true
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
  PopUp.Btn_Right_GrayState:SetIsEnabled(false)
  PopUp.Btn_Right_GrayState.img_suo:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TeamBattle_Preparation_C:OnReConnectStart()
  self:DoClose()
end

function UMG_TeamBattle_Preparation_C:UpdateHealth()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    local stamina = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
    local StaminaProportion = string.format("%s%s%s", StarNum, "/", stamina.num)
    self.MoneyBtn2:SetInfo(_G.Enum.VisualItem.VI_STAR, StaminaProportion, true)
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    local costItemId = _G.DataConfigManager:GetLegendaryGlobalConfig("beast_challenge_ticket_id").num
    local itemConf = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItemId)
    local starNum = 0
    if nil == itemConf then
      starNum = 0
    else
      starNum = itemConf.num
    end
    self.MoneyBtn2:SetInfo(costItemId, starNum, true)
  end
  self.MoneyBtn2:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_TeamBattle_Preparation_C:OnTick(deltaTime)
  if self.bStartTick == true and self.challengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE and self.challengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    if self.module.LeftTime >= 0 then
      local percent = self.module.LeftTime / self.module.CountDownTime
      self.JinduProgressBar:SetPercent(percent)
      if true == self.module.ShowBtnTime then
        local text = string.format(LuaText.umg_teambattle_preparation_1, math.ceil(self.module.LeftTime))
        self.PopUp4:SetBtnLeftText(text)
      end
    end
    if self.module.LeftTime <= 0 then
    end
  end
end

function UMG_TeamBattle_Preparation_C:OnCancelBtnClicked()
  self.module:ClearFusionInfo()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
    local title = _G.DataConfigManager:GetLocalizationConf("teambattlemodule_6").msg
    local des = _G.DataConfigManager:GetLocalizationConf("legendary_battle_tips_10").msg
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.ConfirmCancelPopup):SetButtonText(_G.DataConfigManager:GetLocalizationConf("teambattlemodule_8").msg, _G.DataConfigManager:GetLocalizationConf("teambattlemodule_7").msg):SetCloseOnCancel(true)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    self:ConfirmCancelPopup(true)
  end
end

function UMG_TeamBattle_Preparation_C:OnPcClose()
  self:OnCancelBtnClicked()
end

function UMG_TeamBattle_Preparation_C:ConfirmCancelPopup(bCancel)
  if not self then
    return
  end
  if bCancel then
    self:LoadAnimation(1)
    _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_TeamBattle_Preparation_C:OnCancelBtnClicked")
    if self.challengeType ~= _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
      self.module:OnZoneTeamBattleCancelReq()
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, true, "OpenTeamBattlePreWarInfo")
    else
      if 1 == self.uiData then
        _G.NRCModeManager:DoCmd(_G.TeamBattleModuleCmd.OpenTeamBattleStartConfirmTips, true)
      end
      self.module:OnZoneTeamBattleCancelReq()
    end
  else
    self:LoadAnimation(0)
    if self.PopUp4 and UE4.UObject.IsValid(self.PopUp4) then
      self.PopUp4:SetLock(false)
    end
  end
end

function UMG_TeamBattle_Preparation_C:OnConfirmBtnClicked()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    local SceneNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.data.TargetNPCActorId)
    if SceneNpc then
      local _, FlowerTypeWrap = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetNpcFlowerInfo, SceneNpc.serverData.npc_base.npc_content_cfg_id)
      if FlowerTypeWrap and FlowerTypeWrap.Is7StarHardFlower then
        local medal_id, bGet = self.data:GetHardSeedMedalData()
        if not bGet then
          local MedalList, _ = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.prepareInfoList[1].petGid)
          if MedalList then
            for _, v in ipairs(MedalList) do
              if v.conf_id == medal_id then
                local Context = DialogContext()
                Context:SetTitle(LuaText.TIPS):SetContent(string.format(LuaText.Activity_FlowerHard_Confirm, _G.DataConfigManager:GetMedalConf(medal_id).name)):SetContentTextJustify(UE4.ETextJustify.Center):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.umg_teambattle_preparation_2, LuaText.CANCEL):SetCloseOnOK(true):SetCallbackOkOnly(self, self.StartBattle)
                _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
                return
              end
            end
          end
        end
      end
    end
  end
  self:StartBattle()
end

function UMG_TeamBattle_Preparation_C:StartBattle()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_TeamBattle_Preparation_C:OnConfirmBtnClicked")
  self:ChangeSelectedPet()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    self.module:OnZoneTeamBattleStartReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE)
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    self.module:OnZoneTeamBattleStartReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE)
  else
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if bOwner then
      if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM then
        self.module:OnZoneTeamBattleStartReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM)
      elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
        self.module:OnZoneTeamBattleStartReq(self.data:GetCurNPCActorId(), self.data.TargetNPCLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST)
      end
    else
      local myUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
      local myPrepareInfo = self.data:GetTeamMateInfoByUin(myUin)
      if myPrepareInfo and myPrepareInfo.prepare_state == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
        self.module:OnZoneTeamBattlePrepareReq(false)
      else
        local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        if localPlayer then
          local rideComp = localPlayer.viewObj.BP_RideComponent
          if rideComp then
            rideComp:TryChangeToLink()
          end
        end
        self.module:OnZoneTeamBattlePrepareReq(true)
      end
    end
  end
end

function UMG_TeamBattle_Preparation_C:ChangeSelectedPet(bSendReq)
  _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.SetSelectedBattlePetInfo, nil, nil, nil)
  local teamIndex, petIndex = self:GetChooseTeamIndexAndPetIndex()
  if teamIndex and petIndex and self.data and self.data.ChangePetPanelChoosePet and self.data.ChangePetPanelChoosePet.gid then
    local gid = self.data.ChangePetPanelChoosePet.gid
    if gid then
      _G.NRCModuleManager:DoCmd(TeamBattleModuleCmd.SetSelectedBattlePetInfo, teamIndex, petIndex, gid)
      if bSendReq then
        self.module:OnZoneTeamBattleUpdatePetReq(gid, teamIndex)
      end
    end
  end
end

function UMG_TeamBattle_Preparation_C:GetChooseTeamIndexAndPetIndex()
  local PetTeams = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfoByTeamType(Enum.PlayerTeamType.PTT_BIG_WORLD)
  if PetTeams and PetTeams.teams then
    for i, team in pairs(PetTeams.teams or {}) do
      for j, pet in pairs(team.pet_infos or {}) do
        if pet.pet_gid == self.data.curChoosePet then
          return i - 1, j
        end
      end
    end
  end
  return -1, -1
end

function UMG_TeamBattle_Preparation_C:InitPanelInfo(data)
  Log.Dump(data, 4, "UMG_TeamBattle_Preparation_C:InitPanelInfo")
  self:UpdateHealth()
  local prepareInfoList = {}
  local curBattleBaseId
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    curBattleBaseId = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetBattlePetBaseId)
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    curBattleBaseId = self.module:GetOwnerSelectTeamBattlePetBaseId()
  end
  for i = 1, 4 do
    table.insert(prepareInfoList, {
      bPreparation = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_NONE,
      playerInfo = nil,
      petBaseConfId = 0,
      petLv = 0,
      petGid = 0,
      glass_info = nil,
      curBattleBaseId = curBattleBaseId
    })
  end
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    local gid = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedPetGid)
    if gid <= 0 then
      local teamPetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
      for i = 1, #teamPetInfo do
        local hpCur = PetUtils.GetPetAdditionalByType(teamPetInfo[i], _G.ProtoEnum.AttributeType.AT_HPCUR)
        if hpCur > 0 then
          gid = teamPetInfo[i].gid
          break
        end
      end
    end
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
    if not petData then
      Log.Error("UMG_TeamBattle_Preparation_C:InitPanelInfo has not petData!!!")
      return
    end
    prepareInfoList[1].petBaseConfId = petData.base_conf_id
    prepareInfoList[1].petLv = petData.level
    prepareInfoList[1].petGid = petData.gid
    prepareInfoList[1].playerInfo = {}
    prepareInfoList[1].playerInfo.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    prepareInfoList[1].mutation_type = petData.mutation_type
    prepareInfoList[1].glass_info = petData.glass_info
    self.module:OnCmdSetCurChoosePet(petData.gid)
    _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SetChangePetPanelChoosePet, petData)
    local TeamMateInfoList = self.data.TeamMateInfoList
    for i = 1, 4 do
      prepareInfoList[i].bPreparation = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK
      if TeamMateInfoList and TeamMateInfoList.NPCHelperNum and i <= TeamMateInfoList.NPCHelperNum + 1 and i > 1 then
        local indexInNPCHelper = i - 1
        prepareInfoList[i].helperNPC = true
        prepareInfoList[i].pet_cfg_id = TeamMateInfoList.NPCHelper[indexInNPCHelper].pet_cfg_id
        prepareInfoList[i].npc_id = TeamMateInfoList.NPCHelper[indexInNPCHelper].npc_id
        prepareInfoList[i].petLv = TeamMateInfoList.NPCHelper[indexInNPCHelper].pet_lv
        prepareInfoList[i].bPreparation = TeamMateInfoList.NPCHelper[indexInNPCHelper].prepare_state
        prepareInfoList[i].glass_info = TeamMateInfoList.NPCHelper[indexInNPCHelper].glass_info
      end
    end
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:ChangeSelectedPet(true)
  else
    local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
    local TeamMateInfoList = self.data.TeamMateInfoList
    if visitorList and #visitorList > 0 then
      for i = 1, 4 do
        if prepareInfoList[i].playerInfo == nil then
          prepareInfoList[i].playerInfo = {}
        end
        if i <= #visitorList then
          prepareInfoList[i].playerInfo = visitorList[i]
          if data and data[i] then
            if data[i].pet_cfg_id and data[i].pet_cfg_id > 0 then
              prepareInfoList[i].petBaseConfId = data[i].pet_cfg_id
            end
            prepareInfoList[i].petGid = data[i].pet_gid
            prepareInfoList[i].petLv = data[i].pet_lv
            prepareInfoList[i].bPreparation = data[i].prepare_state
            prepareInfoList[i].mutation_type = data[i].mutation_type
            prepareInfoList[i].glass_info = data[i].glass_info
            if data[i].uin == _G.DataModelMgr.PlayerDataModel:GetPlayerUin() then
              self.module:OnCmdSetCurChoosePet(data[i].pet_gid)
              _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.SetChangePetPanelChoosePet, data[i])
            end
          else
            Log.Error(string.format(LuaText.umg_teambattle_preparation_5, i))
          end
        elseif TeamMateInfoList and TeamMateInfoList.NPCHelperNum and i <= TeamMateInfoList.NPCHelperNum + #visitorList then
          local indexInNPCHelper = i - #visitorList
          prepareInfoList[i].helperNPC = true
          prepareInfoList[i].pet_cfg_id = TeamMateInfoList.NPCHelper[indexInNPCHelper].pet_cfg_id
          prepareInfoList[i].npc_id = TeamMateInfoList.NPCHelper[indexInNPCHelper].npc_id
          prepareInfoList[i].petLv = TeamMateInfoList.NPCHelper[indexInNPCHelper].pet_lv
          prepareInfoList[i].bPreparation = TeamMateInfoList.NPCHelper[indexInNPCHelper].prepare_state
          prepareInfoList[i].glass_info = TeamMateInfoList.NPCHelper[indexInNPCHelper].glass_info
        else
          prepareInfoList[i].bPreparation = _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK
        end
      end
    else
      Log.Error("\228\186\146\232\174\191\230\149\176\230\141\174\230\156\137\232\175\175\239\188\140\232\175\183\230\163\128\230\159\165visitorList\230\149\176\230\141\174")
    end
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if bOwner then
      self:SetConfirmBtnEnable(self.data:AllPrepared())
    end
  end
  Log.Dump(prepareInfoList, 4, "UMG_TeamBattle_Preparation_C:InitPanelInfo11")
  self.Pet_List:InitGridView(prepareInfoList)
  self.prepareInfoList = prepareInfoList
  local rightBtnText = ""
  if prepareInfoList[1].playerInfo == nil then
    Log.Error("prepareInfoList[1].playerInfo is nil")
  end
  if prepareInfoList[1].playerInfo and _G.DataModelMgr.PlayerDataModel:GetPlayerUin() == prepareInfoList[1].playerInfo.uin then
    rightBtnText = LuaText.umg_teambattle_preparation_2
  else
    local teamMateInfoList = self.data:GetTeamMateInfoByUin(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
    local bPre = teamMateInfoList and teamMateInfoList.prepare_state or nil
    if nil ~= bPre and (bPre == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_IDLE or bPre == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_SELECT_PET or bPre == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_NONE) then
      rightBtnText = LuaText.umg_teambattle_preparation_3
    else
      rightBtnText = LuaText.umg_teambattle_preparation_4
    end
  end
  self.PopUp4:SetBtnRightText(rightBtnText)
  self.PopUp4.Btn_Right_GrayState.Title_1:SetText(rightBtnText)
end

function UMG_TeamBattle_Preparation_C:RefreshPanelInfo(data, source, challengeType)
  Log.Dump(data, 4, "UMG_TeamBattle_Preparation_C:RefreshPanelInfo")
  if not data then
    return
  end
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if 0 == tonumber(source) then
    for i = 1, 4 do
      if self.prepareInfoList[i].playerInfo and self.prepareInfoList[i].playerInfo.uin == playerUin then
        self.prepareInfoList[i].petBaseConfId = data.base_conf_id
        self.prepareInfoList[i].petGid = data.gid
        self.prepareInfoList[i].petLv = data.level
        self.prepareInfoList[i].mutation_type = data.mutation_type
        self.prepareInfoList[i].glass_info = data.glass_info
        break
      end
    end
  elseif 1 == tonumber(source) then
    for i = 1, #data do
      for j, v in ipairs(self.prepareInfoList) do
        if v.playerInfo and v.playerInfo.uin == data[i].uin then
          local mateInfo = data[i]
          self.prepareInfoList[i].petBaseConfId = mateInfo.pet_cfg_id
          self.prepareInfoList[i].petLv = mateInfo.pet_lv
          self.prepareInfoList[i].petGid = mateInfo.pet_gid
          self.prepareInfoList[i].bPreparation = mateInfo.prepare_state
          self.prepareInfoList[i].mutation_type = mateInfo.mutation_type
          self.prepareInfoList[i].glass_info = mateInfo.glass_info
        end
      end
    end
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if bOwner and self.prepareInfoList[1].bPreparation == _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
      if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
        self:SetConfirmBtnEnable(true)
      else
        self:SetConfirmBtnEnable(self.data:AllPrepared())
      end
    end
  end
  self.Pet_List:InitGridView(self.prepareInfoList)
  local rightBtnText = ""
  if self.prepareInfoList[1].playerInfo == nil then
    Log.Error("prepareInfoList[1].playerInfo is nil")
  end
  if self.prepareInfoList[1].playerInfo and _G.DataModelMgr.PlayerDataModel:GetPlayerUin() == self.prepareInfoList[1].playerInfo.uin then
    rightBtnText = LuaText.umg_teambattle_preparation_2
  else
    local bPre = self.data:GetTeamMateInfoByUin(_G.DataModelMgr.PlayerDataModel:GetPlayerUin()).prepare_state
    if nil ~= bPre and bPre ~= _G.ProtoEnum.TeamBattleMatePrepareState.TBMPS_OK then
      rightBtnText = LuaText.umg_teambattle_preparation_3
    else
      rightBtnText = LuaText.umg_teambattle_preparation_4
    end
  end
  self.PopUp4:SetBtnRightText(rightBtnText)
  self.PopUp4.Btn_Right_GrayState.Title_1:SetText(rightBtnText)
end

function UMG_TeamBattle_Preparation_C:AddPcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.AddBlockIMC, self, self.depth)
end

function UMG_TeamBattle_Preparation_C:OnEnable()
  self:LoadAnimation(0)
  self.PopUp4:SetLock(false)
end

function UMG_TeamBattle_Preparation_C:RemovePcInputBlock()
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.RemoveBlockIMC, self)
end

function UMG_TeamBattle_Preparation_C:SetConfirmBtnEnable(enable)
  self.PopUp4.Btn_Right:SetClickAble(enable)
  if enable then
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PopUp4.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PopUp4.Btn_Right_GrayState:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_TeamBattle_Preparation_C:OnAnimationFinished(anim)
  if anim == self.Out or anim == self:GetAnimByIndex(1) then
    self:DoClose()
  end
end

return UMG_TeamBattle_Preparation_C
