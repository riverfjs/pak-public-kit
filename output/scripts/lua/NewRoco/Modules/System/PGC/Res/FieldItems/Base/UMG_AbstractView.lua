local UMG_AbstractView = NRCUmgClass:Extend("UMG_AbstractView")

function UMG_AbstractView:Active()
  self:OnActiveView()
end

function UMG_AbstractView:Deactive()
  self:OnDeactiveView()
end

function UMG_AbstractView:RefreshData(Data)
  if Data and type(Data) == "table" and not self:OnNormalizeData(Data) then
    Data = nil
  end
  self.Data = Data
  if self.Data then
    self:OnFlushData()
  else
    self:OnCleanData()
  end
end

function UMG_AbstractView:OnActiveView()
end

function UMG_AbstractView:OnDeactiveView()
end

function UMG_AbstractView:OnNormalizeData(Data)
  return true
end

function UMG_AbstractView:OnFlushData()
end

function UMG_AbstractView:OnCleanData()
end

return UMG_AbstractView
