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
        $i/Файл/@ID/data() ||
        '/аннотации' 
      let $update := 
        $i/Файл/@UPDATE__TIME/substring-before( data(), 'T' )
      
      return
        <li><a href = "{ $href }">{ normalize-space( $i/@НазваниеПрофиля ) }</a>{ ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра} (<i><a href = '{ $fileURL }'>шахтинский РУП</a></i>, { $update })</li>
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
         <table>
           <tr>
             <td>№ пп</td>
             <td>Обновлен</td>
             <td>Название ООП, форма обучения, выпускающая кафедра</td>
             <td></td>  
           </tr>
           { ivgpu:списокООП( $b ) }
         </table>
       </body>
     </html>
};

declare function ivgpu:списокООП( $data ){   
      for $i in $data
      
      let $update := 
        $i/Файл/@UPDATE__TIME/substring-before( data(), 'T' )
      order by $update descending
      where $i/@КодНаправления/data()
      count $c
      let $fileURL := $i/Файл/@DETAIL__URL/data()
      let $fileName := tokenize( $fileURL, '/' )[ last() ]
      let $href := 
        $i/Файл/@DETAIL__URL/data()
      let $ссылкаАннотации := 
        <a href = "{ $href }">файл РУП</a>  
      return
        <tr>
          <td>{ $c }. </td>
          <td>{ $update } : </td>
          <td>{ normalize-space( $i/@НазваниеПрофиля )|| ' (' || $i/@ФормаОбучения || '); кафедра: ' || $i/@Кафедра }</td>
          <td>({$ссылкаАннотации})</td>
        </tr>
};