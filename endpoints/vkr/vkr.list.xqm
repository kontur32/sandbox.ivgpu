module namespace vkr = 'sandbox/ivgpu/vkr';

declare
  %rest:path( '/sandbox/ivgpu/vkr' )
  %rest:query-param( 'группа', '{ $g }' )
  %output:method( 'xhtml' )
function vkr:main( $g ){
  let $data := vkr:request()
  let $группа :=
    if( $g != "" )
    then( $g )
    else( $data/file/table[ matches( @label, '-') ][ 1 ]/@label/data() )
  let $текущаяГруппа := vkr:текущаяГруппа( $data, $группа )
  let $таблица := vkr:table( $data, $группа )
  let $всеГруппы := $data/file/table[ matches( @label, '-') ]
  let $всегоОтчислены := $всеГруппы/row[ cell[ @label = 'Эл' ] = 'Отчислен' ]
  let $данныеГруппы := $всеГруппы[ @label = $g ]
  let $отчисленыВГруппе := 
    $данныеГруппы/row[ cell[ @label = 'Эл' ] = 'Отчислен' ]
  return
    vkr:replace(
      vkr:tplMain(),
      map{
        'группа' : $группа,
        'списокГрупп' : vkr:списокГрупп( $data, $группа ),
        'направлениеПодготовки' : $текущаяГруппа[ 1 ],
        'профильПодготовки' : $текущаяГруппа[ 2 ],
        'количество' : count( $данныеГруппы/row ),
        'отчислены' : count( $отчисленыВГруппе ),
        'защитились' : count( $данныеГруппы/row ) - count( $отчисленыВГруппе ),
        'загружены' : count( $таблица/tbody/tr/td[ 7 ][ a ] ),
        'студентовВсего' : count( $всеГруппы/row ),
        'студентовВсегоОтчислено' : count( $всегоОтчислены ),
        'студентовВсегоЗащитились' : count( $всеГруппы/row ) - count( $всегоОтчислены ),
        'таблица' : $таблица
      }
    )
};

declare function vkr:table( $data, $группа ){
  let $записиГруппы := $data/file/table[ @label= $группа ]
   let $путьФайлов :=  '/static/ivgpu/Зима%202020/' || $группа || '/'
   return
   <table class = "table table-striped">
     <thead >
       <tr class = "align-middle text-center">
         <th>№</th>
         <th>Зачетка</th>
         <th>ФИО студента</th>
         <th>Тема ВКР</th>
         <th>Ключевые слова</th>
         <th>Руководитель</th>
         <th>Ссылка на ВКР</th>
         <th>Ссылка на антиплагиат</th>
       </tr>
     </thead>
     <tbody>
     {
       for $i in $записиГруппы/row
       count $c
       let $ФИОстудента := $i/cell[ @label = "ФИО_студента" ]/text()
       let $ФИОстудентаКороткое := 
         let $t := tokenize( $ФИОстудента )
         return
           string-join( ( $t[1], '_', substring( $t[2], 1, 1 ), '.', substring( $t[3], 1, 1 ) ) )
       let $href := function( $f ){
         let $test:= 
           http:send-request(
              <http:request method='GET'/>,
             iri-to-uri( $f )
          )[1]/@status/data()
         
         return
           if( $test = '200' )
           then( <a href = '{ $f }'>скачать</a> )
           else( 'нет' )
       }
       return
         <tr>
           <td>{ $c }.</td>
           <td>{ $i/cell[ @label = "Зачетка" ]/substring-before( text(), '.') }</td>
           <td>{ $ФИОстудента }</td>
           <td>{ $i/cell[ @label = "Тема_ВКР" ]/text() }</td>
           <td>{ $i/cell[ @label = "Ключевые слова" ]/text() }</td>
           <td>{ $i/cell[ @label = "ФИО_должность_руководителя" ]/text() }</td>
           <td>{ $href( 'http://localhost:9984' || $путьФайлов || "ВКР_" || $ФИОстудентаКороткое || '.pdf' ) }</td>
           <td>{ $href( 'http://localhost:9984' || $путьФайлов || "Антиплагиат_" || $ФИОстудентаКороткое || '.pdf' ) }</td>
         </tr>
     }
     </tbody>
   </table>
};

declare function vkr:tplMain(){
  fetch:text( 'http://localhost:9984/static/ivgpu/src/main.html' )
};

declare function vkr:текущаяГруппа( $data, $группа ){
  let $группы := $data/file/table[ @label = 'Список групп' ]
  let $текущаяГруппа := $группы/row[ cell[ @label = 'Код группы' ] = $группа ][ 1 ]
  return
    (
      $текущаяГруппа/cell[ @label = 'Код направления' ]/text(),
      $текущаяГруппа/cell[ @label = 'Название профиля' ]/text()
    )
};

declare function vkr:списокГрупп( $data, $группа ){
   let $списокГрупп := $data/file/table/@label/data()
   return
     <div>
       <p>
         {
           for $i in $списокГрупп
           where matches( $i, '-' )
           return
             if( $i = $группа )
             then( <b>{ $i }</b>)
             else(
               <a href = "{ '?группа=' || $i }">{ $i }</a>
             )
         }
         <span>(<a href = "/sandbox/ivgpu/vkr/api/эуф/2019-2020/профили">api</a>)</span>
       </p>
     </div>
};

declare function vkr:request(){
  let $path := 
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTdknxFBgxhKfzPEOU2aIp5fqJqAhAt9nD7Ejb3Eb_55_3gjKm6aK_spGhIflWdaNIJQ1zm3-Az8iEE/pub?output=xlsx'
    
  let $rawData := fetch:binary( $path )
  let $request := 
      <http:request method='POST'>
        <http:header name="Content-type" value="multipart/form-data; boundary=----7MA4YWxkTrZu0gW"/>
        <http:multipart media-type = "multipart/form-data" >
            <http:header name='Content-Disposition' value='form-data; name="data"'/>
            <http:body media-type = "application/octet-stream">
               { $rawData }
            </http:body>
        </http:multipart> 
      </http:request>
  
  let $data := 
      http:send-request(
        $request,
        "http://localhost:9984/ooxml/api/v1.1/xlsx/parse/workbook"
    )[ 2 ]
  return
    $data
};

declare function vkr:replace( $string, $map ){
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