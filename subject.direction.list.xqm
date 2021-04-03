module namespace ivgpu = 'subjects.Departments.List';


import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';


declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $disc }/directions' )
  %rest:query-param( 'dep', '{ $dep }' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %output:method( 'xhtml' )
function ivgpu:view( $disc, $year, $dep ){
   
   let $years := tokenize( $year, ',' )
 
   let $d := 
     data:getProgrammData()
     [ Дисциплины/Дисциплина/@Название/data() = web:decode-url( $disc ) ]
     [ @Год = $years ]
  
  let $items :=   
    for $i in $d
    let $дисциплина := $i/Дисциплины/Дисциплина[ @Название/data() = web:decode-url( $disc )  ]
    
    where  if( $dep )then( $дисциплина/@КодКафедры/data() = $dep )else( true() )
    order by $i/@ФормаОбучения/data()
    order by $дисциплина/@КодКафедры/number( data() )
   
    let $href := 
      '/sandbox/ivgpu/api/directions/' || $i/@Год/data() || '/' || $i/@КодНаправления/data() || '/' || $i/Файл/@ID/data() ||  '/очная/аннотации'
    let $urlРУПа := $i/Файл/@DETAIL__URL/data()
    let $urlРУПаЕксель := replace( $urlРУПа, '.plx', '.plx.xls')
    return
       <li >{ $i/@КодНаправления/data() } : <a href = "{ $href }">{ $i/@НазваниеПрофиля/data() }</a> (<a href = "{ $urlРУПа }">{ $i/Файл/@ID/data() }</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) : { $i/@Год/data() } : { $i/@ФормаОбучения/data() } : кафедра - { $дисциплина/@КодКафедры/data() }</li>
 
  return
    <html>
      <body>
        <h2>Дисциплина "{ $disc }" в РУПах { string-join( sort( $years ), ', ' ) } годов приёма</h2>
        <ol> { $items }</ol>  
      </body>
    </html>
};