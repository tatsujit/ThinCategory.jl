using DataStructures

struct ThinCategory
    objects::Vector{Symbol}
    relations::Dict{Symbol, Set{Symbol}}

    # Inner constructor to ensure valid relations
    function ThinCategory(objects::Vector{Symbol}, relations::Dict{Symbol, Set{Symbol}})
        # Verify all keys and values are valid objects
        for (k, v) in relations
            @assert k in objects "Invalid object in relations: $k"
            for obj in v
                @assert obj in objects "Invalid object in relations: $obj"
            end
        end
        new(objects, relations)
    end
end

# Helper function to compute transitive closure
function compute_closure(objects::Vector{Symbol}, immediate_relations::Vector{Pair{Symbol,Symbol}})
    # Initialize with reflexive relations
    relations = Dict(obj => Set{Symbol}([obj]) for obj in objects)

    # Add immediate relations
    for (source, target) in immediate_relations
        push!(relations[source], target)
    end

    # Compute transitive closure
    changed = true
    while changed
        changed = false
        for source in objects
            current = copy(relations[source])
            for mid in current
                for target in relations[mid]
                    if !in(target, current)
                        push!(relations[source], target)
                        changed = true
                    end
                end
            end
        end
    end

    relations
end

# Outer constructor using immediate relations
function ThinCategory(objects::Vector{Symbol}, immediate_relations::Vector{Pair{Symbol,Symbol}})
    relations = compute_closure(objects, immediate_relations)
    ThinCategory(objects, relations)
end

# Simple check for arrow existence
has_arrow(cat::ThinCategory, source::Symbol, target::Symbol) = target in cat.relations[source]

# Functor between thin categories
struct Functor
    source::ThinCategory
    target::ThinCategory
    mapping::Dict{Symbol,Symbol}
end

# Separate function to verify functor validity
function is_valid_functor(source::ThinCategory, target::ThinCategory, mapping::Dict{Symbol,Symbol})
    for src_obj in source.objects
        for related_obj in source.relations[src_obj]
            if !has_arrow(target, mapping[src_obj], mapping[related_obj])
                return false
            end
        end
    end
    true
end

# Safe functor constructor
function create_functor(source::ThinCategory, target::ThinCategory, mapping::Dict{Symbol,Symbol})
    if !is_valid_functor(source, target, mapping)
        return nothing
    end
    Functor(source, target, mapping)
end

# Find all valid functors between categories
function find_all_functors(source::ThinCategory, target::ThinCategory)
    functors = Vector{Functor}()

    function try_extend(partial_map::Dict{Symbol,Symbol}, remaining::Vector{Symbol})
        if isempty(remaining)
            functor = create_functor(source, target, copy(partial_map))
            if !isnothing(functor)
                push!(functors, functor)
            end
            return
        end

        curr = first(remaining)
        rest = remaining[2:end]

        # Try all possible assignments for the current object
        for target_obj in target.objects
            partial_map[curr] = target_obj
            # Quick validation of partial assignment
            valid = true
            for (s, rel) in source.relations
                if haskey(partial_map, s)
                    for t in rel
                        if haskey(partial_map, t) &&
                           !has_arrow(target, partial_map[s], partial_map[t])
                            valid = false
                            break
                        end
                    end
                end
                if !valid
                    break
                end
            end
            if valid
                try_extend(partial_map, rest)
            end
            delete!(partial_map, curr)
        end
    end

    try_extend(Dict{Symbol,Symbol}(), source.objects)
    return functors
end

# Natural transformations
function has_natural_transformation(F::Functor, G::Functor)::Bool
    @assert F.source == G.source && F.target == G.target
    all(has_arrow(F.target, F.mapping[obj], G.mapping[obj])
        for obj in F.source.objects)
end

# Example usage
function run_example()
    println("\n=== Simple Example ===")

    # Create simple categories
    C = ThinCategory([:a, :b, :c], [:a => :b, :b => :c])
    D = ThinCategory([:x, :y], [:x => :y])

    # Show category structures
    println("Category C relations:")
    for (obj, rels) in C.relations
        println("$obj → $rels")
    end

    println("\nCategory D relations:")
    for (obj, rels) in D.relations
        println("$obj → $rels")
    end

    # Find and display functors
    functors = find_all_functors(C, D)
    println("\nFound $(length(functors)) functors:")

    for (i, F) in enumerate(functors)
        print("Functor $i: ")
        for obj in C.objects
            print("$(obj)→$(F.mapping[obj]) ")
        end
        println()
    end

    # Find natural transformations
    println("\nNatural transformations:")
    for (i, F) in enumerate(functors)
        for (j, G) in enumerate(functors)
            if has_natural_transformation(F, G)
                println("F$i ⇒ F$j exists")
            end
        end
    end
end

# Run the example
run_example()
#+end_
