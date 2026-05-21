local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local enum = reload("Data.Config.Enum")
local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_PetSkillItem_C = Base:Extend("UMG_PetSkillItem_C")
local SELECT_BG_COLOR = UE4.UNRCStatics.HexToLinearColor("F4EFE0FF")
local UNSELECT_BG_COLOR = UE4.UNRCStatics.HexToLinearColor("1E1E21FF")

function UMG_PetSkillItem_C:Initialize(Initializer)
  Log.Debug("UMG_PetSkillItem_C:Initialize")
  self.petUIModule = _G.NRCModuleManager:GetModule("PetUIModule")
  self.petUIModule:RegisterEvent(self, PetUIModuleEvent.RemoveSkillNewState, self.RemoveSkillNewState)
end

function UMG_PetSkillItem_C:OnConstruct()
  self.FirstOpen = true
  Log.Debug("UMG_PetSkillItem_C:OnConstruct")
  _G.NRCEventCenter:RegisterEvent("UMG_PetSkillItem_C", self, PetUIModuleEvent.OnPetAssumptionEquipSkillChange, self.OnPetAssumptionEquipSkillChange)
end

function UMG_PetSkillItem_C:OnDestruct()
  Log.Debug("UMG_PetSkillItem_C:OnDestruct")
  self.petUIModule:UnRegisterEvent(self, PetUIModuleEvent.RemoveSkillNewState, self.RemoveSkillNewState)
  _G.NRCEventCenter:UnRegisterEvent(self, PetUIModuleEvent.OnPetAssumptionEquipSkillChange, self.OnPetAssumptionEquipSkillChange)
  self:CancelDelaAnim()
  self.NrcRedPoint:UnRegister()
  if self.DelayHandle then
    _G.DelayManager:CancelDelayById(self.DelayHandle)
    self.DelayHandle = nil
  end
  local loadCloudNor4MaskRequest = self.loadCloudNor4MaskRequest
  if loadCloudNor4MaskRequest then
    _G.NRCResourceManager:UnLoadRes(loadCloudNor4MaskRequest)
  end
end

function UMG_PetSkillItem_C:OnEnable()
  Log.Debug("UMG_PetSkillItem_C:OnEnable")
end

function UMG_PetSkillItem_C:OnDisable()
end

function UMG_PetSkillItem_C:OnItemUpdate(data, datalist, index)
  self:ResetItem()
  self.bIsAccessGrantedSkill = false
  self.data = data
  self.index = index
  self.selected = false
  self.bFantastic = false
  if data.petData then
    self.bFantastic = data.petData.blood_id == Enum.PetBloodType.PBT_FANTASTIC and data.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD
  end
  if self.NRCImageNor_3 then
    self.NRCImageNor_3:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if 1 == data.mode and not self.data.skillData.is_learned then
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif -1 == data.mode then
    if self.NRCImageNor_3 then
      self.NRCImageNor_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  self:UpdateItemInfo()
  self:CancelDelaAnim()
  if data.delayPlayAnim then
    self.DelayId = _G.DelayManager:DelayFrames(3, function()
      if self.selected then
        self:PlaySelectIn()
      else
        self:PlayFadeIn()
      end
    end)
  else
    self:PlayFadeIn()
  end
end

function UMG_PetSkillItem_C:CancelDelaAnim()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_PetSkillItem_C:UpdateItemInfo()
  self.skillConfig = nil
  local isEquip = false
  if self.data.skillData then
    local skillConf = _G.DataConfigManager:GetSkillConf(self.data.skillData.id)
    self.skillConfig = skillConf
    if skillConf then
      self.SkillNameTxt:SetText(skillConf.name)
      self.SkillIcon:SetPath(skillConf.icon)
      self.SkillNengNum:SetText(skillConf.energy_cost[1])
      local Name
      if skillConf.damage_type == enum.DamageType.DT_NONE then
        Name = "--"
      else
        Name = skillConf.dam_para[1]
      end
      local typeDic = _G.DataConfigManager:GetTypeDictionary(skillConf.skill_dam_type)
      if typeDic then
        local typeList = {
          {
            Name = Name,
            Path = typeDic.tips_res
          }
        }
        if UE4.UObject.IsValid(self.Attr) then
          self.Attr:InitGridView(typeList)
          local attrItem = self.Attr:GetItemByIndex(0)
          if attrItem then
            attrItem:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
          end
          self.Attr:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        end
      end
      local pos = self.data.skillData.pos
      if self.data.herbologyBadgeLockedSkillId then
        if self.data.skillData.id == self.data.herbologyBadgeLockedSkillId then
          self.OrderBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Number:SetText(1)
        else
          self.OrderBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      elseif self.data.skillData.is_equipped and pos >= 1 and pos <= 4 and pos then
        self.OrderBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Number:SetText(pos)
        isEquip = true
      else
        self.OrderBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.data.skillData.is_learned or self.data.skillData.onlyShow then
        self.Lock:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.nengliang_Mask:SetVisibility(UE4.ESlateVisibility.Collapsed)
        if UE4.UObject.IsValid(self.Attr) then
          self.Attr:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
        self.CanvasPanel_0:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.SkillNameTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
      else
        self.Lock:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.nengliang_Mask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if UE4.UObject.IsValid(self.Attr) then
          self.Attr:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        self.SkillNameTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("929086FF"))
        self.skilLockTxt_1:SetText(LuaText.goods_unlock_tips)
      end
      self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.skillNorPlane:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.OrderBox:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:UpdateAccessGrantedState()
  self:SetSelectedSate(isEquip)
  self:SetOnNewState()
  self:ShowBeastSkill()
  self:RefreshFantasticSkillImages()
end

function UMG_PetSkillItem_C:SetSelectedSate(isSelected)
  self.isEquipSelected = isSelected
  local visState = isSelected and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Hidden
  if 0 == self.data.mode then
  end
  local bgColor = isSelected and 1 == self.data.mode and SELECT_BG_COLOR or UNSELECT_BG_COLOR
  if self.NRCImageNor_3 then
    self.NRCImageNor_3:SetColorAndOpacity(bgColor)
  end
  if -1 == self.data.mode and self.NRCImageNor_3 then
    self.NRCImageNor_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.SkillShuIcon_bg then
    self.SkillShuIcon_bg:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local textColor = isSelected and 1 == self.data.mode and "#272727FF" or "#F4EEE1FF"
  if self.bIsAccessGrantedSkill then
    textColor = "#D56C1FFF"
  end
  if self.data.skillData and self.data.skillData.is_learned then
    self.SkillNameTxt:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(textColor))
  end
end

function UMG_PetSkillItem_C:SetOnNewState()
  if self.data.skillData and self.data.skillData.onlyShow then
    self.NrcRedPoint:SetupKey(0)
    self.NrcRedPoint:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.data.petData then
    local gid = self.data.petData.gid
    local skilldata = self.data.skillData
    local id = skilldata.id
    local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
    if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
      self.NrcRedPoint:SetupKey(0)
    else
      self.NrcRedPoint:SetupKey(133, {gid, id})
    end
  end
end

function UMG_PetSkillItem_C:SetOnNewStateRemove()
  if self.data.petData and self.data.skillData and self.NrcRedPoint and self.NrcRedPoint:IsRed() then
    self.NrcRedPoint:EraseRedPoint()
  end
end

function UMG_PetSkillItem_C:ShowBeastSkill()
  if self.NrcRedPoint:IsRed() then
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local skillData = self.data.skillData
  if skillData and skillData.type == Enum.SkillActiveType.SAT_LEGENDARY then
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.BeastSkill:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PetSkillItem_C:RefreshFantasticSkillImages()
  local data = self.data
  local skillData = data and data.skillData
  local isNightmare = data and data.isNightmare
  local skillSrc = skillData and skillData.skill_src
  local isPnssPetBlood = skillSrc == Enum.PetNewSkillSrc.PNSS_PET_BLOOD
  local isFantastic = self.bFantastic or false
  if isFantastic or isNightmare and isPnssPetBlood then
    local skillId = skillData and skillData.id
    local season_id = skillData and skillData.season_id
    local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, season_id)
    local cloudNm3 = paths and paths.cloudNm3
    local cloudNm5 = paths and paths.cloudNm5
    local cloudNor4 = paths and paths.cloudNor4
    local cloudNor4Mask = paths and paths.cloudNor4Mask
    local cloudNor4MaskUTiling = paths and paths.cloudNor4MaskUTiling
    local cloudNor4MaskVTiling = paths and paths.cloudNor4MaskVTiling
    local cloudNor4MaskUSpeed = paths and paths.cloudNor4MaskUSpeed
    local cloudNor4MaskVSpeed = paths and paths.cloudNor4MaskVSpeed
    local cloudNor5 = paths and paths.cloudNor5
    if cloudNm3 then
      self.Select_NM_3:SetPath(cloudNm3)
    end
    if cloudNm5 then
      self.Select_NM_5:SetPath(cloudNm5)
    end
    local NRCImageNor_4 = self.NRCImageNor_4
    if cloudNor4 and UE.UObject.IsValid(NRCImageNor_4) then
      NRCImageNor_4:SetPath(cloudNor4)
      local dynamicMaterial = NRCImageNor_4:GetDynamicMaterial()
      if UE.UObject.IsValid(dynamicMaterial) then
        if cloudNor4MaskUTiling then
          dynamicMaterial:SetScalarParameterValue("MaskU_Tiling", cloudNor4MaskUTiling)
        end
        if cloudNor4MaskVTiling then
          dynamicMaterial:SetScalarParameterValue("MaskV_Tiling", cloudNor4MaskVTiling)
        end
        if cloudNor4MaskUSpeed then
          dynamicMaterial:SetScalarParameterValue("MaskU_Speed", cloudNor4MaskUSpeed)
        end
        if cloudNor4MaskVSpeed then
          dynamicMaterial:SetScalarParameterValue("MaskV_Speed", cloudNor4MaskVSpeed)
        end
      end
    end
    if cloudNor4Mask then
      local loadCloudNor4MaskRequest = _G.NRCResourceManager:LoadResAsync(self, cloudNor4Mask, 255, -1, function(caller, resRequest, asset)
        self:OnLoadCloudNor4MaskComplete(true, asset)
      end, function(caller, resRequest, errorMessage)
        self:OnLoadCloudNor4MaskComplete(false, errorMessage)
      end, nil)
      self.loadCloudNor4MaskRequest = loadCloudNor4MaskRequest
    end
    if cloudNor5 then
      self.NRCImageNor_5:SetPath(cloudNor5)
    end
  end
end

function UMG_PetSkillItem_C:OnLoadCloudNor4MaskComplete(ok, res1)
  local asset, errorMessage
  if ok then
    asset = res1
  else
    errorMessage = res1
    Log.Error("UMG_PetSkillItem_C:OnLoadCloudNor4MaskComplete load failed", errorMessage)
  end
  local NRCImageNor_4 = self.NRCImageNor_4
  if UE.UObject.IsValid(NRCImageNor_4) then
    local dynamicMaterial = NRCImageNor_4:GetDynamicMaterial()
    if UE.UObject.IsValid(dynamicMaterial) and UE.UObject.IsValid(asset) then
      dynamicMaterial:SetTextureParameterValue("Mask_Texture", asset)
    end
  end
end

function UMG_PetSkillItem_C:RemoveSkillNewState(gid, skillid)
  if self.data and self.data.petData and self.data.skillData and self.NRCImage_new.Visibility == UE4.ESlateVisibility.Visible then
    local petgid = self.data.petData.gid
    local id = self.data.skillData.id
    if petgid == gid and id == skillid then
      self.NRCImage_new:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_PetSkillItem_C:OnSelectSkill(_skillData)
end

function UMG_PetSkillItem_C:OnPetAssumptionEquipSkillChange(poToSkillIdDic, skillIdToPosDic, index)
  if index and self.index ~= index then
    return
  end
  local _skillDic = skillIdToPosDic
  local data = self.data
  if data and data.skillData then
    if _skillDic and _skillDic[data.skillData.id] then
      self.data.skillData.is_equipped = true
      self.data.skillData.pos = _skillDic[data.skillData.id]
      if not data.herbologyBadgeLockedSkillId then
        self.OrderBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Number:SetText(_skillDic[data.skillData.id])
      end
      self:SetSelectedSate(true)
    else
      self.data.skillData.is_equipped = false
      self.data.skillData.pos = 0
      if not data.herbologyBadgeLockedSkillId then
        self.OrderBox:SetVisibility(UE4.ESlateVisibility.Hidden)
      end
      self:SetSelectedSate(false)
    end
  end
end

function UMG_PetSkillItem_C:OnItemSelectedByClick()
  if not self.data then
    Log.Error("UMG_PetSkillItem \231\154\132data\228\184\186\231\169\186")
    return
  end
  if not UE4.UObject.IsValid(self.Object) then
    Log.Error("UMG_PetSkillItem \231\154\132object\228\184\186\231\169\186")
    return
  end
  self:SetOnNewStateRemove()
  self:ShowBeastSkill()
  if 0 == self.data.mode then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.SelectSkill, self.data.skillData)
  elseif 1 == self.data.mode then
    _G.NRCEventCenter:DispatchEvent(PetUIModuleEvent.EquipSkill, self.data.skillData, self.index)
  end
end

function UMG_PetSkillItem_C:OnItemSelected(selected, _bScroll)
  if not self.data then
    Log.Error("UMG_PetSkillItem \231\154\132data\228\184\186\231\169\186")
    return
  end
  if not UE4.UObject.IsValid(self.Object) then
    Log.Error("UMG_PetSkillItem \231\154\132object\228\184\186\231\169\186")
    return
  end
  if selected then
    self:StopAllAnimations()
    if 0 == self.data.mode then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40002003, "UMG_PetBaseInfo_C:OnBtnLevelUpClick")
      self:PlaySelectIn()
    elseif 1 == self.data.mode then
      self:PlaySelectIn()
    elseif -1 == self.data.mode then
      self.petUIModule:DispatchEvent(PetUIModuleEvent.OpenOrCloseSkillTipsPanel, true)
      self.petUIModule:DispatchEvent(PetUIModuleEvent.SelectEmptySkill)
    end
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.CloseMoreList, false)
  else
    self:StopAllAnimations()
    if 0 == self.data.mode then
      self:PlaySelectOut()
    elseif -1 == self.data.mode then
    else
      self:PlaySelectOut()
    end
  end
end

function UMG_PetSkillItem_C:OnAnimationFinished(InAnimation)
  if InAnimation == self.NM_press then
    self:PlayAnimation(self.NM_loop, 0, 0)
  elseif InAnimation == self.Select_In_2 then
    self:PlayAnimation(self.Select_Loop_3, 0, 0)
  end
end

function UMG_PetSkillItem_C:PlaySelectIn()
  if self.data.isNightmare then
    if self.data.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      self:PlayAnimation(self.Select_In_2)
    else
      self:PlayAnimation(self.NM_press)
    end
  elseif self.bFantastic then
    self:PlayAnimation(self.Select_In_2)
  else
    self.NRCImageNor:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.Select_In)
  end
  self.selected = true
end

function UMG_PetSkillItem_C:PlaySelectOut()
  if self.data.isNightmare then
    if self.data.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      self:PlayAnimation(self.Select_Out_4)
    else
      self:PlayAnimation(self.NM_normal)
    end
  elseif self.bFantastic then
    self:PlayAnimation(self.Select_Out_4)
  else
    self:PlayAnimation(self.Select_Out)
  end
  self.selected = false
end

function UMG_PetSkillItem_C:PlayFadeIn()
  if self.data.isNightmare then
    if self.data.skillData and self.data.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      self:PlayAnimation(self.NM_in_2)
    else
      self:PlayAnimation(self.NM_in)
    end
  elseif self.bFantastic then
    self:PlayAnimation(self.NM_in_2)
  else
    self.NRCImageNor:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:PlayAnimation(self.JiNeng_In)
  end
end

function UMG_PetSkillItem_C:OnDespawn()
  if self.data and self.data.isNightmare then
    if self.data.skillData.skill_src == Enum.PetNewSkillSrc.PNSS_PET_BLOOD then
      self:PlayAnimation(self.Select_normal_1)
    else
      self:PlayAnimation(self.NM_in)
    end
  elseif self.bFantastic then
    self:PlayAnimation(self.Select_normal_1)
  else
    self:PlayAnimation(self.JiNeng_Normal)
  end
end

function UMG_PetSkillItem_C:UpdateAccessGrantedState()
  if not self.AccessGranted then
    return
  end
  self.AccessGranted:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if not (self.data and self.data.petData) or not self.data.skillData then
    return
  end
  local friendInfo = _G.NRCModuleManager:DoCmd(_G.PetUIModuleCmd.GetFriendInfoToPetMain)
  if friendInfo and friendInfo.type ~= _G.ProtoEnum.PlayerRelationshipType.PRT_SELF then
    return
  end
  local currentSkillData = self.data.skillData
  if not currentSkillData.is_learned then
    return
  end
  local gid = self.data.petData.gid
  local originalPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(gid)
  if not (originalPetData and originalPetData.skill) or not originalPetData.skill.skill_data then
    return
  end
  local skillId = currentSkillData.id
  local originalSkillLearned = false
  for _, originalSkill in pairs(originalPetData.skill.skill_data) do
    if originalSkill.id == skillId then
      originalSkillLearned = originalSkill.is_learned
      break
    end
  end
  if currentSkillData.is_learned and not originalSkillLearned then
    self.AccessGranted:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.bIsAccessGrantedSkill = true
  end
end

function UMG_PetSkillItem_C:ResetItem()
  self:StopAllAnimations()
end

return UMG_PetSkillItem_C
