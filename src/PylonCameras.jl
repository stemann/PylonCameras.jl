module PylonCameras

using Cameras
using ColorTypes
using FixedPointNumbers
using ImageCore
using ResourcePools

import Cameras:
    isopen,
    open!,
    close!,
    isrunning,
    start!,
    stop!,
    take!,
    trigger!,
    id,
    timestamp

export PylonCamera,
    isopen,
    open!,
    close!,
    isrunning,
    start!,
    stop!,
    take!,
    trigger!,
    id,
    image_number,
    timestamp

include("wrapper.jl")
include("pylon_acquired_image.jl")

mutable struct PylonCamera <: Camera
    device_info::Wrapper.DeviceInfo
    instant_camera::Wrapper.InstantCamera
    terminate_waiter_event::Wrapper.WaitObjectEx
    initiate_wait_event::Wrapper.WaitObjectEx
    grab_result_waiter::Union{Wrapper.StdThread, Nothing}
    grab_result_ready_cond::Base.AsyncCondition
    grab_result_wait_timeout_ms::UInt32
    grab_result_retrieve_timeout_ms::UInt32
    feature_filename::Union{String, Nothing}
    function PylonCamera(;
            vendor_name::Union{String, Nothing} = nothing,
            model_name::Union{String, Nothing} = nothing,
            serial_number::Union{String, Nothing} = nothing,
            max_num_buffer = 10,
            grab_result_wait_timeout_ms = 5000,
            grab_result_retrieve_timeout_ms = 100,
            feature_filename::Union{String, Nothing} = nothing)
        Wrapper.pylon_initialize()

        terminate_waiter_event = Wrapper.create_wait_object_ex(false)
        initiate_wait_event = Wrapper.create_wait_object_ex(false)
        grab_result_ready_cond = Base.AsyncCondition()

        device_infos = Wrapper.enumerate_devices()
        function matches(device_info;
                vendor_name::Union{Regex, String, Nothing} = nothing,
                model_name::Union{Regex, String, Nothing} = nothing,
                serial_number::Union{Regex, String, Nothing} = nothing)
            device_vendor_name = String(Wrapper.get_vendor_name(device_info))
            device_model_name = String(Wrapper.get_model_name(device_info))
            device_serial_number = String(Wrapper.get_serial_number(device_info))
            vendor_name_matches = vendor_name === nothing || occursin(vendor_name, device_vendor_name)
            model_name_matches = model_name === nothing || occursin(model_name, device_model_name)
            serial_number_matches = serial_number === nothing || occursin(serial_number, device_serial_number)
            return vendor_name_matches && model_name_matches && serial_number_matches
        end
        matching_device_infos = filter(
            dev -> matches(dev; vendor_name = vendor_name, model_name = model_name, serial_number = serial_number),
            collect(device_infos))
        if isempty(matching_device_infos)
            error("No matching camera found!")
        end
        device_info = first(matching_device_infos)
        instant_camera = Wrapper.InstantCamera(device_info)
        Wrapper.max_num_buffer!(instant_camera, UInt(max_num_buffer))
        new(device_info, instant_camera,
            terminate_waiter_event,
            initiate_wait_event,
            nothing,
            grab_result_ready_cond,
            grab_result_wait_timeout_ms,
            grab_result_retrieve_timeout_ms,
            feature_filename)
    end
end

function info(c::PylonCamera)
    vendor_name = Wrapper.get_vendor_name(c.device_info)
    model_name = Wrapper.get_model_name(c.device_info)
    serial_number = Wrapper.get_serial_number(c.device_info)
    return vendor_name, model_name, serial_number
end

isopen(c::PylonCamera) = Wrapper.is_open(c.instant_camera)

function open!(c::PylonCamera)
    if c.feature_filename != nothing
        @debug "Removing default configuration from instance"
        Wrapper.register_configuration(c.instant_camera, C_NULL, Wrapper.RegistrationMode_ReplaceAll, Wrapper.Cleanup_None)
    end
    @debug "Opening camera"
    Wrapper.open(c.instant_camera)
    if c.feature_filename != nothing
        @debug "Getting camera node map"
        node_map = Wrapper.get_node_map(c.instant_camera)
        @debug "Loading node map from $(c.feature_filename)"
        Wrapper.load_features(c.feature_filename, node_map)
    end
end

close!(c::PylonCamera) = Wrapper.close(c.instant_camera)

isrunning(c::PylonCamera) = Wrapper.is_grabbing(c.instant_camera)

function start!(c::PylonCamera, images_to_grab::Union{Int, Nothing} = nothing)
    c.grab_result_waiter = Wrapper.start_grab_result_waiter(c.instant_camera,
        c.grab_result_wait_timeout_ms,
        c.grab_result_ready_cond.handle,
        c.terminate_waiter_event,
        c.initiate_wait_event)
    if images_to_grab == nothing
        Wrapper.start_grabbing(c.instant_camera)
    else
        Wrapper.start_grabbing(c.instant_camera, UInt64(images_to_grab))
    end
end

function stop!(c::PylonCamera)
    Wrapper.stop_grab_result_waiter(c.grab_result_waiter, c.terminate_waiter_event)
    Wrapper.stop_grabbing(c.instant_camera)
end

function take!(c::PylonCamera)::AbstractAcquiredImage
    @debug "Waiting for result"
    Wrapper.signal(c.initiate_wait_event)
    wait(c.grab_result_ready_cond)
    @debug "Retrieving result for $(c.grab_result_retrieve_timeout_ms) ms"
    # Be careful not to pass grab_result on (e.g. to active logging like @info),
    # as it may cause the grab_result to be held for too long exhausting the pylon camera's buffer pool
    grab_result = Wrapper.retrieve_result(c.instant_camera, c.grab_result_retrieve_timeout_ms)
    @debug "Retrieved $(grab_result)"
    if Wrapper.grab_succeeded(grab_result)
        return PylonAcquiredImage(grab_result)
    else
        error("$(Wrapper.get_error_code(grab_result)) $(Wrapper.get_error_description(grab_result))")
    end
end

trigger!(camera::PylonCamera) = error("Not implemented yet")

end # module
