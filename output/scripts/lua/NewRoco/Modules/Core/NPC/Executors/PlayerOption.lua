local Class = _G.MakeSimpleClass
local MainUIModuleCmd = require("NewRoco.Modules.System.MainUI.MainUIModuleCmd")
local PlayerActionFactory = require("NewRoco.Modules.Core.NPC.Actions.PlayerActionFactory")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local PlayerOption = Class("PlayerOption")

function PlayerOption:Ctor(Player, OptionID, custom_params)
  self.owner = Player
  self.OptionID = OptionID
  self.bIsPlayerOption = true
  self.custom_params = custom_params
  self.config = _G.DataConfigManager:GetNpcOptionConf(OptionID)
  if self.config then
    self.CurrentAction = PlayerActionFactory:Get(self, self.config.action)
  end
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
end

function PlayerOption:AddToInteractUI()
  if not self:ShouldShowOnUI() then
    return false
  end
  if self.CurrentAction then
    return _G.NRCModuleManager:DoCmd(MainUIModuleCmd.AddNPCInteract, self)
  end
  return false
end

function PlayerOption:RemoveFromInteractUI()
  if self.CurrentAction then
    _G.NRCModuleManager:DoCmd(MainUIModuleCmd.RemoveNPCInteract, self)
  end
end

function PlayerOption:Destroy()
  if self.CurrentAction then
    self.CurrentAction:Destroy()
    self.CurrentAction = nil
  end
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self:RemoveFromInteractUI()
end

function PlayerOption:UpdateInfo(Info)
  if self.CurrentAction then
    self.CurrentAction:UpdateInfo(Info)
  end
end

function PlayerOption:ShouldShowOnUI()
  if not self.owner then
    return false
  end
  if 0 == self.owner.serverData.attrs.hp then
    return false
  end
  if self.CurrentAction and self.CurrentAction.ShouldShowOnUI and not self.CurrentAction:ShouldShowOnUI() then
    return false
  end
  return true
end

function PlayerOption:OnOptionAction()
  if not self.owner then
    Log.Error("PlayerOption\231\154\132Owner\229\183\178\231\187\143\228\184\141\229\173\152\229\156\168\228\186\134\227\128\130\229\129\156\230\173\162\228\186\164\228\186\146")
    return
  end
  if _G.NRCPanelManager:GetLoadingPanelCount() > 0 then
    Log.Error("\230\156\137\230\173\163\229\156\168\229\138\160\232\189\189\228\184\173\231\154\132\233\157\162\230\157\191\239\188\140\230\137\147\230\150\173ActorId\228\184\186...", self.owner.serverData.base.actor_id)
    return false
  end
  if 0 == self.owner.serverData.attrs.hp then
    Log.Error("PlayerOption\231\154\132Owner\229\183\178\231\187\143\232\181\176\228\186\134\227\128\130\229\129\156\230\173\162\228\186\164\228\186\146")
    return
  end
  if self.owner.isDestroy then
    Log.Error("PlayerOption\231\154\132Owner\229\135\134\229\164\135\232\166\129\232\162\171\229\136\160\233\153\164\228\186\134\239\188\140\228\184\141\229\133\129\232\174\184\229\188\128\229\167\139\230\150\176\231\154\132\228\186\164\228\186\146")
    return
  end
  if self.CurrentAction and self.CurrentAction:OnNpcAction() then
    self.CurrentAction:Execute()
  end
end

function PlayerOption:OnStatusChanged(Status, Value, OpCode)
  if Status == Enum.WorldPlayerStatusType.WPST_DEATH and OpCode == Enum.WPST_OpCode.WPST_OPCODE_ADD then
    self:RemoveFromInteractUI()
  end
end

function PlayerOption:IsInteractBanState(PlayerState)
  if PlayerState == Enum.LocationInteractionBanType.STA_BEGIN then
    return false
  end
  local NpcTag
  if not NpcTag then
    local LocationTag = self.config and self.config.LocationTag
    if LocationTag and 0 ~= LocationTag then
      NpcTag = LocationTag
    end
  end
  local InteractBanConf = _G.DataConfigManager:GetLocationInteractBan(NpcTag or Enum.LocationTag.LC_LAND)
  local locaion_interact_ban_list = InteractBanConf and InteractBanConf.locaion_interact_ban_list
  if locaion_interact_ban_list then
    local BanList = locaion_interact_ban_list[PlayerState + 1]
    if BanList then
      return BanList.location_interact_ban
    end
  end
  return false
end

return PlayerOption
