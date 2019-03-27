module Wrapper
    # Disabled precompilation due to segmentation fault when calling functions
    # in Wrapper module -- with __init__() calling @initcxx
    __precompile__(false)

    using CxxWrap
    @wrapmodule(joinpath(@__DIR__, "..", "deps", "usr", "lib", "libpylon_julia_wrapper"), :define_pylon_wrapper)

    import Base: iterate, IteratorSize, length

    notify_async_cond(handle::Ptr{Nothing}) = ccall(:uv_async_send, Cint, (Ptr{Nothing}, ), handle)
    notify_async_cond_safe_c = @safe_cfunction(notify_async_cond, Int32, (Ptr{Nothing}, ))

    retrieve_result(camera::InstantCamera, timeoutMs::UInt32) = retrieve_result(camera, timeoutMs, TimeoutHandling_ThrowException)

    iterate(list::DeviceInfoList) = length(list) > 0 ? (list[1], 2) : nothing
    iterate(list::DeviceInfoList, i) = i <= length(list) ? (list[i], i+1) : nothing
    IteratorSize(list::DeviceInfoList) = length(list)
end
