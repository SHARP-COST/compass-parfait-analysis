# Versioned HEPData inputs

These files are a versioned snapshot of the public HEPData record
[ins1655631](https://www.hepdata.net/record/ins1655631), used to make tests and
site builds reproducible when the upstream download service is unavailable.

- `transition_amplitudes.json`: Transition Amplitudes table
- `decay_phase_space_volume.json`: Decay Phase-Space Volume of Partial Waves table
- `covariance_matrices.tar.gz`: covariance-matrix resource for the transition amplitudes

Refresh all three files together with `pixi run fetch-data`. The fetcher downloads
to a temporary directory and validates the complete snapshot before replacing the
versioned files.
