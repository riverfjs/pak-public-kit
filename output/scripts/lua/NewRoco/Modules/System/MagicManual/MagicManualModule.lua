local ProtoCMD = require("Data.PB.ProtoCMD")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NRCPanelDynamicData = require("Core.NRCPanel.NRCPanelDynamicData")
local WORLD_COMBAT_CONF = _G.DataConfigManager:GetAllByName("WORLD_COMBAT_CONF")
local RedPointModuleEvent = require("NewRoco.Modules.System.RedPoint.RedPointModuleEvent")
local JsonUtils = require("Common.JsonUtils")
local MagicManualModule = NRCModuleBase:Extend("MagicManualModule")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")

function MagicManualModule:OnConstruct()
  _G.MagicManualModuleCmd = reload("NewRoco.Modules.System.MagicManual.MagicManualModuleCmd")
  self.data = self:SetData("MagicManualModuleData", "NewRoco.Modules.System.MagicManual.MagicManualModuleData")
  self:RegPanel("MagicManualMainPanel", "UMG_MagicManual_Main", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Out")
  self:RegPanel("MagicManualItemRewards", "UMG_MagicMaunal_Section", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("MagicManualDescTips", "UMG_MagicManualDescTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("PlayDetails", "UMG_PlayDetails", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("SeasonBadge", "UMG_SeasonBadgeTips", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("ChapterBegin", "UMG_ChapterBegins", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("SeasonChapterBegin", "UMG_SeasonAssignment_WidgetLoader", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("TeachingPopUp", "UMG_TeachingPopUp", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self:RegPanel("RecallPanel", "UMG_MagicManual_Recalling", _G.Enum.UILayerType.UI_LAYER_POPUP)
  self.DeltaTime = 0
  self.DeltaTime1 = 0
  self.TableIndex = -1
  self.SubTableIndex = -1
  self.ChildTableIndex = 0
  self.bIsOpenByManual = false
  self.TaskOpenCmd = false
  self.EnableShowDesc = true
  self.ManaulChildIndex = self.data.ManualTaskType.NormalManual
  self.SeasonChapterBeginUIData = "SeasonChapterBeginUIData"
end

function MagicManualModule:OnOpenMainPanel(arg)
end

function MagicManualModule:OnCmdCloseMagicManual(NeedCloseCompass)
  if self:HasPanel("MagicManualMainPanel") then
    local panel = self:GetPanel("MagicManualMainPanel")
    panel:CloseMagicManual()
    self.NeedCloseCompass = NeedCloseCompass
  end
end

function MagicManualModule:CmdOpenMagicManualTeachingTips(conf)
  self:OpenPanel("TeachingPopUp", conf)
end

function MagicManualModule:CmdShowMagicManualDescTips(DescId)
  if self:HasPanel("MagicManualMainPanel") then
    local Panel = self:GetPanel("MagicManualMainPanel")
    Panel.MagicManual:SetMagicManualDescBG(DescId)
  end
end

function MagicManualModule:OnActive()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SPEC_FLOWER_SEED_INFO_NTY, self.OnZoneSceneSpecFlowerSeedInfoNty)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SEASON_ADV_BADGE_EFFECT_NOTIFY, self.OnZoneSeasonManualProbAddNotify)
  if not _G.ZoneServer:IsUpstreamLocked() then
    self:ZoneSceneQueryAllFlowerSeedReq()
  end
  if _G.DataModelMgr.PlayerDataModel then
    local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_TYPE_BATTLE_TRAIN)
    if Flags then
      self:ZoneMagicGetTeachingTabReq()
    end
  end
  NRCEventCenter:RegisterEvent("MagicManualModule", self, SceneEvent.OnEnterSceneFinishNtyAck, self.OnEnterSceneFinish)
  _G.NRCEventCenter:RegisterEvent("MagicManualModule", self, SceneEvent.LoadMapStart, self.OnLoadMapStart)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  NRCEventCenter:RegisterEvent("UMG_MagicManual_C", self, _G.TaskModuleEvent.TaskChangeNotify, self.TaskChangeNotify)
  self:SendZoneOpenMagicBookSheetReq()
  self:OnReqSeasonManualData()
end

function MagicManualModule:OnGetSeasonManualProbAdd()
  return self.data:GetSeasonProbAdd()
end

function MagicManualModule:OnZoneSeasonManualProbAddNotify(ntf)
  Log.Dump(ntf, 5, "MagicManualModule:OnZoneSeasonManualProbAddNotify")
  self.data:OnUpdateSeasonManualProbAddition(ntf)
end

function MagicManualModule:OnEnterSceneFinish(notify, isReconnecting, isEnteringCell)
  if isEnteringCell or isReconnecting then
    self:ZoneSceneQueryAllFlowerSeedReq()
  end
end

function MagicManualModule:CmdSetMagicManualCanNotClick()
  if self:HasPanel("MagicManualMainPanel") then
    local panel = self:GetPanel("MagicManualMainPanel")
    panel:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    if self.DelayID then
      _G.DelayManager:CancelDelayById(self.DelayID)
      self.DelayID = _G.DelayManager:DelaySeconds(2, function()
        if UE.UObject.IsValid(panel) and (panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed or panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden) then
          Log.Debug("ShowMagicManualMainPanel_By_SetMagicManualCanNotClickFun_DelayShow")
          panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        self.DelayID = nil
      end)
    else
      self.DelayID = _G.DelayManager:DelaySeconds(2, function()
        if UE4.UObject.IsValid(panel) and (panel:GetVisibility() ~= UE4.ESlateVisibility.Collapsed or panel:GetVisibility() ~= UE4.ESlateVisibility.Hidden) then
          Log.Debug("ShowMagicManualMainPanel_By_SetMagicManualCanNotClickFun_DelayShow")
          panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.DelayID = nil
        end
      end)
    end
  end
end

function MagicManualModule:SendZoneOpenMagicBookSheetReq()
  self.OnlyGetMagicBookSheetData = true
  self:OnCmdOpenMagicBookSheet()
end

function MagicManualModule:OnRelogin()
end

function MagicManualModule:OnDeactive()
  NRCEventCenter:UnRegisterEvent(self, RedPointModuleEvent.RedPointChange, self.OnUpdateRedPointData)
  NRCEventCenter:UnRegisterEvent(self, _G.TaskModuleEvent.TaskChangeNotify, self.TaskChangeNotify)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.OnLoadMapStart)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_PLAYER_SEASON_ADV_BADGE_EFFECT_NOTIFY, self.OnZoneSeasonManualProbAddNotify)
  if self.closePanelTimerID then
    _G.DelayManager:CancelDelay(self.closePanelTimerID)
    self.closePanelTimerID = nil
  end
end

function MagicManualModule:OnUpdateRedPointData(notify)
  if notify.rp_group then
    for _, group in pairs(notify.rp_group) do
      if group.reason_type == _G.Enum.RedPointReason.RPR_ADVENTURE_TASK and group.point_data and #group.point_data > 0 then
        for _, point in pairs(group.point_data) do
          local taskid = tonumber(point)
          if self.data.AllTaskRegionList then
            if self:HasPanel("MagicManualMainPanel") then
              for i, v in pairs(self.data.AllTaskRegionList) do
                local TaskRegionList = v.ChapterList
                for RegionI, k in pairs(TaskRegionList) do
                  local taskList = k.taskList
                  for taskI, task in ipairs(taskList) do
                    if task.id == taskid then
                      self.data.AllTaskRegionList[i].ChapterList[RegionI].taskList[taskI].state = ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
                    end
                  end
                end
              end
              if self.data.TaskRegionList then
                for i, v in pairs(self.data.TaskRegionList) do
                  local taskList = v.taskList
                  for taskI, task in ipairs(taskList) do
                    if task.id == taskid then
                      self.data.TaskRegionList[i].taskList[taskI].state = ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
                    end
                  end
                end
              end
            end
            for i, v in pairs(self.data.AllTaskRegionList) do
              local TaskRegionList = v.ChapterList
              for _, k in pairs(TaskRegionList) do
                if k.HideCoreTask and #k.HideCoreTask > 0 then
                  for _, HideTaskId in ipairs(k.HideCoreTask) do
                    if HideTaskId == taskid then
                      self:SendZoneOpenMagicBookSheetReq()
                      return
                    end
                  end
                end
                if k.HideElectiveTask and #k.HideElectiveTask > 0 then
                  for _, HideTaskId in ipairs(k.HideElectiveTask) do
                    if HideTaskId == taskid then
                      self:SendZoneOpenMagicBookSheetReq()
                      return
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

function MagicManualModule:OnDestruct()
  if self.delayTutorJumpId then
    _G.DelayManager:CancelDelayById(self.delayTutorJumpId)
  end
end

function MagicManualModule:OnCmdOpenMagicManualToFlowerPanel(tips)
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id
  local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
  if not select_pet_conf_id or hideMagicManua then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip4)
    return
  end
  self.TaskOpenCmd = true
  self:OnOpenMagicManualByIndex("MMT_FLOWER_PANEL")
end

function MagicManualModule:OnCmdOpenMagicManualToBossPanel(tips)
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id
  local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
  if not select_pet_conf_id or hideMagicManua then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip4)
    return
  end
  self.TaskOpenCmd = true
  self:OnOpenMagicManualByIndex("MMT_PET_BOSS")
end

function MagicManualModule:OnCmdOpenMagicManualToShenShouPanel()
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id
  local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
  if not select_pet_conf_id or hideMagicManua then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip4)
    return
  end
  self.TaskOpenCmd = true
  self:OnOpenMagicManualByIndex("MMT_LEGENDARY")
end

function MagicManualModule:OnCmdOpenMagicManualToPVPPanel(tips)
  self.TaskOpenCmd = true
  self:OnOpenMagicManualByIndex("MMT_PVP")
end

function MagicManualModule:OnCmdOpenMagicManualToSTARWARPanel(tips)
  self.TaskOpenCmd = true
  self:OnOpenMagicManualByIndex("MMT_STAR_WAR")
end

function MagicManualModule:OnCmdOpenMagicManualToDailyTaskPanel()
  if _G.DataModelMgr.PlayerDataModel:IsTraceVisitNotOwnerBan() then
    return
  end
end

function MagicManualModule:GetTabIndexByTabType(_tabType)
  local index = 0
  local ChildTableIndex = 0
  self.ManaulChildIndex = self.data.ManualTaskType.NormalManual
  local tabType = _G.Enum.MagicManualTab[_tabType]
  if tabType == Enum.MagicManualTab.MMT_MAGIC_ASSIGNMENT then
    index = self.data.TaskSortType.Task_Adventure
    self.ManaulChildIndex = self.data.ManualTaskType.NormalManual
  end
  if tabType == Enum.MagicManualTab.MMT_MAGIC_SEASON then
    index = self.data.TaskSortType.Task_Adventure
    self.ManaulChildIndex = self.data.ManualTaskType.SeasonManual
  end
  if tabType == Enum.MagicManualTab.MMT_FLOWER_PANEL then
    index = self.data.TaskSortType.Task_Challenge
    ChildTableIndex = self.data.ChallengeTaskType.XiShou
  end
  if tabType == Enum.MagicManualTab.MMT_PET_BOSS then
    index = self.data.TaskSortType.Task_Challenge
    ChildTableIndex = self.data.ChallengeTaskType.Boss
  end
  if tabType == Enum.MagicManualTab.MMT_LEGENDARY then
    index = self.data.TaskSortType.Task_Challenge
    ChildTableIndex = self.data.ChallengeTaskType.Legend
  end
  if tabType == Enum.MagicManualTab.MMT_PVP then
    index = self.data.TaskSortType.PVP_Challenge
  end
  if tabType == Enum.MagicManualTab.MMT_STAR_WAR then
    index = self.data.TaskSortType.PVE_Challenge
    ChildTableIndex = self.data.BattlePlayTaskType.StarlightDuel
  end
  if tabType == Enum.MagicManualTab.MMT_BATTLE_THEATER then
    index = self.data.TaskSortType.PVE_Challenge
    ChildTableIndex = self.data.BattlePlayTaskType.BattleSilhouette
  end
  if tabType == Enum.MagicManualTab.MMT_CHAMPION_DUEL then
    index = self.data.TaskSortType.PVE_Challenge
    ChildTableIndex = self.data.BattlePlayTaskType.Chieftain
  end
  if tabType == Enum.MagicManualTab.MMT_TYPE_DAVANTAGE_TEACH then
    index = self.data.TaskSortType.Teach
    ChildTableIndex = self.data.TeachType.Restraint
  end
  if tabType == Enum.MagicManualTab.MMT_COMBAT_MECHANISM_TEACH then
    index = self.data.TaskSortType.Teach
    ChildTableIndex = self.data.TeachType.Battle
  end
  return index, ChildTableIndex
end

function MagicManualModule:OnOpenMagicManualByIndex(tabType)
  local hideMagicManua = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK)
  if hideMagicManua then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.item_source_worng_tip4)
    return
  end
  local index, ChildTableIndex = self:GetTabIndexByTabType(tabType)
  if index and index > 0 then
    if index == self.data.TaskSortType.PVE_Challenge then
      local NPCChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT)
      local IsUnLock = false
      local IsNPCUnLock = false
      local IsBOSSUnLock = false
      local IsWeeklyUnLock = false
      if NPCChallengeEventActivityObject and NPCChallengeEventActivityObject[1] then
        local npc_challenge_data = NPCChallengeEventActivityObject[1]:GetNpcChallengeData()
        if npc_challenge_data then
          IsUnLock = true
          IsNPCUnLock = true
        end
      end
      local BossChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT)
      if BossChallengeEventActivityObject and BossChallengeEventActivityObject[1] then
        local boss_challenge_data = BossChallengeEventActivityObject[1]:GetBossChallengeData()
        if boss_challenge_data then
          IsUnLock = true
          IsBOSSUnLock = true
        end
      end
      local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
      if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
        local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
        if weekly_challenge_data then
          IsUnLock = true
          IsWeeklyUnLock = true
        end
      end
      if not IsUnLock then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
      if 0 == ChildTableIndex and IsNPCUnLock then
      elseif 1 == ChildTableIndex and IsBOSSUnLock then
      elseif 3 == ChildTableIndex and IsWeeklyUnLock then
      elseif not ChildTableIndex then
      else
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
    elseif index == self.data.TaskSortType.PVP_Challenge then
      local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_PVP)
      if not Flags then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
    elseif index == self.data.TaskSortType.Task_Challenge then
      local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_CHALLENGE)
      if not Flags then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
    elseif index == self.data.TaskSortType.Task_Adventure and self.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
      local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_SADV)
      if not Flags then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.magic_manual_season_locked_tips)
        return
      end
    elseif index == self.data.TaskSortType.Teach then
      local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_TYPE_BATTLE_TRAIN)
      if not Flags then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
    end
    self.TableIndex = index
    self.ChildTableIndex = ChildTableIndex
  end
  if self:HasPanel("MagicManualMainPanel") then
    if index == self.data.TaskSortType.Task_Challenge then
      local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_CHALLENGE)
      if not Flags then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.task_track_error1)
        return
      end
    end
    local Panel = self:GetPanel("MagicManualMainPanel")
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Tips_CloseItemTips)
    _G.NRCModuleManager:DoCmd(CommonPopUpModuleCmd.CloseNPCShopItemRewardsPanel)
    if Panel:IsVisible() then
      self.SubTableIndex = -1
      self.ChildTableIndex = ChildTableIndex
      Panel:SelectTabByTabIndex(index)
      if self:HasPanel("MagicManualItemRewards") then
        self:ClosePanel("MagicManualItemRewards")
        self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualNextChapterPanel)
        self.data:SetNextChapterInfo()
      end
      self:OpenPanel("MagicManualMainPanel", _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
      return
    end
  end
  self:ZoneSceneQueryAllFlowerSeedReq()
  self:ZoneMagicGetTeachingTabReq()
  if self.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    self:OnCmdOpenMagicBookSheet()
    self:OnCmdOpenSeasonManual()
  else
    self:OnReqSeasonManualData()
    self:OnCmdOpenMagicBookSheet()
  end
end

function MagicManualModule:OnOpenMagicManual(isFromMainMap)
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
  if self.SubTableIndex > -1 and not self.TaskOpenCmd then
    self.IsMapToMagicManual = true
  end
  self.isFromMainMap = isFromMainMap
  if isFromMainMap then
    self.bIsOpenByManual = false
  end
  self.TableIndex = self.data.TaskSortType.Task_Adventure
  self.ChildTableIndex = 0
  self.ManaulChildIndex = self.data.ManualTaskType.NormalManual
  if not select_pet_conf_id then
    Log.Error("\230\178\161\230\156\137select_pet_conf_id\230\149\176\230\141\174")
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
    return
  end
  self:ZoneSceneQueryAllFlowerSeedReq()
  self:OnReqSeasonManualData()
  self:ZoneMagicGetTeachingTabReq()
  self:OnCmdOpenMagicBookSheet()
end

function MagicManualModule:EnableMagicManual()
  if self:HasPanel("MagicManualMainPanel") then
    local Panel = self:GetPanel("MagicManualMainPanel")
    Panel:EnableAndShouldBanWorldRendering()
  end
end

function MagicManualModule:PreLoadMagicManual()
  self:PreLoadPanel("MagicManualMainPanel", 10)
end

function MagicManualModule:OnCmdOpenMagicBookSheet()
  self:MarkPanelWaitingOpen("MagicManualMainPanel")
  local req = _G.ProtoMessage:newZoneOpenMagicBookSheetReq()
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_OPEN_MAGIC_BOOK_SHEET_REQ, req, self, self.HandleOpenMagicBookSheetRsp)
end

function MagicManualModule:HandleOpenMagicBookSheetRsp(Rsp)
  if 0 ~= Rsp.ret_info.ret_code or Rsp.chapter_id <= 0 then
    Log.Error("ZoneOpenMagicBookSheetRsp\229\155\158\229\140\133\230\149\176\230\141\174\230\156\137\233\151\174\233\162\152, ret_code: " .. Rsp.ret_info.ret_code .. ", chapter_id: " .. Rsp.chapter_id .. "")
    self:MarkPanelWaitingOpen("MagicManualMainPanel", true)
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
    self.OnlyGetMagicBookSheetData = false
    return
  end
  local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
  local regionId = {1}
  if 2000670 == select_pet_conf_id then
    regionId = {1}
  elseif 2000671 == select_pet_conf_id then
    regionId = {2}
  elseif 2000672 == select_pet_conf_id then
    regionId = {3}
  end
  local Region_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id or regionId
  self.data:SetInitPetConfInfo(Region_id, Rsp.chapter_id, Rsp.rewarded)
  local TaskRegionIdList = self.data:GetMagicManualTaskRegionIdList()
  if not Rsp.chapter_task_list then
    Log.Error("not Rsp.chapter_task_list")
    self:MarkPanelWaitingOpen("MagicManualMainPanel", true)
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
    self.OnlyGetMagicBookSheetData = false
    return
  end
  self.data:SetAllTaskRegionInfo(Rsp.chapter_task_list)
  local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
  local HasPanel = self:HasPanel("MagicManualMainPanel")
  if HasPanel then
    local Panel = self:GetPanel("MagicManualMainPanel")
    if Panel:IsVisible() then
      self:UnlockIsSelectBtn()
      self:TryCloseWorldMap()
      self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualChapterInfo, TaskPanelInfo)
      self:OpenPanel("MagicManualMainPanel", _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
    else
      self.data.DailyRemainTime = Rsp.remain_time
      self.data.DailySpecialRewardItem = Rsp.special_reward_item
      if Rsp.clue_task_list then
        self.data:SetCluemTaskDic(Rsp.clue_task_list)
      end
      if Rsp.invest_task_list then
        self.data:SetPermanentTaskDic(Rsp.invest_task_list)
      end
      if Rsp.topic_task_list then
        self.data:SetDailyTaskDic(Rsp.topic_task_list)
      end
      local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
      if not self.OnlyGetMagicBookSheetData then
        local panelDynamicData = NRCPanelDynamicData()
        panelDynamicData:SetCloseCallback(self, self.MagicManualMainPanelCloseCallBack)
        self:OpenPanel("MagicManualMainPanel", TaskPanelInfo, panelDynamicData)
      else
        self:MarkPanelWaitingOpen("MagicManualMainPanel", true)
      end
    end
  else
    self.data.DailyRemainTime = Rsp.remain_time
    self.data.DailySpecialRewardItem = Rsp.special_reward_item
    if Rsp.clue_task_list then
      self.data:SetCluemTaskDic(Rsp.clue_task_list)
    end
    if Rsp.invest_task_list then
      self.data:SetPermanentTaskDic(Rsp.invest_task_list)
    end
    if Rsp.topic_task_list then
      self.data:SetDailyTaskDic(Rsp.topic_task_list)
    end
    local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
    if not self.OnlyGetMagicBookSheetData then
      local panelDynamicData = NRCPanelDynamicData()
      panelDynamicData:SetCloseCallback(self, self.MagicManualMainPanelCloseCallBack)
      self:OpenPanel("MagicManualMainPanel", TaskPanelInfo, panelDynamicData)
    else
      self:MarkPanelWaitingOpen("MagicManualMainPanel", true)
    end
  end
  self.OnlyGetMagicBookSheetData = false
end

function MagicManualModule:MagicManualMainPanelCloseCallBack()
  self:LeaveChallengeStopTick()
  self:LeaveChallengeBossStopTick()
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnMainUISubPanelClosed, false)
  if self.NeedCloseCompass then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
  end
  self.NeedCloseCompass = false
end

function MagicManualModule:OnCmdChapterTaskSheetState(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    local select_pet_conf_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.select_pet_conf_id
    local regionId = {1}
    if 2000670 == select_pet_conf_id then
      regionId = {1}
    elseif 2000671 == select_pet_conf_id then
      regionId = {2}
    elseif 2000672 == select_pet_conf_id then
      regionId = {3}
    end
    local Region_id = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().common_info.pet_select_region_id or regionId
    self.data:SetInitPetConfInfo(Region_id, Rsp.chapter_id, Rsp.rewarded)
    local TaskRegionIdList = self.data:GetMagicManualTaskRegionIdList()
    self:OnCmdMagicManualTaskQueryReq(TaskRegionIdList)
  else
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
  end
end

function MagicManualModule:OnCmdMagicManualTaskQueryReq(TaskRegionIdList)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = TaskRegionIdList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetSelectTaskTypeInfo)
end

function MagicManualModule:GetSelectTaskTypeInfo(Rsp)
  if not Rsp.task_info_list then
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
    return
  end
  self.data:SetAllTaskRegionInfo(Rsp.task_info_list)
  local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
  local HasPanel = self:HasPanel("MagicManualMainPanel")
  if HasPanel then
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
    self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualChapterInfo, TaskPanelInfo)
  else
    self:ZoneQueryInvestTaskReqByOpenPanel()
  end
end

function MagicManualModule:ZoneQueryInvestTaskReqByOpenPanel()
  local req = _G.ProtoMessage:newZoneQueryInvestTaskReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_INVEST_TASK_REQ, req, self, self.OnZoneQueryInvestTaskRspByOpenPanel)
end

function MagicManualModule:OnZoneQueryInvestTaskRspByOpenPanel(rsp)
  if rsp.ret_info.ret_code then
    self.data.DailyRemainTime = rsp.remain_time
    self.data.DailySpecialRewardItem = rsp.special_reward_item
    if rsp.clue_task_list then
      self.data:SetCluemTaskDic(rsp.clue_task_list)
    end
    if rsp.invest_task_list then
      self.data:SetPermanentTaskDic(rsp.invest_task_list)
    end
    if rsp.topic_task_list then
      self.data:SetDailyTaskDic(rsp.topic_task_list)
    end
    local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
    local panelDynamicData = NRCPanelDynamicData()
    panelDynamicData:SetCloseCallback(self, self.MagicManualMainPanelCloseCallBack)
    if self:HasPanel("MagicManualMainPanel") then
      self:OpenPanel("MagicManualMainPanel", _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
    else
      self:OpenPanel("MagicManualMainPanel", TaskPanelInfo, panelDynamicData)
    end
  else
    self:UnlockIsSelectBtn()
    self:TryCloseWorldMap()
  end
end

function MagicManualModule:OnCmdEnableShowDescTips(Enable)
end

function MagicManualModule:SetSelectMagicManualChapter(ChapterId)
  if self.data.CurChapterId == ChapterId then
    return
  end
  self.data:SetMagicManualTaskChapterId(ChapterId)
  local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
  self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualChapterInfo, TaskPanelInfo)
end

function MagicManualModule:CheckAndSetSelectRewardChapter()
  if self.data.TaskRegionList then
    local selectChapter
    for i, v in ipairs(self.data.TaskRegionList) do
      local hasRewardRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 165, {
        v.ChapterId
      })
      if hasRewardRedPoint then
        selectChapter = v.ChapterId
        break
      end
    end
    if selectChapter and selectChapter ~= self.data.CurChapterId then
      self.data:SetMagicManualTaskChapterId(selectChapter)
    end
  end
end

function MagicManualModule:CmdSetSelectMagicManualRegion(RegionId)
  if self.data.CurRegionId == RegionId then
    return
  end
  self.data:SetMagicManualTaskRegionId(RegionId)
  local TaskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
  self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualChapterInfo, TaskPanelInfo)
end

function MagicManualModule:ShowMainPanel()
  if self.IsMapToMagicManual then
    self.IsMapToMagicManual = false
    local panel = self:GetPanel("MagicManualMainPanel")
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CloseWorldMap)
    panel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function MagicManualModule:CloseWorldMapWithSource()
  if self.isFromMainMap then
    self.isFromMainMap = false
  end
end

function MagicManualModule:TryCloseWorldMap()
  if self.IsMapToMagicManual then
    self.IsMapToMagicManual = false
    self.SubTableIndex = -1
    self.TableIndex = -1
  end
end

function MagicManualModule:OnLoadMapStart()
  self:ClosePanel("MagicManualMainPanel")
end

function MagicManualModule:CloseMagicManualClearIndex(NotClear)
  if self:HasPanel("MagicManualMainPanel") then
    self.NeedCloseCompass = true
    self:ClosePanel("MagicManualMainPanel")
  end
  if not NotClear then
    self.TableIndex = -1
    self.SubTableIndex = -1
  end
end

function MagicManualModule:OnGetCurChapterTasks(paragraph_id)
  return self.data:GetChapterTasks(paragraph_id)
end

function MagicManualModule:ZoneTaskRewardReq(task_id_list)
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = task_id_list
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.ZoneTaskRewardRsp, false, true)
end

function MagicManualModule:ZoneTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local CurRewardConf = rsp.ret_info.goods_reward
    if #CurRewardConf.rewards > 0 then
      local newRewards = self:MergeRewards(CurRewardConf.rewards)
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
      if self.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
        self:DispatchEvent(MagicManualModuleEvent.UpdateMagicManualPanel)
      elseif rsp.rewarded_task_list and #rsp.rewarded_task_list > 0 then
        self:OnReqTaskData(rsp.rewarded_task_list[1].id)
      end
    end
  else
    local key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText[key])
  end
end

function MagicManualModule:ZoneChapterRewardReq(chapter_id)
  local req = _G.ProtoMessage:newZoneRewardAdventureChapterReq()
  req.chapter_id = chapter_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_REWARD_ADVENTURE_CHAPTER_REQ, req, self, self.ZoneChapterRewardRsp, true)
end

function MagicManualModule:ZoneChapterRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code and #rsp.ret_info.goods_reward.rewards > 0 then
    local newRewards = self:MergeRewards(rsp.ret_info.goods_reward.rewards)
    local CurChapterName = self.data:GetCurChapterName()
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManualItemRewardsPanel, newRewards, CurChapterName)
  end
end

function MagicManualModule:MergeRewards(_rspRewards)
  local newRewards = {}
  for _, goodsItem in ipairs(_rspRewards) do
    if goodsItem.reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_LEVEL_REWARD then
      table.insert(newRewards, goodsItem)
    end
  end
  return newRewards
end

function MagicManualModule:OnCmdOpenMagicManualItemRewardsPanel(_param, _param1, IsNextChapterTips)
  if IsNextChapterTips and not self.data.HasNextChatChapter then
    return
  end
  self:OpenPanel("MagicManualItemRewards", _param, _param1, IsNextChapterTips)
end

function MagicManualModule:ZoneTaskQueryReq(task_id_list)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = task_id_list
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.OnZoneTaskQueryRsp)
end

function MagicManualModule:OnZoneTaskQueryRsp(rsp)
  local taskInfoList = {}
  if 0 == rsp.ret_info.ret_code and rsp.task_info_list then
    taskInfoList = rsp.task_info_list
  end
  for i = 1, #taskInfoList do
    self.data:SetDailyTaskDic(taskInfoList[i])
  end
  self:DispatchEvent(MagicManualModuleEvent.GetDailyTaskInfos, taskInfoList)
end

function MagicManualModule:ZoneTaskInfoNotify(notify)
end

function MagicManualModule:GetTaskReward(task_id_list)
  local req = _G.ProtoMessage:newZoneTaskRewardReq()
  req.task_list = task_id_list
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_REWARD_REQ, req, self, self.OnZoneTaskRewardRsp)
end

function MagicManualModule:OnZoneTaskRewardRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self:ZoneQueryInvestTaskReq()
    self:OnOpenMagicManual()
    if rsp.ret_info.goods_reward then
      local rewards = {}
      local viteAddNum = 0
      local viteInfo
      for i, v in pairs(rsp.ret_info.goods_reward.rewards) do
        if 7 == v.id and v.type == _G.Enum.GoodsType.GT_VITEM then
          viteAddNum = viteAddNum + v.num
        end
        if 7 ~= v.id and 10 ~= v.id and 32 ~= v.id and v.reward_reason ~= _G.ProtoEnum.FlowReason.FLOW_REASON_LEVEL_REWARD then
          table.insert(rewards, v)
        end
      end
      if viteAddNum > 0 then
        table.insert(rewards, {
          id = 7,
          type = _G.Enum.GoodsType.GT_VITEM,
          num = viteAddNum
        })
      end
      if #rewards > 0 then
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, rewards, "")
      end
    end
  end
end

function MagicManualModule:CanTipsTirgger()
  local delayedTime = 0.4
  if not self.tableTipsLastTime then
    self.tableTipsLastTime = os.time()
    return true
  end
  if delayedTime < os.time() - self.tableTipsLastTime then
    self.tableTipsLastTime = os.time()
    return true
  end
  return false
end

function MagicManualModule:ZoneQueryInvestTaskReq()
  local req = _G.ProtoMessage:newZoneQueryInvestTaskReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_INVEST_TASK_REQ, req, self, self.OnZoneQueryInvestTaskRsp)
end

function MagicManualModule:OnZoneQueryInvestTaskRsp(rsp)
  if rsp.ret_info.ret_code then
    self.data.DailyRemainTime = rsp.remain_time
    self.data.DailySpecialRewardItem = rsp.special_reward_item
    if rsp.clue_task_list then
      self.data:SetCluemTaskDic(rsp.clue_task_list)
    end
    if rsp.invest_task_list then
      self.data:SetPermanentTaskDic(rsp.invest_task_list)
    end
    if rsp.topic_task_list then
      self.data:SetDailyTaskDic(rsp.topic_task_list)
    end
    self:DispatchEvent(MagicManualModuleEvent.UpdateDailyDataEnd)
  end
end

function MagicManualModule:GetCuleNum()
  local num = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_CLUE)
  return num
end

function MagicManualModule:GetDailyTaskSpecialRewardId()
  return self.data.DailySpecialRewardItem
end

function MagicManualModule:IsGetDailyTaskSpecial()
  local taskList = self.data:GetCluemTaskList()
  local lastTask = taskList[#taskList]
  if lastTask.state == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
    return true
  end
  return false
end

function MagicManualModule:ShowOrHideMoneyBtn(bIsHide)
  if self:HasPanel("MagicManualMainPanel") then
    local panel = self:GetPanel("MagicManualMainPanel")
    panel.MagicManual:ShowOrHideMoneyBtn(bIsHide)
  end
end

function MagicManualModule:UpdateFlowerData()
  if self.data.XiShouRemainTime then
    self.data.XiShouRemainTime = self.data.XiShouRemainTime - 1
    if true or self.data.XiShouRemainTime > 0 then
      local Hour = self.data.XiShouRemainTime / 3600
      self.data.XiShouRemainTimeMin = (self.data.XiShouRemainTime - math.floor(Hour) * 60 * 60) / 60
      if self.data.OldXiShouRemainTimeMin ~= self.data.XiShouRemainTimeMin then
        self:DispatchEvent(MagicManualModuleEvent.UpdateFlowerDataEnd, true)
      end
      self.data.OldXiShouRemainTimeMin = self.data.XiShouRemainTimeMin
      self:InChallengeStartTick()
    else
      self:ZoneSceneQueryAllFlowerSeedReq()
    end
  end
end

function MagicManualModule:CancelChallengeTick()
  if self.chanllengeDelayID then
    DelayManager:CancelDelayById(self.chanllengeDelayID)
    self.chanllengeDelayID = nil
  end
end

function MagicManualModule:InChallengeStartTick()
  self:CancelChallengeTick()
  self.chanllengeDelayID = DelayManager:DelaySeconds(1, self.UpdateFlowerData, self)
end

function MagicManualModule:LeaveChallengeStopTick()
  self:CancelChallengeTick()
end

function MagicManualModule:StartBossItemTick()
  self:CancelBossItemTick()
  self.bossItemTickDelayID = DelayManager:DelaySeconds(1, self.BossItemTick, self)
end

function MagicManualModule:BossItemTick()
  self:DispatchEvent(MagicManualModuleEvent.BossListItemTick)
  self:StartBossItemTick()
end

function MagicManualModule:CancelBossItemTick()
  if self.bossItemTickDelayID then
    DelayManager:CancelDelayById(self.bossItemTickDelayID)
    self.bossItemTickDelayID = nil
  end
end

function MagicManualModule:LeaveChallengeBossStopTick()
  self:CancelBossItemTick()
end

function MagicManualModule:NeedBossItemsTick()
  self:StartBossItemTick()
end

function MagicManualModule:ZoneSceneQueryAllFlowerSeedReq()
  local req = _G.ProtoMessage:newZoneSceneQueryBossNpcInfoReq()
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() and not _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
    req.friend_uin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin()
  end
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_QUERY_BOSS_NPC_INFO_REQ, req, self, self.OnZoneQueryAllFlowerSeedRsp)
end

function MagicManualModule:ZoneMagicGetTeachingTabReq()
  if _G.DataModelMgr.PlayerDataModel then
    local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_TYPE_BATTLE_TRAIN)
    if Flags then
      local req = _G.ProtoMessage:newZoneGetTeachingTabReq()
      _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_TEACHING_TAB_REQ, req, self, self.OnZoneGetTeachingTabRsp)
    end
  end
end

function MagicManualModule:OnZoneGetTeachingTabRsp(rsp)
  local TeachingTabInfo = {}
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local teaching_tab = rsp.teaching_tab
    if teaching_tab then
      local type_advantage = teaching_tab.type_advantage
      local type_advantage_tasks = teaching_tab.type_advantage_tasks
      local combat_mechanism = teaching_tab.combat_mechanism
      local combat_mechanism_tasks = teaching_tab.combat_mechanism_tasks
      
      local function GetTeachTask(taskIds, isAdvantage)
        local tasks = {}
        local type_tasks = isAdvantage and type_advantage_tasks or combat_mechanism_tasks
        if type_tasks and #type_tasks > 0 and taskIds and #taskIds > 0 then
          for _, task_id in ipairs(taskIds) do
            for i, v in ipairs(type_tasks) do
              if v.id == task_id then
                local task = {}
                task.id = v.id
                task.is_reward = v.is_rewarded
                task.is_complish = v.is_complete
                if isAdvantage then
                  task.conf = _G.DataConfigManager:GetTypeAdvantageBattleConf(v.id)
                else
                  task.conf = _G.DataConfigManager:GetCombatMechanismBattleConf(v.id)
                end
                table.insert(tasks, task)
                break
              end
            end
          end
        end
        return tasks
      end
      
      local advantages = {}
      if type_advantage and #type_advantage > 0 then
        for i, v in ipairs(type_advantage) do
          local advantage = {}
          advantage.id = v.id
          advantage.is_unlock = v.is_unlock
          advantage.unlock_progress = v.unlock_progress
          local conf = _G.DataConfigManager:GetTypeAdvantageTeachConf(v.id)
          advantage.conf = conf
          advantage.tasks = GetTeachTask(conf and conf.type_advantage_train, true)
          table.insert(advantages, advantage)
        end
      end
      TeachingTabInfo.type_advantage = advantages
      local mechanisms = {}
      if combat_mechanism and #combat_mechanism > 0 then
        for i, v in ipairs(combat_mechanism) do
          local mechanism = {}
          mechanism.id = v.id
          mechanism.is_unlock = v.is_unlock
          mechanism.unlock_progress = v.unlock_progress
          local conf = _G.DataConfigManager:GetCombatMechanismTeachConf(v.id)
          mechanism.conf = conf
          mechanism.tasks = GetTeachTask(conf and conf.combat_mechanism_battle, false)
          table.insert(mechanisms, mechanism)
        end
      end
      TeachingTabInfo.combat_mechanism = mechanisms
      self.data.TeachingTabInfo = TeachingTabInfo
    else
      Log.Error("not MagicManualModule:OnZoneGetTeachingTabRsp teaching_tab")
    end
  else
    Log.Error(rsp and rsp.ret_info and rsp.ret_info.ret_code, "MagicManualModule:OnZoneGetTeachingTabRsp")
  end
end

function MagicManualModule:GetBattleTeachInfoById(Type, Id)
  if self.data.TeachingTabInfo then
    if Type == self.data.TeachType.Restraint and self.data.TeachingTabInfo.type_advantage then
      local type_advantage = self.data.TeachingTabInfo.type_advantage
      if type_advantage and #type_advantage > 0 then
        for i, v in ipairs(type_advantage) do
          if v.id == Id then
            return v
          end
        end
      end
    elseif Type == self.data.TeachType.Battle and self.data.TeachingTabInfo.combat_mechanism then
      local combat_mechanism = self.data.TeachingTabInfo.combat_mechanism
      if combat_mechanism and #combat_mechanism > 0 then
        for i, v in ipairs(combat_mechanism) do
          if v.id == Id then
            return v
          end
        end
      end
    end
  end
end

function MagicManualModule:GetBattleTaskInfoById(Type, ConfId, TaskId)
  if self.data.TeachingTabInfo then
    if Type == self.data.TeachType.Restraint and self.data.TeachingTabInfo.type_advantage then
      local type_advantage = self.data.TeachingTabInfo.type_advantage
      if type_advantage and #type_advantage > 0 then
        for i, v in ipairs(type_advantage) do
          if v.id == ConfId then
            local tasks = v.tasks
            if tasks and #tasks > 0 then
              for _, k in ipairs(tasks) do
                if k.id == TaskId then
                  return k
                end
              end
            end
          end
        end
      end
    elseif Type == self.data.TeachType.Battle and self.data.TeachingTabInfo.combat_mechanism then
      local combat_mechanism = self.data.TeachingTabInfo.combat_mechanism
      if combat_mechanism and #combat_mechanism > 0 then
        for i, v in ipairs(combat_mechanism) do
          if v.id == ConfId then
            local tasks = v.tasks
            if tasks and #tasks > 0 then
              for _, k in ipairs(tasks) do
                if k.id == TaskId then
                  return k
                end
              end
            end
          end
        end
      end
    end
  end
end

function MagicManualModule:OnZoneQueryAllFlowerSeedRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    local function LegendListSort(a, b)
      local IdA = 0
      
      local IdB = 0
      local LegendaryBattleEventConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.LEGENDARY_BATTLE_EVENT):GetAllDatas()
      for k, v in pairs(LegendaryBattleEventConf) do
        if v.refresh_content_id_2 == a.content_cfg_id then
          IdA = v.id
        end
        if v.refresh_content_id_2 == b.content_cfg_id then
          IdB = v.id
        end
      end
      return IdA < IdB
    end
    
    if rsp.legendary_npcs.boss_npcs then
      local LegendList = rsp.legendary_npcs.boss_npcs
      for i, v in ipairs(LegendList) do
        LegendList[i].is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, LegendList[i].content_cfg_id)
      end
      if LegendList and #LegendList > 0 then
        table.sort(LegendList, LegendListSort)
      end
      self.data.LegendList = LegendList
    else
      self.data.LegendList = {}
    end
    self.data.LegendRemainTime = rsp.legendary_npcs.remain_time
    self.data.LegendChallengeNum = rsp.legendary_npcs.available_challenge_num_via_star
    if rsp.world_leader_npcs.boss_npcs then
      self:GetAllWorldBossData(rsp.world_leader_npcs.boss_npcs)
    else
      self:GetAllWorldBossData({})
    end
    self:RefreshAllFlowerSeedReq(rsp.flower_npcs, true)
  end
end

function MagicManualModule:OnZoneSceneSpecFlowerSeedInfoNty(Nty)
  if Nty then
    self:RefreshAllFlowerSeedReq(Nty.flowers, false)
  end
end

function MagicManualModule:RefreshAllFlowerSeedReq(AllFlowerSeedInfo, RefreshAll)
  local isBigMapScene = 103 == SceneUtils.GetSceneID()
  if AllFlowerSeedInfo then
    local list = AllFlowerSeedInfo.boss_npcs
    if RefreshAll then
      if not list then
        Log.Error("NotMagicManualModuleFlowerSeedInfo")
      end
      local remain_time
      if list then
        Log.Trace(#list, "MagicManualModule:RefreshAllFlowerSeedReq")
        for i, v in pairs(list) do
          if not v.spec_flower_seed_id then
            remain_time = v.end_timestamp
          end
          local level, IsReCom = MagicManualUtils.GetFlowerLevel(list[i].star, list[i].spec_flower_seed_id)
          list[i].level = level
          list[i].IsReCom = IsReCom
          list[i].is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, list[i].content_cfg_id)
          list[i].isBigMapScene = isBigMapScene
          list[i].Distance = isBigMapScene and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetPlayerToNpcDistance, list[i].content_cfg_id) or 0
          list[i].BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, list[i].battle_petbase_id)
        end
      end
      self.data.XiShouFlowerList = list
      self.data.XiShouRemainTime = remain_time or AllFlowerSeedInfo.remain_time
      if self.data.XiShouRemainTime and self.data.XiShouRemainTime > 0 then
        self.data.XiShouRemainTimeHour = self.data.XiShouRemainTime / 3600
        self.data.XiShouRemainTimeMin = (self.data.XiShouRemainTime - math.floor(self.data.XiShouRemainTimeHour) * 60 * 60) / 60
      end
    elseif list and #list >= 1 then
      if self.data.XiShouFlowerList and #self.data.XiShouFlowerList > 0 then
        for i, k in pairs(list) do
          for index, v in pairs(self.data.XiShouFlowerList) do
            if v.content_cfg_id == k.content_cfg_id then
              self.data.XiShouFlowerList[index] = k
              local level, IsReCom = MagicManualUtils.GetFlowerLevel(self.data.XiShouFlowerList[index].star, self.data.XiShouFlowerList[index].spec_flower_seed_id)
              self.data.XiShouFlowerList[index].level = level
              self.data.XiShouFlowerList[index].IsReCom = IsReCom
              self.data.XiShouFlowerList[index].is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, self.data.XiShouFlowerList[index].content_cfg_id)
              self.data.XiShouFlowerList[index].isBigMapScene = isBigMapScene
              self.data.XiShouFlowerList[index].Distance = isBigMapScene and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetPlayerToNpcDistance, self.data.XiShouFlowerList[index].content_cfg_id) or 0
              self.data.XiShouFlowerList[index].BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, self.data.XiShouFlowerList[index].battle_petbase_id)
              break
            end
            if index == #self.data.XiShouFlowerList then
              local FlowerData = k
              local level, IsReCom = MagicManualUtils.GetFlowerLevel(FlowerData.star, FlowerData.spec_flower_seed_id)
              FlowerData.level = level
              FlowerData.IsReCom = IsReCom
              FlowerData.is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, FlowerData.content_cfg_id)
              FlowerData.isBigMapScene = isBigMapScene
              FlowerData.Distance = isBigMapScene and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetPlayerToNpcDistance, FlowerData.content_cfg_id) or 0
              FlowerData.BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, FlowerData.battle_petbase_id)
              table.insert(self.data.XiShouFlowerList, FlowerData)
              break
            end
          end
        end
      else
        self.data.XiShouFlowerList = {}
        for i, k in pairs(list) do
          local FlowerData = k
          local level, IsReCom = MagicManualUtils.GetFlowerLevel(FlowerData.star, FlowerData.spec_flower_seed_id)
          FlowerData.level = level
          FlowerData.IsReCom = IsReCom
          FlowerData.is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, FlowerData.content_cfg_id)
          FlowerData.isBigMapScene = isBigMapScene
          FlowerData.Distance = isBigMapScene and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetPlayerToNpcDistance, FlowerData.content_cfg_id) or 0
          FlowerData.BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, FlowerData.battle_petbase_id)
          table.insert(self.data.XiShouFlowerList, FlowerData)
          break
        end
      end
    end
    if self.data.XiShouFlowerList and #self.data.XiShouFlowerList >= 1 then
      local function FlowerSeedSort(a, b)
        local a_type = self:GetFlowerType(a)
        
        local b_type = self:GetFlowerType(b)
        local a_is_7star_hard_flower = a_type.Is7StarHardFlower
        local b_is_7star_hard_flower = b_type.Is7StarHardFlower
        local a_is_shiny_flower = a_type.IsShinyFlower
        local b_is_shiny_flower = b_type.IsShinyFlower
        local a_is_limit_flower = a_type.IsLimitedFlower
        local b_is_limit_flower = b_type.IsLimitedFlower
        if a_is_7star_hard_flower and not b_is_7star_hard_flower then
          return true
        end
        if not a_is_7star_hard_flower and b_is_7star_hard_flower then
          return false
        end
        if a_is_shiny_flower and not b_is_shiny_flower then
          return true
        end
        if not a_is_shiny_flower and b_is_shiny_flower then
          return false
        end
        if a_is_limit_flower and not b_is_limit_flower then
          return true
        end
        if not a_is_limit_flower and b_is_limit_flower then
          return false
        end
        if a.is_camp_unlock and not b.is_camp_unlock then
          return true
        end
        if not a.is_camp_unlock and b.is_camp_unlock then
          return false
        end
        if a.level ~= b.level then
          return a.level < b.level
        end
        if a.star == b.star then
          return a.npc_cfg_id < b.npc_cfg_id
        end
        return a.star > b.star
      end
      
      table.sort(self.data.XiShouFlowerList, FlowerSeedSort)
    end
  end
end

function MagicManualModule:GetFlowerData()
  self:InChallengeStartTick()
  self:DispatchEvent(MagicManualModuleEvent.UpdateFlowerDataEnd, false)
end

function MagicManualModule:OpenMagicManualByTeachBattleId(BattleId)
  self.OpenTeachBattleId = BattleId
  if self.data.TeachingTabInfo then
    local type_advantage = self.data.TeachingTabInfo.type_advantage
    if type_advantage and #type_advantage > 0 then
      for i, v in ipairs(type_advantage) do
        local tasks = v.tasks
        if tasks and #tasks > 0 then
          for _, k in ipairs(tasks) do
            if k.conf and k.conf.data[1] == BattleId then
              self:OnOpenMagicManualByIndex("MMT_TYPE_DAVANTAGE_TEACH")
              return
            end
          end
        end
      end
    end
    local combat_mechanism = self.data.TeachingTabInfo.combat_mechanism
    if combat_mechanism and #combat_mechanism > 0 then
      for i, v in ipairs(combat_mechanism) do
        local tasks = v.tasks
        if tasks and #tasks > 0 then
          for _, k in ipairs(tasks) do
            if k.conf and k.conf.data == BattleId then
              self:OnOpenMagicManualByIndex("MMT_COMBAT_MECHANISM_TEACH")
              return
            end
          end
        end
      end
    end
  end
  self:OnOpenMagicManualByIndex("MMT_TYPE_DAVANTAGE_TEACH")
end

function MagicManualModule:GetFlowerType(BossNpcInfo)
  local IsLimitedFlower = false
  local IsShinyFlower = false
  local Is7StarHardFlower = false
  if BossNpcInfo.spec_flower_seed_id and BossNpcInfo.activity_id then
    local activityConf = _G.DataConfigManager:GetActivityConf(BossNpcInfo.activity_id)
    if activityConf then
      if activityConf.activity_type == Enum.ActivityType.ATP_LIMITED_FLOWER_SEED then
        IsLimitedFlower = true
      elseif activityConf.activity_type == Enum.ActivityType.ATP_SHINY_WEEKEND_PREVIEW or activityConf.activity_type == Enum.ActivityType.ATP_SHINY_WEEKEND_START then
        IsShinyFlower = true
      elseif activityConf.activity_type == Enum.ActivityType.ATP_FLOWER_APPEAR_HARD then
        Is7StarHardFlower = true
      end
    end
  end
  return {
    IsLimitedFlower = IsLimitedFlower,
    IsShinyFlower = IsShinyFlower,
    Is7StarHardFlower = Is7StarHardFlower
  }
end

function MagicManualModule:MagicManualOpenBigMap(TableIndex, SubTableIndex, bIsOpenByManual)
  local needTraceCenter = true
  _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.OpenWorldMap, nil, needTraceCenter, nil, bIsOpenByManual)
end

function MagicManualModule:RefreshChallengeItemBtn(RefreshId, next_npc_refresh_time)
  if self.data.BossList and next_npc_refresh_time and next_npc_refresh_time > 0 and #self.data.BossList > 0 then
    for i = 1, #self.data.BossList do
      if self.data.BossList[i].data.content_cfg_id == RefreshId then
        self.data.BossList[i].data.next_refresh_time = next_npc_refresh_time
      end
    end
  end
  self:DispatchEvent(MagicManualModuleEvent.RefreshChallengeItemBtn, RefreshId, next_npc_refresh_time)
end

local function BossListSort(a, b)
  if a.data.is_camp_unlock and not b.data.is_camp_unlock then
    return true
  end
  if not a.data.is_camp_unlock and b.data.is_camp_unlock then
    return false
  end
  if a.data.level ~= b.data.level then
    return a.data.level < b.data.level
  end
  local AID = a.WorldCombatConf.sequence_id or 0
  local BID = b.WorldCombatConf.sequence_id or 0
  return AID < BID
end

function MagicManualModule:GetLegendPetDatas()
  self:DispatchEvent(MagicManualModuleEvent.UpdateLegendPetDataEnd)
end

function MagicManualModule:GetAllWorldBossData(BossInfos)
  local isBigMapScene = 103 == SceneUtils.GetSceneID()
  local List = {}
  local UnLockTaskList = {}
  for i = 1, #BossInfos do
    local npcId = BossInfos[i].content_cfg_id
    if not BossInfos[i].content_cfg_id then
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(BossInfos[i].world_map_cfg_id)
      npcId = worldMapConf.npc_refresh_ids[1]
    end
    BossInfos[i].is_camp_unlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.CheckNpcInFogAreaByRefreshId, npcId)
    BossInfos[i].isBigMapScene = isBigMapScene
    BossInfos[i].Distance = isBigMapScene and _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetPlayerToNpcDistance, npcId) or 0
    BossInfos[i].BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, BossInfos[i].battle_petbase_id)
    local level, IsReCom = MagicManualUtils.GetBossLevel(npcId)
    BossInfos[i].level = level
    BossInfos[i].IsReCom = IsReCom
    for k, v in pairs(WORLD_COMBAT_CONF) do
      if v.refresh_content_id == npcId then
        local lockType = 0
        if v.unlock_task_id and 0 ~= v.unlock_task_id then
          lockType = 2
          table.insert(UnLockTaskList, v.unlock_task_id)
        end
        if 1 == v.whether_display then
          table.insert(List, {
            data = BossInfos[i],
            LockType = lockType,
            WorldCombatConf = v
          })
          break
        end
      end
    end
  end
  table.sort(List, BossListSort)
  self.data.BossList = List
  if _G.DataModelMgr.PlayerDataModel:IsVisitState() then
    self:DispatchEvent(MagicManualModuleEvent.UpdateBossDataEnd)
    return
  end
  if #UnLockTaskList > 0 then
    self:BossListZoneTaskQueryReq(UnLockTaskList)
  else
    self:SetLockState({})
  end
end

function MagicManualModule:BossListZoneTaskQueryReq(taskidList)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = taskidList
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.OnBossListZoneTaskQueryRsp)
end

function MagicManualModule:OnBossListZoneTaskQueryRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    if rsp.task_info_list then
      self:SetLockState(rsp.task_info_list)
    else
      self:SetLockState({})
    end
  else
    self:SetLockState({})
  end
end

function MagicManualModule:SetLockState(taskIdList)
  if #taskIdList > 0 then
    for i = 1, #self.data.BossList do
      for j = 1, #taskIdList do
        if taskIdList[j].id == self.data.BossList.WorldCombatConf.unlock_task_id then
          if taskIdList[j].state >= ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
            self.data.BossList[i].LockType = 0
            break
          end
          self.data.BossList[i].LockType = 2
          break
        end
      end
      if 0 == self.data.BossList[i].LockType and self.data.BossList[i].status == _G.ProtoEnum.LockStatus.ENUM.LOCKED then
        self.data.BossList[j].LockType = 1
      end
    end
  end
  self:DispatchEvent(MagicManualModuleEvent.UpdateBossDataEnd)
end

function MagicManualModule:GetBossData()
  self:DispatchEvent(MagicManualModuleEvent.UpdateBossDataEnd)
end

function MagicManualModule:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAGICMANUA)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM)
end

function MagicManualModule:RegPanel(name, path, layer, openAnimName, closeAnimName, autoSetDesiredCursor)
  local MainPanelData = _G.NRCPanelRegisterData()
  MainPanelData.panelName = name
  MainPanelData.panelPath = string.format("/Game/NewRoco/Modules/System/MagicManual/Res/%s", path)
  MainPanelData.panelLayer = layer
  if openAnimName then
    MainPanelData.openAnimName = openAnimName
  end
  if closeAnimName then
    MainPanelData.closeAnimName = closeAnimName
  end
  MainPanelData.autoSetDesiredCursor = autoSetDesiredCursor
  self:RegisterPanel(MainPanelData)
end

function MagicManualModule:GetOpeningLimitedFlowerActivity()
  local ActivityList = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_LIMITED_FLOWER_SEED)
  return ActivityList and ActivityList[1] or nil
end

function MagicManualModule:GetOpeningShinyActivity()
  local ActivityList = NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_SHINY_WEEKEND_START)
  return ActivityList and ActivityList[1] or nil
end

function MagicManualModule:IsLimitedFlower(NpcRefreshId)
  if self.data.XiShouFlowerList and #self.data.XiShouFlowerList > 0 then
    for i, v in pairs(self.data.XiShouFlowerList) do
      if v.content_cfg_id == NpcRefreshId and v.activity_id and v.spec_flower_seed_id then
        local activityConf = _G.DataConfigManager:GetActivityConf(v.activity_id)
        if activityConf and activityConf.activity_type == Enum.ActivityType.ATP_LIMITED_FLOWER_SEED then
          return true
        end
      end
    end
  end
  return false
end

function MagicManualModule:GetMagicManualFlowerInfoByNpcRefreshId(NpcRefreshId)
  if self.data.XiShouFlowerList and #self.data.XiShouFlowerList > 0 then
    for i, v in pairs(self.data.XiShouFlowerList) do
      if v.content_cfg_id == NpcRefreshId then
        return v
      end
    end
  end
end

function MagicManualModule:GetMagicManualBossInfoByNpcRefreshId(NpcRefreshId)
  if self.data.BossList and #self.data.BossList > 0 then
    for i, v in pairs(self.data.BossList) do
      if v.data.content_cfg_id == NpcRefreshId then
        return v.data
      end
    end
  end
end

function MagicManualModule:HasDoubleTeamBattleReward()
  local Activity = self:GetOpeningShinyActivity()
  if Activity then
    local Info = Activity:GetPlayerShinyPetDayInfo()
    return Info and (Info.remaining_doule_times or 0) > 0
  end
  return false
end

function MagicManualModule:GetShinyNpcFlowerInfo(NpcRefreshId)
  if self.data.XiShouFlowerList and #self.data.XiShouFlowerList > 0 then
    for i, v in pairs(self.data.XiShouFlowerList) do
      if v.content_cfg_id == NpcRefreshId and v.activity_id and v.spec_flower_seed_id then
        local activityConf = _G.DataConfigManager:GetActivityConf(v.activity_id)
        if activityConf and activityConf.activity_type == Enum.ActivityType.ATP_SHINY_WEEKEND_START then
          return v
        end
      end
    end
  end
end

function MagicManualModule:GetNpcFlowerInfo(NpcRefreshId)
  if self.data.XiShouFlowerList and #self.data.XiShouFlowerList > 0 then
    for i, v in pairs(self.data.XiShouFlowerList) do
      if v.content_cfg_id == NpcRefreshId then
        return v, self:GetFlowerType(v)
      end
    end
  end
end

function MagicManualModule:GetShinyNpcTeamBattleThrowCount(NpcRefreshId)
  local Activity = self:GetOpeningShinyActivity()
  if Activity then
    local Info = Activity:GetActivityShinyPetDayData()
    if Info and Info.flower_seed_content_id == NpcRefreshId then
      return Info and Info.total_catch_num or 0
    end
  end
  return 0
end

function MagicManualModule:OnCmdHideMagicManualMain()
  local Panel = self:GetPanel("MagicManualMainPanel")
  if Panel then
    Panel:Hide()
  end
end

function MagicManualModule:OnCmdShowMagicManualMain()
  local Panel = self:GetPanel("MagicManualMainPanel")
  if Panel then
    Panel:Show()
  end
end

function MagicManualModule:OnCmdSelectGamePlayTabType(_data)
  self:DispatchEvent(MagicManualModuleEvent.SelectGamePlayTabTypeEvent, _data)
end

function MagicManualModule:OnCmdOpenPlayDetails(BattleRuleId)
  self:OpenPanel("PlayDetails", BattleRuleId)
end

function MagicManualModule:OnCmdOpenDescTextPanel(descText)
  if self:HasPanel("PlayDetails") then
    local Panel = self:GetPanel("PlayDetails")
    if Panel then
      Panel:ShowDescPanel(descText)
    end
  end
end

function MagicManualModule:OmCmdUpdateAppearanceRate()
  if self:HasPanel("MagicManualMainPanel") then
    self:DispatchEvent(MagicManualModuleEvent.UpdateAppearanceRateEvent)
  end
end

function MagicManualModule:OnCmdHadAgreeRankTeleport()
  local myUinStr = tostring(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  self.data:LoadRankPvpTeleportAgreement()
  if self.data.RankPvpTeleportAgreement[myUinStr] == nil then
    return false
  end
  return true
end

function MagicManualModule:OnCmdAgreeRankTeleport()
  local myUinStr = tostring(_G.DataModelMgr.PlayerDataModel:GetPlayerUin())
  self.data.RankPvpTeleportAgreement[myUinStr] = true
  return self.data:SaveRankPvpTeleportAgreement()
end

function MagicManualModule:OnCmdOpenChapterBeginPanel(uiData, cache)
  if cache then
    self.cacheChapterBeginData = uiData
    return
  end
  local Panel = self:HasPanel(uiData.panelName)
  if not Panel then
    self:OpenPanel(uiData.panelName, uiData)
  end
end

function MagicManualModule:OnCmdOpenSeasonManual(chapterID, notBringToFront)
  self.OpenSeasonPanelMark = true
  self.SeasonPanelNeedBringToFront = not notBringToFront
  self:OnReqSeasonManualData(chapterID)
end

function MagicManualModule:OnCmdOpenSeasonBadgePanel()
  local Panel = self:HasPanel("SeasonBadge")
  if not Panel then
    self:OpenPanel("SeasonBadge", self.data)
  end
end

function MagicManualModule:OnCmdCacheChapterBeginUIDataToFile(uiData)
  if uiData then
    JsonUtils.DumpSaved(self.SeasonChapterBeginUIData, uiData)
  end
end

function MagicManualModule:IsSameSeasonChapter(chapterID)
  local currChapterInfo = self.data:GetSeasonChapterData()
  if chapterID and currChapterInfo and currChapterInfo.currSeasonChapterID == chapterID then
    return true
  end
  return false
end

function MagicManualModule:OnReqSeasonManualData(chapterID)
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_SADV)
  if not Flags then
    return
  end
  local req = _G.ProtoMessage:newZoneOpenSeasonAdventureReq()
  req.chapter_id = chapterID or 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_OPEN_SEASON_ADVENTURE_REQ, req, self, self.OnSeasonManualDataRsp)
end

function MagicManualModule:OnSeasonManualDataRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:OnUpdateSeasonManualData(rsp)
    if self.OpenSeasonPanelMark then
      self.TableIndex = self.data.TaskSortType.Task_Adventure
      self.ManaulChildIndex = self.data.ManualTaskType.SeasonManual
      if self:HasPanel("MagicManualMainPanel") then
        if self.SeasonPanelNeedBringToFront then
          self:OpenPanel("MagicManualMainPanel", _G.NRCPanelOpenOptions.New():SetOpenStrategy(_G.NRCPanelEnum.NRCPanelOpenStrategy.BringToFront))
        end
      else
        self:OpenPanel("MagicManualMainPanel", rsp.chapter_id)
      end
      self:DispatchEvent("MagicManualModuleEvent.UpdateManualTab", self.TableIndex, self.ManaulChildIndex)
      self.OpenSeasonPanelMark = false
    end
  else
    if self.OpenSeasonPanelMark then
      self.OpenSeasonPanelMark = false
    end
    Log.Error("MagicManualModule:OnSeasonManualDataRsp ErrorCode = ", rsp.ret_info.ret_code)
  end
end

function MagicManualModule:OnReqSeasonManualChapterReward(chapterID)
  local req = _G.ProtoMessage:newZoneRewardSeasonAdventureChapterReq()
  req.chapter_id = chapterID
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_REWARD_SEASON_ADVENTURE_CHAPTER_REQ, req, self, self.OnSeasonManualChapterRewardRsp)
end

function MagicManualModule:OnSeasonManualChapterRewardRsp(rsp, reqData)
  if 0 == rsp.ret_info.ret_code then
    local CurRewardConf = rsp.ret_info.goods_reward
    if #CurRewardConf.rewards > 0 then
      local newRewards = self:MergeRewards(rsp.ret_info.goods_reward.rewards)
      local charpterConfData = self.data:GetCurrentChapterData(reqData.chapter_id)
      local CurChapterName = ""
      if charpterConfData and charpterConfData.chapterConfData then
        CurChapterName = self.data:TranslateCurChapterName(charpterConfData.chapterConfData.chapter_num)
      end
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OpenMagicManualItemRewardsPanel, newRewards, CurChapterName)
      self.data:OnUpdataChapterRewardState(reqData.chapter_id, ProtoEnum.PlayerSeasonAdventureChapterStatus.REWARED)
    end
  else
    Log.Error("MagicManualModule:OnSeasonManualChapterRewardRsp ErrorCode = ", rsp.ret_info.ret_code)
  end
end

function MagicManualModule:OnReqSeasonManualBadgeUpgrade()
  local req = _G.ProtoMessage:newZoneUpgradeSeasonAdventureBadgeReq()
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_UPGRADE_SEASON_ADVENTURE_BADGE_REQ, req, self, self.OnSeasonManualBadgeUpgradeRsp)
end

function MagicManualModule:OnSeasonManualBadgeUpgradeRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:OnUpdataBadgeInfo(rsp.badge_info)
    self:DispatchEvent("MagicManualModuleEvent.UpdateSeasonManualBadge")
    if rsp.ret_info.goods_reward then
      local newRewards = self:MergeRewards(rsp.ret_info.goods_reward.rewards)
      if self.BadgeUpgradeRewardDelayId then
        _G.DelayManager:CancelDelay(self.BadgeUpgradeRewardDelayId)
        self.BadgeUpgradeRewardDelayId = nil
      end
      
      local function doShowReward()
        _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenNPCShopItemRewardsPanel, newRewards, "")
        self.BadgeUpgradeRewardDelayId = nil
      end
      
      local badgeLVLConf = _G.DataConfigManager:GetSeasonAdventureBadgeLevel(rsp.badge_info.badge_lvl, true)
      if badgeLVLConf and (not badgeLVLConf.next_level or 0 == badgeLVLConf.next_level) then
        self.BadgeUpgradeRewardDelayId = _G.DelayManager:DelaySeconds(1.5, doShowReward)
      else
        doShowReward()
      end
    end
  else
    Log.Error("MagicManualModule:OnSeasonManualBadgeUpgradeRsp ErrorCode = ", rsp.ret_info.ret_code)
  end
end

function MagicManualModule:OnReqTaskData(taskid)
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = {taskid}
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetTaskStateInfoRsp)
end

function MagicManualModule:GetTaskStateInfoRsp(rsp)
  if 0 == rsp.ret_info.ret_code then
    self.data:OnUpdataTaskStateInfo(rsp.task_info_list)
    self:DispatchEvent("MagicManualModuleEvent.UpdateSeasonManualTask")
  else
    Log.Error("MagicManualModule:GetTaskStateInfoRsp ErrorCode = ", rsp.ret_info.ret_code)
  end
end

function MagicManualModule:TaskChangeNotify(task_list)
  if not task_list or 0 == #task_list then
    return
  end
  self.data:OnUpdataTaskStateInfo(task_list)
  self:DispatchEvent("MagicManualModuleEvent.UpdateSeasonManualTask")
end

function MagicManualModule:OnCmdOpenSeasonManualChapter(chapterID, badgeLevel)
  local req = _G.ProtoMessage:newZoneGmSeasonAdventureSettingReq()
  req.uin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
  req.chapter_id = chapterID
  req.badge_lvl = badgeLevel
  req.operate_type = nil ~= chapterID and 0 or 1
  _G.ZoneServer:Send(ProtoCMD.ZoneSvrGmCmd.ZONE_GM_SEASON_ADVENTURE_SETTING_REQ, req)
end

function MagicManualModule:OpenRecallPanel(recallConfId, parent)
  if not recallConfId or 0 == recallConfId or type(recallConfId) ~= "number" then
    Log.Error("\232\175\149\229\155\190\230\137\147\229\188\128\228\184\128\228\184\170\228\184\141\229\173\152\229\156\168\231\154\132\229\155\158\230\131\179\233\157\162\230\157\191")
    return
  end
  local recallConf = _G.DataConfigManager:GetReacallConf(recallConfId)
  if not recallConf then
    Log.Error("\229\176\157\232\175\149\230\137\147\229\188\128id\239\188\154%s\231\154\132\229\155\158\230\131\179\233\157\162\230\157\191\239\188\140\228\189\134\229\156\168\232\161\168\230\160\188\228\184\173\228\184\141\229\173\152\229\156\168\239\188\140\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174", recallConfId)
    return
  end
  self:OpenPanel("RecallPanel", recallConfId, parent)
end

function MagicManualModule:TutorJumpToPanel(cmd, ...)
  if string.IsNilOrEmpty(cmd) then
    Log.Error("\229\176\157\232\175\149\230\137\167\232\161\140\231\169\186\229\145\189\228\187\164")
    return
  end
  
  local function closePanel()
    if self:HasPanel("MagicManualMainPanel") then
      local panel = self:GetPanel("MagicManualMainPanel")
      panel:DoClose()
    end
  end
  
  if "TaskModuleCmd.TraceOpenPetPanel" == cmd then
    if self.closePanelTimerID then
      _G.DelayManager:CancelDelay(self.closePanelTimerID)
      self.closePanelTimerID = nil
    end
    self.closePanelTimerID = _G.DelayManager:DelaySeconds(0.1, function()
      closePanel()
      self.closePanelTimerID = nil
    end)
  else
    closePanel()
  end
  local params = {
    ...
  }
  self.delayTutorJumpId = _G.DelayManager:DelayFrames(1, function()
    _G.NRCModuleManager:DoCmd(cmd, table.unpack(params))
    self.delayTutorJumpId = nil
  end)
end

function MagicManualModule:GetRecallRelatedTaskStateReq(recallId)
  local tasks = MagicManualUtils.GetAllTaskIdFromRecallId(recallId)
  local needToCheckTask = {}
  if tasks then
    for i, v in ipairs(tasks) do
      if not self.data.CompletedTaskMap[v] then
        table.insert(needToCheckTask, v)
      end
    end
  end
  if 0 == #needToCheckTask then
    self:DispatchEvent(MagicManualModuleEvent.OnRecallCheckTaskFinished, true, recallId)
    return
  end
  self.curReqRecallId = recallId
  local req = _G.ProtoMessage:newZoneTaskQueryReq()
  req.task_list = needToCheckTask
  req.task_state = 0
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_TASK_QUERY_REQ, req, self, self.GetRecallRelatedTaskStateRsp, false)
end

function MagicManualModule:GetRecallRelatedTaskStateRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\232\175\183\230\177\130\229\155\158\230\131\179\228\187\187\229\138\161\229\174\140\230\136\144\230\131\133\229\134\181\229\164\177\232\180\165")
    self:DispatchEvent(MagicManualModuleEvent.OnRecallCheckTaskFinished, false, self.curReqRecallId)
    return
  end
  if rsp.task_info_list then
    for k, v in ipairs(rsp.task_info_list) do
      if v.state >= _G.ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        self.data.CompletedTaskMap[v.id] = true
      end
    end
  end
  self:DispatchEvent(MagicManualModuleEvent.OnRecallCheckTaskFinished, true, self.curReqRecallId)
end

function MagicManualModule:IsLimitSatisfy(limits)
  if not limits or 0 == #limits then
    return true
  end
  
  local function IsAdventureFinished(chapterId)
    if not chapterId or 0 == chapterId then
      return false
    end
    if self.data and self.data.AllTaskRegionList then
      for _, region in pairs(self.data.AllTaskRegionList) do
        if region.ChapterList then
          for _, chapter in pairs(region.ChapterList) do
            if chapter.ChapterId == chapterId then
              if not chapter.taskList or 0 == #chapter.taskList then
                return false
              end
              for _, taskInfo in pairs(chapter.taskList) do
                if taskInfo.state < ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
                  return false
                end
              end
              return true
            end
          end
        end
      end
    end
  end
  
  for k, v in pairs(limits) do
    if v.trigger == _G.Enum.ReacallUnlockTriggerType.RCU_TASK then
      if self.data.CompletedTaskMap[v.data] then
        return true
      end
    elseif v.trigger == _G.Enum.ReacallUnlockTriggerType.RCU_ADVENTURE then
      if IsAdventureFinished(v.data) then
        return true
      end
    elseif v.trigger == _G.Enum.ReacallUnlockTriggerType.RCU_MAGIC_LEVEL then
      if _G.DataModelMgr.PlayerDataModel:GetPlayerLevel() >= v.data then
        return true
      end
    elseif v.trigger == _G.Enum.ReacallUnlockTriggerType.RCU_STORYFLAG and _G.DataModelMgr.PlayerDataModel:HasStoryFlag(v.data) then
      return true
    end
  end
  return false
end

function MagicManualModule:OnDebugOpenSeasonAssignment(chapterId)
  local uiData = {}
  uiData.chapterNumber = self.data:TranslateCurChapterName(2)
  uiData.chapterName = "SeasonChapterBegin"
  uiData.panelName = "SeasonChapterBegin"
  uiData.id = 10201
  self:OpenPanel(uiData.panelName, uiData)
end

return MagicManualModule
