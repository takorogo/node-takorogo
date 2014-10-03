// Generated on 2014-07-07 using generator-nodejs 2.0.0
module.exports = function (grunt) {
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
            lib: ['lib/'],
            doc: ['doc/'],
            test: ['test/**/*.cpl.js', 'test/tmp/']
        },
        codo: {
            options: {
                name: 'Node Grypher',
                title: 'Node.js parser from Grypher to JSON Schema',
                extra: [ 'LICENSE-MIT' ],
                undocumented: true,
                stats: false
            },
            src: [ 'src/' ]
        },
        watch: {
            all: {
                files: ['**/*.js', '**.*.coffee', 'data/*.jison', 'test/fixtures/*.*', '!node_modules/**/*.js', '!lib/**/*.js'],
                tasks: ['default'] ,
                options: {
                    nospawn: true
                }
            }
        }
    });

    // Send coverage report to Coveralls.io only for Travis CI builds.
    var mochaCoverageTask = 'mochacov:' + (process.env.TRAVIS ? 'travis' : 'local');

    grunt.loadNpmTasks('grunt-jison');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-mocha-cov');
    grunt.loadNpmTasks('grunt-release');
    grunt.loadNpmTasks('grunt-execute');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-codo');
    grunt.loadNpmTasks('grunt-coffeelint');

    grunt.registerTask('compile', ['clean:lib', 'clean:test', 'jshint', 'jison', 'coffeelint', 'clean:test', 'coffee', 'copy:sources']);
    grunt.registerTask('document', ['clean:doc', 'codo']);
    grunt.registerTask('e2e', ['execute:e2e']);
    grunt.registerTask('test', ['mochacov:test', 'e2e']);
    grunt.registerTask('test-ci', ['mochaCoverageTask', 'e2e']);
    grunt.registerTask('ci', ['compile', 'test-ci']);
    grunt.registerTask('default', ['compile', 'test', 'document', 'watch']);
    grunt.registerTask('publish', ['ci', 'release']);
};
