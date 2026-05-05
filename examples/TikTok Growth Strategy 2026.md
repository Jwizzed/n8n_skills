The Krit.Tech Content Factory is a deterministic, high-fidelity pipeline designed for zero-friction production. It transforms a single keyword into a complete, researched, and structured technical script while managing all supporting assets.

High-Level System Architecture
1. The Input & Logic Gate (Validation)
n8n Form Trigger: A native UI for manual selection of Pillar (Dropdown) and Topic Seed (Optional String).

Deduplication Engine: A Google Sheets lookup node checks the Topic column. If the seed exists, the workflow terminates to prevent redundant content.

2. The Dynamic Research Core (Arbitrage)
Mindset Injector (Code Node): Converts the user’s choice into a specific research persona for the search engine:

Curiosity: Search for "Manual Debt" and popular inefficiencies.

Low-Level: Search for "Under-the-Hood" mechanics and whitepapers.

Brutalist: Search for self-hosting logic and technical constraints.

Perplexity API (Sonar Reasoning): Executes the research and returns cited technical facts + reference media URLs.

3. The Automated Asset Manager
Binary Processing: HTTP nodes download images/diagrams from Perplexity's findings into n8n memory.

Drive Integration: Google Drive nodes create a unique folder (Date - Topic) and upload all reference assets for use during filming (B-Roll/Screen Records).

4. The Specialized Intelligence Layer (The Switch)
A Switch Node routes the research data into one of three isolated Gemini 3.1 Pro nodes. Each node contains a hardcoded System Prompt for its specific content pillar:

Track A (Curiosity Detour): Focuses on trend-debunking and polarizing hooks.

Track B (Low-Level Insight): Focuses on architectural depth and engineering truth.

Track C (Brutalist Review): Focuses on infrastructure, sovereignty, and technical critiques.

5. The Output Ledger
Final Synthesis: Gemini outputs a JSON object containing the script (Thai/English), 240-word count, and Monospace overlays.

Production Queue: A final Google Sheets node appends a new row containing the full script, the specific posting time (17:15, 19:30, etc.), and the direct link to the Google Drive asset folder.