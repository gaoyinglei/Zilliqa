# Copyright (c) 2018 Zilliqa
# This source code is being disclosed to you solely for the purpose of your
# participation in testing Zilliqa. You may view, compile and run the code for
# that purpose and pursuant to the protocols and algorithms that are programmed
# into, and intended by, the code. You may not do anything else with the code
# without express permission from Zilliqa Research Pte. Ltd., including
# modifying or publishing the code (or any part of it), and developing or
# forming another public or private blockchain network. This source code is
# provided 'as is' and no warranties are given as to title or non-infringement,
# merchantability or fitness for purpose and, to the extent permitted by law,
# all liability for your use of the code is disclaimed. Some programs in this
# code are governed by the GNU General Public License v3.0 (available at
# https://www.gnu.org/licenses/gpl-3.0.en.html) ('GPLv3'). The programs that
# are governed by GPLv3.0 are those programs that are located in the folders
# src/depends and tests/depends and which include a reference to GPLv3 in their
# program files.
#
#
#------------------------------------------------------------------------------
FROM ubuntu:16.04 AS zilliqa-ci
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main" >> /etc/apt/sources.list.d/llvm.list \
    && echo "deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial-7 main" >> /etc/apt/sources.list.d/llvm.list \
    && curl https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
    && apt-get update && apt-get install -y --no-install-recommends \
    clang-format-7 \
    clang-tidy-7 \
    && rm -rf /var/lib/apt/lists/*

#------------------------------------------------------------------------------
ARG BASE_IMAGE=ubuntu:16.04
FROM ubuntu:16.04 AS zilliqa-core

# Install build dependencies
# Format guide: one package per line and keep them alphabetically sorted
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libboost-filesystem-dev \
    libboost-system-dev \
    libboost-test-dev \
    libcurl4-openssl-dev \
    libevent-dev \
    libjsoncpp-dev \
    libjsonrpccpp-dev \
    libjsonrpccpp-dev \
    libleveldb-dev \
    libmicrohttpd-dev \
    libminiupnpc-dev \
    libprotobuf-dev \
    libsnappy-dev \
    libssl-dev \
    ocl-icd-opencl-dev \
    protobuf-compiler \
    python \
    python-pip \
    && rm -rf /var/lib/apt/lists/*

# Intentionally left blank unless specific commit is provided in commandline
ARG COMMIT=
ARG REPO=https://github.com/Zilliqa/Zilliqa.git
ARG SOURCE_DIR=/zilliqa
ARG BUILD_DIR=/build
ARG INSTALL_DIR=/usr/local
ARG BUILD_TYPE=RelWithDebInfo

RUN git clone --recursive ${REPO} ${SOURCE_DIR} \
    && git -C ${SOURCE_DIR} checkout ${COMMIT} \
    && cmake -H${SOURCE_DIR} -B${BUILD_DIR} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    && cmake --build ${BUILD_DIR} -- -j$(nproc) \
    && cmake --build ${BUILD_DIR} --target install \
    && rm -rf ${BUILD_DIR}

ENV LD_LIBRARY_PATH=${INSTALL_DIR}/lib
#-----------------------------------------------------------------------------
FROM zilliqa-builder AS zilliqa-k8s
RUN apt-get update && apt-get install -y --no-install-recommends \
    dnsutils \
    gdb \
    less \
    logrotate \
    net-tools \
    rsyslog \
    vim \
    && rm -rf /var/lib/apt/lists/* \
    && pip install setuptools \
    && pip install urllib3==1.23 kubernetes
