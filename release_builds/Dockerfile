FROM docker.io/debian:9.3-slim

RUN apt-get update \
&& apt-get install -y python3-pip \
&& useradd -ms /bin/bash cc

# install matlab mcr
RUN apt-get install -y curl unzip libxt6 libncurses5 libxext6 \
&& mkdir /mcr-install \
&& curl -L https://www.mathworks.com/supportfiles/downloads/R2015a/deployment_files/R2015a/installers/glnxa64/MCR_R2015a_glnxa64_installer.zip > /mcr-install/installer.zip \
&& unzip /mcr-install/installer.zip -d /mcr-install \
&& /mcr-install/install -agreeToLicense yes -mode silent \
&& rm -r /mcr-install

# install cc-core
USER cc

RUN pip3 install --no-input --user cc-core==3.2.0

ENV PATH="/home/cc/.local/bin:${PATH}"
ENV PYTHONPATH="/home/cc/.local/lib/python3.5/site-packages/"

# install required connector
RUN pip3 install --no-input --user red-connector-xnat

## own application from repository
RUN curl -sSL https://github.com/somnonetz/physiological-networks-tds/releases/download/1.0.0/run_sn_TDS.sh > /home/cc/.local/bin/run_sn_TDS.sh
RUN curl -sSL https://github.com/somnonetz/physiological-networks-tds/releases/download/1.0.0/sn_TDS > /home/cc/.local/bin/sn_TDS


