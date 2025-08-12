FROM docker.io/bitnami/spark:3.3

USER root

# Install prerequisites
RUN apt-get update && apt-get install -y curl netcat-traditional

RUN curl -O https://repo1.maven.org/maven2/software/amazon/awssdk/s3/2.18.41/s3-2.18.41.jar \
    && curl -O https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk/1.12.367/aws-java-sdk-1.12.367.jar \
    && curl -O https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.3_2.12/1.3.1/iceberg-spark-runtime-3.3_2.12-1.3.1.jar \
    && curl -O https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.19/mysql-connector-java-8.0.19.jar \
    && mv s3-2.18.41.jar /opt/bitnami/spark/jars \
    && mv aws-java-sdk-1.12.367.jar /opt/bitnami/spark/jars \
    && mv iceberg-spark-runtime-3.3_2.12-1.3.1.jar /opt/bitnami/spark/jars \
    && mv mysql-connector-java-8.0.19.jar /opt/bitnami/spark/jars