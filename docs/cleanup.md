# Repository cleanup

The cleanup keeps one authoritative script per workflow stage. Superseded
scripts, duplicate MDPs, the unused older pipeline, obsolete topology copies,
duplicate inputs, and diagnostic test outputs were removed from the working
project. Supplied molecular parameters were not edited.

A complete pre-cleanup snapshot was saved alongside the project, outside the
GitHub source package:

`Free_energy_product_release_before_cleanup_20261118_122016.tar.gz`

User simulation results under `simulations/` were preserved. Only the explicitly
identified short tests created while developing this workflow and byte-identical
duplicate input files were removed there. Generated results remain Git-ignored.

## Script names

| Previous working script | Kept script |
|---|---|
| `scripts/preparation/preparation_updated.sh` | `scripts/01_prepare_system.sh` |
| `scripts/pull_ligand_updated.sh` | `scripts/02_pull_ligand.sh` |
| `scripts/get_distances_updated.sh` | `scripts/03_extract_frames.sh` |
| `scripts/analysis/umbrella_des_updated.sh` | `scripts/04_run_umbrella_windows.sh` |
| `scripts/analysis/umbrella_wham_updated.sh` | `scripts/05_analyze_pmf.sh` |

## Input and configuration organization

- `US_intial_coordinate/*.gro` → `inputs/coordinates/` (bytes unchanged).
- Its `index_file/` → `inputs/index/` (bytes unchanged).
- Supporting protein, CTAL and solvent PDBs → `inputs/reference/`.
- `CHL.pdb` removed: it was identical to `choline.pdb`, not a chalcone structure.
- Duplicate copies of `chaina.ndx` removed after comparison with the retained file.
- The duplicate `simulations/naringenin_chalcone_release/md_1.gro` was identical
  to the retained CHL/DES starting GRO and removed.
- Four corrected system topologies retained as `topol_<system>.top`.
- Preparation MDPs consolidated under `mdp/preparation/`.
- Moving-restraint MDPs consolidated under `mdp/pulling/`.
- Stationary-window MDPs consolidated under `mdp/umbrella/`.
- Unused older `protocols/`, including the 500 K NVT alternatives, removed.
- The earlier preflight report was superseded by `docs/validation.md`; the
  original report and its diagnostic logs remain in the backup snapshot.
- Site-specific absolute project paths replaced with repository-relative discovery.
- Each workflow script accepts a system and run name as its two arguments.

## Removed paths

These paths were included in the snapshot before removal:

- `scripts/preparation`
- `scripts/reaction_coordinate`
- `scripts/window_generation`
- `scripts/analysis`
- `scripts/test_2.sh`
- `scripts/test_3.sh`
- `scripts/get_distances.sh`
- `scripts/pull_ser136.sh`
- `scripts/umbrella_pipeline.sh`
- `scripts/pull_ligand_updated.sh`
- `scripts/get_distances_updated.sh`
- `scripts/run_umbrella_windows.sh`
- `mdp_files`
- `protocols`
- `US_intial_coordinate`
- `inputs/CHL.pdb`
- `inputs/choline.pdb`
- `inputs/chloride.pdb`
- `inputs/Ethylene_glycol.pdb`
- `inputs/TaCHS.pdb`
- `inputs/CTAL.pdb`
- `inputs/chaina.ndx`
- `topology/systems/topol_chl_chcl_eg_preparation.top`
- `topology/systems/topol_ctal_chcl_eg_preparation.top`
- `topology/systems/topol_chl_water_preparation.top`
- `topology/systems/topol_ctal_water_preparation.top`
- `topology/systems/chcl_eth_runIII`
- `simulations/naringenin_chalcone_release/md_1.gro`
- `simulations/chaina.ndx`
- `simulations/chl_chcl_eg/preparation_smoke_20261118_110705`
- `simulations/chl_chcl_eg/preparation_smoke_20261118_110732`
- `simulations/ctal_water/preparation_check_20261118_110745`
- `simulations/chl_water/preparation_check_20261118_110745`
- `simulations/ctal_chcl_eg/preparation_check_20261118_110745`
- `simulations/chl_chcl_eg/preparation/full_sequence_test_20261118_111349`
- `analysis/preflight_2026-11-18`
- `docs/umbrella_setup_review_2026-11-18.md`
