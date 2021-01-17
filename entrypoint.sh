#!/bin/ash
# mkdir -p /var/mail
# groupadd --non-unique --gid ${JMETER_GROUP_ID:-1000} jmeter
# useradd  --non-unique --uid ${JMETER_USER_ID:-1000} --no-log-init --create-home --gid jmeter jmeter
# chown jmeter:jmeter /jmeter
# chown -R jmeter:jmeter /opt/apache-jmeter-*

# cp ~root/.Xauthority ~jmeter/.Xauthority
# chown jmeter:jmeter /home/jmeter/.Xauthority

if [[ "${@:0:1}" == "-" ]]; then
  # exec su-exec jmeter:jmeter jmeter "$@"
  exec jmeter "$@"
else
  # exec su-exec jmeter:jmeter "$@"
  exec "$@"
fi
