#!/bin/bash
#SBATCH -J profiling-cpu
#SBATCH -o %x.o%j
#SBATCH --account flowmas
# #SBATCH --account hackathon
# #SBATCH --reservation hackathon
#SBATCH --time=00:10:00
#SBATCH --nodes=8

set -e
cmd() {
  echo "+ $@"
  eval "$@"
}

NTASKS_PER_NODE=4
RANKS=$(( ${NTASKS_PER_NODE}*${SLURM_JOB_NUM_NODES} ))

cmd "export EXAWIND_MANAGER=${HOME}/exawind/exawind-manager"
cmd "source ${EXAWIND_MANAGER}/start.sh && spack-start"
cmd "spack env activate -d ${EXAWIND_MANAGER}/environments/amr-wind-of-gcc"
cmd "spack load amr-wind"
cmd "export MPICH_OFI_SKIP_NIC_SYMMETRY_TEST=1"
cmd "which amr_wind"
cmd "srun -N ${SLURM_JOB_NUM_NODES} -n ${RANKS} --ntasks-per-node=${NTASKS_PER_NODE} amr_wind demo_case.inp amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 time.max_step=40005 > out-cpu-${SLURM_JOB_ID}.log"
