local TakePhotosUtils = require("NewRoco.Modules.System.TakePhotos.TakePhotosUtils")
local Super = require("NewRoco.Modules.System.TakePhotos.Helper.ActionPosePlayer")
local EmojiPlayer = Super:Extend("EmojiPlayer")

function EmojiPlayer:PlayAnim(Conf, bMirror)
  if Conf == self.Conf and bMirror == self.bMirror then
    return
  end
  self:InternalPlayerByConf(Conf, bMirror)
end

function EmojiPlayer:ParseAnimationPath(Conf)
  local ResourcePath
  if 1 == self.Player.gender then
    ResourcePath = Conf.male_emoji_path
  else
    ResourcePath = Conf.female_emoji_path
  end
  return ResourcePath or ""
end

function EmojiPlayer:InternalPlayerAnimation(Animation)
  TakePhotosUtils.EnablePlayerEmoji(self.Player, self.Conf, Animation)
  if UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj.ForbidMorph = true
  end
end

function EmojiPlayer:InternalStopPlayAnimation(Animation)
  TakePhotosUtils.DisablePlayerEmoji(self.Player, self.Conf, Animation)
  if UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj.ForbidMorph = false
  end
end

return EmojiPlayer
