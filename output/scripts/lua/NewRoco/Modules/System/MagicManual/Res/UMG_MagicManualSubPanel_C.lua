local JsonUtils = require("Common.JsonUtils")
local _ChapterBeginCacheFilename = "ChapterBeginCache"
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local MagicManualModuleEvent = require("NewRoco.Modules.System.MagicManual.MagicManualModuleEvent")
local NPCShopUtils = require("NewRoco.Modules.System.NPCShopUI.NPCShopUtils")
local NPCShopUIModuleEvent = reload("NewRoco.Modules.System.NPCShopUI.NPCShopUIModuleEvent")
local UMG_MagicManualSubPanel_C = _G.NRCPanelBase:Extend("UMG_MagicManualSubPanel_C")

function UMG_MagicManualSubPanel_C:OnEnable(TaskPanelInfo, module)
  self.TaskPanelInfo = TaskPanelInfo
  self.module = module
  self.data = self.module.data
  self.curRecallId = 0
  self.curDescRecallId = 0
  self.CloseBtn_Global:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local isOpen = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo) and true or false
  local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_SADV)
  if not isOpen or not Flags then
    self.module.ManaulChildIndex = self.data.ManualTaskType.NormalManual
  end
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
    self.module:CheckAndSetSelectRewardChapter()
  else
    local chapterList = self.data:GetSeasonChapterList()
    if not chapterList then
      Log.Error("Not SeasonChapterList")
    end
    for i, v in ipairs(chapterList) do
      local hasRewardRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 432, {
        v.chapterConfData.id
      })
      if hasRewardRedPoint and self.data.SeasonChapterData then
        self.data.SeasonChapterData.currSeasonChapterID = v.chapterConfData.id
        break
      end
    end
  end
  self.ComboBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ShowRegion(isOpen, Flags)
  self:OnPlayEnterAnim()
  self.module:LeaveChallengeStopTick()
  self.module:LeaveChallengeBossStopTick()
  self:OnAddEventListener()
  self.State_2:SetRenderScale(UE4.FVector2D(1, 1))
  self.ComboBox.OnPopupVisibilityChanged = _G.MakeWeakFunctor(self, self.SetGlobalBtn)
  self.TabList1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.img_Tabbg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not isOpen or not Flags then
    self.img_Tabbg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
end

function UMG_MagicManualSubPanel_C:InitManualTab()
  local tabList = {
    {
      TaskTypeName = LuaText.magic_manual_tab_name,
      Sort = self.data.ManualTaskType.NormalManual,
      RedPointKey = 434,
      TabType = 2
    },
    {
      TaskTypeName = LuaText.season_manual_tab_name,
      Sort = self.data.ManualTaskType.SeasonManual,
      RedPointKey = 433,
      TabType = 2
    }
  }
  self.img_Tabbg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.TabList1:InitGridView(tabList)
  local index = self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual and 1 or 2
  self.TabList1:SelectItemByIndex(index - 1)
end

function UMG_MagicManualSubPanel_C:SetChapterRewardState()
  if self.data.HasNextChatChapter then
    self.IsTakeNewChapterReward = true
  elseif self.data.IsTakeNewChapterReward then
    self.IsTakeNewChapterReward = true
  else
    self.IsTakeNewChapterReward = false
  end
end

function UMG_MagicManualSubPanel_C:UpdateManualTab(tabIndex, childTabIndex)
  local needSelectCatchHard = false
  if childTabIndex ~= self.module.ManaulChildIndex then
    if childTabIndex == self.data.ManualTaskType.NormalManual then
      self.module:CheckAndSetSelectRewardChapter()
    else
      local chapterList = self.data:GetSeasonChapterList()
      for i, v in ipairs(chapterList) do
        local hasRewardRedPoint = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.IsRedPointLightUp, 432, {
          v.chapterConfData.id
        })
        if hasRewardRedPoint and self.data.SeasonChapterData then
          self.data.SeasonChapterData.currSeasonChapterID = v.chapterConfData.id
          break
        end
      end
    end
    needSelectCatchHard = true
  end
  self.module.ManaulChildIndex = childTabIndex
  self:CloseComboBox()
  if childTabIndex == self.data.ManualTaskType.NormalManual then
    local taskPanelInfo = self.data:GetMagicManualTaskPanelInfo()
    self:SetMagicManualChapterInfo(taskPanelInfo, true)
  else
    local chapterData = self.data:GetCurrentChapterData()
    if not chapterData then
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OnOpenSeasonManualPanel, nil)
      return
    end
    self:SetPetBG()
    self:ShowSeasonRegion(needSelectCatchHard)
    self:SetChapterRewardList()
    self:SetChapterTaskProgress()
    self:SetInfo()
    _G.NRCAudioManager:PlaySound2DAuto(1324, "UMG_MagicManualSubPanel_C:UpdateManualTab")
  end
  self:OnPlayEnterAnim()
end

function UMG_MagicManualSubPanel_C:UpdateSeasonManualTask()
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    self:ShowSeasonRegion()
  end
  self:SetChapterRewardList()
  self:SetChapterTaskProgress()
  self:SetInfo()
end

function UMG_MagicManualSubPanel_C:OnPlayEnterAnim()
  if self:IsAnimationPlaying(self.Change) then
    return
  end
  self:PlayAnimation(self.Change)
  local num1 = self.List:GetItemCount()
  for i = 1, num1 do
    local item = self.List:GetItemByIndex(i - 1)
    item:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if 1 == i then
      item:PlayAnimation(item.In)
    else
      self:DelaySeconds(0.03 * (i - 1), function()
        item:PlayAnimation(item.In)
      end)
    end
  end
end

function UMG_MagicManualSubPanel_C:SetMagicManualChapterInfo(_TaskPanelInfo, SkipRefreshRegion)
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    return
  end
  self.TaskPanelInfo = _TaskPanelInfo
  self.ParagraphId = self.TaskPanelInfo.LeftPanelInfo and self.TaskPanelInfo.LeftPanelInfo.id
  self:SetChapterRewardState()
  self:SetPetBG()
  self:SetInfo()
  if SkipRefreshRegion then
  else
    local isOpen = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.GetSeasonInfo) and true or false
    local Flags = _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(Enum.PlayerStoryFlagEnum.PSF_FUNC_UNLOCK_SADV)
    self:ShowRegion(isOpen, Flags)
  end
  local ShowChapterlist, CurChapterSelect, CurState = self.data:GetShowChapter()
  if #ShowChapterlist >= 1 then
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CatchHardLv:InitGridView(ShowChapterlist)
    self.CatchHardLv:SelectItemByIndex(CurChapterSelect - 1)
  else
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetCompleteState(CurState)
end

function UMG_MagicManualSubPanel_C:OnUpdateRedPointData(point_data)
  local num1 = self.List:GetItemCount()
  for i = 1, num1 do
    local item = self.List:GetItemByIndex(i - 1)
    for _, v in pairs(point_data) do
      if tonumber(v) == item.data.PlayerTaskInfo.id then
        item.data.PlayerTaskInfo.state = ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT
        item.Switcher:SetActiveWidgetIndex(0)
        local condition = item.taskConf.task_condition[1]
        local num = condition.count
        item.Describe_1:SetText(string.format("%s/%s", num, num))
        break
      end
    end
  end
end

function UMG_MagicManualSubPanel_C:SetCommonComboBoxInfo(ComboBox, DropDownListInfo, DropDownListIndex)
  local CommonDropDownListData = {}
  if DropDownListInfo then
    CommonDropDownListData.DropDownListInfo = DropDownListInfo
  end
  if DropDownListIndex then
    CommonDropDownListData.DropDownListIndex = DropDownListIndex
  end
  CommonDropDownListData.Call = self
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_MagicManualSubPanel_C:ShowSeasonRegion(needSelectCatchHard)
  local chapterList = self.data:GetSeasonChapterList()
  local currChapterID = self.data:GetCurrSeasonShowChapterID()
  if chapterList and #chapterList > 0 then
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CatchHardLv:InitGridView(chapterList)
    if currChapterID then
      local currSelectIndex = 0
      local currChapterState = 0
      local currChapterConfData
      for _k, _v in pairs(chapterList) do
        if currChapterID == _v.chapterConfData.id then
          currChapterState = _v.state
          currChapterConfData = _v.chapterConfData
          break
        end
        currSelectIndex = currSelectIndex + 1
      end
      local selectIndex = self.CatchHardLv:GetSelectedIndex()
      if selectIndex ~= currSelectIndex or needSelectCatchHard then
        self.CatchHardLv:SelectItemByIndex(currSelectIndex)
      end
      self:SetCompleteState(currChapterState)
      if 0 == currSelectIndex then
        self.Button_0:SetIsEnabled(false)
        self.State:SetActiveWidgetIndex(0)
      else
        self.Button_0:SetIsEnabled(true)
        self.State:SetActiveWidgetIndex(1)
      end
      local isHasNextChapter = false
      if currChapterConfData and currChapterConfData.next_chapter then
        local chapterData = self.data:GetCurrentChapterData(currChapterConfData.next_chapter)
        if chapterData and chapterData.chapterState and chapterData.chapterState.status ~= ProtoEnum.PlayerSeasonAdventureChapterStatus.LOCK then
          isHasNextChapter = true
        end
      end
      if isHasNextChapter then
        self.Button:SetIsEnabled(true)
        self.State_1:SetActiveWidgetIndex(1)
      else
        self.Button:SetIsEnabled(false)
        self.State_1:SetActiveWidgetIndex(0)
      end
      if 0 == currSelectIndex and not isHasNextChapter then
        self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.State_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      local chapterNum = currChapterConfData and currChapterConfData.chapter_num or 1
      local ChapterText = self.data:TranslateCurChapterName(chapterNum)
      self.NRCText_0:SetText(ChapterText)
      local chapterName = currChapterConfData and currChapterConfData.chapter_name or ""
      self.NRCText_3:SetText(chapterName)
    end
  else
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManualSubPanel_C:SetCompleteState(state)
  if 2 == state then
    self.accomplish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_AllCompleted:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif 1 == state then
    self.accomplish:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text_AllCompleted:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.accomplish:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Text_AllCompleted:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManualSubPanel_C:ShowRegion(isOpen, Flags)
  local ShowRegionlist = {}
  if not isOpen or not Flags then
  else
    local ShowSeasonRegionlist = self.data:GetSeasonChapterData()
    if ShowSeasonRegionlist and ShowSeasonRegionlist.seasonManualConf then
      table.insert(ShowRegionlist, {
        IsSeason = true,
        name = LuaText.season_manual_tab_name,
        CurRegionSelect = 1,
        list = {
          {
            IsSeason = true,
            data = ShowSeasonRegionlist.seasonManualConf
          }
        }
      })
    end
  end
  local ShowNormalRegionlist, CurNormalRegionSelect = self.data:GetShowRegion()
  if #ShowNormalRegionlist > 0 then
    table.insert(ShowRegionlist, {
      IsSeason = false,
      name = LuaText.magic_manual_tab_name,
      CurRegionSelect = CurNormalRegionSelect,
      list = {data = ShowNormalRegionlist}
    })
  end
  local index = self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual and 1 or 2
  if #ShowRegionlist >= 1 then
    if 1 == #ShowRegionlist then
      index = 1
    end
    self:SetCommonComboBoxInfo(self.ComboBox, ShowRegionlist, index)
    if #ShowRegionlist > 1 or #ShowNormalRegionlist > 1 then
      self.Button_3:SetVisibility(UE4.ESlateVisibility.Visible)
      self.RedPoint:SetupKey(160)
    else
      self.RedPoint:SetupKey(0)
      self.Button_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.RedPoint:SetupKey(0)
    self.Button_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManualSubPanel_C:ShowChapter()
  local ShowChapterlist, CurChapterSelect, CurState = self.data:GetShowChapter()
  if #ShowChapterlist >= 1 then
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CatchHardLv:InitGridView(ShowChapterlist)
    self.CatchHardLv:SelectItemByIndex(CurChapterSelect - 1)
  else
    self.CatchHardLv:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MagicManualSubPanel_C:SetPetBG()
  local stamp_left = ""
  local chapter_story_name = ""
  local chapter_picture_title1 = ""
  local chapter_picture_title2 = ""
  local chapter_picture_tips = ""
  local chapter_picture = ""
  local chapter_story = ""
  local theme_color2 = ""
  local theme_color1 = ""
  local chapter_stamp = ""
  local theme_color3 = ""
  local comBoxBg = ""
  local comBoxItemBg = ""
  local comBoxItemSelectBg = ""
  local comBoxItemSeasonBg = ""
  local comBoxItemSeasonSelectBg = ""
  local comBoxTextSelect = "FFFFFFFF"
  local recall_id = 0
  local isShowShop = false
  local isShowMoneyBtn = false
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual and self.TaskPanelInfo.LeftPanelInfo then
    local regionData, curSelect = self.data:GetShowRegion()
    local ShowRegion = regionData[curSelect]
    local RegionConf = _G.DataConfigManager:GetRegionConf(ShowRegion.RegionId)
    stamp_left = self.TaskPanelInfo.LeftPanelInfo.stamp_left
    chapter_story_name = self.TaskPanelInfo.LeftPanelInfo.chapter_story_name or LuaText.chapter_story
    chapter_picture_title1 = RegionConf.magic_manual_switch_img1
    chapter_picture_title2 = self.TaskPanelInfo.LeftPanelInfo.chapter_picture_title2
    chapter_picture_tips = self.TaskPanelInfo.LeftPanelInfo.chapter_picture_tips
    chapter_picture = self.TaskPanelInfo.LeftPanelInfo.chapter_picture
    chapter_story = self.TaskPanelInfo.LeftPanelInfo.chapter_story
    theme_color2 = self.TaskPanelInfo.LeftPanelInfo.theme_color2
    theme_color1 = self.TaskPanelInfo.LeftPanelInfo.theme_color1
    chapter_stamp = self.TaskPanelInfo.LeftPanelInfo.chapter_stamp
    theme_color3 = self.TaskPanelInfo.LeftPanelInfo.theme_color3
    recall_id = self.TaskPanelInfo.LeftPanelInfo.reacall_id
    comBoxBg = RegionConf.magic_manual_switch_img2
    comBoxItemBg = RegionConf.magic_manual_switch_img6
    comBoxItemSelectBg = RegionConf.magic_manual_switch_img5
    comBoxItemSeasonBg = RegionConf.magic_manual_switch_img4
    comBoxItemSeasonSelectBg = RegionConf.magic_manual_switch_img3
    comBoxTextSelect = RegionConf.magic_manual_switch_text_color2
  else
    local seasonData = self.data:GetSeasonChapterData()
    local chapterData = self.data:GetCurrentChapterData()
    if chapterData and seasonData and seasonData.seasonUICfg and chapterData.chapterConfData then
      if chapterData.chapterConfData.chapter_type == ProtoEnum.SeasonAdventureChapterType.SACT_BADGE then
        stamp_left = seasonData.seasonUICfg.stamp_left_badge
      else
        stamp_left = seasonData.seasonUICfg.stamp_left
      end
      chapter_story_name = chapterData.chapterConfData.chapter_story_name or LuaText.chapter_story
      chapter_picture_title1 = seasonData.seasonUICfg.magic_manual_switch_img1
      chapter_picture_title2 = seasonData.seasonUICfg.chapter_picture_title2
      chapter_picture_tips = seasonData.seasonUICfg.chapter_picture_tips
      chapter_picture = chapterData.chapterConfData.chapter_picture
      chapter_story = chapterData.chapterConfData.chapter_story
      theme_color2 = seasonData.seasonUICfg.theme_color2
      theme_color1 = seasonData.seasonUICfg.theme_color1
      chapter_stamp = seasonData.seasonUICfg.chapter_stamp
      theme_color3 = seasonData.seasonUICfg.theme_color3
      recall_id = chapterData.chapterConfData.reacall_id
      comBoxBg = seasonData.seasonUICfg.magic_manual_switch_img2
      comBoxItemSeasonBg = seasonData.seasonUICfg.magic_manual_switch_img4
      comBoxItemSeasonSelectBg = seasonData.seasonUICfg.magic_manual_switch_img3
      comBoxItemBg = seasonData.seasonUICfg.magic_manual_switch_img6
      comBoxItemSelectBg = seasonData.seasonUICfg.magic_manual_switch_img5
      comBoxTextSelect = seasonData.seasonUICfg.magic_manual_switch_text_color2
      isShowShop = true
      isShowMoneyBtn = true
    end
  end
  self.ComboBox.ComboBox_Popup.Image_Bg:SetPath(comBoxBg)
  self.ComboBox:SetMagicManualComBoxItemBg(comBoxItemBg, comBoxItemSelectBg, comBoxItemSeasonBg, comBoxItemSeasonSelectBg, comBoxTextSelect)
  self.TitleBg:SetPath(chapter_picture_title1)
  self.BtnBg:SetPath(chapter_picture_title2)
  self.NRCImage_13:SetPath(chapter_picture_tips)
  self.NRCText_5:SetText(chapter_story_name)
  self.NRCImage_87:SetPath(chapter_picture)
  self.ContentText:SetText(chapter_story)
  self.Department:SetPath(stamp_left)
  self.PatternL1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(theme_color2))
  self.PatternL2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(theme_color1))
  self.PatternR1:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(theme_color2))
  self.PatternR2:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(theme_color1))
  self.PatternR3:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor(theme_color2))
  self.accomplish:SetPath(chapter_stamp)
  self.Text_AllCompleted:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(theme_color3))
  self.Text_AllCompleted:SetText(LuaText.magic_manual_all_completed)
  self.Describe_2:SetText(LuaText.magic_manual_season_badge_description)
  self.MoneyBtn:SetVisibility(isShowMoneyBtn and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.Btn_shopping:SetVisibility(isShowShop and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  if recall_id and 0 ~= recall_id then
    self.GetMorePetBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    local recallConf = _G.DataConfigManager:GetReacallConf(recall_id)
    if recallConf and self.GetMorePetBtn.NRCText_1 then
      self.GetMorePetBtn.NRCText_1:SetText(recallConf.reacall_title_name)
    end
    self.curRecallId = recall_id
  else
    self.curRecallId = nil
    self.GetMorePetBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

local function SortTask(a, b)
  if not a or not b then
    return
  end
  local a_taskState = a.PlayerTaskInfo.state
  local b_taskState = b.PlayerTaskInfo.state
  if a.IsHide then
    a_taskState = _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN
  end
  if b.IsHide then
    b_taskState = _G.ProtoEnum.EMTaskState.EM_TASK_STATE_OPEN
  end
  if a_taskState == b_taskState then
    if a.TaskConf.task_class == b.TaskConf.task_class then
      if not a.IsHide and b.IsHide then
        return true
      end
      if a.IsHide and not b.IsHide then
        return false
      end
      return a.PlayerTaskInfo.id > b.PlayerTaskInfo.id
    else
      return a.TaskConf.task_class < b.TaskConf.task_class
    end
  else
    local function GetState(State)
      if State == _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        return 3
      end
      if State < _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        return 2
      end
      if State > _G.ProtoEnum.EMTaskState.EM_TASK_STATE_WAIT then
        return 1
      end
    end
    
    local StateA = GetState(a_taskState)
    local StateB = GetState(b_taskState)
    return StateA > StateB
  end
end

function UMG_MagicManualSubPanel_C:PlayChapterBeginAnim()
  Log.Debug(self.module and self.module.cacheChapterBeginData and self.module.cacheChapterBeginData.id, "UMG_MagicManualSubPanel_C:PlayChapterBeginAnim")
  if self.module and self.module.cacheChapterBeginData and self.module.cacheChapterBeginData.id == self.TaskPanelInfo.LeftPanelInfo.id then
    local _Panel = self.module:HasPanel(self.module.cacheChapterBeginData.panelName)
    if not _Panel then
      self.module:OpenPanel(self.module.cacheChapterBeginData.panelName, self.module.cacheChapterBeginData)
    end
    self.module.cacheChapterBeginData = nil
    JsonUtils.DumpSaved(_ChapterBeginCacheFilename, {})
  elseif self.module then
    local CacheFile = JsonUtils.LoadSaved(_ChapterBeginCacheFilename, {}) or {}
    Log.Dump(CacheFile, 4, "UMG_MagicManualSubPanel_C:PlayChapterBeginAnim")
    if self.TaskPanelInfo.LeftPanelInfo and CacheFile and CacheFile.cache and CacheFile.cache.id and CacheFile.cache.id == self.TaskPanelInfo.LeftPanelInfo.id then
      local _Panel = self.module:HasPanel(CacheFile.cache.panelName)
      if not _Panel then
        self.module:OpenPanel(CacheFile.cache.panelName, CacheFile.cache)
      end
      JsonUtils.DumpSaved(_ChapterBeginCacheFilename, {})
    end
  end
end

function UMG_MagicManualSubPanel_C:SetInfo()
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
    if self.data.PreTaskInfo then
      if self.data.PreTaskInfo.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
        self:SetPretaskShowState(false)
        self:PlayChapterBeginAnim()
      else
        local CacheFile = JsonUtils.LoadSaved(_ChapterBeginCacheFilename, {}) or {}
        if self.module.cacheChapterBeginData then
          CacheFile.cache = self.module.cacheChapterBeginData
          JsonUtils.DumpSaved(_ChapterBeginCacheFilename, CacheFile)
        end
        self:SetPretaskShowState(true)
        self:SetPretaskUIShow(self.data.PreTaskInfo.id)
      end
    else
      self:PlayChapterBeginAnim()
      self:SetPretaskShowState(false)
    end
    self:SetRightPanelInfo(self.TaskPanelInfo.RightPanelInfo)
    self:SetLeftPanelInfo(self.TaskPanelInfo.LeftPanelInfo)
  else
    local taskList = {}
    local pretaskID
    local pretaskFinish = false
    local chapterData = self.data:GetCurrentChapterData()
    if chapterData and chapterData.chapterState then
      local doneTaskNum = 0
      local themeColor
      local seasonData = self.data:GetSeasonChapterData()
      if seasonData and seasonData.seasonUICfg then
        themeColor = seasonData.seasonUICfg.theme_color5
      end
      pretaskID = chapterData.chapterConfData.pre_task
      if pretaskID and 0 ~= pretaskID and chapterData.taskList then
        for _k, _v in pairs(chapterData.taskList) do
          if _v.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE and _v.id ~= pretaskID then
            doneTaskNum = doneTaskNum + 1
          end
        end
      else
        doneTaskNum = chapterData.chapterState.normal_progress
      end
      local needUnlockNum = chapterData.chapterConfData.pre_task_season_num or 0
      if chapterData.taskList then
        for _k, _v in pairs(chapterData.taskList) do
          local bHide = false
          for _kk, _vv in pairs(chapterData.chapterConfData.hide_tasks_season) do
            if _vv == _v.id and doneTaskNum < needUnlockNum then
              bHide = true
            end
          end
          if pretaskID and _v.id == pretaskID then
            if _v.state >= ProtoEnum.EMTaskState.EM_TASK_STATE_DONE then
              pretaskFinish = true
            end
          else
            local taskConf = _G.DataConfigManager:GetTaskConf(_v.id)
            if taskConf then
              table.insert(taskList, {
                PlayerTaskInfo = _v,
                TaskConf = taskConf,
                IsHide = bHide,
                DoneTaskNum = doneTaskNum,
                NeedUnlockNum = needUnlockNum,
                RedPointKey = 429,
                ThemeColor = themeColor
              })
            end
          end
        end
      end
    end
    if pretaskID and 0 ~= pretaskID and not pretaskFinish then
      self:SetPretaskShowState(true)
      self:SetPretaskUIShow(pretaskID)
    else
      self:SetPretaskShowState(false)
      if chapterData then
        self:CheckOpenSeasonChapterBeginPanel(chapterData.chapterConfData.id)
      end
    end
    table.sort(taskList, SortTask)
    self.List:InitList(taskList)
    self:ShowMoney()
  end
end

function UMG_MagicManualSubPanel_C:CheckOpenSeasonChapterBeginPanel(chapterID)
  local CacheFile = JsonUtils.LoadSaved(self.module.SeasonChapterBeginUIData, {}) or {}
  if CacheFile and CacheFile.id == chapterID then
    if not self.module:HasPanel(CacheFile.panelName) then
      self.module:OpenPanel(CacheFile.panelName, CacheFile)
    end
    JsonUtils.DumpSaved(self.module.SeasonChapterBeginUIData, {})
  end
end

function UMG_MagicManualSubPanel_C:SetPretaskUIShow(id)
  local TaskConf = _G.DataConfigManager:GetTaskConf(id)
  self.PreTaskConf = TaskConf
  self.go_guide = nil
  for i, v in pairs(self.PreTaskConf.go_guide) do
    if v.type and v.type == Enum.TaskGoActionType.TGAT_UI and v.text then
      self.go_guide = v
    end
  end
  local isSeasonManual = self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual
  self.Switcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if self.go_guide and self.go_guide.type and self.go_guide.type == Enum.TaskGoActionType.TGAT_UI and self.go_guide.text then
    self.Switcher_1:SetActiveWidgetIndex(1)
  else
    if isSeasonManual then
      self.Switcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Switcher_1:SetActiveWidgetIndex(2)
  end
  local describe = string.format(LuaText.Adventure_pre_task_tips, TaskConf.name)
  if isSeasonManual then
    describe = string.format(LuaText.magic_manual_season_pre_task_tips, TaskConf.name)
  end
  self.Describe_1:SetText(describe)
end

function UMG_MagicManualSubPanel_C:SetPretaskShowState(state)
  local preTaskState = state and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed
  local otherState = state and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.SelfHitTestInvisible
  self.PatternL1:SetVisibility(otherState)
  self.PatternL2:SetVisibility(otherState)
  self.PatternR1:SetVisibility(otherState)
  self.PatternR2:SetVisibility(otherState)
  self.PatternR3:SetVisibility(otherState)
  self.PreTask:SetVisibility(preTaskState)
  self.Ticket_1:SetVisibility(otherState)
  self.CanvasPanel_3:SetVisibility(otherState)
end

function UMG_MagicManualSubPanel_C:SetRightPanelInfo(_RightPanelInfo)
  if not _RightPanelInfo then
    return
  end
  local RightPanelInfo = _RightPanelInfo
  for i, _dataInfo in ipairs(RightPanelInfo) do
    _dataInfo.parent = self
  end
  table.sort(RightPanelInfo, SortTask)
  self.List:InitList(RightPanelInfo)
  self:SetChapterRewardList()
end

function UMG_MagicManualSubPanel_C:SetChapterRewardList()
  local RewardId = 0
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    local chapterData = self.data:GetCurrentChapterData()
    if chapterData then
      RewardId = chapterData.chapterConfData.rewards
      if chapterData.chapterConfData.chapter_type == ProtoEnum.SeasonAdventureChapterType.SACT_BADGE then
        self.SpecialChapter:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self:SetManualBadgeInfo()
      else
        self.SpecialChapter:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  else
    RewardId = self.TaskPanelInfo.LeftPanelInfo.rewards
    self.SpecialChapter:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not RewardId or 0 == RewardId then
    self.List_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  else
    self.List_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local RewardList = {}
  local RewardConf = _G.DataConfigManager:GetRewardConf(RewardId)
  if not RewardConf then
    return
  end
  local RewardItem = RewardConf.RewardItem
  for i, _RewardConf in ipairs(RewardItem) do
    if (_RewardConf.Type ~= _G.Enum.GoodsType.GT_CARD_ICON or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_SKIN or _RewardConf.Type ~= _G.Enum.Enum.GoodsType.GT_CARD_LABEL) and _RewardConf.Type ~= _G.Enum.GoodsType.GT_REWARD then
      table.insert(RewardList, _RewardConf)
    end
  end
  local rewardsTable = {}
  for k, v in ipairs(RewardList) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.itemNum = v.Count
    rewards.bShowNum = true
    rewards.bShowTip = true
    table.insert(rewardsTable, rewards)
  end
  self.List_1:InitGridView(rewardsTable)
end

function UMG_MagicManualSubPanel_C:OnComBoxClick()
  self.ComboBox:OnComboBtnClicked()
end

function UMG_MagicManualSubPanel_C:OnDescCloseClick()
  if self.DescId then
    self.curDescRecallId = 0
    self:PlayAnimation(self.Paper_Out)
    self.DescId = nil
  end
end

function UMG_MagicManualSubPanel_C:SetMagicManualDescBG(DescId)
  _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_MagicManual_C:SetMagicManualDescBG")
  if not DescId then
    if self.DescId then
      self:PlayAnimation(self.Paper_Out)
      self.DescId = nil
    end
  else
    self:CloseComboBox()
    if self.DescId and self.DescId ~= DescId then
      self:PlayAnimation(self.Paper_cut)
    elseif not self.DescId then
      self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      self:PlayAnimation(self.Paper_In)
    end
    self.DescId = DescId
    local DescNoteConf = _G.DataConfigManager:GetDescNoteConf(tonumber(DescId))
    if DescNoteConf then
      if DescNoteConf.picture then
        self.NRCImage_2:SetPath(DescNoteConf.picture)
      end
      self.NRCText:SetText(DescNoteConf.note)
      self.ContentText_1:SetText(DescNoteConf.desc)
      if DescNoteConf.reacall_id and 0 ~= DescNoteConf.reacall_id then
        self.GetMorePetBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
        self.curDescRecallId = DescNoteConf.reacall_id
        local recallConf = _G.DataConfigManager:GetReacallConf(DescNoteConf.reacall_id)
        if recallConf and self.GetMorePetBtn_1.NRCText_1 then
          self.GetMorePetBtn_1.NRCText_1:SetText(recallConf.reacall_title_name)
        end
      else
        self.curDescRecallId = nil
        self.GetMorePetBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_MagicManualSubPanel_C:SetLeftPanelInfo(_LeftPanelInfo)
  if not _LeftPanelInfo then
    return
  end
  local LeftPanelInfo = _LeftPanelInfo
  self:SetChapterTaskProgress()
  if LeftPanelInfo.id == self.data.StartChapter then
    self.Button_0:SetIsEnabled(false)
    self.State:SetActiveWidgetIndex(0)
  else
    self.Button_0:SetIsEnabled(true)
    self.State:SetActiveWidgetIndex(1)
  end
  if self.data.HasNextChatChapter then
    self.Button:SetIsEnabled(true)
    self.State_1:SetActiveWidgetIndex(1)
  else
    self.Button:SetIsEnabled(false)
    self.State_1:SetActiveWidgetIndex(0)
  end
  if LeftPanelInfo.id == self.data.StartChapter and not self.data.HasNextChatChapter then
    self.State:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.State_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.State:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local ChapterText = self.data:TranslateCurChapterName(LeftPanelInfo.chapter_num)
  self.data:SetCurChapterName(ChapterText)
  self.NRCText_0:SetText(ChapterText)
  self.NRCText_3:SetText(LeftPanelInfo.chapter_name)
end

function UMG_MagicManualSubPanel_C:SetManualBadgeInfo()
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    local badgeInfo = self.data:GetSeasonBadgeInfo()
    if badgeInfo and badgeInfo.badgeInfo and badgeInfo.badgeConfData then
      local info = badgeInfo.badgeInfo
      local level = badgeInfo.badgeConfData.level_num - 1
      self:UpdateBadgeIcon(badgeInfo.badgeConfData)
      if 0 == level then
        self.ProbabilityStarSwitcher:SetActiveWidgetIndex(0)
        self.Switcher_2:SetActiveWidgetIndex(0)
      else
        self.ProbabilityStarSwitcher:SetActiveWidgetIndex(1)
        local starList = {}
        for i = 1, 5 do
          local data = -1
          if i <= level then
            data = 1
          end
          table.insert(starList, {IsShow = data})
        end
        self.ProbabilityStarRating:InitGridView(starList)
      end
    end
  end
end

function UMG_MagicManualSubPanel_C:SetChapterTaskProgress()
  local CurDoneTaskCount = 0
  local TaskCount = 0
  local isRewarded = false
  local btnText = LuaText.TASK_TAKE
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual and self.TaskPanelInfo.RightPanelInfo then
    local CurDoneTaskConf = self.TaskPanelInfo.RightPanelInfo
    local DoneTaskCount = {}
    for i = 1, #CurDoneTaskConf do
      if CurDoneTaskConf[i].PlayerTaskInfo.state == ProtoEnum.EMTaskState.EM_TASK_STATE_DONE and CurDoneTaskConf[i].TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE then
        table.insert(DoneTaskCount, CurDoneTaskConf[i])
      end
      if CurDoneTaskConf[i].TaskConf.task_class == Enum.TaskClassType.TCT_ADVENTURE_CORE then
        TaskCount = TaskCount + 1
      end
    end
    CurDoneTaskCount = #DoneTaskCount
    self.Describe:SetText(LuaText.magic_manual_chapter_progress)
    isRewarded = self.IsTakeNewChapterReward
    self:SetMigcManualChapterRewardState(CurDoneTaskCount, TaskCount, isRewarded)
  else
    local chapterData = self.data:GetCurrentChapterData()
    if chapterData and chapterData.chapterConfData then
      local redPointKey = 430
      local rewardState = 0
      if chapterData.chapterConfData.chapter_type == ProtoEnum.SeasonAdventureChapterType.SACT_BADGE then
        local badgeInfo = self.data:GetSeasonBadgeInfo()
        if badgeInfo and badgeInfo.badgeInfo and badgeInfo.badgeConfData then
          if badgeInfo.badgeInfo.full_progress and badgeInfo.badgeInfo.full_progress > 0 then
            self.TargetProgress:SetPercent(badgeInfo.badgeInfo.cur_progress / badgeInfo.badgeInfo.full_progress)
            if not badgeInfo.badgeConfData.next_level or 0 == badgeInfo.badgeConfData.next_level then
              rewardState = badgeInfo.badgeInfo.cur_progress >= badgeInfo.badgeInfo.full_progress and 2 or 0
            else
              rewardState = badgeInfo.badgeInfo.cur_progress >= badgeInfo.badgeInfo.full_progress and 1 or 0
            end
          else
            self.TargetProgress:SetPercent(0)
          end
          btnText = badgeInfo.badgeConfData.button_text
          CurDoneTaskCount = badgeInfo.badgeInfo.cur_progress or 0
          TaskCount = badgeInfo.badgeInfo.full_progress or 0
          redPointKey = 431
        end
      else
        TaskCount = chapterData.chapterConfData.chapter_finish_task_num or 0
        if chapterData.chapterState then
          CurDoneTaskCount = chapterData.chapterState.normal_progress or 0
          isRewarded = chapterData.chapterState.status == ProtoEnum.PlayerSeasonAdventureChapterStatus.REWARED
          if isRewarded then
            rewardState = 2
          elseif TaskCount <= CurDoneTaskCount then
            rewardState = 1
          end
        end
        CurDoneTaskCount = math.min(CurDoneTaskCount, TaskCount)
        self.TargetProgress:SetPercent(CurDoneTaskCount / TaskCount)
      end
      self.Dot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Btn_1.RedDot:SetupKey(redPointKey, chapterData.chapterConfData.id)
      self.Describe:SetText(chapterData.chapterConfData.progress_text)
      self:SetSeasonMaualChapterRewardState(rewardState)
    end
  end
  self.Btn_1:SetBtnText(btnText)
  local CurChapterTaskCout = string.format(CurDoneTaskCount .. "/" .. TaskCount)
  self.NRCText_22:SetText(CurChapterTaskCout)
end

function UMG_MagicManualSubPanel_C:SetSeasonMaualChapterRewardState(rewardState)
  self.IsArrive = 1 == rewardState
  self:SetDoneState(2 == rewardState)
  self.P_reward:SetVisibility(1 == rewardState and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  self.P_reward:SetActivate(1 == rewardState)
  if 0 == rewardState then
    self.Switcher_2:SetActiveWidgetIndex(2)
  elseif 1 == rewardState then
    self.Switcher_2:SetActiveWidgetIndex(0)
  else
    self.Switcher_2:SetActiveWidgetIndex(3)
  end
end

function UMG_MagicManualSubPanel_C:SetMigcManualChapterRewardState(CurDoneTaskCount, TaskCount, isRewarded)
  self.IsArrive = false
  if CurDoneTaskCount < TaskCount then
    self:SetDoneState(false)
    self.P_reward:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.P_reward:SetActivate(false)
    self.Switcher_2:SetActiveWidgetIndex(2)
    self.Dot:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif CurDoneTaskCount == TaskCount then
    if isRewarded then
      self:SetDoneState(true)
      self.P_reward:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.P_reward:SetActivate(false)
      self.Dot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Switcher_2:SetActiveWidgetIndex(3)
    else
      self:SetDoneState(false)
      self.P_reward:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.P_reward:SetActivate(true)
      self.Switcher_2:SetActiveWidgetIndex(0)
      self.Dot:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.IsArrive = true
    end
  else
    Log.Warning("\230\128\142\228\185\136\229\143\175\232\131\189\229\164\167\228\186\142\239\188\140\229\135\186\233\151\174\233\162\152\228\186\134\229\144\167\239\188\140\232\128\129\229\188\159")
  end
end

function UMG_MagicManualSubPanel_C:OnDisable()
  self.DescId = nil
  self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnRemoveEventListener()
end

function UMG_MagicManualSubPanel_C:OnClickPreviousChapter()
  _G.NRCAudioManager:PlaySound2DAuto(1220002026, "UMG_MagicManual_C:OnClickPreviousChapter")
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
    local ShowChapterlist, CurChapterSelect = self.data:GetShowChapter()
    local CurChapterId = self.data.CurChapterId - 1
    for i, v in pairs(ShowChapterlist) do
      if v.id == CurChapterId then
        self.CatchHardLv:SelectItemByIndex(i - 1)
      end
    end
  else
    local CurChapterId = self.data:GetCurrSeasonShowChapterID()
    local count = self.CatchHardLv:GetItemCount()
    local selectIndex = 0
    for i = 1, count do
      local item = self.CatchHardLv:GetItemByIndex(i - 1)
      if item and item.uiData and item.uiData.chapterConfData and item.uiData.chapterConfData.id == CurChapterId then
        selectIndex = i - 1
      end
    end
    self.CatchHardLv:SelectItemByIndex(selectIndex - 1)
  end
end

function UMG_MagicManualSubPanel_C:SetBtnCanClick()
  local num1 = self.List:GetItemCount()
  for i = 1, num1 do
    local item = self.List:GetItemByIndex(i - 1)
    item:SetBtnCanClick()
  end
end

function UMG_MagicManualSubPanel_C:GetChapterReward()
  if self.IsArrive then
    self.IsArrive = false
    
    local function SetChapterState()
      self.P_reward:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.P_reward:SetActivate(false)
      self.Switcher_2:SetActiveWidgetIndex(3)
      self:SetDoneState(true)
    end
    
    if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
      self.Dot:SetVisibility(UE4.ESlateVisibility.Collapsed)
      SetChapterState()
      _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OnZoneChapterRewardReq, self.TaskPanelInfo.LeftPanelInfo.id)
    else
      local chapterData = self.data:GetCurrentChapterData()
      if chapterData and chapterData.chapterConfData then
        if chapterData.chapterConfData.chapter_type == ProtoEnum.SeasonAdventureChapterType.SACT_BADGE then
          self.module:OnReqSeasonManualBadgeUpgrade()
          local badgeInfo = self.data:GetSeasonBadgeInfo()
          if badgeInfo and badgeInfo.badgeConfData and badgeInfo.badgeConfData.next_level and 0 ~= badgeInfo.badgeConfData.next_level then
          else
            SetChapterState()
          end
        else
          SetChapterState()
          self.module:OnReqSeasonManualChapterReward(chapterData.chapterConfData.id)
        end
      end
    end
    _G.NRCAudioManager:PlaySound2DAuto(40008039, "UMG_MagicManual_C:GetChapterReward")
  else
    Log.Warning("\232\191\152\230\156\170\232\190\190\229\136\176\230\157\161\228\187\182\230\136\150\232\128\133\229\183\178\231\187\143\233\162\134\229\143\150\228\186\134\229\147\159")
  end
end

function UMG_MagicManualSubPanel_C:SetDoneState(IsDone)
  local num = self.List_1:GetItemCount()
  for i = 1, num do
    local item = self.List_1:GetItemByIndex(i - 1)
    if item then
      item:SetAlreadyReceived(IsDone)
    end
  end
end

function UMG_MagicManualSubPanel_C:UpdateSeasonManualBadge()
  self:SetChapterRewardList()
  self:SetChapterTaskProgress()
  self:PerformBadgeUpgrade()
end

function UMG_MagicManualSubPanel_C:OnAnimationFinished(anim)
  if anim == self.Reward_get then
    self.P_reward:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.P_reward:SetActivate(false)
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.OnZoneChapterRewardReq, self.TaskPanelInfo.LeftPanelInfo.id)
  elseif anim == self.Paper_Out then
    self.CanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif anim == self.Change_0to1 or anim == self.Change_1to5 or anim == self.Change_5to6 then
    self:UpdateBadgePersistentPerform()
  end
end

function UMG_MagicManualSubPanel_C:OnClickNextChapter()
  _G.NRCAudioManager:PlaySound2DAuto(1220002026, "UMG_MagicManual_C:OnClickNextChapter")
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
    local ShowChapterlist, CurChapterSelect = self.data:GetShowChapter()
    local CurChapterId = self.data.CurChapterId + 1
    for i, v in pairs(ShowChapterlist) do
      if v.id == CurChapterId then
        self.CatchHardLv:SelectItemByIndex(i - 1)
      end
    end
  else
    local CurChapterId = self.data:GetCurrSeasonShowChapterID()
    local count = self.CatchHardLv:GetItemCount()
    local selectIndex = 0
    for i = 1, count do
      local item = self.CatchHardLv:GetItemByIndex(i - 1)
      if item and item.uiData and item.uiData.chapterConfData and item.uiData.chapterConfData.id == CurChapterId then
        selectIndex = i - 1
      end
    end
    self.CatchHardLv:SelectItemByIndex(selectIndex + 1)
  end
end

function UMG_MagicManualSubPanel_C:OnMagicManualKnowBtn()
  if self.module.ManaulChildIndex == self.data.ManualTaskType.NormalManual then
    self:OnOpenLongDialog(LuaText.magicbook_manual)
  else
    local content = self.data:GetSeasonChapterData()
    if content and content.seasonManualConf then
      self:OnOpenLongDialog(LuaText[content.seasonManualConf.tips_id])
    end
  end
end

function UMG_MagicManualSubPanel_C:OnShoppingBtnClicked()
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    local conf = self.data:GetSeasonChapterData()
    if conf and conf.seasonManualConf then
      _G.NRCModuleManager:DoCmd(_G.NPCShopUIModuleCmd.OpenShopById, conf.seasonManualConf.shop_id)
    end
  end
end

function UMG_MagicManualSubPanel_C:ShowMoney()
  self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Btn_shopping:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    local conf = self.data:GetSeasonChapterData()
    if not conf or not conf.seasonManualConf then
      return
    end
    local shopID = conf.seasonManualConf.shop_id
    local showType = _G.DataConfigManager:GetShopConf(shopID)
    if not showType then
      return
    end
    local showTypeNum = #showType.goods
    local ShowSumMoneyInfo = {}
    local sumMoneyNum
    for i = 1, showTypeNum do
      sumMoneyNum = NPCShopUtils:GetGoodsCurrencyNumByType(showType.goods[i].goods_type, showType.goods[i].goods_id) or 0
      local IsShowBuyIcon = false
      if showType.goods[i].goods_type == _G.Enum.GoodsType.GT_VITEM then
        local visualItemConf = _G.DataConfigManager:GetVisualItemConf(showType.goods[i].goods_id)
        if visualItemConf and visualItemConf.exchange_id and 0 ~= visualItemConf.exchange_id then
          IsShowBuyIcon = true
        end
        table.insert(ShowSumMoneyInfo, {
          currencyType = showType.goods[i].goods_type,
          currencyId = showType.goods[i].goods_id,
          moneyType = showType.goods[i].goods_id,
          sum = sumMoneyNum,
          showColor = 0,
          showbg = true,
          bigIcon = true,
          IsShowBuyIcon = IsShowBuyIcon
        })
      elseif showType.goods[i].goods_type == _G.Enum.GoodsType.GT_BAGITEM then
        table.insert(ShowSumMoneyInfo, {
          currencyType = showType.goods[i].goods_type,
          currencyId = showType.goods[i].goods_id,
          sum = sumMoneyNum,
          showColor = 0,
          showbg = true,
          bigIcon = true,
          IsShowBuyIcon = IsShowBuyIcon
        })
      end
    end
    self.MoneyBtn:InitGridView(ShowSumMoneyInfo)
    self.MoneyBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_shopping:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_MagicManualSubPanel_C:OnOpenLongDialog(Content)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = LuaText.magicmanualmoduledata_1
  if self.module.ManaulChildIndex == self.data.ManualTaskType.SeasonManual then
    title = LuaText.season_manual_title
  end
  Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_MagicManualSubPanel_C:TracePreTask()
  MagicManualUtils.TaskTraceByGoGuide(self.go_guide)
end

function UMG_MagicManualSubPanel_C:OnAddEventListener()
  if self.IsAddButtonListener then
    return
  end
  self.IsAddButtonListener = true
  self:AddButtonListener(self.CloseBtn_1.btnClose, self.OnDescCloseClick)
  self:AddButtonListener(self.Button_3, self.OnComBoxClick)
  self:AddButtonListener(self.DescCloseBtn, self.OnDescCloseClick)
  self:AddButtonListener(self.Btn_1.btnLevelUp, self.GetChapterReward)
  self:AddButtonListener(self.Button_0, self.OnClickPreviousChapter)
  self:AddButtonListener(self.Button, self.OnClickNextChapter)
  self:AddButtonListener(self.MagicManualKnowBtn.btnLevelUp, self.OnMagicManualKnowBtn)
  self:AddButtonListener(self.TraceBtn.btnLevelUp, self.TracePreTask)
  self:AddButtonListener(self.CloseBtn_Global, self.CloseComboBox)
  self:AddButtonListener(self.BadgeBtn, self.OnBadgeBtnClicked)
  self:AddButtonListener(self.Btn_shopping.btnLevelUp, self.OnShoppingBtnClicked)
  self:AddButtonListener(self.GetMorePetBtn.GetMorePetBtn, self.OnChapterGoToRecallPanelButtonClicked)
  self:AddButtonListener(self.GetMorePetBtn_1.GetMorePetBtn, self.OnDescNoteGoToRecallPanelButtonClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_MagicManualSubPanel_C:OnAddEventListener", self, MagicManualModuleEvent.OnRecallButtonAnimFinished, self.OnRecallButtonAnimFinished)
  self.GetMorePetBtn:PlayAnimation(self.GetMorePetBtn.Loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self.GetMorePetBtn_1:PlayAnimation(self.GetMorePetBtn_1.Loop, 0.0, 0, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UMG_MagicManualSubPanel_C:OnRemoveEventListener()
  self.IsAddButtonListener = false
  self:RemoveButtonListener(self.CloseBtn_1.btnClose)
  self:RemoveButtonListener(self.Button_3)
  self:RemoveButtonListener(self.DescCloseBtn)
  self:RemoveButtonListener(self.Btn_1.btnLevelUp)
  self:RemoveButtonListener(self.Button_0)
  self:RemoveButtonListener(self.Button)
  self:RemoveButtonListener(self.MagicManualKnowBtn.btnLevelUp)
  self:RemoveButtonListener(self.TraceBtn.btnLevelUp)
  self:RemoveButtonListener(self.CloseBtn_Global)
  self:RemoveButtonListener(self.BadgeBtn)
  self:RemoveButtonListener(self.GetMorePetBtn.GetMorePetBtn)
  self:RemoveButtonListener(self.GetMorePetBtn_1.GetMorePetBtn)
  self:RemoveButtonListener(self.Btn_shopping.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicManualModuleEvent.OnRecallButtonAnimFinished, self.OnRecallButtonAnimFinished)
end

function UMG_MagicManualSubPanel_C:CloseComboBox()
  self.ComboBox:SetPopupVisible(false)
end

function UMG_MagicManualSubPanel_C:SetGlobalBtn(bShow)
  self.CloseBtn_Global:SetVisibility(bShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if bShow then
    if self.State_2 then
      self.State_2:SetRenderScale(UE4.FVector2D(-1, -1))
    end
    self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.GetMorePetBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    if self.State_2 then
      self.State_2:SetRenderScale(UE4.FVector2D(1, 1))
    end
    self.CanvasPanel_4:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.curRecallId and 0 ~= self.curRecallId then
      self.GetMorePetBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    end
  end
end

function UMG_MagicManualSubPanel_C:OnRecallTaskChecked(bSuccess, recallId)
  if not recallId or 0 == recallId then
    Log.Error("OnRecallTaskChecked: recallId \230\151\160\230\149\136")
    return
  end
  if bSuccess then
    self.bCanOpenRecall = true
    self.needToOpenRecallId = recallId
    Log.Info(string.format("recallId:%s \228\187\187\229\138\161\231\138\182\230\128\129\232\175\183\230\177\130\230\136\144\229\138\159\239\188\140\229\135\134\229\164\135\230\137\147\229\188\128\229\155\158\230\131\179\231\149\140\233\157\162", recallId))
    if self.bCanOpenRecall and self.bBtnAnimFinished then
      self:EnterRecallPanel()
    end
  else
    Log.Error(string.format("\229\189\147\229\137\141recallId:%s\232\175\183\230\177\130\228\187\187\229\138\161\231\138\182\230\128\129\229\164\177\232\180\165\239\188\129\229\155\158\230\131\179\231\149\140\233\157\162\230\137\147\229\188\128\230\181\129\231\168\139\228\184\173\230\150\173", recallId))
  end
end

function UMG_MagicManualSubPanel_C:_RequestRecallTask(recallId, context)
  self.bCanOpenRecall = false
  if recallId and 0 ~= recallId then
    self.needToOpenRecallId = recallId
    _G.NRCModuleManager:DoCmd(_G.MagicManualModuleCmd.GetRecallRelatedTaskStateReq, recallId)
  else
    Log.Warning(string.format("\229\189\147\229\137\141\230\178\161\230\156\137\229\175\185\229\186\148\231\154\132%s recall\230\140\137\233\146\174\228\184\138\228\184\139\230\150\135\239\188\140\232\191\153\228\184\170\230\140\137\233\146\174\228\184\141\229\186\148\232\175\165\230\152\190\231\164\186\228\184\148\232\162\171\231\130\185\229\135\187\239\188\140\230\156\137\233\151\174\233\162\152\239\188\129", context))
  end
end

function UMG_MagicManualSubPanel_C:OnChapterGoToRecallPanelButtonClicked()
  self.bBtnAnimFinished = false
  self.GetMorePetBtn:PlayAnimation(self.GetMorePetBtn.Press)
  self:_RequestRecallTask(self.curRecallId, "\231\171\160\232\138\130")
end

function UMG_MagicManualSubPanel_C:OnDescNoteGoToRecallPanelButtonClicked()
  self.bBtnAnimFinished = false
  self.GetMorePetBtn_1:PlayAnimation(self.GetMorePetBtn_1.Press)
  self:_RequestRecallTask(self.curDescRecallId, "\232\182\133\233\147\190\230\142\165")
end

function UMG_MagicManualSubPanel_C:OnBadgeBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(40008039, "UMG_MagicManualSubPanel_C:OnBadgeBtnClicked")
  _G.NRCModuleManager:DoCmd(MagicManualModuleCmd.OnOpenSeasonBadgePanel)
end

function UMG_MagicManualSubPanel_C:OnRecallButtonAnimFinished()
  self.bBtnAnimFinished = true
  if self.bBtnAnimFinished and self.bCanOpenRecall then
    self:EnterRecallPanel()
  end
end

function UMG_MagicManualSubPanel_C:EnterRecallPanel()
  _G.NRCModuleManager:GetModule("MagicManualModule"):DispatchEvent(MagicManualModuleEvent.UpdateTableView, 6, nil, self.needToOpenRecallId, self)
end

function UMG_MagicManualSubPanel_C:UpdateBadgeIcon(badgeConfData)
  if not badgeConfData then
    return
  end
  local currentBadgeLevel = badgeConfData.level_num - 1
  local iconPath = badgeConfData.badge_icon
  if currentBadgeLevel <= 0 then
    self.BadgeIcon:SetPath(iconPath)
  elseif currentBadgeLevel > 0 and currentBadgeLevel < 5 then
    self.BadgeIcon2_1:SetPath(iconPath)
  elseif currentBadgeLevel >= 5 then
    self.BadgeIcon3:SetPath(iconPath)
  end
  self:UpdateBadgePersistentPerform()
end

function UMG_MagicManualSubPanel_C:UpdateBadgePersistentPerform()
  if self:IsAnimationPlaying(self.Change_0to1) or self:IsAnimationPlaying(self.Change_1to5) or self:IsAnimationPlaying(self.Change_5to6) then
    return
  end
  local badgeInfo = self.data:GetSeasonBadgeInfo()
  if badgeInfo and badgeInfo.badgeConfData then
    local currentBadgeLevel = badgeInfo.badgeConfData.level_num - 1
    if currentBadgeLevel <= 0 then
      self.BadgeIcon:SetRenderOpacity(1)
      self.BadgeIcon2_1:SetRenderOpacity(0)
      self.BadgeIcon3:SetRenderOpacity(0)
    elseif currentBadgeLevel > 0 and currentBadgeLevel < 5 then
      self.BadgeIcon:SetRenderOpacity(0)
      self.BadgeIcon2_1:SetRenderOpacity(1)
      self.BadgeIcon3:SetRenderOpacity(0)
    elseif currentBadgeLevel >= 5 then
      self.BadgeIcon:SetRenderOpacity(0)
      self.BadgeIcon2_1:SetRenderOpacity(0)
      self.BadgeIcon3:SetRenderOpacity(1)
    end
    self.BadgeIcon_1:SetRenderOpacity(0)
    self.BadgeIcon2:SetRenderOpacity(0)
    self.BadgeIcon2_2:SetRenderOpacity(0)
    self.BadgeIcon3_1:SetRenderOpacity(0)
    self.BadgeIcon3_2:SetRenderOpacity(0)
  end
end

function UMG_MagicManualSubPanel_C:PerformBadgeUpgrade()
  self:StopAnimation(self.Change_0to1)
  self:StopAnimation(self.Change_1to5)
  self:StopAnimation(self.Change_5to6)
  local badgeInfo = self.data:GetSeasonBadgeInfo()
  if badgeInfo and badgeInfo.badgeConfData then
    local badgeConfData = badgeInfo.badgeConfData
    local currentBadgeLevel = badgeConfData.level_num - 1
    if 1 == currentBadgeLevel then
      local material_1 = self.BadgeIcon_1:GetDynamicMaterial()
      if material_1 and badgeConfData.badge_icon_noedge then
        material_1:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_noedge)
      end
      self:PlayAnimation(self.Change_0to1)
    elseif currentBadgeLevel > 1 and currentBadgeLevel < 5 then
      local material2 = self.BadgeIcon2:GetDynamicMaterial()
      if material2 and badgeConfData.badge_icon_noedge then
        material2:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_noedge)
      end
      local material2_2 = self.BadgeIcon2_2:GetDynamicMaterial()
      if material2_2 and badgeConfData.badge_icon_noedge then
        material2_2:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_mask)
      end
      self:PlayAnimation(self.Change_1to5)
    elseif currentBadgeLevel >= 5 then
      local material2_2 = self.BadgeIcon2_2:GetDynamicMaterial()
      if material2_2 and badgeConfData.badge_icon_noedge then
        material2_2:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_mask)
      end
      local material3_1 = self.BadgeIcon3_1:GetDynamicMaterial()
      if material3_1 and badgeConfData.badge_icon_noedge then
        material3_1:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_noedge2)
      end
      local material3_2 = self.BadgeIcon3_2:GetDynamicMaterial()
      if material3_2 and badgeConfData.badge_icon_noedge then
        material3_2:SetTextureParameterValue("Maintex", badgeConfData.badge_icon_noedge)
      end
      self:PlayAnimation(self.Change_5to6)
    end
  end
end

return UMG_MagicManualSubPanel_C
