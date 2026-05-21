local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local FunctionBanUIController = require("NewRoco.Modules.System.FunctionBan.FunctionBanUIController")
local UMG_Email_C = _G.NRCPanelBase:Extend("UMG_Email_C")
local EmailModuleEvent = require("NewRoco.Modules.System.Email.EmailModuleEvent")
local FunctionEntranceMain = Enum.FunctionEntrance.FE_MAIL
local EmailTabIndexFunctionEntrance = {
  [0] = Enum.FunctionEntrance.FE_MAIL_TAB_MAIL,
  [1] = Enum.FunctionEntrance.FE_MAIL_TAB_ANNOUNCEMENT
}

local function CheckIfBan(tabIndex, showMsg)
  local isBan = false
  if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
    isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, FunctionEntranceMain, showMsg)
  end
  if not isBan and tabIndex then
    local functionEntrance = EmailTabIndexFunctionEntrance[tabIndex]
    if functionEntrance then
      isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, functionEntrance, showMsg)
    end
  end
  return isBan
end

local function CheckIfHide(tabIndex)
  local isHide = false
  if tabIndex then
    local functionEntrance = EmailTabIndexFunctionEntrance[tabIndex]
    if functionEntrance then
      isHide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, functionEntrance)
    end
  end
  return isHide
end

function UMG_Email_C:OnActive()
  self.module = _G.NRCModuleManager:GetModule("EmailModule")
  self.data = self.module:GetData("EmailModuleData")
  self.curMailData = nil
  self.curMailSortOrder = {}
  self.MailMaxCount = _G.DataConfigManager:GetGlobalConfigByKey("mail_max_threshold").num
  self:OnAddEventListener()
  local tables = self.data.TableNameDatas
  self.Tab_1:OnActive(0)
  self.Tab_2:OnActive(1)
  self.data:AddNoticeRedPoint()
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self.data:SetTableIndex(1)
    self.data:SetMailIndex(1)
  else
    local defaultTabIndex
    local tabIndexCtrl = {
      [0] = self.Tab_1,
      [1] = self.Tab_2
    }
    for tabIndex, ctrl in pairs(tabIndexCtrl) do
      local isHide = CheckIfHide(tabIndex)
      if not isHide then
        if not defaultTabIndex then
          defaultTabIndex = tabIndex
        elseif tabIndex < defaultTabIndex then
          defaultTabIndex = tabIndex
        end
        ctrl:SetCanClick(self.CheckCanClick, self, tabIndex)
      else
        ctrl:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if nil == defaultTabIndex then
      defaultTabIndex = 0
      Log.ErrorFormat("all mail tabs are hidden!!")
    end
    self.data:SetTableIndex(defaultTabIndex)
    self.data:SetMailIndex(0)
  end
  self:SetCommonTitle()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.OpenAnim = true
  self:OnRefreshUI(true)
  self.Btn_Claimed:SetBtnText(_G.LuaText.travel_receive_all)
  self.Btn_Claimed:SetShowLockIcon(false)
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_Email_C.OnActive")
  self:BindInputAction()
  if _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
end

function UMG_Email_C:OnDeactive()
  self:UnBindInputAction()
end

function UMG_Email_C:BindInputAction()
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CommonCloseUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperAddInputMappingContext, imc, self.depth)
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseUI")
  UE.UNRCEnhancedInputHelper.BindAction(ia, UE.ETriggerEvent.Triggered, self, "OnPcClose")
end

function UMG_Email_C:UnBindInputAction()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseUI")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  local imc = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_CommonCloseUI")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, imc)
end

function UMG_Email_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnClosePanel()
end

function UMG_Email_C:OnAddEventListener()
  self.CloseBtn.NRCSwitcher_1:SetActiveWidgetIndex(1)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnClosePanel)
  self:AddButtonListener(self.Btn_Draw_1.btnLevelUp, self.OnGetEmailItem)
  self:AddButtonListener(self.Btn_Deleted_1.btnLevelUp, self.OnDeleteEmail)
  self.Btn_Deleted_1.btnLevelUp.OnPressed:Add(self, self.OnBtnDeleted1Pressed)
  self.Btn_Deleted_1.btnLevelUp.OnReleased:Add(self, self.OnBtnDeleted1Released)
  self:AddButtonListener(self.Btn_Draw.btnLevelUp, self.OnGetEmailItemAll)
  self:AddButtonListener(self.Btn_Deleted.btnLevelUp, self.OnDeleteEmailAll)
  self:AddButtonListener(self.ParticularsBtn1.btnLevelUp, self.OnShowTips)
  self:AddButtonListener(self.blockBtn, self.OnBlockBtnClicked)
  self:AddDelegateListener(self.Dialogue.OnRichTextClick, self.OnDialogueTextClick)
  self:RegisterEvent(self, EmailModuleEvent.ClickTableNameEvent, self.OnTableClickRefreshUI)
  self:RegisterEvent(self, EmailModuleEvent.SelectMailEvent, self.ShowMailDes)
  self:RegisterEvent(self, EmailModuleEvent.SelectNoticeEvent, self.ShowNoticeDes)
  self:RegisterEvent(self, EmailModuleEvent.RefreshUIEvent, self.OnRefreshUI)
  self:RegisterEvent(self, EmailModuleEvent.UpdateMailDes, self.UpdateMailDes)
  self:RegisterEvent(self, EmailModuleEvent.RemoveMail, self.UpdateDeleteEmail)
  self:RegisterEvent(self, EmailModuleEvent.UpdateGetAllMail, self.UpdateGetAllMail)
  self:RegisterEvent(self, EmailModuleEvent.UpdateNotice, self.RefreshNoticeUI)
end

function UMG_Email_C:OnDestruct()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAIL)
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  self:UnRegisterEvent(self, EmailModuleEvent.ClickTableNameEvent)
  self:UnRegisterEvent(self, EmailModuleEvent.SelectMailEvent)
  self:UnRegisterEvent(self, EmailModuleEvent.SelectNoticeEvent)
  self:UnRegisterEvent(self, EmailModuleEvent.RefreshUIEvent)
  self:UnRegisterEvent(self, EmailModuleEvent.UpdateMailDes)
  self:UnRegisterEvent(self, EmailModuleEvent.RemoveMail)
  self:UnRegisterEvent(self, EmailModuleEvent.UpdateNotice)
  self:AddDelegateListener(self.Dialogue.OnRichTextClick, self.OnDialogueTextClick)
  if self.functionBanUIController then
    self.functionBanUIController:Deactivate()
  end
end

function UMG_Email_C:OnTableClickRefreshUI(isSort)
  self:PlayAnimation(self.change)
  self:OnRefreshUI(isSort)
end

function UMG_Email_C:OnSetEmailPageInfo(pageNum, reqNum, totalPage)
  self.MailTotalPage = totalPage
  self.MailPageNum = pageNum
  self.MailReqPage = reqNum
  self.MailReqTagDic[reqNum] = true
  self.IsInitPage = true
end

function UMG_Email_C:OnUpdateMailList(offset)
  if not self.IsInitPage then
    return
  end
  local curScrollNum = math.floor(offset / self.MAIL_ITEM_HIGHT)
  if 0 == curScrollNum % self.MAIL_REQ_THRESHOLD then
    local reqPage = math.floor(curScrollNum / self.MailPageNum)
    if not self.MailReqTagDic[reqPage] then
      _G.NRCModuleManager:DoCmd(_G.EmailModuleCmd.ZoneMailGetListByPageReq, reqPage)
    end
  end
end

function UMG_Email_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_Email_C:OnRefreshUI(isSort)
  self.curTableIndex = self.data:GetTableIndex()
  local isBan = CheckIfBan(self.curTableIndex, false)
  self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if 0 == self.curTableIndex then
    self.Tab_1:ShowSelect()
    self.Tab_2:UnShowSelect()
  else
    self.Tab_1:UnShowSelect()
    self.Tab_2:ShowSelect()
  end
  self.Switcher:SetActiveWidgetIndex(self.curTableIndex)
  self.data:SetTableIndex(self.curTableIndex)
  if 0 == self.curTableIndex then
    self:RefreshMailUI(isSort)
  else
    self:RefreshNoticeUI()
  end
  if self.OpenAnim then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.In)
    self.OpenAnim = false
  end
end

function UMG_Email_C:SortEmailList(dataList)
  table.sort(dataList, function(a, b)
    if a.is_read == b.is_read then
      if a.add_time == b.add_time then
        return a.mail_gid < b.mail_gid
      else
        return a.add_time < b.add_time
      end
    else
      return a.is_read == false and b.is_read == true
    end
  end)
  return dataList
end

function UMG_Email_C:RefreshMailUI(isSort)
  if not self.titleConf then
    self:SetCommonTitle()
    if self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
  end
  self.NRCText_65:SetText(LuaText.Error_Code_12015)
  local mailDatas = self.data:GetMailListDatas()
  local curCout = math.clamp(#mailDatas, 0, self.MailMaxCount)
  local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/Email/Raw/Frames/img_huobi_xin_png.img_huobi_xin_png'"
  local numStr = string.format("%d/%d", curCout, self.MailMaxCount)
  self.UpperLimit:InitNum(curCout, self.MailMaxCount, nil, true, iconPath)
  if 0 == #mailDatas then
    self.Switcher:SetActiveWidgetIndex(2)
    self.UpperLimit:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    return
  end
  self:SetButtonColor(mailDatas)
  if isSort then
    mailDatas = self:SortEmailList(mailDatas)
  end
  self.curMailSortOrder = mailDatas
  self.ItemList_4:InitList(mailDatas)
  if isSort and #mailDatas > 0 then
    self.ItemList_4:SelectItemByIndex(0)
  end
end

function UMG_Email_C:UpdateGetAllMail()
  for i = 1, self.ItemList_4:GetItemCount() do
    self.ItemList_4:OpItemByIndex(i, 0)
  end
end

function UMG_Email_C:SetButtonColor(mailDatas)
  local canAllRecv = false
  local canAllDelect = false
  for i = 1, #mailDatas do
    local is_read, is_recv = _G.NRCModuleManager:DoCmd(EmailModuleCmd.GetMailState, mailDatas[i].mail_gid)
    if false == is_recv then
      canAllRecv = true
      break
    end
  end
  for i = 1, #mailDatas do
    local is_read, is_recv = _G.NRCModuleManager:DoCmd(EmailModuleCmd.GetMailState, mailDatas[i].mail_gid)
    if is_read and is_recv then
      canAllDelect = true
      break
    end
  end
  if canAllRecv then
    self.Btn_Draw:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Btn_Claimed:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Draw:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Claimed:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  if canAllDelect then
    self.Btn_Deleted:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FFFFFFFF"))
    self.Btn_Deleted.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_white_png.img_btn1_white_png'")
    self.Btn_Deleted.btnLevelUp:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Btn_Deleted.BG:SetPath("PaperSprite'/Game/NewRoco/Modules/System/Common/CommonStatic/Frames/img_btn1_grey_png.img_btn1_grey_png'")
    self.Btn_Deleted.btnLevelUp:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Email_C:UpdateMailDes(content, index)
  self:ShowMailDes(content, index, true)
end

function UMG_Email_C:ShowMailDes(content, index, DisAima, mailGid)
  if self.lastIndex ~= index then
    self:PlayAnimation(self.change_icon)
  else
  end
  self.lastIndex = index
  if index then
    self.data:SetMailIndex(index)
    self.ItemList_4:OpItemByIndex(index, 1)
  else
    local lastIndex = self.data:GetMailIndex()
    self.ItemList_4:OpItemByIndex(lastIndex + 1, 0)
  end
  for i = 1, #self.curMailSortOrder do
    if content.mail_gid == self.curMailSortOrder[i].mail_gid then
      self.curMailSortOrder[i] = content
    end
  end
  self.ItemList:InitList(self.curMailSortOrder)
  self:SetButtonColor(self.curMailSortOrder)
  self.curMailData = content
  self.MagicAcademy:SetText(content.name)
  self.Number:SetText(content.time_str)
  self.ItemList_1:SetScrollOffset(0)
  self:DelaySeconds(0.1, function()
    local isShow = self.ItemList_1:GetScrollOffsetOfEnd() > 0
    self.ItemList_1:SetAlwaysShowScrollbar(isShow)
  end)
  self.Dialogue:SetText(content.contents)
  local rewardsTable = {}
  for k, v in ipairs(content.rewards) do
    local rewards = _G.NRCCommonItemIconData()
    rewards.itemType = v.Type
    rewards.itemId = v.Id
    rewards.itemNum = v.Count
    rewards.bShowNum = true
    if v.Type == _G.Enum.GoodsType.GT_RP_BEHAVIOR then
      rewards.bShowTip = false
    else
      rewards.bShowTip = true
    end
    rewards.bIsEmail = true
    rewards.showDefaultIconWhenConfigError = true
    rewards.IsShowPetbase = v.IsShowPetbase
    if content.reward and content.reward.rewards and content.reward.rewards[k] and content.reward.rewards[k].egg_info then
      rewards.eggInfo = content.reward.rewards[k].egg_info
    end
    if v.is_head_icon then
      if v.is_read then
        rewards.bShowGetTag = true
      else
        rewards.bShowGetTag = false
      end
    elseif v.is_recv then
      rewards.bShowGetTag = true
    else
      rewards.bShowGetTag = false
    end
    table.insert(rewardsTable, rewards)
  end
  self.cachedItemDataList = rewardsTable
  self.Award:InitList(rewardsTable)
  self.Btn_Deleted:SetVisibility(UE4.ESlateVisibility.Visible)
  self.NRCSwitcher_84:SetVisibility(UE4.ESlateVisibility.Visible)
  if true == content.is_recv then
    self.NRCSwitcher_84:SetActiveWidgetIndex(1)
  else
    self.NRCSwitcher_84:SetActiveWidgetIndex(0)
  end
  self.UpperLimit:SetVisibility(UE4.ESlateVisibility.Visible)
  self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  if mailGid then
    self.Btn_Draw_1:SetRedDotKey(62, mailGid)
  end
end

function UMG_Email_C:RefreshNoticeUI()
  self.UpperLimit:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not self.titleConf then
    self:SetCommonTitle()
    if self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
  self.NRCText_65:SetText(LuaText.Error_Code_12016)
  self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local noticeIndex = self.data:GetNoticeIndex()
  local noticeList = self.data.NoticeListDatas or {}
  if 0 == #noticeList then
    self.Switcher:SetActiveWidgetIndex(2)
    self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.ItemList:InitList(noticeList)
  if #noticeList > 0 then
    self.ItemList:SelectItemByIndex(0)
  end
  local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/Email/Raw/Frames/img_huobi_xin_png.img_huobi_xin_png'"
end

function UMG_Email_C:ShowNoticeDes(content, index)
  self:PlayAnimation(self.change_icon)
  if not self.titleConf then
    self:SetCommonTitle()
    if self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif self.titleConf.subtitle then
    self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
  end
  self.data:SetNoticeIndex(index)
  self.Title:SetText(content.Title)
  if content.bSetCenter then
    self.NxRichText_134:SetJustification(UE4.ETextJustify.Center)
  else
    self.NxRichText_134:SetJustification(UE4.ETextJustify.Left)
  end
  self.NxRichText_134:SetText(content.Content)
  self.ItemList_2:SetScrollOffset(0)
  self:DelaySeconds(0.05, function()
    local isShow = self.ItemList_2:GetScrollOffsetOfEnd() > 0
    self.ItemList_2:SetAlwaysShowScrollbar(isShow)
  end)
end

function UMG_Email_C:OnGetEmailItem()
  if self.curMailData then
    if not self:CheckEmailItemConfigValid(self.cachedItemDataList) then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_2520)
      Log.Error("UMG_Email_C:OnGetEmailItem email item config is invalid, please check!!!")
      return
    end
    self.module:ZoneMailGetAttachmentReq(self.curMailData.mail_gid)
  end
end

function UMG_Email_C:CheckEmailItemConfigValid(itemDataList)
  if not itemDataList or 0 == #itemDataList then
    return true
  end
  for i = 1, #itemDataList do
    local itemData = itemDataList[i]
    if not itemData then
    elseif itemData.itemType == _G.Enum.GoodsType.GT_VITEM then
      local vItemConf = _G.DataConfigManager:GetVisualItemConf(itemData.itemId)
      if nil == vItemConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid visual item config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_BAGITEM then
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemData.itemId)
      if nil == bagItemConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid bag item config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_PET then
      if itemData.IsShowPetbase then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(itemData.itemId)
        if nil == petBaseConf then
          Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid pet base config is nil, pet baseId: %s, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemId), tostring(itemData.itemType))
          return false
        end
      else
        local petInfo = _G.DataConfigManager:GetPetConf(itemData.itemId, true)
        if petInfo then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_id)
          if nil == petBaseConf then
            Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid pet base config is nil, pet baseId: %s, itemId: %s, itemType: %s", tostring(petInfo.base_id), tostring(itemData.itemId), tostring(itemData.itemType))
            return false
          end
        else
          local monsterConf = _G.DataConfigManager:GetMonsterConf(itemData.itemId)
          if nil == monsterConf then
            Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid monster config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
            return false
          end
          if nil ~= monsterConf then
            local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
            if nil == petBaseConf then
              Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid pet base config is nil, pet baseId: %s, itemId: %s, itemType: %s", tostring(monsterConf.base_id), tostring(itemData.itemId), tostring(itemData.itemType))
              return false
            end
          end
        end
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_SKIN then
      local cardSkinConf = _G.DataConfigManager:GetCardSkinConf(itemData.itemId)
      if nil == cardSkinConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid card skin config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_ICON then
      local GetCardIconConf = _G.DataConfigManager:GetCardIconConf(itemData.itemId)
      if nil == GetCardIconConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid card icon config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_CARD_LABEL then
      local CardLabelConf = _G.DataConfigManager:GetCardLabelConf(itemData.itemId)
      if nil == CardLabelConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid card label config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_FASHION_SUITS then
      local fashionConf = _G.DataConfigManager:GetFashionSuitsConf(itemData.itemId)
      if nil == fashionConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid fashion suits config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_FASHION then
      local fashionConf = _G.DataConfigManager:GetFashionItemConf(itemData.itemId)
      if nil == fashionConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid fashion item config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    elseif itemData.itemType == _G.Enum.GoodsType.GT_SALON then
      local salonConf = _G.DataConfigManager:GetSalonItemConf(itemData.itemId)
      if nil == salonConf then
        Log.ErrorFormat("UMG_Email_C:CheckEmailItemConfigValid salon item config is nil, itemId: %s, itemType: %s", tostring(itemData.itemId), tostring(itemData.itemType))
        return false
      end
    end
  end
  return true
end

function UMG_Email_C:OnGetEmailItemAll()
  self.module:GetEmailItemAllReq()
end

function UMG_Email_C:OnDeleteEmail()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local conf = _G.DataConfigManager:GetGlobalConfig("mail_delete_notice")
  local title = conf.title
  local des = conf.str
  local leftText = conf.button_left
  local rightText = conf.button_right
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetClickAnywhereClose(true):SetCallback(self, self.DeleteCallblack):SetCloseOnCancel(true):SetButtonText(rightText, leftText):SetToppingIconType(0)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Email_C:OnBtnDeleted1Pressed()
  self.Btn_Deleted_1:LoadAnimation(0)
end

function UMG_Email_C:OnBtnDeleted1Released()
  self.Btn_Deleted_1:LoadAnimation(1)
end

function UMG_Email_C:DeleteCallblack(isOk)
  if true == isOk then
    self.module:ZoneMailDelReq(self.curMailData.mail_gid)
  end
end

function UMG_Email_C:OnDeleteEmailAll()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local conf = _G.DataConfigManager:GetGlobalConfig("read_delete_notice")
  local title = conf.title
  local des = conf.str
  local leftText = conf.button_left
  local rightText = conf.button_right
  local Context = DialogContext()
  Context:SetTitle(title):SetContent(des):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.DeleteAllCallblack):SetClickAnywhereClose(true):SetCloseOnCancel(true):SetButtonText(rightText, leftText)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Email_C:DeleteAllCallblack(isOk)
  if true == isOk and self.module then
    self.module:DeleteEmailAllReq()
  end
end

function UMG_Email_C:DeleteAllAnimation()
  self:PlayAnimation(self.Email_empty_close)
  _G.NRCAudioManager:PlaySound2DAuto(40007006, "UMG_Email_ListItme_C:OnItemSelected")
  local itemDelayTime = 0.04
  local playOpenAimTime = 6 * itemDelayTime
  for i = 6, 0, -1 do
    if i <= self.ItemList_4:GetItemCount() then
      local time = (7 - i) * itemDelayTime
      self:DelaySeconds(time, function()
        self.ItemList_4:OpItemByIndex(i)
      end)
    end
  end
  self:DelaySeconds(playOpenAimTime, function()
    self.Switcher:SetActiveWidgetIndex(2)
    self:PlayAnimation(self.Email_empty_open)
    self.ItemList_4:InitList({})
  end)
end

function UMG_Email_C:UpdateDeleteEmail(removeList)
  local List = {}
  for i, value in pairs(self.curMailSortOrder) do
    local isAdd = true
    for j = 1, #removeList do
      local removeId = removeList[j]
      if removeId == value.mail_gid then
        isAdd = false
      end
    end
    if isAdd then
      table.insert(List, value)
    end
  end
  if 0 == #List then
    self:DeleteAllAnimation()
    self.curMailSortOrder = List
    local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/Email/Raw/Frames/img_huobi_xin_png.img_huobi_xin_png'"
    local numStr = string.format("%d/%d", #self.curMailSortOrder, self.MailMaxCount)
    self.UpperLimit:InitNum(#self.curMailSortOrder, self.MailMaxCount, nil, true, iconPath)
    return
  end
  self.ItemList_4:InitList(List)
  self.curMailSortOrder = List
  local iconPath = "PaperSprite'/Game/NewRoco/Modules/System/Email/Raw/Frames/img_huobi_xin_png.img_huobi_xin_png'"
  local numStr = string.format("%d/%d", #self.curMailSortOrder, self.MailMaxCount)
  self.UpperLimit:InitNum(#self.curMailSortOrder, self.MailMaxCount, nil, true, iconPath)
  if 0 == #self.curMailSortOrder then
    self.Switcher:SetActiveWidgetIndex(2)
    self.UpperLimit:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ParticularsBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local selectIndex = self.data:GetMailIndex()
  if #self.curMailSortOrder > 0 then
    if selectIndex >= #self.curMailSortOrder then
      selectIndex = #self.curMailSortOrder - 1
    end
    self.ItemList_4:SelectItemByIndex(selectIndex)
  end
  self:SetButtonColor(self.curMailSortOrder)
end

function UMG_Email_C:OnShowTips()
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_Email_C.OnShowTips")
  local arg = {}
  arg.type = 0
  if 0 == self.curTableIndex then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local title = LuaText.umg_email_1
    local Content = _G.DataConfigManager:GetGlobalConfig("mail_notice_text").str
    Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local title = LuaText.umg_email_2
    local Content = _G.DataConfigManager:GetGlobalConfig("mail_notice_text").str
    Context:SetTitle(title):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCloseOnOK(true)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_Email_C:OnClosePanel()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseUI")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  _G.NRCAudioManager:PlaySound2DAuto(41401010, "UMG_Email_C.OnShowTips")
  self:PlayAnimation(self.Out)
  self:OnClose()
end

function UMG_Email_C:OnConstruct()
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAIL)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_MAIL)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self.functionBanUIController = FunctionBanUIController()
  do
    local functionBanUIController = self.functionBanUIController
    for tabIndex, functionEntrance in pairs(EmailTabIndexFunctionEntrance) do
      functionBanUIController:RegisterCustomCallback(functionEntrance, self.OnEmailTabVisibilityChangeHandler, self, tabIndex)
    end
    if FunctionEntranceMain and 0 ~= FunctionEntranceMain then
      functionBanUIController:RegisterCustomCallback(FunctionEntranceMain, self.OnEmailTabVisibilityChangeHandler, self, -1)
    end
    functionBanUIController:Activate()
  end
end

function UMG_Email_C:OnAnimFinished(anim)
  if anim == self.In then
    self:PlayAnimation(self.Loop, 0)
  elseif anim == self.Out then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  elseif anim == self.Email_empty_close then
  elseif anim == self.Email_empty_open then
  end
end

function UMG_Email_C:OnLogin()
end

function UMG_Email_C:CheckCanClick(tabIndex)
  return not CheckIfBan(tabIndex, true)
end

function UMG_Email_C:OnEmailTabVisibilityChangeHandler(tabIndex, funcId, bHide)
  if funcId == FunctionEntranceMain or tabIndex == self.data:GetTableIndex() then
    local isBan = bHide or CheckIfBan(tabIndex, false)
    self.blockBtn:SetVisibility(isBan and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Email_C:OnBlockBtnClicked()
  local isBan = CheckIfBan(self.data:GetTableIndex(), true)
  if not isBan then
    Log.Error("UMG_Email_C:OnBlockBtnClicked: isBan is false")
  end
end

function UMG_Email_C:GetEncodeURL(url)
  if _G.OnlineModuleCmd then
    local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
    if accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel == Enum.CliLoginChannel.CLC_NONE then
      isEncodeUrl = false
    end
  end
  if url:find("?") ~= nil then
    url = UE4.UWebViewStatics.GetEncodeURL(url)
  end
  return url
end

function UMG_Email_C:OnDialogueTextClick(url_key)
  local url = ""
  if self.curMailData and self.curMailData.mail_sub_type then
    if self.curMailData.mail_sub_type == _G.Enum.MailSubType.MST_QUESTIONNAIRE then
      url = self:GetEncodeURL(url_key)
      self:Log("UMG_Email_C:OnDialogueTextClick \229\138\160\229\175\134\231\165\168\230\141\174", url)
    else
      url = url_key
    end
  end
  self:Log("UMG_Email_C:OnDialogueTextClick", url)
  UE4.UWebViewStatics.OpenURL(url, 1, false, true, "", false)
end

function UMG_Email_C:OnServerTimeUpdate()
  local count = self.ItemList_4:GetItemCount()
  for i = 1, count do
    local idx = i - 1
    self.ItemList_4:GetItemByIndex(idx):UpdateItemTime()
  end
end

return UMG_Email_C
