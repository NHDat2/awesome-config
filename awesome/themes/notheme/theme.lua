local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi
local my_table = awful.util.table

-- Theme Definition {{{
local theme = {}
theme.dir = os.getenv("HOME").."/.config/awesome/themes/notheme/"

-- Fonts
theme.font_name = "Iosevka Nerd Font"

theme.font = "Iosevka Nerd Font 9"
theme.taglist_font = "FiraMono Nerd Font Mono 15"
theme.icon_font = "Iosevka Nerd Font 12"
theme.exit_screen_font = "FiraMono Nerd Font Mono 120"
theme.widget_font = 'Iosevka Nerd Font 8'
theme.notification_font = "Iosevka Nerd Font 12"
theme.tasklist_font = "Iosevka Nerd Font 7"

-- colors
theme.clr = {
	purple = "#b782da",
	blue = "#729aef",
	green = "#7cd380",
	red = '#ff5370',
	gray = '#97a6c0',
	yellow = '#ffcb6b'
}
theme.fg_normal = '#525770'
theme.fg_dark = '#424750'
theme.fg_focus = '#b6bcdd'
theme.fg_urgent = '#525770'

theme.bg_normal = '#222632'
theme.bg_focus = '#222632'
theme.bg_urgent = "#182228"
theme.bg_light = '#2f2f3f'
theme.bg_systray = theme.bg_normal
theme.systray_icon_spacing = dpi(10)

theme.tasklist_bg_normal = '#282838'
theme.tasklist_bg_focus = '#2f2f3f'
theme.tasklist_bg_urgent = '#2b2b3b'

theme.prompt_fg = '#868cad'

theme.taglist_bg_focus = theme.bg_light
theme.taglist_fg_occupied = theme.clr.blue
theme.taglist_fg_urgent = theme.clr.red
theme.taglist_fg_empty = theme.clr.gray
theme.taglist_fg_focus = theme.clr.green

theme.notification_fg = '#a6accd'
theme.notification_bg = '#222632'
theme.notification_opacity = 1

theme.border_normal = '#20253e'
theme.border_focus = '#545277'
theme.border_marked = '#424760'

theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = dpi(2)
theme.gap_single_client = true

-- assests
theme.titlebar_close_button_normal = theme.dir.."./assets/close-button.svg"
theme.titlebar_close_button_focus = theme.dir.."./assets/close-button.svg"

theme.titlebar_minimize_button_normal = theme.dir.."./assets/minimize-button.svg"
theme.titlebar_minimize_button_focus = theme.dir.."./assets/minimize-button.svg"

theme.titlebar_maximized_button_normal = theme.dir.."./assets/maximized-button.svg"
theme.titlebar_maximized_button_focus = theme.dir.."./assets/maximized-button.svg"

theme.layout_fairh = theme.dir.."layouts/fairhw.png"
theme.layout_fairv = theme.dir.."layouts/fairvw.png"
theme.layout_floating  = theme.dir.."layouts/floatingw.png"
theme.layout_magnifier = theme.dir.."layouts/magnifierw.png"
theme.layout_max = theme.dir.."layouts/maxw.png"
theme.layout_fullscreen = theme.dir.."layouts/fullscreenw.png"
theme.layout_tilebottom = theme.dir.."layouts/tilebottomw.png"
theme.layout_tileleft   = theme.dir.."layouts/tileleftw.png"
theme.layout_tile = theme.dir.."layouts/tilew.png"
theme.layout_tiletop = theme.dir.."layouts/tiletopw.png"
theme.layout_spiral  = theme.dir.."layouts/spiralw.png"
theme.layout_dwindle = theme.dir.."layouts/dwindlew.png"
theme.layout_cornernw = theme.dir.."layouts/cornernww.png"
theme.layout_cornerne = theme.dir.."layouts/cornernew.png"
theme.layout_cornersw = theme.dir.."layouts/cornersww.png"
theme.layout_cornerse = theme.dir.."layouts/cornersew.png"

-- naughty configuration
theme.notification_border_color = theme.bg_light
theme.notification_border_width = dpi(5)

naughty.config.padding = dpi(8)
naughty.config.defaults = {
	timeout = 5,
	text = "",
	ontop = true,
	position = "top_right",
	margin = dpi(10),
}

-- }}}


-- Separators
local spr = wibox.widget.textbox('     ')
local half_spr = wibox.widget.textbox('  ')

-- widgets {{{
local function line(color)
	return (
		wibox.container.background(
			wibox.widget.textbox(
				'<span font="'..theme.widget_font..'" color="'..color..'">@</span>'
			),
			color
		)
	)
end

-- Clock
local clockicon = wibox.widget.textbox(
	string.format('<span color="%s" font="'..theme.icon_font..'"></span>', theme.clr.purple)
)
local clock = wibox.widget.textclock(
	'<span font="'..theme.widget_font..'" color="'..theme.clr.purple..'"> %R</span>'
)

local clock =
	{
		layout = wibox.layout.fixed.horizontal,
		half_spr,
		clockicon,
		clock,
		half_spr
	}

-- Calendar
local calendaricon = wibox.widget.textbox(
	string.format('<span color="%s" font="'..theme.icon_font..'"></span>', theme.clr.yellow)
)
local calendar = wibox.widget.textclock(
	'<span font="'..theme.widget_font..'" color="'..theme.clr.yellow..'"> %x</span>'
)

local calendar =
	{
		layout = wibox.layout.fixed.horizontal,
		half_spr,
		calendaricon,
		calendar,
		half_spr
	}

-- Battery
local baticon = wibox.widget.textbox('')
function theme.update_baticon(icon)
	baticon:set_markup(
		string.format('<span color="%s" font="'..theme.icon_font..'">%s</span>', theme.clr.blue, icon)
	)
end

local bat = wibox.widget.textbox('')
function theme.update_battery()
	awful.spawn.easy_async_with_shell(
	[[bash -c "echo $(acpi|awk '{split($0,a,", "); print a[2]}')"]],
	function(stdout)
		if stdout == '' then
			bat:set_markup('<span color="'..theme.clr.blue..'" font="'..theme.widget_font..'"> N/A</span>')
			return
		end
		stdout = stdout:gsub("%%", ""):match("^%s*(.-)%s*$")
		percent = tonumber(stdout)
		if percent <= 5 then
			theme.update_baticon('')
		elseif percent <= 25 then
			theme.update_baticon('')
		elseif percent >= 25 and percent <= 75 then
			theme.update_baticon('')
		elseif percent < 100 then
			theme.update_baticon('')
		else
			theme.update_baticon('')
		end
			
		bat:set_markup('<span color="'..theme.clr.blue..'" font="'..theme.widget_font..'"> ' ..stdout.."%</span> ")
	end)
end
theme.update_battery()

local battery =
	{
		layout = wibox.layout.fixed.horizontal,
		half_spr,
		baticon,
		bat,
		half_spr,
	}

-- ALSA volume
local volicon = wibox.widget.textbox('')
local vol = wibox.widget.textbox('')
theme.update_volume = function()
	awful.spawn.easy_async_with_shell([[
		if amixer get Master | grep -q '\[on\]'; then
			grep 'Left:' <(amixer sget Master)|awk -F"[][]" '{ print $2 }'
		else
			echo 'muted'
		fi
	]], function(stdout)
		stdout = tostring(stdout):gsub("\n", ''):gsub("%%", ""):match("^%s*(.-)%s*$")
		percent = tonumber(stdout)
		if stdout == "muted" then
			volicon:set_markup('<span color="'..theme.clr.green..'" font="'..theme.icon_font..'">婢</span>')
		elseif percent == 0 then
			volicon:set_markup('<span color="'..theme.clr.green..'" font="'..theme.icon_font..'"></span>')
		elseif percent <= 50 then
			volicon:set_markup('<span color="'..theme.clr.green..'" font="'..theme.icon_font..'">奔</span>')
		else
			volicon:set_markup('<span color="'..theme.clr.green..'" font="'..theme.icon_font..'">墳</span>')
		end
		vol:set_markup('<span color="'..theme.clr.green..'" font="'..theme.widget_font..'"> '..stdout.."%</span> ")
	end)
end
theme.update_volume()

local volume =
	{
		layout = wibox.layout.fixed.horizontal,
		half_spr,
		volicon,
		vol,
		half_spr,
	}

-- power
local power_menu = { }
local power = wibox.widget.textbox('<span font="'..theme.icon_font..'" color="'..theme.fg_focus..'">⏾</span>')

power:connect_signal("mouse::enter", function()
	power:set_markup('<span font="'..theme.icon_font..'" color="'..theme.clr.blue..'">⏾</span>')
end)

power:connect_signal("mouse::leave", function()
	power:set_markup('<span font="'..theme.icon_font..'" color="'..theme.fg_focus..'">⏾</span>')
end)

power:connect_signal("button::press", function()
	if power_menu.visible == nil then
		local logout = wibox.widget.textbox(
			'<span font="'..theme.exit_screen_font..'" color="'..theme.clr.purple..'"></span>'
		)

		local poweroff = wibox.widget.textbox(
			'<span font="'..theme.exit_screen_font..'" color="'..theme.clr.blue..'">⏻</span>'
		)

		local reboot = wibox.widget.textbox(
			'<span font="'..theme.exit_screen_font..'" color="'..theme.clr.green..'">ﰇ</span>'
		)

		local close = wibox.widget.textbox(
			'<span font="'..theme.exit_screen_font..'" color="'..theme.clr.red..'"></span>'
		)
		power_menu = awful.popup {
			ontop = true,
			visible = true,
			bg = theme.bg_light.."cc",
			fg = theme.fg_focus,
			placement = awful.placement.maximize,
			widget = {
				{
					{
						{
							{
								spr,
								layout = wibox.layout.fixed.horizontal,
							},
							widget = wibox.container.place,
						},
						{
							{
								spr, spr, spr,
								spr, spr,
								logout,
								spr, spr, spr,
								spr, spr,
								poweroff,
								spr, spr, spr,
								spr, spr,
								reboot,
								spr, spr, spr,
								spr, spr,
								layout = wibox.layout.fixed.horizontal,
							},
							widget = wibox.container.place,
						},
						{
							{
								close,
								layout = wibox.layout.align.horizontal,
							},
							widget = wibox.container.place,
						},
						layout = wibox.layout.fixed.vertical,
					},
					margins = dpi(20),
					widget = wibox.container.margin
				},
				widget = wibox.container.background,
			},
		}

		logout:connect_signal("button::press", function()
			awful.util.spawn("pkill X")
		end)

		poweroff:connect_signal("button::press", function()
			awful.util.spawn("doas poweroff")
		end)

		reboot:connect_signal("button::press", function()
			awful.util.spawn("doas reboot")
		end)
		close:connect_signal("button::press", function()
			power_menu.visible = false
		end)
	else power_menu.visible = not power_menu.visible end
end)
-- }}}

-- load theme options {{{
function theme.at_screen_connect(s)
	gears.wallpaper.maximized(theme.dir.."/tile.jpeg", s)

	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.layouts)

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(awful.button({}, 1, function()
		awful.layout.inc(1)
	end), awful.button({}, 2, function()
		awful.layout.set(awful.layout.layouts[1])
	end), awful.button({}, 3, function()
		awful.layout.inc(-1)
	end), awful.button({}, 4, function()
		awful.layout.inc(1)
	end), awful.button({}, 5, function()
		awful.layout.inc(-1)
	end)))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist {
		screen = s,
		filter = awful.widget.taglist.filter.all,
		widget_template = {
			{
				{
					id = 'text_role',
					widget = wibox.widget.textbox,
				},
				layout = wibox.layout.align.horizontal,
			},
			left = 10,
			right = 10,
			widget = wibox.container.margin,
		},
		buttons = awful.util.taglist_buttons
	}
	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = awful.util.tasklist_buttons,
		widget_template = {
			{
				wibox.widget.base.make_widget(),
				forced_height = 5,
				id            = 'background_role',
				widget        = wibox.container.background,
			},
			{
				{
					id     = 'clienticon',
					widget = awful.widget.clienticon,
				},
				margins = 5,
				widget  = wibox.container.margin
			},
			nil,
			create_callback = function(self, c, index, objects) --luacheck: no unused args
				self:get_children_by_id('clienticon')[1].client = c
			end,
			layout = wibox.layout.align.vertical,
		},
	}

	s.mywibox = awful.wibar {
		width = dpi(1360),
		height = dpi(30),
		ontop = false,
		screen = s,
		expand = true,
		visible = true,
		bg = theme.bg_normal,
		border_width = dpi(2),
		border_color = theme.bg_light,
		position = "top",
	}

	s.mywibox:setup {
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			{
				layout = wibox.layout.fixed.horizontal,
				{
					{
						layout = wibox.layout.align.horizontal,
						s.mypromptbox,
						half_spr,
						s.mylayoutbox,
						half_spr
					},
					widget = wibox.container.background,
				},
				half_spr,
				{
					layout = wibox.layout.align.horizontal,
					s.mytaglist,
				},
				{
						layout = wibox.layout.fixed.horizontal,
						half_spr,
						wibox.container.margin(
							wibox.widget.systray(),
							dpi(3), dpi(3), dpi(3), dpi(3)
						),
						half_spr,
				},
				half_spr,
			},
			widget = wibox.container.margin,
			top = dpi(5),
			bottom = dpi(5),
			right = dpi(5),
			left = dpi(5)
		},
		{ -- Center widgets
			layout = wibox.container.place,
			s.mytasklist,
		},
		{ -- Right widgets
			{
				layout = wibox.layout.fixed.horizontal,
				spr,
				spr,
				half_spr,
				clock,
				half_spr,
				calendar,
				half_spr,
				volume,
				half_spr,
				battery,
			},
			widget = wibox.container.margin,
			top = dpi(5),
			bottom = dpi(5),
			right = dpi(5),
			left = dpi(5)
		},
	}

	s.mywibox:struts {
		bottom = dpi(35),
	}
end
-- }}}

return theme
