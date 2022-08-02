local utils = require("nvim-highlight-colors.utils")
local buffer_utils = require("nvim-highlight-colors.buffer_utils")
local colors= require("nvim-highlight-colors.colors")

local load_on_start_up = false
local row_offset = 2
local windows = {}
local is_loaded = false

function is_window_already_created(row, value)
	for _, windows_data in ipairs(windows) do
		if windows_data.row == row and value == windows_data.color then
			return true
		end
	end

	return false
end

function close_windows()
	local ids = {}
	for _, window_data in ipairs(windows) do
		table.insert(ids, window_data.win_id)
	end
	utils.close_windows(ids)
	windows = {}
end

function close_not_visible_windows(min_row, max_row)
	local windows_to_remove = {}
	local new_windows_table = {}
	for _, window_data in ipairs(windows) do
		local window_config = vim.api.nvim_win_get_config(window_data.win_id)
		local window_bufpos = window_config.bufpos
		local window_row = window_bufpos[1] + row_offset
		local is_visible = window_row <= max_row and window_row >= min_row
		if is_visible == false then
			table.insert(windows_to_remove, window_data.win_id)
		else
			table.insert(new_windows_table, window_data)
		end
	end
	utils.close_windows(windows_to_remove)
	windows = new_windows_table
end

function show_visible_windows(min_row, max_row)
	local positions = buffer_utils.get_positions_by_regex(
		{
			colors.hex_regex,
			colors.rgb_regex,
			colors.var_usage_regex
		},
		min_row - 1,
		max_row,
		row_offset
	)

	for _, data in pairs(positions) do
		if is_window_already_created(data.row, data.value) == false then
			table.insert(
				windows,
				{
					win_id = utils.create_window(data.row, 0, data.value, row_offset),
					row = data.row,
					color = data.value
				}
			)
		end
	end
end

function update_windows_visibility()
	local visible_rows = utils.get_win_visible_rows(0)
	local min_row = visible_rows[1]
	local max_row = visible_rows[2]

	show_visible_windows(min_row, max_row)
	close_not_visible_windows(min_row, max_row)
end

function turn_on()
	close_windows()
	local visible_rows = utils.get_win_visible_rows(0)
	local min_row = visible_rows[1]
	local max_row = visible_rows[2]
	show_visible_windows(min_row, max_row)
	is_loaded = true
end

function turn_off()
	close_windows()
	is_loaded = false
end

function setup()
	load_on_start_up = true
end

function toggle()
	if is_loaded then
		turn_off()
	else 
		turn_on()
	end
end

vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI", "TextChangedP", "VimResized"}, {
	callback = turn_on,
})

vim.api.nvim_create_autocmd({"WinScrolled"}, {
	callback = update_windows_visibility,
})

vim.api.nvim_create_autocmd({"BufEnter"}, {
	callback = function ()
		if load_on_start_up == true then
			turn_on()
		end
	end,
})

local M = {}

M.turnOff = turn_off
M.turnOn = turn_on
M.setup = setup
M.toggle = toggle

return M
