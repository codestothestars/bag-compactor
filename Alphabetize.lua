-- Orders items naturally, i.e. the order in which items are placed when looting.
local LogicalStrategy = {
  getDirection = function(back)
    if back then
      return DESCENDING, DESCENDING, DESCENDING, DESCENDING
    else
      return ASCENDING, ASCENDING, ASCENDING, ASCENDING
    end
  end
}

-- Orders items visually, left-to-right and top-to-bottom.
local VisualStrategy = {
  getDirection = function(back)
    if back then
      return ASCENDING, DESCENDING, ASCENDING, DESCENDING
    else
      return DESCENDING, ASCENDING, DESCENDING, ASCENDING
    end
  end
}

function GetAlphabetizeStrategy(arg)
  local strategy

  if string.find(arg, 'visual') then strategy = VisualStrategy
  else strategy = LogicalStrategy
  end

  strategy.isValidMove = function(state)
    local fromItemName = GetItemNameFromLink(GetContainerItemLink(state.fromBag, state.fromSlot))

    for bag, slot in IterateSubsequentSlots(
      state.fromBag,
      state.fromSlot,
      state.fromBagDirection,
      state.fromSlotDirection
    ) do
      local itemLink = GetContainerItemLink(bag, slot)
      if itemLink and GetItemNameFromLink(itemLink) < fromItemName then return false end
    end

    return true
  end

  strategy.intervalSeconds = .1
  strategy.iterative = true

  return strategy
end
