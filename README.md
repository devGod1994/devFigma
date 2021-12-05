# <center>Parabeac-Core

![Parabeac Logo](https://github.com/Parabeac/Parabeac-Core/blob/master/repo_assets/parabeac_core_image.png)


Parabeac-Core converts design files into isolated & responsive Flutter code, continuously.

[![Discord Chat](https://img.shields.io/discord/308323056592486420.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/qUrghes) [![https://twitter.com/parabeac?lang=en](https://img.shields.io/twitter/url/http/shields.io.svg?style=social&style=plastic)](https://twitter.com/parabeac?lang=en) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](https://github.com/Parabeac/Parabeac-Core/blob/master/CODE_OF_CONDUCT.md) <a href="https://dev.to/parabeac"><img src="https://d2fltix0v2e0sb.cloudfront.net/dev-badge.svg" alt="bravemaster619's DEV Profile" height="22" width="22"></a>

<h3>
  <a href="https://docs.parabeac.com">Hello World</a>
  <span> · </span>
  <a href="https://discord.gg/qUrghes">Discord Community/Support</a>
  <span> · </span>
  <a href="https://dev.to/parabeac">Dev.to</a>
  <span> · </span>
  <a href="https://www.youtube.com/channel/UCgfDd4tQYZ5a_A5qxknmh8w">Youtube</a>
    <span> · </span>
    <a href="https://docs.parabeac.com">Tutorials</a>
  <span> · </span>
<a href="https://docs.parabeac.com">Reference Docs</a>

</h3>

# Why are we here?
The handoff between designers & developers is one of the most costly and frustrating bottlenecks in app development. As design iteration becomes more critical in the execution of app development, this problem is increasingly important to solve. Parabeac-Core solves this by generating isolated & responsive Flutter code by interpreting designs created in tools like Figma. By creating isolated UI, design changes & updates are supported forever.
# Table of Contents
  * [Dependencies](#dependencies)
  * [Cloning parabeac_core](#cloning-parabeac_core)
  * [Running parabeac_core](#running-parabeac_core)
    * [Figma](#figma)
    * [Sketch](#sketch)
  * [Running the generated code](#running-the-generated-code)
    * [Running a Figma Frame/Screen](#running-a-figma-framescreen)
    * [Running a Figma Component](#running-a-figma-component)
  * [Other](#other)
    * [Metrics](#metrics)

# Get Started

### Dependencies

 - [Dart](https://dart.dev/get-dart)
 - [Flutter](https://flutter.dev/docs/get-started/install)
 - [node.js](https://nodejs.org/en/download/)
 - [Figma File](https://figma.com) - [Sample](https://www.figma.com/file/Ysnjcij14HaE98ucq1iwW1/Parabeac-Counter-App-Demo?node-id=0%3A1)

## Cloning parabeac_core
Because parabeac-core contains submodules, it is easiest to clone using the following command:
```
git clone --recurse-submodules https://github.com/Parabeac/Parabeac-Core.git
```

If you have already cloned you may need to pull the submodules:
```
git submodule update --init
```

**_Run the following command to update the submodules:_**

```
git pull --recurse-submodules
```
## Running parabeac_core
### Figma
  In your terminal, change your directory to the root paarabeac_core directory and run:

``` bash
 $ pub get
 $ dart parabeac.dart -f <Figma File ID> -k <Figma API Key> -o <Absolute Path To Output Directory> 
```
#### Figma File ID (Required): -f
1. Visit https://figma.com and log in.
2. Select your Design File
3. The file ID is contained in the URL of your design file immediately after figma.com/file/`<fileID>`/. 
   
   *Example: The file ID for ```https://www.figma.com/file/Ysnjcij14HaE98ucq1iwW1/Parabeac-Counter-App-Demo``` is ```Ysnjcij14HaE98ucq1iwW1```*
#### Figma API Key (Required): -k
1. Visit https://figma.com and log in.
2. Navigate to your user profile and select `Settings`
3. Scroll Down to the "Create a new Personal Access Token"
4. Create a new Personal Access Token and copy your new API key. (It should look something like this: ```64522-a0e5509a-d5ce-47a8-880b-c295f9cb27ed```)

#### Name (Optional): -n
Sets the name of the exported project. For instance, if you want to name your project "cool_project", set the `-n` flag to `cool_project`. *Note: parabeac_core can only use valid Flutter project names.* 
#### Absolute Path (Optional): -o
Specifies the absolute path of the exported Flutter Project to be created. For instance, to export your Flutter project in the Documents folder, set your `-o` flag to `/Users/ParabeacUser/Documents/` Not setting this will export the project in the parabeac_core directory.

### Sketch
Due to the lack of requested support for Sketch and the major updates to this project, we temporarily stopped support for Sketch.


# Running the generated code
We recommend following our [Hello World guide](https://github.com/Parabeac/parabeac_generated_counter_app) but if you feel experienced enough with Flutter, feel free to jump right in here:


### Running a Figma Frame/Screen
![Figma Frame Example](https://github.com/Parabeac/Parabeac-Core/blob/master/repo_assets/figma_frame_example.png)
#### Steps
1. Open your generated project (Will be at the absolute path you set or in the parabeac_core directory)
2. If your frame was designed to be a screen, you can quickly test it by editing the MaterialApp widget in main.dart like the following:
``` class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      /// MyAppScreen() is a generated widget from the sample figma file.
      home: MyAppScreen(),
      ),
    );
  }
}
```
3. Save `main.dart` and execute `flutter run` 
### Running a Figma Component
![Figma Component Example](https://github.com/Parabeac/Parabeac-Core/blob/master/repo_assets/figma_component_example.png)

1. Navigate to a widget/screen where you can add in your component as a child.
2. Reference the component by providing a LayoutBuilder widget like the following:
```
Container(
  child: LayoutBuilder(builder: (context, constraints) {
    return FooCompoent(
      constraints,
    );
  })
)
```
1. Save the class and execute `flutter run` in your terminal & navigate your app to the expected location where the component should show up.

# Other
## Metrics
Parabeac-Core keeps track of a few data points to help us understand usage. Although we do not collect any personal information, you can turn off metrics at any time by creating the environment variable `PB_METRICS = "false"`.