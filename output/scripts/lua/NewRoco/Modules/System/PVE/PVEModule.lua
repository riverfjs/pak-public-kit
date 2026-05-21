local PVEModule = NRCModuleBase:Extend("PVEModule")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")
local SeasonIntegrationModuleEvent = require("NewRoco.Modules.System.SeasonIntegration.SeasonIntegrationModuleEvent")
local ActivityUtils = require("NewRoco.Modules.System.Activity.ActivityUtils")
local PetUtils = require("NewRoco.Utils.PetUtils")

function PVEModule:OnConstruct()
  self.data = self:SetData("PVEModuleData", "NewRoco.Modules.System.PVE.PVEModuleData")
  self:RegPanel("PveTalent", "/Game/NewRoco/Modules/System/PVE/Res/UMG_PVE_Talent", _G.Enum.UILayerType.UI_LAYER_FULLSCREEN, nil, "Open", "Close", true)
  self:RegPanel("PveCurrentPeriod", "/Game/NewRoco/Modules/System/PVE/Res/UMG_PVE_CurrentPeriod", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, nil, nil, true)
  self:RegPanel("PveParticulars", "/Game/NewRoco/Modules/System/PVE/Res/UMG_PVE_Particulars", _G.Enum.UILayerType.UI_LAYER_POPUP, nil, "In", "Out", true)
  self:RegPanel("PveWarningPrompt", "/Game/NewRoco/Modules/System/PVE/Res/UMG_PVE_WarningPrompt", _G.Enum.UILayerType.UI_LAYER_POPUP)
end

function PVEModule:OnDestruct()
end

function PVEModule:OnActive()
  self:GeneratePveTalentData()
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SEASON_TALENT_POINT_RSP, self.OnZoneGetSeasonTalentPointRsp)
  _G.ZoneServer:AddProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CLEAR_SEASON_TALENT_POINT_RSP, self.OnZoneClearSeasonTalentPointRsp)
  _G.NRCEventCenter:RegisterEvent("PVEModule", self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.GeneratePveTalentData)
end

function PVEModule:OnDeactive()
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_GET_SEASON_TALENT_POINT_RSP, self.OnZoneGetSeasonTalentPointRsp)
  _G.ZoneServer:RemoveProtocolListener(self, _G.ProtoCMD.ZoneSvrCmd.ZONE_CLEAR_SEASON_TALENT_POINT_RSP, self.OnZoneClearSeasonTalentPointRsp)
  _G.NRCEventCenter:UnRegisterEvent(self, SeasonIntegrationModuleEvent.OnSeasonInfoChange, self.GeneratePveTalentData)
end

function PVEModule:RegPanel(name, path, layer, customDisableRendering, openAnimName, closeAnimName, enablePcEsc)
  local registerData = _G.NRCPanelRegisterData()
  registerData.panelName = name
  registerData.panelPath = path
  registerData.panelLayer = layer
  registerData.customDisableRendering = customDisableRendering or false
  registerData.openAnimName = openAnimName
  registerData.closeAnimName = closeAnimName
  registerData.enablePcEsc = enablePcEsc
  self:RegisterPanel(registerData)
end

function PVEModule:GeneratePveTalentData()
  self.data:GeneratePveTalentData()
end

function PVEModule:RefreshTalentMaterialCnt(materialCnt)
  local talentData = self.data.talentData
  if talentData and materialCnt then
    talentData.materialCnt = materialCnt
    self:DispatchEvent(PVEModuleEvent.TalentMaterialCntChange, materialCnt)
  end
end

function PVEModule:RefreshTalentNodeUnlockCnt(unlockCnt)
  local talentData = self.data.talentData
  if talentData then
    talentData.unlockNodeCnt = unlockCnt
    self:DispatchEvent(PVEModuleEvent.TalentNodeUnlockCntChange, unlockCnt, talentData.totalNodeCnt)
    NRCEventCenter:DispatchEvent(PVEModuleEvent.TalentNodeUnlockCntChange, unlockCnt, talentData.totalNodeCnt)
  end
end

function PVEModule:RefreshTalentNodeLockStatus(nodeId, status, newPetConfId, isInit)
  local nodeData = self.data:GetTalentNodeData(nodeId)
  if not nodeData then
    return
  end
  if nodeData.status ~= status or nodeData.newPetConfId ~= newPetConfId then
    nodeData.status = status
    nodeData.newPetConfId = newPetConfId
    self:DispatchEvent(PVEModuleEvent.TalentNodeLockStatusChange, nodeData, isInit)
    if status == PVEModuleEnum.TalentNodeStatus.Unlocked then
      local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(nodeId)
      if nodeConf then
        for _, neighborSort in ipairs(nodeConf.neighbor_sort) do
          local neighborId = self.data:GetTalentNodeIdBySort(neighborSort)
          local neighborData = neighborId and self.data:GetTalentNodeData(neighborId)
          if neighborData and neighborData.status == PVEModuleEnum.TalentNodeStatus.Locked then
            self:RefreshTalentNodeLockStatus(neighborId, PVEModuleEnum.TalentNodeStatus.CanUnlock, nil, isInit)
          end
        end
      end
    end
  end
end

function PVEModule:CmdDispatchEvent(event, ...)
  self:DispatchEvent(event, ...)
end

function PVEModule:OpenPveTalentPanel()
  if self:HasPanel("PveTalent") then
    return
  else
    local talentData = self.data.talentData
    if not talentData or not talentData.pveBaseConf then
      Log.Error("invalid pve data!!")
      return
    end
    local resListData = _G.NRCPanelResLoadData()
    resListData.PreparingResList = {}
    for _, res in pairs(PVEModuleEnum.TalentNodeUmgCls) do
      table.insert(resListData.PreparingResList, res)
    end
    self:OpenPanel("PveTalent", talentData, resListData)
  end
end

function PVEModule:OpenPveCurrentPeriod()
  if self:HasPanel("PveCurrentPeriod") then
    return
  end
  local talentData = self.data.talentData
  if not talentData or not talentData.pveBaseConf then
    Log.Error("invalid pve data!!")
    return
  end
  self:OpenPanel("PveCurrentPeriod", talentData.pveBaseConf)
end

function PVEModule:OpenPveParticulars(nodeData)
  if not nodeData then
    return
  end
  self:DispatchEvent(PVEModuleEvent.SwitchCurrentTalentNode, nodeData)
  self:OpenPanel("PveParticulars", nodeData)
end

function PVEModule:GetTalentUnlockNodeNum()
  local talentData = self.data.talentData
  if talentData then
    return talentData.unlockNodeCnt or 0, talentData.totalNodeCnt or 0
  end
  return 0, 0
end

function PVEModule:GetTalentNodeDataById(nodeId)
  return self.data:GetTalentNodeData(nodeId)
end

function PVEModule:GetTalentMaterial()
  local talentData = self.data.talentData
  return talentData and talentData.material or 0
end

function PVEModule:GetTalentMaterialCnt()
  local talentData = self.data.talentData
  return talentData and talentData.materialCnt or 0
end

function PVEModule:GetTalentResetReturnMaterialCnt()
  local totalMaterialCnt = 0
  self.data:TraverseTalentNodeData(function(_, data)
    if data.status == PVEModuleEnum.TalentNodeStatus.Unlocked then
      local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(data.id)
      if nodeConf then
        totalMaterialCnt = totalMaterialCnt + nodeConf.material_cost
      end
    end
  end)
  return totalMaterialCnt
end

function PVEModule:ClosePveParticulars()
  if not self:HasPanel("PveParticulars") then
    return
  end
  self:ClosePanel("PveParticulars")
end

function PVEModule:ClearTalentNode()
  self:DispatchEvent(PVEModuleEvent.SwitchCurrentTalentNode, nil)
end

function PVEModule:GetPveFeatureListData(seasonTipsId, excludeNodeId)
  if not seasonTipsId then
    Log.Error("GetPveFeatureListData: seasonTipsId is nil")
    return {}
  end
  local seasonTipsConf = _G.DataConfigManager:GetSeasonTipsNewPetConf(seasonTipsId)
  if not seasonTipsConf or not seasonTipsConf.new_pet then
    Log.ErrorFormat("GetPveFeatureListData: can not get SEASON_TIPS_NEW_PET_CONF for id=%d", seasonTipsId)
    return {}
  end
  local occupiedSkillIds = self:GetOccupiedFeatureSkillIds(excludeNodeId)
  local featureList = {}
  local HandbookModuleData = _G.NRCModuleManager:GetModule("HandbookModule"):GetData("HandbookModuleData")
  for _, petbaseId in ipairs(seasonTipsConf.new_pet) do
    local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petbaseId)
    if petBaseConf then
      local skillId = petBaseConf.pet_feature or 0
      if 0 ~= skillId then
        local skillConf = _G.DataConfigManager:GetSkillConf(skillId)
        if skillConf then
          local isActive = HandbookModuleData:CheckEvoPetbaseIdInHandbook(petbaseId)
          local isOccupied = true == occupiedSkillIds[skillId]
          table.insert(featureList, {
            petbaseId = petbaseId,
            seasonTipsId = seasonTipsId,
            skillId = skillId,
            skillConf = skillConf,
            isActive = isActive,
            isOccupied = isOccupied
          })
        end
      end
    end
  end
  return featureList
end

function PVEModule:GetOccupiedFeatureSkillIds(excludeNodeId)
  local occupiedSkillIds = {}
  self.data:TraverseTalentNodeData(function(id, data)
    if id ~= excludeNodeId and data.status == PVEModuleEnum.TalentNodeStatus.Unlocked and data.newPetConfId and data.newPetConfId > 0 then
      local nodeConf = _G.DataConfigManager:GetSeasonGrowthConf(id)
      if nodeConf and nodeConf.type == Enum.SeasonGrowthType.SGT_PET then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(data.newPetConfId)
        if petBaseConf and petBaseConf.pet_feature and 0 ~= petBaseConf.pet_feature then
          occupiedSkillIds[petBaseConf.pet_feature] = true
        end
      end
    end
  end)
  return occupiedSkillIds
end

function PVEModule:IsCurSeasonOpenTalent()
  local talentData = self.data.talentData
  return talentData and talentData.seasonTalentConf ~= nil
end

function PVEModule:LightUpTalentNode(nodeId, newPetConfId)
  self:SendZoneLightSeasonTalentPointReq(nodeId, newPetConfId)
end

function PVEModule:SetShowInnerPanels(value)
  self:DispatchEvent(PVEModuleEvent.ShowInnerPanels, value)
end

function PVEModule:OnZoneGetSeasonTalentPointRsp(protoData)
  if not protoData or 0 ~= protoData.ret_info.ret_code then
    return
  end
  self:RefreshTalentMaterialCnt(protoData.material_cnt)
  self:RefreshTalentNodeUnlockCnt(protoData.light_growth_list and #protoData.light_growth_list or 0)
  if protoData.light_growth_list then
    for _, data in ipairs(protoData.light_growth_list) do
      self:RefreshTalentNodeLockStatus(data.id, PVEModuleEnum.TalentNodeStatus.Unlocked, data.new_pet_conf_id, true)
    end
  end
end

function PVEModule:SendZoneLightSeasonTalentPointReq(nodeId, newPetConfId)
  local req = _G.ProtoMessage:newZoneLightSeasonTalentPointReq()
  req.point_id = nodeId
  if newPetConfId then
    req.new_pet_conf_id = newPetConfId
  end
  ActivityUtils.SendMsgToSvr(_G.ProtoCMD.ZoneSvrCmd.ZONE_LIGHT_SEASON_TALENT_POINT_REQ, req, self, self.OnZoneLightSeasonTalentPointRsp)
end

function PVEModule:OnZoneLightSeasonTalentPointRsp(protoData, req)
  if not protoData or 0 ~= protoData.ret_info.ret_code then
    return
  end
  if req then
    local talentData = self.data.talentData
    if talentData and req.new_pet_conf_id == nil then
      self:RefreshTalentNodeUnlockCnt(talentData.unlockNodeCnt + 1)
    end
    self:RefreshTalentMaterialCnt(protoData.material_cnt)
    self:RefreshTalentNodeLockStatus(req.point_id, PVEModuleEnum.TalentNodeStatus.Unlocked, req.new_pet_conf_id)
  end
end

function PVEModule:OnZoneClearSeasonTalentPointRsp(protoData)
  if not protoData or 0 ~= protoData.ret_info.ret_code then
    return
  end
  self:RefreshTalentMaterialCnt(protoData.material_cnt)
  self:RefreshTalentNodeUnlockCnt(0)
  self.data:TraverseTalentNodeData(function(_, data)
    if data.status ~= PVEModuleEnum.TalentNodeStatus.Locked then
      if 0 == data.sort then
        self:RefreshTalentNodeLockStatus(data.id, PVEModuleEnum.TalentNodeStatus.CanUnlock)
      else
        self:RefreshTalentNodeLockStatus(data.id, PVEModuleEnum.TalentNodeStatus.Locked)
      end
    end
  end)
end

function PVEModule:OpenPveWarningPrompt(...)
  if not self:HasPanel("PveWarningPrompt") then
    self:OpenPanel("PveWarningPrompt", ...)
  end
end

return PVEModule
