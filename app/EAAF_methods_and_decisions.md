# EAAF Offshore Wind Bird Prioritization: Methods and Decisions

*Working draft. This page is meant to be linked from the Shiny app. Entries marked **[VERIFY]** or **[TODO]** still need a decision or a check before the app goes public.*

**Last updated:** 2026-11-04 (ESI added)

------------------------------------------------------------------------

## 1. What this tool does

The tool ranks birds that use the East Asian-Australasian Flyway (EAAF) by their relative priority for attention in the context of offshore wind energy development. It adapts the framework used for the U.S. Pacific Outer Continental Shelf (Kelsey et al. 2025, USGS Data Report 1214) to a flyway-scale species list.

Priority is the product of three components, each rescaled to 0.5-2 before multiplication, with user-adjustable exponents:

> Priority = Exposure\^w1 × Sensitivity\^w2 × Status\^w3

**[TODO]** Confirm that the EAAF version keeps the Pacific app's exact rescaling and exponent defaults.

## 2. Structure of the tool

| Decision | What we did | Why |
|----|----|----|
| Seabirds and non-seabirds are analyzed separately | Users pick a group; species are never ranked across groups | The two groups use different sensitivity inputs, so a combined ranking would compare unlike numbers |
| Users can choose input traits | Collision and displacement components can be built from selectable traits | Lets users see how the ranking changes with different assumptions (this is the point of the workshop) |
| Uncertainty | **[TODO]** Plan is to generate uncertainty windows around trait values and propagate them by Monte Carlo | No uncertainty is built into the underlying data yet |

## 3. Data sources

| Component | Source | Notes |
|----|----|----|
| Species list | **[TODO]** describe how the list was assembled (BirdLife EAAF list plus additions for residents) |  |
| Range maps | BirdLife International / IUCN range maps, with seasonal categories |  |
| Offshore wind | Global Energy Monitor, Global Wind Power Tracker (Feb 2026) | Operating and planned offshore facilities within the EAAF |
| IUCN status, population, trend | BirdLife Data Zone / IUCN Red List |  |
| Collision and displacement traits | Compiled from the literature; see the Metadata tab and Literature Cited tab of the species dataset | Follows Kelsey et al. 2025 for seabirds |
| Ecological Specialization Index (ESI) | BirdBase v2025.1 (Sekercioglu et al.) | Optional displacement input; matched on scientific name (see 5b) |

## 4. Exposure: how overlap with wind areas is calculated

1.  **Wind footprints.** Each offshore wind facility becomes a circle. Its area is the facility's capacity divided by an assumed capacity density:

    - fixed-bottom: **6 MW/km²**
    - floating: **3 MW/km²**
    - unknown mount type: **4.5 MW/km²** (the average of the two)
    - Basis: as-built Baltic projects average roughly 4.3-6.5 MW/km² (VASAB 2018); floating density assumption follows U.S. lease planning (BOEM/NREL).

2.  **Range maps.** Seasonal range polygons are clipped to the EAAF. Each polygon is assigned one of four seasons (resident, breeding, non-breeding, passage); other legend categories are excluded. **[VERIFY]** list the excluded legend categories exactly.

3.  **Seasonal overlap.** For each season, overlap is the area of the range covered by wind footprints divided by the area of the range. Areas are computed in an equal-area projection (Equal Earth, EPSG:8857).

4.  **Overall overlap.** A months-weighted mean of the seasonal percentages:

    P = Σ(m_c × p_c) / Σ(m_c)

    with weights m: resident 12, breeding 4, non-breeding 4, passage 4 (months).

5.  **Seasons with no mapped range are dropped, not counted as zero.**

### Assumptions and known limitations

- Birds are assumed to use their range **uniformly**. Overlap is area-based, not abundance-based.
- Footprints are circles at the facility point, not real lease boundaries or layouts.
- Species with very small ranges can have large, unstable overlap values from a single farm (e.g. Chinese Crested Tern: about 63% of one island patch overlaps a footprint, which drives the species' overall 24.6%). Interpret with care.
- Most overlaps are very small (the median seabird is about 0.05%), so the rescaling method matters. **[TODO]** document the final choice (log vs. rank vs. linear).
- Some species have no passage range mapped, so migration-stopover exposure is not captured for them. A "passage range mapped?" flag is included.

### Things we chose not to do (and why)

- **Raster-density approach.** We considered converting ranges to rasters, but stayed with polygons because the seasonal range maps are coarse polygons and a raster would add resolution that the data does not have.
- **Weighting by abundance or density within the range.** No consistent density surfaces exist for the whole flyway.

## 5. Sensitivity

### 5a. Collision vulnerability

- **Seabirds:** Collision Vulnerability (CV) follows Kelsey et al. 2025: a product of flight activity (FA), time in the rotor-swept zone (RSZt) and one minus macro-avoidance (MA), with an uncertainty term for each.
- **Non-seabirds:** **[TODO]** document the inputs used (Thaxter et al. 2017 model predictions; Woodward et al. 2023 collision-risk height and avoidance rates) and why.
- **[TODO]** Record the limits of the Thaxter et al. 2017 approach for this application.

#### Flight activity (FA): filling gaps from at-sea survey data

**Where FA comes from.** Kelsey et al. 2025 build FA from Birds of the World accounts, telemetry and logger studies (24-hour and nocturnal/diurnal values), and, for diurnal flight activity (DFA), the ratio of flying individuals to all individuals recorded in at-sea survey databases. The survey-database ratio is used only for species with more than 100 sightings, and not for species that spend much of their time on land (cormorants, terns), because the ratio is biased by birds on land that were not counted. The three databases are the North Pacific Pelagic Seabird Database (Drew et al. 2005, NPPSD v4.1; cited directly for 30 species in our table), PaCSEA (Adams et al. 2016) and the southern California aerial surveys (Takekawa et al. 2017).

**Current state of our data (Seabirds tab, v1.3).** 45 of 126 seabirds have an FA value (16 species-specific, 29 borrowed from a same-family species); 81 have none. FA_Reference is kept in Kelsey's format. A table of which citation supports which species is in `FA_citations_by_species.md`, with a gap/donor list in `FA_citations_and_gaps.xlsx`.

**What we are doing for gaps.** 1. Calculate the flying ratio ourselves from NPPSD v4.1 (script: `nppsd_flying_ratio.R`): flying individuals / (flying + on-water individuals), per species, pooled across surveys. Land and Unknown behavior records are dropped. Species need more than 100 birds, and cormorants/shags, terns and noddies are flagged and excluded. 2. Compare the NPPSD ratios with the DFA values already in our table, to check that our calculation reproduces Kelsey's. 3. Fill remaining gaps from congeners (then same-family species) already in the table, using the existing FA_actVSsimSpp codes (0.25 species, 0.5 same family, 0.75 other family or estimate).

**Decision: survey counting methods are pooled.** NPPSD records how flying birds were counted (`fly_bird_method`: Continuous, Snapshot, Not Specified). Continuous counts from a moving boat tend to overrepresent flying birds relative to sitting ones, so the ratio can be biased upward; snapshot counts are the cleaner version. We pool all methods to get the largest sample, so more species pass the 100-bird filter. The script also writes the ratio split by method, so the effect of pooling can be checked. - **Revisit if:** by-method ratios differ markedly (especially continuous well above snapshot for the same species), or pooled values disagree with Kelsey's DFA for shared species. To change it, set `methods_keep = c("Snapshot")` in the config block of the script and re-run; fewer species will pass the sample filter. - We do not know how Kelsey et al. handled counting method, so this is a departure only if they restricted it.

**Survey data sources skipped.** Adams et al. 2016 (PaCSEA aerial surveys) and Takekawa et al. 2017 are not used for DFA. Both are at-sea survey data like NPPSD, so they would only matter if they added gap species; the only gap species in their species lists are Velvet Scoter and Arctic Herring Gull, and NPPSD already supplies close proxies. Not worth the processing. Revisit only if the Herring Gull / Velvet Scoter proxies are rejected.

**Tracking-logger source: Bonnet-Lebrun et al. 2021.** Gives 24-hour percent time in flight (FA24) by phase (outward migration, non-breeding, return migration), with SD, for 21 seabird species. It does not tabulate day vs night flight, so it only feeds FA24, not NFA or DFA. Kelsey's sheet values show she used the non-breeding value for most species and all three phases for Leach's Storm-petrel; Decision: all phases are pooled for every species (each phase entered as its own value and fed to the median), not just the non-breeding phase Kelsey used for shearwaters and Pterodroma, because species pass through the EAAF at different stages of the annual cycle. Herring Gull: whatever Herring Gull form a paper reports is used directly for Arctic Herring Gull.

**Gulls and uncertainty.** Kelsey's published gull FA values are accepted as is (0.268 for the other gulls; 0.15 Herring Gull used for Arctic Herring Gull) rather than recomputed from the gull tracking papers. NPPSD DFA is kept next to FA24 for petrels that pass the \>100 birds check. FA uncertainty (source counts, actual vs similar species) is deliberately left off the gap-fill sheet until we decide how to handle it.

**Known quirks in the FA references.** Two FA_Reference entries say "Bonnet-Lebrun et al. 2022"; the Literature Cited tab only has 2021 (treated as a typo, not yet corrected in the sheet). One Literature Cited entry (Jakubas et al. 2014) is split across two rows. "Felis pers. comm." and "R. Carle pers. comm." have no Literature Cited entries.

**[TODO]** Record the final NPPSD results (species filled, how many pass the sample filter, agreement with Kelsey's DFA) once the script has been run. Frigatebirds (3 species) and the Common White Tern have no donor in our table and need literature or a no-data decision.

### 5b. Displacement vulnerability (seabirds)

Kelsey et al. 2025 define displacement vulnerability (Version 2) as:

> DV = Macro-avoidance (MA) × Habitat specificity (HS)

and habitat specificity as the average of **spatial specificity (SS)** and **foraging specificity (FS)**.

**What the tool offers.** Users pick one of two displacement options:

| Option | Formula | Notes |
|----|----|----|
| Default | DV = displacement rate | Displacement rate from Lamb et al. 2024 (taxon level; see "Displacement rate source" below). Called "MA" in Kelsey's equations |
| With ESI | DV = displacement rate × ESI | ESI replaces Kelsey's HS; combined multiplicatively, as in Kelsey Version 2 |

| Piece | Kelsey et al. 2025 | EAAF decision |
|----|----|----|
| MA | Proportion of birds displaced, from group-level published avoidance rates (flux-based macro-avoidance, mostly Krijgsveld et al. 2011 and related) | **Replaced for DV** by Lamb et al. 2024 taxon-level displacement (distributional change); Kelsey MA kept in the data for the collision side only |
| SS | Skewness of the species' modeled density distribution within the study region | **Not included** (see below) |
| FS | Count of foraging modes and prey size/trophic levels, rescaled | **Not included** (see below) |
| HS | Mean of SS and FS | Replaced by ESI, as an optional input |

#### About ESI

- **Source:** BirdBase v2025.1 (Sekercioglu et al.). ESI = log10(100 / [diet breadth × habitat breadth]), where diet breadth is the number of major food types consumed and habitat breadth is the number of major habitats used. The maximum is 2 (one food type, one habitat type); higher means more specialized.
- **Matching:** all 126 seabirds matched BirdBase on scientific name (BirdBase's BirdLife-aligned Latin names), with no missing ESI values. The BirdBase habitat breadth matched the habitat breadth already in our dataset for all 126.
- **Stored unscaled.** Any rescaling happens in the app, like the other components. Multiplying by ESI, which is always above 0, does not zero out DV for generalists.
- **What it is, and what it is not:** ESI measures general ecological specialization from coarse category counts across all birds. It is not specific to displacement from wind farms. In our seabird data it ranges from 0.55 to 2.0, but most species fall between about 1.1 and 1.4, so it modulates MA more than it competes with it.
- **Why it is optional:** it is a standardized, published index, which makes it more defensible than building our own, but its link to displacement is indirect. For the 29 seabirds shared with Kelsey's table, habitat breadth (one of its two inputs) had only a weak, wrong-direction rank correlation with Kelsey's HS (about +0.22; small sample, and their HS includes spatial specificity), so we do not treat ESI as reproducing their HS.
- **[TODO]** Decide how species with no ESI are handled when the option is on (drop vs. fall back to MA), and show the count excluded in the app. This is currently moot for seabirds (none missing).
- **[TODO]** Add ESI for non-seabirds if a displacement option is built for them. All 55 non-seabirds also match BirdBase.

#### Displacement rate source: Lamb et al. 2024

**Decision:** the displacement term in DV comes from the meta-analysis of Lamb et al. 2024 (*Environ. Impact Assess. Rev.* 108:107611), not from Kelsey's macro-avoidance values.

**Why** - Lamb measures what DV is meant to capture: change in bird density inside the wind farm compared with before-construction or control areas (BACI and gradient designs). Kelsey's MA is built from group-level avoidance rates (flux-based macro-avoidance from radar and visual studies, several of them defaults or borrowed from other groups) which describe flight-path avoidance and mix barrier, displacement and attraction (Cook et al. 2018). - The two literatures are not independent, so they cannot simply be pooled or cross-checked. Cook et al. 2012's Egmond rows are the Krijgsveld et al. 2011 values, which is also the main source behind Kelsey's MA. - Lamb reports a taxon-level effect with a 95% CI and the number of studies, which gives us something to propagate in the Monte Carlo.

**What goes in the data sheet (Seabirds tab, columns CD-CK), at taxon level** - Lamb taxon group, match tier, % change in use (mean, lower 95%, upper 95%), lnRR, number of studies, number of species (as reported by Lamb for that taxon). - Lower and upper 95% bounds are the published Table 3 values. **The mean % is derived**: exp(lnRR) - 1, because Table 3 lists only the CI in % form. - Negative % = decline (displacement). Displacement rate = -(% change)/100. - Every species in a Lamb group shares that group's values.

**How the tool will use it (Monte Carlo)** 1. Convert CI bounds to the lnRR scale: ln(1 + pct/100). 2. SD = (upper lnRR - lower lnRR) / 3.92. 3. Draw lnRR from a t distribution (df = n studies - 1), not a normal, because several groups rest on very few studies (Skuas 2, Fulmars 4, Waterfowl 4, Terns 5, Cormorants 6). **[TODO]** decide on a minimum df (3 is the current compromise; df = 1 makes the intervals about 6.5 times wider than a normal). 4. Back-transform: displacement = 1 - exp(draw). 5. **Floor at 0**: draws above 0 (attraction or no effect) are set to 0 displacement. The Kelsey framework has no negative displacement.

**Match tiers** (how a species was assigned to a Lamb group) \| Tier \| Meaning \| Count \| \|---\|---\|---\| \| A \| Species itself is in Lamb's data \| 18 \| \| B \| Congener in Lamb (same genus) \| 36 \| \| C \| Family or clade relative, genus not in Lamb \| 42 \| \| N \| Nothing in Lamb: **no data** (NA) \| 30 \|

We use Lamb's skua and fulmar groups. Skuas (n = 2 studies, 1 species, *Stercorarius skua*) apply to the other jaegers and the South Polar Skua; Fulmars (n = 4 studies, 2 species: Northern Fulmar and Manx Shearwater) apply to *Puffinus* shearwaters (Hutton's, Tropical, Bannerman's, Heinroth's). Both have very wide intervals (lnRR CI width about 3 and 2.9) and the extrapolation to unrelated species is weak.

**Known problems in the Lamb values** - **Gannets:** the published point estimate (lnRR -1.14, which converts to -68%) is outside its own published CI [-64%, -29%]. Probably a typo in Table 3. Unresolved; the supplement or the authors would settle it. - Table 3 may be raw or model-based; the supplement (Tables S1-S4) was not available to us. - Lamb's study base is almost entirely North Sea / NW Europe (mean latitudes 51-55 N). Transfer to the EAAF is an assumption. - Lamb could not weight studies by variance; Fig. 3a (probability of detecting an effect) reflects power and is not blended into the effect size. - Cormorants, gulls, terns and waterfowl have CIs that include 0 or an increase.

**Kelsey MA values retained but not used for now.** The Kelsey MA, its reference column (MA_Reference), uncertainty and the flux-based group rates stay in the data sheet. They are **not used for DV for now**; they remain the basis of the (1 - MA) term in collision vulnerability, which still rests on weak flux-based values (**[TODO]** revisit).

#### REMINDER: species with no Lamb data (30 of 126). Discuss in the workshop

These have no displacement value for now (shown as NA in the data sheet) because nothing close enough in Lamb covers them. The decision we are deferring is how to handle them (drop from the displacement score, a fallback value, expert elicitation, a Kelsey-style group default, etc.).

Groups: albatrosses, storm-petrels, gadfly and other petrels (*Pterodroma*, *Pseudobulweria*, *Bulweria*), frigatebirds, tropicbirds, and the Red-necked Phalarope.

- Red-tailed Tropicbird (*Phaethon rubricauda*)
- White-tailed Tropicbird (*Phaethon lepturus*)
- Wilson's Storm-petrel (*Oceanites oceanicus*)
- White-faced Storm-petrel (*Pelagodroma marina*)
- Black-bellied Storm-petrel (*Fregetta tropica*)
- New Caledonian Storm-petrel (*Fregetta lineata*)
- Matsudaira's Storm-petrel (*Hydrobates matsudairae*)
- Leach's Storm-petrel (*Hydrobates leucorhous*)
- Swinhoe's Storm-petrel (*Hydrobates monorhis*)
- Tristram's Storm-petrel (*Hydrobates tristrami*)
- Fork-tailed Storm-petrel (*Hydrobates furcatus*)
- Black-footed Albatross (*Phoebastria nigripes*)
- Laysan Albatross (*Phoebastria immutabilis*)
- Short-tailed Albatross (*Phoebastria albatrus*)
- White-winged (Gould's) Petrel (*Pterodroma leucoptera*)
- Bonin Petrel (*Pterodroma hypoleuca*)
- Black-winged Petrel (*Pterodroma nigripennis*)
- Providence Petrel (*Pterodroma solandri*)
- Kermadec Petrel (*Pterodroma neglecta*)
- Herald Petrel (*Pterodroma heraldica*)
- Hawaiian Petrel (*Pterodroma sandwichensis*)
- White-necked Petrel (*Pterodroma cervicalis*)
- Mascarene Petrel (*Pseudobulweria aterrima*)
- Beck's petrel (*Pseudobulweria becki*)
- Tahiti Petrel (*Pseudobulweria rostrata*)
- Bulwer's Petrel (*Bulweria bulwerii*)
- Lesser Frigatebird (*Fregata ariel*)
- Great Frigatebird (*Fregata minor*)
- Christmas Island Frigatebird (*Fregata andrewsi*)
- Red-necked Phalarope (*Phalaropus lobatus*)

#### FLAG FOR WORKSHOP SLIDES: stretched Lamb assignments (tier C, by choice)

These species have no close relative in Lamb but were deliberately assigned a Lamb group rather than left as no data. Treat their displacement values as extrapolations. - **Ardenna** shearwaters (Wedge-tailed, Buller's, Short-tailed, Sooty, Flesh-footed) and **Streaked Shearwater** (*Calonectris*) use the **Fulmars** group. Lamb's Fulmar group is Northern Fulmar and Manx Shearwater (4 studies), so this is a stretch for the Pacific *Ardenna*. - **Boobies** (Red-footed, Brown, Masked, Abbott's) use the **Gannets** group, which is one species (Northern Gannet) and carries the unresolved CI inconsistency noted above. - **Noddies** (Brown, Lesser, Black, Grey) and the **Common White Tern** use the **Terns** group. These are tropical and forage differently from the temperate terns in Lamb.

**Other tier C assignments:** Harlequin Duck and Steller's Eider to Sea ducks; Greater Scaup to Waterfowl; other auklets, murrelets and guillemots to Alcids; Microcarbo and Urile to Cormorants; Saunders's Gull to Gulls; Hydroprogne, Gelochelidon, Thalasseus and Onychoprion to Terns.

#### Why spatial specificity is left out

- **Skewness cannot be calculated.** It needs density surfaces. We only have presence/absence range polygons, which are coarse and have gaps, so a skewness value would not mean what it means in Kelsey.
- **We tested range size as a substitute and rejected it for now.**
  - Many seabird breeding polygons are small colony islands (e.g. Laysan Albatross 4.5 km², Buller's Shearwater 2.0 km²) and say nothing about how much at-sea habitat is available. A range-size proxy would rate many wide-ranging pelagic species as maximally specific.
  - Range areas span about five orders of magnitude, so any version needs a log transform and a robust rescale.
  - Small range already raises exposure (overlap is a percentage of range) and IUCN status, so a range-size term would count the same property three times in a multiplicative score.

#### Why foraging specificity is left out

- **Documented counts track research effort.** Well-studied species accumulate more recorded foraging modes and prey types and look like generalists; poorly studied species look like specialists because little is written down. This is a bias, and it is worst across a flyway with many data-poor species.
- **The categories are coarse.** Foraging mode and prey size each saturate at about four categories, and "small" and "large" forage fish count as separate prey types.
- **Documented repertoire is not realized flexibility.** A species that is only known to plunge-dive is not necessarily less able to adapt than one recorded using two methods.
- **Without SS it would carry the whole HS term.** In Kelsey it is averaged with SS; on its own, a noisy FS would be a full-strength multiplier.
- **Building it needs a large lit review for every species** and the payoff does not justify it.

#### Alternatives considered and rejected

- **EltonTraits diet and foraging data.** Percentages across broad diet types and foraging strategies are too coarse to translate into displacement sensitivity.

#### Open issue: combined sensitivity options

Collision vulnerability uses (1 − MA) and displacement vulnerability used MA, so MA entered both with opposite sign and the "summed" and "highest" options partly cancelled. Now that DV uses the Lamb displacement rate while CV keeps the Kelsey MA, the two share no input, which largely removes this. **[TODO]** Confirm that is acceptable and that the summed/highest options behave sensibly.

#### Reproducing Kelsey et al.

**[VERIFY]** In their Table 7, the reported DV values do not match MA × HS for the species we spot-checked (e.g. Black Tern: 0.486 × 0.783 ≈ 0.38, reported 0.020). Check against the report before citing their DV numbers.

## 6. Status

IUCN Red List category, converted to a number on the same 0.5-2 scale. **[TODO]** Document the category-to-number mapping.

## 7. Uncertainty

**[TODO]** Fill in once the approach is chosen.

## 8. Reading the outputs

**[TODO]** Describe the table, the priority score boxplot (by family), and the exposure-vs-sensitivity plot once they are built.

------------------------------------------------------------------------

## Decision log

| Date | Decision | Section |
|----|----|----|
| 2026-11-04 | Seabirds and non-seabirds analyzed separately, never ranked together | 2 |
| 2026-11-04 | Users can choose component traits for collision and displacement | 2 |
| 2026-11-04 | Spatial specificity (skewness) left out; range-size proxy rejected for now | 5b |
| 2026-11-04 | Foraging specificity (Kelsey method) left out: effort-confounded, coarse, large lit review for little payoff | 5b |
| 2026-11-04 | EltonTraits diet/foraging data rejected as a habitat-specificity proxy | 5b |
| 2026-11-04 | Displacement offered as two options: DV = MA (default) or DV = MA × ESI (BirdBase ESI, stored unscaled; multiplicative as in Kelsey V2) | 5b |
| 2026-11-04 | BirdBase ESI added to the seabird data (126 of 126 matched on scientific name) | 3, 5b |
| 2026-11-04 | Displacement term in DV taken from Lamb et al. 2024 taxon-level % change in use (not Kelsey MA); Kelsey MA kept for collision (1 - MA) only | 5b |
| 2026-11-04 | Lamb values stored as % change (mean derived from lnRR; published lower/upper 95% CI), plus lnRR, n studies, n species, at taxon level | 5b |
| 2026-11-04 | Monte Carlo to sample on lnRR scale with t distribution (df = n studies - 1), back-transform, floor displacement at 0 | 5b, 7 |
| 2026-11-04 | Species matched to Lamb groups in tiers A (species) / B (congener) / C (family relative); Lamb skua and fulmar groups used | 5b |
| 2026-11-04 | Species with nothing close in Lamb left as no data for now; to be discussed in the workshop (list in 5b) | 5b |
| 2026-11-04 | Ardenna/Calonectris assigned to Lamb Fulmars, boobies to Gannets, noddies and White Tern to Terns (tier C, flagged as stretched for workshop slides) | 5b |
| 2026-11-04 | Gannet Lamb CI inconsistency noted, not resolved | 5b |
| 2026-11-04 | Krijgsveld year artifacts (2012-2022) in MA_Reference corrected to 2011 in the data sheet (v1.3) | 5b |
| 2026-11-04 | FA gaps to be filled by calculating the flying ratio from NPPSD v4.1, then from congeners/same-family species; keep Kelsey's FA_Reference format | 5a |
| 2026-11-04 | NPPSD counting methods (Continuous, Snapshot, Not Specified) pooled for the flying ratio to maximize sample size; revisit if by-method ratios diverge | 5a |

## References

- Kelsey, E.C., Felis, J.J., Pereksta, D.M., and Adams, J., 2025, Revised marine bird collision and displacement vulnerability index for U.S. Pacific Outer Continental Shelf offshore wind energy development: U.S. Geological Survey Data Report 1214.
- Thaxter et al. 2017, *Proc. R. Soc. B*. **[TODO]** full citation
- Woodward et al. 2023. **[TODO]** full citation
- Global Energy Monitor, Global Wind Power Tracker, Feb 2026.
- VASAB 2018; BOEM/NREL floating wind planning reports. **[TODO]** full citations
- BirdLife International range maps and Data Zone.
- Drew, G.S., Schoen, S.K., Hood, M.D., Arimitsu, M.L., and Piatt, J.F., 2005, North Pacific Pelagic Seabird Database (NPPSD) (ver. 4.1, May 2023): U.S. Geological Survey data release, <https://doi.org/10.5066/F7WQ01T3>.
- Adams et al. 2016 (PaCSEA) and Takekawa et al. 2017 (southern California aerial surveys): see the Literature Cited tab for full citations.
- Lamb, J.S., et al., 2024, Meta-analysis of distributional change of marine birds following offshore wind farm construction: *Environmental Impact Assessment Review* 108:107611. **[TODO]** confirm full author list and title against the PDF.
- Krijgsveld, K.L., et al., 2011, Effect studies Offshore Wind Farm Egmond aan Zee: final report on fluxes, flight altitudes and behaviour of flying birds (Bureau Waardenburg). **[TODO]** confirm full citation.
- Cook, A.S.C.P., et al., 2012, Avoidance rates of seabirds and a review of avoidance behaviour: BTO Research Report 618. **[TODO]** confirm full citation.
- Cook, A.S.C.P., et al., 2018, A review of the avoidance, displacement and attraction concepts for seabirds at offshore wind farms. **[TODO]** confirm full citation.
- BirdBase v2025.1: Sekercioglu, C.H. et al. **[TODO]** full citation. ESI definition follows Sekercioglu 2011 as given in the BirdBase legend. **[TODO]** full citation

## Prototype app decisions (2026-11-05)

Files: `app.R`, `core_functions.R`, `plot_functions.R`, `seabird_test_data_v1.csv`. Point estimates only; all inputs are built as species x D matrices (D = 1) so uncertainty can be added by replacing the `build_*()` functions with samplers.

- **Priority** = Exposure\^w1 x Sensitivity\^w2 x Threat\^w3, each rescaled to 0.5-2; sliders 0-3, defaults 3, 2, 1 (as in the Pacific app).
- **Rescaling** = `log_rescale` (geometric map onto 0.5-2), applied across species that have every input the chosen settings need. Species missing an input are excluded and listed on the table tab.
- **Exposure** = `overlap_overall`; default transformed to log10 (zeros set to half the smallest non-zero value) before rescaling because the values span orders of magnitude. The Pacific app's exposure scaling is not known; OPEN, compare. A list column `overlap_draws` is used instead if present.
- **Threat** = IUCN ordinal LC 0, NT 1, VU 2, EN 3, CR 4, then rescaled (LC 0.5, CR 2). DD/NE dropped. OPEN: ordinal spacing is a choice.
- **Collision** = FA x RSZt x (1 - MA). MA from Kelsey (published) or "Lamb" = Lamb displacement rate (floored at 0) substituted for MA with identical math. The Lamb option is a comparison, not a validated avoidance rate.
- **Displacement** = Lamb rate = max(0, -% change/100), optionally x ESI. Lamb match tiers A/B/C can be switched off.
- **Combining**: collision and displacement each rescaled 0-1, then collision / displacement / max / sum, then `log_rescale`.
- **Central values** are geometric means (identical to the value itself while D = 1). Intervals are shown only when D \> 1.
- Seabirds only; non-seabirds are never ranked with them.
