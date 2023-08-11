local fromBag, fromBagDirection, fromSlot, fromSlotDirection, strategy, toBag, toBagDirection, toSlot, toSlotDirection

function Borg(arg)
  BorganizerFrame:Show()

  local back = string.find(arg, 'back')

  strategy = GetStrategy(arg)

  if not strategy then
    BorganizerFrame:Hide()
  end
  
  fromBagDirection, fromSlotDirection, toBagDirection, toSlotDirection = strategy.getDirection(back)

  fromBag, fromSlot = GetStartSlot(fromBagDirection, fromSlotDirection)
  toBag, toSlot = GetStartSlot(toBagDirection, toSlotDirection)
end

function Move()
  while true do
    while not IsComplete() do
      local texture, _, locked = GetContainerItemInfo(toBag, toSlot)

      if locked then return
      elseif not strategy.isValidToSlot or strategy.isValidToSlot(texture) then break
      else SetNextToSlot()
      end
    end

    while not IsComplete() and (not SlotHasMoveableItem(fromBag, fromSlot) or not strategy.isValidMove(GetState())) do
      SetNextFromSlot()
    end

    if IsComplete() then
      BorganizerFrame:Hide()
      return
    end

    PickupContainerItem(fromBag, fromSlot)
    PickupContainerItem(toBag, toSlot)

    SetNextFromSlot()
    SetNextToSlot()
  end
end

SLASH_BORG1 = "/borg"

SlashCmdList["BORG"] = Borg

ASCENDING = 1
DESCENDING = -ASCENDING

-- The client actually uses -1, but we treat the bank as the highest for
-- logical consistency and do a conversion with AdjustBagArgument.
local BANK_LOGICAL = 11
local BANK_REAL = -1

local FIRST_CONTAINER = 0
local LAST_CONTAINER = BANK_LOGICAL

local FIRST_SLOT = 1

function AdjustBagArgument(func)
  return function(bag, ...)
    if bag == BANK_LOGICAL then return func(BANK_REAL, unpack(arg)) else return func(bag, unpack(arg)) end
  end
end

function CanUseBank()
  return GetInventoryItemName(ContainerIDToInventoryID(5)) -- First bank bag.
end

function IsComplete()
  return fromBag == nil or toBag == nil or (strategy.complete and strategy.complete(GetState()))
end

function GetFirstBag(direction)
  if direction == ASCENDING then return FIRST_CONTAINER else return LAST_CONTAINER end
end

function GetFirstSlot(bag, direction)
  if direction == ASCENDING then return FIRST_SLOT else return GetContainerNumSlots(bag) end
end

function GetLastBag(direction)
  return GetFirstBag(-direction)
end

function GetLastSlot(bag, direction)
  return GetFirstSlot(bag, -direction)
end

function GetNextSlot(bag, slot, bagDirection, slotDirection)
  if slot ~= GetLastSlot(bag, slotDirection) then return bag, slot + slotDirection end

  for nextBag in IterateBags(bag + bagDirection, bagDirection) do
    local _, special = GetContainerNumFreeSlots(nextBag)

    if not special then return nextBag, GetFirstSlot(nextBag, slotDirection) end
  end
end

function GetStartSlot(bagDirection, slotDirection)
  for bag in IterateBags(GetFirstBag(bagDirection), bagDirection) do return bag, GetFirstSlot(bag, slotDirection) end
end

function GetState()
  return {
    fromBag = fromBag,
    fromBagDirection = fromBagDirection,
    fromSlot = fromSlot,
    fromSlotDirection = fromSlotDirection,
    toBag = toBag,
    toSlot = toSlot
  }
end

function GetStrategy(arg)
  if string.find(arg, 'compact') then return GetCompactStrategy(arg)
  end
end

function IterateBags(start, direction)
  return function()
    for bag = start, GetLastBag(direction), direction do
      start = start + direction
      if GetContainerNumSlots(bag) > 0 then return bag end
    end
  end
end

function SetNextFromSlot()
  fromBag, fromSlot = GetNextSlot(fromBag, fromSlot, fromBagDirection, fromSlotDirection)
end

function SetNextToSlot()
  toBag, toSlot = GetNextSlot(toBag, toSlot, toBagDirection, toSlotDirection)
end

function SlotHasMoveableItem(bag, slot)
  local texture, _, locked = GetContainerItemInfo(bag, slot)
  return texture and not locked
end

-- Polyfill GetContainerNumFreeSlots
if GetContainerNumFreeSlots == nil then
  local specialBags = {
    'Big Bag of Enchantment',
    'Cenarion Herb Bag',
    'Enchanted Mageweave Pouch',
    'Enchanted Runecloth Bag',
    'Herb Pouch',
    'Mining Sack',
    'Satchel of Cenarius'
  }

  function GetInventoryItemName(slotID)
    local link = GetInventoryItemLink("player", slotID)

    return string.sub(link, string.find(link, '%[') + 1, string.find(link, ']') - 1)
  end

  function IsSpecialBag(bagID)
    if bagID < 1 or GetContainerNumSlots(bagID) == 0 then
      return false
    end

    local bagName = GetInventoryItemName(ContainerIDToInventoryID(bagID))

    for index, specialBagName in ipairs(specialBags) do
      if bagName == specialBagName then
        return true
      end
    end

    return false
  end

  function GetContainerNumFreeSlots(bagID)
    local numFreeSlots = 0

    for i = FIRST_SLOT, GetContainerNumSlots(bagID) do
      if GetContainerItemInfo(bagID, i) == nil then
        numFreeSlots = numFreeSlots + 1
      end
    end

    return numFreeSlots, IsSpecialBag(bagID)
  end
end

GetContainerItemInfo = AdjustBagArgument(GetContainerItemInfo)
GetContainerNumFreeSlots = AdjustBagArgument(GetContainerNumFreeSlots)
PickupContainerItem = AdjustBagArgument(PickupContainerItem)

GetContainerNumSlotsOriginal = GetContainerNumSlots

GetContainerNumSlots = function(bag)
  if bag == BANK_LOGICAL then
    if pcall(CanUseBank) then bag = BANK_REAL else return 0 end
  end
  
  return GetContainerNumSlotsOriginal(bag)
end
