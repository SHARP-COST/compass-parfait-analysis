module CompassParfait

using TOML
using JSON3

export load_config, load_data, fit_model, save_outputs
export TransitionDataset, UncertaintyDataset, load_transition_dataset, load_covariance_uncertainties, write_dashboard_artifacts

include("dashboard_data.jl")

function load_config(path::AbstractString)
    if isfile(path)
        return TOML.parsefile(path)
    end
    return Dict("note" => "default config placeholder")
end

function load_data(cfg)
    return Dict("data" => "placeholder", "cfg" => cfg)
end

function fit_model(data, cfg)
    return Dict("fit_status" => "ok", "data" => data, "cfg" => cfg)
end

function save_outputs(fit, outdir::AbstractString)
    mkpath(outdir)
    open(joinpath(outdir, "fit-summary.txt"), "w") do io
        write(io, "COMPASS Parfait fit placeholder\n")
        write(io, "status = $(fit["fit_status"])\n")
    end
    return nothing
end

end
