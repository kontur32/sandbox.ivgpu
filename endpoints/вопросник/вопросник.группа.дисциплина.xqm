module namespace q = 'sandbox/ivgpu/вопросник';

declare
  %rest:path( '/sandbox/ivgpu/quiz/{$группа}/{$дисциплина}' )
  %output:method( 'xhtml' )
function q:main( $группа, $дисциплина ){
  let $result := 
    for $i in q:комбинацияВопросов( $дисциплина )[ position() = ( 1 to 6 ) ]
    count $c
    let $разрывСтраницы :=
      if( $c = ( 3, 5 ) )then( "container mb-2 border article" )else( "container mb-2 border" )
    let $qrHref := 
      web:create-url(
        'https://chart.googleapis.com/chart',
        map{
          'cht': 'qr',
          'chs' : '200x200',
          'choe' : 'UTF-8',
         
          'chl' : fetch:text( iri-to-uri( 'https://clck.ru/--?url=http://iro37.ru:9984/sandbox/ivgpu/вопросник/' || $группа ||'/' || $дисциплина || '/ответы' ) )
        }
      )
    return
      <div style="height: 180mm; width: 100%" class = "{ $разрывСтраницы }">
        <div class = 'row ml-1' style="height: 10%;">Билет № { $c }({ $дисциплина })</div>
        <div class = 'row' style="height: 45%;">
          <div class = 'col-12 h-25'>Вопрос № 1: { $i?1/text() }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 text-center border'>
            <img class="img-thumbnail" style="height: 100%;" src = '{$qrHref}'/>
          </div>
        </div>
        <div class = 'row' style="height: 45%;">
          <div class = 'col-12 h-25'>Вопрос № 2: { $i?2/text() }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 border'></div>
        </div>
      </div>
   let $экзаменационныйЛист := 
    for $i in  ( 1 to 2 ) 
    return
      <div style="height: 180mm; width: 100%" class = "container mb-2 border">
        <div class = 'row'>
          <div class = 'col-12 h2 text-center'>ЭКЗАМЕНАЦИОННЫЙ ЛИСТ</div>
        </div>
      </div>
      
   let $params := 
    map{
      'дисциплина' : $дисциплина,
      'данные' : $result,
      'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;">{$экзаменационныйЛист}</div>
    }
   
   return
     q:tpl( $params )
};

declare function q:tpl( $params ){
  let $tpl := fetch:text( iri-to-uri( 'http://localhost:9984/static/ivgpu/src/вопросы.html' ) )
  return
    q:replace( $tpl, $params )
 
};

declare function q:комбинацияВопросов( $дисциплина ){
  let $path := 
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTyFIaIv-44-MM7w5qcS7HHggEktJfyp9mwYoH2kYCmRYGiQFMMJ8zhvJOYepQAEmJYQyd8i7ag_UNp/pub?output=xlsx'
  
  let $data :=
    q:request( $path )/file/table[ @label = 'Вопросы' ]
    /row[ cell[ @label = 'Дисциплина' ] = $дисциплина ]
  
  let $вопросы := $data/cell[ matches( @label, 'Вопрос' ) ]
  
  let $комбинацияВопросов := 
    for $i in 1 to 4
    for $j in $i to 4
    where $i != $j
    return
      [ $вопросы[ $i ], $вопросы[ $j ] ]
  return
    $комбинацияВопросов
};

declare function q:replace( $string, $map ){
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

declare function q:request( $path ){  
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