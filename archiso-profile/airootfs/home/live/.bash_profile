# AhmadOS live user shell profile
if [ -z "${DISPLAY:-}" ] && [ "${XDG_VTNR:-}" = 1 ]; then
  exec startplasma-x11
fi
