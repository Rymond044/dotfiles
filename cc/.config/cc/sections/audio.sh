# Звук: список выходов/входов и их переключение теперь нативные в quickseek (PipeWire, источник "audio",
# точка монтирования — quickseek.sh → SEC_SOURCE). Здесь остались действия для командной строки.

audio_default() { wpctl set-default "$1"; }

audio_mic() { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; }
