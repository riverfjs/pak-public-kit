local Base = require("NewRoco.Modules.Core.NPC.Actions.NPCActionBase")
local NPCActionHomePetGetBack = Base:Extend("NPCActionHomePetGetBack")
local HomeModuleEvent = require("NewRoco.Modules.System.Home.HomeModuleEvent")

function NPCActionHomePetGetBack:Ctor(Owner, Config, Info)
  Base.Ctor(self, Owner, Config, Info)
end

function NPCActionHomePetGetBack:Execute(PlayerID, NeedSendReq)
  Base.Execute(self, PlayerID, NeedSendReq)
  if not self.OwnerNpc then
    self:Finish(false)
    return
  end
  local attachmentInfo = self.OwnerNpc.serverData and self.OwnerNpc.serverData.attach_item_info
  if not attachmentInfo or attachmentInfo.attach_item_type ~= ProtoEnum.NpcAttachItemType.NAIT_HOME_PET_NEST then
    Log.Error("no valid attach_item_info when recycle pet on nest")
    self:Finish(false)
    return
  end
  local furnitureId = attachmentInfo.attach_item_id
  if not furnitureId then
    Log.Error("nil attach_item_id when recycle pet on nest ")
    self:Finish(false)
    return
  end
  local homePetActorInfo = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, furnitureId)
  if not homePetActorInfo or not homePetActorInfo.base.actor_id then
    Log.Error("no valid interact nest when spawn pet on nest")
    self:Finish(false)
    return
  end
  local pairPetNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, homePetActorInfo.base.actor_id)
  if pairPetNpc then
    if pairPetNpc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_HOLD_EGG) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_egg_pick_first)
      self:Finish(false)
      return
    end
  else
    self:Finish(false)
    return
  end
  local recycleTips = LuaText.home_pet_take_back_text_1
  if pairPetNpc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_IN_PRODUCT) then
    recycleTips = LuaText.home_pet_take_back_text_4
  end
  local context = DialogContext()
  local pairPetData
  if homePetActorInfo.home_pet and homePetActorInfo.home_pet.home_pet_info then
    pairPetData = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(homePetActorInfo.home_pet.home_pet_info.pet_gid)
  end
  context:SetTitle(LuaText.onlinemodule_1):SetContent(string.format(recycleTips, pairPetData and pairPetData.name or "")):SetMode(DialogContext.Mode.OK_CANCEL):SetToppingIconType(0):SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel):SetCallback(self, self.OnChooseRecyclePet)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, context)
end

function NPCActionHomePetGetBack:OnChooseRecyclePet(bRecycle)
  if bRecycle then
    local req = ProtoMessage:newZoneHomePetUnplaceReq()
    local furnitureId = self.OwnerNpc.serverData.attach_item_info.attach_item_id
    local homePetActorInfo = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.GetPairNestAndPet, furnitureId)
    req.pet_unplace_info_list = {
      {
        furniture_guid = furnitureId,
        npc_obj_id = homePetActorInfo.base.actor_id
      }
    }
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_HOME_PET_UNPLACE_REQ, req, self, self.OnPetRecycleRsp, false, true)
  else
    self:Finish(false)
  end
end

function NPCActionHomePetGetBack:OnPetRecycleRsp(rsp)
  Log.Dump(rsp, 3, "OnReCyclePet")
  local home_pet_info = not rsp.home_pet_info and rsp.home_pet_info_list and rsp.home_pet_info_list[1]
  if rsp.ret_info and 0 == rsp.ret_info.ret_code then
    local petName = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(home_pet_info.pet_gid).name
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(LuaText.home_pet_take_back_text_2, petName))
    local furnitureId = home_pet_info.furniture_guid
    local emptyNpcInfo = ProtoMessage:newActorInfo_Npc()
    NRCModuleManager:DoCmd(HomeModuleCmd.UpdatePairNestAndPet, furnitureId, emptyNpcInfo)
    _G.DataModelMgr.PlayerDataModel:UpdatePetInHomeIndoor(home_pet_info.pet_gid, false)
    self:Finish(true)
  elseif rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_HOME_PET_STATUS_ERROR and home_pet_info and home_pet_info.pet_gid then
    local npcInfo = _G.NRCModuleManager:DoCmd(HomeModuleCmd.GetHomePetInfo, home_pet_info.pet_gid)
    if npcInfo and npcInfo.base.actor_id then
      local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npcInfo.base.actor_id)
      if not npc then
        return
      end
      if npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CAN_STEAL) or npc:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_CANT_STEAL) then
        _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.home_pet_take_back_text_3)
      end
    end
    self:Finish(false)
  else
    self:Finish(false)
  end
end

return NPCActionHomePetGetBack
