local fromBag, fromBagDirection, fromSlot, fromSlotDirection, strategy, toBag, toBagDirection, toSlot, toSlotDirection

function Compact(arg)
  BagCompactorFrame:Show()

  local back = string.find(arg, 'back')

  strategy = GetStrategy(arg)

  fromBagDirection, fromSlotDirection, toBagDirection, toSlotDirection = strategy.getDirection(back)

  fromBag, fromSlot = GetStartSlot(fromBagDirection, fromSlotDirection)
  toBag, toSlot = GetStartSlot(toBagDirection, toSlotDirection)
end

function Move()
  while true do
    while true do
      local texture, _, locked = GetContainerItemInfo(toBag, toSlot)

      if texture then
        if locked then return else SetNextToSlot() end
      else
        break 
      end
    end

    while not strategy.complete() and (not SlotHasMoveableItem(fromBag, fromSlot) or not strategy.isValidMove(fromBag, fromSlot, toBag, toSlot)) do
      SetNextFromSlot()
    end

    if strategy.complete() then
      BagCompactorFrame:Hide()
      return
    end

    PickupContainerItem(fromBag, fromSlot)
    PickupContainerItem(toBag, toSlot)

    SetNextFromSlot()
    SetNextToSlot()
  end
end

SLASH_COMPACT1 = "/compact"

SlashCmdList["COMPACT"] = Compact

local ASCENDING = 1
local DESCENDING = -ASCENDING

local FIRST_CONTAINER = 0
local LAST_CONTAINER = 10

local FIRST_SLOT = 1

-- Compacts in the fewest moves possible with no regard to the order of items.
local InvertStrategy = {
  complete = function()
    if fromBag == nil or toBag == nil then return true
    elseif fromBagDirection == ASCENDING then return fromBag > toBag or fromBag == toBag and fromSlot >= toSlot
    else return fromBag < toBag or fromBag == toBag and fromSlot <= toSlot
    end
  end,
  getDirection = function(back)
    if back then
      return ASCENDING, ASCENDING, DESCENDING, DESCENDING
    else
      return DESCENDING, DESCENDING, ASCENDING, ASCENDING
    end
  end,
  isValidMove = function(fromBag, fromSlot, toBag, toSlot)
    if fromBagDirection == ASCENDING then
      return fromBag < toBag or fromBag == toBag and fromSlot < toSlot
    else
      return fromBag > toBag or fromBag == toBag and fromSlot > toSlot
    end
  end
}

-- Preserves the natural order of items, i.e. the order in which items are placed when looting.
local SlideStrategy = {
  complete = function()
    return fromBag == nil or toBag == nil
  end,
  getDirection = function(back)
    if back then
      return DESCENDING, DESCENDING, DESCENDING, DESCENDING
    else
      return ASCENDING, ASCENDING, ASCENDING, ASCENDING
    end
  end,
  isValidMove = function(fromBag, fromSlot, toBag, toSlot)
    if fromBagDirection == ASCENDING then
      return fromBag > toBag or fromBag == toBag and fromSlot > toSlot
    else
      return fromBag < toBag or fromBag == toBag and fromSlot < toSlot
    end
  end
}

-- Preserves the visual order of items within each bag, left-to-right and top-to-bottom.
local SlideVisualStrategy = {
  complete = SlideStrategy.complete,
  getDirection = function(back)
    if back then
      return DESCENDING, ASCENDING, DESCENDING, ASCENDING
    else
      return ASCENDING, DESCENDING, ASCENDING, DESCENDING
    end
  end,
  isValidMove = function(fromBag, fromSlot, toBag, toSlot)
    if fromBag ~= toBag then
      if fromBagDirection == ASCENDING then return fromBag > toBag else return fromBag < toBag end
    end

    if fromSlotDirection == ASCENDING then return fromSlot > toSlot else return fromSlot < toSlot end
  end
}

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

function GetStrategy(arg)
  if string.find(arg, 'slide') and string.find(arg, 'visual') then return SlideVisualStrategy
  elseif string.find(arg, 'slide') then return SlideStrategy
  else return InvertStrategy
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
    if bagID == 0 or GetContainerNumSlots(bagID) == 0 then
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
