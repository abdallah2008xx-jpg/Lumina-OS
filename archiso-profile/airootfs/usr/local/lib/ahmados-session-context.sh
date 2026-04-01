#!/usr/bin/env bash

resolve_hostname_value() {
    local host_value=""

    if command -v hostname >/dev/null 2>&1; then
        host_value="$(hostname 2>/dev/null || true)"
    fi

    host_value="${host_value//$'\n'/}"
    host_value="${host_value//$'\r'/}"

    if [[ -z "${host_value}" || "${host_value}" == "(none)" || "${host_value}" == "unknown" ]]; then
        if [[ -r /etc/hostname ]]; then
            host_value="$(head -n 1 /etc/hostname | tr -d '\r\n[:space:]')"
        fi
    fi

    if [[ -n "${host_value}" ]]; then
        printf '%s\n' "${host_value}"
    else
        printf '%s\n' "unknown"
    fi
}

resolve_session_id() {
    local session_id="${XDG_SESSION_ID:-}"

    if [[ -n "${session_id}" && "${session_id}" != "unknown" ]]; then
        printf '%s\n' "${session_id}"
        return
    fi

    if command -v loginctl >/dev/null 2>&1; then
        session_id="$(loginctl show-user "$(id -u)" -p Display --value 2>/dev/null | tr -d '\r\n[:space:]')"
        if [[ -n "${session_id}" ]]; then
            printf '%s\n' "${session_id}"
            return
        fi

        session_id="$(loginctl list-sessions --no-legend 2>/dev/null | awk -v user_name="${USER}" '$3 == user_name { print $1; exit }')"
        session_id="$(printf '%s' "${session_id}" | tr -d '\r\n[:space:]')"
        if [[ -n "${session_id}" ]]; then
            printf '%s\n' "${session_id}"
            return
        fi
    fi

    printf '%s\n' "unknown"
}

resolve_session_type() {
    local session_type="${XDG_SESSION_TYPE:-}"
    local session_id=""

    if [[ -z "${session_type}" || "${session_type}" == "unknown" ]]; then
        session_id="$(resolve_session_id)"
        if command -v loginctl >/dev/null 2>&1 && [[ -n "${session_id}" && "${session_id}" != "unknown" ]]; then
            session_type="$(loginctl show-session "${session_id}" -p Type --value 2>/dev/null | tr -d '\r\n[:space:]')"
        fi
    fi

    if [[ -z "${session_type}" || "${session_type}" == "unknown" ]]; then
        if pgrep -u "$(id -u)" -f 'startplasma-x11|kwin_x11|Xorg' >/dev/null 2>&1; then
            session_type="x11"
        elif pgrep -u "$(id -u)" -f 'kwin_wayland|startplasma-wayland|wayland' >/dev/null 2>&1; then
            session_type="wayland"
        fi
    fi

    if [[ -n "${session_type}" ]]; then
        printf '%s\n' "${session_type}"
    else
        printf '%s\n' "unknown"
    fi
}

resolve_desktop_session() {
    local desktop_session="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    local session_id=""

    if [[ -z "${desktop_session}" || "${desktop_session}" == "unknown" ]]; then
        session_id="$(resolve_session_id)"
        if command -v loginctl >/dev/null 2>&1 && [[ -n "${session_id}" && "${session_id}" != "unknown" ]]; then
            desktop_session="$(loginctl show-session "${session_id}" -p Desktop --value 2>/dev/null | tr -d '\r\n[:space:]')"
        fi
    fi

    if [[ -z "${desktop_session}" || "${desktop_session}" == "unknown" ]]; then
        if [[ "${KDE_FULL_SESSION:-}" == "true" || "${KDE_SESSION_VERSION:-}" == "6" ]]; then
            desktop_session="KDE"
        elif pgrep -u "$(id -u)" -x plasmashell >/dev/null 2>&1; then
            desktop_session="KDE"
        fi
    fi

    if [[ -n "${desktop_session}" ]]; then
        printf '%s\n' "${desktop_session}"
    else
        printf '%s\n' "unknown"
    fi
}

resolve_display_value() {
    local display_value="${DISPLAY:-}"

    if [[ -z "${display_value}" || "${display_value}" == "unknown" ]]; then
        display_value=":0"
    fi

    printf '%s\n' "${display_value}"
}

resolve_xauthority_path() {
    local xauthority_path="${XAUTHORITY:-}"

    if [[ -n "${xauthority_path}" && -f "${xauthority_path}" ]]; then
        printf '%s\n' "${xauthority_path}"
        return
    fi

    xauthority_path="${HOME}/.Xauthority"
    if [[ -f "${xauthority_path}" ]]; then
        printf '%s\n' "${xauthority_path}"
        return
    fi

    printf '%s\n' "${xauthority_path}"
}

resolve_dbus_address() {
    local dbus_address="${DBUS_SESSION_BUS_ADDRESS:-}"
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

    if [[ -n "${dbus_address}" ]]; then
        printf '%s\n' "${dbus_address}"
        return
    fi

    if [[ -S "${runtime_dir}/bus" ]]; then
        printf '%s\n' "unix:path=${runtime_dir}/bus"
        return
    fi

    printf '%s\n' ""
}
