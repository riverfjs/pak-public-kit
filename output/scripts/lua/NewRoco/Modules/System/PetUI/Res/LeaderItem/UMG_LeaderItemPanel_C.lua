local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local UMG_LeaderItemPanel_C = _G.NRCPanelBase:Extend("UMG_LeaderItemPanel_C")
local PanelName = "LeaderItemPanel"

function UMG_LeaderItemPanel_C:OnConstruct()
  self.data = self.module:GetData("PetUIModuleData")
  self.LeaderItemList = {}
  self.IsInitPetImage3D = false
  self.bRightPanelShow = false
  self:SetLeaderItemList()
  self:OnAddEventListener()
  self:SetChildViews(self.UMG_PetImage3D)
end

function UMG_LeaderItemPanel_C:OnDestruct()
end

function UMG_LeaderItemPanel_C:OnActive()
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:SetPanelInfo()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetLeaderAttribute)
  self.RightPanel_1:SetVisibility(UE.ESlateVisibility.Collapsed)
  self:PlayAnimation(self.Open_0)
end

function UMG_LeaderItemPanel_C:OnDeactive()
end

function UMG_LeaderItemPanel_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.SwitchButton, self.OnCloseRightPanel)
  self:RegisterEvent(self, PetUIModuleEvent.SelectLeaderItemEvent, self.OnLeaderItemSelected)
  self:RegisterEvent(self, PetUIModuleEvent.ShowOrHideLeaderRight, self.ShowOrHideRight)
  self:RegisterEvent(self, PetUIModuleEvent.OnPetSkillChange, self.OnPetSkillChange)
  self.ItemList:SetItemSelectedCallback(self.OnItemSelected, self)
end

function UMG_LeaderItemPanel_C:SetLeaderItemList()
  local LeaderItemList = self.data:GetLeaderItemList()
  for i, LeaderItem in ipairs(LeaderItemList) do
    local IsHas = false
    local BagItem
    local _BagItem = _G.NRCModeManager:DoCmd(BagModuleCmd.GetBagItemByID, LeaderItem.id)
    if _BagItem then
      IsHas = true
      BagItem = _BagItem
    end
    table.insert(self.LeaderItemList, {
      BagItemConf = LeaderItem,
      IsHas = IsHas,
      itemData = BagItem,
      parentView = self
    })
  end
end

function UMG_LeaderItemPanel_C:OnItemSelected(item, rawIndex, userClick)
  self:SetCurSelectItemIndex(rawIndex + 1)
end

function UMG_LeaderItemPanel_C:SetCurSelectItemIndex(index)
  self.CurSelectItemIndex = index
end

function UMG_LeaderItemPanel_C:GetCurSelectItemIndex()
  return self.CurSelectItemIndex
end

function UMG_LeaderItemPanel_C:SetPanelInfo()
  self.TitleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.TitleConf.title)
  self.Title1:SetBg(self.TitleConf.head_icon)
  self.Title1:SetSubtitle(self.TitleConf.subtitle[1].subtitle)
  self:SetLeftPanelInfo()
end

function UMG_LeaderItemPanel_C:SetLeftPanelInfo()
  self.ItemList:InitList(self.LeaderItemList)
  self.ItemList:SelectItemByIndex(0)
end

function UMG_LeaderItemPanel_C:OnLeaderItemSelected(ItemData)
  self:SetRightPanelInfo(ItemData)
  self:SetPetImage3D()
end

function UMG_LeaderItemPanel_C:SetRightPanelInfo(ItemInfo)
  self.ItemName:SetText(ItemInfo.BagItemConf.name)
  self.ItemWay:SetText(ItemInfo.BagItemConf.type_desc)
  if ItemInfo.IsHas then
    local Time = os.date(LuaText.medal_text_5, ItemInfo.itemData.update_time)
    self.GetTime:SetText(string.format("%s%s", Time, LuaText.BossEvoItemTime_02))
  else
    self.GetTime:SetText(LuaText.BossEvoItemTime_01)
  end
  self.ItemImage:SetPath(ItemInfo.BagItemConf.big_icon)
  self.ItemDescribe:SetText(ItemInfo.BagItemConf.flavor_text)
  self.NRCTextDes_1:SetText(ItemInfo.BagItemConf.description)
  local gainWayList = self:GetGaiWay(ItemInfo.BagItemConf)
  self.ItemGainWay:InitGridView(gainWayList)
  for i = 1, #gainWayList do
    local item = self.ItemGainWay:GetItemByIndex(i - 1)
    self:DelaySeconds(0.05 * i, function()
      item:SetVisibility(UE.ESlateVisibility.Visible)
      item:PlayAnimation(item.In)
    end)
  end
  self:RandomPlayAnimation()
end

function UMG_LeaderItemPanel_C:SetPetImage3D()
  local PetBaseID = self:GetTargetPetBaseID()
  if 0 ~= PetBaseID then
    if not self.IsInitPetImage3D then
      self.UMG_PetImage3D:OnActive(PetBaseID, PanelName)
      self.IsInitPetImage3D = true
    end
    self:UpdateSelectPetData(PetBaseID)
  end
end

function UMG_LeaderItemPanel_C:GetTargetPetBaseID()
  local PetBaseID = 0
  local SelectLeaderItem = self.data:GetSelectLeaderItem()
  local LeaderPetList = self.data:GetLeaderPetList()
  if SelectLeaderItem then
    self.LeaderPet = LeaderPetList[SelectLeaderItem.BagItemConf.id]
    if self.LeaderPet and self.LeaderPet[1] and self.LeaderPet[1].id then
      PetBaseID = self.LeaderPet[1].id
    end
  end
  return PetBaseID
end

function UMG_LeaderItemPanel_C:GetGaiWay(bagItemInfo)
  local real_acquire_struct = {}
  for i = 1, #bagItemInfo.acquire_struct do
    if bagItemInfo.acquire_struct[i].acquire_way_text == nil then
      goto lbl_27
    else
      table.insert(real_acquire_struct, {
        acquire_struct = bagItemInfo.acquire_struct[i],
        IsFirstOpenPanel = false,
        itemId = bagItemInfo.id
      })
    end
    ::lbl_27::
  end
  return real_acquire_struct
end

function UMG_LeaderItemPanel_C:OnCloseRightPanel()
  self:ShowOrHideRight(false)
  _G.NRCAudioManager:PlaySound2DAuto(41400003, "UMG_LeaderItemPanel_C:OnCloseRightPanel")
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetLeaderAttribute)
end

function UMG_LeaderItemPanel_C:ShowOrHideRight(Show)
  self.bRightPanelShow = Show
  if Show then
    self.RightPanel_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.SwitchButton:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_PetImage3D:OpenDetailCameraLocation(1, true, true)
    self:RandomPlayAnimation()
    self:PlayAnimation(self.ScreenBtn_open)
  else
    self.SwitchButton:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.UMG_PetImage3D:OpenDetailCameraLocation(0, false, false)
    self:PlayAnimation(self.ScreenBtn_none)
  end
end

function UMG_LeaderItemPanel_C:OnPetSkillChange(IsPlayPetSkill)
  if IsPlayPetSkill then
    self.SwitchButton:SetIsEnabled(false)
  else
    self.SwitchButton:SetIsEnabled(true)
  end
end

function UMG_LeaderItemPanel_C:RandomPlayAnimation()
  local index = math.random(1, 4)
  local aimName = string.format("star%d", index)
  self:PlayAnimation(self[aimName])
end

function UMG_LeaderItemPanel_C:OnCloseBtn()
  self:ClosePanel()
end

function UMG_LeaderItemPanel_C:ClosePanel()
  self.module:OpenOrCloseLeaderItemPanel(false)
  _G.NRCAudioManager:PlaySound2DAuto(41401014, "UMG_LeaderItemPanel_C:OnCloseBtn")
  if self.bRightPanelShow then
    self:PlayAnimation(self.Out)
  else
    self:PlayAnimation(self.Close_0)
  end
end

function UMG_LeaderItemPanel_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:DoClose()
  elseif Anim == self.Close_0 then
    self:DoClose()
  end
end

function UMG_LeaderItemPanel_C:UpdateSelectPetData(petbaseId)
  if nil == petbaseId or self.curSelectId == petbaseId then
    return
  end
  self.UMG_PetImage3D:SetCachePetModelScale(0.3)
  self.UMG_PetImage3D:UpdateDefaultPetModel3DShow(petbaseId)
end

return UMG_LeaderItemPanel_C
