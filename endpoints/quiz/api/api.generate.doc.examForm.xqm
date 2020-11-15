module namespace ivgpu.api.examForm = 'sandbox/ivgpu/api/jwt/validate';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  jwt = 'sandbox/ivgpu/вопросник/модули/jwt'
    at '../modules/modules.jwt.xqm';

declare
  %rest:path( '/sandbox/ivgpu/api/v01/generate/exam-form' )
  %rest:query-param( '_signature', '{ $signature }', '' )
  %rest:query-param( 'курс', '{ $курс }', '' )
  %rest:query-param( 'группа', '{ $группа }', '' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', '' )
  %rest:query-param( 'ФИОпреподавателя', '{ $ФИОпреподавателя }', '' )
  %rest:query-param( 'студент', '{ $студент }', '' )
  %rest:query-param( 'дисциплина', '{ $дисциплина }', '' )
  %rest:query-param( 'формаОтчетности', '{ $формаОтчетности }', '' )
  %rest:query-param( 'датаСдачи', '{ $датаСдачи }', '' )
  %rest:query-param( 'оценка', '{ $оценка }', '' )
function 
ivgpu.api.examForm:validateToken(
    $signature as xs:string,
    $курс,
    $группа as xs:string,
    $преподаватель as xs:string,
    $ФИОпреподавателя,
    $студент as xs:string,
    $дисциплина as xs:string,
    $формаОтчетности as xs:string,
    $датаСдачи,
    $оценка as xs:string
  ){
  let $ЭЦП := 
    csv:parse( fetch:text('https://docs.google.com/spreadsheets/d/e/2PACX-1vQnKyXRmpX52iJ6Oj4A9xlcLC35KKd61UArCiCKpu-yogCOEW7TolfPe95Pm_st82C_3JF2qYa26uJZ/pub?gid=0&amp;single=true&amp;output=csv'), map{'header': 'yes'} )
/csv/record[ ФИО/text() = $преподаватель ]/ЭЦП/text()
  
  let $payLoad := 
    <json type="object">
      <группа>{ $группа }</группа>
      <студент>{ $студент }</студент>
      <дисцилина>{ $дисциплина }</дисцилина>
      <формаОтчетности>{ $формаОтчетности }</формаОтчетности>
      <преподаватель>{ $преподаватель }</преподаватель>
      <кафедра>ЭУФ</кафедра>
      <оценка>{ $оценка }</оценка>
      <датаСдачи>{ $датаСдачи }</датаСдачи>
      <датаВремяПодписи>{ current-dateTime() }</датаВремяПодписи>
      <подписавшееЛицо>{ $преподаватель }</подписавшееЛицо>
    </json>

  let $jwt := jwt:buildJWT( json:serialize( $payLoad ) )
  
  let $path := web:encode-url( $jwt )
  
  let $shortLink := fetch:text(  'https://clck.ru/--?url=' || $path )

  let $qrHref := 
        web:create-url(
          'https://chart.googleapis.com/chart',
          map{
            'cht': 'qr',
            'chs' : '200x200',
            'choe' : 'UTF-8',
            'chld' : 'H',
            'chl' : 'http://dbx.iro37.ru/sandbox/ivgpu/api/v01/jwt/validate/token?short-link=' || $shortLink
          }
        )
      
  let $картинка := 
    if( $signature = $ЭЦП )
    then( xs:string( fetch:binary( $qrHref ) ) )
    else(
       xs:string( file:read-binary( file:base-dir()|| 'src/fail.jpg' ) )
    )

  let $data :=
    <table>
      <row id="fields">
        <cell id="курс">{ $курс }</cell>
        <cell id="группа">{ $группа }</cell>
        <cell id="студент">{ $студент }</cell>
        <cell id="преподаватель">{ $преподаватель }</cell>
        <cell id="ФИОпреподавателя">{ $ФИОпреподавателя }</cell>
        <cell id="дисциплина">{ $дисциплина }</cell>
        <cell id="датаСдачи" >{
          replace( $датаСдачи, '(\d{4})-(\d{2})-(\d{2})', '$3.$2.$1')
        }</cell>
        <cell id="оценка">{ $оценка }</cell>
        
      </row>
      <row id="pictures">
        <cell id="Картинка 1">{ $картинка }</cell>
      </row>
    </table>

  let $template := fetch:binary( "http://dbx.iro37.ru/zapolnititul/api/v2/forms/c497e390-596a-436c-8e98-137de660c3eb/template" )
 
  let $request :=
    <http:request method='post'>
      <http:multipart media-type = "multipart/form-data" >
          <http:header name="Content-Disposition" value= 'form-data; name="template";'/>
          <http:body media-type = "application/octet-stream" >
            { $template }
          </http:body>
          <http:header name="Content-Disposition" value= 'form-data; name="data";'/>
          <http:body media-type = "application/xml">
            { $data }
          </http:body>
      </http:multipart> 
    </http:request>
  
  let $fileName := 'exForm.pdf'
  
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )

   let $response := 
     http:send-request (
        $request,
        'http://localhost:9984/api/v1/ooxml/docx/template/complete'
      )
  
  return 
   (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      ivgpu.api.examForm:buildPDF( $response[ 2 ]  )
   )
};

declare function ivgpu.api.examForm:buildPDF( $fileDocx ){
  let $fileName := 'titul24.docx'
  
  let $file := 
    file:write-binary(
      file:temp-dir() || $fileName,
      $fileDocx
    )
  
  let $command :=
    if( starts-with( file:temp-dir(), '/tmp/') )
    then(
        '/opt/libreoffice6.3/program/soffice'
    )
    else(
        'C:/Program Files/LibreOffice/program/soffice'
    )
  let $params := 
    (
      '--headless',
      '--convert-to',
      'pdf:writer_pdf_Export', 
      '--outdir',
      file:temp-dir(),
      file:temp-dir() || $fileName
    )
  let $result := proc:execute( $command, $params )
  
  let $f := file:read-binary( file:temp-dir() || 'titul24.pdf' )
 
  return
      $f
};