# Workspace Build Overview

## Quick Stats

- **Total Modules**: 15
- **Modules With build_runner**: 13
- **Modules Without build_runner**: 2
- **Total Dependencies**: 36
- **Average Dependencies**: 2.40
- **Peak Concurrent Modules**: 4
- **Configured Parallel Limit**: 4

## Graph Index

### Overview

- [Full Workspace Module Graph](build_info/graph_all.md) — Complete dependency graph sorted by build waves.

### Build Waves

- [Wave 0 Dependency Graph](build_info/graph_wave_0.md) — Modules scheduled in wave 0 with their workspace dependencies.
- [Wave 1 Dependency Graph](build_info/graph_wave_1.md) — Modules scheduled in wave 1 with their workspace dependencies.
- [Wave 2 Dependency Graph](build_info/graph_wave_2.md) — Modules scheduled in wave 2 with their workspace dependencies.
- [Wave 3 Dependency Graph](build_info/graph_wave_3.md) — Modules scheduled in wave 3 with their workspace dependencies.
- [Wave 4 Dependency Graph](build_info/graph_wave_4.md) — Modules scheduled in wave 4 with their workspace dependencies.

### Architecture Layers

- [Common Layer Graph](build_info/graph_layer_common.md) — Common Layer modules with their workspace dependencies.
- [Core Layer Graph](build_info/graph_layer_core.md) — Core Layer modules with their workspace dependencies.
- [Data Layer Graph](build_info/graph_layer_data.md) — Data Layer modules with their workspace dependencies.
- [Domain Layer Graph](build_info/graph_layer_domain.md) — Domain Layer modules with their workspace dependencies.
- [Presentation Layer Graph](build_info/graph_layer_presentation.md) — Presentation Layer modules with their workspace dependencies.
- [UI Layer Graph](build_info/graph_layer_ui.md) — UI Layer modules with their workspace dependencies.

### Feature Areas

- [GLOBAL Feature Graph](build_info/graph_feature_global.md) — GLOBAL feature modules with their dependencies.

## Build Waves

The modules requiring build_runner will be built in the following waves:


### Wave 0

- **common_shared** → no dependencies
- **core_domain** → no dependencies
- **processor** → no dependencies
- **ui_foundation** → no dependencies

### Wave 1

- **common_presentation** → depends on: common_shared
- **core_data** → depends on: common_shared, core_domain
- **core_navigation** → depends on: ui_foundation
- **demo_domain** → depends on: core_domain

### Wave 2

- **demo_data** → depends on: core_data, demo_domain
- **ui_components** → depends on: common_presentation, common_shared, processor, ui_foundation

### Wave 3

- **console_presentation** → depends on: common_presentation, common_shared, core_navigation, processor, ui_components, ui_foundation
- **demo_presentation** → depends on: core_navigation, demo_data, demo_domain, processor

### Wave 4

- **app** → depends on: common_presentation, common_shared, console_presentation, core_data, core_navigation, demo_presentation, ui_components, ui_foundation

## Unused Module Dependencies

The following modules declare workspace dependencies that are never imported:

- **demo_data** → core_data
- **demo_domain** → core_domain

_Detailed graphs are available under the `build_info/` directory._

