---@module 'hl'

--############################

--## ENVIRONMENT VARIABLES ###

--############################

-- See https://wiki.hypr.land/Configuring/Environment-variables/

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", 20)
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", 20)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("WAYLAND_DISPLAY", "wayland-1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("TFA_DEVICE", "/dev/dri/renderD128")
hl.env("ffmpeg_vaapi_device", "/dev/dri/renderD128")


hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
