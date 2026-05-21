local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Sanctuary_TipsItem2_C = Base:Extend("UMG_Sanctuary_TipsItem2_C")

function UMG_Sanctuary_TipsItem2_C:OnConstruct()
  self.PlayerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
end

function UMG_Sanctuary_TipsItem2_C:OnDestruct()
end

function UMG_Sanctuary_TipsItem2_C:OnItemUpdate(_data, datalist, index)
  if nil == _data or nil == next(_data) then
    return
  end
  if _data then
    local contentId = _data.contentId
    local OwlSancConf = _G.DataConfigManager:GetOwlSanctuaryConf(contentId)
    self.OwlFactorTag = {
      _G.Enum.PetFormFacto.PFF_NORMAL
    }
    if OwlSancConf and OwlSancConf.pet_form_factor_tag then
      self.OwlFactorTag = OwlSancConf.pet_form_factor_tag
    end
    local v = _data.fruit_id
    local cruTime = _G.ZoneServer:GetServerTime() / 1000
    if 0 == v then
      if cruTime - _data.slot_active_timestamp < 0 then
        self.Switcher:SetActiveWidgetIndex(3)
      else
        self.Switcher:SetActiveWidgetIndex(1)
      end
    else
      local baseId = self:GetFristPetBaseId(v)
      self.PetbaseId = baseId
      if 0 == baseId then
        if cruTime - _data.slot_active_timestamp < 0 then
          self.Switcher:SetActiveWidgetIndex(3)
        else
          self.Switcher:SetActiveWidgetIndex(1)
        end
      else
        self.Switcher:SetActiveWidgetIndex(0)
        self.HeadIcon:SetIconPathAndMaterial(baseId)
        if cruTime - _data.fruit_active_timestamp < 0 or cruTime - _data.slot_active_timestamp < 0 then
          local petBaseConf = _G.DataConfigManager:GetPetbaseConf(baseId)
          local modelConf = _G.DataConfigManager:GetModelConf(petBaseConf.model_conf)
          self.headIconMask:SetPath(NRCUtils:FormatConfIconPath(modelConf.icon, _G.UIIconPath.HeadIconPath))
          self.headIconMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.FruitMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          self.Countdown:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end
      end
    end
  end
end

function UMG_Sanctuary_TipsItem2_C:GetFristPetBaseId(fruit_id)
  local petFruitConf = _G.DataConfigManager:GetOwlPetFruitConf(fruit_id)
  if nil == petFruitConf or nil == petFruitConf.pet_refresh then
    return 0
  end
  for i, v in pairs(petFruitConf.pet_refresh) do
    for _, k in pairs(self.OwlFactorTag) do
      if v.pet_form_factor_tag and v.pet_form_factor_tag == k then
        for j = 1, #v.npc_id do
          local npc_id = v.npc_id[j]
          local BaseId = _G.DataConfigManager:GetNpcConf(npc_id).traverse_data_param[1]
          local FirstBaseId = self:GetFirstStageBaseId(BaseId)
          return FirstBaseId
        end
      end
    end
  end
  for i, v in pairs(petFruitConf.pet_refresh) do
    if v.pet_form_factor_tag and v.pet_form_factor_tag == _G.Enum.PetFormFacto.PFF_NORMAL then
      for j = 1, #v.npc_id do
        local npc_id = v.npc_id[j]
        local BaseId = _G.DataConfigManager:GetNpcConf(npc_id).traverse_data_param[1]
        local FirstBaseId = self:GetFirstStageBaseId(BaseId)
        return FirstBaseId
      end
    end
  end
  return 0
end

function UMG_Sanctuary_TipsItem2_C:GetFirstStageBaseId(baseId)
  local conf = _G.DataConfigManager:GetPetbaseConf(baseId)
  if nil == conf or nil == conf.pet_evolution_id then
    Log.Error("PetBaseConf  id\228\184\186", baseId, "\230\178\161\230\156\137\233\133\141\231\189\174pet_evolution_id \232\175\183\231\155\184\229\133\179\231\173\150\229\136\146\230\163\128\230\159\165\228\184\128\228\184\139")
    return baseId
  end
  local evoId = conf.pet_evolution_id[1]
  local evoConf = _G.DataConfigManager:GetPetEvolutionConf(evoId)
  if nil == evoConf then
    Log.Error("id:", evoId, "\229\156\168PetEvolutionConf\228\184\173\230\178\161\230\156\137\233\133\141\231\189\174")
    return baseId
  end
  local evoDatas = evoConf.evolution_chain
  for i = 1, #evoDatas do
    if 1 == evoDatas[i].stage then
      return evoDatas[i].petbase_id
    end
  end
  return baseId
end

function UMG_Sanctuary_TipsItem2_C:OnItemSelected(_bSelected)
end

function UMG_Sanctuary_TipsItem2_C:OnClickItem()
end

function UMG_Sanctuary_TipsItem2_C:OnDeactive()
end

return UMG_Sanctuary_TipsItem2_C
