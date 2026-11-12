# Flight activity (FA): literature extraction

Working document for pulling the individual values behind Kelsey et al. 2025 so FA can be recomputed for the species missing from our data sheet, following her approach (NFA and DFA -> FA_N&D; 24-hour values -> FA24; FA = mean of the two when both exist). Each header is one paper or data source from her FA reference stack.

## How to use this document

1. Work paper by paper. Read the paper, then fill in **Data collection**, **Metric**, and the **species table**.
2. **Record every individual value**, not a summary. Kelsey used the median, min, max and number of sources, which we can only recompute if the raw values are here.
3. Keep the species table in the exact column format below (pipe table, one row per species x metric x value), so an R script can read all the tables into one long data frame later. This document is the single source of truth.
4. Set the **Status** line: `[ ]` not read, `[~]` in progress, `[x]` done, `[-]` read, nothing usable.

**Metrics**

- **DFA**: proportion of daytime spent flying. **NFA**: proportion of night spent flying. **FA24**: proportion of a full 24-hour period spent flying (not split by day/night).
- Kelsey: FA_N&D = mean(median NFA, median DFA); FA24 = median of 24-hour values; FA = mean(FA_N&D, FA24) when both exist, otherwise whichever exists. She prioritized values from the latitudes and seasons the species occupies in the Pacific region. Where only partial day/night data existed she assumed 12 h day / 12 h night.
- For tracking and logger studies, note the **season/period** (breeding, non-breeding, migration), the **sex/stage**, and the **number of birds**.

**Species table columns:** `species | metric | value | period | n | uncertainty | where in paper`

- `value`: as a proportion (0-1). Convert percentages and hours, and note the conversion in the notes.
- `uncertainty`: SD, SE, CI or range as reported, with which one it is; `none` if not reported.
- `where in paper`: table/figure/page, so the value can be checked.
- The table is pre-filled with the species Kelsey cited the paper for and the same-genus leads. Delete rows that turn out not to apply; add rows for same-family leads you use or anything else the paper gives.

**Leads** are our species with no FA yet that share a genus (or, second, a family) with the species the paper actually studied (the donor species when Kelsey used it as a proxy, otherwise the species she cited it for). They are *places to look*, not confirmed coverage. "✓NPPSD" marks gap species that already have a usable NPPSD DFA ratio, so only NFA/FA24 would still be needed for them.

Donor species codes (e.g. COMU) are decoded by me from Kelsey's FA_Reference text and should be checked.

> ## >>> STOPPED HERE (2026-11-04) <<<
>
> **Done:** sources #1 Drew (NPPSD), #4 Bonnet-Lebrun, #5 Adams 2020, #6 Benvenuti, #7 Dunn, #9 Linnebjerg, #10 Rueda-Uribe (incl. supplement), #12 Dean. **Read, nothing usable:** #8 Carle. **Skipped by decision:** #2 Adams 2016, #3 Takekawa. **Duplicate:** #42 (same paper as #4).
>
> **Next up, in order of what it would unlock** (everything else in the Order of attack table is still `Not read`):
> 1. ~~Gull FA24 papers #20, #27, #34, #37~~ not needed: Kelsey's published gull values (other gulls 0.268; Herring Gull 0.15) are accepted as is.
> 2. #11 pers. comm. (Felis/Carle), #23 Cullen, #35 Stedman, #36 Stout and Nuechterlein: grebe NFA/DFA (Great Crested Grebe has nothing yet).
> 3. #13 Heinanen, #15 Paruk: loon NFA/DFA (Arctic Loon is DFA-only).
> 4. #22 Craik, #28 Pearce, #31 Robertson and Goudie, #32 Robertson and Savard: sea duck NFA (eiders, scoters, goldeneye, scaup are DFA-only).
> 5. #25 Gremillet and Wilson, #26 King, #33 Ryan: cormorants (3 gaps with nothing).
> 6. #17-19 Medrano and Militao (storm-petrels), #38 Weimerskirch (boobies), #14 Kato, #16 Jakubas, #24 Ewins (alcid refinements): lower priority.
>
> Open decisions: Manx DFA definition (Dean #12), whether to apply the tern value (0.38) to noddies and White Tern (currently yes, flagged), which NFA to use for alcids (Benvenuti 0.070 vs Kelsey's sheet 0.027).
>
> Where the filled values live: `EAAF_FA_gap_fill_v1.xlsx` (Gap_fill, Inputs and Summary tabs).

## Decisions made while filling this document

- **Phases are pooled for all species** (Bonnet-Lebrun and any other source that reports migration vs non-breeding values): every phase value is entered as its own row and all of them go into the median, as Kelsey did for Leach's Storm-petrel. This departs from Kelsey, who used non-breeding values only for shearwaters and Pterodroma and the spring/fall migration median for skuas and jaegers. Reason: many species pass through the EAAF at different points in the annual cycle, so no single phase should be assumed.
- **Herring Gull:** whichever form of Herring Gull a paper reports is used directly for Arctic Herring Gull (no flagged proxy needed). Same for NPPSD (HERG 0.594).
- **Trip types are pooled** (location-weighted) for tracking reports that split by trip type, e.g. Adams et al. 2020 NFA for Red-footed Booby = 0.169, not Kelsey's multiday-only 0.12. Rows marked POOLED are the ones to aggregate.
- **Gulls: Kelsey's published values are accepted as is** (0.268 for the other gulls, 0.15 Herring Gull for Arctic Herring Gull); the gull source papers (#20, 27, 34, 37) are not read.
- **NPPSD DFA for petrels is kept** alongside the Bonnet-Lebrun FA24 for any species passing the >100 birds check. With no NFA it does not enter FA_N&D, so FA = FA24 for those.
- **Uncertainty is left off for now** (no source counts or actual/similar-species scores in the gap-fill sheet).
- **Adams et al. 2016 and Takekawa et al. 2017 are skipped** (nothing beyond NPPSD for DFA).

## Order of attack

| # | Source | Type | Species Kelsey cited it for | Gap leads (genus / family) | Using? |
|---|---|---|---|---|---|
| 1 | Drew et al. 2005 | Survey data release | 34 | 19 / 27 | Yes (DFA) |
| 2 | Adams et al. 2016 | Survey data release | 23 | 9 / 27 | Skipped |
| 3 | Takekawa et al. 2017 | Survey data release | 23 | 9 / 27 | Skipped |
| 4 | Bonnet-Lebrun et al. 2021 | Journal article / other | 13 | 4 / 44 | Yes (FA24) |
| 5 | Adams et al. 2020 | Agency report | 10 | 2 / 18 | Yes (DFA, NFA) |
| 6 | Benvenuti et al. 2001 | Journal article / other | 7 | 0 / 8 | Yes (NFA proxy, alcids) |
| 7 | Dunn et al. 2020 | Journal article / other | 6 | 1 / 7 | Yes (FA24, alcids) |
| 8 | Carle et al. 2019 | Journal article / other | 5 | 1 / 16 | No (no FA data in paper) |
| 9 | Linnebjerg et al. 2015 | Journal article / other | 5 | 1 / 7 | Yes (FA24, Thick-billed Murre) |
| 10 | Rueda-Uribe et al. 2022 | Journal article / other | 4 | 0 / 28 | Yes (FA24, terns) |
| 11 | pers. comm. (Felis/Carle) | Personal communication | 4 | 1 / 0 | Not read **<- STOPPED HERE: next unread from #11 on** |
| 12 | Dean et al. 2013 | Journal article / other | 3 | 4 / 13 | Yes (DFA, Puffinus donor) |
| 13 | Heinanen et al. 2020 | Journal article / other | 3 | 1 / 0 | Not read |
| 14 | Kato et al. 2003 | Journal article / other | 3 | 0 / 8 | Not read |
| 15 | Paruk et al. 2008 | Journal article / other | 3 | 1 / 0 | Not read |
| 16 | Jakubas et al. 2014 | Journal article / other | 2 | 0 / 8 | Not read |
| 17 | Medrano et al. 2022 | Journal article / other | 2 | 3 / 0 | Not read |
| 18 | Medrano et al. 2024 | Journal article / other | 2 | 3 / 0 | Not read |
| 19 | Militao et al. 2022 | Journal article / other | 2 | 3 / 0 | Not read |
| 20 | Brown et al. 2023 | Journal article / other | 1 | 10 / 18 | Not needed (Kelsey gull values accepted) |
| 21 | Clay et al. 2017 | Journal article / other | 1 | 7 / 10 | Not read |
| 22 | Craik et al. 2020 | Birds of the World species account | 1 | 0 / 10 | Not read |
| 23 | Cullen et al. 2020 | Birds of the World species account | 1 | 1 / 0 | Not read |
| 24 | Ewins 2020 | Birds of the World species account | 1 | 1 / 7 | Not read |
| 25 | Gremillet and Wilson 1999 | Journal article / other | 1 | 2 / 1 | Not read |
| 26 | King et al. 1995 | Journal article / other | 1 | 0 / 3 | Not read |
| 27 | Park et al. 2024 | Journal article / other | 1 | 10 / 18 | Not needed (Kelsey gull values accepted) |
| 28 | Pearce et al. 2020 | Birds of the World species account | 1 | 0 / 10 | Not read |
| 29 | Raine et al. 2021 | Journal article / other | 1 | 3 / 14 | Not read |
| 30 | Ravache et al. 2020 | Journal article / other | 1 | 1 / 16 | Not read |
| 31 | Robertson and Goudie 2020 | Birds of the World species account | 1 | 0 / 10 | Not read |
| 32 | Robertson and Savard 2020 | Birds of the World species account | 1 | 0 / 10 | Not read |
| 33 | Ryan et al. 2009 | Journal article / other | 1 | 0 / 3 | Not read |
| 34 | Shaffer et al. 2017 | Journal article / other | 1 | 10 / 18 | Not needed (Kelsey gull values accepted) |
| 35 | Stedman 2020 | Birds of the World species account | 1 | 1 / 0 | Not read |
| 36 | Stout and Nuechterlein 2020 | Birds of the World species account | 1 | 1 / 0 | Not read |
| 37 | VanDonk et al. 2018 | Journal article / other | 1 | 10 / 18 | Not needed (Kelsey gull values accepted) |
| 38 | Weimerskirch et al. 2008 | Journal article / other | 1 | 1 / 2 | Not read |
| 39 | Potiek et al. 2019 | Journal article / other | 4 | 0 / 0 | Not read |
| 40 | Conners et al. 2015 | Journal article / other | 2 | 0 / 0 | Not read |
| 41 | Bemmelen et al. 2016 | Journal article / other | 1 | 0 / 0 | Not read |
| 42 | Bonnet-Lebrun et al. 2021 [as written: 2022] | Journal article / other | 1 | 0 / 0 | Dup of #4 |

---

## 1. Drew et al. 2005

**Full citation:** Drew, G.S., Schoen, S.K., Hood, M.D., Arimitsu, M.L., Piatt, J.F., 2005, North Pacific Pelagic Seabird Database (NPPSD) (ver. 4.1, May 2023): U.S. Geological Survey data release. [Available at: https://doi.org/10.5066/F7WQ01T3]

**Type:** Survey data release  
**Status:** `[x]` (DFA from NPPSD done; the values below are the NPPSD ones)

**Kelsey cited it for**
- Directly (30): Ancient Murrelet; Arctic/Parasitic Jaeger; Black-footed Albatross; Black-necked Grebe; Buller's Shearwater; Common Murre; Flesh-footed Shearwater; Goosander; Harlequin Duck; Horned Grebe; Horned Puffin; Laysan Albatross; Long-tailed Duck; Long-tailed Jaeger; Northern Fulmar; Pacific Loon; Parakeet Auklet; Pelagic Cormorant; Pigeon Guillemot; Pomarine Jaeger; Red-breasted Merganser; Red-necked Grebe; Red-necked Phalarope; Red-throated Loon; Rhinoceros Auklet; Short-tailed Shearwater; Sooty Shearwater; South Polar Skua; Tufted Puffin; Yellow-billed Loon
- As a similar-species source (4): Fork-tailed Storm-petrel, Hawaiian Petrel, Short-tailed Albatross, Wilson's Storm-petrel (donor not specified)

**Data collection:** at-sea seabird surveys compiled in NPPSD v4.1 (observation records linked to survey locations). We calculated the ratio ourselves with `nppsd_flying_ratio.R`: flying individuals / (flying + on-water individuals), summed over all records for a species. Records with behavior Land or Unknown are dropped. Counting methods (Continuous, Snapshot, Not Specified) are **pooled** to maximize sample size (see methods markdown, 5a). All seasons, years and regions are pooled; no seasonal or latitudinal filtering.

**Metric(s) addressed:** **DFA only.** The surveys were done in daylight, so these are daytime flying ratios. They say nothing about NFA or FA24.

**Filters applied to the table below:** more than 100 birds (flying + on water); not cormorants/shags, terns or noddies (Kelsey's land-time rule); seabirds only (species we might plausibly use as donors, so shorebirds, raptors, dabbling ducks and geese, swans, marine mammals and unidentified/genus-level/hybrid codes are removed). 102 species.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Ancient Murrelet (Synthliboramphus antiquus) | DFA | 0.243 | all seasons pooled | 66453 | none reported (counts only: 16181 flying, 50272 on water; 8921 records) | NPPSD flying-ratio output, species code ANMU |
| Black Guillemot (Cepphus grylle) | DFA | 0.458 | all seasons pooled | 3155 | none reported (counts only: 1444 flying, 1711 on water; 1038 records) | NPPSD flying-ratio output, species code BLGU |
| Cassin's Auklet (Ptychoramphus aleuticus) | DFA | 0.286 | all seasons pooled | 75191 | none reported (counts only: 21503 flying, 53688 on water; 11412 records) | NPPSD flying-ratio output, species code CAAU |
| Common Murre (Uria aalge) | DFA | 0.114 | all seasons pooled | 1248099 | none reported (counts only: 142796 flying, 1105303 on water; 89229 records) | NPPSD flying-ratio output, species code COMU |
| Crested Auklet (Aethia cristatella) | DFA | 0.532 | all seasons pooled | 553784 | none reported (counts only: 294611 flying, 259173 on water; 18059 records) | NPPSD flying-ratio output, species code CRAU |
| Craveri's Murrelet (Synthliboramphus craveri) | DFA | 0.205 | all seasons pooled | 132 | none reported (counts only: 27 flying, 105 on water; 65 records) | NPPSD flying-ratio output, species code CRMU |
| Dovekie (Alle alle) | DFA | 0.585 | all seasons pooled | 135 | none reported (counts only: 79 flying, 56 on water; 70 records) | NPPSD flying-ratio output, species code DOVE |
| Guadalupe Murrelet (Synthliboramphus hypoleucus) | DFA | 0.132 | all seasons pooled | 129 | none reported (counts only: 17 flying, 112 on water; 69 records) | NPPSD flying-ratio output, species code GUMU |
| Horned Puffin (Fratercula corniculata) | DFA | 0.330 | all seasons pooled | 95163 | none reported (counts only: 31400 flying, 63763 on water; 19535 records) | NPPSD flying-ratio output, species code HOPU |
| Kittlitz's Murrelet (Brachyramphus brevirostris) | DFA | 0.113 | all seasons pooled | 11306 | none reported (counts only: 1276 flying, 10030 on water; 2626 records) | NPPSD flying-ratio output, species code KIMU |
| Long-billed Murrelet (Brachyramphus perdix) | DFA | 0.000 | all seasons pooled | 207 | none reported (counts only: 0 flying, 207 on water; 28 records) | NPPSD flying-ratio output, species code LBMU |
| Least Auklet (Aethia pusilla) | DFA | 0.429 | all seasons pooled | 908833 | none reported (counts only: 390118 flying, 518715 on water; 20587 records) | NPPSD flying-ratio output, species code LEAU |
| Marbled Murrelet (Brachyramphus marmoratus) | DFA | 0.080 | all seasons pooled | 236462 | none reported (counts only: 19020 flying, 217442 on water; 33602 records) | NPPSD flying-ratio output, species code MAMU |
| Parakeet Auklet (Aethia psittacula) | DFA | 0.445 | all seasons pooled | 70208 | none reported (counts only: 31210 flying, 38998 on water; 13737 records) | NPPSD flying-ratio output, species code PAAU |
| Pigeon Guillemot (Cepphus columba) | DFA | 0.111 | all seasons pooled | 93676 | none reported (counts only: 10434 flying, 83242 on water; 20310 records) | NPPSD flying-ratio output, species code PIGU |
| Rhinoceros Auklet (Cerorhinca monocerata) | DFA | 0.318 | all seasons pooled | 50597 | none reported (counts only: 16069 flying, 34528 on water; 10755 records) | NPPSD flying-ratio output, species code RHAU |
| Scripps's Murrelet (Synthliboramphus scrippsi) | DFA | 0.111 | all seasons pooled | 162 | none reported (counts only: 18 flying, 144 on water; 81 records) | NPPSD flying-ratio output, species code SCMU |
| Spectacled Guillemot (Cepphus carbo) | DFA | 0.001 | all seasons pooled | 2228 | none reported (counts only: 2 flying, 2226 on water; 21 records) | NPPSD flying-ratio output, species code SPGU |
| Thick-billed Murre (Uria lomvia) | DFA | 0.463 | all seasons pooled | 171683 | none reported (counts only: 79481 flying, 92202 on water; 36451 records) | NPPSD flying-ratio output, species code TBMU |
| Tufted Puffin (Fratercula cirrhata) | DFA | 0.378 | all seasons pooled | 402640 | none reported (counts only: 152045 flying, 250595 on water; 52363 records) | NPPSD flying-ratio output, species code TUPU |
| Whiskered Auklet (Aethia pygmaea) | DFA | 0.177 | all seasons pooled | 74414 | none reported (counts only: 13136 flying, 61278 on water; 1361 records) | NPPSD flying-ratio output, species code WHAU |
| Xantus's Murrelet (Synthliboramphus hypoleucus) | DFA | 0.163 | all seasons pooled | 552 | none reported (counts only: 90 flying, 462 on water; 284 records) | NPPSD flying-ratio output, species code XAMU |
| Arctic Loon (Gavia arctica) | DFA | 0.014 | all seasons pooled | 212 | none reported (counts only: 3 flying, 209 on water; 20 records) | NPPSD flying-ratio output, species code ARLO |
| Common Loon (Gavia immer) | DFA | 0.151 | all seasons pooled | 9248 | none reported (counts only: 1393 flying, 7855 on water; 4298 records) | NPPSD flying-ratio output, species code COLO |
| Pacific Loon (Gavia pacifica) | DFA | 0.419 | all seasons pooled | 23463 | none reported (counts only: 9837 flying, 13626 on water; 7076 records) | NPPSD flying-ratio output, species code PALO |
| Red-throated Loon (Gavia stellata) | DFA | 0.361 | all seasons pooled | 2681 | none reported (counts only: 968 flying, 1713 on water; 1274 records) | NPPSD flying-ratio output, species code RTLO |
| Yellow-billed Loon (Gavia adamsii) | DFA | 0.398 | all seasons pooled | 1004 | none reported (counts only: 400 flying, 604 on water; 682 records) | NPPSD flying-ratio output, species code YBLO |
| Eared Grebe (Podiceps nigricollis) | DFA | 0.065 | all seasons pooled | 278 | none reported (counts only: 18 flying, 260 on water; 133 records) | NPPSD flying-ratio output, species code EAGR |
| Horned Grebe (Podiceps auritus) | DFA | 0.052 | all seasons pooled | 9863 | none reported (counts only: 514 flying, 9349 on water; 2300 records) | NPPSD flying-ratio output, species code HOGR |
| Red-necked Grebe (Podiceps grisegena) | DFA | 0.040 | all seasons pooled | 7832 | none reported (counts only: 310 flying, 7522 on water; 2680 records) | NPPSD flying-ratio output, species code RNGR |
| Clark's Grebe (Aechmophorus clarkii) | DFA | 0.000 | all seasons pooled | 252 | none reported (counts only: 0 flying, 252 on water; 78 records) | NPPSD flying-ratio output, species code CLGR |
| Western Grebe (Aechmophorus occidentalis) | DFA | 0.004 | all seasons pooled | 31190 | none reported (counts only: 139 flying, 31051 on water; 2661 records) | NPPSD flying-ratio output, species code WEGR |
| Black Scoter (Melanitta americana) | DFA | 0.087 | all seasons pooled | 64311 | none reported (counts only: 5570 flying, 58741 on water; 2954 records) | NPPSD flying-ratio output, species code BLSC |
| Common Eider (Somateria mollissima) | DFA | 0.588 | all seasons pooled | 23710 | none reported (counts only: 13934 flying, 9776 on water; 967 records) | NPPSD flying-ratio output, species code COEI |
| Common Goldeneye (Bucephala clangula) | DFA | 0.135 | all seasons pooled | 2612 | none reported (counts only: 352 flying, 2260 on water; 403 records) | NPPSD flying-ratio output, species code COGO |
| Common Merganser (Mergus merganser) | DFA | 0.189 | all seasons pooled | 38000 | none reported (counts only: 7177 flying, 30823 on water; 2792 records) | NPPSD flying-ratio output, species code COME |
| Red-breasted Merganser (Mergus serrator) | DFA | 0.210 | all seasons pooled | 17413 | none reported (counts only: 3665 flying, 13748 on water; 2573 records) | NPPSD flying-ratio output, species code RBME |
| Harlequin Duck (Histrionicus histrionicus) | DFA | 0.132 | all seasons pooled | 118628 | none reported (counts only: 15623 flying, 103005 on water; 8542 records) | NPPSD flying-ratio output, species code HADU |
| King Eider (Somateria spectabilis) | DFA | 0.741 | all seasons pooled | 93383 | none reported (counts only: 69162 flying, 24221 on water; 1178 records) | NPPSD flying-ratio output, species code KIEI |
| Long-tailed Duck (Clangula hyemalis) | DFA | 0.158 | all seasons pooled | 659518 | none reported (counts only: 104001 flying, 555517 on water; 7500 records) | NPPSD flying-ratio output, species code LTDU |
| Spectacled Eider (Somateria fischeri) | DFA | 0.286 | all seasons pooled | 163919 | none reported (counts only: 46957 flying, 116962 on water; 264 records) | NPPSD flying-ratio output, species code SPEI |
| Steller's Eider (Polysticta stelleri) | DFA | 0.048 | all seasons pooled | 6214 | none reported (counts only: 300 flying, 5914 on water; 237 records) | NPPSD flying-ratio output, species code STEI |
| Surf Scoter (Melanitta perspicillata) | DFA | 0.089 | all seasons pooled | 167325 | none reported (counts only: 14836 flying, 152489 on water; 5929 records) | NPPSD flying-ratio output, species code SUSC |
| White-winged Scoter (Melanitta deglandi) | DFA | 0.098 | all seasons pooled | 130799 | none reported (counts only: 12797 flying, 118002 on water; 7543 records) | NPPSD flying-ratio output, species code WWSC |
| Greater Scaup (Aythya marila) | DFA | 0.083 | all seasons pooled | 5526 | none reported (counts only: 460 flying, 5066 on water; 253 records) | NPPSD flying-ratio output, species code GRSC |
| Barrow's Goldeneye (Bucephala islandica) | DFA | 0.079 | all seasons pooled | 62411 | none reported (counts only: 4939 flying, 57472 on water; 3176 records) | NPPSD flying-ratio output, species code BAGO |
| Bufflehead (Bucephala albeola) | DFA | 0.084 | all seasons pooled | 17106 | none reported (counts only: 1430 flying, 15676 on water; 1226 records) | NPPSD flying-ratio output, species code BUFF |
| Black-footed Albatross (Phoebastria nigripes) | DFA | 0.642 | all seasons pooled | 28967 | none reported (counts only: 18590 flying, 10377 on water; 15626 records) | NPPSD flying-ratio output, species code BFAL |
| Laysan Albatross (Phoebastria immutabilis) | DFA | 0.652 | all seasons pooled | 21185 | none reported (counts only: 13822 flying, 7363 on water; 12289 records) | NPPSD flying-ratio output, species code LAAL |
| Short-tailed Albatross (Phoebastria albatrus) | DFA | 0.777 | all seasons pooled | 256 | none reported (counts only: 199 flying, 57 on water; 228 records) | NPPSD flying-ratio output, species code STAL |
| Northern Fulmar (Fulmarus glacialis) | DFA | 0.539 | all seasons pooled | 1013883 | none reported (counts only: 546364 flying, 467519 on water; 120517 records) | NPPSD flying-ratio output, species code NOFU |
| Buller's Shearwater (Ardenna bulleri) | DFA | 0.470 | all seasons pooled | 9574 | none reported (counts only: 4504 flying, 5070 on water; 1913 records) | NPPSD flying-ratio output, species code BULS |
| Flesh-footed Shearwater (Ardenna carneipes) | DFA | 0.690 | all seasons pooled | 168 | none reported (counts only: 116 flying, 52 on water; 119 records) | NPPSD flying-ratio output, species code FFSH |
| Pink-footed Shearwater (Ardenna creatopus) | DFA | 0.417 | all seasons pooled | 28382 | none reported (counts only: 11827 flying, 16555 on water; 7246 records) | NPPSD flying-ratio output, species code PFSH |
| Sooty Shearwater (Ardenna grisea) | DFA | 0.257 | all seasons pooled | 1457299 | none reported (counts only: 374236 flying, 1083063 on water; 34498 records) | NPPSD flying-ratio output, species code SOSH |
| Short-tailed Shearwater (Ardenna tenuirostris) | DFA | 0.403 | all seasons pooled | 2512675 | none reported (counts only: 1013311 flying, 1499364 on water; 34624 records) | NPPSD flying-ratio output, species code STSH |
| Streaked Shearwater (Calonectris leucomelas) | DFA | 0.658 | all seasons pooled | 89895 | none reported (counts only: 59135 flying, 30760 on water; 1257 records) | NPPSD flying-ratio output, species code STRS |
| Wedge-tailed Shearwater (Ardenna pacifica) | DFA | 0.656 | all seasons pooled | 1440 | none reported (counts only: 945 flying, 495 on water; 239 records) | NPPSD flying-ratio output, species code WTSH |
| Black-vented Shearwater (Puffinus opisthomelas) | DFA | 0.357 | all seasons pooled | 27471 | none reported (counts only: 9804 flying, 17667 on water; 1927 records) | NPPSD flying-ratio output, species code BVSH |
| Bonin Petrel (Pterodroma hypoleuca) | DFA | 0.715 | all seasons pooled | 621 | none reported (counts only: 444 flying, 177 on water; 335 records) | NPPSD flying-ratio output, species code BOPE |
| Black-winged Petrel (Pterodroma nigripennis) | DFA | 0.924 | all seasons pooled | 105 | none reported (counts only: 97 flying, 8 on water; 75 records) | NPPSD flying-ratio output, species code BWPE |
| Bulwer's Petrel (Bulweria bulwerii) | DFA | 0.966 | all seasons pooled | 148 | none reported (counts only: 143 flying, 5 on water; 116 records) | NPPSD flying-ratio output, species code BUPE |
| Cook's Petrel (Pterodroma cookii) | DFA | 0.737 | all seasons pooled | 4331 | none reported (counts only: 3192 flying, 1139 on water; 2160 records) | NPPSD flying-ratio output, species code COPE |
| Hawaiian Petrel (Pterodroma sandwichensis) | DFA | 0.707 | all seasons pooled | 116 | none reported (counts only: 82 flying, 34 on water; 74 records) | NPPSD flying-ratio output, species code HAPE |
| Mottled Petrel (Pterodroma inexpectata) | DFA | 0.709 | all seasons pooled | 8898 | none reported (counts only: 6307 flying, 2591 on water; 3810 records) | NPPSD flying-ratio output, species code MOPE |
| Murphy's Petrel (Pterodroma ultima) | DFA | 0.920 | all seasons pooled | 439 | none reported (counts only: 404 flying, 35 on water; 380 records) | NPPSD flying-ratio output, species code MUPE |
| Pycroft's Petrel (Pterodroma pycrofti) | DFA | 0.769 | all seasons pooled | 147 | none reported (counts only: 113 flying, 34 on water; 100 records) | NPPSD flying-ratio output, species code PYPE |
| Solander's Petrel (Pterodroma solandri) | DFA | 0.879 | all seasons pooled | 637 | none reported (counts only: 560 flying, 77 on water; 350 records) | NPPSD flying-ratio output, species code SOPE |
| Stejneger's Petrel (Pterodroma longirostris) | DFA | 0.621 | all seasons pooled | 385 | none reported (counts only: 239 flying, 146 on water; 190 records) | NPPSD flying-ratio output, species code STPE |
| Ashy Storm-Petrel (Hydrobates homochroa) | DFA | 0.909 | all seasons pooled | 1474 | none reported (counts only: 1340 flying, 134 on water; 309 records) | NPPSD flying-ratio output, species code ASSP |
| Black Storm-Petrel (Hydrobates melania) | DFA | 0.904 | all seasons pooled | 1746 | none reported (counts only: 1578 flying, 168 on water; 706 records) | NPPSD flying-ratio output, species code BLSP |
| Band-rumped Storm-Petrel (Hydrobates castro) | DFA | 0.714 | all seasons pooled | 266 | none reported (counts only: 190 flying, 76 on water; 92 records) | NPPSD flying-ratio output, species code BRSP |
| Fork-tailed Storm-Petrel (Hydrobates furcatus) | DFA | 0.624 | all seasons pooled | 335027 | none reported (counts only: 208953 flying, 126074 on water; 45964 records) | NPPSD flying-ratio output, species code FTSP |
| Leach's Storm-Petrel (Hydrobates leucorhous) | DFA | 0.821 | all seasons pooled | 69953 | none reported (counts only: 57449 flying, 12504 on water; 25388 records) | NPPSD flying-ratio output, species code LESP |
| Least Storm-Petrel (Hydrobates microsoma) | DFA | 0.712 | all seasons pooled | 379 | none reported (counts only: 270 flying, 109 on water; 135 records) | NPPSD flying-ratio output, species code LTSP |
| Tristram's Storm-Petrel (Hydrobates tristrami) | DFA | 0.701 | all seasons pooled | 204 | none reported (counts only: 143 flying, 61 on water; 128 records) | NPPSD flying-ratio output, species code TRSP |
| Black-legged Kittiwake (Rissa tridactyla) | DFA | 0.486 | all seasons pooled | 683220 | none reported (counts only: 332078 flying, 351142 on water; 88390 records) | NPPSD flying-ratio output, species code BLKI |
| Bonaparte's Gull (Chroicocephalus philadelphia) | DFA | 0.310 | all seasons pooled | 17540 | none reported (counts only: 5430 flying, 12110 on water; 1610 records) | NPPSD flying-ratio output, species code BOGU |
| California Gull (Larus californicus) | DFA | 0.503 | all seasons pooled | 46449 | none reported (counts only: 23375 flying, 23074 on water; 9110 records) | NPPSD flying-ratio output, species code CAGU |
| Glaucous Gull (Larus hyperboreus) | DFA | 0.659 | all seasons pooled | 81432 | none reported (counts only: 53676 flying, 27756 on water; 11797 records) | NPPSD flying-ratio output, species code GLGU |
| Glaucous-winged Gull (Larus glaucescens) | DFA | 0.407 | all seasons pooled | 338657 | none reported (counts only: 137869 flying, 200788 on water; 51941 records) | NPPSD flying-ratio output, species code GWGU |
| Heermann's Gull (Larus heermanni) | DFA | 0.121 | all seasons pooled | 7676 | none reported (counts only: 925 flying, 6751 on water; 1931 records) | NPPSD flying-ratio output, species code HEEG |
| Herring gull (Larus argentatus) | DFA | 0.594 | all seasons pooled | 14969 | none reported (counts only: 8885 flying, 6084 on water; 7123 records) | NPPSD flying-ratio output, species code HERG |
| Ivory Gull (Pagophila eburnea) | DFA | 0.811 | all seasons pooled | 1152 | none reported (counts only: 934 flying, 218 on water; 371 records) | NPPSD flying-ratio output, species code IVGU |
| Ring-billed Gull (Larus delawarensis) | DFA | 0.304 | all seasons pooled | 853 | none reported (counts only: 259 flying, 594 on water; 366 records) | NPPSD flying-ratio output, species code RBGU |
| Red-legged Kittiwake (Rissa brevirostris) | DFA | 0.882 | all seasons pooled | 26109 | none reported (counts only: 23040 flying, 3069 on water; 6588 records) | NPPSD flying-ratio output, species code RLKI |
| Ross's Gull (Rhodostethia rosea) | DFA | 0.648 | all seasons pooled | 10644 | none reported (counts only: 6894 flying, 3750 on water; 599 records) | NPPSD flying-ratio output, species code ROGU |
| Sabine's Gull (Xema sabini) | DFA | 0.652 | all seasons pooled | 15355 | none reported (counts only: 10018 flying, 5337 on water; 2697 records) | NPPSD flying-ratio output, species code SAGU |
| Slaty-backed Gull (Larus schistisagus) | DFA | 0.649 | all seasons pooled | 1677 | none reported (counts only: 1088 flying, 589 on water; 894 records) | NPPSD flying-ratio output, species code SBGU |
| Short-billed Gull (Larus brachyrhynchus) | DFA | 0.331 | all seasons pooled | 58858 | none reported (counts only: 19466 flying, 39392 on water; 10864 records) | NPPSD flying-ratio output, species code SBIG |
| Thayer's Gull (Larus glaucoides thayeri) | DFA | 0.444 | all seasons pooled | 671 | none reported (counts only: 298 flying, 373 on water; 348 records) | NPPSD flying-ratio output, species code THGU |
| Western Gull (Larus occidentalis) | DFA | 0.511 | all seasons pooled | 60677 | none reported (counts only: 31012 flying, 29665 on water; 23634 records) | NPPSD flying-ratio output, species code WEGU |
| Long-tailed Jaeger (Stercorarius longicaudus) | DFA | 0.845 | all seasons pooled | 2698 | none reported (counts only: 2280 flying, 418 on water; 1773 records) | NPPSD flying-ratio output, species code LTJA |
| Parasitic Jaeger (Stercorarius parasiticus) | DFA | 0.733 | all seasons pooled | 4467 | none reported (counts only: 3275 flying, 1192 on water; 3404 records) | NPPSD flying-ratio output, species code PAJA |
| Pomarine Jaeger (Stercorarius pomarinus) | DFA | 0.758 | all seasons pooled | 12709 | none reported (counts only: 9629 flying, 3080 on water; 8178 records) | NPPSD flying-ratio output, species code POJA |
| South Polar Skua (Stercorarius maccormicki) | DFA | 0.610 | all seasons pooled | 484 | none reported (counts only: 295 flying, 189 on water; 380 records) | NPPSD flying-ratio output, species code SPSK |
| Red Phalarope (Phalaropus fulicarius) | DFA | 0.399 | all seasons pooled | 154484 | none reported (counts only: 61635 flying, 92849 on water; 11035 records) | NPPSD flying-ratio output, species code REPH |
| Red-necked Phalarope (Phalaropus lobatus) | DFA | 0.248 | all seasons pooled | 153844 | none reported (counts only: 38177 flying, 115667 on water; 8245 records) | NPPSD flying-ratio output, species code RNPH |
| Red-Billed Tropicbird (Phaethon aethereus) | DFA | 0.548 | all seasons pooled | 166 | none reported (counts only: 91 flying, 75 on water; 152 records) | NPPSD flying-ratio output, species code RBTR |
| Red-tailed Tropicbird (Phaethon rubricauda) | DFA | 0.768 | all seasons pooled | 125 | none reported (counts only: 96 flying, 29 on water; 93 records) | NPPSD flying-ratio output, species code RTTR |
| Brown Booby (Sula leucogaster) | DFA | 0.224 | all seasons pooled | 442 | none reported (counts only: 99 flying, 343 on water; 74 records) | NPPSD flying-ratio output, species code BRBO |
| Red-Footed Booby (Sula sula) | DFA | 0.542 | all seasons pooled | 201 | none reported (counts only: 109 flying, 92 on water; 61 records) | NPPSD flying-ratio output, species code RFBO |

**Coverage of our data sheet (v1.3).**
- **Gap species with a value here (25):** Crested Auklet; Kittlitz's Murrelet; Long-billed Murrelet; Least Auklet; Spectacled Guillemot; Thick-billed Murre; Whiskered Auklet; Arctic Loon; Black Scoter; Common Eider; Common Goldeneye; King Eider; Spectacled Eider; Steller's Eider; Greater Scaup; Streaked Shearwater; Wedge-tailed Shearwater; Bonin Petrel; Black-winged Petrel; Bulwer's Petrel; Solander's Petrel; Tristram's Storm-Petrel; Glaucous Gull; Slaty-backed Gull; Brown Booby.
- **Already have FA in our sheet (36):** Ancient Murrelet; Common Murre; Horned Puffin; Parakeet Auklet; Pigeon Guillemot; Rhinoceros Auklet; Tufted Puffin; Pacific Loon; Red-throated Loon; Yellow-billed Loon; Eared Grebe; Horned Grebe; Red-necked Grebe; Common Merganser; Red-breasted Merganser; Harlequin Duck; Long-tailed Duck; Black-footed Albatross; Laysan Albatross; Short-tailed Albatross; Northern Fulmar; Buller's Shearwater; Flesh-footed Shearwater; Sooty Shearwater; Short-tailed Shearwater; Hawaiian Petrel; Fork-tailed Storm-Petrel; Leach's Storm-Petrel; Black-legged Kittiwake; Glaucous-winged Gull; Long-tailed Jaeger; Parasitic Jaeger; Pomarine Jaeger; Red-necked Phalarope; Red-tailed Tropicbird; Red-Footed Booby. Useful for comparing with Kelsey's DFA.
- **Not in our sheet (donor candidates only, 41):** Black Guillemot; Cassin's Auklet; Craveri's Murrelet; Dovekie; Guadalupe Murrelet; Marbled Murrelet; Scripps's Murrelet; Xantus's Murrelet; Common Loon; Clark's Grebe; Western Grebe; Surf Scoter; White-winged Scoter; Barrow's Goldeneye; Bufflehead; Pink-footed Shearwater; Black-vented Shearwater; Cook's Petrel; Mottled Petrel; Murphy's Petrel; Pycroft's Petrel; Stejneger's Petrel; Ashy Storm-Petrel; Black Storm-Petrel; Band-rumped Storm-Petrel; Least Storm-Petrel; Bonaparte's Gull; California Gull; Heermann's Gull; Herring gull; Ivory Gull; Ring-billed Gull; Red-legged Kittiwake; Ross's Gull; Sabine's Gull; Short-billed Gull; Thayer's Gull; Western Gull; South Polar Skua; Red Phalarope; Red-Billed Tropicbird.

**Notes**
- Brown Pelican (BRPE) passes the filters but was left out as it is not in our seabird list; add it back if a pelican donor is wanted.
- Genus/family-level codes (e.g. Brachyramphus Murrelet, Unidentified Shearwater) are excluded, but are available in the CSV if wanted as proxies.
- A few values rest on small samples or look odd, and are worth a second look before use: Arctic Loon (0.014, 212 birds), Long-billed Murrelet (0.000, 207 birds), Spectacled Guillemot (0.001, 2,228 birds, only 2 flying).
- Bufflehead and Barrow's Goldeneye were kept as sea-duck donors (*Bucephala*, same genus as our Common Goldeneye); remove if you would rather not.
- The land-time flag in the earlier version of the output CSV wrongly caught any name ending in "tern", including "Western" (Western Gull, Western Grebe). That is fixed in `nppsd_flying_ratio.R`; this table applies the corrected rule. Re-run the script to get a clean CSV.
- Uncertainty: NPPSD gives counts, not an error estimate, so none is reported here.

---

## 2. Adams et al. 2016

**Full citation:** Adams, J., Felis, J.J., Mason, J.W., and Takekawa, J.Y., 2016, Pacific Continental Shelf Environmental Assessment (PaCSEA): aerial seabird and marine mammal surveys off northern California, Oregon, and Washington, 2011-2012. GIS Resource Database: U.S. Geological Survey data release. [Available at: http://dx.doi.org/10.5066/F7668B7V]

**Type:** Survey data release  
**Status:** `[-]` SKIPPED (decision: not worth adding for DFA beyond NPPSD; the only gap species in its species list are Velvet Scoter and Arctic Herring Gull, and NPPSD already provides close proxies. Record this in EAAF_methods_and_decisions.md.)

**Kelsey cited it for**
- Directly (17): Ancient Murrelet; Black-footed Albatross; Black-necked Grebe; Buller's Shearwater; Common Murre; Flesh-footed Shearwater; Horned Grebe; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Pomarine Jaeger; Red-necked Grebe; Red-necked Phalarope; Red-throated Loon; Rhinoceros Auklet; Sooty Shearwater; Yellow-billed Loon
- As a similar-species source (6): Arctic/Parasitic Jaeger (donor not specified); Fork-tailed Storm-petrel (donor not specified); Long-tailed Jaeger (donor not specified); Short-tailed Albatross (donor not specified); South Polar Skua (donor not specified); Wilson's Storm-petrel (donor not specified)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*); Arctic Loon (*Gavia arctica*) ✓NPPSD; Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD; Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD
- Same family (27): White-faced Storm-petrel (*Pelagodroma marina*); Black-bellied Storm-petrel (*Fregetta tropica*); New Caledonian Storm-petrel (*Fregetta lineata*); White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD; Little Pied Cormorant (*Microcarbo melanoleucos*); Great Cormorant (*Phalacrocorax carbo*); Japanese Cormorant (*Phalacrocorax capillatus*); Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; +2 more

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Ancient Murrelet (Kelsey: direct) |  |  |  |  |  |  |
| Black-footed Albatross (Kelsey: direct) |  |  |  |  |  |  |
| Black-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Buller's Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Common Murre (Kelsey: direct) |  |  |  |  |  |  |
| Flesh-footed Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Horned Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Pacific Loon (Kelsey: direct) |  |  |  |  |  |  |
| Pelagic Cormorant (Kelsey: direct) |  |  |  |  |  |  |
| Pigeon Guillemot (Kelsey: direct) |  |  |  |  |  |  |
| Pomarine Jaeger (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Phalarope (Kelsey: direct) |  |  |  |  |  |  |
| Red-throated Loon (Kelsey: direct) |  |  |  |  |  |  |
| Rhinoceros Auklet (Kelsey: direct) |  |  |  |  |  |  |
| Sooty Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Yellow-billed Loon (Kelsey: direct) |  |  |  |  |  |  |
| Arctic/Parasitic Jaeger (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Fork-tailed Storm-petrel (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Long-tailed Jaeger (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Short-tailed Albatross (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| South Polar Skua (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Wilson's Storm-petrel (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |
| Arctic Loon (lead) |  |  |  |  |  |  |
| Matsudaira's Storm-petrel (lead) |  |  |  |  |  |  |
| Swinhoe's Storm-petrel (lead) |  |  |  |  |  |  |
| Tristram's Storm-petrel (lead) |  |  |  |  |  |  |
| Wedge-tailed Shearwater (lead) |  |  |  |  |  |  |
| Spectacled Guillemot (lead) |  |  |  |  |  |  |
| Japanese Murrelet (lead) |  |  |  |  |  |  |
| Thick-billed Murre (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 3. Takekawa et al. 2017

**Full citation:** Takekawa, J.Y., Perry, W.M., Adams, J., Felis, J.J., Williams, L.L, Yee, J.L., Orthmeyer, D.L., Mason, J.W., McChesney, G.J., McIver, W.R., Carter, H.R., and Golightly, R.T., 2017, At-Sea Distribution and Abundance of Seabirds and Marine Mammals off Southern California GIS Resource Database: Aerial seabird and marine mammal surveys off southern California, 1999-2002, GIS Resource Database: U.S. Geological Survey data release. [Available at: https://doi.org/10.5066/F7PK0D9P]

**Type:** Survey data release  
**Status:** `[-]` SKIPPED (decision: not worth adding for DFA beyond NPPSD; the only gap species in its species list are Velvet Scoter and Arctic Herring Gull, and NPPSD already provides close proxies. Record this in EAAF_methods_and_decisions.md.)

**Kelsey cited it for**
- Directly (17): Ancient Murrelet; Black-footed Albatross; Black-necked Grebe; Buller's Shearwater; Common Murre; Flesh-footed Shearwater; Horned Grebe; Pacific Loon; Pelagic Cormorant; Pigeon Guillemot; Pomarine Jaeger; Red-necked Grebe; Red-necked Phalarope; Red-throated Loon; Rhinoceros Auklet; Sooty Shearwater; Yellow-billed Loon
- As a similar-species source (6): Arctic/Parasitic Jaeger (donor not specified); Fork-tailed Storm-petrel (donor not specified); Long-tailed Jaeger (donor not specified); Short-tailed Albatross (donor not specified); South Polar Skua (donor not specified); Wilson's Storm-petrel (donor not specified)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*); Arctic Loon (*Gavia arctica*) ✓NPPSD; Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD; Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD
- Same family (27): White-faced Storm-petrel (*Pelagodroma marina*); Black-bellied Storm-petrel (*Fregetta tropica*); New Caledonian Storm-petrel (*Fregetta lineata*); White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD; Little Pied Cormorant (*Microcarbo melanoleucos*); Great Cormorant (*Phalacrocorax carbo*); Japanese Cormorant (*Phalacrocorax capillatus*); Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; +2 more

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Ancient Murrelet (Kelsey: direct) |  |  |  |  |  |  |
| Black-footed Albatross (Kelsey: direct) |  |  |  |  |  |  |
| Black-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Buller's Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Common Murre (Kelsey: direct) |  |  |  |  |  |  |
| Flesh-footed Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Horned Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Pacific Loon (Kelsey: direct) |  |  |  |  |  |  |
| Pelagic Cormorant (Kelsey: direct) |  |  |  |  |  |  |
| Pigeon Guillemot (Kelsey: direct) |  |  |  |  |  |  |
| Pomarine Jaeger (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Phalarope (Kelsey: direct) |  |  |  |  |  |  |
| Red-throated Loon (Kelsey: direct) |  |  |  |  |  |  |
| Rhinoceros Auklet (Kelsey: direct) |  |  |  |  |  |  |
| Sooty Shearwater (Kelsey: direct) |  |  |  |  |  |  |
| Yellow-billed Loon (Kelsey: direct) |  |  |  |  |  |  |
| Arctic/Parasitic Jaeger (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Fork-tailed Storm-petrel (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Long-tailed Jaeger (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Short-tailed Albatross (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| South Polar Skua (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Wilson's Storm-petrel (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |
| Arctic Loon (lead) |  |  |  |  |  |  |
| Matsudaira's Storm-petrel (lead) |  |  |  |  |  |  |
| Swinhoe's Storm-petrel (lead) |  |  |  |  |  |  |
| Tristram's Storm-petrel (lead) |  |  |  |  |  |  |
| Wedge-tailed Shearwater (lead) |  |  |  |  |  |  |
| Spectacled Guillemot (lead) |  |  |  |  |  |  |
| Japanese Murrelet (lead) |  |  |  |  |  |  |
| Thick-billed Murre (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 4. Bonnet-Lebrun et al. 2021

**Full citation:** Bonnet-Lebrun, A.-S., Dias, M.P., Phillips, R.A., Granadeiro, J.P., Brooke, M.d.L., Chastel, O., Clay, T.A., Fayet, A.L., Gilg, O., González-Solís, J., Guilford, T., Hanssen, S.A., Hedd, A., Jaeger, A., Krietsch, J., Lang, J., Le Corre, M., Militão, T., Moe, B., Montevecchi, W.A., Peter, H.-U., Pinet, P., Rayner, M.J., Reid, T., Reyes-González, J.M., Ryan, P.G., Sagar, P.M., Schmidt, N.M., Thompson, D.R., van Bemmelen, R., Watanuki, Y., Weimerskirch, H., Yamamoto, T., and Catry, P., 2021, Seabird Migration Strategies: Flight Budgets, Diel Activity Patterns, and Lunar Influence, Frontiers in Marine Science, 8:683071. [Available at: http://doi: 10.3389/fmars.2021.683071]

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (8): Flesh-footed Shearwater; Leach's Storm-petrel; Long-tailed Jaeger; Red-tailed Tropicbird; Short-tailed Shearwater; Sooty Shearwater; South Polar Skua; black-legged kittiwake
- As a similar-species source (5): Arctic/Parasitic Jaeger (SPSK/LTJA); Buller's Shearwater (donor not specified); Fork-tailed Storm-petrel (LESP); Pomarine Jaeger (SPSK/LTJA); Wilson's Storm-petrel (LESP)

Donor codes: LESP = Leach's Storm-Petrel, SPSK/LTJA = South Polar Skua / Long-tailed Jaeger

**Leads (gap species)**
- Same genus: Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD; Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD
- Same family (44): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD; Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); +19 more

**Data collection** (instrument/survey, years, location, sample):

> Light-level geolocator + salt-water immersion (wet/dry) loggers on adults from 27 colonies (compiled from many earlier tracking studies). Loggers tested for immersion every 3 s and stored the count of wet tests (0-200) per 10-min bin; flight time per bin = (200 - x)/200. Flight % was averaged per individual per phase, then across individuals (Table 1 = mean of individual means). Phases: outward migration, non-breeding period (stationary period in the non-breeding grounds), return migration. Day = civil dawn to civil dusk. 21 species, 1-3+ years of tracks per species; n per phase = 4-97 birds (Table S2). Species where birds rest out of the water (gulls other than kittiwake, terns, some alcids) were excluded by the authors because immersion data are biased for them.

**Metric(s) addressed:** 

> **FA24** (24-hour proportion of time in flight) for each phase. Not split into DFA/NFA in the tables. Day vs night is only available as the Night Flight Index, NFI = (%flight night - %flight day) / max(%night, %day), range -1 (all flight by day) to +1 (all by night); Table S6 gives the non-breeding baseline. The per-phase day and night percentages are plotted in the figures but not tabulated, so NFA and DFA are NOT recoverable from the text.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Great shearwater (*Ardenna gravis*; not cited by Kelsey) | FA24 | 0.766 | outward migration | 28 | SD 0.196 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Great shearwater (*Ardenna gravis*; not cited by Kelsey) | FA24 | 0.289 | non-breeding period | 29 | SD 0.213 (across individual tracks) | Table 1; n Table S2 |
| Great shearwater (*Ardenna gravis*; not cited by Kelsey) | FA24 | 0.671 | return migration | 26 | SD 0.229 (across individual tracks) | Table 1; n Table S2 |
| Great shearwater (*Ardenna gravis*; not cited by Kelsey) | NFI (not FA) | -0.1 | non-breeding baseline | 29 | SD 0.6 | Table S6 |
| Sooty shearwater (*Ardenna grisea*; Kelsey: direct) | FA24 | 0.722 | outward migration | 15 | SD 0.193 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Sooty shearwater (*Ardenna grisea*; Kelsey: direct) | FA24 | 0.239 | non-breeding period | 17 | SD 0.152 (across individual tracks) | Table 1; n Table S2 |
| Sooty shearwater (*Ardenna grisea*; Kelsey: direct) | FA24 | 0.670 | return migration | 12 | SD 0.241 (across individual tracks) | Table 1; n Table S2 |
| Sooty shearwater (*Ardenna grisea*; Kelsey: direct) | NFI (not FA) | -0.6 | non-breeding baseline | 17 | SD 0.4 | Table S6 |
| Flesh-footed shearwater (*Ardenna carneipes*; Kelsey: direct) | FA24 | 0.699 | outward migration | 19 | SD 0.197 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Flesh-footed shearwater (*Ardenna carneipes*; Kelsey: direct) | FA24 | 0.330 | non-breeding period | 23 | SD 0.220 (across individual tracks) | Table 1; n Table S2 |
| Flesh-footed shearwater (*Ardenna carneipes*; Kelsey: direct) | FA24 | 0.777 | return migration | 20 | SD 0.200 (across individual tracks) | Table 1; n Table S2 |
| Flesh-footed shearwater (*Ardenna carneipes*; Kelsey: direct) | NFI (not FA) | -0.5 | non-breeding baseline | 23 | SD 0.4 | Table S6 |
| Short-tailed shearwater (*Ardenna tenuirostris*; Kelsey: direct) | FA24 | 0.754 | outward migration | 36 | SD 0.246 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Short-tailed shearwater (*Ardenna tenuirostris*; Kelsey: direct) | FA24 | 0.200 | non-breeding period | 39 | SD 0.175 (across individual tracks) | Table 1; n Table S2 |
| Short-tailed shearwater (*Ardenna tenuirostris*; Kelsey: direct) | FA24 | 0.759 | return migration | 37 | SD 0.226 (across individual tracks) | Table 1; n Table S2 |
| Short-tailed shearwater (*Ardenna tenuirostris*; Kelsey: direct) | NFI (not FA) | -0.8 | non-breeding baseline | 39 | SD 0.3 | Table S6 |
| Manx shearwater (*Puffinus puffinus*; not cited by Kelsey) | FA24 | 0.430 | outward migration | 26 | SD 0.239 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Manx shearwater (*Puffinus puffinus*; not cited by Kelsey) | FA24 | 0.186 | non-breeding period | 29 | SD 0.099 (across individual tracks) | Table 1; n Table S2 |
| Manx shearwater (*Puffinus puffinus*; not cited by Kelsey) | FA24 | 0.522 | return migration | 27 | SD 0.265 (across individual tracks) | Table 1; n Table S2 |
| Manx shearwater (*Puffinus puffinus*; not cited by Kelsey) | NFI (not FA) | -0.8 | non-breeding baseline | 29 | SD 0.3 | Table S6 |
| Cory's shearwater (*Calonectris borealis*; not cited by Kelsey) | FA24 | 0.518 | outward migration | 97 | SD 0.199 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Cory's shearwater (*Calonectris borealis*; not cited by Kelsey) | FA24 | 0.259 | non-breeding period | 93 | SD 0.151 (across individual tracks) | Table 1; n Table S2 |
| Cory's shearwater (*Calonectris borealis*; not cited by Kelsey) | FA24 | 0.571 | return migration | 42 | SD 0.199 (across individual tracks) | Table 1; n Table S2 |
| Cory's shearwater (*Calonectris borealis*; not cited by Kelsey) | NFI (not FA) | -0.6 | non-breeding baseline | 93 | SD 0.4 | Table S6 |
| Cape Verde shearwater (*Calonectris edwardsii*; not cited by Kelsey) | FA24 | 0.450 | outward migration | 25 | SD 0.211 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Cape Verde shearwater (*Calonectris edwardsii*; not cited by Kelsey) | FA24 | 0.152 | non-breeding period | 36 | SD 0.111 (across individual tracks) | Table 1; n Table S2 |
| Cape Verde shearwater (*Calonectris edwardsii*; not cited by Kelsey) | FA24 | 0.482 | return migration | 20 | SD 0.218 (across individual tracks) | Table 1; n Table S2 |
| Cape Verde shearwater (*Calonectris edwardsii*; not cited by Kelsey) | NFI (not FA) | -0.8 | non-breeding baseline | 36 | SD 0.4 | Table S6 |
| White-chinned petrel (*Procellaria aequinoctialis*; not cited by Kelsey) | FA24 | 0.712 | outward migration | 11 | SD 0.222 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| White-chinned petrel (*Procellaria aequinoctialis*; not cited by Kelsey) | FA24 | 0.275 | non-breeding period | 14 | SD 0.156 (across individual tracks) | Table 1; n Table S2 |
| White-chinned petrel (*Procellaria aequinoctialis*; not cited by Kelsey) | FA24 | 0.694 | return migration | 9 | SD 0.176 (across individual tracks) | Table 1; n Table S2 |
| White-chinned petrel (*Procellaria aequinoctialis*; not cited by Kelsey) | NFI (not FA) | 0.2 | non-breeding baseline | 14 | SD 0.6 | Table S6 |
| Bulwer's petrel (*Bulweria bulwerii*; not cited by Kelsey) | FA24 | 0.667 | outward migration | 6 | SD 0.092 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Bulwer's petrel (*Bulweria bulwerii*; not cited by Kelsey) | FA24 | 0.566 | non-breeding period | 14 | SD 0.074 (across individual tracks) | Table 1; n Table S2 |
| Bulwer's petrel (*Bulweria bulwerii*; not cited by Kelsey) | FA24 | 0.779 | return migration | 6 | SD 0.085 (across individual tracks) | Table 1; n Table S2 |
| Bulwer's petrel (*Bulweria bulwerii*; not cited by Kelsey) | NFI (not FA) | 0.8 | non-breeding baseline | 14 | SD 0.2 | Table S6 |
| Pycroft's petrel (*Pterodroma pycrofti*; not cited by Kelsey) | FA24 | 0.560 | outward migration | 4 | SD 0.162 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Pycroft's petrel (*Pterodroma pycrofti*; not cited by Kelsey) | FA24 | 0.330 | non-breeding period | 4 | SD 0.157 (across individual tracks) | Table 1; n Table S2 |
| Pycroft's petrel (*Pterodroma pycrofti*; not cited by Kelsey) | FA24 | 0.580 | return migration | 6 | SD 0.213 (across individual tracks) | Table 1; n Table S2 |
| Pycroft's petrel (*Pterodroma pycrofti*; not cited by Kelsey) | NFI (not FA) | -0.1 | non-breeding baseline | 4 | SD 0.4 | Table S6 |
| Murphy's petrel (*Pterodroma ultima*; not cited by Kelsey) | FA24 | 0.831 | outward migration | 8 | SD 0.137 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Murphy's petrel (*Pterodroma ultima*; not cited by Kelsey) | FA24 | 0.399 | non-breeding period | 15 | SD 0.193 (across individual tracks) | Table 1; n Table S2 |
| Murphy's petrel (*Pterodroma ultima*; not cited by Kelsey) | FA24 | 0.808 | return migration | 8 | SD 0.128 (across individual tracks) | Table 1; n Table S2 |
| Murphy's petrel (*Pterodroma ultima*; not cited by Kelsey) | NFI (not FA) | -0.5 | non-breeding baseline | 15 | SD 0.4 | Table S6 |
| Barau's petrel (*Pterodroma baraui*; not cited by Kelsey) | FA24 | 0.790 | outward migration | 9 | SD 0.118 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Barau's petrel (*Pterodroma baraui*; not cited by Kelsey) | FA24 | 0.413 | non-breeding period | 13 | SD 0.166 (across individual tracks) | Table 1; n Table S2 |
| Barau's petrel (*Pterodroma baraui*; not cited by Kelsey) | FA24 | 0.599 | return migration | 10 | SD 0.165 (across individual tracks) | Table 1; n Table S2 |
| Barau's petrel (*Pterodroma baraui*; not cited by Kelsey) | NFI (not FA) | -0.2 | non-breeding baseline | 13 | SD 0.6 | Table S6 |
| Cook's petrel (*Pterodroma cookii*; not cited by Kelsey) | FA24 | 0.768 | outward migration | 8 | SD 0.163 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Cook's petrel (*Pterodroma cookii*; not cited by Kelsey) | FA24 | 0.360 | non-breeding period | 11 | SD 0.163 (across individual tracks) | Table 1; n Table S2 |
| Cook's petrel (*Pterodroma cookii*; not cited by Kelsey) | FA24 | 0.731 | return migration | 4 | SD 0.153 (across individual tracks) | Table 1; n Table S2 |
| Cook's petrel (*Pterodroma cookii*; not cited by Kelsey) | NFI (not FA) | -0.1 | non-breeding baseline | 11 | SD 0.5 | Table S6 |
| Black-winged petrel (*Pterodroma nigripennis*; not cited by Kelsey) | FA24 | 0.665 | outward migration | 9 | SD 0.181 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Black-winged petrel (*Pterodroma nigripennis*; not cited by Kelsey) | FA24 | 0.510 | non-breeding period | 10 | SD 0.201 (across individual tracks) | Table 1; n Table S2 |
| Black-winged petrel (*Pterodroma nigripennis*; not cited by Kelsey) | FA24 | 0.769 | return migration | 10 | SD 0.100 (across individual tracks) | Table 1; n Table S2 |
| Black-winged petrel (*Pterodroma nigripennis*; not cited by Kelsey) | NFI (not FA) | 0.4 | non-breeding baseline | 10 | SD 0.3 | Table S6 |
| Leach's storm-petrel (*Hydrobates leucorhous*; Kelsey: direct) | FA24 | 0.710 | outward migration | 5 | SD 0.125 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Leach's storm-petrel (*Hydrobates leucorhous*; Kelsey: direct) | FA24 | 0.496 | non-breeding period | 6 | SD 0.119 (across individual tracks) | Table 1; n Table S2 |
| Leach's storm-petrel (*Hydrobates leucorhous*; Kelsey: direct) | FA24 | 0.624 | return migration | 6 | SD 0.126 (across individual tracks) | Table 1; n Table S2 |
| Leach's storm-petrel (*Hydrobates leucorhous*; Kelsey: direct) | NFI (not FA) | 0.7 | non-breeding baseline | 6 | SD 0.2 | Table S6 |
| Red-tailed tropicbird (*Phaethon rubricauda*; Kelsey: direct) | FA24 | 0.394 | outward migration | 12 | SD 0.124 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Red-tailed tropicbird (*Phaethon rubricauda*; Kelsey: direct) | FA24 | 0.254 | non-breeding period | 12 | SD 0.098 (across individual tracks) | Table 1; n Table S2 |
| Red-tailed tropicbird (*Phaethon rubricauda*; Kelsey: direct) | FA24 | 0.263 | return migration | 10 | SD 0.118 (across individual tracks) | Table 1; n Table S2 |
| Red-tailed tropicbird (*Phaethon rubricauda*; Kelsey: direct) | NFI (not FA) | -0.1 | non-breeding baseline | 12 | SD 0.5 | Table S6 |
| South polar skua (*Stercorarius maccormicki*; Kelsey: direct) | FA24 | 0.343 | outward migration | 56 | SD 0.197 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| South polar skua (*Stercorarius maccormicki*; Kelsey: direct) | FA24 | 0.122 | non-breeding period | 56 | SD 0.085 (across individual tracks) | Table 1; n Table S2 |
| South polar skua (*Stercorarius maccormicki*; Kelsey: direct) | FA24 | 0.221 | return migration | 55 | SD 0.209 (across individual tracks) | Table 1; n Table S2 |
| South polar skua (*Stercorarius maccormicki*; Kelsey: direct) | NFI (not FA) | -0.8 | non-breeding baseline | 56 | SD 0.4 | Table S6 |
| Long-tailed skua (= Long-tailed Jaeger) (*Stercorarius longicaudus*; Kelsey: direct) | FA24 | 0.473 | outward migration | 14 | SD 0.255 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Long-tailed skua (= Long-tailed Jaeger) (*Stercorarius longicaudus*; Kelsey: direct) | FA24 | 0.263 | non-breeding period | 11 | SD 0.172 (across individual tracks) | Table 1; n Table S2 |
| Long-tailed skua (= Long-tailed Jaeger) (*Stercorarius longicaudus*; Kelsey: direct) | FA24 | 0.373 | return migration | 12 | SD 0.211 (across individual tracks) | Table 1; n Table S2 |
| Long-tailed skua (= Long-tailed Jaeger) (*Stercorarius longicaudus*; Kelsey: direct) | NFI (not FA) | -0.1 | non-breeding baseline | 11 | SD 0.6 | Table S6 |
| Black-legged kittiwake (*Rissa tridactyla*; Kelsey: direct) | FA24 | 0.356 | outward migration | 19 | SD 0.151 (across individual tracks) | Table 1; n Table S2 (quarter-moon column) |
| Black-legged kittiwake (*Rissa tridactyla*; Kelsey: direct) | FA24 | 0.313 | non-breeding period | 32 | SD 0.105 (across individual tracks) | Table 1; n Table S2 |
| Black-legged kittiwake (*Rissa tridactyla*; Kelsey: direct) | FA24 | 0.463 | return migration | 26 | SD 0.196 (across individual tracks) | Table 1; n Table S2 |
| Black-legged kittiwake (*Rissa tridactyla*; Kelsey: direct) | NFI (not FA) | -0.8 | non-breeding baseline | 32 | SD 0.3 | Table S6 |

**Notes** (conversions, assumptions, anything odd):

> - Conversion: percentages / 100. Table 1 SD is among individual tracks, not among years or colonies. n is the quarter-moon column of Table S2 (new / quarter / full moon columns differ by a few birds).
> - **How Kelsey used it (checked against the sheet):** for Leach's Storm-petrel she took all three phases (0.50, 0.62, 0.71 -> median 0.62 = FA24; her text lists the return value as 0.61 but Table 1 says 62.4). For the other direct species her FA24 equals the **non-breeding** value: Sooty 0.24 (23.9), Short-tailed 0.20 (20.0), Flesh-footed 0.33 (33.0), Kittiwake 0.31 (31.3), Red-tailed Tropicbird 0.26 (25.4, rounded). The Long-tailed Jaeger range 0.37-0.47 matches non-breeding / outward-migration values. So the convention was apparently: use non-breeding-period flight where the species is resident in the survey region in that season; use all phases for a migrant passing through (Leach's). **Decision: pool all phases for all species (see Decisions at the top).**
> - Non-breeding values are far below migration values (e.g. Sooty 0.24 vs 0.72/0.67). Pooling all three phases inflates FA; non-breeding is the better match to a bird sitting in the EAAF offshore area.
> - Latitude note: tracks are from Atlantic, Indian and Pacific colonies; the non-breeding grounds for several species are not in the EAAF.
> - Species in the paper that matter for gap species (not cited by Kelsey): Bulwer's Petrel (direct gap species), Black-winged Petrel (direct gap species), Pycroft's / Murphy's / Barau's / Cook's petrel (Pterodroma congener donors), Cory's / Cape Verde shearwater (Calonectris donors for Streaked Shearwater), Manx Shearwater (Puffinus donor for Hutton's, Tropical, Bannerman's, Heinroth's), Great Shearwater (Ardenna donor for Wedge-tailed).
> - Not covered by this paper: Pelagodroma / Fregetta storm-petrels, Pseudobulweria petrels, frigatebirds, Gygis (White Tern). Leach's is the only storm-petrel, so Matsudaira's, Swinhoe's and Tristram's Storm-petrels can only get it as a congener-only donor (Hydrobates).
> - Candidate donor mapping (to decide in the aggregation step, not applied here): Bulwer's and Black-winged = direct; Hydrobates (Matsudaira's, Swinhoe's, Tristram's) <- Leach's; Pterodroma (Gould's, Bonin, Providence, Kermadec, Herald, White-necked) <- Pycroft's, Cook's, Murphy's, Barau's, Black-winged; Wedge-tailed <- Ardenna spp.; Streaked <- Calonectris spp.; Puffinus gaps <- Manx.

---

## 5. Adams et al. 2020

**Full citation:** Adams, J., Felis, J.J., and Czapanskiy, M.F. 2020, Habitat Affinities and At-Sea Ranging Behaviors among Main Hawaiian Island Seabirds: Breeding Seabird Telemetry, 2013–2016. Camarillo (CA): U.S. Department of the Interior, Bureau of Ocean Energy Management, Pacific OCS Region, OCS Study BOEM 2020-006, p. 111.

**Type:** Agency report  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (4): Laysan Albatross; Red-footed Booby; Red-tailed Tropicbird; White-tailed Tropicbird
- As a similar-species source (6): Black-footed Albatross (LAAL); Buller's Shearwater (WTSH); Masked Booby (donor not specified); Short-tailed Albatross (donor not specified); Short-tailed Shearwater (WTSH); Sooty Shearwater (WTSH)

Donor codes: LAAL = Laysan Albatross, WTSH = Wedge-tailed Shearwater

**Leads (gap species)**
- Same genus: Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Brown Booby (*Sula leucogaster*) ✓NPPSD
- Same family (18): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD; Abbott's Booby (*Papasula abbotti*); Australasian Gannet (*Morus serrator*)

**Data collection** (instrument/survey, years, location, sample):

> GPS loggers (i-gotU, e-obs; some with temperature-depth recorders) on breeding adults in the Main Hawaiian Islands, 2013-2016 (Lehua Islet, Kilauea Point NWR, Halona Point, Kaena Point, Waipake, Na Aina Kai and others). Locations rediscretized, then classified by the Residence in Space and Time (RST) algorithm into resting, transiting, searching/foraging; any location with speed < 1 m/s was forced to resting (floating on water). Day phase from sun angle: day > 0 deg, night < -18 deg (astronomical), twilight in between. Percent time per behavior class and day phase is computed by pooling ALL locations from all birds and trips of a trip type, so there is no per-bird variance. Species and trip types: Red-tailed Tropicbird (short, long), Laysan Albatross (short < 6 d, long), Wedge-tailed Shearwater (intraday, short, long), Brown Booby (all trips together in the table), Red-footed Booby (short, long, multiday). Tagged during the breeding season, so values describe foraging trips and exclude time at the colony.

**Metric(s) addressed:** 

> **DFA and NFA** directly (day and night are tabulated separately). Flight proportion = 1 - Rest = Search + Transit (resting is defined as speed < 1 m/s, i.e. on the water, so search and transit are both flight). Twilight is tabulated too but has no place in Kelsey's scheme; recorded as an extra metric so it is not lost.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Red-tailed Tropicbird (Kelsey: direct) | DFA | 0.761 | day; short trips; component, do not aggregate | 4062 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | DFA | 0.561 | day; long trips; component, do not aggregate | 62546 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | DFA | 0.573 | day; all trips; POOLED all trips, N-weighted (use this) | 66608 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | NFA | NA | night; short trips; component, do not aggregate | NA | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | NFA | 0.086 | night; long trips; component, do not aggregate | 37431 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | NFA | 0.086 | night; all trips; POOLED all trips, N-weighted (use this) | 37431 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.838 | twilight; short trips; component, do not aggregate | 619 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.432 | twilight; long trips; component, do not aggregate | 14427 | none reported (location counts only) | Table 5 |
| Red-tailed Tropicbird (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.449 | twilight; all trips; POOLED all trips, N-weighted (use this) | 15046 | none reported (location counts only) | Table 5 |
| Laysan Albatross (Kelsey: direct) | DFA | 0.743 | day; short trips; component, do not aggregate | 9700 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | DFA | 0.761 | day; long trips; component, do not aggregate | 99221 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | DFA | 0.759 | day; all trips; POOLED all trips, N-weighted (use this) | 108921 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | NFA | 0.482 | night; short trips; component, do not aggregate | 6102 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | NFA | 0.379 | night; long trips; component, do not aggregate | 47472 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | NFA | 0.391 | night; all trips; POOLED all trips, N-weighted (use this) | 53574 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.750 | twilight; short trips; component, do not aggregate | 1960 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.612 | twilight; long trips; component, do not aggregate | 26377 | none reported (location counts only) | Table 8 |
| Laysan Albatross (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.621 | twilight; all trips; POOLED all trips, N-weighted (use this) | 28337 | none reported (location counts only) | Table 8 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | DFA | 0.686 | day; intraday trips; component, do not aggregate | 100180 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | DFA | 0.735 | day; short trips; component, do not aggregate | 74385 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | DFA | 0.729 | day; long trips; component, do not aggregate | 182361 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | DFA | 0.718 | day; all trips; POOLED all trips, N-weighted (use this) | 356926 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | NFA | 0.620 | night; intraday trips; component, do not aggregate | 16395 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | NFA | 0.270 | night; short trips; component, do not aggregate | 41558 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | NFA | 0.284 | night; long trips; component, do not aggregate | 122574 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | NFA | 0.311 | night; all trips; POOLED all trips, N-weighted (use this) | 180527 | none reported (location counts only) | Table 11 |
| Wedge-tailed Shearwater (Kelsey: not cited for this species, GAP SPECIES; gives direct value) | twilight flight (NOT DFA/NFA; recorded only) | 0.713 | twilight; all trips; POOLED all trips, N-weighted (use this) | 69147 | none reported (location counts only) | Table 11 |
| Brown Booby (GAP SPECIES; gives direct value) | DFA | 0.676 | day; all trips; POOLED all trips, N-weighted (use this) | 28232 | none reported (location counts only) | Table 15 |
| Brown Booby (GAP SPECIES; gives direct value) | NFA | 0.007 | night; all trips; POOLED all trips, N-weighted (use this) | 1253 | none reported (location counts only) | Table 15 |
| Brown Booby (GAP SPECIES; gives direct value) | twilight flight (NOT DFA/NFA; recorded only) | 0.569 | twilight; all trips; POOLED all trips, N-weighted (use this) | 1347 | none reported (location counts only) | Table 15 |
| Red-footed Booby (Kelsey: direct) | DFA | 0.727 | day; short trips; component, do not aggregate | 49612 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | DFA | 0.702 | day; long trips; component, do not aggregate | 74301 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | DFA | 0.716 | day; multiday trips; component, do not aggregate | 45909 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | DFA | 0.713 | day; all trips; POOLED all trips, N-weighted (use this) | 169822 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | NFA | 0.728 | night; short trips; component, do not aggregate | 519 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | NFA | 0.855 | night; long trips; component, do not aggregate | 919 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | NFA | 0.122 | night; multiday trips; component, do not aggregate | 19509 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | NFA | 0.169 | night; all trips; POOLED all trips, N-weighted (use this) | 20947 | none reported (location counts only) | Table 20 |
| Red-footed Booby (Kelsey: direct) | twilight flight (NOT DFA/NFA; recorded only) | 0.709 | twilight; all trips; POOLED all trips, N-weighted (use this) | 18540 | none reported (location counts only) | Table 20 |

**Notes** (conversions, assumptions, anything odd):

> - **File note:** the PDF you attached is titled in the filename as a Felis et al. 2019 bio-logger data release, but its contents are the BOEM report OCS Study BOEM 2020-006 (Adams, Felis and Czapanskiy 2020), which is what Kelsey cites as Adams et al. 2020. I filled this section (5) with it. If the separate 2019 data release is meant to be its own source, it is not in Kelsey's lit cited list as written.
> - Conversion: flight = 100 - Rest%, divided by 100. n = number of GPS locations (sum of rest + search + transit counts), not birds. No SD or CI are reported anywhere; the behavior tables are pooled across birds.
> - **Row convention:** per trip type rows are components; the row labelled "POOLED all trips, N-weighted (use this)" is the one to feed into the aggregation, so trip types are not double counted. Pooling weights by locations, so long trips dominate.
> - **Kelsey comparison (reproduction check):** see the separate summary in chat. DFA reproduces; NFA reproduces for Red-footed Booby only if multiday trips alone are used (0.122 vs Kelsey 0.12). Pooling all Red-footed trips gives 0.169, which is identical to the sheet's Red-tailed Tropicbird NFA (0.17), worth checking for a mix-up. Masked Booby NFA range 0.01-0.12 in Kelsey's sheet matches Brown Booby (0.007) and Red-footed multiday (0.122).
> - **Gap species with direct values from this report:** Wedge-tailed Shearwater (DFA 0.718, NFA 0.311) and Brown Booby (DFA 0.676, NFA 0.007; only 1,253 night locations, 99% resting, so NFA is close to zero but weakly supported).
> - The sheet row for Wedge-tailed Shearwater has a stray NFA of 0.96 with no reference and no DFA. Looks like a data entry error; to check before we overwrite.
> - Kelsey's text says she estimated NFA for the other shearwaters as 50% of DFA using Wedge-tailed, Pink-footed and Manx; this report's WTSH NFA/DFA ratio is 0.43.
> - These are breeding-season foraging trips from Hawaii, not EAAF non-breeding birds (Kelsey's caveat for seabirds applies).

---

## 6. Benvenuti et al. 2001

**Full citation:** Benvenuti, S., Dall’antonia, L., Lyngs, P., 2001, Foraging behavior and time allocation of chick-rearing Razorbills Alca torda at Graesholmen, central Baltic Sea, Ibis, v. 143, no. 4, p. 402 – 412. . [Available at: http://doi.org/10.1111/j.1474-919X.2001.tb04941.x]

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (7): Ancient Murrelet (RAZO); Common Murre (RAZO); Horned Puffin (RAZO); Parakeet Auklet (RAZO); Pigeon Guillemot (RAZO); Rhinoceros Auklet (RAZO); Tufted Puffin (RAZO)

Donor codes: RAZO = Razorbill

**Leads (gap species)**
- Same family (8): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> Razorbills (*Alca torda*) breeding at Graesholmen, Baltic Sea (Sweden), June-July 1998. 9 chick-rearing adults fitted with event recorders (flight sensor, some with depth meter; 6 s sampling); 42 foraging trips (34 diurnal, 8 nocturnal), 35 trips (28 diurnal + 7 nocturnal) from the 6 birds with depth meters have full time budgets.

**Metric(s) addressed:** no DFA/NFA/FA24 proper. Time in flight as a percentage of *foraging-trip time only* (time at the colony is excluded), split into diurnal and nocturnal trips. Kelsey used it as the Razorbill (RAZO) proxy for Pacific alcid NFA.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Razorbill (*Alca torda*; donor for Pacific alcids; not in sheet) | DFA (proxy: share of foraging-trip time in flight, diurnal trips) | 0.119 | chick rearing, diurnal foraging trips only | 28 trips, 6 birds | trip flight time 14.0 ± 12.8 min of 117.6 ± 85.0 min (SD of minutes; no SD on the %) | Table 2, p. 407 text |
| Razorbill (*Alca torda*; donor for Pacific alcids) | NFA (proxy: share of foraging-trip time in flight, nocturnal trips) | 0.070 | chick rearing, nocturnal foraging trips only | 7 trips, 6 birds | trip flight time 38.5 ± 20.1 min of 550.0 ± 66.9 min (SD of minutes) | Table 2 and text |

**Notes** (conversions, assumptions, anything odd):

> - Conversions: 11.9% and 7.0% / 100. These are shares of trip time, not of 24 h or even of night/day, so they overstate true DFA/NFA (the bird is in the colony or resting at the nest for much of the rest of the day and night). I recorded them as DFA/NFA proxies because that is how Kelsey used them.
> - Diurnal trips outnumber nocturnal ones (nocturnal trips are 8.9 h, at the nest the rest of the night in unpredictable pattern), so the NFA proxy rests on 7 trips.
> - Kelsey's sheet shows NFA 0.027 (range 0.001-0.054) for every alcid proxied from Razorbill/Common Murre. 0.070 does not reproduce those values, so she must have scaled or combined it with something else; unresolved.
> - Gap species it could donate to (all alcid gaps): Least, Whiskered and Crested Auklet; Long-billed and Kittlitz's Murrelet; Spectacled Guillemot; Japanese Murrelet; Thick-billed Murre.

---

## 7. Dunn et al. 2020

**Full citation:** Dunn, R.E., Wanless, S., Daunt, F., Harris, M.P., and Green, J.A., 2020, A year in the life of a North Atlantic seabird: behavioural and energetic adjustments during the annual cycle. Nature Scientific Reports, v. 10, no. 5992. [Available at: https://doi.org/10.1038/s41598-020-62842-x]

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (1): Common Murre
- As a similar-species source (5): Ancient Murrelet (COMU); Horned Puffin (COMU); Parakeet Auklet (COMU); Rhinoceros Auklet (COMU); Tufted Puffin (COMU)

Donor codes: COMU = Common Murre

**Leads (gap species)**
- Same genus: Thick-billed Murre (*Uria lomvia*) ✓NPPSD
- Same family (7): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*)

**Data collection** (instrument/survey, years, location, sample):

> Common guillemots (Common Murre, *Uria aalge*), Isle of May, Scotland. 30 adults fitted with GLS-temperature-depth loggers (Lotek LT2400) in June 2005; 13 retrieved in 2006 (43%), giving 179 complete bird-days across the whole annual cycle. Flight identified from logger temperature/depth, with the assumption that guillemots do not fly at night; flight set to zero in assumed flightless moult (mid-Aug to end Sep).

**Metric(s) addressed:** **FA24** (daily hours in flight / 24). Because flight at night is assumed to be zero, there is no real NFA and DFA is not given (day length not tabulated).

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Common Murre (*Uria aalge*) | FA24 | 0.008 | non-breeding, October-February (0.2 ± 0.03 h/day / 24) | 13 birds, 179 bird-days | ± 0.03 h/day = ± 0.001 (type of error not stated; GAMM prediction) | Results, Fig. 4A |
| Common Murre (*Uria aalge*) | FA24 | 0.030 | start of pre-breeding, March (0.72 ± 0.03 h/day / 24) | 13 birds, 179 bird-days | ± 0.001 (type not stated) | Results, Fig. 4A |
| Common Murre (*Uria aalge*) | FA24 | 0.066 | chick rearing, June (1.58 ± 0.07 h/day / 24) | 13 birds, 179 bird-days | ± 0.003 (type not stated) | Results, Fig. 4A |

**Notes** (conversions, assumptions, anything odd):

> - Conversion: hours of flight per day / 24. Only the winter and the March-June range are given in the text; the full monthly curve is in Fig. 4A and not tabulated. The three rows are the numbers in the text; I did not read values off the figure.
> - Phase pooling decision (all phases, Decisions above): all three rows go to the median. Flight time is also set to zero during assumed flightless moult (about 1.5 months), which is not entered as a value.
> - **Kelsey comparison:** her Common Murre FA24 is 0.029 (range 0.028-0.030); that does not equal any one Dunn number, so she probably blended Dunn with Linnebjerg 2015. Her FA24 range 0.008-0.063 for the puffins, auklets and murrelets proxied from Common Murre matches the Dunn winter value (0.2 h = 0.008) and the breeding peak taken as about 1.5 h/day (0.0625), not 1.58 h (0.066).
> - Gap species it could donate to: Thick-billed Murre (same genus); other alcid gaps at family level.
> - Birds assumed absent from the colony and at sea for most of the non-breeding period, so the values are at-sea flight for a bird that is at sea; breeding values include commuting to and from the colony.

---

## 8. Carle et al. 2019

**Full citation:** Carle, R.D., Felis, J.J., Vega, R., Beck, J., Adams, J., López, V., Hodum, P.J., González, A., Colodro, V., and Varela, T., 2019, Overlap of Pink-footed Shearwaters and central Chilean purse-seine fisheries: Implications for bycatch risk, The Condor, v. 12, no. 3, duz026.

**Type:** Journal article / other  
**Status:** `[-]` read, nothing usable for FA

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (5): Buller's Shearwater (PFSH); Flesh-footed Shearwater (PFSH); Northern Fulmar (PFSH); Short-tailed Shearwater (PFSH); Sooty Shearwater (PFSH)

Donor codes: PFSH = Pink-footed Shearwater

**Leads (gap species)**
- Same genus: Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD
- Same family (16): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> Pink-footed Shearwaters breeding on Isla Mocha, Chile; 49 birds with i-gotU GPS loggers (5-min fixes), 83 foraging trips, Feb-Apr 2015-2017. Purpose: overlap with purse-seine fisheries.

**Metric(s) addressed:** none. The paper reports trip duration, range and distance travelled (Table 1), habitat use grids and fishery overlap. No flying vs resting classification, and no day vs night split, so no DFA, NFA or FA24.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| (no values) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> - Kelsey's text says the Pink-footed Shearwater NFA:DFA ratio (used to set NFA for Sooty and Short-tailed Shearwater and Northern Fulmar) came from Carle et al. 2019, but it is not in the paper; it presumably comes from the unpublished data behind the Felis/Carle personal communication (section 11).
> - A rough flight proportion could be backed out of distance travelled / (speed x duration), using the paper's 27 m/s mean maximum speed (e.g. long trips: 1,203.9 km over 121.2 h), but it would be my own derivation, not Kelsey's method, and speed is a maximum not a mean. Not entered.
> - Table 1: short trips 18.6 ± 3.0 h, long trips 121.2 ± 65.9 h; 47 birds on long trips.

---

## 9. Linnebjerg et al. 2015

**Full citation:** Linnebjerg, J.E., Reuleaux, A., Mouritsen, K.N., and Frederiksen, M., 2015, Foraging ecology of three sympatric breeding alcids in a declining colony in Southwest Greenland, Waterbirds. v. 38, no. 2, p. 143 – 152. [Available at: https://doi.org/10.1675/063.038.0203]

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (1): Common Murre
- As a similar-species source (4): Horned Puffin (COMU); Pigeon Guillemot (COMU); Rhinoceros Auklet (COMU); Tufted Puffin (COMU)

Donor codes: COMU = Common Murre

**Leads (gap species)**
- Same genus: Thick-billed Murre (*Uria lomvia*) ✓NPPSD
- Same family (7): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*)

**Data collection** (instrument/survey, years, location, sample):

> Thick-billed Murres, Common Murres and Razorbills breeding at Kitsissut Avalliit, southwest Greenland (60.8 N), July-August 2009-2011. 35 chick-rearing adults caught; time-depth recorders on all, GPS on a subset; TDRs worn 1-9 days. Flight identified from the TDR record (surface/dive/flight/colony).

**Metric(s) addressed:** none directly. The paper gives mean flight duration per trip (hr) and mean trips per 24 hr (Table 1); I multiplied them to get hours of flight per day and divided by 24 to get **FA24**. The time-budget percentages (Fig. 4A, 4B) are only in the figure, not in text.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Thick-billed Murre (*Uria lomvia*; GAP SPECIES) | FA24 (derived) | 0.020 | chick rearing, July-August (0.2 h flight/trip x 2.4 trips/24 h / 24) | 5 birds with TDR (Fig. 1), 30 trips | flight/trip SD 0.2 h (SD of trips); mean given to 1 decimal so value is +/- about 25% | Table 1 |
| Common Murre (*Uria aalge*; Kelsey: direct) | FA24 (derived) | 0.028 | chick rearing, July-August (0.4 h x 1.7 trips/24 h / 24) | 9 birds with TDR (Fig. 1), 95 trips | flight/trip SD 0.3 h | Table 1 |
| Razorbill (*Alca torda*; donor for Pacific alcids) | FA24 (derived) | 0.053 | chick rearing, July-August (0.6 h x 2.1 trips/24 h / 24) | 9 birds with TDR (Fig. 1), 63 trips | flight/trip SD 0.6 h | Table 1 |

**Notes** (conversions, assumptions, anything odd):

> - **Derived values, not published as such.** FA24 = (mean flight per trip, h) x (mean trips per 24 h) / 24. The mean flight per trip is rounded to one decimal, so the Thick-billed Murre value is coarse (0.15-0.25 h would give 0.015-0.025).
> - Reproduces Kelsey: her Common Murre FA24 minimum is 0.028, which is exactly this value; her NFA maximum of 0.054 for the Razorbill-proxied alcids matches the Razorbill value (0.053) (unrounded inputs). So Linnebjerg is where Kelsey's 0.028 and (probably) 0.054 came from.
> - **Gap species:** Thick-billed Murre now has a direct FA24 (plus the Dunn Common Murre values as a congener). For the other alcid gaps, Common Murre / Razorbill act as the family donors.
> - Includes colony-based time: trips are from the nest, but the 24 h denominator includes time at the colony, so these are true 24 h values (unlike Benvenuti, which used trip time only).
> - Sex differences in foraging timing are not tabulated.

---

## 10. Rueda-Uribe et al. 2022

**Full citation:** Rueda-Uribe, C., Lötberg, U., and Åkesson, S., 2022, Foraging on the wing for fish while migrating over changing landscapes: traveling behaviors vary with available aquatic habitat for Caspian Terns, Movement Ecology, v. 10, no. 9. [Available at: https://doi.org/10.1186/s40462-022-00307-8]

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (1): Caspian Tern
- As a similar-species source (3): Arctic Tern (CATE); Common Gull-billed Tern (CATE); Common Tern (CATE)

Donor codes: CATE = Caspian Tern? (code unclear)

**Leads (gap species)**
- Same family (28): Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); Black-tailed Gull (*Larus crassirostris*); Mew Gull (*Larus canus*); Lesser Black-backed Gull (*Larus fuscus*); Arctic Herring Gull (*Larus smithsonianus*); Slaty-backed Gull (*Larus schistisagus*) ✓NPPSD; Glaucous Gull (*Larus hyperboreus*) ✓NPPSD; aleutian tern (*Onychoprion aleuticus*); Sooty Tern (*Onychoprion fuscatus*); Bridled Tern (*Onychoprion anaethetus*); Grey-backed Tern (*Onychoprion lunatus*); Little Tern (*Sternula albifrons*); Fairy Tern (*Sternula nereis*); Australian Gull-billed Tern (*Gelochelidon macrotarsa*); Roseate Tern (*Sterna dougallii*); White-fronted Tern (*Sterna striata*); Black-naped Tern (*Sterna sumatrana*); +3 more

**Data collection** (instrument/survey, years, location, sample):

> Caspian Terns (*Hydroprogne caspia*) breeding in the Baltic Sea (Sweden): 39 birds (12 adults, 27 juveniles) with solar GPS-GSM/3G loggers (Ornitela), fixes every 5 min to 2 h, resampled to 30 min; complete autumn migration (adults + juveniles) and spring migration (adults only) tracks, 5 colonies.

**Metric(s) addressed:** **FA24** on travelling (migration) days only: average daily hours of flight / 24, by geographic region. Day versus night is only given as a day:night flight ratio (about 1.01 in northern Europe) and 'migratory flights occurred mostly during the night', so no NFA or DFA.

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Caspian Tern (*Hydroprogne caspia*; Kelsey: direct) | FA24 (travelling days only) | 0.354 | autumn migration, all regions (8.5 ± 2 h/day / 24) | 39 birds (12 adults, 27 juveniles) | ± 2 h (SD) = ± 0.083 | Supplement Table S2 |
| Caspian Tern (*Hydroprogne caspia*; Kelsey: direct) | FA24 (travelling days only) | 0.406 | spring migration, all regions (9.74 ± 2.59 h/day / 24) | 12 adults | ± 2.59 h (SD) = ± 0.108 | Supplement Table S2 |

**Notes** (conversions, assumptions, anything odd):

> - **Kelsey's 0.38 is found.** Supplement Table S2 gives average daily flight hours in travelling segments: autumn 8.5 (SD 2) h and spring 9.74 (SD 2.59) h. 8.5/24 = 0.354 and 9.74/24 = 0.406; the median of the two (= their mean) is 0.380. So her 'FA24 = 0.38' is the median of the two seasonal values, and the two rows above reproduce it. Under the all-phases pooling rule these two rows are the ones to aggregate.
> - Conversion: hours / 24. Travelling days only, so these overstate a year-round FA24 (stopover days excluded). Tracks are from Baltic-breeding birds migrating to Africa, not EAAF birds.
> - Regional means (Supplement Table S4, hours/day), recorded here but **not entered** to avoid double counting the same flights: autumn Northern Europe 6.21 (3.17), Europe 10.52 (3.00), Sahara 15.05 (3.12), African coast 10.53 (2.69), Sahel 6.28 (4.27); spring Northern Europe 6.77 (1.60), Europe 11.11 (3.02), Sahara 13.08 (2.42).
> - Day vs night: the day:night flight ratio, corrected for available light, is 0.95 (SD 0.08) in both seasons (S2), i.e. terns fly nearly as much per available hour at night as by day. No separate NFA or DFA is given.
> - Gap species it covers under the tern rule: all terns (13), noddies (4) and White Tern (1). Value 0.38, uncertainty from the two seasonal values (0.354-0.406).

---

## 11. pers. comm. (Felis/Carle)

**Full citation:** Personal communication (J. Felis / R. Carle) — no entry in Literature Cited

**Type:** Personal communication  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (4): Black-necked Grebe; Horned Grebe; Red-necked Grebe; Red-necked Phalarope
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Black-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Horned Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Red-necked Phalarope (Kelsey: direct) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 12. Dean et al. 2013

**Full citation:** Dean, B., Freeman, R., Kirk, H., Leonard, K., Phillips, R.A., Perrins, C.M. and Guilford, T., 2013, Behavioural mapping of a pelagic seabird: combining multiple sensors and a hidden Markov model reveals the distribution of at-sea behaviour, Journal of the Royal Society Interface, v. 10, no. 78, p. 20120570.

**Type:** Journal article / other  
**Status:** `[x]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (3): Buller's Shearwater (MASH); Short-tailed Shearwater (MASH); Sooty Shearwater (MASH)

Donor codes: MASH = Manx Shearwater

**Leads (gap species)**
- Same genus: Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*)
- Same family (13): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> Manx Shearwaters breeding on Skomer (Wales) and Copeland (N. Ireland), 2009-2011, incubation and chick-rearing trips: GPS (5-10 min fixes) + geolocator-immersion loggers (3 s tests, 10-min summaries), plus TDRs on 25 Skomer birds. A hidden Markov model classified each 10-min interval into three states: sustained direct flight, sitting on the sea surface, foraging (tortuous flight interspersed with immersion).

**Metric(s) addressed:** daytime time budget only: percentage of **daylight hours** in each state. No night budget is reported. So the closest metric is **DFA**, with ambiguity over what counts as flight: direct flight alone, or direct flight plus the foraging state (which contains tortuous flight and immersion, median proportion immersed 0.63).

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Manx Shearwater (*Puffinus puffinus*; donor for Puffinus gaps) | DFA (lower bound: direct flight only) | 0.100 | incubation trips, daylight hours, both colonies | 62 bird-deployments (Copeland 33, Skomer 29) | none (mean; Wilcoxon tests only) | Results 3.3, Fig. 6 |
| Manx Shearwater (*Puffinus puffinus*; donor for Puffinus gaps) | DFA (upper bound: direct flight + foraging) | 0.730 | incubation trips, daylight hours (10% + 63%) | 62 bird-deployments | none | Results 3.3 |
| Manx Shearwater (*Puffinus puffinus*; donor for Puffinus gaps) | DFA (lower bound: direct flight only) | 0.150 | chick rearing trips, daylight hours, both colonies | 106 bird-deployments (Copeland 50, Skomer 56) | none | Results 3.3, Fig. 6 |
| Manx Shearwater (*Puffinus puffinus*; donor for Puffinus gaps) | DFA (upper bound: direct flight + foraging) | 0.720 | chick rearing trips, daylight hours (15% + 57%) | 106 bird-deployments | none | Results 3.3 |

**Notes** (conversions, assumptions, anything odd):

> - Percentages / 100. The colony-level medians are also given in the text (incubation: Skomer 12% direct flight / 60% foraging / 27% sitting, Copeland 6 / 64 / 27; chick rearing: Skomer 19 / 54 / 27, Copeland 12 / 60 / 28) and are not entered separately; the table uses the overall means.
> - **DFA decision needed:** a middle estimate = direct flight + (1 - 0.63 immersed) x foraging gives 0.10 + 0.37 x 0.63 = 0.33 (incubation) and 0.15 + 0.37 x 0.57 = 0.36 (chick rearing). That is my own derivation, not in the paper and not entered. Kelsey's text only says NFA and DFA for Manx came from tracking; her values for the Manx-proxied shearwaters are not directly traceable to a single number here. Direct-flight-only is clearly too low and direct + foraging too high; the middle estimate is the better DFA.
> - **No NFA:** birds are mostly sitting at night (nocturnal roosting on the sea, often away from the colony), and chick-rearing birds return to the colony at night, but no night percentage is given. Kelsey's rule 'NFA = 50% of DFA' for shearwaters would be applied separately.
> - Gap species it could donate to: Hutton's, Tropical, Bannerman's and Heinroth's Shearwater (Puffinus, same genus).

---

## 13. Heinanen et al. 2020

**Full citation:** Heinanen, S., Zydelis, R., Kleinschmidt, B., Dorsch, M., Burger, C., Morkunas, J., Quillfieldt, P., and Nehls, G., 2020, Satellite telemetry and digital aerial surveys show strong displacement of red-throated divers (Gavia stellata) from offshore wind farms, Marine Environmental Research, v. 160, [Available at: https://doi.org/10.1016/j.marenvres.2020.104989]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Red-throated Loon
- As a similar-species source (2): Pacific Loon (RTLO); Yellow-billed Loon (RTLO)

Donor codes: RTLO = Red-throated Loon

**Leads (gap species)**
- Same genus: Arctic Loon (*Gavia arctica*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Red-throated Loon (Kelsey: direct) |  |  |  |  |  |  |
| Pacific Loon (RTLO) (Kelsey: proxy) |  |  |  |  |  |  |
| Yellow-billed Loon (RTLO) (Kelsey: proxy) |  |  |  |  |  |  |
| Arctic Loon (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 14. Kato et al. 2003

**Full citation:** Kato, A., Watanuki, Y., and Naito, Y., 2003, Foraging behavior of chick-rearing rhinoceros auklets Cerorhinca monocerata at Teuri Island, Japan, determined by acceleration-depth recording micro data loggers. Journal of Avian Biology, v. 34, p. 282 – 287.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Rhinoceros Auklet
- As a similar-species source (2): Horned Puffin (RHAU); Tufted Puffin (RHAU)

Donor codes: RHAU = Rhinoceros Auklet

**Leads (gap species)**
- Same family (8): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Rhinoceros Auklet (Kelsey: direct) |  |  |  |  |  |  |
| Horned Puffin (RHAU) (Kelsey: proxy) |  |  |  |  |  |  |
| Tufted Puffin (RHAU) (Kelsey: proxy) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 15. Paruk et al. 2008

**Full citation:** Paruk, J.D., 2008, Nocturnal behavior of the Common Loon, Gavia immer, Canadian Field-Naturalist, v. 122, no. 1, p. 70-72.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (3): Pacific Loon (COLO); Red-throated Loon (COLO); Yellow-billed Loon (COLO)

Donor codes: COLO = Common Loon

**Leads (gap species)**
- Same genus: Arctic Loon (*Gavia arctica*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Pacific Loon (COLO) (Kelsey: proxy) |  |  |  |  |  |  |
| Red-throated Loon (COLO) (Kelsey: proxy) |  |  |  |  |  |  |
| Yellow-billed Loon (COLO) (Kelsey: proxy) |  |  |  |  |  |  |
| Arctic Loon (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 16. Jakubas et al. 2014

**Full citation:** Jakubas, D., Wojczulanis-Jakubas, K., Iliszk, L., Darecki, M., and Stempniewicz, L., 2014, Foraging strategy of the little auk 

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (2): Ancient Murrelet (LIAU); Parakeet Auklet (LIAU)

Donor codes: LIAU = Little Auk

**Leads (gap species)**
- Same family (8): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Ancient Murrelet (LIAU) (Kelsey: proxy) |  |  |  |  |  |  |
| Parakeet Auklet (LIAU) (Kelsey: proxy) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 17. Medrano et al. 2022

**Full citation:** Medrano, F., Militão, T., Gomes, I., Sardà-Serra, M., de la Fuente, M., Dinis, H.A., and Gonza´ lez-Solı´s, J., 2022, Phenological divergence, population connectivity and ecological differentiation in two allochronic seabird populations, Frontiers in Marine Science. [Available at: https://doi.org/10.3389/fmars.2022.975716]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (2): Fork-tailed Storm-petrel (CVSP); Wilson's Storm-petrel (CFSP)

Donor codes: CFSP = Cape Verde Storm-Petrel, CVSP = Cape Verde Storm-Petrel

**Leads (gap species)**
- Same genus: Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Fork-tailed Storm-petrel (CVSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Wilson's Storm-petrel (CFSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Matsudaira's Storm-petrel (lead) |  |  |  |  |  |  |
| Swinhoe's Storm-petrel (lead) |  |  |  |  |  |  |
| Tristram's Storm-petrel (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 18. Medrano et al. 2024

**Full citation:** Medrano, F., Hernández-Montoya, J., Saldanha, S.., Bedolla-Guzmán, Y., and González-Solís, J., 2024, Contrasting migratory ecology of two endangered and allochronic storm petrels breeding in the North Pacific, Endangered Species Research, v. 54, p. 331 – 339. 

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (2): Fork-tailed Storm-petrel (CVSP); Wilson's Storm-petrel (CFSP)

Donor codes: CFSP = Cape Verde Storm-Petrel, CVSP = Cape Verde Storm-Petrel

**Leads (gap species)**
- Same genus: Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Fork-tailed Storm-petrel (CVSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Wilson's Storm-petrel (CFSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Matsudaira's Storm-petrel (lead) |  |  |  |  |  |  |
| Swinhoe's Storm-petrel (lead) |  |  |  |  |  |  |
| Tristram's Storm-petrel (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 19. Militao et al. 2022

**Full citation:** Militao, T., Sanz-Aguilar, A., Rotger, A., and Ramos, R., 2022, Non-breeding distribution and at-sea activity patterns of the smallest European seabird, the European Storm Petrel (Hydrobates pelagicus), Ibis, v. 164, p. 1160 – 1179. [Available at: https://doi.org/10.1111/ibi.13068]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (2): Fork-tailed Storm-petrel (EUSP); Wilson's Storm-petrel (EUSP)

Donor codes: EUSP = European Storm-Petrel

**Leads (gap species)**
- Same genus: Matsudaira's Storm-petrel (*Hydrobates matsudairae*); Swinhoe's Storm-petrel (*Hydrobates monorhis*); Tristram's Storm-petrel (*Hydrobates tristrami*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Fork-tailed Storm-petrel (EUSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Wilson's Storm-petrel (EUSP) (Kelsey: proxy) |  |  |  |  |  |  |
| Matsudaira's Storm-petrel (lead) |  |  |  |  |  |  |
| Swinhoe's Storm-petrel (lead) |  |  |  |  |  |  |
| Tristram's Storm-petrel (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 20. Brown et al. 2023

**Full citation:** Brown, J.M, Bouten, W., Camphuysen, K.C.J., Nolet, B.A., Shamoun-Baranes, J., 2023, Energetic and behavioral consequences of migration: an empirical evaluation in the context of the full annual cycle, Scientific Reports, v. 13, no. 1210. [Available at: https://doi.org/10.1038/s41598-023-28198-8]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Glaucous-winged Gull (LBBG)

Donor codes: LBBG = Lesser Black-backed Gull

**Leads (gap species)**
- Same genus: Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); Black-tailed Gull (*Larus crassirostris*); Mew Gull (*Larus canus*); Lesser Black-backed Gull (*Larus fuscus*); Arctic Herring Gull (*Larus smithsonianus*); Slaty-backed Gull (*Larus schistisagus*) ✓NPPSD; Glaucous Gull (*Larus hyperboreus*) ✓NPPSD
- Same family (18): Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); aleutian tern (*Onychoprion aleuticus*); Sooty Tern (*Onychoprion fuscatus*); Bridled Tern (*Onychoprion anaethetus*); Grey-backed Tern (*Onychoprion lunatus*); Little Tern (*Sternula albifrons*); Fairy Tern (*Sternula nereis*); Australian Gull-billed Tern (*Gelochelidon macrotarsa*); Roseate Tern (*Sterna dougallii*); White-fronted Tern (*Sterna striata*); Black-naped Tern (*Sterna sumatrana*); Lesser Crested Tern (*Thalasseus bengalensis*); Chinese Crested Tern (*Thalasseus bernsteini*); Greater Crested Tern (*Thalasseus bergii*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Glaucous-winged Gull (LBBG) (Kelsey: proxy) |  |  |  |  |  |  |
| Brown-headed Gull (lead) |  |  |  |  |  |  |
| Black-headed Gull (lead) |  |  |  |  |  |  |
| Silver Gull (lead) |  |  |  |  |  |  |
| Pallas's Gull (lead) |  |  |  |  |  |  |
| Black-tailed Gull (lead) |  |  |  |  |  |  |
| Mew Gull (lead) |  |  |  |  |  |  |
| Lesser Black-backed Gull (lead) |  |  |  |  |  |  |
| Arctic Herring Gull (lead) |  |  |  |  |  |  |
| Slaty-backed Gull (lead) |  |  |  |  |  |  |
| Glaucous Gull (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 21. Clay et al. 2017

**Full citation:** Clay, T.A., Phillips, R.A., Manica, A., Jackson, H.A., Brooke, M. de L., 2017, Escaping the oligotrophic gyre? The year-round movements, foraging behavior and habitat preferences of Murphy’s petrels, Marine Ecology Progress Series, v. 579, p. 139 – 155.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Hawaiian Petrel (MUPE)

Donor codes: MUPE = Murphy's Petrel

**Leads (gap species)**
- Same genus: White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*)
- Same family (10): Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Hawaiian Petrel (MUPE) (Kelsey: proxy) |  |  |  |  |  |  |
| White-winged (Gould's) Petrel (lead) |  |  |  |  |  |  |
| Bonin Petrel (lead) |  |  |  |  |  |  |
| Black-winged Petrel (lead) |  |  |  |  |  |  |
| Providence Petrel (lead) |  |  |  |  |  |  |
| Kermadec Petrel (lead) |  |  |  |  |  |  |
| Herald Petrel (lead) |  |  |  |  |  |  |
| White-necked Petrel (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 22. Craik et al. 2020

**Full citation:** Craik, S., Pearce, J. and Titman, R.D., 2020, Red-breasted Merganser (Mergus serrator), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.rebmer.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Red-breasted Merganser
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same family (10): Spectacled Eider (*Somateria fischeri*) ✓NPPSD; King Eider (*Somateria spectabilis*) ✓NPPSD; Common Eider (*Somateria mollissima*) ✓NPPSD; Steller's Eider (*Polysticta stelleri*) ✓NPPSD; Velvet Scoter (*Melanitta fusca*); Siberian Scoter (*Melanitta stejnegeri*); Common Scoter (*Melanitta nigra*); Black Scoter (*Melanitta americana*) ✓NPPSD; Common Goldeneye (*Bucephala clangula*) ✓NPPSD; Greater Scaup (*Aythya marila*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Red-breasted Merganser (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 23. Cullen et al. 2020

**Full citation:** Cullen, S. A., Jehl Jr., J.R., and Nuechterlein, G.L., 2020, Eared Grebe (Podiceps nigricollis), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.eargre.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Black-necked Grebe
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Black-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 24. Ewins 2020

**Full citation:** Ewins, P.J., 2020, Pigeon Guillemot (Cepphus columba), version 1.0, In Birds of the World (A. F. Poole and F. B. Gill, Editors), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.piggui.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Pigeon Guillemot
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Spectacled Guillemot (*Cepphus carbo*) ✓NPPSD
- Same family (7): Least Auklet (*Aethia pusilla*) ✓NPPSD; Whiskered Auklet (*Aethia pygmaea*) ✓NPPSD; Crested Auklet (*Aethia cristatella*) ✓NPPSD; Long-billed Murrelet (*Brachyramphus perdix*) ✓NPPSD; Kittlitz's Murrelet (*Brachyramphus brevirostris*) ✓NPPSD; Japanese Murrelet (*Synthliboramphus wumizusume*); Thick-billed Murre (*Uria lomvia*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Pigeon Guillemot (Kelsey: direct) |  |  |  |  |  |  |
| Spectacled Guillemot (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 25. Gremillet and Wilson 1999

**Full citation:** Gremillet, D., Wilson, R.P., 1999, A life in the fast lane: energetics and foraging strategies of the great cormorant, Behavioral Ecology, v. 10, no. 5, p. 516 – 524.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Pelagic Cormorant (GRCO)

Donor codes: GRCO = Great Cormorant

**Leads (gap species)**
- Same genus: Great Cormorant (*Phalacrocorax carbo*); Japanese Cormorant (*Phalacrocorax capillatus*)
- Same family (1): Little Pied Cormorant (*Microcarbo melanoleucos*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Pelagic Cormorant (GRCO) (Kelsey: proxy) |  |  |  |  |  |  |
| Great Cormorant (lead) |  |  |  |  |  |  |
| Japanese Cormorant (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 26. King et al. 1995

**Full citation:** King, D.T., Glahn, J.F., and Andrews, K.J., 1995, Daily activity budgets and movements of winter roosting Double-Crested Cormorants determined by biotelemetry in the delta region of Mississippi, Colonial Waterbirds, v. 18 p. 152 – 157.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Pelagic Cormorant (DCCO)

Donor codes: DCCO = Double-crested Cormorant

**Leads (gap species)**
- Same family (3): Little Pied Cormorant (*Microcarbo melanoleucos*); Great Cormorant (*Phalacrocorax carbo*); Japanese Cormorant (*Phalacrocorax capillatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Pelagic Cormorant (DCCO) (Kelsey: proxy) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 27. Park et al. 2024

**Full citation:** Park, J.-H., Jeong, I.-Y., Lee, S.-H., Yoo, J.-C., and Lee, W.-S., 2024, Changes in Flight Altitude of Black-Tailed Gulls According to Temporal and Environmental Differences, Animals 2024, v. 14, no. 202, [Available at: https://doi.org/10.3390/ani14020202]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Glaucous-winged Gull (BTGU)

Donor codes: BTGU = Black-tailed Gull

**Leads (gap species)**
- Same genus: Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); Black-tailed Gull (*Larus crassirostris*); Mew Gull (*Larus canus*); Lesser Black-backed Gull (*Larus fuscus*); Arctic Herring Gull (*Larus smithsonianus*); Slaty-backed Gull (*Larus schistisagus*) ✓NPPSD; Glaucous Gull (*Larus hyperboreus*) ✓NPPSD
- Same family (18): Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); aleutian tern (*Onychoprion aleuticus*); Sooty Tern (*Onychoprion fuscatus*); Bridled Tern (*Onychoprion anaethetus*); Grey-backed Tern (*Onychoprion lunatus*); Little Tern (*Sternula albifrons*); Fairy Tern (*Sternula nereis*); Australian Gull-billed Tern (*Gelochelidon macrotarsa*); Roseate Tern (*Sterna dougallii*); White-fronted Tern (*Sterna striata*); Black-naped Tern (*Sterna sumatrana*); Lesser Crested Tern (*Thalasseus bengalensis*); Chinese Crested Tern (*Thalasseus bernsteini*); Greater Crested Tern (*Thalasseus bergii*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Glaucous-winged Gull (BTGU) (Kelsey: proxy) |  |  |  |  |  |  |
| Brown-headed Gull (lead) |  |  |  |  |  |  |
| Black-headed Gull (lead) |  |  |  |  |  |  |
| Silver Gull (lead) |  |  |  |  |  |  |
| Pallas's Gull (lead) |  |  |  |  |  |  |
| Black-tailed Gull (lead) |  |  |  |  |  |  |
| Mew Gull (lead) |  |  |  |  |  |  |
| Lesser Black-backed Gull (lead) |  |  |  |  |  |  |
| Arctic Herring Gull (lead) |  |  |  |  |  |  |
| Slaty-backed Gull (lead) |  |  |  |  |  |  |
| Glaucous Gull (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 28. Pearce et al. 2020

**Full citation:** Pearce, J., Mallory, M.L., and Metz, K., 2020, Common Merganser (Mergus merganser), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.commer.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Goosander
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same family (10): Spectacled Eider (*Somateria fischeri*) ✓NPPSD; King Eider (*Somateria spectabilis*) ✓NPPSD; Common Eider (*Somateria mollissima*) ✓NPPSD; Steller's Eider (*Polysticta stelleri*) ✓NPPSD; Velvet Scoter (*Melanitta fusca*); Siberian Scoter (*Melanitta stejnegeri*); Common Scoter (*Melanitta nigra*); Black Scoter (*Melanitta americana*) ✓NPPSD; Common Goldeneye (*Bucephala clangula*) ✓NPPSD; Greater Scaup (*Aythya marila*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Goosander (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 29. Raine et al. 2021

**Full citation:** Raine, A.F., Gjerdrum, C., Pratte, I., Madeiros, J., Felis, J.F., and Adams, J., 2021, Marine distribution and foraging habitat highlight potential threats at-sea for the Endangered Bermuda petrel Pterodroma cahow, Endangered Species Research, v. 45, p. 337 – 356. [Available at: https://doi.org/10.3354/esr01139]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Hawaiian Petrel (BEPE)

Donor codes: BEPE = Beck's Petrel

**Leads (gap species)**
- Same genus: Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*)
- Same family (14): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD; Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Hawaiian Petrel (BEPE) (Kelsey: proxy) |  |  |  |  |  |  |
| Mascarene Petrel (lead) |  |  |  |  |  |  |
| Beck's petrel (lead) |  |  |  |  |  |  |
| Tahiti Petrel (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 30. Ravache et al. 2020

**Full citation:** Ravache, A., Bourgeois, K., Thibault, M., Dromzee, S., Weimerskirch, H., de Grissac, S., Prudor, A., Lorrain, A., Mekes, C., Allain, V., Bustamante, P., Letourneur, Y., and Vidal, E., 2020, Flying to the moon: Lunar cycle influences trip duration and nocturnal foraging behavior of the wedge-tailed shearwater Ardenna pacifica, Journal of Experimental Marine Biology and Ecology, v. 525, [Available at: https://doi.org/10.1016/j.jembe.2020.151322]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Sooty Shearwater (WTSH)

Donor codes: WTSH = Wedge-tailed Shearwater

**Leads (gap species)**
- Same genus: Wedge-tailed Shearwater (*Ardenna pacifica*) ✓NPPSD
- Same family (16): White-winged (Gould's) Petrel (*Pterodroma leucoptera*); Bonin Petrel (*Pterodroma hypoleuca*) ✓NPPSD; Black-winged Petrel (*Pterodroma nigripennis*) ✓NPPSD; Providence Petrel (*Pterodroma solandri*) ✓NPPSD; Kermadec Petrel (*Pterodroma neglecta*); Herald Petrel (*Pterodroma heraldica*); White-necked Petrel (*Pterodroma cervicalis*); Streaked Shearwater (*Calonectris leucomelas*) ✓NPPSD; Hutton's Shearwater (*Puffinus huttoni*); Tropical Shearwater (*Puffinus bailloni*); Bannerman's Shearwater (*Puffinus bannermani*); Heinroth's Shearwater (*Puffinus heinrothi*); Mascarene Petrel (*Pseudobulweria aterrima*); Beck's petrel (*Pseudobulweria becki*); Tahiti Petrel (*Pseudobulweria rostrata*); Bulwer's Petrel (*Bulweria bulwerii*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Sooty Shearwater (WTSH) (Kelsey: proxy) |  |  |  |  |  |  |
| Wedge-tailed Shearwater (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 31. Robertson and Goudie 2020

**Full citation:** Robertson, G.J. and Goudie, R.I., 2020, Harlequin Duck (Histrionicus histrionicus), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.harduc.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Harlequin Duck
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same family (10): Spectacled Eider (*Somateria fischeri*) ✓NPPSD; King Eider (*Somateria spectabilis*) ✓NPPSD; Common Eider (*Somateria mollissima*) ✓NPPSD; Steller's Eider (*Polysticta stelleri*) ✓NPPSD; Velvet Scoter (*Melanitta fusca*); Siberian Scoter (*Melanitta stejnegeri*); Common Scoter (*Melanitta nigra*); Black Scoter (*Melanitta americana*) ✓NPPSD; Common Goldeneye (*Bucephala clangula*) ✓NPPSD; Greater Scaup (*Aythya marila*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Harlequin Duck (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 32. Robertson and Savard 2020

**Full citation:** Robertson, G.J., and Savard, J.-P.L., 2020, Long-tailed Duck (Clangula hyemalis), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.lotduc.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Long-tailed Duck
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same family (10): Spectacled Eider (*Somateria fischeri*) ✓NPPSD; King Eider (*Somateria spectabilis*) ✓NPPSD; Common Eider (*Somateria mollissima*) ✓NPPSD; Steller's Eider (*Polysticta stelleri*) ✓NPPSD; Velvet Scoter (*Melanitta fusca*); Siberian Scoter (*Melanitta stejnegeri*); Common Scoter (*Melanitta nigra*); Black Scoter (*Melanitta americana*) ✓NPPSD; Common Goldeneye (*Bucephala clangula*) ✓NPPSD; Greater Scaup (*Aythya marila*) ✓NPPSD

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Long-tailed Duck (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 33. Ryan et al. 2009

**Full citation:** Ryan, P.G., Pichegru, L., Robert-Coudert, Y., Gremillet, D., and Kato, A., 2009, On a wing and a prayer: the foraging ecology of breeding Cape cormorants, Journal of Zoology, v. 280, p. 25 – 32. 

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Pelagic Cormorant (donor not specified)

**Leads (gap species)**
- Same family (3): Little Pied Cormorant (*Microcarbo melanoleucos*); Great Cormorant (*Phalacrocorax carbo*); Japanese Cormorant (*Phalacrocorax capillatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Pelagic Cormorant (donor not specified) (Kelsey: proxy) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 34. Shaffer et al. 2017

**Full citation:** Shaffer, S.A., Cockerham, S., Warzybok, P., Bradley, R.W., Jahncke, J., Clatterbuck, C.A., Lucia, M., Jelincic, J.A., Cassell, A.L., Kelsey, E.C., and Adams, J., 2017, Population-level plasticity in foraging behavior of western gulls (Larus occidentalis), Movement Ecology, v. 5, no. 27, doi.org/10.1186/s40462-017-0118-9.

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Glaucous-winged Gull (WEGU)

Donor codes: WEGU = Western Gull

**Leads (gap species)**
- Same genus: Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); Black-tailed Gull (*Larus crassirostris*); Mew Gull (*Larus canus*); Lesser Black-backed Gull (*Larus fuscus*); Arctic Herring Gull (*Larus smithsonianus*); Slaty-backed Gull (*Larus schistisagus*) ✓NPPSD; Glaucous Gull (*Larus hyperboreus*) ✓NPPSD
- Same family (18): Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); aleutian tern (*Onychoprion aleuticus*); Sooty Tern (*Onychoprion fuscatus*); Bridled Tern (*Onychoprion anaethetus*); Grey-backed Tern (*Onychoprion lunatus*); Little Tern (*Sternula albifrons*); Fairy Tern (*Sternula nereis*); Australian Gull-billed Tern (*Gelochelidon macrotarsa*); Roseate Tern (*Sterna dougallii*); White-fronted Tern (*Sterna striata*); Black-naped Tern (*Sterna sumatrana*); Lesser Crested Tern (*Thalasseus bengalensis*); Chinese Crested Tern (*Thalasseus bernsteini*); Greater Crested Tern (*Thalasseus bergii*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Glaucous-winged Gull (WEGU) (Kelsey: proxy) |  |  |  |  |  |  |
| Brown-headed Gull (lead) |  |  |  |  |  |  |
| Black-headed Gull (lead) |  |  |  |  |  |  |
| Silver Gull (lead) |  |  |  |  |  |  |
| Pallas's Gull (lead) |  |  |  |  |  |  |
| Black-tailed Gull (lead) |  |  |  |  |  |  |
| Mew Gull (lead) |  |  |  |  |  |  |
| Lesser Black-backed Gull (lead) |  |  |  |  |  |  |
| Arctic Herring Gull (lead) |  |  |  |  |  |  |
| Slaty-backed Gull (lead) |  |  |  |  |  |  |
| Glaucous Gull (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 35. Stedman 2020

**Full citation:** Stedman, S.J., 2020, Horned Grebe (Podiceps auritus), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.horgre.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Horned Grebe
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Horned Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 36. Stout and Nuechterlein 2020

**Full citation:** Stout, B.E. and Nuechterlein, G.L., 2020, Red-necked Grebe (Podiceps grisegena), version 1.0, In Birds of the World (S. M. Billerman, Editor), Cornell Lab of Ornithology, Ithaca, NY, USA. [Available at: https://doi.org/10.2173/bow.rengre.01]

**Type:** Birds of the World species account  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Red-necked Grebe
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Great Crested Grebe (*Podiceps cristatus*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Red-necked Grebe (Kelsey: direct) |  |  |  |  |  |  |
| Great Crested Grebe (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 37. VanDonk et al. 2018

**Full citation:** Van Donk, S., Shamoun-Baranes, J., Bouten, W., Van Der Meer, J., and Camphuysen, K.C.J., 2018, Individual differences in foraging site fidelity are not related to time-activity budgets in Herring Gulls, Ibis, v. 162, no. 2, p. 429 – 444. [Available at: https://doi.org/10.1111/ibi.12697]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (1): Glaucous-winged Gull (HERG)

Donor codes: HERG = Herring Gull

**Leads (gap species)**
- Same genus: Brown-headed Gull (*Larus brunnicephalus*); Black-headed Gull (*Larus ridibundus*); Silver Gull (*Larus novaehollandiae*); Pallas's Gull (*Larus ichthyaetus*); Black-tailed Gull (*Larus crassirostris*); Mew Gull (*Larus canus*); Lesser Black-backed Gull (*Larus fuscus*); Arctic Herring Gull (*Larus smithsonianus*); Slaty-backed Gull (*Larus schistisagus*) ✓NPPSD; Glaucous Gull (*Larus hyperboreus*) ✓NPPSD
- Same family (18): Brown Noddy (*Anous stolidus*); Lesser Noddy (*Anous tenuirostris*); Black Noddy (*Anous minutus*); Grey Noddy (*Anous albivittus*); Saunders's Gull (*Saundersilarus saundersi*); aleutian tern (*Onychoprion aleuticus*); Sooty Tern (*Onychoprion fuscatus*); Bridled Tern (*Onychoprion anaethetus*); Grey-backed Tern (*Onychoprion lunatus*); Little Tern (*Sternula albifrons*); Fairy Tern (*Sternula nereis*); Australian Gull-billed Tern (*Gelochelidon macrotarsa*); Roseate Tern (*Sterna dougallii*); White-fronted Tern (*Sterna striata*); Black-naped Tern (*Sterna sumatrana*); Lesser Crested Tern (*Thalasseus bengalensis*); Chinese Crested Tern (*Thalasseus bernsteini*); Greater Crested Tern (*Thalasseus bergii*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Glaucous-winged Gull (HERG) (Kelsey: proxy) |  |  |  |  |  |  |
| Brown-headed Gull (lead) |  |  |  |  |  |  |
| Black-headed Gull (lead) |  |  |  |  |  |  |
| Silver Gull (lead) |  |  |  |  |  |  |
| Pallas's Gull (lead) |  |  |  |  |  |  |
| Black-tailed Gull (lead) |  |  |  |  |  |  |
| Mew Gull (lead) |  |  |  |  |  |  |
| Lesser Black-backed Gull (lead) |  |  |  |  |  |  |
| Arctic Herring Gull (lead) |  |  |  |  |  |  |
| Slaty-backed Gull (lead) |  |  |  |  |  |  |
| Glaucous Gull (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 38. Weimerskirch et al. 2008

**Full citation:** Weimerskirch, H., Le Corre, M., and Bost, C.A., 2008, Foraging strategy of masked boobies from the largest colony in the world: relationship to environmental conditions and fisheries, Marine Ecology Progress Series, v. 362, p. 291 – 302. [Available at: https://doi.org/10.3354/meps07424]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Masked Booby
- As a similar-species source (0): (none)

**Leads (gap species)**
- Same genus: Brown Booby (*Sula leucogaster*) ✓NPPSD
- Same family (2): Abbott's Booby (*Papasula abbotti*); Australasian Gannet (*Morus serrator*)

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Masked Booby (Kelsey: direct) |  |  |  |  |  |  |
| Brown Booby (lead) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 39. Potiek et al. 2019

**Full citation:** Potiek, A., Collier, M.P., Schekkerman, H., Fijn, R.C., 2019, Effects of turbine collision mortality on population dynamics of 13 bird species, Bureau Waardenburg Report 18-342, Bureau Waardenburg, Culemborg. [Available at: https://www.noordzeeloket.nl/publish/pages/168793/effects_of_turbine_collision_mortality_on_population_dynamics_of_13_bird_species.pdf]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (0): (none)
- As a similar-species source (4): Arctic/Parasitic Jaeger (GRSK); Long-tailed Jaeger (GRSK); Pomarine Jaeger (GRSK); South Polar Skua (GRSK)

Donor codes: GRSK = Great Skua

**Leads (gap species)**
- none identified

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Arctic/Parasitic Jaeger (GRSK) (Kelsey: proxy) |  |  |  |  |  |  |
| Long-tailed Jaeger (GRSK) (Kelsey: proxy) |  |  |  |  |  |  |
| Pomarine Jaeger (GRSK) (Kelsey: proxy) |  |  |  |  |  |  |
| South Polar Skua (GRSK) (Kelsey: proxy) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 40. Conners et al. 2015

**Full citation:** Conners, M.G., Hazen, E.L. Costa, D.P., and Shaffer, S.A., 2015, Shadowed by scale: subtle behavioral niche partitioning in two sympatric, tropical breeding albatross species, Movement Ecology, v. 28. [Available at: https://doi.org/10.1186/s40462-015-0060-7]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (2): Black-footed Albatross; Laysan Albatross
- As a similar-species source (0): (none)

**Leads (gap species)**
- none identified

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Black-footed Albatross (Kelsey: direct) |  |  |  |  |  |  |
| Laysan Albatross (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 41. Bemmelen et al. 2016

**Full citation:** van Bemmelen, R.S.A, Hungar, J., Tulp, I., Klaassen, R.H.G., 2016, First geolocator tracks of Swedish red-necked phalaropes reveal the Sandinavia-Arabian Sea connection, Journal of Avian Biology, v. 47 p. 295 – 303. [Available at: https://doi.org/ 10.1111/jav.00807]

**Type:** Journal article / other  
**Status:** `[ ]`

**Kelsey cited it for**
- Directly (1): Red-necked Phalarope
- As a similar-species source (0): (none)

**Leads (gap species)**
- none identified

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| Red-necked Phalarope (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---

## 42. Bonnet-Lebrun et al. 2021 [as written: 2022]

**Full citation:** Bonnet-Lebrun, A.-S., Dias, M.P., Phillips, R.A., Granadeiro, J.P., Brooke, M.d.L., Chastel, O., Clay, T.A., Fayet, A.L., Gilg, O., González-Solís, J., Guilford, T., Hanssen, S.A., Hedd, A., Jaeger, A., Krietsch, J., Lang, J., Le Corre, M., Militão, T., Moe, B., Montevecchi, W.A., Peter, H.-U., Pinet, P., Rayner, M.J., Reid, T., Reyes-González, J.M., Ryan, P.G., Sagar, P.M., Schmidt, N.M., Thompson, D.R., van Bemmelen, R., Watanuki, Y., Weimerskirch, H., Yamamoto, T., and Catry, P., 2021, Seabird Migration Strategies: Flight Budgets, Diel Activity Patterns, and Lunar Influence, Frontiers in Marine Science, 8:683071. [Available at: http://doi: 10.3389/fmars.2021.683071]

**Type:** Journal article / other  
**Status:** `[~]` Same paper as section 4 (Kelsey's "2022" is a typo for 2021). White-tailed Tropicbird has no values in the paper; Kelsey's use appears to be a proxy for Red-tailed Tropicbird (see section 4).

**Kelsey cited it for**
- Directly (1): White-tailed Tropicbird
- As a similar-species source (0): (none)

**Leads (gap species)**
- none identified

**Data collection** (instrument/survey, years, location, sample):

> 

**Metric(s) addressed:** 

| species | metric | value | period | n | uncertainty | where in paper |
|---|---|---|---|---|---|---|
| White-tailed Tropicbird (Kelsey: direct) |  |  |  |  |  |  |

**Notes** (conversions, assumptions, anything odd):

> 

---
