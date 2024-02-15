local battery = require("termux.modules.battery")
local volume = require("termux.modules.volume")

---@class TermuxInfo
---@field battery BatteryInfo
---@field volumes VolumesInfo
---@field timers TimersInfo
_G.termux_values = {
	---@class BatteryInfo
	---@field percentage number
	---@field status string
	---@field health string
	---@field plugged boolean
	---@field wireless boolean
	---@field temperature float
	battery = {
		percentage = 0,
		status = "DISCHARGING",
		health = "GOOD",
		plugged = false,
		wireless = false,
		temperature = 25.5,
	},

	---@class VolumesInfo
	---@field call VolumeInfo
	---@field system VolumeInfo
	---@field ring VolumeInfo
	---@field music VolumeInfo
	---@field alarm VolumeInfo
	---@field notification VolumeInfo
	volumes = {
		---@class VolumeInfo
		---@field stream string # Name of the stream
		---@field volume number # Actual volume
		---@field max_volume number # Maximum allowed value
		call = {
			stream = "call",
			volume = 0,
			max_volume = 7,
		},
		system = {
			stream = "system",
			volume = 0,
			max_volume = 7,
		},
		ring = {
			stream = "ring",
			volume = 0,
			max_volume = 7,
		},
		music = {
			stream = "music",
			volume = 0,
			max_volume = 25,
		},
		alarm = {
			stream = "alarm",
			volume = 0,
			max_volume = 7,
		},
		notification = {
			stream = "notification",
			volume = 0,
			max_volume = 7,
		},
	},

	---@class TimersInfo
	---@field battery uv_timer_t|nil
	---@field volume uv_timer_t|nil
	timers = {
		battery = nil,
		volume = nil,
	},
}

local M = {}

---@alias Streams Stream[]
---@alias Stream
---| "call" # volume for calls, max is 7
---| "system" # volume for system, max is 7
---| "ring" # volume for calls, max is 7
---| "music" # volume for music and general audio, max is 25
---| "alarm" # volume for alarms, max is 7
---| "notification" # volume for notifications, max is 7

---@class TermuxModuleOptions
---@field battery BatteryOptions
---@field volume VolumeOptions
_G.termux_options = {
	---@class BatteryOptions
	---@field enabled boolean # Whether or not to enable the battery module
	---@field print_percentage boolean # Whether or not to also print the percentage value
	---@field refresh_rate number # Refresh rate in seconds
	---@field icons BatteryIconsOptions
	battery = {
		enabled = true,
		refresh_rate = 30,
		print_percentage = true,

		---@class BatteryIconsOptions
		---@field empty string # Icon to use when the battery level is <= 15%
		---@field oneq string # Icon to use when the battery level is between 15% and 25%
		---@field half string # Icon to use when the battery level is between 25% and 75%
		---@field threeq string # Icon to use when the battery level is between 75% and 90%
		---@field full string # Icon to use when the battery level is above 90%
		---@field charging string # Icon to use when the battery is charging
		---@field wireless string # Icon to use when the battery is charging wirelessly
		icons = {
			empty = "  ",
			oneq = "  ",
			half = "  ",
			threeq = "  ",
			full = "  ",
			charging = "󰉁 ",
			wireless = "󰠕  ",
		},
	},
	---@class VolumeOptions
	---@field enabled boolean # Whether or not to enable the volume module
	---@field refresh_rate number # Refresh rate in seconds
	---@field streams Streams # Streams to print in the statusline
	---@field icons VolumeIconsOptions
	volume = {
		enabled = true,
		refresh_rate = 10,
		streams = { "music", "ring", "notification", "system", "call" },

		---@class VolumeIconsOptions
		---@field call string # Icon to use for call volume
		---@field system string # Icon to use for system volume
		---@field ring string # Icon to use for ring volume
		---@field music string # Icon to use for music volume
		---@field alarm string # Icon to use for alarm volume
		---@field notification string # Icon to use for notification volume
		icons = {
			call = "󱡏  ",
			system = "  ",
			ring = "󱆫  ",
			music = "  ",
			alarm = "󰀠  ",
			notification = "  ",
		},
	},
}

M.get_volume_info = volume.get_info
M.get_volume_statusline = volume.get_statusline
M.get_battery_info = battery.get_info
M.get_battery_statusline = battery.get_statusline

M.stop_all_timers = function()
	battery.stop_timer()
	volume.stop_timer()
end

M.start_all_timers = function()
	if _G.termux_options.battery.enabled then
		battery.start_timer()
	end

	if _G.termux_options.volume.enabled then
		volume.start_timer()
	end
end

---Setup the Termux Plugin
---@param opts TermuxModuleOptions
M.setup = function(opts)
	_G.termux_options = vim.tbl_deep_extend("force", _G.termux_options, opts)
	M.start_all_timers()
end

return M
