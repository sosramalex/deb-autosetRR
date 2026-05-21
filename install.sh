#!/usr/bin/env bash
set -euo pipefail

show_banner() {
  echo "    _    _     ____   ___  ____    _    ____       ____  _____ ____          _   _   _ _____ ___  ____  ____  "
  echo "   / \  | |   / ___| / _ \/ ___|  / \  |  _ \     |  _ \| ____| __ )        / \ | | | |_   _/ _ \|  _ \|  _ \ "
  echo "  / _ \ | |   \___ \| | | \___ \ / _ \ | |_) |____| | | |  _| |  _ \ _____ / _ \| | | | | || | | | |_) | |_) |"
  echo " / ___ \| |___ ___) | |_| |___) / ___ \|  _ <_____| |_| | |___| |_) |_____/ ___ \ |_| | | || |_| |  _ <|  _ < "
  echo "/_/   \_\_____|____/ \___/|____/_/   \_\_| \_\    |____/|_____|____/     /_/   \_\___/  |_| \___/|_| \_\_| \_\\"
  echo ""
  echo "            Media Automation Stack — Radarr, Prowlarr, qBit & Media Server"
  echo ""
}

show_banner

SERVARR_SCRIPT_URL="https://raw.githubusercontent.com/Servarr/Wiki/master/servarr/servarr-install-script.sh"
JELLYFIN_INSTALL_URL="https://repo.jellyfin.org/install-debuntu.sh"
PLEX_KEY_URL="https://downloads.plex.tv/plex-keys/PlexSign.v2.key"
PLEX_REPO_URL="https://repo.plex.tv/deb/"
PLEX_KEYRING="/etc/apt/keyrings/plexmediaserver.v2.gpg"
QB_USER="qbittorrent"
QB_GROUP="media"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Please run this installer as root:"
    echo "  su -"
    echo "  bash install.sh"
    echo ""
    echo "Or, if sudo is already configured:"
    echo "  curl -fsSL https://raw.githubusercontent.com/alsosram/deb-autorr/main/install.sh | sudo bash"
    exit 1
  fi
}

require_debian_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "This installer is intended for Debian-based systems with apt-get."
    exit 1
  fi
}

install_base_packages() {
  echo "Updating package lists and upgrading system..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

  echo "Installing base dependencies..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    libsqlite3-0 \
    sqlite3 \
    wget
}

install_servarr_app() {
  local app_name="$1"
  local menu_choice="$2"
  local script_path

  script_path="$(mktemp)"
  curl -fsSL "${SERVARR_SCRIPT_URL}" -o "${script_path}"
  chmod +x "${script_path}"

  echo "Installing ${app_name} with the Servarr installer..."
  printf '%s\n\n\nyes\n' "${menu_choice}" | bash "${script_path}"
  rm -f "${script_path}"
}

install_qbittorrent() {
  echo "Installing qBittorrent nox..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y qbittorrent-nox

  if ! getent group "${QB_GROUP}" >/dev/null; then
    groupadd "${QB_GROUP}"
  fi

  if ! id "${QB_USER}" >/dev/null 2>&1; then
    adduser --system --no-create-home --ingroup "${QB_GROUP}" "${QB_USER}"
  fi

  mkdir -p /var/lib/qbittorrent-nox
  chown -R "${QB_USER}:${QB_GROUP}" /var/lib/qbittorrent-nox

  cat >/etc/systemd/system/qbittorrent-nox.service <<EOF
[Unit]
Description=qBittorrent nox service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=${QB_USER}
Group=${QB_GROUP}
UMask=0002
ExecStart=/usr/bin/qbittorrent-nox --profile=/var/lib/qbittorrent-nox --confirm-legal-notice
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now qbittorrent-nox.service

  sleep 3
  QB_TEMP_PASS=$(journalctl -u qbittorrent-nox -n 30 --no-pager 2>/dev/null \
    | grep -oP 'password is set to: \K.*' \
    | head -1) || QB_TEMP_PASS=""
  export QB_TEMP_PASS
}

install_plex() {
  echo "Installing Plex Media Server..."
  install -d -m 0755 /etc/apt/keyrings
  rm -f /etc/apt/sources.list.d/plexmediaserver.list
  curl -fsSL "${PLEX_KEY_URL}" | gpg --dearmor -o "${PLEX_KEYRING}"
  echo "deb [arch=amd64 signed-by=${PLEX_KEYRING}] ${PLEX_REPO_URL} public main" \
    >/etc/apt/sources.list.d/plexmediaserver.list

  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y plexmediaserver || {
    echo "Plex install via repo failed. Trying direct .deb download..."
    local plex_deb
    plex_deb="$(mktemp)"
    curl -fsSL -o "${plex_deb}" \
      "https://downloads.plex.tv/plex-media-server-new/1.41.6.9663-ce7c0d806/plexmediaserver_1.41.6.9663-ce7c0d806_amd64.deb"
    dpkg -i "${plex_deb}" || DEBIAN_FRONTEND=noninteractive apt-get install -y -f
    rm -f "${plex_deb}"
  }
}

install_jellyfin() {
  echo "Installing Jellyfin..."
  curl -fsSL "${JELLYFIN_INSTALL_URL}" | bash
}

choose_media_server() {
  echo ""
  echo "Choose a media server to install:"
  select media_server in "Plex Media Server" "Jellyfin Server" "Skip media server"; do
    case "${REPLY}" in
      1)
        install_plex
        break
        ;;
      2)
        install_jellyfin
        break
        ;;
      3)
        echo "Skipping media server installation."
        break
        ;;
      *)
        echo "Invalid choice. Enter 1, 2, or 3."
        ;;
    esac
  done
}

print_summary() {
  local ip_local

  ip_local="$(hostname -I 2>/dev/null | awk '{print $1}')"
  ip_local="${ip_local:-SERVER_IP}"

  echo ""
  echo "Done."
  echo "Radarr:      http://${ip_local}:7878"
  echo "Prowlarr:    http://${ip_local}:9696"
  echo "qBittorrent: http://${ip_local}:8080"
  if [[ -n "${QB_TEMP_PASS:-}" ]]; then
    echo "qBit Pass:   ${QB_TEMP_PASS}  (change on first login)"
  else
    echo "qBit Pass:   check 'journalctl -u qbittorrent-nox -n 20'"
  fi
  echo "Plex:        http://${ip_local}:32400/web"
  echo "Jellyfin:    http://${ip_local}:8096"
}

main() {
  require_root
  require_debian_apt
  install_base_packages

  install_servarr_app "Prowlarr" "2"
  install_servarr_app "Radarr" "3"
  install_qbittorrent
  choose_media_server
  print_summary
}

main "$@"
