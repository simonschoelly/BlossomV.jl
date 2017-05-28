__precompile__()
module BlossomV

if isfile(joinpath(Pkg.dir("BlossomV"),"deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("BlossomV not properly installed. Please run Pkg.build(\"BlossomV\")")
end

export
    PerfectMatchingCtx,
    Matching, solve, add_edge, get_match, get_all_matches


const CostT = Union{Int32, Float64}

type PerfectMatchingCtx{T<:CostT}
    ptr::Ptr{Void}

     function (::Type{PerfectMatchingCtx{T}}){T<:CostT}(ptr::Ptr{Void})
        self = new{T}(ptr)
        finalizer(self, destroy)
        verbose(self, false)
        self
    end
end

function destroy{T}(matching::PerfectMatchingCtx{T})
    if matching.ptr == C_NULL
        return
    end
    if T == Int32
        ccall((:matching_destruct, _jl_blossom5int32), Void, (Ptr{Void},), matching.ptr)
    elseif T == Float64
        ccall((:matching_destruct, _jl_blossom5float64), Void, (Ptr{Void},), matching.ptr)
    end

    matching.ptr = C_NULL
    nothing
end

dense_num_edges(node_num) =  node_num*(node_num-1)÷2

Matching(node_num::Integer) = Matching(Int32, node_num)
Matching(node_num::Integer, edge_num_max::Integer) = Matching(Int32, node_num, edge_num_max)

Matching{T}(::Type{T}, node_num::Integer) = Matching(T, node_num, dense_num_edges(node_num))

#TODO maybe use dispatch here
function Matching{T}(::Type{T}, node_num::Integer, edge_num_max::Integer)
    if T <: CostT
        return Matching(T, Int32(node_num), Int32(edge_num_max))
    elseif T <: Integer
        return Matching(Int32, Int32(node_num), Int32(edge_num_max))
    elseif T <: AbstactFloat
        return Matching(Float64, Int32(node_num), Int32(edge_num_max))
    end
end

function Matching{T<:CostT}(::Type{T}, node_num::Int32, edge_num_max::Int32)
    assert(node_num % 2 == 0)
    if T == Int32
        ptr = ccall((:matching_construct, _jl_blossom5int32), Ptr{Void}, (Int32, Int32), node_num, edge_num_max)
    elseif T == Float64
        ptr = ccall((:matching_construct, _jl_blossom5float64), Ptr{Void}, (Int32, Int32), node_num, edge_num_max)
    end
    return PerfectMatchingCtx{T}(ptr)
end


function add_edge{T}(matching::PerfectMatchingCtx{T}, first_node::Integer, second_node::Integer, cost::Number)
	add_edge(matching, Int32(first_node), Int32(second_node), T(cost))
end

function add_edge{T<:CostT}(matching::PerfectMatchingCtx{T}, first_node::Int32, second_node::Int32, cost::T)
    first_node != second_node || error("Can not have an edge between $(first_node) and itself.")
    first_node >= 0  || error("first_node less than zero (value: $(first_node)). Indexes are zero-based.")
    second_node >= 0  || error("second_node less than zero (value: $(second_node)). Indexes are zero-based.")
    cost >= 0  || error("Cost must be positive. Edge between $(first_node) and $(second_node) has cost $cost.")
    if T == Int32
       ccall((:matching_add_edge, _jl_blossom5int32), Int32, (Ptr{Void}, Int32, Int32, Int32), matching.ptr, first_node, second_node, cost)
    elseif T == Float64
       ccall((:matching_add_edge, _jl_blossom5float64), Int32, (Ptr{Void}, Int32, Int32, Float64), matching.ptr, first_node, second_node, cost)
    end
end

function solve{T}(matching::PerfectMatchingCtx{T})
    if T == Int32
        ccall((:matching_solve, _jl_blossom5int32), Void, (Ptr{Void},), matching.ptr)
    elseif T == Float64
        ccall((:matching_solve, _jl_blossom5float64), Void, (Ptr{Void},), matching.ptr)
    end
    nothing
end

get_match(matching::PerfectMatchingCtx, node::Integer) = get_match(matching, Int32(node))
function get_match{T<:CostT}(matching::PerfectMatchingCtx{T}, node::Int32)
    if T == Int32
        ccall((:matching_get_match, _jl_blossom5int32), Int32, (Ptr{Void}, Int32), matching.ptr, node)
    elseif T == Float64
        ccall((:matching_get_match, _jl_blossom5float64), Int32, (Ptr{Void}, Int32), matching.ptr, node)
    end
end

function get_all_matches(m::PerfectMatchingCtx, n_nodes::Integer)
    ret = Matrix{Int32}(2, n_nodes÷2)
    assigned = falses(n_nodes)
    kk = 1
    for ii in 0:n_nodes-1
        assigned[ii+1] && continue
        jj = get_match(m, ii)
        @assert(!assigned[jj+1])
        assigned[ii+1] = true
        assigned[jj+1] = true

        ret[1,kk] = ii
        ret[2,kk] = jj
        kk+=1
    end
    @assert(kk-1 == n_nodes÷2)
    return ret
end

function verbose{T}(matching::PerfectMatchingCtx{T}, verbose::Bool)
    if T == Int32
        ccall((:matching_verbose, _jl_blossom5int32), Void, (Ptr{Void}, Bool), matching.ptr, verbose)
    elseif T == Float64
        ccall((:matching_verbose, _jl_blossom5float64), Void, (Ptr{Void}, Bool), matching.ptr, verbose)
    end
end

end # module
