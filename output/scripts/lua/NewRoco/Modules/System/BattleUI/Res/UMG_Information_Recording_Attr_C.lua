local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Modules.System.TipsModule.Utils.UIUtils")
local SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UMG_Information_Recording_Attr_C = Base:Extend("UMG_Information_Recording_Attr_C")

function UMG_Information_Recording_Attr_C:OnConstruct()
  self.Desc.OnRichTextClick:Clear()
  self.Desc.OnRichTextClick:Add(self, self.OnDescTextClicked)
  self.CloseHyperlink.OnClicked:Clear()
  self.CloseHyperlink.OnClicked:Add(self, self.OnCloseHyperLink)
end

function UMG_Information_Recording_Attr_C:OnDestruct()
end

function UMG_Information_Recording_Attr_C:GetPetInfo(petInfos, id)
  if petInfos then
    for _, v in ipairs(petInfos) do
      if v.pet_id == id then
        return v
      end
    end
  end
end

function UMG_Information_Recording_Attr_C:GetPetId(data)
  if data.type == ProtoEnum.BattleOpRecord.RoundOpType.TYPE_SKILL then
    return data.skill_op.caster
  else
    return data.change_pet_op.down_pet
  end
end

function UMG_Information_Recording_Attr_C:OnItemUpdate(itemData, datalist, index)
  local _data = itemData and itemData.record
  local currentDisplayRoundIsTheLatest = itemData and itemData.currentDisplayRoundIsTheLatest
  local testIcon = "Texture2D'/Game/NewRoco/Modules/System/BattleUI/Raw/Atlas/SkillIcon/btn_kongzhi.btn_kongzhi'"
  self.descText = ""
  if _G.GlobalConfig.DebugOpenUI then
    self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(testIcon, _G.UIIconPath.SkillIconPath))
    return
  end
  self.index = index
  if _data and _data.selfPet then
    local petInfo = _data.selfPet
    local battleCard = _G.BattleManager.battlePawnManager:GetCardByGuid(petInfo.pet_id)
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    if _data.type == ProtoEnum.BattleOpRecord.RoundOpType.TYPE_SKILL then
      self.Switcher:SetActiveWidgetIndex(0)
      local skillData = _data.skill_op
      local skillConf = _G.SkillUtils.GetSkillConf(skillData.skill_id)
      local targetCard = _G.BattleManager.battlePawnManager:GetCardByGuid(skillData.target)
      if skillConf and skillConf.type == Enum.SkillActiveType.SAT_BOSS_SKILL then
        self.CanvasPanel_Boss:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.boss_skill:SetPath(NRCUtils:FormatConfIconPath(skillConf.icon, _G.UIIconPath.SkillIconPath))
        self.boss_skill:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.Switcher:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.CanvasPanel_Boss:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.boss_skill:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.Switcher:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
      local petCard = BattleManager.battlePawnManager:GetCardByGuid(petInfo.pet_id)
      if currentDisplayRoundIsTheLatest and petCard and petCard.petState:GetGather() then
        local fakeSkillId = SkillUtils.GetGatherFakeSkillId()
        skillConf = SkillUtils.GetSkillConf(fakeSkillId)
      end
      if skillConf then
        self.SkillIcon:SetPath(NRCUtils:FormatConfIconPath(skillConf.icon, _G.UIIconPath.SkillIconPath))
        local fantasticBackgroundPath = ""
        local skillOp = _data and _data.skill_op
        local performFlag = skillOp and skillOp.perform_flag
        local skillOpSkillId = skillOp and skillOp.skill_id
        local petId = battleCard and battleCard.guid
        local seasonId = skillOp and skillOp.season_id
        if performFlag == _G.ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_FANTASTIC then
          local skillId = skillOpSkillId and _G.SkillUtils.CheckSkillId(skillOpSkillId)
          local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, seasonId)
          fantasticBackgroundPath = paths and paths.squareNm3 or fantasticBackgroundPath
        end
        local selectNm3Visibility = UE4.ESlateVisibility.Collapsed
        if not string.IsNilOrEmpty(fantasticBackgroundPath) then
          selectNm3Visibility = UE4.ESlateVisibility.SelfHitTestInvisible
        end
        self.Select_NM_3:SetPath(fantasticBackgroundPath)
        self.Select_NM_3:SetVisibility(selectNm3Visibility)
        self.TxtSkillName:SetText(skillConf.name)
        self.descText = skillConf.desc
        self.Desc:SetText(skillConf.desc)
        self.Desc:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local skillType = skillConf.skill_dam_type
        if _data then
          local extraDamageTypes = SkillUtils.GetUniqueExtraDamageTypes(_data.skill_op.extra_damage_type)
          skillType = extraDamageTypes[1] or skillType
        end
        local typeDic = _G.DataConfigManager:GetTypeDictionary(skillType)
        if not typeDic or typeDic.type_icon then
        else
        end
        if skillData.cost_hp and skillData.cost_hp > 0 then
          self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.StarImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
          self.RoleHPImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.SkillNengNum:SetText(string.format("<white>%d</>", math.abs(skillData.cost_hp)))
        elseif skillData.cost_energy and skillData.cost_energy > 0 then
          self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.StarImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.RoleHPImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
          local cost = math.abs(skillData.cost_energy)
          if cost > skillConf.energy_cost[1] then
            self.SkillNengNum:SetText(string.format("<red>%d</>", skillData.cost_energy))
          elseif cost == skillConf.energy_cost[1] then
            self.SkillNengNum:SetText(string.format("<black>%d</>", skillData.cost_energy))
          else
            self.SkillNengNum:SetText(string.format("<pow_green>%d</>", skillData.cost_energy))
          end
        else
          self.Canvasnenliang:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        local Name
        if skillConf.damage_type ~= ProtoEnum.DamageType.DT_NONE then
          if skillData.damage_param > skillConf.dam_para[1] then
            Name = skillData.damage_param
          elseif skillData.damage_param == skillConf.dam_para[1] then
            Name = skillData.damage_param
          else
            Name = skillData.damage_param
          end
          if not BattleUtils.IsPartialShow(targetCard) and _data.skill_op.restraint_param then
            self.NRCButton_85:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            local restraintResult = _data.skill_op.restraint_param
            if restraintResult == ProtoEnum.SkillRestraintType.SRT_NONE then
              self.EffectSwitcher:SetActiveWidgetIndex(1)
            elseif restraintResult == ProtoEnum.SkillRestraintType.SRT_RESTRAINT_ONE then
              self.EffectSwitcher:SetActiveWidgetIndex(0)
            elseif restraintResult == ProtoEnum.SkillRestraintType.SRT_RESTRAINTED_ONE then
              self.EffectSwitcher:SetActiveWidgetIndex(2)
            elseif restraintResult > 0 then
              self.EffectSwitcher:SetActiveWidgetIndex(3)
            elseif restraintResult < 0 then
              self.EffectSwitcher:SetActiveWidgetIndex(4)
            end
          else
            self.NRCButton_85:SetVisibility(UE4.ESlateVisibility.Collapsed)
          end
        else
          Name = "-"
          self.NRCButton_85:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
        local tipsRes = typeDic and typeDic.tips_res
        if Enum.SkillDamType.SDT_RELAX ~= skillType and tipsRes then
          local typeList = {
            {Name = Name, Path = tipsRes}
          }
          self.Attr1:InitGridView(typeList)
          self.Attr1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        else
          self.Attr1:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      end
      local damageType = skillData.adapt_damage_type or skillConf.damage_type
      if skillConf then
        if string.IsNilOrEmpty(skillConf.Skill_Type) or skillConf.Skill_Type == ProtoEnum.SkillType.ST_NONE then
          self.SkillTypeParent:SetVisibility(UE4.ESlateVisibility.Collapsed)
        else
          self.SkillTypeParent:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          local text, ImagePath = BattleUtils.GetSkillTypePath(skillConf.Skill_Type, damageType)
          self.DepartmentText:SetText(text)
          self.SkillTypeIcon1:SetPath(ImagePath)
        end
      end
      if petCard and petCard.petState:GetMimic() then
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self.PetIconBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
        self.PetIconBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local uiParam
        if petCard then
          uiParam = self.HeadIcon:PrepareUIParam(petCard.petInfo.battle_inside_pet_info)
        end
        self.HeadIcon:SetIconPathAndMaterial(petInfo.pet_base_id, petInfo.mutation, petInfo.glass_info, nil, uiParam)
      end
      if BattleUtils.IsTeam() and battleCard and battleCard.owner.teamEnm == BattleEnum.Team.ENUM_TEAM then
        local pos = battleCard.owner.TeamNumber
        self.NRCSwitcher_37:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        if 1 == pos then
          self.NRCSwitcher_37:SetActiveWidgetIndex(0)
          self.NRCText_0:SetText(string.format("%dP", pos))
        else
          self.NRCSwitcher_37:SetActiveWidgetIndex(1)
          self.ArrangeText:SetText(string.format("%dP", pos))
        end
      else
        self.NRCSwitcher_37:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if skillData.is_defeat then
        self.Defeat:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      else
        self.Defeat:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    else
      self.Switcher:SetActiveWidgetIndex(1)
      local changeData = _data.change_pet_op
      local upPet = BattleManager.battlePawnManager:GetPetByGuid(changeData.up_pet)
      local UpCard = self:GetPetInfo(_data.petInfos, changeData.up_pet)
      local DownCard = self:GetPetInfo(_data.petInfos, changeData.down_pet)
      if UpCard then
        if upPet and upPet.card:CheckIsMimic() then
          self.Icon_1:SetIconPath(upPet.card.icon)
        else
          self.Icon_1:SetIconPathAndMaterial(UpCard.pet_base_id, UpCard.mutation, UpCard.glass_info)
        end
        self.NumText_1:SetText(UpCard.level)
        local petBase = _G.DataConfigManager:GetPetbaseConf(UpCard.pet_base_id)
        self.BGColor_1:SetPath(UEPath.PROP_QUALITY_NONE1)
      end
      if DownCard then
        self.Icon:SetIconPathAndMaterial(DownCard.pet_base_id, DownCard.mutation, DownCard.glass_info)
        self.NumText:SetText(DownCard.level)
        local petBase = _G.DataConfigManager:GetPetbaseConf(DownCard.pet_base_id)
        self.BGColor:SetPath(UEPath.PROP_QUALITY_NONE1)
      end
    end
    if _data.HideDivider then
      self.Divider_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Divider:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
      self.Divider_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.Divider:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Information_Recording_Attr_C:OnCloseHyperLink()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.InformationRecordingCloseHyperLink)
end

function UMG_Information_Recording_Attr_C:OnDescTextClicked(id)
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.InformationRecordingHyperLinkClick, self.descText, self.index)
end

function UMG_Information_Recording_Attr_C:OnItemSelected(_bSelected)
end

function UMG_Information_Recording_Attr_C:OpenHyperLinkState(_bSelected)
  self.CloseHyperlink:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Information_Recording_Attr_C:CloseHyperLinkState(_bSelected)
  self.CloseHyperlink:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

return UMG_Information_Recording_Attr_C
