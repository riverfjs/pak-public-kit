local LinkedList = require("Utils.LinkedList")
local IS_SHIPPING = _G.RocoEnv.IS_SHIPPING
local UpdateManager = {}
UpdateManager.Timestamp = 0
UpdateManager.CurGCTickIdx = 0
UpdateManager.List = LinkedList("UpdateManager")
UpdateManager.MemleakSet = {}
UpdateManager.FrameCnt = 0
WeakTable(UpdateManager.MemleakSet)

function UpdateManager:Register(target, silence)
  if not silence then
    if _G.RocoEnv.IS_EDITOR then
      Log.Trace("UpdateManager Register:", target.name, target)
    else
      Log.Debug("UpdateManager Register:", target.name, target)
    end
  end
  if target.OnTick == nil then
    return
  end
  if target == self then
    Log.Error("cannot register self")
    return
  end
  self.List:Insert(target)
end

function UpdateManager:UnRegister(target)
  Log.Debug("UpdateManager UnRegister:", target.name, target)
  self.List:Remove(target)
end

function UpdateManager:CompareValue(Value, Target)
  return Value == Target
end

function UpdateManager:OnTick(deltaTime, realTickTime)
  self.Timestamp = self.Timestamp + realTickTime
  self.FrameCnt = self.FrameCnt + 1
  if IS_SHIPPING then
    local CallingNode = self.List.CallingNode
    local StuckOnDelayManager = false
    if CallingNode and CallingNode.Value == _G.DelayManager then
      StuckOnDelayManager = true
      Log.Debug("DelayManager Stuck!!!!!!!!!")
    end
    self.List:Recovery()
    if StuckOnDelayManager and CallingNode then
      Log.Debug("Set DelayManger back!!!!!!!!!")
      CallingNode.Removed = false
    end
    self.List:Iterate(self, self.IterateTargets, realTickTime)
  else
    self.List:Iterate(self, self.SafeIterateTargets, realTickTime)
  end
end

function UpdateManager:SafeIterateTargets(Target, RealTickTime)
  if not Target then
    return
  end
  local Result, Message = xpcall(self.IterateTargets, debug.traceback, self, Target, RealTickTime)
  if Result then
    return
  end
  Log.Error(Message)
  if Target ~= _G.DelayManager and Target ~= _G.NRCPanelManager then
    self:UnRegister(Target)
  end
  local ClassName = Target.className
  if string.IsNilOrEmpty(ClassName) then
    ClassName = "\230\156\170\231\159\165\232\132\154\230\156\172"
  end
  if not _G.RocoEnv.IS_EDITOR then
    _G.NRCSDKManager:CrashSightReportExceptionWithReason(string.format("Tick\229\188\130\229\184\184%s", ClassName), "Lua,OnTick,Exception", Message)
  end
  local Errors = string.split(Message, "\n")
  local NewLines = {}
  for i = 1, 5 do
    if Errors[i] then
      table.insert(NewLines, Errors[i])
    else
      break
    end
  end
  local Shorten = table.concat(NewLines, "\n")
  local Ctx = _G.DialogContext()
  Ctx:SetTitle("\233\157\158Shipping\231\137\136\230\156\172\228\184\147\229\177\158\228\184\165\233\135\141\233\148\153\232\175\175\230\143\144\231\164\186")
  Ctx:SetContent(string.format("%s\231\154\132OnTick\231\130\184\228\186\134\239\188\129\232\191\153\229\190\136\228\184\165\233\135\141\239\188\129\230\184\184\230\136\143\229\141\179\229\176\134\229\129\156\230\173\162\239\188\129\232\175\183\230\156\172\230\136\170\229\155\190\229\143\145\231\187\153\229\174\162\230\136\183\231\171\175\229\188\128\229\143\145\239\188\140\232\176\162\232\176\162\239\188\129\n%s", ClassName, Shorten))
  Ctx:SetMode(_G.DialogContext.Mode.OK)
  Ctx:SetButtonText("\229\129\156\230\173\162\230\184\184\230\136\143", "\229\129\156\230\173\162\230\184\184\230\136\143")
  Ctx:SetCallback(nil, function()
    UE.UNRCStatics.QuitGame()
  end)
  _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UpdateManager:IterateTargets(Target, RealTickTime)
  if not Target then
    return
  end
  if Target.Object then
    if UE.UObject.IsValid(Target) then
      local OnTick = Target.OnTick
      if OnTick then
        OnTick(Target, RealTickTime)
      end
    elseif not IS_SHIPPING and not UpdateManager.MemleakSet[Target] then
      Log.Error("UpdateManager OnTick:item\229\135\186\231\142\176\230\179\132\230\188\143:", type(Target), Target, Target.Object)
      UpdateManager.MemleakSet[Target] = 1
    end
  elseif Target.OnTick then
    Target:OnTick(RealTickTime)
  end
end

return UpdateManager
