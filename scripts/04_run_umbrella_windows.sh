#!/bin/bash

#$ -cwd
#$ -N CTAL_UM_water
#$ -q GPU
#$ -l slotsGPU_1=0
#$ -l slotsGPU_0=1
#$ -l memGPU=16
#$ -pe parallelGPU 1
#$ -l hostname=compchem18

# Run one NPT and MD simulation per row in frames.dat.
set -e

SYSTEM="${1:-chl_chcl_eg}"
run="${2:-RunI}"
SEED_BASE=100000  # Use another base for independent repeat runs.
project="$(cd "$(dirname "$0")/.." && pwd)"
frames="$project/simulations/$SYSTEM/pulling/$run/frames"
job="$project/simulations/$SYSTEM/umbrella/$run"
topology="$project/topology/systems/topol_${SYSTEM}.top"

case "$SYSTEM" in
    chl_chcl_eg|ctal_chcl_eg) index="$project/inputs/index/chaina.ndx" ;;
    chl_water) index="$project/inputs/index/chl_water.ndx" ;;
    ctal_water) index="$project/inputs/index/ctal_water.ndx" ;;
    *) echo "Unknown system: $SYSTEM" >&2; exit 1 ;;
esac

if [[ ! -s "$frames/frames.dat" ]]; then
    echo "Generate the pulling frames first: $frames/frames.dat" >&2
    exit 1
fi

# Stop if this run already exists, keeping its results.
mkdir -p "$project/simulations/$SYSTEM/umbrella"
mkdir "$job"
touch "$job/tpr-mdthr135_${run}.dat" "$job/pullf-mdthr135_${run}.dat"

# Use the generated frame numbers instead of the old hard-coded list.
for i in $(awk '{print $1}' "$frames/frames.dat")
do
    mkdir "$job/window_$i"
    cd "$job/window_$i"
    center=$(awk -v frame="$i" '$1 == frame {print $3}' "$frames/frames.dat")
    seed=$((SEED_BASE + i))

    # Same stationary center in NPT and MD; different velocities per window.
    sed -e "s/^pull-coord1-init *=.*/pull-coord1-init = $center/" \
        -e "s/^gen_seed *=.*/gen_seed = $seed/" \
        "$project/mdp/umbrella/${SYSTEM}_equilibration.mdp" > npt.mdp
    sed "s/^pull-coord1-init *=.*/pull-coord1-init = $center/" \
        "$project/mdp/umbrella/${SYSTEM}_production.mdp" > md.mdp

    # NPT equilibration for this frame (100 ps).
    gmx grompp -f npt.mdp -c "$frames/frame$i.gro" \
        -p "$topology" -n "$index" -o npt.tpr -po npt_processed.mdp
    gmx mdrun -deffnm npt -v

    # Production MD for this window (10 ns).
    gmx grompp -f md.mdp -c npt.gro -t npt.cpt \
        -p "$topology" -n "$index" -o md.tpr -po md_processed.mdp
    gmx mdrun -deffnm md -v -pf md_pullf.xvg -px md_pullx.xvg

    # Keep matching TPR and force lists for WHAM, as in your original script.
    echo "$job/window_$i/md.tpr" >> "$job/tpr-mdthr135_${run}.dat"
    echo "$job/window_$i/md_pullf.xvg" >> "$job/pullf-mdthr135_${run}.dat"
done

# Analyze all completed production windows with the same system and run.
bash "$project/scripts/05_analyze_pmf.sh" "$SYSTEM" "$run"
