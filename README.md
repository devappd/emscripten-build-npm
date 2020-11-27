# emscripten-build-npm

Configure and build a C/C++ project with Emscripten by using node.js.

See example usage of this toolset in [emscripten-npm-examples](https://github.com/devappd/emscripten-npm-examples).

***This package is experimental! See [issues](https://github.com/devappd/emscripten-build-npm/issues) for current progress and [emscripten#5774](https://github.com/emscripten-core/emscripten/issues/5774) to discuss emscripten on NPM.***

## Example

Building is as simple as switching to your project directory and entering the command line:

```sh
npx emscripten build
```

or invoking from JavaScript:

```js
const emscripten = import('emscripten-build');

emscripten.build()
    .then(_ => { /* ... */ });
```

## Configuration

You set your build parameters in a file named `emscripten.config.js`. A simple configuration file may look like this:

```js
module.exports = {
    "myProject": {
        "type": "cmake",

        "configure": {
            "path": "./src",
            "generator": "Ninja",
            "type": "Release",
            "arguments": [
                "-DDEFINE1=\"Value1\""
            ]
        },

        "build": {
            "path": "./build"
        },

        "install": {
            "path": "./dist"
        }
    }
}
```

You may set different parameters for the `configure`, `build`, `install`, and `clean` steps. See later in this document for the configuration format.

## Installation

Before you install this package, you must have at least Python 3.6 on your system. You may download it at [python.org](https://www.python.org/downloads/), or refer to your OS's package manager.

This package works with Node.js 12.x or later.

The install command is:

```sh
npm install --emsdk='/your/custom/install/path' --save-dev git+https://github.com/devappd/emscripten-build-npm.git
```

Use the `--emsdk` switch to specify your own install path for the Emscripten SDK. This path is saved to your `npmrc` user config and it is referred to every time this package is installed.

You should specify your own path in order to save disk space across duplicate `node_modules` installations. If you are running on Windows, the installation will fail if the install path is longer than 85 characters (per [emsdk#152](https://github.com/emscripten-core/emsdk/issues/152)). This is a certainty if you install globally with `-g`.

In addition to the above switch, you may specify an install path via this command:

```sh
npm config set emsdk "/your/install/path"
```

This package installs these dependencies:

* [emsdk-npm](https://github.com/devappd/emsdk-npm) -- Installs EMSDK into a location of your choice.
* [cmake-binaries](https://github.com/devappd/cmake-binaries) -- Locates CMake on your system
or installs it into your `node_modules`.
* [ninja-binaries](https://github.com/Banno/ninja-binaries) -- Locates ninja on your system
or installs it into your `node_modules`.
* [msbuild](https://github.com/jhaker/nodejs-msbuild) -- Locates MSBuild (Visual Studio) on your
system. If you wish to use Visual Studio, you'll need to have it installed on your system.

Usage of `make`, `configure`, `mingw32-make`, and any other build toolset, will
require you to install those systems by yourself. Have those commands available
in your PATH.

If you have any issues with the environment, you may refer to [issue #15](https://github.com/devappd/emscripten-build-npm/issues/15) and [Emscripten's prerequisites](https://emscripten.org/docs/getting_started/downloads.html#platform-notes-installation-instructions-sdk) for guidance.

## Command Line Usage

In all commands, `config_name` is optional and refers to the name of your config in
`emscripten.config.js`.

If `config_name` is not specified, it defaults to the `default` name specified in
`emscripten.config.js`. Or, if there's only one config specified, then that sole config
will be selected.

| Command | Description
| ------- | -----------
| `npx emscripten configure [config_name]` | Configure the project.
| `npx emscripten build [config_name]` | Build the project and configure it first if necessary.
| `npx emscripten clean [config_name]` | Reset the project's build files.
| `npx emscripten install [config_name]` | Copy the project's build output into a target directory.
| `npx emscripten reconfigure [config_name]` | Clean the project then configure it.
| `npx emscripten rebuild [config_name]` | Clean the project, configure it, then build.
| `npx emscripten compile [config_name]` | Build the project. If the build fails, the project is cleaned then a rebuild is attempted.
| `npx emscripten run <command> [arg...]` | Runs a given command under the context of the EMSDK environment.

## JavaScript Usage

This package also supplies JavaScript bindings for the above commands:
    
* `emscripten.configure(configName, customConfig)`

* `emscripten.build(configName, customConfig)` or `emscripten.make(configName, customConfig)`

* `emscripten.clean(configName, customConfig)`

* `emscripten.install(configName, customConfig)`

* `emscripten.reconfigure(configName, customConfig)`

* `emscripten.rebuild(configName, customConfig)`

* `emscripten.compile(configName, customConfig)`

For all methods, both parameters are optional.

| Parameter    | Description |
| ------------ | ------------|
| `configName` | Selects the named config in your `emscripten.config.js`. Defaults to the `default` name specified in that file, or the sole config if there's only one listed.
| `customConfig` | An object fragment with properties to overwrite on your selected config. This performs a deep merge on your selected config using this fragment.

Calling these methods will perform the action and return a Promise that yields a Bootstrap object.
On the Bootstrap object, you can chain multiple calls while reusing the same config.

```js
const emscripten = require('emscripten-build');

emscripten.configure()
    .then(bootstrap => bootstrap.build())
    .then(bootstrap => bootstrap.clean());
```

However, you cannot select a new config in the chained bootstrap nor specify a fragment to edit it. If you wish to do so, you need to call a method on the `emscripten` module.

You can specify an object fragment to override certain parameters in your config. Note in this example that we're not chaining calls on `bootstrap`, but we are calling `emscripten.build()` every time.

```js
const emscripten = require('emscripten-build');

emscripten.configure()
    .then(_ => emscripten.build({
        "build": {
            "target": "MainProject"
        }
    }))
    .then(_ => emscripten.build({
        "build": {
            "target": "SubProject"
        }
    }))
    .then(_ => emscripten.clean({
        "clean": {
            "paths": [ "/path/to/obj" ]
        }
    }));
```

With `emscripten.run()`, you can run any command inside the EMSDK environment. It does not return a bootstrap.

```js
const emscripten = require('emscripten-build');

emscripten.run('command',
    ['args1','args2','args3', /*...*/],
    { /* child_process.spawn options, e.g., cwd */ }
)
    .then(_ => { /*...*/ });
```

You can also invoke `run()` on an existing bootstrap. In this case, it can be chained
with other bootstrap calls.

```js
const emscripten = require('emscripten-build');

emscripten.build()
    .then(bootstrap => bootstrap.run('command', 
        ['args1', 'args2', 'args3', /*...*/],
        { /* child_process.spawn options, e.g., cwd */ }
    ));
```

## Configuration Files

The below describes the parameters you can set for your build steps: `configure`, `build`, `install`, and `clean`.

Note that the only required parameters are `your_config["type"]` and `your_config["configure"]["path"]` (for Makefile, `your_config["build"]["path"]` is used instead.)
The other parameters have defaults as specified below.

If any relative paths are specified, they are resolved in relation to the config file's directory.

## Top-Level

Your config file will be searched at these locations:

* `<your_module>/emscripten.config.js`
* `<current_working_dir>/emscripten.config.js`.

The config file lists some top-level fields such as `emsdkVersion`, `default`, and your project's build configurations.

In this top-level object, you may list multiple configurations by name:

```js
module.exports = {
    // Selects the EMSDK version to use.
    // Default: "latest"
    "emsdkVersion": "latest",

    // Selects the configuration to use if one is not specified
    // on the command line.
    //
    // Default: Sole config if only one is listed, otherwise
    // this is required.
    "default": "named_config",

    "named_config": {
        // Selects the build toolset to use. Required.
        // Possible values: "make"|"autotools"|"cmake"
        "type": "cmake",

        "configure": { /* ... */ },
        "build": { /* ... */ },
        "install": { /* ... */ },
        "clean": { /* ... */ }
    },

    "other_named_config": {
        "type": "make",

        "configure": { /* ... */ },
        "build": { /* ... */ },
        "install": { /* ... */ },
        "clean": { /* ... */ }
    }
}
```

## Make Configuration

Make does not have `configure` parameters. As such, the
`emscripten.configure()` call has no effect for Make configs.

```js
{
    "type": "make",

    "build": {
        // Path which contains Makefile. Required.
        "path": "/path/to/dir/with/Makefile",

        // Target to pass to Make
        // Default: None
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [
            "-j", "4", "-DFLAG", "-DDEFINE1=value1", "-DDEFINE2=value2"
        ]
    },

    "install": {
        // Target to pass to Make
        // Default: "install"
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [ /* ... */ ]
    },

    "clean": {
        // Target to pass to Make
        // Default: "clean"
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [ /* ... */ ]
    }
}
```

## Autotools Configuration

### Configure

```js
{
    "type": "autotools",

    "configure": {
        // Path to your source directory which contains ./configure. Required.
        "path": "/path/to/dir/with/configure",

        // Command line arguments to pass to ./configure.
        // Default: []
        "arguments": [
            "-DCUSTOM1=\"VAL 1\"",
            "-DCUSTOM1=\"VAL 2\""
        ]
    },

    "build": {
        // Path to store Makefile and build cache
        // Default: <config_dir>/build
        "path": "/path/to/build/cache",

        // Target to pass to Make
        // Default: None
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [
            "-j", "4"
        ]
    },

    "install": {
        // Path to install executables to.
        // Default: <config_dir>/dist
        "path": "/path/to/install/destination",

        // Paths to install artifacts.
        // Relative paths are resolved to the config file directory, as normal.
        // Default: <install_path>/bin (lib, include...)
        "binaryPath": "/path/to/install/bin",
        "libraryPath": "/path/to/install/lib",
        "includePath": "/path/to/install/include",

        // Target to pass to Make
        // Default: "install"
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [ /* ... */ ]
    },

    "clean": {
        // Target to pass to Make
        // Default: "clean"
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [ /* ... */ ]
    }
}
```

## CMake Configuration

### Configure

```js
{
    "type": "cmake",

    "configure": {
        // Path to your source directory which contains CMakeLists.txt. Required.
        "path": "/path/to/dir/with/CMakeLists",

        // Type of build files to generate. Specify as if you were passing -G to CMake.
        // Default: "Ninja"
        // Possible values: "Ninja"|"Unix Makefiles"|"Visual Studio 16"|etc.
        "generator": "Ninja",

        // Build type.
        // Default: "Release"
        // Possible: "Debug"|"Release"|"RelWithDebInfo"|etc.
        "type": "Release",

        // Extra command line arguments, e.g., cache defines.
        // Default: []
        "arguments": [
            "-DCUSTOM1=\"VAL 1\"",
            "-DCUSTOM1=\"VAL 2\""
        ]
    },

    "build": {
        // Path to build cache
        // Default: <config_dir>/build
        "path": "/path/to/build/cache",

        // Target to pass to Make
        // Default: None
        "target": "targetName",

        // Arguments to pass to ninja, make, etc.
        // Default: []
        "arguments": [
            "-j", "4"
        ]
    },

    "install": {
        // Path to install executables to.
        // Default: <config_dir>/dist
        "path": "/path/to/install/destination",

        // Paths to install artifacts.
        // Relative paths are resolved to the config file directory, as normal.
        // Default: <install_path>/bin (lib, include...)
        "binaryPath": "/path/to/install/bin",
        "libraryPath": "/path/to/install/lib",
        "includePath": "/path/to/install/include",

        // Target to pass to Make
        // Default: "install"
        "target": "targetName",

        // Arguments to pass to Make
        // Default: []
        "arguments": [ /* ... */ ]
    },

    "clean": {
        // List of paths to clean.
        // Default: [ config["configure"]["cachePath"] ]
        "paths": [
            "/path/to/clean/1",
            "/path/to/clean/2",
            /* ... */
        ]
    }
}
```

## License

MIT License.
