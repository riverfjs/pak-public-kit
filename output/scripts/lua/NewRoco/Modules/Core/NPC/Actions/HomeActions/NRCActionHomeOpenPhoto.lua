local NPCActionBase = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local Base = NPCActionBase
local HomeNpcInfoComponent = require("NewRoco.Modules.System.Home.Components.HomeNpcInfoComponent")
local M = Base:Extend("NRCActionHomeOpenPhoto")

function M:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function M:Execute()
  self.SkipSubmit = true
  Base.Execute(self)
  local Npc = self.Owner.owner
  local Comp = Npc:GetComponent(HomeNpcInfoComponent)
  local FurnitureData = Comp:GetFurnitureData()
  if FurnitureData and FurnitureData.Conf then
    local parameter = FurnitureData.Conf.parameter
    Log.Debug("NRCActionHomeOpenPhoto:Execute", parameter, FurnitureData.Conf.name)
    if parameter then
      local DisplayData = HomeIndoorSandbox.Enum.MakeFurniturePhotoViewData()
      DisplayData.TexturePath = parameter
      DisplayData.FurnitureName = FurnitureData.Conf.name
      HomeIndoorSandbox.Module:OpenFurniturePhotoView(DisplayData)
    end
  end
  self.needSendReq = false
  self.SkipSubmit = false
  self:Submit()
  self:Finish()
end

return M
