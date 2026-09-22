# syntax=docker/dockerfile:1

# ---- Estagio 1: build ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# Copia primeiro o pom.xml e o Maven Wrapper para aproveitar o cache de camadas
# do Docker: as dependencias so sao baixadas novamente se o pom.xml mudar.
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN mvn -B dependency:go-offline

# Copia o codigo fonte e empacota a aplicacao. Os testes sao pulados aqui
# porque ja rodam separadamente via CI/dev.
COPY src src
RUN mvn -B package -DskipTests

# ---- Estagio 2: runtime ----
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=build /build/target/tecsys-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
