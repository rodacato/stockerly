module TotpHelper
  # The QR is drawn from the provisioning URI, in-process. No image service and
  # no third-party endpoint sees the secret (ADR-019).
  def totp_qr_svg(uri)
    RQRCode::QRCode.new(uri).as_svg(
      module_size: 5, standalone: true, use_path: true,
      color: "000", shape_rendering: "crispEdges"
    ).html_safe
  end
end
