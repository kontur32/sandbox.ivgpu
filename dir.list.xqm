module namespace ivgpu = 'dir.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/dir.List' )
  %rest:query-param( 'dir', '{ $dir }', '07.03.01' )
  %rest:query-param( 'year', '{ $year }', '2019' )
  %output:method( 'xhtml' )
function ivgpu:view( $dir, $year ){
let $b := data:getProgrammData()[ @КодНаправления = $dir and @Год = $year ]
let $list :=   
  for $i in $b
  order by $i/@НазваниеПрофиля/data()
  where $i/@КодНаправления/data()
  let $fileURL := $i/Файл/@DETAIL__URL/data()
  let $fileName := tokenize( $fileURL, '/' )[ last() ]
  return
    <li>{ normalize-space( $i/@НазваниеПрофиля )|| ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра} (<a href = '{ $fileURL }'>{ $fileName }</a>)</li>
    
return
 <html>
   <body>
     <h2>Профили по направлению { $dir } за { $year } год</h2>
     <ul>{ $list }</ul>
   </body>
 </html>
};