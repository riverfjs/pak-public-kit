local UMG_BoxOrganizationFethod_C = _G.NRCPanelBase:Extend("UMG_BoxOrganizationFethod_C")

function UMG_BoxOrganizationFethod_C:OnConstruct()
  self:SetChildViews(self.PopUp4)
end

function UMG_BoxOrganizationFethod_C:OnActive(curBoxIndex)
  self.curBoxIndex = curBoxIndex
  self:InitPanel()
  self:PlayAnimation(self:GetAnimByIndex(0))
end

function UMG_BoxOrganizationFethod_C:OnDeactive()
end

function UMG_BoxOrganizationFethod_C:OnAddEventListener()
end

function UMG_BoxOrganizationFethod_C:InitPanel()
  self:SetCommonPopUpInfo(self.PopUp4)
  self.NRCText_2:SetText(LuaText.tidy_sequence_title)
  local tidySequenceTypeConf = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.TIDY_SEQUENCE_TYPE):GetAllDatas()
  if tidySequenceTypeConf then
    local typeList = {}
    for _, conf in pairs(tidySequenceTypeConf or {}) do
      if conf then
        local temp = {conf = conf, parent = self}
        table.insert(typeList, temp)
      end
    end
    self.petList:InitGridView(typeList)
    local index = 0
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerPetInfo()
    if petInfo and petInfo.backpack_info and petInfo.backpack_info.tidy_rules and petInfo.backpack_info.tidy_rules[1] then
      index = petInfo.backpack_info.tidy_rules[1]
    end
    self.petList:SelectItemByIndex(index)
  end
end

function UMG_BoxOrganizationFethod_C:OnChooseTidyType(conf)
  if conf then
    self.PopUp4:SetDescInfo(conf.tip_text)
  end
  self.tidyType = conf.sequence_type
end

function UMG_BoxOrganizationFethod_C:SetCommonPopUpInfo(PopUp)
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.FullScreen_Close = true
  CommonPopUpData.TitleText = LuaText.tidy_box_title
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_LeftHandler = self.OnClickCloseBtn
  CommonPopUpData.Btn_RightHandler = self.OnClickConfirm
  CommonPopUpData.ClosePanelHandler = self.OnClickCloseBtn
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  PopUp:SetPanelInfo(CommonPopUpData)
end

function UMG_BoxOrganizationFethod_C:OnClickCloseBtn()
  if self:IsAnimationPlaying(self:GetAnimByIndex(2)) then
    return
  end
  self:PlayAnimation(self:GetAnimByIndex(2))
end

function UMG_BoxOrganizationFethod_C:OnClickConfirm()
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.OnCmdZonePetBoxTidyReq, self.curBoxIndex, self.tidyType)
  self:OnClickCloseBtn()
end

function UMG_BoxOrganizationFethod_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_BoxOrganizationFethod_C
