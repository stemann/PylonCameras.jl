mutable struct PylonAcquiredImage{T,N} <: AbstractAcquiredImage{T,N}
    grab_result
    # Inherits behaviour of AbstractPooledDenseArray, by having the same fields
    array::Array{T,N}
    ref_count::Int
    dispose::Function
    function PylonAcquiredImage(grab_result)
        width = Wrapper.get_width(grab_result)
        height = Wrapper.get_height(grab_result)
        buffer = Wrapper.get_buffer(grab_result)
        pixel_type = Wrapper.get_pixel_type(grab_result)
        if Wrapper.is_bgr(pixel_type) || Wrapper.is_rgb(pixel_type)
            samples_per_pixel = Wrapper.samples_per_pixel(pixel_type)
            size = (samples_per_pixel, width, height)
            TPixel = Wrapper.is_bgr(pixel_type) ? BGR : RGB
        else
            size = (width, height)
            TPixel = Gray
        end
        @assert prod(size) == Wrapper.get_image_size(grab_result)
        buffer_array = unsafe_wrap(Array, Ptr{UInt8}(buffer), size)
        image = colorview(TPixel, normedview(buffer_array))
        N = ndims(image)
        new{TPixel{N0f8},N}(grab_result, image, 1, dispose)
    end
end

function dispose(img::PylonAcquiredImage)
    @debug "Releasing $(img.grab_result)"
    Wrapper.release(img.grab_result)
end

id(img::PylonAcquiredImage) = Wrapper.get_id(img.grab_result)
image_number(img::PylonAcquiredImage) = Wrapper.get_image_number(img.grab_result)
timestamp(img::PylonAcquiredImage) = Wrapper.get_time_stamp(img.grab_result)
