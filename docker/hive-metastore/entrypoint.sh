#!/bin/bash
set -e

export HADOOP_HOME=/opt/hadoop-3.2.0
export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.375.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.2.0.jar

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

echo "Starting Hive Metastore..."
/opt/apache-hive-metastore-3.0.0-bin/bin/start-metastore