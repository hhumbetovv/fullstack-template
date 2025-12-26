# Workspace Build Overview

## Quick Stats

- **Total Modules**: 23
- **Modules With build_runner**: 13
- **Modules Without build_runner**: 10
- **Total Dependencies**: 67
- **Average Dependencies**: 2.91
- **Peak Concurrent Modules**: 3

## Graph Index

- [foundation.md](module_graph.md#foundationmd) — Highlights how shared modules feed feature delivery.
- [features.md](module_graph.md#featuresmd) — Focuses purely on feature-layer dependencies.
- [waves.md](module_graph.md#wavesmd) — Visualizes build waves from top to bottom.
- [layers.md](module_graph.md#layersmd) — Clusters modules by architectural tier and feature area.

## Build Waves

### Wave 0

- **common_shared** → no dependencies
- **processor** → no dependencies
- **ui_foundation** → no dependencies

### Wave 1

- **common_presentation** → depends on: common_shared
- **core_domain** → depends on: common_shared, processor
- **core_navigation** → depends on: ui_foundation

### Wave 2

- **core_data** → depends on: common_shared, core_domain
- **demo_domain** → depends on: core_domain
- **ui_components** → depends on: common_presentation, common_shared, processor, ui_foundation

### Wave 3

- **console_presentation** → depends on: common_presentation, common_shared, core_domain, core_navigation, processor, ui_components, ui_foundation
- **demo_data** → depends on: core_data, demo_domain

### Wave 4

- **demo_presentation** → depends on: common_presentation, common_shared, core_domain, core_navigation, demo_data, demo_domain, processor

### Wave 5

- **app** → depends on: common_presentation, common_shared, console_presentation, core_data, core_domain, core_navigation, demo_presentation, processor, ui_components, ui_foundation


## Unused Module Dependencies

- **demo_data** → core_data
- **demo_domain** → core_domain

## Unused Packages

- **console_presentation** → get_it, injectable
- **core_data** → flutter
- **core_presentation** → auto_route, get_it
- **demo_data** → get_it
- **demo_domain** → get_it
- **demo_presentation** → get_it
- **gen_exporter** → source_gen

_Detailed graphs are available in `module_graph.md`._

