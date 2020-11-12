module namespace ivgpu.api.examForm = 'sandbox/ivgpu/api/jwt/validate';

import module namespace request = 'http://exquery.org/ns/request';

declare
  %rest:path( '/sandbox/ivgpu/api/v01/generate/exam-form' )
  %rest:query-param( 'группа', '{ $группа }', '' )
  %rest:query-param( 'преподаватель', '{ $преподаватель }', '' )
  %rest:query-param( 'студент', '{ $студент }', '' )
  %rest:query-param( 'дисциплина', '{ $дисциплина }', '' )
  %rest:query-param( 'оценка', '{ $оценка }', '' )
function 
ivgpu.api.examForm:validateToken(
    $группа as xs:string,
    $преподаватель as xs:string,
    $студент as xs:string,
    $дисциплина as xs:string,
    $оценка as xs:string
  ){
  let $secret := 'secret'
  let $currentDate :=  current-date()
  
  let $payLoad := 
    <json type="object">
      <группа>{ $группа }</группа>
      <студент>{ $студент }</студент>
      <дисцилина>{ $дисциплина }</дисцилина>
      <преподаватель>{ $преподаватель }</преподаватель>
      <кафедра>ЭУФ</кафедра>
      <оценка>{ $оценка }</оценка>
      <дата>{ $currentDate }</дата>
      <датаВремяСозданияПодписи>{ current-dateTime() }</датаВремяСозданияПодписи>
    </json>

  let $jwt := ivgpu.api.examForm:buildJWT( json:serialize( $payLoad ),  $secret )
  
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
      
  let $картинка := xs:string( fetch:binary( $qrHref ) )

  let $data :=
    <table>
      <row id="fields">
        <cell id="группа">{ $группа }</cell>
        <cell id="студент">{ $студент }</cell>
        <cell id="преподаватель">{ $преподаватель }</cell>
        <cell id="дисциплина">{ $дисциплина }</cell>
        <cell id="оценка">{ $оценка }</cell>
        <cell id="дата" >{ $currentDate }</cell>
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

declare function ivgpu.api.examForm:buildJWT( $payLoad, $secret ){
  let $h := string( convert:string-to-base64( '{ "alg": "HS256", "typ": "JWT"}' ))
  let $p := string( convert:string-to-base64(  $payLoad ) )
  let $hash :=  string( hash:sha256( $h || '.' || $p || $secret ) )
  return
    $h || '.' ||   $p  || '.' || $hash
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
    (
      $f
    )
};