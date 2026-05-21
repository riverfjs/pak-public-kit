local UMG_Battle_BuffInfo_C = _G.NRCPanelBase:Extend("UMG_Battle_BuffInfo_C")
UMG_Battle_BuffInfo_C.ContextData = nil

function UMG_Battle_BuffInfo_C:OnConstruct()
  Log.Debug("UMG_Battle_BuffInfo_C:construct")
  self.uiData = {
    list = {},
    handler = self
  }
  self.HotArea:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:AddButtonListener(self.HotArea, self.OnHotAreaClick)
end

function UMG_Battle_BuffInfo_C:OnDestruct()
  self.uiData = nil
  self:RemoveButtonListener(self.HotArea)
end

function UMG_Battle_BuffInfo_C:updateBuffList(_buffList)
  self.NRCScrollView_107:InitList(_buffList)
end

function UMG_Battle_BuffInfo_C:updatePetBuffInfo(_buffData)
  local petBuffList = {
    list = {},
    handler = self
  }
  local UpdateIcon = false
  Log.Debug("Ready to update pet buff Info")
  if _buffData then
    Log.Debug(_buffData)
    for i, buffData in ipairs(_buffData) do
      if not UpdateIcon then
        self:SetHeadIcon(buffData.owner)
        UpdateIcon = true
      end
      local buffConfig = _G.DataConfigManager:GetBuffConf(buffData.id)
      if buffConfig and buffData:NeedShow() then
        table.insert(petBuffList.list, buffData)
      end
    end
  end
  self.uiData = petBuffList
  self:updateBuffInfo()
end

function UMG_Battle_BuffInfo_C:updateBuffInfo()
  local buffListBox = {}
  buffListBox = self.uiData
  local petBuffListBox = {}
  table.insert(petBuffListBox, buffListBox)
  self:updateBuffList(petBuffListBox)
end

function UMG_Battle_BuffInfo_C:OnActive(contextData)
  Log.Debug("UMG_Battle_BuffInfo_C:active")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1083, "UMG_Battle_BuffInfo_C:open")
  if contextData.buffData and #contextData.buffData > 0 then
    Log.Debug("Will Update Buff Data")
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:updatePetBuffInfo(contextData.buffData)
    self:PlayAnimation(self.Transparency_Appear)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimationForward(self.Transparency_Disappear)
  end
  self.HotArea:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Battle_BuffInfo_C:SetHeadIcon(BattlePet)
  if BattlePet.card.petState:GetMimic() then
    self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Unknown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Unknown:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local card = BattlePet and BattlePet:GetCard()
    local petBaseConf = card and card.petBaseConf
    local petConfId = petBaseConf and petBaseConf.id
    local petInfo = card and card.petInfo
    local battle_common_pet_info = petInfo and petInfo.battle_common_pet_info
    local mutation = battle_common_pet_info and battle_common_pet_info.mutation_type
    local glassInfo = battle_common_pet_info and battle_common_pet_info.glass_info
    local battle_inside_pet_info = petInfo and petInfo.battle_inside_pet_info
    local uiParam = self.Pet:PrepareUIParam(battle_inside_pet_info)
    self.Pet:SetIconPathAndMaterial(petConfId, mutation, glassInfo, nil, uiParam)
  end
end

function UMG_Battle_BuffInfo_C:OnDeactive()
end

function UMG_Battle_BuffInfo_C:OnHotAreaClick()
  Log.Debug("UMG_Battle_BuffInfo_C:OnHotAreaClick")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1076, "UMG_Battle_BuffInfo_C:close")
  self:PlayAnimationForward(self.Transparency_Disappear)
end

function UMG_Battle_BuffInfo_C:OnAnimationFinished(anima)
  if anima == self.Transparency_Disappear then
    self.HotArea:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:DoClose()
  end
end

return UMG_Battle_BuffInfo_C
