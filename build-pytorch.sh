#!/usr/bin/env bash

# Script setup
set -e -x -o pipefail

# Required versions
# * Python 3.10 (wheel won't be installable with other versions of python)
# * GCC 10.4.0
# * CUDA 11.8.20220929 (You may be able to get around this; I'm not sure which other packages would require different version)
# * CuDNN:  cudnn-linux-x86_64-8.9.7.29_cuda11-archive
# * CuSparseLt: libcusparse_lt-linux-x86_64-0.5.1.1-archive
# * NCCL v2.20.5-1
# Optional:
# * MAGMA: magma-2.7.2


# Get modules, etc.
# module load cuda
# spack load gcc@10.4.0%gcc@8.5.0   # Have to use <=v11 because otherwise nvcc complains
# spack load gcc@10.3.0
# spack load openmpi
# spack load cmake
# spack load ninja

# GLIB andC/CXX stuff
# export GLIB_HOME="$(dirname $(dirname $(which gcc)))"
export GLIB_HOME="/none"
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
export MAGMA_HOME="/opt/magma"  # TODO: Download and prep MAGMA!
export PYTORCH_REPO_LOC="/mnt/sharedfs/megatron/pytorch/pytorch-repo"
export NVCC_GENCODE="-gencode=arch=compute_90,code=sm_90 -gencode=arch=compute_90a,code=sm_90a"
# export TAG_OR_COMMIT="v2.2.1"
export TAG_OR_COMMIT="14e348b7ad1b3472812f2b077020d80deaf6a787"  # Fix "thrust" issues?

# Add all home directories (pls CMAKE, pls find everything with this)
export CMAKE_PREFIX_PATH="${NCCL_HOME}:${MAGMA_HOME}:${MPI_HOME}:${CUDA_MATH_LIBS_HOME}:${CUDNN_HOME}:${CUSPARSELT_HOME}:${CUDA_HOME}"

# Set up include directories (doesn't appear to work?)
export CMAKE_INCLUDE_PATH="${NCCL_HOME}/include:${MAGMA_HOME}/include:${MPI_HOME}/include:${CUDA_MATH_LIBS_HOME}/include:${CUDNN_HOME}/include:${CUSPARSELT_HOME}/include:${CUDA_HOME}/include"

# Set up library paths
export CMAKE_LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib"
export LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${LD_LIBRARY_PATH}"

# # [HACK] [HACK]: Manually force certain compiler flags because CMAKE is shit [HACK] [HACK]
# # Note: CFLAGS is a pytorch envvar, while CMAKE_CXX_FLAGS is a CMake one. 
# export CFLAGS="-I${NCCL_HOME}/include -I${MPI_HOME}/include -I${CUDA_MATH_LIBS_HOME}/include -I${CUDNN_HOME}/include -I${CUSPARSELT_HOME}/include -I${CUDA_HOME}/include"
# export CMAKE_CXX_FLAGS="${CFLAGS}"

# Build Flags
export MAX_JOBS=94
export CUDNN_LIB_DIR="${CUDNN_HOME}/lib"
export CUDNN_INCLUDE_DIR="${CUDNN_HOME}/include"
export CUDNN_LIBRARY="${CUDNN_LIB_DIR}/libcudnn.so"
export NCCL_ROOT="${NCCL_HOME}"
export NCCL_INCLUDE_DIR="${NCCL_HOME}/include"
export NCCL_LIB_DIR="${NCCL_HOME}/lib"
export USE_SYSTEM_NCCL=1  # Use system NCCL instead of the bundled one
export TORCH_CUDA_ARCH_LIST="9.0;9.0+PTX"  # 9.0a is currently broken?
# export USE_GLOO="OFF"
# export USE_KINETO="OFF"
export USE_XNNPACK="OFF"  # Tries to compile with AVX-512 instructions otherwise (and breaks on p5)

# Clone if doesn't exist
if [ ! -d "${PYTORCH_REPO_LOC}" ]; then
  git clone https://github.com/pytorch/pytorch.git "${PYTORCH_REPO_LOC}"
fi

# Enter pytorch repo
pushd "${PYTORCH_REPO_LOC}" || exit

# Check out version
git checkout "${TAG_OR_COMMIT}"

# Create/activate venv
if [ ! -d ".venv" ]; then
  python -m venv .venv
fi
source .venv/bin/activate

# Install python dependencies
pip install -r requirements.txt

# Clean (OPTIONAL: Uncomment only if you want to clean the build first!)
# python setup.py clean

# Build
# NOTE: See setup.py! Most relevant options are there! (https://github.com/pytorch/pytorch/blob/main/setup.py)
# OUTPUT: $PYTORCH_REPO/dist/torch-2.4.0a0+git14e348b-cp310-cp310-linux_x86_64.whl
python setup.py bdist_wheel

# Output necessary things to set in order to run this version of PyTorch
echo "\n\n[IMPORTANT] You will need to run the following to run this version of PyTorch: export LD_LIBRARY_PATH=\"${NCCL_HOME}/lib:${NCCL_HOME}/lib64:${MAGMA_HOME}/lib:${CUSPARSELT_HOME}/lib:${CUDNN_HOME}/lib:${CUDA_MATH_LIBS_HOME}/lib64:${NVIDIA_PROFILER_LDPATHS}:${CUDA_HOME}/lib64:${MPI_HOME}/lib:${GLIB_HOME}/lib:${GLIB_HOME}/lib64:\$\{LD_LIBRARY_PATH\}\"\n\n"

# Exit repo
popd || exit
