local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local BagModuleEnum = require("NewRoco.Modules.System.Bag.BagModuleEnum")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local UMG_MainPetTempate_C = Base:Extend("UMG_MainPetTempate_C")
local TICK_DELTA_TIME = 0.1

function UMG_MainPetTempate_C:OnConstruct()
  self:AddEventListener()
end

function UMG_MainPetTempate_C:OnDestruct()
  if self.DelaySkillId then
    _G.DelayManager:CancelDelayById(self.DelaySkillId)
    self.DelaySkillId = nil
  end
  if self.DelayPlayId then
    _G.DelayManager:CancelDelayById(self.DelayPlayId)
    self.DelayPlayId = nil
  end
  if self.DelayFinshId then
    _G.DelayManager:CancelDelayById(self.DelayFinshId)
    self.DelayFinshId = nil
  end
  if self.DelayPlayNextSkillTipsId then
    _G.DelayManager:CancelDelayById(self.DelayPlayNextSkillTipsId)
    self.DelayPlayNextSkillTipsId = nil
  end
  if self.DelayPlayNextMedalTipsId then
    _G.DelayManager:CancelDelayById(self.DelayPlayNextMedalTipsId)
    self.DelayPlayNextMedalTipsId = nil
  end
  Log.Debug("UMG_MainPetTempate_C:OnDestruct")
  self:RemoveEventListener()
end

function UMG_MainPetTempate_C:OnQuickChatOpen()
  if self.Text_PCKey then
    self._cachedPCKeyVisible = self.Text_PCKey:GetVisibility() ~= UE4.ESlateVisibility.Collapsed
    self.Text_PCKey:SetKeyVisibility(false)
  end
end

function UMG_MainPetTempate_C:OnQuickChatClose()
  if self.Text_PCKey and self._cachedPCKeyVisible then
    self.Text_PCKey:SetKeyVisibility(true)
  end
end

function UMG_MainPetTempate_C:AddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_MainPetTempate_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPetTempate_C", self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_MainPetTempate_C", self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
end

function UMG_MainPetTempate_C:RemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatOpen, self.OnQuickChatOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.QuickChatClose, self.OnQuickChatClose)
end

function UMG_MainPetTempate_C:OnItemUpdate(_data, _datalist, _index)
  if _data.PetData == "nil" then
    self:SetClickable(false)
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  end
  self.levelUpShowTime = _G.DataConfigManager:GetPetGlobalConfig("level_up_show_time").num / 1000
  self.skillUnlockShowTime = _G.DataConfigManager:GetPetGlobalConfig("skill_unlock_show_time").num / 1000
  self.medalUnlockShowTime = _G.DataConfigManager:GetPetGlobalConfig("medal_unlock_show_time").num / 1000
  self.energyRecoveredShowTime = _G.DataConfigManager:GetPetGlobalConfig("energy_recovered_show_time").num / 1000
  self.PanelLifebar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.levelOrSkillData == nil then
    self.levelOrSkillData = {}
    self.isShowEffect = false
  end
  self.waitAimState = 0
  self.index = _index
  self.IsPlaySkill = false
  self.IsTimer = false
  self.uiData = _data
  self.datalist = _datalist
  self.IsTouchStarted = false
  self.touchStartTime = 0
  self:HideAllState()
  self:UpdateItemInfo()
  if self.uiData.IsScrollPet then
  else
    self:ShowChangeEnergyAnimation()
  end
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.Deviation = {X = 60, Y = 40}
  self.screenPos = nil
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.EndTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self.SkillBtn_1.OnClicked:Add(self, self.OpenSkillPanel)
  self.SkillBtn.OnClicked:Add(self, self.OpenSkillPanel)
  self:PCKeySetting()
  self:CheckLock()
end

function UMG_MainPetTempate_C:UpdateThrowPetCanClick(bThrow)
  self.bThrow = bThrow
  if bThrow and self.clickable and (not self.uiData or not self.uiData.DiedState) then
    local IsRidePet = false
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      local RidePet = player.viewObj.BP_RideComponent.ScenePet
      if RidePet and self.uiData.PetData.gid == RidePet.gid then
        IsRidePet = true
      end
    end
    if IsRidePet then
      self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
    else
      self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
    end
    self:SetClickable(not IsRidePet)
  elseif not bThrow and not self.clickable and not self.uiData.DiedState then
    self:SetClickable(true)
    self:ShowDisabled(false)
  end
end

function UMG_MainPetTempate_C:OpenSkillPanel()
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, self.index)
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  })
end

function UMG_MainPetTempate_C:UpdateDiedState()
  local curHp = PetUtils.GetPetAdditionalByType(self.uiData.PetData, _G.ProtoEnum.AttributeType.AT_HPCUR)
  if curHp <= 0 then
    self.uiData.DiedState = true
    self:ShowDisabled(true)
  else
    self.uiData.DiedState = false
    self:ShowDisabled(false)
    local InWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsInWorldCombat)
    if InWorldCombat then
      local MaxHp = PetUtils.GetPetAdditionalByType(self.uiData.PetData, _G.ProtoEnum.AttributeType.AT_HPMAX)
      if curHp ~= MaxHp then
        self.PanelLifebar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local hpPercent = curHp / MaxHp
        self:SetHPPercent(hpPercent)
      end
    end
  end
  local IsRidePet = false
  if self.bThrow then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      local RidePet = player.viewObj.BP_RideComponent.ScenePet
      if RidePet and self.uiData.PetData.gid == RidePet.gid then
        IsRidePet = true
      end
    end
    if IsRidePet then
      self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
    end
  end
  self:SetClickable(not self.uiData.DiedState and not IsRidePet)
end

function UMG_MainPetTempate_C:UpdateItemInfo()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.uiData.PetData.base_conf_id)
  if petBaseConf then
    self.PetLevel:SetText(self.uiData.PetData.level)
    self.HeadIcon:SetIconPathAndMaterial(self.uiData.PetData.base_conf_id, self.uiData.PetData.mutation_type, self.uiData.PetData.glass_info)
    self:ShowRecycle(self.uiData.RecycleState)
    self:ShowLock(self.uiData.IsLock)
    self.oldRecycle = self.uiData.RecycleState
    self:ShowSelected(self.uiData.SelectedState)
    self:UpdateDiedState()
    self:UpdateFriendRideStateShow()
  end
end

function UMG_MainPetTempate_C:PCKeySetting()
  local index
  if self.uiData and self.uiData.IsScrollPet and self.index > 6 then
    index = self.index % 6
    if 0 == index then
      index = 6
    end
  else
    index = self.index
  end
  self:PCKeyShow(index)
end

function UMG_MainPetTempate_C:ForceUpdatePetRiderState(RidePetGid)
  if not self.uiData or not self.uiData.PetData then
    return
  end
  local IsRidePet = RidePetGid == self.uiData.PetData.gid
  if IsRidePet then
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
  else
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  end
  if not self.uiData or not self.uiData.DiedState then
    if IsRidePet then
      self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
    else
      self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
    end
    self:SetClickable(not IsRidePet)
  end
end

function UMG_MainPetTempate_C:OnItemClicked(selected)
  self:LongPressBreak()
end

function UMG_MainPetTempate_C:OnItemSelected(selected, bScrollChoose, bUserClick)
  if _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetMainPetListVisibility) == UE4.ESlateVisibility.Collapsed then
    return
  end
  if selected then
    if not self.uiData then
      Log.Error("self.uiData is nil")
      return
    end
    local scenePet = _G.DataModelMgr.PlayerDataModel:GetPetByGid(self.uiData.PetData.gid)
    local isAmining = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
    local SelectPetIndex = self.index
    if isAmining and self.uiData.RecycleState == true then
      local tipText = _G.DataConfigManager:GetLocalizationConf("Cannot_Switch").msg
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, tipText)
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainPetRecycleSelect)
      return
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player then
      if not player.statusComponent then
        Log.Warning("cannot found player statusComponent")
        return
      end
      if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
        Log.Warning("select pet, but pending throw magic")
        return
      end
    end
    if self.uiData.DiedState == false then
      self:ShowSelected(true)
      if bUserClick and not _G.NRCModuleManager:GetModule("PetUIModule"):HasPanel("PetInfoMain") and _G.NRCModuleManager:DoCmd(PlayerModuleCmd.CheckPetIsFriendRiding, self.uiData.PetData.gid) then
        local FriendRideInfo = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GetFriendRideInfoByPetGID, self.uiData.PetData.gid)
        if FriendRideInfo and FriendRideInfo.IsFriendRiding then
          local FriendName = FriendRideInfo.FriendName
          local TipText = _G.DataConfigManager:GetLocalizationConf("interactiontree_ride_friend_text").msg
          TipText = string.format(TipText, FriendName)
          _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, TipText)
        end
      end
      if self.uiData and self.uiData.PetData and self.uiData.IsScrollPet then
        local teamIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(self.uiData.PetData.gid)
        if teamIndex then
          teamIndex = teamIndex - 1
          local needToSend = true
          local selectedPetInfo = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetThrowSelectPetInfo)
          if selectedPetInfo and selectedPetInfo.gid == self.uiData.PetData.gid and selectedPetInfo.teamIdx == teamIndex and selectedPetInfo.selectIdx == self.index % 6 then
            needToSend = false
          end
          if needToSend then
            _G.NRCModeManager:DoCmd(_G.MainUIModuleCmd.SetSelectPetIndex, self.index % 6, self.uiData.PetData)
            _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.UpdateThrowPetListSelectGid, self.uiData.PetData.gid, teamIndex, self.index % 6)
          end
        end
      end
      if self.uiData.IsScrollPet then
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, self.uiData.PetData, self.uiData.RecycleState, self.uiData.Session)
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, self.uiData.PetData.gid)
        local RidePet = player and player.viewObj and player.viewObj.BP_RideComponent and player.viewObj.BP_RideComponent.ScenePet
        if not RidePet or self.uiData.PetData.gid ~= RidePet.gid or _G.DataModelMgr.PlayerDataModel:GetIsTeamPetByGid(self.uiData.PetData.gid) then
        else
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SelectRidePetToThrow_ChangePetTeam, self.uiData.PetData.gid)
        end
      else
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, self.index, self.uiData.PetData)
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, SelectPetIndex)
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, self.uiData.PetData, self.uiData.RecycleState, self.uiData.Session)
        _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, self.uiData.PetData.gid)
        _G.NRCModeManager:DoCmd(MainUIModuleCmd.CloseSimpleUseList)
      end
    end
  else
    self:ShowSelected(false)
  end
  _G.UpdateManager:UnRegister(self)
end

function UMG_MainPetTempate_C:SendPetResponseReq()
  if not self.IsLongPress then
    local req = _G.ProtoMessage:newZoneSelectMainTeamPetReq()
    req.gid = self.uiData.PetData.gid
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SELECT_MAIN_TEAM_PET_REQ, req)
  end
end

function UMG_MainPetTempate_C:OnTouchStarted(MyGeometry, InTouchEvent)
  Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, moduleName, panelName)
  if isSelectBtn then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    if not player.statusComponent then
      Log.Warning("cannot found player statusComponent")
      return UE4.UWidgetBlueprintLibrary.Handled()
    end
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      Log.Warning("select pet, but pending throw magic")
      return UE4.UWidgetBlueprintLibrary.Handled()
    end
  end
  if _G.BattleManager:IsInBattle() then
    return
  end
  if _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetMainPetListVisibility) == UE4.ESlateVisibility.Collapsed then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).PETITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  self.IsOnClick = true
  self:SetSelectable(true)
  _G.UpdateManager:Register(self)
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainPetTempate_C:OnTouchEnded(MyGeometry, InTouchEvent)
  Base.OnTouchEnded(self, MyGeometry, InTouchEvent)
  if _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetMainPetListVisibility) == UE4.ESlateVisibility.Collapsed then
    return UE4.UWidgetBlueprintLibrary.Handled()
  end
  self:SendPetResponseReq()
  return UE4.UWidgetBlueprintLibrary.Handled()
end

function UMG_MainPetTempate_C:SetLongPressState(_IsLongPress)
  self.IsLongPress = _IsLongPress
end

function UMG_MainPetTempate_C:OnMouseLeave(MyGeometry, MouseEvent)
  self:LongPressBreak()
end

function UMG_MainPetTempate_C:OnTick(InDeltaTime)
  if self.IsOnClick then
    if self.StartPressTime == nil then
      self.StartPressTime = 0
    end
    self.StartPressTime = self.StartPressTime + InDeltaTime
  end
  if not self.StartPressTime then
    self.StartPressTime = 0
  end
  if not self.LongPressTime then
    self.LongPressTime = 0
  end
  if self.StartPressTime and self.LongPressTime and self.StartPressTime >= self.LongPressTime then
    _G.NRCAudioManager:PlaySound2DAuto(40008017, "UMG_Control_Camera_C:OnTick")
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET, true)
    if isBan then
      self:LongPressBreak()
      return
    end
    self.IsLongPress = true
    self.StartPressTime = 0
    self.IsOnClick = false
    self:SetSelectable(false)
  end
  if self.IsLongPress then
    self.StartTime = self.StartTime + InDeltaTime
    self.Progress:showAni(self.ScreenPos, self.StartTime, self.EndTime)
    if self.StartTime and self.EndTime and self.StartTime >= self.EndTime then
      local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if player then
        if not player.statusComponent then
          Log.Warning("cannot found player statusComponent")
          self:LongPressBreak()
          return
        end
        if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) or player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
          self:LongPressBreak()
          return
        end
      end
      local isLockOpen = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetLockOpenSubUI)
      if isLockOpen then
        self:LongPressBreak()
        return
      end
      _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.SetIsOpenPetPanel, true)
      self:SetSelectable(true)
      local SelectPetIndex = self.index
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, SelectPetIndex)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SelectLongPressPetIndex, SelectPetIndex, true)
      local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET, true)
      Log.Debug(isBan, "UMG_MainPetTempate_C:OnTick")
      if not isBan then
        if self.uiData.PetData and not self:IsInMiniGamePerform() then
          NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, {
            subPanelIndex = 4,
            callback = self.OnUMGLoadFinished
          }, nil, nil, true)
          _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, true)
        end
      else
        _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.SetIsOpenPetPanel, false)
      end
      self:LongPressBreak()
    end
  end
end

function UMG_MainPetTempate_C:LongPressBreak()
  self.IsOnClick = false
  self.IsLongPress = false
  self:SetSelectable(true)
  self.StartTime = 0
  self.StartPressTime = 0
  self.Progress:showEndAni()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetLongPressPetIndex, nil)
  _G.UpdateManager:UnRegister(self)
  local isOpenPetPanel = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsOpenPetPanel)
  if not isOpenPetPanel then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PETITEM
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  end
end

function UMG_MainPetTempate_C:IsInMiniGamePerform()
  local status = _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
  if "Perform" == miniGameStage or status == ProtoEnum.MinigameStatus.MS_FINISH then
    return true
  end
  return false
end

function UMG_MainPetTempate_C:SetHPPercent(hpPercent)
  self.Lifebar:SetPercent(hpPercent)
  if hpPercent < 0.2 then
    self.Lifebar:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#af3d3eff"))
  elseif hpPercent < 0.5 then
    self.Lifebar:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#fcb641ff"))
  else
    self.Lifebar:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#73c615ff"))
  end
end

function UMG_MainPetTempate_C:ShowRecycle(show)
  if self.IsPlayingSkill or self.uiData.IsLock then
    self.PetRecycle:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if self.uiData and self.uiData.PetData and self.uiData.PetData.gid and _G.NRCModuleManager:DoCmd(PlayerModuleCmd.CheckPetIsFriendRiding, self.uiData.PetData.gid) then
    return
  end
  if show then
    self.PetRecycle:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.oldRecycle ~= show and not self:IsAnimationPlaying(self.PetRecycle_In) then
      self:StopAnimation(self.PetRecycle_Out)
      self:PlayAnimation(self.PetRecycle_In)
    end
  elseif self.oldRecycle ~= show and not self:IsAnimationPlaying(self.PetRecycle_Out) then
    self:StopAnimation(self.PetRecycle_In)
    self:PlayAnimation(self.PetRecycle_Out)
  end
end

function UMG_MainPetTempate_C:UpdateFriendRideStateShow()
  if self.uiData == nil then
    return
  end
  if nil == self.uiData.PetData then
    return
  end
  if nil == self.uiData.PetData.gid then
    return
  end
  local bShow = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.CheckPetIsFriendRiding, self.uiData.PetData.gid) or false
  bShow = bShow or false
  if bShow then
    self:StopAnimation(self.PetRecycle_In)
    self:PlayAnimation(self.PetRecycle_Out)
    self.Switcher_Interaction:SetActiveWidgetIndex(2)
    self.Switcher_Interaction:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Switcher_Interaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.RecycleState then
      self:StopAnimation(self.PetRecycle_Out)
      self:PlayAnimation(self.PetRecycle_In)
    end
  end
end

function UMG_MainPetTempate_C:ShowLock(bShow)
  if bShow then
    self.Lock:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetRecycle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainPetTempate_C:ShowDisabled(show)
  if show then
    self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PetLevel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(0.3, 0.3, 0.3, 1))
  else
    self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetLevel:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HeadIcon:SetColorAndOpacity(UE4.FLinearColor(1, 1, 1, 1))
  end
end

function UMG_MainPetTempate_C:ShowSelected(show)
  if show then
    if not self.isShow then
      _G.NRCAudioManager:PlaySound2DAuto(40001001, "UMG_MainPetTempate_C:ShowSelected")
    end
    self:PlaySelectAnim()
  else
    self:PlayAnimation(self.change_unselect)
    self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.isShow = show
end

function UMG_MainPetTempate_C:HideAllState()
  self.PetLevel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PetDisabled:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MainPetTempate_C:ShowSelectedRest(show)
  if show then
    self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Visible)
    self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.Visible)
    local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
    if curSelectedPetGid ~= self.uiData.PetData.gid then
    else
      self:PlayAnimation(self.change_selectloop)
    end
  else
    self:PlayAnimation(self.change_unselect)
    self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainPetTempate_C:PlaySelectAnim()
  self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Visible)
  self.SelectedAnim_bg:SetVisibility(UE4.ESlateVisibility.Visible)
  local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if self.IsTouchStarted then
    self.IsTouchStarted = false
    if curSelectedPetGid ~= self.uiData.PetData.gid then
      self:PlayAnimation(self.change_select)
    end
  elseif curSelectedPetGid ~= self.uiData.PetData.gid then
    self:PlayAnimation(self.change_select)
  else
    self:StopAnimation(self.change_unselect)
    self:PlayAnimation(self.change_selectloop)
  end
end

function UMG_MainPetTempate_C:SetMedalTipsInfo(medalTipsData)
  if nil == medalTipsData then
    return
  end
  local MedalConf = _G.DataConfigManager:GetMedalConf(medalTipsData.conf_id)
  if medalTipsData.complete_cnt then
    self.Medal_Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.EXP_1:SetText(string.format(LuaText.medal_text_2, medalTipsData.complete_cnt))
    if MedalConf and MedalConf.can_repeat_get and MedalConf.can_repeat_get > 0 then
      if MedalConf.repeat_get_award and #MedalConf.repeat_get_award > 0 and medalTipsData.complete_cnt >= MedalConf.repeat_get_award[1].count then
        self.Medal_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("71c204FF"))
        self.EXP_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("71c204FF"))
      else
        self.Medal_Icon:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("929086FF"))
        self.EXP_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("929086FF"))
      end
    end
  else
    self.Medal_Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EXP_1:SetText(LuaText.medal_text_1)
  end
  if MedalConf then
    self.EXP_2:SetText(MedalConf.name)
  end
end

function UMG_MainPetTempate_C:SetMedalInfo(AcquireType, isManuiOpen, MedalItem)
end

function UMG_MainPetTempate_C:PlayMedalAnim()
end

function UMG_MainPetTempate_C:OpItem(opType, opData, opReasonType)
  local OpTypes = PetUIModuleEnum.MainPetTemplateOpType
  opReasonType = opReasonType or PetUIModuleEnum.MainPetTemplateOpReasonType.None
  self.opReasonType = opReasonType
  if opType == OpTypes.RecycleState and self.uiData then
    self:ShowRecycle(self.uiData.RecycleState)
    self.oldRecycle = self.uiData.RecycleState
  elseif opType == OpTypes.All then
    self:OnItemUpdate(opData or self.uiData, self.datalist, self.index)
  elseif opType == OpTypes.DiedState then
    self:UpdateDiedState()
  elseif opType == OpTypes.Lock then
    self:ShowRecycle(self.uiData.RecycleState)
    self:ShowLock(self.uiData.IsLock)
    self.oldRecycle = self.uiData.RecycleState
  elseif opType == OpTypes.FriendRideState then
    self:UpdateFriendRideStateShow()
  elseif opType == OpTypes.updateThrowPetSelect then
    self:UpdateThrowPetCanClick(opData and opData.bThrow)
  elseif opType == OpTypes.ForceClearTips then
    self:ForceClearAllTips()
  end
end

function UMG_MainPetTempate_C:PlayTips(petGid, petTipsItem)
  if nil == petTipsItem then
    return
  end
  local tipsType = petTipsItem.subType
  local tipsData = petTipsItem.subData
  if nil == tipsType or nil == tipsData then
    return
  end
  if self.uiData and self.uiData.PetData and self.uiData.PetData.gid ~= petGid then
    return
  end
  self:ClearTipsProperties()
  self.TipsBelongPetGid = petGid
  self.petTipsItem = petTipsItem
  self.CurPlayingTipsType = tipsType
  if tipsType == TipEnum.MainPetTipsType.Energy then
    self:PlayEnergyTips(tipsData)
  elseif tipsType == TipEnum.MainPetTipsType.Exp then
    self:PlayExpTips(tipsData)
  elseif tipsType == TipEnum.MainPetTipsType.Level then
    self:PlayLevelTips(tipsData)
  elseif tipsType == TipEnum.MainPetTipsType.Skill then
    self:PlaySkillTips(tipsData)
  elseif tipsType == TipEnum.MainPetTipsType.Medal then
    self:PlayMedalTips(tipsData)
  end
end

function UMG_MainPetTempate_C:OnPlayTipStatusChange(bPause)
  Log.Debug("UMG_MainPetTempate_C:OnPlayTipStatusChange self.index=[", self.index or 0, "], bPause=[", bPause, "]")
  self.bTipPaused = bPause
end

function UMG_MainPetTempate_C:CustomTick()
  local bRemainTimeEnd = false
  if not self.bTipPaused and self.TipsRemainTime ~= nil and self.TipsRemainTime > 0 then
    self.TipsRemainTime = self.TipsRemainTime - TICK_DELTA_TIME
    if self.TipsRemainTime <= 0 then
      bRemainTimeEnd = true
      self:OnTipsRemainTimeEnd()
    end
  end
  if self.CustomTickDelayId then
    _G.DelayManager:CancelDelay(self.CustomTickDelayId)
    self.CustomTickDelayId = nil
  end
  if not bRemainTimeEnd then
    self.CustomTickDelayId = _G.DelayManager:DelaySeconds(TICK_DELTA_TIME, self.CustomTick, self)
  end
end

function UMG_MainPetTempate_C:OnTipsRemainTimeEnd()
  Log.Debug("UMG_MainPetTempate_C:OnTipsRemainTimeEnd self.index=[", self.index or 0, "], self.CurPlayingTipsType=[", self.CurPlayingTipsType or 0, "]")
  if self.CurPlayingTipsType == TipEnum.MainPetTipsType.Energy then
    if self.petTipsItem and self.petTipsItem.subData and self.petTipsItem.subData.newEnergy > self.petTipsItem.subData.oldEnergy then
      self.Energy:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Energy_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:PlayAnimation(self.EnergyRecovery_out)
      self:ShowSelectedRest(true)
    elseif self.petTipsItem and self.petTipsItem.subData and self.petTipsItem.subData.newEnergy < self.petTipsItem.subData.oldEnergy then
      self:EnergyTipsPlayEnd()
    end
  elseif self.CurPlayingTipsType == TipEnum.MainPetTipsType.Exp then
    self:PlayDisappear()
  elseif self.CurPlayingTipsType == TipEnum.MainPetTipsType.Level then
    self:PlayDisappear()
  elseif self.CurPlayingTipsType == TipEnum.MainPetTipsType.Skill then
    self:PlayNextSkillTips()
  elseif self.CurPlayingTipsType == TipEnum.MainPetTipsType.Medal then
    self:PlayAnimation(self.Medal_Out)
  end
end

function UMG_MainPetTempate_C:OnTipsPlayEnd(TargetPetGid)
  Log.Debug("UMG_MainPetTempate_C:OnTipsPlayEnd self.index=[", self.index or 0, "], TargetPetGid=[", TargetPetGid or 0, "]")
  local petGid = 0
  if self.uiData and self.uiData.PetData then
    petGid = self.uiData.PetData.gid
  end
  if TargetPetGid and TargetPetGid > 0 then
    petGid = TargetPetGid
  end
  local Index = self.index
  local petTipsItem = self.petTipsItem
  self:ClearTipsProperties()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.OnMainPetTemplateTipsPlayEnd, Index, petGid, petTipsItem)
end

function UMG_MainPetTempate_C:ForceClearAllTips()
  self:ClearTipsProperties()
  self:StopAnimation(self.appears)
  self:StopAnimation(self.Exp_ADD)
  self:StopAnimation(self.upgrade_appears)
  self:StopAnimation(self.huodejineng_change_1)
  self:StopAnimation(self.huodejineng_change_2)
  self:StopAnimation(self.huodejineng_disappear_1)
  self:StopAnimation(self.huodejineng_disappear_1_2)
  self:StopAnimation(self.Medal_In)
  self:StopAnimation(self.Medal_Out)
  self.CanvasPanelSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanelSkill_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanelMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MainPetTempate_C:PlayEnergyTips(energyTipsData)
  local oldEnergy = energyTipsData.oldEnergy or 0
  local newEnergy = energyTipsData.newEnergy or 0
  local diffEnergy = newEnergy - oldEnergy
  Log.Debug("UMG_MainPetTempate_C:PlayEnergyTips self.index=[", self.index or 0, "], oldEnergy=[", oldEnergy, "], newEnergy=[", newEnergy, "], diffEnergy=[", diffEnergy, "]")
  if diffEnergy > 0 then
    self:ShowSelected(false)
    self.Energy:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Energy_1:SetVisibility(UE4.ESlateVisibility.Visible)
    if newEnergy > 0 then
      self.Switcher_90:SetActiveWidgetIndex(0)
      self.Switcher:SetActiveWidgetIndex(0)
      self.PetLevel_2:SetText(tostring(newEnergy))
    else
      self.Switcher_90:SetActiveWidgetIndex(1)
      self.Switcher:SetActiveWidgetIndex(1)
      self.PetLevel_4:SetText(tostring(newEnergy))
    end
    self:PlayAnimation(self.EnergyRecovery_In)
    self:DisableEnergyZeroState()
  elseif diffEnergy < 0 then
    if 0 == newEnergy then
      self.Switcher_90:SetActiveWidgetIndex(1)
      self.Switcher:SetActiveWidgetIndex(1)
      self.PetLevel_4:SetText(tostring(newEnergy))
      self.Energy:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.EmptyEnergy:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PetLevel_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.EnergyRecovery_In)
    else
      self:EnergyTipsPlayEnd()
    end
  else
    self:EnergyTipsPlayEnd()
  end
end

function UMG_MainPetTempate_C:PlayExpTips(expTipsData)
  local oldExp = expTipsData.old_exp or 0
  local newExp = expTipsData.new_exp or 0
  local curLevel = expTipsData.level or 0
  Log.Debug("UMG_MainPetTempate_C:PlayExpTips self.index=[", self.index or 0, "], oldExp=[", oldExp, "], newExp=[", newExp, "], curLevel=[", curLevel, "]")
  self:SetOldExp(oldExp)
  self:SetNewExp(newExp)
  self:SetOldLevel(curLevel)
  self:SetNewLevel(curLevel)
  local oldExpPercent = self:GetExpPercent(oldExp, curLevel)
  local NewExpPercent = self:GetExpPercent(newExp, curLevel)
  if oldExpPercent < NewExpPercent then
    local expChangeText = string.format("%s%d", LuaText.umg_mainpettempate_1, newExp - oldExp)
    self.EXP:SetText(expChangeText)
    self.Under:SetPercent(oldExpPercent)
    self:SetAppearInfo()
    self:PlayAnimation(self.appears)
    self:DisableEnergyZeroState()
  end
end

function UMG_MainPetTempate_C:PlayLevelTips(levelTipsData)
  self.bUpGrade = true
  self.bAlreadyPlayUpgradeAnim = false
  local oldExp = levelTipsData.old_exp or 0
  local newExp = levelTipsData.new_exp or 0
  local oldLevel = levelTipsData.old_level or 0
  local newLevel = levelTipsData.new_level or 0
  Log.Debug("UMG_MainPetTempate_C:PlayLevelTips self.index=[", self.index or 0, "], oldExp=[", oldExp, "], newExp=[", newExp, "], oldLevel=[", oldLevel, "], newLevel=[", newLevel, "]")
  self:SetOldExp(oldExp)
  self:SetNewExp(newExp)
  self:SetOldLevel(oldLevel)
  self:SetNewLevel(newLevel)
  local oldExpPercent = self:GetExpPercent(oldExp, oldLevel)
  local NewExpPercent = self:GetExpPercent(newExp, newLevel)
  if oldExp < newExp then
    local expChangeText = string.format("%s%d", LuaText.umg_mainpettempate_1, newExp - oldExp)
    self.EXP:SetText(expChangeText)
    self.Under:SetPercent(oldExpPercent)
    self:PlayAnimation(self.appears)
    self:SetAppearInfo()
    self:DisableEnergyZeroState()
  end
end

function UMG_MainPetTempate_C:PlaySkillTips(skillTipsData)
  if nil == skillTipsData then
    self:OnTipsPlayEnd()
    return
  end
  if nil == skillTipsData.skills then
    self:OnTipsPlayEnd()
    return
  end
  if 0 == #skillTipsData.skills then
    self:OnTipsPlayEnd()
    return
  end
  Log.Debug("UMG_MainPetTempate_C:PlaySkillTips self.index=[", self.index or 0, "]")
  if self.DelayPlayNextSkillTipsId then
    _G.DelayManager:CancelDelayById(self.DelayPlayNextSkillTipsId)
    self.DelayPlayNextSkillTipsId = nil
  end
  self.CacheWaitToShowSkillTipsList = skillTipsData.skills
  self.RawSkillTipsNum = #skillTipsData.skills
  self:DisableEnergyZeroState()
  self:PlayNextSkillTips()
end

function UMG_MainPetTempate_C:PlayMedalTips(medalTipsData)
  if nil == medalTipsData then
    self:OnTipsPlayEnd()
    return
  end
  if 0 == #medalTipsData then
    self:OnTipsPlayEnd()
    return
  end
  if self.DelayPlayNextMedalTipsId then
    _G.DelayManager:CancelDelayById(self.DelayPlayNextMedalTipsId)
    self.DelayPlayNextMedalTipsId = nil
  end
  self.CacheWaitToShowMedalTipsList = medalTipsData
  self.RawMedalTipsNum = #medalTipsData
  self:DisableEnergyZeroState()
  self:PlayNextMedalTips()
end

function UMG_MainPetTempate_C:ClearTipsProperties()
  self.petTipsItem = nil
  self.CurPlayingTipsType = TipEnum.MainPetTipsType.None
  self.bTipPaused = false
  self.TipsRemainTime = 0
  self.TipsBelongPetGid = 0
  self.bUpGrade = false
  self.bAlreadyPlayUpgradeAnim = false
  self.CacheWaitToShowSkillTipsList = nil
  self.RawSkillTipsNum = 0
  self.CacheWaitToShowMedalTipsList = nil
  self.RawMedalTipsNum = 0
  self:SetOldExp(nil)
  self:SetOldLevel(nil)
  self:SetNewExp(nil)
  self:SetNewLevel(nil)
  if self.CustomTickDelayId then
    _G.DelayManager:CancelDelayById(self.CustomTickDelayId)
    self.CustomTickDelayId = nil
  end
end

function UMG_MainPetTempate_C:EnergyTipsPlayEnd()
  self:OnTipsPlayEnd()
end

function UMG_MainPetTempate_C:PlayNextSkillTips()
  if self.CacheWaitToShowSkillTipsList ~= nil and #self.CacheWaitToShowSkillTipsList > 0 then
    local bFirstSkillTips = false
    if #self.CacheWaitToShowSkillTipsList == self.RawSkillTipsNum then
      bFirstSkillTips = true
    end
    _G.NRCAudioManager:PlaySound2DAuto(40008026, "UMG_MainPetTempate_C:PlaySkillTips")
    local skillTipsData = table.remove(self.CacheWaitToShowSkillTipsList, 1)
    Log.Debug("UMG_MainPetTempate_C:PlayNextSkillTips self.index=[", self.index or 0, "], skillTipsData.id=[", skillTipsData.id or 0, "]")
    self:ShowSkill(skillTipsData.id, false)
    self:ShowRecycle(false)
    if bFirstSkillTips then
      self.CanvasPanelSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:PlayAnimation(self.appears_1)
    else
      self.CanvasPanelSkill:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.CanvasPanelSkill:SetRenderOpacity(1)
      self:PlayAnimation(self.huodejineng_change_2)
    end
    self.CanvasPanelSkill_1:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanelSkill_1:SetRenderOpacity(1)
  else
    self:PlayAnimation(self.huodejineng_disappear_1)
    self:ShowRecycle(self.uiData.RecycleState)
    self:OnTipsPlayEnd()
  end
end

function UMG_MainPetTempate_C:PlayNextMedalTips()
  if self.CacheWaitToShowMedalTipsList ~= nil and #self.CacheWaitToShowMedalTipsList > 0 then
    local medalTipsData = table.remove(self.CacheWaitToShowMedalTipsList, 1)
    self:SetMedalTipsInfo(medalTipsData)
    _G.NRCAudioManager:PlaySound2DAuto(40008046, "UMG_MainPetTempate_C:PlayNextMedalTips")
    self.CanvasPanelMedal:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Medal_In)
  else
    self:ShowRecycle(self.uiData.RecycleState)
    self:OnTipsPlayEnd()
  end
end

function UMG_MainPetTempate_C:SetOldExp(value)
  self.oldExp = value
end

function UMG_MainPetTempate_C:GetOldExp()
  return self.oldExp or 0
end

function UMG_MainPetTempate_C:SetNewExp(value)
  self.newExp = value
end

function UMG_MainPetTempate_C:GetNewExp()
  return self.newExp or 0
end

function UMG_MainPetTempate_C:SetOldLevel(value)
  self.oldLevel = value
end

function UMG_MainPetTempate_C:GetOldLevel()
  return self.oldLevel or 0
end

function UMG_MainPetTempate_C:SetNewLevel(value)
  self.newLevel = value
end

function UMG_MainPetTempate_C:GetNewLevel()
  return self.newLevel or 0
end

function UMG_MainPetTempate_C:LvChange()
  local oldlv = 0
  local norlevel = true
  if self.uiData.oldlv ~= nil and self.uiData.oldlv < self.uiData.PetData.level then
    oldlv = self.uiData.oldlv
    norlevel = false
  elseif nil ~= self.olduiData then
    if self.olduiData.gid == self.uiData.PetData.gid then
      if self.olduiData.oldLv < self.uiData.PetData.level then
        oldlv = self.olduiData.oldLv
      end
    else
      table.clear(self.levelOrSkillData)
      Log.Debug("UMG_MainPetTempate_C:LvChange table.clear(self.levelOrSkillData)")
    end
  end
  if oldlv > 0 then
    self:GetLockSkills(oldlv)
    self:IsShowSelected(0 == #self.levelOrSkillData)
  end
  self.IsNoChangeExp = true
  if nil ~= self.olduiData and self.uiData.IsNewPet == false and false == self.uiData.PetUIOpen then
    local OldPetData = {
      exp = self.uiData.oldExp or 0,
      level = self.uiData.oldlv or 0
    }
    local lastExpPercent = self:GetPercent(OldPetData)
    local newExpPercent = self:GetPercent(self.uiData.PetData)
    local oldOverflow_exp = self.olduiData.PetData.overflow_exp or 0
    local newOverflow_exp = self.uiData.PetData.overflow_exp or 0
    local overFlowExp = newOverflow_exp - oldOverflow_exp
    local MaxLevel = PetUtils.GetPetMaxLevel(self.uiData.PetData)
    local isMaxLevel = self.uiData.PetData.level == MaxLevel
    self.IsNoChangeExp = lastExpPercent == newExpPercent and self.uiData.oldlv == self.uiData.PetData.level and oldOverflow_exp == newOverflow_exp
    Log.Debug("UMG_MainPetTempate_C:LvChange PerformAnimation=[", self.PerformAnimation or 0, "], IsNoChangeExp=[", self.IsNoChangeExp or 0, "]")
    if true == self.PerformAnimation and self.IsNoChangeExp == true then
      self.IsNoChangeExp = false
      return
    end
    if self.uiData.PetData.exp <= self.uiData.oldExp then
      return
    end
    Log.Debug("UMG_MainPetTempate_C:LvChange name=[", self.uiData.PetData.name or "", "], OldLv=[", self.uiData.oldlv or 0, "], NewLv=[", self.uiData.PetData.level or 0, "], OldExpPercent=[", lastExpPercent or 0, "], NewExpPercent=[", newExpPercent or 0, "")
    if self.olduiData.gid == self.uiData.PetData.gid and self.uiData.oldlv ~= nil and (lastExpPercent ~= newExpPercent or self.uiData.oldlv < self.uiData.PetData.level) then
      self.OverflowExpFlag = false
      self.PerformAnimation = true
      if self.uiData.oldlv < self.uiData.PetData.level then
        self.bUpGrade = true
      end
      self:IsShowSelected(false)
      local NewExp = self.uiData.PetData.exp - self.uiData.oldExp
      if overFlowExp > 0 then
        NewExp = overFlowExp + NewExp
      end
      local Exp = string.format("%s%d", LuaText.umg_mainpettempate_1, NewExp)
      self.EXP:SetText(Exp)
      self.Under:SetPercent(lastExpPercent)
      self.OldPetUiData = table.deepCopy(self.olduiData)
      self:PlayAnimation(self.appears)
      self:SetAppearInfo()
      self:DisableEnergyZeroState()
    elseif self.olduiData.PetData.overflow_exp and self.uiData.PetData.overflow_exp and self.olduiData.gid == self.uiData.PetData.gid and 0 ~= self.olduiData.PetData.overflow_exp and 0 ~= self.uiData.PetData.overflow_exp and 0 ~= self.uiData.PetData.overflow_exp - self.olduiData.PetData.overflow_exp then
      self.OverflowExpFlag = true
      local NewExp = self.uiData.PetData.overflow_exp - self.olduiData.PetData.overflow_exp
      self.PerformAnimation = true
      self:IsShowSelected(false)
      self:SetAppearInfo()
      local Exp = string.format("%s%d", LuaText.pet_exp_save_world, NewExp)
      self.EXP:SetText(Exp)
      self.Under:SetPercent(1)
      self.OldPetUiData = self.olduiData
      self:PlayAnimation(self.appears)
      self:DisableEnergyZeroState()
    elseif true == self.uiData.IsPlayAnim and not isMaxLevel then
      self.OverflowExpFlag = false
      self:IsShowSelected(false)
      self.IsPlayAnim = self.uiData.IsPlayAnim
      self:SetAppearInfo()
      local Exp = string.format("%s%d", "EXP+", 0)
      self.EXP:SetText(Exp)
      self.Under:SetPercent(1)
      self.OldPetUiData = self.olduiData
      self:PlayAnimation(self.appears)
      self.PerformAnimation = true
      self:DisableEnergyZeroState()
    end
  elseif oldlv > 0 then
  end
  self:LevelChange()
  self.olduiData = {
    gid = self.uiData.PetData.gid,
    oldLv = self.uiData.PetData.level,
    PetData = table.deepCopy(self.uiData.PetData),
    isContinueExpEffect = false
  }
end

function UMG_MainPetTempate_C:ShowEnergyZeroState(energy)
  if nil == self.uiData.isMainUIOpen or self.uiData.isMainUIOpen == false then
    return
  end
  if self:IsAnimationPlaying(self.appears) or self:IsAnimationPlaying(self.Exp_ADD) or self:IsAnimationPlaying(self.upgrade_appears) then
  end
  self.Energy:SetVisibility(energy > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  if UE4.UObject.IsValid(self.EmptyEnergy) and UE4.UObject.IsValid(self.EmptyEnergy_1) then
    self.EmptyEnergy:SetVisibility(energy > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.EmptyEnergy_1:SetVisibility(energy > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  end
  self.Energy_1:SetVisibility(energy > 0 and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  self.Switcher_90:SetActiveWidgetIndex(energy > 0 and 0 or 1)
  self.Switcher:SetActiveWidgetIndex(energy > 0 and 0 or 1)
  self.PetLevel_4:SetText(energy)
  if nil == self.LastEnergy and 0 == energy then
    self:PlayAnimation(self.EnergyRecovery_In)
  elseif 0 == energy and 0 ~= self.LastEnergy then
    self:PlayAnimation(self.EnergyRecovery_In)
  else
    self:StopAnimation(self.EnergyRecovery_In)
  end
  self.LastEnergy = energy
end

function UMG_MainPetTempate_C:DisableEnergyZeroState()
  if UE4.UObject.IsValid(self.EmptyEnergy) and UE4.UObject.IsValid(self.EmptyEnergy_1) then
    self.EmptyEnergy:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.EmptyEnergy_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MainPetTempate_C:SetAppearInfo()
  self.Exp:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.Exp:SetRenderOpacity(1)
  self.PanelUnder:SetRenderOpacity(1)
  self.PanelUnder:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.PanelFull:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.NRCImage_44:SetRenderOpacity(0)
  self.NRCImage_8:SetRenderOpacity(0)
end

function UMG_MainPetTempate_C:IsShowSelected(_IsShow)
  if self.isShow then
    self.isShowEffect = true
    self:ShowSelectedRest(_IsShow)
  end
end

function UMG_MainPetTempate_C:PlayExpAnimation()
end

function UMG_MainPetTempate_C:PlayExpAddAnimation()
  local oldLevel = self:GetOldLevel()
  local oldExp = self:GetOldExp()
  local newLevel = self:GetNewLevel()
  local newExp = self:GetNewExp()
  local oldExpPercent = self:GetExpPercent(oldExp, oldLevel)
  local newExpPercent = self:GetExpPercent(newExp, newLevel)
  if self.OverflowExpFlag then
    oldExpPercent = 1
    newExpPercent = 1
  end
  self.CanvasPanel_32:SetVisibility(UE4.ESlateVisibility.Visible)
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime() + aniTime * oldExpPercent
  local endTime = ani:GetStartTime() + aniTime * newExpPercent
  if newLevel ~= oldLevel then
    endTime = ani:GetEndTime()
  end
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  if self.IsPlayAnim == true then
    endTime = 1
    beginTime = 1
    self.IsPlayAnim = false
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008008, "UMG_MainPetTempate_C:ShowSelected")
  self:PlayAnimationTimeRange(ani, beginTime, endTime)
end

function UMG_MainPetTempate_C:playPetExpAnimation(_OldPetUiData, _UiData)
  local uiData = _UiData
  local olduiData = _OldPetUiData
  local oldLevel = olduiData.oldLv or 0
  local lastExpPercent = self:GetPercent(olduiData.PetData)
  local newLevel = uiData.PetData.level
  local newExpPercent = self:GetPercent(uiData.PetData)
  local oldPercent = lastExpPercent or 0
  local newPercent = newExpPercent
  if self.OverflowExpFlag then
    oldPercent = 1
    newPercent = 1
  end
  self.CanvasPanel_32:SetVisibility(UE4.ESlateVisibility.Visible)
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime() + aniTime * oldPercent
  local endTime = ani:GetStartTime() + aniTime * newPercent
  if newLevel ~= oldLevel then
    olduiData.isContinueExpEffect = true
    endTime = ani:GetEndTime()
  end
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  if true == self.IsPlayAnim then
    endTime = 1
    beginTime = 1
    self.IsPlayAnim = false
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008008, "UMG_MainPetTempate_C:ShowSelected")
  self:PlayAnimationTimeRange(ani, beginTime, endTime)
  self.OldPetUiData.PetData = self.uiData.PetData
end

function UMG_MainPetTempate_C:OnPetExpEffectPlayEnd()
  if self.OldPetUiData.isContinueExpEffect == false then
    if false == self.bUpGrade then
      self.waitAimState = 0
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainPetListAimNumberChange)
    else
      self.PanelFull:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.upgrade_appears)
    end
    return
  end
  self.bUpGrade = true
  local lastPetInfo = self.OldPetUiData.PetData
  local lastExpPercent = self:GetPercent(lastPetInfo)
  self.CanvasPanel_32:SetVisibility(UE4.ESlateVisibility.Visible)
  local ani = self.Exp_ADD
  local aniTime = ani:GetEndTime() - ani:GetStartTime()
  local beginTime = ani:GetStartTime()
  local endTime = ani:GetStartTime() + aniTime * lastExpPercent
  if beginTime >= endTime then
    endTime = beginTime + 0.01
  end
  self:PlayAnimationTimeRange(ani, beginTime, endTime)
  self:PlayAnimation(self.LevelUp)
  _G.NRCAudioManager:PlaySound2DAuto(40008021, "UMG_MainPetTempate_C:ShowSelected")
  self.OldPetUiData.isContinueExpEffect = false
end

function UMG_MainPetTempate_C:OnExpAddAnimPlayEnd()
  if self.bUpGrade and not self.bAlreadyPlayUpgradeAnim then
    self.CanvasPanel_32:SetVisibility(UE4.ESlateVisibility.Visible)
    local newExpPercent = self:GetExpPercent(self.newExp, self.newLevel)
    local Anim = self.Exp_ADD
    local animTime = Anim:GetEndTime() - Anim:GetStartTime()
    local startTime = Anim:GetStartTime()
    local endTime = startTime + animTime * newExpPercent
    if startTime >= endTime then
      endTime = startTime + 0.01
    end
    self:PlayAnimationTimeRange(Anim, startTime, endTime)
    self.PanelFull:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.upgrade_appears)
    self.bAlreadyPlayUpgradeAnim = true
    _G.NRCAudioManager:PlaySound2D(40008021, "UMG_MainPetTempate_C:OnExpAddAnimPlayEnd")
  else
    self.TipsRemainTime = self.levelUpShowTime
    if self.CustomTickDelayId then
      _G.DelayManager:CancelDelay(self.CustomTickDelayId)
      self.CustomTickDelayId = nil
    end
    self.CustomTickDelayId = _G.DelayManager:DelaySeconds(TICK_DELTA_TIME, self.CustomTick, self)
  end
end

function UMG_MainPetTempate_C:GetPercent(PetData)
  Log.Debug("UMG_MainPetTempate_C:GetPercent")
  if PetData.level and PetData.level > 0 then
    local petLevelConf = _G.DataConfigManager:GetPetLevelConf(PetData.level)
    if petLevelConf then
      local curExp = PetData.exp
      local maxExp = petLevelConf and petLevelConf.pet_exp or 1
      if PetData.level > 1 then
        petLevelConf = _G.DataConfigManager:GetPetLevelConf(PetData.level - 1)
        if petLevelConf then
          maxExp = maxExp - petLevelConf.pet_exp
          curExp = curExp - petLevelConf.pet_exp
        end
      end
      if 0 ~= maxExp and 0 ~= curExp then
        local expPercent = curExp / maxExp
        return expPercent
      end
    end
  end
  return 0
end

function UMG_MainPetTempate_C:GetExpPercent(exp, level)
  if level and level > 0 then
    local petLevelConf = _G.DataConfigManager:GetPetLevelConf(level)
    if petLevelConf then
      local curExp = exp
      local maxExp = petLevelConf and petLevelConf.pet_exp or 1
      if level > 1 then
        petLevelConf = _G.DataConfigManager:GetPetLevelConf(level - 1)
        if petLevelConf then
          maxExp = maxExp - petLevelConf.pet_exp
          curExp = curExp - petLevelConf.pet_exp
        end
      end
      if 0 ~= maxExp and 0 ~= curExp then
        local expPercent = curExp / maxExp
        return expPercent
      end
    end
  end
  return 0
end

function UMG_MainPetTempate_C:LevelChange()
  self.PetLevel:SetText(self.uiData.PetData.level)
  if self.oldLevel ~= nil and self.oldLevel < self.uiData.PetData.level then
    self:PlayAnimation(self.Light)
  end
  self.oldLevel = self.uiData.PetData.level
end

function UMG_MainPetTempate_C:GetLockSkills(oldlv)
  local oldPetSkillDatas = {}
  if self.olduiData and self.olduiData.PetData and self.olduiData.PetData.skill and self.olduiData.PetData.skill.skill_data then
    oldPetSkillDatas = self.olduiData.PetData.skill.skill_data
  end
  if self.uiData.PetData and self.uiData.PetData.level and oldlv < self.uiData.PetData.level and self.uiData.PetData.skill and self.uiData.PetData.skill.skill_data then
    for i = 1, #self.uiData.PetData.skill.skill_data do
      local skilldata = self.uiData.PetData.skill.skill_data[i]
      if skilldata.unlock_need_lv and oldlv < skilldata.unlock_need_lv and skilldata.unlock_need_lv <= self.uiData.PetData.level then
        for _, oldSkillData in ipairs(oldPetSkillDatas) do
          if oldSkillData.id ~= skilldata.id or oldSkillData.is_learned == true then
          elseif skilldata.is_learned then
            table.insert(self.levelOrSkillData, {
              showtype = 1,
              id = skilldata.id
            })
            Log.Debug("UMG_MainPetTempate_C:GetLockSkills table.insert(self.levelOrSkillData)")
          end
        end
      end
    end
  end
end

function UMG_MainPetTempate_C:PlayLevelChang(norlevel)
  self.animaPlaying = true
  if true == norlevel then
    self:PlayAnimation(self.upgrade_appears)
  else
    self:PlayAnimation(self.upgrade_appears_2)
  end
  if self.isShow then
    self.isShowEffect = true
    self:ShowSelectedRest(false)
  end
end

function UMG_MainPetTempate_C:ShowChangeEnergyAnimation()
end

function UMG_MainPetTempate_C:ShowSkillAnima(levelEnd, showLevel)
end

function UMG_MainPetTempate_C:ShowSkill(id, handbookSkill)
  local skillConfig = _G.DataConfigManager:GetSkillConf(id)
  if skillConfig then
    self.NRCTextskillName:SetText(skillConfig.name)
    self.NRCTextskillName_1:SetText(skillConfig.name)
  end
end

function UMG_MainPetTempate_C:GetPetEvoPetBaseId(_data)
  if self.uiData == nil or self.uiData.PetData.gid ~= _data.PetData.gid then
    local baseid = _data.PetData.base_conf_id
    local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
    self.handbookData = {baseid = baseid, handbooklv = 0}
    for i = 1, #petinfo.handbook.record_collection do
      if not petinfo.handbook.record_collection[i].record or 0 == #petinfo.handbook.record_collection[i].record then
      else
        local record = petinfo.handbook.record_collection[i].record[1]
        if record.pet_base_id == baseid then
          self.handbookData.handbooklv = record.study_lv
          return
        end
      end
    end
  end
end

function UMG_MainPetTempate_C:ShowHanBookSkill()
  local petinfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  for i = 1, #petinfo.handbook.record_collection do
    if not petinfo.handbook.record_collection[i].record or 0 == #petinfo.handbook.record_collection[i].record then
    else
      local record = petinfo.handbook.record_collection[i].record[1]
      if record.pet_base_id == self.handbookData.baseid and record.study_lv and self.handbookData.handbooklv then
        if self.handbookData.handbooklv < record.study_lv then
          self:GetAwardInfoSkill(record, self.handbookData.handbooklv)
          self.handbookData.handbooklv = record.study_lv
        end
        return
      end
    end
  end
end

function UMG_MainPetTempate_C:GetAwardInfoSkill(record, oldLv)
  local study_lv = record.study_lv
  local PetHandbook = _G.DataConfigManager:GetPetHandbook(record.pet_base_id)
  if PetHandbook then
    local pet_handbook = PetHandbook.pet_handbook
    for i, PetAwardList in ipairs(pet_handbook) do
      local award_data = PetAwardList.award_data
      if oldLv < i and i <= study_lv and PetAwardList.award_type == _G.Enum.PetHandbookAward.AWARD_SKILL then
        table.insert(self.levelOrSkillData, {
          showtype = 2,
          id = award_data[1]
        })
      end
    end
  end
  if self.animaPlaying or 0 == #self.levelOrSkillData then
    return
  end
  self:ShowSkillAnima()
end

function UMG_MainPetTempate_C:PlayUpGrade()
  if self.UpgradeAnim == nil or self.UpgradeAnim == false then
    return
  end
  if nil == self.LevelUpAnim or false == self.LevelUpAnim then
    return
  end
  self.UpgradeAnim = nil
  self.LevelUpAnim = nil
  self.waitAimState = 1
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainPetListAimNumberChange)
end

function UMG_MainPetTempate_C:PlayDisappear()
  self:PlayAnimation(self.huodejineng_disappear_1_2)
  self.isShowEffect = false
  if self.isShow then
    self:ShowSelectedRest(self.isShow)
  end
end

function UMG_MainPetTempate_C:OnAnimationStarted(anim)
  if anim == self.appears then
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_MainPetTempate_C:OnAnimationFinished(anim)
  if anim == self.huodejineng_disappear_1 then
    if #self.levelOrSkillData <= 0 then
      self.CanvasPanelSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CanvasPanelSkill_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:ShowEnergyZeroState(self.uiData.PetData.energy)
      self:PlayMedalAnim()
    end
  elseif anim == self.appears then
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:PlayExpAddAnimation()
    self.uiData.oldlv = nil
    self.uiData.oldExp = nil
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnUpdateMainPetTipsShowState, self.uiData.PetData.gid)
  elseif anim == self.Exp_ADD then
    self.CanvasPanel_32:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:OnExpAddAnimPlayEnd()
  elseif anim == self.upgrade_appears then
  elseif anim == self.LevelUp then
  elseif anim == self.huodejineng_disappear_1_2 then
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 0 == self.waitAimState then
      self:ShowEnergyZeroState(self.uiData.PetData.energy)
      self.IsTimer = false
    end
    if self.CurPlayingTipsType == TipEnum.MainPetTipsType.Exp or self.CurPlayingTipsType == TipEnum.MainPetTipsType.Level then
      self:OnTipsPlayEnd()
    end
  elseif anim == self.huodejineng_disappear_1_3 then
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 1 == self.waitAimState then
      self:ShowEnergyZeroState(self.uiData.PetData.energy)
      self.IsTimer = false
    end
    self:PlayMedalAnim()
  elseif anim == self.PetRecycle_Out then
    self.PetRecycle:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.Medal_In then
    self:OnMedalShowAnimPlayEnd()
  elseif anim == self.Medal_Out then
    self.CanvasPanelMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayNextMedalTips()
  elseif anim == self.change_unselect or anim == self.change_selectloop then
    self:PlayMedalAnim()
  elseif anim == self.EnergyRecovery_in then
    self:OnEnergyRecoveryShowAnimPlayEnd()
  elseif anim == self.EnergyRecovery_out then
    self:EnergyTipsPlayEnd()
  elseif anim == self.appears_1 then
    self:OnSkillShowAnimPlayEnd()
  elseif anim == self.huodejineng_change_2 then
    self:OnSkillShowAnimPlayEnd()
  end
end

function UMG_MainPetTempate_C:OnEnergyRecoveryShowAnimPlayEnd()
  if self.CurPlayingTipsType == TipEnum.MainPetTipsType.Energy then
    self.TipsRemainTime = self.energyRecoveredShowTime
    if self.CustomTickDelayId then
      _G.DelayManager:CancelDelay(self.CustomTickDelayId)
      self.CustomTickDelayId = nil
    end
    self.CustomTickDelayId = _G.DelayManager:DelaySeconds(TICK_DELTA_TIME, self.CustomTick, self)
  end
end

function UMG_MainPetTempate_C:OnSkillShowAnimPlayEnd()
  if self.CurPlayingTipsType == TipEnum.MainPetTipsType.Skill then
    self.TipsRemainTime = self.skillUnlockShowTime
    if self.CustomTickDelayId then
      _G.DelayManager:CancelDelay(self.CustomTickDelayId)
      self.CustomTickDelayId = nil
    end
    self.CustomTickDelayId = _G.DelayManager:DelaySeconds(TICK_DELTA_TIME, self.CustomTick, self)
  end
end

function UMG_MainPetTempate_C:OnMedalShowAnimPlayEnd()
  if self.CurPlayingTipsType == TipEnum.MainPetTipsType.Medal then
    self.TipsRemainTime = self.medalUnlockShowTime
    if self.CustomTickDelayId then
      _G.DelayManager:CancelDelay(self.CustomTickDelayId)
      self.CustomTickDelayId = nil
    end
    self.CustomTickDelayId = _G.DelayManager:DelaySeconds(TICK_DELTA_TIME, self.CustomTick, self)
  end
end

function UMG_MainPetTempate_C:OnAllWaitFinsh(isOnePlay, onePlayIndex)
  if self.uiData and self.uiData.PetData then
    Log.Debug("UMG_MainPetTempate_C:OnAllWaitFinsh, name=[", self.uiData.PetData.name, "]")
  end
  if isOnePlay and onePlayIndex ~= self.index then
    return
  end
  if self.IsNoChangeExp then
    self.CanvasPanelSkill_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  Log.Debug("UMG_MainPetTempate_C:OnAllWaitFinsh, waitAimState=[", self.waitAimState, "]")
  if 0 == self.waitAimState then
    self.PerformAnimation = false
  elseif 1 == self.waitAimState then
    if self.IsTimer then
      return
    end
    if #self.levelOrSkillData <= 0 then
      self.IsTimer = true
    end
    self.DelayFinshId = _G.DelayManager:DelaySeconds(1.5, function()
      if self.DelayFinshId then
        _G.DelayManager:CancelDelayById(self.DelayFinshId)
        self.DelayFinshId = nil
      end
      if #self.levelOrSkillData <= 0 then
        self:PlayAnimation(self.huodejineng_disappear_1_3)
        self.isShowEffect = false
        if self.isShow then
          self:ShowSelectedRest(self.isShow)
        end
      else
        self.IsPlaySkill = true
        self:ShowSkillAnima(true, true)
        self.IsPlaySkill = false
      end
    end)
  end
end

function UMG_MainPetTempate_C:OpenPetInfoPanel(_Parent, _index)
  if self.clickable then
    self.Parent = _Parent
    self:PCKeyShow(_index)
    local isAmining = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetAimState)
    if not isAmining and self.uiData.RecycleState ~= true then
      self:PlaySelectAnim()
    end
    self:OnTouchStarted()
  end
end

function UMG_MainPetTempate_C:UnPetInfoPanel(_Parent)
  self.Parent = _Parent
  if self.IsOnClick then
    self:SendPetResponseReq()
  end
  self:LongPressBreak()
end

function UMG_MainPetTempate_C:PCKeyShow(_index)
  if SystemSettingModuleCmd then
    local InputAction = string.format("IA_SelectPetStart_%s", _index)
    local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, InputAction)
    if "" ~= image then
      self.Text_PCKey:SetImageMode(image)
    else
      self.Text_PCKey:SetText(text)
    end
    self.Text_PCKey:SetKeyVisibility(true)
  end
end

function UMG_MainPetTempate_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_MainPetTempate_C:CheckLock()
  if _G.NRCModuleManager:IsModuleActive("TaskPetFollowModule") and _G.NRCModuleManager:DoCmd(_G.TaskPetFollowModuleCmd.CheckPetInTaskFollow, self.uiData.PetData.gid, 4) then
    self.uiData.IsLock = true
    self:UpdateItemInfo()
  end
end

function UMG_MainPetTempate_C:OnDisable()
  self:LongPressBreak()
end

return UMG_MainPetTempate_C
