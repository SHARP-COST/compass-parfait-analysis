#!/usr/bin/env bash
set -euo pipefail

mkdir -p data

# HEPData record (COMPASS resonance-model fit)
curl -sSL 'https://www.hepdata.net/download/table/ins1655631/Transition%20Amplitudes/json' \
  -o data/transition_amplitudes.json
curl -sSL 'https://www.hepdata.net/download/table/ins1655631/Decay%20Phase-Space%20Volume%20of%20Partial%20Waves/json' \
  -o data/decay_phase_space_volume.json
curl -sSL 'https://www.hepdata.net/record/resource/731180?view=true' \
  -o data/covariance_matrices.tar.gz

echo "Downloaded HEPData tables into ./data"
