let $dirToSave:= 'C:\Users\kontu\Downloads\output-18-2020\'
let $reuestString := 
  'https://sm.ivgpu.com/sandbox/ivgpu/subjects.Department.Direction?mode=other&amp;id=18&amp;year=2020'

let $listURL := fetch:xml( $reuestString )//ol/li//a[2]/@href/data()

for $p in $listURL
let $a :=
  http:send-request (
      <http:request method='GET'/>,
     iri-to-uri( 'https://sm.ivgpu.com' || $p ) 
    )
    
let $fileName := 
  $a[ 1 ]/http:header[ @name="Content-Disposition" ]
  /@value/web:decode-url( substring-after( ., ' filename=' ) )

count $c
return
  if(  $fileName and $a[ 2 ] instance of xs:base64Binary)
    then(
    file:write-binary(
     $dirToSave || replace( $c || '.' || $fileName, '"', ''),
      $a[ 2 ]
    )
  )
  else(
    file:write-text(
       $dirToSave || replace( $c || '.' || $fileName || '.txt', '"', ''),
      'ошибка'
    )
  )