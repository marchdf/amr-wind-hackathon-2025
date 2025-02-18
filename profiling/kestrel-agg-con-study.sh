#!/bin/bash
#SBATCH -J profiling-maxgridstudy
#SBATCH -o %x.o%j
#SBATCH --account hackathon
#SBATCH --reservation hackathon
#SBATCH --time=00:30:00
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=128
#SBATCH --gpus=32
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --exclude=x3103c0s37b0n0,x3104c0s25b0n0

set -e
cmd() {
  echo "+ $@"
  eval "$@"
}

NTASKS_PER_NODE=4
RANKS=$(( ${NTASKS_PER_NODE}*${SLURM_JOB_NUM_NODES} ))

cmd "export MPICH_GPU_SUPPORT_ENABLED=1"
cmd "export EXAWIND_MANAGER=${HOME}/exawind/exawind-manager"
cmd "source ${EXAWIND_MANAGER}/start.sh && spack-start"
cmd "spack env activate -d ${EXAWIND_MANAGER}/environments/amr-wind-cuda"
cmd "spack load amr-wind+cuda build_type=Release"
cmd "export MPICH_OFI_SKIP_NIC_SYMMETRY_TEST=1"
cmd "export MPICH_GPU_SUPPORT_ENABLED=1"
cmd "which amr_wind"

for agg_size in {16,32,64}; do
	for con_size in {16,32,64}; do
		cmd "srun -N ${SLURM_JOB_NUM_NODES} -n ${RANKS} --ntasks-per-node=${NTASKS_PER_NODE} --gpus-per-node=4 --gpu-bind=closest amr_wind demo_case.inp amrex.abort_on_out_of_gpu_memory=1 amrex.the_arena_is_managed=0 amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 amrex.use_gpu_aware_mpi=1 nodal_proj.agg_grid_size=${agg_size} nodal_proj.con_grid_size=${con_size} time.max_step=40005 > out-nodal-${agg_size}-${con_size}.log"
		cmd "sleep 1s"
		cmd "srun -N ${SLURM_JOB_NUM_NODES} -n ${RANKS} --ntasks-per-node=${NTASKS_PER_NODE} --gpus-per-node=4 --gpu-bind=closest amr_wind demo_case.inp amrex.abort_on_out_of_gpu_memory=1 amrex.the_arena_is_managed=0 amr.blocking_factor=16 amr.max_grid_size=128 amrex.use_profiler_syncs=0 amrex.async_out=0 amrex.use_gpu_aware_mpi=1 mac_proj.agg_grid_size=${agg_size} mac_proj.con_grid_size=${con_size} time.max_step=40005 > out-mac-${agg_size}-${con_size}.log"
		cmd "sleep 1s"
	done
done
