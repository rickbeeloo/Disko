
include("src/DiskoVector.jl")

using BenchmarkTools

function gen_test_file() 
    h = open("test.bin", "w+")
    #r = rand(UInt32, 100)
    r = UInt32.(collect(1:1_000_000))
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
   #gen_test_file()
   @btime begin
        tot = 0
        d = diskVector("test.bin", 100_000)
        for i in 1:length(d)
            tot += d[i]
        end
   end

end

gen_test_file() 
