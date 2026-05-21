local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local EnhancedInputModuleEvent = require("NewRoco.Modules.Core.EnhancedInput.EnhancedInputModuleEvent")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local ProtoEnum = require("Data.PB.ProtoEnum")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local luaText = require("LuaText")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local Delegate = require("Utils.Delegate")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local ForceShowIdle = true
local UMG_Battle_Skill_List_C = NRCPanelBase:Extend("UMG_Battle_Skill_List_C")
UMG_Battle_Skill_List_C.State = {
  Enable = 0,
  Disable = 1,
  Ban = 2
}
local DefaultSkillNum = 4
local SkillState = UMG_Battle_Skill_List_C.State

function UMG_Battle_Skill_List_C:OnConstruct()
  self.bindActionSucceed = false
  self.FullyConstructedDelegate = Delegate()
  self.isFullyConstructed = false
  au.Launch(self:ConstructAsync(), function(ok, errorMessage)
    if ok then
    else
      Log.Error(errorMessage)
    end
    self.isFullyConstructed = true
    self.FullyConstructedDelegate:Invoke()
    self.FullyConstructedDelegate:Clear()
  end)
end

local function ConstructAsync(self)
  self.ItemList = {}
  self.skillPositionChangePerformItems = {}
  self.petSkillIdToChangePositionPerformItem = {}
  self.petSkillIdToItemDataModel = {}
  self.SkillItemLoaderList = {
    self.SkillItemLoader,
    self.SkillItemLoader_1,
    self.SkillItemLoader_2,
    self.SkillItemLoader_3,
    self.SkillItemLoader_4,
    self.SkillItemLoader_5,
    self.SkillItemLoader_6
  }
  local SlateVisibility = UE4.ESlateVisibility.Collapsed
  if _G.GlobalConfig.DebugOpenUI then
    SlateVisibility = UE4.ESlateVisibility.SelfHitTestInvisible
  end
  for i, skillItemLoader in ipairs(self.SkillItemLoaderList) do
    local ok, skillItem
    ok, skillItem = a.wait(self:LoadSkillItemByUmgLoaderAsync(skillItemLoader, SlateVisibility))
    local widgetName = "SkillItem"
    if i > 1 then
      widgetName = widgetName .. "_" .. tostring(i - 1)
    end
    if ok then
      self.ItemList[i] = skillItem
      self[widgetName] = skillItem
      skillItem:SetData(nil, nil, nil, self)
      skillItem:SetIndex(i)
    else
      Log.ErrorFormat("UMG_Battle_Skill_List_C:ConstructSkillItemAsync SkillItem %s loading failed", tostring(i))
      self.ItemList[i] = {}
    end
    a.wait(au.DelayFrames(1))
  end
  do
    local ok, skillItem
    ok, skillItem = a.wait(self:LoadSkillItemByUmgLoaderAsync(self.GlobalSkillItemLoader, SlateVisibility))
    if ok then
      self.GlobalSkillItem = skillItem
      self.GlobalSkillItem.normalBG:SetBrushSize(UE4.FVector2D(78, 78))
      skillItem:SetData(nil, nil, nil, self)
    else
      Log.Error("UMG_Battle_Skill_List_C:ConstructSkillItemAsync GlobalSkillItem loading failed")
      self.GlobalSkillItem = nil
    end
  end
  a.wait(au.DelayFrames(1))
  do
    local ok, skillItem = a.wait(self:LoadSkillItemByUmgLoaderAsync(self.SkillItem_EXLoader, UE4.ESlateVisibility.Collapsed))
    if ok then
      self.SkillItem_EX = skillItem
    else
      Log.Error("UMG_Battle_Skill_List_C:ConstructSkillItemAsync SkillItem_EX loading failed")
      self.SkillItem_EX = nil
    end
  end
  self.pet = nil
  self:SetBtnSwitchVisible(false)
  self.battleManager = _G.BattleManager
  self:AddListener()
  self.widgetType = BattleEnum.WidgetType.ENUM_SKILL_PANEL
  self.visible = false
  self.visibleCount = 0
  self.Showing = false
  self.ShowingForPerformChangeSkillPosition = false
  self:SetShowState(nil, nil)
  self.skillState = SkillState.Disable
  self.skillExState = nil
  self.IsPlayerSkillSuccess = false
  self.PlayerSkillData = nil
  self:PCKeySetting()
  if UE4Helper.IsPCMode() then
    local Padding = UE4.FMargin()
    Padding.Left = -257
    Padding.Top = -22
    Padding.Right = 370
    Padding.Bottom = 40
    self.GlobalSkillItem.PCKey.Slot:SetOffsets(Padding)
    Padding.Left = 17
    Padding.Top = -120
    Padding.Right = 100
    Padding.Bottom = 100
    self.GlobalSkillItemLoaderContainer.Slot:SetOffsets(Padding)
    Padding.Left = 14
    Padding.Top = -345
    Padding.Right = 76
    Padding.Bottom = 73
    self.BtnSwitch.Slot:SetOffsets(Padding)
  end
  self:PlayDisplacement()
  self:InitializeSkillItemsLayout()
end

UMG_Battle_Skill_List_C.ConstructAsync = a.sync(ConstructAsync)

function UMG_Battle_Skill_List_C:PlayDisplacement()
  if BattleUtils.IsTeam() then
    self:StopAllAnimations()
    self:PlayAnimation(self.Displacement)
  end
end

function UMG_Battle_Skill_List_C:OnEnable(...)
  self:OnActive(...)
end

function UMG_Battle_Skill_List_C:IsSkillOp()
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow and mainWindow.UMG_Battle_Operate and mainWindow.UMG_Battle_Operate.curIndex == BattleEnum.Operation.ENUM_SKILL then
    return true
  end
  return false
end

function UMG_Battle_Skill_List_C:OnActive(pet, playAnim, callback)
  if not self.isFullyConstructed then
    self.FullyConstructedDelegate:Add(nil, function()
      if self:IsSkillOp() then
        self:OnActive(pet, playAnim, callback)
      end
    end)
    return
  end
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow and mainWindow.pet then
    pet = mainWindow.pet
  end
  self:PCModeScreenSetting()
  if self.pet ~= pet then
    self:SetCurrentPet(pet, self.battleManager:GetCurrentStateName())
  end
  self:Show(playAnim, callback)
  self:SetUndoCallback()
end

function UMG_Battle_Skill_List_C:OnDisable()
  self:Hide(true)
end

function UMG_Battle_Skill_List_C:OnDeactive()
  self:Hide(true)
  self:CloseMagicAnimDelay()
end

function UMG_Battle_Skill_List_C:OnDestruct()
  self:RemoveListener()
  table.clear(self.ItemList)
  self.ItemList = nil
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  self:UnBindInputAction()
  self.FullyConstructedDelegate:Clear()
  self.FullyConstructedDelegate = nil
  self.petSkillIdToItemDataModel = {}
  self:CloseMagicAnimDelay()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.BattlePerformEvent.SimulateClickSkill1, self.SimulateClickSkill1)
end

function UMG_Battle_Skill_List_C:DoLongClickItem(index)
  local ItemList = self:GetItemList()
  if ItemList[index] then
    ItemList[index]:DoLongClick()
  end
end

function UMG_Battle_Skill_List_C:SelectItem(index, isPressed)
  local ItemList = self:GetItemList()
  if ItemList[index] then
    if isPressed then
      ItemList[index]:OnItemPressed()
    else
      ItemList[index]:OnItemRelease()
    end
  end
end

function UMG_Battle_Skill_List_C:recordInputActionTrigger(inputActionName)
  self.triggerInputActionName = inputActionName
end

function UMG_Battle_Skill_List_C:BindInputAction()
  if self.bindActionSucceed then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_Battle")
  if mappingContext then
    local actions = {
      {
        name = "IA_BattleGlobalSkillStart",
        method = "GlobalSkillStart"
      },
      {
        name = "IA_BattleGlobalSkillEnd",
        method = "GlobalSkillEnd"
      },
      {
        name = "IA_BattleChangePet",
        method = "TryChangePet"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:BindAction(action.name, self, action.method, UE.ETriggerEvent.Triggered)
    end
    self.bindActionSucceed = true
  end
end

function UMG_Battle_Skill_List_C:UnBindInputAction()
  if not self.bindActionSucceed then
    return
  end
  local mappingContext = self:GetInputMappingContext("IMC_Battle")
  if mappingContext then
    local actions = {
      {
        name = "IA_BattleGlobalSkillStart"
      },
      {
        name = "IA_BattleGlobalSkillEnd"
      },
      {
        name = "IA_BattleChangePet"
      }
    }
    for _, action in ipairs(actions) do
      mappingContext:UnBindAction(action.name)
    end
    self.bindActionSucceed = false
  end
  if "IA_BattleGlobalSkillStart" == self.triggerInputActionName then
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  end
end

function UMG_Battle_Skill_List_C:GlobalSkillStart()
  if not self.Showing then
    return
  end
  if self.triggerInputActionName then
    return
  else
    _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER, "IA_BattleGlobalSkillStart")
  end
  self.GlobalSkillItem:OnItemPressed()
end

function UMG_Battle_Skill_List_C:GlobalSkillEnd()
  if not self.Showing then
    return
  end
  if self.triggerInputActionName ~= "IA_BattleGlobalSkillStart" then
    return
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.INPUT_ACTION_TRIGGER)
  self.GlobalSkillItem:OnItemRelease()
end

function UMG_Battle_Skill_List_C:ReleasePcKey()
  if self.triggerInputActionName == "IA_BattleGlobalSkillStart" then
    self:GlobalSkillEnd()
  end
end

function UMG_Battle_Skill_List_C:SimulateClickSkill1()
  if self.ItemList and self.ItemList[1] then
    self.ItemList[1]:OnItemClick()
  end
end

function UMG_Battle_Skill_List_C:TryChangePet()
  if not self.Showing then
    return
  end
  if self.triggerInputActionName then
    return
  end
  local myPets = self.battleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
  if myPets and #myPets > 1 then
    self:_OnBtnSwitchClick()
  end
end

function UMG_Battle_Skill_List_C:_OnBtnSwitchClick()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1177, "UMG_Battle_Skill_List_C:_OnBtnSwitchClick")
  if not self.UndoCallback then
    return
  end
  if self.skillState ~= SkillState.Enable then
    return
  end
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1178, "UMG_Battle_Skill_List_C:_OnBtnSwitchClick")
  self.UndoCallback(self.UndoCaller)
end

function UMG_Battle_Skill_List_C:SetUpPCKey()
  if SystemSettingModuleCmd then
    if self.GlobalSkillItem then
      self.GlobalSkillItem.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleGlobalSkillStart")
      if "" ~= image then
        self.GlobalSkillItem.PCKey:SetImageMode(image)
      else
        self.GlobalSkillItem.PCKey:SetText(text)
      end
    end
    if self.SkillItem then
      self.SkillItem.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_1")
      if "" ~= image then
        self.SkillItem.PCKey:SetImageMode(image)
      else
        self.SkillItem.PCKey:SetText(text)
      end
    end
    if self.SkillItem_1 then
      self.SkillItem_1.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_2")
      if "" ~= image then
        self.SkillItem_1.PCKey:SetImageMode(image)
      else
        self.SkillItem_1.PCKey:SetText(text)
      end
    end
    if self.SkillItem_2 then
      self.SkillItem_2.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_3")
      if "" ~= image then
        self.SkillItem_2.PCKey:SetImageMode(image)
      else
        self.SkillItem_2.PCKey:SetText(text)
      end
    end
    if self.SkillItem_3 then
      self.SkillItem_3.PCKey:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleSelectItemStart_4")
      if "" ~= image then
        self.SkillItem_3.PCKey:SetImageMode(image)
      else
        self.SkillItem_3.PCKey:SetText(text)
      end
    end
    if self.PCKey_1 then
      self.PCKey_1:SetKeyVisibility(true)
      local text, image = _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.GetMappingKeyUIName, "IA_BattleChangePet")
      if "" ~= image then
        self.PCKey_1:SetImageMode(image)
      else
        self.PCKey_1:SetText(text)
      end
    end
  end
end

function UMG_Battle_Skill_List_C:SetUndoCallback()
  local mainWindow = BattleUtils.GetMainWindow()
  if mainWindow and mainWindow.undoCaller then
    self.UndoCallback = mainWindow.undoCallback
    self.UndoCaller = mainWindow.undoCaller
    local ItemList = self:GetItemList()
    for _, v in ipairs(ItemList) do
      v:SetUndoCallback(mainWindow.undoCaller, mainWindow.undoBattleSelect)
    end
  end
end

function UMG_Battle_Skill_List_C:SetBtnSwitchVisible(visible)
  if visible then
    self.BtnSwitch:SetVisibility(UE4.ESlateVisibility.Visible)
  elseif self.BtnSwitch then
    self.BtnSwitch:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skill_List_C:OnRoundStart()
  if self.pet then
    self:SetCurrentPet(self.pet, self.battleManager:GetCurrentStateName())
  end
end

function UMG_Battle_Skill_List_C:SetCurrentPet(pet, stateName)
  if not pet then
    Log.Error("UMG_Battle_Skill_List_C:SetCurrentPet et is nil")
    return
  end
  local isChangePet
  if not self:IsUsePlayerSkill(pet, Enum.EffectType.ET_ROLE_CHANGE_PET) then
    isChangePet = pet.team.RestPets[pet.card.pos] and true or false
  end
  if isChangePet then
    pet = pet.team.RestPets[pet.card.pos]
  end
  self.pet = pet
  if isChangePet then
    local ItemList = self:GetItemList()
    for i = 1, #ItemList do
      local skillItem = ItemList[i]
      local IsShowSkillEmpty = false
      if i <= DefaultSkillNum then
        IsShowSkillEmpty = true
      end
      if i > 1 then
        skillItem:SetData(nil, stateName, pet, self, IsShowSkillEmpty)
      else
        skillItem:SetCancel(pet)
      end
    end
    self.GlobalSkillItem:SetData(nil, stateName, pet)
  else
    local skillDisplayInfo = pet.skillComponent:GetSkillDisplayInfo()
    local skillMap = skillDisplayInfo and skillDisplayInfo.slotIndexToSkill or {}
    local tempSkillMap = {}
    local allSkills = pet.skillComponent.skills
    for _, skill in pairs(allSkills) do
      if skill.config.describe_type[1] == Enum.SkillDescribeType.SDT_TEMPORARY then
        tempSkillMap[skill.skillData.pos] = skill
      end
    end
    local ItemList = self:GetItemList()
    if not self.hasChangeSkillPet then
      self.hasChangeSkillPet = {}
    end
    local hasChangeSkill = false
    for i = 1, #ItemList do
      local skillItem = ItemList[i]
      local oneSkill = skillMap[i]
      local IsShowSkillEmpty = false
      if i <= DefaultSkillNum then
        IsShowSkillEmpty = true
      end
      if oneSkill then
        if self:IsNewSkill(oneSkill, skillItem.newSkill, pet, skillItem.CastPet) then
          self:CloseMagicAnimDelay()
          self.MagicAnimId = self:DelaySeconds(i * 0.2, self.PlayMagic, self, skillItem)
        end
        if tempSkillMap[i] then
          if oneSkill == tempSkillMap[i] or self.hasChangeSkillPet[self.pet.guid] then
            skillItem:SetData(oneSkill, stateName, pet, self, IsShowSkillEmpty)
          else
            hasChangeSkill = true
            skillItem:SetNewSkillData(oneSkill, stateName, pet, self, IsShowSkillEmpty)
            skillItem:SetData(oneSkill, stateName, pet, self, IsShowSkillEmpty)
          end
        else
          local fantasticBackgroundPath = ""
          local skillData = oneSkill and oneSkill.skillData
          local skillId = skillData and skillData.skill_id
          local seasonId = skillData and skillData.season_id
          local performFlag = skillData and skillData.perform_flag
          if performFlag == ProtoEnum.PET_SKILL_PERFORM_FLAG.PET_SKILL_PERFORM_FLAG_FANTASTIC then
            local paths = BattleUtils.GetFantasticBackgroundPathWithSkillAndSeason(skillId, seasonId)
            fantasticBackgroundPath = paths and paths.squareNm3 or fantasticBackgroundPath
          end
          skillItem:SetData(oneSkill, stateName, pet, self, IsShowSkillEmpty, fantasticBackgroundPath)
        end
      else
        skillItem:SetData(nil, stateName, pet, self, IsShowSkillEmpty)
      end
    end
    if hasChangeSkill then
      self.hasChangeSkillPet[self.pet.guid] = true
    end
    local GlobalSkill = skillDisplayInfo and skillDisplayInfo.globalSkillList or {}
    self.GlobalSkillItem:SetData(GlobalSkill[1], stateName, pet, self)
    self.GlobalSkillItem:SetIconInfo(pet)
    self.GlobalSkillItem:HidePoint()
    self.GlobalSkillItem:HideBubble()
    self.skillState = SkillState.Enable
    self:SetupExSkillButton(stateName, pet)
  end
  self.skillState = SkillState.Enable
  local color = self.skillState == SkillState.Enable and UE4.FLinearColor(1, 1, 1, 1) or UE4.FLinearColor(0.2, 0.2, 0.2, 1)
  if self.BtnSwitch then
    self.BtnSwitch:SetColorAndOpacity(color)
  end
  local myPets = self.battleManager.battlePawnManager:GetInFieldAllPet(BattleEnum.Team.ENUM_TEAM, true)
  if myPets and #myPets > 1 then
    self:SetBtnSwitchVisible(true)
  else
    self:SetBtnSwitchVisible(false)
  end
  self:CheckB1FinalBattleUI()
end

function UMG_Battle_Skill_List_C:CheckB1FinalBattleUI()
  if BattleUtils.IsB1FinalBattleP3() then
    self.GlobalSkillItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skill_List_C:CloseMagicAnimDelay()
  if self.MagicAnimId then
    self:CancelDelayByID(self.MagicAnimId)
  end
  self.MagicAnimId = nil
end

function UMG_Battle_Skill_List_C:RemoveDisabledSkill(skills)
  for i = #skills, 1, -1 do
    if skills[i].skillData.state == ProtoEnum.SkillState.SKILL_DISABLED or 0 == skills[i].skillData.pos then
      table.remove(skills, i)
    end
  end
  return skills
end

function UMG_Battle_Skill_List_C:RemoveDisabledRestSkill(skills)
  for i = #skills, 1, -1 do
    if skills[i].skillData.state == ProtoEnum.SkillState.SKILL_DISABLED then
      table.remove(skills, i)
    end
  end
  return skills
end

function UMG_Battle_Skill_List_C:IsUsePlayerSkill(pet, PlayerSkillType)
  if self.IsPlayerSkillSuccess and self.PlayerSkillData and self.PlayerSkillData.EffectConf.effect_order == PlayerSkillType and self.PlayerSkillData.OpPet.card.pos == pet.card.pos then
    return true
  end
  return false
end

function UMG_Battle_Skill_List_C:IsNewSkill(NewSkill, OldSkill, pet, CastPet)
  local newSkill = _G.BattleManager.battleRuntimeData:GetNewSkillBySpEnergy(NewSkill)
  if pet and CastPet and pet.card.guid == CastPet.card.guid and (not OldSkill and newSkill or OldSkill and newSkill and OldSkill.id ~= newSkill.id) then
    return true
  end
  return false
end

function UMG_Battle_Skill_List_C:PlayMagic(skillItem)
  if self and UE4.UObject.IsValid(self) then
    skillItem:PlayMagic()
  end
end

function UMG_Battle_Skill_List_C:CheckShouldTip(item, isCover)
  if not self.Showing then
    return false
  end
  if isCover then
    if self.curTipSkillBtn and not self.curTipSkillBtn:GetIsCover() and item ~= self.curTipSkillBtn then
      self:SetCurTipSkill(item)
      item:UpdateTips()
      return true
    end
  elseif not self.curTipSkillBtn then
    self:SetFirstTipSkill(item)
    self:SetCurTipSkill(item)
    return true
  end
  return false
end

function UMG_Battle_Skill_List_C:CheckHideTip(item)
  if self.firstTipSkillBtn and item == self.firstTipSkillBtn then
    self:HideCurTipSkill()
  end
end

function UMG_Battle_Skill_List_C:SetFirstTipSkill(item)
  self.firstTipSkillBtn = item
end

function UMG_Battle_Skill_List_C:SetCurTipSkill(item)
  self.curTipSkillBtn = item
end

function UMG_Battle_Skill_List_C:HideCurTipSkill()
  if self.curTipSkillBtn then
    self.curTipSkillBtn:CloseTips()
    self.firstTipSkillBtn = nil
    self.curTipSkillBtn = nil
  end
end

function UMG_Battle_Skill_List_C:SetupExSkillButton(stateName, pet)
  self.SkillItem_EX:SetVisibility(UE4.ESlateVisibility.Collapsed)
  do return end
  local SkillCheckReasonLst = {}
  local Enable = false
  for _, Skill in ipairs(self.pet.skillComponent:GetDisplaySkills()) do
    if Skill.type == Enum.SkillActiveType.SAT_NORMAL and 0 ~= Skill.energy then
      local canCast, reason = Skill:CanCast()
      table.insert(SkillCheckReasonLst, reason)
      Enable = Enable or canCast
    end
  end
  if Enable or self.skillState ~= SkillState.Enable then
    self.SkillItem_EX:SetVisibility(UE4.ESlateVisibility.Collapsed)
    return
  end
  local skillExID, skill
  local checkRes = self:CheckExSkillState(SkillCheckReasonLst)
  if checkRes then
    skill = self.pet.skillComponent:GetExSkillByType(ProtoEnum.SkillActiveType.SAT_LACKENERGY)
    if skill then
      if skill.config.energy_cost[1] >= self.pet.player.roleInfo.base.hp then
        skill = self.pet.skillComponent:GetExSkillByType(ProtoEnum.SkillActiveType.SAT_IDLE)
        skillExID = skill.config.id
        self.skillExState = BattleEnum.SkillPanelExButtonState.Idle
      else
        skillExID = skill.config.id
        self.skillExState = BattleEnum.SkillPanelExButtonState.RoleHp
      end
    end
  else
    skill = self.pet.skillComponent:GetExSkillByType(ProtoEnum.SkillActiveType.SAT_IDLE)
    skillExID = skill.config.id
    self.skillExState = BattleEnum.SkillPanelExButtonState.Idle
  end
  local skillConf = _G.DataConfigManager:GetSkillConf(skillExID, true)
  if skillConf and skillConf.icon then
    self.ImageBtnEx:SetPath(skillConf.icon)
  end
  self.SkillItem_EX:SetData(skill, stateName, pet, self)
  self.SkillItem_EX:HidePoint()
  self.SkillItem_EX:SetVisibility(UE4.ESlateVisibility.Visible)
  self.GlobalSkillItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_Battle_Skill_List_C:CheckExSkillState(reasonLst)
  for i, reason in ipairs(reasonLst) do
    if reason ~= BattleEnum.SkillFailToCastReason.LackEnergy and reason ~= BattleEnum.SkillFailToCastReason.LackHealth and nil ~= reason then
      return false
    end
  end
  return true
end

function UMG_Battle_Skill_List_C:AddListener()
  self.BtnSwitch.OnClicked:Add(self, self._OnBtnSwitchClick)
  _G.BattleEventCenter:Bind(self, BattleEvent.ROUND_START, BattleEvent.DIRECT_UPDATE_UI, BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL, BattleEvent.UI_HIDE, BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL, BattleEvent.UI_USE_PLAYERSKILL_UPDATE, BattleEvent.UPDATE_DATA, BattleEvent.B1BattleRefreshSkillItem)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Skill_List_C", self, EnhancedInputModuleEvent.KeyMappingsChanged, self.PCKeySetting)
  _G.NRCEventCenter:RegisterEvent("UMG_Battle_Skill_List_C", self, _G.BattlePerformEvent.SimulateClickSkill1, self.SimulateClickSkill1)
end

function UMG_Battle_Skill_List_C:RemoveListener()
  self.BtnSwitch.OnClicked:Remove(self, self._OnBtnSwitchClick)
  _G.BattleEventCenter:UnBind(self)
end

function UMG_Battle_Skill_List_C:OnBattleEvent(eventName, ...)
  if not BattleManager:IsInBattle() then
  end
  if eventName == BattleEvent.ROUND_START or eventName == BattleEvent.DIRECT_UPDATE_UI then
    self:OnRoundStart()
  elseif eventName == BattleEvent.BATTLE_BEGIN_USE_PLAYERSKILL then
  elseif eventName == BattleEvent.UI_HIDE then
    self:InitializedPlayerSkill()
    self:ClearItemCache()
  elseif eventName == BattleEvent.BATTLE_CLICKED_UI_CANCELPLAYERSKILL then
    self:InitializedPlayerSkill()
  elseif eventName == BattleEvent.UI_USE_PLAYERSKILL_UPDATE then
    self:PlayerSkillSuccess(...)
  elseif eventName == BattleEvent.UPDATE_DATA then
    self:UpdateData(...)
  elseif eventName == BattleEvent.B1BattleRefreshSkillItem then
    self:OnRoundStart()
  end
end

function UMG_Battle_Skill_List_C:PCKeySetting()
  self:SetUpPCKey()
end

function UMG_Battle_Skill_List_C:UpdateData(pet)
  local prevPetGuid = self.pet and self.pet.card and self.pet.card.guid
  local nextPetGuild = pet and pet.card and pet.card.guid
  self:SetCurrentPet(pet, self.battleManager:GetCurrentStateName())
  if prevPetGuid ~= nextPetGuild and self.Showing then
    self:Show(true)
  end
end

function UMG_Battle_Skill_List_C:ClearItemCache()
  local ItemList = self:GetItemList()
  self.GlobalSkillItem:OnItemRelease()
  for index = 1, #ItemList do
    if ItemList[index] then
      ItemList[index]:OnItemRelease()
    end
  end
end

function UMG_Battle_Skill_List_C:InitializedPlayerSkill()
  self.IsPlayerSkillSuccess = false
  self.PlayerSkillData = nil
end

function UMG_Battle_Skill_List_C:PlayerSkillSuccess(PlayerSkillData)
  self.IsPlayerSkillSuccess = true
  self.PlayerSkillData = PlayerSkillData
end

function UMG_Battle_Skill_List_C:StopShowHide()
  self:StopAllAnimations()
  self:SetShowState(false, nil)
end

function UMG_Battle_Skill_List_C:Show(playAnim, callback)
  Log.Debug("UMG_Battle_SKill_List_C:Show " .. tostring(playAnim))
  self.TweenOutCallback = nil
  self:RecycleAndHideAllPerformSkillItemThatNotRelativeToCurrentPet()
  if playAnim then
    self:StopAllAnimations()
    self.TweenInCallback = callback
    self:PlayAnimation(self.TweenIn)
    self:PlayOpenAnim(true)
  elseif callback then
    callback()
  end
  self:SetShowState(true, false)
  self:BindInputAction()
end

function UMG_Battle_Skill_List_C:ShowForPerformChangeSkillPosition()
  local skillItems = self:GetItemList()
  for i, skillItem in ipairs(skillItems) do
    skillItem.CanvasPanel_0:SetRenderOpacity(0)
  end
  self:SetShowState(nil, true)
end

function UMG_Battle_Skill_List_C:SetShowState(showingForSkillButtons, showingForSkillTransmission)
  if nil == showingForSkillButtons then
    showingForSkillButtons = self.Showing
  end
  if nil == showingForSkillTransmission then
    showingForSkillTransmission = self.ShowingForPerformChangeSkillPosition
  end
  local prevShow = self.Showing or self.ShowingForPerformChangeSkillPosition
  local nextShow = showingForSkillButtons or showingForSkillTransmission
  if self:IsAnimationPlaying(self.TweenIn) or self:IsAnimationPlaying(self.TweenOut) then
    nextShow = true
  end
  self.Showing = showingForSkillButtons
  self.ShowingForPerformChangeSkillPosition = showingForSkillTransmission
  if nextShow then
    self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Battle_Skill_List_C:HasChangeSkillItemDisplay()
  if not self.petSkillIdToChangePositionPerformItem then
    Log.Error("UMG_Battle_Skill_List_C:HasChangeSkillItemDisplay petSkillIdToChangePositionPerformItem is nil\239\188\140\229\175\185\232\177\161\229\143\175\232\131\189\229\183\178\231\187\143\232\162\171\230\158\144\230\158\132", UE.UObject.IsValid(self))
  end
  return self.petSkillIdToChangePositionPerformItem and next(self.petSkillIdToChangePositionPerformItem) ~= nil
end

function UMG_Battle_Skill_List_C:Hide(playAnim, callback)
  self.FullyConstructedDelegate:Clear()
  if not self.Showing then
    playAnim = false
  end
  self.TweenInCallback = nil
  self.TweenOutCallback = nil
  self:StopAllAnimations()
  if playAnim then
    self:PlayAnimation(self.TweenOut)
    self.TweenOutCallback = callback
    self:PlayOpenAnim(false)
  elseif callback then
    callback()
  end
  self:HideCurTipSkill()
  self:SetShowState(false, nil)
  self:UnBindInputAction()
end

function UMG_Battle_Skill_List_C:OnAnimationFinished(Animation)
  if Animation == self.TweenIn then
    self:SetShowState(nil, nil)
    local Callback = self.TweenInCallback
    self.TweenInCallback = nil
    if Callback then
      Callback()
    end
  elseif Animation == self.TweenOut then
    self:SetShowState(nil, nil)
    local Callback = self.TweenOutCallback
    self.TweenOutCallback = nil
    if Callback then
      Callback()
    end
  end
end

function UMG_Battle_Skill_List_C:CheckSkillStatus()
end

function UMG_Battle_Skill_List_C:PlayOpenAnim(_IsOpen)
  local ItemList = self:GetItemList()
  local indexToItem = BattleUtils.GetMainWindowSubPanelItemOpenOrderTable(ItemList)
  local excludeHideSkillIdMap = {}
  for i, skillItem in pairs(indexToItem) do
    if _IsOpen then
      skillItem.CanvasPanel_0:SetRenderOpacity(0)
      self:PlaySkillItemAnim(skillItem, _IsOpen, i)
      local petGuid = skillItem.CastPet and skillItem.CastPet.guid
      local skillId = skillItem:GetDataModelSkillId()
      if petGuid and skillId then
        if not excludeHideSkillIdMap[petGuid] then
          excludeHideSkillIdMap[petGuid] = {}
        end
        excludeHideSkillIdMap[petGuid][skillId] = true
      end
    else
      skillItem:PlayOpenAnimation(_IsOpen)
    end
  end
  self:CheckShowB1FinalBattleP3GuideLight(_IsOpen)
  self:RecycleAndHideAllBindChangePositionSkillItem(excludeHideSkillIdMap)
end

function UMG_Battle_Skill_List_C:CheckShowB1FinalBattleP3GuideLight(_IsOpen)
  if not BattleUtils.IsB1FinalBattleP3() then
    return
  end
  if not _IsOpen then
    NRCModuleManager:DoCmd(BattleUIModuleCmd.CloseBattleTutorialPanel1)
    return
  end
  local roundIndex = _G.BattleManager.battleRuntimeData.roundIndex
  if roundIndex and 1 == roundIndex then
    _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OpenBattleTutorialPanel1)
  end
end

function UMG_Battle_Skill_List_C:PlaySkillItemAnim(skillItem, _IsOpen, i)
  skillItem:DelayPlayAnim(_IsOpen, i)
end

function UMG_Battle_Skill_List_C:PCModeScreenSetting()
  if UE.UGameplayStatics.GetGameInstance(self):IsPCMode() then
    local Padding = UE4.FMargin()
    self.SubRootPanel:SetRenderScale(UE4.FVector2D(0.88, 0.88))
    Padding.Left = -70
    Padding.Top = 41
    Padding.Right = 70
    Padding.Bottom = -41
    self.SubRootPanel.Slot:SetOffsets(Padding)
  end
end

local function LoadSkillItemByUmgLoaderAsync(self, loader, defaultVisibility, callback)
  local OnLoadPanelCallback = function(ok, widget)
    loader.OnLoadPanelCallbackDelegate:Remove(nil, OnLoadPanelCallback)
    local widgetName = ""
    if ok then
      widgetName = widget:GetName()
    end
    Log.Debug("UMG_Battle_Skill_List_C:LoadSkillItemByUmgLoaderAsync OnLoadPanelCallback ", widgetName)
    if ok and nil ~= defaultVisibility then
      widget:SetVisibility(defaultVisibility)
    end
    callback(ok, widget)
  end
  loader.OnLoadPanelCallbackDelegate:Add(nil, OnLoadPanelCallback)
  loader:LoadPanel(nil)
end

UMG_Battle_Skill_List_C.LoadSkillItemByUmgLoaderAsync = a.wrap(LoadSkillItemByUmgLoaderAsync)

function UMG_Battle_Skill_List_C:GetItemList()
  if not self.isFullyConstructed then
    Log.Error("UMG_Battle_Skill_List_C:GetItemList Item List \229\176\154\230\156\170\229\138\160\232\189\189\229\174\140\230\136\144\239\188\140\232\175\183\230\163\128\230\159\165\230\151\182\229\186\143")
  end
  return self.ItemList
end

function UMG_Battle_Skill_List_C:BindSkillItemToPerformItem(petGuid, skillId, targetItem)
  skillId = _G.SkillUtils.CheckSkillId(skillId)
  local skillIdToPerformItem = self.petSkillIdToChangePositionPerformItem[petGuid]
  local currentItem = skillIdToPerformItem and skillIdToPerformItem[skillId]
  if currentItem then
    Log.Error("UMG_Battle_Skill_List_C:BindSkillItemToPerformItem \229\173\152\229\156\168\228\188\160\229\138\168\232\161\168\230\188\148\231\154\132\230\138\128\232\131\189\229\155\190\230\160\135\233\135\141\229\164\141\231\187\145\229\174\154\229\136\176\229\144\140\228\184\128\228\184\170 skill item \228\184\138\239\188\140\232\175\183\230\163\128\230\159\165, source: ", currentItem and currentItem.id, "target: ", targetItem and targetItem.skillId)
    self:HideRelativeChangePositionSkillItem(petGuid, skillId)
  end
  skillIdToPerformItem = self.petSkillIdToChangePositionPerformItem[petGuid]
  if not skillIdToPerformItem then
    skillIdToPerformItem = {}
    self.petSkillIdToChangePositionPerformItem[petGuid] = skillIdToPerformItem
  end
  skillIdToPerformItem[skillId] = targetItem
end

function UMG_Battle_Skill_List_C:ShouldPlayChangeSkill2(petGuid, skillId)
  skillId = _G.SkillUtils.CheckSkillId(skillId)
  local skillIdToPerformItem = self.petSkillIdToChangePositionPerformItem[petGuid]
  local targetItem = skillIdToPerformItem and skillIdToPerformItem[skillId]
  if targetItem then
    return true
  end
end

function UMG_Battle_Skill_List_C:HideRelativeChangePositionSkillItem(petGuid, skillId)
  skillId = _G.SkillUtils.CheckSkillId(skillId)
  local skillIdToPerformItem = self.petSkillIdToChangePositionPerformItem[petGuid]
  local targetItem = skillIdToPerformItem and skillIdToPerformItem[skillId]
  if targetItem then
    skillIdToPerformItem[skillId] = nil
    targetItem:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:RecyclePerformSkillItem(targetItem)
  end
end

UMG_Battle_Skill_List_C.TrackType = {
  External = 1,
  Main = 2,
  Internal = 3
}
UMG_Battle_Skill_List_C.TrackRadius = {
  [UMG_Battle_Skill_List_C.TrackType.External] = 900,
  [UMG_Battle_Skill_List_C.TrackType.Main] = 768,
  [UMG_Battle_Skill_List_C.TrackType.Internal] = 560
}
UMG_Battle_Skill_List_C.TrackLayoutAngleRange = {
  [UMG_Battle_Skill_List_C.TrackType.External] = {0, 0},
  [UMG_Battle_Skill_List_C.TrackType.Main] = {14, -32},
  [UMG_Battle_Skill_List_C.TrackType.Internal] = {14, -27}
}
UMG_Battle_Skill_List_C.TrackRenderAngleRange = {
  [UMG_Battle_Skill_List_C.TrackType.External] = {0, 0},
  [UMG_Battle_Skill_List_C.TrackType.Main] = {0, -10},
  [UMG_Battle_Skill_List_C.TrackType.Internal] = {2, -15}
}
UMG_Battle_Skill_List_C.TrackSkillItemCount = {
  [UMG_Battle_Skill_List_C.TrackType.External] = 0,
  [UMG_Battle_Skill_List_C.TrackType.Main] = 4,
  [UMG_Battle_Skill_List_C.TrackType.Internal] = 3
}

function UMG_Battle_Skill_List_C:CalculateSlotPositionByRadiusAndAngle(radius, angle)
  local circleImageSlot = self.CircleImage.Slot
  local circleCenter = circleImageSlot:GetPosition()
  local FVector2D = UE.FVector2D
  local angleRad = math.rad(angle)
  local polarOffset = FVector2D(math.cos(angleRad), math.sin(angleRad)) * radius
  polarOffset.X = -polarOffset.X
  polarOffset.Y = -polarOffset.Y
  local position = circleCenter + polarOffset
  return position
end

function UMG_Battle_Skill_List_C:CalculateSlotPositionByAngleRangeAndPercent(center, radius, minAngle, maxAngle, minRenderAngle, maxRenderAngle, percentage)
  local angle = LuaMathUtils.LerpWithAlpha(minAngle, maxAngle, percentage)
  local renderAngle = LuaMathUtils.LerpWithAlpha(minRenderAngle, maxRenderAngle, percentage)
  local position = self:CalculateSlotPositionByRadiusAndAngle(radius, angle)
  return position, renderAngle
end

function UMG_Battle_Skill_List_C:CalculateItemRenderAngleOnTrack(trackPosition)
  local count = UMG_Battle_Skill_List_C.TrackSkillItemCount[trackPosition.trackType]
  local percentage = (trackPosition.index - 1) / (count - 1)
  local minRenderAngle = UMG_Battle_Skill_List_C.TrackRenderAngleRange[trackPosition.trackType][1]
  local maxRenderAngle = UMG_Battle_Skill_List_C.TrackRenderAngleRange[trackPosition.trackType][2]
  local renderAngle = LuaMathUtils.LerpWithAlpha(minRenderAngle, maxRenderAngle, percentage)
  return renderAngle
end

function UMG_Battle_Skill_List_C:CalculateItemRenderAngleOnTrackWithAnyTrackAngle(trackType, angle)
  local minAngle = UMG_Battle_Skill_List_C.TrackLayoutAngleRange[trackType][1]
  local maxAngle = UMG_Battle_Skill_List_C.TrackLayoutAngleRange[trackType][2]
  local minRenderAngle = UMG_Battle_Skill_List_C.TrackRenderAngleRange[trackType][1]
  local maxRenderAngle = UMG_Battle_Skill_List_C.TrackRenderAngleRange[trackType][2]
  local percentage = (angle - minAngle) / (maxAngle - minAngle)
  local renderAngle = LuaMathUtils.LerpWithAlpha(minRenderAngle, maxRenderAngle, percentage)
  return renderAngle
end

function UMG_Battle_Skill_List_C:GetItemPositionOnTrack(trackPosition)
  local angle = self:GetAngleByTrackPosition(trackPosition)
  local radius = UMG_Battle_Skill_List_C.TrackRadius[trackPosition.trackType]
  return self:CalculateSlotPositionByRadiusAndAngle(radius, angle)
end

function UMG_Battle_Skill_List_C:GetAngleByTrackPosition(trackPosition)
  local count = UMG_Battle_Skill_List_C.TrackSkillItemCount[trackPosition.trackType]
  local percentage = (trackPosition.index - 1) / (count - 1)
  local minAngle = UMG_Battle_Skill_List_C.TrackLayoutAngleRange[trackPosition.trackType][1]
  local maxAngle = UMG_Battle_Skill_List_C.TrackLayoutAngleRange[trackPosition.trackType][2]
  local angle = LuaMathUtils.LerpWithAlpha(minAngle, maxAngle, percentage)
  return angle
end

function UMG_Battle_Skill_List_C:InitializeSkillItemsLayout()
  local mainTrackPositions = {
    [self.SkillItemLoaderContainer] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Main,
      index = 1
    },
    [self.SkillItemLoaderContainer_1] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Main,
      index = 2
    },
    [self.SkillItemLoaderContainer_2] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Main,
      index = 3
    },
    [self.SkillItemLoaderContainer_3] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Main,
      index = 4
    }
  }
  local internalTrackPositions = {
    [self.SkillItemLoaderContainer_4] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Internal,
      index = 1
    },
    [self.SkillItemLoaderContainer_5] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Internal,
      index = 2
    },
    [self.SkillItemLoaderContainer_6] = {
      trackType = UMG_Battle_Skill_List_C.TrackType.Internal,
      index = 3
    }
  }
  
  local function UpdateSkillItemWidgetPositionAndRenderAngleWithTrackPosition(skillItem, trackPosition)
    local position = self:GetItemPositionOnTrack(trackPosition)
    local renderAngle = self:CalculateItemRenderAngleOnTrack(trackPosition)
    local canvasSlot = skillItem.Slot
    canvasSlot:SetPosition(position)
    skillItem:SetRenderTransformAngle(renderAngle)
  end
  
  for skillItem, trackPosition in pairs(mainTrackPositions) do
    UpdateSkillItemWidgetPositionAndRenderAngleWithTrackPosition(skillItem, trackPosition)
  end
  for skillItem, trackPosition in pairs(internalTrackPositions) do
    UpdateSkillItemWidgetPositionAndRenderAngleWithTrackPosition(skillItem, trackPosition)
  end
end

function UMG_Battle_Skill_List_C:TryGetNextPerformSkillItem(asset)
  local foundItem
  for i, skillItem in ipairs(self.skillPositionChangePerformItems) do
    if not skillItem.isUsing then
      foundItem = skillItem
      break
    end
  end
  if not foundItem then
    local UWidgetBlueprintLibrary = UE4.UWidgetBlueprintLibrary
    local skillItem = UWidgetBlueprintLibrary.Create(_G.UE4Helper.GetCurrentWorld(), asset)
    skillItem.isUsing = false
    self.SubRootPanel:AddChildToCanvas(skillItem)
    local newSkillItemSlot = skillItem.Slot
    local anchors = UE4.FAnchors()
    anchors.Minimum = UE4.FVector2D(0, 0.5)
    anchors.Maximum = UE4.FVector2D(0, 0.5)
    newSkillItemSlot:SetSize(UE.FVector2D(100, 100))
    newSkillItemSlot:SetAnchors(anchors)
    table.insert(self.skillPositionChangePerformItems, skillItem)
    foundItem = skillItem
  end
  return foundItem
end

function UMG_Battle_Skill_List_C:RecyclePerformSkillItem(skillItem)
  skillItem.isUsing = false
  skillItem.currentAngle = nil
  skillItem.skillId = nil
end

function UMG_Battle_Skill_List_C:RecycleAndHideAllPerformSkillItemThatNotRelativeToCurrentPet()
  local currentPetGuid = self.pet and self.pet.guid or -1
  for petGuid, skillIdToChangeItem in pairs(self.petSkillIdToChangePositionPerformItem) do
    if petGuid ~= currentPetGuid then
      for skillId, item in pairs(skillIdToChangeItem) do
        item:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:RecyclePerformSkillItem(item)
        skillIdToChangeItem[skillId] = nil
      end
      self.petSkillIdToChangePositionPerformItem[petGuid] = nil
    end
  end
end

function UMG_Battle_Skill_List_C:RecycleAndHideAllBindChangePositionSkillItem(excludePetGuidAndSkillIdMap)
  excludePetGuidAndSkillIdMap = excludePetGuidAndSkillIdMap and excludePetGuidAndSkillIdMap or {}
  for petGuid, skillIdToPerformItem in pairs(self.petSkillIdToChangePositionPerformItem) do
    local petSkillIdMap = excludePetGuidAndSkillIdMap[petGuid] or {}
    for skillId, item in pairs(skillIdToPerformItem) do
      local skillExclude = petSkillIdMap[skillId] or false
      if skillExclude then
      else
        item:SetVisibility(UE4.ESlateVisibility.Collapsed)
        self:RecyclePerformSkillItem(item)
        skillIdToPerformItem[skillId] = nil
      end
    end
    if not next(skillIdToPerformItem) then
      self.petSkillIdToChangePositionPerformItem[petGuid] = nil
    end
  end
end

function UMG_Battle_Skill_List_C:UpdateItemDataModel(petGuid, skillId, dataModel)
  if not petGuid or not skillId then
    return
  end
  local changeInfo = self:GetItemDataModelChangeInfo(petGuid, skillId)
  if changeInfo then
    local currentAfter = changeInfo.after
    if currentAfter.round ~= dataModel.round then
      if currentAfter.round < dataModel.round then
        changeInfo.before = changeInfo.after
      else
        changeInfo.before = nil
      end
    end
    changeInfo.after = dataModel
  else
    local skillIdToChangeInfo = self.petSkillIdToItemDataModel[petGuid]
    if not skillIdToChangeInfo then
      self.petSkillIdToItemDataModel[petGuid] = {}
      skillIdToChangeInfo = self.petSkillIdToItemDataModel[petGuid]
    end
    skillIdToChangeInfo[skillId] = {after = dataModel, before = nil}
  end
end

function UMG_Battle_Skill_List_C:ClearItemDataModelBefore(petGuid, skillId)
  if not petGuid or not skillId then
    return
  end
  local changeInfo = self:GetItemDataModelChangeInfo(petGuid, skillId)
  if changeInfo then
    changeInfo.before = nil
  end
end

function UMG_Battle_Skill_List_C:GetItemDataModelChangeInfo(petGuid, skillId)
  if not petGuid then
    return nil
  end
  if not skillId then
    return nil
  end
  local skillIdToChangeInfo = self.petSkillIdToItemDataModel[petGuid]
  if not skillIdToChangeInfo then
    return nil
  end
  return skillIdToChangeInfo[skillId]
end

return UMG_Battle_Skill_List_C
