# syntax=docker/dockerfile:1

FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN mvn -B dependency:go-offline

COPY src src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=build /build/target/tecsys-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
