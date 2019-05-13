module Wrapper
    # Disabled precompilation due to segmentation fault when calling functions
    # in Wrapper module -- with __init__() calling @initcxx
    __precompile__(false)

    import Base: iterate, IteratorSize, length

    using CxxWrap
    @wrapmodule(joinpath(@__DIR__, "..", "deps", "usr", "lib", "libpylon_julia_wrapper"), :define_pylon_wrapper)

    retrieve_result(camera::InstantCamera, timeoutMs::UInt32) = retrieve_result(camera, timeoutMs, TimeoutHandling_ThrowException)

    iterate(list::DeviceInfoList) = length(list) > 0 ? (list[1], 2) : nothing
    iterate(list::DeviceInfoList, i) = i <= length(list) ? (list[i], i+1) : nothing
    IteratorSize(list::DeviceInfoList) = length(list)
end
