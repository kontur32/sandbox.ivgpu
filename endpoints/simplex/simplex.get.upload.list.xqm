module  namespace ivgpu = '/ivgpu/simplex/api/v01/get/шаблонАннотации';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../../generate.doc/config.xqm';

declare
 %rest:path( '/sandbox/ivgpu/generate/lists/upload/rpd' )
 %output:method( 'xhtml' )
function ivgpu:main( ){
  let $items :=
    let $fileList := file:list( config:param('log.dir'))
  return
    for $i in $fileList
    return
      <ol><b>{ substring-before( $i, '.') }</b>
      {
        for $j in  file:read-text-lines( config:param('log.dir') || $i )
        let $record := tokenize( $j )
        let $time := substring-after( substring-before( $record[ 1 ], '.' ), 'T')
        return
          <li>{ $time } : { $record[ 2 ] } : <a href = "{ substring-before( $record[ 3 ], '?' )}">{ web:decode-url( substring-before( $record[ 3 ], '?' ) ) }</a></li>
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