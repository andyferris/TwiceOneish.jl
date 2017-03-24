#=
"TwiceOneish" - a play on words for "bimonoidal". The package focuses on structures
with both a direct sum and tensor product, such as that seen in a symmetric bimonoidal category.
We focus on simple Cartesian structures.
=#

module TwiceOneish

import Base: size, getindex, setindex!, IndexStyle, IndexCartesian, tail,
    @propagate_inbounds, @_inline_meta

export ⊕, DirectSumArray

# Multidimensional direct sums are modelled as nested structures which
# concatenate their outermost dimensions

struct DirectSumArray{T, N} <: AbstractArray{T, N}
    a::AbstractArray{T, N}
    b::AbstractArray{T, N}

    function DirectSumArray{T, N}(a::AbstractArray{<:T, N}, b::AbstractArray{<:T, N}) where {T, N}
        @_inline_meta
        @boundscheck check_leading_sizes(size(a), size(b))
        return new{T,N}(a, b)
    end
end

const DirectSumVector{T} = DirectSumArray{T, 1}
const DirectSumMatrix{T} = DirectSumArray{T, 2}

@inline check_leading_sizes(::Tuple{}, ::Tuple{}) = nothing
@inline function check_leading_sizes(sa::Tuple, sb::Tuple)
    if sa[1] == sb[1]
        check_leading_sizes(tail(sa), tail(sb))
    else
        throw(DimensionMismatch("DirectSumArray expected leading dimensions to match"))
    end
end

DirectSumArray(a::AbstractArray{T1, N}, b::AbstractArray{T2, N}) where {T1, T2, N} = DirectSumArray{typejoin(T1, T2), N}(a, b)

# AbstractArray interface
IndexStyle(::Union{DSA, Type{DSA}} where DSA <: DirectSumArray) = IndexCartesian()

@inline size(dsa::DirectSumArray) = _size_concat((), size(dsa.a), size(dsa.b))
@inline _size_concat(out::Tuple, ::Tuple{}, ::Tuple{}) = out
@inline function _size_concat(out::Tuple, sa::Tuple, sb::Tuple)
    _size_concat((out..., sa[1] + sb[1]), tail(sa), tail(sb))
end

@propagate_inbounds function getindex(dsa::DirectSumArray{<:Any, N}, inds::Vararg{Int, N}) where {N}
    n = size(dsa.a, N)
    if inds[end] <= n
        return dsa.a[inds...]
    else
        return dsa.b[subtract_last(inds, n)...]
    end
end

@propagate_inbounds function setindex!(dsa::DirectSumArray{<:Any, N}, v, inds::Vararg{Int, N}) where {N}
    n = size(dsa.a, N)
    if inds[end] <= n
        return dsa.a[inds...] = v
    else
        return dsa.b[subtract_last(inds, n)] = v
    end
end

@inline subtract_last(inds::Tuple{Vararg{Int}}, n::Int) = _subtract_last((), n, inds...)
@inline _subtract_last(out, n, i) = (out..., i-n)
@inline _subtract_last(out, n, i, inds...) = _subtract_last((out..., i), n, inds...)

# Operator ⊕ notation
directsumcat(a::AbstractArray{<:Any, N}, b::AbstractArray{<:Any, N}) where {N} = DirectSumArray(a, b)
const ⊕ = directsumcat


end # module
