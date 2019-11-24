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
    element{'ul'}{
      for $kaf in $kafList
   return 
     element{ 'li' }{
       element{ 'h3' }{
         $kaf/NAME/text() 
       },
       for $rup in $rupList[ .?kaf= $kaf ]
       return
       element{'ul'}{
         let $data := fetch:xml( $rup?url )
       return
         element{ 'li' }{
           element{ 'span' }{
             attribute{'style'}{'font-weight: bold;'},
              $data//Титул/@ПоследнийШифр/data() || ', год: ' || $data//Титул/@ГодНачалаПодготовки/data() ||', группа: ' || $rup?rup/NAME/text(),
             '(',
             element{ 'a' }{
               attribute{ 'href' }{ $rup?pdf },
               'скачать РУП'
             },
             ')'
           },
           element{'ol'}{
             for $discip in $data//СтрокиПлана/Строка[ @Кафедра = $currentKaf?code ]
             count $cd
             let $attr := 
               for $s in $discip/child::*[ name() = ( 'Сем', 'Курс' )]/attribute::*
               return
                 $s/name() || ': ' || $s/data()
             let $properties := 
                ' (Код: ' ||  
                   $discip/@ИдетификаторДисциплины/data() || '; Компетенции: ' ||
                   $discip/@Компетенции/data()|| '; ' ||
                   string-join( $attr, '; ' ) || 
                 ')'
             
             return
               element{'li'}{
                 $discip/@Дис/data() || '&#xd;&#xa;' ||
                 $properties
               }
           }
         }
       }
     }
    }   
};


declare 
  %rest:path( '/sandbox/ivgpu/subjects.Department.Direction' )
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
        file:current-dir() ||  '../webapp/sandbox.ivgpu/subjects.Department.' || $code || '.Direction.xml'
        
  let $data:= 
    if( $update = 'yes' or not ( file:exists( $path ) ) )
    then(
      let $a :=  ivgpu:a( $kafList, $currentKaf, $getList )
      return
        (
          file:write( $path, $a ),
          $a
        )
    )
    else(
      doc( $path )
    )
  
  return
  <html>
    <h2>Дисциплины кафедры { $code } по кафедрам и направления</h2>
    <div>
      {
        $data
      }
    </div>
  </html>
    
};