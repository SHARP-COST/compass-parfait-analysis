# COMPASS Parfait Analysis Site

Public-facing Quarto website and reproducible Pixi/Julia workflow for the SharP COST COMPASS Parfait Analysis presentation.

## Site Structure

- `index.qmd`: overview and scope
- `workflow.qmd`: reproducible execution path
- `data-layout.qmd`: binning by `m(3π)` and `t'`
- `model.qmd`: model entrypoint and API sketch
- `ci.qmd`: CI-based reproducibility
- `references.qmd`: source links and pending scientific references

## Local Usage

```bash
pixi install
pixi run bootstrap
pixi run instantiate
pixi run run-model
pixi run render-site
```

Rendered site output: `docs/site/`

## CI

Workflow file: `.github/workflows/site.yml`

CI uses the same Pixi task interface used locally.

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
