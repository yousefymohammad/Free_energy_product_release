#!/bin/bash

#$ -cwd
#$ -N CTAL_UM_water
#$ -q GPU
#$ -l slotsGPU_1=1
#$ -l slotsGPU_0=0
#$ -l memGPU=16
#$ -pe parallelGPU 1

set -e

# Choose: chl_chcl_eg, ctal_chcl_eg, chl_water, or ctal_water.
SYSTEM="${1:-chl_chcl_eg}"
RUN="${2:-RunI}"

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
START="$PROJECT/simulations/$SYSTEM/preparation/$RUN"
TOPOLOGY="$PROJECT/topology/systems/topol_${SYSTEM}.top"
MDP="$PROJECT/mdp/pulling/${SYSTEM}.mdp"
OUTPUT="$PROJECT/simulations/$SYSTEM/pulling/$RUN"

# Select the index file belonging to this system.
case "$SYSTEM" in
    chl_chcl_eg|ctal_chcl_eg) INDEX="$PROJECT/inputs/index/chaina.ndx" ;;
    chl_water) INDEX="$PROJECT/inputs/index/chl_water.ndx" ;;
    ctal_water) INDEX="$PROJECT/inputs/index/ctal_water.ndx" ;;
    *) echo "Unknown system: $SYSTEM" >&2; exit 1 ;;
esac

# Use completed preparation outputs
if [[ ! -f "$START/md.gro" || ! -f "$START/md.cpt" ]]; then
    echo "Complete the preparation run first: $START" >&2
    exit 1
fi

# Keep previous results: choose another RUN name if this folder exists.
mkdir -p "$PROJECT/simulations/$SYSTEM/pulling"
mkdir "$OUTPUT"
cd "$OUTPUT"

# Pull the ligand: increase the coordinate by 2 nm over 2 ns.
gmx grompp -f "$MDP" -c "$START/md.gro" -t "$START/md.cpt" \
    -p "$TOPOLOGY" -n "$INDEX" -o pull.tpr
gmx mdrun -deffnm pull -v -px pullx.xvg -pf pullf.xvg

# Center the protein and keep complete molecules for viewing/extraction.
printf 'Protein\nSystem\n' | gmx trjconv -s pull.tpr -f pull.xtc \
    -n "$INDEX" -o pull_centered.xtc -center -pbc mol -ur compact

# Save the final structure. Check its ligand position before choosing windows.
printf 'System\n' | gmx trjconv -s pull.tpr -f pull_centered.xtc \
    -n "$INDEX" -o pulled_final.gro -dump 2000
