# TICKET-016: Improve Starship Color Contrast and Waybar Hover Colors

## User Request
better starship text and bg colors
improve :hover colors in waybar

## Q&A
**Which colors need improvement?**
- color_text, color_a _b _c

**What specific problems are you experiencing?**
- poor contrast makes them not readable

**Scope of changes:**
- all themes color review

**Expected outcome:**
- IDK, YOU WILL PRINT HOW IT LOOKS HERE IN CHAT AND I WILL DECIDE IF THATS OK

**Priority level:**
- LOW

**Waybar hover color issues:**
- current colors are too similar to foreground so the hover effect is none

## Description
Review and improve color contrast across all starship themes and Waybar hover colors to enhance readability and visual feedback. Analysis revealed several critical issues:

### Starship Color Issues:
1. **tokyo-night**: `color_text: #202020` is too dark for colored backgrounds
2. **matte-black**: `color_a: #1a1a1a` won't be visible on dark terminals  
3. **catppuccin-latte**: Pure white text may be harsh

### Waybar Hover Color Issues:
1. **All themes**: Current `@hover` colors are too similar to `@foreground` colors
2. **Poor visual feedback**: Hover effects are barely noticeable due to low contrast
3. **Inconsistent contrast ratios**: Some themes have minimal hover color differentiation

### All Themes Requiring Review:
- catppuccin, catppuccin-latte, tokyo-night, gruvbox, nord, rose-pine, everforest, kanagawa, matte-black, osaka-jade, ristretto

The task involves analyzing current color combinations for adequate contrast ratios and improving both Starship readability and Waybar hover visibility while maintaining each theme's aesthetic identity.

## Acceptance Criteria
### Starship Colors:
- [ ] Analyze contrast ratios for all 11 starship themes
- [ ] Fix critical contrast issues (tokyo-night dark text, matte-black dark backgrounds)
- [ ] Ensure text remains readable on all background color combinations
- [ ] Update all theme starship.toml files with improved colors

### Waybar Hover Colors:
- [ ] Analyze current @hover vs @foreground contrast ratios across all 11 themes
- [ ] Improve hover color visibility to create noticeable visual feedback
- [ ] Ensure hover colors maintain theme aesthetic while providing clear contrast
- [ ] Update all theme waybar.css files with improved @hover colors

### General:
- [ ] Present color changes in chat for user approval
- [ ] Maintain each theme's visual identity and aesthetic
- [ ] Test colors work in both light and dark terminal environments

## Priority
Low

## Status
Todo

## Preparation
[To be filled during implementation planning]

## Architecture
[To be filled during implementation planning]

## TODOWrite
[Placeholder. Leave empty.]