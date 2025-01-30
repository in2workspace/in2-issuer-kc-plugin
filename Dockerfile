# Prepare the build environment
FROM maven:3.8.4-openjdk-17-slim AS tmp_builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
COPY /api/api.yaml ./api/
COPY /api/openapi.yaml ./api/
RUN mvn clean install

# Build the final image
FROM quay.io/keycloak/keycloak:24.0.1
USER root
RUN ["sed", "-i", "s/SHA1, //g", "/usr/share/crypto-policies/DEFAULT/java.txt"]
USER 1000
COPY --from=tmp_builder /app/target/classes/keyfile.json /opt/keycloak/providers/keyfile.json
COPY --from=tmp_builder /app/target/in2-keycloak-extension-1.1.1.jar /opt/keycloak/providers/
COPY /themes /opt/keycloak/themes
ENV VCISSUER_ISSUER_DID="did:key:z6MkqmaCT2JqdUtLeKah7tEVfNXtDXtQyj4yxEgV11Y5CqUa"
ENV VCISSUER_ISSUER_KEY_FILE="/opt/keycloak/providers/keyfile.json"
EXPOSE 8080
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--health-enabled=true","--metrics-enabled=true", "--log-level=INFO", "--import-realm"]