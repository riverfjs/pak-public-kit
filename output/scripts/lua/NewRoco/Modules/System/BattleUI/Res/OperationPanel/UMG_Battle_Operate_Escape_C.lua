local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local UMG_Battle_Operate_Escape_C = NRCUmgClass:Extend("")

function UMG_Battle_Operate_Escape_C:Construct()
  self.BtnOperate.OnClicked:Add(self, self.OnClicked_BtnOperate)
end

function UMG_Battle_Operate_Escape_C:OnClicked_BtnOperate()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")()
  DialogContext:SetTitle(LuaText.umg_battle_operate_escape_1):SetContent(LuaText.umg_battle_operate_escape_2):SetButtonText(LuaText.umg_battle_operate_escape_3, LuaText.umg_battle_operate_escape_4):SetCallback(self, self.OnDialogCallback)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, DialogContext)
end

function UMG_Battle_Operate_Escape_C:OnDialogCallback(result)
  if result then
    _G.BattleNetManager:SendEscapeReq(BattleEnum.RunAwayType.Abandon)
  end
end

return UMG_Battle_Operate_Escape_C
