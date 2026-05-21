local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local UMG_MagicManual_Main_C = _G.NRCPanelBase:Extend("UMG_MagicManual_Main_C")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_MAGIC_BOOK
local TabIndexFunctionEntrance = {
  [0] = Enum.FunctionEntrance.FE_MAGIC_BOOK_TASK,
  [1] = Enum.FunctionEntrance.FE_MAGIC_BOOK_DAILY_INVESTIGATE
}
local SubPanel = {
  MagicManualSubPanel = 1,
  DailySurveySubPanel = 2,
  ChallengeSubPanel = 3,
  PvPSubPanel = 4,
  ChallengePlaySubPanel = 5,
  RecallSubPanel = 6
}

local function CheckIfBan(tabIndex, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if not isBan and tabIndex then
    local functionEntrance = TabIndexFunctionEntrance[tabIndex]
    if functionEntrance then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntrance, showMsg)
    end
  end
  return isBan
end

function UMG_MagicManual_Main_C:OnConstruct()
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ADVENTURE)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_ADVENTURE)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self:SetChildViews(self.MagicManual)
  self:BindInputAction()
  self.subsPanel = {
    self.MagicManual
  }
  self.MagicManual.parent = self
  self.IsCanOnClick = false
  self.CloseBtn_1.NRCSwitcher_1:SetActiveWidgetIndex(2)
  self:RegisterEvent(self, MagicManualModuleEvent.UpdateTableView, self.OnSelectTabIndexChangeHandler)
  self.functionBanUIController = FunctionBanUIController()
  do
    local functionBanUIController = self.functionBanUIController
    for tabIndex, functionEntrance in pairs(TabIndexFunctionEntrance) do
      functionBanUIController:RegisterCustomCallback(functionEntrance, self.OnMagicManualTabVisibilityChangeHandler, self, tabIndex)
    end
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnMagicManualTabVisibilityChangeHandler, self, -1)
    end
    functionBanUIController:Activate()
  end
end

function UMG_MagicManual_Main_C:OnActive(TaskPanelInfo)
  if self.module.IsMapToMagicManual then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.FirstSelectTimer = 3
  self.SelectLoopTimer = 8
  self.UpdateTime = 0
  self.IsFirst = true
  self.data = self.module:GetData("MagicManualModuleData")
  if self.module.TableIndex == self.data.TaskSortType.Task_Daily then
    self.MagicManual:LoadSubPanel(2, self.module)
  elseif self.module.TableIndex == self.data.TaskSortType.Task_Adventure then
    self.MagicManual:LoadSubPanel(1, TaskPanelInfo, self.module)
  elseif self.module.TableIndex == self.data.TaskSortType.Task_Challenge then
    self.MagicManual:LoadSubPanel(3, self.module)
  elseif self.module.TableIndex == self.data.TaskSortType.PVP_Challenge then
    self.MagicManual:LoadSubPanel(4, self.module)
  elseif self.module.TableIndex == self.data.TaskSortType.PVE_Challenge then
    self.MagicManual:LoadSubPanel(5, self.module)
  elseif self.module.TableIndex == self.data.TaskSortType.Teach then
    self.MagicManual:LoadSubPanel(6, self.module)
  end
  self.IsFirst = true
  self:OnAddEventListener()
  local cluemTaskDic = self.data.CluemTaskDic
  if TaskPanelInfo then
    self:SetTaskInfoList(TaskPanelInfo)
    self:SetPanelInfo()
  end
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  self:PlayAnimation(self.In)
  self.MagicManual:PlayAnimation(self.MagicManual.In)
  self:UnlockIsSelectBtn()
  _G.NRCAudioManager:PlaySound2DAuto(40004004, "UMG_MagicManual_Main_C:OnClickBtnClose")
end

function UMG_MagicManual_Main_C:GetClueTaskIdList()
  local TaskId = self.data:GetCluemTaskList()
  if TaskId and #TaskId > 0 then
    local DailyTaskRewardConf = _G.DataConfigManager:GetAllByName("DAILY_TASK_REWARD_CONF")
    for _, v in pairs(DailyTaskRewardConf) do
      local taskList = v.task_id
      for _, Id in pairs(taskList) do
        if Id == TaskId[1].id then
          return v.task_id
        end
      end
    end
  end
end

function UMG_MagicManual_Main_C:OnEnable()
end

function UMG_MagicManual_Main_C:SetPanelInfo()
  local TaskTypeList = {}
  local taskTabList = self:AddOtherTabInfo(TaskTypeList)
  local SelectIndex = self.data:GetSelectIndex()
  self.TabList = taskTabList
  self.List:InitGridView(taskTabList)
  self.List:SetItemCanClickChecker(self.CheckTabCanClick, self)
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    SelectIndex = 0
  elseif 1 == GlobalConfig.OpenMainPanelFromDebugBtn then
    SelectIndex = 0
  end
  if 0 == SelectIndex then
    local hideMagicManual = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK_TASK)
    if hideMagicManual then
      if #taskTabList > 1 then
        SelectIndex = 1
      else
        self:DoClose()
        return
      end
    end
  end
  if self.module.TableIndex > -1 then
    self:SelectTabByTabIndex(self.module.TableIndex)
    self.module.TableIndex = -1
  else
    self.List:SelectItemByIndex(SelectIndex)
  end
end

function UMG_MagicManual_Main_C:SelectTabByTabIndex(TabIndex)
  if self.TabList and #self.TabList > 0 then
    local index = 0
    for i, v in ipairs(self.TabList) do
      if v.Sort == TabIndex then
        index = i - 1
      end
    end
    if 0 == index then
      local hideMagicManual = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAGIC_BOOK_TASK)
      if hideMagicManual then
        index = 1
      end
    end
    self.List:SelectItemByIndex(index)
  end
end

function UMG_MagicManual_Main_C:AddOtherTabInfo(TaskTypeList)
  table.insert(TaskTypeList, {
    Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_miaomiaomoren_png.img_miaomiaomoren_png'",
    UnderlayPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_miaomiaoxuanze_png.img_miaomiaoxuanze_png'",
    Sort = self.data.TaskSortType.Task_Adventure,
    TabEnum = Enum.MagicManualTab.MMT_MAGIC_ASSIGNMENT,
    open = true,
    TaskTypeName = LuaText.magicmanualmoduledata_1
  })
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_CHALLENGE)
  if Flags then
    table.insert(TaskTypeList, {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_Challengemoren_png.img_Challengemoren_png'",
      UnderlayPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_Challengexuanze_png.img_Challengexuanze_png'",
      Sort = self.data.TaskSortType.Task_Challenge,
      TabEnum = Enum.MagicManualTab.MMT_FLOWER_PANEL,
      open = true,
      TaskTypeName = nil
    })
  end
  Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_PVP)
  if Flags then
    table.insert(TaskTypeList, {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_pvp1_png.img_pvp1_png'",
      UnderlayPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_pvp2_png.img_pvp2_png'",
      Sort = self.data.TaskSortType.PVP_Challenge,
      open = true,
      TaskTypeName = _G.DataConfigManager:GetLocalizationConf("magicmanualmoduledata_4").msg
    })
  end
  Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_MAGICMANUAL_TYPE_BATTLE_TRAIN)
  if Flags then
    table.insert(TaskTypeList, {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_teaching_png.img_teaching_png'",
      UnderlayPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_teachingxuanze_png.img_teachingxuanze_png'",
      Sort = self.data.TaskSortType.Teach,
      open = true,
      TaskTypeName = nil
    })
  end
  local NPCChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_NPC_CHALLENGE_EVENT)
  local IsUnLock = false
  if NPCChallengeEventActivityObject and NPCChallengeEventActivityObject[1] then
    local npc_challenge_data = NPCChallengeEventActivityObject[1]:GetNpcChallengeData()
    if npc_challenge_data then
      IsUnLock = true
    end
  end
  local BossChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_BOSS_CHALLENGE_EVENT)
  if BossChallengeEventActivityObject and BossChallengeEventActivityObject[1] then
    local boss_challenge_data = BossChallengeEventActivityObject[1]:GetBossChallengeData()
    if boss_challenge_data then
      IsUnLock = true
    end
  end
  local WeeklyChallengeEventActivityObject = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_WEEKLY_CHALLENGE_EVENT)
  if WeeklyChallengeEventActivityObject and WeeklyChallengeEventActivityObject[1] then
    local weekly_challenge_data = WeeklyChallengeEventActivityObject[1]:GetWeeklyChallengeData()
    if weekly_challenge_data then
      IsUnLock = true
    end
  end
  if IsUnLock then
    table.insert(TaskTypeList, {
      Icon = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_jianyingmoren_png.img_jianyingmoren_png'",
      UnderlayPath = "PaperSprite'/Game/NewRoco/Modules/System/MagicManual/Raw/MagicManual/Frames/img_jianyingxuanze_png.img_jianyingxuanze_png'",
      Sort = self.data.TaskSortType.PVE_Challenge,
      open = true,
      TaskTypeName = _G.DataConfigManager:GetLocalizationConf("challenge_title_1").msg
    })
  end
  return TaskTypeList
end

function UMG_MagicManual_Main_C:SetTaskInfoList(_TaskPanelInfo)
  local TaskPanelInfo = _TaskPanelInfo
  self.MagicManual:OnActive(TaskPanelInfo, self.IsFirst)
  self.IsFirst = false
end

function UMG_MagicManual_Main_C:OnDestruct()
  self.module.SubTableIndex = -1
  self.module.data.PreTaskInfo = nil
  self.module.TaskOpenCmd = false
  self.module.cacheChapterBeginData = nil
  self.module.OpenTeachBattleId = nil
  self:UnRegisterEvent(self, MagicManualModuleEvent.UpdateTableView, self.OnSelectTabIndexChangeHandler)
  self:UnRegisterEvent(self, MagicManualModuleEvent.OnRecallCheckTaskFinished, self.OnRecallCheckTaskFinished)
  if self.functionBanUIController then
    self.functionBanUIController:Deactivate()
  end
end

function UMG_MagicManual_Main_C:OnDeactive()
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
end

function UMG_MagicManual_Main_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_MagicManualUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseMagicManualUI", self, "OnPcClose")
    mappingContext:BindAction("IA_CloseMagicManualQuick", self, "OnPcClose")
  end
end

function UMG_MagicManual_Main_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  if self.MagicManual.TableIndex == SubPanel.MagicManualSubPanel then
    local MagicManualSubPanel = self.MagicManual:GetSubPanel(SubPanel.MagicManualSubPanel)
    if MagicManualSubPanel and MagicManualSubPanel.DescId then
      MagicManualSubPanel:OnDescCloseClick()
      return
    end
  end
  self:OnClickBtnClose()
end

function UMG_MagicManual_Main_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn_1.btnClose, self.OnClickBtnClose)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  self:RegisterEvent(self, MagicManualModuleEvent.OnRecallCheckTaskFinished, self.OnRecallCheckTaskFinished)
end

function UMG_MagicManual_Main_C:OnRecallCheckTaskFinished(bSuccess, recallId)
  if self.MagicManual and self.MagicManual.MagicManualLoader then
    local MagicManualPanel = self.MagicManual.MagicManualLoader:GetPanel()
    if MagicManualPanel then
      MagicManualPanel:OnRecallTaskChecked(bSuccess, recallId)
    end
  end
end

function UMG_MagicManual_Main_C:OnClickBtnClose()
  if self.MagicManual and self.MagicManual.TableIndex == SubPanel.RecallSubPanel then
    if self.module then
      self.module:DispatchEvent(MagicManualModuleEvent.UpdateTableView, SubPanel.MagicManualSubPanel)
    else
      self:DispatchEvent(MagicManualModuleEvent.UpdateTableView, SubPanel.MagicManualSubPanel)
    end
    return
  end
  self:CloseMagicManual()
end

function UMG_MagicManual_Main_C:CloseMagicManual()
  local mappingContext = self:GetInputMappingContext("IMC_MagicManualUI")
  if mappingContext then
    mappingContext:UnBindAction("IA_CloseMagicManualUI")
    mappingContext:UnBindAction("IA_CloseMagicManualQuick")
  end
  _G.NRCAudioManager:PlaySound2DAuto(40004005, "UMG_MagicManual_Main_C:OnClickBtnClose")
  self:OnClose()
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_MagicManual_Main_C:IsInOutAnim()
  return self:IsAnimationPlaying(self.Out)
end

function UMG_MagicManual_Main_C:SetVisibility(_ESlateVisibility)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if _ESlateVisibility == UE4.ESlateVisibility.SelfHitTestInvisible and self.MagicManual then
    if self.MagicManual.MagicManualLoader then
      local MagicManualPanel = self.MagicManual.MagicManualLoader:GetPanel()
      if MagicManualPanel then
        MagicManualPanel:SetBtnCanClick()
      end
    end
    if self.MagicManual.DailySurveyLoader then
      local DailySurvey = self.MagicManual.DailySurveyLoader:GetPanel()
      if DailySurvey then
        DailySurvey:SetBtnCanClick()
      end
    end
  end
  self.Overridden.SetVisibility(self, _ESlateVisibility)
end

function UMG_MagicManual_Main_C:UnlockIsSelectBtn()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAGICMANUA)
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM)
end

function UMG_MagicManual_Main_C:Hide()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MagicManual_Main_C:Show()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_MagicManual_Main_C:OnUnDoFoldCollapsed()
  if not self.module or not self.data then
    return
  end
  if self.MagicManual and self.MagicManual.TableIndex == SubPanel.MagicManualSubPanel and self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    self.module:OnCmdOpenSeasonManual(nil, true)
  end
end

function UMG_MagicManual_Main_C:OnSelectTabIndexChangeHandler(tabIndex, tableName)
  local isBan = CheckIfBan(tabIndex - 1, false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_MagicManual_Main_C:CheckTabCanClick(tabItem, tabIndex, userClick)
  if userClick then
    return not CheckIfBan(tabIndex, true)
  end
  return true
end

function UMG_MagicManual_Main_C:OnMagicManualTabVisibilityChangeHandler(tabIndex, funcId, bHide)
  if funcId == FunctionEntranceMain or tabIndex == self.List:GetSelectedIndex() then
    local isBan = bHide or CheckIfBan(tabIndex, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManual_Main_C:OnBlockBtnClicked()
  local isBan = CheckIfBan(self.List:GetSelectedIndex(), true)
  if not isBan then
    Log.Error("UMG_MagicManual_Main_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_MagicManual_Main_C:OnTouchEnded(_MyGeometry, _InTouchEvent)
  _G.NRCEventCenter:DispatchEvent(MagicManualModuleEvent.OnMagicManualMainPanelTouchEnded)
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_MagicManual_Main_C
