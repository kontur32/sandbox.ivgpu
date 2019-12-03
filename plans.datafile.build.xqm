module namespace ivgpu = '/sandbox/ivgpu/plans.datafile.build';

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
        [ 1 ]
      where $url
      return 
        fetch:xml( $url/DOWNLOAD__URL/text() )/child::* 
          update insert node attribute { 'DETAIL__URL' } { $url/DETAIL__URL/text() } into .,
      
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
    file:write(
      file:temp-dir() || $rootID ||'.xml',
      <data>{ ivgpu:getPlans( $rootID, '/' )  }</data>
    )
  )
  else(),
  <p>Обновить данные из папки:
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=7266'>ФГОС 3+ 2016-2018</a>, 
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=25839'>ФГОС 3+ 2019</a>,
     <a href = '/sandbox/ivgpu/plans.datafile.build?rootID=19677'>ФГОС 3++ 2019</a>
   </p>
};
