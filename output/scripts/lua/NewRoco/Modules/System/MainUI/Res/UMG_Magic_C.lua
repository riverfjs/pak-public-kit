local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local UMG_Magic_C = _G.NRCPanelBase:Extend("UMG_Magic_C")

function UMG_Magic_C:OnActive()
end

function UMG_Magic_C:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBagChange)
  _G.NRCEventCenter:UnRegisterEvent(self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
end

function UMG_Magic_C:OnDisable()
  self:OnBtnReleased()
end

function UMG_Magic_C:OnAddEventListener()
  self.MagicBtn.OnPressed:Add(self, self.OnBtnPressed)
  self.MagicBtn.OnReleased:Add(self, self.OnBtnReleased)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.MainUIModuleEvent.SetBagChangeInfoEvent, self.OnBagChange)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MagicReplayModuleEvent.UpdateBagItemNumMagicReplayVideo, self.UpdateBagItemNumMagicReplayVideo)
end

function UMG_Magic_C:OnConstruct()
  self.RegisteredTick = false
  self.MagicBtn.LongPressTriggerTime = 0.8
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.Deviation = {X = 60, Y = 40}
  self.screenPos = nil
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.EndTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self.bIsMoving = false
  self.bIsCastingMagic = false
  self.bIsThrowingBall = false
  self.IsSelected = false
  self.bIsCurrentBannedOrNoMaterial = false
  self:OnAddEventListener()
  self.uiData = nil
  self.uiData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
  self.abilityHelper = nil
  self.magicBaseConf = nil
  self.currentCornerIconPath = ""
  self:SetProgressPos()
  _G.UpdateManager:Register(self)
end

function UMG_Magic_C:OnDestruct()
  _G.UpdateManager:UnRegister(self)
end

function UMG_Magic_C:OnMagicBtnClick()
end

function UMG_Magic_C:OnBtnPressed()
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if mainUIModule and mainUIModule:HasPanel("SimpleUseList") then
    local panel = mainUIModule:GetPanel("SimpleUseList")
    if panel and panel.enableView then
      return
    end
  end
  _G.NRCModeManager:DoCmd(MainUIModuleCmd.ResetMainPetProgress)
  if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
    return
  end
  self.IsOnClick = true
  self:OnMagicBtnPressed()
end

function UMG_Magic_C:OnBtnReleased()
  self:LongPressBreak()
end

function UMG_Magic_C:OnMouseLeave(MouseEvent)
  self:LongPressBreak()
end

function UMG_Magic_C:LongPressBreak()
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.Progress:showEndAni()
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAGIC
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
end

function UMG_Magic_C:OnTick(InDeltaTime)
  if self.abilityHelper and self.magicBaseConf then
    local bShowCorner, iconPath = self:_ShouldShowCornerIconFromAbilityHelper()
    self.currentCornerIconPath = iconPath
    self:_ChangeIconState(bShowCorner, iconPath, self.bShowNumber)
  end
  if self.IsOnClick then
    self.StartPressTime = self.StartPressTime + InDeltaTime
  end
  if self.StartPressTime >= self.LongPressTime then
    self.StartPressTime = 0
    if _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetIsSelectBtn, "MainUIModule", "LobbyMain") then
      return
    end
    local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "LobbyMain").MAGIC
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "MainUIModule", "LobbyMain", touchReasonType)
    self.IsLongPress = true
  end
  if self.IsLongPress then
    self.StartTime = self.StartTime + InDeltaTime
    if self.IsOnClick then
      _G.NRCAudioManager:PlaySound2DAuto(1377, "UMG_EquipItem_C:Tick")
      self.IsOnClick = false
    end
    if _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerIsAiming) then
      self:LongPressBreak()
      return
    end
    self.Progress:showAni(self.ScreenPos, self.StartTime, self.EndTime)
    if self.StartTime >= self.EndTime then
      self:OnMagicBtnLongPressed()
      self:LongPressBreak()
    end
  end
end

function UMG_Magic_C:ShowMagicPanel()
  local hasMagic = _G.NRCModeManager:DoCmd(_G.BagModuleCmd.CheckHasBagItemByType, Enum.BagItemType.BI_MAGIC)
  Log.Debug(hasMagic, "ShowMagicPanel")
  if not hasMagic then
    self.MagicBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.MagicBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.CanvasPanel_94:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Magic_C:OnMagicBtnLongPressed()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UnLockOpenSubUiEvent)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(40008024, "UMG_Magic_C:OnMagicBtnLongPressed")
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListByType, _G.Enum.BagItemType.BI_MAGIC)
  self:InPutClose()
end

function UMG_Magic_C:OnMagicBtnPressed()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401003, "UMG_Magic_C:OnMagicBtnPressed")
    self.uiData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
    if self.uiData ~= nil then
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, self.uiData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
    else
      self:ShowSelected(false)
    end
  end
end

function UMG_Magic_C:ShowSelected(show)
  local IsFirstAcquisitionMagic = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetIsFirstAcquisitionMagic)
  Log.Debug("[MAGIC] ShowSelected", show, IsFirstAcquisitionMagic)
  local NewData = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
  local OldData = self.uiData
  local bChanged = not NewData or not OldData or NewData.id ~= OldData.id
  if bChanged then
    self:SetMagicInfo(NewData, false)
  end
  if show then
    if not self.IsSelected then
      self.IsSelected = true
      self:StopAllAnimations()
      local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
      if -1 ~= curSelectedPetGid then
        if IsFirstAcquisitionMagic then
          self:PlayAnimation(self.Appear)
          _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
        else
          self:PlayAnimation(self.change1)
        end
      elseif IsFirstAcquisitionMagic then
        self:PlayAnimation(self.Appear)
      else
        self:PlayAnimation(self.select)
      end
    end
  elseif self.IsSelected then
    self.IsSelected = false
    self:StopAllAnimations()
    self:PlayAnimation(self.change2)
  end
end

function UMG_Magic_C:SetMagicInfo(curEquipMagicInfo, bSetThrow)
  if not self.RegisteredTick then
    self.RegisteredTick = true
  end
  Log.Debug("[MAGIC] SetMagicInfo", curEquipMagicInfo and curEquipMagicInfo.id, bSetThrow)
  self.uiData = curEquipMagicInfo
  self:ShowMagicPanel()
  if self.uiData == nil or type(self.uiData) == "boolean" then
    if type(self.uiData) == "boolean" then
      Log.Error("\230\159\165\231\156\139\228\184\186\228\187\128\228\185\136uiData\228\184\186boolean\231\177\187\229\158\139")
    end
    self.Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Magic:SetPath("")
    self.MagicItemNum:SetText("")
    if not _G.UE4Helper.IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    elseif self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
  elseif self.uiData.id and self.uiData.num > 0 then
    self.Magic:SetVisibility(UE4.ESlateVisibility.Visible)
    local pcKey = self.Text_PCKey
    if not _G.UE4Helper.IsPCMode() then
      pcKey = self.Text_PCKey
    elseif self.FoundationPCKey then
      pcKey = self.FoundationPCKey
    end
    if SystemSettingModuleCmd then
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_MagicSelectStart")
      if "" ~= image then
        pcKey:SetImageMode(image)
      else
        pcKey:SetText(text)
      end
    end
    local itemConf = _G.DataConfigManager:GetBagItemConf(self.uiData.id)
    if itemConf then
      self.MagicItemNum:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Magic:SetPath(itemConf.TUIbutton_icon)
      local bShouldShowCorner, iconPath, bShowNumber = self:_ShouldShowCornerIcon(itemConf)
      self.currentCornerIconPath = iconPath
      self:_ChangeIconState(bShouldShowCorner, iconPath, bShowNumber)
    end
  else
    self.Magic:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SelectedAnim:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Magic:SetPath("")
    self.MagicItemNum:SetText("")
    if not _G.UE4Helper.IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    elseif self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
  end
  if self.uiData and bSetThrow then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.MAGIC, self.uiData)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, -1)
  end
end

function UMG_Magic_C:OnAnimationFinished(Animation)
  if Animation == self.Appear then
    _G.NRCModuleManager:DoCmd(BagModuleCmd.SetIsFirstAcquisitionMagic, false)
    self:PlayAnimation(self.select)
  end
end

function UMG_Magic_C:InPutClose()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil == localPlayer then
    Log.Error("UMG_Magic_C:InPutClose Local player is not found")
    return
  end
end

function UMG_Magic_C:SetProgressPos()
  local Pos
  if UE4Helper.IsPCMode() then
    Pos = UE4.FVector2D(-117, 0)
  else
    Pos = UE4.FVector2D(0, -117)
  end
  self.Progress.Slot:SetPosition(Pos)
end

function UMG_Magic_C:_ShouldShowCornerIcon(bagItemConf)
  if not bagItemConf then
    return false
  end
  if bagItemConf.type == _G.Enum.BagItemType.BI_PET_BALL then
    return false
  end
  if bagItemConf.type == _G.Enum.BagItemType.BI_MAGIC then
    self.magicBaseConf = _G.DataConfigManager:GetMagicBaseConf(bagItemConf.magic_id)
    if not self.magicBaseConf then
      return false
    end
    self.abilityHelper = AbilityHelperManager.GetHelper(self.magicBaseConf.sceneability)
    if not self.abilityHelper then
      return false
    end
    self.abilityHelper:InitFromConf(bagItemConf.id, bagItemConf.magic_id, self.magicBaseConf.sceneability)
    local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local bIsBlock, MyAbilityErrorCode = self.abilityHelper:IsBlock(localPlayer)
    self.bShowNumber = false
    local costItemId = self.magicBaseConf.cost_bag_item[1]
    local costNum = self.magicBaseConf.cost_bag_item[2]
    if nil == costItemId then
      costNum = -1
      self.bShowNumber = false
    else
      self.bShowNumber = true
      local costBagItemConf = _G.DataConfigManager:GetBagItemConf(costItemId, true)
      if costBagItemConf and costNum > 0 and 0 ~= costBagItemConf.show_quantity then
        local OwnedNum = 0
        local ownedItemData = _G.NRCModuleManager:DoCmd(_G.BagModuleCmd.GetBagItemByID, costItemId)
        if ownedItemData and ownedItemData.num then
          OwnedNum = ownedItemData.num
        end
        local itemNum = math.floor(OwnedNum / costNum)
        if itemNum > 0 then
          self.MagicItemNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1ff"))
        else
          self.MagicItemNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#c7494aff"))
        end
        local showNumStr = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetBallOrMagicShowCountText, itemNum, _G.Enum.BagItemType.BI_MAGIC)
        self.MagicItemNum:SetText(showNumStr)
        local isBan = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ExceptMyAbilityErrorCode, MyAbilityErrorCode)
        if not bIsBlock or bIsBlock and not isBan then
          self.MagicItemNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          return false
        end
      end
    end
    if bIsBlock then
      local isBan = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ExceptMyAbilityErrorCode, MyAbilityErrorCode)
      if isBan then
        return true, "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_Forbidden_png.img_Forbidden_png'", self.bShowNumber
      end
    end
  end
  return false
end

function UMG_Magic_C:_ShouldShowCornerIconFromAbilityHelper()
  if not self.abilityHelper or not self.magicBaseConf then
    return false
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not localPlayer then
    return false
  end
  local bIsBlock, MyAbilityErrorCode = self.abilityHelper:IsBlock(localPlayer)
  local isBan = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ExceptMyAbilityErrorCode, MyAbilityErrorCode)
  if bIsBlock and isBan then
    return true, "PaperSprite'/Game/NewRoco/Modules/System/MainUI/Raw/Atlas/MainUI/Frames/img_Forbidden_png.img_Forbidden_png'"
  end
  return false
end

function UMG_Magic_C:_ChangeIconState(bShouldShowCorner, iconPath, bShowNum)
  if bShouldShowCorner then
    if not self.bIsCurrentBannedOrNoMaterial then
      self.CornerMark:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Show_change, 0)
      self:StopAnimation(self.Show_change)
      self.MagicItemNum:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if iconPath and "" ~= iconPath then
        self.CornerMark:SetPath(iconPath)
      end
      self.bIsCurrentBannedOrNoMaterial = true
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.MagicBanStateChanged)
    end
  elseif not bShouldShowCorner then
    if self.bIsCurrentBannedOrNoMaterial then
      if bShowNum then
        self.MagicItemNum:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      self.CornerMark:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if self.bIsCurrentBannedOrNoMaterial and not self.bIsMoving and not self.bIsCastingMagic and not self.bIsThrowingBall then
        self:StopAnimation(self.Show_change)
        self:PlayAnimation(self.Show_change)
      end
    end
    self.bIsMoving = false
    self.bIsCastingMagic = false
    self.bIsThrowingBall = false
    if self.bIsCurrentBannedOrNoMaterial then
      _G.NRCEventCenter:DispatchEvent(_G.MainUIModuleEvent.MagicBanStateChanged)
    end
    self.bIsCurrentBannedOrNoMaterial = false
  end
end

function UMG_Magic_C:OnBagChange(GoodsChangeItems)
  if GoodsChangeItems then
    if self.targetItemID == nil then
      local numList = _G.DataConfigManager:GetGlobalConfig("mark_video_item_demand").numList
      if 2 == #numList then
        self.targetItemID = numList[1]
      end
    end
    local watchIDs = {}
    if self.targetItemID then
      watchIDs[self.targetItemID] = true
    end
    if self.uiData and self.uiData.id then
      watchIDs[self.uiData.id] = true
    end
    if self.magicBaseConf and self.magicBaseConf.cost_bag_item and self.magicBaseConf.cost_bag_item[1] then
      watchIDs[self.magicBaseConf.cost_bag_item[1]] = true
    end
    for _, v in ipairs(GoodsChangeItems) do
      if v.bag_item and watchIDs[v.bag_item.id] then
        self:RefreshMagicInfo()
        break
      end
    end
  end
end

function UMG_Magic_C:UpdateBagItemNumMagicReplayVideo()
  self:RefreshMagicInfo()
end

function UMG_Magic_C:RefreshMagicInfo()
  local BagModuleCmd = require("NewRoco.Modules.System.Bag.BagModuleCmd")
  local curEquipMagicInfo = _G.NRCModuleManager:DoCmd(BagModuleCmd.GetEquipMagicInfo)
  self:SetMagicInfo(curEquipMagicInfo, false)
end

return UMG_Magic_C
