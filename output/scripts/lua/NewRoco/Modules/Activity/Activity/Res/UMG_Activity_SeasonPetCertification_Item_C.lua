local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Activity_SeasonPetCertification_Item_C = Base:Extend("UMG_Activity_SeasonPetCertification_Item_C")

function UMG_Activity_SeasonPetCertification_Item_C:OnConstruct()
  self:AddButtonListener(self.ButtonClick, self.OnBtnClicked)
end

function UMG_Activity_SeasonPetCertification_Item_C:SetInfo(_data)
  local conf = _G.DataConfigManager:GetActivityPetCertification(_data.base_id)
  local conditionNum = conf.condition_param
  self.Desc:SetText(string.format(conf.part_name, tostring(math.min(_data.dayNum, conditionNum)), tostring(conditionNum)))
  self.QuantityText:SetText(string.format(conf.part_desc, tostring(conditionNum)))
  if conditionNum <= _data.dayNum then
    if _data.bGetReward then
      self.Switcher:SetActiveWidgetIndex(2)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.Switcher:SetActiveWidgetIndex(1)
      self.NRCImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self.Switcher:SetActiveWidgetIndex(0)
    self.NRCImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NRCImage_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  self.npc_id = conf.npc_id
  self.flag = conf.player_story_flag
  self.redPointNew:SetupKey(471, _data.activity_id)
end

function UMG_Activity_SeasonPetCertification_Item_C:OnBtnClicked()
  local index = self.Switcher:GetActiveWidgetIndex()
  local hasStoryFlag = 0 == self.flag or _G.DataModelMgr.PlayerDataModel:IsAssignStoryFlags(self.flag)
  if 1 == index then
    if self.redPointNew:IsRed() then
      self.redPointNew:EraseRedPoint()
    end
    local teleportDialog = DialogContext()
    if hasStoryFlag then
      teleportDialog:SetCallbackOkOnly(self, self.ConfirmTeleport)
      teleportDialog:SetContent(_G.LuaText.PET_CERTIFICATION_11)
      teleportDialog:SetMode(DialogContext.Mode.OK_CANCEL)
      teleportDialog:SetTitle(_G.LuaText.TIPS)
      teleportDialog:SetButtonText(_G.LuaText.PET_CERTIFICATION_12, _G.LuaText.PET_CERTIFICATION_13)
      teleportDialog:SetClickAnywhereClose(true)
    else
      teleportDialog:SetCallbackOkOnly(self, self.ConfirmTask)
      teleportDialog:SetContent(_G.LuaText.PET_CERTIFICATION_14)
      teleportDialog:SetMode(DialogContext.Mode.OK_CANCEL)
      teleportDialog:SetTitle(_G.LuaText.TIPS)
      teleportDialog:SetButtonText(_G.LuaText.PET_CERTIFICATION_15, _G.LuaText.PET_CERTIFICATION_16)
      teleportDialog:SetClickAnywhereClose(true)
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, teleportDialog)
  end
end

function UMG_Activity_SeasonPetCertification_Item_C:ConfirmTask()
  _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.OpenSeasonIntegrationPanel)
end

function UMG_Activity_SeasonPetCertification_Item_C:ConfirmTeleport(result)
  if not result then
    return
  end
  local NpcData = _G.NRCModuleManager:DoCmd(BigMapModuleCmd.GetNpcInfoByRefreshId, self.npc_id)
  if NpcData then
    local bBan = _G.NRCModuleManager:DoCmd(FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_UI_TELEPORT, true, true)
    if bBan then
      return
    end
    _G.NRCModuleManager:DoCmd(BigMapModuleCmd.SendWorldMapTeleportReq, NpcData.entry_id)
  else
    Log.Error("Invalid NpcData", self.npc_id)
  end
end

function UMG_Activity_SeasonPetCertification_Item_C:OnDestruct()
  self:RemoveButtonListener(self.ButtonClick)
end

return UMG_Activity_SeasonPetCertification_Item_C
