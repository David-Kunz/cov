local M = {}

local coverage_file = "./coverage/coverage-final.json"
local coverage_data = {}

local function load_coverage()
  local f = io.open(coverage_file, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, json = pcall(vim.fn.json_decode, content)
  if not ok then return {} end
  return json
end

local function highlight_for_count(count)
  if count == 0 then return "CoverageRed"
  elseif count < 5 then return "CoverageOrange"
  elseif count < 20 then return "CoverageYellow"
  else return "CoverageGreen" end
end

local function define_highlights()
  vim.api.nvim_set_hl(0, "CoverageRed", { fg = "#ff5555" })
  vim.api.nvim_set_hl(0, "CoverageOrange", { fg = "#ff9900" })
  vim.api.nvim_set_hl(0, "CoverageYellow", { fg = "#f1fa8c" })
  vim.api.nvim_set_hl(0, "CoverageGreen", { fg = "#50fa7b" })
end

-- left pad a string to fixed width
local function pad_number(num, width)
  local s = tostring(num)
  local padding = width - #s
  if padding > 0 then
    return string.rep(" ", padding) .. s
  else
    return s
  end
end

local function place_signs(bufnr, file_coverage)
  vim.fn.sign_unplace("coverage", { buffer = bufnr })

  -- compute maximum width for counts
  local max_width = 1
  for id, _ in pairs(file_coverage.statementMap or {}) do
    local count = file_coverage.s[tostring(id)] or 0
    local w = #tostring(count)
    if w > max_width then max_width = w end
  end

  -- place padded signs
  for id, stmt in pairs(file_coverage.statementMap or {}) do
    local count = file_coverage.s[tostring(id)] or 0
    local hl = highlight_for_count(count)
    local line = stmt.start.line

    local text = pad_number(count, max_width)
    local sign_name = "CoverageSign_" .. text .. "_" .. hl
    pcall(vim.fn.sign_define, sign_name, { text = text, texthl = hl })

    vim.fn.sign_place(
      0,
      "coverage",
      sign_name,
      bufnr,
      { lnum = line, priority = 10 }
    )
  end
end

function M.refresh()
  coverage_data = load_coverage()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)

  for path, data in pairs(coverage_data) do
    if filename:sub(-#path) == path then
      place_signs(bufnr, data)
      return
    end
  end
end

function M.setup()
  define_highlights()
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function() M.refresh() end
  })
  vim.api.nvim_create_user_command("CoverageRefresh", function() M.refresh() end, {})
end

return M
