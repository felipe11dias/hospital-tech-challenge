# Build unico para os tres servicos.
#
# Por que um Dockerfile com tres targets, e nao um por servico: os tres modulos compartilham o
# pom pai e quase todas as dependencias. Com targets, o BuildKit reaproveita o estagio "build"
# entre as tres imagens e o download do Maven acontece uma vez, nao tres.
#
# O avaliador nao precisa de Java nem de Maven na maquina: a compilacao acontece aqui dentro
# (F6, FR-001).

# ---------------------------------------------------------------------------- build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Os poms primeiro, sozinhos: enquanto nenhuma dependencia mudar, esta camada fica em cache e
# o rebuild depois de uma alteracao de codigo nao baixa nada de novo.
COPY pom.xml ./
COPY agendamento-service/pom.xml agendamento-service/
COPY notificacao-service/pom.xml notificacao-service/
COPY historico-service/pom.xml historico-service/
RUN mvn -B -ntp -DskipTests dependency:go-offline || true

COPY agendamento-service/src agendamento-service/src
COPY notificacao-service/src notificacao-service/src
COPY historico-service/src historico-service/src

# Testes nao rodam aqui: os de integracao precisam de Docker (Testcontainers), o que exigiria
# Docker dentro do Docker. A verificacao `mvn verify` roda na integracao continua
# (.github/workflows/ci.yml) e na maquina do desenvolvedor.
RUN mvn -B -ntp -DskipTests package

# ------------------------------------------------------------------------- runtime base
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app
# Usuario sem privilegio: nenhum servico precisa de root para rodar.
RUN groupadd --system hospital && useradd --system --gid hospital hospital \
    && mkdir -p /app/certs && chown -R hospital:hospital /app
USER hospital
EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# ------------------------------------------------------------------------- um target por servico
FROM runtime AS agendamento-service
COPY --from=build /build/agendamento-service/target/agendamento-service-*.jar /app/app.jar

FROM runtime AS notificacao-service
COPY --from=build /build/notificacao-service/target/notificacao-service-*.jar /app/app.jar

FROM runtime AS historico-service
COPY --from=build /build/historico-service/target/historico-service-*.jar /app/app.jar
