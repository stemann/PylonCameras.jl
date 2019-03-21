mutable struct PylonAcquiredImage{T,N} <: AcquiredImage{T,N}
    grab_result
    # Inherits behaviour of AbstractPooledArray, by having the same fields
    array::AbstractArray{T,N}
    ref_count::Int
    dispose::Function
    function PylonAcquiredImage(grab_result)
        T = UInt8
        width = Wrapper.get_width(grab_result)
        height = Wrapper.get_height(grab_result)
        buffer = Wrapper.get_buffer(grab_result)
        pixel_type = Wrapper.get_pixel_type(grab_result)
        if Wrapper.is_bgr(pixel_type) || Wrapper.is_rgb(pixel_type)
            samples_per_pixel = Wrapper.samples_per_pixel(pixel_type)
            size = (samples_per_pixel, width, height)
        else
            size = (width, height)
        end
        @assert prod(size) == Wrapper.get_image_size(grab_result)
        buffer_array = unsafe_wrap(Array, Ptr{T}(buffer), size)
        N = ndims(buffer_array)
        new{T,N}(grab_result, buffer_array, 1, dispose)
    end
end

function dispose(img::PylonAcquiredImage)
    @debug "Releasing $(img.grab_result)"
    Wrapper.release(img.grab_result)
end
