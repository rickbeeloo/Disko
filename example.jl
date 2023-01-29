
include("src/DiskoVector.jl")



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

test()