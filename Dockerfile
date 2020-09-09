FROM ubuntu:18.04 AS flutter-image
RUN apt update
RUN apt install -y git
RUN cd /opt && git clone https://github.com/flutter/flutter.git
ENV PATH="/opt/flutter/bin:${PATH}"

RUN apt install -y curl
RUN apt install -y unzip
RUN flutter doctor


# install java
# RUN apt-get update
# RUN apt-get upgrade -y
# RUN apt-get install -y  software-properties-common
# RUN add-apt-repository ppa:webupd8team/java -y
# RUN apt-get update
# RUN echo oracle-java11-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
# RUN apt-get install -y oracle-java11-installer
# RUN apt-get clean

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install -y curl
RUN apt-get install -y ca-certificates
RUN apt-get install -y fontconfig
RUN apt-get install -y locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
RUN rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-11.0.8+10

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
    aarch64|arm64) \
    ESUM='fb27ea52ed901c14c9fe8ad2fc10b338b8cf47d6762571be1fe3fb7c426bab7c'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.8_10.tar.gz'; \
    ;; \
    armhf|armv7l) \
    ESUM='d00370967e4657e137cc511e81d6accbfdb08dba91e6268abef8219e735fbfc5'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_arm_linux_hotspot_11.0.8_10.tar.gz'; \
    ;; \
    ppc64el|ppc64le) \
    ESUM='d206a63cd719b65717f7f20ee3fe49f0b8b2db922986b4811c828db57212699e'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.8_10.tar.gz'; \
    ;; \
    s390x) \
    ESUM='5619e1437c7cd400169eb7f1c831c2635fdb2776a401147a2fc1841b01f83ed6'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.8_10.tar.gz'; \
    ;; \
    amd64|x86_64) \
    ESUM='6e4cead158037cb7747ca47416474d4f408c9126be5b96f9befd532e0a762b47'; \
    BINARY_URL='https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_x64_linux_hotspot_11.0.8_10.tar.gz'; \
    ;; \
    *) \
    echo "Unsupported arch: ${ARCH}"; \
    exit 1; \
    ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="/opt/java/openjdk/bin:$PATH"


# install sonarqube

RUN apt-get update \
    && apt-get install -y curl gnupg2 unzip \
    && rm -rf /var/lib/apt/lists/*

ENV SONAR_VERSION=7.9.4 \
    SONARQUBE_HOME=/opt/sonarqube \
    SONARQUBE_JDBC_USERNAME=sonar \
    SONARQUBE_JDBC_PASSWORD=sonar \
    SONARQUBE_JDBC_URL=""

# Http port
EXPOSE 9000

RUN groupadd -r sonarqube && useradd -r -g sonarqube sonarqube

# pub   2048R/D26468DE 2015-05-25
#       Key fingerprint = F118 2E81 C792 9289 21DB  CAB4 CFCA 4A29 D264 68DE
# uid                  sonarsource_deployer (Sonarsource Deployer) <infra@sonarsource.com>
# sub   2048R/06855C1D 2015-05-25
RUN for server in $(shuf -e ha.pool.sks-keyservers.net \
    hkp://p80.pool.sks-keyservers.net:80 \
    keyserver.ubuntu.com \
    hkp://keyserver.ubuntu.com:80 \
    pgp.mit.edu) ; do \
    gpg --batch --keyserver "$server" --recv-keys F1182E81C792928921DBCAB4CFCA4A29D26468DE && break || : ; \
    done

RUN set -x \
    && cd /opt \
    && curl -o sonarqube.zip -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip \
    && curl -o sonarqube.zip.asc -fSL https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip.asc \
    && gpg --batch --verify sonarqube.zip.asc sonarqube.zip \
    && unzip -q sonarqube.zip \
    && mv sonarqube-$SONAR_VERSION sonarqube \
    && chown -R sonarqube:sonarqube sonarqube \
    && rm sonarqube.zip* \
    && rm -rf $SONARQUBE_HOME/bin/*

VOLUME "$SONARQUBE_HOME/data"




















# ENTRYPOINT [ "tail", "-f", "/dev/null" ]

# Base this off of the official sonarqube image
# FROM sonarqube:latest AS sonarqube-image

# RUN apt-get update
# RUN apt install -y git
# RUN apt install -y curl
# RUN apt install -y unzip


# COPY --from=flutter-image /opt/flutter /opt/flutter
# ENV PATH="/opt/flutter/bin:${PATH}"















# Add plugin so it can scan .dart files
ADD sonar-flutter-plugin-0.3.1.jar $SONARQUBE_HOME/extensions/plugins/sonar-flutter-plugin-0.3.1.jar

# Add scanner so we can actually run scans
ADD scanner $SONARQUBE_HOME/scanner
ENV PATH="$SONARQUBE_HOME/scanner/bin:${PATH}"

# Add my files to be scanned
ADD sudoku_solver_2 $SONARQUBE_HOME/sudoku_solver_2


ENV SONAR_PROJECT_BASE_DIR: $SONARQUBE_HOME/sudoku_solver_2




WORKDIR $SONARQUBE_HOME
COPY run.sh $SONARQUBE_HOME/bin/
USER sonarqube
ENTRYPOINT ["./bin/run.sh"]