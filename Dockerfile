FROM openjdk:8-jdk-alpine

# Add Maintainer Info
LABEL maintainer="rykelley@gmail.com"

# Make port 8081 available to the world outside this container
EXPOSE 8081

# The application's jar file
ARG JAR_FILE=target/umsl-0.0.1-SNAPSHOT.jar

# Add the application's jar to the container
ADD ${JAR_FILE} umsl-0.0.1-SNAPSHOT.jar

# Run the jar file
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/umsl-0.0.1-SNAPSHOT.jar"]
