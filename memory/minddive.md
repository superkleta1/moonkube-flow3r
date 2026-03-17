# MindDive — Implementation Details

## John Doe Resource Layout (res://resources/johndoe/)

```
johndoe/
  proximity_rules/          (8 .tres)
    pr_bouquet_with_kaleidoscope.tres   RESONANCE, strength=0.5
    pr_bouquet_with_echo.tres           INTERFERENCE, strength=0.5
    pr_kaleidoscope_with_bouquet.tres   RESONANCE, strength=0.5
    pr_echo_with_bouquet.tres           INTERFERENCE, strength=0.5
    pr_echo_with_trash_art.tres         RESONANCE, strength=0.5
    pr_trash_art_with_bandage.tres      RESONANCE, strength=0.5
    pr_trash_art_with_echo.tres         RESONANCE, strength=0.5
    pr_bandage_with_trash_art.tres      RESONANCE, strength=0.5

  concept_items/            (7 playable) — icons attached from res://assets/sprites224/
    ci_jd_bouquet.tres      id="ci_jd_bouquet", SMELL, emotion +2.0/step, rules: ci_jd_kaleidoscope RESONANCE, ci_jd_echo INTERFERENCE
    ci_jd_echo.tres         id="ci_jd_echo", HEAR, emotion -2.0/step, rules: ci_jd_bouquet INTERFERENCE, ci_jd_trash_art RESONANCE
    ci_jd_trash_art.tres    id="ci_jd_trash_art", SEE, left_att=-3 right_att=+3, rules: ci_jd_bandage RESONANCE, ci_jd_echo RESONANCE
    ci_jd_kaleidoscope.tres id="ci_jd_kaleidoscope", SEE, base_att=+3, rules: ci_jd_bouquet RESONANCE
    ci_jd_bandage.tres      id="ci_jd_bandage", SEE, left_att=+3 right_att=-3, rules: ci_jd_trash_art RESONANCE
    ci_jd_report.tres       id="ci_jd_badge", SEE, base_att=-3, is_suppressor=true
    ci_jd_window.tres       id="ci_jd_window", PATH/gate, gate_shifts=[0,+25,0,-25] (E=Hope, W=Despair)

  preset_items/             (2 baked into level, no icons)
    ci_jd_bed.tres          id="ci_jd_bed", SEE, base_att=-2, right_att=+2 (Hope neutralizes repulsion)
    ci_jd_light.tres        id="ci_jd_light", SEE, base_att=+1, left_att=+4 (Despair greatly amplifies)

  base_items/               (5 items — filenames stable, internal ids prefixed)
    bi_jd_flowers.tres      id="bi_jd_wilted_flower",  slot_count=1
    bi_jd_echobottle.tres   id="bi_jd_glass_bottle",   slot_count=1
    bi_jd_kaleidoscope.tres id="bi_jd_twisted_wire",   slot_count=1
    bi_jd_report.tres       id="bi_jd_badge_item",     slot_count=0
    bi_jd_windowsill.tres   id="bi_jd_window_frame",   slot_count=1

  informations/             (4 intel pieces — icons attached from res://assets/sprites224/)
    i_jd_hope.tres          id="i_jd_scent"
    i_jd_pain.tres          id="i_jd_self_harm"
    i_jd_art.tres           id="i_jd_dump_report"
    i_jd_medical_record.tres id="i_jd_medical_record"

  recipes/                  (7 recipes)
    cr_jd_bouquet.tres      wilted_flower + scent → bouquet
    cr_jd_echo.tres         glass_bottle + medical_record → echo
    cr_jd_trash_art.tres    glass_bottle + dump_report → trash_art
    cr_jd_kaleidoscope.tres twisted_wire + scent → kaleidoscope
    cr_jd_bandage.tres      wilted_flower + self_harm → bandage
    cr_jd_report.tres       badge_item (no intel) → badge
    cr_jd_window.tres       window_frame + dump_report → window (gate)

  jd_prepconfig.tres        max_concept_items=7, 5 base_items, 4 informations
```

## Scene Wiring

### MindDive.tscn changes
- Added `PresetConceptItems` node under World
- BedPreset: instance of PlacedConceptItem.tscn, cell=(7,0,4), concept=ci_jd_bed
- LightPreset: instance of PlacedConceptItem.tscn, cell=(5,0,6), concept=ci_jd_light
- PlanningMode node: added `gridmap_nav = NodePath("../../World/GridMapNav")`

### MindDivePrep.tscn changes
- Config now points to `res://resources/johndoe/jd_prepconfig.tres`

## Known Gaps / TODO
- Icons assigned for all base_items, informations, and concept_items from res://assets/sprites224/
- Preset items (ci_jd_bed, ci_jd_light) have no icons — add when available
- Preset item world positions (transform.origin) are approximate: developer should verify
  in editor against actual GridMap coordinate system
- emotion proximity amplification (echo+trash_art "emotion effect amplified" per spec) is
  implemented as attraction RESONANCE only; the code doesn't currently modify emotion rate
  via proximity — flag for future enhancement
