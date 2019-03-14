module PylonCameras

using Cameras
using ResourcePools

import Cameras:
    isrunning,
    start!,
    stop!,
    take!,
    trigger!

export PylonCamera,
    isrunning,
    open!,
    close!,
    start!,
    stop!,
    take!,
    trigger!

include("wrapper.jl")

mutable struct PylonCamera <: Camera
    device::Wrapper.IPylonDevice
    instant_camera::Wrapper.InstantCamera
    grab_result_ready_cond::Base.AsyncCondition
    grab_result_wait_timeout_ms::UInt32
    grab_result_retrieve_timeout_ms::UInt32
    function PylonCamera(max_num_buffer::Int, grab_result_wait_timeout_ms::Int, grab_result_retrieve_timeout_ms::Int)
        Wrapper.pylon_initialize()
        transport_layer_factory = Wrapper.get_transport_layer_factory_instance()
        grab_result_ready_cond = Base.AsyncCondition()

        device = Wrapper.create_first_device(transport_layer_factory)
        instant_camera = Wrapper.InstantCamera(device)
        Wrapper.max_num_buffer!(instant_camera, UInt(max_num_buffer))
        new(device, instant_camera, grab_result_ready_cond, grab_result_wait_timeout_ms, grab_result_retrieve_timeout_ms)
    end
end

function info(c::PylonCamera)
    device_info = Wrapper.get_device_info(c.device)
    vendor_name = Wrapper.get_vendor_name(device_info)
    model_name = Wrapper.get_model_name(device_info)
    serial_number = Wrapper.get_serial_number(device_info)
    return vendor_name, model_name, serial_number
end

isrunning(c::PylonCamera) = Wrapper.is_grabbing(c.instant_camera)
open!(c::PylonCamera) = Wrapper.open(c.instant_camera)
close!(c::PylonCamera) = Wrapper.close(c.instant_camera)
start!(c::PylonCamera) = Wrapper.start_grabbing_async(c.instant_camera, c.grab_result_wait_timeout_ms, Wrapper.notify_async_cond_safe_c, c.grab_result_ready_cond.handle)
start!(c::PylonCamera, images_to_grab::Int) = Wrapper.start_grabbing_async(c.instant_camera, UInt64(images_to_grab), c.grab_result_wait_timeout_ms, Wrapper.notify_async_cond_safe_c, c.grab_result_ready_cond.handle)
stop!(c::PylonCamera) = Wrapper.stop_grabbing(c.instant_camera)

function take!(c::PylonCamera)
    @debug "Waiting for result"
    wait(c.grab_result_ready_cond)
    @debug "Retrieving result for $(c.grab_result_retrieve_timeout_ms) ms"
    # Be careful not to pass grab_result on (e.g. to active logging like @info),
    # as it may cause the grab_result to be held for too long exhausting the pylon camera's buffer pool
    grab_result = Wrapper.retrieve_result(c.instant_camera, c.grab_result_retrieve_timeout_ms)
    @debug "Retrieved $(grab_result)"
    if Wrapper.grab_succeeded(grab_result)
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
        buffer_array = unsafe_wrap(Array, Ptr{UInt8}(buffer), size)
        function dispose(a)
            @debug "Releasing $(grab_result)"
            Wrapper.release(grab_result)
        end
        return PooledArray(buffer_array, dispose)
    else
        error("$(Wrapper.get_error_code(grab_result)) $(Wrapper.get_error_description(grab_result))")
    end
end

trigger!(camera::PylonCamera) = error("Not implemented yet")

end # module
