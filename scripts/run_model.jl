using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CompassParfait

cfg = CompassParfait.load_config(joinpath(@__DIR__, "..", "config", "default.toml"))
data = CompassParfait.load_data(cfg)
fit = CompassParfait.fit_model(data, cfg)
CompassParfait.save_outputs(fit, joinpath(@__DIR__, "..", "artifacts"))

println("Model run complete. Outputs written to artifacts/")
