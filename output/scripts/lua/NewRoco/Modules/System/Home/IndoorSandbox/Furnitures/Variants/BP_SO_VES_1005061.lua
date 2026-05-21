local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local Base = require("NewRoco.Modules.System.Home.Res.NRCHomePlacementActor_C")
local BP_SO_VES_1005061 = Base:Extend("BP_SO_VES_1005061")

function BP_SO_VES_1005061:ReceiveBeginPlay()
  Base.ReceiveBeginPlay(self)
end

function BP_SO_VES_1005061:ReceiveEndPlay()
  Base.ReceiveEndPlay(self)
  if self.InfoComp then
    self.InfoComp.OnSoundChangedDelegate:Remove(self, self.OnSoundChanged)
  end
end

function BP_SO_VES_1005061:OnMeshLoaded()
  Base.OnMeshLoaded(self)
  Log.Debug("BP_SO_VES_1005061:OnMeshLoaded", self)
  self:ConditionLoadFx()
end

function BP_SO_VES_1005061:OnNpcChanged(Npc, bReady)
  self.Npc = Npc
  self.bNpcReady = bReady
  self.InfoComp = self.Npc:GetComponent(HomeNpcInfoComponent)
  Log.Debug("BP_SO_VES_1005061:OnNpcChanged", Npc, bReady, self)
  if bReady then
    self.InfoComp.OnSoundChangedDelegate:Add(self, self.OnSoundChanged)
    self:ConditionLoadFx()
  end
end

function BP_SO_VES_1005061:OnSoundChanged(Proxy)
  if not UE.UObject.IsValid(self) then
    Log.Error("BP_SO_VES_1005061:OnSoundChanged Invalid")
    return
  end
  Log.Debug("BP_SO_VES_1005061:OnSoundChanged", Proxy.EventName, self)
  self:RefreshFx()
end

function BP_SO_VES_1005061:RefreshFx()
  if self.InfoComp:AnySoundPlaying() then
    self:LuaPlayFx()
  else
    self:LuaStopFx()
  end
end

function BP_SO_VES_1005061:ConditionLoadFx()
  if self.bMeshLoaded and self.bNpcReady then
    self:RefreshFx()
  end
end

function BP_SO_VES_1005061:LuaPlayFx()
  Log.Debug("BP_SO_VES_1005061:LuaPlayFx", self)
  self:PlayFX()
end

function BP_SO_VES_1005061:LuaStopFx()
  Log.Debug("BP_SO_VES_1005061:LuaStopFx", self)
  self:StopFX()
end

return BP_SO_VES_1005061
