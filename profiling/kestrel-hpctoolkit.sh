#!/bin/bash
#SBATCH -J profiling
#SBATCH -o %x.o%j
#SBATCH --account=flowmas   # Required
#SBATCH --time=00:15:00
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=128
#SBATCH --gpus=32
#SBATCH --exclusive
#SBATCH --mem=0

set -e
cmd() {
  echo "+ $@"
  eval "$@"
}

NTASKS_PER_NODE=4
RANKS=$(( ${NTASKS_PER_NODE}*${SLURM_JOB_NUM_NODES} ))

# cmd "module load ums ums023 hpctoolkit/2024.01.1-gpu-mpi"
cmd "export MPICH_GPU_SUPPORT_ENABLED=1"
cmd "export EXAWIND_MANAGER=${HOME}/exawind/exawind-manager"
cmd "source ${EXAWIND_MANAGER}/start.sh && spack-start"
cmd "spack env activate -d ${EXAWIND_MANAGER}/environments/amr-wind-cuda"
cmd "spack load amr-wind+cuda build_type=Release"
cmd "export MPICH_OFI_SKIP_NIC_SYMMETRY_TEST=1"
cmd "export MPICH_GPU_SUPPORT_ENABLED=1"
cmd "which amr_wind"
PROFNAME="profiling"
cmd "spack build-env 'amr-wind+cuda build_type=Release' srun -N ${SLURM_JOB_NUM_NODES} -n ${RANKS} --ntasks-per-node=${NTASKS_PER_NODE} --gpus-per-node=4 --gpu-bind=closest amr_wind demo_case.inp amrex.abort_on_out_of_gpu_memory=1 amrex.the_arena_is_managed=0 amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 amrex.use_gpu_aware_mpi=1 time.max_step=40040 > out.log"
# cmd "spack build-env 'amr-wind+cuda build_type=RelWithDebInfo' srun -N ${SLURM_JOB_NUM_NODES} -n ${RANKS} --ntasks-per-node=${NTASKS_PER_NODE} --gpus-per-node=4 --gpu-bind=closest hpcrun -o ${PROFNAME} -f 0.2 -t -e CPUTIME -e gpu=amd amr_wind demo_case.inp amrex.abort_on_out_of_gpu_memory=1 amrex.the_arena_is_managed=0 amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 amrex.use_gpu_aware_mpi=1 time.max_step=40040 > out.log"
# cmd "spack build-env 'amr-wind+netcdf+cuda build_type=RelWithDebInfo' hpcstruct ${PROFNAME}"
# cmd "spack build-env 'amr-wind+netcdf+cuda build_type=RelWithDebInfo' hpcprof -o ${PROFNAME}_db ${PROFNAME}"
