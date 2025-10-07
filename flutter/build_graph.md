# Flutter Module Dependency Graph

## Visual Representation

```mermaid
graph LR
    common_shared["common_shared
🌊 Wave 0"]
    common_shared:::common
    core_navigation["core_navigation
🌊 Wave 0"]
    core_navigation:::core
    demo_domain["demo_domain
🌊 Wave 0"]
    demo_domain:::domain
    processor["processor
🌊 Wave 0"]
    common_presentation["common_presentation
🌊 Wave 1"]
    common_presentation:::common
    core_data["core_data
🌊 Wave 1"]
    core_data:::core
    demo_data["demo_data
🌊 Wave 2"]
    demo_data:::data
    ui_components["ui_components
🌊 Wave 2"]
    ui_components:::ui
    console_presentation["console_presentation
🌊 Wave 3"]
    console_presentation:::presentation
    demo_presentation["demo_presentation
🌊 Wave 3"]
    demo_presentation:::presentation
    app["app
🌊 Wave 4"]
    core_domain["core_domain
🚫 No build"]
    core_domain:::core
    core_presentation["core_presentation
🚫 No build"]
    core_presentation:::core
    ui_foundation["ui_foundation
🚫 No build"]
    ui_foundation:::ui

    %% Edge colours follow the target module category
    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35
    common_presentation --> app
    common_shared --> app
    console_presentation --> app
    core_data --> app
    core_navigation --> app
    core_presentation --> app
    demo_presentation --> app
    ui_components --> app
    ui_foundation --> app
    common_shared --> common_presentation
    common_presentation --> console_presentation
    common_shared --> console_presentation
    core_navigation --> console_presentation
    core_presentation --> console_presentation
    processor --> console_presentation
    ui_components --> console_presentation
    ui_foundation --> console_presentation
    common_shared --> core_data
    core_domain --> core_data
    ui_foundation --> core_navigation
    common_presentation --> core_presentation
    common_shared --> core_presentation
    core_domain --> core_presentation
    processor --> core_presentation
    core_data --> demo_data
    demo_domain --> demo_data
    core_domain --> demo_domain
    core_navigation --> demo_presentation
    core_presentation --> demo_presentation
    demo_data --> demo_presentation
    demo_domain --> demo_presentation
    processor --> demo_presentation
    common_presentation --> ui_components
    common_shared --> ui_components
    processor --> ui_components
    ui_foundation --> ui_components

    linkStyle 0 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 1 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 2 stroke:#0277bd,stroke-width:1.9,opacity:0.9
    linkStyle 3 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 4 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 5 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 6 stroke:#0277bd,stroke-width:1.9,opacity:0.9
    linkStyle 7 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 8 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 9 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 10 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 11 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 12 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 13 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 14 stroke:#546e7a,stroke-width:1.9,opacity:0.9
    linkStyle 15 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 16 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 17 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 18 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 19 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 20 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 21 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 22 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 23 stroke:#546e7a,stroke-width:1.9,opacity:0.9
    linkStyle 24 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 25 stroke:#7b1fa2,stroke-width:1.9,opacity:0.9
    linkStyle 26 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 27 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 28 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 29 stroke:#2e7d32,stroke-width:1.9,opacity:0.9
    linkStyle 30 stroke:#7b1fa2,stroke-width:1.9,opacity:0.9
    linkStyle 31 stroke:#546e7a,stroke-width:1.9,opacity:0.9
    linkStyle 32 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 33 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 34 stroke:#546e7a,stroke-width:1.9,opacity:0.9
    linkStyle 35 stroke:#f57c00,stroke-width:1.9,opacity:0.9

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
