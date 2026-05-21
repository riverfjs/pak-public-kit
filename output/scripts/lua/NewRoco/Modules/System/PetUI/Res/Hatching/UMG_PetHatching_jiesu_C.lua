local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local UMG_PetHatching_jiesu_C = _G.NRCPanelBase:Extend("UMG_PetHatching_jiesu_C")

function UMG_PetHatching_jiesu_C:OnActive(arg)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local eggPetGid = arg.eggPetGid
  local petBaseId = arg.eggPetBaseID
  local eggBallItemId = arg.eggBallItemId
  local name = _G.DataConfigManager:GetPetbaseConf(petBaseId).name
  self.NRCText_1:SetText(name)
  self.genderIcons = {
    self.ImagePetGender1,
    self.ImagePetGender2
  }
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401004, "UMG_EggIncubatePanel_C:OnFinshPerform")
  if eggPetGid then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(eggPetGid)
    if PetData then
      self.module:SetCurrPetData(PetData)
      local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
      local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(PetData.blood_id)
      local commonAttrData = {}
      table.insert(commonAttrData, {
        Name = PetBloodConf.blood_name,
        Path = PetBloodConf.icon
      })
      if self.Attr then
        self.Attr:InitGridView(commonAttrData)
      end
      self:updatePetGender(PetData.gender)
      self:updatePetTypeIcon(PetBaseConf.unit_type)
      self:SetTalentRank(PetData)
      self.petGid = PetData.gid
      self:UpdateCollect(PetData.partner_mark)
      self:UpdateMDT_SHINING(PetData)
      self:UpdateBallInfluencePanel(eggBallItemId)
    end
  else
    self.bSimpleShow = true
    self.petBaseId = petBaseId
    local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(petBaseId)
    if PetBaseConf then
      self:updatePetTypeIcon(PetBaseConf.unit_type)
    end
    self:updatePetGender()
    self:UpdateBallInfluencePanel()
    self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PetRate:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.UMG_CollectBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.DazzlingColors:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHatching_jiesu_C:OnConstruct()
  self.PetRate:OnConstruct()
  self:OnAddEventListener()
end

function UMG_PetHatching_jiesu_C:OnDeactive()
  self:UnRegisterEvent(self, PetUIModuleEvent.EggIncubatePanelUpdate)
  self:UnRegisterEvent(self, PetUIModuleEvent.EndEggEffect)
end

function UMG_PetHatching_jiesu_C:OnAddEventListener()
  self:RegisterEvent(self, PetUIModuleEvent.EggIncubatePanelUpdate, self.ShowText)
  self:RegisterEvent(self, PetUIModuleEvent.EndEggEffect, self.EndEggEffect)
  self:AddButtonListener(self.UMG_Btn2, self.OnClosePanel)
  self:AddButtonListener(self.BtnRechristen_1, self.OnBtnRechristen_1Click)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnBtnCollectClick)
  self.BtnRechristen_1.OnPressed:Add(self, self.OnDepartBtnPressed)
  self.BtnRechristen_1.OnReleased:Add(self, self.OnDepartBtnReleased)
  self.BloodPulse.OnPressed:Add(self, self.OnBloodPulsePressed)
  self.BloodPulse.OnReleased:Add(self, self.OnBloodPulseReleased)
end

function UMG_PetHatching_jiesu_C:OnDepartBtnPressed()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Press_1)
end

function UMG_PetHatching_jiesu_C:OnDepartBtnReleased()
  self:StopAnimation(self.Press_1)
  self:StopAnimation(self.Up_1)
  self:PlayAnimation(self.Up_1)
end

function UMG_PetHatching_jiesu_C:OnBloodPulsePressed()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Press_2)
end

function UMG_PetHatching_jiesu_C:OnBloodPulseReleased()
  self:StopAnimation(self.Press_2)
  self:StopAnimation(self.Up_2)
  self:PlayAnimation(self.Up_2)
end

function UMG_PetHatching_jiesu_C:UpdateBallInfluencePanel(eggBallItemId)
  if nil == eggBallItemId then
    self.CanvasPanel_Ball:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local ballConf = _G.DataConfigManager:GetBallConf(eggBallItemId)
  if nil == ballConf then
    return
  end
  if ballConf.ball_effect_type == _G.Enum.BallEffectType.BET_CHANGE_PET_MUTATION then
    self.CanvasPanel_Ball:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local ballName = ballConf.editor_name
    self.Text_Influence:SetText(string.format(LuaText.choose_ball_tips_4, ballName))
    self.BallImage:SetPath(ballConf.ball_icon)
  elseif ballConf.ball_effect_type == _G.Enum.BallEffectType.BET_CHANGE_PET_ATTRIBUTE then
    self.CanvasPanel_Ball:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local ballName = ballConf.editor_name
    self.Text_Influence:SetText(string.format(LuaText.choose_ball_tips_7, ballName))
    self.BallImage:SetPath(ballConf.ball_icon)
  else
    self.CanvasPanel_Ball:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetHatching_jiesu_C:SetTalentRank(petData)
  self.PetRate:SetText(petData)
end

function UMG_PetHatching_jiesu_C:updatePetTypeIcon(_dicTypes)
  local commonAttrData = {}
  local petType = _dicTypes
  if petType and type(petType) == "table" and #petType >= 1 then
    for i = 1, table.len(petType) do
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
    if commonAttrData and self.Attr1 then
      self.Attr1:InitGridView(commonAttrData)
    end
  end
end

function UMG_PetHatching_jiesu_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_PetHatching_jiesu_C:OnBtnRechristen_1Click()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  if self:GetIsSelectBtn() then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1002, "UMG_PetBaseInfo_C:OnBtnBtnRechristenClick")
  if self.bSimpleShow then
    local petData = {
      base_conf_id = self.petBaseId
    }
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips, petData)
  else
    _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips)
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").PETTIPS
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_PetHatching_jiesu_C:OnBloodPulse()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  if self:GetIsSelectBtn() then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_PetBaseInfo_C:OnBloodPulse")
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.PetUIOpenPetBloodPulse)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").PETBLOOD
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_PetHatching_jiesu_C:UpdateMDT_SHINING(PetData)
  self.DazzlingColors:InitUI(PetData)
end

function UMG_PetHatching_jiesu_C:OnBtnCollectClick()
  if self:IsAnimationPlaying(self.Out) then
    return
  end
  if self:GetIsSelectBtn() then
    return
  end
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.petGid, self.partner_mark or 0)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").PETCOLLECT
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_PetHatching_jiesu_C:UpdateCollect(partner_mark)
  self.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_PetHatching_jiesu_C:ShowText()
  self:PlayAnimation(self.In)
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
end

function UMG_PetHatching_jiesu_C:EndEggEffect()
  self.bCloseEnable = true
end

function UMG_PetHatching_jiesu_C:OnPcClose()
  self:OnClosePanel()
end

function UMG_PetHatching_jiesu_C:OnClosePanel()
  if not self.bCloseEnable then
    return
  end
  if self:GetIsSelectBtn() then
    return
  end
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.LockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
  if not self:IsAnimationPlaying(self.Out) then
    _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
    if self.bSimpleShow then
      _G.NRCModuleManager:DoCmd(PetUIModuleCmd.ClosePetHatchOnlyPanel)
    end
    self:OnClose()
  end
end

function UMG_PetHatching_jiesu_C:OnFinshPerform()
  self.CanvasPanel_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1220002038, "UMG_EggIncubatePanel_C:OnFinshPerform")
  _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.CloseEggIncubatePanel)
  local touchReasonType = _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.GetPanelSelectBtnReason, "EggIncubatePanel").CLOSE
  _G.NRCModuleManager:DoCmd(MultiTouchModuleCmd.UnlockIsSelectBtn, "PetUIModule", "EggIncubatePanel", touchReasonType)
end

function UMG_PetHatching_jiesu_C:OnAnimFinished(Anim)
  if Anim == self.Out then
    self:OnFinshPerform()
  end
end

return UMG_PetHatching_jiesu_C
