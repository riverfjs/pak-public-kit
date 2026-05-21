local UMG_ShareUI_Photo_C = _G.NRCPanelBase:Extend("UMG_ShareUI_Photo_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_ShareUI_Photo_C:OnConstruct()
  self.module = _G.NRCModuleManager:GetModule("ShareUIModule")
  self:SetChildViews(self.PhotoSub)
end

function UMG_ShareUI_Photo_C:OnActive(data)
  self.data = data
  self.uiItem = {}
  self.uiItem.genderIcons = {
    self.PhotoSub.ImagePetGender1,
    self.PhotoSub.ImagePetGender2
  }
  self.uiItem.skillIcons = {
    self.PhotoSub.skillIcon1,
    self.PhotoSub.skillIcon2,
    self.PhotoSub.skillIcon3,
    self.PhotoSub.skillIcon4
  }
  self.PhotoSub.PetRadarInfo.detailedBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.PhotoSub.UMG_PetImage3D:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:ShowPetInfo()
  self:ShowPlayerInfo()
  self.PhotoSub:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self.PhotoSub.PetRadarInfo:PlayAnimationIn()
end

function UMG_ShareUI_Photo_C:OnDeactive()
end

function UMG_ShareUI_Photo_C:OnAddEventListener()
end

function UMG_ShareUI_Photo_C:ShowPetInfo()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.petData.base_conf_id)
  self:updatePetNature(self.data.petData.nature)
  self:updatePetGender(self.data.petData.gender)
  self:updatePetTypeIcon(petBaseConf.unit_type)
  if self.PhotoSub.PetRadarInfo and self.PhotoSub.PetRadarInfo.updatePetInfo then
    self.PhotoSub.PetRadarInfo:SetIsShowChangeValue(true)
    self.PhotoSub.PetRadarInfo:updatePetInfo(self.data.petData, petBaseConf)
  else
    Log.Error("self.PetRadarInfo or self.PetRadarInfo.updatePetInfo Not Found")
  end
  if utf8.len(self.data.petData.name) ~= nil and utf8.len(self.data.petData.name) > _G.DataConfigManager:GetPetGlobalConfig("pet_name_num_max").num then
    self.data.petData.name = string.sub(self.data.petData.name, 1, string.len(self.data.petData.name) - 3)
  end
  if self.data.petData.name ~= "" then
    if self.data.petData.name ~= nil then
      self.PhotoSub.textPetName:SetText(self.data.petData.name)
    else
      self.PhotoSub.textPetName:SetText(petBaseConf.name)
    end
  else
    self.PhotoSub.textPetName:SetText(petBaseConf.name)
  end
  local BallId = self.data.petData.ball_id
  if 0 == BallId then
    BallId = 100002
  end
  local CurIconPath = _G.DataConfigManager:GetBallConf(BallId).ball_tips_icon
  self.PhotoSub.UMG_PetEvoTip.CurIcon:SetPath(CurIconPath)
  self.PhotoSub.UMG_PetEvoTip.Image_evo:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local specialityId = self.data.petData and self.data.petData.speciality_id
  if specialityId then
    local PetTalentConf = _G.DataConfigManager:GetPetTalentConf(specialityId)
    if PetTalentConf then
      self.PhotoSub.textPetNature_1:SetText(PetTalentConf.name)
    end
  end
  self:SetTalentRank()
  self:SetWeightAndStature()
  self:SetSpecialSign()
  self:ShowMedalIcon()
  self:ShowPetFeatureSkill()
  self:ShowNormalSkill()
  self:ShowPetModel()
  self:ShowPetLevel()
end

function UMG_ShareUI_Photo_C:updatePetNature(_nature)
  local petNatureConf = _G.DataConfigManager:GetNatureConf(_nature)
  if petNatureConf then
    self.PhotoSub.textPetNature:SetText(petNatureConf.name or "")
  end
end

function UMG_ShareUI_Photo_C:updatePetGender(_gender)
  for gender, genderIcon in ipairs(self.uiItem.genderIcons) do
    if _gender == gender then
      genderIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
      genderIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_ShareUI_Photo_C:updatePetTypeIcon(_dicTypes)
  local typeList = {}
  local BloodTypeList = {}
  for i, Type in ipairs(_dicTypes) do
    table.insert(typeList, Type)
  end
  self.PhotoSub.Attr1:InitGridView(typeList)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(self.data.petData.blood_id)
  if PetBloodConf then
    table.insert(BloodTypeList, {
      Name = PetBloodConf.blood_name,
      Path = PetBloodConf.icon
    })
  end
  self.PhotoSub.Attr:InitGridView(BloodTypeList)
end

function UMG_ShareUI_Photo_C:SetTalentRank()
  self.PhotoSub.UMG_PetRate:SetText(self.data.petData)
end

function UMG_ShareUI_Photo_C:SetWeightAndStature()
  if not self.data.petData.weight or not self.data.petData.height then
    return
  end
  local WeightData = self.data.petData.weight * 0.001
  local num = self:GetPreciseDecimal(WeightData, 2)
  self.PhotoSub.TextWeight:SetText(num)
  self.PhotoSub.TextStature:SetText(string.format("%.2f", self.data.petData.height * 0.01))
end

function UMG_ShareUI_Photo_C:GetPreciseDecimal(num, n)
  if type(num) ~= "number" then
    return num
  end
  n = n or 0
  n = math.floor(n)
  if n < 0 then
    n = 0
  end
  local decimal = 10 ^ n
  local temp = math.floor(num * decimal)
  return temp / decimal
end

function UMG_ShareUI_Photo_C:SetSpecialSign()
  self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if PetUtils.CheckIsShiningChaos(self.data.petData.mutation_type) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(6)
  elseif PetUtils.CheckIsCHAOS(self.data.petData.mutation_type) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(2)
  elseif PetUtils.CheckIsHiddenShiningGlass(self.data.petData.mutation_type, self.data.petData.glass_info) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(5)
    local path = self:GetHiddenGlassIcon(true)
    if "" ~= path then
      self.PhotoSub.Nightmare_3:SetPath(path)
    end
  elseif PetUtils.CheckIsShiningGlass(self.data.petData.mutation_type) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(3)
  elseif PetMutationUtils.GetMutationValue(self.data.petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(1)
  elseif PetUtils.CheckIsHiddenGlass(self.data.petData.mutation_type, self.data.petData.glass_info) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(4)
    local path = self:GetHiddenGlassIcon(false)
    if "" ~= path then
      self.PhotoSub.Nightmare_2:SetPath(path)
    end
  elseif PetMutationUtils.GetMutationValue(self.data.petData.mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
    self.PhotoSub.State_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.State_1:SetActiveWidgetIndex(0)
  end
end

function UMG_ShareUI_Photo_C:ShowMedalIcon()
  local _, WearMedal = _G.DataModelMgr.PlayerDataModel:GetMedalListAndWearMedalByPetGid(self.data.petData.gid)
  if WearMedal then
    local medalConf = _G.DataConfigManager:GetMedalConf(WearMedal.conf_id)
    self.PhotoSub.MedaIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PhotoSub.MedaIcon:SetPath(medalConf.big_icon)
  else
    self.PhotoSub.MedaIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_ShareUI_Photo_C:ShowPetFeatureSkill()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.petData.base_conf_id)
  local skillId = petBaseConf.pet_feature
  if 0 == skillId then
    local evolution_pet_id = petBaseConf.evolution_pet_id[1]
    local evoPetbaseCfg = _G.DataConfigManager:GetPetbaseConf(evolution_pet_id)
    if evolution_pet_id then
      skillId = evoPetbaseCfg.pet_feature
    end
  end
  if 0 == skillId then
    return
  end
  local skillCfg = _G.DataConfigManager:GetSkillConf(skillId)
  self.PhotoSub.SkillIcon:SetPath(skillCfg.icon)
  self.PhotoSub.SkillNameTxt:SetText(skillCfg.name)
end

function UMG_ShareUI_Photo_C:ShowNormalSkill()
  local skillList = {}
  local equipSkills = PetUtils.GetPetEquipSkills(self.data.petData)
  for i = 1, #equipSkills do
    if equipSkills[i] then
      table.insert(skillList, equipSkills[i])
    end
  end
  self.PhotoSub.Skill:InitGridView(skillList)
end

function UMG_ShareUI_Photo_C:ShowPlayerInfo()
  local playerInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info
  self.PhotoSub.Grade:SetText(playerInfo.name)
  self.PhotoSub.Grade_1:SetText("UID:" .. playerInfo.uin)
  local cardInfo = playerInfo.additional_data.card_brief_info
  if cardInfo then
    local cardIconConf = _G.DataConfigManager:GetCardIconConf(cardInfo.card_icon_selected)
    if cardIconConf then
      local avatarPath = cardIconConf.icon_resource_path
      avatarPath = string.format("%s%s.%s'", "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/HeadIcon/", avatarPath, avatarPath)
      self.PhotoSub.HeadPortrait:SetPath(avatarPath)
    end
  end
end

function UMG_ShareUI_Photo_C:ShowPetModel()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.data.petData.base_conf_id)
  local scale, offset, rotate
  local scaleConf = _G.DataConfigManager:GetGlobalConfig("share_image_zoom")
  if scaleConf and scaleConf.str then
    scale = tonumber(scaleConf.str)
  end
  local offsetConf = _G.DataConfigManager:GetGlobalConfig("share_image_move")
  if offsetConf and offsetConf.numList then
    offset = UE4.FVector(offsetConf.numList[1], offsetConf.numList[2], offsetConf.numList[3])
  end
  local rotateConf = _G.DataConfigManager:GetGlobalConfig("share_image_rotation")
  if rotateConf and rotateConf.numList then
    rotate = UE4.FRotator(rotateConf.numList[1], rotateConf.numList[2], rotateConf.numList[3])
  end
  local data = {
    petBaseConf = petBaseConf,
    scale = scale,
    offset = offset,
    rotate = rotate,
    petData = self.data.petData
  }
  self:ShowPetImage3D(data)
end

function UMG_ShareUI_Photo_C:ShowPetImage3D(data)
  self.PhotoSub.UMG_PetImage3D:OnActive(data.petBaseConf, "PetInfoMain")
  self.PhotoSub.UMG_PetImage3D:InitPetShareData(data.scale, data.offset, data.rotate)
  local modelConf = _G.DataConfigManager:GetModelConf(data.petBaseConf.model_conf)
  if modelConf then
    self.PhotoSub.UMG_PetImage3D.PetBaseConf = data.petBaseConf
    self.PhotoSub.UMG_PetImage3D:SetPath(modelConf.path, nil, nil, data.petData, false)
    self.PhotoSub.UMG_PetImage3D.isEgg = false
  end
end

function UMG_ShareUI_Photo_C:ShowPetLevel()
  self.PhotoSub.Level:SetText(self.data.petData.level)
end

function UMG_ShareUI_Photo_C:GetHiddenGlassIcon(bShiningGlass)
  if self.data.petData and self.data.petData.glass_info then
    local HiddenGlassID = self.data.petData.glass_info.glass_value
    if HiddenGlassID then
      local HiddenGlassConf = _G.DataConfigManager:GetHiddenGlassConf(HiddenGlassID)
      if HiddenGlassConf then
        if bShiningGlass and HiddenGlassConf.yise_icon then
          return HiddenGlassConf.yise_icon
        elseif HiddenGlassConf.icon then
          return HiddenGlassConf.icon
        end
      end
    end
  end
  return ""
end

function UMG_ShareUI_Photo_C:PlayInAnim()
  self:StopAllAnimations()
  self:PlayAnimation(self.In_Photo)
end

function UMG_ShareUI_Photo_C:PlayOutAnim()
  self:StopAllAnimations()
  self:PlayAnimation(self.Out)
end

function UMG_ShareUI_Photo_C:OnAnimationFinished(Animation)
  if Animation == self.In_Photo then
    self:PlayAnimation(self.loop)
  elseif Animation == self.loop then
    self:PlayAnimation(self.loop)
  end
end

function UMG_ShareUI_Photo_C:ShowPlayerInfoPanel(isShow)
  if isShow then
    self.PhotoSub.PersonalInformation:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.PersonalInformation:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_ShareUI_Photo_C
