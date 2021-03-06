#!/bin/bash

PROCNAME='sshd'
DAEMON='/usr/sbin/sshd'
DAEMON_ARGS=( -D )

if [ -z "$1" ]; then
  set -- "${DAEMON}" "${DAEMON_ARGS[@]}"
elif [ "${1:0:1}" = '-' ]; then
  set -- "${DAEMON}" "$@"
elif [ "${1}" = "${PROCNAME}" ]; then
  shift
  if [ -n "${1}" ]; then
    set -- "${DAEMON}" "$@"
  else
    set -- "${DAEMON}" "${DAEMON_ARGS[@]}"
  fi
fi

if [ "$1" = "${DAEMON}" ]; then
  export SSH_PASSWORD="${SSH_PASSWORD:=}"
  export SSH_SHELL="${SSH_SHELL:=/bin/bash}"
  export SSH_USER="${SSH_USER:=}"

  for ALGO in dsa ecdsa ed25519 rsa; do
    if [ ! -f /var/lib/ssh/ssh_host_${ALGO}_key ]; then
      ssh-keygen -q -f "/var/lib/ssh/ssh_host_${ALGO}_key" -N '' -t "${ALGO}"
    fi
  done

  if [ -n "${SSH_USER}" ]; then
    if ! getent passwd "${SSH_USER}" >/dev/null 2>&1; then
      useradd --extrausers -d "/home/${SSH_USER}" -m -s "${SSH_SHELL}" -U "${SSH_USER}"
    else
      usermod -d "/home/${SSH_USER}" -s "${SSH_SHELL}" "${SSH_USER}"
    fi
    if [ -n "${SSH_PASSWORD}" ]; then
      echo "${SSH_USER}:${SSH_PASSWORD}" | chpasswd -c SHA256
      passwd "${SSH_USER}" <<- EOF
	${SSH_PASSWORD}
	${SSH_PASSWORD}
EOF
    fi
  fi

  mkdir -p /var/run/sshd
fi

exec "$@"
