---@class Ringbuf<T>
---@field items table[]
---@field idx_read integer
---@field idx_write integer
---@field size integer
---@overload fun(M): table?
local Ringbuf = {}

Ringbuf.size = 0
Ringbuf.items = {}
Ringbuf.idx_read = 0
Ringbuf.idx_write = 0

--- Clear all items
function Ringbuf.clear(self)
  self.items = {}
  self.idx_read = 0
  self.idx_write = 0
end

--- Adds an item, overriding the oldest item if the buffer is full.
---@generic T
---@param item T
function Ringbuf.push(self, item)
  self.items[self.idx_write] = item
  self.idx_write = (self.idx_write + 1) % self.size
  if self.idx_write == self.idx_read then
    self.idx_read = (self.idx_read + 1) % self.size
  end
end

--- Removes and returns the first unread item
---@generic T
---@return T?
function Ringbuf.pop(self)
  local idx_read = self.idx_read
  if idx_read == self.idx_write then
    return nil
  end
  local item = self.items[idx_read]
  self.items[idx_read] = nil
  self.idx_read = (idx_read + 1) % self.size
  return item
end

--- Returns the first unread item without removing it
---@generic T
---@return T?
function Ringbuf.peek(self)
  if self.idx_read == self.idx_write then
    return nil
  end
  return self.items[self.idx_read]
end

--- Create a ring buffer limited to a maximal number of items.
--- Once the buffer is full, adding a new entry overrides the oldest entry.
---
--- ```lua
--- local ringbuf = vim.ringbuf(4)
--- ringbuf:push("a")
--- ringbuf:push("b")
--- ringbuf:push("c")
--- ringbuf:push("d")
--- ringbuf:push("e")    -- overrides "a"
--- print(ringbuf:pop()) -- returns "b"
--- print(ringbuf:pop()) -- returns "c"
---
--- -- Can be used as iterator. Pops remaining items:
--- for val in ringbuf do
---   print(val)
--- end
--- ```
---
--- Returns a Ringbuf instance with the following methods:
---
--- - |Ringbuf:push()|
--- - |Ringbuf:pop()|
--- - |Ringbuf:peek()|
--- - |Ringbuf:clear()|
---
---@param size integer
---@return Ringbuf ringbuf
function ringbuf(size)
  local r = Ringbuf
  r.size = size
  return r
end

return ringbuf
