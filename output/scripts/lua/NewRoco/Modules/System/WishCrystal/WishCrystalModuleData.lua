local WishCrystalModuleData = _G.NRCData:Extend("WishCrystalModuleData")

function WishCrystalModuleData:Ctor()
  NRCData.Ctor(self)
  self.ExchangeNum = nil
  self.OldMoneyCount = nil
  self.PlayerStarInfo = nil
  self.IncrementStarlight = nil
  self.StarlightInfoList = {}
end

function WishCrystalModuleData:UpdateStarlightInfo(InStarlightInfo, StarlightIncrement, InIsShare)
  self.PlayerStarInfo = InStarlightInfo
  self.IncrementStarlight = StarlightIncrement
  if InStarlightInfo and StarlightIncrement then
    local starlightInfo = {}
    starlightInfo.PlayerStarInfo = InStarlightInfo
    starlightInfo.IncrementStarlight = StarlightIncrement
    starlightInfo.MarkUsed = false
    starlightInfo.Unlock = true
    starlightInfo.IsShare = InIsShare
    table.insert(self.StarlightInfoList, starlightInfo)
  end
end

function WishCrystalModuleData:ResetStarlightInfo(InStarlightInfo)
  self.PlayerStarInfo = InStarlightInfo
  self.IncrementStarlight = nil
  self.StarlightInfoList = {}
  self.ExchangeNum = nil
end

function WishCrystalModuleData:RemoveUsedStarlightInfo()
  local UnusedList = {}
  for _, info in pairs(self.StarlightInfoList or {}) do
    if not info.MarkUsed then
      table.insert(UnusedList, info)
    end
  end
  self.StarlightInfoList = UnusedList
end

function WishCrystalModuleData:UpdateWishCrystalNum(NewNum)
  if NewNum and self.OldMoneyCount and NewNum ~= self.OldMoneyCount then
    self.ExchangeNum = NewNum - self.OldMoneyCount
  else
    self.ExchangeNum = nil
  end
end

function WishCrystalModuleData:GetMoneyCount()
  return _G.DataModelMgr.PlayerDataModel:GetVItemCount(_G.Enum.VisualItem.VI_DIAMOND) or 0
end

function WishCrystalModuleData:GetStarlightInfo()
  local starlightInfo = {}
  for _, info in pairs(self.StarlightInfoList or {}) do
    if info.MarkUsed and 0 ~= info.IncrementStarlight then
      starlightInfo = info.PlayerStarInfo
    end
  end
  return starlightInfo
end

return WishCrystalModuleData
