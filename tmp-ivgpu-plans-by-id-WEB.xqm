module namespace ivgpu = 'ivgpu';

declare 
  %rest:path( '/sandbox/ivgpu/plans/{$id}' )
  %rest:query-param( 'komp', '{ $komp }', '1')
  %output:method( 'text' )
function ivgpu:b( $id, $komp ){
  let $urlList := 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' 
    let $getList := function( $id ){
      json:parse(
       fetch:text( $urlList || $id )
    )/json/result/_
    }
  let $kafList := $getList( $id )
  let $rup := fetch:xml( $kafList[ ends-with( NAME/text(), '.xml' ) ]/DOWNLOAD__URL/text() )
  for $i in tokenize( $komp, ';' )
  where $i
  return
  
    '- ' || $rup//Компетенции/Строка[ @Код = $i ]/@Индекс/data() || ' - ' ||
    $rup//Компетенции/Строка[ @Код = $i ]/@Содержание/data() || '&#xd;'
};