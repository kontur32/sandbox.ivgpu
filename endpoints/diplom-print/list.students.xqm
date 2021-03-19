module namespace ivgpu = '/sandbox/ivgpu/diplom/print';
import module namespace request = "http://exquery.org/ns/request";

declare 
  %rest:path( '/sandbox/ivgpu/diplom/print/2021/{ $группа }' )
  %output:method( 'xhtml' )
function ivgpu:main( $группа ){
  let $path := 
    switch ( $группа )
    case 'ЭПОдз-53' 
      return
         'https://docs.google.com/spreadsheets/d/e/2PACX-1vTQOmzf1ez2H2AxsZH1AbMHEFVKbQKCgurs5SsqQA4gGPqIG1Q_jce9XUvnGzYj0m12d6vEdnTBFONH/pub?output=xlsx'
    case 'ЭФКдз-51' 
      return
         'https://docs.google.com/spreadsheets/d/e/2PACX-1vSK9z8pL98sc2JpJc8gQhpu_2nnaigXy4f2uYvXbcR9pV0mUTkArfdkCwYtnGQKUmnbwOUJj6jG63Ai/pub?output=xlsx'
    case 'ЭФКдз-52' 
      return
         'https://docs.google.com/spreadsheets/d/e/2PACX-1vS8hYjruYsCjAU8uvz13JjGciyYyjYQKjrlk-5l9UyuB6oVLIkhcHaM04uiJd1ha0OnqcECxPgUja7h/pub?output=xlsx'
    default
      return
       'https://docs.google.com/spreadsheets/d/e/2PACX-1vTQOmzf1ez2H2AxsZH1AbMHEFVKbQKCgurs5SsqQA4gGPqIG1Q_jce9XUvnGzYj0m12d6vEdnTBFONH/pub?output=xlsx'  
  
  let $rawData := fetch:binary( $path )
  let $данные := ivgpu:trci( $rawData )/file/table[ @label = 'Студенты' ]
  let $студенты :=
    <table>
      <tr class = 'text-center'>
        <th>№ пп</th>
        <th>Студент</th>
        <th>Страница 1-3</th>
        <th>Страница 2-4</th>
      </tr>
      {
        for $i in $данные/row
        count $c
        let $номер := $i/cell[ @label = 'Номер']/text()
        let $путь := '/sandbox/ivgpu/diplom/print/2021/' || $группа || '/'|| $номер  
        let $href1 := $путь || '/1'
        let $href2 := $путь || '/2'
        return
        <tr>
          <td>{ $c }.</td>
          <td>
            {
              string-join(
                (
                  $i/cell[ @label = 'Фамилия'],
                  $i/cell[ @label = 'Имя'],
                  $i/cell[ @label = 'Отчество']
                ),
                ' '
              )
            }
          </td>
          <td class = 'text-center'><a href = "{ $href1 }">скачать</a></td>
          <td class = 'text-center'><a href = "{ $href2 }">скачать</a></td>
        </tr>
      }
      
    </table>
  let $страница :=
    <div class = "m-4">
      <h2>Сервис распечатки приложений к диплому</h2>
      <h4>Группа { $группа }</h4>
      { $студенты }
    </div>
  let $tpl := doc( "../../html/main.tpl.html" )
  return
    $tpl update insert node $страница into .//body 
  
};

declare function ivgpu:trci( $rawData ){
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
      let $response := 
          http:send-request(
              $request,
              "http://localhost:9984/ooxml/api/v1.1/xlsx/parse/workbook"
          )
      return
       $response[ 2 ]
};
  