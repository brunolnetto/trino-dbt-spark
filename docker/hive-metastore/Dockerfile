FROM eclipse-temurin:8-jre AS downloads

ARG HADOOP_VERSION=3.2.0
ARG METASTORE_VERSION=3.0.0
ARG POSTGRES_CONNECTOR_VER=42.7.3

WORKDIR /downloads

RUN set -ex; \
    curl -fL "https://archive.apache.org/dist/hive/hive-standalone-metastore-${METASTORE_VERSION}/hive-standalone-metastore-${METASTORE_VERSION}-bin.tar.gz" \
    -o hive-metastore.tar.gz && \
    echo "Hive metastore downloaded successfully" && \
    ls -l hive-metastore.tar.gz

RUN set -ex; \
    curl -fL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    -o hadoop.tar.gz && \
    echo "Hadoop downloaded successfully" && \
    ls -l hadoop.tar.gz

RUN set -ex; \
    curl -fL "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_CONNECTOR_VER}/postgresql-${POSTGRES_CONNECTOR_VER}.jar" \
    -o postgresql-jdbc.jar && \
    echo "PostgreSQL JDBC connector downloaded successfully" && \
    ls -l postgresql-jdbc.jar

FROM eclipse-temurin:8-jre

ARG HADOOP_VERSION=3.2.0
ARG METASTORE_VERSION=3.0.0
ARG POSTGRES_CONNECTOR_VER=42.7.3

ENV HADOOP_VERSION=${HADOOP_VERSION} \
    METASTORE_VERSION=${METASTORE_VERSION} \
    HADOOP_HOME=/opt/hadoop-${HADOOP_VERSION} \
    HIVE_HOME=/opt/apache-hive-metastore-${METASTORE_VERSION}-bin \
    HIVE_SYMLINK=/opt/hive \
    JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"

WORKDIR /opt

# Install dependencies in a single layer
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        procps \
        netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Copy and extract files from download stage
COPY --from=downloads /downloads/hive-metastore.tar.gz ./
COPY --from=downloads /downloads/hadoop.tar.gz ./

RUN set -ex; \
    echo "Extracting Hive metastore..." && \
    tar xzf hive-metastore.tar.gz && \
    echo "Extracting Hadoop..." && \
    tar xzf hadoop.tar.gz && \
    echo "Removing archives..." && \
    rm *.tar.gz && \
    echo "Creating symlink..." && \
    ln -sfn "${HIVE_HOME}" "${HIVE_SYMLINK}" && \
    echo "Extraction complete" && \
    ls -la /opt/


COPY --from=downloads /downloads/postgresql-jdbc.jar ${HIVE_HOME}/lib/postgresql-jdbc-${POSTGRES_CONNECTOR_VER}.jar
RUN chmod 644 ${HIVE_HOME}/lib/postgresql-jdbc-${POSTGRES_CONNECTOR_VER}.jar

# Copy configurations
COPY conf/metastore-site.xml ${HIVE_HOME}/conf/
COPY conf/log4j.properties ${HIVE_HOME}/conf/
COPY conf/metastore-log4j2.properties ${HIVE_HOME}/conf/
COPY conf/log4j2.properties ${HIVE_HOME}/conf/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Fix SLF4J binding conflicts by removing the conflicting binding
RUN find ${HADOOP_HOME} -name "*slf4j-log4j12*.jar" -exec rm {} \; || true 
RUN touch ${HIVE_HOME}/conf/hive-log4j2.properties

ENV HIVE_AUX_JARS_PATH=${HIVE_HOME}/lib/postgresql-jdbc-${POSTGRES_CONNECTOR_VER}.jar \
    HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${HIVE_HOME}/lib/postgresql-jdbc-${POSTGRES_CONNECTOR_VER}.jar \
    HADOOP_OPTS="-Dlog4j.configurationFile=file:${HIVE_HOME}/conf/metastore-log4j2.properties" \
    HIVE_OPTS="-Dlog4j.configurationFile=file:${HIVE_HOME}/conf/metastore-log4j2.properties"

# Set up user and permissions in a single layer
RUN groupadd -r hive && \
    useradd -r -g hive -d ${HIVE_HOME} hive && \
    mkdir -p /var/log/hive /var/log/metastore && \
    chown -R hive:hive ${HIVE_HOME} /entrypoint.sh /var/log/hive /var/log/metastore

USER hive
WORKDIR ${HIVE_HOME}
EXPOSE 9083

ENTRYPOINT ["/entrypoint.sh"]
