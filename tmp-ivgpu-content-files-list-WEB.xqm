module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/subjects.ContentFiles.List/{ $disc }' )
  %output:method( 'xhtml' )
function ivgpu:file( $disc ){
  <div>
      <h2>Список файлов с содержанием аннотаций дисциплины "{ $disc }"</h2>
      <ol>{
        for $i in rup:getFileContentList( '46686')
        where substring-before( $i/NAME/text(), '_') = $disc
        order by $i/NAME/text()
        return
          <li><a href = '{ "/sandbox/ivgpu/file.get/" || $i/ID/text() }'>{ $i/NAME/text() }</a></li>
      }</ol>
  </div>

  
};

declare 
  %rest:path( '/sandbox/ivgpu/subjects.ContentFiles.List' )
  %output:method( 'xhtml' )
function ivgpu:list(){
  <ol>{
    for $i in $rup:getList( $rup:folderList( '46686' ) )
    order by $i/NAME/text()
    return
      <li><a href = '{ "/sandbox/ivgpu/file.get/" || $i/ID/text() }'>{ $i/NAME/text() }</a></li>
  }</ol>
  
};