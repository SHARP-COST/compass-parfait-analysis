using Test
using CompassParfait

@testset "CompassParfait core" begin
    cfg = CompassParfait.load_config("nonexistent.toml")
    @test haskey(cfg, "note")

    data = CompassParfait.load_data(cfg)
    fit = CompassParfait.fit_model(data, cfg)
    @test fit["fit_status"] == "ok"

    tmp = mktempdir()
    CompassParfait.save_outputs(fit, tmp)
    @test isfile(joinpath(tmp, "fit-summary.txt"))
end

@testset "Dashboard loader" begin
    path = joinpath(@__DIR__, "..", "data", "transition_amplitudes.json")
    if isfile(path)
        ds = CompassParfait.load_transition_dataset(path)
        @test length(ds.m3pi) > 0
        @test length(ds.tbins) > 0
        @test length(ds.waves) > 0
    else
        @test_broken false
    end
end
