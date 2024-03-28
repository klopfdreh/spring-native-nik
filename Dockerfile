FROM redhat/ubi9-minimal:9.3-1552@sha256:582e18f13291d7c686ec4e6e92d20b24c62ae0fc72767c46f30a69b1a6198055

ENV ARTIFACT_JAR=spring-native-nik-1.0.0-SNAPSHOT-exe.jar
ENV MAIN_CLASS=spring.nat.nik.NativeApplications
ENV BINARY_NAME=spring-native-tools-test

ENV NIK_FOLDER=bellsoft-liberica-vm-openjdk17-23.0.3
ENV NIK_TAR_GZ=bellsoft-liberica-vm-openjdk17.0.10+13-23.0.3+1-linux-aarch64.tar.gz

ENV MAVEN_FOLDER=apache-maven-3.9.6
ENV MAVEN_TAR_GZ=apache-maven-3.9.6-bin.tar.gz

USER root

RUN microdnf install tar --assumeyes g++ --assumeyes make --assumeyes zlib-devel --assumeyes gzip --assumeyes findutils --assumeyes #zlib1g-dev

# Liberica Native Image Kit
RUN mkdir -p /Library/Java/LibericaNativeImageKit/
COPY ./${NIK_TAR_GZ} /Library/Java/LibericaNativeImageKit/
WORKDIR /Library/Java/LibericaNativeImageKit/
RUN tar -zxvf ./${NIK_TAR_GZ}
RUN rm ./${NIK_TAR_GZ}
ENV NIK_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV JAVA_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV PATH="$PATH:/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/bin"

# Maven (not required)
# RUN mkdir -p /Library/Java/maven
# COPY ./${MAVEN_TAR_GZ} /Library/Java/maven/
# WORKDIR /Library/Java/maven/
# RUN tar -zxvf ./${MAVEN_TAR_GZ}
# RUN rm ./${MAVEN_TAR_GZ}
# ENV PATH="$PATH:/Library/Java/maven/${MAVEN_FOLDER}/bin"

# Build native image
RUN mkdir -p /native-image/
COPY ./target/${ARTIFACT_JAR} /native-image/
WORKDIR /native-image/
RUN jar -xvf ${ARTIFACT_JAR}
RUN rm ./${ARTIFACT_JAR}
RUN native-image --no-fallback -march=native --enable-https -H:Name=${BINARY_NAME} -cp .:BOOT-INF/classes:`find BOOT-INF/lib | tr '\n' ':'` ${MAIN_CLASS}

# For debug
#ENTRYPOINT ["sleep", "infinity"]

# Run binary
ENTRYPOINT [ "bash", "-c", "/native-image/${BINARY_NAME}" ]