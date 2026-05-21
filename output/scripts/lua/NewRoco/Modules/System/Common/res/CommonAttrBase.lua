local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local CommonAttrBase = Base:Extend("CommonAttrBase")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")

function CommonAttrBase:OnConstruct()
  if self.Button then
    self:AddButtonListener(self.Button, self.OnClickItem)
  end
end

function CommonAttrBase:OnDestruct()
  if self.Button then
    self:RemoveButtonListener(self.Button)
  end
end

function CommonAttrBase:OnItemUpdate(_data, datalist, index)
  if type(_data) == "table" then
    self.data = _data
  else
    self.data = {Type = _data}
  end
  self.index = index
  self:SetInfo(self.data)
end

function CommonAttrBase:SetInfo(_data)
  local data = _data
  if _data.Type then
    local typeDic = _G.DataConfigManager:GetTypeDictionary(_data.Type)
    if typeDic then
      self.TypeName2_1:SetText(typeDic.short_name)
      self.BloodPulse:SetPath(typeDic.type_icon)
    end
  else
    self.TypeName2_1:SetText(data.Name)
    self.BloodPulse:SetPath(data.Path)
  end
end

function CommonAttrBase:SetColorAndOpacityInfo(textColor)
  if self.TypeName2_1 then
    self.TypeName2_1:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor(textColor))
  end
end

function CommonAttrBase:OnItemSelected(_bSelected)
  if _bSelected then
    self:OnClickItem()
  end
end

function CommonAttrBase:OnClickItem()
  self:PlayPressAnim()
  if self.click then
    self:PlayAnimation(self.click)
  end
  local data = self.data
  if data and data.ShowTips then
    if data.IsBlood and data.petData then
      _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetBloodPulse, data.petData, TipEnum.OpenPetTipsType.FakePetData)
    elseif data.typeId then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {
        typeId = data.typeId
      }, _G.Enum.GoodsType.GT_PET)
    elseif data.typeList then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {
        typeList = data.typeList
      }, _G.Enum.GoodsType.GT_PET)
    elseif data.Type then
      _G.NRCModeManager:DoCmd(_G.TipsModuleCmd.Tips_OpenPetTips, {
        typeId = data.Type
      }, _G.Enum.GoodsType.GT_PET)
    elseif data.petData then
      _G.NRCModeManager:DoCmd(_G.PetUIModuleCmd.PetUIOpenPetTips, data.petData)
    end
  end
end

function CommonAttrBase:PlayPressAnim()
  if self.Press then
    self:PlayAnimation(self.Press)
  end
end

function CommonAttrBase:OnAnimationFinished(Anim)
  if self.Press == Anim then
    self:PlayAnimation(self.Up)
  end
end

return CommonAttrBase
