module  namespace ivgpu = '/ivgpu/simplex/api/v01/get/шаблонАннотации';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../../generate.doc/config.xqm';

declare
 %rest:path( '/sandbox/ivgpu/generate/lists/upload/rpd' )
 %output:method( 'xhtml' )
function ivgpu:main( ){
  let $пользователи :=
      csv:parse(  
            fetch:text(
              'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=1161096430&amp;single=true&amp;output=csv'
          ), map{ 'header' : true() } )/csv/record
  
  let $items :=
    let $fileList := file:list( config:param('log.dir') )
  return
    for $i in $fileList[ not( matches( ., 'error-' ) ) ]
    let $date := substring-before( $i, '.' )
    order by $date descending
    return
      <ol><b>{ $date }</b>
      {
        for $j in  file:read-text-lines( config:param('log.dir') || $i )
        let $record := tokenize( $j )
        let $time := substring-after( substring-before( $record[ 1 ], '.' ), 'T' )
        order by $time descending
        let $пользователь := $пользователи[ email/text() = $record[ 2 ] ]
        let $userName := 
          if( $пользователь )
          then(
            $пользователь/Фамилия/text() || ' ' ||
            substring( $пользователь/Имя/text(), 1, 1 ) || '.' ||
            substring( $пользователь/Отчество/text(), 1, 1 ) || '.'
          )
          else( 'John Doe' )
        let $кафедра := $пользователь/Кафедра/text()
        let $hrefUserSite := '/sandbox/ivgpu/statistic/lists/subjects/' || $кафедра || '/' || $userName
        return
          <li>{ $time } : <a href = "{ $hrefUserSite }">{ $userName }</a> (кафедра: { $кафедра }): <a href = "{ substring-before( $record[ 3 ], '?' )}">{ web:decode-url( substring-before( $record[ 3 ], '?' ) ) }</a></li>
      }</ol>
  let $result :=
    <div>
      <h3>Загруженные РПД</h3>
      <div>{ $items }</div>
    </div>
  let $tpl := doc( "../../html/main.tpl.html" )
  return
    $tpl update insert node $result into .//body
};