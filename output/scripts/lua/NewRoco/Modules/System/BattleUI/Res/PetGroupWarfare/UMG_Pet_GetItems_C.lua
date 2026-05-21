local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local UMG_Pet_GetItems_C = _G.NRCPanelBase:Extend("UMG_Pet_GetItems_C")

function UMG_Pet_GetItems_C:OnActive(_Param, PrivilegeChannel, MedalReward)
  _G.NRCAudioManager:BatchSetState("UI_Music;UI_Music;UI_Type;Settlement")
  if self:IsPCMode() then
    self:PCModeScreenSetting()
  end
  _G.BattleEventCenter:Bind(self, BattleEvent.BATTLE_TEAMBATTLE_BALANCELENS)
  self:OnAddEventListener()
  local firstPassRewards = {}
  local firstRewards = {}
  local secondRewards = {}
  local activityItems = {}
  local Items = {}
  for i, reward in ipairs(_Param.rewards) do
    if reward.type == ProtoEnum.GoodsType.GT_PET then
    elseif reward.reward_reason == _G.ProtoEnum.FlowReason.FLOW_REASON_BATTLE_SETTLEMENT then
      if 0 == reward.tag and (reward.type == ProtoEnum.GoodsType.GT_VITEM or reward.type == ProtoEnum.GoodsType.GT_BAGITEM) then
        table.insert(firstRewards, reward)
      elseif reward.tag == Enum.RewardTag.RTA_SHINYDOUBLE then
        table.insert(activityItems, reward)
      elseif reward.tag == Enum.RewardTag.RTA_ACTIVITY_FLOWER_FIRST then
        table.insert(firstPassRewards, reward)
      else
        table.insert(secondRewards, reward)
      end
    end
  end
  
  local function Sorter(a, b)
    if a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
      local vItemConfA = _G.DataConfigManager:GetVisualItemConf(a.id)
      local vItemConfB = _G.DataConfigManager:GetVisualItemConf(b.id)
      return vItemConfA.sort_id < vItemConfB.sort_id
    elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
      local BagItemConfA = _G.DataConfigManager:GetBagItemConf(a.id)
      local BagItemConfB = _G.DataConfigManager:GetBagItemConf(b.id)
      return BagItemConfA.sort_id < BagItemConfB.sort_id
    elseif a.type == ProtoEnum.GoodsType.GT_VITEM and b.type == ProtoEnum.GoodsType.GT_BAGITEM then
      return true
    elseif a.type == ProtoEnum.GoodsType.GT_BAGITEM and b.type == ProtoEnum.GoodsType.GT_VITEM then
      return false
    else
      return a.id < b.id
    end
  end
  
  table.sort(firstPassRewards, Sorter)
  table.sort(firstRewards, Sorter)
  table.sort(activityItems, Sorter)
  table.sort(secondRewards, Sorter)
  table.move(firstPassRewards, 1, #firstPassRewards, #Items + 1, Items)
  table.move(firstRewards, 1, #firstRewards, #Items + 1, Items)
  table.move(activityItems, 1, #activityItems, #Items + 1, Items)
  table.move(secondRewards, 1, #secondRewards, #Items + 1, Items)
  self.IsClickClose = false
  self:SetItemInfo(Items, PrivilegeChannel, MedalReward)
  self:PlayAnimIn()
end

function UMG_Pet_GetItems_C:OnDeactive()
  _G.NRCAudioManager:BatchSetState("UI_Music;None")
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Pet_GetItems_C:SetItemInfo(Items, PrivilegeChannel, MedalReward)
  self.List:InitGridView(Items)
  self:UpdatePrivilegeUI(PrivilegeChannel)
  if MedalReward and MedalReward.pet_gid then
    local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(MedalReward.pet_gid)
    local pet_evolution_id = _G.DataConfigManager:GetPetbaseConf(MedalReward.petbase_id).pet_evolution_id[1]
    local pet_name = _G.DataConfigManager:GetPetEvolutionConf(pet_evolution_id).evolution_chain[1].pet_name
    self.HeadIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
    self.Text_Description:SetText(string.format(_G.LuaText.Activity_FlowerHard_MedalReward, pet_name))
  else
    self.CanvasMedal:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_GetItems_C:GetSelfLoginChannelType()
  local accountInfo = _G.NRCModuleManager:DoCmd(_G.OnlineModuleCmd.GetUserAccountInfo)
  local loginChannelType = accountInfo and accountInfo.plat_info and accountInfo.plat_info.cli_login_channel or nil
  return loginChannelType
end

function UMG_Pet_GetItems_C:UpdatePrivilegeUI(PrivilegeChannel)
  local loginChannelType = self:GetSelfLoginChannelType()
  local IsBan = false
  if loginChannelType == Enum.CliLoginChannel.CLC_WX then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_WX_VIP, false)
  elseif loginChannelType == Enum.CliLoginChannel.CLC_QQ then
    IsBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PRIVILEGE_QQ_VIP, false)
  end
  if IsBan then
    self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if PrivilegeChannel and PrivilegeChannel ~= Enum.CliStartUpChannel.CSUC_NONE then
    local LocalText = ""
    if PrivilegeChannel == Enum.CliStartUpChannel.CSUC_WX_GAME_CENTER then
      LocalText = LuaText.privilege_wechat_reward_addition_text
    elseif PrivilegeChannel == Enum.CliStartUpChannel.CSUC_QQ_GAME_CENTER then
      LocalText = LuaText.privilege_qq_reward_addition_text
    end
    if "" ~= LocalText then
      self.Desc:SetText(LocalText)
      self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.Desc:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Pet_GetItems_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_Pet_GetItems_C:PCModeScreenSetting()
  local Padding = UE4.FMargin()
  Padding.Left = -164
  Padding.Top = -74
  Padding.Right = -164
  Padding.Bottom = -74
  self:SetRenderScale(UE4.FVector2D(0.88, 0.88))
  if self.Slot then
    self.Slot:SetOffsets(Padding)
  end
end

function UMG_Pet_GetItems_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseRenamePanel, self.OnClickbtnCloseRenamePanel)
end

function UMG_Pet_GetItems_C:OnClickbtnCloseRenamePanel()
  self:CloseUI()
end

function UMG_Pet_GetItems_C:CloseUI()
  self:PlayAnimOut()
end

function UMG_Pet_GetItems_C:PlayAnimOut()
  if not UE4.UObject.IsValid(self) then
    return
  end
  if self.IsClickClose then
    return
  end
  self.IsClickClose = true
  self:PlayAnimation(self.Out)
end

function UMG_Pet_GetItems_C:OnAnimationFinished(Animation)
  if Animation == self.Out then
    NRCModeManager:DoCmd(BattleUIModuleCmd.OpenGetItemsPanel, false)
    _G.BattleEventCenter:Dispatch(BattleEvent.BATTLE_TEAMBATTLE_BALANCELENS_END)
  end
end

function UMG_Pet_GetItems_C:PlayAnimIn()
  if not UE4.UObject.IsValid(self) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1502, "UMG_Pet_GetItems_C:PlayAnimIn")
  self:PlayAnimation(self.In)
end

return UMG_Pet_GetItems_C
