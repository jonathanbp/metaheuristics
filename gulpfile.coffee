cargv          = (require 'yargs').argv
cfr           = require 'coffee-script/register'
coffee        = require 'gulp-coffee'
coffeelint    = require 'gulp-coffeelint'
del           = require 'del'
env           = require 'gulp-env'
gulp          = require 'gulp'
gutil         = require 'gulp-util'
istanbul      = require('gulp-coffee-istanbul')
mocha         = require 'gulp-mocha'

sources =
  coffee: './src/**/*.coffee'
  tests:  './test/**/*.coffee'

destinations =
  js:     './dist/'

gulp.task 'clean', -> del(destinations.js)

gulp.task 'lint', ->
  gulp.src(sources.coffee)
  .pipe(coffeelint())
  .pipe(coffeelint.reporter())

gulp.task 'compile', ->
  gulp.src(sources.coffee)
  .pipe(coffee({bare: true}).on('error', gutil.log))
  .pipe(gulp.dest(destinations.js))


gulp.task 'test', ->
  #Executes all mocha tests. use -g "pattern" to execute individual tests
  opts =
    timeout: 10000
    reporter: 'spec'
    compilers: 'coffee:coffee-script/register'

  if 'g' of gutil.env
    # -g (grep) parameter was passed
    opts.grep = gutil.env.g

  # Simply run the tests
  withoutCov = ->
    gulp.src(sources.tests, {read: false})
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(mocha(opts))
    .once('error', (err) ->
      console.error err
      process.exit(1)
    )
    .once('end', ->
      process.exit()
    )

  # Run tests with test coverage calculations
  withCov = ->
    covWriteOpts =
      dir: './coverage',
      reporters: ['text', 'text-summary' ],
      reportOpts: { dir: './coverage' },
    gulp.src(sources.coffeeCov)
      .pipe(istanbul({includeUntested: true}))
      .pipe(istanbul.hookRequire())
      .on 'finish', ->
        gulp.src(sources.tests, {read: false})
        .pipe(mocha(opts))
        .pipe(istanbul.writeReports(covWriteOpts))
        .once('error', (err) ->
          console.error err
          process.exit(1)
        )
        .once('end', ->
          process.exit()
        )

  if argv?['with-coverage']?
    withCov()
  else
    withoutCov()



gulp.task('default', () -> )
