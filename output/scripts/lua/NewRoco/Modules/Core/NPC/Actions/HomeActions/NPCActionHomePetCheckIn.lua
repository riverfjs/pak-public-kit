local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local NPCActionHomePetCheckIn = Base:Extend("NPCActionHomePetCheckIn")

function NPCActionHomePetCheckIn:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
  _G.NRCEventCenter:RegisterEvent("NPCActionHomePetCheckIn", self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
end

function NPCActionHomePetCheckIn:Execute(PlayerID, NeedSendReq)
  if not (self.Owner and self.OwnerNpc) or not self.OwnerNpc.FurnitureID then
    self:Finish(false)
    return
  end
  local petInfo = _G.DataModelMgr.PlayerDataModel:HasPet()
  if not petInfo then
    Log.PrintScreenMsgRed("no pet with player, stop showing petCheckIn")
    self:Finish(false)
    return
  end
  _G.NRCModuleManager:DoCmd(HomeModuleCmd.OnCmdOpenPanel, "HomePetChoosing", true, self.OwnerNpc.FurnitureID)
  self.isPanelOpening = true
  local PropsData = HomeIndoorSandbox.HomePropsServ:GetPropsDataById(self.OwnerNpc.FurnitureID)
  HomeIndoorSandbox.HomePropsServ:RequestPropsCamera(PropsData, true)
  _G.NRCEventCenter:RegisterEvent("NPCActionHomePetCheckIn", self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
  Base.Execute(self, PlayerID, NeedSendReq)
end

function NPCActionHomePetCheckIn:OnClosePanel(PanelData)
  local Name = PanelData.panelName
  if "HomePetChoosing" == Name then
    HomeIndoorSandbox.HomePropsServ:ReleasePropsCamera()
    _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCPanelEvent.ClosePanel, self.OnClosePanel)
    if self.OwnerNpc then
      local attachmentInfo = self.OwnerNpc.serverData and self.OwnerNpc.serverData.attach_item_info
      if attachmentInfo and attachmentInfo.attach_item_id then
        local homePetActorInfo = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, attachmentInfo.attach_item_id)
        if homePetActorInfo then
          self:Finish(true, homePetActorInfo)
        end
      end
    end
    return self:Finish(false)
  end
end

function NPCActionHomePetCheckIn:Finish(success, data, param)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnectFinish)
  self.isPanelOpening = false
  Base.Finish(self, success, data, param)
end

function NPCActionHomePetCheckIn:OnReconnectFinish()
  if self.isPanelOpening then
    self:Finish(true)
  end
end

return NPCActionHomePetCheckIn
