#!/bin/bash
set -e

export HADOOP_HOME=/opt/hadoop-3.2.0
export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.375.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.2.0.jar
export HIVE_HOME=/opt/apache-hive-metastore-3.0.0-bin
export METASTORE_CONF_DIR=${HIVE_HOME}/conf
export HIVE_LOG_DIR=${HIVE_LOG_DIR:-/var/log/hive}
export HIVE_LOG_FILE=${HIVE_LOG_FILE:-hive-metastore.log}

# Ensure log directory exists and has proper permissions
mkdir -p ${HIVE_LOG_DIR}
chmod 755 ${HIVE_LOG_DIR}

# Copy the log4j properties file to the location where Hive expects it
cp ${HIVE_HOME}/conf/metastore-log4j2.properties ${HIVE_HOME}/conf/hive-log4j2.properties

# Configure system properties for logging and Thrift protocol
export HADOOP_OPTS="-Dhive.log.dir=${HIVE_LOG_DIR} -Dhive.log.file=${HIVE_LOG_FILE} -Dmetastore.thrift.compact=true -Dmetastore.thrift.framed=true -Dhive.metastore.client.connect.retry.delay=5 -Dhive.server2.transport.mode=binary"
export HADOOP_CLIENT_OPTS="${HADOOP_OPTS}"
export METASTORE_OPTS="${HADOOP_OPTS}"

echo "Waiting for PostgreSQL to be ready..."
until nc -z de_psql 5432; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "PostgreSQL is up!"

echo "Checking schema..."
if ! /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -dbType postgres -info; then
  echo "Schema not found. Initializing..."
  /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -initSchema -dbType postgres
fi

echo "Starting Metastore Server..."
# Hive Metastore doesn't accept Java properties as command-line args
# Set through environment variables instead
exec /opt/apache-hive-metastore-3.0.0-bin/bin/start-metastore