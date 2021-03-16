module namespace ivgpu = '/sandbox/ivgpu/diplom/print';
import module namespace request = "http://exquery.org/ns/request";

declare 
  %rest:path( '/sandbox/ivgpu/diplom/print/2021/ЭПОдз-53/{ $id }/2' )
function ivgpu:main( $id ){
  let $rawData := 
      fetch:binary(
            'https://docs.google.com/spreadsheets/d/e/2PACX-1vTQOmzf1ez2H2AxsZH1AbMHEFVKbQKCgurs5SsqQA4gGPqIG1Q_jce9XUvnGzYj0m12d6vEdnTBFONH/pub?output=xlsx' )
  let $данные := ivgpu:trci( $rawData )
  let $xq := fetch:text( 'http://localhost:' || request:port() ||'/static/simplex/funct/ocenki.student.xq' )
  
  let $оценки := xquery:eval( $xq, map{ "" : $данные , 'params' : map{ 'id' : $id, 'group' : 'Сводная ведомость'} }  )/оценки
  
  let $данныеСтудента := $данные/file/table[ @label = 'Студенты' ]/row[ cell[ @label = 'Номер' ]/text() = $id ]
  
  let $fields := ivgpu:getDipolma.2( $данныеСтудента, $оценки )
   
  let $templatePath := 
      'http://dbx.iro37.ru/zapolnititul/api/v2/forms/' || 'fa2ea490-35df-4395-bfd7-0129affa1617'  || '/template'
      
  let $fileName := 'diplom-' || '2-4' || '.docx' 
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
      ivgpu:fillTemplate( $fields, $templatePath, $fileName )
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

declare function ivgpu:getDipolma.2( $данныеСтудента, $оценки ){
let $оценкиПоПредметам := 
      (
        <table>
        {
          for $i in $оценки/дисциплина[ position() <= 59 ][ ЗЕТ/text() ][ формаОтчетности/text() = "экзамен" ]
          return
            <row>
              <cell>{  $i/название/text() }</cell>
              <cell>{ $i[ last() ]/ЗЕТ/text() } з.е.</cell>
              <cell>{ $i[ last() ]/оценкаПрописью/text() }</cell>
            </row>
        }
        </table>,
        <table>
         {
          for $i in$оценки/дисциплина[ position() > 59 ][ ЗЕТ/text() ][ формаОтчетности/text() = "экзамен" ]
          return
            <row>
              <cell>{ $i/название/text() }</cell>
              <cell>{ $i/ЗЕТ/text() } з.е.</cell>
              <cell>{ $i/оценкаПрописью/text() }</cell>
            </row>
        }
        <row>
          <cell>Практики</cell>
          <cell></cell>
          <cell></cell>
        </row>
        <row>
          <cell>в том числе:</cell>
          <cell></cell>
          <cell></cell>
        </row>
        {
          for $i in $оценки/дисциплина[ ЗЕТ/text() ][ формаОтчетности = "практика" ]
          where $i[ формаОтчетности/text()  ]
          let $название := $i/название/text()          
          return
            <row>
              <cell>{ $название }</cell>
              <cell>{ $i[ last() ]/ЗЕТ/text() } з.е.</cell>
              <cell>{ $i[ last() ]/оценкаПрописью/text() }</cell>
            </row>
        }
        <row>
          <cell>Государственная итоговая аттестация</cell>
          <cell>{ $оценки/дисциплина[ название/text() = "Государственная итоговая аттестация" ]/ЗЕТ/text() } з.е.</cell>
          <cell>х</cell>
        </row>
        <row>
          <cell>в том числе:</cell>
          <cell></cell>
          <cell></cell>
        </row>
        <row>
          <cell>Выпускная квалификационная работа (бакалаврская работа)</cell>
          <cell></cell>
          <cell></cell>
        </row>
        <row>
          <cell>"{ $данныеСтудента/cell[ @label = 'Тема ВКР']/text() }"</cell>
          <cell>х</cell>
          <cell>{ $оценки/дисциплина[ название/text() = "Государственная итоговая аттестация" ]/оценкаПрописью/text() }</cell>
        </row>
        <row>
          <cell>Объём образовательной программы</cell>
          <cell>240 з.е.</cell>
          <cell>х</cell>
        </row>
        <row>
          <cell>В том числе объём работы во взаимодействии с</cell>
          <cell></cell>
          <cell></cell>
        </row>
        <row>
          <cell>преподавателем:</cell>
          <cell>452 час.</cell>
          <cell>х</cell>
        </row>
      </table>
    )

return
  <table>
    <row id = 'tables'>
      <cell id = 'Оценки1'>
        { $оценкиПоПредметам[ 1 ] }
      </cell>
      <cell id = 'Оценки2'>
        { $оценкиПоПредметам[ 2 ] }
      </cell>
    </row>
  </table>
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