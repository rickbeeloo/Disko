
mutable struct DiskoVector
    io::IOStream 
    byte_buffer::Vector{UInt8}
    int_buffer::Vector{Int64}
    last_read_ints::Int
    last_index::Int
    arr_size::Int
    DiskoVector() = new() # Allows unit def (see diskVector(...))
end

function _base_checks(file::String, buffer_size::Int)
    # Check validity of some args
    isfile(file) || error("Not a file")
    mod(buffer_size, 8) == 0 || error("Buffer should be mutliple of 8")
end

function diskVector(file::String, byte_buffer_size::Int) 
    # Create the struct 
    d = DiskoVector()
    _base_checks(file, byte_buffer_size)
    # Allocate the buffer vector
    d.byte_buffer = zeros(UInt8, byte_buffer_size) #Vector{UInt8}(undef, byte_buffer_size)
    # Open the file handle 
    d.io = open(file, "r")
    d.last_index = 0
    # Calculate array size 
    d.arr_size = Int64(filesize(file) / 8)
    d.int_buffer = Vector{Int64}(undef, Int64(byte_buffer_size/8))
    return d
end

function diskVector!(file::String, buffer::Vector{UInt8}) 
    # Same as the other funciton, but resuing the a buffer 
    d = DiskoVector() 
    _base_checks(file, length(buffer))
    d.byte_buffer = buffer 
    d.io = open(file, "r")
    d.arr_size = Int64(filesize(file) / 8)
    d.int_buffer = Vector{Int64}(undef,d.arr_size)
    d.last_index = 0
    return d
end

function read_chunk!(d::DiskoVector)
    # Read the bytes to the byte buffer
    rb = @inbounds readbytes!(d.io, d.byte_buffer, length(d.byte_buffer))
    # Move up the typed location, we use the size of the type for this
    d.last_read_ints = copy(d.last_index)
    d.last_index += Int64(rb / 8)
    # Fill in the reinterpret array 
    b_uint8 = reinterpret(UInt8, d.int_buffer)
    unsafe_copyto!(pointer(b_uint8), pointer(d.byte_buffer), length(d.byte_buffer))
end

function Base.getindex(d::DiskoVector, i::Int)
    # Check out of bounds 
    i > d.arr_size && throw(BoundsError(d, i))
    i == d.arr_size && close(d.io)
    # Keep reading till we can access the required index 
    if i > Int64(d.last_index)
       read_chunk!(d) # This mutates, last_index 
    end 
    # Calculate the shifted location in the current array 
    array_index = i - d.last_read_ints
    return @inbounds d.int_buffer[array_index]
end

function Base.length(d::DiskoVector)
    return d.arr_size
end

function Base.sizeof(d::DiskoVector)
    return sizeof(d.byte_buffer) + 96
end

function Base.eltype(d::DiskoVector)
    return Int64
end

function Base.close(d::DiskoVector)
    close(d.io)
end
