#!/bin/bash

#$ -cwd
#$ -N chl
#$ -q GPU
#$ -l slotsGPU_0=1
#$ -l slotsGPU_1=0
#$ -l memGPU=10
#$ -pe parallelGPU 1

set -e

# Choose: chl_chcl_eg, ctal_chcl_eg, chl_water, or ctal_water.
SYSTEM="${1:-chl_chcl_eg}"
RUN="${2:-RunI}"  # Change this name for another run.

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
COORDINATES="$PROJECT/inputs/coordinates/md_${SYSTEM}.gro"
TOPOLOGY="$PROJECT/topology/systems/topol_${SYSTEM}.top"
MDP="$PROJECT/mdp/preparation"
OUTPUT="$PROJECT/simulations/$SYSTEM/preparation/$RUN"

# Stop if this run directory already exists, preserving previous results.
mkdir -p "$PROJECT/simulations/$SYSTEM/preparation"
mkdir "$OUTPUT"
cd "$OUTPUT"

# 1. Energy minimization.
gmx grompp -f "$MDP/minimize.mdp" -c "$COORDINATES" -p "$TOPOLOGY" -o em.tpr
gmx mdrun -deffnm em -v

# 2. NVT: equilibrate temperature at 300.15 K with position restraints.
gmx grompp -f "$MDP/nvt.mdp" -c em.gro -r em.gro -p "$TOPOLOGY" -o nvt.tpr
gmx mdrun -deffnm nvt -v

# 3. NPT: equilibrate pressure, continuing from NVT.
gmx grompp -f "$MDP/npt.mdp" -c nvt.gro -t nvt.cpt -r em.gro -p "$TOPOLOGY" -o npt.tpr
gmx mdrun -deffnm npt -v

# 4. Production MD: continue from NPT without position restraints (100 ns).
gmx grompp -f "$MDP/production.mdp" -c npt.gro -t npt.cpt -p "$TOPOLOGY" -o md.tpr
gmx mdrun -deffnm md -v
