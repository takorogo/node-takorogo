// Generated on 2014-07-07 using generator-nodejs 2.0.0
module.exports = function (grunt) {
    require('load-grunt-tasks')(grunt);

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        jshint: {
            all: [
                'Gruntfile.js',
                'test/**/*.js'
            ],
            options: {
                jshintrc: '.jshintrc'
            }
        },
        jison: {
            all : {
                files: { 'lib/parser.js': 'data/grypher.jison' }
            }
        },
        coffeelint: {
            all: ['src/*.coffee', 'test/*.coffee'],
            options: {
                configFile: 'coffeelint.json'
            }
        },
        coffee: {
            src: {
                files: [
                    { expand: true, src: ['**.coffee'], cwd: 'src/', dest: 'lib/', ext: '.js' }
                ]
            },
            test: {
                files: [
                    { expand: true, src: ['**.test.coffee'], cwd: 'test/', dest: 'test/', ext: '.test.cpl.js' }
                ]
            },
            e2e: {
                files: [
                    { expand: true, src: ['**.e2e.coffee'], cwd: 'test/', dest: 'test/', ext: '.e2e.cpl.js' }
                ]
            },
            options: {
                sourceMap: true
            }

        },
        mochacov: {
            test: {
                options: {
                    reporter: 'spec',
                    ui: 'tdd'
                }
            },
            travis: {
                options: {
                    coveralls: true
                }
            },
            local: {
                options: {
                    reporter: 'html-cov',
                    output: 'coverage/coverage.html'
                }
            },
            options: {
                files: ['test/**/*.test.js', 'test/**/*.test.*.js']
            }
        },
        execute: {
            e2e: {
                src: ['test/*.e2e.js', 'test/*.e2e.*.js']
            }
        },
        copy: {
            sources: {
                files: [
                    { expand: true, src: ['**.js'], cwd: 'src/', dest: 'lib/' }
                ],
                mode: true
            }
        },
        clean: {
            grunt: ['.grunt/'],
            lib: ['lib/'],
            doc: ['doc/'],
            client: ['client/'],
            test: ['test/**/*.cpl.js', 'test/tmp/'],
            sourceMaps: ['**/*.js.map', '!node_modules/**/*.js']
        },
        codo: {
            options: {
                name: 'Node Grypher',
                title: 'Node.js parser from Grypher to JSON Schema',
                extra: [ 'LICENSE-MIT' ],
                undocumented: true,
                stats: false,
                analytics: 'UA-55577995-1'
            },
            src: [ 'src/' ]
        },
        browserify: {
            all: {
                files: {
                    'client/grypher.js': ['index.js', 'lib/**/*.js']
                },
                options: {
                    alias: [ './index.js:grypher']
                }
            }
        },
        uglify: {
            grypher: {
                files: {
                    'client/grypher.min.js': ['client/grypher.js']
                }
            }
        },
        watch: {
            all: {
                files: ['**/*.js', '**/*.coffee', 'data/*.jison', 'test/fixtures/*.*', '!node_modules/**/*.js', '!lib/**/*.js'],
                tasks: ['default'] ,
                options: {
                    nospawn: true
                }
            }
        },
        'gh-pages': {
            options: {
                base: 'doc'
            },
            src: ['**']
        }
    });

    // Send coverage report to Coveralls.io only for Travis CI builds.
    var mochaCoverageTask = 'mochacov:' + (process.env.TRAVIS ? 'travis' : 'local');

    //todo Review tasks that seems to be too complicated
    grunt.registerTask('compile', ['clean', 'jshint', 'jison', 'coffeelint', 'coffee', 'copy:sources', 'browserify', 'uglify']);
    grunt.registerTask('document', ['clean:doc', 'codo']);
    grunt.registerTask('e2e', ['execute:e2e']);
    grunt.registerTask('test', ['mochacov:test', 'e2e']);
    grunt.registerTask('test-ci', [mochaCoverageTask, 'e2e']);
    grunt.registerTask('ci', ['compile', 'test-ci', 'clean:sourceMaps']);
    grunt.registerTask('default', ['build', 'watch']);
    grunt.registerTask('website', ['gh-pages']);
    grunt.registerTask('build', ['compile', 'test', 'document']);
    grunt.registerTask('publish', ['build', 'release', 'website']);
    grunt.registerTask('prerelease', ['build', 'release:prerelease', 'website']);
};
