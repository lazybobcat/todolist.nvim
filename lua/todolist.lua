local M = {}

---@class todolist.Options
---@field todo_file ?string
---@field todo_statuses ?table<string, string>

---@type todolist.Options
local options = {
  todo_file = "TODO.md",
  todo_statuses = {
    [" "] = "todo",
    ["-"] = "doing",
    ["x"] = "done",
  },
}

---@class todolist.Todo
---@field line number
---@field label string
---@field status string
---@field tags string[]
---@field priority number | nil
---@field due string | nil

---@type todolist.Todo[]
local todos = {}

---@param opts todolist.Options
M.setup = function(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend('force', options, opts)
  print(vim.inspect(options))
end

M.parse_lines = function(lines)
  for i, line in ipairs(lines) do
    -- match todos lines, beggining with '- [ ]'
    if line:match("^%s*%- %[.%]") then
      -- Todo format is: - [<status>] (<priority>) <label> +<tag> due:<date>
      local status, rest = line:match("^%s*%- %[(.)]%s*(.-)$")
      status = options.todo_statuses[status] or status

      -- extract priority
      local priority, r = rest:match("^%((%d)%)%s*(.-)$")
      rest = r or rest

      -- extract tags
      local tags = {}
      for tag in rest:gmatch("%+([%w:]+)") do
        table.insert(tags, tag)
      end
      local r = rest:match("^(.-)%s*%+")
      rest = r or rest

      -- extract due date
      local r, due = rest:match("^(.-)%s*due:(.*)")
      rest = r or rest

      -- extract label
      local label = rest:match("^(.*)%s*")

      table.insert(todos, {
        line = i,
        label = label,
        status = status,
        tags = tags,
        priority = priority and tonumber(priority) or nil,
        due = due,
      })
    end
  end

  return todos
end

M.open_todo_file = function()
  -- check if todo file exists
  local file_path = vim.fn.expand(vim.fs.joinpath(vim.fn.getcwd(), options.todo_file))
  if not vim.fn.filereadable(file_path) then
    -- create file if it doesn't exist
    local f = io.open(file_path, "w")
    if not f then
      error("Error creating file: " .. file_path)
      return
    end
    f:write("# Todo\n")
    f:close()
  end

  local lines = {}
  for line in io.lines(file_path) do
    table.insert(lines, line)
  end

  return M.parse_lines(lines)
end

-- print(vim.inspect(M.parse_lines({
--   "# Todo",
--   "",
--   "- [ ] (1) Task 1",
--   "- [x] Task 2 due:tomorrow",
--   "- [p] Task 3",
--   "- [ ] Task 4 +project:todolist +tag2 due:2025-03-15",
-- })))

-- print(vim.inspect(M.open_todo_file()))

return M
