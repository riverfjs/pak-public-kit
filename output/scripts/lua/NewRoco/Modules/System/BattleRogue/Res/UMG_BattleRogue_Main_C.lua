local BattleRogueModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_BattleRogue_Main_C = _G.NRCPanelBase:Extend("UMG_BattleRogue_Main_C")

function UMG_BattleRogue_Main_C:OnConstruct()
  self.Data = self.module:GetData("BattleRogueModuleData")
  self:OnAddEventListener()
end

function UMG_BattleRogue_Main_C:OnDestruct()
  self.module:CloseBuffTips()
end

function UMG_BattleRogue_Main_C:OnActive()
  self:SetPanelInfo()
end

function UMG_BattleRogue_Main_C:OnDeactive()
end

function UMG_BattleRogue_Main_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.ClosePanel)
  self:AddButtonListener(self.Btn_Pet.btnLevelUp, self.OnBtnPetClick)
  self:AddButtonListener(self.EventBtn.btnLevelUp, self.OnEventBtn)
  self:RegisterEvent(self, BattleRogueModuleEvent.OnChoseEvent, self.OnChoseEventInfo)
  self:RegisterEvent(self, BattleRogueModuleEvent.OnUpdateCoinNum, self.OnUpdateCoinNum)
end

function UMG_BattleRogue_Main_C:SetPanelInfo()
  self:SetHp()
  self:SetMagic()
  self:SetPetList()
  self:SetNodeList()
  self:SetCurrentNodeList()
  self:RandomSDI()
  self:SetRogueCoin(self.Data:GetRogueCoinNum())
  self:OpenSettlementTips()
  self:OpenBuffTips()
end

function UMG_BattleRogue_Main_C:SetHp()
  local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local tempCount = localPlayer.serverData.attrs.hp_temporary or 0
  local hp = localPlayer.serverData.attrs.hp + tempCount
  local realHp = hp - (tempCount or 0)
  local maxhp = math.max(localPlayer.serverData.attrs.hp_max, hp)
  if hp < maxhp then
    hp = maxhp
  end
  local HpListInfo = {}
  for i = 1, hp do
    if i <= realHp then
      table.insert(HpListInfo, {IsShowHP = true})
    else
      table.insert(HpListInfo, {IsShowHP = false})
    end
  end
  self.HpList:InitGridView(HpListInfo)
end

function UMG_BattleRogue_Main_C:SetMagic()
  self.Switcher:SetActiveWidgetIndex(1)
  local petInfoList = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
  local teamInfo = PetUtils.PlayerPetInfoGetTeamInfo(petInfoList, Enum.PlayerTeamType.PTT_BIG_WORLD)
  local BagItemS = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetBagItemArrayByType, Enum.BagItemType.BI_PLAYERSKILL)
  self.IsHasBlood = BagItemS and #BagItemS > 0 and true or false
  if self.IsHasBlood then
    for i, BagItem in ipairs(BagItemS) do
      if teamInfo and teamInfo.teams and teamInfo.teams[teamInfo.main_team_idx + 1] and BagItem.gid == teamInfo.teams[teamInfo.main_team_idx + 1].role_magic_gid then
        local BagItemConf = _G.DataConfigManager:GetBagItemConf(BagItem.id)
        if BagItemConf then
          self.Icon_1:SetPath(BagItemConf.icon)
          self.Switcher:SetActiveWidgetIndex(0)
        end
        break
      end
    end
  end
end

function UMG_BattleRogue_Main_C:SetPetList()
  local PetInfoList = self.Data.PetInfo
  self.PetHeadList:InitGridView(PetInfoList)
  local Index = _G.NRCModuleManager:DoCmd(PetUIModuleCmd.GetPetSelectIndex) or 1
  self.PetHeadList:SelectItemByIndex(Index - 1)
end

function UMG_BattleRogue_Main_C:OpenBuffTips()
  local CurBuffDatas = self.Data:GetCurBuffDatas()
  if CurBuffDatas and #CurBuffDatas > 0 then
    self.module:OpenBuffTips(CurBuffDatas)
  end
end

function UMG_BattleRogue_Main_C:GetPetHP(PetData)
  return PetUtils.GetPetAdditionalByType(PetData, _G.Enum.AttributeType.AT_HPMAX), PetUtils.GetPetAdditionalByType(PetData, _G.Enum.AttributeType.AT_HPCUR)
end

function UMG_BattleRogue_Main_C:SetRogueCoin(RogueCoin)
  local MoneyList = {
    {
      moneyType = _G.Enum.VisualItem.VI_ROGUE_COIN,
      sum = RogueCoin,
      IsShowBuyIcon = false
    }
  }
  self.MoneyList:InitGridView(MoneyList)
end

function UMG_BattleRogue_Main_C:OnUpdateCoinNum(RogueCoin, RefreshNeedCoinNum)
  self:SetRogueCoin(RogueCoin)
end

function UMG_BattleRogue_Main_C:SetCurrentNodeList()
  local UIEventDatas = self.Data:GetUIEventDatas()
  self.SDIList_2:InitGridView(UIEventDatas)
end

function UMG_BattleRogue_Main_C:RandomSDI()
  local IsOpenSettlementTips = self.Data:GetIsOpenSettlementTips()
  local UINodeInfo = self.Data:GetCurrentUINodeInfo()
  if not UINodeInfo.NodeUIEventData and not IsOpenSettlementTips then
    self.module:OpenBattleRogueCardTips()
    self:ShowOrHideMainInfo(true)
  end
end

function UMG_BattleRogue_Main_C:OpenSettlementTips()
  local IsOpenSettlementTips = self.Data:GetIsOpenSettlementTips()
  if IsOpenSettlementTips then
    self.module:OpenSettlement_Tips()
    self:OpenSettlementTipsPanelChange(true)
  end
end

function UMG_BattleRogue_Main_C:SetNodeList()
  local LevelInfo = self.Data:GetLevelInfo()
  self.SDIList:InitGridView(LevelInfo.Nodes)
end

function UMG_BattleRogue_Main_C:OnEventBtn()
  _G.NRCModuleManager:DoCmd(BattleRogueModuleCmd.SendStartEventReq)
  self:DoClose()
end

function UMG_BattleRogue_Main_C:OnBtnPetClick()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_CompassIcon_C:OnBtnPetClick")
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_PET, true)
  if isBan then
    return
  end
  local battlePetList = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  if not battlePetList[1] then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OpenPanelPetMain, {
    subPanelIndex = 4,
    callback = self.OnUMGLoadFinished
  })
  self.module:CloseBuffTips()
end

function UMG_BattleRogue_Main_C:OnChoseEventInfo()
  self:SetNodeList()
  self:SetCurrentNodeList()
end

function UMG_BattleRogue_Main_C:ShowOrHideMainInfo(IsHide)
  if IsHide then
    self.SDIList_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RightPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.SDIList_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RightPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_BattleRogue_Main_C:OpenSettlementTipsPanelChange(Open)
  if Open then
    self.MiddlePanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.RightPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.MiddlePanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RightPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:RandomSDI()
    self:OpenBuffTips()
  end
end

function UMG_BattleRogue_Main_C:ClosePanel()
  self:DoClose()
end

function UMG_BattleRogue_Main_C:OnAnimationFinished(anim)
end

return UMG_BattleRogue_Main_C
