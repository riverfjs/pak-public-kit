local PetUtils = require("NewRoco.Utils.PetUtils")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local CommonBtnEnum = require("NewRoco.Modules.System.CommonBtn.CommonBtnEnum")
local UMG_Handbook_C = _G.NRCPanelBase:Extend("UMG_Handbook_C")

function UMG_Handbook_C:OnActive(arg)
  self.InputBox_1:SetHintText(LuaText.hb_default_search_text2)
  self:ShowPhotoSwitchTabs()
  if not _G.DataModelMgr.PlayerDataModel:HasPanelMusic(Enum.InterfaceType.IT_HANDBOOK) then
    local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
    _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
    if StateGroup then
      _G.NRCAudioManager:BatchSetState(StateGroup)
    end
  end
  if nil == arg then
    arg = {}
    Log.Error("\229\155\190\233\137\180\228\188\160\229\133\165arg\229\143\130\230\149\176\228\184\186\231\169\186\239\188\129\232\175\183\230\163\128\230\159\165")
  end
  self.bEnableClick = false
  self.arg = arg
  if self.arg and self.arg.IsHide then
    if self.arg.LodFinshCall then
      self.arg.LodFinshCall()
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:BindInputAction()
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1364, "MG_Handbook_C:OnActive")
  self.CloseBtn:SetStyle(2)
  self:SetCommonTitle()
  local areaId = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookId)
  local areaConf = _G.DataConfigManager:GetAreaHandbook(areaId)
  self.Title1:SetBg(areaConf.icon)
  self:InitPanel()
  self.ComboBox_White:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if not self.bComboBoxSetUp then
    local SortList = self:GetSortList()
    local DropDownListInfo = {}
    for i = 1, #SortList do
      table.insert(DropDownListInfo, {
        ComType = CommonBtnEnum.ComboBoxType.Handbook,
        name = SortList[i].text,
        sortList = SortList,
        isHideRedDot = true
      })
    end
    if not self.SelectComboIndex then
      self.SelectComboIndex = 1
    end
    local comboBoxText
    if self.module.data.HandbookLeftSortIndex == _G.Enum.HandbookSequenceDefault.HSD_SEQUENCE_NUMBER_UP then
      self.SelectComboIndex = 1
      comboBoxText = SortList[1].text
    else
      self.SelectComboIndex = 2
      comboBoxText = SortList[2].text
    end
    self:SetCommonComboBoxInfo(self.ComboBox_White, DropDownListInfo, self.SelectComboIndex, comboBoxText)
  end
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    self:StopAnimation(self.Open)
    self:PlayAnimation(self.Open, 0, 1, 0, 1)
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TASKITEM
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  self:ChangeFilterIcon()
end

function UMG_Handbook_C:OnEnable()
end

function UMG_Handbook_C:OnDisable()
end

function UMG_Handbook_C:SetArg(arg)
  self.arg = arg
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local isAssignTo = arg and arg.handbookId and arg.petbaseId and true or false
  local isShowBookAim = self.arg and self.arg.isShowBookAim or false
  self.IsCanPlayAnima = isShowBookAim
  self.IsPlayAnimOpen = true
  self.module = _G.NRCModuleManager:GetModule("HandbookModule")
  self.data = self.module:GetData("HandbookModuleData")
  local list, SelectComboIndex = self.data:UpdatePetHandbookSortLeftList()
  self.NRCScrollView_43:InitList(list)
  self.NRCScrollView_43:SetVisibility(UE4.ESlateVisibility.Visible)
  self.curListDatas = list
  self:JumpToIndex(isAssignTo, list)
  self:ShowPhotoSwitchTabs()
  self.HandbookContent:OnActive(self.IsCanPlayAnima)
  if self.IsCanPlayAnima then
    self.HandbookContent:HidePreviewWorld(3)
    self:PlayAnimation(self.Book_Open)
  end
end

function UMG_Handbook_C:OnConstruct()
  self.isFirstInitList = false
  self.bindActionSucceed = false
  self.bComboBoxSetUp = false
  self:SetChildViews(self.HandbookContent)
  self:OnAddEventListener()
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetDistrictMapGuideRecordEnable, true, "UMG_Handbook_C")
end

function UMG_Handbook_C:BindInputAction()
  if self.bindActionSucceed then
    return
  end
  self.bindActionSucceed = true
  local mappingContext = self:AddInputMappingContext("IMC_HandBookUI")
  if mappingContext then
    mappingContext:BindAction("IA_CloseHandBookUI", self, "OnPcClose")
  end
end

function UMG_Handbook_C:OnPcClose()
  if not self.bEnableClick then
    return
  end
  self:OnClickCloseBtn()
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnMainUISubPanelClosed, false)
end

function UMG_Handbook_C:InitPanel()
  local isAssignTo = self.arg and self.arg.handbookId and self.arg.petbaseId and true or false
  local isShowBookAim = self.arg and self.arg.isShowBookAim or false
  self.IsPlayAnimOpen = true
  self.IsCanPlayAnima = true
  self.IsCanPlayAnima = isShowBookAim
  self.module = _G.NRCModuleManager:GetModule("HandbookModule")
  self.data = self.module:GetData("HandbookModuleData")
  self.data.HandbookLeftReversal = false
  self.Quantity:SetText(self.data.CollectedCount)
  self.Quantity_1:SetText(self.data.HaveDiscoveredCount)
  self.NRCScrollView_43:SetVisibility(UE4.ESlateVisibility.Visible)
  local list, SelectComboIndex = self.data:UpdatePetHandbookSortLeftList()
  self.SelectComboIndex = SelectComboIndex
  self.data:SetSelectLeftListItemUI(nil)
  local areaId = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookId)
  local areaConf = _G.DataConfigManager:GetAreaHandbook(areaId)
  if UE4.UObject.IsValid(self.NRCImage_94) then
    self.NRCImage_94:SetPath(areaConf.icon)
  end
  self.Title1:SetSubtitle(areaConf.name)
  if self.arg.NeedOpenSubject then
    self.NRCScrollView_43:InitList(list)
    self.curListDatas = list
    self:JumpToIndex(isAssignTo, list)
    self:DelayFrames(3, function()
      self.HandbookContent:OnClickBtnTrophy()
    end)
  else
    self:DelayFrames(10, function()
      self.NRCScrollView_43:InitList(list)
      self.curListDatas = list
      self:JumpToIndex(isAssignTo, list)
    end)
  end
  self.HandbookContent:OnActive(self.IsCanPlayAnima)
  if self.IsCanPlayAnima then
    self.HandbookContent:HidePreviewWorld(3)
    self:PlayAnimation(self.Book_Open)
  else
    self.bEnableClick = true
  end
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
end

function UMG_Handbook_C:JumpToIndex(isAssignTo, list)
  local jumpToIndex = 0
  if isAssignTo then
    local bookInfo
    local Index = 0
    for i = 1, #list do
      if list[i].HandbookId == self.arg.handbookId then
        bookInfo = self.data:GetPetHandBookData(self.arg.handbookId)
        Index = i
        break
      end
    end
    if bookInfo and Index > 0 then
      local subIndex = 1
      if bookInfo.Collection ~= nil then
        for j = 1, #bookInfo.Collection.record do
          if bookInfo.Collection.record[j].pet_base_id == self.arg.petbaseId then
            subIndex = j
            break
          end
        end
      end
      jumpToIndex = Index - 1
      self.NRCScrollView_43:SelectItemByIndex(Index - 1)
      self:SetScrollOffsetInfo()
      self.data:SetSubSelectIndex(subIndex)
    end
  else
    local bookInfo
    local Index = 0
    for i = 1, #list do
      local State = list[i].State
      if State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
        bookInfo = self.data:GetPetHandBookData(list[i].HandbookId)
        Index = i
        break
      end
    end
    if bookInfo and Index > 0 then
      local subIndex = 1
      if bookInfo.Collection ~= nil then
        for j = 1, #bookInfo.Collection.record do
          if bookInfo.Collection.record[j].state == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
            subIndex = j
            break
          end
        end
      end
      jumpToIndex = Index - 1
      self.NRCScrollView_43:SelectItemByIndex(Index - 1)
      self:SetScrollOffsetInfo()
      self.data:SetSubSelectIndex(subIndex)
    end
  end
  self:PlayLoopAnimation(jumpToIndex)
end

function UMG_Handbook_C:PlayLoopAnimation(jumpToIndex)
  local coutn = self.NRCScrollView_43:GetItemCount()
  self:CancelDelay()
  for i = 0, 8 do
    local index = jumpToIndex + i
    if coutn >= index then
      local item = self.NRCScrollView_43:GetItemByIndex(jumpToIndex + i)
      if item then
        item:HideItem()
        self:DelaySeconds(0.05 * i, function()
          item:PlayBookOpenAnimation()
        end)
      end
    end
  end
end

function UMG_Handbook_C:OnDeactive()
  self:RemoveButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:UnRegisterEvent(self, HandbookModuleEvent.SetReversedSort)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnBookDropDownListClose)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangeAreaData)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnSearchHandbook)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangSelectItemData)
  self:UnRegisterEvent(self, HandbookModuleEvent.SetSelectedItemUpdatePanel)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.UpdateSort, self.OnUpdateSortType)
  self.HandbookContent:OnDeactive()
end

function UMG_Handbook_C:SetCommonComboBoxInfo(ComboBox, DropDownListInfo, DropDownListIndex, DropDownListText, ComboBoxText, ComboBoxIcon)
  self.bComboBoxSetUp = true
  local CommonDropDownListData = _G.NRCCommonDropDownListData()
  if DropDownListInfo then
    CommonDropDownListData.DropDownListInfo = DropDownListInfo
  end
  CommonDropDownListData.ComType = CommonBtnEnum.ComboBoxType.Bag
  if DropDownListIndex then
    CommonDropDownListData.DropDownListIndex = DropDownListIndex
  end
  if DropDownListText then
    CommonDropDownListData.DropDownListText = DropDownListText
  end
  if ComboBoxText then
    CommonDropDownListData.DropDownListText = ComboBoxText
  end
  if ComboBoxIcon then
    CommonDropDownListData.DropDownListIcon = ComboBoxIcon
  end
  CommonDropDownListData.Call = self
  CommonDropDownListData.Btn_LeftHandler = self.OnOpenFilter
  CommonDropDownListData.Btn_RightHandler = self.OnClickSort
  ComboBox:SetPanelInfo(CommonDropDownListData)
end

function UMG_Handbook_C:OnAddEventListener()
  self:AddDelegateListener(self.InputBox_1.OnTextChanged, self.OnTextChanged)
  self:AddDelegateListener(self.InputBox_1.OnTextCommitted, self.OnTextCommitted)
  self:AddDelegateListener(self.InputBox_1.OnTextEndTransaction, self.OnTextEndTransaction)
  self:AddDelegateListener(self.InputBox_1.OnFocusChanged, self.OnFocusChanged)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClickCloseBtn)
  self:AddButtonListener(self.Upvote.btnLevelUp, self.OnSearch)
  self:RegisterEvent(self, HandbookModuleEvent.SetReversedSort, self.OnSetReversedSort)
  self:RegisterEvent(self, HandbookModuleEvent.OnBookDropDownListClose, self.OnBookDropDownListClose)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangeAreaData, self.OnChangeArea)
  self:RegisterEvent(self, HandbookModuleEvent.OnSearchHandbook, self.OnSearchHandbook)
  self:RegisterEvent(self, HandbookModuleEvent.OnTopicTurnPage, self.OnChangeNextPage)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangSelectItemData, self.OnChageSelectLeftListItemData)
  self:RegisterEvent(self, HandbookModuleEvent.OnUpdateLeftItemListTaskState, self.OnUpdateLeftListTaskState)
  self:RegisterEvent(self, HandbookModuleEvent.SetSelectedItemUpdatePanel, self.UpdateSelectItemInfo)
  _G.NRCEventCenter:RegisterEvent("UMG_Handbook_C", self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.NRCEventCenter:RegisterEvent("HandbookModule", self, BagModuleEvent.UpdateSort, self.OnUpdateSortType)
end

function UMG_Handbook_C:UpdateSelectItemInfo(handbookInfo)
  if handbookInfo and handbookInfo.State then
    if self.LastState ~= handbookInfo.State and handbookInfo.State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      self:ShowPhotoSwitchTabs()
    end
    if handbookInfo.State ~= _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      self.Panel_TabBg:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Panel_TabBg:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.LastState = handbookInfo.State
  end
end

function UMG_Handbook_C:GetSortList()
  local list = {}
  local conf1 = _G.DataConfigManager:GetPetHandbookSequence(1)
  local conf2 = _G.DataConfigManager:GetPetHandbookSequence(2)
  local info1 = {
    id = conf1.id,
    text = conf1.sequence_desc,
    sequence = conf1.sequence_switch
  }
  local info2 = {
    id = conf2.id,
    text = conf2.sequence_desc,
    sequence = conf2.sequence_switch
  }
  table.insert(list, info1)
  table.insert(list, info2)
  return list
end

function UMG_Handbook_C:ChangeFilterIcon()
  local path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  if self.filterConditon == nil then
    self.ComboBox_White:SetScreeningBtnIcon(path)
    return
  end
  if self:IsFilterCondition() then
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen3_png.img_Screen3_png'"
  else
    path = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Screen1_png.img_Screen1_png'"
  end
  self.ComboBox_White:SetScreeningBtnIcon(path)
end

function UMG_Handbook_C:OnOpenFilter()
  _G.NRCAudioManager:PlaySound2DAuto(1013, "UMG_BookDropDownList_C:OnSelectedBtnClick")
  local filterDatas = self.module.data:GetAllFilterData()
  _G.NRCModeManager:DoCmd(_G.BagModuleCmd.OpenFilterPanel, filterDatas, _G.DataConfigManager.ConfigTableId.HANDBOOK_FILTER_CONF, self.filterConditon)
end

function UMG_Handbook_C:ActiveFiltering(list)
  if self:IsFilterCondition() then
    local lst = self.module.data:GetAllFilterData()
    local filterList = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.FilterDepart, self.filterConditon.FilterDepartCondition, lst or {})
    local showList = self:FilterShining(filterList, self.filterConditon)
    if self.filterConditon.FilterSeasonCondition and #self.filterConditon.FilterSeasonCondition > 0 then
      showList = self:FilterSeason(showList, self.filterConditon)
    end
    return showList
  end
  return list
end

function UMG_Handbook_C:FilterShining(filterList, condition)
  local bookIdDic = {}
  local showList = {}
  for i, data in pairs(filterList) do
    if bookIdDic[data.handbookId] == nil then
      if condition.FilterShiningCondition and condition.FilterShiningCondition == _G.Enum.FilterShining.FS_ALL_SHINING then
        local recordData = self.module.data:GetPetHandBookRecordData(data.handbookId, data.filterData.petbase_id)
        if recordData.Record and recordData.PetBaseConf then
          local baseConf = recordData.PetBaseConf
          if baseConf.have_shiny and 1 == baseConf.have_shiny then
            bookIdDic[data.handbookId] = data.handbookId
          end
        end
      else
        bookIdDic[data.handbookId] = data.handbookId
      end
    end
  end
  local curLeftListDatas = self.module.data.CacheLeftHandbookList
  for i, data in pairs(curLeftListDatas) do
    if bookIdDic[data.HandbookId] then
      table.insert(showList, data)
    end
  end
  return showList
end

function UMG_Handbook_C:FilterSeason(filterList, condition)
  local bookIdDic = {}
  local showList = {}
  for i, data in pairs(filterList) do
    if bookIdDic[data.HandbookId] == nil then
      if condition.FilterSeasonCondition and #condition.FilterSeasonCondition > 0 then
        for j = 1, #condition.FilterSeasonCondition do
          local enum = condition.FilterSeasonCondition[j]
          local handbookData = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, data.HandbookId)
          if handbookData and handbookData.Records then
            local records = handbookData.Records
            if records then
              for _, v in pairs(records) do
                local baseConf = v.PetBaseConf
                if baseConf.belong_season and 0 ~= baseConf.belong_season then
                  local belong_season = baseConf.belong_season
                  if belong_season == enum then
                    bookIdDic[data.HandbookId] = data.HandbookId
                    break
                  end
                end
              end
            end
            if bookIdDic[data.HandbookId] then
              break
            end
          end
        end
      end
    else
      bookIdDic[data.HandbookId] = data.HandbookId
    end
  end
  local curLeftListDatas = self.module.data.CacheLeftHandbookList
  for i, data in pairs(curLeftListDatas) do
    if bookIdDic[data.HandbookId] then
      table.insert(showList, data)
    end
  end
  return showList
end

function UMG_Handbook_C:OnFilter(filterList, condition)
  self.filterConditon = condition
  if (condition.FilterDepartCondition == nil or 0 == #condition.FilterDepartCondition) and (nil == condition.FilterShiningCondition or condition.FilterShiningCondition == _G.Enum.FilterShining.FS_NONE) and condition.FilterSeasonCondition and 0 == #condition.FilterSeasonCondition then
    local showList = self.module.data.CacheLeftHandbookList
    self.NRCScrollView_43:InitList(showList)
    self.curListDatas = showList
    self.NRCScrollView_43:SelectItemByIndex(0)
    self:ChangeFilterIcon()
    return
  end
  local showList = self:FilterShining(filterList, condition)
  if condition.FilterSeasonCondition and #condition.FilterSeasonCondition > 0 then
    showList = self:FilterSeason(showList, condition)
  end
  if #showList > 0 then
    self.NRCScrollView_43:InitList(showList)
    self.curListDatas = showList
    self.NRCScrollView_43:SelectItemByIndex(0)
  else
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_handbook_filter_3)
  end
  self:ChangeFilterIcon()
end

function UMG_Handbook_C:OnTextChanged()
  local text = self.InputBox_1:GetText()
  text = self:SubStr(text, 30)
  text = string.GetSubStr(text, 30)
  if string.SubStringGetTotalIndex(text) > 30 then
    text = string.GetSubStr(text, 30)
  end
  self.InputBox_1:SetText(text)
end

function UMG_Handbook_C:OnTextCommitted(text, type)
  if type == UE4.ETextCommit.OnEnter then
    self:OnSearch()
  end
end

function UMG_Handbook_C:OnTextEndTransaction()
end

function UMG_Handbook_C:OnFocusChanged(bIsFocus)
  if _G.RocoEnv.IS_EDITOR or _G.RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    return
  end
  if bIsFocus then
    self.Mask:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.input_in)
  else
    self:PlayAnimation(self.input_out)
  end
end

function UMG_Handbook_C:SubStr(str, byte_count)
  local count = 0
  local len = #str
  local index = 1
  while byte_count > count and len >= index do
    local ch = string.byte(str, index)
    local step
    if ch < 128 then
      step = 1
    elseif ch >= 192 and ch < 224 then
      step = 2
    elseif ch >= 224 and ch < 240 then
      step = 3
    elseif ch >= 240 and ch < 248 then
      step = 4
    elseif ch >= 248 and ch < 252 then
      step = 5
    elseif ch >= 252 then
      step = 6
    else
      step = 0
    end
    if byte_count < count + step then
      break
    end
    count = count + step
    index = index + step
  end
  return string.sub(str, 1, index - 1)
end

function UMG_Handbook_C:OnSearch()
  _G.NRCAudioManager:PlaySound2DAuto(1002, "UMG_Handbook_Search_C:OnSearch")
  local text = self.InputBox_1:GetText()
  if nil == text or 0 == #text or nil ~= text:match("^[%s\r\n\t]*$") then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.hb_search_error1)
    return
  end
  if self:IsFilterCondition() then
    _G.NRCModeManager:DoCmd(HandbookModuleCmd.OnSearchHandbook, text, self.curListDatas)
  else
    local cacheLeftList = self.module.data.CacheLeftHandbookList
    _G.NRCModeManager:DoCmd(HandbookModuleCmd.OnSearchHandbook, text, cacheLeftList)
  end
  self.InputBox_1:SetText("")
end

function UMG_Handbook_C:IsFilterCondition()
  if self.filterConditon == nil then
    return false
  end
  local isFilter = nil ~= self.filterConditon.FilterShiningCondition and self.filterConditon.FilterShiningCondition ~= _G.Enum.FilterShining.FS_NONE or #self.filterConditon.FilterDepartCondition > 0 or #self.filterConditon.FilterSeasonCondition > 0
  return isFilter
end

function UMG_Handbook_C:OnClickSort()
  NRCModuleManager:DoCmd(HandbookModuleCmd.ReversedSort)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1238, "UMG_BookDropDownList_C:OnClickNRCButton_0")
end

function UMG_Handbook_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Handbook_C:OnChangeArea(areaData)
  local conf = areaData.conf
  self.Title1:SetSubtitle(conf.name)
end

function UMG_Handbook_C:OnSearchHandbook(searchData)
  self:OnChageSelectLeftListItemData(searchData.bookId, searchData.recordIdx)
  self.HandbookContent:OnShowPetBaseByRecordIndex()
end

function UMG_Handbook_C:OpenHandBook(handbookId, petBaseId)
  self.NRCScrollView_43:SetVisibility(UE4.ESlateVisibility.Visible)
  if handbookId and petBaseId then
    if self.data:GetPetHandBookState(petBaseId) == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      self:OnSetLeftSortType(2)
    else
      self:OnSetLeftSortType(1)
    end
  end
  self:ShowHandBookHomeInfoList(handbookId, petBaseId)
end

function UMG_Handbook_C:CloseHandBook()
  self.NRCScrollView_43:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.IsPlayAnimOpen = false
  if self.IsCanPlayAnima then
    self.HandbookContent:HidePreviewWorld()
    self:PlayAnimationReverse(self.Book_Open)
  else
    self:DoClose()
  end
  self.filterConditon = nil
end

function UMG_Handbook_C:UpdateLeftList()
  local list, SelectComboIndex = self.data:UpdatePetHandbookSortLeftList()
  self.NRCScrollView_43:InitList(list)
  self.curListDatas = list
  local index = self.data:GetSelectIndex()
  self.NRCScrollView_43:SelectItemByIndex(index)
end

function UMG_Handbook_C:OnUpdateLeftListTaskState()
  for i = 1, self.NRCScrollView_43:GetItemCount() do
    local item = self.NRCScrollView_43:GetItemByIndex(i - 1)
    if UE4.UObject.IsValid(item) then
      item:OnUpdateTaskState()
    end
  end
end

function UMG_Handbook_C:ShowHandBookHomeInfoList(handbookId, petBaseId)
  local index = self.data:GetSelectIndex()
  local subIndex = self.data:GetSubSelectIndex()
  local list, SelectComboIndex = self.data:UpdatePetHandbookSortLeftList()
  if self.isFirstInitList == false then
    self.isFirstInitList = true
    return
  end
  if handbookId and petBaseId then
    subIndex = self.data:GetPetHandBookRecordIndex(handbookId, petBaseId)
    self.data:SetSubSelectIndex(subIndex)
    for i = 1, #list do
      if list[i].HandbookId == handbookId then
        index = i - 1
        break
      end
    end
    self.NRCScrollView_43:InitList(list)
    self.curListDatas = list
    self.data:SetSelectSubForce(true)
    self.NRCScrollView_43:SelectItemByIndex(index)
  else
    self.data:SetSubSelectIndex(1)
    local listDatas = self:ActiveFiltering(list)
    self.NRCScrollView_43:InitList(listDatas)
    self.curListDatas = listDatas
    self.data:SetSelectSubForce(false)
    self.NRCScrollView_43:SelectItemByIndex(0)
  end
end

function UMG_Handbook_C:SetScrollOffsetInfo()
  local size_Y = 122
  local ChildSize_Y = 121
  local OffsetIndex = self.data:GetSelectIndex()
  local margin = size_Y % ChildSize_Y
  local sizeoffset = OffsetIndex * ChildSize_Y
  if size_Y < sizeoffset then
    local offset = sizeoffset - size_Y + margin + ChildSize_Y
    self.NRCScrollView_43:NRCSetScrollOffset(offset)
  else
    self.NRCScrollView_43:NRCSetScrollOffset(0)
  end
end

function UMG_Handbook_C:OnSetReversedSort()
  self.data:SetSelectIndex(0)
  if self.data.HandbookLeftReversal then
    local sortingBtnPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Sort1_png.img_Sort1_png'"
    self.ComboBox_White.SortingBtn:SetPath(sortingBtnPath, sortingBtnPath, sortingBtnPath)
  else
    local sortingBtnPath = "PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_Sort1_1_png.img_Sort1_1_png'"
    self.ComboBox_White.SortingBtn:SetPath(sortingBtnPath, sortingBtnPath, sortingBtnPath)
  end
  self.data.HandbookLeftReversal = not self.data.HandbookLeftReversal
  self:ShowHandBookHomeInfoList()
end

function UMG_Handbook_C:ResetComboBox()
  if self.ComboBox_White and self.ComboBox_White.CommonDropDownListData then
    self.ComboBox_White:SetPopupVisible(false)
  end
end

function UMG_Handbook_C:OnSetLeftSortType(_sortId)
  self.data:SetSortIndex(_sortId)
  self:ShowHandBookHomeInfoList()
end

function UMG_Handbook_C:OnUpdateSortType(index)
  local sortConf = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.PET_HANDBOOK_SEQUENCE):GetAllDatas()
  for key, conf in pairs(sortConf) do
    if key == index then
      self:OnSetLeftSortType(conf.sequence_default)
    end
  end
end

function UMG_Handbook_C:OnSelectDataShowPanel(_handbookId, _petBaseId)
  local subIndex = self.data:GetPetHandBookRecordIndex(_handbookId, _petBaseId)
end

function UMG_Handbook_C:OnChangeNextPage(index, handbookId, petBaseId)
  local indexPage = index
  local curLeftListDatas = self.curListDatas or self.module.data.CacheLeftHandbookList
  local curBookData = curLeftListDatas[indexPage]
  if handbookId and (not curBookData or curBookData.HandbookId ~= handbookId) then
    for i, data in ipairs(curLeftListDatas) do
      if data.HandbookId == handbookId then
        indexPage = i
        curBookData = data
        break
      end
    end
  end
  if not curBookData then
    return
  end
  self.NRCScrollView_43:SelectItemByIndex(indexPage - 1)
  self:SetScrollOffsetInfo()
  local petBookInfo = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandBookData, curBookData.HandbookId)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenHandbookSubjectPanel, petBookInfo, petBaseId or curBookData.PetBaseId)
end

function UMG_Handbook_C:OnChageSelectLeftListItemData(handbookId, subIndex)
  local bookInfo
  local Index = 0
  local list = self.curListDatas
  for i = 1, #list do
    if list[i].HandbookId == handbookId then
      bookInfo = self.data:GetPetHandBookData(handbookId)
      Index = i
      break
    end
  end
  if bookInfo and Index > 0 then
    self.NRCScrollView_43:SelectItemByIndex(Index - 1)
    self:SetScrollOffsetInfo()
    self.data:SetSubSelectIndex(subIndex)
  end
end

function UMG_Handbook_C:OnBookDropDownListClose(_visible)
  if not _visible then
  else
  end
end

function UMG_Handbook_C:OnDestruct()
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.OnFilter, self.OnFilter)
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_HANDBOOK)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetDistrictMapGuideRecordEnable, false, "UMG_Handbook_C")
end

function UMG_Handbook_C:OnClickButtonLeft()
end

function UMG_Handbook_C:OnGlobalBtn()
end

function UMG_Handbook_C:OnClickCloseBtn()
  local mappingContext = self:GetInputMappingContext("IMC_HandBookUI")
  if mappingContext then
    self.bindActionSucceed = false
    mappingContext:UnBindAction("IA_CloseHandBookUI")
  end
  self:RemoveInputMappingContext("IMC_HandBookUI")
  _G.NRCAudioManager:PlaySound2DAuto(40004005, "UMG_Plane_ExchangeVisits_C:OnActive")
  self.HandbookContent:PlayCloseAnimation()
  self:CloseHandBook()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.CloseHandbookPanel)
  _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.OnMainUISubPanelClosed, false)
end

function UMG_Handbook_C:OnAnimationFinished(Animation)
  if Animation == self.Book_Open then
    if self.IsPlayAnimOpen then
      _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
      self.HandbookContent:ShowPreviewWorld()
      self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.bEnableClick = true
    else
      self:ClearAllEnhancedInput()
      self.bindActionSucceed = false
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      local IsHaveCover = self.module:IsHaveCover()
      if not IsHaveCover then
        self:DoClose()
      end
    end
  elseif Animation == self.close then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1039, "UMG_HandbookContent_C:OnChangeHandBookActiveState")
  elseif Animation == self.input_out then
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Handbook_C:ShowPhotoSwitchTabs()
  local tableDatas = {}
  table.insert(tableDatas, {
    title = LuaText.handbook_tab_text_1
  })
  table.insert(tableDatas, {
    title = LuaText.handbook_tab_text_2
  })
  self.TabList1:InitGridView(tableDatas)
  self.TabList1:SelectItemByIndex(0)
end

return UMG_Handbook_C
