local RealtimeDialogModuleCmd = require("NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleCmd")
local RealtimeDialogModuleEvent = require("NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleEvent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local DIALOG_UI_MAX_COUNT = 5
local RealtimeDialogModule = NRCModuleBase:Extend("RealtimeDialogModule")

function RealtimeDialogModule:OnConstruct()
  print("==amonsu=====RealtimeDialogModule===OnConstruct=")
  self.data = self:SetData("RealtimeDialogModuleData", "NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleData")
  self.DialogKeyList = {}
  self.DialogList = {}
  self.TickTimer = {}
  self.PerformerList = {}
  self:RegisterCmd(RealtimeDialogModuleCmd.StartRealtimeDialogByNpc, self.StartRealtimeDialogByNpc)
  self:RegisterCmd(RealtimeDialogModuleCmd.StopRealtimeDialogByNpc, self.StopRealtimeDialogByNpc)
  self:RegisterCmd(RealtimeDialogModuleCmd.StartRealtimeDialogByOption, self.StartRealtimeDialogByOption)
  self:RegisterCmd(RealtimeDialogModuleCmd.StartRealtimeDialog, self.StartRealtimeDialog)
  self:RegisterCmd(RealtimeDialogModuleCmd.UpdateDialogList, self.UpdateDialogList)
  self:RegisterCmd(RealtimeDialogModuleCmd.CloseDialogPanel, self.CloseDialogPanel)
  self:RegisterCmd(RealtimeDialogModuleCmd.FinishDialogOption, self.FinishDialogOption)
end

function RealtimeDialogModule:StartRealtimeDialogByOption(Option, DialogConf)
  print("==amonsu=====RealtimeDialogModule===StartRealtimeDialogByOption=", DialogConf.id, table.contains(self.DialogList, Option.config.id))
  if table.contains(self.DialogList, Option.config.id) then
    Log.Debug("amonsu: \229\189\147\229\137\141\230\176\148\230\179\161\229\175\185\232\175\157\230\173\163\229\156\168\232\191\155\232\161\140\228\184\173, OptionID:", Option.config.id)
    return
  end
  if not table.contains(self.DialogList, Option.config.id) then
    table.insert(self.DialogList, Option.config.id)
  end
  local Actor = DialogueUtils.GetActor(DialogConf.speaker, Option.owner)
  if not Actor then
    Log.Error("amonsu===RealtimeDialogModule====StartRealtimeDialogByOption==Speaker Is Nil!==", Option.config.id, DialogConf.id, DialogConf.speaker)
    return
  end
  self:SetAllPerformerAIEnabled(DialogConf, false)
  self:StartRealtimeDialog(Actor.config.id, DialogConf, Actor, Option.config.id)
end

function RealtimeDialogModule:StartRealtimeDialogByNpc(Npc, DialogConf)
  self:StartRealtimeDialog(Npc.config.id, DialogConf, Npc, -1)
end

function RealtimeDialogModule:StartRealtimeDialogByNpcText(Npc, ID, Text)
  local DialogConf = {
    id = ID,
    text = Text,
    speaker = Npc.config.id
  }
  if table.contains(self.DialogList, ID) then
    Log.Debug("amonsu: \229\189\147\229\137\141\230\176\148\230\179\161\229\175\185\232\175\157\230\173\163\229\156\168\232\191\155\232\161\140\228\184\173, NPC:", Npc.config.id, ID)
    return
  end
  if not table.contains(self.DialogList, ID) then
    table.insert(self.DialogList, ID)
  end
  self:StartRealtimeDialog(Npc.config.id, DialogConf, Npc, ID)
end

function RealtimeDialogModule:StartRealtimeDialog(DialogKey, DialogConf, Actor, OptionID)
  if not DialogConf then
    return
  end
  if DIALOG_UI_MAX_COUNT == #self.DialogKeyList then
    Log.Error("amonsu: \229\164\180\233\161\182\230\176\148\230\179\161\230\152\190\231\164\186\232\182\133\232\191\135\230\156\128\229\164\167\230\149\176\233\135\143\239\188\140\230\156\128\230\150\176\229\175\185\232\175\157ID\228\184\186", DialogConf.id)
  end
  print("==amonsu=====RealtimeDialogModule===StartRealtimeDialog=", DialogConf.id, DialogConf.speaker)
  if DialogConf and DialogConf.speaker then
    self:RemoveTickTimer(DialogKey .. DialogConf.id)
    if not self:TickCheck(DialogKey, DialogConf, Actor, OptionID) then
      self.TickTimer[DialogKey .. DialogConf.id] = _G.TimerManager:CreateTimer(self, "RealtimeDialogModule:TickCheck" .. DialogKey .. DialogConf.id, 5, function()
        self:TickCheck(DialogKey, DialogConf, Actor, OptionID)
      end, function()
        self:CheckTimeout(DialogKey, DialogConf)
      end, 1)
    end
  end
end

function RealtimeDialogModule:StopRealtimeDialogByNpc(Npc)
  self:CloseDialogPanel(Npc)
end

function RealtimeDialogModule:OpenDialogPanel(DialogKey, DialogConf, Actor, OptionID)
  print("==amonsu=====RealtimeDialogModule===OpenDialogPanel=", DialogConf.id)
  if DialogConf.speaker then
    if not Actor then
      return
    end
    local Performs = DialogConf.actor_perform
    if Performs and #Performs > 0 then
      for _, Perform in ipairs(Performs) do
        self:ConsumeActorPerform(Perform, DialogConf)
      end
    end
    local View = Actor.viewObj
    if View then
      local HeadWidget = View.HeadWidget
      if HeadWidget then
        local HUD = HeadWidget:GetUserWidgetObject()
        if HUD then
          HUD:SetDialogPanelInfo(DialogKey, DialogConf, Actor, OptionID)
        end
      end
    end
  end
end

function RealtimeDialogModule:CloseDialogPanel(Actor, DialogConf)
  if DialogConf then
    print("==amonsu=====RealtimeDialogModule===CloseDialogPanel=", DialogConf.id)
  end
  if not Actor then
    return
  end
  if DialogConf then
    local Performs = DialogConf.actor_perform
    if Performs and #Performs > 0 then
      for _, Perform in ipairs(Performs) do
        if -1 == Perform.actor then
          local player = DialogueUtils.GetPlayer()
          if player then
            local headLookAt = player:GetHeadLookAtComponent()
            if headLookAt then
              headLookAt:DisableManualOverride()
            end
          end
        end
      end
    end
  end
  local View = Actor.viewObj
  if View then
    local HeadWidget = View.HeadWidget
    if HeadWidget then
      local HUD = HeadWidget:GetUserWidgetObject()
      if HUD then
        HUD:SetDialogPanelVisible(false)
      end
    end
  end
end

function RealtimeDialogModule:UpdateDialogList(DialogKey, OptionID, bInProgress, DialogConf)
  print("==amonsu=====RealtimeDialogModule===UpdateDialogList=", OptionID, bInProgress, table.contains(self.DialogKeyList, DialogKey))
  if bInProgress then
    if not table.contains(self.DialogKeyList, DialogKey) then
      table.insert(self.DialogKeyList, DialogKey)
    end
  else
    table.removeValue(self.DialogKeyList, DialogKey)
    if DialogConf and 0 == DialogConf.next_dialog_id then
      self:FinishDialogOption(OptionID, DialogConf)
    end
  end
end

function RealtimeDialogModule:FinishDialogOption(OptionID, DialogConf)
  self:SetAllPerformerAIEnabled(DialogConf, true)
  table.removeValue(self.DialogList, OptionID)
end

function RealtimeDialogModule:TickCheck(DialogKey, DialogConf, Actor, OptionID)
  if self:Check(Actor, DialogConf) then
    self:RemoveTickTimer(DialogKey .. DialogConf.id)
    self:OpenDialogPanel(DialogKey, DialogConf, Actor, OptionID)
    return true
  end
  return false
end

function RealtimeDialogModule:CheckTimeout(DialogKey, DialogConf)
  self:RemoveTickTimer(DialogKey .. DialogConf.id)
  self:SetAllPerformerAIEnabled(DialogConf, true)
  Log.Debug("==amonsu======NPCDialogRealtimeAction===CheckTimeout==DialogConf:", DialogConf.id)
end

function RealtimeDialogModule:Check(Actor, DialogConf)
  if not DialogConf then
    return false
  end
  if not Actor then
    return false
  end
  if Actor.isDestroy then
    return false
  end
  local View = Actor.viewObj
  if not View then
    return false
  end
  if (UE.UObject.IsA(View, UE.ANPCBaseActor) or UE.UObject.IsA(View, UE.ANPCBaseCharacter)) and not View.resourceLoaded then
    return false
  end
  return true
end

function RealtimeDialogModule:RemoveTickTimer(TimerKey)
  local TickTimer = self.TickTimer[TimerKey]
  if TickTimer then
    _G.TimerManager:RemoveTimer(TickTimer)
    self.TickTimer[TimerKey] = nil
  end
end

function RealtimeDialogModule:ConsumeActorPerform(Perform, DialogConf)
  if not Perform then
    return
  end
  local Actor = DialogueUtils.GrabActor(Perform.actor)
  if not Actor or Actor.isDestroy then
    return
  end
  if Actor.config and 1 == Actor.config.not_turn_face then
    return
  end
  if not string.IsNilOrEmpty(Perform.action) then
    if Perform.action == "AI" then
      return
    end
    DialogueUtils.PlayAnim(Actor, Perform.action)
  end
  local HeadLookAt = Actor:GetHeadLookAtComponent()
  if not HeadLookAt then
    return
  end
  if Perform.body_turn_to < 0 or Perform.body_turn_to > 360 then
    local NPCView = DialogueUtils.GrabActorView(Perform.body_turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, NPCView)
    end
  elseif Perform.body_turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Body, nil, nil, nil, 0, math.fmod(Perform.body_turn_to, 360))
  end
  if Perform.turn_to < 0 or Perform.turn_to > 360 then
    local NPCView = DialogueUtils.GrabActorView(Perform.turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, NPCView)
    end
  elseif Perform.turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Head, nil, nil, nil, 0, math.fmod(Perform.turn_to, 360))
  end
  if Perform.eye_turn_to < 0 or Perform.eye_turn_to > 360 then
    local NPCView = DialogueUtils.GrabActorView(Perform.eye_turn_to)
    if NPCView then
      HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, NPCView)
    end
  elseif Perform.eye_turn_to > 0 then
    HeadLookAt:SetAutoLookAtParam(UE4.ELookAtParamType.Eye, nil, nil, nil, 0, math.fmod(Perform.eye_turn_to, 360))
  end
  HeadLookAt:ActiveAutoLookAt(false, nil, true)
  HeadLookAt:EnableManualOverride()
  HeadLookAt:CalculateAutoLookAt(true)
  if Perform.shakehead then
    Actor:DoHeadMotion(Perform.shakehead or Enum.HeadMotion.Shake)
  end
  if Perform.hidden_switch and 0 ~= Perform.hidden_switch then
    local HidComp = Actor:GetComponent(HiddenComponent)
    if HidComp and HidComp:CanHide() then
      if 2 == Perform.hidden_switch then
        HidComp:BeginHide()
      else
        HidComp:EndHide(self, function()
        end)
      end
      if Actor.AIComponent then
        Actor.AIComponent:OnHiddenStatusChangedInDialogue(2 == Perform.hidden_switch, DialogConf and DialogConf.id or 0)
      end
    end
  end
end

function RealtimeDialogModule:GetPerformers(DialogConf)
  local Performs = DialogConf.actor_perform
  if Performs and #Performs > 0 then
    for _, Perform in ipairs(Performs) do
      if Perform.actor then
        local Actor = DialogueUtils.GrabActor(Perform.actor)
        if Actor then
          local ID = Actor.serverData.base.actor_id
          if not table.contains(self.PerformerList, ID) then
            table.insert(self.PerformerList, ID)
          end
        end
      end
    end
  end
end

function RealtimeDialogModule:SetAllPerformerAIEnabled(DialogConf, bEnabled)
  if bEnabled then
    for i, ID in ipairs(self.PerformerList) do
      local Character = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ID)
      if Character then
        if not Character.config or 1 ~= Character.config.is_clean_ani then
          DialogueUtils.StopAnim(Character, 0.1)
        end
        DialogueUtils.StopTalk(Character, 0.1)
        DialogueUtils.StopLookAt(Character)
        DialogueUtils.StopTurn(Character)
        DialogueUtils.ToggleLOD(Character, false)
        DialogueUtils.ToggleAI(Character, true)
      end
    end
  else
    self.PerformerList = {}
    local CurDialogConf = DialogConf
    while CurDialogConf.next_dialog_id and 0 ~= CurDialogConf.next_dialog_id do
      self:GetPerformers(CurDialogConf)
      CurDialogConf = _G.DataConfigManager:GetDialogueConf(CurDialogConf.next_dialog_id)
    end
    for i, ID in ipairs(self.PerformerList) do
      local Character = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ID)
      if Character then
        DialogueUtils.ToggleAI(Character, false)
        DialogueUtils.ToggleLOD(Character, true)
        DialogueUtils.StopTurn(Character)
      end
    end
  end
end

return RealtimeDialogModule
