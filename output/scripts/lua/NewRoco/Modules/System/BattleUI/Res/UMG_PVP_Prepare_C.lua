local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleModuleCmd = require("NewRoco.Modules.Core.Battle.BattleModuleCmd")
local UMG_PVP_Prepare_C = _G.NRCPanelBase:Extend("UMG_PVP_Prepare_C")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")

function UMG_PVP_Prepare_C:OnConstruct()
  _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;PVP_Intro")
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  self.PlayerInfo = PlayerInfo
  self:OnAddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PK_INFO_NOTIFY, self.OnNotifyUpdate)
  self.accumulatedTime = 0
  self.ready = false
  self.enemyThink = true
end

function UMG_PVP_Prepare_C:OnRemoveEventListener()
  _G.BattleEventCenter:UnBind(self)
end

function UMG_PVP_Prepare_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Quit, self.OnQuitBtnClick)
  self:AddButtonListener(self.Btn_Confirm.btnLevelUp, self.OnConfirmBtnClick)
  self:AddButtonListener(self.Btn_CancelReady.btnLevelUp, self.OnCancelBtnClick)
  self:AddButtonListener(self.Btn_Global, self.OnBtnGlobalClicked)
  _G.BattleEventCenter:Bind(self, BattleEvent.EntryHudSkillStartPlayerEvent)
end

function UMG_PVP_Prepare_C:PlayUIStartAnimation()
  self:PlayAnimation(self.In)
  _G.NRCAudioManager:PlaySound2DAuto(40100014, "UMG_PVP_Prepare_C:PlayUIStartAnimation")
end

function UMG_PVP_Prepare_C:OnActive(arg)
  NRCModuleManager:DoCmd(BattleUIModuleCmd.AddDontDisablePanelToList, "PVP_Prepare")
  if not arg then
    if _G.GlobalConfig.DebugOpenUI then
      self.ReflectOn_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ReflectOn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_PvPPrepareImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:PlayUIStartAnimation()
    end
    return
  end
  self.IsClose = false
  self.FirstSelect = true
  self.isInitPlayer = false
  local PlayerPkInfo = arg.pk_info
  self.self_state = PlayerPkInfo.self_state
  self.enemy = PlayerPkInfo.enemy
  self.npc_enemy = PlayerPkInfo.npc_enemy
  self.PKPetDataList = PlayerPkInfo.pets
  self.PKEnemyPetDataList = PlayerPkInfo.enemy_pets or {}
  if not self.PKPetDataList then
    return
  end
  self.first_pet_gid = PlayerPkInfo.first_pet_gid
  self.self_cancel = PlayerPkInfo.self_cancel
  self.enemy_cancel = PlayerPkInfo.enemy_cancel
  self.self_hp = PlayerPkInfo.self_hp or 4
  self.enemy_hp = PlayerPkInfo.enemy_hp or 4
  self.enemy_fashion = PlayerPkInfo.enemy_fashion
  self.start_time = PlayerPkInfo.start_time
  self.pvp_id = PlayerPkInfo.pvp_id
  self.enemyPvpRankStar = PlayerPkInfo.enemy_pvp_rank_star
  self.enemyPvpRankOrder = PlayerPkInfo.enemy_pvp_rank_order
  self.end_time = PlayerPkInfo.end_time or _G.ZoneServer:GetServerTime() / 1000 + 20
  self.countdown = self.end_time - _G.ZoneServer:GetServerTime() / 1000
  local curSeasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  self.curSeasonId = curSeasonId
  self:UpdateUI()
  self.BackgroundBlur_49:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_PvPPrepareImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PrepareLoadOther()
  self:PlayUIStartAnimation()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.SetPvpPlayerPkInfoStartTime, self.start_time)
  UE4Helper.SetDesiredShowCursor(true, "UMG_PVP_Prepare_C")
  BattleResourceManager:PreloadPvpAssetOutsideBattle()
  self:TryStartBattleProfiler()
end

function UMG_PVP_Prepare_C:OnBattleEvent(eventName, ...)
  if eventName == BattleEvent.EntryHudSkillStartPlayerEvent then
    self:DoClose()
  end
end

function UMG_PVP_Prepare_C:FakeData()
end

function UMG_PVP_Prepare_C:OnDeactive()
  self:OnRemoveEventListener()
  self:ClosePetConfirm3()
  _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.CloseNounInterpretationTipsPanel)
  self.IsClose = true
  self.UMG_PvPPrepareImage:ClearWorld()
  self.UMG_PvPPrepareImage:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:ClearLoad()
  UE4Helper.ReleaseDesiredShowCursor("UMG_PVP_Prepare_C")
end

function UMG_PVP_Prepare_C:OnDestruct()
  _G.NRCAudioManager:BatchSetState("UI_Music;None")
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_PK_INFO_NOTIFY, self.OnNotifyUpdate)
end

function UMG_PVP_Prepare_C:UpdateUI()
  self:UpdatePlayerInfo()
  self:updatePetList(self.PKPetDataList)
  self:updateEnemyPetList()
  self:UpdatePvpRankInfo()
end

function UMG_PVP_Prepare_C:TryStartBattleProfiler()
  if self.pvp_id == 1001 then
  elseif self.pvp_id == 2001 then
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.PVPFateDuel)
  elseif self.pvp_id == 3001 then
  elseif self.pvp_id == 4001 then
  elseif self.pvp_id == 5001 then
  elseif self.pvp_id == 6001 then
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.PVPSpeedDuel)
  end
end

function UMG_PVP_Prepare_C:PreBattleIsPvpRank()
  local pvpQualifierMatchPvpConfIdList = {}
  for _, battleType in pairs(BattleConst.PvpQualifierOpenRankCheckValueToBattleType) do
    local battlePvpConf = _G.NRCModuleManager:DoCmd(BattleModuleCmd.GetPvpConfByBattleType, battleType)
    local matchPvpId = battlePvpConf and battlePvpConf.id
    table.insert(pvpQualifierMatchPvpConfIdList, matchPvpId)
  end
  local currentMatchPvpId = self.pvp_id
  local isPvpRankBattleType = table.contains(pvpQualifierMatchPvpConfIdList, currentMatchPvpId)
  return isPvpRankBattleType
end

function UMG_PVP_Prepare_C:UpdatePvpRankInfo()
  if self:PreBattleIsPvpRank() then
    local RankStar = self.enemyPvpRankStar
    local enemyRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(RankStar)
    local playerRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
    local playerRankOrder = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_PVP_RANK_ORDER)
    if not enemyRankConf then
      Log.Error("UMG_PVP_Prepare_C enemyRankConf is nil RankStar=", RankStar)
      return
    end
    local curSeasonId = self.curSeasonId
    self.ClassIcon_1:SetRankInfo(enemyRankConf, self.enemyPvpRankOrder, curSeasonId)
    self.ClassIcon:SetRankInfo(playerRankConf, playerRankOrder, curSeasonId)
    self.ClassIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ClassIcon_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn_Quit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ClassIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ClassIcon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Quit:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PVP_Prepare_C:UpdatePlayerInfo()
  local hpData = {}
  for i = 1, self.self_hp do
    table.insert(hpData, {index = i})
  end
  self.HPList:InitGridView(hpData)
  local enemyHpData = {}
  for i = 1, self.enemy_hp do
    table.insert(enemyHpData, {index = i})
  end
  self.HPList_1:InitGridView(enemyHpData)
  self.PlayerName:SetText(self.PlayerInfo.name)
  self.EnemyName:SetText(self.enemy.name or self.npc_enemy.name)
  local playerCardInfo = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo()
  if playerCardInfo and playerCardInfo.card_appearance_info then
    local playerCardID = _G.DataModelMgr.PlayerDataModel:GetCardBriefInfo().card_appearance_info.card_skin_selected
    self.GradeLeft:Init(playerCardID)
    local PlayerCardSkinConf = _G.DataConfigManager:GetCardSkinConf(playerCardID)
    if PlayerCardSkinConf then
      self.BusinessCard:SetPath(string.format(UEPath.CARD_PVP_PATH, PlayerCardSkinConf.skin_resource_path, PlayerCardSkinConf.skin_resource_path))
      if PlayerCardSkinConf.level_icon and PlayerCardSkinConf.level_icon ~= "" then
        self:PlayAnimation(self.shine_loop_L)
      else
        self:PlayAnimation(self.shine_no_L)
      end
    end
  end
  if self.enemy.additional_data.card_brief_info and self.enemy.additional_data.card_brief_info.card_appearance_info then
    local enemyCardID = self.enemy.additional_data.card_brief_info.card_appearance_info.card_skin_selected
    local EnemyCardSkinConf = _G.DataConfigManager:GetCardSkinConf(enemyCardID)
    self.GradeRight:Init(enemyCardID)
    if EnemyCardSkinConf then
      self.BusinessCard_1:SetPath(string.format(UEPath.CARD_PVP_PATH, EnemyCardSkinConf.skin_resource_path, EnemyCardSkinConf.skin_resource_path))
      if EnemyCardSkinConf.level_icon and EnemyCardSkinConf.level_icon ~= "" then
        self:PlayAnimation(self.shine_loop_R)
      else
        self:PlayAnimation(self.shine_no_R)
      end
    else
      self.BusinessCard_1:SetPath("Texture2D'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Textures/BusinessCardBg/img_Bg002_pvp.img_Bg002_pvp'")
    end
  else
    self.BusinessCard_1:SetPath("Texture2D'/Game/NewRoco/Modules/System/Friend/Raw/BusinessCard/Textures/BusinessCardBg/img_Bg002_pvp.img_Bg002_pvp'")
  end
end

function UMG_PVP_Prepare_C:OnTick(DeltaTime)
  if self.end_time then
    self.countdown = self.end_time - _G.ZoneServer:GetServerTime() / 1000
  else
    if _G.GlobalConfig.DebugOpenUI then
      return
    end
    Log.Error("end time \232\142\171\229\144\141\229\133\182\229\166\153\231\188\186\229\164\177\239\188\140\232\175\183\232\129\148\231\179\187jobhuang\229\146\140dsxu")
    if not self.countdown then
      self.countdown = 20
    end
  end
  self.accumulatedTime = self.accumulatedTime + DeltaTime
  if self.accumulatedTime > 1 then
    self:PlayAnimation(self.Countdown_Loop)
    if self.accumulatedTime == nil then
      self.accumulatedTime = 0
    end
    self.accumulatedTime = self.accumulatedTime % 1
  end
  if self.countdown > 0 then
    local minutes = math.floor(self.countdown / 60)
    local seconds = math.floor(self.countdown % 60)
    local timeString = string.format("%01d:%02d", minutes, seconds)
    self.Text_CountDown:SetText(timeString)
  else
    if self.countdownEnd then
      return
    end
    self.Text_CountDown:SetText("0:00")
    self.countdownEnd = true
    if nil == self.ready or self.ready == false then
      self.Battle_ChangePetConfirm:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:OnConfirmBtnClick(true)
    end
  end
end

function UMG_PVP_Prepare_C:updatePetList(PKPetDataList)
  self.petList:InitGridView(self.PKPetDataList)
  self.petList:SelectItemByIndex(0)
  self:SetSelectPet(1, true)
end

function UMG_PVP_Prepare_C:updateEnemyPetList()
  if self.PKEnemyPetDataList and #self.PKEnemyPetDataList > 0 then
    for i, v in pairs(self.PKEnemyPetDataList) do
      v.base_conf_id = v.petbase_id
      v.last_breakthrough_lv = v.last_breakthrough_lv or 0
    end
    self.PetList_right:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetList_right:InitGridView(self.PKEnemyPetDataList)
  else
    self.PetList_right:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVP_Prepare_C:OnQuitBtnClick()
  if _G.GlobalConfig.DebugOpenUI then
    self:Quit()
    return
  end
  self:OpenQuitDialog()
end

function UMG_PVP_Prepare_C:OpenQuitDialog()
  self.QuitDialog = DialogContext()
  self.QuitDialog:SetCallback(self, self.OnDialogCallback)
  self.QuitDialog:SetContent(LuaText.pvp_firstpet_choose_exit_desc)
  self.QuitDialog:SetMode(DialogContext.Mode.OK_CANCEL)
  self.QuitDialog:SetTitle(LuaText.pvp_firstpet_choose_exit_title)
  self.QuitDialog:SetButtonText(LuaText.YES, LuaText.NO)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, self.QuitDialog)
end

function UMG_PVP_Prepare_C:OnDialogCallback(result)
  if result then
    _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_PVP_Prepare_C:ClickYes")
    self:Quit()
  else
    _G.NRCAudioManager:PlaySound2DAuto(1006, "UMG_PVP_Prepare_C:ClickNo")
  end
end

function UMG_PVP_Prepare_C:Quit()
  NRCModuleManager:DoCmd(BattleUIModuleCmd.SendZonePkExitReq)
  self:CancelPKClosePanel()
end

function UMG_PVP_Prepare_C:OpenPVPCuttoCallBack()
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.ShowNpcRankedMatchUiAction)
  self:OnClose()
end

function UMG_PVP_Prepare_C:CancelPKClosePanel(enemyCancel)
  _G.NRCModeManager:DoCmd(_G.BattleUIModuleCmd.CloseBattlePvpState)
  if enemyCancel and self:PreBattleIsPvpRank() then
    _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.OpenPVPCutto, "UMG_PVP_Prepare_C", self, self.OpenPVPCuttoCallBack, true, true)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
    self:OnClose()
  end
end

function UMG_PVP_Prepare_C:OnConfirmBtnClick(IsCountDownFinished)
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_PVP_Prepare_C:OnConfirmBtnClick")
  if self.ready == true then
    return
  end
  if not IsCountDownFinished then
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.PVPRankClickPrepareConfirm)
  end
  self.ready = true
  self:StopAnimation(self.Cancel)
  self:PlayAnimation(self.ConfirmedFirstRelease)
  self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.CancelReadyCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ReflectOn:StopAllAnimations()
  self.ReflectOn:PlayAnimation(self.ReflectOn.Out)
  self.petListSelectedIndexWhenConfirmed = self.petList:GetSelectedIndex()
  self.petList:ClearSelection()
  self.petList:SetItemClickAble(false)
  self.PetList_right:ClearSelection()
  self.PetList_right:SetItemClickAble(false)
  if not IsCountDownFinished then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.SendZonePkSelectPetReq, self.selectPetGid)
  end
end

function UMG_PVP_Prepare_C:OnCancelBtnClick()
  if self.bothReady == true then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self.ready = false
  self:StopAnimation(self.ConfirmedFirstRelease)
  self:StopAnimation(self.ConfirmedFirstRelease_Loop)
  self:PlayAnimation(self.Cancel)
  self.CancelReadyCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.BtnSwitcher:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ReflectOn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ReflectOn:StopAllAnimations()
  self.ReflectOn:PlayAnimation(self.ReflectOn.In)
  self.petList:SetItemClickAble(true)
  if self.petListSelectedIndexWhenConfirmed then
    self.petList:SelectItemByIndex(self.petListSelectedIndexWhenConfirmed)
    self.petListSelectedIndexWhenConfirmed = nil
  end
  NRCModuleManager:DoCmd(BattleUIModuleCmd.SendZonePkCancelPrepareReq)
end

function UMG_PVP_Prepare_C:OnAnimationStarted(Animation)
  if Animation == self.In then
    NRCModeManager:DoCmd(BattleUIModuleCmd.ClosePVPMatchPanel)
    self:DelaySeconds(1.33, self.HPItemPlayAnimationIn, self)
    self:DelaySeconds(1.72, self.PetItemPlayAnimationIn, self)
  elseif Animation == self.Out then
    self:PetItemPlayAnimationOut()
  end
end

function UMG_PVP_Prepare_C:OnAnimationFinished(Animation)
  if Animation == self.ConfirmedFirstRelease and self.ready == true then
    self:PlayAnimation(self.ConfirmedFirstRelease_Loop, nil, 999999)
  end
end

function UMG_PVP_Prepare_C:SetSelectPet(index, selected)
  if self.FirstSelect then
    self.FirstSelect = false
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(40001001, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
  end
  if selected then
    self.selectIndex = index
    self.selectPetGid = self.PKPetDataList[index].pet_data.gid
  end
  self.selectPetData = self.PKPetDataList[index].pet_data
  if self.PKPetDataList[index].base_conf_id and 0 ~= self.PKPetDataList[index].base_conf_id then
    self.selectPetData.finalEvoPetID = self.PKPetDataList[index].base_conf_id
  end
end

function UMG_PVP_Prepare_C:OpenPetInfoTips(index, isRight)
  self:ShowPetInfoTips(true, false, index, isRight)
end

function UMG_PVP_Prepare_C:ShowPetInfoTips(bShow, bNotPlaySound, index, isRight)
  local _, err, _ = tcall(self, self.NewShowPetInfoTips, bShow, bNotPlaySound, index, isRight)
  if err then
    Log.Error(err)
    if not _G.RocoEnv.IS_EDITOR then
      _G.NRCSDKManager:CrashSightReportExceptionWithReason("UMG_PVP_Prepare_C:ShowPetInfoTips", "Lua,ShowPetInfoTips,Exception", err)
    end
  end
end

function UMG_PVP_Prepare_C:NewShowPetInfoTips(bShow, bNotPlaySound, index, isRight)
  if bShow then
    if not bNotPlaySound then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1083, "UMG_PVP_Prepare_C:ShowRightTips Show")
    end
    local petData = self.selectPetData
    local adjusted = false
    if index then
      if isRight then
        if index > 0 and self.PKEnemyPetDataList and index <= #self.PKEnemyPetDataList then
          petData = self.PKEnemyPetDataList[index]
          adjusted = false
        end
      elseif index > 0 and index <= #self.PKPetDataList then
        petData = self.PKPetDataList[index].pet_data
        adjusted = self.PKPetDataList[index].adjusted
      end
    elseif self.PKPetDataList and self.PKPetDataList[self.selectIndex] then
      adjusted = self.PKPetDataList[self.selectIndex].adjusted
    end
    if petData then
      if isRight then
        self.IsOpenPetConfirm3 = true
        NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm3, petData, true)
      else
        self.Battle_ChangePetConfirm:SetPetInfo(petData, nil, adjusted)
        self.Battle_ChangePetConfirm:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Battle_ChangePetConfirm.Bg_pvp:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  else
    if not bNotPlaySound then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1076, "UMG_PVP_Prepare_C:ShowRightTips UnShow")
    end
    self.Battle_ChangePetConfirm:Hide(true, false)
    self:ClosePetConfirm3()
  end
end

function UMG_PVP_Prepare_C:ClosePetConfirm3()
  if self.IsOpenPetConfirm3 then
    self.IsOpenPetConfirm3 = false
    NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseChangePetConfirm3)
  end
end

function UMG_PVP_Prepare_C:OnBtnGlobalClicked()
  self:ShowPetInfoTips(false)
end

function UMG_PVP_Prepare_C:OnNotifyUpdate(arg)
  local PlayerPkInfo = arg.pk_info
  self.self_state = PlayerPkInfo.self_state
  self.enemy = PlayerPkInfo.enemy
  self.npc_enemy = PlayerPkInfo.npc_enemy
  self.enemy_state = PlayerPkInfo.enemy_state
  self.PKPetDataList = PlayerPkInfo.pets
  self.first_pet_gid = PlayerPkInfo.first_pet_gid
  self.self_cancel = PlayerPkInfo.self_cancel
  self.enemy_cancel = PlayerPkInfo.enemy_cancel
  if self.self_state == ProtoEnum.PlayerPkState.PPS_NONE then
    if self.enemy_cancel then
      self:CancelPKClosePanel(true)
    else
      self:CancelPKClosePanel(false)
    end
  end
  if self.self_state == ProtoEnum.PlayerPkState.PPS_READY then
  end
  if self.enemy_state == ProtoEnum.PlayerPkState.PPS_READY then
    self.enemyThink = false
    if self.PlayCharaAnimFinish == true then
      self.ReflectOn_1:StopAnimation(self.ReflectOn_1.Loop)
      self.ReflectOn_1:StopAnimation(self.ReflectOn_1.HeidianLoop)
      self.ReflectOn_1:PlayAnimation(self.ReflectOn_1.Out)
    end
  end
  if self.self_state == ProtoEnum.PlayerPkState.PPS_THINKING then
  end
  if self.enemy_state == ProtoEnum.PlayerPkState.PPS_THINKING and self.PlayCharaAnimFinish == true and (self.enemyThink == nil or self.enemyThink == false) then
    self.enemyThink = true
    self.ReflectOn_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ReflectOn_1:PlayAnimation(self.ReflectOn_1.In)
  end
  if self.enemy_cancel then
    self:CancelPKClosePanel(true)
  end
  if self.self_state == ProtoEnum.PlayerPkState.PPS_READY and self.enemy_state == ProtoEnum.PlayerPkState.PPS_READY then
    self:BothGetReady()
  end
end

function UMG_PVP_Prepare_C:BothGetReady()
  self.bothReady = true
  self.ReflectOn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ReflectOn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CountDownPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CancelReadyCanvas:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_CloseDialog)
  self.BackgroundBlur_49:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UMG_PvPPrepareImage:CameraClose()
  self:StopAnimation(self.ConfirmedFirstRelease)
  self:StopAnimation(self.ConfirmedFirstRelease_Loop)
  self:PlayAnimation(self.Out)
  self:SetPanelReadyToClosed()
end

function UMG_PVP_Prepare_C:PrepareLoadOther()
  self.Requests = {}
  self.LoadedAssets = {}
  local loadList = {}
  loadList[1] = BattleConst.PVPPrepareEnter
  if self.PlayerInfo then
    loadList[2] = self:GetPlayerModelPath(self.PlayerInfo.sex)
    if self.enemy and self.enemy.sex and self.PlayerInfo.sex ~= self.enemy.sex then
      loadList[3] = self:GetPlayerModelPath(self.enemy.sex)
    elseif self.npc_enemy and self.npc_enemy.sex and self.PlayerInfo.sex ~= self.npc_enemy.sex then
      loadList[3] = self:GetPlayerModelPath(self.npc_enemy.sex)
    end
  end
  for Name, Path in pairs(loadList) do
    self.Requests[Name] = _G.NRCResourceManager:LoadResAsync(self, Path, 0, 0, self.OnLoadSuccess, self.OnLoadFailed)
  end
end

function UMG_PVP_Prepare_C:OnLoadSuccess(Request, Res)
  local Path = Request.assetPath
  self.LoadedAssets[Path] = Res
  self:CheckFinish()
end

function UMG_PVP_Prepare_C:OnLoadFailed(Request, Message)
  Log.Warning("\233\162\132\229\138\160\232\189\189\232\181\132\230\186\144\229\164\177\232\180\165", Message)
  _G.NRCResourceManager:UnLoadRes(Request)
  self.Requests[Request.assetPath] = nil
  self:CheckFinish()
end

function UMG_PVP_Prepare_C:ClearLoad()
  for _, v in pairs(self.Requests or {}) do
    _G.NRCResourceManager:UnLoadRes(v)
  end
  self.Requests = nil
  self.LoadedAssets = nil
  self.teamPlayerForRevert = nil
  self.enemyPlayerForRevert = nil
end

function UMG_PVP_Prepare_C:CheckFinish()
  local TotalCount = table.len(self.Requests)
  local CurrentCount = table.len(self.LoadedAssets)
  local Done = TotalCount <= CurrentCount
  if Done then
    self:LoadPlayer(true)
  end
end

function UMG_PVP_Prepare_C:SetPlayerVisibility(player, isVisible)
  if player then
    player:SetActorHiddenInGame(not isVisible)
    local AvatarComponent = player:GetComponentByClass(UE4.UAvatarComponent)
    if AvatarComponent then
      local AActorS = AvatarComponent:GetDecorators()
      for i, Actor in ipairs(AActorS:ToTable()) do
        Actor:SetActorHiddenInGame(not isVisible)
      end
    end
  end
end

function UMG_PVP_Prepare_C:LoadPlayer(isInit)
  if self.IsClose or not self.isInitPlayer and not isInit then
    return
  end
  self.isInitPlayer = true
  local teamPlayer, enemyPlayer
  self.isLeftAvatarReady = true
  self.isRightAvatarReady = true
  if self.PlayerInfo and not self.UMG_PvPPrepareImage.teamModel then
    teamPlayer = self:PawnPlayerInWorldView(self.PlayerInfo.sex)
    if teamPlayer then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player then
        local fashionIds = player:GetFashionItems()
        local salonIds = player:GetSalonIds()
        self.isLeftAvatarReady = false
        teamPlayer:SetDefaultSuit(teamPlayer.Mesh, self.PlayerInfo.sex, fashionIds, salonIds, self.LeftAvatarOver, self)
      else
        Log.Error("UMG_PVP_Prepare_C:LoadPlayer player is nil!!!")
      end
      self.UMG_PvPPrepareImage:SetTeam(teamPlayer)
      if teamPlayer.AnimConfig and teamPlayer.RocoAnim then
        teamPlayer.RocoAnim:SetAnimConfig(teamPlayer.AnimConfig)
      else
        Log.Error("zgx teamPlayer no RocoAnim!!!")
      end
      self:SetPlayerVisibility(teamPlayer, false)
    end
  end
  if self.enemy or self.npc_enemy then
    if self.UMG_PvPPrepareImage.enemyModel then
      self.UMG_PvPPrepareImage.previewWorld:DestroyActor(self.UMG_PvPPrepareImage.enemyModel)
      self.UMG_PvPPrepareImage:SetEnemy(nil)
    end
    if self.enemy and self.enemy.sex then
      enemyPlayer = self:PawnPlayerInWorldView(self.enemy.sex)
      if enemyPlayer and self.enemy_fashion then
        local wearing_item = self.enemy_fashion.wearing_item or self.enemy_fashion.fashion_id
        local salonIds = self.enemy_fashion.salon_item_data
        self.isRightAvatarReady = false
        enemyPlayer:SetDefaultSuit(enemyPlayer.Mesh, self.enemy.sex, wearing_item, salonIds, self.RightAvatarOver, self)
      end
    elseif self.npc_enemy and self.npc_enemy.sex then
      enemyPlayer = self:PawnPlayerInWorldView(self.npc_enemy.sex)
      if enemyPlayer and (self.npc_enemy.wearing_item or self.npc_enemy.fashion) then
        local wearing_item = self.npc_enemy.wearing_item or self.npc_enemy.fashion
        self.isRightAvatarReady = false
        enemyPlayer:SetDefaultSuit(enemyPlayer.Mesh, self.npc_enemy.sex, wearing_item, nil, self.RightAvatarOver, self)
      end
    end
    if enemyPlayer then
      self.UMG_PvPPrepareImage:SetEnemy(enemyPlayer)
      if not isInit then
        self.UMG_PvPPrepareImage:AddPetToScene(self.UMG_PvPPrepareImage.enemySlotActor, self.UMG_PvPPrepareImage.enemyModel)
      end
      if enemyPlayer.AnimConfig and enemyPlayer.RocoAnim then
        enemyPlayer.RocoAnim:SetAnimConfig(enemyPlayer.AnimConfig)
      else
        Log.Error("zgx teamPlayer no RocoAnim!!!")
      end
      self:SetPlayerVisibility(enemyPlayer, false)
    end
  end
  if isInit then
    self.UMG_PvPPrepareImage:SetTeamData()
  end
  self.isWaitingPlayAnimDelay = true
  self:DelaySeconds(1, function()
    self.isWaitingPlayAnimDelay = false
    self:CheckBothSideAvatarLoaded()
  end)
  self.teamPlayerForRevert = teamPlayer
  self.enemyPlayerForRevert = enemyPlayer
  self:CheckBothSideAvatarLoaded()
end

function UMG_PVP_Prepare_C:StartRevertPlayerPos()
  local teamPlayer = self.teamPlayerForRevert
  local enemyPlayer = self.enemyPlayerForRevert
  if self.isInitPlayer then
    if enemyPlayer then
      local enemyStartPos = enemyPlayer:K2_GetActorLocation()
      local pos = UE.FVector(enemyStartPos.X, enemyStartPos.Y + 300, enemyStartPos.Z)
      enemyPlayer:SetActorLocation(pos)
      self:RevertPlayerPos(enemyPlayer, "PVPEntryR", enemyStartPos)
    end
    if teamPlayer then
      local playerStartPos = teamPlayer:K2_GetActorLocation()
      local pos = UE.FVector(playerStartPos.X, playerStartPos.Y - 300, playerStartPos.Z)
      teamPlayer:SetActorLocation(pos)
      self:RevertPlayerPos(teamPlayer, "PVPEntryL", playerStartPos)
    end
    self:PlayEntryAnim()
  end
end

function UMG_PVP_Prepare_C:LeftAvatarOver()
  self.UMG_PvPPrepareImage:AddPlayerAvatar(self.UMG_PvPPrepareImage.teamModel)
  self.isLeftAvatarReady = true
  self:CheckBothSideAvatarLoaded()
end

function UMG_PVP_Prepare_C:RightAvatarOver()
  self.UMG_PvPPrepareImage:AddPlayerAvatar(self.UMG_PvPPrepareImage.enemyModel)
  self.isRightAvatarReady = true
  self:CheckBothSideAvatarLoaded()
end

function UMG_PVP_Prepare_C:CheckBothSideAvatarLoaded()
  if self.isLeftAvatarReady and self.isRightAvatarReady and not self.isWaitingPlayAnimDelay then
    self:StartRevertPlayerPos()
  end
end

function UMG_PVP_Prepare_C:RevertPlayerPos(player, anim, startPos)
  if self.IsClose then
    return
  end
  self:SetPlayerVisibility(player, true)
  self:DelayFrames(2, function()
    if not self.IsClose and startPos and UE4.UObject.IsValid(player) then
      player:SetActorLocation(startPos)
    end
  end)
end

function UMG_PVP_Prepare_C:PlayEntryAnim()
  self.UMG_PvPPrepareImage:SetRenderOpacity(1)
  if self.IsClose then
    return
  end
  self.UMG_PvPPrepareImage:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if self.UMG_PvPPrepareImage.enemyModel and self.UMG_PvPPrepareImage.teamModel then
    local skillClass = self.LoadedAssets[BattleConst.PVPPrepareEnter]
    if skillClass then
      local SkillComponent = self.UMG_PvPPrepareImage.teamModel.RocoSkill
      if SkillComponent then
        SkillComponent:ClearAllPassiveSkillObjs()
        local Skill = SkillComponent:FindOrAddSkillObj(skillClass)
        Skill:SetCaster(self.UMG_PvPPrepareImage.teamModel)
        local character = {}
        character[0] = self.UMG_PvPPrepareImage.teamModel
        character[8] = self.UMG_PvPPrepareImage.enemyModel
        Skill:SetCharacters(character)
        Skill:RegisterEventCallback("ShowLeftPopup", self, function()
          self.PlayCharaAnimFinish = true
          if self.ready == false then
            self.ReflectOn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.ReflectOn:PlayAnimation(self.ReflectOn.In)
          end
        end)
        Skill:RegisterEventCallback("ShowRightPopup", self, function()
          if self.enemyThink == true then
            self.ReflectOn_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.ReflectOn_1:PlayAnimation(self.ReflectOn_1.In)
          end
        end)
        local blackboard = Skill:GetBlackboard()
        if blackboard then
          if self.PlayerInfo then
            if self.PlayerInfo.sex == ProtoEnum.ESexValue.SEX_MALE then
              blackboard:SetValueAsString("LeftBoy", "LeftBoy")
            else
              blackboard:SetValueAsString("LeftGirl", "LeftGirl")
            end
          end
          if self.enemy then
            if self.enemy.sex == ProtoEnum.ESexValue.SEX_MALE then
              blackboard:SetValueAsString("RightBoy", "RightBoy")
            else
              blackboard:SetValueAsString("RightGirl", "RightGirl")
            end
          end
        end
        SkillComponent:PlaySkill(Skill)
      end
    end
  end
end

function UMG_PVP_Prepare_C:GetPlayerModelPath(roleID)
  local modelPath
  local ModelConfID = roleID
  if roleID == ProtoEnum.ESexValue.SEX_FEMALE or roleID == ProtoEnum.ESexValue.SEX_MALE then
    if roleID == ProtoEnum.ESexValue.SEX_MALE then
      ModelConfID = 1010001
    else
      ModelConfID = 1010002
    end
  end
  local modelConfig = _G.DataConfigManager:GetModelConf(ModelConfID)
  if modelConfig then
    modelPath = modelConfig.path
  end
  return modelPath
end

function UMG_PVP_Prepare_C:PawnPlayerInWorldView(roleID)
  local modelClass = self.LoadedAssets[self:GetPlayerModelPath(roleID)]
  if not modelClass then
    Log.ErrorFormat("UMG_PetImage3D_C:SetPath \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", modelPath or "")
    return
  end
  local fTransfom = UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0), UE4.FVector(1, 1, 1))
  local player = self.UMG_PvPPrepareImage.previewWorld:SpawnActor(modelClass, fTransfom)
  return player
end

function UMG_PVP_Prepare_C:HPItemPlayAnimationIn()
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  for i = 1, self.self_hp do
    local item = self.HPList:GetItemByIndex(i - 1)
    self:DelaySeconds(0.066 * (i - 1), function()
      item:SetVisibility(UE.ESlateVisibility.Visible)
      item:PlayAnimation(item.In)
    end, self)
  end
  for i = 1, self.enemy_hp do
    local item = self.HPList_1:GetItemByIndex(i - 1)
    self:DelaySeconds(0.066 * (i - 1), function()
      item:SetVisibility(UE.ESlateVisibility.Visible)
      item:PlayAnimation(item.In)
    end, self)
  end
end

function UMG_PVP_Prepare_C:PetItemPlayAnimationIn()
  if _G.GlobalConfig.DebugOpenUI then
    return
  end
  for i = 1, #self.PKPetDataList do
    local item = self.PetList:GetItemByIndex(i - 1)
    self:DelaySeconds(0.033 * (i - 1), function()
      item:SetVisibility(UE.ESlateVisibility.Visible)
      item:PlayAnimation(item.In)
    end, self)
  end
  if self.PKEnemyPetDataList then
    for i = 1, #self.PKEnemyPetDataList do
      local item = self.PetList_right:GetItemByIndex(i - 1)
      self:DelaySeconds(0.033 * (i - 1), function()
        item:SetVisibility(UE.ESlateVisibility.Visible)
        item:PlayAnimation(item.In)
      end, self)
    end
  end
end

function UMG_PVP_Prepare_C:PetItemPlayAnimationOut()
  for i = 1, #self.PKPetDataList do
    local item = self.PetList:GetItemByIndex(i - 1)
    item:PlayAnimation(item.Out)
  end
  if self.PKEnemyPetDataList then
    for i = 1, #self.PKEnemyPetDataList do
      local item = self.PetList_right:GetItemByIndex(i - 1)
      item:PlayAnimation(item.Out)
    end
  end
end

return UMG_PVP_Prepare_C
