local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local OnlineModuleEvent = reload("NewRoco.Modules.Core.Online.OnlineModuleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local MiniGameModuleEvent = reload("NewRoco.Modules.System.MiniGame.MiniGameModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ThrowSessionEvent = require("NewRoco.Modules.Core.NPC.ThrowSessionEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local ThrowSession = require("NewRoco.Modules.Core.NPC.ThrowSession")
local WorldCombatModuleEvent = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local RolePlayModuleEvent = require("NewRoco.Modules.System.RolePlay.RolePlayModuleEvent")
local UIVisibilityConstraint = require("Common.UIVisibilityConstraint")
local BagModuleEvent = reload("NewRoco.Modules.System.Bag.BagModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local FunctionBanModuleEvent = require("NewRoco.Modules.System.FunctionBan.FunctionBanModuleEvent")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEvent = require("NewRoco.Modules.System.Farm.FarmModuleEvent")
local RelationTreeEvent = require("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local BigMapUtils = require("NewRoco/Modules/System/BigMap/BigMapUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local UMG_LobbyMain_C = _G.NRCPanelBase:Extend("UMG_LobbyMain_C")
local PetUtils = require("NewRoco.Utils.PetUtils")
local InstanceModuleEvent = require("NewRoco.Modules.Core.Instance.InstanceModuleEvent")
local ScenePlayerInputManager = require("NewRoco.Modules.Core.Scene.ScenePlayerInputManager")

function UMG_LobbyMain_C:OnConstruct()
  self.uiVisibilityConstraint = UIVisibilityConstraint()
  self.imcPriority = -3
  self:BindInputAction()
  if self:IsPCMode() then
    self:SetChildViews(self.UMG_PlayerAbilities, self.UMG_Lobby_Vitality, self.UMG_Lobby_BleedingIndication, self.UMG_EnergyStorage, self.UMG_PlayerInfoHUD, self.UMG_Lobby_TandemRide, self.UMG_LobbyPropTips, self.UMG_TraceTaskPanel, self.UMG_TraceRelationTreePanel, self.UMG_PointOfInterestPanel, self.UMG_OnlineTeammateTagPanel, self.PlayerCtrl, self.UMG_MainUIRoleHP, self.UMG_Hud_PerceptionPanel, self.UMG_CompassIcon, self.UMG_Task_Track, self.ProjectTask, self.PCKeyFoundation)
  else
    self:SetChildViews(self.UMG_PlayerAbilities, self.UMG_Lobby_Vitality, self.UMG_Lobby_BleedingIndication, self.UMG_EnergyStorage, self.UMG_PlayerInfoHUD, self.UMG_Lobby_TandemRide, self.UMG_LobbyPropTips, self.UMG_TraceTaskPanel, self.UMG_TraceRelationTreePanel, self.UMG_PointOfInterestPanel, self.UMG_OnlineTeammateTagPanel, self.PlayerCtrl, self.UMG_MainUIRoleHP, self.UMG_Hud_PerceptionPanel, self.UMG_CompassIcon, self.UMG_Task_Track, self.ProjectTask, self.PCKeyFoundation)
  end
  self.UMG_TraceTaskPanel.Is1080p = self.NRCSafeZone.Is1080p
  self.UMG_OnlineTeammateTagPanel.Is1080p = self.NRCSafeZone.Is1080p
  self.UMG_TraceRelationTreePanel.Is1080p = self.NRCSafeZone.Is1080p
  self.PanelOpen = false
  self.bMainOpenFriend = false
  self.WorldCombatHideCompass = false
  self.CurrentAreaID = -1
  self.ObjectiveStack = {
    "UMG_Task_Track"
  }
  self.ThrowSelectBallDelayHandler = -1
  self:OnNavigationModeUpdate(_G.DataModelMgr.PlayerDataModel:GetNavigationMode() or 1)
  self:OnAddEventListener()
  self:RefreshActiveSessions()
  self.bThrowItemInitialized = false
  self:GetThrowItem()
  self.module.bAiming = false
  self:SetUpPhotoButton()
  self.bSceneLoaded = false
  self.SubUiType = {
    Map = 1,
    Bag = 2,
    Pet = 3,
    Task = 4,
    HandBook = 5,
    Friend = 6,
    Guide = 7,
    Activity = 8,
    MagicManual = 9,
    Individuation = 10,
    Dialogue = 11,
    PhotoGraph = 12,
    Shop = 13,
    Message = 14,
    FashionMall = 15,
    QuickDressUp = 16,
    QuickChat = 17
  }
  self.CanThrowSelectBall = true
  self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_CompassIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_LobbyMain_C:OnActive(...)
  _G.NRCPanelBase.OnActive(self, ...)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_DATA, self.RefreshTaskDungeon)
  self.isPcMode = self:IsPCMode()
  if self:IsPCMode() then
    local PCScale = UE4.FVector2D(0.88, 0.88)
    self.NRCSafeZone:SetRenderScale(PCScale)
    local Padding = UE4.FMargin()
    Padding.Left = -194
    Padding.Top = -73
    Padding.Right = -261
    Padding.Bottom = -70
    _G.UpdateManager:UnRegister(self.UMG_PlayerAbilities)
    self.NRCSafeZone.Slot:SetOffsets(Padding)
    self.PlayerCtrl:ModifyPanelScaleOnPC(PCScale, Padding)
    Padding.Left = -36
    Padding.Top = 0
    Padding.Right = 100
    Padding.Bottom = 100
    self.UMG_LockMagic.Slot:SetOffsets(Padding)
    Padding.Left = -36
    Padding.Top = 0
    Padding.Right = 150
    Padding.Bottom = 150
    self.UMG_LockPet.Slot:SetOffsets(Padding)
    Padding.Left = -36
    Padding.Top = 0
    Padding.Right = 150
    Padding.Bottom = 150
    self.UMG_LockBall.Slot:SetOffsets(Padding)
    Padding.Left = 0
    Padding.Top = 0
    Padding.Right = 0
    Padding.Bottom = 22
    self.UMG_MiniGame_Task.Slot:SetPadding(Padding)
    self.PCKeyFoundation:OnActive()
    self:PCKeySetting()
    self.FunctionEntry.m_rowSpan = 30
    self.FunctionEntry.m_colSpan = 46
  else
    _G.UpdateManager:UnRegister(self.PCKeyFoundation)
    self.FunctionEntry.m_rowSpan = 0
    self.FunctionEntry.m_colSpan = 17
    self.UMG_PlayerAbilities:OnActive()
  end
  self.FunctionEntry:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UMG_MiniGame_Task:OnActive()
  self.UMG_MainPet:OnActive()
  self:ApplyObjective()
  if self.bSceneLoaded then
    self:OnSceneLoaded()
  end
  self:SendShowEvent()
  self:OnInitializedQuickChat()
  self:RefreshIcons()
  self:InitUIBan()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.InitFollowUIPanel)
end

function UMG_LobbyMain_C:ShowTestAimRect(bVisible)
  local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
  local ScaleX = _G.DataConfigManager:GetPetGlobalConfig("pet_level_show_length").num / 10000
  local ScaleY = _G.DataConfigManager:GetPetGlobalConfig("pet_level_show_width").num / 10000
  self.TestAimRect:SetRenderScale(UE4.FVector2D(viewportSize.X * ScaleX, viewportSize.Y * ScaleY))
  if bVisible and GlobalConfig.ShowAimRect then
    self.TestAimRect:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TestAimRect:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMain_C:ProcessHandBook()
  if _G.BattleManager.IsMeetNewPet then
  end
end

function UMG_LobbyMain_C:OnEnable()
  Log.Debug("LobbyMainOnEnable")
  UE4Helper.SetDesiredShowCursor(false, "UMG_LobbyMain_C")
  self:SendShowEvent()
  self:ProcessHandBook()
  self.UMG_Compass:OnEnable()
  self.UMG_Hud_PerceptionPanel:OnEnable()
  self:RemoveInputBlockMappingContext("UMG_LobbyMain_C:OnEnable")
  self.PlayerCtrl:OnEnable()
  if self.module then
    self.module:OpenInteractMain()
  else
    Log.Error("UMG_LobbyMain_C:OnEnable module is nil!!!")
  end
end

function UMG_LobbyMain_C:OnDisable()
  Log.Debug("UMG_LobbyMain_C:OnDisable")
  UE4Helper.ReleaseDesiredShowCursor("UMG_LobbyMain_C")
  self:SendMainUIClose()
  _G.NRCModeManager:DoCmd(TipsModuleCmd.IsOpenAllTips, false)
  self.PlayerCtrl.UMG_Control_Joystick:OnInVisible()
  self.PlayerCtrl.UMG_Control_Camera:OnInVisible()
  self.PlayerCtrl.UMG_Aim_Joystick:OnInVisible()
  self.PlayerCtrl:OnDisable()
  self.UMG_Compass:OnDisable()
  self.PCKeyFoundation:OnDisable()
  self.BallList:OnDisable()
  self.UMG_MainPet:OnDisable()
  self.UMG_PlayerInfoHUD:SetSimpleUseListVisible(false)
  self:AddInputBlockMappingContext("UMG_LobbyMain_C:OnDisable")
end

function UMG_LobbyMain_C:OnInVisible()
  self.PlayerCtrl:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:DelaySeconds(1.2, function()
    self.PlayerCtrl:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
  self.PlayerCtrl.UMG_Control_Joystick:OnInVisible()
  self.PlayerCtrl.UMG_Control_Camera:OnInVisible()
  self.PlayerCtrl.UMG_Aim_Joystick:OnInVisible()
  self.PlayerCtrl:OnDisable()
end

function UMG_LobbyMain_C:OnTick(deltaTime)
  self.PlayerCtrl:OnTick(deltaTime)
end

function UMG_LobbyMain_C:SendMainUIClose()
  self.PanelOpen = false
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.MAINUICLOSE)
  _G.NRCAudioManager:SetMainUIOpen(false)
end

function UMG_LobbyMain_C:SendMainUIOpen()
  Log.Debug("UMG_LobbyMain_C:SendMainUIOpen")
  self.PanelOpen = true
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.MAINUIOPEN)
end

function UMG_LobbyMain_C:SendShowEvent()
  self.ControlSwitcher:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  _G.NRCAudioManager:SetMainUIOpen(true)
  self:PlayAnimation(self.Appear)
  self:RefreshTaskDungeon()
  self:RestoreWorldCombat()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListVisible, false)
  _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.OnReady, false)
  _G.NRCModeManager:DoCmd(TipsModuleCmd.IsOpenAllTips, true)
  if self:IsPCMode() then
    self.ControlSwitcher:SetActiveWidgetIndex(1)
  else
    self.ControlSwitcher:SetActiveWidgetIndex(0)
  end
end

function UMG_LobbyMain_C:RestoreWorldCombat()
  local InWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsSelfInWorldCombat)
  if not InWorldCombat then
    return
  end
  if InWorldCombat then
    self:WorldCombatEnter()
  end
end

function UMG_LobbyMain_C:RefreshActiveSessions()
  self.curPetSession = ThrowSession.ActivePetSessions
  if self.curPetSession then
    for i = 1, #self.curPetSession do
      self:OnSessionStatusChange2(self.curPetSession[i], self.curPetSession[i].Status)
      self.curPetSession[i]:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStatusChange2)
    end
  end
  self.UMG_MainPet:SetSessionList(self.curPetSession)
end

function UMG_LobbyMain_C:UseMainUIChatBubbleParent()
  self.PlayerCtrl:UseMainUIChatBubbleParent()
end

function UMG_LobbyMain_C:RefreshTaskDungeon()
  local IsInDungeon = _G.DataModelMgr.PlayerDataModel:IsInDungeon()
  local isInLeaderChallengeDungeon = false
  if IsInDungeon then
    local ID = _G.DataModelMgr.PlayerDataModel:GetDungeonID()
    if _G.BattleUtils.IsLeaderChallengeDungeon(ID) then
      self.BtnExitDungeon:SetVisibility(UE.ESlateVisibility.Collapsed)
      isInLeaderChallengeDungeon = true
    else
      local Conf = _G.DataConfigManager:GetDungeonConf(ID)
      if Conf then
        self.BtnExitDungeon:SetVisibility(Conf.main_exit and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
      else
        self.BtnExitDungeon:SetVisibility(UE.ESlateVisibility.Visible)
      end
    end
  else
    self.BtnExitDungeon:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
  if BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
    if self.UMG_CompassIcon.HomePlayerList and #self.UMG_CompassIcon.HomePlayerList > 0 then
      self.BtnExitDungeon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_CompassIcon.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.BtnExitDungeon:SetVisibility(UE.ESlateVisibility.Visible)
      self.UMG_CompassIcon.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local isInOtherHomeInDoor = _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InOtherHomeIndoor()
    if isInOtherHomeInDoor then
      self.Report:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Report:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif not IsInDungeon then
    self.BtnExitDungeon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Report:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if NRCModuleManager:DoCmd(TakePhotosModuleCmd.IfInTakePhotoState) then
    self.BtnExitDungeon:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Report:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if isInLeaderChallengeDungeon then
    self.WorldCombat_Lifebar:ShowLeaderChallengeBtn(true)
    self.Peculiarity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_GiveUp:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CharacterButton:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.WorldCombat_Lifebar:ShowLeaderChallengeBtn(false)
    self.Peculiarity:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_GiveUp:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CharacterButton:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:RefreshIcons()
  if NRCModuleManager:DoCmd(TakePhotosModuleCmd.IfInTakePhotoState) then
    self.UMG_CompassIcon.VisitListBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMain_C:OnClickCharacterButton()
  local BossChallengeInfo = BattleBossChallengeUtils.MergeBossChallengeInfo()
  _G.NRCModuleManager:DoCmd(_G.BattleUIModuleCmd.OpenMechanismValidation, nil, BossChallengeInfo)
end

function UMG_LobbyMain_C:OnBtnGiveUp()
  _G.NRCModeManager:DoCmd(LevelSelectionModuleCmd.OpenLeaveBossChallengePanel)
end

function UMG_LobbyMain_C:RefreshIcons()
  local Items = {}
  local hideFriend = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FRIEND, false) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FRIEND)
  if not hideFriend then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_haoyou1_png.img_haoyou1_png'",
      on_clicked = FPartial(self.OpenFriendPanel, self),
      redDotKey = 81,
      type = _G.Enum.FunctionEntrance.FE_FRIEND,
      IsHide = true
    })
  else
    table.insert(Items, {IsHide = true})
  end
  table.insert(Items, {IsHide = true})
  table.insert(Items, {IsHide = true})
  local hideQuickChat = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT) or FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MULTI_MAIN_MULTI_CHAT, false, false)
  if not hideQuickChat then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_kuaijieliaotian_png.img_kuaijieliaotian_png'",
      on_clicked = FPartial(self.OpenQuickChatByKey, self),
      redDotKey = 83,
      type = _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT,
      IsHide = false
    })
  end
  local hidePhoto = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO)
  if not hidePhoto then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/TakePhotos/Raw/Frames/img_xiangji1_png.img_xiangji1_png'",
      on_clicked = FPartial(self.OpenTakePhotos, self),
      redDotKey = 6,
      type = _G.Enum.FunctionEntrance.FE_TAKE_PHOTO
    })
  end
  local hideFastDressUp = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP) or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  if not hideFastDressUp or self.bMainOpenFriend then
    table.insert(Items, {
      icon = "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_shizhuang_png.img_shizhuang_png'",
      on_clicked = FPartial(self.EnterQuickDressUp, self),
      redDotKey = 405,
      type = _G.Enum.FunctionEntrance.FE_FAST_DRESSUP
    })
    self.bMainOpenFriend = false
  end
  if self.FunctionEntry:GetItemCount() == #Items then
    self.FunctionEntry._listDatas = Items
    for i = 1, #Items do
      self.FunctionEntry:RefreshItemDataByIndex(i - 1)
    end
  else
    self.FunctionEntry:InitGridView(Items)
  end
  self:PCKeySetting()
end

function UMG_LobbyMain_C:OnDestruct()
  self.bThrowItemInitialized = false
  self:OnRemoveEventListener()
  self:CancelDelay()
  if (self.ThrowSelectBallDelayHandler or 0) > 0 then
    _G.DelayManager:CancelDelayById(self.ThrowSelectBallDelayHandler)
    self.ThrowSelectBallDelayHandler = -1
  end
end

function UMG_LobbyMain_C:OnDeactive(...)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_DATA, self.RefreshTaskDungeon)
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  _G.Log.Debug("UMG_LobbyMain_C OnDeactive")
  if self:IsPCMode() then
    self.PCKeyFoundation:OnDeactive()
  else
    self.UMG_PlayerAbilities:OnDeactive()
  end
  self:SendMainUIClose()
  ReleaseForceAllChild(self)
  UE4.UNRCPlatformGameInstance.GetInstance().MinimapWidget = nil
  if self.DelayUpdateFriendRideStateId then
    _G.DelayManager:CancelDelay(self.DelayUpdateFriendRideStateId)
    self.DelayUpdateFriendRideStateId = nil
  end
end

function UMG_LobbyMain_C:UpdateStoryState(flag, bIsHomeOwner)
  local UseSelf = _G.DataModelMgr.PlayerDataModel:IsUseSelfStoryFlag(flag)
  if bIsHomeOwner == UseSelf then
    return
  end
  if 9999 == flag then
    self:UpdateCompassUIBan()
  end
end

function UMG_LobbyMain_C:OnAddEventListener()
  self:BindPlayerWorldPlayerStatusChange()
  self:AddButtonListener(self.BtnExitDungeon, self.OnBtnExitDungeon)
  self.BtnExitDungeon.OnPressed:Add(self, self.OnBtnExitDungeonPressed)
  self.BtnExitDungeon.OnReleased:Add(self, self.OnBtnExitDungeonReleased)
  self:AddButtonListener(self.Btn_GiveUp, self.OnBtnGiveUp)
  self:AddButtonListener(self.CharacterButton, self.OnClickCharacterButton)
  self:RegisterEvent(self, MainUIModuleEvent.UnLockOpenSubUiEvent, self.UnLockOpenSubUi)
  self:RegisterEvent(self, MainUIModuleEvent.LockOpenSubUiEvent, self.LockOpenSubUi)
  self:RegisterEvent(self, MainUIModuleEvent.GetLockOpenSubUiEvent, self.GetLockOpenSubUi)
  self:RegisterEvent(self, MainUIModuleEvent.UI_BIGMAP_OPEN, self.OnBigMapOpenEvent)
  self:RegisterEvent(self, MainUIModuleEvent.UI_BIGMAP_CLOSE, self.OnBigMapCloseEvent)
  self:RegisterEvent(self, MainUIModuleEvent.MainUIGameLoginEvent, self.OnRelogin)
  self:RegisterEvent(self, MainUIModuleEvent.UI_ShowFrontSight, self.ShowFrontSight)
  self:RegisterEvent(self, MainUIModuleEvent.UI_SetThrowItem, self.SetFrontSightType)
  self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, self.SetThrowAimJoystickVisible)
  self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK_CHECK, self.CheckThrowAimJoystick)
  self:RegisterEvent(self, MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, self.SetAbilityAimJoystickVisible)
  self:RegisterEvent(self, MainUIModuleEvent.UI_UPDATE_JOYSTICK_LOCK_MOVE, self.UpdateJoyStickLockMove)
  self:RegisterEvent(self, MainUIModuleEvent.UI_Refresh_MainPet, self.RefreshThrowPet)
  self:RegisterEvent(self, MainUIModuleEvent.UI_HandbookRedSystem, self.HandbookRedSystem)
  self:RegisterEvent(self, MainUIModuleEvent.UI_SetSimpleUseListByType, self.SetSimpleList)
  self:RegisterEvent(self, MainUIModuleEvent.SelectLongPressPetEvent, self.OnSelectLongPressPetEvent)
  self:RegisterEvent(self, MainUIModuleEvent.SetUiAlpha, self.ChangBG)
  self:RegisterEvent(self, MainUIModuleEvent.UI_UpdateFrontSight, self.UpdateLockPetUI)
  self:RegisterEvent(self, MainUIModuleEvent.SetWidgetDisplayConstraints, self.OnSetWidgetDisplayConstraints)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.VISIT_OWNER_CHANGED, self.OnVisitPlayerInfoSyncNotify)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryState)
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    player:AddEventListener(self, PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE, self.OnFriendRideStateChange)
  else
    Log.Error("\228\184\187\231\149\140\233\157\162\230\179\168\229\134\140\230\151\182\230\151\160player!!!")
  end
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, NPCModuleEvent.ADD_THROW_SESSION_PET, self.OnSessionStatusChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, NPCModuleEvent.ADD_THROW_SESSION_ITEM, self.OnSessionStatusChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MiniGameModuleEvent.Start, self.MiniGameStart)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MiniGameModuleEvent.End, self.MiniGameEnd)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, WorldCombatModuleEvent.Enter, self.WorldCombatEnter)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, WorldCombatModuleEvent.Exit, self.WorldCombatExit)
  self:RegisterEvent(self, MainUIModuleEvent.UI_RefreshMainPetSelectedState, self.SetMainPetSelectedGid)
  self:RegisterEvent(self, MainUIModuleEvent.TryShowOrCloseMainPetUi, self.ShowOrCloseMainPet)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, InstanceModuleEvent.RefreshMainPanelTasks, self.RefreshTaskDungeon)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, RolePlayModuleEvent.RolePlayMainPanelOpen, self.OnRolePlayMainPanelOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, RolePlayModuleEvent.RolePlayMainPanelClosed, self.OnRolePlayMainPanelClosed)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MainUIModuleEvent.OnPropPlacementPanelOpen, self.OnPropPlacementPanelOpen)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MainUIModuleEvent.OnPropPlacementPanelClose, self.OnPropPlacementPanelClose)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MainUIModuleEvent.OnLobbyMainChildVisibilityChange, self.OnChildVisibilityChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MainUIModuleEvent.RefreshJoystick, self.RefreshJoystick)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.SwitchToPet)
  self:RegisterEvent(self, MainUIModuleEvent.RefreshTaskDungeon, self.RefreshTaskDungeon)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, FriendModuleEvent.OnLeaveVisit, self.OnPlayerLeaveVisit)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, FriendModuleEvent.OnEnterVisit, self.OnPlayerEnterVisit)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, SceneEvent.EntranceVisibleZone, self.OnEntranceVisibleZone)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, FarmModuleEvent.OnEnterFarmMap, self.OnEnterFarmMap)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, MainUIModuleEvent.ReOpenQuickChat, self.OpenQuickChat)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, RelationTreeEvent.RelationInteractionNext, self.ThrowSelectBallDown)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, RelationTreeEvent.RelationInteractionPrevious, self.ThrowSelectBallUP)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.OnEnterHomeMap)
  end
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMain_C", self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.ForceRefreshWidget)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, self, self.RefreshIcons)
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MULTI_MAIN_MULTI_CHAT, self, self.RefreshIcons)
  self:AddButtonListener(self.Report.btnLevelUp, self.OnOpenVisitOtherHomeReport)
end

function UMG_LobbyMain_C:OnWorldPlayerStatusChange()
end

function UMG_LobbyMain_C:OnNavigationModeUpdate(mode)
  local Pos = self.VerticalBox_4.Slot:GetPosition()
  if mode == ProtoEnum.NavigationModeType.NMT_COMPASS then
    Pos.Y = 180
  elseif mode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
    Pos.Y = 290
  end
  self.VerticalBox_4.Slot:SetPosition(Pos)
end

function UMG_LobbyMain_C:PowerDashChargingStart(maxTime)
end

function UMG_LobbyMain_C:BindPlayerWorldPlayerStatusChange()
  if self.IsBindSceneLocalPlayer then
    return
  end
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    player:RemoveEventListener(self, PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE, self.OnFriendRideStateChange)
    player:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    player:AddEventListener(self, PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE, self.OnFriendRideStateChange)
  else
    Log.Error("\228\184\187\231\149\140\233\157\162\230\179\168\229\134\140\230\151\182\230\151\160player!!!")
  end
end

function UMG_LobbyMain_C:UnBindPlayerWorldPlayerStatusChange()
  local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnPlayerStatusChanged)
    player:RemoveEventListener(self, PlayerModuleEvent.On_FRIENDRIDE_STATE_CHANGE, self.OnFriendRideStateChange)
  end
end

function UMG_LobbyMain_C:PowerDashChargingEnd()
end

function UMG_LobbyMain_C:OnRemoveEventListener()
  self:UnBindPlayerWorldPlayerStatusChange()
  self:UnRegisterEvent(self, MainUIModuleEvent.LockOpenSubUiEvent, self.LockOpenSubUi)
  self:UnRegisterEvent(self, MainUIModuleEvent.UnLockOpenSubUiEvent, self.UnLockOpenSubUi)
  self:UnRegisterEvent(self, MainUIModuleEvent.UI_BIGMAP_OPEN, self.OnBigMapOpenEvent)
  self:UnRegisterEvent(self, MainUIModuleEvent.UI_BIGMAP_CLOSE, self.OnBigMapCloseEvent)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.PlayerBornFinish, self.OnSceneLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.ADD_THROW_SESSION_PET, self.OnSessionStatusChange)
  _G.NRCEventCenter:UnRegisterEvent(self, NPCModuleEvent.ADD_THROW_SESSION_ITEM, self.OnSessionStatusChange)
  _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.Start, self.MiniGameStart)
  _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.End, self.MiniGameEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, WorldCombatModuleEvent.Enter, self.WorldCombatEnter)
  _G.NRCEventCenter:UnRegisterEvent(self, WorldCombatModuleEvent.Exit, self.WorldCombatExit)
  _G.NRCEventCenter:UnRegisterEvent(self, RolePlayModuleEvent.RefreshMainPanelTasks, self.RefreshTaskDungeon)
  _G.NRCEventCenter:UnRegisterEvent(self, RolePlayModuleEvent.RolePlayMainPanelOpen, self.OnRolePlayMainPanelOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, RolePlayModuleEvent.RolePlayMainPanelClosed, self.OnRolePlayMainPanelClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnPropPlacementPanelOpen, self.OnPropPlacementPanelOpen)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnPropPlacementPanelClose, self.OnPropPlacementPanelClose)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.UpdateBag, self.OnBagInfoChange)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.STORY_FLAG_CHANGE, self.UpdateStoryState)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.TopBlockImcChange, self.TopBlockImcChange)
  self:RemoveButtonListener(self.Btn_GiveUp, self.OnBtnGiveUp)
  self:RemoveButtonListener(self.CharacterButton, self.OnClickCharacterButton)
  self:UnRegisterEvent(self, MainUIModuleEvent.SetUiAlpha, self.ChangBG)
  self:UnRegisterEvent(self, MainUIModuleEvent.UI_UpdateFrontSight, self.UpdateLockPetUI)
  self:UnRegisterEvent(self, MainUIModuleEvent.SetWidgetDisplayConstraints)
  if self.curPetSession and #self.curPetSession > 0 then
    for i = 1, #self.curPetSession do
      self.curPetSession[i]:RemoveEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStatusChange2)
    end
  end
  _G.NRCEventCenter:UnRegisterEvent(self, FunctionBanModuleEvent.OnUIFuncVisibilityChange, self.UIBan)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainChildVisibilityChange, self.OnChildVisibilityChange)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.RefreshJoystick, self.RefreshJoystick)
  self:UnRegisterEvent(self, MainUIModuleEvent.RefreshTaskDungeon, self.RefreshTaskDungeon)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnPlayerLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnPlayerEnterVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FarmModuleEvent.OnEnterFarmMap, self.OnEnterFarmMap)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.ReOpenQuickChat, self.OpenQuickChat)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RelationInteractionNext, self.ThrowSelectBallDown)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RelationInteractionPrevious, self.ThrowSelectBallUP)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.ForceRefreshWidget)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_TAKE_PHOTO, self, self.RefreshIcons)
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MULTI_MAIN_MULTI_CHAT, self, self.RefreshIcons)
  self:RemoveButtonListener(self.Report.btnLevelUp)
end

function UMG_LobbyMain_C:TestNiagara()
  self.NiagaraWidgetTest:SetActivate(true)
end

function UMG_LobbyMain_C:DialogTest()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle("Test"):SetContent("Test"):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnDialogResult):SetCloseOnCancel(true):SetButtonText("", "LuaText.BACK")
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_LobbyMain_C:OnBigMapOpenEvent()
end

function UMG_LobbyMain_C:PushObjective(Name)
  local Found = false
  for _, Objective in ipairs(self.ObjectiveStack) do
    if Name == Objective then
      Found = true
      break
    end
  end
  if Found then
    Log.Error("\232\175\183\229\139\191\233\135\141\229\164\141\230\143\146\229\133\165\229\144\140\228\184\128\228\184\170\229\133\131\231\180\160", Name)
  else
    self.ObjectiveStack[#self.ObjectiveStack + 1] = Name
  end
  self:ApplyObjective()
end

function UMG_LobbyMain_C:PopObjective(Name)
  if self.ObjectiveStack[#self.ObjectiveStack] ~= Name then
    Log.Error("\230\179\168\230\132\143\239\188\140\230\130\168\232\166\129\231\167\187\233\153\164\231\154\132\229\133\131\231\180\160\228\184\141\230\152\175\230\156\128\229\144\142\228\184\128\228\184\170\229\133\131\231\180\160", Name, self.ObjectiveStack[#self.ObjectiveStack])
  end
  table.removeValue(self.ObjectiveStack, Name)
  self:ApplyObjective()
end

function UMG_LobbyMain_C:ApplyObjective()
  self.Objectives:SetActiveWidgetByWidgetName(self.ObjectiveStack[#self.ObjectiveStack])
end

function UMG_LobbyMain_C:MiniGameStart()
  self.inMiniGame = true
  self:PushObjective("UMG_MiniGame_Task")
end

function UMG_LobbyMain_C:MiniGameEnd()
  self.inMiniGame = nil
  self:PopObjective("UMG_MiniGame_Task")
end

function UMG_LobbyMain_C:WorldCombatEnter()
  self.WorldCombatHideCompass = true
  self:MainUIBlockByArea(nil)
  if _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsInNightmare) then
    return
  end
  self:PushObjective("UMG_WorldCombat_Task")
end

function UMG_LobbyMain_C:WorldCombatExit()
  self.WorldCombatHideCompass = false
  self:MainUIBlockByArea(nil)
  if _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.IsInNightmare) then
    return
  end
  self:PopObjective("UMG_WorldCombat_Task")
end

function UMG_LobbyMain_C:OnBigMapCloseEvent()
end

function UMG_LobbyMain_C:OnSceneLoaded()
  self.bSceneLoaded = true
  if not self.isActive then
    return
  end
  self.MainPetSelectedGid = 0
  self:ShowFrontSight(false)
  self.curThrowSession = nil
  self.curPetSession = {}
  self:RefreshTaskDungeon()
  self:ChangeLobbyMainStyle(true)
  self.UMG_Hud_PerceptionPanel:OnSceneLoad()
  self:UpdateBindInputAction()
end

function UMG_LobbyMain_C:MiniMapTimeSync(TimeSync)
  self.UMG_MinimapTime:SetGameTime(TimeSync)
end

function UMG_LobbyMain_C:OnBtnExitDungeon()
  if _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_UI_DUNGEON_EXIT, true, true) then
    return
  end
  if BigMapUtils.IsHomeScene(SceneUtils.GetSceneID()) then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1192, "UMG_LobbyMain_C:OnBtnExitDungeon")
    HomeIndoorSandbox.Module:ReqLeavePlayerHomeIndoor()
  else
    self.PlayerCtrl.UMG_Aim_Joystick:OnInVisible()
    _G.NRCModuleManager:DoCmd(InstanceModuleCmd.OpenLeavePanel)
  end
end

function UMG_LobbyMain_C:OnBtnExitDungeonPressed()
  self:PlayAnimation(self.BtnExitDungeon_Press)
end

function UMG_LobbyMain_C:OnBtnExitDungeonReleased()
  self:PlayAnimation(self.BtnExitDungeon_Up)
end

function UMG_LobbyMain_C:LeaveAimState()
  self.PlayerCtrl.UMG_Aim_Joystick:ReleaseAim()
end

function UMG_LobbyMain_C:OnBtnChatClick()
end

function UMG_LobbyMain_C:OnPlayerStatusChanged(status, value, opCode)
  if status ~= ProtoEnum.WorldPlayerStatusType.WPST_LANDED then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSuitPopupPanel, nil, true, false)
  end
  if status == ProtoEnum.WorldPlayerStatusType.WPST_SLIDING then
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
  end
end

function UMG_LobbyMain_C:OnFriendRideStateChange()
  if self.DelayUpdateFriendRideStateId then
    return
  end
  self.DelayUpdateFriendRideStateId = _G.DelayManager:DelayFrames(1, function()
    if self.UMG_MainPet then
      self.UMG_MainPet:OnForceUpdateFriendRideState()
    end
    if self.MainPetScrollList then
      self.MainPetScrollList:OnForceUpdateFriendRideState()
    end
    _G.DelayManager:CancelDelay(self.DelayUpdateFriendRideStateId)
    self.DelayUpdateFriendRideStateId = nil
  end)
end

function UMG_LobbyMain_C:OnGameSecureAreaChanage()
end

function UMG_LobbyMain_C:MainUIBlockByArea(_zoneId)
  _zoneId = _zoneId or self.CurrentAreaID
  if 0 ~= _zoneId and -1 ~= _zoneId then
    local AreaConf = _G.DataConfigManager:GetAreaFuncConf(_zoneId)
    local _areaId = AreaConf and AreaConf.area_id[1]
    if nil ~= _areaId then
      local blockTypeList = {
        1,
        1,
        1,
        1,
        1
      }
      local blockInfoTable = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.AREA_UI_CONF)
      local blockInfoDatas = blockInfoTable:GetAllDatas()
      for k, blockInfo in pairs(blockInfoDatas) do
        if k == _areaId and blockInfo.BlockType1 == _G.Enum.MainBlockType.COMPS_BLOCK then
          blockTypeList[1] = 0
          self.UMG_Compass:Hide()
          break
        end
      end
      if 1 == blockTypeList[1] then
        self.UMG_Compass:Show()
      else
        self.UMG_Compass:Hide()
      end
    else
      self.UMG_Compass:Show()
    end
  end
  if self.WorldCombatHideCompass then
    self.UMG_Compass:Hide()
  end
  self.CurrentAreaID = _zoneId
end

function UMG_LobbyMain_C:ShowCompass(bShow)
  if bShow then
    self.UMG_Compass:Show()
  else
    self.UMG_Compass:Hide()
  end
end

function UMG_LobbyMain_C:OnAnimationFinished(Animation)
  if Animation == self.CheckMap_Open then
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
  elseif Animation == self.Appear then
    self:SendMainUIOpen()
    self.ControlSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyMain_C:SetUpPhotoButton()
end

function UMG_LobbyMain_C:OpenTakePhotos()
  self:EnterPhotoGraph()
end

function UMG_LobbyMain_C:OpenChat()
  NRCModuleManager:DoCmd(FriendModuleCmd.OnCmdSetIsPanelMoveCamera, true)
  NRCModuleManager:DoCmd(MainUIModuleCmd.TryOpenChatPanel)
end

function UMG_LobbyMain_C:OpenFastDressUp()
  _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenAppearanceClosetPanel, nil, true)
end

function UMG_LobbyMain_C:OpenQuickChatByKey(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.QuickChat)
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT, true)
  local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT)
  if isBan or isHide then
    return
  end
  local Item = self.FunctionEntry:GetItemByIndex(3)
  if Item and Item:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OpenQuickChat()
  return true
end

function UMG_LobbyMain_C:OpenQuickChat()
  Log.Debug("UMG_LobbyMain_C:OpenQuickChat")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenQuickChatBubble)
  self.UMG_PlayerAbilities:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PCKeyFoundation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.FunctionEntry:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_PlayerInfoHUD:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetClickState(false)
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LobbyMain_C:OpenQuickChat")
end

function UMG_LobbyMain_C:OpenFriendPanel()
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenFriendUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  Log.Debug("UMG_LobbyMain_C:OpenFriendPanel")
  self.bMainOpenFriend = true
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LobbyMain_C:OpenFriendPanel")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenMainPanel)
end

function UMG_LobbyMain_C:CameraSetIsCanClick()
  self.PlayerCtrl.UMG_Control_Camera:SetIsCanClick(true)
end

function UMG_LobbyMain_C:SetClickState(IsCanClick)
  if IsCanClick then
    self.Under:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.On:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Left:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Hud_PerceptionPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_TraceTaskPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_OnlineTeammateTagPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_InteractMarkPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_TraceRelationTreePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CompassIcon.UMG_Minimap:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PlayerCtrl.UMG_Control_Camera:SetIsCanClick(false)
  else
    self.Under:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.On:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Left:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Right:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_Hud_PerceptionPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_TraceTaskPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_OnlineTeammateTagPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_InteractMarkPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_TraceRelationTreePanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_CompassIcon.UMG_Minimap:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.PlayerCtrl.UMG_Control_Camera:SetIsCanClick(true)
  end
end

function UMG_LobbyMain_C:CloseQuickChat()
  Log.Debug("UMG_LobbyMain_C:CloseQuickChat")
  self.UMG_PlayerAbilities:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PCKeyFoundation:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.FunctionEntry:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.UMG_PlayerInfoHUD:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SetClickState(true)
end

function UMG_LobbyMain_C:ShowFrontSight(show, cancelType, isAbility)
  self.IsShowFrontSight = show
  if self.PreFrontSightType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    if show then
      self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockBall:OnShow()
    else
      self.UMG_LockBall:PlayLockOutAnim()
      self.UMG_LockBall:ClearActorCache()
    end
  elseif self.PreFrontSightType == _G.MainUIModuleEnum.MainUIChooseType.PET or isAbility then
    if show then
      self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockPet:OnShow(isAbility)
    else
      if self.UMG_LockPet:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
        self.UMG_LockPet:OnCancel(1)
        self.UMG_LockPet:ClearActorCache()
      end
      if self.UMG_LockBall:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
        self.UMG_LockBall:PlayLockOutAnim()
        self.UMG_LockBall:ClearActorCache()
      end
    end
  elseif self.PreFrontSightType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    local magic_type
    local itemId = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetSelectedItemId)
    local itemInfo = _G.DataConfigManager:GetBagItemConf(itemId)
    if itemInfo and itemInfo.magic_id then
      local magicConf = _G.DataConfigManager:GetMagicBaseConf(itemInfo.magic_id, true)
      if magicConf and magicConf.magic_type then
        magic_type = magicConf.magic_type
      end
    end
    if magic_type == ProtoEnum.SceneMagicType.SMT_LIQUEFY then
      if show then
        self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LiqueFaction:OnShow(self)
      else
        self.UMG_LiqueFaction:OnCancel(1)
        self.UMG_LiqueFaction:ClearActorCache()
      end
    elseif magic_type == ProtoEnum.SceneMagicType.SMT_LIGHT then
      if show then
        self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.UMG_LightMagic:OnShow(self)
      else
        self.UMG_LightMagic:OnCancel(1)
      end
    elseif show then
      self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_LockMagic:OnShow()
    else
      self.UMG_LockMagic:OnCancel(1)
      self.UMG_LockMagic:ClearActorCache()
    end
  elseif show then
    self.UMG_LockMagic:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_LockPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LockBall:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LiqueFaction:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LightMagic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LockMagic:OnShow()
  else
    self.UMG_LockMagic:OnCancel(1)
    self.UMG_LockMagic:ClearActorCache()
  end
  if not show then
    self.PreFrontSightType = self.SightType
  end
end

function UMG_LobbyMain_C:UpdateLockPetUI(isCollision)
  self.UMG_LockPet:UpdateUI(isCollision)
end

function UMG_LobbyMain_C:SetFrontSightType(type, itemInfo)
  if not self.IsShowFrontSight then
    self.PreFrontSightType = type
  end
  self.SightType = type
  if type == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    self:SetMainPetSelectedGid(0)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, 0)
    self.UMG_MainPet:RefreshSelectedState(false)
    if self:IsPCMode() then
      self.PCKeyFoundation:SetMagicSelected(false)
      self.PCKeyFoundation:SetEquipItemSelected(true)
    else
      self.UMG_PlayerInfoHUD:SetMagicSelected(false)
      self.UMG_PlayerInfoHUD:SetEquipItemSelected(true)
    end
  elseif type == _G.MainUIModuleEnum.MainUIChooseType.PET then
    if 3 ~= self.Switcher:GetActiveWidgetIndex() then
      self:SetMainPetSelectedGid(itemInfo.gid)
    end
    if self:IsPCMode() then
      self.PCKeyFoundation:SetMagicSelected(false)
      self.PCKeyFoundation:SetEquipItemSelected(false)
    else
      self.UMG_PlayerInfoHUD:SetMagicSelected(false)
      self.UMG_PlayerInfoHUD:SetEquipItemSelected(false)
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    player:SendEvent(PlayerModuleEvent.ON_THROW_INFO_CHANGE, type, itemInfo)
  elseif type == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    self:SetMainPetSelectedGid(0)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, 0)
    self.UMG_MainPet:RefreshSelectedState(false)
    if self:IsPCMode() then
      self.PCKeyFoundation:SetMagicSelected(true)
      self.PCKeyFoundation:SetEquipItemSelected(false)
    else
      self.UMG_PlayerInfoHUD:SetMagicSelected(true)
      self.UMG_PlayerInfoHUD:SetEquipItemSelected(false)
    end
  end
end

function UMG_LobbyMain_C:OnBagInfoChange()
  if not self.bThrowItemInitialized then
    Log.Info("Refresh ThrowItem when bag info received")
  end
  self:GetThrowItem()
  self:OnEnterHomeMap()
end

function UMG_LobbyMain_C:GetThrowItem()
  local BagModule = _G.NRCModuleManager:GetModule("BagModule")
  if not BagModule then
    Log.Warning("Cannot found bag module")
    return
  end
  local BagInfo = BagModule:GetData():GetBagInfo()
  if not BagInfo then
    Log.Warning("Cannot found bag info, may be wait for server packets")
    return
  end
  if self.bThrowItemInitialized then
    return
  end
  self.bThrowItemInitialized = true
  Log.Info("Refresh ThrowItem")
  local curThrowItemInfo = _G.DataModelMgr.PlayerDataModel:GetThrowItemInfo()
  if curThrowItemInfo.cur_selected_throw_item ~= nil then
    local throwGid = curThrowItemInfo.cur_selected_throw_item.cur_selected_gid
    local throwType = curThrowItemInfo.cur_selected_throw_item.cur_selected_throw_type
    local magicGid = curThrowItemInfo.cur_selected_magic_item_gid
    local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_SHENHE_ADVANCE_ROLE)
    local magicItemInfo
    if Flags then
      magicItemInfo = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, 100701)
    else
      magicItemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, magicGid)
    end
    if not magicItemInfo then
      local MagicItemArray = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, ProtoEnum.BagItemType.BI_MAGIC)
      if MagicItemArray then
        for k, Item in ipairs(MagicItemArray) do
          magicItemInfo = magicItemInfo or Item
          if Item.bag_item_flags then
            if 0 ~= Item.bag_item_flags & 1 then
              Log.Info("[MAGIC] Client equip magic item", Item.id, Item.type, Item.bag_item_flags)
              magicItemInfo = Item
            end
          else
            Log.Info("[MAGIC] Client item not bag_item_flags", Item.id, Item.type)
          end
        end
      end
      if not magicItemInfo then
        Log.Info("[MAGIC] No Magic Item")
      end
    end
    _G.NRCModuleManager:DoCmd(BagModuleCmd.SetEquipMagicInfo, magicItemInfo, false)
    if self:IsPCMode() then
      self.PCKeyFoundation:UpdateEquipMagicItemInfo(false)
      self.PCKeyFoundation:UpdateEquipItemInfo(false)
    else
      self.UMG_PlayerInfoHUD:UpdateEquipMagicItemInfo(false)
      self.UMG_PlayerInfoHUD:UpdateEquipItemInfo(false)
    end
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    local throwItemInfo = {}
    local throwClientType = 0
    if throwType == _G.ProtoEnum.ThrowType.THROW_PET then
      throwClientType = 1
      for i = 1, #petInfo do
        if petInfo[i].gid == throwGid then
          throwItemInfo = petInfo[i]
        end
      end
      self.UMG_MainPet:RefreshSelectedState(false)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetSelectedPetGid, throwGid)
    elseif throwType == _G.ProtoEnum.ThrowType.THROW_BAGITEM then
      throwClientType = 0
      throwItemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, throwGid)
      if self:IsPCMode() then
        self.PCKeyFoundation:UpdateEquipItemInfo(true)
      else
        self.UMG_PlayerInfoHUD:UpdateEquipItemInfo(true)
      end
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetSelectedPetGid, 0)
    elseif throwType == _G.ProtoEnum.ThrowType.THROW_MAGIC then
      throwClientType = 2
      throwItemInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByGid, magicGid)
      if self:IsPCMode() then
        self.PCKeyFoundation:UpdateEquipMagicItemInfo(true)
      else
        self.UMG_PlayerInfoHUD:UpdateEquipMagicItemInfo(true)
      end
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SetSelectedPetGid, -1)
    end
    self:DispatchEvent(MainUIModuleEvent.UI_SetThrowItem, throwClientType, throwItemInfo)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.UI_SetThrowItem, throwClientType, throwItemInfo)
    self.UMG_MainPet:RefreshSelectedState(false)
  end
end

function UMG_LobbyMain_C:UpdateJoyStickLockMove(visible)
  if visible then
    if self.PlayerCtrl.bLockMove then
      self.PlayerCtrl.bLockMove = false
    end
  else
    self.PlayerCtrl.UMG_Control_Joystick:OnInVisible()
    self.PlayerCtrl.bLockMove = true
  end
end

function UMG_LobbyMain_C:SetAbilityAimJoystickVisible(visible, abilityID)
  self.PlayerCtrl:SetAimJoystickMode(MainUIModuleEnum.ShowAimJoystick.Ability, abilityID)
  self:SetAimJoystickVisible(visible)
end

function UMG_LobbyMain_C:SetThrowAimJoystickVisible(visible, mode)
  self.PlayerCtrl:SetAimJoystickMode(mode or MainUIModuleEnum.ShowAimJoystick.Throw)
  self:SetAimJoystickVisible(visible)
end

function UMG_LobbyMain_C:GetAimJoystickPointerIndex(mode)
  mode = mode or MainUIModuleEnum.ShowAimJoystick.Throw
  if mode == MainUIModuleEnum.ShowAimJoystick.Throw then
    return self.UMG_PlayerAbilities.AbilitySlot_Throw.Btn_Slot:GetMouseCapturePointerIndex()
  else
    return self.UMG_PlayerAbilities.AbilitySlot_RideAbility.Btn_Slot:GetMouseCapturePointerIndex()
  end
end

function UMG_LobbyMain_C:CheckThrowAimJoystick()
  local UMG_Aim_Joystick = self.PlayerCtrl.UMG_Aim_Joystick
  local List = UMG_Aim_Joystick.TouchListenList
  if List and 0 == #List and not UMG_Aim_Joystick:IsPCMode() then
    UMG_Aim_Joystick:OnCancelBtnClicked()
  end
end

function UMG_LobbyMain_C:SetAimJoystickVisible(visible)
  self.PlayerCtrl:SetAimJoystickVisible(visible)
  if visible then
    self.module.bAiming = true
    self.ControlSwitcher:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_PlayerInfoHUD:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if self.UMG_Task_Track:IsVisible() then
      self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
    self.UMG_TraceTaskPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_OnlineTeammateTagPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_TraceRelationTreePanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_Hud_PerceptionPanel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_CompassIcon:Show(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.module.bAiming = false
    self.ControlSwitcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if not _G.NRCModuleManager:GetModule("FriendModule"):HasPanel("QuickChatBubble") then
      self.UMG_PlayerInfoHUD:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_PET_LIST) then
    end
    if self.UMG_Task_Track:IsVisible() then
      self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self.UMG_TraceTaskPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_OnlineTeammateTagPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_TraceRelationTreePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Hud_PerceptionPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CompassIcon:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.module:ShowNPCLv(false)
  end
  self:ShowTestAimRect(visible)
end

function UMG_LobbyMain_C:SetThrowHitTestInvisible(bool, bThrowing)
  if bool then
    if not bThrowing then
      self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif self:IsPCMode() then
      self.PCKeyFoundation:ChangeHUDMagicState(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PCKeyFoundation:ChangeEquipItemState(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.UMG_PlayerInfoHUD:ChangeHUDMagicState(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.UMG_PlayerInfoHUD:ChangeEquipItemState(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  elseif not bThrowing then
    self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif self:IsPCMode() then
    self.PCKeyFoundation:ChangeHUDMagicState(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PCKeyFoundation:ChangeEquipItemState(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_PlayerInfoHUD:ChangeHUDMagicState(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_PlayerInfoHUD:ChangeEquipItemState(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyMain_C:OnTaskClicked()
  self.UMG_Compass:OnTaskClicked()
end

function UMG_LobbyMain_C:RefreshTaskText()
  local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_TASK_TEXT)
  if bHide then
    if self.UMG_Task_Track:IsVisible() then
      self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.module.bAiming then
    if self.UMG_Task_Track:IsVisible() then
      self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    end
  elseif self.UMG_Task_Track:IsVisible() then
    self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyMain_C:RefreshJoystick()
  local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_ANALOG_STICK)
  if bHide then
    if self.PlayerCtrl and self.PlayerCtrl.UMG_Control_Joystick and self.PlayerCtrl.UMG_Control_Joystick:IsVisible() then
      self.PlayerCtrl.UMG_Control_Joystick:OnInVisible()
      self.PlayerCtrl.UMG_Control_Joystick:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif self.PlayerCtrl and self.PlayerCtrl.UMG_Control_Joystick then
    self.PlayerCtrl.UMG_Control_Joystick:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_LobbyMain_C:RefreshVitality()
  local bHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_STA_BAR)
  if bHide then
    self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_Vitality, "FE_STA_BAR")
  else
    self.uiVisibilityConstraint:RemoveWidgetDisplayConstraintsByFactor("FE_STA_BAR")
  end
end

function UMG_LobbyMain_C:RefreshThrowPet(type, petDatas)
  self.UMG_MainPet:RefreshMainPetInfo(type, petDatas)
  if 3 ~= self.Switcher:GetActiveWidgetIndex() then
    self.MainPetScrollList:InitPanelInfo(true)
  end
end

function UMG_LobbyMain_C:TipShowOrHide(On)
  self.UMG_MainPet:TipShowOrHide(On)
end

function UMG_LobbyMain_C:ShowOrCloseMainPet(_Show)
  if _Show then
    self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UMG_MainPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMain_C:HandbookRedSystem()
end

function UMG_LobbyMain_C:IsShowRed()
end

function UMG_LobbyMain_C:OnSessionStatusChange(session)
  if session.petData then
  else
    self.UMG_LockBall.throwItemSession = session
  end
  if not session:HasListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStatusChange2) then
    session:AddEventListener(self, ThrowSessionEvent.OnStatusChanged, self.OnSessionStatusChange2)
  end
  if session.Status == ThrowSessionStatusEnum.PostInteract then
    self:OnSessionStatusChange2(session, session.Status)
  end
end

function UMG_LobbyMain_C:OnSessionStatusChange2(session, status)
  if session.petData then
    self.UMG_MainPet:UpdataRecycleState(session, status)
    self.MainPetScrollList:UpdataRecycleState(session, status)
    if status == ThrowSessionStatusEnum.InHand or status == ThrowSessionStatusEnum.Destroyed then
      if session.petData.gid == self:GetCurSelectedGid() then
        if self.isPcMode then
          self.PCKeyFoundation:SetThrowOrRecycle(false)
          self.PCKeyFoundation.AbilitySlot_Throw.UMG_Ability_Slot_Throw.Btn_Slot:SetIsEnabled(true)
        else
          self.UMG_PlayerAbilities:SetThrowOrRecycle(false)
          self.UMG_PlayerAbilities.AbilitySlot_Throw.Btn_Slot:SetIsEnabled(true)
        end
      end
    elseif session.petData.gid == self:GetCurSelectedGid() then
      if self:IsPCMode() then
        self.PCKeyFoundation:SetThrowOrRecycle(true)
      else
        self.UMG_PlayerAbilities:SetThrowOrRecycle(true)
      end
    end
    if #self.curPetSession > 0 then
      for i = 1, #self.curPetSession do
        if self.curPetSession[i].Status == ThrowSessionStatusEnum.Destroyed then
          local Removed = table.remove(self.curPetSession, i)
          self.UMG_MainPet:SetSessionList(self.curPetSession)
          return
        end
        if self.curPetSession[i] == session then
          return
        end
      end
      table.insert(self.curPetSession, session)
      self.UMG_MainPet:SetSessionList(self.curPetSession)
    else
      table.insert(self.curPetSession, session)
      self.UMG_MainPet:SetSessionList(self.curPetSession)
    end
  else
    self.UMG_LockBall.throwItemSession = session
    if status == ThrowSessionStatusEnum.InAir then
    end
  end
end

function UMG_LobbyMain_C:SetMainPetSelectedGid(gid)
  self.MainPetSelectedGid = gid
  self.UMG_MainPet:SetSelectedGid(gid)
end

function UMG_LobbyMain_C:GetCurSelectedGid()
  return self.UMG_MainPet:GetCurSelectedGid()
end

function UMG_LobbyMain_C:GetCurPetSession()
  return self.curPetSession
end

function UMG_LobbyMain_C:OnRelogin()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.FollowUIRelogin)
end

function UMG_LobbyMain_C:ShowEvoTip()
end

function UMG_LobbyMain_C:GetEvo()
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetList then
    for i, petData in pairs(battlePetList) do
      local data = PetUtils.GetLevelUpData(petData)
      if data and data.evoType == true then
        return true
      end
    end
  end
  return nil
end

function UMG_LobbyMain_C:SetSimpleList(type)
  self.UMG_PlayerInfoHUD:SetSimpleListInfo(type)
  self.UMG_PlayerInfoHUD:SetSimpleUseListVisible(true)
end

function UMG_LobbyMain_C:OnSelectLongPressPetEvent(_index)
  self.UMG_MainPet:SelectLongPressPet(_index)
end

function UMG_LobbyMain_C:SetSimpleUseListVisible(bool)
  self.UMG_PlayerInfoHUD:SetSimpleUseListVisible(bool)
end

function UMG_LobbyMain_C:ChangeCompassIconByFunctionBan(bNew)
  if bNew then
    self.UMG_CompassIcon:Show()
  else
    self.UMG_CompassIcon:Hide()
  end
end

function UMG_LobbyMain_C:ChangeTaskTrackByFunctionBan(bNew)
  if bNew then
    self.Objectives:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Objectives:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMain_C:ChangeHUDMagicByFunctionBan(bShow)
  if self:IsPCMode() then
    self.PCKeyFoundation:ChangeHUDMagicByFunctionBan(bShow)
  else
    self.UMG_PlayerInfoHUD:ChangeHUDMagicByFunctionBan(bShow)
  end
end

function UMG_LobbyMain_C:ChangeLobbyMainStyle(bNew)
  if bNew then
    self.UMG_CompassIcon:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_CompassIcon:InitUI()
  else
    Log.Warning("\228\184\187\231\149\140\233\157\162\229\138\159\232\131\189\229\183\178\231\167\187\233\153\164")
  end
end

function UMG_LobbyMain_C:OpenWorldWardrobe(bOpen)
  if bOpen then
    self.UMG_CompassIcon:Hide(UE4.ESlateVisibility.Collapsed)
    self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LobbyPropTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.UMG_CompassIcon:Show(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Task_Track:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_LobbyPropTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyMain_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_LobbyMain_C:AddInputBlockMappingContext(Reason)
  Log.InfoFormat("MainUIModule:AddInputBlockMappingContext, Reason = %s", Reason)
  if self.isGmDisable then
    return
  end
  if self.lockOpenDelayHandle then
    _G.DelayManager:CancelDelayById(self.lockOpenDelayHandle)
    self.lockOpenDelayHandle = nil
  end
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:DisableInputMappingContext()
    self.UMG_MainPet:OnPCSelectPet0(1)
    if self:IsPCMode() then
      self.PCKeyFoundation.AbilitySlot_Throw.UMG_Ability_Slot_Throw:ThrowCancel(true)
    end
  end
  local PlayerControllIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PlayerControll")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, PlayerControllIMC)
  if self:IsPCMode() and self.PCKeyFoundation then
    self.PCKeyFoundation:UiRemoveInputMappingContext()
  end
end

function UMG_LobbyMain_C:RemoveInputBlockMappingContext(Reason)
  Log.InfoFormat("MainUIModule:RemoveInputBlockMappingContext, Reason = %s", Reason)
  self.lockOpenSubUi = nil
  local PlayerControllIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_PlayerControll")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, PlayerControllIMC, -3)
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
  end
  if self:IsPCMode() then
    if self.PCKeyFoundation then
      self.PCKeyFoundation:UiRemoveInputMappingContext()
      self.PCKeyFoundation:UiAddInputMappingContext()
    end
  elseif self.UMG_PlayerAbilities and UE4.UObject.IsValid(self.UMG_PlayerAbilities) then
    self.UMG_PlayerAbilities:UiRemoveInputMappingContext()
    self.UMG_PlayerAbilities:UiAddInputMappingContext()
  end
end

function UMG_LobbyMain_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MainUIDefault", self.imcPriority)
  if mappingContext then
    mappingContext:EnableInputMappingContext(self.imcPriority)
    local actions = {
      {
        name = "IA_OpenMapUI",
        method = "OpenMapUI"
      },
      {
        name = "IA_OpenBagUI",
        method = "OpenBagUI"
      },
      {
        name = "IA_OpenPetUI",
        method = "OpenPetUI"
      },
      {
        name = "IA_OpenTaskUI",
        method = "OpenTaskUI"
      },
      {
        name = "IA_OpenHandbookUI",
        method = "OpenHandbookUI"
      },
      {
        name = "IA_OpenFriendUI",
        method = "OpenFriendUI"
      },
      {
        name = "IA_OpenGuideUI",
        method = "OpenGuideUI"
      },
      {
        name = "IA_OpenActivityUI",
        method = "OpenActivityUI"
      },
      {
        name = "IA_OpenMagicManualUI",
        method = "OpenMagicManualUI"
      },
      {
        name = "IA_Individuation",
        method = "OpenIndividuationUI"
      },
      {
        name = "IA_ExitDungeon",
        method = "ExitDungeon"
      },
      {
        name = "IA_PgEnter",
        method = "EnterPhotoGraph"
      },
      {
        name = "IA_OpenShopUI",
        method = "OpenShopUI"
      },
      {
        name = "IA_OpenFashionMallUI",
        method = "OpenFashionMallUI"
      },
      {
        name = "IA_MessageDetails",
        method = "HandleMessage"
      },
      {
        name = "IA_QuickDressUP",
        method = "EnterQuickDressUp"
      },
      {
        name = "IA_InteractionNext",
        method = "ThrowSelectBallDown"
      },
      {
        name = "IA_InteractionPrevious",
        method = "ThrowSelectBallUP"
      },
      {
        name = "IA_QuickChat",
        method = "OpenQuickChatByKey"
      }
    }
    for i = 1, 6 do
      actions[#actions + 1] = {
        name = "IA_SelectPetStart_" .. i,
        method = "SelectPetStart" .. i
      }
      actions[#actions + 1] = {
        name = "IA_SelectPetEnd_" .. i,
        method = "SelectPetEnd" .. i
      }
    end
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
    mappingContext:BindAction("MoveForward")
    mappingContext:BindAction("MoveRight")
    mappingContext:BindAction("IA_MoveBackward")
    mappingContext:BindAction("IA_MoveLeft")
    mappingContext:BindAction("IA_MagicSelectStart")
    mappingContext:BindAction("IA_MagicSelectEnd")
    mappingContext:BindAction("IA_BallSelectStart")
    mappingContext:BindAction("IA_BallSelectEnd")
    mappingContext:BindAction("IA_OpenSeedBag")
    mappingContext:BindAction("IA_Shovel_MainUIDefault")
    mappingContext:BindAction("IA_AbilitySlotHomePetFood")
    mappingContext:BindAction("IA_AbilitySlotHomePetCall")
  end
end

function UMG_LobbyMain_C:UnBindInputAction()
  local actions = {
    {
      name = "IA_OpenMapUI"
    },
    {
      name = "IA_OpenBagUI"
    },
    {
      name = "IA_OpenPetUI"
    },
    {
      name = "IA_OpenTaskUI"
    },
    {
      name = "IA_OpenHandbookUI"
    },
    {
      name = "IA_OpenFriendUI"
    },
    {
      name = "IA_OpenGuideUI"
    },
    {
      name = "IA_OpenActivityUI"
    },
    {
      name = "IA_OpenMagicManualUI"
    },
    {
      name = "IA_Individuation"
    },
    {
      name = "IA_ExitDungeon"
    },
    {
      name = "IA_OpenShopUI"
    },
    {
      name = "IA_OpenFashionMallUI"
    },
    {
      name = "IA_MessageDetails"
    },
    {
      name = "IA_QuickDressUP"
    },
    {
      name = "IA_SelectPetStart_1"
    },
    {
      name = "IA_SelectPetStart_2"
    },
    {
      name = "IA_SelectPetStart_3"
    },
    {
      name = "IA_SelectPetStart_4"
    },
    {
      name = "IA_SelectPetStart_5"
    },
    {
      name = "IA_SelectPetStart_6"
    },
    {
      name = "IA_SelectPetEnd_1"
    },
    {
      name = "IA_SelectPetEnd_2"
    },
    {
      name = "IA_SelectPetEnd_3"
    },
    {
      name = "IA_SelectPetEnd_4"
    },
    {
      name = "IA_SelectPetEnd_5"
    },
    {
      name = "IA_SelectPetEnd_6"
    },
    {
      name = "IA_InteractionPrevious"
    },
    {
      name = "IA_InteractionNext"
    },
    {
      name = "IA_QuickChat"
    },
    {
      name = "IA_AbilitySlotHomePetFood"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  end
  local MainDefaultIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MainUIDefault")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, MainDefaultIMC)
end

function UMG_LobbyMain_C:UpdateBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_MainUIDefault")
  if mappingContext and not mappingContext:IsMappingContextEnable() then
    self:BindInputAction()
    self.UMG_Task_Track:BindInputAction()
    self.UMG_CompassIcon:BindInputAction()
    self.PlayerCtrl:UpdateBindInputAction()
    if self:IsPCMode() then
      self.PCKeyFoundation:UpdateBindInputAction()
    else
      self.UMG_PlayerInfoHUD:BindInputAction()
      self.UMG_PlayerAbilities:UpdateBindInputAction()
    end
  end
end

function UMG_LobbyMain_C:OnPCSelectPetOrMagic(action_type, index)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    self.UMG_HUDSimpleList:OnPCSelectPet0(action_type, index)
    return
  elseif player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    local statusId = ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING
    local customParams = player.statusComponent:GetCustomParams(statusId)
    if customParams and customParams.throw_aim_param then
      local throwType = customParams.throw_aim_param.throw_item_type
      if throwType == _G.Enum.BagItemType.BI_ITEM then
        self.BallList:OnPCSelectPet0(action_type, index)
        return
      end
    end
    if customParams and customParams.throw_aim_param then
      local throwType = customParams.throw_aim_param.throw_item_type
      if throwType == _G.Enum.BagItemType.BI_PET_BALL then
        if not self.MainPetScrollList:IsScrollIng() then
          if self.MainPetScrollList:IsCurMainTeamIndex() then
            self.UMG_MainPet:OnPCSelectPet0(action_type, index)
          end
          self.MainPetScrollList:OnPCSelectPet0(action_type, index)
        end
        return
      end
    end
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PET_LIST, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_PET_LIST, true)
  if isBan or isHide then
    return
  elseif not self.MainPetScrollList:IsScrollIng() then
    self.UMG_MainPet:OnPCSelectPet0(action_type, index)
    if self.MainPetScrollList:IsCurMainTeamIndex() then
      self.MainPetScrollList:OnPCSelectPet0(action_type, index)
    end
  end
end

function UMG_LobbyMain_C:SelectPetStart1()
  self:OnPCSelectPetOrMagic(0, 1)
end

function UMG_LobbyMain_C:SelectPetStart2()
  self:OnPCSelectPetOrMagic(0, 2)
end

function UMG_LobbyMain_C:SelectPetStart3()
  self:OnPCSelectPetOrMagic(0, 3)
end

function UMG_LobbyMain_C:SelectPetStart4()
  self:OnPCSelectPetOrMagic(0, 4)
end

function UMG_LobbyMain_C:SelectPetStart5()
  self:OnPCSelectPetOrMagic(0, 5)
end

function UMG_LobbyMain_C:SelectPetStart6()
  self:OnPCSelectPetOrMagic(0, 6)
end

function UMG_LobbyMain_C:SelectPetEnd1()
  self:OnPCSelectPetOrMagic(1, 1)
end

function UMG_LobbyMain_C:SelectPetEnd2()
  self:OnPCSelectPetOrMagic(1, 2)
end

function UMG_LobbyMain_C:SelectPetEnd3()
  self:OnPCSelectPetOrMagic(1, 3)
end

function UMG_LobbyMain_C:SelectPetEnd4()
  self:OnPCSelectPetOrMagic(1, 4)
end

function UMG_LobbyMain_C:SelectPetEnd5()
  self:OnPCSelectPetOrMagic(1, 5)
end

function UMG_LobbyMain_C:SelectPetEnd6()
  self:OnPCSelectPetOrMagic(1, 6)
end

function UMG_LobbyMain_C:IsInMiniGamePerform()
  local status = _G.NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  local miniGameStage = _G.NRCModuleManager:DoCmd(_G.MiniGameModuleCmd.GetMiniGameStage)
  if "Perform" == miniGameStage or status == ProtoEnum.MinigameStatus.MS_FINISH then
    return true
  end
  return false
end

function UMG_LobbyMain_C:InternalCheckSubUi(ui_type)
  if ui_type ~= self.SubUiType.PhotoGraph and self.WaitForEnterPhotoGraph then
    return
  end
  if self.lockOpenSubUi or ui_type ~= self.SubUiType.Message and not self.PanelOpen then
    return
  end
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.inputComponent and player.inputComponent:GetPlayDialogueVideo() then
    return
  end
  if player then
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) and ui_type ~= self.SubUiType.PhotoGraph then
      return
    elseif player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and ui_type ~= self.SubUiType.PhotoGraph then
      return
    end
  end
  if self:IsInMiniGamePerform() then
    return
  end
  return true
end

function UMG_LobbyMain_C:CheckOpenSubUi(ui_type)
  if not self:InternalCheckSubUi(ui_type) then
    return
  end
  local openSucceed = false
  if ui_type == self.SubUiType.Map then
    openSucceed = self:OpenMapUI(true)
  elseif ui_type == self.SubUiType.Bag then
    openSucceed = self:OpenBagUI(true)
  elseif ui_type == self.SubUiType.Pet then
    openSucceed = self:OpenPetUI(true)
  elseif ui_type == self.SubUiType.Task then
    openSucceed = self:OpenTaskUI(true)
  elseif ui_type == self.SubUiType.HandBook then
    openSucceed = self:OpenHandbookUI(true)
  elseif ui_type == self.SubUiType.Friend then
    openSucceed = self:OpenFriendUI(true)
  elseif ui_type == self.SubUiType.Guide then
    openSucceed = self:OpenGuideUI(true)
  elseif ui_type == self.SubUiType.Activity then
    openSucceed = self:OpenActivityUI(true)
  elseif ui_type == self.SubUiType.MagicManual then
    openSucceed = self:OpenMagicManualUI(true)
  elseif ui_type == self.SubUiType.Individuation then
    openSucceed = self:OpenIndividuationUI(true)
  elseif ui_type == self.SubUiType.PhotoGraph then
    openSucceed = self:InternalCheckedEnterPhotoGraph()
  elseif ui_type == self.SubUiType.Shop then
    openSucceed = self:OpenShopUI(true)
  elseif ui_type == self.SubUiType.FashionMall then
    openSucceed = self:OpenFashionMallUI(true)
  elseif ui_type == self.SubUiType.Message then
    openSucceed = self:HandleMessage(true)
  elseif ui_type == self.SubUiType.QuickDressUp then
    openSucceed = self:EnterQuickDressUp(true)
  elseif ui_type == self.SubUiType.QuickChat then
    openSucceed = self:OpenQuickChatByKey(true)
  end
  if openSucceed then
    self.lockOpenSubUi = true
    self.UMG_Task_Track:CancelPcInput()
    if self.lockOpenDelayHandle then
      _G.DelayManager:CancelDelayById(self.lockOpenDelayHandle)
      self.lockOpenDelayHandle = nil
    end
    self.lockOpenDelayHandle = _G.DelayManager:DelaySeconds(3, self.UnLockOpenSubUi, self)
  end
end

function UMG_LobbyMain_C:GetLockOpenSubUi()
  return self.lockOpenSubUi
end

function UMG_LobbyMain_C:LockOpenSubUi()
  self.lockOpenSubUi = true
  if self.lockOpenDelayHandle then
    _G.DelayManager:CancelDelayById(self.lockOpenDelayHandle)
    self.lockOpenDelayHandle = nil
  end
  self.lockOpenDelayHandle = _G.DelayManager:DelaySeconds(3, self.UnLockOpenSubUi, self)
end

function UMG_LobbyMain_C:UnLockOpenSubUi()
  self.lockOpenDelayHandle = nil
  self.lockOpenSubUi = nil
end

function UMG_LobbyMain_C:EnterQuickDressUp(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.QuickDressUp)
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_FAST_DRESSUP)
  if isBan or isHide then
    return
  end
  self:OpenFastDressUp()
  return true
end

function UMG_LobbyMain_C:InternalCheckedEnterPhotoGraph()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO, true)
  local isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO)
  if isBan or isHide then
    return
  end
  local openResult = NRCModuleManager:DoCmd(MainUIModuleCmd.TryOpenTakePhotosPanel)
  return openResult
end

function UMG_LobbyMain_C:EnterPhotoGraph()
  if not self:InternalCheckSubUi(self.SubUiType.PhotoGraph) then
    if self.WaitForEnterPhotoGraph then
      self:CancelDelayByID(self.WaitForEnterPhotoGraph)
      self.WaitForEnterPhotoGraph = nil
    end
    return
  end
  if self.WaitForEnterPhotoGraph then
    self:CancelDelayByID(self.WaitForEnterPhotoGraph)
    self.WaitForEnterPhotoGraph = nil
    return NRCModuleManager:DoCmd(MainUIModuleCmd.TryOpenTakePhotosPanel, true)
  end
  self.WaitForEnterPhotoGraph = self:DelaySeconds(0.25, function()
    self.WaitForEnterPhotoGraph = nil
    self:CheckOpenSubUi(self.SubUiType.PhotoGraph)
  end)
end

function UMG_LobbyMain_C:CheckIsVisible(Visibility)
  return Visibility == UE4.ESlateVisibility.Visible or Visibility == UE4.ESlateVisibility.HitTestInvisible or Visibility == UE4.ESlateVisibility.SelfHitTestInvisible
end

function UMG_LobbyMain_C:ExitDungeon()
  local LoadingUIModule = _G.NRCModuleManager:GetModule("LoadingUIModule")
  if LoadingUIModule then
    local WaitingUI = LoadingUIModule:GetPanel("UMG_WaitingUI")
    local FastLoadingUI = LoadingUIModule:GetPanel("UMG_FastLoadingUI")
    local bLoading = FastLoadingUI and self:CheckIsVisible(FastLoadingUI:GetVisibility()) or WaitingUI and self:CheckIsVisible(WaitingUI:GetVisibility())
    if bLoading then
      return
    end
  end
  if self:IsInMiniGamePerform() then
    return
  end
  if self.BtnExitDungeon:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:OnBtnExitDungeon()
  elseif self.inMiniGame then
    self.UMG_MiniGame_Task:OpenExitPanel()
  end
end

function UMG_LobbyMain_C:OpenMapUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Map)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_WORLD_MAP_UI, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenMapUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170")
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_MAP, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAP, true)
  if isBan or isHide then
    return
  elseif BigMapModuleCmd then
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.OpenWorldMap)
    return true
  else
    Log.Error("BigMapModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenBagUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Bag)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_BAG_UI, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenBagUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170")
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_BAG, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_BAG, true)
  if isBan or isHide then
    return
  elseif BagModuleCmd then
    _G.NRCModuleManager:DoCmd(BagModuleCmd.OpenBagMainPanel)
    return true
  else
    Log.Error("BagModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenPetUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Pet)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PET, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_PET, true)
  if isBan or isHide then
    return
  elseif PetUIModuleCmd then
    _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnPetClick")
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPanelPetMain, nil, nil, nil, true)
    return true
  else
    Log.Error("PetUIModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenTaskUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Task)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenTaskUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_TASK, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_TASK, true)
  if isBan or isHide then
    return
  elseif TaskModuleCmd then
    _G.NRCModuleManager:DoCmd(TaskModuleCmd.OpenTaskPanel)
    return true
  else
    Log.Error("TaskModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenHandbookUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.HandBook)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_PETBOOK_UI, false, false)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenHandbookUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_HANDBOOK, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_HANDBOOK, true)
  if isBan or isHide then
    return
  elseif HandbookModuleCmd then
    _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnBookClick")
    _G.NRCProfilerLog:NRCClickBtn(true, "HandbookCover")
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookCover)
    return true
  else
    Log.Error("HandbookModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenFriendUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Friend)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenFriendUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_FRIEND, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_FRIEND, true)
  if isBan or isHide then
    return
  elseif FriendModuleCmd then
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LobbyMain_C:OpenFriendUI")
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenMainPanel)
    return true
  else
    Log.Error("FriendModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenGuideUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Guide)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_COMPASS, true, true)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenGuideUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  local isForbiddenScene = false
  if SceneModule then
    local currentSceneId = SceneModule:GetCurrentMapId()
    if 130 == currentSceneId then
      isForbiddenScene = true
    end
  end
  if isForbiddenScene then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_GUIDE, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_GUIDE, true)
  if isBan or isHide then
    return
  elseif TeachingManualModuleCmd then
    _G.NRCModuleManager:DoCmd(TeachingManualModuleCmd.OpenMainPanel)
    return true
  else
    Log.Error("TeachingManualModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenActivityUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Activity)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_ACTIVITY, false, false)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenActivityUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_ACTIVITY, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_ACTIVITY, true)
  if isBan or isHide then
    return
  elseif ActivityModuleCmd then
    _G.NRCModuleManager:DoCmd(ActivityModuleCmd.OpenMainPanel)
    return true
  else
    Log.Error("ActivityModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenMagicManualUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.MagicManual)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_MAGIC_BOOK, false, false)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenMagicManualUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_MAGIC_BOOK, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_MAGIC_BOOK, true)
  if isBan or isHide then
    return
  elseif MagicManualModuleCmd then
    _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.OpenMagicManual)
    return true
  else
    Log.Error("MagicManualModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:TopBlockImcChange(lastTopImc, newTopImc)
  if "IMC_MainUIDefault" == lastTopImc then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
      self.UMG_HUDSimpleList:OnPCSelectPet0(1)
    else
      self.UMG_MainPet:OnPCSelectPet0(1)
    end
    if self:IsPCMode() then
      self.PCKeyFoundation:MagicSelectEnd()
      self.PCKeyFoundation:BallSelectEnd()
    end
  end
end

function UMG_LobbyMain_C:PCKeySetting()
  if SystemSettingModuleCmd then
    self.PCKey:SetKeyVisibility(true)
    text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_ExitDungeon")
    if image ~= "" then
      self.PCKey:SetImageMode(image)
    else
      self.PCKey:SetText(text)
    end
    for i = 1, 6 do
      local item = self.FunctionEntry:GetItemByIndex(i - 1)
      if item and item._data then
        local text, image = ""
        if item._data.type == _G.Enum.FunctionEntrance.FE_TAKE_PHOTO then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_PgEnter")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_FAST_DRESSUP then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_QuickDressUP")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_QuickChat")
        elseif item._data.type == _G.Enum.FunctionEntrance.FE_FRIEND then
          text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_OpenFriendUI")
        end
        if "" ~= image then
          item.PCKey_2:SetImageMode(image)
        else
          item.PCKey_2:SetText(text)
        end
        item.PCKey_2:SetKeyVisibility(true)
      end
    end
  end
end

function UMG_LobbyMain_C:SwitchToPet()
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.SwitchPetOrMagic, 0)
end

function UMG_LobbyMain_C:OpenIndividuationUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Individuation)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local bBan = NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_ROLE_PLAY, true, true)
  if bBan then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  if RolePlayModuleCmd then
    if _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.CheckCanOpenMainPanel) then
      _G.NRCModuleManager:DoCmd(RolePlayModuleCmd.OpenMainPanel)
      return true
    end
  else
    Log.Error("RolePlayModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenFashionMallUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.FashionMall)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_FASHION_STORE, false, false)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenShopUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_FASHION_STORE, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_FASHION_STORE, true)
  if isBan or isHide then
    return
  elseif AppearanceModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop)
    return true
  else
    Log.Error("AppearanceModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:OpenShopUI(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Shop)
    return
  end
  local bHadGotCompass = _G.DataModelMgr.PlayerDataModel:CompassShouldAppear()
  if not bHadGotCompass then
    return
  end
  local Ban, Msg = FunctionBanManager:GetFunctionState(Enum.PlayerFunctionBanType.PFBT_CHARGE, false, false)
  if Ban then
    Log.Debug("UMG_LobbyMain_C.OpenShopUI \228\186\146\230\150\165\231\179\187\231\187\159\230\139\166\230\136\170,CD", Msg)
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  local isBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_CHARGE, true)
  local isHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_CHARGE, true)
  if isBan or isHide then
    return
  elseif ShopModuleCmd then
    _G.NRCModuleManager:DoCmd(ShopModuleCmd.OpenMainPanel)
    return true
  else
    Log.Error("ShopModuleCmd\228\184\141\229\173\152\229\156\168\230\136\150\232\128\133\228\184\186nil,\232\175\183\230\143\144\229\141\149\231\187\153\229\188\128\229\143\145")
  end
end

function UMG_LobbyMain_C:HandleMessage(checkSucceed)
  if not checkSucceed then
    self:CheckOpenSubUi(self.SubUiType.Message)
    return
  end
  local mainUIModule = self.module
  local friendModule = _G.NRCModuleManager:GetModule("FriendModule")
  if nil == mainUIModule or nil == friendModule then
    return false
  end
  local bPcMode = UE4Helper.IsPCMode()
  
  local function IsBlockByTopPanel(panel)
    if not bPcMode then
      return false
    end
    local PanelData = panel.panelData
    if not PanelData then
      return false
    end
    local bBlock, BlockPanelName = NRCPanelManager:IfBlockByEscPanel(PanelData)
    if bBlock then
      Log.Info("UMG_LobbyMain_C:HandleMessage block by top visible panel", BlockPanelName)
    end
    return bBlock
  end
  
  local bHasPanel = friendModule:HasPanel("Plane_ExchangeVisits_Hint")
  if bHasPanel then
    local panel = friendModule:GetPanel("Plane_ExchangeVisits_Hint")
    if panel and panel:IsInteractableNow() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OpenVisitPanel()
      return true
    end
  end
  bHasPanel = mainUIModule:HasPanel("LobbyDownTips")
  if bHasPanel then
    local panel = mainUIModule:GetPanel("LobbyDownTips")
    if panel and panel:IsVisible() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OpenMessageDetailsUI()
      return true
    end
  end
  local rolePlayModule = _G.NRCModuleManager:GetModule("RolePlayModule")
  if rolePlayModule then
    bHasPanel = rolePlayModule:HasPanel("RolePlay_GetTips")
    if bHasPanel then
      local panel = rolePlayModule:GetPanel("RolePlay_GetTips")
      if panel and panel.OnClickTips and panel.HasValidData and panel:HasValidData() then
        if IsBlockByTopPanel(panel) then
          return false
        end
        panel:OnClickTips(bPcMode)
        return true
      end
    end
  end
  local musicCollectionModule = _G.NRCModuleManager:GetModule("MusicCollectionModule")
  if musicCollectionModule and musicCollectionModule:HasPanel("MusicCollectTips") then
    local panel = musicCollectionModule:GetPanel("MusicCollectTips")
    if panel and panel.OnClickTips and panel.HasValidData and panel:HasValidData() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OnClickTips()
      return true
    end
  end
  local bagModule = _G.NRCModuleManager:GetModule("BagModule")
  if bagModule and bagModule:HasPanel("NPCRosterTip") then
    local panel = bagModule:GetPanel("NPCRosterTip")
    if panel and panel.OnClick then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OnClick()
      return true
    end
  end
  if bagModule and bagModule:HasPanel("UniversalTips") then
    local panel = bagModule:GetPanel("UniversalTips")
    if panel and panel.OpenPanel and panel.HasValidData and panel:HasValidData() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OpenPanel()
      return true
    end
  end
  local taskModule = _G.NRCModuleManager:GetModule("TaskModule")
  if taskModule and taskModule:HasPanel("LegendaryTaskUnlockTips") then
    local panel = taskModule:GetPanel("LegendaryTaskUnlockTips")
    if panel and panel:IsVisible() and panel.OnClickTips and panel.HasValidData and panel:HasValidData() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OnClickTips()
      return true
    end
  end
  local TeachingManualModule = _G.NRCModuleManager:GetModule("TeachingManualModule")
  if TeachingManualModule and TeachingManualModule:HasPanel("TeachingUnlockTips") then
    local panel = TeachingManualModule:GetPanel("TeachingUnlockTips")
    if panel and panel.OpenPanel and panel.HasValidData and panel:HasValidData() then
      if IsBlockByTopPanel(panel) then
        return false
      end
      panel:OpenPanel()
      return true
    end
  end
  return false
end

function UMG_LobbyMain_C:SelectPetByGid(Gid)
  self.UMG_MainPet:SelectPetByGid(Gid)
end

function UMG_LobbyMain_C:GetPropTipsSizeY()
  local ObjectDesiredSize = self.Objectives:GetDesiredSize()
  return 360 - ObjectDesiredSize.Y
end

function UMG_LobbyMain_C:ChangBG()
  self.UMG_PlayerInfoHUD.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.UMG_MainPet.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
  if not self:IsPCMode() then
    self.UMG_PlayerAbilities.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.PCKeyFoundation.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.UMG_PointOfInterestPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.VerticalBox_4:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.UMG_Compass.Compass:Hide()
  self.PlayerCtrl.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_LobbyMain_C:ShowCenterRedCross()
  if self.CenterCrossPanel:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self.CenterCrossPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local viewportSize = UE4.UWidgetLayoutLibrary.GetViewportSize(UE4Helper.GetCurrentWorld())
    local Size1 = UE4.FVector2D(viewportSize.Y, self.Line1.Slot:GetSize().Y)
    self.Line1.Slot:SetSize(Size1)
    self.Line1:SetRenderTransformAngle(90)
    local Size2 = UE4.FVector2D(viewportSize.X, self.Line2.Slot:GetSize().Y)
    self.Line2.Slot:SetSize(Size2)
    self.Line2:SetRenderTransformAngle(0)
  else
    self.CenterCrossPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMain_C:OnRolePlayMainPanelOpen()
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_CompassIcon, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.BtnExitDungeon, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Report, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_Vitality, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_EnergyStorage, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_TandemRide, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LiqueFaction, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LightMagic, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.WorldCombat_Lifebar, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.On, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Left, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Right, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Hud_PerceptionPanel, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_TraceTaskPanel, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_OnlineTeammateTagPanel, "RolePlay")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_TraceRelationTreePanel, "RolePlay")
  if self:IsPCMode() then
    self.PCKeyFoundation:AddInputBlock()
  else
    self.UMG_PlayerAbilities:AddInputBlock()
  end
  self.UMG_PlayerInfoHUD:SetSimpleUseListVisible(false)
end

function UMG_LobbyMain_C:OnRolePlayMainPanelClosed()
  self.uiVisibilityConstraint:RemoveWidgetDisplayConstraintsByFactor("RolePlay")
  if self:IsPCMode() then
    self.PCKeyFoundation:RemoveInputBlock()
  else
    self.UMG_PlayerAbilities:RemoveInputBlock()
  end
end

function UMG_LobbyMain_C:OnPropPlacementPanelOpen()
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_CompassIcon, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.BtnExitDungeon, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Report, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_Vitality, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_EnergyStorage, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_TandemRide, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LockBall, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LockPet, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LockMagic, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LiqueFaction, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_LightMagic, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.WorldCombat_Lifebar, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.On, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Left, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.Right, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.VerticalBox_4, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Hud_PerceptionPanel, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_TraceTaskPanel, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_OnlineTeammateTagPanel, "PropPlacement")
  self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_TraceRelationTreePanel, "PropPlacement")
  if self:IsPCMode() then
    self.PCKeyFoundation:AddInputBlock()
  else
    self.UMG_PlayerAbilities:AddInputBlock()
  end
  self.UMG_PlayerInfoHUD:SetSimpleUseListVisible(false)
end

function UMG_LobbyMain_C:OnPropPlacementPanelClose()
  self.uiVisibilityConstraint:RemoveWidgetDisplayConstraintsByFactor("PropPlacement")
  if self:IsPCMode() then
    self.PCKeyFoundation:RemoveInputBlock()
  else
    self.UMG_PlayerAbilities:RemoveInputBlock()
  end
end

function UMG_LobbyMain_C:InitUIBan()
  if not self.UIBanList then
    local UIBanList = {}
    UIBanList[Enum.FunctionEntrance.FE_PET_LIST] = {
      UI = self.UMG_MainPet.MainPetList
    }
    UIBanList[Enum.FunctionEntrance.FE_MAGIC] = {
      UI = self.UMG_PlayerInfoHUD
    }
    UIBanList[Enum.FunctionEntrance.FE_THROW] = {
      UI = self.UMG_PlayerAbilities.AbilitySlot_Throw
    }
    UIBanList[Enum.FunctionEntrance.FE_TASK_TEXT] = {
      UI = self.UMG_Task_Track
    }
    UIBanList[Enum.FunctionEntrance.FE_HP] = {
      UI = self.UMG_MainUIRoleHP
    }
    UIBanList[Enum.FunctionEntrance.FE_MINIMAP_TIME] = {
      UI = self.UMG_MinimapTime
    }
    UIBanList[Enum.FunctionEntrance.FE_ANALOG_STICK] = {
      UI = self.PlayerCtrl
    }
    self.UIBanList = UIBanList
    self.UIBanPostNotifiers = {
      [Enum.FunctionEntrance.FE_MAP_TOP] = function()
        self.UMG_Compass:UpdateUIBan()
        self.UMG_CompassIcon:UpdateMiniMapUIBan()
      end,
      [Enum.FunctionEntrance.FE_COMPASS] = function()
        self.UMG_CompassIcon:UpdateUIBan()
        self:UpdateCompassUIBan()
      end,
      [Enum.FunctionEntrance.FE_COMPASS_MAINMENU] = function()
        self.UMG_CompassIcon:UpdateUIBan()
      end,
      [Enum.FunctionEntrance.FE_TASK_TEXT] = function()
        self:RefreshTaskText()
      end,
      [Enum.FunctionEntrance.FE_FRIEND] = function()
        self:RefreshIcons()
      end,
      [Enum.FunctionEntrance.FE_TAKE_PHOTO or 0] = function()
        self:RefreshIcons()
      end,
      [Enum.FunctionEntrance.FE_FAST_DRESSUP or 0] = function()
        self:RefreshIcons()
      end,
      [Enum.FunctionEntrance.FE_MULTI_MAIN_MULTI_CHAT or 0] = function()
        self:RefreshIcons()
      end,
      [Enum.FunctionEntrance.FE_THROW] = function()
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation.AbilitySlot_Throw.UMG_Ability_Slot_Throw:RefreshView()
          end
        else
          self.UMG_PlayerAbilities.AbilitySlot_Throw:RefreshView()
        end
      end,
      [Enum.FunctionEntrance.FE_MAIN_BRIEF_SETTTING] = function()
        self.UMG_CompassIcon:UpdateStoryState()
      end,
      [Enum.FunctionEntrance.FE_MAIN_ABILITY_SLOT_JUMP] = function()
        self.UMG_PlayerAbilities.AbilitySlot_Jump:RefreshFlag()
      end,
      [Enum.FunctionEntrance.FE_CATCH_IN_WORLD] = function()
        local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation:OnChangePetCatch(bHide)
          end
        elseif self.UMG_PlayerInfoHUD then
          self.UMG_PlayerInfoHUD:OnChangePetCatch(bHide)
        end
      end,
      [Enum.FunctionEntrance.FE_CROUCH] = function()
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation.AbilitySlot_Crouch.UMG_Ability_Slot_Crouch:RefreshUI()
          end
        else
          self.UMG_PlayerAbilities.AbilitySlot_Crouch:RefreshUI()
        end
      end,
      [Enum.FunctionEntrance.FE_EMOTE] = function()
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation.AbilitySlot_Emote.UMG_Ability_Slot_Emote:RefreshUI()
          end
        else
          self.UMG_PlayerAbilities.AbilitySlot_Emote:RefreshUI()
        end
      end,
      [Enum.FunctionEntrance.FE_UNTRANSFORM] = function()
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation.AbilitySlot_Untransform.UMG_Ability_Slot_Untransform:RefreshUI()
          end
        else
          self.UMG_PlayerAbilities.AbilitySlot_Untransform:RefreshUI()
        end
      end,
      [Enum.FunctionEntrance.FE_UNHAND] = function()
        if self:IsPCMode() then
          if self.PCKeyFoundation then
            self.PCKeyFoundation.AbilitySlot_UnHand.UMG_Ability_Slot_UnHand:RefreshView()
          end
        else
          self.UMG_PlayerAbilities.AbilitySlot_UnHand:RefreshView()
        end
      end,
      [Enum.FunctionEntrance.FE_FURNITURE_HANDBOOK] = function()
        self.UMG_CompassIcon:RefreshFurnitureAtlasVisible()
      end,
      [Enum.FunctionEntrance.FE_EDIT_HOME] = function()
        self.UMG_CompassIcon:RefreshEditHomeVisible()
      end,
      [Enum.FunctionEntrance.FE_BP] = function()
        self.UMG_CompassIcon:UpdatePassActive()
      end,
      [Enum.FunctionEntrance.FE_SEASON] = function()
        self.UMG_CompassIcon:SetSeasonIntegrationIcon()
      end,
      [Enum.FunctionEntrance.FE_MAGIC_BOOK] = function()
        self.UMG_CompassIcon:SetMagicManualIcon()
      end,
      [Enum.FunctionEntrance.FE_PET] = function()
        self.UMG_CompassIcon:RefreshPetVisibility()
      end,
      [Enum.FunctionEntrance.FE_HANDBOOK] = function()
        self.UMG_CompassIcon:RefreshHandbookVisibility()
      end,
      [Enum.FunctionEntrance.FE_ACTIVITY] = function()
        self.UMG_CompassIcon:RefreshActivityVisibility()
      end,
      [Enum.FunctionEntrance.FE_TASK] = function()
        self.UMG_CompassIcon:RefreshTaskVisibility()
      end,
      [Enum.FunctionEntrance.FE_FRIEND] = function()
        self.UMG_CompassIcon:RefreshFriendVisible()
      end,
      [Enum.FunctionEntrance.FE_ANALOG_STICK] = function()
        self:RefreshJoystick()
      end,
      [Enum.FunctionEntrance.FE_STA_BAR] = function()
        self:RefreshVitality()
      end
    }
  end
  for FuncEntranceEnum, UIInfo in pairs(self.UIBanList) do
    local bHide = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.CheckUIFunctionHide, FuncEntranceEnum)
    self:UIBan(FuncEntranceEnum, bHide)
  end
  for FuncEntranceEnum, Notifier in pairs(self.UIBanPostNotifiers) do
    if not self.UIBanList[FuncEntranceEnum] then
      Notifier()
    end
  end
end

function UMG_LobbyMain_C:UpdateCompassUIBan()
  local hideCompass = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_COMPASS)
  local pos = self.UMG_MainUIRoleHP.Slot:GetPosition()
  local pos1 = self.UMG_MinimapTime.Slot:GetPosition()
  if _G.DataModelMgr.PlayerDataModel:CompassShouldAppear() and not hideCompass then
    pos.x = 258.2
    pos1.x = 280
  else
    pos.x = 167.5
    pos1.x = 189.3
  end
  self.UMG_MainUIRoleHP.Slot:SetPosition(pos)
  self.UMG_MinimapTime.Slot:SetPosition(pos1)
end

function UMG_LobbyMain_C:UIBan(FunctionEntrance, bHide)
  if self.UIBanList then
    self:Log("FunctionBan UIBan func=", FunctionEntrance, bHide)
    local UIInfo = self.UIBanList[FunctionEntrance]
    if UIInfo then
      if UIInfo.UI then
        self:Log("FunctionBan UIBan visibility changed, func=", FunctionEntrance, bHide)
        if bHide then
          UIInfo.UI:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
          UIInfo.UI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
      else
        self:Log("FunctionBan UIBan no implementation", FunctionEntrance)
      end
    end
    local Notifier = self.UIBanPostNotifiers[FunctionEntrance]
    if Notifier then
      Notifier(FunctionEntrance, bHide)
    end
  else
    Log.Warning("UIBanList\230\156\170\229\136\157\229\167\139\229\140\150")
  end
end

function UMG_LobbyMain_C:RefreshLeftBottomFunctions()
  local isChatBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHAT)
  local isPhotoBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TAKE_PHOTO or 0)
end

function UMG_LobbyMain_C:SetMainPetVisible()
end

function UMG_LobbyMain_C:OnChildVisibilityChange(widget, visibility)
  self.uiVisibilityConstraint:TrySetWidgetVisibility(widget, visibility)
end

function UMG_LobbyMain_C:OnPlayerLeaveVisit()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ExitVisitPlayFollowUI)
end

function UMG_LobbyMain_C:OnPlayerEnterVisit()
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.JoinVisitPlayFollowUI)
end

function UMG_LobbyMain_C:OnWandChanged()
  self.UMG_LockMagic:OnWandChanged()
  self.UMG_LiqueFaction:OnWandChanged()
end

function UMG_LobbyMain_C:OnEntranceVisibleZone()
  self:OnInitializedQuickChat()
end

function UMG_LobbyMain_C:OnInitializedQuickChat()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    local VisitState = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if VisitState or 1 == localPlayer.visibleZoneNum then
      self:ShowOrHideQuickChat(false)
    else
      self:ShowOrHideQuickChat(true)
    end
  end
end

function UMG_LobbyMain_C:OnVisitPlayerInfoSyncNotify(oldOwner, newOwner, bFirstEnter)
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  if nil ~= newOwner and newOwner ~= oldOwner and nil ~= playerUin then
    if 0 == newOwner then
      if nil ~= oldOwner then
        self:ShowOrHideQuickChat(true)
      end
    elseif bFirstEnter then
      self:ShowOrHideQuickChat(false)
    end
  end
end

function UMG_LobbyMain_C:ShowOrHideQuickChat(IsHide)
end

function UMG_LobbyMain_C:ThrowSelectBallUP(IsFromRelation)
  if self:IsPCMode() then
    if 2 == self.Switcher:GetActiveWidgetIndex() and self.BallList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      if self.CanThrowSelectBall then
        self.CanThrowSelectBall = false
        self.BallList:ScrollNextPage(1)
        self.ThrowSelectBallDelayHandler = _G.DelayManager:DelaySeconds(0.2, self.ResetCanThrowSelectBall, self)
      end
    elseif 3 == self.Switcher:GetActiveWidgetIndex() and self.MainPetScrollList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      if self.CanThrowSelectBall then
        self.CanThrowSelectBall = false
        self.MainPetScrollList:ScrollNextPage(1)
        self.ThrowSelectBallDelayHandler = _G.DelayManager:DelaySeconds(0.2, self.ResetCanThrowSelectBall, self)
      end
    else
      local mainUIModule = self.module
      if nil == mainUIModule then
        return
      end
      local bHasPanel = mainUIModule:HasPanel("NPCInteractMain")
      if bHasPanel then
        local panel = mainUIModule:GetPanel("NPCInteractMain")
        if panel and panel:IsVisible() then
          panel:SelectPreviousInteraction(IsFromRelation)
        end
      end
    end
  end
end

function UMG_LobbyMain_C:ThrowSelectBallDown(IsFromRelation)
  if self:IsPCMode() then
    if 2 == self.Switcher:GetActiveWidgetIndex() and self.BallList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      if self.CanThrowSelectBall then
        self.CanThrowSelectBall = false
        self.BallList:ScrollNextPage(-1)
        self.ThrowSelectBallDelayHandler = _G.DelayManager:DelaySeconds(0.2, self.ResetCanThrowSelectBall, self)
      end
    elseif 3 == self.Switcher:GetActiveWidgetIndex() and self.MainPetScrollList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      if self.CanThrowSelectBall then
        self.CanThrowSelectBall = false
        self.MainPetScrollList:ScrollNextPage(-1)
        self.ThrowSelectBallDelayHandler = _G.DelayManager:DelaySeconds(0.2, self.ResetCanThrowSelectBall, self)
      end
    else
      local mainUIModule = self.module
      if nil == mainUIModule then
        return
      end
      local bHasPanel = mainUIModule:HasPanel("NPCInteractMain")
      if bHasPanel then
        local panel = mainUIModule:GetPanel("NPCInteractMain")
        if panel and panel:IsVisible() then
          panel:SelectNextInteraction(IsFromRelation)
        end
      end
    end
  end
end

function UMG_LobbyMain_C:ResetCanThrowSelectBall()
  self.CanThrowSelectBall = true
end

function UMG_LobbyMain_C:OnOpenVisitOtherHomeReport()
  _G.NRCAudioManager:PlaySound2DAuto(1010, "UMG_Friend_Chitchat_C:OnReportBtn")
  local ReportData = {}
  ReportData.business_data = {}
  ReportData.business_data.report_entrance = 1
  ReportData.business_data.report_scene = ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE
  local homeReportData = _G.NRCModeManager:DoCmd(_G.HomeModuleCmd.GetReportData)
  ReportData.business_data.homeName = homeReportData.homeName
  ReportData.business_data.masterId = homeReportData.masterId
  ReportData.uin = homeReportData.masterId
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.OpenFriendReport, ReportData)
end

function UMG_LobbyMain_C:OnEnterFarmMap()
  if self.SightType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    local equipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
    if nil ~= equipMagicInfo then
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, equipMagicInfo)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
    end
  end
end

function UMG_LobbyMain_C:OnEnterHomeMap()
  if not (_G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InLocalMasterIndoor()) or self:IsPCMode() then
    return
  end
  if self.SightType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    local magics = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemArrayByType, _G.ProtoEnum.BagItemType.BI_MAGIC)
    local magicId = 100701
    local magicItemInfo
    if magics and #magics > 0 then
      local magic = magics[1]
      if magic then
        magicId = magic.id
      end
    end
    magicItemInfo = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, magicId)
    if magicItemInfo then
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, magicItemInfo)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.SetEquipMagicInfo, magicItemInfo, true)
      if self.UMG_PlayerInfoHUD and self.UMG_PlayerInfoHUD.HUDMagic then
        self.UMG_PlayerInfoHUD.HUDMagic:OnMagicBtnPressed()
      end
    else
      local teamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMainPetTeam()
      if teamInfo and teamInfo.pet_infos and #teamInfo.pet_infos > 0 then
        local pet = teamInfo.pet_infos[1]
        local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(pet.pet_gid)
        if petInfo then
          _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.PET, petInfo)
          _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.UI_RefreshMainPetSelectedState, pet.pet_gid)
          _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.SetPetSelectIndex, 1)
        end
      end
    end
  end
end

function UMG_LobbyMain_C:OnSetWidgetDisplayConstraints(GroupName, bAdd)
  if bAdd then
    if "TakePhotos" == GroupName then
      self.uiVisibilityConstraint:AddWidgetDisplayConstraints(self.UMG_Lobby_Vitality, GroupName)
    end
  else
    self.uiVisibilityConstraint:RemoveWidgetDisplayConstraintsByFactor(GroupName)
  end
end

function UMG_LobbyMain_C:UpdateEquipItemSelect()
  if self.SightType == _G.MainUIModuleEnum.MainUIChooseType.ITEM then
    self:SetMainPetSelectedGid(0)
    _G.NRCModeManager:DoCmd(MainUIModuleCmd.SetSelectPetIndex, 0)
    self.UMG_MainPet:RefreshSelectedState()
    if self:IsPCMode() then
      self.PCKeyFoundation:SetMagicSelected(false)
      self.PCKeyFoundation:SetEquipItemSelected(true)
    else
      self.UMG_PlayerInfoHUD:SetMagicSelected(false)
      self.UMG_PlayerInfoHUD:SetEquipItemSelected(true)
    end
  end
end

function UMG_LobbyMain_C:OnChangeMagicLimit()
  if self:IsPCMode() then
    self.PCKeyFoundation.AbilitySlot_Throw.UMG_Ability_Slot_Throw:OnChangeMagicLimit()
  else
    self.UMG_PlayerAbilities.AbilitySlot_Throw:OnChangeMagicLimit()
  end
end

function UMG_LobbyMain_C:ForceRefreshWidget()
  self:DelayFrames(1, function(panelInst)
    if UE4.UObject.IsValid(panelInst) then
      panelInst:InvalidateLayoutAndVolatility()
    end
  end, self)
end

return UMG_LobbyMain_C
