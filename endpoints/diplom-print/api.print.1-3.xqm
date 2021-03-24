module namespace ivgpu = '/sandbox/ivgpu/diplom/print';
import module namespace request = "http://exquery.org/ns/request";

declare 
  %rest:path( '/sandbox/ivgpu/diplom/print/2021/{ $группа }/{ $id }/1' )
function ivgpu:main( $id, $группа ){
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
  let $данные := ivgpu:trci( $rawData )
  let $xq := fetch:text( request:scheme() ||  '://' || request:hostname() || ':' || request:port() ||'/static/simplex/funct/ocenki.student.xq' )
  
  let $оценки := xquery:eval( $xq, map{ "" : $данные , 'params' : map{ 'id' : $id, 'group' : 'Сводная ведомость'} }  )/оценки/дисциплина
  
  let $данныеСтудента := 
    $данные/file/table[ @label = 'Студенты' ]/row[ cell[ @label = 'Номер' ]/text() = $id ]
  
  (: для иностранных студенов :)
  let $годПредыдущегоДокумента := 
    if( matches( $данныеСтудента/cell[ @label = 'Год предыдущийДокумент']/text(), 'год' ) )
    then(
      $данныеСтудента/cell[ @label = 'Год предыдущийДокумент']/text()
    )
    else(
      $данныеСтудента/cell[ @label = 'Год предыдущийДокумент']/text() || ' год'
    )
  let $data := 
 <table>
    <row  id = 'fields'>
      <cell id = "Фамилия" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'Фамилия']/text() }</cell>
      <cell id = "Имя" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'Имя']/text() }</cell>
      <cell id = "Отчество" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'Отчество']/text() }</cell>
      <cell id = "ДатаРождения" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'ДатаРождения']/text() }</cell>
      <cell id = "предыдущийДокумент" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'предыдущийДокумент']/text() }, { $годПредыдущегоДокумента }</cell>
      <cell id = "ДатаВыдачи" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'ДатаВыдачи']/text() }</cell>
      <cell id = "номер" contentType = 'field'>{ $данныеСтудента/cell[ @label = 'номер']/text() }</cell>
      <cell id = "отличие" contentType = 'field'>бакалавр { $данныеСтудента/cell[ @label = 'отличие']/text() }</cell>
    </row>
    <row id = 'tables'>
      <cell id = 'ОценкиКурсовые'>
        <table>
        {
          for $i in $оценки[ формаОтчетности/text() = 'курсовая работа' ]
          return
             <row>
              <cell>{ $i/название/text() }</cell>
              <cell>{ $i/оценкаПрописью/text() }</cell>
            </row>
        }
        </table>
      </cell>
    </row>
  </table>
   
  let $templatePath := 
      'http://dbx.iro37.ru/zapolnititul/api/v2/forms/841d7cb3-a27e-4fc4-ad80-bba1b899b667/template'
      
  let $fileName :=  $данныеСтудента/cell[ @label = 'Фамилия']/text() || '-diplom-1-3.docx' 
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  ) 
  return
    (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      ivgpu:fillTemplate( $data, $templatePath, $fileName )
    )
};

declare function ivgpu:fillTemplate( $fields, $templatePath, $fileName ){
  let $template := fetch:binary( $templatePath )
  let $request :=
      <http:request method='post'>
        <http:multipart media-type = "multipart/form-data" >
            <http:header name="Content-Disposition" value= 'form-data; name="template";'/>
            <http:body media-type = "application/octet-stream" >
              { $template }
            </http:body>
            <http:header name="Content-Disposition" value= 'form-data; name="data";'/>
            <http:body media-type = "application/xml">
              { $fields }
            </http:body>
        </http:multipart> 
      </http:request>
    
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )
  let $response := 
     http:send-request (
        $request,
        'http://localhost:9984/api/v1/ooxml/docx/template/complete'
      )
  return
     $response[2]
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