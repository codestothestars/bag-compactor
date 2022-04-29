local fromBag, fromBagDirection, fromSlot, fromSlotDirection, toBag, toBagDirection, toSlot, toSlotDirection

function Compact(arg)
  BagCompactorFrame:Show()

  fromBagDirection, fromSlotDirection, toBagDirection, toSlotDirection = GetDirection(arg)

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

    while not Complete() and (not SlotHasMoveableItem(fromBag, fromSlot) or not IsValidMove(fromBag, fromSlot, toBag, toSlot)) do
      SetNextFromSlot()
    end

    if Complete() then
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

function Complete()
  if fromBag == nil or toBag == nil then return true
  elseif fromBagDirection == ASCENDING then return fromBag > toBag or fromBag == toBag and fromSlot >= toSlot
  else return fromBag < toBag or fromBag == toBag and fromSlot <= toSlot
  end
end

function GetDirection(arg)
  if string.find(arg, 'back') then
    return ASCENDING, ASCENDING, DESCENDING, DESCENDING
  else
    return DESCENDING, DESCENDING, ASCENDING, ASCENDING
  end
end
function IsValidMove(fromBag, fromSlot, toBag, toSlot)
  if fromBagDirection == ASCENDING then
    return fromBag < toBag or fromBag == toBag and fromSlot < toSlot
  else
    return fromBag > toBag or fromBag == toBag and fromSlot > toSlot
  end
end

function GetFirstSlot(bag, direction)
  if direction == ASCENDING then return 1 else return GetContainerNumSlots(bag) end
end

function GetLastBag(direction)
  if direction == ASCENDING then return 4 else return 0 end
end

function GetLastSlot(bag, direction)
  if direction == ASCENDING then return GetContainerNumSlots(bag) else return 1 end
end

function GetNextSlot(bag, slot, bagDirection, slotDirection)
  if slot ~= GetLastSlot(bag, slotDirection) then return bag, slot + slotDirection end

  for nextBag = bag + bagDirection, GetLastBag(bagDirection), bagDirection do
    local _, special = GetContainerNumFreeSlots(nextBag)

    if not special then return nextBag, GetFirstSlot(nextBag, slotDirection) end
  end
end

function GetStartBag(direction)
  if direction == ASCENDING then return 0 else return 4 end
end

function GetStartSlot(bagDirection, slotDirection)
  local bag = GetStartBag(bagDirection)

  function GetSlot()
    if slotDirection == ASCENDING then return 1 else return GetContainerNumSlots(bag) end
  end

  return bag, GetSlot()
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

    for i = 1, GetContainerNumSlots(bagID) do
      if GetContainerItemInfo(bagID, i) == nil then
        numFreeSlots = numFreeSlots + 1
      end
    end

    return numFreeSlots, IsSpecialBag(bagID)
  end
end
