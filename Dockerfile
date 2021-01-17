FROM alpine:latest as builder

ARG JMETER_VERSION="5.3"
ARG MIRROR="https://downloads.apache.org//jmeter/binaries/"
ARG MVN_SEARCH="http://search.maven.org/remotecontent?filepath="
ARG ALPN_VERSION="8.1.13.v20181017"

ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}

WORKDIR /tmp
RUN mkdir -p ${JMETER_HOME}/lib/ext && apk --no-cache add curl \
# && curl --location --silent --show-error --output apache-jmeter-${JMETER_VERSION}.tgz ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz \
# && curl --location --silent --show-error --output apache-jmeter-${JMETER_VERSION}.tgz.sha512 ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && curl --location --show-error --output apache-jmeter-${JMETER_VERSION}.tgz ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz \
 && curl --location --show-error --output apache-jmeter-${JMETER_VERSION}.tgz.sha512 ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && sha512sum -c apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && curl --location --silent --show-error --output /opt/alpn-boot-${ALPN_VERSION}.jar ${MVN_SEARCH}org/mortbay/jetty/alpn/alpn-boot/${ALPN_VERSION}/alpn-boot-${ALPN_VERSION}.jar \
 && curl --location --silent --show-error --output ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-1.6.jar ${MVN_SEARCH}kg/apc/jmeter-plugins-manager/1.6/jmeter-plugins-manager-1.6.jar \
 && curl --location --silent --show-error --output ${JMETER_HOME}/lib/cmdrunner-2.2.jar ${MVN_SEARCH}kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar \
 && tar -zxf /tmp/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
 && chown -R ${JMETER_USER_ID:-1000}:${JMETER_GROUP_ID:-1000} ${JMETER_HOME} \
 && rm -rf /tmp/* ${JMETER_HOME}/docs ${JMETER_HOME}/printable_docs

# FROM adoptopenjdk/openjdk15:jdk-15.0.1_9-alpine
FROM adoptopenjdk/openjdk15:jre-15.0.1_9-alpine
#Original: maintainer="emmanuel.gaillardon@orange.fr", now archived repo.
#Original: maintainer="davi.zucon@gmail.com"
LABEL maintainer="y.karezaki@gmail.com"
STOPSIGNAL SIGKILL

ARG JMETER_VERSION="5.3"
ARG JMETER_LANGUAGE="-Duser.language=ja -Duser.region=JP"
ARG INSTALL_PLUGINS="jpgc-standard"

ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN ${JMETER_HOME}/bin
ENV JMETER_LANGUAGE=${JMETER_LANGUAGE}

ENV PATH ${JMETER_BIN}:$PATH

ARG TZ="Asia/Tokyo"
ENV TZ=${TZ}

COPY entrypoint.sh /usr/local/bin/
COPY simple_test.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/simple_test.sh

# WORKDIR $JMETER_HOME
WORKDIR /tmp

COPY --from=builder /opt /opt

RUN apk upgrade --update && apk add --no-cache \
    font-noto-cjk \
    fontconfig \
    libxext \
    libxi \
    libxrender \
    libxtst \
    net-tools \
    shadow \
    su-exec \
    tcpdump  \
    ttf-dejavu \
    xauth \
    tzdata \
 && fc-cache -f \
 # see https://github.com/gliderlabs/docker-alpine/issues/136
#  && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
#     && echo "${TZ}" > /etc/timezone \
# for Java9 and above
 && sed -i '/file=gc_jmeter_%p.log/s/^# /: "${/g' ${JMETER_BIN}/jmeter && sed -i '/file=gc_jmeter_%p.log/s/$/}"/g' ${JMETER_BIN}/jmeter \
# for Java 8
# && sed -i '/RUN_IN_DOCKER/s/^# //g' ${JMETER_BIN}/jmeter \
# && sed -i '/PrintGCDetails/s/^# /: "${/g' ${JMETER_BIN}/jmeter && sed -i '/PrintGCDetails/s/$/}"/g' ${JMETER_BIN}/jmeter \
 && java -cp ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-1.6.jar org.jmeterplugins.repository.PluginManagerCMDInstaller \
 && chmod +x ${JMETER_HOME}/bin/*.sh && jmeter --version \
 && ${JMETER_HOME}/bin/PluginsManagerCMD.sh install ${INSTALL_PLUGINS} \
 && groupadd --non-unique --gid ${JMETER_GROUP_ID:-1000} jmeter \
 && useradd  --non-unique --uid ${JMETER_USER_ID:-1000} --no-log-init --create-home --gid jmeter jmeter \
 && jmeter --version \
 && rm -rf /tmp/*
 
# Java8 Required for HTTP2 plugins
# ENV JVM_ARGS -Xbootclasspath/p:/opt/alpn-boot-${ALPN_VERSION}.jar

COPY simple_test.jmx /home/jmeter/

USER jmeter
WORKDIR /jmeter
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jmeter", "--?"]

