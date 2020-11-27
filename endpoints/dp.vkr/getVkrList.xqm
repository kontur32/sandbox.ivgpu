module namespace ivgpu = "ivgpu";

declare 
  %rest:path("/sandbox/ivgpu/vkr/monitor")
  %rest:GET
  %rest:query-param( "sessionid", "{ $sessionid }",  "")
  %rest:query-param( "year", "{ $year }",  "все")
  %output:method( "xhtml" )
function ivgpu:monitor( $sessionid, $year ){

let $sessionid := file:read-text( file:base-dir() || '/sessionid.txt' )

let $r := http:send-request(
    <http:request method='get'
       href='{ "https://dp.ivgpu.com/teacher/vkr_department" }'>
      <http:header name="Cookie" value="{ 'sessionid=' || $sessionid }" />
    </http:request>
   )[2]//table[1]


let $rows :=
  $r/tbody/tr[ if( $year != "все" )then( td[ 6 ]/text() = $year )else( true() ) ]
let $prep := sort( distinct-values( $rows/td[ 2 ] ) )
let $napr := sort( distinct-values( $rows/td[ 4 ] ) )
let $годы :=
  for $i in ( '2018', '2019', '2020', 'все')
  return
    if( $i = $year )
    then( <b>{ $i }</b>)
    else( <a href = "{ '?year=' || $i }">{ $i }</a> )
let $result := 
  <html>
    <body>
      <div class="container">
      <div class="row">
        <div class="h3">Мониторинг загрузки ВКР кафедры ЭУФ</div>
      </div>
      <div>Можно выбрать год: { $годы }</div>
      <div class="row">
        <div class="text-center font-italic">по состоянию на { current-date() }</div>
      </div>
      <div class="table">
      <table class="table-striped">
        <tr class="text-center">
          <th>#</th>
          <th>Преподаватель</th>
          <th>Загружено ВКР всего</th>
          {
            for $n in $napr
            return
              <th>{ $n }</th>
          }
        </tr>
      {
        for $p in $prep
        count $c
        return
          <tr>
            <td>{ $c }.</td>
            <td>{$p}</td>
            <td  class="text-center">{ count( $rows[td[2]/text() = $p ] ) }</td>
            {
              for $n in $napr
              return
                <td class="text-center">{  count( $rows[ td[2]/text() = $p and  td[4]/text() = $n ] ) }</td>
            }
          </tr> ,
          <tr class="text-center font-bold">
            <th></th>
            <th>Всего:</th>
            <th>{ count ( $rows ) }</th>
            {
              for $n in $napr
              return
                <th class="text-center">
                  { count( $rows[ td[ 4 ]/text() = $n ] ) }
                </th> 
            }
          </tr>
        }</table>
        </div>
      </div>
     </body>
     <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"></link>
   </html>
   
   return $result
};