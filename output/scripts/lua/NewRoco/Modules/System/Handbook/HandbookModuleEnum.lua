local HandbookModuleEnum = {}
HandbookModuleEnum.District = {
  Nature = 0,
  Talent = 1,
  Blood = 2,
  Skill = 3
}
HandbookModuleEnum.DistrictDesc = {
  [HandbookModuleEnum.District.Nature] = LuaText.Pet_Recommend_titile_nature,
  [HandbookModuleEnum.District.Talent] = LuaText.Pet_Recommend_titile_talent,
  [HandbookModuleEnum.District.Blood] = LuaText.Pet_Recommend_titile_blood,
  [HandbookModuleEnum.District.Skill] = LuaText.Pet_Recommend_titile_skill
}
HandbookModuleEnum.RedPointType = {
  CollectedRed = 0,
  TopicRed = 1,
  NumberRed = 2
}
HandbookModuleEnum.UIEditorOperationType = {
  is_display_shadow = 0,
  shadow_horizontal_flip_data = 1,
  shadow_vertical_flip_data = 2,
  shadow_ui_percentage = 3,
  shadow_offset = 4,
  shadow_angle = 5,
  shadow_opacity = 6
}
HandbookModuleEnum.UIEditorAxialType = {XAxial = 0, YAxial = 1}
HandbookModuleEnum.SeasonHandbookAwardState = {
  NotReached = 0,
  NotClaimed = 1,
  Claimed = 2
}
HandbookModuleEnum.SeasonHandbookTable = {Handbook = 0, Photo = 1}
return HandbookModuleEnum
