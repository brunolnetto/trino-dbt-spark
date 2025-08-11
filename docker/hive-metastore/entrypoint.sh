#!/bin/bash
set -e

export HADOOP_HOME=/opt/hadoop-3.2.0
export HADOOP_CLASSPATH=${HADOOP_HOME}/share/hadoop/tools/lib/aws-java-sdk-bundle-1.11.375.jar:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws-3.2.0.jar

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
until nc -z ${MYSQL_HOST} 3306; do
  echo "MySQL is unavailable - sleeping"
  sleep 2
done
echo "MySQL is up!"

# Check and initialize schema
echo "Checking schema..."
if ! /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -dbType mysql -info; then
  echo "Schema not found. Initializing..."
  /opt/apache-hive-metastore-3.0.0-bin/bin/schematool -initSchema -dbType mysql
fi

echo "Starting Hive Metastore..."
/opt/apache-hive-metastore-3.0.0-bin/bin/start-metastore