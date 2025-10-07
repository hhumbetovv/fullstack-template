# Flutter Module Dependency Graph

## Visual Representation

```mermaid
graph TD
    app["app
🌊 Wave 4"]
    processor["processor
🌊 Wave 0"]
    common_shared["common_shared
🌊 Wave 0"]
    common_shared:::common
    common_presentation["common_presentation
🌊 Wave 1"]
    common_presentation:::presentation
    core_presentation["core_presentation
🚫 No build"]
    core_presentation:::presentation
    core_navigation["core_navigation
🌊 Wave 0"]
    core_navigation:::core
    core_data["core_data
🌊 Wave 1"]
    core_data:::data
    core_domain["core_domain
🚫 No build"]
    core_domain:::domain
    ui_foundation["ui_foundation
🚫 No build"]
    ui_foundation:::ui
    ui_components["ui_components
🌊 Wave 2"]
    ui_components:::ui
    console_presentation["console_presentation
🌊 Wave 3"]
    console_presentation:::presentation
    demo_domain["demo_domain
🌊 Wave 0"]
    demo_domain:::domain
    demo_data["demo_data
🌊 Wave 2"]
    demo_data:::data
    demo_presentation["demo_presentation
🌊 Wave 3"]
    demo_presentation:::presentation

    common_shared --> app
    common_presentation --> app
    core_data --> app
    core_presentation --> app
    core_navigation --> app
    ui_foundation --> app
    ui_components --> app
    console_presentation --> app
    demo_presentation --> app
    common_shared --> common_presentation
    processor --> core_presentation
    common_shared --> core_presentation
    common_presentation --> core_presentation
    core_domain --> core_presentation
    ui_foundation --> core_navigation
    common_shared --> core_data
    core_domain --> core_data
    processor --> ui_components
    common_presentation --> ui_components
    common_shared --> ui_components
    ui_foundation --> ui_components
    processor --> console_presentation
    core_presentation --> console_presentation
    core_navigation --> console_presentation
    common_shared --> console_presentation
    common_presentation --> console_presentation
    ui_foundation --> console_presentation
    ui_components --> console_presentation
    core_domain --> demo_domain
    core_data --> demo_data
    demo_domain --> demo_data
    processor --> demo_presentation
    core_presentation --> demo_presentation
    core_navigation --> demo_presentation
    demo_domain --> demo_presentation
    demo_data --> demo_presentation

    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000
    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000
    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000
    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000
    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000
```

## Build Statistics

- **Total Modules**: 14
- **Modules With build_runner**: 11
- **Modules Without build_runner**: 3
- **Total Dependencies**: 36
- **Average Dependencies**: 2.57
- **Max Parallel Builds**: 8

## Build Waves

The modules requiring build_runner will be built in the following waves:


### Wave 0

- **processor** → no dependencies
- **common_shared** → no dependencies
- **core_navigation** → no dependencies
- **demo_domain** → no dependencies

### Wave 1

- **common_presentation** → depends on: common_shared
- **core_data** → depends on: common_shared

### Wave 2

- **ui_components** → depends on: processor, common_presentation, common_shared
- **demo_data** → depends on: core_data, demo_domain

### Wave 3

- **console_presentation** → depends on: processor, core_navigation, common_shared, common_presentation, ui_components
- **demo_presentation** → depends on: processor, core_navigation, demo_domain, demo_data

### Wave 4

- **app** → depends on: common_shared, common_presentation, core_data, core_navigation, ui_components, console_presentation, demo_presentation

## Unused Modules

The following declared module dependencies appear unused (no `package:` import found):

- **demo_data** → unused: core_data
- **demo_domain** → unused: core_domain
