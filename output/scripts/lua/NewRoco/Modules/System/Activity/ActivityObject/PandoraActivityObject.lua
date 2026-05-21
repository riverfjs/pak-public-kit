local Base = require("NewRoco.Modules.System.Activity.ActivityObject.ActivityObjectBase")
local PandoraActivityObject = Base:Extend("PandoraActivityObject")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function PandoraActivityObject:OnConstruct(_conf, _briefInfo)
  assert(nil ~= _briefInfo, "Pandora activity briefInfo is nil")
  self.activityConf = {
    activity_type = ActivityEnum.ActivityTypeSpecial.PandoraActivity,
    id = _briefInfo.activityId,
    activity_name = _briefInfo.activityName,
    maintab_id = _briefInfo.maintabId,
    priority = _briefInfo.priority,
    icon = _briefInfo.icon,
    icon_select = _briefInfo.iconSelect,
    if_appear = true
  }
  self.viewClass = nil
  self.activityReady = false
end

function PandoraActivityObject:GetActivityShowStatus()
  local isBan = _G.NRCModuleManager:DoCmd(_G.FunctionBanManager.CheckUIFunctionBan, Enum.FunctionEntrance.FE_PANDORA)
  if isBan then
    return ActivityEnum.ActivityShowStatus.Disable_Shielding
  end
  if not self.activityReady then
    return ActivityEnum.ActivityShowStatus.Disable_AdditionalCond
  end
  return Base.GetActivityShowStatus(self)
end

function PandoraActivityObject:LoadViewClass(caller, callbackLoaded)
  local viewClass = self:GetPandoraViewClass()
  if self.activityReady and UE.UObject.IsValid(viewClass) then
    if callbackLoaded then
      callbackLoaded(viewClass, self)
    end
    return true
  end
  if callbackLoaded then
    callbackLoaded(nil, nil)
  end
  return true
end

function PandoraActivityObject:SetPandoraViewClass(viewClass)
  self.viewClass = viewClass
  if UE.UObject.IsValid(viewClass) then
    self.activityReady = true
  else
    Log.Error("PandoraActivityObject:SetPandoraViewClass viewClass is invalid")
    self.activityReady = false
  end
end

function PandoraActivityObject:GetPandoraViewClass()
  return self.viewClass
end

function PandoraActivityObject:SetActivityCompleted()
  self.viewClass = nil
  self.activityReady = false
  Base.SetActivityCompleted(self)
end

return PandoraActivityObject
