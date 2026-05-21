local PetUIModuleEvent = reload("NewRoco.Modules.System.PetUI.PetUIModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local UMG_PetTeam_Information_C = _G.NRCViewBase:Extend("UMG_PetTeam_Information_C")
local _pressed = false

function UMG_PetTeam_Information_C:OnConstruct()
  self.isFirstRun = true
end

function UMG_PetTeam_Information_C:OnDestruct()
  self:CancelDelay()
end

function UMG_PetTeam_Information_C:OnDeactive()
end

function UMG_PetTeam_Information_C:OnClicked()
  self.parentView:OnOpenPetWarehouseUI(self.petGid, self.slotId)
end

function UMG_PetTeam_Information_C:InitUI(slotId, parentView)
  self.slotId = slotId
  self.parentView = parentView
end

function UMG_PetTeam_Information_C:SetData(petGid, isMirror)
  self.petGid = petGid
  self.isMirror = isMirror
  self:RefreshUI()
end

function UMG_PetTeam_Information_C:RefreshUI()
  local petGid = self.petGid
  if self.petGid then
    if self.isFirstRun then
    else
      self:PlayShowAnimation()
    end
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(petGid, self.isMirror)
    if petInfo then
      local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfo.base_conf_id, true)
      self:SetPetTopTagInfo(petInfo, petBaseConf)
    end
  end
  self.isFirstRun = false
end

function UMG_PetTeam_Information_C:PlayShowAnimation()
  _G.NRCProfilerLog:NRCPanelOpenAnimation(true, self.panelName)
  self:PlayAnimation(self.In)
end

function UMG_PetTeam_Information_C:SetPetTopTagInfo(petInfo, petBaseConf)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(petInfo.blood_id, true)
  local petTypeInfoType = PetUtils.GetPetTypeInfoType(petInfo)
  self.NameTxt:SetText(petInfo.name)
  if petBaseConf then
    self:SetTypes(BattleUtils.GetPetDefaultTypes(petBaseConf.id))
  elseif petTypeInfoType == ProtoEnum.PetTypeInfo.ENUM.PET_TYPE_RANDOM then
    local typeInfo = petInfo and petInfo.type
    self:SetRandomPetType(typeInfo)
  end
  local petLevel = PetUtils.GetCatchHardInfo(petInfo)
end

function UMG_PetTeam_Information_C:SetTypes(Types)
  Types = Types or {}
  local attrList = {}
  for i, type in ipairs(Types) do
    if type and type > 0 then
      table.insert(attrList, type)
    end
  end
  local attr1 = attrList and attrList[1] or 0
  local attr2 = attrList and attrList[2] or 0
  local attr3 = attrList and attrList[3] or 0
  local petTypes = {}
  if attr1 > 0 then
    if attr2 > 0 then
      petTypes = {attr1, attr2}
    else
      petTypes = {0, attr1}
    end
  end
  if petTypes then
    for i = 1, 2 do
      local petType = petTypes[i]
      if petType and petType > 0 then
        local conf = _G.DataConfigManager:GetTypeDictionary(petType)
        if i <= #petTypes and petType > 1 and conf then
          self["petTypeIcon" .. i]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
          local iconPath = conf.type_icon
          self["petTypeIcon" .. i]:SetPath(iconPath)
        else
          self["petTypeIcon" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
      else
        self["petTypeIcon" .. i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
end

function UMG_PetTeam_Information_C:SetRandomPetType(type)
  local skillDamType = type and type.param
  local iconPath = ""
  if 0 == skillDamType then
    iconPath = BattleConst.RandomPetTypeIcon
  else
    local damType = skillDamType
    local typeDictionaryConf = _G.DataConfigManager:GetTypeDictionary(damType)
    iconPath = typeDictionaryConf and typeDictionaryConf.type_icon or ""
  end
  self.petTypeIcon1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.petTypeIcon2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.petTypeIcon2:SetPath(iconPath)
end

function UMG_PetTeam_Information_C:SetNameTagVisState(isShow)
  if not isShow or self.petGid then
  else
  end
end

function UMG_PetTeam_Information_C:ShowDragIndicator(isShow)
  local petGid = self.petGid
  if isShow then
    if petGid then
    else
    end
  else
    if petGid then
      self:DelayFrames(1, function()
      end)
    else
    end
  end
end

function UMG_PetTeam_Information_C:OnAnimationFinished(Anim)
  if Anim == self.In then
    _G.NRCProfilerLog:NRCPanelOpenAnimation(false, self.panelName)
  end
end

return UMG_PetTeam_Information_C
