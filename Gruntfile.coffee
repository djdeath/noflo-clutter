module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # CoffeeScript compilation
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # Browser version building
    component:
      install:
        options:
          action: 'install'
    component_build:
      'noflo-clutter':
        output: './browser/'
        config: './component.json'
        scripts: true
        styles: false
        plugins: ['coffee']
        configure: (builder) ->
          # Enable Component plugins
          json = require 'component-json'
          builder.use json()

    # Fix broken Component aliases, as mentioned in
    # https://github.com/anthonyshort/component-coffee/issues/3
    combine:
      browser:
        input: 'browser/noflo-clutter.js'
        output: 'browser/noflo-clutter.js'
        tokens: [
          token: '.coffee'
          string: '.js'
        ]

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      noflo:
        files:
          './browser/noflo-clutter.min.js': ['./browser/noflo-clutter.js']

    # Editor's UI
    exec:
      nuke_main:
        command: 'rm -rf ./components/*/'
      main_install:
        command: './node_modules/.bin/component install'
      main_build:
        command: './node_modules/.bin/component build -u component-json,component-coffee -o assets/browser -n noflo-ui -c'
      preview_deps:
        command: 'npm install'
        stdout: false
        stderr: false
        cwd: 'components/noflo-noflo-ui/preview'
      preview_install:
        command: './node_modules/.bin/component install'
        cwd: 'components/noflo-noflo-ui/preview'
      preview_build:
        command: './node_modules/.bin/component build -u component-json,component-coffee -o ../../../assets/preview/browser -n noflo-ui-preview -c'
        cwd: 'components/noflo-noflo-ui/preview'
      copy_index:
        command: 'cp -R assets/browser/noflo-noflo-ui/* assets/'

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee', 'graphs/*.json']
      tasks: ['test']

    # Coding standards
    coffeelint:
      components: ['components/*.coffee']

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-component'
  @loadNpmTasks 'grunt-component-build'
  @loadNpmTasks 'grunt-combine'
  @loadNpmTasks 'grunt-contrib-uglify'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-exec'

  # Our local tasks
  @registerTask 'build', 'Build NoFlo for the chosen target platform', (target = 'all') =>
    @task.run 'coffee'
    if target is 'all' or target is 'browser'
      @task.run 'component'
      @task.run 'component_build'
      @task.run 'combine'
      @task.run 'uglify'
      @task.run 'exec'

  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run 'coffeelint'
    @task.run 'coffee'
    if target is 'all' or target is 'browser'
      @task.run 'component'
      @task.run 'component_build'
      @task.run 'combine'

  @registerTask 'default', ['test']
