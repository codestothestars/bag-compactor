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
    local link = GetInventoryItemLink('player', slotID)

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

    return numFreeSlots, IsSpecialBag(bagID) and 1 or 0
  end
end

function Compact(arg)
  local currentBagFrom, currentSlotFrom, currentBagTo, currentSlotTo, numSlots, numFreeSlots, bagType

  if arg == 'back' then
    currentBagFrom, currentSlotFrom, currentBagTo, currentSlotTo = 0, 1, 4, 0
  else
    currentBagFrom, currentSlotFrom, currentBagTo, currentSlotTo = 4, 0, 0, 1
  end

  numSlots, numFreeSlots, specialBag = {}, {}, {}

  --Loop that establishes the numbers of slots and free slots in each bag, as well as the bag type of each bag, to be kept track of for the duration of the function.
  for i = 0, 4 do
    local freeSlots, type = GetContainerNumFreeSlots(i)

    numSlots[i] = GetContainerNumSlots(i)
    numFreeSlots[i] = freeSlots
    specialBag[i] = type > 0
  end

  if arg == 'back' then
    currentSlotTo = numSlots[currentBagTo]
  else
    currentSlotFrom = numSlots[currentBagFrom]
  end

  --Primary loop that will terminate when currentSlotFrom and currentSlotTo have passed each other.
  while true do
    local compactionComplete = 0

    --Select the proper currentBagFrom.
    while true do
      if numFreeSlots[currentBagFrom] == numSlots[currentBagFrom] or specialBag[currentBagFrom] or numSlots[currentBagFrom] == 0 then
        if arg == 'back' then
          currentBagFrom = currentBagFrom + 1
          currentSlotFrom = 1

          if currentBagFrom > currentBagTo then
            compactionComplete = 1

            break
          end
        else
          currentBagFrom = currentBagFrom - 1
          currentSlotFrom = numSlots[currentBagFrom]

          if currentBagFrom < currentBagTo then
            compactionComplete = 1

            break
          end
        end
      else
        break
      end
    end

    if compactionComplete == 1 then
      break
    end

    --Select the proper currentSlotFrom.
    while true do
      local texture, _, locked = GetContainerItemInfo(currentBagFrom, currentSlotFrom)

      if texture == nil or locked == 1 then
        if arg == 'back' then
          currentSlotFrom = currentSlotFrom + 1
        else
          currentSlotFrom = currentSlotFrom - 1
        end

        if locked == 1 then
          numFreeSlots[currentBagFrom] = numFreeSlots[currentBagFrom] + 1
        end

        if arg == 'back' then
          if currentBagFrom == currentBagTo and currentSlotFrom >= currentSlotTo then
            compactionComplete = 1

            break
          end
        else
          if currentBagFrom == currentBagTo and currentSlotFrom <= currentSlotTo then
            compactionComplete = 1

            break
          end
        end

        if arg == 'back' then
          if currentSlotFrom > numSlots[currentBagFrom] then
            while true do
              if numFreeSlots[currentBagFrom] == numSlots[currentBagFrom] or specialBag[currentBagFrom] or numSlots[currentBagFrom] == 0 then
                currentBagFrom = currentBagFrom + 1
                currentSlotFrom = 1

                if currentBagFrom > currentBagTo then
                  compactionComplete = 1

                  break
                end
              else
                break
              end
            end

            if compactionComplete == 1 then
              break
            end
          end
        else
          if currentSlotFrom < 1 then
            while true do
              if numFreeSlots[currentBagFrom] == numSlots[currentBagFrom] or specialBag[currentBagFrom] or numSlots[currentBagFrom] == 0 then
                currentBagFrom = currentBagFrom - 1
                currentSlotFrom = numSlots[currentBagFrom]

                if currentBagFrom < currentBagTo then
                  compactionComplete = 1

                  break
                end
              else
                break
              end
            end
            if compactionComplete == 1 then
              break
            end
          end
        end
      else
        break
      end
    end

    if compactionComplete == 1 then
      break
    end

    --Select the proper currentBagTo
    while true do
      if numFreeSlots[currentBagTo] == 0 or specialBag[currentBagTo] or numSlots[currentBagTo] == 0 then
        if arg == 'back' then
          currentBagTo = currentBagTo - 1
          currentSlotTo = numSlots[currentBagTo]

          if currentBagTo < currentBagFrom then
            compactionComplete = 1

            break
          end
        else
          currentBagTo = currentBagTo + 1
          currentSlotTo = 1

          if currentBagTo > currentBagFrom then
            compactionComplete = 1

            break
          end
        end
      else
        break
      end
    end

    if compactionComplete == 1 then
      break
    end

    --Select the proper currentSlotTo
    while true do
      if GetContainerItemInfo(currentBagTo, currentSlotTo) == nil then
        break
      else
        if arg == 'back' then
          currentSlotTo = currentSlotTo - 1

          if currentBagTo == currentBagFrom and currentSlotTo <= currentSlotFrom then
            compactionComplete = 1

            break
          end

          if currentSlotTo < 1 then
            while true do
              if numFreeSlots[currentBagTo] == 0 or specialBag[currentBagTo] then
                currentBagTo = currentBagTo - 1
                currentSlotTo = numSlots[currentBagTo]

                if currentBagTo < currentBagFrom then
                  compactionComplete = 1

                  break
                end
              else
                break
              end
            end

            if compactionComplete == 1 then
              break
            end
          end
        else
          currentSlotTo = currentSlotTo + 1

          if currentBagTo == currentBagFrom and currentSlotTo >= currentSlotFrom then
            compactionComplete = 1

            break
          end

          if currentSlotTo > numSlots[currentBagTo] then
            while true do
              if numFreeSlots[currentBagTo] == 0 or specialBag[currentBagTo] then
                currentBagTo = currentBagTo + 1
                currentSlotTo = 1

                if currentBagTo > currentBagFrom then
                  compactionComplete = 1

                  break
                end
              else
                break
              end
            end

            if compactionComplete == 1 then
              break
            end
          end
        end
      end
    end

    if compactionComplete == 1 then
      break
    end

    --Move the item from slot currentSlotFrom of bag currentBagFrom to slot currentSlotTo of bag currentBagTo.
    PickupContainerItem(currentBagFrom, currentSlotFrom)
    PickupContainerItem(currentBagTo, currentSlotTo)

    numFreeSlots[currentBagFrom] = numFreeSlots[currentBagFrom] + 1
    numFreeSlots[currentBagTo] = numFreeSlots[currentBagTo] - 1

    if arg == 'back' then
      currentSlotFrom = currentSlotFrom + 1
      currentSlotTo = currentSlotTo - 1
    else
      currentSlotFrom = currentSlotFrom - 1
      currentSlotTo = currentSlotTo + 1
    end
  end
end

SLASH_COMPACT1 = '/compact'

SlashCmdList['COMPACT'] = Compact
