local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local TeamBattleModuleEnum = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEnum")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TeamBattleModuleEvent = require("NewRoco.Modules.System.TeamBattle.TeamBattleModuleEvent")
local MagicManualUtils = require("NewRoco/Modules/System/MagicManual/MagicManualUtils")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local UMG_PrewarInformation_C = _G.NRCPanelBase:Extend("UMG_PrewarInformation_C")

function UMG_PrewarInformation_C:OnConstruct()
  self.data = self.module:GetData("TeamBattleModuleData")
  self.hintCountDownTime = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_teammate_wait_time", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_UI, "PreWarInformation")
  self.bgProxy = _G.NRCModuleManager:DoCmd(TUIModuleCmd.PushBlackBackgroundWidgets, {
    self.NRCImage_125,
    self.NRCImage_58
  })
  self.TheShinyFlowerDescField = MagicManualUtils.InitFlowerCueBubble(self.CueBubble, self, self.OnGetFlowerData)
  self.NotCollectedText:SetText(string.format("(%s)", LuaText.pet_not_collected))
end

function UMG_PrewarInformation_C:OnActive(challengeType, param, bOwner)
  NRCModeManager:GetCurMode():DisablePanelByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.AddToDisableLobbyMainPopUpList, "PreWarInformation")
  _G.NRCAudioManager:PlaySound2DAuto(40007007, "UMG_PrewarInformation_C:OnActive")
  self:OnAddEventListener()
  self.challengeType = challengeType
  self.AgreeChallenge = false
  self.module.CurChallengeType = self.challengeType
  self.uiData = param
  self.bOwner = bOwner
  self.bShowCountDown = false
  self.countDownTip = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_text_team", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
  self.data.TargetNPCLogicId = param.npc_logic_id
  self.data.TargetNPCActorId = param.npc_obj_id
  self.data.TargetNPCContentID = param.npc_logic_id >> 32
  self:UpdatePanelInfo()
  UE4Helper.SetDesiredShowCursor(true, "UMG_PrewarInformation_C")
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.ResumeTip, TipEnum.TipsPauseReason.ExchangeVisitsHint)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").TEAMBATTLE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST_SINGLE then
    _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.OnOnlyZoneQueryBeastChallengeReq)
  end
  self.ItemRequired:SetText(LuaText.worldmap_tips_reward_text)
  if param.bind_pet_gid and 0 ~= param.bind_pet_gid then
    self.bGetMedal = true
  else
    self.bGetMedal = false
  end
  self:SetFlowerSeedFusionInfo()
end

function UMG_PrewarInformation_C:SetFlowerSeedFusionInfo()
  if self.uiData.visit_flower_seed_boss_datas then
    self.SharedFlowerSeeds:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local visit_flower_seed_boss_datas = {}
    local VisitOwnerData = MagicManualUtils.GetFlowerSeedFusionDataByData(self.uiData)
    table.insert(visit_flower_seed_boss_datas, {data = VisitOwnerData, isTip = false})
    for k, v in ipairs(self.uiData.visit_flower_seed_boss_datas) do
      table.insert(visit_flower_seed_boss_datas, {data = v, isTip = false})
    end
    
    local function SortVisitFlowerData(a, b)
      local A_owner_id = a.data and a.data.owner_id
      local B_owner_id = b.data and b.data.owner_id
      local aIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, A_owner_id) or 99
      local bIndex = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorIndex, B_owner_id) or 99
      return aIndex < bIndex
    end
    
    table.sort(visit_flower_seed_boss_datas, SortVisitFlowerData)
    self.SharedFriendsHeadItem:InitGridView(visit_flower_seed_boss_datas)
    self.SharedFriendsHeadItem:SetItemClickAble(true)
    if self.uiData.select_flower_owner_id and self.uiData.select_flower_owner_id ~= _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin() then
      Log.Debug("UMG_PrewarInformation_C:SetFlowerSeedFusionInfo", self.uiData.select_flower_owner_id)
      local index = 0
      local visit_flower_seed_boss_data
      for i, v in pairs(visit_flower_seed_boss_datas) do
        if v.data and v.data.owner_id == self.uiData.select_flower_owner_id then
          index = i - 1
          visit_flower_seed_boss_data = v
          break
        end
      end
      if visit_flower_seed_boss_data then
        self:SetVisitSelectTeamBattlePetRsp(visit_flower_seed_boss_data.data, true)
      end
      if _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
        self.SharedFriendsHeadItem:SelectItemByIndex(index)
      else
        local item = self.SharedFriendsHeadItem:GetItemByIndex(index)
        if item and item.Selected then
          item.Selected:SetVisibility(UE.ESlateVisibility.selfHitTestInvisible)
        end
      end
    elseif _G.DataModelMgr.PlayerDataModel:IsVisitOwner() then
      self.SharedFriendsHeadItem:SelectItemByIndex(0)
    else
      local item = self.SharedFriendsHeadItem:GetItemByIndex(0)
      if item and item.Selected then
        item.Selected:SetVisibility(UE.ESlateVisibility.selfHitTestInvisible)
      end
    end
  else
    self.SharedFlowerSeeds:SetVisibility(UE.ESlateVisibility.Collapsed)
  end
end

function UMG_PrewarInformation_C:SetVisitSelectTeamBattlePet(uin, npc_logic_id)
  self.module:SetVisitSelectTeamBattlePet(uin, npc_logic_id)
end

function UMG_PrewarInformation_C:SetVisitSelectTeamBattlePetRsp(visit_flower_seed_boss_data, isOpenSet)
  if visit_flower_seed_boss_data and (_G.DataModelMgr.PlayerDataModel:IsVisitOwner() or isOpenSet) then
    self.inner_petbase_id = visit_flower_seed_boss_data.inner_petbase_id
    self.inner_glass_info = visit_flower_seed_boss_data.inner_glass_info
    self.inner_spec_flower_seed_id = visit_flower_seed_boss_data.spec_flower_seed_id
    self.owner_id = visit_flower_seed_boss_data.owner_id
    local BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, visit_flower_seed_boss_data.inner_petbase_id)
    if BookState == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      self.NotCollectedText:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      self.NotCollectedText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    local levelText, IsReCom = MagicManualUtils.GetFlowerLevel(visit_flower_seed_boss_data.seed_star, visit_flower_seed_boss_data.spec_flower_seed_id)
    self.IsReCom = IsReCom
    if IsReCom then
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    else
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
    end
    self.Text_Grade:SetText(string.format(LuaText.umg_petskilltemple2_1, levelText))
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(visit_flower_seed_boss_data.inner_petbase_id)
    local petAttrData = {}
    local unit_type = petBaseConf and petBaseConf.unit_type or {}
    for i = 1, #unit_type do
      local petType = petBaseConf.unit_type[i]
      table.insert(petAttrData, {Type = petType})
    end
    self.Attr_Pet:InitGridView(petAttrData)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      if modelConf then
        self.PetIcon:SetPath(modelConf.icon)
      end
    end
  end
end

function UMG_PrewarInformation_C:OnDeactive()
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.RemoveFromDisableLobbyMainPopUpList, "PreWarInformation")
  NRCModeManager:GetCurMode():RevertPanelEnableStateByLayer(Enum.UILayerType.UI_LAYER_MAIN)
  self:OnRemoveEventListener()
  UE4Helper.ReleaseDesiredShowCursor("UMG_PrewarInformation_C")
end

function UMG_PrewarInformation_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_Challenge.btnLevelUp, self.OnChallengeClicked)
  self:AddButtonListener(self.Btn_Challenge_1.btnLevelUp, self.OnCloseBtnClicked)
  _G.NRCEventCenter:RegisterEvent("UMG_PrewarInformation_C", self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.UpdateStarNum)
  _G.NRCEventCenter:RegisterEvent("UMG_PrewarInformation_C", self, TeamBattleModuleEvent.SetVisitSelectTeamBattlePet, self.SetVisitSelectTeamBattlePet)
  self:RegisterEvent(self, TeamBattleModuleEvent.StarNumChange, self.UpdateHealth)
  self:RegisterEvent(self, TeamBattleModuleEvent.CloseInformationPanel, self.DoClose)
  self.Btn_Challenge.btnLevelUp.OnPressed:Add(self, self.OnChallengePressed)
  self.Btn_Challenge.btnLevelUp.OnReleased:Add(self, self.OnChallengeReleased)
  self:AddButtonListener(self.DepartmentBtn, self.OnOpenPetTips)
  self:AddButtonListener(self.FlowerBloodBtn, self.OnOpenBloodTips)
  self:AddButtonListener(self.UMG_Details.btnLevelUp, self.OnOpenPetInfoPanel)
end

function UMG_PrewarInformation_C:OnGetFlowerData()
  return self.FlowerInfo
end

function UMG_PrewarInformation_C:UpdateShinyFlowerTips()
  self.FlowerInfo = nil
  if (self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM) and 0 ~= (self.uiData and self.uiData.spec_flower_seed_id or 0) then
    local SceneNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.data.TargetNPCActorId)
    if SceneNpc then
      local bFlower = SceneNpc.config.genre == Enum.ClientNpcType.CNT_FLOWER_SEED
      if bFlower then
        local NpcRefreshId = SceneNpc.serverData.npc_base.npc_content_cfg_id
        local FlowerInfo, FlowerTypeWrap = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetNpcFlowerInfo, NpcRefreshId)
        self.FlowerInfo = FlowerInfo
        self.FlowerTypeWrap = FlowerTypeWrap
        if FlowerInfo then
          local TypeWrap = FlowerTypeWrap
          if TypeWrap.IsShinyFlower then
            MagicManualUtils.RefreshCurBubbleText(self.TheShinyFlowerDescField, NpcRefreshId)
            self.CueBubble.Switcher:SetActiveWidgetIndex(1)
            self.CueBubble:SetVisibility(UE.ESlateVisibility.Visible)
            self.bg:SetPath(self.shiny_bg_icon_soft_path.AssetPathName)
            self.CampBG:SetPath(self.shiny_icon_soft_path.AssetPathName)
            local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.uiData.battle_petbase_id)
            if petBaseConf then
              local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
              if modelConf then
                self.PetIcon:SetPath(modelConf.shiny_icon)
              end
            end
            self.npcName:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("272727FF"))
            self.NRCText_34:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
            self.TextQuantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
            self.TextQuantity_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
            self.Name:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
            self.NRCImage_bg:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("016FAEFF"))
          elseif TypeWrap.Is7StarHardFlower then
            MagicManualUtils.RefreshCueBubbleNature(self.CueBubble, FlowerInfo)
            self.CueBubble.Switcher:SetActiveWidgetIndex(1)
            self.CueBubble:SetVisibility(UE.ESlateVisibility.Visible)
            self.bg:SetPath(self.star7_hard_bg_icon_soft_path.AssetPathName)
            self.Img_di:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
          return
        end
      end
    end
  end
  self.CueBubble:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function UMG_PrewarInformation_C:UpdateStarNum(GoodsChangeItem)
  local costItemId, _ = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, self.data.TargetNPCContentID)
  if GoodsChangeItem.id == costItemId then
    self:UpdateHealth()
  end
end

local function OpenSelfFunc()
  _G.NRCModuleManager:DoCmd(_G.TeamBattleModuleCmd.TempDisableTeamBattlePanel, true)
end

function UMG_PrewarInformation_C:OnEnable()
  self:UpdatePanelInfo()
  self:OnAddDynamicIMC()
end

function UMG_PrewarInformation_C:OnDisable()
  self:OnRemoveDynamicIMC()
end

function UMG_PrewarInformation_C:UpdateHealth()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    local StarDebrisNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR_DEBRIS)
    StarDebrisNum = StarDebrisNum or 0
    local staminaA = _G.DataConfigManager:GetRoleGlobalConfig("star_debris_top_limit")
    local StaminaProportionA = ""
    if StarDebrisNum == staminaA.num then
      self.MoneyBtn2.SumNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("FFC65FFF"))
      StaminaProportionA = string.format("%s   \230\187\161", staminaA.num)
    elseif StarDebrisNum >= 0 then
      StaminaProportionA = string.format("%s", StarDebrisNum)
    end
    self.MoneyBtn2:SetSourceReturnFlagAndFunc(true, OpenSelfFunc)
    self.MoneyBtn2:SetCurrentEnterType(self.MoneyBtn2.EnterType.BloodBattle)
    self.MoneyBtn2:SetInfo(_G.Enum.VisualItem.VI_STAR_DEBRIS, StaminaProportionA, true)
    local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    local staminaB = _G.DataConfigManager:GetRoleGlobalConfig("star_top_limit")
    local StaminaProportionB = string.format("%s%s%s", StarNum, "/", staminaB.num)
    self.MoneyBtn2_1:SetSourceReturnFlagAndFunc(true, OpenSelfFunc)
    self.MoneyBtn2_1:SetCurrentEnterType(self.MoneyBtn2_1.EnterType.BloodBattle)
    self.MoneyBtn2_1:SetInfo(_G.Enum.VisualItem.VI_STAR, StaminaProportionB, true)
    if StarNum >= _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_starlink", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num then
    end
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
    local starNum1 = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    self.MoneyBtn2_1:SetSourceReturnFlagAndFunc(true, OpenSelfFunc)
    self.MoneyBtn2_1:SetCurrentEnterType(self.MoneyBtn2_1.EnterType.BloodBattle)
    self.MoneyBtn2_1:SetInfo(_G.Enum.VisualItem.VI_STAR, starNum1, true)
    local costItemId, _ = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, self.data.TargetNPCContentID)
    local itemConf = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItemId)
    local starNum2 = 0
    if nil == itemConf then
      starNum2 = 0
    else
      starNum2 = itemConf.num
    end
    self.MoneyBtn2:SetSourceReturnFlagAndFunc(true, OpenSelfFunc)
    self.MoneyBtn2:SetCurrentEnterType(self.MoneyBtn2.EnterType.BloodBattle)
    self.MoneyBtn2:SetInfo(costItemId, starNum2, false)
  end
end

function UMG_PrewarInformation_C:OnRemoveEventListener()
  NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.GoodChangeTypeEnum.GT_BAGITEM, self.UpdateStarNum)
  NRCEventCenter:UnRegisterEvent(self, TeamBattleModuleEvent.SetVisitSelectTeamBattlePet, self.SetVisitSelectTeamBattlePet)
  self:UnRegisterEvent(self, TeamBattleModuleEvent.StarNumChange, self.UpdateHealth)
  self.Btn_Challenge.btnLevelUp.OnPressed:Remove(self, self.OnChallengePressed)
  self.Btn_Challenge.btnLevelUp.OnReleased:Remove(self, self.OnChallengeReleased)
  self:RemoveButtonListener(self.DepartmentBtn)
  self:RemoveButtonListener(self.FlowerBloodBtn)
  self:RemoveButtonListener(self.UMG_Details.btnLevelUp)
end

function UMG_PrewarInformation_C:OnDestruct()
  self.module.CanSetTeamBattle = false
  _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenOrCloseMainUIDownTips, true, "OpenTeamBattlePreWarInfo")
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_UI, "PreWarInformation")
  _G.NRCModuleManager:DoCmd(TUIModuleCmd.PopBlackBackgroundWidgets, self.bgProxy)
end

function UMG_PrewarInformation_C:OnTick(deltaTime)
  if self.bOwner then
    if self.bShowCountDown and self.module.LeftTime >= 0 then
      local countDownText = string.format(self.countDownTip, math.ceil(self.module.LeftTime))
      self.Text_Hint:SetText(countDownText)
      local percent = self.module.LeftTime / self.module.CountDownTime
      self.JinduProgressBar:SetPercent(percent)
    end
    if self.bShowCountDown and self.module.LeftTime <= 0 then
      self:DoClose()
    end
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
    if self.bShowCountDown and self.module.LeftTime >= 0 then
      local countDownText = string.format(self.countDownTip, math.ceil(self.module.LeftTime))
      self.Text_Hint:SetText(countDownText)
      local percent = self.module.LeftTime / self.module.CountDownTime
      self.JinduProgressBar:SetPercent(percent)
    end
    if self.bShowCountDown and self.module.LeftTime <= 0 then
      self:DoClose()
    end
  else
    if self.bShowCountDown and self.module.HintLeftTime >= 0 then
      local countDownText = string.format(self.countDownTip, math.ceil(self.module.HintLeftTime))
      self.Text_Hint:SetText(countDownText)
      local percent = self.module.HintLeftTime / self.hintCountDownTime
      self.JinduProgressBar:SetPercent(percent)
    end
    if self.bShowCountDown and self.module.HintLeftTime <= 0 then
      local bTeamBattle = self.module:OnCmdGetEnterTeamBattleType()
      if bTeamBattle and not self.bOwner then
        if not self.AgreeChallenge then
          Log.Info("UMG_TeamBattle_ChangePet_C::OnZoneTeamBattleConfirmInviteReq false OnTick")
          self.module:OnZoneTeamBattleConfirmInviteReq(false)
        else
          Log.Info("UMG_TeamBattle_ChangePet_C::OnZoneTeamBattleConfirmInviteReq true OnTick")
        end
      end
      self:DoClose()
    end
  end
end

function UMG_PrewarInformation_C:OnCloseBtnClicked()
  _G.NRCAudioManager:PlaySound2DAuto(41401002, "UMG_TeamBattle_ChangePet_C:OnConfirmBtnClicked")
  local bTeamBattle = self.module:OnCmdGetEnterTeamBattleType()
  if bTeamBattle and not self.bOwner then
    Log.Info("UMG_TeamBattle_ChangePet_C::OnZoneTeamBattleConfirmInviteReq false  OnCloseBtnClicked")
    self.module:OnZoneTeamBattleConfirmInviteReq(false)
  end
  self.module:ClearFusionInfo()
  self:OnClose()
end

function UMG_PrewarInformation_C:OnChallengePressed()
  self:PlayAnimation(self.Btn_Press)
end

function UMG_PrewarInformation_C:OnChallengeReleased()
end

function UMG_PrewarInformation_C:TryEnterShinyFlowerChallengeNotify()
  if self.uiData and self.uiData.npc_cfg_id then
    local SceneNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.data.TargetNPCActorId)
    if SceneNpc then
      local bFlower = SceneNpc.config.genre == Enum.ClientNpcType.CNT_FLOWER_SEED
      if bFlower then
        local NpcRefreshId = SceneNpc.serverData.npc_base.npc_content_cfg_id
        local FlowerInfo = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcFlowerInfo, NpcRefreshId)
        if FlowerInfo then
          local ThrowCount = NRCModuleManager:DoCmd(MagicManualModuleCmd.GetShinyNpcTeamBattleThrowCount, NpcRefreshId)
          if ThrowCount > 0 then
            local PetBallIdList = ActivityUtils.GetActivityGlobalConfig("ShinyFlower_again_use_ball").numList
            local bHasBalls = false
            for _, BallId in ipairs(PetBallIdList) do
              local Item, Number = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemByID, BallId)
              if Number and Number > 0 then
                bHasBalls = true
                break
              end
            end
            if not bHasBalls then
              self:InternalNotifyAnyThrowCount()
              return true
            end
          else
            self:InternalNotifyNoThrowCount()
            return true
          end
        end
      end
    end
  end
end

function UMG_PrewarInformation_C:InternalNotifyNoThrowCount()
  self:SetVisibility(UE.ESlateVisibility.Hidden)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(LuaText.TIPS):SetContent(LuaText.ShinyFlower_first_popup):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.OK, LuaText.CANCEL):SetCloseOnOK(true):SetCallback(self, self.InternalEnterChallenge)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_PrewarInformation_C:InternalNotifyAnyThrowCount()
  self:SetVisibility(UE.ESlateVisibility.Hidden)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  Context:SetTitle(LuaText.TIPS):SetContent(LuaText.ShinyFlower_again_popup):SetContentTextJustify(UE4.ETextJustify.Left):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.OK, LuaText.CANCEL):SetCloseOnOK(true):SetCallback(self, self.InternalEnterChallenge)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_PrewarInformation_C:InternalEnterChallenge(bEnterConfirmed)
  self:SetVisibility(UE.ESlateVisibility.Visible)
  if not bEnterConfirmed then
    return
  end
  local bTeamBattle = self.module:OnCmdGetEnterTeamBattleType()
  if bTeamBattle then
    local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
    if bOwner then
      if not self.module.CanSetTeamBattle then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.Error_Code_50185)
        return
      end
      self.module:OnCmdOpenTeamBattleStartConfirmTips()
      self:OnClose()
    else
      Log.Info("UMG_TeamBattle_ChangePet_C::OnZoneTeamBattleConfirmInviteReq true  InternalEnterChallenge")
      self.AgreeChallenge = true
      self.module:OnZoneTeamBattleConfirmInviteReq(true)
    end
  else
    local Module = self.module
    local ActorId = self.data:GetCurNPCActorId()
    local NpcLogicId = self.data.TargetNPCLogicId
    self:OnClose()
    if self.FlowerTypeWrap and self.FlowerTypeWrap.Is7StarHardFlower then
      if self.bGetMedal then
        self.data:SetHardSeedMedalData(nil, true)
      else
        self.data:SetHardSeedMedalData(self:GetMedalConfId(), false)
      end
    end
    Module:OnSendZoneTeamBattleChallengeReq(ActorId, NpcLogicId, _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE, nil, self.uiData.blood)
  end
end

function UMG_PrewarInformation_C:OnDialogChallengeClicked(_ok)
  if _ok then
    if not self.module then
      return
    end
    _G.NRCAudioManager:PlaySound2DAuto(40008029, "UMG_TeamBattle_ChangePet_C:OnConfirmBtnClicked")
    local EnterCondition = self.module:CheckEnterCondition(self.challengeType)
    if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM then
      if EnterCondition ~= TeamBattleModuleEnum.EnterConditionState.BothOK then
        self.module:OpenPreWarConfirmPanel(self.challengeType, EnterCondition)
        self.module:DisablePanel("PreWarInformation")
      elseif not self:TryEnterShinyFlowerChallengeNotify() then
        self:InternalEnterChallenge(true)
      end
      BattleProfiler:CheckPoint(BattleProfilerCheckPoint.FlowerMainPanelClick)
    elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
      local bOpen, tips = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.CheckCanStartLegendaryBattle, EnterCondition)
      if true == bOpen then
        local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
        if bOwner then
          self.module:OnCmdOpenTeamBattleStartConfirmTips()
          self:OnClose()
        else
          self.module:OnZoneTeamBattleConfirmInviteReq(true)
        end
      else
        self.module:OpenPreWarConfirmPanel(self.challengeType, nil, tips)
        self.module:DisablePanel("PreWarInformation")
      end
      BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryMainPanelClick)
    end
  end
  self:ShowOrHideBtn(true)
end

function UMG_PrewarInformation_C:OnChallengeClicked()
  if _G.FunctionBanManager:GetConditionCounter(_G.Enum.PlayerConditionType.PCT_PROP_BLINDBOX) then
    local banConf = _G.DataConfigManager:GetFunctionBanConf(_G.Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, banConf and banConf.ban_desc)
    self:OnCloseBtnClicked()
    return
  end
  if self.IsReCom then
  else
    local title = LuaText.TIPS
    local Context = DialogContext()
    Context:SetTitle(title):SetContent(LuaText.magicmanual_challenge_trace_confirm02):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnDialogChallengeClicked):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetButtonText(LuaText.YES, LuaText.NO)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
    self:ShowOrHideBtn(false)
    if BattleProfiler:IsEnable() then
      if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM then
        BattleProfiler:CheckPoint(BattleProfilerCheckPoint.FlowerMainPanelClick)
      elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
        BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryMainPanelClick)
      end
    end
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008029, "UMG_TeamBattle_ChangePet_C:OnConfirmBtnClicked")
  local EnterCondition = self.module:CheckEnterCondition(self.challengeType)
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM then
    if EnterCondition ~= TeamBattleModuleEnum.EnterConditionState.BothOK then
      self.module:OpenPreWarConfirmPanel(self.challengeType, EnterCondition)
      self.module:DisablePanel("PreWarInformation")
    elseif not self:TryEnterShinyFlowerChallengeNotify() then
      self:InternalEnterChallenge(true)
    end
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.FlowerMainPanelClick)
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
    local bOpen, tips = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.CheckCanStartLegendaryBattle, EnterCondition)
    if true == bOpen then
      local bOwner = _G.DataModelMgr.PlayerDataModel:IsVisitOwner()
      if bOwner then
        self.module:OnCmdOpenTeamBattleStartConfirmTips()
        self:OnClose()
      else
        self.module:OnZoneTeamBattleConfirmInviteReq(true)
      end
    else
      self.module:OpenPreWarConfirmPanel(self.challengeType, nil, tips)
      self.module:DisablePanel("PreWarInformation")
    end
    BattleProfiler:CheckPoint(BattleProfilerCheckPoint.LegendaryMainPanelClick)
  end
end

function UMG_PrewarInformation_C:ShowOrHideBtn(Show)
  if Show then
    self.Btn_Challenge:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Btn_Challenge_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Btn_Challenge:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Btn_Challenge_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PrewarInformation_C:UpdatePanelInfo()
  self:UpdateHealth()
  if self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_TEAM or self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BLOOD_SINGLE then
    local AwardList = self.module:OnCmdGetTeamBattleAwards(self.uiData.star, self.uiData.blood) or {}
    local StarList = {}
    for i = 1, self.uiData.star do
      table.insert(StarList, {hasStar = true})
    end
    local rewardsTable = {}
    local activity_objects = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetActivityInstByType, _G.Enum.ActivityType.ATP_FLOWER_APPEAR_HARD)
    for _, v in ipairs(activity_objects) do
      if v:IsInProgress() then
        local flower_group = _G.DataConfigManager:GetActivityFlowerAppearConf(v:GetSinglePartId()).flower_group
        for _, seed in ipairs(flower_group) do
          if seed.seed_id == self.uiData.spec_flower_seed_id then
            local bGetReward = v:GetTaskState(seed.appear_task_id[1])
            local bGetMedal = v:GetTaskState(seed.appear_task_id[2])
            if not bGetMedal then
              local flowerTaskConf = _G.DataConfigManager:GetActivityFlowerTaskConf(seed.appear_task_id[2])
              local rewards = _G.NRCCommonItemIconData()
              rewards.itemType = flowerTaskConf.reward_type
              rewards.itemId = flowerTaskConf.reward_id
              rewards.itemNum = 1
              rewards.bShowTip = true
              rewards.tag = _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_MEDAL
              table.insert(rewardsTable, rewards)
            end
            if not bGetReward then
              local reward_id = _G.DataConfigManager:GetActivityFlowerTaskConf(seed.appear_task_id[1]).reward_id
              local rewardItem = _G.DataConfigManager:GetRewardConf(reward_id).RewardItem
              for _, item in ipairs(rewardItem) do
                local rewards = _G.NRCCommonItemIconData()
                rewards.itemType = item.Type
                rewards.itemId = item.Id
                rewards.itemNum = item.Count
                rewards.bShowNum = true
                rewards.bShowTip = true
                rewards.tag = _G.Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST
                table.insert(rewardsTable, rewards)
              end
            end
            goto lbl_165
          end
        end
      end
    end
    ::lbl_165::
    local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_FLOWER)
    if dropReward then
      for k, v in ipairs(dropReward) do
        table.insert(rewardsTable, v)
      end
    end
    for k, v in ipairs(AwardList) do
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.Type
      rewards.itemId = v.Id
      rewards.itemNum = v.Count
      rewards.bShowNum = true
      if v.Count <= 0 then
        rewards.bShowNum = false
      end
      rewards.bShowTip = true
      table.insert(rewardsTable, rewards)
    end
    self.Icon_List:InitGridView(rewardsTable)
    self.Star_List:InitGridView(StarList)
    local BookState = _G.NRCModuleManager:DoCmd(HandbookModuleCmd.GetPetHandBookState, self.uiData.battle_petbase_id)
    if BookState == _G.ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
      self.NotCollectedText:SetVisibility(UE4.ESlateVisibility.Hidden)
    else
      self.NotCollectedText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    local levelText, IsReCom = MagicManualUtils.GetFlowerLevel(self.uiData.star, self.uiData.spec_flower_seed_id)
    self.IsReCom = IsReCom
    if IsReCom then
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    else
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
    end
    self.Text_Grade:SetText(string.format(LuaText.umg_petskilltemple2_1, levelText))
    local campConf = _G.DataConfigManager:GetCampConf(self.uiData.camp_cfg_id)
    if campConf then
      self.CampBG:SetPath(campConf.background_pic)
    end
    if self.uiData.remain_time then
      self.RemainTime:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local hour = self.uiData.remain_time / 3600
      local min = (self.uiData.remain_time - math.floor(hour) * 60 * 60) / 60
      local text = string.format(LuaText.umg_prewarinformation_1, math.floor(hour), math.ceil(min))
      self.Text_Time:SetText(text)
    else
      self.RemainTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.AttrPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local baseId = self.inner_petbase_id or self.uiData.battle_petbase_id
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
    local petAttrData = {}
    local unit_type = petBaseConf.unit_type
    for i = 1, #unit_type do
      local petType = petBaseConf.unit_type[i]
      table.insert(petAttrData, {Type = petType})
    end
    self.Attr_Pet:InitGridView(petAttrData)
    local bloodConf = _G.DataConfigManager:GetPetBloodConf(self.uiData.blood)
    self.CampBG:SetPath(bloodConf.icon_flower_2)
    self:SetBgColor(bloodConf.blood_type)
    self.Img_di:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local bloodAttrData = {}
    table.insert(bloodAttrData, {
      Name = bloodConf.blood_name,
      Path = bloodConf.icon
    })
    self.Attr_Blood:InitGridView(bloodAttrData)
    if petBaseConf then
      local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
      self.PetIcon:SetPath(modelConf.icon)
    else
      self:LogError("invalid petbase_id", self.uiData.battle_petbase_id)
    end
    self.npcName:SetText(_G.DataConfigManager:GetNpcConf(self.uiData.npc_cfg_id).name)
    local useStarNum = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_starlink", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).num
    local StarNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_STAR)
    self.Text_Quantity:SetText(useStarNum)
    self.TextQuantity:SetText(useStarNum)
    self.TextQuantity_1:SetText(useStarNum)
    if useStarNum > StarNum then
      self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#af3d3eff"))
    else
      self.Text_Quantity:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#272727FF"))
    end
    local descText = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_flower", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
    self.npcDesc:SetText(descText)
    local bVisit = _G.DataModelMgr.PlayerDataModel:IsVisitState()
    if bVisit then
      if self.bOwner then
        self.Btn_Challenge:SetBtnText(LuaText.umg_prewarinformation_2)
        self.Btn_Challenge_1:SetBtnText(_G.DataConfigManager:GetLocalizationConf("teambattlemodule_7").msg)
        self:ShowCountDown(false)
        self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.Btn_Challenge:SetBtnText(LuaText.umg_prewarinformation_3)
        self.Btn_Challenge_1:SetBtnText(_G.DataConfigManager:GetLocalizationConf("team_battle_text_2").msg)
        self:ShowCountDown(true)
        self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
        if visitorList and #visitorList > 0 then
          local nameText = string.format(LuaText.umg_prewarinformation_4, visitorList[1].name)
          self.Name:SetText(nameText)
        else
          Log.Error("\228\186\146\232\174\191\230\149\176\230\141\174\230\156\137\232\175\175\239\188\140\232\175\183\230\163\128\230\159\165visitorList\230\149\176\230\141\174")
        end
      end
    else
      self.Btn_Challenge_1:SetBtnText(_G.DataConfigManager:GetLocalizationConf("teambattlemodule_7").msg)
      self.Btn_Challenge:SetBtnText(LuaText.umg_prewarinformation_2)
      self:ShowCountDown(false)
      self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
    self.Icon:SetPath(vItemsConf.bigIcon)
    self.CoinIcon:SetPath(vItemsConf.iconPath)
    local Bg = "Texture2D'/Game/NewRoco/Modules/System/TeamBattle/Raw/TeamBattle/Textures/img_bg.img_bg'"
    if self.uiData.spec_flower_seed_id and 0 ~= self.uiData.spec_flower_seed_id and self.uiData.activity_id and 0 ~= self.uiData.activity_id then
      local activityConf = _G.DataConfigManager:GetActivityConf(self.uiData.activity_id)
      if activityConf and activityConf.activity_type == Enum.ActivityType.ATP_LIMITED_FLOWER_SEED then
        local worldMapConfs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.WORLD_MAP_CONF):GetAllDatas()
        local SceneNpc = NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, self.data.TargetNPCActorId)
        if SceneNpc then
          local bFlower = SceneNpc.config.genre == Enum.ClientNpcType.CNT_FLOWER_SEED
          if bFlower then
            local NpcRefreshId = SceneNpc.serverData.npc_base.npc_content_cfg_id
            for k, v in pairs(worldMapConfs) do
              local npc_refresh_ids = v.npc_refresh_ids
              if npc_refresh_ids and #npc_refresh_ids > 0 then
                for i, j in pairs(npc_refresh_ids) do
                  if j == NpcRefreshId then
                    icon = v.dungeon_title_bg
                    Bg = v.dungeon_interface_bg_path
                    break
                  end
                end
              end
            end
          end
        end
      end
    end
    self.bg:SetPath(Bg)
  elseif self.challengeType == _G.ProtoEnum.TeamBattleChallengeType.TBCT_BEAST then
    self.NotCollectedText:SetVisibility(UE4.ESlateVisibility.Hidden)
    local costNum2 = _G.DataConfigManager:GetLegendaryGlobalConfig("star_consume").num
    self.TextQuantity:SetText(costNum2)
    local StarList = {}
    for i = 1, self.uiData.select_star do
      table.insert(StarList, {hasStar = true})
    end
    self.Star_List:InitGridView(StarList)
    if self.bOwner then
      self.Btn_Challenge:SetBtnText(LuaText.umg_prewarinformation_2)
      self.Btn_Challenge_1:SetBtnText(_G.DataConfigManager:GetLocalizationConf("teambattlemodule_7").msg)
      self:ShowCountDown(false)
      self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Btn_Challenge:SetBtnText(LuaText.umg_prewarinformation_3)
      self.Btn_Challenge_1:SetBtnText(_G.DataConfigManager:GetLocalizationConf("team_battle_text_2").msg)
      self:ShowCountDown(true)
      self.Name:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local visitorList = _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.GetOnlineVisitorList)
      if visitorList and #visitorList > 0 then
        local nameText = string.format(LuaText.umg_prewarinformation_4, visitorList[1].name)
        self.Name:SetText(nameText)
      else
        self.Name:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    local vItemsConf = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_STAR)
    self.Icon:SetPath(vItemsConf.bigIcon)
    self.CoinIcon:SetPath(vItemsConf.iconPath)
    local costItemId, useLegendaryCoinNum = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetLegendaryTicketIDAndNum, self.data.TargetNPCContentID)
    local bagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId)
    self.CoinIcon_1:SetPath(bagItemConf.icon)
    self.Text_Quantity:SetText(useLegendaryCoinNum)
    self.TextQuantity_1:SetText(useLegendaryCoinNum)
    local monsterConfId = _G.DataConfigManager:GetBattleConf(self.uiData.battle_cfg_id).npc_battle_list[1].pos1_1st[1]
    local monsterConf = _G.DataConfigManager:GetMonsterConf(monsterConfId)
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(monsterConf.base_id)
    local level = 0
    if monsterConf.new_level and #monsterConf.new_level > 0 then
      level = monsterConf.new_level[1]
    end
    local lvText = string.format(LuaText.umg_petskilltemple2_1, level)
    local worldLevel = _G.DataModelMgr.PlayerDataModel:GetPlayerWorldLevel()
    local pet_top_level = 0
    local WORLD_LEVEL_CONF = _G.DataConfigManager:GetAllByName("WORLD_LEVEL_CONF")
    for _, item in ipairs(WORLD_LEVEL_CONF) do
      if item.world_level == worldLevel then
        pet_top_level = item.pet_top_level
        break
      end
    end
    local IsReCom = level <= pet_top_level
    self.IsReCom = IsReCom
    if IsReCom then
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#62605EFF"))
    else
      self.Text_Grade:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#C7494AFF"))
    end
    self.Text_Grade:SetText(lvText)
    self.npcName:SetText(petBaseConf.name)
    self.CampBG:SetPath(self:GetPicResByPetBaseId(monsterConf.base_id))
    local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
    self.PetIcon:SetPath(modelConf.icon)
    self.AttrPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_Details:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local text = _G.NRCModuleManager:DoCmd(_G.LegendaryBattleModuleCmd.GetActivityTimeByContentId, monsterConf.base_id)
    self.Text_Time:SetText(text)
    if "" == text or nil == text then
      self.RemainTime:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    local showRewards = _G.NRCModuleManager:DoCmd(LegendaryBattleModuleCmd.GetLegendaryBattleAwards, self.uiData.select_star, monsterConf.base_id)
    local rewardsTable = {}
    local dropReward = _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.GetSpecificTimeActivityReward, ProtoEnum.ActivityDropShowArea.ADSA_LEGENDARY)
    if dropReward then
      for k, v in ipairs(dropReward) do
        table.insert(rewardsTable, v)
      end
    end
    for k, v in ipairs(showRewards) do
      local rewards = _G.NRCCommonItemIconData()
      rewards.itemType = v.Type
      rewards.itemId = v.Id
      rewards.itemNum = v.Count
      rewards.bShowNum = true
      if v.Count <= 0 then
        rewards.bShowNum = false
      end
      rewards.bShowTip = true
      table.insert(rewardsTable, rewards)
    end
    self.Icon_List:InitGridView(rewardsTable)
  end
  self:UpdateShinyFlowerTips()
end

function UMG_PrewarInformation_C:GetPicResByPetBaseId(petBaseId)
  local filePath = string.format("%s%d%s", "/Game/NewRoco/Modules/System/Activity/Raw/LegendaryBattle/", petBaseId, "/")
  local bgPath = string.format("%s%s", filePath, "img_prewar.img_prewar")
  return bgPath
end

function UMG_PrewarInformation_C:ShowCountDown(bShow)
  self.bShowCountDown = bShow
  if bShow then
    local countDownTip = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_text_team", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    local countDownTip = _G.DataConfigManager:GetGlobalConfigByKeyType("team_battle_text_single", _G.DataConfigManager.ConfigTableId.PET_GLOBAL_CONFIG).str
    self.Text_Hint:SetText(countDownTip)
    self.JinduProgressBar:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PrewarInformation_C:GetIconPath(iconName)
  return string.format("PaperSprite'/Game/NewRoco/Modules/System/TeamBattle/Raw/Frames/%s'", iconName)
end

function UMG_PrewarInformation_C:OnAnimFinished(anim)
  if anim == self.Out then
  end
end

function UMG_PrewarInformation_C:OnOpenPetTips()
  local flag = false
  if self.FlowerTypeWrap and self.FlowerTypeWrap.IsShinyFlower then
    flag = true
  end
  local petBaseId = self.inner_petbase_id or self.uiData.battle_petbase_id
  local infoData = {
    petBaseId = petBaseId,
    bloodId = self.uiData.blood,
    flowerSeedId = self.uiData.spec_flower_seed_id,
    star = self.uiData.star,
    isShinyFlower = flag,
    bForceShowType = true
  }
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.ShowChangePetConfirm3, infoData, nil, false, false, {isShowPetTips = true})
end

function UMG_PrewarInformation_C:SetBgColor(Type)
  if Type == Enum.SkillDamType.SDT_GRASS then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("D4E3BFFF"))
  elseif Type == Enum.SkillDamType.SDT_COMMON then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("B6DFE3FF"))
  elseif Type == Enum.SkillDamType.SDT_DEMON then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F0B6CDFF"))
  elseif Type == Enum.SkillDamType.SDT_FIRE then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F5D8BBFF"))
  elseif Type == Enum.SkillDamType.SDT_WATER then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("CEDFE9FF"))
  elseif Type == Enum.SkillDamType.SDT_LIGHT then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C4D4ECFF"))
  elseif Type == Enum.SkillDamType.SDT_STONE then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("DBCEB6FF"))
  elseif Type == Enum.SkillDamType.SDT_ICE then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("B6D9ECFF"))
  elseif Type == Enum.SkillDamType.SDT_DRAGON then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F5BFBBFF"))
  elseif Type == Enum.SkillDamType.SDT_ELECTRIC then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F5EA9BFF"))
  elseif Type == Enum.SkillDamType.SDT_TOXIC then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("DDB9EDFF"))
  elseif Type == Enum.SkillDamType.SDT_INSECT then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("DDE5BDFF"))
  elseif Type == Enum.SkillDamType.SDT_FIGHT then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("F5DABBFF"))
  elseif Type == Enum.SkillDamType.SDT_WING then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("B6DFE3FF"))
  elseif Type == Enum.SkillDamType.SDT_MOE then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("FBBAC3FF"))
  elseif Type == Enum.SkillDamType.SDT_GHOST then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C7ADEEFF"))
  elseif Type == Enum.SkillDamType.SDT_MECHANIC then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("BDE5DFFF"))
  elseif Type == Enum.SkillDamType.SDT_PHANTOM then
    self.Img_di:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("C1C1EEFF"))
  end
end

function UMG_PrewarInformation_C:OnOpenTypeTips()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  local petBaseId = self.inner_petbase_id or self.uiData.battle_petbase_id
  local t_petData = {base_conf_id = petBaseId}
  local data = {petData = t_petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, data)
end

function UMG_PrewarInformation_C:OnOpenBloodTips()
  local petBaseId = self.inner_petbase_id or self.uiData.battle_petbase_id
  local glass_info = self.inner_glass_info or self.uiData.battle_npc_glass_info
  local data = {
    base_conf_id = petBaseId,
    mutation_type = _G.Enum.MutationDiffType.MDT_NONE,
    glass_info = glass_info,
    blood_id = self.uiData.blood
  }
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_PetBaseInfo_C:OnBloodPulse")
  _G.NRCModeManager:DoCmd(BattleUIModuleCmd.OpenBattleBloodPulse, data)
end

function UMG_PrewarInformation_C:OnOpenPetInfoPanel()
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_PetBaseInfo_C:OnOpenPetInfoPanel")
  local petBaseId = self.inner_petbase_id or self.uiData.battle_petbase_id
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, petBaseId, true)
end

function UMG_PrewarInformation_C:GetMedalConfId()
  local flowerAppearConf = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ACTIVITY_FLOWER_APPEAR_CONF):GetAllDatas()
  for _, v in pairs(flowerAppearConf) do
    for _, v2 in ipairs(v.flower_group) do
      if v2.seed_id == self.uiData.spec_flower_seed_id then
        return _G.DataConfigManager:GetActivityFlowerTaskConf(v2.appear_task_id[2]).reward_id
      end
    end
  end
end

return UMG_PrewarInformation_C
