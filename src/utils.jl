
get_module_path() = dirname(dirname(pathof(@__MODULE__)))

function create_results_dir()
    return "./"
end

function cosmos_get_values(name_file::String) 
    output_file = open(name_file)
    dict_values = Dict{String}{Vector{Float64}}()
    while !eof(output_file)
        line = readline(output_file)
        splitted_line = split(line, ':')
        str_val = split(splitted_line[2], ' ')[1]
        if (length(splitted_line) > 1) && tryparse(Float64, str_val) !== nothing
            if !haskey(dict_values, splitted_line[1])
                dict_values[splitted_line[1]] = zeros(0)
            end
            push!(dict_values[splitted_line[1]], parse(Float64, str_val))
        end
    end
    close(output_file)
    return dict_values
end

load_model(name_model::String) = Base.MainInclude.include("$(get_module_path())/models/$(name_model).jl")
load_automaton(automaton::String) = Base.MainInclude.include("$(get_module_path())/automata/$(automaton).jl")
load_plots() = Base.MainInclude.include(get_module_path() * "/src/plots.jl")

newid() = Dates.format(Dates.now(), "YmHMs")

