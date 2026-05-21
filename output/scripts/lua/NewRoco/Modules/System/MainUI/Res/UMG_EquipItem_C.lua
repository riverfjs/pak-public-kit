local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_EquipItem_C = _G.NRCPanelBase:Extend("UMG_EquipItem_C")

function UMG_EquipItem_C:OnConstruct()
  self.uiData = {}
  self.selected = false
  self.vector2DZero = UE4.FVector2D(0, 0)
  self.Deviation = {X = 60, Y = 40}
  self.screenPos = nil
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.LongPressTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn_show").num / 1000
  self.EndTime = _G.DataConfigManager:GetGlobalConfig("long_press_lobby_btn").num / 1000
  self.hasPlaySelectAnim = false
  _G.UpdateManager:UnRegister(self)
  self:AddEventListener()
  local conf = _G.DataConfigManager:GetGlobalConfig("outside_catch_trigger")
  self.bOutsideCatchOpen = conf and 1 == conf.num or false
  if not self.bOutsideCatchOpen then
    self:CheckEquipItemShow(false, true)
  end
  self:SetProgressPos()
end

function UMG_EquipItem_C:OnDestruct()
  self.BallBtn.OnPressed:Remove(self, self.OnBtnPressed)
  self.BallBtn.OnReleased:Remove(self, self.OnBtnReleased)
end

function UMG_EquipItem_C:AddEventListener()
  self.BallBtn.OnPressed:Add(self, self.OnBtnPressed)
  self.BallBtn.OnReleased:Add(self, self.OnBtnReleased)
end

function UMG_EquipItem_C:OnDisable()
  self:OnBtnReleased()
end

function UMG_EquipItem_C:OnBtnPressed()
  local mainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if mainUIModule and mainUIModule:HasPanel("SimpleUseList") then
    local panel = mainUIModule:GetPanel("SimpleUseList")
    if panel and panel.enableView then
      return
    end
  end
  self.IsOnClick = true
  self:OnBallBtnPressed()
  _G.UpdateManager:Register(self)
end

function UMG_EquipItem_C:OnBtnReleased()
  self:LongPressBreak()
end

function UMG_EquipItem_C:OnMouseLeave(MouseEvent)
  self:LongPressBreak()
end

function UMG_EquipItem_C:SetEquipItem(curEquipitem, bSetThrow)
  if curEquipitem and curEquipitem.type == Enum.BagItemType.BI_PET_BALL and not self.bOutsideCatchOpen then
    curEquipitem = nil
  end
  self.uiData = curEquipitem
  local hide = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
  if hide then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ChangeAbilitySlotTrowBallState, false)
    self:CheckEquipItemShow(false)
    self.EquipItem:SetPath("")
    self.EquipItemNum:SetText("")
  elseif nil == curEquipitem then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ChangeAbilitySlotTrowBallState, false)
    self:CheckEquipItemShow(false)
    self.EquipItem:SetPath("")
    self.EquipItemNum:SetText("")
  elseif curEquipitem.id then
    self:CheckEquipItemShow(true)
  else
    self:CheckEquipItemShow(false)
  end
  local selectedGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if 0 == selectedGid and bSetThrow then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.ITEM, self.uiData)
  end
  if not PetUtils.IsHavePet then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.ITEM, self.uiData)
  end
end

function UMG_EquipItem_C:OnBallItemClicked()
end

function UMG_EquipItem_C:OnTick(InDeltaTime)
  if self.IsOnClick then
    self.StartPressTime = self.StartPressTime + InDeltaTime
  end
  if self.StartPressTime >= self.LongPressTime then
    self.StartPressTime = 0
    self.IsLongPress = true
  end
  if self.IsLongPress then
    if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
      self:LongPressBreak()
      return
    end
    self.StartTime = self.StartTime + InDeltaTime
    if self.IsOnClick then
      _G.NRCAudioManager:PlaySound2DAuto(1377, "UMG_EquipItem_C:Tick")
      self.IsOnClick = false
    end
    self.Progress:showAni(self.ScreenPos, self.StartTime, self.EndTime)
    if self.StartTime >= self.EndTime then
      self:OnBallBtnLongPressed()
      self:LongPressBreak()
    end
  end
end

function UMG_EquipItem_C:LongPressBreak()
  self.IsOnClick = false
  self.IsLongPress = false
  self.StartTime = 0
  self.StartPressTime = 0
  self.Progress:showEndAni()
  _G.UpdateManager:UnRegister(self)
end

function UMG_EquipItem_C:ShowSelected(show)
  if show then
    if not self.selected then
      self.selected = true
      if self.uiData and self.uiData.id then
        self:PlaySelectedAnim()
      else
        self:StopAllAnimations()
        self:PlayAnimation(self.change2)
      end
    end
  elseif self.selected then
    self:StopAllAnimations()
    self:PlayAnimation(self.change2)
    self.selected = false
  end
end

function UMG_EquipItem_C:OnBallBtnLongPressed()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1304, "UMG_EquipItem_C:OnBallBtnLongPressed")
  _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetSimpleUseListByType, _G.Enum.BagItemType.BI_PET_BALL)
  self:InPutClose()
end

function UMG_EquipItem_C:OnBallBtnPressed()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) and not player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC) then
    if self.uiData then
      self:ShowSelected(true)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_SetThrowItem, _G.MainUIModuleEnum.MainUIChooseType.ITEM, self.uiData)
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.UI_RefreshMainPetSelectedState, 0)
    else
      self:ShowSelected(false)
    end
  end
end

function UMG_EquipItem_C:OnAnimationFinished(anim)
  if anim == self.change1 then
  end
end

function UMG_EquipItem_C:InPutClose()
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
end

function UMG_EquipItem_C:SetProgressPos()
  local Pos
  if UE4Helper.IsPCMode() then
    Pos = UE4.FVector2D(-117, 0)
  else
    Pos = UE4.FVector2D(0, -117)
  end
  self.Progress.Slot:SetPosition(Pos)
end

function UMG_EquipItem_C:ShowEquipItem(showEnum)
  if showEnum ~= UE4.ESlateVisibility.Collapsed and showEnum ~= UE4.ESlateVisibility.Hidden then
    local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
    if isBan then
      self:SetVisibility(UE4.ESlateVisibility.Collapsed)
      if not _G.UE4Helper.IsPCMode() then
        self.Text_PCKey:SetKeyVisibility(false)
      elseif self.FoundationPCKey then
        self.FoundationPCKey:SetKeyVisibility(false)
      end
    else
      self:SetVisibility(UE4.ESlateVisibility.Visible)
      if not _G.UE4Helper.IsPCMode() then
        self.Text_PCKey:SetKeyVisibility(true)
      elseif self.FoundationPCKey then
        self.FoundationPCKey:SetKeyVisibility(true)
      end
      self:SetEquipItemInfo()
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not _G.UE4Helper.IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    elseif self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
  end
end

function UMG_EquipItem_C:CheckEquipItemShow(show, limit)
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionHide, _G.Enum.FunctionEntrance.FE_CATCH_IN_WORLD)
  if isBan or limit then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if not _G.UE4Helper.IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(false)
    elseif self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(false)
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
    if not _G.UE4Helper.IsPCMode() then
      self.Text_PCKey:SetKeyVisibility(true)
    elseif self.FoundationPCKey then
      self.FoundationPCKey:SetKeyVisibility(true)
    end
    if show then
      if self.selected and not self.hasPlaySelectAnim then
        self:PlaySelectedAnim()
      end
      self:SetEquipItemInfo()
      self.EquipItem:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Kong:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Kong:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.EquipItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_EquipItem_C:SetEquipItemInfo()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  local curEquipitem = self.uiData
  if curEquipitem and curEquipitem.id then
    local itemConf = _G.DataConfigManager:GetBallConf(curEquipitem.id)
    self.EquipItem:SetPath(itemConf.ball_icon)
    local showNumStr = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetBallOrMagicShowCountText, curEquipitem.num, _G.Enum.BagItemType.BI_PET_BALL)
    self.EquipItemNum:SetText(showNumStr)
    if curEquipitem.num > 0 then
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ChangeAbilitySlotTrowBallState, true, false)
      self.EquipItemNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#f4eee1ff"))
    else
      _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ChangeAbilitySlotTrowBallState, true, true)
      self.EquipItemNum:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("#c7494aff"))
    end
  else
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.ChangeAbilitySlotTrowBallState, false)
    self.EquipItem:SetPath("")
    self.EquipItemNum:SetText("")
  end
end

function UMG_EquipItem_C:PlaySelectedAnim()
  if not self.hasPlaySelectAnim then
    self.hasPlaySelectAnim = true
  end
  local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  self:StopAllAnimations()
  if 0 ~= curSelectedPetGid then
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1115, "UMG_EquipItem_C:ShowSelected")
    self:PlayAnimation(self.change1)
  else
    self:PlayAnimation(self.select)
  end
end

return UMG_EquipItem_C
