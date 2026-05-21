local Base = require("NewRoco.Modules.Core.NPC.Lua_NPCBase")
local Lua_NPCMiniGameClock = Base:Extend("Lua_NPCMiniGameClock")

function Lua_NPCMiniGameClock:Ctor()
  Base.Ctor(self)
  self.BlockUpdate = false
  self.StarScale = 1
  self.StartSymbol = 1
  self.PlayRate = 1
  self.startPos = 0
  self.Valid = false
  self.DurationPer = 9999
  self.Activate = false
  self.Reset = false
  self.Finish = false
  self.timeout = false
  self.ConfigId = nil
  self.Finished = false
end

function Lua_NPCMiniGameClock:RefreshActive()
  local status = NRCModuleManager:DoCmd(MiniGameModuleCmd.GetState)
  if status == ProtoEnum.MinigameStatus.MS_RECOVERY or status == ProtoEnum.MinigameStatus.MS_OPEN then
    self.Activate = true
  else
    self.Activate = false
  end
end

function Lua_NPCMiniGameClock:InitActStatus(optionInfo)
  Base.InitActStatus(self, optionInfo)
  self:RefreshActive()
  if not self.Activate then
    if optionInfo.enabled == false or 0 == optionInfo.executable_times then
      self.Finished = true
    else
      self.Finished = false
    end
  end
  local OptionID = self.sceneCharacter.config.option_id
  if next(OptionID) == nil then
    return
  end
  local OptionConf = _G.DataConfigManager:GetNpcOptionConf(OptionID[1])
  if OptionConf and OptionConf.action and OptionConf.action.action_param1 then
    self.ConfigId = tonumber(OptionConf.action.action_param1)
  else
    self.ConfigId = false
  end
end

function Lua_NPCMiniGameClock:RecoverSettings()
  if not MiniGameModuleCmd then
    Log.Error("Lua_NPCMiniGameClock:MiniGameModuleCmd not inited")
    return false
  end
  local LocSet
  if self.ConfigId then
    LocSet = NRCModuleManager:DoCmd(MiniGameModuleCmd.GetSettings, self.ConfigId)
  end
  if not LocSet then
    return false
  end
  self.BlockUpdate = LocSet.BlockUpdate
  if not self.BlockUpdate and self.viewObj then
    self.viewObj.StarScale = self.StarScale
  end
  self.StartSymbol = LocSet.StartSymbol
  self.PlayRate = LocSet.PlayRate
  self.startPos = LocSet.StartPos
  self.Valid = LocSet.Valid
  self.DurationPer = LocSet.DurationPer
  self.Activate = LocSet.Activate
  self.Reset = LocSet.Reset
  self.Finish = LocSet.Finish
  self.Finished = LocSet.Finish
  self.timeout = LocSet.timeout
  return true
end

function Lua_NPCMiniGameClock:GetTimeActor()
  if not self then
    return nil
  end
  if not self.viewObj then
    return nil
  end
  local Time = self.viewObj.Time
  local Actor = Time and Time:GetChildActor()
  return Actor
end

function Lua_NPCMiniGameClock:ApplySettings()
  if not self.viewObj then
    return
  end
  if self.viewObj and not self:RecoverSettings() then
    self.viewObj.Activate = false
    self.viewObj.Reset = true
    return
  end
  local TimeActor = self:GetTimeActor()
  if not TimeActor then
    return
  end
  TimeActor.StartSymbol = self.StartSymbol
  TimeActor.DurationPer = self.DurationPer
  self.viewObj.PlayRate = self.PlayRate
  self.viewObj.StartPos = self.StartPos
  if not self.timeout then
    self.viewObj.Reset = self.Reset
  end
  self.viewObj.Finish = self.Finish
  self.viewObj.Activate = self.Activate
  if self.Activate then
    TimeActor:StartClock()
  end
  if self.Reset then
    _G.NRCAudioManager:PlaySound2DAuto(1342, "Lua_NPCMiniGameClock:ApplySettings")
  end
  if self.Finish or self.Reset then
    TimeActor:KillAll()
  end
end

function Lua_NPCMiniGameClock:ResetView()
  if not self.viewObj then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(1342, "Lua_NPCMiniGameClock:ApplySettings")
  self.viewObj.Reset = self.Reset
end

function Lua_NPCMiniGameClock:Poof()
  if not self.viewObj then
    return
  end
  self.viewObj:Poof()
end

return Lua_NPCMiniGameClock
