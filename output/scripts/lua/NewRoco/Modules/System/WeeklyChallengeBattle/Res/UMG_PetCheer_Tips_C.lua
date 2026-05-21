local UMG_PetCheer_Tips_C = _G.NRCPanelBase:Extend("UMG_PetCheer_Tips_C")

function UMG_PetCheer_Tips_C:OnConstruct()
end

function UMG_PetCheer_Tips_C:OnDestruct()
end

function UMG_PetCheer_Tips_C:OnActive(petData)
  self:OnAddEventListener()
  self:PlayAnimation(self.Appear)
  if not petData or 0 == petData.gid then
    Log.Error("\228\188\160\229\133\165\228\186\134\228\184\128\228\184\170\233\157\158\230\179\149petData")
    return
  end
  self.petData = petData
  self:_InitPanel()
end

function UMG_PetCheer_Tips_C:OnPcClose()
  self:OnClickedShutdownBtn()
end

function UMG_PetCheer_Tips_C:OnDeactive()
end

function UMG_PetCheer_Tips_C:OnAddEventListener()
  self:AddButtonListener(self.Btn_ShutDown, self.OnClickedShutdownBtn)
end

function UMG_PetCheer_Tips_C:OnClickedShutdownBtn()
  self:StopAllAnimations()
  self:PlayAnimation(self.Disappear)
end

function UMG_PetCheer_Tips_C:_InitPanel()
  self.TitleText:SetText(_G.LuaText.weekly_challenge_text_6)
  local initList = {}
  local cheerPointTable = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.CHEER_POINT_CONF)
  local tempIndex = 1
  for k, v in pairs(cheerPointTable) do
    table.insert(initList, {
      cheerUpCount = v.cheer_point,
      bIsActive = false,
      cheerUpText = v.topic
    })
    local bHas, point = _G.NRCModuleManager:DoCmd(_G.WeeklyChallengeBattleModuleCmd.IsCheerUpRuleSatisfy, v.pet_type_1, v.pet_type_2, v.pet_type_3, self.petData)
    if bHas then
      initList[tempIndex].bIsActive = true
    end
    tempIndex = tempIndex + 1
  end
  table.stableSort(initList, function(a, b)
    return a.cheerUpCount > b.cheerUpCount
  end)
  self.NRCGridView_List:InitGridView(initList)
end

function UMG_PetCheer_Tips_C:OnAnimationFinished(Anim)
  if Anim == self.Disappear then
    self:DoClose()
  end
end

return UMG_PetCheer_Tips_C
