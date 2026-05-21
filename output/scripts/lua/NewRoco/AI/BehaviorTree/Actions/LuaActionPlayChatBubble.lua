local Base = require("NewRoco.AI.BehaviorTree.LuaActionBase")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local LuaActionPlayChatBubble = Base:Extend("LuaActionPlayChatBubble")

function LuaActionPlayChatBubble:OnStart(owner)
  local Message = self.Message:GetValue(owner)
  if string.IsNilOrEmpty(Message) then
    return self:Finish(true)
  end
  local npc = owner.Npc
  if npc:IsHidden() and not npc:IsHidden(NPCModuleEnum.NpcReasonFlags.HIDDEN) then
    return self:Finish(true)
  end
  local view = npc.viewObj
  if view then
    local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
    if FriendModule then
      if FriendModule:IsEmo(Message) then
        local Path = FriendModule:OnCmdGetEmoPathByEsc(Message)
        FriendModule.chatBubbleController:AddEmojiBubble(Path, view, ZoneServer:GetServerTime())
      else
        FriendModule.chatBubbleController:AddTextBubble(Message, UE4.UNRCStatics.HexToSlateColor("#ffffff"), _G.NRCBigWorldPreloader:Get("Font_Obj_FangZhengLanTing_ZhongChu"), false, view, ZoneServer:GetServerTime())
      end
    end
  end
  return self:Finish(true)
end

return LuaActionPlayChatBubble
