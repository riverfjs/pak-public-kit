local UMG_DamageNumberBase_C = _G.NRCUmgClass:Extend("UMG_DamageNumberBase_C")

function UMG_DamageNumberBase_C:Construct()
  self:BuildNums()
end

function UMG_DamageNumberBase_C:BuildNums()
  if self.Nums and #self.Nums > 0 then
    return
  end
  self.Nums = {
    self.Num1,
    self.Num2,
    self.Num3,
    self.Num4,
    self.Num5,
    self.Num6,
    self.Num7,
    self.Num8
  }
end

function UMG_DamageNumberBase_C:SetType(type)
  if self.DamageType ~= type then
    self.DamageType = type
    if not self.FontColor or not self.OutLineColor then
      Log.Error("UMG_DamageNumberBase_C: FontColor or OutLineColor is nil")
      return
    end
    if type < 1 or type > self.FontColor:Num() then
      Log.Error(string.format("UMG_DamageNumberBase_C: Invalid type index %d, FontColor array size is %d", type, self.FontColor:Num()))
      return
    end
    if type < 1 or type > self.OutLineColor:Num() then
      Log.Error(string.format("UMG_DamageNumberBase_C: Invalid type index %d, OutLineColor array size is %d", type, self.OutLineColor:Num()))
      return
    end
    local color = self.FontColor:Get(type)
    local outColor = self.OutLineColor:Get(type)
    for i, v in pairs(self.Nums) do
      v:SetColorAndOpacity(color)
      local font = v.Font
      font.OutlineSettings.OutlineColor = outColor
      v:SetFont(font)
    end
  end
end

function UMG_DamageNumberBase_C:MakeColor(R, G, B, A)
  return UE4.FColor(R or 0, G or 0, B or 0, A or 255):ToLinearColor()
end

function UMG_DamageNumberBase_C:Destruct()
  if not self.Nums then
    return
  end
  table.clear(self.Nums)
  NRCUmgClass.Destruct(self)
end

function UMG_DamageNumberBase_C:SetContent(Popup)
  self:BuildNums()
  self.Popup = Popup
  local Content = Popup.content
  if not Content then
    Content = ""
    Log.Error("UMG_DamageNumberBase_C Content is nil!!!")
  end
  for i = 1, 8 do
    if self.Nums[i] then
      if i <= #Content then
        local c = Content:sub(i, i)
        self.Nums[i]:SetText(c)
        self.Nums[i]:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      else
        self.Nums[i]:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
    end
  end
  if self.Popup:IsPowerful() then
    self:SetColorAndOpacity(self.PowerColor)
  else
  end
  self:SetType(Popup:GetDamageType())
end

function UMG_DamageNumberBase_C:Play()
  if self.Popup:IsPowerful() then
    if self.Popup:IsRestrainted() or self.Popup:IsRestraint() then
      self:PlayAnimation(self.Anim1)
    else
      self:PlayAnimation(self.Anim2)
    end
  end
end

function UMG_DamageNumberBase_C:SetCallBack(Caller, CallBack, PopupData)
  self.Caller = Caller
  self.CallBack = CallBack
  self.PopupData = PopupData
end

function UMG_DamageNumberBase_C:OnDestruct()
  if self.Caller and self.CallBack then
    self.CallBack(self.Caller, self.PopupData)
  end
  self.Caller = nil
  self.CallBack = nil
  self.PopupData = nil
end

return UMG_DamageNumberBase_C
