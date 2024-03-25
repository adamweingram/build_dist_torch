#!/usr/bin/env bash

# Script setup
set -e -x -o pipefail

# Get modules, etc.
# module load cuda
# spack load gcc@10.4.0%gcc@8.5.0  # Have to use <=v11 because otherwise nvcc complains

# Envvars
# export CUDA_HOME="/opt/nvidia/hpc_sdk/Linux_x86_64/21.9/cuda"
export CUDA_HOME="$(realpath deps/cuda)"
# export INTEL_MKL_HOME="/opt/intel/mkl"
export OPENBLAS_HOME="/opt/openblas"
export MAGMA_TMP_DIR="/tmp/magma"
export MAGMA_DIR="/home/Adam/Research/LY-SC-24-MSCCL/pytorch-build/deps/magma"
export MAGMA_INSTALL_DIR="/opt/magma"

export MAGMA_GPU_TARGET="Volta Turing Ampere Hopper"  # Default is `Volta Turing Ampere`
export NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80"

# Set up environment
export PATH="${CUDA_HOME}/bin:${INTEL_MKL_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib:${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"

# Create temp dir
mkdir -p "${MAGMA_TMP_DIR}"

# Enter temp dir
pushd "${MAGMA_TMP_DIR}" || exit

# Clone if doesn't exist
if [ ! -d "${MAGMA_DIR}" ]; then
    # Download
    MAGMA_TAR_FILE="magma-2.7.2.tar.gz"
    curl -fsSL -L "https://icl.utk.edu/projectsfiles/magma/downloads/${MAGMA_TAR_FILE}" -o "${MAGMA_TMP_DIR}/${MAGMA_TAR_FILE}"

    # Unarchive
    mkdir -p "${MAGMA_DIR}"
    tar -axf "${MAGMA_TMP_DIR}/${MAGMA_TAR_FILE}" -C "${MAGMA_DIR}" --strip-components=1
fi

# Exit temp dir
popd || exit

# Enter MAGMA repo
pushd "${MAGMA_DIR}" || exit

if [ -z "${INTEL_MKL_HOME}" ]; then
    # Copy relevant make.inc file
    cp "${MAGMA_DIR}/make.inc-examples/make.inc.openblas" "${MAGMA_DIR}/make.inc"

    # Build
    # Note: Can append `install` and include `prefix=/usr/local/magma` to install to a specific location
    make OPENBLASDIR="${OPENBLAS_HOME}" CUDADIR="${CUDA_HOME}" GPU_TARGET="${MAGMA_GPU_TARGET}" -j 
else
    # Copy relevant make.inc file
    cp "${MAGMA_DIR}/make.inc-examples/make.inc.mkl-gcc" "${MAGMA_DIR}/make.inc"

    # Build
    # Note: Can append `install` and include `prefix=/usr/local/magma` to install to a specific location
    make MKLROOT="${INTEL_MKL_HOME}" CUDADIR="${CUDA_HOME}" GPU_TARGET="${MAGMA_GPU_TARGET}" -j 
fi

# Install
sudo make install prefix="${MAGMA_INSTALL_DIR}"

# Exit repo
popd || exit
