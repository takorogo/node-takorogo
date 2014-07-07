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
        mochacli: {
            all: ['test/**/*.js'],
            options: {
                reporter: 'spec',
                ui: 'tdd'
            }
        },
        watch: {
            js: {
                files: ['**/*.js', 'data/*.jison', 'test/fixtures/**', '!node_modules/**/*.js'],
                tasks: ['default'],
                options: {
                    nospawn: true
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-jison');
    grunt.loadNpmTasks('grunt-contrib-jshint');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-mocha-cli');
    grunt.loadNpmTasks('grunt-release');
    grunt.registerTask('test', ['jshint', 'jison', 'mochacli', 'watch']);
    grunt.registerTask('ci', ['jshint', 'jison', 'mochacli']);
    grunt.registerTask('default', ['test']);
    grunt.registerTask('publish', ['ci', 'release']);
};
