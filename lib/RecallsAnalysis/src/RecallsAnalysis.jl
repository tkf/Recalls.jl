module RecallsAnalysis

using Recalls
using DataFrames

function note_dataframe(notes = Recalls.NOTES; sortby = :timestamp)
    df = DataFrame(Recalls.note_table(notes), copycols = false)
    if sortby !== nothing
        sort!(df, sortby)
    end
    return df
end

function variables_dataframe(variables)
    foldl(variables, init = DataFrame()) do df, row
        push!(df, row; cols = :union)
    end
end

function splat_variables(df = note_dataframe(); copycols = true, makeunique = true)
    return hcat(
        variables_dataframe(df.variables),
        select(df, Not(:variables), copycols = false),
        copycols = copycols,
        makeunique = makeunique,
    )
end

function note_dataframes_groupby_location(notes = Recalls.NOTES)
    dfs = DataFrame[]
    for gdf in groupby(note_dataframe(notes), :location)
        push!(dfs, splat_variables(gdf))
    end
    return dfs
end

end
