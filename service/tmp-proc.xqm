module namespace ivgpu = '/sandbox/ivgpu/plans.list';

declare 
  %rest:path('/sandbox/ivgpu/proc')
  %output:method( 'text' )
function ivgpu:main(){
  let $command := '/opt/libreoffice6.3/program/soffice' 
  let $param := ('--headless', '--convert-to', 'pdf:writer_pdf_Export',  '--outdir', '/var/www/domains/iro37.ru/res/tmp', '/var/www/domains/iro37.ru/res/tmp/a.docx')
  return
    proc:execute( $command, $param )
};