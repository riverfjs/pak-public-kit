local UMG_Activity_BackflowPetSelectItem_C = _G.NRCViewBase:Extend("UMG_Activity_BackflowPetSelectItem_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")

function UMG_Activity_BackflowPetSelectItem_C:OnConstruct()
  self:AddButtonListener(self.ExamineBtn.btnLevelUp, self.ExamineBtnClick)
  self.bSelected = false
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_BackflowPetSelectItem_C", self, ActivityModuleEvent.OnBackflowPetSelected, self.OnPetSelected)
end

function UMG_Activity_BackflowPetSelectItem_C:SetInfo(conf_id)
  local recallPetConf = _G.DataConfigManager:GetActivityRecallPetConf(conf_id)
  self.Icon1:SetPath(recallPetConf.pet_image)
  self.petBase_id = recallPetConf.pet_id
  self.petEgg_id = recallPetConf.pet_egg
  local petConf = _G.DataConfigManager:GetPetbaseConf(self.petBase_id)
  self.Text_Title:SetText(petConf.name)
  self.List_1:InitGridView(petConf.unit_type)
  self.Text_Name:SetText(recallPetConf.pet_label)
end

function UMG_Activity_BackflowPetSelectItem_C:ExamineBtnClick()
  _G.NRCModuleManager:DoCmd(_G.BattlePassModuleCmd.OpenPetDetailPanel, self.petBase_id, true)
end

function UMG_Activity_BackflowPetSelectItem_C:OnAnimationFinished(anim)
  if anim == self.Press_in then
    self:PlayAnimation(self.Press_loop, nil, 0)
  end
end

function UMG_Activity_BackflowPetSelectItem_C:OnPetSelected(pet_id)
  if self.petBase_id == pet_id then
    self.bSelected = true
    self:PlayAnimation(self.Press_in)
  elseif self.bSelected then
    self.bSelected = false
    self:StopAllAnimations()
    self:PlayAnimation(self.Press_out)
  end
end

function UMG_Activity_BackflowPetSelectItem_C:OnTouchEnded(MyGeometry, InTouchEvent)
  _G.NRCAudioManager:PlaySound2DAuto(40002004, "UMG_Activity_BackflowPetSelectItem_C:OnTouchEnded")
  if not self.bSelected then
    _G.NRCEventCenter:DispatchEvent(ActivityModuleEvent.OnBackflowPetSelected, self.petBase_id, self.petEgg_id)
  end
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

function UMG_Activity_BackflowPetSelectItem_C:OnDestruct()
  self:RemoveButtonListener(self.ExamineBtn.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnBackflowPetSelected, self.OnPetSelected)
end

return UMG_Activity_BackflowPetSelectItem_C
