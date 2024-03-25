#!/usr/bin/env bash

# Script setup
set -e -x -o pipefail

# GLIB andC/CXX stuff
export CC="/usr/bin/gcc10-gcc"
export CXX="/usr/bin/gcc10-g++"

# NVCC Setup
export NVCC_PREPEND_FLAGS="-ccbin ${CXX}"

# Customizable Envvars
export MPI_HOME="/opt/amazon/openmpi"
export CUDA_HOME="/usr/local/cuda"
export CUDA_MATH_LIBS_HOME="${CUDA_HOME}"
# export CUDNN_HOME="/opt/cudnn"
export CUDNN_HOME="/mnt/sharedfs/megatron/deps/cudnn-linux-x86_64-8.9.7.29_cuda12-archive"
# export CUSPARSELT_HOME="/opt/libcusparse_lt"
export CUSPARSELT_HOME="/mnt/sharedfs/megatron/deps/libcusparse_lt-linux-x86_64-0.5.1.1-archive"
export NVIDIA_PROFILER_LDPATHS="/usr/local/cuda/lib64"
export NCCL_HOME="/opt/nccl/build"
export MAGMA_HOME="/opt/magma"
export TORCHVISION_REPO_LOC="/mnt/sharedfs/megatron/pytorch/torchvision-repo"
export NVCC_GENCODE="-gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_90a,code=sm_90a"
export TAG_OR_COMMIT="a0c79b399b75368208464b2c638708165cca7ef1"

export VENV="/mnt/sharedfs/megatron/pytorch/.venv"

# Add all home directories (pls CMAKE, pls find everything with this)
export CMAKE_PREFIX_PATH="${NCCL_HOME}:${MAGMA_HOME}:${MPI_HOME}:${CUDA_MATH_LIBS_HOME}:${CUDNN_HOME}:${CUSPARSELT_HOME}:${CUDA_HOME}"

# Set up include directories (doesn't appear to work?)
export CMAKE_INCLUDE_PATH="${NCCL_HOME}/include:${MAGMA_HOME}/include:${MPI_HOME}/include:${CUDA_MATH_LIBS_HOME}/include:${CUDNN_HOME}/include:${CUSPARSELT_HOME}/include:${CUDA_HOME}/include"

# Set up library paths
export CMAKE_LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib"
export LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LD_LIBRARY_PATH}"

# Build Flags
export MAX_JOBS=94
export CUDNN_LIB_DIR="${CUDNN_HOME}/lib"
export CUDNN_INCLUDE_DIR="${CUDNN_HOME}/include"
export CUDNN_LIBRARY="${CUDNN_LIB_DIR}/libcudnn.so"
export NCCL_ROOT="${NCCL_HOME}"
export NCCL_INCLUDE_DIR="${NCCL_HOME}/include"
export NCCL_LIB_DIR="${NCCL_HOME}/lib"
export TORCH_CUDA_ARCH_LIST="9.0;9.0+PTX"  # 9.0a is currently broken?
export FORCE_CUDA=1

# Clone if doesn't exist
if [ ! -d "${TORCHVISION_REPO_LOC}" ]; then
  git clone https://github.com/pytorch/vision.git "${TORCHVISION_REPO_LOC}"
fi

# Enter pytorch repo
pushd "${TORCHVISION_REPO_LOC}" || exit

# Check out version
git checkout "${TAG_OR_COMMIT}"

source "${VENV}/bin/activate"

# Install python dependencies
pip install expecttest flake8 typing mypy pytest pytest-mock scipy

# Clean (OPTIONAL: Uncomment only if you want to clean the build first!)
# python setup.py clean

# Build
python setup.py install

# Exit repo
popd || exit
