local RocoSkillAction = require("NewRoco.Modules.Core.Battle.Skill.RocoSkillAction")
local Base = RocoSkillAction
local RocoBattleCameraTransAction = Base:Extend("RocoBattleCameraTransAction")

function RocoBattleCameraTransAction:Ctor()
  Base.Ctor(self)
end

function RocoBattleCameraTransAction:OnActionStart()
  if not _G.BattleManager then
    return
  end
  local selectIndex = 1
  local SkillObject = Base.GetSkill(self)
  if SkillObject and SkillObject.DynamicData then
    local target = SkillObject.DynamicData.Caster
    if target and target.BattlePet and target.BattlePet.CardIndex then
      local targetCardId = target.BattlePet.CardIndex
      local myPets = _G.BattleManager.battlePawnManager:GetTeamAllPets()
      if myPets then
        for i = 1, 2 do
          local pet = myPets[i]
          if pet and pet.CardIndex == targetCardId then
            selectIndex = i
            break
          end
        end
      end
    end
  end
  local battleCameraManager = _G.BattleManager.vBattleField.battleCameraManager
  if battleCameraManager then
    battleCameraManager:PetSelectIndexUpdate(selectIndex)
  end
  if self.bIsClearPosCache and battleCameraManager then
    battleCameraManager:CalcPosCache()
    battleCameraManager:ClearTemporaryPosData()
  end
  local Length = math.max(0, self.m_EndTime - self.m_StartTime)
  if self.bUseNewCamEnum then
    if self:IsSkillEditor() then
      self:ChangeCameraInSkillEditor()
      return
    end
    local CraneCamera = _G.BattleManager.vBattleField.battleCraneCamera
    if CraneCamera then
      local cameraBlendParam = {
        MoveAxis = self.MoveAxis,
        TweenCurveVector = self.TweenCurveVector,
        TweenCurveFloat = self.TweenCurveFloat,
        MoveAxis1 = self.MoveAxis1,
        RotatorCurveVector = self.RotatorCurveVector,
        RotatorCurveFloat = self.RotatorCurveFloat,
        FovCurveFloat = self.FovCurveFloat
      }
      local cameraTag = self.m_CameraTagTo
      if self.bUseCurrentPerformCamera then
        if BattleUtils.IsNpcAssist() or BattleUtils.IsFriendAssist() then
          cameraTag = UE4.EBattleCameraTags.PlayerNpcAssistPerformSkill
        elseif BattleUtils.IsFinalBattleP1() then
          cameraTag = UE4.EBattleCameraTags.A1FBPerformSkill
        elseif BattleUtils.IsFinalBattleP2() then
          cameraTag = UE4.EBattleCameraTags.A1FBPerformSkillP2
        elseif BattleUtils.IsB1FinalBattleP1() then
          cameraTag = UE4.EBattleCameraTags.B1FBPerformSkillP1
        elseif BattleUtils.IsB1FinalBattleP2() then
          cameraTag = UE4.EBattleCameraTags.B1FBPerformSkillP2
        elseif BattleUtils.IsB1FinalBattleP3() then
          cameraTag = UE4.EBattleCameraTags.B1FBPerformSkillP3
        elseif BattleUtils.Is1VN() then
          cameraTag = UE4.EBattleCameraTags.OneVsAll_PerformSkill
        elseif BattleUtils.IsTerritoryTrialBattle() then
          cameraTag = UE4.EBattleCameraTags.TerritoryTrial_PerformSkill
        else
          cameraTag = UE4.EBattleCameraTags.PlayerSkill
        end
        Log.Debug("RocoBattleCameraTransAction:OnActionStart cameraTag:", cameraTag)
      end
      CraneCamera:ChangeCameraTagOnG6(cameraTag, self.withBlend and Length or 0, self.withBlend and self.blendFunc or nil, cameraBlendParam)
    end
  elseif self:IsSkillEditor() then
    self:ChangeCameraInSkillEditor()
  else
    _G.BattleManager.TransBattleCamera(self.m_CameraTransTo, self.withBlend and Length or 0, self.blendFunc)
  end
end

return RocoBattleCameraTransAction
