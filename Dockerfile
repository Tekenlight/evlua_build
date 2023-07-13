# Use Ubuntu as the base image
FROM ubuntu:latest
# FROM ubuntu/postgres:14-22.04_beta

# Set the working directory inside the container
WORKDIR /platform

# Install any necessary dependencies
RUN apt-get update
RUN apt install zlib1g -y
RUN apt-get install -y zlib1g-dev
RUN apt-get install -y git
RUN apt-get install -y python3-dev
RUN apt-get install -y cmake
RUN apt-get install -y g++
RUN apt-get install -y build-essential
RUN apt-get install -y clang
RUN apt-get install -y liblzma-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y libreadline-dev
RUN apt-get install -y autoconf
RUN apt-get install -y libtool
RUN apt-get install -y libsqlite3-dev
RUN apt-get install -y wget
RUN apt-get install -y zip
RUN apt-get install -y pkg-config
