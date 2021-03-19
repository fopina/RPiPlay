FROM debian:buster-slim AS builder

# dependencies, per README.md
RUN apt-get update \
 && apt-get -y install build-essential \
                       curl \
                       # the ones from README:md
                       cmake \
                       libavahi-compat-libdnssd-dev \
                       libplist-dev \
                       libssl-dev

WORKDIR /rpiplay

# Download Raspberry firmware and unpack /opt/vc folder
ARG FIRMWARE_VERSION=1.20210303
RUN curl -kL https://github.com/raspberrypi/firmware/archive/${FIRMWARE_VERSION}.tar.gz -o firmware.tgz \
 && tar xpf firmware.tgz \
 && cp -a firmware-${FIRMWARE_VERSION}/opt/vc /opt/vc \
 && rm -fr firmware.tgz firmware-${FIRMWARE_VERSION}

ADD . /rpiplay/src

WORKDIR /rpiplay/src/build

RUN cmake ..
RUN make

FROM scratch

COPY --from=builder /rpiplay/src/build/rpiplay /rpiplay
