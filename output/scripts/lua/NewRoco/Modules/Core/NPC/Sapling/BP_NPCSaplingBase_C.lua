require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local MathExtend = require("Utils.MathExtend")
local BP_NPCSaplingBase_C = Base:Extend("BP_NPCSaplingBase_C")

function BP_NPCSaplingBase_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.GrowUpSpeed = 0.5
  self.CachedFruits = {}
  self.RandomLocations = {}
  self.UsedLocation = {}
  self.GrowUpHandler = nil
end

function BP_NPCSaplingBase_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  self:AddGeometryCache(self.SaplingCacheRes, self.GeometryCache)
  if self.bIsSeeding then
    self.RandomLocations = MathExtend.GetRandomSequence_TArray(self.FruitsLocations, self.FruitsLocations:Length())
  end
  Log.Error("\233\166\150\229\133\136\239\188\140\233\156\128\232\166\129\229\133\136\231\161\174\232\174\164\228\184\139\228\184\186\229\149\165\229\174\131\228\188\154\232\162\171\229\164\141\230\180\187\239\188\140\232\191\153\229\183\178\231\187\143\230\152\175\229\155\155\229\185\180\229\137\141\231\154\132\228\184\156\232\165\191\228\186\134\239\188\140\229\164\141\230\180\187\232\191\152\230\152\175\230\143\144\233\156\128\230\177\130\229\144\167")
end

function BP_NPCSaplingBase_C:SetSaplingStatus()
  if self.bIsSeeding then
    self.GeometryCache:SetStartTimeOffset(0.3)
  else
    self.GeometryCache:SetStartTimeOffset(2.0)
  end
end

function BP_NPCSaplingBase_C:GrowUp()
  local PlayTime = self.GeometryCache:GetDuration()
  self.GeometryCache:SetPlaybackSpeed(self.GrowUpSpeed)
  self.GeometryCache:Play()
  if self.GrowUpHandler then
    _G.DelayManager:CancelDelayById(self.GrowUpHandler)
    self.GrowUpHandler = nil
  end
  self.GrowUpHandler = _G.DelayManager:DelaySeconds(PlayTime / self.GrowUpSpeed, self.OnFinishGrow, self)
end

function BP_NPCSaplingBase_C:OnFinishGrow()
  if self.GrowUpHandler then
    _G.DelayManager:CancelDelayById(self.GrowUpHandler)
    self.GrowUpHandler = nil
  end
  self.bIsSeeding = false
  self:LoadAllFruits()
end

function BP_NPCSaplingBase_C:CacheCreatedNPC(fruit)
  local Index = self:GetNextFruitTransform()
  local RelativeLocation = self.RandomLocations[Index]
  local WorldLocation = UE4.UKismetMathLibrary.TransformLocation(self:Abs_GetTransform(), RelativeLocation)
  fruit:ReportPosition()
  self.CachedFruits[WorldLocation] = fruit
end

function BP_NPCSaplingBase_C:SetCreatedNPC(fruit, location)
  self.sceneCharacter:SetNotDestroyFlag(false)
  if not fruit.viewObj then
    fruit:CreateView(false)
  end
  local fruitObj = fruit.viewObj
  if location then
    fruitObj:Mount(location)
    fruit:ReportPosition()
  end
  fruitObj.needTick = false
  fruitObj:OnFrameLoad(fruit:GetDistanceRatio())
end

function BP_NPCSaplingBase_C:LoadAllFruits()
  for location, fruit in pairs(self.CachedFruits) do
    self:SetCreatedNPC(fruit, location)
  end
end

function BP_NPCSaplingBase_C:GetNextFruitTransform()
  local Index = 1
  while self.UsedLocation[Index] do
    Index = Index + 1
  end
  self.UsedLocation[Index] = true
  return Index
end

function BP_NPCSaplingBase_C:ReceiveEndPlay(EndPlayReason)
  if self.GrowUpHandler then
    _G.DelayManager:CancelDelayById(self.GrowUpHandler)
    self.GrowUpHandler = nil
  end
  Base.ReceiveEndPlay(self, EndPlayReason)
end

return BP_NPCSaplingBase_C
