using Cameras
using PylonCameras
using Test

@testset "pylon_camera_tests" begin
    ENV["PYLON_CAMEMU"] = 2

    expected_vendor_name = "Basler"
    expected_model_name = "Emulation"
    expected_serial_number(n::Int) = "0815-$(lpad(string(n), 4, '0'))"

    @testset "Construction" begin
        camera = PylonCamera()

        vendor_name, model_name, serial_number = PylonCameras.info(camera)

        @test vendor_name == expected_vendor_name
        @test model_name == expected_model_name
        @test serial_number == expected_serial_number(0)
    end

    @testset "Construction with vendor_name" begin
        camera = PylonCamera(vendor_name = expected_vendor_name)

        vendor_name, model_name, serial_number = PylonCameras.info(camera)

        @test vendor_name == expected_vendor_name
        @test model_name == expected_model_name
        @test serial_number == expected_serial_number(0)
    end

    @testset "Construction with model_name" begin
        camera = PylonCamera(model_name = expected_model_name)

        vendor_name, model_name, serial_number = PylonCameras.info(camera)

        @test vendor_name == expected_vendor_name
        @test model_name == expected_model_name
        @test serial_number == expected_serial_number(0)
    end

    @testset "Construction with serial_number" begin
        selected_serial_number = expected_serial_number(1)

        camera = PylonCamera(serial_number = selected_serial_number)

        vendor_name, model_name, serial_number = PylonCameras.info(camera)

        @test vendor_name == expected_vendor_name
        @test model_name == expected_model_name
        @test serial_number == selected_serial_number
    end

    @testset "Opening/Closing" begin
        camera = PylonCamera()

        @test !isopen(camera)
        open!(camera)
        @test isopen(camera)
        close!(camera)
        @test !isopen(camera)

        @testset "Re-opening a camera" begin
            open!(camera)
            @test isopen(camera)
            close!(camera)
            @test !isopen(camera)
        end
    end

    @testset "Grab synchronously, finite" begin
        images_to_grab = 1
        camera = PylonCamera()
        open!(camera)

        images_grabbed = 0
        @test !isrunning(camera)
        start!(camera, images_to_grab)
        @test isrunning(camera)
        while isrunning(camera)
            img = take!(camera)
            images_grabbed = images_grabbed + 1
            release!(img)
        end
        stop!(camera)
        @test !isrunning(camera)
        @test images_grabbed == images_to_grab

        @testset "Re-start grabbing" begin
            start!(camera, images_to_grab)
            @test isrunning(camera)
            stop!(camera)
            @test !isrunning(camera)
        end
    end

    @testset "Grab synchronously, infinite" begin
        images_to_grab = 1
        camera = PylonCamera()
        open!(camera)

        images_grabbed = 0
        @test !isrunning(camera)
        start!(camera)
        @test isrunning(camera)
        while images_grabbed < images_to_grab
            img = take!(camera)
            images_grabbed = images_grabbed + 1
            release!(img)
        end
        stop!(camera)
        @test !isrunning(camera)
        @test images_grabbed == images_to_grab
    end

    @testset "Grab asynchronously" begin
        images_to_grab = 3
        camera = PylonCamera()
        open!(camera)

        compute_task = @async begin
            i = 0
            t = 0
            while isrunning(camera)
                t1 = time_ns()
                (1:1_000_000) .^ 2 # Just a computation
                t2 = time_ns()
                i = i + 1
                t = t + (t2 - t1)
                yield()
            end
            return i, t
        end

        images_grabbed = 0
        @test !isrunning(camera)
        start!(camera, images_to_grab)
        @test isrunning(camera)
        while isrunning(camera)
            img = take!(camera)
            images_grabbed = images_grabbed + 1
            release!(img)
        end
        stop!(camera)
        @test !isrunning(camera)
        @test images_grabbed == images_to_grab

        compute_i, compute_t_ns = fetch(compute_task)
        @test compute_i > 0
        @test compute_t_ns > 0
    end
end
