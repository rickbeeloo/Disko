## DISKO - sequential integer disk buffer
**Own usage**; this is very limited still and only allows fast sequential access. For more advanced usage of arrays on disk use [DiskArray](https://github.com/meggart/DiskArrays.jl)

Sometimes, like for mergesort, we want to access integers from multiple files at the same time. While `mmap` is ideal for this it will cause[ major page faults](https://scoutapm.com/blog/understanding-page-faults-and-memory-swap-in-outs-when-should-you-worry " major page faults") - significantly affecting performance. To tackle this we can read parts of arrays from files, and when indexes beyond the buffer size are required we read the next bytes to the buffer. This is maximum around ~2x slower than directly filling a big buffer using `readbytes!`

---

#### How it's done 
It's quite simple using `readbytes!` and `reinterpret`:
- Read bytes (`UInt8`) into a buffer array
- use `reinterpret` to "pretend" that this array is actually `Int64`
- Keep loading chunks and updating the pointers when indexes are requested 
- **Note**, this violates O(1) for `getindex()` as it may have to read bytes before returning results

---

#### How to use
```Julia
d = diskVector("test.bin", 100_000, Int64)
for i in 1:length(d)
     println(d[i])
end
```
Here `100_000` is the buffer size, i.e. the number of bytes to read from the file. If you use `Int64` this then will cover `100_000 / 8  = 12_500` integers. 

---

#### TODO
- Make type defs in struct more specific