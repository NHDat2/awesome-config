pcall(require, "luarocks.loader")
require("awful.autofocus")

local gears		 = require("gears")
local awful		 = require("awful")
local wibox		 = require("wibox")
local beautiful	 = require("beautiful")
local naughty	 = require("naughty")
local menubar	 = require("menubar")
local help_utils = require("help_utils")
local rubato 	 = require("rubato")
local bling 	 = require("bling")
local utils = require("util.utils")

beautiful.init("~/.config/awesome/themes/something/theme.lua")

local cmd_usg = "top -b -n 1 | awk '/Cpu/ { print $2 }'"
local cmd_temp = "sensors | awk '/Package id 0:/ { print $4 }' | sed 's/+//'"

local cmd_ram_total = "top -b -n 1 | awk '/MiB Mem/ { print $4 }'"
local cmd_ram_used = "top -b -n 1 | awk '/MiB Mem/ { print $8 }'"
local cmd_swap_used = "top -b -n 1 | awk '/MiB Swap/ { print $7 }'"

mymainmenu = awful.menu({
	items = {
		{ "Open terminal", terminal },
		{ "Edit config", editor_cmd .. " " .. awesome.conffile },
		{ "Restart awesome", awesome.restart },
		{ "Shutdown", function() awful.util.spawn("systemctl poweroff") end },
		{ "Reboot", function() awful.util.spawn("systemctl reboot") end }
	}
})
mymainmenu.wibox.shape = function (cr, w, h)
	gears.shape.rounded_rect(cr, w, h, 10)
end

-- Creates the textclock widget.
mytextclock = wibox.widget {
	{
		id = "clock",
		widget = wibox.widget.textclock("%H:%M")
	},
	widget = wibox.container.margin,
	left = 12,
	right = 12
}

local calender_tt = awful.tooltip{
    objects = { mytextclock },
    mode = "outside",
}
local month_calendar = awful.widget.calendar_popup.month({
    margin = 12,
    style_month = {
        border_width = 7,
        shape = gears.shape.rounded_rect
    }
})
month_calendar:attach( mytextclock, "tr" )

-- Creates the cpu widget.
local cpu_widget = wibox.widget{
    {
        {
            {
                {
                    id = "text",
                    -- font = beautiful.font_type .. "10",
                    markup = '<span>﬙ </span> 0%',
                    widget = wibox.widget.textbox,
                },
                right = 5,
                left = 5,
                layout = wibox.container.margin,
            },
            -- shape = function (cr, width, height)
                            -- shape.rounded_rect(cr, width, height, 10) end,
            -- shape_border_width = 1.75,
            -- fg = beautiful.primary_fg_color,
            -- shape_border_color = beautiful.dark_primary_color,
            -- bg = beautiful.primary_bg_color .. "40",
            widget = wibox.container.background,
        },
        -- top = 3,
        -- bottom = 3,
        -- right = 4,
        -- left = 4,
        layout = wibox.container.margin,
    },
    layout = wibox.layout.align.horizontal
}

local cpu_tt = awful.tooltip{
    objects = { cpu_widget },
    mode = "outside",
}

awful.widget.watch("sh -c \"" .. cmd_usg .. " ; " .. cmd_temp .. "\"", 1.5, function(widget, stdout)
    local split_stdout = utils.split_str(stdout, "\n")
    cpu_widget:get_children_by_id("text")[1].markup = '<span> </span> ' .. utils.split_str(split_stdout[1], ".")[1] .. '%'
    cpu_tt.text = "Usg: " .. split_stdout[1] .. "%\nTemp: " .. split_stdout[2]
end, cpu_widget)

-- Creates the Ram widget.
local ram_widget = wibox.widget{
	{
		{
			{
				{
					id = "text",
					-- font = beautiful.font_type .. "10",
					markup = '<span> </span> ' .. '0/0G',
					widget = wibox.widget.textbox,
				},
				right = 5,
				left = 5,
				layout = wibox.container.margin,
			},
			-- shape = function (cr, width, height)
							-- shape.rounded_rect(cr, width, height, 10) end,
			-- shape_border_width = 1.75,
			-- fg = beautiful.primary_fg_color,
			-- shape_border_color = beautiful.dark_primary_color,
			-- bg = beautiful.primary_bg_color .. "40",
			widget = wibox.container.background,
		},
		-- top = 3,
		-- bottom = 3,
		-- right = 4,
		-- left = 4,
		layout = wibox.container.margin,
	},
	layout = wibox.layout.align.horizontal
}

local ram_tt = awful.tooltip{
	objects = { ram_widget },
	mode = "outside",
}

local total_ram = string.format("%.1f", tostring(tonumber(utils.os_output(cmd_ram_total)) / 1000))

awful.widget.watch("sh -c \"" .. cmd_ram_used .. " ; " .. cmd_swap_used .. "\"", 3, function(widget, stdout)
	local split_stdout = utils.split_str(stdout, "\n")
	ram_widget:get_children_by_id("text")[1].markup = '<span> </span> ' ..
		string.format("%.1f", tostring((tonumber(split_stdout[1]) / 1024) * 100 / total_ram)) .. '%'
	ram_tt.text = "RAM: " .. split_stdout[1] .. "\nSwap: " .. split_stdout[2]
end, ram_widget)

-- Creates the system tray.
tray = wibox.widget.systray()
mysystemtray = {
	{
		{
			widget = tray,
			id = "tray"
		},
		top = 5,
		bottom = 5,
		left = 10,
		right = 10,
		widget = wibox.container.margin
	},
	shape      = gears.shape.rounded_bar,
	shape_border_color = beautiful.secondary,
	shape_border_width = 3,
	shape_clip = true,
	widget     = wibox.container.background,
	bg = beautiful.secondary
}

local function interpolate(first_color, second_color, amount)
	return {
		r = second_color.r * amount + first_color.r * (1 - amount),
		g = second_color.g * amount + first_color.g * (1 - amount),
		b = second_color.b * amount + first_color.b * (1 - amount),
	}
end

local function parse_color(color)
	local color = { gears.color.parse_color(color) }
	return {
		r = color[1] * 255,
		g = color[2] * 255,
		b = color[3] * 255
	}
end

local function get_color(name)
	return parse_color(beautiful[name])
end

-- Volume widget.
local function draw_volume(cr, height)
	local two_pi = math.pi * 2
	local half_pi = math.pi / 2

	local volume = help_utils.get_volume()
	local muted = help_utils.get_muted()

	local colors = {
		get_color("volume_color_normal"),
		get_color("volume_color_high")
	}
	local muted_color = get_color("volume_color_muted")

	progress = (volume % 100) / 100
	if not(volume == 0) and progress == 0 then
		progress = 1
	end

	local function draw_volume_arc(start, stop, color) -- start and stop are values in [0,1]
		cr:set_source_rgb(color.r / 255, color.g / 255, color.b / 255)
		cr:set_line_width(4)
		cr:arc(height/2, height/2, 6, start * two_pi - half_pi, stop * two_pi - half_pi)
		cr:stroke()
	end

	if volume <= 100 then
		local c
		if muted then
			c = muted_color
		else
			c = colors[1]
		end
		draw_volume_arc(0, progress, c)
	elseif volume <= 200 then
		local c
		if muted then
			c = muted_color
		else
			c = colors[1]
			draw_volume_arc(progress, 0, colors[1])
		end
		draw_volume_arc(0, progress, c)
	else
		local c
		if muted then
			c = muted_color
		else
			c = colors[2]
		end
		draw_volume_arc(0, 1, c)
	end
end

local function make_volume_widget()
	local widget = wibox.widget {
		fit = function(self, context, width, height)
			return height, height
		end,
		draw = function(self, context, cr, width, height)
			draw_volume(cr, height)
		end,
		layout = wibox.widget.base.make_widget
	}

	awesome.connect_signal("volume_refresh", function() widget:emit_signal("widget::redraw_needed") end)

	return widget
end

local myvolumewidget = make_volume_widget()

awful.screen.connect_for_each_screen(function(s)
	-- Tagtable for each screen.
	awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

	local function draw_circle(cr, height)
		cr:arc(height/2, height/2, 5, 0, math.pi * 2)
		cr:fill()
	end

	local function make_circle_widget(color)
		return wibox.widget {
			fit = function(self, context, width, height)
				return height, height
			end,
			draw = function(self, context, cr, width, height)
				cr:set_source_rgb(color.r / 255, color.g / 255, color.b / 255)
				draw_circle(cr, height)
			end,
			layout = wibox.widget.base.make_widget
		}
	end

	local function update_rgb(widget, rgb)
		widget.draw = function(self, context, cr, width, height)
			cr:set_source_rgb(rgb.r / 255, rgb.g / 255, rgb.b / 255)
			draw_circle(cr, height)
		end
		widget:emit_signal("widget::redraw_needed")
	end

	local function create_taglist_items(s)
		local widgets = { layout = wibox.layout.fixed.horizontal }

		local non_empty_color = get_color("tag_non_empty")
		local empty_color = get_color("tag_empty")
		local hover_color = get_color("tag_hover")

		for i, tag in pairs(s.tags) do
			local widget = make_circle_widget(color)
			widget.buttons = awful.button({}, 1,
				function() tag:view_only() end)

			local update_tags = function()
				if not (#tag:clients() == 0) then
					update_rgb(widget, non_empty_color)
				else
					update_rgb(widget, empty_color)
				end
			end
			client.connect_signal("tagged", update_tags)
			client.connect_signal("untagged", update_tags)

			local hover_timed = rubato.timed {
				intro = 0.075,
				duration = 0.2,
				awestore_compat = true
			}

			hover_timed:subscribe(function(pos)
				local col
				if not (#tag:clients() == 0) then
					col = non_empty_color
				else
					col = empty_color
				end
				col = interpolate(col, hover_color, pos)
				update_rgb(widget, col)
			end)

			widget:connect_signal("mouse::enter", function()
				tag.is_being_hovered = true
				hover_timed:set(1)

				if #tag:clients() > 0 then
					awesome.emit_signal("bling::tag_preview::update", tag)
					awesome.emit_signal("bling::tag_preview::visibility", s, true)
				end

			end)
			widget:connect_signal("mouse::leave", function()
				tag.is_being_hovered = false
				hover_timed:set(0)

				awesome.emit_signal("bling::tag_preview::visibility", s, false)
			end)

			table.insert(widgets,widget)
		end

		return widgets
	end

	local function draw_tag_indicator(cr, height, xpos)
		cr:arc(xpos, height/2, 12, 0, math.pi*2)
		cr:fill()
	end

	local function update_tag_indicator(widget, pos, rgb)
		widget.draw = function(self, context, cr, width, height)
			cr:set_source_rgb(rgb.r / 255, rgb.g / 255, rgb.b / 255)
			draw_tag_indicator(cr, height,
				height/2 + (pos - 1) * height)
		end
		widget:emit_signal("widget::redraw_needed")
	end

	local function create_tag_indicator(s)
		local col = get_color("tag_ind")

		local widget = wibox.widget{
			fit = function(self, context, width, height)
				return height, height
			end,

			draw = function(self, context, cr, width, height)
				cr:set_source_rgba(col.r / 255, col.g / 255, col.b / 255)
				draw_tag_indicator(cr, height, height/2)
			end,

			layout = wibox.widget.base.make_widget,
		}

		local index = 1

		local tag_indices = {}
		for i,tag in ipairs(s.tags) do tag_indices[tag] = i end

		local pos

		local timed = rubato.timed {
			duration = 0.3,
			intro = 0.15,
			pos = index,
			easing = rubato.quadratic,
			awestore_compat = true
		}

		timed:subscribe(function(_pos)
			pos = _pos
			update_tag_indicator(widget, pos, col)
		end)

		s:connect_signal("tag::history::update", function()
			if tag_indices[s.selected_tag] == widget.index then
				return
			end

			timed:set(tag_indices[s.selected_tag])
			index = tag_indices[s.selected_tag]
		end)

		return widget
	end

	s.test_taglist = wibox.widget{
		create_tag_indicator(s),
		create_taglist_items(s),
		layout = wibox.layout.stack
	}

	-- Wibars.
	local sgeo = s.geometry
	local gap = beautiful.useless_gap

	local width  = 190
	local height = 38

	local args = {
		x 	   	= sgeo.x + gap * 2,
		y 	   	= sgeo.y + gap,
		screen 	= s,
		width   = width,
		height 	= height,
		visible = true,
		border_width = beautiful.border_width,
		border_color = beautiful.secondary,
		shape = function(cr)
			gears.shape.rounded_rect(cr,width,height,beautiful.bar_corner_radius)
		end
	}

	s.tagbar = wibox(args)

	s.tagbar:setup {
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",

			-- Left.
			nil,

			-- Middle.
			s.test_taglist,

			-- Right.
		},
		bottom = beautiful.border_width * 2 + 2,
		top = 2,
		left = 2,
		right = beautiful.border_width * 2 + 2,
		color = beautiful.bg_normal,
		widget = wibox.container.margin
	}

	width = 90
	args.width = width

	args.x = sgeo.x + sgeo.width - width - gap * 2

	s.clockbar = wibox(args)

	s.clockbar:setup {
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",

			-- Left.
			nil,

			-- Middle.
			mytextclock,

			-- Right.
		},
		bottom = beautiful.border_width * 2 + 5,
		top = 5,
		left = 10,
		right = beautiful.border_width * 2 + 10,
		color = beautiful.bg_normal,
		widget = wibox.container.margin
	}

	old_width = args.width
	width = 50
	args.width = width

	args.x = sgeo.x + sgeo.width - width - old_width - gap * 4

	s.volumebar = wibox(args)

	s.volumebar:setup {
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",

			-- Left.
			nil,

			-- Middle.
			myvolumewidget,

			-- Right.
		},
		bottom = beautiful.border_width * 2 + 5,
		top = 5,
		left = 10,
		right = beautiful.border_width * 2 + 10,
		color = beautiful.bg_normal,
		widget = wibox.container.margin
	}
    volume_width = args.width
	width = 100
	args.width = width

	args.x = sgeo.x + sgeo.width - width - old_width - volume_width - gap * 6

	s.cpubar = wibox(args)

	s.cpubar:setup {
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",

			-- Left.
			nil,

			-- Middle.
			cpu_widget,

			-- Right.
		},
		bottom = beautiful.border_width * 2 + 5,
		top = 5,
		left = 10,
		right = beautiful.border_width * 2 + 20,
		color = beautiful.bg_normal,
		widget = wibox.container.margin
	}
    cpu_width = args.width
	width = 100
	args.width = width

	args.x = sgeo.x + sgeo.width - width - old_width - volume_width - cpu_width - gap * 8

	s.rambar = wibox(args)

	s.rambar:setup {
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",

			-- Left.
			nil,

			-- Middle.
			ram_widget,

			-- Right.
		},
		bottom = beautiful.border_width * 2 + 5,
		top = 5,
		left = 10,
		right = beautiful.border_width * 2 + 20,
		color = beautiful.bg_normal,
		widget = wibox.container.margin
	}

	s.padding = height + gap * 2

	tray = nil
	if s == screen.primary then
		tray = mysystemtray
	end
end)
