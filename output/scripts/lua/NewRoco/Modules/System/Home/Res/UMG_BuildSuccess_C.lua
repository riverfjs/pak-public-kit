local UMG_BuildSuccess_C = _G.NRCPanelBase:Extend("UMG_BuildSuccess_C")

function UMG_BuildSuccess_C:OnConstruct()
  self.QualityBgPathTable = {
    "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_QualityBg1_png.img_QualityBg1_png'",
    "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_QualityBg2_png.img_QualityBg2_png'",
    "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_QualityBg3_png.img_QualityBg3_png'",
    "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_QualityBg4_png.img_QualityBg4_png'",
    "PaperSprite'/Game/NewRoco/Modules/System/Home/Raw/HomeFurnitureAtlas/Frames/img_QualityBg5_png.img_QualityBg5_png'"
  }
  self:OnAddEventListener()
end

function UMG_BuildSuccess_C:OnActive(FurnitureConf)
  local ItemConf = _G.DataConfigManager:GetBagItemConf(FurnitureConf.id, true)
  if ItemConf then
    self.EmptyState:SetPath(self.QualityBgPathTable[ItemConf.item_quality])
  end
  self.NRCText_51:SetText(FurnitureConf.name)
  _G.NRCAudioManager:PlaySound2DAuto(1220002061, "UMG_BuildSuccess_C:OnActive")
end

function UMG_BuildSuccess_C:OnDeactive()
end

function UMG_BuildSuccess_C:OnAddEventListener()
  self:AddButtonListener(self.btnCloseTips, self.OnReqCloseTips)
end

function UMG_BuildSuccess_C:OnReqCloseTips()
  if self.bPendingClose then
    return
  end
  self.bPendingClose = true
  self:DispatchEvent(HomeIndoorSandbox.Event.OnUserConfirmBuildFinish)
  self:OnClose()
end

function UMG_BuildSuccess_C:OnAnimationFinished(Anim)
  if Anim == self.Out then
    self:OnClose()
  elseif Anim == self.In or Anim == self.Loop then
    self:PlayAnimation(self.Loop)
  end
end

return UMG_BuildSuccess_C
