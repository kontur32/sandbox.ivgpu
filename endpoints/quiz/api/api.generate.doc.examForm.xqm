module namespace ivgpu.api.examForm = 'sandbox/ivgpu/api/jwt/validate';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  jwt = 'sandbox/ivgpu/вопросник/модули/jwt'
    at '../modules/modules.jwt.xqm';

import module namespace 
  config = 'sandbox/ivgpu/вопросник/модули/config'
    at '../config.xqm';

declare
  %rest:path( '/sandbox/ivgpu/api/v01/generate/exam-form' )
  %rest:query-param( '_jwt-path', '{ $jwt-path }', '' )
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
    $jwt-path,
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
  
  
  let $payLoad := 
    if( $jwt-path != "")
    then(
      let $j := fetch:text( iri-to-uri( $jwt-path ) )
      let $t := tokenize( $j , '\.' )
      let $p := json:parse( convert:binary-to-string( xs:base64Binary( $t[2] ) ) )
      return
        $p/json
    )
    else(
      <json type="object">
        <группа>{ $группа }</группа>
        <студент>{ $студент }</студент>
        <дисциплина>{ $дисциплина }</дисциплина>
        <формаОтчетности>{ $формаОтчетности }</формаОтчетности>
        <преподаватель>{ $преподаватель }</преподаватель>
        <кафедра>ЭУФ</кафедра>
        <оценка>{ $оценка }</оценка>
        <датаСдачи>{ $датаСдачи }</датаСдачи>
        <датаВремяПодписи>{ current-dateTime() }</датаВремяПодписи>
        <подписавшееЛицо>{ $преподаватель }</подписавшееЛицо>
      </json>
    )

  let $jwt := 
    if( $jwt-path != "" )
    then(
      fetch:text( iri-to-uri( $jwt-path ) )
    )
    else(
      jwt:buildJWT( json:serialize( $payLoad ) ) 
    )
  
  let $ЭЦП := 
   config:получитьКодПодписи( $payLoad/преподаватель/text() )   
  
  let $картинка := 
    if( $signature = $ЭЦП or $jwt-path != "" )
    then(  ivgpu.api.examForm:buildQR( $jwt ) )
    else(
       xs:string( file:read-binary( file:base-dir()|| 'src/fail.jpg' ) )
    )
    
  let $data := ivgpu.api.examForm:buildData( $payLoad, $картинка )
  let $docx := ivgpu.api.examForm:buildDocx( $data )
  
  let $fileName := 'exForm.pdf'
  
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
      ivgpu.api.examForm:buildPDF( $docx )
   )
};


declare
  %private
function ivgpu.api.examForm:buildData( $payLoad, $картинка ){
   let $ФИО :=
       let $t := tokenize( $payLoad/преподаватель/text() )
       return
         substring( $t[ 2 ], 1, 1 ) ||'.'
         ||substring( $t[ 3 ], 1, 1 ) ||'. '||
         $t[ 1 ]
  return
    <table>
      <row id="fields">
        <cell id="курс">{ substring( replace( $payLoad/группа/text(), '\D', ''), 1, 1 ) }</cell>
        <cell id="группа">{ $payLoad/группа/text() }</cell>
        <cell id="студент">{ $payLoad/студент/text() }</cell>
        <cell id="преподаватель">{ $payLoad/преподаватель/text() }</cell>
        <cell id="ФИОпреподавателя">{ $ФИО }</cell>
        <cell id="дисциплина">{ $payLoad/дисциплина/text() }</cell>
        <cell id="формаОтчетности">{ $payLoad/формаОтчетности/text() }</cell>
        <cell id="датаСдачи" >{
          replace(  $payLoad/датаСдачи/text(), '(\d{4})-(\d{2})-(\d{2})', '$3.$2.$1')
        }</cell>
        <cell id="оценка">{  $payLoad/оценка/text() }</cell>
      </row>
      <row id="pictures">
        <cell id="Картинка 1">{ $картинка }</cell>
      </row>
    </table>
};

declare
  %private
function ivgpu.api.examForm:buildQR( $jwt ){
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
   return
     xs:string( fetch:binary( $qrHref ) )
};

declare
  %private
function ivgpu.api.examForm:buildDocx( $data ){
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
  
   return 
     http:send-request (
        $request,
        'http://localhost:9984/api/v1/ooxml/docx/template/complete'
      )[ 2 ]
};

declare
  %private
function ivgpu.api.examForm:buildPDF( $fileDocx ){
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