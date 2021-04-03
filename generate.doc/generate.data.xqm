 module namespace data = '/sandbox/ivgpu/generate/data';
 
 declare function data:getProgrammData(){
 
  let $Программы :=
    db:open( 'tmp-simplex', '.187254.simplex.xml' )
    /Программы/Программа
  
  return 
    $Программы 
 };