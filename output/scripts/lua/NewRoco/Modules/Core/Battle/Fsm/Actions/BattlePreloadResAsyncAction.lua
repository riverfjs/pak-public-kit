local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local Base = BattleActionBase
local BattlePreloadResAsyncAction = Base:Extend("BattlePreloadResAsyncAction")

function BattlePreloadResAsyncAction:Ctor()
  Base.Ctor(self)
  self.preLoadSkillNumber = 0
  self.isResFinish = false
  self.isSkillFinish = false
  self.preloadResList = {
    _G.UEPath.BP_BattleFieldConf,
    BattleConst.BattleDepthCam,
    BattleConst.UI.UMG_Battle_Common_1,
    BattleConst.UI.UMG_Battle_BuffEffectUp,
    BattleConst.UI.UMG_Battle_DamageGeneral,
    BattleConst.MimicRemove,
    _G.UEPath.UMG_Battle_Buff,
    _G.UEPath.UMG_Battle_BuffInfoItem_C,
    BattleConst.BP_BattleEQSRunner_C,
    BattleConst.HandheldShake,
    BattleConst.HandheldWaterShake
  }
  if BattleUtils.IsCrowdBattle() then
    table.insert(self.preloadResList, BattleConst.BattleSearchElliptic)
  end
  self.preloadSkillLst = {
    BattleConst.CounterSkillPreFx,
    false,
    BattleConst.CounterSkillPreNpc,
    false,
    BattleConst.AI_BattlePetJumpToLocation_C,
    false,
    BattleConst.ChangePetEffect,
    false,
    BattleConst.PetTransparentNames.Start,
    true,
    BattleConst.PetTransparentNames.LoopOne,
    true,
    BattleConst.PetTransparentNames.LoopTwo,
    true
  }
  if BattleUtils.IsBloodTeam() then
    table.insert(self.preloadSkillLst, BattleConst.TeamBloodBossEffect)
    table.insert(self.preloadSkillLst, false)
  end
  if not BattleConst.DefaultBattlePlayerPath then
    local global = _G.DataConfigManager:GetBattleGlobalConfig("battle_npc_guarantee", true)
    if global then
      local modelConf = _G.DataConfigManager:GetModelConf(global.num or 0, true)
      if modelConf then
        BattleConst.DefaultBattlePlayerPath = modelConf.path
      end
    end
  end
  self:SetActionType(BattleActionBase.ActionType.ClientLoadResAction)
end

function BattlePreloadResAsyncAction:OnEnter()
  Log.Debug("show me BattlePreloadResAsyncAction time begin:", UE4.UNRCStatics.GetMilliSeconds())
  NRCPanelManager:PreloadPanel("/Game/NewRoco/Modules/System/BattleUI/Res/UMG_BattleMainWindow")
  self:BeginLoadRes()
  Log.Debug("show me BattlePreloadResAsyncAction time mid:", UE4.UNRCStatics.GetMilliSeconds())
  self:BeginLoadSkill()
  Log.Debug("show me BattlePreloadResAsyncAction time end:", UE4.UNRCStatics.GetMilliSeconds())
  self:Finish()
end

function BattlePreloadResAsyncAction:BeginLoadRes()
  self.preLoadAssetNumber = #self.preloadResList
  for i = 1, #self.preloadResList do
    Log.Debug("show me BattlePreloadResAsyncAction time do load:", UE4.UNRCStatics.GetMilliSeconds())
    _G.BattleResourceManager:LoadResAsync(self, self.preloadResList[i], self.PreloadAssetCallBack, self.PreloadAssetCallBack, nil, nil, 255, _G.PriorityEnum.BattleDefault)
  end
end

function BattlePreloadResAsyncAction:PreloadAssetCallBack()
  self.preLoadAssetNumber = self.preLoadAssetNumber - 1
  if 0 == self.preLoadAssetNumber then
    self.isResFinish = true
    self:CheckLoadFinish()
  end
end

function BattlePreloadResAsyncAction:BeginLoadSkill()
  self.preLoadSkillNumber = #self.preloadSkillLst / 2
  for i = 1, #self.preloadSkillLst - 1, 2 do
    BattleSkillManager:PreLoadSingleResInternal(self.preloadSkillLst[i], self.preloadSkillLst[i + 1])
  end
end

function BattlePreloadResAsyncAction:OnBattleEvent(e)
  if e == BattleEvent.OnSkillResLoaded then
    self.preLoadSkillNumber = self.preLoadSkillNumber - 1
    if self.preLoadSkillNumber <= 0 then
      self.isSkillFinish = true
      self:CheckLoadFinish()
    end
  end
end

function BattlePreloadResAsyncAction:CheckLoadFinish()
  if self.isResFinish and self.isSkillFinish and not BattleManager.isPreloadResWithoutWaiting then
    BattleEventCenter:UnBind(self)
    self:Finish()
  end
end

return BattlePreloadResAsyncAction
