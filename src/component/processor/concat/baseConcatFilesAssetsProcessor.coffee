_ = require 'lodash'
Promise = require 'bluebird'
fs = require 'fs'
path = require 'path'
fileExtension = require '../../utils/fileExtension'
calculateViewFilesByType = require('../../calculateViewFiles/calculateByType')

AssetsProcessor = require '../../../model/assetsProcessor'

mkdirp = require 'mkdirp'

class BaseConcatFilesAssetsProcessor extends AssetsProcessor
  constructor:(name, @extensions, @resultExtension, grunt, options)->
    super(name, grunt, options)
    throw new Error("Extensions must be informed") if ! (_.isArray(@extensions) and @extensions.length > 0)
    throw new Error("Result Extension must be informed") if ! (_.isString(@resultExtension) and @resultExtension.length > 0)
    @separator = grunt.util.linefeed

  run:(carteroJSON, callback)=>
    @concatTemplateViewFiles(carteroJSON)
    .then (filesCalculated)=>
      @debug msg: "Successfully runned #{@name}"
      callback(null, filesCalculated)
    .error (error)=>
      @error msg:"rror while trying to run #{@name}", error: error
      callback(new Error(error))

  calculateLibraryPath:(libraryId)=> path.resolve(@options.librariesDestinationPath, "library-assets", libraryId)

  concatTemplateViewFiles:(carteroJSON)=>
    Promise.resolve().then ()=>
      files = {}

      for templateId, template of carteroJSON.templates
        @findFilesInTemplate(carteroJSON, template, files)

      @concatTemplatesFiles (data for file, data of files)
      return files

  findFilesInTemplate:(carteroJSON, template, files)=>
    opts =
      carteroJSON:carteroJSON
      web: false
      filterLibrary: (library)->
        library.bundleJSON.keepSeparate is false
      filterFile: (path, ext, fileObj)=>
        return @resultExtension is ext and fileObj.type is "LOCAL"

    filesToConcat = calculateViewFilesByType(opts)(template)

    if filesToConcat.length > 0
      @logger.debug "Found the following files for template #{template.filePath} #{JSON.stringify(filesToConcat, null, 2)}"
      files[template.filePath] = {src:filesToConcat, dest:@calculateTemplateViewFilesDestinationPath(template)}

  calculateTemplateViewFilesDestinationPath:(template)=>
    concatFileName = path.basename(template.filePath) + '-' + Date.now() + "." + @resultExtension
    newPath = path.join @options.librariesDestinationPath, "views-assets", path.relative(@options.templatesPath, template.filePath)
    return path.resolve newPath, "..", concatFileName

  concatTemplatesFiles:(files)=>
    concatOptions =
      files: files
      options:
        separator: @separator
    @grunt.config( [ "concat", "project_cartero_concat_#{@resultExtension}_views_files" ], concatOptions )
    @grunt.task.run "concat:project_cartero_concat_#{@resultExtension}_views_files"
    @logger.debug "created concat grunt job with options #{JSON.stringify(concatOptions, null, 2)}"

module.exports = BaseConcatFilesAssetsProcessor
