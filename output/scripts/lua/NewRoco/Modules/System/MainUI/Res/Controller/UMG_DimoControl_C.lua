local CreatePlayerEvent = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerEvent")
local UMG_DimoControl_C = _G.NRCPanelBase:Extend("UMG_DimoControl_C")
local CreatePlayerModuleCmd = require("NewRoco.Modules.System.CreatePlayerModule.CreatePlayerModuleCmd")

function UMG_DimoControl_C:OnConstruct()
  self:SetChildViews(self.UMG_TaskTrack, self.UMG_TaskTracePanel)
end

local Mode = {
  Move = 1,
  CameraMove = 2,
  Dash = 3,
  Jump = 4,
  End = 5
}

function UMG_DimoControl_C:OnActive(levelData)
  UE4Helper.SetDesiredShowCursor(false, "UMG_DimoControl_C")
  self.isPC = UE.UGameplayStatics.GetGameInstance(UE4Helper.GetCurrentWorld()):IsPCMode()
  _G.NRCEventCenter:RegisterEvent("UMG_DimoControl_C", self, CreatePlayerEvent.PlayerMove, self.OnPlayerMove)
  _G.NRCEventCenter:RegisterEvent("UMG_DimoControl_C", self, CreatePlayerEvent.PlayerCameraMove, self.OnCameraMove)
  _G.NRCEventCenter:RegisterEvent("UMG_DimoControl_C", self, CreatePlayerEvent.PlayerJump, self.OnPlayerJump)
  _G.NRCEventCenter:RegisterEvent("UMG_DimoControl_C", self, CreatePlayerEvent.PlayerDash, self.OnPlayerDash)
  self:AddButtonListener(self.SystemSetBtn.btnLevelUp, self.OpenSetting)
  self:BindInputAction()
  self.countDown = 1
  if self.isPC then
    self.PhoneCanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.PcCanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Ability_DimoDash_PC.UMG_PCKey_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Ability_DimoJump_PC.UMG_PCKey_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.UMG_Ability_DimoDash_PC.UMG_PCKey_1:SetText("Shift")
    self.UMG_Ability_DimoJump_PC.UMG_PCKey_1:SetText("Space")
    self.SystemSetBtn.Text_PCKey:SetKeyVisibility(true)
    self.SystemSetBtn.Text_PCKey:SetText("Esc")
    self:UpdateUIInPC(levelData)
    self.playerActor = NRCModuleManager:DoCmd(CreatePlayerModuleCmd.GetPlayerActor)
  else
    self:UpdateUIInPhone(levelData)
    self.PhoneCanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.PcCanvasPanel:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_DimoControl_C:IsPCMode()
  return self.isPC
end

function UMG_DimoControl_C:OnDeactive()
  UE4Helper.ReleaseDesiredShowCursor("UMG_DimoControl_C")
  _G.NRCEventCenter:UnRegisterEvent(self, CreatePlayerEvent.PlayerJump, self.OnPlayerJump)
  _G.NRCEventCenter:UnRegisterEvent(self, CreatePlayerEvent.PlayerDash, self.OnPlayerDash)
  self:UnBindInputAction()
end

function UMG_DimoControl_C:BindInputAction()
  local mappingContext = self:AddInputMappingContext("IMC_DimoControll")
  if mappingContext then
    local actions = {
      {name = "IA_Jump", method = "OnJump"},
      {
        name = "IA_DimoDashStart",
        method = "OnDashStart"
      },
      {
        name = "IA_OpenSetting_DimoControll",
        method = "OnPCOpenSetting"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method)
    end
  end
end

function UMG_DimoControl_C:UnBindInputAction()
  local actions = {
    {name = "IA_Jump"},
    {
      name = "IA_DimoDashStart"
    },
    {
      name = "IA_OpenSetting_DimoControll"
    }
  }
  for _, action in ipairs(actions) do
    local ia = UE.UNRCEnhancedInputHelper.GetInputAction(action.name)
    UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  end
  local FashionIMC = UE.UNRCEnhancedInputHelper.GetInputMappingContext("IMC_DimoControll")
  _G.NRCModuleManager:DoCmd(_G.EnhancedInputModuleCmd.EnhancedInputHelperRemoveInputMappingContext, FashionIMC)
end

function UMG_DimoControl_C:OnJump()
  self.UMG_Ability_DimoJump:OnSlotClicked()
end

function UMG_DimoControl_C:OnDashStart()
  self.UMG_Ability_DimoDash:OnSlotPressed()
end

function UMG_DimoControl_C:OnDashEnd()
  self.UMG_Ability_DimoDash:OnSlotReleased()
end

function UMG_DimoControl_C:OnAddEventListener()
end

function UMG_DimoControl_C:UpdateUIInPhone(levelData)
  self.TeachingPrompt1.RightArrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeachingPrompt2.LeftArrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeachingPrompt3.LeftArrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeachingPrompt4.LeftArrow:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.TeachingPrompt1.Text:SetText(_G.DataConfigManager:GetRoleGlobalConfig("ftue_joystick").str)
  self.TeachingPrompt4.Text:SetText(_G.DataConfigManager:GetRoleGlobalConfig("ftue_camera_adjust").str)
  self.TeachingPrompt3.Text:SetText(_G.DataConfigManager:GetRoleGlobalConfig("ftue_jump").str)
  self.TeachingPrompt2.Text:SetText(_G.DataConfigManager:GetRoleGlobalConfig("ftue_sprint").str)
  if levelData and levelData.points then
    if 1 == levelData.points[1].pos.y then
      self.LowerLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.TeachingGesture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.PlayerHasMoved = true
    end
    if 1 == levelData.points[1].pos.z then
      self.CameraHasMoved = true
      self.TeachingGesture:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.LowerRight2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if 1 == levelData.points[1].dir.x then
      self.PlayerHasDashed = true
      self.LowerRight2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.LowerRight1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    if 1 == levelData.points[1].dir.y then
      self.PlayerHasJumped = true
      self.LowerRight1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
  if not self.PlayerHasMoved then
    self:PlayAnimation(self.LowerLeft_Animation)
  elseif not self.CameraHasMoved then
    self:PlayAnimation(self.TeachingGesture_Animation)
  elseif not self.PlayerHasDashed then
    self:PlayAnimation(self.LowerRight2_Animation)
  elseif not self.PlayerHasJumped then
    self:PlayAnimation(self.LowerRight1_Animation)
  end
end

function UMG_DimoControl_C:UpdateUIInPC(levelData)
  if levelData and levelData.points then
    if 1 == levelData.points[1].pos.y then
      self.PlayerHasMoved = true
    end
    if 1 == levelData.points[1].pos.z then
      self.CameraHasMoved = true
    end
    if 1 == levelData.points[1].dir.x then
      self.PlayerHasDashed = true
    end
    if 1 == levelData.points[1].dir.y then
      self.PlayerHasJumped = true
    end
  end
  if not self.PlayerHasMoved then
    self.MovePC:LoadPanel(nil, Mode.Move)
    self:PlayAnimation(self.LowerLeft_Animation)
  elseif not self.CameraHasMoved then
    self.MovePC:LoadPanel(nil, Mode.CameraMove)
    self:PlayAnimation(self.TeachingGesture_Animation)
  elseif not self.PlayerHasDashed then
    self.MovePC:LoadPanel(nil, Mode.Dash)
    self:PlayAnimation(self.LowerRight2_Animation)
  elseif not self.PlayerHasJumped then
    self.MovePC:LoadPanel(nil, Mode.Jump)
    self:PlayAnimation(self.LowerRight1_Animation)
  end
end

function UMG_DimoControl_C:CheckIsPlayingAnimation()
  if not self or not UE4.UObject.IsValid(self) then
    return false
  end
  if self.isPC then
    if not self.PCPanel then
      self.PCPanel = self.MovePC:GetPanel()
    end
    if self.PCPanel and self.PCPanel:CheckIsPlayingAnim() then
      return true
    end
  elseif self:IsAnimationPlaying(self.TeachingGesture_Animation) then
    return true
  end
  return false
end

function UMG_DimoControl_C:OnPlayerMove()
  if not self.PlayerHasMoved then
    if self:CheckIsPlayingAnimation() then
      return
    end
    self.PlayerHasMoved = true
    if self.isPC then
      if not self.PCPanel then
        self.PCPanel = self.MovePC:GetPanel()
      end
      if self.PCPanel then
        self.PCPanel:ChangeMode(Mode.CameraMove)
      else
        self.PlayerHasMoved = false
      end
    else
      self.LowerLeft:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.TeachingGesture:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.TeachingGesture_Animation)
    end
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 1, 0, 0, 0, 0)
  end
end

function UMG_DimoControl_C:OnCameraMove()
  if not self.CameraHasMoved and self.PlayerHasMoved then
    if self:CheckIsPlayingAnimation() then
      return
    end
    self.CameraHasMoved = true
    if self.isPC then
      if not self.PCPanel then
        self.PCPanel = self.MovePC:GetPanel()
      end
      if self.PCPanel then
        self.PCPanel:ChangeMode(Mode.Dash)
      else
        self.PlayerHasMoved = false
      end
    else
      self.TeachingGesture:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.LowerRight2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.LowerRight2_Animation)
    end
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 1, 1, 0, 0, 0)
  end
end

function UMG_DimoControl_C:OnPlayerDash()
  if not self.PlayerHasDashed and self.CameraHasMoved then
    if self:CheckIsPlayingAnimation() then
      return
    end
    self.PlayerHasDashed = true
    if self.isPC then
      if not self.PCPanel then
        self.PCPanel = self.MovePC:GetPanel()
      end
      if self.PCPanel then
        self.PCPanel:ChangeMode(Mode.Jump)
      else
        self.PlayerHasMoved = false
      end
    else
      self.LowerRight2:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self.LowerRight1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self:PlayAnimation(self.LowerRight1_Animation)
    end
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 1, 1, 1, 0, 0)
  end
end

function UMG_DimoControl_C:OnPlayerJump()
  if not self.PlayerHasJumped and self.PlayerHasDashed then
    if self:CheckIsPlayingAnimation() then
      return
    end
    self.PlayerHasJumped = true
    if self.isPC then
      if not self.PCPanel then
        self.PCPanel = self.MovePC:GetPanel()
      end
      if self.PCPanel then
        self.PCPanel:ChangeMode(Mode.End)
      else
        self.PlayerHasMoved = false
      end
    else
      self.LowerRight1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadLevelInfo, 1, 1, 1, 1, 1, 0)
  end
end

function UMG_DimoControl_C:OpenSetting()
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenMainPanel)
end

function UMG_DimoControl_C:OnTick(deltaTime)
  self.countDown = self.countDown - deltaTime
  if self.countDown < 0 then
    self.countDown = 1
    NRCModuleManager:DoCmd(CreatePlayerModuleCmd.UploadDimoLocation)
  end
end

function UMG_DimoControl_C:OnAnimationFinished(anim)
  if anim == self.TeachingGesture_Animation then
    self:PlayAnimation(self.TeachingGesture_Loop, nil, 99999)
  elseif anim == self.LowerLeft_Animation then
    self:PlayAnimation(self.LowerLeft_Loop, nil, 99999)
  elseif anim == self.LowerRight1_Animation then
    self:PlayAnimation(self.LowerRight1_Loop, nil, 99999)
  elseif anim == self.LowerRight2_Animation then
    self:PlayAnimation(self.LowerRight2_Loop, nil, 99999)
  end
end

function UMG_DimoControl_C:OnPCOpenSetting()
  self:OpenSetting()
end

return UMG_DimoControl_C
