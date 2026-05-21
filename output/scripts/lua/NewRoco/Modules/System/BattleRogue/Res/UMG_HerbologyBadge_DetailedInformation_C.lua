local PetUtils = require("NewRoco.Utils.PetUtils")
local UMG_HerbologyBadge_DetailedInformation_C = _G.NRCPanelBase:Extend("UMG_HerbologyBadge_DetailedInformation_C")

function UMG_HerbologyBadge_DetailedInformation_C:OnActive()
  self.data = self.module.Data
  self.petData = self.data.TrialPetInfo
  self:OnAddEventListener()
  self:InitPanel()
end

function UMG_HerbologyBadge_DetailedInformation_C:OnDeactive()
end

function UMG_HerbologyBadge_DetailedInformation_C:OnAddEventListener()
  self:AddButtonListener(self.CloseBtn.btnClose, self.OnCloseButtonClicked)
end

function UMG_HerbologyBadge_DetailedInformation_C:OnCloseButtonClicked()
  self:DoClose()
end

function UMG_HerbologyBadge_DetailedInformation_C:InitPanel()
  local fullPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.petData.pet_gid)
  if not fullPetData then
    return
  end
  local petbaseConf = _G.DataConfigManager:GetPetbaseConf(fullPetData.base_conf_id)
  if petbaseConf then
    self.textPetName:SetText(petbaseConf.name)
  end
  self.textPetLv:SetText(string.format(_G.LuaText.umg_petskilltemple2_1, self.petData.level))
  local BreakThroughStarsList = PetUtils.GetBreakThroughStarsList(fullPetData)
  if BreakThroughStarsList then
    self.CatchHardLv:InitGridView(BreakThroughStarsList)
  end
  local commonAttrData1 = {}
  local petType = petbaseConf and petbaseConf.unit_type or {}
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
  if self.Attr1 then
    self.Attr1:InitGridView(commonAttrData1)
  end
  local attrInfo = fullPetData.attribute_info
  if attrInfo and self.AttrList then
    local attrDefs = {
      {
        attrEnum = _G.Enum.AttributeType.AT_HPMAX,
        protoEnum = ProtoEnum.AttributeType.AT_HPMAX,
        attrData = attrInfo.hp,
        aptitudeName = LuaText.umg_petdetailedinfo_2
      },
      {
        attrEnum = _G.Enum.AttributeType.AT_SPEED,
        protoEnum = ProtoEnum.AttributeType.AT_SPEED,
        attrData = attrInfo.speed,
        aptitudeName = LuaText.umg_petdetailedinfo_7
      },
      {
        attrEnum = _G.Enum.AttributeType.AT_PHYATK,
        protoEnum = ProtoEnum.AttributeType.AT_PHYATK,
        attrData = attrInfo.attack,
        aptitudeName = LuaText.umg_petdetailedinfo_3
      },
      {
        attrEnum = _G.Enum.AttributeType.AT_SPEATK,
        protoEnum = ProtoEnum.AttributeType.AT_SPEATK,
        attrData = attrInfo.special_attack,
        aptitudeName = LuaText.umg_petdetailedinfo_4
      },
      {
        attrEnum = _G.Enum.AttributeType.AT_PHYDEF,
        protoEnum = ProtoEnum.AttributeType.AT_PHYDEF,
        attrData = attrInfo.defense,
        aptitudeName = LuaText.umg_petdetailedinfo_5
      },
      {
        attrEnum = _G.Enum.AttributeType.AT_SPEDEF,
        protoEnum = ProtoEnum.AttributeType.AT_SPEDEF,
        attrData = attrInfo.special_defense,
        aptitudeName = LuaText.umg_petdetailedinfo_6
      }
    }
    local attrList = {}
    for _, def in ipairs(attrDefs) do
      local conf = _G.DataConfigManager:GetAttributeConf(def.attrEnum)
      local attrName = conf and conf.attribute_name or ""
      local iconPath = conf and conf.attribute_icon or ""
      local attrValue = PetUtils.GetPetAdditionalByType(fullPetData, def.protoEnum)
      table.insert(attrList, {
        bShowIcon = true,
        text = attrName,
        value = attrValue,
        iconPath = iconPath
      })
      local totalAptitude = 0
      if def.attrData then
        totalAptitude = (def.attrData.total_race or 0) + (def.attrData.talent or 0)
      end
      table.insert(attrList, {
        bShowIcon = false,
        text = def.aptitudeName,
        value = totalAptitude
      })
    end
    self.AttrList:InitList(attrList)
  end
  local petNatureConf = _G.DataConfigManager:GetNatureConf(fullPetData.nature)
  if petNatureConf then
    self.textPetNature:SetText(petNatureConf.name or "")
  end
  if self.Character then
    if 0 ~= fullPetData.changed_nature_neg_attr_type or 0 ~= fullPetData.changed_nature_pos_attr_type then
      self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_lailang_png.img_lailang_png'")
    else
      self.Character:SetPath("PaperSprite'/Game/NewRoco/Modules/System/PetUI/Raw/Atlas/PetUI/Frames/img_character_png.img_character_png'")
    end
  end
  local curHp = self.petData.current_hp or 0
  local maxHp = self.petData.max_hp or 1
  self.textPetExp:SetText(string.format("%d/%d", curHp, maxHp))
  if maxHp > 0 then
    self.progressPetExp:SetPercent(curHp / maxHp)
  else
    self.progressPetExp:SetPercent(0)
  end
  if self.SkillList then
    self.SkillList:Clear()
    self.SkillList:InitList(self.petData.acquired_feature_ids or {})
  end
  if self.HaveSkill then
    self.HaveSkill:Clear()
    self.HaveSkill:InitList(self.petData.skills or {})
  end
  if self.previewWorld then
    self.previewWorld:SetPreviewByPetBaseId(nil, fullPetData.base_conf_id, fullPetData.mutation_type, fullPetData.glass_info, fullPetData.nature)
  end
end

function UMG_HerbologyBadge_DetailedInformation_C:OnConstruct()
end

function UMG_HerbologyBadge_DetailedInformation_C:OnDestruct()
end

return UMG_HerbologyBadge_DetailedInformation_C
