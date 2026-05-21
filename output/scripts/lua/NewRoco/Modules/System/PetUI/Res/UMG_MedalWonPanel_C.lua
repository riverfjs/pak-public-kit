local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_MedalWonPanel_C = _G.NRCPanelBase:Extend("UMG_MedalWonPanel_C")

function UMG_MedalWonPanel_C:OnConstruct()
  self.PetData = nil
  self.MedalList = nil
  self.SelectMedal = nil
  self.WearMedal = nil
  self.IsOpenDialog = true
  self.Index = 1
  self:OnAddEventListener()
  self:SetCommonTitle()
end

function UMG_MedalWonPanel_C:OnDestruct()
end

function UMG_MedalWonPanel_C:OnActive(_PetData)
  if _G.GlobalConfig.DebugOpenUI then
    NRCModeManager:GetCurMode():DisablePanelByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  self.SkipAudio = true
  self.PetData = _PetData
  if _PetData then
    self.Title1:SetSubtitle(_PetData.name)
  end
  self:SetPanelInfo()
  if self.WearMedal then
    self:PlayAnimation(self.Own_In)
  else
    self:PlayAnimation(self.Non_in)
  end
end

function UMG_MedalWonPanel_C:OnDeactive()
end

function UMG_MedalWonPanel_C:OnAddEventListener()
  self:AddButtonListener(self.ButtonLeft, self.OnClickButtonLeft)
  self:AddButtonListener(self.ButtonRight, self.OnClickButtonRight)
  self:AddButtonListener(self.Btn.btnLevelUp, self.OperationBtn)
  self:AddButtonListener(self.UMG_btnClose.btnClose, self.OnClosePanel)
  self:RegisterEvent(self, PetUIModuleEvent.SelectMedalItemEvent, self.OnSelectMedalItem)
  self:RegisterEvent(self, PetUIModuleEvent.PetWearMedalEvent, self.OnPetWearMedalEvent)
  self.OnPcCloseHandler = self.OnClosePanel
end

function UMG_MedalWonPanel_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_MedalWonPanel_C:SetPanelInfo()
  self:SetMedalList()
end

function UMG_MedalWonPanel_C:SetBaseInfo()
  local curPage = self.ScrollPageController.curPage
  if curPage > 0 then
    self.ButtonLeft:SetIsEnabled(true)
  else
    self.ButtonLeft:SetIsEnabled(false)
  end
  local pageNum = self.ScrollPageController:GetTotalPageNum()
  if pageNum > 1 then
    self.ButtonLeft:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonRight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  elseif 1 == pageNum then
    for i, Medal in ipairs(self.MedalList) do
      if not Medal.PetData then
        self.ButtonLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.ButtonRight:SetVisibility(UE4.ESlateVisibility.Collapsed)
        return
      end
    end
    self.ButtonLeft:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonRight:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonLeft:SetIsEnabled(false)
    self.ButtonRight:SetIsEnabled(false)
  else
    self.ButtonLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ButtonRight:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MedalWonPanel_C:OnPetWearMedalEvent(medalData)
  self:UpdateMedalList(medalData)
end

function UMG_MedalWonPanel_C:UpdateMedalList(medalData)
  for i, v in ipairs(self.MedalList) do
    if v then
      local Medal = v.MedalData
      if Medal and medalData and Medal.conf_id == medalData.conf_id and Medal.medal_type == medalData.medal_type and Medal.owner_id == medalData.owner_id then
        Medal = medalData
        if Medal.conf_id == self.SelectMedal.conf_id and Medal.medal_type == self.SelectMedal.medal_type and Medal.owner_id == self.SelectMedal.owner_id then
          self.SelectMedal = Medal
        end
        local Item = self.GridView:GetItemByIndex(i - 1)
        if Item then
          Item:UpdateItemInfo(Medal)
        end
      end
    end
  end
  local MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
  self.WearMedal = WearMedal
  self:UpdateEquipmentInfo(self.SelectMedal)
  self:SetBtnState()
end

function UMG_MedalWonPanel_C:SetMedalList(bSort)
  if not self.PetData then
    local PetDataList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    self.PetData = PetDataList[1]
    self.Btn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local MedalListData = {}
  local MedalList, WearMedal
  if not self.MedalList or not (#self.MedalList > 0) then
    MedalList, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
    if not bSort and MedalList then
      table.sort(MedalList, function(a, b)
        local Time_A = a.add_time or 0
        local Time_B = b.add_time or 0
        if a.is_wear then
          Time_A = 999999999999
        end
        if b.is_wear then
          Time_B = 999999999999
        end
        if a.is_wear and (not a.wear_pet_gid or 0 == a.wear_pet_gid or a.wear_pet_gid == self.PetData.gid) then
          Time_A = Time_A + 1
        end
        if b.is_wear and (not b.wear_pet_gid or 0 == b.wear_pet_gid or b.wear_pet_gid == self.PetData.gid) then
          Time_B = Time_B + 1
        end
        return Time_A > Time_B
      end)
    end
    self.NRCText_3:SetText(#MedalList)
    for i, Medal in ipairs(MedalList) do
      table.insert(MedalListData, {
        MedalData = Medal,
        PetData = self.PetData
      })
    end
    local itemNum = #MedalListData
    local itemNumPerPage
    if itemNum <= 9 then
      itemNumPerPage = 9
    else
      itemNumPerPage = 12
    end
    local lastPageItemNum = itemNum % itemNumPerPage
    if 0 ~= lastPageItemNum then
      local missingItemNum = itemNumPerPage - lastPageItemNum
      for i = 1, missingItemNum do
        table.insert(MedalListData, {})
      end
    end
    self.WearMedal = WearMedal
  else
    local Text
    Text, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.PetData.gid)
    self.WearMedal = WearMedal
  end
  if not self.MedalList or not (#self.MedalList > 0) then
    self.MedalList = MedalListData
  end
  self.GridView:InitGridView(self.MedalList)
  self.GridView:SelectItemByIndex(self.Index - 1)
end

function UMG_MedalWonPanel_C:OnSelectMedalItem(Item, Index)
  if self.SkipAudio then
    self.SkipAudio = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(40002006, "UMG_MedalPanel_C:OnClickButton_EquippableMedal")
  end
  if nil == Item then
    return
  end
  local MedalConf = _G.DataConfigManager:GetMedalConf(Item.conf_id)
  local medalUIType = MedalConf.medal_ui_format
  local TextData_1 = ""
  if medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_1 then
    self.NRCText_7:SetText(LuaText.get_medal_form_2)
    local extData = Item.ext_data
    if extData then
      local dataTable = os.date("*t", extData.num_1)
      local natureStr = string.format("H5_callback_medal_nature%d", extData.num_2)
      local natureDesc = ActivityUtils.GetActivityGlobalConfig(natureStr).str
      local confStr = _G.DataConfigManager:GetLocalizationConf("medal_bff_text2").msg
      TextData_1 = string.format(confStr, dataTable.year, dataTable.month, dataTable.day, natureDesc, extData.num_3)
    end
    self.NRCText_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SizeBox_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCText_7:SetText(LuaText.get_medal_form_3)
    local Name
    if Item.medal_type == _G.Enum.MedalType.MT_IND then
      Name = self.PetData.name
    elseif Item.medal_type == _G.Enum.MedalType.MT_SPECIES or Item.medal_type == _G.Enum.MedalType.MT_BOND then
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(Item.obtain_pet_gid)
      if PetData then
        Name = PetData.name
      else
        Name = Item.obtain_pet_name
      end
    end
    if not Name then
      Log.Error("\229\144\142\229\143\176\230\149\176\230\141\174\229\135\186\233\151\174\233\162\152,\232\175\183\229\144\142\229\143\176\230\159\165\231\156\139\229\142\159\229\155\160")
    end
    local formatDesc = MedalConf.desc
    if medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 or medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_4 then
      local medalLevelInfo = UIUtils.GetMedalLevelInfo(Item.conf_id, Item.complete_cnt)
      if medalLevelInfo then
        formatDesc = medalLevelInfo.task_desc2
      end
    end
    TextData_1 = string.format(formatDesc or "", Name)
    self.NRCText_8:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SizeBox_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_2 then
      local extData = Item.ext_data
      local TextData = ""
      if extData then
        TextData = os.date(LuaText.medal_text_5, extData.num_1)
      else
        TextData = os.date(LuaText.medal_text_5, Item.add_time)
      end
      self.Tex_1:SetText(TextData)
    else
      local AddTime = os.date(LuaText.medal_text_5, Item.add_time)
      local msg = _G.DataConfigManager:GetLocalizationConf("get_medal_form_1").msg
      local TextData = string.format(msg, AddTime, Name)
      self.Tex_1:SetText(TextData)
    end
  end
  local iconPath = MedalConf.big_icon
  if medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 or medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_4 then
    local medalLevelInfo = UIUtils.GetMedalLevelInfo(Item.conf_id, Item.complete_cnt)
    if medalLevelInfo then
      iconPath = medalLevelInfo.big_icon2
    end
  end
  self.Icon:SetPath(iconPath)
  self.Tex:SetText(TextData_1)
  self.NRCText_5:SetText(MedalConf.name)
  self:UpdateEquipmentInfo(Item)
  self.NRCText_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Tex_Defeat:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText_DefeatQuantity:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if Item.complete_cnt and Item.complete_cnt > 0 then
    if MedalConf.can_repeat_get and MedalConf.can_repeat_get > 0 then
      if MedalConf.repeat_get_award and #MedalConf.repeat_get_award > 0 and Item.complete_cnt >= MedalConf.repeat_get_award[1].count then
        self.NRCText_4:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("73C615FF"))
        self.Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Achieved_png.img_Medal_Achieved_png'")
        self:PlayAnimation(self.Achieved_in)
      else
        self.NRCText_4:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("62605eFF"))
        self.Bg:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_Medal_Achieved2_png.img_Medal_Achieved2_png'")
      end
      self.Achieved:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Line_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCText_4:SetText(Item.complete_cnt)
    else
      self.Achieved:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if medalUIType == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 then
      self.NRCText_2:SetText(LuaText.get_medal_form_4)
      self.Tex_Defeat:SetText(LuaText.get_medal_form_5)
      local totalCount = _G.DataConfigManager:GetPetEvolutionChainCount()
      self.NRCText_DefeatQuantity:SetText(string.format("(%d/%d)", Item.complete_cnt, totalCount))
      self.NRCText_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Tex_Defeat:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCText_DefeatQuantity:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local medalLevelInfo = UIUtils.GetMedalLevelInfo(Item.conf_id, Item.complete_cnt)
      if medalLevelInfo and medalLevelInfo.ui_param2 then
        local params = medalLevelInfo.ui_param2:split(";")
        if params and #params >= 2 then
          self.NRCText_4:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(params[1]))
          self.Bg:SetPath(params[2])
        end
        self.Achieved:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Line_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NRCText_4:SetText(Item.complete_cnt)
        self:PlayAnimation(self.Achieved_in)
      end
    end
  else
    self.Achieved:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if not MedalConf.prefix_text or "" == MedalConf.prefix_text then
    self.NRCText_9:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCText_10:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Line_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCText_9:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_10:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Line_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local TextData = string.format("%s%s", MedalConf.prefix_text, self.PetData.name)
    self.NRCText_10:SetText(TextData)
  end
  self.SelectMedal = Item
  self.Index = Index
  self:SetBtnState()
end

function UMG_MedalWonPanel_C:UpdateEquipmentInfo(Item)
  Log.Dump(Item, 6, "UMG_MedalWonPanel_C:UpdateEquipmentInfo")
  if Item.is_wear and Item.wear_pet_gid and self.PetData.gid == Item.wear_pet_gid then
    self.Equipped:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Equipped:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if Item.is_wear and Item.owner_id and 0 ~= Item.wear_pet_gid and Item.wear_pet_gid ~= self.PetData.gid then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(Item.wear_pet_gid)
    if PetData then
      local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
      if PetBaseConf then
        local model_conf = _G.DataConfigManager:GetModelConf(PetBaseConf.model_conf)
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.HeadIcon:SetPath(model_conf.icon)
      end
    end
  else
    self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_MedalWonPanel_C:OnClickButtonLeft()
  if self.ScrollPageController.curPage > 0 then
    local Success = self.ScrollPageController:ScrollToPage(self.ScrollPageController.curPage - 1, 0.5, true)
  end
end

function UMG_MedalWonPanel_C:OnClickButtonRight()
  if self.ScrollPageController.curPage < self.ScrollPageController:GetTotalPageNum() - 1 then
    local Success = self.ScrollPageController:ScrollToPage(self.ScrollPageController.curPage + 1, 0.5, true)
  end
end

function UMG_MedalWonPanel_C:OnPageChangeHandle(_page)
  self.Dot_List:SelectItemByIndex(_page)
end

function UMG_MedalWonPanel_C:SetBtnState()
  if self.WearMedal then
    if self.WearMedal.conf_id == self.SelectMedal.conf_id and self.WearMedal.owner_id == self.SelectMedal.owner_id then
      self.Btn:SetBtnText(LuaText.medal_text_7)
    elseif self.SelectMedal.is_wear and self.SelectMedal.wear_pet_gid ~= self.PetData.gid then
      self.Btn:SetBtnText(LuaText.medal_text_8)
    else
      self.Btn:SetBtnText(LuaText.medal_text_9)
    end
  elseif self.SelectMedal.is_wear and self.SelectMedal.wear_pet_gid == self.PetData.gid then
    self.Btn:SetBtnText(LuaText.medal_text_7)
  elseif self.SelectMedal.is_wear and self.SelectMedal.wear_pet_gid ~= self.PetData.gid then
    self.Btn:SetBtnText(LuaText.medal_text_8)
  else
    self.Btn:SetBtnText(LuaText.medal_text_9)
  end
end

function UMG_MedalWonPanel_C:OperationBtn()
  local Type = _G.ProtoEnum.PetMedalAction.PMA_WEAR
  local Name = ""
  if self.WearMedal then
    if self.WearMedal.conf_id == self.SelectMedal.conf_id and self.WearMedal.owner_id == self.SelectMedal.owner_id then
      Type = _G.ProtoEnum.PetMedalAction.PMA_TAKE_OFF
    else
      if not self.SelectMedal.is_wear or self.SelectMedal.wear_pet_gid == self.PetData.gid then
        self.IsOpenDialog = false
      end
      Type = _G.ProtoEnum.PetMedalAction.PMA_REPLACE
      local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.SelectMedal.wear_pet_gid)
      if PetData then
        Name = PetData.name
      end
    end
  elseif self.SelectMedal.is_wear and self.SelectMedal.wear_pet_gid == self.PetData.gid then
    Type = _G.ProtoEnum.PetMedalAction.PMA_TAKE_OFF
  elseif self.SelectMedal.is_wear and self.SelectMedal.wear_pet_gid ~= self.PetData.gid then
    Type = _G.ProtoEnum.PetMedalAction.PMA_REPLACE
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.SelectMedal.wear_pet_gid)
    if PetData then
      Name = PetData.name
    end
  else
    Type = _G.ProtoEnum.PetMedalAction.PMA_WEAR
  end
  if Type == _G.ProtoEnum.PetMedalAction.PMA_REPLACE and self.IsOpenDialog then
    local function OpenLegendIFCatchPanelFunc()
      local Ctx = DialogContext()
      
      local consumeTicket = DataConfigManager:GetLocalizationConf("medal_tips1").msg
      local name = Name
      local tips = string.format(consumeTicket, name)
      Ctx:SetContent(tips)
      Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
      Ctx:SetTitle(LuaText.TIPS)
      Ctx:SetClickAnywhereClose(true)
      Ctx:SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel)
      Ctx:SetCallback(self, self.OpenDialog)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    end
    
    OpenLegendIFCatchPanelFunc()
  else
    if Type == _G.ProtoEnum.PetMedalAction.PMA_WEAR then
      _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_MedalPanel_C:OnClickButton_EquippableMedal")
    elseif Type == _G.ProtoEnum.PetMedalAction.PMA_REPLACE then
      _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_MedalPanel_C:OnClickButton_EquippableMedal")
    elseif Type == _G.ProtoEnum.PetMedalAction.PMA_TAKE_OFF then
      _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_MedalPanel_C:OnClickButton_EquippableMedal")
    end
    if self.PetData.gid and self.SelectMedal.conf_id then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.MedalOperation, Type, self.PetData.gid, self.SelectMedal.conf_id)
    end
  end
end

function UMG_MedalWonPanel_C:OpenDialog(_ok)
  if _ok and self.PetData.gid and self.SelectMedal.conf_id then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.MedalOperation, _G.ProtoEnum.PetMedalAction.PMA_REPLACE, self.PetData and self.PetData.gid, self.SelectMedal.conf_id)
  end
end

function UMG_MedalWonPanel_C:OnClosePanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002014, "UMG_MedalWonPanel_C:OnClosePanel")
  if _G.GlobalConfig.DebugOpenUI then
    self:DoClose()
    NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(_G.Enum.UILayerType.UI_LAYER_MAIN)
    return
  end
  self:DispatchEvent(PetUIModuleEvent.OpenDetailPanelEvent, false, true)
  if not self.module:HasPanel("NewPetBag") then
    self:DispatchEvent(PetUIModuleEvent.SetPetHiddenInGame, false)
  end
  self:RemoveAllRed()
  if self.WearMedal then
    self:PlayAnimation(self.Own_out)
  else
    self:PlayAnimation(self.Non_out)
  end
end

function UMG_MedalWonPanel_C:RemoveAllRed()
  for i, Medal in ipairs(self.MedalList) do
    local Item = self.GridView:GetItemByIndex(i - 1)
    if Item then
      Item:SetOnNewStateRemove()
    end
  end
end

function UMG_MedalWonPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Own_out or Anim == self.Non_out then
    self:DispatchEvent(PetUIModuleEvent.CloseMedalWonPanel)
    self:DoClose()
  end
end

return UMG_MedalWonPanel_C
