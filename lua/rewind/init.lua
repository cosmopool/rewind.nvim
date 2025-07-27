local M = {}

require("ring_buffer")

M.timeline = ringbuf(500)
M.position = 1

function M.inspect()
  for key, value in pairs(M.timeline) do
    print("KEY: ", key, " VALUE: ", value)
  end
  print("TAIL:", M.tail)
  print("POSITION:", M.position)
  print("ITEMS:", M.timeline.items)
  local buffer = M.timeline.items[M.position - 2]
  print("BUFFER:", buffer)
  print("BUFFER:", buffer.id, buffer.row, buffer.col)
end

function M.setup(opts)
  vim.api.nvim_create_user_command("Rewind", M.rewind, {})
  vim.api.nvim_create_user_command("RewindRevert", M.forward, {})
  vim.api.nvim_create_user_command("RewindInspect", M.inspect, {})
  vim.keymap.set("n", "<space>[", "Rewind")
  vim.keymap.set("n", "<space>]", "RewindRevert")

  vim.api.nvim_create_autocmd('BufLeave', {
    pattern = '*',
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if win == -1 then
        error('not able to get the current window')
      end

      local cursor = vim.api.nvim_win_get_cursor(win)
      local buff_number = vim.api.nvim_get_current_buf()
      M.timeline:push({ row = cursor[1], col = cursor[2], number = buff_number })
      M.position = M.position + 1
    end
  })
end

function M.rewind()
  if M.position <= 1 then return end

  M.position = M.position - 2
  local buffer = M.timeline.items[M.position]
  vim.api.nvim_set_current_buf(buffer.number)
  vim.api.nvim_win_set_cursor(0, { buffer.row, buffer.col })
end

function M.forward()
  print("idx write", M.timeline.idx_write)
  print("idx read", M.timeline.idx_read)
  print("position", M.position)
  if M.position >= M.timeline._idx_write then return end

  M.position = M.position + 1
  local buffer = M.timeline.items[M.position]
  if not buffer then return end

  vim.api.nvim_set_current_buf(buffer.number)
  vim.api.nvim_win_set_cursor(0, { buffer.row, buffer.col })
end

return M
