module namespace ivgpu = '/sandbox/ivgpu/plans.list';

import module namespace request = 'http://exquery.org/ns/request';

import module  namespace 
  docx = '/sandbox/ivgpu/generate/Аннотация' 
  at 'generate.docx.xqm';

declare 
  %rest:path('/sandbox/ivgpu/generate/Аннотация/{$ID}/{$discID}/pdf')
  %rest:query-param( 'mode', '{ $mode }', 'signature' )
function ivgpu:main( $ID, $discID, $mode ){
  let $request :=
    http:send-request (
      <http:request method='GET'/>,
      web:create-url(
        'http://dbx.iro37.ru/sandbox/ivgpu/generate/Аннотация/' || $ID || '/' || $discID,
        map{ 'mode' : $mode }
      )
    )
  
  let $fileName := 'titul24.docx'
  let $fileNamePDF := replace( $fileName, '.docx', '.pdf' )
  let $outputFileName := 
    $request
     [ 1 ]/*:header[ @name="Content-Disposition" ]
     /@value/substring-after( data(), 'filename=' )
  
  let $file := 
    file:write-binary(
      file:temp-dir() || $fileName,
      $request[ 2 ]
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
  
  let $f := file:read-binary( file:temp-dir() || $fileNamePDF )
 
  let $ContentDispositionValue := 
    "attachment; filename=" 
    || iri-to-uri( replace( $outputFileName, '.docx', '.pdf' )  )
 
  return
    (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      $f,
      file:delete(  file:temp-dir() || $fileName ),
      file:delete(  file:temp-dir() || $fileNamePDF )
  )
};