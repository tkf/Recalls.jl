using Aqua
using Recalls
using Test

@testset "Aqua" begin
    Aqua.test_all(Recalls)
end

@testset "recall" begin
    @recall 1 + 2
    @recall 3 + 4
    @test Recalls.recall() == 7
    @test Recalls.CALLS[end-1]() == 3
end

@testset "note" begin
    empty!(Recalls.NOTES)
    @note a = 1
    @note a = 2
    notes = Recalls.sortbytime!()
    @test [notes[1].a, notes[2].a] == [1, 2]
end
