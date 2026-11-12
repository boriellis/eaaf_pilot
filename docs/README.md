# EAAF Offshore Wind Bird Prioritization: Methods and Decisions

*Working draft. This page is meant to be linked from the Shiny app. Entries marked **[VERIFY]** or **[TODO]** still need a decision or a check before the app goes public.*

**Last updated:** 2026-11-04 (ESI added)

---

## 1. What this tool does

The tool ranks birds that use the East Asian-Australasian Flyway (EAAF) by their relative priority for attention in the context of offshore wind energy development. It adapts the framework used for the U.S. Pacific Outer Continental Shelf (Kelsey et al. 2025, USGS Data Report 1214) to a flyway-scale species list.

Priority is the product of three components, each rescaled to 0.5-2 before multiplication, with user-adjustable exponents:

> Priority = Exposure^w1 × Sensitivity^w2 × Status^w3

**[TODO]** Confirm that the EAAF version keeps the Pacific app's exact rescaling and exponent defaults.

## 2. Structure of the tool

| Decision | What we did | Why |
|---|---|---|
| Seabirds and non-seabirds are analyzed separately | Users pick a group; species are never ranked across groups | The two groups use different sensitivity inputs, so a combined ranking would compare unlike numbers |
| Users can choose input traits | Collision and displacement components can be built from selectable traits | Lets users see how the ranking changes with different assumptions (this is the point of the workshop) |
| Uncertainty | **[TODO]** Plan is to generate uncertainty windows around trait values and propagate them by Monte Carlo | No uncertainty is built into the underlying data yet |

## 3. Data sources

| Component | Source | Notes |
|---|---|---|
| Species list | **[TODO]** describe how the list was assembled (BirdLife EAAF list plus additions for residents) | |
| Range maps | BirdLife International / IUCN range maps, with seasonal categories | |
| Offshore wind | Global Energy Monitor, Global Wind Power Tracker (Feb 2026) | Operating and planned offshore facilities within the EAAF |
| IUCN status, population, trend | BirdLife Data Zone / IUCN Red List | |
| Collision and displacement traits | Compiled from the literature; see the Metadata tab and Literature Cited tab of the species dataset | Follows Kelsey et al. 2025 for seabirds |
| Ecological Specialization Index (ESI) | BirdBase v2025.1 (Sekercioglu et al.) | Optional displacement input; matched on scientific name (see 5b) |

## 4. Exposure: how overlap with wind areas is calculated

1. **Wind footprints.** Each offshore wind facility becomes a circle. Its area is the facility's capacity divided by an assumed capacity density:
   - fixed-bottom: **6 MW/km²**
   - floating: **3 MW/km²**
   - unknown mount type: **4.5 MW/km²** (the average of the two)
   - Basis: as-built Baltic projects average roughly 4.3-6.5 MW/km² (VASAB 2018); floating density assumption follows U.S. lease planning (BOEM/NREL).
2. **Range maps.** Seasonal range polygons are clipped to the EAAF. Each polygon is assigned one of four seasons (resident, breeding, non-breeding, passage); other legend categories are excluded. **[VERIFY]** list the excluded legend categories exactly.
3. **Seasonal overlap.** For each season, overlap is the area of the range covered by wind footprints divided by the area of the range. Areas are computed in an equal-area projection (Equal Earth, EPSG:8857).
4. **Overall overlap.** A months-weighted mean of the seasonal percentages:

   P = Σ(m_c × p_c) / Σ(m_c)

   with weights m: resident 12, breeding 4, non-breeding 4, passage 4 (months).
5. **Seasons with no mapped range are dropped, not counted as zero.**

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

**What we are doing for gaps.**
1. Calculate the flying ratio ourselves from NPPSD v4.1 (script: `nppsd_flying_ratio.R`): flying individuals / (flying + on-water individuals), per species, pooled across surveys. Land and Unknown behavior records are dropped. Species need more than 100 birds, and cormorants/shags, terns and noddies are flagged and excluded.
2. Compare the NPPSD ratios with the DFA values already in our table, to check that our calculation reproduces Kelsey's.
3. Fill remaining gaps from congeners (then same-family species) already in the table, using the existing FA_actVSsimSpp codes (0.25 species, 0.5 same family, 0.75 other family or estimate).

**Decision: survey counting methods are pooled.** NPPSD records how flying birds were counted (`fly_bird_method`: Continuous, Snapshot, Not Specified). Continuous counts from a moving boat tend to overrepresent flying birds relative to sitting ones, so the ratio can be biased upward; snapshot counts are the cleaner version. We pool all methods to get the largest sample, so more species pass the 100-bird filter. The script also writes the ratio split by method, so the effect of pooling can be checked.
- **Revisit if:** by-method ratios differ markedly (especially continuous well above snapshot for the same species), or pooled values disagree with Kelsey's DFA for shared species. To change it, set `methods_keep = c("Snapshot")` in the config block of the script and re-run; fewer species will pass the sample filter.
- We do not know how Kelsey et al. handled counting method, so this is a departure only if they restricted it.

**Survey data sources skipped.** Adams et al. 2016 (PaCSEA aerial surveys) and Takekawa et al. 2017 are not used for DFA. Both are at-sea survey data like NPPSD, so they would only matter if they added gap species; the only gap species in their species lists are Velvet Scoter and Arctic Herring Gull, and NPPSD already supplies close proxies. Not worth the processing. Revisit only if the Herring Gull / Velvet Scoter proxies are rejected.

**Tracking-logger source: Bonnet-Lebrun et al. 2021.** Gives 24-hour percent time in flight (FA24) by phase (outward migration, non-breeding, return migration), with SD, for 21 seabird species. It does not tabulate day vs night flight, so it only feeds FA24, not NFA or DFA. Kelsey's sheet values show she used the non-breeding value for most species and all three phases for Leach's Storm-petrel; Decision: all phases are pooled for every species (each phase entered as its own value and fed to the median), not just the non-breeding phase Kelsey used for shearwaters and Pterodroma, because species pass through the EAAF at different stages of the annual cycle. Herring Gull: whatever Herring Gull form a paper reports is used directly for Arctic Herring Gull.

**Gulls and uncertainty.** Kelsey's published gull FA values are accepted as is (0.268 for the other gulls; 0.15 Herring Gull used for Arctic Herring Gull) rather than recomputed from the gull tracking papers. NPPSD DFA is kept next to FA24 for petrels that pass the >100 birds check. FA uncertainty (source counts, actual vs similar species) is deliberately left off the gap-fill sheet until we decide how to handle it.

**Known quirks in the FA references.** Two FA_Reference entries say "Bonnet-Lebrun et al. 2022"; the Literature Cited tab only has 2021 (treated as a typo, not yet corrected in the sheet). One Literature Cited entry (Jakubas et al. 2014) is split across two rows. "Felis pers. comm." and "R. Carle pers. comm." have no Literature Cited entries.

**[TODO]** Record the final NPPSD results (species filled, how many pass the sample filter, agreement with Kelsey's DFA) once the script has been run. Frigatebirds (3 species) and the Common White Tern have no donor in our table and need literature or a no-data decision.

### 5b. Displacement vulnerability (seabirds)
Kelsey et al. 2025 define displacement vulnerability (Version 2) as:

> DV = Macro-avoidance (MA) × Habitat specificity (HS)

and habitat specificity as the average of **spatial specificity (SS)** and **foraging specificity (FS)**.

**What the tool offers.** Users pick one of two displacement options:

| Option | Formula | Notes |
|---|---|---|
| Default | DV = displacement rate | Displacement rate from Lamb et al. 2024 (taxon level; see "Displacement rate source" below). Called "MA" in Kelsey's equations |
| With ESI | DV = displacement rate × ESI | ESI replaces Kelsey's HS; combined multiplicatively, as in Kelsey Version 2 |

| Piece | Kelsey et al. 2025 | EAAF decision |
|---|---|---|
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

**Why**
- Lamb measures what DV is meant to capture: change in bird density inside the wind farm compared with before-construction or control areas (BACI and gradient designs). Kelsey's MA is built from group-level avoidance rates (flux-based macro-avoidance from radar and visual studies, several of them defaults or borrowed from other groups) which describe flight-path avoidance and mix barrier, displacement and attraction (Cook et al. 2018).
- The two literatures are not independent, so they cannot simply be pooled or cross-checked. Cook et al. 2012's Egmond rows are the Krijgsveld et al. 2011 values, which is also the main source behind Kelsey's MA.
- Lamb reports a taxon-level effect with a 95% CI and the number of studies, which gives us something to propagate in the Monte Carlo.

**What goes in the data sheet (Seabirds tab, columns CD-CK), at taxon level**
- Lamb taxon group, match tier, % change in use (mean, lower 95%, upper 95%), lnRR, number of studies, number of species (as reported by Lamb for that taxon).
- Lower and upper 95% bounds are the published Table 3 values. **The mean % is derived**: exp(lnRR) - 1, because Table 3 lists only the CI in % form.
- Negative % = decline (displacement). Displacement rate = -(% change)/100.
- Every species in a Lamb group shares that group's values.

**How the tool will use it (Monte Carlo)**
1. Convert CI bounds to the lnRR scale: ln(1 + pct/100).
2. SD = (upper lnRR - lower lnRR) / 3.92.
3. Draw lnRR from a t distribution (df = n studies - 1), not a normal, because several groups rest on very few studies (Skuas 2, Fulmars 4, Waterfowl 4, Terns 5, Cormorants 6). **[TODO]** decide on a minimum df (3 is the current compromise; df = 1 makes the intervals about 6.5 times wider than a normal).
4. Back-transform: displacement = 1 - exp(draw).
5. **Floor at 0**: draws above 0 (attraction or no effect) are set to 0 displacement. The Kelsey framework has no negative displacement.

**Match tiers** (how a species was assigned to a Lamb group)
| Tier | Meaning | Count |
|---|---|---|
| A | Species itself is in Lamb's data | 18 |
| B | Congener in Lamb (same genus) | 36 |
| C | Family or clade relative, genus not in Lamb | 42 |
| N | Nothing in Lamb: **no data** (NA) | 30 |

We use Lamb's skua and fulmar groups. Skuas (n = 2 studies, 1 species, *Stercorarius skua*) apply to the other jaegers and the South Polar Skua; Fulmars (n = 4 studies, 2 species: Northern Fulmar and Manx Shearwater) apply to *Puffinus* shearwaters (Hutton's, Tropical, Bannerman's, Heinroth's). Both have very wide intervals (lnRR CI width about 3 and 2.9) and the extrapolation to unrelated species is weak.

**Known problems in the Lamb values**
- **Gannets:** the published point estimate (lnRR -1.14, which converts to -68%) is outside its own published CI [-64%, -29%]. Probably a typo in Table 3. Unresolved; the supplement or the authors would settle it.
- Table 3 may be raw or model-based; the supplement (Tables S1-S4) was not available to us.
- Lamb's study base is almost entirely North Sea / NW Europe (mean latitudes 51-55 N). Transfer to the EAAF is an assumption.
- Lamb could not weight studies by variance; Fig. 3a (probability of detecting an effect) reflects power and is not blended into the effect size.
- Cormorants, gulls, terns and waterfowl have CIs that include 0 or an increase.

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
These species have no close relative in Lamb but were deliberately assigned a Lamb group rather than left as no data. Treat their displacement values as extrapolations.
- **Ardenna** shearwaters (Wedge-tailed, Buller's, Short-tailed, Sooty, Flesh-footed) and **Streaked Shearwater** (*Calonectris*) use the **Fulmars** group. Lamb's Fulmar group is Northern Fulmar and Manx Shearwater (4 studies), so this is a stretch for the Pacific *Ardenna*.
- **Boobies** (Red-footed, Brown, Masked, Abbott's) use the **Gannets** group, which is one species (Northern Gannet) and carries the unresolved CI inconsistency noted above.
- **Noddies** (Brown, Lesser, Black, Grey) and the **Common White Tern** use the **Terns** group. These are tropical and forage differently from the temperate terns in Lamb.

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

---

## Decision log

| Date | Decision | Section |
|---|---|---|
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
- Drew, G.S., Schoen, S.K., Hood, M.D., Arimitsu, M.L., and Piatt, J.F., 2005, North Pacific Pelagic Seabird Database (NPPSD) (ver. 4.1, May 2023): U.S. Geological Survey data release, https://doi.org/10.5066/F7WQ01T3.
- Adams et al. 2016 (PaCSEA) and Takekawa et al. 2017 (southern California aerial surveys): see the Literature Cited tab for full citations.
- Lamb, J.S., et al., 2024, Meta-analysis of distributional change of marine birds following offshore wind farm construction: *Environmental Impact Assessment Review* 108:107611. **[TODO]** confirm full author list and title against the PDF.
- Krijgsveld, K.L., et al., 2011, Effect studies Offshore Wind Farm Egmond aan Zee: final report on fluxes, flight altitudes and behaviour of flying birds (Bureau Waardenburg). **[TODO]** confirm full citation.
- Cook, A.S.C.P., et al., 2012, Avoidance rates of seabirds and a review of avoidance behaviour: BTO Research Report 618. **[TODO]** confirm full citation.
- Cook, A.S.C.P., et al., 2018, A review of the avoidance, displacement and attraction concepts for seabirds at offshore wind farms. **[TODO]** confirm full citation.
- BirdBase v2025.1: Sekercioglu, C.H. et al. **[TODO]** full citation. ESI definition follows Sekercioglu 2011 as given in the BirdBase legend. **[TODO]** full citation

## Prototype app decisions (2026-11-05)

Files: `app.R`, `core_functions.R`, `plot_functions.R`, `seabird_test_data_v1.csv`. Point estimates only; all inputs are built as species x D matrices (D = 1) so uncertainty can be added by replacing the `build_*()` functions with samplers.

- **Priority** = Exposure^w1 x Sensitivity^w2 x Threat^w3, each rescaled to 0.5-2; sliders 0-3, defaults 3, 2, 1 (as in the Pacific app).
- **Rescaling** = `log_rescale` (geometric map onto 0.5-2), applied across species that have every input the chosen settings need. Species missing an input are excluded and listed on the table tab.
- **Exposure** = `overlap_overall`; default transformed to log10 (zeros set to half the smallest non-zero value) before rescaling because the values span orders of magnitude. The Pacific app's exposure scaling is not known; OPEN, compare. A list column `overlap_draws` is used instead if present.
- **Threat** = IUCN ordinal LC 0, NT 1, VU 2, EN 3, CR 4, then rescaled (LC 0.5, CR 2). DD/NE dropped. OPEN: ordinal spacing is a choice.
- **Collision** = FA x RSZt x (1 - MA). MA from Kelsey (published) or "Lamb" = Lamb displacement rate (floored at 0) substituted for MA with identical math. The Lamb option is a comparison, not a validated avoidance rate.
- **Displacement** = Lamb rate = max(0, -% change/100), optionally x ESI. Lamb match tiers A/B/C can be switched off.
- **Combining**: collision and displacement each rescaled 0-1, then collision / displacement / max / sum, then `log_rescale`.
- **Central values** are geometric means (identical to the value itself while D = 1). Intervals are shown only when D > 1.
- Seabirds only; non-seabirds are never ranked with them.

## Flight activity: interpretation and gap-fill decisions (2026-11-11)

- **What FA measures (rule adopted).** Following Kelsey et al. 2025, FA is the proportion of time in flight as opposed to on land or on the water, a time budget rather than "flying given that it is in the lease area." Regular daily land roosting counts as not flying (as for her cormorants, terns, gulls and pelicans: NFA 0.001 where no species data). Breeding-colony attendance is not corrected for, which she also lists as a limitation of survey-derived DFA.
- **Kelsey values for species in her dataset** were checked against the v1.3 sheet (44 species in both): all match except Black Scoter, whose FA block was not copied and whose MA differs (sheet 0.735, Kelsey 0.9). Previously "unreproducible" NFA values (Laysan Albatross 0.595, Red-tailed Tropicbird 0.17, alcids 0.027) are Kelsey's published values.
- **Stray NFA values** (21 tubenose species, NFA only, no source) are not Kelsey's and were present in earlier sheet versions. They are to be overwritten with gap-fill values on merge.
- **Combined donors** (Kelsey approach: median of donor species values per metric; grebes averaged): Abbott's Booby and Australasian Gannet from Masked and Brown Booby; Great Crested Grebe from Kelsey's five grebes; Arctic Loon NFA 0.001 from Kelsey's loons with its own NPPSD DFA; Pseudobulweria from Bulwer's Petrel DFA and FA24; Little Pied, Great and Japanese Cormorant from Kelsey's three cormorants; Velvet, Siberian and Common Scoter from Kelsey's White-winged, Black and Surf Scoter.
- **Frigatebirds (Lesser, Great, Christmas Island): expert judgement, not measured.** DFA 0.80-0.95, NFA 0.25-0.80, midpoints used (DFA 0.875, NFA 0.525, FA 0.70). Basis: Great Frigatebirds stay aloft for weeks to months with only short rests on land (Weimerskirch et al. 2016); Ascension Frigatebirds cannot rest on water (Clark et al. 2019); but birds near colonies roost on land at night, sometimes in the thousands (Birds of the World). Flag on workshop slides. Suggested check: run the app with frigatebird FA at 1.0 and at 0.70 to see whether rank changes.
- **Open:** Gannet CI in Lamb Table 3 (email to author pending; lnRR -1.14 kept, CI likely centred wrongly, corrected CI about -77% to -55%); six DFA-only species (Spectacled, King, Common and Steller's Eider, Common Goldeneye, Greater Scaup).
- 2026-11-11 update: eiders filled from Kelsey's scoter values; Common Goldeneye and Greater Scaup from Kelsey's other sea ducks (mergansers, Long-tailed Duck, Harlequin Duck). All 81 gap species now have FA.

## All-species dataset, Data limited tab, and related decisions (2026-11-11)

- **Datasets.** `seabird_test_data_v2.csv` (106 complete-case species, built from the v1.4 sheet) replaced the 34-species v1 test set. `seabird_all_species_v1.csv` (+ `_dictionary.csv`) now holds all 126 species on the Seabirds tab, with NA for missing values. Added columns: `family`, `tax_index` (family order, then scientific name), `fa_fill_tier` (how FA was obtained), `data_complete`, `missing_fields`. `data_complete`/`missing_fields` use a fixed field list (including population trend); the app does not use them and works out data limitation itself for each setting.
- **Data limited tab (supersedes the old "excluded species" note).** A species is ranked only if it has every input the chosen sensitivity setting needs: exposure and threat always; collision (FA, RSZt, MA) for collision only; displacement (Lamb rate, plus ESI if selected, within the selected Lamb tiers) for displacement only; both for "higher of the two" and "sum". So the number of data-limited species depends on the setting (with the all-species CSV and default options: collision only 13, displacement only 10, higher/sum 20). The tab shows raw values and rescaled values for whatever a species has, NA for the rest, and a "Missing for these settings" column naming the fields.
- **Rescaling (changes the 2026-11-05 entry).** Each component is rescaled across every species that has that component, not only across species that will be ranked. Data-limited species therefore get rescaled values on the same scale as ranked species, but the ranked set need not span exactly 0.5-2 on exposure and threat. Decision: keep this (user agreed 2026-11-11). Old masking code is kept commented out in `scale_inputs`.
- **NA^0 guard.** In R `NA^0` is 1, so weighted components are set to NA explicitly and priority is forced to NA for non-ranked species; otherwise a weight of 0 would score species with missing data.
- **Mascarene Petrel and Hawaiian Petrel: overlap stays NA.** The sheet's definition of NA is "no included range in the EAAF" (no clipped range polygon in any season). The user decided to keep NA, not 0, because some estimates do overlap these species with the flyways but the range polygons available are incomplete. They are data limited under every setting, because of the range data, not because they are out of scope. Describe them that way in workshop materials.
- **Saunders's Gull.** RSZt filled by the user from the small-gull aggregate. Options considered: Kelsey's small gulls (Sabine's, Bonaparte's) RSZt 0.070 (0.038-0.180), MA 0.283; all Kelsey gulls mean 0.252 / median 0.266, MA 0.298. OPEN: the sheet's Black-headed, Brown-headed, Silver, Mew, Black-tailed and Pallas's Gulls carry the large-gull value (0.35, MA 0.298) and arguably belong with the small-gull value, which would lower their collision score about five-fold. Not changed.
- **Lamb gannet row.** Table 3 gannet row is internally inconsistent (lnRR -1.14 = -68%, but the CI is centred on lnRR -0.68). lnRR -1.14 kept; the CI is probably wrong, reconstructed about -77.2% to -55.1% (lnRR -1.48 to -0.80). Email to the author drafted; reply pending. Datasheet CI not yet changed.
- **Lamb uncertainty plan.** For uncertainty later, draw per-taxon displacement from the lnRR and its CI (the lnRR scale is the symmetric one), after the gannet CI is settled. Not implemented.
- **Open items.** Bulwer's Petrel has a Lamb % change but a lamb_tier other than A/B/C, so displacement leaves it out as "Lamb tier not selected": check the tier label. DD species (one) is dropped under every setting because threat has no score. R code is still untested. Missing RSZt/MA remain for noddies, Common White Tern, and RSZt for Lesser Black-backed Gull, Aleutian, Sooty, Bridled and Grey-backed Terns. Frigatebird FA 0.70 should be sensitivity-checked against 1.0 in the app.

#### FLAG FOR WORKSHOP SLIDES: range polygons, BirdLife/IUCN vs Birds of the World (2026-11-11)

- **Issue.** Exposure depends on range polygons, and the IUCN/BirdLife polygons we had are incomplete for many seabirds (offshore and non-breeding ranges especially; see Mascarene and Hawaiian Petrel, overlap NA). Birds of the World (BOW) distribution pages carry separate breeding and non-breeding polygons, credited "BirdLife International and Cornell Lab of Ornithology (in review)", that are often much more complete. They are not available as vector data (eBird Status and Trends does not predict over open sea, so it is not a substitute), and digitizing them was judged not attainable for this project. Using BOW polygons would need a data request to BOW/BirdLife, and the licence terms apply.
- **Slide: three example screenshots (BOW vs IUCN side by side).**
  1. **Hawaiian Petrel**: BOW makes a large difference. IUCN has one resident/breeding blob east of the date line; BOW has a small breeding area around the main Hawaiian Islands plus a non-breeding range from Taiwan to the Pacific Northwest.
  2. **Chinese Crested Tern**: BOW improves the range somewhat but does not fully fix it.
  3. **Arctic Tern**: BOW and IUCN share similar gaps for this species.
- **Discussion points.** Where polygons are incomplete, what are the options (leave as NA / data limited, sea sketch elicitation with experts to draw the missing at-sea ranges, requesting updated BirdLife/BOW ranges, tracking data)? What the BOW contribution is and how it was made (appears to be literature review plus bird data; not confirmed). Why the data-limited tab matters here: species with poor ranges are shown as data limited and not given a misleading low exposure.

## Global seasons mapped (2026-11-12)

- **New column "Seasons mapped (global)"** (last column on both the Seabirds and non-seabirds tabs of `TBC_offline_backup_v1.5.xlsx`, documented on the Metadata tab): seasons with an included range polygon anywhere, not clipped to the EAAF, from `exposure_scratch.R` Part 12 (same `include` rule as the EAAF seasons). Intended as a range-map completeness indicator; unlike "Seasons mapped (EAAF)" it does not feed the overlap formula. All 126 seabirds and 55 non-seabirds matched.
- **Uncertainty from seasons: deferred.** Turning this into an exposure-uncertainty metric needs a rule for the seasons a species should have; judged too complex for now. For now the column is descriptive only: shown in the app tables and plot hover text with the migratory status (1-3).
- **App data** is now `seabird_all_species_v2.csv` (adds `seasons_mapped_global`; Bulwer's Petrel Lamb tier updated from N to C in the sheet).

## Non-seabirds: collision sensitivity (2026-11-12)

**Decision.** The non-seabirds tab will offer two options for the collision component; the user picks one:
1. **Thaxter:** collision = Thaxter et al. 2017 predicted collision vulnerability (sheet column "Thaxter 2017 Predicted").
2. **Flight height x avoidance:** collision = proportion at collision risk height x (1 - avoidance rate), both from Woodward et al. 2023 (sheet columns "Proportion at Collision Risk Height" and "Avoidance rate").

Whichever option is chosen is rescaled 0-1 across the non-seabirds that have it (same `rescale_01` as the seabird collision and displacement components), then combined with displacement (or not) using the same collision / displacement / higher of the two / sum options as for seabirds, and the combined sensitivity is rescaled 0.5-2 (`log_rescale`). Exposure and threat are the same as for seabirds. Non-seabirds are never ranked with seabirds. A species missing the selected collision option goes to the Data limited tab when the sensitivity setting needs collision, as for seabirds. **App code is not to be changed until displacement for non-seabirds has been worked through.**

**Where option 1 comes from (Thaxter et al. 2017, Proc. R. Soc. B 284: 20170829).**
- Predicted collisions per turbine per year from a Bayesian zero-adjusted Poisson mixed model (MCMCglmm), fitted to carcass counts from 88 bird studies at 93 ONSHORE wind farms (133 found); 362 bird species recorded as collision victims plus 407 pseudo-absences (species whose breeding-range polygons overlap but that were not recorded). Predicted for 9,568 species at the highest study-quality level over 365 days, marginal to the study random effect. Treated by the authors as the collision vulnerability index. Upper/Lower in the sheet are presumably the 95% credible intervals from the supplementary predictions file (not verified; the supplement was not seen).
- Fixed effects: habitat (artificial and grassland higher, marine lower), diet, foraging stratum, migratory status, dispersal distance, Kipp's distance, body mass, population size, turbine MW (strong positive) and study quality. Habitat is the main trait signal. Migrants higher but the mean effect just overlaps zero (significant in 1 of 7 models). Dispersal distance is non-monotonic (25-99 km highest); the authors suggest long dispersers may fly higher. Fixed effects explain about 46% of variance; with study and phylogeny about 85%, so predictions for little-studied species lean on relatives.
- Data are about 64% North America and 31% Europe; Japan is the only East Asian country mentioned.
- **Concerns for offshore / over-ocean migration:** no offshore collision data (only 5% of studies had marine species at coastal wind farms; the negative marine coefficient is attributed by the authors to that gap); no flight height, speed, night flying or avoidance; migratory status is an onshore species-level label, not over-water passage; population size and range presence enter as abundance proxies, so part of the index is encounter rate and partly double-counts our wind-overlap exposure axis. Intervals are very wide (e.g. Whimbrel 0.019, 0.0002-0.082).

**Where option 2 comes from (Woodward et al. 2023, JNCC / ScotMER strategic review of birds on migration in Scottish waters; Table 6).**
- **Proportion at collision risk height** is a precautionary categorical assignment (25%, 50% or 100%), based on published mean or median flight heights relative to a collision risk band of about 22 m to a precautionary maximum rotor height (18 MW turbine). Where no data exist, 100% is assumed (low confidence). Heights are usually reported only as mean/median; marine GPS height data come mostly from large species. Nocturnal activity was assumed zero in the avoidance calculations. In the sheet 42 of 46 non-blank values are 100% and 9 are blank, so for most species this term is the 'no data' default and is not comparable with Kelsey's measured continuous RSZt.
- **Avoidance rate** comes from observed-vs-predicted collisions at 31 onshore wind farms (Table 5) or is assigned by group (e.g. one value, 0.9851, for most ducks; 0.9996 for waders). The authors rate confidence as very low and state it is unclear how transferable onshore rates are offshore.
- **OPEN, check before use:** these rates describe avoidance within the wind farm as used in collision risk models, which as I read it is not the same quantity as Kelsey's macro-avoidance (MA), typically about 0.3-0.9. Using 1 - 0.9996 as the avoidance term makes values tiny and compresses the 0-1 rescale. Confirm the report's definition and decide whether option 2 is meaningful as a relative index or needs a different avoidance term.
- **Possible typos in the sheet** (check against Woodward Table 6): White-tailed Sea-eagle and Steller's Sea-eagle 0.9972 (report: White-tailed Eagle 0.9872); Chinese Sparrowhawk 0.9956 (raptor group value 0.9957). Several non-seabirds carry 0.9954, the report's group value for divers, grebes and 'all birds', so these are proxies.

**Uncertainty (deferred).** Option 1 has 95% credible intervals (Lower/Upper) that could be sampled on the log scale; option 2 has the +/- on the avoidance rate but the PCRH categories have no uncertainty.

## Non-seabirds: coastal disturbance sensitivity (displacement analogue)

Non-seabird migrants have no Lamb et al. displacement rates. As a displacement-type metric the app uses **flight initiation distance (FID)** combined with whether the species is **known to use coastal migratory stopover habitat**. The logic (collaborator's): a species that uses coastal habitat and is easily disturbed is more at risk of losing that habitat to coastal development. It is labelled "coastal disturbance sensitivity" throughout, not displacement, because it is a proxy for habitat loss from disturbance, not an observed displacement response.

**Equation.** FID_s = rescale_01(log(FID in m)); H = 1 if coastal habitat is used, else 0; **D = FID_s x (b + (1 - b) x H)**. b is the floor (user slider, default 0). At b = 0, H is a pure gate (species not known to use coastal habitat get 0); at b > 0 they keep a fraction b of their FID score. D is then rescaled 0-1 again with the other species in the group and combined with collision (collision only / disturbance only / higher of the two / sum), and the combined sensitivity is rescaled 0.5-2, as for seabirds.

**Options.**
- Log transform of FID is always applied (raw FID is right-skewed; skew 0.93 raw vs 0.26 logged).
- **Body-size correction (checkbox, default off).** FID scales with body mass (log-log r about 0.7, slope about 0.27). Ticking the box replaces log(FID) by its residual from log(FID) ~ log(mass) before the 0-1 rescale, so the score reflects how skittish a species is for its size. Species without mass go to Data limited when it is ticked.
- **Floor b (slider 0-0.5).** Exists because the habitat flag is "known to use", so a 0 can mean absence of evidence rather than evidence of absence.

**Caveats.**
- FID values are heavily shared across species (28.1 m for 19 species; 89.7 m for 5; 82.1 m for 5), i.e. many are proxies from relatives or body-size groups, so ranks within ties are arbitrary.
- 50 of 55 species have coastal_habitat = 1, so the gate removes only 5 species at b = 0 and mostly FID drives the ranking.
- Thaxter predictions include abundance and range-size proxies, so using them alongside overlap (exposure) partly double-counts exposure.

## Non-seabird app and data decisions
- New input file `nonseabird_data_v1.csv` (55 species, from the non-seabirds tab of TBC_offline_backup_v1.5) with a dictionary. Same exposure/threat columns as seabirds, plus thaxter_pred/lower/upper, pcrh, avoidance_rate, fid_m, coastal_habitat, mass_g, family, tax_index.
- App has a top-level switch **Seabirds / Non-seabird migrants**; the two groups are never ranked together and rescaling is within group.
- Non-seabird sidebar: collision measure (Thaxter or PCRH x (1 - avoidance)), size-correction checkbox, floor slider; the combine option, exposure transform (log10 default / linear) and exponent sliders (3, 2, 1) are shared with seabirds.
- Data limited tab works as for seabirds: a species needs overlap, IUCN category and whatever the chosen collision/disturbance settings require. Under the PCRH option 9 species (blank PCRH) are data limited whenever collision is part of the sensitivity; all 55 have Thaxter values.
- Hover text for non-seabirds shows Thaxter prediction with its interval (or PCRH and avoidance rate) and FID and coastal habitat used, in place of FA/RSZt/MA and Lamb text.
