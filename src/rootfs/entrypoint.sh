#!/bin/bash
export HOME="${HOME:-/home/$USER}"

export GROUP="${GROUP:-$USER}"

echo "Setting up user account: ${USER}"

groupadd \
  --gid "${UID}" \
    "${GROUP}"

useradd \
  --uid "${UID}" \
  --gid "${UID}" \
  --home-dir "${HOME}" \
  --shell /bin/bash \
    "${USER}"

usermod \
  -a -G \
    adm,sudo,video,audio,tty,users \
      "${USER}"

passwd -d "${USER}"

echo "Setting up /run/user/${UID}"
mkdir -p "/run/user/${UID}"
chmod 0700 "/run/user/${UID}"
chown "${USER}":"${GROUP}" "/run/user/${UID}"

if [[ "${ENABLE_ROOT}" == "true" ]] ; then
  echo "Allowing passwordless sudo for ${USER}"
  echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

echo "Setting up user environment"

# First setup VNC socket directory
if [[ -z "${DISPLAY_SOCK_ADDR}" ]] ; then
  if [[ -n "${VNC_SOCK_ADDR}" ]] ; then
    export DISPLAY_SOCK_ADDR="${VNC_SOCK_ADDR}"
  else
    export DISPLAY_SOCK_ADDR="/run/user/${UID}/vnc.sock"
  fi
fi
echo "Setting up VNC socket directory at $(dirname ${DISPLAY_SOCK_ADDR})"
mkdir -pv "$(dirname ${DISPLAY_SOCK_ADDR})"
chown -Rv "${USER}":"${GROUP}" "$(dirname ${DISPLAY_SOCK_ADDR})"

echo "Granting ${USER} ownership of ${HOME}"
chown -Rv "${USER}":"${GROUP}" "${HOME}"

mkdir -pv /run/dbus

/usr/bin/dbus-daemon --system --nofork --nopidfile &

sudo -u epers /usr/bin/dbus-launch grdctl --headless vnc set-auth-method none
sudo -u epers /usr/bin/dbus-launch grdctl --headless vnc clear-password
sudo -u epers /usr/bin/dbus-launch grdctl --headless vnc disable-view-only
sudo -u epers /usr/bin/dbus-launch grdctl --headless vnc enable
sudo -u epers /usr/bin/dbus-launch grdctl --headless status

pkill dbus-daemon

/usr/bin/supervisord \
  -n \
  -c /etc/supervisor/supervisord.conf
