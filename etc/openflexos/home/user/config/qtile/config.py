#############################################################
############### Import/from Modules #########################
#############################################################
import os
import subprocess
import threading
import time
from libqtile import bar, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile import hook
from libqtile.widget import TextBox

from qtile_extras.widget.decorations import PowerLineDecoration
from qtile_extras import widget

import json
with open(os.path.expanduser("~/.config/themes.json")) as f:
    data = json.load(f)

theme_name = data["current"]
colors = data["themes"][theme_name]

powerlineleft = {
    "decorations": [
        PowerLineDecoration(
            path="arrow_left",
            filled=True,
            size=20,
            padding_y=0,
        )
    ]
}

powerlineright = {
    "decorations": [
        PowerLineDecoration(
            path="arrow_right",
            filled=True,
            size=20,
            padding_y=0,
        )
    ]
}

#############################################################
############### Functions ###################################
#############################################################

# Function to get script's Path to then call on later
import os

def get_script_path(script_name):
    """
    Search recursively under ~/.config/qtile/scripts for the given script name.
    Supports both 'OpenFlexOS_Power.sh' and 'Power' style names.
    Returns the first full path found, or None if not found.
    """

    base_dir = os.path.expanduser("~/.config/qtile/scripts")

    # Build possible filename variants
    # This lets you call get_script_path("OpenFlexOS_Power.sh") OR get_script_path("Power")
    name_core = script_name.replace("OpenFlexOS_", "").replace(".sh", "")
    variants = [
        script_name,                       # e.g. "OpenFlexOS_Power.sh"
        f"{name_core}",                    # e.g. "Power"
        f"{name_core}.sh",                 # e.g. "Power.sh"
        f"OpenFlexOS_{name_core}.sh",      # e.g. "OpenFlexOS_Power.sh"
    ]

    try:
        for root, dirs, files in os.walk(base_dir):
            for f in files:
                if f in variants:
                    return os.path.join(root, f)
    except Exception as e:
        print(f"[Qtile] get_script_path error: {e}")

    # Fallback: try direct join guesses (non-recursive)
    for variant in variants:
        guess = os.path.join(base_dir, variant)
        if os.path.exists(guess):
            return guess

    print(f"[Qtile] get_script_path: no match for {script_name} (variants tried: {variants})")
    return None

# Function to auto-start applicaions/proesses at login
@hook.subscribe.startup_once
def autostart():
    home_dir = os.path.expanduser("~")
    script = os.path.join(home_dir, ".config", "qtile", "OpenFlexOS_AutoStart.sh")
    subprocess.Popen([script])

# Allow Copy Info
def copy_info_widget():
    text = qtile.widgets_map["Info"].text

    # Split on first ":" and trim whitespace
    if ":" in text:
        text = text.split(":", 1)[1].strip()

    subprocess.run(
        ["xclip", "-selection", "clipboard"],
        input=text,
        text=True,
    )

def battery_widget():
    if os.path.exists("/sys/class/power_supply/BAT1"):
        return widget.Battery(
            battery="BAT1",
            charge_char="󰂄",
            discharge_char="",
            full_char="",
            format="{char} {percent:2.0%}",  # Ensure "Full" text is removed
            show_short_text=False,  # Prevents Qtile from displaying "Full"
            update_interval=1,
            foreground=colors["fg"],
            background=colors["bg"],

        )
    else:
         return widget.TextBox(text="", width=0,)

# Function to display a icon for network status. x icon disconnected, wifi for connected to wifi, Desktop pc for ethernet. see OpenFlexOS_NerdDictation.sh
def get_nmcli_output():
    return subprocess.check_output([get_script_path("OpenFlexOS_Network.sh")]).decode("utf-8").strip()

# Function for Resize Floating Windows, See "keys =" for seting Keybindings
@lazy.function
def resize_floating_window(qtile, width: int = 0, height: int = 0):
    w = qtile.current_window
    w.cmd_set_size_floating(w.width + width, w.height + height)

#############################################################
############### Class #######################################
#############################################################

# Function to display Screen brightnless and allow left click and right click
class BrightnessWidget(TextBox):
    def __init__(self):
        super().__init__(foreground=colors["fg"], background=colors["bg"], padding=8, )
        self.brightness()
        # Add callbacks to the widget
        self.add_callbacks({'Button1': self.on_left_click, 'Button3': self.on_right_click})
    def brightness(self):
        # Run your OpenFlexOS_Brightness.sh script to get the volume level or mute state
        result = subprocess.run([get_script_path("OpenFlexOS_Brightness.sh")], capture_output=True, text=True)
        self.text = result.stdout.strip()
        self.draw()
    def on_left_click(self):
        subprocess.run([get_script_path("OpenFlexOS_Brightness.sh"), "-u"])
        self.brightness()
    def on_right_click(self):
        subprocess.run([get_script_path("OpenFlexOS_Brightness.sh"), "-d"])
        self.brightness()

# class VolumeWidget(TextBox):
class VolumeWidget(widget.TextBox):
    def __init__(self):
        super().__init__(
            foreground=colors["fg"],
            background=colors["color1"],
            padding=8,
            **powerlineright,
        )

        self.update_interval = 1

        self.update()
        self._schedule()

        self.add_callbacks({
            "Button1": self.vol_up,
            "Button2": self.vol_mute,
            "Button3": self.vol_down,
        })

    def _schedule(self):
        # ✔ Safe scheduling (works only when Qtile is running)
        if qtile is not None and hasattr(qtile, "call_later"):
            qtile.call_later(self.update_interval, self._refresh)

    def _refresh(self):
        self.update()
        self._schedule()

    def update(self):
        result = subprocess.run(
            [get_script_path("OpenFlexOS_Volume.sh")],
            capture_output=True,
            text=True
        )
        self.text = result.stdout.strip()

        # ✔ Safe redraw (runs only inside Qtile)
        if hasattr(self, "bar") and self.bar:
            self.bar.draw()

    def vol_up(self):
        subprocess.run([get_script_path("OpenFlexOS_Volume.sh"), "-u"])
        self.update()

    def vol_mute(self):
        subprocess.run([get_script_path("OpenFlexOS_Volume.sh"), "-m"])
        self.update()

    def vol_down(self):
        subprocess.run([get_script_path("OpenFlexOS_Volume.sh"), "-d"])
        self.update()

class nerd_dictation(TextBox):
    def __init__(self):
        super().__init__(foreground=colors["fg"], background=colors["bg"], padding=8, )
        self.nerd()
        # Add callbacks to the widget
        self.add_callbacks({'Button1': self.on_left_click,'Button3': self.on_right_click})
    def nerd(self):
        result = subprocess.run([get_script_path("OpenFlexOS_NerdDictation.sh")], capture_output=True, text=True)
        self.text = result.stdout.strip()
        self.draw()
    def on_left_click(self):
        subprocess.run([get_script_path("OpenFlexOS_NerdDictation.sh"), "-s"])
        self.nerd()
    def on_right_click(self):
        subprocess.run([get_script_path("OpenFlexOS_NerdDictation.sh"), "-S"])
        self.nerd()

#############################################################
############### Widgets #####################################
#############################################################
nmcli_widget = widget.GenPollText(
    func=get_nmcli_output,
    update_interval=1,
    fmt='{} ',  # You can customize the formatting here
    mouse_callbacks={
    'Button1': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Network.sh") + " -d"),
    'Button3': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Network.sh") + " -r"),
    },
    foreground=colors["fg"],
    background=colors["color4"],
    padding=8,
    **powerlineright,
)

#############################################################
############### Bar #######################################
#############################################################

def init_widgets_list():
    widgets_list = [
    # This Spacer below is to add a few pixels and set it to the same background as the first widget. Maybe help full when using picom with rounded conors

#widget.Spacer(length=8, background=colors["bg"]),
#
#widget.TextBox(
#    text="",
#    fontsize=15,
#    padding=8,
#    foreground=colors["fg"],
#    background=colors["color3"],
#    mouse_callbacks={
#        'Button1': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Applications.sh") + " -d"),
#        'Button3': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Applications.sh") + " -r"),
#    },
#    **powerlineleft,
#),

widget.Clock(
    foreground=colors["fg"],
    background=colors["color1"],
    format="  %a %d-%m-%Y",
    padding=8,
    **powerlineleft,
),

widget.Clock(
    foreground=colors["fg"],
    background=colors["color4"],  # changed from bg
    format="  %I:%M:%S %p",
    padding=8,
    **powerlineleft,
),

widget.CPU(
    format=' {load_percent}%',
    foreground=colors["fg"],
    background=colors["color3"],  # not bg!
    padding=8,
    **powerlineleft,
),

widget.Memory(
    foreground=colors["fg"],
    format=' {MemPercent}%',
    background=colors["color3"],
    padding=8,
    **powerlineleft,
),






            widget.WindowName(
                foreground=colors["fg"],
                background=colors["color1"],
                scroll=True,
                scroll_delay=2,
                scroll_interval=0.1,
                scroll_step=2,
                scroll_repeat=True,
                scroll_clear=False,
                scroll_fixed_width=True,
                width=100,
                padding=8,
                **powerlineleft,
            ),

            widget.Spacer(),
            widget.GroupBox(
                highlight_method='block',
                highlight_color=colors["fg"],  # Set this to black or your desired block color
                this_current_screen_border=colors["color1"],  # Optional: controls text/border color for current screen
                background=colors["bg"],
                padding_x=8,  # Horizontal padding around group names
                padding_y=8,  # Vertical padding (optional)
            ),
            widget.Spacer(
                background=colors["bg"],
                **powerlineright


            ),
            widget.Systray(
                background=colors["color1"],
                **powerlineright


            ),

            widget.CurrentLayout(
                fmt=" {}",
                foreground=colors["fg"],
                background=colors["color3"],
                padding=8,
                **powerlineright
            ),

            VolumeWidget(),

            widget.GenPollText(
                name="updates",
                update_interval=30,
                func=lambda: subprocess.run(
                    [get_script_path("OpenFlexOS_UpdateCheck.sh")],
                    capture_output=True,
                    text=True
                ).stdout.strip(),
                background=colors["color2"],
                foreground=colors["fg"],
                padding=8,
                mouse_callbacks={
                    'Button1': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_UpdateCheck.sh") + " -u"),
                    'Button3': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_UpdateCheck.sh") + " -v"),
                },
                **powerlineright
            ),
            nmcli_widget,  # (Network Widget) A Script runs and displays an icon depending on if connected to wifi, ethernet, or disconnected

widget.GenPollText(
    name="Info",
    update_interval=1,
    padding=8,
    func=lambda: subprocess.run(
        [get_script_path("OpenFlexOS_Info.sh")],
        capture_output=True,
        text=True,
        timeout=2
    ).stdout.strip(),
    mouse_callbacks={
        'Button1': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Info.sh") + " -n"),
        'Button3': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Info.sh") + " -p"),
        'Button2': copy_info_widget,  # middle-click copy
    },
    **powerlineright
),

           widget.GenPollText(
                name="menu",
                update_interval=30,
                func=lambda: subprocess.run(
                    [get_script_path("OpenFlexOS_Menu.sh")],
                    capture_output=True,
                    text=True
                ).stdout.strip(),
                background=colors["color1"],
                foreground=colors["fg"],
                padding=8,
                mouse_callbacks={
                    'Button1': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Menu.sh") + " -d"),
                    'Button3': lambda: qtile.cmd_spawn(get_script_path("OpenFlexOS_Menu.sh") + " -r"),
                },

            ),
    #This Spacer below is to add a few pixels and set it to the same background as the last widget. Maybe help full when using picom with rounded conors
    #widget.Spacer(length=8,background=colors["bg"],),
        ]
    return widgets_list

def init_widgets_screen1():
    widgets_screen1 = init_widgets_list()
    return widgets_screen1

def init_widgets_screen2():
    widgets_screen2 = init_widgets_list()
    # Remove Widgets by counting the number of widgets and use the number of that widget starting from 0, EG remove first widget use 0 [0] or [0:4] below
    # 10=systray
    del widgets_screen2[10]
    return widgets_screen2

def init_screens():
    return [Screen(top=bar.Bar(widgets=init_widgets_screen1(), font="JetBrainsMono Nerd Font", margin=[20, 18, 0, 18], size=24, background=colors["bg"])),
            Screen(top=bar.Bar(widgets=init_widgets_screen2(), font="JetBrainsMono Nerd Font", margin=[20, 18, 0, 18], size=24, background=colors["bg"])),
            Screen(top=bar.Bar(widgets=init_widgets_screen2(), font="JetBrainsMono Nerd Font",  margin=[20, 18, 0, 18], size=24, background=colors["bg"]))]

if __name__ in ["config", "__main__"]:
    screens = init_screens()
    widgets_list = init_widgets_list()
    widgets_screen1 = init_widgets_screen1()
    widgets_screen2 = init_widgets_screen2()

#############################################################
############### Variables ###################################
#############################################################

# Alternative modifier key (Alt key)
alt = "mod1"

# Primary modifier key (Super/Windows key)
mod = "mod4"

# Automatically detect the default terminal emulator
terminal = guess_terminal()

# No key bindings for dynamically assigned groups
dgroups_key_binder = None

# No specific application rules for dynamic groups
dgroups_app_rules = []  # type: list

# Focus follows the mouse cursor when hovering over a window
follow_mouse_focus = True

# Clicking on a window does not bring it to the front
bring_front_click = False

# Keep floating windows above tiled windows
floats_kept_above = True

# Disable cursor warping when switching focus between windows
cursor_warp = False

# Enable automatic fullscreen for certain applications
auto_fullscreen = True

# Automatically focus on newly opened windows based on context
focus_on_window_activation = "smart"

# Reload screen configurations when they change (e.g., external monitors)
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on thef
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"

#############################################################
############### KeyBindings #################################
#############################################################

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html

    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),

    # Grow/resize Windows in monadtall
    Key([mod], "i", lazy.layout.grow()),
    Key([mod], "m", lazy.layout.shrink()),

    # Grow/shrink/resize in floating mode
    Key([alt], "l", resize_floating_window(width=10), desc="Increase width by 10"),
    Key([alt], "h", resize_floating_window(width=-10), desc="Decrease width by 10"),
    Key([alt], "j", resize_floating_window(height=10), desc="Increase height by 10"),
    Key([alt], "k", resize_floating_window(height=-10), desc="Decrease height by 10"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),

    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),

    Key(
        [mod], "f", lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),

    Key([mod], "t", lazy.window.toggle_floating(), desc="Toggle floating on the focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),

    # Start of My Config: setting my own keys
    Key([alt], "c", lazy.spawn("caja"), desc="Launch Caja"),
    Key([alt], "f", lazy.spawn("firefox"), desc="Launch Firefox"),
    Key([alt], "b", lazy.spawn("brave --password-store=basic"), desc="Launch Brave"),
    Key([mod, alt], "b", lazy.spawn([get_script_path("OpenFlexOS_NerdDictation.sh "), "start"]), desc="begin/start nerd dictation"),
    Key([mod, alt], "e", lazy.spawn([get_script_path("OpenFlexOS_NerdDictation.sh "), "stop"]), desc="end/stop nerd dictation"),
    Key([], "XF86AudioRaiseVolume", lazy.spawn(get_script_path("OpenFlexOS_Volume.sh") + " -u"), desc="Increase volume"),
    Key([], "XF86AudioLowerVolume", lazy.spawn(get_script_path("OpenFlexOS_Volume.sh") + " -d"), desc="Decrease volume"),
    Key([], "XF86AudioMute", lazy.spawn(get_script_path("OpenFlexOS_Volume.sh") + " -m"), desc="Mute/Unmute"),

    # Key Chord for Applications Menu
    KeyChord([alt], "a", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_Applications.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_Applications.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Launcher"),

    # Key Chord for Power Menu
    KeyChord([alt], "p", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_Power.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_Power.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Power"),

    # Key Chord for SSH Menu
    KeyChord([alt], "s", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_SSH.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_SSH.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="SSH"),


    # Key Chord for Network Menu
    KeyChord([alt], "m", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_Menu.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_Menu.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Launcher"),

    # Key Chord for Network Menu
    KeyChord([alt], "n", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_Network.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_Network.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Launcher"),

    # Key Chord for Network Menu
    KeyChord([alt], "n", [
        Key([], "d",
            lazy.spawn(get_script_path("OpenFlexOS_Network.sh") + " -d"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "r",
            lazy.spawn(get_script_path("OpenFlexOS_Network.sh") + " -r"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Launcher"),

    # Key Chord for Updates
    KeyChord([alt], "u", [
        Key([], "u",
            lazy.spawn(get_script_path("OpenFlexOS_UpdateCheck.sh") + " -u"),
            lazy.ungrab_chord(),
            desc="Dmenu"
        ),
        Key([], "v",
            lazy.spawn(get_script_path("OpenFlexOS_UpdateCheck.sh") + " -v"),
            lazy.ungrab_chord(),
            desc="Rofi"
        ),
    ], mode="Launcher"),

    # Key Chord for Flameshot(screenshot)
    KeyChord([alt], "i", [
        Key([], "g",
            lazy.spawn("flameshot gui"),
            lazy.ungrab_chord(),
            desc="Take a full screenshot with Flameshot"
        ),
        Key([], "s",
            lazy.spawn("flameshot screen"),
            lazy.ungrab_chord(),
            desc="Take a full screenshot with Flameshot"
        ),
        Key([], "f",
            lazy.spawn("flameshot full"),
            lazy.ungrab_chord(),
            desc="Take a full screenshot with Flameshot"
        ),
    ], mode="Screenshot"),

    KeyChord([alt], "e", [
        Key([], "r",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WebBookmarker.sh -r"),
            lazy.ungrab_chord(),
            desc="Use Rofi with WebBookmaker"
        ),
        Key([], "d",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WebBookmarker.sh -d"),
            lazy.ungrab_chord(),
            desc="Use Dmenu with WebBookmaker"
        ),
    ], mode="WebBookmaker"),

    KeyChord([alt], "w", [
        Key([], "s",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WallpaperChanger.sh -s"),
            lazy.ungrab_chord(),
            desc="Select a static wallpaper"
        ),
        Key([], "r",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WallpaperChanger.sh -r"),
            lazy.ungrab_chord(),
            desc="Select a random wallpaper"
        ),
        Key([], "b",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WallpaperChanger.sh -b"),
            lazy.ungrab_chord(),
            desc="Start a wallpaper cycle"
        ),
        Key([], "e",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WallpaperChanger.sh -e"),
            lazy.ungrab_chord(),
            desc="Stop a wallpaper cycle"
        ),
        Key([], "l",
            lazy.spawn("/etc/openflexos/usr/local/bin/OpenFlexOS_WallpaperChanger.sh -l"),
            lazy.ungrab_chord(),
            desc="Start a full screen slideshow"
        ),
    ], mode="Wallpaper_changer"),
    # End of My Config: setting my own keys
]

#############################################################
############### Miscellaneous ###############################
#############################################################
layouts = [
    layout.MonadTall(margin=15,border_focus=colors["fg"],border_width=8,),
    layout.MonadWide(margin=15,border_focus=colors["fg"],border_width=8,),
    layout.RatioTile(margin=15,border_focus=colors["fg"],border_width=8,),
    layout.TreeTab(),
]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

widget_defaults = dict(
    font="sans",
    fontsize=12,
    padding=2,
)

floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="zenity"),
        Match(wm_class="tilda"),
    ]
)

extension_defaults = widget_defaults.copy()

#############################################################
############### For Loops ###################################
#############################################################

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


# --- Define static groups (permanent workspaces) ---
static_groups = ["1", "2", "3", "4"]
groups = [Group(i) for i in static_groups]

# --- Dynamic workspace creation ---
@lazy.function
def go_to_or_create_group(qtile, group_name):
    """Go to group if it exists, otherwise create it dynamically."""
    if group_name not in qtile.groups_map:
        qtile.add_group(group_name)
    qtile.groups_map[group_name].toscreen()

@lazy.function
def move_window_to_group(qtile, group_name):
    """Move focused window to a group, creating it if necessary."""
    if group_name not in qtile.groups_map:
        qtile.add_group(group_name)
    window = qtile.current_window
    if window is not None:
        window.togroup(group_name)
        # Optional: also switch to that group
        qtile.groups_map[group_name].toscreen()

# --- Keybindings for mod+[1–9] and mod+shift+[1–9] ---
for i in range(1, 10):
    keys.extend([
        # Switch to workspace (create if needed)
        Key([mod], str(i),
            go_to_or_create_group(str(i)),
            desc=f"Go to or create group {i}"),
        # Move focused window to workspace (create if needed)
        Key([mod, "shift"], str(i),
            move_window_to_group(str(i)),
            desc=f"Move window to group {i}")
    ])

# --- Hooks to clean up empty dynamic groups ---
@hook.subscribe.client_killed
def remove_empty_dynamic_groups(client):
    """Delete dynamic groups when their last window closes."""
    group = client.group
    if group.name not in static_groups and len(group.windows) == 0:
        # Delay slightly to allow Qtile to update internal state
        client.qtile.call_later(0.5, lambda: client.qtile.delete_group(group.name))

@hook.subscribe.setgroup
def remove_empty_groups_on_switch():
    """Also delete empty dynamic groups when switching away."""
    current_group = qtile.current_group
    for g in list(qtile.groups_map.values()):
        if g.name not in static_groups and g != current_group:
            if len(g.windows) == 0:
                qtile.delete_group(g.name)
