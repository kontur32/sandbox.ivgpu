 module namespace data = '/sandbox/ivgpu/generate/data';
 
 declare function data:getProgrammData(){
    let $Программы1 := doc(
      file:temp-dir() || '.' || '19677' ||'.simplex.xml'
    )/Программы/Программа
  let $Программы2 := doc(
        file:temp-dir() || '.' || '25839' ||'.simplex.xml'
      )/Программы/Программа  
  let $Программы3 := doc(
        file:temp-dir() || '.' || '7266' ||'.simplex.xml'
      )/Программы/Программа 

  return
    ( $Программы1, $Программы2, $Программы3 )
 };