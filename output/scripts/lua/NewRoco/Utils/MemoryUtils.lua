local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
local MemoryUtils = {}
local bShowing = false

function MemoryUtils.ShowLowMemoryWarning(availableMemoryMB)
  if bShowing then
    return
  end
  bShowing = true
  local content = string.format("\229\189\147\229\137\141\232\174\190\229\164\135\229\143\175\231\148\168\229\134\133\229\173\152\228\184\141\232\182\179\239\188\140\229\143\175\232\131\189\229\175\188\232\135\180\230\184\184\230\136\143\229\180\169\230\186\131\227\128\130\229\187\186\232\174\174\229\133\179\233\151\173\233\131\168\229\136\134\229\144\142\229\143\176\229\186\148\231\148\168\230\136\150\233\135\141\229\144\175\231\148\181\232\132\145\239\188\140\228\187\165\232\142\183\229\190\151\230\155\180\228\189\179\231\154\132\230\184\184\230\136\143\228\189\147\233\170\140\227\128\130")
  local ctx = DialogContext()
  ctx:SetTitle("\229\134\133\229\173\152\228\184\141\232\182\179"):SetContent(content):SetMode(DialogContext.Mode.OK):SetButtonText("\230\136\145\231\159\165\233\129\147\228\186\134", nil):SetCloseOnOK(true):SetCallback(nil, function(_, result)
    bShowing = false
  end)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, ctx)
end

return MemoryUtils
