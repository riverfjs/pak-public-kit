local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local HandbookModuleEvent = reload("NewRoco.Modules.System.Handbook.HandbookModuleEvent")
local HandbookModuleCmd = reload("NewRoco.Modules.System.Handbook.HandbookModuleCmd")
local HandbookModuleEnum = require("NewRoco.Modules.System.Handbook.HandbookModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PetPhotoListView = require("NewRoco.Modules.System.TakePhotos.Common.PetPhotos.PetPhotoListView")
local UMG_HandbookContent_C = _G.NRCViewBase:Extend("UMG_HandbookContent_C")

local function FormatFloat(_value)
  local formatted = string.format("%.3f", _value or 0)
  formatted = string.gsub(formatted, "0+$", "")
  formatted = string.gsub(formatted, "%.$", "")
  return tonumber(formatted)
end

function UMG_HandbookContent_C:OnConstruct()
  self.OpenUIAdjustTool = false
  self.RequestProjectionIcon = nil
  self.RequestBg = nil
  self.PetBaseConf = nil
  self.previewWorld:OnConstruct()
  self.HadNormalForm = false
  self.CurPhotoTabIndex = 1
  self.PetPhotoListView = PetPhotoListView(self.PhotoList, self.PhotoScrollBox_0)
  self.PetPhotoListView.OnPhotosRemovedDelegate:Add(self, self.OnRefreshPhotoNum)
  self:OnAddEventListener()
end

function UMG_HandbookContent_C:OnActive(isPlayAnim)
  self.PetPhotoListView:Active()
  self.module = _G.NRCModuleManager:GetModule("HandbookModule")
  self.data = self.module:GetData("HandbookModuleData")
  self.IsCanPlayAnima = isPlayAnim
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  self.NRCSwitcher_0:SetActiveWidgetIndex(player.gender - 1)
  self.handbook_describe1_percent = _G.DataConfigManager:GetPetGlobalConfig("handbook_describe1_percent").num / 10000
  self.handbook_describe2_percent = _G.DataConfigManager:GetPetGlobalConfig("handbook_describe2_percent").num / 10000
  local areaId = _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.GetCurAreaHandbookId)
  local areaConf = _G.DataConfigManager:GetAreaHandbook(areaId)
  self.NRCImage_6:SetPath(areaConf.inside_open_btn)
  self.Name:SetText(areaConf.bg_name)
  self.RequestBg = _G.NRCResourceManager:LoadResAsync(self, areaConf.bottom_cover_res, 255, 0, self.OnBgResLoadComplete, nil)
  self.NRCImage_17:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCImage_18:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.curChargeIndex = 0
  self.curRecord = nil
  self.curRecordState = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND_FOUND
  self.buttonDisableFlag = false
  self.ButtonLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:PlayBookOpen()
end

function UMG_HandbookContent_C:OnDeactive()
  self.PetPhotoListView:Deactivate()
end

function UMG_HandbookContent_C:ShowPetPhotos(HandbookId)
  self.NRCSwitcher_2:SetActiveWidgetIndex(1)
  self.PetPhotoListView:Show(HandbookId or self.curHandbookId)
  self:OnRefreshPhotoNum()
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCloseDazzlingPopUp)
  self.Information:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ShowDefaultMutationBtnStyle()
end

function UMG_HandbookContent_C:OnRefreshPhotoNum()
  if not self.PetPhotoListView then
    return
  end
  local ItemCount = self.PetPhotoListView:GetDisplayPhotoNum()
  self.Quantity_1:SetText(string.format(LuaText.handbook_tab_text_3, ItemCount))
end

function UMG_HandbookContent_C:ShowPetContent()
  self.NRCSwitcher_2:SetActiveWidgetIndex(0)
end

function UMG_HandbookContent_C:PlayBookOpen()
  if self.IsCanPlayAnima then
    self:PlayAnimation(self.Book_Open)
  else
    self:PlayAnimation(self.Change)
  end
end

function UMG_HandbookContent_C:PlayCloseAnimation()
  if self.IsCanPlayAnima then
    self:PlayAnimationReverse(self.Book_Open)
  end
end

function UMG_HandbookContent_C:OnDestruct()
  self.data:SetSelectLeftListItemUI(nil)
  self:RemoveButtonListener(self.BtnTrophy, self.OnClickBtnTrophy)
  self:RemoveButtonListener(self.Btn_Dazzling_1.btnLevelUp, self.ClickShiningToggle)
  self:RemoveButtonListener(self.Btn_Dazzling.btnLevelUp, self.ClickGlassToggle)
  self:RemoveButtonListener(self.Btn_Dazzling_2.btnLevelUp, self.ClickShiningGlassToggle)
  self:UnRegisterEvent(self, HandbookModuleEvent.SetSelectedItemUpdatePanel)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangeAreaData)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangCurBookPreviewWorld)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnCloseDazzlingPopUp)
  self:UnRegisterEvent(self, HandbookModuleEvent.OnChangeSelectPhotoSwitcher)
  _G.NRCEventCenter:UnRegisterEvent(self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
  if self.RequestProjectionIcon then
    _G.NRCResourceManager:UnLoadRes(self.RequestProjectionIcon)
    self.RequestProjectionIcon = nil
  end
  if self.RequestBg then
    _G.NRCResourceManager:UnLoadRes(self.RequestBg)
    self.RequestBg = nil
  end
end

function UMG_HandbookContent_C:OnAddEventListener()
  self.Btn_Left.OnPressed:Add(self, self.OnBtnLeftPressed)
  self.Btn_Left.OnReleased:Add(self, self.OnBtnLeftReleased)
  self.Btn_Right.OnPressed:Add(self, self.OnBtnRightPressed)
  self.Btn_Right.OnReleased:Add(self, self.OnBtnRightReleased)
  self:AddButtonListener(self.BtnTrophy, self.OnClickBtnTrophy)
  self:AddButtonListener(self.Btn_recommend.btnLevelUp, self.OnRecommend)
  self:AddButtonListener(self.ViewPet.btnLevelUp, self.OnShowPetView)
  self:AddButtonListener(self.NRCButton_0, self.OnClickTraceIcon)
  self:AddButtonListener(self.ButtonReset, self.OnButtonResetClicked)
  self.Btn_PetUIAdjust.OnHovered:Add(self, self.ShowUIIconLine)
  self.Btn_PetUIAdjust.OnUnhovered:Add(self, self.NotShowUIIconLine)
  self:AddButtonListener(self.Btn_Dazzling_1.btnLevelUp, self.ClickShiningToggle)
  self:AddButtonListener(self.Btn_Dazzling.btnLevelUp, self.ClickGlassToggle)
  self:AddButtonListener(self.Btn_Dazzling_2.btnLevelUp, self.ClickShiningGlassToggle)
  self:RegisterEvent(self, HandbookModuleEvent.SetSelectedItemUpdatePanel, self.ShowPetBasicInfo)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangeAreaData, self.OnChangeArea)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangCurBookPreviewWorld, self.OnChangePreviewWorld)
  self:RegisterEvent(self, HandbookModuleEvent.OnCloseDazzlingPopUp, self.OnCloseDazzlingPopUp)
  self:RegisterEvent(self, HandbookModuleEvent.OnChangeSelectPhotoSwitcher, self.OnChangeSelectPhotoSwitcher)
  _G.NRCEventCenter:RegisterEvent("UMG_HandbookContent_C", self, HandbookModuleEvent.OnHandBookChanged, self.OnHandBookChanged)
end

function UMG_HandbookContent_C:OnHandBookChanged(_handbookId)
  local module = _G.NRCModuleManager:GetModule("HandbookModule")
  local moduleData = module:GetData("HandbookModuleData")
  local selectData = moduleData:GetSelectPetData()
  if selectData.HandbookId == _handbookId then
    self:ShowMinSubject(selectData)
  end
end

function UMG_HandbookContent_C:OnClickButtonLeft()
end

function UMG_HandbookContent_C:OnClickButton()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.OpenHandbookTrophyPanel)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1361, "UMG_HandbookContent_C:OnClickButton")
end

function UMG_HandbookContent_C:ShowPetBasicInfo(_handBookInfo, _playAim, _delay)
  self.Right:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if _playAim and _handBookInfo.HandbookId ~= self.curHandbookId then
    self.Canvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.Change)
  end
  self.isDelayLoadMoudel = _delay
  local redId = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdGetCurAreaHandBookRedId, 1, 3)
  self.Dot:SetupKey(redId, {
    _handBookInfo.HandbookId
  })
  local BookInfo = _handBookInfo
  self.BookInfo = BookInfo
  self.curHandbookId = _handBookInfo.HandbookId
  if self.BookInfo and self.BookInfo.State == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED and self.CurPhotoTabIndex then
    self:OnChangeSelectPhotoSwitcher(self.CurPhotoTabIndex)
  else
    self.CurPhotoTabIndex = 1
    self:ShowPetContent()
  end
  self.Information:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdCloseDazzlingPopUp)
  if self.data == nil then
    self.module = _G.NRCModuleManager:GetModule("HandbookModule")
    self.data = self.module:GetData("HandbookModuleData")
  end
  self.curRecordIndex = self.data:GetSubSelectIndex()
  self.curRecord = nil
  self.state = _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND
  if nil ~= BookInfo.Collection then
    self.curRecord = BookInfo.Collection.record[self.curRecordIndex]
    self.state = self.curRecord.status
    self.CanvasPanel_84:SetVisibility(BookInfo.Collection.status == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
  else
    self.CanvasPanel_84:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:ShowDefaultMutationBtnStyle()
  self:ChangeShow(self.state)
  if self.state == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self:ShowPetFinderInfo(BookInfo)
  elseif self.state == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    self:ShowPetHaveInfo(BookInfo)
  else
    self:ShowPetNotFindInfo(BookInfo)
  end
  self:ShowStatisticsBtn()
  self:ShowTraceIcon()
  self:OnShowPackTurnButton(BookInfo)
  self:ShowModule()
  if self.curRecord and self.HadNormalForm == false then
    if self.MutationBtnToggleDic[0].isShow then
      self:ClickMutationBtnToggle(0)
    elseif self.MutationBtnToggleDic[1].isShow then
      self:ChangeBtnStyle()
    end
  end
  local conf = _G.DataConfigManager:GetPetHandbook(self.curHandbookId)
  if conf and conf.roco_scale then
    self:SetRocoHight(conf.roco_scale)
  end
  if conf and conf.design_base and self.state == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    self.CoCreationActivityText:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CoCreationActivityText:SetText(conf.design_base)
  else
    self.CoCreationActivityText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.curRecord and self.curRecord.pet_base_id then
    if self.HadNormalForm == true then
      _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, _G.Enum.MutationDiffType.MDT_NONE)
    elseif self.MutationBtnToggleDic[0].isShow == true then
      _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, _G.Enum.MutationDiffType.MDT_SHINING)
    end
  end
end

function UMG_HandbookContent_C:OnChangeSelectHeadIcon(mutation_type)
  if self.curRecord ~= nil then
    local glass_info = {}
    if self.curRecord.glass_info and #self.curRecord.glass_info > 0 then
      glass_info = self.curRecord.glass_info[1]
    end
    _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, mutation_type, glass_info)
  end
end

function UMG_HandbookContent_C:ShowModule()
  if self.state == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self:AddPetToScene(self.curRecord.pet_base_id)
  elseif self.state == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    self:AddPetToScene(self.curRecord.pet_base_id)
  else
    self:AddPetToScene()
  end
end

function UMG_HandbookContent_C:ChangeShow(_state)
  local state = _state
  self.QuestionMark_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.QuestionMark_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    self.diwen:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.wenhao:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Pet_Switcher:SetActiveWidgetIndex(2)
    self.Stature_1:SetText("?.??~?.??")
    self.Weight_1:SetText("?.??~?.??")
  elseif state == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self.diwen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.wenhao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Stature_1:SetText("?.??~?.??")
    self.Weight_1:SetText("?.??~?.??")
    self.Pet_Switcher:SetActiveWidgetIndex(1)
    self.CanvasPanel_143:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_47:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.diwen:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.wenhao:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Stature_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Weight_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_143:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.CanvasPanel_47:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.Pet_Switcher:SetActiveWidgetIndex(0)
  end
end

function UMG_HandbookContent_C:ShowWightHight()
  if self.curRecord == nil then
    return
  end
  local record = self.curRecord
  self.Weight_1:SetText(string.format(LuaText.umg_handbookcontent_2, record.weight_min * 0.001))
  self.Stature_1:SetText(string.format(LuaText.umg_handbookcontent_3, record.height_min * 0.01))
  if record.height_min ~= record.height_max then
    self.Stature_1:SetText(string.format(LuaText.umg_handbookcontent_4, record.height_min * 0.01, record.height_max * 0.01))
  end
  if record.weight_min ~= record.weight_max then
    self.Weight_1:SetText(string.format(LuaText.umg_handbookcontent_5, record.weight_min * 0.001, record.weight_max * 0.001))
  end
end

function UMG_HandbookContent_C:ShowPetName(_bookInfo)
  if nil == _bookInfo then
    return
  end
  local petId
  if _bookInfo then
    petId = _bookInfo.PetId
  end
  if nil ~= self.curRecord then
    petId = self.curRecord.pet_base_id
  end
  if nil == petId then
    return
  end
  local conf = _G.DataConfigManager:GetPetbaseConf(petId)
  local name = conf.name
  local form = conf.form
  if nil == conf.form or conf.form == "" then
    self.Name_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Name_2:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self.Name_1:SetText(name)
  self.Name_2:SetText(conf.form)
  local isBoss = self.curRecord.is_boss
  if isBoss then
    self.Name_2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Name_2:SetText(LuaText.handbook_boss_title)
  end
end

function UMG_HandbookContent_C:ShowStatisticsBtn()
  if self.BookInfo == nil or nil == self.curRecord or self.curRecord.status ~= _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ViewPet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local showTime = _G.DataConfigManager:GetGlobalConfigByKeyType("pet_statistics_display_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).str
  local openTime = _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.ConvertToTimeSeconds, showTime)
  local curSvrTime = _G.NRCModeManager:DoCmd(_G.BattlePassModuleCmd.GetCurServerTime)
  if openTime <= curSvrTime then
    self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.ViewPet:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_HandbookContent_C:ShowTraceIcon()
  local isShowBtn = false
  if self.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    isShowBtn = 1 == _G.DataConfigManager:GetPetGlobalConfig("hd_is_notfind_show_track").num
  elseif self.state == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    isShowBtn = 1 == _G.DataConfigManager:GetPetGlobalConfig("hd_is_find_show_track").num
  elseif self.state == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    isShowBtn = 1 == _G.DataConfigManager:GetPetGlobalConfig("hd_is_catch_show_track").num
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MAP, false)
  if isBan then
    isShowBtn = false
  end
  self.NRCButton_0:SetVisibility(isShowBtn and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_HandbookContent_C:ShowPetType(_bookInfo)
  local unit_type = _G.DataConfigManager:GetPetbaseConf(self.curRecord.pet_base_id).unit_type
  local mainUnitType = unit_type[1]
  if mainUnitType then
    local skillColorConf = _G.DataConfigManager:GetSkillColorConf(mainUnitType)
    if skillColorConf then
      self.diwen:SetPath(skillColorConf.handbook_type_background)
    end
  end
  if unit_type and #unit_type > 0 then
    self.Attr:InitGridView(unit_type)
    self.Attr:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  else
    self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_HandbookContent_C:ShowPetModuleIcon(_bookInfo)
  local petId = 0
  local isNOtFound = self.state == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND and true or false
  local handbookConf = _G.DataConfigManager:GetPetHandbook(_bookInfo.HandbookId)
  if self.curRecord ~= nil then
    petId = self.curRecord.pet_base_id
  elseif handbookConf and handbookConf.include_petbase_id[1] then
    petId = handbookConf.include_petbase_id[1].petbase_id[1]
  end
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petId)
  self.PetBaseConf = petBaseConf
  if petBaseConf then
    local path = petBaseConf.JL_res
    if self.curRecord then
      local isSelectMutation = self.MutationBtnToggleDic[0].isSelect
      if isSelectMutation then
        if petBaseConf.JL_shiny_res and petBaseConf.JL_shiny_res ~= "" then
          path = petBaseConf.JL_shiny_res
        else
          Log.Warning("petBaseConf id:", petId, "\230\178\161\230\156\137\229\188\130\232\137\178\230\136\150\232\128\133\231\130\171\229\189\169icon\233\133\141\231\189\174")
        end
      end
    end
    self:SetUIScaleAndLocation(petBaseConf)
    self:SetProjectionIcon(petBaseConf)
    self.Icon:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:SetIcon(path)
    self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.RequestProjectionIcon then
      _G.NRCResourceManager:UnLoadRes(self.RequestProjectionIcon)
      self.RequestProjectionIcon = nil
    end
    self.RequestProjectionIcon = _G.NRCResourceManager:LoadResAsync(self, petBaseConf.JL_small_res, 255, 0, self.OnProjectionIconResLoadComplete, nil)
    self.IconBg:SetPath(isNOtFound and petBaseConf.handbook_unknown_bg or petBaseConf.handbook_standpaint_bg)
    self.IconBg_1:SetPath(isNOtFound and petBaseConf.handbook_unknown_bg or petBaseConf.handbook_standpaint_bg)
    self.IconBg_3:SetPath(isNOtFound and petBaseConf.handbook_unknown_bg or petBaseConf.handbook_standpaint_bg)
    self:SetAdjustPetParam()
  end
end

function UMG_HandbookContent_C:SetStampImage(image)
  local material = image:GetDynamicMaterial()
  if UE4.UObject.IsValid(material) then
    material:SetTextureParameterValue("SpriteTexture", self.Icon.Brush.ResourceObject)
    image:SetBrushFromMaterial(material, false)
  else
    Log.Error("UMG_HandbookContent_C material is nil")
  end
end

function UMG_HandbookContent_C:ShowPetNotFindInfo(_bookInfo)
  self.Canvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.CanvasPanel_143:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.DepartmentName:SetText(LuaText.umg_handbookcontent_7)
  self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Name_1:SetText("???")
  self.Name_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ShowPetModuleIcon(_bookInfo)
  if _bookInfo.Collection == nil then
    self.Describe:SetText(_bookInfo.HandBookConf.description_habitat)
    return
  end
end

function UMG_HandbookContent_C:ShowPetFinderInfo(_bookInfo)
  self:ShowPetName(_bookInfo)
  self.Canvas:SetVisibility(UE4.ESlateVisibility.Visible)
  if _bookInfo.Collection ~= nil and _bookInfo.Collection.status == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    local handbookcCfg = _bookInfo.HandBookConf
    local name = handbookcCfg.type_desc
    self.DepartmentName:SetText(name)
  else
    self.DepartmentName:SetText(LuaText.umg_handbookcontent_7)
  end
  local handbookcCfg = _bookInfo.HandBookConf
  local desc = handbookcCfg.description_habitat
  self.Describe:SetText(desc)
  self:ShowPetType(_bookInfo)
  self:ShowPetModuleIcon(_bookInfo)
end

function UMG_HandbookContent_C:ShowPetHaveInfo(_bookInfo)
  self:ShowPetName(_bookInfo)
  local handbookcCfg = _bookInfo.HandBookConf
  local name = handbookcCfg.type_desc
  local desc = ""
  self.DepartmentName:SetText(name)
  if self.curRecord then
    desc = _G.DataConfigManager:GetPetbaseConf(self.curRecord.pet_base_id).description
  end
  self.Describe:SetText(desc)
  self:ShowPetType(_bookInfo)
  self:ShowPetModuleIcon(_bookInfo)
  self:ShowWightHight(_bookInfo)
  self:ShowMinSubject(_bookInfo)
  self.Canvas:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_HandbookContent_C:OnClickBtn_Left()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_HandbookContent_C:OnClickBtn_Left")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  local BookInfo = self.data:GetSelectPetData()
  if self.curRecordIndex == nil then
    self.curRecordIndex = 1
  end
  self.data:SetSubSelectIndex(self.curRecordIndex - 1)
  self.curRecordIndex = self.data:GetSubSelectIndex()
  if self.curRecordIndex and self.curRecordIndex < 1 then
    self.curRecordIndex = 1
    self.data:SetSubSelectIndex(1)
  else
  end
  self:DispatchEvent(HandbookModuleEvent.OnChangSelectItemData, BookInfo.HandbookId, self.curRecordIndex)
  self:ShowPetBasicInfo(BookInfo, false)
end

function UMG_HandbookContent_C:OnShowPetBaseByRecordIndex()
  if self.curRecord then
    local BookInfo = self.data:GetSelectPetData()
    self:ShowPetBasicInfo(BookInfo, false)
  end
end

function UMG_HandbookContent_C:OnBtnLeftPressed()
  self:PlayAnimation(self.Press_Left)
end

function UMG_HandbookContent_C:OnBtnLeftReleased()
  self:PlayAnimation(self.Up_Left)
end

function UMG_HandbookContent_C:OnBtnRightPressed()
  self:PlayAnimation(self.Press_Right)
end

function UMG_HandbookContent_C:OnBtnRightReleased()
  self:PlayAnimation(self.Up_Right)
end

function UMG_HandbookContent_C:OnClickBtn_Right()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1003, "UMG_HandbookContent_C:OnClickBtn_Right")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  local BookInfo = self.data:GetSelectPetData()
  self.data:SetSubSelectIndex(self.curRecordIndex + 1)
  self.curRecordIndex = self.data:GetSubSelectIndex()
  if self.curRecordIndex > BookInfo.SelectMaxIndex then
    self.curRecordIndex = BookInfo.SelectMaxIndex
    self.data:SetSubSelectIndex(BookInfo.SelectMaxIndex)
  else
  end
  self:DispatchEvent(HandbookModuleEvent.OnChangSelectItemData, BookInfo.HandbookId, self.curRecordIndex)
  self:ShowPetBasicInfo(BookInfo, false)
end

function UMG_HandbookContent_C:OnButtonResetClicked()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
end

function UMG_HandbookContent_C:OnShowPackTurnButton(_bookInfo)
  local BookInfo = _bookInfo
  if self.curRecordIndex <= 1 then
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.curRecordIndex >= BookInfo.SelectMaxIndex then
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_HandbookContent_C:OnRecommend()
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_HandbookContent_C:OnRecommend")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  local petId = 0
  local handbookConf = _G.DataConfigManager:GetPetHandbook(self.BookInfo.HandbookId)
  if self.curRecord ~= nil then
    petId = self.curRecord.pet_base_id
  elseif handbookConf and handbookConf.include_petbase_id[1] and handbookConf.include_petbase_id[1].petbase_id[1] then
    petId = handbookConf.include_petbase_id[1].petbase_id[1]
  end
  if petId then
    _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDistrictMapGuide, petId)
  end
end

function UMG_HandbookContent_C:OnShowPetView()
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  _G.NRCAudioManager:PlaySound2DAuto(40002013, "UMG_HandbookContent_C:OnShowPetView")
  if self.curRecord ~= nil then
    local petId = self.curRecord.pet_base_id
    _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petId)
  end
end

function UMG_HandbookContent_C:OnClickTraceIcon()
  if self.bLockTraceIcon then
    return
  end
  self.bLockTraceIcon = true
  self:DelaySeconds(2, function()
    self.bLockTraceIcon = false
  end)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK_TRACE, true)
  if isBan then
    return
  end
  local bMapUnlock = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.IsMapUnlock, SceneUtils.GetSceneResId())
  if not bMapUnlock then
    local tips = _G.DataConfigManager:GetLocalizationConf("handbook_nomap_track_fail_text").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, tips)
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1004, "UMG_HandbookContent_C:OnClickTraceIcon")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  local selPetBookInfo = self.data:GetSelectPetData()
  local pet_base_id
  if self.curRecord then
    pet_base_id = self.curRecord.pet_base_id
  else
    local curBookId = selPetBookInfo.HandbookId
    local curBookConf = _G.DataConfigManager:GetPetHandbook(curBookId)
    if curBookConf and curBookConf.include_petbase_id and #curBookConf.include_petbase_id > 0 then
      local include = curBookConf.include_petbase_id[1]
      if include.petbase_id and #include.petbase_id > 0 then
        pet_base_id = include.petbase_id[1]
      end
    end
  end
  local baseConf = _G.DataConfigManager:GetPetbaseConf(pet_base_id)
  Log.Warning("pet_base_id", pet_base_id, baseConf.pet_track_npc_id[1])
  if baseConf and baseConf.pet_track_npc_id then
    _G.NRCModuleManager:DoCmd(_G.BigMapModuleCmd.SendZoneNpcTraceQueryReq, baseConf.pet_track_npc_id)
  end
end

function UMG_HandbookContent_C:OnClickBtnTrophy()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HANDBOOK_REWARD, true)
  if isBan then
    return
  end
  local selPetBookInfo = self.data:GetSelectPetData()
  local pet_base_id
  if self.curRecord then
    pet_base_id = self.curRecord.pet_base_id
  elseif selPetBookInfo.Records then
    for _, value in pairs(selPetBookInfo.Records) do
      pet_base_id = value.PetBaseId
      break
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401006, "UMG_PetWarehouseMain_C:OnCloseBtnClicked")
  _G.NRCModuleManager:DoCmd(HandbookModuleCmd.ResetComboBox)
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenHandbookSubjectPanel, selPetBookInfo, pet_base_id)
end

function UMG_HandbookContent_C:OnHabitatBtnClick()
  local selPetBookInfo = self.data:GetSelectPetData()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1004, "UMG_HandbookContent_C:OnHabitatBtnClick")
  local parms = {}
  if self.curRecord then
    parms.pet_base_id = self.curRecord.pet_base_id
  else
    for key, value in pairs(selPetBookInfo.Records) do
      parms.pet_base_id = value.PetBaseId
      break
    end
  end
  parms.handBookId = selPetBookInfo.HandbookId
  _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OpenHabitMap, parms)
end

function UMG_HandbookContent_C:ShowMinSubject(handbookInfo)
  local tot_node_num = 0
  if handbookInfo.HandBookConf and handbookInfo.HandBookConf.pet_topic and #handbookInfo.HandBookConf.pet_topic then
    tot_node_num = #handbookInfo.HandBookConf.pet_topic
  end
  local num = 0
  if handbookInfo.Collection and handbookInfo.Collection.topic_list then
    for i = 1, #handbookInfo.Collection.topic_list do
      local count = handbookInfo.Collection.topic_list[i].finish_cnt
      if i <= #handbookInfo.HandBookConf.pet_topic and count >= handbookInfo.HandBookConf.pet_topic[i].topic_cnt then
        num = num + 1
      end
    end
  end
  if tot_node_num <= num then
    self.Achieved:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    self.VerticalBox_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCText_3:SetText(num)
    self.NRCText_4:SetText(string.format("/%s", tot_node_num))
    self.Achieved:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.VerticalBox_2:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
end

function UMG_HandbookContent_C:AddPetToScene(petId, petGid)
  self.loadModulePetId = petId
  if self.isDelayLoadMoudel then
    self.isDelayLoadMoudel = false
    self:DelaySeconds(0.2, function()
      self:ShowHandbookModule(petId)
    end)
  else
    self:ShowHandbookModule(petId)
  end
end

function UMG_HandbookContent_C:ShowHandbookModule(petId, select_mutations, glass_info)
  if nil == glass_info and self.curRecord and self.curRecord.glass_infos and #self.curRecord.glass_infos > 0 then
    glass_info = self.curRecord.glass_infos[1]
  end
  self.previewWorld:SetPreviewByPetBaseId(self, petId, select_mutations, glass_info)
end

function UMG_HandbookContent_C:ResetRotateModule()
  self.previewWorld:ResetRotate()
end

function UMG_HandbookContent_C:OnChangePreviewWorld(glass_info, select_mutations)
  if self.SkipAudio then
    self.SkipAudio = false
  else
    _G.NRCAudioManager:PlaySound2DAuto(1324, "UMG_RegionalSelection_List_C:OnItemSelected")
  end
  if self.curRecord then
    self:ShowHandbookModule(self.curRecord.pet_base_id, select_mutations, glass_info)
    _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, select_mutations, glass_info)
  end
end

function UMG_HandbookContent_C:SetRocoHight(scale)
  local newScale = UE4.FVector2D(scale, scale)
  self:SetRocoScale(newScale)
end

function UMG_HandbookContent_C:SetRuler(headPos)
  local star_y = -15
  local end_y = -396
  local rulerDistance = math.abs(end_y - star_y)
  local ImgaeTotalHeight = 70
  local proportion = math.abs(headPos.Z) / ImgaeTotalHeight
  local ruler_y = star_y - rulerDistance * proportion
  self.biao.Slot:SetPosition(UE4.FVector2D(10, ruler_y))
  self.biao:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_HandbookContent_C:SetAdjustPetParam()
  if not UE4.UNRCStatics.IsEditor() then
    return
  end
  local PetParam = {}
  if self.curRecord == nil then
    return
  end
  PetParam.id = self.curRecord.pet_base_id
  local _petBaseCfg = _G.DataConfigManager:GetPetbaseConf(PetParam.id)
  PetParam.name = _petBaseCfg.name
  PetParam.res_horizontal_flip_data = _petBaseCfg.res_horizontal_flip_data
  local UIScale = FormatFloat(_petBaseCfg.res_ui_percentage and _petBaseCfg.res_ui_percentage > 0 and _petBaseCfg.res_ui_percentage or 1)
  PetParam.Scale = UIScale
  if _petBaseCfg.res_offset and next(_petBaseCfg.res_offset) then
    local offsetConf = _petBaseCfg.res_offset
    PetParam.res_offset = UE4.FVector2D(offsetConf[1] or 0, offsetConf[2] or 0)
  else
    PetParam.res_offset = UE4.FVector2D(0, 0)
  end
  PetParam.is_display_shadow = _petBaseCfg.is_display_shadow or 1
  PetParam.shadow_horizontal_flip_data = _petBaseCfg.shadow_horizontal_flip_data or 0
  PetParam.shadow_vertical_flip_data = _petBaseCfg.shadow_vertical_flip_data or 0
  if _petBaseCfg.shadow_ui_percentage and next(_petBaseCfg.shadow_ui_percentage) then
    local shadow_ui_percentageX = FormatFloat(_petBaseCfg.shadow_ui_percentage[1])
    local shadow_ui_percentageY = FormatFloat(_petBaseCfg.shadow_ui_percentage[2])
    PetParam.shadow_ui_percentage = UE4.FVector2D(shadow_ui_percentageX, shadow_ui_percentageY)
  else
    PetParam.shadow_ui_percentage = UE4.FVector2D(0, 0)
  end
  if _petBaseCfg.shadow_offset and next(_petBaseCfg.shadow_offset) then
    PetParam.shadow_offset = UE4.FVector2D(_petBaseCfg.shadow_offset[1], _petBaseCfg.shadow_offset[2])
  else
    PetParam.shadow_offset = UE4.FVector2D(0, 0)
  end
  if _petBaseCfg.shadow_angle and next(_petBaseCfg.shadow_angle) then
    PetParam.shadow_angle = UE4.FVector2D(_petBaseCfg.shadow_angle[1], _petBaseCfg.shadow_angle[2])
  else
    PetParam.shadow_angle = UE4.FVector2D(-15, 0)
  end
  PetParam.shadow_opacity = FormatFloat(_petBaseCfg.shadow_opacity) or 0.3
  _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.SetPetVisualParam, PetParam)
end

function UMG_HandbookContent_C:SetUIScaleAndLocation(_petBaseConf)
  local _scale = _petBaseConf.res_ui_percentage and _petBaseConf.res_ui_percentage > 0 and _petBaseConf.res_ui_percentage or 1
  local NewUILocation = UE4.FVector2D(0, 0)
  local _offsetConf, _offsetLocation
  if _petBaseConf.res_offset and next(_petBaseConf.res_offset) then
    _offsetConf = _petBaseConf.res_offset
    _offsetLocation = UE4.FVector2D(_offsetConf[1] or 0, _offsetConf[2] or 0)
  else
    _offsetLocation = UE4.FVector2D(0, 0)
  end
  NewUILocation.X = NewUILocation.X + _offsetLocation.X
  NewUILocation.Y = NewUILocation.Y + _offsetLocation.Y
  self.Icon.Slot:SetPosition(NewUILocation)
  self.Icon_1.Slot:SetPosition(NewUILocation)
  self.Icon_2.Slot:SetPosition(NewUILocation)
  if 1 ~= _petBaseConf.res_horizontal_flip_data then
    self.Icon:SetRenderScale(UE4.FVector2D(_scale, _scale))
    self.Icon_1:SetRenderScale(UE4.FVector2D(_scale, _scale))
    self.Icon_2:SetRenderScale(UE4.FVector2D(_scale, _scale))
  else
    self.Icon:SetRenderScale(UE4.FVector2D(-_scale, _scale))
    self.Icon_1:SetRenderScale(UE4.FVector2D(-_scale, _scale))
    self.Icon_2:SetRenderScale(UE4.FVector2D(-_scale, _scale))
  end
end

function UMG_HandbookContent_C:SetProjectionIcon(_petBaseConf)
  local NewUILocation = UE4.FVector2D(0, 0)
  local _offsetConf, _offsetLocation
  if _petBaseConf.shadow_offset and next(_petBaseConf.shadow_offset) then
    _offsetConf = _petBaseConf.shadow_offset
    _offsetLocation = UE4.FVector2D(_offsetConf[1] or 0, _offsetConf[2] or 0)
  else
    _offsetLocation = UE4.FVector2D(0, 0)
  end
  NewUILocation.X = NewUILocation.X + _offsetLocation.X
  NewUILocation.Y = NewUILocation.Y + _offsetLocation.Y
  self.ProjectionIcon.Slot:SetPosition(NewUILocation)
  local Shear = UE4.FVector2D(0, 0)
  local ShadowAngleConf, shadow_angle
  if _petBaseConf.shadow_angle and next(_petBaseConf.shadow_angle) then
    ShadowAngleConf = _petBaseConf.shadow_angle
    shadow_angle = UE4.FVector2D(ShadowAngleConf[1] or 0, ShadowAngleConf[2] or 0)
  else
    shadow_angle = UE4.FVector2D(0, 0)
  end
  Shear.X = Shear.X + shadow_angle.X
  Shear.Y = Shear.Y + shadow_angle.Y
  self.ProjectionIcon:SetRenderShear(Shear)
  local Scale
  if _petBaseConf.shadow_ui_percentage and next(_petBaseConf.shadow_ui_percentage) then
    local _scale = _petBaseConf.shadow_ui_percentage
    Scale = UE4.FVector2D(_scale[1] or 0, _scale[2] or 0)
  else
    Scale = UE4.FVector2D(0, 0)
  end
  if 1 == _petBaseConf.shadow_horizontal_flip_data then
    Scale.X = -Scale.X
  end
  if 1 == _petBaseConf.shadow_vertical_flip_data then
    Scale.Y = -Scale.Y
  end
  self.ProjectionIcon:SetRenderScale(Scale)
  self.ProjectionIcon:SetRenderOpacity(_petBaseConf.shadow_opacity)
end

function UMG_HandbookContent_C:UpdateProjectionIconInfo(PetUIVisualParam)
  local is_display_shadow = PetUIVisualParam.is_display_shadow
  if 0 ~= is_display_shadow then
    self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local Scale = UE4.FVector2D(PetUIVisualParam.shadow_ui_percentage.X, PetUIVisualParam.shadow_ui_percentage.Y)
  if 1 == PetUIVisualParam.shadow_horizontal_flip_data then
    Scale.X = -Scale.X
  end
  if 1 == PetUIVisualParam.shadow_vertical_flip_data then
    Scale.Y = -Scale.Y
  end
  self.ProjectionIcon:SetRenderScale(Scale)
  self.ProjectionIcon.Slot:SetPosition(PetUIVisualParam.shadow_offset)
  self.ProjectionIcon:SetRenderShear(PetUIVisualParam.shadow_angle)
  self.ProjectionIcon:SetRenderOpacity(PetUIVisualParam.shadow_opacity)
end

function UMG_HandbookContent_C:ShowUIIconLine()
  if not self.OpenUIAdjustTool then
    return
  end
  self.Img_RedLine:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_HandbookContent_C:NotShowUIIconLine()
  if not self.OpenUIAdjustTool then
    return
  end
  self.Img_RedLine:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_HandbookContent_C:ControlShowUIRedLine(_IsOpen)
  if _IsOpen then
    self.OpenUIAdjustTool = true
  else
    self.OpenUIAdjustTool = false
  end
end

function UMG_HandbookContent_C:SetPetUIImageRevert(_flip, _Scale)
  if UE4.UNRCStatics.IsEditor() then
    local PetVisualParam = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetVisualParam, true)
    if 1 == _flip then
      self.Icon:SetRenderScale(UE4.FVector2D(-_Scale, _Scale))
    else
      self.Icon:SetRenderScale(UE4.FVector2D(_Scale, _Scale))
    end
    if PetVisualParam then
      PetVisualParam.res_horizontal_flip_data = _flip
      _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.SetPetVisualParam, PetVisualParam)
    end
  end
end

function UMG_HandbookContent_C:UpdateUIScaleAndOffset(_flip, _scale, _offset, _CurModifyAxis)
  if self.curRecord then
    if 1 == _flip then
      self.Icon:SetRenderScale(UE4.FVector2D(-_scale, _scale))
    else
      self.Icon:SetRenderScale(UE4.FVector2D(_scale, _scale))
    end
    local CurPetUILocation = self.Icon.Slot:GetPosition()
    local NewPetUILocation = CurPetUILocation
    if 1 == _CurModifyAxis then
      NewPetUILocation.X = _offset.X
    elseif 2 == _CurModifyAxis then
      NewPetUILocation.Y = _offset.Y
    elseif 0 == _CurModifyAxis then
      NewPetUILocation = _offset
    end
    self.Icon.Slot:SetPosition(NewPetUILocation)
  end
end

function UMG_HandbookContent_C:SetUIParamByOperationType(UIOperationType, Param)
  if UIOperationType == HandbookModuleEnum.UIEditorOperationType.is_display_shadow then
    if 1 == Param then
      self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_horizontal_flip_data then
    local Scale = self.ProjectionIcon.RenderTransform.Scale
    Scale.X = -Scale.X
    self.ProjectionIcon:SetRenderScale(Scale)
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_vertical_flip_data then
    local Scale = self.ProjectionIcon.RenderTransform.Scale
    Scale.Y = -Scale.Y
    self.ProjectionIcon:SetRenderScale(Scale)
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_ui_percentage then
    self.ProjectionIcon:SetRenderScale(Param)
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_offset then
    self.ProjectionIcon.Slot:SetPosition(Param)
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_angle then
    self.ProjectionIcon:SetRenderShear(Param)
  elseif UIOperationType == HandbookModuleEnum.UIEditorOperationType.shadow_opacity then
    self.ProjectionIcon:SetRenderOpacity(Param)
  end
end

function UMG_HandbookContent_C:OnTouchMoved(MyGeometry, InTouchEvent)
  if not self.OpenUIAdjustTool then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  local deltaX, deltaY = FPointerEvent_GetCursorDelta(InTouchEvent)
  local CharacterDesignSketch
  if _G.AppMain:HasDebug() then
    CharacterDesignSketch = _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.GetCharacterDesignSketch)
  end
  local NewUILocation
  if CharacterDesignSketch then
    NewUILocation = self.Icon.Slot:GetPosition()
    NewUILocation.X = NewUILocation.X + deltaX
    NewUILocation.Y = NewUILocation.Y + deltaY
    self.Icon.Slot:SetPosition(NewUILocation)
  else
    NewUILocation = self.ProjectionIcon.Slot:GetPosition()
    NewUILocation.X = NewUILocation.X + deltaX
    NewUILocation.Y = NewUILocation.Y + deltaY
    self.ProjectionIcon.Slot:SetPosition(NewUILocation)
  end
  if _G.AppMain:HasDebug() then
    _G.NRCModuleManager:DoCmd(_G.DebugModuleCmd.SetNewOffsetInfo, NewUILocation)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_HandbookContent_C:ClickShiningToggle()
  if self.HadNormalForm == false then
    _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.handbook_not_found_regular)
    _G.NRCAudioManager:PlaySound2DAuto(1329, "UMG_HandbookContent_C:ClickShiningToggle")
  else
    self:ClickMutationBtnToggle(0)
  end
end

function UMG_HandbookContent_C:ClickGlassToggle()
  self:ClickMutationBtnToggle(1)
end

function UMG_HandbookContent_C:ClickShiningGlassToggle()
  self:ClickMutationBtnToggle(2)
end

function UMG_HandbookContent_C:TriggerMutionFunction()
  self.Name_2:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.MutationBtnToggleDic[0].isSelect == true and self.MutationBtnToggleDic[1].isSelect == false and self.MutationBtnToggleDic[2].isSelect == false then
    self.Name_2:SetText(LuaText.umg_handbookcontent_9)
    self.Information:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:ShowHandbookModule(self.curRecord.pet_base_id, _G.Enum.MutationDiffType.MDT_SHINING)
    self:OnChangeSelectHeadIcon(_G.Enum.MutationDiffType.MDT_SHINING)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdCloseDazzlingPopUp)
  elseif self.MutationBtnToggleDic[1].isSelect == true then
    self.Name_2:SetText(LuaText.umg_handbookcontent_8)
    _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDazzlingPopUp, self.curRecord, self.MutationBtnToggleDic[1].mutationTypes)
    self.Information:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.MutationBtnToggleDic[0].isSelect == true and self.MutationBtnToggleDic[1].isSelect == false and self.MutationBtnToggleDic[2].isSelect == true then
    self.Name_2:SetText(LuaText.hb_shining_glass_text)
    _G.NRCModeManager:DoCmd(_G.HandbookModuleCmd.OnCmdOpenDazzlingPopUp, self.curRecord, self.MutationBtnToggleDic[2].mutationTypes)
    self.Information:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.MutationBtnToggleDic[0].isSelect == false and self.MutationBtnToggleDic[1].isSelect == false and self.MutationBtnToggleDic[2].isSelect == false then
    self:ShowPetName(self.BookInfo)
    self.Information:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.OnCmdCloseDazzlingPopUp)
    self:ShowHandbookModule(self.curRecord.pet_base_id, _G.Enum.MutationDiffType.MDT_NONE)
    if self.curRecord then
      local glass_info = {glass_type = 0, glass_value = 0}
      _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, _G.Enum.MutationDiffType.MDT_NONE, glass_info)
    end
  end
end

function UMG_HandbookContent_C:ChangeBtnStyle()
  if self.MutationBtnToggleDic[0].isShow == true and self.MutationBtnToggleDic[1].isShow == false and self.MutationBtnToggleDic[2].isShow == false then
    self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BoliSwitcher:SetActiveWidgetIndex(self.MutationBtnToggleDic[0].isSelect and 0 or 1)
  elseif self.MutationBtnToggleDic[0].isShow == true and self.MutationBtnToggleDic[1].isShow == true and self.MutationBtnToggleDic[2].isShow == false then
    self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Visible)
    self.VerticalBox_3:SetVisibility(self.MutationBtnToggleDic[0].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.BoliSwitcher:SetActiveWidgetIndex(self.MutationBtnToggleDic[0].isSelect and 0 or 1)
    self.YiseSwitcher:SetVisibility(self.MutationBtnToggleDic[1].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  elseif self.MutationBtnToggleDic[0].isShow == true and self.MutationBtnToggleDic[1].isShow == false and self.MutationBtnToggleDic[2].isShow == true then
    self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Visible)
    self.VerticalBox_4:SetVisibility(self.MutationBtnToggleDic[0].isSelect and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.BoliSwitcher:SetActiveWidgetIndex(self.MutationBtnToggleDic[0].isSelect and 0 or 1)
    self.YiseSwitcher_1:SetVisibility(self.MutationBtnToggleDic[2].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  elseif self.MutationBtnToggleDic[0].isShow == true and self.MutationBtnToggleDic[1].isShow == true and self.MutationBtnToggleDic[2].isShow == true then
    self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Visible)
    self.BoliSwitcher:SetActiveWidgetIndex(self.MutationBtnToggleDic[0].isSelect and 0 or 1)
    self.VerticalBox_4:SetVisibility(self.MutationBtnToggleDic[0].isSelect and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
    self.VerticalBox_3:SetVisibility(self.MutationBtnToggleDic[0].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.YiseSwitcher:SetVisibility(self.MutationBtnToggleDic[1].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
    self.YiseSwitcher_1:SetVisibility(self.MutationBtnToggleDic[2].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  elseif self.MutationBtnToggleDic[0].isShow == false and self.MutationBtnToggleDic[1].isShow == true and self.MutationBtnToggleDic[2].isShow == false then
    self.VerticalBox_3:SetVisibility(UE4.ESlateVisibility.Visible)
    self.YiseSwitcher:SetVisibility(self.MutationBtnToggleDic[1].isSelect and UE4.ESlateVisibility.Collapsed or UE4.ESlateVisibility.Visible)
  end
end

function UMG_HandbookContent_C:ShowDefaultMutationBtnStyle()
  self.MutationBtnToggleDic = {}
  self.MutationBtnToggleDic[0] = {
    isShow = false,
    isSelect = false,
    mutationTypes = {}
  }
  self.MutationBtnToggleDic[1] = {
    isShow = false,
    isSelect = false,
    mutationTypes = {}
  }
  self.MutationBtnToggleDic[2] = {
    isShow = false,
    isSelect = false,
    mutationTypes = {}
  }
  self.CanvasPanel_8:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.VerticalBox_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.VerticalBox_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HadNormalForm = false
  if self.curRecord and self.curRecord.catch_mutation and #self.curRecord.catch_mutation then
    for i, mutation_type in pairs(self.curRecord.catch_mutation) do
      local isShining = PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING)
      local isGlass = PetUtils.CheckIsCHAOS(mutation_type) or PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS)
      local isShiningGlass = PetUtils.CheckIsShiningGlass(mutation_type)
      local isShiningChaos = PetUtils.CheckIsShiningChaos(mutation_type)
      if isShiningGlass then
        self.MutationBtnToggleDic[2].isShow = true
        self.MutationBtnToggleDic[0].isShow = true
        table.insert(self.MutationBtnToggleDic[2].mutationTypes, mutation_type)
      elseif isShiningChaos then
        self.MutationBtnToggleDic[2].isShow = true
        self.MutationBtnToggleDic[0].isShow = true
        table.insert(self.MutationBtnToggleDic[2].mutationTypes, mutation_type)
      elseif isGlass then
        self.MutationBtnToggleDic[1].isShow = true
        self.HadNormalForm = true
        table.insert(self.MutationBtnToggleDic[1].mutationTypes, mutation_type)
      elseif isShining then
        self.MutationBtnToggleDic[0].isShow = true
        table.insert(self.MutationBtnToggleDic[0].mutationTypes, mutation_type)
      end
      if mutation_type == _G.Enum.MutationDiffType.MDT_NONE then
        self.HadNormalForm = true
      end
    end
  end
  self:ChangeBtnStyle()
end

function UMG_HandbookContent_C:ClickMutationBtnToggle(index)
  self.SkipAudio = true
  self.MutationBtnToggleDic[index].isSelect = not self.MutationBtnToggleDic[index].isSelect
  if self.MutationBtnToggleDic[index].isSelect then
    if 0 == index then
      _G.NRCAudioManager:PlaySound2DAuto(1028, "UMG_RegionalSelection_List_C:OnItemSelected")
      self.MutationBtnToggleDic[1].isSelect = false
    elseif 1 == index then
      _G.NRCAudioManager:PlaySound2DAuto(1073, "UMG_RegionalSelection_List_C:OnItemSelected")
      self.MutationBtnToggleDic[0].isSelect = false
    else
      _G.NRCAudioManager:PlaySound2DAuto(1073, "UMG_RegionalSelection_List_C:OnItemSelected")
    end
  end
  if self.MutationBtnToggleDic[index].isSelect == false then
    if 0 == index then
      _G.NRCAudioManager:PlaySound2DAuto(1071, "UMG_RegionalSelection_List_C:OnItemSelected")
      self.MutationBtnToggleDic[2].isSelect = false
    else
      _G.NRCAudioManager:PlaySound2DAuto(1179, "UMG_RegionalSelection_List_C:OnItemSelected")
    end
  end
  local isNormalForm = self.HadNormalForm
  if false ~= isNormalForm or 0 == index and self.MutationBtnToggleDic[0].isShow and self.MutationBtnToggleDic[1].isShow then
  elseif self.MutationBtnToggleDic[0].isShow and not self.MutationBtnToggleDic[1].isShow then
    self.MutationBtnToggleDic[0].isSelect = true
  end
  self:ChangeBtnStyle()
  self:TriggerMutionFunction()
  self:ShowPetModuleIcon(self.BookInfo)
  self:ResetRotateModule()
end

function UMG_HandbookContent_C:OnChangeArea(areaData)
  self.Name:SetText(areaData.conf.bg_name)
  self.RequestBg = _G.NRCResourceManager:LoadResAsync(self, areaData.conf.bottom_cover_res, 255, 0, self.OnBgResLoadComplete, nil)
  self.Dot:SetupKey(122, {
    areaData.conf.area_handbook_type,
    self.curHandbookId
  })
end

function UMG_HandbookContent_C:SetIcon(path)
  local materialPath
  local status = self.state
  self.iconPath = path
  if status == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_Silhouettew_Dirty_2.MI_UI_Silhouettew_Dirty_2'"
    self.Icon_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif status == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    materialPath = "MaterialInstanceConstant'/Game/ArtRes/UI/TUI/Materials/MI_UI_Silhouettew_Dirty.MI_UI_Silhouettew_Dirty'"
  else
    materialPath = nil
    self.Icon:SetPathWithCallBack(path, {
      self,
      self.OnIconLoaded
    })
  end
  if nil ~= materialPath then
    self:LoadPanelRes(materialPath, 255, self.OnLoadIconMaterialSucceed, self.OnLoadIconMaterialFail, nil)
  end
end

function UMG_HandbookContent_C:OnLoadIconMaterialSucceed(_, asset)
  if asset and self.iconPath then
    local status = self.state
    if status == _G.ProtoEnum.PetHandbookStatus.PHS_NOT_FOUND then
      self.Icon_2.MaterialInstance = asset
      self.Icon_2:SetBrushFromMaterial(asset)
      self.Icon_2:SetPathWithCallBack(self.iconPath, {
        self,
        self.OnIcon2Loaded
      })
    elseif status == _G.ProtoEnum.PetHandbookStatus.PHS_FOUND then
      self.Icon_1.MaterialInstance = asset
      self.Icon_1:SetBrushFromMaterial(asset)
      self.Icon_1:SetPathWithCallBack(self.iconPath, {
        self,
        self.OnIcon1Loaded
      })
    end
  end
end

function UMG_HandbookContent_C:OnIconLoaded()
  if UE4.UObject.IsValid(self.Icon) then
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_HandbookContent_C:OnIcon1Loaded()
  if UE4.UObject.IsValid(self.Icon_1) then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_HandbookContent_C:OnIcon2Loaded()
  if UE4.UObject.IsValid(self.Icon_2) then
    self.Icon_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_HandbookContent_C:OnLoadIconMaterialFail()
end

function UMG_HandbookContent_C:OnIconResLoadComplete(req, Texture2D)
  if UE4.UObject.IsValid(self.Icon) then
    self.Icon:SetBrushFromTexture(Texture2D, false)
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:SetStampImage(self.Icon_1)
  self:SetStampImage(self.Icon_2)
end

function UMG_HandbookContent_C:OnProjectionIconResLoadComplete(req, Texture2D)
  if UE4.UObject.IsValid(self.ProjectionIcon) then
    local material = self.ProjectionIcon:GetDynamicMaterial()
    if UE4.UObject.IsValid(material) then
      material:SetTextureParameterValue("Tex", Texture2D)
      self.ProjectionIcon:SetBrushFromMaterial(material, false)
      if self.PetBaseConf and 0 ~= self.PetBaseConf.is_display_shadow then
        self.ProjectionIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      Log.Error("UMG_HandbookContent_C material is nil")
    end
  end
end

function UMG_HandbookContent_C:OnBgResLoadComplete(req, PaperSprite)
  if UE4.UObject.IsValid(self.NRCImage_5) then
    self.NRCImage_5:SetBrushFromPaperSprite(PaperSprite, false)
    self:SetImageDrawas(UE4.ESlateBrushDrawType.Box)
  end
end

function UMG_HandbookContent_C:SetImageDrawas(drawAs)
  local CurrentBrush = self.NRCImage_5.Brush
  CurrentBrush.DrawAs = drawAs
  self.NRCImage_5:SetBrush(CurrentBrush)
end

function UMG_HandbookContent_C:OnCloseDazzlingPopUp(isColor)
  if isColor then
    self:ClickMutationBtnToggle(1)
    self:ShowPetName(self.BookInfo)
    self.Information:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:ShowHandbookModule(self.curRecord.pet_base_id, _G.Enum.MutationDiffType.MDT_NONE)
    if self.curRecord then
      local glass_info = {glass_type = 0, glass_value = 0}
      _G.NRCModeManager:DoCmd(HandbookModuleCmd.SetSelectedItemIcon, self.curRecord.pet_base_id, self.state, _G.Enum.MutationDiffType.MDT_NONE, glass_info)
    end
  else
    self:ClickMutationBtnToggle(2)
  end
end

function UMG_HandbookContent_C:OnAnimationFinished(anim)
  if anim == self.Book_Open then
  elseif anim == self.Up_Left then
    self:OnClickBtn_Left()
  elseif anim == self.Up_Right then
    self:OnClickBtn_Right()
  end
end

function UMG_HandbookContent_C:HidePreviewWorld(delayShowTime)
end

function UMG_HandbookContent_C:ShowPreviewWorld()
end

function UMG_HandbookContent_C:OnChangeSelectPhotoSwitcher(index)
  self.CurPhotoTabIndex = index
  self:PlayAnimation(self.Change_2)
  if 1 == index then
    self:ShowPetContent()
  else
    self:ShowPetPhotos()
  end
end

return UMG_HandbookContent_C
