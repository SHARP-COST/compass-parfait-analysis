module CompassParfait

using TOML

export load_config, load_data, fit_model, save_outputs

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
