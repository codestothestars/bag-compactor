-- Compacts in the fewest moves possible with no regard to the order of items.
local InvertStrategy = {
  complete = function(state)
    if state.fromBagDirection == ASCENDING then
      return state.fromBag > state.toBag or state.fromBag == state.toBag and state.fromSlot >= state.toSlot
    else
      return state.fromBag < state.toBag or state.fromBag == state.toBag and state.fromSlot <= state.toSlot
    end
  end,
  getDirection = function(back)
    if back then
      return ASCENDING, ASCENDING, DESCENDING, DESCENDING
    else
      return DESCENDING, DESCENDING, ASCENDING, ASCENDING
    end
  end,
  isValidMove = function(state)
    if state.fromBagDirection == ASCENDING then
      return state.fromBag < state.toBag or state.fromBag == state.toBag and state.fromSlot < state.toSlot
    else
      return state.fromBag > state.toBag or state.fromBag == state.toBag and state.fromSlot > state.toSlot
    end
  end
}

-- Preserves the natural order of items, i.e. the order in which items are placed when looting.
local SlideStrategy = {
  getDirection = function(back)
    if back then
      return DESCENDING, DESCENDING, DESCENDING, DESCENDING
    else
      return ASCENDING, ASCENDING, ASCENDING, ASCENDING
    end
  end,
  isValidMove = function(state)
    if state.fromBagDirection == ASCENDING then
      return state.fromBag > state.toBag or state.fromBag == state.toBag and state.fromSlot > state.toSlot
    else
      return state.fromBag < state.toBag or state.fromBag == state.toBag and state.fromSlot < state.toSlot
    end
  end
}

-- Preserves the visual order of items within each bag, left-to-right and top-to-bottom.
local SlideVisualStrategy = {
  getDirection = function(back)
    if back then
      return DESCENDING, ASCENDING, DESCENDING, ASCENDING
    else
      return ASCENDING, DESCENDING, ASCENDING, DESCENDING
    end
  end,
  isValidMove = function(state)
    if state.fromBag ~= state.toBag then
      if state.fromBagDirection == ASCENDING then
        return state.fromBag > state.toBag
      else
        return state.fromBag < state.toBag
      end
    end

    if state.fromSlotDirection == ASCENDING then
      return state.fromSlot > state.toSlot
    else
      return state.fromSlot < state.toSlot
    end
  end
}

function GetCompactStrategy(arg)
  local strategy

  if string.find(arg, 'slide') and string.find(arg, 'visual') then strategy = SlideVisualStrategy
  elseif string.find(arg, 'slide') then strategy = SlideStrategy
  else strategy = InvertStrategy
  end

  strategy.isValidToSlot = function(texture) return not texture end

  return strategy
end
