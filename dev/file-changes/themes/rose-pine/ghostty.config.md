# themes/rose-pine/ghostty.config

## 🚨 MERGE GUIDANCE
**CRITICAL TO PRESERVE**: All customizations shown in diff  
**SAFE TO UPDATE**: Non-customized sections that don't conflict with changes  
**CONFLICT RESOLUTION**: Preserve fork customizations, accept upstream structural changes

## Change Summary
New ghostty theme configuration

## Diff
```diff
@@ -0,0 +1,30 @@
+# Rose Pine theme for Ghostty
+background = faf4ed
+foreground = 575279
+
+# Cursor colors
+cursor-color = cecacd
+
+# Selection colors
+selection-background = dfdad9
+selection-foreground = 575279
+
+# Standard colors
+palette = 0=f2e9e1
+palette = 1=b4637a
+palette = 2=286983
+palette = 3=ea9d34
+palette = 4=56949f
+palette = 5=907aa9
+palette = 6=d7827e
+palette = 7=575279
+
+# Bright colors
+palette = 8=9893a5
+palette = 9=b4637a
+palette = 10=286983
+palette = 11=ea9d34
+palette = 12=56949f
+palette = 13=907aa9
+palette = 14=d7827e
+palette = 15=575279
\ No newline at end of file
```

## Reasoning
Added theme support for ghostty terminal to replace alacritty theme
