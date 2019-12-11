module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' 
  at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module  namespace 
  content = '/sandbox/ivgpu/generate/content' 
  at 'generate.doc/generate.content.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/content.author.list' )
  %rest:query-param( 'id', '{ $id }', '29' )
  %rest:query-param( 'starts', '{ $starts }', '1' )
  %rest:query-param( 'limit', '{ $limit }', '5' )
  %rest:query-param( 'mode', '{ $mode }' )
  %output:method( 'xhtml' )
function ivgpu:view1( $id, $starts as xs:integer, $limit as xs:integer, $mode ){
  
  let $data := rup:getFileContentList( '46686' )
      [ TYPE='file' ]
      [ NAME/ends-with( ., '_содержание.docx' ) ]
  
  let $signatureFiles := 
    rup:getFileContentList( '55279' )
      [ TYPE='file' ]
        
  let $list := 
    for $i in $data[ position() = ( $starts to $starts + $limit - 1 ) ]
    let $currentName := content:getContent( $i/NAME/text(), [ 'Автор', 'field' ] )
    let $currentSignature := 
         $signatureFiles
          [ contains( NAME/text(), $currentName ) ]
    where if( $mode = 'none' )then( not( $currentSignature ) )else( true()  )
    order by $currentSignature
    return
      <li>
        <a href = '{ $i/DOWNLOAD__URL/text() }'>{ $i/NAME/text() }</a> - 
          {
            if( $currentSignature )
            then(
              <a href = '{ $currentSignature/DOWNLOAD__URL/text()}'>{ $currentName }</a>
            )
            else(
              $currentName
            )
          }
      </li>
    
    return
      <div>
        <div>Записей на странице: 
          {
            for $i in ( 5, 10, 15 )
            let $href := 
              web:create-url(
                '/sandbox/ivgpu/content.author.list',
                map{
                  'limit' : $i,
                  'starts' : '1',
                  'mode' : $mode
                }
              )
            return
              <a href = '{ $href }'>{ $i }</a>
          }
        </div>
        <div> Страницы: 
          {
            for $i in ( 1 to xs:integer( ceiling( count( $data ) div $limit ) ) )
            let $first := $i*$limit - $limit + 1
            let $href := 
              web:create-url(
                '/sandbox/ivgpu/content.author.list',
                map{
                  'limit' : $limit,
                  'starts' : $first,
                  'mode' : $mode
                }
              )
            return
              <a href = '{ $href }'>[{ $first } - { $i*$limit }]</a>
          }
        </div>
        <ol start = '{ $starts }'>{ $list }</ol>
      </div>
};