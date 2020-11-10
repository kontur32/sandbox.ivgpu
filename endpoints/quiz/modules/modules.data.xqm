module namespace данные = 'sandbox/ivgpu/вопросник/модули/данные';

declare variable  $данные:вопросыПутьГугл := 
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTyFIaIv-44-MM7w5qcS7HHggEktJfyp9mwYoH2kYCmRYGiQFMMJ8zhvJOYepQAEmJYQyd8i7ag_UNp/pub?output=xlsx';

declare variable  $данные:задолженностьПутьГугл :=     
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTl_qBpwCG7slZvoff3krP-bCIhBOTYQctNQYuqT3yNSvTfVolZBl3f_YcD2hSq2ATdADRzK_oVB6hG/pub?output=xlsx';

declare
  %public
function данные:билетыСтудента( $студент, $группа ){
  let $дисциплиныСтудента :=
   данные:получитьЗадолженностьСтудента( $студент, $группа )
 
 let $ВсеВопросы :=
   данные:получитьВсеВопросы( $группа )
 
 let $вопросыПоДисциплинам :=
   for $i in $дисциплиныСтудента
   let $номерБилета := random:integer( 6 ) + 1
   let $вопросыПоДисциплине := 
     данные:получитьВопросыПоДисциплине( $ВсеВопросы, $i )
   where $вопросыПоДисциплине
   let $комбинацияВопросов :=
     данные:комбинацияВопросов( $вопросыПоДисциплине )
   let $билет := $комбинацияВопросов[ $номерБилета ]
   return
    <row label = "{ $i }">
      <cell label = 'Вопрос 1'>{ $билет?1 }</cell>
      <cell label = 'Вопрос 2'>{ $билет?2 }</cell>
      <cell label = 'Ссылка Мудл'>{ $ВсеВопросы/row[ cell[ @label = 'Дисциплина'] = $i ]/cell[ @label = 'Ссылка на курс в Мудл']/text() }</cell>
      <cell label = 'Преподаватель'>{ $ВсеВопросы/row[ cell[ @label = 'Дисциплина'] = $i ]/cell[ @label = 'Преподаватель' ]/text() }</cell>
      <cell label = 'Форма отчетности'>{ $ВсеВопросы/row[ cell[ @label = 'Дисциплина'] = $i ]/cell[ @label = 'Форма отчетности' ]/text() }</cell>
    </row>
  return
    <table label = "{ $студент }">{ $вопросыПоДисциплинам }</table>
};

declare
  %public
function данные:номераБилетов(){
  (
    for $i in 1 to 25
    order by random:integer( 25 )
    return 
      $i
  )
};

declare function данные:комбинацияВопросов( $вопросы ){
    for $i in 1 to 4
    for $j in $i to 4
    where $i != $j
    return
      [ $вопросы[ $i ], $вопросы[ $j ] ]
};

declare
  %public
function данные:получитьЗадолженностьСтудента( $студент, $группа ){
  данные:получитьГуглТаблицу( $данные:задолженностьПутьГугл )
  /file/table[ @label = 'Актуальная' ]
  /row[
    cell [ @label = 'ФИО студента'] = $студент and
    cell [ @label = 'Группа' ] = $группа
  ]
  /cell[ @label = 'Дисциплина' ]/text()
};


declare
  %public
function данные:получитьВопросыПоДисциплине( $всеВопросыПоГруппе, $дисциплина ){
  let $data := 
      $всеВопросыПоГруппе
      /row[ cell[ @label = 'Дисциплина' ] = $дисциплина ] 
  return
    $data/cell[ matches( @label, 'Вопрос' ) ]/text()
};

declare
  %public
function данные:получитьВсеВопросы( $группа ){
  let $data := 
      данные:получитьГуглТаблицу( $данные:вопросыПутьГугл )
      /file/table[ matches( @label,  $группа || ' Вопросы'  ) ]
  return
    $data
};

declare
  %public
function данные:получитьГуглТаблицу( $path ){  
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