local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local PVEModuleEvent = require("NewRoco.Modules.System.PVE.PVEModuleEvent")
local UMG_PVE_Talent_Item_C = Base:Extend("UMG_PVE_Talent_Item_C")
local PVEModuleEnum = require("NewRoco.Modules.System.PVE.PVEModuleEnum")

function UMG_PVE_Talent_Item_C:OnConstruct()
  self:AddButtonListener(self.ClickButton, self.OnClickSelect)
end

function UMG_PVE_Talent_Item_C:OnDestruct()
  self:RemoveButtonListener(self.ClickButton)
end

function UMG_PVE_Talent_Item_C:OnActive(itemConf, callback, isParticulars)
  if nil == itemConf then
    Log.ErrorFormat("UMG_PVE_Talent_Item_C:OnActive itemConf is nil")
    return
  end
  local nodeData = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentNodeDataById, itemConf.id)
  self.itemData = nodeData
  self.itemConf = itemConf
  self.oldStatus = nil
  self.isParticulars = isParticulars
  self:InitItem(itemConf)
  self:RefreshLockStatus(nodeData, true)
  if callback then
    callback(itemConf, nodeData and nodeData.status or PVEModuleEnum.TalentNodeStatus.Locked)
  end
end

function UMG_PVE_Talent_Item_C:OnClickSelect()
  _G.NRCAudioManager:PlaySound2DAuto(40002008, "UMG_PVE_Talent_Item_C:OnClickSelect")
  _G.NRCModuleManager:DoCmd(_G.PVEModuleCmd.OpenPveParticulars, self.itemData)
end

function UMG_PVE_Talent_Item_C:ChangeSelect(IsSelect)
  if IsSelect then
    if self.Select_in then
      self:PlayAnimation(self.Select_in)
    end
  elseif self.Select_out then
    self:PlayAnimation(self.Select_out)
  end
end

function UMG_PVE_Talent_Item_C:InitItem(itemConf)
  if not string.IsNilOrEmpty(itemConf.frame) then
    self.Contaminate:SetPath(itemConf.frame)
  end
  if not string.IsNilOrEmpty(itemConf.icon) then
    self.IconImage:SetPath(itemConf.icon)
  end
end

function UMG_PVE_Talent_Item_C:RefreshLockStatus(nodeData, bInit, bForce)
  if not nodeData then
    Log.ErrorFormat("UMG_PVE_Talent_Item_C:RefreshLockStatus nodeData is nil")
    return
  end
  local oldStatus = self.oldStatus
  local newStatus = nodeData and nodeData.status or PVEModuleEnum.TalentNodeStatus.Locked
  self.itemData = nodeData
  self.oldStatus = newStatus
  if oldStatus == newStatus and not bForce then
    return
  end
  self:StopAllAnimations()
  if not bInit and oldStatus == PVEModuleEnum.TalentNodeStatus.CanUnlock and newStatus == PVEModuleEnum.TalentNodeStatus.Unlocked and self.Activate then
    _G.NRCAudioManager:PlaySound2DAuto(1232, "UMG_PVE_Talent_Item_C:RefreshLockStatus")
    self:PlayAnimation(self.Activate)
  end
  oldStatus = oldStatus or PVEModuleEnum.TalentNodeStatus.Locked
  if newStatus == PVEModuleEnum.TalentNodeStatus.CanUnlock then
    local materialCnt = _G.NRCModeManager:DoCmd(_G.PVEModuleCmd.GetTalentMaterialCnt)
    local materialCost = self.itemConf and self.itemConf.material_cost or 0
    if materialCnt >= materialCost and not self.isParticulars then
      if self.Activatable_loop then
        self:PlayAnimation(self.Activatable_loop, 0, 0)
      end
    elseif self.un_active_loop then
      self:PlayAnimation(self.un_active_loop)
    end
  elseif newStatus == PVEModuleEnum.TalentNodeStatus.Locked then
    if self.Lock_loop then
      self:PlayAnimation(self.Lock_loop, 0, 0)
    end
  else
    self:PlayAnimation(self.unlock_loop)
  end
end

return UMG_PVE_Talent_Item_C
