local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_ShinyWeekendPetItem_C = Base:Extend("UMG_ShinyWeekendPetItem_C")

function UMG_ShinyWeekendPetItem_C:OnConstruct()
end

function UMG_ShinyWeekendPetItem_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self.bSelected = false
  if _data.PetData.gid then
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(_data.PetData.gid)
    self.pet:SetIconPathAndMaterial(petInfo.base_conf_id, petInfo.mutation_type, petInfo.glass_info)
  else
    self.pet:SetIconPathAndMaterial(_data.PetData.base_conf_id)
  end
  if _data.PetData.is_trial_pet then
    self.TryOut:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.TryOut:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self.Text_Quantity:SetText(_data.PetData.level)
  if self.needInit then
    self:PlayAnimation(self.Normal)
    self.needInit = false
  end
end

function UMG_ShinyWeekendPetItem_C:OnItemSelected(_bSelected, _bScrollSelected)
  if self.bSelected == _bSelected then
    return
  end
  self.bSelected = _bSelected
  if _bSelected then
    if _bScrollSelected then
      self:PlayAnimation(self.select)
    else
      local module = _G.NRCModuleManager:GetModule("PetUIModule")
      module:DispatchEvent(PetUIModuleEvent.PetTeamWarehouseItemSelected, self.data.PetData)
      self:PlayAnimation(self.In)
    end
  else
    self:PlayAnimation(self.Out)
  end
end

function UMG_ShinyWeekendPetItem_C:OnDespawn()
  if self._parent and self._parent._selectedItemIndex == self.index then
    self.needInit = true
  end
end

return UMG_ShinyWeekendPetItem_C
