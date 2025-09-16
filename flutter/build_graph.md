# Flutter Module Dependency Graph

## Visual Representation

```mermaid
graph TD
    app["app
🌊 Wave 5"]
    processor["processor
🌊 Wave 0"]
    common_shared["common_shared
🌊 Wave 0"]
    common_shared:::common
    common_presentation["common_presentation
🌊 Wave 1"]
    common_presentation:::presentation
    core_data["core_data
🌊 Wave 2"]
    core_data:::data
    core_domain["core_domain
🌊 Wave 1"]
    core_domain:::domain
    demo_domain["demo_domain
🌊 Wave 2"]
    demo_domain:::domain
    demo_data["demo_data
🌊 Wave 3"]
    demo_data:::data
    demo_presentation["demo_presentation
🌊 Wave 4"]
    demo_presentation:::presentation
    foundation["foundation
🌊 Wave 1"]

    common_shared --> app
    common_presentation --> app
    core_domain --> app
    core_data --> app
    foundation --> app
    demo_presentation --> app
    common_shared --> common_presentation
    processor --> core_data
    common_shared --> core_data
    core_domain --> core_data
    processor --> core_domain
    common_shared --> core_domain
    core_domain --> demo_domain
    core_data --> demo_data
    demo_domain --> demo_data
    processor --> demo_presentation
    demo_domain --> demo_presentation
    demo_data --> demo_presentation
    processor --> foundation

    classDef presentation fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000000
    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000
    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000
    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000
    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000
    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000
```

## Build Statistics

- **Total Modules**: 10
- **Total Dependencies**: 19
- **Average Dependencies**: 1.90
- **Max Parallel Builds**: 8

## Build Waves

The modules will be built in the following waves:


### Wave 0

- **processor** → no dependencies
- **common_shared** → no dependencies

### Wave 1

- **common_presentation** → depends on: common_shared
- **core_domain** → depends on: processor, common_shared
- **foundation** → depends on: processor

### Wave 2

- **core_data** → depends on: processor, common_shared, core_domain
- **demo_domain** → depends on: core_domain

### Wave 3

- **demo_data** → depends on: core_data, demo_domain

### Wave 4

- **demo_presentation** → depends on: processor, demo_domain, demo_data

### Wave 5

- **app** → depends on: common_shared, common_presentation, core_domain, core_data, foundation, demo_presentation
