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

ARG FIRMWARE_VERSION=1.20210303

# Download Raspberry firmware and unpack /opt/vc folder
RUN curl -kL https://github.com/raspberrypi/firmware/archive/${FIRMWARE_VERSION}.tar.gz -o firmware.tgz \
 && tar xpf firmware.tgz \
 && cp -a firmware-${FIRMWARE_VERSION}/opt/vc /opt/vc \
 && rm -fr firmware.tgz firmware-${FIRMWARE_VERSION}

ADD . /rpiplay/src

WORKDIR /rpiplay/src/build

RUN cmake ..
RUN make

ARG BIN_VERSION=1.2
ARG DEB_VERSION=1

WORKDIR /rpiplay/rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf/
RUN mkdir -p DEBIAN/
RUN mkdir -p usr/bin
RUN mkdir -p lib/systemd/system/

WORKDIR /rpiplay/
COPY .github/build/systemctl.service /rpiplay/rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf/lib/systemd/system/rpiplay.service
COPY .github/build/debian.control /rpiplay/rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf/DEBIAN/control
RUN sed -i "s/^Version: 1.2/Version: 1.2-${DEB_VERSION}/g" /rpiplay/rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf/DEBIAN/control
RUN cp src/build/rpiplay /rpiplay/rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf/usr/bin/
RUN dpkg-deb --build --root-owner-group rpiplay_${BIN_VERSION}-${DEB_VERSION}_armhf

FROM scratch

COPY --from=builder /rpiplay/src/build/rpiplay /rpiplay
COPY --from=builder /rpiplay/rpiplay_*.deb /
