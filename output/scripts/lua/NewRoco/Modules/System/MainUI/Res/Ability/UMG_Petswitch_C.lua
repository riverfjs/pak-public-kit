local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local UMG_Petswitch_C = _G.NRCPanelBase:Extend("UMG_Petswitch_C")

function UMG_Petswitch_C:OnConstruct()
  self.lastGid = 0
end

function UMG_Petswitch_C:OnDestruct()
end

function UMG_Petswitch_C:OnActive()
end

function UMG_Petswitch_C:OnDeactive()
end

function UMG_Petswitch_C:SetPetIcon(petConfigId)
  self.UMG_ColorfulHeadIcon:SetIconPathAndMaterial(petConfigId, Enum.MutationDiffType.MDT_NONE)
  self.BallIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.UMG_ColorfulHeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Petswitch_C:SetIcon(itemType, itemInfo)
  if nil == itemInfo then
    return
  end
  local curSelectedPetGid = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if itemType == _G.MainUIModuleEnum.MainUIChooseType.ITEM and itemInfo.id then
    local itemConf = _G.DataConfigManager:GetBallConf(itemInfo.id)
    self.BallIcon:SetPath(itemConf.ball_icon)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, itemType, itemInfo)
    self.BallIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_ColorfulHeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
  elseif itemType == _G.MainUIModuleEnum.MainUIChooseType.PET and itemInfo.base_conf_id then
    local petBaseInfo = _G.DataConfigManager:GetPetbaseConf(itemInfo.base_conf_id)
    if petBaseInfo then
      local petData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(itemInfo.gid)
      if petData then
        self.UMG_ColorfulHeadIcon:SetIconPathAndMaterial(petData.base_conf_id, petData.mutation_type, petData.glass_info)
      end
      self.BallIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.UMG_ColorfulHeadIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    end
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, itemType, itemInfo)
  elseif itemType == _G.MainUIModuleEnum.MainUIChooseType.MAGIC then
    local itemConf = _G.DataConfigManager:GetBagItemConf(itemInfo.id)
    self.BallIcon:SetPath(itemConf.TUIbutton_icon)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, itemType, itemInfo)
    self.BallIcon:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UMG_ColorfulHeadIcon:SetVisibility(UE4.ESlateVisibility.Collapsed)
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.OnCmdSendChangeSelectedThrowItemReq, itemType, itemInfo)
  end
end

return UMG_Petswitch_C
