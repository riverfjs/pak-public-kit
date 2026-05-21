local GCloudEndPoints = {
  Maple = {
    TestPre = "pre-dir.924524759-2-2.gcloudsvcs.com",
    TestFormal = "dir.924524759-2-1.gcloudsvcs.com",
    ReleasePre = "pre-dir.924524759-2-2.gcloudsvcs.com",
    ReleaseFormal = "dir.924524759-2-1.gcloudsvcs.com"
  },
  Dolphin = {
    TestPre = "pre-download.924524759-1-2.gcloudsvcs.com",
    ReleaseFormal = "download.924524759-1-1.gcloudsvcs.com"
  },
  Puffer = {
    TestPre = "pre-puffer.924524759-11-2.gcloudsvcs.com",
    ReleaseFormal = "puffer.924524759-11-1.gcloudsvcs.com"
  }
}

function GCloudEndPoints:GetMapleUrl()
  local AppMain = _G.App
  local Override = AppMain.launchParams.dolphin_url_key
  if Override then
    return GCloudEndPoints.Maple[Override] or GCloudEndPoints.Maple.ReleaseFormal
  elseif AppMain:GetFormalPipeline() then
    return GCloudEndPoints.Maple.ReleaseFormal
  else
    return GCloudEndPoints.Maple.TestPre
  end
end

function GCloudEndPoints:GetDolphinUrl()
  local AppMain = _G.App
  local OverrideUrl = AppMain.launchParams.dolphin_url_key
  if OverrideUrl then
    return GCloudEndPoints.Dolphin[OverrideUrl] or GCloudEndPoints.Dolphin.ReleaseFormal
  elseif AppMain:GetFormalPipeline() then
    return GCloudEndPoints.Dolphin.ReleaseFormal
  else
    return GCloudEndPoints.Dolphin.TestPre
  end
end

function GCloudEndPoints:GetPufferUrl()
  local AppMain = _G.App
  local OverrideUrl = AppMain.launchParams.dolphin_url_key
  if OverrideUrl then
    return GCloudEndPoints.Puffer[OverrideUrl] or GCloudEndPoints.Puffer.ReleaseFormal
  elseif AppMain:GetFormalPipeline() then
    return GCloudEndPoints.Puffer.ReleaseFormal
  else
    return GCloudEndPoints.Puffer.TestPre
  end
end

function GCloudEndPoints:GetDolphinChannel()
  local AppMain = _G.App
  return AppMain:GetDolphinChannel()
end

return GCloudEndPoints
