module namespace ivgpu = 'subjects.Department.Direction';

declare variable  $ivgpu:folderList := 
  function( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  };

declare variable  $ivgpu:getList :=
    function( $url ){
      json:parse(
       fetch:text( $url )
    )/json/result/_
  };

declare function ivgpu:getFileContentList( $folderID ){
  let $list := 
    $ivgpu:getList( $ivgpu:folderList( $folderID ) )
   return
     (
       $list[ TYPE = 'file'],
       for $f in $list[ TYPE = 'folder']
       return
         ivgpu:getFileContentList( $f/ID/text() )
     ) 
};

declare 
  %rest:path( '/sandbox/ivgpu/v0.1/subjects.Department.Direction' )
  %rest:query-param( 'id', '{ $id }' )
  %rest:query-param( 'code', '{ $code }', '29' )
  %rest:query-param( 'update', '{ $update }', 'no')
  %rest:query-param( 'mode', '{ $mode }', 'full')
  %rest:query-param( 'subj', '{ $subj }')
  %rest:query-param( 'year', '{ $year }')
  %output:method( 'xhtml' )
function ivgpu:view( $id, $code, $update, $mode, $subj, $year ){
  
  let $code := if( $id )then( $id )else( $code )
  
  let $fileContentList :=
    ivgpu:getFileContentList( '46686' )/NAME/substring-before( text(), '_' )
   
  let $data := ivgpu:getData( $code, $update, $mode )
  
  let $departmentList := 
    distinct-values( $data/li/ul/li/ol/li/kafcode/text() )
      [ switch ( $mode )
        case 'other' return . != $code
        case 'own' return . = $code
        default return true()
       ]
  
  let $result := 
      switch ( $mode )
        case 'own'
         return
           $data update delete node ./li/ul/li/ol/li[ kafcode/text() != $code ]
        case 'other'
         return
           $data update delete node ./li/ul/li/ol/li[ kafcode/text() = $code ]
       default return $data
  
  let $result := 
    if( $subj )
    then(
      $result 
        update { delete node ./li/ul/li/ol/li[ a/text() != $subj ] }
        update { delete node ./li/ul/li[ not( ol/li )] }
        update { delete node ./li[ not( ul/li/ol/li )] }
    )
    else(
      $result
        update { delete node ./li/ul/li[ not( ol/li )] }
        update { delete node ./li[ not( ul/li/ol/li )] }
     )
  
  let $result := 
    if( $year )
    then(
      $result 
        update { delete node ./li/ul/li[ span[ not ( contains( string-join( ./text() ) , $year ) ) ] ] }
    )
    else(
      $result
     )
     
  let $result :=
    $result
      update 
        for $i in .//li/ol/li/a
        where normalize-space( $i/text() ) = $fileContentList
        return
          insert node <span>></span> before $i
           
  let $unique := count( distinct-values( $result/li/ul/li/ol/li/a/text() ) )
  
  let $href := 
    web:create-url(
      '/sandbox/ivgpu/subjects.Departments.List',
      map{
        'id' : $code,
        'mode' : $mode
      }
    )
  let $totalSubjectCount := count( $result/li/ul/li/ol/li )
  let $readySubjectCount := count( $result/li/ul/li/ol/li/a[ text() = $fileContentList ] )
  let $baseURL := '/sandbox/ivgpu/subjects.Department.Direction'
  return
    <html>
      <h2>Дисциплины кафедры "{ $code }" по кафедрам и направлениям 2016-2018 годов приема</h2>
      <div>
        <div>По годам: 
          {
            for $i in ( 2016 to 2018 )
            let $href := 
              web:create-url(
                $baseURL,
                map{
                  'id' : $code,
                  'mode' : $mode,
                  'year' : $i
                }
              )
            return
              <a href = '{ $href }'>{$i}</a>,
              let $href := 
                web:create-url(
                  $baseURL,
                  map{
                    'id' : $code,
                    'mode' : $mode
                  }
                )
               return
                <a href = '{ $href }'>Все годы</a>
          }
        </div>
        <div>По выпускащим кафедрам:
          {
            let $modeList := 
              map{
                 'own' : '"Свои"' ,
                 'other': '"Чужие"',
                 'full': '"Все"' 
              }
            for $i in map:keys( $modeList )
            let $href := 
              web:create-url(
                  $baseURL,
                  map{
                    'id' : $code,
                    'mode' : $i,
                    'year' : if( $year )then($year)else()
                  }
                )
             return
              <a href = '{ $href }'>{ map:get( $modeList, $i ) }</a>
          }
        </div>
        <ul>Всего наш поисковый бот насчитал:
          <li>дисциплин: {  $totalSubjectCount  } 
          (из них уникальных <a href='{ $href }'>{ $unique }</a>), 
          в том числе по { $readySubjectCount } ({ round(  $readySubjectCount div $totalSubjectCount * 100 ) } %) загружен контент аннотаций          
          </li>
          <li>
            кафедр: { count( $departmentList ) } 
            (с кодами: {
              for $i in $departmentList
              order by number( $i )
              return
                <a href = '{ "/sandbox/ivgpu/subjects.Department.Direction?id=" || $i}'>{ $i }</a>
            } - <a target = '_blank' href = 'https://portal.ivgpu.com/~k35kp'>подсказка по кодам</a>)
          </li>
          <li>РУПов: { count( $result/li/ul/li[ ol/li ] ) }</li>
        </ul>
      </div>
      <div>
        {
          $result
        }
      </div>
    </html>
};

declare function ivgpu:getData( $id, $update, $mode ){
  
  let $kafList := $ivgpu:getList( $ivgpu:folderList( '7266' ) )
  let $currentKaf:= map{ 'code' : $id }
  let $path := 
        file:temp-dir() ||  'subjects.Department.' || $id || '.Direction.xml'
        
  return
    if( $update = 'yes' or not ( file:exists( $path ) ) )
    then(
      let $a := ivgpu:getSubjectsList( $kafList, $currentKaf, $ivgpu:getList, $mode )
      return
        (
          file:write( $path, $a ),
          $a
        )
    )
    else(
      doc( $path )/child::*
    )
};

declare function ivgpu:getSubjectsList( $kafList, $currentKaf, $getList, $mode ){
  let $rupList := 
    for $kaf in $kafList
      let $rupList := $getList( $ivgpu:folderList( $kaf/ID/text() ) )
      for $rup in $rupList
      where matches( $rup/NAME/text(), '201[6-8]' )
      let $downloadURL := 
         $getList( $ivgpu:folderList( $rup/ID/text() ) )
           [ TYPE/text() = 'file' ]
           [ ends-with( NAME/text(), '.xml' ) ][1]/DOWNLOAD__URL/text()
      let $downloadPdfURL := 
        $getList( $ivgpu:folderList( $rup/ID/text() ) )
        [ TYPE/text() = 'file' ]
        [ ends-with( NAME/text(), 'План.pdf' ) ][1]/DOWNLOAD__URL/text()
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

       return
       element{'ul'}{
         element{ 'li' }{
           attribute{ 'style' }{ 'margin-bottom: 20px; ' },
           element{ 'span' }{
             attribute{ 'style' }{ 'font-weight: bold;' },
              '(', $data//Титул/@ГодНачалаПодготовки/data(), ')',
              substring-after( $data//Специальности/Специальность[ 1 ]/@Название/data(), ' '),
              if(
                $data//Специальности/Специальность[ 2 ]/@Название/data() != ''
              )
              then(
                ' - ',
                substring-after( $data//Специальности/Специальность[ 2 ]/@Название/data(), 'Профиль ')
              )
              else(),
              
             '( ' || 
             $rup?rup/NAME/text() || ', ',
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
                    element{ 'kafcode' } {
                       attribute{ 'style' }{ 'visibility: hidden;' },
                       $data//Титул/@КодКафедры/data()
                     },
                 element{ 'a' }{
                     attribute{ 'href' }{
                       '/sandbox/ivgpu/templates/fill/' || $rup?rup/ID/text() ||'/' || $discip/@ИдетификаторДисциплины/data()
                     },
                     normalize-space( $discip/@Дис/data() )
                 },
                 $properties
               }
           }
         }
       }
     }
    }
};
