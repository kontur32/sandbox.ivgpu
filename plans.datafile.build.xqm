module namespace ivgpu = '/sandbox/ivgpu/plans.datafile.build';
import module namespace transf = 'transformator' at 'modules/transformator.xqm';

declare variable  $ivgpu:folderList := 
  function( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  };

declare variable  $ivgpu:getList :=
    function( $url ){
      json:parse(
       fetch:text( $url )
    )/json/result/_
  };

declare function ivgpu:getPlans( $folderID, $folderName ){
  let $list := $ivgpu:getList( $ivgpu:folderList( $folderID ) )
  return
    (
      let $url := 
        $list[ NAME[ matches( ., '(.xml|.plx)$' ) ] ]
      where $url
      for $i in $url
      return 
        fetch:xml( $i/DOWNLOAD__URL/text() )/child::* 
          update { insert node attribute { 'DETAIL__URL' } { $i/DETAIL__URL/text() } into . }
          update { insert node attribute { 'ID' } { $i/ID/text() } into . },
      
      for $f in $list[ TYPE = 'folder' ]
      return
        ivgpu:getPlans( $f/ID, $f/NAME )  
    )
};

declare 
  %rest:path('/sandbox/ivgpu/plans.datafile.build')
  %rest:query-param('rootID', '{ $rootID }' )
  %output:method( 'xhtml' )
function ivgpu:main( $rootID ){
  if( $rootID )
  then(
    let $data := ivgpu:getPlans( $rootID, '/' )
    return
    ( 
      file:write(
        file:temp-dir() || '.' || $rootID ||'.xml',
        <data>{ $data  }</data>
      ),
      file:write(
        file:temp-dir() || '.' || $rootID ||'.simplex.xml',
        switch ( $rootID )
        case '19677'
          return
            <Программы>{ transf:PP-to-simplex( $data ) }</Программы>
        default
          return
             <Программы>{ transf:P-to-simplex( $data ) }</Программы>
      )
    )
  )
  else(),
  <p>Обновить данные из папки:
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=7266'>ФГОС 3+ 2016-2018</a>, 
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=25839'>ФГОС 3+ 2019</a>,
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=19677'>ФГОС 3++ 2019</a>
   </p>
};