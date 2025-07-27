local M = {}

M._size = 1000
M._idx_current = 0
M._idx_oldest = 0
M._idx_latest = 0
M.timeline = {}

function M.inspect()
  for key, value in pairs(M.timeline) do
    print("KEY: ", key, " VALUE: ", value)
  end

  print("TAIL:", M.tail)
  print("ITEMS:", M.timeline)
  local buffer = M.timeline[M._idx_oldest]
  print("BUFFER:", buffer)
  print("BUFFER:", buffer.id, buffer.row, buffer.col)
end

function M.setup(opts)
  vim.api.nvim_create_user_command("Rewind", M.rewind, {})
  vim.api.nvim_create_user_command("RewindRevert", M.forward, {})
  vim.api.nvim_create_user_command("RewindInspect", M.inspect, {})
  vim.keymap.set("n", "<leader>[", "<CMD>Rewind<CR>")
  vim.keymap.set("n", "<leader>]", "<CMD>RewindRevert<CR>")

  vim.api.nvim_create_autocmd('BufLeave', {
    pattern = '*',
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if win == -1 then
        error('not able to get the current window')
      end

      local cursor = vim.api.nvim_win_get_cursor(win)
      local buff_number = vim.api.nvim_get_current_buf()
      local file_name = vim.api.nvim_buf_get_name(buff_number)
      print(file_name)
      M.push(cursor[1], cursor[2], buff_number)
    end
  })
end

--- The buffer id number and in each [row] and [column] the cursor was when last navigated to other buffer
---@param row number
---@param col number
---@param buff_number number
function M.push(row, col, buff_number)
  local entry = { row = row, col = col, number = buff_number }
  M.timeline[M._idx_latest + 1 % M.size] = entry

  M._idx_latest = (M._idx_latest + 1) % M._size
  if M._idx_latest == M._idx_oldest then
    M._idx_oldest = (M._idx_oldest + 1) % M._size
  end
end

function M.rewind()
  print("idx write", M._idx_latest)
  print("idx read", M._idx_current)
  if M._idx_current == M._idx_latest then return end

  M._idx_latest = (M._idx_latest - 1) % M._size
  if M._idx_latest == M._idx_current then
    M._idx_current = (M._idx_current - 1) % M._size
  end

  local buffer = M.timeline[M._idx_current]
  vim.api.nvim_set_current_buf(buffer.number)
  vim.api.nvim_win_set_cursor(0, { buffer.row, buffer.col })
end

function M.forward()
  print("idx write", M._idx_latest)
  print("idx read", M._idx_oldest)
  if M.position >= M._idx_latest then return end

  M.position = M.position + 1
  local buffer = M.timeline.pop()
  if not buffer then return end

  vim.api.nvim_set_current_buf(buffer.number)
  vim.api.nvim_win_set_cursor(0, { buffer.row, buffer.col })
end

return M
