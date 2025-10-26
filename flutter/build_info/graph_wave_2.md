# Wave 2 Dependency Graph

Modules scheduled in wave 2 with their workspace dependencies.

```mermaid
graph LR
    common_shared["common_shared\n🌊 Wave 0"]
    common_shared:::common
    processor["processor\n🌊 Wave 0"]
    ui_foundation["ui_foundation\n🌊 Wave 0"]
    ui_foundation:::ui
    common_presentation["common_presentation\n🌊 Wave 1"]
    common_presentation:::common
    core_data["core_data\n🌊 Wave 1"]
    core_data:::core
    demo_domain["demo_domain\n🌊 Wave 1"]
    demo_domain:::domain
    class demo_domain unused;
    demo_data["demo_data\n🌊 Wave 2"]
    demo_data:::data
    class demo_data unused;
    class demo_data focus;
    ui_components["ui_components\n🌊 Wave 2"]
    ui_components:::ui
    class ui_components focus;

    %% Edge styling
    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35
    common_shared --> common_presentation
    common_shared --> core_data
    core_data --> demo_data
    demo_domain --> demo_data
    common_presentation --> ui_components
    common_shared --> ui_components
    processor --> ui_components
    ui_foundation --> ui_components

    linkStyle 0,1,4,5 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 2 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 3 stroke:#7b1fa2,stroke-width:1.9,opacity:0.9
    linkStyle 6 stroke:#546e7a,stroke-width:1.9,opacity:0.9
    linkStyle 7 stroke:#f57c00,stroke-width:1.9,opacity:0.9

    classDef domain fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000000
    classDef data fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000000
    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000
    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000
    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000
    classDef unused fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000000
    classDef focus fill:#fffde7,stroke:#fbc02d,stroke-width:2.5px,color:#000000
```

