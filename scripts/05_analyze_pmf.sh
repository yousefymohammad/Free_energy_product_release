#!/bin/bash

# Analyze completed umbrella windows with WHAM.
set -e

# Optional arguments: system and run; otherwise use these defaults.
SYSTEM="${1:-chl_chcl_eg}"
run="${2:-RunI}"
ANALYSIS="wham_01"  # Change this for another analysis without overwriting results.
BEGIN=1000           # ps: initially discard the first 1 ns of production.
END=10000           # ps: end of the 10 ns production runs.

project="$(cd "$(dirname "$0")/.." && pwd)"
frames="$project/simulations/$SYSTEM/pulling/$run/frames/frames.dat"
job="$project/simulations/$SYSTEM/umbrella/$run"
output="$project/analysis/$SYSTEM/$run/$ANALYSIS"

if [[ ! -s "$frames" ]]; then
    echo "Missing window table: $frames" >&2
    exit 1
fi

# Require every expected window before analyzing the collection.
for i in $(awk '{print $1}' "$frames")
do
    if [[ ! -f "$job/window_$i/md.tpr" || ! -f "$job/window_$i/md.gro" || ! -s "$job/window_$i/md_pullf.xvg" ]]; then
        echo "Missing production output for window $i: $job/window_$i" >&2
        exit 1
    fi
done

mkdir -p "$project/analysis/$SYSTEM/$run"
mkdir "$output"
cd "$output"

# Rebuild paired lists in the same order; no old entries are reused.
for i in $(awk '{print $1}' "$frames")
do
    echo "$job/window_$i/md.tpr" >> tpr_files.dat
    echo "$job/window_$i/md_pullf.xvg" >> pullf_files.dat
done

# PMF in kcal/mol, with autocorrelation weighting and 100 bootstrap samples.
gmx wham -it tpr_files.dat -if pullf_files.dat \
    -temp 300.15 -b "$BEGIN" -e "$END" -unit kCal \
    -o pmf.xvg -hist histograms.xvg \
    -ac -oiact autocorrelation_times.xvg \
    -nBootstrap 100 -bs-method traj -bs-seed 12345 \
    -bsres bootstrap_errors.xvg -bsprof bootstrap_profiles.xvg

echo "Analysis saved in: $output"
echo "Inspect histogram overlap and compare different time ranges before interpreting the PMF."
