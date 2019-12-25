module namespace ivgpu = 'dir.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/dir.List' )
  %rest:query-param( 'dir', '{ $dir }', '07.03.01' )
  %rest:query-param( 'year', '{ $yearsList }', '2015,2016,2017,2018,2019' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:view( $dir, $yearsList, $dep ){
let $years := tokenize( $yearsList, ',' )
  let $b := 
    data:getProgrammData()
    [ @КодНаправления = $dir ]
    [ if( $dep )then( @Кафедра = tokenize( $dep, ',' ) )else( true() ) ]
  let $list :=
    function( $year ){   
    for $i in $b[ @Год = $year ]
    order by $i/@НазваниеПрофиля/data()
    where $i/@КодНаправления/data()
    let $fileURL := $i/Файл/@DETAIL__URL/data()
    let $fileName := tokenize( $fileURL, '/' )[ last() ]
    return
      <li>{ normalize-space( $i/@НазваниеПрофиля )|| ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра} (<a href = '{ $fileURL }'>{ $fileName }</a>)</li>
    }
  return
   <html>
     <body>
       <h2>Профили по направлению { $dir } за { string-join( sort( $years ), ', ') } год(ы)</h2>
       {
         for $y in $years
         order by number( $y )
         return
           <ul><h3>{ $y }</h3>{ $list( $y ) }</ul>
       }
     </body>
   </html>
};