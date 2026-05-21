local UMG_PVE_PetList_C = _G.NRCPanelBase:Extend("UMG_PVE_PetList_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local PetUtils = require("NewRoco.Utils.PetUtils")

function UMG_PVE_PetList_C:OnConstruct()
  self:AddButtonListener(self.ReplacePetBtn.btnLevelUp, self.OnClickReplacePet)
  self:RegisterEvent(self, PVEModuleEvent.SelectPvePet, self.OnSelectPvePet)
  self:RegisterEvent(self, PVEModuleEvent.TalentNodeLockStatusChange, self.OnTalentNodeLockStatusChange)
end

function UMG_PVE_PetList_C:OnActive(petGid, unitType, nodeId)
  self.unitType = unitType
  self.nodeId = nodeId
  self.selectedPetGid = petGid
  self:RefreshPetList(petGid, unitType)
end

function UMG_PVE_PetList_C:RefreshPetList(petGid, unitType)
  local petDataList = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetPvePetListData, unitType)
  self.petDataList = petDataList
  self.curPetGid = petGid
  if petDataList and #petDataList > 0 then
    self.PetList:SetCustomData(petGid)
    self.PetList:InitList(petDataList)
    local selectIdx = 0
    if petGid and petGid > 0 then
      for i, petData in ipairs(petDataList) do
        if petData.gid == petGid then
          selectIdx = i - 1
          break
        end
      end
    end
    self.PetList:SelectItemByIndex(selectIdx)
    self.lastSelectIdx = selectIdx
  end
  self:RefreshReplaceBtn(petGid)
end

function UMG_PVE_PetList_C:RefreshReplaceBtn(selectGid)
  if selectGid and selectGid == self.curPetGid then
    self.ReplacePetBtn:SetCommonText(_G.LuaText.season_growth_unlock_button_5)
    return
  end
  self.ReplacePetBtn:SetCommonText(self.curPetGid ~= nil and _G.LuaText.season_growth_unlock_button_3 or _G.LuaText.season_growth_unlock_button_4)
end

function UMG_PVE_PetList_C:OnDeactive()
  self.petDataList = nil
  self.curPetGid = nil
  self.unitType = nil
  self.nodeId = nil
  self.selectedPetGid = nil
end

function UMG_PVE_PetList_C:OnAddEventListener()
end

function UMG_PVE_PetList_C:OnSelectPvePet(petData)
  if not petData then
    return
  end
  self.selectedPetGid = petData.gid
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petData.base_conf_id)
  local skillId, lock = PetUtils.GetPetFeatrueSkillId(petBaseConf)
  if 0 ~= skillId then
    local petTalentConf = _G.DataConfigManager:GetSkillConf(skillId)
    if petTalentConf then
      if self.SkillIcon_1 and petTalentConf.icon then
        self.SkillIcon_1:SetPath(petTalentConf.icon)
      end
      if self.SkillNameTxt then
        self.SkillNameTxt:SetText(petTalentConf.name or "")
      end
      if self.NRCTextDes then
        self.NRCTextDes:SetText(petTalentConf.desc or "")
      end
    end
  end
  self:RefreshReplaceBtn(self.selectedPetGid)
end

function UMG_PVE_PetList_C:OnClickReplacePet()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_PVE_PetList_C:OnClickReplacePet")
end

function UMG_PVE_PetList_C:RefreshSelectedPetItem()
  self.PetList:SetCustomData(self.curPetGid)
  if self.lastSelectIdx then
    self.PetList:OpItemByIndex(self.lastSelectIdx + 1, 1)
  end
  local petDataList = self.petDataList
  if petDataList and #petDataList > 0 then
    local selectIdx = 0
    if self.selectedPetGid and self.selectedPetGid > 0 then
      for i, petData in ipairs(petDataList) do
        if petData.gid == self.selectedPetGid then
          selectIdx = i - 1
          break
        end
      end
    end
    self.lastSelectIdx = selectIdx
    self.PetList:OpItemByIndex(self.lastSelectIdx + 1, 1)
  end
end

function UMG_PVE_PetList_C:OnTalentNodeLockStatusChange(nodeData, isInit)
  if nil == nodeData then
    return
  end
  if nodeData.id == self.nodeId then
    self.curPetGid = nodeData.petGid
    self:RefreshSelectedPetItem()
    self:RefreshReplaceBtn(self.curPetGid)
  end
end

return UMG_PVE_PetList_C
