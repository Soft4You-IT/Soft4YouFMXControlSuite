# Rules of the project

## Coding rules

The coding rules of the sources (identifier prefixes, names, formatting, blank lines, inline variables, structure of the classes, properties, header of the sources, line endings) are in [CONTRIBUTING.md](CONTRIBUTING.md), section "Coding rules": follow them for every change.

## Settings of the local IDE

Before every commit check the diff of the project files: the IDE writes settings of the local installation into them by itself. Do not commit:

- `DCC_UsePackage` in the `.dproj` of the demos and the tests (the list of the packages installed in the IDE);
- `Excluded_Packages` with an absolute path in the `.dproj` of the packages;
- `FileName` of the images in the `.fmx` forms (the path of the file the image was loaded from: the image itself is in the form);
- any other absolute path of the local computer.

The documentation, the CHANGELOG and the commit messages describe only the suite: they do not mention other projects or packages of the author.

## Versioning of the packages

The scheme for the users is in the section "Versioning" of the README. Operational rules:

- One version of the suite, identical in the six projects of the packages (`Packages\D11|D12|D13\Soft4You.FMX.Controls.Suite.dproj` and `...SuiteD.dproj`), FileVersion = ProductVersion. Demos and tests are not versioned.
- The D12 and D13 packages have the Win32 and Win64 platforms (Win64 is needed by the 64-bit IDE, from Delphi 12.3), the D11 ones only Win32; the version groups are the same in all six dproj anyway. The version is in the groups `Cfg_1_Win32` and `Cfg_1_Win64` (Debug) and `Cfg_2_Win32` and `Cfg_2_Win64` (Release), in `VerInfo_MajorVer`/`VerInfo_MinorVer`/`VerInfo_Release` and in `FileVersion`/`ProductVersion` of `VerInfo_Keys`. Build always 0, no automatic increment. The Debug groups also have `VerInfo_Debug` = true: the splash screen and About box read it (flag `VS_FF_DEBUG`) to add "(development)" to the title with the version.
- The other keys of `VerInfo_Keys` (`CompanyName`, `FileDescription`, `InternalName`, `LegalCopyright`, `ProductName`, `Comments`, ...) are identical in the six groups `Base_Win32`, `Base_Win64`, `Cfg_1_Win32`, `Cfg_1_Win64`, `Cfg_2_Win32` and `Cfg_2_Win64`: they are changed all together. `OriginalFilename` stays empty (the name of the `.bpl` depends on `{$LIBSUFFIX AUTO}`).
- **Debug** (development): odd Minor. After every merge into `develop` that touches the code of the packages (`Sources`, or `Packages`/`Graphics` for what goes into the packages), **including the merge of the release branch**, the Debug Minor goes to the next odd number (+2; +1 if it were even). One bump per merged branch, in a separate commit directly on `develop`. Merges that touch only `Docs`, `Demos` or `Tests`: no bump.
- **Release**: even Minor, +2 compared to the previous release (never calculated from the Debug one); `Release` +1 for a release with fixes only; `Major` +1 (Minor and Release at 0) for incompatible changes, such as a published property renamed or removed. It is set on the `rel_*` branch.
- **Default configuration**: on the `rel_*` branch it is set to Release (`<Config Condition="'$(Config)'==''">Release</Config>` in the six dproj), so that whoever downloads the tag builds in Release. The bump commit after the merge of the release into `develop` sets it back to Debug.

## Compiled resources (`Resources`)

The `RcCompile` of the packages (styles of the Badge and the Expander, icons `XxxDesign.rc`) and the project resource with the version information (`Soft4You.FMX.Controls.Suite.res`, `...SuiteD.res`) go into `Resources\` in the root: `BRCC_OutputDir` in the Base group of the six dproj. The build creates the folder and adds it by itself to the search path of the resources, so it must not be put in the `DCC_UnitSearchPath` of the packages; the folder is excluded from git. Applications and demos that use the Badge or the Expander from the sources need `Resources` in the search path and the packages already built.

The folder is shared by D11, D12 and D13: every build overwrites `Suite.res` and `SuiteD.res` of the previous one. It is harmless only as long as the version information is identical in the six dproj (see "Versioning of the packages").
