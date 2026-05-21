function _G.WeakTable(table, mode)
  return setmetatable(table or {}, {
    __mode = mode or "kv"
  })
end

_G.LockedVector = {}
WeakTable(_G.LockedVector)
_G.FVectorNewIndex = nil

function _G.LockFVector(vector)
  if not _G.FVectorNewIndex then
    _G.FVectorNewIndex = getmetatable(vector).__newindex
  end
  LockedVector[vector] = 1
  local metaTable = getmetatable(vector)
  
  function metaTable.__newindex(t, k, v)
    if _G.LockedVector[t] then
      Log.Error("fvector is locked!!!")
    else
      _G.FVectorNewIndex(t, k, v)
    end
  end
end

local function GetFunctorArgs(args, ...)
  local extraArgs = table.pack(...)
  local allArgs = _G.table.new(args.n + extraArgs.n)
  for i = 1, args.n do
    table.insert(allArgs, args[i])
  end
  for i = 1, extraArgs.n do
    table.insert(allArgs, extraArgs[i])
  end
  return allArgs
end

function _G.MakeWeakFunctor(_this, _func, ...)
  if nil == _func then
    Log.Error("function can not be nil!")
    return
  end
  local functor = {
    memberFunc = _this and _G.MakeWeakTable({this = _this, func = _func}, "v") or nil,
    lambdaFunc = not _this and _func or nil,
    params = table.pack(...)
  }
  setmetatable(functor, {
    IsValid = function(self)
      local _memberFunc = self.memberFunc
      local _lambdaFunc = self.lambdaFunc
      return _memberFunc and _memberFunc.this and _memberFunc.func or _lambdaFunc
    end,
    __eq = function(t1, t2)
      local _memberFuncT1 = t1.memberFunc
      local _memberFuncT2 = t2.memberFunc
      if _memberFuncT1 and _memberFuncT2 then
        return _memberFuncT1.this == _memberFuncT2.this and _memberFuncT1.func == _memberFuncT2.func
      end
      return t1.lambdaFunc == t2.lambdaFunc
    end,
    __call = function(self, ...)
      local _memberFunc = self.memberFunc
      local _lambdaFunc = self.lambdaFunc
      local _extraArgs = self.params
      if _memberFunc then
        if _memberFunc.this and _memberFunc.func then
          if _extraArgs and _extraArgs.n and _extraArgs.n > 0 then
            local allArgs = GetFunctorArgs(_extraArgs, ...)
            return _memberFunc.func(_memberFunc.this, table.unpack(allArgs))
          else
            return _memberFunc.func(_memberFunc.this, ...)
          end
        end
      elseif _lambdaFunc then
        if _extraArgs and _extraArgs.n and _extraArgs.n > 0 then
          local allArgs = GetFunctorArgs(_extraArgs, ...)
          return _lambdaFunc(table.unpack(allArgs))
        else
          return _lambdaFunc(...)
        end
      end
    end
  })
  return functor
end

function _G.ObjectRefBoxing(rawObj)
  return rawObj and UE4.UObject.IsValid(rawObj) and {
    rawObj,
    UnLua.Ref(rawObj)
  }
end

function _G.ObjectRefUnBoxing(boxingObj)
  return boxingObj and boxingObj[1]
end

function LuaLogger(callFrom, ...)
  local from = string.format("[%s]", callFrom)
  Log.DebugWithLevel(5, from, ...)
end

function OpenMessageBox(title, content, btnOk, btnCancel, mode, callback, debugInfo)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  Log.Debug("[ZoneServer] OpenDialog", title, content, btnOk, btnCancel, mode, callback, debugInfo)
  local Ctx = DialogContext()
  Ctx:SetTitle(title):SetContent(content):SetMode(mode):SetCallback(self, callback):SetCloseOnCancel(true):SetButtonText(btnOk, btnCancel):SetDebugInfo(debugInfo)
  Log.Debug("[ZoneServer] Ctx", Ctx.content)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function OpenMessageBoxWthCaller(title, content, btnOk, btnCancel, mode, callback, Caller, debugInfo, bClickAnywhereClose, bCancelAnyWay)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  Log.Debug("[ZoneServer] OpenDialog", title, content, btnOk, btnCancel, mode, callback, debugInfo)
  local Ctx = DialogContext()
  Ctx:SetTitle(title):SetContent(content):SetMode(mode):SetCallback(Caller, callback):SetCloseOnCancel(true):SetButtonText(btnOk, btnCancel):SetDebugInfo(debugInfo):SetClickAnywhereClose(bClickAnywhereClose):SetCancelAnyway(bCancelAnyWay)
  Log.Debug("[ZoneServer] Ctx", Ctx.content)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function TryGetLogFunctionName(...)
end

local fullName

function _G.GetFileModifyTime(strFileName)
  if RocoEnv and RocoEnv.LUA_ROOT_PATH then
    fullName = RocoEnv.LUA_ROOT_PATH .. strFileName
  end
  return UEGetFileDateTime and UEGetFileDateTime(fullName) or -1
end

function _G.ReleaseForceAllChild(widget)
  Log.Debug("ReleaseForceAllChild:", widget)
  for k, v in pairs(widget) do
    if type(v) == "table" then
      if v.UnbindSelf then
        v:UnbindSelf()
      end
      if v.RemoveFromParent then
        v:RemoveFromParent()
      end
      if v.ReleaseForce then
        v:ReleaseForce()
      end
    end
  end
  widget:ReleaseForce()
end

function _G.ForceReload(path)
  HotFix.ReloadFile(path)
  return require(path)
end

local NRCUtils = {}

function NRCUtils.CheckUserWidgetExist(userWidget)
  if userWidget then
    return true
  else
    return false
  end
end

function NRCUtils.FormatBlueprintAssetPath(InAssetPath)
  if not InAssetPath then
    return nil
  end
  if string.EndsWith(InAssetPath, "_C") or string.EndsWith(InAssetPath, "_C'") then
    return InAssetPath
  end
  if not InAssetPath:find("%.") then
    local index = string.find(InAssetPath, "/[^/]*$")
    if index then
      local last = InAssetPath:len()
      if string.EndsWith(InAssetPath, "'") then
        last = last - 1
      end
      local bpName = string.sub(InAssetPath, index + 1, last)
      InAssetPath = string.format("%s.%s_C", InAssetPath, bpName)
    end
  elseif string.EndsWith(InAssetPath, "'") then
    InAssetPath = string.sub(InAssetPath, 1, InAssetPath:len() - 1)
    InAssetPath = InAssetPath .. "_C'"
  else
    InAssetPath = InAssetPath .. "_C"
  end
  return InAssetPath
end

function NRCUtils.FormatBlueprintAssetPathAvatar(InAssetPath)
  if not InAssetPath:find("%.") then
    local index = string.find(InAssetPath, "/[^/]*$")
    local last = InAssetPath:len()
    if string.EndsWith(InAssetPath, "'") then
      last = last - 1
    end
    local bpName = string.sub(InAssetPath, index + 1, last)
    InAssetPath = string.format("%s.%s_C", InAssetPath, bpName)
  elseif string.EndsWith(InAssetPath, "'") then
    InAssetPath = string.sub(InAssetPath, 1, InAssetPath:len() - 1)
    InAssetPath = InAssetPath .. "_C'"
  else
    InAssetPath = InAssetPath .. "_C"
  end
  return InAssetPath
end

function NRCUtils.FormatResPackageNameToFullPath(InAssetPath)
  if not InAssetPath:find("%.") then
    local index = string.find(InAssetPath, "/[^/]*$")
    if not index then
      return
    end
    local last = InAssetPath:len()
    if string.EndsWith(InAssetPath, "'") or string.EndsWith(InAssetPath, "\"") then
      last = last - 1
    end
    local SuffixName = string.sub(InAssetPath, index + 1, last)
    InAssetPath = string.format("%s.%s", InAssetPath, SuffixName)
  end
  return InAssetPath
end

function NRCUtils.CheckedSyncLoadObject(path)
  UE4.UNRCStatics.PauseSyncCheck()
  local obj = LoadObject(path)
  UE4.UNRCStatics.ResumeSyncCheck()
  return obj
end

function NRCUtils:OpenDialog(title, content, btnOk, btnCancle, mode, callback, debugInfo)
  Log.Debug("[NRCUtils] OpenDialog", title, content, btnOk, btnCancle, mode, callback, debugInfo)
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local TipsModuleCmd = require("NewRoco.Modules.System.TipsModule.TipsModuleCmd")
  local Ctx = DialogContext()
  Ctx:SetTitle(title):SetContent(content):SetMode(mode):SetCallback(self, callback):SetCloseOnCancel(true):SetButtonText(btnOk, btnCancle):SetDebugInfo(debugInfo)
  Log.Debug("[ZoneServer] Ctx", Ctx.content)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function NRCUtils.OnLuaError(ErrorString, ErrorReason, ErrorTrace)
  if not RocoEnv.IS_SHIPPING and DebugModuleCmd and NRCModuleManager then
    NRCModuleManager:DoCmd(DebugModuleCmd.OpenLuaErrorPanel, ErrorString, ErrorString .. "\n" .. ErrorReason .. "\n" .. ErrorTrace)
  end
end

function NRCUtils:FormatConfIconPath(ConfIconPath, UIIconPath)
  return ConfIconPath
end

function NRCUtils:GetIconName(ConfIconPath)
  if not ConfIconPath then
    return
  end
  local index = string.find(ConfIconPath, "/[^/]*$")
  if not index then
    return
  end
  local last = ConfIconPath:len()
  if string.EndsWith(ConfIconPath, "'") then
    last = last - 1
  end
  return string.sub(ConfIconPath, index + 1, last)
end

function NRCUtils.LuaFatalError(errorMsg, reason, stackTrace, enableRetry)
  if not errorMsg then
    return
  end
  reason = reason or "LuaFatalError"
  stackTrace = stackTrace or ""
  Log.Error(errorMsg, "\n", stackTrace)
  if not _G.RocoEnv.IS_EDITOR then
    _G.NRCSDKManager:CrashSightReportExceptionWithReason(errorMsg, reason, stackTrace)
  end
  if not _G.RocoEnv.IS_SHIPPING then
    local callStackLines = {}
    local callStacks = string.split(stackTrace, "\n")
    for i = 1, 5 do
      if callStacks[i] then
        table.insert(callStackLines, callStacks[i])
      else
        break
      end
    end
    local Ctx = _G.DialogContext()
    Ctx:SetTitle("\233\157\158Shipping\231\137\136\230\156\172\228\184\147\229\177\158\228\184\165\233\135\141\233\148\153\232\175\175\230\143\144\231\164\186")
    Ctx:SetContent(string.format("[%s] \229\143\145\231\148\159\228\184\165\233\135\141\233\151\174\233\162\152\239\188\140\230\184\184\230\136\143\229\141\179\229\176\134\229\129\156\230\173\162\239\188\129\232\175\183\230\156\172\230\136\170\229\155\190\229\143\145\231\187\153\229\174\162\230\136\183\231\171\175\229\188\128\229\143\145\239\188\140\232\176\162\232\176\162\239\188\129\n%s", errorMsg, table.concat(callStackLines, "\n")))
    if enableRetry then
      Ctx:SetMode(_G.DialogContext.Mode.OK_CANCEL)
      Ctx:SetButtonText("\229\129\156\230\173\162\230\184\184\230\136\143", "\229\191\189\231\149\165")
      Ctx:SetCloseOnOK(true)
      Ctx:SetCallbackOkOnly(nil, function()
        UE.UNRCStatics.QuitGame()
      end)
    else
      Ctx:SetMode(_G.DialogContext.Mode.OK)
      Ctx:SetButtonText("\229\129\156\230\173\162\230\184\184\230\136\143", "\229\129\156\230\173\162\230\184\184\230\136\143")
      Ctx:SetCloseOnOK(true)
      Ctx:SetCallback(nil, function()
        UE.UNRCStatics.QuitGame()
      end)
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Ctx)
  end
end

return NRCUtils
