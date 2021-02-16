module namespace ivgpu = 'oop.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/directions/{ $dir }' )
  %rest:query-param( 'year', '{ $yearsList }' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:view( $dir, $yearsList, $dep ){
  let $b := 
    data:getProgrammData()
    [ @КодНаправления = $dir ]
    [ if( $dep )then( @Кафедра = tokenize( $dep, ',' ) )else( true() ) ]
  
  let $years := 
    if( $yearsList )
    then(
      tokenize( $yearsList, ',' )
    )
    else(
      distinct-values( $b/@Год/data() )
    )
    
  let $list :=
    function( $year ){   
      for $i in $b[ @Год = $year ]
      order by $i/@НазваниеПрофиля/data()
      where $i/@КодНаправления/data()
      let $fileURL := $i/Файл/@DETAIL__URL/data()
      let $fileName := tokenize( $fileURL, '/' )[ last() ]
      let $href := 
        '/sandbox/ivgpu/api/directions/' ||
        $year || '/' ||
        $dir || '/' ||
        $i/Файл/@ID/data() || '/' ||
        $i/@ФормаОбучения/data() || '/аннотации' 
      let $update := 
        $i/Файл/@UPDATE__TIME/substring-before( data(), 'T' )
      let $ссылкаАннотации := 
        <a href = "{ $href }">аннотации</a>  
      return
        <li>{ normalize-space( $i/@НазваниеПрофиля )|| ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра} ({$ссылкаАннотации}, <a href = '{ $fileURL }'>{ $fileName }</a>, { $update })</li>
    }
  return
   <html>
     <body>
       <h2>Профили по направлению { $dir } за { string-join( sort( $years ), ', ') } год(ы)</h2>
       {
         for $y in $years
         order by number( $y )
         return
           <ol><h3>{ $y }</h3>{ $list( $y ) }</ol>
       }
     </body>
   </html>
};

declare 
  %rest:path( '/sandbox/ivgpu/list/oop' )
  %rest:query-param( 'year', '{ $yearsList }' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:полныйСписок( $yearsList, $dep ){

  let $b := 
    data:getProgrammData()
    [ if( $dep )then( @Кафедра = tokenize( $dep, ',' ) )else( true() ) ]
  
  let $years := 
    if( $yearsList )
    then( tokenize( $yearsList, ',' ) )
    else( true() )

  return
     <html>
       <body>
         <h3>Список РУПов по дате обновления</h3>
         <ol>{ ivgpu:списокООП( $b ) }</ol>
       </body>
     </html>
};

declare function ivgpu:списокООП( $data ){   
      for $i in $data
      let $update := 
        $i/Файл/@UPDATE__TIME/substring-before( data(), 'T' )
      order by $update descending
      where $i/@КодНаправления/data()
      let $fileURL := $i/Файл/@DETAIL__URL/data()
      let $fileName := tokenize( $fileURL, '/' )[ last() ]
      let $href := 
        '/sandbox/ivgpu/api/directions/' ||
        $i/@Год/data() || '/' ||
        $i/@КодНаправления/data() || '/' ||
        $i/Файл/@ID/data() || '/' ||
        $i/@ФормаОбучения/data() || '/аннотации' 
      
      let $ссылкаАннотации := 
        <a href = "{ $href }">аннотации</a>  
      return
        <li>{ $update } : { normalize-space( $i/@НазваниеПрофиля )|| ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра} ({$ссылкаАннотации})</li>
};