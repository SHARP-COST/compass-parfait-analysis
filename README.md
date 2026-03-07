# COMPASS Parfait Analysis Site

Public-facing Quarto website and reproducible Pixi/Julia workflow for the SHARP-COST COMPASS Parfait Analysis presentation.

## What This Repository Does

This project explains and reproduces a two-dimensional partial-wave-analysis workflow in bins of:

- `m(3π)` (three-pion invariant mass),
- `t'` (reduced four-momentum transfer squared).

The core goal is educational and reproducible:

- explain how bins are defined and connected,
- show how model/data performance is evaluated within each bin,
- provide a runnable path (`pixi run ...`) for others to reproduce the workflow.

## Site Structure

- `index.qmd`: overview and scope
- `workflow.qmd`: reproducible execution path
- `data-layout.qmd`: binning by `m(3π)` and `t'`
- `model.qmd`: model entrypoint and API sketch
- `ci.qmd`: CI-based reproducibility
- `references.qmd`: source links and pending scientific references

## Physics/Data References

- COMPASS PWA context paper (2017): [INSPIRE 1391643](https://inspirehep.net/literature/1391643), [DOI 10.1103/PhysRevD.95.032004](https://doi.org/10.1103/PhysRevD.95.032004)
- COMPASS resonance-model-fit paper (2018): [INSPIRE 1655631](https://inspirehep.net/literature/1655631), [DOI 10.1103/PhysRevD.98.092003](https://doi.org/10.1103/PhysRevD.98.092003)
- HEPData record used in this workflow: [ins1655631](https://www.hepdata.net/record/ins1655631), [DOI 10.17182/hepdata.82958.v1](https://doi.org/10.17182/hepdata.82958.v1)
- Integrals source: GitHub data-hub repository (to be linked once finalized by the collaboration)

## Local Usage

```bash
pixi install
pixi run bootstrap
pixi run setup-julia
pixi run instantiate
pixi run fetch-data
pixi run run-model
pixi run render-site
```

Rendered site output: `docs/site/`

## CI

Workflow file: `.github/workflows/site.yml`

CI uses the same Pixi task interface used locally, restores cached HEPData files, and falls back to `pixi run fetch-data` when cache content is incomplete.

On pushes to `main`, CI deploys the rendered site to GitHub Pages.

## Publishing to SharP COST

Recommended repository name: `compass-parfait-analysis`.

1. Create or select the destination repository under the `SHARP-COST` organization.
2. Add remote:
   ```bash
   git remote add sharp-cost https://github.com/SHARP-COST/compass-parfait-analysis.git
   ```
3. Push:
   ```bash
   git push sharp-cost main
   ```
