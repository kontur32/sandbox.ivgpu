module namespace ivgpu = '/sandbox/ivgpu/rup.list';

declare variable  $ivgpu:folderInfo := 
  function( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.get?id=' || $id
  };

declare variable  $ivgpu:getData :=
    function( $url ){
      json:parse(
       fetch:text( $url )
    )/json/result
  };
  
declare 
  %rest:path( '/sandbox/ivgpu/rup.list' )
  %rest:query-param( 'rootID', '{ $rootID }', '25839' )
  %rest:query-param('year', '{ $year }')
  %rest:query-param( 'id', '{ $id }' )
  %rest:query-param( 'dir', '{ $dir }' )
  %rest:query-param( 'update', '{ $update }', 'no' )
  %rest:query-param( 'mode', '{ $mode }', 'full' )
  %output:method( 'xhtml' )
function ivgpu:view( $rootID, $year, $id, $dir, $update, $mode ){
  let $path :=  file:temp-dir() || $rootID || ".xml"
  let $data := 
    try{ doc( $path ) }
    catch*{
      'Файл с данными не найден'
    }

  let $list:=
     for $i in $data//Документ
     let $t2 := 
       if( $i//Титул )
       then(
         map{
           'год' : $i//Титул/@ГодНачалаПодготовки/data(),
           'шифр' : $i//Титул/@ПоследнийШифр/data(),
           'кафедра' : $i//Титул/@КодКафедры/data()
         }
       )
       else(
           map{
             'год' :'',
             'шифр' : $i//*:dsMMISDB/*:ООП/@Шифр/data(),
             'кафедра' : ''
           }
           
       )
     order by number( $t2?кафедра )
     order by $t2?шифр
     order by $t2?год
     
     where if( $year )then( $t2?год = $year )else( true() )
     where if( $id )then( $t2?кафедра = $id )else( true() )
     where if( $dir )then( starts-with( $t2?шифр, $dir ) )else( true() ) 
     return 
       <li>
         { $t2?год } :
         { $t2?шифр } :
         { $t2?кафедра } :
         <a href = '{ $i/@DETAIL__URL/data() }'>{ $i/@LastName/data() }</a>
       </li>
   let $folderName := $ivgpu:getData( $ivgpu:folderInfo( $rootID ) )
   return
   <div>
     <i>Информация об этой форме на <a href='http://iro37.ru/xqwiki/TRaC/simplex'>TRaC/simplex</a></i>
     <p> Выберите папку с РУПами:
       <a href = '/sandbox/ivgpu/rup.list?rootID=7266'>ФГОС 3+ 2016-2018</a>, 
       <a href = '/sandbox/ivgpu/rup.list?rootID=25839'>ФГОС 3+ 2019</a>,
       <a href = '/sandbox/ivgpu/rup.list?rootID=19677'>ФГОС 3++ 2019</a>
     </p>
     <b>Список РУПов папке "<a href = '{ $folderName/DETAIL__URL }'>{ $folderName/NAME/text() }</a>"</b>
     <ol>
       {
         $list
       }
     </ol>
   </div>
     
};
