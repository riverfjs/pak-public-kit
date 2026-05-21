local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local MainPanelMgr = NRCClass("MainPanelMgr")
local MainPanelMapping = {
  [MainUIModuleEnum.MainUIPanelType.LobbyMain] = {
    PanelName = "LobbyMain",
    PanelPath = "UMG_LobbyMain",
    ModuleName = "MainUIModule"
  },
  [MainUIModuleEnum.MainUIPanelType.LobbyMainLocal] = {
    PanelName = "LobbyMainLocal",
    PanelPath = "Ability/UMG_LocalUI",
    ModuleName = "MainUIModule"
  },
  [MainUIModuleEnum.MainUIPanelType.RogueLobbyMain] = {
    PanelName = "HerbologyBadgeMain",
    PanelPath = "UMG_HerbologyBadge_Main",
    ModuleName = "BattleRogueModule"
  }
}

function MainPanelMgr:Ctor()
  self.CurUIType = MainUIModuleEnum.MainUIPanelType.None
  _G.NRCEventCenter:RegisterEvent(self, self, MainUIModuleEvent.MainUIModeChange, self.SwitchMainPanel)
end

local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")

function MainPanelMgr:SwitchMainPanel(NewMainUIType, bNotTemp, bReBindIA)
  if self.CurUIType ~= NewMainUIType then
    a.task(function()
      if self.CurUIType ~= MainUIModuleEnum.MainUIPanelType.None then
        local MainUIModule = _G.NRCModuleManager:GetModule("MainUIModule")
        local CurPanelModule = self:GetCurMainUIModule()
        local CurPanelName = MainPanelMapping[self.CurUIType].PanelName
        local CurMainPanel = CurPanelModule:GetPanel(CurPanelName)
        if bNotTemp then
          CurPanelModule:ClosePanel(CurPanelName)
        else
          if bReBindIA and CurMainPanel and CurMainPanel.UnBindInputAction then
            CurMainPanel:UnBindInputAction()
          end
          CurPanelModule:DisablePanel(CurPanelName)
        end
        MainUIModule:CloseInteractMain()
      end
      self.CurUIType = NewMainUIType
      au.DelayFrames(1)
      local NewPanelName = MainPanelMapping[self.CurUIType].PanelName
      local NewPanelModule = self:GetCurMainUIModule()
      local isOpening = NewPanelModule:HasPanel(NewPanelName)
      if isOpening then
        local NewMainPanel = NewPanelModule:GetPanel(NewPanelName)
        if NewMainPanel then
          NewPanelModule:EnablePanel(NewPanelName)
          if bReBindIA and NewMainPanel.BindInputAction then
            NewMainPanel:BindInputAction()
          end
        end
      else
        NewPanelModule:OpenPanel(NewPanelName)
      end
      Log.Debug("[MainPanelMgr] SwitchMainPanel", NewPanelName, NewPanelModule.moduleName)
    end)()
  end
end

function MainPanelMgr:GetCurMainUI()
  if self.CurUIType == MainUIModuleEnum.MainUIPanelType.None then
    return nil
  else
    return self:GetCurMainUIModule():GetPanel(MainPanelMapping[self.CurUIType].PanelName)
  end
end

function MainPanelMgr:GetCurMainUIType()
  return self.CurUIType
end

function MainPanelMgr:GetCurPanelName()
  return MainPanelMapping[self.CurUIType] and MainPanelMapping[self.CurUIType].PanelName or nil
end

function MainPanelMgr:HasAnyMainUIOpened()
  if self.CurUIType == MainUIModuleEnum.MainUIPanelType.None then
    return false
  else
    return self:GetCurMainUIModule():HasPanel(MainPanelMapping[self.CurUIType].PanelName)
  end
end

function MainPanelMgr:HasAnyMainUIShowing()
  if self.CurUIType == MainUIModuleEnum.MainUIPanelType.None then
    return false
  else
    local CurPanelName = MainPanelMapping[self.CurUIType].PanelName
    local CurPanelModule = self:GetCurMainUIModule()
    if CurPanelModule:HasPanel(CurPanelName) then
      return CurPanelModule:GetPanel(CurPanelName):IsVisible()
    end
  end
  return false
end

function MainPanelMgr:GetCurMainUIModule()
  return _G.NRCModuleManager:GetModule(MainPanelMapping[self.CurUIType].ModuleName)
end

return MainPanelMgr
