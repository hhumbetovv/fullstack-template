# Core Layer Graph

Core Layer modules with their workspace dependencies.

```mermaid
graph LR
    common_shared["common_shared\n🌊 Wave 0"]
    common_shared:::common
    core_domain["core_domain\n🌊 Wave 0"]
    core_domain:::core
    class core_domain focus;
    processor["processor\n🌊 Wave 0"]
    ui_foundation["ui_foundation\n🌊 Wave 0"]
    ui_foundation:::ui
    common_presentation["common_presentation\n🌊 Wave 1"]
    common_presentation:::common
    core_data["core_data\n🌊 Wave 1"]
    core_data:::core
    class core_data focus;
    core_navigation["core_navigation\n🌊 Wave 1"]
    core_navigation:::core
    class core_navigation focus;
    core_presentation["core_presentation\n🚫 No build"]
    core_presentation:::core
    class core_presentation focus;

    %% Edge styling
    linkStyle default stroke:#b0bec5,stroke-width:1,opacity:0.35
    common_shared --> common_presentation
    common_shared --> core_data
    core_domain --> core_data
    ui_foundation --> core_navigation
    common_presentation --> core_presentation
    common_shared --> core_presentation
    core_domain --> core_presentation
    processor --> core_presentation

    linkStyle 0,1,4,5 stroke:#c2185b,stroke-width:1.9,opacity:0.9
    linkStyle 2,6 stroke:#00695c,stroke-width:1.9,opacity:0.9
    linkStyle 3 stroke:#f57c00,stroke-width:1.9,opacity:0.9
    linkStyle 7 stroke:#546e7a,stroke-width:1.9,opacity:0.9

    classDef ui fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000000
    classDef common fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000000
    classDef core fill:#e0f2f1,stroke:#00695c,stroke-width:2px,color:#000000
    classDef focus fill:#fffde7,stroke:#fbc02d,stroke-width:2.5px,color:#000000
```

