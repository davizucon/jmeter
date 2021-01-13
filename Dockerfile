FROM adoptopenjdk/openjdk8:jdk8u252-b09-alpine
#Original:  maintainer="emmanuel.gaillardon@orange.fr", now archived repo.
LABEL maintainer="davi.zucon@gmail.com"
STOPSIGNAL SIGKILL

ENV MIRROR https://downloads.apache.org//jmeter/binaries/
ENV JMETER_VERSION 5.4
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN ${JMETER_HOME}/bin
#Version
ENV MVN_SEARCH http://search.maven.org/remotecontent?filepath=
ENV ALPN_VERSION 8.1.13.v20181017
#Version
ENV PATH ${JMETER_BIN}:$PATH
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && apk add --no-cache \
    curl \
    fontconfig \
    net-tools \
    shadow \
    su-exec \
    tcpdump  \
    ttf-dejavu
RUN cd /tmp/ \
 && curl --location --silent --show-error --output apache-jmeter-${JMETER_VERSION}.tgz ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz \
 && curl --location --silent --show-error --output apache-jmeter-${JMETER_VERSION}.tgz.sha512 ${MIRROR}/apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && sha512sum -c apache-jmeter-${JMETER_VERSION}.tgz.sha512 \
 && mkdir -p /opt/ \
 && tar x -z -f apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
 && rm -R -f apache* \
 && sed -i '/RUN_IN_DOCKER/s/^# //g' ${JMETER_BIN}/jmeter \
 && sed -i '/PrintGCDetails/s/^# /: "${/g' ${JMETER_BIN}/jmeter && sed -i '/PrintGCDetails/s/$/}"/g' ${JMETER_BIN}/jmeter \
 && jmeter --version \
 && rm -fr /tmp/*

RUN curl --location --silent --show-error --output /opt/alpn-boot-${ALPN_VERSION}.jar ${MVN_SEARCH}org/mortbay/jetty/alpn/alpn-boot/${ALPN_VERSION}/alpn-boot-${ALPN_VERSION}.jar \
 && curl --location --silent --show-error --output  ${JMETER_HOME}/lib/cmdrunner-2.2.jar ${MVN_SEARCH}kg/apc/cmdrunner/2.2/cmdrunner-2.2.jar \
 && curl --location --silent --show-error --output  ${JMETER_HOME}/lib/ext/jmeter-plugins-manager-1.6.jar ${MVN_SEARCH}kg/apc/jmeter-plugins-manager/1.6/jmeter-plugins-manager-1.6.jar

RUN cd $JMETER_HOME && java -cp lib/ext/jmeter-plugins-manager-1.6.jar org.jmeterplugins.repository.PluginManagerCMDInstaller \
 && chmod +x ${JMETER_HOME}/bin/*.sh

RUN ${JMETER_HOME}/bin/PluginsManagerCMD.sh install jpgc-graphs-basic,bzm-http2,jpgc-casutg,jpgc-plugins-manager,bzm-random-csv,jmeter-core,jmeter-ftp,jmeter-http,jmeter-jdbc,jmeter-jms,jmeter-junit,jmeter-java,jmeter-ldap,jmeter-mail,jmeter-mongodb,jmeter-native,jmeter-tcp,jmeter-components
RUN rm -fr /tmp/*

# Required for HTTP2 plugins
ENV JVM_ARGS -Xbootclasspath/p:/opt/alpn-boot-${ALPN_VERSION}.jar
WORKDIR /jmeter
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["jmeter", "--?"]

