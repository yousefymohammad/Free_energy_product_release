#!/bin/bash

set -e

# Match the system and run used in 02_pull_ligand.sh.
SYSTEM="${1:-chl_chcl_eg}"
RUN="${2:-RunI}"
FRAME_INTERVAL=10  # Save one GRO every 10 ps; decrease for more structures.

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
PULL="$PROJECT/simulations/$SYSTEM/pulling/$RUN"
OUTPUT="$PULL/frames"
LIGAND="chlb"

# Match the index and distance dimensions in mdp/pulling/.
case "$SYSTEM" in
    chl_chcl_eg|ctal_chcl_eg)
        INDEX="$PROJECT/inputs/index/chaina.ndx"
        COLUMN=0  # Full 3D distance.
        ;;
    chl_water)
        INDEX="$PROJECT/inputs/index/chl_water.ndx"
        COLUMN=2  # Absolute X distance.
        ;;
    ctal_water)
        INDEX="$PROJECT/inputs/index/ctal_water.ndx"
        LIGAND="ctal_b"
        COLUMN=4  # Absolute Z distance.
        ;;
    *) echo "Unknown system: $SYSTEM" >&2; exit 1 ;;
esac

if [[ ! -f "$PULL/pull.tpr" || ! -f "$PULL/pull_centered.xtc" ]]; then
    echo "Run the pulling script first: $PULL" >&2
    exit 1
fi

# Stop if this directory exists, keeping previous extracted structures.
mkdir "$OUTPUT"
cd "$OUTPUT"

# Keep the complete system, including solvent, for each saved frame.
printf 'System\n' | gmx trjconv -s "$PULL/pull.tpr" \
    -f "$PULL/pull_centered.xtc" -n "$INDEX" \
    -o frame.gro -sep -dt "$FRAME_INTERVAL"

# Measure distances at exactly the same trajectory times.
gmx distance -s "$PULL/pull.tpr" -f "$PULL/pull_centered.xtc" \
    -n "$INDEX" -dt "$FRAME_INTERVAL" \
    -select "com of group \"$LIGAND\" plus com of group \"thr135_b\"" \
    -oxyz distance_components.xvg

# frames.dat columns: frame number, time (ps), pulling coordinate (nm).
awk -v column="$COLUMN" '
    /^[@#]/ { next }
    NF >= 4 {
        if (column == 0)
            distance = sqrt($2*$2 + $3*$3 + $4*$4)
        else
            distance = sqrt($column*$column)
        printf "%d %.8f %.8f\n", frame++, $1, distance
    }
' distance_components.xvg > frames.dat

# Two-column version for selecting umbrella windows: frame number, distance.
awk '{print $1, $3}' frames.dat > summary_distances.dat

echo "GRO files and distance tables saved in: $OUTPUT"
