local UMG_Activity_ElfParadiseSelect_C = _G.NRCPanelBase:Extend("UMG_Activity_ElfParadiseSelect_C")

function UMG_Activity_ElfParadiseSelect_C:OnActive(para)
  self.WishChoiceCountInfo = para or {}
  local PetTripActivityInst = _G.NRCModuleManager:DoCmd(ActivityModuleCmd.GetActivityInstByType, Enum.ActivityType.ATP_PET_TRIP)
  if PetTripActivityInst and #PetTripActivityInst > 0 then
    self.activityInst = PetTripActivityInst[1]
  end
  if self.activityInst then
    self.activityData = self.activityInst:GetActivityData()
    self:UpdateUI()
    if self.activityData.wish_choice and 0 ~= self.activityData.wish_choice then
      self:OnSelectItem(self.activityData.wish_choice)
    end
  else
    self:DoClose()
    return
  end
  self:PlayAnimation(self.In)
  self:OnAddEventListener()
end

function UMG_Activity_ElfParadiseSelect_C:OnSelectItem(index)
  for i = 1, 3 do
    if self["SelectItem" .. i] then
      if index == i then
        self["SelectItem" .. i]:SetSelect()
      else
        self["SelectItem" .. i]:CancelSelect()
      end
    end
    self.selectWish = index
  end
end

function UMG_Activity_ElfParadiseSelect_C:UpdateUI()
  self.Desc:SetText(LuaText.pet_trip_9)
  self.Tips:SetText(LuaText.pet_trip_16)
  local PetTripAwardConf = self.activityInst:GetPetTripAwardConf()
  local rewardGroup = PetTripAwardConf and PetTripAwardConf.condition_group or {}
  self.RewardList = {}
  for i, v in ipairs(rewardGroup) do
    local reward = {}
    reward.WishChoiceCountInfo = self:GetWishChoiceCountInfoByWish(i)
    reward.data = v
    reward.wish = i
    if reward.WishChoiceCountInfo then
      table.insert(self.RewardList, reward)
    end
  end
  table.sort(self.RewardList, function(a, b)
    if a.WishChoiceCountInfo.count ~= b.WishChoiceCountInfo.count then
      return a.WishChoiceCountInfo.count > b.WishChoiceCountInfo.count
    else
      return a.data.goods_level < b.data.goods_level
    end
  end)
  for i, v in ipairs(rewardGroup) do
    local reward = {}
    reward.WishChoiceCountInfo = self:GetWishChoiceCountInfoByWish(i)
    reward.Parent = self
    reward.data = v
    reward.wish = i
    if self["SelectItem" .. i] and v then
      self["SelectItem" .. i]:UpdateUI(reward)
    end
  end
end

function UMG_Activity_ElfParadiseSelect_C:GetWishPeopleCountText(wish)
  for i, v in ipairs(self.RewardList) do
    if v.wish == wish then
      if v.WishChoiceCountInfo.count >= 10000 then
        if 1 == i then
          return true, LuaText.pet_trip_56
        elseif 2 == i then
          return true, LuaText.pet_trip_57
        elseif 3 == i then
          return true, LuaText.pet_trip_58
        end
      else
        return false, v.WishChoiceCountInfo.count or 0
      end
    end
  end
end

function UMG_Activity_ElfParadiseSelect_C:GetWishChoiceCountInfoByWish(index)
  if not self.WishChoiceCountInfo then
    return {}
  end
  for _, v in ipairs(self.WishChoiceCountInfo) do
    if v.wish_choice == index then
      return v
    end
  end
end

function UMG_Activity_ElfParadiseSelect_C:OnDeactive()
end

function UMG_Activity_ElfParadiseSelect_C:OnBtnClose()
  if self:IsAnimationPlaying(self.Out) or self:IsAnimationPlaying(self.In) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(40006009, "UMG_Activity_ElfParadiseSelect_C:OnBtnClose")
  self:PlayAnimation(self.Out)
end

function UMG_Activity_ElfParadiseSelect_C:OnAnimationFinished(anim)
  if anim == self.Out then
    self:DoClose()
  elseif anim == self.In then
    self:PlayAnimation(self.Loop)
  elseif anim == self.Loop then
    self:PlayAnimation(self.Loop)
  end
end

function UMG_Activity_ElfParadiseSelect_C:BtnGoToInvestigate()
  if self:IsAnimationPlaying(self.Out) or self:IsAnimationPlaying(self.In) then
    return
  end
  _G.NRCAudioManager:PlaySound2DAuto(41401001, "UMG_Activity_ElfParadiseSelect_C:BtnGoToInvestigate")
  if self.selectWish ~= self.activityData.wish_choice then
    self.activityInst:SendSelectWishReq(self.selectWish)
  end
  self:PlayAnimation(self.Out)
end

function UMG_Activity_ElfParadiseSelect_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose, self.OnBtnClose)
  self:AddButtonListener(self.GoToInvestigate.btnLevelUp, self.BtnGoToInvestigate)
end

return UMG_Activity_ElfParadiseSelect_C
