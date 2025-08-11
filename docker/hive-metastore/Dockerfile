# docker/hive-metastore/Dockerfile
FROM eclipse-temurin:8-jre

ARG HADOOP_VERSION=3.2.0
ARG METASTORE_VERSION=3.0.0
ARG MYSQL_CONNECTOR_VER=8.0.33

ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV METASTORE_VERSION=${METASTORE_VERSION}
ENV HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION}
ENV HIVE_HOME=/opt/apache-hive-metastore-${METASTORE_VERSION}-bin
ENV HIVE_SYMLINK=/opt/hive

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="$JAVA_HOME/bin:$PATH"

WORKDIR /opt

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl tar gzip ca-certificates procps wget unzip telnet netcat-traditional; \
    rm -rf /var/lib/apt/lists/*

# Download & extract hive standalone metastore + hadoop, then normalize the extracted dir into HIVE_HOME
RUN set -eux; \
    curl -sSL "https://archive.apache.org/dist/hive/hive-standalone-metastore-${METASTORE_VERSION}/hive-standalone-metastore-${METASTORE_VERSION}-bin.tar.gz" | tar -xz -C /opt; \
    curl -sSL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" | tar -xz -C /opt; \
    HIVE_EXTRACTED=$(ls -d /opt/*metastore*${METASTORE_VERSION}*-bin 2>/dev/null | head -n1); \
    if [ -z "$HIVE_EXTRACTED" ]; then echo "Hive extraction not found"; exit 1; fi; \
    if [ "$HIVE_EXTRACTED" != "${HIVE_HOME}" ]; then \
      mv "$HIVE_EXTRACTED" "${HIVE_HOME}"; \
    fi; \
    ln -sfn "${HIVE_HOME}" "${HIVE_SYMLINK}"


# Fetch MySQL connector straight into hive lib
RUN set -eux; \
    mkdir -p "${HIVE_HOME}/lib"; \
    curl -sSL "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VER}/mysql-connector-java-${MYSQL_CONNECTOR_VER}.jar" \
      -o "${HIVE_HOME}/lib/mysql-connector-java-${MYSQL_CONNECTOR_VER}.jar"; \
    chmod 644 "${HIVE_HOME}/lib/mysql-connector-java-${MYSQL_CONNECTOR_VER}.jar"

# copy local configs and the entrypoint (relative to build context: ./docker/hive-metastore)
COPY conf/metastore-site.xml ${HIVE_HOME}/conf/
COPY conf/core-site.xml ${HIVE_HOME}/conf/
COPY entrypoint.sh /entrypoint.sh

# ensure entrypoint is executable and owned by hive (do this before switching to user)
RUN chmod +x /entrypoint.sh || true

# force connector into classpath for schematool
ENV HIVE_AUX_JARS_PATH=${HIVE_HOME}/lib/mysql-connector-java-${MYSQL_CONNECTOR_VER}.jar
ENV HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${HIVE_HOME}/lib/mysql-connector-java-${MYSQL_CONNECTOR_VER}.jar

# create user and set ownership
RUN groupadd -r hive && \
    useradd -r -g hive -d ${HIVE_HOME} hive && \
    chown -R hive:hive ${HIVE_HOME} /entrypoint.sh


USER hive
WORKDIR ${HIVE_HOME}
EXPOSE 9083

ENTRYPOINT ["/entrypoint.sh"]
