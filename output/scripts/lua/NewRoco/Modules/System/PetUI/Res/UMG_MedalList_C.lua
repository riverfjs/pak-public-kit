local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UIUtils = require("NewRoco.Utils.UIUtils")
local UMG_MedalList_C = Base:Extend("UMG_MedalList_C")

function UMG_MedalList_C:OnConstruct()
end

function UMG_MedalList_C:OnDestruct()
end

function UMG_MedalList_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.index = index
  self:InitializeInfo()
  self:SetData()
  self:PlayAnimation(self.open)
end

function UMG_MedalList_C:UpdateItemInfo(medalData)
  self.data.MedalData = medalData
  self:InitializeInfo()
  self:SetData()
end

function UMG_MedalList_C:SetData()
  if self.data and self.data.MedalData and self.data.PetData then
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NoneIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local medalConf = _G.DataConfigManager:GetMedalConf(self.data.MedalData.conf_id)
    if medalConf then
      local iconPath = medalConf.icon
      if medalConf.medal_ui_format == _G.Enum.MedaluiFormat.MUIF_SPECIAL_3 or medalConf.medal_ui_format == _G.Enum.MedaluiFormat.MUIF_SPECIAL_4 then
        local medalLevelInfo = UIUtils.GetMedalLevelInfo(self.data.MedalData.conf_id, self.data.MedalData.complete_cnt)
        if medalLevelInfo then
          iconPath = medalLevelInfo.icon2
        end
      end
      self.Icon:SetPath(iconPath)
      self.NRCText_4:SetText(medalConf.name)
    end
    self.Icon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.NRCText_4:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.RedDot:SetupKey(196, {
      self.data.PetData.gid,
      self.data.MedalData.conf_id
    })
    if self.data.MedalData.is_wear then
      self:SetOnNewStateRemove()
      if not self.data.MedalData.wear_pet_gid or 0 == self.data.MedalData.wear_pet_gid or self.data.MedalData.wear_pet_gid == self.data.PetData.gid then
        self.Equipped:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      end
    else
      self.Equipped:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    self:SetHeadInfo()
    self:SetClickable(true)
  else
    self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.NoneIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:SetClickable(false)
  end
end

function UMG_MedalList_C:InitializeInfo()
  self.Icon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.NRCText_4:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Equipped:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_MedalList_C:SetHeadInfo()
  if self.data.MedalData.wear_pet_gid and 0 ~= self.data.MedalData.wear_pet_gid and self.data.MedalData.wear_pet_gid ~= self.data.PetData.gid then
    local PetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(self.data.MedalData.wear_pet_gid)
    if PetData then
      local PetBaseConf = _G.DataConfigManager:GetPetbaseConf(PetData.base_conf_id)
      if PetBaseConf then
        local model_conf = _G.DataConfigManager:GetModelConf(PetBaseConf.model_conf)
        self.HeadIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.HeadIcon:SetPath(model_conf.icon)
      end
    end
  end
end

function UMG_MedalList_C:SetOnNewStateRemove()
  if self.data and self.data.PetData and self.data.PetData.gid and self.RedDot and self.RedDot:IsRed() then
    self.RedDot:EraseRedPoint()
  end
end

function UMG_MedalList_C:OnSelect(_bSelected)
  if not self:IsAnimationPlaying(self.open) then
    self:StopAllAnimations()
  end
  if _bSelected then
    self.NRCText_4:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("F4EEE1FF"))
    self:PlayAnimation(self.Select_In)
  else
    self.NRCText_4:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("908F85FF"))
    self:PlayAnimation(self.Select_Out)
  end
end

function UMG_MedalList_C:OnItemSelected(_bSelected)
  if not self.data or not self.data.MedalData then
    return
  end
  self:OnSelect(_bSelected)
  if _bSelected then
    _G.NRCModuleManager:DoCmd(PetUIModuleCmd.SelectMedalItem, self.data.MedalData, self.index)
  else
    self:SetOnNewStateRemove()
  end
end

function UMG_MedalList_C:OnDeactive()
end

return UMG_MedalList_C
