local Sound2DProxy = Class("Sound2DProxy")
local Delegate = require("Utils.Delegate")

function Sound2DProxy:Ctor(EventName, Source)
  Log.Debug("Sound2DProxy:Create", EventName, Source)
  self.EventName = EventName
  self.Source = Source
  self.bPlaying = false
  self.OnChanged = Delegate()
end

function Sound2DProxy:Toggle()
  Log.Debug("Sound2DProxy:Toggle", self.EventName, self.Source, self.bPlaying)
  if self.bPlaying then
    self.bPlaying = false
    assert(self.SoundSession)
    assert(-1 ~= self.SoundSession, self.SoundSession)
    _G.NRCAudioManager:ReleaseSession(self.SoundSession, true, self.Source)
    Log.Debug("Sound2DProxy:Toggle Stop", self.EventName, self.Source, self.SoundSession)
    self.SoundSession = -1
  else
    self.SoundSession = _G.NRCAudioManager:PlaySound2DByEventNameAuto(self.EventName, self.Source)
    if self.SoundSession and -1 ~= self.SoundSession then
      self.bPlaying = true
      _G.NRCAudioManager:AddSessionFinishCallback(self.SoundSession, self, self.OnFinish)
      self.OnChanged:Invoke(self)
    end
    Log.Debug("Sound2DProxy:Toggle Play", self.EventName, self.Source, self.SoundSession)
  end
end

function Sound2DProxy:OnFinish()
  Log.Debug("Sound2DProxy:OnFinish", self.EventName, self.Source, self.SoundSession)
  self.bPlaying = false
  self.SoundSession = -1
  self.OnChanged:Invoke(self)
end

function Sound2DProxy:IsPlaying()
  return self.bPlaying
end

function Sound2DProxy:Stop()
  if self:IsPlaying() then
    self:Toggle()
  end
end

function Sound2DProxy:Play()
  if not self:IsPlaying() then
    self:Toggle()
  end
end

return Sound2DProxy
