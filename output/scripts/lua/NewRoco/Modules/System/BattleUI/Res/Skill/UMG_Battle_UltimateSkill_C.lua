local UMG_Battle_UltimateSkill_C = _G.NRCPanelBase:Extend("UMG_Battle_UltimateSkill_C")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")

function UMG_Battle_UltimateSkill_C:OnActive(pet)
  self.pet = pet
  self.battleManager = _G.BattleManager
  self:OnAddEventListener()
  if self:IsPlayingAnimation() then
    self:StopAllAnimations()
  end
  self:PlayAnimation(self.In)
  self.ParticleSystemWidget2_75:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.ParticleSystemWidget2_75:SetIsEnabled(true)
  self:RefreshUI()
  self:BindInputAction()
  self:PCKeySetting()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1183, "UMG_Battle_UltimateSkill_C:OnActive")
end

function UMG_Battle_UltimateSkill_C:OnDeactive()
  self:StopLoopSound()
  self:OnRemoveEventListener()
  self.pet = nil
end

function UMG_Battle_UltimateSkill_C:StopLoopSound()
  if self.SoundSession then
    _G.NRCAudioManager:ReleaseSession(self.SoundSession, true)
    self.SoundSession = nil
  end
end

function UMG_Battle_UltimateSkill_C:RefreshUI()
  self.CallNameTutorialPanel3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.CallNameTutorial2_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeachingPrompt3:SetVisibility(UE4.ESlateVisibility.Collapsed)
  if self.pet then
    self:SetCurrentPet(self.pet, self.battleManager:GetCurrentStateName())
  end
end

function UMG_Battle_UltimateSkill_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_B1P3FinalSkill", -1)
  if mappingContext then
    local actions = {
      {
        name = "IA_B1P3FinalSkillStart_1",
        method = "SelectBattleItemStart1"
      },
      {
        name = "IA_B1P3FinalSkillEnd_1",
        method = "SelectBattleItemEnd1"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
  end
end

function UMG_Battle_UltimateSkill_C:SetCurrentPet(pet, stateName)
  local skills = pet.skillComponent:GetDisplaySkills()
  local oneSkill = skills[1]
  self.Skill_Item:SetB1FinalP3FinalSkill(true)
  self.Skill_Item:SetData(oneSkill, stateName, pet, nil, false)
  self.Skill_Item:PlayGradePointLoopAnim()
  self.Skill_Item:SetInb1FinalP3FinalSkill(true)
  self.Skill_Item:SetEnable(true)
end

function UMG_Battle_UltimateSkill_C:SelectBattleItemEnd1()
  self.Skill_Item:OnItemRelease()
end

function UMG_Battle_UltimateSkill_C:SelectBattleItemStart1()
  self.Skill_Item:OnItemPressed()
end

function UMG_Battle_UltimateSkill_C:PCKeySetting()
  self:SetUpPCKey()
end

function UMG_Battle_UltimateSkill_C:SetUpPCKey()
  if _G.SystemSettingModuleCmd and self.Skill_Item then
    self.Skill_Item.PCKey:SetKeyVisibility(true)
    self.Skill_Item.PCKey:SetText("1")
  end
end

function UMG_Battle_UltimateSkill_C:OnRemoveEventListener()
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Battle_UltimateSkill_C:OnAddEventListener()
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_UltimateSkill_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_Battle_UltimateSkill_C:OnBattleEvent(eventName, ...)
  _G.NRCEventCenter:UnRegisterEvent(self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
end

function UMG_Battle_UltimateSkill_C:PlayOutCallBack(Caller, CallBack)
  self:PlayAnimation(self.Out)
  self.Caller = Caller
  self.CallBack = CallBack
end

function UMG_Battle_UltimateSkill_C:DoCallBack()
  if self.Caller and UE4.UObject.IsValid(self.Caller) and self.CallBack then
    self.CallBack(self.Caller)
  end
  self.Caller = nil
  self.CallBack = nil
end

function UMG_Battle_UltimateSkill_C:OnTick()
end

function UMG_Battle_UltimateSkill_C:OnLogin()
end

function UMG_Battle_UltimateSkill_C:OnConstruct()
end

function UMG_Battle_UltimateSkill_C:OnDestruct()
end

function UMG_Battle_UltimateSkill_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoCallBack()
  elseif anim == self.In then
    self.SoundSession = _G.NRCAudioManager:PlaySound2DAuto(1220002044, "UMG_Battle_UltimateSkill_C:OnActive")
  end
end

function UMG_Battle_UltimateSkill_C:OnClickCallTutorialBtn2_1()
end

return UMG_Battle_UltimateSkill_C
