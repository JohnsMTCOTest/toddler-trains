# Toddler Trains (ChuggaChugga)

A touch-interactive native iOS train game built for 2-year-olds using SwiftUI.
Features continuous motion, tapping to toot the whistle with steam puffs, day/night switching, and floating pop-able balloons.

## Deployment
Automated via GitHub Actions to Apple TestFlight.

The deployment workflow imports a persistent Apple Distribution certificate into its temporary keychain. Configure the repository secrets `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64` (the base64-encoded `.p12` certificate and private key) and `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD` (the `.p12` export password), in addition to the App Store Connect and team secrets already used by the workflow. The signing certificate must belong to the configured Apple Developer team. If creating a replacement certificate is blocked by Apple's certificate limit, revoke only obsolete CI-created distribution certificates before creating and exporting a new certificate. Keep the `.p12` and its password private; do not commit either to the repository.
