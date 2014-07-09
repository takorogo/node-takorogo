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
                files: ['test/**/*.js']
            }
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
    grunt.registerTask('test', ['jshint', 'jison', 'mochacov:test', 'watch']);
    grunt.registerTask('ci', ['jshint', 'jison', mochaCoverageTask]);
    grunt.registerTask('default', ['test']);
    grunt.registerTask('publish', ['ci', 'release']);
};
