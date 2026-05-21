local MagicSkillAutomation
if _G.AppMain:HasDebug() then
  MagicSkillAutomation = require("NewRoco.Modules.System.Debug.MagicSkill.MagicSkillAutomation")
end
MagicSkillAutomator = {}

function MagicSkillAutomator.StartTest()
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "gc.TimeBetweenPurgingPendingKillObjects 999999999.1")
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "r.shadow.csmcaching 0")
  if _G.AppMain:HasDebug() then
    MagicSkillAutomation:StartAutomationWithSavedConfig()
  end
  return true
end

function MagicSkillAutomator.Reset()
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "gc.TimeBetweenPurgingPendingKillObjects 60")
  UE4.UKismetSystemLibrary.ExecuteConsoleCommand(UE4Helper.GetCurrentWorld(), "r.shadow.csmcaching 1")
end

function MagicSkillAutomator.HasFinished()
  if MagicSkillAutomation:IsFinished() then
    local PerfChannelSubsystem = UE.USubsystemBlueprintLibrary.GetEngineSubsystem(UE.UPerfChannelSubsystem)
    if PerfChannelSubsystem:GetRunningStatus() == UE.EPerfEventProfilerRunningStatus.Stopped then
      MagicSkillAutomator.Reset()
      return true
    end
  end
  return false
end

function MagicSkillAutomator.HasStarted()
  return MagicSkillAutomation:IsStarted()
end

return MagicSkillAutomator
