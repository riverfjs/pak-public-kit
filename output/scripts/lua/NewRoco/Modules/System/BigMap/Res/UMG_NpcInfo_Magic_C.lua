local UMG_NpcInfo_Magic_C = _G.NRCPanelBase:Extend("UMG_NpcInfo_Magic_C")

function UMG_NpcInfo_Magic_C:OnActive()
end

function UMG_NpcInfo_Magic_C:OnDeactive()
end

function UMG_NpcInfo_Magic_C:OnAddEventListener()
end

function UMG_NpcInfo_Magic_C:OnConstruct()
  self:SetChildViews(self.MagicInfo)
end

function UMG_NpcInfo_Magic_C:OnDestruct()
end

function UMG_NpcInfo_Magic_C:OnEnable(isCamp, title, node, npcInfo)
  if self.module then
    print("\230\139\165\230\156\137self.module")
  end
  self:DynamicAddChildView(self.MagicInfo)
  if isCamp then
    self.npcName_2:SetText(title)
    self.Node_1:SetPath(node)
    self.MagicInfo:UpdateInfo(npcInfo)
    self.MagicInfo:GetPetNum()
  else
    self.npcName_2:SetText(title)
    if not node or 0 == string.len(node) then
      local worldMapId = npcInfo.world_map_cfg_id
      local worldMapConf = _G.DataConfigManager:GetWorldMapConf(worldMapId, true)
      local Icon = worldMapConf.npcicon_levelup[1].icon
      local param = string.split(Icon, "/")
      if #param <= 1 then
        local bigMapModule = _G.NRCModuleManager:GetModule("BigMapModule")
        if bigMapModule then
          node = bigMapModule:GetBigMapIconRes(Icon)
        end
      end
    end
    self.Node_1:SetPath(node)
    self.MagicInfo:UpdateInfo(npcInfo, true)
  end
end

function UMG_NpcInfo_Magic_C:OnDisable()
end

return UMG_NpcInfo_Magic_C
