local SkillPerformAutoBattle = require("Common.LocalServer.SkillPerformAutoBattle")
local CopingSkillPerformAutoBattle = require("Common.LocalServer.CopingSkillPerformAutoBattle")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local SkillAutoPerform = require("Common.LocalServer.SkillPerformAutoBattle")
local SkillPerformAutoBattleUtils = {}

function SkillPerformAutoBattleUtils:IsRunning()
  return SkillPerformAutoBattle.isRunning
end

function SkillPerformAutoBattleUtils:IsStarted()
  return SkillPerformAutoBattle.isStarted
end

function SkillPerformAutoBattleUtils:IsFinished()
  return SkillPerformAutoBattle.isFinished
end

function SkillPerformAutoBattleUtils:HasAutoTestFinished()
  local FxPerfToolSubsystem = UE.USubsystemBlueprintLibrary.GetEngineSubsystem(UE.UFxPerfToolSubsystem)
  if SkillPerformAutoBattle.isRunning then
    return false
  elseif FxPerfToolSubsystem:GetRunningStatus() == UE.EPerfEventProfilerRunningStatus.Stopped then
    return true
  end
  return false
end

function SkillPerformAutoBattleUtils:UpdateLocalProtocol()
  if _G.AppMain:HasDebug() then
    local DebugTabNetwork = require("NewRoco.Modules.System.Debug.Tabs.DebugTabNetwork")
    DebugTabNetwork:StartHook()
  end
  local openID = SkillAutoPerform:GetOpenID()
  self:AutoLogin(openID)
  if _G.AppMain:HasDebug() then
    NRCModeManager:DoCmd(DebugModuleCmd.OpenOrClosePanel, false)
  end
end

function SkillPerformAutoBattleUtils:SimulateNormalBattle()
  local RSPTable = require("Common.LocalServer.LocalBattleRSPTable")
  RSPTable.SwitchToNormalBattle()
  self:UseLocalBattleServer(RSPTable)
  self:AutoLogin()
end

function SkillPerformAutoBattleUtils:Simulate2V2Battle()
  local RSPTable = require("Common.LocalServer.LocalBattleRSPTable")
  RSPTable.SwitchToSinglePlayer2V2Battle()
  self:UseLocalBattleServer(RSPTable)
  self:AutoLogin()
end

function SkillPerformAutoBattleUtils:SimulateBossBattle()
  local RSPTable = require("Common.LocalServer.LocalBattleRSPTable")
  RSPTable.SwitchToBossBattle()
  self:UseLocalBattleServer(RSPTable)
  self:AutoLogin()
end

function SkillPerformAutoBattleUtils:AutoPerformCopingSkill()
  local RSPTable = require("Common.LocalServer.LocalBattleRSPTable")
  RSPTable.SwitchToAutoBattleCoping()
  self:UseLocalBattleServer(RSPTable, true)
  CopingSkillPerformAutoBattle:Enable()
  CopingSkillPerformAutoBattle:SetEnterBattleInfo(RSPTable)
  self:AutoLoginForAutoPerform(CopingSkillPerformAutoBattle:GetOpenID())
end

function SkillPerformAutoBattleUtils:AutoPerformBattle()
  local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
  _G.DataConfigManager = _G.CreateSingleton("DataConfigManagerTest", "Common.DataConfigManager")
  _G.unload("Common.DataConfigManagerEx")
  _G.reload("Common.DataConfigManagerEx")
  BattleConst.FindBattleCenterByClient = true
  local RSPTable = require("Common.LocalServer.LocalBattleRSPTable")
  RSPTable.SwitchToAutoBattle()
  self:UseLocalBattleServer(RSPTable, true)
  SkillPerformAutoBattle:Enable()
  self:AutoLoginForAutoPerform(SkillPerformAutoBattle:GetOpenID())
end

function SkillPerformAutoBattleUtils:AutoLoginForAutoPerform(openID)
  self:AutoLogin(openID)
  if _G.AppMain:HasDebug() then
    NRCModeManager:DoCmd(DebugModuleCmd.OpenOrClosePanel, false)
  end
  local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
  NRCEventCenter:RegisterEvent("AutoPerformBattleOnServerListUpdated", self, LoginModuleEvent.OnServerListUpdated, function()
    _G.DelayManager:DelaySeconds(1.0, function()
      Log.Warning(string.format("AutoPerformBattleOnServerListUpdated SkillPerformAutoBattleUtils:AutoLogin(%s)", openID))
      self:AutoLogin(openID)
    end)
  end)
end

function SkillPerformAutoBattleUtils:UseLocalBattleServer(RSPTable, NoOpenUI)
  self:ChangeToLocalServer()
  _G.ZoneServer:SetRSPTable(RSPTable)
  if not NoOpenUI and _G.AppMain:HasDebug() then
    NRCModuleManager:DoCmd(_G.DebugModuleCmd.OpenLocalBattleDebug)
  end
end

function SkillPerformAutoBattleUtils:ChangeToLocalServer()
  if _G.ZoneServer.isLocalServer then
    return
  end
  _G.ZoneServer.isLocalServer = true
  local zoneServer = _G.ZoneServer
  local localServer = require("Common.LocalServer.LocalServer")
  Log.Warning("Switch To LocalServer")
  zoneServer.SendWithHandler = localServer.SendWithHandler
  zoneServer.Send = localServer.Send
  zoneServer.OnTick = localServer.OnTick
  zoneServer.SetRSPTable = localServer.SetRSPTable
  zoneServer.Connect = localServer.Connect
  _G.UpdateManager:Register(zoneServer)
end

function SkillPerformAutoBattleUtils:AutoLogin(openID)
  local LoginModule = NRCModuleManager:GetModule("LoginModule")
  local AutoTestUserName = openID or "zgx601"
  local Panel = LoginModule:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    local onlineMoudle = NRCModuleManager:GetModule("OnlineModule")
    NRCEventCenter:RegisterEvent("AutoPerformBattle", self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLoginSuccess)
    local tryLogin
    
    function tryLogin()
      Log.Warning("SkillPerformAutoBattleUtils:AutoLogin tryLogin")
      if not onlineMoudle.isLogin then
        Panel:OnClickLogin()
        _G.DelayManager:DelaySeconds(1.0, tryLogin)
      end
    end
    
    if onlineMoudle.isLogin then
      Panel:OnClickLogin()
    else
      Panel.data:SetOpenID(AutoTestUserName)
      Panel:OnClickLogin()
      _G.DelayManager:DelaySeconds(2.0, tryLogin)
    end
  else
    Log.Error("SkillPerformAutoBattleUtils:AutoLogin Panel is nil")
  end
end

function SkillPerformAutoBattleUtils:OnLoginSuccess()
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLoginSuccess)
  local LoginModule = NRCModuleManager:GetModule("LoginModule")
  local Panel = LoginModule:GetPanel(LoginEnum.PanelNames.NRCLoginPanel)
  if Panel then
    Panel:OnClickEnter()
  end
end

function SkillPerformAutoBattleUtils:GetCoping()
  local AllSkill = _G.DataConfigManager:GetAllByName("SKILL_CONF")
  local counterSkill = {}
  local counterSkillMap = {}
  local beCounterSkill = {}
  local beCounterSkillMap = {}
  local tInsert = table.insert
  local orderSkillList = {}
  for _, v in pairs(AllSkill) do
    tInsert(orderSkillList, v)
  end
  table.sort(orderSkillList, function(a, b)
    return a.id < b.id
  end)
  local test = {
    702073,
    702081,
    704022,
    709021,
    714019,
    718005
  }
  local skillCfg
  for _, v in ipairs(orderSkillList) do
    skillCfg = v
    local needPlay = not string.IsNilOrEmpty(skillCfg.name) and not string.find(skillCfg.name, "\230\181\139\232\175\149") and not string.IsNilOrEmpty(skillCfg.res_id) and skillCfg.id % 10 < 2 and skillCfg.Skill_Type and skillCfg.Skill_Type ~= Enum.SkillType.ST_NONE
    if needPlay then
      if not counterSkillMap[skillCfg.res_id] and skillCfg.skill_result and #skillCfg.skill_result > 0 then
        for i, v in pairs(skillCfg.skill_result) do
          local EffectConf = _G.DataConfigManager:GetEffectConf(v.effect_id, true)
          if EffectConf and EffectConf.effect_order == Enum.EffectType.ET_COUNTER then
            counterSkillMap[skillCfg.res_id] = skillCfg.id
            local realCountSkill = _G.SkillUtils.GetSkillConf(skillCfg.id + 1, true)
            if realCountSkill then
              counterSkillMap[realCountSkill.res_id] = realCountSkill.id
              tInsert(counterSkill, {
                id = realCountSkill.id,
                skillType = realCountSkill.Skill_Type,
                res_id = realCountSkill.res_id
              })
            end
          end
        end
      end
      if not beCounterSkillMap[skillCfg.res_id] and not counterSkillMap[skillCfg.res_id] and 0 == skillCfg.id % 10 then
        beCounterSkillMap[skillCfg.res_id] = skillCfg.id
        tInsert(beCounterSkill, {
          id = skillCfg.id,
          skillType = skillCfg.Skill_Type,
          res_id = skillCfg.res_id
        })
      end
    end
  end
  Log.Debug("DebugTabBattle:ExportCoping", #counterSkill, #beCounterSkill)
  return counterSkill, beCounterSkill
end

return SkillPerformAutoBattleUtils
