local UMG_RollNumber_C = _G.NRCPanelBase:Extend("UMG_RollNumber_C")
local DigitTotal = 6
local MaxLimit = 10000
local MaxStr = "10000+"

function UMG_RollNumber_C:OnActive()
  self.animFinishedCallback = nil
  self.isPlay = false
  self.needTick = false
  self.lastDigitRollEndTime = 0
end

function UMG_RollNumber_C:OnDeactive()
  self:ChangePlayState(false)
end

function UMG_RollNumber_C:OnAddEventListener()
end

function UMG_RollNumber_C:OnTick(DeltaTime)
  self:TryPlay(DeltaTime)
  if self.lastDigitRollEndTime and self.lastDigitRollEndTime > 0 then
    self.lastDigitRollEndTime = self.lastDigitRollEndTime - DeltaTime
    if self.lastDigitRollEndTime <= 0 then
      self.lastDigitRollEndTime = 0
      self:ChangePlayState(false)
    end
  end
end

function UMG_RollNumber_C:PlayRollNumberAnimForPVPRank(Form, To)
  To = To or 0
  if To <= 0 then
    To = 10001
  end
  self:PlayRollNumberAnim(Form, To)
end

function UMG_RollNumber_C:PlayRollNumberAnimWithCallback(Form, To, Callback)
  self:PlayRollNumberAnim(Form, To)
  self.animFinishedCallback = Callback
end

function UMG_RollNumber_C:PlayRollNumberAnim(Form, To, Time)
  self.curValue = Form
  self.targetValue = To
  self.animTime = Time or 0.75
  self.lastTime = 0
  self.ToShowMaxStr = false
  if Form > MaxLimit and To > MaxLimit then
    self:ShowFirstStage(MaxStr)
  else
    local firstValue = self.curValue
    if Form > MaxLimit then
      firstValue = MaxStr
      self.curValue = MaxLimit
    elseif To > MaxLimit then
      self.ToShowMaxStr = true
      self.targetValue = MaxLimit
    end
    self:ShowFirstStage(firstValue)
    self:DelaySeconds(1, function()
      if not self or not UE4.UObject.IsValid(self) then
        return
      end
      self.needTick = true
    end)
  end
  self:ChangePlayState(true)
end

function UMG_RollNumber_C:GetDigitList(Value)
  local digitList = {}
  if type(Value) == "number" then
    Value = math.floor(Value)
    while Value > 0 do
      local d = Value % 10
      Value = math.floor(Value / 10)
      table.insert(digitList, d)
    end
  elseif type(Value) == "string" then
    local len = string.len(Value)
    for i = len, 1, -1 do
      local char = string.sub(Value, i, i)
      table.insert(digitList, char)
    end
  end
  if #digitList > DigitTotal then
    Log.Error("\230\149\176\229\173\151\232\191\135\229\164\167\239\188\140\232\182\133\229\135\186", DigitTotal, "\228\189\141\230\149\176\239\188\140 Value=", Value)
  end
  for index = #digitList + 1, DigitTotal do
    digitList[index] = 0
  end
  if 0 == digitList[DigitTotal] then
    digitList[DigitTotal] = ""
  end
  return digitList
end

function UMG_RollNumber_C:ShowFirstStage(Value)
  local digitList = self:GetDigitList(Value)
  for index = 1, #digitList do
    if self.DigitListWidget[index] then
      self.DigitListWidget[index]:SetFirstNumber(digitList[index])
    end
  end
end

function UMG_RollNumber_C:GetShowValue(ratio)
  if self.targetValue > self.curValue then
    return math.ceil(_G.LuaMathUtils.LerpWithAlpha(self.curValue, self.targetValue, ratio))
  else
    return math.floor(_G.LuaMathUtils.LerpWithAlpha(self.curValue, self.targetValue, ratio))
  end
end

function UMG_RollNumber_C:TryPlay(DeltaTime)
  if not self.needTick then
    return
  end
  if self.lastTime and self.lastTime + DeltaTime <= self.animTime then
    self.lastTime = self.lastTime + DeltaTime
    local ratio = 1 - (self.animTime - self.lastTime) / self.animTime
    local showValue = self:GetShowValue(ratio)
    self:InnerPlay(showValue)
  else
    local len = #self.DigitListWidget
    for i = 1, len do
      self.DigitListWidget[len - i + 1]:StopAllAnimations()
    end
    if self.ToShowMaxStr then
      self:InnerPlay(MaxStr)
    else
      local showValue = self:GetShowValue(1)
      self:InnerPlay(showValue)
    end
    self.needTick = false
    self.lastDigitRollEndTime = self.Digit1:GetRollAnimTotalTime()
  end
end

function UMG_RollNumber_C:InnerPlay(Value)
  local digitList = self:GetDigitList(Value)
  for index = 1, #digitList do
    self.DigitListWidget[index]:Play(digitList[index])
  end
end

function UMG_RollNumber_C:OnLogin()
end

function UMG_RollNumber_C:OnConstruct()
  self.DigitListWidget = {
    self.Digit1,
    self.Digit2,
    self.Digit3,
    self.Digit4,
    self.Digit5,
    self.Digit6
  }
  local speed = 1
  local len = #self.DigitListWidget
  for i = 1, len do
    self.DigitListWidget[len - i + 1]:InitSpeed(speed)
    speed = speed * 1.5
  end
end

function UMG_RollNumber_C:OnDestruct()
  self.DigitListWidget = nil
  self.curValue = nil
  self.targetValue = nil
  self.animTime = nil
  self.lastTime = nil
  self.ToShowMaxStr = nil
end

function UMG_RollNumber_C:ChangePlayState(bPlaying)
  if self.isPlay ~= bPlaying then
    local old = self.isPlay
    if old then
      self:OnPlayFinished()
    end
    self.isPlay = bPlaying
  end
end

function UMG_RollNumber_C:OnPlayFinished()
  if self.animFinishedCallback then
    self.animFinishedCallback()
    self.animFinishedCallback = nil
  end
end

function UMG_RollNumber_C:OnAnimationFinished(anim)
end

return UMG_RollNumber_C
