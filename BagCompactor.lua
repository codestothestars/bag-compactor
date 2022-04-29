local direction, fromBag, fromSlot, toBag, toSlot

function Compact(arg)
  BagCompactorFrame:Show()

  direction = GetDirection(arg)

  fromBag, fromSlot = GetStartSlot(direction)
  toBag, toSlot = GetStartSlot(-direction)
end

function Move()
  while true do
    fromBag, fromSlot = GetNextSlot(fromBag, fromSlot, toBag, direction, ValidFromSlot)

    if Complete() then
      BagCompactorFrame:Hide()
      return
    end

    toBag, toSlot = GetNextSlot(toBag, toSlot, fromBag, -direction, ValidToSlot)

    if Complete() then
      BagCompactorFrame:Hide()
      return
    end

    PickupContainerItem(fromBag, fromSlot)
    PickupContainerItem(toBag, toSlot)
  end
end

SLASH_COMPACT1 = "/compact"

SlashCmdList["COMPACT"] = Compact

local ASCENDING = 1
local DESCENDING = -ASCENDING

function Complete()
  if fromBag == nil or toBag == nil then return true
  elseif direction == ASCENDING then return fromBag > toBag or fromBag == toBag and fromSlot >= toSlot
  else return fromBag < toBag or fromBag == toBag and fromSlot <= toSlot
  end
end

function GetDirection(arg)
  if string.find(arg, 'back') then return ASCENDING else return DESCENDING end
end

function GetFirstSlot(bag, direction)
  if direction == ASCENDING then return 1 else return GetContainerNumSlots(bag) end
end

function GetLastSlot(bag, direction)
  if direction == ASCENDING then return GetContainerNumSlots(bag) else return 1 end
end

function GetNextSlot(fromBag, fromSlot, toBag, direction, filter)
  for bag = fromBag, toBag, direction do
    local _, special = GetContainerNumFreeSlots(bag)

    if not special then
      for slot = fromSlot + direction, GetLastSlot(bag, direction), direction do
        local texture, _, locked = GetContainerItemInfo(bag, slot)

        if filter(texture, locked) then return bag, slot end
      end

      fromSlot = GetFirstSlot(bag + direction, direction) - direction
    end
  end
end

function GetStartSlot(direction)
  function GetBag()
    if direction == ASCENDING then return 0 else return 4 end
  end

  local bag = GetBag()

  function GetSlot()
    if direction == ASCENDING then return 0 else return GetContainerNumSlots(bag) + 1 end
  end

  return bag, GetSlot()
end

function ValidFromSlot(texture, locked)
  return texture and not locked
end

function ValidToSlot(texture)
  return not texture
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

    for i = 1, GetContainerNumSlots(bagID) do
      if GetContainerItemInfo(bagID, i) == nil then
        numFreeSlots = numFreeSlots + 1
      end
    end

    return numFreeSlots, IsSpecialBag(bagID)
  end
end
