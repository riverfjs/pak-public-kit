local UMG_KnockMessageTips_C = _G.NRCPanelBase:Extend("UMG_KnockMessageTips_C")

function UMG_KnockMessageTips_C:OnActive()
  local info = _G.NRCModuleManager:DoCmd(_G.SeasonIntegrationModuleCmd.S2_GetCurrentKnockBoxInfo)
  self:UpdateTipsInfo(info)
end

function UMG_KnockMessageTips_C:OnDeactive()
end

function UMG_KnockMessageTips_C:UpdateTipsInfo(info)
  if not info then
    self:EndKnock()
    return
  end
  local dialogueId = info.DialogueId
  if dialogueId then
    local dialogueConf = _G.DataConfigManager:GetDialogueConf(dialogueId, true)
    if dialogueConf then
      self.Name:SetText(dialogueConf.name)
      self.describe:SetText(dialogueConf.text)
    else
      Log.Debug("UMG_KnockMessageTips_C:UpdateTipsInfo dialogueConf is nil", dialogueId)
    end
  end
  local roleIndex = 0
  local npc = info.Npc
  if npc then
    if npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOWBOX_ELITE) then
      roleIndex = 0
    elseif npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_MIDBOX_ELITE) then
      roleIndex = 1
    elseif npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_HIGHBOX_ELITE) then
      roleIndex = 2
    end
    Log.Debug("UMG_KnockMessageTips_C:UpdateTipsInfo npc", npc:DebugNPCNameAndID(), roleIndex)
  end
  self.Switcher_Role:SetActiveWidgetIndex(roleIndex)
  if self:IsAnimationPlaying(self.Out) then
    self:StopAnimation(self.Out)
  end
  self:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  if not self:IsAnimationPlaying(self.In) then
    self:PlayAnimation(self.In)
  end
end

function UMG_KnockMessageTips_C:EndKnock()
  self:PlayAnimation(self.Out)
end

function UMG_KnockMessageTips_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_KnockMessageTips_C
