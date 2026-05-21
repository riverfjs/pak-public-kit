local UMG_Nourish_BigMapTips_C = _G.NRCPanelBase:Extend("UMG_Nourish_BigMapTips_C")

function UMG_Nourish_BigMapTips_C:OnActive(arg)
  self:UpdateData(arg or {})
  self:BindInputAction()
  self:LoadAnimation(0)
end

function UMG_Nourish_BigMapTips_C:UpdateData(arg)
  self.dataList = arg.petDataList
  self.curPetBaseId = arg.petBaseConfId
  self.isNotFind = arg.NotFound
  self.call = arg.caller
  self.callBack = arg.callBack
  self.isFruit = arg.isFruit
  self:ShowIcon()
  self.List:InitGridView(self.dataList)
end

function UMG_Nourish_BigMapTips_C:ShowIcon()
  local petBaseId = self.curPetBaseId
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
  local petModuleCof = _G.DataConfigManager:GetModelConf(petbaseConf.model_conf)
  local iconPath = petModuleCof.icon
  self.Pet:SetPath(iconPath)
  self.Switcher2:SetActiveWidgetIndex(self.isNotFind and 1 or 0)
  self.Switcher1:SetActiveWidgetIndex(petbaseConf.Pet_Circadian)
  if self.isNotFind and 0 == self.isFruit then
    self.UsualAppearance:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.TitleText:SetText("???\229\174\182\230\151\143")
    self.Switcher1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.Pet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HaveNotMet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Pet:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HaveNotMet:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if petbaseConf.form and petbaseConf.form ~= "" then
      self.Type:SetText(petbaseConf.form)
      self.UsualAppearance:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      self.UsualAppearance:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self.Switcher1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.TitleText:SetText(string.format(LuaText.umg_nourish_bigmaptips_1, petbaseConf.name))
  end
end

function UMG_Nourish_BigMapTips_C:OnDeactive()
end

function UMG_Nourish_BigMapTips_C:OnAddEventListener()
  self.HotArea.OnClicked:Add(self, self.OnCloseBtnClick)
end

function UMG_Nourish_BigMapTips_C:OnCloseBtnClick()
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  if self.call and self.callBack then
    self.callBack(self.call)
    self.call = nil
    self.callBack = nil
  end
  self:LoadAnimation(2)
end

function UMG_Nourish_BigMapTips_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Nourish_BigMapTips_C:OnAnimationFinished(anim)
  if anim == self:GetAnimByIndex(2) then
    self:DoClose()
  elseif anim == self:GetAnimByIndex(0) then
    self:LoadAnimation(1)
  end
end

function UMG_Nourish_BigMapTips_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_NourishBigMapTips")
  if mappingContext then
    mappingContext:BindAction("IA_CloseNourishBigMapTips", self, "OnPcClose2")
  end
end

function UMG_Nourish_BigMapTips_C:OnPcClose2()
  self:OnCloseBtnClick()
end

return UMG_Nourish_BigMapTips_C
