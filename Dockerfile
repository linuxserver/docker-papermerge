FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PAPERMERGE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips"

# ensures our console output looks familiar and is not buffered by Docker
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE config.settings.production

# NOTE: the additional lib and python dependencies are for the ARM builds
ARG BUILD_PACKAGES="\
	apache2-dev \
	build-essential \
	git \
	libffi-dev \
	libpq-dev \
	libmariadbclient-dev \
	libxml2-dev \
	libxslt-dev \
	python3-dev \
	python3-pip"

# packages as variables
ARG RUNTIME_PACKAGES="\
	imagemagick \
	libmariadb3 \
	libpq5 \
	libxslt1.1 \
	poppler-utils \
	python3 \
	python3-cryptography \
	python3-distutils \
	python3-mysqldb \
	python3-psycopg2 \
	python3-setuptools \
	redis \
	tesseract-ocr \
	tesseract-ocr-eng \
	uwsgi \
	uwsgi-plugin-python3"

RUN \
 apt-get update && \
 echo "**** install build packages ****" && \
 apt-get install -y \
 	--no-install-recommends \
	$BUILD_PACKAGES && \
 echo "**** install runtime packages ****" && \
 apt-get install -y \
 	--no-install-recommends \
	$RUNTIME_PACKAGES && \
 echo "**** install papermerge ****" && \
 mkdir -p /app/papermerge && \
 if [ -z ${PAPERMERGE_RELEASE+x} ]; then \
	PAPERMERGE_RELEASE=$(curl -sX GET "https://api.github.com/repos/ciur/papermerge/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
 	/tmp/papermerge.tar.gz -L \
	"https://github.com/ciur/papermerge/archive/${PAPERMERGE_RELEASE}.tar.gz" && \
 tar xf \
 	/tmp/papermerge.tar.gz -C \
	/app/papermerge/ --strip-components=1 && \
 echo "**** install pip packages ****" && \
 cd /app/papermerge && \
 pip3 install django==3.1.7 && \
 /bin/bash -c 'shopt -s globstar && \
    for f in ./requirements/**/*; do pip3 install -r $f; done && \
    shopt -u globstar' && \
 echo "**** cleanup ****" && \
 apt-get purge -y --auto-remove \
	$BUILD_PACKAGES && \
 rm -rf \
	/root/.cache \
	/tmp/* && \
 apt-get clean -y

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8000
