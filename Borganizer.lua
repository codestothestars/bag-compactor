local fromBag,
  fromBagDirection,
  fromSlot,
  fromSlotDirection,
  intervalSeconds,
  lastMoveTime,
  strategy,
  toBag,
  toBagDirection,
  toSlot,
  toSlotDirection,
  waitingForMove,
  waitingToMove

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

  intervalSeconds = strategy.intervalSeconds or 0
  lastMoveTime = 0
  waitingForMove = false
  waitingToMove = false
end

function Move()
  if waitingToMove then TryMoveItem() end

  while true do
    if waitingForMove then
      TryAdvanceCursors()

      if waitingForMove then return end
    end

    if waitingToMove then return end

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

    TryMoveItem()
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

function TryAdvanceCursors()
  if strategy.iterative then
    local _, _, fromLocked = GetContainerItemInfo(fromBag, fromSlot)
    local _, _, toLocked = GetContainerItemInfo(toBag, toSlot)

    waitingForMove = fromLocked or toLocked
  end

  if not waitingForMove then
    if strategy.iterative then
      fromBag = toBag
      fromSlot = toSlot
    end

    SetNextFromSlot()
    SetNextToSlot()
  end
end

function MoveItem()
  PickupContainerItem(fromBag, fromSlot)
  PickupContainerItem(toBag, toSlot)

  lastMoveTime = GetTime()
end

function TryMoveItem()
  waitingToMove = (GetTime() - lastMoveTime) < intervalSeconds
  if not waitingToMove then
    if fromBag ~= toBag or fromSlot ~= toSlot then MoveItem() end

    TryAdvanceCursors()
  end
end

function GetItemNameFromLink(itemLink)
  return string.sub(itemLink, string.find(itemLink, '%[') + 1, string.find(itemLink, ']') - 1)
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
  if string.find(arg, 'alpha') then return GetAlphabetizeStrategy(arg)
  elseif string.find(arg, 'compact') then return GetCompactStrategy(arg)
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

function IterateSubsequentSlots(bag, slot, bagDirection, slotDirection)
  return function()
    bag, slot = GetNextSlot(bag, slot, bagDirection, slotDirection)

    if bag ~= nil and slot ~= nil then return bag, slot end
  end
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
    return GetItemNameFromLink(GetInventoryItemLink("player", slotID))
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
GetContainerItemLink = AdjustBagArgument(GetContainerItemLink)
GetContainerNumFreeSlots = AdjustBagArgument(GetContainerNumFreeSlots)
PickupContainerItem = AdjustBagArgument(PickupContainerItem)

GetContainerNumSlotsOriginal = GetContainerNumSlots

GetContainerNumSlots = function(bag)
  if bag == BANK_LOGICAL then
    if pcall(CanUseBank) then bag = BANK_REAL else return 0 end
  end
  
  return GetContainerNumSlotsOriginal(bag)
end
