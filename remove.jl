

function create(type::T) where T <: DataType
    v = Vector{type}(undef, 10)
    println(typeof(v))
    return v
end


println(create(Int64))