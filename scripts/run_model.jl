using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "CompassParfait.jl"))
using .CompassParfait

cfg = CompassParfait.load_config(joinpath(@__DIR__, "..", "config", "default.toml"))
data = CompassParfait.load_data(cfg)
fit = CompassParfait.fit_model(data, cfg)
CompassParfait.save_outputs(fit, joinpath(@__DIR__, "..", "artifacts"))

println("Model run complete. Outputs written to artifacts/")
