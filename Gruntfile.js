// Generated on 2014-07-07 using generator-nodejs 2.0.0
module.exports = function (grunt) {
    'use strict';

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
            takorogo : {
                files: [
                    { 'lib/parser.js': ['data/takorogo.jison', 'data/takorogo.jisonlex'] }
                ]
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
                    {
                        expand: true,
                        src: ['**.js'],
                        cwd: 'src/',
                        dest: 'lib/'
                    }
                ],
                mode: true
            }
        },
        clean: {
            grunt: ['.grunt/'],
            lib: ['lib/'],
            doc: ['doc/'],
            client: ['client/lib/'],
            test: ['test/**/*.cpl.js', 'test/tmp/'],
            sourceMaps: ['**/*.js.map', '!node_modules/**/*.js']
        },
        codo: {
            options: {
                name: 'Node Takorogo',
                title: 'Node.js parser from Takorogo to JSON Schema',
                extra: [ 'LICENSE' ],
                undocumented: true,
                stats: false,
                analytics: 'UA-55577995-1'
            },
            src: {
                src: 'src/',
                dest: 'doc/'
            }
        },
        browserify: {
            all: {
                files: {
                    'client/lib/takorogo.js': ['index.js', 'lib/**/*.js']
                },
                options: {
                    alias: [ './index.js:takorogo']
                }
            }
        },
        uglify: {
            takorogo: {
                files: {
                    'client/lib/takorogo.min.js': ['client/lib/takorogo.js']
                }
            }
        },
        watch: {
            all: {
                files: ['**/*.js', '**/*.coffee', 'data/*.jison', 'data/*.jisonlex', 'test/fixtures/*.*', '!node_modules/**/*.js', '!lib/**/*.js'],
                tasks: ['default'] ,
                options: {
                    nospawn: true
                }
            }
        },
        'gh-pages': {
            'docs': {
                options: {
                    base: 'doc'
                },
                src: ['**']
            },
            client: {
                options: {
                    base: 'client/',
                    repo: 'https://github.com/takorogo/takorogo.js.git',
                    branch: 'master',
                    tag: '<%= client.tag %>',
                    message: 'Client release of version <%= client.tag %> (<%= client.description %>).'
                },
                src: ['**']
            }
        }
    });

    grunt.registerTask('release-client', 'Release client library to "client" branch with proper tag', function () {
        // Convert task to async mode
        var done = this.async();

        // Retrieve latest tag info from git
        require('child_process').exec('git describe', function (error, stdout) {
            // Throw on error
            if (error) {
                throw new Error(error);
            }

            // Parse git description to retrieve semver tag only
            var description = stdout.toString();
            var tag = description.match((/([0-9\.]+(-\w+)?)(-\w+)?/))[1];

            // Throw if tag is invalid
            if (!tag) {
                throw new Error("Can't determine tag for client release.");
            }
            // Save tag in the config where it will be used by `gh-pages:client`
            grunt.config.set('client', {
                tag: tag,
                description: description
            });

            // Run tasks
            grunt.log.writeln('Releasing client of version "' + tag + '" of state "' + description + '"...');
            grunt.task.run([
                'gh-pages:client'
            ]);

            done();
        });
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
    grunt.registerTask('default', ['build']);
    grunt.registerTask('serve', ['build', 'watch']);
    grunt.registerTask('website', ['gh-pages:docs']);
    grunt.registerTask('build', ['compile', 'test', 'document']);
    grunt.registerTask('publish', ['build', 'release', 'release-client', 'website']);
    grunt.registerTask('prerelease', ['build', 'release:prerelease', 'release-client', 'website']);
};
