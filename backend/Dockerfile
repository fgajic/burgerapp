FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml ./
RUN mvn -B -q -e -DskipTests dependency:resolve dependency:resolve-plugins

COPY src ./src
RUN mvn -B -q -e -DskipTests clean package

FROM eclipse-temurin:21-jre
WORKDIR /app

RUN useradd -r -u 1001 appuser

COPY --from=build /app/target/*.jar /app/app.jar

EXPOSE 8080

ENV SPRING_PROFILES_ACTIVE=docker \
    SERVER_PORT=8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

USER appuser

ENTRYPOINT ["java","-jar","/app/app.jar"]
