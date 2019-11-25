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
       let $data := fetch:xml( $rup?url )
       where $data//Титул/@КодКафедры/data() != $currentKaf?code
       return
       element{'ul'}{
         element{ 'li' }{
           attribute{ 'style' }{ 'margin-bottom: 20px; ' },
           element{ 'span' }{
             attribute{ 'style' }{ 'font-weight: bold;' },
              '(',$data//Титул/@ГодНачалаПодготовки/data(),')',
              substring-after( $data//Специальности/Специальность[ 1 ]/@Название/data(), ' '),
              if(
                $data//Специальности/Специальность[ 2 ]/@Название/data() != ''
              )
              then(
                ' - ',
                substring-after( $data//Специальности/Специальность[ 2 ]/@Название/data(), 'Профиль ')
              )
              else(),
              
             '( ',
             $rup?rup/NAME/text(),' ',
             element{ 'a' }{
               attribute{ 'href' }{ $rup?pdf },
               'скачать РУП'
             },
             ' )'
           },
           element{'ol'}{
             for $discip in $data//СтрокиПлана/Строка[ @Кафедра = $currentKaf?code ]
             count $cd
             let $attr := 
               for $s in $discip/child::*[ name() = ( 'Сем', 'Курс' ) ]/attribute::*
               return
                 $s/name() || ': ' || $s/data()
             
             let $rupID :=  $rup?rup/ID/text()
             let $komp := replace( $discip/@КомпетенцииКоды/data(), '&amp;', ';' )
             let $href :=
               web:create-url(
                 '/sandbox/ivgpu/plans/' || $rupID,
                 map{ 'komp' : $komp }
               )
             
             let $properties := 
               <span>
                 (Код: { $discip/@ИдетификаторДисциплины/data() };
                 Компетенции: 
                 <a href = '{ $href }' target='_blank'>{ $discip/@Компетенции/data() }</a>;
                 { string-join( $attr, '; ' ) })
               </span>
             
             return
               element{'li'}{
                 $discip/@Дис/data(),
                 '&#xd;&#xa;',
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
  %rest:query-param( 'komp', '{ $komp }', '')
  %output:method( 'xhtml' )
function ivgpu:b( $code, $update, $komp ){
  let $urlList := 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' 
  let $getList := function( $id ){
    json:parse(
     fetch:text( $urlList || $id )
  )/json/result/_
  }
  let $kafList := $getList( '7266' )
  let $currentKaf:= map{ 'NAME' : 'ЭУФ', 'code' : $code }
  let $path := 
        file:temp-dir() ||  'subjects.Department.' || $code || '.Direction.xml'
        
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
    <h2>Дисциплины кафедры "{ $code }" по кафедрам и направлениям 2016-2018 годов приема</h2>
    <div>
      {
        $data
      }
    </div>
  </html>
    
};