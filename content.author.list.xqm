module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' 
  at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module namespace comp = 'ivgpu' at 'old/template.Complete.xqm';

import module  namespace 
  content = '/sandbox/ivgpu/generate/content' 
  at 'generate.doc/generate.content.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/content.author.list/old' )
  %rest:query-param( 'id', '{ $id }', '29' )
  %rest:query-param( 'update', '{ $update }', 'no' )
  %rest:query-param( 'mode', '{ $mode }', 'other' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $update, $mode ){
  <ol>{
     let $signList := $rup:getList( $rup:folderList( '55279' ) )
     let $contentList := rup:getFileContentList( '46686' )
     for $disc in $contentList
     let $author := comp:subjectContent( $disc/NAME/text()/substring-before( ., '_содержание.docx'), 'Автор' )//cell/text()
     order by $author
     let $file:= 
       if ( $author )
       then(
         $signList[ matches( NAME/text(), $author ) ]
       )
       else()
     return
      <li>
        <a href='{ $disc/DETAIL__URL/text() }'>{ $disc/NAME/text()/substring-before( ., '_содержание.docx') }</a> - 
        {
          if( $file/DOWNLOAD__URL/text() )
          then( <a href="{ $file/DOWNLOAD__URL/text() }">{ $author }</a> )
          else( $author )
        }
      </li>
  }</ol>
};

declare 
  %rest:path( '/sandbox/ivgpu/content.author.list' )
  %rest:query-param( 'id', '{ $id }', '29' )
  %rest:query-param( 'starts', '{ $starts }', '1' )
  %rest:query-param( 'limit', '{ $limit }', '5' )
  %output:method( 'xhtml' )
function ivgpu:view1( $id, $starts as xs:integer, $limit as xs:integer ){
  let $data := rup:getFileContentList( '46686' )
      [ TYPE='file' ]
      [ NAME/ends-with( ., '_содержание.docx' ) ]
  let $fields := 
    (
      [ 'Автор', 'field' ]
    )
  let $fileList := 
    rup:getFileContentList( '55279' )
      [ TYPE='file' ]
 
        
  let $list := 
  for $i in $data[ position() = ($starts to $starts + $limit - 1 )]
  let $content := content:getContent( $i/NAME/text(), $fields )
   let $pictureFile := 
       $fileList
        [ contains( NAME/text(), $content ) ]
  return
    <li>
      <a href = '{$i/DOWNLOAD__URL/text()}'>{$i/NAME/text()}</a> - 
        {
          if($pictureFile)
          then(
            <a href = '{ $pictureFile/DOWNLOAD__URL/text()}'>{ $content}</a>
          )
          else(
            $content
          )
        }
    </li>
  return
    <ol>{$list}</ol>
    
  
};