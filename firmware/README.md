# Firmware

Two firmwares, one per half:

- **Master half**: runs unmodified upstream [GP2040-CE](https://gp2040-ce.info/). Not vendored here — the build pulls a release binary or builds GP2040-CE from its own checkout. Configuration is captured in `master/` (config snapshots, `.uf2` build notes).
- **Slave half** (`slave/`): custom Pico-SDK firmware. Scans the local Choc matrix, exposes buttons as an I2C button expander (PCF8575-compatible) on the inter-half USB-C cable. GP2040-CE on the master reads it as a normal I2C button expander.

See `../../research/gp2040-split.md` for the architecture rationale.
