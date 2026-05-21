local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local SkillUtils = require("NewRoco.Modules.Core.Battle.BattleCore.Skill.SkillUtils")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local UMG_Battle_Skillpick_Item_C = _G.NRCViewBase:Extend("UMG_Battle_Skillpick_Item_C")
UMG_Battle_Skillpick_Item_C.LoopAnimType = {
  NoSkill = 1,
  FirstNoSkill = 2,
  HasSkill = 3
}

function UMG_Battle_Skillpick_Item_C:OnConstruct()
  self.data = nil
  self.Parent = nil
  self.Index = 0
  self.isLoopAnimPlaying = false
  self.loopAnimType = UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill
  self.loopAnimTypeDisplay = UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill
  self.LightPanel:SetRenderOpacity(0)
  self.NormalWhite:SetRenderOpacity(0)
  self:IsShowSkillIcon(false)
  self:OnAddEventListener()
end

function UMG_Battle_Skillpick_Item_C:OnAddEventListener()
  self:AddButtonListener(self.BtnSkill, self.OnClearAllSkill)
end

function UMG_Battle_Skillpick_Item_C:OnDestruct()
end

function UMG_Battle_Skillpick_Item_C:OnActive()
end

function UMG_Battle_Skillpick_Item_C:IsShowSkillIcon(_IsShow)
  if _IsShow then
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skillpick_Item_C:HideLine()
  self.Line_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Skillpick_Item_C:OnClearAllSkill()
  if BattleUtils.IsWatchingBattle() then
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.Clear_SkillList)
end

function UMG_Battle_Skillpick_Item_C:OnDeactive()
end

function UMG_Battle_Skillpick_Item_C:PlayLoop(_IsPlay)
  self.LightPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  if _IsPlay then
    self:StopAllAnimations()
    self:PlayAnimation(self.In_yellow)
  end
end

function UMG_Battle_Skillpick_Item_C:PlayInLight()
  self:StopAllAnimations()
  self:PlayAnimation(self.Click_in)
end

function UMG_Battle_Skillpick_Item_C:PlayNolight()
  self:PlayAnimation(self.In_black)
end

function UMG_Battle_Skillpick_Item_C:SetData(_data, isFirstNoSkill)
  self.data = _data
  local nextLoopAnimType = UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill
  if self.data then
    nextLoopAnimType = UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill
  elseif isFirstNoSkill then
    nextLoopAnimType = UMG_Battle_Skillpick_Item_C.LoopAnimType.FirstNoSkill
  end
  self.loopAnimType = nextLoopAnimType
  self:RefreshLoopAnim()
  if self.data == nil then
    self:InitializedInfo()
  elseif self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill then
    self:SetInfo()
  end
end

function UMG_Battle_Skillpick_Item_C:SetInfo()
  local data = self.data
  local SkillConf = SkillUtils.GetSkillConf(data.cast_skill.skill_id)
  if SkillConf then
    self:IsShowSkillIcon(true)
    self.Icon_1:SetPath(NRCUtils:FormatConfIconPath(SkillConf.icon, _G.UIIconPath.SkillIconPath))
  end
end

function UMG_Battle_Skillpick_Item_C:SetParent(Parent, i)
  self.Parent = Parent
  self.Index = i
end

function UMG_Battle_Skillpick_Item_C:InitializedInfo()
  if self.data then
    self.data = nil
  end
  self.Icon_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Skillpick_Item_C:OnAnimationFinished(Animation)
  if Animation == self.In_light then
  elseif Animation == self.UnClick_loop then
  elseif Animation == self.Click_in or Animation == self.Click_out or Animation == self.white_out or Animation == self.In_yellow or Animation == self.yellow_out then
    self:DelayFrames(1, function()
      self.isLoopAnimPlaying = false
      self:RefreshLoopAnim()
    end)
  end
end

function UMG_Battle_Skillpick_Item_C:PlayLoopAnim()
  if 1 == self.Index and not self.data then
    if self.Icon_1:GetVisibility() == UE4.ESlateVisibility.Visible or self.Icon_1:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
      self.LightPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.Click_out)
    end
  elseif 1 == self.LightPanel:GetRenderOpacity() then
    self:PlayAnimation(self.yellow_out)
  elseif 1 == self.NormalWhite:GetRenderOpacity() then
    self:PlayAnimation(self.white_out)
  end
end

function UMG_Battle_Skillpick_Item_C:RefreshLoopAnim()
  if self.loopAnimType == self.loopAnimTypeDisplay then
    return
  end
  if self.isLoopAnimPlaying then
    return
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.FirstNoSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill then
    self:PlayAnimation(self.Click_in)
    self.isLoopAnimPlaying = true
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.FirstNoSkill then
    self:PlayAnimation(self.Click_out)
    self.isLoopAnimPlaying = true
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill then
    self:PlayAnimation(self.Click_in)
    self.isLoopAnimPlaying = true
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill then
    self:PlayAnimation(self.white_out)
    self.isLoopAnimPlaying = true
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.FirstNoSkill then
    self:PlayAnimation(self.In_yellow)
    self.isLoopAnimPlaying = true
  end
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.FirstNoSkill and self.loopAnimType == UMG_Battle_Skillpick_Item_C.LoopAnimType.NoSkill then
    self:PlayAnimation(self.yellow_out)
    self.isLoopAnimPlaying = true
  end
  self.loopAnimTypeDisplay = self.loopAnimType
  if self.loopAnimTypeDisplay == UMG_Battle_Skillpick_Item_C.LoopAnimType.HasSkill then
    self:SetInfo()
  end
end

function UMG_Battle_Skillpick_Item_C:StopUnClick_loop()
  if self:IsAnimationPlaying(self.UnClick_loop) then
    self:StopAnimation(self.UnClick_loop)
  end
end

return UMG_Battle_Skillpick_Item_C
