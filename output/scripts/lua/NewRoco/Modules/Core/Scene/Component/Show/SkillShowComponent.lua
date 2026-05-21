local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local DialogueUtils = require("NewRoco.Modules.System.Dialogue.DialogueUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local Base = ActorComponent
local SkillShowComponent = Base:Extend("SkillShowComponent")

function SkillShowComponent:Ctor()
  Base.Ctor(self)
end

function SkillShowComponent:Attach(owner)
  Base.Attach(self, owner)
  Log.Debug("\230\183\187\229\138\160\232\161\168\230\188\148\230\138\128\232\131\189\231\154\132Component")
  self.perform_callbacks = {}
  self.perform_commands = {}
  self.performConf_map = {}
  self.perform_proxy_map = {}
  self.priority_map = {}
  self.performConf = nil
end

function SkillShowComponent:DeAttach()
  Base.DeAttach(self)
end

function SkillShowComponent:Destroy()
  Base.Destroy(self)
end

function SkillShowComponent:PlayPerform(target, performConf, caller, callback, skillProxy, pre_start_caller, pre_start_callback, priority)
  if not self.owner.HoldingItemComponent then
    return
  end
  self.performConf = performConf
  self.petMap = {}
  self:AutoFillPetMap()
  local skill_path = self.performConf.skill_path
  local skill_name = self:GetSkillDisplayName(skill_path)
  local skillComponent = self.owner:GetSkillComponent()
  if not skillComponent then
    return
  end
  self.perform_callbacks[skill_name] = {
    caller = caller,
    callback = callback,
    pre_start_caller = pre_start_caller,
    pre_start_callback = pre_start_callback
  }
  self.performConf_map[skill_name] = performConf
  self.perform_proxy_map[skill_name] = skillProxy
  self.priority_map[skill_name] = priority or 0
  if self:IsAllItemPrepared(self.performConf) then
    self:PlayPerformInter()
  else
    self.owner.HoldingItemComponent:AddOrder(self.performConf.performer, self, self.OnItemLoadFinish, priority)
  end
end

function SkillShowComponent:OnItemLoadFinish()
  if not self.isPlaying then
    self:AutoFillPetMap()
    if self:IsAllItemPrepared(self.performConf) then
      self:PlayPerformInter()
    else
      Log.Error("\232\191\152\230\152\175\228\184\141\229\164\159\239\188\140\228\184\186\228\187\128\228\185\136\239\188\129\239\188\129\239\188\129")
    end
  end
end

function SkillShowComponent:GetItemByKey(key)
  return self.owner.HoldingItemComponent:GetItemByKey(key)
end

function SkillShowComponent:removeSuffix(str, suffix)
  if nil == suffix then
    suffix = "_C"
  end
  if string.sub(str, -string.len(suffix)) == suffix then
    return string.sub(str, 1, -string.len(suffix) - 1)
  end
  return str
end

function SkillShowComponent:GetSkillDisplayName(skill_path)
  local skill_paths = string.Split(skill_path, ".")
  if #skill_paths < 2 then
    Log.Error("Skill Path is strange", skill_path)
    return ""
  end
  skill_paths = string.split(skill_paths[1], "/")
  return self:removeSuffix(skill_paths[#skill_paths], "_C")
end

function SkillShowComponent:PlayPerformInter()
  if not self.performConf then
    return
  end
  if self.performConf.skill_path == "" then
    self:Clear()
    return
  end
  self.isPlaying = true
  local skill_path = self.performConf.skill_path
  local skill_name = self:GetSkillDisplayName(skill_path)
  if not self.owner then
    self:Clear()
    return
  end
  local skillComponent = self.owner:GetSkillComponent()
  if not skillComponent then
    self:Clear()
    Log.Error("Play skill with no skillComponent", self.performConf.skill_path)
    return
  end
  if skillComponent:IsPlayingSkill() then
    skillComponent:StopCurrentSkill()
  end
  local SkillProxy
  if self.perform_proxy_map[skill_name] then
    SkillProxy = self.perform_proxy_map[skill_name]
  else
    SkillProxy = RocoSkillProxy.Create(skill_path, skillComponent, self.priority_map[skill_name] or 0)
  end
  SkillProxy:SetForcePlaySkill(true)
  SkillProxy:SetCaster(self.owner:GetViewObject())
  SkillProxy:SetStartFailedAsEnd(true)
  SkillProxy:RegisterEventCallback("End", self, self.PlayPerformEnd)
  SkillProxy:RegisterEventCallback("PreEnd", self, self.PlayPerformEnd)
  SkillProxy:RegisterEventCallback("Interrupt", self, self.PlayPerformEnd)
  SkillProxy:RegisterEventCallback("PreStart", self, self.PreStart)
  self.perform_proxy_map[skill_name] = nil
  self.perform_commands[skill_name] = {}
  for i, item in ipairs(self.performConf.commands) do
    self.perform_commands[skill_name][item.event] = item
    SkillProxy:RegisterEventCallback(item.event, self, self.OnSkillEvent)
  end
  self.SkillProxy = SkillProxy
  SkillProxy:PlaySkill(self, self.PlayCallback)
end

function SkillShowComponent:PlayCallback(skillProxy, result)
  if result == UE4.ESkillStartResult.StartFailed then
    local skill_name = self:GetSkillDisplayName(skillProxy:GetSkillPath())
    self.petMap = {}
    self.isPlaying = false
    local callback_data = self.perform_callbacks[skill_name]
    if callback_data then
      local caller = callback_data.caller
      local callback = callback_data.callback
      if caller and callback then
        callback(caller)
      end
    end
    self.perform_callbacks[skill_name] = nil
  end
end

function SkillShowComponent:PreStart(EventName, SkillObj)
  if not self.performConf then
    return
  end
  local SkillDisplayName = self:removeSuffix(SkillObj:GetDisplayName())
  local targets = {}
  local characters = {}
  for index, modelInfo in ipairs(self.performConf.performer) do
    local key = modelInfo.key
    local item = self.owner.HoldingItemComponent:GetItemByKey(key)
    if modelInfo.character_index and modelInfo.character_index >= 0 then
      characters[modelInfo.character_index] = item
    elseif modelInfo.blackboard_key and modelInfo.blackboard_key ~= "" then
      if UE.UObject.IsValid(item) then
        SkillObj.Blackboard:SetValueAsObject(key, item)
      end
    else
      table.insert(targets, item)
    end
  end
  for _, blackboard_value in ipairs(self.performConf.skill_blackboard_value) do
    local Item = self:GetItemByKey(blackboard_value.key)
    if UE.UObject.IsValid(Item) then
      SkillObj.Blackboard:SetValueAsObject(blackboard_value.key, Item)
    end
  end
  for index, out_item in ipairs(self.performConf.out_value) do
    local Item = self:GetItemByKey(out_item.key)
    if UE.UObject.IsValid(Item) then
      SkillObj.Blackboard:SetValueAsObject(out_item.key, Item)
      table.insert(targets, Item)
    end
  end
  SkillObj:SetTargets(targets)
  SkillObj:SetCharacters(characters)
  local callback_data = self.perform_callbacks[SkillDisplayName]
  if callback_data then
    local caller = callback_data.pre_start_caller
    local callback = callback_data.pre_start_callback
    if caller and callback then
      callback(caller, SkillObj)
    end
    callback_data.pre_start_caller = nil
    callback_data.pre_start_callback = nil
  end
end

function SkillShowComponent:OnSkillEvent(EventName, SkillObj)
  local SkillDisplayName = self:removeSuffix(SkillObj:GetDisplayName())
  if self.perform_commands[SkillDisplayName] and self.perform_commands[SkillDisplayName][EventName] then
    local command = self.perform_commands[SkillDisplayName][EventName]
    local param1, param2, param3
    if command.params[1] and 1 == command.params[1].param_type then
      param1 = self.owner.HoldingItemComponent:GetItemByKey(command.params[1].param)
    end
    if command.params[2] and 1 == command.params[2].param_type then
      param1 = self.owner.HoldingItemComponent:GetItemByKey(command.params[2].param)
    end
    if command.params[3] and 1 == command.params[3].param_type then
      param1 = self.owner.HoldingItemComponent:GetItemByKey(command.params[3].param)
    end
    _G.NRCModuleManager:DoCmd(command.cmd_id, param1, param2, param3)
  end
end

function SkillShowComponent:PlayPerformEnd(Event, Skill)
  if not self.performConf then
    return
  end
  if not Skill then
    Log.Error("SkillShowComponent:PlayPerformEnd Skill is nil")
    return
  end
  self.SkillProxy = nil
  for key, item in pairs(self.petMap) do
    Skill.Blackboard:RemoveObjectValue(key)
  end
  local skill_name = self:removeSuffix(Skill:GetDisplayName())
  for _, item in ipairs(self.performConf_map[skill_name].performer) do
    if item.delete_model == true then
      self.owner.HoldingItemComponent:DestroyItem(item.key)
    end
  end
  for index, blackboard_value in ipairs(self.performConf.skill_blackboard_value) do
    local value = Skill.Blackboard:GetValueAsObject(blackboard_value.key)
    if value then
      self.owner.HoldingItemComponent:RegisterItem(blackboard_value.key, value)
      Skill.Blackboard:RemoveObjectValue(blackboard_value.key)
    end
    if blackboard_value.delete_model == true then
      self.owner.HoldingItemComponent:DestroyItem(blackboard_value.key)
    end
  end
  for index, out_item in ipairs(self.performConf.out_value) do
    Skill.Blackboard:RemoveObjectValue(out_item.key)
    if true == out_item.delete_value then
      self.owner.HoldingItemComponent:DestroyItem(out_item.key)
    end
    if true == out_item.release_value then
      self.owner.HoldingItemComponent:UnRegisterItem(out_item.key)
    end
  end
  self.petMap = {}
  self.isPlaying = false
  local callback_data = self.perform_callbacks[skill_name]
  if callback_data then
    local caller = callback_data.caller
    local callback = callback_data.callback
    if caller and callback then
      callback(caller)
    end
  end
  self.perform_callbacks[skill_name] = nil
end

function SkillShowComponent:AutoFillPetMap()
  if not self.performConf then
    return
  end
  for _, modelInfo in ipairs(self.performConf.performer) do
    local item = self:GetItemByIdAndKey(modelInfo.npc_id, modelInfo.key)
    if not self.petMap[modelInfo.key] and item then
      self.petMap[modelInfo.key] = item
    end
  end
end

function SkillShowComponent:IsAllItemPrepared(performConf)
  if not performConf then
    return true
  end
  for _, modelInfo in ipairs(performConf.performer) do
    if not self.petMap[modelInfo.key] then
      return false
    end
  end
  return true
end

function SkillShowComponent:GetItemByIdAndKey(ItemId, ItemKey)
  if not self.owner.HoldingItemComponent then
    return nil
  end
  return self.owner.HoldingItemComponent:GetItemByKey(ItemKey)
end

function SkillShowComponent:Clear()
end

function SkillShowComponent:StopAll()
  if self.owner.HoldingItemComponent then
    self.owner.HoldingItemComponent:CancelAllOrder()
  end
  if self.SkillProxy then
    self.SkillProxy:CancelSkill(UE4.ESkillActionResult.SkillActionResultInterrupted)
    self.SkillProxy:Destroy()
  end
  self.SkillProxy = nil
  self.performConf = nil
end

return SkillShowComponent
