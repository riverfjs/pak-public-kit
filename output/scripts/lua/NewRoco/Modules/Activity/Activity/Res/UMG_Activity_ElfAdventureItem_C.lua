local PetUtils = require("NewRoco.Utils.PetUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local UMG_Activity_ElfAdventureItem_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfAdventureItem_C")

function UMG_Activity_ElfAdventureItem_C:OnActive()
end

function UMG_Activity_ElfAdventureItem_C:UpDateUI(_data, parent)
  if parent then
    self._parent = parent
  end
  local data = _data.tripInfo
  local isFly = _data.isFly
  local baseConf = _G.DataConfigManager:GetPetbaseConf(data.pet_base_id)
  local pet_data = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(data.pet_gid)
  if not pet_data then
    Log.Error("UMG_Activity_ElfAdventureItem_C:UpDateUI pet_data is nil", data.pet_gid)
    return
  end
  local _scale = baseConf.res_ui_percentage and baseConf.res_ui_percentage > 0 and baseConf.res_ui_percentage or 1
  if 1 ~= baseConf.res_horizontal_flip_data then
    self.PetIcon:SetRenderScale(UE4.FVector2D(_scale, _scale))
  else
    self.PetIcon:SetRenderScale(UE4.FVector2D(-_scale, _scale))
  end
  local path = baseConf.JL_res
  if PetMutationUtils.GetMutationValue(pet_data.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) or PetUtils.CheckIsShiningGlass(pet_data.mutation_type) then
    path = baseConf.JL_shiny_res
  end
  if path then
    local prefix = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/Pet1024/"
    local newPrefix = "Texture2D'/Game/NewRoco/Modules/System/Common/Icon/PetOutline1024/"
    if string.sub(path, 1, #prefix) == prefix then
      path = newPrefix .. string.sub(path, #prefix + 1)
    end
  end
  self.PetIcon:SetPath(path)
  if isFly then
    self.NRCImage_23:SetVisibility(UE4.ESlateVisibility.Collapsed)
  else
    self.NRCImage_23:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Activity_ElfAdventureItem_C:ChangePetBegin(waitChangePetJlData, changePetJlDataIndex)
  self.waitChangePetJlData = waitChangePetJlData
  self.IsInChange = true
  self.changePetJlDataIndex = changePetJlDataIndex
  _G.NRCAudioManager:PlaySound2DAuto(1177, "UMG_Activity_ElfAdventureItem_C:ChangePetBegin")
  self:PlayAnimation(self.Out)
end

function UMG_Activity_ElfAdventureItem_C:ChangePetEnd()
  if not self.waitChangePetJlData then
    _G.NRCAudioManager:PlaySound2DAuto(1178, "UMG_Activity_ElfAdventureItem_C:ChangePetEnd")
    self:PlayAnimation(self.In)
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1178, "UMG_Activity_ElfAdventureItem_C:ChangePetEnd")
  self._parent:OnChangePetEnd(self.changePetJlDataIndex)
  self:UpDateUI(self.waitChangePetJlData)
  self:PlayAnimation(self.In)
end

function UMG_Activity_ElfAdventureItem_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:ChangePetEnd()
  end
  if anim == self.In then
    self.IsInChange = false
    self:StopAllAnimations()
    local RandLoopIndex = math.random(1, 5)
    self:PlayAnimation(self["Loop_" .. RandLoopIndex], 0, 0)
  end
end

function UMG_Activity_ElfAdventureItem_C:OnDeactive()
end

function UMG_Activity_ElfAdventureItem_C:OnAddEventListener()
end

return UMG_Activity_ElfAdventureItem_C
