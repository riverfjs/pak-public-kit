local Base = require("NewRoco.TUI.BP_NRCItemBase_C")
local UMG_Share_Btn_C = Base:Extend("UMG_Share_Btn_C")

function UMG_Share_Btn_C:OnConstruct()
  self:OnAddEventListener()
end

function UMG_Share_Btn_C:OnDestruct()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
  end
  self:RemoveButtonListener(self.Btn, self.OnShareWayClick)
end

function UMG_Share_Btn_C:OnAddEventListener()
  self:AddButtonListener(self.Btn, self.OnShareWayClick)
end

function UMG_Share_Btn_C:OnItemUpdate(_data, datalist, index)
  self.data = _data
  self.Index = index
  self.Icon:SetPath(self.data.share_icon)
end

function UMG_Share_Btn_C:OnShareWayClick()
  _G.NRCAudioManager:PlaySound2DAuto(1078, "UMG_Share_Btn_C:OnShareWayClick")
  local data = {
    name = self.data.name,
    qrcodeShow = self.data.qrcodeShow,
    qrcodeLink = self.data.qrcodeLink
  }
  self.DelayId = _G.DelayManager:DelaySeconds(0.1, function()
    _G.NRCModuleManager:DoCmd(ShareUIModuleCmd.ShareChannelExecute, data)
  end)
end

function UMG_Share_Btn_C:PlayInAnim()
  self:PlayAnimation(self.In)
end

function UMG_Share_Btn_C:OnAnimationFinished(Anim)
  if Anim == self.Press then
    self:PlayAnimation(self.Up)
  end
end

return UMG_Share_Btn_C
