local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattlePlayAnimBaseAction = require("NewRoco.Modules.Core.Battle.Fsm.Actions.Base.BattlePlayAnimBaseAction")
local Base = BattlePlayAnimBaseAction
local BattlePetMoveToRightPosAction = Base:Extend("BattlePetMoveToRightPosAction")

function BattlePetMoveToRightPosAction:Ctor(name, properties)
  Base.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
  self.TargetPoint = {}
  self.MovePets = {}
  self.BattlePetNumber = 0
  self.IsHideEnemyUI = false
  self.ShowPopList = {
    10,
    20,
    11,
    12,
    21,
    22
  }
  self.ShowPopIndex = 1
  self.ShowPopDetal = 0.5
end

function BattlePetMoveToRightPosAction:OnEnter()
  if BattleUtils.IsCrowdBattle() then
    self.BattlePetNumber = 0
    self.MovePets = {}
    local enemyPets = self.BattleManager.battlePawnManager:GetAllPets()
    for _, v in ipairs(enemyPets) do
      if v.teamEnm == BattleEnum.Team.ENUM_ENEMY and v.card:WillMove() and v.model then
        v:ShowPet()
        if 10 ~= v.card.petInfo.battle_inside_pet_info.cheers_tag then
          table.insert(self.MovePets, v)
        end
      end
    end
    if #self.MovePets > 0 then
      self:CalculateTargetPosition()
      local hudClassPath = "WidgetBlueprint'/Game/NewRoco/Modules/System/MainUI/Res/UMG_Hud_Pet.UMG_Hud_Pet_C'"
      _G.BattleResourceManager:LoadResAsync(self, hudClassPath, self.LoadHUDClassCallBack, self.LoadHUDClassCallBack)
    else
      self:Finish()
    end
    _G.BattleEventCenter:Dispatch(BattleEvent.SHOW_NO_MOVE_HP)
  else
    self:Finish()
  end
end

function BattlePetMoveToRightPosAction:LoadHUDClassCallBack(hudClass)
  self:ShowPerception(hudClass)
  self:MoveStart()
end

function BattlePetMoveToRightPosAction:ShowPerception(hudClass)
  if nil == hudClass then
    return
  end
  local BattleMain = BattleUtils.GetMainWindow()
  for _, v in ipairs(self.MovePets) do
    v.model.HeadWidget:SetHiddenInGame(false)
    local newHud = UE4.UWidgetBlueprintLibrary.Create(v.model, hudClass)
    v.model.HeadWidget:SetWidget(newHud)
    v.model.HeadWidget:SetComponentTickEnabled(true)
    local hud = v.model.HeadWidget:GetUserWidgetObject()
    if hud then
      hud:SetVisible(true)
      hud:ShowPerceptionHead(v, 2)
    end
    if BattleMain then
      if BattleMain.PerceptionPanel then
        BattleMain.PerceptionPanel:UpdateViewportInBattle()
        BattleMain.PerceptionPanel:TackActionToPlayer(v)
      else
        BattleMain.PerceptionPanel = NRCModuleManager:DoCmd(BattleUIModuleCmd.GetHudPerceptionPanel)
        if BattleMain.PerceptionPanel then
          BattleMain.PerceptionPanel:UpdateViewportInBattle()
          BattleMain.PerceptionPanel:TackActionToPlayer(v)
        end
      end
    end
  end
end

function BattlePetMoveToRightPosAction:HidePerception()
  local BattleMain = BattleUtils.GetMainWindow()
  for _, v in ipairs(self.MovePets) do
    if UE4.UObject.IsValid(v.model) then
      v.model.HeadWidget:SetHiddenInGame(true)
      v.model.HeadWidget:SetComponentTickEnabled(false)
      local hud = v.model.HeadWidget:GetUserWidgetObject()
      if hud then
        hud:SetVisible(false)
      end
    end
    if BattleMain and BattleMain.PerceptionPanel then
      BattleMain.PerceptionPanel:LosePlayer(v)
    end
  end
end

function BattlePetMoveToRightPosAction:CalculateTargetPosition()
  for _, v in ipairs(self.MovePets) do
    if not v.card:IsCheerPet() then
      self.BattlePetNumber = self.BattlePetNumber + 1
      local TargetTransform = self.BattleManager.vBattleField:GetPositionInBattleMap(v.teamEnm, v.card.posInField)
      table.insert(self.TargetPoint, UE4.FVector(TargetTransform.Translation.X, TargetTransform.Translation.Y, TargetTransform.Translation.Z))
    else
      table.insert(self.TargetPoint, self.BattleManager.vBattleField:GetPositionInElliptic(v.card.petInfo.battle_inside_pet_info.cheers_tag))
    end
  end
end

function BattlePetMoveToRightPosAction:StartShowPop()
  if self.ShowPopIndex < #self.ShowPopList then
    local index = self.ShowPopIndex
    for i = index + 1, #self.ShowPopList do
      local flag = self.ShowPopList[i]
      self.ShowPopIndex = i
      for _, v in ipairs(self.MovePets) do
        if v.card.petInfo.battle_inside_pet_info.cheers_tag == flag then
          _G.BattleEventCenter:Dispatch(BattleEvent.UI_SHOW_INFO_POPUP, {
            BattleEnum.InfoPopupType.PetJoin1VN,
            v
          }, self)
          self:SafeDelaySeconds("d_StartShowPop", self.ShowPopDetal, self.StartShowPop, self)
          return
        end
      end
    end
  end
end

function BattlePetMoveToRightPosAction:MoveStart()
  local pets = self.MovePets
  if 0 == self.BattlePetNumber then
    self:SafeDelaySeconds("d_FinishAction", 1, self.FinishAction, self)
  end
  for i, v in ipairs(pets) do
    v.card:SetWillMove(false)
    if not v.card:IsCheerPet() then
      v:MoveTo(self.TargetPoint[i], true, self.MoveFinish, self)
    else
      v:MoveTo(self.TargetPoint[i], true)
    end
  end
end

function BattlePetMoveToRightPosAction:HideEnemyUI()
  if not self.IsHideEnemyUI then
    self.IsHideEnemyUI = true
    self:ShowEnemyHp()
    self:HidePerception()
  end
end

function BattlePetMoveToRightPosAction:ShowEnemyHp()
  _G.BattleEventCenter:Dispatch(BattleEvent.ARRIVE_TARGETED_SHOW_ENEMY_HP)
end

function BattlePetMoveToRightPosAction:MoveFinish()
  self.BattlePetNumber = self.BattlePetNumber - 1
  if 0 == self.BattlePetNumber then
    self:FinishAction()
  end
end

function BattlePetMoveToRightPosAction:FinishAction()
  _G.BattleManager.vBattleField.battleCameraManager:CalcPos()
  self:HideEnemyUI()
  self.MovePets = {}
  self:Finish()
end

function BattlePetMoveToRightPosAction:OnFinish()
  _G.BattleEventCenter:UnBind(self)
end

return BattlePetMoveToRightPosAction
