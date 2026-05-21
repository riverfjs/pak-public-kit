require("UnLuaEx")
local UMG_Hud_Player_C = NRCClass:Extend("UMG_Hud_Player_C")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local PlayerHudStateShowPriority = {}
local SvrLogicStatusToPlayerState = {
  [Enum.SpaceActorLogicStatus.SALS_OBSERVING] = MainUIModuleEnum.PlayerHudState.Observing,
  [Enum.SpaceActorLogicStatus.SALS_FIGHTING] = MainUIModuleEnum.PlayerHudState.Fighting,
  [Enum.SpaceActorLogicStatus.SALS_PLAYER_AFK] = MainUIModuleEnum.PlayerHudState.AFK,
  [Enum.SpaceActorLogicStatus.SALS_PLAYER_NPC] = MainUIModuleEnum.PlayerHudState.NpcInteraction,
  [Enum.SpaceActorLogicStatus.SALS_OPEN_UI_FULL_SCENE] = MainUIModuleEnum.PlayerHudState.FullScreen
}

local function OnInitStatePriority()
  PlayerHudStateShowPriority = {}
  local confPriority = _G.DataConfigManager:GetGlobalConfigByKeyType("head_info_priority", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
  local strList = string.Split(confPriority, ";")
  for _, state in ipairs(strList) do
    local confState = rawget(Enum.SpaceActorLogicStatus, state)
    table.insert(PlayerHudStateShowPriority, SvrLogicStatusToPlayerState[confState])
  end
  if 0 == #PlayerHudStateShowPriority then
    PlayerHudStateShowPriority = {
      MainUIModuleEnum.PlayerHudState.Fighting,
      MainUIModuleEnum.PlayerHudState.Observing,
      MainUIModuleEnum.PlayerHudState.NpcInteraction,
      MainUIModuleEnum.PlayerHudState.FullScreen,
      MainUIModuleEnum.PlayerHudState.AFK
    }
  end
  table.insert(PlayerHudStateShowPriority, MainUIModuleEnum.PlayerHudState.Fight)
  table.insert(PlayerHudStateShowPriority, MainUIModuleEnum.PlayerHudState.Perform)
end

OnInitStatePriority()

function UMG_Hud_Player_C:OnInitialized()
  self.statePanelActiveState = MainUIModuleEnum.PlayerHudState.Normal
  self.statePanelHideState = MainUIModuleEnum.PlayerHudState.Normal
end

function UMG_Hud_Player_C:Construct()
  self.isDestruct = false
  self.PlayerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  self.ScreenSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MainUIModuleEvent.MAINUICLOSE, self.OnLobbyMainClosed)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.AddOrRemoveBlackListUpdate, self.UpdateBlackInfo)
  self:CheckVisible()
  self:UpdateBlackInfo()
  self:UpdateCardUpgradeInfo()
  self:SetStateNameVisible(false)
  self:SetStateNameByState(MainUIModuleEnum.PlayerHudState.Normal)
end

function UMG_Hud_Player_C:Destruct()
  self.isDestruct = true
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUIOPEN, self.OnLobbyMainReady)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnLobbyMainClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.AddOrRemoveBlackListUpdate, self.UpdateBlackInfo)
  if self.DelayId then
    DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  self:CancelDelayCheckVisible()
end

function UMG_Hud_Player_C:ShowPerform(type, data, duration)
  if 2 == type then
    local pet = DataConfigManager:GetPetbaseConf(data[2])
    local ball = DataConfigManager:GetBagItemConf(data[4])
    if pet and ball then
      if pet.quality == Enum.PetQuality.PQ_ORANGE then
        self.IconQuality:SetPath(UEPath.PET_QUALITY_ORANGE)
      elseif pet.quality == Enum.PetQuality.PQ_PURPLE then
        self.IconQuality:SetPath(UEPath.PET_QUALITY_PURPLE)
      else
        self.IconQuality:SetPath(UEPath.PET_QUALITY_BLUE)
      end
      self.IconBall:SetPath(ball.icon)
      self.IconPet:SetPath(pet.big_icon)
    end
    self.PerformPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:CheckVisible()
    self.DelayId = DelayManager:DelaySeconds(duration, function()
      self.PerformPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:CheckVisible()
    end)
  end
end

function UMG_Hud_Player_C:RefreshStatePanel(activeStates, hideStates)
  if activeStates == MainUIModuleEnum.PlayerHudState.Normal then
    self.StatePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IdleState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NotSocializing:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetStateNameByState(MainUIModuleEnum.PlayerHudState.Normal)
  else
    local showState = 0
    for _, state in ipairs(PlayerHudStateShowPriority) do
      if 0 ~= activeStates & state and 0 == hideStates & state then
        showState = state
        break
      end
    end
    if 0 ~= showState then
      self.StatePanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    self.ImagePerform:SetVisibility(showState == MainUIModuleEnum.PlayerHudState.Perform and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Collapsed)
    self.ImageFight:SetVisibility(showState == MainUIModuleEnum.PlayerHudState.Fight and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Collapsed)
    if showState == MainUIModuleEnum.PlayerHudState.Fighting then
      if self.Fighting then
        self.Fighting:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self:PlayAnimation(self.Fighting_loop, 0, 0)
    else
      if self.Fighting then
        self.Fighting:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self:IsAnimationPlaying(self.Fighting_loop) then
        self:StopAnimation(self.Fighting_loop)
      end
    end
    if showState == MainUIModuleEnum.PlayerHudState.AFK then
      if self.IdleState then
        self.IdleState:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if not self.IdleState:IsAnimationPlaying(self.IdleState.Loop) then
          self.IdleState:PlayAnimation(self.IdleState.Loop, 0, 0)
        end
      end
    elseif self.IdleState then
      if self.IdleState:IsAnimationPlaying(self.IdleState.Loop) then
        self.IdleState:StopAnimation(self.IdleState.Loop)
      end
      self.IdleState:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if showState == MainUIModuleEnum.PlayerHudState.Observing then
      if self.WitnessBattle then
        self.WitnessBattle:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        if not self:IsAnimationPlaying(self.WitnessBattle_1) then
          self:PlayAnimation(self.WitnessBattle_1, 0, 0)
        end
      end
    elseif self.WitnessBattle then
      self.WitnessBattle:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self:IsAnimationPlaying(self.WitnessBattle_1) then
        self:StopAnimation(self.WitnessBattle_1)
      end
    end
    if self.NotSocializing then
      self.NotSocializing:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if showState == MainUIModuleEnum.PlayerHudState.FullScreen then
        self.NotSocializing:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.ImgSwitcher:SetActiveWidgetIndex(0)
        if not self:IsAnimationPlaying(self.Busy) then
          self:PlayAnimation(self.Busy, 0, 0)
        end
      elseif self:IsAnimationPlaying(self.Busy) then
        self:StopAnimation(self.Busy)
      end
      if showState == MainUIModuleEnum.PlayerHudState.NpcInteraction then
        self.NotSocializing:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.ImgSwitcher:SetActiveWidgetIndex(1)
        if not self:IsAnimationPlaying(self.Interact) then
          self:PlayAnimation(self.Interact, 0, 0)
        end
      elseif self:IsAnimationPlaying(self.Interact) then
        self:StopAnimation(self.Interact)
      end
    end
    self:SetStateNameByState(showState)
    self:SetStateNameVisible(self.InteractionOptionsVisible)
  end
  self:CheckVisible()
end

function UMG_Hud_Player_C:SetRoleState(state, active)
  local statePanelActiveState = self.statePanelActiveState
  if active then
    statePanelActiveState = statePanelActiveState | state
  else
    statePanelActiveState = statePanelActiveState & ~state
  end
  self.statePanelActiveState = statePanelActiveState
  self:RefreshStatePanel(statePanelActiveState, self.statePanelHideState)
end

function UMG_Hud_Player_C:SetRoleStateVisible(state, visible)
  local statePanelHideState = self.statePanelHideState
  if visible then
    statePanelHideState = statePanelHideState & ~state
  else
    statePanelHideState = statePanelHideState | state
  end
  self.statePanelHideState = statePanelHideState
  self:RefreshStatePanel(self.statePanelActiveState, statePanelHideState)
end

function UMG_Hud_Player_C:SetFightingState(_inFighting)
  self:SetRoleState(MainUIModuleEnum.PlayerHudState.Fighting, _inFighting)
end

function UMG_Hud_Player_C:SetRelationTreeState(RelationTreeType, ActionID)
  if nil ~= RelationTreeType or nil ~= ActionID then
    if self:GetInteractionOptionsVisible() then
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if not self.OldData then
      self.OldData = {}
    end
    self.PerformPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local StatePanelVisibility = self.StatePanel:IsVisible()
    if not StatePanelVisibility then
      local RelationBubbleVisible = self.RelationTree_Interaction:IsVisible()
      local NeedPlayAnimIn = table.getTableCount(self.OldData) <= 0 or not RelationBubbleVisible or not self:IsVisible()
      local forbiddenAudio = false
      if self.Player and self.Player.viewObj and self.Player:IsVisible() and not self.Player.viewObj:GetActorHidden() then
      else
        forbiddenAudio = true
      end
      if NeedPlayAnimIn then
        self.OldData = {RelationTreeType = RelationTreeType, ActionID = ActionID}
        self.RelationTree_Interaction:UpdateHeadHUD(true, RelationTreeType, ActionID, false, true, nil, forbiddenAudio)
      elseif self.OldData and (self.OldData.RelationTreeType ~= RelationTreeType or self.OldData.ActionID ~= ActionID) then
        self.OldData = {RelationTreeType = RelationTreeType, ActionID = ActionID}
        self.RelationTree_Interaction:PlayerAnimChangeOut(true, RelationTreeType, ActionID)
      end
    end
  else
    if self.RelationTree_Interaction:IsVisible() then
      self.OldData = {}
      self.RelationTree_Interaction:PlayerAnimOut()
    end
    if self:GetInteractionOptionsVisible() then
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  self:CheckVisible()
end

function UMG_Hud_Player_C:SetRelationTreeVisible(isVisible)
  if self.RelationTree_Interaction:IsVisible() and not isVisible then
    self.OldData = {}
    self.RelationTree_Interaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self:GetInteractionOptionsVisible() then
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Hud_Player_C:SetRelationTreeImgBGYellow(isYellow)
  self.RelationTree_Interaction:SetHeadHUD_BGYellow(isYellow)
end

function UMG_Hud_Player_C:SetVisitNumber(_number)
  if not _number or _number <= 0 then
    self.VisitInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.VisitInfo:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.VisitNumber:SetText(tostring(_number))
    self.VisitImage:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.VisitImage_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Hud_Player_C:SetNameVisible(visible)
  if self.nameVisible == visible then
    return
  end
  if visible then
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.NamePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.nameVisible = visible
  self:CheckVisible()
end

function UMG_Hud_Player_C:SetReturnIconVisible(visible)
  if visible then
    self.Starlight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Starlight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Hud_Player_C:SetVisible(visible)
  if self.visible == visible then
    return
  end
  if visible then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.visible = visible
end

function UMG_Hud_Player_C:SetName(showName)
  self.TextName:SetText(showName)
end

function UMG_Hud_Player_C:SetLevel(level)
  self.TextLevel:SetText(string.format("Lv.%d", level))
end

function UMG_Hud_Player_C:GetInteractionOptionsVisible()
  return self.InteractionOptionsVisible
end

function UMG_Hud_Player_C:SetInteractionOptionsVisible(Visible, Player)
  if self.InteractionOptionsVisible == Visible then
    return
  end
  self.InteractionOptionsVisible = Visible
  if Visible then
    self.Player = Player
    if not self.RelationTree_Interaction:IsVisible() then
      self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    local CardInfo = Player.serverData.card_info
    if CardInfo then
      self:SetInteractionOptionsInfo(CardInfo.card_skin_selected, CardInfo.card_label_first_selected, CardInfo.card_label_last_selected)
    end
  else
    self.Player = nil
    self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetStateNameVisible(Visible)
end

function UMG_Hud_Player_C:SetInteractionOptionsInfo(Skin, LabelFirst, LabelLast)
  if Skin then
    local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(Skin)
    if CardSkinConf then
      self.Bg:SetPath(string.format(UEPath.CARD_COMMON_PATH, CardSkinConf.skin_resource_path, "Overhead", CardSkinConf.skin_resource_path, "Overhead"))
      self:UpdateCardUpgradeInfo()
    end
  end
  if LabelFirst then
    local CardLabelFirstConf = _G.DataConfigManager:GetCardLabelConf(LabelFirst)
    if CardLabelFirstConf then
      self.BriefIntroduction_1:SetText(CardLabelFirstConf.label_text)
    end
  end
  if LabelLast then
    local CardLabelLastConf = _G.DataConfigManager:GetCardLabelConf(LabelLast)
    if CardLabelLastConf then
      self.BriefIntroduction:SetText(CardLabelLastConf.label_text)
    end
  end
  self:UpdateBlackInfo()
end

function UMG_Hud_Player_C:UpdateCardUpgradeInfo()
  if not (self.Player and self.Player.serverData) or not self.Player.serverData.card_info then
    return
  end
  local cardSkinId = self.Player.serverData.card_info.card_skin_selected
  if not cardSkinId then
    return
  end
  self.Grade:Init(cardSkinId)
  local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(cardSkinId)
  if CardSkinConf then
    if CardSkinConf.level_icon and CardSkinConf.level_icon ~= "" then
      self:PlayAnimation(self.shine_loop)
    else
      self:PlayAnimation(self.shine_no)
    end
  end
end

function UMG_Hud_Player_C:UpdateBlackInfo()
  if not self.BlacklistIcon then
    return
  end
  if not self.Player then
    self.BlacklistIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local isBlack = _G.DataModelMgr.PlayerDataModel:CheckHasBlackByPlayerUin(self.Player.serverData.base.logic_id)
  if isBlack then
    self.BlacklistIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.BlacklistIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Hud_Player_C:HandleScreenClick(Location)
  if not self.InteractionOptionsVisible then
    return
  end
  if not self.Player then
    return
  end
  if not NRCModuleManager:DoCmd(MainUIModuleCmd.GetLobbyMainEnableState) then
    return
  end
  local ViewportPos = UE4.FVector()
  UE4.USlateBlueprintLibrary.AbsoluteToViewport(_G.UE4Helper.GetCurrentWorld(), Location, nil, ViewportPos)
  local Scale = UE4.UWidgetLayoutLibrary.GetViewportScale(_G.UE4Helper.GetCurrentWorld())
  ViewportPos.X = ViewportPos.X * Scale
  ViewportPos.Y = ViewportPos.Y * Scale
  if ViewportPos.X > self.ScreenSize.X * 0.9 or ViewportPos.Y > self.ScreenSize.Y * 0.9 or ViewportPos.X < self.ScreenSize.X * 0.1 or ViewportPos.Y < self.ScreenSize.Y * 0.1 then
    print("=====amonsu=========UMG_Hud_Player_C========HandleScreenClick====Out Of Range===")
    return
  end
  local WorldPos = UE4.FVector()
  local WorldDir = UE4.FVector()
  UE.UGameplayStatics.Abs_DeprojectScreenToWorld(self.PlayerController, ViewportPos, WorldPos, WorldDir)
  local LineEnd = WorldPos + WorldDir * 10000
  local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), WorldPos, LineEnd, UE4.UNRCStatics.ConvertToTraceChannel(_G.UE4.ECollisionChannel.ECC_GameTraceChannel6), false)
  if Success then
    local HitComps = Hit.Actor:GetComponentsByTag(UE4.URocoWidgetComponent, "HudHeadWidget")
    for i = 1, HitComps:Length() do
      if HitComps:Get(i) then
        _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenStudentCardPanel, self.Player.serverData, FriendEnum.AdminFriendType.Others, FriendEnum.Source.Scene, FriendEnum.SELECT_TAB.FaceToFaceInteraction)
      end
    end
  end
end

function UMG_Hud_Player_C:CallCtrlUserWidgetEvent(funcName, ...)
  if self.ctrl and self.ctrl[funcName] then
    return tcall(self.ctrl, self.ctrl[funcName], ...)
  elseif self.Overridden[funcName] then
    return tcall(self, self.Overridden[funcName], ...)
  end
end

function UMG_Hud_Player_C:CheckVisible()
  if self.DelayCheckVisible or self.isDestruct then
    return
  end
  self.DelayCheckVisible = _G.DelayManager:DelayFrames(1, self.DelayDoCheckVisible, self)
end

function UMG_Hud_Player_C:DelayDoCheckVisible()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  self.DelayCheckVisible = nil
  local isShow = self.StatePanel:IsVisible() or self.PerformPanel:IsVisible() or self.NamePanel:IsVisible() or self.InteractionOptions:IsVisible() or self.RelationTree_Interaction:IsVisible() or self.NotSocializingText:IsVisible() or self.NotSocializing:IsVisible()
  self:SetVisible(isShow)
  self:SetDetailedInfo(isShow and "" or "InVisible")
end

function UMG_Hud_Player_C:CancelDelayCheckVisible()
  local DelayCheckVisible = self.DelayCheckVisible
  if DelayCheckVisible then
    _G.DelayManager:CancelDelayById(DelayCheckVisible)
    self.DelayCheckVisible = nil
  end
end

function UMG_Hud_Player_C:OnLobbyMainReady()
  if self.InteractionOptionsVisible and not self.RelationTree_Interaction:IsVisible() then
    self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Hud_Player_C:SetStateNameByState(state)
  local stateName = ""
  if state == MainUIModuleEnum.PlayerHudState.Observing then
    stateName = LuaText.head_info_watch_tip
  elseif state == MainUIModuleEnum.PlayerHudState.Fighting then
    stateName = LuaText.head_info_fight_tip
  elseif state == MainUIModuleEnum.PlayerHudState.AFK then
    stateName = LuaText.head_info_afk_tip
  elseif state == MainUIModuleEnum.PlayerHudState.NpcInteraction then
    stateName = LuaText.head_info_npc_tip
  elseif state == MainUIModuleEnum.PlayerHudState.FullScreen then
    stateName = LuaText.head_info_busy_tip
  end
  self.NotSocializingText:SetText(stateName)
end

function UMG_Hud_Player_C:SetStateNameVisible(visible)
  local showState = visible and UE4.ESlateVisibility.HitTestInvisible or UE4.ESlateVisibility.Collapsed
  self.NotSocializingText:SetVisibility(showState)
end

function UMG_Hud_Player_C:OnLobbyMainClosed()
  if self.InteractionOptionsVisible then
    self.InteractionOptions:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Hud_Player_C
