local MiniGameHideReason = {
  GameActor = "Np\230\152\175GameActor",
  NoServerData = "\230\151\160ServerData",
  IsAThrownPet = "\230\152\175\231\142\169\229\174\182\230\136\150\229\174\160\231\137\169",
  NotHideInMinigame = "can_hide_in_minigame\228\184\186false",
  NotContentID = "\230\156\170\232\174\190\231\189\174ContentIDs",
  InContentIDs = "\229\177\158\228\186\142ContentIDs",
  NoRegion = "\230\178\161\230\156\137\231\169\186\230\176\148\229\162\153",
  RegionNotContainPoint = "\228\184\141\229\156\168\231\169\186\230\176\148\229\162\153\232\140\131\229\155\180\229\134\133",
  RegionContainPoint = "\229\164\132\228\186\142\231\169\186\230\176\148\229\162\153\232\140\131\229\155\180\229\134\133"
}
local ShowHideBase = require("NewRoco.Modules.Core.NPC.ShowHide.ShowHideBase")
local Base = ShowHideBase
_G.DebugMiniGameShowHide = false
local MiniGameShowHide = Base:Extend("MiniGameShowHide")

function MiniGameShowHide:Ctor()
  Base.Ctor(self)
  self.MiniGameID = -1
  self.MiniGameConf = nil
  self.RuleConf = nil
  self.GroupConf = nil
  self.GameActor = nil
  self.GameActorServerID = nil
  self.Region = nil
  self.ContentIDs = {}
  self.PlayerUIN = -1
end

function MiniGameShowHide:GetReason()
  return 9
end

function MiniGameShowHide:StartHide()
  local MiniGameModule = _G.NRCModuleManager:GetModule("MiniGameModule")
  local MiniGameID = MiniGameModule.ConfigId
  if not MiniGameID then
    return false
  end
  local MiniGameConf = _G.DataConfigManager:GetMinigameConf(MiniGameID)
  if not MiniGameConf then
    return false
  end
  if not MiniGameConf.npc_hide then
    return false
  end
  local RuleConf = _G.DataConfigManager:GetMinigameRuleConf(MiniGameConf.rule)
  if not RuleConf then
    return false
  end
  local GroupConf = _G.DataConfigManager:GetNpcRefreshGroupConf(RuleConf.group_id)
  if not GroupConf then
    return false
  end
  self.MiniGameID = MiniGameID
  self.MiniGameConf = MiniGameConf
  self.GameActor = MiniGameModule.BigBen
  self.GameActorServerID = MiniGameModule.SceneNPCID
  self.RuleConf = RuleConf
  self.PlayerUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  for _, Content in ipairs(GroupConf.content_id) do
    table.insert(self.ContentIDs, Content)
  end
  local AreaConf = _G.DataConfigManager:GetAreaConf(self.MiniGameConf.gameplay_area)
  if AreaConf then
    self.Region = NewObject(UE.URegion, _G.UE4Helper.GetCurrentWorld())
    self.Region_Ref = UnLua.Ref(self.Region)
    local Verts = UE4.TArray(UE4.FVector2D)
    for _, point in ipairs(AreaConf.pos) do
      if point.position_xyz and #point.position_xyz >= 2 then
        Verts:Add(UE4.FVector2D(point.position_xyz[1], point.position_xyz[2]))
      end
    end
    self.Region:SetMainRegionVerts(Verts)
  else
    self.Region = nil
  end
  return true
end

function MiniGameShowHide:CheckShouldHide(npc)
  if not npc.serverData then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.NoServerData)
    return false
  end
  local BaseData = npc.serverData.npc_base
  local ContentID = BaseData and BaseData.npc_content_cfg_id
  if ContentID and table.contains(self.ContentIDs, ContentID) then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.InContentIDs)
    return false
  end
  if not self.Region or not UE4.UObject.IsValid(self.Region) then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.NoRegion)
    return false
  end
  if not self.Region:ContainPoint(npc:GetActorLocation()) then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.RegionNotContainPoint)
    Log.Debug("\228\184\141\233\154\144\232\151\143", npc:DebugNPCNameAndID())
    return false
  end
  if npc == self.GameActor then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.GameActor)
    return false
  end
  if npc:GetServerId() == self.GameActorServerID then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.GameActor)
    return false
  end
  if npc:IsAThrownPet() then
    local bHide = npc:GetWorldOwnerID() ~= self.PlayerUIN
    self:DrawDebugHideReason(npc, bHide, MiniGameHideReason.IsAThrownPet)
    if bHide then
      _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.AddHideNpcViews, npc.viewObj)
    end
    return bHide
  end
  if npc.config and 1 ~= npc.config.can_hide_in_minigame then
    self:DrawDebugHideReason(npc, false, MiniGameHideReason.NotHideInMinigame)
    return false
  end
  Log.Debug("\233\154\144\232\151\143", npc:DebugNPCNameAndID())
  if npc.AIComponent then
    Log.PrintScreenMsg("\229\129\156\230\142\137AI %s", npc.config.name)
    npc.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.MINIGAME_HIDE)
  end
  self:DrawDebugHideReason(npc, true, MiniGameHideReason.RegionContainPoint)
  _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.AddHideNpcViews, npc.viewObj)
  return true
end

function MiniGameShowHide:EndHide()
  Base.EndHide(self)
end

function MiniGameShowHide:StartShow()
  self.MiniGameID = -1
  self.MiniGameConf = nil
  self.RuleConf = nil
  self.GroupConf = nil
  self.GameActor = nil
  self.GameActorServerID = nil
  self.Region = nil
  self.Region_Ref = nil
  self.PlayerUIN = -1
  table.clear(self.ContentIDs)
  return true
end

function MiniGameShowHide:CheckShouldShow(npc)
  if npc.AIComponent then
    npc.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.MINIGAME_HIDE)
  end
  _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.RemoveHideNpcViews, npc.viewObj)
  return true
end

function MiniGameShowHide:EndShow()
  Base.EndShow(self)
end

function MiniGameShowHide:ShouldPauseTick()
  return false
end

function MiniGameShowHide:DrawDebugHideReason(npc, bHide, reason)
  if not _G.DebugMiniGameShowHide then
    return
  end
  local message = string.format("%d-%s:%s", npc.config.id, npc.config.name, reason)
  local color = UE4.FLinearColor(0, 1, 0, 1)
  if bHide then
    color = UE4.FLinearColor(1, 0, 0, 1)
  end
  local duration = self.MiniGameConf.time_limit + 10.0
  UE4.UKismetSystemLibrary.Abs_DrawDebugString(UE4Helper.GetCurrentWorld(), npc:GetActorLocation(), message, nil, color, duration)
end

return MiniGameShowHide
