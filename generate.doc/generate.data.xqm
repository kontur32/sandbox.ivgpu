module namespace data = '/sandbox/ivgpu/generate/data';
 
declare function data:getProgrammData(){
  let $ООПнаАккредитацию :=
    let $csv := 
      fetch:text( 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=731239307&amp;single=true&amp;output=csv' ) 
    return
      csv:parse( $csv, map{ 'header' : true() } )
      /csv/record/ID/tokenize( replace( text(), '\s', '' ), ',' )
          
  let $Программы :=
    db:open( 'tmp-simplex', '.187254.simplex.xml' )
    /Программы/Программа
    [ Файл/@ID/data() = $ООПнаАккредитацию ]
  
  return 
    $Программы 
};

declare
  %public
function data:getProgrammsEqual( $программа as element( Программа ) )
 as element( Программа )*
{
  data:getProgrammData()
    [ @КодНаправления = $программа/@КодНаправления ]
    [ @НазваниеПрофиля = $программа/@НазваниеПрофиля ]
    [ @КодФормыОбучения = $программа/@КодФормыОбучения ]
    [ @Год = $программа/@Год ]
};