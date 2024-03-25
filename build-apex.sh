#!/usr/bin/env bash

# Script setup
set -e -x -o pipefail

# Load system-level dependencies
# spack load gcc@10.3.0

# GLIB C/CXX stuff
# export GLIB_HOME="$(dirname $(dirname $(which gcc)))"
export CC="/usr/bin/gcc10-gcc"
export CXX="/usr/bin/gcc10-g++"

# NVCC Setup
export NVCC_PREPEND_FLAGS="-ccbin ${CXX}"

# Customizable Envvars
export CUDA_HOME="/usr/local/cuda"
export NCCL_HOME="/opt/nccl/build"
export CUDNN_HOME="/mnt/sharedfs/megatron/deps/cudnn-linux-x86_64-8.9.7.29_cuda12-archive"
export CUSPARSELT_HOME="/mnt/sharedfs/megatron/deps/libcusparse_lt-linux-x86_64-0.5.1.1-archive"
export NVIDIA_PROFILER_LDPATHS="/usr/local/cuda/lib64"
export NCCL_HOME="/opt/nccl/build"
export MAGMA_HOME="/opt/magma"

export APEX_REPO_LOC="/mnt/sharedfs/megatron/deps/apex"
export VENV_LOC="/mnt/sharedfs/megatron/venv"
export NVCC_GENCODE="-gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_90a,code=sm_90a"
export TAG_OR_COMMIT="810ffae374a2b9cb4b5c5e28eaeca7d7998fca0c"

# Set up library paths
export LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LD_LIBRARY_PATH}"

# Build Flags
export TORCH_CUDA_ARCH_LIST="9.0;9.0+PTX"

# Clone if doesn't exist
if [ ! -d "${APEX_REPO_LOC}" ]; then
  git clone https://github.com/NVIDIA/apex "${APEX_REPO_LOC}"
fi

# Activate Python venv
# WARNING: THIS IS BROKEN! SEEMS TO IGNORE LD_LIBRARY_PATH!
# source "${VENV_LOC}/bin/activate"

# Install necessary dependencies
"${VENV_LOC}/bin/pip" install packaging wheel

# Verify can load torch from this environment
"${VENV_LOC}/bin/python" -c "import torch; print(f'CUDA Available: {torch.cuda.is_available}')"

# Enter apex repo
pushd "${APEX_REPO_LOC}" || exit

echo "[INFO] Full LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"
"${VENV_LOC}/bin/pip" install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" "${APEX_REPO_LOC}"

# Exit
popd || exit