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
end
