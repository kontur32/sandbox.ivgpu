module namespace ivgpu = '/sandbox/ivgpu/plans.list';

declare 
  %rest:path('/sandbox/ivgpu/proc')
  %output:method( 'text' )
function ivgpu:main(){
  proc:execute('ls', ('-l', '-a'))
};