local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local TipsDisplayExecutor = require("NewRoco.Modules.System.TipsModule.TipsDisplayExecutor")
local UMG_TopHUD_C = _G.NRCPanelBase:Extend("UMG_TopHUD_C")

function UMG_TopHUD_C:OnConstruct()
  self:SetChildViews(self.UMG_ZoneTip, self.UMG_ExpUp, self.UMG_TaskTips_New, self.UMG_Tips, self.UMG_LevelBreakThrough, self.UMG_MagicUnlockTips, self.UMG_CompassUnLockTips, self.UMG_ExpansionTips, self.UMG_CabinExperience, self.UMG_PetCertificationTips)
  self.CatchPetTipsLoader.OnLoadPanelCallbackDelegate:Add(self, self.OnLoadWidgetCallback)
  self.ImportTipsQueue = Queue()
  self.NoImportTipsWaiting = nil
end

function UMG_TopHUD_C:OnActive(...)
  NRCPanelBase.OnActive(self, ...)
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:OnInit()
  self:OnAddEventListener()
  self.tipDisplayExecutor = TipsDisplayExecutor():Attach(self, self.OnPlayTips, nil, self.OnAllTipsFinished, self.OnTipDisplayStatusChangeHandler)
  self.tipDisplayExecutor:StartTipDispatchStateListener()
  self.tipDisplayExecutor:EnableTipSort(function(a, b)
    return a.tipCustomType < b.tipCustomType
  end)
end

function UMG_TopHUD_C:OnDestruct()
  self:OnRemoveEventListener()
end

function UMG_TopHUD_C:OnInit()
  self.IsNotHide = false
  self.TaskTipsShow = false
  self.HUDTipsShow = false
  self.UMG_Tips:SetParent(self)
  self.UMG_TaskTips_New:SetParent(self)
  self.UMG_ZoneTip:SetParent(self)
  self.UMG_ExpUp:SetParent(self)
  self.UMG_CompassUnLockTips:SetParent(self)
  self.UMG_MagicUnlockTips:SetParent(self)
  self.UMG_LevelBreakThrough:SetParent(self)
  if self.UMG_PetCertificationTips then
    self.UMG_PetCertificationTips:SetParent(self)
  end
  if self.UMG_ExpansionTips then
    self.UMG_ExpansionTips:SetParent(self)
  end
  if self.UMG_CabinExperience then
    self.UMG_CabinExperience:SetParent(self)
  end
end

function UMG_TopHUD_C:OnAddEventListener()
  self:RegisterEvent(self, TipsModuleEvent.TopHud_AddTips, self.AddTips)
  self:RegisterEvent(self, TipsModuleEvent.TopHud_ShowTips, self.OnShowTips)
  self:RegisterEvent(self, TipsModuleEvent.TopHud_ClearTipsList, self.ClearTipsList)
  self:RegisterEvent(self, TipsModuleEvent.TopHud_HideTips, self.HideTips)
  self:RegisterEvent(self, TipsModuleEvent.TopHud_HideTargetTips, self.HideTargetTips)
  if HomeIndoorSandbox then
    HomeIndoorSandbox:RegisterEvent(HomeIndoorSandbox.Event.OnExitHomeMap, self, self.OnExitHome)
  end
  _G.NRCEventCenter:RegisterEvent("UMG_TopHud", self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
end

function UMG_TopHUD_C:OnRemoveEventListener()
  _G.NRCEventCenter:UnRegisterEvent(self, MainUIModuleEvent.MAINUICLOSE, self.OnMainUIClose)
end

function UMG_TopHUD_C:TryCollapsed()
  self.TipsContent = nil
  if self.tipDisplayExecutor then
    self.tipDisplayExecutor:Resume("Tips_Show")
  end
end

function UMG_TopHUD_C:OnMainUIClose()
  if string.IsNilOrEmpty(self.TipsContent) then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_TopHUD_C:AddTips(tip)
  if tip.tipCustomType == TipEnum.TopHudTipsType.TaskTips then
    local hasTaskTips = false
    self.tipDisplayExecutor:TraverseCacheData(function(_, _tip)
      if _tip.tipCustomType == TipEnum.TopHudTipsType.TaskTips then
        hasTaskTips = true
        return true
      end
    end)
    if hasTaskTips then
      return
    end
  end
  self.tipDisplayExecutor:AddDisplayTip(tip)
end

function UMG_TopHUD_C:OnPlayTips(tip)
  self:StopAllAnim()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.TipsContent = nil
  if tip.tipCustomType == TipEnum.TopHudTipsType.ZoneTips then
    local ZoneData = tip.customData
    self.UMG_ZoneTip:OnShowZoneTip(ZoneData.zoneId, ZoneData.action)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.ActivityTips then
    self.UMG_ZoneTip:OnShowActivityZoneTip(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.EnterHomeZoneTips then
    self.UMG_ZoneTip:OnShowEnterHomeZoneTip()
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.ExpTips then
    self.UMG_ExpUp:SetExpUpInfo(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.HomeAddExpTips then
    self.UMG_CabinExperience:SetExpUpInfo(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.BreakThroughTips then
    self.UMG_LevelBreakThrough:OnActive(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.FunUnlockTips then
    local UnlockId = tip.customData
    local UIEnterData = _G.DataConfigManager:GetUiEnterBanConf(UnlockId)
    if UnlockId == _G.Enum.FunctionEntrance.FE_PVP then
      self:DelaySeconds(3.0, self.ShowUnlockUI, self, UIEnterData)
    else
      self:ShowUnlockUI(UIEnterData)
    end
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.MagicTips then
    self.UMG_MagicUnlockTips:UpdateTipInfo(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.TaskTips then
    self.UMG_TaskTips_New:ConsumeTips(tip)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.HomeRoomExpandTips then
    self.UMG_ExpansionTips:Show(tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.CatchPetTips then
    self:LoaderCatchTips(tip.customData.umgName, tip.customData)
  elseif tip.tipCustomType == TipEnum.TopHudTipsType.PetCertification then
    self.UMG_PetCertificationTips:Show(tip.customData)
  end
end

function UMG_TopHUD_C:OnAllTipsFinished()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if not self.IsNotHide and self.TipsContent ~= LuaText.worldcombat_tips_3 and self.TipsContent ~= LuaText.pvp_fight_exit_desc then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  _G.NRCEventCenter:DispatchEvent(TaskModuleEvent.TipsPerformFinished)
end

function UMG_TopHUD_C:OnExitHome()
  self.tipDisplayExecutor:StopQueuedTips(function(Tip)
    return Tip.tipCustomType == TipEnum.TopHudTipsType.EnterHomeZoneTips
  end)
  self.UMG_ZoneTip:StopAllAnimations()
end

function UMG_TopHUD_C:OnTipDisplayStatusChangeHandler(pause)
  if pause then
    local tip = self.tipDisplayExecutor:GetDisplayingTip()
    if tip then
      local tipUmg
      if tip.tipCustomType == TipEnum.TopHudTipsType.ZoneTips or tip.tipCustomType == TipEnum.TopHudTipsType.EnterHomeZoneTips then
        tipUmg = self.UMG_ZoneTip
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.ExpTips then
        tipUmg = self.UMG_ExpUp
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.BreakThroughTips then
        tipUmg = self.UMG_LevelBreakThrough
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.FunUnlockTips then
        tipUmg = self.UMG_CompassUnLockTips
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.MagicTips then
        tipUmg = self.UMG_MagicUnlockTips
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.TaskTips then
        tipUmg = self.UMG_TaskTips_New
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.HomeAddExpTips then
        tipUmg = self.UMG_CabinExperience
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.HomeRoomExpandTips then
        tipUmg = self.UMG_ExpansionTips
      elseif tip.tipCustomType == TipEnum.TopHudTipsType.PetCertification then
        tipUmg = self.UMG_PetCertificationTips
      end
      if tipUmg then
        local desireRecoverable = not self.tipDisplayExecutor:IsPausedExcept("Tips_Show")
        local handled = false
        if tipUmg.SetPaused then
          handled = tipUmg:SetPaused(true, desireRecoverable)
          self.curCollapsedTipUmg = tipUmg
        end
        if not handled then
          if not desireRecoverable then
            tipUmg:StopAllAnimations()
          else
            tipUmg:SetVisibility(UE4.ESlateVisibility.Collapsed)
            self.curCollapsedTipUmg = tipUmg
          end
        end
      end
    end
  else
    local curCollapsedTipUmg = self.curCollapsedTipUmg
    if curCollapsedTipUmg then
      local handled = false
      if curCollapsedTipUmg.SetPaused then
        handled = curCollapsedTipUmg:SetPaused(false)
      end
      if not handled then
        if curCollapsedTipUmg:IsPlayingAnimation() then
          curCollapsedTipUmg:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.tipDisplayExecutor:ConsumeNextTip()
        end
      end
      self.curCollapsedTipUmg = nil
    end
  end
end

function UMG_TopHUD_C:OnShowTips(content, delay, Color, showTime, isNotHide, bAsImportTips)
  self.NoImportTipsWaiting = nil
  local bPlayingTips = self.HUDTipsShow
  if not bPlayingTips then
    self:InternalShowTips(content, delay, Color, showTime, isNotHide, bAsImportTips)
  elseif self.bAsImportTips then
    local TipsPack = table.pack(content, delay, Color, showTime, isNotHide, bAsImportTips)
    if bAsImportTips then
      self.ImportTipsQueue:Enqueue(TipsPack)
    else
      self.NoImportTipsWaiting = TipsPack
    end
  else
    self:InternalShowTips(content, delay, Color, showTime, isNotHide, bAsImportTips)
  end
end

function UMG_TopHUD_C:ConditionalQueueShowTips()
  local bPlayingTips = self.HUDTipsShow
  local bCanPlayTips = true
  if not bPlayingTips and bCanPlayTips then
    local TipsPack
    if self.ImportTipsQueue:Size() > 0 then
      TipsPack = self.ImportTipsQueue:Dequeue()
    elseif self.NoImportTipsWaiting then
      TipsPack = self.NoImportTipsWaiting
      self.NoImportTipsWaiting = nil
    end
    if TipsPack then
      self:InternalShowTips(table.unpack(TipsPack, 1, TipsPack.n))
    end
  end
end

function UMG_TopHUD_C:InternalShowTips(content, delay, Color, showTime, isNotHide, bAsImportTips)
  if string.IsNilOrEmpty(content) then
    Log.Error("\229\188\185\229\135\186\228\186\134\231\169\186\231\153\189tips\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129\239\188\129", content)
  end
  self.IsNotHide = isNotHide
  self.TipsContent = content
  self.bAsImportTips = bAsImportTips
  self.UMG_Tips:SetContent(content, delay, Color, showTime)
  if self.tipDisplayExecutor and not string.IsNilOrEmpty(content) then
    self.tipDisplayExecutor:Pause("Tips_Show")
  end
end

function UMG_TopHUD_C:HideTips()
  self.NoImportTipsWaiting = nil
  self.ImportTipsQueue:Clear()
  self.UMG_Tips:HideTips()
end

function UMG_TopHUD_C:HideTargetTips(target)
  for _, content in pairs(target) do
    if self.TipsContent == content then
      self.TipsContent = nil
      self:HideTips()
      return
    end
  end
end

function UMG_TopHUD_C:ShowUnlockUI(UIEnterData)
  self.UMG_CompassUnLockTips:DoShow({
    name = UIEnterData.func_name,
    icon = UIEnterData.img_path
  })
end

function UMG_TopHUD_C:PlayCutSceneEnter()
end

function UMG_TopHUD_C:CutSceneFinish()
end

function UMG_TopHUD_C:ConsumeNext()
  self.tipDisplayExecutor:ConsumeNextTip()
end

function UMG_TopHUD_C:IsPaused()
  return self.tipDisplayExecutor:IsPaused()
end

function UMG_TopHUD_C:StopAllAnim()
  self:StopAllAnimations()
  self.UMG_Tips:StopAllAnimations()
  self.UMG_LevelBreakThrough:StopAllAnimations()
  self.UMG_MagicUnlockTips:StopAllAnimations()
  self.UMG_TaskTips_New:StopAllAnimations()
  self.UMG_ExpUp:StopAllAnimations()
  self.UMG_ZoneTip:StopAllAnimations()
  self.UMG_CompassUnLockTips:StopAllAnimations()
end

function UMG_TopHUD_C:ClearTipsList()
  self.tipDisplayExecutor:Clear()
end

function UMG_TopHUD_C:LoaderCatchTips(name, arg)
  self.CatchPetTipsLoader:UnLoadPanel(true)
  local widgetClass = string.format("WidgetBlueprint'/Game/NewRoco/Modules/System/TipsModule/Res/Tips/Season_BonusCatch/%s.%s'", name, string.format("%s_C", name))
  local softClassPath = UE4.UKismetSystemLibrary.MakeSoftClassPath(widgetClass)
  self.CatchPetTipsLoader:SetWidgetClass(softClassPath)
  self.CatchPetTipsLoader:LoadPanel(self, arg)
end

function UMG_TopHUD_C:OnLoadWidgetCallback(widget)
  if widget then
    local panel = self.CatchPetTipsLoader:GetPanel()
    panel:SetParent(self)
  end
end

return UMG_TopHUD_C
