_ = require 'lodash'
uuid = require 'node-uuid'

# When block is dropped on it. side is top, left, bottom, right)
# returns new root block
exports.dropBlock = (rootBlock, sourceBlock, targetBlock, side) ->
  # Handle root case, only dropping on bottom
  if targetBlock.type == "root" and rootBlock.id == targetBlock.id
    blocks = rootBlock.blocks.slice()
    blocks.push(sourceBlock)
    return _.extend({}, rootBlock, blocks: blocks)

  # If vertical
  if rootBlock.type in ['vertical', 'root']
    blocks = rootBlock.blocks

    # Find target block
    index = _.findIndex(blocks, id: targetBlock.id)
    if index >= 0
      blocks = blocks.slice()

      # Add 
      switch side
        when "top"
          blocks.splice(index, 0, sourceBlock)

        when "bottom"
          blocks.splice(index + 1, 0, sourceBlock)

        when "left"
          blocks.splice(index, 1, { id: uuid.v4(), type: "horizontal", blocks: [sourceBlock, targetBlock] })

        when "right"
          blocks.splice(index, 1, { id: uuid.v4(), type: "horizontal", blocks: [targetBlock, sourceBlock] })

      return _.extend({}, rootBlock, blocks: blocks)
    else
      # Recurse
      blocks = _.map(blocks, (block) -> exports.dropBlock(block, sourceBlock, targetBlock, side))
      return _.extend({}, rootBlock, blocks: blocks)

  # If horizontal
  if rootBlock.type == "horizontal"
    blocks = rootBlock.blocks

    # Find target block
    index = _.findIndex(blocks, id: targetBlock.id)
    if index >= 0
      blocks = blocks.slice()

      # Add 
      switch side
        when "left"
          blocks.splice(index, 0, sourceBlock)

        when "right"
          blocks.splice(index + 1, 0, sourceBlock)

        when "top"
          blocks.splice(index, 1, { id: uuid.v4(), type: "vertical", blocks: [sourceBlock, targetBlock] })

        when "bottom"
          blocks.splice(index, 1, { id: uuid.v4(), type: "vertical", blocks: [targetBlock, sourceBlock] })

      return _.extend({}, rootBlock, blocks: blocks)
    else
      # Recurse
      blocks = _.map(blocks, (block) -> exports.dropBlock(block, sourceBlock, targetBlock, side))
      return _.extend({}, rootBlock, blocks: blocks)
      
  return rootBlock


# Updates a block
# returns new root block
exports.updateBlock = (rootBlock, block) ->
  # If vertical or horizontal
  if rootBlock.type in ['vertical', 'horizontal', 'root']
    blocks = rootBlock.blocks

    # Update block
    blocks = _.map(blocks, (b) -> if b.id == block.id then block else b)

    # Recurse
    blocks = _.map(blocks, (b) -> exports.updateBlock(b, block))

    return _.extend({}, rootBlock, blocks: blocks)
  
  return rootBlock

# When block is removed
# returns new root block
exports.removeBlock = (rootBlock, block) ->
  # If vertical or horizontal
  if rootBlock.type in ['vertical', 'horizontal', 'root']
    blocks = rootBlock.blocks

    # Remove blocks
    blocks = _.filter(blocks, (b) -> b.id != block.id)

    # Recurse
    blocks = _.compact(_.map(blocks, (b) -> exports.removeBlock(b, block)))

    # If empty and not root, return null
    if blocks.length == 0 and rootBlock.type != "root"
      return null

    return _.extend({}, rootBlock, blocks: blocks)
  
  return rootBlock