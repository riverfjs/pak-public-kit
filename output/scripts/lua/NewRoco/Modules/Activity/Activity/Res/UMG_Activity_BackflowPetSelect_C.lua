local UMG_Activity_BackflowPetSelect_C = _G.NRCPanelBase:Extend("UMG_Activity_BackflowPetSelect_C")
local ActivityModuleEvent = require("NewRoco.Modules.System.Activity.ActivityModuleEvent")
local ActivityEnum = require("NewRoco.Modules.System.Activity.ActivityEnum")

function UMG_Activity_BackflowPetSelect_C:OnConstruct()
  UE4Helper.SetEnableWorldRendering(true, nil, "UMG_Activity_BackflowPetSelect")
  self:SetChildViews(self.PetSelectItem1, self.PetSelectItem2, self.PetSelectItem3)
  self:AddButtonListener(self.GoToInvestigate.btnLevelUp, self.SelectPet)
  _G.NRCEventCenter:RegisterEvent("UMG_Activity_BackflowPetSelect_C", self, ActivityModuleEvent.OnBackflowPetSelected, self.OnPetSelected)
end

function UMG_Activity_BackflowPetSelect_C:OnActive(pet_ids, activity_id)
  self.activity_id = activity_id
  self.PetSelectItem1:SetInfo(pet_ids[1])
  self.PetSelectItem2:SetInfo(pet_ids[2])
  self.PetSelectItem3:SetInfo(pet_ids[3])
  self.Desc:SetText(_G.LuaText.recall_pet_choose_tips)
end

function UMG_Activity_BackflowPetSelect_C:SelectPet()
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_BackflowPetSelect_C:SelectPet")
  if self.selected_egg_id then
    local req = _G.ProtoMessage:newZoneActivityCommonRewardsReq()
    req.activity_id = self.activity_id
    req.params = {
      self.selected_egg_id
    }
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_ACTIVITY_COMMON_REWARDS_REQ, req, self, self.GetEggReward)
  end
end

function UMG_Activity_BackflowPetSelect_C:GetEggReward(rsp)
  if 0 == rsp.ret_info.ret_code then
    local popupInitData = {}
    local popupData = _G.ProtoMessage:newGoodsItem()
    popupData.id = self.selected_egg_id
    popupData.num = 1
    popupData.type = _G.Enum.GoodsType.GT_BAGITEM
    table.insert(popupInitData, popupData)
    local commonPopUpData = _G.NRCCommonPopUpData()
    commonPopUpData.Call = self
    commonPopUpData.ClosePanelHandler = self.Finish
    commonPopUpData.HideBtn = true
    _G.NRCModuleManager:DoCmd(_G.CommonPopUpModuleCmd.OpenNPCShopItemRewardsPanel, popupInitData, nil, nil, nil, nil, nil, nil, commonPopUpData)
  elseif rsp.ret_info.ret_code == _G.ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_ACTIVITY_REWARD_HAS_BEEN_RECEIVED then
    self:Finish()
  end
end

function UMG_Activity_BackflowPetSelect_C:Finish()
  self:StopAllAnimations()
  self:OnClose()
end

function UMG_Activity_BackflowPetSelect_C:OnPetSelected(_, petEgg_id)
  self.selected_egg_id = petEgg_id
end

function UMG_Activity_BackflowPetSelect_C:OnDeactive()
  self:RemoveButtonListener(self.GoToInvestigate.btnLevelUp)
  _G.NRCEventCenter:UnRegisterEvent(self, ActivityModuleEvent.OnBackflowPetSelected, self.OnPetSelected)
  UE4Helper.SetEnableWorldRendering(nil, nil, "UMG_Activity_BackflowPetSelect")
end

function UMG_Activity_BackflowPetSelect_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    _G.NRCModuleManager:DoCmd(_G.ActivityModuleCmd.OpenMainPanel, nil, nil, ActivityEnum.MainPanelOpenSource.RecallActivity)
    self:DoClose()
  elseif Anim == self.In then
    self:PlayAnimation(self.Loop, nil, 0)
  end
end

return UMG_Activity_BackflowPetSelect_C
