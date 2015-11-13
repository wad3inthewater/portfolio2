var gulp = require('gulp'),
    sass = require('gulp-sass'),
    jshint = require('gulp-jshint');


gulp.task('jshint', function() {
  gulp.src('./public/javascript/*.js')
    .pipe(jshint())
    .pipe(jshint.reporter('default'));
});

gulp.task('sass', function(){
  gulp.src('./public/sass/*.scss')
    .pipe(sass().on('error', sass.logError))
    .pipe(gulp.dest('./public/css'));
});

// gulp.task('sass:watch', function () {
//   gulp.watch('./sass/**/*.scss', ['sass']);
// });

gulp.task('default',['jshint','sass'],  function() {
  //watches for sass changes
  gulp.watch('./public/sass/**/*.scss',['sass']);
  //watches for js changes
  gulp.watch('./public/javascript/**/*.js', ['jshint']);
});
