local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local BagModuleCmd = require("NewRoco.Modules.System.Bag.BagModuleCmd")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local NpcOptionEvent = require("NewRoco.Modules.Core.NPC.Executors.NpcOptionEvent")
local ShowID = RocoEnv.IS_EDITOR or not RocoEnv.IS_SHIPPING and _G.AppMain:HasLaunchParams()
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local FarmUtils = require("NewRoco.Modules.System.Farm.FarmUtils")
local FarmModuleEnum = require("NewRoco.Modules.System.Farm.FarmModuleEnum")
local FarmConst = require("NewRoco.Modules.System.Farm.FarmConst")
local ENUM_PLAYER_DATA_EVENT = require("Data.Global.PlayerDataEvent")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")
local RelationTreeEvent = reload("NewRoco.Modules.System.RelationTree.RelationTreeEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local UMG_NPCInteractItem_C = Base:Extend("UMG_NPCInteractItem_C")

function UMG_NPCInteractItem_C:SetBackGround(bIsPress)
  if self.option and self.option.bFake or self.bIsPress == bIsPress then
    return
  end
  self.bIsPress = bIsPress
  if bIsPress then
    self.Background_Selected:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Background:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if SystemSettingModuleCmd and self.FKey then
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_InteractionStart")
      if "" ~= image then
        self.FKey:SetImageMode(image)
      else
        self.FKey:SetText(text)
      end
      self.FKey:SetKeyVisibility(true)
    end
    UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, self.bIsPress, 22)
    UIUtils.SetTextWithValidation(self.ItemDesc_1, self.coin_content, self.coin_validation, self.bIsPress)
  else
    self.Background_Selected:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Background:SetVisibility(UE4.ESlateVisibility.Visible)
    if SystemSettingModuleCmd and self.FKey then
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_InteractionStart")
      if "" ~= image then
        self.FKey:SetImageMode(image)
      else
        self.FKey:SetText(text)
      end
      self.FKey:SetKeyVisibility(false)
    end
    UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, self.bIsPress, 22)
    UIUtils.SetTextWithValidation(self.ItemDesc_1, self.coin_content, self.coin_validation, self.bIsPress)
  end
  self:UpdateDesc2Content(self.bIsPress, self.option)
end

function UMG_NPCInteractItem_C:OnItemSelected(bSelected)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.InteractItemOnSelect)
  self.bSelectedAndTouch = bSelected
  self:SetBackGround(bSelected)
end

function UMG_NPCInteractItem_C:OnMouseEnter()
end

function UMG_NPCInteractItem_C:OnMouseLeave(_)
  self:ReleaseTouchMark(true)
end

function UMG_NPCInteractItem_C:ReleaseTouchMark(bHaverOut)
  if self.TouchMark then
    if bHaverOut then
      self:SetHoverBG(false)
    end
    self.TouchMark = false
  end
end

function UMG_NPCInteractItem_C:Tick(_, deltaTime)
  if self.option and not self.option.bIsPlayerOption and self.option:IsFarmOption() then
    self:UpdateDesc2Content(self.bIsPress, self.option)
  end
  if not self.isPressed then
    return
  end
  self._timer = self._timer - deltaTime
  if self.LongPressTime - self._timer >= self.LongPressMinTime then
    self.Progress:showAni(nil, self.LongPressTime - self._timer, self.LongPressTime)
  end
  if self._timer <= 0 then
    self:OnLongClick()
  end
end

function UMG_NPCInteractItem_C:ClearCacheData()
  self.isPressed = false
  self.bSelectedAndTouch = false
  self._timer = self.LongPressTime
  if self.ParentView then
    self.ParentView.longTouchItem = nil
  end
  self.Progress:showEndAni()
end

function UMG_NPCInteractItem_C:OnLongClick()
  self.isPressed = false
  self.bSelectedAndTouch = false
  self:SetBackGround(false)
  self.Progress:showEndAni()
  local AllCount = self.ParentView.itemCount
  self.ParentView.longTouch = true
  for i = AllCount, 1, -1 do
    local itemData = self.ParentView:GetItemByIndex(i - 1)
    if itemData and itemData.option and itemData.option.config.action.action_type == Enum.ActionType.ACT_BAGITEM then
      itemData.option:OnOptionAction()
    end
  end
end

function UMG_NPCInteractItem_C:OnTouchStarted(MyGeometry, InTouchEvent)
  if not self.option or self.option.bFake then
    return UE.UWidgetBlueprintLibrary.UnHandled()
  end
  self:SetHoverBG(true)
  if self:CheckIsLock() then
    Log.DebugFormat("[NPCInteractMainUI] OnTouchStarted MultiTouch\230\139\166\230\136\170\228\186\134 %s", self.GetOptionID and self:GetOptionID() or "\231\130\184\231\154\132\229\190\136\228\184\165\233\135\141\228\186\134")
    return UE.UWidgetBlueprintLibrary.UnHandled()
  end
  self._timer = self.LongPressTime
  if self.option.config.action.action_type == Enum.ActionType.ACT_BAGITEM then
    self.isPressed = true
  end
  if self.ParentView then
    self.ParentView.longTouchItem = self
  end
  self.TouchMark = true
  return Base.OnTouchStarted(self, MyGeometry, InTouchEvent)
end

local NoScrollActionTypes = {
  [Enum.ActionType.ACT_BAGITEM] = true,
  [Enum.ActionType.ACT_AWARD] = true,
  [Enum.ActionType.ACT_NONE] = true,
  [Enum.ActionType.ACT_UNLOCK_DUNGEON_ENTRY] = true,
  [Enum.ActionType.ACT_OPENCHEST] = true
}

function UMG_NPCInteractItem_C:OnTouchEnded(_, _)
  if not self.option or self.option.bFake or not self.TouchMark then
    Log.DebugFormat("[NPCInteractMainUI] OnTouchEnded \229\174\140\229\133\168\230\178\161\230\156\186\228\188\154\232\167\166\229\143\145 %s", self.GetOptionID and self:GetOptionID() or "\231\130\184\231\154\132\229\190\136\228\184\165\233\135\141\228\186\134")
    self:SetHoverBG(false)
    return UE.UWidgetBlueprintLibrary.Unhandled()
  end
  self:ReleaseTouchMark(true)
  if self:CheckIsLock() then
    Log.DebugFormat("[NPCInteractMainUI] OnTouchEnded MultiTouch\230\139\166\230\136\170\228\186\134 %s", self.GetOptionID and self:GetOptionID() or "\231\130\184\231\154\132\229\190\136\228\184\165\233\135\141\228\186\134")
    self:SetHoverBG(false)
    return UE.UWidgetBlueprintLibrary.Unhandled()
  end
  if not self.option.bIsPlayerOption then
    local owner = self.option and self.option.owner
    local canInteract = owner and owner:CanInteract() or false
    local serverId = owner and owner:GetServerId() or 0
    local realNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, serverId)
    if not (self.option.inActionArea and canInteract and realNpc) or realNpc ~= owner then
      Log.Error("[NPCInteractMainUI] Option\232\161\140\228\184\186\229\188\130\229\184\184", self.option.inActionArea, canInteract, realNpc or "\230\151\160", owner)
      self:BroadcastMsg("OnOptionResidue", self.option)
      return UE.UWidgetBlueprintLibrary.Unhandled()
    end
  end
  self.ParentView.longTouchItem = nil
  self.isPressed = false
  Log.Debug("[NPCInteractMainUI] OnTouchEnded")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1067, "UMG_Magic_Nourish_C:OnUpgradeBtnClick")
  self.bSelectedAndTouch = true
  local actionType = self.option.config.action.action_type
  if self.option.NeedStatusNotify and self.option:NeedStatusNotify() and not SceneUtils.debugForceNpcOptionInvalid then
    local CurrentAction = self.option.CurrentAction
    if CurrentAction then
      CurrentAction:LogError("[NPCInteractMainUI] \233\156\128\232\166\129\231\173\137\229\190\133\228\184\138\230\172\161\228\186\164\228\186\146\229\141\143\232\174\174\230\156\141\229\138\161\229\153\168\229\155\158\229\140\133\239\188\140\230\156\172\230\172\161\228\186\164\228\186\146\229\183\178\231\187\143\232\162\171\230\139\166\230\136\170")
    else
      Log.Error("[NPCInteractMainUI] \233\156\128\232\166\129\231\173\137\229\190\133\228\184\138\230\172\161\228\186\164\228\186\146\229\141\143\232\174\174\230\156\141\229\138\161\229\153\168\229\155\158\229\140\133\239\188\140\230\156\172\230\172\161\228\186\164\228\186\146\229\183\178\231\187\143\232\162\171\230\139\166\230\136\170", self.option.config.id)
    end
    self:SetHoverBG(false)
    return UE.UWidgetBlueprintLibrary.Unhandled()
  end
  self:LockIsSelectBtnByActionType(actionType)
  self.option:OnOptionAction()
  return UE.UWidgetBlueprintLibrary.Handled()
end

function UMG_NPCInteractItem_C:OnOptionChanged(Option, _)
  if self.option == Option and Option:NeedsValidation() then
    self:RefreshValidationInfo()
  end
end

function UMG_NPCInteractItem_C:RefreshValidationInfo()
  if not self.option then
    Log.DebugFormat("[NPCInteractMainUI] RefreshValidationInfo %s", self.GetOptionID and self:GetOptionID() or "\231\130\184\231\154\132\229\190\136\228\184\165\233\135\141\228\186\134")
    return
  end
  local validation, content, itemid = self.option:GetValidationInfo()
  self.coin_validation = validation
  self.coin_content = content
  self.ItemDesc_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self.Icon_1:SetVisibility(UE4.ESlateVisibility.Visible)
  UIUtils.SetTextWithValidation(self.ItemDesc_1, self.coin_content, self.coin_validation, self.bIsPress)
  local item_conf = _G.DataConfigManager:GetBagItemConf(itemid)
  if item_conf then
    self.Icon_1:SetPath(item_conf.icon)
  end
end

function UMG_NPCInteractItem_C:RefreshFarmInfo()
  if not self.option or not self.option.owner then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self:UpdateFarmIcon(self.option)
  self:UpdateDesc2Visibility(self.option)
  self:UpdateDesc2Content(self.bIsPress, self.option)
end

function UMG_NPCInteractItem_C:UpdateFarmIcon(option)
  local optionType = FarmUtils.GetFarmOptionType(option)
  if optionType == FarmModuleEnum.OptionType.Harvesting or optionType == FarmModuleEnum.OptionType.Stealing then
    local landInfo = option:GetOwnerFarmlandInfo()
    local landId = landInfo.plant_id
    if FarmUtils.IsLandHarvest(landId) then
      self.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      local harvestIconPath = _G.NRCModeManager:DoCmd(_G.FarmModuleCmd.GetHarvestIconPath)
      self.Icon_1:SetPath(harvestIconPath)
    else
      self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif optionType == FarmModuleEnum.OptionType.Sowing then
    local equippingSeed = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetEquipSeed)
    if 0 == equippingSeed then
      self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(equippingSeed)
      if plantGrowConf then
        self.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Icon_1:SetPath("Texture2D'/Game/NewRoco/Modules/System/Common/Icon/BagItem/1.1'")
      end
    end
  elseif optionType == FarmModuleEnum.OptionType.Watering then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif optionType == FarmModuleEnum.OptionType.Fertilizing or optionType == FarmModuleEnum.OptionType.None then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_NPCInteractItem_C:OnFarmOptionInfoChange()
  if not self.option then
    return
  end
  if self.option:IsFarmOption() and FarmUtils.GetFarmOptionType(self.option) == FarmModuleEnum.OptionType.Sowing then
    self:RefreshFarmInfo()
    local option = self.option
    local optionConfig = option.config
    local item_conf
    local NPCMapping = _G.NRCModeManager:DoCmd(BagModuleCmd.GetNPCMapping)
    local npcConfig = option.owner.config
    local id = npcConfig.id
    if NPCMapping and NPCMapping[id] then
      item_conf = _G.DataConfigManager:GetBagItemConf(NPCMapping[id])
    end
    local seed_Id = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetEquipSeed)
    if seed_Id then
      item_conf = _G.DataConfigManager:GetBagItemConf(seed_Id)
    end
    self.content = optionConfig.button_text or npcConfig.name
    local contentSize = 22
    if RocoEnv.IS_EDITOR and ShowID then
      self.content = string.format("%s(%d)", self.content, optionConfig.id)
    end
    self.item_quality = 0
    UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, self.isPressed or self.bSelectedAndTouch, contentSize)
    self:SetBackGround(self.isPressed or self.bSelectedAndTouch)
    if optionConfig.button_icon then
      if item_conf then
        self.Icon:SetPath(item_conf.icon)
      elseif optionConfig.button_icon then
        self.Icon:SetPath(optionConfig.button_icon)
        self:PlayShine(optionConfig)
      end
    end
  end
end

function UMG_NPCInteractItem_C:OnDestruct()
  self.ColorAndOpacity.A = 0
end

function UMG_NPCInteractItem_C:SetData(option)
  if option.bFake then
    self:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Hidden)
    return
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.option == option then
    if self.option.NeedsValidation and self.option:NeedsValidation() then
      self:RefreshValidationInfo()
    end
    return
  end
  self.option = option
  self.bSelectedAndTouch = false
  self:SetBackGround(false)
  self:SetHoverBG(false)
  self:ReleaseTouchMark(false)
  self:PlayAnimation(self.In, 0, 1, 0, 1.8)
  LoadingProfiler:CheckPoint(LoadingProfilerCheckPoint.ShowInteractItem)
  _G.NRCEventCenter:UnRegisterEvent(self, RelationTreeEvent.OnPetInfoChangeEvent, self.UpdatePetName)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnFarmOptionInfoChange)
  local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
  if homeModule then
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEquipSeedChange)
    homeModule:UnRegisterEvent(self, HomeModuleEvent.OnEquipFoodChange)
  end
  self.PrevIsHasLuoPan = self.IsHasLuoPan
  self.IsHasLuoPan = false
  if option.bIsPlayerOption then
    self:SetPlayerOptionData(option)
  else
    self:SetNpcOptionData(option)
  end
end

function UMG_NPCInteractItem_C:OnAnimationFinished(Animation)
  if Animation == self.In then
    self.Background_Selected:SetRenderOpacity(1)
  end
end

function UMG_NPCInteractItem_C:SetHoverBG(bShow)
  local NewColor = self.HoverBG.ColorAndOpacity
  NewColor.A = bShow and 1 or 0
  self.HoverBG:SetColorAndOpacity(NewColor)
end

function UMG_NPCInteractItem_C:ClearData()
  if self.option and self.option.NeedsValidation and self.option:NeedsValidation() then
    self.option:RemoveEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionChanged)
  end
  self.option = nil
end

function UMG_NPCInteractItem_C:SetPlayerOptionData(Option)
  self.coin_validation = false
  self.coin_content = ""
  local OptionConfig = Option.config
  self.ItemDesc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local CustomName = Option and Option.custom_params and Option.custom_params.CustomName or ""
  if CustomName and "" ~= CustomName then
    self.content = string.format(OptionConfig.button_text, CustomName)
  else
    self.content = OptionConfig.button_text
  end
  if RocoEnv.IS_EDITOR and ShowID then
    self.content = string.format("%s(%d)", self.content, OptionConfig.id)
  end
  self.item_quality = 1
  local IsYellow = Option and Option.custom_params and Option.custom_params.IsYellow or false
  if IsYellow then
    self.item_quality = 6
  else
    local option_config = self.option and self.option.config
    local option_action = option_config and option_config.action
    local action_type = option_action and option_action.action_type or _G.Enum.ActionType.ACT_NONE
    if action_type == _G.Enum.ActionType.ACT_INTERACTION_CIFU_PREPARE then
      self.item_quality = 6
    end
  end
  local IsYellowBG = Option and Option.custom_params and Option.custom_params.IsYellowBG or false
  if IsYellowBG then
    self.NRCImage_35:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#DC9827FF"))
  else
    self.NRCImage_35:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#3D3D3DFF"))
  end
  UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, false, 22)
  self:SetBackGround(false)
  if OptionConfig.button_icon then
    self.Icon:SetPath(OptionConfig.button_icon)
    self:PlayShine(OptionConfig)
  end
end

function UMG_NPCInteractItem_C:SetNpcOptionData(option)
  self.coin_validation = false
  self.coin_content = ""
  local optionConfig = option.config
  local npcConfig = option.owner.config
  local serverData = option.owner.serverData
  self.NRCImage_35:SetBrushTintColor(UE4.UNRCStatics.HexToSlateColor("#3D3D3DFF"))
  if self.option.NeedsValidation and self.option:NeedsValidation() then
    self.option:AddEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionChanged)
    self:RefreshValidationInfo()
    self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif self.option:IsFarmOption() then
    self:RefreshFarmInfo()
    self.ItemDesc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    _G.DataModelMgr.PlayerDataModel:AddEventListener(self, ENUM_PLAYER_DATA_EVENT.UPDATE_DATA, self.OnFarmOptionInfoChange)
    local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
    if homeModule then
      homeModule:RegisterEvent(self, HomeModuleEvent.OnEquipSeedChange, self.OnFarmOptionInfoChange)
    end
  elseif self.option and self.option.config and self.option.config.npc_interact_type == _G.Enum.InteractType.IT_HOME_PET_FEED then
    local homeModule = _G.NRCModuleManager:GetModule("HomeModule")
    if homeModule then
      homeModule:RegisterEvent(self, HomeModuleEvent.OnEquipFoodChange, self.OnHomeFeedOptionChange)
    end
    self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ItemDesc_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local item_conf
  local NPCMapping = _G.NRCModeManager:DoCmd(BagModuleCmd.GetNPCMapping)
  local id = npcConfig.id
  if NPCMapping and NPCMapping[id] then
    local item_id = NPCMapping[id]
    item_conf = _G.DataConfigManager:GetBagItemConf(item_id)
  end
  if option:IsFarmOption() then
    local farmOptionType = FarmUtils.GetFarmOptionType(option)
    if farmOptionType == FarmModuleEnum.OptionType.Sowing then
      local seed_Id = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetEquipSeed)
      if seed_Id and 0 ~= seed_Id then
        item_conf = _G.DataConfigManager:GetBagItemConf(seed_Id)
      end
    elseif farmOptionType == FarmModuleEnum.OptionType.Harvesting or farmOptionType == FarmModuleEnum.OptionType.Stealing then
      local landInfo = option:GetOwnerFarmlandInfo()
      if landInfo and landInfo.plant_seed_id then
        item_conf = _G.DataConfigManager:GetBagItemConf(landInfo.plant_harvest_id)
      end
    end
  end
  self.item_quality = item_conf and item_conf.item_quality or npcConfig.item_quality or 0
  if option:GetInteractType() == _G.Enum.InteractType.IT_MANUAL_BOND then
    local serverBase = serverData and serverData.base
    local serverName = serverBase and serverBase.name
    self.content = optionConfig.button_text or serverName
    self.item_quality = 7
  elseif option:GetInteractType() == _G.Enum.InteractType.IT_MANUAL then
    optionConfig = option.config
    if optionConfig and optionConfig.id == 150001 then
      local serverBase = serverData and serverData.base
      local serverName = serverBase and serverBase.name
      local Name = string.ExtralongandOmitted(serverName, 9)
      self.content = string.format(optionConfig.button_text, Name)
      _G.NRCEventCenter:RegisterEvent("UMG_NPCInteractItem_C", self, RelationTreeEvent.OnPetInfoChangeEvent, self.UpdatePetName)
    elseif optionConfig and optionConfig.id == 720000012 then
      self.content = optionConfig.button_text
      if option.owner.serverData and option.owner.serverData.attach_item_info then
        local attachInfo = option.owner.serverData.attach_item_info
        if attachInfo.attach_item_type == ProtoEnum.NpcAttachItemType.NAIT_HOME_PET_NEST then
          local furnitureId = attachInfo.attach_item_id
          local petInfo = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, furnitureId)
          if petInfo and petInfo.base and petInfo.base.name then
            self.content = string.format(optionConfig.button_text, petInfo.base.name)
          end
        end
      end
    elseif string.IsNilOrEmpty(optionConfig.button_text) then
      self.content = npcConfig.name
    else
      self.content = optionConfig.button_text
    end
  elseif option:GetInteractType() == _G.Enum.InteractType.IT_HOME_PET_FEED or option:GetInteractType() == _G.Enum.InteractType.IT_HOME_PET_REWARD then
    optionConfig = option.config
    if optionConfig and optionConfig.id == 720000013 or optionConfig.id == 720000016 then
      local serverBase = serverData and serverData.base
      local serverName = serverBase and serverBase.name
      local Name = string.ExtralongandOmitted(serverName, 9)
      self.content = string.format(optionConfig.button_text, Name)
    else
      self.content = optionConfig.button_text
    end
  elseif string.IsNilOrEmpty(optionConfig.button_text) then
    self.content = npcConfig.name
  else
    self.content = optionConfig.button_text
  end
  local contentSize = 22
  if option:IsFarmOption() then
    local farmOptionType = FarmUtils.GetFarmOptionType(option)
    if farmOptionType == FarmModuleEnum.OptionType.Harvesting or farmOptionType == FarmModuleEnum.OptionType.Stealing then
      local landInfo = option:GetOwnerFarmlandInfo()
      if landInfo and landInfo.plant_harvest_num and #self.content > 5 then
        contentSize = 20
      end
    else
      self.item_quality = 0
    end
  end
  if option:IsHomeViewArtOption() then
    local InfoComp = option.owner:GetComponent(HomeNpcInfoComponent)
    local Name = ""
    if InfoComp then
      local PropsData = InfoComp:GetFurnitureData()
      Name = PropsData and PropsData:GetName() or ""
    end
    self.content = string.format(optionConfig.button_text, Name)
  end
  self.RawContent = self.content
  if option:IsHomeSound2dOption() then
    local InfoComp = option.owner:GetComponent(HomeNpcInfoComponent)
    if InfoComp then
      local ActionConf = option:GetActionConf()
      if ActionConf then
        local EventName = ActionConf.action_param1
        local Proxy = InfoComp:EnsureSound2dProxy(EventName)
        if Proxy:IsPlaying() then
          self.content = ActionConf.action_param2
        end
        if not Proxy.OnChanged:Has(self, self.OnRefreshSoundOptionName) then
          Proxy.OnChanged:Add(self, self.OnRefreshSoundOptionName)
        end
      end
    end
  end
  if RocoEnv.IS_EDITOR and ShowID then
    self.content = string.format("%s(%d)", self.content, optionConfig.id)
  end
  UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, false, contentSize)
  if serverData and serverData.miracle_change_info and serverData.npc_base and serverData.npc_base.refresh_src == ProtoEnum.SpaceEnum_NpcRefreshSource.ENUM.NpcInteract_MiracleChange then
    local ballId = serverData.miracle_change_info.ball_cfg_id
    local ballCfg = _G.DataConfigManager:GetBallConf(ballId)
    if not ballCfg then
      return
    end
    self.Icon:SetPath(ballCfg.ball_mini_icon)
    return
  end
  if optionConfig.button_icon then
    if self.option:IsFarmOption() and FarmUtils.GetFarmOptionType(self.option) == FarmModuleEnum.OptionType.Sowing then
      local seed_Id = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetEquipSeed)
      if seed_Id and 0 ~= seed_Id then
        item_conf = _G.DataConfigManager:GetBagItemConf(seed_Id)
      end
      if item_conf then
        self.Icon:SetPath(item_conf.icon)
        return
      end
    end
    if self.option and self.option.config and self.option.config.npc_interact_type == _G.Enum.InteractType.IT_HOME_PET_FEED then
      local itemId, _ = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.OnCmdGetEquipFoodIdAndNum)
      if itemId then
        local foodConf = _G.DataConfigManager:GetBagItemConf(itemId)
        if foodConf and foodConf.big_icon then
          self.Icon:SetPath(foodConf.big_icon)
          return
        end
      end
    end
    if optionConfig.button_icon then
      self.Icon:SetPath(optionConfig.button_icon)
      self:PlayShine(optionConfig)
    end
  elseif item_conf then
    self.Icon:SetPath(item_conf.icon)
  end
end

function UMG_NPCInteractItem_C:OnRefreshSoundOptionName()
  if not self.option then
    return
  end
  local optionConfig = self.option.config
  self.content = self.RawContent
  if self.option:IsHomeSound2dOption() then
    local InfoComp = self.option.owner:GetComponent(HomeNpcInfoComponent)
    if InfoComp then
      local ActionConf = self.option:GetActionConf()
      if ActionConf then
        local EventName = ActionConf.action_param1
        local Proxy = InfoComp:EnsureSound2dProxy(EventName)
        if Proxy:IsPlaying() then
          self.content = ActionConf.action_param2
        else
          self.content = self.RawContent
        end
      end
    end
  end
  if RocoEnv.IS_EDITOR and ShowID then
    self.content = string.format("%s(%d)", self.content, optionConfig.id)
  end
  UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, self.bIsPress, 22)
end

function UMG_NPCInteractItem_C:OnHomeFeedOptionChange(bEquip, itemId, num)
  if bEquip then
    if num and num > 0 and itemId then
      local foodConf = _G.DataConfigManager:GetBagItemConf(itemId)
      if foodConf and foodConf.big_icon then
        self.Icon:SetPath(foodConf.big_icon)
        return
      end
    end
  elseif self.option.config and self.option.config.button_icon then
    self.Icon:SetPath(self.option.config.button_icon)
  end
end

function UMG_NPCInteractItem_C:UpdateDesc2Visibility(option)
  if not option or not option.owner then
    self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  if option.IsFarmOption and option:IsFarmOption() then
    local optionType = FarmUtils.GetFarmOptionType(option)
    if optionType == FarmModuleEnum.OptionType.Harvesting or optionType == FarmModuleEnum.OptionType.Stealing or optionType == FarmModuleEnum.OptionType.Watering then
      self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    elseif optionType == FarmModuleEnum.OptionType.Sowing then
      local equippingSeed = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetEquipSeed)
      if 0 == equippingSeed then
        self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        local plantGrowConf = _G.DataConfigManager:GetPlantGrowConf(equippingSeed)
        if plantGrowConf then
          self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
    elseif optionType == FarmModuleEnum.OptionType.Fertilizing or optionType == FarmModuleEnum.OptionType.None then
      self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_NPCInteractItem_C:UpdateDesc2Content(isPress, option)
  if option and option.IsFarmOption and option:IsFarmOption() then
    local farmOptionType = FarmUtils.GetFarmOptionType(option)
    local descColor = FarmConst.UIColor.Normal
    if isPress then
      descColor = FarmConst.UIColor.Pressed
    end
    local descContent
    if farmOptionType == FarmModuleEnum.OptionType.Watering then
      local landInfo = option:GetOwnerFarmlandInfo()
      if landInfo then
        local wateringReduceTime = FarmUtils.GetWateringReduceTimeCurrent(landInfo.plant_id)
        if wateringReduceTime >= 0 then
          local wateringReduceTimeTxt = FarmUtils.GetTxtByTime(wateringReduceTime)
          if wateringReduceTime and "" == wateringReduceTimeTxt then
            wateringReduceTimeTxt = "1"
          end
          descContent = string.format("-%s", wateringReduceTimeTxt)
        end
      end
    elseif farmOptionType == FarmModuleEnum.OptionType.Harvesting or farmOptionType == FarmModuleEnum.OptionType.Stealing then
      local landInfo = option:GetOwnerFarmlandInfo()
      if landInfo then
        descContent = string.format("%s/%s", landInfo.plant_harvest_num - landInfo.plant_steal_account, landInfo.plant_harvest_num)
        if FarmUtils.IsLandHarvest(landInfo.plant_id) then
          descColor = FarmConst.UIColor.Harvest
        end
      end
    elseif farmOptionType == FarmModuleEnum.OptionType.Sowing then
      local equippingSeed, tabId = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetEquipSeed)
      tabId = tabId or 1
      if 0 ~= equippingSeed then
        local plantGrowConf = DataConfigManager:GetPlantGrowConf(equippingSeed)
        if plantGrowConf then
          local growGrade = plantGrowConf.plant_grow_grade[tabId]
          if not growGrade then
            Log.Debug("UMG_NPCInteractItem_C:UpdateDesc2Content growGrade is nil", equippingSeed, tabId)
            self.ItemDesc_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
          else
            descContent = tostring(growGrade.plant_vitem_value)
            local ownNum = _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.ProtoEnum.VisualItem.VI_COIN) or 0
            if ownNum < growGrade.plant_vitem_value then
              descColor = FarmConst.UIColor.LackCoin
            end
          end
        end
      end
    end
    if descContent and descColor then
      self.ItemDesc_2:SetText(string.format("<span color=\"%s\">%s</>", descColor, descContent))
    end
  end
end

function UMG_NPCInteractItem_C:PlayShine(optionConfig)
  Log.Debug("[NPCInteractMainUI] PlayShine:", optionConfig.button_icon)
  if optionConfig.button_icon == UEPath.LuoPan then
    self.IsHasLuoPan = true
    self:PlayAnimation(self.Shine)
  elseif self.PrevIsHasLuoPan then
    self:PlayAnimation(self.Stop)
    self.IsHasLuoPan = false
    self.PrevIsHasLuoPan = nil
  end
end

function UMG_NPCInteractItem_C:GetFarmLandInfo(Option)
  if not Option then
    return
  end
end

function UMG_NPCInteractItem_C:SetScrollView(scrollView)
  Base.SetScrollView(self, scrollView)
end

function UMG_NPCInteractItem_C:Construct()
  Base.Construct(self)
  self.option = nil
  self.content = ""
  self.item_quality = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_pick_all").num / 1000
  self.LongPressMinTime = _G.DataConfigManager:GetGlobalConfig("long_press_pick_all_display_delay").num / 1000
  self.isPressed = false
end

function UMG_NPCInteractItem_C:Destruct()
  Base.Destruct(self)
  if self.option and self.option.NeedsValidation and self.option:NeedsValidation() then
    self.option:RemoveEventListener(self, NpcOptionEvent.OptionChange, self.OnOptionChanged)
  end
  self.option = nil
end

function UMG_NPCInteractItem_C:IsPCMode()
  return UE.UGameplayStatics.GetGameInstance(self):IsPCMode()
end

function UMG_NPCInteractItem_C:IsMouseCursorShow()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerController = localPlayer:GetUEController()
  return playerController.bShowMouseCursor
end

function UMG_NPCInteractItem_C:LockIsSelectBtnByActionType(actionType)
  local touchReasonType
  local panelName = "LobbyMain"
  local moduleName = "MainUIModule"
  if actionType == ProtoEnum.ActionType.ACT_DIALOG then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).DIALOG
  elseif actionType == ProtoEnum.ActionType.ACT_OPEN_TEAM_BATTLE_UI then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).TEAMBATTLE
  elseif actionType == ProtoEnum.ActionType.ACT_TRIG_MINIGAME then
    touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, panelName).MINIGAME
  end
  if touchReasonType then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetLockOpenSubUI, true)
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, moduleName, panelName, touchReasonType)
  end
end

function UMG_NPCInteractItem_C:UpdatePetName()
  local option = self.option
  local optionConfig = option.config
  if optionConfig and optionConfig.id == 150001 and option.owner then
    local serverData = option.owner.serverData
    local serverBase = serverData and serverData.base
    local serverName = serverBase and serverBase.name
    serverName = string.ExtralongandOmitted(serverName, 9)
    self.content = string.format(optionConfig.button_text, serverName)
    if self:IsPCMode() then
      UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, self.bIsPress, 22)
    else
      UIUtils.SetTextWithQuality(self.ItemDesc, self.content, self.item_quality, false, 22)
      self:SetBackGround(false)
    end
  end
end

function UMG_NPCInteractItem_C:GetOptionID()
  local Option = self.option
  if not Option then
    return "No Option"
  end
  local Conf = Option and Option.config
  if not Conf then
    return string.format("No NPC_OPTION_CONF(%s)", Option.className or "Unknown Option Type")
  end
  local ID = Conf and Conf.id
  return ID and tostring(ID) or "No ID"
end

function UMG_NPCInteractItem_C:CheckIsLock()
  local isSelectBtn = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain")
  if isSelectBtn then
    local lockList = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetLockFlags, "MainUIModule", "LobbyMain")
    local reason = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").THROW
    if lockList and 1 == #lockList and lockList[1] == reason then
      if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
        local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
        if localPlayer then
          localPlayer:AddEventListener(self, PlayerModuleEvent.ON_INTERRUPT_THROW, self.OnThrowInterrupt)
        end
      end
      return false
    else
      return true
    end
  else
    return false
  end
end

return UMG_NPCInteractItem_C
