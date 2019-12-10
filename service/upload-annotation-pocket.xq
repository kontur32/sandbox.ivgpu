let $dirToSave:= 'C:\Users\kontu\Downloads\output\'
let $reuestString := 
  'http://dbx.iro37.ru/sandbox/ivgpu/subjects.Department.Direction?mode=other&amp;fgos=&amp;id=21&amp;year=2019'

let $listURL := fetch:xml( $reuestString )//ol/li/a/@href/data()

for $p in $listURL
let $a := http:send-request (
      <http:request method='GET'/>,
     iri-to-uri( 'http://dbx.iro37.ru' || $p ) 
    )
    
let $fileName := 
  $a[1]/http:header[ @name="Content-Disposition" ]/@value/web:decode-url( substring-after( ., ' filename=' ))

return
  file:write-binary(
    $dirToSave || replace( $fileName, '"', ''),
    $a[2]
  )
  