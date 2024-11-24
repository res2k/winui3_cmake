# winui3_cmake
CMake scripts for building WinUI 3 apps.

Useful if you want to build a a WinUI 3 app with CMake and not necessarily use the Visual Studio generator.

Provides the following functionality:
* Run `nuget install`, get package directories
* Locate Windows 10 SDK & relevant files within
* Generate `.winmd` files using `midl`
* Merge `.winmd` files using `mdmerge`
* Generate headers using `cppwinrt`
* Create `.pri` files
* Compile `.xaml` files using standalone `XamlCompiler.exe`

# Caveats

The standalone `XamlCompiler.exe` has broken error reporting (see https://github.com/microsoft/microsoft-ui-xaml/issues/10027),
making troubleshooting failures quite hard.

Apparently the only officially supported way to run the XAML compiler is through MSBuild;
so a possible approach to get run it in a supported fashion could be to generate a wrapper
MSBuild project to run it.

# Acknowledgements

Shout out to GitHub user [DarranRowe](https://github.com/DarranRowe) who
[shared his own experience with running the standalone XamlCompiler](https://github.com/microsoft/microsoft-ui-xaml/issues/10027#issuecomment-2381644081),
making it vastly easier for me to build the required CMake logic.
