local HomeEnterMap = Class("HomeEnterMap")

function HomeEnterMap:Ctor()
end

function HomeEnterMap:Destroy()
end

function HomeEnterMap:OnExitHome()
end

function HomeEnterMap:ReqEnterHome(HomeInfo)
  local IndoorSandbox = HomeIndoorSandbox
  if not IndoorSandbox:Ensure(not self.bInHomeIndoor, "enter exits home?") then
    return
  end
  self.bInHomeIndoor = false
  IndoorSandbox.TaskMgr:CleanAllTasks()
  IndoorSandbox.TaskMgr:EnQueTask(IndoorSandbox.TaskMgr.TaskModules.AsyncTask, {
    {
      IndoorSandbox.TaskMgr.TaskModules.PreloadTask,
      IndoorSandbox.Define.ControlPawnClassPath
    },
    {
      IndoorSandbox.TaskMgr.TaskModules.PreloadTask,
      IndoorSandbox.Define.PropsStatusClassPath
    }
  })
  self:DoEnterMap(HomeInfo)
end

function HomeEnterMap:DoEnterMap(HomeInfo)
  HomeIndoorSandbox:LogInfo("DoEnterMap")
  self.bInHomeIndoor = true
  self:InternalEnterMap(HomeInfo)
end

function HomeEnterMap:ReqExitHome(bPassive)
  if self.bInHomeIndoor then
    local IndoorSandbox = HomeIndoorSandbox
    IndoorSandbox.TaskMgr:CleanAllTasks()
    if bPassive then
      self:DoExitMap()
    else
      IndoorSandbox.Server:ReqExitHome()
    end
  end
end

function HomeEnterMap:DoExitMap()
  HomeIndoorSandbox:LogInfo("DoExitMap", self.bInHomeIndoor)
  if self.bInHomeIndoor then
    self.bInHomeIndoor = false
    self:InternalExitMap()
  end
end

function HomeEnterMap:InternalEnterMap(HomeInfo)
  _G.FunctionBanManager:RegisterConditionTypeChangeListener(self, self.OnPlayerConditionTypeChanged)
  HomeIndoorSandbox.World:Instantiate(HomeInfo)
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnEnterHomeMap)
  HomeIndoorSandbox.HomeAIServ:OnEnterHome()
  self:RefreshFunctionBanInPlace()
end

function HomeEnterMap:RefreshFunctionBanInPlace()
  local Key
  if HomeIndoorSandbox.Server:IsLocalMaster() then
    Key = Enum.PlayerConditionType.PCT_AT_HOME
  else
    Key = Enum.PlayerConditionType.PCT_VISIT_HOME
  end
  if Key ~= self.FunctionBanKey then
    if self.FunctionBanKey then
      HomeIndoorSandbox:LogDebug("RemovePlayerConditionType", self.FunctionBanKey)
      _G.FunctionBanManager:RemovePlayerConditionType(self.FunctionBanKey)
    end
    self.FunctionBanKey = Key
    if Key then
      HomeIndoorSandbox:LogDebug("AddPlayerConditionType", self.FunctionBanKey)
      _G.FunctionBanManager:AddPlayerConditionType(Key)
    end
  end
end

function HomeEnterMap:InternalExitMap()
  _G.FunctionBanManager:UnRegisterConditionTypeChangeListener(self, self.OnPlayerConditionTypeChanged)
  HomeIndoorSandbox.Module:CloseAllPanel()
  HomeIndoorSandbox:OnExitMap()
  HomeIndoorSandbox.World:Destroy()
  HomeIndoorSandbox:DispatchEvent(HomeIndoorSandbox.Event.OnExitHomeMap)
  if self.FunctionBanKey then
    HomeIndoorSandbox:LogDebug("RemovePlayerConditionType InternalExitMap", self.FunctionBanKey)
    _G.FunctionBanManager:RemovePlayerConditionType(self.FunctionBanKey)
    self.FunctionBanKey = nil
  end
end

function HomeEnterMap:OnPlayerConditionTypeChanged(ConditionType, bHasConditionType)
  if ConditionType == Enum.PlayerConditionType.PCT_SITDOWN and not bHasConditionType then
    HomeIndoorSandbox.World.Controller:StopResolveObstacle()
  end
end

return HomeEnterMap
