local UMG_PVPShare_C = _G.NRCPanelBase:Extend("UMG_PVPShare_C")

function UMG_PVPShare_C:OnActive(data)
  self.data = data
  local ShareDataSnapshot = data.extraData
  self.tableIndex = ShareDataSnapshot.TableIndex
  local curSeasonData = ShareDataSnapshot.CurSeasonData
  self.TableDatas = ShareDataSnapshot.TableDatas
  local startNum = ShareDataSnapshot.rank_star
  self.PhotoSub:InitData(curSeasonData, self.tableIndex, self.TableDatas, startNum)
end

function UMG_PVPShare_C:OnDeactive()
end

function UMG_PVPShare_C:OnAddEventListener()
end

function UMG_PVPShare_C:ShowPlayerInfoPanel(isShow)
  if isShow then
    self.PhotoSub.CanvasPanel_7:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.PhotoSub.CanvasPanel_7:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_PVPShare_C:HideSelectBoxByShare()
  if self.PhotoSub.Popup_Downward and self.PhotoSub.Popup_Downward:GetVisibility() == UE4.ESlateVisibility.SelfHitTestInvisible then
    self.PhotoSub.Popup_Downward:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

return UMG_PVPShare_C
