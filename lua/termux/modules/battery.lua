local M = {}

M.get_info = function()
	local stdout = vim.loop.new_pipe(false)
	_G.termux_battery_handle = vim.loop.spawn(
		"termux-battery-status",
		{ stdio = { nil, stdout, nil } },
		vim.schedule_wrap(function(code)
			stdout:read_stop()
			stdout:close()
			_G.termux_battery_handle:close()

			if code ~= 0 then
				vim.notify("Failure while trying to get battery status, exit code: " .. code, vim.log.levels.ERROR)
			end
		end)
	)

	vim.loop.read_start(stdout, function(err, data)
		if err then
			vim.notify("Error when trying to receive stdout: " .. err)
		elseif data then
			vim.schedule(function()
				---@class RawBatteryValues
				---@field health string
				---@field percentage number
				---@field plugged string
				---@field status string
				---@field temperature float
				local parsed_json = vim.fn.json_decode(data)
				_G.termux_values.battery = {
					percentage = parsed_json.percentage,
					status = parsed_json.status,
					health = parsed_json.health,
					plugged = parsed_json.plugged ~= "UNPLUGGED",
					wireless = parsed_json.plugged == "PLUGGED_WIRELESS",
					temperature = parsed_json.temperature,
				}
			end)
		end
	end)
end

---Helper function to use to generate an entry for a statusline
M.get_statusline = function()
	local battery = _G.termux_values.battery
	local all_icons = _G.termux_options.battery.icons
	local icon = all_icons.empty

	if battery.wireless then
		icon = all_icons.wireless
	elseif battery.plugged then
		icon = all_icons.charging
	elseif battery.percentage >= 90 then
		icon = all_icons.full
	elseif battery.percentage >= 75 then
		icon = all_icons.threeq
	elseif battery.percentage >= 35 then
		icon = all_icons.half
	elseif battery.percentage >= 15 then
		icon = all_icons.oneq
	else
		icon = all_icons.empty
	end

	local percentage = ""
	if _G.termux_options.battery.print_percentage then
		percentage = battery.percentage .. "%%"
	end

	return icon .. percentage
end

M.start_timer = function()
	if _G.termux_values.timers.battery == nil then
		-- launch it the first time to get the first opening values
		_G.termux_values.timers.battery = vim.loop.new_timer()
		_G.termux_values.timers.battery:start(
			0,
			_G.termux_options.battery.refresh_rate * 1000,
			vim.schedule_wrap(M.get_info)
		)
	end
end

M.stop_timer = function()
	if _G.termux_values.timers.battery ~= nil then
		_G.termux_values.timers.battery:stop()
		_G.termux_values.timers.battery = nil
	end
end

return M
