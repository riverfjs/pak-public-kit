local UMG_PetVideoShare_C = _G.NRCPanelBase:Extend("UMG_PetVideoShare_C")

function UMG_PetVideoShare_C:OnDestruct()
  self:CancelDelayId()
end

function UMG_PetVideoShare_C:Init(petGid)
  self.delayId = nil
  self.gid = petGid
  self:PlayAnimation(self.Stamp_in, 0)
  self:PauseAnimation(self.Stamp_in)
end

function UMG_PetVideoShare_C:PlayStampInAnim()
  self:PlayAnimation(self.Stamp_in)
end

function UMG_PetVideoShare_C:OnAnimationFinished(Animation)
  if Animation == self.Stamp_in then
    self:CheckEndRecordVideo()
  end
end

function UMG_PetVideoShare_C:CheckEndRecordVideo()
  local GlobalConfig = _G.DataConfigManager:GetGlobalConfig("share_video_endingframe_duration")
  if GlobalConfig and GlobalConfig.num then
    local time = math.min(GlobalConfig.num / 1000, 1.2)
    
    local function cb()
      _G.NRCModuleManager:DoCmd(ShareModuleCmd.EndRecordVideo, self.gid)
    end
    
    self:CancelDelayId()
    self.delayId = _G.DelayManager:DelaySeconds(time, cb, self)
  else
    _G.NRCModuleManager:DoCmd(ShareModuleCmd.EndRecordVideo, self.gid)
  end
  _G.NRCModuleManager:DoCmd(_G.ShareUIModuleCmd.PlayPetVideoShareInAnim)
end

function UMG_PetVideoShare_C:CancelDelayId()
  if self.delayId then
    _G.DelayManager:CancelDelayById(self.delayId)
    self.delayId = nil
  end
end

return UMG_PetVideoShare_C
