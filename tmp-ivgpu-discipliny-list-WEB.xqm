 module namespace ivgpu = 'ivgpu';

declare function ivgpu:a( $kafList, $currentKaf, $getList ){
  let $rupList := 
  for $kaf in $kafList
    let $rupList := $getList( $kaf/ID/text() )
    for $rup in $rupList
    where matches( $rup/NAME/text(), '201[6-8]' )
    let $downloadURL := 
       $getList( $rup/ID/text() )[ TYPE/text() = 'file' ][ ends-with( NAME/text(), '.xml' ) ][1]/DOWNLOAD__URL/text()
    let $downloadPdfURL := 
      $getList( $rup/ID/text() )[ TYPE/text() = 'file' ][ ends-with( NAME/text(), 'План.pdf' ) ][1]/DOWNLOAD__URL/text()
    where $downloadURL
    return
       map{ 'kaf' : $kaf, 'rup' : $rup, 'url' : $downloadURL, 'pdf' : $downloadPdfURL }
       
  return
    for $kaf in $kafList
    for $rup in $rupList[ .?kaf= $kaf ]
    let $data := fetch:xml( $rup?url )
    for $discip in $data//СтрокиПлана/Строка[ @Кафедра = $currentKaf?code ]
    order by $discip/@Дис/data()
    return
      $discip/@Дис/data()
};


declare 
  %rest:path( '/sandbox/ivgpu/subjects.Department.List' )
  %rest:query-param( 'code', '{ $code }', '29' )
  %rest:query-param( 'update', '{ $update }', 'no')
  %output:method( 'xhtml' )
function ivgpu:b( $code, $update ){
  let $urlList := 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' 
  let $getList := function( $id ){
    json:parse(
     fetch:text( $urlList || $id )
  )/json/result/_
  }
  let $kafList := $getList( '7266' )
  let $currentKaf:= map{ 'NAME' : 'ЭУФ', 'code' : $code }
  let $path := 
        file:temp-dir() ||  'subjects.Department.' || $code || '.List.txt'
        
  let $data:= 
    if( $update = 'yes' or not ( file:exists( $path ) ) )
    then(
      let $a := distinct-values( ivgpu:a( $kafList, $currentKaf, $getList ) )
      
      return
        (
          file:write-text-lines( $path, $a ),
          $a
        )
      
    )
    else(
      file:read-text-lines( $path )
    )
  return
  <html>
    <h2>Перечень дисциплин кафедры { $code } 2016-2018 годов приема</h2>
    <ol>
      { 
        for $i in  $data
        return
          <li>{ $i }</li>
      }
    </ol>
  </html>
    
};