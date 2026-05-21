local UMG_HandBook_SeasonPet_C = _G.NRCPanelBase:Extend("UMG_HandBook_SeasonPet_C")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")

function UMG_HandBook_SeasonPet_C:OnConstruct()
end

function UMG_HandBook_SeasonPet_C:InitPanel()
  self.bCollected = self:CheckPetIsCollected()
  self:SetPetIcon()
end

function UMG_HandBook_SeasonPet_C:OnDeactive()
end

function UMG_HandBook_SeasonPet_C:OnAddEventListener()
end

function UMG_HandBook_SeasonPet_C:CheckPetIsCollected()
  local record = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetPetHandbookRecordByPetBaseID, self.PetBaseID)
  if record and record.status and record.status == ProtoEnum.PetHandbookStatus.PHS_COLLECTED then
    local photoType = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
    if photoType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
      return true
    else
      local isShining = false
      for _, mutation in pairs(record.catch_mutation or {}) do
        isShining = PetMutationUtils.GetMutationValue(mutation, _G.Enum.MutationDiffType.MDT_SHINING)
        if isShining then
          break
        end
      end
      if isShining then
        return true
      end
    end
  end
  return false
end

function UMG_HandBook_SeasonPet_C:SetPetIcon()
  local petBaseConf = _G.DataConfigManager:GetPetbaseConf(self.PetBaseID)
  local photoType = _G.NRCModuleManager:DoCmd(_G.HandbookModuleCmd.GetCurSelectedSeasonPhotoType)
  local iconPath
  if petBaseConf then
    if photoType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NEW then
      iconPath = petBaseConf.JL_photo_res
    elseif photoType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_SHINING or photoType == ProtoEnum.PetHandbookSeasonPetType.PHSPT_NORMAL_SHINING then
      iconPath = petBaseConf.JL_photo_shiny_res
    end
  end
  if iconPath then
    if self.bCollected then
      local oldZOrder = self.Slot:GetZOrder()
      self.Slot:SetZOrder(oldZOrder + 10)
      self.PetMask:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.Pet:SetRenderOpacity(0)
      self.Pet:SetPathWithCallBack(iconPath, {
        self,
        self.OnSetPetPath
      })
    else
      self.PetMask:SetRenderOpacity(0)
      self.PetMask:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PetMask:SetPathWithCallBack(iconPath, {
        self,
        self.OnSetPetMaskPath
      })
      self.Pet:SetRenderOpacity(0)
      self.Pet:SetPathWithCallBack(iconPath, {
        self,
        self.OnSetPetPath
      })
    end
  end
end

function UMG_HandBook_SeasonPet_C:OnSetPetPath()
  self.Pet:SetRenderOpacity(1)
end

function UMG_HandBook_SeasonPet_C:OnSetPetMaskPath()
  self.PetMask:SetRenderOpacity(1)
end

return UMG_HandBook_SeasonPet_C
