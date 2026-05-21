local MultiTouchModuleData = _G.NRCData:Extend("MultiTouchModuleData")

function MultiTouchModuleData:Ctor()
  NRCData.Ctor(self)
  self.enableTouchMask = false
  self.defaultTouchLimit = 4
  self.mainTouchLimit = 4
  self.singleTouchLimit = 1
  self.disableTouchLimit = 0
  self.joystickTouchLimit = 2
  self.touchInputLimit = 1
  self.revertTime = 0.5
  self.revertTimer = 0
  self.panelStack = {}
  self.addPanelTypeList = {}
  self.isOpenPetPanel = false
  self.panelSelectBtnReason = {
    LobbyMain = {
      PETITEM = 0,
      COMPASS = 1,
      ACTIVITY = 2,
      MAGICMANUA = 3,
      PET = 4,
      BOOK = 5,
      PASS = 6,
      CHAT = 7,
      MINIGAME = 8,
      TEAMBATTLE = 9,
      DIALOG = 10,
      TASKITEM = 11,
      THROW = 12,
      MAGIC = 13,
      ROLEPLAYER = 14,
      MAP = 15,
      NEWPET = 16,
      PROJECTTASK = 17,
      SEEDBAG = 18,
      TASK = 19,
      PETCARE = 20
    },
    BattlePassAwardMain = {
      CHANGETEAM = 0,
      UNLOCK = 1,
      PET = 2,
      TAB = 3,
      INFO = 4,
      UPGRADE = 5,
      TIPS = 6,
      GET = 7,
      TICKET = 8,
      CLOSE = 9
    },
    PetEvoNewPanel = {EVOLUTIONCONFIRM = 0, CLOSE = 1},
    PetHatchingPanel = {
      EGGITEM = 0,
      EGGBTN = 1,
      EGGOUT = 2,
      BACKBTN = 3,
      HATCHEGG = 4
    },
    AlternateMaterial = {
      Confirm = 0,
      CANCEL = 1,
      ITEM = 2
    },
    UMG_StarChainAward = {
      CANCEL = 0,
      CONFIRM = 1,
      MONEYTIMECLICK = 2,
      TIPSITEM = 3
    },
    MainBigMap = {
      GETALL = 0,
      SWITCH = 1,
      TELEPORT = 2
    },
    Friend = {
      VISIT = 0,
      CLOSE = 1,
      VISITSET = 2,
      BLACKLIST = 3,
      MESSAGE = 4,
      WORLD = 5,
      ADDFRIEND = 6,
      STARTVISIT = 7,
      ACCEPT = 8,
      DELETE = 9,
      WATCH = 10,
      QQINVITE = 11
    },
    EggIncubatePanel = {
      DAZZLING = 0,
      PETTIPS = 1,
      PETCOLLECT = 2,
      PETBLOOD = 3,
      RATE = 4,
      CLOSE = 5
    },
    BagBlood = {
      PETTIPS = 0,
      SKILLTIPS = 1,
      CANCEL = 2,
      OK = 3
    },
    UMG_GiftVoucherSharing = {SHARE = 0, CLOSE = 1},
    PetBox = {
      SUBPANEL = 0,
      OPEN = 1,
      CLOSE = 2,
      EVO = 3
    },
    PetInfoMain = {LEFTPANELOPEN = 0, PETUPGRADEOPEN = 1}
  }
  self.lastTimeTouchNRCButton = os.msTime()
  self.nrcButtonCoolDownTime = 100
  self.specialSelectLimit = {
    SelectLimit1 = {
      flag = 0,
      reason = {THROW = 1, GANZHI = 2}
    }
  }
end

return MultiTouchModuleData
