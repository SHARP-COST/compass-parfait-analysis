struct TPrimeBin
    low::Float64
    high::Float64
end

struct TransitionDataset
    m3pi::Vector{Float64}
    tbins::Vector{TPrimeBin}
    waves::Vector{String}
    re::Array{Float64,3}  # (m, t, wave)
    im::Array{Float64,3}  # (m, t, wave)
end

struct UncertaintyDataset
    sigma_re::Array{Float64,3}   # (m, t, wave)
    sigma_im::Array{Float64,3}   # (m, t, wave)
    cov_re_im::Array{Float64,3}  # (m, t, wave)
end

function _parse_float(value)::Float64
    if value isa Number
        return Float64(value)
    end
    s = String(value)
    m = match(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", s)
    m === nothing && error("Could not parse float from '$s'")
    return parse(Float64, m.match)
end

function _parse_component_wave(header_name::AbstractString)
    m = match(r"^(RE|IM)\(AMP\(\$(.*)\$\)\)", header_name)
    m === nothing && return nothing
    component = m.captures[1]
    wave = strip(m.captures[2])
    return component, wave
end

function _parse_tprime_bins(qualifiers)
    lowers = get(qualifiers, "\$t'\$ bin lower limit", nothing)
    uppers = get(qualifiers, "\$t'\$ bin upper limit", nothing)
    (lowers === nothing || uppers === nothing) && error("Missing t' qualifiers in transition amplitude table")

    starts = Int[]
    bins = TPrimeBin[]
    for i in eachindex(lowers)
        low = _parse_float(lowers[i]["value"])
        high = _parse_float(uppers[i]["value"])
        push!(starts, Int(lowers[i]["group"]) + 1)  # convert 0-based to 1-based
        push!(bins, TPrimeBin(low, high))
    end
    return starts, bins
end

function load_transition_dataset(path::AbstractString)
    raw = JSON3.read(read(path, String))

    headers = raw["headers"]
    values = raw["values"]
    qualifiers = raw["qualifiers"]

    t_starts, tbins = _parse_tprime_bins(qualifiers)

    n_m = length(values)
    n_cols = length(headers) - 1  # exclude x-column

    col_tindex = fill(0, n_cols)
    col_wave = fill(0, n_cols)
    col_is_re = fill(false, n_cols)

    wave_to_index = Dict{String,Int}()
    waves = String[]

    # Map each y-column to (t' bin, wave, component)
    for col in 1:n_cols
        header_name = String(headers[col + 1]["name"])
        parsed = _parse_component_wave(header_name)
        parsed === nothing && error("Unsupported header format: $header_name")
        component, wave = parsed

        tidx = searchsortedlast(t_starts, col)
        (tidx < 1 || tidx > length(tbins)) && error("Could not map column $col to t' bin")

        widx = get!(wave_to_index, wave) do
            push!(waves, wave)
            length(waves)
        end

        col_tindex[col] = tidx
        col_wave[col] = widx
        col_is_re[col] = (component == "RE")
    end

    n_t = length(tbins)
    n_w = length(waves)

    re = fill(0.0, n_m, n_t, n_w)
    im = fill(0.0, n_m, n_t, n_w)
    m3pi = Vector{Float64}(undef, n_m)

    for (mi, row) in enumerate(values)
        m3pi[mi] = _parse_float(row["x"][1]["value"])

        for yentry in row["y"]
            col = Int(yentry["group"]) + 1
            val = _parse_float(yentry["value"])

            tidx = col_tindex[col]
            widx = col_wave[col]
            if col_is_re[col]
                re[mi, tidx, widx] = val
            else
                im[mi, tidx, widx] = val
            end
        end
    end

    return TransitionDataset(m3pi, tbins, waves, re, im)
end

function _parse_values_block(text::String)
    mvals = match(r"values:\n(.*?)\nindependent_variables:"s, text)
    mvals === nothing && error("Could not locate covariance values block")
    block = mvals.captures[1]
    vals = Float64[]
    for m in eachmatch(r"\{value:\s*([^}]+)\}", block)
        push!(vals, _parse_float(strip(m.captures[1])))
    end
    return vals
end

function _find_m_index(m3pi::Vector{Float64}, mval::Float64)
    idx = findfirst(x -> isapprox(x, mval; atol=5e-3), m3pi)
    idx === nothing && error("Could not map m(3pi)=$mval to dataset index")
    return idx
end

function _find_t_index(tbins::Vector{TPrimeBin}, low::Float64, high::Float64)
    idx = findfirst(tb -> isapprox(tb.low, low; atol=5e-4) && isapprox(tb.high, high; atol=5e-4), tbins)
    idx === nothing && error("Could not map t' bin [$low, $high] to dataset index")
    return idx
end

function load_covariance_uncertainties(ds::TransitionDataset, tarpath::AbstractString)
    n_m = length(ds.m3pi)
    n_t = length(ds.tbins)
    n_w = length(ds.waves)

    sigma_re = fill(0.0, n_m, n_t, n_w)
    sigma_im = fill(0.0, n_m, n_t, n_w)
    cov_re_im = fill(0.0, n_m, n_t, n_w)

    mktempdir() do tmp
        run(`tar -xzf $tarpath -C $tmp`)
        root = joinpath(tmp, "covariance_matrices")
        isdir(root) || error("Expected covariance_matrices directory in archive")
        files = filter(f -> occursin("covariance_matrix__m_", f) && endswith(f, ".yaml"), readdir(root; join=true))

        for path in files
            fname = basename(path)
            m = match(r"covariance_matrix__m_([0-9.]+)__t_([0-9.]+)_to_([0-9.]+)\.yaml$", fname)
            m === nothing && continue

            mval = parse(Float64, m.captures[1])
            tlow = parse(Float64, m.captures[2])
            thigh = parse(Float64, m.captures[3])

            mi = _find_m_index(ds.m3pi, mval)
            ti = _find_t_index(ds.tbins, tlow, thigh)

            text = read(path, String)
            vals = _parse_values_block(text)
            nvar = Int(round(sqrt(length(vals))))
            nvar * nvar == length(vals) || error("Covariance matrix is not square in $fname")

            # Variable order in HEPData covariance files is:
            # RE(w1), IM(w1), RE(w2), IM(w2), ... for the 14 selected waves.
            for wi in 1:n_w
                idx_re = 2 * wi - 1
                idx_im = 2 * wi
                idx_re > nvar && continue
                idx_im > nvar && continue

                var_re = vals[(idx_re - 1) * nvar + idx_re]
                var_im = vals[(idx_im - 1) * nvar + idx_im]
                cov_ri = vals[(idx_re - 1) * nvar + idx_im]

                sigma_re[mi, ti, wi] = sqrt(max(var_re, 0.0))
                sigma_im[mi, ti, wi] = sqrt(max(var_im, 0.0))
                cov_re_im[mi, ti, wi] = cov_ri
            end
        end
    end

    return UncertaintyDataset(sigma_re, sigma_im, cov_re_im)
end

function write_dashboard_artifacts(ds::TransitionDataset, outdir::AbstractString; unc::Union{Nothing,UncertaintyDataset}=nothing)
    mkpath(outdir)

    n_m = length(ds.m3pi)
    n_t = length(ds.tbins)
    n_w = length(ds.waves)

    manifest = Dict(
        "n_m" => n_m,
        "n_t" => n_t,
        "n_w" => n_w,
        "m3pi" => ds.m3pi,
        "tprime_bins" => [Dict("low" => tb.low, "high" => tb.high) for tb in ds.tbins],
        "waves" => ds.waves,
    )

    cells = Vector{Dict{String,Any}}()
    amplitudes = Vector{Dict{String,Any}}()

    for ti in 1:n_t
        for mi in 1:n_m
            total_intensity = 0.0
            dominant_w = 1
            dominant_intensity = -Inf

            for wi in 1:n_w
                re = ds.re[mi, ti, wi]
                im = ds.im[mi, ti, wi]
                intensity = re^2 + im^2
                phase = atan(im, re)
                sigma_re = unc === nothing ? 0.0 : unc.sigma_re[mi, ti, wi]
                sigma_im = unc === nothing ? 0.0 : unc.sigma_im[mi, ti, wi]
                cov_ri = unc === nothing ? 0.0 : unc.cov_re_im[mi, ti, wi]
                var_intensity = 4.0 * (re^2 * sigma_re^2 + im^2 * sigma_im^2 + 2.0 * re * im * cov_ri)
                sigma_intensity = sqrt(max(var_intensity, 0.0))

                total_intensity += intensity
                if intensity > dominant_intensity
                    dominant_intensity = intensity
                    dominant_w = wi
                end

                push!(amplitudes, Dict(
                    "m_index" => mi,
                    "m_center" => ds.m3pi[mi],
                    "t_index" => ti,
                    "t_low" => ds.tbins[ti].low,
                    "t_high" => ds.tbins[ti].high,
                    "wave_index" => wi,
                    "wave" => ds.waves[wi],
                    "re" => re,
                    "im" => im,
                    "sigma_re" => sigma_re,
                    "sigma_im" => sigma_im,
                    "cov_re_im" => cov_ri,
                    "intensity" => intensity,
                    "sigma_intensity" => sigma_intensity,
                    "phase" => phase,
                ))
            end

            push!(cells, Dict(
                "m_index" => mi,
                "m_center" => ds.m3pi[mi],
                "t_index" => ti,
                "t_low" => ds.tbins[ti].low,
                "t_high" => ds.tbins[ti].high,
                "total_intensity" => total_intensity,
                "dominant_wave" => ds.waves[dominant_w],
            ))
        end
    end

    open(joinpath(outdir, "manifest.json"), "w") do io
        JSON3.pretty(io, manifest)
    end
    open(joinpath(outdir, "cells.json"), "w") do io
        JSON3.pretty(io, cells)
    end
    open(joinpath(outdir, "amplitudes.json"), "w") do io
        JSON3.pretty(io, amplitudes)
    end

    return nothing
end
