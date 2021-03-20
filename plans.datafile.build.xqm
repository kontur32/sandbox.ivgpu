module namespace ivgpu = '/sandbox/ivgpu/plans.datafile.build';
import module namespace transf = 'transformator' at 'modules/transformator.xqm';


declare function ivgpu:getFolderList( $folderID, $start ){
  let $list := 
    json:parse(
           fetch:text(
             web:create-url(
               'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren',
               map{
                 'id' : $folderID,
                 'start' : $start
               }
             )
           )
        )
 let $next := $list/json/next/text()
 
 return
    if( $next )
    then(
      $list,
      ivgpu:getFolderList( $folderID, $next )
    )
    else(
      $list
    )
};

declare function ivgpu:getPlans( $folderID, $folderName ){
  let $list := ivgpu:getFolderList( $folderID, '0' )/json/result/_
  return
    (
      let $url := 
        $list[ NAME[ matches( ., '(.xml|.plx)$' ) ] ]
      where $url
      for $i in $url
      return 
        fetch:xml( $i/DOWNLOAD__URL/text() )/child::* 
          update { insert node attribute { 'DETAIL__URL' } { $i/DETAIL__URL/text() } into . }
          update { insert node attribute { 'ID' } { $i/ID/text() } into . }
          update { insert node attribute { 'CREATE__TIME' } { $i/CREATE__TIME/text() } into . }
          update { insert node attribute { 'UPDATE__TIME' } { $i/UPDATE__TIME/text() } into . },
      
      for $f in $list[ TYPE = 'folder' ]
      return
        ivgpu:getPlans( $f/ID, $f/NAME )  
    )
};

declare 
  %rest:path('/sandbox/ivgpu/plans.datafile.build')
  %rest:query-param( 'rootID', '{ $rootID }' )
  %output:method( 'xhtml' )
function ivgpu:main( $rootID ){
  if( $rootID )
  then(
    let $fileName := file:temp-dir() || '.' || $rootID ||'.simplex.xml'
    return
    ( 
      file:write-text(
        $fileName,
        '<Программы>'
      ),
      let $data := ivgpu:getPlans( $rootID, '/' )
      let $p := $data[ not( ./*:diffgram ) ]
      let $pp := $data[  ./*:diffgram ]
      return
          file:append(
              $fileName,
              (
                for $i in $pp
                return
                  transf:PP-to-simplex( $i ),
                for $i in $p
                return
                  transf:P-to-simplex( $i )
              )
         ),
      file:append-text(
        $fileName,
        '</Программы>'
      )
    )
  )
  else(),
  <p>Обновить данные из папки:
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=7266'>ФГОС 3+ 2016-2018</a>, 
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=25839'>ФГОС 3+ 2019</a>,
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=19677'>ФГОС 3++ 2019</a>
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=187254'>Все в редакции 2020 года</a>
   </p>
};
(: 237379 ЭПОд :)