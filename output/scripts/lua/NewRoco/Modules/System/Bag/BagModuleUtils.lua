local BagModuleUtils = {}

function BagModuleUtils.FilterSkillMachine(itemList, FilterPetCondition, FilterDepartCondition, FilterClassifyCondition)
  local filterList = BagModuleUtils.FilterPet(itemList, FilterPetCondition)
  filterList = BagModuleUtils.FilterDepart(filterList, FilterDepartCondition)
  filterList = BagModuleUtils.FilterClassify(filterList, FilterClassifyCondition)
  return filterList
end

function BagModuleUtils.FilterPet(itemList, FilterPetCondition)
  local bagItemList = {}
  local filter = FilterPetCondition
  if nil ~= filter and #filter > 0 then
    local petFilter = filter
    local learnSkillId = 0
    for j = 1, #petFilter do
      if petFilter[j] then
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petFilter[j].base_conf_id)
        learnSkillId = petBaseConf and petBaseConf.level_skill_conf_id or 0
      end
      local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(learnSkillId)
      local machineSkillList = {}
      if LevelSkillConf and LevelSkillConf.machine_skill_group then
        machineSkillList = LevelSkillConf.machine_skill_group
      end
      for k = 1, #machineSkillList do
        for i = 1, #itemList do
          local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
          if bagItemConf then
            local skillMachineId = bagItemConf.item_behavior[1].ratio[1]
            if machineSkillList[k].machine_skill_id == skillMachineId then
              table.insert(bagItemList, itemList[i])
            end
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModuleUtils.FilterDepart(itemList, FilterDepartCondition)
  local bagItemList = {}
  local filter = FilterDepartCondition
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
        if bagItemConf then
          local skillMachineId = bagItemConf.item_behavior[1].ratio[1]
          local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineId)
          if skillConf.skill_dam_type == enum then
            table.insert(bagItemList, itemList[i])
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModuleUtils.FilterClassify(itemList, FilterClassifyCondition)
  local bagItemList = {}
  local filter = FilterClassifyCondition
  if nil ~= filter and #filter > 0 then
    for j = 1, #filter do
      local enum = filter[j]
      for i = 1, #itemList do
        local bagItemConf = _G.DataConfigManager:GetBagItemConf(itemList[i].id)
        if bagItemConf then
          local skillMachineId = bagItemConf.item_behavior[1].ratio[1]
          local skillConf = _G.DataConfigManager:GetSkillConf(skillMachineId)
          if skillConf.Skill_Type == enum then
            table.insert(bagItemList, itemList[i])
          end
        end
      end
    end
  else
    bagItemList = itemList
  end
  return bagItemList
end

function BagModuleUtils.GetPetSkillLearnList(bagItemInfo, PetData)
  local skillMachineId = -1
  if bagItemInfo then
    skillMachineId = bagItemInfo.item_behavior[1].ratio[1]
  end
  local petSkillLearnList = {}
  local BattlePetInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerBattlePetInfo()
  local petInfoList = {}
  if PetData then
    local petInfo = _G.DataModelMgr.PlayerDataModel:GetPetDataByGid(PetData.gid)
    petInfoList = {petInfo}
  else
    petInfoList = BattlePetInfo
  end
  if petInfoList and #petInfoList >= 1 then
    for i = 1, #petInfoList do
      if petInfoList[i].blood_id == Enum.PetBloodType.PBT_NIGHTMARE then
        local skillinfo = {
          petInfoList[i],
          2
        }
        table.insert(petSkillLearnList, skillinfo)
      else
        local petBaseConf = _G.DataConfigManager:GetPetbaseConf(petInfoList[i].base_conf_id)
        local learnSkillId = petBaseConf and petBaseConf.level_skill_conf_id or 0
        local LevelSkillConf = _G.DataConfigManager:GetLevelSkillConf(learnSkillId)
        local PetLevelSkillList = {}
        local Allmachineskilllist = {}
        if LevelSkillConf then
          local machineskilllist = LevelSkillConf.machine_skill_group
          local PetLevelInfo = LevelSkillConf.level
          for l, v in pairs(PetLevelInfo) do
            table.insert(PetLevelSkillList, {
              machine_skill_id = v.param
            })
          end
          
          local function isIdExists(id, table)
            for _, v in ipairs(table) do
              if v.machine_skill_id == id then
                return true
              end
            end
            return false
          end
          
          for _, v in ipairs(machineskilllist) do
            if not isIdExists(v.machine_skill_id, Allmachineskilllist) then
              table.insert(Allmachineskilllist, v)
            end
          end
          for j = 1, #Allmachineskilllist do
            if Allmachineskilllist[j].machine_skill_id == skillMachineId then
              if petInfoList[i].skill.skill_data then
                for k = 1, #petInfoList[i].skill.skill_data do
                  if petInfoList[i].skill.skill_data[k].id == skillMachineId then
                    if petInfoList[i].skill.skill_data[k].is_learned == true then
                      local skillInfo = {
                        petInfoList[i],
                        1
                      }
                      table.insert(petSkillLearnList, skillInfo)
                      break
                    else
                      local skillInfo = {
                        petInfoList[i],
                        0
                      }
                      table.insert(petSkillLearnList, skillInfo)
                      break
                    end
                  end
                  if k == #petInfoList[i].skill.skill_data then
                    local skillInfo = {
                      petInfoList[i],
                      0
                    }
                    table.insert(petSkillLearnList, skillInfo)
                  end
                end
              end
              break
            end
            if j == #Allmachineskilllist then
              local skillInfo = {
                petInfoList[i],
                2
              }
              table.insert(petSkillLearnList, skillInfo)
            end
          end
        else
          local skillInfo = {
            petInfoList[i],
            2
          }
          table.insert(petSkillLearnList, skillInfo)
        end
      end
    end
  end
  return petSkillLearnList
end

function BagModuleUtils.GetConvertAfterItemsList(_data)
  local afterConvertList = {}
  if _data then
    for _, expireInfo in ipairs(_data) do
      local bagItemConf = _G.DataConfigManager:GetBagItemConf(expireInfo.id)
      if bagItemConf and bagItemConf.expire_converse_struct then
        for _, converseInfo in ipairs(bagItemConf.expire_converse_struct) do
          local bFound = false
          for _, existingItem in ipairs(afterConvertList) do
            if existingItem.itemType == converseInfo.converse_type and existingItem.itemId == converseInfo.converse_id then
              existingItem.itemNum = existingItem.itemNum + (converseInfo.converse_num or 1)
              bFound = true
              break
            end
          end
          if not bFound then
            local afterItem = _G.NRCCommonItemIconData()
            afterItem.itemType = converseInfo.converse_type
            afterItem.itemId = converseInfo.converse_id
            afterItem.itemNum = converseInfo.converse_num or 1
            afterItem.bShowNum = true
            afterItem.bShowTip = true
            table.insert(afterConvertList, afterItem)
          end
        end
      end
    end
  end
  return afterConvertList
end

return BagModuleUtils
