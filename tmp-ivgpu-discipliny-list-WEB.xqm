module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/subjects.Departments.List' )
  %rest:query-param( 'id', '{ $id }', '29' )
  %rest:query-param( 'update', '{ $update }', 'no' )
  %rest:query-param( 'mode', '{ $mode }', 'other' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $update, $mode ){
  
  let $filesList := 
    $rup:getList( $rup:folderList( '46686' ) )/NAME/substring-before( ./text(), '_' )
  
  let $data := rup:getData( $id, $update, $mode )
  
  let $result := 
      switch ( $mode )
        case 'own'
         return
           $data update delete node ./li/ul/li/ol/li[ kafcode/text() != $id ]
        case 'other'
         return
           $data update delete node ./li/ul/li/ol/li[ kafcode/text() = $id ]
       default return $data
  return
    <html>
      <h2>Перечень дисциплин кафедры "{ $id }" 2016-2018 годов приема</h2>
      <ol>
        {
          for $i in distinct-values( $result/li/ul/li/ol/li/a/text() )
          let $count := count( $result/li/ul/li/ol/li/a[ text() = $i ] )
          order by $count descending
          let $href := '/sandbox/ivgpu/subjects.ContentFiles.List/' || $i
          return
            <li>{ $count }.<a href = '{ $href }'>{ count( $filesList[ . =  $i ]) }</a>.{ $i }</li>
        }
      </ol>
    </html>
};