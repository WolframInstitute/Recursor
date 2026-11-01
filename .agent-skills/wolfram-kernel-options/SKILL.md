---
name: wolfram-kernel-options
description: Implement or review options in this paclet's Wolfram kernel functions, including native visualization defaults, option forwarding and SetOptions behavior.
---

# Kernel option conventions

Apply this skill when adding or changing public kernel functions or auditing
their default behavior. The user's policy is to use native Wolfram defaults,
with Automatic sizing instead of explicit default dimensions. This concerns
the implementation as well as the Options declaration.

- Inherit options from the built-in function that represents the result, such
  as TreeGraph for a syntax tree or ListLinePlot for a fitness history. Keep
  ImageSize -> Automatic; do not insert fixed widths, heights, or symbolic
  sizes such as Large in the function body as hidden defaults.
- Apply the same rule to other presentation options: retain the corresponding
  built-in defaults for padding, aspect ratio, colors, markers, frames and
  plot ranges. Do not change every value to Automatic: some native defaults
  are None, False or another meaningful value.
- Make Options[f] describe the function's actual defaults. Honor both
  SetOptions[f, ...] and explicit call options, with the explicit value taking
  precedence. Use OptionsPattern and OptionValue for consumed options. When
  forwarding options, retain wrapper defaults after explicit caller rules and
  use FilterRules against the target's supported options. Handle nested option
  lists without dropping RuleDelayed values.
- Choose the right built-in representation before forcing a layout. Resolve
  Automatic to program-specific labels or data coordinates only when needed
  to explain the result. Document such behavior and allow callers to override
  it, including disabling labels with None.
- Preserve computational parameters, resource budgets and necessary dialog
  geometry. They are not interchangeable with visualization defaults. Do not
  change them as a side effect of a presentation-options audit.
- Check observable defaults and overrides, including a SetOptions change and
  an explicit call that overrides it. Restore defaults after tests. Render
  representative outputs in light and dark appearances; correct the data or
  representation if a figure is awkward instead of adding hidden sizes.

Sources: [ImageSize](https://reference.wolfram.com/language/ref/ImageSize.html),
[Options](https://reference.wolfram.com/language/ref/Options.html),
[OptionsPattern](https://reference.wolfram.com/language/ref/OptionsPattern.html),
[OptionValue](https://reference.wolfram.com/language/ref/OptionValue.html),
[FilterRules](https://reference.wolfram.com/language/ref/FilterRules.html).
