FROM julia:1.0-stretch

RUN apt-get update
RUN apt-get install -y apt-utils

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y usbutils

ENV PYLON_VERSION 5.1.0.12682
ENV PYLON_SHA1SUM 2e051aa9e6470dc22eeb6069514c845f3dff4752

WORKDIR /root
RUN export TIME_LIMIT=`echo $(($(date +%s) + 24*60*60))` && curl https://www.baslerweb.com/fp-${TIME_LIMIT}/media/downloads/software/pylon_software/pylon_${PYLON_VERSION}-deb0_amd64.deb -O
RUN echo "${PYLON_SHA1SUM} pylon_${PYLON_VERSION}-deb0_amd64.deb" | sha1sum -c
RUN DEBIAN_FRONTEND=noninteractive dpkg -i pylon_${PYLON_VERSION}-deb0_amd64.deb
RUN rm -f pylon_${PYLON_VERSION}-deb0_amd64.deb

ENV LD_LIBRARY_PATH=/opt/pylon5/lib64

COPY . /project
WORKDIR /project

RUN julia --project --eval 'using Pkg; pkg"instantiate"; pkg"build"; using PylonCameras'

CMD julia --project -i
