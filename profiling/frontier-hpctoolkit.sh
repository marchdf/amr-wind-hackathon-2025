#!/bin/bash
#SBATCH -J profiling
#SBATCH -o %x.o%j
#SBATCH -A CFD162
#SBATCH -t 0:15:00
#SBATCH -N 32
#SBATCH -S 0
#SBATCH -q debug

set -e
cmd() {
  echo "+ $@"
  eval "$@"
}

cmd "module load ums ums023 hpctoolkit/2024.01.1-gpu-mpi"
cmd "export MPICH_GPU_SUPPORT_ENABLED=1"
cmd "export EXAWIND_MANAGER=${HOME}/exawind/exawind-manager"
cmd "source ${EXAWIND_MANAGER}/start.sh && spack-start"
cmd "spack env activate -d ${EXAWIND_MANAGER}/environments/amr-wind-of"
cmd "spack load amr-wind+netcdf+rocm build_type=RelWithDebInfo"
cmd "which amr_wind"
PROFNAME="profiling"
cmd "rm -rf ${PROFNAME}"
cmd "rm -rf ${PROFNAME}_db"
cmd "spack build-env 'amr-wind+netcdf+rocm build_type=RelWithDebInfo' srun -N32 -n256 --gpus-per-node=8 --gpu-bind=closest hpcrun -o ${PROFNAME} -f 0.2 -t -e CPUTIME -e gpu=amd amr_wind demo_case.inp amrex.abort_on_out_of_gpu_memory=1 amrex.the_arena_is_managed=0 amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 amrex.use_gpu_aware_mpi=1 time.max_step=40040 > out.log"
cmd "spack build-env 'amr-wind+netcdf+rocm build_type=RelWithDebInfo' hpcstruct ${PROFNAME}"
cmd "spack build-env 'amr-wind+netcdf+rocm build_type=RelWithDebInfo' hpcprof -o ${PROFNAME}_db ${PROFNAME}"
