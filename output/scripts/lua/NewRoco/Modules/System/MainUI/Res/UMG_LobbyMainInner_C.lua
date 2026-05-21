local BattleUIModuleCmd = reload("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local LevelUpUtils = require("NewRoco.Modules.System.LevelUpUI.LevelUpUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local BagModuleEnum = reload("NewRoco.Modules.System.Bag.BagModuleEnum")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local FriendEnum = require("NewRoco.Modules.System.Friend.FriendEnum")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ResQueue = require("NewRoco.Utils.ResQueue")
local UILayerEvent = require("Core.NRCPanelLayer.UILayerEvent")
local WishCrystalModuleEvent = require("NewRoco.Modules.System.WishCrystal.WishCrystalModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")
local PreDownloadEvent = require("NewRoco.Modules.System.Download.PreDownload.PreDownloadEvent")
local ActivityModuleEvent = require("NewRoco/Modules/System/Activity/ActivityModuleEvent")
local UMG_LobbyMainInner_C = _G.NRCPanelBase:Extend("UMG_LobbyMainInner_C")

function UMG_LobbyMainInner_C:OnActive(OpenType)
  Log.Debug("UMG_LobbyMainInner_C:OnActive", OpenType)
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnClosePanelLobbyMain)
  NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddToDisableLobbyMainPopUpList, "LobbyMainInner")
  if self.CloseBtn1 and self.CloseBtn1.btnClose and self.CloseBtn1.btnClose.OnClicked and self.headButton and self.headButton.OnClicked then
  else
    self:EarlyCrash()
    return
  end
  _G.NRCAudioManager:SetLobbyMainInnerOpen(true)
  self.LuopanExpand = true
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    self:EarlyCrash()
    return
  end
  local playerCtrl = UE4.UGameplayStatics.GetPlayerControllerFromID(player.viewObj, 0)
  if not UE.UObject.IsValid(playerCtrl) or not playerCtrl.SetFadeEnable then
    self:EarlyCrash()
    return
  end
  self.Died = false
  self.StartSkillSuccessDone = false
  self.OpenType = OpenType or MainUIModuleEnum.CompassOpenType.COMPASS_3D
  self.isNormal = self.OpenType == MainUIModuleEnum.CompassOpenType.COMPASS_3D
  if self.isNormal then
    self:SwitchToMainCamera()
    self:PlayerAnim()
    self.HaloPanelLoader:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_LobbyMainInnerParticleLoader:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.HaloPanelLoader:LoadPanel(true, _G.PriorityEnum.Active_LobbyMainInner)
    self.HaloPanelLoader:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.UMG_LobbyMainInnerParticleLoader:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if self.OpenType ~= MainUIModuleEnum.CompassOpenType.COMPASS_2D_IGNORE_PLAYER then
      player.viewObj:SetActorHiddenInGame(self.OpenType == MainUIModuleEnum.CompassOpenType.COMPASS_2D_NO_PLAYER)
    end
  end
  if self.StartSkill then
    self.StartSkill:Destroy()
    self.StartSkill = nil
  end
  if self.EndSkill then
    self.EndSkill:Destroy()
    self.EndSkill = nil
  end
  self.PostProcessSkill = nil
  self.preDownLoadActivityInst = nil
  player:SendEvent(PlayerModuleEvent.ON_LUOPAN_STATE_CHANGED, true)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "LobbyMainInner")
  self.SubPanelType = MainUIModuleEnum.SubPanelOpenType.NoneUI
  self.IsWaitingForSubPanel = 0
  self.IconList = {
    self.BattleIconLoader,
    self.TaskIconLoader,
    self.MapIconLoader,
    self.HandbookIconLoader,
    self.PetIconLoader,
    self.BagIconLoader
  }
  self.LeftPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TopPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BottomPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnAddEventListener()
  self.DpiScaleY = 1
  self:UpdateUIData()
  self.ui_types = {}
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.BattleUI)
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.TaskUI)
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.MapUI)
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.HandbookUI)
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.PetUI)
  table.insert(self.ui_types, MainUIModuleEnum.SubPanelOpenType.BagUI)
  self.panel_bone_map = {}
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.BattleUI] = "Bone009"
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.TaskUI] = "Bone011"
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.MapUI] = "Bone013"
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.HandbookUI] = "Bone015"
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.PetUI] = "Bone017"
  self.panel_bone_map[MainUIModuleEnum.SubPanelOpenType.BagUI] = "Bone019"
  self.panel_icon_map = {}
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.BattleUI] = self.BattleIconLoader
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.TaskUI] = self.TaskIconLoader
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.MapUI] = self.MapIconLoader
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.HandbookUI] = self.HandbookIconLoader
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.PetUI] = self.PetIconLoader
  self.panel_icon_map[MainUIModuleEnum.SubPanelOpenType.BagUI] = self.BagIconLoader
  self.CloseBtn1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.GlobalShutdown_Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ButtonClickable = false
  for _, ui_type in ipairs(self.ui_types) do
    local icon = self.panel_icon_map[ui_type]
    icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateHead()
  self.PlayerStarted = true
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").COMPASS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  _G.NRCPanelManager.layerCenter:SendEvent(UILayerEvent.BREAKRIDESKILL_LAYER_OPENWINDOW)
  self.TitlePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LobbyMainInner_C:OnLobbyMainInnerIconLoaded()
  Log.Debug("UMG_LobbyMainInner_C:OnLobbyMainInnerIconLoaded")
  if self:AllIconLoaded() then
    self:DelayFrames(1, self.RealShow, self)
  end
end

function UMG_LobbyMainInner_C:AllIconLoaded()
  Log.Debug("UMG_LobbyMainInner_C:AllIconLoaded?")
  for _, IconPanel in ipairs(self.IconList) do
    if not IconPanel:GetPanel() then
      return false
    end
  end
  if not self.UMG_LobbyMainInnerParticleLoader:GetPanel() then
    return false
  end
  if not self.LeftIconLoader:GetPanel() then
    return false
  end
  if not self.BottomIconLoader:GetPanel() then
    return false
  end
  if not self.isNormal and not self.HaloPanelLoader:GetPanel() then
    return false
  end
  return true
end

function UMG_LobbyMainInner_C:RealShow()
  self.panel_icon_panel_map = {}
  for _, ui_type in ipairs(self.ui_types) do
    self.panel_icon_panel_map[ui_type] = self.panel_icon_map[ui_type]:GetPanel()
  end
  self.BattleIcon = self.BattleIconLoader:GetPanel()
  self.TaskIcon = self.TaskIconLoader:GetPanel()
  self.MapIcon = self.MapIconLoader:GetPanel()
  self.HandbookIcon = self.HandbookIconLoader:GetPanel()
  self.PetIcon = self.PetIconLoader:GetPanel()
  self.BagIcon = self.BagIconLoader:GetPanel()
  self.UMG_LobbyMainInnerParticle = self.UMG_LobbyMainInnerParticleLoader:GetPanel()
  self.LeftIcon = self.LeftIconLoader:GetPanel()
  self.BottomIcon = self.BottomIconLoader:GetPanel()
  self.HaloPanel = self.HaloPanelLoader:GetPanel()
  self.CloseBtn1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.GlobalShutdown_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
  self:InitAllUI()
  Log.Debug("UMG_LobbyMainInner_C:OnLobbyMainInnerIconLoaded")
  if self.isNormal then
    self.LoadQueue = ResQueue(30, nil, _G.PriorityEnum.Active_LobbyMainInner)
    self.LoadQueue:InsertObject("Luopan", "/Game/NewRoco/Modules/Core/NPC/LobbyMain/BP_CompassHalo.BP_CompassHalo_C")
    self.LoadQueue:StartLoad(self, self.OnStartLoaded)
    Log.Debug("UMG_LobbyMainInner_C:Open As Normal")
    self:PlayCompassPostPrecessSkill()
    self:HideIcons(true)
  else
    Log.Debug("UMG_LobbyMainInner_C:Open As Special")
    self:ShowUMGOption(true)
    self.StartSkillSuccessDone = true
    self:CompassStarFinish()
    self.UMG_LobbyMainInnerParticle:PlayStart()
    self:PlayHaloAnimation(self.Open_Luopan)
    _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, "LobbyMainInner")
  end
end

function UMG_LobbyMainInner_C:InitAllUI()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    self:EarlyCrash()
    return
  end
  local playerCtrl = UE4.UGameplayStatics.GetPlayerControllerFromID(player.viewObj, 0)
  if not UE.UObject.IsValid(playerCtrl) or not playerCtrl.SetFadeEnable then
    self:EarlyCrash()
    return
  end
  if self.isNormal then
    playerCtrl:SetFadeEnable(false)
    player:SetCustomDepth(3)
    if player.viewObj and player.viewObj.Mesh then
      player.viewObj.Mesh:SetRenderCustomDepth(true)
      player.viewObj.Mesh:SetCustomDepthStencilValue(3)
    end
  end
  if _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK, false) then
    self.BattleIcon.NrcRedPoint:SetupKey(0)
  else
    self.BattleIcon.NrcRedPoint:SetupKey(169)
  end
  self.PetIcon.NrcRedPoint:SetupKey(12)
  self.HandbookIcon.NrcRedPoint:SetupKey(11)
  self.MapIcon.NrcRedPoint:SetupKey(15)
  self.BagIcon.NrcRedPoint:SetupKey(14)
  self:AddButtonListener(self.BattleIcon.IconButton, self.OnBattleIconClicked)
  self:AddButtonListener(self.TaskIcon.IconButton, self.OnTaskIconClicked)
  self:AddButtonListener(self.MapIcon.IconButton, self.OnMapIconClicked)
  self:AddButtonListener(self.HandbookIcon.IconButton, self.OnHandbookIconClicked)
  self:AddButtonListener(self.PetIcon.IconButton, self.OnPetIconClicked)
  self:AddButtonListener(self.BagIcon.IconButton, self.OnBagIconClicked)
  self:AddButtonListener(self.AwardBtn, self.OnClickedAwardBtn)
  for _, ui_type in ipairs(self.ui_types) do
    local icon = self.panel_icon_map[ui_type]
    local icon_panel = self.panel_icon_panel_map[ui_type]
    icon_panel:InitIcon(self, ui_type, not self:IsFunctionBan(ui_type, false))
    icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:InitLeftIcon()
  self:InitBottomIcon()
  self:InitWishCyrstalUI()
  self:InitDownloadBtn()
  self.TitlePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.Open)
end

function UMG_LobbyMainInner_C:InitDownloadBtn()
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    self.Download:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PRE_DOWNLOAD)
  if isBan then
    return
  end
  self.RedDot:SetupKey(499)
  self.DownloadedBtn.RedDot:SetupKey(491)
  self:AddButtonListener(self.DownloadBtn, self.OnDownloadBtnClicked)
  self:AddButtonListener(self.DownloadedBtn.btnLevelUp, self.OnDownloadBtnClicked)
  self:AddButtonListener(self.DownloadingBtn, self.OnDownloadBtnClicked)
  local preDownLoadActivities = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_PRE_DOWNLOAD, true)
  if preDownLoadActivities and #preDownLoadActivities > 0 and 1 == table.len(preDownLoadActivities) then
    local activityInst = preDownLoadActivities[1]
    self.preDownLoadActivityInst = activityInst
    if activityInst.status == ActivityEnum.ActivityStatus.Complete then
      self.Download:SetVisibility(UE4.ESlateVisibility.Visible)
      self.Download:SetActiveWidgetIndex(2)
    elseif activityInst.status == ActivityEnum.ActivityStatus.Available or activityInst.status == ActivityEnum.ActivityStatus.Active then
      self.Download:SetVisibility(UE4.ESlateVisibility.Visible)
      local bResourceDataReady = _G.NRCPreDownloadManager:IsPreDownloadResEnabled()
      local activityData = activityInst.preDownloadData
      if activityData then
        Log.Dump(activityData, 3, "UMG_LobbyMainInner_C:InitDownloadBtn activityData")
        if not bResourceDataReady then
          Log.Debug("UMG_LobbyMainInner_C:InitDownloadBtn bResourceDataReady false")
          local downloadTips = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_book_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_book_tips").str or ""
          if activityData.book_download then
            downloadTips = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked").str or ""
          end
          self.Download:SetActiveWidgetIndex(0)
          self.DownloadText:SetText(downloadTips)
        elseif bResourceDataReady and not _G.NRCPreDownloadManager:IfNeedToDownload() then
          self.Download:SetActiveWidgetIndex(2)
        elseif _G.NRCPreDownloadManager:IsDownloading() then
          self.Download:SetActiveWidgetIndex(1)
          local isDownloading = _G.NRCPreDownloadManager:IsDownloading()
          local networkStatus = UE.UNetworkStatics:GetNetworkState()
          if isDownloading and 2 == networkStatus then
            self:PlayAnimation(self.Down_Loop, 0, 9999)
          end
        else
          self.Download:SetActiveWidgetIndex(0)
          local downloadTips = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_download_tips") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_start_download_tips").str or ""
          self.DownloadText:SetText(downloadTips)
        end
      end
    elseif activityInst.status == ActivityEnum.ActivityStatus.WaitingActive then
      self.Download:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_LobbyMainInner_C:OnDownloadBtnClicked()
  if self.preDownLoadActivityInst then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_LobbyMainInner_C:OnDownloadBtnClicked")
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OnCmdOpenPreDownload, self.preDownLoadActivityInst)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, MainUIModuleEnum.SubPanelOpenType.PreDownload)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.SubPanelOpenType.PreDownload)
  end
end

function UMG_LobbyMainInner_C:OnStartLoaded(Queue, Success)
  Log.Debug("UMG_LobbyMainInner_C:OnStartLoaded", Success)
  if not Success then
    Log.Error("UMG_LobbyMainInner_C:OnStartLoaded \231\189\151\231\155\152\232\181\132\230\186\144\229\138\160\232\189\189\229\164\177\232\180\165", Success)
    self:EarlyCrash()
    return
  end
  if not self.LoadQueue then
    local isValid = UE4.UObject.IsValid(self)
    Log.Error("UMG_LobbyMainInner_C:OnStartLoaded LoadQueue\232\162\171\231\189\174\231\169\186\228\186\134\239\188\140\231\149\140\233\157\162\232\162\171\229\133\179\228\186\134\239\188\159\229\156\168\230\173\164\231\187\147\230\157\159", isValid)
    if isValid then
      self:EarlyCrash()
    end
    return
  end
  local LuopanClass = self.LoadQueue:Get("Luopan")
  self:GenerateLuopan(LuopanClass)
  if self.LoadQueue then
    self.LoadQueue:Release()
  end
  self.LoadQueue = nil
  self:PlayCompassStartSkill()
end

function UMG_LobbyMainInner_C:EarlyCrash()
  Log.Error("UMG_LobbyMainInner_C:EarlyCrash")
  self:DelayFrames(2, self.DoClose, self)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").COMPASS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  if self.SetVisibility then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMainInner_C:PlayHaloAnimation(Animation, times)
  times = times or 1
  if Animation == self.Loop_Luopan or Animation == self.Open_Luopan then
    self.LuopanExpand = true
  else
    self.LuopanExpand = false
  end
  if self:IsAnimationPlaying(self.Loop_Luopan) then
    self:StopAnimation(self.Loop_Luopan)
  end
  self:PlayAnimation(Animation, 0, times)
  if self.HaloPanel then
    self.HaloPanel:StopAllAnimations()
    if Animation == self.Open_Luopan then
      self.HaloPanel:PlayAnimation(self.HaloPanel.Open_Luopan, 0, times)
    elseif Animation == self.Loop_Luopan then
      self.HaloPanel:PlayAnimation(self.HaloPanel.Loop_Luopan, 0, times)
    elseif Animation == self.Close_Luopan then
      self.HaloPanel:PlayAnimation(self.HaloPanel.Close_Luopan, 0, times)
    end
  else
    Log.Error("HaloPanel is nil")
  end
end

function UMG_LobbyMainInner_C:UpdateHead()
  local PlayerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  local CardInfo = PlayerInfo.additional_data.card_brief_info
  if CardInfo then
    local CardIconConf = _G.DataConfigManager:GetCardIconConf(CardInfo.card_icon_selected)
    if CardIconConf then
      local AvatarPath = CardIconConf.icon_resource_path
      AvatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BigHeadIcon256/", AvatarPath, AvatarPath)
      self.head:SetPath(AvatarPath)
    end
    if CardInfo.card_appearance_info and CardInfo.card_appearance_info.card_skin_selected then
      local CardSkinConf = _G.DataConfigManager:GetCardSkinConf(CardInfo.card_appearance_info.card_skin_selected)
      local Path = string.format(UEPath.CARD_COMMON_PATH, CardSkinConf.skin_resource_path, "luopan", CardSkinConf.skin_resource_path, "luopan")
      self.Icon:SetPath(Path)
    end
  else
    Log.Debug("\230\178\161\230\156\137\233\187\152\232\174\164\229\144\141\231\137\135\229\164\180\229\131\143\230\149\176\230\141\174,\232\175\183\230\159\165\231\156\139\229\144\142\229\143\176\230\149\176\230\141\174")
  end
end

function UMG_LobbyMainInner_C:OnDisable()
end

function UMG_LobbyMainInner_C:OnDeactive()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  end
  Log.Debug("UMG_LobbyMainInner_C:OnDeactive")
  _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, "LobbyMainInner")
  self:CancelDelay()
  self:OnRemoveEventListener()
  self.IconList = {}
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer and localPlayer.viewObj then
    if localPlayer.viewObj.Mesh then
      localPlayer.viewObj.Mesh:SetRenderCustomDepth(false)
      localPlayer.viewObj.Mesh:SetCustomDepthStencilValue(0)
    end
    if not self.isNormal and self.OpenType ~= MainUIModuleEnum.CompassOpenType.COMPASS_2D_IGNORE_PLAYER then
      localPlayer.viewObj:SetActorHiddenInGame(false)
    end
  end
  self:UnShowCompass(true)
  if self.module then
    self.module.LobbyMainInnerClosing = false
  else
    Log.Error("UMG_LobbyMainInner_C module is nil")
  end
  self:DoCloseThings()
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "LobbyMainInner")
  _G.NRCAudioManager:SetLobbyMainInnerOpen(false)
  table.clear(self.panel_icon_panel_map)
  self.BattleIcon = nil
  self.TaskIcon = nil
  self.MapIcon = nil
  self.HandbookIcon = nil
  self.PetIcon = nil
  self.BagIcon = nil
  if self.LoadQueue then
    self.LoadQueue:Release()
  end
  self.LoadQueue = nil
  if self.AwardBtnDelayHandle then
    _G.DelayManager:CancelDelayById(self.AwardBtnDelayHandle)
    self.AwardBtnDelayHandle = nil
  end
  if self.WishLoopAudioID then
    _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:UpdateWishCrystalInfo", false, 0.2)
    self.WishLoopAudioID = nil
  end
  self.preDownLoadActivityInst = nil
end

function UMG_LobbyMainInner_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn1.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.GlobalShutdown_Btn, self.OnClickCloseBtn)
  self:AddButtonListener(self.headButton, self.OnClickLevel)
  self:AddButtonListener(self.ChangeNumber, self.OnUinCopyBtnClick)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnMainUISubPanelOpen, self.OnSubUIOpened)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnMainUISubPanelClosed, self.OnSubUIClosed)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.BackToWorldFast, self.OnBackToWorldFast)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnClickTaskTrackToWorldFast, self.OnTaskTrackToWorldFast)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnMainUILuopanChanged, self.OnMainUILuopanChanged)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnMainUIFuncPanelOpen, self.OnFuncPanelOpenClick)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnLobbyMainInnerBlackTransitionFinish, self.OpenSubPanel)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnLobbyMainInnerBlackTransitionInBegin, self.OnBlackScreenTransitionInBegin)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, _G.SceneEvent.LoadMapStart, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.UI_Refresh_TeachRed, self.RefreshTeachRed)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnMainUIVisibileBottomIconList, self.OnFuncVisibileBottomIconListClick)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.OnLobbyMainInnerIconLoaded, self.OnLobbyMainInnerIconLoaded)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, MainUIModuleEvent.ChangeMoreServiceClickState, self.UpdateButtonMoreListFocus)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, PreDownloadEvent.PreDownloadStart, self.OnPreDownloadStart)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, PreDownloadEvent.PreDownloadPaused, self.OnPreDownloadPaused)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
  _G.NRCEventCenter:RegisterEvent("UMG_LobbyMainInner_C", self, PreDownloadEvent.PreDownloadBooked, self.OnPreDownloadBooked)
  _G.NRCModuleManager:GetModule("ActivityModule"):RegisterEvent(self, ActivityModuleEvent.PreDownloadActivityDataUpdate, self.OnPredownloadActivityDataUpdate)
end

function UMG_LobbyMainInner_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.UI_Refresh_TeachRed, self.RefreshTeachRed)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainUISubPanelOpen, self.OnSubUIOpened)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainUISubPanelClosed, self.OnSubUIClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.BackToWorldFast, self.OnBackToWorldFast)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainUILuopanChanged, self.OnMainUILuopanChanged)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnClickTaskTrackToWorldFast, self.OnTaskTrackToWorldFast)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainUIFuncPanelOpen, self.OnFuncPanelOpenClick)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerBlackTransitionFinish, self.OpenSubPanel)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerBlackTransitionInBegin, self.OnBlackScreenTransitionInBegin)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.SceneEvent.LoadMapStart, self.OnEnterSceneFinishNtyAck)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnLobbyMainInnerIconLoaded, self.OnLobbyMainInnerIconLoaded)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.OnMainUIVisibileBottomIconList, self.OnFuncVisibileBottomIconListClick)
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.ChangeMoreServiceClickState, self.UpdateButtonMoreListFocus)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadStart, self.OnPreDownloadStart)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadPaused, self.OnPreDownloadPaused)
  _G.NRCEventCenter:UnRegisterEvent(self, PreDownloadEvent.PreDownloadBatchReturn, self.OnPreDownloadFinished)
  _G.NRCModuleManager:GetModule("ActivityModule"):UnRegisterEvent(self, ActivityModuleEvent.PreDownloadActivityDataUpdate)
end

function UMG_LobbyMainInner_C:OnPreDownloadStart()
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    return
  end
  self:StopAnimation(self.Down_Normal)
  self:PlayAnimation(self.Down_Loop, 0, 9999)
end

function UMG_LobbyMainInner_C:OnPreDownloadPaused()
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    return
  end
  self:StopAnimation(self.Down_Loop)
  self:PlayAnimation(self.Down_Normal)
end

function UMG_LobbyMainInner_C:OnPreDownloadFinished(bSuccess)
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    return
  end
  if bSuccess then
    self.Download:SetActiveWidgetIndex(2)
  end
end

function UMG_LobbyMainInner_C:OnPreDownloadBooked()
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    return
  end
  local downloadTips = _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked") and _G.DataConfigManager:GetActivityGlobalConfig("pre_download_booked").str or ""
  self.Download:SetActiveWidgetIndex(0)
  self.DownloadText:SetText(downloadTips)
end

function UMG_LobbyMainInner_C:OnPredownloadActivityDataUpdate(updateData)
  if RocoEnv.PLATFORM_WINDOWS and not RocoEnv.IS_EDITOR then
    return
  end
  if updateData and updateData.rewarded and not _G.NRCPreDownloadManager:IfNeedToDownload() then
    self.Download:SetActiveWidgetIndex(2)
  end
end

function UMG_LobbyMainInner_C:OnEnterSceneFinishNtyAck()
  self:ForceCloseCompass()
end

function UMG_LobbyMainInner_C:RefreshTeachRed()
end

function UMG_LobbyMainInner_C:OpenPanelTimeOut()
  if not UE4.UObject.IsValid(self) then
    Log.Error("UMG_LobbyMainInner_C:OpenPanelTimeOut No!!!! panel is Invalid", self.SubPanelType)
    return
  end
  Log.Error("UMG_LobbyMainInner_C:OpenPanelTimeOut No!!!!", self.SubPanelType)
  self.IsWaitingForSubPanel = 0
  self:SetClickable()
  local subPanelIcon = self.panel_icon_panel_map[self.SubPanelType]
  if UE4.UObject.IsValid(subPanelIcon) then
    subPanelIcon:PlayAnimation(subPanelIcon.UnSelect)
  else
    Log.Warning("SubPanelIcon Is InValid")
  end
  if self.SubPanelType ~= MainUIModuleEnum.SubPanelOpenType.NoneUI then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.DoBlackScreenTransitionOut)
  elseif self.FunctionUIType ~= _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_NoneType then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.DoNormalBlackScreenTransitionOut)
  end
end

function UMG_LobbyMainInner_C:OnFuncPanelOpenClick(type)
  if not self.ButtonClickable then
    return
  end
  if type == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_GOODS_SHOP then
  else
    self:SetUnClickable()
  end
  self.IsWaitingForSubPanel = 1
  self:CancelDelay()
  self:DelaySeconds(20, self.OpenPanelTimeOut, self)
  self.SubPanelType = MainUIModuleEnum.SubPanelOpenType.NoneUI
  if type == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FASHIONMALL then
    _G.NRCAudioManager:PlaySound2DAuto(40002001, "UMG_LobbyMainInner_C:LobbyMainInnerUIType.FashionMall")
  else
    _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_LevelMain_C:OnFriendIconClicked")
  end
  self.FunctionUIType = type
  self:OpenSubPanel()
  if self.Halo then
    self.Halo:CollectWishCrystal(false)
  end
  if self.WishLoopAudioID then
    _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:OnSubUIOpened", false, 0.2)
    self.WishLoopAudioID = nil
  end
end

function UMG_LobbyMainInner_C:OnFuncVisibileBottomIconListClick(IsVisibile)
  self.ButtomIconPanel = self.BottomIconList:GetPanel()
  if not self.ButtomIconPanel then
    return false
  end
  self:BottomIconListVisibileChange(IsVisibile)
end

function UMG_LobbyMainInner_C:UpdateButtonMoreListFocus(IsNil)
  local ListIsVisible = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetBottomIconListVisible)
  if ListIsVisible and self.ButtomIconPanel then
    if IsNil then
      self.ButtomIconPanel:SetIsFocusable(false)
    else
      self.ButtomIconPanel:SetIsFocusable(true)
    end
  end
end

function UMG_LobbyMainInner_C:BottomIconListVisibileChange(IsVisibile)
  if IsVisibile then
    self.ButtomIconPanel:SetData()
    self.ButtomIconPanel:SetIsFocusable(true)
    local PlayerController = _G.UE4Helper.GetPlayerCharacter(0):GetController()
    self.ButtomIconPanel:SetUserFocus(PlayerController)
    self:UpdateButtonMoreListFocus(false)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetBottomIconListVisible, IsVisibile)
    self.BottomIconList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:UpdateButtonMoreListFocus(true)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetBottomIconListVisible, IsVisibile)
    self.BottomIconList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyMainInner_C:OnFriendIconClicked()
  if self.Lock then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FRIEND)
  if isBan then
    return
  end
  self:SetIsLock(true)
  self.OpenFriend = true
  self:StopAnimation(self.Loop)
  self:PlayAnimation(self.Out)
end

function UMG_LobbyMainInner_C:IsFunctionBan(type, autoPopMsg)
  if type == MainUIModuleEnum.SubPanelOpenType.BattleUI then
    return _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK, autoPopMsg)
  elseif type == MainUIModuleEnum.SubPanelOpenType.TaskUI then
    return _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_TASK, autoPopMsg)
  elseif type == MainUIModuleEnum.SubPanelOpenType.MapUI then
    return _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, autoPopMsg)
  elseif type == MainUIModuleEnum.SubPanelOpenType.HandbookUI then
    return _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK, autoPopMsg)
  elseif type == MainUIModuleEnum.SubPanelOpenType.PetUI then
    local functionBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET, autoPopMsg)
    if functionBan then
      return true
    end
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    if not battlePetList[1] then
      return true
    end
    return false
  elseif type == MainUIModuleEnum.SubPanelOpenType.BagUI then
    return _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BAG, autoPopMsg)
  end
end

function UMG_LobbyMainInner_C:OnBattleIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.BattleUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.BattleIcon:PlayClickLockAnimation()
    return
  end
  NRCProfilerLog:NRCClickBtn(true, "MagicManualMainPanel")
  self.BattleIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008031, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.BattleUI)
end

function UMG_LobbyMainInner_C:OnTaskIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.TaskUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.TaskIcon:PlayClickLockAnimation()
    return
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "TaskMainPanel")
  self.TaskIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008032, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.TaskUI)
end

function UMG_LobbyMainInner_C:OnHandbookIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.HandbookUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.HandbookIcon:PlayClickLockAnimation()
    return
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "HandbookCover")
  self.HandbookIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008034, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.HandbookUI)
end

function UMG_LobbyMainInner_C:OnMapIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.MapUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.MapIcon:PlayClickLockAnimation()
    return
  end
  local bInDungeon = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.IsInDungeon)
  if bInDungeon then
    local DungeonInfo = _G.NRCModuleManager:DoCmd(InstanceModuleCmd.GetDungeonInfo)
    if DungeonInfo then
      local dungeonId = DungeonInfo.dungeon_id
      if dungeonId > 0 then
        local dungeonConf = _G.DataConfigManager:GetDungeonConf(dungeonId)
        if nil == dungeonConf or 0 == dungeonConf.world_scene_id then
          local tips = _G.DataConfigManager:GetLocalizationConf("ban_openmap_tips").msg
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
          return
        end
      end
    end
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "MainBigMap")
  self.MapIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008033, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.MapUI)
end

function UMG_LobbyMainInner_C:OnBagIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.BagUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.BagIcon:PlayClickLockAnimation()
    return
  end
  NRCProfilerLog:NRCClickBtn(true, "BagMain")
  self.BagIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008036, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.BagUI)
end

function UMG_LobbyMainInner_C:OnPetIconClicked()
  if not self.ButtonClickable then
    return
  end
  local icon_type = MainUIModuleEnum.SubPanelOpenType.PetUI
  local isBan = self:IsFunctionBan(icon_type, true)
  if isBan then
    self.PetIcon:PlayClickLockAnimation()
    return
  end
  _G.NRCProfilerLog:NRCClickBtn(true, "PetInfoMain")
  self.PetIcon:PlayClickAnimation(self, self.OnSelectAnimDone)
  _G.NRCAudioManager:PlaySound2DAuto(40008035, "UMG_LevelMain_C:OnFriendIconClicked")
  _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelOpen, icon_type)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SendTLog, MainUIModuleEnum.FunctionID.PetUI)
end

function UMG_LobbyMainInner_C:OnConstruct()
  self:BindInputAction()
  if self.CollectParticle then
    self.CollectParticle:SetActivate(false)
    self.CollectParticle:HideParticleWidget(true)
  end
end

function UMG_LobbyMainInner_C:OnDestruct()
  self:UnBindInputAction()
end

function UMG_LobbyMainInner_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MainInnerUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local actions = {
    {
      name = "IA_CloseMainInnerUI",
      method = "OnPcClose"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, action.method)
  end
end

function UMG_LobbyMainInner_C:UnBindInputAction()
  local actions = {
    {
      name = "IA_CloseMainInnerUI"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  end
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_MainInnerUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_LobbyMainInner_C:OnPcClose()
  self:OnClickCloseBtn()
end

function UMG_LobbyMainInner_C:SwitchToMainCamera()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerCameraManager = player:GetUEController().PlayerCameraManager
  local speed = _G.DataConfigManager:GetGlobalConfigByKeyType("camera_speed_unfold_compass", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str
  playerCameraManager:SwitchMainUiCamera(true, tonumber(speed))
end

function UMG_LobbyMainInner_C:OnMainUILuopanChanged(stateValue, idleValue)
end

function UMG_LobbyMainInner_C:UpdateUIData()
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local playerLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  self.levelText:SetText(string.format("%d", playerLevel))
  self.MagicianNameText:SetText(_G.DataModelMgr.PlayerDataModel:GetPlayerName())
  self.NRCText_145:SetText(playerUin)
  self.ChangeNumber:SetVisibility(UE4.ESlateVisibility.Visible)
  local Exp, ExpMax = LevelUpUtils.GetExpAndMax()
  if ExpMax > 0 then
    self.ExpProgressBar:SetPercent(Exp / ExpMax)
    self.ExpProgressBarText:SetText(string.format("%d/%d", Exp, ExpMax))
  else
    self.ExpProgressBarText:SetText(LuaText.role_exp_lv_max)
    self.ExpProgressBar:SetPercent(1)
  end
  self.Yellow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local req = _G.ProtoMessage:newZoneQueryLevelAwardReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_LEVEL_AWARD_REQ, req, self, self.GetZoneQueryLevelAwardRsp, false, false)
end

function UMG_LobbyMainInner_C:HideUMG(immediate)
  if immediate then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
  end
end

function UMG_LobbyMainInner_C:HidePlayerAndUI()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.isNormal then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.viewObj then
      player.viewObj:SetActorHiddenInGame(true)
    end
    if UE4.UObject.IsValid(self.Halo) then
      self.Halo:SetActorHiddenInGame(true)
    end
  end
end

function UMG_LobbyMainInner_C:ShowUMGOption(immediate)
  self:SetUnClickable()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:ShowIcons(immediate)
  self:ShowWishCrystalRedPoint(immediate)
end

function UMG_LobbyMainInner_C:ShowUMG()
  Log.Debug("UMG_LobbyMainInner_C:ShowUMG")
  self:ShowUMGOption(false)
end

function UMG_LobbyMainInner_C:ShowIcons(immediate, bNoRedPointAnim)
  self.BattleIcon:Show(immediate, 0.06, bNoRedPointAnim)
  self.TaskIcon:Show(immediate, 0.12, bNoRedPointAnim)
  self.MapIcon:Show(immediate, 0.18, bNoRedPointAnim)
  self.HandbookIcon:Show(immediate, 0.24, bNoRedPointAnim)
  self.PetIcon:Show(immediate, 0.3, bNoRedPointAnim)
  self.BagIcon:Show(immediate, 0.36, bNoRedPointAnim)
end

function UMG_LobbyMainInner_C:HideIcons(immediate)
  self.BattleIcon:Hide(immediate)
  self.TaskIcon:Hide(immediate)
  self.MapIcon:Hide(immediate)
  self.HandbookIcon:Hide(immediate)
  self.PetIcon:Hide(immediate)
  self.BagIcon:Hide(immediate)
end

function UMG_LobbyMainInner_C:GetZoneQueryLevelAwardRsp(rsp)
  if rsp.awards and rsp.awards.valid_awards and #rsp.awards.valid_awards > 0 then
    for i = 1, #rsp.awards.valid_awards do
      local award = rsp.awards.valid_awards[i]
      local AllAwards = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.ROLE_WORLD_LEVEL_MAP_CONF):GetAllDatas()
      for j = 1, #AllAwards do
        if AllAwards[j] and AllAwards[j].grade_num == award and 1 == AllAwards[j].list_type then
          return
        end
      end
    end
  else
    local worldLevelConf = LevelUpUtils.GetTargetWorldLevelConf()
    if worldLevelConf then
      local req = _G.ProtoMessage:newZoneWorldLevelTaskQueryReq()
      req.world_level_task_id = worldLevelConf.update_task_id
      Log.Debug("\229\143\145\233\128\129\229\141\143\232\174\174\230\159\165\232\175\162\228\187\187\229\138\161\231\138\182\230\128\129", table.tostring(req))
      _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_WORLD_LEVEL_TASK_QUERY_REQ, req, self, self.GetSelectTaskTypeInfo)
      return
    else
    end
  end
end

function UMG_LobbyMainInner_C:GetSelectTaskTypeInfo(rsp)
  if 0 ~= rsp.ret_info.ret_code or rsp.world_level_task_state == _G.ProtoEnum.WorldLevelTaskState.WLTS_ENABLE_TO_UNLOCK then
  end
end

function UMG_LobbyMainInner_C:GenerateLuopan(luopanClass)
  local world = _G.UE4Helper.GetCurrentWorld()
  self.Halo = world:SpawnActor(luopanClass, UE4.FTransform(UE4.FQuat(), UE4.FVector(0, 0, 0)), UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, world)
  self.Halo.NRCNiagaraHalo:SetComponentActive(true)
end

function UMG_LobbyMainInner_C:OnSubUIOpened(SubPanelType)
  _G.NRCAudioManager:SetLobbyMainInnerOpen(false)
  self.sub_panel_loaded = false
  self.select_anim_done = false
  Log.Debug("UMG_LobbyMainInner_C:OnSubUIOpened", SubPanelType)
  self:SetUnClickable()
  self:CancelDelay()
  self:DelaySeconds(20, self.OpenPanelTimeOut, self)
  self:PreLoadBlackScreen()
  self.SubPanelType = SubPanelType
  self.FunctionUIType = _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_NoneType
  if self.SubPanelType then
    if SubPanelType == MainUIModuleEnum.SubPanelOpenType.HandbookUI then
      self.IsWaitingForSubPanel = 2
    else
      self.IsWaitingForSubPanel = 1
    end
  else
    for _, Icon in pairs(self.panel_icon_panel_map) do
      Icon:PlayDisappearAnimation()
    end
    self.UMG_LobbyMainInnerParticle:PlayCollapse()
    if self.isNormal then
      if UE4.UObject.IsValid(self.Halo) then
        self.Halo:HaloCollapse()
      end
    else
      self:PlayHaloAnimation(self.Close_Luopan)
    end
    self:HideIcons(true)
    self:PlayAnimation(self.Close_2)
    self.ItemRedPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.AwardBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PreLoadSubPanel()
  if self.Halo then
    self.Halo:CollectWishCrystal(false)
  end
  if self.WishLoopAudioID then
    _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:OnSubUIOpened", false, 0.2)
    self.WishLoopAudioID = nil
  end
end

function UMG_LobbyMainInner_C:OnSubUIClosed(IsLevelMain, bHadOpenSubPanelSuccess)
  UE4Helper.SetEnableWorldRendering(nil)
  if not IsLevelMain and _G.NRCModuleManager:DoCmd(_G.LevelUpUIModuleCmd.HasLevelMainPanel) then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.viewObj then
      player.viewObj:SetActorHiddenInGame(false)
    end
    if UE4.UObject.IsValid(self.Halo) then
      self.Halo:SetActorHiddenInGame(false)
    end
    return
  end
  self:UpdateUIData()
  if nil == bHadOpenSubPanelSuccess then
    bHadOpenSubPanelSuccess = true
  end
  _G.NRCAudioManager:SetLobbyMainInnerOpen(true)
  Log.Debug("UMG_LobbyMainInner_C:OnSubUIClosed", self.SubPanelType)
  if bHadOpenSubPanelSuccess then
    self:SetUnClickable()
  else
    self:SetClickable()
  end
  if self.isNormal then
    if UE4.UObject.IsValid(self.Halo) then
      self.Halo:HaloExpand()
    end
    if not self.SubPanelType then
      self:ShowIcons(false)
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player.viewObj then
      player.viewObj:SetActorHiddenInGame(false)
    end
    if UE4.UObject.IsValid(self.Halo) then
      self.Halo:SetActorHiddenInGame(false)
    end
  else
    self.HaloPanelLoader:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self:ShowIcons(true, true)
  end
  if nil == self.SubPanelType then
    self.UMG_LobbyMainInnerParticle:PlayExpand()
    if self.isNormal then
    else
      self:PlayHaloAnimation(self.Open_Luopan)
    end
  elseif bHadOpenSubPanelSuccess then
    for _, UI in pairs(self.panel_icon_panel_map) do
      UI:PlayAppearAnimation()
    end
  else
    local iconWidget = self.panel_icon_panel_map[self.SubPanelType]
    if iconWidget and iconWidget.PlayUnSelectAnimation then
      iconWidget:PlayUnSelectAnimation()
    end
  end
  self.SubPanelType = MainUIModuleEnum.SubPanelOpenType.NoneUI
  self:UpdateHead()
  if bHadOpenSubPanelSuccess then
    self:PlayAnimation(self.Open_2)
  end
  self:ShowWishCrystalRedPoint(true)
  self:CancelCollect()
end

function UMG_LobbyMainInner_C:UnShowCompass(bClose)
  Log.Debug("UMG_LobbyMainInner_C:UnShowCompass", bClose)
  if not bClose then
    self:PlayCompassEndSkill()
  end
  if UE4.UObject.IsValid(self.Halo) then
    if self.Halo.K2_DestroyActor then
      self.Halo:K2_DestroyActor()
    end
    self.Halo = nil
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and UE4.UObject.IsValid(player.viewObj) then
    local skillComponent = player.viewObj.RocoSkill
    if self.StartSkill then
      skillComponent:RemoveSkillObj(self.StartSkill)
    end
    if self.PostProcessSkill then
      self.PostProcessSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultSuccessful)
      self.PostProcessSkill = nil
      skillComponent:RemoveSkillObj(self.PostProcessSkill)
    end
    if self.EndSkill then
      skillComponent:RemoveSkillObj(self.EndSkill)
    end
    player:SendEvent(PlayerModuleEvent.ON_LUOPAN_STATE_CHANGED, false)
    if player.inputComponent then
      player.inputComponent:SetInputEnable(self, true)
    end
    local playerCtrl = player:GetUEController()
    if playerCtrl then
      playerCtrl:SetFadeEnable(true)
    end
  end
end

function UMG_LobbyMainInner_C:FastClose()
  Log.Debug("UMG_LobbyMainInner_C:FastClose")
  self:SetUnClickable()
  self:ResetPlayer()
  self:DoClose()
end

function UMG_LobbyMainInner_C:OnBackToWorldFast()
  self:SetClickable()
  self:OnClickCloseBtn()
  self:HideAllIcon()
end

function UMG_LobbyMainInner_C:HideAllIcon()
  if self.IconPanel and self.IconPanel.SetVisibility then
    self.IconPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    Log.Warning("UMG_LobbyMainInner.IconPanel\228\184\141\232\167\129\228\186\134!")
  end
  if self.CloseBtn1 and self.CloseBtn1.SetVisibility then
    self.CloseBtn1:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    Log.Warning("UMG_LobbyMainInner.CloseBtn\228\184\141\232\167\129\228\186\134!!")
  end
  if self.GlobalShutdown_Btn and self.GlobalShutdown_Btn.SetVisibility then
    self.GlobalShutdown_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    Log.Warning("UMG_LobbyMainInner.CloseBtn\228\184\141\232\167\129\228\186\134!!")
  end
end

function UMG_LobbyMainInner_C:LoadSubPanel()
  Log.Debug("UMG_LobbyMainInner_C:LoadSubPanel", self.SubPanelType)
  if self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BattleUI then
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManual)
  elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.TaskUI then
    _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.OpenTaskPanel)
  elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.MapUI then
    _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap)
  elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.HandbookUI then
    _G.NRCProfilerLog:NRCClickBtn(true, "HandbookCover")
    _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookCover, {isPlayCompass = true})
  elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.PetUI then
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
      subPanelIndex = 4,
      callback = self.OnUMGLoadFinished
    }, nil, nil, true)
  elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BagUI then
    _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanel, BagModuleEnum.DisplayMode.Zone)
  end
end

function UMG_LobbyMainInner_C:GetIconLoopTime(icon_type)
  local panel_icon = self.panel_icon_panel_map[self.SubPanelType]
  if panel_icon then
    return panel_icon:GetAnimationCurrentTime(panel_icon.Loop)
  else
    Log.Error("\230\151\160\232\174\186\229\166\130\228\189\149\228\184\141\229\186\148\232\175\165\232\181\176\229\136\176\232\191\153\233\135\140\239\188\140\229\174\131\230\156\137\229\164\167\230\175\155\231\151\133\239\188\140\231\156\139\231\156\139\228\185\139\229\137\141\232\182\133\230\151\182\230\178\161\230\156\137")
    return 0
  end
end

function UMG_LobbyMainInner_C:OnBlackScreenTransitionInBegin()
  Log.Debug("UMG_LobbyMainInner_C:OnBlackScreenTransitionInBegin")
  local panel_icon = self.panel_icon_panel_map[self.SubPanelType]
  if panel_icon then
  else
    Log.Error("UMG_LobbyMainInner_C:OnBlackScreenTransitionInBegin \231\138\182\230\128\129\231\130\184\228\186\134", self.SubPanelType)
  end
end

function UMG_LobbyMainInner_C:OpenSubPanel()
  Log.Debug("UMG_LobbyMainInner_C:OpenSubPanel", self.SubPanelType, self.FunctionUIType)
  if self.SubPanelType ~= MainUIModuleEnum.SubPanelOpenType.NoneUI then
    if self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BattleUI then
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManual)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.TaskUI then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.OpenTaskPanel)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.MapUI then
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.HandbookUI then
      _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookCover, {isPlayCompass = true})
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.PetUI then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
        subPanelIndex = 4,
        callback = self.OnUMGLoadFinished
      }, nil, nil, true)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BagUI then
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.OpenBagMainPanel, BagModuleEnum.DisplayMode.Zone)
    end
  elseif self.FunctionUIType ~= _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_NoneType then
    if self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FRIEND then
      _G.NRCProfilerLog:NRCClickBtn(true, "Friend")
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MAIL then
      NRCProfilerLog:NRCClickBtn(true, "EmailMainPanel")
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.OpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SHOP then
      NRCProfilerLog:NRCClickBtn(true, "Shop")
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.OpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_ACTIVITY then
      _G.NRCProfilerLog:NRCClickBtn(true, "ActivityMainPanel")
      _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenMainPanel, nil, nil, ActivityEnum.MainPanelOpenSource.LobbyMainInner)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_BATTLEPASS then
      _G.NRCProfilerLog:NRCClickBtn(true, "BattlePassAwardMain")
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsLobbyMainInnerOpenPass)
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenBattlePass, nil, false, nil, true)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SETTING then
      NRCProfilerLog:NRCClickBtn(true, "SystemSettingMain")
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_TEACHING then
      NRCProfilerLog:NRCClickBtn(true, "TeachingManual")
      _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_ROLECARD then
      _G.NRCProfilerLog:NRCClickBtn(true, "StudentCard")
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OpenStudentCardPanel, nil, FriendEnum.AdminFriendType.Own, FriendEnum.Source.Friend, nil)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MUSICCOLLECTION then
      NRCProfilerLog:NRCClickBtn(true, "MusicCollectionPanel")
      _G.NRCModuleManager:DoCmd(_G.MusicCollectionModuleCmd.OnOpenMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FASHIONMALL then
      NRCProfilerLog:NRCClickBtn(true, "SeasonalCombinationBagShop")
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.OpenSeasonalCombinationBagShop)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SEASON then
      NRCProfilerLog:NRCClickBtn(true, "SeasonIntegrationPanel")
      _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_GOODS_SHOP then
      local goodsShopSkipId = (_G.DataConfigManager:GetGlobalConfig("goods_shop_skip_id") or {}).num
      if goodsShopSkipId then
        ActivityUtils.DoActivityOptionCmd(goodsShopSkipId)
      end
    end
  end
end

function UMG_LobbyMainInner_C:PreLoadSubPanel()
  Log.Debug("UMG_LobbyMainInner_C:PreLoadSubPanel", self.SubPanelType)
  if self.SubPanelType ~= MainUIModuleEnum.SubPanelOpenType.NoneUI then
    if self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BattleUI then
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.PreLoadMagicManual)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.TaskUI then
      _G.NRCModuleManager:DoCmd(_G.TaskModuleCmd.PreLoadTaskMainPanel)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.MapUI then
      _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.PreLoadWorldMap)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.HandbookUI then
      _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.PreLoadHandbookPanel)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.PetUI then
      _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.PreLoadPetMain)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.BagUI then
      _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.PreLoadBagMainPanel)
    elseif self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.PreDownload then
      _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.PreLoadDownloadActivityPanel)
    end
  elseif self.FunctionUIType ~= _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_NoneType then
    if self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FRIEND then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MAIL then
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SHOP then
      _G.NRCModuleManager:DoCmd(_G.ShopModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_ACTIVITY then
      _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_BATTLEPASS then
      _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.PreLoadBattlePass)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SETTING then
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_TEACHING then
      _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_ROLECARD then
      _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PreLoadStudentCardPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MUSICCOLLECTION then
      _G.NRCModuleManager:DoCmd(_G.MusicCollectionModuleCmd.PreLoadMainPanel)
    elseif self.FunctionUIType == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FASHIONMALL then
      _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.PreLoadSeasonalCombinationBagShop)
    end
  end
end

function UMG_LobbyMainInner_C:OnClickExitBtn()
  local StepAwayDialog = DialogContext()
  StepAwayDialog:SetCallback(self, self.ReturnToLogin)
  StepAwayDialog:SetContent(RocoEnv.PLATFORM_WINDOWS and LuaText.setting_quit_the_client or LuaText.setting_switch_account)
  StepAwayDialog:SetMode(DialogContext.Mode.OK_CANCEL)
  StepAwayDialog:SetTitle(LuaText.TIPS)
  StepAwayDialog:SetButtonText(LuaText.umg_systemsettingmain_5, LuaText.umg_systemsettingmain_6)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, StepAwayDialog)
end

function UMG_LobbyMainInner_C:ReturnToLogin(result)
  if result then
    if _G.ZoneServer.bPause then
      _G.ZoneServer:Resume()
    end
    _G.AppMain.BackToLogin()
  end
end

function UMG_LobbyMainInner_C:OnClickCloseBtn()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008006, "UMG_LobbyMainInner_C:OnClickCloseBtn")
  if not self.ButtonClickable then
    return
  end
  self:DoClose()
end

function UMG_LobbyMainInner_C:ForceCloseCompass()
  Log.Debug("UMG_LobbyMainInner_C:ForceCloseCompass")
  self.Died = true
  self:BackBigWorld()
  self:SetUnClickable()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj then
    if self.OpenType ~= MainUIModuleEnum.CompassOpenType.COMPASS_2D_IGNORE_PLAYER then
      player.viewObj:SetActorHiddenInGame(false)
    end
    local ctrl = player:GetUEController()
    ctrl:SetUICameraState(_G.MainUIModuleEnum.MainUICameraState.Normal)
    if self.isNormal then
      local speed = _G.DataConfigManager:GetGlobalConfigByKeyType("camera_speed_retract_compass", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str
      local playerCameraManager = player:GetUEController().PlayerCameraManager
      playerCameraManager:SwitchMainUiCamera(false, tonumber(speed))
    end
    player:StopAllMontage(0.01)
    player.viewObj.RocoSkill:stopcurrentskill()
    if self.PostProcessSkill then
      player.viewObj.RocoSkill:CancelSkill(self.PostProcessSkill, UE4.ESkillActionResult.SkillActionResultSuccessful)
    end
  end
  if self.StartSkill then
    self.StartSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.StartSkill:Destroy()
  end
  if self.PostProcessSkill then
    self.PostProcessSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.PostProcessSkill:Destroy()
  end
  if self.EndSkill then
    self.EndSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.EndSkill:Destroy()
  end
  self:DestroyActor()
  self:RealCloseLobbyMainInner()
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCPanelManager:CloseAllPanelByLayer(_G.Enum.UILayerType.UI_LAYER_POPUP)
end

function UMG_LobbyMainInner_C:OnTaskTrackToWorldFast()
  self:SetUnClickable()
  self:OnBackToWorldFast()
end

function UMG_LobbyMainInner_C:OnUinCopyBtnClick()
  _G.NRCAudioManager:PlaySound2DAuto(1001, "UMG_StudentCard_C:OnChangeNumber")
  UE4.UNRCStatics.ClipboardCopy(self.NRCText_145:GetText())
  _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.card_copy_UID_tips)
end

function UMG_LobbyMainInner_C:OnClickLevel()
  if not self.ButtonClickable then
    return
  end
  self:SetUnClickable()
  _G.NRCModuleManager:DoCmd(_G.LevelUpUIModuleCmd.RequestOpenLevelPanel)
end

function UMG_LobbyMainInner_C:PlayerAnim()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  player.inputComponent:SetInputEnable(self, false)
end

function UMG_LobbyMainInner_C:PlayCompassStartSkill()
  Log.Debug("UMG_LobbyMainInner_C:PlayCompassStartSkill")
  local assetPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Compass/G6_Scene_Compass_Star.G6_Scene_Compass_Star"
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local caster = player.viewObj
  local skillComponent = caster and caster.RocoSkill
  local skillProxy = skillComponent and RocoSkillProxy.Create(assetPath, skillComponent, 99999)
  if skillProxy then
    self.StartSkill = skillProxy
    skillProxy:SetCaster(caster)
    local targets = {}
    table.insert(targets, self.Halo)
    skillProxy:SetTargets(targets)
    skillProxy:RegisterEventCallback("ShowUI", self, self.ShowUMG)
    skillProxy:RegisterEventCallback("PlayStart", self, self.PlayAnimStart)
    skillProxy:RegisterEventCallback("PlayIdle", self, self.PlayAnimIdle)
    skillProxy:RegisterEventCallback("End", self, self.CompassStarFinish)
    skillProxy:RegisterEventCallback("PreEnd", self, self.CompassStarFinish)
    skillProxy:RegisterEventCallback("Interrupt", self, self.SkillInterrupt)
    skillProxy:SetPassive(false)
    skillProxy:PlaySkill(self, self.StartSkillCallback)
  else
    Log.Error(string.format("FindOrAddSkillObj %s failed!!!! Why??????", assetPath))
    self:DelayFrames(5, self.ForceCloseCompass, self)
    return
  end
  for _, Icon in pairs(self.panel_icon_panel_map) do
    Icon:HideRedPoint(true)
  end
  self:SetUnClickable()
  self.UMG_LobbyMainInnerParticle:PlayStart()
end

function UMG_LobbyMainInner_C:StartSkillCallback(skillProxy, result)
  _G.UE4Helper.SetDesiredResLoadMode(_G.UE4Helper.ResLoadMode.Default, "LobbyMainInner")
  Log.Debug("UMG_LobbyMainInner_C:StartSkillCallback", result)
  if result == UE4.ESkillStartResult.Success then
    return
  end
  if not self.Died then
    Log.Error("\228\184\186\228\187\128\228\185\136\232\131\189\230\146\173\229\164\177\232\180\165\229\149\138\239\188\140\231\187\157\228\186\134\227\128\130\227\128\130\227\128\130")
    self:ForceCloseCompass()
  end
end

function UMG_LobbyMainInner_C:PlayCompassPostPrecessSkill()
  Log.Debug("UMG_LobbyMainInner_C:PlayCompassPostPrecessSkill")
  local assetPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Compass/G6_Scene_Compass_PostProcess.G6_Scene_Compass_PostProcess"
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local caster = player.viewObj
  if caster then
    local skillComponent = caster.RocoSkill
    if skillComponent then
      local skillProxy = RocoSkillProxy.Create(assetPath, skillComponent, PriorityEnum.Local_Player_Perform)
      if skillProxy then
        self.PostProcessSkill = skillProxy
        skillProxy:SetCaster(caster)
        local targets = {}
        table.insert(targets, self.Halo)
        skillProxy:SetTargets(targets)
        skillProxy:SetPassive(true)
        skillProxy:PlaySkill()
      else
        Log.Error(string.format("FindOrAddSkillObj %s failed!!!! Why??????", assetPath))
        self:DelayFrames(5, self.ForceCloseCompass, self)
        return
      end
    end
  end
end

function UMG_LobbyMainInner_C:SkillInterrupt(Event, Skill)
  Log.Info("UMG_LobbyMainInner_C \230\138\128\232\131\189\232\162\171\230\137\147\230\150\173\228\186\134", Skill and Skill:GetFullName())
  if not self.Died then
    self:ForceCloseCompass()
  end
end

function UMG_LobbyMainInner_C:CompassStarFinish(Event, Skill)
  Log.Debug("UMG_LobbyMainInner_C:CompassStarFinish")
  _G.NRCEventCenter:DispatchEvent(_G.GuidanceModuleEvent.OnPanelAllReady, self.panelData)
  if self.Died then
    Log.Error("\228\184\187\231\149\140\233\157\162\229\183\178\231\187\143\229\142\187\228\184\150\228\186\134\239\188\140\228\184\141\229\186\148\232\175\165\230\138\128\232\131\189\229\129\156\230\173\162\229\164\177\232\180\165")
    return
  end
  if not self.StartSkillSuccessDone then
    self:SkillInterrupt(Event, Skill)
    Log.Error("\230\138\128\232\131\189\233\157\158\230\173\163\229\184\184\232\162\171\228\184\173\230\150\173\228\186\134")
    return
  end
  self:SetClickable()
  if self.panel_icon_panel_map then
    for _, Icon in pairs(self.panel_icon_panel_map) do
      Icon:ShowRedPoint()
    end
  else
    Log.Error("UMG_LobbyMainInner_C:CompassStarFinish No Icon in icon list")
  end
end

function UMG_LobbyMainInner_C:PlayCompassEndSkill(bForceEnd)
  Log.Debug("UMG_LobbyMainInner_C:PlayCompassEndSkill", bForceEnd)
  if not self.isNormal then
    self.UMG_LobbyMainInnerParticle:PlayCollapse()
    self:PlayHaloAnimation(self.Close_Luopan)
    self:DestroyActorAndCloseUI()
    return
  end
  local assetPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Compass/G6_Scene_Compass_End.G6_Scene_Compass_End"
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local caster = player.viewObj
  if caster then
    local skillComponent = caster.RocoSkill
    if skillComponent then
      local skillProxy = RocoSkillProxy.Create(assetPath, skillComponent, 99999)
      if caster.RocoSkill:GetActiveSkill() == skillProxy then
        return
      end
      self.EndSkill = skillProxy
      skillProxy:SetCaster(caster)
      local targets = {}
      table.insert(targets, self.Halo)
      skillProxy:SetTargets(targets)
      skillProxy:SetPassive(false)
      if bForceEnd then
        player:GetAnimComponent():StopAllMontage(0)
      else
        skillProxy:RegisterEventCallback("PlayEnd", self, self.PlayAnimEnd)
      end
      skillProxy:RegisterEventCallback("PreEnd", self, self.DestroyActorAndCloseUI)
      skillProxy:RegisterEventCallback("End", self, self.DestroyActorAndCloseUI)
      skillProxy:RegisterEventCallback("Interrupt", self, self.SkillInterrupt)
      skillProxy:PlaySkill()
    end
    caster.RocoSkill:StopCurrentSkill()
    if self.PostProcessSkill then
      self.PostProcessSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultSuccessful)
      self.PostProcessSkill = nil
    end
    self:HideIcons(false)
  end
  self.UMG_LobbyMainInnerParticle:PlayCollapse()
end

function UMG_LobbyMainInner_C:DestroyActorAndCloseUI()
  self:DestroyActor()
  self:RealCloseLobbyMainInner()
end

function UMG_LobbyMainInner_C:DestroyActor()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:SetCustomDepth(nil)
  end
  self:UnShowCompass(true)
end

function UMG_LobbyMainInner_C:TryPlayAnimWithStatus(Status, Anim, Param)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil == player then
    return false
  end
  if nil == Status then
    player:PlayAnim(Anim, table.unpack(Param))
    return true
  end
  if player.statusComponent:HasStatus(Status) then
    player:PlayAnim(Anim, table.unpack(Param))
    return true
  end
  return false
end

function UMG_LobbyMainInner_C:PlayAnimStart()
  self.PlayerStarted = true
  self:SwitchToMainCamera()
  local param = {
    1,
    0,
    0,
    0.2,
    1
  }
  local Type = ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainOpen", param) or Play(self, Type.WPST_SWIMMING, "SwimMainOpen", param) or Play(self, nil, "LobbyMainOpen", param)
end

function UMG_LobbyMainInner_C:PlayAnimIdle()
  self:SwitchToMainCamera()
  local param = {
    1,
    0,
    0.2,
    0.05,
    -1
  }
  local Type = ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  self.StartSkillSuccessDone = true
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainIdle", param) or Play(self, Type.WPST_SWIMMING, "SwimMainIdle", param) or Play(self, nil, "LobbyMainIdle", param)
end

function UMG_LobbyMainInner_C:PlayAnimEnd()
  self.PlayerStarted = false
  local param = {
    1,
    0,
    0.05,
    0.5,
    1,
    0,
    "Locomotion"
  }
  local Rideparam = {
    1,
    0,
    0.05,
    0.35,
    1
  }
  local Type = ProtoEnum.WorldPlayerStatusType
  local Play = self.TryPlayAnimWithStatus
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    player:StopAllMontage()
  end
  local _ = Play(self, Type.WPST_CLIMB, "ClimbMainEnd", param) or Play(self, Type.WPST_SWIMMING, "SwimMainEnd", param) or Play(self, nil, "LobbyMainEnd", param)
end

function UMG_LobbyMainInner_C:Tick(MyGeometry, InDeltaTime)
  if UE4.UObject.IsValid(self.Halo) then
    self.BattleIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone009", true, true))
    self.TaskIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone011", true, true))
    self.MapIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone013", true, true))
    self.HandbookIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone015", true, true))
    self.PetIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone017", true, true))
    self.BagIconLoader.Slot:SetPosition(self:GetLocatorLocation("Bone019", true, true))
    self.UMG_LobbyMainInnerParticleLoader.Slot:SetPosition(self:GetLocatorLocation("Root", true, true))
    self.ItemRedPoint.Slot:SetPosition(self:GetLocatorLocation("RedPoint", true, true))
    self.AwardBtn.Slot:SetPosition(self:GetLocatorLocation("Root", true, true))
    self.CollectParticle.Slot:SetPosition(self:GetLocatorLocation("Root", true, true))
    self.ParticleImage.Slot:SetPosition(self:GetLocatorLocation("Root", true, true))
  end
end

function UMG_LobbyMainInner_C:GetLocatorLocation(socketName, UseSafeZone, FixOffset)
  local HaloMesh = self.Halo:GetComponentByClass(UE4.USkeletalMeshComponent)
  if not HaloMesh then
    return
  end
  local playerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  local headLoation = HaloMesh:Abs_GetSocketLocation(socketName)
  local ScreenPos = UE4.FVector2D()
  local headPositon = headLoation
  local InScreen = UE4.UGameplayStatics.Abs_ProjectWorldToScreen(playerController, headPositon, ScreenPos)
  if InScreen then
    local wndSize = UE4.USlateBlueprintLibrary.GetLocalSize(self:GetCachedGeometry())
    local ViewportPos = UE4.FVector2D()
    UE4.USlateBlueprintLibrary.ScreenToViewport(_G.UE4Helper.GetCurrentWorld(), ScreenPos, ViewportPos)
    if not UseSafeZone then
      return ViewportPos
    end
    if FixOffset then
      ViewportPos.X = ViewportPos.X - wndSize.X / 2
      ViewportPos.Y = ViewportPos.Y - wndSize.Y / 2
    end
    if _G.GlobalConfig.bUseDpiScale then
      ViewportPos.X = ViewportPos.X * self.DpiScaleY
      ViewportPos.Y = ViewportPos.Y * self.DpiScaleY
    end
    return ViewportPos
  else
    local ViewportPos = UE4.FVector2D()
    ViewportPos.X = -1000
    ViewportPos.Y = -1000
    if not UseSafeZone then
      return ViewportPos
    end
    return ViewportPos
  end
end

function UMG_LobbyMainInner_C:GetLocatorScale(socketName)
  local HaloMesh = self.Halo:GetComponentByClass(UE4.USkeletalMeshComponent)
  if not HaloMesh then
    return
  end
  local ActorScale = self.Halo:GetActorScale3D()
  local Scale = HaloMesh:K2_GetComponentScale()
  local headTransform = HaloMesh:Abs_GetSocketTransform(socketName)
  local Size = UE4.FVector2D()
  Size.X = headTransform.Scale3D.X / Scale.X / ActorScale.X
  Size.Y = headTransform.Scale3D.Y / Scale.Y / ActorScale.Y
  return Size
end

function UMG_LobbyMainInner_C:RealCloseLobbyMainInner()
  Log.Debug("UMG_LobbyMainInner_C:RealCloseLobbyMainInner")
  if UE.UObject.IsValid(self) then
    self:DoClose()
  end
end

function UMG_LobbyMainInner_C:ResetPlayer()
  if not self.PlayerStarted then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return
  end
  local ctrl = player and player:GetUEController()
  if ctrl then
    ctrl:SetUICameraState(_G.MainUIModuleEnum.MainUICameraState.Normal)
  end
  if self.isNormal then
    local speed = _G.DataConfigManager:GetGlobalConfigByKeyType("camera_speed_retract_compass", _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG).str
    local playerCameraManager = player:GetUEController().PlayerCameraManager
    playerCameraManager:SwitchMainUiCamera(false, tonumber(speed))
  end
  self:DestroyActor()
  if self.isNormal then
    self:PlayAnimEnd()
  end
  if self.StartSkill then
    self.StartSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.StartSkill:Destroy()
    self.StartSkill = nil
  end
  if self.PostProcessSkill then
    self.PostProcessSkill:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.PostProcessSkill:Destroy()
    self.PostProcessSkill = nil
  end
end

function UMG_LobbyMainInner_C:DoCloseThings()
  self:ResetPlayer()
  Log.Debug("UMG_LobbyMainInner_C:DoCloseThings")
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnLobbyMainInnerClosed)
  if _G.BattleManager.isInBattle then
    _G.BattleManager.NeedOpenMain = true
  end
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveFromDisableLobbyMainPopUpList, "LobbyMainInner")
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnOpenPanelLobbyMain)
end

function UMG_LobbyMainInner_C:OnAnimationFinished(anim)
  if anim == self.Close then
    self:SetUnClickable()
  elseif anim == self.Close_2 then
    self:SetUnClickable()
  elseif anim == self.Open_2 then
    self:SetClickable()
  elseif anim == self.Open_Luopan and self.LuopanExpand then
    self:PlayHaloAnimation(self.Loop_Luopan, 0)
  end
  if anim == self.Open then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

function UMG_LobbyMainInner_C:SetClickable()
  Log.Trace("UMG_LobbyMainInner_C:SetClickable")
  if self and self.SetVisibility then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonClickable = true
  else
    Log.Warning("UMG_LobbyMainInner_C:SetClickable failed because invalid")
  end
end

function UMG_LobbyMainInner_C:SetUnClickable()
  Log.Trace("UMG_LobbyMainInner_C:SetUnClickable")
  if self and self.SetVisibility then
    self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.ButtonClickable = false
  else
    Log.Warning("UMG_LobbyMainInner_C:SetUnClickable failed because invalid")
  end
end

function UMG_LobbyMainInner_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_LobbyMainInner_C:BackBigWorld()
end

function UMG_LobbyMainInner_C:OnPCKeyCloseCompass(action_type)
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if 0 == action_type then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
    self:OnClickCloseBtn()
  end
end

function UMG_LobbyMainInner_C:IsWaitingForSubPanelPrepared()
  if self.SubPanelType ~= MainUIModuleEnum.SubPanelOpenType.NoneUI or self.SubPanelType == MainUIModuleEnum.SubPanelOpenType.PreDownload then
    self:HidePlayerAndUI()
  end
  self:CancelDelay()
  return self.IsWaitingForSubPanel > 0 and false
end

function UMG_LobbyMainInner_C:OnSubPanelPrepared()
  self.IsWaitingForSubPanel = self.IsWaitingForSubPanel - 1
  if self.IsWaitingForSubPanel <= 0 then
    Log.Debug("UMG_LobbyMainInner_C:OnSubPanelLoadDone After 1 frame")
    self:CancelDelay()
    if self.SubPanelType ~= MainUIModuleEnum.SubPanelOpenType.NoneUI then
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.DoBlackScreenTransitionOut)
    elseif self.FunctionUIType ~= _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_NoneType then
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.DoNormalBlackScreenTransitionOut)
    end
  end
end

function UMG_LobbyMainInner_C:TryDoBlackScreenTransition()
  self:PreLoadSubPanel()
  Log.Debug("UMG_LobbyMainInner_C:TryDoBlackScreenTransition")
end

function UMG_LobbyMainInner_C:OnSelectAnimDone()
  Log.Debug("UMG_LobbyMainInner_C:OnSelectAnimDone")
  self:OpenSubPanel()
end

function UMG_LobbyMainInner_C:PreLoadBlackScreen()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.PreLoadBlackScreen)
end

function UMG_LobbyMainInner_C:TryOpenBlackScreenTransition()
  Log.Debug("UMG_LobbyMainInner_C:TryOpenBlackScreenTransition")
  if self.Halo then
    local location = self:GetLocatorLocation(self.panel_bone_map[self.SubPanelType], true, true)
    _G.NRCModeManager:DoCmd(_G.MainUIModuleCmd.DoBlackScreenTransition, self.SubPanelType, location)
  else
    local location = self.panel_icon_panel_map[self.SubPanelType]:GetPosition()
    _G.NRCModeManager:DoCmd(_G.MainUIModuleCmd.DoBlackScreenTransition, self.SubPanelType, location)
  end
end

function UMG_LobbyMainInner_C:TryOpenNormalBlackScreenTransition()
  _G.NRCModeManager:DoCmd(_G.MainUIModuleCmd.DoNormalBlackScreenTransition)
end

function UMG_LobbyMainInner_C:GetSeasonIconAnNameBySeasonId(seasonId)
  local seasonConf = _G.DataConfigManager:GetSeasonConf(seasonId)
  if seasonConf then
    return seasonConf.lobby_icon, seasonConf.s_title
  end
end

function UMG_LobbyMainInner_C:InitLeftIcon()
  if not self.UIConfigTable then
    self.UIConfigTable = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.UI_LOBBY_MAIN_COMPASS):GetAllDatas()
  end
  local iconList = {}
  if self.UIConfigTable then
    for _, value in pairs(self.UIConfigTable) do
      if value then
        local isBan = false
        local isOpen = true
        local iconPath, iconName
        if value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FRIEND then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FRIEND, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MAIL then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAIL, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_MUSICCOLLECTION then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MUSIC, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_TEACHING then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_GUIDE, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SHOP then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHARGE, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_FASHIONMALL then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_FASHION_STORE, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_ACTIVITY then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_ACTIVITY, false)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_BATTLEPASS then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BP, false)
          isOpen = _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.IsActivitePass)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_SEASON then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, Enum.FunctionEntrance.FE_SEASON)
          local seasonInfo = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo)
          isOpen = seasonInfo and true or false
          iconPath, iconName = self:GetSeasonIconAnNameBySeasonId(isOpen and seasonInfo.season_id or 0)
        elseif value.icon_initialize == _G.ProtoEnum.LobbyMainInnerUIType.LMIUT_GOODS_SHOP then
          isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CHARGE_GOODS_SHOP, false)
        end
        if not isBan and isOpen and value.icon_order ~= nil and 0 ~= value.icon_order then
          local tmp = {}
          tmp.icon_order = value.icon_order
          tmp.icon_path = iconPath or value.icon_path
          tmp.icon_initialize = value.icon_initialize
          tmp.icon_name = iconName or value.icon_name
          table.insert(iconList, tmp)
        end
      end
    end
  end
  table.sort(iconList, function(a, b)
    return a.icon_order < b.icon_order
  end)
  self.LeftIcon.IconList:InitGridView(iconList)
  self.LeftPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_LobbyMainInner_C:InitBottomIcon()
  self.BottomPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_LobbyMainInner_C:InitWishCyrstalUI()
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data then
    local coin_num = data:GetMoneyCount() or 0
    local moneyInfo = {
      {
        moneyType = _G.Enum.VisualItem.VI_DIAMOND,
        sum = coin_num,
        IsShowBuyIcon = false
      }
    }
    self.MoneyBtn:InitGridView(moneyInfo)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TopPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyMainInner_C:ShowWishCrystalRedPoint(immediate)
  self.ItemRedPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AwardBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.NumText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.RedPointImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.RedPointNode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.NumText:SetText("")
  if not _G.DataModelMgr.PlayerDataModel:HasStoryFlag(_G.Enum.PlayerStoryFlagEnum.PSF_FUNC_EXCHANGE_WISH_STAR) then
    return
  end
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data and data.PlayerStarInfo then
    local count = data.PlayerStarInfo.unexchange_wishing_star_num or 0
    if count > 0 and count <= 99 then
      self.ItemRedPoint.NumText:SetText(tostring(count))
    elseif count > 99 then
      self.ItemRedPoint.NumText:SetText("99+")
    end
    if count > 0 then
      self.ItemRedPoint.NumText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ItemRedPoint.RedPointImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.ItemRedPoint.RedPointNode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.AwardBtn:SetVisibility(UE4.ESlateVisibility.Visible)
      if self.Halo then
        self.Halo:GetWishLoop(true)
      end
      if self.WishLoopAudioID then
        _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:ShowWishCrystalRedPoint", false, 0.2)
        self.WishLoopAudioID = nil
      end
      self.WishLoopAudioID = _G.NRCAudioManager:PlaySound2DAuto(41500308, "UMG_LobbyMainInner_C:ShowWishCrystalRedPoint")
      if immediate then
        self.ItemRedPoint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self:DelaySeconds(0.42, function()
          self.ItemRedPoint:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end)
      end
    end
  end
end

function UMG_LobbyMainInner_C:OnClickedAwardBtn()
  if self.bTest then
    self:UpdateWishCrystalInfo()
    return
  end
  if self.ButtonClickable and not self.bLockAwardBtn then
    _G.NRCAudioManager:PlaySound2DAuto(41500309, "UMG_LobbyMainInner_C:OnClickedAwardBtn")
    _G.NRCEventCenter:DispatchEvent(WishCrystalModuleEvent.WISH_CRYSTAL_SEND_WISHSTAR_EXCHANGE_REQ)
    self.bLockAwardBtn = true
    if self.AwardBtnDelayHandle then
      _G.DelayManager:CancelDelayById(self.AwardBtnDelayHandle)
      self.AwardBtnDelayHandle = nil
    end
    self.AwardBtnDelayHandle = _G.DelayManager:DelaySeconds(5, function()
      self.bLockAwardBtn = false
    end, self)
  end
end

function UMG_LobbyMainInner_C:UpdateWishCrystalInfo(InStarlightInfo)
  if not InStarlightInfo then
    local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
    if data then
      if self.bTest or data.ExchangeNum and data.ExchangeNum > 0 then
        if data.ExchangeNum then
          self.AdditionText_95:SetText(string.format("+%d", data.ExchangeNum))
        end
        if self.Halo then
          self.Halo:CollectWishCrystal(true)
          self.Halo:GetWishLoop(false)
        end
        if self.WishLoopAudioID then
          _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:UpdateWishCrystalInfo", false, 0.2)
          self.WishLoopAudioID = nil
        end
        _G.NRCAudioManager:PlaySound2DAuto(41500306, "UMG_LobbyMainInner_C:UpdateWishCrystalInfo")
        self:PlayCollectWishCrystalSkill()
        self:PlayCollectAnim()
        self.CollectID = self:DelaySeconds(1, self.FinishCollectAnim, self)
      else
        self:OnCollectWishCrystalFinished()
        if self.Halo then
          self.Halo:GetWishLoop(false)
          self.Halo:CollectWishCrystal(false)
        end
        if self.WishLoopAudioID then
          _G.NRCAudioManager:ReleaseSession(self.WishLoopAudioID, true, "UMG_LobbyMainInner_C:UpdateWishCrystalInfo", false, 0.2)
          self.WishLoopAudioID = nil
        end
      end
    end
  else
    self:ShowWishCrystalRedPoint(true)
  end
end

function UMG_LobbyMainInner_C:PlayCollectAnim()
  if self.CollectParticle.WorldParticleComponent then
    local y = 730
    local z = 430
    local MoneyBtnPos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.MoneyBtn:GetCachedGeometry(), UE4.FVector2D(0, 0))
    local CollectParticlePos = UE4.USlateBlueprintLibrary.LocalToAbsolute(self.ParticleImage:GetCachedGeometry(), UE4.FVector2D(0, 0))
    if MoneyBtnPos and CollectParticlePos then
      local Scale = UE4.UWidgetLayoutLibrary.GetViewportScale(UE4Helper.GetCurrentWorld())
      if Scale and Scale > 0 then
        MoneyBtnPos = MoneyBtnPos / Scale
        CollectParticlePos = CollectParticlePos / Scale
        y = MoneyBtnPos.X - CollectParticlePos.X
        z = CollectParticlePos.Y - MoneyBtnPos.Y
      end
    end
    self.CollectParticle.WorldParticleComponent:SetFloatParameter("Axis_Y", y)
    self.CollectParticle.WorldParticleComponent:SetFloatParameter("Axis_Z", z)
    self.CollectParticle:HideParticleWidget(false)
    self.CollectParticle.WorldParticleComponent:SetActive(true, true)
  end
end

function UMG_LobbyMainInner_C:FinishCollectAnim()
  self.CollectID = nil
  for i = 1, self.MoneyBtn:GetItemCount() do
    if self.MoneyBtn:GetItemByIndex(i - 1) and self.MoneyBtn:GetItemByIndex(i - 1).moneyType == _G.Enum.VisualItem.VI_DIAMOND then
      local MoneyNum = self:GetMoneyCount()
      self.MoneyBtn:GetItemByIndex(i - 1):PlayCollectAnim(MoneyNum)
    end
  end
  self:OnCollectWishCrystalFinished()
  if self.Halo then
    self.Halo:CollectWishCrystal(false)
  end
end

function UMG_LobbyMainInner_C:OnCollectWishCrystalFinished()
  self.ItemRedPoint.NumText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.RedPointImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint.RedPointNode:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemRedPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.AwardBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CollectParticle:SetActivate(false)
  self.CollectParticle:HideParticleWidget(true)
end

function UMG_LobbyMainInner_C:GetMoneyCount()
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data then
    local coin_num = data:GetMoneyCount() or 0
    return coin_num
  end
  return 0
end

function UMG_LobbyMainInner_C:RefreshMoneyList()
  local data = _G.NRCModuleManager:GetModule("WishCrystalModule").data
  if data then
    local coin_num = data:GetMoneyCount() or 0
    local moneyCountList = {coin_num}
    for i = 1, self.MoneyBtn:GetItemCount() do
      if self.MoneyBtn:GetItemByIndex(i - 1) and self.MoneyBtn:GetItemByIndex(i - 1).moneyType == _G.Enum.VisualItem.VI_DIAMOND then
        self.MoneyBtn:GetItemByIndex(i - 1).SumNum:SetText(moneyCountList[i])
      end
    end
  end
end

function UMG_LobbyMainInner_C:CancelCollect()
  if self.CollectID then
    self:CancelDelayByID(self.CollectID)
    self.CollectID = nil
  end
  for i = 1, self.MoneyBtn:GetItemCount() do
    if self.MoneyBtn:GetItemByIndex(i - 1) and self.MoneyBtn:GetItemByIndex(i - 1).moneyType == _G.Enum.VisualItem.VI_DIAMOND then
      self.MoneyBtn:GetItemByIndex(i - 1):StopAllAnimations()
    end
  end
  self:RefreshMoneyList()
end

function UMG_LobbyMainInner_C:PlayCollectWishCrystalSkill()
  if self.Halo then
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player and player.viewObj then
      local caster = player.viewObj
      local skillComponent = caster.RocoSkill
      if skillComponent then
        local skillProxy = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Compass/G6_Compass_GetWish.G6_Compass_GetWish", skillComponent)
        if skillProxy then
          skillProxy:SetCaster(self.Halo)
          skillProxy:SetPassive(true)
          skillProxy:PlaySkill()
        end
      end
    end
  end
end

function UMG_LobbyMainInner_C:TestWishCrystalParticle()
  self.bTest = true
  self.AwardBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.Halo then
    self.Halo:GetWishLoop(true)
  end
end

return UMG_LobbyMainInner_C
