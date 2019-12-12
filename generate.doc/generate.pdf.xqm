module namespace ivgpu = '/sandbox/ivgpu/plans.list';

declare 
  %rest:path('/sandbox/ivgpu/generate/Аннотация/{$ID}/{$discID}/pdf')
function ivgpu:main( $ID, $discID ){

  let $fileName := 'titul24.docx'
  let $fileNamePDF := replace( $fileName, '.docx', '.pdf' )
  
  let $file := 
    file:write-binary(
      file:temp-dir() || $fileName,
      fetch:binary(
        iri-to-uri( 'http://dbx.iro37.ru/sandbox/ivgpu/generate/Аннотация/' || $ID || '/' || $discID
        )
      ) 
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
    "attachment; filename=" || iri-to-uri( $fileNamePDF )
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