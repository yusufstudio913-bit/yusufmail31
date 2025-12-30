default_platform(:ios)

platform :ios do
  desc "Build & upload to TestFlight"
  lane :beta do
    build_app(
      scheme: "YusufMail31",
      export_method: "app-store"
    )

    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end