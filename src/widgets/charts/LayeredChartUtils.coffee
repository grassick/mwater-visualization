# Misc utils for layered charts

# Get possible types for axis of a layer
exports.getAxisTypes = (design, layer, axis) ->
  # If categorical
  layerType = (layer.type or design.type) 

  switch axis
    when "x"
      if layerType == 'bar'
        return ['enum', 'text', 'integer', 'date']

      # All
      return null
    when "color"
      return ['enum', 'text', 'date']
    when "y"
      return ['integer', "decimal"]