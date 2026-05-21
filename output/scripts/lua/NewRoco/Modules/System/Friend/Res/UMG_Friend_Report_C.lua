local UMG_Friend_Report_C = _G.NRCPanelBase:Extend("UMG_Friend_Report_C")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local TimeoutEventListener = require("Common.TimeoutEventListener")

function UMG_Friend_Report_C:OnConstruct()
  self:SetChildViews(self.PopUp2)
  self.ReportItems = {}
  self.SingleSelect_CurIndex = 0
  self.SelectCount = 0
  self.Lock = false
  self.ReportContentList = {}
  self.NewInput = nil
  self.OldInput = nil
  self:OnAddEventListener()
end

function UMG_Friend_Report_C:OnDestruct()
  self.ReportItems = {}
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_REPORT_SAFETY_DATA_RSP, self.UnlockConfirmButton)
end

function UMG_Friend_Report_C:OnActive(_data, closeCallbackCaller, closeCallback)
  self.Lock = false
  self.data = _data
  self.closeCallbackCaller = closeCallbackCaller
  self.closeCallback = closeCallback
  self:SetCommonPopUpInfo()
  self:SetPopUpBtn(false, true)
  self:SetPanelInfo()
  self.In = self:GetAnimByIndex(0)
  self.Loop = self:GetAnimByIndex(1)
  self.Out = self:GetAnimByIndex(2)
  local ReportScene = self.data.business_data.report_scene
  if ReportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE then
    self.Text:SetText(LuaText.umg_homestead_report_8)
    self.PromptText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PromptText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:PlayAnimation(self.In)
  _G.NRCAudioManager:PlaySound2DAuto(41401011, "UMG_Friend_Report_C:OnActive")
end

function UMG_Friend_Report_C:SetPanelInfo()
  local data = self.data
  local reportScene = data.business_data.report_scene
  if reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_CONVERSATION_SPEAKING_SCENE then
    self.ReportContentList = {
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_1,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_INSULT_AND_ABUSE,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_2,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_TRAFFIC_ADVERTISING,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_3,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PORNOGRAPHIC_AND_VULGAR,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_4,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CONTENT_INVOLVES_POLITICS,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_5,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_HARASSMENT,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_6,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_VIOLENCE_AND_BLOODSHED,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_7,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_8,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_FRAUDULENT_INFORMATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_9,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CHAT_OTHER,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      }
    }
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_PERSONAL_INFORMATION_SCENE then
    if data.business_data.is_form_card then
      self.ReportContentList = {
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_7,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_11,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_SIGNATURE_VIOLATION,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_9,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PERSONAL_INFO_OTHERS,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_25,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PLAYER_BUSINESS_CARD,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_report_1,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NON_GAMING_PHOTOS,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        }
      }
    else
      self.ReportContentList = {
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_7,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_11,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_SIGNATURE_VIOLATION,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_9,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PERSONAL_INFO_OTHERS,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        }
      }
    end
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_GAME_MATCH_SCENE then
    self.ReportContentList = {
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_21,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_MODIFICATION_VALUE_CHEAT,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_USE_CHEATING_TOOLS
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_22,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_EXPLOITING_BUG,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_MALICIOUS_GAMING_BEHAVIOR
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_24,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NEGATIVE_MATCH,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_MALICIOUS_GAMING_BEHAVIOR
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_23,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_AFK_RUNNING_AWAY,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_MALICIOUS_GAMING_BEHAVIOR
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_7,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_9,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_GAME_SCENSE_OTHERS,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_USE_CHEATING_TOOLS
      }
    }
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_DYNAMIC_POSTS_SCENE then
    self.ReportContentList = {
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_1,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_INSULT_AND_ABUSE,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_2,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_TRAFFIC_ADVERTISING,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_3,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PORNOGRAPHIC_AND_VULGAR,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_4,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CONTENT_INVOLVES_POLITICS,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_5,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_HARASSMENT,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_6,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_VIOLENCE_AND_BLOODSHED,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_8,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_FRAUDULENT_INFORMATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_7,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_9,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CHAT_OTHER,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      }
    }
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_COMMENT_AND_MESSAGE_SCENE then
    self.ReportContentList = {
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_1,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_INSULT_AND_ABUSE,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_2,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_TRAFFIC_ADVERTISING,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_3,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PORNOGRAPHIC_AND_VULGAR,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_4,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CONTENT_INVOLVES_POLITICS,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_5,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_HARASSMENT,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_6,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_VIOLENCE_AND_BLOODSHED,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_8,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_FRAUDULENT_INFORMATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_7,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
      },
      {
        IsCheck = false,
        Text = LuaText.umg_friend_report_9,
        Parent = self,
        ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CHAT_OTHER,
        ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_VIOLATING_CONTENT
      }
    }
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE then
    if 2 == data.business_data.report_entrance then
      self.ReportContentList = {
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_5,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_INSULT_AND_ABUSE_705,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_friend_report_7,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NICKNAME_VIOLATION,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_PERSONAL_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_4,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CONTENT_INVOLVES_POLITICS_704,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_6,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_FRAUDULENT_INFORMATION_706,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_3,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PORNOGRAPHIC_AND_VULGAR_703,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_7,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_OTHER_799,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_report_1,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_NON_GAMING_PHOTOS,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        }
      }
    else
      self.ReportContentList = {
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_2,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_ROOM_NAME_INVALID_701,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_3,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_PORNOGRAPHIC_AND_VULGAR_703,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_4,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_CONTENT_INVOLVES_POLITICS_704,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_5,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_INSULT_AND_ABUSE_705,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_6,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_FRAUDULENT_INFORMATION_706,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        },
        {
          IsCheck = false,
          Text = LuaText.umg_homestead_report_7,
          Parent = self,
          ReportType = _G.ProtoEnum.SafetyBusinessInfo.ReportReason.RPTRS_OTHER_799,
          ReportCategory = ProtoEnum.SafetyBusinessInfo.ReportCategory.RPTCAT_ORGANIZATION_INFORMATION
        }
      }
    end
  end
  self.NRCGridView_128:InitGridView(self.ReportContentList)
end

function UMG_Friend_Report_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClose
  CommonPopUpData.Btn_RightHandler = self.OnConfirm
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp2:SetPanelInfo(CommonPopUpData)
end

function UMG_Friend_Report_C:SetPopUpBtn(IsShowRight, IsShowRightGrayState)
  self.PopUp2:ShowOrHideBtnRight(IsShowRight)
  self.PopUp2:SetBtnRightGrayState(IsShowRightGrayState)
end

function UMG_Friend_Report_C:OnInitReportItem(Index, Item)
  if not self.ReportItems[Index] then
    self.ReportItems[Index] = Item
  end
end

function UMG_Friend_Report_C:SetReportContentListInfo(_IsCheck, Index)
  if self.ReportContentList[Index] then
    if _IsCheck then
      self.SelectCount = self.SelectCount + 1
    else
      self.SelectCount = self.SelectCount - 1
    end
    self.ReportContentList[Index].IsCheck = _IsCheck
  end
  if self:IsSelect() then
    self:SetPopUpBtn(true, false)
  else
    self:SetPopUpBtn(false, true)
  end
end

function UMG_Friend_Report_C:OnSelectItem(Index)
  local LastSelect = self.SingleSelect_CurIndex
  local ReportScene = self.data.business_data.report_scene
  if ReportScene ~= ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_PERSONAL_INFORMATION_SCENE and ReportScene ~= ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE and 0 ~= LastSelect then
    self:SetReportContentListInfo(false, LastSelect)
    self.ReportItems[LastSelect]:SetIsCheck(false)
  end
  self.SingleSelect_CurIndex = Index
end

function UMG_Friend_Report_C:IsSelect()
  for i, List in ipairs(self.ReportContentList) do
    if List.IsCheck then
      return true
    end
  end
  return false
end

function UMG_Friend_Report_C:OnDeactive()
  if self.closeCallback and self.closeCallbackCaller then
    Log.Info("UMG_Friend_Report_C:OnDeactive call closeCallback")
    tcall(self.closeCallbackCaller, self.closeCallback)
  end
  self.closeCallback = nil
  self.closeCallbackCaller = nil
end

function UMG_Friend_Report_C:OnAddEventListener()
  self.InputBox.OnTextChanged:Add(self, self.OnTextChanged)
  self.InputBox.OnTextEndTransaction:Add(self, self.OnTextEndTransaction)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_REPORT_SAFETY_DATA_RSP, self.UnlockConfirmButton)
end

function UMG_Friend_Report_C:OnTextChanged()
  if self._isPinYin then
    return
  end
  local text = self.InputBox:GetSelectedText()
  if text and "" ~= text then
    self._isPinYin = true
    return
  end
  self.NewInput = self.InputBox:GetText()
  local MaxCount = _G.DataConfigManager:GetFriendGlobalConfig("expose_reason_describe_num_max").num
  local MaxContent, CurrentNum = string.GetSubStr(self.NewInput, MaxCount)
  if MaxCount <= CurrentNum and self.NewInput ~= MaxContent then
    self.InputBox:SetText(MaxContent)
  end
end

function UMG_Friend_Report_C:OnTextEndTransaction()
  self._isPinYin = false
  self:OnTextChanged()
end

function UMG_Friend_Report_C:OnConfirm()
  if self.Lock then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401019, "UMG_Friend_Report_C:OnConfirm")
  local ReportType = {}
  local ReportCategory
  for i, List in ipairs(self.ReportContentList) do
    if List.IsCheck then
      table.insert(ReportType, List.ReportType)
      ReportCategory = List.ReportCategory
    end
  end
  if #ReportType <= 0 then
    local Text = _G.DataConfigManager:GetLocalizationConf("expose_reason_tips").msg
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  local business_data = self.data.business_data
  business_data.report_reason = ReportType
  business_data.report_desc = self.InputBox:GetText()
  business_data.report_category = ReportCategory
  business_data.reported_profile_url = "default"
  local reportScene = self.data.business_data.report_scene
  if reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_CONVERSATION_SPEAKING_SCENE then
    business_data.report_content = self.data.business_data.report_content
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_PERSONAL_INFORMATION_SCENE then
    business_data.report_content = self.data.business_data.signature
    if self.data.business_data.reported_card_url and self.data.business_data.reported_card_name then
      business_data.pic_url_array = {}
      business_data.callback = self.data.business_data.reported_card_name
      table.insert(business_data.pic_url_array, self.data.business_data.reported_card_url)
    end
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_GAME_MATCH_SCENE then
    business_data.report_battle_id = tostring(self.data.business_data.report_battle_id)
    business_data.report_battle_time = self.data.business_data.report_battle_time
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_DYNAMIC_POSTS_SCENE or reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_COMMENT_AND_MESSAGE_SCENE then
    business_data.report_content = self.data.business_data.report_content
    business_data.callback = self.data.business_data.callback
  elseif reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE and 2 ~= business_data.report_entrance then
    business_data.report_content = self.data.business_data.homeName
    business_data.callback = "{\"homeid\":" .. "\"" .. self.data.business_data.masterId .. "\"" .. "}"
  end
  local MaxCount = _G.DataConfigManager:GetFriendGlobalConfig("expose_reason_describe_num_max").num
  local reportDescLength = string.StringGetTotalNum(business_data.report_desc)
  if MaxCount < reportDescLength then
    local Text = _G.DataConfigManager:GetLocalizationConf("expose_overlimit_tips").msg
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE and 2 ~= business_data.report_entrance then
    local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
    if playerInfo.uin == business_data.masterId then
      Log.Error("UMG_Friend_Report_C:OnConfirm==\228\184\141\232\131\189\232\135\170\229\183\177\228\184\190\230\138\165\232\135\170\229\183\177\239\188\129\239\188\129\239\188\129")
      return
    end
    self:IsLock(true)
    self.UploadScreenShotUrlBegin = false
    self.UploadHomeReportSuccessBegin = false
    self.UploadScreenShotHttpSuccessBegin = false
    self.EventListener = TimeoutEventListener()
    self.HomeBusinessData = business_data
    self:OnScreenshot()
  else
    self.PopUp2.Btn_Right:SetIsEnabled(false)
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.ReportPlayer, self.data.uin, business_data)
  end
end

function UMG_Friend_Report_C:UnlockConfirmButton()
  self.PopUp2.Btn_Right:SetIsEnabled(true)
end

function UMG_Friend_Report_C:OnAnimationFinished(Animation)
  if Animation == self.In then
    self:PlayAnimation(self.Loop)
  elseif Animation == self.Out then
    self:OnClosePanel()
  end
end

function UMG_Friend_Report_C:IsLock(_Lock)
  self.Lock = _Lock
end

function UMG_Friend_Report_C:OnClose()
  if self.Lock then
    return
  end
  self:IsLock(true)
  _G.NRCAudioManager:PlaySound2DAuto(41401019, "UMG_Friend_Report_C:OnConfirm")
  if self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self:OnClosePanel()
  else
    self:PlayAnimation(self.Out)
  end
end

function UMG_Friend_Report_C:OnPcClose()
  self:OnClose()
end

function UMG_Friend_Report_C:CheckIsSelectEnough()
  local ReportScene = self.data.business_data.report_scene
  if ReportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE then
    local maxCount = tonumber(LuaText.umg_homestead_report_11)
    if self.SelectCount == maxCount then
      local tipsDesc = string.format(LuaText.umg_homestead_report_10, maxCount)
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tipsDesc)
      return true
    end
  end
  return false
end

function UMG_Friend_Report_C:OnScreenshot()
  local function cb()
    self:CancelDelayId()
    
    self.GMPlatformKits = UE4.UMoreFunPlatformKits
    self.ScreenShotService = self.GMPlatformKits.CreateScreenShotService()
    self.ScreenShotServiceRef = UnLua.Ref(self.ScreenShotService)
    self.HttpService = self.GMPlatformKits.CreateSimpleHttpService()
    self.HttpServiceRef = UnLua.Ref(self.HttpService)
    self.FileName = "HomeScreenShot" .. tostring(os.time())
    self:_DoReqScreenShot(self.FileName, function(bIsSuccess, SavePath, Service)
      if bIsSuccess then
        self:ScreenShotFinishSuccess(SavePath)
      else
        self:IsLock(false)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
        self:OnClosePanel()
      end
    end)
  end
  
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.delayId = _G.DelayManager:DelaySeconds(0.2, cb, self)
end

function UMG_Friend_Report_C:_DoReqScreenShot(FileName, Callback, bShowUI)
  self.ScreenShotService:RequestScreenshot({
    self.ScreenShotService,
    function(Service, Status)
      Callback(Status == UE4.EHttpServiceStatus.RspSuccess, Service:GetSavedFilePath(), Service)
    end
  }, FileName, bShowUI or false)
end

function UMG_Friend_Report_C:ScreenShotFinishSuccess(SavePath)
  self.SavePath = SavePath
  local req = _G.ProtoMessage:newZoneGetCosUploadUrlReq()
  req.type = 3
  req.file_name = self.FileName
  req.file_size = UE.UNRCStatics.GetFileSize(self.FileName)
  req.file_md5 = UE.UNRCStatics.HashFileMD5(self.FileName)
  req.client_version = AppMain.AppVersion
  local rspWrapper = {}
  rspWrapper.handler = _G.MakeWeakFunctor(self, self.OnZoneGetCosUploadUrlRsp)
  rspWrapper.reqMsg = req
  rspWrapper.full_path_filename = self.FileName
  
  local function OnSvrRspHandle(_rspWrapper, _protoData)
    if _rspWrapper then
      _rspWrapper.handler(_protoData, _rspWrapper.reqMsg, _rspWrapper.full_path_filename, _rspWrapper.custom_data)
    end
  end
  
  self.UploadScreenShotUrlBegin = true
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_COS_UPLOAD_URL_REQ, req, rspWrapper, OnSvrRspHandle)
  self.EventListener:StartGlobalEventListener(2.0, self.name, self, FriendModuleEvent.OnUploadScreenShotUrl, self.OnUploadScreenShotUrlCallBack)
end

function UMG_Friend_Report_C:OnUploadScreenShotUrlCallBack()
  if not self.UploadScreenShotUrlBegin then
    return
  end
  self.UploadScreenShotUrlBegin = false
  self:IsLock(false)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
  self:OnClosePanel()
end

function UMG_Friend_Report_C:OnZoneGetCosUploadUrlRsp(Rsp, Req, FullFileName, CustomData)
  if not self.UploadScreenShotUrlBegin then
    return
  end
  self.EventListener:Stop()
  self.UploadScreenShotUrlBegin = false
  if 0 == Rsp.ret_info.ret_code then
    self:UploadScreenShot(Rsp)
  else
    self:IsLock(false)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
    self:OnClosePanel()
  end
end

function UMG_Friend_Report_C:UploadScreenShot(Rsp)
  self.UploadScreenShotHttpSuccessBegin = true
  self.EventListener:StartGlobalEventListener(2.0, self.name, self, FriendModuleEvent.OnUploadScreenShotHttp, self.OnUploadScreenShotHttpCallBack)
  self:_DoReqPutImage(Rsp.url, self.SavePath, function(bUploadSuccess, UploadRsp)
    if not self.UploadScreenShotHttpSuccessBegin then
      return
    end
    self.UploadScreenShotHttpSuccessBegin = false
    self.EventListener:Stop()
    if bUploadSuccess then
      if self.HomeBusinessData then
        self.UploadHomeReportSuccessBegin = true
        self.HomeBusinessData.pic_url_array = {
          Rsp.access_url
        }
        _G.NRCModuleManager:DoCmd(FriendModuleCmd.ReportPlayer, self.data.uin, self.HomeBusinessData)
        self.EventListener:StartGlobalEventListener(2.0, self.name, self, FriendModuleEvent.OnUploadHomeReport, self.OnUploadHomeReportCallBack)
      end
      self.HomeBusinessData = nil
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
      self:IsLock(false)
      self:OnClosePanel()
    end
  end)
end

function UMG_Friend_Report_C:OnUploadScreenShotHttpCallBack()
  if not self.UploadScreenShotHttpSuccessBegin then
    return
  end
  self.UploadScreenShotHttpSuccessBegin = false
  self:IsLock(false)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
  self:OnClosePanel()
end

function UMG_Friend_Report_C:OnUploadHomeReportCallBack()
  if not self.UploadHomeReportSuccessBegin then
    return
  end
  self.UploadHomeReportSuccessBegin = false
  _G.NRCModuleManager:DoCmd(FriendModuleCmd.CloseFriendInfoFrame)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
  self:IsLock(false)
  self:OnClosePanel()
end

function UMG_Friend_Report_C:_DoReqPutImage(Url, FilePath, Callback)
  self.HttpService:ResetHeaders()
  self.HttpService:ResetFields()
  self.HttpService:SetHeader("Content-Type", "image/png")
  self.HttpService:SetFile(FilePath)
  self.HttpService:SetUrl(Url)
  self.HttpService:SetVerb("PUT")
  self.HttpService:Request({
    self.HttpService,
    function(HttpService, Status)
      Callback(Status == UE4.EHttpServiceStatus.RspSuccess, HttpService:GetRspContent())
    end
  })
end

function UMG_Friend_Report_C:CancelDelayId()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

function UMG_Friend_Report_C:OnClosePanel()
  self:CancelDelayId()
  if self.EventListener then
    self.EventListener:Cleanup()
  end
  self:DoClose()
end

function UMG_Friend_Report_C:ClosePanelWithHomeReport()
  local reportScene = self.data.business_data.report_scene
  if reportScene == ProtoEnum.SafetyBusinessInfo.ReportScense.RPTSS_ORGANIZATION_INFORMATION_SCENE then
    self:OnClosePanel()
  end
end

function UMG_Friend_Report_C:OnRelogin()
  if self.delayId then
    self:CancelDelayId()
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_homestead_report_9)
  end
  self:IsLock(false)
end

return UMG_Friend_Report_C
