# Workflow validation

## Status

The organized workflow was checked with **GROMACS 2022.1**, Bash, and CPU-only
short executions on 2026-11-18. This document records software/input checks.
No converged CTAL or naringenin-chalcone production PMF is provided.

## Checks performed after reorganization

| Check | Result |
|---|---|
| Bash syntax for the five numbered scripts | Passed |
| Execution from a different checkout location | Passed |
| System atom count and topology atom-name order | Matched for all four systems |
| Main index bounds and selected ligand/Thr135 groups | Checked for all four systems |
| Minimization/NVT/NPT/MD/pulling/window-equilibration/window-production preprocessing | 28 of 28 passed: seven stages for each of four systems |
| Short preparation run | Minimization, NVT, NPT and MD executed in a temporary relocated checkout |
| Short pulling and final-structure extraction | Executed in that checkout |
| GRO-frame extraction and coordinate table | Executed; frame count and full-system atom count checked |
| Stationary-window execution | Executed with shortened budgets; earlier two-window tests checked separate seeds and constant centers |
| WHAM after relocation | Executed using explicitly synthetic force data and matching test TPRs |
| Input data checksums | 12 of 12 passed |

Preprocessing was run without `-maxwarn` overrides. The relocation checks used
new system-topology paths and the supplied force field. The short dynamics tests
used at most 100 minimization steps and 10 integration steps per dynamics stage,
with one thread-MPI rank and two OpenMP threads on CPU. Simulation-length
changes were made only in temporary test copies; the distributed scientific
budgets remain 1 ns NVT, 2 ns NPT, 100 ns preparation MD, 2 ns pulling, 100 ps
window equilibration, and 10 ns window production.

The test checkout used the original input data. Its simulation outputs and the
synthetic WHAM outputs are not included as research results. The pre-cleanup
snapshot records the previous development tree. GitHub Actions checks shell
syntax and the input checksums; it does not install GROMACS or run MD.

## What passing tests establish

- Renamed scripts can find their configurations and input files after relocation.
- System topology includes resolve, including the supplied force-field files.
- The simulation stages can produce files required by the next stage.
- Fixed window centers and matched production TPR/force lists can be generated.
- The WHAM software path produces the intended analysis files.

## Scientific assessment still required

Short tests do not establish stable long trajectories, minimization convergence,
sufficient equilibration, representative solvent sampling, or an accurate PMF.
Before using the workflow for a result, assess:

1. The exact protein and solvent parameter provenance; the directory label and
   force-field header differ as documented in `input_provenance.md`.
2. The inherited position-restraint policy and its differences between CHL and CTAL.
3. Comparable reaction coordinates/pathways across systems; current DES and water
   coordinates have different dimensions.
4. A real bulk-solvent endpoint, absence of periodic-image interactions, and
   acceptable enzyme deformation along the pulling path.
5. Window coverage, overlap, autocorrelation, time-block convergence and
   reproducibility in independent repeats.
6. Geometric/restraint corrections required for the intended thermodynamic
   comparison. The WHAM outputs are raw coordinate PMFs, not automatically
   standard binding free energies or dissociation rates.
