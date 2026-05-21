require("UnLuaEx")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local UMG_DialogueSelector_C = _G.NRCViewBase:Extend("UMG_DialogueSelector_C")
local MaxDisplayNum = 6

function UMG_DialogueSelector_C:OnConstruct()
  Log.Debug("UMG_DialogueSelector_C:OnConstruct")
  local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ObjListNew)
  self.oriPos = slot:GetPosition()
  self.oriSize = slot:GetSize()
  self:OnAddEventListener()
  self.Option = nil
  self.AutoPlayChangedCallbackID = _G.UserSettingManager:RegisterDialogueAutoPlayChangedCallback(self, self.OnDialogueAutoPlayChanged)
end

function UMG_DialogueSelector_C:OnAddEventListener()
  Log.Debug("UMG_DialogueSelector_C:OnAddEventListener")
  self.ObjListNew.OnUserScrolled:Add(self, self.OnLevelListScrolled)
  self:RegisterEvent(self, DialogueModuleEvent.DialogueSelectFinished, self.OnItemSelected)
  self:RegisterEvent(self, DialogueModuleEvent.DialogueSelectedIndex, self.OnDialogueSelectedIndex)
  self:BindInputAction()
end

function UMG_DialogueSelector_C:OnLevelListScrolled()
  local Count = self.ObjListNew:GetItemCount()
  for i = 0, Count - 1 do
    local item = self.ObjListNew:GetItemByIndex(i)
    if item.Content then
      item:OnPanelScrolled()
    end
  end
end

function UMG_DialogueSelector_C:OnDestruct()
  Log.Debug("UMG_DialogueSelector_C:OnDestruct")
  self:UnRegisterEvent(self, DialogueModuleEvent.DialogueSelectFinished)
  self:UnRegisterEvent(self, DialogueModuleEvent.DialogueSelectedIndex)
  self:UnBindInputAction()
  self.Option = nil
  _G.UserSettingManager:UnregisterDialogueAutoPlayChangedCallback(self.AutoPlayChangedCallbackID)
  self.AutoPlayChangedCallbackID = 0
  local Count = self.ObjListNew:GetItemCount()
  for i = 0, Count do
    local item = self.ObjListNew:GetItemByIndex(i)
    if item then
      item:ClearDefaultOptionTimer()
    end
  end
end

function UMG_DialogueSelector_C:BindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_Dialogue")
  if mappingContext then
    local actions = {
      {
        name = "IA_SelectDialogueOption_1",
        method = "SelectDialogueOption1"
      },
      {
        name = "IA_SelectDialogueOption_2",
        method = "SelectDialogueOption2"
      },
      {
        name = "IA_SelectDialogueOption_3",
        method = "SelectDialogueOption3"
      },
      {
        name = "IA_SelectDialogueOption_4",
        method = "SelectDialogueOption4"
      },
      {
        name = "IA_SelectDialogueOption_5",
        method = "SelectDialogueOption5"
      },
      {
        name = "IA_SelectDialogueOption_6",
        method = "SelectDialogueOption6"
      },
      {
        name = "IA_SelectDialogueOption_ESC",
        method = "SelectDialogueOptionESC"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
end

function UMG_DialogueSelector_C:UnBindInputAction()
  local mappingContext = self:GetInputMappingContext("IMC_Dialogue")
  if mappingContext then
    local actions = {
      {
        name = "IA_SelectDialogueOption_1"
      },
      {
        name = "IA_SelectDialogueOption_2"
      },
      {
        name = "IA_SelectDialogueOption_3"
      },
      {
        name = "IA_SelectDialogueOption_4"
      },
      {
        name = "IA_SelectDialogueOption_5"
      },
      {
        name = "IA_SelectDialogueOption_6"
      },
      {
        name = "IA_SelectDialogueOption_ESC"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
  end
end

function UMG_DialogueSelector_C:SelectDialogueOption(index)
  if self:GetVisibility() == UE4.ESlateVisibility.Visible and self.ObjListNew and self.ObjListNew._listDatas and self.ObjListNew._listDatas[index] then
    local SelectItem = self.ObjListNew:GetItemByIndex(index - 1)
    if SelectItem then
      SelectItem:OnOptionSelect()
    end
  end
end

function UMG_DialogueSelector_C:SelectDialogueOption1()
  self:SelectDialogueOption(1)
end

function UMG_DialogueSelector_C:SelectDialogueOption2()
  self:SelectDialogueOption(2)
end

function UMG_DialogueSelector_C:SelectDialogueOption3()
  self:SelectDialogueOption(3)
end

function UMG_DialogueSelector_C:SelectDialogueOption4()
  self:SelectDialogueOption(4)
end

function UMG_DialogueSelector_C:SelectDialogueOption5()
  self:SelectDialogueOption(5)
end

function UMG_DialogueSelector_C:SelectDialogueOption6()
  self:SelectDialogueOption(6)
end

function UMG_DialogueSelector_C:SelectDialogueOptionESC()
  if self.module and self.module.IsButtonSkipVisible and self.module:IsButtonSkipVisible() then
    return
  end
  if self:GetVisibility() ~= UE4.ESlateVisibility.Hidden and self:GetVisibility() ~= UE4.ESlateVisibility.Collapsed and self.ObjListNew then
    for i = self.ObjListNew:GetItemCount() - 1, 0, -1 do
      local item = self.ObjListNew:GetItemByIndex(i)
      if item and item.SelectConf and item.SelectConf.esc_skip then
        item:OnSelected(true)
      end
    end
  end
end

function UMG_DialogueSelector_C:OnItemSelected()
  self:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.ObjListNew and self.ObjListNew.Clear then
    self.ObjListNew:Clear()
  end
end

function UMG_DialogueSelector_C:ShowOptions(selectConfs, Option)
  if not selectConfs then
    Log.Error("select conf is empty")
    selectConfs = {}
  end
  if not UE.UObject.IsValid(self) then
    Log.Error("UMG_DialogueSelector_C:ShowOptions\231\130\184\228\186\134!!!!!!!!")
    return
  end
  if not self.SetRenderOpacity then
    Log.Error("UMG_DialogueSelector_C:ShowOptions\231\130\184\228\186\134!!!!!!!!")
    return
  end
  self:SetVisibility(UE4.ESlateVisibility.Visible)
  self:SetRenderOpacity(0)
  self.Option = Option
  local selectNum = #selectConfs
  self.TotalNum = MaxDisplayNum
  self.ItemNum = selectNum
  self:OnParamChange()
  if selectNum < MaxDisplayNum then
    local moveNum = MaxDisplayNum - selectNum
    local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ObjListNew)
    if slot then
      local itemWidth = 88
      local newPos = UE4.FVector2D(self.oriPos.X, self.oriPos.Y + moveNum * itemWidth)
      slot:SetPosition(newPos)
      local newSize = UE4.FVector2D(self.oriSize.X, self.oriSize.Y - moveNum * itemWidth)
      slot:SetSize(newSize)
    end
  else
    local slot = UE4.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.ObjListNew)
    slot:SetPosition(self.oriPos)
    slot:SetSize(self.oriSize)
  end
  local SelectionPayload = {}
  for _, _dataInfo in ipairs(selectConfs) do
    table.insert(SelectionPayload, {Conf = _dataInfo, Option = Option})
  end
  if self.ObjListNew then
    self.ObjListNew:InitList(SelectionPayload)
    for i = 0, self.ObjListNew:GetItemCount() do
      local item = self.ObjListNew:GetItemByIndex(i)
      if item then
        item:OnShownByScrollView()
      end
    end
  else
    Log.Debug("UMG_DialogueSelector_C: ObjListNew is empty or uninitialized")
  end
  self:SetSelectionEnableByAutoPlay()
  _G.DelayManager:DelayFrames(2, self.ChangeRenderOpacity, self)
end

function UMG_DialogueSelector_C:SetSelectionEnable(bSelectEnable)
  self:SetVisibility(bSelectEnable and UE4.ESlateVisibility.Visible or UE4.ESlateVisibility.HitTestInvisible)
end

function UMG_DialogueSelector_C:SetSelectionEnableByAutoPlay()
  if self:GetVisibility() == UE4.ESlateVisibility.Hidden or self:GetVisibility() == UE4.ESlateVisibility.Collapsed then
    return
  end
  local bAutoPlayEnable = _G.UserSettingManager:IsDialogueAutoPlayOn()
  local Count = self.ObjListNew:GetItemCount()
  for i = 0, Count do
    local item = self.ObjListNew:GetItemByIndex(i)
    if item then
      local bDefaultSelect = bAutoPlayEnable and item.SelectConf and item.SelectConf.select_skip
      if bDefaultSelect then
        item:StartDefaultOptionTimer()
      else
        item:ClearDefaultOptionTimer()
      end
    end
  end
end

function UMG_DialogueSelector_C:ChangeRenderOpacity()
  if not UE.UObject.IsValid(self) then
    Log.Error("UMG_DialogueSelector_C:ShowOptions\231\130\184\228\186\134!!!!!!!!")
    return
  end
  self:SetRenderOpacity(1)
end

function UMG_DialogueSelector_C:OnDialogueSelectedIndex(_index)
  local Count = self.ObjListNew:GetItemCount()
  for i = 1, Count do
    self.ObjListNew:SelectItemByIndex(_index - 1)
  end
end

function UMG_DialogueSelector_C:OnDialogueAutoPlayChanged()
  self:SetSelectionEnableByAutoPlay()
end

return UMG_DialogueSelector_C
