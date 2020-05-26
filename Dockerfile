FROM cran/debian

VOLUME /data

# Extra sysdeps needed for 'virtuoso' pkg
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -yq install virtuoso-opensource

ADD setup.R /tmp/setup.R
RUN Rscript /tmp/setup.R

# Workaround for buggy courier fonts
RUN rm -Rf /usr/share/fonts/type1/texlive-fonts-recommended

ADD build.R /build.R
ADD deploy.R /deploy.R
ADD info.R /info.R
ADD universe.R /universe.R
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
