#!/bin/bash

NCU_RANK="0"
PROF_NAME="amr-wind-ncu-profile"
if [[ ${SLURM_PROCID} == "${NCU_RANK}" ]]; then
    echo "NCU profiling on rank ${SLURM_PROCID}"
    # ncu --import-source true --set full -f -o pele-ncu-profile --kernel-name launch_global --launch-skip 164796 --launch-count 1 "$@"
    # ncu --import-source true --set full -f -o myprofilename --kernel-id ::regex:".*RHS*":1 "$@"
    # ncu --import-source true --set full -f -o myprofilename --kernel-name regex:".*RHS" "$@"
    # ncu --import-source true --set full -f -o myprofilename --kernel-name regex:".*RHS" "$@"
    ncu --import-source true --set full -f -o "${PROF_NAME}" --nvtx --nvtx-include "Pele::ReactorCvode::cF_RHS()/" "$@"
else
    "$@"
fi
