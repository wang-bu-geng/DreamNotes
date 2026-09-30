#!/usr/bin/env python3
"""
generate_project.py — 生成 DreamNotes.xcodeproj (OpenStep plist 格式)
"""

import os
import uuid

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
PRODUCT_NAME = "DreamNotes"
BUNDLE_ID = "com.nousresearch.DreamNotes"
SWIFT_VERSION = "5.9"
DEPLOYMENT_TARGET = "17.0"

SOURCE_FILES = [
    "DreamNotes/DreamNotesApp.swift",
    "DreamNotes/Views/ContentView.swift",
    "DreamNotes/Models/DreamEntry.swift",
    "DreamNotes/Models/UserSettings.swift",
    "DreamNotes/Services/AudioRecorderService.swift",
    "DreamNotes/Services/SpeechToTextService.swift",
    "DreamNotes/Services/AIDreamService.swift",
    "DreamNotes/Services/DreamStorage.swift",
    "DreamNotes/ViewModels/AppViewModel.swift",
    "DreamNotes/ViewModels/RecordingViewModel.swift",
    "DreamNotes/ViewModels/ArchiveViewModel.swift",
    "DreamNotes/Views/Onboarding/WelcomeSetupView.swift",
    "DreamNotes/Views/Home/HomeView.swift",
    "DreamNotes/Views/Recording/RecordingView.swift",
    "DreamNotes/Views/Archive/ArchiveView.swift",
    "DreamNotes/Views/Archive/DreamDetailView.swift",
    "DreamNotes/Views/Settings/SettingsView.swift",
]


def uid():
    return uuid.uuid4().hex.upper()


def is_uid(s):
    """Check if a string is a UUID-style hex identifier (case-insensitive)."""
    if not isinstance(s, str):
        return False
    s = s.strip()
    if len(s) != 32:
        return False
    try:
        int(s, 16)
        return True
    except ValueError:
        return False


def openstep_value(val):
    """Serialize a Python value to OpenStep string (no indentation prefix)."""
    if isinstance(val, dict):
        if not val:
            return "{}"
        items = []
        for k, v in val.items():
            items.append(f"{k} = {openstep_value(v)}")
        return "{ " + "; ".join(items) + "; }"
    elif isinstance(val, (list, tuple)):
        if not val:
            return "()"
        parts = ", ".join(openstep_value(item) for item in val)
        return f"({parts})"
    elif isinstance(val, bool):
        return "YES" if val else "NO"
    elif isinstance(val, int):
        return str(val)
    elif isinstance(val, str) and is_uid(val):
        return val  # bare UID, no quotes
    elif isinstance(val, str):
        # Escape special chars
        escaped = val.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    else:
        return f'"{str(val)}"'


def format_object(obj, indent=2):
    """Format a single object dictionary into OpenStep plist format."""
    tab = "\t"
    isa = obj.get("isa", "")
    # Build key-value pairs, excluding isa which goes inline
    pairs = []
    for key in sorted(obj.keys()):
        if key == "isa":
            continue
        pairs.append(f"{key} = {openstep_value(obj[key])}")
    body = "; ".join(pairs)
    if body:
        return f"{{isa = {isa}; {body}; }}"
    else:
        return f"{{isa = {isa}; }}"


def write_pbxproj():
    source_refs = {}  # path -> (file_ref_id, build_file_id)
    objects = {}

    # Build file references for source files
    for rel_path in SOURCE_FILES:
        ref_id = uid()
        build_id = uid()
        source_refs[rel_path] = (ref_id, build_id)
        objects[ref_id] = {
            "isa": "PBXFileReference",
            "lastKnownFileType": "sourcecode.swift",
            "path": rel_path,
            "sourceTree": "<group>",
        }
        objects[build_id] = {
            "isa": "PBXBuildFile",
            "fileRef": ref_id,
        }

    # Info.plist
    info_ref_id = uid()
    info_build_id = uid()
    objects[info_ref_id] = {
        "isa": "PBXFileReference",
        "lastKnownFileType": "text.plist.xml",
        "path": "DreamNotes/Info.plist",
        "sourceTree": "<group>",
    }
    objects[info_build_id] = {
        "isa": "PBXBuildFile",
        "fileRef": info_ref_id,
    }

    # Product reference
    product_ref_id = uid()
    objects[product_ref_id] = {
        "isa": "PBXFileReference",
        "explicitFileType": "wrapper.application",
        "includeInIndex": 0,
        "path": f"{PRODUCT_NAME}.app",
        "sourceTree": "BUILT_PRODUCTS_DIR",
    }

    # Groups
    root_group_id = uid()
    main_group_id = uid()

    all_children = [info_ref_id]
    for ref_id, _ in source_refs.values():
        all_children.append(ref_id)

    objects[root_group_id] = {
        "isa": "PBXGroup",
        "children": all_children,
        "sourceTree": "<group>",
    }
    objects[main_group_id] = {
        "isa": "PBXGroup",
        "children": [product_ref_id],
        "name": PRODUCT_NAME,
        "sourceTree": "<group>",
    }

    # Build phases
    sources_phase_id = uid()
    frameworks_phase_id = uid()
    headers_phase_id = uid()
    resources_phase_id = uid()

    objects[sources_phase_id] = {
        "isa": "PBXSourcesBuildPhase",
        "buildActionMask": 2147483647,
        "files": [build_id for _, build_id in source_refs.values()],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    objects[frameworks_phase_id] = {
        "isa": "PBXFrameworksBuildPhase",
        "buildActionMask": 2147483647,
        "files": [],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    objects[headers_phase_id] = {
        "isa": "PBXHeadersBuildPhase",
        "buildActionMask": 2147483647,
        "files": [],
        "runOnlyForDeploymentPostprocessing": 0,
    }
    objects[resources_phase_id] = {
        "isa": "PBXResourcesBuildPhase",
        "buildActionMask": 2147483647,
        "files": [],
        "runOnlyForDeploymentPostprocessing": 0,
    }

    # Configs
    target_config_list_id = uid()
    debug_config_id = uid()
    release_config_id = uid()

    objects[target_config_list_id] = {
        "isa": "XCConfigurationList",
        "buildConfigurations": [debug_config_id, release_config_id],
        "defaultConfigurationIsVisible": 0,
        "defaultConfigurationName": "Release",
    }

    target_debug_settings = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_NS_ASSERTIONS": "YES",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": ("DEBUG=1", "$(inherited)"),
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_VERSION": SWIFT_VERSION,
        "TARGETED_DEVICE_FAMILY": "1",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": PRODUCT_NAME,
        "INFOPLIST_FILE": "DreamNotes/Info.plist",
        "APPLICATION_EXTENSION_API_ONLY": "NO",
        "LAUNCH_STORYBOARD_NAME": "",
    }
    objects[debug_config_id] = {
        "isa": "XCBuildConfiguration",
        "buildSettings": target_debug_settings,
        "name": "Debug",
    }

    target_release_settings = dict(target_debug_settings)
    target_release_settings["COPY_PHASE_STRIP"] = "YES"
    target_release_settings["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
    target_release_settings["ENABLE_NS_ASSERTIONS"] = "NO"
    target_release_settings["GCC_OPTIMIZATION_LEVEL"] = "s"
    target_release_settings["GCC_PREPROCESSOR_DEFINITIONS"] = ("$(inherited)",)
    target_release_settings["MTL_ENABLE_DEBUG_INFO"] = "NO"
    target_release_settings["ONLY_ACTIVE_ARCH"] = "NO"
    target_release_settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = ""
    objects[release_config_id] = {
        "isa": "XCBuildConfiguration",
        "buildSettings": target_release_settings,
        "name": "Release",
    }

    # Target
    target_id = uid()
    objects[target_id] = {
        "isa": "PBXNativeTarget",
        "buildConfigurationList": target_config_list_id,
        "buildPhases": [sources_phase_id, frameworks_phase_id, headers_phase_id, resources_phase_id],
        "buildRules": [],
        "dependencies": [],
        "name": PRODUCT_NAME,
        "productName": PRODUCT_NAME,
        "productReference": product_ref_id,
        "productType": "com.apple.product-type.application",
    }

    # Project configs
    project_config_list_id = uid()
    project_debug_id = uid()
    project_release_id = uid()

    objects[project_config_list_id] = {
        "isa": "XCConfigurationList",
        "buildConfigurations": [project_debug_id, project_release_id],
        "defaultConfigurationIsVisible": 0,
        "defaultConfigurationName": "Release",
    }

    project_base = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_NS_ASSERTIONS": "YES",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": ("DEBUG=1", "$(inherited)"),
        "IPHONEOS_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_VERSION": SWIFT_VERSION,
        "TARGETED_DEVICE_FAMILY": "1",
    }
    objects[project_debug_id] = {
        "isa": "XCBuildConfiguration",
        "buildSettings": project_base,
        "name": "Debug",
    }

    project_release = dict(project_base)
    project_release["COPY_PHASE_STRIP"] = "YES"
    project_release["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
    project_release["ENABLE_NS_ASSERTIONS"] = "NO"
    project_release["GCC_OPTIMIZATION_LEVEL"] = "s"
    project_release["GCC_PREPROCESSOR_DEFINITIONS"] = ("$(inherited)",)
    project_release["MTL_ENABLE_DEBUG_INFO"] = "NO"
    project_release["ONLY_ACTIVE_ARCH"] = "NO"
    project_release["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = ""
    objects[project_release_id] = {
        "isa": "XCBuildConfiguration",
        "buildSettings": project_release,
        "name": "Release",
    }

    # Project object
    root_object_id = uid()
    objects[root_object_id] = {
        "isa": "PBXProject",
        "attributes": {
            "BuildIndependentTargetsInParallel": 1,
            "LastSwiftUpdateCheck": 1430,
            "LastUpgradeCheck": 1430,
        },
        "buildConfigurationList": project_config_list_id,
        "compatibilityVersion": "Xcode 14.0",
        "developmentRegion": "zh-Hans",
        "hasScannedForEncodings": 0,
        "knownRegions": ("en", "zh-Hans", "Base"),
        "mainGroup": root_group_id,
        "productRefGroup": root_group_id,
        "projectDirPath": "",
        "projectRoot": "",
        "targets": [target_id],
    }

    # ── Write OpenStep plist ──────────────────────────────

    # Group objects by isa for section headers
    sections = {}
    for obj_id, obj in objects.items():
        isa = obj.get("isa", "Unknown")
        sections.setdefault(isa, {})[obj_id] = obj

    section_order = [
        "PBXBuildFile",
        "PBXFileReference",
        "PBXFrameworksBuildPhase",
        "PBXGroup",
        "PBXHeadersBuildPhase",
        "PBXNativeTarget",
        "PBXProject",
        "PBXResourcesBuildPhase",
        "PBXSourcesBuildPhase",
        "XCBuildConfiguration",
        "XCConfigurationList",
    ]

    lines = ['// !$*UTF8*$!', '{']
    lines.append('\tarchiveVersion = 1;')
    lines.append('\tclasses = {')
    lines.append('\t};')
    lines.append('\tobjectVersion = 56;')
    lines.append('\tobjects = {')
    lines.append('')

    for sec_name in section_order:
        items = sections.get(sec_name)
        if not items:
            continue
        lines.append(f'/* Begin {sec_name} section */')
        for obj_id in sorted(items.keys(), key=lambda x: x.upper()):
            obj = items[obj_id]
            obj_str = format_object(obj)
            # Try to get a meaningful comment
            comment = obj.get('name') or obj.get('path') or sec_name
            lines.append(f'\t\t{obj_id} /* {comment} */ = {obj_str};')
        lines.append(f'/* End {sec_name} section */')
        lines.append('')

    lines.append('\t};')
    lines.append(f'\trootObject = {root_object_id};')
    lines.append('}')

    pbxproj_content = '\n'.join(lines)

    # Write
    xcodeproj_dir = os.path.join(PROJECT_DIR, f"{PRODUCT_NAME}.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)
    pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")

    with open(pbxproj_path, "w") as f:
        f.write(pbxproj_content)

    print(f"✅ 已生成: {pbxproj_path}")

    # ── Generate scheme ──────────────────────────────────────────
    schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(schemes_dir, exist_ok=True)

    scheme_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1430"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{PRODUCT_NAME}.app"
               BlueprintName = "{PRODUCT_NAME}"
               ReferencedContainer = "container:{PRODUCT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{PRODUCT_NAME}.app"
            BlueprintName = "{PRODUCT_NAME}"
            ReferencedContainer = "container:{PRODUCT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{PRODUCT_NAME}.app"
            BlueprintName = "{PRODUCT_NAME}"
            ReferencedContainer = "container:{PRODUCT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    scheme_path = os.path.join(schemes_dir, f"{PRODUCT_NAME}.xcscheme")
    with open(scheme_path, "w") as f:
        f.write(scheme_xml)
    print(f"✅ 已生成: {scheme_path}")


if __name__ == "__main__":
    write_pbxproj()
