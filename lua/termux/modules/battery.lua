local Job = require("plenary.job")

local M = {}

M.get_info = function()
	Job:new({
		command = "termux-battery-status",
		on_exit = function(self, code)
			if code ~= 0 then
				vim.notify("Exit code for termux-battery-status is not 0, check logs.")
			else
				vim.schedule(function()
					local final_result = table.concat(self:result(), "")
					---@class RawBatteryValues
					---@field health string
					---@field percentage number
					---@field plugged string
					---@field status string
					---@field temperature float
					local parsed_json = vim.fn.json_decode(final_result)
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
		end,
	}):start()
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
		_G.termux_values.timers.battery:start(0, _G.termux_options.battery.refresh_rate * 1000, M.get_info)
	end
end

M.stop_timer = function()
	if _G.termux_values.timers.battery ~= nil then
		_G.termux_values.timers.battery:stop()
		_G.termux_values.timers.battery = nil
	end
end

return M
