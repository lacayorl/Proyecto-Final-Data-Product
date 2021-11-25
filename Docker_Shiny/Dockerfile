# Base image https://hub.docker.com/u/rocker/
FROM obedaeg/shiny:latest


RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libsqlite3-dev \
    libmariadbd-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libglpk-dev

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean


RUN Rscript -e 'install.packages("shiny")'
RUN Rscript -e 'install.packages("shinydashboard")'
RUN Rscript -e 'install.packages("formattable")'
RUN Rscript -e 'install.packages("shinyWidgets")'
RUN Rscript -e 'install.packages("leaflet")'
RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("tidyr")'
RUN Rscript -e 'install.packages("lubridate")'
RUN Rscript -e 'install.packages("igraph")'
RUN Rscript -e 'install.packages("highcharter")'
RUN Rscript -e 'install.packages("RMySQL")'
RUN Rscript -e 'install.packages("DBI")'
RUN Rscript -e 'install.packages("ggplot2")'
RUN Rscript -e 'install.packages("plotly")'
RUN Rscript -e 'install.packages("scales")'
RUN Rscript -e 'install.packages("broom")'
RUN Rscript -e 'install.packages("xts")'
