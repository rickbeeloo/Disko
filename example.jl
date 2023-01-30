
include("src/DiskoVector.jl")

using BenchmarkTools

function gen_test_file() 
    h = open("test.bin", "w+")
    #r = rand(UInt32, 100)
    r = UInt16.(collect(1:100))
    for numb in r 
        write(h, numb)
    end
    close(h)
end

function test() 
    gen_test_file()
    d = diskVector("test.bin", 16, UInt16)
    for i in 1:length(d)
        println(d[i])
    end
end

function disko_test()

   @time begin
        tot = 0
        arr = Vector{UInt8}(undef, 100_000)
        d = diskVector("/home/codegodz/packages/DiskMergeSort/data/test1.bin", 100_000)
        for i in 1:length(d)
            tot += d[i]
        end
   end

end


#disko_test()


function test(type::T) where T <: DataType
    x = zeros(type, 10)
    println(x)
end

test(UInt32)