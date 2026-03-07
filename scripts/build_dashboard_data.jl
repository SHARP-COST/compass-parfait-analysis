using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CompassParfait

infile = joinpath(@__DIR__, "..", "data", "transition_amplitudes.json")
covfile = joinpath(@__DIR__, "..", "data", "covariance_matrices.tar.gz")
outdir = joinpath(@__DIR__, "..", "artifacts", "dashboard")

dataset = CompassParfait.load_transition_dataset(infile)
unc = isfile(covfile) ? CompassParfait.load_covariance_uncertainties(dataset, covfile) : nothing
CompassParfait.write_dashboard_artifacts(dataset, outdir; unc=unc)

println("Dashboard artifacts written to artifacts/dashboard")
