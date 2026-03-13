# T5DesktopShipyard

T5DesktopShipyard is a legacy desktop ship-design tool built with ActionScript 3 and Flex.
It was originally developed in Adobe Flash Builder and has remained usable long after the
original toolchain stopped receiving support.

## Status

- Last known successful compile in the original environment: 2016.
- Runtime behavior is still functional in preserved builds as of 2026.
- This repository should be treated as a legacy codebase with historical tooling.

## Repository Layout

- `ACS/`
	- Core shipyard UI and component logic.
	- Key source root: `ACS/src/`.
	- Includes configuration YAML under `ACS/src/T5ShipyardCfg/`.
- `T5DesktopShipyard/`
	- Desktop wrapper application project.
	- Main app entry point: `T5DesktopShipyard/src/T5DesktopShipyard.mxml`.
- `T5DesktopShipyard-app/`
	- Preserved app package artifacts.
- `as3yaml/`
	- Supporting AS3 YAML parsing library.
- `lib1541/`
	- Additional supporting ActionScript library code.
- `designs-and-tools/`
	- Design library (mostly `.yml`, plus `.acs`, `.txt`, `.html`, and some `.json`).
	- Conversion, reporting, and batch scripts for design data.

## Data and Formats

The project primarily uses YAML for design persistence and configuration. The surrounding
tooling also supports workflows involving ACS text format, JSON, and HTML exports.

Common data locations:

- App configuration: `ACS/src/T5ShipyardCfg/*.yml`
- Design corpus and converters: `designs-and-tools/`

## Tooling in `designs-and-tools`

The Perl scripts in `designs-and-tools/` are useful for conversion and reporting.

Examples:

- Convert YAML ships to ACS format:

	```bash
	cd designs-and-tools
	perl acs2acs.pl "Im-- A2-CL22 Fat Cat.yml"
	```

- Convert YAML ships to HTML:

	```bash
	cd designs-and-tools
	perl acs2html.pl "Im-- A2-CL22 Fat Cat.yml"
	```

- Build summary CSV from YAML designs:

	```bash
	cd designs-and-tools
	perl compile.pl > acs-summary.csv
	```

Dependencies for these scripts include Perl plus the YAML module.

## Opening the Project

Because Flash Builder is discontinued, modern development is mostly archival/maintenance.
If you have a compatible Flex/AS3 environment, import the projects as existing Eclipse-style
projects from:

- `ACS/`
- `T5DesktopShipyard/`
- `as3yaml/`
- `lib1541/`

## Notes for Maintenance

- The component system is highly configuration-driven, which makes extension easier but
	increases UI/editor complexity.
- Design headers and component arrays contain overlapping summary/detail fields; changes
	should be tested with real ship files from `designs-and-tools/`.
- Prefer small, verifiable changes and keep sample ship exports to confirm compatibility.

