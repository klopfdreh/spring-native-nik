FROM redhat/ubi9-minimal:9.3-1552@sha256:582e18f13291d7c686ec4e6e92d20b24c62ae0fc72767c46f30a69b1a6198055

ARG RUNTIMEUSER=1001

ENV ARTIFACT_JAR_PATTERN=spring-native-nik-1.0.0-SNAPSHOT-exe.jar
ENV MAIN_CLASS=spring.nat.nik.NativeApplications
ENV BINARY_NAME=spring-native-tools-test

ENV NIK_TAR_GZ=bellsoft-liberica-vm-openjdk17.0.10+13-23.0.3+1-linux-aarch64.tar.gz
ENV NIK_DOWNLOAD_URL=https://github.com/bell-sw/LibericaNIK/releases/download/23.0.3%2B1-17.0.10%2B13/${NIK_TAR_GZ}
ENV NIK_FOLDER=bellsoft-liberica-vm-openjdk17-23.0.3
ENV NIK_CHECKSUM=b85c2ec281935b13679c7711d119c6ac65df6a38

# ENV MAVEN_FOLDER=apache-maven-3.9.6
# ENV MAVEN_TAR_GZ=apache-maven-3.9.6-bin.tar.gz

USER root

# Install required tools
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y tar g++ make zlib-devel gzip findutils
RUN microdnf clean all

# Liberica Native Image Kit
RUN mkdir -p /Library/Java/LibericaNativeImageKit/
WORKDIR /Library/Java/LibericaNativeImageKit/
RUN curl -OL ${NIK_DOWNLOAD_URL}
RUN echo "'$(sha1sum ${NIK_TAR_GZ})' checked against '${NIK_CHECKSUM}  ${NIK_TAR_GZ}'"
RUN if [ $(sha1sum ${NIK_TAR_GZ}) != `echo ${NIK_CHECKSUM}  ${NIK_TAR_GZ}` ]; then exit 1; fi
RUN tar -zxvf ./${NIK_TAR_GZ}
RUN rm ./${NIK_TAR_GZ}
ENV NIK_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV JAVA_HOME=/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/
ENV PATH="$PATH:/Library/Java/LibericaNativeImageKit/${NIK_FOLDER}/bin/"

# Maven (not required)
# RUN mkdir -p /Library/Java/maven
# COPY ./${MAVEN_TAR_GZ} /Library/Java/maven/
# WORKDIR /Library/Java/maven/
# RUN tar -zxvf ./${MAVEN_TAR_GZ}
# RUN rm ./${MAVEN_TAR_GZ}
# ENV PATH="$PATH:/Library/Java/maven/${MAVEN_FOLDER}/bin"

# Build native image
RUN mkdir -p /native-image-build/
COPY ./target/${ARTIFACT_JAR_PATTERN} /native-image-build/
WORKDIR /native-image-build/
COPY ./InitializeAtBuildTime /native-image-build/
COPY ./InitializeAtRunTime /native-image-build/
RUN jar -xvf ${ARTIFACT_JAR_PATTERN}
RUN native-image \
`if [ -s ./InitializeAtBuildTime ] ; then echo -n '--initialize-at-build-time=' ; cat ./InitializeAtBuildTime | tr "\n" "," ; fi` \
`if [ -s ./InitializeAtRunTime ] ; then echo -n '--initialize-at-run-time=' ; cat ./InitializeAtRunTime | tr "\n" "," ; fi` \
--no-fallback \
-march=native \
--enable-https \
-H:Name=${BINARY_NAME} \
-cp .:BOOT-INF/classes:`find BOOT-INF/lib | tr '\n' ':'` ${MAIN_CLASS}

# Copy native image to destination
RUN mkdir -p /native-image/
RUN mv /native-image-build/${BINARY_NAME} /native-image/${BINARY_NAME}
RUN rm -Rf /native-image-build/

RUN microdnf remove -y tar gcc cpp make g++ zlib-devel gzip findutils

USER ${RUNTIMEUSER}

# For debug
#ENTRYPOINT ["sleep", "infinity"]

# Run binary
ENTRYPOINT [ "bash", "-c", "/native-image/${BINARY_NAME}" ]