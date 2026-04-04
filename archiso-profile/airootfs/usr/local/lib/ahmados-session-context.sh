#!/usr/bin/env bash

session_env_process_patterns=(
    'qmlscene6 /usr/share/ahmados/welcome/Main.qml'
    'plasmashell'
    'kwin_x11'
    'startplasma-x11'
    'kwin_wayland'
    'startplasma-wayland'
    'Xorg'
)

resolve_process_env_value() {
    local variable_name="$1"
    local existing_path_only="${2:-false}"
    local current_uid pattern pid env_file value

    current_uid="$(id -u)"

    for pattern in "${session_env_process_patterns[@]}"; do
        while IFS= read -r pid; do
            [[ -n "${pid}" ]] || continue
            env_file="/proc/${pid}/environ"

            if [[ ! -r "${env_file}" ]]; then
                continue
            fi

            value="$(
                tr '\0' '\n' < "${env_file}" 2>/dev/null |
                    awk -F= -v target="${variable_name}" '$1 == target { sub($1 "=", ""); print; exit }'
            )"

            if [[ -z "${value}" ]]; then
                continue
            fi

            if [[ "${existing_path_only}" == "true" && ! -e "${value}" ]]; then
                continue
            fi

            printf '%s\n' "${value}"
            return 0
        done < <(pgrep -u "${current_uid}" -f "${pattern}" 2>/dev/null || true)
    done

    return 1
}

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
        display_value="$(resolve_process_env_value DISPLAY 2>/dev/null || true)"
    fi

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

    xauthority_path="$(resolve_process_env_value XAUTHORITY true 2>/dev/null || true)"
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
    local runtime_dir="${XDG_RUNTIME_DIR:-}"

    if [[ -n "${dbus_address}" ]]; then
        printf '%s\n' "${dbus_address}"
        return
    fi

    dbus_address="$(resolve_process_env_value DBUS_SESSION_BUS_ADDRESS 2>/dev/null || true)"
    if [[ -n "${dbus_address}" ]]; then
        printf '%s\n' "${dbus_address}"
        return
    fi

    if [[ -z "${runtime_dir}" ]]; then
        runtime_dir="$(resolve_process_env_value XDG_RUNTIME_DIR 2>/dev/null || true)"
    fi

    runtime_dir="${runtime_dir:-/run/user/$(id -u)}"

    if [[ -S "${runtime_dir}/bus" ]]; then
        printf '%s\n' "unix:path=${runtime_dir}/bus"
        return
    fi

    printf '%s\n' ""
}

resolve_hypervisor() {
    local hypervisor=""
    local product_name=""
    local sys_vendor=""

    if command -v systemd-detect-virt >/dev/null 2>&1; then
        hypervisor="$(systemd-detect-virt 2>/dev/null || true)"
        hypervisor="${hypervisor//$'\n'/}"
        hypervisor="${hypervisor//$'\r'/}"
        hypervisor="$(printf '%s' "${hypervisor}" | tr -d '[:space:]')"
    fi

    if [[ -z "${hypervisor}" || "${hypervisor}" == "none" ]]; then
        if [[ -r /sys/class/dmi/id/product_name ]]; then
            product_name="$(tr -d '\r\n' < /sys/class/dmi/id/product_name 2>/dev/null || true)"
        fi

        if [[ -r /sys/class/dmi/id/sys_vendor ]]; then
            sys_vendor="$(tr -d '\r\n' < /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
        fi

        case "${product_name} ${sys_vendor}" in
            *VirtualBox*|*virtualbox*)
                hypervisor="virtualbox"
                ;;
            *VMware*|*vmware*)
                hypervisor="vmware"
                ;;
        esac
    fi

    if [[ -n "${hypervisor}" && "${hypervisor}" != "none" ]]; then
        printf '%s\n' "${hypervisor}"
    else
        printf '%s\n' "bare-metal"
    fi
}

resolve_primary_x11_output() {
    local xrandr_output="${1:-}"

    if [[ -z "${xrandr_output}" ]]; then
        xrandr_output="$(xrandr --current 2>/dev/null || true)"
    fi

    if [[ -z "${xrandr_output}" ]]; then
        return 1
    fi

    printf '%s\n' "${xrandr_output}" | awk '
        / connected primary / {
            print $1
            exit
        }
        / connected / {
            print $1
            exit
        }
    '
}

resolve_current_x11_mode() {
    local output_name="${1:-}"
    local xrandr_output="${2:-}"

    if [[ -z "${output_name}" ]]; then
        return 1
    fi

    if [[ -z "${xrandr_output}" ]]; then
        xrandr_output="$(xrandr --current 2>/dev/null || true)"
    fi

    if [[ -z "${xrandr_output}" ]]; then
        return 1
    fi

    printf '%s\n' "${xrandr_output}" | awk -v target="${output_name}" '
        $1 == target && / connected/ {
            in_target = 1
            next
        }
        /^[^[:space:]]/ {
            if (in_target) {
                exit
            }
        }
        in_target && /\*/ {
            print $1
            exit
        }
    '
}

resolve_x11_mode_dimensions() {
    local mode_name="${1:-}"

    if [[ "${mode_name}" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        printf '%s %s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

x11_output_supports_mode() {
    local output_name="$1"
    local mode_name="$2"
    local xrandr_output="${3:-}"

    if [[ -z "${xrandr_output}" ]]; then
        xrandr_output="$(xrandr --current 2>/dev/null || true)"
    fi

    if [[ -z "${output_name}" || -z "${mode_name}" || -z "${xrandr_output}" ]]; then
        return 1
    fi

    printf '%s\n' "${xrandr_output}" | awk -v target="${output_name}" -v requested="${mode_name}" '
        $1 == target && / connected/ {
            in_target = 1
            next
        }
        /^[^[:space:]]/ {
            if (in_target) {
                exit
            }
        }
        in_target && $1 == requested {
            found = 1
            exit
        }
        END {
            exit(found ? 0 : 1)
        }
    '
}

choose_virtualbox_fallback_x11_mode() {
    local output_name="${1:-}"
    local xrandr_output="${2:-}"
    local candidate=""

    if [[ -z "${output_name}" ]]; then
        return 1
    fi

    if [[ -z "${xrandr_output}" ]]; then
        xrandr_output="$(xrandr --current 2>/dev/null || true)"
    fi

    for candidate in 1366x768 1600x900 1440x900 1400x900 1280x800 1280x720 1024x768; do
        if x11_output_supports_mode "${output_name}" "${candidate}" "${xrandr_output}"; then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    return 1
}
