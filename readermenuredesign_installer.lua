-- Loosely based on code from @joshuacant
-- https://github.com/joshuacant/ProjectTitle/blob/master/ptutil.lua

local DataStorage = require("datastorage")
local ffiUtil = require("ffi/util")
local util = require("util")
local logger = require("logger")

local Installer = {}

local logprefix = "[ReaderMenuRedesign] Installer:"
local koreader_dir = DataStorage:getDataDir()
local plugins_dir = koreader_dir .. "/plugins"
local plugin_path = plugins_dir .. "/" .. "zzz-readermenuredesign.koplugin"
local plugin_icons_dir = plugin_path .. "/resources/icons/mdlight"
local koreader_icons_dir = koreader_dir .. "/resources/icons/mdlight"

function Installer:installIcons()
	local icon_list = {}

	logger.info(logprefix, plugins_dir)
	logger.info(logprefix, plugin_path)
	logger.info(logprefix, plugin_icons_dir)
	logger.info(logprefix, koreader_icons_dir)

	logger.info(logprefix, "Getting list of bundled icons...")
	util.findFiles(plugin_icons_dir, function(fullpath, filename, attr)
		if attr.mode == "file" and filename then
			local ext = util.getFileNameSuffix(filename):lower()
			if ext == "png" or ext == "svg" then
				table.insert(icon_list, {
					fullpath = fullpath,
					filename = filename,
				})
			end
		end
	end, false, nil)

	if #icon_list == 0 then
		logger.info(logprefix, "No bundled icons found.")
		return true
	end

	logger.info(logprefix, "Found " .. #icon_list .. " bundled icons.")

	if not util.directoryExists(koreader_icons_dir) then
		logger.info(logprefix, "Creating icons folder...")
		local result = util.makePath(koreader_icons_dir)
		if not result then
			return false
		end
	end

	local did_add_icons = false
	for _, icon in ipairs(icon_list) do
		-- check icon files one at a time, and only copy when missing
		-- this will preserve custom icons set by the user
		local target_icon_path = koreader_icons_dir .. "/" .. icon.filename
		if not util.fileExists(target_icon_path) then
			logger.info(logprefix, "Adding new icon: " .. icon.filename)
			ffiUtil.copyFile(icon.fullpath, target_icon_path)
			did_add_icons = true
		end
	end

	if did_add_icons then
		-- Allow new icons to be loaded.
		package.loaded["ui/widget/iconwidget"] = nil
		package.loaded["ui/widget/iconbutton"] = nil
	else
		logger.info(logprefix, "No new icons to add.")
	end

	return true
end

return Installer
