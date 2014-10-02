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
                files: ['test/**/*.test.js']
            }
        },
        execute: {
            e2e: {
                src: ['test/*.e2e.js']
            }
        },
        copy: {
            sources: {
                files: [
                    { expand: true, src: ['**'], cwd: 'src/', dest: 'lib/' }
                ],
                mode: true
            }
        },
        clean: {
            lib: ['lib/']
        },
        watch: {
            js: {
                files: ['**/*.js', 'data/*.jison', 'test/fixtures/*.*', '!node_modules/**/*.js'],
                tasks: ['default'],
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

    grunt.registerTask('compile', ['clean:lib', 'jison', 'copy:sources']);
    grunt.registerTask('e2e', ['execute:e2e']);
    grunt.registerTask('test', ['jshint', 'compile', 'mochacov:test', 'e2e', 'watch']);
    grunt.registerTask('ci', ['jshint', 'compile', mochaCoverageTask, 'e2e']);
    grunt.registerTask('default', ['test']);
    grunt.registerTask('publish', ['ci', 'release']);
};
