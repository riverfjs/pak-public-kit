local PetUtils = require("NewRoco.Utils.PetUtils")
local ModuleEnum = require("NewRoco/Modules/System/BattleRogue/RogueModuleEnum")
local ModuleEvent = require("NewRoco.Modules.System.BattleRogue.BattleRogueModuleEvent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local UMG_HerbologyBadge_AffirmPet_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_AffirmPet_C")

function UMG_HerbologyBadge_AffirmPet_C:OnActive()
  self:OnAddEventListener()
  self:OnPanelShow()
end

function UMG_HerbologyBadge_AffirmPet_C:OnDeactive()
  self:OnRemoveEventListener()
end

function UMG_HerbologyBadge_AffirmPet_C:OnPanelShow()
  local petGid = self.module.Data.TrialPetInfo.pet_gid
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid)
  if not self.petData then
    Log.Error("UMG_HerbologyBadge_AffirmPet_C:OnActive \232\142\183\229\143\150\231\178\190\231\129\181\230\149\176\230\141\174\229\164\177\232\180\165\239\188\129Gid\228\184\186", petGid)
    return
  end
  self:_InitPanel()
end

function UMG_HerbologyBadge_AffirmPet_C:OnAddEventListener()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseButtonClicked)
  self:AddButtonListener(self.DetailsBtn.btnLevelUp, self.OnDetailButtonClicked)
  self:AddButtonListener(self.Notarize_Btn.btnLevelUp, self.OnConfirmButtonClicked)
  self:AddButtonListener(self.BtnTrophy, self.OnTrophyButtonClicked)
  self:AddButtonListener(self.UMG_CollectBtn.Button, self.OnCollectBtn)
  self:AddButtonListener(self.BtnRechristen_1, self.OpenPetTips)
  self:AddButtonListener(self.BloodPulse, self.OnBloodPulse)
  self:RegisterEvent(self, ModuleEvent.OnUpdatePetCollect, self.UpdateCollect)
end

function UMG_HerbologyBadge_AffirmPet_C:OnRemoveEventListener()
  self:UnRegisterEvent(self, ModuleEvent.OnUpdatePetCollect, self.UpdateCollect)
end

function UMG_HerbologyBadge_AffirmPet_C:OnCloseButtonClicked()
  _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.SelectPet)
end

function UMG_HerbologyBadge_AffirmPet_C:OnDetailButtonClicked()
  local titleText = "\232\191\153\230\152\175\230\160\135\233\162\152"
  local contentStr = "\232\191\153\230\152\175\229\134\133\229\174\185"
  local Context = DialogContext()
  Context:SetTitle(titleText):SetContent(contentStr):SetContentTextJustify(UE4.ETextJustify.Left):SetClickAnywhereClose(true):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCallback(self, self.OnDescDialogClosed)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_HerbologyBadge_AffirmPet_C:OnConfirmButtonClicked()
  local ModuleData = self.module.Data
  local Req = ProtoMessage:newZoneGrassTrialStartChallengeReq()
  Req.trial_conf_id = ModuleData.TrialID
  Req.pet_gid = ModuleData.TrialPetInfo.pet_gid
  Req.initial_skill_id = ModuleData.TrialPetInfo.skills[1]
  Req.first_dungeon_id = _G.NRCModuleManager:DoCmd(_G.InstanceModuleCmd.GetCurrentDungeon)
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_GRASS_TRIAL_START_CHALLENGE_REQ, Req, self, self.OnServerConfirm)
end

function UMG_HerbologyBadge_AffirmPet_C:OnServerConfirm(Rsp)
  if 0 == Rsp.ret_info.ret_code then
    self.module.Data:UpdateChallengeInfo(Rsp.challenge_data)
    self.module:OpenHerbologyTrialTips()
    _G.NRCModuleManager:DoCmd(_G.BattleRogueModuleCmd.TryChangeState, ModuleEnum.RogueStateEnum.ChallengeLobby)
  end
end

function UMG_HerbologyBadge_AffirmPet_C:OnTrophyButtonClicked()
end

function UMG_HerbologyBadge_AffirmPet_C:OnCollectBtn()
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetCollectPanel, self.petData.gid, self.petData.partner_mark)
end

function UMG_HerbologyBadge_AffirmPet_C:UpdateCollect(partner_mark)
  self.petData.partner_mark = partner_mark
  self.UMG_CollectBtn:UpdateInfo(partner_mark)
end

function UMG_HerbologyBadge_AffirmPet_C:OnBtnRechristenPressed()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Press)
end

function UMG_HerbologyBadge_AffirmPet_C:OnBtnRechristenReleased()
  self:StopAnimation(self.BtnRechristen_Press)
  self:StopAnimation(self.BtnRechristen_Up)
  self:PlayAnimation(self.BtnRechristen_Up)
end

function UMG_HerbologyBadge_AffirmPet_C:OnBloodPulsePressed()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Press)
end

function UMG_HerbologyBadge_AffirmPet_C:OnBloodPulseReleased()
  self:StopAnimation(self.BloodPulse_Press)
  self:StopAnimation(self.BloodPulse_Up)
  self:PlayAnimation(self.BloodPulse_Up)
end

function UMG_HerbologyBadge_AffirmPet_C:OpenPetTips()
  local petData = self.petData
  local uidata = {petData = petData}
  _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, uidata, _G.Enum.GoodsType.GT_PET)
end

function UMG_HerbologyBadge_AffirmPet_C:OnBloodPulse()
  local petData = self.petData
  _G.NRCModeManager:DoCmd(PetUIModuleCmd.OpenPetBloodPulse, petData, TipEnum.OpenPetTipsType.PetWareHouse)
end

function UMG_HerbologyBadge_AffirmPet_C:_InitPanel()
  if self.NRCSwitcher_16 then
    self.NRCSwitcher_16:SetActiveWidgetIndex(0)
  end
  if self.ColorfulHeadIcon then
    self.ColorfulHeadIcon:SetIconPathAndMaterial(self.petData.base_conf_id, self.petData.mutation_type, self.petData.glass_info)
  end
  self.textPetName:SetText(self.petData.name)
  self.textPetLv:SetText(string.format(_G.LuaText.umg_petaltaritem_1, self.petData.level))
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.petData.base_conf_id)
  local petType = petBaseConf and petBaseConf.unit_type or {}
  local commonAttrData1 = {}
  for i = 1, 2 do
    if i <= #petType then
      local typeDic = _G.DataConfigManager:GetTypeDictionary(petType[i])
      if typeDic then
        table.insert(commonAttrData1, {
          Name = typeDic.short_name,
          Path = typeDic.type_icon
        })
      end
    end
  end
  self.Attr1:InitGridView(commonAttrData1)
  local commonAttrData = {}
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.petData.blood_id)
  if PetBloodConf then
    table.insert(commonAttrData, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  if self.Attr then
    self.Attr:InitGridView(commonAttrData)
  end
  self.UMG_CollectBtn:UpdateInfo(self.petData.partner_mark, true)
  local BreakThroughStarsList = PetUtils.GetBreakThroughStarsList(self.petData)
  self.CatchHardLv:InitGridView(BreakThroughStarsList)
  self:_InitFeatureSkill(petBaseConf)
  self:_InitSkill()
  self.Notarize_Btn.TitleCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_HerbologyBadge_AffirmPet_C:_InitFeatureSkill(petBaseConf)
  local skillId, lock = PetUtils.GetPetFeatrueSkillId(petBaseConf)
  if not skillId or 0 == skillId then
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  if not skillCfg then
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if skillCfg.icon then
    self.SkillIcon:SetPath(skillCfg.icon)
  end
  self.SkillNameTxt:SetText(skillCfg.name or "")
  self.NRCTextDes:SetText(skillCfg.desc or "")
end

function UMG_HerbologyBadge_AffirmPet_C:_InitSkill()
  local savedSkillId = self.module.Data.TrialPetInfo.skills[1]
  local skillList = {}
  if savedSkillId then
    local fantasticId
    if self.petData.blood_id == _G.Enum.PetBloodType.PBT_FANTASTIC or self.petData.blood_id == _G.Enum.PetBloodType.PBT_NIGHTMARE then
      for _, skill in ipairs(self.petData.skill.skill_data) do
        if skill.skill_src == _G.Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
          fantasticId = skill.id
          break
        end
      end
    end
    for _, skillData in ipairs(self.petData.skill.skill_data) do
      if skillData.id == savedSkillId then
        local itemData = {}
        table.deepCopy(skillData, itemData)
        itemData.bFantastic = nil ~= fantasticId and fantasticId == skillData.id
        table.insert(skillList, itemData)
        break
      end
    end
    if 0 == #skillList then
      local itemData = {id = savedSkillId}
      itemData.bFantastic = nil ~= fantasticId and fantasticId == savedSkillId
      table.insert(skillList, itemData)
    end
  end
  self.SkillList:InitGridView(skillList)
end

return UMG_HerbologyBadge_AffirmPet_C
