local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local Sound2DProxy = require("NewRoco.Modules.System.Home.IndoorSandbox.Proxy.Sound2DProxy")
local Base = ActorComponent
local Delegate = require("Utils.Delegate")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local HomeNpcInfoComponent = Base:Extend("HomeNpcInfoComponent")
local EnumComponentFlag = {
  None = 0,
  FurnitureLoaded = 2,
  NPCVisible = 4
}

function HomeNpcInfoComponent:Ctor(NpcId, FurnitureId)
  self.NpcId = NpcId
  self.FurnitureId = FurnitureId
  Log.Debug("HomeNpcInfoComponent:Construct", self.NpcId, self.FurnitureId)
  self.Flag = EnumComponentFlag.None
  self.bReady = false
  self.OnSoundChangedDelegate = Delegate()
  self.OnReadyChangedDelegate = Delegate()
end

function HomeNpcInfoComponent:Attach(owner)
  Base.Attach(self, owner)
  SceneUtils.RegisterNPCVisibilityNotify(self, true)
end

function HomeNpcInfoComponent:DeAttach()
  Base.DeAttach(self)
  SceneUtils.UnregisterNPCVisibilityNotify(self)
end

function HomeNpcInfoComponent:OnFurniturePostLoad()
  if 0 == self.Flag & EnumComponentFlag.FurnitureLoaded then
    self.Flag = self.Flag | EnumComponentFlag.FurnitureLoaded
    self:OnDirty()
  end
end

function HomeNpcInfoComponent:OnVisible()
  if 0 == self.Flag & EnumComponentFlag.NPCVisible then
    self.Flag = self.Flag | EnumComponentFlag.NPCVisible
    local bHasFurniture = self:GetFurnitureActor()
    if bHasFurniture then
      local bNoFurnitureFlag = 0 == self.Flag & EnumComponentFlag.FurnitureLoaded
      if bNoFurnitureFlag then
        return self:OnFurniturePostLoad()
      end
    end
    self:OnDirty()
  end
end

function HomeNpcInfoComponent:OnInvisible()
  if 0 ~= self.Flag & EnumComponentFlag.NPCVisible then
    self.Flag = self.Flag & ~EnumComponentFlag.NPCVisible
    self:OnDirty()
  end
end

function HomeNpcInfoComponent:IsReady()
  return 0 ~= self.Flag & EnumComponentFlag.FurnitureLoaded and 0 ~= self.Flag & EnumComponentFlag.NPCVisible
end

function HomeNpcInfoComponent:OnDirty()
  Log.Debug("HomeNpcInfoComponent:OnDirty", self.NpcId, self.FurnitureId, self.Flag)
  local bNewReady = self:IsReady()
  local bOldReady = self.bReady
  if bOldReady ~= bNewReady then
    local Furniture = self:GetFurnitureActor()
    Furniture:OnNpcChanged(self:GetOwner(), bNewReady)
    self.OnReadyChangedDelegate:Invoke(self:GetOwner(), bNewReady)
  end
end

function HomeNpcInfoComponent:Destroy()
  Log.Debug("HomeNpcInfoComponent:Destroy", self.NpcId, self.FurnitureId)
  if self.Sound2DProxyTable then
    for k, proxy in pairs(self.Sound2DProxyTable) do
      proxy:Stop()
    end
    self.Sound2DProxyTable = nil
  end
end

function HomeNpcInfoComponent:EnsureSound2dProxy(EventName)
  if not self.Sound2DProxyTable then
    self.Sound2DProxyTable = {}
  end
  local Proxy = self.Sound2DProxyTable[EventName]
  if not Proxy then
    local Source = string.format("Home:%s:%s", self.NpcId, self.FurnitureId)
    Proxy = Sound2DProxy(EventName, Source)
    self.Sound2DProxyTable[EventName] = Proxy
    Proxy.OnChanged:Add(self, self.OnSoundChanged)
  end
  return Proxy
end

function HomeNpcInfoComponent:AnySoundPlaying()
  if self.Sound2DProxyTable then
    for EventName, Proxy in pairs(self.Sound2DProxyTable) do
      if Proxy:IsPlaying() then
        return Proxy
      end
    end
  end
  return nil
end

function HomeNpcInfoComponent:OnSoundChanged(Proxy)
  self.OnSoundChangedDelegate:Invoke(Proxy)
end

function HomeNpcInfoComponent:GetFurnitureData()
  return HomeIndoorSandbox.Server.WorldData:GetFurnitureById(self.FurnitureId)
end

function HomeNpcInfoComponent:GetFurnitureActor()
  local Props = self:GetFurnitureData()
  if Props then
    return Props:ResolvePropsActor()
  end
end

return HomeNpcInfoComponent
