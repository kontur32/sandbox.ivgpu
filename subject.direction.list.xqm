module namespace ivgpu = 'subjects.Departments.List';


import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';


declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $disc }/directions' )
  %rest:query-param( 'dep', '{ $dep }', '21' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %rest:query-param( 'дата', '{ $auth }' )
  %output:method( 'xhtml' )
function ivgpu:view( $disc, $year, $dep, $auth ){
   
   let $авторизация :=
     if( $auth = '1844-02-20' )
     then( session:set( 'auth', 'ok' ) )
     else( session:set( 'auth', 'нет' ))
   
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
    
    let $check :=
      fetch:xml(
       'http://localhost:9984/sandbox/ivgpu/api/v01/generate/%D0%A0%D0%9F%D0%94.%D0%A2%D0%B8%D1%82%D1%83%D0%BB/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/check'
      )/items/item[ 1 ]
    
    let $маркер :=
      if( $check )
      then( <span style = 'color : green;'>&#9679;</span> )
      else( <span style = 'color : red;'>&#9679;</span> )
    
    let $hrefUpload := 
      '/sandbox/ivgpu/api/v01/generate/РПД.Титул/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/upload'
    
    return
       <li>
         { $маркер }{ $i/@КодНаправления/data() } : <a href = "{ $href }">{ $i/@НазваниеПрофиля/data() }</a> (<a href = "{ $urlРУПа }">{ $i/Файл/@ID/data() }</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) : { $i/@Год/data() } : { $i/@ФормаОбучения/data() } : кафедра - { $дисциплина/@КодКафедры/data() }
         {
           if( $check )
           then(
             <span  class = 'text-success'>
                 файл загружен  
                 (
                   <a href = "{ $check/DOWNLOAD_URL/text()}">скачать</a>,
                   <a href = "{ $check/DETAIL_URL/text()}" target = '_blank'>просмотреть</a>
                 )
               </span>
           )
           else( <a href = '{ $hrefUpload }'><button>загрузить</button></a> )
         }
          
       </li>
 
  return
    <html>
      <body>
        <h2>Дисциплина "{ $disc }" в РУПах { string-join( sort( $years ), ', ' ) } годов приёма</h2>
        <div>Статус авторизации: { session:get( 'auth' ) }</div>
        <form action = "{ '/sandbox/ivgpu/statistic/lists/subjects/' || $disc || '/directions' }" class = "my-1">
           <div class="form-group my-1">
             <label>Введите дату</label>
           </div>
           <input type = 'date' name = 'дата'/>
           <input type = 'submit' value = 'Отправить'/>
        </form>
        
        <ol> { $items }</ol>  
      </body>
    </html>
};