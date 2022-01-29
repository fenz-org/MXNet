ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE}

USER root

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHON_VERSION="3.8"

WORKDIR /tmp

# Intall Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        curl \
        wget \
        unzip \
        ca-certificates \
        sudo \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-distutils \
        python3-pip \
        g++ \
        libopencv-dev \
        protobuf-compiler \
        libprotoc-dev \
        python3-opencv && \
    cd /usr/bin && \
    ln -s python${PYTHON_VERSION} python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install MKL
ADD https://raw.githubusercontent.com/intel/oneapi-containers/master/images/docker/basekit/third-party-programs.txt /third-party-programs.txt

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gpg-agent \
        software-properties-common && \
  rm -rf /var/lib/apt/lists/*
# repository to install Intel(R) oneAPI Libraries
RUN curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB | apt-key add -
RUN echo "deb [trusted=yes] https://apt.repos.intel.com/mkl all main " > /etc/apt/sources.list.d/intel-mkl.list

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        intel-mkl-2019.5-075 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/opt/intel/lib/intel64_lin:$LD_LIBRARY_PATH

# Install MXNet
ARG MXNET_VER=1.7.0
RUN python${PYTHON_VERSION} -m pip install --ignore-installed --no-cache-dir \
        cmake && \
    git clone \
        --depth 1 \
        --single-branch \
        -b ${MXNET_VER} \
        https://github.com/apache/incubator-mxnet.git && \
    cd incubator-mxnet && \
    git submodule update --init --recursive && \
    make -j 2 \
        USE_OPENCV=0 \
        USE_MKLDNN=1 \
        USE_BLAS=mkl \
        USE_PROFILER=0 \
        USE_LAPACK=0 \
        USE_GPERFTOOLS=0 \
        USE_INTEL_PATH=/opt/intel/ && \
    cd python && \
    python setup.py install
