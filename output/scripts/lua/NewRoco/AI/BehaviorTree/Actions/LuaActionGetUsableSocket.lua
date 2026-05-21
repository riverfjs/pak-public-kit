local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local LuaActionGetUsableSocket = Base:Extend("LuaActionGetUsableSocket")
local DummyOneIndices = {1}

function LuaActionGetUsableSocket:OnStart(owner)
  local object = self.Target:GetValue(owner)
  if object and object.config and object.config.model_conf then
    local socketConf = _G.DataConfigManager:GetModelSocketConf(object.config.model_conf, false)
    if socketConf and #socketConf.socket_info > 0 then
      local socket_count = #socketConf.socket_info
      if object.__ai_socketUsage == nil then
        object.__ai_socketUsage = 0
        if 1 == socket_count then
          object.__ai_socketUsageIndices = DummyOneIndices
        else
          local indices = table.new(socket_count, 0)
          for i = 1, socket_count do
            indices[i] = i
          end
          for i = socket_count, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
          end
          object.__ai_socketUsageIndices = indices
        end
      end
      local currentUsage = object.__ai_socketUsage
      local currentIndices = object.__ai_socketUsageIndices
      if socket_count > currentUsage then
        local currentUsageIndex = currentIndices[currentUsage + 1]
        local socket_info = socketConf.socket_info[currentUsageIndex]
        local SocketXfm = UE.FTransform()
        local Translation = SocketXfm.Translation
        Translation.X = (socket_info.location[1] or 0) / 1000.0
        Translation.Y = (socket_info.location[2] or 0) / 1000.0
        Translation.Z = (socket_info.location[3] or 0) / 1000.0
        SocketXfm.Rotation = UE.FRotator((socket_info.rotation[1] or 0) / 10.0, (socket_info.rotation[2] or 0) / 10.0, (socket_info.rotation[3] or 0) / 10.0):ToQuat()
        local Scale = SocketXfm.Scale3D
        Scale.X = (socket_info.scale[1] or 1000) / 1000.0
        Scale.Y = (socket_info.scale[2] or 1000) / 1000.0
        Scale.Z = (socket_info.scale[3] or 1000) / 1000.0
        local ObjXfm = object:GetActorTransform()
        local FinalXfm = SocketXfm * ObjXfm
        self.OutLocation:SetValue(owner, FinalXfm.Translation)
        if GlobalConfig.DebugLuaBTree then
          UE.UKismetSystemLibrary.Abs_DrawDebugSphere(object.viewObj, FinalXfm.Translation, 100, 12, UE.FColor(255, 0, 0), 1000.0)
          UE.UKismetSystemLibrary.Abs_DrawDebugLine(object.viewObj, ObjXfm.Translation, FinalXfm.Translation, UE.FColor(255, 0, 0), 1000.0)
        end
        object.__ai_socketUsage = currentUsage + 1
        return self:Finish(true)
      end
    end
  end
  return self:Finish(false)
end

return LuaActionGetUsableSocket
