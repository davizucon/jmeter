#!/bin/bash

JMETER_VERSION="5.3"
# JMETER_VERSION="5.4.1-SNAPSHOT"

# for JMeter Release build
MIRROR="https://downloads.apache.org//jmeter/binaries/"
# for JMeter SNAPSHOT build
# MIRROR=https://ci-builds.apache.org/job/JMeter/job/JMeter-trunk/lastSuccessfulBuild/artifact/src/dist/build/distributions/

INSTALL_PLUGINS="jpgc-standard"
# INSTALL_PLUGINS="jpgc-graphs-basic,bzm-http2,jpgc-casutg,bzm-random-csv"

TZ="Asia/Tokyo"
JMETER_LANGUAGE="-Duser.language=ja -Duser.region=JP"

docker build \
 -t jm \
--build-arg JMETER_VERSION="${JMETER_VERSION}" \
--build-arg MIRROR="${MIRROR}" \
--build-arg INSTALL_PLUGINS="${INSTALL_PLUGINS}" \
--build-arg TZ="${TZ}" \
--build-arg JMETER_LANGUAGE="${JMETER_LANGUAGE}" \
"$@" \
.
