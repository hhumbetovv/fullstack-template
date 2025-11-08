# Workspace Build Overview

## Quick Stats

- **Total Modules**: 16
- **Modules With build_runner**: 13
- **Modules Without build_runner**: 3
- **Total Dependencies**: 37
- **Average Dependencies**: 2.31
- **Peak Concurrent Modules**: 4
- **Configured Parallel Limit**: 4

## Graph Index

- [Foundation](build_info/foundation.md) — Highlights how shared modules feed feature delivery.
- [Features](build_info/features.md) — Focuses purely on feature-layer dependencies.
- [Waves](build_info/waves.md) — Visualizes build waves from top to bottom.
- [Module Groups](build_info/module_groups.md) — Clusters modules by architectural layer.

## Build Waves

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

- **demo_data** → core_data
- **demo_domain** → core_domain

_Detailed graphs are available under the `build_info/` directory._

