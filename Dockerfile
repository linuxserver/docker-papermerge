FROM lsiobase/ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PAPERMERGE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips"

# ensures our console output looks familiar and is not buffered by Docker
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE config.settings.production

ARG BUILD_PACKAGES="\
	apache2-dev \
	build-essential \
	git \
	locales \
	python3-dev"

# packages as variables
ARG RUNTIME_PACKAGES="\
	imagemagick \
	pdftk-java \
	poppler-utils \
	python3 \
	python3-pip \
	tesseract-ocr \
	tesseract-ocr-eng \
	uwsgi \
	uwsgi-plugin-python3"

RUN \
 apt update && \
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
 pip3 install -r requirements/base.txt && \
 pip3 install -r requirements/production.txt && \
 pip3 install -r requirements/extra.txt && \
 echo "**** cleanup ****" && \
 apt-get purge -y --auto-remove \
	$BUILD_PACKAGES && \
 rm -rf \
	/root/.cache \
	/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8000
