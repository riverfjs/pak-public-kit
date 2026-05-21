local UMG_AttributeChange_C = _G.NRCPanelBase:Extend("UMG_AttributeChange_C")
local enum = reload("Data.Config.Enum")
local PetUtils = require("NewRoco.Utils.PetUtils")
local PetUIModuleEvent = require("NewRoco.Modules.System.PetUI.PetUIModuleEvent")

function UMG_AttributeChange_C:OnConstruct()
  self:SetChildViews(self.PopUp1)
  self:SetCommonPopUpInfo()
end

function UMG_AttributeChange_C:OnActive(_data, showItemListFood, showItemListItem)
  self:LoadAnimation(0)
  self.data = _data
  if not _data then
    Log.Error("UMG_AttributeChange_C:OnActive _data is nil")
    return
  end
  self.petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.petGid)
  local needLevel = 0
  local levelSkillConf = _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.GetLevelSkillConfByPetBaseId, self.data.petBaseId)
  if levelSkillConf then
    needLevel = levelSkillConf.blood_skill_level_point
  end
  local itemList = {}
  local item1Data = {
    petData = self.petData,
    mode = 0,
    itemList = showItemListFood or {},
    param = {}
  }
  item1Data.param.leftVal = self.petData.level
  item1Data.param.rightVal = needLevel
  local item2Data = {
    petData = self.petData,
    mode = 1,
    itemList = showItemListItem or {},
    param = {}
  }
  local skillConf = _G.DataConfigManager:GetSkillConf(_data.skillId, true)
  item2Data.param.leftVal = self:GetSkillAttrConf(self.petData.blood_id)
  item2Data.param.rightVal = self:GetSkillAttrConf(PetUtils.GetPetBloodBySkillDamType(skillConf.skill_dam_type))
  table.insert(itemList, item1Data)
  table.insert(itemList, item2Data)
  self.Scrollview:InitList(itemList)
  self.PopUp1:SetDescInfo(string.format(LuaText.skill_blood_tips_8, self.petData.name, needLevel, item2Data.param.leftVal.name, self.data.text))
end

function UMG_AttributeChange_C:GetSkillAttrConf(blood_id)
  local PetBloodConf = _G.DataConfigManager:GetPetBloodConf(blood_id)
  if PetBloodConf then
    return {
      name = PetBloodConf.blood_name,
      icon = PetBloodConf.icon
    }
  end
  return {name = "", icon = ""}
end

function UMG_AttributeChange_C:OnDeactive()
  self:DispatchEvent(PetUIModuleEvent.OnAttributeChangeClose)
end

function UMG_AttributeChange_C:OnAddEventListener()
end

function UMG_AttributeChange_C:SetCommonPopUpInfo()
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.Call = self
  CommonPopUpData.ClosePanelHandler = self.OnClose
  self.OnPcCloseHandler = CommonPopUpData.ClosePanelHandler
  self.PopUp1:SetPanelInfo(CommonPopUpData)
  self.PopUp1:SetPanelInfo(CommonPopUpData)
end

function UMG_AttributeChange_C:OnClose()
  self:LoadAnimation(2)
end

function UMG_AttributeChange_C:OnAnimationFinished(Anim)
  if Anim == self:GetAnimByIndex(2) then
    self:DoClose()
  end
end

return UMG_AttributeChange_C
