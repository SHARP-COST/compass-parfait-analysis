#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
data_dir="${DATA_DIR:-${repo_root}/data}"

validate_json_table() {
  local path="$1"

  if [[ ! -s "${path}" ]]; then
    echo "Missing or empty HEPData JSON: ${path}" >&2
    return 1
  fi
  if [[ "$(head -c 1 "${path}")" != "{" ]]; then
    echo "Invalid HEPData JSON (expected an object): ${path}" >&2
    return 1
  fi
  if ! grep -q '"headers"' "${path}" || ! grep -q '"values"' "${path}"; then
    echo "Invalid HEPData JSON (missing headers or values): ${path}" >&2
    return 1
  fi
}

validate_data() {
  local directory="$1"

  validate_json_table "${directory}/transition_amplitudes.json"
  validate_json_table "${directory}/decay_phase_space_volume.json"

  local covariance="${directory}/covariance_matrices.tar.gz"
  if [[ ! -s "${covariance}" ]] || ! tar -tzf "${covariance}" >/dev/null; then
    echo "Invalid covariance archive: ${covariance}" >&2
    return 1
  fi
}

if [[ "${1:-}" == "--validate-only" ]]; then
  validate_data "${data_dir}"
  echo "Validated cached HEPData in ${data_dir}"
  exit 0
fi

mkdir -p "${data_dir}"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/compass-hepdata.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

download() {
  local url="$1"
  local output="$2"

  curl --fail --silent --show-error --location \
    --retry 4 --retry-all-errors --retry-delay 2 \
    --connect-timeout 20 --max-time 180 \
    "${url}" -o "${output}"
}

# HEPData record (COMPASS resonance-model fit)
download \
  'https://www.hepdata.net/download/table/ins1655631/Transition%20Amplitudes/json' \
  "${tmp_dir}/transition_amplitudes.json"
download \
  'https://www.hepdata.net/download/table/ins1655631/Decay%20Phase-Space%20Volume%20of%20Partial%20Waves/json' \
  "${tmp_dir}/decay_phase_space_volume.json"
download \
  'https://www.hepdata.net/record/resource/731180?view=true' \
  "${tmp_dir}/covariance_matrices.tar.gz"

validate_data "${tmp_dir}"

mv "${tmp_dir}/transition_amplitudes.json" "${data_dir}/transition_amplitudes.json"
mv "${tmp_dir}/decay_phase_space_volume.json" "${data_dir}/decay_phase_space_volume.json"
mv "${tmp_dir}/covariance_matrices.tar.gz" "${data_dir}/covariance_matrices.tar.gz"

echo "Downloaded and validated HEPData tables into ${data_dir}"
