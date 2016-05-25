FROM java:8-jdk-alpine

ENV MAVEN_VERSION 3.3.9
ENV SPARK_VERSION 1.6.1
ENV HADOOP_VERSION 2.6.0

ENV MAVEN_OPTS "-Xmx2g -XX:MaxPermSize=512M -XX:ReservedCodeCacheSize=512m"


RUN set -xe \
  && apk add --no-cache --virtual .build-deps \
                git \
                bash \
                gnupg \
                curl \
  && export GNUPGHOME="$(mktemp -d)" \
\ 
  && echo "Install Apache Spark" \
  && mkdir -p /root/build \
  && cd /root/build \
  && curl -fSL http://www.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}.tgz -o spark.tgz \
  && curl -fSL http://www.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}.tgz.asc -o spark.tgz.asc \
  && curl -fSL https://dist.apache.org/repos/dist/release/spark/KEYS -o spark.tgz.keys \
  && gpg --import spark.tgz.keys \ 
  && gpg --verify spark.tgz.asc spark.tgz \
  && tar -zxf spark.tgz \
  && cd spark-${SPARK_VERSION}/ \
  && ./make-distribution.sh --name custom-spark -Pyarn -Phadoop-$(echo $HADOOP_VERSION|cut -c 1-3) -Phive-thriftserver -Phive -Dhadoop.version=${HADOOP_VERSION} -DskipTests \
  && mkdir -p /usr/local/spark \
  && mv dist/* /usr/local/spark/ \
  && mv lib_managed/jars/* /usr/local/spark/lib/ \
  && cd / \
  && rm -rf /root/.m2 /root/build \
\
  && echo "Link compatible library, because ld-linux is not available in Alpine" \
  && ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 \
\
  && addgroup -S supergroup \
  && adduser -S -D -G supergroup spark

ENV SPARK_HOME /usr/local/spark/
