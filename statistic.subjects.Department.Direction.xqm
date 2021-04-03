module namespace ivgpu = '/sandbox/ivgpu/v0.2/subjects.Department.Direction';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/subjects.Department.Direction' )
  %rest:query-param( 'id', '{ $id }', '21' )
  %rest:query-param( 'year', '{ $year }', '2019' )
  %rest:query-param( 'mode', '{ $mode }', 'other' )
  %rest:query-param( 'subj', '{ $subj }' )
  %rest:query-param( 'fgos', '{ $fgos }' )
  %output:method( 'json' )
function ivgpu:main( $id, $year, $mode, $subj, $fgos ){
    let $params:=
    map{
      'mode' : $mode,
      'year' : $year,
      'id' : $id,
      'fgos' : '3P',
      'subj' : ''
    }
      
  let $data:= ivgpu:getData( $params )
  let $list := 
    distinct-values( 
      rup:getFileContentList( '46686' )/NAME/ normalize-space( substring-before( text(), '_' ) ) 
    )
  let $countData := count( $data )
  let $result :=
    if( $countData > 0 )
    then(
      round( count( $data[ @Название = $list ] ) div $countData * 100 )
    )
    else( 0 )
   
  return
    map{
      'result' : $result
  }
};

declare function ivgpu:getData( $params ){
  let $data := 
    data:getProgrammData( )
      [ @Год = $params?year ]
      [
        switch ( $params?mode )
        case 'own' return @Кафедра = $params?id
        case 'other'  return @Кафедра != $params?id
        default return true()
      ]
      [ if( $params?fgos and @ФГОС )then( @ФГОС = $params?fgos )else( true() ) ]
        /Дисциплины/Дисциплина
          [ @КодКафедры = $params?id ]
          [ if( $params?subj )then( @Название = $params?subj )else( true() ) ]
  return  
     $data
};