module namespace funct = 'sandbox/ivgpu/вопросник/функции';


declare function funct:tpl( $tplPath, $params ){
  let $tpl := fetch:text( file:base-dir() || $tplPath )
  return
    funct:replace( $tpl, $params )
};

declare function funct:replace( $string, $map ){
  let $result :=
    fold-left(
          map:for-each( $map, function( $key, $value ){ map{ $key : $value } } ),
          $string, 
          function( $string, $d ){
             replace(
              $string,
              "\{\{" || map:keys( $d )[ 1 ] || "\}\}",
              replace( serialize( map:get( $d, map:keys( $d )[ 1 ] ) ), '\\', '\\\\' )
            ) 
          }
        )
   return
     parse-xml( $result )
};

declare
  %public
function funct:getData( $path ){
  
};