module namespace data = '/sandbox/ivgpu/generate/data';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';

declare function data:getProgramms(){
  db:open( 'tmp-simplex', '.187254.simplex.xml' )
    /Программы/Программа
};

declare function data:getProgrammData( $ID ){
  db:open( 'tmp-simplex', '.187254.simplex.xml' )
    /Программы/Программа
    [ Файл/@ID/data() = $ID ]
};

declare function data:getProgrammData(){
  let $ООПнаАккредитацию :=
    
    let $csv := 
      data:getResourceCSV( config:param( 'ресурс.ООПнаАккредитацию' ) )
    
    return
      $csv
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
    [ @КодФормыОбучения = $программа/@КодФормыОбучения ]
    [ @КодНаправления = $программа/@КодНаправления ]
    [ @Год = $программа/@Год ]
    [ @НазваниеПрофиля = $программа/@НазваниеПрофиля ]
};

declare
  %public
function data:getResource( $resourcePath as xs:string, $function )
 as node()*
{
   data:getResource( $resourcePath, $function, map{ 'mode' : 'refresh' } )
};

declare
  %public
function data:getResource( $resourcePath as xs:string, $function, $params )
 as node()*
{
  let $hash :=  xs:string( xs:hexBinary( hash:md5( $resourcePath ) ) )
  let $cache := 
      let $res := try{ doc( config:param( 'cache.dir' ) || $hash ) }catch*{}
      return
        if( not( $res//record ) or $params?mode = 'refresh' )
        then(
          let $res2 := 
            try{
              $function( $resourcePath )
            }catch*{}
          let $w := file:write( config:param( 'cache.dir' ) || $hash, $res2 )
          return
             $res2
        )
        else( $res )
  return
    $cache
};

declare
  %public
function data:getResourceCSV( $resourcePath as xs:string )
 as node()*
{
  data:getResourceCSV( $resourcePath, map{ 'mode' : '' } )
};

declare
  %public
function data:getResourceCSV( $resourcePath as xs:string, $params as map(*) )
 as node()*
{
  let $funct := 
    function( $resourcePath ){
      csv:parse( fetch:text( $resourcePath ), map{ 'header' : true() } )
    }
  return
    data:getResource( $resourcePath, $funct, $params )
};

declare
  %public
function data:getResourceXML( $resourcePath as xs:string, $params as map(*) )
 as node()*
{
  let $funct := function( $resourcePath ){ fetch:xml( $resourcePath ) }
  return
    data:getResource( $resourcePath, $funct, $params )
};

declare
  %public
function data:getResourceXML( $resourcePath as xs:string )
 as node()*
{
  let $funct := function( $resourcePath ){ fetch:xml( $resourcePath ) }
  return
    data:getResource( $resourcePath, $funct )
};