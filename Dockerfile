ARG BASE_IMAGE=ubuntu:24.04
####################################################
## Build Packages from github
####################################################
FROM $BASE_IMAGE AS build
# apt install tools needed for build
RUN apt-get update \
    && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    g++-10 \
    gcc-10 \
    git \
    python3 \
    wget \
    zlib1g-dev \
    libterm-readline-gnu-perl

# create a programs directory for building and a bin directory for finished binaries
RUN mkdir -p /opt/programs && mkdir -p /opt/bin

FROM build AS vt
WORKDIR /opt/programs
RUN git clone --branch 0.577 https://github.com/atks/vt.git
WORKDIR /opt/programs/vt
RUN git submodule update --init --recursive
RUN make
RUN make test
RUN mv vt /opt/bin/vt

FROM build AS wrangler
# install MIPWrangler
WORKDIR /opt/bin
RUN git clone --branch develop https://github.com/bailey-lab/MIPWrangler.git
WORKDIR /opt/bin/MIPWrangler
RUN ./install.sh 20
RUN rm -rf /opt/bin/MIPWrangler/external/build/

FROM build AS parasight
# install parasight
WORKDIR /opt/programs
RUN git clone --branch v7.6 https://github.com/bailey-lab/parasight.git
RUN cp parasight/parasight.pl /opt/bin/

FROM build AS basespace
# install basespace cli
RUN wget "https://launch.basespace.illumina.com/CLI/1.5.1/amd64-linux/bs" \
  -O /opt/bin/bs

####################################################
######## Final image with just the binaries ########
####################################################
FROM $BASE_IMAGE AS final
RUN apt-get update \
    && apt-get -yq dist-upgrade
COPY --from=vt /opt/bin /opt/bin
COPY --from=wrangler /opt/bin /opt/bin
COPY --from=parasight /opt/bin /opt/bin
COPY --from=basespace /opt/bin /opt/bin