#Hints

* The following steps need to be done before compiling the spring app natively
  * Install Docker Desktop App: `https://www.docker.com/products/docker-desktop/`
  * Install and setup zulu-17 jdk `https://www.azul.com/downloads/?package=jdk#zulu` (Note: It has to be JDK 17)
  * Download `apache-maven-3.9.6-bin.tar.gz` and place it into the root project folder
* run command `mvn clean verify`
* run command `docker build -t testimg .`
* run command `docker images` to find the image id
* run command `docker run <image_id>` to run the actual image