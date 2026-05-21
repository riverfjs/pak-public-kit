local UMG_Activity_ElfAdventureRightPanel_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventureRightPanel_C")

function UMG_Activity_ElfAdventureRightPanel_C:OnConstruct()
  self.Btn_Right:SetTitleTextAndIcon()
  self.Btn_RightGray:SetTitleTextAndIcon()
  self:OnAddEventListener()
end

function UMG_Activity_ElfAdventureRightPanel_C:UpdateUI(activityInst, activityData, Init)
  self.activityInst = activityInst
  self.activityData = activityData
  if Init then
    self.SelectPetList = {}
    if self.activityData.pet_formation_info and #self.activityData.pet_formation_info > 0 then
      if self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info > 0 then
        if self.activityData.max_pet_num > #self.activityData.cur_pet_trip_info then
          self.Btn_RightGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Btn_LeftGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
        else
          self.Btn_RightGray:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.Btn_LeftGray:SetVisibility(UE4.ESlateVisibility.Visible)
          self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self.Btn_RightGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_Right:SetVisibility(UE4.ESlateVisibility.Visible)
        self.Btn_LeftGray:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Btn_Left:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.Switcher:SetActiveWidgetIndex(1)
      self.ListData = {}
      for i, v in ipairs(self.activityData.pet_formation_info) do
        local data = {}
        local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(v.pet_gid)
        data.Data = v
        data.CatchTime = PetData and PetData.add_time or 0
        data.Parent = self
        data.IsSelect = false
        table.insert(self.ListData, data)
      end
      table.sort(self.ListData, function(a, b)
        if a.Data.max_trip_time == b.Data.max_trip_time then
          if a.CatchTime == b.CatchTime then
            return a.Data.pet_gid < b.Data.pet_gid
          else
            return a.CatchTime > b.CatchTime
          end
        end
        return a.Data.max_trip_time > b.Data.max_trip_time
      end)
      self.Check:SetVisibility(self.activityData.auto_trip and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
      self.List:InitList(self.ListData)
      self.Button:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.Button:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Switcher:SetActiveWidgetIndex(0)
    end
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:PlayInAnimation()
  self.IsShow = true
  self:PlayAnimation(self.In)
end

function UMG_Activity_ElfAdventureRightPanel_C:OnSelectPet(gid)
  if self.SelectPetList then
    if self.SelectPetList[gid] then
      self.SelectPetList[gid] = nil
    else
      local curNum = self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info or 0
      local maxNum = self.activityData.max_pet_num
      local num = maxNum - curNum - (self.SelectPetList and table.getTableCount(self.SelectPetList) or 0)
      if num <= 0 then
        _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_trip_53)
        return
      end
      self.SelectPetList[gid] = true
    end
  else
    self.SelectPetList = {}
    self.SelectPetList[gid] = true
  end
  for i, v in ipairs(self.ListData) do
    v.IsSelect = self.SelectPetList[v.Data.pet_gid]
    local item = self.List:GetItemByIndex(i - 1)
    if item then
      item:UpdateSelected(v.IsSelect)
    end
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:OnAnimationStarted(anim)
  if anim == self.In then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:OnBtnClose()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  self.IsShow = false
  _G.NRCAudioManager:PlaySound2DAuto(40002010, "UMG_Activity_ElfAdventureRightPanel_C:OnBtnClose")
  self:PlayAnimation(self.Out)
end

function UMG_Activity_ElfAdventureRightPanel_C:OnAutoTripBtn()
  if self.activityData.auto_trip then
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local title = LuaText.TIPS
    Context:SetTitle(title):SetContent(LuaText.pet_trip_47):SetMode(DialogContext.Mode.OK_CANCEL):SetClickAnywhereClose(true):SetCloseOnCancel(true):SetCallbackOkOnly(self, function()
      self.activityInst:SendAutoTripReq(not self.activityData.auto_trip)
    end):SetCloseOnOK(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    local title = LuaText.TIPS
    Context:SetTitle(title):SetContent(LuaText.pet_trip_51):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnCancel(true):SetClickAnywhereClose(true):SetCallbackOkOnly(self, function()
      self.activityInst:SendAutoTripReq(not self.activityData.auto_trip)
    end):SetCloseOnOK(true)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:OnBtnGoTrip()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_ElfAdventureRightPanel_C:OnBtnGoTrip")
  if table.isEmpty(self.SelectPetList) then
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.pet_trip_50)
  else
    local petList = {}
    for i, v in pairs(self.SelectPetList) do
      table.insert(petList, i)
    end
    self.activityInst:SendPetTripReq(petList)
  end
end

function UMG_Activity_ElfAdventureRightPanel_C:OnAutoChooseBtn()
  _G.NRCAudioManager:PlaySound2DAuto(41401004, "UMG_Activity_ElfAdventureRightPanel_C:OnAutoChooseBtn")
  local curNum = self.activityData.cur_pet_trip_info and #self.activityData.cur_pet_trip_info or 0
  local maxNum = self.activityData.max_pet_num
  local num = maxNum - curNum - (self.SelectPetList and table.getTableCount(self.SelectPetList) or 0)
  if num <= 0 then
    return
  end
  if not self.SelectPetList then
    self.SelectPetList = {}
  end
  local count = 0
  for i, v in ipairs(self.ListData) do
    if not self.SelectPetList[v.Data.pet_gid] and num > count then
      count = count + 1
      self.SelectPetList[v.Data.pet_gid] = true
    end
  end
  for i, v in ipairs(self.ListData) do
    v.IsSelect = self.SelectPetList[v.Data.pet_gid]
  end
  self.List:InitList(self.ListData, true)
end

function UMG_Activity_ElfAdventureRightPanel_C:OnExplanationBtn()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local title = LuaText.TIPS
  Context:SetTitle(title):SetContent(LuaText.pet_trip_52):SetMode(DialogContext.Mode.NotBtn):SetCloseOnCancel(true):SetCloseOnOK(true)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Activity_ElfAdventureRightPanel_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose, self.OnBtnClose)
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnBtnClose)
  self:AddButtonListener(self.Button, self.OnAutoTripBtn)
  self:AddButtonListener(self.Btn_Left.btnLevelUp, self.OnAutoChooseBtn)
  self:AddButtonListener(self.Btn_Right.btnLevelUp, self.OnBtnGoTrip)
  self:AddButtonListener(self.ExplanationBtn.btnLevelUp, self.OnExplanationBtn)
end

return UMG_Activity_ElfAdventureRightPanel_C
