# Звук: выходы и входы PipeWire, устройство по умолчанию — wpctl.

# Тип (sink/source), id, имя, подробность («-» — нет), по умолчанию (0/1).
# Имя — node.nick (у HDMI это монитор: «LG FHD»), подробность — профиль («HDMI / DisplayPort 1 Output»).
audio_nodes() {
	pw-dump 2>/dev/null | jq -r '
		([.[] | select(.type == "PipeWire:Interface:Metadata" and .props["metadata.name"] == "default")
		  | .metadata[]? | select(.key == "default.audio.sink" or .key == "default.audio.source")
		  | {(.key): .value.name}] | add // {}) as $def
		| .[] | select(.type == "PipeWire:Interface:Node") | .info.props as $p
		| select($p["media.class"] == "Audio/Sink" or $p["media.class"] == "Audio/Source")
		| ($p["media.class"] == "Audio/Sink") as $sink
		| (($p["node.nick"] // $p["node.description"] // $p["node.name"]) | gsub("[\t\n]"; " ")) as $name
		| ($p["device.profile.description"] // "-" | if . == $name or . == "" then "-" else gsub("[\t\n]"; " ") end) as $detail
		| [(if $sink then "sink" else "source" end), .id, $name, $detail,
		   (if $p["node.name"] == $def[if $sink then "default.audio.sink" else "default.audio.source" end]
		    then 1 else 0 end)] | @tsv'
}

audio_status() {
	esc "$(audio_nodes | awk -F'\t' '$1 == "sink" && $5 == 1 { print $3; exit }')"
}

audio_list() { audio_nodes; }

audio_mic_muted() {
	wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED
}

audio_rows() {
	TITLE=Sound
	MESG="Output: $(audio_status)"
	local nodes
	nodes=$(audio_nodes)
	audio_node_rows sink 󰓃 <<<"$nodes"
	audio_node_rows source 󰍬 <<<"$nodes"
	if audio_mic_muted; then
		row "$(lbl 󰍭 "Microphone" "muted")" audio_mic
	else
		row "$(lbl 󰍬 "Microphone" "on")" audio_mic
	fi
	row "$(lbl 󰕾 "Open wiremix")" audio_mixer
}

audio_node_rows() { # тип иконка < audio_nodes
	local kind id name detail def note
	while IFS=$'\t' read -r kind id name detail def; do
		[[ $kind == "$1" ]] || continue
		note=$([[ $detail == - ]] || esc "$detail") # «-» вместо пустого: read схлопывает пустые поля
		((def)) && note="󰄬 default${note:+ · $note}"
		row "$(lbl "$2" "$(esc "$name")" "$note")" audio_default "$id"
	done
}

audio_default() { wpctl set-default "$1"; }

audio_mic() { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; }

audio_mixer() { term wiremix wiremix; }
