
mutable struct DiskoVector
    io::IOStream 
    byte_buffer::Vector{UInt8}
    int_buffer::Base.ReinterpretArray{Int64, 1, UInt8, Vector{UInt8}, false}
    type::T where T <: DataType
    last_read_ints::Int
    last_index::Int
    arr_size::Int
    DiskoVector() = new() # Allows unit def (see diskVector(...))
end

function _base_checks(file::String, buffer_size::Int, type::DataType)
    # Check validity of some args
    isfile(file) || error("Not a file")
    mod(buffer_size, sizeof(type)) == 0 || error("Buffer should be mutliple of ", string(sizeof(type)))
end

function diskVector(file::String, byte_buffer_size::Int, type::T) where T <:DataType
    # Create the struct 
    d = DiskoVector()
    _base_checks(file, byte_buffer_size, type)
    # Allocate the buffer vector
    d.byte_buffer = Vector{UInt8}(undef, byte_buffer_size)
    # Open the file handle 
    d.io = open(file, "r")
    d.type = type
    # Calculate array size 
    d.arr_size = Int64(filesize(file) / sizeof(type))
    return d
end

function diskVector!(file::String, buffer::Vector{UInt8}, type::T) where T <: DataType
    # Same as the other funciton, but resuing the a buffer 
    d = DiskoVector() 
    _base_checks(file, length(buffer), type)
    d.byte_buffer = buffer 
    d.io = open(file, "r")
    d.type = type
    d.arr_size = Int64(filesize(file) / sizeof(type))
    return d
end

function read_chunk!(d::DiskoVector)
    # Read the bytes to the byte buffer
    rb = @inbounds readbytes!(d.io, d.byte_buffer, length(d.byte_buffer))
    # Move up the typed location, we use the size of the type for this
    d.last_read_ints = copy(d.last_index)
    d.last_index += Int64(rb / sizeof(d.type))
    # Fill in the reinterpret array 
    d.int_buffer = reinterpret(Int64, d.byte_buffer)
end

@inline function Base.getindex(d::DiskoVector, i::Int)
    # Check out of bounds 
    i > d.arr_size && throw(BoundsError(d, i))
    i == d.arr_size && close(d.io)
    # Keep reading till we can access the required index 
    if i > Int64(d.last_index)
       read_chunk!(d) # This mutates, last_index 
    end 
    # Calculate the shifted location in the current array 
    array_index = i - d.last_read_ints
    return d.int_buffer[array_index]
end

function Base.length(d::DiskoVector)
    return d.arr_size
end

function Base.sizeof(d::DiskoVector)
    return sizeof(d.byte_buffer) + 96
end


