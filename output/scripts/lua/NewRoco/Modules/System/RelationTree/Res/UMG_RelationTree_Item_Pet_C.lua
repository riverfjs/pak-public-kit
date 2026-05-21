local UMG_RelationTree_Item_Pet_C = _G.NRCPanelBase:Extend("UMG_RelationTree_Item_Pet_C")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local RolePlayModuleDef = require("NewRoco.Modules.System.RolePlay.RolePlayModuleDef")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local relationtree_refresh_cd = _G.DataConfigManager:GetGlobalConfigByKeyType("relationtree_refresh_cd", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local RelationTreeRidePetItem = require("NewRoco.Modules.System.RelationTree.Res.RelationTreeRidePetItem")
local InteractionComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.InteractionComponent")
local BOND_TOUCH_VISION_RANGE = _G.DataConfigManager:GetGlobalConfigByKeyType("bond_touch_vision_range", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local BOND_TOUCH_DISTANCE = _G.DataConfigManager:GetGlobalConfigByKeyType("bond_touch_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG).num
local AppearanceModuleEnum = require("NewRoco.Modules.System.Appearance.AppearanceModuleEnum")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")
local ScenePlayerRideFriendPetBuff = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerRideFriendPetBuff")
local EnumOpationState = {GetState = 1, Implement = 2}
local PetTouchState = {
  IsCanTouch = 1,
  IsNotCanTouch = 2,
  IsNotFriendPet = 3,
  IsCanIntimate = 4,
  IsNotCanTouchForAnge = 5,
  IsInAnyGroup = 6
}
local PetCloseState = {
  IsHave = 1,
  IsNotHave = 2,
  IsNotBuyTime = 3,
  IsEmpty = 4,
  IsYiSeANotReward = 5,
  IsXuanCaiANotReward = 6,
  IsYiSeHaveReward = 7,
  IsXuanCaiHaveReward = 8,
  IsYiSeLowLevelNotReward = 9,
  IsXuanCaiLowLevelNotReward = 10,
  IsHaveButNoInteract = 11
}

function UMG_RelationTree_Item_Pet_C:IsPetBaseLowLevel(BaseId, fashionBondConf)
  if not (fashionBondConf and fashionBondConf.petbase_id) or not BaseId then
    return true
  end
  for _, id in ipairs(fashionBondConf.petbase_id) do
    if id == BaseId then
      return false
    end
  end
  return true
end

function UMG_RelationTree_Item_Pet_C:OnConstruct()
  self.player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  self:OnAddEventListener()
end

function UMG_RelationTree_Item_Pet_C:OnActive()
end

function UMG_RelationTree_Item_Pet_C:OnAddEventListener()
  self:AddButtonListener(self.SelectButton, self.OnSelectButton)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_Pet_C", self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.UpdateInviteAnim)
  _G.NRCEventCenter:RegisterEvent("UMG_RelationTree_Item_Pet_C", self, RelationTreeEvent.OnPetInfoEnableTouch, self.UpdatePetInfoEnableTouch)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoin)
end

function UMG_RelationTree_Item_Pet_C:UpdateSuitReward()
  if self:IsSelf() and self.ItemData and self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CLOSE then
    self.State = self:GetEnumOpation(EnumOpationState.GetState)
    self:UpdateClosenessUI()
  end
end

function UMG_RelationTree_Item_Pet_C:UpdateInviteAnim(isCancel)
  if self.ItemData and self.player then
    local InviteComponent = self.player:EnsureComponent(require("NewRoco.Modules.Core.Scene.Component.RolePlay.InviteComponent"))
    local pet_target_uin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerUin)
    if InviteComponent and pet_target_uin and InviteComponent.TargetUin == pet_target_uin then
      local IITType
      if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CIFU then
        IITType = ProtoEnum.InteractInviteType.IIT_PET_BLESSING
      end
      if not isCancel then
        if self.ItemData.Unlock then
        end
        if IITType and IITType == InviteComponent.InviteType and not self:IsSelf() then
          self:PlayAnimation(self.WaitForResponse_In)
        end
      elseif IITType and IITType == InviteComponent.InviteType and not self:IsSelf() then
        self:StopAnimation(self.WaitForResponse_In)
        self:StopAnimation(self.WaitForResponse)
        self:PlayAnimation(self.WaitForResponse_Out)
      end
    end
  end
end

function UMG_RelationTree_Item_Pet_C:SetData(Data)
  if not Data then
    return
  end
  self:OnItemUpdate(Data)
end

function UMG_RelationTree_Item_Pet_C:ShowITTDEmptyUI()
  self.NRCSwitcher:SetActiveWidgetIndex(1)
  self.NameText:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_RelationTree_Item_Pet_C:OnItemUpdate(Data)
  self.ItemData = Data
  self.State = self:GetEnumOpation(EnumOpationState.GetState)
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  if self.ItemData then
    if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_EMPTY then
      self:ShowITTDEmptyUI()
    else
      self.Text_NotOwned:SetText("")
      self.QuantityText:SetText("")
      if self.ItemData.Unlock then
        self:UpdateInviteAnim(false)
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Text_NotOwned:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.NameText:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_RIDE then
          if ParamData and ParamData.PetInfo and not self.PetRideIconInfo then
            local petInfo = ParamData.PetInfo
            local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
            local PetGid = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.gid or 0
            local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
            local Pet = ScenePlayerPet(nil, PetbaseId, PetGid, self.player, PetData)
            self.PetRideIconInfo = RelationTreeRidePetItem(Pet, function(IconType, IsBlock)
              self.RideBlock = IsBlock
              self:UpdateItemIconByRide(IconType)
            end)
          end
          if self.PetRideIconInfo then
            local IconType, IsBlock = self.PetRideIconInfo:GetIconInfo()
            self.RideBlock = IsBlock
            self:UpdateItemIconByRide(IconType)
          end
          self.NRCSwitcher:SetActiveWidgetIndex(0)
          self:PlayAnimation(self.Unlocked_normal, 0, 0)
          self.NameText:SetText(self.ItemData.StateStruct[self.State].name)
        elseif self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CLOSE then
          self:UpdateClosenessUI()
        else
          self.NRCSwitcher:SetActiveWidgetIndex(0)
          self:PlayAnimation(self.Unlocked_normal, 0, 0)
          self.NameText:SetText(self.ItemData.StateStruct[self.State].name)
          self:UpdateItemIcon()
        end
      else
        self.NRCSwitcher:SetActiveWidgetIndex(1)
        self.NameText:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if self.ItemData.InteractionTreeTypeDefault ~= Enum.InteractiontreeTypeDefault.ITTD_CLOSE then
      if self.ItemData.Cost > 0 then
        self.QuantityText:SetText(self.ItemData.Cost)
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local path = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_BRAVE_STAR).iconPath
        self.Icon:SetPath(path)
        local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_BRAVE_STAR) or 0
        if diamondNum < self.ItemData.Cost then
          self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
        else
          self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
        end
      else
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
    if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CIFU then
      if not ParamData or not ParamData.PetInfo then
        return
      end
      local petInfo = ParamData.PetInfo
      local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
      local curBaseConf = _G.DataConfigManager:GetPetbaseConf(PetbaseId)
      local curEvoConf = _G.DataConfigManager:GetPetEvolutionConf(curBaseConf.pet_evolution_id[1])
      local fristEvoBaseId
      if curEvoConf then
        for i = 1, #curEvoConf.evolution_chain do
          local chain = curEvoConf.evolution_chain[i]
          if 1 == chain.stage then
            fristEvoBaseId = chain.petbase_id
            break
          end
        end
      end
      local isShowTips = _G.NRCModuleManager:DoCmd(RelationTreeCmd.IsShowEggTips, fristEvoBaseId)
      local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_BRAVE_STAR) or 0
      if not isShowTips and diamondNum >= self.ItemData.Cost then
        self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    end
  end
end

function UMG_RelationTree_Item_Pet_C:UpdateClosenessUI()
  local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
  local BaseId = PetData and PetData.base_conf_id or 0
  local BondId = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
  local fashion_bond_conf = _G.DataConfigManager:GetFashionBondConf(BondId)
  if self.ItemData and self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CLOSE then
    if self.State == PetCloseState.IsYiSeANotReward or self.State == PetCloseState.IsYiSeLowLevelNotReward then
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self.headPortrait:SetPath("/Game/NewRoco/Modules/System/RelationTree/Rew/Frames/img_ClothingDifferentColors1_png.img_ClothingDifferentColors1_png")
      self.NameText:SetText(LuaText.interactiontree_closeness_mystery_gift)
      self.Text_NotOwned:SetText(LuaText.fashion_bond_lack_condition)
      self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
        self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
      end
    elseif self.State == PetCloseState.IsYiSeHaveReward then
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self.headPortrait:SetPath("/Game/NewRoco/Modules/System/RelationTree/Rew/Frames/img_ClothingDifferentColors2_png.img_ClothingDifferentColors2_png")
      self.NameText:SetText(LuaText.interactiontree_closeness_mystery_gift)
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_NotOwned:SetText(LuaText.interactiontree_already_have)
      self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
      self:PlayAnimation(self.head_In)
      if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
        self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
      end
    elseif self.State == PetCloseState.IsXuanCaiANotReward or self.State == PetCloseState.IsXuanCaiLowLevelNotReward then
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self.headPortrait:SetPath("/Game/NewRoco/Modules/System/RelationTree/Rew/Frames/img_xuancai1_png.img_xuancai1_png")
      self.NameText:SetText(LuaText.interactiontree_closeness_mystery_gift)
      self.Text_NotOwned:SetText(LuaText.fashion_bond_lack_condition)
      self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
        self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
      end
    elseif self.State == PetCloseState.IsXuanCaiHaveReward then
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self.headPortrait:SetPath("/Game/NewRoco/Modules/System/RelationTree/Rew/Frames/img_xuancai_png.img_xuancai_png")
      self.NameText:SetText(LuaText.interactiontree_closeness_mystery_gift)
      self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Text_NotOwned:SetText(LuaText.interactiontree_already_have)
      self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
      self:PlayAnimation(self.head_In)
      if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
        self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
      end
    elseif self.State == PetCloseState.IsEmpty or self.State == PetCloseState.IsHaveButNoInteract then
      self.NRCSwitcher:SetActiveWidgetIndex(1)
      self.NameText:SetText(self.ItemData.StateStruct[2].name)
    else
      self.NRCSwitcher:SetActiveWidgetIndex(0)
      self.headPortrait:SetPath(self.ItemData.StateStruct[1].icon)
      self.NameText:SetText(self.ItemData.StateStruct[1].name)
      if self.State == PetCloseState.IsHave then
        local IsFirst = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetBondFirstClick, BondId)
        if IsFirst then
          self:PlayAnimation(self.head_In)
          self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
            self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.Text_NotOwned:SetText(LuaText.interactiontree_already_have)
            self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
            self.headPortrait:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
            self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
          else
            self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
        else
          self:PlayAnimation(self.Unlocked_normal, 0, 0)
          self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      elseif self.State == PetCloseState.IsNotHave then
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if fashion_bond_conf and fashion_bond_conf.fashion_bond_icon and fashion_bond_conf.fashion_bond_icon ~= "" then
          self.Text_NotOwned:SetText(LuaText.fashion_bond_lack_condition)
          self.headPortrait:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
          self.Text_NotOwned:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
          self.Icon:SetPath(fashion_bond_conf.fashion_bond_icon)
        else
          self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      elseif self.State == PetCloseState.IsNotBuyTime then
        self.NRCSwitcher:SetActiveWidgetIndex(1)
        self.headPortrait:SetColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("#62605EFF"))
        self.ConstPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_RelationTree_Item_Pet_C:IsSelf()
  local isSelf = false
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
  if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
    isSelf = true
  end
  return isSelf
end

function UMG_RelationTree_Item_Pet_C:UpdateItemIconByRide(IconType)
  if self.ItemData then
    if not self:IsSelf() then
    end
    if IconType ~= RelationTreeRidePetItem.IconType.None then
      if self.ItemData.StateStruct[self.State].icon[IconType] and self.ItemData.StateStruct[self.State].icon[IconType] ~= "" then
        self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon[IconType])
      end
      if self.RideBlock then
        self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.RideBlock = true
      if self.ItemData.StateStruct[self.State].icon[1] and self.ItemData.StateStruct[self.State].icon[1] ~= "" then
        self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon[1])
      end
      self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end

function UMG_RelationTree_Item_Pet_C:UpdatePetInfoEnableTouch(PetNpc, Dis, CurAnge)
  if PetNpc and self.ItemData and self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_PET_TOUCH and Dis and CurAnge then
    local PlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerUin)
    local InTakePhotoWorld = NRCModuleManager:DoCmd(TakePhotosModuleCmd.IfInTakePhotoWorldPreviewMode) or NRCModuleManager:DoCmd(TakePhotosModuleCmd.IfInTakePhotoTripodMode)
    if self:IsSelf() and not InTakePhotoWorld then
      local InterComp = PetNpc:EnsureComponent(InteractionComponent)
      if InterComp then
        local NpcOption = InterComp:GetOptionByInteractType(Enum.InteractType.IT_MANUAL_BOND)
        if NpcOption and NpcOption:IsPetBond() and NpcOption:IsOptionEnable() then
          self.isIntimate = true
        else
          self.isIntimate = false
        end
      end
    end
    if Dis <= BOND_TOUCH_DISTANCE * BOND_TOUCH_DISTANCE and CurAnge <= BOND_TOUCH_VISION_RANGE then
      if PetNpc.AIComponent then
        local ctrl = PetNpc.AIComponent:GetControllerSafe()
        if ctrl then
          local inst, _, _ = ctrl:GetGroupInfos()
          if 0 ~= inst then
            self.IsEnableTouch = PetTouchState.IsInAnyGroup
            PetNpc:SetPetBondActive(false, 1)
            self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          else
            self:IsCanEnbaleTouchSetting(PetNpc)
          end
        else
          self:IsCanEnbaleTouchSetting(PetNpc)
        end
      else
        self:IsCanEnbaleTouchSetting(PetNpc)
      end
    else
      PetNpc:SetPetBondActive(false, 1)
      self.IsEnableTouch = PetTouchState.IsNotCanTouch
      if Dis <= BOND_TOUCH_DISTANCE * BOND_TOUCH_DISTANCE and CurAnge > BOND_TOUCH_VISION_RANGE then
        self.IsEnableTouch = PetTouchState.IsNotCanTouchForAnge
      end
      self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    self:PlayerPetEnableTouchAnimation()
  end
end

function UMG_RelationTree_Item_Pet_C:IsCanEnbaleTouchSetting(PetNpc)
  if PetNpc then
    if not self.isIntimate then
      self.IsEnableTouch = PetTouchState.IsCanTouch
    else
      self.IsEnableTouch = PetTouchState.IsCanIntimate
    end
    PetNpc:SetPetBondActive(true, 1)
    self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_RelationTree_Item_Pet_C:PlayerPetEnableTouchAnimation()
  if self.isIntimate and self.selfOldEnableTouch ~= self.IsEnableTouch then
    if self.IsEnableTouch == PetTouchState.IsCanIntimate then
      self:StopAnimation(self.line_loop)
      self:PlayAnimation(self.line_no)
      self:PlayAnimation(self.head_loop, 0, 0)
    else
      self:StopAnimation(self.head_loop)
      self:PlayAnimation(self.head_out)
      self:PlayAnimation(self.line_loop, 0, 0)
    end
    self.selfOldEnableTouch = self.IsEnableTouch
  end
end

function UMG_RelationTree_Item_Pet_C:UpdateItemIcon()
  if self.ItemData.StateStruct[self.State].icon and self.ItemData.StateStruct[self.State].icon ~= "" then
    self.headPortrait:SetPath(self.ItemData.StateStruct[self.State].icon)
  end
end

function UMG_RelationTree_Item_Pet_C:GetMovementMode()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player then
    return nil
  end
  if not player.viewObj then
    return nil
  end
  if not player.viewObj.BP_RideComponent then
    return nil
  end
  return player.viewObj.BP_RideComponent.RideMoveType
end

function UMG_RelationTree_Item_Pet_C:GetBPRideIsNotPlay()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    local state = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetPlayerInteractState, player)
    if state then
      return state == Enum.LocationInteractionBanType.STA_WATER_RIDE or state == Enum.LocationInteractionBanType.STA_FLY_RIDE
    end
  end
  return false
end

function UMG_RelationTree_Item_Pet_C:OnSelectButton()
  if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CLOSE and (self.State == PetCloseState.IsEmpty or self.State == PetCloseState.IsHaveButNoInteract) then
    return
  end
  if _G.BattleManager:IsInBattle() then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_PET_TOUCH then
    if self.IsEnableTouch == PetTouchState.IsNotCanTouch then
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local Name = PetData.name or ""
        local Text = string.format(LuaText.interactiontree_distance_far, Name)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      end
      return
    elseif self.IsEnableTouch == PetTouchState.IsNotFriendPet then
      local Text = LuaText.interactiontree_ride_request_text_4
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      return
    elseif self.IsEnableTouch == PetTouchState.IsNotCanTouchForAnge then
      local Text = LuaText.interactiontree_angle_out
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      return
    elseif self.IsEnableTouch == PetTouchState.IsInAnyGroup then
      self:ShowPetIsBusy()
      return
    end
  end
  local CanPlay = self:GetBPRideIsNotPlay()
  if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CIFU then
    local rideMovemode = self:GetMovementMode()
    if not (not (player and player.statusComponent) or player.statusComponent:PreApplyStatus(_G.Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING) or CanPlay) or rideMovemode == ProtoEnum.SceneRideAllType.SRAT_CLIMB_WATER or rideMovemode == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
      local Text = LuaText.RLTT_Error_Code_2443
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
      return
    end
  end
  if player and player.statusComponent and player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_PET_BLESSING) then
    local Text = LuaText.relationtree_abnormal_status_tip
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_RIDE and self.RideBlock then
    if player and player.buffComponent and player.buffComponent:HasBuff(ScenePlayerRideFriendPetBuff.BuffName) then
      Log.Debug("UMG_RelationTree_Item_Pet_C:OnSelectButton is requesting, no need to show tips")
      return
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.RLTT_Error_Code_2443)
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_Pet_C:OnConfirm")
  if _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetRelationItemSelectCD) > 0 then
    local Text = _G.DataConfigManager:GetLocalizationConf("relationtree_item_select_incd").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if self.ItemData.Unlock then
    local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
    local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
    if PetData then
      local BaseID = PetData.base_conf_id or 0
      local GID = PetData.gid or 0
      local mutationType = PetData.mutation_type or 0
      local PetOwnerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerUin)
      _G.NRCModuleManager:DoCmd(RelationTreeCmd.RelationTreeSendTLog, 1, self.ItemData, BaseID, GID, mutationType, PetOwnerUin)
    end
    if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CIFU and player and player.statusComponent and player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE) then
      local custom_params = player.statusComponent:GetCustomParams(Enum.WorldPlayerStatusType.WPST_TWO_PLAYER_ANIM_INVITE)
      if custom_params and custom_params.player_interact_param then
        local pet_id = custom_params.player_interact_param.pet_id
        local CurPetId = ParamData and ParamData.PetInfo and ParamData.PetInfo.serverData and ParamData.PetInfo.serverData.base and ParamData.PetInfo.serverData.base.actor_id
        if pet_id == CurPetId then
          local Text = LuaText.relationtree_repeat_request_tip
          _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
          return
        end
      end
    end
    if self.ItemData.Cost > 0 then
      local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_BRAVE_STAR) or 0
      if diamondNum < self.ItemData.Cost then
        local name = _G.DataConfigManager:GetVisualItemConf(_G.Enum.VisualItem.VI_BRAVE_STAR).displayName
        local Text = _G.DataConfigManager:GetLocalizationConf("interactiontree_cifu_lack_money").msg
        local des = string.format(Text, name)
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, des)
        return
      end
    end
    local IsSuccess = self:GetEnumOpation(EnumOpationState.Implement)
    if self.ItemData.InteractionTreeTypeDefault ~= Enum.InteractiontreeTypeDefault.ITTD_RIDE or IsSuccess then
    end
  elseif self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_EMPTY then
    self:GetEnumOpation(EnumOpationState.Implement)
    return
  end
  _G.NRCModeManager:DoCmd(RelationTreeCmd.SetRelationItemSelectCD, relationtree_refresh_cd)
  if self.click then
    self:PlayAnimation(self.click)
  end
end

function UMG_RelationTree_Item_Pet_C:UpdateItemSelect(NodeId)
  if self.ItemData and self.ItemData.InteractionTreeTypeDefault ~= Enum.InteractiontreeTypeDefault.ITTD_EMPTY then
    if self.ItemData.ID == NodeId then
      self.SelfSelect = true
    elseif self.SelfSelect then
      self.SelfSelect = false
      if self.ItemData.Unlock then
        self:PlayAnimation(self.Unlocked_normal, 0, 0)
      end
    end
  end
end

function UMG_RelationTree_Item_Pet_C:GetDefaultEnumOpation(Opation)
  local InteractionEnum = Enum.InteractiontreeTypeDefault
  if self.ItemData.InteractionTreeTypeDefault == InteractionEnum.ITTD_CHECK_INF then
    if Opation == EnumOpationState.GetState then
      return 1
    else
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      self:OnHandleCheckPet(ParamData and ParamData.PetInfo or nil)
      return true
    end
  elseif self.ItemData.InteractionTreeTypeDefault == InteractionEnum.ITTD_CIFU then
    if Opation == EnumOpationState.GetState then
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
      if PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) then
        return 1
      else
        return 2
      end
    else
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetNpcCreateAvatarId = ParamData and ParamData.AvatarID or 0
      local Player = PetNpcCreateAvatarId == _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN) and _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER) or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, PetNpcCreateAvatarId)
      local IsSuccess = self:OnHandleCIFU(Player, ParamData and ParamData.PetInfo or nil)
      return IsSuccess
    end
  elseif self.ItemData.InteractionTreeTypeDefault == InteractionEnum.ITTD_RIDE then
    if Opation == EnumOpationState.GetState then
      return 1
    else
      _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_RelationTree_Item_Pet_C.InteractionEnum.ITTD_RIDE")
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      if ParamData then
        local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
        local localPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        localPlayer:RideFriendPet(ParamData.PetInfo, PetData)
        local isRide = localPlayer.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
        return isRide
      end
      return false
    end
  elseif self.ItemData.InteractionTreeTypeDefault == InteractionEnum.ITTD_PET_TOUCH then
    if Opation == EnumOpationState.GetState then
      return 1
    else
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
      if not PetNpc or not PetNpc:CanInteract() then
        self:ShowPetIsBusy()
        return
      end
      local InterComp = PetNpc:EnsureComponent(InteractionComponent)
      if InterComp and self.IsEnableTouch then
        if self.IsEnableTouch == PetTouchState.IsCanTouch then
          self:RequestForPetInteract()
        elseif self.IsEnableTouch == PetTouchState.IsCanIntimate then
          self:RequestForPetInteract()
        end
      end
    end
  elseif self.ItemData.InteractionTreeTypeDefault == InteractionEnum.ITTD_CLOSE then
    if Opation == EnumOpationState.GetState then
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local BondId = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
        local IsYiSe = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(PetData.mutation_type) or PetUtils.CheckIsHiddenShiningGlass(PetData.mutation_type, PetData.glass_info) or PetUtils.CheckIsShiningChaos(PetData.mutation_type)
        local IsXuanCai = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) or PetUtils.CheckIsShiningGlass(PetData.mutation_type) or PetUtils.CheckIsHiddenGlass(PetData.mutation_type, PetData.glass_info) or PetUtils.CheckIsHiddenShiningGlass(PetData.mutation_type, PetData.glass_info)
        local GlassInfo = PetData.glass_info or nil
        if BondId then
          local IsHave = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetSelfIsHaveBondID, BondId)
          local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(BondId)
          local fashion_bond_source = fashionBondConf and fashionBondConf.fashion_bond_source or nil
          local Quality = 1
          local isHaveShiningSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetShiningSuitIdFromBondId, BondId)
          if fashionBondConf and fashionBondConf.fashion_bond_quality then
            if fashionBondConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_S then
              Quality = 1
            elseif fashionBondConf.fashion_bond_quality == _G.Enum.FashionBondQuality.FBQ_A then
              Quality = 2
            end
          end
          local isLowLevel = self:IsPetBaseLowLevel(BaseId, fashionBondConf)
          if self:IsSelf() then
            if IsHave then
              if IsYiSe and isHaveShiningSuit then
                local IsState = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetColorSuitState)
                if 0 == IsState then
                  if isLowLevel then
                    return PetCloseState.IsYiSeLowLevelNotReward
                  elseif 2 == Quality then
                    return PetCloseState.IsYiSeANotReward
                  end
                elseif 1 == IsState then
                  return PetCloseState.IsYiSeHaveReward
                end
              end
              if IsXuanCai and fashion_bond_source and fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
                local isClanmable = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckPetGlassTintIsClaimableByBondID, BondId, GlassInfo, IsYiSe)
                if isClanmable then
                  return PetCloseState.IsXuanCaiHaveReward
                end
              end
            else
              local SutId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, BondId)
              local bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, SutId)
              local IsCanBuy = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetFashionSuitIsCanBuy, BondId)
              local isShowReward = false
              if not bHasSuit then
                local IsCanBuy = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetFashionSuitIsCanBuy, BondId)
                if IsCanBuy then
                  isShowReward = true
                end
              else
                isShowReward = true
              end
              if isShowReward then
                if isHaveShiningSuit and IsYiSe then
                  local IsState = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetColorSuitState)
                  if 0 == IsState then
                    if isLowLevel then
                      return PetCloseState.IsYiSeLowLevelNotReward
                    elseif 2 == Quality then
                      return PetCloseState.IsYiSeANotReward
                    end
                  end
                end
                if IsXuanCai and fashion_bond_source and fashion_bond_source == Enum.FashionBondSource.FBS_SUITS then
                  if isLowLevel then
                    return PetCloseState.IsXuanCaiLowLevelNotReward
                  elseif 2 == Quality then
                    local isClanmable = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckPetGlassTintIsClaimableByBondID, BondId, GlassInfo, IsYiSe)
                    if not isClanmable then
                      return PetCloseState.IsXuanCaiANotReward
                    end
                  end
                end
              end
            end
          end
          local IsHaveAnim = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetBondInteractID, BondId)
          if not IsHaveAnim then
            return PetCloseState.IsEmpty
          end
          if IsHave then
            if isLowLevel then
              return PetCloseState.IsHaveButNoInteract
            end
            return PetCloseState.IsHave
          else
            local SutId = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.GetSuitIdFromBondId, BondId)
            local bHasSuit = _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.CheckHasSuit, SutId)
            if not bHasSuit then
              local IsCanBuy = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetFashionSuitIsCanBuy, BondId)
              if IsCanBuy then
                return PetCloseState.IsNotHave
              else
                local commodityState = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetFashionSuitBuyState, BondId)
                if commodityState == AppearanceModuleEnum.SuitState.NotOnShelf then
                  return PetCloseState.IsEmpty
                elseif commodityState == AppearanceModuleEnum.SuitState.OffShelf or commodityState == AppearanceModuleEnum.SuitState.NotPurchasable then
                  return PetCloseState.IsNotBuyTime
                else
                  return PetCloseState.IsEmpty
                end
              end
            else
              return PetCloseState.IsNotHave
            end
          end
        else
          return PetCloseState.IsEmpty
        end
      else
        return PetCloseState.IsEmpty
      end
    elseif self.State == PetCloseState.IsHave then
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
      if not PetNpc or not PetNpc:CanInteract() then
        self:ShowPetIsBusy()
        return
      end
      self:RequestForPetInteract()
    elseif self.State == PetCloseState.IsNotHave then
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local fashion_bond_id = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
        _G.NRCModuleManager:DoCmd(RelationTreeCmd.OpenRelationTreeMedalPopUp, fashion_bond_id, PetData.mutation_type)
      end
    elseif self.State == PetCloseState.IsNotBuyTime then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.interactiontree_badge_not_during_purchase)
    elseif self.State == PetCloseState.IsEmpty or self.State == PetCloseState.IsHaveButNoInteract then
    elseif self.State == PetCloseState.IsYiSeANotReward or self.State == PetCloseState.IsYiSeLowLevelNotReward then
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local fashion_bond_id = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
        _G.NRCModuleManager:DoCmd(RelationTreeCmd.OpenRelationTreeMedalPopUp, fashion_bond_id, PetData.mutation_type)
      end
    elseif self.State == PetCloseState.IsYiSeHaveReward then
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local fashion_bond_id = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetPetFashionBondID, BaseId)
        local IsHasAnim = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetBondInteractID, fashion_bond_id)
        local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(fashion_bond_id)
        local isLowLevel = self:IsPetBaseLowLevel(BaseId, fashionBondConf)
        if IsHasAnim and not isLowLevel then
          local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
          if not PetNpc or not PetNpc:CanInteract() then
            self:ShowPetIsBusy()
            return
          end
          self:RequestForPetInteract()
        else
          local PetGid = PetData.gid or 0
          _G.NRCModuleManager:DoCmd(AppearanceModuleCmd.ClaimHeterochromeSuitReq, fashion_bond_id, PetGid)
          _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnPetInfoRideSuccessClose, true)
        end
      end
    elseif self.State == PetCloseState.IsXuanCaiANotReward or self.State == PetCloseState.IsXuanCaiLowLevelNotReward then
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local fashion_bond_id = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
        _G.NRCModuleManager:DoCmd(RelationTreeCmd.OpenRelationTreeMedalPopUp, fashion_bond_id, PetData.mutation_type)
      end
    elseif self.State == PetCloseState.IsXuanCaiHaveReward then
      local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
      local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
      if PetData then
        local BaseId = PetData.base_conf_id or 0
        local BondId = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
        local fashionBondConf = _G.DataConfigManager:GetFashionBondConf(BondId)
        local IsHasAnim = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.GetBondInteractID, BondId)
        local isLowLevel = self:IsPetBaseLowLevel(BaseId, fashionBondConf)
        if IsHasAnim and not isLowLevel then
          local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
          if PetNpc and not PetNpc:CanInteract() then
            self:ShowPetIsBusy()
            return
          end
          self:RequestForPetInteract()
        else
          local GlassInfo = PetData.glass_info or nil
          local IsYiSe = PetMutationUtils.GetMutationValue(PetData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(PetData.mutation_type) or PetUtils.CheckIsHiddenShiningGlass(PetData.mutation_type, PetData.glass_info) or PetUtils.CheckIsShiningChaos(PetData.mutation_type)
          _G.NRCModuleManager:DoCmd(_G.AppearanceModuleCmd.SendClaimGlassTintReq, BondId, IsYiSe, GlassInfo, nil, PetData)
        end
      end
    end
  end
end

function UMG_RelationTree_Item_Pet_C:GetEnumOpation(Opation)
  if self.ItemData then
    if self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_EMPTY then
      if Opation == EnumOpationState.GetState then
        return 1
      else
        self:ShowStayTunedTips()
      end
    elseif Opation == EnumOpationState.GetState then
      return self:GetDefaultEnumOpation(Opation)
    else
      return self:GetDefaultEnumOpation(Opation)
    end
  end
end

function UMG_RelationTree_Item_Pet_C:OnHandleCIFU(player, petInfo)
  local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_BRAVE_STAR) or 0
  if self.ItemData and diamondNum < self.ItemData.Cost then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.interactiontree_coin_lack)
    return
  end
  if player and petInfo then
    local panelData = require("NewRoco.Modules.System.RelationTree.Res.RelationEggPanelData")
    if panelData then
      local PlayerUin = player.serverData and player.serverData.base and player.serverData.base.logic_id or 0
      local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
      local PetGid = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.gid or 0
      local PetActorId = petInfo.serverData and petInfo.serverData.base and petInfo.serverData.base.actor_id or 0
      local IsLocalPet = player and player.isLocal or false
      local PlayerName = player.serverData and player.serverData.base and player.serverData.base.name or ""
      panelData:SetType(panelData.EggPanelType.Bless)
      panelData:SetArgData({
        targetUin = PlayerUin,
        petId = PetGid,
        petNpcId = PetActorId,
        targetName = PlayerName,
        petbaseId = PetbaseId,
        isLocal = IsLocalPet
      })
      local isSuccess = _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenRelationEggBag, panelData)
      return isSuccess
    end
  else
    local pet_target_name = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerName)
    local refuse_info = string.format(_G.LuaText.interactiontree_cifu_pet_distance_out, pet_target_name)
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, refuse_info)
    return false
  end
end

function UMG_RelationTree_Item_Pet_C:OnHandleCheckPet(petInfo)
  local PlayerUin = _G.NRCModeManager:DoCmd(_G.RelationTreeCmd.GetCurOpenPetPanelPlayerUin)
  if petInfo then
    local PetGid = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.gid or 0
    local PetNpcId = petInfo.serverData and petInfo.serverData.base and petInfo.serverData.base.logic_id or 0
    _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.OpenRelationPetPreview, PlayerUin, PetGid, PetNpcId)
  end
end

function UMG_RelationTree_Item_Pet_C:ShowStayTunedTips()
  local Text = _G.DataConfigManager:GetLocalizationConf("interactiontree_unknown_text").msg
  if Text then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
  end
end

function UMG_RelationTree_Item_Pet_C:UpdateCoin()
  if self.ItemData and self.ItemData.InteractionTreeTypeDefault == Enum.InteractiontreeTypeDefault.ITTD_CIFU then
    local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
    local petInfo = ParamData.PetInfo
    local PetbaseId = petInfo.serverData and petInfo.serverData.pet_info and petInfo.serverData.pet_info.pet_base_conf_id or 0
    local curBaseConf = _G.DataConfigManager:GetPetbaseConf(PetbaseId)
    local curEvoConf = _G.DataConfigManager:GetPetEvolutionConf(curBaseConf.pet_evolution_id[1])
    local fristEvoBaseId
    if curEvoConf then
      for i = 1, #curEvoConf.evolution_chain do
        local chain = curEvoConf.evolution_chain[i]
        if 1 == chain.stage then
          fristEvoBaseId = chain.petbase_id
          break
        end
      end
    end
    local isShowTips = _G.NRCModuleManager:DoCmd(RelationTreeCmd.IsShowEggTips, fristEvoBaseId)
    local diamondNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_BRAVE_STAR) or 0
    if not isShowTips and diamondNum >= self.ItemData.Cost then
      self.Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if diamondNum < self.ItemData.Cost then
      self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#AE3D3EFF"))
    else
      self.QuantityText:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#F4EEE1FF"))
    end
  end
end

function UMG_RelationTree_Item_Pet_C:OnAnimationFinished(anim)
  if anim == self.WaitForResponse_In then
    self:PlayAnimation(self.WaitForResponse, 0, 0)
  elseif anim == self.head_In then
    self:PlayAnimation(self.head_loop, 0, 0)
  end
end

function UMG_RelationTree_Item_Pet_C:ShowPetIsBusy()
  local BusyTip = _G.LuaText.intercationtree_touch_head_busy
  local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
  local PetName = PetData and PetData.name or ""
  local TipContent = string.format(BusyTip, PetName)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, TipContent)
end

function UMG_RelationTree_Item_Pet_C:RequestForPetInteract()
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
  local serverData = PetNpc and PetNpc.serverData
  local base = serverData and serverData.base
  local pet_npc_id = base and base.actor_id
  if not pet_npc_id then
    return
  end
  local req = _G.ProtoMessage:newZoneScenePetTreeInteractHoldReq()
  req.pet_npc_id = pet_npc_id
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_PET_TREE_INTERACT_HOLD_REQ, req, self, self.OnPetInteractHoldRsp, false, true)
end

function UMG_RelationTree_Item_Pet_C:OnPetInteractHoldRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ShowPetIsBusy()
    return
  end
  local ParamData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetRelationTreeUIData)
  local PetNpc = ParamData and ParamData.PetInfo and ParamData.PetInfo or nil
  if not PetNpc then
    self:ShowPetIsBusy()
    return
  end
  local cachedInteractTreeType = self.ItemData and self.ItemData.InteractionTreeTypeDefault
  if not cachedInteractTreeType then
    return
  end
  if not self.player.statusComponent:PreApplyStatus(_G.Enum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR) then
    local Text = LuaText.RLTT_Error_Code_2443
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, Text)
    return
  end
  if cachedInteractTreeType == Enum.InteractiontreeTypeDefault.ITTD_PET_TOUCH then
    if self.IsEnableTouch then
      if PetNpc and PetNpc.HiddenComponent then
        PetNpc.HiddenComponent:ResetHide()
      end
      if self.IsEnableTouch == PetTouchState.IsCanTouch then
        self:ExecutePetTouch(PetNpc)
      elseif self.IsEnableTouch == PetTouchState.IsCanIntimate then
        self:StopAnimation(self.head_loop)
        self:StopAnimation(self.line_loop)
        self:PlayAnimation(self.head_out)
        self:PlayAnimation(self.line_no)
        local InterComp = PetNpc.InteractionComponent
        local NpcOption = InterComp and InterComp:GetOptionByInteractType(Enum.InteractType.IT_MANUAL_BOND)
        if NpcOption then
          NpcOption:OnOptionAction()
        end
      end
    else
      self:ShowPetIsBusy()
      return
    end
  elseif cachedInteractTreeType == Enum.InteractiontreeTypeDefault.ITTD_CLOSE then
    local PetData = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetInfoData)
    if PetData then
      local BaseId = PetData.base_conf_id or 0
      local fashion_bond_id = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetFashionBondID, BaseId)
      if fashion_bond_id then
        local IsFirst = _G.NRCModuleManager:DoCmd(RelationTreeCmd.GetPetBondFirstClick, fashion_bond_id)
        if IsFirst then
          local Req = ProtoMessage:newZonePetTreeFirstInteractNty()
          Req.pet_base_id = BaseId
          Req.fashion_bond_id = fashion_bond_id
          _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_PET_TREE_FIRST_INTERACT_NTY, Req)
        end
        self:ExecuteFashionBond(PetNpc, fashion_bond_id, PetData.gid)
      else
        Log.Error("\228\184\141\229\186\148\232\175\165\232\131\189\232\181\176\232\191\155\230\157\165")
      end
    end
  else
    self:ShowPetIsBusy()
    return
  end
  _G.NRCEventCenter:DispatchEvent(RelationTreeEvent.OnPetInfoRideSuccessClose, true)
end

function UMG_RelationTree_Item_Pet_C:ExecutePetTouch(pet)
  local StateStructs = self.ItemData and self.ItemData.StateStruct
  local StateStruct = StateStructs and StateStructs[self.State]
  local actionId = StateStruct and StateStruct.actionID or 0
  local conf = _G.DataConfigManager:GetRelationtreeAnimConf(actionId)
  if not conf then
    return
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local petView = pet.viewObj
  local random_params
  if petView:IsHigherThanPlayer(localPlayer) then
    random_params = conf.param2
  else
    random_params = conf.param1
  end
  local random_actions = string.split(random_params, ";")
  local random_index = math.random(1, #random_actions)
  local random_action = random_actions[random_index]
  local random_action_id = tonumber(random_action)
  if not random_action_id then
    return
  end
  local executeParam = {}
  executeParam.skill_interact_id = random_action_id
  executeParam.statusParams = {}
  executeParam.pet_actor_id = pet.serverData.base.actor_id
  executeParam.statusParams.role_play_param = {}
  executeParam.statusParams.role_play_param.skill_interact_id = random_action_id
  executeParam.statusParams.role_play_param.pet_id = pet.serverData.pet_info.pet_base_conf_id
  executeParam.statusParams.role_play_param.skill_type = _G.ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ExecuteRolePlay, executeParam)
end

function UMG_RelationTree_Item_Pet_C:ExecuteFashionBond(pet, fashion_bond_id, petGid)
  local fashion_bond = _G.DataConfigManager:GetFashionBondConf(fashion_bond_id)
  local pet_interact_id = fashion_bond and fashion_bond.pet_interact_id
  if not pet_interact_id then
    return
  end
  local executeParam = {}
  executeParam.skill_interact_id = pet_interact_id
  executeParam.statusParams = {}
  executeParam.pet_actor_id = pet.serverData.base.actor_id
  executeParam.statusParams.role_play_param = {}
  executeParam.statusParams.role_play_param.skill_interact_id = pet_interact_id
  executeParam.statusParams.role_play_param.pet_id = pet.serverData.pet_info.pet_base_conf_id
  executeParam.statusParams.role_play_param.skill_type = _G.ProtoEnum.RolePlaySkillType.RPST_PET_TREE_CLOSE
  local PetOwnerActorID = pet.serverData.npc_base.create_avatar_id or 0
  _G.NRCModuleManager:DoCmd(_G.RelationTreeCmd.StartCloseRolePlayFromRelationTree, fashion_bond_id, petGid, PetOwnerActorID)
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.ExecuteRolePlay, executeParam)
end

function UMG_RelationTree_Item_Pet_C:OnDestruct()
  if self.PetRideIconInfo then
    self.PetRideIconInfo:Dctor()
  end
  self.PetRideIconInfo = nil
  _G.NRCModeManager:DoCmd(RelationTreeCmd.SetRelationItemSelectCD, 0)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.RELATION_INVITE_CANCEL_UPDATE, self.UpdateInviteAnim)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnPetInfoEnableTouch, self.UpdatePetInfoEnableTouch)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.UpdateCoin)
end

return UMG_RelationTree_Item_Pet_C
