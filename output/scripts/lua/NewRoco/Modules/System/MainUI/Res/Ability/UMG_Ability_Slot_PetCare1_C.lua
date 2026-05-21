local Base = require("NewRoco.Modules.System.MainUI.Res.Ability.UMG_Ability_Slot_C")
local UMG_Ability_Slot_PetCare1_C = Base:Extend("UMG_Ability_Slot_PetCare1_C")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local BagModuleEvent = require("NewRoco.Modules.System.Bag.BagModuleEvent")
local OptionHighlightMaterial = "/Game/ArtRes/Effects/Texture/Outline/Material/MI_FX_Perception_Outline_001.MI_FX_Perception_Outline_001"
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")

function UMG_Ability_Slot_PetCare1_C:OnConstruct()
  Base.OnConstruct(self)
  self._isVisible = false
  self:AddEventListener()
  self:RefreshUI()
  if _G.HomeModuleCmd then
    self:RefreshFoodIcon()
  end
end

function UMG_Ability_Slot_PetCare1_C:AddEventListener()
  _G.ZoneServer:AddProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEquipFoodChange, self.OnEquipFoodChange)
    homeModule:RegisterEvent(self, HomeModuleEvent.OnEnterHomeMap, self.OnEnterHomeMap)
    homeModule:RegisterEvent(self, HomeModuleEvent.OnExitHomeMap, self.RefreshUI)
  end
  _G.FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_FOOD, self, self.OnFunctionBan)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_PetCare1_C", self, BagModuleEvent.BagItemUpdate, self.OnBagItemUpdate)
  _G.NRCEventCenter:RegisterEvent("UMG_Ability_Slot_PetCare1_C", self, BagModuleEvent.BagItemAdd, self.OnBagItemAdd)
end

function UMG_Ability_Slot_PetCare1_C:OnBagItemAdd(id)
  if id ~= self.equipFoodId then
    return
  end
  local equipItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.equipFoodId)
  if equipItem and equipItem.num then
    self.equipFoodNum = equipItem.num
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_PetCare1_C:OnBagItemUpdate(id)
  if id ~= self.equipFoodId then
    return
  end
  local equipItem = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, self.equipFoodId)
  if equipItem and equipItem.num then
    self.equipFoodNum = equipItem.num
    self:RefreshUI()
  end
end

function UMG_Ability_Slot_PetCare1_C:OnEnterHomeMap()
  self:RefreshUI()
  self:RefreshFoodIcon()
end

function UMG_Ability_Slot_PetCare1_C:OnFunctionBan()
  self:RefreshUI()
end

function UMG_Ability_Slot_PetCare1_C:OnZoneGoodsRewardNotify(notify)
  local rewards = notify.ret_info and notify.ret_info.goods_change_info
  if rewards then
    local changeInfoItem = rewards.changes
    if changeInfoItem then
      for _, itemInfo in ipairs(changeInfoItem) do
        if itemInfo.id == self.equipFoodId then
          self.equipFoodNum = itemInfo.num
          self.ItemNum:SetText(self.equipFoodNum)
          if 0 == self.equipFoodNum then
            self.FruitEmpty:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_HomePlanting_FruitEmpty_png.img_HomePlanting_FruitEmpty_png'")
            _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, nil, 0)
          else
            _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdSetEquipFoodIdAndNum, itemInfo.id, itemInfo.num)
          end
        end
      end
    end
  end
end

function UMG_Ability_Slot_PetCare1_C:OnEquipFoodChange(bEquip, itemId, num)
  if bEquip and num then
    self.equipFoodNum = num
    self.equipFoodId = itemId
    self:RefreshFoodIcon()
    return
  end
  self.equipFoodId = nil
  self.equipFoodNum = 0
  self:RefreshFoodIcon()
end

function UMG_Ability_Slot_PetCare1_C:RefreshFoodIcon()
  if not self._isVisible then
    return
  end
  if self.equipFoodId and self.equipFoodNum and 0 ~= self.equipFoodNum then
    if self:IsAnimationPlaying(self.AbilitySlot_PetCare_Remind) then
      self:StopAnimation(self.AbilitySlot_PetCare_Remind)
      if not self:IsAnimationPlaying(self.AbilitySlot_PetCare_Normal) then
        self:PlayAnimation(self.AbilitySlot_PetCare_Normal, 0, 99999)
      end
    end
    local foodConf = _G.DataConfigManager:GetBagItemConf(self.equipFoodId)
    if foodConf and foodConf.big_icon then
      self.FruitEmpty:SetPath(foodConf.big_icon)
    end
    self.ItemNum:SetText(self.equipFoodNum)
    self.ItemNum:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self:PlayRemindAnim()
  end
end

function UMG_Ability_Slot_PetCare1_C:IsPanelOnTop()
  local topPanel = _G.NRCPanelManager:GetTopVisiblePanel()
  if not topPanel then
    return false
  end
  local parentPanel = _G.NRCUtils.GetParentPanelUserWidget(self)
  return topPanel == parentPanel or topPanel == self
end

function UMG_Ability_Slot_PetCare1_C:PlayRemindAnim()
  local equipableFood = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, _G.Enum.BagItemType.BI_HOME_PET_FEED)
  if not equipableFood then
    self.ItemNum:SetText("")
    self.FruitEmpty:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_HomePlanting_FruitEmpty_png.img_HomePlanting_FruitEmpty_png'")
    return
  end
  if self.equipFoodId and self.equipFoodNum and self.equipFoodNum > 0 then
    return
  end
  self.ItemNum:SetText("")
  self.FruitEmpty:SetPath("PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUIStatic/Frames/img_HomePlanting_FruitEmpty_png.img_HomePlanting_FruitEmpty_png'")
  local homePet = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetHomePetInfo)
  if not homePet then
    return
  end
  for _, pet in ipairs(homePet) do
    if pet.base and pet.base.actor_id then
      local npc = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, pet.base.actor_id)
      if npc and npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_WAIT_PRODUCT) then
        if not self:IsPanelOnTop() then
          return
        end
        if not self:IsAnimationPlaying(self.AbilitySlot_PetCare_Remind) then
          self:PlayAnimation(self.AbilitySlot_PetCare_Remind, 0, 99999)
        end
      end
    end
  end
end

function UMG_Ability_Slot_PetCare1_C:UpdateIconRes()
  if 0 ~= self.EmptyItem:GetActiveWidgetIndex() then
    self.EmptyItem:SetActiveWidgetIndex(0)
  end
  if _G.NRCModuleManager:GetModule("HomeModule") then
    self.equipFoodId, self.equipFoodNum = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdGetEquipFoodIdAndNum)
  end
  if self.equipFoodId ~= nil then
    self:RefreshFoodIcon()
  end
end

function UMG_Ability_Slot_PetCare1_C:RefreshUI()
  local bCurrentPCMode = UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
  if self.bPCModeUI ~= bCurrentPCMode then
    return
  end
  local visible = false
  local isBan = _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_HOME_PET_FOOD)
  if isBan then
    visible = false
  elseif _G.HomeIndoorSandbox and _G.HomeIndoorSandbox:InLocalMasterIndoor() then
    visible = true
  else
    visible = false
  end
  if self._isVisible ~= visible then
    self._isVisible = visible
    self:SetVisible(self._isVisible)
  end
  if self._isVisible then
    self:RefreshFoodIcon()
  end
end

function UMG_Ability_Slot_PetCare1_C:SetVisible(bVisible)
  if bVisible then
    if self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(true)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    if self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Ability_Slot_PetCare1_C:OnSlotPressed(bind)
  local isBan = _G.FunctionBanManager:GetFunctionState(_G.Enum.PlayerFunctionBanType.PFBT_HOME_PET_FOOD, false, false)
  if isBan then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_Home_Property_C:OnActive")
  self:PlayAnimation(self.Press)
  self:ReqOpenEquipPanel()
end

function UMG_Ability_Slot_PetCare1_C:ReqOpenEquipPanel()
  if not _G.HomeIndoorSandbox or _G.HomeIndoorSandbox:InOtherHomeIndoor() then
    return
  end
  local req = ProtoMessage:newZoneGetBagReq()
  req.type = _G.Enum.BagItemType.BI_HOME_PET_FEED
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_GET_BAG_REQ, req, self, self.OnQueryEquipRsp)
end

function UMG_Ability_Slot_PetCare1_C:OnQueryEquipRsp(rsp)
  _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdOpenPanel, "HomePetFoodPocket", true, rsp)
end

function UMG_Ability_Slot_PetCare1_C:OnPCKey()
  if self.Visibility == UE.ESlateVisibility.Hidden or self.Visibility == UE.ESlateVisibility.Collapsed or self.Visibility == UE.ESlateVisibility.HitTestInvisible then
    return
  end
  if _G.FriendModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.PCKeyPressCloseFriendPanelTeam)
  end
  self.Btn_Slot:OnPress()
  self:OnSlotPressed()
end

function UMG_Ability_Slot_PetCare1_C:RemoveListener()
  _G.ZoneServer:RemoveProtocolListener(self, ProtoCMD.ZoneSvrCmd.ZONE_GOODS_REWARD_NOTIFY, self.OnZoneGoodsRewardNotify)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEquipFoodChange)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEnterHomeMap)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnExitHomeMap)
  end
  _G.FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_HOME_PET_FOOD, self, self.OnFunctionBan)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemUpdate, self.OnBagItemUpdate)
  _G.NRCEventCenter:UnRegisterEvent(self, BagModuleEvent.BagItemAdd, self.OnBagItemAdd)
end

function UMG_Ability_Slot_PetCare1_C:OnDestruct()
  Base.OnDestruct(self)
  self:RemoveListener()
end

function UMG_Ability_Slot_PetCare1_C:OnPlayerStatusChanged(status, value, opCode)
  self:RefreshUI()
  Base:OnPlayerStatusChanged(status, value, opCode)
end

function UMG_Ability_Slot_PetCare1_C:SetInputType(bPCModeUI, bCurrentPCMode)
  self.bPCModeUI = bPCModeUI
  if self.bPCModeUI ~= bCurrentPCMode then
    if self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
    if self.ParentPanel then
      self.ParentPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_Ability_Slot_PetCare1_C
