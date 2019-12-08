module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' 
  at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

import module namespace comp = 'ivgpu' at 'old/template.Complete.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/content.author.list' )
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