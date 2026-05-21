local Enum = require("Data.Config.Enum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
require("Common.UE4Extension")
local ChaosExpressionNatureId = 22
local PetMutationUtils = {}
local colorIdBitNum = 20
local particleBitNum = 12

function PetMutationUtils.MakeEmptyShineInfo()
  return {colorId = 1, particle = 1}
end

function PetMutationUtils.MakeEmptyGlassInfoDetails()
  return {
    colorInfo = PetMutationUtils.MakeEmptyShineInfo(),
    glassType = ProtoEnum.GlassType.GT_COMMON,
    hiddenGlassValue = 0
  }
end

function PetMutationUtils.EncodeShineColorInfo(glassInfoDetails)
  local glassValue = 0
  local glassType = ProtoEnum.GlassType.GT_COMMON
  if glassInfoDetails then
    if glassInfoDetails.glassType == ProtoEnum.GlassType.GT_COMMON then
      if glassInfoDetails.colorInfo ~= nil then
        glassValue = glassInfoDetails.colorInfo.colorId + (glassInfoDetails.colorInfo.particle << colorIdBitNum)
        glassType = ProtoEnum.GlassType.GT_COMMON
      end
    elseif glassInfoDetails.glassType == ProtoEnum.GlassType.GT_HIDDEN then
      glassValue = glassInfoDetails.hiddenGlassValue
      glassType = ProtoEnum.GlassType.GT_HIDDEN
    end
  end
  local glassInfo = {glass_type = glassType, glass_value = glassValue}
  return glassInfo
end

function PetMutationUtils.DecodeShineColorId(glass_info)
  local glassInfoDetails = PetMutationUtils.MakeEmptyGlassInfoDetails()
  if glass_info and glass_info.glass_type and glass_info.glass_value then
    if glass_info.glass_type == ProtoEnum.GlassType.GT_COMMON then
      glassInfoDetails.glassType = ProtoEnum.GlassType.GT_COMMON
      glassInfoDetails.colorInfo.particle = glass_info.glass_value >> colorIdBitNum
      glassInfoDetails.colorInfo.colorId = glass_info.glass_value - (glassInfoDetails.colorInfo.particle << colorIdBitNum)
    elseif glass_info.glass_type == ProtoEnum.GlassType.GT_HIDDEN then
      glassInfoDetails.glassType = ProtoEnum.GlassType.GT_HIDDEN
      glassInfoDetails.hiddenGlassValue = glass_info.glass_value
    end
  end
  return glassInfoDetails
end

function PetMutationUtils.GetShineColor(rgba)
  if nil == rgba or #rgba < 3 then
    return nil
  end
  local color = UE.FLinearColor(0, 0, 0, 1)
  color.R = rgba[1]
  color.G = rgba[2]
  color.B = rgba[3]
  if rgba[4] then
    color.A = rgba[4]
  end
  return color
end

local PerLoadPathToKeyMap = {}
local PreLoadKeyHelper = {}

function PetMutationUtils.GetPreloadList()
  local list = {}
  
  local function getAssetPath(longPath)
    if not longPath or type(longPath) ~= "string" then
      return longPath
    end
    local startQuote, endQuote = string.find(longPath, "'([^']+)'")
    if startQuote and endQuote then
      local extractedPath = string.sub(longPath, startQuote + 1, endQuote - 1)
      return extractedPath
    end
    return longPath
  end
  
  local function setPreLoadList(key, path)
    if not key or "" == key then
      return
    end
    if not path or "" == path then
      return
    end
    local exitedKey = PerLoadPathToKeyMap[path]
    if exitedKey then
      PreLoadKeyHelper[key] = exitedKey
      return
    end
    PerLoadPathToKeyMap[path] = key
    list[key] = path
  end
  
  local particleRandomConfigs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PARTICLE_RANDOM_CONF)
  if particleRandomConfigs then
    for _, conf in pairs(particleRandomConfigs) do
      local assetPath = getAssetPath(conf.particle_res)
      setPreLoadList(PetMutationUtils.GetGeneralParticleKey(conf.id), assetPath)
      if conf.egg_particle_res and conf.egg_particle_res ~= "" then
        local EggAssetPath = getAssetPath(conf.egg_particle_res)
        setPreLoadList(PetMutationUtils.GetGeneralEggParticleKey(conf.id), EggAssetPath)
      end
    end
  end
  local hiddenGlassConfigs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.HIDDEN_GLASS_CONF)
  if hiddenGlassConfigs then
    for _, conf in pairs(hiddenGlassConfigs) do
      local texturePaths = conf.tex_param
      if texturePaths then
        for _, texturePath in pairs(texturePaths) do
          local assetPath = getAssetPath(texturePath.tex_param_path)
          setPreLoadList(PetMutationUtils.GetHiddenParticleKey(conf.id, texturePath.tex_param_name), assetPath)
        end
      end
    end
  end
  setPreLoadList(PetMutationUtils.GetNormalEggKeyStarStickTex(), "Texture2D'/Game/ArtRes/BP/Texture/PetGlassyStar/Tex_EggGlassyStar_001.Tex_EggGlassyStar_001'")
  setPreLoadList(PetMutationUtils.GetNormalEggKeyAdditionalMat(), "MaterialInstanceConstant'/Game/ArtRes/Material/Characters/PetBase/MaterialInstance/Special/MI_P_EggGlassy_Outline.MI_P_EggGlassy_Outline'")
  local eggTypeConfigs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.EGG_TYPE_CONF)
  if eggTypeConfigs then
    for _, conf in pairs(eggTypeConfigs) do
      local assetPath = conf.model_tex
      if assetPath then
        setPreLoadList(PetMutationUtils.GetNormalEggKeyModelMat(conf.precious_egg_type), assetPath)
      end
    end
  end
  local petRandomEggConfigs = _G.DataConfigManager:GetTable(_G.DataConfigManager.ConfigTableId.PET_RANDOM_EGG_CONF)
  if petRandomEggConfigs then
    for _, conf in pairs(petRandomEggConfigs) do
      local assetPath = conf.model_mark_tex
      setPreLoadList(PetMutationUtils.GetRandomEggKeyModelMarkTex(conf.id), assetPath)
    end
  end
  setPreLoadList(PetMutationUtils.GetRandomEggKeyOutline(), "Texture2D'/Game/ArtRes/AnimSequence/Pets/EggRandom/T_EggRandom_Fx.T_EggRandom_Fx'")
  return list
end

function PetMutationUtils.GetGeneralParticleKey(id)
  return string.format("PetMutationParticleGeneral-%d", id)
end

function PetMutationUtils.GetGeneralEggParticleKey(id)
  return string.format("PetEggMutationParticleGeneral-%d", id)
end

function PetMutationUtils.GetHiddenParticleKey(id, property)
  return string.format("PetMutationParticleHidden-%d-%s", id, property)
end

function PetMutationUtils.GetNormalEggKeyStarStickTex()
  return string.format("PetMutationShine-NormalEgg-StarStick")
end

function PetMutationUtils.GetNormalEggKeyAdditionalMat()
  return string.format("PetMutationShine-NormalEgg-AdditionalMat")
end

function PetMutationUtils.GetRandomEggKeyModelMarkTex(id)
  return string.format("PetMutationShine-RandomEgg-%d-MarkTex", id)
end

function PetMutationUtils.GetRandomEggKeyOutline()
  return string.format("PetMutationShine-RandomEgg-Outline")
end

function PetMutationUtils.GetNormalEggKeyModelMat(precious_egg_type)
  return string.format("PetMutation-NormalEgg-%d-ModelMat", precious_egg_type)
end

function PetMutationUtils.GetShineParticle(key)
  if not key then
    Log.Warning("PetMutationUtils.GetShineParticle key is nil")
    return
  end
  local realKey = key
  local existedKey = PreLoadKeyHelper[key]
  if existedKey then
    realKey = existedKey
  end
  local particle = _G.NRCBigWorldPreloader:Get(realKey)
  if not particle then
    Log.Warning("PetMutationUtils.GetShineParticle particle is nil", key, realKey)
  end
  return particle
end

PetMutationUtils.GlassActorType = {
  NormalPet = 0,
  NormalEgg = 1,
  RandomEgg = 2
}

function PetMutationUtils.SetPetDataGlassActorType(petData, value)
  if petData then
    petData.glassyActorType = value
  end
end

function PetMutationUtils.GetPetDataGlassActorType(petData)
  if not petData then
    return nil
  end
  return petData.glassyActorType
end

function PetMutationUtils.IsGlassyNormalPet(petData)
  local actorType = PetMutationUtils.GetPetDataGlassActorType(petData)
  return nil == actorType or actorType == PetMutationUtils.GlassActorType.NormalPet
end

function PetMutationUtils.IsGlassyNormalEgg(petData)
  return PetMutationUtils.GetPetDataGlassActorType(petData) == PetMutationUtils.GlassActorType.NormalEgg
end

function PetMutationUtils.IsGlassyRandomEgg(petData)
  return PetMutationUtils.GetPetDataGlassActorType(petData) == PetMutationUtils.GlassActorType.RandomEgg
end

function PetMutationUtils.GetNpcColorMutatationModelCfg(npcCfg)
  local modelCfg
  if npcCfg.traverse_data_type and #npcCfg.traverse_data_param > 0 and npcCfg.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
    local petbaseId = npcCfg.traverse_data_param[1]
    modelCfg = PetMutationUtils.GetutatationModelCfgByPetbaseId(petbaseId)
  end
  modelCfg = modelCfg or _G.DataConfigManager:GetModelConf(npcCfg.model_conf)
  return modelCfg
end

function PetMutationUtils.GetutatationModelCfgByPetbaseId(petbaseId)
  local modelCfg
  local petbaseCfg = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  if petbaseCfg then
    modelCfg = _G.DataConfigManager:GetModelConf(petbaseCfg.shining_model_conf)
  end
  return modelCfg
end

function PetMutationUtils.GetNpcHeightModelScale(npcCfg, height)
  local heightModelScale = 1
  if npcCfg.traverse_data_type and #npcCfg.traverse_data_param > 0 and npcCfg.traverse_data_type == Enum.Traverse_Data_Type.TDT_PETBASE then
    local petbaseId = npcCfg.traverse_data_param[1]
    heightModelScale = PetMutationUtils.GetHeightModelScale(petbaseId, height)
  end
  return heightModelScale
end

local _height_low_scale_percent, _height_scale_space

function PetMutationUtils.GetHeightModelScale(petbaseId, height)
  if nil == height then
    return 1
  end
  local petbaseCfg = _G.DataConfigManager:GetPetbaseConf(petbaseId)
  if not petbaseCfg then
    return 1
  end
  local height_low = petbaseCfg.height_low
  local height_high = petbaseCfg.height_high
  if height < height_low then
    height = height_low
  end
  if height_high < height then
    height = height_high
  end
  local height_ratio = 1
  local height_diff = height_high - height_low
  if height_diff >= 0.01 then
    height_ratio = (height - height_low) / height_diff
  end
  if not _height_low_scale_percent then
    _height_low_scale_percent = _G.DataConfigManager:GetPetGlobalConfig("height_low_scale_percent").num / 10000
  end
  if not _height_scale_space then
    _height_scale_space = _G.DataConfigManager:GetPetGlobalConfig("height_scale_space").num / 10000
  end
  local scale = _height_low_scale_percent + _height_scale_space * height_ratio
  if scale > 20 then
    Log.Error("zgx GetHeightModelScale \229\188\130\229\184\184\239\188\129\239\188\129\239\188\129", scale)
    return 20
  else
    return scale
  end
end

function PetMutationUtils.GetHeightModelScaleByPetData(petData)
  if not petData then
    return 1
  end
  local petbaseId = petData.base_conf_id
  local height = petData.height
  local heightModelScale = PetMutationUtils.GetHeightModelScale(petbaseId, height)
  return heightModelScale
end

function PetMutationUtils.NotifyMutationComplete(character)
  if not character then
    return
  end
  if character.sceneCharacter and character.sceneCharacter.SendEvent then
    character.sceneCharacter:SendEvent(NPCModuleEvent.OnNpcMutationComplete, character)
  else
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.OnNpcMutationComplete, character)
  end
end

function PetMutationUtils.GetDisplayMutationData(card, is_show_shining)
  is_show_shining = is_show_shining or false
  local mutationPetData = {
    mutation_type = card.petInfo.battle_common_pet_info.mutation_type,
    nature = card.petInfo.battle_common_pet_info.nature,
    glass_info = card.petInfo.battle_common_pet_info.glass_info,
    base_conf_id = card.petInfo.battle_inside_pet_info.base_conf_id or card.petInfo.battle_common_pet_info.base_conf_id
  }
  if card.petState:GetNightmare() or card.petState:GetNightmareOne() then
    mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS
    mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS_TWO
    mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_CHAOS_THREE
    if not is_show_shining then
      mutationPetData.mutation_type = mutationPetData.mutation_type & ~_G.Enum.MutationDiffType.MDT_SHINING
    end
  end
  return mutationPetData
end

function PetMutationUtils.GetMutationValue(mutation_type, type)
  return (mutation_type or 0) & (type or 0) > 0
end

function PetMutationUtils.DoMutation(character, petData)
  if not petData or not character then
    return
  end
  if not UE.UObject.IsValid(character) then
    return
  end
  local mutation_type = petData.mutation_type
  local nature = petData.nature
  local bAsyncLoaded = false
  if mutation_type then
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
      PetMutationUtils.SetColorDiffMutation(character)
      bAsyncLoaded = true
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
      PetMutationUtils.SetGlassyDiffMutation(character, petData)
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS) then
      PetMutationUtils.SetNightmareFirstMutation(character)
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) then
      PetMutationUtils.SetNightmareSecondMutation(character)
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) then
      PetMutationUtils.SetNightmareByIDMask(character)
    end
  end
  if not bAsyncLoaded then
    PetMutationUtils.NotifyMutationComplete(character)
  end
  if nature then
    local finalNature = PetMutationUtils.GetFinalNature(nature, mutation_type)
    local Value = PetMutationUtils.GetOverrideExpression(finalNature)
    character.OverrideExpression = Value
    local Mesh = character.Mesh
    local MatComp = character.RocoMaterial
    if Mesh and MatComp then
      MatComp:SetOverrideNature(finalNature)
      MatComp:UpdateOverrideNature(Mesh, finalNature)
    end
  end
end

function PetMutationUtils.DoMutationForTest(character, MutationDiffType)
  if not MutationDiffType or not character then
    return
  end
  if MutationDiffType then
    if PetMutationUtils.GetMutationValue(MutationDiffType, _G.Enum.MutationDiffType.MDT_SHINING) then
      character:SetColorDiffMutation(UE.EPetMaterialDifferenceType.ColorDiff)
    end
    if PetMutationUtils.GetMutationValue(MutationDiffType, _G.Enum.MutationDiffType.MDT_GLASS) then
      character:SetGlassyDiffMutation()
    end
    if PetMutationUtils.GetMutationValue(MutationDiffType, _G.Enum.MutationDiffType.MDT_CHAOS) then
      character:SetNightmare1Mutation()
    end
    if PetMutationUtils.GetMutationValue(MutationDiffType, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) then
      character:SetNightmare2Mutation()
    end
  end
end

function PetMutationUtils.DoMutationSpecific(character, diffType)
  if not character then
    return
  end
  diffType = diffType or UE.EPetMaterialDifferenceType.Default
  PetMutationUtils.SetColorDiffMutation(character, diffType)
end

function PetMutationUtils.GetFinalNature(nature, diff)
  if PetMutationUtils.GetMutationValue(diff, _G.Enum.MutationDiffType.MDT_CHAOS) or PetMutationUtils.GetMutationValue(diff, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) or PetMutationUtils.GetMutationValue(diff, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) then
    return ChaosExpressionNatureId
  end
  return nature
end

function PetMutationUtils.GetOverrideExpression(NatureID)
  if not NatureID or 0 == NatureID then
    return 100
  end
  local nature = _G.DataConfigManager:GetNatureConf(NatureID)
  if nature then
    return math.max(nature.relative_emotion, 100)
  end
  return 100
end

function PetMutationUtils.GetMatSuffix(object)
  local name = ""
  if type(object) == "string" then
    name = object
  else
    name = UE.UKismetSystemLibrary.GetObjectName(object)
  end
  local nameSet = string.split(name, "_")
  if #nameSet <= 0 then
    return nil
  end
  return nameSet[#nameSet]
end

function PetMutationUtils.GetMaterialsSuffixTable(character)
  local materialsSuffix = {}
  if not UE4.UObject.IsValid(character) then
    return materialsSuffix
  end
  local mesh = character.mesh
  if nil == mesh then
    return materialsSuffix
  end
  local materials
  if mesh.GetSoftSkeletalMeshMaterials then
    materials = mesh:GetSoftSkeletalMeshMaterials()
  else
    materials = mesh:GetMaterials()
  end
  for idx, mat in tpairs(materials) do
    local suffix = PetMutationUtils.GetMatSuffix(mat)
    if nil ~= suffix then
      materialsSuffix[idx] = suffix
    end
  end
  return materialsSuffix
end

function PetMutationUtils.PrepareMutationAssets(character, petData)
  if not petData or not character then
    return
  end
  local mutation_type = petData.mutation_type
  if mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    local MaterialMap = character.DiffMaterials
    local originMaterialsSuffix
    local defaultMaterialList = MaterialMap:Find(UE.EPetMaterialDifferenceType.Default)
    if defaultMaterialList and defaultMaterialList.Materials and defaultMaterialList.Materials:Num() > 0 then
      originMaterialsSuffix = {}
      for idx, softMaterial in tpairs(defaultMaterialList.Materials) do
        local materialPath = UE4.UNRCStatics.GetSoftObjPath(softMaterial)
        local suffix = PetMutationUtils.GetMatSuffix(materialPath)
        if nil ~= suffix then
          originMaterialsSuffix[idx] = suffix
        end
      end
    end
    local colorDiffMaterialList = MaterialMap:Find(UE.EPetMaterialDifferenceType.ColorDiff)
    if colorDiffMaterialList then
      if nil == originMaterialsSuffix then
        Log.Debug("PetMutationUtils.PrepareMutationAssets originMaterialsSuffix still nil", UE4.UKismetSystemLibrary.GetDisplayName(character))
        originMaterialsSuffix = PetMutationUtils.GetMaterialsSuffixTable(character)
      end
      local materialsPaths = UE4.TArray("")
      for _, _ in pairs(originMaterialsSuffix) do
        materialsPaths:Add("")
      end
      for _, softMaterial in tpairs(colorDiffMaterialList.Materials) do
        local materialPath = UE4.UNRCStatics.GetSoftObjPath(softMaterial)
        local materialSuffix = PetMutationUtils.GetMatSuffix(materialPath)
        for idx, suffix in pairs(originMaterialsSuffix) do
          if materialSuffix == suffix then
            materialsPaths[idx] = materialPath
            break
          end
        end
      end
      character.mesh:SetMaterialsToLoad(materialsPaths)
    end
    local fxListColorDiff = character.SelfFxListColorDiff
    if fxListColorDiff and fxListColorDiff:Num() > 0 then
      character.SelfFxList = fxListColorDiff
    end
  end
end

function PetMutationUtils.GetMaterialParamsAll(mesh, idx)
  if not UE4.UObject.IsValid(mesh) then
    return nil
  end
  local result = {}
  local mat = mesh:GetMaterial(idx)
  if not UE4.UObject.IsValid(mat) then
    return nil
  end
  result.SelfParam = PetMutationUtils.GetMaterialRecord(mat)
  result.AdditionalParam = {}
  for additionalIdx, additionalMaterial in tpairs(mat.AdditionalMaterials) do
    local record = PetMutationUtils.GetMaterialRecord(additionalMaterial)
    if nil ~= record then
      result.AdditionalParam[additionalIdx] = record
    end
  end
  return result
end

function PetMutationUtils.GetMaterialRecord(mat)
  if not mat then
    return nil
  end
  local record = {}
  if mat.DynamicSwitchParameters then
    record.SwitchParam = {}
    for _, param in tpairs(mat.DynamicSwitchParameters) do
      record.SwitchParam[param.ParameterInfo] = param.Value
    end
  end
  if mat.ScalarParameterValues then
    record.FloatParam = {}
    for _, param in tpairs(mat.ScalarParameterValues) do
      record.FloatParam[param.ParameterInfo] = param.ParameterValue
    end
  end
  if mat.VectorParameterValues then
    record.VectorParam = {}
    for _, param in tpairs(mat.VectorParameterValues) do
      record.VectorParam[param.ParameterInfo] = param.ParameterValue
    end
  end
  if mat.TextureParameterValues then
    record.TextureParam = {}
    for _, param in tpairs(mat.TextureParameterValues) do
      record.TextureParam[param.ParameterInfo] = param.ParameterValue
    end
  end
  return record
end

function PetMutationUtils.ApplyMaterialParamsAll(mesh, mat, params)
  if not params then
    return
  end
  PetMutationUtils.ApplyMaterialRecord(mesh, mat, params.SelfParam)
  if params.AdditionalParam then
    for idx, additionalMaterial in tpairs(mat.AdditionalMaterials) do
      local record = params.AdditionalParam[idx]
      if nil ~= record then
        PetMutationUtils.ApplyMaterialRecord(mesh, additionalMaterial, record)
      end
    end
  end
end

function PetMutationUtils.ApplyMaterialRecord(mesh, mat, record)
  if not mat or not record then
    return
  end
  if record.SwitchParam and mat.SetSwitchParameterValueByInfo then
    for info, val in pairs(record.SwitchParam) do
      mat:SetSwitchParameterValueByInfo(info, val, mesh, false)
    end
  end
  if record.FloatParam and mat.SetScalarParameterValueByInfo then
    for info, val in pairs(record.FloatParam) do
      mat:SetScalarParameterValueByInfo(info, val)
    end
  end
  if record.VectorParam and mat.SetVectorParameterValueByInfo then
    for info, val in pairs(record.VectorParam) do
      mat:SetVectorParameterValueByInfo(info, val)
    end
  end
  if record.TextureParam and mat.SetTextureParameterValueByInfo then
    for info, val in pairs(record.TextureParam) do
      mat:SetTextureParameterValueByInfo(info, val)
    end
  end
end

function PetMutationUtils.SetColorDiffMutation(character, diffType)
  if not UE4.UObject.IsValid(character) then
    return
  end
  if not character.RocoMaterial then
    Log.Warning("character.RocoMaterial is invalid", UE4.UKismetStringLibrary.Conv_ObjectToString(character))
    return
  end
  if character.mesh.GetMaterialResources then
    local colorDiffMaterials = character.mesh:GetMaterialResources()
    if colorDiffMaterials:Num() > 0 then
      PetMutationUtils.NotifyMutationComplete(character)
      return
    end
  end
  Log.Warning("PetMutationUtils.SetColorDiffMutation not prepare", character, diffType)
  local MaterialMap = character.DiffMaterials
  if nil == diffType then
    diffType = UE.EPetMaterialDifferenceType.ColorDiff
  end
  local mutationMaterials = MaterialMap:Find(diffType)
  if mutationMaterials then
    local totalMaterialNums = mutationMaterials.Materials:Num()
    local completedMaterialNum = 0
    
    local function onMaterialComplete()
      completedMaterialNum = completedMaterialNum + 1
      if completedMaterialNum >= totalMaterialNums then
        PetMutationUtils.NotifyMutationComplete(character)
      end
    end
    
    local originMaterialsSuffix = PetMutationUtils.GetMaterialsSuffixTable(character)
    
    local function onLoadMaterialSucceed(caller, req, asset)
      PetMutationUtils.ApplyColorDiffMaterial(character, originMaterialsSuffix, asset)
      onMaterialComplete()
    end
    
    local function onLoadMaterialFailed(caller, req, msg)
      Log.Warning("PetMutationUtils.SetColorDiffMutation onLoadMaterialFailed!", UE4.UKismetSystemLibrary.GetDisplayName(character), req.assetPath, msg)
      onMaterialComplete()
    end
    
    for _, softColorDiffMat in tpairs(mutationMaterials.Materials) do
      _G.NRCResourceManager:LoadResAsync(character, UE4.UNRCStatics.GetSoftObjPath(softColorDiffMat), PriorityEnum.Active_World_NPC_Mutation, 10, onLoadMaterialSucceed, onLoadMaterialFailed)
    end
  end
end

function PetMutationUtils.ApplyColorDiffMaterial(character, originMaterialsSuffix, colorDiffMat)
  if UE4.UObject.IsValid(colorDiffMat) then
    local colorDiffMatSuffix = PetMutationUtils.GetMatSuffix(colorDiffMat)
    for originIdx, originMatSuffix in pairs(originMaterialsSuffix) do
      if colorDiffMatSuffix == originMatSuffix then
        local realOriginIdx = originIdx - 1
        if character and UE4.UObject.IsValid(character) and character.RocoMaterial and UE4.UObject.IsValid(character.RocoMaterial) then
          local params = PetMutationUtils.GetMaterialParamsAll(character.mesh, realOriginIdx)
          local newMat = character.RocoMaterial:PermanentModifyMaterialByIndexSingleMesh(colorDiffMat, realOriginIdx, character.mesh)
          PetMutationUtils.ApplyMaterialParamsAll(character.mesh, newMat, params)
        end
        break
      end
    end
  end
end

function PetMutationUtils.SetGlassyDiffMutation(character, petData)
  if not UE4.UObject.IsValid(character) then
    return
  end
  if not petData then
    return
  end
  local glass_info = petData.glass_info
  if PetMutationUtils.IsGlassyNormalEgg(petData) then
    local bNotExplicitGlassyEgg = false
    if not glass_info then
      bNotExplicitGlassyEgg = true
    elseif glass_info.glass_type == _G.ProtoEnum.GlassType.GT_NULL and 0 == glass_info.glass_value then
      bNotExplicitGlassyEgg = true
    end
    if bNotExplicitGlassyEgg then
      PetMutationUtils.SetGlassyDiffMutationForNormalEgg(character, petData)
      return
    end
  end
  if not glass_info then
    Log.Debug("PetMutationUtils.SetGlassyDiffMutation no glass_info", petData.base_conf_id)
    return
  end
  if glass_info.glass_type == _G.ProtoEnum.GlassType.GT_NULL then
    Log.Debug("PetMutationUtils.SetGlassyDiffMutation no glass", glass_info.glass_value)
    return
  end
  
  local function processMaterial(mat, mesh, idx, colorA, colorB, strength, particle, starStickTiling)
    if not PetMutationUtils.IsGlassyRandomEgg(petData) then
      mat:SetSwitchParameterValue("GlassySwitch", true, mesh, false)
      if nil ~= colorA then
        mat:SetVectorParameterValue("RedChannel", colorA)
      end
      if nil ~= colorB then
        mat:SetVectorParameterValue("GreenChannel", colorB)
      end
      if nil ~= strength then
        mat:SetScalarParameterValue("StarIntensity", strength)
      end
      if nil ~= particle then
        mat:SetTextureParameterValue("StarStickTex", particle)
      end
      mat:SetVectorParameterValue("MutationRimColor", UE.FLinearColor(0.6, 0.6, 0.6, 1))
      mat:SetVectorParameterValue("MutationSpecularParams", UE.FLinearColor(0.8, 0.3, 200, 0.2))
    else
      local GlassInfo = UE4.FMaterialParameterInfo()
      GlassInfo.Name = ""
      GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
      GlassInfo.Index = 1
      if nil ~= colorA then
        GlassInfo.Name = "RedChannel"
        mat:SetVectorParameterValueByInfo(GlassInfo, colorA)
      end
      if nil ~= colorB then
        GlassInfo.Name = "GreenChannel"
        mat:SetVectorParameterValueByInfo(GlassInfo, colorB)
      end
      if nil ~= strength then
        GlassInfo.Name = "StarIntensity"
        mat:SetScalarParameterValueByInfo(GlassInfo, strength)
      end
      if nil ~= starStickTiling then
        GlassInfo.Name = "StarStickTiling"
        mat:SetScalarParameterValueByInfo(GlassInfo, starStickTiling)
      end
      if nil ~= particle then
        GlassInfo.Name = "StarStickTex"
        mat:SetTextureParameterValueByInfo(GlassInfo, particle)
      end
    end
  end
  
  local function processAdditionalMaterial(additionalMat, mesh, idx, colorA, colorB)
    if colorA and colorB then
      additionalMat:SetSwitchParameterValue("GlassySwitch", true, mesh, false)
    end
    if nil ~= colorA then
      additionalMat:SetVectorParameterValue("RedChannel", colorA)
    end
    if nil ~= colorB then
      additionalMat:SetVectorParameterValue("GreenChannel", colorB)
    end
  end
  
  local materialFunc, additionalFunc
  if glass_info.glass_type == _G.ProtoEnum.GlassType.GT_HIDDEN then
    local conf = _G.DataConfigManager:GetHiddenGlassConf(glass_info.glass_value, true)
    if conf then
      local colorA = PetMutationUtils.GetShineColor(conf.glass_color_1)
      local colorB = PetMutationUtils.GetShineColor(conf.glass_color_2)
      local bSeasonButNotCustomPet = false
      if conf.type == _G.ProtoEnum.HiddenGlassType.HGT_SEASON then
        if petData.base_conf_id and petData.base_conf_id == conf.season_pet then
          if not PetMutationUtils.IsGlassyRandomEgg(petData) then
            local seasonSwitchName = "MutationSwitch"
            local seasonSwitchLayer = UE4.EMaterialParameterAssociation.LayerParameter
            
            function materialFunc(mat, mesh, idx)
              if mat.DynamicSwitchParameters then
                for _, param in tpairs(mat.DynamicSwitchParameters) do
                  local paramInfo = param.ParameterInfo
                  if paramInfo and paramInfo.Name == seasonSwitchName and paramInfo.Association == seasonSwitchLayer then
                    mat:SetSwitchParameterValueByInfo(paramInfo, true, mesh, false)
                    break
                  end
                end
              end
            end
            
            function additionalFunc(additionalMat, mesh, idx)
              processAdditionalMaterial(additionalMat, mesh, idx, colorA, colorB)
            end
          end
        else
          bSeasonButNotCustomPet = true
        end
      end
      if bSeasonButNotCustomPet or conf.type == _G.ProtoEnum.HiddenGlassType.HGT_RESIDENT then
        local textureParams = {}
        if conf.tex_param then
          for _, texturePath in ipairs(conf.tex_param) do
            local paramName = texturePath.tex_param_name
            if paramName then
              local texture = PetMutationUtils.GetShineParticle(PetMutationUtils.GetHiddenParticleKey(conf.id, paramName))
              if texture then
                textureParams[paramName] = texture
              end
            end
          end
        end
        local scalarParams = {}
        if conf.num_param then
          for _, scalarParam in ipairs(conf.num_param) do
            local paramName = scalarParam.num_param_name
            local scalarValue = scalarParam.num_param_value
            if paramName and scalarValue then
              scalarParams[paramName] = scalarValue
            end
          end
        end
        local vectorParams = {}
        if conf.color_param then
          for _, colorParam in ipairs(conf.color_param) do
            local paramName = colorParam.color_param_name
            local colorArray = colorParam.color_param_value
            vectorParams[paramName] = PetMutationUtils.GetShineColor(colorArray)
          end
        end
        
        function materialFunc(mat, mesh, idx)
          processMaterial(mat, mesh, idx, colorA, colorB, nil, nil)
          for name, value in pairs(scalarParams) do
            if value then
              if not PetMutationUtils.IsGlassyRandomEgg(petData) then
                mat:SetScalarParameterValue(name, value)
              else
                local GlassInfo = UE4.FMaterialParameterInfo()
                GlassInfo.Name = name
                GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
                GlassInfo.Index = 1
                mat:SetScalarParameterValueByInfo(GlassInfo, value)
              end
            end
          end
          for name, color in pairs(vectorParams) do
            if color then
              if not PetMutationUtils.IsGlassyRandomEgg(petData) then
                mat:SetVectorParameterValue(name, color)
              else
                local GlassInfo = UE4.FMaterialParameterInfo()
                GlassInfo.Name = name
                GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
                GlassInfo.Index = 1
                mat:SetVectorParameterValueByInfo(GlassInfo, color)
              end
            end
          end
          for name, texture in pairs(textureParams) do
            if texture then
              if not PetMutationUtils.IsGlassyRandomEgg(petData) then
                mat:SetTextureParameterValue(name, texture)
              else
                local GlassInfo = UE4.FMaterialParameterInfo()
                GlassInfo.Name = name
                GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
                GlassInfo.Index = 1
                mat:SetTextureParameterValueByInfo(GlassInfo, texture)
              end
            end
          end
        end
        
        function additionalFunc(additionalMat, mesh, idx)
          processAdditionalMaterial(additionalMat, mesh, idx, colorA, colorB)
        end
      end
    else
      Log.Warning("PetMutationUtils.SetGlassyDiffMutation hidden glass config not existed", glass_info.glass_type, glass_info.glass_value)
    end
  elseif glass_info.glass_type == _G.ProtoEnum.GlassType.GT_COMMON then
    local glassInfoDetails = PetMutationUtils.DecodeShineColorId(glass_info)
    local colorA, colorB, strength, particle, starStickTiling
    if glassInfoDetails and glassInfoDetails.glassType == ProtoEnum.GlassType.GT_COMMON and glassInfoDetails.colorInfo then
      local conf = _G.DataConfigManager:GetColorRandomConf(glassInfoDetails.colorInfo.colorId)
      if nil ~= conf then
        colorA = PetMutationUtils.GetShineColor(conf.mat_color_1)
        colorB = PetMutationUtils.GetShineColor(conf.mat_color_2)
        strength = conf.shine_strength
      end
      local particleId = glassInfoDetails.colorInfo.particle
      local particleConf = _G.DataConfigManager:GetParticleRandomConf(particleId)
      if particleConf and PetMutationUtils.IsGlassyRandomEgg(petData) then
        starStickTiling = particleConf.StarStickTiling
      end
      particle = PetMutationUtils.GetShineParticle(PetMutationUtils.GetGeneralParticleKey(particleId))
      if PetMutationUtils.IsGlassyRandomEgg(petData) and 4 == particleId then
        particle = PetMutationUtils.GetShineParticle(PetMutationUtils.GetGeneralEggParticleKey(particleId))
      end
    end
    
    function materialFunc(mat, mesh, idx)
      processMaterial(mat, mesh, idx, colorA, colorB, strength, particle, starStickTiling)
    end
    
    function additionalFunc(additionalMat, mesh, idx)
      processAdditionalMaterial(additionalMat, mesh, idx, colorA, colorB)
    end
  end
  if nil == materialFunc or nil == additionalFunc then
    Log.Debug("PetMutationUtils.SetGlassyDiffMutation materialFunc or additionalFunc is nil")
    return
  end
  local normalMaterial = true
  local suffixes = {"by"}
  for idx = 0, 9 do
    table.insert(suffixes, string.format("by%d", idx))
  end
  if PetMutationUtils.IsGlassyRandomEgg(petData) then
    suffixes = {
      "MI_UI_RandomEgg_003"
    }
    if petData.random_egg_conf then
      local randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(petData.random_egg_conf)
      if randomEggConf then
        local materialName = PetMutationUtils.GetRandomEggMaterialName(randomEggConf.model_mutation_mat)
        if materialName then
          if materialName ~= suffixes[1] then
            normalMaterial = false
          end
          suffixes = {materialName}
        end
      end
    end
  end
  local mesh = character.mesh
  local rocoMaterial = character.RocoMaterial
  if not rocoMaterial or not UE4.UObject.IsValid(rocoMaterial) then
    Log.Warning("PetMutationUtils.SetGlassyDiffMutation rocoMaterial is nil", UE4.UKismetSystemLibrary.GetDisplayName(character))
    return
  end
  local materials
  if not PetMutationUtils.IsGlassyNormalEgg(petData) then
    materials = rocoMaterial:GetMaterialsBySuffixesAsMID(mesh, suffixes)
  else
    materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  end
  if not materials then
    return
  end
  for idx, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      if normalMaterial then
        materialFunc(mat, mesh, idx)
      end
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalFunc(additionalMat, mesh, idx)
        end
      end
    end
  end
end

function PetMutationUtils.SetGlassyDiffMutationForNormalEgg(character, petData)
  local mesh = character.mesh
  local rocoMaterial = character.RocoMaterial
  if not rocoMaterial or not UE4.UObject.IsValid(rocoMaterial) then
    Log.Warning("PetMutationUtils.SetGlassyDiffMutationForNormalEgg rocoMaterial is nil", UE4.UKismetSystemLibrary.GetDisplayName(character))
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  if not materials then
    return
  end
  local curPreciousEggType
  if petData and petData.precious_egg_type then
    curPreciousEggType = petData.precious_egg_type
  end
  if nil == curPreciousEggType and petData and petData.conf_id then
    local PetEggConf = _G.DataConfigManager:GetPetEggConf(petData.conf_id)
    if PetEggConf then
      curPreciousEggType = PetEggConf.precious_egg_type
    end
  end
  for idx, mat in pairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("GlassySwitch", true, mesh, false)
      mat:SetScalarParameterValue("GlassyMainColorOpacity", 1.0)
      mat:SetScalarParameterValue("StarStickTiling", 2.0)
      local starStickTex = PetMutationUtils.GetShineParticle(PetMutationUtils.GetNormalEggKeyStarStickTex())
      if starStickTex then
        mat:SetTextureParameterValue("StarStickTex", starStickTex)
      end
      if curPreciousEggType then
        local additionalMat = PetMutationUtils.GetShineParticle(PetMutationUtils.GetNormalEggKeyModelMat(curPreciousEggType))
        if additionalMat then
          local matInstance = UE4.UKismetMaterialLibrary.CreateDynamicMaterialInstance(character, additionalMat)
          if matInstance then
            mat.AdditionalMaterials:Clear()
            mat.AdditionalMaterials:Add(matInstance)
          end
        end
      end
    end
  end
end

function PetMutationUtils.GetNightmareParameterInfo()
  local nightmareParameterInfo = UE4.FMaterialParameterInfo()
  nightmareParameterInfo.Name = "\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156"
  nightmareParameterInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
  nightmareParameterInfo.Index = 0
  return nightmareParameterInfo
end

function PetMutationUtils.GetNightmareOneParameterInfo()
  local nightmareParameterInfo = UE4.FMaterialParameterInfo()
  nightmareParameterInfo.Name = "\229\188\128\229\144\175\229\153\169\230\162\166\230\174\139\231\149\153\230\149\136\230\158\156"
  nightmareParameterInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
  nightmareParameterInfo.Index = 0
  return nightmareParameterInfo
end

function PetMutationUtils.SetNightmareFirstMutation(character)
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetVectorParameterValue("MainColor", UE4.UNRCStatics.HexToLinearColor("9E50C5FF"))
      mat:SetScalarParameterValue("MainBright", 0.6)
      mat:SetVectorParameterValue("Rim LightColor", UE4.UNRCStatics.HexToLinearColor("FF3AF4FF"))
      mat:SetVectorParameterValue("Rim DarkColor", UE4.UNRCStatics.HexToLinearColor("E01EE5FF"))
      mat:SetScalarParameterValue("Offset Percent", -1.0)
      mat:SetScalarParameterValue("Rim Power", 0.5)
      mat:SetScalarParameterValue("Rim Soft Edge", 1.0)
      mat:SetScalarParameterValue("Rim Intensity", 10.0)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareParameterInfo(), 1.0)
      mat:SetScalarParameterValue("OpenBlackMagicByIDMask", 0)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", true, mesh, false)
        end
      end
    end
  end
end

function PetMutationUtils.SetNightmareByIDMask(character)
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", true, mesh, false)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareParameterInfo(), 1.0)
      mat:SetSwitchParameterValue("\229\188\128\229\144\175\229\153\169\230\162\166\230\174\139\231\149\153\230\149\136\230\158\156", true, mesh, false)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareOneParameterInfo(), 1.0)
      mat:SetScalarParameterValue("OpenBlackMagicByIDMask", 1)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", true, mesh, false)
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\229\153\169\230\162\166\230\174\139\231\149\153\230\149\136\230\158\156", true, mesh, false)
          additionalMat:SetScalarParameterValue("OpenBlackMagicByIDMask", 1)
        end
      end
    end
  end
end

function PetMutationUtils.SetNightmareSecondMutation(character)
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMIDWithClear(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", true, mesh, false)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareParameterInfo(), 1.0)
      mat:SetScalarParameterValue("OpenBlackMagicByIDMask", 0)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", true, mesh, false)
          additionalMat:SetScalarParameterValue("OutlineWidth", 0.2)
        end
      end
    end
  end
end

function PetMutationUtils.RemoveNightmareFirstMutation(character)
  if not character or not UE4.UObject.IsValid(character) then
    return
  end
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  rocoMaterial:ClearMaterials()
end

function PetMutationUtils.RemoveNightmareSecondMutation(character)
  if not character or not UE4.UObject.IsValid(character) then
    return
  end
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMIDWithClear(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", false, mesh, false)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareParameterInfo(), 0.0)
      mat:SetScalarParameterValue("OpenBlackMagicByIDMask", 0)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", false, mesh, false)
        end
      end
    end
  end
end

function PetMutationUtils.RemoveNightmareByIDMask(character)
  if not character or not UE4.UObject.IsValid(character) then
    return
  end
  local rocoMaterial = character.RocoMaterial
  local mesh = character.mesh
  if not UE4.UObject.IsValid(rocoMaterial) or not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = rocoMaterial:GetCurrentMaterialsAsMID(mesh)
  for _, mat in tpairs(materials) do
    if UE4.UObject.IsValid(mat) then
      mat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", false, mesh, false)
      mat:SetScalarParameterValueByInfo(PetMutationUtils.GetNightmareParameterInfo(), 0.0)
      mat:SetScalarParameterValue("OpenBlackMagicByIDMask", 0)
      for _, additionalMat in tpairs(mat.AdditionalMaterials) do
        if UE4.UObject.IsValid(additionalMat) then
          additionalMat:SetSwitchParameterValue("\229\188\128\229\144\175\233\187\145\233\173\148\230\179\149\230\149\136\230\158\156", false, mesh, false)
          additionalMat:SetScalarParameterValue("OpenBlackMagicByIDMask", 0)
        end
      end
    end
  end
end

function PetMutationUtils.TryRemoveNightMareMutation(character, oldPetData, newPetData)
  if not oldPetData or not newPetData then
    return
  end
  if newPetData.blood_id ~= Enum.PetBloodType.PBT_NIGHTMARE then
    local mutation_type = oldPetData.mutation_type
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS) then
      PetMutationUtils.RemoveNightmareFirstMutation(character)
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_TWO) then
      PetMutationUtils.RemoveNightmareSecondMutation(character)
    end
    if PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) then
      PetMutationUtils.RemoveNightmareByIDMask(character)
    end
  end
end

function PetMutationUtils.DoPetEggMutation(egg, eggData)
  if egg and eggData then
    local mutation_type = eggData.mutation_type
    if eggData.random_egg_conf then
      local randomEggConf = _G.DataConfigManager:GetPetRandomEggConf(eggData.random_egg_conf)
      if randomEggConf and randomEggConf.model_mutation_mat then
        if egg.MaterialMap:Find(randomEggConf.model_mutation_mat) then
          egg:ChangeMaterial(randomEggConf.model_mutation_mat)
          PetMutationUtils.SetRandomEggExtraEffect(egg, eggData, randomEggConf)
        else
          PetMutationUtils.DoSpecialPetEggMutation(egg, eggData, randomEggConf)
        end
      end
    elseif PetMutationUtils.CheckIsCustomGlassEgg(eggData) then
      PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.NormalEgg)
      PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
    elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
      PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.NormalEgg)
      PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
    elseif eggData then
      local CurPreciousEggType
      if nil == CurPreciousEggType then
        CurPreciousEggType = eggData.precious_egg_type
      end
      if nil == CurPreciousEggType and eggData.conf_id then
        local PetEggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
        if PetEggConf then
          CurPreciousEggType = PetEggConf.precious_egg_type
        end
      end
      if CurPreciousEggType then
        local PetEggTypeConf = _G.DataConfigManager:GetEggTypeConf(CurPreciousEggType + 1)
        if PetEggTypeConf and PetEggTypeConf.icon_tex then
          PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.NormalEgg)
          PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
        end
      end
    end
  end
end

function PetMutationUtils.GetRandomEggMaterialName(assetPath)
  if not assetPath or "" == assetPath then
    return nil
  end
  local fileName = assetPath:match("[^/]+$")
  if not fileName then
    return nil
  end
  return fileName:match("^([^%.]+)")
end

function PetMutationUtils.SetRandomEggExtraEffect(egg, eggData, randomEggConf)
  if egg and eggData and randomEggConf then
    local normalEgg = randomEggConf.mutation_type ~= _G.Enum.MutationDiffType.MDT_GLASS
    local mutation_type = eggData.mutation_type
    local glass_info = eggData.glass_info
    if mutation_type then
      if glass_info and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) then
        PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.RandomEgg)
        PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
      elseif PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_CHAOS_THREE) and egg then
        PetMutationUtils.SetNightmareByIDMask(egg)
      end
    end
    local materials
    if not normalEgg then
      local materialName = PetMutationUtils.GetRandomEggMaterialName(randomEggConf.model_mutation_mat)
      if materialName then
        local suffixes = {materialName}
        materials = egg.RocoMaterial:GetMaterialsBySuffixesAsMID(egg.mesh, suffixes)
      end
    end
    
    local function OnSetOutline(asset)
      if materials then
        for _, mat in tpairs(materials) do
          if UE4.UObject.IsValid(mat) then
            for _, additionalMat in tpairs(mat.AdditionalMaterials) do
              if UE4.UObject.IsValid(additionalMat) then
                local GlassInfo = UE4.FMaterialParameterInfo()
                GlassInfo.Name = "RampTex"
                GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
                GlassInfo.Index = 1
                additionalMat:SetTextureParameterValueByInfo(GlassInfo, asset)
                GlassInfo.Name = "OpenFlowColor"
                additionalMat:SetScalarParameterValueByInfo(GlassInfo, 1)
              end
            end
          end
        end
      end
    end
    
    local markTexPath = randomEggConf.model_mark_tex
    if markTexPath and "" ~= markTexPath then
      local texture = PetMutationUtils.GetShineParticle(PetMutationUtils.GetRandomEggKeyModelMarkTex(randomEggConf.id))
      if texture and UE4.UObject.IsValid(texture) then
        local material = egg.mesh:GetMaterial(0)
        if UE4.UObject.IsValid(material) and not normalEgg then
          local GlassInfo = UE4.FMaterialParameterInfo()
          GlassInfo.Name = "RampTex"
          GlassInfo.Association = UE4.EMaterialParameterAssociation.LayerParameter
          GlassInfo.Index = 2
          material:SetTextureParameterValueByInfo(GlassInfo, texture)
        end
        if not glass_info and not mutation_type then
          OnSetOutline(texture)
        end
      end
    end
    if mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_GLASS) and glass_info and glass_info.glass_value then
      local value = glass_info.glass_value
      value = value & 1048575
      value = value >> 0
      if 0 == value then
        local texture = PetMutationUtils.GetShineParticle(PetMutationUtils.GetRandomEggKeyOutline())
        if texture and UE4.UObject.IsValid(texture) then
          OnSetOutline(texture)
        end
      end
    end
  end
end

function PetMutationUtils.DoSpecialPetEggMutation(egg, eggData, randomEggConf)
  if egg and eggData and randomEggConf then
    local function onLoadMaterialSucceed(caller, req, asset)
      if asset then
        egg.Mesh:SetMaterial(0, asset)
        
        PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.RandomEgg)
        PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
        PetMutationUtils.SetRandomEggExtraEffect(egg, eggData, randomEggConf)
      elseif eggData then
        local CurPreciousEggType
        if nil == CurPreciousEggType then
          CurPreciousEggType = eggData.precious_egg_type
        end
        if nil == CurPreciousEggType and eggData.conf_id then
          local PetEggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
          if PetEggConf then
            CurPreciousEggType = PetEggConf.precious_egg_type
          end
        end
        if CurPreciousEggType then
          local PetEggTypeConf = _G.DataConfigManager:GetEggTypeConf(CurPreciousEggType + 1)
          if PetEggTypeConf and PetEggTypeConf.icon_tex then
            PetMutationUtils.SetPetDataGlassActorType(eggData, PetMutationUtils.GlassActorType.NormalEgg)
            PetMutationUtils.SetGlassyDiffMutation(egg, eggData)
          end
        end
      end
    end
    
    if randomEggConf.model_mutation_mat then
      _G.NRCResourceManager:LoadResAsync(egg, randomEggConf.model_mutation_mat, PriorityEnum.Active_World_NPC_Mutation, 10, onLoadMaterialSucceed)
    end
  end
end

function PetMutationUtils.CheckIsCustomGlassEgg(eggData)
  local isCustomGlassEgg = false
  if not eggData then
    return isCustomGlassEgg
  end
  if not eggData.conf_id then
    return isCustomGlassEgg
  end
  local PetEggConf = _G.DataConfigManager:GetPetEggConf(eggData.conf_id)
  if PetEggConf and PetEggConf.precious_egg_type == _G.Enum.PreciousEggType.PET_CUSTOM_GLASS then
    isCustomGlassEgg = true
  end
  return isCustomGlassEgg
end

return PetMutationUtils
