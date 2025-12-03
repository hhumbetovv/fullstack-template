# Module dependencies

## app

### Dependencies

- Modules: common_presentation, common_shared, console_presentation, core_data, core_navigation, core_presentation, demo_presentation, ui_components, ui_foundation
- Packages: auto_route (^10.1.0), flutter (sdk:flutter), get_it (^8.0.3), injectable (^2.5.2), intl (^0.20.2)

### Dev dependencies

- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0)

## common_presentation

### Dependencies

- Modules: common_shared
- Packages: flutter (sdk:flutter)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15)

## common_shared

### Dependencies

- Packages: flutter_dotenv (^5.2.1), intl (^0.20.2)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15)

## common_tooling

### Dependencies

- Packages: path (^1.9.0)

### Dev dependencies

- None

## console_presentation

### Dependencies

- Modules: common_presentation, common_shared, core_navigation, core_presentation, processor, ui_components, ui_foundation
- Packages: auto_route (^10.1.0), flutter (sdk:flutter), get_it (^8.0.3), injectable (^2.5.2), path_provider (^2.1.5), share_plus (^11.0.0)

### Dev dependencies

- Modules: gen_data, gen_view_kit
- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0)

## core_data

### Dependencies

- Modules: common_shared, core_domain
- Packages: dio (^5.8.0+1), flutter (sdk:flutter), flutter_secure_storage (^9.2.4), get_it (^8.0.3), injectable (^2.5.2), json_annotation (^4.9.0), retrofit (^4.7.2), shared_preferences (^2.5.3)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0), json_serializable (^6.9.4), retrofit_generator (^10.0.5)

## core_domain

### Dependencies

- Packages: flutter (sdk:flutter)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15)

## core_navigation

### Dependencies

- Modules: ui_foundation
- Packages: auto_route (^10.1.0), flutter (sdk:flutter)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15)

## core_presentation

### Dependencies

- Modules: common_presentation, common_shared, core_domain, processor
- Packages: auto_route (^10.1.0), flutter (sdk:flutter), get_it (^8.0.3), nested (^1.0.0), provider (^6.1.4)

### Dev dependencies

- None

## demo_data

### Dependencies

- Modules: core_data, demo_domain
- Packages: get_it (^8.0.3), injectable (^2.5.2)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0)

## demo_domain

### Dependencies

- Modules: core_domain
- Packages: get_it (^8.0.3), injectable (^2.5.2)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0)

## demo_presentation

### Dependencies

- Modules: core_navigation, core_presentation, demo_data, demo_domain, processor
- Packages: auto_route (^10.1.0), flutter (sdk:flutter), get_it (^8.0.3), injectable (^2.5.2)

### Dev dependencies

- Modules: gen_data, gen_view_kit
- Packages: build_runner (^2.4.15), injectable_generator (^2.7.0)

## gen_assets

### Dependencies

- Modules: common_tooling
- Packages: build (^3.0.0), collection (^1.18.0), dart_style (^3.1.0), glob (^2.1.3), package_config (^2.1.0), path (^1.9.0)

### Dev dependencies

- None

## gen_core

### Dependencies

- Modules: common_tooling
- Packages: analyzer (^7.4.5), build (^3.0.0), code_builder (^4.10.1), dart_style (^3.1.0), source_gen (^3.0.0)

### Dev dependencies

- None

## gen_data

### Dependencies

- Modules: gen_core, processor
- Packages: analyzer (^7.4.5), build (^3.0.0), code_builder (^4.10.1), source_gen (^3.0.0)

### Dev dependencies

- None

## gen_exporter

### Dependencies

- Packages: analyzer (^7.4.5), build (^3.0.0), dart_style (^3.1.0), glob (^2.1.3), source_gen (^3.0.0)

### Dev dependencies

- None

## gen_palette

### Dependencies

- Modules: gen_core, gen_data, processor
- Packages: analyzer (^7.4.5), build (^3.0.0), code_builder (^4.10.1), source_gen (^3.0.0)

### Dev dependencies

- None

## gen_view_kit

### Dependencies

- Modules: common_tooling, gen_core, processor
- Packages: analyzer (^7.4.5), build (^3.0.0), code_builder (^4.10.1), source_gen (^3.0.0)

### Dev dependencies

- None

## processor

### Dependencies

- Packages: json_annotation (^4.9.0), meta (^1.15.0)

### Dev dependencies

- Modules: gen_exporter
- Packages: build_runner (^2.4.15), json_serializable (^6.9.4)

## scripts

### Dependencies

- Modules: common_tooling
- Packages: args (^2.5.0), get_it (^8.0.3), path (^1.9.0), yaml (^3.1.2)

### Dev dependencies

- None

## ui_components

### Dependencies

- Modules: common_presentation, common_shared, processor, ui_foundation
- Packages: flutter (sdk:flutter), flutter_svg (^2.2.1)

### Dev dependencies

- Modules: gen_exporter, gen_palette
- Packages: build_runner (^2.4.15)

## ui_foundation

### Dependencies

- Packages: flutter (sdk:flutter)

### Dev dependencies

- Modules: gen_assets, gen_exporter
- Packages: build_runner (^2.4.15)

## ui_previews

### Dependencies

- Modules: ui_components, ui_foundation
- Packages: flutter (sdk:flutter)

### Dev dependencies

- None
