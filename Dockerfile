#-----------------------------------------------------------------------------
# Variables are shared across multiple stages (they need to be explicitly
# opted into each stage by being declaring there too, but their values need
# only be specified once).

ARG KOBWEB_APP_ROOT="site"
ARG KOBWEB_CLI_VERSION=0.9.15

FROM eclipse-temurin:17 as java

#-----------------------------------------------------------------------------
# Create an intermediate stage which builds and exports our site. In the
# final stage, we'll only extract what we need from this stage, saving a lot
# of space.
FROM java as builder

ARG KOBWEB_APP_ROOT
ARG KOBWEB_CLI_VERSION

ENV NODE_MAJOR=20

# Update and install required OS packages to continue
# Note: Node install instructions from: https://github.com/nodesource/distributions#installation-instructions
# Note: Playwright is a system for running browsers, and here we use it to
# install Chromium.
RUN pwd

RUN apt-get update && \
    apt-get install -y curl gnupg unzip wget && \
    apt-get install -y ca-certificates && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm init -y && \
    npx playwright install --with-deps chromium

# Fetch the Kobweb CLI
WORKDIR /
RUN wget https://github.com/varabyte/kobweb-cli/releases/download/v${KOBWEB_CLI_VERSION}/kobweb-${KOBWEB_CLI_VERSION}.zip
RUN unzip kobweb-${KOBWEB_CLI_VERSION}.zip
RUN rm kobweb-${KOBWEB_CLI_VERSION}.zip
ENV PATH="/kobweb-${KOBWEB_CLI_VERSION}/bin:${PATH}"


#RUN apt-get install -y libglib2.0-0\
    #libnss3\
    #libnspr4\
    #libatk1.0-0\
    #libatk-bridge2.0-0\
    #libcups2\
    #libdbus-1-3\
    #libdrm2\
    #libxcb1\
    #libxkbcommon0\
    #libatspi2.0-0\
    #libx11-6\
    #libxcomposite1\
    #libxdamage1\
    #libxext6\
    #libxfixes3\
    #libxrandr2\
    #libgbm1\
    #libpango-1.0-0\
    #libcairo2\
    #libasound2


# cache gradle
# (Useful for faster local iteration, but just adds noise in prod)
#COPY  gradlew gradlew.bat settings.gradle.kts gradle.properties /project/
#COPY  gradle/wrapper/ /project/gradle/wrapper
#WORKDIR /project
#RUN pwd
#RUN find .
#RUN ./gradlew tasks --no-daemon

# Decrease Gradle memory usage to avoid OOM situations in tight environments
# (many free Cloud tiers only give you 512M of RAM). The following amount
# should be more than enough to build and export our site.
RUN mkdir ~/.gradle
RUN echo "org.gradle.jvmargs=-Xmx512m" >> ~/.gradle/gradle.properties

COPY . /project
WORKDIR /project/${KOBWEB_APP_ROOT}
RUN kobweb export --notty

#WORKDIR /project
#RUN ./gradlew kobwebExport -PkobwebReuseServer=false -PkobwebEnv=DEV -PkobwebRunLayout=KOBWEB -PkobwebBuildTarget=RELEASE -PkobwebExportLayout=KOBWEB --stacktrace

#-----------------------------------------------------------------------------
# Create the final stage, which contains just enough bits to run the Kobweb
# server.
FROM java as run

ARG KOBWEB_APP_ROOT

COPY --from=builder /project/${KOBWEB_APP_ROOT}/.kobweb .kobweb

EXPOSE 8080
ENTRYPOINT .kobweb/server/start.sh
