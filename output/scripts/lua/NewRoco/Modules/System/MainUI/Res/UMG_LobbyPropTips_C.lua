require("UnLuaEx")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local TipsModuleEvent = require("NewRoco.Modules.System.TipsModule.TipsModuleEvent")
local TipsDisplayExecutor = require("NewRoco.Modules.System.TipsModule.TipsDisplayExecutor")
local MainUIModuleEnum = require("NewRoco.Modules.System.MainUI.MainUIModuleEnum")
local UMG_LobbyPropTips_C = _G.NRCViewBase:Extend("UMG_LobbyPropTips_C")

function UMG_LobbyPropTips_C:OnConstruct()
  self:SetChildViews(self.NewPropTips, self.Hint)
  self.Hint.IsIn = false
  self.PropTipsList = {}
  self.TipsWidgets = {}
  self.BurnTime = 0
  self.CanvasPanel_title:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.MaxTipsCount = self.TipsContainer:GetChildrenCount()
  for i = 0, self.MaxTipsCount - 1 do
    local tips = self.TipsContainer:GetChildAt(i)
    table.insert(self.TipsWidgets, tips)
    self.NewPropTips:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    tips:SetVisibility(UE4.ESlateVisibility.Collapsed)
    tips:OnConstruct()
  end
  self.allList = {}
  self.useList = {}
  self.newTipsShow = false
  self.waiteTime = 0
  self.IsPlayerExp = false
  self.movdis = 54
  self.moveSpeed = self.movdis / 0.3
  self.ItemHeight = 54
  self.CanvasTitleSizeY = 45
  self.isQuan = false
  self.isMove = false
  self.waiteTimeHide = 0
  self.isShow = false
  self.DisableFlag = 0
  self.MaxShowTipsCount = 0
  self.NeedRemoveTip = {}
  self:SetShowCollapse()
  self.tipDisplayExecutor = TipsDisplayExecutor():Attach(self, nil, nil, nil, self.OnTipDisplayStatusChangeHandler)
  self.tipDisplayExecutor:StartTipDispatchStateListener()
end

function UMG_LobbyPropTips_C:OnDestruct()
  table.clear(self.PropTipsList)
  self.PropTipsList = nil
  table.clear(self.TipsWidgets)
  table.clear(self.NeedRemoveTip)
  self.TipsWidgets = nil
end

function UMG_LobbyPropTips_C:OnTipDisplayStatusChangeHandler(pause)
  self:SetTipsEnabled(not pause, MainUIModuleEnum.RewardTipsDisableReason.System)
end

function UMG_LobbyPropTips_C:PlayTips(tip)
  Log.DebugFormat("UMG_LobbyPropTips_C %s tip=%s", "PlayTips", tip)
  self:RemoveTip(tip)
  local tipList = {}
  table.insert(tipList, tip)
  self:ItemSort(tipList)
  local list = {}
  list.newTips = {}
  list.tipList = {}
  for _, v in ipairs(tipList) do
    if not v:IsBattlePassIgnored() and v.type ~= ProtoEnum.GoodsType.GT_CDKEY then
      if v.tipType == TipEnum.TipObjectType.Reward and v.type ~= ProtoEnum.GoodsType.GT_FASHION then
        local more = v:GetDetails()
        if more and #more > 0 then
          table.insert(list.newTips, v)
        end
      end
      if not v:IsPlayerCard() and v:IsNotFashionOrMyGenderFashion() then
        table.insert(list.tipList, v)
      end
    end
  end
  if #list.tipList > 0 or #list.newTips > 0 then
    if 0 == #list.newTips then
      if self:GetHasNewTips() == false then
        for _, v in ipairs(list.tipList) do
          table.insert(self.PropTipsList, v)
        end
      else
        local num = #self.allList
        local data = self.allList[num]
        for _, v in ipairs(list.tipList) do
          table.insert(data.tipList, v)
        end
      end
    else
      table.insert(self.allList, list)
    end
  end
  self:TryShowNew()
end

function UMG_LobbyPropTips_C:RemoveTip(tip)
  table.insert(self.NeedRemoveTip, tip)
end

function UMG_LobbyPropTips_C:GetHasNewTips()
  for i = 1, #self.allList do
    local item = self.allList[i]
    if #item.newTips > 0 then
      return true
    end
  end
  return false
end

function UMG_LobbyPropTips_C:ItemSort(itemList)
  table.sort(itemList, function(a, b)
    local ItemConf, PropName, PropIcon, ContainerIcon, Quality, Desc = a:Resolve()
    local ItemConfb, PropNameb, PropIconb, ContainerIconb, Qualityb, Descb = b:Resolve()
    local TieBreaker = true
    if Quality and Qualityb then
      if Quality == Qualityb and (4 == a.type or 4 == b.type) then
        if 4 == a.type and 4 == b.type then
          TieBreaker = a.id < b.id
        end
        return 4 == a.type and TieBreaker
      end
      if Quality == Qualityb then
        TieBreaker = a.id < b.id
      end
      return Quality > Qualityb and TieBreaker
    end
    return a.tipType > b.tipType
  end)
  return itemList
end

function UMG_LobbyPropTips_C:FireFinishCallback()
  for i, Tip in ipairs(self.NeedRemoveTip) do
    Tip:MarkFinished()
  end
  table.clear(self.NeedRemoveTip)
end

function UMG_LobbyPropTips_C:TryNewFinish()
  self.newTipsShow = false
  self:TryShowNew()
end

function UMG_LobbyPropTips_C:TryFinish()
  if self.PropTipsList and 0 ~= #self.PropTipsList then
    return
  end
  if #self.allList > 0 then
    return
  end
  if 0 ~= self.NewPropTips:TipsCount() then
    self:ShowCanvasPanel_title(true)
    return
  end
  self:ShowCanvasPanel_title(false)
  self:FireFinishCallback()
end

function UMG_LobbyPropTips_C:OnAnimationFinished(Animation)
  if Animation == self.TipsIn then
    self.BurnTime = 2
    Log.Debug("Tips Are Shown... Start Burn")
  elseif Animation == self.TipsOut then
    Log.Debug("Tips Out Will Try Show More")
    self:SetWidgetVisibility(UE4.ESlateVisibility.Collapsed)
    self.IsPlayerExp = false
    self.TipsPlaying = false
    self:TryShow()
  elseif Animation == self.huode_out and not self.isShow then
    self.CanvasPanel_title:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:SetShowCollapse()
  end
end

function UMG_LobbyPropTips_C:SetWidgetVisibility(visibility)
  if not self.TipsWidgets then
    return
  end
  for _, widget in ipairs(self.TipsWidgets) do
    widget:SetVisibility(visibility)
  end
end

function UMG_LobbyPropTips_C:AnimOut()
end

function UMG_LobbyPropTips_C:OnDisable()
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_LobbyPropTips_C:OnEnable()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_LobbyPropTips_C:NeedPlayTipsOut()
  if not self.PropTipsList then
    return true
  end
  local VisibleCount = 0
  for _, tip in ipairs(self.PropTipsList) do
    if tip.tipType == TipEnum.TipObjectType.TaskAccept then
    elseif tip.tipType == TipEnum.TipObjectType.TaskComplete then
    elseif tip.tipType == TipEnum.TipObjectType.TaskUpdate then
    elseif tip.tipType == TipEnum.TipObjectType.IncreaseUseCount then
    elseif tip.tipType == TipEnum.TipObjectType.AmplifyUseEffect then
    else
      VisibleCount = VisibleCount + 1
    end
  end
  return 0 == VisibleCount
end

function UMG_LobbyPropTips_C:Tick(MyGeometry, InDeltaTime)
  if not self.TipsPlaying then
    return
  end
  self:UpDataMove(InDeltaTime)
  if 0 == self.BurnTime then
    return
  end
  self.BurnTime = self.BurnTime - InDeltaTime
  if self.BurnTime > 0 then
    return
  end
  self.BurnTime = 0
end

function UMG_LobbyPropTips_C:GetNextTipsAllHave()
  local count = #self.PropTipsList
  for i = 1, count do
    if #self.PropTipsList > 0 then
      local tips = self:GetNextTip()
      if tips and tips:ShowInList() then
        return tips
      end
    end
  end
  return nil
end

function UMG_LobbyPropTips_C:GetNextTip()
  local tip = table.remove(self.PropTipsList, 1)
  self.IsPlayerExp = false
  if not tip then
    return nil
  end
  return tip
end

function UMG_LobbyPropTips_C:TryShowNew()
  if not self.PropTipsList or not self:IsTipsEnabled() then
    return
  end
  if not self.TipsPlaying and 0 == #self.PropTipsList and #self.allList > 0 then
    self.NewPropTips:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetShowCollapse()
    local tipItem = table.remove(self.allList, 1)
    self.PropTipsList = tipItem.tipList
    if #tipItem.newTips > 0 then
      for i = 1, #tipItem.newTips do
        local tips = tipItem.newTips[i]
        local more = tips:GetDetails()
        if more and #more > 0 then
          for _, tip in ipairs(more) do
            self.NewPropTips:PushTip(tip)
            self.NewPropTips:SetFinishCallback(self, self.TryNewFinish)
            self.newTipsShow = true
          end
        end
      end
    end
  end
  if self.newTipsShow == true then
    return
  end
  if true == self.isMove then
    return
  end
  if self.TipsPlaying then
    self.waiteTime = 0
    if self.isQuan == false then
      local TipsCount = 0
      local count = #self.PropTipsList
      for i = 1, count do
        if #self.TipsWidgets > 0 and #self.useList < self:GetShowTipsCount() then
          local tips = self:GetNextTipsAllHave()
          if tips then
            TipsCount = TipsCount + 1
            local widget = table.remove(self.TipsWidgets, 1)
            table.insert(self.useList, widget)
            widget:SetData(tips)
            local pos = widget.Slot:GetPosition()
            pos.y = self.ItemHeight * (#self.useList - 1)
            self:DelaySeconds(0.1 * TipsCount, function()
              widget.Slot:SetPosition(pos)
              widget:SetVisibility(UE4.ESlateVisibility.Visible)
              widget:PlayAnimationTweenIn()
            end)
            self.waiteTime = self.waiteTime + 0.1
          end
        end
      end
      if TipsCount > 0 then
        self.TipsPlaying = true
        self.waiteTime = self.waiteTime + 0.3
      end
      if 0 == #self.TipsWidgets or #self.useList == self:GetShowTipsCount() then
        self.isQuan = true
      end
    else
      Log.Debug("Too late to display, wait for next round")
    end
  else
    self:TryNextBatchNew()
  end
  if 0 == #self.PropTipsList and 0 == #self.useList then
    self.TipsPlaying = false
    self:ShowCanvasPanel_title(false)
    if #self.allList > 0 then
      self:TryShowNew()
    else
      if self.IsPlayerExp then
        self:TryFinish()
        return
      end
      self:DelayFrames(1, function()
        self:TryFinish()
      end)
    end
  else
    self:ShowCanvasPanel_title(true)
  end
end

function UMG_LobbyPropTips_C:GetShowTipsCount()
  local PropTipsSizeY = _G.NRCModeManager:DoCmd(MainUIModuleCmd.GetPropTipsSizeY)
  local Count = PropTipsSizeY / self.ItemHeight
  Log.Debug(Count, "UMG_LobbyPropTips_C:GetShowTipsCount")
  if Count <= 0 then
    Count = 1
  end
  return math.floor(Count)
end

function UMG_LobbyPropTips_C:SetTipsEnabled(bEnable, Reason)
  Log.Debug("[Tips] UMG_LobbyPropTips_C SetTipsEnabled", bEnable, Reason)
  if bEnable then
    local oldDisableFlag = self.DisableFlag
    self.DisableFlag = self.DisableFlag & ~Reason
    if self:IsTipsEnabled() then
      self:SetShowCollapse()
      if 0 ~= oldDisableFlag then
        self:TryShowNew()
      end
    end
  else
    self.DisableFlag = self.DisableFlag | Reason
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_LobbyPropTips_C:IsTipsEnabled()
  return 0 == self.DisableFlag
end

function UMG_LobbyPropTips_C:SetShowCollapse()
  if self.NewPropTips:GetVisibility() == UE4.ESlateVisibility.Collapsed and self.CanvasPanel_title:GetVisibility() == UE4.ESlateVisibility.Collapsed and self.CanvasPanel_0:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif not self:IsTipsEnabled() then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_LobbyPropTips_C:ShowCanvasPanel_title(show)
  if show then
    if self.isShow == false then
      self.isShow = true
      self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.CanvasPanel_title:SetVisibility(UE4.ESlateVisibility.Visible)
      self:SetShowCollapse()
      if self:IsAnimationPlaying(self.huode_out) then
        self:StopAnimation(self.huode_out)
      end
      if not self:IsAnimationPlaying(self.huode_in) then
        self:PlayAnimation(self.huode_in)
      end
    end
  elseif self.isShow == true then
    self.isShow = false
    if self:IsAnimationPlaying(self.huode_in) then
      self:StopAnimation(self.huode_in)
    end
    if not self:IsAnimationPlaying(self.huode_out) then
      self:PlayAnimation(self.huode_out)
    end
  end
end

function UMG_LobbyPropTips_C:TryNextBatchNew()
  if not self.PropTipsList then
    return
  end
  local TitleType = TipEnum.TitleType.None
  local TipsCount = 0
  self.waiteTime = 0
  local count = #self.PropTipsList
  for i = 1, count do
    if #self.TipsWidgets > 0 and #self.useList < self:GetShowTipsCount() then
      local tips = self:GetNextTipsAllHave()
      if tips then
        TipsCount = TipsCount + 1
        local widget = table.remove(self.TipsWidgets, 1)
        table.insert(self.useList, widget)
        widget:SetData(tips)
        local pos = widget.Slot:GetPosition()
        pos.y = self.ItemHeight * (#self.useList - 1)
        self:DelaySeconds(0.1 * TipsCount, function()
          widget.Slot:SetPosition(pos)
          widget:SetVisibility(UE4.ESlateVisibility.Visible)
          widget:PlayAnimationTweenIn()
        end)
        self.waiteTime = self.waiteTime + 0.1
        TitleType = tips.titleType
        local title = TitleType or TipEnum.TitleType.None
        self.TipTitle:SetText(TipEnum.Title[title])
      end
    end
  end
  if TipsCount > 0 then
    self.TipsPlaying = true
    self.BurnTime = 2
    self.waiteTime = self.waiteTime + 1.8
  end
  if 0 == #self.TipsWidgets or #self.useList == self:GetShowTipsCount() then
    self.isQuan = true
  end
end

function UMG_LobbyPropTips_C:UpDataMove(InDeltaTime)
  if self.newTipsShow == true then
    return
  end
  if self.waiteTime > 0 then
    self.waiteTime = self.waiteTime - InDeltaTime
    return
  end
  if #self.useList > 0 and self.useList[1]:GetCanHide() then
    if self.isMove == false and 35 == self.movdis then
      self.isMove = true
      self.useList[1]:TryTweenOut()
    end
    self.movdis = self.movdis - self.moveSpeed * InDeltaTime
    if self.movdis < 0 then
      self.movdis = 0
    end
    local item = self.useList[1]
    local pos1 = item.Slot:GetPosition()
    pos1.y = pos1.y - self.moveSpeed * InDeltaTime
    item.Slot:SetPosition(pos1)
    for i = 2, #self.useList do
      local widget = self.useList[i]
      local pos = widget.Slot:GetPosition()
      pos.y = self.movdis + (i - 2) * self.ItemHeight
      widget.Slot:SetPosition(pos)
    end
    if 0 == self.movdis then
      self.isMove = false
      local widget = table.remove(self.useList, 1)
      table.insert(self.TipsWidgets, widget)
      self.movdis = self.ItemHeight
      if true == self.isQuan then
        if 0 == #self.useList then
          self.isQuan = false
          self:TryShowNew()
        end
      else
        self:TryShowNew()
      end
    end
  end
end

return UMG_LobbyPropTips_C
