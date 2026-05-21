local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local luaText = require("LuaText")
local MainUIModuleEvent = reload("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEnum = require("NewRoco.Modules.System.PetUI.PetUIModuleEnum")
local ShareUIModuleEvent = reload("NewRoco.Modules.System.ShareUI.ShareUIModuleEvent")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_PetLeftPanel_C = _G.NRCViewBase:Extend("UMG_PetLeftPanel_C")
local EnumPetInfoChangeReasonType = {None = 0, TraceBack = 1}

function UMG_PetLeftPanel_C:Initialize(Initializer)
  Log.Debug("UMG_PetLeftPanel_C:Initialize")
end

function UMG_PetLeftPanel_C:OnConstruct()
  self:SetChildViews(self.Attribute)
  self.subPanels = {
    self.Attribute,
    self.Attribute
  }
  self.bShowSkillPanel = true
  self.curSubPanelIndex = 0
  self.keepSubPanel = false
  self.IsCutTeam = false
  self.petBagOpening = false
  self.ThumbVersion = true
  self.IsReverseAnimation = false
  self.IsReverseOpenXqAni = false
  self.IsHasBlood = false
  self.ShowList = false
  self:updateCloseButtonVisible()
  self:updateSubPanelVisible()
  self.Incubating:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.bPetBagBtnEnable = true
  local icon1 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_basci_icon_png.ui_petinfo_basci_icon_png'"
  local icon2 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_basci_icon2_png.ui_petinfo_basci_icon2_png'"
  local icon3 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petAttri_png.umg_petAttri_png'"
  local icon4 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petAttri_2_png.umg_petAttri_2_png'"
  local icon5 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petskill_png.umg_petskill_png'"
  local icon6 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/umg_petskill_2_png.umg_petskill_2_png'"
  local icon7 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_icon_having_png.ui_petinfo_icon_having_png'"
  local icon8 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/ui_petinfo_icon_having2_png.ui_petinfo_icon_having2_png'"
  local icon9 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_PetImpression1_png.img_PetImpression1_png'"
  local icon10 = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/GameInfo/Frames/img_PetImpression2_png.img_PetImpression2_png'"
  self.uiData = {}
  self.uiItem = {}
  self:OnAddEventListener()
  self:DelayFrames(2, self.panelRefresh, self)
  self.petHeadList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local openPanelPetData, index, IsRevertMainPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPanelPetData and not IsRevertMainPanel then
    self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetEggBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.Attribute.petInfoMainCtrl = self.petInfoMainCtrl
  self.Attribute:SetOwner(self)
  self.Attribute:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SwitchToThumbVersion(true)
  self:StopAllAnimations()
  self:UpdateBloodInfo(false)
  self.RedDot_1:SetupKey(195)
  self.RedDot_2:SetupKey(195)
  self.RedDot1:SetupKey(0)
  local isQualifying = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsCurrentlyInQualifying)
  if isQualifying then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:CheckShareIsOpen()
  if self.ShareIsOpen then
    _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.CheckRewardStateEntrance, self.shareBaseId)
  end
  local TitleList
  if self.ShareIsOpen then
    TitleList = {
      {
        IconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_ChangeName_png.img_ChangeName_png'",
        type = PetUIModuleEnum.PetTitleListShowType.NameSet,
        caller = self,
        callback = self.OnTitleListItemSelect
      },
      {
        IconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_ShareFormation_png.img_ShareFormation_png'",
        type = PetUIModuleEnum.PetTitleListShowType.ShareTeam,
        caller = self,
        callback = self.OnShareTeamItemSelect
      },
      {
        IconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_SecretCode_png.img_SecretCode_png'",
        type = PetUIModuleEnum.PetTitleListShowType.LoadTeam,
        caller = self,
        callback = self.OnLoadTeamItemSelect
      }
    }
  else
    TitleList = {
      {
        IconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_ChangeName_png.img_ChangeName_png'",
        type = PetUIModuleEnum.PetTitleListShowType.NameSet,
        caller = self,
        callback = self.OnTitleListItemSelect
      },
      {
        IconPath = "PaperSprite'/Game/NewRoco/Modules/System/PetUI/PetUIStatic/Frames/img_SecretCode_png.img_SecretCode_png'",
        type = PetUIModuleEnum.PetTitleListShowType.LoadTeam,
        caller = self,
        callback = self.OnLoadTeamItemSelect
      }
    }
  end
  self.List_More:InitList(TitleList)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfigByKeyType("drag_mode_press_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num / 1000
end

function UMG_PetLeftPanel_C:SetSkillShow(bShowSkillPanel)
  self.bShowSkillPanel = bShowSkillPanel
  self:SetTitleVisible(bShowSkillPanel)
  if not bShowSkillPanel then
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_PetLeftPanel_C:RefreshRedPointWithOne(CanEvo, CanBreakThrough)
  local item = self.petHeadList:GetItemByIndex(0)
  if CanEvo then
    item.CultivateRed:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    item.CultivateRed_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    item.CultivateRed:SetVisibility(UE4.ESlateVisibility.Collapsed)
    item.CultivateRed_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetLeftPanel_C:OnTitleListItemSelect(SelectType)
  self.ShowList = false
  self.MoreList:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if SelectType == PetUIModuleEnum.PetTitleListShowType.NameSet and self.curTeamInfo then
    local param = {
      teamType = self.curTeamInfo.team_type,
      TeamIdx = self.petBagTeamIndex and self.petBagTeamIndex - 1 or self.curTeamInfo.main_team_idx,
      teamName = self:GetTeamName()
    }
    _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenRechristenPanel, param, nil, 2)
  end
end

function UMG_PetLeftPanel_C:GetTeamName()
  if self.curTeamInfo then
    local TeamIndex = self.petBagTeamIndex or self.curTeamInfo.main_team_idx and self.curTeamInfo.main_team_idx + 1 or 1
    local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
    local CurPetTeam = self.curTeamInfo.teams[TeamIndex]
    if CurPetTeam.team_name then
      return CurPetTeam.team_name
    else
      return string.format(default_name, TeamIndex)
    end
  end
end

function UMG_PetLeftPanel_C:GetPetEggBtnShow()
  if self.module and self.module:GetData("PetUIModuleData"):GetEnterPetPanelType() == PetUIModuleEnum.EnterType.PvpPetTeamUmg then
    return false
  end
  local openPanelPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if openPanelPetData then
    return false
  end
  if self.module:HasPanel("NewPetBag") then
    return false
  end
  local IsOpenAttribute = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetAttribute)
  if not IsOpenAttribute then
    return false
  end
  local dontShow = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET_HATCH_EGG, false)
  dontShow = dontShow or _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_HATCH_EGG, false)
  return not dontShow
end

function UMG_PetLeftPanel_C:panelRefresh()
  self:SetTitleVisible(self.bShowSkillPanel)
  local OpenByLobbyMain = true
  local openPetData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  if not openPetData then
    self.IsOpenWithOne = false
    local SelectIndex = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetSelectIndex)
    local isOpenPetBag, gid = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetBag)
    if SelectIndex then
      self.petInfoMainCtrl:SetCurrentSelectedPetIndex(SelectIndex)
    end
    self:updatePetList(true, isOpenPetBag)
    
    local function delayRefresh()
    end
    
    if isOpenPetBag then
      self:DispatchEvent(PetUIModuleEvent.PetBagStopAllAnimation)
      self:DispatchEvent(PetUIModuleEvent.PetBagUnlockAllButton)
      self.TryOpenTime = 1
      self:TryOpenPetBag()
      self.delayBagOpen = delayRefresh
    elseif not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CheckIsPetHatchingPanelShow) then
      delayRefresh()
    end
  else
    self.IsOpenWithOne = true
    if 1 == index then
      self:OpenPanelWithOnePet(openPetData)
      self.Attribute:SwitchVersion()
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetAttribute, false)
      self:OnMenuButtonClick(index)
    else
      self:OpenPanelWithOnePet(openPetData)
      self.Attribute:SwitchVersion()
      self:OnMenuButtonClick(index)
    end
    self:PetFriendInterfaceDisplay()
  end
  self.uiData.init_pet_gid = 0
  self:UpdateResonanceList()
  local isShow = self:GetPetEggBtnShow()
  self:ShowEggSpeedUp()
  self:UpdateHatchInfo()
  self.PetEggBtn:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:RefreshAttributeInfo()
  if self.uiData.petData then
    self.uiData.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.uiData.petData.gid)
    self.Attribute:UpdatePetData(self.uiData)
  end
  local item = self.petHeadList:GetSelectedItem()
  if item then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(item.uiData.petData.gid)
    local UiData = {
      gid = petData.gid,
      base_conf_id = petData.base_conf_id,
      showPetHp = true,
      level = petData.level,
      petData = petData
    }
    item:SetData(UiData)
  end
end

function UMG_PetLeftPanel_C:UpdateBloodInfo(IsPlayAnim)
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  self.curTeamInfo = teamInfo
  local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
  self.IsHasBlood = BagItemS and #BagItemS > 0 and true or false
  local IsEquipment = false
  if self.IsHasBlood then
    if BagItemS then
      for i, BagItem in ipairs(BagItemS) do
        local curTeamIndex = self.petBagTeamIndex or self.curTeamInfo.main_team_idx + 1
        if self.curTeamInfo and self.curTeamInfo.teams and self.curTeamInfo.teams[curTeamIndex] and BagItem.gid == self.curTeamInfo.teams[curTeamIndex].role_magic_gid then
          IsEquipment = true
          local isQualifying = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsCurrentlyInQualifying)
          if isQualifying then
            self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
          else
            self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          end
          self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Switcher:SetActiveWidgetIndex(0)
          local BagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
          if BagItemConf then
            self.Icon:SetPath(BagItemConf.icon)
          end
          if IsPlayAnim then
            self:PlayAnimation(self.Xuemaimofa_In)
          end
          break
        end
      end
    else
      self.Switcher:SetActiveWidgetIndex(1)
    end
  end
  if not self.IsHasBlood then
    self:SetSwitcher()
  elseif IsPlayAnim then
    if not IsEquipment then
      self:PlayAnimation(self.Xuemaimofa_Out)
    end
  elseif not IsEquipment then
    self.Switcher:SetActiveWidgetIndex(1)
  end
end

function UMG_PetLeftPanel_C:OnPlayerDataUpdate(UpdateGoodType, PetDataChangeItemList)
  if PetDataChangeItemList and 1 == #PetDataChangeItemList and PetDataChangeItemList[1] and PetDataChangeItemList[1].PetDataUpdateReasonType == PetUIModuleEnum.PetDataUpdateReason.TraceBack then
    return
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  for i = 1, self.petHeadList:GetItemCount() do
    local Item = self.petHeadList:GetItemByIndex(i - 1)
    for j, _Pet in ipairs(battlePetList) do
      if _Pet.gid == Item.uiData.gid then
        Item:UpdateNewData(_Pet, _Pet.base_conf_id)
      end
    end
  end
end

function UMG_PetLeftPanel_C:SetSwitcher()
  self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Switcher:SetActiveWidgetIndex(1)
end

function UMG_PetLeftPanel_C:ShowOrHideBloodIcon(IsShow)
  Log.Debug(self.IsHasBlood, IsShow, "UMG_PetLeftPanel_C:ShowOrHideBloodIcon")
  if self.IsHasBlood then
    if IsShow then
      local isQualifying = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsCurrentlyInQualifying)
      if isQualifying then
        self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetLeftPanel_C:TryShowOrCloseList(bIsShow)
  _G.NRCAudioManager:PlaySound2DAuto(40002003, "UMG_PetLeftPanel_C:TryShowOrCloseList")
  if true == bIsShow or false == bIsShow then
    self.ShowList = bIsShow
  else
    self.ShowList = not self.ShowList
  end
  if self.ShowList then
    self:PlayAnimation(self.MoreList_in)
    self.MoreList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:PlayAnimation(self.MoreList_out)
  end
  self:updateCloseButtonVisible()
end

function UMG_PetLeftPanel_C:CheckPetHeadListShow()
  if self.petHeadList then
    return self.petHeadList:GetVisibility() == UE4.ESlateVisibility.Visible or self.petHeadList:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible
  end
  return false
end

function UMG_PetLeftPanel_C:OpenAddFriends()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo then
    _G.NRCModuleManager:DoCmd(FriendModuleCmd.AddFriendApplicationOrRemoveFriend, friendInfo.info.uin, _G.ProtoEnum.ZoneFriendAddOrRemoveFriendReq.TYPE.ADD_FRIEND)
  else
    Log.Error("\229\143\145\233\128\129\229\165\189\229\143\139\232\175\183\230\177\130")
  end
end

function UMG_PetLeftPanel_C:OpenBloodLineMagic()
  _G.NRCAudioManager:PlaySound2DAuto(41400009, "UMG_PetLeftPanel_C:OpenBloodLineMagic")
  local petTeamInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetTeamInfo()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenBloodLineMagic, _G.Enum.PlayerTeamType.PTT_BIG_WORLD, self.petBagTeamIndex and self.petBagTeamIndex - 1 or petTeamInfo.main_team_idx)
end

function UMG_PetLeftPanel_C:OnEquipmentOrRemoveBloodEvent()
  self:UpdateBloodInfo(true)
end

function UMG_PetLeftPanel_C:UpdateEggSpeedIcon(redpointDatas)
  self.Incubating:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:ShowEggSpeedUp()
  local isEggUp = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetEggSpeedActiveOpenState)
  local pointData = _G.NRCModuleManager:DoCmd(_G.RedPointModuleCmd.GetReasonPointData, Enum.RedPointReason.RPR_EGG_HATCH_COMPLETE)
  if pointData and #pointData > 0 then
    isEggUp = false
  end
  local backpackEggList = _G.DataModelMgr.PlayerDataModel:GetPlayerBackpackEggInfo()
  if nil == backpackEggList or 0 == #backpackEggList then
    isEggUp = false
  end
  self.Incubating:SetVisibility(isEggUp and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:UpdateHatchInfo()
  local eggCount = 0
  local backpack_info = _G.DataModelMgr.PlayerDataModel.playerInfo.pet_info.backpack_info
  if backpack_info and backpack_info.egg_gid then
    eggCount = #backpack_info.egg_gid
  end
  local maxCount = _G.DataConfigManager:GetPetGlobalConfig("hatch_limit").num
  self.NumberHatchlingsText:SetText(eggCount .. "/" .. maxCount)
end

function UMG_PetLeftPanel_C:PlayAnimationIn()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.In)
  local isOpenPetBag = self:GetPetBagIsVisible()
  if isOpenPetBag then
  end
end

function UMG_PetLeftPanel_C:PlayAnimationInReverse()
  self.IsReverseAnimation = true
  self:PlayAnimationReverse(self.In)
end

function UMG_PetLeftPanel_C:SetTitleVisible(_bVisible)
  if _bVisible then
    if not self.IsOpenWithOne then
      self.TeamName:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    self.NRCImage_196:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TeamName:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_196:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetLeftPanel_C:PlayAniMationOpenXqAni()
  self.buttons:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:PlayAnimation(self.OpenXqAni)
end

function UMG_PetLeftPanel_C:PlayAniMationOpenXqAniReverse(_IsFirstIn)
  self:PlayAnimationReverse(self.OpenXqAni)
  self.buttons:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_PetLeftPanel_C:SwitchToThumbVersion(_IsFirstIn)
  self.ThumbVersion = true
  for i = 0, self.petHeadList:GetItemCount() - 1 do
    local head = self.petHeadList:GetItemByIndex(i)
    head:ShowDetail(_IsFirstIn)
  end
  if not self.module:HasPanel("NewPetBag") then
    self:TryShowOrCloseTeamSwitch(true)
  end
end

function UMG_PetLeftPanel_C:SwitchToDetailVersion()
  self.ThumbVersion = false
  for i = 0, self.petHeadList:GetItemCount() - 1 do
    local head = self.petHeadList:GetItemByIndex(i)
    head:HideDetail()
  end
  self:TryShowOrCloseTeamSwitch(false)
end

function UMG_PetLeftPanel_C:UpdateResonanceList()
  local teamInfo = {}
  local petInfos = {}
  for i, pet in ipairs(self.petList) do
    table.insert(petInfos, PetUtils.PetInfoCreate(pet.gid))
  end
  teamInfo.pet_infos = petInfos
end

function UMG_PetLeftPanel_C:OnDeactive()
  self:CancelDelay()
  self.Attribute:OnDeactive()
  self:CancelShareDelayId()
  self.ShareUIReward:CancelShareDelayId()
end

function UMG_PetLeftPanel_C:OnDestruct()
  self:CancelDelay()
  self:OnRemoveEventListener()
  table.clear(self.subPanels)
  self.petList = nil
  self.subPanels = nil
  table.clear(self.uiItem)
  self.uiData = nil
  self.uiItem = nil
  self.Attribute:Destruct()
  if self.dragInstance and UE4.UObject.IsValid(self.dragInstance) then
    self.dragInstance:RemoveFromParent()
    self.dragInstance = nil
  end
end

function UMG_PetLeftPanel_C:OnEnable()
end

function UMG_PetLeftPanel_C:OnDisable()
end

function UMG_PetLeftPanel_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseSubPanel, self.OnCloseButtonClicked)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.btnPetFangSheng, self.OnBtnPetFangShengClick)
  self:AddButtonListener(self.PetEggBtn, self.OpenEggPanel)
  self:AddButtonListener(self.PetBagBtn, self.OnPetBagBtnClick)
  self:AddButtonListener(self.BloodBtn, self.OpenBloodLineMagic)
  self:AddButtonListener(self.Exchange.btnLevelUp, self.OpenBloodLineMagic)
  self:AddButtonListener(self.Exchange_1.btnLevelUp, self.OpenBloodLineMagic)
  self:AddButtonListener(self.Btn_recommend.btnLevelUp, self.TryShowOrCloseList)
  self:AddButtonListener(self.AddFriends.btnLevelUp, self.OpenAddFriends)
  self:AddButtonListener(self.BtnLeft, self.OnLeftSlide)
  self:AddButtonListener(self.BtnRight, self.OnRightSlide)
  self:RegisterEvent(self, PetUIModuleEvent.GetOpenPanelPetDataRedPoint, self.RefreshRedPointWithOne)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_SKILL_SUCCESS, self.OnEquippedSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.USE_EXP_ITEM_SUCCESS1, self.OnUseExpItemSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.OnRefreshEvoPetModel, self.OnEvolutionSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PET_GROWUP_SUCCESS, self.OnPetGroUpSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PET_TRACEBACK_SUCCESS_REWARD_POPUP_CLOSE, self.OnPetTraceBackSuccessAndRewardPopupClose)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_TEAMBTN_BTNCLICK, self.OnLeftPanelTeamButtonClick)
  self:RegisterEvent(self, PetUIModuleEvent.SET_PET_ISPLAY_SUCCESS, self.OnSetPetIsPlaySuccess)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_PET_CHANGE_TEAM, self.OnUIPetChangeTeam)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_CHANG_TO_EVOLUTION, self.OnUIChangeToEvolution)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_SECONDPANEL_CLOSE, self.HiddenSecondPanelClose)
  self:RegisterEvent(self, PetUIModuleEvent.GameLoginEvent, self.OnGameLoginEvent)
  self:RegisterEvent(self, PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_BTNCLICK, self.HiddenSecondPanelClose)
  self:RegisterEvent(self, PetUIModuleEvent.PET_TEAM_CHANGE, self.PetTeamChanage)
  self:RegisterEvent(self, PetUIModuleEvent.PET_TEAM_OPEND, self.PetTeamOpend)
  self:RegisterEvent(self, PetUIModuleEvent.EQUIP_POSSESION_SUCCESS, self.OnEquipPossesionSuccess)
  self:RegisterEvent(self, PetUIModuleEvent.UpdateImpressionGroup, self.OnUpdateImpressionGroup)
  self:RegisterEvent(self, PetUIModuleEvent.HavingUpgradeAndResonanceEvent, self.HavingUpgradeAndResonanceEvent)
  self:RegisterEvent(self, PetUIModuleEvent.ChangeChoosePet, self.ChangeChoosePet)
  self:RegisterEvent(self, PetUIModuleEvent.HideRetractionBtn, self.OnHideRetractionBtn)
  self:RegisterEvent(self, PetUIModuleEvent.SelectPetDept, self.OnOpenResonanceUI)
  self:RegisterEvent(self, PetUIModuleEvent.SelectPetEgg, self.OnSelectPetEgg)
  self:RegisterEvent(self, PetUIModuleEvent.OnOpenEggPanel, self.OnOpenEggClick)
  self:RegisterEvent(self, PetUIModuleEvent.OnCloseEggPanel, self.OnCloseEggClick)
  self:RegisterEvent(self, PetUIModuleEvent.AttributeChangeSetEggBtn, self.AttributeChangeSetEggBtn)
  self:RegisterEvent(self, PetUIModuleEvent.PetBagChangeSetEggBtn, self.PetBagChangeSetEggBtn)
  self:RegisterEvent(self, PetUIModuleEvent.OpenDetailPanelEvent, self.HiddenHeadListUI)
  self:RegisterEvent(self, PetUIModuleEvent.LeftPanelRefresh, self.panelRefresh)
  self:RegisterEvent(self, PetUIModuleEvent.AttributePanelRefresh, self.RefreshAttributeInfo)
  self:RegisterEvent(self, PetUIModuleEvent.EquipmentOrRemoveBloodEvent, self.OnEquipmentOrRemoveBloodEvent)
  self:RegisterEvent(self, PetUIModuleEvent.UpdateEggSpeedIcon, self.UpdateEggSpeedIcon)
  self:RegisterEvent(self, PetUIModuleEvent.PetInfoMainModifyTeamName, self.RefreshCurTeamName)
  self:RegisterEvent(self, PetUIModuleEvent.ChangeWorldTeamSuccess, self.RefreshCurTeamInfo)
  self:RegisterEvent(self, PetUIModuleEvent.UpdateBloodInfo, self.UpdateBloodInfo)
  self:RegisterEvent(self, PetUIModuleEvent.PlayerDataUpdate, self.OnPlayerDataUpdate)
  self:RegisterEvent(self, PetUIModuleEvent.OnOpenNewPetBag, self.OnSwitchNewPetBagOpened)
  self:RegisterEvent(self, PetUIModuleEvent.SetAttributeState, self.CloseSwitchButton)
  _G.NRCEventCenter:RegisterEvent("UMG_PetLeftPanel_C", self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetLeftPanel_C", self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:RegisterEvent("UMG_PetLeftPanel_C", self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
  _G.NRCModuleManager:GetModule("PetUIModule"):RegisterEvent(self, PetUIModuleEvent.RemoveSkillNewState, self.RemoveSkillNewState)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
  _G.NRCEventCenter:RegisterEvent("UMG_PetLeftPanel_C", self, PetUIModuleEvent.CHANGE_PET_POS_SUCCESS, self.OnChangePetBagPosComplete)
  self.RedDot:SetupKey(192)
  _G.NRCEventCenter:RegisterEvent(self.name, self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  self:RegisterEvent(self, PetUIModuleEvent.OnBigWorldTeamPetChangeEvent, self.OnBigWorldTeamPetChangeEvent)
end

function UMG_PetLeftPanel_C:OnRightSlide()
  if self.curTeamInfo then
    local team_idx = self:GetNextTeamIndex()
    if team_idx then
      self.UpdateRefreshSelect = true
      if self.waitForRsp then
      else
        self.petHeadList:ClearSelection()
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, team_idx - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
        self.waitForRsp = true
        self:DelaySeconds(0.3, function()
          self.waitForRsp = false
        end)
      end
    end
  end
end

function UMG_PetLeftPanel_C:OnLeftSlide()
  if self.curTeamInfo then
    local team_idx = self:GetLastTeamIndex()
    if team_idx then
      self.UpdateRefreshSelect = true
      if self.waitForRsp then
      else
        self.petHeadList:ClearSelection()
        _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, team_idx - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
        self.waitForRsp = true
        self:DelaySeconds(0.3, function()
          self.waitForRsp = false
        end)
      end
    end
  end
end

function UMG_PetLeftPanel_C:PetTeamDotListSelect()
end

function UMG_PetLeftPanel_C:GetNextTeamIndex()
  if self.curTeamInfo then
    local ValidIndex
    local Num = self.curTeamInfo.teams and #self.curTeamInfo.teams > 0 and #self.curTeamInfo.teams
    if Num then
      for i = 1, Num do
        local curTeam = self.curTeamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 and i > self.curTeamInfo.main_team_idx + 1 then
          ValidIndex = i
          break
        end
      end
    end
    if not ValidIndex and Num then
      for i = 1, Num do
        local curTeam = self.curTeamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
          ValidIndex = i
          break
        end
      end
    end
    return ValidIndex
  end
end

function UMG_PetLeftPanel_C:GetLastTeamIndex()
  if self.curTeamInfo then
    local ValidIndex
    local Num = self.curTeamInfo.teams and #self.curTeamInfo.teams > 0 and #self.curTeamInfo.teams
    if Num then
      for i = Num, 1, -1 do
        local curTeam = self.curTeamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 and i < self.curTeamInfo.main_team_idx + 1 then
          ValidIndex = i
          break
        end
      end
    end
    if not ValidIndex and Num then
      for i = Num, 1, -1 do
        local curTeam = self.curTeamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
          ValidIndex = i
          break
        end
      end
    end
    return ValidIndex
  end
end

function UMG_PetLeftPanel_C:RefreshCurTeamInfo()
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  self.curTeamInfo = teamInfo
  local TeamIndex = self.petBagTeamIndex or teamInfo.main_team_idx and teamInfo.main_team_idx + 1 or 1
  local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
  local CurPetTeam = teamInfo.teams[TeamIndex]
  if CurPetTeam.team_name then
    self.TeamName:SetText(CurPetTeam.team_name)
  else
    self.TeamName:SetText(string.format(default_name, TeamIndex))
  end
  if not self.petBagOpening then
    local petHead = self.petHeadList:GetItemByIndex(0)
    if petHead then
      petHead.bFirstOpen = false
    end
    self:updatePetList(true, false, 1)
  end
end

function UMG_PetLeftPanel_C:RefreshCurTeamName()
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  self.curTeamInfo = teamInfo
  local teams = {}
  local selectIndex = 0
  local Num = self.curTeamInfo and self.curTeamInfo.teams and #self.curTeamInfo.teams > 0 and #self.curTeamInfo.teams
  if Num then
    for i = 1, Num do
      local curTeam = self.curTeamInfo.teams[i]
      if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
        table.insert(teams, curTeam)
        if i == self.curTeamInfo.main_team_idx + 1 then
          selectIndex = #teams - 1
        end
      end
    end
  end
  self.Dot_List:InitGridView(teams)
  self.Dot_List:SelectItemByIndex(selectIndex)
  if #teams > 1 then
    self.OnlyOneTeam = false
    self:TryShowOrCloseTeamSwitch(true)
  else
    self.OnlyOneTeam = true
    self:TryShowOrCloseTeamSwitch(false)
  end
  local TeamIndex = self.petBagTeamIndex or teamInfo.main_team_idx and teamInfo.main_team_idx + 1 or 1
  local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
  local CurPetTeam = teamInfo.teams[TeamIndex]
  if CurPetTeam and CurPetTeam.team_name then
    self.TeamName:SetText(CurPetTeam.team_name)
  else
    self.TeamName:SetText(string.format(default_name, TeamIndex))
  end
end

function UMG_PetLeftPanel_C:TryShowOrCloseTeamSwitch(_bShow)
  if _bShow then
    if self.module:HasPanel("NewPetBag") then
      self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
      return
    end
    if self.IsOpenWithOne then
      self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    elseif self.ThumbVersion then
      if self.OnlyOneTeam then
        self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetLeftPanel_C:SetPetBagCurTeamNameAndBloodLineMagic(_TeamIndex)
  if self.curTeamInfo then
    self.petBagTeamIndex = _TeamIndex
    local default_name = _G.DataConfigManager:GetPetGlobalConfig("mainworld_team_default_name").str
    local CurPetTeam = self.curTeamInfo.teams[self.petBagTeamIndex]
    if CurPetTeam.team_name then
      self.TeamName:SetText(CurPetTeam.team_name)
    else
      self.TeamName:SetText(string.format(default_name, self.petBagTeamIndex))
    end
    self:UpdateBloodInfo()
  end
end

function UMG_PetLeftPanel_C:OnRemoveEventListener()
  if _G.NRCModuleManager:GetModule("PetUIModule") then
    _G.NRCModuleManager:GetModule("PetUIModule"):UnRegisterEvent(self, PetUIModuleEvent.RemoveSkillNewState, self.RemoveSkillNewState)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.CHANGE_PET_POS_SUCCESS, self.OnChangePetBagPosComplete)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnOpenEggPanel, self.OnOpenEggClick)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnCloseEggPanel, self.OnCloseEggClick)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnChangeEggBtn, self.SetEggBtn)
  if _G.DataModelMgr.PlayerDataModel:HasListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange) then
    _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.UPDATE_PET_HP, self.OnPlayerPetHPChange)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, ShareUIModuleEvent.SHOW_ENTRANCE_REWARD, self.CheckShowShareReward)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchStart, self.OnRocoTouchStartHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchMove, self.OnRocoTouchMoveHandler)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnRocoTouchEnd, self.OnRocoTouchEndHandler)
end

function UMG_PetLeftPanel_C:OnSwitchNewPetBagOpened(isOpen, bNeedAutoSelectTeamPet)
  if isOpen then
    self:OnPetBagOpen(bNeedAutoSelectTeamPet)
  else
    self:OnPetBagClose()
  end
end

function UMG_PetLeftPanel_C:CloseSwitchButton(isDisable)
  self.bPetBagBtnEnable = not isDisable
  self:UpdatePetBagBtnState()
end

function UMG_PetLeftPanel_C:UpdatePetBagBtnState()
  local bEnable = _G.DataModelMgr.PlayerDataModel.WaitGetPetInfoRspSuccess and self.bPetBagBtnEnable
  self.PetBagBtn:SetIsEnabled(bEnable)
end

function UMG_PetLeftPanel_C:OnPetBagOpen(bNeedAutoSelectTeamPet)
  self.petBagOpening = true
  self.petHeadList:SetVisibility(UE4.ESlateVisibility.Hidden)
  if nil == bNeedAutoSelectTeamPet then
    bNeedAutoSelectTeamPet = true
  end
  self:PlayAnimation(self.PetBag_Open)
  if not self.petInfoMainCtrl then
    Log.Error("petInfoMainCtrl\228\184\141\229\173\152\229\156\168")
    return
  end
  if bNeedAutoSelectTeamPet then
    self:DispatchEvent(PetUIModuleEvent.PetBagOnPetItemClick, self.petInfoMainCtrl.currentSelectedPetIndex, true, nil, true)
  end
  local isOpenPetBag, gid = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPetBag)
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetOpenPetBag, false, 0)
  if isOpenPetBag then
    self:DispatchEvent(PetUIModuleEvent.PetBagOnSelectPetBag, gid)
  end
  if 3 == self.curMenuButtonIndex then
    self:DispatchEvent(PetUIModuleEvent.HAVING_EQUIPLEFT)
  end
  if self.delayBagOpen then
    self.delayBagOpen()
    self.delayBagOpen = nil
  end
  local isOpenPetAttri = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetEggFinshOpenAttribute)
  if isOpenPetAttri then
    self:DelaySeconds(0.3, function()
      self.Attribute:SwitchVersion()
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetEggFinshOpenAttribute, false)
    end)
  end
  self:LeaveDragState()
end

function UMG_PetLeftPanel_C:CheckCurPetBagTeamIsValid(NeedTips)
  local isValid = false
  if self.petBagTeamIndex then
    if self.curTeamInfo then
      local curTeam = self.curTeamInfo.teams[self.petBagTeamIndex]
      if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
        isValid = true
      end
    end
  else
    isValid = true
  end
  if not isValid and not NeedTips then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.empty_team_retract_tip)
  end
  return isValid
end

function UMG_PetLeftPanel_C:GetPetBagValidTeamIndex()
  local ValidIndex = 0
  if self.curTeamInfo then
    ValidIndex = self.curTeamInfo.main_team_idx
    local Num = self.curTeamInfo.teams and #self.curTeamInfo.teams > 0 and #self.curTeamInfo.teams
    if Num then
      for i = 1, Num do
        local curTeam = self.curTeamInfo.teams[i]
        if curTeam and curTeam.pet_infos and #curTeam.pet_infos > 0 then
          ValidIndex = i
          break
        end
      end
    end
  end
  return ValidIndex - 1
end

function UMG_PetLeftPanel_C:OnPetBagClose(petBagSelectIndex)
  self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  local PetBagTeamIsValid = self:CheckCurPetBagTeamIsValid()
  local isShow = self:GetPetEggBtnShow()
  self.PetEggBtn:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  if PetBagTeamIsValid then
    if self.petBagTeamIndex and self.curTeamInfo.main_team_idx ~= self.petBagTeamIndex - 1 then
      if self.petInfoMainCtrl and self.petInfoMainCtrl.currentSelectedPetIndex and self.petInfoMainCtrl.currentSelectedPetIndex > 6 then
        self.UpdateRefreshSelect = true
      end
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, self.petBagTeamIndex - 1, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
    end
  elseif self.petBagTeamIndex and self.curTeamInfo.main_team_idx == self.petBagTeamIndex - 1 then
    PetBagTeamIsValid = true
    local Index = self:GetPetBagValidTeamIndex()
    self.petBagTeamIndex = Index + 1
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetMainTeams, Index, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD)
  end
  self.petBagOpening = false
  if not self.IsOpenWithOne and UE4.UObject.IsValid(self.petHeadList) then
    self.petHeadList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local isQualifying = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.IsCurrentlyInQualifying)
  if self.IsHasBlood and not isQualifying then
    self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.BloodBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:PlayAnimation(self.PetBag_Out)
  if self.petInfoMainCtrl and (not (PetBagTeamIsValid and self.petBagTeamIndex) or self.curTeamInfo.main_team_idx ~= self.petBagTeamIndex - 1) then
    self.petBagTeamIndex = nil
    self:UpdateBloodInfo()
    self:updatePetList(true, true)
    self:UpdateResonanceList()
    self:AutoSelectPetOnPetBagClose(petBagSelectIndex, PetBagTeamIsValid)
  end
  if self.ThumbVersion then
    self:SwitchToThumbVersion()
  else
    self:SwitchToDetailVersion()
  end
  if 3 == self.curMenuButtonIndex then
    self:DispatchEvent(PetUIModuleEvent.HAVING_EQUIPRIGHT)
  end
end

function UMG_PetLeftPanel_C:AutoSelectPetOnPetBagClose(petBagSelectIndex, PetBagTeamIsValid)
  local AutoSelectIndex = self:GetAutoSelectIndex(petBagSelectIndex, PetBagTeamIsValid)
  local head = self.petHeadList:GetItemByIndex(AutoSelectIndex)
  if head then
    if self.UpdateRefreshSelect then
      head.NeedOpenDoubleSelectAnim = true
    end
    head:SetIsRefreshSelect(true)
    self.petHeadList:SelectItemByIndex(AutoSelectIndex)
    head:SetIsRefreshSelect(false)
  end
end

function UMG_PetLeftPanel_C:GetAutoSelectIndex(petBagSelectIndex, PetBagTeamIsValid)
  local AutoSelectIndex = 0
  local CurSelectedPetIndex
  if self.petInfoMainCtrl.currentSelectedPetIndex ~= nil then
    CurSelectedPetIndex = self.petInfoMainCtrl.currentSelectedPetIndex - 1
  end
  if nil ~= CurSelectedPetIndex then
    if CurSelectedPetIndex > 5 then
      AutoSelectIndex = 0
    else
      local CurSelectPetGID = self.petInfoMainCtrl.currentSelectedPetGid or -1
      local petHead = self.petHeadList:GetItemByIndex(CurSelectedPetIndex)
      if petHead and petHead._itemData and petHead._itemData.gid == CurSelectPetGID then
        if (not petBagSelectIndex or petBagSelectIndex == CurSelectedPetIndex) and PetBagTeamIsValid then
          AutoSelectIndex = CurSelectedPetIndex
        else
          AutoSelectIndex = 0
        end
      end
    end
  else
    AutoSelectIndex = 0
  end
  return AutoSelectIndex
end

function UMG_PetLeftPanel_C:ChangeChoosePet(index, petInfo)
  if not petInfo then
    self:ChangeEmptyPet()
  else
    self.currentPetInfo = petInfo
    self:DispatchEvent(PetUIModuleEvent.RightPanelMenuBtnSetAllVisibility, UE4.ESlateVisibility.Visible)
    self:ResettingMenuSelect(self.currentPetInfo.base_conf_id)
    self.Attribute:UpdatePetData(petInfo)
  end
end

function UMG_PetLeftPanel_C:ChangeEmptyPet()
  self.currentPetInfo = nil
  self:DispatchEvent(PetUIModuleEvent.RightPanelMenuBtnSetAllVisibility, UE4.ESlateVisibility.Collapsed)
  self.Attribute:UpdatePetData(nil)
end

function UMG_PetLeftPanel_C:ResettingMenuSelect(base_conf_id)
  if nil == base_conf_id then
    return
  end
  local PetConf = _G.DataConfigManager:GetPetbaseConf(base_conf_id)
  if 0 == PetConf.belong_habit_group then
    if 4 == self.curMenuButtonIndex then
      self:OnMenuButtonClick(1)
    end
  else
    if 5 == self.curMenuButtonIndex then
      self:OnMenuButtonClick(1)
    else
    end
  end
end

function UMG_PetLeftPanel_C:OnMenuButtonClick(_index)
  if nil == _index or _index > 0 and _index == self.curMenuButtonIndex then
    return
  end
  if _index > 4 then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_petleftpanel_4)
    return
  end
  self:ChangeCurButtonState(false)
  if self.uiData then
    self:SetPetNewSkillInfo(self.uiData.petData, self.curMenuButtonIndex)
  end
  self.curMenuButtonIndex = _index
  self:ChangeCurButtonState(true)
  self:DispatchEvent(PetUIModuleEvent.OnShowPetRadar, self.uiData.petData)
  local bagPanelOpen = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBagOpenState)
  self:DispatchEvent(PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_BTNCLICK, _index, bagPanelOpen)
  self:setActive(self.changeTeambuttons, 1 == self.curMenuButtonIndex)
end

function UMG_PetLeftPanel_C:ChangeCurButtonState(_select)
  if self.curMenuButtonIndex ~= nil then
  end
end

function UMG_PetLeftPanel_C:updatePetListView(_petList, _selectIndex)
  self.petList = _petList
  if not _G.NRCModuleManager:DoCmd(PetUIModuleCmd.IsPetHatchingPanel) then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.petHeadList:InitGridView(self.petList)
  if self.module.data.CulCanEvo then
    local item = self.petHeadList:GetItemByIndex(0)
    item.CultivateRed:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    item.CultivateRed_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  local count = #_petList
  if _selectIndex and _selectIndex > 0 and _selectIndex <= count then
    local isHatchingPanel = _G.NRCModeManager:DoCmd(PetUIModuleCmd.IsPetHatchingPanel)
    if not isHatchingPanel then
      self.petHeadList:SelectItemByIndex(_selectIndex - 1)
    end
  else
    local curIndex = self.curMenuButtonIndex
    if not (curIndex and curIndex > 0) or count > curIndex then
    else
    end
  end
  for i = #_petList, 1, -1 do
    if 0 == _petList[i].gid then
      table.remove(_petList, i)
    end
  end
  local petListData = {}
  for i, v in ipairs(_petList) do
    table.insert(petListData, v.petData)
  end
  self:UpdatePetSelect()
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF or self.IsOpenWithOne then
  else
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, petListData)
  end
end

function UMG_PetLeftPanel_C:UpdatePetSelect()
  local SelectPetIndex = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectLongPressPetIndex)
  if SelectPetIndex > 0 then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.SelectLongPressPetIndex, 0, false)
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SetPetSelectIndex, 0)
  end
end

function UMG_PetLeftPanel_C:OnMouseWheel(MyGeometry, InTouchEvent)
  if UE4.UObject.IsValid(self.Attribute) and not self.Attribute.showing then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  if self.OnlyOneTeam then
    return UE4.UWidgetBlueprintLibrary.Unhandled()
  end
  local wheelData = UE4.UKismetInputLibrary.PointerEvent_GetWheelDelta(InTouchEvent)
  if wheelData > 0 then
    self:OnLeftSlide()
  elseif wheelData < 0 then
    self:OnRightSlide()
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_PetLeftPanel_C:updatePetHpInfo(_petData)
  local maxHp, curHp = self:GetPetHP(_petData)
  if maxHp > 0 then
    local petHpPercent = curHp / maxHp
    if petHpPercent < 0.2 then
      self.petHpIcon:SetColorAndOpacity(UE4.FLinearColor(0.904661, 0.093059, 0.039546, 1))
    elseif petHpPercent < 0.5 then
      self.petHpIcon:SetColorAndOpacity(UE4.FLinearColor(1, 0.361307, 0.012286, 1))
    else
      self.petHpIcon:SetColorAndOpacity(UE4.FLinearColor(0.07036, 0.40724, 0.038204, 1))
    end
  end
end

function UMG_PetLeftPanel_C:UpdatePetEnergy(_petData)
  local petData = _petData
  local PetConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
end

function UMG_PetLeftPanel_C:UpdatePetLevel()
  local curPetData = self.uiData.petData
  if not curPetData or not self.petList then
    return nil
  end
  for _, petInfo in ipairs(self.petList) do
    if petInfo.gid == curPetData.gid then
      petInfo.level = curPetData.level
    end
  end
  return nil
end

function UMG_PetLeftPanel_C:updateStateChangeTeamButton(_petInfo)
  if not _petInfo then
    return
  end
  self:setActive(self.stateMainFight, _petInfo.isMainFight)
  self:setActive(self.stateNormalFight, _petInfo.isFight and not _petInfo.isMainFight)
  self:setActive(self.stateInHouse, not _petInfo.isFight)
end

function UMG_PetLeftPanel_C:getMainFightPet()
  if self.petList then
    for _, petInfo in ipairs(self.petList) do
      if petInfo.isMainFight then
        return petInfo
      end
    end
  end
end

function UMG_PetLeftPanel_C:ShowSubPanel(_index, _subIndex)
  if 1 == _index then
    Log.Error("subPanel index\228\184\186\233\148\153\232\175\175\229\128\188\239\188\140\228\184\141\229\186\148\232\175\165\232\162\171\232\176\131\231\148\168\239\188\140\232\175\183\232\129\148\231\179\187jobhuang ")
    return
  end
  if _index > 0 and _index <= #self.subPanels then
    if _subIndex then
      self.subPanels[_index]:ShowSubPanel(_subIndex)
    end
    if self.curSubPanelIndex ~= _index or 3 == _index then
      self:ChangeSubPanelState(self.curSubPanelIndex, false)
      self.curSubPanelIndex = _index
      self:updateCloseButtonVisible()
      self:ChangeSubPanelState(self.curSubPanelIndex, true)
      if 3 == self.curSubPanelIndex then
      else
        self:DispatchEvent(PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_CHANGE, self.curSubPanelIndex or 0)
        self.button_close:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1069, "UMG_PetLeftPanel_C:ShowSubPanel")
    end
  end
end

function UMG_PetLeftPanel_C:HiddenSecondPanelClose()
  self:HideSubPanel()
end

function UMG_PetLeftPanel_C:HideSubPanel()
  if self.curSubPanelIndex > 0 then
    if 3 == self.curSubPanelIndex then
      self.Attribute:CloseSwitchButton(false)
    end
    if 4 == self.curSubPanelIndex then
      self.Attribute:CloseSwitchButton(false)
      self:DispatchEvent(PetUIModuleEvent.PET_UI_RIGHTGROWUP_SUBPANEL_CHANGE, false)
    end
    self:ChangeSubPanelState(self.curSubPanelIndex, false)
    self.curSubPanelIndex = 0
    self:updateCloseButtonVisible()
    self:DispatchEvent(PetUIModuleEvent.PET_UI_LEFT_SUBPANEL_CHANGE, self.curSubPanelIndex)
    self.button_close:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetLeftPanel_C:getCurSubPanelIndex()
  return self.curSubPanelIndex or 0
end

function UMG_PetLeftPanel_C:checkCurSkillInfo(_skillPos)
  return false
end

function UMG_PetLeftPanel_C:updateCloseButtonVisible()
  if self.ShowList then
    self.btnCloseSubPanel:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.btnCloseSubPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_PetLeftPanel_C:updateSubPanelVisible()
  for panelIndex, subPanel in pairs(self.subPanels) do
    if subPanel then
      if panelIndex == self.curSubPanelIndex then
        subPanel:SetVisibility(UE4.ESlateVisibility.Visible)
      else
        subPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
      end
    end
  end
end

function UMG_PetLeftPanel_C:ChangeSubPanelState(_index, _isShow)
  if 1 == _index then
    Log.Error("ChangeSubPanelState index = 1\239\188\140\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\232\129\148\231\179\187jobhuang")
    return
  end
  if _index then
    local subPanel = self.subPanels[_index]
    if subPanel then
      if subPanel.OnPanelStateChange then
        tcall(subPanel, subPanel.OnPanelStateChange, _isShow)
      end
      if _isShow then
        subPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        subPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetLeftPanel_C:OnCloseButtonClicked()
  self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1007, "UMG_PetLeftPanel_C:OnCloseButtonClicked")
  self:HideSubPanel()
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:OnLeftCloseSubPanel()
    self:DispatchEvent(PetUIModuleEvent.OnShowPetRadar, self.uiData.petData)
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_Refresh_MainPet, 1, battlePetList)
  if self.ShowList then
    self:TryShowOrCloseList()
  end
end

function UMG_PetLeftPanel_C:OnOpenResonanceUI()
  local petInfos = {}
  for i, petData in ipairs(self.petList) do
    table.insert(petInfos, PetUtils.PetInfoCreate(petData.gid))
  end
  local petTeam = {pet_infos = petInfos}
  if nil == petTeam or petTeam.pet_infos == nil or 0 == #petTeam.pet_infos then
    local msg = _G.DataConfigManager:GetPetGlobalConfig("pet_no_synchron").str
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, msg)
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1290, "UMG_PetTeam_C:OnOpenResonanceUI")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPetTeamResonancePanel, petTeam)
end

function UMG_PetLeftPanel_C:OnBtnSetMainFightClick()
  local curPetInfo = self:GetCurPetInfo()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1001, "UMG_PetLeftPanel_C:OnBtnSetMainFightClick")
  self:DispatchEvent(PetUIModuleEvent.PET_UI_TEAMBTN_BTNCLICK, 1, curPetInfo)
end

function UMG_PetLeftPanel_C:OnBtnPetFangShengClick()
  local curPetInfo = self:GetCurPetInfo()
  if not curPetInfo then
    return
  end
  local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(curPetInfo.gid)
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(curPetInfo.base_conf_id)
  
  local function DialogCallBack(_petInfo, _ok)
    if _ok then
      NRCModuleManager:DoCmd(PetUIModuleCmd.SendFangShengPet, _petInfo.gid)
    end
  end
  
  if self:CanRelease() then
    local isAcceptTask = petData and petData.evolution_task and petData.evolution_task > 0
    local msgInfo
    if isAcceptTask then
      msgInfo = string.format(LuaText.umg_petleftpanel_5, petBaseConf.name, petBaseConf.name)
    else
      msgInfo = string.format(LuaText.umg_petleftpanel_6, petBaseConf.name)
    end
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local dialogContext = DialogContext()
    dialogContext:SetContent(msgInfo):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(luaText.YES, luaText.NO):SetCallback(curPetInfo, DialogCallBack)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, dialogContext)
  else
    NRCModuleManager:DoCmd(PetUIModuleCmd.SendFangShengPet, curPetInfo.gid)
  end
end

function UMG_PetLeftPanel_C:FangShengPet()
  local curPetInfo = self:GetCurPetInfo()
  if not curPetInfo then
    return
  end
  local have = HaveCarryon()
  if true == have then
  else
    NRCModuleManager:DoCmd(PetUIModuleCmd.SendFangShengPet, curPetInfo.gid)
  end
end

function UMG_PetLeftPanel_C:HaveCarryon()
  local curPetInfo = self:GetCurPetInfo()
  local num = #curPetInfo.possession.item
  if num > 0 then
    for i = 1, num do
      local possessItem = curPetInfo.possession.item[i]
      if possessItem.conf_id ~= nil and possessItem.conf_id > 0 then
        return true
      end
    end
  end
end

function UMG_PetLeftPanel_C:OpenEggPanel()
  if self:IsAnimationPlaying(self.In_FuDan) then
    return
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    return
  end
  if self:isClickBagOrEgg() then
    return
  end
  if self.petHeadList then
    local item = self.petHeadList:GetItemByIndex(0)
    if item then
      item.bFirstOpen = false
    end
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002001, "UMG_PetLeftPanel_C:OnBtnSetMainFightClick")
  _G.NRCModuleManager:DoCmd(PetUIModuleCmd.OpenPetHatchingPanel)
  self:ShowOrHideBloodIcon(false)
  self.petInfoMainCtrl.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petInfoMainCtrl.ViewingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petInfoMainCtrl:ShowHideGiftColleaguesBtn(false)
  self:DispatchEvent(PetUIModuleEvent.ShowHideTimeRewindBtn, false)
  if self.petInfoMainCtrl.ComboBox_Popup:GetVisibility() == UE4.ESlateVisibility.Visible then
    self.petInfoMainCtrl.ComboBox_Popup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.petInfoMainCtrl.IsShowShareBox = false
  end
  self:TryShowOrCloseList(false)
end

function UMG_PetLeftPanel_C:OnOpenEggClick(isShowOver)
  if isShowOver then
    return
  end
  self:TryShowOrCloseTeamSwitch(false)
  self:PlayAnimation(self.In_FuDan)
  self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:DispatchEvent(PetUIModuleEvent.PetBagNrcRedPointSetupKey, 0)
  self.petInfoMainCtrl:ShowOrHideCloseBtn(false)
  self.petInfoMainCtrl.ShareBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petInfoMainCtrl.ViewingBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petInfoMainCtrl:ShowHideGiftColleaguesBtn(false)
  self:SetTitleVisible(false)
  self:ShowOrHideBloodIcon(false)
end

function UMG_PetLeftPanel_C:OnCloseEggClick(isHatch)
  self:TryShowOrCloseTeamSwitch(true)
  self:PlayAnimation(self.Out_FuDan)
  self:ShowEggSpeedUp()
  self:UpdateHatchInfo()
  self:updatePetList(true)
  self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  self:SetTitleVisible(true)
  self:DispatchEvent(PetUIModuleEvent.PetBagNrcRedPointSetupKey, 0)
  if not isHatch then
    self.module.isHatchingPanel = false
    self:OnPetItemClick(1)
  end
  local isShow = self:GetPetEggBtnShow()
  self.PetEggBtn:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  self.petInfoMainCtrl:ShowOrHideCloseBtn(true)
  self:ShowOrHideBloodIcon(true)
  if self.petInfoMainCtrl.ShareIsOpen then
    self.petInfoMainCtrl.ShareBtn:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetLeftPanel_C:OnNRCButton_41Click()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1217, "UMG_PetLeftPanel_C:OnBtnSetMainFightClick")
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:showPetTotalWarehouse()
  end
  self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
end

function UMG_PetLeftPanel_C:OnBtnChangeTeamClick()
  local curPetInfo = self:GetCurPetInfo()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1001, "UMG_PetLeftPanel_C:OnBtnChangeTeamClick")
  self:DispatchEvent(PetUIModuleEvent.PET_UI_TEAMBTN_BTNCLICK, 2, curPetInfo)
end

function UMG_PetLeftPanel_C:SetInitPetId(_pet_gid)
  self.uiData.init_pet_gid = _pet_gid
end

function UMG_PetLeftPanel_C:updatePetList(_isActive, bIgnoreUpdateSelection, selectIndex)
  if not self.uiData then
    return
  end
  local petInfos = {}
  self.uiData.petInfos = petInfos
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if battlePetList then
    for i, petData in ipairs(battlePetList) do
      table.insert(petInfos, {
        gid = petData.gid,
        base_conf_id = petData.base_conf_id,
        showPetHp = true,
        level = petData.level,
        petData = petData,
        parent = self
      })
    end
  end
  for i = #petInfos + 1, 6 do
    table.insert(petInfos, {})
  end
  if 0 == self.petInfoMainCtrl.currentSelectedPetIndex or self.UpdateRefreshSelect then
    self.petInfoMainCtrl.currentSelectedPetIndex = 1
  end
  local SelectIndex = self.petInfoMainCtrl.currentSelectedPetIndex or selectIndex
  if bIgnoreUpdateSelection then
    SelectIndex = nil
  end
  self:RefreshCurTeamName()
  self:updatePetListView(petInfos, SelectIndex)
end

function UMG_PetLeftPanel_C:OpenPanelWithOnePet(petData)
  if self.IsOpenWithOne then
    self.TeamName:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_recommend:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.petHeadList:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TeamSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:IsShowTitle(false)
  end
  local petInfos = {}
  self.uiData.petInfos = petInfos
  table.insert(petInfos, {
    gid = petData.gid,
    base_conf_id = petData.base_conf_id,
    showPetHp = true,
    level = petData.level,
    petData = petData,
    parent = self
  })
  self:updatePetListView(petInfos, 1)
end

function UMG_PetLeftPanel_C:GetIsOpenWithOne()
  return self.IsOpenWithOne
end

function UMG_PetLeftPanel_C:IsShowTitle(isShow)
  self.CanvasPanel_Title:SetVisibility(isShow and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:OnPetItemClick(_index)
  if _index > 6 then
    self.petHeadList:ClearSelection()
    self:HideSubPanel()
    return
  end
  self.petHeadList:SelectItemByIndex(_index - 1)
end

function UMG_PetLeftPanel_C:OnGlobalPetItemClick(index)
  if self.keepSubPanel then
    self.keepSubPanel = false
  else
    self:HideSubPanel()
  end
  if nil ~= index and index > 6 then
    self.petHeadList:ClearSelection()
    return
  end
end

function UMG_PetLeftPanel_C:CanRelease()
  local petInfos = self.uiData.petInfos
  local aliveCnt = 0
  for i = 1, #petInfos do
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petInfos[i].gid)
    local maxHp, curHp = self:GetPetHP(petData)
    if curHp <= 0 then
      aliveCnt = aliveCnt + 1
    end
  end
  if aliveCnt <= 1 then
    return false
  else
    return true
  end
end

function UMG_PetLeftPanel_C:OnSelectPetChange(_petData)
  if not _petData then
    self:ChangeEmptyPet()
    return
  end
  self.uiData.BeForePetData = self.uiData.petData or _petData
  self.uiData.petData = _petData
  if self.uiData.BeForePetData.gid ~= self.uiData.petData.gid then
    self:SetPetNewSkillInfo(self.uiData.BeForePetData)
  end
  if _petData then
    self.uiData.petBaseConf = _G.DataConfigManager:GetPetbaseConf(_petData.base_conf_id)
  else
    self.uiData.petBaseConf = nil
  end
  local petBaseConf = self.uiData.petBaseConf
  self.Attribute:UpdatePetData(self.uiData)
  self:UpdatePetLevel()
  local curPetInfo = self:GetCurPetInfo()
  self:updateStateChangeTeamButton(curPetInfo)
  self.btnPetFangSheng:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:SetWeigthAndStature(self.uiData.petData)
end

function UMG_PetLeftPanel_C:SetWeigthAndStature(petData)
  if not petData.weight or not petData.height then
    return
  end
  local WeightData = petData.weight * 0.001
  local num = self:GetPreciseDecimal(WeightData, 2)
  self.State_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:GetPreciseDecimal(num, n)
  if type(num) ~= "number" then
    return num
  end
  n = n or 0
  n = math.floor(n)
  if n < 0 then
    n = 0
  end
  local decimal = 10 ^ n
  local temp = math.floor(num * decimal)
  return temp / decimal
end

function UMG_PetLeftPanel_C:OnEquippedSuccess(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetLeftPanel_C:OnUseExpItemSuccess(_changes)
  local petData = _changes[1].pet_data
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetLeftPanel_C:OnPetGroUpSuccess(_changes)
  local changes = _changes
  self:checkCurPetInfoChange(changes)
end

function UMG_PetLeftPanel_C:OnPetTraceBackSuccessAndRewardPopupClose(_changes)
  self:checkCurPetInfoChange(_changes, nil, EnumPetInfoChangeReasonType.TraceBack)
end

function UMG_PetLeftPanel_C:OnEvolutionSuccess(_changes, IsEvolutionSuccess)
  self:checkCurPetInfoChange(_changes, IsEvolutionSuccess)
end

function UMG_PetLeftPanel_C:OnEquipPossesionSuccess(_changes)
  Log.Dump(_changes, 6, "UMG_PetLeftPanel_C:OnEquipPossesionSuccess")
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetLeftPanel_C:OnUpdateImpressionGroup(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetLeftPanel_C:OnHideRetractionBtn(bHide)
  self.Attribute:CloseSwitchButton(bHide)
end

function UMG_PetLeftPanel_C:HavingUpgradeAndResonanceEvent(_changes)
  self:checkCurPetInfoChange(_changes)
end

function UMG_PetLeftPanel_C:SetPetNewSkillInfo(_PetData)
  local PetData = _PetData
  if 3 == self.curMenuButtonIndex then
    PetUtils.UpdatePetNewSkill(PetData)
  end
end

function UMG_PetLeftPanel_C:OnLeftPanelTeamButtonClick(_btnId, _petInfo)
  if not _petInfo or _petInfo.gid <= 0 then
    return
  end
  if 1 == _btnId then
    local dstPetInfo = self:getMainFightPet()
    if dstPetInfo and dstPetInfo.gid ~= _petInfo.gid then
      self.uiData.init_pet_gid = _petInfo.gid
      NRCModuleManager:DoCmd(PetUIModuleCmd.ChangePetPos2, _petInfo.gid, dstPetInfo.gid)
    end
  end
end

function UMG_PetLeftPanel_C:OnSetPetIsPlaySuccess(changes, bag_pos_gid)
end

function UMG_PetLeftPanel_C:OnChangePetBagPosComplete(bag_pos_gid)
  self:updatePetList(true)
  self.uiData.init_pet_gid = 0
end

function UMG_PetLeftPanel_C:PetTeamChanage(bag_pos_gid)
  if self.module:HasPanel("NewPetBag") then
    return
  end
  self:updatePetList(true, not self.UpdateRefreshSelect)
  self:UpdateBloodInfo()
  self.UpdateRefreshSelect = false
  self.uiData.init_pet_gid = 0
end

function UMG_PetLeftPanel_C:PetTeamOpend(_IsOpend)
  if _IsOpend then
    self.button_close:SetVisibility(UE4.ESlateVisibility.Hidden)
  else
    self.button_close:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_PetLeftPanel_C:OnPetFreeSuccess(_pet_gid)
  self:updatePetList(true)
  self.uiData.init_pet_gid = 0
end

function UMG_PetLeftPanel_C:OnGameLoginEvent(_isRelogin)
  if _isRelogin then
    local panelData, index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
    if not panelData then
      self:updatePetList(true)
      self.uiData.init_pet_gid = 0
    end
  end
end

function UMG_PetLeftPanel_C:OnUIPetChangeTeam(_srcPet_gid, _dstPet_gid)
  self.uiData.init_pet_gid = _srcPet_gid
end

function UMG_PetLeftPanel_C:OnUIChangeToEvolution()
  self:HideSubPanel()
  self:OnMenuButtonClick(2)
end

function UMG_PetLeftPanel_C:OnPlayerPetHPChange(_petData)
end

function UMG_PetLeftPanel_C:RemoveSkillNewState(gid)
  if self.uiData.petData and gid == self.uiData.petData.gid then
    self:SetSkillRedPointState()
  end
end

function UMG_PetLeftPanel_C:checkCurPetInfoChange(_changes, IsEvolutionSuccess, PetInfoChangeReasonType)
  local curPetData = self.uiData.petData
  if not curPetData or not _changes then
    return
  end
  local petData
  for i, changItem in ipairs(_changes) do
    if changItem.type == ProtoEnum.GoodsType.GT_PET then
      petData = changItem.pet_data
      self:ChangesInfo(petData, curPetData, IsEvolutionSuccess, PetInfoChangeReasonType)
    elseif changItem.type == ProtoEnum.GoodsType.GT_PETEXP then
      petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(changItem.gid)
      self:ChangesInfo(petData, curPetData, IsEvolutionSuccess)
    end
  end
end

function UMG_PetLeftPanel_C:ChangesInfo(petData, curPetData, IsEvolutionSuccess, PetInfoChangeReasonType)
  self:ResettingMenuSelect(petData.base_conf_id)
  self:UpdatePetListInfo(petData)
  if curPetData.gid == petData.gid then
    local PetIndex = self:UpdatePetInfo(petData)
    self:OnSelectPetChange(petData)
    if PetIndex > 0 then
      _G.DataModelMgr.PlayerDataModel:OnPlayerPetInfoChange(petData)
      if IsEvolutionSuccess then
        self:OnPetItemClick(PetIndex)
      end
      local Item = self.petHeadList:GetItemByIndex(PetIndex - 1)
      Item:UpdateNewData(petData, petData.base_conf_id, PetInfoChangeReasonType)
    end
  end
end

function UMG_PetLeftPanel_C:UpdatePetListInfo(_petData)
  for i, pet in ipairs(self.petList) do
    if pet.petData and pet.petData.gid == _petData.gid then
      pet.petData = _petData
    end
  end
  if self.petBagOpening then
    self:DispatchEvent(PetUIModuleEvent.PetBagUpdatePetListInfo, _petData)
  end
end

function UMG_PetLeftPanel_C:SetSkillRedPointState()
  local gid = self.uiData.petData.gid
  self:DispatchEvent(PetUIModuleEvent.RightPanelMenuBtnSetPoint, 2, gid)
end

function UMG_PetLeftPanel_C:SetImpressionPointState()
  Log.Error("\232\175\165\233\128\187\232\190\145\229\183\178\231\167\187\229\138\168\232\135\179\229\143\179\233\157\162\231\137\136\232\191\155\232\161\140\232\167\166\229\143\145\239\188\140\230\173\164\229\164\132\228\184\141\229\186\148\232\175\165\229\134\141\232\162\171\232\167\166\229\143\145\239\188\140\232\139\165\232\167\166\229\143\145\232\175\180\230\152\142\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\229\145\138\231\159\165jobhuang")
end

function UMG_PetLeftPanel_C:SetPetEvoPointState()
  Log.Error("\232\175\165\233\128\187\232\190\145\229\183\178\231\167\187\229\138\168\232\135\179\229\143\179\233\157\162\231\137\136\232\191\155\232\161\140\232\167\166\229\143\145\239\188\140\230\173\164\229\164\132\228\184\141\229\186\148\232\175\165\229\134\141\232\162\171\232\167\166\229\143\145\239\188\140\232\139\165\232\167\166\229\143\145\232\175\180\230\152\142\230\156\137\233\151\174\233\162\152\239\188\140\232\175\183\229\145\138\231\159\165jobhuang")
end

function UMG_PetLeftPanel_C:GetSelectPet()
  return self.uiData.petData
end

function UMG_PetLeftPanel_C:GetMenuButtonsIndex()
  return self.curMenuButtonIndex
end

function UMG_PetLeftPanel_C:UpdatePetInfo(petData)
  local petinfo = petData
  local selectItemIndex
  if petinfo.gid then
    for i, petInfo in ipairs(self.petList) do
      if petInfo.gid == petinfo.gid then
        selectItemIndex = i
        break
      end
    end
  end
  selectItemIndex = selectItemIndex or 0
  return selectItemIndex
end

function UMG_PetLeftPanel_C:OnMainUIPetSkillSelectChange(_skillData, _skillIndex)
end

function UMG_PetLeftPanel_C:setPetInfoMainCtrl(_petInfoMainCtrl)
  self.petInfoMainCtrl = _petInfoMainCtrl
end

function UMG_PetLeftPanel_C:GetAttributeIsVisible()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetAttributeOpenState()
  end
end

function UMG_PetLeftPanel_C:GetPetBagIsVisible()
  if self.petInfoMainCtrl then
    return self.petInfoMainCtrl:GetPetBagOpenState()
  end
end

function UMG_PetLeftPanel_C:AttributeChangeSetEggBtn(isShow)
  local isShowBtn = isShow and self:GetPetEggBtnShow()
  self.PetEggBtn:SetVisibility(isShowBtn and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:PetBagChangeSetEggBtn(isShow)
  local isOpenAttribute = self:GetAttributeIsVisible()
  if isOpenAttribute then
    isShow = false
  end
  local isShowBtn = isShow and self:GetPetEggBtnShow()
  self.PetEggBtn:SetVisibility(isShowBtn and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:GetPetHP(_petData)
  if _petData and _petData.attribute_new_info then
    local type = _G.ProtoEnum.AttributeType
    local addi_attr = _petData.attribute_new_info.addi_attr_data
    if addi_attr then
      return PetUtils.GetPetAdditionalByType(_petData, type.AT_HPMAX), PetUtils.GetPetAdditionalByType(_petData, type.AT_HPCUR)
    end
  end
  return 0, 0
end

function UMG_PetLeftPanel_C:GetCurPetInfo()
  local curPetData = self.uiData.petData
  if not curPetData or not self.petList then
    return nil
  end
  for _, petInfo in ipairs(self.petList) do
    if petInfo.gid == curPetData.gid then
      return petInfo
    end
  end
  return nil
end

function UMG_PetLeftPanel_C:setActive(_uiItem, _isShow)
  if _uiItem then
    if _isShow then
      _uiItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      _uiItem:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_PetLeftPanel_C:OpenPetToTalWareHouseUpdate()
  self:SetPetNewSkillInfo(self.uiData.petData)
  self:ChangeCurButtonState(false)
  self.curMenuButtonIndex = 1
  self:ChangeCurButtonState(true)
  self:HideSubPanel()
  self.Panel_Base:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:updateCloseButtonVisible()
  self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, false)
  self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
end

function UMG_PetLeftPanel_C:ClosePetToTalWareHouseUpdate()
  self:OnCloseButtonClicked()
  self:updatePetList(true)
  self.Panel_Base:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:DispatchEvent(PetUIModuleEvent.Hide_CloseBtn, true)
end

function UMG_PetLeftPanel_C:OpenPetFormation()
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl:showPetTotalWarehouse()
  end
  self:DispatchEvent(PetUIModuleEvent.SetPetModelLocation, UE4.FVector(1000, 1000, 1000))
  self.PetTotalWarehouse:OpenPetFormation()
end

function UMG_PetLeftPanel_C:OnAnimationFinished(Animation)
  if Animation == self.In and self.IsReverseAnimation == true then
    self.petInfoMainCtrl:ClosePanelInfo()
    self.IsReverseAnimation = false
  elseif Animation == self.Xuemaimofa_Out then
  end
  if Animation == self.In then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
    local IsCultivatePet = _G.NRCModuleManager:DoCmd(CampingModuleCmd.GetIsCultivatePet)
    local openPanelPetData, index, IsRevertMainPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
    if (IsCultivatePet or openPanelPetData) and not IsRevertMainPanel then
      self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  local bagPanelOpen = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetBagOpenState)
  if false == bagPanelOpen then
    if Animation == self.To_Jinhua_2 then
      self:DispatchEvent(PetUIModuleEvent.PetBagSetVisibility, UE4.ESlateVisibility.Collapsed)
    elseif Animation == self.BackTo_Jingling_2 then
      self:DispatchEvent(PetUIModuleEvent.PetBagSetVisibility, UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
  if Animation == self.In_FuDan then
    self.PetEggBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.Out_FuDan then
    local isShow = self:GetPetEggBtnShow()
    self.PetEggBtn:SetVisibility(isShow and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.PetBag_Open then
    self.PetEggBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif Animation == self.MoreList_out then
    self.MoreList:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if Animation == self.PetBag_Out then
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "PetInfoMain").LEFTPANELOPEN
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "PetInfoMain", touchReasonType)
  end
end

function UMG_PetLeftPanel_C:ChangePetNameByPetData(_PetData)
  for i, Pet in ipairs(self.petList) do
    if Pet.gid == _PetData.gid then
      local Item = self.petHeadList:GetItemByIndex(i - 1)
      Item:UpdatePetName(_PetData)
      self.Attribute:RefreshPetName(_PetData)
    end
  end
end

function UMG_PetLeftPanel_C:OnSelectPetEgg(index, eggInfo)
  self:ChangeSubPanelState(self.curSubPanelIndex, false)
  self:DispatchEvent(PetUIModuleEvent.RightPanelMenuBtnSetAllVisibility, UE4.ESlateVisibility.Collapsed)
end

function UMG_PetLeftPanel_C:DisableMenuButtons(isDisable)
  for i = 1, #self.menuButtons do
    local menuBtn = self.menuButtons[i]
    if menuBtn.data then
      menuBtn.data.isDisable = isDisable
    end
  end
end

function UMG_PetLeftPanel_C:PlayEvoPanelAnim(bEvo)
  if bEvo then
    self:TryShowOrCloseTeamSwitch(false)
    self:PlayAnimation(self.To_Jinhua_2)
  else
    self:TryShowOrCloseTeamSwitch(true)
    self:PlayAnimation(self.BackTo_Jingling_2)
  end
end

function UMG_PetLeftPanel_C:HiddenHeadListUI(_IsShow, IsMedalPanel)
  local openPanelPetData, index, IsRevertMainPanel = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetOpenPanelPetData)
  local petBagOpenState = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetPetBagOpenState)
  local isOpenNewPetBagPanel = self.module:HasPanel("NewPetBag")
  if _IsShow then
    if IsMedalPanel then
      self:PlayAnimation(self.JiangpaiList_out)
    elseif not self.module:HasPanel("PetSkillTips") then
      self:PlayAnimation(self.PetList_out)
    end
    self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not IsMedalPanel then
      self:SetTitleVisible(false)
      self:DispatchEvent(PetUIModuleEvent.PetSkillTipsOpen, true)
    end
  else
    if not (not openPanelPetData or IsRevertMainPanel) or isOpenNewPetBagPanel then
      self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if petBagOpenState then
      if IsMedalPanel then
        self:PlayAnimation(self.JiangpaiList_in)
      else
        self:SetTitleVisible(true)
        self:PlayAnimation(self.PetList_in)
      end
    elseif IsMedalPanel then
      self:PlayAnimation(self.JiangpaiList_in)
    else
      self:SetTitleVisible(true)
      self:PlayAnimation(self.PetList_in)
    end
    if not IsMedalPanel then
      self:DispatchEvent(PetUIModuleEvent.PetSkillTipsOpen, false)
    end
  end
end

function UMG_PetLeftPanel_C:TryOpenPetBag()
  if not self:OnPetBagBtnClick() then
    if self.TryOpenTime < 50 then
      self.TryOpenTime = self.TryOpenTime + 1
      self:DelayFrames(1, self.TryOpenPetBag, self)
    else
      Log.Warning("\232\181\132\230\186\144\230\178\161\230\156\137\229\138\160\232\189\189\230\136\144\229\138\159,\230\137\147\228\184\141\229\188\128\231\149\140\233\157\162!")
      self:updatePetList(true)
      if self.delayBagOpen then
        self.delayBagOpen()
        self.delayBagOpen = nil
      end
    end
  end
end

function UMG_PetLeftPanel_C:OnPetBagBtnClick()
  if not self.petInfoMainCtrl:GetOpenTwoPanelLevelSequenceIsLoad() then
    Log.Warning("\232\181\132\230\186\144\230\178\161\230\156\137\229\138\160\232\189\189\230\136\144\229\138\159,\229\133\136\228\184\141\232\131\189\230\137\147\229\188\128\233\154\143\232\186\171\232\131\140\229\140\133")
    return false
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    Log.Warning("\230\156\137\233\157\162\230\157\191\232\181\132\230\186\144\230\178\161\230\156\137\229\138\160\232\189\189\230\136\144\229\138\159,\229\133\136\228\184\141\232\131\189\230\137\147\229\188\128\233\154\143\232\186\171\232\131\140\229\140\133\233\152\178\230\173\162UI\233\135\141\229\143\160")
    return false
  end
  if self:isClickBagOrEgg() then
    return false
  end
  self:SetFirstOpen()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenNewPetBagPanel)
  self:TryShowOrCloseTeamSwitch(false)
  self:IsShowTitle(false)
  self.PetBagBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  return true
end

function UMG_PetLeftPanel_C:isClickBagOrEgg()
  if not self.isClickBagOrEggTime then
    self.isClickBagOrEggTime = os.time()
    return false
  elseif os.time() - self.isClickBagOrEggTime > 1 then
    self.isClickBagOrEggTime = os.time()
    return false
  end
  return true
end

function UMG_PetLeftPanel_C:SetFirstOpen()
  if self.petHeadList then
    local item = self.petHeadList:GetItemByIndex(0)
    if item then
      item.bFirstOpen = false
    end
  end
end

function UMG_PetLeftPanel_C:OnShareTeamItemSelect()
  local curTeamIndex = self.petBagTeamIndex and self.petBagTeamIndex - 1 or self.curTeamInfo.main_team_idx or 0
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenShareTeamPanel, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD, curTeamIndex)
end

function UMG_PetLeftPanel_C:OnLoadTeamItemSelect()
  local curTeamIndex = self.petBagTeamIndex and self.petBagTeamIndex - 1 or self.curTeamInfo.main_team_idx or 0
  NRCModuleManager:DoCmd(PetUIModuleCmd.OpenLoadPetTeamPanel, _G.ProtoEnum.PlayerTeamType.PTT_BIG_WORLD, curTeamIndex)
end

function UMG_PetLeftPanel_C:PetFriendInterfaceDisplay()
  self.CanvasPanel_123:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.info then
    local info = friendInfo.info
    if UE4.UObject.IsValid(self.NRCSwitcher_1) then
      self.NRCSwitcher_1:SetActiveWidgetIndex(1)
      self.Class:SetText(info.level)
      if friendInfo.type == _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
        self.AddFriends:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif friendInfo.type == _G.ProtoEnum.PlayerRelationshipType.PRT_FRIEND then
        self.AddFriends:SetVisibility(UE4.ESlateVisibility.Collapsed)
      elseif friendInfo.type == _G.ProtoEnum.PlayerRelationshipType.PRT_STRANGER then
        self.AddFriends:SetVisibility(UE4.ESlateVisibility.Visible)
      elseif friendInfo.type == _G.ProtoEnum.PlayerRelationshipType.PRT_FORBID then
        self.AddFriends:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if info.card_icon_selected and 0 ~= info.card_icon_selected then
        local CardIconConf = _G.DataConfigManager:GetCardIconConf(info.card_icon_selected)
        if CardIconConf then
          local path = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/"
          local AvatarPath = CardIconConf.icon_resource_path
          AvatarPath = string.format("%s%s.%s'", path, AvatarPath, AvatarPath)
          self.HeadPortrait:SetPath(AvatarPath)
        end
      end
    end
  end
end

function UMG_PetLeftPanel_C:CheckShowShareReward(data)
  if data.shareBaseId == self.shareBaseId and 0 == data.rewardGetState then
    local function cb()
      self.ShareUIReward:Init({
        shareBaseId = data.shareBaseId,
        
        isUpAnim = true
      })
    end
    
    self.shareDelayId = _G.DelayManager:DelayFrames(1, cb, self)
  end
end

function UMG_PetLeftPanel_C:CancelShareDelayId()
  if self.shareDelayId then
    _G.DelayManager:CancelDelayById(self.shareDelayId)
    self.shareDelayId = nil
  end
end

function UMG_PetLeftPanel_C:CheckShareIsOpen()
  self.shareBaseId = _G.Enum.ShareButtonType.SBT_TEAM_SHARE
  self.ShareIsOpen = _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.CheckIsOpen, self.shareBaseId)
end

function UMG_PetLeftPanel_C:SetEmptyHeadPutVisibility(visibility)
  if not self.petHeadList then
    return
  end
  local bLong = self.ThumbVersion == true
  for i = 0, self.petHeadList:GetItemCount() - 1 do
    local head = self.petHeadList:GetItemByIndex(i)
    if head then
      head:SetPutVisibility(visibility, bLong)
    end
  end
end

function UMG_PetLeftPanel_C:UpdateAllHeadsOnDrag(bDrag)
  if not self.petHeadList then
    return
  end
  local bLong = self.ThumbVersion == true
  local putVisibility = bDrag and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed
  for i = 0, self.petHeadList:GetItemCount() - 1 do
    local head = self.petHeadList:GetItemByIndex(i)
    if head and UE4.UObject.IsValid(head) then
      head:SetDragSelectState(bDrag)
      head:SetPutVisibility(putVisibility, bLong)
    end
  end
end

function UMG_PetLeftPanel_C:EnsureDragInstance()
  if not self.dragInstance or not UE4.UObject.IsValid(self.dragInstance) then
    self.dragInstance = UE4.UWidgetBlueprintLibrary.Create(self, self.DragItem)
    if self.dragInstance then
      self.dragInstance:AddToViewport(_G.UILayerCtrlCenter.ENUM_LAYER.TOP_MSG, false)
      self.dragInstance:SetAlignmentInViewport(UE4.FVector2D(0.5, 0.5))
    end
  end
end

function UMG_PetLeftPanel_C:FindFirstEmptySlotIndex(excludeIndex)
  local count = self.petHeadList:GetItemCount()
  for i = 0, count - 1 do
    if i ~= excludeIndex then
      local item = self.petHeadList:GetItemByIndex(i)
      if item and UE4.UObject.IsValid(item) then
        local gid = item.uiData and item.uiData.gid
        if not gid or 0 == gid then
          return i
        end
      end
    end
  end
  return nil
end

function UMG_PetLeftPanel_C:ResolveDragTargetIndex()
  local targetIndex = self.dragHoverIndex
  if nil == targetIndex then
    return nil
  end
  local targetItem = self.petHeadList:GetItemByIndex(targetIndex)
  if not targetItem or not UE4.UObject.IsValid(targetItem) then
    return nil
  end
  local targetGid = targetItem.uiData and targetItem.uiData.gid
  if not targetGid or 0 == targetGid then
    targetIndex = self:FindFirstEmptySlotIndex(self.dragSourceIndex)
  end
  return targetIndex
end

function UMG_PetLeftPanel_C:CachePetHeadItemRects()
  self.cachedHeadItemRects = {}
  local count = self.petHeadList:GetItemCount()
  local bLong = self.ThumbVersion == true
  for i = 0, count - 1 do
    local item = self.petHeadList:GetItemByIndex(i)
    if item and UE4.UObject.IsValid(item) then
      local rect = bLong and item:GetLongRect() or item:GetShortRect()
      self.cachedHeadItemRects[i] = {
        pos = rect.pos,
        size = rect.size,
        item = item
      }
    end
  end
end

function UMG_PetLeftPanel_C:GetHitHeadItemIndex(position)
  if not self.cachedHeadItemRects then
    return nil
  end
  local dragItemRect
  if self.dragInstance and UE4.UObject.IsValid(self.dragInstance) then
    local bLong = self.ThumbVersion == true
    dragItemRect = self.dragInstance:GetDragItemRect(bLong)
  end
  if dragItemRect then
    local realPosition = dragItemRect.pos
    local dragLeft = realPosition.X
    local dragRight = realPosition.X + dragItemRect.size.X
    local dragTop = realPosition.Y
    local dragBottom = realPosition.Y + dragItemRect.size.Y
    for i, rect in pairs(self.cachedHeadItemRects) do
      if rect.pos and rect.size then
        local itemLeft = rect.pos.X
        local itemRight = rect.pos.X + rect.size.X
        local itemTop = rect.pos.Y
        local itemBottom = rect.pos.Y + rect.size.Y
        if dragLeft < itemRight and dragRight > itemLeft and dragTop < itemBottom and dragBottom > itemTop then
          return i
        end
      end
    end
  end
  return nil
end

function UMG_PetLeftPanel_C:UpdateDragInstancePosition(position)
  if not self.dragInstance or not UE4.UObject.IsValid(self.dragInstance) then
    return
  end
  local viewportPos = UIUtils.ScreenPositionToViewport(position)
  self.dragInstance:SetPositionInViewport(viewportPos, false)
end

function UMG_PetLeftPanel_C:UpdateDragHover(position)
  local hitIndex = self:GetHitHeadItemIndex(position)
  if hitIndex == self.dragSourceIndex then
    hitIndex = nil
  end
  if hitIndex == self.dragHoverIndex then
    return
  end
  local bLong = self.ThumbVersion == true
  if self.dragHoverIndex ~= nil then
    local oldRect = self.cachedHeadItemRects[self.dragHoverIndex]
    if oldRect and oldRect.item and UE4.UObject.IsValid(oldRect.item) then
      oldRect.item:SetDragHover(false, bLong)
    end
  end
  self.dragHoverIndex = hitIndex
  if self.dragHoverIndex ~= nil then
    local newRect = self.cachedHeadItemRects[self.dragHoverIndex]
    if newRect and newRect.item and UE4.UObject.IsValid(newRect.item) then
      newRect.item:SetDragHover(true, bLong)
    end
  end
end

function UMG_PetLeftPanel_C:StartDrag(position)
  if not self.DragItem then
    Log.Warning("UMG_PetLeftPanel_C:StartDrag DragItem \230\156\170\233\133\141\231\189\174")
    return
  end
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl.BorderMask:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  local bLong = self.ThumbVersion == true
  self:CachePetHeadItemRects()
  self:EnsureDragInstance()
  if self.dragInstance then
    self.dragInstance:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
    local sourceItem = self.petHeadList and self.petHeadList:GetItemByIndex(self.dragSourceIndex)
    local sourcePetData = sourceItem and sourceItem.uiData and sourceItem.uiData.petData
    if sourcePetData then
      self.dragInstance:SetDragData(sourcePetData, bLong)
    end
    self:UpdateDragInstancePosition(position)
  end
  self.isDragging = true
  self.dragHoverIndex = nil
  if self.petHeadList then
    self.petHeadList:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  end
  if self.petHeadList and self.dragSourceIndex ~= nil then
    local sourceHead = self.petHeadList:GetItemByIndex(self.dragSourceIndex)
    if sourceHead and UE4.UObject.IsValid(sourceHead) then
      sourceHead:SetDragSelf(true, bLong)
    end
  end
  self:UpdateAllHeadsOnDrag(true)
  self:TryShowOrCloseTeamSwitch(false)
end

function UMG_PetLeftPanel_C:EndDrag()
  local bLong = self.ThumbVersion == true
  self:TryExchangePetOnDragEnd()
  if self.dragHoverIndex ~= nil and self.cachedHeadItemRects then
    local rect = self.cachedHeadItemRects[self.dragHoverIndex]
    if rect and rect.item and UE4.UObject.IsValid(rect.item) then
      rect.item:SetDragHover(false, bLong)
    end
    self.dragHoverIndex = nil
  end
  if self.dragInstance and UE4.UObject.IsValid(self.dragInstance) then
    self.dragInstance:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.isDragging = false
  if self.petHeadList and nil ~= self.dragSourceIndex then
    local sourceHead = self.petHeadList:GetItemByIndex(self.dragSourceIndex)
    if sourceHead and UE4.UObject.IsValid(sourceHead) then
      sourceHead:SetDragSelf(false, bLong)
    end
  end
  self.dragSourceIndex = nil
  self.cachedHeadItemRects = nil
  if self.petHeadList then
    self.petHeadList:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self:UpdateAllHeadsOnDrag(false)
  if self.longPressDelayHandle then
    _G.DelayManager:CancelDelay(self.longPressDelayHandle)
    self.longPressDelayHandle = nil
  end
  self:TryShowOrCloseTeamSwitch(true)
end

function UMG_PetLeftPanel_C:TryExchangePetOnDragEnd()
  if self.dragSourceIndex == nil then
    return
  end
  local sourceItem = self.petHeadList and self.petHeadList:GetItemByIndex(self.dragSourceIndex)
  if not sourceItem or not UE4.UObject.IsValid(sourceItem) then
    return
  end
  local sourceGid = sourceItem.uiData and sourceItem.uiData.gid
  if not sourceGid or 0 == sourceGid then
    return
  end
  local targetIndex = self:ResolveDragTargetIndex()
  if nil == targetIndex or targetIndex == self.dragSourceIndex then
    return
  end
  local finalTargetItem = self.petHeadList:GetItemByIndex(targetIndex)
  if not finalTargetItem or not UE4.UObject.IsValid(finalTargetItem) then
    return
  end
  local targetGid = finalTargetItem.uiData and finalTargetItem.uiData.gid
  if sourceGid == targetGid then
    return
  end
  local sourceTeamIndex = _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(sourceGid)
  if not sourceTeamIndex then
    return
  end
  local targetTeamIndex = targetGid and 0 ~= targetGid and _G.DataModelMgr.PlayerDataModel:GetPlayerBattleTeamIndexByGid(targetGid) or sourceTeamIndex
  local ori_info = {
    pet_gid = sourceGid,
    is_in_team = true,
    id = sourceTeamIndex,
    pos = self.dragSourceIndex + 1
  }
  local tar_info = {
    pet_gid = targetGid or 0,
    is_in_team = true,
    id = targetTeamIndex,
    pos = targetIndex + 1
  }
  self.pendingDragGid = sourceGid
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxChangePetReq, ori_info, tar_info)
end

function UMG_PetLeftPanel_C:OnBigWorldTeamPetChangeEvent()
  if self.pendingDragGid then
    local pendingGid = self.pendingDragGid
    self.pendingDragGid = nil
    local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
    local newIndex
    if battlePetList then
      for i, petData in ipairs(battlePetList) do
        if petData.gid == pendingGid then
          newIndex = i
          break
        end
      end
    end
    if newIndex then
      self.petInfoMainCtrl.currentSelectedPetIndex = newIndex
    end
    self:updatePetList()
  end
end

function UMG_PetLeftPanel_C:SetDragItemTemp(dragItem)
  if self.longPressDelayHandle then
    _G.DelayManager:CancelDelay(self.longPressDelayHandle)
    self.longPressDelayHandle = nil
  end
  if self.touchStartPosition and dragItem then
    self.dragSourceIndex = dragItem.index - 1
    self.longPressDelayHandle = _G.DelayManager:DelaySeconds(self.LongPressTime, function()
      self.longPressDelayHandle = nil
      if not self.isDragging and not self.petBagOpening then
        self:StartDrag(self.touchStartPosition)
      end
    end)
  end
end

function UMG_PetLeftPanel_C:OnRocoTouchStartHandler(touchIndex, position)
  self.touchStartPosition = UE4.FVector2D(position.X, position.Y)
  self.isDragging = false
end

function UMG_PetLeftPanel_C:OnRocoTouchMoveHandler(touchIndex, position)
  if not self.isDragging then
    return
  end
  self:UpdateDragInstancePosition(position)
  self:UpdateDragHover(position)
end

function UMG_PetLeftPanel_C:OnRocoTouchEndHandler(touchIndex)
  self:LeaveDragState()
end

function UMG_PetLeftPanel_C:LeaveDragState()
  self.touchStartPosition = nil
  if self.longPressDelayHandle then
    _G.DelayManager:CancelDelay(self.longPressDelayHandle)
    self.longPressDelayHandle = nil
  end
  if self.petInfoMainCtrl then
    self.petInfoMainCtrl.BorderMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.isDragging then
    self:EndDrag()
  end
end

return UMG_PetLeftPanel_C
