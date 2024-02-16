local Job = require("plenary.job")

local M = {}

M.get_info = function()
	Job:new({
		command = "termux-volume",
		on_exit = function(self, code)
			if code ~= 0 then
				vim.notify("Exit code for termux-volume is not 0, check logs.")
			else
				vim.schedule(function()
					local data = table.concat(self:result(), "")
					---@type VolumeInfo[]
					---@diagnostic disable-next-line: assign-type-mismatch
					local parsed_json = vim.fn.json_decode(data)
					for _, stream in ipairs(parsed_json) do
						for stream_type, stream_info in pairs(_G.termux_values.volumes) do
							if stream.stream == stream_type then
								stream_info.volume = stream.volume
								stream_info.max_volume = stream.max_volume
							end
						end
					end
				end)
			end
		end,
	}):start()
end

M.start_timer = function()
	if _G.termux_values.timers.volume == nil then
		-- launch it the first time to get the first opening values
		_G.termux_values.timers.volume = vim.loop.new_timer()
		_G.termux_values.timers.volume:start(0, _G.termux_options.volume.refresh_rate * 1000, M.get_info)
	end
end

M.stop_timer = function()
	if _G.termux_values.timers.volume ~= nil then
		_G.termux_values.timers.volume:stop()
		_G.termux_values.timers.volume = nil
	end
end

M.get_statusline = function()
	---@type string
	local final_string = ""
	for _, stream in ipairs(_G.termux_options.volume.streams) do
		final_string = final_string .. _G.termux_options.volume.icons[stream]
		final_string = final_string .. _G.termux_values.volumes[stream].volume .. " "
	end

	-- Remove final whitespaces from string
	final_string = string.match(final_string, "^%s*(.-)%s*$")

	return final_string
end

return M
