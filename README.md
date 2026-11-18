# Calculating the free energy profile for the release of the desired and byproduct

## Scientific background

Natural deep eutectic solvents (NADES) belong to a wider family of deep eutectic
solvents (DES) whose composition can be tailored for biocatalysis. Their
components and water content can alter enzyme hydration, hydrogen-bond networks,
active-site organization, and conformational flexibility. Changes in solvent
viscosity and substrate/product solvation can also affect access to the enzyme
and transport away from it. These effects depend on the enzyme and formulation;
a solvent that stabilizes a protein does not necessarily increase its catalytic
activity. Experimental and simulation studies illustrate the importance of
[solvent composition](https://doi.org/10.1039/D1GC04059F),
[hydration](https://doi.org/10.1039/D1CP03282H), and
[component ratio](https://doi.org/10.1016/j.molliq.2022.120180).

This project examines the solvent-dependent behavior of chalcone synthase
(TaCHS). The implemented eutectic formulation is **hydrated choline chloride /
ethylene glycol (ChCl:EG, 1:2)**, compared with water.

## Research question

**Does product promoscuity arise primarily during the chemical
cyclization step, or can differences in product retention and release from the
active site also contribute? second what would be the influence of solvent on the product release**

We use umbrella sampling to investigate the free-energy profiles for releasing
**p-coumaroyltriacetic acid lactone (CTAL)** and **naringenin chalcone (NC)** from
the TaCHS active site toward bulk solvent. Naringenin chalcone is the desired product which will be converted to the naringenin, CTAL is the byproduct. 

The working hypothesis is that solvent-dependent interactions with the enzyme
and solvent may stabilize the bound products differently and alter their release
profiles. The simulations estimate a potential of mean force (PMF) along a chosen
release coordinate. A release PMF therefore addresses the release contribution to the
question; identifying the controlling chemical step requires complementary
reactive calculations or experimental kinetic evidence.

## Systems and release coordinates

`chl` is the historical file identifier for **naringenin chalcone**, not choline.
`CHO` denotes solvent choline in the topology.

| System argument | Product | Solvent | Atoms | Current pulling coordinate |
|---|---|---|---:|---|
| `chl_chcl_eg` | Naringenin chalcone | Hydrated ChCl:EG | 115,206 | Full 3D COM distance |
| `ctal_chcl_eg` | CTAL | Hydrated ChCl:EG | 115,206 | Full 3D COM distance |
| `chl_water` | Naringenin chalcone | Water | 72,174 | Absolute X component of COM separation |
| `ctal_water` | CTAL | Water | 69,174 | Absolute Z component of COM separation |

The pulled product is the second ligand in the dimer (atom IDs 12163–12194).
The reference group is **Thr135 of chain B**, atom IDs 8199–8212. 
The DES index calls the second ligand `chlb` for both products; in the CTAL/DES
structure these atoms are CTAL despite the historical group name.

**Coordinate definitions are inherited from the supplied setup.** The extraction
script matches those dimensions. Before interpreting differences between systems,
choose comparable release pathways and coordinate conventions. A projected
laboratory-axis coordinate and a full 3D distance have different physical
meanings; protein rotation and lateral ligand motion require particular care
for the projected coordinates. No orientation restraint is added by these
scripts.

## Repository contents

```text
scripts/
  01_prepare_system.sh       Energy minimization, NVT, NPT, production MD
  02_pull_ligand.sh          Moving harmonic restraint and final structure
  03_extract_frames.sh       GRO frames and their measured coordinates
  04_run_umbrella_windows.sh Independent window equilibration and production
  05_analyze_pmf.sh          WHAM, histograms and uncertainty estimates
inputs/
  coordinates/              Four complete, solvated starting GRO files
  index/                    Pulling and analysis index groups
  reference/                Original protein, CTAL and solvent component PDBs
  checksums.sha256           Integrity checks for the supplied input data
mdp/
  preparation/              Minimization, NVT, NPT and production settings
  pulling/                  One moving-restraint MDP per system
  umbrella/                 Equilibration and production templates per system
topology/
  amber14sb_parmbsc1.ff/     Supplied Amber-family force-field files
  molecules/                Protein, ligand and solvent ITPs and restraints
  systems/                  One complete system topology per system
docs/
  input_provenance.md        Composition, parameter sources and input roles
  validation.md              Tests performed and their limits
  cleanup.md                 Script renaming and cleanup record
```

`simulations/` and `analysis/` are created locally. They are excluded from Git,
as are trajectories, checkpoints, run-input binaries and log files. Original
simulation results already present on the local machine are retained locally.

## Requirements

- Linux with Bash, `awk`, `sed`, and standard shell utilities.
- **GROMACS 2022.1**, the version used for the recorded tests, available as `gmx`.
  Validate compatibility before using another version.
- Sufficient disk space and compute time. An NVIDIA GPU with a compatible
  GROMACS/CUDA installation is useful for MD; WHAM uses the CPU.
- A viewer such as PyMOL or VMD for inspecting the release trajectory.

No Python package is required to run the five workflow scripts.

Check the installation and input files from the repository root:

```bash
gmx --version
sha256sum -c inputs/checksums.sha256
```

The scripts locate the repository relative to their own location, so the project
can be cloned into another directory. Each script accepts the same two arguments:
**system** and **run name**. Defaults are `chl_chcl_eg` and `RunI`.
Use a fresh run name for a new calculation. Existing run directories are protected
against reuse; automatic checkpoint restart is not implemented.

The MD scripts retain the original cluster's `#$` scheduler comments. These are
ignored by `bash`. Before using `qsub`, adapt the queue, GPU allocation and host
constraint to your cluster. Submit each stage only after its prerequisites have
finished; submitting all scripts at once does not create job dependencies.

## Step-by-step workflow

### 1. Prepare the system

```bash
bash scripts/01_prepare_system.sh chl_chcl_eg RunI
```

This starts from `inputs/coordinates/md_chl_chcl_eg.gro`, using the matching
system topology, and runs:

| Stage | Settings |
|---|---|
| Energy minimization | Steepest descent; up to 50,000 steps; target maximum force 1,000 kJ mol⁻¹ nm⁻¹ |
| NVT | 1 ns at 300.15 K; position restraints enabled |
| NPT | 2 ns at 300.15 K and 1 bar; C-rescale barostat; position restraints enabled |
| Production MD | 100 ns at 300.15 K and 1 bar; Parrinello–Rahman barostat; no `POSRES` define |

The supplied GRO files are previously simulated, solvated configurations.
This script performs a fresh minimization/equilibration sequence from those
coordinates; it does not reconstruct the systems from the reference PDBs.
It generates velocities in the first NVT stage, then passes checkpoints forward.

Inspect convergence of minimization, temperature, pressure, density and protein
stability before proceeding. The restraint definitions are molecule-specific;
see [input provenance](docs/input_provenance.md) for their scope.

Main outputs:

```text
simulations/chl_chcl_eg/preparation/RunI/
  em.gro
  nvt.gro  nvt.cpt
  npt.gro  npt.cpt
  md.gro   md.cpt   md.xtc   md.log
```

### 2. Pull the ligand toward solvent

```bash
bash scripts/02_pull_ligand.sh chl_chcl_eg RunI
```

The script reads the completed preparation's `md.gro` and `md.cpt`. It applies a
moving harmonic restraint with force constant **1,000 kJ mol⁻¹ nm⁻²** and rate
**0.001 nm ps⁻¹** for **2 ns**. The reference coordinate increases by **2 nm**
relative to its starting value. Edit the corresponding file in `mdp/pulling/`
when choosing another rate, endpoint or coordinate.

Outputs are in `simulations/chl_chcl_eg/pulling/RunI/`:

- `pull.tpr`, `pull.xtc`, `pull.gro`: pulling run inputs, trajectory and final state.
- `pullx.xvg`, `pullf.xvg`: pulling coordinate and force.
- `pull_centered.xtc`: centered trajectory with whole molecules.
- `pulled_final.gro`: structure extracted at 2,000 ps for inspection.

Inspect the path for steric collisions, deformation, periodic-image contacts,
and remaining enzyme–product contacts. **A 2 nm increase does not establish that
the product is in bulk solvent.** Confirm a solvent-exposed region with no
significant protein interaction, and extend or redesign the path if needed.
Changing the pulling duration also requires changing the `-dump 2000` extraction
time in this script.

### 3. Extract candidate umbrella structures

```bash
bash scripts/03_extract_frames.sh chl_chcl_eg RunI
```

`FRAME_INTERVAL=10` saves one complete-system GRO every **10 ps**. Change this
setting inside the script to control extraction density. A 2 ns trajectory
normally gives about **201 structures** at this interval, including the first
frame. Full-system GRO files are large; the DES extraction can occupy roughly
1.6 GB.

Outputs in `simulations/chl_chcl_eg/pulling/RunI/frames/`:

| File | Contents |
|---|---|
| `frame0.gro`, `frame1.gro`, … | Protein, both ligands, solvent and ions |
| `frames.dat` | Frame number, time in ps, measured coordinate in nm |
| `summary_distances.dat` | Frame number and coordinate in nm |
| `distance_components.xvg` | COM separation components used for the table |

**Extraction time intervals are not uniform distance intervals.** These are
candidate windows. Inspect their measured coordinates and select sufficient
coverage with overlap between neighbors. The next script uses every row in
`frames.dat`; to use a subset, back up that table and keep only the selected
rows. Keep each frame number matched to its `frame<number>.gro`. Preserve the
same table through production and analysis.

The force-bearing coordinate is measured using the same dimensions as the
pulling MDP: the full 3D norm for DES and absolute X/Z components for the water
systems. If the MDP dimensions change, update the extraction calculation too.

### 4. Simulate the umbrella windows

```bash
bash scripts/04_run_umbrella_windows.sh chl_chcl_eg RunI
```

For every selected row in `frames.dat`, the script creates a separate directory:

```text
simulations/chl_chcl_eg/umbrella/RunI/window_<frame-number>/
```

Each window starts from its own extracted structure, receives a different
velocity seed (`SEED_BASE + frame number`), undergoes **100 ps NPT equilibration**,
and then **10 ns production MD**. The loops run windows sequentially. Choose a
different `SEED_BASE` when planning independent repeat runs.

The restraint is stationary (`pull-coord1-rate=0`). Both stages use
`pull-coord1-start=no` and the same explicit `pull-coord1-init`, taken from the
window table. Production continues that window's NPT checkpoint. Each directory
contains `npt.gro`, `npt.cpt`, `md.tpr`, `md.gro`, `md_pullx.xvg` and
`md_pullf.xvg`, together with the other normal GROMACS outputs and local MDPs.

The planned durations are initial sampling budgets, not convergence criteria.
With 201 windows, production alone totals **2.01 microseconds per system**.
Inspect the window count before launching. Separate velocity seeds do not
eliminate correlations inherited from the same pulling path.

After all windows succeed, the script automatically calls step 5. Matching TPR
and force lists are also saved at the umbrella run root for reference.

### 5. Analyze the PMF with WHAM

For a separate analysis of completed windows:

```bash
bash scripts/05_analyze_pmf.sh chl_chcl_eg RunI
```

This is already called by step 4. Before rerunning it, change `ANALYSIS` inside
the script from `wham_01` to a new name, such as `wham_02`, to preserve earlier
results. Adjust `BEGIN` and `END` for the time interval being assessed.

The initial settings use **1,000–10,000 ps** of each production run, temperature
**300.15 K**, autocorrelation weighting and **100 trajectory-bootstrap samples**.
Excluding the first 1 ns is an initial choice that must be checked against
window equilibration. Only production force files enter WHAM. The script
requires each expected window's production files and rebuilds fresh paired lists.

Outputs in `analysis/chl_chcl_eg/RunI/wham_01/`:

| Output | Meaning |
|---|---|
| `pmf.xvg` | PMF in kcal mol⁻¹ versus coordinate in nm |
| `histograms.xvg` | Coordinate histograms for assessing window overlap |
| `autocorrelation_times.xvg` | Estimated integrated autocorrelation times |
| `bootstrap_errors.xvg` | Bootstrap mean profile and estimated standard deviation |
| `bootstrap_profiles.xvg` | Individual bootstrap profiles |
| `tpr_files.dat`, `pullf_files.dat` | Exact, matched analysis inputs |

WHAM is described by [Hub et al. (2010)](https://doi.org/10.1021/ct100494z).
Follow the [GROMACS WHAM guidance](https://manual.gromacs.org/documentation/2022/onlinehelp/gmx-wham.html)
when assessing overlap, autocorrelation estimates and bootstrap uncertainty.

## Validation and reproducibility

The workflow has passed GROMACS preprocessing checks and short CPU tests covering
preparation, pulling, extraction and two umbrella windows. The WHAM software
path was tested with explicitly synthetic force data. These tests establish
execution and file consistency; **no converged production PMF is supplied**.
See [validation details](docs/validation.md).

Retain the input structures, force-field files, effective MDPs, TPRs, seeds,
window table, GROMACS version and analysis time intervals for every reported
calculation. Run directories are ignored by Git; archive research results in an
appropriate data repository and link the dataset when available.

## GitHub use and licensing

This directory contains the source scripts, configuration files and initial data.
Generated `simulations/` and `analysis/` outputs are intentionally excluded by
`.gitignore`. Review the files before committing:

```bash
git init
git add README.md LICENSE LICENSE_SCOPE.md .gitignore .gitattributes .github scripts mdp inputs topology docs
git status --short
```

The original workflow code, configuration and documentation are licensed under
the [MIT License](LICENSE). Supplied structures and third-party force-field
material retain their own terms; see [license scope](LICENSE_SCOPE.md) and
[third-party provenance](docs/input_provenance.md).

## References

- Bittner et al. (2022). DES components, enzyme activity and solvation.
  [DOI: 10.1039/D1GC04059F](https://doi.org/10.1039/D1GC04059F).
- Qiao, Shi and Shao (2021). Effects of hydration on lipase solvation and active-site structure.
  [DOI: 10.1039/D1CP03282H](https://doi.org/10.1039/D1CP03282H).
- Kovács et al. (2022). NADES composition and enzyme stability.
  [DOI: 10.1016/j.molliq.2022.120180](https://doi.org/10.1016/j.molliq.2022.120180).
- Experimental identification of CHS/STS residues affecting cyclization and CTAL formation.
  [Article](https://pmc.ncbi.nlm.nih.gov/articles/PMC1221246/).
- Hub, de Groot and van der Spoel (2010). WHAM with error and autocorrelation estimates.
  [DOI: 10.1021/ct100494z](https://doi.org/10.1021/ct100494z).
