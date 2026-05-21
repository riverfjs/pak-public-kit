local UMG_PVP_DanGrading_C = _G.NRCPanelBase:Extend("UMG_PVP_DanGrading_C")
local PVPRankedMatchModuleUtils = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleUtils")
local BattleUIModuleCmd = require("NewRoco.Modules.System.BattleUI.BattleUIModuleCmd")
local PVPRankedMatchModuleCmd = require("NewRoco.Modules.System.PVPQualifier.PVPRankedMatchModuleCmd")
local ChangeStarState = {
  reduceOneStar = 0,
  AddOneStar = 1,
  AddTwoStar = 2
}

function UMG_PVP_DanGrading_C:OnActive(pvpRankSettleInfo)
  if not self:CheckSettleData(pvpRankSettleInfo) then
    self:DelaySeconds(0.1, function()
      if not self or not UE.UObject.IsValid(self) then
        return
      end
      self:OnBtnClose()
    end)
    return
  end
  self:OnAddEventListener()
  self.TargetShowStar = PVPRankedMatchModuleUtils.CorrectionRankStar(pvpRankSettleInfo.new_pvp_rank_star)
  self.CurShowStar = PVPRankedMatchModuleUtils.CorrectionRankStar(pvpRankSettleInfo.old_pvp_rank_star)
  self.TargetOrder = pvpRankSettleInfo.new_pvp_rank_order
  self.CurShowOrder = pvpRankSettleInfo.old_pvp_rank_order
  self.TargetMasterScore = pvpRankSettleInfo.new_pvp_rank_master_score
  self.CurMasterScore = pvpRankSettleInfo.old_pvp_rank_master_score
  self.CurChangeStarState = self:CalcChangeStar(pvpRankSettleInfo.old_pvp_rank_star, pvpRankSettleInfo.new_pvp_rank_star)
  self.win_streak_addtional_rank_star = pvpRankSettleInfo.win_streak_addtional_rank_star
  self.random_pet_addtional_rank_star = pvpRankSettleInfo.random_pet_addtional_rank_star
  self:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.Advantage:SetVisibility(UE4.ESlateVisibility.Visible)
  self.CanvasPanel_Plus:SetVisibility(UE4.ESlateVisibility.Visible)
  self.callbackChain = nil
  self.callbackChainEnable = false
  self:StartLoadSpineAsset()
end

function UMG_PVP_DanGrading_C:OnDeactive()
  self.callbackChain = nil
  self.callbackChainEnable = false
  self:OnRemoveEventListener()
end

function UMG_PVP_DanGrading_C:OnAddEventListener()
  self:AddButtonListener(self.BtnClose, self.OnBtnClose)
  self.SpineFlag.AnimationStart:Add(self, self.OnSpineAnimationStart)
end

function UMG_PVP_DanGrading_C:OnRemoveEventListener()
  self:RemoveButtonListener(self.BtnClose, self.OnBtnClose)
  self.SpineFlag.AnimationStart:Clear()
end

function UMG_PVP_DanGrading_C:OnBtnClose()
  self:DoClose()
  _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.PVPResultShowQuitState)
  _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.ClosePVPCongratulation)
end

function UMG_PVP_DanGrading_C:OnTick(deltaTime)
  if self.SpineFlag then
    self.SpineFlag:Tick(deltaTime, false)
  end
end

function UMG_PVP_DanGrading_C:OnSpineAnimationStart(entry)
  PVPRankedMatchModuleUtils.OnFlagSpineAnimationStart(entry)
end

function UMG_PVP_DanGrading_C:FirstPlay()
  local oldRankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(self.CurShowStar)
  self:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  local incomingGradeAnimConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, oldRankConf.ID)
  self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
  self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
  local spineAnimLength = self.SpineFlag:GetAnimationDuration(incomingGradeAnimConf.show)
  spineAnimLength = spineAnimLength - 1.5
  self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:AnimSyncGroupReset()
  local bCurMaxRankStar = PVPRankedMatchModuleUtils.IsMaxRankStar(self.CurShowStar)
  if bCurMaxRankStar then
    local bTargetMaxRankStar = PVPRankedMatchModuleUtils.IsMaxRankStar(self.TargetShowStar)
    if bTargetMaxRankStar then
      self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
      self:UpdateRankName(oldRankConf)
      self:AnimSyncGroupReset()
    else
      self:DelaySeconds(spineAnimLength, function()
        if not self or not UE.UObject.IsValid(self) then
          return
        end
        self.bFlagAnimFirstPlayed = true
        self:TryPlay()
      end)
      self:UpdateRankName(oldRankConf, function()
        if not self or not UE.UObject.IsValid(self) then
          return
        end
        self.bRollNumberAnimFirstPlayed = true
        self:TryPlay()
      end)
      self.bStartAnimFirstPlayed = true
    end
  else
    self:DelaySeconds(spineAnimLength, function()
      if not self or not UE.UObject.IsValid(self) then
        return
      end
      self.bFlagAnimFirstPlayed = true
      self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
      self.bStartAnimFirstPlayed = true
      self:TryPlay()
    end)
    self:UpdateRankName(oldRankConf)
    self.bRollNumberAnimFirstPlayed = true
  end
end

function UMG_PVP_DanGrading_C:AnimSyncGroupReset()
  self.bRollNumberAnimFirstPlayed = false
  self.bStartAnimFirstPlayed = false
  self.bFlagAnimFirstPlayed = false
end

function UMG_PVP_DanGrading_C:TryPlay()
  if self.bFlagAnimFirstPlayed and self.bStartAnimFirstPlayed and self.bRollNumberAnimFirstPlayed then
    self:AnimSyncGroupReset()
    if self.CurShowStar ~= self.TargetShowStar then
      self:DoPlay()
    else
      local curGrade = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.OnCmdGetRankGrade, self.CurShowStar)
      self:ShowDanStars(curGrade.star_num, curGrade.star_num, true)
    end
  end
end

function UMG_PVP_DanGrading_C:CreateShowDanStarsCallbackChain(oldRankStar, newRankStar)
  local fromRankStar = oldRankStar
  local toRankStar = newRankStar
  local finalRankStar = newRankStar
  local repeatCall
  
  function repeatCall()
    if not self or not UE.UObject.IsValid(self) then
      return
    end
    if not self.callbackChainEnable then
      self:OnGradingEnd()
      return
    end
    local fromGrade = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.OnCmdGetRankGrade, fromRankStar)
    local toGrade = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.OnCmdGetRankGrade, toRankStar)
    local fromShowNum = fromGrade.star_num
    if fromGrade.grade == toGrade.grade then
      if PVPRankedMatchModuleUtils.IsMaxRankStar(toRankStar) then
        self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
      else
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanStars, fromGrade.star_num, toGrade.star_num, false, nil)
      end
    elseif fromGrade.grade < toGrade.grade then
      if fromGrade.star_num < fromGrade.star_total then
        local nextGradeRankStar = fromRankStar + (fromGrade.star_total - fromGrade.star_num)
        fromRankStar = nextGradeRankStar
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanStars, fromGrade.star_num, fromGrade.star_total, false, repeatCall)
      else
        local nextGradeRankStar = fromRankStar + 1
        fromRankStar = nextGradeRankStar
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanFlag, nextGradeRankStar, true, repeatCall)
      end
    else
      local bMaxRankStar = PVPRankedMatchModuleUtils.IsMaxRankStar(fromRankStar)
      if bMaxRankStar then
        local prevGradeRankStar = fromRankStar - 1
        fromRankStar = prevGradeRankStar
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanFlag, prevGradeRankStar, false, repeatCall)
      elseif fromGrade.star_num > 0 then
        local prevGradeRankStar = fromRankStar - fromGrade.star_num
        fromRankStar = prevGradeRankStar
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanStars, fromGrade.star_num, 0, false, repeatCall)
      else
        local prevGradeRankStar = fromRankStar - 1
        fromRankStar = prevGradeRankStar
        _G.NRCModuleManager:DoCmd(BattleUIModuleCmd.OnCmdShowDanFlag, prevGradeRankStar, false, repeatCall)
      end
    end
  end
  
  return repeatCall
end

function UMG_PVP_DanGrading_C:DoPlay()
  self.SpineFlag:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.callbackChain = self:CreateShowDanStarsCallbackChain(self.CurShowStar, self.TargetShowStar)
  self.callbackChainEnable = true
  self.callbackChain()
  self:OnGradingStart()
end

function UMG_PVP_DanGrading_C:OnGradingStart()
  local rankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(self.TargetOrder)
  self:UpdateTextHint(rankConf)
end

function UMG_PVP_DanGrading_C:OnGradingEnd()
end

function UMG_PVP_DanGrading_C:PlayAddDanAnim(newRankConf, isUpgrade, onFinishedCallback)
  if not self or not UE.UObject.IsValid(self) then
    return
  end
  local outgoingGradeAnimConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, newRankConf.ID - 1)
  local incomingGradeAnimConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, newRankConf.ID)
  local rankNameOutAnimLength = 0
  local upgradeDelay = 0
  if isUpgrade then
    self.SpineFlag:SetAnimation(0, outgoingGradeAnimConf.upgrade, false)
    self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
    self:PlayAnimation(self.Level_Out)
    _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.OpenPVPCongratulation)
    rankNameOutAnimLength = self.Level_Out:GetEndTime() - self.Level_Out:GetStartTime()
    upgradeDelay = self.SpineFlag:GetAnimationDuration(outgoingGradeAnimConf.upgrade) - self.SpineFlag:GetAnimationDuration(incomingGradeAnimConf.show)
  else
    self.SpineFlag:SetAnimation(0, incomingGradeAnimConf.show, false)
    self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
  end
  self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
  local rankNameInDelay = rankNameOutAnimLength + upgradeDelay
  self:DelaySeconds(rankNameInDelay, function()
    if not self or not UE.UObject.IsValid(self) then
      return
    end
    self:UpdateRankName(newRankConf)
    if onFinishedCallback then
      local rankNameInAnimLength = self.Level_In:GetEndTime() - self.Level_In:GetStartTime()
      local callBackDelay = rankNameInAnimLength
      self:DelaySeconds(callBackDelay, function()
        if not self or not UE.UObject.IsValid(self) then
          return
        end
        if onFinishedCallback then
          onFinishedCallback()
        end
      end)
    end
  end)
end

function UMG_PVP_DanGrading_C:PlayReduceDanAnim(newRankConf, onFinishedCallback)
  local outgoingGradeAnimConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, newRankConf.ID + 1)
  local incomingGradeAnimConf = _G.NRCModuleManager:DoCmd(PVPRankedMatchModuleCmd.CmdGetGradingAnimConfigWhenDanGrading, newRankConf.ID)
  local flagOutDelay = 0
  if outgoingGradeAnimConf.downgrade then
    self.SpineFlag:SetAnimation(0, outgoingGradeAnimConf.downgrade, false)
  else
    self.SpineFlag:SetAnimation(0, outgoingGradeAnimConf.out, false)
    self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.show, false, 0)
    flagOutDelay = self.SpineFlag:GetAnimationDuration(outgoingGradeAnimConf.out)
  end
  self.SpineFlag:AddAnimation(0, incomingGradeAnimConf.loop, true, 0)
  self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.Collapsed)
  
  local function func()
    if not self or not UE.UObject.IsValid(self) then
      return
    end
    self:UpdateRankName(newRankConf)
    self:UpdateTextHint(newRankConf)
    if onFinishedCallback then
      local rankNameInAnimLength = self.Level_In:GetEndTime() - self.Level_In:GetStartTime()
      local callBackDelay = rankNameInAnimLength
      self:DelaySeconds(callBackDelay, function()
        if not self or not UE.UObject.IsValid(self) then
          return
        end
        if onFinishedCallback then
          onFinishedCallback()
        end
      end)
    end
  end
  
  local bMaxRankStar = PVPRankedMatchModuleUtils.IsMaxRankStar(newRankConf.ID + 1)
  if bMaxRankStar then
    if flagOutDelay > 0 then
      local rankNameInDelay = flagOutDelay
      self:DelaySeconds(flagOutDelay, func)
      self.RankInfoSwitcher:SetActiveWidgetIndex(1)
      self:PlayAnimation(self.Level_Out, 999)
    else
      func()
    end
  else
    self:PlayAnimation(self.Level_Out)
    local rankNameOutAnimLength = self.Level_Out:GetEndTime() - self.Level_Out:GetStartTime()
    local rankNameInDelay = math.max(rankNameOutAnimLength, flagOutDelay)
    self:DelaySeconds(rankNameInDelay, func)
  end
end

function UMG_PVP_DanGrading_C:ShowDanFlag(rankStarToShow, bUpgrade, onFinishedCallback)
  local rankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(rankStarToShow)
  if bUpgrade then
    self:PlayAddDanAnim(rankConf, true, onFinishedCallback)
  else
    self:PlayReduceDanAnim(rankConf, onFinishedCallback)
  end
end

function UMG_PVP_DanGrading_C:ShowDanStars(oldStarNum, newStarNum, bFastShow, onFinishedCallback)
  self.PVPQualifier_Star:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self.PVPQualifier_Star:ShowStars(oldStarNum, newStarNum, bFastShow, onFinishedCallback)
end

function UMG_PVP_DanGrading_C:SequenceEvent_PlayAnimation_UpgradeDan()
  _G.NRCAudioManager:PlaySound2DAuto(40100010, "UMG_PVP_DanGrading_C:DoPlay")
  _G.NRCAudioManager:PlaySound2DAuto(40100009, "UMG_PVP_DanGrading_C:DoPlay")
  _G.NRCAudioManager:PlaySound2DAuto(40100007, "UMG_PVP_DanGrading_C:DoPlay")
  _G.NRCAudioManager:PlaySound2DAuto(40100008, "UMG_PVP_DanGrading_C:DoPlay")
  _G.NRCAudioManager:PlaySound2DAuto(40100011, "UMG_PVP_DanGrading_C:DoPlay")
  _G.NRCAudioManager:PlaySound2DAuto(40100012, "UMG_PVP_DanGrading_C:DoPlay")
end

function UMG_PVP_DanGrading_C:CheckSettleData(pvpRankSettleInfo)
  if not pvpRankSettleInfo then
    Log.Error("UMG_PVP_DanGrading_C ZoneBattleFinishNotify\229\141\143\232\174\174\231\188\186\229\176\145\231\187\147\231\174\151\230\149\176\230\141\174pvp_rank_settle_info")
    return false
  end
  if not pvpRankSettleInfo.new_pvp_rank_star then
    Log.Error("UMG_PVP_DanGrading_C ZoneBattleFinishNotify\229\141\143\232\174\174\231\188\186\229\176\145\231\187\147\231\174\151\230\149\176\230\141\174pvp_rank_settle_info.new_pvp_rank_star")
    return false
  end
  if not pvpRankSettleInfo.old_pvp_rank_star then
    Log.Error("UMG_PVP_DanGrading_C ZoneBattleFinishNotify\229\141\143\232\174\174\231\188\186\229\176\145\231\187\147\231\174\151\230\149\176\230\141\174pvp_rank_settle_info.old_pvp_rank_star")
    return false
  end
  return true
end

function UMG_PVP_DanGrading_C:TryDelayLogic(index, callBack, ...)
  local time = self:GetDelayNumber(index, self.CurChangeStarState)
  if not time then
    Log.Error("UMG_PVP_DanGrading_C: Delay time is nil, Please check DelayFramesMap or DelaySecondsMap, index = ", index, "IsUseFrames=", self.IsUseFrames)
    return
  end
  local args = {
    ...
  }
  if self.IsUseFrames then
    self:DelayFrames(time, function()
      if not self or not UE.UObject.IsValid(self) then
        return
      end
      callBack(table.unpack(args))
    end)
  else
    self:DelaySeconds(time, function()
      if not self or not UE.UObject.IsValid(self) then
        return
      end
      callBack(table.unpack(args))
    end)
  end
end

function UMG_PVP_DanGrading_C:CalcChangeStar(oldRankStar, newRankStar)
  if oldRankStar < newRankStar then
    local realStarNum = 0
    for curId = oldRankStar + 1, newRankStar do
      local rankConf = PVPRankedMatchModuleUtils.GetPvpRankConf(curId)
      if 0 ~= rankConf.star_num then
        realStarNum = realStarNum + 1
      end
    end
    if realStarNum <= 1 then
      return ChangeStarState.AddOneStar
    else
      return ChangeStarState.AddTwoStar
    end
  else
    return ChangeStarState.reduceOneStar
  end
end

function UMG_PVP_DanGrading_C:UpdateRankName(RankConf, Callback)
  if PVPRankedMatchModuleUtils.IsMaxRankStar(RankConf.id) then
    self.RankInfoSwitcher:SetActiveWidgetIndex(2)
    if 0 == self.TargetOrder then
      self.TargetOrder = 10001
    end
    self.UMG_RollNumber:PlayRollNumberAnimWithCallback(self.CurShowOrder, self.TargetOrder, Callback)
    self.TextAdvantage:SetText(tostring(self.TargetMasterScore))
    local deltaMasterScore = PVPRankedMatchModuleUtils.GetDeltaMasterScoreText(self.CurMasterScore, self.TargetMasterScore)
    self.TextAdvantage_1:SetText(deltaMasterScore)
  else
    if Callback then
      Callback()
    end
    self.RankInfoSwitcher:SetActiveWidgetIndex(1)
    self.RankName:SetText(RankConf.name)
    self:PlayAnimation(self.Level_In)
  end
end

function UMG_PVP_DanGrading_C:UpdateTextHint(RankConf)
  local visibility = UE4.ESlateVisibility.Collapsed
  if self.random_pet_addtional_rank_star or self.win_streak_addtional_rank_star then
    if self.random_pet_addtional_rank_star and self.win_streak_addtional_rank_star and self.random_pet_addtional_rank_star > 0 and self.win_streak_addtional_rank_star > 0 then
      visibility = UE4.ESlateVisibility.SelfHitTestInvisible
      if self.win_streak_addtional_rank_star then
        self:BindToAnimationFinished(self.lowest, {
          self,
          function(caller)
            self:UnbindAllFromAnimationFinished(self.lowest)
            self:DelaySeconds(1, function()
              self:_UpdateTextHint_WinStreak()
            end)
          end
        })
      end
      self:_UpdateTextHint_RandomPet()
    elseif self.random_pet_addtional_rank_star and self.random_pet_addtional_rank_star > 0 then
      visibility = UE4.ESlateVisibility.SelfHitTestInvisible
      self:_UpdateTextHint_RandomPet()
    elseif self.win_streak_addtional_rank_star and self.win_streak_addtional_rank_star > 0 then
      visibility = UE4.ESlateVisibility.SelfHitTestInvisible
      self:_UpdateTextHint_WinStreak()
    end
  elseif RankConf and RankConf.rank_unchanged then
    visibility = UE4.ESlateVisibility.SelfHitTestInvisible
    self:_UpdateTextHint_Unchanged()
  end
  self.TextHint:SetVisibility(visibility)
end

function UMG_PVP_DanGrading_C:_UpdateTextHint_WinStreak()
  local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character26").str
  self.TextHint:SetText(str)
  self:PlayAnimation(self.lowest)
end

function UMG_PVP_DanGrading_C:_UpdateTextHint_RandomPet()
  local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character25").str
  self.TextHint:SetText(str)
  self:PlayAnimation(self.lowest)
end

function UMG_PVP_DanGrading_C:_UpdateTextHint_Unchanged()
  local str = _G.DataConfigManager:GetBattleGlobalConfig("pvp_rank_character13").str
  self.TextHint:SetText(str)
  self:PlayAnimation(self.lowest)
end

function UMG_PVP_DanGrading_C:StartLoadSpineAsset()
  local seasonId = _G.NRCModuleManager:DoCmd(_G.PVPRankedMatchModuleCmd.CmdGetCurSeasonId)
  local curRankConf = PVPRankedMatchModuleUtils.GetSelfPVPRankConf()
  local atlasPath, skeletonDataPath = PVPRankedMatchModuleUtils.GetSpineAssetPathsSeasonIdInRankConf(curRankConf, seasonId)
  if atlasPath == self.atlasPath and skeletonDataPath == self.skeletonDataPath then
    self:OnLoadSpineAssetComplete(false, "same path")
    return
  end
  if atlasPath and skeletonDataPath then
    local atlasAsset, skeletonAsset
    local isReady = false
    
    local function checkAssetReady()
      if isReady then
        return
      end
      if UE.UObject.IsValid(atlasAsset) and UE.UObject.IsValid(skeletonAsset) then
        isReady = true
        self.atlasPath = atlasPath
        self.skeletonDataPath = skeletonDataPath
        self:OnLoadSpineAssetComplete(true, atlasAsset, skeletonAsset)
      end
    end
    
    self:LoadPanelRes(atlasPath, 255, function(caller, resRequest, asset)
      atlasAsset = asset
      checkAssetReady()
    end, function()
      self:OnLoadSpineAssetComplete(false, "failed to load atlas data")
    end, nil)
    self:LoadPanelRes(skeletonDataPath, 255, function(caller, resRequest, asset)
      skeletonAsset = asset
      checkAssetReady()
    end, function()
      self:OnLoadSpineAssetComplete(false, "failed to load skeleton data")
    end, nil)
  else
    self:OnLoadSpineAssetComplete(false, "failed to fetch asset path")
  end
end

function UMG_PVP_DanGrading_C:OnLoadSpineAssetComplete(ok, res1, res2)
  if ok then
    local atlasAsset = res1
    local skeletonAsset = res2
    self:SetupSpineWidget(atlasAsset, skeletonAsset)
  else
    local errorMessage = res1
    Log.Error("[UMG_PVPQualifier_C]", errorMessage)
  end
  self:TryDelayLogic(0, self.FirstPlay, self)
end

function UMG_PVP_DanGrading_C:SetupSpineWidget(atlasAsset, skeletonAsset)
  local spineWidget = self.SpineFlag
  spineWidget:ClearTrack(0)
  spineWidget.skeletondata = skeletonAsset
  spineWidget.atlas = atlasAsset
  spineWidget:LuaSynchronizeProperties()
end

return UMG_PVP_DanGrading_C
