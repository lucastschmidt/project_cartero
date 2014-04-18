# Project Cartero
> Project Cartero is a tool that runs on [Grunt.js](http://gruntjs.com/), based on [Cartero v1](https://github.com/rotundasoftware/cartero/tree/cartero-1), that provides a way to manage your client-side code in web projects (Node ...). No direct support for browserify (like Cartero v1), if you wish that, please see [Cartero v2](https://github.com/rotundasoftware/cartero).

> The theory is that you have a bunch of views (normally template based) and you have client-side code (css/js/coffee...) for that view, and you have a set of libraries that your view may depend on.

> During development, you want files to be served in their original form, while, in production, you want the files minified and concatenated.

> This tool will allow you to calculate which files should be served for a view, and inject into your views when its served.

## What this does?

Basically this tool detects which assets files are required for a determined view, and allows you to apply transformations to these files.

You can create your own file processor, to apply transformations, or you can use the built in [Grunt.js](http://gruntjs.com/) support, to run your *grunt tasks* in your assets files. There is a *ConcatAssetsProcessor* already built in to join your javascript/css files.

As well, its included an [Express.js v3](http://expressjs.com/) hook to inject the calculated view files in your template.

## Background

In general, this is basically a re-write of cartero v1 (without browserify built in support), based on what I felt in the moment (in terms of architecture). I wanted to improve performance and primarly the ability to customize and add features to it without breaking stuff

When I say performance, it means that I wanted to be able to create Grunt tasks that allow me to develop code and, when code changes, be able to keep development under 1-2 seconds. Since I wasnt being able to achieve that using [Cartero v1](https://github.com/rotundasoftware/cartero/tree/cartero-1), I did this re-write.

## Grunt Options
You can view other internal options in the last section.

```
  templatesPath: null
  	# you must specify where your templates/views are located

  templatesExtensions: /.*\.jade$/
  	# this is the default regular expression to detect templates/views

  templatesOwnFilesExtensions: /.*\.(coffee|js|css|less)$/
  	# this is the regular expression to detect assets files in the templates folders

  librariesPath: null
  	# this is the location of the libraries

  publicFilesPath : null
  	# this is the location you want to serve the files. This should be the dir where you store   your static files, in express js.

  contextPath: null
  	# used if your application or public dir runs in a different contextPath in your web application.
  	# You could say app.use(express.static('/publicSomething', publicDirPath)) in express js

  librariesPublicRelativePath: "libraries"
	# this is to organize your libraries inside your public folder. If your public folder is already the place where you want to store directly the libraries, just let this be an empty string

  libraryFilesExtensions: /.*\.(coffee|js|css|less|jpg|jpeg|tiff|gif|png|bmp|swf|eot|svg|ttf|woff)$/
 	# here you define which kind of files should be moved to the destination public dir, of your libraries

  carteroFileDescriptorPath: null
  	# you must specify the directory you want to store your cartero.json file

  carteroFileDescriptorName: "cartero"
  	# you could change the name of the file cartero.json

  carteroFileDescriptorExtension: "json"
  	# you could change the extension of the cartero.json file

  assetsProcessors: [require('project-cartero/component/processor/moveAssetsProcessor')]
  	# you can define an array of assetsProcessors, there are a few ways to specify each one
    # the MoveAssetsProcessProcessor should be included always, unless you want to replace with your own. See included AssetsProcessors.
  	# 1 - you can specify a built in inside the library
  	# 2 - you can specify one that you did implement, for that, you must extend /lib/model/assetsProcessor and implement the method named run
  	# 3 - you can specify a grunt task, by defining an object with fields: fileExt, destExt, task, clean.
  		- fileExt must be the extension of the files you want to process
  		- destExt is the extension that should be assigned to the transformed file
  		- task is the name of the grunt task you want to call
  		- clean is a boolean that indicates if you want to remove the old files

  logLevel: "warn"
  	# you can change the logLevel to try to detect problems
```

## Describe a library with bundle.json File

You can describe a library by using *bundle.json* file. The following options are available.

```
  keepSeparate : false
    # if true, files wont be joined when ConcatAssetsProcessor is used
  dependencies : []
  	# library id (relative path of the library folder) of all library that this one depends on
  directoriesToIgnore : []
    # relative dir paths from this directory of dirs to ignore
  directoriesToFlatten: []
  	# relative dir paths from this directory of dirs to scan as part of this own library 
  	# (instead they become their own libraries, that depend on the current)
  prioritizeFlattenedDirectories : false
  filePriority : []
    # relative file paths from this directory of files that should have an order preserved
  filesToIgnore : []
  	# relative file paths from this directory of files to ignore
  dynamicallyLoadedFiles : []
  	# relative file paths from this directory, of files that will be loaded manually by you
  remoteFiles : []
  	# array of urls, or relative paths, it should work just fine
```


## Included Assets Processors

### 1. MoveAssetsProcessor

This should always be the first one. This processor will move your library/assets files to your public destination folder. This means that when moving CSS, we will change all relative paths. *Do not use absolute paths in your CSS, I dont think it makes sense in this case.*

### 2. GruntAssetsProcessor

This processor is used internally so we can transform your object descring a Grunt task, into an instance of a GruntAssetsProcessor. This processor will simply run a Grunt task, but before that, it will map correctly the new file names into cartero.json file. 

An example of usage would be: ```{task: "cssmin", fileExt:"css", destExt:"css"}```

To use this, you will define an object in the assetsProcessor array, and the following options are availble:

- *fileExt* must be the extension of the files you want to process
- *destExt* is the extension that should be assigned to the transformed file
- *task* is the name of the grunt task you want to call
- *clean* is a boolean that indicates if you want to remove the old files

### 3. ConcatAssetsProcessor

This processor will join all the files (css, js) required for a view. This means that it will loop through all templates, and calculate all files that can be joined. This means files from templates extended, included, own files, and library files (directly and indirectly dependencies) that are *LOCAL* and not ```keepSeparate:true```. 


## Example of how a project can look like
This example can be found in /example in this repository.

### 1. Views

- /views/layout.jade

You can have a base layout, to be used by all your views, and here, you could load basic libraries that will be used by all your views. By using *##cartero_requires*, you are saying which libraries will be loaded for this view, and for all views that *extend* this layout.

```
// ##cartero_requires "jquery", "bootstrap" ,"utils"
doctype html
head
| !{cartero_css}
| !{cartero_js}
body
	block content
```

**A important thing to notice is the local variables cartero_css and cartero_js. They are generated by express-hook. If you use express, based on a cartero.json, you can inject the correct dependencies automatically for your views.**

- /views/clock/clock.jade, /views/clock/clock.js, /views/clock/clock.css

Here you have a view that extends **layout.jade**, by using *##cartero_extends* **or** by simply by using *Jade extends* command (built in support). You can see that this view requires the library *app/timekeeper*.

Another detail is that this view contains two files in their folders: this means that these files will be loaded as view files as well. Plus, this view includes another view. If the included view has libraries required, or assets files inside their folder, they will be loaded as well.

```
// ##cartero_extends "layout.jade"
// ##cartero_requires "app/timekeeper"

extends ../layout
block content
  .row
    .col-lg-12
      p Hello Clock World
      include table/redtable
```


> You can implement your own LibraryCreator by extending the default one, and overriding the function to detect extends/includes of a view, so that, based on your own templating language, you can detect when a view extends another view (to load their assets), or includes another view.

### 2. Libraries

- /library/bootstrap (contains bootstrap.min.js, bootstrap.css)
- /library/jquery (contains bundle.JSON, file that describes this library)

You can define a library based on remote files, so that you dont need to built in jquery inside your view files, and enjoy of CDN benefits.

```
{
	"remoteFiles": [
		"https://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"
	]
}

```
- /library/app/timekeeper (can contain any kind of asset that you define as a possible asset in your options, meaning, javascript, css, images ..., and can contain a bundle.json, if you want to describe your library and add options to it)

### 3. Gruntfile

In your Gruntfile, you will have a *project_cartero* task. You can define multiple configurations per environment, eg:

```
project_cartero:
	dev:
		options:
			templatesPath: path.resolve(__dirname, ".app/server/views")
			librariesPath:  path.resolve(__dirname, ".app/client/library")
			libraryFilesExtensions: /.*\.(coffee|js|css|less|jpg|jpeg|tiff|gif|png|bmp|swf|eot|svg|ttf|woff|jade)$/
			publicFilesPath: path.resolve(__dirname, ".app/public")
			librariesPublicRelativePath: ""
			assetsProcessors: [
				require('project-cartero/lib/component/processor/moveAssetsProcessor')
				,{task: "coffee", fileExt:"coffee", destExt:"js", clean:true}
			]
			carteroFileDescriptorPath: __dirname
			logLevel: "info"
	prod:
		options:
			templatesPath: path.resolve(__dirname, ".app/server/views")
			librariesPath:  path.resolve(__dirname, ".app/client/library")
			libraryFilesExtensions: /.*\.(coffee|js|css|less|jpg|jpeg|tiff|gif|png|bmp|swf|eot|svg|ttf|woff|jade)$/
			publicFilesPath: path.resolve(__dirname, ".app/public")
			librariesPublicRelativePath: ""
			assetsProcessors: [
				require('project-cartero/lib/component/processor/moveAssetsProcessor')
				,{task: "cssmin", fileExt:"css", destExt:"css"}
				,{task: "coffee", fileExt:"coffee", destExt:"js", clean:true}
				,{task: "uglify", fileExt:"js", destExt:"js"}
				,require('project-cartero/lib/component/processor/concatAssetsProcessor')
			]
			carteroFileDescriptorPath: __dirname
			logLevel: "info"
```

If you notice, you must define where your templates are located, where your libraries are located, which files extensions should we consider, whats the folder where you want your output (publicFilesPath).

You can list multiple assets processors to process your files after they are detected. The description of your view/libraries are saved in a file named *cartero.json**, thats why you must specify the directory you want to save this file. (This file will be necessary for the express-hook)

Notice that we have a *MoveAssetsProcessor* always there. For now, you must always explicitly include as the first one, if you want your code moved (it doesnt make sense for it to not be moved, since you dont want to transform your source files anyways).

### 4. Serve files using Express.js hook

```
express = require 'express'
projectCarteroMiddleware = require 'project-cartero/lib/express-hook'
path = require 'path'

app = express()
app.use '/', express.static(path.resolve(__dirname, '../public'))

app.set 'view engine', 'jade'
app.set('views', __dirname+'/views')

carteroJSONPath = path.resolve __dirname, "../..", "cartero.json"
app.use projectCarteroMiddleware(carteroJSONPath)

app.get "/", (req, res, next)->
  res.render "clock/clock"

app.listen 3000, ()-> console.log "Started app!!"

```

## TODOs:

- Always Improve Docs
- Always Refactor, remove complexity
- Create tests
- Create environment support (bundle.json set up by environment)

## Contributing

The code is written in coffe-script, so, use **grunt clean coffee** to generate code. Please write tests if you add a new feature.


## Release History
Not ready yet.
