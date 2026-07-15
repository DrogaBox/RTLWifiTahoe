import sys
content = open('scripts/gen_xcode_project.py', 'r').read()

# Add CODE_SIGN_IDENTITY after ASSETCATALOG in Debug target
old_dbg = """L('\\t\\t\\t\\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')\\nL('\\t\\t\\t\\tCOMBINE_HIDPI_IMAGES = YES;')"""
new_dbg = """L('\\t\\t\\t\\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')\\nL('\\t\\t\\t\\tCODE_SIGN_IDENTITY = \\"-\\";')\\nL('\\t\\t\\t\\tCOMBINE_HIDPI_IMAGES = YES;')"""
content = content.replace(old_dbg, new_dbg)

# Fix the comment
content = content.replace('# Release (target) -- FIXED: buildSettings close uses 3 tabs, not 2', '# Release (target)')

open('scripts/gen_xcode_project.py', 'w').write(content)
print('Patched')
