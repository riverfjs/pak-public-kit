local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_Handbook_Subject_C = _G.NRCPanelBase:Extend("UMG_Handbook_Subject_C")

function UMG_Handbook_Subject_C:OnConstruct()
  self.uiData = {}
  self:SetChildViews(self.PopUp2)
  self:OnAddEventListener()
  self:RefreshCacheLeftHandbookList()
end

function UMG_Handbook_Subject_C:RefreshCacheLeftHandbookList()
  local sourceList
  if self.module and self.module.HasPanel and self.module:HasPanel("HandbookMain") then
    local handbookPanel = self.module:GetPanel("HandbookMain")
    if handbookPanel and handbookPanel.curListDatas then
      sourceList = handbookPanel.curListDatas
    end
  end
  if not sourceList and self.module and self.module.data and self.module.data.CacheLeftHandbookList then
    sourceList = self.module.data.CacheLeftHandbookList
  end
  self.CacheLeftHandbookList = sourceList or {}
end

function UMG_Handbook_Subject_C:OnActive(petBookInfo, pet_base_id)
  self:RefreshCacheLeftHandbookList()
  self:SetCommonPopUpInfo()
  self:OnUpdateMoney()
  self:SetBtnArrow()
  self:OnUpdateData(petBookInfo, pet_base_id)
  self:LoadAnimation(0)
end

function UMG_Handbook_Subject_C:OnUpdateData(petBookInfo, pet_base_id)
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  if not petBookInfo then
    self:DoClose()
    return
  end
  _G.NRCModuleManager:DoCmd(_G.TeachingManualModuleCmd.OnZoneUnlockTeachConditionReq, ProtoEnum.TeachClientTrigger.CT_PET_ALBUM_TASK)
  self:AddPcInputBlock()
  _G.NRCAudioManager:PlaySound2DAuto(41400007, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  self.uiData.petBookInfo = petBookInfo
  self.uiData.record = self.module.data:GetPetHandBookRecordData(petBookInfo.HandbookId, pet_base_id)
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 2, 1)
  local handbookData = _G.NRCModuleManager:GetModule("HandbookModule").data
  if handbookData and handbookData.CurHandbookAreaId then
    local areaConf = _G.DataConfigManager:GetAreaHandbook(handbookData.CurHandbookAreaId)
    if areaConf and areaConf.area_handbook_type then
      self.Btn_OneClickClaim.RedDot:SetupKey(redId, tostring(areaConf.area_handbook_type))
    end
  end
  self.pet_base_id = pet_base_id
  self.handbookId = petBookInfo.HandbookId
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1361, "UMG_Handbook_Subject_C:OnActive")
  self:UpdateUI()
  self:SetPageBtnVisible()
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").PROJECTTASK)
end

function UMG_Handbook_Subject_C:OnUpdateMoney()
  local moneyCount = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_TOPIC_POINT)
  local MoneyDatas = {
    {
      moneyType = _G.Enum.VisualItem.VI_TOPIC_POINT,
      sum = moneyCount
    }
  }
  self.MoneyBtn:InitGridView({
    MoneyDatas[1]
  })
end

function UMG_Handbook_Subject_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnUpdateMoney)
  self:RemovePcInputBlock()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1358, "UMG_Handbook_Subject_C:OnDeactive")
end

function UMG_Handbook_Subject_C:AddPcInputBlock()
end

function UMG_Handbook_Subject_C:RemovePcInputBlock()
end

function UMG_Handbook_Subject_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_OneClickClaim.btnLevelUp, self.OnGetAllAward)
  _G.NRCEventCenter:RegisterEvent("UMG_Handbook_Subject_C", self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnUpdateMoney)
end

function UMG_Handbook_Subject_C:OnPcClose()
  self:OnCloseBtn()
end

function UMG_Handbook_Subject_C:SetItemPosition(number)
  local itemStart_X = 92
  local itemEnd_X = 1032
  if 4 == number then
    itemStart_X = 191.5
    itemEnd_X = 932.0
  elseif 5 == number then
    itemStart_X = 108.5
    itemEnd_X = 1016.0
  end
  local totalLength = itemEnd_X - itemStart_X
  local itemDistance = totalLength / (number - 1)
end

function UMG_Handbook_Subject_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnCloseBtn
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
  self.PopUp2:SetTitleTextInfo()
end

function UMG_Handbook_Subject_C:SetBtnArrow()
  local CommonBtnArrowData1 = {}
  CommonBtnArrowData1.Call = self
  CommonBtnArrowData1.btnHandler = self.OnNextBtnClick
  CommonBtnArrowData1.modeIndex = 2
  self.Btn1:SetBtnInfo(CommonBtnArrowData1)
  local CommonBtnArrowData2 = {}
  CommonBtnArrowData2.Call = self
  CommonBtnArrowData2.btnHandler = self.OnPreviousBtnClick
  CommonBtnArrowData2.modeIndex = 1
  self.Btn2:SetBtnInfo(CommonBtnArrowData2)
end

function UMG_Handbook_Subject_C:GetCurBookIndexInCacheList()
  local curBookIndex = 0
  if self.CacheLeftHandbookList and self.uiData and self.uiData.petBookInfo then
    for i, v in ipairs(self.CacheLeftHandbookList) do
      if v.HandbookId == self.uiData.petBookInfo.HandbookId then
        curBookIndex = i
        break
      end
    end
  end
  return curBookIndex
end

function UMG_Handbook_Subject_C:OnPreviousBtnClick()
  local curBookIndex = self:GetCurBookIndexInCacheList()
  local preIndex, isPre = self:ComputeHandbookIndex(curBookIndex, false)
  if isPre then
    local preBookData = self.CacheLeftHandbookList[preIndex]
    if preBookData then
      self:DispatchEvent(HandbookModuleEvent.OnTopicTurnPage, preIndex, preBookData.HandbookId, preBookData.PetBaseId)
    end
  end
  self:SetPageBtnVisible()
end

function UMG_Handbook_Subject_C:OnNextBtnClick()
  local curBookIndex = self:GetCurBookIndexInCacheList()
  local nextIndex, isNext = self:ComputeHandbookIndex(curBookIndex, true)
  if isNext then
    local nextBookData = self.CacheLeftHandbookList[nextIndex]
    if nextBookData then
      self:DispatchEvent(HandbookModuleEvent.OnTopicTurnPage, nextIndex, nextBookData.HandbookId, nextBookData.PetBaseId)
    end
  end
  self:SetPageBtnVisible()
end

function UMG_Handbook_Subject_C:SetPageBtnVisible()
  local curBookIndex = self:GetCurBookIndexInCacheList()
  local curLeftListDatas = self.CacheLeftHandbookList
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 1, 2)
  local nextIndex, isNext = self:ComputeHandbookIndex(curBookIndex, true)
  local preIndex, isPre = self:ComputeHandbookIndex(curBookIndex, false)
  if false == isPre then
    self.Btn2:ShowOrHideBtnArrow(false)
    self.PopUp2:ShowOrHideBtnLeft(false)
  else
    self.PopUp2:ShowOrHideBtnLeft(false)
    self.Btn2:ShowOrHideBtnArrow(true)
    local bookId = curLeftListDatas[preIndex].HandbookId
    local iconPath = curLeftListDatas[preIndex].IconPath
    self.Btn2:SetBtnIcon(1, iconPath)
    self.Btn2.RedDot:SetupKey(redId, {
      tostring(bookId)
    })
  end
  if false == isNext then
    self.Btn1:ShowOrHideBtnArrow(false)
    self.PopUp2:ShowOrHideBtnRight(false)
  else
    self.PopUp2:ShowOrHideBtnRight(false)
    self.Btn1:ShowOrHideBtnArrow(true)
    local bookId = curLeftListDatas[nextIndex].HandbookId
    local iconPath = curLeftListDatas[nextIndex].IconPath
    self.Btn1:SetBtnIcon(1, iconPath)
    self.Btn1.RedDot:SetupKey(redId, {
      tostring(bookId)
    })
  end
end

function UMG_Handbook_Subject_C:ComputeHandbookIndex(curIndex, isNext)
  local curBookIndex = curIndex
  local curLeftListDatas = self.CacheLeftHandbookList
  if not curLeftListDatas then
    return 0, false
  end
  local nextIndex = isNext and curBookIndex + 1 or curBookIndex - 1
  if nextIndex < 1 or nextIndex > #curLeftListDatas then
    return 0, false
  end
  local nextState = curLeftListDatas[nextIndex].State
  if nextState ~= _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    return self:ComputeHandbookIndex(nextIndex, isNext)
  end
  return nextIndex, true
end

function UMG_Handbook_Subject_C:IsAllTopicAward(curIndex, isNext)
  local curLeftListDatas = self.CacheLeftHandbookList
  if isNext then
    if #curLeftListDatas >= curIndex + 1 then
      for i = curIndex + 1, #curLeftListDatas do
        local handbookId = curLeftListDatas[i].HandbookId
        local handbookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, handbookId)
        local Collection = handbookData.Collection
        local isAward = false
        if Collection then
          isAward = self:IsTopicAward(handbookData.HandBookConf, Collection.topic_list)
        end
        if isAward then
          return true
        end
      end
    end
  elseif #curLeftListDatas > 1 then
    for i = 1, curIndex - 1 do
      local handbookId = curLeftListDatas[i].HandbookId
      local handbookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, handbookId)
      local Collection = handbookData.Collection
      local isAward = false
      if Collection then
        isAward = self:IsTopicAward(handbookData.HandBookConf, Collection.topic_list)
      end
      if isAward then
        return true
      end
    end
  end
  return false
end

function UMG_Handbook_Subject_C:IsTopicAward(handbookConf, topic_list)
  local isAward = false
  local pet_topics = handbookConf.pet_topic
  if not pet_topics then
    return false
  end
  for i = 1, #pet_topics do
    local max_cnt = 0
    local finish_cnt = 0
    local isReceive = false
    if pet_topics and i <= #pet_topics then
      max_cnt = pet_topics[i].topic_cnt
    end
    if topic_list and i <= #topic_list then
      finish_cnt = topic_list[i].finish_cnt
    end
    isReceive = self.module.data:GetHandbookTopicAwardState(handbookConf.id, pet_topics.topic_Id)
    if max_cnt <= finish_cnt and not isReceive then
      isAward = true
      break
    end
  end
  return isAward
end

function UMG_Handbook_Subject_C:OnCloseBtn()
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_Plane_ExchangeVisits_C:OnActive")
  self:LoadAnimation(2)
end

function UMG_Handbook_Subject_C:OnRewardBtnClick()
  local complete_node_num = self.uiData.petBookInfo.Collection.complete_node_num
  local tot_node_num = self.uiData.petBookInfo.Collection.tot_node_num or 0
  local topic_list = self.uiData.petBookInfo.Collection.topic_list
  local isCanGetAward = true
  for i = 1, #topic_list do
    if topic_list[i].get_award == false then
      isCanGetAward = false
      break
    end
  end
  if false == isCanGetAward and complete_node_num >= tot_node_num then
    _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetHandbookTopicAward, self.uiData.petBookInfo.HandbookId)
  else
    local petBookCfg = self.uiData.petBookCfg
    local itemType = petBookCfg.reward_type
    local itemId = petBookCfg.reward_id
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenItemTips, itemId, itemType, false)
  end
end

function UMG_Handbook_Subject_C:OnAnimationFinished(Animation)
  if Animation == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

function UMG_Handbook_Subject_C:OnHandBookChanged(HandbookId)
  self:UpdateUI()
end

function UMG_Handbook_Subject_C:UpdateUI()
  local petBookCfg = _G.DataConfigManager:GetPetHandbook(self.uiData.petBookInfo.HandbookId)
  self.uiData.petBookCfg = petBookCfg
  local state = _G.Enum.PetHandbookStatus.PHS_NOT_FOUND
  if self.uiData.petBookInfo.Collection then
    state = self.uiData.petBookInfo.Collection.status
  end
  local path = ""
  if self.uiData.record == nil then
    if petBookCfg then
      local baseId = petBookCfg.include_petbase_id[1].petbase_id[1]
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      path = modelConf.icon
    end
  else
    path = self.uiData.record.HandbookPetIcon.icon
  end
  local iconPath = NRCUtils:FormatConfIconPath(path, _G.UIIconPath.HeadIconPath)
  self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.SubjectList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if state == _G.Enum.PetHandbookStatus.PHS_FOUND then
    self.Switcher_1:SetActiveWidgetIndex(1)
    self.Title:SetText(petBookCfg.name .. LuaText.umg_handbook_subject_1)
    self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.NRCpetIcon:SetPath(iconPath)
  elseif state == _G.Enum.PetHandbookStatus.PHS_COLLECTED then
    self.SubjectList:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Switcher_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Title:SetText(petBookCfg.name .. LuaText.umg_handbook_subject_1)
    self.NRCpetIcon:SetPath(iconPath)
    self.NRCpetIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self:SetupSubjects()
  else
    self.Switcher_1:SetActiveWidgetIndex(0)
    self.Title:SetText(LuaText.umg_handbook_subject_2)
    self.QuestionMark:SetVisibility(UE4.ESlateVisibility.Visible)
    self.QuestionMark:SetPath(iconPath)
    self.QuestionMark:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#000000"))
    self.QuestionMark:SetOpacity(0.4)
  end
end

function UMG_Handbook_Subject_C:SetupSubjects()
  local topic_list = self.uiData.petBookInfo.Collection.topic_list
  local petBookCfg = self.uiData.petBookCfg
  local pet_topic = petBookCfg.pet_topic
  local isGetAll = false
  local topicListData = {}
  for i, v in ipairs(pet_topic) do
    local finish_cnt = 0
    for j, topicInfo in pairs(topic_list) do
      if topicInfo.topic_id == v.topic_Id then
        finish_cnt = topicInfo.finish_cnt
        break
      end
    end
    local max_cnt = v.topic_cnt
    local reward_id = v.topic_reward
    local is_getaward = self.module.data:GetHandbookTopicAwardState(self.uiData.petBookInfo.HandbookId, v.topic_Id)
    local data = {
      idx = i - 1,
      id = v.topic_Id or 0,
      topic_desc = v.topic_desc,
      finish_cnt = finish_cnt,
      max_cnt = max_cnt,
      reward_id = reward_id,
      is_getaward = is_getaward,
      handbook_id = self.handbookId
    }
    table.insert(topicListData, data)
  end
  
  local function getAwrrdSortId(topicData)
    if topicData.is_getaward then
      return 2
    elseif topicData.is_getaward == false and topicData.finish_cnt >= topicData.max_cnt then
      return 0
    else
      return 1
    end
  end
  
  table.sort(topicListData, function(a, b)
    if getAwrrdSortId(a) == getAwrrdSortId(b) then
      return a.idx < b.idx
    else
      return getAwrrdSortId(a) < getAwrrdSortId(b)
    end
  end)
  local data = _G.NRCModuleManager:GetModule("HandbookModule").data
  if data then
    local list = self.CacheLeftHandbookList
    for _, info in pairs(list) do
      local bookInfo = data:GetPetHandBookData(info.HandbookId)
      if bookInfo.Collection and bookInfo.Collection.topic_list and bookInfo.Collection.status == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
        local topicList = bookInfo.Collection.topic_list
        local handbookConf = _G.DataConfigManager:GetPetHandbook(bookInfo.HandbookId)
        local petTopic = handbookConf.pet_topic
        for i, v in pairs(petTopic) do
          local finish_cnt = i <= #topicList and topicList[i] and topicList[i].finish_cnt or 0
          local max_cnt = v.topic_cnt
          local is_award = self.module.data:GetHandbookTopicAwardState(bookInfo.HandbookId, v.topic_Id)
          if false == isGetAll and finish_cnt >= max_cnt and false == is_award then
            isGetAll = true
            break
          end
        end
        if isGetAll then
          break
        end
      end
    end
  end
  self.SubjectList:InitList(topicListData)
  self.Btn_OneClickClaim:SetVisibility(isGetAll and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_Handbook_Subject_C:OnGetAllAward()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK_REWARD, true)
  if isBan then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401001, "UMG_Handbook_Subject_List_C:OnGetAwardBtn")
  local bookId = self.uiData.petBookInfo.handbookId
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetHandbookTopicAward, bookId)
end

return UMG_Handbook_Subject_C
