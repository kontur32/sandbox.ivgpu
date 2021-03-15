module namespace ivgpu = '/sandbox/ivgpu/diplom/print';
import module namespace request = "http://exquery.org/ns/request";

declare 
  %rest:path( '/sandbox/ivgpu/diplom/print/2021/ЭПОдз-53' )
  %output:method( 'xhtml' )
function ivgpu:main(){
let $rawData := 
      fetch:binary(
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vTQOmzf1ez2H2AxsZH1AbMHEFVKbQKCgurs5SsqQA4gGPqIG1Q_jce9XUvnGzYj0m12d6vEdnTBFONH/pub?output=xlsx' )
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
        let $href1 := '/sandbox/ivgpu/diplom/print/2021/ЭПОдз-53/'|| $номер || '/1'
        let $href2 := '/sandbox/ivgpu/diplom/print/2021/ЭПОдз-53/'|| $номер || '/2'
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
      <h4>Группа ЭПОдз-53</h4>
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
  